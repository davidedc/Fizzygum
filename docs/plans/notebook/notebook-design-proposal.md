# Notebook in Fizzygum — design proposal

**STATUS: PROPOSAL 2026-11-24 — research done, design proposed, owner decisions D1–D4 (§7) open, NO code
written.** Not yet a cold-executable plan: once D1–D4 are ruled, the next step is to author one from
this proposal (`/author-plan`). Facts in §2 were verified against the working tree at Fizzygum
`ccad1631` on 2026-11-24; anchor on the quoted class and method names, not on line numbers.

The research behind it: [`js-notebook-references.md`](js-notebook-references.md) (the JS notebook
material in the owner's notes, filtered and sorted by implementation size). A local HTML version with
screenshots sits beside it, gitignored (`js-notebook-references.html`).

## 1. Goal and the one-line answer

A **simple notebook** inside Fizzygum: prose and code cells in one document, each code cell showing
its result under it, results kept current, saved with the rest of the world.

**The answer: build it as the spreadsheet's engine laid out as a document.** Almost everything a
notebook needs (compiling cell code, naming dependencies, recomputing what depends on what, showing
live widgets as values, errors as values, saving source rather than results) already exists for the
Sheets Maker. The new work is layout and naming.

## 2. What already exists (verified 2026-11-24)

**Running a person's code.**
- `TextWdgt` (`src/basic-widgets/TextWdgt.coffee`) adds *Run selection*, *Show selection*, *Inspect
  selection* and *Run contents* rows to any text whose container chain names a code receiver
  (`_codeReceiver`: the nearest container defining `codeReceiver` answers; `WorldWdgt.codeReceiver`
  answers at the root, so a Docs Maker paragraph on the desktop offers them today).
- Every run gesture goes through ONE seam on `Widget` (`src/basic-widgets/Widget.coffee`):
  `_runningTypedCodeAgainst` compiles first (`compileFGCode`; text that is not code is reported beside
  the hand, nothing runs), then `_runningAPersonsCode` runs `receiver.evaluateString code` and tells
  the receiver (`sourceChanged`). Code is CoffeeScript; `@` is the receiver.
- `ConsoleWdgt` (`src/meta-tools/ConsoleWdgt.coffee`) is a code area with *Run selection* / *Run
  contents* buttons against its target; `CodeAreaWdgt` is the family's shared base.

**The calculation engine.** `DataflowEngine` (`src/dataflow/DataflowEngine.coffee`, spec
[`docs/specs/dataflow-engine-spec.md`](../../specs/dataflow-engine-spec.md)) is core, not a part. Its
header is the node contract: a node may implement `dataflowRecompute()`, `dataflowValue()`,
`dataflowApply(value)`, `dataflowNoteError(error)`; sources call `markStale(node)`; edges are
`addEdge(producer, consumer)`; notifications carry no values (values are pulled); one drain per cycle
(`recalculateDataflow`). It serves two clients today: patch-programming circuits and the spreadsheet.

**The spreadsheet already is a reactive notebook in grid form** (`src/spreadsheet/`, its own
[`CLAUDE.md`](../../../src/spreadsheet/CLAUDE.md)):
- `FormulaCompiler.commit(cell, source)`: the source is CoffeeScript; one scan of it (comments and
  strings stripped) finds the names to bind, which become both the compiled function's parameters and
  the cell's dataflow edges; compiled ONCE into `(boundNames) -> source`; a compile failure becomes a
  `SYNTAX` `SheetError` value. `@` in a formula is the `SimpleSpreadsheetWdgt`.
- `FormulaCompiler.TIME_SOURCES`: `seconds` and `frame` bind as numbers and as edges from the world's
  time sources, so a formula can animate.
- `SheetCellRecord.dataflowRecompute`: a widget DROPPED into a cell is the cell's value (no formula
  runs); an error input short-circuits to the same error (error-as-value propagation); a reference to
  a widget-valued cell yields the widget's exported value (`_resolveBoundName`), so a slider cell
  reads as its number.
- Presentation (spec §9.4): a Widget value presents itself, mounted live in the cell (`CellWdgt`); a
  value answering `cellPresenter()` is shown by the widget it returns (`Color.cellPresenter`, a swatch);
  anything else as text. A widget-valued cell keeps its live widget across recompute, save and scroll
  (spec, Phase 4: retain-and-remount, never destroy-rebuild), and an interactive widget in a cell
  (slider, picker, clock) marks the cell stale when used.
- `SliderInCellButtonWdgt` (sheet toolbar) puts a slider in a cell by entering the source
  `new SliderWdgt 1, 100, 50, 1`.

**The source is the truth.** `CalculatingPatchNodeWdgt` (`src/authoring/`) and `FormulaCompiler` keep
the compiled function derived and never serialized; a restored node recompiles on its first
recompute. `Widget.evaluateString`'s comment states the same limit from the other side: a function
left in a field has no source, and a save refuses it.

**Documents.** `DocumentWdgt` (`src/authoring/DocumentWdgt.coffee`) is the Docs Maker's document: a
`MakerDocumentWdgt` (title, save-or-destroy close, payload rebuild) whose payload is a
`DocumentViewportWdgt` (a vertical stack seeded with one editable paragraph). The frame does the
chrome; the payload owns edit/view mode. `LayoutElementAdderOrDropletWdgt` is the stack's slot a widget
is dropped into or added after, which is how blocks are inserted and moved.

