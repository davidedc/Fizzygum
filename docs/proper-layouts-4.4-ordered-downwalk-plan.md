# Plan — §4.4 the ORDERED down-walk that deletes the re-fit seam (the convergence-arc finale)

> **STATUS (2026-06-29, UPDATED end-of-session). ⛔ ARC CLOSED — STOP-and-BANK. The seam-deletion paths are
> FALSIFIED (see §8); the capstone-green Stage 3 is the resting point.** A feasibility session (owner-approved: probe
> before committing) ran runtime-only reverse-probes for BOTH the local off-pass climb (D1) AND the ordered-traversal
> content-first pre-settle — each recovers 0 of the 10. KEY: the arrange is already SINGLE-PASS-correct; the seam
> orchestrates a multi-widget size↔position CONVERGENCE (in-pass, post-geometry-application), which neither the
> off-pass dirty-tree nor a content-first pre-settle can replace. The elimination mandate's CORE (delete the *waste*)
> was already met by Stage 3; the residual seam is a legitimate, effectively-irreducible dependency edge. §1–§7 below
> are the (now-historical) design; **§8 is the binding RESULT.** ALL identified seam-deletion paths are now
> EXHAUSTED — the local off-pass climb, the ordered-traversal pre-settle, AND the analytic position↔frame decoupling
> (owner-requested, falsified 2026-06-29: the arrange is already idempotent, so the synchronous fixpoint that dominates
> any one-pass decoupling is a no-op; the seam's role is multi-widget notification, not single-container convergence).

Builds on: §4.1 pure-measure campaign (DONE — `preferredExtentForWidth`/`subWidgetsMergedPreferredBounds` built),
§4.2 Stages 1/3 (DONE+committed-held `c8098e6d` — non-notifying STACK + SCROLL arrange, capstone GREEN 18→0),
§4.2 Stage 2 (window) PROBED+DEFERRED. Memories: [[fizzygum-structural-arrange-arc]],
[[fizzygum-convergence-arc-feasibility]], [[proper-layouts-elimination-goal]]. Authoritative analysis (READ, owner WIP,
do NOT edit): `docs/layout-system-architecture-assessment.md` §2.4/§2.5/§4.1/§4.2/§4.4/§4.5.

---

## §0 — Why this now (the §4.2 Stage 4 falsification)

§4.2 Objective A (the non-notifying single-pass arrange, Stages 1/3) greened the end-of-cycle capstone (18→0): the
arrange no longer fires the seam at ITSELF (Intent-2). What survives is the seam's Intent-1 role — a size-tracking
container must re-fit after an EXTERNAL change to its freefloating content. The reverse-probe (seam no-op) breaks
EXACTLY 10 tests (7 scroll + 3 window/stack); that 10 is the job-B work-list.

§4.2 Stage 4 hypothesised this was a cheap "explicit content→container edge." This session FALSIFIED that, twice, and
re-characterised the real shape (all probes runtime-only / reverted; tree clean at `c8098e6d`):

- **Closure-stack probe** (track `_reLayout` entry/exit in a closure array — NO widget property, so it sidesteps the
  inspector/serialization breakage that killed the earlier `__reLayoutDepth` probe). For all 7 scroll tests the
  load-bearing seam fire is uniformly `top=ScrollPanelWdgt, self=0` — the scroll panel mutating its OWN content during
  its own resize, NOT the content's own `_reLayout` (the §4.2-Stage-4 "content's `_reLayout`" note was reasoning-based
  and is WRONG). Source pinned: `ScrollPanelWdgt.rawSetExtent` override (`:261 @contents.fullRawMoveTo` / `:263
  @contents.rawSetExtent aPoint`), reached via base `_reLayout`:4285. `NoSpuriousScrollbars` = 91 fires (one per resize
  step), the others = 1. The 3 window tests are dominated by the unconverted window-arrange Intent-2 (Stage 2 deferred).
- **Selective-suppress probe** (suppress the seam whenever ANY `_reLayout` is on the closure stack — models converting
  every in-arrange container→content mutation to non-notifying, keeping off-pass/external fires): breaks the SAME 10,
  regresses no other test. ⇒ the off-pass/external fires are NOT load-bearing; the **container's in-arrange deferred
  self-re-fit** is.
