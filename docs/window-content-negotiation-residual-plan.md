# Plan — the last proper-layouts residual: 8 `WindowWdgt` content-negotiation re-visits

> ## ✅ RESULT (2026-07-01) — the WASTE half is ELIMINATED; the residual is now the 3 GENUINE convergences
> The 9 re-visits SPLIT cleanly: **6 were WASTE (a window over STACK content) — now eliminated byte-exact; 3 are
> GENUINE width↔height convergences (a window over a NESTED WINDOW / aspect content) — correctly retained.**
> Suite-wide window re-visits **9 → 3.**
> - **Mechanism (instrument-and-LOOK, reverted):** a fit-to-content window is laid out BEFORE its content settles.
>   Content climbs → invalidates the window; the LIFO work-list pops the window first, so it reads the content's
>   STALE height; the content settles as its own chain-top; the settle-time re-fit re-visits the window. Root
>   asymmetry: `_setWidthSizeHeightAccordingly` settles DEFERRED-layout content synchronously (window-over-scroll is
>   already one-pass), but a stack pins `implementsDeferredLayout` false → stale read → re-visit.
> - **Fix (§4a-adjacent, the byte-exact one):** `WindowWdgt._positionAndResizeChildren` settles NON-deferred stack
>   content synchronously DURING the window's arrange — the SAME `_reLayout()` the settle loop would call one
>   iteration later, so byte-exact. Excludes window-as-content via the `_reLayoutMayResizeOwnWidth` capability (NOT a
>   type test): settling a window early re-negotiates its OWN width (an outer window collapses an inner window to its
>   content's aspect width — confirmed by dump+LOOK), so those re-visits are a REAL convergence, left to the settle loop.
> - **Falsified (§4b, reverted):** the general "non-freefloating content of a size-tracking container does NOT
>   climb-enqueue it; the settle-time re-fit handles it" broke 9 load-bearing tests (the same scroll/stack/window set as
>   the geometry-seam falsification) — the content→container climb is load-bearing.
> - **Verified:** gauntlet dpr1/dpr2/webkit 165/165 + apps/tiernaming/settle; danger torture 12/12 (RECALC absent, 0
>   fails); build 0 violations; 0 inspector recaptures. Diff: `WindowWdgt.coffee` +25 (the early-settle + the capability).
> - **The remaining 3 (nested-window content) were then CHASED (2026-07-01, owner-requested) and proven IRREDUCIBLE
>   — do NOT re-attempt.** Instrument-and-LOOK (window-state trace, reverted) showed ALL 3 are CONSTRUCTION-TIME
>   FIRST-PLACEMENT re-visits: in every re-visit flush the inner window is `contentNeverSetInPlaceYet=true` (its content
>   — a clock / text — is being placed for the FIRST time), e.g. `Outer[563x339] content=Inner[cnsipy=true] → Inner
>   settles 553x303→180x206 → Outer re-fits`. Irreducible three ways: (1) can't MEASURE ahead — `WindowWdgt.preferredExtentForWidth`
>   returns stale extent for `cnsipy=true` BY DESIGN (uninitialised nested specs would NaN); (2) can't SETTLE early — pulling
>   the inner's first placement into the outer's arrange is not byte-exact (breaks the clock/nested images, proven); (3) can't
>   REORDER — the content-before-container climb-block breaks 9 load-bearing tests. They are ONE-TIME construction costs
>   (first placement happens once per nested window), not steady-state waste. **BANK them — the proper-layouts arc is
>   COMPLETE.** §1–§6 below are the original cold-start plan, now historical.

**Status: DONE — stack half eliminated 2026-07-01; nested-window half banked as genuine.** (Originally: SCOPED, NOT
STARTED.) This was the FINAL residual of the "proper-layouts" arc. The convergence-boolean MANDATE is COMPLETE (Stage 6 —
the cap is a never-fire assert). **Line numbers drift: grep the named symbol.**

---

