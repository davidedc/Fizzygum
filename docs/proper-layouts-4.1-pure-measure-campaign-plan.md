# Plan — §4.1 the GENERAL pure-measure campaign (`preferredExtentForWidth`) that deletes the re-fit seam

> **STATUS (2026-06-28). Stages 0/A/B/D DONE+committed (held); Stage C PROBE GREEN + PRODUCTION CONSUME LANDED & FULLY VERIFIED (byte-identical; gauntlet ×3 + capstone 18 + paint-readonly 0 + 20-min dpr2 torture all green) — awaiting owner commit approval (held).**
> The owner-approved §4.1 pure-measure protocol ("kill the read-back — highest leverage; attacks the root") is
> executing. Stage 0 GREEN (4022 text-measure differentials, 0 mismatches). Landed + committed HELD:
> **A** (`TextWdgt` measure, `a07f534a`), **B** (composable stack + aspect measures + `getWidthInStack` param +
> `WindowWdgt` stub, `ea9ffcef`/tests `7547c04b4`), **D** (the REAL `WindowWdgt` content+chrome measure + the base
> `Widget.preferredExtentForWidth` default for width-invariant widgets + 3 totality guards, `20b37277`/tests
> `d3f3dc5eb`). Stage-D probe: 15469/15475 byte-exact, 0 throws; the 6 mismatches are ALL the deferred-relayout
> CONVERGENCE LAG in `macroWindowWithSimpleVerticalPanelResizesAsContentChanges` (the measure is the fixpoint
> PREDICTOR; the multi-pass arrange the one-step ITERATOR) = the Stage-E boundary, the FIRST departure from A/B's
> 0-mismatch precedent (INHERENT, not a bug). **NEXT = Stage C** (scroll-panel recursive `subWidgetsMergedFullBounds`
> consume — THE HARD KNOT; first BEHAVIOUR-TOUCHING + dpr2-torture-gated stage; probe in isolation first).
> This doc is the self-contained execution plan; written to be picked up cold.
>
> **Line numbers drift — grep the named symbol, never trust a line number here.** Anchors verified against
> `a5e89d1b` source. The MEASURE protocol now also has a base `Widget.preferredExtentForWidth` default
> (current extent) ~Widget:757, beside `rawSetWidthSizeHeightAccordingly` ~:750.

---

## §0 — Orientation + why this now

**Fizzygum** — CoffeeScript GUI framework ("web operating system") on a single HTML5 `<canvas>`, ~470 in-browser-
compiled global classes (no `require`/`import`; `nil`==`undefined`; one class per file, filename==class name).
Umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; three sibling repos: `Fizzygum/` (source +
build + `buildSystem/check-layering.js` lint), `Fizzygum-tests/` (165 macro SystemTests comparing SWCanvas SHA-256
screenshots **byte-exactly** + audit/torture harnesses), `Fizzygum-builds/` (generated — never hand-edit). Commands
via the path-correct `fg` wrapper from the umbrella root: `./fg build` · `./fg suite` (165, dpr1, ~1.3min) ·
`./fg gauntlet` (build+dpr1+dpr2+WebKit+12 apps) · `./fg test <name>` · `./fg recapture <name>`.

**Why now.** The owner's STANDING goal (memory `proper-layouts-elimination-goal`): "proper layouts" (measure →
non-notifying arrange → dirty-tree) is the goal in itself — COMPLETELY DELETE the layout suppression/convergence
mechanisms, not relocate/rename them. The boolean-deletion roadmap (`proper-layouts-eliminate-suppression-booleans-
plan.md`, Phases A–E) already deleted the `@_adjustingContentsBounds` flag (committed `3a1fb165`+`b52a0d6f`+
`a5e89d1b`, held). What REMAINS is the **re-fit seam** `_reFitContainerAfterRawGeometryChange`/`_reFitContainer`
and the red end-of-cycle capstone (18 off-pass pushes). The "convergence arc" (memory `fizzygum-convergence-arc-
feasibility`) scoped seam deletion: it breaks exactly 10 job-B tests and is gated on §4.1 (pure measure) + §4.2
(structural DAG) — NOT a seam-hoist, NOT §4.4 alone. **THIS doc is the §4.1 execution.**

---

