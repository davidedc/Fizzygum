# MenuWdgts is a Pop-up with basically a vertical stack of buttons

class MenuWdgt extends PopUpWdgt

  target: nil
  title: nil
  environment: nil
  fontSize: nil
  label: nil

  # Role query (replaces `m instanceof MenuWdgt` in ActivePointerWdgt's menuAtPointer filter + the
  # click-outside-a-menu dismissal): "am I a menu?" -- distinguishes menus from other pop-ups. True here,
  # inherited by PromptWdgt/SaveShortcutPromptWdgt (mirroring the instanceof); dispatched via ?() (nothing
  # on Widget). Parallels isWindow. (type-test-elimination campaign)
  isMenu: ->
    true

  # widgetOpeningThePopUp is the one required argument; everything else rides an opts object
  # (P5 arg-object conversion). Defaults match the old positional signature: killOutside /
  # killOnTriggers true; target / title / environment / fontSize nil.
  constructor: (@widgetOpeningThePopUp, opts = {}) ->
    @target = opts.target
    @killThisPopUpIfClickOutsideDescendants = opts.killOutside ? true
    @killThisPopUpIfClickOnDescendantsTriggers = opts.killOnTriggers ? true
    @title = opts.title
    @environment = opts.environment
    @fontSize = opts.fontSize
    if @killThisPopUpIfClickOutsideDescendants
      @onClickOutsideMeOrAnyOfMyChildren "close"
    super @widgetOpeningThePopUp, @killThisPopUpIfClickOutsideDescendants, @killThisPopUpIfClickOnDescendantsTriggers
    @isLockingToPanels = false
    @appearance = new MenuAppearance @
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor

    @_buildMenuLabel()

  # Build the label via the NoSettle core, settling ONCE at the end (orphan-settledness:
  # `new MenuWdgt` returns settled). Only the LABEL is ctor-built: a menu's ITEMS are composed
  # by the opener after construction (addMenuItem/addLine), and it lays itself out at popup.
  # The name is deliberately DISTINCT from `_buildAndConnectChildren` — same reason as
  # ScrollPanelWdgt._buildScrollFrame: MenuWdgt is a base whose subclasses (PromptWdgt,
  # SaveShortcutPromptWdgt) build their own children, and CoffeeScript binds a subclass's
  # constructor params only AFTER super(), so a virtual `_buildAndConnectChildren` called
  # from THIS base constructor would dispatch into the subclass's core too early.
  _buildMenuLabel: ->
    @_settleLayoutsAfter => @_buildMenuLabelNoSettle()

  _buildMenuLabelNoSettle: ->
    if @title
    # own method, not inlined, so a future title-change rebuild can reuse @_createLabel()
      @_createLabel()
      @_addNoSettle @label

  colloquialName: ->
    if @title
      return "\"" + @title + "\" menu"
    else
      return "menu"

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW , WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW, 0
    @layoutSpecDetails.canSetHeightFreely = false


  createLine: (height = 1) ->
    new DividerWdgt height

  addLine: (height) ->
    item = @createLine height
    @__add item

  prependLine: (height) ->
    item = @createLine height
    @__add item,nil,0
  
  _createLabel: ->
    @label = new MenuHeader @title

  # Builds a MenuItemWdgt from a MenuItemSpec (the per-item fields) and this
  # menu's context: the font (this menu's @fontSize, or the global default) and
  # -- note the historical mapping -- this menu's @target as the item's
  # "environment" and this menu's @environment as the item's widgetEnv. The
  # spec's named fields replace what used to be a 17-argument positional call
  # carrying a per-argument trailing comment on every line.
  createMenuItem: (menuItemSpec) ->
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
      if destroyNextLines and item.isDivider?()
        item.fullDestroy()
      if item.isDivider?()
        destroyNextLines = true
        continue
      else
        destroyNextLines = false

  # Public menu-row API (P5 arg-object conversion): label / target / action are the three
  # everyday positional arguments; anything else — closesUnpinnedPopUps, toolTip, color, bold,
  # italic, doubleClickAction, arg1, arg2, representsAWidget — rides an opts object. The spec's
  # own constructor defaults (closes-unpinned true; bold/italic/representsAWidget false) fill
  # any opt the caller omits, so the old defaults are reproduced exactly.
  addMenuItem: (label, target, action, opts = {}) ->
    @__add @createMenuItem @_menuItemSpecFrom label, target, action, opts

  prependMenuItem: (label, target, action, opts = {}) ->
    @__add (@createMenuItem @_menuItemSpecFrom label, target, action, opts), nil, 0

  _menuItemSpecFrom: (label, target, action, opts) ->
    new MenuItemSpec label, opts.closesUnpinnedPopUps, target, action,
      opts.toolTip, opts.color, opts.bold, opts.italic,
      opts.doubleClickAction, opts.arg1, opts.arg2, opts.representsAWidget

  # »>> this part is excluded from the fizzygum homepage build

  # this is used by the test system to check that the menu
  # has the correct number of items: children minus the top
  # label (a shadow lives in @shadowInfo, never a child, so
  # there is nothing to exclude for it).
  testNumberOfItems: ->
    @testItems().length

  # this is used by the test system to check that the menu
  # has the correct items: the children minus the top label
  # (a shadow lives in @shadowInfo, never a child, so there
  # is nothing to exclude for it).
  testItems: ->
    items = []
    for item in @children
      if item != @label
        items.push item
    items

  # this part is excluded from the fizzygum homepage build <<«

  _reLayoutSelf: ->
    super()

    # no point in breaking a rectangle for each menu entry,
    # let's hold on the broken rects and then issue
    # a fullChanged() at the end.
    world.disableTrackChanges()




    @cornerRadius = if WorldWdgt.preferencesAndSettings.isFlat then 0 else 5
    @color = Color.create 238, 238, 238
    @__commitExtent new Point 0, 0
    y = @top()
    x = @left() + 2

    if @title
      @label._applyMoveTo @position().add 2
      y = @label.bottom()
    else
      y = @top()
    y += 1

    # public-call-sanctioned: removeShadow is the public shadow API (the pop-up shadow policy also
    # drives it) — this pass re-baselines the menu's shadow before re-laying out; pre-existing design.
    @removeShadow()

    # note that menus can contain:
    # strings, colorpickers,
    # sliders, menuItems (which are buttons)
    # and divider lines.
    for item in @children
      if item == @label then continue
      item._applyMoveTo new Point x, y
      y = y + item.height()
  
    @adjustWidthsOfMenuEntries()
    fb = @fullBounds()
    # add some padding to the right and bottom of the menu
    @__commitExtent fb.extent().add 2
    world.maybeEnableTrackChanges()
    @fullChanged()
  
  maxWidthOfMenuEntries: ->
    w = 0
    # Each entry that contributes a width answers menuEntryPreferredWidth()
    # (MenuItemWdgt / StringFieldWdgt / ColorPickerWdgt / SliderWdgt define it);
    # divider lines and the header don't, and are skipped -- exactly the set the
    # old `instanceof` chain matched.
    @children.forEach (item) ->
      if item.menuEntryPreferredWidth?
        w = Math.max w, item.menuEntryPreferredWidth()

    if @label
      w = Math.max w, @label.width()
    w
  
  # makes all the elements of this menu the
  # right width.
  adjustWidthsOfMenuEntries: ->
    w = @maxWidthOfMenuEntries()
    world.disableTrackChanges()
    @children.forEach (item) =>
      item._applyWidth w
    world.maybeEnableTrackChanges()

  
  unselectAllItems: ->
    # only menu items carry a selection state; each resets its own (was
    # `if item instanceof MenuItemWdgt`). (type-test-elimination campaign)
    @children.forEach (item) ->
      item.unselect?()

    @changed()



