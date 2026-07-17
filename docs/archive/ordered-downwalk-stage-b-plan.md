> **ARCHIVED — COMPLETE (2026-07-17 restructure).** CAMPAIGN CLOSED 2026-07-16; B1-B3 executed+pushed, engine fully ungated (N4) — nothing remains
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Ordered down-walk — the Stage-B plan (authored 2026-07-16, to be executed COLD, owner-gated)

**Status: CAMPAIGN CLOSED 2026-07-16. B1–B3 EXECUTED + PUSHED (Fizzygum `b88102ee` / tests
`9f2ac0cb3`) — §8 is the execution log, §9 the next steps. §9 N1/N2/N3 RESOLVED same day (see their
bullets). The B4 SCHEDULE-VALVE RETIREMENT ARC EXECUTED the same day — §10 is its execution log: the
Stage-A synchronous hook is DEAD, the settle engine is the sole healer of composite interiors (valve
+ injection + walk). §9-N4 THEN EXECUTED the same day — §11 is its execution log: the engine is
UNGATED (injection watches EVERY valid child; the valve + the V1 seam gate on STRUCTURAL facts) and
the whole declaration mechanism is DELETED — `_placesChildrenInLayout`, `_compositeChildrenBuilt`,
the 5 exempt markers, check-composite-relay.js + its build wiring. One engine, one healing
mechanism, zero capability declarations, zero markers, one lint fewer. NOTHING REMAINS of this
plan's ambition.**
The sections below §0–§7 are the original plan, kept verbatim as authored (deviations called out
in §8).

This refreshes the §4.4 ordered-down-walk direction for the post-seam,
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

## §9 — Next steps (authored at arc close 2026-07-16, with the session's hard-won knowledge)

Ordered by recommended sequence; each is independently shippable and separately gated.

