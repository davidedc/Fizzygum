# Deferred-layout — re-fit chokepoint + public `add`/`addRaw` — design (Phase 1 output)

**Written 2026-06-19.** Companion to `softwrap-deferred-layout-conversion-plan.md`,
`deferred-layout-16-macro-breakages.md` (RESOLUTION + privates-hygiene backlog), and
`deferred-layout-path-a-design.md`. This is the design-of-record for the remaining phases of the
deferred-layout migration. It is the output of a 3-survey design pass; it is meant to be executable cold.

## Goal (the agreed end state)

Top-level callers (macros, apps, event handlers) never call a layout/re-fit method. A public mutation
leaves a consistent world by itself. Concretely:
- the scroll/stack/window **content re-fit** runs via the normal `recalculateLayouts`/`doLayout` cycle
  (mark-dirty → settle), not via the ~25 scattered **inline** `adjustContentsBounds`/`adjustScrollBars`
  calls + child-reaching hooks it uses today;
- **both** `add` and `addRaw` are public and **self-settle** (re-fit via `recalculateLayouts`);
- all the re-fit/notification machinery is **private**, registered in the layering lint, and the lint
  also scans the macro sources so a macro can't call a private.

## Phase map (risk rises monotonically; each phase is the enabler for the next)

- **Phase 1 (this doc):** design + feasibility. DONE.
- **Phase 2:** ✅ DONE 2026-06-19. `_reFitToContents` chokepoint (Slice A, duck-typed + `?()`-soaked);
  concrete re-fit machinery privatized to leading-`_` (Slice B: `_adjustContentsBounds` /
  `_adjustScrollBars` / `_refitContentsAndScrollBars` / `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` /
  `_amIDirectlyInside*`; the one inspector test `macroDuplicatedInspectorDrivesCopiedTargetOnly`
  recaptured — benign inherited-member-list shift); `check-layering.js` now recognizes `/^_/` (A/B/C)
  **plus a new rule D** scanning macro sources for `_`-private calls (Slice C). Verified 165/165 at
  dpr1/dpr2/WebKit; lint = 487 src + 165 macros, 0 violations; negative-tested (a planted
  `._reFitToContents()` is caught). The duck-typed hooks (`childGeometryChanged` /
  `reLayOutAfterContainedPanelChange` / `reactToDropOf` / `childAdded`…) stay non-`_` pending the
  base-declared reorg (deferred to plan-end).
  - **RECAPTURE GOTCHA (will recur in 3b):** `capture-macro-test-references.js` WRITES the new refs but
    LEAVES the old (tracked) ones → the build's stray/duplicate-ref gate aborts. After a recapture,
    delete the now-stale old refs (`.js`+`.png`) so there's exactly one per image+density.
  - **END-OF-PLAN rule-D tightening (owner-requested):** rule D currently TOLERATES `reLayout()` + the
    raw/silent construction read-back idiom (`silentRawSetWidth`→`breakTextIntoLines`→`silentRawSetHeight`
    →`reflowText`, in macroBareTextWidgetDropShadowRestAndDrag / macroBoxTransparencyAndColorChanging /
    macroTextRelayoutsCorrectlyOnResize). At plan-end, give these public self-settling alternatives and
    extend rule D's `MACRO_FORBIDDEN_CALL` to also forbid `raw*`/`silent*`/`fullRaw*`/`/Layout$/`.
- **Phase 3a:** `add` + `addRaw` public & self-settling, over a private non-settling core. No blocker.
- **Phase 3b:** move the chokepoint onto the `doLayout` cycle (solve `implementsDeferredLayout`). Hard;
  determinism-sensitive; own review.

---

## Findings that shape the design (from the 3 surveys)

