# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph

  # labelString can also be a Morph or a Canvas or a tuple: [icon, string]
  constructor: (target, action, labelString, fontSize, fontStyle, environment, hint, color) ->
    super target, action, labelString, fontSize, fontStyle, environment, hint, color
  
  createLabel: ->
    @label.destroy()  if @label isnt null

    if isString(@labelString)
      @label = @createLabelString(@labelString)
    else if @labelString instanceof Array      
      # assume its pattern is: [icon, string] 
      @label = new Morph()
      @label.alpha = 0 # transparent
      @label.add icon = @createIcon(@labelString[0])
      @label.add lbl = @createLabelString(@labelString[1])
      lbl.setCenter icon.center()
      lbl.setLeft icon.right() + 4
      @label.bounds = (icon.bounds.merge(lbl.bounds))
      @label.drawNew()
    else # assume it's either a Morph or a Canvas
      @label = @createIcon(@labelString)
  
    @silentSetExtent @label.extent().add(new Point(8, 0))
    np = @position().add(new Point(4, 0))
    @label.bounds = np.extent(@label.extent())
    @add @label
  
  createIcon: (source) ->
    # source can be either a Morph or an HTMLCanvasElement
    icon = new Morph()
    icon.image = (if source instanceof Morph then source.fullImage() else source)

    # adjust shadow dimensions
    if source instanceof Morph and source.getShadow()
      src = icon.image
      icon.image = newCanvas(
        source.fullBounds().extent().subtract(
          @shadowBlur * ((if useBlurredShadows then 1 else 2))))
      icon.image.getContext("2d").drawImage src, 0, 0

    icon.silentSetWidth icon.image.width
    icon.silentSetHeight icon.image.height
    icon

  createLabelString: (string) ->
    lbl = new TextMorph(string, @fontSize, @fontStyle)
    lbl.setColor @labelColor
    lbl  

  # MenuItemMorph events:
  mouseEnter: ->
    unless @isListItem()
      @image = @highlightImage
      @changed()
    @bubbleHelp @hint  if @hint
  
  mouseLeave: ->
    unless @isListItem()
      @image = @normalImage
      @changed()
    @world().hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    @image = @pressImage
    @changed()
  
  mouseMove: ->
    @escalateEvent "mouseMove"  if @isListItem()
  
  mouseClickLeft: ->
    unless @isListItem()
      @parent.destroy()
      @root().activeMenu = null
    @trigger()
  
  isListItem: ->
    return @parent.isListContents  if @parent
    false
  
  isSelectedListItem: ->
    return @image is @pressImage  if @isListItem()
    false
