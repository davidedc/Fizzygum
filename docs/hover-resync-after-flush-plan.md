# Hover re-sync AFTER the coalesced flush — swap plan

**STATUS BOX (updated 2026-07-04):** ✅ SWAP EXECUTED + FULLY VERIFIED — PENDING OWNER COMMIT APPROVAL.

- **Phase 1 (swap + comments): DONE.** `WorldWdgt.doOneCycle` reCheck now runs AFTER `@recalculateLayouts()`
  (`src/WorldWdgt.coffee` ~:1414–1422); swap-explaining comment added; caret-block pipeline sentence touched
  ("… → re-sync hover to settled geometry → paint …"); framing comment added above
  `ActivePointerWdgt.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges` (~:920). `fg build`: 0 violations.
- **Phase 2 (battery): ✅ except one PRE-EXISTING, SWAP-INDEPENDENT gate.** `fg gauntlet` **167/167 BYTE-EXACT
  everywhere** (dpr1+dpr2+webkit+apps+tiernaming+settle), ZERO diffs, NO recaptures. paint-readonly gate GREEN
  (0 paint-time schedules). determinism torture **8/8 ALL-PASS** (dpr2-fastest-s8 / dpr2-fast-s8 / dpr1-fastest-s8 /
  dpr2-fastest-s4, ×2 rounds; every run 167/167, failed:0, 0 `RECALC_NONCONVERGENCE`). ⚠ end-of-cycle **CAPSTONE
  gate RED on `SystemTest_macroDegreesConverterFourWayDrive` (2 careless pushes) — PROVEN PRE-EXISTING &
  SWAP-INDEPENDENT**: baseline stash+rebuild+probe shows the IDENTICAL 2 pushes with and without the swap, and
  `reCheck…` appears in NO enqueue stack. The gate's plan-purpose (no *hover handler* makes a careless push from the
  new position) is SATISFIED — zero reCheck-attributed pushes.
- **Phase 3 (docs): DONE** — `layout-system-architecture-assessment.md` §2.1 spine + read-settled narrative + §5
  appendix per-frame-cycle row updated (pointer to this plan; no rationale restated).
- **Phase 4:** end-of-arc review presented; awaiting owner commit approval (one commit in `Fizzygum`, code + docs).
- **SIDE-DISCOVERY (owner-requested investigation — see §6 below):** the capstone RED is a latent regression from the
  converter test (added 2026-07-03). Root cause: `StretchableEditableWdgt.disableDragsDropsAndEditing`
  (`src/StretchableEditableWdgt.coffee:174`) ends with a bare `@_invalidateLayout()` (pre-drawdown style, no
  self-settle) — the MISSED TWIN of the `ScrollPanelWdgt.disableDragsDropsAndEditing` push the drawdown campaign
  deleted as redundant (`ScrollPanelWdgt.coffee:875–881`). Only surfaced now because `DegreesConverterApp.buildWindow`
  calls it on an ATTACHED widget (`world.add wm` :94 THEN `disableDragsDropsAndEditing()` :98) and the capstone gate
  is NOT part of `fg gauntlet`. Recommended fix (separate change): delete the redundant push per the ScrollPanelWdgt
  precedent, prove byte-identical via disable-probe + `fg gauntlet` + capstone-green. **OUT OF SCOPE for this arc.**

## §0 What this is

Swap two adjacent lines in `WorldWdgt.doOneCycle` so the per-cycle **hover re-sync**
(`@hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()`) runs **after** the end-of-cycle
coalesced layout flush (`@recalculateLayouts()`) instead of before it — so the hover judgment reads the
frame's **settled** geometry (the same fixed point paint reads) instead of a mid-pipeline snapshot. Plus the
comment/doc updates that record the reasoning. This plan is **fully self-contained**: everything needed to
execute it cold is embedded below; no other conversation context exists.

- Repo layout: `Fizzygum-all/` (umbrella, NOT a git repo) contains sibling git repos `Fizzygum/` (source —
  the only repo this plan edits, unless recaptures are needed), `Fizzygum-tests/` (SystemTests + gates),
  `Fizzygum-builds/` (generated; never edit).
- Baseline: `Fizzygum` master at `e7b99dd8` (2026-07-04) or later; `Fizzygum-tests` master at `7f79c508d`
  or later. All `file:line` references below were verified at that baseline; **method names are
  authoritative, line numbers are approximate — re-grep before editing.**

