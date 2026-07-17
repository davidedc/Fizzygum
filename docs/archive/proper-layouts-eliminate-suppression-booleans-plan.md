> **ARCHIVED — COMPLETE (2026-07-17 restructure).** Phase E DONE 2026-06-28 (narrow flag deletion); full mandate later completed via geometry-seam-removal-plan.md
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Plan — "Proper layouts": COMPLETELY eliminate the layout-suppression booleans (spearhead: `@_adjustingContentsBounds`)

**Status: Phase E ✅ DONE 2026-06-28 (NARROW — the `@_adjustingContentsBounds` boolean is now 100% DELETED: field +
all three #1 re-entrancy guards GONE, byte-identical, determinism-verified; the §0 spearhead is eliminated). It was
done NOT the way the plan sketched (seam → dirty-tracking). The planned full seam deletion was EXECUTED as a probe and
REVERTED on a hard finding: deleting the generic seam dropped the capstone 18→7 but broke 8 scroll/drag/clock tests
because the scroll panels' "careless" end-of-cycle pushes ARE their layout-CONVERGENCE re-enqueues — a general scroll
panel re-fits its `@contents` over multiple passes driven by the seam's self-re-enqueue. So restoring the capstone for
scroll panels ⟺ making the general-scroll arrange a ONE-PASS fixed point, the exact problem Phase C deliberately
avoided (its naive fix broke 10 general panels — §5 Phase C). That entanglement hits the full-deletion path AND a
"non-notifying arrange" pivot. So the owner chose NARROW E: delete the flag now (low-risk, byte-identical), and defer
the seam deletion + capstone-green to a later CONVERGENCE arc (general-scroll one-pass + §4.4 dirty-tracking).
MECHANISM: the flag's last use was the per-arrange re-entrancy guard, caught only because each arrange sized ITSELF
(`@rawSetHeight`/`@rawSetWidth`) through its class `rawSetExtent` override, which re-ran `@_reLayoutChildren()`
synchronously (a guard no-op). Replaced with `SimpleVerticalStackPanelWdgt._applyOwnArrangedWidth/Height` → base
`Widget::rawSetExtent` (fires the up-notify seam, SKIPS `_reLayoutChildren`); that removes the last synchronous
re-entry, so the guards + field are deletable byte-identically. The notify-by-mutation SEAM STAYS. Verified: build 0;
suite 165/165 dpr1; gauntlet dpr1/dpr2/webkit + apps 165/165; paint-readonly 0; capstone 18 (UNCHANGED — Phase D state,
narrow E does not touch the seam); 20-min dpr2 torture clean. NEXT: the convergence arc — ✅ now SCOPED 2026-06-28 (a
throwaway probe + instrumented Stage-2-redux, no production code): seam deletion breaks EXACTLY 10 job-B tests
(dpr1≡dpr2), the genuine-convergence tests SURVIVE (cascade-covered), the width⇄height cycle is NEGLIGIBLE (14), and a
clean in-pass/off-pass seam split was FALSIFIED (6 of 10 need the in-pass firing; separating waste from load-bearing
needs the deleted boolean). CONCLUSION: deleting the seam is gated on **§4.1 (pure-measure keystone) + §4.2 (structural
DAG)** — §4.4 alone is insufficient — i.e. the assessment's #1 and biggest change, a major foundational campaign,
BANKED + deferred to a future §4.1 arc. See §5 Phase E "Deferred" (rewritten with the findings) + memory
`fizzygum-convergence-arc-feasibility`. Written to be executed COLD by an LLM/engineer with ZERO prior context.**

**Prior — Phase C ✅ DONE 2026-06-28 (byte-identical, gauntlet-green dpr1/dpr2/webkit) — but NOT the way it was scoped.
The scoped "fold the keep-in-view clamp + consistent frame+children commit" design was EXECUTED and FALSIFIED: it
broke 10 general (non-wrapping) scroll panels with the flag still ON (centered content shoved to a corner — the
frame-vs-children move asymmetry is load-bearing for general panels, NOT a transient). The REAL Phase C is far
smaller: of the three non-idempotencies the scoping found, the PERPETUAL driver was #3 (the height wobble); #1/#2
(the position clamp) self-settle in ≤2 passes once #3 is gone. So Phase C = DELETE the redundant priming
`@contents.rawSetHeight` (the merged-bounds commit is the single owner of the frame extent). The reverse-disable test
then PASSES: all 4 tripwires converge (RECALC=0) AND byte-match with the cross-method suppression disabled — proving
the flag is now correctness-unnecessary. (Consequence: Phase A/B's `measureWrappedHeight` was a TRANSIENT consumer of
an overwritten value — it was reverted here; see §5 Phase A/B/C.)**
Everything
needed — what the project is, the current layout machinery, why the booleans exist (the *corrected*, code-proven
mechanism), the target architecture, the phased elimination path, the byte-exactness strategy, and all references — is
embedded inline or one named-doc hop away. **Line numbers drift: grep the named symbol, never trust a line number here.**

---

## §0 — Mandate, and the lens that filters every step

**Mandate (non-negotiable framing).** The goal is **"proper layouts" as an end in itself**: a layout engine that is a
clean **measure → arrange** with **explicit dirty-tracking**, and that therefore does **not need** the runtime booleans
the current engine leans on. The concrete spearhead is **`@_adjustingContentsBounds`** — a per-container boolean that
suppresses a self-referential layout notification — but the real target is the whole **boolean-DRIVEN** convergence
machinery it is part of. **The aim of every step is to DELETE these booleans, not to live with them more comfortably.**

**The filter (apply to every proposed step):**
- ✅ **KEEP** a step iff it *paves the way to deletion* — it removes a read-back, makes a pass single-pass-correct,
  replaces notify-by-mutation with explicit invalidation, or otherwise makes the eventual `delete` of a boolean
  **possible and byte-safe**.
- ❌ **REJECT** a step whose payoff is "the boolean is now nicer to live with" — renaming it, asserting it stays
  balanced, or **relocating it into an engine object** (assessment §4.3). Those make peace with the boolean; we want it
  **gone**. (§6 lists the rejected moves explicitly so a future session doesn't drift into them.)

**The one structural truth this whole plan turns on (proved this session, see §3):** the booleans are *symptoms* of two
missing properties — **(1)** a pure *measure* (so containers don't mutate-then-read-back), and **(2)** a separation of
layout *output* from layout *input* (so applying computed geometry does not re-trigger layout). Restore those two
properties and the booleans have nothing left to do. **You cannot delete the boolean first; you delete the *reason* for
it, then the boolean falls out.**

---

## §1 — Orientation (project, repos, commands)

**Fizzygum** is a CoffeeScript GUI framework — a "web operating system" (windows, desktop, drag-and-drop, live in-system
editing) rendered on a single HTML5 `<canvas>`, descended from Morphic.js. ~470 `.coffee` classes in `Fizzygum/src/`;
every class is a global compiled in-browser (no `require`/`import`); `nil` == `undefined`; one class per file,
filename == class name. The umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; it holds three
sibling git repos that must stay siblings:
- **`Fizzygum/`** — framework source (edit here) + build script + the layering lint (`buildSystem/check-layering.js`).
- **`Fizzygum-tests/`** — 165 macro SystemTests (drive the live world, compare SWCanvas **SHA-256 screenshots
  byte-exactly**) + the harness + audit gates + the dpr2 determinism torture harness.
- **`Fizzygum-builds/`** — generated build output (never hand-edit).

Commands via the path-correct `fg` wrapper **from the umbrella root**: `./fg build` · `./fg suite` (165 tests, dpr1,
~1.3 min) · `./fg gauntlet` (build + dpr1 + dpr2 + WebKit + 12 apps) · `./fg test <name>` · `./fg recapture <name>`.
Single test headless from `Fizzygum-tests/`: `node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1`.
**`nil` == `undefined`.** Edit only `src/**/*.coffee`; rebuild — never hand-edit `Fizzygum-builds/`.

**Determinism is the binding constraint.** Render/layout/input must be a pure function of the **event stream** + **final
geometry** — never wall-clock, frame-count, or intermediate-pass state; those diverge at **dpr2 under parallel load**.
The contract + convergence bug-class case law: `Fizzygum-tests/DETERMINISM.md`. **Any layout change is verified
byte-exact against the SHA-256 references; a deliberate pixel change needs owner approval before recapture.**

---

## §2 — The current layout machinery (ground truth — read this before touching anything)

### 2.1 The per-frame spine (`WorldWdgt.doOneCycle`)
1. **`playQueuedEvents`** — input handlers run; each *public* geometry mutation self-settles in place via
   `_settleLayoutsAfter` (runs a core, then calls `recalculateLayouts` once).
2. **`recalculateLayouts`** (`WorldWdgt.coffee`, grep `recalculateLayouts:` and `_recalculatingLayouts`) — the
   **end-of-cycle coalesced flush**: an **until-loop** that drains `widgetsThatMaybeChangedLayout`, `_reLayout`-ing the
   top of each broken chain to a **fixed point**. Backstopped by `recalcIterationsCap = 100000` → on non-convergence it
   logs **`RECALC_NONCONVERGENCE`** and bails (instead of freezing).
3. **`updateBroken`** — PAINT (read-only; the broken-rectangles repaint).

### 2.2 The settle engine (assessment §2.3): *invalidate **up**, re-layout **down**, iterate to a fixed point*
- **Invalidate up:** `_invalidateLayout` marks a widget dirty and climbs to ancestors (enqueues them).
- **Re-layout down:** `_reLayout` lays a widget out, which lays its children out.
- **Iterate:** the until-loop repeats until `widgetsThatMaybeChangedLayout` empties. The shared in-pass enqueue atom is
  `Widget._markForRelayoutNoClimb` (push + `layoutIsValid=false`, no climb).

### 2.3 The notify-by-mutation **seam** (this is the crux)
**Every raw geometry setter fires a bottom-up re-fit notification.** Grep `_reFitContainerAfterRawGeometryChange` and
`_reFitContainer` in `Widget.coffee`:
- `rawSetExtent` (`Widget.coffee` ~:1563) → delegates to `silentRawSetExtent` + `@changed()` + `@_reLayoutSelf()`.
- **`silentRawSetExtent` (~:1609) ENDS with `@_reFitContainerAfterRawGeometryChange()` (~:1642).** ⇒ **"silent" means
  *no repaint / no self-relayout*, NOT *no re-fit notification*. The silent setters fire the seam too.**
- `fullRawMoveBy` (~:1271) also fires it (~:1294).
- `_reFitContainerAfterRawGeometryChange` (~:1662): skip if `@isLayoutInert?()` (overlay chrome); else
  `_reFitContainer(@parent)` (+ `@parent.parent` if directly inside a *non-text-wrapping* scroll panel).
- `_reFitContainer(container)` (~:1693): `return unless container?._reLayoutChildren?` (only Window/Stack/ScrollPanel
  react); **`return if container._adjustingContentsBounds`** (THE suppression); then in-pass →
  `container._markForRelayoutNoClimb()`, off-pass → `container._invalidateLayout()`.

The seam has **two distinct intents fused onto one mechanism**:
- **Intent-1 (legitimate):** an **external** agent moves/resizes a freefloating child → its container must re-fit.
- **Intent-2 (spurious):** a container's **own arrange** mutates its children → the seam targets the container itself.
  The flag exists ONLY to suppress Intent-2. **There is no setter that does Intent-2 without firing the seam — only the
  flag suppresses it.** (This is the lever the whole plan pulls; see §4.)

### 2.4 The booleans on the chopping block
- **`@_adjustingContentsBounds`** — **per-container** (`SimpleVerticalStackPanelWdgt` ~:12, `WindowWdgt` ~:32,
  `ScrollPanelWdgt` ~:14). THREE uses of the one field:
  1. **Re-entrancy guard** atop each `_positionAndResizeChildren` (`if @_adjustingContentsBounds then return else … = true`).
  2. **Cross-method seam suppression** (`_reFitContainer` ~:1702, the `return if`).
  3. **Scrollbar-layout suppression** — `ScrollPanelWdgt._reLayoutScrollbars` save/restore (~:125/195) so the bars'
     raw resizes don't re-fit the panel.
  It is **per-container because arranges NEST**: `ScrollPanelWdgt._positionAndResizeChildren` synchronously calls
  `@contents._positionAndResizeChildren()` (`ScrollPanelWdgt` ~:340) when contents is a vertical stack, so a scroll
  panel and its stack are both mid-arrange at once. (⇒ a single world-level "are we arranging" flag could NOT replace
  it; it would need a *set/stack* — which is itself a symptom, see §6.)
- **The three world-level phase booleans** (`WorldWdgt.coffee` ~:295–296, `Widget.coffee` ~:822):
  `world._inLayoutMutation` (a public setter's core+flush is running), `world._recalculatingLayouts` (the end-of-cycle
  flush is running), `world._batchingLayoutSettling` (the mostly-dormant batch tier). The "throw vs enqueue vs
  invalidate vs apply" decision is reconstructed from these all over `Widget`/`WorldWdgt`.
- **`layoutIsValid`** (per widget) + **`widgetsThatMaybeChangedLayout`** (the worklist) + **`recalcIterationsCap`** (the
  empirical-convergence backstop). These are the *iteration* machinery; "proper layouts" replaces the fixpoint loop with
  a single ordered walk, so they reduce or go.

### 2.5 Two sizing philosophies already coexist (assessment §2.5 — the most important structural finding)
- **Horizontal stacks** use a clean **measure → arrange**: pure bottom-up `getRecursiveMinDim/DesiredDim/MaxDim`
  (`Widget.coffee` ~:4025–4125) with **no mutate-read-back and no flag**.
- **Vertical / window / scroll / wrapping-text** use the imperative **mutate-the-child-and-read-`@bounds`-back**
  fixed-point path that needs the flag. *"The framework already contains a clean measure engine — it just isn't used on
  the side that hurts."* **This plan extends the measure engine to the side that hurts, then deletes the machinery the
  imperative path required.**

---

## §3 — Why the flag exists: the corrected, code-PROVEN mechanism (do not re-derive — this was settled empirically)

A prior session attempted to retire `@_adjustingContentsBounds` via a "pure text-height measure" and **FALSIFIED that
approach** (see `docs/archive/retire-adjustingContentsBounds-via-text-measure-plan.md`, the ⛔ VERDICT block). The corrected
mechanism — which THIS plan is built on — is:

1. **The flag suppresses a SEAM fired by a container POSITIONING/sizing its own contents — not a height read-back.**
   Every raw setter (incl. silent) fires the seam (§2.3). When a container arranges its children, each child mutation
   fires the seam at the container → re-enqueue. The flag swallows it.

2. **THE PERPETUAL DRIVER — the height wobble (corrected by Phase C execution, 2026-06-28).** The flag swallows the
   seam fired by EVERY in-pass child mutation, but only ONE of those mutations RE-FIRES forever. In
   `ScrollPanelWdgt._positionAndResizeChildren`'s wrapping-text branch, the priming `@contents.rawSetHeight(max(M,vp) −
   totalPadding)` DISAGREES with the end-of-method merged-bounds commit (`max(M + 2·padding, vp)`) by ~`totalPadding`,
   so the frame height flip-flops WITHIN every pass (net-unchanged, but two seams fire). That **height wobble** is the
   non-idempotency that never settles. *(An earlier instrumented stack-capture — cap lowered to ~12 so the console
   didn't flood — fingered `@contents.silentRawSetBounds(newBounds)` as "the" re-enqueue site. It IS a seam-firer, but
   it is the POSITION clamp — a ONE-TIME snap that self-settles in ≤2 passes once the height stops wobbling. "Position
   cycle" was a RED HERRING; the live driver is the height. The disable-probe still names `SimplePlainTextScrollPanelWdgt`
   in `RECALC_NONCONVERGENCE`, which is correct — that is where the wobble lives.)* **Phase C deletes the priming line**
   (the commit already owns the frame extent) → the arrange becomes its own fixed point.

3. **Scope, then the Phase C result.** The disable-probe (comment out `return if container._adjustingContentsBounds` in
   `_reFitContainer`, build, run dpr1) breaks only **4 wrapping-text-scroll tests**; **161/165 unaffected** (for them the
   flag is already a pure optimization — a redundant pass it skips). The 4 tripwires: `macroWrappingTextFieldResizesOK`,
   `macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved`,
   `macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent`,
   `macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo`. The pre-execution scoping PREDICTED
   two of the four would settle at a *different fixed point* (an irreducible pixel change, the byte-exactness gate).
   **That prediction was FALSIFIED:** after Phase C deletes the wobble, all 4 CONVERGE (no `RECALC_NONCONVERGENCE`) AND
   byte-match with the suppression disabled — removing the wobble makes the flag-off loop reach the SAME fixed point.
   So `@_adjustingContentsBounds` is now **correctness-unnecessary** for all 165 (Phase D removes it).

4. **Why a *measure* (Phase A/B) was the wrong lever — and what the right one was.** A pure text-height measure
   (`measureWrappedHeight`) targets the height the priming line READS — but that line's output is OVERWRITTEN by the
   commit and read by nothing in between, so measuring it changed no captured geometry: Phase A/B's measure was a
   TRANSIENT consumer and was reverted in Phase C. The two earlier probes (wrap at final `@width()`; priming
   `rawSetHeight`→`silentRawSetHeight`) failed for the same reason — they reshaped the wobble's value but did not remove
   it. The fix was not to *measure* the wobble but to *delete* it. The genuine remaining size read-back is `subBounds`
   (the children's applied bounds), retired only when Phase D/E gives the arrange a pure child measure.

**The three structural facts that force *some* suppression today (and which the roadmap dismantles):**
- **(a)** setters notify by mutation (the seam fires on every apply);
- **(b)** the arrange applies geometry with those setters;
- **(c)** a container is a valid re-fit target of its own children's seam.
(b) is irreducible (the arrange must apply geometry). **So elimination = make the arrange IDEMPOTENT so iteration
converges harmlessly (Phase C ✅ — deleted the height wobble), then DELETE the cross-method suppression (Phase D ✅ —
direct deletion; the feared redundant pass was a pre-C wobble artifact that didn't materialize, so the non-notifying
apply that breaks (a) for arrange output is deferred to Phase E where it belongs), and ultimately replace the seam with
explicit dirty-tracking (Phase E).** Phase C demoted the flag from *correctness* to *optimization* without touching
(a)/(b)/(c) — it removed the *reason the iteration didn't converge*, not the seam; Phase D then removed the (now
purely-optional) suppression itself. Renaming/relocating the flag breaks none of (a)/(b)/(c) — hence §6 rejects them.

---

## §4 — The target architecture: "proper layouts" (measure → arrange → dirty-tree)

A standard retained-mode layout (how Flutter / CSS / RN layout work), reached incrementally:

- **Invalidation (INPUT, explicit).** External code (public `setExtent`/`setText`/`add`, drag handlers) marks the
  affected node `needsLayout` and flips `hasDirtyDescendant` up the ancestor chain (O(depth) mark, O(1) work-enqueue of
  dirty roots — assessment §4.4). **No seam. No mutate-then-notify.**
- **Measure (bottom-up, PURE).** Each widget answers `preferredExtentForWidth(availW) → {w,h}` as a side-effect-free
  function of its children's measures + own content (text wraps to a given width without committing — Phase A). This is
  `getRecursive*Dim` (already pure for horizontal stacks) generalized to text + vertical/window/scroll.
- **Arrange (top-down, SINGLE PASS).** Each container positions+sizes its children from the **measured** values and
  applies the result via a **non-notifying** `applyLayoutGeometry` primitive. Because children were measured before they
  are arranged, **one pass suffices** — no fixpoint iteration, no `recalcIterationsCap`.
- **No self-notification.** Arrange output does not re-trigger layout. A container laying out its subtree never
  re-enqueues itself ⇒ **`@_adjustingContentsBounds` has nothing to suppress and is deleted.**
- **Genuine cycles (aspect-locked nested content: square clock in window-in-window — width⇄height) stay explicitly
  broken** by the existing `elasticity 0` fix (assessment §2.5 / `deferred-layout-OVERVIEW.md` §5). The §4.2 lint
  (Phase F) forbids any *new* both-direction edge, so the graph stays a per-axis DAG.

**End state for the booleans:** `@_adjustingContentsBounds` GONE; the `_reFitContainerAfterRawGeometryChange` seam GONE;
`recalcIterationsCap` + the fixpoint until-loop GONE (replaced by one ordered walk). The world phase machinery reduces to
**at most one** honest "layout in progress" re-entrancy guard for the public API (a normal thing even in React/Flutter —
*that* one is not a symptom and may legitimately remain; total-zero-booleans is not the test — **zero
*suppression/empirical-convergence* booleans** is).

---

## §5 — The elimination roadmap (each phase: byte-safe, independently shippable, soak-gated)

> Ordering rule: **A → B → C → D → E → F.** A/B are pure prerequisites (additive, byte-identical). C is the
> determinism gate. D performs the first *deletion* (the cross-method suppression). E performs the second (the
> re-entrancy guard) by replacing the seam. F removes the empirical-convergence scaffolding. **Each phase ends with the
> full §7 verification and is committed before the next begins.**

### Phase A — Build the pure measure primitive `preferredExtentForWidth(availW)` (additive) — ⛔ REVERTED in Phase C 2026-06-28
> **REVERTED (the measure was a transient).** `measureWrappedHeight` was only ever consumed by the ScrollPanelWdgt
> wrapping-text path's priming `@contents.rawSetHeight` (Phase B slice 1) — and that frame-height write is OVERWRITTEN
> by the merged-bounds commit at the end of the same arrange, with NOTHING reading `@contents.height()` in between
> (subBounds is the CHILDREN's merged bounds, not the frame's). So Phase A/B-slice-1's "read-back removal" never touched
> the geometry the suite captures; the genuine content-height read-back is `subBounds`, retired only in Phase D/E. When
> Phase C deleted the redundant priming line, `measureWrappedHeight` was orphaned, and the build's **dead-method gate**
> (empty allowlist — the project keeps ZERO sanctioned dead methods) forced its removal. So `TextWdgt.measureWrappedHeight`
> + the `breakTextIntoLines` `widthOverride` param were both deleted. **The pure measure returns in Phase D** as the
> GENERAL `preferredExtentForWidth(availW)→{w,h}` — which is where it actually retires the `subBounds` read-back. Lesson:
> a measure that feeds a value the arrange immediately overwrites is not "paving"; the read-back to attack is the one the
> committed geometry depends on (`subBounds`), and that needs the Phase D/E arrange restructure, not a cheap primitive.
- **Reference for Phase D (the byte-exactness construction, the one durable artifact of this attempt).** When rebuilding
  the measure as the GENERAL `preferredExtentForWidth(availW)→{w,h}`: the text-height construction is byte-exact because
  `TextWdgt.getTextWrappingData` (~:201) is pure (writes only the `world.cacheForTextWrappingData` memo, returns
  `[lines,slots,maxW,height]`) and its `height = lines·Math.ceil(fontHeight)` is the **same formula** `_reLayoutSelf`
  commits when the box is sized to that width. Generalize to a `Widget` measure that, for the measure-clean classes,
  mirrors `getRecursive*Dim` (§2.5). The mistake to NOT repeat: a measure is only worth building where its result feeds
  geometry the suite captures — wire it into the `subBounds` path (Phase D), not a transient priming write.

### Phase B — Consume the measure in each arrange; kill the SIZE read-back (container by container) — ◑ PARTIALLY SUPERSEDED by Phase C
> **Status:** slice 1 SUPERSEDED (removed in Phase C); slice 2 STANDS. Originally landed byte-identical 2026-06-28.
> - **Slice 1 — `ScrollPanelWdgt` wrapping-text path:** ❌ SUPERSEDED. It changed the priming `@contents.rawSetHeight`
>   from `widget.height()` to `widget.measureWrappedHeight(textWidth)` — but that frame-height write is a TRANSIENT
>   overwritten by the merged-bounds commit (see Phase A REVERTED note), so it never affected captured geometry. Phase C
>   deleted the whole priming line (it was the non-idempotent height wobble), taking slice 1 with it.
> - **Slice 2 — `SimpleVerticalStackPanelWdgt` (~:176):** ✅ STANDS. Consume the height `rawSetWidthSizeHeightAccordingly`
>   HANDS FORWARD instead of re-reading `widget.height()` (completes the §2.4 "half-done" hand-forward). This is the ONE
>   surviving piece of the original af56245e Phase A/B commit, and it is a genuine (non-transient) read-back removal —
>   the stack actually sums the handed-forward height.
>
> **`WindowWdgt` was already converted (no change needed).** A classification of every `.height()` read in
> `WindowWdgt._positionAndResizeChildren` found it already on the Path-B hand-forward
> (`@contents.rawSetWidthSizeHeightAccordingly`, ~:563/:569) from the earlier deferred-layout campaign; the lone
> `@contents.height()` (~:551) is a PRE-mutation `THIS_ONE_I_HAVE_NOW` size INPUT, not an output read-back.
>
> **Net after Phase C — do NOT believe an earlier "read-back gone from all three" claim.** The ONE genuine size read-back
> this phase removed is the vertical stack's (slice 2). The scroll panel's REAL content read-back is `subBounds` (the
> children's applied merged bounds), which slice 1 never touched (it only rewired the transient priming write) and which
> is STILL PRESENT — retired only by the GENERAL measure + non-notifying arrange of Phase D/E. So "kill the SIZE
> read-back" is complete for the vertical stack; the scroll panel still reads its children's applied bounds back, and
> that is the genuine target for Phase D.

### Phase C — Make the arrange a FIXED POINT so the flag is correctness-unnecessary — ✅ DONE 2026-06-28 (NOT as scoped)
> **RESULT: the scoped design was EXECUTED and FALSIFIED; the real fix is one deleted line.** Read this in full before
> any further work — the falsified path is an easy one to re-walk.
>
> **The scoping's value-trace (still valid, kept for reference)** caught the non-idempotent pass on
> `macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo` (format `[left@top | w@h]`):
> ```
> in=[20@-948 | 390@1278]   target=[20@-948 | 390@305]   out=[20@25 | 390@305]   vp=[20@25 | 390@305]
> ```
> Content scrolled to bottom (top −948), text SHRANK (h 1278→305); `newBounds` kept the stale top (−948),
> `silentRawSetBounds` applied it, `keepContents` snapped it back (+973 → top 25). `target ≠ out` → not a fixed point.
> The scoping named THREE interacting non-idempotencies: (1) clamp-after-compute, (2) frame-vs-children move asymmetry,
> (3) the priming height re-set. **What the scoping got WRONG: it assumed all three had to be fixed together via a
> "fold the clamp + consistent frame+children commit" rewrite. Execution proved otherwise.**
>
> **What was FALSIFIED (do NOT re-attempt this).** The scoped fix — replace `silentRawSetBounds(newBounds)` +
> `keepContentsInScrollPanelWdgt()` with `contentsBoundsClampedIntoView` (pure clamp folded into `newBounds`) +
> `silentRawSetExtent` + `fullRawMoveBy` (consistent frame+children commit) — was implemented and **broke 10 general
> (non-wrapping) scroll panels with the flag still ON** (a centered content box was shoved to the bottom-right corner;
> e.g. `macroNoSpuriousScrollbarsOnScrollPanelResize`). ROOT CAUSE: for general scroll panels the frame-vs-children
> asymmetry (#2) is **load-bearing, not a transient** — `silentRawSetBounds` moving the FRAME without its children is
> exactly the scroll geometry (`newBounds` = content ∪ viewport, origin ≠ `@contents.origin` when scrolled), and a
> "consistent" commit changes their settled positions. **#1/#2 are NOT safe to "fix" — they ARE the behaviour.**
>
> **What was actually TRUE — #3 alone is the perpetual driver.** Of the three, only #3 fires a seam EVERY pass: the
> priming `@contents.rawSetHeight(max(M,vp) − totalPadding)` and the merged-bounds commit `max(M + 2·padding, vp)`
> DISAGREE by ~`totalPadding`, so the frame height flip-flops within every pass (net-unchanged, but two seams). #1/#2
> (the clamp) are a ONE-TIME snap that self-settles in ≤2 passes — once #3 stops re-dirtying the pass, the next pass
> sees `boundingBox == newBounds`, skips `silentRawSetBounds`, and the clamp is a no-op. **So removing #3 alone makes
> the arrange a fixed point; #1/#2 needed nothing.**
- **Do (the whole change).** DELETE the priming `@contents.rawSetHeight` line from the wrapping-text branch of
  `ScrollPanelWdgt._positionAndResizeChildren`. The merged-bounds commit at the end of the method becomes the single
  owner of the frame extent (it already set the final height; the priming line was redundant AND non-idempotent).
  Keep `widget.rawSetWidth textWidth` (re-wraps the text so subBounds + paint + the caret's `@wrappedLines` are
  current). That orphaned `measureWrappedHeight` → deleted too (Phase A REVERTED note). **No apply rewrite, no clamp
  fold, no new method — `silentRawSetBounds` + `keepContentsInScrollPanelWdgt` are UNTOUCHED.**
- **Byte-safety.** The deleted line wrote a TRANSIENT frame height overwritten by the commit, with nothing reading it
  in between → byte-identical with the flag ON. Verified: **suite 165/165 dpr1 + gauntlet 165/165 dpr1/dpr2/webkit + apps.**
- **The gate (reverse-disable) — PASSED.** With `return if container._adjustingContentsBounds` disabled in
  `Widget._reFitContainer`, ALL 4 tripwires CONVERGE (RECALC=0) **and byte-match** — including the two that the
  scoping predicted would reach a "different fixed point." (They didn't: removing the height wobble makes the flag-off
  loop reach the SAME fixed point.) This proves the cross-method suppression is now correctness-unnecessary.
- **Exit.** Flag re-ENABLED (its deletion is Phase D). **Lessons:** (a) when a scoping lists N non-idempotencies, find
  WHICH is the perpetual driver before "fixing" all N — the others may be load-bearing behaviour. (b) The
  disable-the-mechanism PROBE (here: implement the scoped fix, run the suite with the flag ON) decisively kills a wrong
  design in one build — the 10 flag-ON regressions said "this changed real behaviour," not "this changed convergence."

### Phase D — DELETE the cross-method suppression (#2 + #3) by DIRECT deletion — ✅ DONE 2026-06-28 (option 4)
> **RESULT: #2 (`return if container._adjustingContentsBounds` in `Widget._reFitContainer`) and the coupled #3
> (`ScrollPanelWdgt._reLayoutScrollbars` save/restore) were DELETED directly — NOT via the non-notifying apply tier the
> earlier sketch proposed.** Two execution-prep findings drove the choice (cold-readable summary):
>
> 1. **The non-notifying apply tier only PARTIALLY covers the seam, at real cost.** The seam fired during a container's
>    arrange has THREE sources, only one cleanly convertible: **(1)** direct simple raw-setter calls on children [clean
>    twins]; **(2)** container SELF-resizes (`@rawSetHeight newHeight`, stack ~:190 / window ~:596) — a LOAD-BEARING
>    up-notification to the PARENT (the flag only suppressed these when nested), NOT convertible; **(3)** generic
>    `child._reLayout(bounds)` positioning (window buttons) + `rawSetWidthSizeHeightAccordingly` (9 overrides) — generic
>    / proliferating. So "convert EVERY arrange-internal mutation" is not cleanly reachable; the tier would remove only
>    (1), leaving (2)+(3) notifying — a partial, asymmetric change whose seam-suppression internals Phase E rewrites to
>    dirty-bit form anyway. (The seam funnels through just two primitives — `silentRawSetExtent` tail, `fullRawMoveBy`
>    mid — so the tier itself is clean to factor; the problem is which call-sites it can reach.)
> 2. **The predicted ~1.6× slowdown did NOT materialize on the post-Phase-C base.** The probe's 1.6× (an earlier draft of
>    this section) was a PRE-Phase-C wobble-interaction artifact: with the height wobble gone (Phase C) every arrange is
>    a true fixed point, so a re-enqueued mid-arrange container re-runs ONCE and that pass NO-OPS (geometry unchanged →
>    the `unless @bounds.equals` / `if delta.isZero` setter guards fire → no seam re-fires → the until-loop drains).
>    Measured: gauntlet dpr1 1.32 / dpr2 1.65 min == baseline. The whole reason to prefer the tier (avoid the 1.6×)
>    evaporated.
>
> Given (1)+(2), and that the END-STATE code is IDENTICAL whether #2/#3 are deleted now or folded into E (E deletes the
> seam + builds the apply tier in its permanent dirty-bit form regardless — the direct deletion adds ZERO transitional
> code), the owner chose the **direct deletion**: cleanest code now, a proven determinism-safe milestone, no throwaway
> tier. The apply tier is built ONCE, in E, in its final form. (3-vs-4 analysis: same destination; option-4 staging is
> strictly cleaner — zero transitional code.)
- **Do (the whole change).** DELETE #2 (`Widget._reFitContainer`) and #3 (the `@_adjustingContentsBounds` save/restore in
  `ScrollPanelWdgt._reLayoutScrollbars` — coupled: #3 set the flag SOLELY so #2 suppressed the bars' raw resizes, inert
  once #2 is gone). The `@_adjustingContentsBounds` FIELD and the #1 re-entrancy guards (atop the three
  `_positionAndResizeChildren`) STAY — retired in Phase E.
- **KNOWN INTERMEDIATE REGRESSION (owner-accepted).** #2/#3 were ALSO active end-of-cycle-drawdown ELIMINATEs (their own
  comments said so): they suppressed the OFF-SETTLE synchronous re-fits (`ScrollPanel.add`, `scrollCaretIntoView`,
  `ListWdgt.add`, scroll handlers) whose child mutations fire the seam → the container `_invalidateLayout`s ITSELF
  off-settle → a careless end-of-cycle push. Deleting #2/#3 re-exposes these: **the capstone gate is RED — 18 pushes /
  10 tests** (ScrollPanelWdgt / SimpleVerticalStackPanelWdgt / SimpleDocumentScrollPanelWdgt / ListWdgt). ACCEPTED as
  intermediate: Phase E deletes the seam these re-fits trip, so the pushes vanish STRUCTURALLY. (The screenshot-only
  probe never ran this gate — that is why it was invisible until now. No minimal fix avoids it without re-introducing #2:
  the careless push IS what #2 suppressed; the clean alternative is the non-notifying apply tier, deferred to E.)
- **Byte-safety / determinism.** Screenshots byte-identical (the deleted suppression only skipped a redundant convergence
  pass, never changed committed geometry). Verified: build 0 violations; suite 165/165 dpr1; gauntlet 165/165
  dpr1/dpr2/webkit + apps; paint-readonly gate 0; dpr2 torture (4 iters, ~660 execs) — no nondeterminism,
  `RECALC_NONCONVERGENCE` absent. Capstone gate RED (18 pushes — accepted intermediate).
- **Exit.** #2 + #3 deleted; `@_adjustingContentsBounds` field + the #1 re-entrancy guards remain; capstone red. **NEXT:
  Phase E** — replace the seam with §4.4 dirty-tracking, which (a) deletes the seam + the #1 guard + the field, (b) builds
  the non-notifying apply tier in its permanent dirty-bit form, and (c) RESTORES the capstone to green (the off-settle
  re-fits no longer trip a seam).

### Phase E — DELETE the `@_adjustingContentsBounds` boolean (NARROW) — ✅ DONE 2026-06-28 (NOT as sketched)
> **RESULT: the spearhead boolean is 100% GONE (field + all three #1 re-entrancy guards), byte-identical. But NOT via
> the sketched "seam → dirty-tracking" — the full seam deletion was EXECUTED as a probe and REVERTED on a hard
> convergence finding. Read this before re-attempting the seam deletion; it is an easy trap to re-walk.**
>
> **What was FALSIFIED (do NOT re-attempt as a seam-hoist).** The sketch — hoist every external (Intent-1)
> `_reFitContainerAfterRawGeometryChange` caller to explicit invalidation, then delete the generic seam from
> `silentRawSetExtent` + `fullRawMoveBy` — was implemented in two byte-safe stages. Stage 1 (add explicit notifications
> at the arrange self-resize tails + the ratio / `_sizeToText` sites, seam still firing) was byte-identical. Stage 2
> (delete the seam) dropped the capstone **18 → 7** (the Stack/ScrollPanel Intent-2 self-invalidations vanished) BUT
> broke **8 scroll/drag/clock tests** — render showed spurious scrollbars, `@contents` left OVERSIZED
> (`macroNoSpuriousScrollbarsOnScrollPanelResize`, `macroScrollBarsTrackContentChange`,
> `macroScrollPanelCaretBroughtIntoViewWhenMoved`, `macroEditingStringInScrollablePanelCaretAlwaysVisible`,
> `macroLockedScrollPanelScrollsWhenDragged`, `macroScrollPanelInWindowMovesWindowWhenDragged`,
> `macroScrollPanelNotMovedViaNonFloatDragChild`, `macroWindowWithAClockInAWindowConstructionTwo`).
> **ROOT CAUSE (the entanglement).** The capstone pushes that vanished and the tests that broke are the SAME thing: a
> general scroll panel's "careless" end-of-cycle push IS its layout-CONVERGENCE re-enqueue. Its arrange resizes
> `@contents` (`@contents.silentRawSetBounds`), the seam re-enqueues the panel, and the panel re-snugs `@contents` on
> the next pass — a multi-pass fixed-point iteration the seam DRIVES. Delete the seam and the arrange under-converges
> (`@contents` stays oversized → scrollbars). So **greening the capstone for scroll panels ⟺ making the general-scroll
> arrange a ONE-PASS fixed point** — the exact problem Phase C deliberately did NOT solve (its naive "fold the clamp +
> consistent commit" fix broke 10 general panels; the frame-vs-children asymmetry is load-bearing). This entanglement
> hits the full-deletion path AND a "non-notifying arrange" pivot (anything that removes the panel's self-re-fit
> under-converges it). The ONLY thing NOT entangled is deleting the flag itself. LESSONS: (1) a screenshot-clean dpr1
> probe is not enough — Stage 1 was byte-identical; Stage 2's breakage only showed when the seam was actually removed.
> (2) The capstone count is a load-bearing signal whose pushes can be CONVERGENCE, not carelessness — do not assume
> "green capstone" is free.
> **OWNER DECISION (2026-06-28): NARROW E.** Bank the spearhead boolean now (byte-identical, low-risk); defer the seam
> deletion + capstone-green to a CONVERGENCE arc (below).
- **Do (the whole executed change).** The flag's last use was the per-arrange re-entrancy guard. It was needed ONLY
  because each container arrange sizes ITSELF — `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` does
  `@rawSetHeight newHeight`; `WindowWdgt` does `@rawSetWidth windowWidth` (×3) + `@rawSetHeight newHeight` — and the
  class `rawSetExtent` override (`SimpleVerticalStackPanelWdgt`, inherited by `WindowWdgt`) re-runs `@_reLayoutChildren()`
  synchronously, RE-ENTERING `_positionAndResizeChildren` (the guard caught that as a no-op). Add
  `SimpleVerticalStackPanelWdgt._applyOwnArrangedWidth/Height` (breakCaches + **base** `Widget::rawSetExtent.call @, …`):
  applies the geometry AND fires the up-notification seam (so the nested clock-in-window cascade still works) but SKIPS
  the override's `@_reLayoutChildren()`. With the last synchronous re-entry gone, **DELETE all three #1 guards
  (`SimpleVerticalStackPanelWdgt` / `WindowWdgt` / `ScrollPanelWdgt`) + the `@_adjustingContentsBounds` field.**
  (`ScrollPanelWdgt`'s arrange does not self-resize, so its guard was already inert; deleted directly.)
- **Byte-safety.** Byte-identical BY CONSTRUCTION: the skipped `@_reLayoutChildren()` re-entry was already a guarded
  no-op, so omitting it changes nothing. Verified: build 0; suite 165/165 dpr1; gauntlet 165/165 dpr1/dpr2/webkit +
  apps; paint-readonly 0; capstone 18 (UNCHANGED — narrow E keeps the seam, so the Phase D push set is untouched);
  20-min dpr2 torture clean, `RECALC_NONCONVERGENCE` absent.
- **Exit.** `@_adjustingContentsBounds` (field + all #1 guards) DELETED — the boolean is gone. The seam
  (`_reFitContainerAfterRawGeometryChange` / `_reFitContainer`) STAYS. Capstone still red (18), now correctly understood
  as the scroll panels' convergence iteration, NOT careless leakage.

### Phase E (deferred half) + endgame — the CONVERGENCE arc — ✅ SCOPED 2026-06-28 (feasibility + falsification; deferred to a §4.1 campaign)
> **A throwaway runtime probe + an instrumented Stage-2-redux fully characterized this arc WITHOUT committing production
> code (workspace restored to `a5e89d1b`). The findings REFINE the "make general-scroll one-pass" framing above and
> CORRECT the dependency: the seam is gated on §4.1 (pure measure), and §4.4 alone is NOT sufficient. Read before
> re-attempting. Durable record: memory `fizzygum-convergence-arc-feasibility`; throwaway tooling in the session
> scratchpad `conv-probe/` (a prelude patching `_positionAndResizeChildren`/`_reFitContainer`/`recalculateLayouts` at
> RUNTIME via run-all-headless's `AUDIT_PRELUDE` hook — no src edit).**
>
> **FEASIBILITY (the seam IS deletable in principle).** An instrumented Stage-2-redux (no-op the seam method, rebuild,
> full suite dpr1 AND dpr2) shows seam deletion breaks **EXACTLY 10 tests, byte-identical at dpr1≡dpr2 (zero
> determinism flakes)** — the job-B "external change → container must re-fit" work-list: 7 scroll (caret-edit-grows /
> caret-move / content-change / panel-resize / locked-drag / in-window-drag / non-float-drag) + 3 window/stack
> (clock-in-window construct / vert-panel resize-on-content-change / nested collapse). (The earlier in-session Stage-2
> reported "8"; this clean redux finds 10.) **The genuine-convergence tests SURVIVE seam deletion** —
> `macroResizingPristineInspector`, `macroWrappingTextFieldResizesOK`, the document/inspector set are NOT in the 10:
> the normal parent→child cascade already converges them, so the "general-scroll ONE-PASS" framing above was the wrong
> blocker. A mutation-aware whole-suite probe: of 5,826 repeat arranges, **92% are pure-waste idempotent**, only 8%
> genuine — and the feared §2.5 width⇄height content cycle is **NEGLIGIBLE (14 passes)**; the raw "338" was a
> measurement artifact (wrapping text rewraps INSIDE pass 1). So the seam is **NOT gated on the width⇄height cycle.**
>
> **⚠ PHASE-1 FALSIFICATION (do NOT re-attempt the clean in-pass/off-pass split).** The obvious decomposition — skip the
> seam's IN-PASS firing (`return if world?._recalculatingLayouts` in `_reFitContainerAfterRawGeometryChange`), keep the
> off-pass — was implemented and **FALSIFIED by the gauntlet: 6 of the 10 break** (the drag/construct/collapse/resize
> ones). Those 6 mutate content DURING a settle, so their job-B notify is itself in-pass; the in-pass firing is NOT all
> waste. The "92%" is repeat ARRANGES (self-re-enqueue cascade), not all in-pass refits. Distinguishing wasteful (a
> container re-enqueuing ITSELF mid-arrange) from load-bearing (a FIRST re-fit) at firing time needs per-container
> arrange-state = **exactly the `@_adjustingContentsBounds` boolean this campaign just deleted (forbidden, §6)**. So
> there is NO boolean-free byte-identical way to condition the seam. Reverted.
>
> **THE CORRECTED DEPENDENCY (why §4.4 alone is insufficient).** The seam's WASTE *is* the fixed-point ITERATION; it
> only vanishes when convergence becomes STRUCTURAL. The seam EXISTS because of the read-back (§2.4): a container can't
> *measure* its content, so it mutates-and-reads-back, and must be *notified by mutation* of changes — that notification
> IS the seam. **§4.1 (pure `preferredExtentForWidth` measure) removes the read-back; §4.2 (per-axis DAG) makes
> measure-up/arrange-down a SINGLE traversal with zero iteration** → no "pass" to re-enqueue into → seam + waste gone,
> and the capstone greens because the off-pass notify becomes a structural measure-dirty, not a raw `_invalidateLayout`.
> **§4.4 (two-flag `needsLayout`/`hasDirtyDescendant`) is the efficiency/cleanliness layer on top — it does NOT by
> itself stop a settled container being re-dirtied, so it neither deletes the seam nor greens the capstone alone.**
> Real order: **§4.1 (keystone) → §4.2 (structural) → §4.4 (two-flag) → seam deletes + capstone greens as a consequence.**
>
> **VERDICT (owner-decided 2026-06-28): this is the assessment's #1 and BIGGEST change — a major, determinism-critical,
> multi-arc FOUNDATIONAL campaign, not a seam-hoist and not a quick refactor.** §4.1's text-measure was already
> built-and-reverted once (it fed a transient); the general `preferredExtentForWidth` is TODO and "the big change."
> BANKED as scoped; deferred to a deliberate future §4.1 campaign (own design pass + incremental soak-gated landings).
> The spearhead boolean is already gone (Phase E), so this is a clean resting point.

### Phase F — Structural convergence: retire `recalcIterationsCap` + the empirical crutches; §4.2 lint
- **Do.** With a single-pass down-walk over a per-axis DAG, the fixpoint until-loop runs zero extra iterations. Replace
  it (or prove it terminates in one pass), demote `recalcIterationsCap` to a never-fire assert, then remove it. Add the
  assessment **§4.2** `check-layering` rule: forbid any new edge coupling both directions on the same axis of the same
  widget (the empirical convergence of §2.6 becomes build-enforced). Reduce the three world phase booleans to the
  honest minimum (see §4 end-state note).
- **Why it paves / completes.** This removes the *last* boolean-driven property — empirical convergence — and makes
  "proper layouts" build-guaranteed. `recalcIterationsCap`, `widgetsThatMaybeChangedLayout`-as-fixpoint-worklist, and the
  scattered `world._recalculatingLayouts` phase tests collapse.
- **Exit.** No `RECALC_NONCONVERGENCE` path; §4.2 lint green; the booleans enumerated in §2.4 are gone except (possibly)
  one public-API re-entrancy guard, which is documented as legitimate (not a suppression/convergence symptom).

---

## §6 — REJECTED moves (do NOT do these; they are "live with the boolean," not "delete it")

Per the §0 filter, the following make the boolean nicer to keep — they break none of facts (a)/(b)/(c) (§3) and do not
move deletion closer. **Explicitly out of scope:**
- **Renaming `@_adjustingContentsBounds`** (e.g. to `_arrangingOwnContents`) as an end — cosmetic; the field still
  exists and is still consulted at runtime.
- **A set/clear balance assertion** as an end — hardens the boolean's *correctness*, i.e. helps you keep it.
- **Relocating the booleans into a `world.layoutEngine` object with a phase enum (assessment §4.3).** This is the
  archetypal "bury it deeper": `@_adjustingContentsBounds` would become `engine.arrangingStack` (a set, because arranges
  nest — §2.4), the three world flags become an enum — **the suppression still runs at runtime, just centrally.** It is
  *cohesion*, not elimination, and the mandate (§0) explicitly rejects it. (If a future owner wants cohesion for its own
  sake, that is a separate, different goal — but it is **not** on this elimination path and must not be mistaken for a
  step toward it. The dirty-tracking of Phase E *replaces* the mechanism; it is not §4.3's relocation of it.)
- **"Internal non-notifying arrange setters" as a STANDALONE end** (Phase D stopped before E/F) — a lateral move (trades a
  central flag for a per-call-site discipline). Valid ONLY as part of the march to E/F, where non-notifying apply is the
  architectural norm and the seam is gone.

---

## §7 — Verification protocol (MANDATORY for any phase that changes behaviour or deletes a boolean)
`fg` runs from any cwd. **Kill orphan `Chrome for Testing` before any suite/torture; rebuild first (stale-build canary).**
1. `./fg build` — 0 violations, 0 warnings (incl. any new lint rule from Phase D/F).
2. `./fg suite` — dpr1 **165/165**. On a pixel failure: dump + LOOK, don't recapture blindly —
   `node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`, then Read the `.png`.
3. `./fg gauntlet` — dpr1 / dpr2 / WebKit **165/165** + apps 12/12.
4. **dpr2 torture — THE GOLD GATE for any convergence/seam change:**
   `node scripts/torture-headless.js --dprs=2 --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture`
   → REPORT.md "No nondeterminism observed", failures dir empty, **AND grep the run for `RECALC_NONCONVERGENCE`
   (must be ABSENT)** — the single most important signal for this work.
5. **The 4 §3 tripwires** as the fast inner loop (Phases C/D): run each, grep for `RECALC_NONCONVERGENCE`.
6. **The reverse-disable test** (Phases C/D): with the cross-method suppression disabled, the 4 tripwires must converge +
   match — that is the positive proof the phase made the flag unnecessary.
7. **End-of-cycle capstone gate** (`bash scripts/end-of-cycle-audit/run-capstone-gate.sh`) and **paint-read-only gate**
   (`bash scripts/paint-readonly-audit/run-paint-readonly-gate.sh`) stay 0. **DO NOT pipe a gate whose exit code you need
   into `tail`/`grep`** — dump to a file, echo `$status`, then read.
8. **20-minute determinism soak** before declaring a behaviour-changing phase done.

**Determinism contract & recapture:** byte-exact change ⇒ no recapture; deliberate pixel change ⇒ owner approval first.
A benign inspector member-list shift is the one pre-authorized recapture class — e.g. adding the general
`preferredExtentForWidth` to `Widget` (Phase D) may shift an inspected widget test's member list; dump + look, then
recapture only that. (Phase A/C were byte-identical and needed none — the orphaned `measureWrappedHeight` was deleted,
not added, so it shifted nothing.) Full contract + convergence case law: `Fizzygum-tests/DETERMINISM.md`.

---

## §8 — Risks & honest STOP conditions
- **Phase C — DONE; the predicted gate did not bite.** The scoping feared the 2 "different-fixed-point" tripwires
  (§3.3) might be irreproducible byte-exactly, forcing an owner-visible constraint-ordering choice. They were NOT: once
  the height wobble was deleted, all 4 tripwires byte-matched with the flag off. The actual hazard was elsewhere — the
  scoped "fix all three non-idempotencies" rewrite was the thing that broke pixels (10 general panels, flag ON), because
  #1/#2 (the position clamp / frame-vs-children move) are load-bearing behaviour, not bugs. The disable-the-mechanism
  PROBE (implement the candidate, run the suite) caught it in one build. **Carry that probe into Phase D.**
- **Phase E is the biggest determinism surface.** Replacing the seam changes re-fit timing across many gestures. Migrate
  one mutation-class at a time; each must clear the soak. The soft-wrap §5 family
  (`docs/archive/softwrap-deferred-layout-conversion-plan.md`) is reversal-heavy — expect care.
- **Whack-a-mole inversion (Phase D).** Missing one arrange-internal mutation re-introduces a self-seam with no flag to
  catch it. The new lint rule + the reverse-disable test are the guardrails; do not delete the flag until both are green.
- **General.** Never reinstate a deleted boolean to mask a missed case — find the case. If a phase can't be made
  byte-exact with reasonable effort, **STOP, leave the prior phase's state (which is sound and committed), and report.**
  Each phase is independently valuable, so a clean stop after any phase is a legitimate outcome.

---

## §9 — Owner principles & workflow
- **Goal is deletion, not accommodation** (§0). Apply the filter to every step; if in doubt, it is probably a §6 reject.
- **Staged + soak each phase**; never big-bang core convergence code. A clean STOP after any committed phase is fine.
- **Review-driven.** Run an arc straight through, present ONE end-of-arc review. **ASK before each commit AND push** —
  present the diff + proposed message, wait for explicit approval. Use `git commit -F <file>` — **NEVER backticks /
  `$()` in `git commit -m`** (the Bash tool runs bash semantics and command-substitutes them, corrupting the message);
  verify with `git log -1 --format=%B`. End every commit message with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Push each repo from its OWN dir.
- **Clean/elegant code is the standing priority** over avoiding a benign inspector recapture (just recapture; never
  contort code to dodge it).
- **Shell:** the Bash tool runs FISH (`$status`, not `$?`); cwd may reset (use `cd /abs/… && …`). A PreToolUse guard
  BLOCKS a command that `cd`s into a non-`Fizzygum-tests` dir then runs a `Fizzygum-tests/scripts` node script — run
  those FROM `Fizzygum-tests` or via `fg`. Kill orphan `Chrome for Testing` before any suite/torture/audit.
- **Do NOT hand-edit `Fizzygum-builds/`** — rebuild. Scope every search (`Fizzygum-builds/latest` is ~1.3 GB).
- **`docs/archive/layout-system-architecture-assessment.md` is the owner's parallel-work — READ it, do NOT edit it.**

---

## §10 — Anchors & references (grep the symbol; numbers drift)
- **The booleans being deleted:** `_adjustingContentsBounds` — **✅ FULLY DELETED. Phase D (2026-06-28) deleted #2 (the
  `Widget._reFitContainer` check) + #3 (the `ScrollPanelWdgt._reLayoutScrollbars` save/restore); Phase E (2026-06-28,
  NARROW) then deleted the FIELD + all three #1 re-entrancy guards (`SimpleVerticalStackPanelWdgt` / `WindowWdgt` /
  `ScrollPanelWdgt`) via the non-re-applying self-resize `SimpleVerticalStackPanelWdgt._applyOwnArrangedWidth/Height`
  (base `Widget::rawSetExtent`). The boolean no longer exists.** Still live: `world._inLayoutMutation` / `_recalculatingLayouts`
  (`WorldWdgt` ~:295–296) / `_batchingLayoutSettling` (`Widget` ~:822); `layoutIsValid`;
  `widgetsThatMaybeChangedLayout` (`WorldWdgt` ~:287); `recalcIterationsCap` (`WorldWdgt` ~:930).
- **The seam being deleted (Phase E):** `Widget._reFitContainerAfterRawGeometryChange` (~:1662), `Widget._reFitContainer`
  (~:1693), `silentRawSetExtent` (~:1609, the seam fire at ~:1642), `rawSetExtent` (~:1563), `fullRawMoveBy` (~:1271),
  `_markForRelayoutNoClimb` (~:3883).
- **The arranges being converted:** `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` (~:118, read-back ~:157/176),
  `WindowWdgt._positionAndResizeChildren`, `ScrollPanelWdgt._positionAndResizeChildren` (~:327; text path ~:341–352;
  merged-bounds commit ~:399), `ScrollPanelWdgt._reLayoutScrollbars` (~:119), `keepContentsInScrollPanelWdgt` (~:412).
- **The pure measure to build (Phase D — the GENERAL `preferredExtentForWidth`):** `TextWdgt.breakTextIntoLines` (~:304;
  reads `@width()` when `@softWrap`), `TextWdgt.getTextWrappingData` (~:201, pure), `TextWdgt._reLayoutSelf` (the commit;
  `height = lines·ceil(fontHeight)`), `Widget.getRecursiveMinDim/DesiredDim/MaxDim` (~:4025–4125, the clean model),
  `Widget.rawSetWidthSizeHeightAccordingly` (~:750, already returns the height). *(The text-scoped `measureWrappedHeight`
  built in the old Phase A was REVERTED in Phase C — it measured a transient; rebuild the measure here, general, where it
  retires the `subBounds` read-back.)*
- **The fixpoint loop (Phases E/F):** `WorldWdgt.recalculateLayouts` / `_recalculateLayoutsBody` (~:925, the until-loop +
  `recalcIterationsCap` → `RECALC_NONCONVERGENCE` ~:936), `WorldWdgt.doOneCycle`.
- **The authoritative analysis (READ FIRST, owner's WIP — kept current with this plan):**
  `docs/archive/layout-system-architecture-assessment.md` — §2.3 (fixpoint), §2.4 (read-back root), §2.5 (two sizing
  philosophies + the clean measure engine), §2.6 (empirical convergence rests on these booleans), **§4.1 (pure measure —
  the GENERAL `preferredExtentForWidth`, Phase D), §4.2 (structural convergence — Phase F), §4.4 (split dirtiness —
  Phase E)**. Its "Do not revisit (already falsified)" list (Path A pending-aware accessors; reformulating the
  proportion fraction; routing ScrollPanel.add through the batch tier) must NOT be re-attempted.
- **The corrected falsification record (why the naive measure fails):**
  `docs/archive/retire-adjustingContentsBounds-via-text-measure-plan.md` (⛔ VERDICT block) + memory
  `fizzygum-adjustingcontentsbounds-flag`.
- **Context:** `docs/archive/deferred-layout-OVERVIEW.md` (render/layout separation, the in-pass-enqueue/off-pass-invalidate
  seam, the `elasticity 0` cycle-break §5), `docs/archive/softwrap-deferred-layout-conversion-plan.md` (§5 — the reversal-heavy
  soft-wrap family), `Fizzygum-tests/DETERMINISM.md`, memories `fizzygum-deferred-layout-plan`,
  `fizzygum-layering-naming-tiers` (the `check-layering.js` rule family Phases D/F extend), `Fizzygum/CLAUDE.md`,
  `Fizzygum-tests/CLAUDE.md`.

---

**One honest framing to carry in.** This is the assessment's "big change," done as a sequence of byte-safe deletions
rather than a rewrite — and the executed shape differs from the original sketch: **A/B's pure text measure was
a transient and was reverted** (its only surviving piece is the vertical-stack hand-forward); **C makes the arrange a
FIXED POINT by deleting the height wobble** (the flag is now correctness-unnecessary — proven by the reverse-disable
gate); **D** DELETES the cross-method suppression (#2 + #3) DIRECTLY (option 4) — the predicted ~1.6× redundant-pass cost
was a pre-C wobble artifact that didn't materialize, so the non-notifying apply tier the sketch proposed was deferred to
E (where it belongs, in dirty-bit form), and the trade is an owner-accepted temporary capstone-red intermediate; **E**
(NARROW) DELETES the `@_adjustingContentsBounds` boolean itself (field + all #1 re-entrancy guards) via a non-re-applying
self-resize — the FULL seam deletion was probed and REVERTED because greening the capstone for scroll panels is
entangled with general-scroll one-pass convergence (their careless pushes ARE their convergence re-enqueues), so the
seam + capstone-green are deferred to a convergence arc; the seam STAYS; **F** (now merged with E's deferred half) makes
the scroll arrange single-pass, deletes the seam, and makes convergence structural (the empirical crutches DELETED). The
destination is **proper layouts**; the spearhead boolean `@_adjustingContentsBounds` is now GONE, and the remaining proof
of arrival is that `_reFitContainerAfterRawGeometryChange` and `recalcIterationsCap` no longer exist and the dpr2 torture
is silent. If any phase cannot be made byte-exact with reasonable effort, the prior committed phase is a sound resting
point — stop there and report. **Recurring lessons: (C) when a scoping lists N non-idempotencies, find WHICH one
perpetuates the cycle before "fixing" all N — the others may be load-bearing behaviour, and "fix them all" broke 10
panels here. (D) a screenshot-only probe is INCOMPLETE — run the capstone + paint-read-only gates too. (E) a
"green capstone" is NOT free: the pushes the capstone flags on scroll panels are their CONVERGENCE iteration, so removing
them ⟺ solving general-scroll one-pass convergence — the full seam deletion under-converged 8 scroll/drag tests and was
reverted; narrow E (delete only the flag) banks the spearhead at zero risk.**
