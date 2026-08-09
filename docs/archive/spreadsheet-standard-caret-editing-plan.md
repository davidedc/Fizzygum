> **ARCHIVED — COMPLETE (authored + executed 2026-07-24).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Spreadsheet standard-caret cell editing — design + execution plan

**STATUS: COMPLETE — EXECUTED IN FULL 2026-07-24 (same day it was authored). All phases
S1 + P1–P4 landed; closing gauntlet green (13 legs incl. dpr1/dpr2/webkit + both
serialization rigs). See the STATUS BOX ledger below for the per-phase record, including
the two S1 findings that CORRECTED the reframe (the accept/cancel escalation was dead as
written — fire-order — and the caret does blink live but is pinned always-visible under
the harness). Current-state truth: `src/spreadsheet/CLAUDE.md` (the editing-model
section) + the dataflow spec's superseded-2b note.**

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

## STATUS BOX (execution ledger — updated per phase)

- **S1 spike: DONE 2026-07-24** (`Fizzygum-tests/.scratch/caret-cell-edit-spike.js` +
  `tab-live-set-probe.js`, throwaway). Findings, superseding parts of the reframe:
  1. ✅ The parenting fact HOLDS: `world._editNoSettle(editorWdgt)` inside the sheet's settle
     mounts the caret AS A CELL CHILD targeting the editor, correctly placed; typing inserts.
  2. ❌ **Reframe #1 CORRECTED: the accept/cancel escalation is DEAD as written.**
     `CaretWdgt.accept` runs `world.stopEditing()` FIRST, which destroys the caret and nils
     its `@parent` — the subsequent `@escalateEvent` climbs from nil and delivers to nobody
     (empirical: cell handler never fired). This is consistent with the old 2b note
     ("only CaretWdgt escalates them, to nobody"). Fix (P1, minimal + first-consumer-only):
     capture `target = @target`, stopEditing, then `target.escalateEvent` — the TARGET is
     still parented at that moment, so the climb reaches the cell. Not a STOP-condition:
     the architecture supports the arc; only the fire-order needed the 3-line correction.
  3. ✅ **R1 mid-dispatch double delivery is REAL** (`KeydownInputEvent` iterates the LIVE
     Set): a caret created during the sheet's `processKeyDown` receives the SAME key
     (seeded 'a' → "aa"; Enter-to-edit instantly self-tears-down). Fix: dispatch over a
     SNAPSHOT (`Array.from`) in KeydownInputEvent/KeyupInputEvent. Evidence this is a
     framework REPAIR, not a workaround: ONE Tab press today runaway-hops text-field focus
     (probe: 21 hops / 20 caret creations bailed by a guard — `switchTextFieldFocus` swaps
     carets mid-dispatch and each new caret receives the same Tab).
  4. ✅ Click-away teardown (`processMouseDown` →
     `stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere` → `world.stopEditing()`) fires
     NO escalation → sheet left "editing" with a dead caret. Fix (P1): route that funnel
     through `world.caret.accept()` (click-away ACCEPTS — no-op change outside the
     spreadsheet, accept has no other consumer) + a sheet-side self-heal (a dangling edit
     commits on the next key/click).
  5. ✅ Overflow under a caret: the CROP hand-off pops out an editor window at ~8 chars
     mid-typing. With the hand-off suppressed the inline edit survives cleanly (caret clamps
     at the cell edge, display ellipsises, no repaint errors). Fix (P1): a StringWdgt
     prototype flag `alwaysEditsInline` (default false; the cell editor sets true) consulted
     by `edit`/`_editNoSettle`/`handOffToPopoutEditorIfOverflowing`.
  6. ✅ R3: entering via `world._editNoSettle` directly never pops out, even on long text.
  7. `reactToKeystroke` has NO implementors on the cell chain — the caret's per-key
     escalation lands nowhere; no surprise listeners.
  8. ⚠ Reframe #2 nuance: the caret DOES blink in live use (`BlinkerWdgt.step`, 2 fps) but
     is pinned ALWAYS-VISIBLE under the Automator (`animationsPacingControl`, state ≠ IDLE)
     — which is why carets in committed references are deterministic. P3's doc rewrite must
     say "pinned visible under the harness", not "never blinks".
  9. Tab mid-edit would today climb to `WorldWdgt.nextTab` and hop the caret to a random
     entry field WITHOUT committing → P1 swallows Tab at the cell (`nextTab`/`previousTab`
     no-ops on CellWdgt; Excel-style cell-advance stays a later variant).
