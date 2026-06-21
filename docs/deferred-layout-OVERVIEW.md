# Deferred-layout: OVERVIEW — aim, model, mechanism, state, what's next

**Read this first — it is the self-contained entry point for the whole deferred-layout effort.** You should be
able to pick the work up cold from this one doc. The other docs (§9 Doc map) are detail/history. Last updated
2026-06-21.

**master:** Fizzygum **`55c80ea6`** / Fizzygum-tests **`6785d94ad`** — all green (suite 165/165 at dpr1+dpr2+WebKit,
smoke-apps 12/12, lint A–E 0). The high-value deferred-layout phase is **COMPLETE** (see §5 — the campaign is at a
natural stop-and-report point: the remaining families are deliberately left synchronous or are the last+blocked capstone).

> **This doc is canonical — it supersedes every other deferred-layout doc on any conflict.** Line numbers below are
> **approximate (as of `55c80ea6`) — the METHOD NAME is authoritative; `grep` it.** (Each shipped edit shifts lines.)

---

## 1. The aim

**Turn EVERY synchronous re-layout into a DEFERRED one.** A relayout (a `doLayout`/`reLayout`/container `_reFitToContents`)
must run at exactly one of two SETTLE POINTS, never mid-handler and never from a low-level mutator:

- **(a) the end of a geometry-changing PUBLIC method** — the self-settling flush `Widget.mutateGeometryThenSettle`
  (records intent, then runs `recalculateLayouts`); *modulo batching*, where a batch settles once via
  `settleLayoutsOnceAfter`; or
- **(b) the end of `doOneCycle`** — the `recalculateLayouts → doLayout` pass that runs before paint.

Low-level mutators (`raw*`/`silent*`/`fullRaw*`) must only MUTATE geometry, never schedule/run layout.

## 2. The model (how deferred layout already works)

- **Public geometry setters self-settle.** The 7 public mutators — `setExtent`, `setWidth`, `setHeight`,
  `setBounds`, `fullMoveTo`, `add`, `addRaw` (all in `src/basic-widgets/Widget.coffee`) — wrap
  `mutateGeometryThenSettle`: they record desired state (`@desiredExtent`/`@desiredPosition` + `@invalidateLayout()`)
  and then run `world.recalculateLayouts()` once before returning. So a top-level caller always sees a consistent
  world; deferral is **within-frame** (no cross-frame lag).
- **The until-loop is the single settle engine.** `WorldWdgt._recalculateLayoutsCore` (`src/WorldWdgt.coffee`
  ~:876, the loop ~:885) drains `world.widgetsThatMaybeChangedLayout`, calling `doLayout()` on the top-most invalid
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
# own _adjustContentsBounds (it is driving this child top-down and already accounts for it -- enqueuing
# then would re-fire every pass and never converge).
enqueueReFitDuringPass = (container) ->
  return unless container?._reFitToContents?
  return if container._adjustingContentsBounds
  if container.layoutIsValid
    world.widgetsThatMaybeChangedLayout.push container
  container.layoutIsValid = false
```

Because every container's `doLayout` is `super; @_reFitToContents()` (ScrollPanelWdgt ~:276, SimpleVerticalStackPanelWdgt ~:70,
WindowWdgt inherits), **enqueuing a container makes the until-loop re-fit it on the same cycle, identically.**

The seams + their conversion state (all in `Widget.coffee` unless noted):

| Seam | fired from | shape now |
|---|---|---|
| `_reFitContainerAfterRawGeometryChange` (~:1659) | the immediate mutators `silentRawSetExtent` (~:1566) + `fullRawMoveBy` (~:1220) | **3-way**: `_recalculatingLayouts` → enqueue · `_reFittingContents` → synchronous · else → `invalidateLayout` |
| `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (~:1606) | property setters (`VerticalStackLayoutSpec` align/elasticity/base-width), collapse, content-edit/soft-wrap | **3-way** (same) |
| `reactToDropOf`/`reactToGrabOf` (ScrollPanelWdgt/PanelWdgt/SimpleVerticalStackPanelWdgt) + the stack's `childRemoved` | `ActivePointerWdgt.drop`/`grab` (after a self-settling `add`) | **2-way**: pass/cascade → synchronous · else → `invalidateLayout` (no recalc-enqueue arm — these are never dispatched mid-pass) |

**`world._reFittingContents`** (`WorldWdgt.coffee:277`) is a COUNTER, bumped inside each container `_reFitToContents`
(ScrollPanelWdgt ~:258, SimpleVerticalStackPanelWdgt ~:54, WindowWdgt ~:194). It marks "inside a cross-widget re-fit
cascade" (e.g. clock ↔ inner-window ↔ outer-window). Inside such a cascade the seams stay **synchronous** so the
cascade completes/iterates within the public op; only a PRIMARY change outside it defers. This is what made deferral
sound where a naive blanket deferral was not.

**Path-B de-read-back** is the companion technique for constraint handlers: instead of mutate-then-read-geometry-back,
the mutator HANDS its result forward. `rawSetWidthSizeHeightAccordingly` RETURNS its resulting height (base
`Widget.coffee:706` + 8 overrides); `WindowWdgt._adjustContentsBounds` uses the return instead of reading
`@contents.height()` back. (`SliderWdgt.updateValue` was the pilot.)

## 4. What's shipped

### Pre-session foundation (all on master)
| What | commit |
|---|---|
| Self-settling public geometry API (`mutateGeometryThenSettle`) | `817c2ce4` |
| Re-fit chokepoint `_reFitToContents` + lint A/B/C/D | `ad2000cc` |
| `add`/`addRaw` public & self-settling over private `_addCore` | `b8165920` |
| Stack/window content re-fit on the `doLayout` cycle (Phase 3b) | `00cea256` / `6c7060e5` |
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

