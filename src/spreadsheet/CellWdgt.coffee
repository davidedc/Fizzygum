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
#   branch 3 — a scalar / error / nil → PAINT its toString() text directly (moved here off the
#              sheet's old _paintGrid value loop in Phase 8; since F5 the cell ALSO paints its
#              own top+left grid edges and — when selected — its own ring: every visible pixel
#              belongs to a widget, the sheet paints nothing).
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

  # @address + @hostedWidget serialize; the back-ref, churn-skip value, derived scalar text and
  # the overlay editor (a mid-edit snapshot restores to a settled, not-editing sheet — the
  # re-index destroys any stray editor child) are rebuilt on restore.
  @serializationTransients: ["_sheetWidget", "presentedValue", "_scalarText", "_scalarIsError", "_editorWdgt"]

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
    @_scalarText = nil         # branch-3 painted text (a scalar/error toString), or nil when empty/hosting
    @_scalarIsError = false    # true when @_scalarText is a SheetError badge (paint in the error colour)
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

  # ── branch 3: paint the scalar value's text (the sheet's old _paintGrid value loop lives here now) ──
  # NoSettle: called from the sheet's reconcile, which runs inside the dataflow drain's layout settle
  # (DataflowEngine._drainOnePass). Drops any hosted widget first (a cell that was rich and became a
  # scalar). `text` nil / "" clears the cell (an emptied cell paints nothing).
  showScalarNoSettle: (text, isError) ->
    @_unhostNoSettle() if @hostedWidget?
    @_scalarText = if text? and text != "" then text else nil
    @_scalarIsError = isError is true
    @_changed()
    return

  # 12px Arial — the SWCanvas-deterministic band (Arial/Times/Courier atlases only); matches the
  # sheet's header/value font. No bold/italic.
  _cellFont: -> "12px Arial, sans-serif"

  # Paint this cell's OWN pixels (F5 — every visible thing is a widget; the sheet paints
  # nothing): my top+left grid edges (ALWAYS — even when hosting/editing/empty; the F5
  # edge-ownership convention, colours + crossing rule in SimpleSpreadsheetWdgt.paintGridEdges),
  # then my selection ring when I am the selected cell (F2: drawn fully INSIDE — band [1,3),
  # touching no edge pixel, under my hosted child since children paint after me, never
  # overlapping my text which starts at x 4), then my scalar text (branch 3) at the SAME
  # local offsets the old sheet paint used (x 4, baseline height−6). The text is suppressed
  # while a widget is hosted (it paints itself) or while my overlay editor is mounted (the
  # editor shows the buffer instead — no doubled text). Clipped to the cell. Follows the
  # AnalogClockWdgt paint model.
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
      if not @hostedWidget? and @_scalarText? and not @_editorWdgt?
        aContext.font = @_cellFont()
        aContext.fillStyle = (if @_scalarIsError then sheetWidget.errorTextColor else sheetWidget.valueTextColor).toString()
        aContext.fillText @_scalarText, 4, @height() - 6
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
    @_scalarText = nil
    @hostedWidget = widget
    @_addNoSettle widget
    inset = 2
    widget._applyExtent @extent().subtract new Point 2 * inset, 2 * inset
    widget._applyMoveTo @position().add new Point inset, inset
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
    editor = new StringWdgt bufferText, 12
    editor.color = @_sheetWidget.valueTextColor
    editor.isEditable = false
    @_addNoSettle editor
    editor._applyExtent @extent()
    editor._applyMoveTo @position()
    @_editorWdgt = editor
    return

  _updateEditorTextNoSettle: (bufferText) ->
    @_editorWdgt?._setTextNoSettle bufferText
    return

  _teardownEditorNoSettle: ->
    editor = @_editorWdgt
    @_editorWdgt = nil
    editor?._fullDestroyNoSettle()
    @_changed()
    return
