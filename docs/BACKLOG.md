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

### `plans/pixel-icons-plan.md`
AUTHORED 2026-07-18, NOT STARTED; replace ~79 vector `*IconAppearance` files with ASCII index-mask pixel icons (16/32/48 all supported, per-icon subset by usage cohort, coverage-rule variant selection; maps/gradients/logo-with-text stay vector); ⛔ two owner gates (P0 aesthetic, P4 mass recapture).
- [ ] §5 pre-step: owner re-judges the convert list against the crispness-audit tiers (`measurements/vector-icon-crispness-audit-2026-07-19.md` §7) — per icon now a THREE-way choice: keep-vector / pixel-grid / size-aware redraw (§5b; LANDED for Typewriter + Folder + ShortcutArrow 2026-07-21 on the shared `SizeAwareIconAppearance` base; process = local skill `/convert-icon-size-aware`)
- [ ] P0: spike (`PixelIconAppearance` + hand-converted Heart) + native≡SWCanvas byte-identity evidence + ⛔ owner aesthetic sign-off
- [ ] P1: rasterizer/parser hardening (variants, crop, literal palette entries)
- [ ] P2: sentinel-supersample authoring tool + all-icon draft contact sheet
- [ ] P3: mass conversion of ~79 appearance files (markers byte-verbatim; Wdgt files untouched)
- [ ] P4: red-set enumeration → diffpage → ⛔ owner recapture approval → serial mass recapture → gauntlet
- [ ] P5: `architecture/pixel-icons.md`, measurements, archive+close
- [ ] P6 (banked): dot-mode at large scale; in-system pixel editor; dead vector-helper prune (⚠ FanoutPin uses `_paintRoundedSquareBadge`)

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

