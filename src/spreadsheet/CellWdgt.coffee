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
#   branch 3 — a scalar / error / nil → present its toString() text as my passive StringWdgt
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
# branch-2 churn-skip), and @_scalarText / @_scalarIsError (derived text, rebuilt by the next
# reconcile). On restore the sheet re-indexes cells by address, then recompute RETAINS a widget-valued
# cell's restored widget (class match) rather than rebuilding it — presenters (derived) are rebuilt,
# scalars repaint, value-widgets (state-bearing) are kept. This is the SAME retain-and-remount the
# CellSocketWdgt used for one-per-rich-cell, now scaled to one-per-visible-cell.

class CellWdgt extends Widget

  # @address + @hostedWidget serialize; the back-ref, churn-skip value, derived scalar-text
  # child and the overlay editor (a mid-edit snapshot restores to a settled, not-editing
  # sheet — the re-index destroys any stray non-hosted child) are rebuilt on restore.
  @serializationTransients: ["_sheetWidget", "presentedValue", "_scalarTextWdgt", "_scalarShowsError", "_editorWdgt"]

  # a cell is GRID CHROME, solid with its panel — never rippable out by a drag (F4 close of a
  # latent F5 hole: when the cells moved into the SheetCellsPanelWdgt, the default
  # isLockingToPanels false silently made every cell float-draggable out of the grid;
  # pre-F5 sheet-parented cells were solid via the plain-Widget parent rule). A prototype
  # default — never an own property, so nothing serializes.
  isLockingToPanels: true

  constructor: (address) ->
    super()
    @address = address         # which cell (col/row via the model); stable across save/load
    @hostedWidget = nil        # the mounted value/presenter widget (this cell's rich child), or nil
    @presentedValue = nil      # branch-2 churn-skip: the value the current presenter reflects
    @_sheetWidget = nil        # back-ref to the owning SimpleSpreadsheetWdgt (set by attachSheet)
    @_scalarTextWdgt = nil     # branch-3 text child (a passive StringWdgt), or nil when empty/hosting
    @_scalarShowsError = false # true when the text child wears the error colour (SheetError badge)
    @_editorWdgt = nil         # the mounted overlay editor while THIS cell is being edited (F2/F5), or nil
    # transparent: the cells panel under me fills the data background; I paint my own grid
    # edges + selection ring + scalar text (F5 — "the sheet paints nothing"), so the panel's
    # background shows through a hosted widget's transparent parts (a slider's track).
    # (The CanvasGlassTopWdgt idiom — a nil colour paints nothing.)
    @color = nil

  colloquialName: -> "cell"

  # the owning sheet, re-established on build and on restore re-index (a transient back-ref, so no
  # serialized cell→sheet→cell cycle).
  attachSheet: (sheetWidget) ->
    @_sheetWidget = sheetWidget
    return

  # ── branch 3: present the scalar value's text as my passive StringWdgt child ──────────────
  # The editor's exact configuration (isEditable false, fontSize 12, full cell rect) so
  # resting and editing text align; the pixels come from StringWdgt's standard immutable back
  # buffers, so repeated labels share cached rasters world-wide. NoSettle: called from the
  # sheet's reconcile, which runs inside the dataflow drain's layout settle
  # (DataflowEngine._drainOnePass). Drops any hosted widget first (a cell that was rich and
  # became a scalar). `text` nil / "" clears the cell (an emptied cell shows nothing).
  # Churn-tolerant: a per-cycle recompute (a `frame` cell) funnels into _setTextNoSettle's own
  # no-change guard; an error↔value colour flip (rare) rebuilds the child.
  showScalarNoSettle: (text, isError) ->
    @_unhostNoSettle() if @hostedWidget?
    scalarText = if text? and text != "" then text else nil
    showsError = isError is true
    if not scalarText?
      if @_scalarTextWdgt?
        @_scalarTextWdgt._fullDestroyNoSettle()
        @_scalarTextWdgt = nil
        @_changed()
      return
    if @_scalarTextWdgt? and @_scalarShowsError != showsError
      @_scalarTextWdgt._fullDestroyNoSettle()
      @_scalarTextWdgt = nil
    if @_scalarTextWdgt?
      @_scalarTextWdgt._setTextNoSettle scalarText
    else
      textWdgt = new StringWdgt scalarText, 12
      textWdgt.color = if showsError then @_sheetWidget.errorTextColor else @_sheetWidget.valueTextColor
      textWdgt.isEditable = false
      @_addNoSettle textWdgt
      # the (4,2) box inset places the child's TOP/LEFT-aligned glyphs at the exact position
      # the pre-conversion painted text had (x 4, baseline height−6) — measured, a pure
      # translation of identical glyph rasters, so the conversion changes no resting pixel
      textWdgt._applyBounds (@position().add new Point 4, 2), @extent().subtract new Point 4, 2
      @_scalarTextWdgt = textWdgt
      @_scalarShowsError = showsError
      # a commit's reconcile can land while my overlay editor is still mounted — the editor
      # shows the buffer, so the fresh child starts hidden and teardown reveals it
      textWdgt.__hide() if @_editorWdgt?
    return

  # Paint this cell's OWN pixels (F5 — every visible thing is a widget; the sheet paints
  # nothing): my top+left grid edges (ALWAYS — even when hosting/editing/empty; the F5
  # edge-ownership convention, colours + crossing rule in SimpleSpreadsheetWdgt.paintGridEdges),
  # then my selection ring when I am the selected cell (F2: drawn fully INSIDE — band [1,3),
  # touching no edge pixel, under my children since children paint after me — the scalar-text
  # child included, exactly as the old painted text drew last). Clipped to the cell. Follows
  # the AnalogClockWdgt paint model. My VALUE is not painted here: it is a child widget in
  # every branch (hosted value / presenter / the branch-3 scalar-text StringWdgt).
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return
    sheetWidget = @_sheetWidget
    return unless sheetWidget?
    [area, sl, st, al, at, w, h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil
      aContext.save()
      aContext.clipToRectangle al, at, w, h
      aContext.useLogicalPixelsUntilRestore()
      widgetPosition = @position()
      aContext.translate widgetPosition.x, widgetPosition.y
      # dark edges sit on the header separators: the left edge of the viewport's FIRST visible
      # column and the top edge of its FIRST visible row (viewport-relative, F1 — at origin 0
      # that is sheet col/row 0, exactly the pre-scroll form)
      colRow = sheetWidget.model.colRowFor @address
      sheetWidget.paintGridEdges aContext, @width(), @height(), (colRow?.col is sheetWidget.viewOriginCol), (colRow?.row is sheetWidget.viewOriginRow)
      # my MODEL selection ring (F5 receipt B): drawn INLINE here, in my own logical-pixel scope, fully
      # INSIDE me (band [1,3), under my hosted child). This is a distinct concern from the editor-focus
      # SELECTION overlay (Widget._drawSelectionOverlay): a cell is never world.editorFocusWdgt (clicks
      # escalate to the sheet; SheetCellsPanelWdgt opts its cells out of the editor-selection walk), so the
      # generic teal overlay never fires for me -- I own my selection look, the sheet owns the state.
      if sheetWidget.isSelectedAddress @address
        aContext.strokeStyle = sheetWidget.selectionColor.toString()
        aContext.lineWidth = 2
        aContext.strokeRect 2, 2, @width() - 4, @height() - 4
      aContext.restore()

  # ── presentation: host a widget filling this cell (the sheet's _addNoSettle + _apply* idiom) ──
  # NoSettle: called from the sheet's reconcile, which runs inside the dataflow drain's layout settle
  # (DataflowEngine._drainOnePass), and from the drop hook (F4) — it TOLERATES a widget that is
  # already my child (the drop's target.add ran first): _addNoSettle's __add is a safe
  # remove-then-append self-re-add. Any previously-hosted widget (or painted scalar) is dropped first.
  # The hosted widget is inset by the gridline so the cell's borders/selection stay visible around it
  # (the CellSocketWdgt inset, now applied here since the cell fills the whole cell rect).
  hostNoSettle: (widget) ->
    @_unhostNoSettle()
    @_scalarTextWdgt?._fullDestroyNoSettle()
    @_scalarTextWdgt = nil
    @hostedWidget = widget
    @_addNoSettle widget
    inset = 2
    widget._applyBounds (@position().add new Point inset, inset), @extent().subtract new Point 2 * inset, 2 * inset
    return

  _unhostNoSettle: ->
    old = @hostedWidget
    @hostedWidget = nil
    @presentedValue = nil
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
  # ENTRY widget back out empties the cell — clear the entry, un-wire (bare field-clear; no
  # un-wire idiom exists in ControllerMixin — verified 2026-07-17 — and the engine edge dies via
  # the PUBLIC node-death API, equivalent for a value-widget, which has no incoming edges), and
  # let the widget ride the hand. ⚠ the cached record.value is still this widget — clear it
  # through the normal blank-commit path, or the next recompute's branch-1 reconcile would
  # RE-HOST the widget right off the hand. Guarded on widgetEntry identity: grabbing a PRESENTER
  # swatch out (possible pre-F4 too) keeps its old behavior — the next reconcile rebuilds the
  # derived presenter.
  _reactToChildGrabbed: (grabbedWdgt) ->
    return unless @_sheetWidget?
    record = @_sheetWidget.model.cellAt @address
    return unless record? and record.widgetEntry? and grabbedWdgt is record.widgetEntry
    @hostedWidget = nil if @hostedWidget is grabbedWdgt
    @presentedValue = nil
    record.widgetEntry = nil
    grabbedWdgt.target = nil
    grabbedWdgt.action = nil
    world.dataflow?.removeAllEdgesOf grabbedWdgt
    FormulaCompiler.commit record, ""
    world.dataflow?.markStale record
    @_changed()
    return

  # ── interaction: wire an interactive value-widget to fire into this cell ──────────────────
  # Hard-wire the hosted value-widget's connection to THIS cell's cellInput (spec §9.3): the two
  # ignored args match setTargetAndActionWithOnesPickedFromMenu's menu-driven signature. A widget
  # with no connection API (a plain RectangleWdgt presenter) simply isn't wired (the `?` guard).
  wireValueWidget: (widget) ->
    widget.setTargetAndActionWithOnesPickedFromMenu? nil, nil, this, "cellInput"
    return

  # the connection target the hosted value-widget fires into: mark this cell's cell STALE so the
  # drain recomputes its dependents (this is a pooled dataflow markStale, NOT a layout settle — so no
  # settle is opened here; the drain owns any settle).
  cellInput: (value, argumentToAction) ->
    @_sheetWidget?._markCellStaleFromHostedWidgetNoSettle @address
    return

  # ── the overlay editor (F2, executed with F5): the SHEET owns the buffer + the keys; this
  # cell owns the editor WIDGET — its complete view state in one place. All NoSettle cores:
  # called from the sheet's edit lifecycle, inside the ONE settle its public event entries
  # (processKeyDown / mouseClickLeft) open. The editor is a passive StringWdgt display driven
  # by the sheet's buffer (isEditable false — the sheet stays the sole keyboard receiver, no
  # caret is ever mounted), a child of THIS cell at exactly the cell's rect — the same
  # absolute rect the old sheet-child editor used, so the move itself changed no pixels.
  _mountEditorNoSettle: (bufferText) ->
    # the editor shows the buffer, so the resting scalar-text child hides for the edit's
    # duration (damage-free __hide — adding the editor repaints the same rect); teardown
    # reveals it again, which also serves the Escape-cancel path (no reconcile runs there)
    @_scalarTextWdgt?.__hide()
    editor = new StringWdgt bufferText, 12
    editor.color = @_sheetWidget.valueTextColor
    editor.isEditable = false
    # the steady end-of-text bar is the edit-in-progress affordance (a live CaretWdgt is a
    # keyboard receiver — the sheet must stay sole receiver; the bar is deterministic, no
    # blink, and tracks the buffer through the editor's own text re-render)
    editor.showsEndOfTextBar = true
    @_addNoSettle editor
    # the SAME (4,2) box inset as the resting scalar-text child, so the text does not
    # shift when editing starts/ends — resting and editing glyphs sit at identical positions
    editor._applyBounds (@position().add new Point 4, 2), @extent().subtract new Point 4, 2
    @_editorWdgt = editor
    return

  _updateEditorTextNoSettle: (bufferText) ->
    @_editorWdgt?._setTextNoSettle bufferText
    return

  _teardownEditorNoSettle: ->
    editor = @_editorWdgt
    @_editorWdgt = nil
    editor?._fullDestroyNoSettle()
    @_scalarTextWdgt?.show()
    @_changed()
    return
