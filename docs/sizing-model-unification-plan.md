# Sizing-model unification (assessment §2.5) — the design-assessment plan (authored 2026-07-16, to be executed COLD, owner-gated)

**STATUS UPDATE 2026-07-16 (same day): U0 EXECUTED — all six decisions D1–D6 CLOSED with
in-tree evidence, P1 spike closed, P2 re-visit counter built + baselined (14 re-visit flushes /
8 tests / 250, classified). See §9. Verdict: GO. U1 (§9.4 scope cut) awaits the OWNER GATE —
no behaviour change has been made; the only new artifact is the P2 prelude in
`Fizzygum-tests/.scratch/revisit-prelude.js` (gitignored).**

**Original status: AUTHORED, no code. This plan stages the DESIGN-FIRST ASSESSMENT for unifying Fizzygum's
two sizing philosophies (`docs/layout-system-architecture-assessment.md` §2.5 — "the most important
structural finding"), plus the implementation phases contingent on its decisions. It is the root-cause
arc for all three residual convergence cases the ordered-downwalk campaign deliberately kept
(down-walk plan §2.5/§2.6 note): aspect-locked width↔height cycles, nested-window first placement
(`contentNeverSetInPlaceYet`), and the settle-time up-edge's informal status. NOTHING here is
committed to until U0's decision gate.**

**OWNER CONSTRAINT UPDATE (2026-07-16, same day as authoring): (1) NOTHING is serialized yet —
private project, no saved files exist, so there is NO file-format compatibility constraint; the
spec classes may change shape freely. (2) LARGE BEHAVIOURAL CHANGES ARE SANCTIONED, provided the
new behaviours give ROUGHLY the same affordances as the old (users can still control how an element
sizes in a stack; elements still stretch when their container stretches). This FLIPS the D1
recommendation from (c) [keep the proportional formula, byte-exact] to (b) [ONE true constraint-box
model everywhere] — the sections below carry both the original conservative analysis and the
updated recommendation, marked ⇄.**

Line numbers drift — grep the named symbol.

## §0 — Cold context

Fizzygum = CoffeeScript GUI on one `<canvas>`; every class a global; `nil` == `undefined`. Umbrella
`/Users/davidedellacasa/code/Fizzygum-all/` (not a repo) holds `Fizzygum/` (source), `Fizzygum-tests/`
(250 macro SystemTests, byte-exact SWCanvas screenshots), `Fizzygum-builds/` (generated). Commands via
the cwd-safe wrapper: `fg build` / `fg presuite` (~3.5 min) / `fg gauntlet` (~5 min, incl. the CAPSTONE
careless-push gate) / `fg status`. Long ops: `run_in_background` + task notification; never
foreground-poll. Never edit src mid-suite/torture (the stale-build guard scans `.coffee` mtimes).

Where the layout engine stands (2026-07-16, post ordered-downwalk campaign, Fizzygum `cee6939f`):
the settle engine is the SOLE healer of composite interiors — ordered root-down walk + the
frame-changed child injection (watching EVERY valid child, ungated) + the schedule-valve in
`Widget._applyExtent` (gated `children.length != 0`) + the V1 ScrollPanel seam (gated
`implementsDeferredLayout`). Zero capability declarations, zero markers. Convergence is bounded and
near-single-pass but *verified-empirical*, not structural (assessment §2.6): the sanity cap is a
never-fire assert, and the only real multi-visit residuals are the three cases this plan attacks at
the root.

## §1 — What this is, and why now

**The finding (assessment §2.5):** two sizing philosophies coexist.

| | HORIZONTAL stacks | VERTICAL stacks / window content / scroll content |
|---|---|---|
| Model | min/desired/max constraint box (flexbox-like) | PROPORTIONAL: width = f(add-time snapshot, elasticity, container width) |
| Measure | pure bottom-up recursion (`_getRecursiveStackDim`) | pure `preferredExtentForWidth` since §4.1 — EXCEPT the source's mutate-then-read (`_setWidthSizeHeightAccordingly`, "Path B") and the folder/toolbar applied read-back (`subWidgetsMergedFullBounds`) |
| Arrange | 3-case distribution in base `_reLayout` (~:4913–4994) | sum the handed/measured heights (`_positionAndResizeChildren`) |

**Why the split matters:** the proportional model couples child width to container width
*continuously* while container size depends back on children — thread that through aspect-locked
content and width↔height→width is a genuine cycle (today broken by the `elasticity 0` convention,
which is correct but is a per-class cycle-breaking CONVENTION, not a model property). The
first-placement flag exists because window-content specs are initialised only ON first placement, so
an outer window cannot measure an unplaced inner window (NaN). The settle-time up-edge is the
bottom-up half of layout done as a post-settle CORRECTION rather than a formal measure phase.

**Why now:** when the assessment judged this "not currently justified" it named the ordered
down-walk as the missing, far-larger prerequisite. That prerequisite EXISTS as of 2026-07-16
(down-walk plan §8/§10/§11): the top-down half is built, uniform, and ungated; the pure-measure
campaign already put `preferredExtentForWidth` on every width→height type. What remains is the
measure-side unification — this plan.

**What it buys (the end-state):**
- aspect cycles DISSOLVE into the measure pass (aspect content = a measure function, like
  flexbox's aspect-ratio — `KeepsRatioWhenInVerticalStackMixin.preferredExtentForWidth` already is one);
- `contentNeverSetInPlaceYet` DELETED (a convergence boolean, squarely in the standing
  elimination goal — [[proper-layouts-elimination-goal]]);
- Path B's mutate-then-read retired (measure purely, apply once);
- the last applied read-back (`subWidgetsMergedFullBounds`) retired or proven-essential-and-named;
- convergence becomes STRUCTURAL (one measure up, one arrange down, plus the formalized up-edge)
  instead of verified-empirical — gate-able by a re-visit counter instead of a torture soak.

**What it does NOT touch:** the up-edge's information flow. Container-fits-content is inherently
bottom-up; the goal is to FORMALIZE it as the measure phase, not remove it.

## §2 — The two models as-built (verified in-tree 2026-07-16)

### 2.1 The proportional model (the wide one)
- `VerticalStackLayoutSpec` (:31): `getWidthInStack(availW) = round(wEl + elasticity·(availW·wEl/wStk − wEl))`,
  capped at availW; `wEl`/`wStk` = `widthOfElementWhenAdded`/`widthOfStackWhenAdded` captured AT ADD
  TIME (`rememberInitialDimensions`). **The state is HISTORICAL** — layout depends on an add-time
  snapshot, not on the current tree alone.
- **It is USER-FACING**: the "layout in stack ➜" menu edits base width / elasticity / alignment per
  element (all self-settling public setters); the spec rides `DeepCopierMixin` through duplication
  and would ride serialization. ⇄ ORIGINALLY flagged as the most constraining fact (user semantics +
  file format); the owner constraint update DEFUSES it — nothing is serialized yet, and behaviour may
  change if the affordances survive. What REMAINS binding: the menu must keep offering roughly the
  same three controls (a size knob, a stretchiness knob, alignment), mapped onto the new model's
  vocabulary (D2).
- `WindowContentLayoutSpec extends VerticalStackLayoutSpec` (+`preferredStartingWidth/Height`) —
  window content IS a stack element w.r.t. sizing. Consumers of `getWidthInStack`: the stack arrange
  (`SimpleVerticalStackPanelWdgt`:132), the window arrange (`WindowWdgt`:633), the window measure
  (`WindowWdgt`:91).
- `elasticity 0` users (the aspect/fixed contents): `IconWdgt`, `SpreadsheetWdgt`, `AnalogClockWdgt`
  — each with a rationale comment saying it makes width convergence-independent
  (`getWidthInStack = min(wEl, availW)`).

### 2.2 The constraint-box model (the narrow one!)
min/desired/max + spreadability (`setMinAndMaxBoundsAndSpreadability`, `Widget` ~:4666;
`LayoutSpec.SPREADABILITY_*`), measured by the shared `_getRecursiveStackDim` walker, arranged by the
3-case distribution in base `_reLayout` (~:4913–4994: under-min shrink / desired-margin grow /
max-margin fill). Only ~6 files reference `ATTACHEDAS_STACK_HORIZONTAL*` (dividers, spacers,
adders, `StackElementsSizeAdjustingWdgt`, `WidgetFactory`, `PointerWdgt`). **The "textbook" model is
the less-deployed one** — deployment-wise, unification onto EITHER side is a migration of the other.

### 2.3 The impure residue on the vertical side
- **Path B** — `_setWidthSizeHeightAccordingly(newWidth)` (base `Widget`:765 + 10 overrides:
  TTF, StretchableEditable, WidgetHolderWithCaption, StretchableWidgetContainer, KeepsRatio mixin,
  Spreadsheet, GenericCompositeIcon, AnalogClock, Example3DPlot, +base): APPLY width, re-lay, read
  height back. It is the mutate-then-read SOURCE the §4.1 campaign could not fully remove.
- **The applied read-back** — `subWidgetsMergedFullBounds`: non-content-sizing folder/toolbar frames
  merge children's APPLIED bounds. §4.1 proved a measure pass ALONE could not replace it (that is
  why the re-fit seam could not be deleted then).
- **The pinned-false exception** — `ScrollPanelWdgt.implementsDeferredLayout: -> false`
  (ScrollPanelWdgt:332, despite defining `_reLayout`): pinned so (A) `_setWidthSizeHeightAccordingly`
  and (B) `subWidgetsMergedFullBounds` classify it as before (a deferred-layout child contributes
  only its viewport rect — un-pinning regressed nested-scroll, the proven 16→18 Path-A trap). Any
  protocol unification must either honour or retire this classification split. (N4 note: the V1 seam
  now gates on `implementsDeferredLayout`, so a hypothetical ScrollPanel-as-`@contents` would not be
  seam-scheduled — no such construct exists in-tree and the 250-test relayset A/B confirmed no lost
  heals; recorded here as a known edge of that gate.)
- **The first-placement flag** — `WindowWdgt.contentNeverSetInPlaceYet` (:29, :81, :306–318,
  :608–654): guards the measure (returns current extent while true — the inner specs are
  uninitialised and `getWidthInStack` would NaN) and selects the first-placement branch of the
  window arrange. 3 one-time construction re-visits suite-wide; three removal routes FALSIFIED (§6).

## §3 — The design space: six decisions U0 must close

- **D1 — target semantics.** (a) Re-express the proportional formula as constraint parameters
  (byte-exact goal, model preserved); (b) ⇄ **RECOMMENDED (post owner-constraint-update): ONE true
  constraint-box model everywhere** — min/desired/max + grow, the model the horizontal stacks
  already run — for vertical stacks, window content, and scroll content (mass recapture: ~65/250
  tests touch stack/window/scroll/toolbar/list surfaces; sanctioned); (c) keep the proportional
  formula as the vertical MEASURE FUNCTION inside a unified protocol — byte-exact, but preserves
  the add-time-snapshot state and therefore CANNOT deliver D3-for-free (below); now the FALLBACK if
  (b) hits an unforeseen wall, not the default.
  Why (b) is also the SIMPLER end-state: the proportional model's add-time snapshot
  (`widthOfElementWhenAdded`/`widthOfStackWhenAdded`) makes layout depend on HISTORY rather than the
  current tree — the constraint model has no such state, which is precisely what makes measures
  well-defined before placement (D3) and cycles impossible (D6).
- **D2 — the affordance map (the binding constraint that remains).** The three menu knobs survive
  with roughly the same meanings: *base width* → **desired width** (still captured from the
  element's natural width at add time — as the spec's INITIAL desired value, an initialisation
  policy, not load-bearing model state); *elasticity* → **grow factor / spreadability** (elasticity
  0 ↔ no-grow/fixed; elasticity 1 ↔ full grow); *alignment* → unchanged. Behavioural delta to
  accept: proportional keeps element/stack width RATIO constant under container resize; grow
  distributes EXTRA space — elements still stretch when the container stretches, but along a
  different curve. That is the "roughly similar affordance" the owner sanctioned. U0 writes the
  precise mapping table incl. what each existing elasticity value becomes.
- **D3 — spec-at-construction.** ⇄ Under D1(b) this likely falls out FOR FREE: the NaN that forces
  `contentNeverSetInPlaceYet` (WindowWdgt:78–81) is `getWidthInStack` dividing by the UNINITIALISED
  add-time snapshot — the constraint model has no add-time state, so an unplaced window's content
  measure is well-defined. Spike P1 shrinks to: verify nothing ELSE needs placement, and design the
  replacement discriminator for the flag's SECOND job — selecting the first-placement arrange
  branch (WindowWdgt:608/:638, "place initially vs preserve user scroll/position"; candidate:
  derive from the content's own never-laid state, not a window-level boolean).
- **D4 — the folder/toolbar applied read-back.** What information does `subWidgetsMergedFullBounds`
  carry that `subWidgetsMergedPreferredBounds` cannot? (Free-floating children placed by the USER —
  their positions are state, not derivable from specs. A pure measure can still READ CURRENT
  child frames without APPLYING anything — the impurity to kill is mutate-then-read, not
  read-current-state.) Reframe: the read-back may be reclassifiable as a legitimate STATE-read
  measure. Decide the taxonomy before touching code.
- **D5 — Path B.** Can `_setWidthSizeHeightAccordingly` become measure(`preferredExtentForWidth`) +
  ONE apply at every call site? All 10 overrides already have measure twins or trivial ones. The
  arrange (stack Path-B branch) and `WindowWdgt` (:633–654) are the callers to convert. Watch the
  height-read-back consumers (the caller consumes the returned height mid-arrange).
- **D6 — aspect content.** Formalize "elasticity 0 + `preferredExtentForWidth`" as THE aspect
  contract (measure function; no cycle possible) — likely just documentation + a lint candidate
  (an aspect measure with elasticity ≠ 0 is the cycle recipe).

## §4 — Staging (each stage independently shippable, gated, STOP-per-stage sanctioned)

⇄ Re-staged for D1(b) after the owner constraint update. Pixel-changing phases are SANCTIONED;
their gate is visually-reviewed batch recapture (`fg diffpage`, the 70-ref gradient-arc workflow)
plus the behaviour-invariant oracles (census / capstone / torture / P2), NOT byte-exactness.

- **U0 — the assessment itself (no behaviour change).** Close D1–D6 with in-tree evidence — chiefly
  the D2 affordance-mapping table (every existing elasticity/base-width use in-tree and what it
  becomes, incl. the 3 elasticity-0 classes) and the vertical DISTRIBUTION semantics per content
  type (wrapping text, fixed icons/spreadsheet/clock, fill-stretchables); run the probes; write the
  decisions into §9; OWNER GATE on the package.
  - **P1 (spike):** what besides `getWidthInStack`'s snapshot needs placement (D3), + the
    first-placement-branch discriminator design.
  - **P2 (instrument):** resurrect the per-flush re-visit counter (assessment §2.6 — "instrumented +
    reverted") as a durable oracle: per-settle count of widgets re-laid MORE THAN ONCE per flush,
    classified by cause. Baseline on the current build (expect: 3 first-placement re-visits + the
    aspect-cycle iterations + zero else). This is the campaign's convergence gauge — what the
    staleness census was for the down-walk campaign.
- **U1 — vertical stacks onto the constraint model.** `VerticalStackLayoutSpec` re-shaped
  (min/desired/max+grow; add-time snapshot state DELETED; menu knobs remapped per D2); the stack
  arrange consumes the unified measure; Path-B stack sites become measure+apply (D5). Mass
  recapture expected (stack/list/toolbar tests). Gates: §5 set with visual review in place of
  byte-exactness; P2 counter must show the aspect-cycle iterations GONE.
- **U2 — window content (+ the flag).** `WindowContentLayoutSpec` onto the same model; window
  measure/arrange (:75–:91, :608–676) consume it; `contentNeverSetInPlaceYet` DELETED (D3 —
  P2 counter −3). Window-surface recaptures.
- **U3 — scroll content + the read-back taxonomy (D4) + the `implementsDeferredLayout` pin (§2.3)
  resolved or explicitly re-pinned.** Retire `subWidgetsMergedFullBounds` into the unified measure
  or reclassify it as the ONE named state-read with rationale + lint note.
- **U4 — cleanup + the structural-convergence gate.** Delete the dead proportional machinery;
  formalize the aspect contract (D6); ship the P2 counter as a standing gate (settle leg or a new
  audit): ZERO multi-visit settles outside the up-edge.

Recommended order: U0 → U1 → U2 → U3 → U4, each with the full §5 gate; U1 is the risk
concentrator — if its distribution semantics fight the suite beyond recapture-and-review, STOP and
fall back to D1(c) for that surface (the falsification exit).

## §5 — Verification protocol (per stage)

`fg build` + `fg presuite` + 1-round `.scratch/stage-b-torture.sh` per stage; arc close =
`fg gauntlet` (capstone leg is the off-settle-schedule watchdog) + 3-round torture + staleness
census (`.scratch/staleness-census.js`, extended battery incl. slides apps, 1506 targets, 0 movers)
+ relayset A/B vs the stage's base sha (`.scratch/relayset-prelude.js` + `relayset-subset-check.py`;
shared-clone before-trace under `FIZZYGUM_ALLOW_STALE_BUILD=1` — ⚠ the clone umbrella MUST be named
`<x>/Fizzygum-all/` and the baseline artifact MUST be verified (index.html mtime + a
changed-symbol grep) BEFORE tracing: the raw build ABORTS-but-EXITS-0 on a wrong umbrella name,
down-walk plan §11) + the P2 re-visit counter. The FIRING-PROFILE technique (down-walk plan §11:
a zero-behavior-change counting prelude answering "what would this gate candidate fire on?" BEFORE
building it) applies to every D-decision with a gate-shaped alternative.

## §6 — Falsified prior art — do NOT re-attempt these shapes

- **First-placement removal, 3 routes** (assessment §2.6/§4.1): measure-ahead (uninitialised specs
  NaN), settle-early (not byte-exact), reorder (content-before-container climb-block broke 9
  load-bearing tests). The ONLY unexplored route is D3's root-cause decoupling.
- **Measure pass alone deleting the re-fit seam** (§4.1): falsified — the folder/toolbar applied
  read-back was load-bearing. D4 exists because of this.
- **Seam deletion via structural arrange** (`fizzygum-structural-arrange-arc` §4.2, `c8098e6d`):
  falsified; the seam stays.
- **In-pass/off-pass seam skip** (`fizzygum-convergence-arc-feasibility`): falsified.
- **Un-pinning `ScrollPanelWdgt.implementsDeferredLayout`** (ScrollPanelWdgt:325 comment): the
  proven 16→18 nested-scroll Path-A trap.
- **The `wEl/wStk` stack fraction** was judged IRREDUCIBLE *within the proportional model*
  (deferred-layout campaign) — this plan changes the frame (D1), it does not retry the reduction.

## §7 — Symbol map

`VerticalStackLayoutSpec` (`getWidthInStack`, `rememberInitialDimensions`, `elasticity`,
`widthOfElementWhenAdded`/`widthOfStackWhenAdded`) · `WindowContentLayoutSpec`
(`preferredStartingWidth/Height`) · `WindowWdgt` (`preferredExtentForWidth`:75,
`contentNeverSetInPlaceYet`:29/:81/:306/:608/:638/:654, arrange :608–676) ·
`SimpleVerticalStackPanelWdgt` (`_positionAndResizeChildren`, `preferredExtentForWidth`:169,
`subWidgetsMergedPreferredBounds`:195, `getWidthInStack` call :132) · `ScrollPanelWdgt`
(`implementsDeferredLayout` pin :332, arrange + V1 seam) · base `Widget`
(`_setWidthSizeHeightAccordingly`:765, `preferredExtentForWidth`:781, h-stack distribution
~:4913–4994, `setMinAndMaxBoundsAndSpreadability`:4666, `implementsDeferredLayout`:4810) ·
`KeepsRatioWhenInVerticalStackMixin` (the aspect measure) · elasticity-0 users: `IconWdgt:26`,
`SpreadsheetWdgt:110`, `AnalogClockWdgt:42`. Authorities: `layout-system-architecture-assessment.md`
§2.4–§2.7/§4.1/§4.2/§4.4 · `ordered-downwalk-stage-b-plan.md` §8–§11 (the built top-down half +
instruments + ops traps).

## §8 — Success criteria (the campaign's definition of done) ⇄ updated for D1(b)

1. ONE sizing model (min/desired/max + grow) on every path — horizontal AND vertical stacks, window
   content, scroll content; the proportional formula and its add-time snapshot state DELETED.
2. ONE measure protocol reachable on every sizing path; Path B's mutate-then-read gone.
3. `contentNeverSetInPlaceYet` deleted (or its irreducibility PROVEN with a named replacement route
   falsified — updating §6).
4. `subWidgetsMergedFullBounds` unified, or reclassified as the ONE named state-read.
5. Aspect contract formalized (D6) as a measure function; no cycle-breaking convention needed.
6. The P2 re-visit counter reads ZERO outside the up-edge in steady state — convergence is
   STRUCTURAL — and the counter ships as a standing gate.
7. The stack/window affordances survive: a size knob, a stretchiness knob, alignment — per the D2
   mapping table (behavioural curves may differ; capabilities may not shrink).

## §9 — Execution log

### §9.1 — U0 evidence inventory (2026-07-16, Fizzygum @ `c675bab5`, build FRESH, all gates green at start)

**The complete spec-writer census** (every in-tree construction/mutation of a vertical/window
layout spec — grep-verified closed set):

| # | Site | Today | Under the constraint model |
|---|------|-------|----------------------------|
| 1 | `Widget:312` default window-content spec | WCLS(THIS_ONE_I_HAVE_NOW, THIS_ONE_I_HAVE_NOW, e=1) | desired = content natural width, grow = 1. **Near-identical behaviour**: at add the window hugs content so wEl≈wStk ⇒ the proportional ratio ≈ 1 ⇒ today's "ratio-track the window" already ≈ fill. |
| 2 | `Widget:317` default stack-element spec | VSLS(e=1) | desired = natural width at add, grow = **the ONE real curve break** — see below. |
| 3 | `PaletteWdgt:29`, `SimplePlainTextScrollPanelWdgt:61`, `WindowContentsPlaceholderText:14` | WCLS(DONT_MIND, DONT_MIND, 1) | grow = 1 (fill). **Identical**: DONT_MIND sets wEl=wStk at capture ⇒ proportional ≡ fill already. |
| 4 | `SliderWdgt:63` | VSLS(0) | grow = 0, desired = natural. **Identical**: e=0 ≡ min(wEl, availW) ≡ grow-0 with the availW cap. |
| 5 | `SliderWdgt:86`, `MenuWdgt:70` | WCLS(THIS, THIS, 0) | grow = 0. **Identical.** |
| 6 | `IconWdgt:26`, `SpreadsheetWdgt:110`, `AnalogClockWdgt:42` | `elasticity = 0` in initialiseDefault… | grow = 0. **Identical** (these are the D6 aspect/fixed trio). |
| 7 | `HowToSaveMessageApp:28`, `WelcomeMessageInfoWdgt:14`, `SimpleDocumentWdgt:53` | `setElasticity 0` (+ center) | grow = 0. **Identical.** |
| 8 | ~15 `setAlignmentTo*` sites (info-widgets, apps) + `AlignButtonWdgt:18` (addresses setters BY NAME) | alignment | **Unchanged verbatim** (keep the three alignment setter names). |
| 9 | Oversize-at-add clamp `VSLS.rememberInitialDimensions:23–25` (wEl=availW, FORCE e=1) and `WCLS:56–58` (DONT_MIND ⇒ wEl=availW, e=1) | fill | grow = 1. **Identical** (wEl=wStk ⇒ proportional ≡ fill). |
| 10 | Explicit-px `preferredStartingWidth` (`WindowWdgt:621`) | content gets px, window resizes to it | desired = px. **No in-tree constructor ever passes a px** — every WCLS ctor call uses the sentinels; the px path is API-only, dead in tree. |

**The ONE real curve break (the honest D2 core).** Every row above is behaviour-identical or
near-identical EXCEPT the default stack element added/dropped at natural width < stack width
with e=1 (row 2): today it keeps its natural width at add and then RATIO-scales when the stack
resizes. The grow model cannot express "keep at rest, scale ratio-wise on container resize":
grow 1 fills the row immediately (a dropped small widget would jump to full stack width — an
affordance DEGRADATION, not just a curve change); grow 0 keeps natural width but never
stretches on stack widen. **Decision (D2-def): default grow = 0 for plain added/dropped stack
elements** — they keep their drop width; stretchiness remains one menu tap away; the fill-class
content (text panels, DONT_MIND window content, oversize adds — rows 1/3/9) keeps grow 1 and
still stretches with its container, which is where "elements stretch when the container
stretches" actually lives in practice. Pixel churn concentrates in stack-resize-after-drop
flows; U1's diffpage review enumerates the exact set.

**Named non-recommended alternative for the owner gate (D1(b′), the fraction hybrid):** store
`widthFraction = wEl/wStk` (ONE number, default 1) instead of the two-value snapshot; width =
round(min(availW, wEl + e·(availW·fraction − wEl))). Keeps today's ratio look EXACTLY, still
kills the divide-by-nil NaN (⇒ D3 still falls out) — but it is still the proportional model
(fraction IS captured history), does NOT unify the vocabulary with the h-stacks, and keeps
order-dependence (a measure before capture answers fraction=1). Present at the gate; not
recommended.

**Chokepoint findings (why U1 is mechanically small):**
- The STACK side has ONE width-policy chokepoint: `SimpleVerticalStackPanelWdgt._childWidthInStack:131`
  — all three walkers (the arrange `_positionAndResizeChildren`, and the pure measures
  `preferredExtentForWidth` / `subWidgetsMergedPreferredBounds`) funnel through it. Swapping the
  model = swapping the spec's answer; the walkers don't change.
- The WINDOW side consumes the spec at exactly `WindowWdgt:91` (measure) and `:633` (arrange)
  plus the first-placement branch (§9.2 P1).
- The SCROLL side has NO direct spec consumer: `ScrollPanelWdgt` sizes its content frame from
  `subWidgetsMergedPreferredBounds` (content-sizing branch, :422/:425) or
  `subWidgetsMergedFullBounds` (folder/toolbar branch, :427). "Scroll content" rides the stack's
  chokepoint. U3 shrinks accordingly.
- Spec init happens at FIRST ARRANGE, not at add(): `_positionAndResizeChildren` initialises
  missing specs before asking (stack :226–229, window :604–606). "Add-time snapshot" is really
  "first-arrange-time snapshot" — the order-dependence D3 kills.
- Window content is centered UNCONDITIONALLY (`WindowWdgt:688`) — the alignment knob is inert
  for window content today (pre-existing quirk; carry it over unchanged).

**D4 evidence (closed):** `subWidgetsMergedFullBounds` has exactly ONE consumer —
`ScrollPanelWdgt:427`, the non-content-sizing (folder/toolbar) branch, where children are
USER-PLACED free-floating widgets: their positions are genuine state, not layout-derived, and
that arrange never mutates them (no mutate-then-read). **D4 closes as RECLASSIFY**: it is the
ONE named state-read measure; document + keep; no unification work. (Its
`implementsDeferredLayout` child-classification fork at `Widget:1134` is part of the same named
read — the ScrollPanel pin (§2.3) stays honoured through U1–U3 and is re-examined only in U4.)

**D5 evidence (protocol gap found):** five Path-B container overrides have NO true measure
twin — `WidgetHolderWithCaptionWdgt`, `StretchableWidgetContainerWdgt`,
`GenericCompositeIconWdgt`, `Example3DPlotWdgt`, `StretchableEditableWdgt` (the measure-override
set is: base Widget, TextWdgt, AnalogClock, KeepsRatio mixin, Spreadsheet, Stack, Window, TTF,
TransformFrame). For those five, the stack's pure measure falls back to base width-invariant
(current height) — correct ONLY at the fixed point; the arrange's Path B is what actually
produces their height. **D5 closes as: STAGE THE PROTOCOL CHANGE SEPARATELY from the width
policy** — U1 swaps only WHAT WIDTH is handed down (the model), keeping Path B as the
application mechanism for container children; the mutate-then-read retirement (true measures
for the five, callers converted to measure+apply) moves wholly to U3. Path B callers are
exactly three: stack arrange :268, window arrange :652/:658, and the ratio mixin's self-call
(`_constrainToRatio`).

**D6 evidence (closed):** the aspect contract as-built = `elasticity 0` + a pure
`preferredExtentForWidth` (clock: square, :50–51; KeepsRatio mixin: current-ratio measure,
:24–25 — reads applied geometry, a legitimate state-read). Under the unified model: grow 0 + the
measure. Formalize as documentation + a lint CANDIDATE (aspect measure with grow ≠ 0 = the
cycle recipe) — run the firing-profile technique (§5) before building the lint.

**D1 storage sub-decision:** the h-model's vocabulary lives as WIDGET FIELDS
(`minWidth/desiredWidth/maxWidth`, set by `setMinAndMaxBoundsAndSpreadability:4655`, max
DERIVED from spreadability%); the v-model's lives in the SPEC OBJECT (menu home, DeepCopier).
**Close as: unify the READ PROTOCOL, not the storage, in U1–U3** — the distribution/arrange
reads go through one accessor family (getMinDim/getDesiredDim/getMaxDim/grow), backed by
spec-details where present and fields otherwise; storage unification is U4 cleanup IF still
warranted then. §8.1's "ONE sizing model" is satisfied at the protocol level.

### §9.2 — P1 spike (closed by inspection; no code)

**Reader census of `contentNeverSetInPlaceYet`:** exactly six sites, all in `WindowWdgt` —
decl :29, measure guard :81, set-true :318 (content add), branch selectors :608/:638, clear
:654. No harness/test readers.

**Job 1 (measure guard :81) dies automatically under D1(b):** the guarded NaN is
`getWidthInStack` dividing by the uninitialised `widthOfStackWhenAdded`; the constraint answer
(desired + grow·(availW − desired), desired defaulting to the element's natural width) is total
— every leaf measure in the v-chain (base, text, clock, ratio, spreadsheet, TTF) reads only own
state + the availW input; the stack recurses; window chrome is prefs+padding. NOTHING else in
the measure chain needs placement. Bonus: a pre-negotiation measure now returns approximately
the POST-negotiation answer (THIS_ONE_I_HAVE_NOW ⇒ desired=natural ≈ content current width;
DONT_MIND ⇒ grow 1 ⇒ fill), which is exactly what dissolves the outer window's garbage first
measure of an inner window — the root of the 3 first-placement re-visits.

**Job 2 (first-placement arrange branch :608–654) — what it actually is:** a ONE-TIME
window↔content size negotiation on content swap, driven by the `preferredStartingWidth/Height`
sentinels (THIS_ONE_I_HAVE_NOW = window hugs content; DONT_MIND = content fills window;
explicit px = dead in tree), ending in `rememberInitialDimensions` (dies with the snapshot) and
the flag clear. **Discriminator design — RECOMMENDED (b-route): a spec-keyed one-shot** — key
the branch on the CONTENT-owned "spec not yet initialised for this placement" state (e.g.
`desiredWidth` unset), not a window boolean: mechanically closest to today (same arrange-time
timing, so the collapsed-at-add edge keeps today's semantics for free — the negotiation runs at
the first UNCOLLAPSED arrange, `:599` guard unchanged), the window-level boolean is DELETED,
and the measure needs no guard because measures are total. The (a-route) alternative — negotiate
at ADD time in `_addNoSettle`, deleting the arrange branch entirely — is cleaner but must
design the collapsed-at-add edge (a collapsed window's applied bounds are titlebar-only; the
negotiated extent would have to land in the stored uncollapsed extent) and re-times the
window-resize side effect; keep as a U2 stretch goal, attempt only after (b) is green.
`_reLayoutMayResizeOwnWidth` (:298, the nested-window early-settle EXCLUSION at :670 that
CAUSES the 3 re-visits) exists only because the first-placement branch resizes the window's own
width — once U2 lands, re-derive whether it can return false/be deleted, which un-excludes
windows from the single-pass early-settle and takes the re-visits to zero.

### §9.3 — P2 instrument (built; baseline pending below)

`Fizzygum-tests/.scratch/revisit-prelude.js` — rides the AUDIT_PRELUDE/AUDIT_DIR rails
(relayset-prelude.js pattern: name-preserving wrappers, closure state only,
LAYOUTAUDIT_TESTSTART contract). Counts per-flush DEPTH-0 `_reLayout` entries per widget —
depth-0-only is load-bearing: it excludes in-arrange child re-lays (corner-internal children
are re-laid by every parent arrange, twice per stack arrange by design — V3) and super-chain
hops, isolating genuine settle-loop re-visits (chain-top picks / injections / up-edge
re-fits). Emits `LAYOUTAUDIT REVISIT i=<flush> visited=<n> multi=<id>:<count>;…` only for
flushes containing a re-visit. Run:
`AUDIT_PRELUDE=.scratch/revisit-prelude.js AUDIT_DIR=.scratch/revisit-baseline node scripts/run-all-headless.js`.

**Baseline (2026-07-16, Fizzygum @ `c675bab5`, 250/250 pass with the prelude installed, 0
geometry violations): 14 re-visit flushes across 8 tests / 250.** Classified:

| Class | Where | Count | Owner stage |
|---|---|---|---|
| **Nested-window negotiation** (the plan's target): `WindowWdgt#…:2–3` + companion injections (Handle/Box/String/text re-picked after the window's frame changed) | `macroWindowsNestedCollapsingUncollapsing` (6 flushes, incl. one `WindowWdgt#1:3`), `macroWindowWithAClockInAWindowConstructionTwo` (2 flushes, both windows) | 8 flushes | U2 ⇒ 0 |
| **Aspect content**: `AnalogClockWdgt#1:2` riding the same nested-window flushes | clock-in-window construction | (inside the 2 above) | dies with U2; D6 formalizes |
| **TransformFrame slot-tracking up-edge**: `TrackingTransformFrameWdgt#N:2`, exactly once per flow | 5 island tests (drop/track/resize flows) | 5 flushes | up-edge BY DESIGN (slot tracks content extent) — §8.6's "outside the up-edge" carve-out; re-examine in U4 only |
| **Scroll uncollapse up-edge**: `PanelWdgt#1:2; ScrollPanelWdgt#1:2`, one flush | `macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsing…` | 1 flush | up-edge; re-examine in U3 |

The earlier "3 first-placement re-visits" figure (assessment §2.6) counted only the WindowWdgt
content-negotiation re-visits in steady construction; the P2 counter sees the full picture —
the nested-window FAMILY is 8 flushes across 2 tests once collapse/uncollapse flows are
included. Baseline artifacts: `.scratch/revisit-baseline/` + `/tmp/u0-p2-baseline.log`.

### §9.4 — U0 closing package (owner gate)

**OWNER GATE PASSED (2026-07-16): D2-def APPROVED (default grow 0 for plain added/dropped
stack elements; D1(b′) declined), U1 GO.** The U1 execution log continues in §9.5.

**All six decisions CLOSED** (evidence in §9.1–§9.3):
- **D1 = (b)** — ONE constraint-box model (desired + grow, min/max clamps) on every vertical
  path; vocabulary unified at the READ-PROTOCOL level in U1–U3, storage unification deferred to
  U4-if-warranted. The (b′) fraction hybrid is the named fallback if the owner wants today's
  ratio look preserved (still kills the NaN ⇒ D3 survives; forfeits vocabulary unification).
- **D2** — mapping table §9.1; every in-tree use is behaviour-identical or near-identical
  under (desired, grow) EXCEPT the default narrow-add stack element: **D2-def = default grow 0
  for plain added/dropped stack elements** (fill-class content keeps grow 1). Menu keeps its
  three knobs ("base width…" ⇒ desired, "elasticity… 0–100" ⇒ grow×100, align unchanged);
  setter NAMES kept in U1 (AlignButtonWdgt + menu address them by name), renames deferred to U4.
- **D3** — falls out: measure guard dies with the NaN (Job 1); the arrange branch becomes a
  spec-keyed one-shot (Job 2, P1 (b)-route); `contentNeverSetInPlaceYet` DELETED in U2;
  `_reLayoutMayResizeOwnWidth`'s early-settle exclusion re-derived after U2 (takes the
  nested-window re-visit family to zero).
- **D4** — RECLASSIFY: `subWidgetsMergedFullBounds` is the ONE named state-read (single
  consumer, user-placed free-floating children, no mutation in that arrange); document, keep.
- **D5** — width POLICY (U1) staged separately from measure PROTOCOL (U3): five container
  types have no true measure; Path B remains the container-child application mechanism through
  U1–U2.
- **D6** — aspect contract = grow 0 + a pure `preferredExtentForWidth`; documentation + a
  firing-profiled lint candidate in U4.

**Go/no-go: GO.** The evidence strengthened the case: the swap is behaviour-identical on
every in-tree use but one (D2-def covers it), the stack side has a single width-policy
chokepoint, the scroll side has no direct consumer at all, and the P2 counter now gives the
campaign a numeric convergence gauge with a classified baseline.

**U1 scope cut (next session, owner-gated):**
1. `VerticalStackLayoutSpec` re-shaped: `desired` (captured once from natural width — an
   initialisation default, user-editable) + `grow` + `alignment`; `widthOfStackWhenAdded`
   DELETED; `getWidthInStack(availW)` → `round(min(availW, desired + grow·(availW −
   desired)))`; `rememberInitialDimensions` → a capture-desired-once init; oversize-at-add ⇒
   desired=availW, grow=1 (unchanged semantics); default grow 0 per D2-def.
2. `WindowContentLayoutSpec` follows structurally (it extends the spec): DONT_MIND ⇒ grow 1;
   THIS_ONE_I_HAVE_NOW ⇒ desired=current width. The window's first-placement FLAG machinery is
   untouched until U2.
3. Consumers unchanged (the chokepoint answers differently; walkers/Path B/menu plumbing keep
   their shapes; setter names kept).
4. Gates: `fg build` + `fg presuite` + 1-round torture + `fg census` + P2 re-run (target:
   stack-surface deltas only; nested-window family UNCHANGED until U2) + `fg diffpage` visual
   review of every stack/window/list-surface test that changes + full recapture of the reviewed
   set. Falsification exit: if the distribution semantics fight the suite beyond
   recapture-and-review, STOP and re-frame on D1(b′) for that surface.
