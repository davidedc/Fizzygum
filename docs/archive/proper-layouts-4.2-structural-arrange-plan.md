> **ARCHIVED — COMPLETE (2026-07-17 restructure).** CLOSED 2026-06-29 (per 4.4 §8) — seam-deletion FALSIFIED, seam STAYS; Stages 0-3 landed (capstone 18→0)
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Plan — §4.2 the STRUCTURAL arrange that deletes the re-fit seam (the convergence-arc payoff)

> **STATUS (2026-06-28). DESIGN PASS + Stage 0 (characterization probe) DONE — no production code yet; owner approved
> the design + Stage 0, deciding the per-stage plan below before implementation.** Stage 0's decisive finding: ALL 18
> capstone pushes are Intent-2 arrange self-re-enqueues (4 patterns) ⇒ the capstone greens via Objective A (the
> non-notifying arrange, Stages 1–3) ALONE, not via a separate self-settling stage; the 6/4 in-pass/off-pass job-B
> split is reconfirmed; see §4 Stage 0.
> §4.1 (the pure-measure campaign) is COMPLETE and committed-held (Stages 0/A/B/C/D — `preferredExtentForWidth` on
> every width→height widget + a base `Widget` default + the scroll-panel `subWidgetsMergedPreferredBounds` consume).
> This plan is the NEXT and BIGGEST arc — the assessment's "#1 and biggest change": restructure the arrange into a
> single **measure-up → non-notifying arrange-down** traversal so the notify-by-mutation re-fit **seam**
> (`_reFitContainerAfterRawGeometryChange` / `_reFitContainer`) can be DELETED, the end-of-cycle **capstone** greens
> (18 → 0), and the empirical fixpoint iteration (`recalcIterationsCap`) is retired. A multi-stage, determinism-
> critical, revert-heavy FOUNDATIONAL campaign — staged so every landing is byte-exact, soak-gated, and STOP-able.
>
> **Line numbers drift — grep the named symbol, never trust a line number here.** Anchors verified against
> `85d0c186` (the §4.1 Stage-C HEAD; src clean). Written to be executed COLD by an LLM/engineer with ZERO prior context.

---

## §0 — Orientation + why this now

**Fizzygum** — CoffeeScript GUI framework ("web operating system") on a single HTML5 `<canvas>`, ~470 in-browser-
compiled global classes (no `require`/`import`; `nil`==`undefined`; one class per file, filename==class name).
Umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; three sibling repos: `Fizzygum/` (source +
build + `buildSystem/check-layering.js` lint), `Fizzygum-tests/` (165 macro SystemTests comparing SWCanvas SHA-256
screenshots **byte-exactly** + audit/torture harnesses), `Fizzygum-builds/` (generated — never hand-edit). Commands
via the path-correct `fg` wrapper from the umbrella root: `./fg build` · `./fg suite` (165, dpr1, ~1.2min) ·
`./fg gauntlet` (build+dpr1+dpr2+WebKit+12 apps) · `./fg test <name>` · `./fg recapture <name>`.

**The standing mandate (memory `proper-layouts-elimination-goal`).** "Proper layouts" — a clean measure → non-
notifying arrange → explicit dirty-tree — is the goal **in itself**: COMPLETELY DELETE the layout suppression/
convergence mechanisms, not relocate/rename them. Filter every step: KEEP iff it paves the way to **deletion**;
REJECT anything whose payoff is "the mechanism is nicer to keep" (a rename, a balance assert, relocating into a
`world.layoutEngine` object — assessment §4.3).

**Where we are.** The boolean-deletion roadmap (`proper-layouts-eliminate-suppression-booleans-plan.md`, Phases A–E)
already DELETED the `@_adjustingContentsBounds` per-container suppression flag (committed-held `3a1fb165`/`b52a0d6f`/
`a5e89d1b`). The §4.1 pure-measure campaign (`proper-layouts-4.1-pure-measure-campaign-plan.md`, Stages 0/A/B/C/D)
then BUILT the pure measure and consumed it in the scroll panel (committed-held through `85d0c186`). **What REMAINS
is exactly this plan:** the **seam** `_reFitContainerAfterRawGeometryChange` / `_reFitContainer` STILL fires, the
end-of-cycle **capstone** is RED (18 off-pass pushes / 10 tests), and `recalcIterationsCap` is still load-bearing.
Deleting all three is "the convergence arc" — scoped in memory `fizzygum-convergence-arc-feasibility` and reconfirmed
empirically (below).

**THE BASELINE (reconfirmed on the live tree 2026-06-28).** A throwaway reverse probe — early-`return` in
`_reFitContainerAfterRawGeometryChange` (no-op the seam; callers kept so the dead-method gate passes), build, dpr1
suite — breaks **EXACTLY 10 tests**, identical to the feasibility memo's list:
- **7 scroll:** `macroEditingStringInScrollablePanelCaretAlwaysVisible`, `macroScrollPanelCaretBroughtIntoViewWhenMoved`,
  `macroScrollBarsTrackContentChange`, `macroNoSpuriousScrollbarsOnScrollPanelResize`,
  `macroLockedScrollPanelScrollsWhenDragged`, `macroScrollPanelInWindowMovesWindowWhenDragged`,
  `macroScrollPanelNotMovedViaNonFloatDragChild`.
- **3 window/stack:** `macroWindowWithAClockInAWindowConstructionTwo`, `macroWindowWithSimpleVerticalPanelResizesAsContentChanges`,
  `macroWindowsNestedCollapsingUncollapsing`.

These 10 are the **job-B work-list**: an EXTERNAL change to a freefloating content widget that its container must
re-fit to. The §4.1 MEASURE did **not** shrink this list (the reverse probe is identical pre- and post-§4.1) — because
the seam delivers the **notification** (when to re-fit), which the measure does not replace. **That notification is the
thing this plan replaces structurally.**

---

## §1 — The current machinery (ground truth — read before touching anything)

