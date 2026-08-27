# A vertical stack of rows (menu items, dividers, and small editors like
# sliders / colour-pickers / string fields) — the pure LAYOUT half of a
# menu, carrying no menu-ness of its own: no pop-up membership, no
# click-outside-to-close, no shadow, no title. A pop-up FRAME (a MenuWdgt or a
# PromptWdgt) owns the transient/pin behaviour, the title strip and the shadow, and
# paints the box around me; a ListWdgt owns the surrounding viewport and leaves my own
# box painting me. Either way the ROWS are laid out HERE.
#
# One knob shapes a panel to its client:
#  - `selectsItemsOnClick`: true makes each MenuItemWdgt SELECT on click (a list),
#    false makes it TRIGGER (a menu / prompt's Ok-Close). MenuItemWdgt.isListItem
#    dispatches on it via ?(); default false so a plain menu reads falsy.
#
# Rows answer menuEntryPreferredWidth() (MenuItemWdgt / StringFieldWdgt /
# ColorPickerWdgt / SliderWdgt) so every row is widened to the panel's widest;
# dividers are DividerWdgt. Rows are added by the owner after construction
# (addMenuItem / addLine), matching MenuWdgt's compose-after-build protocol.
#
# LAYOUT (§5.2e): the panel IS a VerticalStackPanelWdgt — the ONE vertical-
# stack engine lays the rows out. Menu-ness enters only through the base's own policy seams:
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
# re-arrange it via the engine; the viewport I sit in absorbs those through
# _reLayOutAfterContainedPanelChange (re-lay + re-hug the frame), see PopUpRowsViewportWdgt.