### `plans/onion-widget-composition-plan.md` — "The Frame model" — EXECUTING (phases A + C + B ✅ 2026-07-19)
Naked `Simple*` capability → framed `*Wdgt` citizen (`FrameWdgt`, was `WindowWdgt`) → App=launcher. Intrinsic-framing principle LOCKED (D1–D9). Correctness-first — no churn deferrals.
- [x] §5 P0: `architecture/regularity-principles.md` — LANDED 2026-07-19
- [x] §5.A: `WindowWdgt` → `FrameWdgt` rename + de-inherit + `FrameBarWdgt` bar composition — PHASE A COMPLETE 2026-07-19
- [x] §5.C: one shared `ToolbarWdgt` per content type + the frame toolbar-slot — PHASE C COMPLETE 2026-07-19 (C1 `1e06b79f`, C2 `74322e1d`, C3 `3e8eecd6`); paint toolbar QUARANTINED in `ReconfigurablePaintWdgt` for §5.D; slot guard test landed (tests `24bfa3882`)
- [x] §5.B: payload/citizen split — PHASE B COMPLETE 2026-07-19 (B1 `fe76f679` substrate, B2 `79eaaf9c` SimpleTextWdgt+TitleWdgt, B3 `4dcfbc4c` DocumentWdgt, B4 `19b13d9d` GenericPanelWdgt family, B5+B6 spreadsheet/image renames — execution design + case law in plan §5.B)
- [ ] §5.C follow-ons: undock-to-float context-menu entry (D9 tail, never a bar button); `right`/`bottom` dock arranges (property values exist, arrange support doesn't); `HorizontalMenuPanelWdgt` now demo-only (MenusHelper) — fold or keep
- [ ] §5.B follow-ons: `DeckWdgt` = D2 reserved name, no substrate yet. Creation-menu wording ✅ 2026-07-20 — the citizen-creator dev-menu labels renamed to the kind ("simple document"→"document", "Simple slide"→"slide", + the two launchers "document launcher"/"slide launcher"); recapture-FREE (those labels are dev-menu-only, navigated/screenshotted by no test). The `simple plain text …` dev-menu cluster left as-is (out of scope, owner kept it tight)
- [ ] §5.D follow-ons: a load-image-FILE flow into `ImageWdgt` (owner decision D13: `SimpleImageWdgt`, the bitmap loader, stays a sibling payload with its one button-face consumer until such a flow exists — the stamp drop-flow already imports pixels). The ungrammatical "a Image" hierarchy row ✅ FIXED 2026-07-20 — `Widget.toString` now derives the article ("an" before a vowel-initial class name, else "a"); probe-verified (`an Image`/`an AnalogClock`/`a Rectangle`), zero recaptures (no test screenshots a vowel-initial menu label)
- [ ] build tooling: shippable-vs-`find src` coverage check — a new `src/` directory ships NOTHING until listed in `build.py`'s explicit glob list, the build exits 0, and the syntax gate consumes the same list (cost one red presuite in C1; runtime symptom `<NewClass> is not defined`)
- [ ] census blind spot (pre-existing, exposed then re-masked in B): an AS-BUILT (never-resized) sample-slide window's NYC scroll content panel sits one scrollbar-width short of its content hull until any resize converges it — the census battery resizes every window before the sweep, so the oracle never sees the as-built state (B4 briefly exposed it when citizens escaped the battery's old `/FrameWdgt/` name regex, now the polymorphic `isFrame()`); a truth-re-lay pass over AS-BUILT windows would be the honest extension
- [x] §5.D: D-1 paint-on-focus — execution design + S1 spike ✅ 2026-07-20 (spike ALL PASS, evidence in plan §5.D D-iii); D1b landing = `ImageWdgt` + `PaintToolbarWdgt` + press-time `paintingOverlay()` resolution, `ReconfigurablePaintWdgt` + `StretchableEditableWdgt` DELETED
- [x] §5.D: D-2 focus-policy unification ✅ 2026-07-20 — the mandated four-way (caret + paint tool-head + focus pointer + `StringWdgt.selection`) abstraction was FALSIFIED as structure-without-a-consumer (D-1 dissolved the paint half into per-image injected handlers — nothing world-level left to unify); honest scope landed = D2a one editor-chrome capability (`excludedFromEditorFocusTracking`, the `editorContentPropertyChangerButton` field retired), D2b destroy-time focus hygiene, D2c rename `lastNonTextPropertyChangerButtonClickedOrDropped`→`editorFocusWdgt` (plan §5.D D-2-i…D-2-v)
- [x] §5.D D-3: VISIBLE editor-focus indicator — ✅ PUSHED 2026-07-20 (`6f1514b4` + tests `05f8e2bb5`), ⚠ overlay-WIDGET approach SUPERSEDED (see `selection-overlay-unification-plan.md`). As-landed: `WorldWdgt.addEditorFocusIndicatorWidget` reconciler draws ONE `HighlighterWdgt` teal OUTLINE (D19, `Color 38,166,154`) around `_widgetBeingEdited()` — `editorFocusWdgt` WHEN a caret targets it (text) OR `providesAmenitiesForEditing`+`dragsDropsAndEditingEnabled` (citizen); load-bearing world-guard (desktop click focuses the world, a PanelWdgt with both flags). ⚖ OWNER RULING: KEEP BOTH branches (D18). The predicate SEMANTICS (incl. D21 selected-item branch + spreadsheet opt-out) are KEPT; the world-attached indicator WIDGET is being replaced by a per-widget PAINT-TIME overlay (owner: "not a widget… draw on top of the buffer") — fixes the z-order bug (bringToForeground buries the world-child indicator) + chrome-framing + spreadsheet double-selection. D-2 re-open RESOLVED (four-way `FocusWdgt` stays CLOSED)
- [ ] Selection-overlay unification — PLAN AUTHORED 2026-07-20, NOT started (`selection-overlay-unification-plan.md`). Rework the D-3/D21 editor-focus indicator from a world-attached `HighlighterWdgt` overlay into a per-widget PAINT-TIME overlay via the existing `paintHighlight` hook (rename → `paintSelectionOrHighlight`), drawn on top of the widget's own content/back-buffer; `Widget.showsSelectionOverlay`/`drawSelectionOverlay` (default teal outline), `CellWdgt` overrides to its blue ring (folds the spreadsheet's bespoke selection in — the F5 receipt-B precedent). KEEP `editorFocusWdgt` + `_widgetBeingEdited`; DELETE `addEditorFocusIndicatorWidget`/`editorFocusIndicatorWdgt`/`HighlighterWdgt.editorFocusOutlineStyle`/allowlist line. Also fixes correction 1 = `excludedFromEditorFocusTracking → true` on `ButtonWdgt` (frame-bar chrome buttons weren't excluded → eye got framed). ⚠ #1 risk = invalidate old+new selected widget on change (diff the cached selected-widget per cycle). Spikes S1–S3 before the full rework
- [x] §5.E ✅ 2026-07-20 — most of §5.E was ALREADY DELIVERED by A/B/D (thread 1 uniform-content-entry done: no `FrameWdgt.setContents(x,N)`, `defaultContents` placeholder exists; the read-only INHERITANCE smell removed by B: info-widgets are factories). Landed deliverable = E2 `closeFromFrameBarPolicy` tracked field (`saveOrAsk`/`close`/`destroy`) replacing 6 per-instance `closeFromFrameBar` monkey-patches (DocumentWdgt._buildInfoDocNextTo's own TODO) + deduping the twin citizen bodies onto `FrameWdgt._saveOrAskThenCloseCitizen` (plan §5.E E-vi). ⇒ FRAME-MODEL FLAGSHIP ARC (A·C·B·D·E) COMPLETE
- [x] §5.E follow-on (E1) — ⛔ REJECTED 2026-07-20 (owner): a no-pencil `readOnly`/locked-view-mode capability will NOT be built. Fizzygum glorifies direct-manipulation authoring, so locked-in-view-mode content goes against the spirit — everything stays editable via the pencil (the D8 view-mode-WITH-pencil model is the intended one, not a compromise). Do not re-propose. (Supersedes the plan §5.E E-iii/E-D19 "deferred" framing.)
- [x] §5.E E3 ✅ 2026-07-20 — info-widget factory collapse LANDED (Option A "closure table", Sonnet subagent): the 9 shared-builder `info-widgets/*` classes collapsed into `src/apps/InfoDocs.coffee` (`@REGISTRY` of build closures keyed by kind + `@createNextTo(key, nextTo)`; `_buildInfoDocNextTo` moved off `DocumentWdgt`). Every construction is a LITERAL `new X`, so the regex dep-finder keeps all load-order edges — no `REQUIRES` markers needed. `WelcomeMessageInfoWdgt` stays standalone (large bespoke `@create`). 9 classes deleted, 1 added; 9 call sites re-pointed

### `plans/graph-edges-and-lifecycle-plan.md`
AUTHORED 2026-07-18, design-stage/exploratory, owner-gated; unify containment/target/reference edges; GC = reachability over their union. Supersedes the reference plan's link-rename + GC.
- [ ] §4.1: reference link `@target` → `referencedWidget` (reference ≠ dataflow target)
- [ ] §4.2: name the 3 edges as one vocabulary; reuse the dataflow index for target edges
- [ ] §4.3: one incremental whole-graph collector (containment ∪ target ∪ reference) — second wave
- [ ] §4.4: (bank) record that reference-counting is NOT the mechanism

### `plans/creation-and-templates-plan.md`
AUTHORED 2026-07-18, design-stage/exploratory, owner-gated; create = duplicate-a-template (Factory) | run-an-assembler (ScriptRunner); App = a Factory over an empty framed `*Wdgt` in edit mode. Supersedes the reference plan's launcher/Factory.
- [ ] §4.1: name `FactoryWdgt`/`ScriptRunnerWdgt` (use `isTemplate` + `DeepCopierMixin`)
- [ ] §4.2: redefine "App" as a Factory over an empty framed `*Wdgt` in edit mode
- [ ] §4.3: fold the creator zoo (CreatorButton/WidgetFactory/MenusHelper "new X") onto the two primitives — second wave
- [ ] §4.4: (bank) templates as first-class editable objects

### `plans/container-regularization-plan.md` — IN PROGRESS; List/Menu untie + prompt family LANDED (green)
AUTHORED+FLESHED 2026-07-18; de-byzantinate Menu/List/Prompt/Divider. Key finding: menu-ness already lives in `PopUpWdgt`, so the untie is a LAYOUT extraction, not a behaviour one. **§5.1 + §5.2a–c LANDED 2026-07-18 (gauntlet 11/11, byte-identical bar 1 benign inspector recapture); `instanceof` baseline ratcheted 97→95. §5.3 (prompt family) LANDED 2026-07-18 — full re-base off `PopUpWdgt` composing a titled `MenuRowsPanelWdgt`; gauntlet 11/11 incl. revisits+census, byte-identical bar 1 conscious save-as recapture + 1 test-structure edit.** Remaining: owner-gated tail (§5.2d/§5.2e/§5.4) — §5.2d is now a clean drop-in (the shared titled-rows body is built) that also kills a temporary `_reLayoutSelf` duplication.
- [x] §5.1 [H]: extract `DividerWdgt` (retire inline-`RectangleWdgt` dividers) — DONE, byte-identical; `isDivider` role query
- [x] §5.2a: extract `MenuRowsPanelWdgt` (byte-preserving row-stack lift) — DONE (landed with 5.2b)
- [x] §5.2b [C]: `ListWdgt` uses `MenuRowsPanelWdgt` not `MenuWdgt`; `isListItem` → `selectsItemsOnClick?()` — DONE, byte-identical (Inspector green, zero recapture)
- [x] §5.2c: retire the `isListContents` flag (no readers left after 5.2b) — DONE, byte-identical
- [x] §5.3 [E]: prompt family — `PromptWdgt extends PopUpWdgt` composing a titled `MenuRowsPanelWdgt`; `Text/Number/ColorPromptWdgt`; `pickColor` folded; `SaveShortcutPromptWdgt` re-homed; `SelectPromptWdgt` BANKED (font selectors are editor-integrated menus, not value prompts) — DONE, green (1 conscious save-as recapture + 1 popover test-structure edit)
- [x] §5.2d [B]: recompose `MenuWdgt` = `PopUpWdgt` composing a titled `MenuRowsPanelWdgt` — DONE 2026-07-18 (gauntlet 11/11 incl. revisits(0)+census(0); net −55 lines; 8 menu tests recaptured — invisible corner AA). ⚠⚠ NOT a clean drop-in: 4 real regressions from the extra panel layer (empty-render, ±1px oscillation, transparent-corner hover, inform centering) + 2 `menu.children[N]`→`menu.rowsPanel.children[N]` production sites — see plan §5.2d
- [ ] §5.2e: (follow-on) re-base `MenuRowsPanelWdgt` on `SimpleVerticalStackPanelWdgt` (watch `fg revisits`/`census`)
- [ ] §5.4 [F]: record the deliberate NON-merge of the "one container becomes a window" idea (owner may overrule)

### `plans/reference-widgets-plan.md` — RE-SCOPED (UI + lifecycle areas only)
AUTHORED+RE-SCOPED 2026-07-18; link/GC → graph-edges plan, launcher/Factory → creation plan. Residual = the visible reference UI + desktop lifecycle areas, built on those two arcs.
- [ ] §4.1: clean `Reference*` UI family (retire the verbose `IconicDesktopSystem*` prefix)
- [ ] §4.2: minimise-to-a-bar, distinct from collapse-in-place (second wave)
- [ ] §4.3: RecentlyClosed vs Trash — one store / two views first (second wave)
- [ ] §4.4: duplicate vs duplicate-contents for references (second wave)

## Residual / parked items (owning doc archived)

- [ ] `archive/accidental-complexity-reduction-plan.md` P5 Family 4 note: optional [U] gate baseline tighten 150→148
- [ ] `archive/basement-dormant-layout-flag-plan.md` §5: design + implement the cached _inBasement flag
- [ ] `archive/basement-dormant-layout-flag-plan.md` §7: step-by-step build of the flag — not started
- [ ] `archive/basement-dormant-layout-flag-plan.md` §8: mandatory gauntlet + dpr2 torture verification — never run
- [ ] `archive/basement-to-bin-plan.md` §6 auto-empty: empty the bin automatically at snapshot/quit — DEFERRED, not rejected; revisit after living with the Bin (recoverability expectations; the doGC on-screen precondition it worried about is GONE since the bin/shelf split)
- [ ] `archive/basement-to-bin-plan.md` §4 Phase 3c: bin presentation — swap the pseudo-random scatter for a representativeIcon grid — cosmetic follow-up, owner kept scatter for the semantics arc
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
