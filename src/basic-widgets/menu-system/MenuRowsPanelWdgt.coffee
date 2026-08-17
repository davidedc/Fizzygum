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
#    from its container) — the _positionAndResizeChildren specialization hugs
#    the width, then super() distributes it; the _childWidthInStack policy hands
#    every row the full row width, so hover highlights span the menu. Each row
#    kind arranges its own innards through the engine's standard chokepoints
#    (menu-row-conformance Phase 2), so no equalization post-pass exists.
# Unlike a general stack the panel accepts no drops and imposes no width ratio
# (suppressed below). It IS a size-tracking container now: membership changes
# re-arrange it via the engine; the wrapping MenuWdgt / PromptWdgt absorbs those
# through _reLayOutAfterContainedPanelChange (re-lay + re-hug), see PopUpWdgt.

class MenuRowsPanelWdgt extends SimpleVerticalStackPanelWdgt

  target: undefined
  environment: undefined
  fontSize: undefined
  title: undefined
  label: undefined
  # the rounding of the panel's own corners. Declared per class rather than pulled up:
  # this class extends SimpleVerticalStackPanelWdgt, not BoxWdgt, which is where the
  # framework's other cornerRadius lives.
  cornerRadius: undefined
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
    super padding: 2
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

  # Row width POLICY (the base's per-child sizing seam): every row takes the
  # FULL row width — menus equalize so hover highlights span the menu — where
  # the base's spec-derived answer would leave a narrower row at its natural
  # width. With this, both engine branches emerge equalized and no stretch
  # post-pass is needed (menu-row-conformance Phase 2e — falsification history
  # in docs/archive/menu-row-conformance-plan.md).
  _childWidthInStack: (widget, availForContents) ->
    availForContents

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
  # the same reason PromptWdgt states: a subclass binds its ctor params only after
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
    @__add item, atIndex: 0

  # Builds a MenuItemWdgt from a MenuItemSpec and this panel's context: the font (this panel's
  # @fontSize, or the global default) and the environment pair. ⚠ Note the CROSSOVER, which the
  # named options now make visible where positional slots hid it: this panel's @target is the
  # item's dataSource, and this panel's @environment is the item's widgetEnv.
  createMenuItem: (menuItemSpec) ->
    @_subscribeToReflectedSource menuItemSpec.reflection
    item = new MenuItemWdgt menuItemSpec,
      fontSize: (@fontSize or WorldWdgt.preferencesAndSettings.menuFontSize)
      fontStyle: WorldWdgt.preferencesAndSettings.menuFontName
      dataSource: @target
      widgetEnv: @environment
    if !@environment?
      item.dataSourceWidgetForTarget = item
      item.widgetEnv = @target

    item

  # ── REFLECTED ROWS: a row that SHOWS somebody else's value (MenuRowReflectionSpec) ──────────
  # Subscribe me, once, to each distinct source among my reflecting rows: a dataflow edge
  # source → me whose action is my reconciler. Then when that source announces itself (markStale),
  # the drain delivers to EVERY subscribed panel — which is the whole difference from the
  # hand-rolled fix-ups this replaces, where a menu could only ever re-tick itself, at the moment it
  # was clicked. N open copies now agree, and so does one open across a change made by a script, the
  # loader, or another menu.
  #   ⚠ addEdge, NOT ensureWireEdges: that one MIRRORS a controller's wire list, so it drops any wire
  # edge the list does not account for — and my subscription is not a wire and is not in anybody's
  # list. (It survives regardless, because the removal spares firesOnAnyChange records; declaring it
  # through the wire vocabulary would still be claiming to be something I am not.)
  #   Dedup is mine to do (addEdge appends a fresh record per call, and a seven-row wallpaper menu
  # would otherwise subscribe seven times and be reconciled seven times per change) — asked of the
  # engine's index rather than tracked in a field of my own, which would have to be declared,
  # deep-copied and serialized to say something the index already knows.
  #   Lifecycle needs nothing: a closed menu is destroyed, and Widget._destroyNoSettle calls
  # removeAllEdgesOf, which drops me from every producer's out-set.
  #   firesOnAnyChange says what my rows actually watch. A source's VALUE (its principal pin) is
  # rarely the property a row shows — a text's font, its soft wrap, a wire's delivery policy are
  # none of them the text's value — so I must be woken by markNonValueChange too. It is also what
  # makes me safe to keep: a re-wired controller drops its old WIRE and spares this edge, where the
  # blunt older removal would have unsubscribed an open menu (DataflowEngine._removeOutgoingWireEdgesOf).
  # I never read the delivered value; every row re-reads its own source through its readerName.
  _subscribeToReflectedSource: (reflection) ->
    return unless reflection?.source?
    return if world.dataflow.hasEdge reflection.source, @
    world.dataflow.addEdge reflection.source, @, action: "reconcileReflectedRows", firesOnAnyChange: true

  # Re-derive every reflecting row's label from the value it shows.
  #   This is the reactive CONNECTOR lane and it is the only entrypoint: the drain reaches it by the
  # computed name `_#{action}Connector` from the edge's action, and it JOINS the pass's settle
  # instead of opening one (a sink must never open a settle mid-drain — dataflow rules; the engine
  # has already opened one for the pass). check-layering rule [P] sanctions
  # _settleLayoutsAfterOrJoinEnclosingPass for exactly this shape and nothing else, so a "simpler"
  # single public method using it is rejected — correctly.
  #   There is deliberately no public `reconcileReflectedRows` twin: nothing calls one. Rows are born
  # showing the right value (MenuItemWdgt's constructor reads the reflection), so the only re-derive
  # that ever has to happen is the reactive one.
  _reconcileReflectedRowsConnector: (ignored) ->
    @_settleLayoutsAfterOrJoinEnclosingPass => @_reconcileReflectedRowsNoSettle()

  _reconcileReflectedRowsNoSettle: ->
    for row in @children
      row._applyRowReflectionNoSettle?()
    return

  # Drop the row with this label. Matched WITHOUT the tick decoration on either side: a reflecting
  # row's prefix follows the value it shows, so the spelling on screen is not something a caller
  # removing a row by name can know. Pass the bare name ("soft wrap"); a decorated one still works.
  removeMenuItem: (label) ->
    wanted = label.withoutTickDecoration()
    item = @firstChildSuchThat (m) ->
      m.label? and m.label.text.withoutTickDecoration() == wanted
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
    @__add (@createMenuItem @_menuItemSpecFrom label, target, action, opts), atIndex: 0

  # The spec takes the SAME label/target/action head and the SAME opts vocabulary
  # this method is handed, so it forwards rather than transcribes -- an opt added
  # to one is available on the other with no edit here.
  _menuItemSpecFrom: (label, target, action, opts) ->
    new MenuItemSpec label, target, action, opts

  # The stack arrange, specialized by ONE menu policy: a menu SELF-sizes its
  # width to its widest row + border (a general stack takes its width from its
  # container) — hug the width FIRST so super() distributes exactly that.
  # Row equalization needs no pass of its own: _childWidthInStack (above) hands
  # every row the full row width, and each row kind arranges its own innards
  # through the engine's standard chokepoints (header/slider/field track via
  # _reLayoutChildren, the picker via its deferred _reLayout; items and
  # dividers are true leaves), so BOTH engine branches emerge equalized. The
  # retired interim post-pass this replaced is in
  # docs/archive/menu-row-conformance-plan.md (Phase 2e).
  _positionAndResizeChildren: ->
    @_applyExtentBase new Point (@maxWidthOfMenuEntries() + 2 * @padding), @height()
    super()

  # HONEST pure measures (menu-row-conformance Phase 3): my width is
  # CONTENT-driven — the hug the arrange above applies — not container-given,
  # so the measures answer that same truth instead of the base's
  # availW-distributing arithmetic: a measuring parent sees exactly the width
  # the arrange will commit. Height rides the base measure AT the hug width
  # (which _childWidthInStack then hands to every row, mirroring the arrange).
  # The panel is a hug-class stack on BOTH axes — the base already hugs height
  # (tight: true); these make the width story symmetric. (No consumer exists
  # today — ListWdgt opts out of the scroll-stack refit — so this is model
  # honesty for the next consumer, not a behaviour change.)
  preferredExtentForWidth: (availW) ->
    hugW = @maxWidthOfMenuEntries() + 2 * @padding
    new Point hugW, (super hugW).y

  subWidgetsMergedPreferredBounds: (availW) ->
    super (@maxWidthOfMenuEntries() + 2 * @padding)

  # My preferred row width: the widest child's PURE content measure. Every row
  # kind that contributes a width answers menuEntryPreferredWidth() — MenuItemWdgt
  # / StringFieldWdgt / ColorPickerWdgt / SliderWdgt and (since the conformance
  # arc's Phase 1) the MenuHeader too, so the walk is uniform; divider lines
  # don't answer and are skipped. All the measures are stretch-immune (frozen or
  # content-derived), so re-arranges can legitimately SHRINK the hug — the old
  # `@label.width()` read-back special case ratcheted the width up forever.
  maxWidthOfMenuEntries: ->
    w = 0
    @children.forEach (item) ->
      if item.menuEntryPreferredWidth?
        w = Math.max w, item.menuEntryPreferredWidth()
    w

  unselectAllItems: ->
    # only menu items carry a selection state; each resets its own.
    @children.forEach (item) ->
      item.unselect?()

    @_changed()
