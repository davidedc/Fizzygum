# Phase 3b Slice 2 — completion plan (Path A: make the cycle-driven re-fit pixel-correct)

**Written 2026-06-19. Executable cold — read this top-to-bottom and you have everything.**
Companion / parents (read for depth, not required): `deferred-layout-refit-and-add-design.md` (the
design-of-record for the whole migration — its "Phase map" + "Phase 3b — Slice 2 … DIAGNOSED" bullet),
`Fizzygum-tests/DETERMINISM.md` (byte-exact contract + the dpr2-under-load flake class),
`softwrap-deferred-layout-conversion-plan.md` (the originating soft-wrap case).

---

## ✅ RESOLUTION (2026-06-19) — Path A landed; read this first

**Slice 2 is done in the working tree** (uncommitted, pending soak + `--homepage` boot + commit). The regression
in §4 turned out to be a **POLYMORPHISM break, not a fit-math problem**, so §5's "instrument the height
read-back" plan was not needed — the fix was found by reading.

**Root cause.** The WIP added a NEW method `rawSetWidthAndReLayoutSynchronously` defined **only on base `Widget`**
and pointed `WindowWdgt`/`SimpleVerticalStackPanelWdgt._adjustContentsBounds` at it. But
`rawSetWidthSizeHeightAccordingly` has **8 overrides** — `AnalogClockWdgt` (→ square), `KeepsRatioWhenInVerticalStackMixin`
(→ ratio), `WidgetHolderWithCaptionWdgt`, `StretchableWidgetContainerWdgt`, `GenericShortcutIconWdgt`,
`GenericObjectIconWdgt`, `StretchableEditableWdgt`, `Example3DPlotWdgt`. The new method carried **none** of them,
so a clock routed through it got `@rawSetWidth` only — width set, height left stale → no longer square → the
window mis-fit. Four of those overriders (`WidgetHolderWithCaptionWdgt`, `StretchableWidgetContainerWdgt`, the two
icons) ALSO `implementsDeferredLayout()`, so an `if @implementsDeferredLayout()` discriminator would have bypassed
their shape overrides too — a latent bug beyond the clock. All three content-fit failures shared this one cause.

**The fix (Option 1 — clean, smaller diff than the WIP).**
1. **Deleted** `rawSetWidthAndReLayoutSynchronously`; **reverted** the 3 call-sites in `WindowWdgt` (the two `else`
   branches of `_adjustContentsBounds`) and `SimpleVerticalStackPanelWdgt` (its `_adjustContentsBounds`) back to
   `rawSetWidthSizeHeightAccordingly`.
2. Made the **base** `Widget.rawSetWidthSizeHeightAccordingly` context-aware:
   ```coffee
   rawSetWidthSizeHeightAccordingly: (newWidth) ->
     @rawSetWidth newWidth
     if @implementsDeferredLayout()
       if world?._recalculatingLayouts then @doLayout() else @invalidateLayout()
   ```
   Every override replaces the WHOLE method, so they all keep winning (clock stays square) automatically. The ONLY
   behaviour that ever needed to change is the base body's reflow trigger, and ONLY when a container sizes a child
   from inside its own `doLayout` (i.e. during recalc) — there `@invalidateLayout()` would climb back and re-dirty
   the container (the non-convergence of §3.1); `@doLayout()` settles in place → **fixed point**.
   `world._recalculatingLayouts` (WorldWdgt:857) wraps the whole `recalculateLayouts` until-loop, so it is exactly
   "are we inside a layout pass." No new public API, no call-site churn, robust against a future container
   forgetting to opt in.

**KEPT from the WIP (orthogonal, correct):** `SimpleVerticalStackPanelWdgt.doLayout`+`implementsDeferredLayout: -> false`
(the Slice-2 trigger flip; WindowWdgt inherits); `WindowWdgt.buildAndConnectChildren` batched via
`settleLayoutsOnceAfter` (the §3.2 teardown-crash fix); `settleLayoutsOnceAfter` + the `_batchingLayoutSettling`
guard in `mutateGeometryThenSettle`; `check-layering.js` whitelist += `settleLayoutsOnceAfter`. (NB
`settleLayoutsOnceAfter` MUST be non-underscore — lint rule A forbids `_`-methods calling `recalculateLayouts`.)

