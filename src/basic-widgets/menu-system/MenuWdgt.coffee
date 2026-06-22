# MenuWdgts is a Pop-up with basically a vertical stack of buttons

class MenuWdgt extends PopUpWdgt

  target: nil
  title: nil
  environment: nil
  fontSize: nil
  label: nil
  isListContents: false

  # Role query (replaces `m instanceof MenuWdgt` in ActivePointerWdgt's menuAtPointer filter + the
  # click-outside-a-menu dismissal): "am I a menu?" -- distinguishes menus from other pop-ups. True here,
  # inherited by PromptWdgt/SaveShortcutPromptWdgt (mirroring the instanceof); dispatched via ?() (nothing
  # on Widget). Parallels isWindow. (type-test-elimination campaign)
  isMenu: ->
    true

  constructor: (@widgetOpeningThePopUp, @isListContents = false, @target, @killThisPopUpIfClickOutsideDescendants = true, @killThisPopUpIfClickOnDescendantsTriggers = true, @title = nil, @environment = nil, @fontSize = nil) ->
    # console.log "menu constructor"
    # console.log "menu super"
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()
    if !@isListContents
      if @killThisPopUpIfClickOutsideDescendants
        @onClickOutsideMeOrAnyOfMyChildren "close"
    super @widgetOpeningThePopUp, @killThisPopUpIfClickOutsideDescendants, @killThisPopUpIfClickOnDescendantsTriggers
    @isLockingToPanels = false
    @appearance = new MenuAppearance @
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor


    if @isListContents
      world.freshlyCreatedPopUps.delete @
      world.openPopUps.delete @

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
    item = new RectangleWdgt
    item.setMinimumExtent new Point 5,1
    item.color = Color.create 230,230,230
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

  # Builds a MenuItemWdgt from a MenuItemSpec (the per-item fields) and this
  # menu's context: the font (this menu's @fontSize, or the global default) and
  # -- note the historical mapping -- this menu's @target as the item's
  # "environment" and this menu's @environment as the item's widgetEnv. The
  # spec's named fields replace what used to be a 17-argument positional call
  # carrying a per-argument trailing comment on every line.
  createMenuItem: (menuItemSpec) ->
    # console.log "menu creating MenuItemWdgt "
    item = new MenuItemWdgt menuItemSpec, (@fontSize or WorldWdgt.preferencesAndSettings.menuFontSize), WorldWdgt.preferencesAndSettings.menuFontName, false, @target, @environment
    if !@environment?
      item.dataSourceWidgetForTarget = item
      item.widgetEnv = @target

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
      if destroyNextLines and item instanceof RectangleWdgt
        item.fullDestroy()
      if item instanceof RectangleWdgt
        destroyNextLines = true
        continue
      else
        destroyNextLines = false

  # NOTE: the positional (label, closes-unpinned, target, action, ...) signature
  # is the public menu API used by hundreds of call sites, so it is deliberately
  # NOT changed. We just bundle the arguments into a MenuItemSpec internally; the
  # spec's constructor defaults reproduce the old createMenuItem defaults exactly.
  addMenuItem: (label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic, doubleClickAction, arg1, arg2, representsAWidget)->
    # console.log "menu creating MenuItemWdgt "
    menuItemSpec = new MenuItemSpec label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic, doubleClickAction, arg1, arg2, representsAWidget
    item = @createMenuItem menuItemSpec
    @silentAdd item

  prependMenuItem: (label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic, doubleClickAction, arg1, arg2, representsAWidget)->
    # console.log "menu creating MenuItemWdgt "
    menuItemSpec = new MenuItemSpec label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic, doubleClickAction, arg1, arg2, representsAWidget
    item = @createMenuItem menuItemSpec
    @silentAdd item, nil, 0

  # »>> this part is excluded from the fizzygum homepage build

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

  # this part is excluded from the fizzygum homepage build <<«

  _reLayoutSelf: ->
    # console.log "menu update rendering"
    super()

    # no point in breaking a rectangle for each menu entry,
    # let's hold on the broken rects and then issue
    # a fullChanged() at the end.
    world.disableTrackChanges()


    # we are going to re-build the
    # children list from the @items.
    # If the list of @items has changed, we
    # make sure we destroy the children that
    # are going away.
    #for w in @children
    #  if !@items.includes(w)
    #    w.fullDestroy()

    #@children = []

    unless @isListContents
      @cornerRadius = if WorldWdgt.preferencesAndSettings.isFlat then 0 else 5
    @color = Color.create 238, 238, 238
    @silentRawSetExtent new Point 0, 0
    y = @top()
    x = @left() + 2

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
    world.maybeEnableTrackChanges()
    @fullChanged()
  
  maxWidthOfMenuEntries: ->
    w = 0
    #if @parent instanceof PanelWdgt
    #  if @parent.scrollPanel instanceof ScrollPanelWdgt
    #    w = @parent.scrollPanel.width()
    # Each entry that contributes a width answers menuEntryPreferredWidth()
    # (MenuItemWdgt / StringFieldWdgt / ColorPickerWdgt / SliderWdgt define it);
    # divider lines and the header don't, and are skipped -- exactly the set the
    # old `instanceof` chain matched.
    @children.forEach (item) ->
      if item.menuEntryPreferredWidth?
        w = Math.max w, item.menuEntryPreferredWidth()
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
      world.disableTrackChanges()
      item.rawSetWidth w
      #console.log "new width of " + item + " : " + item.width()
      world.maybeEnableTrackChanges()

  
  unselectAllItems: ->
    @children.forEach (item) ->
      if item instanceof MenuItemWdgt
        item.state = item.STATE_NORMAL

    @changed()



