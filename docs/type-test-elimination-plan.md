# Type-test elimination — decouple widgets from subclass identity (codebase-wide, capability-first)

The live campaign backlog for removing *type-test-then-branch* smells (`if x instanceof FooWdgt then A else
B`, and its predicate twin `if x.isFoo?()`) across `src/`. It is the **codebase-wide superset** of the
Widget-scoped `widget-identity-decoupling-plan.md` (which it absorbs) and the true-polymorphism part of Phase 5
in `oo-smells-refactoring-backlog.md`. Executable cold; grep symbols (line numbers drift).

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
`macroDuplicatedInspectorDrivesCopiedTargetOnly` (`fg recapture …`). A cluster that changes WHEN/HOW layout or
input fires (not a pure boolean swap) → also a clean-env dpr2 soak. `--homepage` boot leg for homepage-included
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
- ☐ **fanout-pin filter** — `mixins/ContainerMixin.coffee:26`, `mixins/ControllerMixin.coffee:23` → `selectableAsConnectionTarget?()` on `FanoutPinWdgt`.
- ☐ **last-focus tracking** — `ActivePointerWdgt.coffee:248/556` → `tracksAsLastFocusedWidget?()` (excludes `HorizontalMenuPanelWdgt`).
- ☐ **glass-box wrap idempotency** — `HorizontalMenuPanelWdgt.coffee:28`, `ToolPanelWdgt.coffee:30` → `isGlassBoxWrapper?()` on `GlassBoxBottomWdgt`.
- ☐ **ratio-constraint drop/grab** — `mixins/KeepsRatioWhenInVerticalStackMixin.coffee:15/32`, `graphs-plots-charts/Example3DPlotWdgt.coffee:70/74/90/94` → `imposesRatioConstraintOnDroppedChildren?()`/`releasesRatioConstraintOnGrabbedChildren?()` on the stack (overridden false by `WindowWdgt`); kills 6 copy-pasted sites + the IS-A-minus-subclass smell.
- ☐ **entry fields** — `Widget.coffee:~3586`, `PanelWdgt.coffee:78` → reuse `isEditable` + `isTextEntryField?()`.
- ☐ **pen surface** — `PenWdgt.coffee:28` → `acceptsPenDrawing?()` on `CanvasWdgt`+`ActivePointerWdgt`.
- ☐ **basement** — `TreeNode.coffee:168/174/182` → `isBasementContainer?()` on `BasementWdgt`.
- ☐ **desktop-icon family** — `IconicDesktopSystemLinkWdgt.coffee:11`, `WorldWdgt.coffee:1457`, `mixins/GridPositioningOfAddedShortcutsMixin.coffee:25` → `isDesktopIcon?()`/`participatesInIconGrid?()`.
- ☐ **shortcut-to-self** — `Widget.coffee:~2125` → `isShortcutTo?(w)`.
- ☐ **menu detection (filter half)** — `ActivePointerWdgt.coffee:83/382` → `isMenu?()` on `MenuWdgt`.
- ☐ **hierarchy-scaffold** — `Widget.coffee:~3124` → `hiddenAsInternalScaffolding?()`.
- ☐ **handle-initiated geometry** — `Widget.coffee:~1343/1562` → `changeShouldRememberFractionalGeometry?()` on the initiator.

### Phase α — capability reuse (per-site faithfulness; NOT a blanket reuse)
- ☐ **overlay-chrome** — sites test DIFFERENT class-sets, so map per site: {Caret,Handle}→`isLayoutDecoration?()` (`WindowWdgt.coffee:197`); {annotation,Handle}→a distinct `attachesToScrollFrameDirectly?()` (`ScrollPanelWdgt.coffee:194`, `HorizontalMenuPanelWdgt.coffee:20`, `ToolPanelWdgt.coffee:16`, `StretchableWidgetContainerWdgt.coffee:34`); {Caret} / {Highlighter,Caret} (`ActivePointerWdgt.coffee:66`, `PanelWdgt.coffee:75`, `SimplePlainTextWdgt.coffee:97`, `Widget.coffee:2377`) → extend `isLayoutDecoration` ONLY if the firing set stays exact, else a narrower query. Verify each is byte-identical.
- ☐ **dead commented-out instanceof** — delete `WorldWdgt.coffee:669`, `Widget.coffee:1907`, `MenuWdgt.coffee:196-202`.

