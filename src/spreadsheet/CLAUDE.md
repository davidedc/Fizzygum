# CLAUDE.md — src/spreadsheet/

The **spreadsheet app** — the dataflow engine's first client (cells wired by named references
in CoffeeScript formulas). Normative design:
**[`../../docs/specs/dataflow-engine-spec.md`](../../docs/specs/dataflow-engine-spec.md)** §9;
build order + phase ledger:
**[`../../docs/dataflow-engine-implementation-plan.md`](../../docs/dataflow-engine-implementation-plan.md)**.
The dataflow engine itself is in [`../dataflow/`](../dataflow/CLAUDE.md).

## What's here (grows per phase)

- `SpreadsheetApp.coffee` — the desktop launcher/opener (`IconicDesktopSystemWindowedApp`
  subclass; `slot: nil` ⇒ a fresh window per launch, multiple sheets allowed). `buildWindow`
  wraps a `SpreadsheetWdgt` in a window via `world.openWindowWith`. Registered at the WorldWdgt
  boot site into the desktop "examples" folder.
- `SpreadsheetWdgt.coffee` — the painted grid + editor (Phases 2a/2b): custom paint (the
  AnalogClockWdgt model) draws gridlines, headers, the selection, and the committed cell VALUES
  directly; click + arrow-key selection; type-to-edit through a buffer-driven overlay editor.
  Owns `@model` and is the formula SCOPE (`@` inside a formula is this widget).
- `SheetModel.coffee` (2b) — the sparse data model: a Map keyed `"A1"` of `SheetCellRecord`s +
  the address algebra (`colToLetters`/`lettersToCol`, `addressFor`/`colRowFor`, `cellAt`/
  `getOrCreateCellAt`/`valueAt`). A plain class (not a Widget); back-ref `@sheetWidget`.
- `SheetCellRecord.coffee` (2b) — one cell AND the dataflow node the engine holds by identity.
  Persistent `{@sheet, @address, @source}`; derived `{@compiledFn, @boundNames, @value,
  @errorFlag}` in `@serializationTransients` (rebuilt on load/duplicate by recommitting). Node
  protocol: `dataflowRecompute` (run the formula, cache `@value`) / `dataflowValue` (what refs
  pull). Reactive reference EDGES + error propagation arrive in 2c.
- `FormulaCompiler.coffee` (2b) — stateless (class methods): `commit(cell, source)` scans the
  source (comments/strings stripped) for the identifiers to bind — cell refs (`A1`), helper
  names, later `seconds`/`frame` — builds the `"(names) ->\n  <source>"` wrapper and compiles it
  ONCE via `compileFGCode` (bare) to `@compiledFn`; a compile failure yields a `#SYNTAX`
  `SheetError`.
- `SheetError.coffee` (2b) — a failed computation IS the cell's value (`#SYNTAX` now; `#ERR`/
  `#LOOP` in 2c). `{@kind, @message}`, `toString -> "#" + @kind`.
- Presenters, sockets, `FormulaHelpers`, widget-valued cells arrive in Phases 3/4.

## The evaluation flow (2b)

Committing an edit is the engine's FIRST live client: `FormulaCompiler.commit cell, source`
compiles once, then `world.dataflow.markStale cell`; the once-per-cycle dataflow drain (between
stepping and layout in `doOneCycle`) calls `cell.dataflowRecompute()`, which runs
`@compiledFn.apply sheetWidget, boundValues` and caches `@value`; the grid repaints it — all in
the SAME cycle as the Enter event (deterministic, spec §10). `@` inside a formula is the
`SpreadsheetWdgt` (full world access, no sandbox — spec §9.2).

## References, errors & duplication (2c)

- **Reactive references.** `FormulaCompiler.commit` DECLARES the dataflow edges: it drops the
  cell's old incoming edges (`engine.removeEdgesInto`), then for each cell-shaped reference adds
  `engine.addEdge refCell, cell` — so editing an upstream cell marks it stale and the drain
  recomputes the downstream closure in dependency order (a diamond's bottom exactly once).
- **Cycle rejection (spec §7).** BEFORE wiring, each new edge is checked with
  `engine.wouldCloseCycle refCell, cell` (against the pre-commit graph); a cycle ⇒ the value
  becomes a `#LOOP` `SheetError`, `@compiledFn` is cleared, NO edges are declared (the drain cannot
  spin). Catches the trivial self-reference too.
- **Errors are values (spec §9.6).** A formula that THROWS is caught by the engine →
  `SheetCellRecord.dataflowNoteError` returns a `#ERR`. A cell whose INPUT is a `SheetError` yields
  that same error, short-circuiting before running its formula — so errors PROPAGATE along
  references. Error values paint in the error colour.
- **Deleting a cell (blank commit).** The value is cleared to `nil` and the cell's incoming edges
  dropped, but the NODE is KEPT — so downstream references reactively see `nil`. Full
  `removeAllEdgesOf` (node death) is reserved for the sheet's `destroy` (drops every cell's edges)
  and Phase 6 un-wiring; a plain deletion is not node death because the cell may still be referenced.

## Serialization & duplication (spec §2 — the engine index is derived, never serialized)

