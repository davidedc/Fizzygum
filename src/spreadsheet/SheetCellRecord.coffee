# SheetCellRecord — one grid cell, and the dataflow NODE the engine holds by identity (spec
# docs/specs/dataflow-engine-spec.md §9.2/§9.6). A plain class (NOT a Widget): stored in the
# SheetModel's sparse Map; the grid PAINTS it (no widget-per-cell), so it carries data + compute
# behaviour, never geometry.
#
# ── PERSISTENT vs DERIVED state ──────────────────────────────────────────────────────────────
# Persistent (serialized): {@sheet, @address, @source, @widgetEntry}. @source IS the cell's
# CoffeeScript ("everything is CoffeeScript", spec §9.2 — `42`, `"total"`, `A1 * 2` are all just
# source). @widgetEntry (F4) is the OTHER kind of entry: a desktop widget DROPPED into the cell
# IS the cell's value — no formula (source stays blank). Prototype default undefined, own-only-when-set
# (the 6a idiom: a formula cell serializes byte-for-byte as before); when set it serializes as an
# in-structure $r reference to the widget, which rides the tree as the cell's hosted child, and
# the Duplicator remaps it to the copy — save AND duplicate free (spec §2). Its LIFECYCLE is
# owned by the GESTURES, never by FormulaCompiler.commit (pure source machinery): SET by the drop
# (CellWdgt._reactToChildDropped), CLEARED by a user edit-commit on the cell
# (SimpleSpreadsheetWdgt._commitEditNoSettle — typed content of any kind replaces the widget) and by
# the drag-out (CellWdgt._reactToChildGrabbed).
# Derived (rebuilt on load and on duplicate, so neither a save nor a copy carries them — declared in
# @serializationTransients and @copyTransients):
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

  # deep-copied per sheet (a duplicated sheet gets its OWN records). The four derived fields are left
  # out of a copy as they are left out of a save, and rebuilt the same way: the copied sheet recommits
  # every cell (SimpleSpreadsheetWdgt._reactToBeingCopied marks each stale; the next drain computes its
  # value), as a loaded one does (_afterDeserialization). Until then the copy's records hold none of
  # them. So a formula's value of any kind -- a RegExp, an Error, a DOMRect, which no copy carries --
  # never meets the copier (Duplicator's Note 5).

  @serializationTransients: ["compiledFn", "boundNames", "value", "errorFlag"]
  @copyTransients: ["compiledFn", "boundNames", "value", "errorFlag"]

  # F4 widget-entry kind (see the header): a DROPPED desktop widget as the cell's value.
  # PERSISTENT (deliberately NOT in @serializationTransients) but a PROTOTYPE default — only a
  # cell that actually received a drop carries the own property.
  widgetEntry: undefined

  # the cell's FORMAT (docs/archive/spreadsheet-ux-plan.md R5): how its value shows — a plain object
  # whose keys, each optional, are bold, italic, fontName, fontSize (px at 100%), align ("LEFT" /
  # "CENTER" / "RIGHT"), fill (a Color) and decimals. DOCUMENT state, so it is saved, copied with
  # the sheet, and survives scroll and zoom; never touched by a commit, so clearing a cell keeps it.
  # Written through SimpleSpreadsheetWdgt.restyleCell (a fresh object each time, never mutated in
  # place), or set whole as a sheet is built (SampleSheetApp). A PROTOTYPE default: only a formatted
  # cell carries the own property.
  format: undefined

  # @sheet is the owning SheetModel ("the sheet the cell belongs to"); @sheet.sheetWidget is the
  # SimpleSpreadsheetWdgt that paints it and serves as the formula scope (@ inside a formula).
  constructor: (@sheet, @address, @source = "") ->
    @compiledFn = undefined
    @boundNames = []
    @value      = undefined
    @errorFlag  = false

  # ── dataflow node protocol ───────────────────────────────────────────────────────────────

  dataflowRecompute: ->
    # F4 widget-entry FIRST: a dropped widget IS the value — no formula runs, and the branch-1
    # reconcile RETAINS the mounted instance (identity match). Checked before everything so the
    # entry kind wins over any leftover compiled state (there is none by construction: the drop
    # blank-commits the source).
    return @_cacheValue @widgetEntry if @widgetEntry?
    # A blank, syntax-errored or loop-rejected cell has no compiled function: its @value is already
    # resolved (undefined, or a SheetError set by FormulaCompiler.commit). Route it through _cacheValue
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
  # value — read through Widget.exportedValue, i.e. from the widget's declared PRINCIPAL PIN, and
  # this is that reader's first live CONSUMER — or the widget itself if it exports nothing; a scalar
  # / Color / SheetError exports itself. @value stays the raw widget so the sheet can present it
  # (branch 1); THIS is what flows.
  exportedCellValue: ->
    v = @value
    return v unless v instanceof Widget
    v.exportedValue() ? v

  # The engine calls this when @compiledFn THREW mid-recompute: force-resolve to an "ERR" value so
  # the drain cannot spin on the cell and references propagate the error (spec §5/§9.6). Detail is
  # logged to the console OUTSIDE the drain by the engine.
  dataflowNoteError: (error) ->
    @_cacheValue new SheetError "ERR", (error?.message ? textOfThrownValue error)

  # Cache the computed value AND reconcile the cell's CellWdgt (spec §9.4 classify → present): the sheet
  # hosts/RETAINS a live widget (branch 1), mounts a swatch (branch 2), or paints the scalar text
  # (branch 3) into the cell's widget. The reconcile RETURNS the value to actually cache — for a
  # widget-valued cell that keeps its existing widget, the RETAINED instance (so a dragged/restored
  # widget survives its own markStale, spec §13), else `v` unchanged. This runs inside the drain's
  # layout settle (DataflowEngine._drainOnePass wraps the pass), so the reconcile is a NoSettle core.
  # Then RETURN the EXPORTED form — the engine's cutoff compares old vs returned (NOMENCLATURE: dataflow
  # "caches/recomputes", it does not "settle"). Repaint is the VIEW's business, not this record's:
  # every reconcile branch self-invalidates (the sheet's own _changed() on host, the cell's own
  # _changed() in showScalarNoSettle) — a damage rect, never a relayout.
  #   The record holds `v` BEFORE the sheet presents it: what the presentation reads of the record
  # (the formula bar's error message for the selected cell, the row's text spill, a number's default
  # alignment) is the value being presented, never the one it replaces.
  _cacheValue: (v) ->
    sheetWidget = @sheet.sheetWidget
    @value     = v
    @value     = sheetWidget._reconcileCellNoSettle this, v if sheetWidget?
    @errorFlag = @value instanceof SheetError
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
    # A time binding (spec §6) -> the source's current pulled value (a NUMBER: epoch seconds /
    # the frame counter). Formulas NEVER read the wall clock — all time enters through the source,
    # pulled here from the one-timestamp-per-cycle. The reactive EDGE that re-runs this cell on each
    # tick was declared by FormulaCompiler.commit; the source ticks only while such a cell exists.
    if Object::hasOwnProperty.call FormulaCompiler.TIME_SOURCES, name
      return FormulaCompiler.timeSourceFor(name, world?.dataflow)?.dataflowValue()
    undefined
