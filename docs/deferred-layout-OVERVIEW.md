# Deferred-layout: OVERVIEW — aim, model, mechanism, state, what's next

**Read this first — it is the self-contained entry point for the whole deferred-layout effort.** You should be
able to pick the work up cold from this one doc. The other docs (§9 Doc map) are detail/history. Last updated
2026-06-22.

**master:** Fizzygum — at/after the capstone **`a7463bbc`** (`world._reFittingContents` retired, §4/§5) plus the
PanelWdgt residual closure (§5, 2026-06-22) / Fizzygum-tests **`6785d94ad`** — all green (suite 165/165 at
dpr1+dpr2+WebKit, smoke-apps 12/12, lint A–E 0, 20-min torture soak clean). The deferred-layout phase is **COMPLETE**
(see §5 — every off-settle synchronous re-fit trigger now defers; the remaining families are deliberately left synchronous, documented in §5).

> **This doc is canonical — it supersedes every other deferred-layout doc on any conflict.** Line numbers below are
> **approximate (as of `55c80ea6`) — the METHOD NAME is authoritative; `grep` it.** (Each shipped edit shifts lines.)
>
> **2026-06-22 — the layout-method family was renamed to a coherent private `_reLayout*` scheme** (this doc has been
> updated to the new names). Older git revisions / sibling memories use the pre-rename names; translate via:
> `doLayout`→`_reLayout`, `reLayout`→`_reLayoutSelf`, `_reFitToContents`→`_reLayoutChildren`,
> `_adjustContentsBounds`→`_positionAndResizeChildren`, `_adjustScrollBars`→`_reLayoutScrollbars`,
> `_refitContentsAndScrollBars`→`_reLayoutChildrenAndScrollbars`, `desktopReLayout`→`_reLayoutDesktop`,
> `reLayOutAfterContainedPanelChange`→`_reLayOutAfterContainedPanelChange`.

---

## 1. The aim

**Turn EVERY synchronous re-layout into a DEFERRED one.** A relayout (a `_reLayout`/`_reLayoutSelf`/container `_reLayoutChildren`)
must run at exactly one of two SETTLE POINTS, never mid-handler and never from a low-level mutator:

- **(a) the end of a geometry-changing PUBLIC method** — the self-settling flush `Widget.mutateGeometryThenSettle`
  (records intent, then runs `recalculateLayouts`); *modulo batching*, where a batch settles once via
  `settleLayoutsOnceAfter`; or
- **(b) the end of `doOneCycle`** — the `recalculateLayouts → _reLayout` pass that runs before paint.

Low-level mutators (`raw*`/`silent*`/`fullRaw*`) must only MUTATE geometry, never schedule/run layout.

## 2. The model (how deferred layout already works)

- **Public geometry setters self-settle.** The 7 public mutators — `setExtent`, `setWidth`, `setHeight`,
  `setBounds`, `fullMoveTo`, `add`, `addRaw` (all in `src/basic-widgets/Widget.coffee`) — wrap
  `mutateGeometryThenSettle`: they record desired state (`@desiredExtent`/`@desiredPosition` + `@invalidateLayout()`)
  and then run `world.recalculateLayouts()` once before returning. So a top-level caller always sees a consistent
  world; deferral is **within-frame** (no cross-frame lag).
- **The until-loop is the single settle engine.** `WorldWdgt._recalculateLayoutsCore` (`src/WorldWdgt.coffee`
  ~:876, the loop ~:885) drains `world.widgetsThatMaybeChangedLayout`, calling `_reLayout()` on the top-most invalid
  widget of each broken chain, until the queue is empty. `WorldWdgt.doOneCycle` runs it every frame before paint.
- **`invalidateLayout` is how you enqueue** (`Widget.coffee` ~:3791): `if @layoutIsValid then push @ onto
  world.widgetsThatMaybeChangedLayout; @layoutIsValid = false; climb to @parent (unless ATTACHEDAS_FREEFLOATING)`.
  It **THROWS if called while `world._recalculatingLayouts`** (the flow-rule guard, ~:3804) — a raw/handler must not
  schedule layout mid-pass (this caused the "Slice-2" app-freeze historically).
- **THE ROOT CONSTRAINT — accessors read APPLIED geometry only.** `position`/`extent`/`width`/`height`/`left`/`top`/
  `center`/`boundingBox` all read the *applied* `@bounds`. So any code that reads a widget's geometry **between a
  deferred set and the settle** sees the STALE value. This is *why* low-level code historically used the immediate
  `raw*` API + synchronous re-fits: a handler that mutates and reads geometry back in the same pass can't see the
  pending value. **Every remaining synchronous re-layout is a symptom of this one root.**