## §1 — The root constraint and what §4.1 changes (assessment §2.4/§2.5/§4.1)

Every geometry accessor (`width()`, `height()`, …) reads the **applied** `@bounds` — there is no "what size would
this be" query. So a container that sizes to its content cannot *measure* it; it **mutates the child and reads the
result back** (`SimpleVerticalStackPanelWdgt._positionAndResizeChildren`: `rawSetWidthSizeHeightAccordingly(W)` then
`+= widget.height()`). That read-back forces synchronous `_reLayout`, the mid-pass `_invalidateLayout` throw, and the
re-fit seam — it is "the cause of most of the engine's complexity" (§2.4).

The framework already runs a **pure measure** on ONE path: horizontal stacks use `getRecursiveMinDim/DesiredDim/MaxDim`
(`Widget.coffee` ~:4049–4153) — no mutation, no read-back, no seam. The vertical/window/scroll/text path uses the
imperative mutate-read-back fixpoint (§2.5). **§4.1 generalises the pure measure to the side that hurts:** a side-
effect-free `preferredExtentForWidth(availW) → {w,h}` that NEVER touches `@bounds`, so `_positionAndResizeChildren`
sums MEASURED heights instead of mutating-and-reading-back. The container's size becomes a pure function of children's
measures → the synchronous "apply-then-see-it" (and the seam it fires) is no longer needed.

**Critical nuance — §4.1 alone does NOT delete the seam.** Even a pure-measure container still does ONE final geometry
commit (`silentRawSetExtent`/`fullRawMoveBy`) that fires the seam. Removing the fire needs the **non-notifying arrange**
(Stage E). And the seam's OFF-pass job-B notify (an external change to a freefloating child's container) is replaced
by the §4.4 dirty-propagation (Stage E). So the seam-delete + capstone-green payoff lands at **Stage E**, not at the
end of §4.1's measure work.

---

## §2 — The Stage-0 evidence (the gate that greenlit this — DONE 2026-06-28)

The campaign's load-bearing risk is byte-exact text measurement ("CSS/Flutter/WPF all special-case it"). A throwaway
probe settled it WITHOUT production commitment:

- A pure `measureWrappedHeight(availW)` threaded `availW` into the **already-pure** `breakTextIntoLines`
  (`TextWdgt.coffee` ~:307 — writes only width+font+text-keyed memo caches, returns `[lines,slots,maxW,height]`; the
  ONLY geometry input is `widgetWidth = @width()` at ~:321) via an optional `widthOverride` param, replicating
  `silentRawSetExtent`'s `max(round(W), minExtent.x)` clamp (`Widget.coffee` ~:1615/~:1618); NO `@bounds` touch.
- It was differential-tested against the real commit path at `TextWdgt.rawSetExtent` — the chokepoint EVERY container
  width-set funnels through (`rawSetWidth` for the scroll path; `rawSetWidthSizeHeightAccordingly` for stack/window).
- **Result: full suite 165/165 (probe non-perturbing); 44 of 165 tests exercise wrapping text; 4022 measure-vs-commit
  differentials; 0 mismatches** (the 4 §3 tripwires alone = 680 / 0). Spanned `w=30→1935px`.
- **Byte-exactness is STRUCTURAL, not lucky:** `getTextWrappingData` NULLS the fit-check for `FIT_BOX_TO_TEXT` (~:207),
  so measure(`wrapW`) and commit(`@width()`=`wrapW`) build the SAME `getTextWrappingData` cache key → return the SAME
  tuple. Exactness reduces to "does the measure round+clamp to the width the commit lands on" — confirmed 4022×.

Probe fully reverted. Tooling kept in the session scratchpad (`stage0-prelude.js`, `run-tripwires.sh`,
`stage0-suite.sh`). **Conclusion: the wrap kernel is a pure fn of (text, font, width); the pure measure is faithful.**

---

## §3 — The design: `preferredExtentForWidth(availW) → Point`, pure, per family

A side-effect-free measure (no `@bounds`, no seam; only the benign keyed wrap memo). Built BOTTOM-UP because a
container's measure recurses into its children's measures.

