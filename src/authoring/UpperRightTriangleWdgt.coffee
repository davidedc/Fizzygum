class UpperRightTriangleWdgt extends Widget

  # my carrier-owned corner knob — the layoutSpec I hand my parent at add() time
  # (the pattern LayoutSpec.coffee names, alongside HandleWdgt.cornerSpec)
  cornerSpec: undefined

  constructor: (parent, proportionOfParent = 4/8) ->
    super()
    @cornerSpec = new CornerInternalLayoutSpec 'topRight', proportionOfParent, 0
    # my shape is a triangle, and reacting to the pointer only within that triangle
    # follows from the appearance answering shapeContainsPoint -- nothing to declare here
    @appearance = new UpperRightTriangleAppearance @

    size = WorldWdgt.preferencesAndSettings.handleSize
    @__commitExtent new Point size, size
    parent?.add @, layoutSpec: @cornerSpec
