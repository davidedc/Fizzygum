# A vertical stack of rows (menu items, dividers, and small editors like
# sliders / colour-pickers / string fields) — the pure LAYOUT half of a
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
# dividers are DividerWdgt. Rows are added by the owner after construction
# (addMenuItem / addLine), matching MenuWdgt's compose-after-build protocol.
#
# LAYOUT (§5.2e): the panel IS a SimpleVerticalStackPanelWdgt — the ONE vertical-
# stack engine lays the rows out (the optional MenuHeader is just child 0, stacked
# like any row). Menu-ness enters only through the base's own policy seams:
#  - border 2 / gap 0: the stack's padding knob set tight, with the new
#    interElementGap() policy at 0 so rows sit FLUSH inside the 2px border;
#  - width: a menu SELF-sizes to its widest row (a general stack takes its width
#    from its container) and then EQUALIZES — every row is stretched to the full
#    row width so hover highlights span the menu. Both live in the
#    _positionAndResizeChildren specialization below, around super().
# Unlike a general stack the panel accepts no drops and imposes no width ratio
# (suppressed below). It IS a size-tracking container now: membership changes
# re-arrange it via the engine; the wrapping MenuWdgt / PromptWdgt absorbs those
# through _reLayOutAfterContainedPanelChange (re-lay + re-hug), see PopUpWdgt.

class MenuRowsPanelWdgt extends SimpleVerticalStackPanelWdgt

  target: nil
  environment: nil
  fontSize: nil
  title: nil
  label: nil
  _selectsItemsOnClick: false
  # A menu / list-contents row-stack is the internal body of a pop-up or scroll
  # frame — it accepts no drops and imposes no width ratio on its rows, unlike a
  # general SimpleVerticalStackPanelWdgt (which does both). Suppress the inherited
  # container behaviours.
  _acceptsDrops: false

  imposesRatioConstraintOnDroppedChildren: ->
    false

  releasesRatioConstraintOnGrabbedChildren: ->
    false

  constructor: (opts = {}) ->
    # padding 2 = the menu's tight border; rows stack FLUSH inside it (see
    # interElementGap below). No extent/color through the base ctor — the look
    # is set right here.
    super nil, nil, 2
    @target = opts.target
    @environment = opts.environment
    @fontSize = opts.fontSize
    @title = opts.title
    @_selectsItemsOnClick = opts.selectsItemsOnClick ? false
    # replace the stack's RectangularAppearance: the panel draws the menu box
    # (rounded when titled, stroked with the menu stroke).
    @appearance = new MenuAppearance @
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor
    @color = Color.create 238, 238, 238
    if @title
      @cornerRadius = if WorldWdgt.preferencesAndSettings.isFlat then 0 else 5
    @_buildMenuLabel()

  colloquialName: ->
    "menu rows"

  # menu rows sit FLUSH (contiguous hover highlights); only the outer border
  # keeps the 2px padding. See the base's interElementGap policy comment.
  interElementGap: ->
    0

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
      # the RAW structural add, exactly like the rows (addMenuItem -> __add): the
      # header is just child 0 of the stack, composed before the driver arranges;
      # the stack's _addNoSettle insert-by-height + pre-resize protocol is for
      # interactive drops, not for the menu's compose-after-build protocol.
      @__add @label

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

  # The stack arrange, specialized by menu POLICY around super() (§5.2e):
  #  1. WIDTH: a menu SELF-sizes to its widest row + border (a general stack
  #     takes its width from its container) — hug the width FIRST so super()
  #     distributes exactly that.
  #  2. super() stacks all children (header first, rows flush inside the 2px
  #     border) at their natural widths and hugs my height.
  #  3. EQUALIZE: stretch every row to the full row width so hover highlights
  #     span the menu — a plain stack leaves a narrow row narrow. The stretch
  #     goes through the VIRTUAL _applyWidth (not the arrange's base extent
  #     apply) because several row types re-lay their innards there: a slider
  #     re-lays its button, a string field its text, the MenuHeader re-centres
  #     its title.
  _positionAndResizeChildren: ->
    # no point in breaking a rectangle for each row; hold the broken rects and
    # issue ONE fullChanged() at the end.
    world.disableTrackChanges()
    @_applyExtentBase new Point (@maxWidthOfMenuEntries() + 2 * @padding), @height()
    super()
    w = @availableWidthForContents()
    @children.forEach (item) ->
      item._applyWidth w
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

  unselectAllItems: ->
    # only menu items carry a selection state; each resets its own.
    @children.forEach (item) ->
      item.unselect?()

    @changed()
