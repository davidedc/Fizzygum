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

1. `fg build` 0 violations · 2. `fg gauntlet` all legs · 3. danger-config torture ({dpr2-fastest-s8,
dpr2-fast-s8, dpr1-fastest-s8, dpr2-fastest-s4}; `RECALC_NONCONVERGENCE` AND
`DOWNWALK_UNREACHABLE_CHAINTOP` absent) — **1 round (~6–7 min) is the PER-STAGE gate; 3 rounds
(~22 min) only at the arc close** (amended 2026-07-16, owner request: the DOWNWALK token is wired
into both headless runners' fail-gate exactly like NON_INTEGER_GEOMETRY, so every presuite/gauntlet
suite run already exercises the audit — the torture only adds danger-cadence sampling; script:
`Fizzygum-tests/.scratch/stage-b-torture.sh [ROUNDS]`) · 4. re-lay SET trace before/after (B2's
acceptance): `Fizzygum-tests/.scratch/relayset-prelude.js` rides the runner's existing
`AUDIT_PRELUDE`/`AUDIT_DIR` rails (one `LAYOUTAUDIT RELAYSET` line per non-empty flush, per-test
logs), diffed by `relayset-diff.js`; ⚠ CALIBRATE FIRST with an A/A run (same build traced twice) —
if event batching under load merges flushes, fall back from per-flush sequences to per-test union
sets · 5. the staleness census oracle (B3's acceptance: 0 movers) · 6. production probes (basement
geometry; open-app battery).
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

## §8 — Execution log

### B1 — two-flag scaffold, ASSERT-ONLY ✅ COMPLETE 2026-07-16 (all gates green, 1 sanctioned recapture)

**Shape as landed (grep the symbols; line numbers drift):**
- `Widget.hasDirtyDescendant` (default `false`, declared next to `layoutIsValid`; added to
  `@serializationTransients` — it is flush-scoped bookkeeping, and without the transient entry every
  once-flagged widget would bake a stale own-`false` into saved files).
- `Widget.__flagHasDirtyDescendantUpwards` — THE propagation atom: flag me + ancestors, stop at the
  first already-flagged node (O(depth) amortized); every node it flags is recorded on
  `world._dirtyDescendantFlagged` (declared beside `widgetsThatMaybeChangedLayout`).
- Two call sites — both were needed from the start, not empirically discovered later:
  1. `__markForRelayout` (the single enqueue atom; the single `layoutIsValid = false` writer —
     grep-verified) calls `@parent?.__flagHasDirtyDescendantUpwards()`, UNconditionally (re-invalidating
     an already-invalid widget re-flags its CURRENT chain, self-healing reparents-after-invalidate).
  2. `Widget.__add`, right after `@_addChild` — the ATTACH funnel (grep-verified the only `_addChild`
     caller; parent assignment exists only in `TreeNode._addChild`/`removeChild`): if the attached
     subtree arrives dirty (`not aWdgt.layoutIsValid or aWdgt.hasDirtyDescendant`), flag my chain.
     Without this the audit would fire on the UNIVERSAL constructor-then-add flow (an orphan is
     invalidated before it has ancestors). TreeNode itself stays layout-free (its header forbids it).
- Clearing: `recalculateLayouts`' `finally`, ONLY when the drain emptied the work-list — the two
  structures share one lifecycle, and a RECALC_NONCONVERGENCE throw deliberately keeps the flags (the
  pending widgets still need to be reachable). NO `_resetWorldNoSettle` clearing — deliberately: the
  reset rides a settle, so its own flush lands in this `finally` with the list drained (clearing
  mid-reset would DROP flags for teardown-invalidated survivors like the basement and false-fire the
  audit at the enclosing flush).
- The audit: in `_recalculateLayoutsBody` right after the climb — walk the chain-top's ancestors; any
  unflagged ancestor ⇒ `console.error "DOWNWALK_UNREACHABLE_CHAINTOP: …"` (no throw — B1 is
  diagnostic; nothing reads the flags for behaviour). Root identity is NOT checked (world / hand /
  orphan roots are all legitimate walk roots for B2).
- Fail-gate wiring (tests repo): `run-all-headless.js` + `run-macro-test-headless.js` treat the token
  exactly like NON_INTEGER_GEOMETRY — a firing FAILS the test it happened in, suite-wide.

**Evidence (2026-07-16 11:46–12:17):** build 0 violations · audit token ZERO across: dpr1 suite +
paint audit (presuite ×2), full gauntlet 9/9 legs (dpr1/dpr2/webkit/apps/paint/tiernaming/settle/
capstone/refs, 260 s), 1-round danger-config torture (all 4 configs, both tokens absent) — the
reachability invariant held on the FIRST run; no hole was ever observed. ONE sanctioned recapture:
`macroDuplicatedInspectorDrivesCopiedTargetOnly` dpr1+dpr2 (the two new base members shift the
member-list scroll proportion — visually verified as the known benign sub-row scroll class before
recapturing; same event as Stage A).