- **N1 — B4 decision (owner, ~zero code either way).** Recommendation was: **keep** the Stage-A
  immediate-resize hook + `check-composite-relay.js` lint. The `_placesChildrenInLayout` capability
  now does double duty (immediate raw path via the hook; settle path via the B3 injection), and the
  lint's declare-or-mark pressure directly feeds engine coverage. If deletion is still wanted:
  prerequisite is a RAW-PATH AUDIT (grep every `_applyExtent`/`_applyMoveTo` call outside settles —
  ctors, `_createReferenceNoSettle` — and prove each site's composite either flushes before the next
  paint or cannot host a declared composite), then expect recaptures. Not worth it unless the hook
  obstructs something.
  **DECIDED 2026-07-16 (owner): RETIRE — but via the SCHEDULE-VALVE redesign, sequenced AFTER N2**
  (decision trail: keep was recommended → owner chose retire → the raw-path audit FALSIFIED cheap
  deletion → owner confirmed retire-as-redesign-after-N2). **N2 landed later the same day, so the
  prerequisite is MET — this retirement arc is now unblocked and is the plan's NEXT work item.**
  The audit's findings, so the future arc executes cold:
  - **Closure**: 27 classes answer `_placesChildrenInLayout` true (10 declarers + inheritors:
    WindowWdgt/FolderWindowWdgt/TemplatesWindowWdgt via the stack; ListWdgt + 3 scroll-panel
    subclasses via ScrollPanelWdgt; the icon/shortcut family via WidgetHolderWithCaptionWdgt and
    GenericCompositeIconWdgt). 233 `_applyExtent` call sites in-tree.
  - **Why naive deletion regresses (4 verified classes):** (1) Path B
    (`_setWidthSizeHeightAccordingly` = `_applyWidth` → polymorphic `_applyExtent` → HOOK) runs the
    hook MID-ARRANGE and the caller consumes the returned height — the B3 injection fires too late
    (post-`_reLayout`); only the 3 `implementsDeferredLayout` classes (stack / scroll panel / TTF)
    get an explicit in-Path-B `@_reLayout()`. (2) TrackingTransformFrameWdgt (exempt marker) relies
    on the hook firing on its forwarded CONTENT (`TrackingTransformFrameWdgt.coffee` ~:94 comment)
    — a GRANDCHILD of the arrange's settle node, structurally invisible to the injection's
    direct-children window. (3) `StretchableCanvasWdgt._reLayoutMyChildrenAfterImmediateResize`
    is where paint buffers get recreated at the new size (unconditional recreation in `_reLayout`
    would erase the user's painting — FizzyPaint regression class #4a). (4) Raw sites heal only by
    settle-nesting context: `_createReferenceNoSettle` (`Widget.coffee` ~:2958, 95→75 post-ctor-
    settle + freefloating skip = nothing re-lays it, the shipped BasementOpenerWdgt/D1 bug class);
    ~40 builder sites (apps / creator buttons / WidgetFactory) on closure receivers.
  - **What retirement buys:** kills the arrange-path DOUBLE re-lay (hook mid-arrange + B3
    injection post-arrange, idempotent/pixel-neutral, perf-only), ~30 lines, 3 overrides, 1 lint.
  - **The sanctioned shape — SCHEDULE-VALVE:** replace the hook's synchronous re-lay with
    `_scheduleRelayoutRespectingPhase()` (in-pass → `__markForRelayout`, same-flush next round
    heals it; off-pass → `_invalidateLayout`, end-of-cycle flush heals before paint). Receiver-side,
    so it also closes the TTF grandchild hole. Prerequisites/costs: **N2 lands FIRST** (every extra
    re-lay makes arrange idempotence load-bearing — same prerequisite as N4, which this largely
    subsumes); layering rule [E] ("apply never schedules") deliberately amended in
    check-layering.js; equivalence oracle degrades to old-⊆-new UNION + byte-exact pixels;
    StretchableCanvasWdgt buffer recreation moves behind an extent-delta guard in its re-lay;
    ScrollPanelWdgt's contents-move TODO (`ScrollPanelWdgt.coffee` ~:286) absorbed into its
    `_reLayout` first; Path-B height-read-back verified per declarer (non-deferred declarers'
    heights must be interior-independent — spot-checked true for icons/holders/stretchables, verify
    on execution).
- **N2 — the residual census mover: scroll-panel CONTENTS fit non-idempotence (its own mini-arc,
  NOT engine work).** Evidence (§8-B3): forcing `ScrollPanelWdgt._reLayout` on the basement's panel
  re-sizes its contents PanelWdgt ONE step (591→900 wide open-flow / 476→557 tall census-battery)
  then stable — a POLICY CLASH between whoever sized contents to the viewport width and the
  arrange's content-width fixpoint. Pre-existing (present before any Stage-B code; the old baseline's
  "2 cascade artifacts" read was WRONG — only the Handle was cascade). Plan of attack: instrument
  who last sizes `sp.contents` in the open-basement flow (probe-basement-relay-trace.js is the
  template), name the two policies, decide the correct one with the owner, fix at the policy home
  (likely `_positionAndResizeChildren`/`_reLayoutChildren` disagreement), gate = census 0 movers +
  the full §5 protocol. ⚠ scroll-thumb pixels CAN change (vBar proportion) → possible recaptures.
  **✅ RESOLVED 2026-07-16 — one line at the scatter seam; the "two policies" framing was WRONG in
  an instructive way.** Writer-tagged probe (`.scratch/probe-n2-contents-writers.js`, tags every
  bounds-commit on the basement sp's contents with the policy method active at commit time) showed
  the two policies CONVERGE fine — every hook viewport-set is merge-corrected by the arrange in the
  same call (4× set→fix pairs in the open flow). The staleness enters AFTER the last arrange: lost
  widgets scattered into `sp.contents` via `PanelWdgt._addInPseudoRandomPositionNoSettle` (both
  callers: the close/lost re-home chain and `BasementOpenerWdgt`'s drop) never re-ran sp's merge.
  ROOT CAUSE: the fam-2 verify-and-drop (deferred-layout-residuals-audit.md, 2026-06-22) removed
  the seam's synchronous container re-fit claiming the settle-time up-edge covers it — FALSIFIED:
  the up-edge is gated on the laid widget's FRAME having CHANGED, and a scattered widget settles AT
  the frame the scatter just applied. User-visible: items beyond the contents edge were UNREACHABLE
  BY SCROLLING until an unrelated re-arrange healed them. FIX: `@_reFitContainer @parent` at the
  scatter seam (deferred, phase-valved; the parked-basement enqueue settles via the B2 fallback,
  exactly as designed). First cut used `instanceof ScrollPanelWdgt` and tripped the stink gate —
  `_reFitContainer` is the idiom the sibling drop/remove seams already use. Probe after: boot state
  heals while parked; the open flow's scheduled sp re-lay rides the same flush through the engine;
  census force = ZERO writes (idempotent). Gates: census **0 movers** (extended battery, 1282
  targets), gauntlet 9/9 byte-exact (zero recaptures — the scroll-thumb warning above did not
  materialize), combined 3-round torture at close. The residuals-audit doc closure paragraph now
  records the falsification.
- **N3 — exempt-marker audit under B3 semantics (cheap, mechanical, census-gated).** The 22
  remaining `immediate-resize-relay-exempt` markers were justified by Stage-A-era reasoning ("no
  polymorphic raw `_applyExtent` receiver"). B3 changed the question to "can an ARRANGE move/resize
  this class without re-laying it?" — true for ANY non-tracking stack element / window content.
  Audit each marked class: if it can sit bypass-sized (stack child, window content), convert marker
  → declaration (one line, engine-backed, BasementWdgt is the worked example). Extend the census
  battery to cover each converted class's flow (the battery is a sample, not proof — §3 note).
  **✅ RESOLVED 2026-07-16 — 16 of 21 markers CONVERTED to declarations; 5 stay.** Converted:
  window-content classes (ScriptWdgt, ErrorsLogViewerWdgt, CodePromptWdgt, ConsoleWdgt,
  InspectorWdgt, FridgeMagnetsWdgt, PatchNodeWdgt base — subclasses inherit, SimpleDocumentWdgt,
  VideoPlayerWithRecommendationsWdgt), stack/stretchable elements (SimpleLinkWdgt,
  SpeechBubbleWdgt), desktop-creatable droppables (ButtonWdgt — subclasses inherit,
  SwitchButtonWdgt, ColorPickerWdgt, FanoutWdgt, AxisWdgt). KEPT: CaretWdgt (childless overlay),
  LabelButtonWdgt (self-only re-lay), VideoControlsPaneWdgt + VideoPlayerWdgt (internal children —
  the parent's `_reLayout` always drives them), TrackingTransformFrameWdgt (its own `_applyExtent`
  override IS the mechanism). Ctor-order sweep (the WidgetHolderWithCaption trap): only
  ColorPickerWdgt raw-resizes pre-build → gained `_compositeChildrenBuilt: -> @feedback?`.
  Census battery EXTENDED with 11 window-host flows (inspector/console/errors-log/script/
  fridge-magnets/code-prompt/patch-node/fanout/axis/color-picker/toggle-button), 509 → ~1300
  targets. **A/B counterfactual** (`.scratch/staleness-census-neutralized.js` forces the 16
  declarations false in-page): declared = 0 movers; neutralized = 1 mover, ColorPickerWdgt —
  PROOF that conversion is load-bearing; the other 15 are mechanically-justified insurance.
  Mechanism note (WindowWdgt ~:630-676): Path-B'd deferred-layout contents get an explicit
  `_reLayout()` regardless of declaration; contents hit via the `_applyWidth`/`_applyHeight`
  branches (starting-height / `contentsRecursivelyCanSetHeightFreely`) are healed ONLY by the
  declaration — the basement's original staleness route, and ColorPicker's. Gates: build green
  (check-composite-relay accepted all 16), census 0 movers, gauntlet 9/9 byte-exact with ZERO
  recaptures, combined 3-round torture at close.
- **N4 (optional, bigger) — drop the capability gate from the B3 injection.** Watch ALL children,
  not just `_placesChildrenInLayout` ones: the engine would then guarantee EVERY arrange-moved child
  a re-lay, making declarations (and N3) moot for the settle path entirely. Cost: a per-re-lay
  snapshot of every child + extra idempotent re-lays; risk: any non-idempotent arrange anywhere
  becomes load-bearing (N2's class!) — so N2 must land FIRST, and an idempotence sweep (staleness
  census extended to force-re-lay EVERY widget class in place) is the prerequisite gate. Payoff:
  `_placesChildrenInLayout` shrinks back to a Stage-A-hook-only concern, simplifying B4.
  **✅ RESOLVED 2026-07-16 — executed post-B4 as the campaign closer; §11 is the execution log**
  (the injection watches every valid child; the valve gates on `children.length != 0`; the V1
  ScrollPanel seam gates on `implementsDeferredLayout` — the capstone falsified `children.length`
  THERE; the capability + guard + lint + markers are all deleted).
- **Standing protocol for all of the above** (§5, amended this arc): per-stage gate = `fg build` +
  `fg presuite` + 1-round torture; arc close = `fg gauntlet` + 3-round torture; equivalence oracle =
  per-test UNION relay-sets (never per-flush sequences); census for behaviour stages. Probes live in
  `Fizzygum-tests/.scratch/` (relayset-prelude/diff, stage-b-torture.sh, probe-basement-relay-trace,
  boot-spin-stack, staleness-census).

## §10 — Execution log: the B4 SCHEDULE-VALVE retirement arc (2026-07-16, same session as §9 N1–N3)

Staged V1→V4, each stage byte-exact-gated with the hook still live until V3 flipped the base.

### V1 — ScrollPanelWdgt absorption (its hook override dies; its _reLayout becomes self-sufficient)
- `_positionAndResizeChildren`: the two text-wrap width reads derive from `@width()` (the viewport),
  not `@contents.width()` — equal at the fixpoint, but only `@width()` is current mid-transient
  (the old hook's viewport pre-set existed to feed those reads).
- Stack branch: the arrange normalizes a WIDTH-CONSTRAINING stack's tracked width itself
  (`constrainContentWidth` gate — see the capstone falsification below). FOUND BY THE GATE: the
  first cut omitted the normalization entirely → `macroWindowCellsInConstrainedScrollStackReflow`
  failed deterministically; the second cut applied it UNGATED → the capstone gate caught a
  valve-schedule ping-pong on `macroFreeWidthScrollStackShowsHorizontalScrollbar` (a FREE-width
  stack OWNS its width; normalizing it re-grows every arrange and rides the end-of-cycle flush —
  4 careless pushes). Both cuts corrected; both tests pass.
- Commit seam: after the arrange's `_commitBounds` + `_reLayoutSelf()`, a DECLARED contents is
  scheduled through the phase-valve (ToolPanelWdgt's re-wrap relied on the retired hook's
  polymorphic chain — found statically; also covers the WindowWdgt early-settle route, where the
  engine's later idempotent re-visit shows the injection no frame delta).
- The contents-MOVE (reset-scroll-on-resize, wrapping non-stack panels) is RESIZE-EVENT behaviour,
  not arrange behaviour: moved to a small `_applyExtent` scroll-policy override (pin BEFORE super
  == the old post-commit pin; an extent commit never moves the origin). A settle re-lay at an
  unchanged frame must never touch the scroll position — an extent-delta gate inside _reLayout
  structurally cannot see an immediate resize (the extent is committed before entry).

### V2 — StretchableCanvasWdgt buffer relocation (its hook override dies)
- Buffer reconciliation moved to `_reLayoutSelf` — `_applyExtentBase` calls it on EVERY real extent
  commit, so it now also covers the bypass route the hook could not see (a small coverage FIX).
  Delta-guarded on the front buffer's physical size (the CanvasWdgt/BackBufferMixin dims idiom);
  the behind-the-scenes buffer (the user's PAINTING) is kept once painted, exactly as before.
  Sized from the COMMITTED extent (the RAW extent differs only under round/min-clamp, where
  buffer==frame is the correct invariant).

### V3 — the valve swap
- `Widget._applyExtent`'s composite branch: synchronous `_reLayoutMyChildrenAfterImmediateResize`
  → `_scheduleRelayoutRespectingPhase()`. The base hook method and the last override (the stack's
  terminal-_reLayoutChildren) DELETED. Mid-re-lay self-applies self-enqueue benignly (the entry is
  marked valid right after and dropped by the next sweep — verified live).
- rule [E] AMENDED in check-layering.js: the phase-valve is now banned in immediate mutators
  exactly like `_invalidateLayout`, with the ONE named sanctioned exemption = this valve line.
- **The retired hook had been MASKING two pre-existing arrange defects — both exposed by the
  gates, both diagnosed with the in-page OLD-SEMANTICS SHIM (`.scratch/old-valve-shim-prelude.js`
  restores the synchronous hook on the current build: a failing test that PASSES under the shim
  isolates hook timing as the cause), both fixed AT THE ARRANGE (the standing idempotence
  direction):**
  1. `SimpleVerticalStackPanelWdgt`: super's corner-internal tail placed the HANDLE OVERLAYS
     against the PRE-tight-hug frame; the hook used to land the hug early by accident (it ran the
     arrange inside super's self-extent-apply). FIX: base tail extracted as
     `_reLayoutCornerInternalChildren`; the stack's tail re-runs it after the hug. (A handle-place
     probe first ruled out a valve re-enqueue loop — the observed frame "creep" was one step per
     FLUSH: the drag gesture's pointer deceleration.)
  2. `ColorPickerWdgt` (census mover, feedback child off by half the size delta): its _reLayout
     CENTERED the feedback swatch from its STALE size, then resized it — per-pass non-idempotent,
     historically converged by the hook's extra synchronous passes
     (`.scratch/probe-colorpicker-valve.js`: a forced re-lay at the SAME frame moved the feedback).
     FIX: size first, centre from the new dims. Probe after: idempotent.
- `macroDuplicatedInspectorDrivesCopiedTargetOnly` failed mid-V3 and STILL failed under the shim ⇒
  not timing: the deleted base method removed one member-list line (the benign sub-row scroll churn
  class, in reverse). After the stack fix ADDED `_reLayoutCornerInternalChildren`, the count
  restored and the recapture came back BYTE-IDENTICAL — **zero reference changes for the arc**.

### V4 — arc close oracles
- **Relayset A/B vs the pre-arc build `5afc9bef`** (shared clone + symlinked siblings — never
  `git stash`; before-trace under the documented `FIZZYGUM_ALLOW_STALE_BUILD=1` override):
  per-test re-laid-SET **UNION IDENTICAL 250/250, zero subset violations, zero extras** — the
  valve re-lays exactly the same widgets, at engine-scheduled moments
  (`.scratch/relayset-subset-check.py`).
- Census 0 movers / 1310 (after the picker fix); **the neutralized-declarations counterfactual now
  breaks 15 window-host flows (vs 1 pre-arc)** — the declared capability is fully load-bearing:
  the engine is the sole healer of composite interiors on every route (walk, injection, valve).
- Suite byte-exact dpr1/dpr2/webkit; presuite green per stage; 1-round torture per stage.
- Final (post free-width fix): gauntlet 9/9 incl. the capstone leg (its careless-push audit is what
  caught the free-width ping-pong); 3-round danger-config torture 12/12; census 0 movers / 1310;
  neutralized A/B 14 movers across 13 classes; relayset UNION IDENTICAL 250/250 vs `5afc9bef`,
  0 subset violations, 0 extras.

### What died / what stays
- DIED: `_reLayoutMyChildrenAfterImmediateResize` (base + 3 overrides) — the synchronous composite
  re-lay mechanism, Stage A's hook.
- STAYS *(as of this arc's close)*: `_placesChildrenInLayout` + check-composite-relay.js +
  `_compositeChildrenBuilt` — they now gate the valve and the B3 injection. N4 (drop the
  injection's capability gate → delete the capability + lint + the 5 remaining markers) is the
  remaining §9 item; under the valve the census/A-B is a per-class idempotence detector, which is
  exactly N4's prerequisite instrument. **(N4 executed later the same day — §11. None of these
  survive it.)**

## §11 — Execution log: N4, the capability deletion (2026-07-16, the campaign closer)

The last §9 item: the settle engine's child re-lay is now UNGATED and the whole declaration
mechanism is DELETED — `_placesChildrenInLayout` (base + 26 declarations),
`_compositeChildrenBuilt` (base + 6 ctor guards), the 5 remaining
`immediate-resize-relay-exempt` markers, and `buildSystem/check-composite-relay.js` + its
`build_it_please.sh` wiring. One engine, one healing mechanism, zero capability declarations,
zero markers, one lint fewer. 38 files, +60/−515.

### Design — decided on a firing profile, not on theory
Three sites referenced the capability: (a) the B3 injection's watched-children filter
(`WorldWdgt.__reLayoutOneSettleNode`), (b) the schedule-valve's composite branch
(`Widget._applyExtent`), (c) the V1 ScrollPanel declared-contents schedule. A
ZERO-BEHAVIOR-CHANGE counting prelude (`.scratch/n4-firing-probe-prelude.js`, aggregated by
`.scratch/n4-profile-report.js`) measured, on the pre-N4 build over the full 250-test dpr1
suite, what each candidate replacement would fire on:

- INJECTION, watch-ALL: 17,112 settle-node re-lays snapshot 28,736 children (~1.7/node —
  trivial); watch-ALL adds ~6,800 re-lays/suite (~27/test), almost all LEAVES whose re-visit
  is a PROVABLE no-op (a VALID child has no pending desired*, so a no-arg `_reLayout` re-lays
  at the CURRENT frame and the equal-extent top guard eats it). The theorized CaretWdgt hazard
  (its `_reLayout` carries scroll-follow side effects) measured ZERO occurrences. Bonus: the
  profile surfaced real UNDECLARED composites arrange-moved with children (SliderWdgt 420,
  PanelWdgt 412, SpreadsheetWdgt 13, PatchProgrammingWdgt 10…) that now get the guarantee.
- VALVE, structural gate (`@children.length != 0`): +1,360 schedules/suite, only 31
  bare-off-pass — near-today flush composition.
- VALVE, ungated: +12,000 MORE schedules, 2,287 bare-off-pass — dominated by orphan ctor flows
  (SpreadsheetWdgt grid cells 924, menu separator RectangleWdgts 880) and CaretWdgt 142 (raw
  `_applyHeight` in editing events). A childless widget's COMPLETE heal is `_reLayoutSelf`,
  which `_applyExtentBase` fires on every real commit — so ungated buys zero healing, and its
  only marginal coverage (the caret) is its only concrete risk.

DECISION: injection watch-ALL (every VALID child; the `layoutIsValid` filter stays — a
pending-desired widget is invalid, so a forced no-arg re-lay can never fight the arrange);
valve gates on `@children.length != 0`. The owner-pre-flagged fork (structural vs none)
dissolved under measurement — structural dominates on every axis but "philosophical
uniformity".

### FALSIFIED FIRST CUT — the V1 seam gate must be `implementsDeferredLayout`, NOT `children.length`
The first gauntlet's CAPSTONE leg (the valve's watchdog, catching its second falsification
this campaign) failed with 34 careless end-of-cycle pushes across 10 scroll tests, every one a
PanelWdgt + ScrollPanelWdgt/ListWdgt PAIR (the climbing `_invalidateLayout` signature). Stack
capture (`.scratch/n4-eoc-stack-prelude.js` — the production careless gate wrapped onto
`_invalidateLayout`, emitting over the LAYOUTAUDIT rails) attributed 100% of them to the V1
commit seam in `_positionAndResizeChildren`, which is reached OFF-SETTLE by two sanctioned
synchronous callers — the public content-change endpoints (`add`/`addMany` →
`_reLayoutChildren`) and the drag-to-scroll `step` function. The old declared gate was inert
for the plain-PanelWdgt contents of every ordinary scroll panel; `children.length` made every
such call push the contents onto the end-of-cycle flush. All suite legs stayed byte-exact (the
flush heals before paint) — ONLY the capstone saw it. FIX at the seam: gate on
`@contents.implementsDeferredLayout()` — schedule only a contents whose CLASS has its own
arrange (ToolPanelWdgt, stacks); a base-`_reLayout` contents gets nothing from a full re-lay
beyond the `_reLayoutSelf` the commit already fired, and its settle path is covered by the
watch-ALL injection. (Non-seam enqueue residue checked: only the caret's sanctioned in-event
`_requestScrollFollow` — drained by `_settleScrollFollow`, never rides the flush — and 6
pre-existing TTF `_addNoSettle` cases.) The after-side relayset trace was REDONE on the fixed
build.

### Why the six `_compositeChildrenBuilt` guards die with the capability
All six (WidgetHolderWithCaption, ColorPicker, GenericCompositeIcon abstract-false,
GenericShortcutIcon, GenericObjectIcon, PlotWithAxes) protected the same scenario: the OLD
SYNCHRONOUS hook running mid-ctor with children missing. Under the schedule-valve that is
STRUCTURALLY impossible: builders run inside a settle window (or pre-world), a nested public
setter on an under-construction ORPHAN defers rather than flushes, so a scheduled re-lay can
only run at the window-closing flush — after the builder completed and every child exists.
Belt-and-braces: every verified builder `_applyExtent`s its placeholder BEFORE the first child
add (WidgetHolder / ColorPicker / ShortcutIcon / ObjectIcon checked in-tree), so the
structural valve gate is inert at that moment anyway; PlotWithAxes never placeholder-applies
in its own builder at all (its guard covered the mixin's Path-B applies — in-pass, benign
self-enqueue).

### What changed (the whole edit set)
- `WorldWdgt.__reLayoutOneSettleNode`: watch filter `c._placesChildrenInLayout?() and
  c.layoutIsValid` → `c.layoutIsValid`.
- `Widget._applyExtent`: `if @_placesChildrenInLayout() and @_compositeChildrenBuilt()` →
  `if @children.length != 0`; base `_placesChildrenInLayout` + `_compositeChildrenBuilt`
  DELETED; the valve comment rewritten (structural rationale + profile numbers).
- `ScrollPanelWdgt._positionAndResizeChildren` commit seam: `if
  @contents._placesChildrenInLayout()` → `if @contents.implementsDeferredLayout()` (see the
  falsification above).
- 26 class declarations + their §9-N3/INV-2 rationale blocks deleted (script-swept, git-diff
  reviewed); 6 `_compositeChildrenBuilt` overrides deleted; 5 exempt marker lines deleted
  (Caret, LabelButton, VideoControlsPane, VideoPlayer, TTF — TTF's own `_applyExtent` override
  IS still its mechanism and stays).
- `check-composite-relay.js` deleted + its `build_it_please.sh` wiring block; rule [E]'s named
  `Widget._applyExtent` exemption in check-layering.js unchanged (it keys on class+method, not
  the gate).

### Gates (all on the final build unless noted)
- build green (syntax + layering 0 violations; the composite-relay gate is gone).
- presuite: dpr1 250/250 + paint audit PASS after ONE benign recapture —
  `macroDuplicatedInspectorDrivesCopiedTargetOnly` (the SAME test that caught V3's base-method
  count change): net −2 base methods shift the inspector member-list scroll anchored at the
  macro's `alpha` click; diff-page verified the semantic content identical (alpha 0.25/0.6,
  ref == act), only the list offset moved. 4 screenshots recaptured (img2/img3 × dpr1/dpr2).
- staleness census: 0 movers / 1310; **battery gap found and fixed** — the census's
  'SlidesApp' entry never resolved (`no such class`, silently skipped), so slides flows were
  uncovered; now opens `SimpleSlideApp` + `SampleSlideApp` (1310 → 1506 targets incl. the
  visible slide-maker tool palette, opened AND resized): **0 movers / 1506** re-stamped on the
  final build.
- relayset A/B vs `a7d8fdf4` (shared clone, FIZZYGUM_ALLOW_STALE_BUILD=1 before-trace; the
  before leg fails the one recaptured inspector test by construction — harmless, the audit
  rides failures): 250 tests, 865 extra re-laid ids (the expected watch-ALL adds), and ONE
  residual subset "violation" — `MenuItemWdgt#514/#515` in the recaptured inspector test are
  widgets that DON'T EXIST post-N4 (the deleted base methods' own member-list rows; the new
  run's MenuItemWdgt counter tops out exactly 2 lower). Check instance-counter tops before
  suspecting a lost heal. (An earlier `ToolPanelWdgt#1` violation was the `children.length`
  seam cut and disappeared with the `implementsDeferredLayout` fix.)
- gauntlet 9/9 — dpr1/dpr2/webkit/apps/paint/tiernaming/settle/CAPSTONE/refs all PASS.
- danger-config torture: 1-round per stage green; 3-round at close 12/12 green.
- OPS trap found on the way: the raw `build_it_please.sh` ABORTS but EXITS 0 when the umbrella
  directory is not literally named `Fizzygum-all` — the first baseline clone at
  `/tmp/n4-baseline/Fizzygum` "built" green while writing NOTHING, and the before-trace
  silently ran against the NEW build (a vacuous A/B — caught because the expected 1-test
  failure was missing and `latest/index.html`'s mtime hadn't moved). The clone umbrella must
  be `<anything>/Fizzygum-all/Fizzygum`; ALWAYS verify the baseline artifact (mtime + a
  deleted-symbol grep) before the before-trace.
- Instruments retired: `.scratch/staleness-census-neutralized.js` (it forced declarations that
  no longer exist — the counterfactual is now meaningless; the census itself IS the
  idempotence sweep).
