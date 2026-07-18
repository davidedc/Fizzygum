# Container regularization — de-byzantinate Menu / List / Prompt / Divider

**STATUS: IN PROGRESS 2026-07-18 — §5.1 + §5.2a–c LANDED (the List/Menu/Divider untie; gauntlet 11/11,
byte-identical bar 1 benign inspector recapture; `instanceof` baseline ratcheted 97→95). REMAINING:
§5.3 (prompt family) + owner-gated tail (§5.2d/§5.2e/§5.4). Owner banked the untie as a milestone before §5.3.**
This is the FIRST of the five-plan program the owner chose to start.
Current-state facts were verified against the working tree on 2026-07-18 by reading the actual sources.
Anchor on the **class/method names** below; line numbers are hints and drift.

Self-contained: embeds the method-level facts so it runs cold. Part of one program with
[`onion-widget-composition-plan.md`](onion-widget-composition-plan.md),
[`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md),
[`creation-and-templates-plan.md`](creation-and-templates-plan.md), and
[`reference-widgets-plan.md`](reference-widgets-plan.md); shared north star = orthogonalisation,
de-byzantination, regularity — **the name encodes the role.** This is the same move applied to the
Menu/List/Prompt widgets that the Frame model applies to content widgets.

**Correctness-first (owner, 2026-07-18):** recapture/rename churn is NOT a reason to defer or compromise the
target; the phasing below exists **only for verifiability** (prove a byte-preserving lift, then apply the
riskier restructure in a bisectable batch) — never to dodge the right change.

---

## 1. The problem, in one sentence

A **List contains a Menu** — `ListWdgt` builds a `MenuWdgt` (flagged `isListContents: true`) purely to reuse
the menu's vertical row-stack layout — and that flag then strips the menu of its menu-ness (title, pop-up
membership, corner radius, click-outside-to-close). The 2017 "ZombieKernelMenuRevisionPlanV2" diagram called
this *"the oddest part."* The prize: make **layout** (a vertical stack of arbitrary rows) and **menu-ness**
(pop-over / pin / submenu / auto-close) two independent, composable things.

**Key finding (2026-07-18): menu-ness is ALREADY factored out — it lives in `PopUpWdgt`.** So this is NOT a
behaviour extraction; it is a **layout extraction**: pull the row-stack out of `MenuWdgt` so a `ListWdgt` can
own one directly, without borrowing a whole (crippled) menu.

---

## 2. Provenance — the source notes

| Note | Contribution |
|---|---|
| *Zombie kernel morphs structure refactoring* (the V2 "NOW vs NEW" diagram) | `MenuMorph` = "a box with a label and a ScrollableListMorph"; a general container; a `ListMorph`/`ScrollableListMorph` that holds **anything** (no hardwired child whitelist); **a List must NOT contain a Menu**; a `MenuTitle`; a `DividerMorph`; `PromptMorph` = a Menu with no title. |
| *Rewriting the ListMorph with layouts* | A List is a vertical stack that **hugs** its rows; resize negotiates via the normal extent mechanism. (Subsumed by the sizing-model-unification arc — item I below.) |
| *There should be different PromptMorph subclasses for each type of value…* | Per-value-type prompts (numeric / text / select / colour); prompts should be "Menus" **only via a Mixin** that adds pop-over/pin/auto-destroy. |

---

## 3. Current-state truth (verified 2026-07-18)

All `*Morph`→`*Wdgt` renames are done; the menu family lives in `src/basic-widgets/menu-system/`.
Superclass chains (root `TreeNode → Widget`):

- `MenuWdgt → PopUpWdgt → Widget` — `src/basic-widgets/menu-system/MenuWdgt.coffee`
- `PromptWdgt → MenuWdgt → PopUpWdgt → Widget` — `src/PromptWdgt.coffee`
- `SaveShortcutPromptWdgt → MenuWdgt` — `src/SaveShortcutPromptWdgt.coffee` (own header: *"TODO this widget has to be re-made"*)
- `CodePromptWdgt → Widget` (NOT a menu — windowed code editor) — `src/CodePromptWdgt.coffee`
- `ListWdgt → ScrollPanelWdgt → PanelWdgt → Widget` — `src/ListWdgt.coffee` (single class; already IS the scrollable list — no separate `ScrollableListWdgt`)
- `MenuItemWdgt → LabelButtonWdgt → ButtonWdgt → Widget` — `src/basic-widgets/menu-system/MenuItemWdgt.coffee`
- `MenuHeader → BoxWdgt → Widget` — `src/basic-widgets/menu-system/MenuHeader.coffee`
- `RectangleWdgt → Widget` — `src/basic-widgets/RectangleWdgt.coffee`

### 3.1 `PopUpWdgt` — the menu-ness behaviour (already factored)
`PopUpWdgt.coffee` owns the entire pop-up behaviour: the kill flags
(`killThisPopUpIfClickOnDescendantsTriggers` / `…OutsideDescendants`), world-set membership
(`world.freshlyCreatedPopUps` / `world.openPopUps`, added in its ctor), `propagateKillPopUps`,
`isPopUpPinned`, `getParentPopUp`, `pinPopUp`, `_reactToBeingDropped` (pins if dropped outside `world`),
the 3-shadow policy (`_updatePopUpShadow`/`addShadow`), `popUp`/`popUpAtHand`/`popUpCenteredAtHand`, and
`destroy`/`close` (delete from `openPopUps`). **This is exactly "being a menu is only a behaviour."**

### 3.2 `MenuWdgt` — a PopUp that hand-rolls a row-stack (the fusion)
`MenuWdgt.coffee` = `PopUpWdgt` + a **self-laid vertical row-stack** + a title. The layout lives in
`_reLayoutSelf` (commits extent 0,0 → positions each non-`@label` child top-to-bottom via `item._applyMoveTo`
+ `y += item.height()` → `adjustWidthsOfMenuEntries` → commits extent to `fullBounds + 2`). Row helpers:
`createLine`/`addLine`/`prependLine` (build a divider — §3.5), `createMenuItem`/`addMenuItem`/
`prependMenuItem`/`_menuItemSpecFrom` (build a `MenuItemWdgt` from a `MenuItemSpec`), `removeMenuItem`,
`removeConsecutiveLines`, `maxWidthOfMenuEntries`/`adjustWidthsOfMenuEntries` (equalize all rows to the max
row width — **duck-typed** via `item.menuEntryPreferredWidth?()`, the old `instanceof` whitelist is gone),
`unselectAllItems` (duck-typed `item.unselect?()`), `_createLabel` (`new MenuHeader @title`) +
`_buildMenuLabel`/`_buildMenuLabelNoSettle`. Role query `isMenu: -> true`. Test hooks `testItems`/
`testNumberOfItems` count `@children` minus `@label`.

### 3.3 `isListContents` — the byzantine flag (2 external readers)
Field on `MenuWdgt` (default false), set true only by `ListWdgt`. When true it: skips the title-label build
(`_buildMenuLabelNoSettle`); skips wiring click-outside-to-close (`onClickOutsideMeOrAnyOfMyChildren "close"`
in the ctor); **deletes the menu from `world.freshlyCreatedPopUps` + `world.openPopUps`** (ctor lines
39-42 — i.e. "un-pop-up" the menu); skips `cornerRadius` and title layout in `_reLayoutSelf`. External
readers of the flag are exactly TWO: `ListWdgt.coffee:65` (sets it) and `MenuItemWdgt.coffee:141`
(`isListItem: -> @parent.isListContents if @parent`).

`MenuItemWdgt.isListItem()` drives selection-vs-trigger behaviour: `mouseDownLeft` (`:133`) → if a list item,
`@parent.unselectAllItems()` + escalate (list selection); else the normal button trigger.

### 3.4 `ListWdgt` — wraps a `MenuWdgt` (the core oddity)
`ListWdgt.coffee`: field `listContents: nil # a MenuWdgt with the contents of the list`. Built in
`_buildAndConnectChildrenNoSettle` (`:64`): `@listContents = new MenuWdgt @, isListContents: true, target:
@, killOutside: false, killOnTriggers: false`; fill via `@listContents.addMenuItem …` per `@elements`; then
`@contents._addNoSettle @listContents, layoutSpec: LayoutSpec.ATTACHEDAS_FREEFLOATING`.
**⚠ Two traps documented in the source (lines 54-60):** (a) `ListWdgt extends ScrollPanelWdgt`, whose `add`
is a CUSTOM override redirecting a non-frame child into `@contents`; the non-settling twin is
**`@contents._addNoSettle`** — using the base `@_addNoSettle` wrongly attaches the contents to the scroll
frame and **breaks every `InspectorWdgt` property pane** (this is why the orphan-settledness sweep left it
unconverted). (b) `_applyExtent` (`:120`) keeps `@listContents` pinned to the frame's right/bottom on resize.
Public API to preserve: `select(item, trigger)` → `@target[@action]`; the `format`/`labelGetter` mechanism
(the `InspectorWdgt` "markOwnProperties" colouring).

**`ListWdgt` consumers:** `meta/InspectorWdgt.coffee` (the property panes — the main, pixel-critical
client), `basic-widgets/ScrollPanelWdgt.coffee` (base plumbing), and `macros/MACRO-PATTERNS.md` (test docs).

### 3.5 The divider — an inline `RectangleWdgt` (no class)
`MenuWdgt.createLine(height)` mints a `new RectangleWdgt`, sets `minimumExtent 5,1`, `color 230,230,230`,
`_applyHeight height+2`. `removeConsecutiveLines` re-identifies dividers via **`item instanceof
RectangleWdgt`** (`:118,:120`). `RectangleWdgt` itself (`basic-widgets/RectangleWdgt.coffee`) is a trivial
borderless box. **Latent bug:** any stray `RectangleWdgt` in a menu is treated as a divider.

### 3.6 The prompt family + entry points
- `PromptWdgt` (`extends MenuWdgt`) handles **text + number** in one class: ctor builds a `StringFieldWdgt`
  (`@tempPromptEntryField`, built before `super` and passed as the menu's `environment`), passes `@msg` as
  the **title**, then adds the field (+ a `SliderWdgt` when `@ceilingNum`/`useSliderForInput`, wired to
  `takeSliderValue`) and "Ok"/"Close" rows. So it is *not* "a menu with no title" — it has one.
- **Colour has no prompt class:** `Widget.pickColor(msg, callback, defaultContents)`
  (`basic-widgets/Widget.coffee:3869`) builds a `MenuWdgt` inline, `__add`s a `ColorPickerWdgt`, `addLine`,
  "Ok"/"Close", `popUpAtHand` — an ad-hoc menu.
- `CodePromptWdgt` (`extends Widget`) is the windowed multi-line code prompt (`Widget.textPrompt:3860`).
- `SaveShortcutPromptWdgt` (`extends MenuWdgt`) — the save-as prompt (4 callers: `ScriptWdgt`,
  `StretchableEditableWdgt`, `FolderWindowWdgt`, `apps/SimpleDocumentWdgt`); header says "to be re-made".
- Entry points (all on `Widget`): `inform(msg):3841` (message menu + "Ok"), `prompt(…):3851` (→ `PromptWdgt`),
  `textPrompt(…):3860` (→ `CodePromptWdgt`), `pickColor(…):3869` (→ inline `MenuWdgt` + `ColorPickerWdgt`).

### 3.7 Scorecard vs the V2 diagram
| # | Diagram proposal | Verdict | Evidence |
|---|---|---|---|
| A | Menu holds no hardwired child-type whitelist | **DONE** | duck-typed `menuEntryPreferredWidth?()`/`unselect?()` |
| B | Menu = title + a list (not self-laying) | **NOT DONE** | `MenuWdgt._reLayoutSelf` self-lays a row-stack |
| C | A List holds **anything** and **NOT** a Menu | **NOT DONE** | `ListWdgt` builds `new MenuWdgt(isListContents:true)` of rows |
| D | Menu items richer than a bare label | **DONE** | `MenuItemSpec` label may be `Widget`/`Canvas`/`[icon,string]` |
| E | Prompt = a Menu with no title; menu-ness via a Mixin; per-value-type subclasses | **NOT DONE** | `PromptWdgt extends MenuWdgt` **with** a title; text+number in one class; colour ad-hoc; no per-type family |
| F | One general container that becomes a window/pinnable-window | **NOT DONE — recommend NON-merge (§5.4)** | roles split: `PanelWdgt`/`WindowWdgt`/`PopUpWdgt`/`StretchableWidgetContainerWdgt` |
| G | A `MenuTitle` class | **DONE** | `MenuHeader` (`extends BoxWdgt`) |
| H | A `DividerMorph` class | **NOT DONE** | inline `RectangleWdgt` + `instanceof RectangleWdgt` |
| I | List hugs content / fits any area | **DONE (elsewhere)** | sizing-model-unification arc |

**Open work = B, C, E, H, and a ruling on F.** A/D/G/I are done; the plan says so rather than re-proposing.

---

## 4. Architecture we MUST respect

From `docs/architecture/{layering-naming-convention,layout,lint-and-static-checks}.md`:
- **⚠ Menu-row rendering is pixel-sensitive and heavily tested.** ~55 SystemTests exercise menus/lists/
  prompts/inspector/colour/sliders (§7). Any change to how rows are built or laid out (esp. C) can shift
  pixels → conscious recapture with a stated reason.
- **⚠ Settle model of the row-stack.** `MenuWdgt` lays out in **`_reLayoutSelf`** (a self-heal hook), NOT
  `_reLayoutChildren` — it is *not* a size-tracking container; it hand-sizes itself to its rows. If an
  extracted row-stack becomes a proper `SimpleVerticalStackPanelWdgt` (which DOES define `_reLayoutChildren`),
  its re-fit timing changes; keep the `fg revisits` (zero re-visit) and `fg census` (arrange-idempotence)
  baselines at zero. Constructors must build children via `_buildAndConnectChildrenNoSettle` reached from the
  settling wrapper (`check-constructors-build.js`); apply own bounds first (`check-relayout-bounds-first.js`).
- **⚠ The `@contents._addNoSettle` trap (§3.4a)** — a `ListWdgt`'s contents attach MUST go through
  `@contents._addNoSettle`, never the base `@_addNoSettle`, or every `InspectorWdgt` pane breaks.
- **Menu behaviour is already `PopUpWdgt`** — reuse it; do not re-implement pop-up/pin/close.
- **Mixins for stateless behaviour bundles are sanctioned** (`@augmentWith`); the project moves mixins→OO
  only for God-class *state*, not for a behaviour bundle.
- **Naming/tiers:** new classes `*Wdgt`, one class per file, filename == class name; public `name`/`_name`/
  `__name` tiers; reference by literal `extends X`/`new X`. Watch the `coalesced` menu-takeover homonym
  (`takesOverAndCoalescesChildrensMenus`) — unrelated to the layout "coalesced" family.
- **`MenusHelper`** (already God-class-split, `docs/archive/god-class-decomposition-plan.md`) is where menu
  *assembly* lives — construction changes land there, not scattered.

---

## 5. The work — step by step

### 5.1 [H] Extract `DividerWdgt`. *Smallest; pixel-identical; do first.*
1. New file `src/basic-widgets/menu-system/DividerWdgt.coffee`: `class DividerWdgt extends RectangleWdgt`
   with the exact current divider look (the `createLine` body: `minimumExtent 5,1`, `color 230,230,230`,
   height+2, a `colloquialName`). Keep the geometry byte-identical.
2. `MenuWdgt.createLine` → `new DividerWdgt height` (same dimensions/colour).
3. `MenuWdgt.removeConsecutiveLines` → `item instanceof DividerWdgt` (both sites).
4. Grep for any other `instanceof RectangleWdgt` that means "divider" and switch it; leave genuine rectangles.
- **Fixes the latent bug** (a stray `RectangleWdgt` is no longer mistaken for a divider).
- **Verify:** `fg build` + `fg gauntlet`; menu-bearing tests (§7) must be **byte-identical** (a real divider
  with the same look/size ⇒ no pixel change). If any differ, the extraction changed geometry — fix, don't
  recapture.

### 5.2 [B]+[C] Untie List-from-Menu. *The core delta — phased by risk.*

**5.2a — Extract the row-stack into `MenuRowsPanelWdgt` (byte-preserving lift; low risk).**
Create `src/basic-widgets/menu-system/MenuRowsPanelWdgt.coffee` owning the row-stack **layout + row helpers**
lifted verbatim from `MenuWdgt`: the `_reLayoutSelf` row-positioning body, `maxWidthOfMenuEntries`/
`adjustWidthsOfMenuEntries`, `createMenuItem`/`addMenuItem`/`prependMenuItem`/`_menuItemSpecFrom`, `createLine`/
`addLine`/`prependLine`, `removeMenuItem`/`removeConsecutiveLines`, `unselectAllItems`, `testItems`/
`testNumberOfItems`. Decision (C2): **base it on `Widget`/`PanelWdgt` with the lifted self-layout first**
(byte-preserving, self-laying like the menu is today) — NOT on `SimpleVerticalStackPanelWdgt` yet (that
changes settle timing; a follow-on, §5.2e). In this step **`MenuWdgt` still uses its own copy** (or delegates
to a shared `MenuRowsPanelWdgt` instance internally if delegation proves byte-identical) — the point of 5.2a
is only to make the row-stack *available as a class a `ListWdgt` can instantiate*.
- **Verify:** pure lift ⇒ `fg gauntlet` byte-identical.

**5.2b — `ListWdgt` uses a `MenuRowsPanelWdgt`, not a `MenuWdgt`.**
- Replace field `listContents: nil # a MenuWdgt…` and the `_buildAndConnectChildrenNoSettle` line
  `@listContents = new MenuWdgt @, isListContents:true, …` with `@listContents = new MenuRowsPanelWdgt …`
  (no pop-up args — a rows-panel is not a pop-up, so `killOutside`/`killOnTriggers` and the
  `freshlyCreatedPopUps`/`openPopUps` deletion hack simply disappear).
- Keep the fill loop (`@listContents.addMenuItem …`) and **keep `@contents._addNoSettle @listContents`**
  (§3.4a trap). Keep `_applyExtent`'s right/bottom pinning.
- Replace `MenuItemWdgt.isListItem` (`@parent.isListContents`) with a role query the rows-panel answers —
  e.g. `@parent.selectsItemsOnClick?()` (true on `MenuRowsPanelWdgt`-used-as-list, false on a menu). Keep
  `mouseDownLeft`'s selection-vs-trigger split behaviourally identical.
- **Verify (pixel-critical):** the `InspectorWdgt` set + list tests — `macroNakedInspectorRendersResizesAndEdits`,
  `macroResizingPristineInspector`, `macroInspectorRejectsDrops`, `macroInspectorScrollbarUnplugged`,
  `macroInspectorResizingOKEvenWhenTakenApart`, `macroInspectorWorkAreaEvaluatesCoffeeScript`,
  `macroPickingUpPartsFromInspector`, `macroDuplicatedInspector*`, `macroSimpleDocumentHandlesOldInspector`,
  `macroAddingWidgetToListUpdatesScroll`, `macroListWdgtWheelScroll`, `macroListWdgtAutoScrollsNearDraggedEdge`.
  Aim byte-identical; if the inspector rows legitimately move, recapture consciously (`fg recapture-inspector`
  exists for the inspector set) with a one-line reason.

**5.2c — Retire `isListContents`.**
Remove the field and every branch it guards from `MenuWdgt` (the label-skip, the click-outside-skip, the
`freshlyCreatedPopUps`/`openPopUps` deletion, the `cornerRadius`/title-layout skips). After 5.2b there are no
readers left. **Verify:** `fg gauntlet` (menus now always build their title/pop-up membership — confirm no
menu test regressed).

**5.2d — (Phase 2, owner-gated) Recompose `MenuWdgt` as `PopUpWdgt` + [`MenuHeader` + `MenuRowsPanelWdgt`].**
The full diagram realization: `MenuWdgt` stops self-laying and instead composes a title + a rows-panel. This
touches `testItems`/`testNumberOfItems` (rows move one level deeper), submenu logic, and hover-highlight
(`macroHierarchyMenuHoverHighlightsExactSubtree`) → **larger recapture**. Gate hard; land alone. Owner
decides whether to take Phase 2 or stop after 5.2c (the core oddity is already gone at 5.2c).

**5.2e — (follow-on, optional) Re-base `MenuRowsPanelWdgt` on `SimpleVerticalStackPanelWdgt`.**
Replace the lifted hand-layout with the canonical hug/grow stack (+ a width-equalization override). The
"right" end state (one vertical-stack engine), but it shifts settle timing (`_reLayoutChildren` appears) →
keep `fg revisits`/`fg census` at zero. Only after 5.2d is stable.

### 5.3 [E] Regularize the prompt family. *Uses the 5.2a row-stack.*
1. **Menu-ness via `PopUpWdgt`, not inheritance.** Re-base `PromptWdgt` off **`PopUpWdgt`** (the behaviour)
   composing a `MenuRowsPanelWdgt` (title + value-editor + Ok/Close), instead of `extends MenuWdgt`. This is
   the note's "prompts are Menus only via a Mixin" — realized as "prompts share the pop-up behaviour, not the
   menu class."
2. **Per-value-type family.** `PromptWdgt` base + `TextPromptWdgt` (current `StringFieldWdgt` case),
   `NumberPromptWdgt` (the slider case; keep `takeSliderValue`/`_takeSliderValueConnector`/`_takeSliderValueNoSettle`
   and the dataflow-connector wiring verbatim), `ColorPromptWdgt` (fold `Widget.pickColor`'s inline
   `MenuWdgt`+`ColorPickerWdgt` into a class), `SelectPromptWdgt` (the font/enum select — trace the
   `ChangeFontButtonWdgt` font menu and fold it if it fits; else bank). Fold `SaveShortcutPromptWdgt`'s
   "to be re-made" onto this base.
3. **Route the entry points:** `Widget.prompt` → `TextPromptWdgt`/`NumberPromptWdgt` (dispatch on
   `ceilingNum`); `Widget.pickColor` → `ColorPromptWdgt`; leave `Widget.textPrompt` → `CodePromptWdgt`
   (windowed, separate). `inform` may stay a plain message menu or become a trivial prompt — owner's call.
- **Verify:** `macroPromptShadowFollowsOnDrag`, `macroSaveAsPromptAboveTiltedWindow`,
  `macroStringWdgtEditDefersToPromptWhenCropped`, the colour tests (`macroBoxTransparencyAndColorChanging`,
  `macroCanMoveAndResizeColorPaletteWdgt`, `macroSpreadsheetColorCell`), the slider tests
  (`macroSlider*`, `macroLonelySlider*`). Byte-identical or conscious recapture.

### 5.4 [F] Rule on "one container that becomes a window/pinnable-window" — a deliberate NON-merge.
Record *why not* rather than building it: `PanelWdgt` is the general clipping container; `WindowWdgt`'s
internal/external skin is already **derived from parentage** (drag-embed arc) so "becomes a window when
embedded" is already automatic; `PopUpWdgt` already provides pinnable/transient behaviour (and becomes the
single shared home of it after 5.2/5.3). A mode-flagged mega-container would re-introduce exactly the
special-casing this arc removes. The regularity win is **naming the relationship** (Panel = container,
PopUp = +transient/pin, Window/Frame = +chrome/identity) in the program's P0 principles doc — not collapsing
them. *(Owner may overrule → then it's a separate design spike, flagged not dropped.)*

---

## 6. Owner decisions
| # | Decision | Recommendation |
|---|---|---|
| C1 | Order | **5.1 → 5.2a → 5.3 → 5.2b → 5.2c → (5.2d/5.2e) → 5.4** — ascending pixel-risk, respecting the 5.2a→5.3 dependency; the inspector-touching untie (5.2b) and the menu recompose (5.2d) last. |
| C2 | Row-stack base | **`Widget`/`PanelWdgt` + lifted self-layout first** (byte-preserving); migrate to `SimpleVerticalStackPanelWdgt` in 5.2e. |
| C3 | Take Phase 2 (5.2d menu recompose)? | Owner's call — the core oddity is gone at 5.2c; 5.2d is the full-diagram polish (bigger recapture). |
| C4 | [F] unify containers? | **No** (§5.4) — record the non-merge; re-open only on explicit request. |
| C5 | Renames | In-scope where right (correctness-first — recapture is not a blocker); batch for verifiability only. |

---

## 7. Verification protocol
- **Every step:** `fg build` then `fg gauntlet` (parallel full gate). Nothing here touches the render/input
  loop's timing, so determinism risk is low — but 5.2e changes settle timing, so run `fg revisits` + `fg
  census` there.
- **The subsystem test surface (~55 tests) — must stay byte-identical or be consciously recaptured:**
  - *Lists:* `macroAddingWidgetToListUpdatesScroll`, `macroListWdgtWheelScroll`, `macroListWdgtAutoScrollsNearDraggedEdge`.
  - *Inspector (main `ListWdgt` client — pixel-critical):* `macroNakedInspectorRendersResizesAndEdits`,
    `macroResizingPristineInspector`, `macroInspectorRejectsDrops`, `macroInspectorScrollbarUnplugged`,
    `macroInspectorResizingOKEvenWhenTakenApart`, `macroInspectorWorkAreaEvaluatesCoffeeScript`,
    `macroPickingUpPartsFromInspector`, `macroDuplicatedInspectorDrivesCopiedTargetOnly`,
    `macroDuplicatedInspectorsCloseIndependently`, `macroSimpleDocumentHandlesOldInspector`. Recapture tool:
    `fg recapture-inspector`.
  - *Menus:* `macroBasicWorldMenuAndBubble`, `macroCheckNumberOfItemsInWorldMenu`, `macroDemoMenuCatalogueParade`,
    `macroHoppingBetweenSubMenus`, `macroMenusCloseOnMouseDownOutside`, `macroRightClickClosesDownstreamSubMenus`,
    `macroSubMenuDroppedIntoPanelPinsItself`, `macroScrollPanelMergesChildMenu`,
    `macroHierarchyMenuHoverHighlightsExactSubtree`, `macroDuplicatedMenuAutoPinsOnDesktop`,
    `macroMenuItemDuplicatesToStandaloneWidget`, `macroMenuPinnedByHeaderClick`, `macroMenuPinnedInScrollPanel`,
    `macroMenuRepositionsToStayOnScreen`, `macroMenuShadowCorrectWhileAndAfterDrag`, `macroMenuFromFramedItemNotClipped`,
    `macroMenuInWindowInScrollStackStaysLive`, `macroMenusAndSubMenusRemainOpenWhileDraggingMenusOnly`,
    `macroMenuPickUpKeepsTiltNoStrandedIsland`, `macroPinnedMenuKeepsCorrectShadowWhenBroughtToForeground`.
  - *Prompts:* `macroPromptShadowFollowsOnDrag`, `macroSaveAsPromptAboveTiltedWindow`,
    `macroStringWdgtEditDefersToPromptWhenCropped`.
  - *Colour/slider (prompt siblings):* `macroBoxTransparencyAndColorChanging`, `macroCanMoveAndResizeColorPaletteWdgt`,
    `macroSpreadsheetColorCell`, `macroSpreadsheetSliderCell`, `macroSlider*`, `macroLonelySlider*`,
    `macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways`, `macroPalette*`, `macroTwoPalettesShareOneTarget`.
- Run one while debugging: `node scripts/run-macro-test-headless.js SystemTest_<name>` (in `Fizzygum-tests`).

---

## 8. Risks & gotchas
- **Pixel risk concentrated in 5.2b (inspector) and 5.2d (menu recompose).** Verify byte-exact or recapture
  deliberately with a stated reason (owner: recapture is not a blocker — but it must be *conscious*).
- **The `@contents._addNoSettle` trap (§3.4a)** — using base `@_addNoSettle` breaks every inspector pane.
- **The row-stack settle model (§4)** — a byte-preserving self-laying lift (5.2a/C2) avoids the
  `_reLayoutChildren` timing shift; only 5.2e introduces it (guard with `fg revisits`/`fg census`).
- **`testItems`/`testNumberOfItems` depth** — 5.2d moves rows one level deeper; update the test hooks and
  `macroCheckNumberOfItemsInWorldMenu` accordingly.
- **Two failed fix-shapes ⇒ STOP.** If untying (5.2) is falsified twice, the model is wrong — re-frame, don't
  iterate a third shape (owner standing rule).
- **Do NOT revive:** a hardwired child-type whitelist (regressing item A); the `_announce*ToContainer`
  up-notify seam (deleted, banned by rule [N]).
- **Non-goals:** the sizing/hug work (done, item I); class renames for their own sake; changing the
  duck-typed containment that already works (item A).

## 9. Cross-links
- Program siblings: [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md),
  [`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md),
  [`creation-and-templates-plan.md`](creation-and-templates-plan.md),
  [`reference-widgets-plan.md`](reference-widgets-plan.md).
- Landed history to build on: `docs/archive/menu-slider-ctor-conversion-plan.md` (menu/prompt ctor
  settle-conversion — preserve it), `docs/archive/oo-smells-refactoring-backlog.md` (`MenuItemSpec`),
  `docs/archive/god-class-decomposition-plan.md` (`MenusHelper` split),
  `docs/archive/coalesced-nomenclature-rename-plan.md` (the menu-takeover homonym caution).
- Architecture: `docs/architecture/{layering-naming-convention,layout,lint-and-static-checks}.md`.
```
