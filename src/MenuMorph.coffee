# MenuMorph ///////////////////////////////////////////////////////////

class MenuMorph extends BoxMorph
  constructor: (target, title, environment, fontSize) ->
    # additional properties:
    @target = target
    @title = title or null
    @environment = environment or null
    @fontSize = fontSize or null
    @items = []
    @label = null
    @world = null
    @isListContents = false
    #
    # initialize inherited properties:
    super()
    #
    # override inherited properties:
    @isDraggable = false
    #
    # immutable properties:
    @border = null
    @edge = null
  
  addItem: (labelString, action, hint, color) ->
    @items.push [localize(labelString or "close"), action or nop, hint, color]
  
  addLine: (width) ->
    @items.push [0, width or 1]
  
  createLabel: ->
    text = undefined
    @label.destroy()  if @label isnt null
    text = new TextMorph(localize(@title), @fontSize or MorphicPreferences.menuFontSize, MorphicPreferences.menuFontName, true, false, "center")
    text.alignment = "center"
    text.color = new Color(255, 255, 255)
    text.backgroundColor = @borderColor
    text.drawNew()
    @label = new BoxMorph(3, 0)
    @label.color = @borderColor
    @label.borderColor = @borderColor
    @label.setExtent text.extent().add(4)
    @label.drawNew()
    @label.add text
    @label.text = text
  
  drawNew: ->
    item = undefined
    fb = undefined
    x = undefined
    y = undefined
    isLine = false
    @children.forEach (m) ->
      m.destroy()
    #
    @children = []
    unless @isListContents
      @edge = 5
      @border = 2
    @color = new Color(255, 255, 255)
    @borderColor = new Color(60, 60, 60)
    @silentSetExtent new Point(0, 0)
    y = 2
    x = @left() + 4
    unless @isListContents
      if @title
        @createLabel()
        @label.setPosition @bounds.origin.add(4)
        @add @label
        y = @label.bottom()
      else
        y = @top() + 4
    y += 1
    @items.forEach (tuple) =>
      isLine = false
      if tuple instanceof StringFieldMorph or tuple instanceof ColorPickerMorph or tuple instanceof SliderMorph
        item = tuple
      else if tuple[0] is 0
        isLine = true
        item = new Morph()
        item.color = @borderColor
        item.setHeight tuple[1]
      else
        # bubble help hint
        item = new MenuItemMorph(@target, tuple[1], tuple[0], @fontSize or MorphicPreferences.menuFontSize, MorphicPreferences.menuFontName, @environment, tuple[2], tuple[3]) # color
      y += 1  if isLine
      item.setPosition new Point(x, y)
      @add item
      y = y + item.height()
      y += 1  if isLine
    #
    fb = @fullBounds()
    @silentSetExtent fb.extent().add(4)
    @adjustWidths()
    super()
  
  maxWidth: ->
    w = 0
    w = @parent.width()  if @parent.scrollFrame instanceof ScrollFrameMorph  if @parent instanceof FrameMorph
    @children.forEach (item) ->
      w = Math.max(w, item.width())  if (item instanceof MenuItemMorph) or (item instanceof StringFieldMorph) or (item instanceof ColorPickerMorph) or (item instanceof SliderMorph)
    #
    w = Math.max(w, @label.width())  if @label
    w
  
  adjustWidths: ->
    w = @maxWidth()
    @children.forEach (item) =>
      item.silentSetWidth w
      if item instanceof MenuItemMorph
        item.createBackgrounds()
      else
        item.drawNew()
        item.text.setPosition item.center().subtract(item.text.extent().floorDivideBy(2))  if item is @label
  
  
  unselectAllItems: ->
    @children.forEach (item) ->
      item.image = item.normalImage  if item instanceof MenuItemMorph
    #
    @changed()
  
  popup: (world, pos) ->
    @drawNew()
    @setPosition pos
    @addShadow new Point(2, 2), 80
    @keepWithin world
    world.activeMenu.destroy()  if world.activeMenu
    world.add @
    world.activeMenu = @
    @fullChanged()
  
  popUpAtHand: (world) ->
    wrrld = world or @world
    @popup wrrld, wrrld.hand.position()
  
  popUpCenteredAtHand: (world) ->
    wrrld = world or @world
    @drawNew()
    @popup wrrld, wrrld.hand.position().subtract(@extent().floorDivideBy(2))
  
  popUpCenteredInWorld: (world) ->
    wrrld = world or @world
    @drawNew()
    @popup wrrld, wrrld.center().subtract(@extent().floorDivideBy(2))
