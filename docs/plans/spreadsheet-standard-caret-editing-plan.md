# Spreadsheet standard-caret cell editing — design + execution plan

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-07-24 (same day as the scalar-text-as-StringWdgt-child conversion, Fizzygum
`71f07d24` / tests `554964964` — both pushed; execute on top of those or later).

**Mandate:** ELIMINATE the spreadsheet's bespoke append/Backspace-only edit buffer as the
user-facing editing model — replace it with Fizzygum's standard caret editing (click-to-place,
arrows, selection, insertion), keeping the sheet's grid semantics (Excel-style selection keys,
Enter commits, Escape reverts, click-away commits). Do not bolt more affordances onto the
buffer model; the buffer dies as the interaction surface.

## §0 Orientation

Fizzygum is a CoffeeScript canvas GUI framework (umbrella workspace `Fizzygum-all/`; build/test
via the `fg` wrapper — see the root `CLAUDE.md`). The spreadsheet lives in `src/spreadsheet/`
(depth: its `CLAUDE.md`). The suite is 266 byte-exact screenshot macro tests (`fg presuite`
inner loop, `fg gauntlet` closing gate).

**Immediately-prior arc (2026-07-24, pushed):** every visible spreadsheet glyph became a real
widget — `CellWdgt` presents branch-3 scalar text as a passive `StringWdgt` child
(`_scalarTextWdgt`, box-inset (+4,+2)); `SheetHeaderCellWdgt` labels likewise; the overlay
EDITOR is a passive `StringWdgt` child (`_editorWdgt`, same inset) showing a sheet-owned edit
buffer, with a steady `showsEndOfTextBar` bar as the edit affordance.

**Why this plan exists:** the owner immediately hit the deferred tail of the F2 (Phase-2b)
edit model: no caret on click, no caret movement/click-positioning/selection while editing —
only append + Backspace. Owner direction: make cell editing STANDARD. The F2 model
(`src/spreadsheet/CLAUDE.md` "Buffer-driven overlay editor, NO caret") was a deliberate v1
scope cut; its two stated technical fears are now FALSIFIED — see the critical reframe.

**⚠ CRITICAL REFRAME (verified 2026-07-24 — the arc is much smaller than the F2 rationale
implies):**
1. **The accept/cancel plumbing ALREADY EXISTS end-to-end.** `CaretWdgt.accept` (Enter) does
   `world.stopEditing()` then `@escalateEvent "accept", nil`; `cancel` (ESC) likewise with
   `'cancel'` (`src/basic-widgets/CaretWdgt.coffee:401-409` — line numbers drift, grep the
   method names). `WorldWdgt.edit` parents the caret INTO the edited widget's parent
   (`_editTearingAndAddingCaretWith`, `src/WorldWdgt.coffee:~2880`: `addCaret
   aStringWidgetOrTextWidget.parent, @caret`) — so for a cell-editor StringWdgt (a child of
   `CellWdgt`) the caret is ALSO a `CellWdgt` child, and `escalateEvent` climbs cell →
   cells-panel → sheet. **The sheet (or the cell) merely implements `accept:` and `cancel:`
   handlers. No framework seam is needed.**
2. **The Fizzygum caret does NOT blink** (no blink/fps logic in `CaretWdgt.coffee` — verified
   by grep; carets appear in committed screenshot references across the suite, e.g. the affine
   click-through tests). The F2 "a caret BLINKS (non-deterministic)" rationale is stale —
   correct it in `src/spreadsheet/CLAUDE.md` when landing this plan.

## §1 Current mechanism (as of `71f07d24`) — grep-verified facts

- **Keyboard:** the sheet registers in `world.keyboardEventsReceivers` (a Set;
  `SimpleSpreadsheetWdgt._takeKeyboardFocus` removes only OTHER sheets) and receives
  `processKeyDown`. It drives: selection arrows, type-to-edit (printable key starts an edit
  with that char), the edit BUFFER `@_editBuffer` (append/Backspace), Enter → 
  `_commitEditNoSettle` (→ `FormulaCompiler.commit` + `markStale` + `_teardownEditorNoSettle`),
  Escape → cancel path, click-away-commits (in `mouseClickLeft`), scroll-follow-then-edit.
  Grep anchors: `_startEditNoSettle` / `_commitEditNoSettle` / `_cancelEditNoSettle` (names may
  differ slightly — grep `_editBuffer` for the cluster).
- **The editor child:** `CellWdgt._mountEditorNoSettle bufferText` — a `new StringWdgt
  bufferText, 12`, `isEditable = false`, `showsEndOfTextBar = true`, box `position+(4,2)`,
  extent `−(4,2)`; `_updateEditorTextNoSettle` mirrors the buffer via `_setTextNoSettle`;
  `_teardownEditorNoSettle` destroys it and re-`show()`s the hidden `_scalarTextWdgt`.
