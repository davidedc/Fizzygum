# CLAUDE.md — src/spreadsheet/

The **spreadsheet app** — the dataflow engine's first client (cells wired by named references
in CoffeeScript formulas). Normative design:
**[`../../docs/specs/dataflow-engine-spec.md`](../../docs/specs/dataflow-engine-spec.md)** §9;
build order + phase ledger:
**[`../../docs/plans/dataflow-engine-implementation-plan.md`](../../docs/plans/dataflow-engine-implementation-plan.md)**.
The dataflow engine itself is in [`../dataflow/`](../dataflow/CLAUDE.md).

## What's here (grows per phase)

- `SpreadsheetApp.coffee` — the desktop launcher/opener (`IconicDesktopSystemWindowedApp`
  subclass; `slot: nil` ⇒ a fresh window per launch, multiple sheets allowed). `buildWindow`
  wraps a `SpreadsheetWdgt` in a window via `world.openFrameWith`. Registered at the WorldWdgt
  boot site into the desktop "examples" folder.
- `SpreadsheetWdgt.coffee` — the grid owner (Phases 2a/2b/8 + follow-ons F5/F1/F6): it paints
  NOTHING (nil appearance) — every visible thing is a child widget (see `SheetCellsPanelWdgt` /
  `SheetHeaderCellWdgt` / `CellWdgt` below) — and it CLIPS at its bounds (F6:
  `ClippingAtRectangularBoundsMixin`, cropping partial-edge headers; the panel crops partial
  cells). It materialises the widget chrome
  (`_buildChromeNoSettle` — sized with the sheet, headers built/trimmed to the visible
  counts) + the VIEWPORT of cells over the 26×100 LOGICAL sheet — the viewport DERIVES from
  the sheet's extent (F6: default 6×14, partial edge cells at a non-quantized granted size;
  the `_reLayout` arrange re-derives chrome + viewport on every resize)
  (`_reconcileViewportNoSettle` — F1 scroll: sheet-owned `viewOriginCol/Row`, wheel +
  keyboard scroll-follow, the viewport invariant below), reconciles each cell's value into its
  widget (`_reconcileCellNoSettle`), owns the single-cell selection (SHEET-space; cells render
  their own ring off the PUBLIC `isSelectedAddress`) and the type-to-edit BUFFER + keys (the
  editor WIDGET lives on the editing cell — F2; an edit COMMITS before any scroll), houses the
  shared edge-stroke helper `paintGridEdges` (the edge-ownership colours + the crossing rule),
  owns `@model` and is the formula SCOPE (`@` inside a formula is this widget).
- `SheetCellsPanelWdgt.coffee` (F5) — the TRANSPARENT `PanelWdgt` subclass spanning the data
  region and hosting the `CellWdgt`s (owner direction: cells attach into a container
  subclass). Nil appearance (the sheet never painted a data background — the backdrop shows
  through, as always); clicks escalate through it to the sheet; drops/lock-menu/editing
  amenities neutralised; its inherited bounds-clipping is LOAD-BEARING since F6 (it crops the
  PARTIAL edge cells a non-cell-quantized window size leaves at the right/bottom; pre-F6 it
  was only a standing guard — F1's cell-quantized reconcile kept every visible cell tiling it
  exactly). Paints no residual border (the old outermost right/bottom strokes were clipped
  invisible — F5 receipt C).
- `SheetHeaderCellWdgt.coffee` (F5) — one widget per HEADER cell (kind column/row/corner + its
  index; 21 in all, direct sheet children, OUTSIDE the panel so a future scroll clip never
  touches the frozen headers). Paints its 236 strip fill, its own top+left edges, and its
  letter/number label at the exact old offsets. DERIVED chrome: destroyed + rebuilt from the
  geometry constants on restore, never adopted. Clicks escalate to the sheet; column/row
  SELECTION semantics are a deliberate later arc.
- `SheetModel.coffee` (2b) — the sparse data model: a Map keyed `"A1"` of `SheetCellRecord`s +
  the address algebra (`colToLetters`/`lettersToCol`, `addressFor`/`colRowFor`, `cellAt`/
  `getOrCreateCellAt`/`valueAt`). A plain class (not a Widget); back-ref `@sheetWidget`.
