# Container regularization — de-byzantinate Menu / List / Prompt / Divider

**STATUS: IN PROGRESS 2026-07-18 — §5.1 + §5.2a–c + §5.3 LANDED. §5.1/§5.2a–c = the List/Menu/Divider
untie (gauntlet 11/11, byte-identical bar 1 benign inspector recapture; `instanceof` baseline 97→95;
committed `44493b78`+`7733d214`, tests `38e25bcce`). §5.3 = the prompt family re-based OFF `MenuWdgt`:
`PromptWdgt extends PopUpWdgt` composing ONE titled `MenuRowsPanelWdgt` (generalized in this step with a
`title` opt → titled body + a `selectsItemsOnClick` ctor opt, default false=trigger, `ListWdgt` passes true),
per-type `TextPromptWdgt`/`NumberPromptWdgt`/`ColorPromptWdgt` (the last folds `Widget.pickColor`),
`SaveShortcutPromptWdgt` re-homed onto the base, `Widget.prompt` dispatches Text/Number on `ceilingNum`.
SelectPromptWdgt BANKED (font selectors are editor-integrated menus, not value prompts); `inform` left as a
message menu. Gauntlet 11/11 green incl. revisits+census; byte-identical bar 1 conscious save-as recapture
(its `_applyWidth 150` hack → invisible sub-pixel width churn) + 1 test-structure edit (the popover test found
its slider at `prompt.rowsPanel.children`, not `prompt.children`). §5.2d = `MenuWdgt` recomposed off its
self-laid row-stack: `extends PopUpWdgt` composing ONE free-floating `MenuRowsPanelWdgt` (title/target/
environment/fontSize), row API DELEGATED (addMenuItem/prependMenuItem/addLine/prependLine/removeMenuItem/
removeConsecutiveLines/testItems/testNumberOfItems), `@label = @rowsPanel.label`, and its own
`_reLayoutSelf`/`maxWidthOfMenuEntries`/`adjustWidthsOfMenuEntries`/`createLine`/`createMenuItem`/
`_buildMenuLabel` DELETED (net −55 lines). Gauntlet 11/11 green incl. revisits (0 up-edge re-visits) +
census (0 movers/1623 targets); 8 menu tests consciously recaptured (invisible rounded-corner-stroke AA at
menu-overlap corners — eyeballed via `fg diffpage`, 0 major-change). **⚠⚠ §5.2d was NOT a clean drop-in —
four real regressions surfaced (see §8), each a consequence of inserting the panel BETWEEN the menu and its
items; the load-bearing fixes are `_reactToBeingAdded`-drives-the-panel-layout, `isTransparentAt → true`,
lay-out-ONCE (not a size-tracking container), and two `menu.children[N]`→`menu.rowsPanel.children[N]`
production sites.** **§5.4 LANDED 2026-07-18** (docs-only F non-merge ruling recorded in `layering-naming-convention.md` §6;
scorecard F → DONE). **§5.6 LANDED as (b) 2026-07-19**: base fix (a) rejected (regressed ~70 tests — appearance-
less widgets rely on the opaque default), so kept per-class + added `PromptWdgt.isTransparentAt: -> true`; owner
eyeballed + accepted its one visible effect (a stray hover-highlight through the prompt corner in
`macroSaveAsPromptAboveTiltedWindow` image_2) and it was consciously recaptured (see §5.6 OUTCOME).
**§5.5 WALLPAPER TEST LANDED + guard-proven 2026-07-19** (`macroWallpaperMenuTickTracksSelection` covers the
`menu.rowsPanel.children[N]` tick path; the sibling fonts test is DEFERRED — the Wallpaper test already guards
the bug class; see §5.5 OUTCOME). REMAINING (fleshed out below, executable cold): **§5.2e** (re-base
`MenuRowsPanelWdgt` on `SimpleVerticalStackPanelWdgt` — hardest, OK to leave unfinished).**
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
| B | Menu = title + a list (not self-laying) | **DONE (§5.2d)** | `MenuWdgt extends PopUpWdgt` composing a titled `MenuRowsPanelWdgt`; the menu draws nothing, the panel lays out the rows |
| C | A List holds **anything** and **NOT** a Menu | **DONE (§5.2b/c)** | `ListWdgt` builds `new MenuRowsPanelWdgt(selectsItemsOnClick:true)`, never a `MenuWdgt`; `isListContents` retired |
| D | Menu items richer than a bare label | **DONE** | `MenuItemSpec` label may be `Widget`/`Canvas`/`[icon,string]` |
| E | Prompt = a Menu with no title; menu-ness via a Mixin; per-value-type subclasses | **DONE (§5.3)** | `PromptWdgt extends PopUpWdgt` composing a titled `MenuRowsPanelWdgt`; per-type `Text`/`Number`/`ColorPromptWdgt`; `pickColor` folded; menu-ness via the pop-up, not the menu class |
| F | One general container that becomes a window/pinnable-window | **DONE (§5.4) — deliberate NON-merge, ruling recorded** | roles split + named in `docs/architecture/layering-naming-convention.md` §6: `PanelWdgt`(clip)/`PopUpWdgt`(pin/shadow)/`WindowWdgt`(chrome, skin derived from parentage)/`StretchableWidgetContainerWdgt` |
| G | A `MenuTitle` class | **DONE** | `MenuHeader` (`extends BoxWdgt`) |
| H | A `DividerMorph` class | **DONE (§5.1)** | `DividerWdgt extends RectangleWdgt`; `isDivider?()` role query replaced `instanceof RectangleWdgt` |
| I | List hugs content / fits any area | **DONE (elsewhere)** | sizing-model-unification arc |