## 3. The mechanism that completes it — the DEFERRED RE-QUEUE (the key technique)

The hard case is a **freefloating content widget** (scroll content / window content / a stacked cell / a square
clock) that changes its own geometry: its container must re-fit, but **there is no clean deferred path** for that
notification because — (a) a freefloating child's `invalidateLayout` does NOT climb to its container
(`Widget.coffee` ~:3808); (b) the until-loop's walk-up **deliberately stops at freefloating widgets**
(`WorldWdgt.coffee` ~:925), so the loop never re-fits a container in response to a freefloating child; and
(c) `invalidateLayout` throws mid-pass. So the container is notified by **"seam" methods**. The seams used to re-fit
the container **synchronously**; they now **DEFER** via the re-queue:

```coffee
# In a layout pass, schedule the container into the until-loop instead of re-fitting it NOW.
# Legal mid-pass: no throw (unlike invalidateLayout), no climb. Skip a container that is mid its
# own _positionAndResizeChildren (it is driving this child top-down and already accounts for it -- enqueuing
# then would re-fire every pass and never converge).
enqueueReFitDuringPass = (container) ->
  return unless container?._reLayoutChildren?
  return if container._adjustingContentsBounds
  if container.layoutIsValid
    world.widgetsThatMaybeChangedLayout.push container
  container.layoutIsValid = false
```

Because every container's `_reLayout` is `super; @_reLayoutChildren()` (ScrollPanelWdgt ~:276, SimpleVerticalStackPanelWdgt ~:70,
WindowWdgt inherits), **enqueuing a container makes the until-loop re-fit it on the same cycle, identically.**

The seams + their conversion state (all in `Widget.coffee` unless noted):

