# MenuMorph ///////////////////////////////////////////////////////////

class MenuMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  target: null
  title: null
  environment: null
  fontSize: null
  label: null
  isListContents: false
  killThisMenuIfClickOnDescendantsTriggers: true
  killThisMenuIfClickOutsideDescendants: true
  tempPromptEntryField: null

  constructor: (@isListContents = false, @target, @killThisMenuIfClickOutsideDescendants = true, @killThisMenuIfClickOnDescendantsTriggers = true, @title = null, @environment = null, @fontSize = null) ->
    # console.log "menu constructor"
    # console.log "menu super"
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    if !@isListContents
      if @killThisMenuIfClickOutsideDescendants
        @onClickOutsideMeOrAnyOfMyChildren "destroy"
    super()

    if !@isListContents
      world.freshlyCreatedMenus.push @
      world.openMenus.push @
    # important not to traverse all the children for stepping through, because
    # there could be a lot of entries for example in the inspector the number
    # of properties of an object - there could be a 100 of those and we don't
    # want to traverse them all. Setting step to null (as opposed to nop)
    # achieves that.

    unless @isListContents
      if @title
        @createLabel()
        @silentAdd @label


  propagateKillMenus: ->
    if @killThisMenuIfClickOnDescendantsTriggers
      if @parent?
        @parent.propagateKillMenus()
      @markForDestruction()

  isPinned: ->
    return !(@killThisMenuIfClickOnDescendantsTriggers or @killThisMenuIfClickOutsideDescendants)

  pin: (pinMenuItem)->
    @killThisMenuIfClickOnDescendantsTriggers = false
    @killThisMenuIfClickOutsideDescendants = false
    @onClickOutsideMeOrAnyOfMyChildren null
    pinMenuItem.parent.propagateKillMenus()
    world.destroyMorphsMarkedForDestruction()
    world.add @

  # StringMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addMenuItem "pin", false, @, "pin"
    menu
  
  createLine: (height = 1) ->
    item = new RectangleMorph()
    item.setMinimumExtent new Point 5,1
    item.color = new Color 230,230,230
    item.rawSetHeight height + 2
    item

  addLine: (height) ->
    item = @createLine height
    @silentAdd item

  prependLine: (height) ->
    item = @createLine height
    @silentAdd item,null,0
  
  createLabel: ->
    # console.log "menu create label"
    if @label?
      @label = @label.destroy()
    text = new TextMorph(localize(@title),
      @fontSize or WorldMorph.preferencesAndSettings.menuFontSize,
      WorldMorph.preferencesAndSettings.menuFontName, true, false, "center")
    text.alignment = "center"
    text.color = new Color 255, 255, 255
    text.backgroundColor = new Color 60,60,60

    @label = new BoxMorph 3
    @label.add text
    if WorldMorph.preferencesAndSettings.isFlat
      @label.cornerRadius = 0
    @label.color = new Color 60,60,60
    @label.rawSetExtent text.extent().add 2
    @label.text = text

  createMenuItem: (label, closesUnpinnedMenus = true, target, action, hint, color, bold = false, italic = false,doubleClickAction, arg1, arg2,representsAMorph = false)->
    # console.log "menu creating MenuItemMorph "
    item = new MenuItemMorph(
      closesUnpinnedMenus, # closes unpinned menus
      target, # target
      action, # action
      (label or "close"), # label
      @fontSize or WorldMorph.preferencesAndSettings.menuFontSize,
      WorldMorph.preferencesAndSettings.menuFontName,
      false,
      @target, # environment
      @environment, # environment2
      hint, # bubble help hint
      color, # color
      bold, # bold
      italic, # italic
      doubleClickAction,  # doubleclick action
      arg1,  # argument to action 1
      arg2,  # argument to action 2
      representsAMorph  # does it represent a Morph?
      )
    if !@environment?
      item.dataSourceMorphForTarget = item
      item.morphEnv = @target

    item


  addMenuItem: (label, closesUnpinnedMenus, target, action, hint, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph)->
    # console.log "menu creating MenuItemMorph "
    item = @createMenuItem label, closesUnpinnedMenus, target, action, hint, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph
    @silentAdd item

  prependMenuItem: (label, closesUnpinnedMenus, target, action, hint, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph)->
    # console.log "menu creating MenuItemMorph "
    item = @createMenuItem label, closesUnpinnedMenus, target, action, hint, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph
    @silentAdd item, null, 0

  # this is used by the test system to check that the menu
  # has the correct number of items. Note that we count the
  # children, but we don't count the top label and we don't
  # count the shadow.
  testNumberOfItems: ->
    @testItems().length

  # this is used by the test system to check that the menu
  # has the correct items. Note that we consider the
  # children, but we don't consider the top label and we don't
  # consider the shadow.
  testItems: ->
    items = []
    for item in @children
      if (item != @label) and (item not instanceof ShadowMorph)
        items.push item
    items

  reLayout: ->
    # console.log "menu update rendering"
    super()

    # no point in breaking a rectangle for each menu entry,
    # let's hold on the broken rects and then issue
    # a fullChanged() at the end.
    trackChanges.push false


    # we are going to re-build the
    # children list from the @items.
    # If the list of @items has changed, we
    # make sure we destroy the children that
    # are going away.
    #for eachChild in @children
    #  if @items.indexOf(eachChild) == -1
    #    eachChild.fullDestroy()

    #@children = []

    unless @isListContents
      @cornerRadius = if WorldMorph.preferencesAndSettings.isFlat then 0 else 5
    @color = new Color 255, 255, 255
    @silentRawSetExtent new Point 0, 0
    y = @top()
    x = @left() + 2
    @notifyChildrenThatParentHasReLayouted()


    unless @isListContents
      if @title
        @label.fullRawMoveTo @position().add 2
        y = @label.bottom()
      else
        y = @top()
    y += 1

    @removeShadowMorph()

    # note that menus can contain:
    # strings, colorpickers,
    # sliders, menuItems (which are buttons)
    # and divider lines.
    # console.log "menu @items.length " + @items.length
    for item in @children
      if item == @label then continue
      item.fullRawMoveTo new Point x, y
      #console.log "item added: " + item.bounds
      y = y + item.height()
  
    @adjustWidthsOfMenuEntries()
    fb = @fullBounds()
    #console.log "fb: " + fb
    # add some padding to the right and bottom of the menu
    @silentRawSetExtent fb.extent().add 2
    trackChanges.pop()
    @fullChanged()
  
  maxWidthOfMenuEntries: ->
    w = 0
    #if @parent instanceof FrameMorph
    #  if @parent.scrollFrame instanceof ScrollFrameMorph
    #    w = @parent.scrollFrame.width()    
    @children.forEach (item) ->
      if item instanceof MenuItemMorph
        if !item.children[0]? then debugger
        w = Math.max(w, item.children[0].width() + 8)
      else if (item instanceof StringFieldMorph) or
        (item instanceof ColorPickerMorph) or
        (item instanceof SliderMorph)
          w = Math.max w, item.width()
      #console.log "maxWidthOfMenuEntries: width of item " + item + " : " + w

    if @label
      w = Math.max w, @label.width()
      #console.log "maxWidthOfMenuEntries: label width : " + w
    w
  
  # makes all the elements of this menu the
  # right width.
  adjustWidthsOfMenuEntries: ->
    w = @maxWidthOfMenuEntries()
    #console.log "maxWidthOfMenuEntries " + w
    @children.forEach (item) =>
      trackChanges.push false
      item.rawSetWidth w
      if item is @label
        item.text.fullRawMoveTo item.center().subtract item.text.extent().floorDivideBy 2
      #console.log "new width of " + item + " : " + item.width()
      trackChanges.pop()

  
  unselectAllItems: ->
    @children.forEach (item) ->
      if item instanceof MenuItemMorph
        item.state = item.STATE_NORMAL

    @changed()

  destroy: ->
    WorldMorph.numberOfAddsAndRemoves++
    super()
    if !@isListContents
      world.openMenus.remove @


  itemSelected: ->
    unless @isListContents
      @destroy()

  justDropped: ->
    if @isPinned()
      @removeShadowMorph()
    else
      @addFullShadow()


  popup: (morphToAttachTo, pos) ->
    # console.log "menu popup"
    @silentFullRawMoveTo pos
    morphToAttachTo.add @
    # the @fullRawMoveWithin method
    # needs to know the extent of the morph
    # so it must be called after the morphToAttachTo.add
    # method. If you call before, there is
    # nopainting happening and the morph doesn't
    # know its extent.
    @fullRawMoveWithin world
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    # shadow must be added after the morph
    # has been placed somewhere because
    # otherwise there is no visible image
    # to base the shadow on
    # P.S. this is the thing that causes the MenuMorph buffer
    # to be painted after the creation.
    @addFullShadow()
    @fullChanged()

  # shadow is added to a morph by
  # the HandMorph while floatDragging
  addFullShadow: (offset = new Point(2, 2), alpha = 0.8, color) ->
    super offset, alpha, color
  
  popUpAtHand: (morphToAttachTo)->
    if !morphToAttachTo?
      morphToAttachTo = world
    @popup morphToAttachTo, world.hand.position()
  
  popUpCenteredAtHand: (world) ->
    @popup world, world.hand.position().subtract @extent().floorDivideBy 2
  
  popUpCenteredInWorld: (world) ->
    @popup world, world.center().subtract @extent().floorDivideBy 2