| Family | Measure | Feasibility (from the verified code map) |
|---|---|---|
| **Leaf text** (`TextWdgt`/`SimplePlainText`) | `{w: maxLineWidth‖clampedAvailW, h: lines·⌈fontHeight⌉}` via `breakTextIntoLines` with `availW` threaded in | ✅ **GREEN — Stage-0-proven.** Kernel already pure; height formula `:297` ≡ commit `:424`. |
| **Vertical stack** (`SimpleVerticalStackPanelWdgt`) | `w=availW`, `h=Σ child.preferredExtentForWidth(getWidthInStack).h + padding` | ✅ **GREEN — already measure-clean.** Heights are already *handed-forward* (`:174`), not read back; lone applied read (`:196`) is a no-resize natural measure. |
| **Window** (`WindowWdgt`) | pick width (incoming/spec/own) → `contentH = @contents.preferredExtentForWidth(w).h` (or `@height()−chrome`) → `h=contentH+chrome` | ⚠ **AMBER — separable but tangled.** No child read-back into sizing, but bidirectional cases (`THIS_ONE_I_HAVE_NOW`/`DONT_MIND`/`canSetHeightFreely`) + 3 interleaved `_applyOwnArrangedWidth` (`:518/:527/:549`) must untangle to measure→one-commit. |
| **Scroll panel** (`ScrollPanelWdgt`) | content-frame = pure `subWidgetsMergedFullBounds` = recursive union of children's measures | ❌ **RED — the hard knot.** `subBounds` (`:361`) reads contents' children's APPLIED merged bounds after mutating them (`:335`/`:347`), feeding the frame size (`:405–407`). Irreducible without a RECURSIVE pure measure; gated on stack+text beneath it. In-file comment `:354–359` already names it. |
| **Horizontal stack** | already pure (`getRecursive*Dim`) | done — unify under the protocol name in Stage F. |

Two companion pieces (Stage E), without which the measure work does not pay off:
- **Non-notifying arrange** — the final geometry commit must NOT fire the seam (the measure already determined sizes).
- **Dirty-propagation (§4.4)** — `needsLayout`/`hasDirtyDescendant` climbs from a freefloating child to its container,
  replacing the seam's off-pass job-B notify (the 10 convergence-arc tests).

---

## §4 — Staging (bottom-up; each independently soak-gated + byte-exact; STOP if any can't be made byte-exact)

The seam is sound today — leaving it is a defensible fallback (one mechanism + a documented empirical-convergence
position, §2.6). Do NOT paper over a missed read-back by reinstating a suppression.

> **NB — the BREADTH-FIRST reshuffle (discovered at Stage B).** The composable stack measure recurses into ALL
> stack-child types, so `preferredExtentForWidth` is a GENERAL protocol (every width→height type + a base `Widget`
> default), built BOTTOM-UP but BREADTH-FIRST and **landed DEAD** (no consumer) one type at a time, with windows
> (D) before the scroll consume (C). So A/B/D are all measure-BUILDS (dead, byte-identical-proven by a throwaway
> differential probe); the first real CONSUME (a measure replacing a read-back, hence behaviour-touching) is **Stage
> C**, and the seam delete is **Stage E**. Original §4 wording ("B/D consume/untangle") is superseded by this.

- **Stage 0 — ✅ DONE.** Byte-exact text-measure probe (§2). GO.
- **Stage A — ✅ DONE (`a07f534a`).** The pure `TextWdgt.preferredExtentForWidth(availW)` + the `widthOverride` param
  on `breakTextIntoLines`. Dead. Byte-identical (gauntlet + gates).