- **The resting text child:** `CellWdgt._scalarTextWdgt` (transient; rebuilt by the drain's
  reconcile via `showScalarNoSettle`; hidden while editing via `__hide`).
- **`world.edit(target)`** (`WorldWdgt.coffee:~2870`): destroys any previous caret, `new
  CaretWdgt target`, adds it to `target.parent`, adds the CARET to `keyboardEventsReceivers`.
  While a caret lives, keys reach BOTH the caret and the sheet (the receivers Set is not
  exclusive) — see risk R1.
- **`StringWdgt.edit`** (`StringWdgt.coffee:~1415`): the widget-side entry; ⚠ known gotcha
  (memory, affine 4A-1): a CROPPED StringWdgt routes `edit()` to a POP-OUT editor and returns
  nil — for in-cell editing call `world.edit @_editorWdgt` directly and verify the crop branch
  is not in the path (grep `edit:` body first).
- **Serialization:** `_editorWdgt` is a `CellWdgt` serialization transient; the restore
  re-index sweeps any non-hosted cell child and `_reindexCellsNoSettle` nils the edit state.
  The caret is never serialized (world chrome). The rig check
  `spreadsheet.roundtrip.midEditClean` (tests repo `scripts/serialization-roundtrip-headless.js`)
  asserts a mid-edit snapshot restores settled + not-editing with exactly the scalar-text child.

## §2 Why it is shaped this way (history)

Phase 2b (2026-07-05) wanted deterministic Enter-commits/Escape-reverts with minimal framework
surface; at the time nobody implemented the caret's accept/cancel escalations, and the caret
was believed to blink. So the sheet became sole keyboard owner with a private buffer, and
"rich editing" was explicitly deferred (spec §9.1). The 2026-07-24 conversion kept that model
verbatim, only adding the bar affordance — which made the missing caret conspicuous.

## §3 The distilled argument

The editor is already a real `StringWdgt` child; the caret already escalates accept/cancel
through the cell's parent chain; the caret doesn't blink. Therefore standard editing =
flipping the editor to `isEditable = true`, entering via `world.edit`, and moving
commit/revert from per-key buffer plumbing to `accept`/`cancel` handlers — DELETING the buffer
mirror (`_editBuffer` / `_updateEditorTextNoSettle` and the sheet's per-printable-key append
path). Every other StringWdgt in the system already edits this way; the spreadsheet is the
sole exception. Uniformity is the owner's stated design principle ("scalar text is a StringWdgt
child, period").

## §4 Target behaviour (owner-approved shape, 2026-07-24 conversation)

- Single click: selects the cell (ring), NO caret — standard spreadsheet behaviour.
- Typing on a selected cell: starts a REPLACE-edit — editor mounts with the typed char and a
  live caret at its end.
- Double-click (and/or click on the already-selected cell — pick ONE, note the other as a
  variant): enters edit with the caret AT THE CLICKED SLOT; further clicks/drags inside move
  the caret / select (free — standard `StringWdgt` behaviour once `isEditable`).
- While editing: arrows move the caret (F2-style); Enter commits; Escape reverts (restore from
  `record.source` — the model already holds it); click-away commits (both on another cell and
  outside the sheet — the world.edit caret-teardown path must funnel to commit, verify which
  hook fires: `stopEditing` → caret destroy → does an escalation fire? If not, commit from the
  sheet's existing click-away + add a caret-death commit fallback).
- The editor keeps the (4,2) inset (resting ≡ editing alignment); `showsEndOfTextBar` retires
  from the editor (the real caret replaces it — decide: delete the StringWdgt flag entirely
  (its only consumer dies; dead-code gate will flag it) or keep it dormant with a non-test
  consumer; DEFAULT: delete, and reshape the pinning test).

## §5 Fix shape (phased; each phase gate-green + owner-reviewable)

- **P1 — caret-based edit lifecycle.** Editor mounts `isEditable = true`; enter via
  `world._editNoSettle @_editorWdgt` (NoSettle twin exists — grep `_editNoSettle`) inside the
  sheet's existing edit-start settle; sheet stops appending to a buffer (typing flows through
  the caret); `accept:` handler on `CellWdgt` (or the sheet — put it where escalation lands
  first, the CELL, and forward) commits `@_editorWdgt.text`; `cancel:` restores. Sheet's
  `processKeyDown` must IGNORE keys while its caret edit is live (R1) except the keys it still
  owns (none? Enter/Escape now arrive via accept/cancel; arrows go to the caret. Tab —
  currently? grep — if unhandled, out of scope).
- **P2 — entry gestures.** Type-to-edit replace (sheet still sees the FIRST printable key —
  it is not yet editing — mounts editor with that char + `world.edit` + caret to end);
  double-click / click-on-selected → edit with caret at `slotAt(clicked pos)` (the 4A-1
  plane-mapped `pos` — NEVER `world.hand.position()`, the raw-pointer lint gate bans it).