**F ruled DONE 2026-07-18 (§5.4, a deliberate NON-merge — recorded in `layering-naming-convention.md` §6).**
A/B/C/D/E/F/G/H/I are all DONE. Only the OPTIONAL §5.2e stack re-base remains (leaving it unfinished is fine).

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

**5.2d — Recompose `MenuWdgt` as `PopUpWdgt` composing a titled `MenuRowsPanelWdgt`. ✅ LANDED 2026-07-18.**
`MenuWdgt extends PopUpWdgt`, builds ONE free-floating `MenuRowsPanelWdgt(title/target/environment/fontSize)`,
DELEGATES the row API to it, surfaces `@label = @rowsPanel.label`, and deletes its own `_reLayoutSelf`/
`maxWidthOfMenuEntries`/`adjustWidthsOfMenuEntries`/`createLine`/`createMenuItem`/`_buildMenuLabel` (net −55
lines; the panel already carries them). Gauntlet **11/11 incl. revisits (0) + census (0 movers/1623)**; 8 menu
tests consciously recaptured (invisible corner-stroke AA, eyeballed via `fg diffpage`).

**⚠⚠ NOT the clean drop-in the Post-§5.3 note predicted.** Inserting the panel BETWEEN the menu and its
items broke four things the direct-child structure hid — all four are the load-bearing lessons (see §8):
1. **The panel never lays its rows out.** `addMenuItem` routes through the RAW `__add` (no invalidate, no
   settle); the old self-laying menu got away with it because its OWN `_reLayoutSelf` fired at popUp (via base
   `Widget._reactToBeingAdded → @_reLayoutSelf()`). Fix: `MenuWdgt._reactToBeingAdded` DRIVES
   `@rowsPanel._reLayoutSelf()` + hugs via `_applyExtentBase` (method `_layOutAndHugRowsPanel`). Without it
   menus render EMPTY (66 failures, fractional geometry cascading everywhere a menu opens).
