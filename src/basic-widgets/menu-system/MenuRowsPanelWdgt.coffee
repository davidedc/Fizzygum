# A self-laying vertical stack of rows (menu items, dividers, and small editors
# like sliders / colour-pickers / string fields), WITHOUT any menu-ness: no
# pop-up membership, no title header, no click-outside-to-close, no corner
# radius, no shadow. It is the pure LAYOUT half of a menu, split from the pop-up
# behaviour (which lives in PopUpWdgt), so a ListWdgt can own a row-stack directly
# instead of borrowing a whole pop-up menu it has to cripple.
#
# Rows answer menuEntryPreferredWidth() (MenuItemWdgt / StringFieldWdgt /
# ColorPickerWdgt / SliderWdgt) so every row is widened to the panel's widest;
# dividers are DividerWdgt. The panel lays itself out in _reLayoutSelf (like the
# menu does) — it hand-sizes to its rows, it is NOT a size-tracking container, so
# it defines no _reLayoutChildren. Rows are added by the owner after construction
# (addMenuItem / addLine), matching MenuWdgt's compose-after-build protocol.
#
# The look is a plain menu body: MenuAppearance (a plain BoxyAppearance), the menu
# stroke colour, and a 238-grey fill committed each layout. Base is Widget (not
# PanelWdgt): the panel does not clip — the ListWdgt's scroll frame does — and the
# menu whose row-stack this is was never a panel.

class MenuRowsPanelWdgt extends Widget

  target: nil
  environment: nil
  fontSize: nil

  constructor: (opts = {}) ->
    super()
    @target = opts.target
    @environment = opts.environment
    @fontSize = opts.fontSize
    @appearance = new MenuAppearance @
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor

  # Role query: rows in THIS panel are list entries (click selects, not triggers).
  # MenuItemWdgt.isListItem dispatches on it via ?(), so a plain MenuWdgt (which
  # does not answer it) reads false.
  selectsItemsOnClick: ->
    true

  createLine: (height = 1) ->
    new DividerWdgt height

  addLine: (height) ->
    item = @createLine height
    @__add item

  prependLine: (height) ->
    item = @createLine height
    @__add item, nil, 0

  # Builds a MenuItemWdgt from a MenuItemSpec and this panel's context: the font
  # (this panel's @fontSize, or the global default) and -- note the historical
  # mapping -- this panel's @target as the item's "environment" and @environment
  # as the item's widgetEnv.
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

  # label / target / action are the everyday positional arguments; the rest ride
  # an opts object (the spec's own constructor defaults fill any omitted opt).
  addMenuItem: (label, target, action, opts = {}) ->
    @__add @createMenuItem @_menuItemSpecFrom label, target, action, opts

  prependMenuItem: (label, target, action, opts = {}) ->
    @__add (@createMenuItem @_menuItemSpecFrom label, target, action, opts), nil, 0

  _menuItemSpecFrom: (label, target, action, opts) ->
    new MenuItemSpec label, opts.closesUnpinnedPopUps, target, action,
      opts.toolTip, opts.color, opts.bold, opts.italic,
      opts.doubleClickAction, opts.arg1, opts.arg2, opts.representsAWidget

  # »>> this part is excluded from the fizzygum homepage build

  # used by the test system to check the row count / rows (there is no header row
  # to exclude, and a shadow lives in @shadowInfo, never a child).
  testNumberOfItems: ->
    @testItems().length

  testItems: ->
    items = []
    for item in @children
      items.push item
    items

  # this part is excluded from the fizzygum homepage build <<«

  _reLayoutSelf: ->
    super()

    # no point in breaking a rectangle for each row, let's hold on the broken
    # rects and then issue a fullChanged() at the end.
    world.disableTrackChanges()

    @color = Color.create 238, 238, 238
    @__commitExtent new Point 0, 0
    y = @top() + 1
    x = @left() + 2

    for item in @children
      item._applyMoveTo new Point x, y
      y = y + item.height()

    @adjustWidthsOfMenuEntries()
    fb = @fullBounds()
    # add some padding to the right and bottom
    @__commitExtent fb.extent().add 2
    world.maybeEnableTrackChanges()
    @fullChanged()

  maxWidthOfMenuEntries: ->
    w = 0
    # Each row that contributes a width answers menuEntryPreferredWidth()
    # (MenuItemWdgt / StringFieldWdgt / ColorPickerWdgt / SliderWdgt define it);
    # divider lines don't, and are skipped.
    @children.forEach (item) ->
      if item.menuEntryPreferredWidth?
        w = Math.max w, item.menuEntryPreferredWidth()
    w

  # makes all the rows of this panel the right width.
  adjustWidthsOfMenuEntries: ->
    w = @maxWidthOfMenuEntries()
    world.disableTrackChanges()
    @children.forEach (item) =>
      item._applyWidth w
    world.maybeEnableTrackChanges()

  unselectAllItems: ->
    # only menu items carry a selection state; each resets its own.
    @children.forEach (item) ->
      item.unselect?()

    @changed()
