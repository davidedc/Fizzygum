# CellWdgt — one VISIBLE spreadsheet cell, as a real widget (spec docs/specs/dataflow-engine-
# spec.md §9.1, Phase 8 "widgetise the grid"). The sheet materialises ONE of these per visible
# grid cell (the fixed 6×14 viewport); each is the VIEW of its SheetCellRecord (the model/dataflow
# NODE, which is untouched by this phase — the dataflow layer operates on records, never widgets).
#
# This GENERALISES Phase 4's CellSocketWdgt (which existed only for RICH cells) to EVERY cell: a
# CellWdgt renders whichever of the three value forms its cell holds (spec §9.4 classify → present),
# and it is the two-way interaction boundary a hosted interactive value-widget fires into.
#   branch 1 — the value IS a Widget (a `new SliderWdgt`) → HOST it live (hostNoSettle) + wire it.
#   branch 2 — the value answers cellPresenter() (a Color → a swatch) → host that presenter.
#   branch 3 — a scalar / error / undefined → present its toString() text as my passive StringWdgt
#              CHILD ("scalar text is a StringWdgt child, period" — owner direction 2026-07-24,
#              completing the F5 everything-is-a-widget story; the editor's exact configuration,
#              so resting and editing text align). The cell still paints its own top+left grid
#              edges and — when selected — its own ring (F5: the sheet paints nothing).
#
# Why one widget per visible cell (owner direction 2026-07-05): full Fizzygum composability — every
# cell the user sees is a real, inspectable, live-editable widget, not a paint artifact. Widget count
# is bounded by the VIEWPORT, not the (sparse) model: an off-screen cell is still a live dataflow node
# whose record recomputes with no widget present; scroll (a later sub-phase) materialises/recycles the
# viewport's CellWdgts. For v1 the viewport is the whole fixed grid, so all cells are materialised once.
#
# ── TWO-WAY BOUNDARY ─────────────────────────────────────────────────────────────────────────
# Presentation (down): the sheet's reconcile mounts a hosted widget via hostNoSettle, or sets the
# scalar text via showScalarNoSettle. Interaction (up): a hosted INTERACTIVE value-widget (a slider)
# is wired so its firings land on this cell's `cellInput`, which marks the cell STALE — the drain then
# recomputes the cell's dependents (spec §9.3 Scenario A: a drag = a per-cycle recompute of the
# closure). A presenter is "one-way glass" (spec §9.4) and is NOT wired.
#
# ── SERIALIZATION (spec §13 retain-and-remount) ──────────────────────────────────────────────
# @address (which cell — re-indexed on restore) and @hostedWidget (a ref to the child, so a
# VALUE-widget's runtime state — a dragged slider's position — rides the tree and survives save/load)
# serialize. Transient: @_sheetWidget (a back-ref cycle, re-set on re-index), @presentedValue (the
# branch-2 churn-skip), and @_scalarTextWdgt / @_scalarLookKey (the derived scalar-text child,
# rebuilt by the next reconcile). On restore the sheet re-indexes cells by address, then recompute
# RETAINS a widget-valued cell's restored widget (class match) rather than rebuilding it —
# presenters (derived) are rebuilt, scalars repaint, value-widgets (state-bearing) are kept. This
# is the SAME retain-and-remount the CellSocketWdgt used for one-per-rich-cell, now scaled to
# one-per-visible-cell.

