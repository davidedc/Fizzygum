# Deferred-layout — re-fit chokepoint + public `add`/`addRaw` — design (Phase 1 output)

> **STATUS: HISTORICAL (Phase-1 design-of-record; shipped — `ad2000cc`/`b8165920`).** The aim, the current model +
> mechanism (the deferred re-queue), the shipped history, and what's next are all in
> [`deferred-layout-OVERVIEW.md`](deferred-layout-OVERVIEW.md) (the self-contained entry point). Kept as the design
> rationale for the `_reLayoutChildren` chokepoint + the public self-settling `add`/`addRaw` over private `_addCore`.

**Written 2026-06-19.** Companion to `softwrap-deferred-layout-conversion-plan.md`,
`deferred-layout-16-macro-breakages.md` (RESOLUTION + privates-hygiene backlog), and
`deferred-layout-path-a-design.md`. This is the design-of-record for the remaining phases of the
deferred-layout migration. It is the output of a 3-survey design pass; it is meant to be executable cold.

## Goal (the agreed end state)

Top-level callers (macros, apps, event handlers) never call a layout/re-fit method. A public mutation
leaves a consistent world by itself. Concretely:
- the scroll/stack/window **content re-fit** runs via the normal `recalculateLayouts`/`_reLayout` cycle
  (mark-dirty → settle), not via the ~25 scattered **inline** `adjustContentsBounds`/`adjustScrollBars`
  calls + child-reaching hooks it uses today;
- **both** `add` and `addRaw` are public and **self-settle** (re-fit via `recalculateLayouts`);
- all the re-fit/notification machinery is **private**, registered in the layering lint, and the lint
  also scans the macro sources so a macro can't call a private.

## Phase map (risk rises monotonically; each phase is the enabler for the next)

- **Phase 1 (this doc):** design + feasibility. DONE.
- **Phase 2:** ✅ DONE 2026-06-19. `_reLayoutChildren` chokepoint (Slice A, duck-typed + `?()`-soaked);
  concrete re-fit machinery privatized to leading-`_` (Slice B: `_positionAndResizeChildren` /
  `_reLayoutScrollbars` / `_reLayoutChildrenAndScrollbars` / `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` /
  `_amIDirectlyInside*`; the one inspector test `macroDuplicatedInspectorDrivesCopiedTargetOnly`
  recaptured — benign inherited-member-list shift); `check-layering.js` now recognizes `/^_/` (A/B/C)
  **plus a new rule D** scanning macro sources for `_`-private calls (Slice C). Verified 165/165 at
  dpr1/dpr2/WebKit; lint = 487 src + 165 macros, 0 violations; negative-tested (a planted
  `._reLayoutChildren()` is caught). The duck-typed hooks (`childGeometryChanged` /
  `_reLayOutAfterContainedPanelChange` / `reactToDropOf` / `childAdded`…) stay non-`_` pending the
  base-declared reorg (deferred to plan-end).
  - **RECAPTURE GOTCHA (will recur in 3b):** `capture-macro-test-references.js` WRITES the new refs but
    LEAVES the old (tracked) ones → the build's stray/duplicate-ref gate aborts. After a recapture,
    delete the now-stale old refs (`.js`+`.png`) so there's exactly one per image+density.
  - **END-OF-PLAN rule-D tightening (owner-requested):** rule D currently TOLERATES `_reLayoutSelf()` + the
    raw/silent construction read-back idiom (`silentRawSetWidth`→`breakTextIntoLines`→`silentRawSetHeight`
    →`reflowText`, in macroBareTextWidgetDropShadowRestAndDrag / macroBoxTransparencyAndColorChanging /
    macroTextRelayoutsCorrectlyOnResize). At plan-end, give these public self-settling alternatives and
    extend rule D's `MACRO_FORBIDDEN_CALL` to also forbid `raw*`/`silent*`/`fullRaw*`/`/Layout$/`.
