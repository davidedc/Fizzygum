# Deferred-layout CAPSTONE — retire `world._reFittingContents` + tighten lint [E]

> **STATUS: ATTEMPTED → BLOCKED at the C2 cross-widget-convergence wall (2026-06-21). NOT shipped; reverted to clean.**
> Canonical overview: `deferred-layout-OVERVIEW.md`. The plan below (from a read-only design pass) was EXECUTED on
> slice 1 and hit a genuine wall — see the RESULT banner. Read the RESULT first; the slice plan is retained as the
> record + the starting point for whoever takes the prerequisite (the **next step**, §RESULT).

## RESULT — slice 1 executed, hit the C2 wall; the counter is load-bearing (2026-06-21)

**Outcome: NOT shipped. `world._reFittingContents` / the `WindowWdgt.add` pre-fit is doing REAL, load-bearing
cross-widget convergence work for nested aspect-locked content — it cannot be retired without first making the
window-content re-fit READ-BACK-FREE / idempotent (the next step).** Master left clean.

**What slice 1 exposed, in order (each diagnosed empirically — read-only analysis could NOT predict these):**
1. **NOT non-convergence first — two init-ordering null-derefs.** Removing `WindowWdgt.add:212`'s `@_reFitToContents()`
   crashed (`Cannot read properties of undefined (reading 'preferredStartingWidth')`, then `'canSetHeightFreely'`
   recursively) because the pre-fit *implicitly* initialised `@contents.layoutSpecDetails` (its `_adjustContentsBounds`
   ran BEFORE `super` set the layoutSpec, so the `layoutSpec != ATTACHEDAS_WINDOW_CONTENT` gate was true). Two
   order-independent init fixes (init in `_adjustContentsBounds` when details missing; init at `add` time for the
   recursive nested case) cleared BOTH crashes → **164/165, converging, no stalls** for ALL normal window content.