**Net: every synchronous re-fit triggered by an IMMEDIATE MUTATOR or an ad-hoc gesture/menu/collapse handler now
defers.** The C2 "wall" was specifically the *naive* removal (stub the in-pass re-fit with no replacement → 7 tests
break, because the freefloating→container notification has no home); the re-queue is the replacement that converges
byte-identically. See `deferred-layout-c2-execution-plan.md` for the full finding + evidence.

## 5. What's left — the residuals campaign

`deferred-layout-residuals-audit.md` is the map, and it now records a **2026-06-21 reassessment** (a read-only mapping
Workflow + adversarial verification) of everything that was "next." **The high-value phase is COMPLETE — the campaign
is at a natural stop-and-report point.** Status of the 8 families (2–5 + the `newParentChoice*` leftover deferred; see §4):

- **Families 1 (scroll-input), 6 (Slider), 7 (LabelButton): assessed LEAVE SYNCHRONOUS — do NOT "fix".** Family 1 is
  the highest-determinism-risk residual (timer/momentum/known dpr2 scroll-thumb-flake path) for ZERO correctness gain,
  and is the wrong problem class (the panel adjusts its OWN contents — not a freefloating-child→container notification —
  so the re-queue machinery doesn't apply). Family 6 has no pattern surface (`SliderWdgt.reLayout` is the empty base
  no-op; the button reLayout repositions only its own thumb). Family 7 is already compliant in substance (own-label
  re-center from a discrete menu action). None blocks the capstone (they're event/menu handlers, not immediate mutators).
- **`BoxWdgt.choiceOfWidgetToBePicked`: dead code** (`BoxWdgt` is never a `ScrollPanelWdgt` ancestor) — leave it.
- **Soft-wrap `reLayout` (family 5): assessed 2026-06-21 = LEAVE SYNCHRONOUS.** The one byte-safe slice (a redundant
  re-wrap in a text-wrapping scroll panel) is blocked by a same-cycle caret geometry read (`CaretWdgt.insert`
  `setText`→`gotoSlot`→`slotCoordinates`); the other sites are load-bearing/non-redundant; a `TextWdgt.doLayout` is a
  no-go; and deferral wins NO lint [E] (co-gated on family-8). Full closure is a large owner-gated sub-arc.
  `softwrap-deferred-layout-conversion-plan.md` §5 VERDICT.
- **The capstone — retire `world._reFittingContents` + tighten lint [E]: ATTEMPTED 2026-06-21, BLOCKED at the C2
  cross-widget-convergence wall (reverted to clean).** Slice 1 (defer the `WindowWdgt.add` pre-fit) was executed: after
  fixing two init-ordering null-derefs it reached 164/165, but `macroWindowWithAClockInAWindowConstructionTwo` renders
  the nested aspect-locked clock HUGE because the cross-widget cascade **DRIFTS +1px/frame under deferral instead of
  converging** — root-caused to a stale geometry read-back: `VerticalStackLayoutSpec.rememberInitialDimensions` reads a
  stale `availableWidthInStack` and records the clock as stretchy (`elasticity=1`). So the counter / the synchronous
  pre-fit is doing **real load-bearing convergence work** (the synchronous cascade iterates to a fixed point in one
  frame; the deferred re-queue, one re-fit/frame, drifts because the re-fit is not idempotent). Part B (lint) is
  separately **cosmetic** (it would forbid a `rawSetExtent→_reFitToContents` apply identical to the sanctioned family-8
  `rawSetExtent→reLayout`). **NEXT STEP toward the all-deferred aim (the prerequisite): make the cross-widget
  window-content re-fit READ-BACK-FREE / idempotent** — a Path-B de-read-back of the stack-proportion + window-fit
  sizing model (find the +1px drift source first), after which the deferred re-queue converges and the counter can be
  retired. Full mechanism + the next-step arc: `deferred-layout-capstone-execution-plan.md` (RESULT banner).

**Left deliberately synchronous (correct, do not "fix"):** the above families 1/6/7; `SimpleVerticalStackPanelWdgt.childGeometryChanged`
(the cascade SINK the seams call); `ScrollPanelWdgt.reLayOutAfterContainedPanelChange`/`_refitContentsAndScrollBars`
(absorb the return-value contract); `WindowWdgt.childUnCollapsed`'s `reInflating`-coupled re-fit; and the soft-wrap `reLayout`
(assessed 2026-06-21 = leave-synchronous, blocked by a same-cycle caret read — `softwrap-deferred-layout-conversion-plan.md` §5).

## 6. The dead end (do not revive)

**Path A — "pending-aware accessors"** (add `effective*` reads that return where geometry is HEADING) is **FALSIFIED**.
A blanket version diverges (one accessor can't serve both pending-needers and the applied-needers: canvas buffers,
inspector, dirty-rects). The targeted container-path version is not just non-byte-safe but *incorrect*: `_adjustContentsBounds`
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
  that STOPS at freefloating ~:925); `world._reFittingContents` :277.
- `src/basic-widgets/ScrollPanelWdgt.coffee`: `_reFitToContents` ~:258 (bumps `_reFittingContents`) · `doLayout`
  (`super; @_reFitToContents`) ~:276 · gesture seams `reactToDropOf` ~:241 / `reactToGrabOf` ~:247.
- `src/SimpleVerticalStackPanelWdgt.coffee`: `_reFitToContents` ~:54 · `doLayout` ~:70 · `childGeometryChanged` (the
  cascade SINK — left synchronous). Plus `src/basic-widgets/PanelWdgt.coffee` + `src/WindowWdgt.coffee` (`_reFitToContents` ~:194).
