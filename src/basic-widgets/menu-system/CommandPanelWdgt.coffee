# A vertical stack of rows (menu items, dividers, and small editors like
# sliders / colour-pickers / string fields) — the pure LAYOUT half of a
# menu, carrying no menu-ness of its own: no pop-up membership, no
# click-outside-to-close, no shadow, no title. A pop-up FRAME (a MenuWdgt or a
# PromptWdgt) owns the transient/pin behaviour, the title strip and the shadow, and
# paints the box around me; a ListWdgt owns the surrounding viewport and leaves my own
# box painting me. Either way the ROWS are laid out HERE.
#
# Three knobs shape a panel to its client:
#  - `selectsItemsOnClick`: true makes each MenuItemWdgt SELECT on click (a list),
#    false makes it TRIGGER (a menu). MenuItemWdgt.isListItem
#    dispatches on it via ?(); default false so a plain menu reads falsy. It is also
#    which LOOK my rows are built with (_createMenuItem): a list's rows, or menu rows.
#  - `memberRows`: true makes me a MEMBER list's rows panel (ListWdgt's memberFactsQuery): my rows
#    are MemberRowWdgts, I take my list's width rather than hugging my rows, and I paint no box of
#    my own.
#  - `padding`: the border my rows stack inside. A pop-up hands me its content padding
#    (its content box inside its border); a list's panel keeps its own, rowsPanelPadding, or a
#    member list's memberRowsPanelPadding.
#
# Rows answer menuEntryPreferredWidth() (MenuItemWdgt / StringFieldWdgt /
# ColorPickerWdgt / SliderWdgt / PromptButtonsRowWdgt) so every row is widened to the
# panel's widest; dividers are DividerWdgt. Rows are added by the owner after construction
# (addMenuItem / addLine, or a prompt's own editors and buttons row), matching MenuWdgt's
# compose-after-build protocol.
#
# LAYOUT (§5.2e): the panel IS a VerticalStackPanelWdgt — the ONE vertical-
# stack engine lays the rows out. Menu-ness enters only through the base's own policy seams:
#  - padding / gap 0: the stack's padding knob is my client's (above), with the
#    interElementGap() policy at 0 so rows sit FLUSH inside that border;
#  - width: a menu SELF-sizes to its widest row (a general stack takes its width
#    from its container) — the _positionAndResizeChildren specialization hugs
#    the width, then super() distributes it; the _childWidthInStack policy hands
#    every row the full row width, so hover highlights span the menu. (A member
#    list's panel keeps the width its list gives it instead: _myArrangedWidth.) Each row
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
  # am I a MEMBER list's rows panel (the `memberRows` knob)? An own field only when true.
  _holdsMemberRows: false
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
  #   A MEMBER list's rows panel says `false` instead (an own field, set by my constructor): its
  # rows show their selection themselves, with their plate, so the walk STOPS at me and frames none
  # of them -- the opt-out a container managing its own selection look makes (SheetCellsPanelWdgt
  # makes the same one). Without it, the walk from a clicked member row would reach my list's plane
  # above me (a panel: true) and frame the row in the editor's outline.
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
  # survives extraction is a button that still does something. (A prompt's row of buttons
  # carries none itself and asks me on behalf of its buttons: PromptButtonsRowWdgt.wantsDetachOfChild.)
  #   A ListWdgt's rows panel needs no exception: it sits in no pop-up, so it has no holder to
  # ask (see _holdingPopUp) and answers false.
  wantsDetachOfChild: (aWdgt) ->
    return false unless aWdgt.action?
    @_holdingPopUp()?.isPersistent?() ? false

  constructor: (opts = {}) ->
    theme = WorldWdgt.theme
    # the border my rows stack FLUSH inside (see interElementGap below): my client's to give,
    # a list's rows-panel padding when it gives none (a member list's own). No extent/color
    # through the base ctor — the look is set right here.
    super padding: opts.padding ? (if opts.memberRows then theme.memberRowsPanelPadding else theme.rowsPanelPadding)
    @target = opts.target
    @fontSize = opts.fontSize
    @_selectsItemsOnClick = opts.selectsItemsOnClick ? false
    @_holdsMemberRows = true  if opts.memberRows
    # replace the stack's RectangularAppearance: the panel draws the rows box, stroked with the
    # rows-panel stroke -- a list's look. A pop-up frame paints its OWN box around me and turns
    # mine off (alpha 0) rather than doubling the stroke; a plain list's panel IS the box. A member
    # list's panel paints neither fill nor stroke, and frames none of its rows in the editor's
    # outline (providesAmenitiesForEditing, above).
    @appearance = new MenuAppearance @
    if @_holdsMemberRows
      @strokeColor = undefined
      @color = theme.memberRowsPanelFill
      @providesAmenitiesForEditing = false
    else
      @strokeColor = theme.rowsPanelStroke
      @color = theme.rowsPanelFill

  colloquialName: ->
    "menu rows"

  # THE POP-UP FRAME I AM THE BODY OF, or undefined outside one. Asked BY PARENTAGE — my holder
  # answers, and only a pop-up's rows viewport does — rather than through the pop-up chain,
  # which answers for any FRAME (a window's list rows are not a pop-up's rows) and which
  # deliberately steps over a pop-up already marked for closure, exactly when a row's action
  # runs. A list's rows panel sits in a plain viewport, which answers nothing.
  _holdingPopUp: ->
    @parent?.holdingPopUp?()

  # THE TITLE OF A PROMPT ONE OF MY ROWS OPENS: the name of the pop-up I am the body of, as stored,
  # then the prompt's question on the lines below it ("rectangle\nalpha\nvalue:"), so the prompt
  # says WHAT it is about. A pop-up with no title (an untitled submenu), or no pop-up at all (a
  # list's rows), has no name to give, and the question stands alone. Every prompt a row opens
  # takes its title here: the row's dispatcher hands the action the row itself, whose parent I am.
  promptTitleAsking: (question) ->
    nameOfMyPopUp = @_holdingPopUp()?.titleText?()
    if nameOfMyPopUp then nameOfMyPopUp + "\n" + question else question

  # menu rows sit FLUSH (contiguous hover highlights); only the outer border
  # keeps my padding. See the base's interElementGap policy comment.
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

  # A group boundary: a DividerWdgt, whose band is the theme's whoever mints it -- every group
  # boundary reads the same, so a caller has no size to give.
  createLine: ->
    new DividerWdgt

  addLine: ->
    item = @createLine()
    @__add item

  prependLine: ->
    item = @createLine()
    @__add item, atIndex: 0

  # Builds a row from a CommandSpec and this panel's context: the LOOK my rows wear -- a member
  # list's rows are MemberRowWdgts, whose look is their own; otherwise a MenuItemWdgt in a plain
  # list's look when I select on click and a menu row's when I do not (the row picks its font and
  # colours from it) -- my own @fontSize when I have one, and the subject: every row of mine acts
  # ABOUT my @target, however the row's own receiver is wired.
  _createMenuItem: (commandSpec) ->
    if @_holdsMemberRows
      return new MemberRowWdgt commandSpec,
        fontSize: @fontSize
        subject: @target
    new MenuItemWdgt commandSpec,
      listRow: @_selectsItemsOnClick
      fontSize: @fontSize
      subject: @target

  # ── REFLECTED ROWS are not mine ─────────────────────────────────────────────────────────────
  # A row that SHOWS somebody else's value (MenuRowReflectionSpec) subscribes ITSELF to that source
  # and re-reads it on delivery: MenuItemWdgt._subscribeToMyReflectedSource, and the
  # _applyRowReflectionConnector lane the drain calls. I hold no edge and take no part — what
  # reflects is the ROW, so a row keeps showing its value wherever it goes, including out of me.

  # A VALUE's words as the label of the row that offers it: capitalised like every other row's
  # label ("top" → "Top", "vert. stripes" → "Vert. stripes"), one character for one. Only the
  # LABEL is written so: the row's argument, its reflection's value and anything else keyed on
  # the value keep the value itself. A name that is data (a font, a member, a class) is never
  # passed here: it shows as it is.
  @rowLabelOfValue: (aValue) ->
    StringWdgt.inDisplayCase aValue, "sentence"

  # THE LABELS OF ONE MENU'S ROWS THAT NAME WIDGETS, one per entry of `widgets` (row order), told
  # apart from each other. A builder asks it ONCE per menu, with every widget its rows will name,
  # before adding them — a row's wording depends on its neighbours, so no row can be named alone.
  # Each widget reads its row name (Widget.rowName: "Rectangle"); widgets whose rows would read ALIKE
  # take their distinguishing detail (Widget.distinguishedRowName: 'Text "Hello"', 'Window "Docs
  # Maker"'); widgets whose rows STILL read alike are numbered in order of first appearance, the
  # first one left as it is ("Rectangle", "Rectangle 2"). A widget whose rows read like no other
  # widget's keeps its bare name. The NAME is the widget's, not the row's: a widget named by several
  # rows (a controller wired twice into one widget) reads the same in each of them.
  #   `labelFromName` (name, index) -> label is what a row says AROUND its widget's name, for rows
  # that say more than the name (a wire's row: 'Slider · value'): rows are told apart by the whole
  # of what they say. Absent, a row says the name alone.
  @rowLabelsNaming: (widgets, labelFromName = ((name) -> name)) ->
    nameOf = new Map
    nameOf.set each, each.rowName() for each in widgets
    labelAt = (i) -> labelFromName (nameOf.get widgets[i]), i
    firstAppearances = widgets.filter (each, i) -> widgets.indexOf(each) is i
    # the widgets with a row that reads like a row of ANOTHER widget, in order of first appearance
    readingAlike = ->
      alike = new Set
      for i in [0...widgets.length]
        for j in [i + 1...widgets.length]
          if widgets[j] isnt widgets[i] and labelAt(j) is labelAt(i)
            alike.add widgets[i]
            alike.add widgets[j]
      (each for each in firstAppearances when alike.has each)
    for each in readingAlike()
      nameOf.set each, each.distinguishedRowName()
    timesSeen = new Map
    for each in readingAlike()
      name = nameOf.get each
      timesSeen.set name, (timesSeen.get(name) ? 0) + 1
      nameOf.set each, name + " " + timesSeen.get(name) if timesSeen.get(name) > 1
    (labelAt i for i in [0...widgets.length])

  # Drop the row with this label. A row's label is its plain wording whatever it shows -- its tick
  # and its submenu chevron are drawn beside it, never written into it -- so the name a caller
  # removes a row by ("Soft wrap") is the text on screen.
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
  # through the engine's standard chokepoints (header/slider/field/a prompt's buttons row
  # track via _reLayoutChildren, the picker via its deferred _reLayout; items and
  # dividers are true leaves), so BOTH engine branches emerge equalized. The
  # retired interim post-pass this replaced is in
  # docs/archive/menu-row-conformance-plan.md (Phase 2e).
  _positionAndResizeChildren: ->
    @_deriveTickColumn()
    @_applyExtentBase new Point @_myArrangedWidth(), @height()
    super()
    @_deriveRowSeparators()

  # MY WIDTH, the one my arrange commits and both my pure measures report: a menu's or a plain
  # list's rows panel hugs its widest row plus my padding at each side; a MEMBER list's keeps the
  # width its list gives it (ListWdgt._positionAndResizeChildren, its own width), so its rows are as
  # wide as the list less my padding and it never scrolls sideways.
  _myArrangedWidth: ->
    return @width()  if @_holdsMemberRows
    @maxWidthOfMenuEntries() + 2 * @padding

  # Does a leading TICK COLUMN run down my rows? Exactly while one of them ticks -- a row reflecting
  # somebody's value, or one its builder made ticked or unticked (MenuItemWdgt.ticks) -- so that
  # every label of a menu with a tick in it starts at the same x, ticked or not. Never in a list: a
  # list's rows wear no indicators. A pure query, asked by my rows' own measures
  # (MenuItemWdgt._reservesTickColumn), so what a measure of mine reports is what my arrange commits.
  reservesTickColumn: ->
    return false if @_selectsItemsOnClick
    @children.some (child) -> child.ticks?()

  # WHETHER MY ROWS RESERVE THE TICK COLUMN, told to each (the C5 derive-at-arrange idiom, like the
  # separators below) -- told FIRST, before the hug reads their widths, so a row whose label the
  # column moves has re-placed it by the time it is measured and sized. A row keeps the answer when it
  # leaves me, with the rest of its look. Membership is what moves the answer, and a membership
  # change is what re-arranges me.
  _deriveTickColumn: ->
    reserved = @reservesTickColumn()
    for child in @children
      child.reserveTickColumn? reserved
    return

  # WHICH of my rows carry a hairline above them (ruling G5, the C5 derive-at-arrange idiom): a row
  # does exactly when the child before it is another row. So my FIRST row never does -- the line
  # above it is my own border -- and a row just below a DIVIDER never does either, because the
  # divider already IS that boundary and a hairline beside it would double it.
  #   Adjacency is mine to know and no row's: a row that moves, or a row inserted between two
  # others, changes its neighbours' answers as much as its own, and only I see all three.
  #   Only a plain LIST's rows wear hairlines, so its rows panel is this derive's one client: a
  # pop-up's rows are told apart by their hover plate and grouped by dividers, a member list's by
  # their selection plate alone, and neither is ever told.
  _deriveRowSeparators: ->
    return unless @_selectsItemsOnClick and not @_holdsMemberRows
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
  # the arrange will commit (a member list's panel: the width its list gave it,
  # _myArrangedWidth). Height rides the base measure AT the hug width
  # (which _childWidthInStack then hands to every row, mirroring the arrange).
  # The panel is a hug-class stack on BOTH axes — the base already hugs height
  # (tight: true); these make the width story symmetric. THE consumer is the
  # pop-up rows viewport's frame committer, through scrolledContentMeasure
  # below (the menu-sandwich dissolution).
  preferredExtentForWidth: (availW) ->
    hugW = @_myArrangedWidth()
    # WITH NO ROWS AT ALL my hug is just my border: the base stack has nothing to sum and
    # answers its APPLIED height instead, which is a leftover, not a measure. A titled pop-up
    # carrying no rows is exactly that case ("no widgets to attach to").
    if @children.length is 0
      return new Point hugW, 2 * @padding
    new Point hugW, (super hugW).y

  subWidgetsMergedPreferredBounds: (availW) ->
    super @_myArrangedWidth()

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
  # misses the bottom border and would disagree by my padding in the world-capped state.
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
  # / StringFieldWdgt / ColorPickerWdgt / SliderWdgt / PromptButtonsRowWdgt — so the walk is uniform; divider
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
