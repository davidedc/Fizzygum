# BACKLOG.md — every open item, with its owning doc

Index only: the executable detail lives in the linked plan section.
Active arcs live in `plans/`; residual items point into `archive/`.
Generated 2026-07-17 from the docs restructure; keep current per README rule 5.

## Active arcs (`plans/`)

### `plans/affine-transforms-plan.md`
Phase 4 + residuals + claimsSpace arc shipped/pushed; REMAINING = big §7.1-7.4/7.8 items, design-first, owner-gated.
- [ ] §7.1: transform policy engine (banked, not built)
- [ ] §7.2: leaf self-warp (non-island rotation)
- [ ] §7.3: quad-aware damage + occlusion behind transformed widgets
- [ ] §7.4: density folding (owner-downgraded priority)
- [ ] §7.8: SWCanvas bilinear drawImage (separate repo; v1 uses nearest-neighbor)

### `plans/dataflow-engine-implementation-plan.md`
Phases 0-8 plus F1/F2/F4/F5/F6 all LANDED; only F3 ('operate ➜' cell menu) remains, independent, any time.
- [ ] F3: 'operate ➜' cell menu — value-class method introspection into a formula

### `plans/livecodelang-cleanup-and-extensions-plan.md`
AUTHORED 2026-07-07, NOT STARTED; owner-initiated execution only.
- [ ] T1 R1-R4: headless preprocessor test gate + corpus fixes — not started
- [ ] T2 R5-R10: correctness fixes: escaping, boundary guards, magnet geometry, tan collision
- [ ] T3: dead weight & duplication removal, corpus must stay 300/0 — not started
- [ ] T4: preprocessor structural refactor, behavior-preserving — not started
- [ ] T5: language/runtime extensions, owner picks which — not started

### `plans/occlusion-culling-plan.md`
P0-P3 (Avenue A) LANDED 2026-07-09; P4/P5/P5b/P5c OWNER-GATED, not started.
- [ ] P4: Avenue B maintained covered-rect list, replacing per-rect traversal — not started
- [ ] P5: descend to nested opaque panels/window bodies — optional, not started
- [ ] P5b: hand-carried drag coverer (hand paints last, uncounted today) — not started
- [ ] P5c: fringe decomposition of the dragged window's own rects — not started

### `plans/runtime-performance-optimization-plan.md`
H1/Arc2-4/W1-W2/A/C1/O1/O2 landed; NEXT = O3 (per-widget occlusion) + O4 (drawImage attribution)
- [ ] §5B O3: per-widget/descend occlusion (plan P4/P5) — large, owner-gated
- [ ] §5B O4: reduce _drawImageInternal blits — needs targeted attribution profiling first
- [ ] §8/top banner: S2 Tier 2, S6b, F1 (precompiled test-harness boot) still unlanded
- [ ] §5 F3: dirty-rect DOM present — deprioritized, not landed

### `plans/single-file-save-plan.md`
AUTHORED 2026-07-10, design LOCKED by owner, no code written yet; next = Phase 0 spikes S1/S2
- [ ] §5 Phase 0: S1 FizzyPaint round-trip spike + S2 hand-built prototype — not yet run
- [ ] §7: banked v1-excluded items: precompiled file, SWCanvas strip, baked edits, dirty guard

## Residual / parked items (owning doc archived)

- [ ] `archive/accidental-complexity-reduction-plan.md` P5 Family 4 note: optional [U] gate baseline tighten 150→148
- [ ] `archive/basement-dormant-layout-flag-plan.md` §5: design + implement the cached _inBasement flag
- [ ] `archive/basement-dormant-layout-flag-plan.md` §7: step-by-step build of the flag — not started
- [ ] `archive/basement-dormant-layout-flag-plan.md` §8: mandatory gauntlet + dpr2 torture verification — never run
- [ ] `archive/caret-follow-in-place-settle-plan.md` §5: decisive first step: trace where typing's caret drains today
- [ ] `archive/caret-follow-in-place-settle-plan.md` §6: implement the fix shape once §5's trace is known
- [ ] `archive/caret-follow-in-place-settle-plan.md` §7: mandatory byte-exact verification protocol — not run
- [ ] `archive/claimsspace-footprint-default-and-scroll-reachability-plan.md` §5 S3 / G2: owner halo feel-check (desktop/document/scroll-panel), post-push
- [ ] `archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md` §8-C follow-up 4a: FizzyPaint canvas-resize ghost — fix identified, couldn't reproduce to verify
- [ ] `archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md` §8-C follow-up 4b: broader ScrollPanel resize-preservation — implemented, verified no-op, reverted
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: whether PNG export flattens over opaque background — uninspected
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: backfill blast radius (SWCanvas ref count, scriptability) — uncounted
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: cross-engine (V8 vs JSC) invisible-pixel residue identity — unverified
- [ ] `archive/god-class-decomposition-plan.md` Tier 3 / C21: context-menu construction relocation to menusHelper — deferred, screenshot label-strip risk
- [ ] `archive/hover-resync-after-flush-plan.md` § CAPSTONE GATE WEAKNESS note: paint-readonly gate shares the careless-push-count-only weakness — still open backlog
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.1 A2: action-string dispatch resolution gate — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.2 A3: must-call-super table-driven rule — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.4 A6: dead-class detector (ReClassNotReferencedRule) — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.5 C: per-file metrics ratchet for god-class line counts — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.9: empty-catch stink — needs multiline stink-engine extension
- [ ] `archive/lint-ratchet-static-checks-plan.md` Phase 4: encode tier in underscore prefix on immediate mutators — PARKED, owner-gated, low priority
- [ ] `archive/menu-slider-ctor-conversion-plan.md` §0 non-goals: WorldWdgt dev-menu show-all/hide-all removal — separate parked item, 12-macro recapture
- [ ] `archive/private-noLayouting-core-callpaths-plan.md` §5: static lint for private/Core method calling a public settling method — optional, unbuilt — NOTE: check lint-and-static-checks.md — may already be enforced
- [ ] `archive/private-noLayouting-core-callpaths-plan.md` top banner: Plan 2 — rename 'Core'→'NoLayouting' (separate later doc/session) — NOTE: DONE via layout-settle-tier-rename (*NoSettle names live) — verify, then drop
- [ ] `archive/settle-tier-followups-examination-plan.md` Topic 3: audit that every non-settling private fn is named *NoSettle — never started — NOTE: likely subsumed by the standing tiernaming gate — verify before executing
