# Ordered down-walk — the Stage-B plan (authored 2026-07-16, to be executed COLD, owner-gated)

**Status: PLAN. No code.** This refreshes the §4.4 ordered-down-walk direction for the post-seam,
post-INV-2-unification world, with NEW production evidence (§3) that the down-walk fixes a real,
shipping staleness class nothing else covers. It supersedes the *staging* sections of
`proper-layouts-4.4-ordered-downwalk-plan.md` (whose §8 verdict was about the now-moot SEAM deletion,
see §6) and is the "Stage B" named by the INV-2 unification plan (Fizzygum `db6f19b4`, 2026-07-16).
**Line numbers drift — grep the named symbol.**

## §0 — Cold context

Fizzygum = CoffeeScript GUI on one `<canvas>`; every class a global; `nil` == `undefined`. Umbrella
`/Users/davidedellacasa/code/Fizzygum-all/` (not a repo) holds `Fizzygum/` (source), `Fizzygum-tests/`
(macro SystemTests, byte-exact SWCanvas screenshots), `Fizzygum-builds/` (generated). Commands via the
cwd-safe wrapper: `fg build` (all lints), `fg presuite` (~3.5 min inner loop), `fg gauntlet` (~5 min
full gate), `fg status`. Long ops: `run_in_background` + task notification; never foreground-poll.
Layout tiers (FLOWRULE, enforced): public setters self-settle; immediate `_apply*` mutators only
mutate; off-settle code records intent (`_invalidateLayout` + `@desired*`).

## §1 — What the down-walk is, and why now

**Today** the settle engine (`WorldWdgt._recalculateLayoutsBody`) drains a work-list
(`widgetsThatMaybeChangedLayout`): pop valid entries; on an invalid one, CLIMB to the top-most invalid
ancestor (chain-top); `_reLayout` that chain-top (which lays its subtree however its class chooses);
then the ordered settle-time up-edge (`_reFitMyTrackingContainerAfterSettle`, gated on a
frame-actually-changed no-op skip) re-fits a size-tracking container once after its content settles.
Convergence is near-single-pass; the 100000-iteration guard is a never-fire assert
(`RECALC_NONCONVERGENCE`).

**The down-walk** (assessment §4.4) replaces the pop/climb discovery with two-flag dirtiness: every
`_invalidateLayout` marks the widget `needsLayout` and flips `hasDirtyDescendant` up the parent chain;
the settle then walks DOWN from the world (or from dirty roots), visiting a parent before its children,
in ONE ordered traversal. The engine — not per-class idioms — guarantees a resized parent's children
are re-laid.

**Why now (what changed since it was deprioritized):**
1. **The seam is gone** (2026-07-01): §4.4 no longer competes with a seam-deletion goal; it stands on
   its own merits (assessment §4.4 note).
2. **INV-2 is unified** (`db6f19b4`, 2026-07-16): the composite-child re-lay is ONE base hook
   (`Widget._applyExtent` → `_reLayoutMyChildrenAfterImmediateResize`, declared via
   `_placesChildrenInLayout`) + ONE lint (`check-composite-relay.js`) — the down-walk has a single,
   uniform entry-point to absorb and then delete, not 8 bespoke overrides.
3. **NEW production evidence (§3):** a staleness class the hook CANNOT cover ships today — the
   bypass-sized window content. Only an engine-side guarantee fixes it.

## §2 — Engine facts a cold executor needs (verified in-tree 2026-07-16)

- `WorldWdgt._recalculateLayoutsBody`: work-list stack + pop-valid + climb-to-topmost-invalid +
  `_reLayout(chainTop)` + settle-time up-edge with the frame-unchanged skip. Read its long comments —
  they are the authoritative history.
- **⚡ THE BYTE-EXACTNESS LEVER: the settled layout is an order-independent fixpoint.** In-tree comment
  (Opt-2, 2026-07-02): *"reversing the loop's processing order is 165/165 at dpr1/dpr2/webkit."* So a
  traversal-order change is byte-exact **iff the same set of widgets gets re-laid**; the acceptance
  instrument is a re-lay SET trace (not order).
