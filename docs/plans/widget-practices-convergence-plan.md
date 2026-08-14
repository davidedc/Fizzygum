# Widget-practices convergence — acting on the 2026-08-14 survey

**STATUS: AUTHORED 2026-08-14 — NOT STARTED. No source touched. Owner-gated at W3, W4b, W6b, W7, W8.**
Self-contained / runnable cold. Anchor on **symbol names** (verified 2026-08-14 at `21d5b64` +
the survey commit); line numbers drift — grep the symbol.

This plan turns the findings of
[`../measurements/widget-practices-survey-2026-08-14.md`](../measurements/widget-practices-survey-2026-08-14.md)
into an ordered, verifiable arc. The survey is the EVIDENCE (counts, class lists, per-facet
verdicts); [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md)
is the TARGET STATE (the rule each phase converges on). Read neither to execute a phase — every
fact a phase needs is restated here.

---

## 0. Goal, non-goals, honest possible verdicts

**Goal.** Close the gap between how widgets are written and how the guidelines say they should be,
**in order of (defect severity × safety)**, and — for the facets where a convention is worth keeping —
leave behind a *mechanism* that keeps it closed, at the correct severity tier.

**The survey's structural finding is the plan's organising principle:** every CONVERGED facet has a
gate, a census, or a named architecture doc behind it; every PATCHWORK facet has none. So the arc is
not only "fix 124 declarations": it is "fix what is wrong, decide what is a real convention, and give
each surviving convention a mechanism" (W9).

**Acceptance for the arc.** Full `fg gauntlet` green (build gates + dpr 1 + dpr 2 + WebKit + apps +
tier-naming + notification-settle + capstone + paint-readonly) plus `fg homepage`; every phase
byte-identical **except** the phases whose recapture budget is stated up front (W3, W7, and the
inspector member-list churn of W4) — and for those, only the budgeted tests recapture.

