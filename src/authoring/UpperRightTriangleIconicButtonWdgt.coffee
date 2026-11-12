# like an UpperRightTriangleWdgt, but it adds an icon on the top-right
#
# MY LOOK is the edit mark's (a paint tool's EditableMarkWdgt): my triangle's fill for my pointer
# state -- editMarkFill at rest, editMarkHoverFill hovered, editMarkPressFill pressed -- asked of the
# hand as I am painted (_fillForMyState), and the pencil on me in editMarkInk.

# to test this:
# create a canvas. then:
# new UpperRightTriangleIconicButtonWdgt(world.children[0])

class UpperRightTriangleIconicButtonWdgt extends UpperRightTriangleWdgt

  # my triangle's fill for each pointer state, when one is set on me (a live edit); unset, each is
  # the edit mark's role, read as I am painted (_fillForMyState)
  color_normal: undefined
  color_hover: undefined
  color_pressed: undefined

  constructor: (parent) ->
    super
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    pencilIconWdgt = new PencilIconWdgt WorldWdgt.theme.editMarkInk

    @_addNoSettle pencilIconWdgt, layoutSpec: new CornerInternalLayoutSpec 'topRight', 1/2, 0

  # MY TRIANGLE'S FILL for the pointer state I show now, which my UpperRightTriangleAppearance asks as
  # it paints: pressed while the hand presses me (ActivePointerWdgt.pressesOn), hovered while the
  # pointer rests on me (restsOn), at rest otherwise -- my field for that state when one is set, else
  # the edit mark's role, read here.
  _fillForMyState: ->
    theme = WorldWdgt.theme
    if world.hand.pressesOn @
      @color_pressed ? theme.editMarkPressFill
    else if world.hand.restsOn @
      @color_hover ? theme.editMarkHoverFill
    else
      @color_normal ? theme.editMarkFill

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): my fill
  # is read from them as I am painted, so I repaint.
  notePointerStateChanged: ->
    @_changed()
