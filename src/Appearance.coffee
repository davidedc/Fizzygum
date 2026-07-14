class Appearance

  @augmentWith DeepCopierMixin

  widget: nil
  # the ownColorInsteadOfWidgetColor is used for buttons
  # with icons on a glass bottom: the glass bottom has
  # to change the color on hover, so the icon_button on it
  # stain it, but they have to retain their color otherwise
  # they are not visible anymore.
  ownColorInsteadOfWidgetColor: nil

  constructor: (@widget, @ownColorInsteadOfWidgetColor) ->

  isTransparentAt: (aPoint) ->

  # paintHighlight can work in two patterns:
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
  paintHighlight: (aContext, al, at, w, h) ->


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


  # This method only paints this very widget
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
