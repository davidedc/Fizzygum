# A parameter object for a single menu row.
#
# MenuWdgt.addMenuItem / .prependMenuItem / .createMenuItem used to thread a
# dozen positional arguments straight into MenuItemWdgt's (17-arg) constructor,
# annotated with a per-argument trailing comment because the bare positional
# call was otherwise unreadable. This value object bundles those per-item fields
# under named slots, so the construction is self-documenting and the comment
# wall is gone.
#
# Note what is NOT here: the menu-level context (font, and the menu's
# environment) is supplied by the owning MenuWdgt when it builds the
# MenuItemWdgt -- it is the same for every row, so it does not belong on a
# per-row spec.
#
# The constructor defaults mirror the old createMenuItem signature exactly
# (closes-unpinned defaults true; bold / italic / representsAWidget default
# false) so callers that omit those arguments get identical behaviour.

class MenuItemSpec

  # labelString can also be a Widget or a Canvas or a tuple: [icon, string]
  label: nil
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  target: nil
  action: nil
  toolTipMessage: nil
  color: nil
  bold: false
  italic: false
  doubleClickAction: nil
  argumentToAction1: nil
  argumentToAction2: nil
  representsAWidget: false

  constructor: (@label, @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true, @target, @action, @toolTipMessage, @color, @bold = false, @italic = false, @doubleClickAction, @argumentToAction1, @argumentToAction2, @representsAWidget = false) ->