- **Phase 3a:** ✅ DONE 2026-06-19. `add`/`addRaw` public & self-settling over a private non-settling
  `_addCore` (= the old `addRaw` body); `mutateGeometryThenSettle` now RETURNS its thunk's value. The
  load-bearing discovery: the design's premise that construction-time settles are "byte-safe idempotent
  relayouts" is **WRONG** — a half-built widget IS reachable (its already-added children point back via
  `.parent`), so settling during its constructor lays it out half-built and **crashes** (boot died in
  `new BasementWdgt → buildAndConnectChildren → @add → recalculateLayouts → _reLayout(half-built)`). Fixed
  at the root with ONE guard in `mutateGeometryThenSettle`: **skip the flush when `@isOrphan()`** (a widget
  attached to neither the world nor the hand has no world-managed layout to flush; it settles for real when
  added to the world). `isOrphan()` is false for the world itself and for anything on the hand, so
  `world.add` / dragged-widget mutations still flush. This covers ALL ~150 construction `add` sites without
  touching them. See "Phase 3a — what actually shipped" below. Verified: boot-smoke clean, lint A/B/C/D 0,
  suite 165/165 at dpr1+dpr2+WebKit, 12 apps launch, 1 benign inspector recapture (`_addCore` joins the
  member list).
- **Phase 3b — Slice 1:** ✅ DONE 2026-06-19. The byte-safe foundation: `ScrollPanelWdgt` now has a
  `_reLayout` (`super` applies own bounds first — DETERMINISM.md case-3c — then `@_reLayoutChildren()`), and
  `implementsDeferredLayout` is pinned to `false` so giving it a `_reLayout` does NOT flip the two read sites
  (resize-invalidate + the load-bearing `subWidgetsMergedFullBounds` nested-scroll contribution). This solves
  the `implementsDeferredLayout` blocker and puts the scroll-panel re-fit on the cycle for RESIZES; the
  re-fit is idempotent on top of the still-present inline triggers, so it removed none of them. Verified
  byte-safe at dpr1/dpr2/WebKit (165/165) + boot clean. (`ScrollPanelWdgt.coffee`, +24 lines.)