- **P1: DONE 2026-07-24.** Landed (framework): KeydownInputEvent/KeyupInputEvent dispatch
  over a SNAPSHOT of the receivers Set; CaretWdgt.accept/cancel escalate from the captured
  TARGET after stopEditing (the escalation was dead as written — S1 finding 2);
  ActivePointerWdgt's click-away funnel calls `world.caret.accept()` (click-away ACCEPTS —
  byte-identical outside the sheet, accept had no other consumer); StringWdgt gains
  `alwaysEditsInline` (prototype default false) consulted by edit/_editNoSettle/
  handOffToPopoutEditorIfOverflowing. Landed (spreadsheet): the cell editor mounts
  `isEditable=true` + `alwaysEditsInline=true` (no more end-of-text bar);
  `_startEditNoSettle` enters `world._editNoSettle(editor)`; sheet's `processKeyDown`
  ignores keys while `_isCaretEditLive()` and SELF-HEALS a dangling edit (commit) before
  selection-mode handling; `CellWdgt.accept/cancel` forward to new public
  `acceptCellEdit`/`cancelCellEdit` (settle-opening); `CellWdgt.nextTab/previousTab`
  swallow Tab; `_teardownEditorNoSettle` kills a still-live caret (wheel commit-before-
  scroll path) via `world._stopEditingNoSettle()`; the dead-method gate forced the P3
  deletions of `_processKeyWhileEditingNoSettle` + both `_updateEditorTextNoSettle`
  forward into P1. Verified: 18/18 functional probe (`.scratch/caret-p1-verify.js` —
  type-to-edit seeds once, caret nav + mid-string insert, Enter-commit → model,
  Escape-revert, click-away commit via the pointer funnel, Tab swallowed, 16-char
  overflow stays inline, wheel commit leaves no orphan caret, selection arrows intact,
  plain StringWdgt editing regression-free). `fg presuite`: paint PASS; dpr1 = 5 fails,
  ALL diffpage-eyeballed + classified: EditCaretBar (bar→real caret, the designed change
  — reshaped in P4), StringWdgtInlineTypingRefitsUnderFittingModes (the ref had BAKED IN
  a double-delivered duplicate glyph — 'klmm' — from the live-Set bug; the fix's render
  is the correctly-typed run → recapture), 3 inspector tests (member list gained the
  `alwaysEditsInline` row — the standard benign churn). Recaptures DEFERRED to one gated
  `fg recapture` batch in P4 (after the test reshape) so the full-suite gate runs once.
- **P2: DONE 2026-07-24.** Type-to-edit replace + Enter/F2 edit-existing landed FREE with
  P1 (the seed path + caret-at-end were already the mount's shape). New: DOUBLE-CLICK
  enters an edit with the caret at the clicked slot — `StringWdgt.mouseDoubleClick` gains
  the dispatcher's pos param and ESCALATES when not editable (mirror of mouseClickLeft's
  else-escalate; the only other implementor, ButtonWdgt, guards on `doubleClickAction`,
  so button-label double-clicks change from dead zone to the button's own action),
  `CellWdgt.mouseDoubleClick` forwards to the sheet's new PUBLIC `startEditAtPointer`
  (select + edit inside the settle; the caret's `gotoSlot(editor.slotAt pos)` after it —
  the caret's own self-settling entry). DECIDED: click-on-already-selected variant left
  out (double-click is the standard); drag-SELECT inside the editor is NOT free (the
  editor is solid with its cell — `wantsDetachOfChild` false → `grabsToParentWhenDragged`
  true → a down+drag is the window-drag gesture) and stays out of scope; click-to-place,
  shift-click extend, double-click word-select all work. Verified: 7/7 gesture probe
  (`.scratch/caret-p2-verify.js` — double-click at slot via the scalar-child escalation,
  word-select, shift-click extend, empty-cell double-click at slot 0, switch-cell
  commit-then-edit). `fg presuite`: paint PASS; dpr1 = the SAME 5 documented fails as P1,
  nothing new.
- **P3: DONE 2026-07-24.** Deleted: `@_editBuffer` entirely (ctor, transients list, start /
  teardown / re-index writes; the seed now flows as a parameter into
  `_mountEditorNoSettle(seedText)`); `StringWdgt.showsEndOfTextBar` + its cache-key term,
  width reservation and bar paint (its only consumer died with P1 — pixel-neutral, nobody
  set it anymore). `_commitEditNoSettle` reads the editor's text as THE source (blank text
  = a legitimate emptying commit; an UNREACHABLE editor abandons instead of blanking).
  (`_processKeyWhileEditingNoSettle` + both `_updateEditorTextNoSettle` had already been
  deleted in P1 — the dead-method gate forced them forward.) Docs rewritten: the sheet's
  header EDITING paragraph; `src/spreadsheet/CLAUDE.md` (What's-here sheet + cell bullets,
  Phase-8 selection/editing bullet, the 2b bullet marked SUPERSEDED with the corrected
  history — incl. the blink claim: the caret is pinned always-visible under the Automator,
  not blink-free — plus a new standard-caret editing-model section); spec 2b deviation
  bullet marked SUPERSEDED. `fg presuite`: paint PASS; dpr1 = the SAME 5 documented fails
  (EditCaretBar's value assert on the deleted flag now fails too — reshaped in P4; the
  inspector diffs became a row SWAP: `alwaysEditsInline` in, `showsEndOfTextBar` out).
- **P4: DONE 2026-07-24.** Serialization rigs green FIRST (both: roundtrip-headless 90
  checks incl. `midEditClean` — the mid-edit snapshot now carries the EDITABLE editor +
  the CARET as cell children, serializes without crash, restores settled/not-editing with
  exactly the scalar child; the re-index sweep uses raw `children`, not the caret-excluding
  walk, and `Widget._destroyNoSettle` removes a swept caret shell from
  `keyboardEventsReceivers` — verified in src; file-roundtrip 7 checks). Test reshaped:
  `git mv` → `SystemTest_macroSpreadsheetEditCaret`, old bar references dropped, macro
  rewritten to 4 images / 5 beats (mid-edit REAL caret + inset alignment; ArrowLeft+type =
  MID-string insertion '1257' caret between 5 and 7; Escape-revert leaves A1 uncommitted;
  Enter-commit glyph-identity; double-click at [0.1,0.5] of the scalar child re-enters
  with the caret at the clicked slot < end) — all value asserts PASSED on the first
  reference-less run; one macro-rule-[D] sanction comment was demanded by the layering
  gate. Gated `fg recapture` batch (the 4 churned tests + the new one):
  **✅ RECAPTURE COMPLETE — full suite GREEN at dpr1 AND dpr2.** New references
  eyeball-verified (image_2 shows 125|7, image_4 shows 1|27). Visualisation page emitted.
  BACKLOG section checked off; the perf plan's pin-test pointer annotated with the rename.

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
