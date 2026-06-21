# True C2 — converge the container re-fit cascade IN-PASS, remove the synchronous seam

> Execution plan (durable copy of the owner-approved plan, 2026-06-20). Entry point:
> `deferred-layout-OVERVIEW.md`. Companion docs: `deferred-layout-path-a-design.md` (§11 Path-A falsified),
> `softwrap-deferred-layout-conversion-plan.md` (§6b the C0–C3 arc).

## RESULT — the NAIVE seam removal is a wall, BUT the DEFERRED RE-QUEUE WORKS and is SHIPPED (2026-06-21). (Plan below is the record.)

**The Phase-1 feasibility probe (the decision gate) returned a hard NO.** Stubbing the seam's IN-PASS/cascade
synchronous re-fire to a no-op (keeping the outside-pass `invalidateLayout` arm; build green, lint 0) broke **7
SystemTests** across ALL THREE families — so the in-pass re-fire is NOT redundant; it is load-bearing for in-pass
convergence:
- **Scroll/REACT arm (5):** `macroScrollBarsTrackContentChange`, `macroNoSpuriousScrollbarsOnScrollPanelResize`,
  `macroEditingStringInScrollablePanelCaretAlwaysVisible`, `macroScrollPanelCaretBroughtIntoViewWhenMoved`,
  `macroScrollPanelNotMovedViaNonFloatDragChild`.
- **Stack/window arm (2):** `macroWindowWithAClockInAWindowConstructionTwo` (cross-widget),
  `macroWindowWithSimpleVerticalPanelResizesAsContentChanges` (DRIVE).

**Concrete failure mode (clock test, dumped):** after the clock drops, the clock is sized to the full available
WIDTH (huge, overflowing/clipped by the inner window) and the windows never re-fit to center the square; images
4-6 share ONE dataHash (the subsequent resizes are inert — no re-fit notification). I.e. the cascade does NOT
converge without the in-pass re-fire.

**Root cause — the freefloating-child→container notification has no clean deferred home.** A freefloating content
widget (scroll content / window content / clock) changes its OWN geometry via internal raw/silent mutators
(text re-wrap, slider thumb, clock square, drop). Its container must re-fit. But: (a) a freefloating child's
`invalidateLayout` does NOT climb to its container (`Widget.coffee:3756`); (b) the `recalculateLayouts` until-loop's
walk-up DELIBERATELY stops at freefloating widgets (`WorldWdgt.coffee:924-927` + the TODO at :907-922), so the loop
never re-fits a container in response to a freefloating child; (c) `invalidateLayout` THROWS mid-pass (the
flow-rule guard, `Widget.coffee:3751`). So SOMETHING must explicitly notify the container — that something is the
seam. Every alternative either keeps the immediate-mutator trigger (a mid-pass enqueue of the container — still
"an immediate mutator schedules layout", so NO lint/enforcement payoff; and it's erased by the container's own
`markLayoutAsFixed` when the change is top-down-driven) or requires converting the internal raw mutators to public
deferred setters (infeasible — they run inside layout passes where public setters re-enter `recalculateLayouts`
and throw).

**The premise of the recommended one-shot constraint solve is FALSIFIED.** It assumed fixing the clock's cross-
widget cascade would let the seam's cascade arm be removed → C3. But the probe shows the **scroll/REACT arm breaks
INDEPENDENTLY of the clock** (5 scroll tests, no clock involved). So even a perfect clock one-shot-solve cannot
enable C3 — the seam stays for the scroll arm → no enforcement payoff. (This re-grounds, with hard evidence, the
older softwrap §6b.1 "scroll/REACT arm stays synchronous → C3 unachievable" conclusion that had been marked
SUPERSEDED after C1/Path-B; the "superseded" was over-optimistic — it only held for the OUTSIDE-pass case.)

