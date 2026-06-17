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


  # This method only paints this very widget
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
