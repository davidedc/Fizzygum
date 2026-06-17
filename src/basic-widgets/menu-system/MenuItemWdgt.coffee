# I automatically determine my bounds

# A menu row. It extends LabelButtonWdgt (the flat label-bearing button base, on
# the modern ButtonWdgt family) and adds the menu-specific behaviour: a
# self-sizing multi-line TextWdgt label, tick toggling, list-row selection, and
# the "represents a widget" hover-highlight.

class MenuItemWdgt extends LabelButtonWdgt

  # labelString can also be a Widget or a Canvas or a tuple: [icon, string]
  constructor: (ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, labelString, fontSize, fontStyle, centered, environment, widgetEnv, toolTipMessage, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2, representsAWidget) ->
    #console.log "menuitem constructing"
    super ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, labelString, fontSize, fontStyle, centered, environment, widgetEnv, toolTipMessage, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2, representsAWidget
    @actionableAsThumbnail = true

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
  #reLayout: ->
  #  @label.setExtent @extent().subtract (@label.bounds.origin.subtract @.bounds.origin)

  # MenuItemWdgt hugs its box to its (multi-line, modern TextWdgt) label -- the
  # opposite of LabelButtonWdgt's default single-line StringWdgt label, which
  # leaves the box alone.
  createLabel: ->
    # console.log "menuitem createLabel"
    @label = new TextWdgt @labelString, @fontSize, @fontStyle
    @label.setColor @labelColor

    @add @label
    # the modern family does not self-size; make the label hug its text before
    # we read @label.extent() below to size this menu item around it.
    @label.sizeToTextAndDisableFitting()

    w = @width()
    @silentRawSetExtent @label.extent().add new Point 8, 0
    @silentRawSetWidth w
    np = @position().add new Point 4, 0
    @label.silentFullRawMoveTo np

  isTicked: ->
    @label.text.isTicked()

  toggleTick: ->
    if @label.text.isTicked()
      @label.text = @label.text.toggleTick()
      # reLayout is a base no-op on the modern TextWdgt, so it would leave the
      # ticked/unticked label at a stale width; re-measure and re-size instead.
      @label.sizeToTextAndDisableFitting()
      @label.changed()
    else if @label.text.isUnticked()
      @label.text = @label.text.toggleTick()
      @label.sizeToTextAndDisableFitting()
      @label.changed()

  shrinkToTextSize: ->
    # '5' is to add some padding between
    # the text and the button edge
    @rawSetWidth @widthOfLabel() + 5

  widthOfLabel: ->
    @label.width()

  # MenuItemWdgt events:
  mouseEnter: ->
    #console.log "@target: " + @target + " @widgetEnv: " + @widgetEnv

    # this could be a way to catch menu entries that should cause
    # an highlighting but don't
    #if @labelString.startsWith("a ") and !@representsAWidget
    #  debugger

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
      @changed()
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
      @changed()
    world.destroyToolTips()  if @toolTipMessage

  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    # LabelButtonWdgt.mouseDownLeft sets STATE_PRESSED + bringToForeground + escalate
    super

  isListItem: ->
    return @parent.isListContents  if @parent
    false

  # »>> this part is excluded from the fizzygum homepage build
  isSelectedListItem: ->
    return @state is @STATE_PRESSED if @isListItem()
    false
  # this part is excluded from the fizzygum homepage build <<«
