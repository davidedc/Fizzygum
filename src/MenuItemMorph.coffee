# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # labelString can also be a Morph or a Canvas or a tuple: [icon, string]
  constructor: (target, action, labelString, fontSize, fontStyle, centered, environment, morphEnv, hint, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2) ->
    #console.log "menuitem constructing"
    super target, action, labelString, fontSize, fontStyle, centered, environment, morphEnv, hint, color, bold, italic, doubleClickAction, argumentToAction1, argumentToAction2 
  
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
      @label.bounds = (icon.bounds.merge(lbl.bounds))
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
    icon.image = (if source instanceof Morph then source.fullImage() else source)

    # adjust shadow dimensions
    if source instanceof Morph and source.getShadow()
      src = icon.image
      icon.image = newCanvas(
        source.fullBounds().extent().subtract(
          @shadowBlur * ((if WorldMorph.preferencesAndSettings.useBlurredShadows then 1 else 2))).scaleBy pixelRatio)
      context = icon.image.getContext("2d")
      #context.scale pixelRatio, pixelRatio
      context.drawImage src, 0, 0

    icon.silentSetWidth icon.image.width
    icon.silentSetHeight icon.image.height
    icon

  createLabelString: (string) ->
    # console.log "menuitem createLabelString"
    lbl = new TextMorph(string, @fontSize, @fontStyle)
    lbl.setColor @labelColor
    lbl  

  # MenuItemMorph events:
  mouseEnter: ->
    unless @isListItem()
      @image = @highlightImage
      @changed()
    if @hint
      @startCountdownForBubbleHelp @hint
  
  mouseLeave: ->
    unless @isListItem()
      @image = @normalImage
      @changed()
    world.hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    @image = @pressImage
    @changed()
  
  mouseMove: ->
    @escalateEvent "mouseMove"  if @isListItem()
  
  mouseClickLeft: ->
    super()
    # this might now destroy the
    # menu this morph is in
    # The menu item might be detached
    # from the menu so check existence of
    # method
    if @parent.itemSelected
      @parent.itemSelected()
  
  isListItem: ->
    return @parent.isListContents  if @parent
    false
  
  isSelectedListItem: ->
    return @image is @pressImage  if @isListItem()
    false
