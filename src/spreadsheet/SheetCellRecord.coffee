# SheetCellRecord — one grid cell, and the dataflow NODE the engine holds by identity (spec
# docs/specs/dataflow-engine-spec.md §9.2/§9.6). A plain class (NOT a Widget): stored in the
# SheetModel's sparse Map; the grid PAINTS it (no widget-per-cell), so it carries data + compute
# behaviour, never geometry.
#
# ── PERSISTENT vs DERIVED state ──────────────────────────────────────────────────────────────
# Persistent (serialized): {@sheet, @address, @source}. @source IS the cell's CoffeeScript
# ("everything is CoffeeScript", spec §9.2 — `42`, `"total"`, `A1 * 2` are all just source).
# Derived (rebuilt on load/duplicate, NEVER serialized — declared in @serializationTransients):
#   @compiledFn   the once-compiled formula function (FormulaCompiler.commit)
#   @boundNames   the identifier names bound as its parameters (cell refs / helpers / later time)
#   @value        the last computed value (what the grid paints, what references pull)
#   @errorFlag    true when @value is a SheetError (the grid paints it distinctly)
# The serializer THROWS on an undeclared function-valued own-property (Serializer ~229; the
# transients check runs BEFORE that), so declaring @compiledFn is MANDATORY for saving to work
# at all — not hygiene. On restore the SHEET recommits every cell (recompile + re-mark stale),
# rebuilding all four; the same recommit re-declares the engine edges in Phase 2c — so the engine
# needs no serialized state (spec §2, the derived-index philosophy the cells share).
#
# ── NODE PROTOCOL (see DataflowEngine header) ────────────────────────────────────────────────
#   dataflowRecompute() -> value   run the compiled formula, cache @value + reconcile the socket,
#                                  return the EXPORTED form (the engine cutoff compares old vs
#                                  returned; exporting makes a dragged widget-valued cell propagate).
#   dataflowValue()     -> value   the EXPORTED form too (spec §9.3).
#   dataflowNoteError / dataflowApply — Phase 2c (error-as-value) / not needed (a cell displays
#                                  its own value; it pushes onto no other node's property).
#
# ── VALUE vs EXPORTED VALUE (spec §9.3, Phase 4) ─────────────────────────────────────────────
# @value is the raw computed value (a number, a Color, a SheetError, or — Phase 4 — a live Widget
# the sheet mounts in a socket). A REFERENCE to the cell, and the engine's cutoff, see the EXPORTED
# form (exportedCellValue): a widget-valued cell exports its widget's exportedValue() so a mounted
# slider's number flows downstream; everything else exports itself.

