# I automatically determine my bounds

# A menu row. It extends LabelButtonWdgt (the flat label-bearing button base, on
# the modern ButtonWdgt family) and adds the menu-specific behaviour: a
# self-sizing multi-line TextWdgt label, tick toggling, list-row selection, and
# the "represents a widget" hover-highlight.

class MenuItemWdgt extends LabelButtonWdgt

  # Built from a MenuItemSpec (the per-item fields) plus the menu-level context
  # the owning MenuWdgt supplies: the font (size / style), whether the label is
  # centered, and the menu's environment (which maps onto the button family's
  # "environment" / widgetEnv slots). We unpack the spec onto LabelButtonWdgt's
  # positional constructor here; an absent spec.label falls back to "close" (the
  # historical default). (spec.label may itself be a Widget, a Canvas, or an
  # [icon, string] tuple.)
  constructor: (menuItemSpec, fontSize, fontStyle, centered, environment, widgetEnv) ->
    super menuItemSpec.ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, menuItemSpec.target, menuItemSpec.action, (menuItemSpec.label or "close"), fontSize, fontStyle, centered, environment, widgetEnv, menuItemSpec.toolTipMessage, menuItemSpec.color, menuItemSpec.bold, menuItemSpec.italic, menuItemSpec.doubleClickAction, menuItemSpec.argumentToAction1, menuItemSpec.argumentToAction2, menuItemSpec.representsAWidget
    @actionableAsThumbnail = true

  # As a menu/list ROW I am the selectable UNIT (and I stretch FULL-WIDTH in a list), but a click lands on
  # my tight LABEL child. So the editor-focus selection frame must hug ME, not the label's text bounds
  # (owner: a tight-text highlight is visual noise). WorldWdgt._widgetBeingEdited resolves a selected
  # descendant (my label) up to me through this. Capability, not an `instanceof MenuItemWdgt` type-test
  # (type-test-elimination convention — the same reason my glass-box sizing uses a capability, above).
  absorbsDescendantEditorSelection: -> true

  # In a glass box I am sized to my (variable-width) text, not laid out as a square
  # thumbnail like other contents -- the glass-box layout in GlassBoxBottomWdgt
  # keys off this instead of `instanceof MenuItemWdgt`.
  # (type-test-elimination campaign)
  isTextSizedGlassBoxItem: ->
    true

  # reset my selection highlight (called for every menu child by MenuWdgt.unselectAllItems,
  # replacing its `if item instanceof MenuItemWdgt`). (type-test-elimination campaign)
  unselect: ->
    @state = @STATE_NORMAL

  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of menu item)"
    if @labelString
      textWithoutLocationOrInstanceNo = @labelString.replace /#\d*/, ""
      return textWithoutLocationOrInstanceNo + " (text in button)"
    else
      return super()

  # in theory this would be the right thing to do
  # but a bunch of tests break and it's not worth it
  # as we are going to remake the whole layout system anyways
  #_reLayoutSelf: ->
  #  @label.setExtent @extent().subtract (@label.bounds.origin.subtract @.bounds.origin)

  # MenuItemWdgt hugs its box to its (multi-line, modern TextWdgt) label -- the
  # opposite of LabelButtonWdgt's default single-line StringWdgt label, which
  # leaves the box alone.
  _createLabel: ->
    @label = new TextWdgt @labelString, @fontSize, @fontStyle
    @label.setColor @labelColor

    # _addNoSettle (NOT add): _createLabel is driven by _reLayoutSelf (a layout pass), so a
    # self-settle here would re-enter the flush guard and throw.
    @_addNoSettle @label
    # the modern family does not self-size; make the label hug its text before
    # we read @label.extent() below to size this menu item around it. _createLabel is driven by
    # _reLayoutSelf (a layout pass), so use the NoSettle core -- the wrapper would throw mid-pass.
    @label._sizeToTextAndDisableFittingNoSettle()

    w = @width()
    @__commitExtent @label.extent().add new Point 8, 0
    @__commitWidth w
    np = @position().add new Point 4, 0
    @label.__commitMoveTo np

  isTicked: ->
    @label.text.isTicked()

  toggleTick: ->
    if @label.text.isTicked()
      @label.text = @label.text.toggleTick()
      # _reLayoutSelf is a base no-op on the modern TextWdgt, so it would leave the
      # ticked/unticked label at a stale width; re-measure and re-size instead.
      @label.sizeToTextAndDisableFitting()
      # cross-invalidation-sanctioned: own sub-part — the label's text was poked directly above
      @label._changed()
    else if @label.text.isUnticked()
      @label.text = @label.text.toggleTick()
      @label.sizeToTextAndDisableFitting()
      # cross-invalidation-sanctioned: own sub-part — the label's text was poked directly above
      @label._changed()

  # As a menu entry, prefer my (multi-line TextWdgt) label's width plus a little
  # padding. MenuWdgt.maxWidthOfMenuEntries calls this polymorphically rather
  # than type-checking the entry. The label is @children[0]; a row somehow built
  # without one is a BUG -- let the read throw loudly here. (This guard used to
  # be a `debugger` statement: dead in production, a stealth breakpoint under
  # devtools.)
  menuEntryPreferredWidth: ->
    @children[0].width() + 8

  # MenuItemWdgt events:
  mouseEnter: ->

    if @representsAWidget
      if @argumentToAction1?
        # this first case handles when you pick a widget
        # as a target
        widgetToBeHighlighted = @argumentToAction1
      else
        # this second case handles when you attach to a widget
        widgetToBeHighlighted = @target
      widgetToBeHighlighted.turnOnHighlight()
    unless @isListItem()
      @state = @STATE_HIGHLIGHTED
      @_changed()
    if @toolTipMessage
      @startCountdownForBubbleHelp @toolTipMessage

  mouseLeave: ->
    if @representsAWidget
      if @argumentToAction1?
        # this first case handles when you pick a widget
        # as a target
        widgetToBeHighlighted = @argumentToAction1
      else
        # this second case handles when you attach to a widget
        widgetToBeHighlighted = @target
      widgetToBeHighlighted.turnOffHighlight()
    unless @isListItem()
      @state = @STATE_NORMAL
      @_changed()
    world.destroyToolTips()  if @toolTipMessage

  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    # LabelButtonWdgt.mouseDownLeft sets STATE_PRESSED + bringToForeground + escalate
    super

  isListItem: ->
    # true when my container selects rows on click (a MenuRowsPanelWdgt used as a
    # ListWdgt's contents) rather than triggering them (a MenuWdgt). Dispatched via
    # ?() so a plain menu, which does not answer it, reads falsy.
    return @parent.selectsItemsOnClick?()  if @parent
    false
