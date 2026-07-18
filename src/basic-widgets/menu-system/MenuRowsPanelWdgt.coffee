# A self-laying vertical stack of rows (menu items, dividers, and small editors
# like sliders / colour-pickers / string fields) — the pure LAYOUT half of a
# menu, split from the pop-up behaviour (which lives in PopUpWdgt). It carries no
# menu-ness of its own: no pop-up membership, no click-outside-to-close, no
# shadow. What a wrapping PopUpWdgt (a MenuWdgt or a PromptWdgt) owns is the
# transient/pin behaviour + shadow; what a ListWdgt owns is the surrounding
# scroll frame. Either way the visible body — box, optional title header, and the
# rows — is drawn HERE.
#
# Two knobs shape a panel to its client:
#  - `title`: when given, the panel draws a rounded titled body (a MenuHeader row
#    at the top, corner radius) — the shape a menu / prompt wants. Omitted, the
#    panel is a plain square row-stack — the shape a ListWdgt's contents want.
#  - `selectsItemsOnClick`: true makes each MenuItemWdgt SELECT on click (a list),
#    false makes it TRIGGER (a menu / prompt's Ok-Close). MenuItemWdgt.isListItem
#    dispatches on it via ?(); default false so a plain menu reads falsy.
#
# Rows answer menuEntryPreferredWidth() (MenuItemWdgt / StringFieldWdgt /
# ColorPickerWdgt / SliderWdgt) so every row is widened to the panel's widest;
# dividers are DividerWdgt. The panel lays itself out in _reLayoutSelf (like the
# menu does) — it hand-sizes to its rows, it is NOT a size-tracking container, so
# it defines no _reLayoutChildren. Rows are added by the owner after construction
# (addMenuItem / addLine), matching MenuWdgt's compose-after-build protocol.
#
# Base is Widget (not PanelWdgt): the panel does not clip — a ListWdgt's scroll
# frame does — and the menu whose row-stack this is was never a panel.

class MenuRowsPanelWdgt extends Widget

  target: nil
  environment: nil
  fontSize: nil
  title: nil
  label: nil
  _selectsItemsOnClick: false

  constructor: (opts = {}) ->
    super()
    @target = opts.target
    @environment = opts.environment
    @fontSize = opts.fontSize
    @title = opts.title
    @_selectsItemsOnClick = opts.selectsItemsOnClick ? false
    @appearance = new MenuAppearance @
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor
    @_buildMenuLabel()

  # Role query: rows in a select-on-click panel are list entries; elsewhere they
  # trigger. MenuItemWdgt.isListItem dispatches on it via ?(), so a plain MenuWdgt
  # (which does not answer it) reads false.
  selectsItemsOnClick: ->
    @_selectsItemsOnClick

  # I am the internal body of a menu / prompt / list -- an implementation detail,
  # not a widget the user picks. Stay OUT of the ancestor hierarchy-disambiguation
  # menu (Widget.getHierarchyMenuWidgets), like a stack inside a stack-scroll-panel
  # or a PanelWdgt inside a ScrollPanelWdgt. Capability ?() at the call site, so no
  # instanceof there (type-test-elimination convention).
  hiddenFromHierarchyMenu: ->
    true

  # My input slider's track press jump-drags its button, like a scroll frame's
  # scrollbars do — SliderWdgt.mouseDownLeft asks its parent via ?(); see
  # ScrollPanelWdgt.sliderTrackPressJumpsButton (type-test-elimination ε).
  sliderTrackPressJumpsButton: ->
    true

  # Build the title header (when titled) via the NoSettle core, settling ONCE at
  # the end (orphan-settledness: `new X` returns settled). Only the HEADER is
  # ctor-built: the ROWS are composed by the owner after construction
  # (addMenuItem / addLine). Distinct name from `_buildAndConnectChildren` for
  # the same reason MenuWdgt states: a subclass binds its ctor params only after
  # super(), so a virtual builder called from a base ctor would dispatch too early.
  _buildMenuLabel: ->
    @_settleLayoutsAfter => @_buildMenuLabelNoSettle()

  _buildMenuLabelNoSettle: ->
    if @title
      @_createLabel()
      @_addNoSettle @label

  _createLabel: ->
    @label = new MenuHeader @title

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

  # used by the test system to check the row count / rows: children minus the top
  # title header (a shadow lives in @shadowInfo, never a child, so there is
  # nothing to exclude for it).
  testNumberOfItems: ->
    @testItems().length

  testItems: ->
    items = []
    for item in @children
      if item != @label
        items.push item
    items

  # this part is excluded from the fizzygum homepage build <<«

  _reLayoutSelf: ->
    super()

    # no point in breaking a rectangle for each row, let's hold on the broken
    # rects and then issue a fullChanged() at the end.
    world.disableTrackChanges()

    if @title
      @cornerRadius = if WorldWdgt.preferencesAndSettings.isFlat then 0 else 5
    @color = Color.create 238, 238, 238
    @__commitExtent new Point 0, 0

    if @title
      @label._applyMoveTo @position().add 2
      y = @label.bottom()
    else
      y = @top()
    y += 1
    x = @left() + 2

    for item in @children
      if item == @label then continue
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
    # divider lines and the title header don't, and are skipped.
    @children.forEach (item) ->
      if item.menuEntryPreferredWidth?
        w = Math.max w, item.menuEntryPreferredWidth()
    if @label
      w = Math.max w, @label.width()
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