The SHEET serializes its model + cell SOURCES + geometry; the engine's edges are NOT serialized or
deep-copied. On **restore** (`_afterDeserialization`) and **duplicate** (`_reactToBeingCopied`) the
sheet calls `recommitAllCells` — recommit every cell (rebuild `compiledFn`/`value` AND re-declare
edges), mark all stale, one drain — so a restored/duplicated sheet re-declares its OWN edges and
needs no engine fix-up. This requires the plain data classes to be deep-copyable:
`SheetModel`/`SheetCellRecord` `@augmentWith DeepCopierMixin`, `SheetError`
`keptByReferenceOnDeepCopy` (immutable), and the general `Map::deepCopy`/`Set::deepCopy`
(`src/boot/extensions/Map-extensions.coffee`). Derived fields are dropped on serialize
(`@serializationTransients`) and copied-then-overwritten on deep-copy. **Single-sheet keyboard
focus:** `_takeKeyboardFocus` removes other sheets from `world.keyboardEventsReceivers` first, so a
duplicated sheet (which inherits receiver membership via the copier) doesn't edit in lockstep.

## Design north star (spec §9)

**Painted chrome, widgetized contents.** The sheet's appearance paints gridlines, headers and
plain text/number values DIRECTLY — no widget-per-cell (that would defeat the framework's lack
of widget virtualization; paint is already clipped). A live child widget — the **socket** —
exists only for cells that hold/present rich widgets or are currently selected/being edited
(Phases 2b/4). The socket is the two-way boundary adapter: it mounts the presenter and is the
connection target interactive widget-sources (slider, picker, clock) fire into — each firing a
`markStale` on the cell.

## Phase 2a decisions / deviations (recorded also in the plan)

- **Direct-paint, no `ScrollPanelWdgt` yet.** The spec hosts the grid in a `ScrollPanelWdgt`;
  v1 paints a fixed viewport that fits the window and defers scroll until the model exceeds it.
  The paint + hit-test math transplant into a scroll-child unchanged; sockets (2b/4) are
  unaffected. Revisit when the sheet needs more cells than fit.
- **Text = 12px Arial.** SWCanvas ships bitmap atlases for Arial/Times/Courier only
  (`src/boot/extensions/SWCanvasElement-extensions.coffee`), so 12px Arial is the deterministic
  choice; left-aligned with a small pad in v1 (centering needs `measureText` — a later polish).
- **Placeholder icon** (`GenericShortcutIconWdgt`+`TypewriterIconWdgt`); a dedicated
  `SpreadsheetIconWdgt` is deferred.
- **Launcher in the examples folder** (not the desktop) to avoid shifting the desktop icon grid
  (which would recapture many desktop screenshots). Tests open a sheet via `SpreadsheetApp.launch()`.

## Phase 2b decisions / deviations (recorded also in the plan)

- **Buffer-driven overlay editor, NO caret** (deviation from "reuse the caret"). The framework
  provides no built-in "Enter commits / Escape reverts" — no `accept`/`cancel` handlers exist
  (only `CaretWdgt` escalates them, to nobody), and a live caret is a keyboard receiver that
  BLINKS (non-deterministic under a screenshot). So `SpreadsheetWdgt` stays the SOLE keyboard
  receiver in both selection and editing modes and drives its own edit BUFFER (append / Backspace
  / Enter-commits / Escape-cancels), mirroring it into a live overlay `StringWdgt`. This gives
  exact, deterministic commit/cancel and needs no caret juggling. Rich editing (cursor,
  selection, multi-line) stays the deferred `CodePromptWdgt` path (spec §9.1). The overlay is the
  first live child widget = the socket precursor (Phase 4 generalises "mount a live widget at a
  cell rect").
- **Settle discipline:** the mount/teardown of the overlay editor mutates the tree, so the ONE
  layout settle is opened at the PUBLIC event entries (`processKeyDown` / `mouseClickLeft`, like
  `world.edit`) and every edit-lifecycle helper is a `*NoSettle` core using `_addNoSettle` /
  `_setTextNoSettle` / `_fullDestroyNoSettle` / `_apply*` (satisfies `check-layering.js`).
- **Evaluation through the engine** (not eager in `commit`): commit compiles + `markStale`; the
  drain computes the value. This is what makes the spreadsheet the engine's first live client.
- **`SheetError` defined in 2b** (minimal — the `#SYNTAX` path needs it); 2c grows its use
  (`#ERR`/`#LOOP` + propagation).
- **`FormulaHelpers` deferred to Phase 3** (the veneer is only useful once value-class operations
  exist to delegate to, spec §9.5). The compiler's helper-binding scan already runs, guarded by
  `if FormulaHelpers?`, so it lights up when the class arrives — no 2b change needed.
- **No overflow clipping / centring** of painted values in v1 (values are short); a later polish
  alongside `measureText`-based centring.

## Determinism (the suite is byte-exact — see ../../../Fizzygum-tests/DETERMINISM.md)

The paint is a pure function of `{selection, geometry}` — no wall-clock, no frame count, no
intermediate-layout dependence. Keep it that way (nothing time-based lives here until time
sources arrive in Phase 5, and those enter only through the engine).

## Verifying (umbrella `fg`)

`fg build` (0 violations / `done!!!`) + `fg suite` (dpr1). New behaviour ⇒ new
`SystemTest_macro*` tests in the sibling repo (author per `../macros/CLAUDE.md` +
`MACRO-PATTERNS.md`); recaptures are WebKit-verified.
