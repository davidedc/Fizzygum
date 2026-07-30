# archive/INDEX.md — ledger of archived docs

One entry per archived doc: status, what it was, and the case law worth
citing before re-attempting anything it rejected. Stamped 2026-07-17.
Archived docs are immutable history — the current-state truth lives in
`docs/architecture/`; open work is indexed in `docs/BACKLOG.md`.

## Layout & settle campaigns

- **`all-constructors-settle-plan.md`** — COMPLETE. Converts ~27 inline-building constructors to the uniform self-settling _buildAndConnectChildren wrapper/core pattern.
  - ⚖ notification-settle gate refined to permit orphan-receiver settle in a callback, not weakened
  - ⚖ ScrollPanelWdgt needed a DISTINCT _buildScrollFrame name, not the shared leaf core name
- **`basement-dormant-layout-flag-plan.md`** — PARKED. Proposes a cached per-widget flag to skip layout-invalidations for widgets sitting in the CLOSED (dormant, off-world) basement.
  - ⚖ §4 — blanket orphan-skip REJECTED, previously broke 63 tests
  - ⚖ §6 — safer seam-by-seam alternative to weigh before building the flag
- **`caret-follow-in-place-settle-plan.md`** — PARKED. Proposes folding the caret's typing/delete scroll-follow into an in-place per-event settle instead of the end-of-cycle flush.
  - ⚖ purity refinement only — if not byte-exact with reasonable effort, LEAVE the status quo
  - ⚖ caret must NOT coalesce (a past coalesce-the-caret attempt was wrong, corrected)
- **`caret-scroll-follow-single-pass-plan.md`** — COMPLETE. Makes the caret's scroll-into-view converge in a single settle pass instead of re-visiting the layout loop up to 372 times.
  - ⚖ §4.3 internal-loop fallback NOT needed — §4.1+§4.2 alone reached zero re-visits
  - ⚖ Point.floor() clamp-to-≥0 was the root cause of the multi-pass crawl
- **`claimsspace-footprint-default-and-scroll-reachability-plan.md`** — COMPLETE. Makes 'footprint' the default claimsSpace mode and makes scroll extent track ink reachability in every mode (owner decisions D1+D2).
  - ⚖ shrink-to-fit stays FORBIDDEN (D3 — cyclic-constraint / LivelyKernel precedent)
  - ⚖ claimsSpace gates ASKING containers only, never DICTATING _applyExtent (owner correction)
  - ⚖ CSS-like-scroll-without-default-flip and slot-default-with-opt-in both SUPERSEDED by D1+D2
- **`coalesced-nomenclature-rename-plan.md`** — COMPLETE. Renames the layout deferred-settle family off the ambiguous word 'coalesced' before the dataflow-engine work begins.
  - ⚖ *EndOfCycle and *Streamed suffixes REJECTED as naming candidates
  - ⚖ the menu-takeover homonym (takesOverAndCoalescesChildrensMenus) is unrelated, handled separately
- **`connection-cascade-settle-fix-plan.md`** — COMPLETE. Adds a dedicated 'connector' settle-lane so reactive wiring cascades (e.g. the C↔F converter) settle once instead of throwing.
  - ⚖ rejected: relax setText's flow guard generally — would hide genuine internal-layout misuse
  - ⚖ rejected: dispatch the cascade to the raw _setTextNoSettle core — no cycle-guard, infinite-loop risk
  - ⚖ rejected: deferred/queued propagation — breaks the circuits' synchronous semantics
- **`deferred-layout-16-macro-breakages.md`** — COMPLETE. Catalogues 16 construction-macro breakages under the first deferred-geometry API and root-causes each one.
  - ⚖ the eventual fix was NOT either weighed option — a 3rd approach (self-settling setters) shipped instead
  - ⚖ M4 — slider thumb positioned from a stale parent origin (settle-before-add or framework fix)
- **`deferred-layout-OVERVIEW.md`** — COMPLETE. Former entry point for the deferred-layout campaign; its durable content was merged into the architecture assessment doc.
  - ⚖ its own §3 'deferred re-queue is the mechanism' framing was later OVERTURNED by the 2026-07-01 seam deletion
- **`deferred-layout-c2-execution-plan.md`** — COMPLETE. Converges the container re-fit cascade in-pass via a deferred re-queue instead of a synchronous re-fire.
  - ⚖ naive no-op seam removal broke 7 tests across 3 families — not a viable path
  - ⚖ the scroll/REACT arm breaks INDEPENDENTLY of the clock — a clock-only fix could never enable C3
- **`deferred-layout-capstone-execution-plan.md`** — COMPLETE. Retires the world._reFittingContents counter and tightens layering lint [E] to close the deferred-layout campaign.
  - ⚖ blanket wEl/wStk deletion and lazy GET-time capture BOTH falsified — a surgical elasticity-0 fix used instead
  - ⚖ forbidding _reLayoutChildren by name DECLINED as cosmetic, no real added protection
- **`deferred-layout-path-a-design.md`** — COMPLETE. Records why blanket 'pending-aware geometry accessors' diverges, and the per-reader taxonomy that replaced it.
  - ⚖ blanket pending-aware conversion made failures WORSE (16→17→18), regressed 3 previously-green tests
  - ⚖ a pending read over-sizes scroll content by 43px — proven wrong, not merely different
- **`deferred-layout-refit-and-add-design.md`** — COMPLETE. Design for the _reLayoutChildren re-fit chokepoint and a public self-settling add/addRaw over a private _addCore.
  - ⚖ construction-time settles are NOT byte-safe idempotent — half-built widgets reachable via .parent, fixed via isOrphan() skip
  - ⚖ giving stack/window panels the scroll-panel's _reLayout pattern directly HANGS — not a quadratic-add bug
- **`deferred-layout-residuals-audit.md`** — COMPLETE. Read-only audit mapping every synchronous relayout still at a non-settle point across the deferred-layout campaign.
  - ⚖ families 1 (scroll-input) / 6 (Slider) / 7 (LabelButton): verdict LEAVE SYNCHRONOUS, wrong problem class or no gain
  - ⚖ soft-wrap caret-follow deferral PROBED and REJECTED — broke 7 scroll-follow tests
- **`deferred-layout-slice2-completion-plan.md`** — COMPLETE. State record after Phase 3b of the deferred-layout migration; documents the FLOW RULE that raw setters never schedule layout.
  - ⚖ FLOW RULE violation froze 9/12 desktop apps — a raw/silent mutator must only mutate, never schedule
  - ⚖ createErrorConsole recovery must run OUTSIDE the flush, not inline in the recalc catch
- **`freefloating-invalidation-skip-centralization-plan.md`** — COMPLETE. Consolidates the ATTACHEDAS_FREEFLOATING teardown invalidation-skip into one Widget.invalidateLayout(triggeringChild) parameter across all 5 propagation sites.
  - ⚖ widening sweep found NO further safe skip targets — surface fully captured
- **`hover-resync-after-flush-plan.md`** — COMPLETE. Swaps hover re-sync to run after the coalesced end-of-cycle flush so hover reads settled geometry, matching what paint reads.
  - ⚖ capstone gate exited 0 on a crashing/failing suite — fixed to also fail on suite runner exit != 0
- **`layout-optimizations-and-oo-cleanup-plan.md`** — COMPLETE. Post-seam-deletion layout engine optimization + OO-cleanup campaign across Tiers A-J: dedup, geometry-cache versions, wart hunts, bounds-cache.
  - ⚖ Appendix X1-X9 bank every considered-and-rejected idea — do not re-derive
  - ⚖ layoutEngine-object encapsulation — RULED OUT by owner
