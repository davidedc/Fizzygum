# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # labelString can also be a Morph or a Canvas or a tuple: [icon, string]
  constructor: (closesUnpinnedMenus, target, action, labelString, fontSize, fontStyle, centered, environment, morphEnv, hint, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2) ->
    #console.log "menuitem constructing"
    super closesUnpinnedMenus, target, action, labelString, fontSize, fontStyle, centered, environment, morphEnv, hint, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2 

  getTextDescription: ->
    if @textDescription?
      return @textDescription + " (adhoc description of menu item)"
    if @labelString
      textWithoutLocationOrInstanceNo = @labelString.replace(/\[\d*@\d*[ ]*\|[ ]*\d*@\d*\]/,"")
      textWithoutLocationOrInstanceNo = textWithoutLocationOrInstanceNo.replace(/#\d*/,"")
      return textWithoutLocationOrInstanceNo + " (text in button)"
    else
      return super()
  
  createLabel: ->
    # console.log "menuitem createLabel"
    if @label?
      @label = @label.destroy()

    if isString(@labelString)
      @label = @createLabelString(@labelString)
    else if @labelString instanceof Array      
      # assume its pattern is: [icon, string] 
      @label = new Morph()
      @label.alpha = 0 # transparent

      icon = @createIcon(@labelString[0])
      @label.add icon
      lbl = @createLabelString(@labelString[1])
      @label.add lbl

      lbl.setCenter icon.center()
      lbl.setLeft icon.right() + 4
      @label.setBounds(icon.boundingBox().merge(lbl.boundingBox()))
    else # assume it's either a Morph or a Canvas
      @label = @createIcon(@labelString)

    @add @label
  
    w = @width()
    @silentSetExtent @label.extent().add(new Point(8, 0))
    @silentSetWidth w
    np = @position().add(new Point(4, 0))
    @label.bounds = np.extent(@label.extent())
  
  createIcon: (source) ->
    # source can be either a Morph or an HTMLCanvasElement
    icon = new Morph()
    icon.backBuffer = (if source instanceof Morph then source.fullImage() else source)
    icon.backBufferContext = icon.backBuffer.getContext("2d")

    # adjust shadow dimensions
    if source instanceof Morph and source.getShadow()
      src = icon.backBuffer
      icon.backBuffer = newCanvas(
        source.fullBounds().extent().subtract(
          @shadowBlur * ((if WorldMorph.preferencesAndSettings.useBlurredShadows then 1 else 2))).scaleBy pixelRatio)
      icon.backBufferContext = icon.backBuffer.getContext("2d")
      icon.backBufferContext.drawImage src, 0, 0

    icon.silentSetWidth icon.backBuffer.width
    icon.silentSetHeight icon.backBuffer.height
    icon

  createLabelString: (string) ->
    # console.log "menuitem createLabelString"
    lbl = new TextMorph(string, @fontSize, @fontStyle)
    lbl.setColor @labelColor
    lbl  

  # MenuItemMorph events:
  mouseEnter: ->
    unless @isListItem()
      @state = @STATE_HIGHLIGHTED
      @changed()
    if @hint
      @startCountdownForBubbleHelp @hint
  
  mouseLeave: ->
    unless @isListItem()
      @state = @STATE_NORMAL
      @changed()
    world.hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    @state = @STATE_PRESSED
    @changed()  
  
  isListItem: ->
    return @parent.isListContents  if @parent
    false
  
  isSelectedListItem: ->
    return @state is @STATE_PRESSED if @isListItem()
    false