2. **Lay out ONCE, do NOT be a size-tracking container.** The first fix made the menu a `_reLayoutChildren`
   container that re-drove the panel on every settle → a **±1px menu-position oscillation** (caught by
   `fg census`/`fg revisits`). Menus are ALWAYS fully composed BEFORE popUp, so the panel never changes
   post-popUp — lay out once at `_reactToBeingAdded`, no `_reLayout`/`_reLayoutChildren` override, and
   re-layouts are stable base no-ops (exactly the old menu's model).
3. **The menu draws NOTHING → it must be `isTransparentAt → true`.** With `MenuAppearance` removed (the panel
   draws the box), `Widget.isTransparentAt` returns `undefined`, and `not undefined === true` treats the menu
   as OPAQUE everywhere — so its transparent rounded corners INTERCEPTED clicks meant for a menu BEHIND it,
   dropping the hover-highlight of the item whose submenu was open. (Latent-identical in `PromptWdgt`;
   untested there. The real base bug is `undefined`-means-opaque.)
4. **`popUpCenteredAtHand` + build-time hug.** Do NOT hug at build: the old menu centred inform on a ~0
   pre-layout extent (top-left at hand); a build hug offsets by half the real size and mis-places it. Leave
   the menu at zero extent until popUp lays it out.

Plus two PRODUCTION `menu.children[N]`-index sites (feature code reaching items as direct children):
`Wallpaper.updatePatternsMenuEntriesTicks` and `StringWdgt.updateFontsMenuEntriesTicks` → `menu.rowsPanel.children[N]`
(index-preserving; the owner hit the wallpaper one as `undefined is not an object at menu.children[1].label`).
These are the ONLY two such sites in the tree (grep-confirmed); NO test covered either — verify by hand /
headless probe.

**5.2e — (follow-on) Re-base `MenuRowsPanelWdgt` on `SimpleVerticalStackPanelWdgt`. THE HARDEST remaining
step — do it LAST; leaving it unfinished is fine (the arc is complete without it).**
Today `MenuRowsPanelWdgt extends Widget` and hand-lays its rows in `_reLayoutSelf` (position each non-`@label`
row top-to-bottom under the optional MenuHeader, then `adjustWidthsOfMenuEntries` equalizes every row to the
widest via `menuEntryPreferredWidth?()`, then `__commitExtent fullBounds+2`). §5.2e replaces that lifted
hand-layout with the canonical vertical-stack engine so ONE stack engine serves the whole tree.
GOAL: `MenuRowsPanelWdgt extends SimpleVerticalStackPanelWdgt`, KEEPING (a) the optional title header
(MenuHeader at child 0 + corner radius when `@title`); (b) width-equalization — menus/lists want every row
STRETCHED to the widest so highlights span the full row, which a plain stack does NOT do; (c) the
`selectsItemsOnClick` knob; (d) the delegated row API + `hiddenFromHierarchyMenu?()`; (e)
`sliderTrackPressJumpsButton?()`.
⚠⚠ SETTLE-MODEL CHANGE — this is EXACTLY what §5.2d's abandoned size-tracking design tripped on. A
`SimpleVerticalStackPanelWdgt` lays out in `_reLayoutChildren` (it IS a size-tracking container), whereas
today's panel self-lays in `_reLayoutSelf`. Consequences to trace and fix:
  - `MenuWdgt._layOutAndHugRowsPanel` currently calls `@rowsPanel._reLayoutSelf()` at popUp. A stack sizes in
    `_reLayoutChildren` → hand-drive THAT (trace `SimpleVerticalStackPanelWdgt._reLayoutChildren` /
    `_positionAndResizeChildren` and call whatever actually places the rows + hugs). Same for `ListWdgt`,
    which calls `@listContents._reLayoutSelf()` at build (ListWdgt.coffee ~:103).
  - `fg revisits` (baseline 0) and `fg census` (0 movers) MUST stay at zero. A stack's `_reLayoutChildren`
    plus the settle-time up-edge can add a re-visit; if it does, that is a REGRESSION to fix at the arrange,
    not a baseline to bake.
  - width-equalization: a stack sizes each child to its own preferred width and hugs the widest for its OWN
    width, but leaves the rows their own width. Add a `_positionAndResizeChildren` (or grow/fill) override
    that widens every row to the stack width AFTER the stack sizes itself.
VERIFY: full `fg gauntlet` 11/11 over the §7 menu/list/prompt/inspector surface. **AIM BYTE-IDENTICAL.** If
pixels shift, do NOT recapture unattended (no one to eyeball) — leave §5.2e UNCOMMITTED and hand the
`fg diffpage` to the owner. STOP after two falsified shapes (owner standing rule).

### 5.3 [E] Regularize the prompt family. *Uses the 5.2a row-stack.* — ✅ LANDED 2026-07-18
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

### 5.4 [F] Rule on "one container that becomes a window/pinnable-window" — a deliberate NON-merge. *Docs-only; do FIRST (trivial, safe).* — ✅ LANDED 2026-07-18
Record *why not* rather than building it: `PanelWdgt` is the general clipping container; `WindowWdgt`'s
internal/external skin is already **derived from parentage** (drag-embed arc) so "becomes a window when
embedded" is already automatic; `PopUpWdgt` already provides pinnable/transient behaviour (and IS, after
§5.2/§5.3, the single shared home of it). A mode-flagged mega-container would re-introduce exactly the
special-casing this arc removes. The regularity win is **naming the relationship** — not collapsing them.
EXECUTE (no code): add a short subsection **"Container roles — deliberately NOT one mega-container"** to
`docs/architecture/layering-naming-convention.md` stating: **Panel** = general clipping container; **PopUp**
= Panel + transient/pin/shadow (the single shared home after §5.2/§5.3); **Window/Frame** = + chrome/identity;
a mode-flagged mega-container would re-introduce the special-casing this whole arc removed. Then flip
scorecard row **F → DONE (§5.4)** in §3.7 and mark this section ✅. No build/gauntlet (docs-only) — `git diff`
review + commit. *(Owner may overrule → separate design spike, flagged not dropped.)*

