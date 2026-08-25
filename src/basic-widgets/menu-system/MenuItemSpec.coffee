# A parameter object for a single menu row: it bundles the per-item fields that
# MenuItemWdgt's constructor needs, so a row is described by named slots rather
# than by a dozen unreadable positional arguments.
#
# SHALLOWLY IMMUTABLE — fields are never written after construction, but `target` /
# `action` / `icon` reference live widgets (see docs/architecture/immutable-value-classes.md).
#
# Note what is NOT here: the menu-level context (font, and the menu's
# subject) is supplied by the owning MenuWdgt when it builds the
# MenuItemWdgt -- it is the same for every row, so it does not belong on a
# per-row spec.
#
# CONSTRUCTOR SHAPE (docs/architecture/constructor-and-parameter-conventions.md):
# label / target / action are the identity -- what the row SAYS and what it DOES,
# passed by every caller -- so they stay positional. EVERY other field is an
# independently-optional knob and rides `opts`, however many of them there come to be.
#
# The opts KEYS are deliberately the ones MenuRowsPanelWdgt.addMenuItem already
# offers its callers (R4: an option is named for what the caller means, not for
# the field it lands in), which is what lets `_menuItemSpecFrom` forward its opts
# straight through instead of transcribing it into positional slots.

class MenuItemSpec

  # what the row SAYS: a STRING. What it SHOWS beside that is the `icon` slot below -- two named
  # slots, because a picture and a sentence are two facts and neither can be read out of the other.
  label: undefined
  # the widget the row shows at its left, inside a glyph box: a paint-only icon widget, or a live
  # tool's stand-in held inert (InertIconHolderWdgt). undefined for a label-only row, which is what
  # a row that asks for no picture is.
  icon: undefined
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  target: undefined
  action: undefined
  toolTipMessage: undefined
  color: undefined
  bold: false
  italic: false
  doubleClickAction: undefined
  argumentToAction1: undefined
  argumentToAction2: undefined
  representsAWidget: false
  # a MenuRowReflectionSpec when this row is a VIEW of somebody else's value (a tick, a wording
  # swap); undefined for an ordinary row whose label is fixed at build time
  reflection: undefined

  constructor: (@label, @target, @action, opts = {}) ->
    @icon = opts.icon
    @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = opts.closesUnpinnedPopUps ? true
    @toolTipMessage = opts.toolTip
    @color = opts.color
    @bold = opts.bold ? false
    @italic = opts.italic ? false
    @doubleClickAction = opts.doubleClickAction
    @argumentToAction1 = opts.arg1
    @argumentToAction2 = opts.arg2
    @representsAWidget = opts.representsAWidget ? false
    @reflection = opts.reflection