2. **The 1 remaining failure = the genuine C2 wall.** `macroWindowWithAClockInAWindowConstructionTwo`: the nested
   aspect-locked clock (window-in-window) renders HUGE on a drop. **Instrumented root cause:** under deferral the
   cross-widget cascade does NOT converge — it **DRIFTS +1px/frame** (windows 548→549→…→553) instead of settling,
   then the clock stretches to fill. The drift is a stale geometry READ-BACK in the stack-proportion model:
   `VerticalStackLayoutSpec.rememberInitialDimensions` (`:23`) records an element as **stretchy (`elasticity=1`)** when
   `elementWidthWithoutSpacing > availableWidthInStack`, and under deferral `availableWidthInStack`
   (`@stack.availableWidthForContents()`) is **stale-small** (the window hasn't re-fit yet) → the 170px clock reads as
   "wider than its stack" → recorded stretchy → `getWidthInStack` (`:31`) inflates it as the window grows → the
   clock↔inner↔outer feedback loop runs away. (Also `THIS_ONE_I_HAVE_NOW` reads `@contents.width()` back, and
   `WindowWdgt._adjustContentsBounds` reads applied window geometry — all part of the same read-back family.)

**Why this is a genuine wall, not a bug:** the synchronous pre-fit (+ the counter making nested seams synchronous)
ITERATES the cross-widget cascade to a stable fixed point WITHIN one frame; the deferred re-queue does ONE re-fit per
frame, and because the re-fit is NOT IDEMPOTENT (the read-backs make it drift), it never settles. Every candidate quick
fix is determinism-unsafe: forcing `elasticity=0` for aspect content, skipping re-recording on re-parent, or
de-read-backing `rememberInitialDimensions` would each change the SYNCHRONOUS-correct behaviour (windows adapting to
dropped content depends on exactly this re-recording) and needs a full soak with low odds of byte-identity.

**Part B (lint [E]) is independently cosmetic:** the two would-be violations (`ScrollPanelWdgt.rawSetExtent` /
`SimpleVerticalStackPanelWdgt.rawSetExtent` → `@_reFitToContents()`) are a legitimate synchronous APPLY-on-resize,
structurally identical to the SANCTIONED family-8 pattern (`TextWdgt.rawSetExtent → @reLayout()`). Forbidding one while
allowing the other is an arbitrary name-based line; the "conversion" (inline `_adjustContentsBounds`) does the identical
apply. The real enforcement (forbid SCHEDULES from immediate mutators) is already rule [E].

## The drift diagnosed to ONE value, then the targeted de-read-back ATTEMPTED → FALSIFIED (2026-06-21)

Pursuing the prerequisite, the nested-clock failure was instrumented and reduced to **one mis-recorded value**, then
the obvious fix was tried and **empirically broke 9 tests** — which revealed the constraint is deeper than a read-back.

**The precise diagnosis (instrumented `getWidthInStack` / `rememberInitialDimensions`):** the clock inflates because
its stored proportion `widthOfElementWhenAdded / widthOfStackWhenAdded` is wrong. `widthOfStackWhenAdded` is recorded as
**543 synchronously (correct) but 170 deferred (wrong)**:
- `getWidthInStack` is FAITHFUL (`out = availW · wEl/wStk`, elasticity-blended) — not the bug.
- Synchronous: `wEl=170, wStk=543` → clock `= 543·170/543 = 170` (stays small). Deferred: `wEl=170, wStk=170` →
  `543·170/170 = 543` (stretches to fill). The window-growth "+1px/frame" was a RED HERRING (the test's resize drag).

**The targeted fix tried (and reverted):** thread an `availableWidthOverride` into `rememberInitialDimensions` and pass
the window's available width captured at `_adjustContentsBounds` ENTRY (before the `THIS_ONE_I_HAVE_NOW` content-fit
shrinks the window to the dropped element). Hypothesis: entry-width = the settled 543, so deferred would match
synchronous, byte-identically. **RESULT: FALSIFIED — broke 9 window-content tests** (incl. the clock test it aimed to
fix): `macroClockInWindowKeepsSquareOnResize`, `macroClosingInnerWindowKeepsOuter`, `macroDuplicatedCollapsedWindowKeepsStateAndContent`,
`macroInternalWindowDroppedIntoWindowFits`, `macroResizeWindowContainingInternalWindow`, `macroScrollPanelInWindowMovesWindowWhenDragged`,
`macroWindowContentResizesFreely`, `macroWindowWithAClockInAWindowConstructionTwo`, `macroWindowsNestedCollapsingUncollapsing`.

**What that proves:** the synchronous-correct `widthOfStackWhenAdded` is NOT the entry width — it is a value the
synchronous cascade produces at a specific **converged** moment, and many tests are tightly coupled to it. So
`rememberInitialDimensions` fundamentally records a proportion **relative to the stack's SETTLED width**, and that
settled width only exists once the cross-widget cascade has converged — exactly what the synchronous pre-fit/counter
provides and what deferral removes. There is no pre-shrink value to capture; the correct value is post-convergence.

## THE NEXT STEP (deferred to a future session, owner-decided 2026-06-21): RE-ARCHITECT the stack-proportion model

The capstone is blocked on a deeper prerequisite than a read-back: **re-architect the stack-proportion model
(`VerticalStackLayoutSpec` / `WindowContentLayoutSpec` `rememberInitialDimensions` + `getWidthInStack`, and the
`WindowWdgt._adjustContentsBounds` content-fit) so an element's recorded proportion does NOT depend on the stack's
CONVERGED width.** I.e. capture/define an element's "size relative to its container" from STABLE, intent-level inputs
(the element's own natural size, an explicit base width, the container's natural/desired width) rather than the
applied container width sampled mid-cascade. Once the proportion is convergence-independent, the window-content re-fit
becomes idempotent, the deferred re-queue converges in one pass, the `WindowWdgt.add` pre-fit can be deferred, and
`world._reFittingContents` can be retired — completing the all-deferred aim. This is a standalone arc (its own design
pass + likely sanctioned reference recapture, since it changes how proportions are computed), **to be done in a next
session** — NOT a targeted inline fix (that path is now empirically closed). The init-robustness fixes from slice 1
(order-independent `layoutSpecDetails` init) are a recorded byproduct, needed only if the pre-fit is removed.

---

## (Original sliced plan — retained as the record + starting point)

## The goal (two coupled parts)

- **(A) Retire `world._reFittingContents`** — the counter that keeps the seam/twin/gesture re-fits SYNCHRONOUS inside an
  OUT-OF-PASS `_reFitToContents` cascade (so the cross-widget clock↔inner-window↔outer-window cascade converges within
  the public op; a naive mid-cascade deferral was the C2 wall).
- **(B) Tighten lint rule [E]** (`buildSystem/check-layering.js`) to FORBID synchronous container re-fits
  (`_reFitToContents`/`childGeometryChanged`) from immediate mutators (`raw*`/`silent*`/`fullRaw*`) — a build-time
  barrier against the exact class that froze 9/12 desktop apps in Phase-3b-Slice-2. **This is the high-value payoff.**

## The decisive finding — the payoff comes EARLY, the hard part is OPTIONAL

**Part B does NOT need full counter retirement, and does NOT need family-8.** It gates on ONLY the two `rawSetExtent`
overrides being converted off synchronous `_reFitToContents`. The full counter deletion (Part A) is lower marginal
reward and concentrates the freeze risk in one un-read-only-settleable behaviour-equivalence claim (the `reInflating`
decouple). So: **ship the enforcement win via slices 1–3; gate slices 4–5 behind a feasibility probe; do NOT attempt
the capstone as a single landing.**

**A "freeze" is NOT a hang** — `WorldWdgt._recalculateLayoutsCore` bails at `recalcIterationsCap=100000` (~:887) with a
`RECALC_NONCONVERGENCE` console error and empties the queue; the smoke gate (console.error = fail) + dpr1 red pixels
catch any non-convergent reroute. So bad reroutes fail loudly at dpr1/smoke, never ship silently.

## Counter census (verified — the map of what must change)

- **Declared:** `WorldWdgt.coffee:277` `_reFittingContents: 0`.
- **Bumped (3 chokepoints, try/finally inside `_reFitToContents`):** `WindowWdgt:195/199`, `SimpleVerticalStackPanelWdgt:55/59`,
  `ScrollPanelWdgt:259/264`.
- **Read (10, each `if _recalculatingLayouts or _reFittingContents → synchronous else → invalidate/enqueue`):** seam
  `Widget:1680`, twin `Widget:1621`, `newParentChoice Widget:3406`, `newParentChoiceWithHorizLayout Widget:3422`,
  `SimpleVerticalStackPanelWdgt:91/98`, `PanelWdgt:88/154`, `ScrollPanelWdgt:242/248`.
- **Which reads' synchronous arm is ACTUALLY taken outside a pass:** the **seam (1680)** (via the out-of-pass roots
  below). The **twin (1621)** only when a property-change caller fires mid-cascade. The **gesture seams** only when a
  drop/grab is nested inside another cascade. The **newParticleChoice reads are vestigial** (menu actions, counter==0,
  always take the invalidate arm) — they collapse for free.