### 1.1 The per-frame spine + the settle loop
`WorldWdgt.doOneCycle` (~:1335): `playQueuedEvents` (dispatch input; whole-queue drain) → `recalculateLayouts` (the
end-of-cycle flush) → `updateBroken` (PAINT, read-only). `recalculateLayouts` (~:896) is a re-entrancy-guarded wrapper
over `_recalculateLayoutsBody` (~:924): an **until-loop** that drains `widgetsThatMaybeChangedLayout` —
```
until widgetsThatMaybeChangedLayout empty:                       (~:933)
  pop valid widgets off the tail
  take a dirty widget; walk UP parents while parent also dirty   (~:972)
      stop at a valid parent OR a FREEFLOATING boundary (~:973)   → "top of a broken chain"
  tryThisWidget._reLayout()    (~:982 — arrange that subtree top-down, each node markLayoutAsFixed)
```
Two facts make this a *fixed-point* loop, not a fixed number of passes (assessment §2.3):
1. **Invalidate climbs UP, layout flows DOWN.** `_invalidateLayout` (~:3920) marks dirty + climbs to `@parent`
   (short-circuits iff the triggering child is freefloating — the param guard ~:3928). `_reLayout` ends in
   `markLayoutAsFixed` (~:4231), popping the node.
2. **A `_reLayout` can re-dirty something OUTSIDE the subtree it just settled, via the seam** (`_reFitContainer`
   ~:1736, in-pass arm `_markForRelayoutNoClimb` ~:1739). **This is the ONLY thing that produces genuine iteration**:
   a container the seam re-enqueues runs another `_reLayout`, and again, until the queue drains.

`recalcIterationsCap = 100000` (~:930) is the freeze-backstop → on non-convergence it logs `RECALC_NONCONVERGENCE`.

### 1.2 The seam (the crux)
**Every raw geometry setter fires a bottom-up re-fit notification:**
- `silentRawSetExtent` (`Widget.coffee` ~:1644) ENDS with `@_reFitContainerAfterRawGeometryChange()` (~:1677). ⇒
  *"silent" = no repaint / no self-relayout, NOT no notification.* (`silentRawSetBounds` ~:892 routes its extent
  through `silentRawSetExtent`, so it fires too.)
- `fullRawMoveBy` (~:1306) also fires it (~:1329).
- `_reFitContainerAfterRawGeometryChange` (~:1697): skip if `@isLayoutInert?()` (overlay chrome); else
  `_reFitContainer(@parent.parent)` if directly inside a non-text-wrapping scroll panel, then `_reFitContainer(@parent)`.
- `_reFitContainer(container)` (~:1736): `return unless container?._reLayoutChildren?` (only Window / Stack /
  ScrollPanel define it, so only they react); **in-pass** (`world._recalculatingLayouts`) → `_markForRelayoutNoClimb`
  (enqueue the directly-affected container, no climb); **off-pass** → `_invalidateLayout()`.

**The seam crosses the FREEFLOATING boundary.** Scroll/window CONTENT is freefloating (so it can be scrolled/moved
independently), so a content widget's own `_invalidateLayout` does NOT climb to its container (the freefloating
short-circuit). The seam is the explicit cross-boundary notification — content changed → container re-fits.

**THE SEAM HAS TWO FUSED INTENTS (the whole lever this plan pulls):**
| | What | When | Effect today | This plan |
|---|---|---|---|---|
| **Intent-2** | a container's OWN arrange mutates its children/content → the raw setter fires the seam at the container ITSELF | IN-pass (during a settle) → `_markForRelayoutNoClimb` (enqueue) | the **convergence ITERATION** ("92% pure-waste idempotent repeat arranges"); NOT a capstone push | **ELIMINATED** by the **non-notifying arrange** (the arrange applies via a primitive that does not fire the seam) |
| **Intent-1** | an EXTERNAL agent (drag, content edit, scroll, add) raw-mutates a freefloating content widget → the seam re-fits its container | OFF-pass → `_invalidateLayout` (the **18 careless capstone pushes**); or IN-pass for the 6 mid-settle cases | the **load-bearing job-B notification** (the 10 tests) | **REPLACED** by explicit self-settling invalidation across the content→container edge |

### 1.3 The three container arranges (the restructure targets)
Each defines `_reLayoutChildren` (the re-fit chokepoint the seam gates on) → `_positionAndResizeChildren` (the arrange
body). Each applies child/content/own geometry via **seam-firing** raw setters:

- **`SimpleVerticalStackPanelWdgt._positionAndResizeChildren` (~:204).** Per child:
  `widget.rawSetWidthSizeHeightAccordingly(W)` (~:245 — mutate child + synchronous `_reLayout` + HAND the height
  forward) then `widget.fullRawMoveTo(...)` (~:263 — move it; fires the seam). Own height via
  `@_applyOwnArrangedHeight(newHeight)` (~:274 — base `Widget::rawSetExtent`, fires the UP-notify seam to its parent,
  skips re-entering `_reLayoutChildren` — the Phase-E mechanism).
- **`WindowWdgt._positionAndResizeChildren` (~:527).** Lays out close/collapse buttons via `_reLayout(rect)` (~:535/541);
  sizes `@contents` via `@contents.rawSetWidthSizeHeightAccordingly` (~:602/608, hand-forward) + `rawSetWidth`/
  `rawSetHeight`; moves it via `@contents.fullRawMoveTo` (~:626); own width/height via `@_applyOwnArrangedWidth`
  (~:563/572/594) + `@_applyOwnArrangedHeight` (~:635).
- **`ScrollPanelWdgt._positionAndResizeChildren` (~:324).** If contents is a stack: `@contents._positionAndResizeChildren()`
  (~:335 — recurse). Text-wrapping: re-wrap the text child (`widget.rawSetWidth` ~:347). Then (§4.1 Stage C)
  `subBounds = @contents.subWidgetsMergedPreferredBounds(...)` (~:374 — the PURE measure) → compute the viewport-grown
  `newBounds` frame (~:397–414) → `@contents.silentRawSetBounds newBounds` (~:421 — apply frame, **fires the seam**) +
  `@contents._reLayoutSelf()` (~:422) → `@keepContentsInScrollPanelWdgt()` (~:431 — position clamp via `@contents.fullRawMoveBy`,
  **fires the seam**).

