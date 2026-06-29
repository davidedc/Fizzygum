class ModifiedTextTriangleAnnotationWdgt extends Widget

  @augmentWith CornerInternalHaloMixin, @name
  positionWithinParent: "topLeft"

  constructor: (parent = nil, @layoutSpec_cornerInternal_proportionOfParent = 0, @layoutSpec_cornerInternal_fixedSize = 10) ->
    super()
    @appearance = new UpperRightTriangleAppearance @, @positionWithinParent

    # this widget has triangular shape and we want it
    # to only react to pointer events happening
    # within tha shape
    @noticesTransparentClick = false

    size = WorldWdgt.preferencesAndSettings.handleSize
    @_commitExtentAndNotify new Point size, size
    parent?.add @, nil, LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPLEFT

  # I attach directly to a scroll panel's frame (not its inner contents) when added -- the
  # container add methods key off this instead of `instanceof ModifiedTextTriangleAnnotationWdgt`.
  # (type-test-elimination campaign)
  attachesToScrollFrameDirectly: -> true
