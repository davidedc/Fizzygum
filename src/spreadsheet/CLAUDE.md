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
- `SpreadsheetWdgt.coffee` — the painted grid (Phase 2a): custom paint (the AnalogClockWdgt
  model) draws gridlines, lettered column / numbered row headers, and the selection; click +
  arrow-key selection (the `world.keyboardEventsReceivers` + `processKeyDown` path, focus-on-
  click). Cell model, formulas, values, presenters and sockets arrive in Phases 2b/2c/3/4.

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

## Determinism (the suite is byte-exact — see ../../../Fizzygum-tests/DETERMINISM.md)

The paint is a pure function of `{selection, geometry}` — no wall-clock, no frame count, no
intermediate-layout dependence. Keep it that way (nothing time-based lives here until time
sources arrive in Phase 5, and those enter only through the engine).

## Verifying (umbrella `fg`)

`fg build` (0 violations / `done!!!`) + `fg suite` (dpr1). New behaviour ⇒ new
`SystemTest_macro*` tests in the sibling repo (author per `../macros/CLAUDE.md` +
`MACRO-PATTERNS.md`); recaptures are WebKit-verified.