| Seam | fired from | shape now |
|---|---|---|
| `_reFitContainerAfterRawGeometryChange` (~:1651) | the immediate mutators `silentRawSetExtent` (~:1599) + `fullRawMoveBy` (~:1243) | **2-state**: in-pass (`_recalculatingLayouts`) → enqueue · else → `invalidateLayout` (the old `_reFittingContents` synchronous middle arm was RETIRED by the capstone — §4/§5) |
| `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (~:1608) | property setters (`VerticalStackLayoutSpec` align/elasticity/base-width), collapse, content-edit/soft-wrap | **2-state** (same) |
| `reactToDropOf`/`reactToGrabOf` (ScrollPanelWdgt/PanelWdgt/SimpleVerticalStackPanelWdgt) + `PanelWdgt`'s & the stack's `childRemoved` | `ActivePointerWdgt.drop`/`grab` (after a self-settling `add`); `childRemoved` from `destroy`/reparent | **2-way**: pass/cascade → synchronous · else → `invalidateLayout` (no recalc-enqueue arm — these are never dispatched mid-pass) |

**`world._reFittingContents`** WAS a COUNTER marking "inside a cross-widget re-fit cascade" (e.g. clock ↔ inner-window ↔
outer-window), used to keep the seams **synchronous** inside such a cascade while only a PRIMARY change outside it
deferred. The capstone **RETIRED it** (§4/§5): the cross-widget cascade now converges through the **pure deferred
re-queue** — the in-pass arm enqueues the affected container into `widgetsThatMaybeChangedLayout` and the until-loop
re-fits it on the same cycle, so no synchronous middle arm is needed. (Historical detail in `deferred-layout-capstone-execution-plan.md`.)

**Path-B de-read-back** is the companion technique for constraint handlers: instead of mutate-then-read-geometry-back,
the mutator HANDS its result forward. `rawSetWidthSizeHeightAccordingly` RETURNS its resulting height (base
`Widget.coffee:706` + 8 overrides); `WindowWdgt._positionAndResizeChildren` uses the return instead of reading
`@contents.height()` back. (`SliderWdgt.updateValue` was the pilot.)

## 4. What's shipped

### Pre-session foundation (all on master)
| What | commit |
|---|---|
| Self-settling public geometry API (`mutateGeometryThenSettle`) | `817c2ce4` |
| Re-fit chokepoint `_reLayoutChildren` + lint A/B/C/D | `ad2000cc` |
| `add`/`addRaw` public & self-settling over private `_addCore` | `b8165920` |
| Stack/window content re-fit on the `_reLayout` cycle (Phase 3b) | `00cea256` / `6c7060e5` |
| **Flow rule** — raw/silent/fullRaw must MUTATE, never SCHEDULE (runtime throw + lint [E]) | `c45113ac` / `b89c9141` |
| `createErrorConsole` freeze-amplifier fixed; `invalidateLayout` guard log→throw | `4c78c9cb` |
| **C0** — inline re-fit triggers consolidated into the single seam | `c8bb8a87` |
| Slider Path-B de-read-back | `89ee825f` |
| Path-B window-fit de-read-back (`rawSetWidthSizeHeightAccordingly` returns its height) | `fa0d7961` |
| **C1** — seam defers PRIMARY changes; cascade stays synchronous via `world._reFittingContents` | `7ee0b871` |

### This session (2026-06-21) — the re-queue rollout
| What | commit |
|---|---|
| **C2 finding** — naive in-pass seam removal is a WALL; the deferred re-queue is the fix (docs) | `8deb1d55` |
| **Seam in-pass re-queue** — `_reFitContainerAfterRawGeometryChange` enqueues in a pass (the dominant ~99% case) | `5fc152c7` |
| **Twin in-pass re-queue** + the residuals audit | `7303fc5d` |
| **Menu/collapse/content-edit** — twin's outside-pass branch defers (invalidate the container) | `1caea690` |
| **Drag/drop** — gesture re-fits (`reactToDropOf`/`reactToGrabOf`/stack `childRemoved`) defer | `1e5d3745` |
| **Family-3 leftover** — the two `newParentChoice*` dev-menu re-fits defer (2-way; the high-value phase's final conversion) | `55c80ea6` |

### This session (2026-06-21 cont.) — THE CAPSTONE (counter retired)
| What | commit |
|---|---|
| **A-minimal proportion fix** — aspect content (`AnalogClockWdgt`/`IconWdgt`) `elasticity 0` ⇒ `getWidthInStack = min(wEl, availW)`, convergence-independent; 2 clock-resize tests recaptured | `a7463bbc` |
| **Defer the `WindowWdgt.add` pre-fit** + order-independent content-spec init (prior 164/165 HUGE-clock → 165/165) | `a7463bbc` |
| **Retire `world._reFittingContents`** — declaration + 3 `_reLayoutChildren` bumps removed; seam/twin/gesture/menu reads collapsed 3-way → deferred 2-state | `a7463bbc` |

**Net: every synchronous re-fit triggered by an IMMEDIATE MUTATOR or an ad-hoc gesture/menu/collapse handler now
defers.** The C2 "wall" was specifically the *naive* removal (stub the in-pass re-fit with no replacement → 7 tests
break, because the freefloating→container notification has no home); the re-queue is the replacement that converges
byte-identically. See `deferred-layout-c2-execution-plan.md` for the full finding + evidence.

## 5. What's left — the residuals campaign

`deferred-layout-residuals-audit.md` is the map, and it now records a **2026-06-21 reassessment** (a read-only mapping
Workflow + adversarial verification) of everything that was "next." **The campaign is COMPLETE — every synchronous
relayout that can defer WITHOUT cost now does; the last residual (soft-wrap, family 5) was PROBED and confirmed
LEAVE-SYNCHRONOUS (below).** Status of the 8 families (2–5 + the `newParentChoice*` leftover deferred; see §4):

- **Families 1 (scroll-input), 6 (Slider), 7 (LabelButton): assessed LEAVE SYNCHRONOUS — do NOT "fix".** Family 1 is
  the highest-determinism-risk residual (timer/momentum/known dpr2 scroll-thumb-flake path) for ZERO correctness gain,
  and is the wrong problem class (the panel adjusts its OWN contents — not a freefloating-child→container notification —
  so the re-queue machinery doesn't apply). Family 6 has no pattern surface (`SliderWdgt._reLayoutSelf` is the empty base
  no-op; the button _reLayoutSelf repositions only its own thumb). Family 7 is already compliant in substance (own-label
  re-center from a discrete menu action). None blocks the capstone (they're event/menu handlers, not immediate mutators).
- **`BoxWdgt.choiceOfWidgetToBePicked`: dead code** (`BoxWdgt` is never a `ScrollPanelWdgt` ancestor) — leave it.
- **Soft-wrap `_reLayoutSelf` (family 5): LEAVE SYNCHRONOUS — PROBED & rejected 2026-06-21.** Its prerequisite (making the
  Caret↔Text geometry read settle-correct so the re-wrap can defer) was tested by a disable-the-mechanism probe
  (neutralise the edit-time caret placement+scroll, rely on the existing paint-time `gotoSlot`): **7 tests red**, incl.
  the scroll-follow tripwires. ROOT CAUSE: `CaretWdgt.gotoSlot`'s `scrollCaretIntoView` MUTATES contents geometry that
  must settle IN-CYCLE (it runs at edit-time, before `recalculateLayouts`); deferring the caret read past the settle
  pass — REQUIRED to defer the re-wrap — can't re-settle it. A byte-exact alternative needs the `isLayoutDecoration`
  caret to participate in the settle loop (scroll re-dirties the panel mid-pass = freeze-class risk) for ZERO reward
  (no lint [E] unlock; caret already byte-correct; the re-wrap is already redundant with the deferred container re-fit).
  Full record: `softwrap-deferred-layout-conversion-plan.md` §5 (VERDICT + PROBE box).
- **The capstone — retire `world._reFittingContents`: ✅ ACHIEVED 2026-06-21 (full gauntlet dpr1/dpr2/WebKit + smoke +
  20-min torture soak green; net −14 lines, a SIMPLIFICATION).** The C2 wall was root-caused NOT to the geometry
  cascade per se but to the **stack-proportion model** — and specifically: the ONLY content whose width genuinely
  depends on the converged container width is **nested aspect-locked content (a clock in a window-in-window)**. THREE
  convergence-independent reformulations of the proportion FORMULA were each empirically FALSIFIED: (B) lazy GET-time
  capture broke the console fill (desyncs `wEl`/`wStk`); blanket-A and explicit-FILL/FIXED (A-refined) both broke the
  **base-width menu** (`macroSimpleDocumentCanAddIndentedParagraph`) and context-dependent text. So the stored
  `wEl/wStk` fraction is **irreducibly load-bearing** (it powers `setWidthOfElementWhenAdded`, `DONT_MIND` fill, and
  per-instance text). **The surgical fix (A-minimal):** give aspect content (clock/icon) **elasticity 0** (like
  `SliderWdgt`/`MenuWdgt` already do). At `e=0`, `getWidthInStack = min(wEl, availW)` — the `widthOfStackWhenAdded`
  term is multiplied out, so the clock is **convergence-independent with the rest of the proportion model UNTOUCHED**.
  Behaviour change (owner-approved): the in-window clock keeps its NATURAL size on resize instead of scaling
  proportionally (proportional scaling inherently needs the converged width — the irreducible part); recaptured the 2
  clock-resize tests (`macroWindowWithAClockInAWindowConstructionTwo`, `macroClockInWindowKeepsSquareOnResize`). With
  the clock fixed, the `WindowWdgt.add` pre-fit DEFERS and converges (prior **164/165 HUGE-clock → 165/165**), and the
  cross-widget geometry cascade converges through the **pure deferred re-queue** — so the counter is **RETIRED**
  (`WorldWdgt` declaration + the 3 `_reLayoutChildren` bumps removed; seam/twin/gesture/menu reads collapsed from 3-way
  to the deferred 2-state: enqueue in-pass / invalidate out-of-pass). **Part B (tighten lint [E]) — RESOLVED 2026-06-21
  (assessed → no lint to add).** The freeze vector Part B targeted — an immediate mutator triggering a CLIMB — was
  already eliminated by the capstone's deferred re-fit seam, which retired the synchronous `childGeometryChanged` climb
  arm; that now-orphaned method has been **deleted** (zero callers). The two `rawSetExtent→_reLayoutChildren` calls are
  TERMINAL single-container applies (no climb), identical in kind to the sanctioned `TextWdgt.rawSetExtent→_reLayoutSelf`;
  forbidding `_reLayoutChildren` by name was **declined as cosmetic** (it would force a DRY-breaking inline for zero real
  protection). Instead the two applies are marked sanctioned in code and lint [E]'s header documents the now-complete
  boundary. Full record: `deferred-layout-capstone-execution-plan.md` (RESULT-2 + Part B).
- **The last residual (PanelWdgt) — CLOSED 2026-06-22 (full gauntlet green; a SIMPLIFICATION).** The two off-settle
  synchronous `@parent._reLayoutChildren?()` calls that `deferred-layout-residuals-audit.md` flagged as a "verify-and-drop
  slice" are resolved: `PanelWdgt.addInPseudoRandomPosition`'s trailing re-fit was **DROPPED** as redundant — its
  `aWdgt.fullRawMoveTo` already fires `_reFitContainerAfterRawGeometryChange`, which invalidates the enclosing
  non-text-wrapping ScrollPanel (verified `BasementWdgt.scrollPanel` / `BasementOpenerWdgt` are plain `ScrollPanelWdgt`,
  so `_amIDirectlyInsideNonTextWrappingScrollPanelWdgt` holds); `PanelWdgt.childRemoved`'s was **CONVERTED** to the
  deferred 2-state seam (mirrors `reactToGrabOf` and the already-converted `SimpleVerticalStackPanelWdgt.childRemoved`).
  Net: every off-settle synchronous re-fit TRIGGER now defers; the only remaining synchronous `_reLayoutChildren` callers
  are APPLY bodies, the documented leave-synchronous families below, and the `ScrollPanelWdgt.add`/`addMany`/`showResize…`
  public ENDPOINTS (annotated in code as intentional applies, idempotent with the cycle; the only stricter form —
  routing through `settleLayoutsOnceAfter` — is byte-risky and zero-gain, see §11 PROOF 2).
  Verified: suite 165/165 at dpr1/dpr2/WebKit, smoke-apps 12/12, lint A–E 0, 20-min torture soak (dpr2·fastest·8-shard,
  15 runs / ~2,475 execs) ZERO nondeterminism.

**Left deliberately synchronous (correct, do not "fix"):** the above families 1/6/7;
`ScrollPanelWdgt._reLayOutAfterContainedPanelChange`/`_reLayoutChildrenAndScrollbars`
(absorb the return-value contract); `WindowWdgt.childUnCollapsed`'s `reInflating`-coupled re-fit; and the soft-wrap `_reLayoutSelf`
(assessed 2026-06-21 = leave-synchronous, blocked by a same-cycle caret read — `softwrap-deferred-layout-conversion-plan.md` §5).

## 6. The dead end (do not revive)

**Path A — "pending-aware accessors"** (add `effective*` reads that return where geometry is HEADING) is **FALSIFIED**.
A blanket version diverges (one accessor can't serve both pending-needers and the applied-needers: canvas buffers,
inspector, dirty-rects). The targeted container-path version is not just non-byte-safe but *incorrect*: `_positionAndResizeChildren`
bakes its size via the non-invalidating `silentRawSetBounds`, so reading pending bakes a mid-settle transient
(over-sized scroll content by 43px). The synchronous re-fit/convergence that re-reads APPLIED geometry is load-bearing.
→ `deferred-layout-path-a-design.md` §11.

## 7. Verification — the gauntlet (self-contained commands)

**Paths are absolute on purpose** (the Bash cwd resets to the umbrella `Fizzygum-all/` between calls — a bare
`./build_it_please.sh` silently fails and you then test a STALE build; see §8).

```sh
# Build (lint gate; expect "0 violations (A/B/C/D/E)" and a final "done!!!!!!!!!!!!")
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && ./build_it_please.sh
#   --keepTestsDirectoryAsIs   (faster while iterating; does NOT recopy tests)
#   VERIFY the build took: confirm "done!!!" printed, OR grep the artifact for a marker of your change:
#   grep -rl '<your unique edit string>' /Users/.../Fizzygum-builds/latest/js/coffeescript-sources/

