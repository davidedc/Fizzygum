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
  give the content enough overflow that the button is small. Slider as a CONTROLLER, by DRAGGING its button:
  `dragSliderButtonToFraction_InputEvents(sliderOrIdentifier, [fx,fy])` does a press-drag-release ON the slider
  BUTTON (not the track) to a fraction of the slider's bounds — a non-float child drag
  (`SliderButtonMorph.nonFloatDragging` → `SliderMorph.updateValue` → `setValue` → `updateTarget`), so if the
  slider has a controller target set it drives `target[setter](value)` LIVE the whole drag. Use this (not the
  track-click verb) for a free-standing controller slider — its `mouseDownLeft` only jumps the button on a
  ScrollPanelWdgt/PromptMorph slider; a free slider responds to dragging its button. (Larger fy = larger value
  on a default slider, `smallestValueIsAtBottomEnd` false.) Window chrome: `collapseOrUncollapseWindow_InputEvents(windowWidget)`
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
  MENU CASCADE AUTO-CLOSE (on the mouse-DOWN): an open menu (and any submenu opened off it by clicking its parent
  item) is dismissed by a mouse-DOWN on a NON-menu area. The hand's `cleanupMenuWdgts` runs on every mouse-down and
  tears down the unpinned popups in `world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren` when the press lands
  outside them — the inverse of `clickMenuHeaderToPin_InputEvents`. The dismissal is on the DOWN, not the up, so to
  capture the dismissed state use the **`moveToAndMouseDown_InputEvents(positionOrWidget)`** verb (move then press,
  NO release — scheduled after the move like `moveToAndClick_InputEvents`), then `yield "waitNoInputsOngoing"`, then
  the screenshot (taken with the button still held), then `syntheticEventsMouseUp_InputEvents()`. The SAME
  press-and-hold pattern captures a float-dragged morph being DROPPED (a mouse-down drops it). (A menu is also
  dismissed by CLICKING one of its action items — which runs the action; e.g. "demo → rectangle" both dismisses the
  cascade and attaches a new rectangle to the hand.) The cascade stays open for a settle-wait screenshot before the press.
  TEXT ELLIPSISATION (no new verb): a `StringMorph2` does NOT grow to its text — when its bounds are too narrow it
  crops to the longest fitting prefix plus "…" (its `fittingSpecWhenBoundsTooSmall` DEFAULTS to
  `FittingSpecTextInSmallerBounds.CROP`; the alternative SCALEDOWN scales the text down instead, toggled by the
  "crop to fit"/"shrink to fit" menu item). So `new StringMorph2 "long text", fontSize` (give it a `backgroundColor`
  so the bounds/crop are visible) + `rawSetExtent` to a narrow width ellipsises it; a narrower extent crops more. The
  screenshot's settle repaints and re-crops, so no explicit re-layout call is needed.
  TEXT ALIGNMENT (no new verb): the converse of ellipsisation — a `StringMorph2` whose extent is LARGER than its text
  does NOT grow the text either; `fittingSpecWhenBoundsTooLarge` DEFAULTS to `FittingSpecTextInLargerBounds.FLOAT`, so
  the text floats within the bounds per two independent fields, `horizontalAlignment` (default LEFT) and
  `verticalAlignment` (default TOP). Drive alignment DIRECTLY with `str.alignLeft()/alignCenter()/alignRight()` and
  `str.alignTop()/alignMiddle()/alignBottom()` (each sets the field + `changed()`) — the exact methods the "align …"
  menu items call; a synthetic right-click on a StringMorph2 does not open a usable menu in a macro (same TextMorph2-
  family drift as soft-wrap). Give it a `backgroundColor` so the bounds, and so the float position, are visible.
  SHAPE HIT-TEST / click-through (no new verb): the pointer resolves to a morph by SHAPE, not bounding box —
  `ActivePointerWdgt.topWdgtUnderPointer` skips any morph that `isTransparentAt` the pointer and continues to the one
  behind (`ActivePointerWdgt.coffee:48`). A `BoxMorph` with a large `cornerRadius` is transparent at its four corners
  (`BoxyAppearance.isTransparentAt` is true outside the rounded arc), so a click on a corner passes THROUGH while a
  click on the opaque body hits the box. Make it observable with z-order: a left-click raises whatever it lands on
  (`Widget.mouseDownLeft → bringToForeground`), so put a `RectangleMorph` backdrop behind a rounded `BoxMorph` and click
  the box's corner (the backdrop comes forward) vs its body (the box comes forward). `new BoxMorph radius` sets the
  corner radius; `box.cornerRadius = 0; box.changed()` squares it (every corner becomes opaque).
  INTERNAL vs EXTERNAL WINDOW DROP (no new verb): a `WindowWdgt`'s 4th ctor arg is `internal` (default false).
  `WindowWdgt.rejectsBeingDropped` returns `!@internal`, and `ActivePointerWdgt.drop` forces the drop `target = world`
  when the dropped widget rejectsBeingDropped (`ActivePointerWdgt.coffee:242`) — so an EXTERNAL window dropped over a
  container lands on the desktop (NOT nested) while an INTERNAL window nests into the morph under the drop point (e.g. a
  `PanelWdgt`, `_acceptsDrops:true`). Carry a window on the hand with `win.pickUp()` (centres it on the hand) + a
  no-button `syntheticEventsMouseMove_InputEvents`, then drop with `syntheticEventsMouseClick_InputEvents()` (a
  mouse-down while float-dragging drops — the duplication-drop path, which routes through `ActivePointerWdgt.drop`).
  Prove the nesting by then moving the container (`panel.fullMoveTo …`): the nested internal window travels with it,
  the external one stays put. Dropping an internal window into an empty WINDOW (not a panel) instead makes it that
  window's CONTENT: `WindowWdgt.add` (`:179`) re-parents it `ATTACHEDAS_WINDOW_CONTENT`, `adjustContentsBounds`
  (`:384`) COUPLES their bounds (a free-floating window sizes itself to WRAP the dropped content + chrome, so on the
  drop it is the OUTER window that adapts, not the inner one), and the window relabels itself "window with an internal
  window". Thereafter dragging the window's `.resizer` (`@dragWindowResizerTo_InputEvents win, point`) resizes the
  outer window and `adjustContentsBounds` stretches the inner content to fill — so the inner window TRACKS the outer
  on every resize; the resizer visually sits at the inner window's corner because the content fills the window
  (`resizerCanOverlapContents`, `:437`).
  RECTANGULAR CLIPPING (no new verb): a `ClippingBoxMorph` is an ORDINARY `BoxMorph` that merely
  `@augmentWith ClippingAtRectangularBoundsMixin` (`ClippingBoxMorph.coffee:1-7` is the whole class body) — that mixin
  is what makes it CLIP its children to its own bounds, so a child that extends past the box is only drawn inside it.
  Build `new ClippingBoxMorph` (setColor/rawSetExtent/fullRawMoveTo, `world.add`), then add a child (`clipBox.add
  child`) and move it (`child.fullRawMoveTo …` — fine under SWCanvas, which full-renders) to STRADDLE each of the four
  edges in turn — on each it is cut off at that edge, proving the clip is the box's fixed rectangle on every side.
  LISTMORPH SCROLLING (no new verb): a `ListMorph` (`extends ScrollPanelWdgt`) is a column of selectable rows in a
  clipped viewport. Build a STANDALONE one — `new ListMorph nil, nil, [item strings]` — sized SHORTER than its content
  (`rawSetExtent`) so it overflows and shows a vertical scrollbar; then `@wheelOn list, deltaY` scrolls it (the
  ScrollPanel wheel path). Tune the wheel delta to the overflow (small overflow ⇒ a big delta reaches the bottom in one
  wheel and later shots stop changing — drop the delta so each wheel advances ~⅓). The recorded list tests drive the
  property list INSIDE an InspectorMorph; a direct `new ListMorph` isolates the widget. (Clicking a row calls
  `ListMorph.select` — `@selected`/`@active` — but the row highlight is not a reliable screenshot signal; scrolling is.)
  EDGE AUTO-SCROLL while dragging (no new verb): a `ScrollPanelWdgt` auto-scrolls when a float-dragged morph it
  `wantsDropOf` (= its `_acceptsDrops`, true for a plain list) is held near an edge band (`scrollBarsThickness*3` ≈ 30px
  from a side, OUTSIDE the inner inset). `ActivePointerWdgt.processMouseMove` (`:1063`) calls `startAutoScrolling`,
  whose per-cycle step calls `autoScroll` (`ScrollPanelWdgt.coffee:482`), scrolling toward whichever edge band the
  pointer is in (top⇒up, left⇒left, right⇒right, bottom⇒down). Pattern: build a list overflowing BOTH ways (long item
  labels ⇒ horizontal bar, many items ⇒ vertical bar), `pickUp` a rectangle (don't drop it), then
  `@syntheticEventsMouseMove_InputEvents (a point in an edge band), "no button", …` and **yield a generous time** so it
  scrolls. **TWO determinism musts:** (1) `autoScroll` has a 500ms `Date.now()` settle, so the test MUST set
  **`supportsTurboPlayback: false`** in its metadata (real-time replay, like the recorded autoScrolling test) or the
  settle never elapses; (2) hold long enough that the scroll CLAMPS at the limit, so the captured state is deterministic
  (a mid-scroll capture is time-dependent). Make the overflow VISIBLE (labels well wider than the viewport) — a tiny
  overflow scrolls invisibly.
  CARET PLACEMENT (no new verb): clicking inside an EDITABLE TextMorph2/StringMorph2 places `world.caret` at the slot
  nearest the click (`StringMorph2.mouseClickLeft`, `:1242`, gated on `@isEditable`). **A directly-constructed
  StringMorph2/TextMorph2 has `isEditable = false`** (`:43`) — so a click does NOTHING; the demo widgets set
  `isEditable = true` on creation (`WorldMorph.coffee`), so a direct fixture must do the same (`txt.isEditable = true`)
  before clicking. With a MULTI-LINE (soft-wrapped) text, `@moveToAndClickAtFractionOf_InputEvents txt, [fx, fy]` places
  the caret on the clicked line: `[0.02, firstLineFrac]` lands it BEFORE the first letter, a click PAST the end of the
  last line clamps it AFTER the last letter, and intermediate `(fx, fy)` hit per-line slots. Size the widget so the
  wrapped text FITS (a cropped one opens the "edit:" prompt). The caret is a thin vertical bar, frozen-visible during
  playback. (Distinct from caret SELECTION, which the double/triple-click and shift-click tests cover.)
  CARET ARROW-KEY NAVIGATION (no new verb): once `world.caret` is editing a text, the ARROW KEYS walk it —
  `CaretMorph.processKeyDown` (`:62-68`) maps ArrowLeft/Right/Up/Down to `goLeft/goRight/goUp/goDown`: Left/Right step one
  slot along the text (wrapping over the soft line break), Up/Down move to the slot on the adjacent line nearest the
  caret's column (clamping at the first/last line). Place the caret first (click an editable, fitting, multi-line
  TextMorph2 — the same `isEditable = true` fixture as CARET PLACEMENT), then drive
  `@syntheticEventsShortcutsAndSpecialKeys_InputEvents "ArrowUp"` / `@repeatSpecialKey_InputEvents "ArrowDown", n` (the
  generalized special-keys verbs send ANY key name as a `KeydownInputEvent` the caret routes — not just F2/Meta combos).
  Screenshot between presses; each move shifts the thin caret bar to a new, distinct position. (The keyboard counterpart
  of click-placement; distinct from caret SELECTION.)
  ATTACH "NO TARGETS" MESSAGE (no new verb): the "attach..." context-menu item (`Widget.coffee:3491` → `Widget.attach`)
  re-parents a morph onto another whose bounds INTERSECT it (`world.plausibleTargetAndDestinationMorphs`, excluding self
  + current parent). When that list is EMPTY — a morph alone on the desktop, nothing overlapping — `attach` pops a
  `MenuMorph` titled **"no morphs to attach to"** (`:3680`) at the hand instead of a "choose new parent:" target list;
  that titled, item-less menu IS the user-facing message. Build a lone widget (clear of everything else),
  `clickMenuItemOfWidget_InputEvents_Macro w, "attach..."`, screenshot. (The negative counterpart of a successful attach,
  where the handle/morph OVERLAPS a target so the list is non-empty — see the attach/target verbs.)
  LAYOUT SPACER / SPRING (no new verb): a `LayoutSpacerMorph` is a layout spring — `setMinAndMaxBoundsAndSpreadability`
  computes `maxWidth = desired + spreadability*desired/100` (Widget.coffee:4050), and the spacer's ctor passes
  spreadability `weight * LayoutSpec.SPREADABILITY_SPACERS` (= 1e8), giving it a ~1e6 max that dwarfs any cell's. In a
  STACK, the holder's spare width is absorbed almost entirely by the springs, so the cells stay at their DESIRED size.
  **Reuse the standard demo fixture for this rather than hand-rolling it: `Widget.setupTestScreen1()`** (a class method —
  the demo's "layout tests → test screen 1") builds a size ruler + 8 resizable stack holders, several shaped
  `[ spacer(w1) | adj | green | adj | blue | adj | yellow | adj | spacer(w2=2) ]` (two springs flanking three cells, the
  weight-2 right spring putting a stretched block ~⅓ from the left). Locate the holders as the world's RectangleMorphs
  with children (`world.children.filter (c) -> c instanceof RectangleMorph and c.children.length > 0`); each holder's
  resize handle is a `HandleMorph` among ITS OWN corner children (`holder.children.filter (c) -> c instanceof HandleMorph`),
  so move the holder with `fullMoveTo` (the handle travels with it) and drag the handle with
  `@syntheticEventsMouseMovePressDragRelease_InputEvents handle.center(), point`. **DRIFT/footgun:** the CURRENT layout
  settles a stretched stack's cells at their DESIRED width — so two holders look the same ONLY if their cells share a
  desired size; pick the two desired-30 holders that differ in spreadability (one MEDIUM, one NONE) to show "they look the
  same no matter the spreadability". (The recorded test's old reference shows the literal last two looking identical
  because the OLDER layout settled cells at their MIN; don't expect that pair to match now.) Two holders ⇒ two handles, so
  grab each by reference (`holder.children`-found), not the topmost-handle verb. (Converse of the proportional-cells test,
  where with no spacer the cells DO split the spare space by their spreadability ratio.)
  HOVER-TO-HIGHLIGHT a target/attach candidate (no new verb): picking a controller's "set target" or a morph's
  "attach..." opens a menu of candidate morphs (the ones whose bounds INTERSECT it). **Hovering** such an item highlights
  the morph it represents — `MenuItemMorph.mouseEnter → morphToBeHighlighted.turnOnHighlight()` (`MenuItemMorph.coffee:78`)
  adds it to `world.morphsToBeHighlighted`, and `WorldMorph.addHighlightingMorphs` (each cycle) paints a `HighlighterMorph`
  over it (mouseLeave/`turnOffHighlight` removes it). The SAME feedback works for both the "choose target:" and "choose
  new parent:" menus. Pattern: make a `ColorPaletteMorph` (a controller) OVERLAP a rectangle, `clickMenuItemOfWidget…
  "set target"` (or `"attach..."`), grab the just-opened menu with `@getMostRecentlyOpenedMenu()`, find the candidate with
  `@getTextMenuItemFromMenuByPrefix menu, "a RectangleMorph"`, then `@syntheticEventsMouseMove_InputEvents item.center(),
  "no button", …` to HOVER it (no click) and screenshot — the represented morph shows its highlight tint. (The first
  visual-feedback test; reuses the prefix-find + no-button move primitives.)
  EMBED / REPOSITION A WIDGET IN A SIMPLEDOCUMENT (no new verb): a `SimpleDocumentScrollPanelWdgt`'s inner content panel
  (`SimpleVerticalStackPanelWdgt`, `_acceptsDrops:true`) flows arbitrary widgets, not just text — dropping a widget over
  the content area inserts it into the flow. So `@dragWidgetTo_InputEvents (new HeartIconMorph …), (a Point in the doc)`
  embeds an ICON among the text (an `IconMorph` self-sizes from its appearance, so it needs no extent); dragging that
  embedded icon to a new Y RE-INSERTS it (top → bottom). **Insertion index ↔ drop Y (the footgun):**
  `SimpleVerticalStackPanelWdgt.add` (`:34-42`) inserts the widget AFTER the sibling whose vertical span (`top < y <
  bottom`) contains the drop's `positionOnScreen.y` (= the hand position at drop, `ActivePointerWdgt:250`), and APPENDS to
  the end if the Y is in a GAP between siblings or below everything — **index 0 (above the first sibling) is unreachable**.
  So to drop "near the top" aim at a sibling's CENTRE (`(doc.contents.childrenNotHandlesNorCarets())[0].center()`,
  guaranteed within its span ⇒ inserts right after it), and to drop "at the bottom" aim just below the last element
  (`lastEl.bottom()+N` ⇒ appended). A drop that lands in the blank GAP between two paragraphs silently appends instead of
  inserting there. Fill the doc with a paragraph first so "top" and "bottom" are far enough apart to read.
  WINDOW RESIZES TO ITS CONTENT (no new verb): an empty `WindowWdgt` adopts a dropped widget as its content
  (`WindowWdgt.add`, `ATTACHEDAS_WINDOW_CONTENT`) and a free-floating window sizes itself to WRAP that content, so when the
  content's own size changes the window RE-FITS. Drop a wrapping `SimplePlainTextWdgt` into a `new WindowWdgt nil,nil,nil`
  (via `@dragWidgetTo_InputEvents text, window`), then `text.setText longerString` ⇒ the wrapping text grows taller and the
  window grows; `text.setText shorterString` ⇒ it shrinks — content-driven resize, the converse of the handle-driven
  window resize. (`setText` is enough; no caret editing needed.)
  SUB-MENU NAVIGATION / HOPPING — KEEP THE COMMON CHAIN OPEN (no new verb): the world menu's arrow items OPEN a sub-menu
  on CLICK (`TriggerMorph.trigger` runs the item's action — `popUpDemoMenu`/`testMenu`/…), popped AT THE HAND POSITION
  (`PopUpWdgt.popUp` puts the new menu's top-left where you clicked). **The hop mechanic:** clicking ANY item in a menu of
  an open chain KEEPS the menus in that menu's ASCENDING pop-up hierarchy (`PopUpWdgt.hierarchyOfPopUps`, walked via
  `getParentPopUp`) and DISMISSES the DOWNSTREAM (descendant) sub-menus (the hand's `cleanupMenuWdgts`); then the clicked
  trigger opens its own sub-menu. So you DON'T dismiss-and-reopen between branches — re-click the item you need IN THE
  CHAIN and the chain is preserved UP TO it while the deeper menus vanish; the world menu (top of the chain) survives
  every hop until one final desktop click clears it. Open the world menu (`@moveToAndClick_InputEvents (new Point 75,40),
  "right button"`); find items by labelString PREFIX (`world.topWdgtSuchThat (w) -> w.labelString?.startsWith "demo"`;
  arrow GLYPH never matters; inline `topWdgtSuchThat (w) -> …` predicates compile fine in macro source). **The one
  subtlety — OCCLUSION:** a hop re-clicks a WORLD-menu sibling whose centre is covered by the sub-menu sitting over the
  world menu (sub-menus pop at the clicked point). Click each world-menu sibling at its LEFT (`@moveToAndClickAtFractionOf_InputEvents
  sibling, [0.3,0.5]`), going progressively FURTHER LEFT for each deeper hop (`[0.1,0.5]`) since that hop's sub-menu popped
  a little further left; descend (clicking a sub-menu's own item) with a plain centre click since that sub-menu is
  right-most. **Two more behaviours** the same shape gives for free: RE-POPPING a sub-menu (re-click its trigger at its
  left → re-opens shifted, common chain still up) and ONE-CLICK-DISMISSES-THE-WHOLE-CASCADE (the final desktop click tears
  down the world menu AND whatever sub-menu is still open). (Footgun banked: do NOT re-grab a hopped-to sub-menu via
  `getMostRecentlyOpenedMenu()` — a hop's auto-close runs DEFERRED cleanup that re-clears `world.freshlyCreatedPopUps`,
  so it returns `nil`; find items directly. Earlier attempts also used dismiss-and-reopen — correct behaviour but it does
  NOT show that the common chain is preserved, which is the point.)
  POP-UP (PROMPT/MENU) SHADOW ON DRAG (no new verb): a `PromptMorph` (extends `MenuMorph` extends `PopUpWdgt`) — opened by
  a morph's "transparency..." item (`Widget.transparencyPopout`, an alpha entry-field + slider + Ok/Close) — casts a drop
  shadow like every pop-up (`PopUpWdgt.popUp → addShadow`, offset (5,5) α0.2). Drag it by its TITLE BAR (the `MenuHeader`,
  reachable as `prompt.label`) with `@syntheticEventsMouseMovePressDragRelease_InputEvents prompt.label.center(), dest` —
  a press-then-drag GRABS and float-drags the whole pop-up, whereas a mere CLICK on the header would PIN it
  (`MenuHeader.mouseClickLeft → pinPopUp`); read `prompt.label.center()` live so it tracks the moved prompt. On DROP in the
  world `PopUpWdgt.justDropped` re-runs `updatePopUpShadow` (an unpinned prompt dropped on the desktop re-adds its normal
  shadow), so the shadow renders correctly at every position — a pop-up's shadow "behaves like all other menus'". (Do NOT
  drag from the prompt's CENTRE — that hits its inner field/slider, not the title.) Capture the prompt fresh right after
  it opens (`prompt = @getMostRecentlyOpenedMenu()`, before the next mouseUp clears the fresh set).
  UNPLUGGING AN INSPECTOR PART + DETACHED-CONTROLLER ASYMMETRY (no new verb): an inspector is built of ordinary widgets,
  so a sub-part can be DETACHED and KEEPS working. Its property list (`inspector.list`, a `ListMorph`/`ScrollPanelWdgt`)
  has a vertical scrollbar `inspector.list.vBar` (a `SliderMorph`; `target`=the list, `action`="adjustContentsBasedOnVBar";
  knob `inspector.list.vBar.button`). **Open the OLD small `InspectorMorph` via the DIRECT "inspect" item**
  (`clickMenuItemOfWidget_InputEvents_Macro str, "inspect"`, `Widget.coffee:3492`) — NOT `bringUpInspector_…_Macro`'s
  "dev → inspect", which opens the big `InspectorMorph2`; the small one leaves room for the detached parts. **Capture
  `scrollbar1 = inspector.list.vBar` BEFORE detaching** — the list does NOT rebuild a fresh vBar when one is picked up, so
  the reference stays valid (and resolving by reference sidesteps the recorded which-of-six-slider-buttons ambiguity).
  DETACH: right-click the knob → ancestor HIERARCHY menu → `@moveToItemStartingWithOfMenuAndClick_InputEvents
  @getMostRecentlyOpenedMenu(), "a SliderMorph"` → `@moveToItemOfTopMenuAndClick_InputEvents "pick up"` (`Widget.pickUp`
  keeps `target`/`action`) → carry (no-button move) and DROP (`syntheticEventsMouseClick_InputEvents()`) CLEAR of the
  inspector. The detached scrollbar STILL drives the list: `@dragSliderButtonToFraction_InputEvents scrollbar1, [0.5, fy]`
  scrolls it (`detachesWhenDragged` is false whenever the button's parent is a `SliderMorph`, so the knob moves in the
  track even though the slider's own parent is now the world). DUPLICATE it (same path, "duplicate" instead of "pick up";
  `fullCopy` copies the `target` reference so the copy `scrb2` ALSO drives the list) → `scrb2 = (world.children.filter (c)
  -> (c instanceof SliderMorph) and (c isnt scrollbar1))[0]`. **THE ASYMMETRY (the point of the test):** dragging `scrb2`
  scrolls the list, and the list updates its OWN `@vBar` (= `scrollbar1`) via `ScrollPanelWdgt.adjustScrollBars`, so the
  first scrollbar FOLLOWS (round-trip list↔scrollbar1); but dragging `scrollbar1` scrolls the list while `scrb2` — which the
  list has no back-reference to — stays put.
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
  (every mouseUp clears the fresh-popup set) — the reusable verb for the whole controller/target family. Its 4th
  arg `controllerMenuFraction` (default `[0.5,0.5]`) is the fractional point right-clicked to open the controller's
  menu: pass e.g. `[0.5,0.85]` for a SLIDER, whose button sits at the centre at value 50 — right-clicking the
  button opens no menu, so target its LOWER TRACK instead. Its 5th arg `controllerHierarchyPrefix` (default nil)
  handles a controller INSIDE a container: right-clicking a non-world-child opens the ancestor HIERARCHY menu, so
  pass the controller's class-name prefix (e.g. `"a SliderMorph"`) to step into its own submenu before "set target"
  (omit it for a world-child controller, which opens its menu directly). After wiring a slider, drive it live with
  `dragSliderButtonToFraction_InputEvents`. (A slider's property menu lists only NUMERIC setters — font size /
  alpha / width / height / padding — not colour channels; `setTargetAndAction` pushes the current value on binding,
  so a slider wired to "text" sets the text to its numeric value immediately.) DUPLICATING a controller+target
  composite (e.g. a panel holding a text + its sliders) deep-copies the bindings remapped to the COPY's target, so
  the copy's controllers drive the copy's target independently — what the duplication-keeps-control-separate tests
  verify. EDITING A BUTTON'S LABEL (no new verb): clicking a
  button TRIGGERS it, so to edit its caption call `button.label.edit()` directly (= `world.edit label`, sets
  `world.caret` on the label, no isEditable gate — what the "edit" menu item does), then reuse the caret verbs
  (Meta+a via `syntheticEventsShortcutsAndSpecialKeys_InputEvents`, `syntheticEventsStringKeys_InputEvents`) and
  `world.stopEditing()` to commit. Use an old-family label (a `TriggerMorph`/`MenuItemMorph` `TextMorph`, which
  re-lays-out on setText) — a `SimpleButtonMorph`'s `StringMorph2` face crops rather than resizing — and, for a
  standalone TriggerMorph, give it `centered=true` + a fixed `rawSetExtent` and `reLayout()` after each edit (it
  doesn't size its own bg to its label; a parent menu normally does).
- **Shared fixtures via verbs** — the window-in-window pair shares its whole setup through two verbs,
  **`buildExternalAndFreeInternalWindow_Macro()`** (`return [extWin, intWin]`) and
  **`dropInternalWindowIntoExternalWindow_InputEvents_Macro extWin, intWin`** (`return extWin` = the composite). See
  **"Composing macros"** just below for the general capability (a macro invoking another macro, with arguments and
  return values, including the no-arg form) and the DRY-for-code-AND-assets pattern these two verbs implement.

## Composing macros: a macro invoking another macro (args, return values, DRY for code AND assets)

A macro calls another macro (a "verb") by **bare name**, like an ordinary function — the engine
(`Macro._replaceMacroInvocationWithYieldingInvocations`) rewrites every `someMacro args` into
`yield from someMacro.call this, args`, so the callee runs inline and its own `yield`s (waits, screenshots) propagate
up to the driver. Three capabilities follow:

- **Arguments** — pass them positionally: `dropInternalWindowIntoExternalWindow_InputEvents_Macro extWin, intWin`.
- **Return values** — a subroutine may `return` data and the caller captures it, because `yield from` evaluates to the
  delegated generator's return value: `[extWin, intWin] = buildExternalAndFreeInternalWindow_Macro()`. Write an
  explicit `return …` (don't rely on CoffeeScript's implicit return inside a generator).
- **No-arg calls** — `someMacro()` works. (The rewriter runs its with-args pass FIRST; the with-args pattern's `[^\(]`
  guard skips `Macro()`, so the no-arg rewrite that follows isn't re-scanned. Before this ordering fix the no-arg form
  double-rewrote to `yield from yield from …` and errored at compile — it had simply never been used, because every
  prior subroutine call passed arguments. It's the form that makes `x = build()` read naturally.)

**DRY across two tests — for BOTH the code AND the screenshots.** When two tests share a setup, don't duplicate it:

- **Code (the fixture):** put the shared setup in `standardMacroSubroutines` as verb(s) that **return** the built
  widgets — NOT in a per-test `extraSubroutineSources` (those are embedded per test and can't be shared without copying
  the string). A fix to the fixture is then made in one place. A shared verb must take **no screenshots**: only a test's
  own `mainMacroSource`/`extraSubroutineSources` are scanned for reference-image names
  (`AutomatorEventCommandStartMacro.screenshotImageNamesFromMacroSources`), so a `takeScreenshot_…` inside a global verb
  would never get its reference preloaded. Keep the screenshots (the assertions) in each test's main macro.
- **Assets (the screenshots):** references are stored **per test**, matched by `SystemTest_<test>_image_N`, with no
  cross-test reference sharing or aliasing. So when two tests would capture the SAME state, have only ONE of them
  screenshot it; the other still builds that state (via the shared verb) but skips the shot — so an identical reference
  image is never stored under two names.

Worked example (the window-in-window pair). The shared fixture is the two verbs above.
`macroInternalWindowDroppedIntoWindowFits` calls both and screenshots the two-separate-windows state and the composite —
it **owns** the composite shot. `macroResizeWindowContainingInternalWindow` calls the same two verbs, does **not**
re-screenshot the composite, and goes straight to dragging the resizer (grow then shrink). Net: neither the setup code
nor the composite screenshot is duplicated, across two still-separate, independently-named tests.

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