**Facts B2 inherits:** the flags are trustworthy suite-wide (audit-verified); `__markForRelayout` is
the single dirt writer and `__add` the single attach funnel; a copied/deserialized widget cannot sit
dirty outside the work-list post-flush (post-drain, `layoutIsValid == false` ⇒ in the work-list —
enforced by the single-writer discipline).
### B2 — root-down visitation ✅ COMPLETE 2026-07-16 (two falsified cuts on the way; all gates green, 0 recaptures)

**Shape as landed** (all in `WorldWdgt` unless noted; grep the symbols):
- `_recalculateLayoutsBody` = ROUND loop over the work-list: SWEEP still-invalid entries (whole-list
  filter replacing the lazy tail-pop; the sweep REPLACES the array — safe, no other code holds a
  reference, grep-verified) → DERIVE flags + dirty roots fresh from the entries
  (`__flagHasDirtyDescendantUpwards`, INCLUSIVE of the entry; roots by climbing CURRENT parent
  pointers, encounter order) → WALK each root (`__downWalkLayout`: parent-first, flags-only
  descent, re-lay iff invalid) → **FALLBACK**: any entry still invalid after the walks gets the old
  drain's exact treatment (climb to top-most contiguously-invalid ancestor, settle) → STUCK
  TRIPWIRE (zero-progress round ⇒ `DOWNWALK_UNREACHABLE_CHAINTOP` console.error + throw).
- `__reLayoutOneSettleNode` = the old per-chain-top processing extracted verbatim (frame snapshot,
  `_reLayout`, settle-time up-edge gated on frame-changed, minimal error containment, the
  `RECALC_NONCONVERGENCE` counter) — shared by walk + fallback.
- `Widget.hasDirtyDescendant` is FLUSH-LOCAL scratch: derived per round, cleared wholesale in
  `recalculateLayouts`' finally (only when the drain emptied). B1's enqueue-time propagation and
  `__add` attach hook are GONE — with flags derived at flush time from the entries themselves, the
  whole reparent/attach hazard class is structurally impossible instead of empirically absent.
- **DELIBERATE deviation from §4-B2's "keep the work-list only as a cross-check trace":** the
  work-list stays load-bearing — it is the enqueue-dedup structure, the loop-termination oracle,
  the per-round derivation source, and the fallback's entry list. The flags only steer the descent.