- **Phase 3b — Slice 2 (✅ SHIPPED 2026-06-20 — `6c7060e5` (_reLayout) + the flow-rule app-freeze fix `c45113ac` + lint `b89c9141`). CURRENT SELF-CONTAINED RECORD + NEXT STEPS: `docs/deferred-layout-slice2-completion-plan.md` — read that; the bullets below are historical (the "context-aware rawSetWidthSizeHeightAccordingly" they describe was SUPERSEDED by the flow rule).** flip the ~20 inline `_reLayoutChildren` content-change
  triggers to `invalidateLayout` (mark-dirty → re-fit in `_reLayout`). Censusing it showed it is larger than
  the Slice-1 foundation implied: the triggers span **5 files / 3 classes** (ScrollPanel,
  SimpleVerticalStackPanel, Window) — stack/window re-fits would each need their OWN `_reLayout` — and several
  sites carry a synchronous read-back (`justDropped` right after `reactToDropOf`) or content that resizes
  DURING the cycle (stacks, `FIT_BOX_TO_TEXT` text), which is the genuine determinism exposure (the re-fit
  reads `@contents.subWidgetsMergedFullBounds()`, so the panel's `_reLayout` must run AFTER the contents
  settle). The trigger sites are interconnected (a content GRAB re-fits via `PanelWdgt.childRemoved`, not
  `reactToGrabOf`), so a partial flip is incoherent. Reward is architectural (closes the deeper-nesting gap +
  removes the inline triggers); no test fails today. Do it as a dedicated, per-site-analysed effort with a
  torture soak. Canaries: see the test oracle below.
  - **DIAGNOSED 2026-06-19 (the real blocker — why stack/window can't take the Slice-1 `_reLayout`):** giving
    `SimpleVerticalStackPanelWdgt`/`WindowWdgt` the same `_reLayout = super; @_reLayoutChildren()` as the scroll
    panel **hangs** (suite stalled, 5 stack/text/inspector tests). Root-caused by stack-trace instrumentation
    (a perl-`alarm` timeout — `timeout(1)` is absent in this shell, so earlier `timeout …` probes silently
    no-op'd): it is **NOT** an add-relayout quadratic and **NOT** a `recalculateLayouts` until-loop — it's a
    **non-convergent single recalc pass**. Exact cycle:
    `window._reLayout → _reLayoutChildren → WindowWdgt._positionAndResizeChildren → @contents.rawSetWidthSizeHeightAccordingly`
    and `rawSetWidthSizeHeightAccordingly` (Widget:684) does `@invalidateLayout()` **when the contents
    `implementsDeferredLayout()`** (e.g. an `InspectorWdgt`/document) → the contents (non-freefloating) climb
    `invalidateLayout` back to the window → the window is re-dirtied **during its own `_reLayout`** → the
    until-loop reprocesses it forever (`WindowWdgt._positionAndResizeChildren` ran 15000×/pass). **Why Slice 1's
    scroll panel is immune:** `ScrollPanelWdgt._positionAndResizeChildren` sizes its contents with **SILENT**
    setters (`@contents.silentRawSetBounds` + `@contents._reLayoutSelf()`) that DON'T invalidate — so its
    `_reLayout` is a fixed point. **The fix for Slice 2:** make `SimpleVerticalStackPanelWdgt`/`WindowWdgt`
    `_positionAndResizeChildren` size their (deferred-layout) children the scroll-panel way — silently +
    synchronously re-laid-out — instead of via the invalidating `rawSetWidthSizeHeightAccordingly`, so their
    `_reLayout` becomes a fixed point too. That is a determinism-sensitive change to core child-sizing (needs
    the _reLayoutSelf-vs-_reLayout semantics per child type right, then the full gauntlet + a torture soak); it is
    the prerequisite for the trigger flip. Owner-gated.
  - **⚠️ SUPERSEDED HISTORY (2026-06-19) — what follows describes the FIRST fix attempt (a context-aware
    `rawSetWidthSizeHeightAccordingly`). It shipped as `6c7060e5` and passed the screenshot gauntlet but FROZE 9/12
    desktop apps (the suite has no app-launch coverage). The real fix was the FLOW RULE (raw setters must not
    schedule layout), `c45113ac` + `b89c9141` — see `docs/deferred-layout-slice2-completion-plan.md` §2. Kept below
    for the diagnosis trail only.**
    Slice 2 ships three orthogonal pieces:
    (1) **the trigger flip** — `SimpleVerticalStackPanelWdgt` got `_reLayout: super; @_reLayoutChildren()` +
    `implementsDeferredLayout: -> false` (WindowWdgt inherits both), so the stack/window content re-fit runs on
    the `recalculateLayouts` cycle; (2) **convergence** — instead of a separate `rawSetWidthAndReLayoutSynchronously`
    (the first attempt; it BROKE polymorphism — see below), the **base** `rawSetWidthSizeHeightAccordingly` is now
    context-aware: when it would `@invalidateLayout()` a deferred-layout child AND a layout pass is already running
    (`world._recalculatingLayouts`, set across the whole `recalculateLayouts` until-loop), it instead settles the
    child synchronously with `@_reLayout()` — no upward climb, so the container's `_reLayout` is a **fixed point**;
    (3) **teardown-crash fix** — `WindowWdgt.buildAndConnectChildren` is wrapped in a new BATCH primitive
    `settleLayoutsOnceAfter` (one settle after the rebuild completes; stops a mid-build self-settling `add` from
    re-fitting a half-wired window whose `layoutSpec.stack` isn't set yet → `getWidthInStack` null-crash during the
    inter-test `resetWorld`; also collapses the per-build O(N)-relayouts to 1).
    - **The regression's real root cause (why the first attempt's "fresh-height read-back" theory was wrong):**
      it was a **POLYMORPHISM break**, not fit math. `rawSetWidthSizeHeightAccordingly` has **8 overrides**
      (`AnalogClockWdgt` → square, `KeepsRatioWhenInVerticalStackMixin` → ratio, `WidgetHolderWithCaptionWdgt`,
      `StretchableWidgetContainerWdgt`, `GenericShortcut/ObjectIconWdgt`, `StretchableEditableWdgt`,
      `Example3DPlotWdgt`). The new `rawSetWidthAndReLayoutSynchronously` was defined only on base `Widget`, so a
      clock routed through it got `rawSetWidth` ONLY (width set, height left stale → no longer square → window
      mis-fit). Folding the synchronous behaviour back into the BASE `rawSetWidthSizeHeightAccordingly` (and
      deleting the parallel method + reverting the 3 call-sites) lets every override keep winning automatically,
      and confines the change to the one place that ever needed it. Robust (a future container that sizes children
      from its `_reLayout` gets the fixed point for free) and a smaller diff. NB `settleLayoutsOnceAfter` must be
      non-underscore — lint rule A forbids `_`-methods from calling `recalculateLayouts`, which it legitimately does.
    - **Verified:** build syntax 0 + lint A/B/C/D 0; suite **165/165 at dpr1, dpr2, and WebKit**; one **benign
      recapture** (`macroDuplicatedInspectorDrivesCopiedTargetOnly` — `settleLayoutsOnceAfter` joins the inspector
      member list → scrollbar-thumb proportion shifts; image_1 byte-identical, image_2/3 re-captured both
      densities; pixel-diff confirmed it's the list thumb only). The clock family
      (`macroClockInWindowKeepsSquareOnResize`, `macroDocumentScrollsMixedTextAndClocks`,
      `macroWindowWithAClockInAWindowConstructionTwo`) all PASS. **Still UNCOMMITTED** until soak + boot pass.
    - Also surfaced (FIXED in #18): the `createErrorConsole` recovery loop turned any in-recalc `_reLayout` throw
      into a FREEZE that masked the primary error — now the recalc catch is non-flushing + convergent and recovery
      is deferred outside the flush (see the slice2 plan §2d). ZOMBIE GOTCHA: leftover Chromes starve the box —
      `pkill` before every suite run. TOOL GOTCHA: no `timeout(1)` — use `perl -e 'alarm N; exec @ARGV'`.
  - **(historical, superseded by the bullet above) ATTEMPTED + the deeper wall (2026-06-19):** implemented exactly that silent/synchronous-sizing fix —
    a `rawSetWidthAndReLayoutSynchronously` (= `rawSetWidth` + a synchronous `@_reLayout()` instead of
    `@invalidateLayout()`), used by stack + window `_positionAndResizeChildren`, plus the stack/window `_reLayout`.
    Result: it **converges in ISOLATION** — all the originally-stalling tests
    (`macroWrappingTextFieldResizesOK`, `macroSimpleDocumentHandlesOldInspector`, `macroMovingSliders…`,
    `macroDuplicateComplexWidgetRidesHand`, `macroAddEditSaveRenameRemoveProperty`) pass byte-exact, ~6s
    each — **but it HANGS under PARALLEL LOAD.** The full suite freezes shards on
    `macroAddingWidgetToListUpdatesScroll` / `macroSimpleDocumentManualBuildAndScroll` /
    `macroMultilineTextInputScrollsWell` / `macroPinnedMenu…` etc. — each of which runs in ~6s *isolated* but
    makes **no progress for 5 min** under even **2-shard** load (a 50× gap = not slowness — a
    **cadence-dependent non-convergence**: under heavy cycles `playQueuedEvents` drains several events before
    a repaint, so multiple synchronous re-fits compound into a loop that the one-event-per-cycle isolation
    cadence never hits). This is the determinism-flake class (DETERMINISM.md §2B) manifesting as a HANG. So
    the synchronous-sizing fix is **necessary but not sufficient**: a viable Slice 2 needs **load-invariant
    convergence** (the re-fit must reach a fixed point regardless of how many events drained this cycle) —
    the genuine deferred-layout model-completion, a dedicated determinism-expert effort with a torture soak,
    not a localized fix. The fix attempt was REVERTED; Slice 1 remains the banked foundation. (One real
    pixel diff was also seen, `macroWindowWithAClockInAWindowConstructionTwo` — moot until convergence.)

---

## Findings that shape the design (from the 3 surveys)

**Re-fit machinery (survey 1).** Three primitive bodies: `ScrollPanelWdgt.adjustContentsBounds`
(`:266`) + `adjustScrollBars` (`:114`); `SimpleVerticalStackPanelWdgt.adjustContentsBounds` (`:83`, no
scrollbars); `WindowWdgt.adjustContentsBounds` (`:397`, no scrollbars). They are reached by ~25 **inline,
synchronous** call-sites + named wrappers (`refitContentsAndScrollBars` `ScrollPanelWdgt:249`,
`_reLayOutAfterContainedPanelChange` `:262`, `refreshScrollPanelWdgtOrVerticalStackIfIamInIt`
`Widget:1536`), child-side notifications (`childGeometryChanged` stack `:73`; the
`amIDirectlyInsideNonTextWrappingScrollPanelWdgt`-guarded inline blocks in `Widget.fullRawMoveBy:1172`
and `Widget.rawSetExtent:1531`), drop/grab handlers (`PanelWdgt.reactToDropOf/reactToGrabOf/childRemoved`
+ `ScrollPanelWdgt` overrides), and collapse hooks (`WindowWdgt.childCollapsed/childUnCollapsed`). The
re-entrancy guard `_adjustingContentsBounds` is hand-rolled in all 3 classes. **No macro calls any of
these** — every occurrence in `tests/**/*_automationCommands.js` is in a narrative comment. 24 macro
tests are the behavioural guards. **The one true branch to preserve:** `ListWdgt` opts OUT of the
contained-panel *notification* (`_reLayOutAfterContainedPanelChange` returns `nil`, `ListWdgt:108`) but
still re-fits on its own drops/grabs.

**`add` layering (survey 2).** `add` (`Widget:2253`) → `addRaw` (`:2278`) → `silentAdd` (`:2328`) →
`addChild`. Crucially **`addRaw` is already non-settling and full-featured**: it invalidates layout +
fires `iHaveBeenAddedTo`/`childAdded`/`childRemoved`, but never calls `recalculateLayouts`. `silentAdd`
is the pure tree-link (no invalidate, no callbacks). The set of callers that run **inside a layout pass**
(so must NOT trigger a self-settle) is **small: 13 internal + 2 per-frame-overlay = 15 sites**, clustered
in 6 methods: `addOrRemoveAdders` + `showResizeAndMoveHandlesAndLayoutAdjusters` (Widget), the
`reactToDropOf` family (WindowWdgt:279, BasementOpenerWdgt:47→PanelWdgt.addInPseudoRandomPosition:117,
IconicDesktopSystemFolderShortcutWdgt:7, StretchableCanvasWdgt:176, SimpleDropletWdgt:28,
LayoutElementAdderOrDropletWdgt:87/89/98), and `addPinoutingWidgets`/`addHighlightingWidgets`
(WorldWdgt:1113/1137, post-flush per-frame). None of the `iHaveBeenAddedTo`/`childAdded`/`childRemoved`
implementations re-enter add, so the core's synchronous callbacks won't re-flush.

**`implementsDeferredLayout` blocker (survey 3).** `implementsDeferredLayout: -> @_reLayout != Widget::_reLayout`
(`Widget:3807`; line-drifted from the docs' `3756`) — a pure method-identity inference, no state. **Two**
read sites: (A) `rawSetWidthSizeHeightAccordingly:686` (gates an extra `invalidateLayout` on a sized
child); (B) `subWidgetsMergedFullBounds:1019` — **the load-bearing one**: a child that
`implementsDeferredLayout` contributes only `child.bounds` (its own viewport rect), else
`child.fullBounds()` (its whole subtree). The whole scroll/stack family currently reports `false`. Giving
`ScrollPanelWdgt` any `_reLayout` flips it to `true`, so a **nested** scroll panel would contribute only
its viewport (not its overflowing scrolled subtree) to the outer's content size → the outer's scroll
range/scrollbars change → `macroNestedScrollPanelsRouteWheel` (+ the scroll family) diverge. **Verdict:
TRACTABLE** — the coupling is 2 read sites in 1 file, the flag is inferred not stateful, and the failure
mode is deterministic (the byte-exact suite catches it, not a dpr2 flake). **Avoid** unifying the
`:1019` branch (the 2026-06-19 Path-A experiment already proved that regresses 16→18, incl.
`macroScrollBarsTrackContentChange`).

---

## Design decisions

### D1 — the re-fit chokepoint (Phase 2)

Funnel the ~25 inline re-fit triggers + the child-reaching hooks through **one private polymorphic entry
point**, so there is a single seam Phase 3b can later flip onto the cycle.

- **Per-type implementation stays**, renamed private: `_positionAndResizeChildren` (ScrollPanel/Stack/Window),
  `_reLayoutScrollbars` (ScrollPanel only). Centralize the `_adjustingContentsBounds` re-entrancy guard.
- **One private "my contents changed → re-fit me" entry** — `_reLayoutChildren()` — defined on
  `ScrollPanelWdgt` (= `adjustContentsBounds` + `adjustScrollBars`), `SimpleVerticalStackPanelWdgt`
  (= `adjustContentsBounds`), `WindowWdgt` (= `adjustContentsBounds`). It is **duck-typed (NOT declared on
  Widget base)** and reached cross-receiver with the codebase's `?()` soak (`@parent?._reLayoutChildren?()`
  / `@parent.parent._reLayoutChildren?()`), matching the existing optional container-hook idiom
  (`reactToDropOf?`, `childGeometryChanged?`, the old `adjustContentsBounds?` guard). A Widget-base no-op
  was tried first but was rejected: it adds a member to EVERY widget's inspector member-list, which
  recaptures `macroDuplicatedInspectorDrivesCopiedTargetOnly` (the "show inherited" inspector test) — the
  soak keeps the content-change reroute byte-identical instead. Every **content-change**
  `adjustContentsBounds()/adjustScrollBars()` pair (add / reactToDropOf / reactToGrabOf / childRemoved /
  addMany / showResizeAndMoveHandlesAndLayoutAdjusters / rawSetExtent) now funnels through it; **scroll-
  POSITION** gestures (wheel / autoScroll / scrollbar-drag / scrollCaretIntoView / scrollTo) keep their
  own direct calls. **DONE 2026-06-19 (Slice 2.1), byte-identical at dpr1 (165/165).**
- **One private child-initiated funnel** — keep `refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (rename
  `_refreshContainerAfterMyChange`); the `amIDirectlyInside…`-guarded inline blocks in
  `fullRawMoveBy`/`rawSetExtent` and `childGeometryChanged` all route to the enclosing container's
  `_reLayoutChildren()`.
- **Preserve the ListWdgt opt-out** as the single explicit branch (contained-panel *notification* vs.
  own drop/grab re-fit) — do not collapse it away.
- These are the methods the lint marks private; **none is macro-reachable today**, so this is byte-safe
  (verify suite + gauntlet anyway).

### D2 — naming scheme + lint (Phase 2)

- Adopt **leading `_`** as the private convention; teach `check-layering.js`'s `isLowLevel` to recognize
  `/^_/` (alongside the existing `raw*`/`silent*`/`__*`/`*Core`/`*Layout`). Register the chokepoint
  members + `refitContentsAndScrollBars`/`_reLayOutAfterContainedPanelChange`/`childGeometryChanged`/the
  `amIDirectlyInside*` predicates as private.
- **Extend the lint to scan macro sources** (`Fizzygum-tests/tests/**/*_automationCommands.js`): a macro
  calling a private (`.<private>(`) fails the build. This is the gate that would have caught the original
  16-macro mess; it must land before Phase 3 so it guards the risky work.

### D3 — public `add` + `addRaw` self-settling, over a private core (Phase 3a)

- Rename today's **non-settling** `addRaw` body to a private core `_addCore` (full semantics: invalidate
  + `iHaveBeenAddedTo`/`childAdded`/`childRemoved`, NO settle). `silentAdd` stays as the lower pure-tree
  core.
- Public `add` = shadow/world bookkeeping + `_addCore` + `recalculateLayouts` (via the existing
  `mutateGeometryThenSettle`-style wrapper). Public `addRaw` = `_addCore` + settle. **Neither calls the
  other** (public→public is banned); the only duplication is the thin settle wrapper — acceptable.
- Route the **15 internal-layout call-sites** (survey 2 list) to `_addCore`. They currently use `add`;
  switching to `_addCore` preserves full semantics with no flush, and avoids the double-flush in the live
  drop path (`ActivePointerWdgt.drop` does `target.add` then `target.reactToDropOf` as separate steps).
- No `implementsDeferredLayout` interaction — this phase works while the re-fit is still inline at the
  chokepoint.

### D4 — move the chokepoint onto the cycle (Phase 3b)

- **Decouple the classification from `_reLayout` identity** before adding a `_reLayout`: introduce an
  explicit predicate/flag whose default reproduces today's `@_reLayout != Widget::_reLayout` partition
  **exactly**, and pin `ScrollPanelWdgt` (+ stack/window) to their *current* value. Minimal first cut: a
  `implementsDeferredLayout: -> false` override on `ScrollPanelWdgt` (preserves read-site-A and -B
  behaviour byte-for-byte) — fold into a cleanly-named flag.
- Then give `ScrollPanelWdgt` (and stack/window) a `_reLayout` that drives `_reLayoutChildren()` during
  `recalculateLayouts`, replacing the inline triggers. **Care:** it interacts with `ScrollPanelWdgt`'s
  overriding `rawSetExtent` (`:221`, which itself re-fits), the `_adjustingContentsBounds` guard, the
  `unless aPoint.equals @extent()` no-op guard (`:222`), and the soft-wrap pure-move reachability gap
  (`softwrap-…:254`). Ordering of `super` vs. the re-fit is the pixel-sensitive part.
- **Avoid** touching the `subWidgetsMergedFullBounds:1019` branch itself (proven regressor).

---

## Phase 3a — what actually shipped (corrects D3)

The split is as D3 described — `_addCore` (old `addRaw` body, non-settling, low-level per the lint:
`/^_/` + `/Core$/`), public `add` = `mutateGeometryThenSettle => shadow-bookkeeping + _addCore + remember`,
public `addRaw` = `mutateGeometryThenSettle => _addCore`, `mutateGeometryThenSettle` returns the thunk
value. But the **call-site routing in D3 was wrong on two counts**, corrected during implementation:

1. **The orphan guard replaces "route the 15 layout sites."** D3 assumed construction settles are harmless
   and only ~15 *layout-time* sites needed `_addCore`. False: construction settles CRASH (half-built widget
   reachable via children's `.parent`). The fix is the single `@isOrphan()` short-circuit in
   `mutateGeometryThenSettle` (above) — it neutralizes every construction `add`/setter at once. So almost
   nothing needed per-site routing.

2. **The drop / reactToDropOf family must STAY public `add` (do NOT route to `_addCore`).** Two reasons the
   survey missed: (a) `add`'s shadow bookkeeping is **load-bearing on drop** — for a non-world target it does
   `aWdgt.removeShadow()` (strips the drag shadow); for a world target `aWdgt.addShadow()` (the resting
   shadow). `_addCore` skips both, so routing a drop to it leaves the drag shadow stuck on the dropped
   widget. (b) `ActivePointerWdgt.drop` calls `target.add` **polymorphically** — `WindowWdgt.add` /
   `ScrollPanelWdgt.add` do essential work (retitle, contents delegation, re-fit); `_addCore` is only the
   base core and would bypass them. Drop/grab/`reactToDropOf`/`addInPseudoRandomPosition`/`addPinouting`/
   `addHighlighting` are all **event- or post-settle-frame handlers** (proven: they already call public
   `setExtent`/`setWidth` today, which would throw inside a layout pass), so their settles are fine and
   byte-safe (screenshots are taken after a frame yield). `addPinoutingWidgets`/`addHighlightingWidgets`
   run in `doOneCycle` AFTER `recalculateLayouts` (post-settle, pre-paint) — settling there is safe.

**The sites that genuinely needed `_addCore`** (all run INSIDE a `recalculateLayouts`/`_reLayout` pass):
`Widget.addAsSiblingBeforeMe`/`addAsSiblingAfterMe` (→ `@parent._addCore`; reached from `addOrRemoveAdders`
during layout), `Widget.showAdders`/`addOrRemoveAdders` (the `@_addCore new LayoutElementAdderOrDropletWdgt`),
`StringFieldWdgt._reLayoutSelf` (`@_addCore @text`), `LabelButtonWdgt.createLabel` + `MenuItemWdgt.createLabel`
(`@_addCore @label`; createLabel is driven by _reLayoutSelf), and the `ScrollPanelWdgt` constructor's three
`@addRaw @contents/@hBar/@vBar` (→ `@_addCore`; build innards during construction). Plus ONE callback fix:
`BasementOpenerWdgt.iHaveBeenAddedTo` did `@fullMoveTo` — and `iHaveBeenAddedTo` is fired by `_addCore`
INSIDE the add's settle, so it became `@fullRawMoveTo` (byte-equivalent: the outer settle re-lays-out a
freefloating position idempotently). The ~20 `_reLayoutSelf` overrides reachable via the base
`iHaveBeenAddedTo → @_reLayoutSelf()` are already lint-clean (rule A forbids a `/Layout$/` method calling a
public setter), so that indirect channel needed nothing.

**Latent issue noted here, FIXED in #18:** `WorldWdgt._recalculateLayoutsCore` wraps `_reLayout()` in try/catch
and on a throw called `createErrorConsole()` — full of public setters (`wm.setExtent`, `@add`,
`@errorConsole.fullMoveTo`) and running INSIDE `recalculateLayouts`, so it threw (re-entrancy) and masked the
real `_reLayout` error → freeze. Fixed not by converting `createErrorConsole` to raw setters but by the cleaner
documented alternative: the recalc catch now does only non-flushing convergence work and DEFERS recovery (the
console build + softReset + a loud `console.error`) to a next-cycle drain outside the flush; the
`Widget.invalidateLayout` guard is now a hard `throw`. See the slice2 plan §2b/§2d.

---

## Test oracle (canaries, in priority order)

`macroNestedScrollPanelsRouteWheel` (the direct nested-scroll case), `macroScrollBarsTrackContentChange`
(named Path-A regressor), then the scroll/stack family: `macroDocumentScrollsMixedTextAndClocks`,
`macroNoSpuriousScrollbarsOnScrollPanelResize`, `macroScrollPanelCaretBroughtIntoViewWhenMoved`,
`macroScrollPanelCoalesces*`, `macroSimpleDocument*`, `macroVerticalStackPanel*`,
`macroAddingWidgetToListUpdatesScroll`, `macroStackPanelLooseWhenEmptyTightWhenFilled`,
`macroWindowContent*`, `macroResizeWindowContainingInternalWindow`,
`macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow`. Per-phase verification:
full build (runs syntax + layering gates) → `run-all-headless.js --shards=5` at dpr1, `--dpr=2`,
`--browser=webkit`; Phase 3b additionally gets a torture soak. Failure mode is deterministic, so a wrong
move fails the same way every run and points at the reader.

## Why this order is safe

Phase 2 turns ~25 scattered triggers into ONE private seam (byte-safe; no macro reaches them). Phase 3a
makes `add`/`addRaw` self-settle over a core that already exists (today's `addRaw`), touching only 15
internal sites. Only Phase 3b touches the `implementsDeferredLayout` coupling — by then the re-fit is a
single seam, the macro-lint guards regressions, and the canaries are a deterministic oracle.
