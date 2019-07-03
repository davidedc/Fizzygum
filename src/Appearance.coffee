# REQUIRES DeepCopierMixin

class Appearance

  @augmentWith DeepCopierMixin

  morph: nil
  # the ownColorInsteadOfWidgetColor is used for buttons
  # with icons on a glass bottom: the glass bottom has
  # to change the color on hover, so the icon_button on it
  # stain it, but they have to retain their color otherwise
  # they are not visible anymore.
  ownColorInsteadOfWidgetColor: nil

  constructor: (@morph, @ownColorInsteadOfWidgetColor) ->

  isTransparentAt: (aPoint) ->

  # paintHighlight can work in two patterns:
  #  * passing actual pixels, when used
  #    outside the effect of the scope of
  #    "scale ceilPixelRatio, ceilPixelRatio", or
  #  * passing logical pixels, when used
  #    inside the effect of the scope of
  #    "scale ceilPixelRatio, ceilPixelRatio", or
  # Mostly, the first pattern is used.
  #
  # useful for example when hovering over references
  # to morphs. Can only modify the rendering of a morph,
  # so any highlighting is only visible in the measure that
  # the morph is visible (as opposed to HighlighterMorph being
  # used to highlight a morph)
  paintHighlight: (aContext, al, at, w, h) ->


  # This method only paints this very morph
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
