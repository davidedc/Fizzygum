# SheetModel — the spreadsheet's SPARSE data model (spec docs/specs/dataflow-engine-spec.md
# §9.1). A plain class (NOT a Widget): the SpreadsheetWdgt HAS-A one as @model, and holds a
# back-reference here as @sheetWidget (the "sheet" a cell belongs to == this model; the widget
# that paints it == @sheetWidget). Cells are stored SPARSELY in a Map keyed by address string
# ("A1") — only cells the user has touched exist, so an empty 1000×1000 sheet costs nothing.
#
# This class owns the ADDRESS ALGEBRA (letters<->column-index, "A1"<->{col,row}) and the cell
# store; the CELL's own compute/serialize behaviour lives on SheetCellRecord, and the
# source->function compile lives on FormulaCompiler. Nothing here is time- or paint-dependent
# (the model is a pure function of the committed sources) — determinism stays intact.

class SheetModel

  # canonical cell-address shape: 1–2 uppercase letters + a 1-based row 1..9999. Kept in sync
  # with FormulaCompiler's in-source scan regex; `looksLikeCellRef` is the ANCHORED full-string
  # test (the scan uses the un-anchored, boundary-guarded variant).
  @cellAddressPattern: /^[A-Z]{1,2}[1-9][0-9]{0,3}$/

  @looksLikeCellRef: (name) -> SheetModel.cellAddressPattern.test name

  constructor: (@sheetWidget) ->
    # address string ("A1") -> SheetCellRecord. Insertion order is irrelevant (paint walks it,
    # order-independent) — but a Map keeps lookup O(1) and serializes as a $Map record.
    @cells = new Map

  # ── address algebra ────────────────────────────────────────────────────────────────────────

  # 0-based column index -> spreadsheet letters (0->A, 25->Z, 26->AA, …). Bijective with
  # lettersToCol. (Same loop as SpreadsheetWdgt._colToLetters, centralised here now that the
  # model owns addressing; the widget delegates.)
  colToLetters: (col) ->
    s = ""
    n = col
    loop
      s = String.fromCharCode(65 + (n % 26)) + s
      n = Math.floor(n / 26) - 1
      break if n < 0
    s

  # spreadsheet letters -> 0-based column index (inverse of colToLetters).
  lettersToCol: (letters) ->
    n = 0
    for i in [0...letters.length]
      n = n * 26 + (letters.charCodeAt(i) - 65 + 1)
    n - 1

  # {col,row} (both 0-based) -> address ("A1"); rows display 1-based, so row 0 -> "1".
  addressFor: (col, row) -> @colToLetters(col) + (row + 1)

  # address ("A1") -> {col,row} (both 0-based), or nil if it is not a cell address.
  colRowFor: (address) ->
    return nil unless SheetModel.looksLikeCellRef address
    m = address.match /^([A-Z]{1,2})([0-9]+)$/
    return nil unless m?
    {col: @lettersToCol(m[1]), row: (parseInt(m[2], 10) - 1)}

  # ── cell store ─────────────────────────────────────────────────────────────────────────────

  cellAt: (address) -> @cells.get address

  # the record for an address, creating an empty one if absent (an edit target always exists).
  getOrCreateCellAt: (address) ->
    existing = @cells.get address
    return existing if existing?
    record = new SheetCellRecord @, address, ""
    @cells.set address, record
    record

  # the plain VALUE at an address (nil for an untouched cell). References resolve through here;
  # the widget-exportedValue rule (a ref to a widget-valued cell) arrives in Phase 3/4.
  valueAt: (address) -> @cells.get(address)?.value

  # paint / recompute helper: visit every stored cell as (record, address).
  forEachCell: (fn) -> @cells.forEach fn