**Re-fit machinery (survey 1).** Three primitive bodies: `ScrollPanelWdgt.adjustContentsBounds`
(`:266`) + `adjustScrollBars` (`:114`); `SimpleVerticalStackPanelWdgt.adjustContentsBounds` (`:83`, no
scrollbars); `WindowWdgt.adjustContentsBounds` (`:397`, no scrollbars). They are reached by ~25 **inline,
synchronous** call-sites + named wrappers (`refitContentsAndScrollBars` `ScrollPanelWdgt:249`,
`reLayOutAfterContainedPanelChange` `:262`, `refreshScrollPanelWdgtOrVerticalStackIfIamInIt`
`Widget:1536`), child-side notifications (`childGeometryChanged` stack `:73`; the
`amIDirectlyInsideNonTextWrappingScrollPanelWdgt`-guarded inline blocks in `Widget.fullRawMoveBy:1172`
and `Widget.rawSetExtent:1531`), drop/grab handlers (`PanelWdgt.reactToDropOf/reactToGrabOf/childRemoved`
+ `ScrollPanelWdgt` overrides), and collapse hooks (`WindowWdgt.childCollapsed/childUnCollapsed`). The
re-entrancy guard `_adjustingContentsBounds` is hand-rolled in all 3 classes. **No macro calls any of
these** — every occurrence in `tests/**/*_automationCommands.js` is in a narrative comment. 24 macro
tests are the behavioural guards. **The one true branch to preserve:** `ListWdgt` opts OUT of the
contained-panel *notification* (`reLayOutAfterContainedPanelChange` returns `nil`, `ListWdgt:108`) but
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

**`implementsDeferredLayout` blocker (survey 3).** `implementsDeferredLayout: -> @doLayout != Widget::doLayout`
(`Widget:3807`; line-drifted from the docs' `3756`) — a pure method-identity inference, no state. **Two**
read sites: (A) `rawSetWidthSizeHeightAccordingly:686` (gates an extra `invalidateLayout` on a sized
child); (B) `subWidgetsMergedFullBounds:1019` — **the load-bearing one**: a child that
`implementsDeferredLayout` contributes only `child.bounds` (its own viewport rect), else
`child.fullBounds()` (its whole subtree). The whole scroll/stack family currently reports `false`. Giving
`ScrollPanelWdgt` any `doLayout` flips it to `true`, so a **nested** scroll panel would contribute only
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

- **Per-type implementation stays**, renamed private: `_adjustContentsBounds` (ScrollPanel/Stack/Window),
  `_adjustScrollBars` (ScrollPanel only). Centralize the `_adjustingContentsBounds` re-entrancy guard.
- **One private "my contents changed → re-fit me" entry** — `_reFitToContents()` — defined on
  `ScrollPanelWdgt` (= `adjustContentsBounds` + `adjustScrollBars`), `SimpleVerticalStackPanelWdgt`
  (= `adjustContentsBounds`), `WindowWdgt` (= `adjustContentsBounds`). It is **duck-typed (NOT declared on
  Widget base)** and reached cross-receiver with the codebase's `?()` soak (`@parent?._reFitToContents?()`
  / `@parent.parent._reFitToContents?()`), matching the existing optional container-hook idiom
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
  `_reFitToContents()`.
- **Preserve the ListWdgt opt-out** as the single explicit branch (contained-panel *notification* vs.
  own drop/grab re-fit) — do not collapse it away.
- These are the methods the lint marks private; **none is macro-reachable today**, so this is byte-safe
  (verify suite + gauntlet anyway).

### D2 — naming scheme + lint (Phase 2)

- Adopt **leading `_`** as the private convention; teach `check-layering.js`'s `isLowLevel` to recognize
  `/^_/` (alongside the existing `raw*`/`silent*`/`__*`/`*Core`/`*Layout`). Register the chokepoint
  members + `refitContentsAndScrollBars`/`reLayOutAfterContainedPanelChange`/`childGeometryChanged`/the
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

- **Decouple the classification from `doLayout` identity** before adding a `doLayout`: introduce an
  explicit predicate/flag whose default reproduces today's `@doLayout != Widget::doLayout` partition
  **exactly**, and pin `ScrollPanelWdgt` (+ stack/window) to their *current* value. Minimal first cut: a
  `implementsDeferredLayout: -> false` override on `ScrollPanelWdgt` (preserves read-site-A and -B
  behaviour byte-for-byte) — fold into a cleanly-named flag.
- Then give `ScrollPanelWdgt` (and stack/window) a `doLayout` that drives `_reFitToContents()` during
  `recalculateLayouts`, replacing the inline triggers. **Care:** it interacts with `ScrollPanelWdgt`'s
  overriding `rawSetExtent` (`:221`, which itself re-fits), the `_adjustingContentsBounds` guard, the
  `unless aPoint.equals @extent()` no-op guard (`:222`), and the soft-wrap pure-move reachability gap
  (`softwrap-…:254`). Ordering of `super` vs. the re-fit is the pixel-sensitive part.
- **Avoid** touching the `subWidgetsMergedFullBounds:1019` branch itself (proven regressor).

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