So inside a scroll-panel arrange, BOTH the frame commit and the keepContents clamp fire the seam at the scroll panel
(Intent-2). The boolean-plan Phase E entanglement finding: *a general scroll panel's self-re-fit IS its convergence —
its arrange resizes `@contents`, the seam re-enqueues the panel, the panel re-snugs `@contents` next pass.* Post-Phase-C
this converges in ~2 passes (set, then a no-op confirm).

### 1.4 The §4.1 measures already built (the inputs this plan consumes)
- `Widget.preferredExtentForWidth(availW)` (~:766) — pure measure; base default = current extent; overridden by
  `TextWdgt` (wrapped height), `SimpleVerticalStackPanelWdgt` (~:142, Σ children), `WindowWdgt` (~:55, content+chrome),
  `AnalogClockWdgt`/`KeepsRatioWhenInVerticalStackMixin` (aspect).
- `Widget.subWidgetsMergedPreferredBounds(childMeasureWidth)` (~:1169) + the stack override (~:172) — pure children-union.
- `getRecursiveMinDim/DesiredDim/MaxDim` (~:4084–4189) — the horizontal-stack pure measure + 3-case arrange in base
  `_reLayout` (~:4298–4396). The horizontal path is ALREADY clean (its seam fires are no-ops — a horizontal-stack
  container does not define `_reLayoutChildren`, so `_reFitContainer` returns early).

---

## §2 — The design: target architecture + the key insight

### 2.1 Target end-state (how Flutter/CSS/RN do it; assessment §4.1/§4.2/§4.4)
A single **measure-up → arrange-down** traversal per dirty root, ZERO iteration:
1. **Measure (bottom-up, PURE — DONE in §4.1).** `preferredExtentForWidth(availW)` computes each subtree's size as a
   side-effect-free function of its children's measures. No `@bounds` write, no seam.
2. **Arrange (top-down, SINGLE-PASS, NON-NOTIFYING — this plan).** Each container positions+sizes its children from the
   MEASURED values and applies the result via a **non-notifying** primitive. Because children were measured before
   they are arranged, **one pass suffices** — no fixpoint iteration.
3. **Invalidation (INPUT, explicit — this plan).** An external change to a freefloating content widget marks its
   container dirty across the content→container edge — the structural replacement for the seam's notify-by-mutation.
   Self-settling, so no careless off-cycle push.
4. **No seam. No `recalcIterationsCap`. No fixpoint loop.** Genuine width⇄height cycles (aspect-locked nested content)
   stay explicitly broken by the existing `elasticity 0` fix; the §4.2 lint forbids any NEW both-direction edge.

### 2.2 THE KEY INSIGHT — separate the two intents by PRIMITIVE, not by phase or boolean
Every prior attempt tried to condition the seam at its firing site:
- **By PHASE** (skip the in-pass firing, keep off-pass) — FALSIFIED: 6 of the 10 need the in-pass firing (their job-B
  notify is itself mid-settle). [memory `fizzygum-convergence-arc-feasibility`]
- **By the `@_adjustingContentsBounds` BOOLEAN** (am I mid-arrange?) — that boolean was DELETED and is forbidden
  (relocating it is the §6 reject).
- **DELETE the seam outright** (both intents) — REVERTED: breaks the 10 (and under-converges scroll panels).

**This plan uses a NEW axis: which PRIMITIVE applies the geometry.**
- The ARRANGE (`_reLayout` / `_positionAndResizeChildren`, always top-down during a settle) applies child/content/own
  geometry through a **non-notifying** apply twin → it never fires the seam → Intent-2 is gone, structurally.
- EXTERNAL agents (drag handlers, content edit, scroll, add — outside the arrange) keep the **notifying**
  `silentRawSetExtent` / `fullRawMoveBy` → Intent-1 is preserved (until Stage 4 reshapes it into explicit invalidation).

This is **not** the `@_adjustingContentsBounds` boolean relocated: there is NO runtime "am I arranging?" flag. The
distinction is STATIC — determined at authoring time by whether a call site is arrange-code or external-code — and is
exactly what the boolean-plan §6 sanctions ("internal non-notifying arrange setters … valid as part of the march to
E/F, where non-notifying apply is the architectural norm and the seam is gone"). A build lint can enforce it (arrange
methods use the non-notifying twins; §4.2 flavor).

**The new primitive (concrete).** The seam fire is the LAST statement of `silentRawSetExtent` (~:1677) and
`fullRawMoveBy` (~:1329). The non-notifying twins are byte-identical minus that one call:
- `_arrangeApplyExtent(extent)` — `silentRawSetExtent` without `@_reFitContainerAfterRawGeometryChange()`.
- `_arrangeApplyMoveTo(point)` / `_arrangeApplyMoveBy(delta)` — `fullRawMoveTo`/`fullRawMoveBy` without it.
- For a child that `implementsDeferredLayout`, the non-notifying child-apply also recurses into the child's
  (non-notifying) `_reLayout` — exactly as `rawSetWidthSizeHeightAccordingly` recurses today (~:752–755).

The base `_reLayout` (~:4258 `fullRawMoveTo`, ~:4271 `rawSetExtent`) and the three `_positionAndResizeChildren` switch
their child/content/own applies to the non-notifying twins. (The horizontal-stack `C._reLayout childBounds` path is
byte-exact either way — its seam fires were already no-ops.)

### 2.3 Why this is byte-exact (the convergence argument)
The arrange's in-pass seam fires (Intent-2) cause REPEAT arranges that are idempotent no-ops post-Phase-C (set on pass
N, confirm-no-change on pass N+1). Removing them via the non-notifying twin removes the confirm pass — **byte-exact at
the screenshot level** (screenshots are taken post-settle; both the multi-pass and the single-pass arrange reach the
SAME fixed point, the one the §4.1 measure was proven to predict — Stage-D probe: measure == converged height except
mid-active-change transients, which are never captured). DETERMINISM is *helped*: fewer passes, same final geometry,
independent of iteration count (the contract). **The dpr2 torture gate is the proof obligation for every stage.**

---

## §3 — The two objectives, and how they map to §4.2 / §4.4 (REVISED by Stage-0 evidence)