- **P3 — delete the buffer machinery** (`_editBuffer`, `_updateEditorTextNoSettle`, the
  append/Backspace key branches); `src/spreadsheet/CLAUDE.md` F2 section rewrite (incl. the
  stale blink claim); spec §9.1 "deferred rich editing" note updated.
- **P4 — tests.** Reshape `SystemTest_macroSpreadsheetEditCaretBar` →
  `...EditCaret` (mid-edit screenshot now shows the REAL caret; add caret-click-positioning +
  mid-string insertion + Escape-revert assertions). Existing spreadsheet tests: EditCancel /
  LiteralEntry replay the PUBLIC key stream — they should stay green UNLESS their mid-edit
  pixels were captured (they were NOT — verified 2026-07-24: no legacy test screenshots
  mid-edit state). Expect: zero-to-few recaptures + the reshaped test. Serialization rig:
  mid-edit snapshot now carries editor + caret as cell children — the re-index sweep already
  destroys both (caret is a cell child here! verify `isCaret`-family exclusions in
  `childrenNotHandlesNorCarets` don't hide it from the sweep — grep) — update `midEditClean`
  only if its child-count expectation shifts.

## §0.5 Cold-execution protocol

1. `fg status` (repos clean, build FRESH); read this doc fully; read
   `src/spreadsheet/CLAUDE.md` + the three cell/sheet/header sources + `CaretWdgt.coffee`
   accept/cancel + `WorldWdgt.edit` family. Re-grep EVERY `file:~line` above (they drift).
2. Spike S1 (30 min, throwaway probe in `Fizzygum-tests/.scratch/`): boot the build, mount a
   cell editor `isEditable=true`, `world.edit` it, synthesize keys — verify caret appears in
   the cell, typing inserts, Enter fires the cell's `accept` (add a temp handler), Escape fires
   `cancel`, and the sheet ALSO still receives processKeyDown (quantify R1). STOP if the
   escalation does not reach the cell (re-read the reframe's parenting fact first).
3. Execute P1→P4, `fg presuite` per phase, closing `fg gauntlet`; recaptures ONLY via
   `fg recapture` (gated) after `fg diffpage` eyeballing.
4. Owner review at end of arc; commit only on approval (standing preference).

## §6 Central risks

- **R1 — double key delivery:** sheet and caret are both `keyboardEventsReceivers`; typing
  during a caret edit must not ALSO trigger sheet type-to-edit/selection moves. Fix: sheet's
  `processKeyDown` early-returns while `@_editingViaCaret` (a transient flag) — or the sheet
  drops out of the receivers Set for the edit's duration (riskier: re-entry ordering).
- **R2 — caret slot from a plane-mapped click:** use the dispatcher-passed `pos` (already
  inverse-mapped; the tilted-sheet test `macroSpreadsheetTiltedClickSelectsCell` guards this).
- **R3 — StringWdgt.edit pop-out branch** for cropped text (see §1) — enter via `world.edit`
  directly; add a value assert that no pop-out window appeared.
- **R4 — caret-death ordering:** `world.edit`/`stopEditing` destroy/re-create carets;
  Escape's `cancel` runs `world.stopEditing()` BEFORE escalating — verify teardown re-entry
  (cell handler tears down the editor while the caret is mid-destroy) with the settle gates
  (capstone/settle legs catch careless pushes).
- **R5 — determinism:** keys now flow through CaretWdgt's insertion path — covered by the
  existing deterministic caret machinery (event-time, no wall clock), but the dpr2/webkit legs
  are the proof; do not hand-wave them.

## §7 Rejected alternatives

- **Keep the buffer model, add more affordances** (caret-LOOK without caret semantics,
  arrow-key buffer cursor): re-implements CaretWdgt piecemeal; rejected by the owner's
  uniformity direction.
- **A caret-look via text hacks** (appending a bar glyph to the buffer string): pollutes
  metrics/cache keys; the 2026-07-24 bar already does this properly in-buffer, and it retires.
- **Framework-level "editor session" abstraction first:** YAGNI — accept/cancel escalation +
  two handlers is the whole contract; generalize only on a second consumer.

## §8 References

- `src/spreadsheet/CLAUDE.md` (F2 model + the 2026-07-24 conversion notes);
  `docs/measurements/drawimage-blit-attribution-2026-07-24.md` (final-shape + UX sections);
  `docs/specs/dataflow-engine-spec.md` §9 (editing scope note).
- Memory: `runtime-performance-optimization-plan.md` (O4a final shape + edit-bar blocks);
  MEMORY.md "NEXT ARC" line. Standing gotchas: raw-pointer gate; macro rule [D]
  (`# macro-private-call-sanctioned:` on oracle reads); recapture via `fg recapture` only.
