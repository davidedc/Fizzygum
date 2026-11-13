# A BACK BUFFER: an offscreen canvas holding one widget's own picture, its 2D context, and the
# canvas's black-silhouette twin for the shadow pass. The picture is the widget's ALONE, never
# composed with its children's: an inspector's would hold only its pane's background.
#
# A widget keeps one for one of two reasons:
#   1) as a CACHE, which pays off for a widget that has a small extent, an expensive paint and
#      frequent repaints. Text is the ideal case, painting glyphs being slow; the worst case is a
#      desktop-sized rectangle, where a lot of memory would hold a very short paint;
#   2) because the widget IS a raster: a canvas a turtle's pen draws on, a 3D render -- or any
#      widget whose pixels a filter works on.
# Which widgets keep one is each class's decision, not a dynamic one.
#
# A widget keeps ONE, in its `backBuffer` field, kept by its _createRefreshOrGetBackBuffer (a
# serialization transient: a restored widget makes its own at its first paint). A text's or a
# palette's is SHARED, through world.cacheForImmutableBackBuffers, with every text or palette drawn
# the same (the cache key is everything its pixels are a function of), so a BackBuffer holds NO
# widget: the widget it paints or is read for is handed to each call, and the class-side calls
# below are where a widget meets its buffer. The canvas family makes a NEW BackBuffer whenever it
# makes a new canvas (its first, a resize, an adopted drawing), so a BackBuffer's canvas never
# changes.

