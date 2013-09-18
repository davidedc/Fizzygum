# MenuMorph ///////////////////////////////////////////////////////////

class MenuMorph extends BoxMorph

  target: null
  title: null
  environment: null
  fontSize: null
  items: null
  label: null
  world: null
  isListContents: false
  closeIcon: null

  constructor: (@target, @title = null, @environment = null, @fontSize = null) ->
    # Note that Morph does a updateRendering upon creation (TODO Why?), so we need
    # to initialise the items before calling super. We can't initialise it
    # outside the constructor because the array would be shared across instantiated
    # objects.
    @items = []
    super()
    @border = null # the Box Morph constructor puts this to 2
    # important not to traverse all the children for stepping through, because
    # there could be a lot of entries for example in the inspector the number
    # of properties of an object - there could be a 100 of those and we don't
    # want to traverse them all. Setting step to null (as opposed to nop) means
    # that
  
  addItem: (
      labelString,
      action,
      hint,
      color,
      bold = false,
      italic = false,
      doubleClickAction # optional, when used as list contents
      ) ->
    # labelString is normally a single-line string. But it can also be one
    # of the following:
    #     * a multi-line string (containing line breaks)
    #     * an icon (either a Morph or a Canvas)
    #     * a tuple of format: [icon, string]
    @items.push [
      localize(labelString or "close"),
      action or nop,
      hint,
      color,
      bold,
      italic,
      doubleClickAction
    ]

  prependItem: (
      labelString,
      action,
      hint,
      color,
      bold = false,
      italic = false,
      doubleClickAction # optional, when used as list contents
      ) ->
    # labelString is normally a single-line string. But it can also be one
    # of the following:
    #     * a multi-line string (containing line breaks)
    #     * an icon (either a Morph or a Canvas)
    #     * a tuple of format: [icon, string]
    @items.unshift [
      localize(labelString or "close"),
      action or nop,
      hint,
      color,
      bold,
      italic,
      doubleClickAction
    ]
  
  addLine: (width) ->
    @items.push [0, width or 1]

  prependLine: (width) ->
    @items.unshift [0, width or 1]
  
  createLabel: ->
    @label.destroy()  if @label isnt null
    text = new TextMorph(localize(@title),
      @fontSize or WorldMorph.MorphicPreferences.menuFontSize,
      WorldMorph.MorphicPreferences.menuFontName, true, false, "center")
    text.alignment = "center"
    text.color = new Color(255, 255, 255)
    text.backgroundColor = @borderColor
    text.updateRendering()
    @label = new BoxMorph(3, 0)
    if WorldMorph.MorphicPreferences.isFlat
      @label.edge = 0
    @label.color = @borderColor
    @label.borderColor = @borderColor
    @label.setExtent text.extent().add(4)
    @label.updateRendering()
    @label.add text
    @label.text = text
  
  updateRendering: ->
    isLine = false
    @children.forEach (m) ->
      m.destroy()
    #
    @children = []
    unless @isListContents
      @edge = if WorldMorph.MorphicPreferences.isFlat then 0 else 5
      @border = if WorldMorph.MorphicPreferences.isFlat then 1 else 2
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

    # note that menus can contain:
    # strings, colorpickers,
    # sliders, menuItems (which are buttons)
    # and lines.
    @items.forEach (tuple) =>
      isLine = false
      # string, color picker and slider
      if tuple instanceof StringFieldMorph or
        tuple instanceof ColorPickerMorph or
        tuple instanceof SliderMorph
          item = tuple
      # line. A thin Morph is used
      # to draw the line.
      else if tuple[0] is 0
        isLine = true
        item = new Morph()
        item.color = @borderColor
        item.setHeight tuple[1]
      # menuItem
      else
        item = new MenuItemMorph(
          @target,
          tuple[1],
          tuple[0],
          @fontSize or WorldMorph.MorphicPreferences.menuFontSize,
          WorldMorph.MorphicPreferences.menuFontName,
          @environment,
          tuple[2], # bubble help hint
          tuple[3], # color
          tuple[4], # bold
          tuple[5], # italic
          tuple[6]  # doubleclick action
          )
      y += 1  if isLine
      item.setPosition new Point(x, y)
      @add item
      y = y + item.height()
      y += 1  if isLine
  
    fb = @boundsIncludingChildren()
    @silentSetExtent fb.extent().add(4)
    @adjustWidths()
  
    unless @isListContents
      # add a close icon only if the menu is not
      # an embedded list
      @closeIcon = new CloseCircleButtonMorph()
      @closeIcon.color = new Color(255, 255, 255)
      @add @closeIcon
      @closeIcon.mouseClickLeft = =>
          @destroy()
      # close icon
      @closeIcon.setPosition new Point(@top() - 6, @left() - 6)
      closeIconScale = 2/3
      handleSize = WorldMorph.MorphicPreferences.handleSize;
      @closeIcon.setExtent new Point(handleSize * closeIconScale, handleSize * closeIconScale)

    super()
  
  maxWidth: ->
    w = 0
    if @parent instanceof FrameMorph
      if @parent.scrollFrame instanceof ScrollFrameMorph
        w = @parent.scrollFrame.width()    
    @children.forEach (item) ->
      if (item instanceof MenuItemMorph)
        w = Math.max(w, item.children[0].width() + 8)
      else if (item instanceof StringFieldMorph) or
        (item instanceof ColorPickerMorph) or
        (item instanceof SliderMorph)
          w = Math.max(w, item.width())  
    #
    w = Math.max(w, @label.width())  if @label
    w
  
  # makes all the elements of this menu the
  # right width.
  adjustWidths: ->
    w = @maxWidth()
    @children.forEach (item) =>
      item.silentSetWidth w
      if item instanceof MenuItemMorph
        isSelected = (item.image == item.pressImage)
        item.createBackgrounds()
        if isSelected then item.image = item.pressImage          
      else if item instanceof CloseCircleButtonMorph
        # do nothing, close button stays its
        # original width.
      else
        item.updateRendering()
        if item is @label
          item.text.setPosition item.center().subtract(item.text.extent().floorDivideBy(2))
  
  
  unselectAllItems: ->
    @children.forEach (item) ->
      item.image = item.normalImage  if item instanceof MenuItemMorph
    #
    @changed()
  
  popup: (world, pos) ->
    @updateRendering()
    @setPosition pos
    # avoid shadow when there is the close button,
    # as it looks aweful because of the added extent...
    unless @closeIcon?
      @addShadow new Point(2, 2), 80
    @keepWithin world
    # keep only one active menu at a time, destroy the
    # previous one.
    world.activeMenu.destroy()  if world.activeMenu
    world.add @
    world.activeMenu = @
    @fullChanged()
  
  popUpAtHand: (world) ->
    wrrld = world or @world
    @popup wrrld, wrrld.hand.position()
  
  popUpCenteredAtHand: (world) ->
    wrrld = world or @world
    @updateRendering()
    @popup wrrld, wrrld.hand.position().subtract(@extent().floorDivideBy(2))
  
  popUpCenteredInWorld: (world) ->
    wrrld = world or @world
    @updateRendering()
    @popup wrrld, wrrld.center().subtract(@extent().floorDivideBy(2))