This arc has **two separable objectives**; the seam-delete needs BOTH, in this order:

- **OBJECTIVE A — retire the ITERATION (Intent-2) AND green the capstone: the non-notifying single-traversal arrange.**
  This IS the assessment's **§4.2** (make measure-up/arrange-down a single traversal). Stages 1–3, container by
  container. **Stage 0 PROVED all 18 capstone pushes are Intent-2 arrange self-re-enqueues (NOT external Intent-1), so
  Objective A greens the capstone 18 → 0 by itself** (Stage 1 removes 10, Stage 3 the other 8 — §4 Stage 0). After it:
  the arrange is single-pass, the capstone is GREEN, and the seam still fires only for Intent-1 (external changes), so
  the 10 job-B tests still pass.
- **OBJECTIVE B — reshape the NOTIFICATION (Intent-1): explicit content→container invalidation.** The assessment's
  **§4.4** content→container dirty edge (the specific piece, not the full two-flag refactor). Stage 4. Its job is ONLY
  to replace the seam's external-change notification so the seam can be DELETED — it does NOT touch the capstone
  (already green after Objective A). Stage 0 further showed Objective A's single-pass arrange likely SUBSUMES the 6
  in-pass job-B cases (their notify was a re-enqueue the single pass no longer needs), so Stage 4 may only need to wire
  the 4 off-pass edges — re-run the reverse probe after Objective A to find the residual.

**Resolution of "does §4.2 precede §4.4 or co-land": §4.2 PRECEDES (Objective A, Stages 1–3 — which ALSO greens the
capstone); the §4.4 edge FOLLOWS (Objective B, Stage 4 — only to enable the seam delete); the seam-delete (Stage 5)
comes AFTER both.** SEQUENTIAL, each independently byte-exact and soak-gated — never co-landed (a combined big-bang is
the falsified path). The full §4.4 two-flag (`needsLayout`/`hasDirtyDescendant`) refactor is an OPTIONAL efficiency
layer, deferred to Stage 6+ — only the content→container edge is load-bearing for the seam-delete.

---

## §4 — Staging (each stage: byte-exact, independently shippable, soak-gated; STOP if any can't be made byte-exact)

The seam is sound today — leaving it is a defensible fallback (one mechanism + a documented empirical-convergence
position). **Do NOT paper over a missed read-back / notification by reinstating a suppression** (the §6 rejects).

### Stage 0 — precise characterization (PROBE; no production code) — ✅ DONE 2026-06-28
Two throwaway probes (both reverted; build clean at `85d0c186`). Tooling in the session scratchpad
(`stackprobe-prelude.js` + `stackprobe.sh` for the 18; `inpass-probe.sh` for the split; `revprobe.sh` reconfirmed the 10).

**FINDING 1 — ALL 18 capstone pushes are Intent-2 arrange self-re-enqueues, in 4 patterns** (stack-probe = the built-in
careless audit + an unfiltered `new Error().stack` per careless push; 18/18 captured, matching the gate baseline). NONE
is an external Intent-1 push ⇒ **the capstone greens via Objective A alone** — confirming the assessment §2.7
("removable only by the structural work") and correcting the boolean-plan's "external op" framing: the *outer* operation
is `add`/`addNormalParagraph`, but the actual careless push is the arrange's Intent-2 re-enqueue fired during `add`'s
SYNCHRONOUS off-settle re-fit.

| Pattern | Origin (the arrange-internal seam fire) | ctor re-enqueued | n | Removed by |
|---|---|---|---|---|
| **B** | stack child-apply `rawSetWidthSizeHeightAccordingly` → child's seam → `_reFitContainer(stack)` | `SimpleVerticalStackPanelWdgt` | 10 | **Stage 1** |
| **A** | stack content self-resize `_applyOwnArrangedHeight` → seam → `_reFitContainer(scrollPanel)` | `SimpleDocumentScrollPanelWdgt` | 4 | **Stage 1 capability + Stage 3 usage** (who-sizes-the-content) |
| **C** | scrollbar resize `_reLayoutScrollbars` (`rawSetWidth` on a bar) → seam → `_reFitContainer(scrollPanel)` | `ScrollPanelWdgt` | 3 | **Stage 3** |
| **D** | scroll frame-commit `silentRawSetBounds` → seam → `_reFitContainer(ListWdgt)` | `ListWdgt` | 1 | **Stage 3** |

Tests carrying them (Pattern B+A together): `macroDocumentCaretBroughtIntoViewWhenMoved`, `macroDocumentScrollsMixedTextAndClocks`,
`macroNestedScrollPanelsRouteWheel`, `macroSliderTrackClickMovesButton` (3 each); `macroSimpleDocumentCanAddIndentedParagraph`,
`macroSimpleDocumentProgrammaticBuildAndScroll` (1 each, Pattern B only); Pattern C: `macroEditingStringInScrollablePanelCaretAlwaysVisible`,
`macroNoSpuriousScrollbarsOnScrollPanelResize`, `macroScrollPanelCaretBroughtIntoViewWhenMoved`; Pattern D:
`macroAddingWidgetToListUpdatesScroll`. So the capstone is a **PER-STAGE metric: Stage 1 → 18−10 = 8 · Stage 3 → 0.**
The 18-push tests are a DIFFERENT set than the job-B 10 — only the 3 Pattern-C tests overlap.

**FINDING 2 — the job-B 10 split is 6 in-pass / 4 off-pass (reconfirmed on the live tree, matches the feasibility memo).**
- **6 IN-pass** (their Intent-1 notify is mid-settle): `macroLockedScrollPanelScrollsWhenDragged`, `macroScrollBarsTrackContentChange`,
  `macroScrollPanelInWindowMovesWindowWhenDragged`, `macroWindowWithAClockInAWindowConstructionTwo`,
  `macroWindowWithSimpleVerticalPanelResizesAsContentChanges`, `macroWindowsNestedCollapsingUncollapsing`.
- **4 OFF-pass**: `macroEditingStringInScrollablePanelCaretAlwaysVisible`, `macroScrollPanelCaretBroughtIntoViewWhenMoved`,
  `macroNoSpuriousScrollbarsOnScrollPanelResize`, `macroScrollPanelNotMovedViaNonFloatDragChild` (3 of these 4 are also
  the Pattern-C capstone tests).
