# The up-edge endgame + the last convergence-shaped boolean (authored 2026-07-17, to be executed COLD, owner-gated)

**STATUS: AUTHORED, no code. The natural sequel to the sizing-model unification (its §9.8 close
left exactly this residue). Design-first: stage V0 closes every decision on WTRACE evidence and
gates on the owner BEFORE any behaviour change. A full "everything is by-design, keep" close is a
LEGITIMATE outcome of this arc — the deliverable is a verdict per residual, not a mandatory
deletion count.**

## §0 — Cold context

Fizzygum = CoffeeScript GUI on one `<canvas>`; every class a global; `nil` == `undefined`.
Umbrella `/Users/davidedellacasa/code/Fizzygum-all/` (not a repo) holds `Fizzygum/` (source),
`Fizzygum-tests/` (250 macro SystemTests, byte-exact SWCanvas screenshots), `Fizzygum-builds/`
(generated). Commands via the cwd-safe wrapper, invoked by ABSOLUTE path
`/Users/davidedellacasa/code/Fizzygum-all/fg`: `fg build` / `fg presuite` (~2 min) /
`fg revisits` (~2.5 min, see below) / `fg gauntlet` (~5 min) / `fg census` / `fg status`. Long
ops: `run_in_background` + task notification; never foreground-poll. NEVER edit src mid-suite/
torture (the stale-build guard). Probes in `Fizzygum-tests/.scratch/` (node resolves `require`
from the script's dir). Two falsified fix shapes on one target = STOP and document (§6 grows).
Plan-authored-at state: Fizzygum `6cf063f3` / tests `787bcb322`, both pushed, all gates green.

Where the layout engine stands (post sizing-model unification, 2026-07-17): ONE constraint-box
sizing model everywhere; measures total; `contentNeverSetInPlaceYet` deleted; a container-owned
window never self-resizes width (§9.7-Q rule B2+D); construction width ping-pongs = 0. The ONLY
remaining multi-visit settles suite-wide are the **8 baseline flushes** asserted by the standing
gate `fg revisits` (`Fizzygum-tests/scripts/revisit-gate.js` + `scripts/audit-preludes/
revisit-prelude.js` + `scripts/revisit-baseline.json`) — all classified as bottom-up up-edges.
This arc examines exactly that baseline, plus the one remaining convergence-shaped boolean.

## §1 — What this arc is

Two bundled items (they share territory, instruments, and the gate):

**Item A — the 8 baseline up-edge flushes: convert to single-pass, or close as by-design.**
Per flush the deliverable is ONE of: (i) a byte-identical single-pass conversion (the baseline
then shrinks via a conscious `--write-baseline` + commit), or (ii) a documented BY-DESIGN verdict
(rationale recorded in the baseline's own documentation, §4-V2). Honest ROI framing up front:
each is a bounded ONE-TIME cost per user gesture (a drop, a resize, an uncollapse), not
steady-state waste — the value here is structural cleanliness and a semantically-labelled gate,
not performance.

**Item B — `WindowWdgt.reInflating`: delete, derive, or sanction.** The last flag in the layout
engine with a convergence-adjacent smell (the proper-layouts elimination goal — the owner's
standing direction — deleted every other suppression/convergence boolean; the 2 world phase
flags `_recalculatingLayouts`/`_inLayoutMutation` were VERDICTED load-bearing re-entrancy
2026-07-01 and are NOT in scope).

## §2 — The residuals as-built (verified in-tree 2026-07-17 @ `6cf063f3`)

### 2.1 The baseline profile (scripts/revisit-baseline.json — the study set)

| # | Test | Flush signature | Family |
|---|------|-----------------|--------|
| 1–5 | macroDropIntoRotatedStretchablePanelStretchesOnResize · macroDropIntoTiltedStackInsertsAtVisualSlot · macroDropKeepsHandOrientation · macroExplicitIslandFixedVsTrackingResize · macroTransformFrameSlotTracksContentResize | `TrackingTransformFrameWdgt:2` | island slot-track |
| 6 | macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow | `PanelWdgt:2;ScrollPanelWdgt:2` | scroll-uncollapse |
| 7–8 | macroWindowsNestedCollapsingUncollapsing · macroWindowWithAClockInAWindowConstructionTwo | `WindowWdgt:2` | window height re-fit |

`Class:2` = that widget's `_reLayout` entered twice at depth 0 in one flush: its ordinary settle
visit + the settle-loop up-edge re-fit (`_reFitMyTrackingContainerAfterSettle`, which already
no-op-skips when the settled chain-top's frame did not change — the Stage-6 skip).

### 2.2 Family 1 — the island slot-track (5 flushes)

`TrackingTransformFrameWdgt` (src/TrackingTransformFrameWdgt.coffee — read the WHOLE header, it
is the best-documented class in the tree) is the hugging-island tracking container: content is a
FREE-FLOATING child inside the island; the up-edge re-fits the slot to the content's FINAL bounds
after the content settles (`_reLayoutChildren`: slot ← child bounds, one-pass idempotent, sets
`@bounds` directly — the island slot-set idiom — with the Bug-D anchor-pinning / F1
arrange-driven anchor-nil logic). Its `_reLayout` = `super` + `@_reLayoutChildren()`;
`implementsDeferredLayout` pinned false (same reason as Stack/ScrollPanel — the pin family).
The second visit happens when the CONTENT settles after the island's own visit (parent-before-
child order guarantees exactly this for a content whose settle changes its bounds).
Conversion candidates to study (V0): (a) synchronous content settle inside the island's arrange —
the PROVEN window→stack-content shape (§6 precedent P2), maybe gated like that one was on the
content not re-fitting its own width; (b) accept by-design — a hugging parent definitionally
cannot know its slot before its free-floating content settles, and this is the up-edge the whole
engine formalizes. NOTE the transparency family (its `_applyExtent`/`_setWidthSizeHeightAccordingly`
forwards + the stale-extent guard) — any change must keep the DORMANT GUARANTEE (identity/empty ⇒
byte-identical to the base island) and the Bug-D/F1 anchor regimes intact.

### 2.3 Family 2 — the scroll-uncollapse pair (1 flush)

`PanelWdgt:2;ScrollPanelWdgt:2` in the collapse/uncollapse-scroll test. Mechanism NOT yet traced —
V0's first job (WTRACE). Known territory: `WindowWdgt._reactToChildUnCollapsed`
(src/WindowWdgt.coffee ~:466–478) applies the stored extents, runs the synchronous
`@_reLayoutChildren()` (layout-apply-sanctioned, "reInflating-coupled, must stay synchronous —
residuals-audit fam 4"), then `_invalidateLayout` + the scroll-GRANDPARENT invalidate
(`_amIDirectlyInsideNonTextWrappingScrollPanelWdgt` — the proper-layouts climb to a non-tracking
`@contents` PanelWdgt's scroll panel). The pair smells like: uncollapse re-fit → panel+scroll
settle → some frame change → up-edge re-fits both once more. Do NOT guess further; trace it.

### 2.4 Family 3 — the window height re-fit (2 flushes)

The §9.7-Q residue, precisely understood (sizing plan §9.7-Q outcome): fresh content dropped into
an embedded window → the inner window's height changes when its content settles → injection →
the OUTER window re-fits height once. Width is already structurally settled (rule B2). This is
the container-fits-content up-edge in its purest form; the V0 default expectation is BY-DESIGN,
but check whether the outer's first visit could measure-ahead the final height (the truthful
`preferredExtent` exists since U3-C shape 1 — why doesn't it prevent this pair? Likely because
the outer's first visit precedes the inner's content-settle in the same flush; confirm).

### 2.5 Item B — `reInflating` as-built

Declaration `WindowWdgt.coffee:30`; writers :468/:475 (set true around the uncollapse hook's
synchronous `_reLayoutChildren()`, cleared after); ONE reader :309 —
`contentsRecursivelyCanSetHeightFreely` returns `... and !@reInflating`: DURING re-inflation the
window treats its content as NOT free-height, so the arrange takes the content-dictated-height
branch instead of stretching the content to the stale (collapsed-era) window height. It is a
mid-operation MODE flag (an argument passed through instance state because the generic arrange
has no parameter channel), not an iteration suppressor. Candidates (V0 closes): (a) DERIVE — can
the arrange know "a re-inflation is in flight" from state (e.g. the stored
`extentWhenCollapsed`/`widthWhenUnCollapsed` fields being non-nil, cleared at the end of the
hook)? (b) RESTRUCTURE — order the hook's applies so the free-height branch reads correct
geometry without the mode; (c) SANCTION — rename/document as an explicit mode argument of the
uncollapse re-fit (fam-4's "must stay synchronous" verdict already sanctions the hook itself).
⚠ The residuals-audit fam-4 verdict is BINDING prior art: do not attempt to make the uncollapse
re-fit asynchronous.

### 2.6 Instruments (all exist; no new tooling needed to start)

- `fg revisits` — the standing gate; `--audit-dir=DIR` re-checks an existing audit dir;
  `--write-baseline` re-baselines (owner-sanctioned changes only).
- `scripts/audit-preludes/revisit-prelude.js` — the committed depth-0 re-visit counter.
- `Fizzygum-tests/.scratch/revisit-trace-prelude.js` — WTRACE: per-visit bounds before/after for
  re-visit flushes (the U3-C diagnostic; extend its class filter to TTF/Panel/ScrollPanel for V0).
- Single-test runs inject via `PRELUDE_JS=<file> node scripts/run-macro-test-headless.js
  SystemTest_<name> --all-logs` (fast loop; the prelude self-segments on the automator test name).
- Audit-dir runs: `AUDIT_PRELUDE=<f> AUDIT_DIR=<d> node scripts/run-all-headless.js` from the
  tests repo root.

## §3 — Decisions V0 must close (each with in-tree/WTRACE evidence)

- **E1 — island slot-track**: single-pass convertible (which §6 precedent shape, if any) or
  by-design? Per-test WTRACE first: confirm all 5 are the same mechanism (they may not be — the
  drop-flow ones vs the resize-flow ones may differ in who re-arms what).
- **E2 — scroll-uncollapse pair**: mechanism traced; convertible or by-design?
- **E3 — window height re-fit**: why doesn't the truthful measure-ahead prevent the pair?
  Convertible without re-opening §9.7-Q, or by-design?
- **E4 — `reInflating`**: derive / restructure / sanction (2.5's (a)/(b)/(c)).
- **E5 — the gate's vocabulary**: should the prelude TAG up-edge re-entries (the loop KNOWS when
  it calls `_reFitMyTrackingContainerAfterSettle`) so the baseline asserts
  `Class:2(up-edge)` vs `Class:2(unexplained)` — making a future genuine regression
  distinguishable from a sanctioned up-edge even when the class matches? (Instrument refinement,
  zero behaviour change; probably worth it regardless of E1–E3's outcomes.)

## §4 — Staging

- **V0 — the design assessment (no behaviour change).** WTRACE all 8 flushes (extend the trace
  prelude's class filter); write the per-flush mechanism table; close E1–E5 into §9 with
  evidence; OWNER GATE on the package (which conversions to attempt, which by-design verdicts to
  accept, the E4 pick).
- **V1 — sanctioned conversions only.** One at a time, smallest first; each: implement → build →
  presuite → `fg revisits` (drift EXPECTED = the improvement; verify the drift is exactly the
  predicted signature) → 1-round torture → conscious `--write-baseline` + commit (the baseline
  change and the code change in the SAME commit, message explaining the shrink). Stop-rule: two
  falsified shapes on one flush = it closes as by-design (§6 entry).
- **V2 — the close.** E5's tagging (if picked) + baseline re-write; the by-design verdicts
  documented IN `scripts/revisit-baseline.json`'s sibling doc block (extend revisit-gate.js's
  header or a `revisit-baseline.md` alongside — each baseline entry gets its one-line WHY);
  `reInflating` outcome landed; assessment §2.6 one-line touch if the baseline shrank; §9 close +
  arc-close gates.

## §5 — Verification protocol

Per V1 step: `fg build` + `fg presuite` + `fg revisits` + 1-round
`.scratch/stage-b-torture.sh 1`. Arc close: `fg gauntlet` + `fg census` + `fg revisits` +
3-round torture. Byte-identical is EXPECTED for every conversion (the up-edge re-fit computes
the same converged frame — a conversion only changes WHEN, not WHAT; any pixel drift falsifies
the shape). The known-benign inspector churn rule applies if any base Widget member is
added/deleted (→ `fg recapture-inspector`, or the 1-test method-churn set).

## §6 — Falsified prior art + proven precedents (do not re-derive)

**Binding falsifications:**
- Reordering the walk (content-before-container climb-block) breaks 9 load-bearing tests —
  falsified 2026-07-01, do not re-attempt.
- "Settle-early" of a window-as-content re-negotiates its own width — the
  `_reLayoutMayResizeOwnWidth` exclusion exists for this; under the post-§9.7-Q model the width
  half is gone but the HEIGHT half of that caution stands until proven otherwise.
- The residuals-audit fam-4 verdict: the uncollapse re-fit MUST stay synchronous.
- The sizing plan §6 list (esp. U3-C: a transient and a behaviour can share one code path —
  suppressing the path is not separating them; and rule B: never suppress a re-fit without
  pairing it with the state handoff that made it unnecessary).
- The stop-rule: 2 falsified shapes on one target ⇒ re-frame or close as by-design.

**Proven conversion shapes (the only two known to work, both landed + pushed):**
- **P1 — analytic one-shot** (caret scroll-follow 372→0, `CaretWdgt`, 2026-07-01): replace an
  iterative partial-step follow with computing the FINAL value directly; detect convergence on
  the INPUTS (containers moved?), not on one's own reposition.
- **P2 — synchronous settle inside the arrange** (window→stack-content 6→0, `1f035581`): run the
  SAME `_reLayout()` the settle loop would run one iteration later, inside the parent's arrange —
  byte-exact by construction; needs an exclusion for content whose own arrange re-negotiates its
  own frame.

## §7 — Symbol map

`TrackingTransformFrameWdgt` (`_reLayout`, `_reLayoutChildren(arrangeDriven)`, the transparency
forwards, the Bug-D/F1 anchor regimes) · `WorldWdgt._recalculateLayoutsBody` /
`_reFitMyTrackingContainerAfterSettle` (the up-edge + its unchanged-frame skip) ·
`WindowWdgt` (`reInflating` :30/:309/:468/:475, `_reactToChildUnCollapsed` ~:466,
`contentsRecursivelyCanSetHeightFreely` ~:299, `_amIDirectlyInsideNonTextWrappingScrollPanelWdgt`) ·
`ScrollPanelWdgt`/`PanelWdgt` (the uncollapse re-fit path; the `implementsDeferredLayout` pin is
PERMANENT — sizing plan §9.8 U4-6, do not touch) · the gate triplet
(`Fizzygum-tests/scripts/revisit-gate.js` / `audit-preludes/revisit-prelude.js` /
`revisit-baseline.json`). Authorities: `docs/sizing-model-unification-plan.md` §9.7-Q/§9.8/§6 ·
`docs/layout-system-architecture-assessment.md` §2.3/§2.6 + the rules section ·
`docs/deferred-layout-residuals-audit.md` (fam 4) · `docs/window-content-negotiation-residual-plan.md`
(the P2 precedent's full record).

## §8 — Success criteria

1. Every baseline flush carries an evidence-backed verdict: CONVERTED (byte-identical, baseline
   shrunk consciously) or BY-DESIGN (rationale documented next to the baseline).
2. `reInflating` deleted, derived, or explicitly sanctioned-with-rationale (E4).
3. The gate's baseline is semantically labelled (E5 outcome recorded either way).
4. No new re-visit signatures anywhere (`fg revisits` green at close on the final baseline).
5. All §5 arc-close gates green; zero unexplained pixel changes (conversions are byte-identical
   by definition; only inspector-churn recaptures are sanctioned).
6. §9 execution log written; the assessment's §2.6 touched only if the baseline shrank.

## §9 — Execution log

### V0 — the design assessment (2026-07-17, build @ `bc000008`; no behaviour change). ALL FIVE DECISIONS CLOSED.

**Instruments** (all `Fizzygum-tests/.scratch/`, gitignored): `upedge-trace-prelude.js` — the U3-C
trace prelude extended with (a) OBJECT-KEYED serial ids (`~sN`, WeakMap) because `uniqueIDString`
COLLIDES (see E2), (b) a MECHANISM TAG per depth-0 visit (`walk` / `up-edge armedBy=<id>` /
`child-heal parent=<id>` / `sched via=<stack>` — wrapping `_reFitMyTrackingContainerAfterSettle`,
`__reLayoutOneSettleNode` nesting, `_scheduleRelayoutRespectingPhase`, `__markForRelayout`),
(c) per-visit parent+root ids, (d) the WindowWdgt exclusion-predicate snapshot
`{fp coll mrw civ}` (first-placement pending / contents collapsed / `_reLayoutMayResizeOwnWidth` /
contents layoutIsValid), (e) the E4 `RIPROBE` wrap (below), (f) collision-proof `REVISIT2` lines
for EVERY flush suite-wide. Runner `run-upedge-traces.sh` (8 single-test runs) + one full-suite
audit over the AUDIT_PRELUDE rails (250/250 PASSED).

**The per-flush mechanism table** (single-test WTRACE, cross-checked by the full-suite audit):

| # | Test (flush) | Trace (abridged) | Mechanism |
|---|---|---|---|
| 1 | DropIntoRotatedStretchablePanel (i=85) | TTF#1[walk] `=` → SWC#1[walk] 300×300→420×420 → SP#1[child-heal] `=` → **TTF#1[up-edge armedBy=SWC#1]** re-hug | island slot-track up-edge |
| 2 | DropIntoTiltedStackInsertsAtVisualSlot (i=108) | TTF#1[walk] `=` → stack#2[walk] h+35 → 2 rect child-heals `=` → **TTF#1[up-edge armedBy=stack#2]** re-hug | same |
| 3 | DropKeepsHandOrientation (i=153) | TTF#2[walk] `=` → Rect#5[walk] 70×46→130×90 → **TTF#2[up-edge armedBy=Rect#5]** re-hug | same (leaf content) |
| 4 | ExplicitIslandFixedVsTrackingResize (i=40) | identical shape to #3 | same |
| 5 | TransformFrameSlotTracksContentResize (i=38) | identical shape to #3 | same |
| 6 | ScrollPanel…ClosingWindow | **NO re-visit exists** under collision-proof ids | GATE FALSE POSITIVE (E2) |
| 7 | WindowsNestedCollapsingUncollapsing (i=175) | outer[walk `{fp=false civ=false}`] `=` → inner[walk `{fp=true mrw=true}`] h+11 → content/handle heals `=` → **outer[up-edge armedBy=inner]** h+11 | FIRST-PLACEMENT nested window: the §6 P2-exclusion residual |
| 8 | WindowWithAClockInAWindowConstructionTwo (i=181) | same shape, inner h−97 (clock dictates), outer h−97 | same |

All up-edge tags are OBJECT-keyed (the armed widget is the very object re-visited), so families
1 and 3 are proven genuine same-object re-visits; the tag design worked in anger.

**E1 — island slot-track: CONVERTIBLE, shape P2 (sync-settle-in-arrange).** All 5 are ONE
mechanism regardless of flow (drop or resize) and content kind (composite or leaf): parent-before-
child walk visits the island first, the re-hug no-ops on the content's STALE bounds (`=` in every
trace), the free-floating content then settles itself (consuming its own pending state — the
island hands it nothing), and its up-edge re-arms the island for the real re-hug. P1 does NOT
apply (the slot needs the content's settled BOUNDS — position included — which no pure measure
reports). The P2 form: in `TrackingTransformFrameWdgt._reLayout`, between `super` and
`@_reLayoutChildren()`, synchronously settle a pending content —
`content._reLayout() if content? and !content.layoutIsValid and !content._reLayoutMayResizeOwnWidth?()`.
Gate notes: do NOT copy the window's `implementsDeferredLayout` exclusion — there it means "Path B
already settled deferred content"; the island drives NO sizing protocol, and content #1
(StretchableWidgetContainerWdgt, own `_reLayout`, no pin) is deferred-classified, so copying the
exclusion would miss flush 1. Do NOT gate on `transformSpec.isIdentity()` — the sync-settle
extends the TRACKING capability (which hugs at identity too — flush 4's island), not the §5a
transparency family; the DORMANT GUARANTEE (identity ⇒ super on the four transparency overrides)
is untouched. Keep the `_reLayoutMayResizeOwnWidth?()` exclusion for a hypothetical window-as-
island-content (none in the suite; costs nothing; keeps §6 respected). Predicted gate drift:
all 5 `TrackingTransformFrameWdgt:2` signatures vanish.

**E2 — scroll-uncollapse pair: GATE INSTRUMENT FALSE POSITIVE — there is no re-visit.** With
object-serial ids the flush disappears entirely (single-test AND full-suite). Anatomy: the
basement is OFF-TREE and SURVIVES `resetWorld` (only `.empty()`'d, WorldWdgt:2363-2366) while
`fullDestroyChildren` RESETS the per-class `lastBuiltInstanceNumericID` — so the basement
viewer's boot-era ScrollPanelWdgt/PanelWdgt/SliderWdgt keep pre-reset instance numbers that a
test's widgets are RE-ISSUED. `Widget.close()` re-homes the closed figure into the basement
(Widget.coffee:517 `_addLostWidgetNoSettle`), so the close-window flush settles BOTH the
window-side pair (at desktop coords) and the basement trio (at basement-local coords) — five
distinct objects, each visited ONCE, counted as `PanelWdgt:2;ScrollPanelWdgt:2` by uniqueIDString.
FIX (instrument-only): key the committed `revisit-prelude.js` flush map on the WIDGET OBJECT
(the map is per-flush, so object keys are exact); baseline entry 6 is then DELETED. Collisions
can only INFLATE counts, never mask a genuine re-visit (same object ⇒ same id regardless), so
the fix is strictly de-noising. Full-suite audit confirms: exactly 7 genuine re-visit flushes
suite-wide, all in the other 7 baseline tests — nothing new surfaces, nothing else vanishes.

**E3 — window height re-fit: CONVERTIBLE, shape P2 — by NARROWING the stale exclusion.** Both
flushes are FIRST-PLACEMENT flushes of a nested (container-owned) inner window — NOT collapse-time
(the collapsing test's re-visit is its construction flush; predicate snapshots prove it:
inner `{fp=true mrw=true civ=true}`, outer `{fp=false civ=false}`). Mechanism: the outer's
steady-state arrange reaches the WindowWdgt:766 sync-settle gate, which excludes the inner via
`_reLayoutMayResizeOwnWidth` (true while the inner's content spec is uncaptured); the inner then
settles on its own walk turn (first placement: capture + content-dictated height), and its frame
delta re-arms the outer. Measure-ahead CANNOT elide the second visit: the engine's up-edge is
gated on the CHILD's frame delta, so even an outer that fitted the final height in visit 1 gets
re-visited (as a no-op) — the count stays 2. The REAL fix is that the exclusion is OVER-BROAD
post-§9.7-Q: `_reLayoutMayResizeOwnWidth: -> !@contents?.layoutSpecDetails?.desiredWidth?`
answers true for ANY pre-capture window, but under rule B2+D a CONTAINER-OWNED window NEVER
self-resizes width — only an own-freefloating one hugs (WindowWdgt:706's own-layoutSpec gate).
Narrow it to `@layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING and !@contents?.layoutSpecDetails?.desiredWidth?`
and the container-owned inner early-settles inside the outer's arrange exactly like a stack
content (the landed P2 precedent `1f035581`); the §6 width caution is preserved verbatim for the
only class it was ever real for (desktop windows mid-hug). Predicted gate drift: both
`WindowWdgt:2` signatures vanish. (With E1+E3 both landed the baseline is EMPTY.)

**E4 — `reInflating`: LOAD-BEARING today; derive is FALSIFIED; recommend RESTRUCTURE to an
explicit parameter (fallback: sanction-with-rename).** The RIPROBE wrap (momentarily clear the
flag, re-ask the original predicate, restore — pure observation) over the FULL suite: **13 FLIP
events across 7 collapse/uncollapse tests** (`actual=false without=true` — with the flag the
arrange takes the content-dictated-height branch; without it, it would stretch the content to
`@height() − chrome` mid-re-inflation), plus 5 inert `call-during` events (nested-window
recursion — the outer's flag is never the deciding term, WindowWdgt:310 branch). So the term
still decides branches: plain deletion is OFF the table. (a) DERIVE is statically falsified:
the candidate fields `extentWhenCollapsed`/`widthWhenUnCollapsed`/`contentsExtentWhenCollapsed`
are NEVER cleared (read on every subsequent un/collapse), so field-nil-ness would leave the
"mode" permanently on after the first collapse. (b) RESTRUCTURE: the flag's true lifetime is
exactly ONE synchronous call (`_reactToChildUnCollapsed`'s `@_reLayoutChildren()`), and the
reader is only ever the SAME window's arrange — a textbook argument-passed-through-instance-state.
Thread it as a real parameter instead: the hook calls `@_positionAndResizeChildren true`
(it IS the window's `_reLayoutChildren` dispatch target, and the hook is already
layout-apply-sanctioned), `_positionAndResizeChildren (duringReInflation = false)` passes it to
`contentsRecursivelyCanSetHeightFreely (duringReInflation = false)` whose term becomes
`!duringReInflation`; every other caller (the :161 measure, the :310 recursion) passes nothing.
Instance flag DELETED; behaviour identical by construction; the last convergence-adjacent
boolean falls, per the proper-layouts standing direction. (c) SANCTION (keep + rename to e.g.
`_unCollapseReFitInFlight` + doc block) remains the zero-risk fallback if the owner prefers not
to touch arrange signatures. `reInflating` origin: `597435e6` (2018-01-31) — it predates the
modern engine by 8 years; fam-4's "must stay synchronous" verdict is untouched by all candidates.

**E5 — gate vocabulary: identity fix MANDATORY (it IS the E2 fix); tagging into the failure
REPORT only, not the baseline format.** The trace prelude's tags proved their worth in anger
(they exposed the collision and attributed every mechanism), but if V1 lands E1+E3 the baseline
is EMPTY and there is nothing to label; keep `revisit-baseline.json` as plain `Class:count`
multisets and instead have `revisit-gate.js`'s FAILURE output remind the reader of the
mechanism-tagged trace prelude (`.scratch/upedge-trace-prelude.js`) as the diagnosis tool. If
the owner instead closes E1/E3 as by-design, THEN bake `Class:2(up-edge)` tags into the baseline
(the committed prelude gains the object-keyed up-edge arm tracking this trace validated).

**Proposed V1 (owner gate pending — order: smallest/safest first):**
1. **V1-a (instrument):** `revisit-prelude.js` object-keyed counting + delete baseline entry 6
   (tests repo only; zero behaviour change; `fg revisits` re-baselined consciously).
2. **V1-b (1-line):** narrow `_reLayoutMayResizeOwnWidth` (E3) — baseline −2 (`WindowWdgt:2` ×2).
3. **V1-c:** the TTF sync-settle (E1) — baseline −5; baseline now EMPTY.
4. **V1-d:** the E4 restructure (reInflating → `duringReInflation` parameter, flag deleted).
Each step: `fg build` + `fg presuite` + `fg revisits` (drift must equal the predicted signature
exactly) + 1-round torture; baseline+code in the SAME commit. Stop-rule §6 stands: 2 falsified
shapes on one flush ⇒ by-design close. Arc close per §5.

### V1 — execution (owner gate PASSED 2026-07-17: all four steps; E4 = restructure-to-parameter;
### E5 = report-only tags)

**V1-a ✅ LANDED** (tests `c1c6a2f75`): `revisit-prelude.js` counts by widget OBJECT (collision
warning documented in its header); baseline entry 6 deleted (7 entries remain); the
mechanism-tagged diagnosis prelude PROMOTED to committed
`scripts/audit-preludes/revisit-trace-prelude.js` (RIPROBE stripped — one-arc probe) and
`revisit-gate.js`'s failure output now points at it (the E5 report-only vocabulary).
Verified: full `fg revisits` green on the fixed prelude + 7-entry baseline.

**V1-b ✅ LANDED — `_reLayoutMayResizeOwnWidth` narrowed to own-FF** (WindowWdgt): predicate
gains `@layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING and`, comment rewritten with the B2+D
rationale. Gates ALL GREEN: build + presuite (250/250 byte-exact); `fg revisits` drift ==
EXACTLY the two predicted vanished `WindowWdgt:2` signatures (nothing else); baseline → 5
entries, re-checked green via `--audit-dir`; 1-round torture rc=0, both engine tokens absent.
A first-placement nested window now settles inside its outer's arrange — one visit each.
(Fizzygum `452c0ecd` / tests `2560d1f83`.)

**V1-c ✅ LANDED — the TTF sync-settle** (TrackingTransformFrameWdgt._reLayout: settle a pending content
between `super` and the re-hug; the two V0 gate notes — no implementsDeferredLayout gate, no
transform-state gate — are the comment). Gates: build + presuite green (250/250 byte-exact);
`fg revisits` drift == EXACTLY the five predicted vanished `TrackingTransformFrameWdgt:2`
signatures (nothing else); **baseline → EMPTY** (`{}`), re-checked green via `--audit-dir`;
`revisit-gate.js`'s header rewritten to the empty-baseline steady state (every former entry's
retirement rationale documented in place — the V2 "rationale next to the baseline"
deliverable); 1-round torture rc=0, both engine tokens absent. THE SETTLE ENGINE NOW VISITS
EVERY WIDGET AT MOST ONCE PER FLUSH, SUITE-WIDE. (Fizzygum `b2e09a59` / tests `f8a94c334`.)

**V1-d ✅ LANDED — `reInflating` → explicit `duringReInflation` parameter** (E4-b as owner-picked):
the instance flag (2018) is DELETED; `_reactToChildUnCollapsed` calls
`@_positionAndResizeChildren true` (the one caller that carries the mode), the arrange threads
`duringReInflation` (default false) into `contentsRecursivelyCanSetHeightFreely`, whose term is
now `!duringReInflation`; the measure and the nested-window recursion take the default. The last
convergence-adjacent boolean in the layout engine falls (the 2 world phase flags remain, verdicted
load-bearing 2026-07-01). Gates ALL GREEN: build + presuite (250/250 byte-exact — behaviour
identical by construction and by pixels); `fg revisits` green (the EMPTY baseline holds);
1-round torture rc=0, tokens absent. Deserialized pre-change worlds may carry an orphan
`reInflating` own-prop; nothing reads it.

**Tooling follow-on (owner-directed mid-arc): `fg revisits` is now a GAUNTLET WAVE-B LEG** (local
umbrella tooling, uncommitted by design): `run_leg revisits` = one dpr1 suite pass under the
counting prelude at `FG_GATE_SHARDS`, wave B = paint ∥ tiernaming ∥ settle ∥ capstone ∥ revisits
∥ refs, serial escape hatch + usage + umbrella CLAUDE.md updated. With the baseline EMPTY the
leg's assertion is "ANY re-visit anywhere = regression", enforced at every commit point; presuite
deliberately unchanged (the failure class is pixel-neutral — commit-point tier suffices).