### Phase γ — move-behaviour hooks
- ☐ **WindowWdgt title-bar buttons** — `buttons/{Close,Edit,External,Internal}IconButtonWdgt.coffee:~12-13` → action/notify hooks on the window (`closeFromWindowBar?`/`editButtonPressed?`/`makeInternal?`/`makeExternal?`); drop the `@parent(.parent) instanceof WindowWdgt` reach-through (some are Demeter grandparent reaches — prefer routing the action).
- ☐ **enable/disable Drags/Drops/Editing bubble** — `SimpleVerticalStackScrollPanelWdgt.coffee:45/55`, `StretchablePanelWdgt.coffee:106/116`, `StretchableWidgetContainerWdgt.coffee:190/200` → `@parent?.enableDragsDropsAndEditing?(@)`/`disable…?(@)`.
- ☐ **caret Tab/Enter** — `CaretWdgt.coffee:90` (`instanceof SimplePlainTextWdgt`) + `:95` (`constructor.name=="StringWdgt"`) → `tabInsertsSpaces?()`/`enterKeyAccepts?()` on the text classes (kills the string-name smell + the `:95` comment).
- ☐ **glass-box child layout** — `GlassBoxBottomWdgt.coffee:36`, `HorizontalMenuPanelWdgt.coffee:38` → `layoutWithinGlassBox?`/`preferredGlassBoxExtent?`.
- ☐ **desktop reference creation** — `WindowWdgt.coffee:94`, `IconicDesktopSystemFolderShortcutWdgt.coffee:6` → content/dropped-widget hooks.
- ☐ **misc hooks** — `buttons/ExternalLinkButtonWdgt.coffee:6` (`openExternalURL?`), `TextWdgt.coffee:716` (console contributes menu entries), `ActivePointerWdgt.coffee:931` (`maybeStartAutoScroll?`), `Wallpaper.coffee:55`+`StringWdgt.coffee:967` (menu `refreshTicks?`), `WindowWdgt.coffee:149/165` (polymorphic `contentsRecursivelyCanSetHeightFreely`), `mixins/CreateShortcutOfDroppedItemsMixin.coffee:22/29` + `mixins/KeepIconicDesktopSystemLinksBackMixin.coffee:14/18`.

### Phase δ — singleton identity
- ☐ **`@parent instanceof WorldWdgt`** — `ButtonWdgt.coffee:129`, `HandleWdgt.coffee:41`, `Widget.coffee:2706/2837/3214` → `@parent == world`.
- ☐ **hand root** — `Widget.coffee:2814` (`@root() instanceof ActivePointerWdgt`) → `@root() == world.hand`.
- ☐ **grabbable** — `ActivePointerWdgt.coffee:150` (`instanceof WorldWdgt`) → `isGrabbable?()`/`@parent == world`.
- ☐ **isWindow base-default reconciliation** — move `a581b03b`'s `Widget.isWindow: -> false` off the God class (to `?()` dispatch) OR upgrade the call sites to behaviour-moves (e.g. close-vs-delete menu → `addDestroyMenuItem` override).

### ⏳ Phase ε — study (Phase-6-entangled; defer)
Scroll-structure topology (`_amIDirectlyInsideScrollPanelWdgt`/`…NonTextWrapping…` and the Panel/Slider-in-ScrollPanel
drag-policy sites) and lock-to-panels (`Widget.coffee:~2706/3213`) — these dissolve under the God-class split; convert
via a parent capability-query only if the split doesn't reach them first. ScrollPanel content-type layout
(`ScrollPanelWdgt.coffee:240/324/358`) — polymorphic content hook; layout-determinism-sensitive.

## LEAVE (concrete class is clearest — do NOT convert)
Generic class-param tree utils (`TreeNode.parentThatIsA/siblingBeforeMeIsA/siblingAfterMeIsA`); serialization/
deserialization guards (`SliderWdgt` `@button instanceof SliderButtonWdgt`; `DeepCopierMixin:28` `instanceof Widget`;
`.className` round-trips); LayoutSpec value-object init (`instanceof VerticalStackLayoutSpec` — `Widget:269`,
`SliderWdgt:52`); `meta/` reflection (`.constructor.name`/`instanceof Array`); `macros/MacroToolkit` harness locators;
`WorldWdgt._reLayoutDesktop` desktop-furniture singletons; `ToolTipWdgt:72` Widget|String|canvas coercion; all ~21
`Point`/`Rectangle`/`Array`/`Color` guards.

## Documentation & comments to keep in sync
As each cluster lands, rewrite/remove the rationale comment tied to its sites (e.g. `CaretWdgt.coffee:95`,
`WindowWdgt.coffee:180`, `Widget.coffee:2096/3364`, `ScrollPanelWdgt.coffee:302-303`,
`SimpleVerticalStackPanelWdgt.coffee:76`, `ListWdgt.coffee:103`) and add a one-line breadcrumb at the new hook/query.
`widget-identity-decoupling-plan.md` is absorbed by this doc (see its header pointer);
`oo-smells-refactoring-backlog.md` Phase 5/6 and `god-class-decomposition-plan.md` reference the capability-first
override recorded here.