## §1 Background (all context embedded — read this, not git archaeology)

### 1a. The frame loop today

`WorldWdgt.doOneCycle` (`src/WorldWdgt.coffee` ~:1391) runs, in order:

```coffee
@updateTimeReferences()
@showErrorsHappenedInRepaintingStepInPreviousCycle()
@showLayoutErrorsFromPreviousCycle()
@macroToolkit?.progressOnMacroSteps()
@playQueuedEvents()                    # ~:1401 — dispatch the whole input backlog; per-event mini-settles happen INSIDE the events
# replayTestCommands / runOtherTasksStepFunction / progressFramePacedActions
@runChildrensStepFunction()            # ~:1413 — stepping widgets (animations); their mutations self-settle in place
@hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()   # ~:1414  ← THE LINE TO MOVE
@recalculateLayouts()                  # ~:1415 — the ONE end-of-cycle coalesced layout flush
# (large caret comment block ~:1417–1426 — content unaffected, but its "the cycle is purely …" sentence needs a touch, §2)
@addPinoutingWidgets()                 # ~:1429 (homepage-excluded)
@addHighlightingWidgets()              # ~:1431
@updateBroken()                        # ~:1434 — paint (read-only; hard-fail gated)
```

### 1b. What the reCheck step actually is

`ActivePointerWdgt.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges` (~:920) recomputes the
widgets-under-pointer set (`topWdgtUnderPointer()` → `mouseOverNew`, a Set of the top widget + its parent
chain) and hands it to `dispatchEventsFollowingMouseMove` (~:927), which diffs against `@mouseOverList`,
firing `mouseLeave`/`mouseLeavefloatDragging` on departed widgets and `mouseMove`/`mouseEnter`/
`mouseEnterfloatDragging` on entered ones (plus the auto-scroll hook
`maybeStartAutoScrollForDraggedWidget` during float-drags), then replaces `@mouseOverList`.

**The correct framing** (the name half-says it): pointer *motion* is handled per-event inside
`playQueuedEvents`; this per-cycle step exists for **widgets that moved under (or out from under) a
STATIONARY pointer** — stepping animations, event-driven relayouts, teleports, opens/closes. It re-syncs
derived hover state to widget motion, not pointer motion.

### 1c. Why the current order is wrong (and why the swap is safe)

- **The skew:** at ~:1414 the reCheck reads **applied** bounds; the flush at ~:1415 then applies whatever
  is still pending. Post-events/post-steps, the pending set is precisely characterizable (the end-of-cycle
  drawdown campaign drove the "careless" off-settle set to a **gate-enforced zero**): essentially only
  **declared-coalesced stream geometry** — a handle move/resize drag (`_moveToCoalesced` /
  `_setExtentCoalesced` / `_setWidthCoalesced` / `_setHeightCoalesced`, `HandleWdgt.nonFloatDragging`
  ~:252) or the stack-divider drag (`_setMaxDimCoalesced`) whose `@desired*` has not been applied yet. So
  during a coalesced gesture, the hover judgment is made against last-flush geometry while `updateBroken`
  paints post-flush geometry — hover can lag geometry by one frame *within one painted frame*.
- **The pipeline criterion** (the clean-architecture rule this codebase has converged on three times —
  paint made read-only + hard-gated; the caret scroll-follow folded into per-event in-place settling; the
  track-click teleport hover fix `51b5e714` resolving enter/leave at the mutation site,
  "cadence/density-independent"): *a per-cycle stage is clean iff it reads only settled state and writes
  only state no earlier stage reads.* The reCheck currently violates the READ half — it reads geometry one
  stage too early. Post-flush, it reads the same settled fixed point paint reads.
- **The WRITE half already holds** — see the handler census (§3): hover handlers write paint-layer state
  (colors, `@changed()`, DOM cursor, tooltip countdowns, flags) and at most **self-settling** structural
  mutations (tooltip `fullDestroy`), which leave the world settled again before paint. No hover handler
  makes a *careless* (off-settle, attached, undeclared) layout push — the suite-wide **end-of-cycle
  capstone gate** enforces exactly that invariant at enqueue time, position-independently, and is green.
