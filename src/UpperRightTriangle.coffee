class UpperRightTriangle extends Widget

  @augmentWith CornerInternalHaloMixin, @name

  constructor: (parent = nil, @layoutSpec_cornerInternal_proportionOfParent = 4/8) ->
    super()
    @layoutSpec_cornerInternal_fixedSize = 0
    @appearance = new UpperRightTriangleAppearance @

    # this morph has triangular shape and we want it
    # to only react to pointer events happening
    # within tha shape
    @noticesTransparentClick = false

    size = WorldMorph.preferencesAndSettings.handleSize
    @silentRawSetExtent new Point size, size
    parent?.add @, nil, LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT
