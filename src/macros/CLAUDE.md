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
  DIRECTLY (no `_InputEvents` suffix; multi-clicks are recognised by the hand, not queued). Resize/move:
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
- **L2 assertion (non-screenshot)** — `assertTopMenuItemCount(n)` (and future `assert…`) locate by meaning,
  then call `world.automator.player.recordMacroAssertion(passed, description, expected, found)` — the generic
  sink that fails the test like a screenshot mismatch (flips `allTestsPassedSoFar`, records the failing test,
  logs expected-vs-found to the SystemTests console) but, unlike the recorded menu checks, does NOT stop the
  macro. Lets a macro test assert non-visual facts (no screenshot needed).
- **L3 verb** — append a `macroSubroutines.add Macro.fromString """ …Macro = -> … """` block to
  `standardMacroSubroutines`. It's a generator SOURCE string: it may `yield` a sentinel
  (`"waitNoInputsOngoing"`, `"waitForScreenshotReady"`, or a number of ms), call toolkit helpers as `@…`, and
  call **other verbs by bare name** (the engine rewrites those into `yield from …`).

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
