> **ARCHIVED — COMPLETE (2026-07-17 restructure).** CAMPAIGN COMPLETE 2026-07-17 — every cluster ✅ or LEAVE-verdicted; Phase ε closed the last open set
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Type-test elimination — decouple widgets from subclass identity (codebase-wide, capability-first)

The live campaign backlog for removing *type-test-then-branch* smells (`if x instanceof FooWdgt then A else
B`, and its predicate twin `if x.isFoo?()`) across `src/`. It is the **codebase-wide superset** of the
Widget-scoped `widget-identity-decoupling-plan.md` (which it absorbs) and the true-polymorphism part of Phase 5
in `oo-smells-refactoring-backlog.md`. Executable cold; grep symbols (line numbers drift).

> **CAMPAIGN COMPLETE (2026-07-17).** Every cluster carries ✅ or a recorded LEAVE verdict; Phase ε — the last
> open set — executed and closed (`a68677c6` → `0df1d796`). This doc remains the case-law record: the decision
> framework, the LEAVE rationales, and the prior-art patterns govern any future type-test that appears.

## Why / the smell
A type test that drives a branch is *missed polymorphism*: behaviour that varies by type should live on the
type, so the caller names an intent and the right thing happens. Owner directive (2026-06-22): **clean/elegant
code is the priority; inspector recapture is a non-cost** — never contort to avoid it.

## Decision framework (capability-first) — overrides the old "predicates are a dead end" line
The earlier "5c" attempt mechanically swapped `instanceof X → x.isX?()` over ~18 Widget sites and was reverted
for two reasons of very different weight: **(b) a 37-test regression** — an *execution/faithfulness* failure (an
unfaithful swap; not a design flaw), and **(a) a design-bar** — "`isScrollPanel?()` is only cosmetically better
than `instanceof ScrollPanelWdgt`," which was over-generalized into "predicates are a dead end." The tell that
(a) is too broad: the kept work (5a `acceptsSmartPlacedWidgets`, 5b `isLayoutDecoration`) *uses queries* — the
real difference is **capability-named (kept) vs type-named (rejected)**. So (owner decision 2026-06-22) we adopt:

Ranked best→worst for a type-test; pick the highest that fits, **faithfully**:
1. **Move the behaviour — the branch disappears.** *Notify-hook* (act-on-other): `if @other instanceof X then
   @other.foo()` → unconditional `@other.foo?()`. *Override-hook* (self-branch): `if @ instanceof X then @doX()`
   → `Widget` calls `@hook?()`, `X` implements it. **Default choice.**
2. **Capability/role query, named for the CAPABILITY not the class** (`isLayoutDecoration`, `acceptsPenDrawing`,
   `imposesRatioConstraintOnDroppedChildren`). For genuine collection *filters* and "what's my context" structural
   queries where there is no behaviour to move. NEVER a type-named predicate (`isScrollPanel` ← the 5c dead end).
3. **Singleton identity** — `@parent == world`, `@root() == world.hand`. For "is it THE unique X"; not a type-test.
4. **LEAVE** (see below).

- **Placement:** new hooks/queries live **on the answering subclass(es), dispatched via `x.method?()`** — nothing
  as a no-op/`-> false` default on the God-class `Widget` (it is under active Phase-6 decomposition; adding
  defaults feeds the smell). A shared default may land on a *narrow family base* where one exists.
- **Faithfulness rule (hard):** each conversion fires for *exactly* the original `instanceof`'s object set — mind
  inheritance (a hook on a base is inherited, mirroring is-a reach). Do NOT broaden/narrow the set. Expect **zero
  recapture**; any red test is a faithfulness bug — localize it. (This is what 5c violated.)
- **Capability-not-type naming** is the line between 5b (kept) and 5c (reverted).

## Verification (per cluster/commit)
`fg build` (`0 violations (A/B/C/D/E/F)` + `done!!!`) → `fg gauntlet` (dpr1/dpr2/webkit 165/165 + `APPS OK`). A
cluster that DELETES an inspector-visible `Widget` method → one benign recapture of
`macroDuplicatedInspectorDrivesCopiedTargetOnly` (`fg recapture …`). ADDING a method to a class whose instances
are *inspected* by a test (e.g. the StringWdgt family — not just the usual RectangleWdgt inspector test) likewise
recaptures the tests that screenshot that class's *scrolled* member list (the new row sorts below the visible top,
so `image_1` still matches but scrolled shots shift) — also benign, also `fg recapture` (the caret cluster hit 4).
A cluster that changes WHEN/HOW layout or input fires (not a pure boolean swap) → also a clean-env dpr2 soak. `--homepage` boot leg for homepage-included
code. One cluster ≈ one commit; push only after the end-of-campaign review.