- `SheetCellRecord.coffee` (2b) — one cell AND the dataflow node the engine holds by identity.
  Persistent `{@sheet, @address, @source, @widgetEntry}`; derived `{@compiledFn, @boundNames,
  @value, @errorFlag}` in `@serializationTransients` (rebuilt on load/duplicate by
  recommitting). Node protocol: `dataflowRecompute` (entry-first — F4 below — else run the
  formula, cache `@value`) / `dataflowValue` (what refs pull). Reactive reference EDGES +
  error propagation arrive in 2c.
- `FormulaCompiler.coffee` (2b) — stateless (class methods): `commit(cell, source)` scans the
  source (comments/strings stripped) for the identifiers to bind — cell refs (`A1`), helper
  names, and the time bindings `seconds`/`frame` (5, `@timeBindingNames`) — builds the
  `"(names) ->\n  <source>"` wrapper and compiles it ONCE via `compileFGCode` (bare) to
  `@compiledFn`; a compile failure yields a `#SYNTAX` `SheetError`. `commit` also declares the
  reactive edges: cell refs (with a cycle check) and time-source edges (`seconds`/`frame` → the
  world time singletons, no cycle check).
- `SheetError.coffee` (2b) — a failed computation IS the cell's value (`#SYNTAX` now; `#ERR`/
  `#LOOP` in 2c). `{@kind, @message}`, `toString -> "#" + @kind`.
