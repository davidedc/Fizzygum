# CLAUDE.md — `src/macros/` (the "macro" SystemTest subsystem)

The **framework side of the high-level "macro" SystemTests**. Two files, both stripped from `--homepage`
(each starts with `# this file is only needed for Macros`):

- **`Macro.coffee`** — the engine (L0): parses a generator-from-a-string, rewrites verb calls into `yield`s,
  links subroutines, installs the per-cycle pump.
- **`MacroToolkit.coffee`** — the toolkit (L1–L4): input primitives, tree locators, the reusable macro-verb
  library, and the macro-step driver/state. The world HAS-A one, as **`world.macroToolkit`**.

This file is the **router**: architecture + the rules you must get right. Two companion docs hold the detail —
**`MACRO-PATTERNS.md`** (the per-mechanic reuse-pattern catalogue, one entry per test) and the verb
**doc-comments in `MacroToolkit.coffee`** (full signatures + behaviour). The L5 *harness* (`Automator*`,
`AutomatorEventCommand*`) lives in the sibling **`Fizzygum-tests`** repo (see
`../../../Fizzygum-tests/CLAUDE.md` and the `/author-macro-test` skill).

## Why macros exist

The old recorded tests (now removed) replayed a frozen stream of raw mouse/keyboard coordinates and diffed
screenshots — fragile, they broke the moment layout or a class changed. A **macro** describes the test as a generator ("find the clock,
open its inspector, edit a method, screenshot") that asks the **live world** where things are *now* and
synthesises the real input events. Resilient to layout change.

## How a macro test runs, end to end

1. `tests/SystemTest_<name>/<name>_automationCommands.js` is a tiny sequence: `ResetWorld`, a few `TurnOn*`
   determinism toggles, then **one** `AutomatorEventCommandStartMacro` carrying the test's macro as a string
   (`mainMacroSource`, plus optional `extraSubroutineSources`). Screenshot reference names are **not** listed —
   the loader extracts them from the `takeScreenshot_InputEvents_Macro "name"` calls in the source. The four
   **mandatory** self-doc strings — `intent`, `scenario`, `assertions`, `provenance` — live in the metadata
   `SystemTest_<name>.js` and are validated at replay (a missing/empty one throws, by name). The
   `AutomatorEventCommandStartMacro` doc-comment is the single source of truth for the format.
2. `AutomatorEventCommandStartMacro.executeEventCommand` (harness) calls
   **`world.macroToolkit.standardMacroSubroutines()`** for the reusable verb library, adds any per-test
   `extraSubroutineSources`, `linkTo`s the `mainMacroSource`, and `start()`s it.
3. **`Macro`** parses the generator and rewrites verb calls `fooMacro args` → `yield from fooMacro.call this,
   args`; `linkTo` concatenates the subroutine sources + prepends the pump header; `start` evals the linked code
   via **`world.macroToolkit.evaluateString`** — so the whole macro runs with **`@` = the MacroToolkit instance**.
4. Each `WorldMorph.doOneCycle` calls `@macroToolkit?.progressOnMacroSteps()` — the pump — which advances the
   generator whenever the previous `yield` is satisfied: `"waitNoInputsOngoing"` (the input queue drained),
   `"waitForScreenshotReady"` (SWCanvas settled + warm), or `<number>` (ms). Each step pushes timed synthetic
   events onto `world.inputEventsQueue`; `playQueuedEvents` (also in `doOneCycle`) executes them.
5. **Harness bridge:** while a macro runs `world.macroToolkit.aMacroIsRunning` is true and
   `AutomatorPlayer.replayTestCommands` pauses until the generator reports done, then ends the test. Screenshots:
   the macro calls `world.automator.player.compareScreenshots` in-flow (the `takeScreenshot_InputEvents_Macro`
   verb); `AutomatorLoader.loadImagesOfTest` preloads the references whose names it extracts from the source.

The one registered macro test (the regression anchor) is `Fizzygum-tests/tests/SystemTest_macroAnalogClockInspectEdit/`.

## The layers

| Layer | What | Naming signal | Home |
|---|---|---|---|
| **L0** engine | `Macro.fromString` / `linkTo` / `_addHeaderCode` pump | `class Macro` | `Macro.coffee` |
| **L1** input primitives | push timed raw events onto `world.inputEventsQueue` | `syntheticEvents…_InputEvents` | `MacroToolkit` |
| **L2** locators & one-shot actions | read the live tree, compose L1 | `…_InputEvents` (+ bare locator names) | `MacroToolkit` |
| **L3** macro verbs (generators) | reusable `…_InputEvents_Macro` SOURCE strings from `standardMacroSubroutines()` | `…_InputEvents_Macro` | `MacroToolkit` |
| **L4** driver + state | the pump stub, the `wait*` gates, the macro-step fields | (state / predicates) | `MacroToolkit` |
| **L5** test runner (harness) | `Automator*`, `AutomatorEventCommand*` | `Automator…` | `Fizzygum-tests/` |

All of L0–L4 is stripped from `--homepage`.

## The rules to get right

**1. `@` vs `world.`** A running macro has **`@` = the `MacroToolkit` instance**, not the world. So inside
MacroToolkit methods AND macro source strings: `@x` = a toolkit helper/field (`@syntheticEventsMouseClick_InputEvents`,
`@findWidgetByTextDescription`, `@aMacroIsRunning`); `world.x` = the live world (`world.add`,
`world.inputEventsQueue`, `world.hand`, `world.topWdgtSuchThat`, `world.freshlyCreatedPopUps`, `world.automator…`).
**Watch default arguments:** `orig = world.hand.position()` in a signature is world state — a `@`-form there
silently becomes `undefined` (the syntax gate won't catch it). This was the #1 trap when the toolkit split out of
WorldMorph.

```coffee
theTest_InputEvents_Macro = ->
  clock = new AnalogClockWdgt
  world.add clock                                 # world-tree op → world.
  yield "waitNoInputsOngoing"
  bringUpInspectorAndSelectListItem_InputEvents_Macro clock, "drawSecondsHand"  # bare verb call
  @syntheticEventsStringKeys_InputEvents "-"      # toolkit helper → @
  takeScreenshot_InputEvents_Macro "…_image_0"    # bare verb call
```

**2. Drive INPUT through the event queue, never poke the hand.** Every user input — moves, clicks, keys, the
wheel, double/triple-clicks, clipboard — must be SYNTHESISED AS A REAL `*InputEvent` pushed onto
`world.inputEventsQueue` and consumed by the normal pipeline, NOT by reaching into `world.hand`/`world.caret` and
calling `process…` directly. The queue is the whole point: it drives hit-testing, hover/`mouseEnter`, and the
playback fake-pointer overlay. Every input-synthesising verb carries the **`_InputEvents`** suffix
and ends by pushing events; callers `yield "waitNoInputsOngoing"` to drain. Double/triple-clicks just work at
every speed (recognition is proximity + the hand's real 300ms window; the verb spaces its clicks inside it) — see
"Playback speed" below; tests carry NO speed metadata. *Legitimately NOT input* (keep direct): building a fixture (`new …; world.add`,
positioning) and a behaviour whose UI trigger is genuinely blocked / is an escape hatch (`widget.hide()/show()`,
`textBox.toggleSoftWrap()`, `world.evaluateString "…"`). Never use a direct call to STAND IN for a real input.

**3. "Macro" only as a trailing suffix** in any verb/subroutine name (or token in macro source). A *mid-name*
"Macro" (`takeScreenshotForMacro_…`, or `recordMacroAssertion` written in macro source) is mangled by
`Macro._replaceMacroInvocationWithYieldingInvocations`, whose regex rewrites every `…Macro` not immediately followed
by `(` into a `yield from`. (So the assertion sink is reachable only from inside a toolkit `@assert…` method, never the source.)

## Playback speed (one global level — tests say NOTHING about it)

A single global level **`MacroToolkit.speed ∈ {normal, fast, fastest}`** controls how fast the event generators
play. It is set once at boot from **`?speed=`** (parsed in `src/boot/globalFunctions.coffee` like `?sw`/`?dpr`):
a browser run defaults to **`normal`** (watchable); the headless runner requests **`fastest`** (a full-suite sweep
drops from ~33 min to ~15 min). There is **no per-test speed metadata** — the old `supportsTurboPlayback` /
`requiresSlowPlayback` / `skipInbetweenMouseMoves` flags and the turbo/force-slow plumbing were removed; references
are **speed-INVARIANT** (the SAME committed images pass at all three levels), so they are captured once (at fastest).

Two independent axes the generators honour (`MacroToolkit.spanFactor` + the single push chokepoint `queueInputEvent`):
- **SPAN** = each gesture's time-offsets × `spanFactor` → wall-clock speed (the only real lever; events drain over
  ~their timestamp span of real wall-clock — see `WorldMorph.playQueuedEvents`). `normal` = 1.0 (byte-identical to
  the old timing), `fast` ≈ 0.3, `fastest` ≈ 0.03.
- **COUNT** = events-per-millisecond → path sampling. **Deliberately NOT thinned**: it stays full at every level, so
  a gesture emits the SAME deduped pixel path (and final pixel) at every speed — only the timestamps move.

**Non-scaled timings (the real-time SETTLE channel) live OUTSIDE the span axis** — never scaled, so a settle keeps
its real duration at every speed: a numeric **`yield N`** in a macro waits N ms of REAL wall-clock (the pump accrues
real cycle deltas), and `readyForMacroScreenshot` waits for atlas/momentum settle. Use `yield N` for a load-bearing
real-time settle (hold a drag in an auto-scroll edge band until the framework's `Date.now` timer clamps; wait for a
hover bubble). Use the verb's gesture `milliseconds` (scaled) for cosmetic gesture duration.

**Per-verb floors** keep a few frame-cadence-sensitive handlers correct at `fastest` (the verbs apply them; tests
need do nothing): a press-drag-release floors its drag SPAN (`@dragFloorMs`, count held constant) so a per-frame
sampler (`ScrollPanelWdgt` scroll-on-drag; drag-enter/leave) sees several frames; a single click floors its
down→up HOLD (`@clickHoldFloorMs`) so a held-button frame is sampled (a slider track-click's hover resolves on it).
Multi-click recognition is purely proximity + the hand's real 300ms window (a generation guard on the forget-timer
+ a non-scaled minimum gap between distinct same-spot click gestures keep separate clicks from folding).

## The verb library (index)

Full signatures + behaviour are the **doc-comments in `MacroToolkit.coffee`**; usage patterns are in
**`MACRO-PATTERNS.md`**. The families:

- **L1 primitives** (`syntheticEvents…_InputEvents`): `MouseMove`, `MouseClick`, `MouseShiftClick`,
  `MouseMovePressDragRelease`, `MouseMoveWhileDragging`, `MouseUp`, `Wheel`, `ConsecutiveLeftClicks`, `StringKeys`,
  `ShortcutsAndSpecialKeys` ("Shift+ArrowRight" | "Meta+a" | "Enter" | …); plus `repeatSpecialKey`, `moveToAndMouseDown`.
- **L2 locators**: `findWidgetByTextDescription([desc,occ,total])` (the recorded-identity bridge — wraps
  `world.getMorphViaTextLabel`), `findTopWidgetByClassNameOrClass`, `pointAtFractionOf`, `getMostRecentlyOpenedMenu`,
  `getTextMenuItemFromMenu{,ByPrefix,ByContains}`.
- **L2 actions**: clicks (`moveToAndClick`, `moveToAndClickAtFractionOf`, `doubleClickAtFractionOf`,
  `tripleClickAtFractionOf`, `shiftClickAtFractionOf`); drag/resize (`dragWidgetTo`, `dragResizeMoveHandleTo`,
  `wheelOn`, `clickOnSliderTrackAtFraction`, `dragSliderButtonToFraction`); menus (`openMenuOf`,
  `moveToItemOf{Menu,TopMenu}AndClick`, `moveToItem{StartingWith,Containing}OfMenuAndClick`, `clickMenuHeaderToPin`);
  clipboard (`cutSelection`/`copySelection`/`pasteText`); window chrome (`closeWindow`, `collapseOrUncollapseWindow`,
  `dragWindowResizerTo`); assertions (`assertTopMenuItemCount`, `assertTopMenuItemStrings`,
  `assertScreenshotsIdentical` — MANDATORY for every within-test byte-equality claim: call it right after the
  later shot with both full image names, earlier first). All `…_InputEvents`.
- **L3 verbs** (generators, `…_InputEvents_Macro`): `takeScreenshot`, `clickMenuItemOfWidget`, `bringUpInspector`,
  `bringUpInspectorAndSelectListItem`, `bringInViewAndClickOnListItemFromTopInspector`,
  `setControllerTargetToWidgetProperty`, the window-in-window fixture pair.

## Adding to the toolkit

- **L1 primitive** — a method that pushes `*InputEvent`s with scheduled times onto `world.inputEventsQueue`. Default
  the start time to `WorldMorph.dateOfCurrentCycleStart.getTime()` and stagger with an interval.
- **L2 locator/action** — a method that reads the live tree (`world.topWdgtSuchThat`, `world.freshlyCreatedPopUps`, a
  widget's children) and composes L1. No `yield`, no `world.automator` (that's the harness's job).
- **L2 assertion** (non-screenshot) — locate by meaning, then call `world.automator.player.recordMacroAssertion(passed,
  desc, expected, found)` (fails the test like a screenshot mismatch but does NOT stop the macro). MUST be a toolkit
  `@assert…` method (the sink's name has "Macro" mid-token — see rule 3).
- **L3 verb** — append a `macroSubroutines.add Macro.fromString """ …Macro = -> … """` block to
  `standardMacroSubroutines`. A generator SOURCE string: it may `yield` a sentinel, call toolkit helpers as `@…`, and
  call other verbs by bare name (the engine rewrites those into `yield from`).
- Document the new verb's **doc-comment in `MacroToolkit.coffee`**; add the SKILL's digest-kind→verb mapping row only
  if it's a migration target. Reuse existing primitives — most "new" behaviours are pure composition (see MACRO-PATTERNS.md).

## Authoring gotchas (fixture + menu)

- **Direct construction differs from the demo path.** A directly-built `StringMorph2`/`TextMorph2` has `isEditable =
  false` (`:43`) — set `txt.isEditable = true` before clicking it. A `SliderMorph` defaults to `alpha 0.1`; a
  `CanvasMorph` ships no default extent. A morph made via the demo menu (`world.create`, floats on the hand) is
  initialised differently from `new …; world.add` and can inspect differently — reproduce the menu path when it's load-bearing.
- **`fullMoveTo` vs `fullRawMoveTo`.** Before `world.add` (nothing painted yet) a raw `fullRawMoveTo` is fine; to move a
  widget ALREADY in the world use **`fullMoveTo`** (a proper broken-rect repaint of both regions) — `fullRawMoveTo` only
  dirties the OLD bounds.
- **`getMostRecentlyOpenedMenu()` is fresh-only** — every mouseUp clears `world.freshlyCreatedPopUps`. Capture a popup
  reference right after it opens and drive its later items via `@moveToItemOfMenuAndClick_InputEvents`.
- **Right-clicking a non-world child opens the ANCESTOR hierarchy menu** ("a X ➜" per ancestor) — navigate by class-name
  prefix to reach the desired ancestor's own menu (and note "pick up" lives in a morph's own hierarchy submenu, not top-level).
- **Two inspectors:** context-menu "inspect" → old `InspectorMorph`; "dev ➜ → inspect" → `InspectorMorph2` (the
  `*FromTopInspector*` helpers assume InspectorMorph2).

## Composing macros (args, return values, DRY for code AND assets)

A macro calls another by **bare name**; the engine rewrites `someMacro args` → `yield from someMacro.call this, args`,
so the callee runs inline and its `yield`s propagate up. **Arguments** pass positionally. **Return values** work because
`yield from` evaluates to the delegated generator's return value (`[a,b] = build_Macro()`) — write an explicit `return`
(don't rely on CoffeeScript's implicit return in a generator). **No-arg calls** (`someMacro()`) work. **DRY across two
tests:** put a shared fixture in `standardMacroSubroutines` as verb(s) that **return** the built widgets (NOT per-test
`extraSubroutineSources`, which can't be shared); a shared verb must take **no screenshots** (only a test's own sources
are scanned for reference names). References are stored **per test** with no aliasing, so when two tests reach the SAME
state, have only ONE screenshot it; the other reuses the fixture and skips the shot. (Worked example: the window-in-window
pair, `buildExternalAndFreeInternalWindow_Macro` + `dropInternalWindowIntoExternalWindow_InputEvents_Macro`.)

## The delegation model (the first in the codebase)

The project is phasing out mixins for plain OO delegation; `MacroToolkit` is the first example. `world.macroToolkit` is
created in the `WorldMorph` ctor: `if MacroToolkit? then @macroToolkit = new MacroToolkit` (the guard self-disables under
`--homepage`, where the class is stripped). `world` keeps only the two per-cycle hooks (`doOneCycle` →
`@macroToolkit?.progressOnMacroSteps()`; `updateTimeReferences` → bookkeeping). There is **no** `world.progressOnMacroSteps`
/ `world.aMacroIsRunning` any more — all `world.macroToolkit.*`. The pump `progressOnMacroSteps` starts as an empty stub and
is overwritten at macro start by the string `Macro._addHeaderCode` emits (eval'd via `world.macroToolkit.evaluateString`),
then reset to `noOperation` when done.

## Framework-vs-harness rule

Anything that touches `world.automator` is a **harness** (assertion) concern, not framework. Today
`takeScreenshot_InputEvents_Macro` lives in the framework verb set as a pragmatic stripped source string that calls
`world.automator.player.compareScreenshots`; the sanctioned future move is for `AutomatorEventCommandStartMacro` to
contribute that verb via the `extraSubroutineSources` merge-seam.

## Build-strip contract (`--homepage`)

- `Macro.coffee` and `MacroToolkit.coffee` each start with `# this file is only needed for Macros` → `build.py` skips
  the whole file under `--homepage` (and `src/macros/*.coffee` is auto-globbed — a new file here needs no manifest entry).
- In `WorldMorph.coffee` the two cycle hooks sit inside `# »>> … only needed for Macros … <<«` pairs (stripped); the
  `macroToolkit: nil` field and the `if MacroToolkit?` ctor init are unmarked (harmless in homepage: field stays `nil`,
  guard is false).

## History: the recorded→macro migration (closed)

Every old recorded test was migrated to a macro and the recorder + migration tooling have been removed; this
section is kept only as background. The conversion was almost mechanical: every recorded click had stored WHAT it hit —
`morphIdentifierViaTextLabel = [getTextDescription(), occurrence, total]` + a fractional position — which is exactly what
`findWidgetByTextDescription` / `moveToAndClickAtFractionOf_InputEvents` consume, so a migrated macro re-finds the very same
widget and follows it if it moved. New tests are authored as macros directly (`/author-macro-test` skill); reuse patterns
are in **`MACRO-PATTERNS.md`**.

## Run / capture (from `../../../Fizzygum-tests`)

- One-time: `npm i` (Puppeteer).
- Run one headless: `node scripts/run-macro-test-headless.js SystemTest_<name> [--dpr=N]` (boots
  `worldWithSystemTestHarness.html?sw=1&dpr=N`, prints `TEST PASSED` / `failureImages`).
- (Re)capture SWCanvas references: `node scripts/capture-macro-test-references.js <name> [--clean] [--dprs=1,2]`.
  Run that FULL flow (no `--no-build`). A verify `FAIL - no screenshots like this one` is almost always a
  stale/missing-reference artifact of a hand-rolled `--clean --no-build`, NOT nondeterminism — SWCanvas + the
  event queue are deterministic and matching is on the raw-pixel `dataHash` (the filename's `systemInfoHash` is
  unused metadata). The script rebuilds to drop cleaned refs before capture and to publish before verify.
- In a browser: open the built `worldWithSystemTestHarness.html`, then
  `world.automator.loader.loadAndRunSingleTestFromName('SystemTest_<name>')`.