- **Dump + LOOK** (`NoSpuriousScrollbars`, seam off): the failure is **spurious H+V scrollbars** on a panel whose tiny
  content fits — the Phase-E under-convergence. Root: `_reLayoutScrollbars` shows a bar purely from `@contents.width()
  >= @width()+1` (`:158`) / height (`:183`); the frame `newBounds` is anchored at `@contents.left()` (`:418` merge) but
  `keepContentsInScrollPanelWdgt` (`:447`) clamps `@contents`'s position AFTER the frame commit → a genuine
  position↔frame-size 2-pass convergence, the seam's deferred re-fit being pass 2.
- **Bounded synchronous fixpoint** (8-iter loop re-running the arrange in `_reLayoutChildren`): still breaks all 7
  scroll. ⇒ the convergence is NOT a local "needs-N-passes" — it needs the settle loop's INTERLEAVING (the measure
  width `@contents.width()` is itself read-back, changing between passes). This is the §4.1 "one surviving read-back"
  (`subBounds`) biting + the §4.5 freefloating ordering.

**Conclusion:** deleting the seam needs the arrange to be a TRUE single-pass measure (no `@contents.width()` read-back;
position decoupled from frame-size) inside an ORDERED traversal — the §4.4 down-walk. Not a local resize-path patch.

---

## §1 — Current machinery (ground truth; grep the symbol, numbers vs `c8098e6d`)

- **Single dirty flag:** `Widget.layoutIsValid` (`:234`, default true). Set FALSE by `_markForRelayoutNoClimb`
  (`:3930` — pushes to the work-list iff was valid); set TRUE by `markLayoutAsFixed` (`:4245`, called at `_reLayout`
  tail `:4413` + the collapsed-subtree early-out `:4241`).
- **Work-list:** `WorldWdgt.widgetsThatMaybeChangedLayout` (`:287`, an array).
- **`_invalidateLayout(triggeringChild)`** (`:3934`): **freefloating-skip** `return if triggeringChild?.isFreeFloating()`
  (`:3942` — a freefloating child's change does NOT invalidate its parent: the reason the seam exists); inert-receiver
  branch (caret/handle, `:3951`); in-pass FLOWRULE throw (`:3965`); careless-push capstone audit (`:3980`); bare enqueue
  `_markForRelayoutNoClimb` (`:3984`); CLIMB `@parent?._invalidateLayout(@)` (`:3988`).
- **Settle loop** `WorldWdgt._recalculateLayoutsBody` (`:924`): `until work-list empty` → pop VALID off the end, find
  first invalid → **walk UP** `while parent: break if isFreeFloating() or parent.layoutIsValid; else climb` (`:972` —
  chain-top = topmost-invalid, STOP at freefloating-or-valid-parent) → `tryThisWidget._reLayout()` (`:982`, down).
  `recalcIterationsCap = 100000` (`:930`) / `RECALC_NONCONVERGENCE`.
- **`_reLayout(newBounds)`** (`:4248`): `__calculateNewBoundsWhenDoingLayout` (`:4220`, consumes `@desiredExtent`/
  `@desiredPosition`) → apply own geometry → arrange (horizontal 3-case recursion `:4312` / container override
  `_reLayoutChildren`) → `markLayoutAsFixed`.
- **The seam (Stage-D delete target):** `_reFitContainerAfterRawGeometryChange` (`:1711`) fired by `silentRawSetExtent`
  (`:1651`) + `fullRawMoveBy` (`:1312`); dispatch `_reFitContainer` (`:1750`, gated on `container._reLayoutChildren?`,
  in-pass `_markForRelayoutNoClimb` / off-pass `_invalidateLayout`). The container-tracking relation:
  `_amIDirectlyInsideScrollPanelWdgt` (`:2905`) / `_amIDirectlyInsideNonTextWrappingScrollPanelWdgt` (`:2913`).
- **Scroll arrange (the crux site):** `ScrollPanelWdgt.rawSetExtent` override (`:253`, `@contents` mutations `:261/263`
  + synchronous `@_reLayoutChildren` `:268`); `_positionAndResizeChildren` (`:332`, §4.1 measure at `@contents.width()`
  `:386/388`, frame anchor `:418`, commit `:437`, `keepContentsInScrollPanelWdgt` `:447`); `_reLayoutScrollbars`
  (`:116`, bar-visibility `:158/183`).

---

## §2 — Target architecture

A single ordered traversal per dirty root, ZERO iteration, no notify-by-mutation:

1. **Measure (bottom-up, PURE — §4.1, DONE).** `preferredExtentForWidth` / `subWidgetsMergedPreferredBounds` — no
   `@bounds` read-back.
2. **Two-flag dirtiness (§4.4).** `needsLayout` (this node, = today's `!layoutIsValid`) + `hasDirtyDescendant` (a
   descendant needs layout). `_invalidateLayout` sets `needsLayout` on the node and flips `hasDirtyDescendant` up the
   chain (O(depth) mark, O(1) enqueue — only dirty ROOTS go on the work-list); the loop walks DOWN from those roots.
3. **The content→container edge replaces the seam.** A size-tracking container (scroll / stack / window) depends on its
   freefloating content's size. Today the freefloating-skip blocks the climb and the seam bridges it. In the target, the
   container, when visited top-down, sizes itself from its content's PURE MEASURE (no need for the content to be
   pre-applied) and arranges the content in the SAME visit — one pass, no deferred re-fit. The freefloating-skip stays
   for POSITION (a freefloating child's move never resizes its parent); SIZE flows up via the measure, not the seam.
4. **No seam, no `recalcIterationsCap`, no fixpoint loop.** Genuine width↔height cycles (aspect-locked nested content)
   stay broken by the existing `elasticity 0` fix.

---

## §3 — The crux (why the seam survives; what deletes it)

The assessment (§4.4) is explicit: the two-flag is the EFFICIENCY/CLEANLINESS layer — it does NOT by itself stop a
settled container being re-dirtied. The seam dissolves only when the arrange stops needing a second pass. This session
pinned exactly what forces the second pass for scroll:

- **The last read-back (`subBounds`).** `_positionAndResizeChildren` measures at `@contents.width()` (`:388`) — the
  APPLIED frame width it just set. So the measure width changes between passes (frame width → measure width → frame
  size → frame width). A pass-1 frame at the transient width, then keepContents, then a pass-2 re-measure. To be
  single-pass, measure at the VIEWPORT-derived width (a pure function of `@width()`), not `@contents.width()`.
- **Position↔frame-size coupling.** `:418` anchors the frame at `@contents.left()`; `keepContents` (`:447`) clamps the
  position AFTER the commit. Decouple: frame SIZE = max(content-measure, viewport) computed independent of
  `@contents`'s current position; POSITION = preserved scroll offset, clamped. (Mind `:418`'s centered-icon purpose +
  legitimately-scrolled content — that is the byte-exactness risk.)

