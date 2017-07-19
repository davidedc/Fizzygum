# Appearance //////////////////////////////////////////////////////////////

# REQUIRES DeepCopierMixin

class Appearance
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

  morph: null

  constructor: (@morph) ->

  isTransparentAt: (aPoint) ->

  # paintHighlight can work in two patterns:
  #  * passing actual pixels, when used
  #    outside the effect of the scope of
  #    "scale pixelRatio, pixelRatio", or
  #  * passing logical pixels, when used
  #    inside the effect of the scope of
  #    "scale pixelRatio, pixelRatio", or
  # Mostly, the first pattern is used.
  paintHighlight: (aContext, al, at, w, h) ->


  # This method only paints this very morph
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
