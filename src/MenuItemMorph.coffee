# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph

  # labelString can also be a Widget or a Canvas or a tuple: [icon, string]
  constructor: (ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, labelString, fontSize, fontStyle, centered, environment, morphEnv, hint, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2, representsAMorph) ->
    #console.log "menuitem constructing"
    super ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, labelString, fontSize, fontStyle, centered, environment, morphEnv, hint, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2, representsAMorph 
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
    if isString @labelString
      @label = @createLabelString @labelString
    else if @labelString instanceof Array      
      # assume its pattern is: [icon, string] 
      @label = new Widget()
      @label.alpha = 0 # transparent

      icon = @createIcon @labelString[0]
      @label.add icon
      lbl = @createLabelString @labelString[1]
      @label.add lbl

      lbl.fullRawMoveCenterTo icon.center()
      lbl.fullRawMoveLeftSideTo icon.right() + 4
      @label.rawSetBounds icon.boundingBox().merge lbl.boundingBox()
    else # assume it's either a Widget or a Canvas
      @label = @createIcon @labelString

    @add @label
  
    w = @width()
    @silentRawSetExtent @label.extent().add new Point 8, 0
    @silentRawSetWidth w
    np = @position().add new Point 4, 0
    @label.silentFullRawMoveTo np
  

  createIcon: (source) ->
    # source can be either a Widget or an HTMLCanvasElement
    icon = new Widget()
    icon.backBuffer = (if source instanceof Widget then source.fullImage() else source)
    icon.backBufferContext = icon.backBuffer.getContext "2d"

    # adjust shadow dimensions
    if source instanceof Widget and source.hasShadow()
      src = icon.backBuffer
      icon.backBuffer = newCanvas(
        source.fullBounds().extent().subtract(
          @shadowBlur * 2).scaleBy pixelRatio)
      icon.backBufferContext = icon.backBuffer.getContext "2d"
      icon.backBufferContext.drawImage src, 0, 0

    icon.silentRawSetWidth icon.backBuffer.width
    icon.silentRawSetHeight icon.backBuffer.height
    icon

  createLabelString: (string) ->
    # console.log "menuitem createLabelString"
    lbl = new TextMorph string, @fontSize, @fontStyle
    lbl.setColor @labelColor
    lbl  

  # MenuItemMorph events:
  mouseEnter: ->
    #console.log "@target: " + @target + " @morphEnv: " + @morphEnv
    
    # this could be a way to catch menu entries that should cause
    # an highlighting but don't
    #if @labelString.indexOf("a ") == 0 and !@representsAMorph
    #  debugger

    if @representsAMorph
      morphToBeHighlighted = nil
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
    if @hint
      @startCountdownForBubbleHelp @hint
  
  mouseLeave: ->
    if @representsAMorph
      morphToBeHighlighted = nil
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
    world.hand.destroyToolTips()  if @hint
  
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
  
  isSelectedListItem: ->
    return @state is @STATE_PRESSED if @isListItem()
    false
