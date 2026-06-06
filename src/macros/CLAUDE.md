# CLAUDE.md — `src/macros/` (the "macro" SystemTest subsystem)

This directory is the **framework side of the high-level "macro" SystemTests**. It holds two files,
both stripped from `--homepage` (each starts with `# this file is only needed for Macros`):

- **`Macro.coffee`** — the engine (L0): parses a generator-from-a-string, rewrites verb calls into
  `yield`s, links subroutines, and installs the per-cycle pump.
- **`MacroToolkit.coffee`** — the toolkit (L1–L4): ~25 input primitives, tree locators, the reusable
  macro-verb library, and the macro-step driver/state. The world HAS-A one, as **`world.macroToolkit`**.

> The L5 *harness* (the test runner: `Automator*`, `AutomatorEventCommand*`) lives in the **sibling
> `Fizzygum-tests` repo**, not here. See `../../../Fizzygum-tests/CLAUDE.md`.

## Why macros exist (vs the old recorded tests)

A recorded test replays a frozen stream of raw mouse/keyboard coordinates and diffs screenshots — fragile,
it breaks the moment layout or a class changes. A **macro** test instead describes the test at a high level
as a generator ("find the clock, open its inspector, edit a method, screenshot") that asks the **live world**
where things are *right now* and synthesises the real input events. Resilient to layout change.

## How a macro test runs, end to end

1. The test's `tests/SystemTest_<name>/<name>_automationCommands.js` is a tiny command sequence: `ResetWorld`,
   a few `TurnOn*` determinism toggles, then **one** `AutomatorEventCommandStartMacro` carrying the test's
   macro as a string (`mainMacroSource`, plus optional `extraSubroutineSources`). Screenshot reference names
   are **not** listed — the loader extracts them from the macro source itself (every screenshot is a literal
   `takeScreenshot_InputEvents_Macro "name"` call), so there's no list to drift. The test's per-test
   self-documentation — four **mandatory** strings `intent`, `scenario`, `assertions`, `provenance` — lives
   in the **metadata** file `SystemTest_<name>.js` (alongside `description`/`tags`) and is validated at
   replay (a missing/empty one throws, by name). See `AutomatorEventCommandStartMacro`'s doc-comment — the
   single source of truth for how macro tests work.
2. `AutomatorEventCommandStartMacro.executeEventCommand` (harness) builds the macro: it calls
   **`world.macroToolkit.standardMacroSubroutines()`** to get the reusable verb library, adds any per-test
   `extraSubroutineSources`, `linkTo`s the test's `mainMacroSource`, and `start()`s it.
3. **`Macro`** does the work: `fromString` parses the generator and rewrites verb calls
   `fooMacro args` → `yield from fooMacro.call this, args`; `linkTo` concatenates the subroutine sources and
   prepends the pump header (`_addHeaderCode`); `start` seeds the macro state on `world.macroToolkit` and
   evals the linked code via **`world.macroToolkit.evaluateString`** — so the whole macro runs with
   **`@` = the MacroToolkit instance**.
4. Each `WorldMorph.doOneCycle` calls `@macroToolkit?.progressOnMacroSteps()` — the pump the header installed
   onto the instance — which advances the generator one step whenever the previous `yield` is satisfied:
   - `yield "waitNoInputsOngoing"` — wait until the input-event queue drains (`world.inputEventsQueue`),
   - `yield "waitForScreenshotReady"` — wait until the SWCanvas surface is settled + warm,
   - `yield <number>` — wait that many ms.
   Each step calls toolkit helpers that query the live tree and push timed synthetic events onto
   `world.inputEventsQueue`; `playQueuedEvents` (also in `doOneCycle`) executes them.