- **Stage B — ✅ DONE (`ea9ffcef` / tests `7547c04b4`).** The composable **stack** measure
  `SimpleVerticalStackPanelWdgt.preferredExtentForWidth` (Σ children's measured heights) + parameterised
  `VerticalStackLayoutSpec.getWidthInStack(availableWidthOverride)` + **aspect** measures (clock=square / ratio) + a
  `WindowWdgt` stub. Dead. Differential probe 3252/0. 2 benign inspector recaptures.
- **Stage D — ✅ DONE (`20b37277` / tests `d3f3dc5eb`).** The REAL `WindowWdgt.preferredExtentForWidth` (content
  measured at its in-window width + title/resizer chrome) replacing the Stage-B stub + the **base
  `Widget.preferredExtentForWidth` default** (= current extent; width-invariant widgets measure to their current
  height, width→height widgets override) + **3 totality guards** (mid-construction / spec-less → current extent / raw
  availW). Dead. Differential probe 15469/15475 byte-exact, 0 throws; the 6 mismatches = the deferred-relayout
  CONVERGENCE LAG (the Stage-E boundary; the measure predicts the converged height the multi-pass arrange iterates
  toward). 1 benign inspector recapture. Gauntlet 165/165 dpr1/dpr2/webkit + apps; capstone 18; paint-readonly 0.
- **Stage C — ✅ PROBE GREEN + PRODUCTION CONSUME LANDED (2026-06-28; byte-identical, NOT committed — review pending).**
  The FIRST behaviour-touching + dpr2-torture-gated stage. **Production (3 edits):** base
  `Widget.subWidgetsMergedPreferredBounds(childMeasureWidth)` (side-effect-free twin of `subWidgetsMergedFullBounds`,
  same seeding, child SIZE from `preferredExtentForWidth`, for the bare-text-panel case) + a
  `SimpleVerticalStackPanelWdgt` override that also derives child POSITIONS purely (cumulative-stack + alignment, no
  `tight=false` viewport grow) + `ScrollPanelWdgt._positionAndResizeChildren` consuming the pure measure in the
  content-sizing branch (`@contents.width()` for a stack; `@contents.width()-totalPadding` for a bare text panel),
  the folder/toolbar else-branch keeping the applied read-back. **Verified: build 0; gauntlet dpr1/dpr2/WebKit 165/165
  + apps; capstone 18 UNCHANGED; paint-readonly 0; 1 benign inspector recapture (`macroDuplicatedInspectorDrives
  CopiedTargetOnly`, new `Widget` base method in the inherited-member list — LOOK-confirmed, Stage-D pattern).** 20-min
  dpr2 torture gold gate ✅ GREEN (10 iters, 0 flaky, "No nondeterminism observed", RECALC_NONCONVERGENCE 0). STAGE C
  FULLY VERIFIED — awaiting owner commit approval (held). `ScrollPanelWdgt._positionAndResizeChildren` (~:324) sizes its content-frame from
  `subBounds`=`subWidgetsMergedFullBounds` (~:361) AFTER mutating the contents (~:335 recurse, ~:347 text re-wrap),
  feeding the frame (~:405-407). The pure replacement = a recursive children-union built from children's
  `preferredExtentForWidth` (now on stack/text/window/aspect + the base default). **Throwaway differential probe (in
  `ScrollPanelWdgt`, reverted; driver `scratchpad/stageC-suite.sh`, token STAGEC): 7169 differentials / 44 tests
  (1062 stack + 6107 text), CONVERGED-state height mismatches 0/1429, width 0, TRANSIENT height 0/5740, 0 throws,
  suite 165/165 (non-perturbing).** Feasibility PROVEN for the load-bearing EXTENT. Three probe-formula facts (each a
  fix, not a feasibility failure): (1) the scroll's stack content is `tight=false`, so the stack's OWN
  `preferredExtentForWidth` grows to `@height()` (viewport-grown frame) — WRONG for the scroll frame; compute the
  NATURAL children union = `Σ measuredChildH + (n-1)*stackPad`. (2) free-width stacks (`constrainContentWidth=false`)
  keep children at natural width-invariant size — measure must branch and read `widget.height()` (mirrors the stack
  measure's else-arm). (3) clamp each measured child extent to `minimumExtent` (`(5,5)`) as `silentRawSetExtent` does.
  Padding fact: `ScrollPanelWdgt.padding:0` + `PanelWdgt.extraPadding:0`; `SimpleVerticalStackScrollPanelWdgt`
  `extraPadding=5` → `scrollPad=5=stackPad`; the union signal is scrollPad-INDEPENDENT. **Remaining production risk =
  the POSITIONED rectangle: `subBounds` origin feeds the centered-icon merge (~:391) + the toolbar/folder else-branch
  (~:401); reconstructing the origin purely (vs the proven extent) is the revert-prone part.** The production consume
  must then pass the **dpr2 torture gold gate** (20-min soak, no `RECALC_NONCONVERGENCE`) + full gauntlet/gates.
- **Stage E — non-notifying arrange + §4.4 dirty-propagation → DELETE the seam → capstone greens.** The convergence-arc
  payoff. Re-run the convergence-arc probe in reverse: the 10 job-B tests must converge + match WITHOUT the seam, the
  capstone drops to 0, dpr2 torture shows no `RECALC_NONCONVERGENCE`.
- **Stage F — §4.2 structural-DAG lint.** Classify each layout edge by axis/direction; a `check-layering.js` rule
  forbids a width↔height coupling on the same widget's same axis. `recalcIterationsCap` downgrades to a never-fire
  assert. Defer unless wanted.

(NB the §4.1 "Stages A–F" here sit AFTER the completed boolean-deletion roadmap "Phases A–E"; distinct numbering.)

---

## §5 — Verification protocol (MANDATORY for any stage that consumes the measure or touches the seam)

1. `./fg build` — 0 violations/warnings.
2. `./fg suite` — dpr1 165/165. On a pixel failure, dump + LOOK (don't recapture blindly):
   `node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`, Read the PNGs.
3. `./fg gauntlet` — dpr1/dpr2/WebKit 165/165 + apps 12/12.
4. **dpr2 torture — THE GOLD GATE (from Stage B on):** `node scripts/torture-headless.js --dprs=2 --speeds=fastest
   --shards=4 --minutes=10 --out=.scratch/torture` → "No nondeterminism observed", failures dir empty, and grep
   `RECALC_NONCONVERGENCE` ABSENT. `pkill -9 -f "Chrome for Testing"` first; rebuild first (stale-build canary).
5. **Capstone gate** (`bash scripts/end-of-cycle-audit/run-capstone-gate.sh ; echo "EXIT $status"`) + **paint-read-only
   gate** (`bash scripts/paint-readonly-audit/run-paint-readonly-gate.sh ; echo "EXIT $status"`). Do NOT pipe a gate's
   exit into tail/grep — dump to a file, echo `$status`, read.
6. **20-min determinism soak** before declaring a convergence-touching stage (B/E) done.

Determinism contract + convergence bug-class case law: `Fizzygum-tests/DETERMINISM.md`. Recapture: byte-exact → none;
deliberate pixel change → owner approval first; a benign inspector member-list shift is the one pre-authorised class
(Stage-0 proved adding `preferredExtentForWidth` to `TextWdgt` is byte-identical, so no inspector recapture expected).

---

## §6 — Honest caveats / risk gates

- **Stage C (scroll-panel recursive subBounds) is the real remaining risk** — unproven; probe it in isolation first.
- **Aspect-locked nested content is a TRUE width↔height cycle** (square clock in window-in-window). Measure does NOT
  remove it — it is irreducible in any single-pass system, ALREADY cycle-broken by `elasticity 0` (assessment
  §2.5/OVERVIEW §5). Leave that fix in place; do not measure through it.
- **High reversal density** — this terrain has bitten twice (the soft-wrap §5 minefield; the text-slice
  falsification). Probe each stage; expect some reverts.
- **Do NOT re-attempt** (assessment "do not revisit"): Path A pending-aware accessors; reformulating the `wEl/wStk`
  proportion fraction; routing `ScrollPanelWdgt.add` through the batch tier; the **text-SCOPED** measure as a flag/seam
  retirement (falsified — `retire-adjustingContentsBounds-via-text-measure-plan.md`; the GENERAL measure here is
  different — it retires the `subBounds` children's-applied-bounds read-back).

---

## §7 — Anchors (grep the symbol; numbers drift; verified vs `a5e89d1b`)

- **Pure measure seed:** `Widget.coffee` `getRecursiveDesiredDim`/`getRecursiveMinDim`/`getRecursiveMaxDim` ~:4049–4153
  (horizontal-stack children only; caches written but reads commented-out — dead today). Arrange consumer: base
  `Widget._reLayout` 3-case ~:4199–4370 (consumes min/desired/max, feeds each child a full rect via `C._reLayout`).
- **The read-back primitive:** `rawSetWidthSizeHeightAccordingly` `Widget.coffee` ~:750 (`@rawSetWidth` →
  `@_reLayout()` → returns `@height()`). `rawSetWidth` ~:1709 → `@rawSetExtent(new Point width, @height())`.
- **Text wrap kernel (Stage A/B):** `TextWdgt.coffee` `breakTextIntoLines` ~:307 (pure; `widgetWidth=@width()` at
  ~:321 — the coupling parameterised; `widthOverride` added Stage A), `getTextWrappingData` ~:201 (NULLS fit-check for
  FIT_BOX_TO_TEXT ~:207; height `=lines·⌈fontHeight⌉` ~:297), `_reLayoutSelf` ~:409 (the COMMIT: `silentRawSetExtent`
  ~:433, height ~:424), `rawSetExtent` ~:441 (`super` then `_reLayoutSelf` for FIT_BOX_TO_TEXT),
  `preferredExtentForWidth` (NEW, Stage A). Width transform: `silentRawSetExtent` `Widget.coffee` ~:1609
  (`round()` ~:1615, min-extent clamp ~:1618). `getMinimumExtent` ~:1557.
- **Container read-back sites (Stage B/C/D):** `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` ~:133
  (hand-forward `:174`, residual read `:196`, own-size `:203`); `VerticalStackLayoutSpec.getWidthInStack` ~:31
  (`width = wEl + elasticity·(availW·wEl/wStk − wEl)`); `WindowWdgt._positionAndResizeChildren` ~:482 (incoming reads
  `:513/:545`, hand-forward `:557/:563`, 3× `_applyOwnArrangedWidth` `:518/:527/:549`, height `:590`);
  `ScrollPanelWdgt._positionAndResizeChildren` ~:324 (**subBounds read-back `:361`**, commit `:405–407`, recurse
  `:335`, text re-wrap `:347`; `keepContentsInScrollPanelWdgt` ~:418 is a position clamp, NOT sizing).
- **The seam (Stage E target):** `_reFitContainerAfterRawGeometryChange` `Widget.coffee` ~:1662 (`isLayoutInert` skip
  ~:1670), `_reFitContainer` ~:1701 (in-pass `_markForRelayoutNoClimb` ~:1704 / off-pass `_invalidateLayout` ~:1706;
  `_adjustingContentsBounds` check GONE). Fired by `fullRawMoveBy` ~:1294 + `silentRawSetExtent` ~:1642. Settle loop:
  `_recalculateLayoutsBody` ~:924 (until-loop, cap `100000`→`RECALC_NONCONVERGENCE`). Capstone: `auditUndeclaredEnd
  OfCycle`/`_undeclaredEndOfCyclePushes` on `WorldWdgt`.
- **Authoritative analysis (READ):** `docs/layout-system-architecture-assessment.md` §2.4/§2.5/§4.1/§4.2 (owner WIP —
  do NOT commit/restructure). Companion (why the text-SLICE can't do it): `retire-adjustingContentsBounds-via-text-
  measure-plan.md`. Roadmap: `proper-layouts-eliminate-suppression-booleans-plan.md`. Memories:
  `fizzygum-convergence-arc-feasibility` (incl. the Stage-0 result), `proper-layouts-elimination-goal`,
  `fizzygum-adjustingcontentsbounds-flag`, `fizzygum-layering-naming-tiers`.

---

## §8 — Owner principles + workflow

- **Measure, don't mutate-and-read-back.** If a "measure" touches `@bounds` or fires the seam it has failed. Applied
  accessors stay untouched (this is NOT Path A).
- **Staged + soak each stage; STOP and leave the seam if a stage can't be made byte-exact.** Never big-bang.
- **Review-driven.** Run a stage straight through verifying continuously; present ONE review per stage (Stage A is the
  first). **ASK before each commit AND push** — present the diff + message, wait. `git commit -F <file>` (never
  backticks/`$()` in `-m`); verify with `git log -1 --format=%B`. End commit messages with the
  `Co-Authored-By:`/`Claude-Session:` trailers. Push each repo from its own dir.
- **Clean/elegant code > dodging a benign inspector recapture** (just recapture).
- **Shell:** Bash runs FISH (`$status`); cwd may reset — `cd /abs/… && …`; a PreToolUse guard blocks a cross-repo
  `cd`-then-`Fizzygum-tests/scripts` chain (run via `fg` or a driver script). Kill orphan `Chrome for Testing` before
  any suite/torture/audit. Never pipe a gate's exit into tail/grep. Plan docs stay UNTRACKED.