# Full suite (165/165). Always pkill zombie browsers first. No `timeout` in this shell -> perl alarm.
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests \
  && pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"; sleep 1 \
  && perl -e 'alarm 600; exec @ARGV' node scripts/run-all-headless.js --shards=5
#   add --dpr=2   (HiDPI; the cadence-sensitive divergence point)
#   add --browser=webkit   (cross-engine; reuses the same SWCanvas references)

# App-launch smoke gate (MANDATORY for any layout-cycle change — the suite has no app coverage)
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/smoke-apps-headless.js   # -> "APPS OK"

# Torture soak (MANDATORY for cadence-sensitive changes, esp. anything in the transport/drag path).
# Heed the report's "build under test: ... ⚠ STALE (... is newer)" canary -> rebuild if you see it.
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests \
  && caffeinate -i node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=8 --minutes=20
#   verdict: cat .scratch/torture/REPORT.md  (empty failures/ dir = nothing flaked)

# Single test (debugging): node scripts/run-macro-test-headless.js SystemTest_<name>  (PRELUDE_JS=/LOG_FILE= to instrument)
# Recapture sanctioned benign shifts: node scripts/capture-macro-test-references.js SystemTest_<name> --clean --dprs=1,2
```

Determinism: SystemTests assert byte-exact SWCanvas pixels. A wrong conversion fails **deterministically** at dpr1
(stale geometry → red every run). Synchronous→deferred *timing* changes surface as **dpr2-under-load flakes** — that's
what the soak hunts. Read `../Fizzygum-tests/DETERMINISM.md` before touching the render/layout/input loop.

## 8. Gotchas (learned the hard way)

- **Stale builds are now structurally guarded (you don't have to remember).** `build_it_please.sh` self-locates
  (`cd "$(dirname "$0")"`) so cwd can't misdirect it, and it touches `Fizzygum-builds/latest/.build-stamp` ONLY on a
  successful completion. Every headless test runner (`run-all-headless` / `smoke-apps-headless` / `run-macro-test-headless`
  / `torture-headless`) calls `scripts/lib/assert-build-fresh.js` at startup and **REFUSES to run (exit 2, loud
  message) if any `src/**/*.coffee` is newer than the stamp, or the stamp is missing** — so a build that didn't run /
  failed / ran from the wrong cwd can never be tested as if fresh. Deliberate override: `FIZZYGUM_ALLOW_STALE_BUILD=1`.
  (Still prefer `cd /abs/.../Fizzygum && ./build_it_please.sh`, or the pre-baked `./build_and_test.sh` / `./build_and_smoke.sh`
  which self-locate and build-then-test.)
- **Separate `cd` per repo** (chaining build in `Fizzygum/` + node in `Fizzygum-tests/` → MODULE_NOT_FOUND).
- **No `timeout` in this shell** — use `perl -e 'alarm N; exec @ARGV' node …`.
- **pkill zombie browsers** before every suite/soak run (they starve the box and cause infra hiccups).
- **Commit via `git commit -F <file>`** — never backticks/`$()` in `-m` (bash command-substitutes them). **Ask before
  commit/push** (review-driven project).
- **Adding a method to base `Widget` recaptures the inspector test** (`macroDuplicatedInspectorDrivesCopiedTargetOnly`
  — it lists `@target`'s inherited members). The re-queue closures are duplicated INLINE per seam precisely to avoid
  this; do the same, or accept the (sanctioned, benign) recapture.
- **`nil` means `undefined`.** Edit only `src/**/*.coffee`; never `../Fizzygum-builds/**` (regenerated each build).

## 9. Doc map (what each doc is)

- **`deferred-layout-OVERVIEW.md`** — THIS doc (the self-contained entry point).
- **`deferred-layout-residuals-audit.md`** — the campaign MAP: the ~40 remaining synchronous relayouts in 8 families,
  what's done vs left, the suggested order, the leave-synchronous list, the hazards. **Live.**
- **`deferred-layout-c2-execution-plan.md`** — the C2 arc RECORD: the DAG model of the clock/window cascade, the
  feasibility-probe finding (naive removal is a wall), and the shipped deferred re-queue. **Live (reference).**
- **`deferred-layout-capstone-execution-plan.md`** — the CAPSTONE arc: the slice plan to retire `world._reFittingContents`
  + tighten lint [E], the EXECUTION RESULT (slice 1 hit the C2 cross-widget-convergence wall — the `rememberInitialDimensions`
  stale-read drift), and **the NEXT STEP toward the all-deferred aim** (de-read-back the cross-widget sizing → idempotent
  re-fit). **Live (the forward path).**
- **`softwrap-deferred-layout-conversion-plan.md`** — the originating soft-wrap case + the "model is intermediate"
  finding + the Path-A/B taxonomy + the C0–C3 inline-trigger arc history (§6b). **Reference. Soft-wrap was the last
  open family; §5's VERDICT (2026-06-21) = LEAVE SYNCHRONOUS (proof inline).**
- **`deferred-layout-path-a-design.md`** — Path A (pending-aware accessors), **FALSIFIED** — §11 is the instrumented
  why-it-fails. **Historical (do not revive).**
- **`deferred-layout-slice2-completion-plan.md`** — state after Phase 3b + the flow rule; the full gauntlet commands.
  **Historical.**
- **`deferred-layout-refit-and-add-design.md`** — the Phase-1 design-of-record (re-fit chokepoint + public `add`).
  **Historical.**
- **`deferred-layout-16-macro-breakages.md`** — the 16 construction-macro breakages catalogue (fixed by the
  self-settling API). **Historical.**

## 10. Key code locations (approx. as of `1e5d3745` — grep the method name, it's authoritative)
- `src/basic-widgets/Widget.coffee`: `rawSetWidthSizeHeightAccordingly` ~:706 · `mutateGeometryThenSettle` ~:748 ·
  `settleLayoutsOnceAfter` ~:795 · `fullRawMoveBy` ~:1220 · `rawSetExtent` ~:1520 · `silentRawSetExtent` ~:1566 ·
  twin `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` ~:1606 · seam `_reFitContainerAfterRawGeometryChange` ~:1659 ·
  `invalidateLayout` ~:3791 (mid-pass throw ~:3804; freefloating-doesn't-climb ~:3808). Accessors read `@bounds`.
- `src/WorldWdgt.coffee`: `recalculateLayouts` ~:863 / `_recalculateLayoutsCore` ~:876 (until-loop ~:885; the walk-up
  that STOPS at freefloating ~:925). (`world._reFittingContents` was RETIRED by the capstone — §4/§5.)
- `src/basic-widgets/ScrollPanelWdgt.coffee`: `_reLayoutChildren` ~:262 · `_reLayout`
  (`super; @_reLayoutChildren`) ~:276 · gesture seams `reactToDropOf` ~:245 / `reactToGrabOf` ~:251 · the public-endpoint
  applies `add`/`addMany`/`showResizeAndMoveHandlesAndLayoutAdjusters` ~:196/202/207 (intentional synchronous APPLY — §11 PROOF 2; the stricter `settleLayoutsOnceAfter` form is byte-risky/zero-gain).
- `src/SimpleVerticalStackPanelWdgt.coffee`: `_reLayoutChildren` ~:54 · `_reLayout` ~:70 · `childRemoved` (deferred 2-state).
  Plus `src/basic-widgets/PanelWdgt.coffee` (`childRemoved` deferred 2-state ~:93 + `reactToDropOf`/`reactToGrabOf`;
  `addInPseudoRandomPosition` ~:112 defers via the geometry seam, no own re-fit) + `src/WindowWdgt.coffee`
  (`_reLayoutChildren` ~:194). (`childGeometryChanged` was DELETED by the capstone — §5.)

## 11. Why the boundary is maximal — the SCHEDULE/APPLY classifier + the irreducibility proof

**This section makes "COMPLETE" AUDITABLE: it is the classifier of every layout-APPLY call site + the proof that the
remaining synchronous applies CANNOT defer.** A read-only census (2026-06-22) bucketed every runtime apply call
(`_reLayout`/`_reLayoutSelf`/`_reLayoutChildren`/`_positionAndResizeChildren`/`_reLayoutScrollbars`/`recalculateLayouts`) under
`src/` (~142 sites; counts approximate — the bucket BOUNDARIES are the point, not the tallies; re-derive via grep):

| Bucket | ~n | what it is | representative | verdict |
|---|---|---|---|---|
| CYCLE-APPLY | 73 | the until-loop + every container/widget `_reLayout`·`_adjust*` body + child fan-outs | `WorldWdgt._recalculateLayoutsCore:927` | settle point ✓ |
| PUBLIC-FLUSH | 2 | the self-settling flush wrappers | `Widget.mutateGeometryThenSettle:783` | settle point ✓ |
| DEFERRED-SEAM | 11 | in-pass arms (run only under `_recalculatingLayouts`) | `ScrollPanelWdgt.reactToDropOf:252` | already deferred ✓ |
| TERMINAL-RAW-APPLY | 33 | `raw*`/`fullRaw*`/`iHaveBeenAddedTo` → `_reLayoutSelf`/`_reLayout`/`_reLayoutChildren` | `TextWdgt.rawSetExtent:428` | **IRREDUCIBLE** (PROOF 1) |
| SCROLL-INPUT-APPLY | 18 | scroll handlers adjusting their OWN contents | `ScrollPanelWdgt.wheel:737` | LEAVE (family 1) |
| CONSTRUCTION/DEV | 9 | constructors / `WidgetFactory` / live-edit | `WidgetFactory.createNewScrollPanelWdgt:42` | not steady-state |
| SUSPICIOUS | 2 | `BoxWdgt.choiceOfWidgetToBePicked:21-22` | dead (`BoxWdgt` ⊄ `ScrollPanelWdgt`) → DELETED 2026-06-22 |

**THE MAXIMAL INVARIANT (what "complete" means, precisely):**
> Off-settle code may request layout only by RECORDING INTENT (`invalidateLayout`, or `@desired*`-then-flush). A layout
> APPLY runs synchronously only at: (a) the cycle, (b) a public flush, (c) a raw-mutator TERMINAL self-apply
> (irreducible — PROOF 1), (d) a deferred-seam in-pass arm (already under `_recalculatingLayouts`), or (e) a documented
> determinism-exempt family (scroll-input / Slider / LabelButton / soft-wrap / collapse-`reInflating`). **This is the
> MAXIMAL achievable invariant — the strict "no apply outside `recalculateLayouts`/flush" is UNACHIEVABLE for (c).**

Build-gated by **lint [F]** (`buildSystem/check-layering.js`): a non-low-level, non-immediate-mutator method that calls
a container APPLY (`_reLayoutChildren`/`_positionAndResizeChildren`/`_reLayoutScrollbars`/`_reLayout`) must DEFER or carry a
conscious `# layout-apply-sanctioned: <why>` marker. (Cases (a)/(b)/(c) are already exempt via
`isLowLevel||isImmediateMutator`; (d)/(e) carry markers. `_reLayoutSelf` is OUT of [F]'s scope by design — it is a SELF-apply
(own text re-wrap / own thumb / own label), not the freefloating-child→container regression class [F] guards.)

### PROOF 1 — the terminal raw applies cannot defer (so (c) is irreducible)
`rawSetExtent → @_reLayoutSelf()` / `rawSetWidthSizeHeightAccordingly → @_reLayout()` cannot become a deferred SCHEDULE:
(i) raw setters run DURING passes, where `invalidateLayout` THROWS; (ii) the calling pass reads the apply's result back
**in the same pass**; (iii) the only mechanism that would let a deferred read see the heading value is Path A — FALSIFIED
(§6). The decisive same-pass read-back is in the hot container path: `SimpleVerticalStackPanelWdgt._positionAndResizeChildren`
calls `widget.rawSetWidthSizeHeightAccordingly recommendedElementWidth` (~:145) then reads `widget.height()` back to
accumulate `stackHeight` (~:164) and bakes it via `@rawSetHeight` (~:171). Defer the apply ⇒ stale read ⇒ wrong stack
height. (Same shape: `ScrollPanelWdgt._positionAndResizeChildren` ~:335 re `TextWdgt.rawSetExtent→_reLayoutSelf`.) No clean
counterexample (checked `rawSetWidthSizeHeightAccordingly` Widget.coffee:706, the `Stretchable*` overrides,
`ContainerMixin.adjustBounds`).

### PROOF 2 — `ScrollPanelWdgt.add`/`addMany`/`showResize…` correctly stay synchronous APPLIES
A bare two-arm swap (the `reactToDropOf` idiom) is UNSAFE for `add`: (i) `add` passes `ATTACHEDAS_FREEFLOATING`, so
`_addCore`'s climb-invalidate (Widget.coffee ~:2454) is SKIPPED and the freefloating child does not climb — the inner
`@contents.add` self-settle drains a queue the panel was **never enqueued into**, so only the trailing synchronous
`@_reLayoutChildren()` re-fits it; (ii) the dominant caller is ORPHAN construction (`SimpleDocumentWdgt.spawnContents`
~:78-86: `setContents`→`add`→`_reLayoutChildren` before the panel is added to the world), where the inner add hits
`mutateGeometryThenSettle`'s orphan guard (no flush) and the synchronous re-fit is the only thing establishing geometry.
The seams may defer only because `ActivePointerWdgt.drop`/`grab` guarantee a same-cycle settle; `add` has none. The sole
consistency-preserving stricter form (wrap in `settleLayoutsOnceAfter` + keep a synchronous orphan re-fit, because
`settleLayoutsOnceAfter` skips the orphan flush) is byte-risky (reorders content-settle vs panel-refit in one drain) and
zero-gain. **Phase-4 EMPIRICAL RESULT (2026-06-22): PROBED and REJECTED — the question is now closed by attempt, not
just argument.** The `settleLayoutsOnceAfter` form (with a synchronous orphan re-fit, since the batch flush is skipped
for orphans) COMPILED, passed lint [F], and did NOT break construction (boot/smoke fine, `completed:true`) — but it
**deterministically diverged the nested-scroll content/thumb geometry at dpr1**: `macroNestedScrollPanelsRouteWheel`
(3 frames) + `macroDocumentScrollsMixedTextAndClocks` — the exact thumb-proportion hazard named above (a §11/Path-A
casualty). So the synchronous re-fit's re-read of APPLIED geometry IS load-bearing for nested-scroll content sizing:
deferring it to the batch flush reorders content-settle vs panel-refit and changes the *converged* geometry, for ZERO
correctness gain. **BACKED OUT** — the endpoints stay synchronous, with a code breadcrumb at `ScrollPanelWdgt.add`
recording the probe so it is not re-attempted. This empirically confirms PROOF 2 and the original "leave synchronous"
decision.
