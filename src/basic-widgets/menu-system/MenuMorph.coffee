# MenuMorphs is a Pop-up with basically a vertical stack of buttons

class MenuMorph extends PopUpWdgt

  target: nil
  title: nil
  environment: nil
  fontSize: nil
  label: nil
  isListContents: false

  constructor: (@morphOpeningThePopUp, @isListContents = false, @target, @killThisPopUpIfClickOutsideDescendants = true, @killThisPopUpIfClickOnDescendantsTriggers = true, @title = nil, @environment = nil, @fontSize = nil) ->
    # console.log "menu constructor"
    # console.log "menu super"
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    if !@isListContents
      if @killThisPopUpIfClickOutsideDescendants
        @onClickOutsideMeOrAnyOfMyChildren "close"
    super @morphOpeningThePopUp, @killThisPopUpIfClickOutsideDescendants, @killThisPopUpIfClickOnDescendantsTriggers
    @isLockingToPanels = false
    @appearance = new MenuAppearance @
    @strokeColor = WorldMorph.preferencesAndSettings.menuStrokeColor


    if @isListContents
      world.freshlyCreatedPopUps.delete @
      world.openPopUps.delete @
    # important not to traverse all the children for stepping through, because
    # there could be a lot of entries for example in the inspector the number
    # of properties of an object - there could be a 100 of those and we don't
    # want to traverse them all. Setting step to nil (as opposed to nop)
    # achieves that.

    unless @isListContents
      if @title
        @createLabel()
        @silentAdd @label

  colloquialName: ->
    if @title
      return "\"" + @title + "\" menu"
    else
      return "menu"

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.THIS_ONE_I_HAVE_NOW , PreferredSize.THIS_ONE_I_HAVE_NOW, 0
    @layoutSpecDetails.canSetHeightFreely = false


  createLine: (height = 1) ->
    item = new RectangleMorph
    item.setMinimumExtent new Point 5,1
    item.color = new Color 230,230,230
    item.rawSetHeight height + 2
    item

  addLine: (height) ->
    item = @createLine height
    @silentAdd item

  prependLine: (height) ->
    item = @createLine height
    @silentAdd item,nil,0
  
  createLabel: ->
    @label = new MenuHeader @title

  createMenuItem: (label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true, target, action, toolTipMessage, color, bold = false, italic = false,doubleClickAction, arg1, arg2,representsAMorph = false)->
    # console.log "menu creating MenuItemMorph "
    item = new MenuItemMorph(
      ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, # closes unpinned menus
      target, # target
      action, # action
      (label or "close"), # label
      @fontSize or WorldMorph.preferencesAndSettings.menuFontSize,
      WorldMorph.preferencesAndSettings.menuFontName,
      false,
      @target, # environment
      @environment, # environment2
      toolTipMessage, # bubble help toolTipMessage
      color, # color
      bold, # bold
      italic, # italic
      doubleClickAction,  # doubleclick action
      arg1,  # argument to action 1
      arg2,  # argument to action 2
      representsAMorph  # does it represent a Widget?
      )
    if !@environment?
      item.dataSourceMorphForTarget = item
      item.morphEnv = @target

    item

  removeMenuItem: (label) ->
    item = @firstChildSuchThat (m) ->
      m.label? and m.label.text == label
    if item?
      item.fullDestroy()

  removeConsecutiveLines: ->
    # have to copy the array with slice()
    # because we are removing items from it
    # while looping over it
    destroyNextLines = false
    for item in @children.slice()
      if destroyNextLines and item instanceof RectangleMorph
        item.fullDestroy()
      if item instanceof RectangleMorph
        destroyNextLines = true
        continue
      else
        destroyNextLines = false

  addMenuItem: (label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph)->
    # console.log "menu creating MenuItemMorph "
    item = @createMenuItem label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph
    @silentAdd item

  prependMenuItem: (label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph)->
    # console.log "menu creating MenuItemMorph "
    item = @createMenuItem label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph
    @silentAdd item, nil, 0

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
      if item != @label
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
    #for w in @children
    #  if @items.indexOf(w) == -1
    #    w.fullDestroy()

    #@children = []

    unless @isListContents
      @cornerRadius = if WorldMorph.preferencesAndSettings.isFlat then 0 else 5
    @color = new Color 238, 238, 238
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

    @removeShadow()

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
    #if @parent instanceof PanelWdgt
    #  if @parent.scrollPanel instanceof ScrollPanelWdgt
    #    w = @parent.scrollPanel.width()    
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
      #console.log "new width of " + item + " : " + item.width()
      trackChanges.pop()

  
  unselectAllItems: ->
    @children.forEach (item) ->
      if item instanceof MenuItemMorph
        item.state = item.STATE_NORMAL

    @changed()