**The two falsified cuts (§5's two-falsifications rule was hit exactly, then the re-frame worked):**
1. *Incremental flags + walk clears them mid-descent*: a mid-walk enqueue's propagation
   short-circuited at a stale flag below the walk's cleared frontier, leaving the upper chain
   unflagged → next round could not reach the entry → the (then) stuck-detection THREW
   (`ToggleButtonWdgt spec=100000`), the in-world error console popped, and 13 tests diverged in
   cascade (MenuHeader instance-ID shifts). Lesson: never clear derived reachability state while
   still traversing by it.
2. *Derive-per-round but walk-only, tripwire removed as "structurally impossible"*: the
   impossibility proof missed the PARENT-POINTER-ONLY attachment class — a widget whose `parent`
   is set but which is NOT in its parent's `children` (the basement is the documented example) is
   flaggable via the parent climb yet unreachable by the children-array descent. Zero-progress
   round + no tripwire = SILENT infinite spin at 100% CPU **during harness boot** (renderer pegged,
   `world` never constructed — masquerading as the boot-storm flake, same D–E shard hanging twice).
   Diagnosed by per-30s in-page boot diags (`{world:false, coffee:true}` forever) + `ps` CPU;
   `.scratch/boot-spin-stack.js` (CDP Debugger.pause stack sampler) stands ready for the next such
   spin. Lessons: (a) the walk's reach is `children`-arrays, the climb's reach is `parent`
   pointers — they are DIFFERENT graphs; (b) never remove a cheap tripwire on the strength of a
   fresh proof — it was falsified within the hour; a loud throw beats a pegged tab.

**Acceptance evidence (2026-07-16 13:15–13:5x):**
- Re-laid-SET trace: `relayset-prelude.js` (wraps every class's own `_reLayout`; rides the runner's
  AUDIT_PRELUDE/AUDIT_DIR rails) + `relayset-diff.js`. ⚠ CALIBRATION MATTERED: per-flush sequences
  are NOT load-stable (A/A on the same build: 5/250 tests drift by one trailing hover/handle
  flush); the calibrated bar is PER-TEST UNION sets (A/A: 250/250 identical). Result:
  **RELAYSET UNION IDENTICAL — 250/250 tests, 0 union mismatches** (37 benign flush-boundary
  drifts), before-trace `/tmp/relayset-before-A`.
- Full dpr1 suite traced: **ALL 250 PASSED**, byte-exact, zero recaptures.
- Gauntlet 9/9 legs PASS (254 s, no retries): dpr1/dpr2/webkit/apps/paint/tiernaming/settle/
  capstone/refs.
- 1-round danger-config torture: all 4 configs clean, both tokens absent.
- Staleness census: unchanged 3-mover baseline (BasementWdgt bypass instance + 2 cascade
  artifacts) — B2 changes discovery only, not behaviour; the basement heal is B3's acceptance.

**B3 inherits:** the walk is the injection point — `__downWalkLayout` visits parent-first with the
frame-changed predicate already computed in `__reLayoutOneSettleNode`; B3 adds "when my frame
changed, also visit my `_placesChildrenInLayout` children even if unflagged". The fallback path
must get the same treatment for parent-pointer-only widgets (the basement itself lives there!).
### B3 — engine-driven child re-lay ✅ COMPLETE 2026-07-16 (the payoff; ZERO suite diffs, no recaptures)

**Shape as landed:**
- In `__reLayoutOneSettleNode` (so BOTH settle routes — walk and fallback — get it): snapshot the
  frames of the node's `_placesChildrenInLayout` children before `node._reLayout()`; afterwards,
  any watched child whose frame changed gets its own `__reLayoutOneSettleNode` recursively (heals
  cascade; the up-edge no-ops unless the child's own re-lay moved its frame; the error containment
  and RECALC counter apply).
- TWO deliberate refinements over the §4-B3 sketch, both documented at the injection site:
  (1) the predicate is PER-CHILD frame delta, not the node's own frame delta — a divider drag
  redistributes children while the stack's frame stays put, so the sketched gate would miss
  redistribution; (2) the injection lives in the shared per-node settle helper, not the walk's
  traversal — so fallback-settled widgets (parent-pointer-only attachments) are covered too.
- `BasementWdgt` declares `_placesChildrenInLayout: -> true` (replacing its census-day exempt
  marker, whose "deliberately outside this mechanism" rationale is exactly what B3 changed). The
  remaining exempt markers STAY: within the census battery no other instance surfaced, and any
  future find is now a one-line declaration with engine backing.
- Only-invalid-children are skipped at snapshot (the walk/fallback settles them the same flush);
  re-laying a converged child is idempotent (fixpoint), so extra visits are pixel-neutral.

**Acceptance evidence (2026-07-16 13:4x–14:0x):**
- Staleness census: **the arc's motivating instance is HEALED** — BasementWdgt (10-widget mover
  cluster) and the HandleWdgt artifact are GONE; live-flow probe (`probe-basement-relay-trace.js`)
  confirms the basement settles to the correct scrollPanel frame ([…,462]) as the window opens.
- ⚠ The plan's "0 movers" acceptance was MIS-CALIBRATED: the baseline's "2 cascade artifacts"
  read was wrong. One mover remains — the basement scrollPanel's CONTENTS fit — and it is
  PRE-EXISTING and ARC-INDEPENDENT (present at B2-close before any B3 code, and in the pre-Stage-B
  baseline): forcing `ScrollPanelWdgt._reLayout` re-sizes the contents PanelWdgt once
  (591→900 wide in the open-basement flow; 476→557 tall in the census battery) then STABLE — a
  policy disagreement (viewport-width fit vs content-width fit), not a runaway and not an engine
  discovery gap. Follow-on question for the owner; not chased inside this arc (census case law:
  findings are questions, never a backlog).
- Suite: presuite dpr1 250/250 + paint audit green with ZERO pixel diffs (the heals are
  suite-invisible exactly as §4-B3 predicted — no test renders the stale flows). Gauntlet 9/9 +
  1-round danger-config torture clean (see below).

### B4 — assessment (owner decision pending; no code)

B3 does NOT cover the raw immediate path (`_applyExtent` outside any settle — ctors,
`_createReferenceNoSettle`): the injection runs only inside the settle. The Stage-A hook still
heals those synchronously. Options for the review:
- **(a) KEEP the Stage-A hook + lint (recommended):** the hook is one tiny base mechanism; the
  `_placesChildrenInLayout` capability now does double duty (immediate hook + B3 engine
  injection); the lint's declare-or-mark pressure directly feeds the engine's coverage. Zero risk,
  nothing to re-verify.
- **(b) Delete the hook, rely on attach-time settles:** construction flows settle when attached,
  but the raw-path sites that read geometry between a raw resize and the next settle would regress;
  needs a dedicated raw-path audit + likely recaptures. Not attempted.
