class ModifiedTextTriangleAnnotationWdgt extends Widget

  positionWithinParent: "topLeft"
  # my carrier-owned corner knob — the layoutSpec I hand my parent at add() time
  # (the pattern LayoutSpec.coffee names, alongside HandleWdgt.cornerSpec)
  cornerSpec: undefined

  constructor: (parent, proportionOfParent = 0, fixedSize = 10) ->
    super()
    @cornerSpec = new CornerInternalLayoutSpec 'topLeft', proportionOfParent, fixedSize
    # my shape is a triangle, and reacting to the pointer only within that triangle
    # follows from the appearance answering shapeContainsPoint -- nothing to declare here
    @appearance = new UpperRightTriangleAppearance @, @positionWithinParent

    size = WorldWdgt.preferencesAndSettings.handleSize
    @__commitExtent new Point size, size
    parent?.add @, layoutSpec: @cornerSpec

  # I attach directly to a viewport (not its plane / inner contents) when added -- the
  # container add methods key off this instead of instanceof ModifiedTextTriangleAnnotationWdgt.
  # (type-test-elimination campaign)
  attachesToViewportDirectly: -> true