## Prior art — DONE (do not redo)
`5a` `068081de` smart-placer→`acceptsSmartPlacedWidgets`/`smartPlace`; `5b` `4b8ff5d8`
`WindowWdgt`→`isWindow`, `Handle/Caret`→`isLayoutDecoration`; exemplar `c1976e5b` `childGeometryChanged`
notify-hook; Cluster A `770f4526` `_reLayOutAfterContainedPanelChange` (+`ListWdgt` opt-out, deleted
`amIPanelOfScrollPanelWdgt`); Cluster C `4c684991` self-`instanceof ScrollPanelWdgt`→`_reLayoutChildrenAndScrollbars?`.
This session `a581b03b` folded `newParentChoice*` into `_reFitContainer` + gave `isWindow` a base default
(reconcile under δ/study). Pilot `b92345d9` adder/droplet (below).

## Cluster checklist
Status: ✅ done · ☐ todo · ⏳ study (Phase-6-entangled) · — leave. Re-grep each before touching.

### Phase β — capability/role queries (named for capability)
- ✅ **adder/droplet** `b92345d9` — `Widget.addOrRemoveAdders` ×5 → `isLayoutAdderOrDroplet?()` on `LayoutElementAdderOrDropletWdgt`.
- ✅ **fanout-pin** — `mixins/ContainerMixin.coffee:26`, `mixins/ControllerMixin.coffee:23`, `patch-programming/FanoutWdgt.coffee:36` → `isConnectionPin?()` on `FanoutPinWdgt` (role-named, not the class; 3 sites incl. the input-routing loop).
- ✅ **last-focus tracking** — `ActivePointerWdgt.coffee:254/562` → `excludedFromLastFocusTracking?()` on `HorizontalMenuPanelWdgt` (negative capability on the special class, no Widget base).
- ✅ **glass-box wrap idempotency** — `HorizontalMenuPanelWdgt.coffee:28`, `ToolPanelWdgt.coffee:30` → `isGlassBoxWrapper?()` on `GlassBoxBottomWdgt` (the `ActivePointerWdgt` grab-inflate site left for γ).
- ✅ **ratio-constraint drop/grab** — 6 sites (`KeepsRatioWhenInVerticalStackMixin` grab+drop, `Example3DPlotWdgt` justDropped/holderWindowJustDropped + holderWindowJustBeenGrabbed/justBeenGrabbed) → two container capabilities on `SimpleVerticalStackPanelWdgt`: `imposesRatioConstraintOnDroppedChildren?()` (`-> true`, overridden `-> false` on `WindowWdgt` — reproduces the DROP `… and !(whereIn instanceof WindowWdgt)` exclusion exactly, since `WindowWdgt extends SimpleVerticalStackPanelWdgt`) and `releasesRatioConstraintOnGrabbedChildren?()` (`-> true`, NOT overridden — the GRAB sites include windows). Used `whereIn?.…?()`/`whereFrom?.…?()` to preserve the `instanceof` nil→false. Killed the IS-A-minus-subclass smell. Byte-identical, zero recapture.
- ✅ **entry fields (`Widget.allEntryFields`)** — `instanceof StringWdgt or instanceof SimplePlainTextWdgt` (2nd clause already redundant: SimplePlainTextWdgt is-a StringWdgt) → `each.isEditable and each.isTextEntryField?()` (`isTextEntryField -> true` on StringWdgt, family-wide; faithful = the old `instanceof StringWdgt`). **`PanelWdgt:78` SPLIT OUT to ε** (it tests the narrower single class `instanceof SimplePlainTextWdgt`; reusing `isTextEntryField` would broaden it, and a one-class predicate there would be cosmetic). Benign recapture of 3 StringWdgt-inspecting tests (member list grew by `isTextEntryField`).
- ✅ **pen surface** — `PenWdgt.coffee:28` → `acceptsPenDrawing?()` on `CanvasWdgt`+`ActivePointerWdgt`.
- ✅ **basement** — `TreeNode.coffee:168/174/182` → `== world.basementWdgt` (singleton identity, level 3 — the basement is a boot-created singleton with no subclasses; cleaner than a predicate).
- ✅ **desktop-icon family** — 3 `instanceof WidgetHolderWithCaptionWdgt` sites (`IconicDesktopSystemLinkWdgt.moveOnTopOfTopReference`, `WorldWdgt._reLayoutDesktop`, `GridPositioningOfAddedShortcutsMixin.add`) → `isDesktopIcon?()`/`participatesInIconGrid?()` on `WidgetHolderWithCaptionWdgt`. `participatesInIconGrid` overridden `-> false` on `BasementOpenerWdgt` (folds in `!(aWdgt instanceof BasementOpenerWdgt)` — the basement opener IS an icon but the desktop places it itself, not the grid). The `_reLayoutDesktop` furniture-singleton finds (`instanceof BasementOpenerWdgt/AnalogClockWdgt` at :1437/:1447) stay (LEAVE set). Byte-identical, zero recapture.
- ✅ **shortcut-to-self** — `Widget.coffee:~2125` → `isShortcutTo?(w)` on `IconicDesktopSystemShortcutWdgt` (folds the `target == @` check in).
- ✅ **menu detection** — `ActivePointerWdgt.coffee:89/388` → `isMenu?()` on `MenuWdgt` (inherited by Prompt/SaveShortcutPrompt). The `Wallpaper`/`StringWdgt` menu-tick sites are the separate γ notify-hook cluster.
- — **hierarchy-scaffold** — `Widget.getHierarchyMenuWidgets:~3124` → moved to ε; **ε verdict 2026-07-17: LEAVE** (see the LEAVE section). On inspection it is a compound of THREE parent-aware structural pairings (6 `instanceof`: `SimpleVerticalStackPanelWdgt`-in-`SimpleVerticalStackScrollPanelWdgt`, `PanelWdgt`-in-`ScrollPanelWdgt`, `ScrollPanelWdgt`-in-`FolderWindowWdgt`) over overlapping class hierarchies (ScrollPanel is-a Panel). A faithful full de-`instanceof` needs ~6 mutually-checking child+parent capabilities, and the parent check must stay call-time dynamic (a construction-time `isInternalScaffolding` flag would diverge under re-parenting). Same topology flavour as the ε scroll-structure set.
- ✅ **handle-initiated geometry** — `Widget.coffee:~1343/1562` → `changeShouldRememberFractionalGeometry?()` on `HandleWdgt` (the separate find-handle site landed in ε — filter on `m.updateVisibility?`).

