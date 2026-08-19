class ModifiedTextTriangleAnnotationWdgt extends Widget

  positionWithinParent: "topLeft"
  # my carrier-owned corner knob — the layoutSpec I hand my parent at add() time
  # (the pattern LayoutSpec.coffee names, alongside HandleWdgt.cornerSpec)
  cornerSpec: undefined

  constructor: (parent, proportionOfParent = 0, fixedSize = 10) ->
    super()
    @cornerSpec = new CornerInternalLayoutSpec 'topLeft', proportionOfParent, fixedSize
    @appearance = new UpperRightTriangleAppearance @, @positionWithinParent

    # this widget has triangular shape and we want it
    # to only react to pointer events happening
    # within tha shape
    @noticesTransparentClick = false

    size = WorldWdgt.preferencesAndSettings.handleSize
    @__commitExtent new Point size, size
    parent?.add @, layoutSpec: @cornerSpec

  # I attach directly to a scroll panel's frame (not its inner contents) when added -- the
  # container add methods key off this instead of `instanceof ModifiedTextTriangleAnnotationWdgt`.
  # (type-test-elimination campaign)
  attachesToViewportDirectly: -> true
