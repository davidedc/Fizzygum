class Appearance

  widget: nil
  # the ownColorInsteadOfWidgetColor is used for buttons
  # with icons on a glass bottom: the glass bottom has
  # to change the color on hover, so the icon_button on it
  # stain it, but they have to retain their color otherwise
  # they are not visible anymore.
  ownColorInsteadOfWidgetColor: nil

  constructor: (@widget, @ownColorInsteadOfWidgetColor) ->

  isTransparentAt: (aPoint) ->

  # _drawHighlightOverlay can work in two patterns:
  #  * passing actual pixels, when used
  #    outside the effect of the scope of
  #    "useLogicalPixelsUntilRestore()", or
  #  * passing logical pixels, when used
  #    inside the effect of the scope of
  #    "useLogicalPixelsUntilRestore()", or
  # Mostly, the first pattern is used.
  #
  # useful for example when hovering over references
  # to widgets. Can only modify the rendering of a widget,
  # so any highlighting is only visible in the measure that
  # the widget is visible (as opposed to HighlighterWdgt being
  # used to highlight a widget)
  _drawHighlightOverlay: (aContext, al, at, w, h) ->


  # Shared paint preamble for the appearance paint methods: bail (nil) if there is nothing to draw, else return
  # the [area,sl,st,al,at,w,h] key-values (nil when the widget is sub-pixel / off-clip). ZERO draw ops. Callers
  # that need it keep their own justBeforeBeingPainted?() after this. (RectangularAppearance's own paint is the
  # one exception that keeps this inline — it wedges its wallpaper hook between the two guards.)
  _calculateKeyValuesOrNil: (aContext, clippingRectangle) ->
    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil
    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()
    return [area,sl,st,al,at,w,h]

  # Shared "open a logical-pixels drawing box" for the boxy appearances (CircleBoxy / Boxy / UpperRightTriangle):
  # save, clip to the dirty rect, set the shadow-aware alpha, switch to logical pixels and translate to the
  # widget origin. Leaves the context SAVED (each caller restores) with the pen at the widget origin in logical
  # pixels. IconAppearance (a different translate+scale) and DragChargingRing (plain @widget.alpha) keep their own.
  _beginLogicalPixelsBox: (aContext, appliedShadow, al, at, w, h) ->
    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.alpha

    aContext.useLogicalPixelsUntilRestore()
    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y


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
