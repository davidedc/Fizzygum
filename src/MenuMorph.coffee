# MenuMorph ///////////////////////////////////////////////////////////

class MenuMorph extends BoxMorph

  target: null
  title: null
  environment: null
  fontSize: null
  items: null
  label: null
  isListContents: false

  constructor: (@target, @title = null, @environment = null, @fontSize = null) ->
    # console.log "menu constructor"
    # Note that Morph does a updateRendering upon creation (TODO Why?), so we need
    # to initialise the items before calling super. We can't initialise it
    # outside the constructor because the array would be shared across instantiated
    # objects.
    @items = []
    # console.log "menu super"
    if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.IDLE and SystemTestsRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    super()

    @border = null # the Box Morph constructor puts this to 2
    # important not to traverse all the children for stepping through, because
    # there could be a lot of entries for example in the inspector the number
    # of properties of an object - there could be a 100 of those and we don't
    # want to traverse them all. Setting step to null (as opposed to nop)
    # achieves that.
  
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
    # console.log "menu create label"
    if @label?
      @label = @label.destroy()
    text = new TextMorph(localize(@title),
      @fontSize or WorldMorph.preferencesAndSettings.menuFontSize,
      WorldMorph.preferencesAndSettings.menuFontName, true, false, "center")
    text.alignment = "center"
    text.color = new Color(255, 255, 255)
    text.backgroundColor = @borderColor

    @label = new BoxMorph(3, 0)
    @label.add text
    if WorldMorph.preferencesAndSettings.isFlat
      @label.edge = 0
    @label.color = @borderColor
    @label.borderColor = @borderColor
    @label.setExtent text.extent().add(4) # here!
    @label.text = text
    @add @label
  
  updateRendering: ->
    # console.log "menu update rendering"
    isLine = false
    @destroyAll()
    #
    @children = []
    unless @isListContents
      @edge = if WorldMorph.preferencesAndSettings.isFlat then 0 else 5
      @border = if WorldMorph.preferencesAndSettings.isFlat then 1 else 2
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
    # console.log "menu @items.length " + @items.length
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
        # console.log "menu creating MenuItemMorph "
        item = new MenuItemMorph(
          @target,
          tuple[1], # action
          tuple[0], # target
          @fontSize or WorldMorph.preferencesAndSettings.menuFontSize,
          WorldMorph.preferencesAndSettings.menuFontName,
          false,
          @environment,
          tuple[2], # bubble help hint
          tuple[3], # color
          tuple[4], # bold
          tuple[5], # italic
          tuple[6]  # doubleclick action
          )
        if !@environment?
          item.dataSourceMorphForTarget = item
      y += 1  if isLine
      item.setPosition new Point(x, y)
      @add item
      y = y + item.height()
      y += 1  if isLine
  
    @adjustWidthsOfMenuEntries()
    fb = @boundsIncludingChildren()
    @silentSetExtent fb.extent().add(4)
  
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
  adjustWidthsOfMenuEntries: ->
    w = @maxWidth()
    @children.forEach (item) =>
      item.setWidth w
      if item instanceof MenuItemMorph
        isSelected = (item.image == item.pressImage)
        item.layoutSubmorphs()
        if isSelected then item.image = item.pressImage          
      else
        if item is @label
          item.text.setPosition item.center().subtract(item.text.extent().floorDivideBy(2))
  
  
  unselectAllItems: ->
    @children.forEach (item) ->
      item.image = item.normalImage  if item instanceof MenuItemMorph
    #
    @changed()

  itemSelected: ->
    unless @isListContents
      world.unfocusMenu @
      @destroy()
  
  popup: (world, pos) ->
    # console.log "menu popup"
    # keep only one active menu at a time, destroy the
    # previous one.
    if world.activeMenu
      world.activeMenu = world.activeMenu.destroy()
    world.add @
    # it's better do these movement
    # operations after adding to the world
    # in general, as a concept.
    # Specifically, the @keepWithin method
    # needs to know the extent of the morph
    # so it must be called after the world.add
    # method. If you call before, there is
    # nopainting happening and the morph doesn't
    # know its extent.
    @setPosition pos
    @keepWithin world
    if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.IDLE and SystemTestsRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    # shadow must be added after the morph
    # has been placed somewhere because
    # otherwise there is no visible image
    # to base the shadow on
    @addShadow new Point(2, 2), 80
    world.activeMenu = @
    @fullChanged()
  
  popUpAtHand: ->
    @popup world, world.hand.position()
  
  popUpCenteredAtHand: (world) ->
    wrrld = world or @world()
    @popup wrrld, wrrld.hand.position().subtract(@extent().floorDivideBy(2))
  
  popUpCenteredInWorld: (world) ->
    wrrld = world or @world()
    @popup wrrld, wrrld.center().subtract(@extent().floorDivideBy(2))
