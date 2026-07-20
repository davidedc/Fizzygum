# The difference between this and a Canvas is that once the
# user starts to paint on the StretchableCanvas, it locks the
# aspect ratio... and any further resizing keeps the original
# painting and the user can keep painting at any new scale...
#
# This is achieved by keeping an extra canvas behind the scenes
# that keeps the original resolution of when the first paint
# action happened. The user keeps painting on that "behind
# the scenes canvas" with the original resolution, no matter
# what the scale of the "front facing" canvas is on screen.
# So any time the user resizes the front canvas or she paints
# on the "behind the scenes", the "behind the scenes"
# is painted on the front one at the correct scale.
#
# Note that since the "behind the scenes" canvas
# keeps the same size... if the user starts painting
# when the size is small... then enlarging the canvas
# will just cause the smaller "behind the scenes" canvas
# to be painted on the smaller "front facing" canvas...
# so everything new will be painted blurry.
#
# You could enhance this so that if the user scales up
# the canvas, then the "behind the scenes" is also
# resized-up (previous content will be blurry but new
# content will be sharp).

class StretchableCanvasWdgt extends CanvasWdgt

  anythingPaintedYet: false
  extentWhenCanvasGotDirty: nil

  behindTheScenesBackBuffer: nil
  behindTheScenesBackBufferContext: nil


  # No changes of position or extent should be
  # performed in here.
  # There is really little hope to cache this buffer
  # cross-widget, unless you key the buffer with the
  # order of all the primitives and their
  # parameters. So if user wants a cache it will have to specify
  # a dedicated one in here. See textWidget for an example.
  _createRefreshOrGetBackBuffer: ->

    extent = @extent()

    if !@backBuffer?
      @_createNewFrontFacingBuffer extent

    # little shortcut: if nothing has been painted yet then
    # we can omit painting the big canvas on the small one,
    # just clean up the small canvas
    if !@anythingPaintedYet and @color?
      @backBufferContext.fillStyle = @color.toString()
      @backBufferContext.fillRect 0, 0, extent.x * ceilPixelRatio, extent.y * ceilPixelRatio

    # if something *has* been painted then
    # we need to paint the "behind the scenes" buffer into the
    # one we show on screen
    if @anythingPaintedYet
      @backBufferContext.setTransform 1, 0, 0, 1, 0, 0
      @backBufferContext.scale @width()/@extentWhenCanvasGotDirty.x, @height()/@extentWhenCanvasGotDirty.y
      @backBufferContext.drawImage @behindTheScenesBackBuffer, 0, 0

    
    # we leave the context with the correct pixel scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @backBufferContext.useLogicalPixelsUntilRestore()
    return [@backBuffer, @backBufferContext]


  # don't need this at the moment, you'd need to
  # clear both backbuffers and invoke a @parent?.resetRatio?()
  # since once it's empty you can really let the user re-think
  # the aspect ratio of her painting
  clear: (color = @color) ->
    throw new Error "not implemented yet"

  _createNewBehindTheScenesBuffer: (extent) ->
    @behindTheScenesBackBuffer = HTMLCanvasElement.createOfPhysicalDimensions extent.scaleBy ceilPixelRatio
    @behindTheScenesBackBufferContext = @behindTheScenesBackBuffer.getContext "2d"

    if @color?
      @behindTheScenesBackBufferContext.fillStyle = @color.toString()
      @behindTheScenesBackBufferContext.fillRect 0, 0, extent.x * ceilPixelRatio, extent.y * ceilPixelRatio

    # we leave the context with the correct scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @behindTheScenesBackBufferContext.useLogicalPixelsUntilRestore()

  _createNewFrontFacingBuffer: (extent) ->
    @backBuffer = HTMLCanvasElement.createOfPhysicalDimensions extent.scaleBy ceilPixelRatio
    @backBufferContext = @backBuffer.getContext "2d"


    # we leave the context with the correct scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @backBufferContext.useLogicalPixelsUntilRestore()


  # Reconcile my paint buffers to the COMMITTED extent on every real resize (the schedule-valve
  # arc; see docs/archive/layout-system-architecture-assessment.md §10). Guarded on the front
  # buffer's physical size vs my extent, so an unchanged-frame re-lay never touches the buffers.
  # The behind-the-scenes buffer -- the user's PAINTING -- is deliberately kept once anything is
  # painted: recreating it would erase the strokes.
  _reLayoutSelf: ->
    super
    targetPhysicalExtent = @extent().scaleBy ceilPixelRatio
    unless @backBuffer? and @backBuffer.width == targetPhysicalExtent.x and @backBuffer.height == targetPhysicalExtent.y
      if !@behindTheScenesBackBuffer? or !@anythingPaintedYet
        @_createNewBehindTheScenesBuffer @extent()
      @_createNewFrontFacingBuffer @extent()


  getContextForPainting: ->
    # only set ratio with the first paint operation
    # the following ones don't change it
    if @parent?.setRatio? and !@parent.ratio?
      @parent.setRatio @width() / @height()
      @extentWhenCanvasGotDirty = @extent()
      @anythingPaintedYet = true

    @behindTheScenesBackBufferContext.setTransform 1, 0, 0, 1, 0, 0
    @behindTheScenesBackBufferContext.useLogicalPixelsUntilRestore()

    @behindTheScenesBackBufferContext.scale @extentWhenCanvasGotDirty.x/@width(), @extentWhenCanvasGotDirty.y/@height()

    @behindTheScenesBackBufferContext.translate -@bounds.origin.x, -@bounds.origin.y
    return @behindTheScenesBackBufferContext

  # TODO don't need this at the moment, you'd need to
  # paint on the "behind the scenes" backbuffer
  #
  # TODO id: DRAW_LINE_SHOULD_BE_IN_TURTLE_NOT_IN_CANVAS date: 3-May-2023 description:
  # the turtle should implement this, not the canvas, because otherwise the
  # canvas is also going to get all kinds of ther methods e.g. drawCircle
  # which are not really needed by all Canvas subclasses, and rather seem
  # specific to the turtle
  drawLine: (start, dest, lineWidth, color) ->
    throw new Error "not implemented yet"

  _paintImage: (pos, image) ->
    # public-call-sanctioned: getContextForPainting is public canvas API — user-facing injected
    # live-code calls it (PaintToolbarWdgt's tool sources), so it stays public.

    extent = @extent()
    if !@backBuffer?
      @_createNewFrontFacingBuffer extent

    if !@behindTheScenesBackBuffer?
      @_createNewBehindTheScenesBuffer extent

    contextForPainting = @getContextForPainting()

    # Hi-dpi: the widget image is 2x logical size, but pos (from the mouse) is logical.
    # Undo the 2x scale here, then re-apply it explicitly just for the positioning below.

    @behindTheScenesBackBufferContext.scale 1/ceilPixelRatio, 1/ceilPixelRatio
    contextForPainting.drawImage image, pos.x * ceilPixelRatio, pos.y * ceilPixelRatio

    # put back the scaling so it's right again.
    # (always leave the scaling correct)
    # TODO: you could use a save() / restore() here to avoid
    # the anti-scaling followed by re-scaling introducing any artifacts
    # due to rounding errors
    @behindTheScenesBackBufferContext.useLogicalPixelsUntilRestore()

  # Runs inside the drop's single settle: re-home the dropped widget through the non-settling add core.
  _reactToChildDropped: (droppedWidget) ->
    @_paintImage droppedWidget.position(), droppedWidget.fullImage(nil, false, true)
    world._addNoSettle droppedWidget, beingDropped: true
  
  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this widget are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    for w in childrenNotHandlesNorCarets
      w._applyBounds @bounds


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()