**Stage-4 HYPOTHESIS:** Objective A's single-pass arrange likely SUBSUMES the 6 in-pass cases (the in-pass seam was a
re-enqueue the one-pass traversal no longer needs) — re-run the reverse probe after Stage 3 to find the true residual
Stage 4 must wire.

**FINDING 3 — the who-sizes-the-content double-sizing is the architectural core (Pattern A).** A stack content
self-sizes (`_applyOwnArrangedHeight`, natural height) AND is then re-sized by its scroll panel (the frame); that
self-size up-notifies the scroll panel = Pattern A. The CLEAN model: the OWNER of the content's size (the scroll panel /
window) sizes it from the measure, and the content arranges its children WITHIN that size WITHOUT self-sizing — so the
content stack needs a **"sized-by-parent" arrange mode** (skip `_applyOwnArrangedHeight`), built in Stage 1 and used in
Stage 3. This is a deeper restructure than "swap to non-notifying twins"; it is the heart of Objective A.

### Stage 1 — the non-notifying apply primitive + the STACK arrange (Objective A) — ✅ DONE + VERIFIED 2026-06-29 (held)
Built the non-notifying twins on `Widget`: `_setExtentBoundsNoNotify` (shared bounds-set core, also used by
`silentRawSetExtent`) → `_arrangeApplyExtent` (= `rawSetExtent` minus the seam); `_arrangeApplyMoveBy`/`_arrangeApplyMoveTo`
(= `fullRawMove*` minus the seam). Converted `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` to apply each
child's resize AND move non-notifying — **for LEAF children only**. Result: **byte-exact** (suite 165/164, only the one
pre-authorized benign inspector recapture `macroDuplicatedInspectorDrivesCopiedTargetOnly` — 3 new base-`Widget`
methods), **capstone 18 → 10**, all job-B tests pass.