class SheetCellRecord

  # deep-copied per sheet (a duplicated sheet gets its OWN records). The derived fields ride along:
  # @compiledFn (a function) copies by reference and @value (maybe a SheetError, kept by reference)
  # too — both are then OVERWRITTEN when the duplicated sheet recommits every cell (rebuild), so
  # the brief sharing is harmless; @boundNames (an array) copies via Array::deepCopy. On the
  # SERIALIZE side these four are dropped instead (@serializationTransients below), then rebuilt
  # the same way on restore.
  @augmentWith DeepCopierMixin

  @serializationTransients: ["compiledFn", "boundNames", "value", "errorFlag"]

  # @sheet is the owning SheetModel ("the sheet the cell belongs to"); @sheet.sheetWidget is the
  # SpreadsheetWdgt that paints it and serves as the formula scope (@ inside a formula).
  constructor: (@sheet, @address, @source = "") ->
    @compiledFn = nil
    @boundNames = []
    @value      = nil
    @errorFlag  = false

  # ── dataflow node protocol ───────────────────────────────────────────────────────────────

  dataflowRecompute: ->
    # A blank, syntax-errored or loop-rejected cell has no compiled function: its @value is already
    # resolved (nil, or a SheetError set by FormulaCompiler.commit). Route it through _cacheValue
    # anyway so the socket reconcile drops any widget the cell used to show (e.g. blanking a Color).
    return @_cacheValue @value unless @compiledFn?
    boundValues = @boundNames.map (name) => @_resolveBoundName name
    # ERROR-AS-VALUE PROPAGATION (spec §9.6): if any INPUT is a SheetError, this cell yields that
    # SAME error, short-circuit BEFORE running the formula (never compute on a poisoned input).
    for v in boundValues
      return @_cacheValue v if v instanceof SheetError
    # THIN arrow in the wrapper => `@` inside the formula is bound HERE, by apply, to the sheet
    # widget (full world access, no sandbox — spec §9.2). A formula THROW is caught by the engine
    # (_processNode) → dataflowNoteError below turns it into an "ERR" value.
    @_cacheValue @compiledFn.apply @sheet.sheetWidget, boundValues

  # What the engine's equal-value cutoff compares and what dataflowValue exposes: the EXPORTED form
  # (spec §9.3). A widget-valued cell exports its widget's value, so dragging a mounted slider —
  # which changes its number but NOT the widget's identity — reads as a change and propagates to
  # dependents (a Widget has no `.equals`, so an identity cutoff on the widget would wrongly stop).
  dataflowValue: -> @exportedCellValue()

  # The value a REFERENCE to this cell yields (spec §9.3): a widget-valued cell exports its widget's
  # value (getColor?() ?? getValue?() ?? text, via Widget.exportedValue — this is that reader's first
  # live CONSUMER), or the widget itself if it exports nothing; a scalar / Color / SheetError exports
  # itself. @value stays the raw widget so the sheet can present it (branch 1); THIS is what flows.
  exportedCellValue: ->
    v = @value
    return v unless v instanceof Widget
    v.exportedValue() ? v

  # The engine calls this when @compiledFn THREW mid-recompute: force-resolve to an "ERR" value so
  # the drain cannot spin on the cell and references propagate the error (spec §5/§9.6). Detail is
  # logged to the console OUTSIDE the drain by the engine.
  dataflowNoteError: (error) ->
    @_cacheValue new SheetError "ERR", (error?.message ? "" + error)

  # Cache the computed value AND reconcile the cell's SOCKET (spec §9.4 classify → present): the sheet
  # mounts a swatch (branch 2), hosts/RETAINS a live widget (branch 1), or drops any socket for a
  # scalar (branch 3). The reconcile RETURNS the value to actually cache — for a widget-valued cell
  # that keeps its existing widget, the RETAINED instance (so a dragged/restored widget survives its
  # own markStale, spec §13), else `v` unchanged. This runs inside the drain's layout settle
  # (DataflowEngine._drainOnePass wraps the pass), so the reconcile is a NoSettle core. Then RETURN
  # the EXPORTED form — the engine's cutoff compares old vs returned (NOMENCLATURE: dataflow
  # "caches/recomputes", it does not "settle"; `changed()` marks a broken rect, never a relayout).
  _cacheValue: (v) ->
    sheetWidget = @sheet.sheetWidget
    @value     = if sheetWidget? then (sheetWidget._reconcileCellSocketNoSettle this, v) else v
    @errorFlag = @value instanceof SheetError
    sheetWidget?.changed()
    @exportedCellValue()

  # Resolve one bound parameter name to the value passed into the formula.
  _resolveBoundName: (name) ->
    # A cell reference -> the referenced cell's EXPORTED value (a widget-valued cell yields its
    # widget's exportedValue; a scalar/Color yields itself — spec §9.3). A SheetError flows through
    # unchanged and is caught by the propagation short-circuit in dataflowRecompute above. The
    # reactive EDGE that re-runs this cell when the referenced cell changes is declared by
    # FormulaCompiler.commit (Phase 2c).
    if SheetModel.looksLikeCellRef name
      return @sheet.exportedValueAt name
    # A FormulaHelpers veneer name -> the bound helper function (spec §9.5).
    if FormulaHelpers? and Object::hasOwnProperty.call(FormulaHelpers, name)
      return FormulaHelpers[name]
    # seconds / frame time bindings arrive in Phase 5.
    nil
