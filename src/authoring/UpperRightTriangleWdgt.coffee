class UpperRightTriangleWdgt extends Widget

  constructor: (parent = nil, proportionOfParent = 4/8) ->
    super()
    @cornerSpec = new CornerInternalLayoutSpec 'topRight', proportionOfParent, 0
    @appearance = new UpperRightTriangleAppearance @

    # this widget has triangular shape and we want it
    # to only react to pointer events happening
    # within tha shape
    @noticesTransparentClick = false

    size = WorldWdgt.preferencesAndSettings.handleSize
    @__commitExtent new Point size, size
    parent?.add @, nil, @cornerSpec
