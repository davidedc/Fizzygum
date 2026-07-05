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
- `FormulaHelpers.coffee` (3) — the optional free-function veneer (`mix A1, B1`) over the value
  classes' method algebra (spec §9.5). Static methods only; each own-property name is a bindable
  helper (the compiler's scan + `SheetCellRecord._resolveBoundName` already resolve it).
- `CellSocketWdgt.coffee` (4) — the live boundary a cell mounts a RICH value in (spec §9.3/§9.4):
  a transparent freefloating child at the cell's rect that hosts the cell's value-widget (branch 1,
  a `new SliderWdgt`) or presenter (branch 2, a Color → a swatch). Two-way: presentation DOWN
  (`hostNoSettle`), interaction UP (an interactive value-widget is wired via `wireValueWidget` so its
  firings hit the socket's `cellInput` → `markStale` on the cell). Serializes its `@address` +
  hosted widget (so a slider's dragged position rides the tree); the address→socket index is
  transient. Deliberately generalisable from one-socket-per-RICH-cell to Phase 8's
  one-per-VISIBLE-cell `CellWdgt`.

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

## Value protocol & presenters (3)

- **Exported value (spec §9.3).** `Widget.exportedValue()` is the unified reader a reference uses
  when a cell's value is a Widget: `@getColor?() ? @getValue?() ? @text`. Its first live CONSUMER
  is the Phase-4 reference-read site (`SheetCellRecord._resolveBoundName` → `SheetModel.exportedValueAt`
  → `SheetCellRecord.exportedCellValue`): a ref to a widget-valued cell yields the widget's exported
  value (a slider's number), or the widget itself if it exports nothing. `SliderWdgt` gained
  `getValue: -> @value` in Phase 4 to join the chain.
- **The value-class algebra (spec §9.5).** Operations live as METHODS on the value classes, not in
  the sheet: `Color.mixed` (promoted from its old homepage-excluded, unused state — now shipped, and
  routed through the immutable `Color.create` factory), plus new `Color.lighter` / `Color.darker`.
  `FormulaHelpers.mix` is a thin free-function veneer that delegates to `Color.mixed`. Adding a
  method to a value class (even live, via the class inspector) makes it available to the next
  recompute, since formulas compile from source.
- **Classify → present (spec §9.4), in `SpreadsheetWdgt`.** Per recompute, `_cacheValue` calls
  `_reconcileCellSocketNoSettle`: a value that answers `cellPresenter()` (a `Color` → a
  `RectangleWdgt` swatch) gets that widget hosted in a `CellSocketWdgt` in the cell's rect (branch 2);
  a value that IS a Widget is hosted live (branch 1 — see the Phase-4 section below); anything else
  falls back to the painted `toString()` text (branch 3 — the grid's default; the value-paint loop
  skips a cell that has a socket). The reconcile runs INSIDE the drain's layout settle
  (`DataflowEngine._drainOnePass` wraps the pass), so every helper is a NoSettle core.
- **Presenter lifecycle (spec §13 decision): REBUILD on value change, not reuse-and-update.** A
  branch-2 presenter is pure display with no interactive state to keep, so the sheet disposes the
  old widget and calls `cellPresenter()` again — which keeps the sheet value-class-agnostic (no
  per-class "update this widget from that value" protocol). A churn-skip (`_presentedValuesEqual`,
  the engine's `equals?`-or-identity rule; the value lives on the socket as `presentedValue`) means a
  cell whose value is unchanged keeps its widget and rebuilds nothing. Interactive value-widgets that
  must preserve state are the widget-VALUED branch (Phase 4), which is RETAINED, never rebuilt.

## Widget-valued cells & sockets (4)

- **Branch 1 — a cell value that IS a Widget** (`new SliderWdgt`) mounts that widget LIVE in a
  `CellSocketWdgt` (branch 1 of classify→present; presenters, branch 2, mount in a socket too).
  `@value` stays the raw widget (so the sheet presents it); a REFERENCE yields its EXPORTED value —
  `SheetCellRecord.exportedCellValue` runs `widget.exportedValue()` (`Widget.exportedValue`'s first
  live consumer), so `B1 = A1` on a slider-valued A1 shows the slider's number. The engine's cutoff
  compares the EXPORTED form too (`dataflowRecompute` / `dataflowValue` return it): a `Widget` has no
  `.equals`, so an identity cutoff on the widget would wrongly stop propagation when the user moves it.
- **RETAIN-AND-REMOUNT (spec §13), the phase's core rule.** A widget-valued cell's recompute runs its
  formula (`new SliderWdgt` → a throwaway) but the reconcile RETAINS the existing hosted widget when
  the class matches, discarding the throwaway. This is not an optimisation — it is what lets a
  widget-valued cell be marked stale by its OWN widget's interaction (a drag) without the recompute
  resetting the widget being dragged, and it is the SAME rule that (a) survives save/load and (b)
  Phase 8's scroll-virtualisation will reuse. The widget is (re)built only on first mount or a class
  change.
- **Interactivity IN (spec §9.3 Scenario A).** The socket wires an interactive value-widget
  (`wireValueWidget` → `setTargetAndActionWithOnesPickedFromMenu nil, nil, socket, "cellInput"`): a
  drag fires `cellInput` → `SpreadsheetWdgt._markCellStaleFromSocketNoSettle` → `markStale` on the
  cell → the pooled drain recomputes the cell (retaining the widget) and its dependents in one cycle.
  A presenter (branch 2) is "one-way glass" and is NOT wired. Drag-and-DROP of desktop widgets INTO
  cells is OUT of Phase-4 scope (deferred).
- **`SliderWdgt.getValue: -> @value`** joins the export chain (§1.15) — without it `exportedValue`
  falls through for a slider. `SpreadsheetWdgt.hostedWidgetAt address` is the PUBLIC reach into a
  mounted cell widget (a macro drags `sheet.hostedWidgetAt "A1"`, never the private `_cellSockets`).
- **Save/load semantics — retain-and-remount (decided, spec §13).** The socket serializes its
  `@address` + its hosted widget, so a widget-valued cell's live widget (with its dragged position)
  RIDES the tree. On restore `recommitAllCells` RE-INDEXES the sockets (address→socket) and recompute
  RETAINS the restored widget (class match) instead of rebuilding it to the formula default — a moved
  slider comes back moved. The alternative (recompute-and-replace, discarding runtime state) was
  rejected: retain-and-remount is the same rule the live drag and Phase 8 scroll use, so save/load and
  scroll are one problem. The socket's wiring (`@target`/`@action`) serialises too, so a restored
  slider is still live. (Pinned by the serialization rig's `sliderRetain` check: drag→77, save, load,
  assert 77 survived.)
- **v1 limitation (documented).** Sockets are freefloating children positioned at mount; a sheet that
  MOVES after mounting rich cells would leave them behind (shared with the Phase-3 presenter mount).
  Not hit by any test (the sheet is placed once); Phase 8's laid-out cells retire it. The retain check
  also re-CONSTRUCTS a throwaway widget each recompute (to read its class) — a minor v1 cost.

## Serialization & duplication (spec §2 — the engine index is derived, never serialized)

The SHEET serializes its model + cell SOURCES + geometry (and, Phase 4, its socket children + their
hosted value-widgets); the engine's edges are NOT serialized or deep-copied. On **restore**
(`_afterDeserialization`) and **duplicate** (`_reactToBeingCopied`) the sheet calls `recommitAllCells`
— first `_reindexCellSocketsNoSettle` (rebuild the transient address→socket index from the
restored/copied socket children, re-attach their back-ref, destroy any non-socket stray child), then
recommit every cell (rebuild `compiledFn`/`value` AND re-declare edges), mark all stale, one drain —
so a restored/duplicated sheet re-declares its OWN edges, RETAINS its widget-valued cells' live
widgets (class match) and REBUILDS its presenters from values (a Color's swatch is DERIVED, spec §9.4;
its churn-skip `presentedValue` is nil after restore, forcing the rebuild — no orphan/double), needing
no engine fix-up. (This replaced Phase 3's "sweep every derived child then rebuild" — the socket makes
widget state survive, which the sweep destroyed.) This requires the plain data classes to be
deep-copyable: `SheetModel`/`SheetCellRecord` `@augmentWith DeepCopierMixin`, `SheetError`
`keptByReferenceOnDeepCopy` (immutable), and the general `Map::deepCopy`/`Set::deepCopy`
(`src/boot/extensions/Map-extensions.coffee`). Derived fields are dropped on serialize
(`@serializationTransients`) and copied-then-overwritten on deep-copy. **Single-sheet keyboard
focus:** `_takeKeyboardFocus` removes other sheets from `world.keyboardEventsReceivers` first, so a
duplicated sheet (which inherits receiver membership via the copier) doesn't edit in lockstep.

## Design north star (spec §9)

**Painted chrome, widgetized contents.** The sheet's appearance paints gridlines, headers and
plain text/number values DIRECTLY — no widget-per-cell (that would defeat the framework's lack
of widget virtualization; paint is already clipped). A live child widget — the **socket**
(`CellSocketWdgt`, Phase 4) — exists only for cells that hold/present rich widgets or are currently
selected/being edited (Phases 2b/4). The socket is the two-way boundary adapter: it hosts the
value/presenter widget and is the connection target interactive widget-sources (slider, picker, clock)
fire into — each firing a `markStale` on the cell. Phase 8 generalises it from one-socket-per-RICH-cell
to one-`CellWdgt`-per-VISIBLE-cell (widgetise the grid).

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