class CommandPanelWdgt extends VerticalStackPanelWdgt

  target: undefined
  fontSize: undefined
  # the rounding of the panel's own corners. Declared per class rather than pulled up:
  # this class extends VerticalStackPanelWdgt, not BoxWdgt, which is where the
  # framework's other cornerRadius lives.
  cornerRadius: undefined
  _selectsItemsOnClick: false
  # A menu / list-contents row-stack is the internal body of a pop-up or viewport
  # — it accepts no drops and imposes no width ratio on its rows, unlike a
  # general VerticalStackPanelWdgt (which does both). Suppress the inherited
  # container behaviours.
  _acceptsDrops: false

  # I am structure, not an editing surface. PanelWdgt says `true`, and the editor
  # SELECTION walk (WorldWdgt._widgetBeingEdited, the D21 selected-item branch) climbs
  # to the first ancestor with an OPINION — inheriting that answer would frame a
  # pencil-engaged click on a menu/list row as a selected item inside an editor.
  # `undefined` = no opinion: the walk passes through me (and the rows viewport, which
  # declares the same) to the world, and frames nothing.
  providesAmenitiesForEditing: undefined

  imposesRatioConstraintOnDroppedChildren: ->
    false

  releasesRatioConstraintOnGrabbedChildren: ->
    false

  # THE ROW-EXTRACTION OPT-IN — the parent-side query that Widget.grabsToParentWhenDragged and
  # ButtonWdgt.rejectDrags both consult, so one declaration answers both halves of a grab. A
  # command row may be dragged off a PINNED pop-up and kept — the decomposition half of
  # widget citizenship (docs/architecture/widget-citizenship.md, point 5: a part can be taken
  # OUT and reused). Nothing has to be done TO the row: it is already a ButtonWdgt
  # holding a four-slot dispatch resolved at construction against the TARGET rather than against
  # me, and it already owns whatever value it reflects (MenuItemWdgt).
  #   PINNED IS THE WHOLE CONDITION, and it is not a new mode. An unpinned pop-up IS mid-gesture
  # UI — you skid a drag across its rows while making up your mind, which is what slipperiness
  # buys — and a pinned one IS desktop furniture; the frame's lifetime state draws exactly that
  # distinction and the serializer already turns on it. You cannot take a part off something
  # mid-gesture; you can take a part off furniture. So the deliberate act is the pinning, which
  # already exists and already means "this menu stays", and extraction costs no new gesture.
  #   A COMMAND row only — a divider is punctuation. Carrying an `action` is what separates
  # them, and it is the fact that MATTERS rather than a proxy for the row's class: what
  # survives extraction is a button that still does something.
  #   A ListWdgt's rows panel needs no exception: it sits in no pop-up, so it has no holder to
  # ask (see _holdingPopUp) and answers false.
  wantsDetachOfChild: (aWdgt) ->
    return false unless aWdgt.action?
    @_holdingPopUp()?.isPersistent?() ? false

  constructor: (opts = {}) ->
    # menuRowsBorder = the menu's tight border; rows stack FLUSH inside it (see
    # interElementGap below). No extent/color through the base ctor — the look
    # is set right here.
    super padding: WorldWdgt.preferencesAndSettings.menuRowsBorder
    @target = opts.target
    @fontSize = opts.fontSize
    @_selectsItemsOnClick = opts.selectsItemsOnClick ? false
    # replace the stack's RectangularAppearance: the panel draws the square menu box,
    # stroked with the menu stroke. A pop-up frame paints its OWN box around me and turns
    # mine off (alpha 0) rather than doubling the stroke; a list's panel IS the box.
    @appearance = new MenuAppearance @
    @strokeColor = WorldWdgt.preferencesAndSettings.menuStrokeColor
    @color = Color.create 238, 238, 238

  colloquialName: ->
    "menu rows"

  # THE POP-UP FRAME I AM THE BODY OF, or undefined outside one. Asked BY PARENTAGE — my holder
  # answers, and only a pop-up's rows viewport does — rather than through the pop-up chain,
  # which answers for any FRAME (a window's list rows are not a pop-up's rows) and which
  # deliberately steps over a pop-up already marked for closure, exactly when a row's action
  # runs. A list's rows panel sits in a plain viewport, which answers nothing.
  _holdingPopUp: ->
    @parent?.holdingPopUp?()

  # The name of the pop-up I am the body of — what a ROW of mine prefixes its prompt's question
  # with ("Rectangle\nalpha value:"), so the prompt says WHAT it is about.
  popUpTitle: ->
    @_holdingPopUp()?.titleText?()

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
  # menu (Widget.getHierarchyMenuWidgets), like a stack inside a viewport
  # or a PanelWdgt inside a ViewportWdgt. Capability ?() at the call site, so no
  # instanceof there (type-test-elimination convention).
  hiddenFromHierarchyMenu: ->
    true

  # My input slider's track press jump-drags its button, like a viewport's
  # scrollbars do — SliderWdgt.pressBegan asks its parent via ?(); see
  # ViewportWdgt.sliderTrackPressJumpsButton (type-test-elimination ε).
  sliderTrackPressJumpsButton: ->
    true

  createLine: (height = 1) ->
    new DividerWdgt height

  addLine: (height) ->
    item = @createLine height
    @__add item

  prependLine: (height) ->
    item = @createLine height
    @__add item, atIndex: 0

  # Builds a MenuItemWdgt from a CommandSpec and this panel's context: the font (this panel's
  # @fontSize, or the global default) and the subject — every row of mine acts ABOUT my @target,
  # however the row's own receiver is wired.
  _createMenuItem: (commandSpec) ->
    new MenuItemWdgt commandSpec,
      fontSize: (@fontSize or WorldWdgt.preferencesAndSettings.menuFontSize)
      fontStyle: WorldWdgt.preferencesAndSettings.menuFontName
      subject: @target

  # ── REFLECTED ROWS are not mine ─────────────────────────────────────────────────────────────
  # A row that SHOWS somebody else's value (MenuRowReflectionSpec) subscribes ITSELF to that source
  # and re-reads it on delivery: MenuItemWdgt._subscribeToMyReflectedSource, and the
  # _applyRowReflectionConnector lane the drain calls. I hold no edge and take no part — what
  # reflects is the ROW, so a row keeps showing its value wherever it goes, including out of me.

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
    @__add @_createMenuItem @_commandSpecFrom label, target, action, opts

  prependMenuItem: (label, target, action, opts = {}) ->
    @__add (@_createMenuItem @_commandSpecFrom label, target, action, opts), atIndex: 0

  # The spec takes the SAME label/target/action head and the SAME opts vocabulary
  # this method is handed, so it forwards rather than transcribes -- an opt added
  # to one is available on the other with no edit here.
  _commandSpecFrom: (label, target, action, opts) ->
    new CommandSpec label, target, action, opts

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
    @_deriveRowSeparators()

  # WHICH of my rows carry a hairline above them (ruling G5, the C5 derive-at-arrange idiom): a row
  # does exactly when the child before it is another row. So my FIRST row never does -- the line
  # above it is my own border, or the pop-up title strip sitting on top of me -- and a row just
  # below a DIVIDER never does either, because the divider already IS that boundary and a hairline
  # beside it would double it.
  #   Adjacency is mine to know and no row's: a row that moves, or a row inserted between two
  # others, changes its neighbours' answers as much as its own, and only I see all three.
  _deriveRowSeparators: ->
    previousChildWasARow = false
    for child in @children
      childIsARow = child.showSeparatorAbove?
      child.showSeparatorAbove previousChildWasARow  if childIsARow
      previousChildWasARow = childIsARow
    return

  # HONEST pure measures (menu-row-conformance Phase 3): my width is
  # CONTENT-driven — the hug the arrange above applies — not container-given,
  # so the measures answer that same truth instead of the base's
  # availW-distributing arithmetic: a measuring parent sees exactly the width
  # the arrange will commit. Height rides the base measure AT the hug width
  # (which _childWidthInStack then hands to every row, mirroring the arrange).
  # The panel is a hug-class stack on BOTH axes — the base already hugs height
  # (tight: true); these make the width story symmetric. THE consumer is the
  # pop-up rows viewport's frame committer, through scrolledContentMeasure
  # below (the menu-sandwich dissolution).
  preferredExtentForWidth: (availW) ->
    hugW = @maxWidthOfMenuEntries() + 2 * @padding
    # WITH NO ROWS AT ALL my hug is just my border: the base stack has nothing to sum and
    # answers its APPLIED height instead, which is a leftover, not a measure. A titled pop-up
    # carrying no rows is exactly that case ("no widgets to attach to").
    if @children.length is 0
      return new Point hugW, 2 * @padding
    new Point hugW, (super hugW).y

  subWidgetsMergedPreferredBounds: (availW) ->
    super (@maxWidthOfMenuEntries() + 2 * @padding)

  # ── as the pop-up rows viewport's DIRECT contents (menu-sandwich dissolution) ─
  # My width is content-driven (the hug) — the committer must not width-normalize
  # me. NB constrainContentWidth itself stays true: it drives my INTERIOR
  # arithmetic (row equalization via _childWidthInStack and the pure measures'
  # per-child branch), not this viewport-facing fact.
  viewportConstrainsMyWidth: ->
    false

  # The committer's measure answers my FULL self-box — hug width, and the
  # preferredExtentForWidth height (top AND bottom border included), i.e.
  # byte-what my own arrange self-writes — not the base's children union, which
  # misses the bottom border and would disagree by 2px in the world-capped state.
  scrolledContentMeasure: (ignored_widthHint) ->
    e = @preferredExtentForWidth undefined
    new Rectangle @left(), @top(), @left() + e.x, @top() + e.y

  # My measure IS my frame, verbatim — the committer must not floor my width at the
  # window's nor grow-to-fill my height (those adjustments suit a tight:false plane;
  # against my tight hug they manufacture a two-writer fight in ANY state where the
  # viewport is transiently larger than the hug — measured twice in the dissolution's
  # Phase 0: a compose-time livelock and a duplication-path RECALC_NONCONVERGENCE).
  scrolledContentMeasureIsMyFrame: ->
    true

  # My preferred row width: the widest child's PURE content measure. Every row
  # kind that contributes a width answers menuEntryPreferredWidth() — MenuItemWdgt
  # / StringFieldWdgt / ColorPickerWdgt / SliderWdgt — so the walk is uniform; divider
  # lines don't answer and are skipped. All the measures are stretch-immune (frozen or
  # content-derived), so re-arranges can legitimately SHRINK the hug.
  #   The walk starts at what my HOLDER contributes: a pop-up frame's title is an entry of
  # mine that happens to live in its chrome, so a menu still widens for a long title. Outside
  # a pop-up (a list's panel) the climb reaches the world, which contributes nothing.
  maxWidthOfMenuEntries: ->
    w = @enclosingFrame()._titleEntryWidth?() ? 0
    @children.forEach (item) ->
      if item.menuEntryPreferredWidth?
        w = Math.max w, item.menuEntryPreferredWidth()
    w

  unselectAllItems: ->
    # only menu items carry a selection state; each resets its own.
    @children.forEach (item) ->
      item.unselect?()

    @_changed()
