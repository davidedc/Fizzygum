# like an UpperRightTriangleWdgt, but it adds an icon on the top-right
#
# MY LOOK is the edit mark's (a paint tool's EditableMarkWdgt): my triangle's fill for my pointer
# state -- editMarkFill at rest, editMarkHoverFill hovered, editMarkPressFill pressed -- derived at
# each state change (_updateColor) and once as I am built, and the pencil on me in editMarkInk.

# to test this:
# create a canvas. then:
# new UpperRightTriangleIconicButtonWdgt(world.children[0])

class UpperRightTriangleIconicButtonWdgt extends UpperRightTriangleWdgt

  @augmentWith HighlightableMixin, @name

  constructor: (parent) ->
    super
    @_buildAndConnectChildren()
    @_updateColor()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    pencilIconWdgt = new PencilIconWdgt WorldWdgt.theme.editMarkInk

    @_addNoSettle pencilIconWdgt, layoutSpec: new CornerInternalLayoutSpec 'topRight', 1/2, 0

  # HighlightableMixin's colour hook, which every one of its state transitions calls after setting
  # @state: my triangle's fill for the state I am in now -- the state machine's own field for it
  # when one is set (a live edit of the mixin's field reaches me too), else the edit mark's role,
  # read here.
  _updateColor: ->
    theme = WorldWdgt.theme
    @color = switch @state
      when @STATE_HIGHLIGHTED then @color_hover ? theme.editMarkHoverFill
      when @STATE_PRESSED then @color_pressed ? theme.editMarkPressFill
      else @color_normal ? theme.editMarkFill
    @_changed()
