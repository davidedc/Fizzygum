# CellSocketWdgt — the live boundary a spreadsheet cell mounts a rich widget in (spec
# docs/specs/dataflow-engine-spec.md §9.3/§9.4). "Painted chrome, widgetized contents": the sheet
# PAINTS gridlines, headers, selection and scalar cell values directly, but a cell whose value IS a
# Widget (branch 1, `new SliderWdgt`) or answers `cellPresenter()` (branch 2, a Color → a swatch)
# hosts that widget HERE — a transparent freefloating child positioned at the cell's rect, with the
# hosted widget filling it. One socket per RICH cell in Phase 4.
#
# Why a real widget and not ad-hoc child management (owner direction 2026-07-05): the socket is the
# SEED of Phase 8's per-cell `CellWdgt` (widgetise the grid). It is deliberately generalisable from
# "one socket per rich cell" to "one socket per VISIBLE cell": it holds a cell @address, hosts a
# value/presenter widget, and owns the interaction wiring — the three responsibilities a full
# `CellWdgt` needs. Phase 8 grows it to also render the scalar/text case and to mount/unmount on
# scroll (the same retain-and-remount move save/load already uses here).
#
# ── TWO-WAY BOUNDARY ─────────────────────────────────────────────────────────────────────────
# Presentation (down): the sheet's reconcile mounts the presenter/value widget via hostNoSettle.
# Interaction (up): a hosted INTERACTIVE value-widget (a slider) is wired so its firings land on
# this socket's `cellInput`, which marks the socket's cell STALE — the drain then recomputes the
# cell's dependents (spec §9.3 Scenario A: a drag = a per-cycle recompute of the closure). The
# presenter is "one-way glass" (spec §9.4) and is NOT wired.
#
# ── SERIALIZATION (spec §13 retain-and-remount) ──────────────────────────────────────────────
# Serialized: @address (which cell — re-indexed on restore) and @hostedWidget (a ref to the child,
# so a VALUE-widget's runtime state — a dragged slider's position — rides the tree and survives
# save/load). Transient: @_sheetWidget (a back-ref cycle, re-set on re-index) and @presentedValue
# (the churn-skip value, rebuilt by the next reconcile). On restore the sheet re-indexes sockets by
# address, then recompute RETAINS a widget-valued cell's restored widget (class match) rather than
# rebuilding it — presenters (derived) are rebuilt, value-widgets (state-bearing) are kept.

class CellSocketWdgt extends Widget

  # @address + @hostedWidget serialize; the back-ref and churn-skip value are rebuilt on restore.
  @serializationTransients: ["_sheetWidget", "presentedValue"]

  constructor: (address) ->
    super()
    @address = address        # which cell (col/row via the model); stable across save/load
    @hostedWidget = nil        # the mounted value/presenter widget (this socket's sole child)
    @presentedValue = nil      # branch-2 churn-skip: the value the current presenter reflects
    @_sheetWidget = nil        # back-ref to the owning SpreadsheetWdgt (set by attachSheet)
    # transparent container: the sheet paints the cell chrome; the socket only HOSTS, so the cell's
    # white background shows through a hosted widget's transparent parts (a slider's track). (The
    # CanvasGlassTopWdgt idiom — a nil colour paints no background.)
    @color = nil

  colloquialName: -> "cell socket"

  # the owning sheet, re-established on mount and on restore re-index (a transient back-ref, so no
  # serialized socket→sheet→socket cycle).
  attachSheet: (sheetWidget) ->
    @_sheetWidget = sheetWidget
    return

  # ── presentation: host a widget filling this socket (the sheet's _addNoSettle + _apply* idiom) ──
  # NoSettle: called from the sheet's reconcile, which runs inside the dataflow drain's layout settle
  # (DataflowEngine._drainOnePass). Any previously-hosted widget is torn down first.
  hostNoSettle: (widget) ->
    @_unhostNoSettle()
    @hostedWidget = widget
    @_addNoSettle widget
    widget._applyExtent @extent()
    widget._applyMoveTo @position()
    widget.changed()
    return

  _unhostNoSettle: ->
    old = @hostedWidget
    @hostedWidget = nil
    @presentedValue = nil
    old?._fullDestroyNoSettle()
    return

  # ── interaction: wire an interactive value-widget to fire into this socket ──────────────────
  # Hard-wire the hosted value-widget's connection to THIS socket's cellInput (spec §9.3): the two
  # ignored args match setTargetAndActionWithOnesPickedFromMenu's menu-driven signature. A widget
  # with no connection API (a plain RectangleWdgt value) simply isn't wired (the `?` guard).
  wireValueWidget: (widget) ->
    widget.setTargetAndActionWithOnesPickedFromMenu? nil, nil, this, "cellInput"
    return

  # the connection target the hosted value-widget fires into: mark this socket's cell STALE so the
  # drain recomputes its dependents, and accept-and-ignore the connection token (this is a pooled
  # dataflow markStale, NOT a layout settle — so no settle is opened here; the drain owns any settle).
  cellInput: (value, argumentToAction, connectionsCalculationToken) ->
    @_sheetWidget?._markCellStaleFromSocketNoSettle @address
    return
