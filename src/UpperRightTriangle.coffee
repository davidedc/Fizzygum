# UpperRightTriangle ////////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions
# REQUIRES UpperRightInternalHaloMixin
#

# doesn't really work as a fully-fledged button, but
# buttons do hover/pressed states, which is handy
# to have.

class UpperRightTriangle extends EmptyButtonMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype


  @augmentWith UpperRightInternalHaloMixin

  constructor: (parent = null) ->
    super()
    @appearance = new UpperRightTriangleAppearance @

    # this morph has triangular shape and we want it
    # to only react to pointer events happening
    # within tha shape
    @noticesTransparentClick = false

    size = WorldMorph.preferencesAndSettings.handleSize
    @silentRawSetExtent new Point size, size
    if parent
      parent.add @
    @updateResizerPosition()


