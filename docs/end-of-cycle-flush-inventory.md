# End-of-cycle layout-flush — survey report + EXECUTED self-settle conversion

**Status: SURVEY + FIRST CONVERSION SHIPPED (2026-06-23).** The survey answered the owner's question (*what reaches
the end-of-cycle layout flush, why isn't it settled, should it be?*); the first conversion then **shipped** and cut
end-of-cycle traffic −55% (§1, §5b). Behaviour DID change — verified by the full gauntlet + torture.

**Method (hybrid).** Static catalog of enqueue origins (`end-of-cycle-catalog.md`, 84 sites) → **runtime audit** of
which actually survive to the end-of-cycle flush, attributed to the triggering action → classify → convert. The
audit ran the **whole 165-macro suite headless at dpr1** with a behaviour-neutral, inspector-invisible prelude.
**Tooling + how to (re)generate these numbers: `end-of-cycle-audit-tooling.md`** (committed at
`Fizzygum-tests/scripts/end-of-cycle-audit/`).

---

## 1. TL;DR — the owner's hypothesis is CONFIRMED; the conversion was EXECUTED (−55%)

> **✅ EXECUTED & VERIFIED 2026-06-23.** This report's FIRST PASS (below) **under-counted** the opportunity — it
> rationalised the biggest slice (`Widget.destroy`, ~40%) as "continuous, leave." That was wrong. The self-settle
> conversion shipped and proved highly worthwhile: end-of-cycle interaction records **1244 → 564 (−55%)**,
> `Widget.destroy` **505 → 16**, with `fg gauntlet` (dpr1/dpr2/WebKit/apps) 165/165 + an 18-min torture soak green.
> The hypothesis — *discrete state changes that should self-settle through a public API are leaking to end-of-cycle*
> — **holds**: we found and fixed two public methods that did NOT self-settle (`sizeToTextAndDisableFitting`,
> `setLabel`) and removed a pile of wasted freefloating-teardown re-layouts. The continuing campaign — drive the
> queue down, one contributor at a time — is `end-of-cycle-flush-drawdown-plan.md`.

> **Follow-on (2026-06-23):** the freefloating-teardown skip that drove this −55% was later **centralized** into an
> optional `triggeringChild` param on `Widget.invalidateLayout` — one home for the rule, a byte-identical refactor
> (flush-neutral; these numbers unchanged). A proactive widening sweep found **no further skip targets** (the indirect
> membership hooks are the complementary `_reFitContainer` axis, where a freefloating child DOES contribute). Full
> record: `freefloating-invalidation-skip-centralization-plan.md`.

The hypothesis was: *most of what lands at end-of-cycle are discrete state changes that **should** have
self-settled through a public API; an empty end-of-cycle queue should be the steady state, so a non-empty one is a
smell.*

**First-pass reading (since corrected — kept for the data + method).** The first pass classified ~91% of traffic as
"legitimately-batched continuous work, leave," and judged the convert opportunity "<1%." The executed conversion
showed a big part of that was NOT continuous but **wasted or should-self-settle** (the `destroy` slice especially).
So the right end-state is to **drive the end-of-cycle queue DOWN** — treat each non-continuous contributor as a
candidate public method that should self-settle (the proven `destroy` playbook) — leaving a residual **allowlist**
only for the genuinely-continuous (hover, drag, per-frame steps). That residual still backs the eventual "warn on
un-allowlisted end-of-cycle layout" gate (§8).

> **⚠ Revision (owner review).** The biggest single slice — **`Widget.destroy` teardown (505, ~40%)** — was
> *not* "legitimately continuous" after all; that was a settle-count rationalization. It is **actionable** (see §5b):
> the freefloating part (menus/tooltips) schedules a **wasted** parent re-layout that should be skipped, and the
> rest should **self-settle** like `add` for consistency-on-return. So the actionable set is far larger than the
> <1% the first pass implied — and the survey's "mostly correct" framing holds only for the genuinely-continuous
> hover/drag/edit work, not for teardown.

---

## 2. Trust — does the data deserve belief? (all green)