## §0 — Orientation
**Fizzygum** = CoffeeScript GUI framework on one `<canvas>` (Morphic descendant). Umbrella
`/Users/davidedellacasa/code/Fizzygum-all/` (NOT a git repo) holds sibling repos `Fizzygum/` (source),
`Fizzygum-tests/` (165 byte-exact SWCanvas macro SystemTests), `Fizzygum-builds/` (generated). `nil`==`undefined`;
one class per file. Commands via `./fg` from the umbrella root: `./fg build` · `./fg suite` · `./fg gauntlet` (build +
dpr1 + dpr2 + webkit + apps + tiernaming + settle). A PreToolUse guard blocks wrong-cwd `Fizzygum-tests/scripts` runs
and piped builds — use `./fg`, or build from `Fizzygum/` and run scripts from `Fizzygum-tests/` as SEPARATE steps.

## §1 — Why this is what's left
The proper-layouts arc deleted the notify-by-mutation re-fit seam (property + geometry) and replaced it with a
**settle-time up-edge** in the settle loop (`WorldWdgt._recalculateLayoutsBody`): after a chain-top `_reLayout`s, if
its frame CHANGED, `_reFitMyTrackingContainerAfterSettle` re-fits its size-tracking container from the just-settled
(final) geometry — a bounded O(depth) up-walk, no fixpoint iteration. **Stage 6** (`d1e52506`) retired the convergence
cap to a never-fire loud-throw assert and added a NO-OP EARLY RETURN (skip the up-edge when the chain-top's frame is
unchanged), cutting peak per-flush re-visits 10→2. The **caret scroll-follow** residual (372 re-visits) was then driven
to **0** (`7370c25a`; see `caret-scroll-follow-single-pass-plan.md`). What remains is this.

## §2 — FRESH MEASUREMENT (2026-07-01, instrument-and-LOOK, reverted)
Per-flush re-visit detector in `WorldWdgt._recalculateLayoutsBody` (a `__seen = new Set()` reset each call; log when a
widget is processed a 2nd+ time in one flush, with its class + frame before→after), suite at **dpr2**. Result:
**9 re-visits total, ALL `WindowWdgt`, ALL top-level (parent=WorldWdgt), ALL HEIGHT changes (width + position fixed):**
```
macroWindowWithSimpleVerticalPanelResizesAsContentChanges  6  chg=true   380x{361->286, 286->331, 331->346, 346->361, 361->376, 376->86}@505,48
macroWindowWithAClockInAWindowConstructionTwo              2  1 chg=true (563x339->242) + 1 chg=false (242->242 confirm)
macroWindowsNestedCollapsingUncollapsing                   1  chg=true   260x196->222@445,25
```
- **8 of 9 are `chg=true`** — the window GENUINELY resizes its height on the re-visit. These are ONE-ROUND
  negotiations: per content-change flush the window is laid out ONCE with stale content height, its content (a
  `SimpleVerticalStackPanelWdgt` / scroll panel) then settles, and the up-edge re-fits the window to the settled
  height (the re-visit). i.e. the window is a FREEFLOATING chain-top laid out BEFORE its content settled.
- **1 of 9 is `chg=false`** (ConstructionTwo confirm) — a terminal no-op re-visit (the only one structurally like the
  caret's old verify); trigger not chased (marginal).
- This IS the settle loop's own documented sub-optimality — grep the comment in `_recalculateLayoutsBody`: *"a
  freefloating widget might still need to be resized according to the size of its parent … the freefloating child will
  do its layout first according to the wrong size of the parent, and then the parent will have to re-layout it again,
  so the `_reLayout` of the freefloating child is called twice, the first time wrongly."*

## §3 — Why the caret trick does NOT transfer (owner asked)
The caret fix worked because the caret's re-visit was a REDUNDANT verify (`chg=false` — the caret's own reposition to
its slot is exact/idempotent, so "converge on the containers, not on my own move" removed the confirming pass). The
window re-visit is `chg=true`: the second pass does REAL work (reads the settled content and resizes). There is no
"my own move is exact, ignore it" to exploit — the window's re-fit IS the container work, and it genuinely changes.