### Phase α — capability reuse (per-site faithfulness; NOT a blanket reuse)
- ✅ **overlay-chrome** — mapped PER SITE (the sets genuinely differ — the 5c trap): **{Caret,Handle}** (`WindowWdgt.add` content detection) → `isLayoutDecoration?()` (exact reuse); **{annotation,Handle} ×4** (`ScrollPanelWdgt`/`ToolPanelWdgt`/`HorizontalMenuPanelWdgt`/`StretchableWidgetContainerWdgt` add) → new `attachesToScrollFrameDirectly?()` on `ModifiedTextTriangleAnnotationWdgt`+`HandleWdgt`; **{Caret}-only ×3** (`ActivePointerWdgt`, `PanelWdgt`, `SimplePlainTextWdgt`) → `m != world.caret` (SINGLETON identity — the caret is created one-at-a-time and destroyed before replace, so for a child `instanceof CaretWdgt` ⟺ `== world.caret`; reusing `isLayoutDecoration` would have WRONGLY excluded Handle too); **{Highlighter,Caret}** (`Widget.add` world drop-shadow) → new negative `skipsAddShadowManagement?()` on `HighlighterWdgt`+`CaretWdgt`. All chrome classes have no subclasses → each capability is exact. Byte-identical, zero recapture. The {Handle}-only find-handle (`Widget.setLayoutSpec:~608`) landed in ε (filter on `m.updateVisibility?`); `MacroToolkit:576` stays (LEAVE — harness locator); the `Widget.add` `instanceof ToolTipWdgt` self-exclusion is a separate ToolTip concern (not chrome).
- ✅ **dead commented-out instanceof** — deleted the dead `#if … instanceof` blocks: `WorldWdgt.checkARectWithHierarchy` (`instanceof SliderWdgt` debugger guard), `Widget` paint-bounds (the `instanceof MenuWdgt` containsPoint(10,10) debug guard + its 2 sibling dead debug guards, removed as one obviously-dead cluster), `MenuWdgt.maxWidthOfMenuEntries` (the `@parent instanceof PanelWdgt` / `scrollPanel instanceof ScrollPanelWdgt` width block). Comment-only; byte-identical.

