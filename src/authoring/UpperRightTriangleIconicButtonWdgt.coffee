# like an UpperRightTriangleWdgt, but it adds an icon on the top-right

# to test this:
# create a canvas. then:
# new UpperRightTriangleIconicButtonWdgt(world.children[0])

class UpperRightTriangleIconicButtonWdgt extends UpperRightTriangleWdgt

  @augmentWith HighlightableMixin, @name

  color: Color.WHITE

  constructor: (parent = nil) ->
    super
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    pencilIconWdgt = new PencilIconWdgt Color.BLACK

    @_addNoSettle pencilIconWdgt, layoutSpec: LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT
    pencilIconWdgt.layoutSpec_cornerInternal_proportionOfParent = 1/2
    pencilIconWdgt.layoutSpec_cornerInternal_fixedSize = 0