**The reframe that makes this the correct end state.** The in-pass seam re-fit happens DURING `recalculateLayouts`
(within `doOneCycle`, before paint) — instrumented at ~99% `recalc=true`; the remaining ~1% run inside a PUBLIC
operation's synchronous settle (add/drop). Both are exactly the two aim-sanctioned settle points ("end of a public
method" / "end of `doOneCycle`"). So the in-pass seam already SATISFIES the overarching aim — it is NOT a
mid-handler, out-of-band synchronous re-layout. The one case that WAS out-of-band (a primary geometry change
outside any pass) is exactly what **C1 already deferred**. The seam is a legitimate part of the settle pass and
should remain.

**SCOPE OF THE WALL: it is the NAIVE NO-OP removal that is a wall — not in-pass convergence per se.** The probe
removed the in-pass re-fire *with no replacement*. That obviously can't converge (nothing notifies the container).
What C2 always called for is an in-pass CONVERGENCE MECHANISM; the probe only ruled out "no mechanism."

## SHIPPED — the DEFERRED RE-QUEUE (the in-pass cascade arm, now deferred)

The aim is for every relayout to run at a settle point (end of `doOneCycle` / end of a public method), driven by
the `recalculateLayouts` until-loop — not synchronously inside an immediate mutator. The in-pass cascade arm of the
seam was the dominant synchronous relayout (~99% of cascade re-fits). It is now DEFERRED:

**Replace the seam's synchronous in-pass re-fit with a mid-pass-legal RE-QUEUE into the until-loop.** When a
freefloating content widget changes geometry mid-pass, instead of `@parent…_reFitToContents()` / `childGeometryChanged()`
(which run `_adjustContentsBounds` NOW), *enqueue* the container for the until-loop: `container.layoutIsValid = false;
world.widgetsThatMaybeChangedLayout.push container` — a sanctioned enqueue that does NOT throw and does NOT climb
(distinct from `invalidateLayout`, whose throw + climb guards the Slice-2 freeze). The until-loop then re-fits the
container LATER in the same pass. This moves the relayout from "synchronous, inside the mutator" to "deferred,
driven by the until-loop" = the aim.