- **Pixel-neutral:** the instrumented suite passed **165/165 at dpr1, byte-identical** to a clean run. The prelude
  is pure observation (audit state in a `WeakMap`, off the widgets; no globals) and is **invisible to the live
  `InspectorWdgt`** (which enumerates a target's enumerable instance properties) — verified by the inspector tests
  passing.
- **Snapshot fires exactly once/frame at the right place:** the cross-check (`window.recalculatingLayouts` must be
  set at the snapshot) **never** flagged a miss across all 165 tests.
- **Containment:** every runtime survivor maps to a catalog origin (§7). No unattributed dynamic path.
- **Boot excluded:** **0** end-of-cycle survivors occurred before the first input event (boot construction
  self-settles via the orphan/batch paths). The entire residual is *interaction*-driven — which also means the
  allowlist needs no "boot" category.

## 3. Q1 — Inventory (what reaches end-of-cycle)

- **735** distinct interaction frames (across the suite) had a non-empty end-of-cycle queue; **1244** origin
  records total; queue length per frame is small (median 2, max 6).
- **45 / 165** tests had **zero** end-of-cycle survivors (nothing deferred all run).
- **69** distinct origin *groups* (ctor × action); these roll up to **~21 distinct ACTIONS**.

## 4. Q2 + Q3 — Attribution & why-not-settled (the by-action inventory)

> **Current numbers** (2026-06-25 full-suite dpr1 audit, post the collapse + SwitchButton convert — **38** origin records across
> **30** interaction frames / 13 groups; trajectory **1244 → 564 → 320 → 278 → 253 → 140 → 80 → 73 → 38**). ALL FIVE settle-tier "stinks" now self-settle via the
> **single-mutation** `_settleLayoutsAfter`
> (`buildAndConnectChildren` 2026-06-23; `fullDestroy`/`close`/`collapse`/`unCollapse`
> 2026-06-24) — this flip is **flush-NEUTRAL** (the records were already deferred/gone) but it ZEROES the
> `collapse`/`unCollapse` + `childCollapsed`/`childUnCollapsed` rows below. (Older note — the teardown pass that drove
> 569→320:) an earlier session made `close`/`destroy`/`fullDestroy`
> **self-settle** (like `add`), which drove that drop. It also **re-classified the old "230-record hover" row**: that was
> mostly **menu-cleanup `close()`** re-fitting a ScrollPanel (it shared hover's `Set.forEach < playQueuedEvents` sig,
> so the first pass mislabelled it as pointer-dispatch) — `close()` self-settling eliminated ~210 of it; the ~19
> residual is genuine hover/scroll. NB on noise: this metric counts how layout work is *distributed across frames*,
> wall-clock-sensitive (a heavy cycle drains several queued events in one frame — see `DETERMINISM.md`), so totals are
> **run-to-run noisy by a few records** even on a fixed build; read as order-of-magnitude, regenerate any time — see
> `end-of-cycle-audit-tooling.md`.
>
> **2026-06-25 (collapse + SwitchButton convert — RE-AUDIT DONE; total 73 → 38, the biggest residual ELIMINATED):**
> CONVERTED `SwitchButtonWdgt.mouseClickLeft` (the window-collapse toggle, the **32-record biggest residual**): the
> discrete click now SELF-SETTLES (`@_settleLayoutsAfter` around the `@buttonShown` toggle + `_invalidateLayout`)
> instead of riding the per-frame flush — `escalateEvent` stays outside the settle (the ancestor handler self-settles
> independently). The audit confirms `SwitchButtonWdgt.mouseClickLeft` is GONE from the origin records. ENABLED by the
> companion [G] hardening: the width-driven collapse decisions in the layout passes
> (`WindowWdgt._positionAndResizeChildren`'s editButton / internalExternalSwitchButton;
> `HorizontalMenuPanelWdgt._reLayoutSelf`) were ROUTED from the public self-settling `collapse()`/`unCollapse()` to the
> now-idempotent `_collapseNoSettle`/`_unCollapseNoSettle` cores — so the synchronous settle can re-enter those passes
> without hitting the one-flush throw. `check-layering` rule [G] now COVERS collapse/unCollapse (removed from
> `WRAPPER_EXCLUDED`). Byte-identical: full gauntlet (dpr1/dpr2/WebKit 165/165) + dpr2 torture; audit neutrality 165/165.
> Lesson: the prior "OPEN — re-probe; likely CONVERT" verdict was right — the convert is clean once the layout-pass
> collapse calls route to cores. (lint-ratchet follow-up C3; [[fizzygum-end-of-cycle-flush-drawdown]].)
>
> **2026-06-25 (contained-text re-fit refactor — RE-AUDIT DONE; total 278 → 253):** the contained-text re-fit lives on
> **`StringWdgt._reFitContainedTextNoSettle`**, and this session converted all seven API-path setters
> (`setText`/`setFontSize`/`setFontName`/`toggle*`) to the **SINGLE** `_settleLayoutsAfter` (was the BATCH
> `_settleLayoutsAfterBatch`; tier renames for old docs: `_settleLayoutsAfter` was `mutateGeometryThenSettle`,
> `_settleLayoutsAfterBatch` was `settleLayoutsOnceAfter`). An API/menu/connection edit now flushes SYNCHRONOUSLY at the
> setter and **leaves the end-of-cycle queue entirely** — the audit confirms it: the old **120-record
> `reLayoutAndRefreshContainerIfContainedText` action is GONE (0; absent from the rollup)**. The surviving
> contained-text traffic is the **CARET-editing path only**: `SimplePlainTextScrollPanelWdgt` re-fitting during
> `playQueuedEvents` (per-keystroke typing), **~84 records**, rolled up under the "(untagged) hover/pointer-dispatch"
> row because it shares the `Set.forEach < playQueuedEvents` sig (the SAME mislabel the old menu-cleanup `close()` had).
> That caret path was the presumed next convert — but a same-day stack probe (§5c) proved it **wasted work, not a
> missing self-settle**, so it was ELIMINATED, not converted (see the next block). **Tooling fix (2026-06-25):** the prior session's audit
> captured ZERO origins — the prelude patched the renamed `invalidateLayout` (now `_invalidateLayout`); fixed
> (`invPatched=true`), so THIS is the first valid post-rename audit.
>
> **2026-06-25 (caret-seam WASTED-WORK elimination — RE-AUDIT DONE; total 253 → 140, −45%):** the ~84-record caret
> path was NOT a convert. An unfiltered-stack probe (§5c) pinned the survivor: the **caret repositioning ITSELF**
> (`CaretWdgt.gotoSlot`'s `@fullRawMoveTo`) trips the raw-geometry re-fit seam (`_reFitContainerAfterRawGeometryChange`)
> and defers a container re-fit. But the caret is `isLayoutInert` overlay chrome, EXCLUDED from container
> content-bounds, so its move cannot change the container's fit; the genuine scroll-on-edit is already applied
> SYNCHRONOUSLY by `ScrollPanelWdgt.scrollCaretIntoView`. So it is **wasted work, not a missing self-settle** — the
> public mutator in the flow (`setText`) already self-settles (no contract breach; cf. §5c). Skipping the seam for
> `isLayoutInert` widgets (caret **and** resize handles) removed it; because handles are layout-inert too, the
> handle-move re-fits that shared the untagged hover bucket went with it — **hover/pointer 117 → 9**, during-paint
> 10 → 7, setMaxDim 6 → 4, total **253 → 140**. Byte-identical gauntlet + 0-nondeterminism torture confirm the removed
> re-fits were pure redundancy.
>
> **2026-06-25 (drag/DROP gesture CONVERT — RE-AUDIT DONE; total 140 → 80, −43%):** the drag/drop row had been
> dismissed "LEAVE — the deferred-layout campaign deliberately defers these" — a **circular** verdict (that campaign's
> goal was to PUSH re-fits ONTO the cycle; the drawdown's is to drive them OFF). A drop is a DISCRETE re-parent
> gesture. `ActivePointerWdgt.drop` does `target.add` (public, self-settles) then `_reactToDropOf` + `_justDropped`,
> whose recipient re-fit + final-spec change DEFERRED. A disable-the-mechanism probe proved that re-fit is NECESSARY
> (6 stack tests fail without it) — so it is a CONVERT, not the caret's eliminate: wrapping `_reactToDropOf` +
> `_justDropped` in ONE `_settleLayoutsAfter` over non-settling cores (keeping `add`'s settle FIRST so `_justDropped`
> reads settled geometry) drives the **`reactToDropOf` action to 0** (was ~62). The symmetric `reactToGrabOf` (7) + `childRemoved`
> (2) are the SAME pattern, not yet converted — the next targets. Full record: §5d.

Rolled up by **action** (the convert-vs-leave unit), interaction frames, with the §5 verdict:

> **⚠ ALL "LEAVE" VERDICTS RETRACTED (owner, 2026-06-25).** The earlier leave assessments were cavalier — **nothing**
> is allowlisted as "legitimately continuous, leave it" until its discrete-vs-continuous nature is *verified*. Every
> verdict that was **LEAVE** now reads **OPEN — re-probe**: pin the actual enqueue stack (§ technique), and for a
> suspected-continuous prove the interaction record is a raw EVENT STREAM, not a discrete public mutator returning
> unsettled; disable-probe a suspected-wasted re-fit. The prior is strong: drop, grab, teardown, collapse, and
> contained-text were **all** once "LEAVE" and **all** turned out CONVERT or eliminate — a "LEAVE" here has been far
> likelier wrong than right. (§6's "allowlist" is likewise PROVISIONAL until each entry is re-probed.)

| action (trigger) | records | tests | nature | why it defers | **verdict** |
|---|--:|--:|---|---|---|
| `Widget.destroy` / `close` / `fullDestroy` (teardown) | 0 | 0 | teardown | **self-settles**, like `add` — ALL now via the single-mutation `mutateGeometryThenSettle` (`close`/`fullDestroy` flipped off the batching tier 2026-06-24; bulk-teardown loops `fullDestroyChildren`/`closeChildren` use cores) — gone from end-of-cycle | **DONE** (self-settled) |
| *(untagged)* **hover / pointer-dispatch** (genuine hover/scroll) | **9** | 5 | continuous | one settle/frame is correct batching | **OPEN — re-probe** (hypothesis: continuous hover/scroll, one-settle-per-frame is correct — VERIFY, don't assume). The ~84 `SimplePlainTextScrollPanelWdgt` per-keystroke caret re-fit **plus** the layout-inert HANDLE-move re-fits that used to inflate this row (shared `playQueuedEvents` sig) were **ELIMINATED 2026-06-25** as wasted decoration work (§5c) — 117 → 9. |
| `StringWdgt._reFitContainedTextNoSettle` (contained-text edit, **API path**; was `TextWdgt.reLayoutAndRefreshContainerIfContainedText`) | **0** (was 120) | 0 | — | the 7 API-path setters now **single**-self-settle (`_settleLayoutsAfter`), so this leaves end-of-cycle entirely (see the 2026-06-25 note above); the per-keystroke CARET residual that remained was then eliminated-as-wasted (§5c), so contained-text no longer reaches end-of-cycle at all | **DONE** (API path self-settles 2026-06-24; caret residual eliminated 2026-06-25) |
| `*._reactToDropOf` (drag/DROP) | **0** (was ~62) | 0 | discrete re-parent gesture | — | **CONVERTED 2026-06-25** — the drop self-settles (`ActivePointerWdgt.drop` wraps `_reactToDropOf`+`_justDropped` in ONE single settle over non-settling cores); overturned the earlier "LEAVE" (§5d). |
| `*.reactToGrabOf` (drag/GRAB) | **0** (was 7) | 0 | discrete re-parent gesture | — | **CONVERTED 2026-06-25** — the grab self-settles (`ActivePointerWdgt.grab` wraps the recipient `reactToGrabOf`→`_reactToGrabOfNoSettle` in ONE single settle over non-settling cores); the symmetric twin of the drop (§5e). |
| `PanelWdgt.childRemoved` (tree removal) | 2 | 2 | discrete removal | a child removed from a scroll panel **mid string-edit** re-fits the container, deferred | **CONVERT candidate** (SEPARATE from the grab — string-edit path, not a grab gesture; §5e) |
| `SwitchButtonWdgt.mouseClickLeft` (window collapse toggle) | **0** | 0 | discrete click | **self-settles** via `_settleLayoutsAfter` (CONVERTED 2026-06-25; enabled by routing the layout-pass collapse decisions to the `_collapseNoSettle`/`_unCollapseNoSettle` cores) — gone from end-of-cycle | **DONE** (converted; was the 32-record biggest residual) |
| `Widget.collapse` / `unCollapse` | **0** | 0 | discrete | **self-settles** via `mutateGeometryThenSettle` (flipped 2026-06-24; collapse-hook `destroy` + bar-button re-`add` use cores) — gone from end-of-cycle | **DONE** (self-settled) |
| `WindowWdgt.childCollapsed` / `childUnCollapsed` | **0** | 0 | discrete | parent reaction, now inside collapse's single settle | **DONE** (folded into collapse self-settle) |
| *(untagged)* **during-paint** (freefloating re-fit from `fullPaintInto…`) | 7 | 1 | curiosity | a freefloating widget recomputed lazily at paint | **OPEN — re-probe** (hypothesis: self-contained paint-time recompute; §11 — VERIFY) |
| *(untagged)* **macro-driver** (test fixture-build macros) | 14 | 9 | test-construction | harness builds fixtures mid-test | **out of scope** (not product) |
| `Widget.setMaxDim` (stack-divider drag) | 4 | 1 | continuous-ish (divider drag) | constraint change invalidates | **OPEN — re-probe** (hypothesis: continuous divider drag — but is it a discrete `setMaxDim` public mutator? VERIFY) |
| `SimplePlainTextWdgt.setSoftWrap` | 1 | 1 | discrete | family 5, **left synchronous** by prior decision | **OPEN — re-probe** (discrete; family-5 soft-wrap was left synchronous by a prior decision — re-verify that decision) |
| **`VerticalStackLayoutSpec.setAlignment*` / `setWidthOfElementWhenAdded`** | **2** | **1** | **discrete menu pick** | sets a layout-spec property, re-fits via the seam | **CONVERT candidate** |
| `Widget.newParentChoice` (re-parent menu) | 0 | 0 | discrete menu | deferred via `_reFitContainer` (none surfaced this run) | **CONVERT candidate** (or allowlist) |

## 5. Q4 — Should it self-settle? (the verdict, with rationale)

Applying the rubric (continuous/high-frequency → leave; discrete one-shot → convert candidate; category-3 → out of
scope; boot → n/a here):

- **~~LEAVE (the legitimate residual, ~95% of records)~~ — RETRACTED 2026-06-25 (see the §4 banner).** The first pass
  parked hover/pointer-dispatch, teardown (`destroy`), content-edit, drag/drop, collapse-adjacent, stack-divider and
  soft-wrap here as "continuous, leave." That was cavalier: teardown, content-edit, drag/DROP, GRAB and collapse have
  **all since CONVERTED or been eliminated** (§5b–§5e); the remainder (hover, during-paint, `setMaxDim`, soft-wrap) are
  now **OPEN — re-probe**, not leave. "One settle/frame is the correct batching" is the HYPOTHESIS to verify per item,
  not the default — a record is only left once *proven* a raw event stream, never because a public mutator returning
  unsettled is convenient to call continuous. (Determinism risk is real but is checked by the gauntlet+torture on each
  actual convert, not assumed in advance.)
- **CONVERT candidates (the genuine discrete minority, ~7 records):** the **`VerticalStackLayoutSpec` property
  setters** (the textbook case — a discrete menu pick that currently relies on end-of-cycle) and **`newParentChoice`**.
  These *could* wrap their seam call in `settleLayoutsOnceAfter` (the setters already guard with `unless @x == x`,
  so they're idempotent). **But the payoff is tiny** (exercised in a single test) and each conversion is
  determinism-sensitive. **Recommendation: do not pursue broadly; optionally convert the layout-spec setters as a
  one-off if/when that code is next touched.**

**On the #1 contributor, `Widget.destroy` (505).** Fizzygum separates **`close()`** (the user-facing "close/delete":
re-parents the widget into the *basement* — a revivable recycle-bin — via `add`, so it **self-settles** both sides,
including the old parent via `_addCore`'s invalidate at `Widget.coffee:2413`) from **`destroy()`** (single-node
teardown) and **`fullDestroy()`** (recursive whole-tree teardown).

> **⚠ REVISED VERDICT (owner decision — supersedes the initial "LEAVE"; full design in §5b and the conversion plan).**
> The teardown trio should be **public and self-settle like `add`.** The initial "LEAVE" weighed *settle-count*; the
> decisive counters are **(1) consistency-on-return** — a public mutator must leave the world consistent when it
> returns (if you `destroy()` a widget inside a stack/scroll-panel, the container should already reflect the removal,
> exactly as after `add`), and **(2) add/remove symmetry** — a tooltip is *added* on hover via the self-settling
> `add` and *destroyed* on leave via the deferring `destroy`; the add side already self-settles per-call without
> issue, so the remove side should too. **Plus a bigger efficiency lever:** `destroy`/`removeFromTree` invalidate the
> parent **unconditionally** (`Widget.coffee:519`/`2081`), bypassing the freefloating climb-guard
> (`Widget.coffee:3766`). For a **freefloating** widget (menus, tooltips — the bulk of the 505), the parent re-layout
> is **wasted** (the world's layout doesn't depend on a freefloating child; the settle loop already treats
> freefloating as a layout root, `WorldWdgt.coffee:914`). Skipping it eliminates the dominant teardown traffic *and*
> de-risks the self-settle conversion (nothing to settle in the hot menu/tooltip path).

## 5b. REVISION — the teardown trio should self-settle (two-part fix)

> **✅ EXECUTED & VERIFIED 2026-06-23.** Shipped: freefloating-skip on `destroy`/`removeFromTree`/`_addCore` + the
> exposed public methods made to self-settle (`TextWdgt`/`StringWdgt.sizeToTextAndDisableFitting`,
> `LabelButtonWdgt.setLabel`). `fg gauntlet` 165/165 (dpr1/dpr2/WebKit/apps) + 18-min torture (zero
> nondeterminism). **This audit's headline numbers move: `Widget.destroy` 505 → 16, total interaction records
> 1244 → 564 (−55%), non-empty frames 735 → 472**, prelude-neutrality intact. Follow-ons:
> `freefloating-invalidation-skip-centralization-plan.md`, `end-of-cycle-flush-drawdown-plan.md`.

This supersedes the initial "LEAVE `destroy`" verdict. Design lives in
`end-of-cycle-self-settle-conversion-plan.md`; summary:

**Part 1 — freefloating-skip (the big lever, do first).** Make `destroy`/`removeFromTree` honor the same
freefloating principle the climb-guard already encodes: **skip `@parent?.invalidateLayout()` when the destroyed
widget is `ATTACHEDAS_FREEFLOATING`** (mirror `Widget.coffee:3766`). A freefloating child (menu, tooltip,
free-dragged window) does not participate in its parent's layout, so re-fitting the parent on its removal is wasted —
today it is unconditionally scheduled *and* applied (the world's `_reLayout` runs and changes nothing). This alone
removes the **largest** slice of end-of-cycle teardown traffic (the ~261 `WorldWdgt`-from-`destroy` records) and
shrinks the conversion's blast radius to the cases that actually matter.

**Part 2 — self-settle the residual (non-freefloating) teardown.** For a widget that *does* participate in a
container's layout (in a stack / scroll-panel), make teardown consistent-on-return:
- `destroy` (single node) → wrap its body in **`mutateGeometryThenSettle`** (orphan-checked at *entry*, where the
  widget is still attached, so it flushes correctly).
- `fullDestroy` (recursive) → wrap the recursion in **`settleLayoutsOnceAfter`** so N descendant teardowns batch to
  **one** settle of the surviving container — but anchor it on a **survivor** (`world.settleLayoutsOnceAfter` or the
  captured parent), **never `@`**, because `settleLayoutsOnceAfter` orphan-checks at the *tail* and `@` (the
  destroyed root) is orphan by then → the flush would be silently skipped.

**Verification gates:** (i) audit all teardown callers for mid-pass calls — `mutateGeometryThenSettle`/
`settleLayoutsOnceAfter` *throw* during a layout pass/flush (a feature: surfaces hidden violations, but must be
handled); (ii) full gauntlet (dpr1/dpr2/WebKit + app smoke + torture soak) since settle timing/count per frame is
dpr2-under-load-sensitive. Net effect on this report: the teardown slice moves **LEAVE → (Part 1) eliminate /
(Part 2) convert**, materially enlarging the actionable set beyond the <1% the first pass found.

## 5c. REVISION — the per-keystroke caret container re-fit was WASTED, not a convert (eliminate)

> **✅ EXECUTED & VERIFIED 2026-06-25.** Total end-of-cycle records **253 → 140 (−45%)**; the
> `SimplePlainTextScrollPanelWdgt | playQueuedEvents` caret group (84) is **gone**, the untagged hover/pointer row
> collapsed **117 → 9**. `fg gauntlet` (dpr1/dpr2/WebKit/apps) 165/165 byte-identical + dpr2 torture (shards=4,
> ~1,155 execs) 0 nondeterminism + re-audit neutrality 165/165.

After the API-path setters went single (§4 note, contained-text 120 → 0), the largest remaining contributor was the
editing scroll-panel re-fitting **once per keystroke** (~84 records, dominated by `macroWrappingTextFieldResizesOK`
typing a ~400-char string). The drawdown plan had labelled this the "prime convert candidate" by analogy to
`sizeToTextAndDisableFitting`. **That label was wrong**, and *how* we proved it is the reusable lesson:

**1. Pin the stack before classifying.** The audit's `shortSig` is truncated AND filters out `eval` frames — and
since Fizzygum compiles every class in-browser, *every framework method is an `eval` frame*, so the recorded sig
(`Object.playQueuedEvents < e`) hides the real call chain. A throwaway probe prelude (`PRELUDE_JS`) that dumps the
UNFILTERED stack, gated on `!world._inLayoutMutation` (= the genuine end-of-cycle survivors, not the drained
in-settle enqueues), revealed it in one run:
`_invalidateLayout ← _reFitContainer ← _reFitContainerAfterRawGeometryChange ← fullRawMoveBy ← CaretWdgt.gotoSlot ←
goRight ← insert ← processKeyDown`.

**2. The discriminator: is a PUBLIC API mutator on the survivor's stack, returning unsettled?** It is not. The one
public mutator in the keystroke flow, `setText`, self-settles correctly (the probe's `drained` counter proved its
own container re-fits flush *inside* its settle). The survivor is the **caret moving ITSELF** — a raw move of overlay
chrome. So this is NOT the public-API-consistency fault that §3b *converts*; it is the **wasted-work** fault that §3
*eliminates* (the `destroy`/freefloating pattern), one rung lower:

- The caret (and resize handles) are `isLayoutInert` — overlay chrome EXCLUDED from every container's content-bounds
  (`TreeNode.childrenNotHandlesNorCarets`, `WindowWdgt.add`). Their geometry cannot change the container's
  content-fit, so tripping the container re-fit seam on their raw moves schedules a re-fit that **changes nothing**.
- The genuine scroll-on-edit is already applied **synchronously** by `ScrollPanelWdgt.scrollCaretIntoView`; the
  deferred seam re-fit was pure redundancy.

**Fix:** `Widget._reFitContainerAfterRawGeometryChange` returns early for `isLayoutInert` widgets. Because handles are
layout-inert too, this also drained the handle-move re-fits that shared the untagged hover bucket — hence the row
collapsing **117 → 9**, well past the 84 caret records alone. This is the **second instance** of the wasted-work
pattern after `Widget.destroy` (§5b): *a widget that does not participate in a container's layout must not schedule
that container's re-fit.*

## 5d. REVISION — the drag/DROP gesture is a CONVERT (the "LEAVE" was circular)

> **✅ EXECUTED & VERIFIED 2026-06-25.** Total **140 → 80 (−43%)**; the `reactToDropOf` action (was ~62) is **0**.
> Landed in TWO steps: first as a batch (ce5e78b7), then converted to a **SINGLE settle over non-settling cores** — the
> principled end state (see "The fix"). The count is identical across the two (single doesn't move WHERE the drop
> flushes — once, at the gesture — it hardens HOW). `fg gauntlet` (dpr1/dpr2/WebKit/apps) 165/165 byte-identical + dpr2
> torture (shards=4) 0 nondeterminism + neutrality 165/165 (one benign inspector member-list recapture each step — the
> hook rename, then the two new `_create*NoSettle` base methods).

The biggest residual after the caret elimination was the drag/drop family, dismissed as *"LEAVE — the deferred-layout
campaign deliberately defers these."* **That verdict was circular:** the deferred-layout campaign's goal was to push
synchronous re-fits ONTO the cycle (centralize layout); the drawdown's is to drive them OFF. "The other campaign put
it here on purpose" is not a classification under our rubric — and a drop is a **discrete re-parent gesture** (§2.3
convert candidate), not continuous.

**Mechanism.** `ActivePointerWdgt.drop` does, in order: `target.add` (public, self-settles → the dropped widget is
placed) → `_reactToDropOf` (recipient re-fits / rebuilds chrome) → `_justDropped` (the dropped widget tweaks its OWN
spec — `rememberFractionalSituationInHoldingPanel`, `constrainToRatio`). The recipient re-fit + the post-`_justDropped`
spec change DEFERRED to end-of-cycle (the ~62 records).

**Convert, not eliminate — proven by a disable-the-mechanism probe.** No-op'ing the stack's deferred `_reactToDropOf`
re-fit failed **6 stack-drop tests** — so unlike the caret (§5c), this re-fit is NECESSARY (it re-flows the stack
after the spec is finalized, which `add`'s earlier settle predates). So the fix is to make the gesture **self-settle**,
not to delete the re-fit.

**The fix.** Wrap `_reactToDropOf` + `_justDropped` in ONE settle, AFTER `add`'s settle. Two non-obvious constraints
fixed the shape:
- **Keep `add`'s settle first** (don't wrap the whole drop): `_justDropped` READS the dropped widget's settled
  geometry (`@width()`/`@height()`, fractional-in-parent), so absorbing `add`'s settle would feed it stale geometry.
- **SINGLE over non-settling cores, not batch.** The tail dispatches to an OPEN-ENDED set of recipient hooks (13
  `_reactToDropOf` overrides) that legitimately do structural work — rebuild window chrome, `fullDestroy`, re-home via
  `add`, create-a-reference-and-`close`, recompile tiles. The first landing (ce5e78b7) used `_settleLayoutsAfterBatch`,
  which ABSORBS those nested public self-settlers (batch's whole job), because `WindowWdgt._reactToDropOf`'s chrome
  rebuild (`buildAndConnectChildren`, many adds) crashed a NAIVE single mid-rebuild on the half-wired window (16
  window-drop tests). The FOLLOW-UP did it right: route every recipient through the NON-settling CORE
  (`buildAndConnectChildren`→`_buildAndConnectChildrenNoSettle`, `fullDestroy`→`_fullDestroyNoSettle`, `add`→
  `_addNoSettle`, `addInPseudoRandomPosition`→its core; and SPLIT the coreless ones into the standard public-wrapper /
  `_xNoSettle` pair — `createReference`/`createReferenceAndClose`, the popup `closePopUpsMarkedForClosure`, the
  fizzytiles `showCompiledCode`), then wrap the tail in SINGLE (`_settleLayoutsAfter`). `buildAndConnectChildren` was
  ALREADY this shape (single over 8 `_addNoSettle`s) — the precedent proving the "single can't nest a builder" fear
  unfounded; the rebuild just had to call the core it already owned. Single is the campaign's discipline: it THROWS if a
  future recipient sneaks in a public setter (cores-call-cores enforced at runtime); batch silently absorbs it.

**The hook rename (private calls private).** `reactToDropOf`/`justDropped` → `_reactToDropOf`/`_justDropped` (they are
framework-internal drop hooks). This surfaced one lint [A] hit — `SimpleDropletWdgt._reactToDropOf`'s public
`setBounds` → `silentRawSetBounds` (raw twin; byte-identical for the freefloating dropped widget). Under the SINGLE
tier the structural calls (`fullDestroy`/`add`/`buildAndConnectChildren`/…) go to their NON-settling CORES too (the
first batch landing left them public, since batch absorbed them). A cores-only hook needs EVERY caller to provide the
settle: the live drop does; the dead / homepage-excluded slide-back (`Widget.coffee` `slideBackTo`) got an explicit
`_settleLayoutsAfter` wrap. (`addAsSiblingAfterMe` needed no change — it already routes through `_addNoSettle`.) When
deleting a recipient's last settling caller orphans a public wrapper, the build's dead-method gate catches it
(`PanelWdgt.addInPseudoRandomPosition` was deleted, its core kept); a `_xNoSettle` twin that is a sibling-closer not a
wrapper/core is marked `# thin-wrap-exempt` (the popup closer).

## 5e. REVISION — the drag/GRAB gesture is a CONVERT (the symmetric twin of the drop)

> **✅ EXECUTED & VERIFIED 2026-06-25.** Total **80 → 73 (−7)**; the `reactToGrabOf` action (was ~7) now flushes
> IN-GESTURE — audit: **zero `_reactToGrabOfNoSettle` / grab records** across the whole suite. Done as a SINGLE settle
> over non-settling cores from the START — no batch intermediate, because the drop convert (§5d) had already routed every
> recipient through cores. `fg gauntlet` (dpr1/dpr2/WebKit/apps) 165/165 byte-identical + dpr2 torture (shards=4, 5 iters)
> 0 nondeterminism. **Zero recaptures** (no inspector-visible surface changed). NB the old "reactToGrabOf (7) + childRemoved
> (2)" lumping was misleading: only the GRAB is converted here; `childRemoved` (2) is a SEPARATE residual (see below).

A float-GRAB is the mirror of the drop, dismissed in the same breath as the symmetric counterpart. `ActivePointerWdgt.grab`
does, in order: `@add aWdgt` (public, self-settles — the grabbed widget is re-homed onto the hand; its `_addNoSettle`
re-parent already fires the OLD container's `childRemoved` re-fit INSIDE add's settle, so that is captured) → then, after
the shadow/paint, `oldParent?.reactToGrabOf?` (the old container re-fits — e.g. a ScrollPanelWdgt re-snugs its
contents+scrollbars after a widget leaves). That recipient re-fit DEFERRED to end-of-cycle (the ~7 records), exactly like
the drop's `_reactToDropOf`.

**Convert (consistent-on-return), not eliminate.** A grab is a discrete re-parent gesture, so its old-container re-fit
should land on return, not the next `doOneCycle`. Fix: wrap `oldParent?.reactToGrabOf?` in ONE `_settleLayoutsAfter`,
AFTER `@add`'s settle (mirroring the drop's tail at `ActivePointerWdgt.drop`). **No batch needed** — unlike the drop's
first landing, every grab recipient already re-fits through non-settling paths: `PanelWdgt`/`ScrollPanelWdgt` →
`_reFitContainer` (raw invalidate, no public setter); `FridgeWdgt` → `compileTiles` → `FizzytilesCodeWdgt.showCompiledCode`
→ `_setTextNoSettle` core (the `showCompiledCode` having been made non-settling for the drop's Fridge path in §5d). Single
THROWS if a future override sneaks in a public setter — the cores-call-cores discipline, enforced at runtime.

**The hook rename + the `NoSettle`-naming harmonization.** `reactToGrabOf` → `_reactToGrabOfNoSettle` (a private hook that
only ever runs inside the gesture's settle). And the owner-decided convention (2026-06-25): the **`NoSettle` suffix marks a
NON-SETTLING REGION** — a static-checkable "nothing downstream settles" contract — **not** "the core of a public/core
pair." So the drop's already-private hooks were harmonized to match: `_reactToDropOf` → `_reactToDropOfNoSettle`,
`_justDropped` → `_justDroppedNoSettle`. The thin-wrap gate **skips a twinless `*NoSettle`** (no public base to constrain,
`check-thin-wraps.js:57`), so none needs a `# thin-wrap-exempt`; the boundary that keeps the suffix meaningful — suffix the
gesture/lifecycle hooks where "does this settle?" is a real question, NOT the raw/silent primitives (already `raw`/`silent`)
nor `childRemoved`/`childAdded` (a public tree-lifecycle family). The suffix's payoff is a future check-layering ratchet — a
`*NoSettle` **transitive-no-settle** build lint (today the contract is only enforced at runtime, by the `FLOWRULE_VIOLATION`
throw on tested paths). See drawdown-plan §8 + memory `fizzygum-layering-naming-tiers`.

**`childRemoved` (2) is a SEPARATE residual — a next target, NOT this convert.** The post-convert audit shows the grab
gone but a `ScrollPanelWdgt` `PanelWdgt.childRemoved` re-fit (2 records) surviving on the STRING-EDIT tests
(`macroStringWdgtEditDefersToPromptWhenCropped`, `macroStringWdgtInlineTypingRefitsUnderFittingModes`) — a child removed
from a scroll panel mid-edit whose container re-fit defers. So the grab convert does NOT zero "removal": `childRemoved`'s
deferring path is a different mechanism from the grab gesture (it is NOT reached from `ActivePointerWdgt.grab`), and is left
for a dedicated convert/leave decision (find the off-settle removal path, disable-probe it). The grab's OWN `childRemoved`
— fired when `@add` re-homes the grabbed widget onto the hand — is already captured inside `@add`'s settle, which is why the
grab tests show no `childRemoved` survivors.

**Next:** `SwitchButtonWdgt.mouseClickLeft` (32, the biggest residual) is now **DONE** (converted 2026-06-25, see the
banner). `childRemoved` (2, string-edit path) remains the clearest discrete-action convert candidate; the rest of the
post-convert 38 is **OPEN — re-probe** (§6, a provisional suspect-list, not a settled allowlist) + the out-of-scope
macro-driver (14).

## 6. Q5 — The legitimate residual (the proposed allowlist)

> **PROVISIONAL pending re-probe (2026-06-25, §4 banner).** With the "LEAVE" verdicts retracted, this is a LIST OF
> SUSPECTS, not a settled allowlist — each entry must be re-probed and *proven* a raw event stream before it earns a
> permanent place. Several original entries (teardown, drag/DROP+GRAB, contained-text, collapse) have ALREADY converted
> or been eliminated since the first pass; treat every remaining one as **OPEN — re-probe**, not allowed.

The (provisional) list of what *might* legitimately reach end-of-cycle, by action class:

1. **Pointer/hover dispatch** — `ActivePointerWdgt` mouseEnter/mouseLeave (`mouseOverList`/`mouseOverNew` diff).
2. **Teardown** — `Widget.destroy` / `removeFromTree` (parent re-fit on child removal).
3. **Drag/drop/grab gestures** — ~~`reactToDropOf`~~ **CONVERTED** (the drop self-settles, §5d) + ~~`reactToGrabOf`~~
   **CONVERTED 2026-06-25** (the grab self-settles, §5e) — both off the allowlist now; `childRemoved` (the string-edit
   removal path, 2) remains a next convert candidate, NOT a permanent allowlist entry.
4. ~~**Contained-text edit**~~ — **removed from the allowlist 2026-06-25.** The API-path setters self-settle (§4) and
   the per-keystroke caret-move re-fit was eliminated-as-wasted (§5c), so contained-text **no longer reaches
   end-of-cycle at all** — it is neither a residual nor an allowlist entry now.
5. **Collapse/uncollapse** — `Widget.collapse`/`unCollapse` + `WindowWdgt.childCollapsed`/`childUnCollapsed` +
   the `SwitchButtonWdgt` toggle that drives them.
6. **Constraint/divider drag** — `Widget.setMaxDim` / `setMinAndMaxBoundsAndSpreadability`.
7. **Soft-wrap** — `SimplePlainTextWdgt.setSoftWrap` (family 5, deliberately synchronous-adjacent).
8. *(curiosity, monitor)* **paint-time freefloating re-fit** — §11.

Everything **outside** this list reaching end-of-cycle = a **smell**. Today the only things outside it are the
two convert candidates (§5) — i.e. the allowlist is already almost the whole story.

## 7. Phase X — coverage & gaps (no silent truncation)

Every runtime survivor maps to a catalog (C) entry ✓. Catalog (C) entries the **suite never exercised to
end-of-cycle** (so reasoned **by inspection**):
- **Same-mechanism siblings of seen actions** — `setAlignmentToLeft`/`setElasticity` (siblings of the seen
  `setAlignment*`/`setWidth…`), `removeFromTree` (folded into `destroy`), `setMinAndMaxBoundsAndSpreadability`
  (→`setMaxDim`, seen), `SwitchButtonWdgt.resetSwitchButton`. **By inspection: identical classification to their
  seen siblings.**
- **Discrete feature actions not hit** — `showAdders`/`removeAdders`, `ToggleButtonWdgt.setToggleState`,
  `ButtonWdgt`, `StretchableEditableWdgt.*`, `StretchableWidgetContainerWdgt.resetRatio`,
  `disableDragsDropsAndEditing`, `ToolPanelWdgt.add/addMany`, `attach`/`newParentChoiceWithHorizLayout`. **By
  inspection: each is a discrete `@invalidateLayout()`/seam call like the seen discrete actions — would defer to
  end-of-cycle the same way; no new category.**
- **The 12 desktop apps** (suite has **no** app coverage; owner chose "by inspection"). They are built from the
  same Widget primitives (drag/drop, collapse, destroy, content-edit, menus), so they would exercise the **same
  residual categories** above — **no new origin class expected.** (If desired, a prelude-capable app-runner could
  confirm; not built, per scope.)
- **(A) self-settling & (D) construction** catalog entries are *expected* never to survive — and indeed **0 boot
  survivors** confirms (D) self-settles.

**Gap honesty:** the convert-candidate conclusion rests on a single test exercising the layout-spec menus; the
unexercised discrete actions are classified by inspection, not measurement.

## 8. Q6 — Is "warn on end-of-cycle layout" naive? (the end-state)

**Not naive, but "empty queue" is the wrong target.** The data kills the literal-empty invariant: hover alone
fires on 87/165 tests, teardown on 94/165 — the steady state is *legitimately* non-empty. The achievable, valuable
invariant mirrors the existing build lint **[F]**: **every end-of-cycle origin must be on the §6 allowlist;
anything else warns.**

**Updated take (post-conversion):** as the drawdown campaign converts the discrete leaks (the `destroy` slice is
already done, −55%), the residual shrinks toward the genuinely-continuous core, and the **allowlist shrinks with
it** — so the warning becomes both a forward-looking regression tripwire AND an increasingly tight invariant. The
hypothesis was *not* wrong about there being leaks to expose; the first pass just mis-counted how many. Build the
gate (a `check-layering.js` extension with `# end-of-cycle-sanctioned: <why>` markers) once the drawdown
(`end-of-cycle-flush-drawdown-plan.md`) has driven the queue down far enough that the allowlist is small and stable.

## 9. Recommendations

- **Rung 0 (this survey): DONE.** Inventory + classification + allowlist + this verdict.
- **Rung 1 (conversions): WARRANTED for the teardown trio** (revised after owner review — see §5b). The
  `close`/`destroy`/`fullDestroy` self-settle + freefloating-skip is a real API-consistency + efficiency fix on the
  #1 contributor, scoped in **`end-of-cycle-self-settle-conversion-plan.md`**. The `VerticalStackLayoutSpec` property
  setters (~6 records) and `newParentChoice` (1) remain **optional micro-conversions** (wrap the seam call in
  `settleLayoutsOnceAfter` if/when that file is next touched).
- **Rung 2 (the warning): RECOMMENDED, in the build-lint form.** Two options, prefer the second:
  - *Runtime warn* — at `recalculateLayouts` entry when `!_inLayoutMutation`, `console.warn` if a queued origin's
    action is not allowlisted (dev/test builds only, stripped by `--homepage`). **This is literally this survey's
    prelude promoted into a permanent guarded check** — but it is only as good as test coverage and the allowlist
    must be maintained as a runtime set.
  - *Build lint (preferred)* — extend `buildSystem/check-layering.js`: a new discrete-action method that enqueues
    layout (`invalidateLayout`/seam) and is **not** in the allowlist must self-settle or carry an
    `# end-of-cycle-sanctioned: <why>` marker (mirroring the 16 existing `# layout-apply-sanctioned` markers).
    Static, regression-proof, no runtime cost. **Note this is a *different axis* than lint [F]** — [F] guards
    layout-*apply* off the settle path (category 3); this guards discrete *enqueue* without self-settle (category
    2). Complementary, same marker philosophy.

## 10. The owner's two examples, resolved

- **Wheel scroll** — confirmed **category-3 synchronous** (`ScrollPanelWdgt.wheel` applies
  `_positionAndResizeChildren`/`_reLayoutScrollbars` directly; sanctioned). It emits **no** end-of-cycle record.
  It already "settles" — synchronously, which for this determinism-risky path (OVERVIEW §5 family 1) is the
  *correct* form. **There is no scroll-settle API to add; it's already settled.**
- **Collapse** — **two arms.** The *container* re-fit (`WindowWdgt.childUnCollapsed → _reLayoutChildren`) is
  **synchronous & sanctioned** (`reInflating`-coupled). The *collapsing widget's own* `@invalidateLayout()` **does**
  defer to end-of-cycle (18+18 records) — a discrete one-shot. But it is correctly batched with the same frame's
  other work, and its parent re-fit already settled synchronously, so converting it buys nothing. **Leave + allowlist.**

So both flagship examples are *already settled* (synchronously); the actual end-of-cycle residual is the hover /
teardown / edit / drag work catalogued above — not the examples that motivated the question.

## 11. Appendix — the one curiosity worth a glance

**Layout invalidation reached from the PAINT pass** (14 records, 4 tests): a `ATTACHEDAS_FREEFLOATING` widget is
invalidated from inside `fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` (a child `Array.forEach`
during painting). It is self-contained (queue length 1, doesn't climb — freefloating) and harmless, but it means
**paint is triggering layout scheduling**, crossing the render/layout boundary. Low priority, but if the
render/layout separation is ever tightened, this is the spot to look (likely a lazy size/wrap recompute on a
freefloating text/scroll widget computed at draw time).

---

*Raw data & reproducibility:* see **`end-of-cycle-audit-tooling.md`** for the committed harness and the exact
run/diff recipe. Catalog of static origins: `end-of-cycle-catalog.md`. Follow-on work:
`end-of-cycle-self-settle-conversion-plan.md`, `end-of-cycle-flush-drawdown-plan.md`,
`freefloating-invalidation-skip-centralization-plan.md`.
