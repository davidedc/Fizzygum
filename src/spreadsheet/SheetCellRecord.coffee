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
#   dataflowRecompute() -> value   run the compiled formula, cache @value, return it (the engine
#                                  cutoff compares old vs returned).
#   dataflowValue()     -> @value  what downstream references pull.
#   dataflowNoteError / dataflowApply — Phase 2c (error-as-value) / not needed (a cell displays
#                                  its own value; it pushes onto no other node's property).

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
    # A blank, syntax-errored or loop-rejected cell has no compiled function: its @value is
    # already resolved (nil, or a SheetError set by FormulaCompiler.commit) — return it unchanged.
    return @value unless @compiledFn?
    boundValues = @boundNames.map (name) => @_resolveBoundName name
    # ERROR-AS-VALUE PROPAGATION (spec §9.6): if any INPUT is a SheetError, this cell yields that
    # SAME error, short-circuit BEFORE running the formula (never compute on a poisoned input).
    for v in boundValues
      return @_cacheValue v if v instanceof SheetError
    # THIN arrow in the wrapper => `@` inside the formula is bound HERE, by apply, to the sheet
    # widget (full world access, no sandbox — spec §9.2). A formula THROW is caught by the engine
    # (_processNode) → dataflowNoteError below turns it into an "ERR" value.
    @_cacheValue @compiledFn.apply @sheet.sheetWidget, boundValues

  dataflowValue: -> @value

  # The engine calls this when @compiledFn THREW mid-recompute: force-resolve to an "ERR" value so
  # the drain cannot spin on the cell and references propagate the error (spec §5/§9.6). Detail is
  # logged to the console OUTSIDE the drain by the engine.
  dataflowNoteError: (error) ->
    @_cacheValue new SheetError "ERR", (error?.message ? "" + error)

  # cache the computed value for painting + downstream pulls, flag errors, request a repaint,
  # reconcile the cell's presenter widget (spec §9.4 classify→present — a Color mounts a swatch), and
  # RETURN it (the engine's equal-value cutoff compares old vs returned). This runs inside the drain's
  # layout settle (DataflowEngine._drainOnePass), so the presenter mount/teardown rides it via NoSettle
  # cores. Paint-only otherwise — `changed()` marks a broken rect, never a relayout (NOMENCLATURE:
  # dataflow "caches/recomputes", it does not "settle" — that verb is layout's).
  _cacheValue: (v) ->
    @value     = v
    @errorFlag = v instanceof SheetError
    @sheet.sheetWidget?.changed()
    @sheet.sheetWidget?._reconcileCellPresenterNoSettle this
    @value

  # Resolve one bound parameter name to the value passed into the formula.
  _resolveBoundName: (name) ->
    # A cell reference -> the referenced cell's VALUE (plain in v1; the widget-exportedValue rule
    # for a ref to a widget-valued cell arrives in Phase 4). A SheetError value flows through
    # unchanged and is caught by the propagation short-circuit in dataflowRecompute above. The
    # reactive EDGE that re-runs this cell when the referenced cell changes is declared by
    # FormulaCompiler.commit (Phase 2c).
    if SheetModel.looksLikeCellRef name
      return @sheet.valueAt name
    # A FormulaHelpers veneer name -> the bound helper function. The veneer itself arrives in
    # Phase 3 (spec §9.5), once value-class operations exist to delegate to; the binding is ready.
    if FormulaHelpers? and Object::hasOwnProperty.call(FormulaHelpers, name)
      return FormulaHelpers[name]
    # seconds / frame time bindings arrive in Phase 5.
    nil
