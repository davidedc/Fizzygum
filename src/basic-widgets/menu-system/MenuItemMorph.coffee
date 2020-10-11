# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph

  # labelString can also be a Widget or a Canvas or a tuple: [icon, string]
  constructor: (ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, labelString, fontSize, fontStyle, centered, environment, morphEnv, toolTipMessage, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2, representsAMorph) ->
    #console.log "menuitem constructing"
    super ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, labelString, fontSize, fontStyle, centered, environment, morphEnv, toolTipMessage, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2, representsAMorph
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

  isTicked: ->
    @label.text.isTicked()

  toggleTick: ->
    if @label.text.isTicked()
      @label.text = @label.text.toggleTick()
      @label.reLayout()
      @label.changed()
    else if @label.text.isUnticked()
      @label.text = @label.text.toggleTick()
      @label.reLayout()
      @label.changed()


  createLabel: ->
    # console.log "menuitem createLabel"
    @label = new TextMorph @labelString, @fontSize, @fontStyle
    @label.setColor @labelColor

    @add @label
  
    w = @width()
    @silentRawSetExtent @label.extent().add new Point 8, 0
    @silentRawSetWidth w
    np = @position().add new Point 4, 0
    @label.silentFullRawMoveTo np
  
  shrinkToTextSize: ->
    # '5' is to add some padding between
    # the text and the button edge
    @rawSetWidth @widthOfLabel() + 5

  widthOfLabel: ->
    @label.width()

  # MenuItemMorph events:
  mouseEnter: ->
    #console.log "@target: " + @target + " @morphEnv: " + @morphEnv
    
    # this could be a way to catch menu entries that should cause
    # an highlighting but don't
    #if @labelString.startsWith("a ") and !@representsAMorph
    #  debugger

    if @representsAMorph
      if @argumentToAction1?
        # this first case handles when you pick a morph
        # as a target
        morphToBeHighlighted = @argumentToAction1
      else
        # this second case handles when you attach to a morph
        morphToBeHighlighted = @target
      morphToBeHighlighted.turnOnHighlight()
    unless @isListItem()
      @state = @STATE_HIGHLIGHTED
      @changed()
    if @toolTipMessage
      @startCountdownForBubbleHelp @toolTipMessage
  
  mouseLeave: ->
    if @representsAMorph
      if @argumentToAction1?
        # this first case handles when you pick a morph
        # as a target
        morphToBeHighlighted = @argumentToAction1
      else
        # this second case handles when you attach to a morph
        morphToBeHighlighted = @target
      morphToBeHighlighted.turnOffHighlight()
    unless @isListItem()
      @state = @STATE_NORMAL
      @changed()
    world.destroyToolTips()  if @toolTipMessage
  
  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    @state = @STATE_PRESSED
    @changed()
    super
  
  isListItem: ->
    return @parent.isListContents  if @parent
    false

  # »>> this part is excluded from the fizzygum homepage build
  isSelectedListItem: ->
    return @state is @STATE_PRESSED if @isListItem()
    false
  # this part is excluded from the fizzygum homepage build <<«
