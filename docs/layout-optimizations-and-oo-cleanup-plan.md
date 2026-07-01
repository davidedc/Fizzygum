# Plan — layout optimizations + OO cleanup (post-seam-deletion)

**Status: IN PROGRESS (2026-07-01). Self-contained; runnable cold.** Fizzygum master **`c2aec3bf`**; the cheap tier
(**Opt-4 rule `[N]` + OO-1 + OO-3**) has landed on top (uncommitted at time of writing — see the per-item ✅ markers
below). Remaining: Opt-1 (substantive, determinism-gated), Opt-2 (subsumed by Opt-1), Opt-3 (opportunistic), OO-2 (general OO pass).

## §0 — Why this now, and what it is NOT

The **proper-layouts / settle-convergence arc is complete** (see `layout-system-architecture-assessment.md`, esp. §1,
§2.6, §4.1): the notify-by-mutation seam was **deleted 2026-07-01** and replaced by a **settle-time up-edge** (the
settle loop re-fits each chain-top's size-tracking container from its content's *final* geometry, once, after it
settles); **Stage 6** retired the convergence cap to a never-fire assert; the caret scroll-follow and the window→stack
re-fit were made single-pass; the dead `_batchingLayoutSettling` batch tier was deleted. There are **no remaining
deletion targets** — every layout suppression/convergence boolean the standing mandate targeted is gone, and the two
residual convergences (3 nested-window first-placement re-visits; aspect-locked width↔height cycles, cycle-broken by
`elasticity 0`) are *proven irreducible*.

So what remains is **optimization + OO cleanup — none of it the mandate, all of it optional.** This plan collects it.
Each item is independent, byte-identical-intended, and gated (§3). **None deletes a boolean or changes behaviour;** do
not treat any as required. Pick by ROI. The single genuinely-substantive item is Opt-1 (the two-flag walk-down).

**Determinism reminder:** anything touching the settle loop / `_reLayout` / an arrange / `_invalidateLayout` / the
up-edge is a **convergence change** → it needs `./fg gauntlet` (dpr1/dpr2/webkit) **and** the danger-config torture
(`RECALC_NONCONVERGENCE` absent + 0 fails), not just the suite. See assessment §6.4.

---

## §1 — Optimizations (ranked by leverage)

### Opt-1 — Two-flag dirty tracking + walk-DOWN settle loop  (assessment §4.4; the leading item)
**What.** Replace the single `layoutIsValid` + climb-and-enqueue-the-whole-chain with the standard browser/React pair:
**`needsLayout`** (this node) + **`hasDirtyDescendant`** (a descendant needs layout). `_invalidateLayout` sets
`needsLayout` on the node and flips `hasDirtyDescendant` up the chain (O(depth) mark, **O(1) enqueue** — only dirty
*roots* go on the work-list); the settle loop then walks **down** from those roots instead of the current
pop-tail-then-walk-**up** (`WorldWdgt._recalculateLayoutsBody`, the until-loop + walk-up ~:948–997).
**Why (value).** (a) O(1) enqueues vs today's whole-chain push; (b) it makes the "freefloating child laid out twice"
sub-optimality (Opt-2) disappear naturally; (c) a cleaner, more legible loop. It is the closest thing to making
convergence *structural* rather than verified — though note it is **not** a single-pass *proof* (assessment §4.2) and
**not** a seam prerequisite (the seam is already gone).
**Risk / gate.** HIGH determinism sensitivity — this is the settle loop itself. Must be **byte-identical** (same widgets
re-laid-out, same order — verify the work-list contents/order match before/after) and clear the full torture. Stage in
`proper-layouts-4.4-ordered-downwalk-plan.md` (its §8 is the *pre-seam-deletion* record — the seam-replacement framing
there is superseded; mine the two-flag *mechanics*, ignore the "delete the seam" goal).
**Recommendation.** The one worth doing if any is — but only for cleanliness/efficiency, with eyes open that it is a big
determinism-gated change for no behaviour gain. Timebox; abandon if it can't be made byte-identical.