### 5.5 Regression tests for the `menu.rowsPanel.children[N]` contract. *New — closes the coverage gap §5.2d exposed.* — ✅ WALLPAPER TEST LANDED 2026-07-19 (guard-proven); ⏸ FONTS TEST DEFERRED

**OUTCOME (2026-07-19):**
- **`macroWallpaperMenuTickTracksSelection` LANDED + GUARD-PROVEN.** Opens the world > Wallpapers sub-menu
  (default "plain" ticked, image_1), picks "circles", re-opens (tick moved to "circles" + the desktop repaints
  the pattern, image_2). Merely opening the sub-menu runs `Wallpaper.updatePatternsMenuEntriesTicks` →
  `menu.rowsPanel.children[1..7].label` (the crash path). Captured dpr1+2; owner sent the visuals to eyeball.
  **Guard-proven:** temporarily reverting `Wallpaper.coffee` to `menu.children[N]` makes the test crash+fail
  (`undefined … `), confirming it is not a vacuous pass — then restored. This ALSO structurally guards the
  §5.2e menu re-base: any change that alters the menu's child structure re-breaks the tick path and this test
  catches it.
- **`macroFontsMenuTickTracksSelection` DEFERRED** (follow-up — the Wallpaper test already guards the
  `menu.rowsPanel.children[N]` bug CLASS). Diagnosis from three capture attempts + two headless probes: the
  StringWdgt fonts menu itself is fine (`str.buildContextMenu()` returns the own-menu with a working "font ➜"
  item when the String's parent is world, isDevMode true, all `topWdgtSuchThat` locators find it in a direct
  probe). Two dead-ends fixed along the way (a phantom "a String ➜" hierarchy hop that does not exist for a
  world-child; and the "➜" arrow being transliterated to "->" in the macro-source build round-trip, so a
  literal-arrow match never fires — matched arrow-free instead). But even arrow-free, the MACRO's
  input-pipeline right-click on a directly-added `StringWdgt` does not surface the item (same
  `reading 'x'` = locator-returned-undefined, before image_1) — i.e. the pipeline right-click is not opening
  the own-context-menu the direct `buildContextMenu()` call produces. Resolving that needs a WATCHED session
  (observe what menu the right-click actually opens); past this run's two-falsification budget. TODO owning
  section: this §5.5.

**Original plan (for reference — wallpaper done, fonts deferred):**
§5.2d's two production crashes (`Wallpaper` + `StringWdgt` reaching `menu.children[N]` for item labels) sailed
through the ENTIRE gauntlet because **no macro exercises a menu's tick-update path**. Add coverage so a future
menu-structure change (e.g. §5.2e) cannot silently re-break them. Author with the `/author-macro-test` skill
in `Fizzygum-tests`.
1. **`macroWallpaperMenuTickTracksSelection`** — right-click the desktop → click "wallpapers" in the world
   menu → the Wallpapers submenu opens with 7 pattern rows, the CURRENT pattern **ticked** (a ✓ prefix on its
   label). `image_1`: the menu with its tick. Then click a DIFFERENT pattern row, re-open the wallpapers
   submenu, `image_2`: the tick has MOVED to the new pattern. The screenshots ARE the assertion (tick
   position); merely opening the menu also guards the `undefined … menu.children[1].label` crash.
   Facts: world-menu item `menu.addMenuItem "wallpapers ➜", @wallpaper, "wallpapersMenu"` (`WorldWdgt` ~:2550);
   `Wallpaper.wallpapersMenu` (`src/Wallpaper.coffee`) builds a 7-row "Wallpaps" menu + `updatePatternsMenuEntriesTicks`
   (which reads `menu.rowsPanel.children[1..7].label`). Reach rows via `@getMostRecentlyOpenedMenu()` + the
   toolkit item-by-prefix helpers (`moveToItemStartingWithOfMenuAndClick_InputEvents`).
2. **`macroFontsMenuTickTracksSelection`** — same shape for a `StringWdgt` Fonts menu (`StringWdgt` ~:985
   `fontsMenu` → 9 font rows + `updateFontsMenuEntriesTicks` reading `menu.rowsPanel.children[1..9].label`);
   the current font is ticked, picking another moves the tick. Reuse an existing string-widget fixture if handy.
