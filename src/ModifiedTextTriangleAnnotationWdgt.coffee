class ModifiedTextTriangleAnnotationWdgt extends Widget

  positionWithinParent: "topLeft"
  # my carrier-owned corner knob — the layoutSpec I hand my parent at add() time
  # (the pattern LayoutSpec.coffee names, alongside HandleWdgt.cornerSpec)
  cornerSpec: undefined

  # no colour of my own until one is set on me: until then I am painted in the code pane's
  # modified-mark role, read as I am painted (_surfaceFill), so a saved or duplicated code pane
  # wears the world's look
  color: undefined

  constructor: (parent, proportionOfParent = 0, fixedSize = 10) ->
    super()
    @cornerSpec = new CornerInternalLayoutSpec 'topLeft', proportionOfParent, fixedSize
    # my shape is a triangle, and reacting to the pointer only within that triangle
    # follows from the appearance answering shapeContainsPoint -- nothing to declare here
    @appearance = new UpperRightTriangleAppearance @, @positionWithinParent

    size = WorldWdgt.theme.handleSize
    @__commitExtent new Point size, size
    parent?.add @, layoutSpec: @cornerSpec

  # the fill my UpperRightTriangleAppearance paints my triangle in while I hold no colour of my own
  _surfaceFill: ->
    WorldWdgt.theme.codePaneModifiedMark

  # I attach directly to a viewport (not its plane / inner contents) when added -- the
  # container add methods key off this instead of instanceof ModifiedTextTriangleAnnotationWdgt.
  # (type-test-elimination campaign)
  attachesToViewportDirectly: -> true