- `FormulaHelpers.coffee` (3) — the optional free-function veneer (`mix A1, B1`) over the value
  classes' method algebra (spec §9.5). Static methods only; each own-property name is a bindable
  helper (the compiler's scan + `SheetCellRecord._resolveBoundName` already resolve it).
- `CellWdgt.coffee` (4/8/F5) — one VISIBLE cell, as a real widget, rendering ALL of its cell's
  view state: its own top+left GRID EDGES (always — the F5 edge-ownership convention, via the
  sheet's `paintGridEdges`), its own SELECTION RING when it is the selected cell (F2 — the
  inside form, off the sheet's public `isSelectedAddress`), its OVERLAY EDITOR while being
  edited (F2 — `_mountEditorNoSettle`/`_updateEditorTextNoSettle`/`_teardownEditorNoSettle`
  hold the passive `StringWdgt` as `@_editorWdgt`, a transient child; the sheet keeps the
  buffer + keys), and whichever value form the cell holds (spec §9.4 classify → present): a
  hosted value-widget (branch 1, a `new SliderWdgt`), a hosted presenter (branch 2, a Color →
  a swatch), or its own PAINTED scalar text (branch 3, `showScalarNoSettle`; suppressed while
  hosting or editing). Transparent background — the backdrop under the sheet shows through.
  Two-way: presentation DOWN (`hostNoSettle` / `showScalarNoSettle`), interaction UP (an
  interactive value-widget is wired via `wireValueWidget` so its firings hit the cell's
  `cellInput` → `markStale` on the cell). Serializes its `@address` + hosted widget (so a
  slider's dragged position rides the tree); the address→cell index, back-ref and editor are
  transient. In Phase 4 this was `CellSocketWdgt`, one per RICH cell; Phase 8 GENERALISED it
  to one-per-VISIBLE-cell; F5 completed the view story (edges + ring + editor in the cell).

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
  `_reconcileCellNoSettle`, which routes the value into the cell's (always-present) `CellWdgt`: a value
  that answers `cellPresenter()` (a `Color` → a `RectangleWdgt` swatch) is hosted (branch 2); a value
  that IS a Widget is hosted live (branch 1 — see the Phase-4 section below); anything else the cell
  PAINTS as `toString()` text (branch 3 — `showScalarNoSettle`; Phase 8 moved this off the sheet's old
  value-paint loop). The reconcile runs INSIDE the drain's layout settle (`DataflowEngine._drainOnePass`
  wraps the pass), so every helper is a NoSettle core.
- **Presenter lifecycle (spec §13 decision): REBUILD on value change, not reuse-and-update.** A
  branch-2 presenter is pure display with no interactive state to keep, so the sheet disposes the
  old widget and calls `cellPresenter()` again — which keeps the sheet value-class-agnostic (no
  per-class "update this widget from that value" protocol). A churn-skip (`_presentedValuesEqual`,
  the engine's `equals?`-or-identity rule; the value lives on the socket as `presentedValue`) means a
  cell whose value is unchanged keeps its widget and rebuilds nothing. Interactive value-widgets that
  must preserve state are the widget-VALUED branch (Phase 4), which is RETAINED, never rebuilt.

## Widget-valued cells & their cell widget (4; the `CellSocketWdgt` became `CellWdgt` in 8)

*(This Phase-4 section describes the per-cell host it introduced as the "socket"; Phase 8 renamed that
class `CellSocketWdgt` → `CellWdgt` and generalised it to every visible cell — read "socket" below as
"the cell's `CellWdgt`".)*

- **Branch 1 — a cell value that IS a Widget** (`new SliderWdgt`) mounts that widget LIVE in its
  `CellWdgt` (branch 1 of classify→present; presenters, branch 2, mount in the cell too).
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
- **Interactivity IN (spec §9.3 Scenario A).** The cell wires an interactive value-widget
  (`wireValueWidget` → `setTargetAndActionWithOnesPickedFromMenu nil, nil, cell, "cellInput"`): a
  drag fires `cellInput` → `SpreadsheetWdgt._markCellStaleFromHostedWidgetNoSettle` → `markStale` on the
  cell → the pooled drain recomputes the cell (retaining the widget) and its dependents in one cycle.
  A presenter (branch 2) is "one-way glass" and is NOT wired. Drag-and-DROP of desktop widgets INTO
  cells is OUT of Phase-4 scope (deferred).
- **`SliderWdgt.getValue: -> @value`** joins the export chain (§1.15) — without it `exportedValue`
  falls through for a slider. `SpreadsheetWdgt.hostedWidgetAt address` is the PUBLIC reach into a
  mounted cell widget (a macro drags `sheet.hostedWidgetAt "A1"`, never the private `_cells`).
- **Save/load semantics — retain-and-remount (decided, spec §13).** The cell serializes its
  `@address` + its hosted widget, so a widget-valued cell's live widget (with its dragged position)
  RIDES the tree. On restore `recommitAllCells` RE-INDEXES the cells (address→`CellWdgt`) and recompute
  RETAINS the restored widget (class match) instead of rebuilding it to the formula default — a moved
  slider comes back moved. The alternative (recompute-and-replace, discarding runtime state) was
  rejected: retain-and-remount is the same rule the live drag and Phase 8 scroll use, so save/load and
  scroll are one problem. The cell's wiring (`@target`/`@action`) serialises too, so a restored
  slider is still live. (Pinned by the serialization rig's `sliderRetain` check: drag→77, save, load,
  assert 77 survived — and its `grid` check: 84 cells materialised both ways, rich cells host.)
- **v1 limitation (documented).** The retain check re-CONSTRUCTS a throwaway widget each recompute (to
  read its class) — a minor v1 cost. (Phase 8 RESOLVED the old "freefloating sockets left behind when
  the sheet moves" limitation: the whole grid is freefloating and float-follows the sheet, so cells
  move with it.)

## Widget-entry cells — drop a desktop widget INTO a cell (F4)

- **Two ENTRY KINDS coexist per cell record:** a FORMULA (`@source`, everything before F4 —
  including formulas that CONSTRUCT widgets, `new SliderWdgt`, which keep their exact Phase-4
  semantics: source persists, widget retained by class match) and a **widget entry**
  (`@widgetEntry`, F4): a desktop widget DROPPED into the cell IS the cell's value — no
  formula, blank source. `dataflowRecompute` checks the entry FIRST, so the entry kind wins;
  refs flow through `exportedCellValue` unchanged (a dropped slider exports its number).
- **The GESTURES own the entry lifecycle; `FormulaCompiler.commit` never reads or writes
  `widgetEntry`** (pure source machinery). SET by the drop (`CellWdgt._reactToChildDropped`:
  re-host through `hostNoSettle` — which tolerates the already-a-child dropped widget — wire,
  blank-commit the source, set the entry, mark stale). CLEARED by (a) a USER edit-commit on
  the cell (`SpreadsheetWdgt._commitEditNoSettle`) — typed content of ANY kind, including
  blank, replaces the dropped widget, which is DESTROYED with the unhost exactly like a
  formula-widget class change (eject-to-world instead was considered and REJECTED for v1
  scope) — and (b) the drag-OUT (`CellWdgt._reactToChildGrabbed`): grabbing the entry widget
  back out empties the cell — entry + wiring cleared (bare `@target`/`@action` field-clear;
  the engine edge dies via the public `world.dataflow.removeAllEdgesOf`, equivalent for a
  value-widget, which has no incoming edges), and ⚠ the cached `record.value` is cleared
  through the normal blank-commit path — without that the next recompute's branch-1 reconcile
  would RE-HOST the widget right off the hand. Dependents see `nil` next drain; the widget
  lands wherever dropped.
- **The drag-out needed a NEW parent-side seam** (found empirically: NO payload class was
  grabbable out of a cell — `Widget.grabsToParentWhenDragged`'s generic solid-with-parent
  branch climbs the grab to the window when the parent is a plain Widget, so the plan's
  "slider-only" risk framing was falsified): `wantsDetachOfChild(aWdgt)` — a
  `wantsDropOfChild`-style opt-in query the solid-with-parent branch now consults; only
  `CellWdgt` defines it (true exactly for its `hostedWidget` — the editor and any other child
  stay solid), so it is inert everywhere else. And the same investigation exposed a LATENT F5
  hole, closed here: the panel move had silently made every CELL float-draggable out of the
  grid (`isLockingToPanels` defaults false and panel children are loose) — `CellWdgt` now
  locks to panels (grid chrome is never rippable), restoring the pre-F5 solidity.
- **Accept gate:** `CellWdgt.wantsDropOfChild` accepts plain payloads and refuses
  window-class payloads (`requiresDeliberateEmbedding` — a cell is no place for a window; the
  refused drop falls through to the desktop). The restore path needs NO special-casing: a
  blank source commits to nothing and the recompute's entry-first branch re-presents the
  restored widget (retained by identity), with its wiring riding serialization.

## Time sources — `seconds` / `frame` (5)

- **A ticking cell is an ordinary node with an edge from a time source** (spec §6) — no volatile
  concept. `FormulaCompiler.scanBoundNames` reserves `seconds` / `frame` (boundary-guarded, so
  `secondsElapsed` / `foo.frame` don't match); `commit` declares an edge `world.dataflow.secondsSource()`
  / `frameSource()` → cell (no cycle check — a source has no inputs). `SheetCellRecord._resolveBoundName`
  resolves the binding to the source's current `dataflowValue()`. The two sources live in
  `../dataflow/` (`SecondsSource`, `FrameSource`); the subscriber-count lifecycle that makes them tick
  only while a cell depends on them is engine machinery (see `../dataflow/CLAUDE.md`).
- **Pulled shape is a NUMBER** (decided Phase 5): `seconds` = epoch seconds
  (`Math.floor(dateOfCurrentCycleStart.getTime() / 1000)`), `frame` = `WorldWdgt.frameCount`. NOT the
  raw `Date` — formula arithmetic and the engine's `_valuesEqual` cutoff both want a scalar, so two
  cycles in the same wall second pull the same integer and the cutoff stops propagation until the
  second ticks. `frameCount` is incremented at cycle END (after the drain), so a `frame` formula sees
  the count of cycles COMPLETED before this one. Formulas NEVER read the wall clock — all time enters
  through the sources (mockable → deterministic, spec §10).
- **Ticks repaint, never re-layout** (spec §9.7). A tick recompute goes `_cacheValue` → `changed()`
  (paint) + the socket reconcile; a scalar takes the text branch (dispose socket, no widget) — there
  is NO `_invalidateLayout` on the tick path. Cost is linear in the affected subgraph
  (`world.dataflow.lastDrainRecomputeCount`). A `frame` cell defeats the drain's empty-pool early
  return every cycle by design (it IS per-frame); a `seconds` cell only re-propagates when the
  integer second changes.
- **Determinism:** the SecondsCell SystemTest displays time COMPARISONS (`seconds > 1e9`, always
  true), so no raw instant reaches a pixel reference; the numeric + subscriber-lifecycle facts are
  proven by value assertions. Frame/second-driven cells are excluded from pixel refs unless a macro
  drives the tick (`../../../Fizzygum-tests/DETERMINISM.md`).

## Serialization & duplication (spec §2 — the engine index is derived, never serialized)

The SHEET serializes its model + cell SOURCES + geometry (and, Phase 4/8/F5, its widget
children: the cells panel with the `CellWdgt`s + their hosted value-widgets inside, and the
header cells); the engine's edges are NOT serialized or deep-copied. On **restore**
(`_afterDeserialization`) and **duplicate** (`_reactToBeingCopied`) the sheet calls
`_recommitAllCells` — first `_reindexCellsNoSettle` (rescue the `CellWdgt`s out of the
snapshot's chrome, DESTROY the derived chrome — panel, header cells — plus any stray such as
a mid-edit overlay editor riding a cell, re-attach the cells' back-ref and re-index them,
then `_buildChromeNoSettle` to rebuild the chrome + re-home the cells into the fresh panel,
and `_reconcileViewportNoSettle` to re-establish the viewport invariant for the RESTORED view
origin — visible cells re-placed at their slots, an off-viewport HIDDEN rich cell keeping its
exemption, gaps filled; ONE path serves pre-F5 snapshots, whose cells are
direct children, and post-F5 ones), then recommit every cell (rebuild `compiledFn`/`value`
AND re-declare edges), mark all stale, one drain — so a restored/duplicated sheet re-declares
its OWN edges, RETAINS its widget-valued cells' live widgets (class match) and REBUILDS its
presenters from values (a Color's swatch is DERIVED, spec §9.4; its churn-skip
`presentedValue` is nil after restore, forcing the rebuild — no orphan/double), needing no
engine fix-up. **The constructor builds the full
grid, but the deserialize/duplicate path SKIPS the constructor (`Object.create`), so the restored/copied
cells ride the snapshot and are adopted by the re-index — never a double grid.** (This replaced Phase 3's
"sweep every derived child then rebuild" — the cell widget makes widget state survive, which the sweep
destroyed.) This requires the plain data classes to be
deep-copyable: `SheetModel`/`SheetCellRecord` `@augmentWith DeepCopierMixin`, `SheetError`
`keptByReferenceOnDeepCopy` (immutable), and the general `Map::deepCopy`/`Set::deepCopy`
(`src/boot/extensions/Map-extensions.coffee`). Derived fields are dropped on serialize
(`@serializationTransients`) and copied-then-overwritten on deep-copy. **Single-sheet keyboard
focus:** `_takeKeyboardFocus` removes other sheets from `world.keyboardEventsReceivers` first, so a
duplicated sheet (which inherits receiver membership via the copier) doesn't edit in lockstep.

## Design north star (spec §9, as of F5 — 2026-07-17)

**The sheet paints NOTHING; every visible thing is a widget.** The data cells (`CellWdgt`,
inside the transparent `SheetCellsPanelWdgt`) and the header cells (`SheetHeaderCellWdgt`,
direct children) each paint their own fill/edges/label/value/ring — the sheet is the model
owner, formula scope, keyboard receiver and geometry authority, with a nil appearance. This
completes the arc: "painted chrome, widgetized contents" (Phase 4, sockets for rich cells
only) → "widgetized viewport over painted chrome" (Phase 8, every visible DATA cell a widget)
→ "everything a widget" (F5, owner direction 2026-07-17: anything selectable/clickable should
be a Widget — headers included, toward future column/row selection). Two invariants carried
over: widget count stays bounded by the VIEWPORT, not the sparse model — an off-screen cell
(Z99 in a formula) is a live dataflow node whose record recomputes with NO widget; scroll
(F1, landed 2026-07-17) materialises/recycles the viewport's widgets over the 26×100 logical
sheet, with the hidden-rich-cell exemption keeping off-screen widget-VALUED cells' hosted
widgets alive in the tree. And the cell is the two-way
boundary adapter: it hosts the value/presenter widget and is the connection target
interactive widget-sources (slider, picker, clock) fire into — each firing a `markStale` on
the cell. Pixel law (F5 receipts, plan §3-F): every widget strokes its own TOP+LEFT edges;
the grid-coloured edge strokes BEFORE the dark edge (dark wins crossings — the crossing
rule); nobody strokes right/bottom (the old outermost strokes were clipped invisible); no
widget fills the data background (the backdrop shows through, as it always did).

## Phase 8 decisions / deviations (recorded also in the plan)

- **Data cells only (owner-confirmed scope at the time — SUPERSEDED by F5, 2026-07-17).** Phase
  8 widgetised one `CellWdgt` per visible DATA cell and left headers/gridlines painted; F5
  (plan §3-F) took the anticipated "purely additive later step": headers are
  `SheetHeaderCellWdgt`s, the gridline chrome migrated into the widgets, the sheet paints
  nothing.
- **Byte-identical, zero recaptures.** The widgetisation preserved the exact paint offsets (scalar
  text at cell-local `(4, h−6)`) and the 2px host inset, so the grid renders pixel-for-pixel as the
  old painted grid — the whole suite (dpr1/dpr2/webkit) + both serialization legs stayed green with NO
  reference change. The architecture changed; the pixels did not. (The plan had budgeted for recaptures.)
- **Full viewport materialised at construction; deserialize/duplicate adopt the snapshot's cells.**
  The constructor builds the chrome (`_buildChromeNoSettle`) + all 6×14 viewport `CellWdgt`s
  (`_reconcileViewportNoSettle`; freefloating + absolute — they float-follow the sheet; F1 split
  the old `_buildGridNoSettle` into these two: cells follow the view origin, chrome doesn't).
  The deserialize/duplicate path SKIPS the constructor (`Object.create`), so the restored/copied
  cells ride the snapshot and `_reindexCellsNoSettle` adopts them; both rebuild calls are
  idempotent (keyed by field / "kind:index" / address) so they only fill gaps — never a double
  grid.
- **Selection + editing: the sheet owns the STATE, the cell renders it (F2, executed with
  F5).** Clicks on a cell escalate to the sheet's `mouseClickLeft` (cell → cells panel, whose
  `mouseClickLeft` deliberately escalates, → sheet), which hit-tests via `_cellAtLocal` and
  keeps `@selectedCol/Row` + the whole keyboard/buffer machinery (sole-receiver doctrine).
  RENDERING lives in the cell: the ring paints off the sheet's public `isSelectedAddress`
  (drawn fully INSIDE the cell, `strokeRect 2,2,w−4,h−4` — the ONE deliberate pixel change of
  the F5 landing, the whole `macroSpreadsheet*` family recaptured), and the overlay editor is
  the editing cell's transient `@_editorWdgt` child (the cell suppresses its scalar text while
  it holds one; the old sheet-side `_isCellBeingEdited` died). Why the ring had to move (F5
  receipt B): once cells stroke their own edges AFTER the sheet's paint, a sheet-drawn ring's
  antialiased bands get overdrawn — 91/348 px flip at dpr1/dpr2 — so sheet-drawn selection
  cannot survive the widgetisation.

## F1 decisions (scroll — landed 2026-07-17; recorded also in plan §3-F)

- **Sheet-owned view origin, NOT a `ScrollPanelWdgt`** (extends the 2a direct-paint deviation
  permanently): frozen headers, the origin-0 byte-identity constraint, and CELL-QUANTIZED
  steps don't fit the scroll panel's pixel model. `viewOriginCol/Row` are PROTOTYPE defaults
  (own-only-when-scrolled — an unscrolled sheet serializes byte-for-byte as pre-F1; a pre-F1
  snapshot restores to origin 0 through the prototype) and DOCUMENT state (a saved scrolled
  sheet restores scrolled — NOT transients). Logical bounds `sheetCols`×`sheetRows` (26×100);
  the viewport is extent-DERIVED since F6 (the old `numCols`/`numRows` constants are retired
  — `defaultViewportCols/Rows` only size the default open extent).
- **THE VIEWPORT INVARIANT** (re-established by `_reconcileViewportNoSettle` on every origin
  change and on restore): exactly one VISIBLE `CellWdgt` per on-screen address at the viewport
  rect of (address − origin); exactly one HIDDEN `CellWdgt` per OFF-screen widget-VALUED cell
  (the **hidden-rich-cell exemption**: it `__hide`s in place so its hosted widget's runtime
  state keeps riding the tree and survives save/load — spec §13 retain-and-remount extended to
  scroll; the exemption predicate is "the hosted widget IS the record's value, or the record's
  value is still nil on the restore path"); nothing else. `@_cells` indexes both. A recompute
  that turns a hidden cell's value non-widget recycles it on the spot
  (`_reconcileCellNoSettle`); a widget value committed to a cell with NO widget materialises a
  hidden one right there (widgets ride the TREE, not the model — losing the mount would lose
  the widget on save).
- **Wheel + keyboard scroll-follow.** `wheel:` on the sheet (the `ActivePointerWdgt.processWheel`
  climb — cells and the panel deliberately don't implement it) follows the `ScrollPanelWdgt`
  model (axis suppression, invertWheel* prefs, per-axis at-limit ESCALATION) but quantizes to
  whole rows/cols; positive raw deltaY scrolls the view DOWN. Arrows clamp to the LOGICAL sheet
  and scroll-follow minimally; starting an edit scroll-follows first (the selection can sit
  off-viewport), and an in-progress edit COMMITS before any scroll (click-away-commits
  precedent) — the overlay editor never moves mid-edit. Headers never move: their labels derive
  from origin + slot at paint time (relabel-in-place).
- **Origin-0 byte-identity.** At view origin (0,0) every offset is the identity — the whole
  pre-F1 reference set passes unchanged (zero recaptures; all new pixels live in new tests).

## F6 decisions (resizable viewport, partial edge cells — landed 2026-07-17; details in plan §3-F)

- **The viewport DERIVES from the sheet's applied extent — never stored.** The `numCols`/
  `numRows` constants are RETIRED into two derivation pairs: `_viewportCols/RowsPartial`
  (ceil — a partial column/row counts as on-screen; feeds membership and, origin-clamped via
  `_visibleCols/Rows`, the materialise loops / header build/trim / hit-test) and
  `_viewportCols/RowsFull` (floor — scroll clamps, wheel at-limit, scroll-follow: the
  selection and the overlay editor always land on FULLY-visible cells). At the max origin
  every remaining column/row is fully visible and residual pixels are BACKDROP (owner
  decision 2); the origin clamp on the visible counts is the landing deviation — without it
  the partial count would address a column PAST the sheet edge there. `defaultViewportCols/
  Rows` (6×14) only size the default open extent.
- **FILL-class window content by DELETION**: the pre-F6 fixed-size overrides died; the
  default `FrameContentLayoutSpec` (grow 1, `canSetHeightFreely` true) + the BASE Widget
  sizing protocol are exactly right. The default open size is PINNED by `SpreadsheetApp`
  (window 452×336 − 36 chrome = 442×300 content — the pre-F6 on-screen window was ALWAYS
  452×336: the fixed content overrode the old passed 334, so the pin changes no pixel).
- **The resize seam is a `_reLayout` override** (the `StretchableWidgetContainerWdgt`
  precedent: bounds-first `_applyBounds`, then `_buildChromeNoSettle` +
  `_reconcileViewportNoSettle` re-derive everything from the just-applied frame, then
  `super`) — NOT `_positionAndResizeChildren`, which is a stack-family dispatch the
  plain-Widget `_reLayout` never calls. Reached via `_applyExtent`'s schedule-valve in the
  same flush the window grants the extent; idempotent (census), at most one visit per flush
  (revisits). Every child places ABSOLUTELY from the sheet's frame, which subsumes
  float-follow on the arrange path; scroll re-runs the chrome ensure/trim (header validity
  is origin-dependent near the sheet edge).
- **One clip for everything**: the sheet augments `ClippingAtRectangularBoundsMixin` (crops
  the partial HEADERS, which live outside the panel); the panel's inherited clip crops the
  partial CELLS — both byte-invisible at the default size (suite-proven). The sheet gains
  `minimumExtent` = headers + one cell (102×40).
- **Nothing new serializes**: the viewport derives from `@bounds` (already document state) —
  a resized sheet round-trips through its bounds; a pre-F6 default-bounds snapshot restores
  to 6×14 through the same derivations.

## Phase 2a decisions / deviations (recorded also in the plan)

- **Direct-paint, no `ScrollPanelWdgt` yet.** The spec hosts the grid in a `ScrollPanelWdgt`;
  v1 paints a fixed viewport that fits the window and defers scroll until the model exceeds it.
  The paint + hit-test math transplant into a scroll-child unchanged; sockets (2b/4) are
  unaffected. (F1 later made "no `ScrollPanelWdgt`" permanent — see the F1 section above.)
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
