# like an UpperRightTriangle, but it adds an icon on the top-right

# to test this:
# create a canvas. then:
# new UpperRightTriangleIconicButton(world.children[0])

class UpperRightTriangleIconicButton extends UpperRightTriangle

  @augmentWith HighlightableMixin, @name

  color: Color.WHITE
  pencilIconMorph: nil

  constructor: (parent = nil) ->
    super
    @pencilIconMorph = new PencilIconMorph Color.BLACK

    @add @pencilIconMorph, nil, LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT
    @pencilIconMorph.proportionOfParent = 1/2
    @pencilIconMorph.fixedSize = 0