**Packaging.** Parts are declared in `buildSystem/parts.json`: `spreadsheet` is a lazy part requiring
`app-kit` and `authoring`; the Makers are listed in `AppCatalog` ("Docs Maker", "Sheets Maker", …);
each Examples-folder door is a one-class `example-*` part (`example-sheet` is "Party budget").

**Plots.** `src/graphs-plots-charts/` (the `plots` part) has function, bar, scatter and 3D plots; the
function plot draws a fixed example curve. No plot found that takes a function.

## 3. What to build

**Step 0 — "Print it" (small, independent).** A *Print selection* row beside Show and Inspect: run
the selection through the same seam and write its value into the text right after it (Smalltalk's
print-it; Scratch.js and Chalkboard in the references). Every text with a code receiver gets it, so a
Docs Maker document becomes an active essay with no new widget.

**Step 1 — a Notebooks Maker.**
- `NotebookWdgt`: a `MakerDocumentWdgt` whose stack holds the document's ordinary prose paragraphs and
  code cells.
- A code cell: its source text above, a `CellWdgt`-style socket below for the value. Its record is
  `SheetCellRecord` generalised to be addressed by a NAME instead of an A1 address; `FormulaCompiler`'s
  "which identifiers bind" becomes a rule each client supplies (sheet: addresses; notebook: the names
  its cells define). One compiler, one record, not copies.
- Names: `out1`, `out2`, … by default (the In/Out numbering of the owner's 2017 spec), or a chosen
  name (D2). `@` in a cell is the notebook, as `@` in a formula is the sheet.
- View mode (the payload's existing edit/view core) hides the sources: prose plus live outputs, an
  explorable document.
- Saving: sources only; opening recommits from source; widget-valued cells re-mount their restored
  widget (the sheet's rule).
- Packaging: a lazy `notebook` part, a "Notebooks Maker" in `AppCatalog`, and an Examples-folder
  door in its own `example-notebook` part holding the demo (§5).
- One new widget for the demo: a function plot that takes a function.

**Left out, on purpose.**
- A Jupyter-style run order with kernel state: out-of-order runs are what make Jupyter's results
  stale. The engine's ordering makes the question disappear.
- Markdown input: the document's own formatting toolbar does that job.
- KaTeX, an iframe sandbox, any bundled editor: shipped code is hand-written (owner rule).

## 4. The owner's 2017 spec, mapped

From `JS-Notebook-system-desiderata` (notes vault, 2017-03-14):

| Desideratum | Answer |
|---|---|
| in/out notation to reference earlier results | cell names, default `out<n>` |
| output can mix text, LaTeX, plots, ASCII formulas | the presentation chain: live widget → `cellPresenter` → text; plots via the new function plot; LaTeX out |
| input accepts Markdown | replaced by the document's formatting toolbar |
| move / delete / edit / insert blocks | the document stack's existing handling |
| visible which blocks have stale results | a reactive cell is never stale; a broken cell's error shows in it and in every cell downstream |

## 5. The demo: "Waves", behind an Examples door

1. A paragraph, a cell `k = new SliderWdgt 1, 10, 3, 1`, a cell `plot (x) -> Math.sin(k * x + seconds)`
   that animates.
2. Drag the slider: the plot reshapes. Break `k`'s source: the error shows in `k` and in the plot; fix
   it and both heal.
3. Drop a colour picker from the desktop into a cell `c`; the plot takes its colour from `c`.
   Computing on a live desktop object is what no referenced system does.
4. Wire the same slider into a Sheets Maker cell: one drag updates notebook and sheet, through the
   one engine.
5. View mode: the notebook reads as an essay. Save, reopen: the slider is where it was left.
6. Optional: inspect the plot, edit its drawing method live, and the notebook's output changes.

Each step doubles as a macro SystemTest (new tests leave the world as found, proven by a follower run
on both pointers; see `Fizzygum-tests/CLAUDE.md`). Steps 1, 2 and 5 rest on existing machinery; step 3
rests on the sheet's dropped-widget value; step 4 on the existing wires; the function plot and the
notebook layout are the new pieces.

## 6. What each reference contributes

(Details and links in [`js-notebook-references.md`](js-notebook-references.md).)

- Scratch.js, Chalkboard: Step 0's print-it in place, and Do it / Print it inside a document.
- javascript-notebook: one file per notebook; its read-only toggle matches view mode.
- Tangle: what view mode should feel like.
- TensorBook: a cell's `console.log` routed into its own output, if wanted.
- Math Notepad: the look, one column, each result under its expression.
- *The Design Space of Computational Notebooks*: names the positions taken here — dataflow execution
  order, live updates, widgets as outputs, publishing through view mode and the world's save.

## 7. Owner decisions

- **D1 — reactive or imperative cells?** Recommended: reactive, on `DataflowEngine`; staleness stops
  being a thing to show.
- **D2 — how a cell is named:** `name = expr` in the source (as in Observable) or a separate name
  field (as a sheet's address is).
- **D3 — where the shared cell machinery lives:** stay in the `spreadsheet` part with `notebook`
  requiring it, or move beside `DataflowEngine` in core.
- **D4 — dragging an output widget OUT of its cell:** the sheet defines dropping a widget in, not
  taking one out. Options: it leaves the cell (which then recomputes a new one), or it stays the
  cell's value wherever it is placed.