### Opt-2 — Freefloating walk-up TODO  (assessment §4.5)
**What.** The settle loop's walk-up stops at the *first valid* parent rather than the *topmost invalid* one
(`WorldWdgt._recalculateLayoutsBody` ~:987, and the code's own TODO there), so a freefloating child can be laid out
twice — first against a stale parent size. Stop at the last-invalid-on-the-way-up.
**Why.** Removes redundant double-layout for freefloating children.
**Risk / gate.** Local but cadence-sensitive (it changes *which* widget the loop lays out first) → torture. Largely
**subsumed by Opt-1** (the walk-down eliminates the same double-layout structurally); do Opt-2 standalone only if Opt-1
is declined.

### Opt-3 — Flush-count hygiene in multi-mutation handlers  (assessment §4.6)
**What.** A handler doing several geometry mutations self-settles once *each*. Where a gesture changes both extent and
position, prefer the compound `setBounds` (one flush) over `setExtent` + `moveTo` (two). Audit the multi-mutation
handlers (start at `HandleWdgt.nonFloatDragging` `src/HandleWdgt.coffee` ~:252 — `setExtent`/`moveTo`/`setWidth`/
`setHeight`).
**Why.** Pure micro-optimization (fewer flushes/frame). Byte-identical.
**Risk / gate.** Low; still a convergence-adjacent change → gauntlet + a short torture. Small ROI; do opportunistically.

### Opt-4 — A both-direction-edge hygiene lint  (assessment §4.2 / §6 static checks) — ✅ DONE (rule `[N]`, 2026-07-01)
**Outcome.** Scoped, and the *sound* both-direction-edge form was found **infeasible** in the `check-layering.js`
line-scanner: the signal is cross-method/cross-class data-flow ("width flows down" vs "size flows up" on one axis), not
the local textual pattern every rule keys off, and there is no clean per-class marker (every tracking container sets
child widths; the actual cycle is *proportional* width-down, which lives in one method — `VerticalStackLayoutSpec.getWidthInStack`).
Per the Opt-4 decision, built the narrow **sound** slice instead: lint **rule `[N]`**
(`SEAM_VERB_BANNED = /^_announce\w*ToContainer$/`, checked at each method def) bans re-*defining* the deleted
`_announce*ToContainer` seam verbs — a copy-from-git revival of the exact removed shape now fails the build. Verified:
injecting a dummy `_announceGeometryChangeToContainer` def fails `[N]`; clean tree passes (0 false-positives — no
`_announce*` def exists). The CALL side was already covered by rules `[I]`/`[K]`; `[N]` closes the DEF side those never
covered. Caveat (accepted): name-based, so a revival under a *new* name is not caught. Assessment §4.2/§6.3 updated.
**What (original scope).** A `check-layering.js`-style static guard that flags a *new* layout dependency edge coupling both directions on
one axis of one widget (width-flows-down AND size-flows-up on the same axis) — the shape that creates a genuine cycle.
**Why.** Not a convergence *proof* (that was falsified, §4.2), but a cheap **guard** that stops a future layout from
re-introducing the coupling the arc just removed. Fits the §6 rulebook ("obey the tiers, and the lint proves you did").
**Risk / gate.** Build-lint only; no runtime risk. The work is defining the edge-classification precisely enough to be
non-noisy — scope it before committing.

---

## §2 — OO cleanup

### OO-1 — Prune the deleted-seam comment residue — ✅ DONE (2026-07-01)
**Outcome.** Residue **15 → 6**. Higher-value than expected: 4 of the 15 were **misleading-stale** — they asserted a
*deleted* method is the live mechanism (`VerticalStackLayoutSpec:62` "`_announceLayoutPropertyChangeToContainer` stays
the NON-settling re-fit core"; `StringWdgt:121`/`:1236`; `SimplePlainTextWdgt:11`) — now corrected to the real
`@element._invalidateLayout()` / `_reflowContainedTextThenAnnounce` dirty-tree climb. Trimmed 4 redundant re-tellings in
`Widget.coffee` to terse pointers. The 6 survivors are the canonical mechanism docs (settle-loop `WorldWdgt:1000`, the
`_reFitMyTrackingContainerAfterSettle` doc, the PROPERTY-block head, the `_invalidateLayout` D1 one-liner) + MenusHelper's
2 accurate "now-deleted" history notes. Byte-identical (comment-only; build syntax gate green). The up-edge's own
explanatory comment was preserved.

**What (original).** The seam deletion left **~15 explanatory comments** naming the now-deleted announce-verbs
(`_announceGeometryChangeToContainer` / `_announceLayoutPropertyChangeToContainer`); a few were misleading-stale, the
rest fine as history — trimmed to a canonical note at `Widget._reFitMyTrackingContainerAfterSettle` with the scattered
ones shortened.

### OO-2 — Existing OO-smells backlog remnants (not layout-specific)
From the `oo-smells-backlog` memory, Phase 6 (God-class split) + Phase 7 are effectively complete. Remnants:
constant-naming "0b"; the `arg1..arg9` splat cleanup; the tiny optional 7f `GlassBox`; and **Phase-8 opportunistic** —
the drifted unified-shadow offsets (`4,4` / `5,5` / `7,7` / `6,6` across the shadow sites; see the
`fizzygum-unified-shadow-mechanism` memory — the intended single offset). These are pre-existing and orthogonal to the
layout arc; fold in if the owner wants a general OO pass. See `docs/oo-smells-refactoring-backlog.md` /
`docs/god-class-decomposition-plan.md`.

### OO-3 — Assess dead code / naming left by the seam + batch deletions — ✅ DONE (confirm-only, 2026-07-01)
**Outcome.** Nothing to delete. Both suspected-vestigial symbols are **live**, and the plan's "single-purpose"
assumptions were wrong: `_reFitContainer` has ~9 callers with **both** dispatch arms exercised (in-pass `__markForRelayout`
for the up-edge; off-pass `_invalidateLayout` for the gesture/attach callers), and
`_amIDirectlyInsideNonTextWrappingScrollPanelWdgt` is used by `WindowWdgt` ×2 **plus** the up-edge. The
`_batchingLayoutSettling` field is fully gone (only a `check-stinks.js` comment correctly records it as retired). Build
dead-methods gate: **0 new dead**. The one genuine redundancy — the now-trivial notify/non-notify twins — was a
**convergence-adjacent** change left out of this cheap sweep; **✅ DONE as its own determinism-gated pass 2026-07-01**
(next).

### Twin collapse — ✅ DONE (2026-07-01, determinism-gated follow-on to OO-3)
**Outcome.** Two SILENT-commit twin pairs became byte-identical once the re-fit seam was deleted (neither side is
overridden anywhere) and collapsed:
- `_commitExtentAndNotify` (a pure pass-through) folded into the **`__commitExtent`** leaf — its ~20 callers now reach
  the leaf directly, exactly like its `__commitWidth` / `__commitHeight` siblings.
- `_commitBoundsAndNotify` + the silent bounds arrange-twin `_applyBounds` folded into one **`_commitBounds`**.

The **move twins were investigated and found NOT collapsible**: `_applyMoveByAndNotify` is the polymorphic dispatch
point for the `ClippingAtRectangularBoundsMixin` scroll-opt + `ActivePointerWdgt` float-drag OVERRIDES (which repaint via
`@changed`, not `@fullChanged`), whereas bare `_applyMoveBy` is the uniform base translate the top-down arrange calls for
leaf children — merging would route arrange moves through those overrides on clipping panels and change their dirty
regions. The `_apply…AndNotify` full-mutator rename (drop the now-false suffix, ~100 call sites + ~10 overrides) stays
**out of scope**. Byte-identical (pure rename + forwarder removal, no logic change); gated by `./fg gauntlet`
(dpr1/dpr2/webkit) + the danger torture. Comments updated (`Widget.coffee`, `check-layering.js`,
`layering-naming-convention.md`).

**What (original).** Sweep for anything orphaned by the 2026-07-01 deletions beyond what the build gates already catch.
The dead-methods gate (`./fg build`) already fails on newly-dead methods, so this was mostly a naming/legibility pass.

### NOT in scope — §4.3 "encapsulate the engine state in a `layoutEngine` object"
The assessment §4.3 proposes moving the work-list + phase booleans + `_reFitContainer` dispatch into one
`world.layoutEngine` with a phase enum. **The owner has ruled this out** (the `proper-layouts-elimination-goal` memory:
relocating a boolean into an engine object is "bury it deeper," not the goal). The 2 remaining phase booleans
(`_recalculatingLayouts`, `_inLayoutMutation`) are load-bearing re-entrancy/dispatch flags, not convergence devices;
they stay where they are. Do not do §4.3.

---

## §3 — Verification (per item)
- **Opt-1 / Opt-2** (settle loop): `./fg gauntlet` (dpr1/dpr2/webkit 165/165 + apps/tiernaming/settle) **AND** the
  danger torture (manual loop over `dpr2-fastest-s8` / `dpr2-fast-s8` / `dpr1-fastest-s8` / `dpr2-fastest-s4`;
  `RECALC_NONCONVERGENCE` absent + 0 fails). Byte-identical or it does not ship.
- **Opt-3** (flush hygiene): `./fg gauntlet` + a short torture.
- **Opt-4** (lint) / **OO-1 / OO-3** (comments/dead code): `./fg build` (all static gates) + `./fg suite`; OO-2 per its
  own backlog gates. Benign inspector recaptures pre-authorised (deleting an inspector-visible `Widget` method
  recaptures `macroDuplicatedInspectorDrivesCopiedTargetOnly`).
- **Ask before commit/push**; `git commit -F <file>`.

## §4 — Recommended sequencing
1. **Opt-4 + OO-1 + OO-3** — ✅ **DONE 2026-07-01** (the cheap tier: rule `[N]`, the comment prune, the dead-code confirm).
2. **Opt-3** opportunistically.
3. **Opt-1** only as a deliberate, timeboxed effort (biggest change, determinism-gated, no behaviour gain) — and if
   taken, **Opt-2 falls out of it for free**.
4. **OO-2** if/when the owner wants a general (non-layout) OO pass.

The honest default, given the arc is complete and all of this is optional: the cheap §4-tier items are now done; what
remains is **Opt-1** (a "someday, for cleanliness" determinism-gated item, not a priority), plus **Opt-3** (opportunistic)
and **OO-2** (a general non-layout OO pass, on request).