- **Out-of-pass `_reFitToContents` ROOTS that keep the counter load-bearing:** (1) `WindowWdgt.add:212` (pre-flush);
  (2) `WindowWdgt.childUnCollapsed:263`/`childCollapsed:253` (reInflating-coupled); (3) the two `rawSetExtent`
  overrides `ScrollPanelWdgt:232`/`SimpleVerticalStackPanelWdgt:192`; (gesture/panel roots already defer post-settle).

## The slices (ordered; two adversary corrections baked in)

### Slice 1 — `WindowWdgt.add:212`: delete the pre-flush `@_reFitToContents()` (BYTE-SAFE)
Drop line 212. `super` (:213) passes `ATTACHEDAS_WINDOW_CONTENT` (≠ FREEFLOATING), so `_addCore` (~Widget:2469-2470)
invalidates the window and `mutateGeometryThenSettle`'s flush runs the window's inherited `doLayout`
(`SimpleVerticalStackPanelWdgt:70-72` `super; @_reFitToContents`) → the SAME `_adjustContentsBounds`, in-pass,
identically. The `@contents`/`@contentNeverSetInPlaceYet` bookkeeping (:203-211) is already set before super.
- **Byte-safe for the in-world, non-batched add.** AUDIT (don't assert blanket): `mutateGeometryThenSettle` has an
  ORPHAN early-return (~:771) and a BATCH early-return (~:778) — an orphan/batched window won't re-fit synchronously
  after the deletion; it settles on world-add / batch-end (the convention). The gauntlet is the oracle (stale geometry
  → deterministic dpr1 red).
- **Verify:** dpr1 → dpr2 → WebKit → smoke. Soak the nested-window/clock fixture (`macroWindowWithAClockInAWindowConstructionTwo`)
  at dpr2-under-load (this is the C2 cascade topology routed through the in-pass re-queue).

### Slice 2 — convert the two `rawSetExtent` overrides to a SYNCHRONOUS INLINE APPLY (gates Part B)
`ScrollPanelWdgt.rawSetExtent:232` and `SimpleVerticalStackPanelWdgt.rawSetExtent:192` currently call `@_reFitToContents()`.
- **CORRECTION (critical):** `rawSetExtent` IS an immediate mutator, so converting its re-fit to `@invalidateLayout()`
  (a schedule) would trip the EXISTING rule [E] and FAIL THE BUILD on this slice. The correct conversion is a
  **synchronous inline APPLY** — call `@_adjustContentsBounds()` (+ `@_adjustScrollBars()` for the scroll panel)
  DIRECTLY, dodging the forbidden leaf name `_reFitToContents`, exactly as `rawSetWidthSizeHeightAccordingly` applies
  `@doLayout()` and `TextWdgt.rawSetExtent` applies `@reLayout()`. NEVER a schedule.
- **Timing nuance (needs the soak, NOT a free lift):** the inline apply DROPS the `world._reFittingContents` bump (the
  bump lives in `_reFitToContents`, not `_adjustContentsBounds`). So during the override's re-fit, the contents' seam
  fires with `_reFittingContents=0` → outside a pass it takes the ELSE (invalidate) arm instead of the synchronous
  `childGeometryChanged` arm. LIKELY absorbed by the `@_adjustingContentsBounds` re-entrancy guard (`ScrollPanelWdgt:308`),
  but this is a byte-equivalence claim → **resize soak required**.
- **Verify:** full gauntlet + a dpr2 resize soak (the override fires on resize).

### Slice 3 — tighten lint [E] (the payoff; mechanical once slice 2 lands)
In `check-layering.js` (~:151), OR in a leaf-name rule: `REFIT_CALL = /[@.]\s*(_reFitToContents|childGeometryChanged)\b/`,
flagged only when the enclosing 2-space method header (`METHOD_HEADER`) matches `isImmediateMutator` (~:64,
`/^(raw[A-Z]|silent|fullRaw)/`).
- **CORRECTION (critical):** ENUMERATE the two exact leaf names. Do NOT use the owner's old `/Layout$/`-style suffix
  idea (check-layering.js:73 comment) — it would over-match `reLayout`/`doLayout` and FALSELY flag family-8 + every
  in-pass apply → break the build. Verified (method-boundary-aware scan): with the two leaf names, exactly the two
  slice-2 overrides are the only would-be violations; nothing else. `reLayout`/`doLayout` (family-8, base apply) are
  different leaf names → spared. The seam/twin are `_`-prefixed → never `isImmediateMutator` → spared.
- **Verify:** build → lint must be GREEN (slice 2 must have removed both violations first). Negative-test (revert one
  override → lint flags it).
- Commit slices 2+3 together (the lint enforces slice 2's conversion).

### GATE — reassess slices 4–5 (full counter retirement) behind a C2-style feasibility probe
Do NOT proceed to 4–5 without the probe. The probe: stub each reroute, run BOTH oracles:
- **`macroDuplicatedCollapsedWindowKeepsStateAndContent`** — the REAL `reInflating`-flip oracle (rectangle content,
  `canSetHeightFreely:true`; uncollapses the copy → the flag genuinely toggles stretch-to-window-height vs natural).
  (Correction: the nested test does NOT exercise the flip — `contentsRecursivelyCanSetHeightFreely:156` short-circuits
  for FIT_BOX_TO_TEXT and recurses into the inner window, so the outer's `reInflating` term isn't consulted there.)
- **`macroWindowsNestedCollapsingUncollapsing`** — the CONVERGENCE oracle (nested clock/window cascade).

### Slice 4 (gated) — decouple `@reInflating` from the inline re-fit
`WindowWdgt.childUnCollapsed:258-264` does `@reInflating=true; @_reFitToContents(); @reInflating=false`, and
`contentsRecursivelyCanSetHeightFreely:157` reads `!@reInflating` DURING the re-fit. The flag is fully contained
(WindowWdgt only; default :35). Proposed shape: hold `reInflating=true` ACROSS `@invalidateLayout(); world.recalculateLayouts()`
(so the window's in-pass `doLayout` re-runs `_adjustContentsBounds` with the flag still readable), then reset. RESIDUAL
HAZARD: the post-steps (:265-266, incl. the twin) run AFTER `reInflating=false` — fold them before the reset, or prove
the container re-fit doesn't re-enter the window's gated branch. Behaviour-equivalence — settle ONLY via the probe.

### Slice 5 (gated) — delete the counter + collapse the seam/twin
Once every out-of-pass root is rerouted: delete `world._reFittingContents` (`WorldWdgt:277`) + the 3 bumps; collapse
the seam (1680) and twin (1621) middle arms and the gesture/menu reads from 3-way to 2-way
(`if _recalculatingLayouts → enqueue/synchronous else → invalidate`).

## Leave-synchronous (verified load-bearing — do NOT convert)
`childGeometryChanged` (the cascade SINK); `reLayOutAfterContainedPanelChange`/`_refitContentsAndScrollBars` (the
absorb RETURN-VALUE contract); `TextWdgt.rawSetExtent→reLayout` + base apply chains (family-8, the in-pass APPLY base
`doLayout` depends on — converting THROWS).

## Reward vs risk (honest)
Part B (slices 1–3) = the build-time enforcement barrier = HIGH reward, LOW-MEDIUM risk (slice 1 byte-safe; slice 2 a
soak-gated timing change; slice 3 mechanical). Part A full retirement (slices 4–5) = LOWER marginal reward (a small,
correct, well-commented mechanism) + the freeze risk concentrated in slice 4 (un-settleable read-only). Recommendation:
**ship 1→2+3, bank Part B, then reassess 4–5 with the probe.**

## Verification gauntlet (self-contained, absolute paths)
```sh
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && ./build_it_please.sh   # done!!! + 0 violations (A/B/C/D/E)
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"; sleep 1 \
  && perl -e 'alarm 700; exec @ARGV' node scripts/run-all-headless.js --shards=5            # dpr1 165/165
# then --dpr=2 ; then --browser=webkit ; then node scripts/smoke-apps-headless.js (APPS OK)
# soak: caffeinate -i node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=8 --minutes=20
```
The stale-build guard refuses a stale build (exit 2); rebuild if you see it. `git commit -F` (no backticks). Ask
before commit/push.