Why it is plausible (vs the no-op): the container gets a re-fit, just deferred to the loop, so convergence is
preserved. The two things to verify (the reason it's an experiment, not a done deal):
1. **Convergence + termination.** The re-fit re-sizes the content, which may re-enqueue the container → must reach a
   fixed point. The cascade is a DAG (this doc's model), so it should; the scroll panel reacts to a settled
   `subWidgetsMergedFullBounds` → fixed point once content is stable. Backstop: the `recalcIterationsCap` (WorldWdgt:882).
2. **The `markLayoutAsFixed` erase + byte-identity under load.** Enqueuing the container DURING its own doLayout
   (the top-down-driven case) is erased by its trailing `markLayoutAsFixed` — benign there (it already accounted for
   the child via the Path-B return). For the bottom-up case (content re-lays-out during ITS own doLayout, container
   not mid-fit) the enqueue survives → loop re-fits. The FINAL settled pixels should be identical (screenshots are
   taken post-`waitNoInputsOngoing`), but the changed ordering is determinism-sensitive → **the torture soak is
   mandatory** before believing it.

If the re-queue converges byte-identically across the full gauntlet + soak, the seam (and its twin
`_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`) can be removed and lint [E] tightened = C3 = the aim met. If it
does NOT converge (or diverges under load), THAT is the deeper wall: the until-loop's freefloating-content handling
(the walk-up that stops at freefloating, WorldWdgt:924-927) would itself need reworking — a much larger,
determinism-core change to weigh separately.

**SHIPPED 2026-06-21 (`Widget._reFitContainerAfterRawGeometryChange`).** Implemented exactly as above: in a layout
pass (`world._recalculatingLayouts`) the seam now enqueues the affected container(s) via a local closure
(`enqueueReFitDuringPass` — guards `_reFitToContents?` + skips a container mid-`_adjustContentsBounds`, then
`layoutIsValid=false` + push `widgetsThatMaybeChangedLayout`; no throw, no climb). The `_reFittingContents`-only
(public-op/drop settle, not a pass) branch keeps the synchronous re-fit (aim-sanctioned: end of a public method);
the outside-both branch keeps the C1 `invalidateLayout` defer. Used a local closure (not a new method) so NO class
member is added → byte-identical, zero recaptures.

**Verification:** all 7 probe-failing tests now PASS; suite **165/165 at dpr1, dpr2, AND WebKit**; smoke-apps OK;
lint 0; byte-identical (no recapture). **Soak: SHORT — 3 runs / ~495 execs at dpr2-fastest-s8, 0 flaky, stopped
early at the owner's request** (the standard ≥20-min / ~1,900-exec soak was NOT completed; a full soak is advisable
when convenient, since this reorders synchronous→deferred and is the determinism-sensitive class).

**Twin SHIPPED too (2026-06-21).** `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (Widget:1602) got the same
in-pass re-queue (its outside-pass branch — reached from menu/edit/collapse handlers — stays synchronous, a public-
method settle). Verified: 165/165 dpr1+dpr2+WebKit, smoke-apps OK, byte-identical; soak 6 runs ~990 execs 0 flaky.

**Remaining toward the all-deferred aim — see `deferred-layout-residuals-audit.md`** (a full inventory of the ~40
synchronous relayouts still at non-flush points). In brief: scroll-input handlers (wheel/momentum/autoScroll/caret/
scrollbar), drag/drop re-fit cascades (reactToDropOf/reactToGrabOf), menu actions (alignment/elasticity/parent-choice),
collapse/uncollapse, content-edit/soft-wrap, the Slider/LabelButton reLayout family, and the structural root
`rawSetExtent`→`reLayout` (a `raw*` setter that runs layout). Each is a separate determinism-sensitive arc (own soak);
lint [E] can only tighten once the seam's public-op branch + the twin's outside-pass branch are also converted.

---

## Context (why this, why now)

**The overall aim:** turn EVERY synchronous re-layout in Fizzygum into a DEFERRED one — settling at exactly
one of two points: the end of a geometry-changing PUBLIC method (the `mutateGeometryThenSettle` flush, modulo
batching), or the end of `doOneCycle` (the `recalculateLayouts → doLayout` pass before paint). The last
synchronous re-layout left is the container re-fit **seam** `Widget._reFitContainerAfterRawGeometryChange`
(src/basic-widgets/Widget.coffee:1628). Removing it (C3) + tightening lint [E] is the end state.

**Where the arc stands** (all on master, Fizzygum `7ee0b871` / Fizzygum-tests `544166856`, both clean+synced):
- **C0** (`c8bb8a87`): the two inline immediate-mutator re-fit triggers collapsed into the single seam.
- **Path-B window-fit de-read-back** (`fa0d7961`): `rawSetWidthSizeHeightAccordingly` now RETURNS its resulting
  height (base Widget:706 + 8 overrides); `WindowWdgt._adjustContentsBounds` takes the return instead of reading
  `@contents.height()` back. (Path A — pending-aware container reads — is FALSIFIED, path-a-design §11: it bakes
  a mid-settle transient via the non-invalidating `silentRawSetBounds`; the synchronous re-fit/convergence that
  re-reads APPLIED geometry is load-bearing. Do NOT revive it.)
- **C1** (`7ee0b871`): the seam DEFERS a PRIMARY geometry change (outside any pass/cascade → `invalidateLayout`,
  re-fit on the next cycle) but stays SYNCHRONOUS inside a re-fit cascade, gated by a world counter
  `world._reFittingContents` (WorldWdgt:277; bumped around each container `_reFitToContents`). This is C1 done —
  NOT C3: the cascade arm is still synchronous, so the seam isn't removed.

**True C2 = make the in-pass cascade converge WITHOUT the seam's synchronous in-pass re-fire**, so the seam's
cascade arm can be removed → then C3 deletes the seam (+ its twin, see below) + tightens lint [E].

## Verified baseline (start of this arc)

- Build green (`0 violations (A/B/C/D/E)`, syntax 0 errors); suite **dpr1 165/165 failed 0**; smoke-apps **APPS OK**.
- All documented facts re-confirmed in code: the seam's three-state gate (Widget.coffee:1628-1636); the counter
  + 3 `_reFitToContents` wraps (ScrollPanelWdgt:246, SimpleVerticalStackPanelWdgt:54, WindowWdgt:194);
  `rawSetWidthSizeHeightAccordingly` base + 8 overrides return height; `WindowWdgt._adjustContentsBounds`
  branches (contentNeverSetInPlaceYet :475-490 clamps `if !@recursivelyAttachedAsFreeFloating()`; content-already-
  there :494-500 clamps only `if @contentsRecursivelyCanSetHeightFreely()` — FALSE for the clock).

## The model (evidence-backed — instrumented, `macroWindowWithAClockInAWindowConstructionTwo`)

Topology: extWin (free-floating, resize-handle) → content=intWin (WindowWdgt) → content=clock (square,
`canSetHeightFreely=false`). `WindowWdgt extends SimpleVerticalStackPanelWdgt`; `availableWidthForContents = @width()-2·padding`.

1. **The cascade is a DAG, not a cycle.** Width flows strictly DOWN (extWin.width → intWin.width via
   `getWidthInStack` → clock.width via `getWidthInStack`); height flows strictly UP (clock `height=width` →
   `intWin.newHeight = stackHeight+chrome` → extWin likewise, WindowWdgt:521-523). The window ALWAYS auto-fits
   its own height to content. The clock's `height=width` is a pure function — NO true feedback to iterate.
2. The clock is sized to `getWidthInStack()` (its remembered proportional width, ~130-170), NOT the full
   available width — so it sits CENTERED in the content area ("not stretched"), and NEVER overflows in baseline.
3. **Each animation frame converges in ONE ordered evaluation.** Instrumented per-frame: repeated re-fits within
   a frame are byte-identical IDEMPOTENT redundancy, not fixed-point iteration. (The "3,935 re-fits" cited in old
   docs = many frames × 2-4 redundant re-fits/frame, NOT a within-frame loop.)
4. **~99% of cascade re-fits already happen INSIDE `recalculateLayouts`** (instrumented: 2181/2202 adjust lines
   had `recalc=true`); the `_reFittingContents` counter is load-bearing for only ~21 OUTSIDE-pass cascade moments
   (the drop/nest gestures). So the cascade already lives in the deferred pass, driven top-down from the
   outermost invalidated container's `doLayout` (`super; @_reFitToContents → _adjustContentsBounds`), which sizes
   children synchronously via nested `rawSetWidthSizeHeightAccordingly` + the Path-B height returns.

**Trigger inventory (Explore-agent traced, file:line confirmed).** The seam's synchronous re-fire fires from the
immediate mutators `silentRawSetExtent` (Widget:1599) + `fullRawMoveBy` (Widget:1243). OUTSIDE a pass it ALREADY
invalidates (defers). The genuine BOTTOM-UP triggers (leaf resizes/moves itself with no ancestor mid-fit) —
FIT_BOX_TO_TEXT contained-text edits, slider thumbs, string fields, direct `fullRawMoveTo` of content inside a
non-text-wrapping scroll panel, corner-internal handle resizes — all run OUTSIDE a pass, so the seam already
defers them. **The synchronous re-fire ONLY runs inside a pass/cascade — i.e. exactly the cascade-convergence
case.** So the C2 question is precisely: *does the in-pass cascade still converge if that re-fire is removed?*

**Two complications for C3 (not C2):**
- **A SECOND synchronous re-fit seam:** `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (Widget:1602-1605) —
  an UNCONDITIONAL synchronous re-fit (no recalc/reFitting gate), called from `VerticalStackLayoutSpec`
  alignment/elasticity/base-width setters, `SimplePlainTextWdgt.setSoftWrap`,
  `TextWdgt.reLayoutAndRefreshContainerIfContainedText`, `WindowWdgt.childCollapsed/UnCollapsed`. Same
  `ATTACHEDAS_FREEFLOATING` blocker (a freefloating child's `invalidateLayout` does NOT climb to the panel). A
  full seam removal must account for this twin — it is NOT subsumed by deleting `_reFitContainerAfterRawGeometryChange`.
- **The REACT/scroll arm is the predicted risk.** `ScrollPanelWdgt` is a REACT container in the non-text-wrapping
  case (the seam's scroll-arm target): it sizes itself off `@contents.subWidgetsMergedFullBounds()`
  (ScrollPanelWdgt:321) and bakes via the non-invalidating `silentRawSetBounds` (:366). A freefloating content
  child that changes size in a pass does NOT re-invalidate the panel, so without the synchronous re-fire the
  panel may not re-fit in the same pass → stale scrollbar. (DRIVE/window arms are top-down driven → expected to
  survive; this asymmetry is the whole point of the probe.)

## Plan — evidence-first, the probe is the decision gate

### Phase 0 — Reconcile docs (no behaviour change)
Fix the stale currency in `deferred-layout-OVERVIEW.md`: header master commit `0671ad25`→`7ee0b871`; mark
§5 step-1 (the de-read-back) as SHIPPED (`fa0d7961`); add this plan to the doc-map.

### Phase 1 — FEASIBILITY PROBE (throwaway; the go/no-go decision gate)
Make the seam's IN-PASS arm a no-op (keep the outside-pass `invalidateLayout` arm intact), i.e. inside
`if world?._recalculatingLayouts or world?._reFittingContents` do NOTHING. Build `--keepTestsDirectoryAsIs`, run
the **full dpr1 suite** + the oracle subset. The deterministic oracle partitions the result:
- **(a) ALL GREEN** → the in-pass synchronous re-fire is entirely REDUNDANT; the deferred pass converges the
  cascade on its own. C2/C3 is tractable → go to Phase 2 (clean removal).
- **(b) Only REACT/scroll-arm tests break** (`macroScrollBarsTrackContentChange` + category-iv scroll tests) →
  the stack/window arm is removable but the scroll arm needs in-pass convergence. Assess the scroll-arm
  sub-problem (below); if not cleanly fixable, C3 is blocked → partial result / wall.
- **(c) The clock/cross-widget or DRIVE tests break** → the cascade needs the synchronous ordering; investigate
  the top-down-drive ordering fix / one-shot constraint (below). If unfixable cleanly → wall.

This phase changes NO committed behaviour and is reverted regardless of outcome. It directly implements the
owner's "if C2 is a wall, report the finding, don't ship half-done determinism-sensitive work" directive.

### Phase 2 — The fix (conditional on Phase 1's outcome)
- **If (a):** remove the in-pass arm cleanly; the seam becomes "outside-pass invalidate only" (or folds entirely
  into Phase 3). Verify byte-identical across the full gauntlet + soak.
- **If (b) scroll arm needs work:** make the non-text-wrapping `ScrollPanelWdgt` re-fit converge within the same
  `recalculateLayouts` pass after its freefloating content settles — WITHOUT a pending read (path-a §11: must
  read APPLIED geometry on a fixed point), e.g. by ensuring the panel is itself processed in the pass after the
  content (invalidate the panel directly at the legal — non-immediate-mutator — content-change site, handling
  the freefloating non-climb), not by re-invalidating mid-pass (which throws). Keep the stack/window arm removal.
- **If (c) ordering/cross-widget:** ensure the OUTERMOST affected container is the one driven top-down (its
  `doLayout` drives the whole sub-tree via nested synchronous `rawSetWidthSizeHeightAccordingly` + Path-B
  returns, no up-propagation). Only if a container's height is NOT a pure function of its width (so up-propagation
  is unavoidable) is the one-shot constraint solve (size aspect-locked content to fit BOTH dims from the
  container's OWN applied bounds) needed — the DAG model says it is not, but the probe is the arbiter.

### Phase 3 — C3: remove the seam (+ twin) + tighten lint [E]  (only if Phase 2 green for ALL arms)
- Delete `_reFitContainerAfterRawGeometryChange` and its two call sites (Widget:1243, :1599); remove the now-dead
  `world._reFittingContents` counter + the 3 `_reFitToContents` wraps if unused.
- Address the twin `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (Widget:1602) the same way (route its callers
  to the legal invalidation path, respecting the freefloating non-climb).
- Tighten lint [E] (buildSystem/check-layering.js:151): add a REFIT_CALL regex
  (`childGeometryChanged|_reFitToContents|_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`) and forbid it from
  `isImmediateMutator` methods (satisfiable only AFTER the seam is gone). Rule [D] already forbids macros calling
  these; this is the source-side analogue.

### Phase 4 — Full gauntlet + soak + ONE end-of-arc review
Build (lint 0) → suite **dpr1, dpr2, WebKit** (165/165, zero recapture) → **smoke-apps** (APPS OK) → **torture
soak** (`--dprs=2 --speeds=fastest --shards=8`, ≥20 min — this is re-fit-TIMING / cadence-sensitive). Present the
diff, gauntlet results, the probe finding, and a proposed commit split (src + docs; any recapture separately).
**Ask before commit/push.**

## Oracle (deterministic) + abort criteria
- **CROSS-WIDGET/nested:** `macroWindowWithAClockInAWindowConstructionTwo`, `macroClockInWindowKeepsSquareOnResize`,
  `macroResizeWindowContainingInternalWindow`, `macroWindowsNestedCollapsingUncollapsing`,
  `macroInternalWindowDroppedIntoWindowFits`. ABORT signal: clock loses square / goes huge; inner-layer mis-fit.
- **DRIVE:** `macroWindowWithSimpleVerticalPanelResizesAsContentChanges` (+ its negative images 9-10: scroll-panel
  bounds must stay identical), `macroVerticalStackPanelGrowsWithContent`, `macroWindowResizesToTextContent`.
- **REACT/scroll (the predicted risk):** `macroScrollBarsTrackContentChange`, `macroNoSpuriousScrollbarsOnScrollPanelResize`,
  `macroAddingWidgetToListUpdatesScroll`, `macroSimplePlainTextScrollPanelUpdatesWell…`,
  `macroSimpleDocumentRemovingLastParagraph…`, `macroDocumentScrollsMixedTextAndClocks`. ABORT signal: stale/absent
  scrollbar or wrong thumb in the post-`waitNoInputsOngoing` screenshot.
- **Hard abort:** if Phase 1 shows the scroll arm (or cross-widget) needs the synchronous re-fire AND Phase 2 can't
  make it converge in-pass cleanly (no pending-read, no mid-pass re-invalidate) → C3 unachievable → revert to
  `7ee0b871`, record the finding in the docs, STOP. A partial (stack/window arm only) is NOT shippable on its own
  (the seam stays for the scroll arm → no enforcement payoff), so it would also be docs-only.

## Verification quick-reference (self-contained)
- Build: `cd Fizzygum && ./build_it_please.sh` → `0 violations (A/B/C/D/E)`. Probe/iterate: add `--keepTestsDirectoryAsIs`.
- Suite: `cd Fizzygum-tests && pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"; node
  scripts/run-all-headless.js --shards=5` (then `--dpr=2`, `--browser=webkit`). Single: `node
  scripts/run-macro-test-headless.js SystemTest_<name>` (`PRELUDE_JS=`/`LOG_FILE=` to instrument). No `timeout`
  (use `perl -e 'alarm N; exec @ARGV' node …`).
- Apps: `node scripts/smoke-apps-headless.js` → `APPS OK`. Soak: `caffeinate -i node scripts/torture-headless.js
  --dprs=2 --speeds=fastest --shards=8 --minutes=20`.
- Gotchas: separate `cd` per repo (chaining build+test → MODULE_NOT_FOUND); pkill zombies before every suite run;
  commit via `git commit -F <file>` (never backticks/`$()`); **ask before commit/push**; recapture only sanctioned
  benign shifts.

## Scope / non-goals
- This arc = converge the in-pass cascade + (if clean) remove the seam/twin + lint. NOT Path A (dead). NOT the
  transport/deferred-drag pass. NOT touching the 16 already-green construction macros.
- No intended behavioural/pixel change anywhere — target is byte-identical (the cascade already reaches the same
  final pixels). Any pixel change is a red flag to diagnose, not to recapture (except a sanctioned benign inspector
  member-list shift if a Widget method is added/removed — none currently planned).