class BackBuffer

  # my raster, in physical pixels
  canvas: undefined
  # my canvas's 2D context. Named <name>Context beside <name> because that is how a canvas's context
  # is recognised and rebuilt by NAME (NativeValueKinds.isDerivedAt, CanvasRenderingContext2D
  # ::rebuildDerivedValue): a copy of me rebuilds its context off the copied canvas, and a save never
  # writes one -- so a BackBuffer restored from a file (one an inspector was open on) holds none
  # until pixelColorAt, its one reader here, takes it again.
  canvasContext: undefined
  # my canvas's black-silhouette twin for the shadow pass (the shadow-paint contract: per-pixel
  # coverage, chroma always black -- Widget.coffee "How the shadow painting works"), made on first
  # need and shared by every widget sharing me. My canvas never changes, so the twin goes stale only
  # when my raster is drawn on in place. CanvasWdgt's clear and drawLine say so (noteRasterChanged);
  # the other in-place drawers -- a stretchable canvas's repaint, a 3D frame, the paint tools --
  # do not, and their twin keeps the silhouette it was made with.
  _silhouette: undefined

  # the pair my maker already holds: each builder makes its canvas and context its own way (a
  # TextWdgt sizes its canvas after taking the context) and hands both over
  constructor: (@canvas, @canvasContext) ->

  # The paint of a widget whose picture IS its back buffer (a text's one line, CanvasAppearance,
  # the colour half of PaletteAppearance): only this very widget's image, never its children's
  # (fullPaintIntoAreaOrBlitFromBackBuffer descends them). Asked of the widget, in this order:
  # whether it is shown, then for its buffer -- built only for a shown widget --, then the blit.
  # Device-space, like every blit (the appearance paint convention's declared exception): a widget
  # whose picture is the cached raster PLUS something live composes it, drawing the live half over
  # the blit in the logical-pixels scope (PaletteAppearance's mark). Class-side, because a buffer
  # holds no widget.
  @blitOf: (aWdgt, aContext, clippingRectangle, appliedShadow) ->
    aWdgt.justBeforeBeingPainted?()

    if !aWdgt.visibleBasedOnIsVisibleProperty() or aWdgt.isInCollapsedSubtree()
      return undefined

    backBuffer = aWdgt._createRefreshOrGetBackBuffer()

    return undefined unless backBuffer?

    backBuffer.blitInto aContext, aWdgt, clippingRectangle, appliedShadow

  # The colour of aWdgt's picture at aPoint (a point in aWdgt's plane): its buffer, built if need be,
  # read at the widget-local point.
  @pixelColorOf: (aWdgt, aPoint) ->
    aWdgt._createRefreshOrGetBackBuffer().pixelColorAt aPoint.toLocalCoordinatesOf aWdgt

  # The SHAPE answer of a widget whose surface IS its raster (CanvasAppearance, PaletteAppearance):
  # the pointer is on it only where its picture has something drawn, so the question is answered
  # PER PIXEL rather than by an outline. TOTAL, as Appearance.shapeContainsPoint must be: false
  # outside aWdgt's bounds, where no pixel is read. (A widget whose raster is known to fill its box
  # answers catchesPointerAt itself with a plain bounds test -- cheaper, and the honest answer
  # there.)
  #   ⚠ MIND THE SPELLING, because the wrong one is silent: a Color keeps its alpha in `_a`
  # and publishes no `a`, so a `data.a is 0` test reads `undefined is 0` — false for every
  # pixel, which makes every widget answering this catch the pointer everywhere inside its
  # bounds and a click on a see-through pixel of a canvas or a palette never fall through.
  # isFullyTransparent is the question this wants to ask.
  @isPaintedAt: (aWdgt, aPoint) ->
    return false  unless aWdgt.boundsContainPoint aPoint
    not BackBuffer.pixelColorOf(aWdgt, aPoint).isFullyTransparent()

  # Draws my canvas -- or, in the shadow pass, its twin -- into aContext where aWdgt stands, over
  # the part of aWdgt that clippingRectangle asks for, at aWdgt's alpha.
  blitInto: (aContext, aWdgt, clippingRectangle, appliedShadow) ->
    [damageBox,sl,st,al,at,w,h] = @_keyValuesFor aWdgt, clippingRectangle
    return undefined if w < 1 or h < 1 or damageBox.isEmpty()

    aContext.save()

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * aWdgt.alpha

    # the shadow pass blits the buffer's black-silhouette twin, never the buffer's own
    # colours — a coloured string/palette/canvas re-tinted at shadow alpha is a ghost
    # copy, not a shadow (over a light background it LIGHTENS; the tilted-window bug's
    # shape). Per-pixel alpha (glyph AA, semi-transparent raster) carries through.
    sourceBuffer = if appliedShadow? then @_shadowSilhouette() else @canvas
    aContext.drawImage sourceBuffer,
      Math.round(sl),
      Math.round(st),
      Math.round(w),
      Math.round(h),
      Math.round(al),
      Math.round(at),
      Math.round(w),
      Math.round(h)

    aContext.restore()

    return

  # The colour of my raster at aLocalPoint (logical pixels, local to the widget I picture).
  pixelColorAt: (aLocalPoint) ->
    # Math.floor AFTER the ×ceilPixelRatio (affine transforms §4.6): a widget
    # inside a non-identity island is hit-tested at an INVERSE-mapped (float)
    # point, so the physical sample coords must be floored to an integer pixel.
    # For any ordinary (integer-pointer) hit test the product is already integer,
    # so the floor is a no-op ⇒ byte-identical when dormant.
    @canvasContext ?= @canvas.getContext "2d"
    data = @canvasContext.getImageData Math.floor(aLocalPoint.x * ceilPixelRatio), Math.floor(aLocalPoint.y * ceilPixelRatio), 1, 1
    # ⚠ THE ALPHA CHANGES UNITS HERE, and it is the only place in the tree that a Color is built
    # from raw image bytes. ImageData carries all four channels as 0..255; Color._a is contracted
    # as 0.0..1.0 (Color.coffee) and Color.create does not normalise, so the byte must be divided
    # HERE or every colour this hands out is out of contract by a factor of 255. The is-it-zero
    # question (isPaintedAt) cannot see the difference (0 is 0 either way) — what could is everyone else:
    # Color.toString gates its rgb-vs-rgba spelling on `_a == 1`, Color.equals compares the field,
    # Widget.opaqueCoveredRect refuses a coverage claim unless its fill colour's `_a == 1`, and a picked
    # colour is serialized. PaletteWdgt._rememberColorPickedAt takes its picked colour straight from here and
    # pushes it to a target, so an un-normalised 255 would ride all the way out to a widget's @color.
    Color.create data.data[0], data.data[1], data.data[2], data.data[3] / 255

  # My raster was drawn on IN PLACE (CanvasWdgt.clear, drawLine), so my twin is stale: the next
  # shadow pass makes a new one.
  noteRasterChanged: ->
    @_silhouette = undefined

  _shadowSilhouette: ->
    @_silhouette ?= HTMLCanvasElement.blackSilhouetteOf @canvas, WorldWdgt.theme.shadowColor


  # The blit's key values, [damageBox,sl,st,al,at,w,h]: the part of aWdgt that clippingRectangle
  # asks for, where it lies in my canvas (sl, st) and where in the target (al, at).
  # As seen by the " * ceilPixelRatio " parts in the code,
  # these are actual pixels, not logical pixels.
  # Hence, these values are only good outside of the
  # scope of the scaling due to the ceilPixelRatio.
  # The width and height are clamped to MY canvas: the clamp is the blit's, since a blit never
  # reads past its canvas (a text's canvas, sized by its text, can be smaller than its widget's box,
  # which is what Widget.calculateKeyValues clamps to).
  _keyValuesFor: (aWdgt, clippingRectangle) ->
    damageBox = clippingRectangle.intersect(aWdgt.boundingBox()).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if damageBox.isNotEmpty()
      delta = aWdgt.position().neg()
      src = damageBox.translateBy(delta).round()

      # the " * ceilPixelRatio " multiplications
      # transform logical pixels into actual pixels.
      sl = src.left() * ceilPixelRatio
      st = src.top() * ceilPixelRatio
      al = damageBox.left() * ceilPixelRatio
      at = damageBox.top() * ceilPixelRatio
      # @canvas.width and @canvas.height are already in
      # physical coordinates so no need to adjust for pixelratio
      w = Math.min(src.width() * ceilPixelRatio, @canvas.width - sl)
      h = Math.min(src.height() * ceilPixelRatio, @canvas.height - st)
    return [damageBox,sl,st,al,at,w,h]
