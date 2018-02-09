# MenuMorph ///////////////////////////////////////////////////////////
# MenuMorphs are special Widgets that have quite complex logic for
# opening themselves, closing themseves when users click outside,
# popping up, opening sub-menus, and pinning them down.
# Other than that, ideally they should be able to contain anything.
#
# Menus have 3 different shadows: "normal", "when dragged" and
# "pinned on desktop", plus no shadow when pinned on anything
# else other than the desktop.

class MenuMorph extends Widget

  target: nil
  title: nil
  environment: nil
  fontSize: nil
  label: nil
  isListContents: false

  killThisPopUpIfClickOnDescendantsTriggers: true
  killThisPopUpIfClickOutsideDescendants: true
  isPopUpMarkedForClosure: false
  # the morphOpeningThePopUp is only useful to get the "parent" pop-up.
  # the "parent" pop-up is the menu that this menu is attached to,
  # but we need this extra property because it's not the
  # actual parent. The reason is that menus are actually attached
  # to the world morph. This is for a couple of reasons:
  # 1) they can still appear at the top even if the "parent menu"
  #    or the parent object are not in the foreground. This is
  #    what happens for example in OSX, you can right-click on a
  #    morph that is not in the background but the menu that comes up
  #    will be in the foreground.
  # 2) they can appear unoccluded if the "parent morph" or "parent object"
  #    are in a morph that clips at its boundaries.
  morphOpeningThePopUp: nil

  constructor: (@morphOpeningThePopUp, @isListContents = false, @target, @killThisPopUpIfClickOutsideDescendants = true, @killThisPopUpIfClickOnDescendantsTriggers = true, @title = nil, @environment = nil, @fontSize = nil) ->
    # console.log "menu constructor"
    # console.log "menu super"
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    if !@isListContents
      if @killThisPopUpIfClickOutsideDescendants
        @onClickOutsideMeOrAnyOfMyChildren "close"
    super()
    @isLockingToPanels = false
    @appearance = new MenuAppearance @
    @strokeColor = new Color 210, 210, 210


    if !@isListContents
      world.freshlyCreatedPopUps.push @
      world.openPopUps.push @
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
    toBeReturned = "menu"
    if @title
      return "\"" + @title + "\" menu"
    else
      return "menu"

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.THIS_ONE_I_HAVE_NOW , PreferredSize.THIS_ONE_I_HAVE_NOW, 0
    @layoutSpecDetails.canSetHeightFreely = false

  hierarchyOfPopUps: ->
    ascendingMorphs = @
    hierarchy = [ascendingMorphs]
    while ascendingMorphs?.getParentPopUp?
      ascendingMorphs = ascendingMorphs.getParentPopUp()
      if ascendingMorphs?
        hierarchy.push ascendingMorphs
    return hierarchy

  # for pop ups, the propagation happens through the getParentPopUp method
  # rather than the parent property, but for other normal widgets it goes
  # up the parent property
  propagateKillPopUps: ->
    if @killThisPopUpIfClickOnDescendantsTriggers
      @getParentPopUp()?.propagateKillPopUps()
      @markPopUpForClosure()

  markPopUpForClosure: ->
    world.popUpsMarkedForClosure.push @
    @isPopUpMarkedForClosure = true

  # why introduce a new flag when you can calculate
  # from existing flags?
  isPopUpPinned: ->
    return !(@killThisPopUpIfClickOnDescendantsTriggers or @killThisPopUpIfClickOutsideDescendants)

  getParentPopUp: ->
    if @isPopUpPinned()
      return @parent
    else
      if @morphOpeningThePopUp?
        return @morphOpeningThePopUp.firstParentThatIsAPopUp()
    return nil


  # this is invoked on the menu morph to be
  # pinned. The triggering menu item is the first
  # parameter.
  pinPopUp: (pinMenuItem)->
    @killThisPopUpIfClickOnDescendantsTriggers = false
    @killThisPopUpIfClickOutsideDescendants = false
    @onClickOutsideMeOrAnyOfMyChildren nil
    if pinMenuItem?
      pinMenuItem.firstParentThatIsAPopUp().propagateKillPopUps()
    else
      @getParentPopUp()?.propagateKillPopUps()
    world.closePopUpsMarkedForClosure()
    
    # leave the menu attached to whatever it's attached,
    # just change the shadow.
    @updatePopUpShadow()



  # StringMorph menus:
  addMorphSpecificMenuEntries: (unused_morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "pin", false, @, "pin"
  
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
    @silentAdd item,nil,0
  
  createLabel: ->
    @label = new MenuHeader localize @title

  createMenuItem: (label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true, target, action, hint, color, bold = false, italic = false,doubleClickAction, arg1, arg2,representsAMorph = false)->
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
      hint, # bubble help hint
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

  addMenuItem: (label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, hint, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph)->
    # console.log "menu creating MenuItemMorph "
    item = @createMenuItem label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, hint, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph
    @silentAdd item

  prependMenuItem: (label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, hint, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph)->
    # console.log "menu creating MenuItemMorph "
    item = @createMenuItem label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, hint, color, bold, italic,doubleClickAction, arg1, arg2,representsAMorph
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
    #for eachChild in @children
    #  if @items.indexOf(eachChild) == -1
    #    eachChild.fullDestroy()

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

  destroy: ->
    WorldMorph.numberOfAddsAndRemoves++
    super()
    if !@isListContents
      world.openPopUps.remove @

  close: ->
    super()
    if !@isListContents
      world.openPopUps.remove @

  justDropped: (widgetDroppedOn) ->
    if widgetDroppedOn != world
      @pinPopUp()

    @updatePopUpShadow()

  updatePopUpShadow: ->
    if @isPopUpPinned()
      if @parent == world
        @addShadow new Point(3, 3), 0.3
      else
        @removeShadow()
    else 
      @addShadow()

  # shadow is added to a morph by
  # the HandMorph while floatDragging
  addShadow: (offset = new Point(5, 5), alpha = 0.2, color) ->
    super offset, alpha
  
  popUpCenteredAtHand: (world) ->
    @popUp (world.hand.position().subtract @extent().floorDivideBy 2), world
  
  # currently unused
  popUpCenteredInWorld: (world) ->
    @popUp (world.center().subtract @extent().floorDivideBy 2), world

  popUpAtHand: ->
    @popUp world.hand.position(), world

  popUp: (pos, morphToAttachTo) ->
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
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    # shadow must be added after the morph
    # has been placed somewhere because
    # otherwise there is no visible image
    # to base the shadow on
    # P.S. this is the thing that causes the MenuMorph buffer
    # to be painted after the creation.
    @addShadow()
    @fullChanged()

