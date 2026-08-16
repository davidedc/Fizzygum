# The base of the pluggable per-widget painters. The paint convention (the law, its
# rationale, and the declared device-space exceptions) is in
# docs/architecture/appearance-paint-convention.md: a body draws its widget's OWN pixels
# in widget-local LOGICAL coordinates through the ctx matrix, inside _paintInLocalScope
# below — device-space business (damage clipping, blits, the shadow-silhouette fallback)
# belongs to the preamble, never to bodies.
class Appearance

  widget: undefined

  # ===== the two _paintInLocalScope knobs, DECLARED per class =====
  # Neither varies between paints of the same appearance, so both are class-level facts rather than
  # call arguments (the field-as-truth idiom used for claimsSpace / laysIconsHorizontallyInGrid).
  #
  # @alphaPolicy — which globalAlpha the scope establishes:
  #   undefined — the shadow-aware product (appliedShadow.alpha or 1) × widget alpha (the norm)
  #   "none"    — untouched; the body paints at the ambient alpha (the sheet cells' edge/ring chrome)
  #   "backgroundTransparencyNormalPass" — @widget.backgroundTransparency, normal pass only (the
  #               plot family: in the shadow pass the body's simpleShadow sets its own)
  alphaPolicy: undefined
  #
  # @clipsToLocalArea — does the scope clip to the damage box? RectangularAppearance declares FALSE:
  # its legacy device paint never clipped (its fills/stroke bound themselves to damage∩tight), and
  # adding the clip is NOT free of pixels — in an island buffer the ambient translate can be
  # FRACTIONAL (a fractional slot origin), where the clip's own boundary quantization differs from
  # the fills' and can cut an edge column (found at dpr 2, macroDropIntoRotatedStretchablePanel…).
  clipsToLocalArea: true
  # the ownColorInsteadOfWidgetColor is used for buttons
  # with icons on a glass bottom: the glass bottom has
  # to change the color on hover, so the icon_button on it
  # stain it, but they have to retain their color otherwise
  # they are not visible anymore.
  ownColorInsteadOfWidgetColor: undefined

  constructor: (@widget, @ownColorInsteadOfWidgetColor) ->

  isTransparentAt: (aPoint) ->

  # The key-values half of the paint preamble: bail (undefined) if there is nothing to draw, else return
  # the [area,sl,st,al,at,w,h] key-values (undefined when the widget is sub-pixel / off-clip). ZERO draw
  # ops. _paintInLocalScope below consumes it; RectangularAppearance's paint also calls it directly
  # as an early bail that gates its post-scope stroke + wallpaper epilogues.
  _calculateKeyValuesOrNil: (aContext, clippingRectangle) ->
    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return undefined
    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return undefined if w < 1 or h < 1 or area.isEmpty()
    return [area,sl,st,al,at,w,h]

  # THE one appearance paint scope (the appearance paint convention): undefined when there is nothing
  # to draw, else runs
  #   bodyFn aContext, localArea, appliedShadow
  # inside save → damage clip → alpha → logical pixels → translate to the widget position, then
  # restores. The body draws the widget's OWN pixels in widget-local LOGICAL coordinates through
  # the ctx matrix; localArea is the damage box as a widget-local logical rect (integer) for
  # partial-repaint fills. Device-space business (the damage clip here, back-buffer blits, the
  # shadow-silhouette fallback) stays OUT of bodies — a body never sees al/at.
  # (IconAppearance keeps its own scope: a different translate+scale into its 200×200 spec space.)
  #
  # The two knobs are DECLARED BY THE CLASS (@alphaPolicy / @clipsToLocalArea below), not passed per
  # call, because no appearance varies them between paints — each one wants a fixed policy for its
  # whole life. Declaring them keeps this signature at four operands with the block LAST, which is
  # what the CoffeeScript block idiom needs; carrying them as a bag in front of the block instead
  # made every default caller write `undefined` to reach past it (R3 of
  # docs/architecture/constructor-and-parameter-conventions.md — 8 of the 14 callers did).
  _paintInLocalScope: (aContext, clippingRectangle, appliedShadow, bodyFn) ->
    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return undefined unless keyValues?
    [area,sl,st,al,at,w,h] = keyValues

    # soft hook, only CaretWdgt defines it (the inert paint-time re-place); same slot it always
    # ran in: after the key values, before any ctx op
    @widget.justBeforeBeingPainted?()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box.
    if @clipsToLocalArea
      aContext.clipToRectangle al,at,w,h

    if @alphaPolicy == "backgroundTransparencyNormalPass"
      if !appliedShadow?
        # `? 1`: an absent backgroundTransparency means fully opaque (Widget's class-level
        # default) — never hand the canvas an undefined. See the note in
        # StringWdgt::_prepareTextBufferContext: an invalid globalAlpha is not necessarily
        # loud, and relying on "the previous value stands" would silently paint at whatever
        # alpha the ambient context happened to carry.
        aContext.globalAlpha = @widget.backgroundTransparency ? 1
    else if @alphaPolicy != "none"
      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.alpha

    aContext.useLogicalPixelsUntilRestore()
    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y

    bodyFn aContext, area.translateBy(widgetPosition.neg()), appliedShadow

    aContext.restore()

  # Fill a widget-local rect SNAPPED to the device-pixel grid — the quantization contract a
  # device-space fill carries, i.e. each edge Math.round()ed to a whole device pixel. For the
  # normal integer-geometry widget the snap is the identity (bit-exact same fill). It exists
  # for the widgets whose PLANE position is legitimately FRACTIONAL — a payload dropped into a
  # rotated container lands at the inverse-mapped screen point (the reparent-transparency
  # figure), fractional in general — where handing the raw fractional rect to the rasterizer
  # rounds edges differently (ceil(v−0.5) boundaries) than the legacy Math.round did, shifting
  # a fill edge by 1 device px (found at dpr 2, macroDropIntoRotatedStretchablePanel…). The
  # C1 float-arithmetic case law: docs/architecture/integer-pixel-placement-and-sizing.md §5.
  _fillLocalRectSnappedToDevicePixels: (ctx, localRect) ->
    widgetPosition = @widget.position()
    l = Math.round (localRect.left() + widgetPosition.x) * ceilPixelRatio
    t = Math.round (localRect.top() + widgetPosition.y) * ceilPixelRatio
    w = Math.round localRect.width() * ceilPixelRatio
    h = Math.round localRect.height() * ceilPixelRatio
    ctx.fillRect l / ceilPixelRatio - widgetPosition.x, t / ceilPixelRatio - widgetPosition.y, w / ceilPixelRatio, h / ceilPixelRatio


  # Shadow-pass wrapper for appearances whose art sets its own colours internally (icons,
  # the analog clock) — where the boxy pattern of swapping ONE fill to Color.BLACK cannot
  # reach the art's colours. Renders `paintColoredArt` (the appearance's NORMAL, full-colour
  # painting; receives the scratch context, pre-translated so the art's usual absolute device
  # coordinates land in the scratch) into a scratch canvas of just the DAMAGED area (w×h
  # device px — cost tracks damage, not widget size), blackens it in place, and blits it at
  # the shadow alpha. This honours the shadow-pass PAINT contract (Widget.coffee "How the
  # shadow painting works": per-pixel coverage, chroma always black) with zero per-primitive
  # colour surgery, so future art changes stay contract-true for free. The art must paint
  # EXACTLY as its normal (non-shadow) path does, @widget.alpha included — per-pixel opacity
  # carries into the silhouette, so the blit applies ONLY the shadow's own alpha on top
  # (total = appliedShadow.alpha × widget alpha, the recursive pass's formula, not squared).
  _paintDamagedAreaAsBlackSilhouette: (aContext, al, at, w, h, appliedShadow, paintColoredArt) ->
    scratch = HTMLCanvasElement.createOfPhysicalDimensions new Point w, h
    sctx = scratch.getContext "2d"
    sctx.translate -al, -at
    paintColoredArt sctx
    HTMLCanvasElement.blackenIntoSilhouetteInPlace scratch
    aContext.save()
    aContext.globalAlpha = appliedShadow.alpha
    aContext.drawImage scratch, 0, 0, w, h, al, at, w, h
    aContext.restore()

  # This method only paints this very widget
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
