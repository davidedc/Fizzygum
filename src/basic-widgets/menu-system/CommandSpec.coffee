# THE COMMAND RECORD: one thing a user can ask for -- what it SAYS, what it SHOWS, and what it
# DOES -- described by named slots rather than by a dozen unreadable positional arguments. It
# bundles the per-item fields MenuItemWdgt's constructor needs, and a menu row is the PROJECTION
# of it that CommandPanelWdgt builds. A toolbar's grid cell is the other projection of the same
# idea, arrived at from the other end: a cell shows a tool rather than a record. What makes the
# two one model rather than two families is the law below -- they agree about what ACTING means.
#
# ── THE DISPATCH CONTRACT (this model's law) ────────────────────────────────────────────────
# A PROJECTION OF A COMMAND INVOKES THE SAME ACTION PATH AS THE PRIMARY PROJECTION. There is no
# second way to act and no per-family case; two implementations answer it:
#  - a spec-built ROW runs the four-slot dispatch this record carries (target / action /
#    argumentToAction1 / argumentToAction2) -- MenuItemWdgt, on the ButtonWdgt trigger;
#  - a grid CELL answers `thumbnailClickReceiver()` (src/GlassBoxBottomWdgt.coffee): the widget a
#    TAP on the cell actually reaches, which is the LID over a drag-out thumbnail, or the tool
#    itself where the tool handles its own clicks.
# So a surface RE-projecting somebody else's commands asks the cell what a tap on it reaches and
# clicks THAT, instead of reaching past it for the tool -- which would leave every lid-covered
# tool inert. The live consumer is OverflowChevronButtonWdgt.triggerToolFromMenu
# (src/app-kit/OverflowChevronButtonWdgt.coffee), which projects a strip's hidden cells as rows
# of this record. A NEW projection surface belongs on this law, not beside it.
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
# The opts KEYS are deliberately the ones CommandPanelWdgt.addMenuItem already
# offers its callers (R4: an option is named for what the caller means, not for
# the field it lands in), which is what lets `_commandSpecFrom` forward its opts
# straight through instead of transcribing it into positional slots.

class CommandSpec

  # what the row SAYS: a STRING, its plain wording. What it SHOWS beside that is the `icon` slot
  # below, and the marks its indicators draw (`opensSubmenu`, `ticked` / `reflection`) -- named
  # slots, because a picture, a mark and a sentence are separate facts and none can be read out of
  # another.
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
  # does the row NAME a widget — its argumentToAction1 when it carries one, else its target? Such a
  # row highlights that widget on hover and is found by it (MenuItemWdgt.representedWidget).
  representsAWidget: false
  # a MenuRowReflectionSpec when this row is a VIEW of somebody else's value -- ticked while that
  # value is the row's choice; undefined for an ordinary row
  reflection: undefined
  # does the row OPEN A SUBMENU? Its builder's to state (`opensSubmenu: true`), because what an
  # action does cannot be read off its name; the row then draws its chevron. A fact about what the
  # row DOES, so it travels with the record, and the label stays its plain wording.
  opensSubmenu: false
  # the row's tick when the BUILDER knows it: true or false for a row ticked or not by
  # construction (`ticked:`), undefined for one that never ticks. A row whose tick follows a live
  # value takes a `reflection` instead.
  ticked: undefined
  # what a MEMBER row (MemberRowWdgt) shows of its member beside the label, which names it: its
  # KIND TAG, a short word its builder chooses ("fn", "var"), and whether the name is DIMMED (shown
  # in a muted ink). Facts about the member, so they travel with the record; any other row ignores
  # them.
  kindTag: undefined
  dimmed: false

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
    @opensSubmenu = opts.opensSubmenu ? false
    @ticked = opts.ticked
    @kindTag = opts.kindTag
    @dimmed = opts.dimmed ? false