Remove those two and the scroll arrange is a pure single-pass measure → the seam's deferred re-fit is unnecessary →
delete the seam. The window arrange (Stage 2, deferred) needs the same treatment.

---

## §4 — Staging (each byte-exact, independently shippable, soak-gated; STOP if a stage can't be made byte-exact)

- **Stage A — §4.5 freefloating walk-up quick-win (safe precursor).** The settle walk-up stops at the FIRST valid
  parent; the assessment §4.5 / the `WorldWdgt:972` TODO want it to stop at the LAST invalid on the way up (so a
  freefloating child is not laid out twice with a stale parent). Local, optimization-only, cadence-sensitive → soak.
  Independent of the seam; a clean warm-up that de-risks the loop edits.
- **Stage B — two-flag dirty tracking (the §4.4 scaffold).** Add `hasDirtyDescendant` alongside `layoutIsValid`
  (rename `!layoutIsValid` → `needsLayout` only if clean). `_invalidateLayout` flips `hasDirtyDescendant` up the chain;
  the loop walks DOWN from dirty roots. Byte-IDENTICAL (same widgets re-laid-out, different bookkeeping) — verify the
  work-list contents/order match. Does NOT touch the seam (assessment: not sufficient alone). Determinism-sensitive.
- **Stage C — the TRUE single-pass arrange (THE CRUX, STOP gate).** Remove the `@contents.width()` read-back (measure at
  the viewport-derived width) + decouple position↔frame-size in `ScrollPanelWdgt._positionAndResizeChildren`; fold the
  `rawSetExtent` override's `:261/263` content mutations into the measure path (its own `:258` TODO). Drive by the
  reverse-probe loop: wire candidate → reverse-probe (seam no-op) → the 7 scroll must flip to PASS, byte-exact with the
  seam ON. Then the window arrange (Stage-2 non-notifying + the same single-pass treatment) for the 3 window tests.
  **This is the make-or-break — this session falsified two local approaches; if it can't be made byte-exact, STOP and
  leave the seam (the capstone-green Stage 3 is the durable resting point).**

  **⚠ DE-RISK 2026-06-29 (throwaway edits, reverted to `c8098e6d`; `NoSpuriousScrollbars` reverse-probe + dump+LOOK):
  Stage C SPLITS INTO TWO PIECES — one tractable + PROVEN, one = the §4.4 ordering.** Decisive diagnostic (an XPRB log
  in `_positionAndResizeChildren`): NoSpurious is `cs=false` (non-content-sizing → the `else` frame branch `:435`). With
  `@contents` AT the viewport (cdx=0) and a tiny `sub=50x40` icon, the frame computed to `nb=530x400` — far over the
  380×320 viewport (→ spurious H+V bars). Two distinct read-backs:
  - **(C1) Frame-SIZE read-backs — PARTLY byte-exact, PARTLY load-bearing (CORRECTED after the seam-ON gate).** Two:
    **(a)** the content-sizing measure at `@contents.width()` (`:386/388` + the text re-wrap `:358`) → measuring at
    `@width()` is **BYTE-EXACT (full dpr1 suite 165/165, seam ON)** — a clean §4.1 read-back removal — but MARGINAL: the
    seam-off reverse-probe still breaks all 10 with (a) alone, so it does NOT reduce the seam's load. **(b)** the
    non-content-sizing `else`-branch `@boundingBox()` merge (`:435`) → dropping it (unify to the subBounds+viewport-grow
    shape) is **NOT byte-exact: breaks 9 tests with the seam ON** (incl. 3 NEW — `CompositeDragsAsUnitIntoScrollPanel`,
    `MenuPinnedInScrollPanel`, `ScrollPanelDragToScrollFlags`). The `@boundingBox()` read-back is **LOAD-BEARING** for
    folder/toolbar/menu/free-positioned content. (The seam-OFF probe that flipped NoSpurious images 2&3 was MISLEADING —
    it showed (b) CHANGES the convergence, not that it is byte-exact.) ⇒ local frame-size read-back removal does NOT make
    the arrange single-pass; (b) + (C2) both genuinely need the content settled BEFORE the container frame = the §4.4 order.
  - **(C2) Frame-POSITION ordering — THE REMAINING BLOCKER = §4.4.** image_1 still fails (spurious *horizontal* bar):
    the content is a CENTERED icon whose layout-derived centered position settles AFTER the frame is computed, so the
    frame (subBounds = the icon's APPLIED world bounds) captures the icon's transient pre-centering position
    (`nb=530x320`; LOOK confirmed: icon visually centered, vertical bar gone, spurious horizontal bar). The seam's
    deferred re-fit re-computes the frame once the icon has centered. This is EXACTLY the §4.4 ordering (a container
    must re-fit after its freefloating content's children settle) — needs either the ordered down-walk (content
    children laid out before the container frame) or a POSITIONAL pure measure (the icon's centered position computed
    without applying it; `subWidgetsMergedFullBounds` is an applied read-back).
  **⇒ The de-risk VALIDATES that the §4.4 ORDERING is necessary (local read-back removal is NOT sufficient).** Both the
  load-bearing `@boundingBox()` read-back (b) and the centered-position (C2) need the content settled/measured BEFORE the
  container frame — which is exactly what the §4.4 ordered down-walk provides (lay the content out, THEN size the
  container from its now-settled bounds, in one ordered traversal). So there is NO byte-exact "land C1 first" increment
  worth landing standalone — (a) is byte-exact but marginal (doesn't reduce the seam), (b) is a behaviour change. The
  real path is the §4.4 ordered traversal itself, which must subsume all three: (a) the content-sizing measure, (b) the
  non-content-sizing frame, and (C2) the content position — by ordering content-before-container. **Falsified-this-arc
  (do-NOT-reattempt as local fixes): non-notifying conversion; synchronous fixpoint; dropping the `@boundingBox()`
  read-back. (a) [measure at `@width()`] is byte-exact and may be folded into the §4.4 arrange rework.**
- **Stage D — DELETE the seam.** Gated on C: the reverse-probe must be byte-exact AND all 10 PASS. Delete
  `_reFitContainerAfterRawGeometryChange` + its 2 firing sites; keep `_reFitContainer`/`_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`
  iff still-called by gesture/membership.
- **Stage E — retire `recalcIterationsCap` + the empirical crutches; §4.2 DAG lint.** Demote the cap to a never-fire
  assert; add the per-axis DAG lint (forbid a new edge coupling both directions on one axis of one widget).

---

## §5 — Verification protocol (every stage touching the loop / arrange / seam)
`./fg build` (0) · `./fg suite` dpr1 165/165 (dump+LOOK on a pixel fail) · `./fg gauntlet` dpr1/dpr2/WebKit 165/165 +
apps · **dpr2 torture 20-min** ("No nondeterminism", `RECALC_NONCONVERGENCE` ABSENT) · **capstone gate** STAYS 0 (EXIT
0) · **paint-readonly gate** 0 · the **reverse-probe** (Stages C/D: seam no-op must converge + byte-match). Recapture
only for a benign inspector member-list shift (pre-authorised). Kill orphan `Chrome for Testing` first; gates' exit to a
file then echo `$status` (never pipe into tail/grep); run gauntlet/torture in BACKGROUND + a file-poll watchdog.

---

## §6 — Honest caveats / risk gates / do-NOT-reattempt
- **Stage C is the make-or-break and is genuinely at risk.** This session falsified (a) non-notifying conversion +
  synchronous re-fit and (b) an 8-iter synchronous fixpoint. The remaining hope is the read-back removal + position↔size
  decoupling; `:418`'s centered-icon purpose and legitimately-scrolled content are the byte-exactness hazards. STOP-and-
  bank (leave the seam after Stage 3) is a defensible, sanctioned outcome — the capstone is already GREEN.
- **The two-flag (Stage B) alone does NOT delete the seam** (assessment §4.4). Don't present it as the deletion.
- **DO-NOT-reattempt** (this session, falsified): the local resize-path non-notifying conversion; the synchronous
  fixpoint; the "content's own `_reLayout`" edge framing. (Earlier, also falsified: in-pass/off-pass seam split; a
  re-introduced `@_adjustingContentsBounds`-style boolean; big-bang full-seam-deletion; relocating into a
  `world.layoutEngine` object §4.3.)
- **Aspect-locked nested content is a TRUE width↔height cycle**, already broken by `elasticity 0` — leave it.

---

## §7 — State / constraints
§4.1 + §4.2 Stages 1/3 COMMITTED-HELD (Fizzygum master 10 ahead `c8098e6d`; tests 5 ahead `a6f95130b`) — NONE pushed.
This plan + the assessment edits are UNTRACKED / owner-WIP (do NOT commit the assessment). ASK before every commit AND
push; `git commit -F` (no backticks in `-m`) + Co-Authored-By/Claude-Session trailers. Bash runs FISH (`$status`);
`./fg` from the umbrella root.

---

## §8 — RESULT (2026-06-29 feasibility session): the seam-deletion paths are FALSIFIED → STOP-and-BANK

Owner approved a design-first §4.4 pass, then "lead with a probe," then (twice) narrowed to the local path, then
"probe ordered-traversal feasibility first." All probes were RUNTIME-ONLY (Puppeteer `PRELUDE_JS` single-test +
`AUDIT_PRELUDE` full-suite); tree stayed clean at `c8098e6d`. **Verdict: the seam cannot be deleted by any tractable
means; the capstone-green Stage 3 is the resting point. The waste is already gone — what remains is a legitimate
convergence-driver.**

**KEY NEW FINDING — the arrange is SINGLE-PASS-CORRECT.** Geometry capture of `ScrollPanelWdgt._positionAndResizeChildren`
on `NoSpuriousScrollbars` (seam on): `C.out` is ALWAYS the correct box+viewport union, in one PARC call; the box's
local position is stable; `keepContents` is a no-op for that test. The de-risk's alarming "nb=530×400" is simply the
CORRECT frame for a box still at the origin. ⇒ **the de-risk's "centered-icon needs §4.4 ordering" interpretation is
WRONG** — it is not a layout-ordering problem inside the arrange. (CONFIRMS: don't touch the frame formula; the
non-content-sizing `@boundingBox()` read-back stays.)

**WHAT the seam actually does — orchestrate a multi-widget size↔position CONVERGENCE (NOT a one-shot notification).**
For the failing 10, the freefloating content's geometry is *scheduled* off-pass (public setter → `_invalidateLayout`)
but *applied* in-pass (its `_reLayout`'s raw setter during the flush). The container must re-fit AFTER that in-pass
application — exactly when the raw setter fires the seam. Instrumented counts on `NoSpurious`: **341 in-pass seam fires
vs 5 off-pass**; the box's position evolves `[0,0]→[315,220]→[225,140]` over PARC calls, driven by `keepContents`
moving the content (children translate with it), NOT by a one-shot `@desiredPosition`. So the system (content frame
size ↔ content scroll position) is a **coupled fixpoint** the seam re-enqueues until converged — across the settle
loop's multi-widget interleaving (other widgets settle between the container's passes).

**FALSIFIED THIS SESSION (each a clean reverse-probe, seam no-op'd):**
- **D1 — off-pass freefloating-climb** (a freefloating child's off-pass `_invalidateLayout` climbs to its tracking
  container, reusing the seam's container selection). `d1only` (climb added, seam intact) = **165/165** → the climb is
  byte-SAFE. `d1probe2` (climb + delete only `_reFitContainerAfterRawGeometryChange`, `_reFitContainer` intact) =
  **same 10 fail, recovers 0**. REASON: the off-pass climb fires at SCHEDULING time, before the content's geometry is
  applied; the load-bearing notification is in-pass-POST-application, and the FLOWRULE forbids `_invalidateLayout`
  in-pass. The off-pass dirty-tree (and equally the two-flag's invalidation-time propagation) cannot deliver an
  after-application notification.
- **Ordered-traversal pre-settle** (each container arrange post-order-settles its content subtree's dirty descendants
  BEFORE measuring+sizing; patched scroll+stack+window; seam no-op'd) = **same 10 fail, recovers 0** (verified the patch
  applied: `scroll=true stack=true window=true`; single-test `NoSpurious` still fails). REASON: the box's position is
  driven by `keepContents` (content move), not a pending descendant `_reLayout`, so pre-settling descendants doesn't
  capture the size↔position fixpoint. (A synchronous in-arrange fixpoint was already falsified in a prior session — the
  convergence needs the settle loop's cross-widget interleaving, which no single container's arrange can reproduce.)

**CUMULATIVE do-NOT-reattempt (all falsified across this arc):** non-notifying conversion · synchronous in-arrange
fixpoint · the content-sizing `@contents.width()` read-back removal (byte-exact but MARGINAL — doesn't reduce the seam)
· dropping the non-content-sizing `@boundingBox()` read-back (breaks 9, LOAD-BEARING) · the "content's own `_reLayout`
edge" framing · the local D1 off-pass climb · the ordered-traversal content-first pre-settle · **the analytic position↔frame
DECOUPLING (FALSIFIED 2026-06-29 — see below).**

**ANALYTIC DECOUPLING — TESTED + FALSIFIED (owner-requested, 2026-06-29).** The decoupling would compute the converged
content frame in ONE pass (no iteration). Its UPPER BOUND is the *synchronous fixpoint* (iterate the container's
arrange — incl. its trailing `keepContents` — to its own internal fixpoint within one visit); if iterating can't make
the seam redundant, no one-pass formula can. Probe: wrap `_positionAndResizeChildren` on scroll+stack+window in a
≤16-iter fixpoint loop (`scroll=true stack=true window=true` confirmed) + no-op the seam → **same 10 fail, recovers 0**.
ROOT CAUSE (decisive): the container's arrange is **already idempotent** (geomcap: `C.out == C.in` on every settled
state), so iterating it is a NO-OP — there is **no internal multi-pass convergence to decouple**. The seam's role is
NOT to converge a single container's arrange; it is the **multi-widget notification** (a freefloating content's
geometry, applied *in-pass* by its own `_reLayout` during the flush, must re-fit its tracking container in a *different*
settle visit), which no single-container frame formula — iterative or one-pass — can address. ⇒ **NO seam-deletion path
remains.**

**STOP-and-BANK rationale (sanctioned by §6).** The elimination mandate's CORE — delete the convergence/suppression
*waste* — is ALREADY achieved: Stage 3 made the arrange non-notifying (capstone GREEN 18→0). The seam now carries ONLY
a legitimate dependency edge: a freefloating content's in-pass geometry change must reach its size-tracking container,
which (given the FLOWRULE separating mutation from layout-scheduling, and the multi-widget convergence) is effectively
irreducible without re-architecting the settle loop into a true topological ordered traversal — the assessment's
biggest+riskiest change, whose cheap proxy (the pre-settle above) just failed byte-exactness. Leaving the seam is the
sound resting point. **ALL identified seam-deletion paths are now exhausted (local climb, ordered pre-settle, analytic
decoupling/synchronous fixpoint) — there is no known next step. Revisiting would require a fundamentally different
architecture (e.g. making the freefloating content's geometry application itself part of the container's ordered visit,
not a separate settle chain-top) — a far larger undertaking than this arc, not currently justified given the
capstone-green resting point.**
