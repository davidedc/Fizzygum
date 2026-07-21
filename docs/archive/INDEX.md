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

- **`drag-embed-implementation-plan.md`** — COMPLETE. Implements dwell-to-arm drag-embed UX: destination edit-mode gate, 450ms dwell arming, offset landing, derived internal/external.
  - ⚖ Phase 4 pill+hint UX BUILT then OWNER-REJECTED — replaced by plain land-at-release, no popup
  - ⚖ S2 gap-credit mechanic FALSIFIED by real-mouse test — revised to elapsed event-time + ring feedback
- **`fizzytiles-sw3d-port-plan.md`** — COMPLETE. Ports Fizzytiles 3D rendering from WebGL/twgl onto vendored SWCanvas SW3D and makes the 3D pane run real tile-authored code.
  - ⚖ §9 AS-BUILT overrides the unticked §landing checklist — read that, not the boxes
  - ⚖ block-scoping bug found post-landing: primitives must return truthy or transforms leak
- **`pencil-eye-edit-mode-toggle-plan.md`** — COMPLETE. Makes the window edit-mode button show pencil/eye as a state glyph, later refined to monochrome-rest plus yellow hover feedforward.
  - ⚖ §2 — rejected SwitchButtonWdgt [pencil,eye], would add a second source of truth
  - ⚖ CLICK-THEN-PARK — must move pointer off button before screenshotting rest state
- **`serialization-deserialization-plan.md`** — COMPLETE. Phased plan building the Serializer/Deserializer pair, file save/load, whole-world snapshot, and source-edit capture, replacing the buggy prototype.
  - ⚖ Duplication (DeepCopierMixin) kept fully untouched/pixel-identical while building the new serializer
  - ⚖ Any out-of-subtree pointer not a well-known singleton = a path-carrying error at serialize time

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