- **`layout-regressions-2026-07-icons-plots-editghosts-plan.md`** — COMPLETE. Bisect-rooted fix plan for 4 layout regressions (desktop icons, plot collapse, edit/view ghosts, slide scroll drift), plus a paint-truthfulness capstone gate.
  - ⚖ Plot 'content-latency' ghost was NOT a bug — intended live animation, proven by freeze test
  - ⚖ Layering rule [D] blocks a dropped-invalidation macro even inside evaluateString strings
- **`layout-settle-tier-rename-plan.md`** — COMPLETE. Renames the layout-settle tier to private, layout-explicit names (mutateGeometryThenSettle to _settleLayoutsAfter, *Core to *NoSettle).
  - ⚖ check-layering.js hard-codes tier names by string — must update in lockstep
- **`layout-system-architecture-assessment.md`** — COMPLETE. Canonical description of Fizzygum's layout engine + the rulebook for introducing a new layout; absorbed the former deferred-layout overview doc.
  - ⚖ §4.3 layoutEngine-object encapsulation — RULED OUT (bury-it-deeper)
  - ⚖ §4.2 per-axis DAG lint — falsified as a convergence proof
- **`ordered-downwalk-stage-b-plan.md`** — COMPLETE. Builds the ordered root-down settle walk as an engine upgrade, deleting the last per-class composite-relay capability declarations.
  - ⚖ §2 — settled layout is order-independent; acceptance = re-lay SET trace not order
  - ⚖ OPS trap — build_it_please.sh aborts but exits 0 if umbrella misnamed
- **`orphan-settledness-plan.md`** — COMPLETE. Closes the I2-on-orphans settledness gap so public calls and constructors on orphan widgets settle synchronously via cores.
  - ⚖ @add→@_addNoSettle byte-identical only for standard Widget.add, not custom-add bases
  - ⚖ Constructors now DO settle via auto-deferring wrapper, superseding original framing
- **`paint-time-caret-resync-plan.md`** — COMPLETE. Plan to move the caret's paint-time layout re-sync out of the read-only paint pass, per the owner's events-flush-paint invariant.
  - ⚖ Owner rejected a 3rd _settleLayoutsAfter variant and try/finally flag toggles
  - ⚖ Clean/elegant code prioritized over dodging a benign inspector recapture
- **`private-noLayouting-core-callpaths-plan.md`** — COMPLETE (residual in BACKLOG.md). Gives every public layout-settling method a private NoLayouting core so private teardown/build chains never re-enter the public settle tier.
  - ⚖ _addCore/_addRawCore split byte-identical only because callers add fresh non-world children
  - ⚖ Orphan-guard must precede flow-throw so orphan construction under a flush defers
- **`proper-layouts-4.1-pure-measure-campaign-plan.md`** — COMPLETE. Builds the pure preferredExtentForWidth measure protocol (text, stack, window, scroll-panel) to delete the mutate-then-read-back sizing seam.
  - ⚖ Stage-D's 6 mismatches were deferred-relayout convergence lag, not bugs (Stage-E boundary)
  - ⚖ Measure, don't mutate-and-read-back — a 'measure' touching @bounds has failed
- **`proper-layouts-4.2-structural-arrange-plan.md`** — COMPLETE. Attempts a single-pass measure-up/non-notifying-arrange-down restructure to delete the re-fit seam; Stage 4's structural edge falsified, closed via the 4.4 arc.
  - ⚖ Option B scroll choke-points FALSIFIED — real edge is content's own base _reLayout
  - ⚖ By-PHASE split FALSIFIED — 6 of 10 job-B tests need in-pass firing
  - ⚖ world.layoutEngine relocation REJECTED — burying the boolean deeper, not deleting it
- **`proper-layouts-4.4-ordered-downwalk-plan.md`** — COMPLETE. Original down-walk-as-seam-replacement design; all seam-deletion paths falsified — the walk was later rebuilt as a pure engine upgrade elsewhere.
  - ⚖ Analytic position-frame decoupling FALSIFIED — container arrange already idempotent, iterating is a no-op
  - ⚖ Do-NOT-reattempt list: non-notifying conversion, sync in-arrange fixpoint, boundingBox() read-back drop
- **`proper-layouts-eliminate-suppression-booleans-plan.md`** — COMPLETE. Roadmap (Phases A-F) to delete Fizzygum's layout-suppression booleans; deletes @_adjustingContentsBounds narrowly, later fully completed elsewhere.
  - ⚖ Full seam deletion REVERTED — broke 8 tests, scroll 'careless' pushes ARE convergence
  - ⚖ Find WHICH non-idempotency perpetuates a cycle before fixing all of them
- **`proper-layouts-geometry-seam-removal-plan.md`** — COMPLETE. Removes the last geometry re-fit sub-seam via a settle-time ordered re-fit, proving the earlier 'irreducible' verdict over-general.
  - ⚖ Prior 'irreducible' verdict proven over-general 3x — don't over-generalize from failed stages
  - ⚖ Do NOT re-run the 8 already-falsified paths (§2); start from fresh angles
- **`retire-adjustingContentsBounds-via-text-measure-plan.md`** — COMPLETE. Investigates retiring @_adjustingContentsBounds via a pure text-height measure; the keystone premise (a height read-back) is false.
  - ⚖ measureWrappedHeight targeted the wrong read — real driver is in-pass contents positioning
  - ⚖ 'Silent' setters still fire the re-fit seam — only the flag suppresses it
- **`settle-tier-followups-examination-plan.md`** — COMPLETE (residual in BACKLOG.md). Post-orphan-settledness examination across 5 topics: determinism flake, lint symmetry, NoSettle naming audit, constructor settling, allowlist sanitization.
  - ⚖ Topic 1 'flake' was a false stall-timeout keyed off wall-clock, not a pixel bug
  - ⚖ Owner wants exemption markers/allowlists re-tested against today's code, not left standing
- **`sizing-model-unification-plan.md`** — COMPLETE. Unifies Fizzygum's two sizing philosophies into ONE constraint-box model, deleting the proportional formula and last convergence residuals.
  - ⚖ Owner mid-arc: no serialization compat exists, so large behaviour changes were sanctioned
  - ⚖ Window drop-mounts content TWICE, re-arming a captured spec — fixed via remount detection
- **`softwrap-deferred-layout-conversion-plan.md`** — COMPLETE. Investigates converting soft-wrap and sibling handlers to deferred layout; concludes the whole family should stay synchronous, no code change.
  - ⚖ Path A pending-aware accessors FALSIFIED — one accessor can't serve pending and applied readers
  - ⚖ C2/C3 'unachievable' conclusions SUPERSEDED once the deferred re-queue mechanism shipped
- **`unify-layout-enqueue-primitives-plan.md`** — COMPLETE. Extracts the caret's open-coded bare layout-enqueue push into one named primitive, folded into _invalidateLayout via a state-derived branch.
  - ⚖ Purity/layering refinement, not a correctness fix — status quo was already byte-exact
  - ⚖ If lint fights back or torture finds non-convergence, leave the status quo
- **`upedge-endgame-plan.md`** — COMPLETE. Examines the 8 baseline settle re-visit flushes plus the last convergence-shaped boolean after sizing-model unification; converts 7, exposes 1 false positive.
  - ⚖ fg revisits + fg census promoted to standing gauntlet legs — empty baseline means any revisit is a regression
  - ⚖ Two falsified fix shapes on one target = STOP and document, not a third attempt
- **`window-content-negotiation-residual-plan.md`** — COMPLETE. Final proper-layouts residual: fixes window-over-stack re-visit waste; the 3 nested-window re-visits proven irreducible one-time construction costs.
  - ⚖ General 'non-freefloating content skips climb-enqueue' rule FALSIFIED — broke 9 tests
  - ⚖ Nested-window residual irreducible 3 ways: can't measure ahead, settle early, or reorder