class CellWdgt extends Widget

  # @address + @hostedWidget serialize; the back-ref, churn-skip value, derived scalar-text
  # child and the overlay editor (a mid-edit snapshot restores to a settled, not-editing
  # sheet — the re-index destroys any stray non-hosted child) are rebuilt on restore.
  @serializationTransients: ["_sheetWidget", "presentedValue", "_scalarTextWdgt", "_scalarLookKey", "_editorWdgt", "spillWidth", "spillCovered"]

  # a cell is GRID CHROME, solid with its panel — never rippable out by a drag (F4 close of a
  # latent F5 hole: when the cells moved into the SheetCellsPanelWdgt, the default
  # isLockingToPanels false silently made every cell float-draggable out of the grid;
  # pre-F5 sheet-parented cells were solid via the plain-Widget parent rule). A prototype
  # default — never an own property, so nothing serializes.
  isLockingToPanels: true

  # which cell (col/row via the model); stable across save/load
  address: undefined
  # the mounted value/presenter widget (this cell's rich child), or undefined
  hostedWidget: undefined
  # branch-2 churn-skip: the value the current presenter reflects
  presentedValue: undefined
  # back-ref to the owning SimpleSpreadsheetWdgt (set by attachSheet)
  _sheetWidget: undefined
  # branch-3 text child (a passive StringWdgt), or undefined when empty/hosting
  _scalarTextWdgt: undefined
  # the look the text child was built in (its font, alignment, inset and ink, as one key): a
  # different look rebuilds the child, the same one only re-texts it
  _scalarLookKey: undefined
  # the mounted overlay editor while THIS cell is being edited (F2/F5), or undefined
  _editorWdgt: undefined
  # TEXT SPILL (docs/archive/spreadsheet-ux-plan.md R12), set by the sheet's row reflow: the width my
  # text may run to, past my right edge over empty neighbours (undefined: my own width), and whether
  # a neighbour's text runs over ME (then I stroke no left edge, so no gridline cuts through it)
  spillWidth: undefined
  spillCovered: false

  constructor: (address) ->
    super()
    @appearance = new CellAppearance @
    @address = address
    @hostedWidget = undefined
    @presentedValue = undefined
    @_sheetWidget = undefined
    @_scalarTextWdgt = undefined
    @_scalarLookKey = undefined
    @_editorWdgt = undefined
    # transparent: the cells panel under me fills the data background; I paint my own grid
    # edges + selection ring (F5 — "the sheet paints nothing") — my scalar text is a passive
    # StringWdgt child that paints itself — so the panel's background shows through a hosted
    # widget's transparent parts (a slider's track).
    # (The CanvasGlassTopWdgt idiom — an undefined colour paints nothing.)
    @color = undefined


  # the owning sheet, re-established on build and on restore re-index (a transient back-ref, so no
  # serialized cell→sheet→cell cycle).
  attachSheet: (sheetWidget) ->
    @_sheetWidget = sheetWidget
    return

  # ── branch 3: present the scalar value's text as my passive StringWdgt child ──────────────
  # `look` is what the sheet derives from my cell's format and value and from its zoom
  # (SimpleSpreadsheetWdgt._textLookFor): {fontRole, alignment, inset, isError}. The text stands
  # `inset` in from my left and right edges and is centred on my height (vertical MIDDLE), aligned
  # left, centre or right in that span; its ink is the theme's spreadsheetValueText, or
  # spreadsheetErrorText for an error, read as the child is built: the child is derived and
  # rebuilt on restore and duplicate, so it wears the current look. The pixels come from
  # StringWdgt's standard immutable back buffers, so repeated labels share cached rasters
  # world-wide. NoSettle: called from the sheet's reconcile, which runs inside the dataflow
  # drain's layout settle (DataflowEngine._drainOnePass), and from its restyle and zoom, inside
  # theirs. Drops any hosted widget first (a cell that was rich and became a scalar). `text`
  # undefined / "" clears the cell (an emptied cell shows nothing). Churn-tolerant: a per-cycle
  # recompute (a `frame` cell) funnels into _setTextNoSettle's own no-change guard; a change of
  # look (an error colour, a format, a zoom) rebuilds the child.
  showScalarNoSettle: (text, look) ->
    @_unhostNoSettle() if @hostedWidget?
    scalarText = if text? and text != "" then text else undefined
    if not scalarText?
      if @_scalarTextWdgt?
        @_scalarTextWdgt._fullDestroyNoSettle()
        @_scalarTextWdgt = undefined
        @_scalarLookKey = undefined
        @_changed()
      return
    key = @_lookKey look
    if @_scalarTextWdgt? and @_scalarLookKey isnt key
      @_scalarTextWdgt._fullDestroyNoSettle()
      @_scalarTextWdgt = undefined
    if @_scalarTextWdgt?
      @_scalarTextWdgt._setTextNoSettle scalarText
    else
      theme = WorldWdgt.theme
      textWdgt = new StringWdgt scalarText,
        fontRole: look.fontRole
        color: (if look.isError then theme.spreadsheetErrorText else theme.spreadsheetValueText)
      textWdgt.isEditable = false
      textWdgt.horizontalAlignment = look.alignment
      textWdgt.verticalAlignment = AlignmentSpecVertical.MIDDLE
      @_addNoSettle textWdgt
      @_scalarTextWdgt = textWdgt
      @_scalarLookKey = key
      @_placeTextNoSettle textWdgt, look.inset
      # a commit's reconcile can land while my overlay editor is still mounted — the editor
      # shows the buffer, so the fresh child starts hidden and teardown reveals it
      textWdgt.__hide() if @_editorWdgt?
    return

  _lookKey: (look) ->
    r = look.fontRole
    [r.family, r.size, !!r.bold, !!r.italic, look.alignment, look.inset, !!look.isError].join "|"

  # a text child's box: `inset` in from my left edge and from the right end of my spill (my own
  # right edge when nothing spills), my whole height. The editor never spills: it stays in me.
  _placeTextNoSettle: (textWdgt, inset) ->
    span = if textWdgt is @_scalarTextWdgt and @spillWidth? then @spillWidth else @width()
    textWdgt._applyBounds (@position().add new Point inset, 0), new Point (Math.max 1, span - 2 * inset), @height()
    return

  # the sheet's row reflow sets my spill: the width my text runs to (undefined: none) and whether
  # a neighbour's text covers me. NoSettle: inside the reflow's settle.
  setSpillNoSettle: (width, covered, inset) ->
    return if width is @spillWidth and covered is @spillCovered
    @spillWidth = width
    @spillCovered = covered
    @_placeTextNoSettle @_scalarTextWdgt, inset if @_scalarTextWdgt?
    @_changed()
    return

  # the width my resting text needs (its text measured in its font at the size it was built in —
  # a fresh text has not yet fitted, so its fitting size is not yet the one to read — plus its
  # inset each side), or undefined when I show no text
  textNeedsWidth: (inset) ->
    text = @_scalarTextWdgt
    return undefined unless text?
    (Math.ceil text.calculateTextWidth text.text, text.originallySetFontSize) + 2 * inset

  # my cell's FORMAT moved (SimpleSpreadsheetWdgt.restyleCell): my own pixels read it — the fill
  # my appearance paints under my edges — so I repaint
  noteFormatChanged: ->
    @_changed()
    return

  # my children follow my box: the sheet calls this after it resizes me (a zoom) — a hosted
  # widget fills me at the gridline inset, and my text and my editor keep their inset
  placeChildrenNoSettle: (inset) ->
    @_placeHostedNoSettle @hostedWidget if @hostedWidget?
    @_placeTextNoSettle @_scalarTextWdgt, inset if @_scalarTextWdgt?
    @_placeTextNoSettle @_editorWdgt, inset if @_editorWdgt?
    return

  # ── presentation: host a widget filling this cell (the sheet's _addNoSettle + _apply* idiom) ──
  # NoSettle: called from the sheet's reconcile, which runs inside the dataflow drain's layout settle
  # (DataflowEngine._drainOnePass), and from the drop hook (F4) — it TOLERATES a widget that is
  # already my child (the drop's target.add ran first): _addNoSettle's __add is a safe
  # remove-then-append self-re-add. Any previously-hosted widget (or scalar-text child) is dropped
  # first. The hosted widget is inset by the gridline so the cell's borders/selection stay visible
  # around it (the CellSocketWdgt inset, now applied here since the cell fills the whole cell rect).
  hostNoSettle: (widget) ->
    @_unhostNoSettle()
    @_scalarTextWdgt?._fullDestroyNoSettle()
    @_scalarTextWdgt = undefined
    @_scalarLookKey = undefined
    @hostedWidget = widget
    @_addNoSettle widget
    @_placeHostedNoSettle widget
    return

  # a hosted widget fills me, inset by the gridline so my borders and selection stay visible
  _placeHostedNoSettle: (widget) ->
    inset = 2
    widget._applyBounds (@position().add new Point inset, inset), @extent().subtract new Point 2 * inset, 2 * inset
    return

  _unhostNoSettle: ->
    old = @hostedWidget
    @hostedWidget = undefined
    @presentedValue = undefined
    old?._fullDestroyNoSettle()
    return

  # ── F4 widget-entry: drop a desktop widget INTO the cell / grab it back OUT ───────────────

  # Accept gate for the hand's drop climb (ActivePointerWdgt.dropTargetFor resolves the CELL as
  # the innermost acceptor; the climb passes the payload's _dropPolicyProxy, which answers by
  # its real class): PLAIN payloads embed instantly (the drag-embed payload-class rule), WINDOW
  # payloads are refused — a 68x20 cell is no place for a window, and the cells panel + sheet
  # above refuse too, so a window drop falls through to the desktop. An override, not
  # enableDrops(): the boolean flag can't discriminate payloads.
  wantsDropOfChild: (aWdgt) ->
    not aWdgt.requiresDeliberateEmbedding()

  # The drag-out enabler (the parent-side opt-in Widget.grabsToParentWhenDragged consults in
  # its solid-with-parent branch — the wantsDropOfChild-style query family): ONLY my hosted
  # payload is loose — verified empirically at implementation that without this NO payload is
  # grabbable out of a cell (the generic solid-with-parent rule climbs the grab to the window;
  # the plan's "slider-only" risk framing was falsified — the blocker was class-independent).
  # The overlay editor and any other child stay solid with the cell. A loose PRESENTER is
  # fine: grabbing a swatch out just makes the next reconcile rebuild the derived presenter.
  wantsDetachOfChild: (aWdgt) ->
    aWdgt is @hostedWidget

  # The drop's recipient hook (runs inside ActivePointerWdgt.drop's single settle — all NoSettle
  # cores here, the cores-call-cores discipline its block comment requires). The dropped widget
  # is ALREADY my child (target.add ran); hostNoSettle tolerates that — its _addNoSettle
  # re-add is a safe remove-then-append self-re-add (__add) — and re-places it at the cell rect
  # with the standard host inset. Then the MODEL: the ENTRY kind is set by this gesture
  # (FormulaCompiler.commit stays pure source machinery): blank-commit first — clears any old
  # formula's compiledFn AND its edges through the normal path — then record the entry and mark
  # stale; the drain's recompute takes the entry-first branch and RETAINS the mounted instance.
  _reactToChildDropped: (droppedWdgt, activePointerWdgt) ->
    return unless @_sheetWidget?
    @hostNoSettle droppedWdgt
    @wireValueWidget droppedWdgt
    record = @_sheetWidget.model.getOrCreateCellAt @address
    FormulaCompiler.commit record, ""
    record.widgetEntry = droppedWdgt
    world.dataflow?.markStale record
    return

  # The symmetric gesture (runs inside the grab's settle, ActivePointerWdgt.grab): grabbing the
  # ENTRY widget back out empties the cell — clear the entry, un-wire, and
  # let the widget ride the hand. ⚠ the cached record.value is still this widget — clear it
  # through the normal blank-commit path, or the next recompute's branch-1 reconcile would
  # RE-HOST the widget right off the hand. Guarded on widgetEntry identity: grabbing a PRESENTER
  # swatch out (possible pre-F4 too) keeps its old behavior — the next reconcile rebuilds the
  # derived presenter.
  _reactToChildGrabbed: (grabbedWdgt) ->
    return unless @_sheetWidget?
    record = @_sheetWidget.model.cellAt @address
    return unless record? and record.widgetEntry? and grabbedWdgt is record.widgetEntry
    @hostedWidget = undefined if @hostedWidget is grabbedWdgt
    @presentedValue = undefined
    record.widgetEntry = undefined
    # THE un-wire, which this site hand-rolled as a bare field-clear under a comment reading "no
    # un-wire idiom exists in ControllerMixin — verified 2026-07-17". §P4 built one, and this was the
    # caller it was built for: cut exactly the wire I made in wireValueWidget and leave any other
    # connection this widget carries alone — which the old blanket removeAllEdgesOf could not do, and
    # got away with only because a value-widget in a cell had no other edges to lose.
    grabbedWdgt.unwireFrom? this, "cellInput"
    FormulaCompiler.commit record, ""
    world.dataflow?.markStale record
    @_changed()
    return

  # ── interaction: wire an interactive value-widget to fire into this cell ──────────────────
  # Hard-wire the hosted value-widget's connection to THIS cell's cellInput (spec §9.3). A widget
  # with no connection API (a plain RectangleWdgt presenter) simply isn't wired (the `?` guard).
  wireValueWidget: (widget) ->
    widget.wireTo? this, "cellInput"
    return

  # the connection target the hosted value-widget fires into: mark this cell's cell STALE so the
  # drain recomputes its dependents (this is a pooled dataflow markStale, NOT a layout settle — so no
  # settle is opened here; the drain owns any settle).
  # (`value` is named but unread — the engine hands it over and the cell answers by pulling, not by
  # taking; naming it is what tells a reader the argument arrives rather than that it matters.)
  cellInput: (value) ->
    @_sheetWidget?._markCellStaleFromHostedWidgetNoSettle @address
    return

  # ── the overlay editor (F2, reshaped by the standard-caret arc): this cell owns the
  # editor WIDGET — a real editable StringWdgt the sheet enters via world._editNoSettle, so
  # the standard CaretWdgt does the typing/click-positioning/selection work; the sheet keeps
  # the edit STATE (which cell, commit/cancel) and receives the outcome through my
  # accept/cancel handlers below. All NoSettle cores: called from the sheet's edit
  # lifecycle, inside the ONE settle its public event entries (processKeyDown /
  # activated) open. A child of THIS cell at exactly the cell's rect.
  # `look` is the sheet's editing look for my cell (SimpleSpreadsheetWdgt._editorLookFor): my
  # format's font at the zoom, left-aligned, centred on my height, at the resting text's inset.
  _mountEditorNoSettle: (seedText, look) ->
    # the editor replaces the resting scalar-text child visually for the edit's duration
    # (damage-free __hide — adding the editor repaints the same rect); teardown reveals it
    # again, which also serves the Escape-cancel path (no reconcile runs there)
    @_scalarTextWdgt?.__hide()
    editor = new StringWdgt seedText,
      fontRole: look.fontRole
      color: WorldWdgt.theme.spreadsheetValueText
    editor.isEditable = true
    editor.verticalAlignment = AlignmentSpecVertical.MIDDLE
    # an edit never leaves the cell for the pop-out "edit:" prompt — a pop-out would bypass
    # the cell's commit semantics; an over-long text stays inline-ellipsised with the caret
    # clamping at the cell edge (see the StringWdgt field comment)
    editor.alwaysEditsInline = true
    @_addNoSettle editor
    @_placeTextNoSettle editor, look.inset
    @_editorWdgt = editor
    return

  # the text the editor shows, replaced as the formula bar's text is typed into (the sheet keeps
  # the two in step, whichever holds the caret)
  mirrorEditTextNoSettle: (text) ->
    @_editorWdgt?._setTextNoSettle text
    return

  # ── standard-caret editing: the caret targets my editor child, and its accept (Enter /
  # action-elsewhere) and cancel (Escape) escalations fire FROM the editor (see
  # CaretWdgt.accept — the caret itself is already destroyed and unparented at escalation
  # time), so they land here first on the climb. Forward to the sheet, which owns the edit
  # state; the sheet guards with `return unless @_editing`, so an accept escalated by an
  # UNRELATED editable text nested in my hosted widget (a dropped widget carrying entry
  # fields) is a harmless no-op.
  # `how` names the key that ended the edit ("Enter" / "Shift+Enter", CaretWdgt.accept), or is
  # undefined for an edit ended by acting elsewhere: the sheet moves the selection for a key only.
  accept: (how) ->
    @_sheetWidget?.acceptCellEdit how
    return

  cancel: ->
    @_sheetWidget?.cancelCellEdit()
    return

  # DOUBLE-CLICK enters an edit of my cell's existing source with the caret at the clicked
  # slot (Excel-style). Reached directly (a click on my empty area) or by the escalation
  # from my non-editable scalar-text child (StringWdgt.doubleActivated's else branch); the
  # dispatcher's pos is already plane-mapped and my child/panel/sheet share the one island
  # plane, so it forwards verbatim (the 4A convention).
  doubleActivated: (pos) ->
    @_sheetWidget?.startEditAtPointer @address, pos
    return

  # Tab commits the edit and moves the selection right (Shift+Tab: left), the one "commit and
  # move" verb Enter shares (SimpleSpreadsheetWdgt.tabFromEdit). Handled here, so Widget.tab's
  # climb never reaches WorldWdgt.nextTab and hops the caret to another entry field elsewhere.
  nextTab: (editField) ->
    @_sheetWidget?.tabFromEdit 1
    return

  previousTab: (editField) ->
    @_sheetWidget?.tabFromEdit -1
    return

  _teardownEditorNoSettle: ->
    editor = @_editorWdgt
    @_editorWdgt = undefined
    editor?._fullDestroyNoSettle()
    @_scalarTextWdgt?.show()
    @_changed()
    return
