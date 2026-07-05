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
    # A blank or syntax-errored cell has no compiled function: its @value is already settled
    # (nil, or the SYNTAX SheetError set by FormulaCompiler.commit) — return it unchanged.
    return @value unless @compiledFn?
    boundValues = @boundNames.map (name) => @_resolveBoundName name
    # THIN arrow in the wrapper => `@` inside the formula is bound HERE, by apply, to the sheet
    # widget (full world access, no sandbox — spec §9.2). A formula throw is caught by the engine
    # (_processNode) and, from Phase 2c, turned into an "ERR" value via dataflowNoteError.
    result = @compiledFn.apply @sheet.sheetWidget, boundValues
    @value     = result
    @errorFlag = result instanceof SheetError
    @sheet.sheetWidget?.changed()   # repaint the grid; paint-only (changed, never a relayout)
    @value

  dataflowValue: -> @value

  # Resolve one bound parameter name to the value passed into the formula.
  _resolveBoundName: (name) ->
    # A cell reference -> the referenced cell's VALUE. A SheetError input propagates (spec §9.6):
    # yield it so the formula short-circuits into the same error at recompute (Phase 2c wires the
    # reactive EDGE that re-runs this cell when the referenced cell changes; here we only READ).
    if SheetModel.looksLikeCellRef name
      return @sheet.valueAt name
    # A FormulaHelpers veneer name -> the bound helper function. The veneer itself arrives in
    # Phase 3 (spec §9.5), once value-class operations exist to delegate to; the binding is ready.
    if FormulaHelpers? and Object::hasOwnProperty.call(FormulaHelpers, name)
      return FormulaHelpers[name]
    # seconds / frame time bindings arrive in Phase 5.
    nil