## Transforms & geometry

- **`affine-geometry-api-plan.md`** — COMPLETE. Two-vocabulary geometry API (layout-box vs screen) for transformed widgets: TransformSpec.mapRectExact plus 5 Widget accessor methods.
  - ⚖ §1.3 — inspector 'honesty' row EXCLUDED by owner, record only
  - ⚖ §1.3 — screenQuad/inverse-maps DEFERRED, no real consumer yet
  - ⚖ §1.2 — island's internal two-faces methods stay internal, not public API
- **`drop-into-rotated-container-layout-transparency-plan.md`** — COMPLETE. Root-causes and fixes widgets dropped into a rotated/tilted container not stretching on resize (island layout-transparency).
  - ⚖ §3c content-forwarding hook DEFERRED — risked firing geometry-changing overrides, not needed for the headline fix
  - ⚖ F1 — an arrange-driven re-fit must NIL the pinned anchor, not Bug-G-normalize (locked choice)
- **`duplication-and-save-preserve-transforms-plan.md`** — COMPLETE. Root-cause + fix plan making widget duplication and per-widget save preserve affine transforms via the enclosing TransformFrameWdgt island.
  - ⚖ file status header never updated post-execution
- **`fractional-widget-bounds-investigation-plan.md`** — COMPLETE. Investigates and resolves fractional widget @bounds: rounds each arrange producer and adds a permanent NON_INTEGER_GEOMETRY hard gate.
  - ⚖ divider-drag reproportion is sub-pixel-sensitive — rounding shifts it 37-57px, not a bug
- **`widget-identity-decoupling-plan.md`** — COMPLETE. Widget-scoped true-polymorphism plan to stop Widget interrogating subclass identity; absorbed into the codebase-wide type-test-elimination-plan.md.
  - ⚖ 5c mechanical instanceof→isX?() sweep reverted — cosmetically better, not actually different
  - ⚖ Adding methods to common base classes is inspector-safe — zero recapture

## Rendering & performance