**Verified:** build syntax 0 + lint A/B/C/D 0; suite **165/165 at dpr1, dpr2, AND WebKit**; clock family all pass;
**one benign recapture** — `macroDuplicatedInspectorDrivesCopiedTargetOnly` (`settleLayoutsOnceAfter` joins the
inspector member list → the list scrollbar-thumb proportion shifts; image_1 byte-identical, image_2/3 recaptured at
both densities; pixel-diff confirmed 1723 px confined to the list's thumb region, member text identical). Same
recapture precedent as Phase 3a (`585b295d3`).

**Remaining before commit:** torture soak (running dpr2/fastest/s8), `--homepage` boot check, delete the 2
untracked diagnostic scripts, then review + commit (ask owner; Fizzygum + tests separately; consider committing
`settleLayoutsOnceAfter` as its own commit). **The sections below (0–7) are the pre-resolution execution plan, kept
as the diagnosis record; `rawSetWidthAndReLayoutSynchronously` they describe no longer exists.**

---

## 0. TL;DR — where we are, in one paragraph

The deferred-layout migration moves geometry/structural mutation onto a self-settling public API. **Phase 3a**
(public `add`/`addRaw` self-settling over a private `_addCore`, guarded by an `isOrphan()` skip in
`mutateGeometryThenSettle`) and **Phase 3b Slice 1** (`ScrollPanelWdgt.doLayout` + `implementsDeferredLayout: -> false`)
are **DONE, committed, pushed** (Fizzygum `b8165920` for 3a, `00cea256` for Slice 1; tests `585b295d3`).
**Phase 3b Slice 2** = give `SimpleVerticalStackPanelWdgt`/`WindowWdgt` the same `doLayout` so their content
re-fit runs on the `recalculateLayouts` cycle (the architectural goal: re-fit via the cycle, not via ~25
scattered inline triggers). This is the determinism-sensitive capstone. **There is uncommitted WIP in the
working tree (Section 2) that FIXES the two hard blockers (non-convergence + a teardown crash → the suite no
longer freezes), but introduces a real LAYOUT REGRESSION (Section 4): a window with ratio-keeping content
(an analog clock) no longer fits its content after a resize.** Path A = make that cycle-driven re-fit
pixel-correct. The owner chose Path A. **Do NOT commit the WIP to master as-is — it red-fails 4 tests.**

---

## 1. State of the world — COMMITTED (pushed to master)

- **Phase 3a** (Fizzygum `b8165920`, tests `585b295d3`): `add`/`addRaw` are public + self-settling over a
  private non-settling `_addCore` (the old `addRaw` body). `mutateGeometryThenSettle` returns its thunk's
  value and SKIPS the flush when `@isOrphan()` (a widget attached to neither world nor hand — e.g. one being
  built in its constructor — has no world-managed layout to flush; settling a half-built widget crashes).
  `BasementOpenerWdgt.iHaveBeenAddedTo` uses `fullRawMoveTo` (fired by `_addCore` inside the settle).
- **Phase 3b Slice 1** (Fizzygum `00cea256`): `ScrollPanelWdgt` got `doLayout: (nb) -> super; @_reFitToContents()`
  and `implementsDeferredLayout: -> false`. The scroll panel re-fits on the cycle for RESIZES; byte-safe
  because `ScrollPanelWdgt._adjustContentsBounds` sizes its contents with **silent** setters
  (`@contents.silentRawSetBounds` + `@contents.reLayout()`) that don't invalidate, so its `doLayout` is a
  fixed point.
- Lint (`buildSystem/check-layering.js`) rules A/B/C/D all pass. `RECALC_WHITELIST` =
  `{doOneCycle, mutateGeometryThenSettle, settleLayoutsOnceAfter}` (the last added by the WIP, Section 2).

**HEAD of Fizzygum = `00cea256`. The WIP below is uncommitted on top of it.**

---

## 2. State of the working tree — UNCOMMITTED Slice-2 WIP (preserve / reconstruct from here)

`git -C Fizzygum diff` shows 5 files (`check-layering.js`, the design doc, `SimpleVerticalStackPanelWdgt.coffee`,
`WindowWdgt.coffee`, `Widget.coffee`). `git -C Fizzygum-tests status` shows 2 untracked diagnostic scripts
(`scripts/repro-2x.js`, `scripts/repro-profile.js`). The exact changes (reconstruct if the tree is ever lost):

### 2a. `Widget.coffee` — two new methods + a batch guard
- **`rawSetWidthAndReLayoutSynchronously: (newWidth) ->`** (after `rawSetWidthSizeHeightAccordingly`, ~:684).
  The synchronous twin of `rawSetWidthSizeHeightAccordingly` — `@rawSetWidth newWidth; if @implementsDeferredLayout() then @doLayout()`
  (the deferred form does `@invalidateLayout()` instead). WHY: a container that sizes a deferred-layout child
  via the *invalidating* form, when run ON the cycle, makes the child's `invalidateLayout` climb back to
  re-dirty the container in the same pass → the `recalculateLayouts` until-loop never converges (15000+
  `_adjustContentsBounds`/pass). The synchronous `@doLayout()` settles the child in place, no climb → fixed point.
- **`settleLayoutsOnceAfter: (thunk) ->`** (right after `mutateGeometryThenSettle`, ~:785). The BATCH
  primitive: sets `world._batchingLayoutSettling = true`, runs the thunk, clears it, then does ONE
  `world.recalculateLayouts()` (guarded `unless @isOrphan() or world._inLayoutMutation or world._recalculatingLayouts`,
  wrapping it in `world._inLayoutMutation = true … finally false`). Nestable (inner batch absorbed by outer).
  Returns the thunk's value.
- **`mutateGeometryThenSettle`** got a new guard after the `@isOrphan()` guard:
  `if world._batchingLayoutSettling then return coreThunk()` — defers the per-mutation flush to the batch's
  single end-settle.

### 2b. `SimpleVerticalStackPanelWdgt.coffee`
- Added `doLayout: (nb) -> super; @_reFitToContents()` and `implementsDeferredLayout: -> false` (mirror of
  Slice 1; WindowWdgt inherits both, since `WindowWdgt extends SimpleVerticalStackPanelWdgt`).
- `_adjustContentsBounds` line ~124: `widget.rawSetWidthSizeHeightAccordingly recommendedElementWidth`
  → `widget.rawSetWidthAndReLayoutSynchronously recommendedElementWidth`.

### 2c. `WindowWdgt.coffee`
- `_adjustContentsBounds` two sites (~:475 the `@contentNeverSetInPlaceYet` else-branch, ~:481 the
  "content already there" branch): `@contents.rawSetWidthSizeHeightAccordingly recommendedElementWidth`
  → `@contents.rawSetWidthAndReLayoutSynchronously recommendedElementWidth`.
- `buildAndConnectChildren` wrapped in the batch: renamed the body to `_buildAndConnectChildrenCore`, and
  `buildAndConnectChildren: -> @settleLayoutsOnceAfter => @_buildAndConnectChildrenCore()`. THIS is the fix
  for the teardown crash (Section 3.2).

### 2d. `buildSystem/check-layering.js`
- `RECALC_WHITELIST` gained `'settleLayoutsOnceAfter'` (it legitimately calls `recalculateLayouts`, same role
  as `mutateGeometryThenSettle`; rule B otherwise fails the build).

### 2e. Diagnostic scaffolding to DELETE before committing (not part of the fix)
- `Fizzygum-tests/scripts/repro-2x.js` — runs a test N× in one page, prints per-run time + leak indicators
  (used to rule out the leak/quadratic theory). Useful; delete or keep as a tool.
- `Fizzygum-tests/scripts/repro-profile.js` — drives the whole suite in one page, CDP-CPU-profiles the stall.
  Useful; delete or keep.
- `run-macro-test-headless.js` is CLEAN (the earlier LOOPDIAG streaming patch was reverted).

---

## 3. The diagnosis journey + EVIDENCE (so you don't re-derive it)

Slice 2's naive form (`SimpleVerticalStackPanelWdgt.doLayout = super; @_reFitToContents()`, like Slice 1)
**froze the suite**. Three layers, each diagnosed with hard evidence:

1. **Non-convergence (FIXED by 2a `rawSetWidthAndReLayoutSynchronously`).** Stack-trace under a `perl alarm`
   timeout (NB: `timeout(1)` is ABSENT in this shell — a bare `timeout … node … | grep` silently no-ops; use
   `perl -e 'alarm N; exec @ARGV' node …`): `window.doLayout → _reFitToContents → WindowWdgt._adjustContentsBounds
   → @contents.rawSetWidthSizeHeightAccordingly → (contents implementsDeferredLayout, e.g. InspectorWdgt) →
   invalidateLayout → climbs to the window (contents is non-freefloating) → re-dirties the window during its
   own doLayout → until-loop reprocesses forever`. Scroll panel is immune (silent sizing). Fix = size
   deferred children synchronously.
2. **Teardown crash (FIXED by 2c batching of `buildAndConnectChildren`).** With (1) fixed, the suite still
   froze in the multi-test run (NOT single-test). Primary error (surfaced by temporarily suppressing the
   `createErrorConsole` recovery + logging `err.stack` in the `recalculateLayouts`/`playQueuedEvents`
   catches): `TypeError: Cannot read 'availableWidthForContents' of undefined  at getWidthInStack ←
   WindowWdgt._adjustContentsBounds ← _reFitToContents ← doLayout ← recalculateLayouts ←
   mutateGeometryThenSettle ← add ← buildAndConnectChildren ← resetToDefaultContents ← childBeingDestroyed
   ← destroy ← fullDestroyChildren ← resetWorld`. I.e. during the inter-test `resetWorld`, a window's content
   is destroyed → `resetToDefaultContents` → `buildAndConnectChildren` → a self-settling `add` mid-build →
   recalc → window `doLayout` → `_adjustContentsBounds` → `VerticalStackLayoutSpec.getWidthInStack` reads
   `@stack.availableWidthForContents()` but `@stack` isn't wired yet (set by `rememberInitialDimensions`).
   Batching the rebuild → ONE settle AFTER it's complete → `@stack` set → no crash. (Single-test runs pass
   because there's nothing to tear down → `resetToDefaultContents` never fires.)
3. **The `createErrorConsole` recovery loop (the freeze AMPLIFIER — pre-existing, not yet fixed).** When any
   `doLayout` throws inside `recalculateLayouts`, `WorldWdgt._recalculateLayoutsCore`'s catch (and the
   `playQueuedEvents` catch) call `createErrorConsole`, which constructs a `SimplePlainTextScrollPanelWdgt`
   that reaches a PUBLIC setter → re-entrancy throw → `@errorConsole` never set → retried every cycle →
   FREEZE. So ANY primary `doLayout` error became a hang, not a visible error. **Worth fixing independently**
   (convert `createErrorConsole`'s setters to raw, or build the console outside the flush) — it would have
   made all of the above a clean red test instead of a 5-min freeze. Callers: `WorldWdgt.coffee` ~:912, ~:1185,
   ~:1204, ~:1335.

**Also confirmed (ruled OUT):** no memory leak and no quadratic-compounding-across-tests — `repro-2x.js`
showed the List test 4× in one page at 4.7s→0.0s→0.0s→0.0s with flat leak indicators (`treeWidgets:21,
dirtyLayout:0` every run). And **82 zombie Chrome processes** had accrued from the session's many runs and
were starving the box (even `--shards=1` froze atop them) — ALWAYS `pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer"`
before a suite run, and re-check `pgrep -fl …| wc -l`.

### Current test result WITH the WIP (clean, no diagnostics, zombies cleared)
`cd Fizzygum-tests && node scripts/run-all-headless.js --shards=5` → **completes in ~1.3 min, all 5 shards,
NO freeze**, with **4 deterministic failures**:
`macroClockInWindowKeepsSquareOnResize`, `macroDocumentScrollsMixedTextAndClocks`,
`macroWindowWithAClockInAWindowConstructionTwo`, `macroDuplicatedInspectorDrivesCopiedTargetOnly`.

---

## 4. The REMAINING problem (Path A's target): a content-fit LAYOUT regression

`macroClockInWindowKeepsSquareOnResize` is a confirmed **real regression** (visually inspected image_3,
dpr1 SWCanvas): the reference shows a window resized to FIT the clock (tall window, large square clock
filling it); the WIP renders a **wide-short window with a small square clock floating in empty space**.
image_1/image_2 (pre-resize) MATCH; image_3/image_4 (post-resize) differ. So the clock stays square but the
**window↔content fit on resize is wrong**.

**Hypothesised cause (verify first):** moving the window/stack re-fit onto the `doLayout` cycle changes the
content-fit math vs the old inline path, specifically for **ratio-keeping content**
(`KeepsRatioWhenInVerticalStackMixin`, used by the analog clock). Two suspects, in order of likelihood:
  (a) `rawSetWidthAndReLayoutSynchronously` reads the child's **fresh** height (the synchronous `@doLayout()`)
      where the old `rawSetWidthSizeHeightAccordingly` left a **stale** height (deferred) — and
      `WindowWdgt._adjustContentsBounds` reads `@contents.height()` right after (~:476, ~:482) to compute the
      window's height. Fresh-vs-stale height → different window extent. (The owner anticipated this: "reads
      the fresh height — arguably more correct but changes the baseline.")
  (b) `super` (Widget::doLayout, which applies the window's own new extent) runs BEFORE `@_reFitToContents()`,
      vs the old inline re-fit ordering — so the content is fit against a different window extent.

The other 3 failures are unt­riaged but almost certainly: `macroDuplicatedInspectorDrivesCopiedTargetOnly` =
**benign** (the WIP added 2 new methods to `Widget` → every widget's inspector member-list grew by 2 rows →
sanctioned recapture, same as Phase 3a's `_addCore`; verify image_1 is byte-identical and only post-"show
inherited" frames moved). `macroDocumentScrollsMixedTextAndClocks` + `macroWindowWithAClockInAWindowConstructionTwo`
= same content-fit family as the clock one (both involve clocks/windows) — triage after fixing (a)/(b).

---

## 5. NEXT STEPS — Path A, in order

1. **Reproduce + instrument the content-fit math.** `cd Fizzygum-tests && pkill -9 … ; node scripts/run-macro-test-headless.js
   SystemTest_macroClockInWindowKeepsSquareOnResize --dump-failures` (it passes image_1/2, dumps image_3/4 to
   `.scratch/…`). Add temporary logging in `WindowWdgt._adjustContentsBounds` of: `@contents.height()` right
   after the sizing call, `recommendedElementWidth`, the computed window width/height, and whether the
   `@contentNeverSetInPlaceYet` vs else branch ran. Compare a WIP run to the committed-Slice-1 baseline (stash
   the WIP, capture the numbers, unstash) at the resize step — the divergent number is the cause (this is the
   DETERMINISM.md §"Step 3 — instrument the suspect state" playbook). Capture page console with `--all-logs`
   (it dumps at end; or stream via a small `perl alarm` wrapper if a run hangs — it shouldn't anymore).
2. **Fix the divergence so the layout is pixel-correct.** If (a): the window must compute its height from the
   content height the SAME way it did inline. Options: read the height the old way (don't rely on the
   synchronous re-fit for the height the window reads back), or make the window-fit math tolerant of the fresh
   height. If (b): reorder so the content is fit against the right window extent (mind DETERMINISM.md case-3c:
   a custom `doLayout` must apply its OWN bounds before laying out children — `super` first is correct, so the
   fix is more likely in the fit math than the order). Keep `_reFitToContents` a FIXED POINT (no
   invalidate-climb) — that's why (2a) `rawSetWidthAndReLayoutSynchronously` exists.
3. **Re-run dpr1** (`run-all-headless.js --shards=5`). Iterate 1–2 until only the **benign inspector** diff
   remains (and any genuinely-improved layouts you decide to recapture — get owner sign-off on recaptures per
   `byte-identical-not-sacred-for-benign-inspector-recapture`; a clock NOT filling its window is a regression,
   not a recapture).
4. **Triage + recapture the benign ones.** `node scripts/capture-macro-test-references.js <name> --dprs=1,2`,
   then DELETE the stale old `.js`+`.png` per image+density (the capture script leaves them → the build's
   duplicate-ref gate aborts otherwise — see the recapture gotcha).
5. **Cross-engine + determinism gauntlet.** dpr2 (`--dpr=2`) + WebKit (`--browser=webkit`) → 165/165. Then a
   **torture soak** (the design mandates it for 3b): `node scripts/torture-headless.js --dprs=2 --speeds=fastest
   --shards=8 --minutes=N` (prefix `caffeinate -i`). Canaries: `macroNestedScrollPanelsRouteWheel`,
   `macroScrollBarsTrackContentChange`, the scroll/stack/document/window family.
6. **`--homepage` boot check** (3-step, separate `cd`s — see the homepage-boot-check memory): build `--homepage`
   in `Fizzygum/`, then `cd Fizzygum-tests && node scripts/smoke-boot-headless.js --native-only`, then restore.
7. **Clean up diagnostics** (Section 2e) and **review + commit** (ask the owner first; commit Fizzygum + tests
   separately; `git commit -F` heredoc, NO backticks/`$()` in the message). Consider committing the
   `settleLayoutsOnceAfter` batch primitive as its own earlier commit (it's independently valuable).
8. **OPTIONAL but recommended:** fix the `createErrorConsole` recovery-loop fragility (Section 3.3) so future
   `doLayout` errors surface as errors, not freezes.

---

## 6. Reference facts (signatures, sites, gotchas)

- **Re-fit chokepoint:** `_reFitToContents` (private, `?()`-soaked) = `_adjustContentsBounds` (+`_adjustScrollBars`
  on scroll panels). Defined on `ScrollPanelWdgt:246`, `SimpleVerticalStackPanelWdgt:54`, `WindowWdgt:194`.
- **The crash method:** `VerticalStackLayoutSpec.getWidthInStack` (`:31`) → `@stack.availableWidthForContents()`;
  `@stack` set by `rememberInitialDimensions(@element, @stack)` (`:18`). `availableWidthForContents` =
  `SimpleVerticalStackPanelWdgt:85` (`@width() - 2*@padding`).
- **`WindowWdgt._adjustContentsBounds`** (`:402`): sets up chrome (closeButton/collapse/edit via direct
  `child.doLayout`), then sizes `@contents` and reads `@contents.height()` back (~:476/:482) — the read-back
  that (a) is about.
- **`implementsDeferredLayout`** = `@doLayout != Widget::doLayout` (`Widget:~3838`); read at
  `rawSetWidthSizeHeightAccordingly` (`:684`, invalidate-on-resize) and `subWidgetsMergedFullBounds` (`:~1019`,
  a deferred-layout child contributes only `child.bounds`, not `fullBounds()` — the nested-scroll content-size;
  DO NOT touch this branch, proven Path-A regressor). Pinned `false` on ScrollPanel + Stack(+Window) so the
  `doLayout` doesn't flip either read site.
- **Failing tests:** `macroClockInWindowKeepsSquareOnResize` (regression, image_3/4), `macroDocumentScrollsMixedTextAndClocks`,
  `macroWindowWithAClockInAWindowConstructionTwo`, `macroDuplicatedInspectorDrivesCopiedTargetOnly` (benign member-list).
- **Tooling gotchas:** (1) NO `timeout(1)` — use `perl -e 'alarm N; exec @ARGV' node …`. (2) ALWAYS `pkill -9 -f
  "Chrome for Testing|chrome-headless|puppeteer"` before a suite run; zombies accrue and starve the box →
  spurious stalls. (3) run-all-headless / run-macro-test-headless buffer page console until completion → a
  hung test shows nothing; the `createErrorConsole` loop is the freeze source — if you ever see a freeze, it's
  a masked `doLayout` throw, surface it by suppressing `createErrorConsole` + logging `err.stack` in the
  catches. (4) Separate `cd` per repo (build in `Fizzygum/`, run/smoke in `Fizzygum-tests/`).
- **Verification recipe:** `cd Fizzygum && ./build_it_please.sh` (syntax + layering A/B/C/D gates) →
  `./build_and_smoke.sh` (boot) → `cd Fizzygum-tests && node scripts/run-all-headless.js --shards=5`
  (dpr1) → `--dpr=2` → `--browser=webkit` → torture soak.

---

## 7. Fallback (if Path A proves intractable in the next session)

Path B = revert the Slice-2 WIP (`git -C Fizzygum checkout src/SimpleVerticalStackPanelWdgt.coffee
src/WindowWdgt.coffee src/basic-widgets/Widget.coffee buildSystem/check-layering.js`), keep Slice 1 as the
banked foundation, and land the `settleLayoutsOnceAfter` batch primitive + the `createErrorConsole` raw-setter
fix as independent improvements. The diagnosis here means a future attempt starts from full understanding.
But the OWNER CHOSE PATH A — exhaust it first.