**Non-goals.**
- No `*Wdgt` renames (F2's `Simple*` split is PARKED — §10).
- No theming work (F26 colours — PARKED pending an owner decision on whether `PreferencesAndSettings`
  is meant to be a real theme surface).
- No new *runtime* mechanism: every check W9 proposes is build-time or advisory.
- No behaviour change is smuggled in as a cleanup. Where a normalization would change behaviour
  (W6b's idempotence guards), it is a separate, owner-gated step with its own evidence.

**Honest possible verdicts per work item** (all three are acceptable outcomes, as in
`archive/menu-slider-ctor-conversion-plan.md`):
1. **CONVERGED** — the item is brought to the guideline shape, byte-identically (or within its stated
   recapture budget).
2. **PARTIALLY CONVERGED** — part of the item lands; the residue gets a factual comment at the site
   and a `BACKLOG.md` line.
3. **BY-DESIGN** — two falsified shapes (stop rule, §6) prove the divergence is correct; record the
   evidence in §10 and **update the survey's verdict and the guidelines' exception list** so the next
   reader is not sent back down the same path.

---

## 0.5 P0 verification findings (2026-08-14, gathered while authoring)

Recorded here because they **correct the survey**, which was published minutes earlier from a
coarser scan. Both corrections are already applied to the survey; they are restated because a cold
executor working from an older copy would otherwise chase phantom work.

- **F9 is 52 classes / 124 fields, not 57 / 135.** The first scan missed two things: mixin members
  declared through the DSL (`@addInstanceProperties fromClass, …` at 6-space indent inside a
  `*Mixin = ` literal, which is **not** a `class`, so a class-only scan never opened those files),
  and `#` comments (`Widget.coffee` ~:4611 mentions `@action = that setter` inside prose). Correct
  denominators: 136 widgets assign at least one own field, **84** declare all of them, **52** have a
  gap. ⚠ Any re-derivation must parse `src/mixins/*.coffee` + `src/app-kit/*Mixin.coffee` and strip
  comments, or it will re-report `state`, `color_hover`, `color_pressed` and `action` as missing.
- **48 of the 124 fields are eight REPEATED fields** — `toolTipMessage` (11 classes), `target` (10),
  `icon` (8), `cornerSpec` (5), `title` (5), `callback` / `cornerRadius` / `seed` (3 each). So W4 is
  eight structural decisions plus ~76 clerical lines, not 124 clerical lines. This is what makes W4
  worth doing at all.
- **`toolTipMessage` has no declaration on `Widget`** (only on `ButtonWdgt` ~:23 and `MenuItemSpec`),
  yet **`Widget.startCountdownForBubbleHelp` (~:369) is the reader**, and non-button widgets set it
  (`RectangleWdgt` ~:19, `SpeechBubbleWdgt` ~:21, six `authoring-icons` classes). The icons' tooltips
  are not dead: `ToolPanelWdgt` (~:59) copies a payload's `toolTipMessage` onto the highlightable
  glass-box top, which is what makes them show. So the field is a genuine cross-family concept —
  W4b's PULL-UP question is real, not cosmetic.
- **`cornerSpec` is a named family concept with no declaration anywhere.** `layout.md` §4.2 calls it
  the carrier-owned corner KNOB; five carriers set it (`HandleWdgt`, `AnalogClockWdgt`,
  `BinOpenerWdgt`, `ModifiedTextTriangleAnnotationWdgt`, `UpperRightTriangleWdgt`) and three call
  sites read it off another object (`WorldWdgt.createDesktop` ~:643, `MenusHelper` ~:25, and the two
  `parent?.add @, undefined, @cornerSpec` sites).
- **The `_reLayout` prologue is copy-pasted in exactly 23 classes** (survey F13 shape A), listed in
  §2.5. One class already has the hook the other 23 want: `PatchNodeWdgt._layOutNodeContents`.
- **The pin-setter divergence is FOUR conventions, not three** (the survey says three). The fourth is
  `setText: (theTextContent, stringFieldWidget)` (`StringWdgt` ~:1315), where slot 2 is a *field
  widget* and the value is dug out as `stringFieldWidget.text.text`. The patch-node family
  (`setInput1..4`, `FanoutWdgt.setInput`, `SliderWdgt.setValue`) is a fifth shape in effect —
  `(newvalue, ignored)`, which silently discards the menu/prompt path's widget.
- **`census-hierarchy-duplication.js` is 0/0/0 and `check-call-separation.js` is 0/0** at authoring,
  so this arc starts from a clean advisory baseline; any non-zero after a phase is that phase's doing.
- ⚠ **Nothing in this plan has been executed or verified against a build.** It was authored in a
  container that can neither build nor run the suite. Every "byte-identical" below is a REQUIREMENT
  to be demonstrated, never a claim.

---

## 1. Cold start — workspace, commands, ground rules

- **Layout (the build aborts without it):**
  ```
  Fizzygum-all/
    Fizzygum/          ← the ONLY repo you edit
    Fizzygum-builds/   ← generated; NEVER hand-edit
    Fizzygum-tests/    ← SystemTests + Automator (separate repo; test edits need no rebuild)
    Fizzygum-website/
  ```
  The umbrella is not a git repo. Use `git -C <repo>` rather than `cd`-chains.
- **Build / verify:** `./build_it_please.sh` (runs every gate) · `./build_and_smoke.sh` (build + boot
  both entry pages) · `./build_and_test.sh` (build + whole SystemTest suite, headless, sharded,
  `speed=fastest`, dpr 1, ~1 min). Where the local `fg` wrapper exists: `fg build` · `fg lint` ·
  `fg presuite` · `fg gauntlet` · `fg homepage` · `fg critique` · `fg recapture <test>`.
- **First action:** `git -C Fizzygum status`. Expect a clean tree. If `src/**` is already dirty, STOP
  and ask.
- **One commit per phase.** Never push without explicit approval.
- **Scope every grep to `Fizzygum/src`** — `Fizzygum-builds/latest` is ~1.3 GB.
- **House invariants that bite in this arc** (each already cost someone a session):
  - `undefined` is the one absence value; `nil` is retired and gated at zero.
  - A CoffeeScript `@param` assigns the field **unconditionally** and shadows the class-level default.
  - One class per file, filename == class name; reference classes by bare identifier
    (`extends X` / `@augmentWith X` / `new X`) so the boot dependency finder sees the edge.
  - `super` is **meta-compiled** (`src/meta/Class.coffee` rewrites every form at fragment-compile
    time), so textual equivalence is not dispatch equivalence — never reason about a `super` change
    without running it.
  - Never `git stash` in this repo (a `stash pop` once emptied both the tree and the stash list).
- **No conclusions before evidence.** Do not write "byte-identical", "safe" or "no-op" in a comment,
  doc or commit message before the corresponding gate has actually passed.

---

## 2. The work items — exact anchors and current state

### 2.1 W1 · The three malformed `SliderWdgt` menu entries (survey F20) — a real defect

`src/basic-widgets/SliderWdgt.coffee`, `addWidgetSpecificMenuEntries` (~:207-238). Current text of
the first of three identically-shaped entries:

```coffee
menu.addMenuItem "floor...", @, (->
  @prompt menu.title + "\nfloor:",
    @setStart,
    @start.toString(),
    undefined,
    0,
    @stop - @size,
    true
), "set the minimum value\nwhich can be selected"
```

Two contract breaches, both provable from the callee signatures:

1. **`addMenuItem label, target, action, opts = {}`** (`MenuWdgt` ~:133 → `MenuRowsPanelWdgt` ~:181 →
   `MenuItemSpec`). Slot 3 receives a **function**, but the action is dispatched as
   `@target[@action]` (`ButtonWdgt.trigger` ~:106) — a function coerces to an undefined key.
   `ButtonWdgt.trigger` (~:100-105) carries a dev-build tripwire that **throws** on a non-string
   action, and its comment names this class: *"SliderWdgt carried the same latent misuse"*. Slot 4
   receives a **string** where `opts` is expected, so `opts.toolTip` is `undefined` and the tooltip is
   lost.
2. **`Widget.prompt (msg, target, callback, defaultContents, width, floorNum, ceilingNum, isRounded)`**
   (~:4224). The call passes `msg, @setStart, @start.toString(), undefined, 0, @stop - @size, true` —
   seven arguments where the intended eight begin `msg, @, "setStart"`. Every argument after slot 1 is
   shifted one place: `target` gets a method value, `callback` gets the current value string, `width`
   gets `0`, `floorNum` gets the ceiling, `ceilingNum` gets `true`.

The intended form, which every other `@prompt` site in the tree already uses (`Widget.transparencyPopout`
~:4203, `StringWdgt` ~:987 and ~:999, `InspectorWdgt` ~:680 and ~:704):

```coffee
menu.addMenuItem "floor...", @, "promptForFloor", toolTip: "set the minimum value\nwhich can be selected"
…
promptForFloor: (ignored, ignored2, menuItem) ->
  @prompt (menuItem?.parent?.title ? "slider") + "\nfloor:", @, "setStart", @start.toString(),
    undefined, 0, @stop - @size, true
```

⚠ The closure captured `menu.title`; a string action cannot. `MenuItemWdgt` reaches its menu as
`@parent` (the rows panel) — resolve the title the way `Widget.transparencyPopout` does
(`menuItem.parent.title`) and confirm the menu-item argument order at the call site before relying on
it. Scope: exactly three sites, all in this method; `grep -n 'addMenuItem .*(->' src` returns these
three and nothing else.

### 2.2 W2 · Teardown overrides on the public wrapper (survey F24)

Bulk teardown recurses **cores**: `Widget.fullDestroyChildren` / `closeChildren` /
`_fullDestroyNoSettle` (~:656-700) all loop `_fullDestroyNoSettle` / `_closeNoSettle`, never the
public verbs. `IconicDesktopSystemShortcutWdgt` (~:45) states the rule in a comment and overrides
`_destroyNoSettle`. Two classes override the public wrapper instead:

- `src/spreadsheet/SimpleSpreadsheetWdgt.coffee` `destroy:` (~:922) — drops keyboard focus and calls
  `world.dataflow?.removeAllEdgesOf` for every cell.
- `src/PopUpWdgt.coffee` `destroy:` (~:204) — `world.openPopUps.delete @`.

`PopUpWdgt` is the *mitigated* case, and the mitigation is visible: it also deletes from the set in
its `_closeNoSettle` core (~:217), and `WorldWdgt` (~:691-700) re-sweeps `openPopUps` every cycle with
the comment *"the destroy() function used everywhere is not recursive"*. `SimpleSpreadsheetWdgt` has
no such sweep — a sheet torn down as part of a subtree keeps its cells' dataflow edges.

### 2.3 W3 · Two `addWidgetSpecificMenuEntries` overrides that drop `super` (survey F19)

`src/demos/PointerWdgt.coffee` (~:76) and `src/IconicDesktopSystemScriptShortcutWdgt.coffee` (~:25).
Both open with `menu.addLine…` instead of `super`, so the base's block (`Widget` ~:4281) never runs and
those two widgets offer no layout submenu when they sit in a division stack or a content stack.
`ScrollPanelWdgt` (~:829) also omits it, but *conditionally and deliberately* — leave it alone.

### 2.4 W4 · Undeclared instance fields (survey F9) — 52 classes / 124 fields

The full list is reproducible with the §7 snippet. The decomposition that makes it tractable:

- **W4a — clerical, 11 classes / 13 fields, no PULL-UP question:** `ButtonWdgt` (`faceWidget`),
  `DragChargingRingWdgt` (`_lastRingCenter`), `Example3DPlotWdgt` (`edges`), `FolderWindowWdgt`
  (`internal`), `InspectorWdgt` (`resizer`, `textWidget`), `MenuItemWdgt` (`actionableAsThumbnail`),
  `PaintToolbarWdgt` (`queue`), `SimpleTextPanelWdgt` (`isTextLineWrapping`, `textAsString`),
  `SimpleVerticalStackPanelWdgt` (`padding`), `SliderButtonWdgt` (`offset`), `TextWdgt` (`alignment`).
- **W4b — the eight repeated fields (48 occurrences), each a placement DECISION:**

  | field | classes | the question |
  |---|---|---|
  | `toolTipMessage` | 11 | declare on `Widget` (the reader `startCountdownForBubbleHelp` lives there) or on each setter? |
  | `target` | 10 | `ControllerMixin` declares it for controllers; the shortcut / prompt / console families each re-declare it as a `@param`. One home or four? |
  | `icon` | 8 | `WidgetHolderWithCaptionWdgt` + the shortcut family + the generic-icon family |
  | `cornerSpec` | 5 | the carrier-owned corner knob — `Widget`, or a `layout.md`-named family base? |
  | `title` | 5 | the `IconicDesktopSystem*` shortcut family — pull up to `IconicDesktopSystemShortcutWdgt` |
  | `callback` | 3 | `CodePromptWdgt`, `ErrorsLogViewerWdgt`, `IconicDesktopSystemWindowedAppLauncherWdgt` |
  | `cornerRadius` | 3 | `MenuRowsPanelWdgt`, `SpeechBubbleWdgt`, `ToolTipWdgt` (`BoxWdgt` already declares it) |
  | `seed` | 3 | the three `Example*PlotWdgt` — pull up to `GraphsPlotsChartsWdgt` |

- **W4c — the four big classes:** `WorldWdgt` (16), `SimpleSpreadsheetWdgt` (16), `CellWdgt` (7),
  `SheetHeaderCellWdgt` (4) — plus `FrameWdgt` (6), `FridgeMagnetsWdgt` (4), `SpeechBubbleWdgt` (4),
  `IconicDesktopSystemWindowedAppLauncherWdgt` (4).

### 2.5 W5 · The 23-fold `_reLayout` prologue (survey F13)

Shape A, verbatim in each of: `AxisWdgt`, `BinWdgt`, `ButtonWdgt`, `CodePromptWdgt`,
`ColorPickerWdgt`, `ConsoleWdgt`, `ErrorsLogViewerWdgt`, `FanoutWdgt`, `FridgeMagnetsWdgt`,
`GenericObjectIconWdgt`, `GenericShortcutIconWdgt`, `PatchNodeWdgt`, `PlotWithAxesWdgt`, `ScriptWdgt`,
`SimpleLinkWdgt`, `SimpleSpreadsheetWdgt`, `SpeechBubbleWdgt`, `StretchableCanvasWdgt`,
`StretchablePanelWdgt`, `StretchableWidgetContainerWdgt`, `SwitchButtonWdgt`, `ToolPanelWdgt`,
`WidgetHolderWithCaptionWdgt`.

```coffee
_reLayout: (newBoundsForThisLayout) ->
  newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout
  if @_handleCollapsedStateShouldWeReturn() then return
  @_applyGrantedBounds newBoundsForThisLayout      # bounds FIRST — gated
  …the only part that varies…
  super
  @_markLayoutAsFixed()
```

Shape B (container: `super` then `@_reLayoutChildren()`) is the other 9 and is already the guideline
shape — leave it alone.

### 2.6 W6 · The pin-setter contract (survey F22) — five shapes in the tree

A pin setter is reached along two paths that put the value in **different argument slots**:

- **wire** — `DataflowEngine._applyWireValue` (~:359) calls `consumer[action] value` → raw value in
  **slot 1**;
- **menu / prompt / button** — `ButtonWdgt.trigger` (~:106) calls
  `@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, arg1, arg2`, and
  `CodePromptWdgt` (~:50) calls `@target[@callback].call @target, undefined, @textWidget` → the
  value-giving **widget in slot 2**.

| shape | reads | sites |
|---|---|---|
| A `(valueOrWidget, widgetGiving)` — coerce slot 2 | `widgetGiving?.getColor?()` / `.getValue?()` | `Widget.setColor` ~:2486, `setBackgroundColor` ~:2501, `setPadding*` ×5 ~:4332-4396, `setAlphaScaled` ~:4399, `BoxWdgt.setCornerRadius` ~:15, `StringWdgt.setFontSize` ~:1369, the `PanelWdgt`/`ScrollPanelWdgt` overrides, the two layout-spec setter families |
| B `(valueOrWidget)` — coerce slot 1 | `valueOrWidget.getValue?()` | `SliderWdgt.setStart` ~:260, `setStop` ~:276, `setSize` ~:307 |
| C `(newvalue, ignored)` — discard slot 2 | nothing | `SliderWdgt.setValue` ~:146, `CalculatingPatchNodeWdgt.setInput1..4`, `DiffingPatchNodeWdgt.setInput1`, `RegexSubstitutionPatchNodeWdgt.setInput1`, `FanoutWdgt.setInput`, `FanoutPinWdgt.setInput` |
| D `(theTextContent, stringFieldWidget)` — dig `.text.text` out of slot 2 | a *field* widget | `StringWdgt.setText` ~:1315, `SimpleTextWdgt.setText` ~:140, `FizzytilesCodeWdgt.setText` ~:11 |
| E plain value | nothing | `NumberPromptWdgt.takeSliderValue` ~:32 (a pure sink; correct as-is) |

Secondary divergence: the **idempotence guard** (`return if @color?.equals aColor`) and the
**return-the-coerced-value tail** exist in shape A and are absent from B, C and D.

### 2.7 W7 · Self-description (survey F21)

164 of 270 widgets answer the base `colloquialName` → `"generic widget"`; 257 answer the base
`representativeIcon` → `new WidgetIconWdgt`. Consumers that put the string on screen: `FrameWdgt`
(~:344 and ~:363, window titles), `InspectorWdgt` (~:67), `ConsoleWdgt` (~:13),
`ActivePointerWdgt` (~:284, the drag-embed hint), `Widget` (~:3558, the shortcut auto-namer).
The non-icon classes among the 164 include `ButtonWdgt`, `CreatorButtonWdgt`, `CodeAreaWdgt`,
`FanoutWdgt`, `AxisWdgt`, `BinOpenerWdgt`, `CaretWdgt` and the whole plot-creator-button family.

### 2.8 W8 · Constructor parameter shape (survey F4/F5)

- `src/LabelButtonWdgt.coffee` — **17** positional slots (~:30-48).
- `src/ButtonWdgt.coffee` — **12** positional slots (~:36-50).
- `src/NumberPromptWdgt.coffee` — 9.
- The `@param` shadowing consequence: `IconButtonWdgt` (~:41-45), `CreatorButtonWdgt` (~:26-29) and
  `EditorContentPropertyChangerButtonWdgt` (~:40-42) each carry a **parallel shadow field**
  `iconToolTipMessage`, copied into `@toolTipMessage` after `super`, precisely because `ButtonWdgt`
  takes `@toolTipMessage` as a parameter defaulting to `undefined`. `IconButtonWdgt`'s comment says so.

Precedent for the conversion: `21d5b64` (`SliderWdgt`: positional numbers + an options object) and
`archive/menu-slider-ctor-conversion-plan.md`.

⚠ **W8 overlaps `plans/constructor-parameter-conformance-plan.md` P3** (authored the same day, from
the constructor survey rather than the widget survey). That plan states the general RULE — now
[`architecture/constructor-and-parameter-conventions.md`](../architecture/constructor-and-parameter-conventions.md)
— sweeps all five families that carry it (the button family is one of them), and seeds the
`positional-hole` ratchet. **The button conversion is ONE piece of work; do it once.** Whichever arc
reaches it first executes it and the other de-scopes to a pointer. The shadow-field finding above is
this section's own and must ride along either way: the options conversion is what lets those three
`iconToolTipMessage` fields be DELETED rather than perpetuated.

---

## 3. The core engineering facts every phase rests on

1. **The one-flush invariant.** One settle per outermost public mutation; low-level code never
   settles. A public mutator is a thin wrap over its `_<name>NoSettle` core
   (`check-thin-wraps.js`); anything inside a layout pass, a constructor, a notification callback or a
   teardown chain calls cores. Rules [A]–[T] in `check-layering.js`.
2. **Bulk teardown recurses cores** (§2.2) — this is the whole of W2.
3. **The duplicator walks own enumerable properties** and restores into `Object.create(prototype)`;
   serialization drives off name strings. A prototype declaration is what makes a lazily-initialised
   field visible to duplication, serialization and the inspector — the whole of W4.
4. **⚠ The mixin/class-body ORDER trap.** `src/meta/Class.coffee` (~:376-382) emits **all**
   `augmentWith` calls **before** all class-body fields, and
   `Object::addInstanceProperties` (`src/boot/extensions/Object-extensions.coffee` ~:22) writes
   `@::[key] = value`. So a class-body `foo: undefined` added to a class whose chain mixes in a
   `foo` **CLOBBERS the mixin's value**. This is the exact mechanism behind the
   `census-property-placement` PULL-UP false positive that "would have turned the desktop icons
   near-white" (`archive/duplication-triage-2026-07-15-hierarchy-round4.md`). **Before adding any
   declaration in W4, check the field against every mixin in the chain** (§7 snippet does this).
5. **Adding a property to a class whose instances a SystemTest inspects lengthens that test's member
   list.** This is a *benign* recapture, not a diff to chase — but it must be budgeted, and it is why
   W4b's "declare on `Widget`" option is the expensive one (every inspector test).
6. **`colloquialName` is DRAWN** (§2.7). Adding one to a class whose window title or hierarchy-menu
   entry appears in a screenshot moves pixels. This is why W7 is owner-gated, not clerical.
7. **A wire carries no value** — `_fireConnection` marks the producer stale and the drain PULLS
   `dataflowValue`. Delivery routes to `_<action>Connector` when the target defines one, else to the
   public `@action` (`DataflowEngine._applyWireValue`). W6 must not disturb either lane.
8. **Determinism.** Render/layout/input must be a pure function of the event stream and final
   geometry — no wall-clock, timers, frame counts or randomness. `../../Fizzygum-tests/DETERMINISM.md`.

---

## 4. Why the obvious approach does not just drop in

- **W1** — the three entries capture `menu.title` in a closure; a string action cannot close over
  anything, so the title has to be recovered from the menu-item argument (`menuItem.parent.title`,
  the `Widget.transparencyPopout` idiom). Confirm the argument the menu machinery actually passes
  before relying on it — `@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, …`
  means the *menu item* is not automatically slot 3.
- **W2** — moving `SimpleSpreadsheetWdgt.destroy`'s body to `_destroyNoSettle` makes it run on paths
  it never ran on (every bulk teardown of a subtree containing a sheet, including `resetWorld`
  between SystemTests). That is the POINT, and it is also the risk: `removeAllEdgesOf` on a
  half-torn-down model must tolerate a `@model` that is already gone. Read
  `SimpleSpreadsheetWdgt._recommitAllCells` / `model.forEachCell` before moving.
- **W4b** — see §3.4 (mixin clobber) and §3.5 (inspector member lists). Also: `target` is *already*
  declared by `ControllerMixin` for controllers; pulling a second `target` onto `Widget` would give
  every widget a prototype `target` and change what the inspector and the target-chooser menus show.
  The safe direction is a **family base**, not `Widget`, unless the owner wants the global concept.
- **W5** — the prologue is not pure boilerplate: the trailing `super` runs the base's corner pass and
  its own `_applyMoveTo`/`_applyExtent`, so a template method must call the hook **between**
  `_applyGrantedBounds` and `super`, exactly where the copies do. Moving the hook one line either way
  changes the frame children see. `check-relayout-bounds-first.js` will catch the bounds half; nothing
  catches the ordering half except the suite.
- **W6** — widening a setter to accept both slots is purely ADDITIVE and should be byte-identical.
  Adding the **idempotence guard** is NOT: a wired circuit that currently re-fires on an equal value
  would stop, which is the desired behaviour but *is* a behaviour change, observable in the
  patch-programming and °C↔°F converter macros. Hence W6a (widen) and W6b (guard, owner-gated) are
  separate.
- **W7** — see §3.6. Also, a colloquial name flows into the shortcut auto-namer, so adding one can
  change generated shortcut names, which appear in folder windows.
- **W8** — `LabelButtonWdgt`'s 17 slots are forwarded positionally from `MenuItemWdgt` (~:18) and
  `MenuItemSpec` (~:38). The conversion is therefore a three-class change, and `MenuItemSpec` is the
  serialized carrier of menu-item state — changing its shape touches snapshots.

---

## 5. Phases — one per commit point, ordered by (defect severity × safety)

Ordering principle: fix defects first, then invisible structure, then the items that move pixels or
need an owner decision, then the mechanism that keeps it all closed.

**W0 — preliminaries (no edits).**
1. `git -C Fizzygum status` clean; `fg gauntlet` green as a baseline (record the suite count).
2. Re-derive the §2 counts with the §7 snippet; if any differs from this plan, fix the plan first.
3. **Recapture-risk survey** (do this ONCE, it serves W3/W4/W7): grep
   `../Fizzygum-tests/tests/**/*_automationCommands.js` for the tests that (a) screenshot an
   inspector member list, (b) screenshot a window title bar, (c) open a widget context menu. Write the
   three lists into §10. These are the only tests any phase here can legitimately recapture.
4. `node ./buildSystem/census-property-placement.js` and `census-hierarchy-duplication.js` — record
   the starting numbers, so a phase's effect on them is visible.

**W1 — the SliderWdgt menu entries.** (§2.1) Convert all three to string actions + `opts`, add the
three small action methods, verify the tooltips appear. Verdict 1 expected.
Coverage: any macro opening a slider's context menu, plus the scrollbar-heavy macros incidentally
(every `ScrollPanelWdgt` bar is a `SliderWdgt`). Recapture budget: **0**, unless a test already
screenshots the (currently tooltip-less) slider menu — then one budgeted recapture, noted in §10.

**W2 — teardown tier.** (§2.2) Move both bodies from `destroy` to `_destroyNoSettle`, `super` first.
Delete the now-redundant `world.openPopUps.delete @` if and only if the core already covers every
path — otherwise keep both and say why. Consider whether `WorldWdgt`'s per-cycle `openPopUps` sweep
(~:691) can then go; **do not remove it in this phase** — bank it as a follow-up with evidence.
Recapture budget: **0**.

**W3 — the two missing `super`s.** (§2.3) *Owner-gated*: this ADDS menu entries to two widgets, so
any test opening those menus recaptures. Ask first (D1). Recapture budget: whatever W0.3 list says.

**W4 — field declarations.** Three commits.
- **W4a** (11 classes / 13 fields) — pure additions, each checked against §3.4. Recapture: only the
  inspector member-list tests from W0.3, and only if they inspect one of these classes.
- **W4b** (the eight repeated fields) — one owner decision per field (D2), then execute. Prefer a
  **family base** over `Widget` wherever a family base exists; `toolTipMessage` is the one genuine
  `Widget` candidate, and it is also the most expensive.
- **W4c** (the four big classes) — `WorldWdgt` and `SimpleSpreadsheetWdgt` first; both are
  inspected rarely and hold the most state.

**W5 — the `_reLayout` template.** (§2.5) Add the hook to `Widget` (name it for the role —
`_layOutOwnContents`, empty base), convert the 23 classes one small batch at a time (suggested
batches: the 5 code-area/prompt classes · the 4 stretchable classes · the 5 icon/holder classes · the
rest). Byte-identity is the acceptance; any diff means the hook is in the wrong place (§4).
Recapture budget: **0** — a diff here is a bug, never a new baseline.

**W6a — widen the pin setters.** (§2.6) ⚠ **Coordinate with
[`connector-ubiquity-and-reflection-plan.md`](connector-ubiquity-and-reflection-plan.md) first** — that
arc (authored the same day) re-examines the whole pin protocol from the other end (a controller is a
view of the value it controls; what announces itself, and which classes can be a source at all), and
its §2 inventories the same setter tables. If it lands first, re-derive §2.6 against the tree it
leaves. If this lands first, W6a is a pure widening that its work sits on top of. Either way the two
must not edit the same setter bodies in parallel.

Bring shapes B, C and D to shape A's coercion, keeping each body's existing clamping and firing
untouched:
```coffee
value = widgetGiving?.getValue?() ? valueOrWidget?.getValue?() ? valueOrWidget
```
Purely additive: a caller that passed a raw value in slot 1 still lands on the same branch. Include
the `return <coerced>` tail. Recapture budget: **0**.

**W6b — idempotence guards.** *Owner-gated* (D3): adds `return @foo if @foo is foo` to shapes B/C/D.
Behaviour change (§4). Run the patch-programming and converter macros explicitly.

**W7 — self-description.** *Owner-gated* (D4). Add `colloquialName` to the substantial classes among
the 164 (start with the ~30 non-icon ones listed in survey F21), and `representativeIcon` to anything
that can be referenced from the desktop. Recapture budget: the window-title and menu lists from W0.3.

**W8 — constructor shapes.** *Owner-gated* (D5), and the largest blast radius. Order:
`ButtonWdgt` (12 → essentials + `opts`) → `LabelButtonWdgt` (17 → essentials + `opts`, with
`MenuItemWdgt`/`MenuItemSpec`) → retire the three `iconToolTipMessage` shadow fields by taking
`toolTipMessage` plainly and assigning it guarded. Recapture budget: **0** (a pure signature change
must not move a pixel); any diff is a faithfulness bug in the call-site rewrite.

**W9 — make it stick.** Give each surviving convention a mechanism at the right severity tier
(`lint-and-static-checks.md` §3b: sound negative → hard gate; count-shaped smell → ratcheted stink;
heuristic → advisory census).
- **HARD GATE — `check-menu-actions.js`.** A `[@.]addMenuItem` call whose 3rd argument is a function
  literal (`(->` / `->` / `=>`), or whose 4th argument is a string literal, is *provably* wrong
  (`@target[<function>]`; `opts` is an object). Sound negative, zero false positives, and W1 makes it
  land green. Extend to `[@.]prompt` whose 3rd argument is not a string literal.
- **ADVISORY CENSUS — `census-widget-conformance.js`** (exit 0, `--json`): re-derives the survey's
  mechanical facets on demand — undeclared fields (mixin-aware, comment-stripped), missing
  `colloquialName`, constructor slot counts, `_reLayout` prologue copies, pin-setter shapes, classes
  with no header comment. This is what turns the survey from a one-off into something re-runnable, and
  it is the correct tier: every one of those signals needs a human to confirm.
- **RATCHET** the census's two most objective headline counts (undeclared fields; prologue copies)
  the way `check-stinks.js` ratchets, so the numbers cannot climb back.
- ⚠ Do **not** gate `colloquialName` coverage, `super`-in-menu-overrides, or the setter shapes:
  each has a legitimate exception in the tree today (`ScrollPanelWdgt`'s conditional forward,
  `NumberPromptWdgt`'s pure sink), so a gate would cry wolf and train people to reach for
  `--noSyntaxCheck`.

**W10 — closeout.**
1. Sync `architecture/widget-authoring-guidelines.md`: any rule that turned out to have a real
   exception gains it; any rule that gained a gate flips `[convention]` → `[gated — <file>]`.
2. Add a **"state at close"** delta table to the survey (never rewrite its measurements — it is a
   dated snapshot; append).
3. `lint-and-static-checks.md`: add the W9 gate + census rows.
4. `git mv` this plan to `archive/`, stamp the status, add the `archive/INDEX.md` line, remove the
   `BACKLOG.md` lines for everything that landed and rewrite the rest as residual items.
5. Full `fg gauntlet` + `fg homepage`.

---

## 6. Verification protocol (every phase)

- `fg lint` (≈2 s) → `fg presuite` (≈3.5 min) after EVERY shape, before moving on.
- **Byte-identity is the default acceptance.** A screenshot diff in a phase whose recapture budget is
  **0** means the shape is wrong ⇒ revert. Never recapture past a diff you did not predict.
- Where a phase has a budget, the budgeted tests are named in §10 *before* the work, from W0.3 — a
  test that recaptures without being on the list is a finding, not a formality.
- **Two-falsification stop rule:** if two shapes of the same item fail, your model of the code is
  wrong. Stop, write the evidence into §10 as verdict 3, move on. Do not try a third variant.
- Arc end: full `fg gauntlet` (dpr 1 + dpr 2 + WebKit + apps + tier-naming + notification-settle +
  capstone + paint-readonly) + `fg homepage`.
- A phase that changes anything a snapshot carries (W4, W6, W8) also runs the serialization
  round-trip: `cd ../Fizzygum-tests && node scripts/serialization-roundtrip-headless.js`.

---

## 7. Reproducing the work lists

Run from `Fizzygum/`. This is the scanner the plan's counts come from; it is mixin-aware and
comment-stripping (§0.5), which the survey's first pass was not.

```python
# python3 - <<'PY'   (from the Fizzygum repo root)
import os, re
src = {}
for dp, _, fn in os.walk('src'):
    for f in fn:
        if f.endswith('.coffee'):
            src[os.path.join(dp, f)] = open(os.path.join(dp, f), encoding='utf-8').read()
cls = {}; mix = {}
for p, s in src.items():
    m = re.search(r'^class\s+(\w+)(?:\s+extends\s+(\w+))?', s, re.M)
    if m: cls[m.group(1)] = (m.group(2), s)
    m = re.search(r'^(\w+Mixin)\s*=', s, re.M)
    if m: mix[m.group(1)] = s
def strip(s):  # naive, same trade the repo's own scanners make
    return '\n'.join(l if l.find('#') < 0 else l[:l.find('#')] for l in s.split('\n'))
def chain(c):
    out = [c]
    while cls.get(c, (None,))[0]: c = cls[c][0]; out.append(c)
    return out
def decls(n):
    if n in cls: return set(re.findall(r'^  ([A-Za-z_]\w*)\s*:\s*(?!\(|->|=>)', cls[n][1], re.M))
    if n in mix: return set(re.findall(r'^\s{4,}([A-Za-z_]\w*)\s*:\s*(?!\(|->|=>)', mix[n], re.M))
    return set()
def mixinsOf(c): return re.findall(r'@augmentWith\s+(\w+)', cls.get(c, (None, ''))[1])
for c in sorted(cls):
    if 'Widget' not in chain(c)[1:] and c != 'Widget': continue
    ch = chain(c); s = strip(cls[c][1])
    declared = set()
    for a in ch + sorted({m for x in ch for m in mixinsOf(x)}): declared |= decls(a)
    written = set(re.findall(r'@([a-z_]\w*)\s*=(?!=|>)', s))
    m = re.search(r'^  constructor:\s*\(([^)]*)\)', s, re.M | re.S)
    params = set(re.findall(r'@([A-Za-z_]\w*)', m.group(1))) if m else set()
    miss = sorted(x for x in (written | params) if x not in declared)
    if miss: print(f'{c:44s} {len(miss):2d}  ' + ', '.join(miss))
# PY
```

Other lists: `grep -rn '^  _reLayout:' src` (W5) · `grep -rn '^  colloquialName:' src` (W7) ·
`grep -rn 'addMenuItem .*(->' src` (W1) · `grep -rn '^  set[A-Z]\w*: *(' src` (W6).

---

## 8. Landmines (each bought with evidence — do not rediscover)

- **⚠⚠ Mixin clobber (§3.4).** A class-body field added to a class whose chain mixes the same name in
  silently overrides the mixin value, because `augmentWith` is emitted before class-body fields. The
  survey's own first pass fell into the adjacent trap (reporting mixin-injected fields as
  undeclared). Check every W4 addition.
- **`super` is meta-compiled** — textual equivalence is not dispatch equivalence, and a trailing space
  after a bare `super` once silently dropped forwarded arguments (the reason
  `check-trailing-whitespace.js` exists). Relevant to W3, W5, W8.
- **CoffeeScript binds a subclass's constructor params only AFTER `super()`** — a base constructor
  calling a virtual builder sees them unbound. This is why `ScrollPanelWdgt` uses `_buildScrollFrame`
  and `MenuRowsPanelWdgt` uses `_buildMenuLabel`. Relevant to W8.
- **A `@param` assigns unconditionally** and shadows the class default — the reason the three
  `iconToolTipMessage` shadow fields exist (W8), and a live hazard whenever W4 adds a default to a
  class that also takes that field as a `@param`.
- **Adding properties to a base class is not pixel-free for inspector tests** (§3.5).
- **`colloquialName` is drawn** (§3.6).
- **The 2026-07-02 meaning swap:** in history before that date, `_applyExtent` names what is today
  `_applyExtentBase`. Reading old commits around the layout code will mislead otherwise.
- **`world.openPopUps` is swept every cycle** (`WorldWdgt` ~:691) — so W2's `PopUpWdgt` half fixes a
  latent tier violation, not a visible leak. Do not oversell it in the commit message.
- **Never recapture your way past a diff** in a zero-budget phase.

---

## 9. Owner decisions

| # | Decision | Recommendation |
|---|---|---|
| D1 | **W3** — add the base menu block to `PointerWdgt` and `IconicDesktopSystemScriptShortcutWdgt`? (adds layout entries; recaptures their menu shots) | **Yes** — the omission looks accidental (both open with `menu.addLine`), and the entries are the base affordance every other widget has. |
| D2 | **W4b** — for each of the eight repeated fields, `Widget` / family base / leave? | **Family base wherever one exists**; `Widget` only for `toolTipMessage` (its reader is already on `Widget`), accepting the inspector recapture. `target` stays per-family — a `Widget.target` would collide conceptually with `ControllerMixin`'s. |
| D3 | **W6b** — add idempotence guards to the B/C/D setters? (behaviour change: a wired circuit stops re-firing on an equal value) | **Yes, but as its own commit**, after W6a is green, with the patch-programming + converter macros run explicitly. |
| D4 | **W7** — is the `"generic widget"` label worth a recapture round? | **Yes for the ~30 substantial non-icon classes**, no for the icon leaves (their colloquial name rarely reaches a title bar). |
| D5 | **W8** — convert `ButtonWdgt`/`LabelButtonWdgt` to options objects? | **Yes, last**, and only if W1–W6 landed clean: it is the highest-churn item and the one most likely to reveal a call site nobody knew about. |
| D6 | **F26 colours** — should `PreferencesAndSettings` become a real theme surface (40 classes hard-code channel triples)? | **Park** until there is a second theme to serve. Recorded in §10. |

---

## 10. Parked — recorded so they are not re-proposed

- **F2 — the `Simple*` prefix's two meanings.** A rename touches identifiers, filenames and
  serialization, and menu/hierarchy labels strip `Wdgt`, so it is not pixel-free. Low value against
  that cost. Revisit only if a `Simple*` class is being renamed for another reason.
- **F7 — five geometry verbs in constructors.** The right output is a *stated criterion*, which
  `widget-authoring-guidelines.md` §3.6 now has. Converting existing sites is not worth a suite run
  each; convert opportunistically when a constructor is touched for another reason.
- **F11 — the 32 constructor-assigned appearances.** The factory form buys an override point; a leaf
  class that nothing subclasses gains nothing. Convert only when a class grows a subclass.
- **F12 — `isTransparentAt` on the widget vs the appearance.** Doc-only: the guidelines state the
  rule ("hit-testing follows the shape"); no code change proposed.
- **F23 — always-on stepping subscriptions.** A performance question (an idle widget costs a slot in
  the once-per-cycle walk), not a correctness one, and `Widget._destroyNoSettle` already keeps the set
  honest. Needs a measurement before it needs a change.
- **F26 — hard-coded colours** (D6).
- **F3 — missing header comments.** Not a phase: a drive-by rule. Any file this arc opens gets its
  header comment before the commit.

---

## 11. Status ledger

- **2026-08-14 — AUTHORED (this doc).** No code changes. Companion docs committed the same day:
  `measurements/widget-practices-survey-2026-08-14.md` (evidence) and
  `architecture/widget-authoring-guidelines.md` (target state). Survey corrected in the same commit
  as this plan for the two §0.5 findings (F9 → 52 classes / 124 fields; the eight repeated fields).
- W0 preliminaries: ☐
- W1 SliderWdgt menu entries: ☐
- W2 teardown tier: ☐
- W3 missing `super`s (D1): ☐
- W4a / W4b (D2) / W4c field declarations: ☐ ☐ ☐
- W5 `_reLayout` template: ☐
- W6a widen setters / W6b guards (D3): ☐ ☐
- W7 self-description (D4): ☐
- W8 constructor shapes (D5): ☐
- W9 gate + census + ratchet: ☐
- W10 closeout: ☐

---

## 12. Cross-links

- Evidence: [`../measurements/widget-practices-survey-2026-08-14.md`](../measurements/widget-practices-survey-2026-08-14.md)
- Target state: [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md)
- Mechanics this arc must respect: [`../architecture/layering-naming-convention.md`](../architecture/layering-naming-convention.md) ·
  [`../architecture/layout.md`](../architecture/layout.md) ·
  [`../architecture/serialization-duplication-reference.md`](../architecture/serialization-duplication-reference.md) ·
  [`../architecture/widget-citizenship.md`](../architecture/widget-citizenship.md)
- Gate/severity policy + how to add a check: [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md) §3b
- Closest precedent for the phase shape and the stop rule:
  [`../archive/menu-slider-ctor-conversion-plan.md`](../archive/menu-slider-ctor-conversion-plan.md);
  the constructor contract it locked in: [`../archive/all-constructors-settle-plan.md`](../archive/all-constructors-settle-plan.md)
- **Sibling arc, same territory:** [`connector-ubiquity-and-reflection-plan.md`](connector-ubiquity-and-reflection-plan.md)
  — the pin protocol seen from the value's side (the controller-is-a-view law). Overlaps W6; see §5.
- Case law on why census findings are questions, not instructions:
  [`../archive/duplication-triage-2026-07-15-hierarchy-round4.md`](../archive/duplication-triage-2026-07-15-hierarchy-round4.md) ·
  [`../archive/census-findings-triage-plan.md`](../archive/census-findings-triage-plan.md)
