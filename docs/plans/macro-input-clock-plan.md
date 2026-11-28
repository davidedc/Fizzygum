# The macro INPUT CLOCK: event time from the macro's schedule, never from the cycle a wait ended in

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**

**STATUS: AUTHORED 2026-11-28, NOTHING BUILT. The owner, 2026-11-28: run it AFTER the inspector-browser loop finishes (its
whole-suite runs would clash with the loop's), and both of its asks are GRANTED in advance — WorldWdgt's method ceiling
136 → 137 (U2) and the new `WALL_CLOCK_STAMP` rule in `check-macro-source-discipline.js` (U3).**
- Every fact in §1 was read off the tree at Fizzygum `58d48282` / Fizzygum-tests `d97074a2c` (497 SystemTests, 483 of them
  playable under a finger, on 2026-11-28).
- Every number in §2 and §4 was MEASURED on that tree on 2026-11-27/28: by a reproduction (§2.3), a whole-suite census
  (§2.4), and a prototype of this design injected into the real page with no source change (§4.3).
- The investigation's scripts and reports live under
  `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/inspector-browser-loop/{uf,up}/`, which is gitignored.
  So every number this plan rests on is written out here, and Appendix A says how to rebuild the instruments.
- The design in §4 corrects two points the prototype got wrong: the due clock across a non-empty queue (§4.1), and where
  the clock starts and ends (§4.1). Both corrections are UNMEASURED, and U2 measures them (marked NEW MEASUREMENT).
- Line numbers drift: the quoted method or symbol name is authoritative, so grep it fresh before trusting a number.

## Mandate

ELIMINATE a class of nondeterminism, not make it rarer: **an under-window hold bounded by a wall-clock wait.**
- **The class.** A macro starts a hold with one event (a carried window comes to rest over a container, a finger
  presses) and ends it with an event queued in a LATER step, after any wait (`yield N`, `yield "waitNoInputsOngoing"`, a
  screenshot). Every such hold today is the wall-clock length of the waits in between. A recognizer that must NOT fire
  (the drag-embed dwell, 450 ms; a finger's press-and-hold, 500 ms) then fires whenever the machine is slow enough.
- **Done means** both of these hold:
  1. Every synthetic event's time is a pure function of the macro's own schedule, and a wait of any kind, under any
     load, does not change a hold.
  2. A macro cannot stamp an event from the wall clock: the toolkit refuses one at its one chokepoint, and a build gate
     refuses one in a macro source.
- **Out of scope:**
  - Which events share a cycle (DETERMINISM.md §3j/§3o, the drain SHAPE), a different class; see §8, fixed pacing.
  - The product's own wall-clock mechanisms (the edge auto-scroll's `Date.now` 500 ms settle), which keep their real
    time.

## §0 Orientation

### 0.1 Fizzygum and its macro tests
- **Fizzygum** is a CoffeeScript GUI framework rendered on one `<canvas>`. Its behavioural tests are SystemTests
  (`Fizzygum-tests/tests/`).
- **Each test is a MACRO:** a generator, compiled from a string in its `_automationCommands.js`, that asks the live world
  where things are and synthesises real input events onto `world.inputEventsQueue`. It compares screenshots byte for
  byte with committed references.
- **The engine and the verb library** are `Fizzygum/src/macros/` (`Macro.coffee`, `MacroToolkit.coffee`), which belong
  to the `harness` part, absent from every production profile.
- **The determinism contract** is `Fizzygum-tests/DETERMINISM.md`: rendered and recognised state must be a pure function
  of the EVENT STREAM. The input recognizers keep it by reading only `WorldWdgt.timeOfEventBeingProcessed`, the time of
  the event being dispatched.

### 0.2 The history: DETERMINISM.md §3k
- **2026-10-23, `SystemTest_macroDragEmbedReleaseWhileChargingLandsOnWorld`.** Four parallel-wave sightings. It carried a
  window over a panel, waited `yield 250`, then clicked. Under load the hold the dwell measures crossed 450 ms and the
  window nested. It was fixed per test with a new verb, `clickAfterHoldingStill_InputEvents 250`, which stamps the press
  in event time in the carry's own step.
- **2026-11-12, -24 and -27, `SystemTest_macroInternalVsExternalWindowDrop`.** Three gauntlet wave-B sightings (one
  tier-naming leg, two storage legs), each passing its serial retry. All three left the SAME three failing dataHashes:
  `9035a689…`, `93fa7153…`, `e282f018…`.
  - Its unarmed release came after `yield "waitNoInputsOngoing"`: a DRAIN, not a numeric yield.
  - It was root-caused and fixed per test on 2026-11-27/28 with `clickAfterHoldingStill_InputEvents 0` (Fizzygum-tests
    `d97074a2c`; DETERMINISM.md §3k, "Second case"). The proof is §2.3.
- **The census of every recognizer decision (§2.4)** then found the same shape across the suite: 88 finger
  press-and-hold decisions in 43 tests, and two more unarmed window releases, are bounded by a wall-clock wait. They are
  latent today only because no test asserts their consequence.

### 0.3 THE CRITICAL REFRAME
**A drain or a screenshot is the same wall-clock lower bound as `yield N`.**
- §3k was first read as "a numeric `yield` bounds a hold only from below". But the step after ANY wait is stamped from the
  cycle that wait happened to end in:
  - `waitNoInputsOngoing` waits at least one cycle, and two when the step before it queued a gesture with a span;
  - a screenshot waits for an atlas, a capture at the end of a cycle and an asynchronous hash.

  How long those cycles take is the machine's business.
- So the fault is not in the tests, and it cannot be fixed test by test: a hold that spans a mid-press or mid-carry
  screenshot has no event-time spelling at all today.
- **The fix belongs in the clock.** Event time must come from the macro's SCHEDULE: the gesture's own scheduled span,
  plus exactly N for `yield N`, plus a fixed ε for "looked at the world, then acted".

## §0.5 Cold-execution protocol (read this before touching anything)
1. Read, whole:
   - this plan;
   - `Fizzygum-all/CLAUDE.md`, `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`;
   - `Fizzygum/src/macros/CLAUDE.md` ("Playback speed" and "Per-verb floors");
   - `Fizzygum-tests/DETERMINISM.md` §1, §3k and §4.
2. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status`, then check what moved since this plan was measured:
   - `git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum log --oneline 58d48282.. -- src`
   - `git -C /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests log --oneline d97074a2c.. -- tests Automator-and-test-harness-src`

   If either lists commits, re-run every count in §1.5 (its commands are given there) and fix this plan's numbers
   BEFORE acting.
3. Run the units in §6 IN ORDER. Each ends at its gate, and a unit whose gate is not green is not done.
   - **Never** carry on past a red gate.
   - **Never** recapture a reference to make a gate green: the predicted failing set is EMPTY (§4.3), so a failing
     picture is a finding.
   - After two falsified attempts at the same fix, stop and report: the model is wrong.
   - **Each unit is two commits, Fizzygum first, then Fizzygum-tests**, so either repo's history builds.
4. Grants. Each of these needs the owner's word: ask with the summary and the proposed message, never act alone.
   - **every commit and push;**
   - **WorldWdgt's method ceiling 136 → 137** (`buildSystem/check-complexity-ratchets.js`, U2), with a dated reason —
     GRANTED by the owner in advance, 2026-11-28 (the dated reason still written beside the number);
   - **a NEW rule in an EXISTING gate** (`check-macro-source-discipline.js`, U3) — GRANTED by the owner in advance,
     2026-11-28 (for this rule as §4.5 specifies it; a different rule is asked anew);
   - **any doc ceiling.** Both CLAUDE.md files are AT their byte ceilings (Fizzygum 35 555, Fizzygum-tests 66 307 on
     2026-11-28, `buildSystem/check-doc-narration-baseline.json`).
5. Long ops:
   - Run them with the Bash tool's `run_in_background: true`, logging to `/tmp/…`, and wait for the notification. No
     foreground pollers; the guard hook blocks them.
   - Peek at `/tmp/fg-<cmd>.verdict` at most every ~5 min.
   - Never pipe a gating `fg` call through `tail`/`grep`.
   - Invoke `fg` by its ABSOLUTE path.
6. Model note: U1's edits are mechanical but wide. Make them with the Edit tool, one signature at a time — never a regex
   over a `.coffee` file (a blanket script edit de-indents CoffeeScript). Re-grep the counts after each batch.

## §1 The mechanism as it stands (2026-11-28; names authoritative, lines drift)

### 1.1 One wall-clock reading feeds every synthetic event
- `WorldWdgt._updateTimeReferences` (WorldWdgt.coffee:2336):
  - `WorldWdgt.dateOfCurrentCycleStart = new Date` — the world's one clock read, sanctioned by the `clock-read` stink
    (baseline 5, AT its ceiling);
  - `@macroToolkit.msSinceLastExecutedMacroStep += current − previous` — real deltas.
- `_closeCycleBookkeepingNoSettle` (:2471) makes the current value the next cycle's `dateOfPreviousCycleStart`.
- `doOneCycle` (:2349) runs `_updateTimeReferences`, then the macro PUMP (`@macroToolkit?.progressOnMacroSteps()`), then
  `_playQueuedEvents`, and later `@automator.player.advanceTestPlaying()`. So a step queues its events before its own
  cycle's drain, and a test ENDS in the cycle its macro reports done (§1.2).
- **The toolkit stamps from `WorldWdgt.dateOfCurrentCycleStart.getTime()` at 58 code sites (MacroToolkit.coffee,
  2026-11-28):**
  - **55 verb signatures** default `startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()`. One of them,
    `_syntheticEventsMousePlace_InputEvents`, names it `scheduledTimeOfEvent`. Among them:
    `syntheticEventsMouseClick_InputEvents` :807, `…MouseDown` :860, `…MouseUp` :888, `…MouseMove` :532,
    `…TouchTap` :977, `…Wheel` :1335 and `wheelOn` :1547.
  - **2 bases:**
    - `queueInputEvent` (:221, base read at :226) — the ONE push chokepoint. It compresses `event.time − base` by
      `spanFactor` (`@spanFactors` :113: normal 1, fast 0.3, fastest 0.03) unless `nonScaled`.
    - `scaledAbs` (:250, read at :251).
  - **1 re-stamp:** `_deliverHeldSwipe` (:337). Once the queue drains, it queues a translated wheel's next HELD swipe at
    `WorldWdgt.dateOfCurrentCycleStart.getTime()` (:339): a wall-clock boundary INSIDE one gesture.
  - A 59th grep hit, :209, is a comment.
- **Six PRIVATE methods call the public `queueInputEvent`:** `_queuePress`, `_queueTouchMove`, `_queueTouchCarryMove`,
  `_queueTouchUp`, `_syntheticEventsMousePlace_InputEvents`, `_selectionToClipboardEvent_InputEvents`. This matters for
  call-separation rule [S] (§4.2).
- **The floors are SPANS, relative to a gesture's start** (macros/CLAUDE.md, "Per-verb floors"):
  - `dragSpanWithFloor` :280 (`@dragFloorMs` 300 real ms), so a per-frame sampler sees several frames;
  - `clickHoldWithFloor` :290 (`@clickHoldFloorMs` 100);
  - `_queueTouchMovePath` :1051, which floors directly;
  - `@holdWindowMarginMs` 60 (:147) for a finger's scheduled hold.
- **`guardedClickStart`** (:261, `@clickGuardWindowMs` 350) keeps two same-spot click gestures apart in EVENT time.
- **`clickAfterHoldingStill_InputEvents holdMs`** (:827): a click whose press is `holdMs` after the queue's LAST event, in
  the same step. It is §3k's per-test workaround.

### 1.2 The pump, its waits, and the end of a test (Macro.coffee `_addHeaderCode`, :72)
- **First tick:** it creates the generator and places the pointer (`_syntheticEventsMousePlace_InputEvents`).
- **Each later tick:**
  1. Deliver a held swipe (`return if @_deliverHeldSwipe()`).
  2. The wait gate:
     - `"waitNoInputsOngoing"` → `noInputsOngoing` (:320): queue empty, no momentum, no knob slide (`_queueDrained` :330);
     - `"waitForScreenshotReady"` → `readyForMacroScreenshot` (:363), which does NOT require an empty queue;
     - `"waitForScreenshotHash"` → `world.automator.player.screenshotHashSettled()`;
     - a number N → `@msSinceLastExecutedMacroStep > N` (real ms);
     - anything else (a bare `yield`) → no wait.
  3. `@macroGenerator.next()`, and `msSinceLastExecutedMacroStep = 0`.
- **At the end:** the generator reports done → `aMacroIsRunning = false`, unless held swipes remain
  (`_deliverHeldSwipesThenEnd`, which delivers them first). In the same cycle `AutomatorPlayer.advanceTestPlaying` sees
  no macro running and runs `stopTestPlaying`:
  - `Automator.state = Automator.IDLE`, so `aTestIsPlaying()` is false from then on;
  - `world.browserInput.initEventListeners()` (AutomatorPlayer.coffee:282) re-attaches the real browser input that
    `removeEventListeners()` (:656) detached while the test played.
- **Measured exposure of events left queued at a macro's end:** 0 of 497 main macros queue input after their last wait
  (static scan, 2026-11-28).
- **`takeScreenshot_InputEvents_Macro`** (:3363) is a drain, a ready wait, a capture at the end of a cycle, and a hash wait:
  three observation waits.
- **Macros start only from `AutomatorPlayer._startTheTestsMacro`** (`mainMacro.start()`, :440): `Macro.start` sets
  `aMacroIsRunning` in that cycle's harness step, and the pump's FIRST tick runs in the NEXT cycle.

### 1.3 The drain (WorldWdgt.coffee `_playQueuedEvents`, :2256)
- An event is due when `event.time ≤ WorldWdgt.dateOfCurrentCycleStart.getTime()` (:2268). That is THE one built-in
  comparison of an event time with a wall time.
- A due event sets `WorldWdgt.timeOfEventBeingProcessed = event.time` (:2276) and is processed.
- The first event not yet due ends the pass (`removeEventsUpTo`), and every event behind it waits too: the queue is FIFO.
- The loop is CoffeeScript's `for event in @inputEventsQueue`, which reads the length ONCE.
- `timeOfEventBeingProcessed` is cleared at the world's teardown (`WorldWdgt` :3402), not at each cycle's tail.
  input-and-gestures.md :53–54 says otherwise (§7).
- A real browser event gets `time = Date.now()` (InputEvent.coffee:13): the same epoch as the cycle clock.

### 1.4 Every reader of time (2026-11-28)

**EVENT time** (`timeOfEventBeingProcessed`). Each is a difference of two event times, except where noted.

| reader | where |
|---|---|
| drag-embed DWELL (arms at `dwellToArmMs` 450, PreferencesAndSettings.coffee:72) | ActivePointerWdgt `_updateDragEmbedStateMachine` :488; origin `_reAnchorDragEmbedLinger` :483; re-evaluated at the release inside `drop` :693 |
| charging-ring fill | DragChargingRingWdgt `_elapsedForCharge`: event time under `aTestIsPlaying()`; off a test, `WorldWdgt.dateOfCurrentCycleStart − @lingerOriginWallTime` (a Date minus a Date) |
| finger PRESS-AND-HOLD (`pressAndHoldMs` 500, :81) | `_beginPressAndHoldRecognition` :985, `_holdDecisionTime` :1018, `_advancePressAndHoldRecognition` :1031 (the release is an evaluation point too) |
| double/triple click (`doubleClickWindowMs` 300, ActivePointerWdgt.coffee:105) | `processPointerUp` :1455 (`isStale`) |
| the acted-gesture rule | `noteClickActsForItsGesture` :1205, `_pointerContinuesAnActedGesture` :1222 |
| FrameBarWdgt piece press | FrameBarWdgt.coffee:174, :838. An EQUALITY of stamps ("one click is drained under one stamp"), so two events of different steps must never share a stamp |
| FridgeMagnets3DCanvasWdgt `timeNowSeconds` | the ABSOLUTE event time / 1000 under a test, `Date.now()` otherwise |

**WALL / cycle clock:**

| reader | where | while a test plays |
|---|---|---|
| stepping fps | `_runChildrensStepFunction` :2485; `Widget.lastTime = Date.now()` | runs |
| the edit-mode knob slide | EditIconButtonWdgt.coffee:70, :81 | runs; drains and screenshots wait for it |
| the EDGE AUTO-SCROLL | ViewportWdgt `_startAutoScrolling`, `Date.now()`, 500 ms | runs; §3m's saturation contract |
| tooltips | ToolTipWdgt.coffee:67 `setTimeout` | shown at once |
| the dataflow `seconds` source | SecondsSource.coffee:50 | runs |
| the clock widget | AnalogClockWdgt | its appearance pinned |
| caret blink, momentum glide, plot animations | — | suppressed |
| the SWCanvas atlas refresh | rAF / `setTimeout 16` | the screenshot readiness waits for it |
| the harness's own timers (start delay, run timing, DOM overlay fades) | — | no world decision |

**MIXED (an event time against a wall time):**
- the drain itself (by design; the seam this plan redefines);
- `_holdDecisionTime`'s off-test branch `Math.max eventTime, cycleTime`;
- the ring's off-test branch, with `dragEmbedLingerOriginWallTime` (:486, a Date), which only that branch reads.

The off-test branches run whenever `aTestIsPlaying()` is false. That includes the cycles after `stopTestPlaying`, so any
synthetic event still queued when its test stops is judged by them (§4.1).

### 1.5 Wall-clock stamps written into test macro sources (2026-11-28)
**30 sites in 15 tests** write `WorldWdgt.dateOfCurrentCycleStart.getTime()` as an explicit event time:

| test | sites |
|---|---|
| `macroAltGrTypesOnAPC` | 1 |
| `macroCutWithNothingSelectedCutsNothing` | 1 (a `fromBrowserEvent` time, never queued) |
| `macroEditMarkAndMenuRowOpenTheSameMember` | 1 |
| `macroEveryPressIsToldItsEnding` | 7 |
| `macroFingerSwipeOverSelectableTextScrolls` | 5 |
| `macroNestedPanesDragLatchesOnePane` | 1 |
| `macroPCChordsGoByPositionOnANonLatinLayout` | 1 |
| `macroScrollingBackReturnsContentToWhereItRested` | 4 (the `− 100` "already due" idiom) |
| `macroSheetEditLeftOpenByAPutAwayResumes` | 1 |
| `macroToolCodeSaveRefusesCodeThatDoesNotCompile` | 1 |
| `macroToolMemberThatCannotBeMadeErrsOnce` | 1 |
| `macroTrackPressInTheFatteningCycleStillPages` | 1 |
| `macroTwoEditsOnOneRingInOneCycle` | 1 |
| `macroTwoScrollStrokesInOneFrameKeepBothTravels` | 3 (`− 100`) |
| `macroWidgetDestroyedOrClosedMidStrokeIsNotPickedUpAgain` | 1 |

No macro source reads `Date.now()` or `performance.now()` in code. The four other tests whose macro files mention a clock
do so in comments or as a value (`new Date 1783122262571`).

Re-measure:
- `grep -c '= WorldWdgt.dateOfCurrentCycleStart.getTime()' /Users/davidedellacasa/code/Fizzygum-all/Fizzygum/src/macros/MacroToolkit.coffee`
  → 57 (55 signatures + 2 bases).
- `grep -c 'dateOfCurrentCycleStart' /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/tests/*/*_automationCommands.js | grep -v ':0$'`
  → the table above.

## §2 Why it is shaped this way, and the evidence that it is wrong

### 2.1 Why
- The drain must pace a gesture over real frames. Some handlers sample once per frame; macros/CLAUDE.md's "Per-verb
  floors" (`dragFloorMs`) exist for them. So a gesture's timestamps are anchored to the wall: "this move is due 18 ms
  after the cycle that queued it".
- Anchoring every NEW step to the wall too was the simplest way to keep each step's events ahead of what was already
  delivered. Nothing recorded that the time BETWEEN steps is fed to recognizers as if a person had spent it.

### 2.2 The rule it breaks
`DETERMINISM.md` §3 says state must be a pure function of the event stream, never of a wall-clock timer or a cycle count.
Today the event stream itself contains the wall clock: the gap between two steps' events is however long the waits took.

### 2.3 The proof (UF reproduction, 2026-11-27/28, single-test runs, dpr 1)
- **Model.** The unarmed drop's press is stamped at the start of the SECOND cycle after the carry's step: the pump runs
  before the drain, and the carry has a span.
  - Mouse: the carry's last event is at +15.87 ms and the dwell's linger origin at +11.70 ms, so hold = (the two cycles)
    − 11.70.
  - Finger: the carry is floored to 300 ms; the origin is at +208 and the last event at +265.
- **Levers**, injected with `--prelude=` (Appendix A):
  - a REAL busy-wait of N ms at the end of every macro cycle;
  - a VIRTUAL clock advancing `dateOfCurrentCycleStart` by exactly P per cycle (DETERMINISM §4);
  - ONE N-ms stall right after the carry's step.

| lever | mouse (hold at the drop, ms) | finger |
|---|---|---|
| idle | 23–29, pass | 72–83, pass |
| stall N (each level twice) | 200: 402/403 pass; 220: 443/443 pass; **230: 461/464 FAIL**; 240–400 FAIL | 200: 406/408 pass; **220–250 FAIL**; 300: 405/404 **pass**; 400 FAIL |
| virtual clock P (predicted exactly: mouse 2P − 11.70, finger (⌈265/P⌉+1)·P − 208) | 230: 448.30 pass; **231: 450.30 FAIL**; all 16 levels exact to 0.01 | 219: 449 pass; **220: 452 FAIL**; 265: 322 pass … 328: 448 pass; **329: 450 FAIL**; all exact |
| one stall after the carry | 440: 442.3 pass; **460: 461.3 FAIL** | 640: 447 pass; **660: 468 FAIL** |

- **The three failing runs that were dumped** (mouse stall 250, finger stall 250, mouse virtual clock 231) left the
  gauntlet's three dataHashes exactly. The other failing runs were not dumped.
- **What it rules out:**
  - The legs' own instruments: the storage and tier-naming preludes alone leave the idle hold at 23–26 ms.
  - The suite predecessor `macroInstancesRegistry`: also 23–26 ms.
  - A frame-count dependency: the linger origin is unchanged at P = 8 and 10.
- **What makes it fail:** machine load (wave B ran at a load average near 300 on 16 cores). One ~450 ms pause right
  after the carry is enough.

### 2.4 The census (UF, 2026-11-28, whole suite at idle, measure only)
- **The instrument:** a prelude that records every recognizer decision, whether the event that decided it was queued in
  a LATER step than the hold's origin (a wall-clock-bounded hold), and over how many cycles.
- **Mouse:** 2 such dwell decisions, `macroDragEmbedWindowTransitNeverArms` (80 ms over 6 cycles) and
  `macroDragEmbedCandidateChangeResets` (70 ms over 5). Both are unarmed releases after a mid-carry screenshot, and
  nothing reads where the window lands.
- **Finger:**
  - 88 press-and-hold decisions in 43 tests, plus the same two dwell releases (135 and 187 ms over 9 and 13 cycles).
  - Of the 88: 67 span one cycle, 10 span two (the flake's own exposure), 5 span three, and 6 span five or more.
  - Those 6, a press shot mid-hold then released, and the 2 dwell releases are the 8 with NO event-time spelling today.
    They are in `macroMenusCloseOnMouseDownOutside`, `macroWindowGripStrip`, `macroInspectorDividerSizesOneColumn`,
    `macroMidEditCopyAndSaveCarryNoCaret`, `macroSliderDragTracksAxisInRotatedIsland`, and the two dwell tests.
  - The other 82 could each be respelled into one step by rewriting the test.
- **At 250 ms a cycle** the hold menu FIRED in 5 of the 14 most exposed sites, and the dwell armed in both window-release
  tests. All 14 still PASSED, because no test asserts that consequence. They are latent, not flaky.

## §3 The distilled argument
1. The class is a property of the CLOCK, not of the tests. Every step after a wait is stamped from the cycle the wait
   ended in (§1.1–1.2), and recognizers decide on event time only (§1.4). So a wall-clock wait between a hold's two
   events IS the hold.
2. Fixing tests one by one (`clickAfterHoldingStill`) works only where the hold's two events can share a step. 8 live
   sites cannot (a mid-press or mid-carry screenshot needs a drain), and 82 more would each need a rewrite (§2.4).
3. So the macro must own its time: each step stamped from the schedule, waits costing exactly what they declare, and no
   path by which a wall-clock value can enter an event's time.
4. Measured before any source change: injected into the real page (§4.3), the rule passes the whole suite in every
   configuration with an EMPTY failing set. It makes the original flaky shape immune at every lever, and it makes every
   cross-step hold identical across engines, densities, epochs and pacing.

## §4 The design, and the evidence for each choice

### 4.1 The rule
While a macro plays, the toolkit keeps an INPUT CLOCK. "Wall now" means `WorldWdgt.dateOfCurrentCycleStart.getTime()`
everywhere below, in both terms of every difference. Never `Date.now()`: that would drift within a step, and would be
one more `clock-read`, a stink at its ceiling of 5.

**Two quantities:**
- **B, the STAMPING base.** Every event a macro step queues is stamped from it: every verb's default `startTime`,
  `queueInputEvent`'s base and `scaledAbs`. B is constant within a step.
- **D, the DUE clock.** The drain delivers an event once its time is ≤ D. `D = A + (wall now − W)`, from an anchor
  (A, W). Between anchors, D advances with real time, so a gesture drains over its own span of REAL time, as today
  ("wall pacing", §4.3). Per-frame samplers and the floors keep their meaning.

**`lastQueued`** is the LATEST time actually pushed onto the queue, after the speed compression.

**At each step boundary** (right before `@macroGenerator.next()`), with `lastYield` = what the previous step yielded:
- after an observation wait (any string, or a bare `yield`): `B' = max(B, lastQueued + ε)`. Looking takes no event time,
  and the next event is strictly after every event queued so far.
- after `yield N`: `B' = max(B + N, lastQueued + ε)`. The hold is exactly N. The pump still waits at least N of REAL time
  (`msSinceLastExecutedMacroStep`, unchanged), so the product's wall-clock mechanisms still get their real time.
- **The anchor moves ONLY if the queue is empty at the boundary:** then `A := B'`, `W :=` this cycle's wall now, so D = B'.
  - If events are still queued, the anchor stays and D keeps running. Then `B' > D` is guaranteed: B' ≥ lastQueued + ε,
    and the event the last drain stopped at has a time > D. So the new step's events queue behind the pending ones and
    are delivered in their turn, paced as today. Nothing is flushed, and nothing is stamped in the past.
  - Re-anchoring with events still queued would jump D past them and deliver them all in one cycle: the defect §8 rejects
    under "stamping in the past". The prototype did exactly that (§4.3). Its exposure in phase B is unknown, and is
    likely nil: the 5 sites that queue input and then wait without draining are `macroListWdgtAutoScrollsNearDraggedEdge`
    ×4 before `yield 2500` and `macroDuplicatedInspectorDrivesCopiedTargetOnly` before `yield 300`, and their gestures
    span 30–133 ms, so their queues are empty well before the yield ends. U2 counts these boundaries
    (NEW MEASUREMENT).
- **A held swipe** (`_deliverHeldSwipe`, which queues only once the queue has drained) is an observation boundary:
  `B' = max(B, lastQueued + ε)`, re-anchored, and the swipe is stamped from B'.

**THE CLOCK'S LIFE:**
- **It STARTS at the pump's FIRST tick** (the tick that builds the generator): `A = B = epoch`, `W =` that cycle's wall now.
  Not at `Macro.start`: the first tick runs one cycle later (§1.2), so starting there would put a load-dependent offset
  into every absolute event time. That would break "Done means" 1 and the fixed epoch's deterministic absolute times.
  The prototype anchored at the first tick (§4.3).
- **It ENDS WITH THE TEST.** The macro reports done only once its queue has drained and its held swipes are delivered,
  which generalises today's `_deliverHeldSwipesThenEnd`. The clock ends in that same tick, so `stopTestPlaying` (same
  cycle) finds nothing queued.
  - Exposure today: 0 of 497 main macros queue input after their last wait (§1.2), so this changes no test.
  - This matters because the off-test branches of §1.4 judge any event drained after `stopTestPlaying`. Under the fixed
    epoch such an event's time (~1e6) would meet a wall "now" (~1.8e12): a finger press would read as a 1.8e12-ms hold
    and fire.
  - And real browser input, re-attached at `stopTestPlaying`, never meets a live clock. Had the clock outlived the test,
    a real event's `Date.now()` stamp (~1.8e12) at the head of the FIFO would block every event behind it until the
    clock ended.

### 4.2 Where it lives
**MacroToolkit (the clock's owner).**
- Class-level field declarations (the house rule): the live flag, B, A, W and `lastQueued`, plus
  `@inputClockEpochMs: 1000000` and `@stepGapMs: 16`.
- `stepTimeNow()` — PUBLIC, a PURE QUERY. B while the clock is live; the wall now otherwise, so a verb run from a console
  outside a macro behaves as today. This is the stamping base every verb defaults to, and what a macro source writes
  (`t = @stepTimeNow() + 50`).
- `inputClockNow()` — PUBLIC, a PURE QUERY. D while the clock is live; the wall now otherwise. Neither query may mutate a
  field: the clock starts, snaps and ends only in the commands below.
- `_startInputClock`, `_snapInputClockAfter lastYield`, `_endInputClock` — private commands, called from the pump's header
  code (Macro.coffee `_addHeaderCode`) and from the generalised end-of-macro tick.
- **The chokepoint becomes a private twin.** `_queueInputEvent` does today's work, records `lastQueued`, and refuses a
  wall stamp (§4.5). The public `queueInputEvent` (macro sources and public verbs call it) delegates to it, and the six
  private callers of §1.1 call the twin.
  - Why: once the chokepoint writes a field it is EFFECTFUL, and call-separation rule [S] (`check-call-separation.js`,
    effectful baseline 0, HARD) forbids a private method to @-self-call a public effectful command.
  - The twin is the honest shape. No `# public-call-sanctioned` markers, and no field name picked to slip past the
    classifier.

**WorldWdgt (the ONE core seam).**
- A public instance method `inputClockNow()` returning `@macroToolkit?.inputClockNow?() ?
  WorldWdgt.dateOfCurrentCycleStart?.getTime()`.
- `_playQueuedEvents` compares against `@inputClockNow()` instead of the cycle start.
- In a production profile (no harness part) the seam answers today's value, so production behaviour is unchanged by
  construction.
- `check-part-edges.js` does not judge this call; the runtime `?.` guard is what protects a profile without the part.
- **This is one more WorldWdgt method, and WorldWdgt is AT its method ceiling (136, `check-complexity-ratchets.js`).**
  U2 needs the owner's dated raise to 137.

**The mixers, routed through the seam (MANDATORY, U2).**
- `_holdDecisionTime`'s cycle branch reads `world.inputClockNow()`.
- `_reAnchorDragEmbedLinger` stores `world.inputClockNow()`, a NUMBER rather than a Date, as the linger's wall origin. The
  ring's off-test branch computes `world.inputClockNow() − @lingerOriginWallTime`. These two change TOGETHER.
- Under the fixed epoch these are load-bearing: they make every "now" an input reader can compare with an event time
  come from the same clock. Together with "ends with the test", that covers the cycles after a test's macro reports done.

**`WorldWdgt.dateOfCurrentCycleStart` stays the WALL clock.** Stepping, the knob slide, the seconds source and the clock
widget keep reading it untouched. That is why the design does NOT make the cycle clock virtual.

### 4.3 The three choices, settled by measurement (phase B, 2026-11-28)
**THE PROTOTYPE** (`/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/inspector-browser-loop/up/proto/input-clock-prelude.js`,
Appendix A.3) is injected with `--prelude=` into the unchanged build. It intercepts the pump through an accessor on
`MacroToolkit.prototype.progressOnMacroSteps`, snaps B at each `macroGenerator.next()`, wraps `_deliverHeldSwipe`, and
replaces `_playQueuedEvents` with a copy whose one change is what "due" means. It differs from §4.1 in four ways:
1. **It re-anchors D at every snap**, even with events still queued: the flaw §4.1 corrects.
2. **It keeps the clock live until the queue drains after the macro ends**, rather than holding the macro open until
   drained. With 0 such tests (§1.2), the two agree on today's suite.
3. **During the pump it shows `dateOfCurrentCycleStart` AS the input clock**: the only way to reach 55 default arguments
   from outside. So a product method a step calls DIRECTLY saw the input clock (the knob slide's start, the clock
   widget's constructor). The real change makes no such swap.
4. **It carries B in a `Date`, so it keeps whole milliseconds.** The real clock keeps fractions: the mouse hold below
   reads 19.30 in the prototype and will read 20.17 in the real change.

**Run A, the whole suite under the prototype, uf's census as audit instrument** (epoch / ε / pacing):

| configuration | mouse dpr1 | finger dpr1 | mouse dpr2 | finger dpr2 WebKit |
|---|---|---|---|---|
| wall / 16 / wall | 497/497 | 483/483 | 497/497 | 483/483 |
| **fixed / 16 / wall (CHOSEN)** | 497/497 | 483/483 | — | 483/483 |
| wall / 16 / fixed Q=16 | 497/497 | 483/483 | 497/497 | 483/483 |
| fixed / 16 / fixed | 497/497 | 483/483 | — | — |
| wall / 1 / wall | 497/497 | — | — | — |

- **6 860 test executions, 0 failures, 0 gate violations**; every shard complete.
- The prototype was proven LIVE in every played test: a per-test `LAYOUTAUDIT UPCLOCK live` line.
- Each image has one reference per density and pointer (`check-refs`), so every shot matched its committed picture byte
  for byte.
- **The timestamps really moved.** The wall-anchored input clock lagged the wall by:

  | run | median | p90 | max |
  |---|---|---|---|
  | mouse dpr1 | 205 ms | 619 | 2 224 |
  | finger dpr1 | 238 | 636 | 2 414 |
  | mouse dpr2 | 372 | 1 269 | 8 311 |
  | finger dpr2 WebKit | 511 | 2 014 | 11 299 |

- **Snaps per configuration:** mouse dpr1 11 443 observation, 72 numeric-yield and 0 held-swipe; finger dpr1 11 239,
  72 and 115.
- **Cross-step holds collapse to the schedule:**

  | | mouse | finger |
  |---|---|---|
  | idle without the clock | 70–80 ms (the two dwell sites) | 13–187, median 20 |
  | under it | 17–19 | 16–127, median 16 (127 = `CandidateChangeResets`' carry rest + ε) |

- **They are IDENTICAL test by test** (`/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/inspector-browser-loop/up/holds-compare.js`
  over the runs' census logs):

  | comparison | finger | mouse |
  |---|---|---|
  | Chrome dpr1 against WebKit dpr2, wall epoch | 67/67 tests | — |
  | Chrome dpr1 against WebKit dpr2, fixed epoch | 67/67 | — |
  | fixed epoch against wall epoch | 67/67 | 40/40 |
  | dpr1 against dpr2 | — | 40/40 |
  | wall against fixed pacing | — | 40/40 |

**Run B, the ORIGINAL (unfixed) InternalVsExternalWindowDrop** (an in-page revert, Appendix A.4; WALL epoch):

| lever | with the clock: mouse / finger | without (control) |
|---|---|---|
| stall 0, 230, 250, 400 | 19.30 / 73.00, PASS all | stall 250: mouse 502.30 FAIL, finger 557.00 FAIL |
| virtual clock 220, 231, 329, 400 | 19.30 / 73.00, PASS all | 231: mouse 450.30 FAIL, finger 485.00 FAIL; 220: finger 452.00 FAIL (mouse 428.30 passes, as predicted) |
| one stall 460, 660 | 19.30 / 73.00, PASS all | — |

The hold is constant: the carry's own rest + ε. The controls reproduce §2.3 exactly, so the revert is live.

**Run C, the census's 11 most exposed sites, stall 0 against stall 250, under the clock (WALL epoch).** All 11 record the
SAME decisions with the SAME holds at both stalls, and all pass. These are the per-site values U2 re-checks (prototype,
whole-ms bases; in ms; `A` = armed):

| site | pointer | cross-step decisions |
|---|---|---|
| `macroAWindowWearsOneCopyOfItsToolbar` | finger | dwell 779 A, hold 20, dwell 736 A, hold 20, dwell 757 A, hold 20, dwell 637 A, hold 16 |
| `macroDragEmbedCandidateChangeResets` | finger / mouse | dwell 127 / dwell 16.95 |
| `macroDragEmbedWindowTransitNeverArms` | finger / mouse | dwell 71 / dwell 19.07 |
| `macroInspectorDividerSizesOneColumn` | finger | 11 holds of 16 |
| `macroMenusCloseOnMouseDownOutside` | finger | hold 16 |
| `macroWidgetDestroyedOrClosedMidStrokeIsNotPickedUpAgain` | finger | holds 17 ×6, 16, 27.16 |
| `macroWindowGripStrip` | finger | hold 16 |
| `macroMidEditCopyAndSaveCarryNoCaret`, `macroSliderDragTracksAxisInRotatedIsland` | finger | none in the single-test runs; one hold of 16 each in the suite-level census (the instruments' order differs) |

The armed dwells of 600 ms and more are the crossing `yield 600` holds.

**Run D, the pacing tie-breaker (WALL epoch):** see choice 3.

**THE CHOICES:**
1. **Epoch: FIXED.** Every macro's clock starts at a constant, 1 000 000 ms.
   - Measured: 0 failures at mouse dpr1, finger dpr1 and finger dpr2 WebKit, and in the two fully virtual runs. Its
     cross-step holds are identical to the wall epoch's (finger 67/67, mouse 40/40) and across engines (67/67).
   - Why: with a wall-anchored clock, a wall-stamped event a migration misses is only "debt" ms ahead (median 205–511,
     up to 11 s, above), so it is delivered LATE by a LOAD-DEPENDENT amount: exactly this class, silently. With a fixed
     epoch it is ~1.8e12 against ~1e6, and the chokepoint refuses it (§4.5).
   - It also makes absolute event times deterministic. The only absolute reader, FridgeMagnets3D's animation clock, is
     played by two tests (`macroFizzytilesBoxTileRendersStaticCube`, `macroFizzytilesBlockScoping`), which pass under
     both epochs.
2. **ε = 16 ms** (`MacroToolkit.stepGapMs`).
   - Measured: 0 failures at 16 (every configuration) and at 1 (mouse dpr1).
   - 16 is one 60 Hz frame. For the flake's own test it lands near today's idle values (finger 72–83 → 73; mouse
     23–29 → 20.17).
   - Holds whose idle values included a screenshot's cycles fall well below today's range: the census-wide mouse dwells,
     70–80 → 17–19, and the finger's mid-press holds, up to 187 → 16–127. This is the class being removed, and the
     suite passed with it.
   - ε ≥ 1 is a hard floor: FrameBarWdgt identifies a press by an EQUAL stamp (§1.4).
3. **Pacing: WALL** (D advances with real time between anchors).
   - Fixed pacing (D advancing Q per cycle) passed 6 suites, but the class does not need it: cross-step holds are
     already identical across engines and densities under wall pacing.
   - It also makes the product's WALL-CLOCK auto-scroll load-sensitive. Under a 250 ms stall a floored drag's transit
     takes a fixed number of cycles, about 4.8 s of wall time, and the auto-scroll started mid-transit (17 `_autoScroll`
     steps each in `macroScrollPanelNotMovedViaNonFloatDragChild` and `macroMenuPinnedInScrollPanel`). Under wall pacing
     the transit stayed 257/262 ms and started none.
   - Both tests passed (the scroll clamped), but the behaviour diverges under load: a defect fixed pacing would
     introduce.

### 4.4 What becomes of today's mechanisms
- **`clickAfterHoldingStill_InputEvents`** STAYS, re-documented as the explicit-hold verb ("press exactly holdMs after the
  queue's last event, in this step"). It reads the queue's last event, which is unchanged.
  - With the clock, a click after a drain holds ε, so §3k's workaround is unneeded for new tests.
  - Its two users (`macroDragEmbedReleaseWhileChargingLandsOnWorld` with 250, `macroInternalVsExternalWindowDrop` with 0)
    are correct under either clock and are not reverted. Reverting them would change their holds for no gain (the
    second's from 4.17 to 20.17 ms).
- **`_deliverHeldSwipe`'s re-stamp** becomes an observation snap (§4.1). Measured in the prototype: 115 snaps per finger
  configuration, no failure.
- **A numeric `yield N`** keeps waiting at least N of real time, and advances event time by exactly N.
- **The DETERMINISM §4 virtual-clock lever** keeps working. It overrides the WALL clock, which D's real-time term reads,
  so it still shapes the drain. A cross-step hold, which is the schedule's, does not move with it.

### 4.5 Enforcement: the class cannot be re-written
1. **The chokepoint refusal** (in `_queueInputEvent`, U3).
   - While the clock is live, an event whose time is more than 24 h from `stepTimeNow()` is refused.
     - First a `console.error "WALL_CLOCK_STAMP: <event> stamped <t>, the macro's step time is <B> — stamp from
       @stepTimeNow()"`: a NEW gate token, listed in `Fizzygum-tests/scripts/lib/gate-tokens.js` `GATE_TOKENS`, whose
       self-test requires each token to be both emitted and listed.
     - Then a `throw`, like the chokepoint's existing throw for a held swipe.
   - Why the token comes first: the throw alone escapes the pump as an uncaught error. The page then stops answering and
     the runner reads the test as STALLED, not as a named failure. The token fails it BY NAME at once.
   - With the fixed epoch, every wall-clock stamp is ~1.8e12 against ~1e6 and is refused: `Date.now()`,
     `WorldWdgt.dateOfCurrentCycleStart`, or an `InputEvent` built without a time, which defaults to `Date.now()`.
   - It also covers toolkit CLASS code (MacroToolkit methods), which the static rule below does not read.
   - Its standing proof is U5's plant (ii).
2. **A NEW rule in an EXISTING gate, `Fizzygum-tests/scripts/check-macro-source-discipline.js`: `WALL_CLOCK_STAMP`.**
   ⚠ This is a change to an existing gate, so **the executing session needs the OWNER'S GRANT before U3.**
   - **Scope:** a macro source (a test's `mainMacroSource`/`extraSubroutineSources`, or a verb's `Macro.fromString`
     literal) may not, in CODE (comment-masked by `coffeeMask`, as the other three rules read it):
     - read a wall clock: the `clock-read` stink's own regex (`check-stinks.js`, its `re:` at :138: `Date.now()`,
       `performance.now()`, a bare `new Date`), SHARED through a small module both gates require, never copied;
       `WorldWdgt.dateOfCurrentCycleStart`; `WorldWdgt.dateOfPreviousCycleStart`; `msSinceLastExecutedMacroStep`, a sum
       of wall deltas;
     - push onto the queue around the chokepoint: `inputEventsQueue.push`.
   - **Shape:** one more kind in `violationsIn`, `RULE_OF_KIND['wall-clock-stamp'] = 'WALL_CLOCK_STAMP'`.
   - **Its bite-proof**, in `check-macro-source-discipline-selftest.js`:
     - a planted test `SystemTest_BiteProofWallClock` whose macro has one banned form per line (the four clock forms, the
       two statics, the wall-delta field, the push), expected as `FAIL <file>:<line>` under `WALL_CLOCK_STAMP` each;
     - a verb case (`--src=`) whose `Macro.fromString` literal reads `Date.now()`;
     - the clean control extended with `# Date.now and WorldWdgt.dateOfCurrentCycleStart named in a comment`,
       `d = new Date 1783122262571` and `t = @stepTimeNow() + 50`, which must stay clean.
   - **Everything that moves with it:**
     - the `pass` summary regex;
     - a `lib/gate-advice.js` row for `WALL_CLOCK_STAMP` (class A: event time must come from the schedule; its quiet
       fixes and right answer), and the selftest's `advised:` lists;
     - the gate header's "THREE RULES" (four);
     - the lint index's row for the gate (§7) and its §3b class-table row (`check-macro-source-discipline.js` | A | adds
       "a wall-clock stamp");
     - Fizzygum-tests/CLAUDE.md's "three of them" (four).
3. **What neither sees.** A toolkit method that pushes onto `world.inputEventsQueue` directly, bypassing the chokepoint, is
   seen by no rule. Today there is none: the only push is inside `queueInputEvent`. Review is the guard there.

## §5 The migration list
- **Toolkit (MacroToolkit.coffee, 58 sites):**
  - the 55 signature defaults → `startTime = @stepTimeNow()` (`scheduledTimeOfEvent = @stepTimeNow()` for the place
    verb);
  - `queueInputEvent`'s and `scaledAbs`' base → `@stepTimeNow()`;
  - `_deliverHeldSwipe` → snap, then `@_queueNextSwipe @stepTimeNow()`.
  - `@` in a default argument IS the toolkit here, which is what is wanted (macros/CLAUDE.md rule 1 warns of the opposite
    case).
- **The six private callers of `queueInputEvent`** (§1.1) → `@_queueInputEvent` (U2).
- **Test macro sources: the 30 sites of §1.5** → `@stepTimeNow()`:
  - `t = WorldWdgt.dateOfCurrentCycleStart.getTime() + 50` → `t = @stepTimeNow() + 50`;
  - the `− 100` idiom keeps its `− 100` (§9 risk 3).

  Inside a fat-arrow helper (`=>`) `@` is still the toolkit; inside a thin arrow (`->`) it is NOT. Checked 2026-11-28:
  - 29 of the 30 sites sit in the macro body itself or in a fat-arrow helper (`ctrlAlt`, `hoverOnGlass`, `stroke`,
    `pressAlone`, `hoverOn`, `clickBareDesktopAtPressPoint`), so `@stepTimeNow()` is right.
  - The ONE exception is `macroCutWithNothingSelectedCutsNothing`'s `throughTheDoor = (eventClass) ->`. Spell it
    `world.macroToolkit.stepTimeNow()` there, or make the helper `=>`.
- **Core:** `WorldWdgt.inputClockNow()` (new, public; the ceiling raise) and `_playQueuedEvents`; ActivePointerWdgt
  `_holdDecisionTime` and `_reAnchorDragEmbedLinger`; DragChargingRingWdgt `_elapsedForCharge`'s off-test branch.
- **Engine:** Macro.coffee `_addHeaderCode`'s pump string.
  - At the first tick: `@_startInputClock()` before the place.
  - Before `@macroGenerator.next()`: `@_snapInputClockAfter @returnFromLastMacroStep`.
  - At done: the generalised end (deliver held swipes, wait for the queue to drain, `@_endInputClock()`, then
    `aMacroIsRunning = false`).

## §6 Units, in execution order

The predicted failing set of every unit is EMPTY, from phase B.
- **Caveat:** the real change differs from the prototype in the four ways §4.3 lists. Two of them (the anchor kept across
  a non-empty queue, the clock ending with the test) are UNMEASURED.
- Any failure is therefore a finding: classify it, never recapture. Run the test alone with and without the change, and
  look at the picture (`fg diffpage <test>`).

**U0 — Preconditions (no edit).**
- `fg status`, then §0.5 step 2's `git log` checks.
- Check the investigation scripts are present:
  `ls /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/inspector-browser-loop/{uf,up}`. Else rebuild them
  from Appendix A under a fresh `.scratch/` directory.
- Run the CONTROL: Appendix A.5's grid WITHOUT any clock prelude, at stall 250 and virtual clock 231, both pointers. It
  must FAIL exactly as §2.3 says, which proves the levers and the revert are live on today's build.

**U1 — The stamping time as a PURE REFACTOR.**
- Add `MacroToolkit.stepTimeNow()` returning `WorldWdgt.dateOfCurrentCycleStart.getTime()`: today's value, so ZERO
  behaviour change.
- Migrate all 58 toolkit sites and the 30 macro-source sites to it.
- Gates:
  - `fg build` (every static gate: call arguments, call separation, dead methods, layering [D] over macro sources,
    stinks);
  - `fg presuite`;
  - the finger suite (`cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/run-all-headless.js --pointer=finger`).
- Predicted: all green; it is a rename of a value.
- Re-grep: `WorldWdgt.dateOfCurrentCycleStart` must remain in MacroToolkit.coffee only inside `stepTimeNow` (and its
  comment), and in NO macro source.

**U2 — The clock itself** (needs the owner's ceiling raise).
- Edits:
  - `stepTimeNow()` answers B and `inputClockNow()` answers D (§4.1), with the fixed epoch, `stepGapMs` 16 and wall
    pacing;
  - the start at the first tick, the snaps, the anchor kept across a non-empty queue;
  - the macro ends only once drained, and the clock ends with it;
  - the private twin `_queueInputEvent` tracking `lastQueued`, and the six private callers moved to it;
  - the core seam `WorldWdgt.inputClockNow()` and `_playQueuedEvents`;
  - **the mixers routed through the seam (MANDATORY, §4.2)**;
  - WorldWdgt's ceiling 136 → 137 with its dated reason.
- Gates:
  - `fg build`;
  - `fg presuite`;
  - the finger suite at dpr 1;
  - `fg finger` (the finger suite at dpr 2 on WebKit, the gauntlet's wave-D leg, ~6 min);
  - **the grids** (Appendix A.5): the UNFIXED test via the in-page revert, with the stall, virtual-clock and one-shot
    levers and NO clock prelude, both pointers. Predicted: a CONSTANT hold of 20.17 (mouse; the prototype's 19.30 plus
    the fraction it truncated) and 73.00 (finger) at every lever, all PASS;
  - **the census** (Appendix A.6), as `--audit-prelude=`, both pointers at idle; then §4.3's 11 sites at stall 0 and 250.
    Predicted: every cross-step hold within 1 ms of §4.3's per-site values, each site identical at both stalls;
  - **NEW MEASUREMENT, the corrections the prototype did not have.** Extend the census instrument to log every step
    boundary that finds the queue NON-EMPTY: wrap `MacroToolkit.prototype._snapInputClockAfter` and print
    `LAYOUTAUDIT UFSNAP {"test", "lastYield", "pending"}` when `world.inputEventsQueue.length > 0`. Run it with the
    suite, both pointers. Predicted: 0 at idle. Any count is a site where the anchor rule matters; confirm each passes.
    Also confirm no test leaves input queued at its end: count a `LAYOUTAUDIT UFEND {"test", "pending"}` line from
    `_endInputClock`. Predicted: 0.

**U3 — Enforcement** (needs the owner's grant for the gate rule).
- The chokepoint refusal with its `WALL_CLOCK_STAMP` gate token (§4.5.1).
- The `WALL_CLOCK_STAMP` rule, its bite-proof and everything that moves with it (§4.5.2), including the shared clock-read
  regex module.
- **The refusal's one-off proof** (made standing by U5's plant (ii)).
  - A `--prelude=` plant, written under a fresh `Fizzygum-tests/.scratch/<dir>/`, polls until
    `MacroToolkit.prototype.syntheticEventsMouseMove_InputEvents` exists.
  - It wraps that verb so that, only while `world.automator.player.currentlyPlayingTestName()` is one named short test
    and only on its first call, it also queues
    `@queueInputEvent (PointermoveInputEvent.synthetic 0, 0, false, false, false, false, Date.now(), 0, 0), true`.
  - Run that test alone with the plant: it must FAIL, naming `WALL_CLOCK_STAMP`. Without the plant it passes.
- Gates: `fg build` (the gate's self-test runs on every build and must plant every rule; the gate-tokens self-test checks
  the new token), then `fg presuite`. Predicted: 0 violations over the tree, since U1 migrated every site.

**U4 — Documentation and in-code comments** (§7).
- Gates:
  - `/Users/davidedellacasa/code/Fizzygum-all/fg doc-narration` (changelog prose in present-tense docs, and the byte
    ceilings);
  - the comment-narration stink (`fg build`): write no "no longer", "now", "used to" in a comment;
  - the gauntlet's `refs` leg at U6.

**U5 — The standing witness (MANDATORY).**
- **A new SystemTest** that writes the class's shape on purpose:
  - carry a window over a panel, `yield "waitNoInputsOngoing"`, take a screenshot, release, and assert it landed on the
    world;
  - as a finger, press, screenshot, release, and assert that the hold did not fire.

  Reading `_pressHoldFired` is a private read from a macro, which layering rule [D] allows only as a test ORACLE with
  `# macro-private-call-sanctioned: <reason>`. Prefer a public query if one exists; ask before adding one.
  - Capture its references at both densities and both pointers (`capture-macro-test-references.js <name> --dprs=1,2`,
    then `--pointer=finger`).
  - Prove its follower: `run-sequence-headless.js SystemTest_<new> SystemTest_<any>`, both pointers, 0
    `WORLD_INVENTORY_` lines.
- **A `*-selftest-headless.js`** (the gauntlet's `selftests` leg, found by name) plays it under a 250 ms per-cycle stall
  prelude and requires PASS. Its plants:
  - (i) a plant making `stepTimeNow`/`inputClockNow` answer the wall must make it FAIL — the clock's standing proof;
  - (ii) a plant that queues one `Date.now()`-stamped event from a step must fail naming `WALL_CLOCK_STAMP` — the
    refusal's standing proof.

  Without U5 the class's absence is held only by U3's refusals, which forbid the WAY back but never replay the shape.

**U6 — Close.**
- `fg gauntlet` (all 20 legs, PARALLEL).
- `fg homepage`. The production profile ships no harness, so the seam falls back to the wall: identical by construction,
  and this proves it.
- Then the arc's docs, memory and archive per the house's close-arc ritual, including this plan's `BACKLOG.md` section.

## §7 Docs and comments to change (U4)
- **`Fizzygum/src/macros/CLAUDE.md`:**
  - "Playback speed", the paragraph on the non-scaled SETTLE channel: `yield N` waits at least N real AND advances event
    time by exactly N. Replace the ⚠ "A `yield N` bounds a hold only from BELOW…" paragraph with the input clock's rule
    in one sentence and a pointer to this plan's archive.
  - "Adding to the toolkit": an L1 primitive defaults its start time to `@stepTimeNow()`.
  - The L2 action list's `clickAfterHoldingStill` gloss.
- **`Fizzygum/src/macros/MACRO-PATTERNS.md`:** the "Window drop = DWELL-TO-ARM" entry (the "wrong for NOT arming…
  `clickAfterHoldingStill`" sentence) and every "non-scaled real-wall-clock linger" passage. Grep `yield 600`,
  `clickAfterHoldingStill`, `NON-SCALED`.
- **`Fizzygum-tests/DETERMINISM.md`:**
  - §1 item 3: drained when `event.time ≤` the input clock;
  - §3k: a closing bullet, "the class is ended by the macro input clock", with its date and this plan's archived path,
    and the Tell kept as case law;
  - §4: the virtual-clock lever shapes the drain, and a cross-step hold is the schedule's.
- **`Fizzygum/docs/architecture/input-and-gestures.md`:**
  - :50–56, the queue drains against `WorldWdgt.dateOfCurrentCycleStart`: name the input clock and the seam. :53–54 is
    STALE already: `timeOfEventBeingProcessed` is cleared at the world's teardown, not at each cycle's tail.
  - :224, `_holdDecisionTime` "may also consult `WorldWdgt.dateOfCurrentCycleStart`": it consults the seam.
  - :236–242, the suppression idiom.
- **`Fizzygum/docs/architecture/lint-and-static-checks.md`:** the "macro source discipline" row (three rules → four, rule
  D `WALL_CLOCK_STAMP`, with its blind spot: macro sources only, while the chokepoint refusal covers class code), and the
  §3b class-table row.
- **`Fizzygum-tests/CLAUDE.md`:** "three of them" → four, inside its byte ceiling (66 307, AT the ceiling: shrink
  something or ask).
- **In-code comments**, present tense, never "no longer":
  - `queueInputEvent`'s doc-comment (the base);
  - `clickAfterHoldingStill_InputEvents`'s (its reason: an explicit hold, not §3k's workaround);
  - Macro.coffee's pump comment ("numeric `yield N` = wait N ms of REAL wall-clock…": it also advances the input clock
    by exactly N);
  - `_deliverHeldSwipe`'s;
  - the `yield 600` verbs' ("NON-SCALED linger": `dwellDragWindowByGrabToEmbed_InputEvents_Macro`,
    `dropInternalWindowIntoExternalWindow_InputEvents_Macro`);
  - `_holdDecisionTime`'s;
  - `_elapsedForCharge`'s.
- **`Fizzygum/docs/BACKLOG.md`:** the plan's index section, drafted in
  `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/inspector-browser-loop/up/DRAFT-backlog-lines.md`
  (filed with this plan), and the census's latent-class line closed if the owner filed it.

## §8 Rejected alternatives (do-not-re-attempt), with the evidence

| alternative | why it fails to END the class |
|---|---|
| **Fix the tests one by one** (`clickAfterHoldingStill`, §3k's fix) | Works only where the hold's two events can share a step. 6 finger decisions and 2 dwell releases (§2.4) hold across a mid-press or mid-carry SCREENSHOT, which needs a drain, so no event-time spelling exists. The other 82 would each need a rewrite of its test. |
| **Refusal alone** (refuse an unarmed or unfired release queued after a wait) | Same 8 sites have no other spelling, and the 82 would all fail until rewritten. It forbids the test shapes instead of fixing the clock. Kept only as the enforcement half (§4.5), which refuses the wall clock, not the shapes. |
| **Release-only stamping** (stamp a release after a wait at lastQueued + ε) | Press → drain → MOVE is untouched (most of the 88). Stamping a click's down in the past while its up stays on the cycle either loses `clickHoldFloorMs`' held frame or turns a finger tap into a hold: down→up would be the debt, median 205–511 ms, up to 11 s (measured). |
| **A capped cycle clock** (≤ cap ms per cycle) | Bounds the hold by cycles × cap. Observation waits measured 5–13 cycles (§2.4), so at cap 50 a 13-cycle hold reaches 650 > 450. It also bends `dateOfCurrentCycleStart` under the wall-clock readers. |
| **DETERMINISM §4's virtual cycle clock made permanent** | Observation cycles still advance it, and their number depends on asynchronous atlas and hash work. Measured: even under fixed pacing, the cycle span of a decision differed between Chrome dpr1 and WebKit dpr2 in 32 of 440 finger tests (54 decisions). |
| **Stamping each new step in the past with today's wall drain** (no core seam), and its twin, **re-anchoring the due clock with events still queued** | The gesture's events are all due at once and drain in ONE cycle, which defeats the drag floor (macros/CLAUDE.md, "Per-verb floors"). §4.1's anchor rule exists to prevent the second form. |
| **Fixed pacing** (D advances Q per cycle) | Not needed for the class (§4.3), and it makes the WALL-CLOCK edge auto-scroll fire mid-drag under load: at a 250 ms stall a floored drag's transit took ~4.8 s and started 17 `_autoScroll` steps in each of two tests; wall pacing: 257/262 ms, none. |
| **A wall-anchored epoch** (works, not chosen) | A wall stamp a migration misses is delivered late by a load-dependent debt instead of being refused: the class, silently. |
| **Starting the clock at `Macro.start`** | The pump's first tick runs one cycle later, so every absolute event time would carry that cycle's load-dependent length. |

## §9 Central risks
1. **A picture that draws an event-time quantity moves.** Two cases: a charging ring filled after a numeric hold, now
   exactly N where today it is N plus overshoot; and the 3D magnets' absolute time. Measured: none moved in 6 860
   executions. The real change's fractional bases differ from the prototype's by under 1 ms.
2. **An outcome that crosses a window today only thanks to drain time.** The census found none: every fired hold was
   scheduled in-step, and every armed dwell crossed via `yield ≥ 600`. Phase B confirmed it suite-wide.
3. **The `− 100` "already due" idiom** (`macroScrollingBackReturnsContentToWhereItRested` ×4,
   `macroTwoScrollStrokesInOneFrameKeepBothTravels` ×3) stamps B − 100 = lastQueued + ε − 100. That is BEFORE the
   previous step's last event, so event time runs backwards between those two events.
   - Today it does too whenever the waits were under 100 ms; with the clock it does so always, by a fixed 84 ms.
   - Both tests passed under the prototype, which fed them B.
   - If a recognizer ever reads that gap, respell the idiom as `@stepTimeNow()`: due at once, and never backwards.
4. **A `yield` exactly equal to a window** (450, 500, 300) becomes exact and decides deterministically, perhaps unlike
   today. None found.
5. **Held-swipe gaps snap**, so translated finger wheels drain on a new schedule. Their travel has been exact since §3l;
   measured green.
6. **The prototype is not the real change** (four differences, §4.3). Two of them are the corrections U2's new
   measurement covers. In the other two the real change stays closer to today: no in-step swap, and fractional times.
7. **A missed migration.** Under the fixed epoch it is REFUSED at once by name (§4.5.1): loud, never a silent delay.
8. **Real browser input.** It is detached while a test plays and re-attached at `stopTestPlaying`, and the clock ends with
   the test, so it never meets a live clock. If a later change let the clock outlive its test, a real event would BLOCK
   the queue (§4.1): U2's `UFEND` count guards that.

## §10 Verification protocol (commands)
- Build: `/Users/davidedellacasa/code/Fizzygum-all/fg build`.
- Inner loop: `…/fg presuite`, in the background, with its log.
- Finger dpr 1: `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/run-all-headless.js --pointer=finger`.
- Finger dpr 2 WebKit: `…/fg finger` (~6 min).
- Docs: `…/fg doc-narration`.
- Grids and census: Appendix A.5 and A.6.
- Commit point: `…/fg gauntlet` (PARALLEL, ~15 min, 20 legs), then `…/fg homepage`.
- One failing test: `node scripts/run-macro-test-headless.js SystemTest_<name> [--pointer=finger] [--dpr=2]
  [--dump-failures]`, then `…/fg diffpage SystemTest_<name>`.

## §11 References
- `Fizzygum-tests/DETERMINISM.md` §3k: both cases, the census Tell, the measured table.
- `Fizzygum/docs/archive/drag-embed-implementation-plan.md`, "InternalVsExternalWindowDrop's unarmed drop can arm under
  load": the case's record.
- `Fizzygum/src/macros/CLAUDE.md`, "Playback speed" and "Per-verb floors".
- Gitignored investigation records on the author's machine (every number above is copied here), all under
  `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/inspector-browser-loop/`:
  - `uf/PHASE1-REPORT.md`, `uf/PHASE2-REPORT.md` (the root cause and the census);
  - `up/PHASEA-REPORT.md` (the clock map and readers), `up/PHASEB-REPORT.md` (the prototype's measurement);
  - the scripts: `uf/make-preludes.js`, `uf/census-prelude.js`, `uf/census-report.js`, `up/proto/input-clock-prelude.js`,
    `up/proto/unfix-internal-vs-external.js`, `up/run-phaseB.sh`, `up/phaseB-report.js`, `up/holds-compare.js`.

## Appendix A — the instruments, so a cold session can rebuild them

All paths are under `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/inspector-browser-loop/`. Write
rebuilt files under a fresh `Fizzygum-tests/.scratch/<dir>/`, because Node resolves `require()` from the script's own
directory.

**A.1 The levers and the measurement** (`uf/make-preludes.js` writes `uf/preludes/{stall-N, vclock-P, oneshot-N,
measure}.js`). A prelude (`--prelude=`) that polls until `WorldWdgt` and `ActivePointerWdgt` exist, then:
- **The stall:** wrap `WorldWdgt.prototype.doOneCycle` so that, after the original and only while
  `world.macroToolkit.aMacroIsRunning`, it busy-waits N ms (`performance.now()` loop).
- **The virtual clock:** wrap `_updateTimeReferences` so that, while a macro runs, `dateOfCurrentCycleStart` advances by
  exactly P per cycle, and `msSinceLastExecutedMacroStep` is corrected by `+= (virtual − real)`.
- **The one-shot:** stall once, in the cycle a carry begins.
- **The measurement:** wrap `ActivePointerWdgt.prototype._updateDragEmbedStateMachine`; inside `drop` (flag it by
  wrapping `drop`), print `UFHOLD drop … armed=<bool> elapsed=<timeOfEventBeingProcessed −
  dragEmbedLingerOriginEventTime>`. Only evaluations inside `processPointerMove/Down/Up` may open a carry's record,
  because the per-cycle re-sync reads a stale time.

**A.2 The census** (`uf/census-prelude.js`, used as `--audit-prelude=` with `--audit-dir=`).
- Print `LAYOUTAUDIT installed …` once, and `LAYOUTAUDIT_TESTSTART <name>` when
  `world.automator.player.currentlyPlayingTestName()` changes.
- Tag each event at `MacroToolkit.prototype.queueInputEvent` with the cycle number that queued it (after U2: at the twin
  `_queueInputEvent`).
- Track the event being processed through `processPointerMove/Down/Up`.
- Print one `LAYOUTAUDIT UFREC {json}` per decision:
  - a dwell at every drop of a payload whose `_dropPolicyProxy().requiresDeliberateEmbedding()`: armed, elapsed, and
    laterStep (the press queued in a later cycle than the event that anchored the linger);
  - a finger hold, read at `_holdDecisionTime`, which the recognizer reaches only past every suppression, and printed at
    `_forgetPressAndHoldRecognition` when it decided anything: the largest gap, laterStep, cycles spanned, fired;
  - the auto-scroll: `_startAutoScrolling` to `_stopScrollStep` age, and whether `_autoScroll` ran.
- U2 adds the `UFSNAP` and `UFEND` lines (§6).

**A.3 The prototype** (`up/proto/input-clock-prelude.js`): §4.3's description, `window.UP_INPUT_CLOCK = {eps, epoch:
'wall'|'fixed', pacing: 'wall'|'fixed', q}` in front of it. It is superseded by the real change at U2.

**A.4 The in-page revert of the fix** (`up/proto/unfix-internal-vs-external.js`).
- `Object.defineProperty(window, 'SystemTest_macroInternalVsExternalWindowDrop_automationCommands', {configurable: true, get, set})`.
- The setter replaces `@clickAfterHoldingStill_InputEvents 0\n` in `mainMacroSource` with
  `yield "waitNoInputsOngoing"\n  @syntheticEventsMouseClick_InputEvents()\n`.
- It `console.error`s `UNFIX_NOT_APPLIED` when the line is missing.
- The commands file is a classic script assigning a global, so the setter sees it first.

**A.5 The grids** (the U0 control, the U2 proof), run from `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests`:
```
S=/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/inspector-browser-loop
cat $S/uf/preludes/stall-250.js $S/up/proto/unfix-internal-vs-external.js > $S/up/gen/grid.js
FIZZYGUM_KEEP_STALE_BROWSERS=1 node scripts/run-macro-test-headless.js SystemTest_macroInternalVsExternalWindowDrop \
  --prelude=$S/up/gen/grid.js --all-logs [--pointer=finger]
```
- Read the `UFHOLD drop` line's `elapsed` and the `TEST PASSED/FAILED` line.
- Levers: stall 0, 230, 250, 400; virtual clock 220, 231, 329, 400; one-shot 460, 660; both pointers.
- `$S/up/run-phaseB.sh B` runs the whole grid, with and without the prototype.

**A.6 The census run**, from `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests`:
```
node scripts/run-all-headless.js [--pointer=finger] --audit-prelude=$S/uf/census-prelude.js --audit-dir=<dir>
node $S/uf/census-report.js <dir>
node $S/up/holds-compare.js <dir A> <dir B>
```

## Start prompt for a fresh session (paste as is)

> You are executing `Fizzygum/docs/plans/macro-input-clock-plan.md` cold. Read it WHOLE first, then the documents its
> §0.5 lists. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status`, then §0.5 step 2's two `git log` checks; if either
> lists commits, re-run §1.5's counts and correct the plan before acting.
>
> I granted in advance (2026-11-28) WorldWdgt's method-ceiling raise 136 → 137 (`buildSystem/check-complexity-ratchets.js`,
> with a dated reason, in U2) and the new `WALL_CLOCK_STAMP` rule in the existing gate `check-macro-source-discipline.js`
> (U3, as §4.5 specifies it); anything beyond those, ask me.
>
> Then run U0 (preconditions; the control that must still FAIL) and continue unit by unit: U1 pure refactor → U2 the
> clock, with its NEW MEASUREMENT of non-empty-queue boundaries → U3 enforcement → U4 docs and comments → U5 the standing
> witness (mandatory) → U6 gauntlet and homepage. Each unit ends at its stated gate and is two commits, Fizzygum first.
>
> The predicted failing set of every unit is EMPTY: any failure is a finding to classify, never a reason to recapture.
> Do not commit, push, or raise any ceiling without asking me with a summary and the proposed message. Run long
> operations in the background with logs, and report at each unit's gate.