## §4 — The two candidate angles (both prior-explored; treat as HYPOTHESES to re-probe, not promises)
### §4a — Pure POSITIONAL/height measure for the window's content (the "pure-measure wall")
Make the window compute its content's FINAL height WITHOUT laying it out first (a `subWidgetsMergedPreferredBounds`-style
pure measure of the window's content subtree), so the first window pass sizes correctly and no correction re-visit is
needed. **Prior status: this is the `§4.2` wall. The §4.1 pure-measure campaign built `subWidgetsMergedPreferredBounds`
for scroll panels, but dropping the applied `subWidgetsMergedFullBounds` read-back for free-positioned content BROKE 9
tests (`proper-layouts-4.4-ordered-downwalk-plan.md §8` #5). The seam's role is a multi-widget size↔position
convergence and was ruled effectively-irreducible; 5+ deletion paths FALSIFIED on the 06-29 tree.** Re-run those
reverse-probes on the CURRENT baseline (they were point-in-time) before trusting the verdict, but expect resistance.

### §4b — Settle-loop ORDERING: don't lay out a freefloating chain-top before its invalid content
The re-visit is literally "freefloating window laid out before its content settled." The walk-up
(`while tryThisWidget.parent? … break if isFreeFloating() or parent.layoutIsValid`) stops AT the freefloating window,
so the window `_reLayout`s first; its content is independently enqueued, settles later, and up-edges back. HYPOTHESIS:
if the content settled FIRST, the window would re-fit once. ⚠ The geometry-seam crack found you must NOT gate the
up-edge on freefloating (a nested non-freefloating window also re-fits its parent). This is the DOWN direction
(initial-layout ordering) which is different — but the ordered-downwalk plan (`proper-layouts-4.4-ordered-downwalk-plan.md`)
explored exactly this space and hit walls. Re-read its §8 verdict FIRST. High reversal-density.

## §5 — HONEST expectation + verification
**Expect this to resist.** It is a GENUINE bounded convergence (8 real re-fits + 1 confirm), not waste; the mandate
(delete the suppression booleans) is already met; the cap is a never-fire assert; 9 bounded deterministic re-visits are
harmless. **Recommended default: BANK IT (leave the residual).** Only pursue if the owner wants the settle loop
provably single-pass as an end in itself, and then timebox a reverse-probe of §4a on the current tree before committing.
- Any attempt is a CONVERGENCE change: gate on `./fg gauntlet` (dpr1/dpr2/webkit 165/165 + apps/tiernaming/settle) AND
  the danger-config determinism torture (manual loop over `dpr2-fastest-s8`, `dpr2-fast-s8`, `dpr1-fastest-s8`,
  `dpr2-fastest-s4` × a few rounds; `RECALC_NONCONVERGENCE` absent + 0 fails; `torture-headless.js` deadlocks
  in-session — use the manual loop, pattern in a prior session's `scratchpad/torture-manual.sh`).
- Byte-exact or it does not ship; benign inspector recaptures pre-authorised. NEVER commit/push without owner approval.
- Re-measure with the §2 detector; target: WindowWdgt re-visits → 0 (or the irreducible minimum).

## §6 — Toolkit + references
- **Re-measure:** add `__seen = new Set()` at the top of `WorldWdgt._recalculateLayoutsBody`'s until-loop; log class +
  frame before/after when `__seen.has(tryThisWidget)`; `./fg build` (or `build_it_please.sh --keepTestsDirectoryAsIs
  --noSyntaxCheck`) then run the suite at dpr2 and tally (run-all-headless prefixes page `console.error` with
  `[shard N] SystemTest_<name>:`). Single-test fast loop: `LOG_FILE=<path> node scripts/run-macro-test-headless.js
  SystemTest_<name> --dpr=2` (it DOES surface `console.error` via `errors[]`/`LOG_FILE` — the "single-test runner
  drops console.error" note in older docs is STALE).
- **Anchors:** `WorldWdgt._recalculateLayoutsBody` (settle loop + walk-up + up-edge + no-op early-return);
  `Widget._reFitMyTrackingContainerAfterSettle` / `_reFitContainer`; `ScrollPanelWdgt._positionAndResizeChildren` /
  `subWidgetsMergedPreferredBounds` / `subWidgetsMergedFullBounds`; `WindowWdgt` (height fit-to-content).
- **Binding prior verdicts (READ before attacking):** `docs/proper-layouts-4.4-ordered-downwalk-plan.md §8` (the
  FALSIFIED-paths record), `docs/proper-layouts-4.2-structural-arrange-plan.md`, `docs/proper-layouts-geometry-seam-removal-plan.md`
  §5 Stage 6, and memory `fizzygum-next-work-backlog` (this residual) + `fizzygum-structural-arrange-arc` (the seam-stays verdict).