**Three corrections to the original plan, learned in execution (durable):**
1. **The container/leaf discriminator is `_reLayoutChildren?`, NOT `implementsDeferredLayout()`.** The latter is pinned
   *false* on Window/Stack/Scroll (so it doesn't flip their read sites), so it mis-routes them to the leaf branch.
   `_reLayoutChildren?` (the same marker the seam gates on) is the correct "is a tracking container" test.
2. **The seam fires from BOTH the child RESIZE and the child MOVE.** Pattern B is split across
   `rawSetWidthSizeHeightAccordingly` *and* `fullRawMoveTo`; converting only one just shifts the push to the other.
   Both the resize and the move must go non-notifying to drop the stack's pushes.
3. **Only LEAF children convert; CONTAINER children keep the notifying resize+move.** A container child's in-pass
   re-enqueue is **load-bearing** for a constrained-scroll-stack's content↔scrollbar WIDTH convergence — making a
   window cell non-notifying settled the stack 6px wider, overlapping its scrollbar
   (`macroWindowCellsInConstrainedScrollStackReflow`). So the stack's own children convert by type; the container
   children's conversion (and the "sized-by-parent" mode / the `_applyOwnArrangedHeight` self-resize) is deferred to
   **Stage 3**, with the scroll convergence. (This is why the capstone lands at **10**, not 8: removing the stack's
   Pattern B un-masked **2** previously-hidden Pattern-A scroll-panel pushes; the remaining 10 are all scroll-panel
   self-pushes — `SimpleDocumentScrollPanelWdgt` ×6 / `ScrollPanelWdgt` ×3 / `ListWdgt` ×1 — i.e. the Stage-3 set.)
4. The `_arrangeApplyMoveBy` body is a small TEMPORARY duplicate of `fullRawMoveBy` (minus the seam); the extent path
   is already DRY via `_setExtentBoundsNoNotify`. They merge with their notifying twins when the seam is deleted (Stage 5).

**Gate: ALL GREEN — build 0 (+ dead-method/stinks lints) · gauntlet dpr1 165/165 · dpr2 165/165 · WebKit 165/165 · apps
PASS · capstone 18 → 10 · 20-min dpr2 torture (no nondeterminism, RECALC_NONCONVERGENCE absent) · paint-readonly 0 · 1
benign inspector recapture. Held (not committed) pending owner review.**

### Stage 2 — the WINDOW arrange (Objective A) — ⏭️ PROBED + DEFERRED 2026-06-29 (owner: skip to Stage 3)
**Decision: deferred — the window's clean slice is low-value and Stage-5-redundant.** A suite-wide WINDOW-SEAM probe
(`scratchpad/winseam-prelude.js` patching `_reFitContainer`; 22,679 window fires) revised the plan's "full window
conversion" sketch:
- **The window contributes 0 to the capstone** — its 1,521 off-pass fires are all *non-careless* (inside declared
  coalescing blocks / already-dirty window / mid-mutation), confirming Stage 0. So Stage 2 is capstone-neutral (10).
- **The only clean Stage-2 target is `titlebar` + `label`** (the two direct-apply chrome leaves): 6720 + 6724 =
  **13,444 in-pass re-enqueues**, trivially byte-exact via the existing twins (pure followers of window width).
- **The rest is deferred or kept notifying:** the chrome BUTTONS (640 in-pass, `editBtn`/`intExtBtn`) ride the base
  `_reLayout(rect)`, whose conversion is entangled with the chain-top self-resize up-notify (load-bearing Pattern-A —
  cannot blanket-convert the base `_reLayout`); the window CONTENT (7074 in-pass) is a CONTAINER (correction #3 → kept
  notifying, Stage 3); the window SELF-resize is the Pattern-A up-notify (kept, like the stack's `_applyOwnArrangedHeight`).
- **The chrome fires are already proven non-load-bearing:** the reverse probe (seam no-op) breaks exactly 10 tests, the 3
  window ones all job-B *Intent-1* (external content change), NONE titlebar/label/chrome. So the chrome fires get removed
  **for free at Stage 5** — a standalone Stage 2 only re-proves a subset the reverse probe already covers.
**⇒ The window's substantive convergence work (its container content) is entangled with the scroll and belongs in
Stage 3.** The titlebar+label trim remains landable any time (optional, capstone-neutral) but is not gated on the
seam-delete. If later wanted, the broader form (make the universal top-down `_reLayout(rect)` non-notifying when given
an explicit rect, preserving the chain-top up-notify) is the arc-central version that also catches the buttons — fold
into Stage 3's general-arrange work or a follow-up.

### Stage 3 — the SCROLL arrange single-pass (Objective A) — **THE CRUX** — ✅ DONE + VERIFIED 2026-06-29 (held)
Converted `ScrollPanelWdgt`, byte-exact, in two gated steps:
- **Step 1 (Patterns C + D), capstone 10 → 6:** the frame commit `@contents.silentRawSetBounds` → `@contents._arrangeApplyBounds`
  (a NEW non-notifying twin on `Widget` = `silentRawSetBounds` minus the seam) + the keepContents clamp's `fullRawMoveBy`
  → `_arrangeApplyMoveBy` [Pattern D]; `_reLayoutScrollbars`'s `hBar`/`vBar` `rawSetWidth`/`rawSetHeight`/`fullRawMoveTo`
  → `_arrangeApplyExtent`/`_arrangeApplyMoveTo` [Pattern C]. The scroll panel OWNS its frame + its (chrome) bars, so
  notifying ITSELF was a redundant confirm pass.
- **Step 2 (Pattern A), capstone 6 → 0:** the content stack's terminal self-resize (`_applyOwnArrangedHeight`) goes
  non-notifying when arranged BY the scroll panel, via a new `parentWillSizeMe` PARAMETER on
  `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` (the scroll panel passes `true` at ~:347; the frame commit
  that follows overrides the self-size anyway, so the up-notify was the redundant self-re-enqueue). Default false keeps
  the notifying self-resize for every OTHER caller (the stack's own `_reLayoutChildren`, a WINDOW content arrange) where
  the up-notify is load-bearing (the clock-in-window cascade). A function PARAMETER expressing the caller's structural
  intent — the "split by who is arranging" axis — NOT a runtime suppression flag.

**The Phase-E under-convergence failure mode (spurious scrollbars) did NOT recur** — confirming the bet: the non-notifying
twin is strictly narrower than Phase C's rewrite (it drops the self-re-enqueue, keeps the frame/clamp arithmetic
verbatim), so the second/confirm pass it removed was a proven no-op. **Two findings:** (1) `@contents._reLayoutSelf()`
(~:432) is a base no-op for stack content, so the line-347 pre-arrange is the ONLY place the stack's children get
arranged — it could NOT be removed, hence the non-notifying-self-size approach. (2) the text-wrap re-wrap (`rawSetWidth`,
~:359) was left alone: its bare-PanelWdgt content has no `_reLayoutChildren`, so that seam fire is already a no-op.

**Gate: ALL GREEN — build 0; gauntlet dpr1/dpr2/WebKit 165/165 + 12 apps; end-of-cycle capstone 18→10→0; 20-min dpr2
torture 10 iters / 0 flaky / RECALC_NONCONVERGENCE absent; paint-readonly 0; 1 pre-authorized benign inspector recapture
(`macroDuplicatedInspectorDrivesCopiedTargetOnly` — the new base `Widget._arrangeApplyBounds` appears in the inspected
RectangleWdgt's inherited-member list; behavioural image_1 byte-identical). Held (not committed) pending owner review.**

**REVERSE-PROBE re-run on the post-Stage-3 tree (throwaway seam no-op, reverted): the SAME EXACT 10 job-B tests break**
(7 scroll + 3 window/stack — identical to pre-§4.1). So **Stage 0's hypothesis is FALSIFIED**: Objective A's single-pass
arrange did NOT subsume the 6 in-pass job-B cases. The seam's Intent-1 notification role is fully intact and orthogonal to
the Intent-2 iteration Objective A removed — **Stage 4 must wire ALL 10 content→container edges, not ~4.**

### Stage 4 — explicit Intent-1 (Objective B; the §4.4 content→container edge) — NOT about the capstone
By Stage 3 the capstone is already 0 (Stage 0 Finding 1: the 18 were all Intent-2). Stage 4's ONLY job is to replace
the seam's surviving role — the Intent-1 notification (an EXTERNAL change to freefloating content → its container must
re-fit) — with an explicit, structural content→container invalidation, so that deleting the seam (Stage 5) is byte-exact
and the job-B 10 still pass. **Reverse probe already re-run post-Stage-3 (2026-06-29): Stage 0's hypothesis FALSIFIED —
the SAME 10 job-B tests still break, NONE subsumed.** So Stage 4 must wire ALL 10 content→container edges (7 scroll: 
`macroEditingStringInScrollablePanelCaretAlwaysVisible`, `macroLockedScrollPanelScrollsWhenDragged`,
`macroNoSpuriousScrollbarsOnScrollPanelResize`, `macroScrollBarsTrackContentChange`,
`macroScrollPanelCaretBroughtIntoViewWhenMoved`, `macroScrollPanelInWindowMovesWindowWhenDragged`,
`macroScrollPanelNotMovedViaNonFloatDragChild`; 3 window/stack: `macroWindowWithAClockInAWindowConstructionTwo`,
`macroWindowWithSimpleVerticalPanelResizesAsContentChanges`, `macroWindowsNestedCollapsingUncollapsing`), not the
optimistic ~4.

**⚠ DESIGN PROBED 2026-06-29 — the surgical "explicit choke-point" framing (Option B) is FALSIFIED; the real edge is
STRUCTURAL.** Findings (all probes runtime-only, source clean at `c8098e6d`):
- **Seam-trigger probe** (instrument `_reFitContainerAfterRawGeometryChange`): the 7 scroll tests' load-bearing edge is
  uniformly **`PanelWdgt → ScrollPanelWdgt`, IN-pass**; the 3 window tests are dominated by IN-pass `*→WindowWdgt`
  firings that are the **unconverted window arrange's Intent-2** (NOT load-bearing — the reverse probe proves disabling
  them is byte-exact), over an off-pass content→`WindowWdgt` cascade.
- **Option B (scroll choke-points) FALSIFIED:** wired `scrollX`/`scrollY`/`scrollTo` to explicitly call
  `@contents._refreshScrollPanelWdgtOrVerticalStackIfIamInIt()` (byte-exact, dpr1 165/165) → **reverse probe STILL
  broke the SAME 10.** So the scroll methods are NOT the load-bearing sites (reverted).
- **The real edge is the content's OWN base `Widget._reLayout`:** when the settle loop re-lays out a freefloating
  scroll/window content as a chain-top, base `_reLayout` applies geometry via the *notifying* `fullRawMoveTo` /
  `rawSetExtent` (code fact, ~:4260/4271) → fires the seam → re-fits the container. This is the generic content→container
  edge in the ARRANGE itself — Option-A / §4.4 territory, **not** per-site Option B. (Possible additional pure-raw-setter
  drag paths remain to characterize.)
- **Probing limit:** in-browser-compiled code shows as anonymous `Object.eval` in stacks (can't name the trigger method);
  a `_reLayout`-depth-flag probe was too invasive (adding a widget property broke 15 inspector/duplicate/wrapping tests).
  ⇒ precise mechanism/site-ID needs the EMPIRICAL reverse-probe loop (wire candidate → reverse-probe → see which of the
  10 flip to passing → iterate), not stack inspection.

**⇒ REVISED scope:** Stage 4 is a STRUCTURAL change (relocate the Intent-1 notification from the raw setters UP into the
base `_reLayout`/settle as an explicit content→container edge, with non-notifying setters + an explicit container-notify),
Stage-3-scale and entangled with the chain-top self-resize up-notify (the Pattern-A that must STAY notifying). It is the
`_invalidateLayout`-across-the-position-freefloating-boundary piece (§4.4 — content content-SIZED by its container is not
position-freefloating for invalidation). NOT the surgical per-site wiring originally sketched. **Gate (unchanged):
byte-exact · capstone stays 0 · reverse probe flips the 10 to PASS incrementally · dpr2 torture clean · paint-readonly 0.**

### Stage 5 — DELETE the seam
With Objective A (no in-pass Intent-2) and Objective B (Intent-1 now explicit) both landed, re-run the reverse probe:
the seam no-op must now be **byte-exact AND the 10 must PASS** (the proof it is fully replaced). Then DELETE
`_reFitContainerAfterRawGeometryChange` + the `@_reFitContainerAfterRawGeometryChange()` calls in `silentRawSetExtent`
(~:1677) and `fullRawMoveBy` (~:1329) + `_reFitContainer` if it has no other live caller (grep the gesture/menu
callers `_reactToDropOf`/`_reactToGrabOf`/`childRemoved`/`newParentChoice*`/`_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`
first — they may keep `_reFitContainer` alive as the explicit-invalidation primitive, in which case only the
raw-setter seam method goes). **Gate: full gauntlet · capstone 0 · paint-readonly 0 · 20-min dpr2 torture.**

### Stage 6 — retire `recalcIterationsCap` + the empirical crutches; §4.2 DAG lint
With a single-pass down-walk, the until-loop runs zero extra iterations. Demote `recalcIterationsCap` to a never-fire
assert, then remove it (or prove one-pass termination). Add the assessment §4.2 `check-layering.js` rule: forbid any
new edge coupling both directions on the same axis of the same widget (the empirical convergence of §2.6 becomes
build-enforced). Reduce the world phase booleans to the honest minimum (one public-API re-entrancy guard may
legitimately remain — total-zero-booleans is not the test; zero *suppression/empirical-convergence* booleans is).

---

## §5 — Verification protocol (MANDATORY for every stage that touches the arrange or the seam)
`fg` runs from any cwd. **Kill orphan `Chrome for Testing` before any suite/torture/gate; rebuild first (stale-build
canary — verify the shipped artifact carries your change).**
1. `./fg build` — 0 violations/warnings.
2. `./fg suite` — dpr1 165/165. On a pixel failure: dump + LOOK, don't recapture blindly —
   `node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`, Read the `.png`.
3. `./fg gauntlet` — dpr1/dpr2/WebKit 165/165 + apps 12/12.
4. **dpr2 torture — THE GOLD GATE (every stage):** `node scripts/torture-headless.js --dprs=2 --speeds=fastest
   --shards=4 --minutes=20 --out=.scratch/torture` → "No nondeterminism observed", failures dir empty, and grep
   `RECALC_NONCONVERGENCE` **ABSENT** (the single most important signal for this work).
5. **Capstone gate** (`bash scripts/end-of-cycle-audit/run-capstone-gate.sh ; echo "EXIT $status"`) — RED at 18 is the
   known baseline through Stage 3 (EXIT 1 expected; check the COUNT==18 on a COMPLETE run: `per-test logs=165 · suite
   runner exit=0`); Stage 4 drives it to 0 (EXIT 0). **Paint-read-only gate**
   (`bash scripts/paint-readonly-audit/run-paint-readonly-gate.sh ; echo "EXIT $status"`) — 0 throughout. Do NOT pipe a
   gate's exit into tail/grep — dump to a file, echo `$status`, read.
6. **The reverse-disable probe** (Stages 3 & 5): seam no-op must converge + byte-match (Stage 5) — positive proof the
   stage made the seam unnecessary.
7. **20-min determinism soak** before declaring any convergence-touching stage done.

Recapture: byte-exact ⇒ none; benign inspector member-list shift ⇒ recapture (the one pre-authorized class — a new
base `Widget` method appears in an inspected widget's inherited-member list; LOOK-confirm image_1 unchanged, then
recapture, cf. §4.1 Stage C/D); deliberate pixel change ⇒ owner approval FIRST. Contract: `Fizzygum-tests/DETERMINISM.md`.

---

## §6 — Honest caveats / risk gates / do-NOT-reattempt
- **Stage 3 (scroll arrange single-pass) is the make-or-break.** The boolean-plan Phase E proved that REMOVING the
  scroll panel's self-re-fit can under-converge it (spurious scrollbars). The bet is that the non-notifying twin (a
  narrower change than Phase C's rewrite, keeping the frame/clamp arithmetic) only drops a no-op confirm pass. Probe in
  isolation; STOP if it under-converges.
- **High reversal density.** This terrain bit twice already (soft-wrap §5; the text-slice falsification; Phase C's
  10-panel break). Expect reverts; probe every stage.
- **Aspect-locked nested content is a TRUE width↔height cycle**, already broken by `elasticity 0`. Do NOT measure
  through it or "fix" it — leave the cycle-break in place.
- **DO NOT re-attempt** (all falsified — assessment "do not revisit"): the in-pass/off-pass seam split; conditioning
  the seam by a (re-introduced) `@_adjustingContentsBounds`-style boolean; a big-bang full-seam-deletion; Path A
  pending-aware accessors; reformulating the `wEl/wStk` proportion fraction; routing `ScrollPanelWdgt.add` through the
  batch tier; relocating the suppression into a `world.layoutEngine` object (§4.3 — the archetypal "bury it deeper").

---

## §7 — Anchors (grep the symbol; numbers drift; verified vs `85d0c186`)
- **Settle loop:** `WorldWdgt._recalculateLayoutsBody` ~:924 (until-loop ~:933; walk-up + freefloating stop ~:972–973;
  `_reLayout` call ~:982; cap `100000`/`RECALC_NONCONVERGENCE` ~:930/936). `recalculateLayouts` wrapper ~:896.
- **The seam (Stage 5 target):** `_reFitContainerAfterRawGeometryChange` `Widget.coffee` ~:1697 (`isLayoutInert` skip
  ~:1705), `_reFitContainer` ~:1736 (in-pass `_markForRelayoutNoClimb` ~:1739 / off-pass `_invalidateLayout` ~:1741),
  `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` ~:1686. Fired by `silentRawSetExtent` ~:1644 (fire ~:1677) +
  `fullRawMoveBy` ~:1306 (fire ~:1329); `silentRawSetBounds` ~:892 routes extent through `silentRawSetExtent`.
- **Enqueue primitives:** `_markForRelayoutNoClimb` ~:3916 · `_invalidateLayout` ~:3920 (freefloating-skip ~:3928;
  inert-receiver branch ~:3937; `FLOWRULE_VIOLATION` mid-pass throw ~:3951; capstone record ~:3966; climb ~:3974).
- **Arrange dispatch:** base `Widget._reLayout` ~:4234 (`fullRawMoveTo` ~:4258, `rawSetExtent`/`rawSetBounds` ~:4269/4271,
  horizontal 3-case ~:4298–4396, `markLayoutAsFixed` ~:4399). `rawSetWidthSizeHeightAccordingly` ~:750 (synchronous
  `_reLayout` ~:755, returns height).
- **Container arranges (restructure targets):** `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` ~:204
  (child resize ~:245 / move ~:263 / own ~:274; `_applyOwnArrangedWidth/Height` ~:125/129) ·
  `WindowWdgt._positionAndResizeChildren` ~:527 (contents sizing ~:602/608, move ~:626, own ~:563/635) ·
  `ScrollPanelWdgt._positionAndResizeChildren` ~:324 (stack recurse ~:335, text re-wrap ~:347, **§4.1 measure**
  `subWidgetsMergedPreferredBounds` ~:374, frame commit ~:421, `keepContentsInScrollPanelWdgt` ~:431/433).
- **§4.1 measures (inputs):** `Widget.preferredExtentForWidth` ~:766 + overrides (`TextWdgt`, stack ~:142, window ~:55,
  aspect); `Widget.subWidgetsMergedPreferredBounds` ~:1169 + stack override ~:172; `getRecursive*Dim` ~:4084–4189.
- **Capstone metric:** `WorldWdgt.auditUndeclaredEndOfCycle` / `_undeclaredEndOfCyclePushes`; the `UNDECLARED-EOC`
  log in `recalculateLayouts` ~:908; the enqueue-time record in `_invalidateLayout` ~:3966.
- **Authoritative analysis (READ, owner WIP — do NOT commit/edit):** `docs/archive/layout-system-architecture-assessment.md`
  §2.3/§2.4/§2.5/§2.6/§2.7/§4.1/§4.2/§4.4. Roadmaps: `proper-layouts-4.1-pure-measure-campaign-plan.md` (§4.1, DONE),
  `proper-layouts-eliminate-suppression-booleans-plan.md` (Phases A–F; §5 Phase E "deferred half" = this arc).
  Memories: `fizzygum-convergence-arc-feasibility`, `fizzygum-pure-measure-campaign-progress`,
  `proper-layouts-elimination-goal`, `fizzygum-adjustingcontentsbounds-flag`, `fizzygum-deferred-layout-plan`.

---

## §8 — Owner principles + workflow
- **Measure, don't mutate-and-read-back; arrange non-notifying, don't notify-by-mutation.** If a "non-notifying" apply
  still fires the seam, or a "measure" touches `@bounds`, it has failed.
- **Staged + soak each stage; STOP and leave the seam if a stage can't be made byte-exact.** Never big-bang the
  convergence code. Each committed stage is an independently valuable resting point.
- **Review-driven.** Run a stage straight through verifying continuously; present ONE review per stage. **ASK before
  each commit AND push** — present the diff + message, wait. `git commit -F <file>` (never backticks/`$()` in `-m`);
  verify with `git log -1 --format=%B`. End commit messages with the `Co-Authored-By: Claude Opus 4.8 (1M context)
  <noreply@anthropic.com>` + `Claude-Session:` trailers. Push each repo from its own dir. Held commits stay held until
  the owner says push; plan docs stay UNTRACKED; the assessment is owner WIP (do NOT commit it).
- **Clean/elegant code > dodging a benign inspector recapture** (just recapture).
- **Shell:** Bash runs FISH (`$status`); cwd may reset — `cd /abs/… && …`; a PreToolUse guard blocks a cross-repo
  `cd`-then-`Fizzygum-tests/scripts` chain (run via `fg` or a driver script with the cd INSIDE). Kill orphan
  `Chrome for Testing` before any suite/torture/gate. Never pipe a gate's exit into tail/grep.
