# FormulaCompiler — turns a cell's CoffeeScript SOURCE into its compiled formula function, ONCE
# per commit (spec docs/specs/dataflow-engine-spec.md §9.2: "everything is CoffeeScript";
# recomputes never re-compile). Stateless — exposed as class ("static") methods; there is nothing
# to instantiate or serialize.
#
# commit(cell, newSource) is the single entry (called from the SpreadsheetWdgt commit path):
#   1. record @source;
#   2. scan the source (comments + string literals stripped from a scan COPY) for the identifiers
#      to bind as the formula's parameters — cell references (`A1`, which ALSO become the cell's
#      dataflow edges in Phase 2c), FormulaHelpers names (the veneer arrives in Phase 3), and
#      later the time bindings `seconds`/`frame` (Phase 5). One scan discovers dependencies,
#      helper bindings, and (future) tick subscriptions;
#   3. build the wrapper `"(boundNames) ->\n  <indented source>"` and compile it ONCE via
#      compileFGCode (bare); eval to the function, cached on @compiledFn;
#   4. on a compile failure the cell's value becomes a "SYNTAX" SheetError (spec §9.6) and it
#      binds nothing.
# Evaluation happens later in SheetCellRecord.dataflowRecompute via @compiledFn.apply(sheetScope,
# boundValues); sheetScope (the formula's `@`) is the SpreadsheetWdgt — full world access, no
# sandbox (spec §9.2).

class FormulaCompiler

  # un-anchored, boundary-guarded cell-ref scan (kept in sync with SheetModel.cellAddressPattern,
  # the anchored full-string test). The `(?<![\w$.])` lookbehind excludes property access, so
  # `foo.A1` is NOT a reference; `(?![\w$])` excludes longer identifiers. JS lookbehind is
  # supported on every engine the suite runs (current Chrome/Puppeteer, Playwright WebKit,
  # production Safari >= 16.4).
  @cellRefScan: /(?<![\w$.])[A-Z]{1,2}[1-9][0-9]{0,3}(?![\w$])/g

  # Strip CoffeeScript comments and string literals to a SCAN COPY (whitespace-preserving-ish),
  # so an address-shaped substring inside a comment or string is NOT mistaken for a reference
  # (e.g. `"see A1"` must not bind A1). Heuristic but sound for the short formulas cells hold:
  # block comments and triple-quoted strings first, then single/double strings, then line
  # comments (by which point any `#` that lived inside a string is already gone).
  @stripCommentsAndStrings: (src) ->
    s = src
    s = s.replace /###[\s\S]*?###/g, " "        # block comments
    s = s.replace /"""[\s\S]*?"""/g, ' "" '     # triple-double strings
    s = s.replace /'''[\s\S]*?'''/g, " '' "     # triple-single strings
    s = s.replace /"(?:[^"\\]|\\.)*"/g, ' "" '  # double-quoted strings
    s = s.replace /'(?:[^'\\]|\\.)*'/g, " '' "  # single-quoted strings
    s = s.replace /#.*$/gm, " "                 # line comments
    s

  # The ORDERED, de-duplicated list of parameter names to bind. Order is stable (first
  # appearance) so the wrapper's parameter list and dataflowRecompute's boundValues line up.
  @scanBoundNames: (source) ->
    scanCopy = FormulaCompiler.stripCommentsAndStrings source
    names = []
    seen = new Set
    push = (n) ->
      return if seen.has n
      seen.add n
      names.push n
    # cell references
    (scanCopy.match(FormulaCompiler.cellRefScan) ? []).forEach push
    # FormulaHelpers veneer names (Phase 3+): bind each helper whose name appears as a bare
    # identifier. Guarded so 2b (no veneer yet) simply finds none.
    if FormulaHelpers?
      for own helperName of FormulaHelpers
        boundaryRe = new RegExp "(?<![\\w$.])" + helperName + "(?![\\w$])"
        push helperName if boundaryRe.test scanCopy
    names

  @commit: (cell, newSource) ->
    cell.source = newSource
    # a blank cell holds nothing (deleting a cell — edge teardown — is Phase 2c).
    if not newSource? or newSource.trim() is ""
      cell.compiledFn = nil
      cell.boundNames = []
      cell.value      = nil
      cell.errorFlag  = false
      return cell

    boundNames = FormulaCompiler.scanBoundNames newSource
    indented   = (("  " + line) for line in newSource.split("\n")).join "\n"
    wrapperSource = "(" + boundNames.join(", ") + ") ->\n" + indented
    try
      cell.compiledFn = eval compileFGCode wrapperSource, true
      cell.boundNames = boundNames
      cell.errorFlag  = false
    catch error
      # compileFGCode throws a rich Error on a parse failure (boot ~88) — that IS the SYNTAX path.
      cell.compiledFn = nil
      cell.boundNames = []
      cell.value      = new SheetError "SYNTAX", (error?.message ? "" + error)
      cell.errorFlag  = true
    cell