- The stack arrange (`SimpleVerticalStackPanelWdgt._positionAndResizeChildren`) sizes children two
  ways: a TRACKING child (`_reLayoutChildren?`) via `_setWidthSizeHeightAccordingly` (Path B); every
  other child via the override-BYPASSING `_applyExtentBase` + `_applyMoveToBase` — **and never calls
  the child's `_reLayout`**. Base `_reLayout` recurses only into corner-internal/h-stack children. A
  leaf heals because `_applyExtentBase` fires `_reLayoutSelf`; a child-PLACING composite (its layout
  in `_reLayout`) does not heal — that is the §3 bug class.
- Residual true convergence cases the down-walk does NOT remove (assessment §2.5/§2.6): aspect-locked
  width↔height cycles (broken by `elasticity 0`), nested-window first-placement
  (`contentNeverSetInPlaceYet`), and the settle-time up-edge (content-size→container-fit is genuinely
  bottom-up). Stage B keeps all three; it fixes the DOWNWARD staleness class only.

## §3 — The evidence: the staleness census (2026-07-16)

**Methodology — the staleness oracle** (`Fizzygum-tests/.scratch/staleness-census.js`, reusable): boot
the production build; open 8 app windows + the basement; resize every window narrow (240px) then wide
(620px) via the PUBLIC `setExtent`; then post-order over all 509 widgets: snapshot subtree geometry →
force `w._reLayout(w.bounds)` → diff. A converged arrange is idempotent, so ANY movement = the widget
sat stale. (Run it synchronously in one `page.evaluate` — no frames elapse between snapshot and re-lay,
so animated widgets don't false-positive.)

**Findings:**
- `ToolPanelWdgt`: buttons wrapped for a ~40px panel inside a 610px frame (column instead of row).
  Reachable via ScrollPanel's POLYMORPHIC contents-resize → **fixed same day by declaring
  `_placesChildrenInLayout: -> true`** (the Stage-A mechanism working as designed; census re-run
  clean for it).
- **`BasementWdgt` — the down-walk's motivating instance, still shipping:** after the basement window
  opens, `@scrollPanel` sits ~100px SHORT of what `BasementWdgt._reLayout` computes
  (census: `ScrollPanelWdgt[…,362] → […,462]`, cascading to its contents + sliders + handle).
  Basement is a NON-tracking stack element sized via the BYPASS — no declaration can intercept
  `_applyExtentBase`, and nothing runs its `_reLayout` after the stack sizes it. **This is the class
  of bug Stage B exists to kill.** More instances likely exist in flows the census battery didn't
  drive (its app list + two window sizes are a sample, not a proof of completeness).

## §4 — Staging (each stage byte-exact-gated + independently shippable; STOP-per-stage sanctioned)

- **B1 — two-flag scaffold, ASSERT-ONLY.** Add `hasDirtyDescendant` (default false);
  `_invalidateLayout` sets it on every ancestor it climbs through (O(depth), stop when already set —
  mirror how `layoutIsValid` pushes to the work-list today). NOTHING reads it for behaviour; add an
  audit assert (danger-config-torture-visible, like the settle/capstone gates): whenever the drain
  picks a chain-top, assert the chain-top is reachable from a `hasDirtyDescendant` path from world.
  Byte-identical by construction (bookkeeping + assert). Also clear flags in `_resetWorldNoSettle`
  (the resetWorld state-leak gotcha).
- **B2 — root-down visitation.** Replace pop/climb discovery: walk down from the world along
  `hasDirtyDescendant`, `_reLayout`-ing each `needsLayout` widget parent-first, clearing flags on the
  way; keep the work-list only as a cross-check trace initially. Acceptance: the SET of re-laid
  widgets per flush is identical to the old engine's (trace-diff over the full suite), leaning on the
  order-independence lever (§2). The settle-time up-edge stays exactly as-is. Determinism-sensitive:
  full §5 protocol.
- **B3 — engine-driven child re-lay (the payoff).** During the walk, when a visited widget's FRAME
  CHANGED (position or extent — same predicate as the up-edge's no-op skip), visit its child-placing
  children (the `_placesChildrenInLayout` capability — Stage A conveniently declared exactly the right
  set) even if not flagged dirty. This is a DELIBERATE BEHAVIOUR FIX, not byte-exact where the bug
  bites: acceptance flips from byte-exactness to (a) the census oracle reports **0 movers** (Basement
  included), (b) visual verify any suite diffs are healed-staleness improvements (expect few: the
  suite never renders the stale flows — `fg diffpage` the changed set), (c) gauntlet + torture green.
- **B4 — retire the transitional pieces.** With B3 the engine guarantees child re-lay: delete the
  Stage-A hook + `_placesChildrenInLayout`… **only if** B3 also covers the IMMEDIATE path (raw
  `_applyExtent` outside any settle — ctors, `_createReferenceNoSettle` — today healed by the hook
  synchronously with NO flush). If B4 would need those sites to flush instead, that is a design
  decision to bring to the owner; keeping the (now tiny, uniform) hook for the immediate path and
  retiring only the lint's exempt-marker debt is a sanctioned resting point.

## §5 — Verification protocol (all of it, per stage)

1. `fg build` 0 violations · 2. `fg gauntlet` all legs · 3. danger-config torture (3× {dpr2-fastest-s8,
dpr2-fast-s8, dpr1-fastest-s8, dpr2-fastest-s4}; `RECALC_NONCONVERGENCE` absent) — the B1 assert and
B2 trace-diff must ride these · 4. re-lay SET trace before/after (B2's acceptance; the relay-trace
probe from the INV-2 arc is the template, `Fizzygum-tests/.scratch/relay-trace.js`) · 5. the staleness
census oracle (B3's acceptance: 0 movers) · 6. production probes (basement geometry; open-app battery).
No conclusions before evidence; two failed fix-shapes on a stage = wrong model, stop and re-frame.

## §6 — What was falsified before, and why it does NOT block this

`proper-layouts-4.4-ordered-downwalk-plan.md` §8 (2026-06-29) falsified: the off-pass freefloating
climb, an ordered-traversal content-first pre-settle, and the analytic position↔frame decoupling —
each as a means to DELETE THE SEAM ("same 10 fail, recovers 0"). The seam was then deleted anyway by a
different route (settle-time up-edge, 2026-07-01). Stage B here does NOT re-attempt any of those
shapes and does NOT touch the up-edge: B2 changes only dirty-discovery/traversal (same re-lay set);
B3 adds a downward child-re-lay guarantee those probes never targeted. The §8 finding that the arrange
is "single-pass-correct" is supporting evidence FOR the walk, not against it.

## §7 — Symbol map

`WorldWdgt._recalculateLayoutsBody` / `widgetsThatMaybeChangedLayout` /
`_reFitMyTrackingContainerAfterSettle` · `Widget._invalidateLayout` / `__markForRelayout` /
`_markLayoutAsFixed` / `layoutIsValid` · `Widget._applyExtent` (Stage-A hook) /
`_placesChildrenInLayout` / `_compositeChildrenBuilt` / `_reLayoutMyChildrenAfterImmediateResize` ·
`SimpleVerticalStackPanelWdgt._positionAndResizeChildren` (the bypass sizing) ·
`buildSystem/check-composite-relay.js` · probes: `Fizzygum-tests/.scratch/staleness-census.js`,
`relay-trace.js`, `probe-basement.js` · docs: `layout-system-architecture-assessment.md` §2.5/§2.6/§4.4,
`proper-layouts-geometry-seam-removal-plan.md`, `proper-layouts-4.4-ordered-downwalk-plan.md` §8,
the INV-2 unification plan (`~/.claude/plans/yes-plan-for-this-sprightly-boot.md`, §10/§11).