5. **Harness bridge:** while a macro runs, `world.macroToolkit.aMacroIsRunning` is true and
   `AutomatorPlayer.replayTestCommands` pauses (doesn't advance/finish) until the generator reports done,
   then resumes and ends the test. Screenshots: a macro calls `world.automator.player.compareScreenshots`
   in-flow (the `takeScreenshot_InputEvents_Macro` verb); `AutomatorLoader.loadImagesOfTest` preloads the
   references whose names it extracts from the macro source (the `takeScreenshot_InputEvents_Macro "name"` calls).

The one registered macro test (the regression anchor) is
`Fizzygum-tests/tests/SystemTest_macroAnalogClockInspectEdit/`.

## The layers

| Layer | What | Naming signal | Home | Ships in `--homepage`? |
|---|---|---|---|---|
| **L0** engine | `Macro.fromString` / `linkTo` / `_addHeaderCode` pump | `class Macro` | `Macro.coffee` | no |
| **L1** input primitives | push timed raw events onto `world.inputEventsQueue` | `syntheticEvents…_InputEvents`, `expoOut` | `MacroToolkit` | no |
| **L2** locators & one-shot actions | read the live widget tree, compose L1 | `…_InputEvents` (+ bare locator names) | `MacroToolkit` | no |
| **L3** macro verbs (generators) | reusable `…_InputEvents_Macro` SOURCE strings from `standardMacroSubroutines()` | `…_InputEvents_Macro` | `MacroToolkit` | no |
| **L4** driver + state | the pump stub, the `wait*` gates, the macro-step fields | (state / predicates) | `MacroToolkit` | no |
| **L5** test runner (harness) | `Automator*`, `AutomatorEventCommand*` | `Automator…` | `Fizzygum-tests/` | no |

## Naming conventions

- `syntheticEvents…_InputEvents` → **L1** primitive (synthesises raw events).
- `…_InputEvents` (no `syntheticEvents` prefix) → **L2** locator/action.
- `…_InputEvents_Macro` → **L3** verb (a generator source string; the *only* layer that `yield`s).
- `Automator…` → **L5** harness.
- **Gotcha:** a verb/subroutine name may contain **"Macro" only as a trailing suffix**. A *mid-name* "Macro"
  (e.g. `takeScreenshotForMacro_…`) breaks `Macro._replaceMacroInvocationWithYieldingInvocations`, whose regex
  rewrites every `…Macro<not-`(`>` occurrence into a `yield from`.

## The `@`-vs-`world.` authoring rule (the thing to get right)

A running macro has **`@` = the `MacroToolkit` instance**, not the world. So inside `MacroToolkit` methods
**and inside macro source strings**:

- `@x` → a **MacroToolkit** helper or macro-state field (`@syntheticEventsMouseClick_InputEvents`,
  `@findTopWidgetByClassNameOrClass`, `@aMacroIsRunning`, …).
- `world.x` → the **live world**: `world.add`, `world.inputEventsQueue`, `world.hand`,
  `world.topWdgtSuchThat`, `world.freshlyCreatedPopUps`, `world.automator…`.

Worked example (a test's `mainMacroSource`):

```coffee
theTest_InputEvents_Macro = ->
  clock = new AnalogClockWdgt
  world.add clock                              # world-tree op → world.
  yield "waitNoInputsOngoing"
  bringUpInspectorAndSelectListItem_InputEvents_Macro clock, "drawSecondsHand"  # bare verb call
  @bringcodeStringFromTopInspectorInView_InputEvents "context.restore()"        # toolkit helper → @
  yield "waitNoInputsOngoing"
  @syntheticEventsStringKeys_InputEvents "-"   # toolkit helper → @
  @clickOnSaveButtonFromTopInspector_InputEvents()
  yield "waitNoInputsOngoing"
  takeScreenshot_InputEvents_Macro "…_image_0"  # bare verb call
```

> Watch default arguments too: `orig = world.hand.position()` in a method signature is world state, not
> `@hand` — a `@`-form there silently becomes `undefined` (the syntax gate won't catch it; the macro test
> will). This was the #1 trap when the toolkit was split out of WorldMorph.

## How to add a …

- **L1 primitive** — a plain method that pushes `*InputEvent`s with scheduled times onto
  `world.inputEventsQueue`. Default the start time to `WorldMorph.dateOfCurrentCycleStart.getTime()` and
  stagger with an interval, like the existing `syntheticEvents*_InputEvents`.
- **L2 locator/action** — a plain method that reads the **live tree** (`world.topWdgtSuchThat …`,
  `world.freshlyCreatedPopUps`, a widget's children) and composes L1 primitives. No `yield`, no
  `world.automator` (that's the harness's job). Key locators: `findWidgetByTextDescription([desc,occ,total])`
  (re-find any widget by its stable `getTextDescription` — the recorded-test bridge; wraps
  `world.getMorphViaTextLabel`), `moveToAndClickAtFractionOf_InputEvents(widgetOrIdentifier,[fx,fy],button)`
  (click a fractional point inside a located widget), `findTopWidgetByClassNameOrClass`. Special keys/combos:
  `syntheticEventsShortcutsAndSpecialKeys_InputEvents("Shift+ArrowRight" | "Meta+a" | "Enter" | …)` and
  `repeatSpecialKey_InputEvents(key, count)`. Fractional clicks share
  `pointAtFractionOf(widgetOrIdentifier,[fx,fy])`. Multi-click: `doubleClickAtFractionOf` /
  `tripleClickAtFractionOf(widgetOrIdentifier,[fx,fy])` — these call `world.hand.process{Double,Triple}Click()`
  DIRECTLY (no `_InputEvents` suffix; multi-clicks are recognised by the hand, not queued). Shift-click:
  `shiftClickAtFractionOf_InputEvents(widgetOrIdentifier,[fx,fy])` moves the pointer then left-clicks with Shift
  held (the L1 `syntheticEventsMouseShiftClick_InputEvents` sets the event's shiftKey — the 4th boolean of
  Mouse{down,up}InputEvent) — in editable text a plain click sets the caret while a shift-click EXTENDS the
  selection to the click point (StringMorph2/TextMorph2.mouseClickLeft reads shiftKey: startSelectionUpToSlot
  then extendSelectionUpToSlot). The selection-extend sibling of the double-/triple-click verbs. Resize/move:
  `dragResizeMoveHandleTo_InputEvents(handleType, destPoint)` drags a "resize/move..." HandleMorph
  (`"resizeBothDimensionsHandle"` | `"moveHandle"` | `"resizeHorizontalHandle"` | `"resizeVerticalHandle"`) —
  a non-float drag (HandleMorph.nonFloatDragging resizes/moves the target). Mouse-wheel:
  `wheelOn(widgetOrIdentifier, deltaY, deltaX, [fx,fy])` scrolls over a located widget — a DIRECT hand op
  (`world.hand.processWheel`, like the multi-clicks; positive `deltaY` scrolls content DOWN), so no
  `_InputEvents` suffix. Window chrome: `closeWindow_InputEvents(windowWidget)` clicks a WindowWdgt's
  `.closeButton` (a `CloseIconButtonMorph`) — the pattern for reaching any window control button semantically
  rather than by coordinates. Clipboard: `cutSelection()` / `copySelection()` RETURN the caret's selected text
  (and cut/copy it) and `pasteText(text)` inserts text at the caret — DIRECT `world.caret.process{Cut,Copy,Paste}`
  calls (Fizzygum keeps NO internal clipboard and synthetic Meta+x/c/v can't fire the browser's clipboard events;
  carry the text in a macro-local var, exactly like the harness' `AutomatorEventCommandCut/Copy/Paste`).
  Drag-and-drop: `dragWidgetTo_InputEvents(widgetOrIdentifier, destination)` float-drags a widget (press-drag
  past the grab threshold so the hand picks it up) and drops it at a Point, or onto another widget / identifier
  (its centre) — e.g. to drop a widget INTO a container that accepts drops. (A SimpleDocument's INNER content
  panel has `_acceptsDrops:true`, so a drop over its content area re-parents the widget as a flowing paragraph —
  no "enable editing" needed, even though the OUTER scroll panel's ctor calls `@disableDrops`.)
  Slider/scrollbar: `clickOnSliderTrackAtFraction_InputEvents(sliderOrIdentifier,[fx,fy])` clicks a SliderMorph's
  TRACK (its background, OUTSIDE the button) to JUMP the button there — for a ScrollPanelWdgt's `@vBar`/`@hBar`
  this scrolls the content to that position (`SliderMorph.mouseDownLeft` non-float-drags the button to the click
  when the slider's parent is a ScrollPanelWdgt **or PromptMorph**; a slider parented to neither ignores it —
  the negative case). Click the TRACK, not the button: a click landing ON the button just grabs it (no jump), so
  give the content enough overflow that the button is small. Window chrome: `collapseOrUncollapseWindow_InputEvents(windowWidget)`
  clicks a WindowWdgt's `.collapseUncollapseSwitchButton` (a `SwitchButtonMorph` toggling Collapse/UncollapseIconButtonMorph)
  — the same verb collapses OR uncollapses depending on the window's current state (sibling of `closeWindow_InputEvents`).
  Window chrome: `dragWindowResizerTo_InputEvents(windowWidget, destination)` drags a WindowWdgt's `.resizer` (its
  bottom-right HandleMorph) to a Point (or a widget's centre) — a non-float drag resizing the window
  (HandleMorph.nonFloatDragging → setExtent); reach the window's OWN handle by reference rather than hunting a
  HandleMorph by coordinates when several windows are present. The resize sibling of close/collapse, completing
  the empty-window chrome trio.
  Menu items in a SPECIFIC menu: `moveToItemOfMenuAndClick_InputEvents(menu, label)` clicks a labelled item in a menu
  you already hold a reference to; `moveToItemOfTopMenuAndClick_InputEvents(label)` is the same on
  `getMostRecentlyOpenedMenu()`; `moveToItemStartingWithOfMenuAndClick_InputEvents(menu, prefix)` matches by label
  PREFIX — for menus whose item labels carry a variable suffix (a HandleMorph/Widget's "attach..."→"choose target:"
  menu labels each candidate `toString() + " ➜"`, e.g. "a RectangleMorph#1 ➜" — an instance number + a trailing
  arrow — and also lists the World), so match the stable class-name head ("a RectangleMorph") to hit the intended
  target rather than the first/Nth item; `moveToItemContainingOfMenuAndClick_InputEvents(menu, substring)` is the SUBSTRING
  sibling — for items whose label carries a LEADING decoration the prefix can't match, e.g. a checkmark toggle
  (`"soft wrap".tick()` renders "✓ soft wrap"; match "soft wrap"). **Use a held-reference variant whenever you touch a popup more than once** (e.g. click a slider /
  colour palette INSIDE a prompt, THEN its "Ok"): `getMostRecentlyOpenedMenu()` reads `world.freshlyCreatedPopUps`,
  which **every mouseUp clears** (`ActivePointerWdgt.processMouseUp`), so capture the popup reference right after it
  opens (while still fresh) and drive its later items through `moveToItemOfMenuAndClick_InputEvents`. (Colour picker
  trap: a `ColorPickerMorph` holds both a hue×lightness `.colorPalette` and a thin `.grayPalette` — a
  `GrayPaletteMorph`, which SUBCLASSES ColorPaletteMorph — so reach the colour one via the picker's `.colorPalette`
  accessor, not an `instanceof ColorPaletteMorph` search. The palette is `hsl(h=360·fx, 100%, l=100−100·fy)`, so
  `fy≈0.5` is a saturated colour.) Menu PINNING: `clickMenuHeaderToPin_InputEvents(menu)` clicks a menu's title
  bar (its `.label`, a MenuHeader) to PIN it — `MenuHeader.mouseClickLeft → pinPopUp` drops the popup's
  kill-on-click-outside flags (and tightens its shadow), so a later click on the empty desktop no longer dismisses
  it (an unpinned menu would vanish); pass a held menu reference. Widget DUPLICATION (no new verb — pure reuse): a
  normal widget's context menu carries a TOP-LEVEL "duplicate" item (`Widget.duplicateMenuActionAndPickItUp` =
  `fullCopy().pickUp()`), so `clickMenuItemOfWidget_InputEvents_Macro widget, "duplicate"` makes the COPY ride the
  hand (already painted on pickup); carry it with `syntheticEventsMouseMove_InputEvents` (a grabbed hand-child
  follows even a no-button move — the hand's `fullRawMoveTo` carries its children) and DROP it with
  `syntheticEventsMouseClick_InputEvents` (a mousedown drops a float-dragged morph). (A MenuMorph is NOT
  right-clickable for a context menu, so the menu-duplication recordings can't migrate this way — duplicate a normal
  widget instead.) Duplicating a COMPLEX / nested widget (e.g. the latest inspector, an `InspectorMorph2` inside a
  `WindowWdgt`): right-clicking a nested widget shows the framework's ANCESTOR HIERARCHY (disambiguation) menu — one
  "a X ➜" item per ancestor that has a menu (`Widget.buildContextMenu`/`buildHierarchyMenu`, labels are
  `toString().replace("Wdgt","")` so a WindowWdgt reads "a Window ➜"). Navigate to the desired ancestor by class-name
  PREFIX (`moveToItemStartingWithOfMenuAndClick_InputEvents menu, "a Window"`) to open ITS own menu, then click
  "duplicate". MOVING a fixture (the broken-rectangles idiom): position widgets BEFORE `world.add` (a raw
  `fullRawMoveTo` is fine — nothing is painted yet, as the framework's own `spawnInspector2` does); to move a widget
  that is ALREADY in the world use the HIGH-LEVEL **`fullMoveTo`** (`invalidateLayout` → a proper broken-rect repaint
  of both old and new regions), NOT `fullRawMoveTo` (which `fullChanged()`s only the OLD bounds before translating, so
  the new position would not repaint until something else dirties it). In-system EVAL: a macro runs arbitrary CoffeeScript against the live world with
  `world.evaluateString "code"` **directly inline** (Widget.evaluateString — compile the snippet, run it with
  `@`=world, then relayout/repaint) — the macro equivalent of the recorded `AutomatorEventCommandEvaluateString`.
  Do NOT write `@evaluateString`: MacroToolkit has its own `evaluateString` (binds `@` to the toolkit; the engine
  uses it to install the macro itself), a DIFFERENT method. No new verb is needed — it's a plain world call.
  BUTTON-TRIGGER discipline (no new verb): a button fires its action only when the mouse-down AND mouse-up land
  on the SAME morph — the gate is in the hand (`ActivePointerWdgt.processMouseUp` fires the click only `when w ==
  @mouseDownWdgt`), not in the button. To exercise "press then release elsewhere does NOT trigger", press on the
  button and release at a point off it: `@syntheticEventsMouseMovePressDragRelease_InputEvents (@pointAtFractionOf
  button, [0.5,0.5]), (new Point X, Y)`; a proper click that DOES trigger is the ordinary `@moveToAndClick_InputEvents
  button` (e.g. `@closeWindow_InputEvents win`). Fixture gotcha: parent the observable button INSIDE a container (a
  `WindowWdgt`/`PanelWdgt`), NOT bare on the world — `EmptyButtonMorph.rejectDrags` returns false only when the
  parent is the world, so a button loose on the desktop would float-drag on the press instead of staying put.
  PROPORTIONAL stack layout (no new verb): make a holder a horizontal stack by adding cells with
  `holder.add cell, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED`, then give each cell a
  share of the spare space with `cell.setMinAndMaxBoundsAndSpreadability(minPoint, desiredPoint,
  k*LayoutSpec.SPREADABILITY_MEDIUM)` (k = its weight). Position the holder with `fullMoveTo` BEFORE `world.add`, then
  `new HandleMorph holder` (it self-installs and snaps to the holder's bottom-right; one holder ⇒ one handle).
  Resize it with `@dragResizeMoveHandleTo_InputEvents "resizeBothDimensionsHandle", (new Point X, Y)` and the stack
  redistributes the cells by their spreadability — this is the first holder of `Widget.setupTestScreen1` distilled.
  CANVAS/PEN turtle drawing (no new verb): `canvas = new CanvasMorph; canvas.rawSetExtent (new Point W, H)`
  (REQUIRED — CanvasMorph ships no default extent), `canvas.fullRawMoveTo …`, `world.add canvas`; then
  `pen = new PenMorph; canvas.add pen` — a `PenMorph` draws on its PARENT when that parent is a `CanvasMorph`
  (`PenMorph.forward → @parent.drawLine` into the canvas back-buffer), so attaching it to the canvas is what wires
  the turtle to the surface. Place the turtle with `pen.fullRawMoveTo …` (turtles move raw) and call a drawing method
  DIRECTLY, e.g. `pen.sierpinski 400, 40` (synchronous) — like soft-wrap/eval, drive the method, don't reconstruct
  the recorded inspector-work-area `this.sierpinski(400,40)`.
  HIDE / SHOW + subtree (no new verb): `widget.hide()` / `widget.show()` flip `@isVisible`; the paint recursion
  short-circuits at an invisible morph BEFORE descending to its children (`Widget.preliminaryCheckNothingToDraw`
  returns true when `!@isVisible`), so hiding a mid-chain morph hides its WHOLE subtree, and `show()` restores it.
  Drive them directly (like soft-wrap) — `hide()` is the method the "hide" context-menu item calls, and `show()`
  MUST be programmatic because a hidden morph can't be right-clicked (the recordings un-hide via an inspector
  `this.children[0].show()` eval). `show()` no-ops if the morph is already effectively visible (an ancestor-chain
  AND), so a hide->show round-trip restores exactly (image-identical).
  COMPOSITE DROP-SHADOW (no new verb): a morph's shadow is added by `Widget.add`, NOT by `attach` — a widget added
  to the world (the desktop) gets the default shadow (`addShadow`, offset (4,4) alpha 0.2, `Widget.coffee:2199`),
  and a widget re-parented to any non-world parent gets `removeShadow` (`:2210`). The shadow paints as the recursive
  silhouette of the whole subtree, so `world.add parent` then `parent.add child` (attach) makes the parent's shadow
  outline the WHOLE parent+child composite. To force a shadow on a morph that never routed through `world.add`,
  call `widget.addShadow()` (default `new Point(4,4), 0.2`) explicitly.
- **L2 assertion (non-screenshot)** — `assertTopMenuItemCount(n)` (and future `assert…`) locate by meaning,
  then call `world.automator.player.recordMacroAssertion(passed, description, expected, found)` — the generic
  sink that fails the test like a screenshot mismatch (flips `allTestsPassedSoFar`, records the failing test,
  logs expected-vs-found to the SystemTests console) but, unlike the recorded menu checks, does NOT stop the
  macro. Lets a macro test assert non-visual facts (no screenshot needed).
- **L3 verb** — append a `macroSubroutines.add Macro.fromString """ …Macro = -> … """` block to
  `standardMacroSubroutines`. It's a generator SOURCE string: it may `yield` a sentinel
  (`"waitNoInputsOngoing"`, `"waitForScreenshotReady"`, or a number of ms), call toolkit helpers as `@…`, and
  call **other verbs by bare name** (the engine rewrites those into `yield from …`). Example:
  `setControllerTargetToWidgetProperty_InputEvents_Macro(controller, targetClassNamePrefix, propertyLabel)` — the
  patch-programming "set target" verb: right-click a controller (a ColorPaletteMorph / GrayPaletteMorph /
  SliderMorph / … — anything augmented with `ControllerMixin`) → "set target" (`openTargetSelector` lists only
  widgets whose bounds INTERSECT the controller, so it must OVERLAP the target) → pick the target by class-name
  PREFIX → pick the property (e.g. "color"); thereafter acting on the controller (clicking a palette, dragging a
  slider) calls `target[setter](value)`. It captures each successive menu fresh from `getMostRecentlyOpenedMenu()`
  (every mouseUp clears the fresh-popup set) — the reusable verb for the whole controller/target family.

## The delegation model (this is the first one in the codebase)

The project is phasing out mixins in favour of plain OO delegation; `MacroToolkit` is the first example.

- `world.macroToolkit` is the collaborator, created in the `WorldMorph` constructor next to the Automator:
  `if MacroToolkit? then @macroToolkit = new MacroToolkit` (the guard self-disables under `--homepage`,
  where the class is stripped — so no in-file macro marker is needed there). `world` keeps only the two
  per-cycle hooks (`doOneCycle` → `@macroToolkit?.progressOnMacroSteps()`; `updateTimeReferences` →
  `@macroToolkit.msSinceLastExecutedMacroStep` bookkeeping), both still inside their macro markers.
- There is **no** `world.progressOnMacroSteps` / `world.standardMacroSubroutines` / `world.aMacroIsRunning`
  any more — they are all `world.macroToolkit.*`.
- The pump `progressOnMacroSteps` starts as an empty stub on the instance and is **overwritten at macro
  start** by the string `Macro._addHeaderCode` emits (eval'd via `world.macroToolkit.evaluateString`, so its
  `@…` bind to the instance), then reset to `noOperation` when the generator is done.

## Framework-vs-harness rule

Anything that touches `world.automator` is a **harness** (assertion) concern, not framework. Today the verb
`takeScreenshot_InputEvents_Macro` lives in the framework verb set as a pragmatic stripped *source string*
that calls `world.automator.player.compareScreenshots`. The **sanctioned future move** is for
`AutomatorEventCommandStartMacro` to contribute that verb itself — the `extraSubroutineSources` merge-seam
already exists for exactly this.

## Build-strip contract (`--homepage`)

- `Macro.coffee` and `MacroToolkit.coffee` each start with `# this file is only needed for Macros` →
  `build.py` skips the whole file under `--homepage` (and `src/macros/*.coffee` is auto-globbed, so a new
  file here needs no manifest entry).
- In `WorldMorph.coffee`, the two cycle hooks sit inside in-file
  `# »>> this part is only needed for Macros … # this part is only needed for Macros <<«` pairs (stripped).
  The `macroToolkit: nil` field and the `if MacroToolkit?` ctor init are **unmarked** (harmless in homepage:
  the field stays `nil`, the guard is false).

## Migrating an old recorded test (the recorded-identity bridge)

The old recorded SystemTests convert to macro tests almost mechanically, because every recorded click
already stored WHAT it hit: `morphIdentifierViaTextLabel = [getTextDescription(), occurrence, total]` +
a fractional in-widget position. That triple is exactly what `findWidgetByTextDescription` /
`moveToAndClickAtFractionOf_InputEvents` consume — so a migrated macro re-finds the very same widget the
recording targeted, and follows it if it has moved.

The pipeline: `Fizzygum-tests/scripts/thin-systemtest.js` decimates a recording (82–92 % of it is
mouse-move bloat) into a readable digest of meaningful steps; the `/migrate-systemtest` skill
(`Fizzygum-tests/.claude/skills/migrate-systemtest/`) translates that digest into a macro, grounding on
the old reference screenshots. Full recipe + digest format: `Fizzygum-tests/scripts/README-migration.md`.
Proven on `SystemTest_basicWorldMenuAndBubble` (pixel-identical) and `SystemTest_addEditSaveRenameRemoveProperty`.

## Run / capture (from `../../../Fizzygum-tests`)

- One-time: `npm i` (Puppeteer).
- Run one macro test headless: `node scripts/run-macro-test-headless.js SystemTest_<name> [--dpr=N]`
  (boots `worldWithSystemTestHarness.html?sw=1&dpr=N`, runs it, prints `TEST PASSED` / `failureImages`).
- (Re)capture SWCanvas references: `node scripts/capture-macro-test-references.js <name> [--clean] [--dprs=1,2]`.
- In a browser: open the built `worldWithSystemTestHarness.html`, then
  `world.automator.loader.loadAndRunSingleTestFromName('SystemTest_<name>')`.
