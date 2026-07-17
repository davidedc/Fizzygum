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

  constructor: (address) ->
    super()
    @address = address         # which cell (col/row via the model); stable across save/load
    @hostedWidget = nil        # the mounted value/presenter widget (this cell's rich child), or nil
    @presentedValue = nil      # branch-2 churn-skip: the value the current presenter reflects
    @_sheetWidget = nil        # back-ref to the owning SpreadsheetWdgt (set by attachSheet)
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
    @changed()
    return

  # 12px Arial — the SWCanvas-deterministic band (Arial/Times/Courier atlases only); matches the
  # sheet's header/value font. No bold/italic.
  _cellFont: -> "12px Arial, sans-serif"

  # Paint this cell's OWN pixels (F5 — every visible thing is a widget; the sheet paints
  # nothing): my top+left grid edges (ALWAYS — even when hosting/editing/empty; the F5
  # edge-ownership convention, colours + crossing rule in SpreadsheetWdgt.paintGridEdges),
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
      colRow = sheetWidget.model.colRowFor @address
      sheetWidget.paintGridEdges aContext, @width(), @height(), (colRow?.col is 0), (colRow?.row is 0)
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
  # (DataflowEngine._drainOnePass). Any previously-hosted widget (or painted scalar) is dropped first.
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
    widget.changed()
    return

  _unhostNoSettle: ->
    old = @hostedWidget
    @hostedWidget = nil
    @presentedValue = nil
    old?._fullDestroyNoSettle()
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
    editor.changed()
    return

  _updateEditorTextNoSettle: (bufferText) ->
    @_editorWdgt?._setTextNoSettle bufferText
    return

  _teardownEditorNoSettle: ->
    editor = @_editorWdgt
    @_editorWdgt = nil
    editor?._fullDestroyNoSettle()
    @changed()
    return
