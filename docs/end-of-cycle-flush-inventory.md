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

> **These are the BASELINE numbers (1244 records, before any conversion).** After the first conversion the headline
> dropped to 564 (`Widget.destroy` 505 → 16; §1). Regenerate the current numbers any time — see
> `end-of-cycle-audit-tooling.md`.

Rolled up by **action** (the convert-vs-leave unit), interaction frames, with the §5 verdict:

| action (trigger) | records | tests | nature | why it defers | **verdict** |
|---|--:|--:|---|---|---|
| `Widget.destroy` (teardown of tooltips, menus, windows) | 505 | 94 | teardown | `removeFromTree`/`destroy` invalidate the parent **unconditionally**; no self-settle | **REVISED → §5b** (freefloating: eliminate; else: self-settle) |
| *(untagged)* **hover / pointer-dispatch** (`ActivePointerWdgt` mouseEnter/mouseLeave diff, `mouseOverList.forEach`) | 432 | 87 | **continuous** (every pointer move) | hover state change invalidates the hovered container | **LEAVE** (textbook batch) |
| `TextWdgt.reLayoutAndRefreshContainerIfContainedText` (contained-text edit) | 114 | 13 | **high-frequency** (per keystroke) | content edit re-fits the container via the seam | **LEAVE** (per-char settle is wasteful) |
| `*.reactToDropOf` / `reactToGrabOf` / `childRemoved` (drag/drop) | 75 | ~22 | **discrete gesture events** | the deferred-layout campaign **deliberately** defers these | **LEAVE** (already a conscious decision) |
| `SwitchButtonWdgt.mouseClickLeft` (window collapse toggle) | 32 | 6 | discrete click | invalidates on toggle | **LEAVE/convert** (entangled w/ collapse) |
| `Widget.collapse` / `unCollapse` | 36 | 7 | discrete | self-invalidate defers; parent re-fit is *synchronous & sanctioned* | **LEAVE** (mixed; see §10) |
| `WindowWdgt.childCollapsed` / `childUnCollapsed` | 8 | 2 | discrete | parent reaction | **LEAVE** (synchronous arm is sanctioned) |
| *(untagged)* **during-paint** (freefloating re-fit from `fullPaintInto…`) | 14 | 4 | curiosity | a freefloating widget recomputed lazily at paint | **LEAVE** (self-contained; §11) |
| *(untagged)* **macro-driver** (test fixture-build macros) | 14 | 9 | test-construction | harness builds fixtures mid-test | **out of scope** (not product) |
| `Widget.setMaxDim` (stack-divider drag) | 4 | 1 | continuous-ish (divider drag) | constraint change invalidates | **LEAVE** |
| `SimplePlainTextWdgt.setSoftWrap` | 3 | 2 | discrete | family 5, **left synchronous** by prior decision | **LEAVE** |
| **`VerticalStackLayoutSpec.setAlignment*` / `setWidthOfElementWhenAdded`** | **6** | **1** | **discrete menu pick** | sets a layout-spec property, re-fits via the seam | **CONVERT candidate** |
| `Widget.newParentChoice` (re-parent menu) | 1 | 1 | discrete menu | deferred via `_reFitContainer` | **CONVERT candidate** (or allowlist) |

## 5. Q4 — Should it self-settle? (the verdict, with rationale)

Applying the rubric (continuous/high-frequency → leave; discrete one-shot → convert candidate; category-3 → out of
scope; boot → n/a here):

- **LEAVE (the legitimate residual, ~95% of records):** hover/pointer-dispatch, teardown (`destroy`), content-edit,
  drag/drop, collapse-adjacent, stack-divider, soft-wrap. These are continuous, high-frequency, or already a
  *conscious* deferral by the deferred-layout campaign. One settle/frame is the **correct** batching; self-settling
  each event would inflate per-frame settle count and risk determinism (esp. dpr2-under-load).
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

## 6. Q5 — The legitimate residual (the proposed allowlist)

The enforceable allowlist (what is *allowed* to reach end-of-cycle), by action class:

1. **Pointer/hover dispatch** — `ActivePointerWdgt` mouseEnter/mouseLeave (`mouseOverList`/`mouseOverNew` diff).
2. **Teardown** — `Widget.destroy` / `removeFromTree` (parent re-fit on child removal).
3. **Drag/drop gestures** — `reactToDropOf` / `reactToGrabOf` / `childRemoved` on the container classes (already a
   conscious campaign deferral).
4. **Contained-text edit** — `TextWdgt.reLayoutAndRefreshContainerIfContainedText`.
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