- **Precedent that post-flush writes are tolerated:** `addPinoutingWidgets`/`addHighlightingWidgets`
  already run after the flush and add overlay widgets via self-settling paths.
- **Determinism improves, not degrades:** settled geometry is a pure function of the event stream (what
  `Fizzygum-tests/DETERMINISM.md` demands); the pre-flush snapshot additionally depends on which mutations
  happened to be coalesced vs already applied — an engine-internal detail. (Case law: the dpr-2
  scroll-thumb hover flake, commit `51b5e714`, was exactly hover-state-vs-cadence trouble in this
  machinery.)

### 1d. Why the reCheck sat before the flush

Git archaeology: the step was introduced at `4cbfec99` ("non-float dragging now working well with
non-step-based handle-resizing mechanism") in its current position — **inherited placement, no recorded
rationale**. The only later touch (`51b5e714`) worked *around* its timing rather than moving it.

## §2 The change (Phase 1)

### 2a. The swap

In `src/WorldWdgt.coffee`, `doOneCycle` (grep `reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges`
— ONE call site in the tree):

```coffee
# BEFORE (baseline ~:1413–1415)
    @runChildrensStepFunction()
    @hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()
    @recalculateLayouts()

# AFTER
    @runChildrensStepFunction()
    @recalculateLayouts()
    # Hover re-sync AFTER the flush: re-derive the widgets-under-(stationary)-pointer set against the
    # frame's SETTLED geometry -- the same fixed point paint reads -- so hover never lags geometry within
    # a painted frame (pre-swap it read pre-flush bounds, one stage too early; coalesced drag geometry
    # was still unapplied). Handlers fired here write paint-layer state and at most SELF-SETTLING
    # mutations (tooltip fullDestroy), so the world is settled again before updateBroken; a careless
    # (off-settle) push from a hover handler would be caught by the end-of-cycle capstone gate.
    # See docs/hover-resync-after-flush-plan.md.
    @hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()
```

### 2b. Comment touch-ups (same commit)

1. The caret comment block just below (~:1417–1426) ends "…the cycle is purely process events fixing
   layouts step by step -> fix coalesced layouts -> paint, with NO caret special-case and paint still
   read-only." Extend the pipeline phrase to "…process events fixing layouts step by step -> fix coalesced
   layouts -> re-sync hover to settled geometry -> paint…".
2. `src/ActivePointerWdgt.coffee`, above `reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges`
   (~:920): add a short framing comment — this is the per-cycle re-sync for **widgets that moved under a
   stationary pointer** (pointer motion is handled per-event); it runs **after** `recalculateLayouts` in
   `doOneCycle` so it reads settled geometry; handlers must not make careless layout pushes (self-settling
   mutations are fine) — capstone-gate-enforced.

### 2c. Non-goals (do NOT do these)

- **No method rename** (`reCheckMouseEnters…` stays — a rename is a separate identifier+tests sweep).
- **No fixed-point hover loop** (flush→recheck→flush…): build only if a real layout-mutating hover handler
  ever exists. Today none does; a self-settling hover mutation self-corrects next frame like any animation.
- **No new hover gate**: the existing end-of-cycle capstone gate already catches a careless hover push
  (off-settle + attached + undeclared, recorded at enqueue time wherever it happens); a dedicated gate
  would add attribution only. Skip.
- **Do not touch** the in-place teleport resolution in `nonFloatDragWdgtFarAwayToHere` (~:907–918) — it is
  deliberately synchronous at the mutation site (`51b5e714`) and stays.

## §3 The handler census (soundness evidence — verified 2026-07-04 at baseline)

Every `mouseEnter:` / `mouseLeave:` / `mouseMove:` / `mouseEnterfloatDragging:` / `mouseLeavefloatDragging:`
implementer in `src/`, and what it writes:

| Handler | Writes |
|---|---|
| `HandleWdgt` :273/:277 | `@state` + `@changed()` (repaint) |
| `LabelButtonWdgt` :172/:177 | state + repaint; `startCountdownForBubbleHelp` (wall-clock-deferred tooltip creation via `ToolTipWdgt.createInAWhileIfHandStillContainedInWidget`); `world.destroyToolTips()` → `tooltip.fullDestroy()` — **self-settling** structural mutator (legal: settles itself) |
| `MouseSensorWdgt` :42/:45 | alpha + registers a step function (demo widget) |
| `LayoutElementAdderOrDropletWdgt` :113/:116 | `setColor` → `@color` + `@changed()` (repaint only — verified body) |
| `StackElementsSizeAdjustingWdgt` :96/:99 | DOM cursor |
| `SliderButtonWdgt` :136/:141 (+`mouseMove` :125) | hover colors + repaint |
| `MenuItemWdgt` :103/:126 | `turnOnHighlight`/`turnOffHighlight` → flag + `world.widgetsToBeHighlighted` add/delete + repaint (the overlay WIDGET is added later by `addHighlightingWidgets`, downstream of both flush and reCheck); state + tooltip countdown / `destroyToolTips` |
| `ExternalLinkButtonWdgt` :10/:13 | DOM cursor |
| `HighlightableMixin` :33/:38 | state + `updateColor` + tooltip countdown / `destroyToolTips` |
| `Example3DPlotWdgt` :219 (+`mouseMove` :205) | rotation flags |
| `mouseEnterfloatDragging:` / `mouseLeavefloatDragging:` | **zero implementers** (dispatch calls them optionally) |

Conclusion: **no careless pushes; at most self-settling mutations** — the swap cannot leave paint reading
an unsettled world, and the capstone gate holds that invariant against future handlers.

## §4 Phases

Owner workflow (standing preferences — follow them): run all phases straight through, verifying as you go;
ONE end-of-arc review at the end; **never commit or push without presenting a summary + proposed commit
message and getting explicit approval**. State an upfront ETA for any long operation and post a status
update roughly every 5 minutes while it runs.

### Phase 1 — the swap + comments (~10 min)

Apply §2a + §2b. Then build: from the umbrella root `/Users/davidedellacasa/code/Fizzygum-all` run
`./fg build` (expect the layering lints `[A]–[Q]` "0 violations" + "done!!!"). The `fg` wrapper is
cwd-correct from anywhere and fails loudly — **prefer it for every build/test step**; if using raw
commands instead, `cd` with ABSOLUTE paths per repo (a bare `./build_it_please.sh` from the umbrella
silently tests a stale build, and chaining a Fizzygum build with a Fizzygum-tests script in one `&&` hits
`MODULE_NOT_FOUND`; a PreToolUse guard hook blocks some wrong-cwd forms).

### Phase 2 — verification battery (~40–60 min total; announce ETA, status every ~5 min)

Kill zombie browsers before every suite run: `pkill -f "Chrome for Testing" || true`.

1. **`./fg gauntlet`** (~6–10 min) — build + full suite at dpr1 + dpr2 + webkit + apps smoke + tiernaming
   + notification-settle gate. Expected: **165/165 byte-exact everywhere, zero diffs** (macros rarely hold
   the pointer stationary over animating geometry; the known-sensitive teleport case was already made
   cadence-independent in-place at `51b5e714`).
2. **The two boundary gates** (each runs the whole suite with a debug audit on, ~2 min each):
   - end-of-cycle capstone: `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && bash scripts/end-of-cycle-audit/run-capstone-gate.sh` — proves no hover handler makes a careless push from the new position.
   - paint-readonly: `bash scripts/paint-readonly-audit/run-paint-readonly-gate.sh` — proves the swap didn't push layout scheduling into paint.
3. **Determinism torture — MANDATORY for a frame-loop change.** `torture-headless.js` deadlocks when run
   from an agent session; run the manual loop instead: 2 rounds each of the danger configs, checking each
   completes with `completed:true`, shards N/N, `failed:0`, and **no `RECALC_NONCONVERGENCE`** anywhere in
   output:
   ```sh
   cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
   node scripts/run-all-headless.js --dpr=2 --speed=fastest --shards=8   # dpr2-fastest-s8 (the hunter config)
   node scripts/run-all-headless.js --dpr=2 --speed=fast    --shards=8   # dpr2-fast-s8
   node scripts/run-all-headless.js --dpr=1 --speed=fastest --shards=8   # dpr1-fastest-s8
   node scripts/run-all-headless.js --dpr=2 --speed=fastest --shards=4   # dpr2-fastest-s4
   ```
   (dpr2-under-load is where a synchronous↔deferred *timing* change surfaces: heavy cycles starve timers
   and drain many events per frame.)

**If a test fails — the classification rubric:**

- **A test "failing" with ZERO failed screenshots = an uncaught error → shard stall**, not a pixel diff.
  Treat as a crash: investigate, do not recapture. (A real pass needs `completed:true` + all shards + 0
  failed.)
- **Pixel diffs:** run the failing test alone (`./fg test <name>` from the umbrella root, or
  `node scripts/run-macro-test-headless.js SystemTest_<name> --dump-failures`) and do pixel-delta
  forensics. The *expected/benign* signature for this change is a **uniform additive hover-colour delta**
  (a highlight strip present/absent — case law: a uniform additive-gray delta over a coloured background
  is a colour-state toggle, not a composite/geometry difference) on a frame where geometry moved under a
  stationary pointer — i.e. a legitimate ≤1-frame hover-timing shift. Only that signature may be
  **recaptured**: `./fg recapture <name>` (captures dpr 1+2).
  **⚠ RECAPTURE SAFEGUARD (learned the hard way):** a recapture BAKES IN whatever the frame shows — a
  crash/error frame recaptured makes the Chrome legs pass vacuously; only the WEBKIT leg surfaces it
  (crash pixels diverge V8/JSC). After ANY recapture, re-run that test under
  `--browser=webkit` and eyeball the failing/passing frames before accepting.
- **Anything else** (layout shift, missing widget, crash frame, nondeterministic flake across torture
  rounds) → STOP, investigate; if the swap is implicated and not quickly fixable, revert it and record the
  falsification in this plan's STATUS BOX with the exact failing evidence.

### Phase 3 — documentation (~15 min)

In `docs/layout-system-architecture-assessment.md` (the canonical layout doc — keep its dense style; line
numbers there are approximate by declared convention):

1. **§2.1 per-frame spine listing** (near the top; currently SEVEN lines ending `updateBroken()`): it
   **omits the reCheck step entirely**. Add, between `recalculateLayouts()` and the overlays line:
   `hand hover re-sync (reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges — re-syncs hover to
   widgets that MOVED under the stationary pointer, reading SETTLED geometry; moved after the flush
   <date>)`. Also update that section's "So layout is wedged between input/stepping and paint" narrative
   with one sentence on the read-settled pipeline criterion.
2. **§5 appendix, "Per-frame cycle" row**: add the reCheck call with its new position + one-line framing.
3. Do NOT restate the whole rationale in the doc — one framing sentence + a pointer to this plan file.

### Phase 4 — end-of-arc review + commit (owner-gated)

Re-read the full diff (`git -C Fizzygum diff`; plus `Fizzygum-tests` if recaptures happened). Present: a
summary, the verification evidence (gauntlet/gates/torture results, any recaptures + their webkit
verification), and proposed commit message(s) — **then WAIT for explicit approval**. Commit mechanics:
message via `git commit -F <file>` (NEVER backticks/`$()` inside `-m` — the shell command-substitutes
them). One commit in `Fizzygum` (code + docs); a separate one in `Fizzygum-tests` only if references were
recaptured. Push only when told.

## §5 Quick reference

- `fg` commands (from `/Users/davidedellacasa/code/Fizzygum-all`): `./fg build` · `./fg suite [--dpr=2|--browser=webkit]` ·
  `./fg gauntlet` · `./fg test <name>` · `./fg recapture <name>`.
- Headless runner flags (`Fizzygum-tests/scripts/run-all-headless.js`): `--browser=chrome|webkit`,
  `--shards=N` (default 8), `--dpr=N` (default 1), `--speed=normal|fast|fastest` (default fastest).
- Key code sites: swap site `WorldWdgt.doOneCycle` ~:1413–1415; reCheck def `ActivePointerWdgt` ~:920;
  dispatch `dispatchEventsFollowingMouseMove` ~:927; teleport in-place resolution ~:907–918; coalesced
  entrypoints `_moveToCoalesced` `Widget` ~:1395 / `_setMaxDimCoalesced` ~:3883 (family comment) /
  callers `HandleWdgt` ~:263 + `StackElementsSizeAdjustingWdgt` ~:87.
- Prereqs (should already be installed): global `coffee`/`terser`/`python3`; `cd Fizzygum-tests && npm i`
  (Puppeteer) once; `npx playwright install webkit` once.
- `nil` means `undefined`. Edit only `Fizzygum/src/**` and the two repos' docs/tests — never
  `Fizzygum-builds/**`.

## §6 Side-discovery — the pre-existing `disableDragsDropsAndEditing` careless push (investigated 2026-07-04, owner-requested)

Running the capstone gate in Phase 2 surfaced a RED that **this arc did NOT cause.** Full causation + root cause,
recorded here so a future fix arc is cold-executable:

- **Symptom:** the end-of-cycle capstone gate FAILS on `SystemTest_macroDegreesConverterFourWayDrive` — 2 careless
  end-of-cycle pushes (`1 PatchProgrammingWdgt`, `1 WindowWdgt`). (paint-readonly gate stays green.)
- **Not this arc (PROVEN, not argued):** stash the swap (`git stash push -- src/WorldWdgt.coffee
  src/ActivePointerWdgt.coffee`), rebuild, and re-probe with `Fizzygum-tests/scripts/end-of-cycle-audit/
  eoc-production-probe.js` (`PRELUDE_JS=… LOG_FILE=… node scripts/run-macro-test-headless.js
  SystemTest_macroDegreesConverterFourWayDrive`) — you get the IDENTICAL 2 pushes, same enqueue stacks, ctors, and
  specs, with and without the swap. `reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges` appears in NO
  stack. The swap only reorders reCheck vs. the flush (~:1414–1422); these pushes originate upstream at the
  macro-step stage.
- **Root cause:** `StretchableEditableWdgt.disableDragsDropsAndEditing` (`src/StretchableEditableWdgt.coffee:163`,
  inherited by `PatchProgrammingWdgt`) ends with a bare `@_invalidateLayout()` (`:174`) and never self-settles (no
  `recalculateLayouts()` / `_settleLayoutsAfter` at its tail) — the pre-drawdown "schedule a re-fit, let the flush
  drain it" style. Its own sibling `_buildAndConnectChildren` (`:180`) WAS converted to `@_settleLayoutsAfter =>
  @…NoSettle()`; this method was not.
- **Why it was missed by the drawdown campaign:** that campaign's audit is RUNTIME — it flags only pushes that
  actually fire during the suite. It DID fix the identical twin in `ScrollPanelWdgt.disableDragsDropsAndEditing`
  (DELETED the push as REDUNDANT — "disabling changes appearance + drop-handling, not this panel's settled geometry";
  see the tombstone comment `src/basic-widgets/ScrollPanelWdgt.coffee:875–881`). But at campaign time no test called
  `StretchableEditableWdgt`'s version on an ATTACHED widget off-settle, so its push never fired carelessly → never
  flagged → left as a latent twin.
- **Why it surfaced now:** the converter test (added 2026-07-03, AFTER the campaign) is the first witness —
  `DegreesConverterApp.buildWindow` does `world.add wm` (attach, `src/apps/DegreesConverterApp.coffee:94`) THEN
  `patchProgrammingWdgt.disableDragsDropsAndEditing()` (`:98`): an attached / off-settle / non-coalesced call, so the
  push fires and climbs PatchProgramming → Window → World (World is special-cased out, hence the gate counts 2). The
  capstone gate is NOT part of `fg gauntlet`, so it was never re-run at the test's landing.
- **No visual defect:** the end-of-cycle flush drains the push to the same geometry, so every screenshot passes
  byte-exact (which is why the gauntlet is green).
- **Recommended fix (a separate, tiny change):** DELETE the redundant `@_invalidateLayout()` at
  `StretchableEditableWdgt:174` per the `ScrollPanelWdgt` precedent, then prove byte-identical via the disable-probe
  + `fg gauntlet` + a green capstone re-run. Wrinkle to confirm in the probe (ScrollPanelWdgt didn't have it): this
  method also `@toolsPanel.destroy()`s the editing toolbar — verify that removal doesn't shift settled geometry (the
  byte-exact screenshots are strong evidence it doesn't). If it turns out NOT redundant, fall back to wrapping the
  body in `@_settleLayoutsAfter => …` (the `_buildAndConnectChildren` idiom). Scope is isolated to that one line —
  base `Widget` (`:3483`), `StretchablePanelWdgt` (`:114`), `StretchableWidgetContainerWdgt` (`:201`) have no
  trailing careless push, and `ScrollPanelWdgt` was already cleaned.