CAPTURE references (`node scripts/capture-macro-test-references.js <name> --dprs=1,2`), confirm both tests
PASS, and **because this is unattended, SendUserFile the captured `image_1`/`image_2`** so the owner can
sanity-check the tick visuals in the morning. To PROVE the guard bites, temporarily revert one fix
(`menu.rowsPanel.children`→`menu.children`), confirm the new test FAILS, then restore. VERIFY: `fg gauntlet`
11/11 with the two new tests in the suite.

### 5.6 `isTransparentAt`: fix the base, drop the `MenuWdgt` override, make `PromptWdgt` consistent. *Design cleanup (the parked discussion).* — ✅ LANDED as (b) 2026-07-19 (base fix (a) rejected; owner-approved the prompt override + recapture)

**OUTCOME (2026-07-19):**
- **(a) base fix REJECTED — it regressed the gauntlet by ~70 tests.** `Widget.isTransparentAt … else true` +
  deleting the `MenuWdgt` override made EVERY appearance-less widget transparent; ~70 tests (menus, inspectors,
  spreadsheets, sliders) rely on the opaque default to catch clicks over their bounds, so clicks fell THROUGH.
  The base's undefined-means-opaque is load-bearing for far more widgets than the box-drawing ones — it stays
  per-class. (The base method keeps its original body.)
- **(b) LANDED — added `PromptWdgt.isTransparentAt: -> true`** (the `MenuWdgt` override is already baseline from
  §5.2d, so this is the whole code delta). Its one visible consequence: after the close-button click in
  `macroSaveAsPromptAboveTiltedWindow`, the pointer rests over the prompt's transparent top-left rounded corner,
  so `topWdgtUnderPointer` falls THROUGH onto the tilted window's close button behind, which renders a red
  hover-highlight that was not there before (image_2 only; the value-assertions and image_1 are unchanged).
  Diffpage: dpr1 = 39 px @ (294,119); dpr2 = 189 px @ (587,238); maxΔ 245 — small, localized, hit-testing-driven.
  **The owner eyeballed it and accepted it** ("quite OK … a little distracting but not too noisy"), so
  `macroSaveAsPromptAboveTiltedWindow` was **consciously recaptured** (dpr1+2) with that approval as the reason.
- Fixes the same latent bug `MenuWdgt` had (an appearance-less pop-up wrongly opaque at its transparent corners),
  now dormant no more on prompts. Change surface: Fizzygum 1 mod (`PromptWdgt`); Fizzygum-tests 1 recapture.

**Original plan (for reference — (a) falsified, (b) landed):**
§5.2d added `MenuWdgt.isTransparentAt: -> true` because the menu draws nothing (its panel draws the box) and
`Widget.isTransparentAt` returns `@appearance?.isTransparentAt aPoint` = `undefined` for an appearance-less
widget, which `not undefined` treats as OPAQUE — so the menu's transparent rounded corners intercepted clicks
meant for a widget BEHIND it (dropping an item's hover-highlight while its submenu was open). The override is
correct but per-class; the REAL bug is the base's undefined-means-opaque, and `PromptWdgt` (also draws nothing,
composes a panel) has the identical latent bug, untested.
DO, in order:
  (a) **PRIMARY — fix the base:** `Widget.isTransparentAt: (aPoint) -> if @appearance? then @appearance.isTransparentAt aPoint else true`
      (appearance-less ⇒ draws nothing ⇒ transparent everywhere). Then DELETE `MenuWdgt.isTransparentAt` (now
      redundant). Run the FULL `fg gauntlet`. This touches hit-testing for EVERY appearance-less widget
      (menus, prompts, pop-ups, alpha-0 scroll frames…), so the risk is a click that used to land ON such a
      widget now falling THROUGH it. The gauntlet exercises thousands of clicks; **if it stays 11/11, ship (a).**
  (b) **FALLBACK if (a) regresses the gauntlet:** revert the base change, KEEP `MenuWdgt.isTransparentAt: -> true`,
      and add the SAME override to `PromptWdgt` (consistency + fixes its dormant bug). Optionally make
      MenuWdgt's self-documenting by delegating to the panel: `isTransparentAt: (p) -> @rowsPanel.isTransparentAt p`.
VERIFY: `fg gauntlet` 11/11. This is HIT-TESTING, not layout (census/revisits unaffected); byte-identical
expected (the change only alters fall-through at points that were already visually transparent). Watch the
click/hover pixel tests.

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
