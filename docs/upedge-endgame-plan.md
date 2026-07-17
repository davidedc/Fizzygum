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

*(empty — V0 starts here)*