### Phase γ — move-behaviour hooks
- ✅ **WindowWdgt title-bar buttons** — `buttons/{Close,Edit,External,Internal}IconButtonWdgt.coffee` → Close/Edit notify the window via new `closeButtonInBarPressed?`/`editButtonInBarPressed?` (Close internalizes the window's `contents?→closeFromWindowBar:close` branch and falls back to `@parent.close()` for a non-window container — faithful to the old `else`); External/Internal call the existing WindowWdgt `makeInternal?`/`makeExternal?` on the grandparent via `?()`. All four `instanceof WindowWdgt` gone; the grandparent reach stays (Demeter is a separate pre-existing smell).
- ✅ **enable/disable Drags/Drops/Editing bubble** — 6 sites (`SimpleVerticalStackScrollPanelWdgt`, `StretchablePanelWdgt`, `StretchableWidgetContainerWdgt`, each enable+disable) → `@parent.coordinatesDragsDropsAndEditingForChildren?()`, with that capability (`-> true`) on exactly the three coordinator classes `SimpleDocumentWdgt`/`StretchableWidgetContainerWdgt`/`SimpleSlideWdgt` (NOT the `StretchableEditableWdgt` base, preserving the `instanceof SimpleSlideWdgt` distinction). GOTCHA: the plan's naive `@parent?.enableDragsDropsAndEditing?(@)` is WRONG — `Widget` has a base `enableDragsDropsAndEditing`, so a bare notify would bubble to ANY parent; the capability query keeps the bubble to the coordinator (this is the 5c broadening trap). Verified no cross-pairing (StretchablePanel only ever under a container; SVSSPW under SimpleDocument or `world`; container under a slide only when a slide built it).
- ✅ **caret Tab/Enter** — `CaretWdgt` Tab `instanceof SimplePlainTextWdgt` → `tabInsertsSpaces?()` (`-> true` on SimplePlainTextWdgt, is-a match); Enter `constructor.name=="StringWdgt"` → `enterKeyAccepts?()` (`-> true` on StringWdgt, overridden `-> false` on TextWdgt + HhmmssLabelWdgt so ONLY the bare single-line StringWdgt accepts — exactly reproduces the old exact-class test across the whole 8-class StringWdgt tree). Killed the apologetic `:95` string-name comment. **BENIGN RECAPTURE** of 4 tests (AddEditSaveRenameRemoveProperty, InspectorScrollbarUnplugged, MovingSlidersSideways, WrappingTextFieldResizesOK): they inspect a StringWdgt and screenshot *scrolled* regions of its member list, which gained the new methods — `image_1` (list top) still matched; neither editing test even presses Tab/Enter, so it's a pure inspector member-list shift, not a behaviour change. Recaptured dpr1+dpr2 (shared with webkit).
- ✅ **glass-box child layout** — both `instanceof MenuItemWdgt` glass-box-sizing sites (`GlassBoxBottomWdgt` child layout, `HorizontalMenuPanelWdgt.add`) → `isTextSizedGlassBoxItem?()` (`-> true` on MenuItemWdgt, which has no subclasses = exact). A menu item is sized to its text; other glass-box contents become square thumbnails. Byte-identical, zero recapture.
- ✅ **menu-item unselect** — `MenuWdgt.unselectAllItems` `if item instanceof MenuItemWdgt then item.state = item.STATE_NORMAL` → behaviour-move `item.unselect?()` (MenuItemWdgt.unselect sets `@state = @STATE_NORMAL`). No other class defines `unselect`, so the firing set is exactly the old `instanceof MenuItemWdgt`. Byte-identical, zero recapture.
- ✅ **desktop reference creation** — `WindowWdgt.createReference` `@contents instanceof ScriptWdgt` → `@contents?.specialWindowReferenceShortcut?(@, referenceName)` (ScriptWdgt returns the script shortcut; other contents fall to super's default reference). `IconicDesktopSystemFolderShortcutWdgt.reactToDropOf` `droppedWidget instanceof IconicDesktopSystemLinkWdgt` → behaviour-move `droppedWidget.addSelfWhenDroppedIntoFolder?(folderContents)` (a desktop icon adds itself directly; anything else makes a reference). NB could NOT reuse `isDesktopIcon` here — it's on the broader `WidgetHolderWithCaptionWdgt`, so it would broaden past `IconicDesktopSystemLinkWdgt`. Byte-identical, zero recapture.
- **misc hooks** (several independent sites, done piecemeal):
  - ✅ **menu-tick** — `Wallpaper.setPattern` + `StringWdgt.setFontName` `menuItem.parent instanceof MenuWdgt` → `menuItem.parent.isMenu?()` (reuses the menu-detect `isMenu`; `menuItem?.parent?` guards nil). Byte-identical, zero recapture.
  - ✅ **window-content height** — `WindowWdgt.contentsRecursivelyCanSetHeightFreely` `!(@contents instanceof WindowWdgt)` → `!@contents.isWindow?()` (done in the isWindow cluster).
  - ✅ **external-link** — `ExternalLinkButtonWdgt.mouseClickLeft` `@parent instanceof SimpleLinkWdgt` (+ reaching into `@parent.outputTextArea`) → behaviour-move `@parent?.openExternalURL?()` (SimpleLinkWdgt opens its own URL; inherited by SimpleVideoLinkWdgt = exact set). Byte-identical, zero recapture.
  - ✅ **console menu** — `TextWdgt.addWidgetSpecificMenuEntries` `@parent.parent.parent instanceof ConsoleWdgt` (a 3-level reach) → behaviour-move `ConsoleWdgt.addRunMenuEntriesForText(menu, textWidget)`; the text calls `(@parent?.parent?.parent)?.addRunMenuEntriesForText?(menu, @)`, else adds its own "run contents". ConsoleWdgt has no subclasses = exact; also drops the great-grandparent Demeter reach. Byte-identical, zero recapture.
  - ✅ **autoscroll** — `ActivePointerWdgt` float-drag `newWdgt instanceof ScrollPanelWdgt` (+ the wantsDropOf/edge/startAutoScrolling logic inline) → behaviour-move `newWdgt.maybeStartAutoScrollForDraggedWidget?(draggedWidget, @position())` on ScrollPanelWdgt (inherited by all scroll-panel subclasses = exact). A faithful guard RELOCATION — the autoscroll TIMING lives in the untouched `startAutoScrolling` (saturation-deterministic). Byte-identical + a 10× dpr2 soak of `macroListWdgtAutoScrollsNearDraggedEdge` (10/10). Zero recapture.
  - ✅ **shortcut-drop** — `CreateShortcutOfDroppedItemsMixin.aboutToDrop`/`reactToDropOf` `instanceof IconicDesktopSystemShortcutWdgt` → `isDesktopShortcut?()` (`-> true` on IconicDesktopSystemShortcutWdgt, inherited by Folder/Script/Document shortcuts = exact). Byte-identical, zero recapture.
  - ✅ **keep-links-back** — `KeepIconicDesktopSystemLinksBackMixin.childAdded`/`childMovedInFrontOfOthers` `if theWidget instanceof IconicDesktopSystemLinkWdgt then theWidget.moveOnTopOfTopReference()` → `theWidget.moveOnTopOfTopReference?()` (that method lives ONLY on IconicDesktopSystemLinkWdgt, so `?()` = exact; no new method). Byte-identical, zero recapture.

### Phase δ — singleton identity
- ✅ **world / hand identity** — `ButtonWdgt:129`, `HandleWdgt:48`, `ActivePointerWdgt.grab` (refuse to grab the world), `Widget` grabsToParentWhenDragged/rootForFocus/lock-menu-label (`@parent == world`) + `isBeingFloatDragged`/`breakNumberOfRawMovesAndResizesCaches` (`== world.hand`). All `instanceof WorldWdgt`/`instanceof ActivePointerWdgt` → `== world`/`== world.hand` (established idiom: cf. PopUpWdgt, TreeNode).
- ✅ **isWindow base-default reconciliation** — DELETED `Widget.isWindow: -> false` (Arc-1's God-class base default); `isWindow` now lives ONLY on `WindowWdgt` (`-> true`), every site dispatching via `?()`. Converted all 5 usage sites: the 2 callers (`Widget.close` → `!@isWindow?() and @parent?.isWindow?()`; the close-vs-delete menu → `@isWindow?()`) + the 3 remaining raw `instanceof WindowWdgt` (`WidgetCreatorAndSmartPlacerOnClickMixin`, `WindowWdgt.contentsRecursivelyCanSetHeightFreely`, `WindowWdgt.recursivelyAttachedAsFreeFloating`). `instanceof WindowWdgt` is now fully gone from src behaviour code. Chose `?()` over a behaviour-move because it NET-REMOVES a method from Widget (a behaviour-move would still add a base method). Benign recapture of `macroDuplicatedInspectorDrivesCopiedTargetOnly` (the documented Widget-method-deletion inspector shift — the vanished isWindow row).

### ✅ Phase ε — the scroll-topology set (EXECUTED + CLOSED 2026-07-17; commits `a68677c6` → `0df1d796`)

**Premise correction (2026-07-17):** the stub deferred this on "dissolves under the God-class split" — that split is
NOT scheduled and three engine campaigns have since landed (proper-layouts, INV-2/down-walk, sizing-model unification,
up-edge endgame). Phase ε now stands on its own merits: convert what a faithful capability/identity query genuinely
improves, LEAVE what concrete-class topology states most clearly (this campaign's own bar — see the LEAVE section).
The deliverable is a verdict per cluster, not a mandatory conversion count.

**The verified census (2026-07-17 @ `d0286fb2` — 24 `instanceof` sites, 8 files; re-grep at arc start, the tree moves):**

- **Cluster A — the two topology helpers** (`Widget.coffee:3585` `_amIDirectlyInsideScrollPanelWdgt` — 3 instanceof:
  parent Panel-or-Stack AND grandparent ScrollPanel AND NOT ListWdgt — and `:3593` the NonTextWrapping refinement).
  7 callers: WindowWdgt collapse/uncollapse hooks ×2 (`:480/:495`), the settle-time up-edge (`Widget:2333`
  `_reFitMyTrackingContainerAfterSettle` — LOAD-BEARING, up-edge endgame arc), SimplePlainTextWdgt:81, CaretWdgt:303,
  Widget:3531. The helpers ARE the campaign-preferred shape already (one named query, `instanceof` centralised);
  candidate = convert their INSIDES to capabilities (`isScrollFrame?()` on ScrollPanelWdgt + a
  scroll-contents-panel capability, with the ListWdgt EXCLUSION preserved — it is LOAD-BEARING, a ListWdgt is-a
  ScrollPanelWdgt that must NOT count) or LEAVE as the two concrete-topology chokepoints.
- **Cluster B — drag/menu policy on parent identity** (`ToolPanelWdgt:117`, `SliderWdgt:267`
  (`ScrollPanelWdgt or PromptWdgt`), `PanelWdgt:86/:167/:177`, `ScrollPanelWdgt:145` (`parent instanceof ListWdgt`),
  `Widget:3537` + `:4061` (the lock-to-panels menu pair; `:4061` = `PanelWdgt and !ScrollPanelWdgt`)). Per-site set
  mapping MANDATORY (the 5c trap — the sets genuinely differ site to site; cf. overlay-chrome).
- **Cluster C — hierarchy-scaffold** (`Widget:3965-3967` `getHierarchyMenuWidgets`: 3 parent-aware structural
  pairings / 6 instanceof over OVERLAPPING hierarchies — ScrollPanel is-a Panel). A faithful de-instanceof needs ~6
  mutually-checking child+parent capabilities and the parent check must stay call-time dynamic (a stored flag
  diverges under re-parenting). STRONG LEAVE-candidate; the stub already leaned this way.
- **Cluster D — ScrollPanel content-type layout hooks** (`ScrollPanelWdgt:285/:372/:390/:429-430/:432` — contents
  is-a stack / text-wrapping panel branches inside `_positionAndResizeChildren` + the `isContentSizing` self-tests).
  ⚠ LAYOUT-DETERMINISM-SENSITIVE: these pick arrange branches; any conversion must be byte-identical under the full
  gauntlet (now incl. the `revisits`+`census` legs) — a polymorphic content hook (e.g.
  `contentsMeasuresOwnWidth?()`-style capabilities on the content classes) is the candidate shape; the self
  `instanceof SimplePlainText/StackScroll` pair (`:429-430`) could become a class-level `isContentSizing` override.
- **Cluster E — slider internals** (`SliderButtonWdgt:31/:71` parent is-a SliderWdgt; `SliderWdgt:267` also in B).
  Small; identity-of-role (`@parent == the slider that owns me`) may be truer than a capability.
- **Cluster F — singletons/leaves**: `PanelWdgt:92` (`SimplePlainTextWdgt and isEditable` click-to-caret forward —
  LEAVE-candidate, a narrower-than-`isTextEntryField` one-class predicate is cosmetic); `Widget:3918`
  (`ScrollPanelWdgt and takesOverAndMergesChildrensMenus` — the boolean already discriminates; candidate = drop the
  instanceof, keep the field test, IF no non-scroll class defines the field); `Widget:695` (`instanceof HandleWdgt`
  find-handle, the split-out δ leftover); `SimpleDocumentWdgt:110` (structural doc-assembly check — LEAVE-candidate);
  `MacroToolkit:619` (harness locator — LEAVE per the standing rule).

**EXECUTION LOG (2026-07-17; staging ran as spec'd — V0 fresh census → owner gate → per-cluster V1 → V2 close).**
The fresh V0 census @ `b601207d` confirmed all spec sites at unchanged lines AND surfaced 3 missed ε-scope sites
(`ScrollPanelWdgt:77/:82/:84` contents-type dispatch — folded into cluster D — and `MenusHelper:80`, cluster-E
flavour) plus out-of-ε leftovers (logged below). Owner gate sanctioned: the six core CONVERTs, F-3918
field-as-truth, B-145 delete-if-dead, the PanelWdgt trio centralization; everything else LEAVE. Every V1 step:
`fg presuite` 250/250 byte-exact at dpr1, 0 geometry violations, paint-truthful, zero recapture, no inspector churn.

- ✅ **cluster B** `a68677c6` — ToolPanelWdgt row-wrap width → `widthContentsMustFitWithin?()` on ScrollPanelWdgt
  (`-> @width()`, is-a exact); slider track-press jump-drag → `sliderTrackPressJumpsButton?()` on ScrollPanelWdgt +
  PromptWdgt (exact: SaveShortcutPromptWdgt extends MenuWdgt, not PromptWdgt); lock-to-panels menu gate →
  `childrenCanLockToMe?()` (`-> true` on the PanelWdgt family base, world included, matching "lock to desktop";
  `-> false` on ScrollPanelWdgt — the ratio-constraint opt-out precedent); PanelWdgt trio (:86/:167/:177) →
  centralized into `_amITheContentsPanelOfAScrollPanelWdgt` (LEAVE-with-cleanup; the ONE instanceof lives inside).
- ✅ **cluster D, sanctioned subset** `d2e8b033` — the :429-430 self-tests → class-level `isContentSizing()`
  (base `-> @isTextLineWrapping`; `-> true` on SimplePlainTextScrollPanelWdgt + SimpleVerticalStackScrollPanelWdgt —
  the override is load-bearing for a plain-text frame with soft-wrap OFF); `wantsDropOfChild` folder veto →
  `vetoesScrollPanelDrops?()` on FolderPanelWdgt (no subclasses = exact); `colloquialName` →
  `scrollPanelColloquialName?()` on FolderPanelWdgt ("folder") / ToolPanelWdgt ("toolbar"), strings preserved
  verbatim (drawn in menu/window labels).
- ✅ **cluster F** `4e4a6ee7` — Widget find-handle → filter on `m.updateVisibility?` (HandleWdgt-only = exact, the
  keep-links-back precedent). Widget menu-take-over → the FIELD is the single truth. ⚠⚠ the spec's convert-condition
  was FALSIFIED in-tree — SimplePlainTextPanelWdgt's constructor ALSO wrote the flag — but the write was DEAD (both
  reads were scroll-frame-scoped), so it was deleted with the instanceof; and because the Serializer stores own
  enumerables and `allParentsTopToBottomSuchThat` matches NEAREST-first (self included), an OLD saved document's
  restored flag would have made the text panel hijack its text's menu — a
  `SimplePlainTextPanelWdgt._afterDeserialization` hook strips the stale own-property (faithfulness preserved for
  old documents). Accepted disclosed edge: a runtime-flipped flag on any widget is now honored.
- ✅ **dead guard deleted** `0df1d796` — ScrollPanelWdgt._reLayoutScrollbars' `unless @parent instanceof ListWdgt`
  around `@changed()` (Morphic vintage, predates the ListWdgt rename): every list child-acquisition path (ctor
  contents+bars, add/addMany → @contents, drops, attach → add, listContents build, serialization/duplication
  reproduce topology) proves a ScrollPanel is never a list's DIRECT child, so the repaint already fired on every
  reachable call.
- **LEAVE verdicts** — written into the LEAVE section below: cluster A helper insides; cluster C scaffold;
  cluster D core arrange branches; cluster E; Widget grabsToParentWhenDragged's full-family fall-through;
  PanelWdgt's editable-plain-text click-forward filter; SimpleDocumentWdgt:110; MenusHelper:80; MacroToolkit:619.
- **Out-of-ε observations** (fresh-census leftovers for the campaign backlog — NOT scroll-topology, no verdict
  issued): `ActivePointerWdgt:587` (`actionedWdgt.parent instanceof SimpleButtonWdgt` policy site);
  `SpreadsheetWdgt:274` (keyboard-receiver dedup) + `:517` (CellWdgt collection filter); `ToolTipWdgt:106`
  (TextWdgt contents coercion); the `TransformFrameWdgt` island-detection family in Widget (deliberate affine-arc
  design, not a smell); `WindowWdgt:430/:710` (WindowContentLayoutSpec value-object guards, standing-LEAVE flavour).

**Post-arc state**: every remaining ε-scope `instanceof` carries a recorded LEAVE verdict; the two Widget topology
helpers plus the new PanelWdgt chokepoint are the only places the scroll-topology classes are named as classes.

## LEAVE (concrete class is clearest — do NOT convert)
Generic class-param tree utils (`TreeNode.parentThatIsA/siblingBeforeMeIsA/siblingAfterMeIsA`); serialization/
deserialization guards (`SliderWdgt` `@button instanceof SliderButtonWdgt`; `DeepCopierMixin:28` `instanceof Widget`;
`.className` round-trips); LayoutSpec value-object init (`instanceof VerticalStackLayoutSpec` — `Widget:269`,
`SliderWdgt:52`); `meta/` reflection (`.constructor.name`/`instanceof Array`); `macros/MacroToolkit` harness locators;
`WorldWdgt._reLayoutDesktop` desktop-furniture singletons; `ToolTipWdgt:72` Widget|String|canvas coercion; all ~21
`Point`/`Rectangle`/`Array`/`Color` guards.

**ε verdicts (owner-gated 2026-07-17)** — each argued on its merits, evidence in the Phase ε log:
- **The two Widget scroll-topology helper INSIDES** (`_amIDirectlyInsideScrollPanelWdgt` + the NonTextWrapping
  refinement): the helpers ARE the campaign-preferred chokepoint shape — all 7 callers dispatch through named
  queries. The de-instanceof alternative (identity `@parent.parent.contents == @parent` + a capability with a
  ListWdgt opt-out) demands an equivalence proof over all reachable trees (`@contents` is constructor-dynamic)
  for zero caller-visible gain. ⚠ the ListWdgt exclusion stays LOAD-BEARING (a list is-a scroll frame whose
  contents are NOT user scroll-content).
- **The PanelWdgt chokepoint's single instanceof** (`_amITheContentsPanelOfAScrollPanelWdgt`, minted by cluster B
  as LEAVE-with-cleanup): three policies (click-to-caret forward, detach refusal, grab-to-parent) share one
  structural premise; per-policy capabilities would mint three same-extension predicates (capability spam).
- **Widget.grabsToParentWhenDragged's full-Panel-family fall-through**: scrollbars (direct children of scroll
  frames) reach it and NEED the full family set — a scroll-frame opt-out demonstrably changes scrollbar drag.
- **The hierarchy-scaffold triple pairing** (`Widget.getHierarchyMenuWidgets`): 6 instanceof over 3 parent-aware
  pairings on OVERLAPPING hierarchies; the parent checks must stay call-time dynamic (a stored flag diverges
  under re-parenting); a menu-redundancy filter is clearest as concrete topology.
- **ScrollPanelWdgt's contents-type arrange/measure/pin branches** (`_positionAndResizeChildren` /
  `_applyExtent`): the frame OWNS its contents' frame ("I OWN its frame regardless"); `@contents` is
  constructor-dynamic so contents-tests don't reduce to frame-subclass dispatch; this is the
  determinism-sensitive core three arcs stabilized — highest stop-rule risk, no clarity gain.
- **SliderButtonWdgt:31/:71** (thumb-in-track drag policy): the truer-looking identity shape
  (`@parent.button == @`) is FALSIFIED by the documented detach-then-duplicate state (ScrollPanelWdgt's
  bar-belonging case law) — a class test keeps a non-owned button captive where identity would not; a `-> true`
  capability on SliderWdgt is `isSlider` in disguise (the 5c cosmetic bar).
- **PanelWdgt's editable-plain-text click-forward filter** (`instanceof SimplePlainTextWdgt and isEditable`):
  deliberately narrower than `isTextEntryField` (split out of the entry-fields cluster for exactly this reason).
- **SimpleDocumentWdgt:110**: a shape check of its OWN self-assembled startup content.
- **MenusHelper:80** (`instanceof SliderButtonWdgt` recolor sweep): dev-menu debug utility, harness-locator flavour.

## Documentation & comments to keep in sync
As each cluster lands, rewrite/remove the rationale comment tied to its sites and add a one-line breadcrumb at the
new hook/query. (The old anchor list here — `CaretWdgt.coffee:95`, `WindowWdgt.coffee:180`, `Widget.coffee:2096/3364`,
`ScrollPanelWdgt.coffee:302-303`, `SimpleVerticalStackPanelWdgt.coffee:76`, `ListWdgt.coffee:103` — was verified
stale at the ε close 2026-07-17: those comments were already rewritten by earlier campaigns or the lines drifted to
unrelated code; every ε conversion carries its own breadcrumb at both the site and the new capability.)
`widget-identity-decoupling-plan.md` is absorbed by this doc (see its header pointer);
`oo-smells-refactoring-backlog.md` Phase 5/6 and `god-class-decomposition-plan.md` reference the capability-first
override recorded here.
