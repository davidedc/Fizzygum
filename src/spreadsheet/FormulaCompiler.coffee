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

  # Reserved time-binding identifiers (spec §6): each, when it appears as a bare identifier, binds
  # as a formula parameter carrying the matching time source's pulled value AND becomes an edge to
  # that source. Not cell-ref-shaped, so they never collide with an address.
  @timeBindingNames: ["seconds", "frame"]

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
    # time bindings (spec §6): `seconds` / `frame` bind as parameters carrying the time sources'
    # pulled values, and each becomes an edge to its source (commit, below). Boundary-guarded so
    # `secondsElapsed`, `frameRate`, or `foo.frame` do NOT match.
    for timeName in FormulaCompiler.timeBindingNames
      boundaryRe = new RegExp "(?<![\\w$.])" + timeName + "(?![\\w$])"
      push timeName if boundaryRe.test scanCopy
    names

  # Compile the source AND (re)declare the cell's reactive dataflow edges. Every path first drops
  # the cell's OLD incoming edges (an idempotent recommit — used live AND to rebuild a restored /
  # duplicated sheet, spec §2). A cell-shaped reference `A1` becomes an edge refCell -> cell, so
  # editing A1 re-runs this cell; but a reference that would close a directed cycle rejects the
  # commit with a "#LOOP" value and declares NO edges (spec §7).
  @commit: (cell, newSource) ->
    cell.source = newSource
    engine = world?.dataflow
    # a blank cell holds nothing. Drop its incoming edges but KEEP the node (its downstream
    # references reactively see `nil`); full node-death (removeAllEdgesOf) is reserved for sheet
    # destroy / Phase 6 un-wiring — see src/spreadsheet/CLAUDE.md.
    if not newSource? or newSource.trim() is ""
      engine?.removeEdgesInto cell
      cell.compiledFn = nil
      cell.boundNames = []
      cell.value      = nil
      cell.errorFlag  = false
      return cell

    boundNames = FormulaCompiler.scanBoundNames newSource
    indented   = (("  " + line) for line in newSource.split("\n")).join "\n"
    wrapperSource = "(" + boundNames.join(", ") + ") ->\n" + indented
    # re-declare edges from scratch: drop old dependencies before (maybe) adding new ones.
    engine?.removeEdgesInto cell
    try
      compiledFn = eval compileFGCode wrapperSource, true
    catch error
      # compileFGCode throws a rich Error on a parse failure (boot ~88) — that IS the SYNTAX path.
      cell.compiledFn = nil
      cell.boundNames = []
      cell.value      = new SheetError "SYNTAX", (error?.message ? "" + error)
      cell.errorFlag  = true
      return cell

    # cycle check BEFORE wiring: check each new edge (refCell -> cell) against the pre-commit graph
    # (cell's old incoming edges already dropped). Any cycle ⇒ reject with "#LOOP", declare NO
    # edges. wouldCloseCycle also catches the trivial self-reference (`A1` inside A1).
    refCells = []
    for name in boundNames when SheetModel.looksLikeCellRef name
      refCell = cell.sheet.getOrCreateCellAt name
      if engine?.wouldCloseCycle refCell, cell
        cell.compiledFn = nil
        cell.boundNames = []
        cell.value      = new SheetError "LOOP"
        cell.errorFlag  = true
        return cell
      refCells.push refCell
    refCells.forEach (refCell) -> engine?.addEdge refCell, cell
    # time-source edges (spec §6): a `seconds`/`frame` binding is an edge from the world time
    # singleton INTO this cell, so the source's per-second / per-frame markStale re-runs the cell.
    # No cycle check — a source has no inputs, so it can never close a loop. The engine's addEdge
    # bumps the source's subscriber count, registering it in the stepping loop on its first cell.
    if engine?
      engine.addEdge engine.secondsSource(), cell if "seconds" in boundNames
      engine.addEdge engine.frameSource(),  cell if "frame"   in boundNames
    cell.compiledFn = compiledFn
    cell.boundNames = boundNames
    cell.errorFlag  = false
    cell