- **`resetworld-teardown-completeness-audit-plan.md`** — COMPLETE (2026-07-29). Audits `WorldWdgt._resetWorldNoSettle` for completeness after two field-caught leaks of the same shape in three weeks (`widgetsToBeHighlighted` 2026-07-10, `UntitledNamingService` counters 2026-07-28). 26 rows inventoried and decided; **14 further leaks found and fixed**. Delivers the structural guard `_auditWorldResetCompletenessNoSettle` → the `RESETWORLD_INCOMPLETE` token, gated by both headless runners, with the allow-list `WorldWdgt._worldStateAuditExemptions` (every exception carries its reason). §7.5 is the execution record. Durable case law: `Fizzygum-tests/DETERMINISM.md` §2d.
  - ⚖ reactive patching had left an ORDER OF MAGNITUDE more holes than the two caught instances implied — when a bug shape recurs, audit the whole surface instead of fixing the new instance. The worst rows were ones nobody had noticed: `numberOfIconsOnDesktop` (the desktop grid cursor — moves later tests' icons, a pure GEOMETRY leak), the world's own EXTENT, `errorConsole` (a dangling console makes every later paint error report into a dead widget, silently swallowing what the fail-gate exists to catch), `wdgtsWithOngoingScrollMomentum` (dead ref ⇒ `anyScrollMomentumOngoing()` true forever ⇒ later tests STALL rather than fail)
  - ⚖ a state-fingerprint guard must compare VALUES, never own-ness: a first cut swept own properties and fired 1469 times on a GREEN suite, because a prototype-declared field the teardown merely ASSIGNS (`@x = nil`) reads as `(absent) → nil`
  - ⚠⚠ prove a guard FAILS, don't just observe it silent — planting one leaking FIELD (not a no-op) made the suite fail 188 tests; only then is silence evidence
  - ⚠ the guard is LOAD-SENSITIVE for per-frame fields and ONLY the PARALLEL gauntlet showed it (the `settle`/`storage` legs warned in-wave, passed serially): a teardown is not a frame boundary, so Widget-level damage bookkeeping on the world reflects where in the cycle it landed. Validate such a guard under the parallel gate, not only the quiet inner loop
  - ⚖ §2's serializer oracle was a floor, not a ceiling exactly as written: it named the app-slot/`infoDoc*`/prefs rows, but the two worst finds are not serialized, so only the direct class sweep could reach them
  - ⛔ the PRODUCT twin `_teardownForSnapshotLoadNoSettle` has the same dangling-ref gaps — evidenced, deliberately NOT changed here (ships in `--homepage`; wanted owner sign-off + serialization round-trip). CLOSED the next day by `teardown-shared-core-plan.md` below, which deleted the twin outright
- **`teardown-shared-core-plan.md`** — COMPLETE (2026-07-29). Successor to the audit above, closing the reverse direction and then removing the ability to have a direction: the "drop every reference to what was just destroyed" half of both world teardowns becomes ONE **shipping** core, `WorldWdgt._teardownWorldStructureNoSettle`, that `_resetWorldNoSettle` (test, homepage-stripped) and `loadWorldSnapshot` (product) both call. The product twin `_teardownForSnapshotLoadNoSettle` was DELETED — all five of its lines were in the core — and `_resetWorldNoSettle` shrank 42 → 19 code lines. Fixes measured PRODUCT bugs on the snapshot path. New gate: six `world.teardownHygiene.*` checks in `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` (both backends, the gauntlet's `serialization` leg). Durable residue: `Fizzygum/CLAUDE.md` Testing, `docs/architecture/serialization-duplication-reference.md` §11 step 2, `Fizzygum-tests/DETERMINISM.md` §2d.
  - ⚖ **the seam was never product-vs-test.** Only the *pristine-LOOK* half is (grey desktop, wallpaper, world extent, page scroll); the *dangling-reference* half is an obligation `fullDestroyChildren()` creates for whoever calls it, and neither caller's name claimed it — which is exactly why it kept being satisfied on one path and forgotten on the other. Believing the "product vs test" story is what kept two twins hand-synchronised through two drifts in two days, in OPPOSITE directions
  - ⚖ measure the split before moving code: a ~20-minute Phase 0 spike (dirty a field → load a snapshot saved BEFORE it existed → read it back) confirmed all 19 leak rows AND all six "not a leak" rows, so no row moved on an argument. It also found one nobody predicted — a stale highlight declaration makes the reconciler RE-MATERIALISE a `HighlighterWdgt` onto a restored desktop, so a load can produce a widget the file does not contain
  - ⚠⚠ **check the `»>>` strip markers around a FIELD's DECLARATION before moving its line into shipping code, not just around the line you are moving.** §4 called "the 6 highlight/pinout sets" one shared row; the three PINOUT sets are declared inside homepage-exclusion markers, so a shipping core clearing them would have thrown on the first snapshot load in a production build. They stay test-side — the strip boundary draws the seam, not a judgement call
  - ⚠ an assertion that can pass while broken is worse than none: the gate's first "no resurrected overlay" check (child-count equality) fired on one page and not another, because `addHighlightingWidgets` only re-parents the destroyed overlay when the dead target reports changed paint bounds. Replaced by a true invariant (nothing DESTROYED back in `world.children`), documented in-place as NOT forced by the fixture — the real highlight coverage is the collections check, which does fire
  - ⚖ writing the falsification probe paid for itself twice: besides proving the gate fails, it exposed a `Map` member-extraction bug in the check itself (`widgetsToBeHighlighted` maps target→style, so `.values()` never sees the dead target)
  - ⛔ `RESETWORLD_INCOMPLETE` was deliberately NOT extended to the load path: its baseline is *the pristine world*, and a snapshot load installs new state, so it would need a second baseline + its own exemption list to say what six named rig assertions say directly. The core is not under-guarded — the suite ratchet covers it through `resetWorld` on all 268 tests, the rig through `loadWorldSnapshot`
- **`suite-nondeterminism-flakes-plan.md`** — COMPLETE (2026-07-29). Investigation record for the three non-boot SystemTest flakes: A `macroClosingRotatedIslandChildClearsFootprint` (a glyph atlas warming BETWEEN the macro's two pixel reads — 7798px, text-shaped; the framework's invalidation was correct), B the serialization rigs' BISTABLE `pixelParity` (a half-warm atlas render is STABLE, and `anyTextDirty()` was under-reporting), C `macroSaveAsPromptAboveTiltedWindow` 100% at `--shards=1` (`UntitledNamingService` counters surviving `resetWorld`). Durable case law: `Fizzygum-tests/DETERMINISM.md` §3g/§3h/§3i.
  - ⚖ a green from an instrument you have NOT seen reproduce the failure is not evidence of absence (a state-leak hypothesis was wrongly "falsified" by a runner that cannot reproduce the bug)
- **`atlas-delay-fuzz-tool-plan.md`** — EXECUTED (2026-07-29). Built `fg fuzz` (`Fizzygum-tests/scripts/run-atlas-fuzz.js` + `audit-preludes/atlas-delay-prelude.js`): delays every SWCanvas glyph-atlas load by a seeded-random 0..250 ms and runs the suite + BOTH serialization rigs, to find pixel reads not covered by the text-settle gate. ON-DEMAND ONLY — ⛔ not a gate, not a gauntlet leg (owner-declined; nondeterministic by construction). Plan §9 is the execution record.
  - ⚖ a fault injector must PROVE it injected before it may say PASS — three verdicts (PASS/FAIL/**INVALID**, exit 0/1/**2**), never two. The prototype produced four invalid runs in one morning, three printed `failed: 0`, and a no-op injector reporting 268/268 certifies coverage that was never tested. Pinned by a 31-case canned-transcript corpus in `npm run selftest`.
  - ⚖ a BIGGER fault dose is NOT more sensitive: the §3i window is ~one frame, so too large a delay lands the atlas after BOTH reads and the diff returns to 0. Measured — the reverted flake-A fixture passed 13/13 under injection AND 3/3 with none.
  - ⚠ `LAYOUTAUDIT installed` contains the substring "stall", so it matched `run-all-headless.js`'s `/STALL/i` relay and printed twice per shard — which reads exactly like a double-wrapped injector, i.e. a silently doubled dose.
  - ⚖ match the CADENCE you are investigating, or you measure a different system (an over-settling probe nearly read as a refutation)
  - ⚖ read `gen` (`immutableBackBufferGeneration`) BEFORE the pixel magnitude — a large diff is NOT evidence of a real dropped invalidation
  - ⚖ shard count is a PREDECESSOR-SET axis, not a load axis; no standing gate runs 1 shard, and an s1 leg is owner-DECLINED on cost
- **`end-of-cycle-flush-drawdown-plan.md`** — COMPLETE. Case-study playbooks, code patterns, and verification protocol for converting/eliminating end-of-cycle layout-flush contributors one at a time.
  - ⚖ §7 snapshot STALE — superseded by flush-inventory §4
- **`end-of-cycle-flush-endgame-plan.md`** — COMPLETE. Endgame plan driving the end-of-cycle careless set to zero via CONVERT/ELIMINATE/DECLARED-COALESCED, then shipping the audit-fail capstone gate.
- **`end-of-cycle-flush-final-records-plan.md`** — COMPLETE. Plan driving the last 5 careless end-of-cycle records to zero (handle-construction, buildOverflow, scroll-factory groups) and shipping the capstone.
- **`end-of-cycle-flush-inventory.md`** — COMPLETE. Survey report + executed self-settle conversion history for the end-of-cycle layout flush; the campaign's binding record of results.
  - ⚖ paint-time caret re-sync flagged as latent — later found inert
- **`end-of-cycle-flush-survey-plan.md`** — COMPLETE. Original cold-executable design for surveying what reaches the end-of-cycle layout flush and whether it should self-settle.
- **`end-of-cycle-self-settle-conversion-plan.md`** — COMPLETE. Plan making widget teardown (close/destroy/fullDestroy) self-settle via a freefloating-skip, without redundant re-layout of unaffected parents.
  - ⚖ blanket freefloating-skip alone FAILED — destroy-then-recreate callers relied on deferred settle
- **`interactive-render-perf-A-C-plan.md`** — COMPLETE. Perf plan for SWCanvas's full-cover canvas-wide fast path (A) and static-face back-buffering (C) on a busy interactive desktop drag.
  - ⚖ C1 lesson: a cached back buffer can differ from direct draw via FP non-associativity
- **`island-buffer-cache-plan.md`** — COMPLETE. Completes the affine-transforms island buffer cache so transform-only changes never re-rasterize content; measured 1.40x.
  - ⚖ async glyph-atlas freeze — SWCanvas-only race, needs an epoch bump; native unaffected
- **`island-buffer-cache-rectlist-plan.md`** — COMPLETE. Upgrades the island buffer cache's single dirty rect to a disjoint rect-list so multi-region damage rebuilds only touched sub-rects.
- **`selection-overlay-unification-plan.md`** — COMPLETE + LANDED (2026-07-21). Replaces the world-attached HighlighterWdgt editor-focus indicator with a per-widget PAINT-TIME selection overlay (`Widget._drawSelectionOverlay`, drawn after the subtree, clipped to the widget's visible footprint), folding the spreadsheet cell ring into one mechanism; hover hook `paintHighlight`→`_drawHighlightOverlay`.
  - ⚖ the overlay respects a widget's OWN clipping — a selected widget overflowing its clipping island shows only its VISIBLE edges; an open-bottomed frame there is CORRECT, not a bug (the old world-child indicator drew the full frame only because it escaped clipping)
  - ⚖ the frame is TRANSIENT editor-focus state — it breaks byte-identity round-trip tests that screenshot two same-document points with different selection (deselect before such shots); a dropped item in an editing container is SELECTED (D21)
  - ⚖ "flakes only in the parallel suite" ≠ determinism bug — confirm with single-process runs + heavy-cycle injection first; here it was stale refs (dpr1-only footprint) + boot-storm infra flakes, not nondeterminism
- **`swcanvas-invisible-pixel-hash-nondeterminism-plan.md`** — PARKED. Investigates a raw-pixel-hash test failure with zero visible PNG difference; the diagnosed A=0 mechanism was disproven and the plan parked.
  - ⚖ Diagnosis tell — pixel-identical PNGs with differing hashes means THIS bug class
  - ⚖ Do not backfill references on the strength of the now-contradicted A=0 hypothesis

## OO cleanup, lint & modernization

- **`accidental-complexity-reduction-plan.md`** — COMPLETE. Five-dimension refactor plan (dead code, duplication, over-engineering, control-flow, tooling) across ~470 .coffee files; all actionable items landed+pushed.
  - ⚖ P4 — ScrollPanelWdgt scroll-delta LEAVE-AS-IS, determinism-critical
  - ⚖ P5 — ctor-arg reorder safe for serialization/duplication (Object.create bypasses ctor)
  - ⚖ §0.1 — layout suppression booleans + naming tiers explicitly OUT of scope
- **`census-findings-triage-plan.md`** — COMPLETE. Triages the remaining hierarchy/property census findings added by the Pharo generic-lint carryover.
  - ⚖ a census finding is a QUESTION never an instruction — the 2 top 'best wins' were false positives
  - ⚖ case law 11 — mixin injection onto subclass prototype defeats a naive pull-up
  - ⚖ case law 15 — WorldWdgt.removeEventListeners silently missed 7 of 20 listeners
- **`class-modernization-playbook.md`** — COMPLETE. Process playbook for 'bringing a class to latest' (delete/rename/re-author-tests), reused across all 23 rename batches.
  - ⚖ presentation is part of 'to latest' — a call site can render broken even after a purely mechanical rename
  - ⚖ test-facing API method names called BY NAME from macros must be enumerated before any vocabulary sweep
- **`cross-branch-duplication-refactors-plan.md`** — EXECUTED 2026-07-27. The inverse audit's non-mixin findings: R1 all nine custom painters (Handle, Pen, LabelButton, LayoutChrome family, Cell, SheetHeaderCell, AnalogClock, GraphsPlotsCharts family, Example3DPlot) converted to per-class Appearance delegation — `Widget::paintIntoAreaOrBlitFromBackBuffer` is now overridden ONLY by BackBufferMixin; R2 the `CodeAreaWdgt` base for the Console/Script/CodePrompt/ErrorsLog code-runner family; R3 `Rectangle.largestCenteredSquare()` + `PreferencesAndSettings.normalizedWheelDeltas()`.
  - ⚖ subclass-supplied drawing tails become PUBLIC protocol methods (`drawPlot`, the `drawLayoutChrome` precedent) — an appearance calling a widget's private helper would bump the call-separation ratchet; helpers private to ONE class move INTO its appearance instead (the clock's five)
  - ⚖ moving members OFF a widget's prototype churns any test that shows that widget's inspector member list (the clock's lost 6 rows → 2 gated recaptures, verified one-mechanism-benign via fg diffpage) — inspector-list churn is the R1 conversion's only pixel cost
  - ⚖ R2's "fold the shared `_reLayout`" was FALSIFIED by the verbatim diff (button fields, 2-vs-3 geometry, `_fullChanged` presence differ) — the base carries only byte-identical members; and R3.3's "pixel-alpha pair" was MIS-CHARACTERISED (they are `RectangularAppearance.isTransparentAt` copies; unification would leak shape menu entries — LEAVE with twin cross-references)
- **`disable-editing-family-convert-plan.md`** — COMPLETE. Converts the disable/enable-editing family (7 classes) to the self-settling wrapper + _*NoSettle core idiom.
  - ⚖ transitive-settle lint blind spot — check-layering only discovers LITERAL settling wrappers, not transitive ones
  - ⚖ Phase 7 witness test caught a real disable-path throw no existing test had exercised
- **`duplication-triage-2026-07-15-hierarchy-round4.md`** — COMPLETE. Snapshot of the hierarchy-aware duplication census (IDENTICAL-TO-INHERITED, PULL-UP, DEMOTE); all tranches actioned, zero recaptures.
  - ⚖ A write-only field is enumeration payload, not a local, until proven otherwise
  - ⚖ A mixin augmented onto a subclass injects only the subclass prototype, not the base
  - ⚖ Deleting a Widget-family method does NOT churn the 15-test inspector set
- **`god-class-decomposition-plan.md`** — COMPLETE. Splits the Widget/WorldWdgt/MenusHelper God classes into delegated collaborator classes, following the MacroToolkit mixins-to-OO-delegation precedent.
  - ⚖ recapture reality corrected the backlog — moving a Widget method DOES recapture the inspector test
- **`lint-generic-rules-carryover-plan.md`** — COMPLETE. Carries Pharo SmallLint/Renraku-inspired generic lint rules (unresolved-sends gate, 7 stinks, 2 censuses, fg critique) into Fizzygum's build gates.
  - ⚖ console.log policy RESOLVED: accept as-is, fix 6 wrong verbs to console.error
- **`lint-ratchet-static-checks-plan.md`** — COMPLETE. Ratchets the layout-flow lint (rule [G] direct form) from partial runtime-throw enforcement to build-time static coverage.
  - ⚖ Phase 1b transitive closure prototyped and REJECTED as intractable
  - ⚖ Phase 5 allowlist lint superseded by the runtime auditUndeclaredEndOfCycle capstone
- **`menu-slider-ctor-conversion-plan.md`** — COMPLETE. Converts SliderWdgt/MenuWdgt/prompt constructors to the wrapper+NoSettle-core settle pattern, retiring 4 constructor-build-exempt lint markers.
  - ⚖ a suite RED on WebKit was LOAD-FLAKE, not a regression — reproduced clean 3x
- **`mixin-application-tidyups-plan.md`** — EXECUTED IN FULL 2026-07-27. The inverse mixin audit's three survivors: new `BubblesEditModeToCoordinatorMixin` (the byte-identical edit-mode-bubbling cores triplicated across SimpleVerticalStackScrollPanel/StretchablePanel/StretchableWidgetContainer, unrelated branches), `HighlightableMixin` + colour triple hoisted from the three `IconicDesktopSystemLinkWdgt` subclasses to the parent, and documentation of the two deliberate pinned-`@ratio` non-consumers of `KeepsRatioWhenInVerticalStackMixin`.
  - ⚖ the KeepsRatio "just augment" conversion was FALSIFIED at authoring — both classes are deliberate pinned-`@ratio` VARIANTS (field-based, super-fallback), and Stretchable's old comment gave a WRONG reason (claimed injection would clobber the class body; class body wins) — do not re-attempt the conversion or unify the two ratio protocols (D6 aspect contract)
  - ⚖ case law 11 applied in REVERSE — to de-duplicate a mixin applied across every subclass, hoist the INJECTION to the parent (fields pulled up without the augment are dead text under injection shadowing); the only churn is any UI that COUNTS consumers (the mixin-edit test's save popup went "9 consumers" → "7")
- **`mixin-editing-v2-plan.md`** — EXECUTED IN FULL (same day, 2026-07-26). Completes live mixin editing atop v1's donor routing: the four-form mixin super rewriter, the receiver-side "override in this class" gesture (via the new `Class.applyMemberEdit` choke point, shared with snapshot replay), the "from `<Name>Mixin`" donor label, add/remove mixin members with registry replay, and mixin class-side statics; closed by `SystemTest_macroMixinEditDonorAndOverride`.
  - ⚖ donor attribution was METHOD-scoped at close — a donated FIELD showed its plain value un-attributed and a field-targeting UI flow silently took the plain class-edit path; field parity landed the same day, owner-directed (see the plan's residual ADDENDUM)
  - ⚖ inspect the class that DECLARES the `@augmentWith` — a subclass's inherited-hidden member list has no such row, and the row-select helper's thumb-press then degenerates into a window float-drag (the naked-inspector vBar gotcha, windowed edition)
- **`oo-smells-refactoring-backlog.md`** — COMPLETE. OO-smell cleanup backlog (dead code, base-class extraction, IconWdgt thinning, MenuItemSpec, Widget decoupling); phases 0-5 landed, 6-8 superseded elsewhere.
  - ⚖ Phase 5c — instanceof→isX?() predicate sweep REVERTED, still a type-test
  - ⚖ Ordering rule — Phase 5 must precede Phase 6 (God-Class split)
- **`public-private-call-separation-plan.md`** — COMPLETE. Command/query discipline campaign (rules [S]/[T]/[U]) privatizing public methods not provably public API; fully executed via census-driven tranches.
  - ⚖ Census heredoc bug misclassified a self-call, letting 2 macro verbs into rename list
  - ⚖ [A]-collision rule — a public method driving public settling on OTHERS can't go private
- **`type-test-elimination-plan.md`** — COMPLETE. Codebase-wide capability-first campaign eliminating instanceof/isFoo? type-test smells; absorbs widget-identity-decoupling-plan.md.
  - ⚖ Capability-named queries legitimate where behaviour can't move — 5c's flaw was faithfulness, not queries
  - ⚖ ε LEAVE example: SliderButtonWdgt identity shape falsified by documented detach-then-duplicate state

## Features & apps

- **`basement-to-bin-plan.md`** — COMPLETE (executed same day, 2026-07-22). Basement→Bin conversion: unpinned pop-ups DESTROY on dismissal (one `PopUpWdgt._closeNoSettle` override covers all four paths), doGC marks world-slot furniture reachable, permanent lost-only view + confirmed Empty bin, full Bin rename (classes/files/keys, both repos), TrashcanIconWdgt deleted. Its §6 "physically split the roles" rejection was SUPERSEDED the next day by `bin-shelf-eager-sorting-plan.md`.
  - ⚖ the thin-wrap gate forced the cleaner shape: `PopUpWdgt.close` DELETED, `openPopUps` bookkeeping moved into the `_closeNoSettle` core (also fixed the NoSettle-drain leak)
  - ⚖ the lost-only filter must be SYMMETRIC (re-show lost) once permanent — with the toggle gone, an item going lost while hidden had no other path back to visible
  - ⚖ Phase-2 `show()` companions in the SAME commit as the oracle fix (hidden-furniture landmine); owner declined the dev-mode show-all escape hatch (deleted outright)
- **`bin-shelf-eager-sorting-plan.md`** — COMPLETE (authored 2026-07-22, executed 2026-07-23). Bin/Shelf split with EAGER sorting: `ShelfWdgt` (bare, never-viewed store) holds the reachable, the bin exactly the lost, at all times; reachability chokepoints mark, a `StorageSorter` doOneCycle drain station (before `recalculateLayouts`) classifies once and moves; whole lazy view machinery (hide/show, revival un-hides, on-open refresh) DELETED; Tier A `STORAGE_INVARIANT` console-token guard on every suite leg + Tier B `fg storage` deep-audit leg (from-scratch reclassify, zero-moves idempotence, empty profile) → 13-leg gauntlet.
  - ⚖ the doGC "bin on-screen" precondition dissolved by ONE pass-1 change — discard only `isOrphan() and !isInStorage()`; an orphan reference IN storage is a pass-3 relay (spike-proven ≡ open-bin on chains, first shape)
  - ⚖ subclass lifecycle bookkeeping goes in the NoSettle CORE: `IconicDesktopSystemShortcutWdgt.destroy`'s tracker delete was bypassed by every bulk destroy (core chains never call public wrappers) — a years-old silent tracker leak the newborn Tier A guard exposed in minutes
  - ⚖ a drain station must suppress its own relay ECHOES (`@_draining`, the dataflow no-re-entry rule): its container moves re-fire child-add/removed hooks, and a mid-drain reclassification overwrites the marks the drain is still reading
  - ⚖ per-event immediate sorting is FALSIFIED by construction — a shortcut registers into the tracker in its ctor while still orphan; only an end-of-cycle drain classifies it attached
- **`drag-embed-implementation-plan.md`** — COMPLETE. Implements dwell-to-arm drag-embed UX: destination edit-mode gate, 450ms dwell arming, offset landing, derived internal/external.
  - ⚖ Phase 4 pill+hint UX BUILT then OWNER-REJECTED — replaced by plain land-at-release, no popup
  - ⚖ S2 gap-credit mechanic FALSIFIED by real-mouse test — revised to elapsed event-time + ring feedback
- **`fizzytiles-sw3d-port-plan.md`** — COMPLETE. Ports Fizzytiles 3D rendering from WebGL/twgl onto vendored SWCanvas SW3D and makes the 3D pane run real tile-authored code.
  - ⚖ §9 AS-BUILT overrides the unticked §landing checklist — read that, not the boxes
  - ⚖ block-scoping bug found post-landing: primitives must return truthy or transforms leak
- **`pencil-eye-edit-mode-toggle-plan.md`** — COMPLETE. Makes the window edit-mode button show pencil/eye as a state glyph, later refined to monochrome-rest plus yellow hover feedforward.
  - ⚖ §2 — rejected SwitchButtonWdgt [pencil,eye], would add a second source of truth
  - ⚖ CLICK-THEN-PARK — must move pointer off button before screenshotting rest state
- **`spreadsheet-standard-caret-editing-plan.md`** — COMPLETE (authored + executed 2026-07-24). Cell editing became STANDARD CaretWdgt editing on a real editable in-cell editor: type-to-edit replace / Enter / F2 / double-click-at-clicked-slot enter; Enter commits + Escape reverts via the caret's accept/cancel escalations landing on the CellWdgt; acting elsewhere commits. The 2b buffer model, the sheet's editing-mode keys and `StringWdgt.showsEndOfTextBar` are DELETED. Framework repairs it forced: dispatch snapshots the receivers Set (fixed a REAL Tab runaway — one press hopped every entry field), accept/cancel escalate from the TARGET (as written they climbed from the destroyed caret's nil parent — delivered to nobody, ever), click-away funnel = `caret.accept()`, `StringWdgt.alwaysEditsInline`, non-editable `mouseDoubleClick` escalates.
  - ⚖ the reframe's "plumbing already exists" was HALF-true: the parenting fact held, but the escalation FIRE-ORDER made it dead — spike before building on a "verified" claim about event delivery
  - ⚖ the "caret blinks (non-deterministic)" fear was wrong the whole time: `BlinkerWdgt.step` is suppressed under the Automator's animations pacing, so carets in references are byte-stable
  - ⚖ a reference can BAKE IN a framework bug: the fitting-modes test's image_4 carried a double-delivered duplicate glyph from the live-Set dispatch — the fix made the render MORE correct and the ref had to follow
  - ⚖ drag-SELECT inside the cell editor is NOT free: the editor is solid with its cell (`wantsDetachOfChild` false ⇒ `grabsToParentWhenDragged` true), so a down+drag is the window-drag gesture — click-to-place / shift-click / double-click-word are the selection story
- **`serialization-deserialization-plan.md`** — COMPLETE. Phased plan building the Serializer/Deserializer pair, file save/load, whole-world snapshot, and source-edit capture, replacing the buggy prototype.
  - ⚖ Duplication (DeepCopierMixin) kept fully untouched/pixel-identical while building the new serializer
  - ⚖ Any out-of-subtree pointer not a well-known singleton = a path-carrying error at serialize time

## Build & toolchain

- **`build-arc-1-test-serving-link-plan.md`** — COMPLETE (2026-07-28). Arc 1 of the build-and-packaging program: replaces the per-build ~4,150-file tests COPY with ONE relative symlink (`Fizzygum-builds/latest/js/tests` → `Fizzygum-tests/tests`), moves the two manifests into the tests repo as derived/gitignored files regenerated by the build and by every runner at startup, and retires the flatten, `--keepTestsDirectoryAsIs`, build.py's manifest generation, and every publish-rebuild in the capture/recapture flow. Gauntlet 13/13 with ZERO reference churn.
  - ⚖ the "file:// can only load from its own folder or lower" folklore is FALSE on both engines the suite drives (it is Firefox's fetch/XHR rule; Fizzygum never fetches) — `<script src>` follows `../` and symlinks fine
  - ⚠⚠ `rm -rf <link>/` — ONE trailing slash — DELETES THE WHOLE TARGET, and `find -L` descends through the link; `rm -rf <parent>` does NOT (measured both ways). Hence exactly two operations on that path anywhere: `ln -sfn`, and a guarded `[ -L p ] && rm -f p` whose `rm -f` cannot recurse. A PreToolUse hook rule blocks the dangerous spellings
  - ⚖ FALSIFIED (§10.1): the `Fizzygum-builds` slimming was a NO-OP — `latest/` was never tracked on `master`; only a 2016 `gh-pages` snapshot holds the old copy, deliberately left alone
  - ⚖ FALSIFIED (§10.2): `--homepage` needed the two manifests to EXIST during its `?generatePreCompiled` pre-compile pass (the boot condition was not `BUILDFLAG_LOAD_TESTS` alone), so the build wrote two EMPTY stubs and cleared them afterwards — **SUPERSEDED by arc 2**, which narrowed that condition; a homepage build now writes no `js/tests` at all
  - ⚖ a manifest regenerated at runner startup is read LIVE by browsers through the link, so the write must be no-op-when-unchanged + atomic `rename()`, never a truncating `writeFileSync`
  - ⚖ reference filenames carry a `systemInfoHash` derived from SCREEN SIZE/COLOUR DEPTH — capturing on a different display renames every file it touches while the pixels and `dataHash` stay identical

- **`build-arc-2-backend-split-precompile-plan.md`** — COMPLETE (2026-07-28). Arc 2 of the build-and-packaging program: splits the rendering backend at BUILD time (the runtime `?sw=1` switch is deleted) and externalizes pre-compiled-image generation. One build pass now emits TWO boot bundles from ONE terser output and three entry pages from one page source (`build.py`'s `ENTRY_PAGES`): `index.html` native (31,898 B, carrying only SWCanvas's new subtractive 3D-core dist target for SW3D), `index-sw.html` + `worldWithSystemTestHarness.html` SWCanvas (314,491 B). `--homepage` is native-only: no SW bundle, no `index-sw.html`, no 90 MB `font-assets/`. Gauntlet 13/13 with ZERO reference churn.
  - ⚖ splitting a bundle is NOT "two builds": the seam is the post-terser concatenation, so a second flavour costs a `cat`, not a build pass
  - ⚖ the 3D path needs ~14 KB of SWCanvas, not 263 KB — and the subset is PIXEL-IDENTICAL to the full engine (SHA-256 over the whole surface, unminified and minified); `examples/3d-core-node.js` is the witness, and it requires ONLY the core so a leaked dependency throws in SWCanvas's own repo
  - ⚠⚠ the homepage's instant-boot precompile had been SILENTLY INOPERATIVE on macOS since the machine stopped being WSL: the driver's whole body sat inside `if [[ "$(uname -r)" == *microsoft* ]]`, so `--homepage` shipped the `window.preCompiled = false` stub and still booted fine. A gate that can pass on the stub is not a gate — `fg homepage` now asserts `window.preCompiled === true`
  - ⚖ every dev boot was accumulating ~2.4 MB of compiled-JS string that nothing read (`JSSourcesContainer.content`); gating the two appends on `generatePreCompiledJS` took a normal boot to a measured 0 bytes
  - ⚠⚠ a 4-leg gauntlet failure that reproduced on EVERY serial retry was still not a regression: the same gate fails on a fully reverted tree (§12.8). `SystemTest_macroClosingRotatedIslandChildClearsFootprint` is the load-sensitive incremental-repaint canary — the SLOWER run is the one that fails. Do the revert-and-rebuild A/B early; reasoning about which code path "could" matter costs more than the ~8 min A/B
  - ⚠⚠ **decision D3 (no det-trig in the native bundle) STANDS, but its premise "it exists solely for SW cross-engine determinism" was FALSE** — the prelude also defined `DetTrig`, a global two source files named DIRECTLY (`HandleWdgt._pointerAngleToTargetAnchorDegrees`, `TransformSpec._cosSin`), so from arc 2 until 2026-07-30 rotating anything on `index.html` or a `--homepage` build threw `DetTrig is not defined`. Fixed by routing both call sites through `Math.*` — which the SW pages' prelude patches to the same fdlibm port before any class compiles, so gated pixels could not move (zero reference churn) — NOT by shipping det-trig natively. See the plan's D3 follow-up note
  - ⚖ **a bundle-content decision is also an API decision**: before calling a payload "backend-specific", grep `src/` for every global it defines — a prelude is not just bytes for the engine, it is part of the namespace every class compiles into
  - ⚖ **booting is not exercising**: a smoke test that only LOADS a page certifies nothing about the paths a user reaches. `smoke-boot-headless.js` now drives a real rotate gesture on both shipped entry pages
  - ⚖ retirements completed in-arc (doctrine): the WSL generator + its `configure-these-paths.sh`, the JSZip/`saveAs` drain, arc 1's homepage manifest stubs, and `remove_tests_link`'s real-directory branch

- **`build-arc-3-world-harmonization-plan.md`** — COMPLETE (2026-07-30). Arc 3 of the build-and-packaging program: ONE world design for homepage and dev/test, and the `»>>` region-exclusion mechanism retired ENTIRELY — 63 → 0 sites (promotes returned the full layout engine + real constants to the homepage; test machinery moved to five harness-side `*TestSupport` extension files; demo/dev content extracted to whole-file-marked collaborators `DemoMenus`/`PinoutsOverlay`/…; dead accretion deleted incl. `MouseSensorWdgt`/`PinType`/`ProfilingDataCollector`); all three build.py region regexes DELETED; `check-region-markers.js` holds every kind at baseline 0 as a HARD rule. Menu topology unified per the owner-ratified phase-7 sub-plan (below). 18 recaptures (dpr 1+2), suite 268 → 269, gauntlet 13/13 + homepage green.
  - ⚖ H-R3's `world.menuContributors` hook was deliberately NOT built — the class-existence collaborator pattern (`if DemoMenus?`; the file is whole-file-marked so the check is false in production) won on consistency with `world.widgetFactory`/`world.pinouts`, and it is exactly the right guard when arc 4 turns these files into lazily-loaded parts
  - ⚖ `MenusHelper` was 689 of 758 lines demo content — "extract the demo class" was really "extract the class"; the three shipping members stayed behind
  - ⚖ comments may MENTION the retired `»>>` mechanism as provenance (4 such mentions survive); the gate counts marker OPENERS, not the glyph

- **`build-arc-3-phase-7-menu-topology.md`** — COMPLETE (2026-07-30, committed with arc 3 phases 5–7). The owner-ratified ONE menu topology (three design calls made with the code in view; two owner follow-ups folded in: scrollbar spacing, keep BOTH duplication verbs). Its §0 is a mid-execution handoff snapshot kept verbatim — the status stamp carries the final truth.

- **`build-arc-4-dynamic-parts-plan.md`** — COMPLETE (2026-07-30). Arc 4 of the build-and-packaging program: turns "everything compiles at boot" into named, lazily-loadable **parts**. `SourceVault` (`src/boot/source-vault.coffee`, first in the boot bundle) became the ONE registry of source text, retiring the 499 `window.<Name>_coffeSource` globals and the `Object.keys(window)` suffix-scan that discovered them — and stopping the emission of 499 per-class source files nothing ever loaded (514 files/6.6 MB → 17/2.7 MB per dev build). `buildSystem/parts.json` now holds the WHOLE partition (10 parts, core included) and subsumed build.py's ~25 hand-maintained globs; 32 files moved into part directories; **all 45 whole-file exclusion-marker lines and all three build.py regexes are GONE** (`FILE_NOT_IN_FIZZYGUM_HOMEPAGE` 43, `FILE_ONLY_FOR_MACROS` 2, `FILE_ONLY_FOR_VIDEOPLAYER` **0 carriers — a live exclusion rule that had matched nothing for years**). Fizzytiles is the lazy pilot on `index.html`: engine + LCL compiler + the SW3D vendor payload all arrive on demand through `world.parts` (`PartsRegistry`), with `loadWorldSnapshot` gaining a pure pre-scan + tail re-entry so opening a file that contains a lazy part's widgets works. Three new gates at zero (`check-source-vault.js`, `check-whole-file-markers.js`, `check-part-edges.js`); two new headless rigs (`parts-lazy-load-headless.js`, `parts-snapshot-load-headless.js`) as the gauntlet's `parts` leg. Gauntlet 14/14 in-wave with ZERO reference churn (269 tests × dpr1/dpr2/webkit) + homepage green. Phase 3 (more lazy parts) declined by the owner — optional by construction, carried forward in `BACKLOG.md`.
  - ⚖ **INCLUSION ≠ EAGERNESS** (R6/P-D7) — the retired whole-file markers only ever expressed *does it ship*; a part needs that AND *is it loaded at boot*, as two independent axes (`inHomepage` in `parts.json` vs per-part `eager` + the per-entry-page `FIZZYGUM_EAGER_ALL_PARTS` preset). Keeping them separate is what let Phase 1 repartition the entire tree while being unable to move a pixel, and Phase 2 flip ONE part on ONE page
  - ⚖ **the `if X?` existence guard is right for INCLUSION and WRONG for LAZINESS** — for a part that was never shipped it means "silently no-op", which is correct; for a part that merely has not loaded yet it silently swallows the user's click. A lazy part's entry point must await `world.parts.ensureLoaded`. (A registration hook / part-declares-itself callback was considered and rejected: the plain class-existence guard is the tree's existing idiom, owner-confirmed)
  - ⚖ **an `extends` / `@augmentWith` edge from core into a part is not guardable at all** — unlike a construction site, there is no "skip it" branch, so it means the partition is drawn wrong. Two different verdicts from one check
  - ⚖ **parity must be MEASURED, not derived** (owner) — before the marker regexes could be deleted, a homepage-tree fingerprint (stored source NAMES + file list + sizes + SHA-256) had to match byte-for-byte, because "still 433 sources" can be true while the SET differs (a swapped pair nets to zero). It came out identical, 433 both sides. Arc 5's PR-D4 pattern, applied early. Corollary drawn when two batch *hashes* did move: "a batch changed" is also what an escaping bug looks like, so all 433 stored sources were decoded back against their `.coffee` files rather than argued about
  - ⚖ **don't write registry API ahead of its callers** — the dead-method gate rejected `SourceVault.partOf`/`forgetPart` on the first build. The right response was to DELETE them and grow the API in the phase whose code calls it, not to allowlist them
  - ⚠⚠ **all four execution bugs shared ONE shape: a rule encoded in two places.** (1) the class→part map read the `SourceVault`, which only knows sources whose batch already loaded — unusable for the lazy case that is its only reason to exist ⇒ it is build-manifest data; (2) "is this part eager here?" existed twice, and the copy the boot loader used ignored the entry-page override ⇒ every Fizzytiles SystemTest STALLED while the registry reported the part LOADED; (3) that one predicate then had to live in the boot BUNDLE, because a pre-compiled `--homepage` boot builds the world before the separately-fetched loader script lands — **`fg homepage` was the only gate that could catch it**; (4) the staleness census's battery reached a window that a lazy page no longer had
  - ⚠⚠ **the dependency scanner does NOT see `new X` in a method body** (only `extends`/`REQUIRES`/`@augmentWith` and 2-space-indented class-body field initialisers) — so the originally-planned "derive the core→part edge check from the dep scan" would have passed VACUOUSLY, since every real launch site is a method-body `new`. The shipped check is an identifier-level scan, with a documented deliberate blind spot for `new (window[name])` after `ensureLoaded` (the sanctioned lazy path) so a future session does not "fix" the hole
  - ⚠⚠ **`loadWorldSnapshot` is NOT async-shaped** — `result.whenReady` is an image-decode promise, not a completion hook. The parts await is a pure pre-scan + tail re-entry, and its ORDERING is the whole risk: it must precede `_teardownWorldStructureNoSettle`, so a REJECTED part load leaves the old world standing (asserted: 12 desktop children before, 12 after)
  - ⚠⚠ **anything the world's CONSTRUCTOR needs must be in the boot bundle**, not in a `js/src/*-min.js` file — those load later in the boot sequence, and a precompiled build has already built the world by then

- **`minimal-coffeescript-runtime-compiler-plan.md`** — COMPLETE + SHIPPED (2026-07-23). Forks the vendored in-browser CoffeeScript compiler down to a minimal compile-only build; shipped as the npm/GitHub package `fizzygum-coffeescript-min@1.0.0` and vendored into Fizzygum (`fc9750b5`, `auxiliary files/CoffeeScript/fizzygum-coffeescript-min.js`). Final 208,604 B (−18.9% vs stock 2.0.3), byte-identical emitted JS over all 4901 corpus fragments + full gauntlet green.
  - ⚖ sub-257 KB is INFEASIBLE on a 2.7.0 base (parser+nodes core alone = 278 KB > the whole 257 KB 2.0.3 bundle) — re-based on 2.0.3 (owner pivot), whose smaller core is the point; the §1/§5 2.7.0 mandate is superseded by §12
  - ⚖ "DEAD in V8 coverage" ≠ safe to cut — the error-reporting path is dead only because the corpus compiles clean yet fires on live-edit typos (KEEP); real language features unused-in-corpus stay usable (KEEP); only exotic tooling (sourcemap/JSX/import-export/literate/shebang/baseFileName) was cut
  - ⚖ the vendored file has THREE refs, not two — the plan AND memory undercounted, missing the runtime boot loader (`src/boot/globalFunctions.coffee`); grep the WHOLE tree before a rename, not just the build scripts
  - ⚖ byte-identity to STOCK 2.0.3 (not 2.7.0) is what keeps the pixel-exact gauntlet refs valid — the fork is frozen on 2.0.3; tracking upstream is an anti-goal, which is why it's an own-package derivative, not a CoffeeScript branch

## Process & workflow

- **`dev-workflow-optimization-plan.md`** — COMPLETE. Post-transcript-audit plan to parallelize the gauntlet, shard the paint audit, and add fg lint/status/recapture-inspector tooling.
  - ⚖ P7h arity assert FALSIFIED — a live 6-arg polymorphic add() contract exists, reverted not re-tuned
  - ⚖ P2 inspector churn driver is ctor-assigned INSTANCE FIELDS, not prototype methods

## Starting prompts (`archive/prompts/`)

- `PROMPT-simplify-layout-arc.md` — session starting prompt (from the umbrella root)
- `PROMPT-simplify-transforms-arc.md` — session starting prompt (from the umbrella root)
- `class-modernization-planning-starting-prompt.md` — Session-bootstrap prompt orchestrating the *Morph→*Wdgt class-rename campaign, batch by batch, plus the naming-consistency follow-up.
- `drag-embed-execution-starting-prompt.md` — Session-bootstrap prompt directing execution of the drag-embed dwell-to-arm implementation plan, phase by phase.
- `drop-into-rotated-container-starting-prompt.md` — Session-bootstrap prompt to implement F1 (pinned-anchor render-drift fix) atop the already-implemented §5 layout-transparency fix.
- `duplication-preserves-transforms-starting-prompt.md` — Paste-ready starting prompt handing a fresh session the duplication/save transform-preservation plan to implement cold.
- `serialization-execution-starting-prompt.md` — Copy-paste session-starter prompt for resuming the serialization arc at Phase 5/6 (whole-world snapshot, source-edit capture), now both landed.
