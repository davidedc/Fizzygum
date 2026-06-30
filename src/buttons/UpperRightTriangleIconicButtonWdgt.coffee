# like an UpperRightTriangleWdgt, but it adds an icon on the top-right

# to test this:
# create a canvas. then:
# new UpperRightTriangleIconicButtonWdgt(world.children[0])

class UpperRightTriangleIconicButtonWdgt extends UpperRightTriangleWdgt

  @augmentWith HighlightableMixin, @name

  color: Color.WHITE
  pencilIconWdgt: nil

  constructor: (parent = nil) ->
    super
    @pencilIconWdgt = new PencilIconWdgt Color.BLACK

    @_addNoSettle @pencilIconWdgt, nil, LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT
    @pencilIconWdgt.layoutSpec_cornerInternal_proportionOfParent = 1/2
    @pencilIconWdgt.layoutSpec_cornerInternal_fixedSize = 0
