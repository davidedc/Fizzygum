# Pointer Events — one input family, one listener set, a real cancel path

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-24 against Fizzygum `cada3c1c` / Fizzygum-tests `08fec10fa` (gauntlet 18/18
green at 08:59, 316 SystemTests, build FRESH). Every `file:line` was verified on that date —
**line numbers DRIFT; the method name / quoted code is authoritative, so `grep` before trusting
a number.** Plan 2 of the program
[`frames-input-touch-program.md`](frames-input-touch-program.md): the decisions this plan
implements are **owner rulings recorded there (IDs I1, I3; context I2/H1; boundaries T4, T7,
T11)** — cite them, do not re-argue them. Plan 1 (frame lifetime + docking) is EXECUTED AND
CLOSED (archived: `../archive/frame-lifetime-and-docking-plan.md`); this plan is authored
against the post-Plan-1 tree, per the program's just-in-time rule (§6).

**STATUS BOX** (fill per phase as executed)
- P0 re-verification + probes: —
- P1 family + listeners + hand + synthesis: —
- P2 the cancel path + witness tests: —
- P3 deletions verified, docs, tail: —

---

## MANDATE

**Eliminate the mouse/touch adapter fork entirely** — not wrap it, not bridge it. At close:
ONE `PointerInputEvent` family (down/move/up/**cancel**) carrying
`pointerType / pointerId / isPrimary / pressure / position`; the `Mouse*`/`Touch*` adapter
classes GONE (bases included); ONE pointer listener set on the canvas; `touch-action: none` on
the canvas; `setPointerCapture` on down; the down/up position TODO resolved; a `pointercancel`
abort path on the hand where today none exists; per-event `pointerType` carried through to the
hand (Plan 4 consumes it). **Pixel-neutral: the recapture budget is ZERO** (program §4 rule 1);
the only new references are the NEW cancel-path tests' own. Anything beyond this — the gesture
grammar (I2), multi-pointer/pinch (T4), the finger harness (H1/H2), the input-mode toggle (T11),
`isTouchDevice` (T7) — is OUT, with its destination already ruled in the program doc.

---

## §0 Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework ("web operating system") rendered on
one HTML5 canvas. Three sibling repos under `Fizzygum-all/`: `Fizzygum/` (source — this plan
edits `src/` and one HTML template), `Fizzygum-tests/` (the SystemTest suite + Automator harness
source, served through the `latest/js/tests` symlink — test edits need NO rebuild),
`Fizzygum-builds/` (generated, never edited). Every build/test command goes through
`/Users/davidedellacasa/code/Fizzygum-all/fg` (ABSOLUTE path, never `./fg`); bare `fg` prints
the roster. Read the root `CLAUDE.md` and `Fizzygum/CLAUDE.md` before touching anything. No
module system: every class is a global; one class per file, **filename = class name** (the
build keys off it — so deleting/adding event classes is deleting/adding files).

**The vocabulary:**
- **The hand** = `ActivePointerWdgt` (`src/ActivePointerWdgt.coffee`, 1275 lines) — the ONE
  pointer: hit-testing, grabs/drops, multi-click recognition, the drag-embed dwell machine, the
  pop-up dismissal plumbing. `world.hand`.
- **The adapters** = the classes in `src/events-input/` that wrap a browser event into an
  immutable value object whose `processEvent()` calls the hand. The queue
  (`world.inputEventsQueue`) is drained once per cycle by `WorldWdgt._playQueuedEvents`
  (`event.time <= dateOfCurrentCycleStart` — EVENT-time, the determinism backbone).
- **The synthesis path** = `src/macros/MacroToolkit.coffee` (the `macros` part): the L1
  primitives construct THE SAME event classes the browser listeners construct and push them
  onto the queue. The harness (`Fizzygum-tests/Automator-and-test-harness-src/`) detaches the
  real browser listeners during a test, so **the suite exercises constructors + hand, never the
  listeners**.
- **Widget-facing dispatch names** (`mouseDownLeft`, `mouseClickLeft`, `mouseMove`,
  `mouseEnter`, `wheel`, `nonFloatDragging`, …) are the surface WIDGETS implement. **Plan 2
  does not rename any of them** — that vocabulary is Plan 4's (the grammar) if it moves at all.

**Why this plan exists now.** The program's Spine II starts here: the grammar (Plan 4) branches
on per-STROKE `pointerType`, which today does not exist anywhere in `src/`
(`grep -rn "pointerType" src/` → 0). Today's touch path is a lossy emulation — `touchstart`
synthesizes a mouse move+down from `touches[0]` — so a hybrid device, a pen, and a second
finger are all indistinguishable from a mouse, and a browser-cancelled gesture
(`touchcancel`/`pointercancel`) is silently DROPPED: the hand keeps a phantom pressed button
forever. Plan 1 rewrote the dismissal LOGIC in the hand (it now runs on
`enclosingFrame()`/`isMenu?()`/`hierarchyOfPopUps()`); this plan rewrites the PLUMBING — the
listener/event-object layer under it. That is the §1 seam ("1 → 2 never concurrent"), now open
because Plan 1 is closed.

**Critical reframes — do not lose these:**
1. **The suite never sees the listeners.** `AutomatorPlayer.startTestPlaying` calls
   `world.removeEventListeners()` (verified, F11), so the listener rewrite is invisible to all
   316 tests. The suite's exposure is exactly: the event classes' constructors, and the hand's
   entry points. That is why pixel-neutrality is achievable AND why the listener path needs its
   OWN proof (the P0 probe + `fg homepage`/smoke — booting is not exercising, H1's lesson).
2. **The macro toolkit is the ONLY test-side constructor.** `grep -rn "new
   \(Mousedown\|Mouseup\|Mousemove\|Touchstart\|Touchmove\|Touchend\)InputEvent"` across
   `Fizzygum-tests/tests` → 0 (F10). Seven construction sites in `MacroToolkit.coffee`, three
   listener sites in `WorldWdgt.coffee` — the whole fan-in. The harness moves WITH the
   constructors in the same phase, or nothing runs.
3. **The coordinate plumbing is a round-trip with a masked bug.** Macros pass CANVAS
   coordinates; `MousemoveInputEvent`'s constructor ADDS `world.getCanvasPosition()` to fake
   page coordinates; `processMouseMove` SUBTRACTS it back. On the REAL browser path
   `fromBrowserEvent` passes `event.pageX` (already page coords) into that same adding
   constructor, so the subtraction returns `event.pageX`, not `event.pageX − canvasPos` — a
   double-offset masked only because every shipped page pins the canvas at (0,0). The touch
   path (`touches[0].pageX` handed straight to `processMouseMove`) does it RIGHT, so the two
   input paths disagree today (F9). The new family stores WORLD (canvas) coordinates and
   converts ONCE, at the browser boundary — the wart dissolves instead of being ported.
4. **"Six adapters deleted" is eight files.** I1 names the six concrete adapters; their two
   bases (`MouseInputEvent`, `TouchInputEvent`) go with them once `WheelInputEvent` — today
   `extends MouseInputEvent` — is re-parented (F19). Precision, not a contradiction.

---

## §0.5 Cold-execution protocol

**Who executes (program §3.1):** a **COORDINATOR** (the session model, Fable) delegates every
phase to a **WORKER on a cheaper model** — Opus for phase execution, Sonnet for mechanical
sub-steps — via the `Agent` tool (`subagent_type: general-purpose`, `model: "opus"`/`"sonnet"`;
never `fork`, never `isolation: worktree` — the build hard-codes the sibling layout and the
tests symlink). §9 is the delegation map. The steps below are written for the WORKER; the
coordinator runs step 1, briefs per §9, reads reports, decides at gates, and talks to the
owner. **The coordinator does not edit source or run suites itself.**

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — orient (heads, build freshness, test
   count, zombie browsers → `fg killz`). Expect heads at or after the header's.
2. Read this plan in full, then the program doc §2.3 (I1–I3, H1) and §5 (T4, T7, T11). Then
   read, in this order: every file in `Fizzygum/src/events-input/` (307 lines total — read all
   21 files), `src/ActivePointerWdgt.coffee` IN FULL, `src/WorldWdgt.coffee` lines ~2210–2520
   (the `_init*EventListeners` family + `initEventListeners`/`removeEventListeners`) and
   ~1760–1800 (`_playQueuedEvents`), `src/macros/MacroToolkit.coffee` lines ~1–135 (speed
   plumbing + `queueInputEvent`) and ~300–560 (the L1 primitives),
   `src/PreferencesAndSettings.coffee` (what you must NOT touch), `src/index.html` (the one
   entry-page template); then `Fizzygum-tests/DETERMINISM.md` §1–§3 (the event-time doctrine),
   `Fizzygum/src/macros/CLAUDE.md` (rule 2: input through the queue, never poke the hand),
   `Fizzygum-tests/CLAUDE.md` ("This repo OWNS the test-only members…" + the scripts list), and
   `docs/architecture/lint-and-static-checks.md` §3 (the gate inventory) +
   `docs/architecture/immutable-value-classes.md` (the family's doctrine).
3. Execute phases IN ORDER, P0 → P3. Each phase ends with its own gate (§7) and a proposed
   commit. **Owner preference: ask before every commit/push — present a summary and the
   proposed message (`git commit -F <file>`, never backticks in `-m`), then wait.**
4. Long ops (`fg gauntlet`, `fg presuite`): launch ONCE with the Bash tool's
   `run_in_background` redirected to a log; peek `cat /tmp/fg-<cmd>.verdict` at a ~5-min
   cadence; never pipe the gating call through `| tail`/`| grep`; never edit src/tests/fg while
   a run is in flight.
5. If a fix shape is falsified twice, STOP and re-frame — never a third variant (owner rule).
6. Comments you write state what IS — present tense, no history narration (`check-stinks.js`
   fails the build on it). `undefined` is the one absence value (`nil` is retired and gated).
7. Probes live under `Fizzygum-tests/.scratch/` (gitignored) — NEVER the session scratchpad
   (Node resolves `require` from the script's directory).
8. Anything this plan defers goes into the program doc's tail ledger with a destination
   (program §5) — never a "for later" in this file.

---

## §1 The system as it stands (verified 2026-08-24; re-verify in P0)

Each fact records its verification command. Line numbers drift — grep the quoted code.

- **F1 — the adapter inventory.** `src/events-input/` holds 21 files, 307 lines
  (`wc -l src/events-input/*.coffee`). The pointer-relevant ones: `InputEvent` (base: `@time`,
  `@isSynthetic`; family doc-comment: IMMUTABLE values), `InputEventsQueue` (an Array subclass),
  `MouseInputEvent` (base: button/buttons/4 modifiers + `@fromBrowserEvent`),
  `MousedownInputEvent`, `MousemoveInputEvent` (+pageX/pageY), `MouseupInputEvent`,
  `TouchInputEvent` (base: `@touches` + modifiers), `TouchstartInputEvent`,
  `TouchmoveInputEvent`, `TouchendInputEvent`, `WheelInputEvent` (deltas; `extends
  MouseInputEvent`). Untouched by this plan: `Keyboard*`/`Keydown`/`Keyup`,
  `Clipboard`/`Copy`/`Cut`/`Paste`, `InputDOMElementForVirtualKeyboard*`, `Resize`.
- **F2 — the down/up position TODO.** `MousedownInputEvent.coffee:3–9` and its twin in
  `MouseupInputEvent.coffee`: down/up carry NO position ("the position is always changed by a
  mousemove … doesn't apply well to pointer events, where there is no pointer update until the
  'down' happens. So we'll need to correct this eventually"). This is I1's "position taken from
  the down itself". Verify: `sed -n '1,13p' src/events-input/MousedownInputEvent.coffee`.
- **F3 — the listener wiring.** All input listeners attach in `WorldWdgt` `_init*EventListeners`
  (mouse ~:2218, touch ~:2256, keyboard ~:2332, clipboard, misc ~:2385), called from
  `initEventListeners` (~:2439), called from the constructor (~:543). Each mouse/touch listener
  body is one line: `@inputEventsQueue.push <Class>.fromBrowserEvent event`. The touch
  listeners also `event.preventDefault()` ("prevent mouse events emulation").
  `removeEventListeners` (~:2467) detaches all of them, grouped BY TARGET (canvas /
  document.body / window — a wrong-target remove is a silent no-op, its header comment carries
  the 2026-07-15 case). Count-prose exists in two comments ("All 20", ":2852"; "all 20 …
  the 7", ":2461") and in `WorldTestSupport.coffee:176` — a live count in prose, the
  docs-veracity anti-pattern; the rewrite de-counts it. Verify:
  `grep -n "addEventListener\|removeEventListener" src/WorldWdgt.coffee`.
- **F4 — NO `touchcancel` and NO `pointer*` listener exists.** `grep -rn
  "touchcancel\|pointerdown\|pointermove\|pointerup\|pointercancel" src/` → 0. I1's premise
  VERIFIED: a cancelled gesture is dropped on the floor today — the hand never learns.
- **F5 — Safari's `gesturestart`/`gesturechange` listeners are preventDefault-only no-ops**
  ("we don't do anything with gestures for the time being", ~:2277–2287). I1: they MAY stay
  until pinch is derived from two `pointerId`s (T4). This plan keeps them verbatim.
- **F6 — the `contextmenu` listener** (~:2387) is `event.preventDefault()` only ("suppress
  context menu for Mac-Firefox"). I1: kept verbatim.
- **F7 — the hand's entry points and their ONLY callers.** `processMouseDown(button, buttons,
  ctrlKey, shiftKey, altKey, metaKey)` (~:694), `processMouseUp(…same…)` (~:752),
  `processMouseMove(pageX, pageY, button, buttons, …)` (~:998), `processWheel(deltaX, deltaY,
  deltaZ, altKey, button, buttons)` (~:985), plus `processDoubleClick`/`processTripleClick`
  (internal, driven from `processMouseUp`). Callers in `src/`: ONLY the adapters' `processEvent`
  bodies. Callers in the tests repo: `scripts/smoke-boot-headless.js:241–247` (direct
  `world.hand.processMouseMove(x + canvasPos.x, …)` call in a probe), plus TWO NAME-STRING
  consumers: `scripts/end-of-cycle-audit/layout-audit-prelude.js:190`
  (`tagClass('ActivePointerWdgt', ['grab','processMouseMove','determineGrabs'])`) and
  `scripts/coalescing-measure/coalescing-measure-prelude.js:42`
  (`wrapCount(AP.prototype, 'processMouseMove', 'MOVE')`). A rename that misses a string
  consumer silently no-ops an audit (the connector-P9 lesson: grep `Fizzygum-tests/scripts/`).
  Verify: `grep -rn "processMouse\|processWheel" src Fizzygum-tests/scripts | grep -v
  events-input`.
- **F8 — today's touch path is synthesized mouse.** `TouchstartInputEvent.processEvent` calls
  `processMouseMove Math.round(@touches[0].pageX), …, 0, 0, …` THEN
  `processMouseDown 0, 1, …`; `Touchmove` → move with `buttons=1`; `Touchend` → `processMouseUp
  0, 0, …`. Coordinates are ROUNDED to integers at this boundary (fractional touch coords;
  comment in `TouchstartInputEvent.coffee`). This is the single-pointer, `touches[0]`-only
  model I3 retires the SPELLING of while T4 defers the multi-pointer SEMANTICS.
- **F9 — the coordinate round-trip, and the masked double-offset.** Macro → canvas coords →
  `MousemoveInputEvent` ctor ADDS `world.getCanvasPosition()` (impure construction, noted in
  `immutable-value-classes.md` ~:139–141) → `processMouseMove` SUBTRACTS it. Browser →
  `fromBrowserEvent(event)` passes `event.pageX` into the SAME adding ctor → net result
  `event.pageX`, which equals the correct `event.pageX − canvasPos` only while `canvasPos` is
  (0,0) — true on every shipped page (`src/index.html:42` pins the canvas absolute 0,0;
  `stretchWorldToFillEntirePage` clamps it to 0). The touch path passes `touches[0].pageX`
  straight to `processMouseMove` (no ctor add) and is correct as-is. Verify by reading
  `MousemoveInputEvent.coffee` + `ActivePointerWdgt.processMouseMove` + `TouchstartInputEvent`.
- **F10 — harness synthesis is CENTRALIZED.** Construction sites of the Mouse* family outside
  `WorldWdgt`: exactly `MacroToolkit.coffee` — `new MousemoveInputEvent` (~:332 in
  `_syntheticEventsMousePlace_InputEvents`, ~:375 in `syntheticEventsMouseMove_InputEvents`),
  `new MousedownInputEvent` (~:401 shift-click, ~:418 `syntheticEventsMouseDown_InputEvents`),
  `new MouseupInputEvent` (~:402, ~:431), `new WheelInputEvent` (~:551). ZERO Touch*
  constructions anywhere outside the WorldWdgt listeners. ZERO event constructions in
  `Fizzygum-tests/tests/**` (`grep -rn "new .*InputEvent" Fizzygum-tests/tests --include="*.js"`
  → 0; the one `WheelInputEvent` hit is provenance PROSE). All pushes go through the ONE
  chokepoint `queueInputEvent` (~:124), which rescales `event.time` by `spanFactor` BEFORE any
  consumer reads it. A comment at ~:390 spells out the Mouse{down,up} constructor parameter
  order — it moves with the signature.
- **F11 — the suite never exercises the listeners.**
  `AutomatorPlayer.coffee:722` (`world.removeEventListeners()` at test start), `:207`
  (`world.initEventListeners()` at test end), and `WorldTestSupport.coffee:180`
  (`@removeEventListeners() if Automator.state is Automator.PLAYING` — re-disarm after
  `resetWorld` reconstructs the world, whose ctor re-arms). The harness calls the PAIR by name
  and never enumerates listeners — so the listener-set rewrite does not touch harness CODE,
  only its count-prose comment (F3).
- **F12 — prose that names the old plumbing.** Test intent/comment prose naming
  `processMouseUp`/`processMouseDown`/`processMouseMove`: ~8 test dirs (e.g.
  `SystemTest_macroButtonTriggersOnlyOnSameWidgetMouseUp`,
  `SystemTest_macroBareButtonFloatDragsWithoutTriggering`,
  `SystemTest_macroListWdgtAutoScrollsNearDraggedEdge`, …), `src/macros/MACRO-PATTERNS.md`
  (~5 sites), `docs/tooling/coalescing-measurement.md`, and the LIVE plan
  `docs/plans/runtime-performance-optimization-plan.md` (~:213, ~:482 — also names
  `MousemoveInputEvent`); `docs/architecture/immutable-value-classes.md` names the family
  (~:139–150). Archive docs are historical and stay. Verify: `grep -rln
  "processMouse\|MousemoveInputEvent" Fizzygum/docs Fizzygum/src/macros/MACRO-PATTERNS.md
  Fizzygum-tests/tests`.
- **F13 — Pointer Events are greenfield here, and available.** `grep -rn
  "pointerType\|PointerEvent" src/` → 0. Support: W3C Pointer Events are in Chrome (Puppeteer's
  Chromium) and WebKit (Safari 13+; the program §7 cites it). The P0 probe PROVES delivery in
  both headless engines before any code is written — a filed premise is a hypothesis.
- **F14 — the two preference booby-traps this plan must NOT touch.**
  `PreferencesAndSettings.isTouchDevice` is declared, commented "turned on by touch events,
  don't set" — and is in fact NEVER set true anywhere (`grep -rn isTouchDevice src/` → both
  writers set `false`; readers: two virtual-keyboard sites in `WorldWdgt` ~:2164/~:3397). Its
  future is T7 (Plan 4: key the virtual keyboard on the tap's `pointerType`). The
  `inputMode`/`toggleInputMode`/`setTouchInputMode` cluster is T11 (Plan 3 deletes it with the
  single geometry). **Plan 2 changes NEITHER — leave every reader and writer byte-identical.**
- **F15 — events are IMMUTABLE values.** The family doc-comment (`InputEvent.coffee:1–2`) and
  `docs/architecture/immutable-value-classes.md`: fields set at construction, never written
  after. The one sanctioned pre-consumption write is `queueInputEvent`'s time-rescale (before
  the queue drains). `MousemoveInputEvent`'s ctor is noted there as IMPURE construction (reads
  `world`) — the new design moves that read to the browser boundary and makes construction pure
  (update the doc in P3).
- **F16 — the event-time doctrine.** `WorldWdgt._playQueuedEvents` (~:1764) drains events with
  `event.time <= dateOfCurrentCycleStart`, exposing `WorldWdgt.timeOfEventBeingProcessed`
  per event; the hand's multi-click recognition and the drag-embed dwell arm on EVENT time,
  never wall-clock (DETERMINISM.md §3's rule; the multi-click lesson). Nothing in this plan may
  introduce a wall-clock decision — the cancel path included.
- **F17 — part boundaries.** `src/events-input` is CORE (`buildSystem/parts.json`, the `core`
  dirs list); `src/macros` is the lazy-excluded `macros` part; the `harness` part (sourced from
  `../Fizzygum-tests/Automator-and-test-harness-src`) `requires: ["macros"]`. Direction rule:
  part → core references are free; core must never name a part's class unguarded
  (`check-part-edges`). The new event classes are core; MacroToolkit referencing them is fine.
- **F18 — the gates this rewrite meets** (full index:
  `docs/architecture/lint-and-static-checks.md`): **syntax** (each new `.coffee` compiled the
  fragmented way — one class per file, filename = class name); **dead-method** (a deleted
  adapter must vanish from src + harness + macro `.js` references); **unresolved-sends** (any
  missed caller of a deleted/renamed method in src+harness fails the build — this is the net
  under the rename); **argument-holes** (no call may punch a bare `undefined` through to a
  later argument — shapes the constructor/factory design, §2.1); **stinks** (comment
  narration; `nil-literal`); **check-call-separation** [U] (the hand's `processPointer*` are
  called dotted from the adapters, so they are externally-referenced public API — no
  allowlisting needed); **check-raw-pointer-reads** matches WIDGET handler names
  (`mouseDownLeft`… `wheel` — verified by reading `HANDLER_NAMES` in the gate), which this plan
  does not rename, so the gate needs no change; **check-plane-discipline** (hand edits keep
  consuming mapped positions — `_pointerPositionInPlaneOf` stays the one mapping point);
  **check-doc-narration** (`fg doc-narration`) on the P3 docs sweep. Tests-repo gates
  (`check-tests-syntax`, `check-macro-source-discipline`) cover the new P2 test.
- **F19 — `WheelInputEvent extends MouseInputEvent`** for button/buttons/modifiers, carries the
  Oct-2020 Mobile-Safari missing-wheel workaround in `fromBrowserEvent`, and its `processEvent`
  calls `processWheel`. Wheel is a SEPARATE W3C event stream that Pointer Events do not
  replace — the wheel path survives this plan unchanged except for re-parenting (§2.5).
- **F20 — one entry-page template.** `src/index.html` is the single source
  (`build.py: INPUT_HTML_FILE`) from which `index.html`, `index-sw.html` and
  `worldWithSystemTestHarness.html` are generated; the canvas is
  `<canvas id="world" tabindex="1" style="position: absolute; left: 0px; top: 0px;
  outline:none;">` (:42). No `touch-action` anywhere in the tree — one style-attribute edit
  covers all three pages.
- **F21 — a latent bug in the resize listener, found in fact-checking.**
  `@resizeBrowserEventListener = =>` (~:2430) takes NO parameter yet its body calls
  `ResizeInputEvent.fromBrowserEvent event` — `event` resolves only via the legacy
  `window.event` global (absent in Firefox ⇒ ReferenceError on every resize there). Out of
  this plan's mandate (resize is not a pointer event) but in the same listener family the plan
  rewrites; §5 P1 carries it as an owner-flagged one-line fix-in-passing.

### 1.3 Why it is shaped this way

The Mouse*/Touch* fork is the DOM's own history imported wholesale: Fizzygum predates usable
Pointer Events (Safari shipped them in 13, 2019), so touch support was added the way every
2010s codebase added it — synthesize mouse events from `touches[0]` and preventDefault the
rest. The adapters' "no position on down/up" parsimony was correct for mouse (a move always
precedes) and is exactly what Pointer Events break (the TODO says so itself, F2). The
dismissal/gesture logic above this layer is freshly rebuilt (Plan 1) and does not care which
family feeds it — which is what makes this migration MECHANICAL now and why the program
sequenced it after Plan 1 rather than alongside.

---

## §2 The mechanism this plan installs (target design)

### 2.1 The `PointerInputEvent` family (5 new files in `src/events-input/`, 8 deleted)

New classes, one per file, named after the DOM event types (the `MousedownInputEvent`
convention):

- **`PointerInputEvent extends InputEvent`** — the base. Fields (all set at construction,
  never written — the family doctrine, F15):
  `worldX`, `worldY` (**WORLD/canvas logical coordinates — the plane the hand lives in — or
  BOTH `undefined`**, meaning "at the pointer's current position"; `undefined` is the one
  absence value), `pointerType` (`'mouse' | 'pen' | 'touch'`), `pointerId` (Number),
  `isPrimary` (Boolean), `pressure` (Number), `button`, `buttons`, `ctrlKey`, `shiftKey`,
  `altKey`, `metaKey`, plus the inherited `isSynthetic`, `time`.
- **`PointerdownInputEvent`**, **`PointermoveInputEvent`**, **`PointerupInputEvent`**,
  **`PointercancelInputEvent`** — each overrides `processEvent` with one call:
  `world.hand.processPointerDown @` / `…Move @` / `…Up @` / `…Cancel @`.

Two construction boundaries, each a static on the base (so the arity appears ONCE and the
argument-holes gate has nothing to flag):

- **`@fromBrowserEvent (event, isSynthetic, time) ->`** — the BROWSER boundary. Converts page →
  world HERE (`canvasPos = world.getCanvasPosition()`; `worldX = Math.round(event.pageX −
  canvasPos.x)`, same for Y) and ROUNDS to integers here and only here (today's touch-boundary
  rounding, F8, generalized; macro-supplied coordinates are NOT rounded — they pass through the
  constructor untouched, preserving today's behaviour bit-for-bit). Copies
  `pointerType/pointerId/isPrimary/pressure/button/buttons` + modifiers off the event.
  Construction itself becomes PURE — the impure `world` read lives in this static, the same
  seam `WheelInputEvent.fromBrowserEvent` already uses for its workaround writes (F15).
- **`@synthetic (worldX, worldY, button, buttons, ctrlKey, shiftKey, altKey, metaKey, time) ->`**
  — the MACRO boundary. Bakes `pointerType: 'mouse'`, `pointerId: 1`, `isPrimary: true`,
  `pressure: 0`, `isSynthetic: true` (deterministic constants; nothing reads
  pointerId/isPrimary/pressure until Plan 4, which may refine the constants — a refinement,
  not a re-plumb). `worldX/worldY` may be `undefined` (down/up at the current pointer
  position — see §2.3).

**Why `worldX/worldY` scalars, not a `Point`:** the existing family stores scalars; a Point per
event is an allocation per synthesized move (hundreds per drag) the runtime-performance plan
would have to claw back.

**Deleted:** `MousedownInputEvent`, `MousemoveInputEvent`, `MouseupInputEvent`,
`TouchstartInputEvent`, `TouchmoveInputEvent`, `TouchendInputEvent`, and the bases
`MouseInputEvent`, `TouchInputEvent` (F19 re-parents Wheel first). `src/events-input/` goes
21 → 18 files.

### 2.2 ONE listener set (`WorldWdgt`)

`_initMouseEventListeners` + `_initTouchEventListeners` collapse into ONE
`_initPointerEventListeners`:

- `pointerdown` → `return unless event.isPrimary`; guarded
  `try canvas.setPointerCapture(event.pointerId)` (see below); push
  `PointerdownInputEvent.fromBrowserEvent event`.
- `pointermove`, `pointerup`, `pointercancel` → `return unless event.isPrimary`; push the
  matching class. No explicit `releasePointerCapture` — the spec releases implicitly on
  up/cancel.
- **`gesturestart`/`gesturechange`** stay verbatim (I1: until T4). **`contextmenu`** stays
  verbatim (I1). **`wheel`** + the Mobile-Safari scroll workaround stay verbatim (F19).
- **NO `preventDefault` on any pointer listener — deliberately.** Two reasons, both
  load-bearing: (a) the canvas is focused by click (`tabindex="1"`, keyboard listeners sit ON
  the canvas), and engines suppress focus when `pointerdown` is cancelled — preventDefault
  here kills keyboard input; (b) the only thing preventDefault used to buy on the touch
  listeners was suppressing COMPATIBILITY mouse events, and after this plan there are no mouse
  listeners left for them to reach — an unobserved compatibility event is harmless. Browser
  panning/zooming is not preventDefault's to stop under pointer events anyway (I1): that is
  `touch-action`'s job —
- **`touch-action: none`** is added to the canvas's inline style in `src/index.html:42` (one
  template → all three entry pages, F20). CSS only; zero pixels.
- **`setPointerCapture` on down** is the new-correctness half: today a drag that leaves the
  canvas loses its move/up stream (the listeners are on the CANVAS, F3) and the hand keeps a
  pressed phantom button. Capture routes the whole stroke to the canvas. It is wrapped in
  `try/catch` because a `dispatchEvent`-synthesized pointerdown has no ACTIVE pointer and
  engines throw `NotFoundError` on capturing it — the P0 probe measures exactly which engines
  do (P0.4); real user input always has an active pointer.
- `removeEventListeners` updates its canvas group to match (same-target rule, F3). Both
  count-prose comments (and `WorldTestSupport.coffee:176`'s) are DE-COUNTED — "every listener
  the `_init*` family attached", never a number (the docs-veracity lesson: no live counts in
  prose).
- `_dissolveWorldNoSettle`'s listener comment (~:2852) is re-worded the same way.

### 2.3 The hand's plumbing (`ActivePointerWdgt`)

The entry points are renamed to what they now process and take THE EVENT VALUE instead of an
exploded parameter list (the immutable value IS the parameter set; per-event `pointerType`
rides it to Plan 4):

- **`processPointerMove: (e) ->`** — replaces `processMouseMove(pageX, pageY, …)`. Body
  unchanged except the head: `pos = new Point e.worldX, e.worldY` directly — the page→world
  subtraction is GONE (the boundary already converted, §2.1; the F9 wart dissolves). Reads
  `e.button`/`e.buttons`/modifiers where the old parameters were read. Records
  `@pointerType = e.pointerType` (see below).
- **`processPointerDown: (e) ->`** — replaces `processMouseDown(button, buttons, …)`. NEW
  head, resolving F2/I1: if the event CARRIES a position (`e.worldX?`) and it differs from
  `@position()`, run the move pipeline first (`@processPointerMove e`) — this is exactly what
  `TouchstartInputEvent` synthesized (F8), now in the one place; then the existing down logic,
  reading `e.button`/`e.ctrlKey`/… for the right-click test (`e.button is 2 or e.ctrlKey`) and
  recording `@pointerType = e.pointerType`. A position-less event (every synthetic macro down)
  or an equal position skips the move — **byte-identical to today for the whole suite**.
- **`processPointerUp: (e) ->`** — replaces `processMouseUp(…)`. Same position head as down
  (browser pointerup carries a position; synthetic ups don't), then the existing up logic
  (click dispatch, multi-click recognition, `cleanupMenuWdgts` — all UNTOUCHED).
- **`processPointerCancel: (e) ->`** — NEW. §2.4.
- **`processWheel`** — unchanged (name, signature, body).
- **New field `pointerType: undefined`** — the type of the stroke currently in progress, set at
  every down/move, the value Plan 4's grammar branches on. Plan 2 installs the carrier and
  branches on it NOWHERE (I2 is Plan 4's).
- `mouseButton` (`"left"/"right"`), `mouseDownWdgt`, the multi-click recognizers, the
  drag-embed machine, the dismissal plumbing (`enclosingFrame()`/`isMenu?()` at ~:723,
  `hierarchyOfPopUps` in `cleanupMenuWdgts` ~:942) — ALL UNTOUCHED. **Every widget-facing
  dispatch name is untouched** (F18's raw-pointer gate list is the inventory).
- The hand's own doc-comment block listing "mouse events" (~:609–630) is updated to name the
  pointer entry points; the widget-facing names it lists stay.

### 2.4 The cancel path — an ABORT, reasoned from the hand's state machine

`pointercancel` means the browser confiscated the stroke (system gesture, palm rejection, tab
switch). The user did not release deliberately, so NOTHING that means "the user chose this
spot/target" may fire. Walk the hand's state:

| hand state at cancel | what happens | why |
|---|---|---|
| float-dragging (`@children[0]?`) | `@_endDragEmbedInteraction()` FIRST (clears candidate/armed/ephemerals), then drop the payload onto the WORLD at its current position — the unarmed-release arm of `drop()`, forced: never an embed, never a dock, never the sticky re-embed | the dwell is a statement of INTENT; a confiscated stroke has none. The payload must not vanish (it may be the only copy of the user's object) — it lands where it visibly is. Bypasses `drop()`'s re-arming `updateDragEmbedStateMachine` re-run (which could arm from elapsed event-time at the cancel instant) |
| non-float-dragging (`@nonFloatDraggedWdgt?`) | `@nonFloatDraggedWdgt.endOfNonFloatDrag?()`; clear the non-float state | same contract `processMouseUp` honors — the slider must repaint un-pressed |
| plain press, no drag yet | no click dispatch, no `cleanupMenuWdgts` | a cancel is not a click: no action may trigger, and open menus must NOT be dismissed (nothing was clicked outside them) |
| always | `@mouseButton = undefined`, `@mouseDownWdgt = undefined`, `@wdgtToGrab = undefined`, `@previousNonFloatDraggingPos = undefined`; `@doubleClick.forget()`, `@tripleClick.forget()` | the stroke is dead — a later tap must not fold with a cancelled press into a double-click, and no phantom pressed state may linger (the class of bug F4 documents) |

The implementation is a small dedicated method — NOT a call into `processPointerUp` (up fires
clicks and dismissals; sharing its body invites exactly the wrong behaviours). Decisions are
event-time/state only — no wall-clock (F16). `_forgetGestureBookkeepingNoSettle` (~:59) is the
teardown-time cousin; cancel is the in-life sibling and may share a helper where the clears
coincide, but cancel additionally DROPS a carried payload, which teardown must not.

### 2.5 `WheelInputEvent` re-parented

`class WheelInputEvent extends InputEvent`, declaring its own `button`, `buttons`, `ctrlKey`,
`shiftKey`, `altKey`, `metaKey` fields (the six it inherited from `MouseInputEvent`), same
constructor arity, same `fromBrowserEvent` (workaround intact), same `processEvent`. Zero
behaviour change; frees `MouseInputEvent` for deletion.

### 2.6 The synthesis sweep (`MacroToolkit` + tests-repo scripts)

- The seven construction sites (F10) become the `@synthetic` factory of the matching Pointer
  class: `_syntheticEventsMousePlace_InputEvents` / `syntheticEventsMouseMove_InputEvents` →
  `PointermoveInputEvent.synthetic place.x, place.y, button, buttons, …`;
  `syntheticEventsMouseDown_InputEvents` / `…MouseUp…` / the shift-click pair →
  `PointerdownInputEvent.synthetic undefined, undefined, button, buttons, …` (position-less:
  the hand keeps its current position — today's semantics exactly, and schedule-time code
  CANNOT know the drain-time position anyway, so `undefined` is the only correct value here).
  `new WheelInputEvent` (~:551) is untouched. The ~:390 signature comment moves with it.
- **The L1 verb NAMES stay mouse-flavoured** (`syntheticEventsMouseMove_InputEvents`, …):
  hundreds of committed macro sources call them; they name the GESTURE vocabulary, and the
  pointer-kind vocabulary (tap/hold/drag per `pointerType`) is H2/Plan 4's design space. A
  rename now would churn 300+ test files to express nothing Plan 4 won't re-decide.
- `scripts/smoke-boot-headless.js:241–247` — the direct probe call becomes the new API with
  WORLD coords (drop its `+ canvasPos.x` compensation; its own comment explains it exists only
  to survive the old round-trip).
- `scripts/end-of-cycle-audit/layout-audit-prelude.js:190` and
  `scripts/coalescing-measure/coalescing-measure-prelude.js:42` — the NAME STRINGS
  `'processMouseMove'` → `'processPointerMove'` (F7's silent-no-op hazard; the gauntlet's
  settle/capstone legs and `docs/tooling/coalescing-measurement.md` are the witnesses).

### 2.7 Disposition table — every current member

| today | fate |
|---|---|
| `MouseInputEvent` (base) | DELETED (Wheel re-parented first, §2.5) |
| `MousedownInputEvent` / `MouseupInputEvent` | DELETED; TODO (F2) resolved by §2.3's position head |
| `MousemoveInputEvent` | DELETED; its canvas-offset ctor dance dissolves into `fromBrowserEvent` (§2.1) |
| `TouchInputEvent` (base) + `Touchstart/move/end` | DELETED; the move+down synthesis becomes §2.3's down head; the boundary rounding moves to `fromBrowserEvent` |
| `WheelInputEvent` | KEPT, re-parented to `InputEvent` (§2.5) |
| `InputEvent`, `InputEventsQueue`, keyboard/clipboard/virtual-keyboard/resize events | KEPT verbatim (F21's one-line resize fix excepted, owner-flagged) |
| `WorldWdgt._initMouseEventListeners` + `_initTouchEventListeners` | replaced by ONE `_initPointerEventListeners` (§2.2) |
| `WorldWdgt.initEventListeners` / `removeEventListeners` / `_dissolveWorldNoSettle` | names + call sites unchanged (the harness calls the pair, F11); bodies/groups updated; count-prose de-counted |
| `ActivePointerWdgt.processMouseDown/Move/Up` | renamed `processPointerDown/Move/Up`, taking the event value (§2.3) |
| `ActivePointerWdgt.processWheel`, `processDoubleClick`, `processTripleClick` | unchanged |
| (nothing) | NEW: `PointerInputEvent` + down/move/up/cancel classes; `ActivePointerWdgt.processPointerCancel`; `@pointerType` field; `touch-action: none` on the canvas; guarded `setPointerCapture` |

---

## §3 The axes (why this shape)

- **One family, not a bridge.** Keeping Mouse* classes as shims over Pointer* would preserve
  two vocabularies for one thing forever ("retirements finish in-arc" — program doctrine). The
  fan-in is 10 construction/call sites total (F7, F10); a bridge costs more than the sweep.
- **The event value into the hand, not exploded params.** The hand needs `pointerType` now and
  `pointerId`/`pressure` later (T4, Plan 4); exploding them is a 12-parameter signature that
  grows again per plan. The value object is immutable, already built, and self-naming. (The
  old "handlers want parameters, not events" comment (~:626) is about WIDGET handlers and the
  harness's storage of them — unchanged by this.)
- **`undefined` position on synthetic down/up, not a schedule-time guess.** L1 primitives build
  events during the macro step, BEFORE the queued moves drain — `world.hand.position()` at
  schedule time is the PRE-gesture position (wrong). Absence marks "current at drain time",
  which is today's semantics and the pixel-neutrality proof (§2.3).
- **World coordinates in the event, converted at the boundary.** One convention, one
  conversion, the F9 double-offset dissolved rather than ported. The alternative — keeping
  fake-page coords — ports a masked bug into a new family.
- **No preventDefault on pointer listeners** — focus survives; compatibility mouse events are
  unobserved; `touch-action` owns panning (I1). The alternative (preventDefault + refocus by
  hand) reimplements the browser.
- **isPrimary filter at the listener.** The hand is a single-pointer machine until T4; filtering
  at the boundary keeps the queue an honest record of what the world processed. T4 lifts the
  filter, not a redesign.
- **Keep the L1 verb names** — §2.6's reason; H2 owns the verb vocabulary.

---

## §4 The distilled argument

The whole input stack narrows to a waist of ten sites: three listener pushes, seven synthetic
constructions — everything else consumes the hand's dispatch, which Plan 1 just rebuilt and
this plan does not touch. Because the harness detaches the listeners during every test (F11),
the suite pins the constructor+hand seam to byte-identity while the listener seam — the only
genuinely NEW code path — is provable by one cheap probe plus the boot-smoke pages. So the
migration is that rare thing: a total retirement (eight files, two emulation layers, one
masked coordinate bug, one phantom-button bug class) whose blast radius is measurable in
advance and whose gate is "nothing changed" — plus one new behaviour (cancel) small enough to
reason out state-by-state (§2.4) and witness with fresh tests. Doing it NOW, between Plan 1
(which unblocked the seam) and Plans 3/4 (which consume `pointerType` and the finger path),
is the program's sequencing doing its job.

---

## §5 Phases

Each phase: goal · steps · pixel impact · gate · commit. **Recapture budget: ZERO in every
phase** (program §4 rule 1). The ONLY new reference files are P2's new tests' own captures —
new tests, not recaptures. **No Automator version bump**: the harness change does not alter
what a capture produces (the version means exactly that — tests-repo CLAUDE.md), and
`check-refs` would force a 3,600+-file recapture on a pointless bump. If ANY existing
reference diffs at any gate: STOP (worker rule 3) — it is a bug or an undeclared visible
change; the coordinator eyeballs `fg diffpage <names>` and takes it to the owner. Never a
silent recapture.

### P0 — Re-verification, counts, the delivery probe (~¼ day)

1. `fg status`; confirm a green gauntlet baseline exists for the current heads (run one in the
   background if the tree moved since the last).
2. **Sonnet, read-only:** re-verify F1–F21 with the recorded commands. Any drift → report;
   coordinator amends §1 BEFORE P1 briefs (a plan's premises are hypotheses).
3. **Opus — probe A, delivery** (`Fizzygum-tests/.scratch/pointer-delivery-probe.js`): boot the
   BUILT `index-sw.html` under Puppeteer-Chrome AND Playwright-WebKit (the two suite engines).
   In-page: attach throwaway `pointerdown/move/up/cancel` listeners on `#world`, dispatch
   constructed `new PointerEvent('pointerdown', {clientX:…, pointerType:'touch', pointerId:7,
   isPrimary:true, pressure:0.5, bubbles:true})` etc.; assert delivery AND field fidelity
   (pointerType/pointerId/isPrimary/pressure/button/buttons) in BOTH engines; assert
   `CSS.supports('touch-action','none')` in both.
4. **Probe A2, capture semantics:** inside the probe's pointerdown listener call
   `canvas.setPointerCapture(e.pointerId)` — record per engine whether a synthetic-dispatch
   capture THROWS (expected `NotFoundError`: no active pointer). The answer calibrates §2.2's
   try/catch comment; either answer keeps the guarded shape.
5. **Probe A3, trusted input:** drive REAL input — CDP `Input.dispatchMouseEvent` (Chrome) and
   `page.mouse` (Playwright-WebKit) — and assert the page's pointer listeners fire from
   trusted events too. This is the headless-engine risk killed before a line of product code.
6. **Sonnet:** measure the sweep surface — `grep -c` per old name across `src/`,
   `Fizzygum-tests/scripts/`, `Fizzygum-tests/tests/` (prose), `docs/` — into the STATUS box.
   These counts are P1/P3's completion checks.
7. Nothing committed (probes stay in `.scratch/`).

**Go/no-go:** probe A green in BOTH engines. A red WebKit half is a stop-the-arc finding
(escalate to the owner with the probe output; do NOT start P1).

### P1 — Family + listeners + hand + synthesis, in one commit (~½ day; PIXEL-IDENTICAL)

One Opus worker, two briefs, ONE gate + commit at the end (the tree is legitimately non-green
between the briefs; nothing else runs meanwhile — one code worker at a time).

- **Brief (a) — framework:** add the 5 classes (§2.1); re-parent `WheelInputEvent` (§2.5);
  delete the 8 files; rewrite the listener set (§2.2) incl. `touch-action: none` in
  `src/index.html`; rewrite the hand's entry points + add `processPointerCancel` + the
  `pointerType` field (§2.3, §2.4); de-count the listener count-prose (F3); the F21 resize
  listener one-liner (`(event) =>`) — **flag it in the report for the owner's commit review as
  a fix-in-passing** (owner preference: ask about out-of-scope changes).
- **Brief (b) — synthesis + scripts:** the seven `MacroToolkit` sites + the ~:390 comment
  (§2.6); `smoke-boot-headless.js`; the two prelude NAME STRINGS;
  `WorldTestSupport.coffee:176` count-prose. Then sweep-check: `grep -rn
  "MousedownInputEvent\|MouseupInputEvent\|MousemoveInputEvent\|TouchstartInputEvent\|
  TouchmoveInputEvent\|TouchendInputEvent\|MouseInputEvent\|TouchInputEvent\|processMouseDown\|
  processMouseUp\|processMouseMove"` over `src/`, `Automator-and-test-harness-src/`,
  `Fizzygum-tests/scripts/` → the only survivors are prose/comments scheduled for P3.
- **Gate:** `fg presuite` **byte-identical** (dpr1 suite ∥ paint audit ∥ fracplane rider);
  then the WebKit suite (`cd Fizzygum-tests && npm run test:webkit`) — the other engine, same
  references; `fg smoke` (both entry pages boot the NEW listener path with zero console
  errors). The build's own 28 gates ran inside `fg presuite`'s build.
- Commit (coordinator proposes; owner approves).

### P2 — The cancel path witnessed (~¼ day; NEW references only)

1. New L1 primitive `syntheticEventsPointerCancel_InputEvents (startTime…) ->` — queues a
   position-less `PointercancelInputEvent.synthetic …` (doc-comment per the toolkit's
   conventions; verb name is an L1 `_InputEvents`, "Macro" nowhere mid-name).
2. New SystemTest **`SystemTest_macroPointerCancelAbortsDragWithoutClick`** (authored per the
   `/author-macro-test` skill + `src/macros/CLAUDE.md`): fixture a widget on the desktop + an
   OPEN menu elsewhere; press-and-drag the widget over a receptive container and PAST the dwell
   (`dwellToArmMs` elapsed, ring/label showing), inject the cancel; assert + screenshot: the
   payload sits on the WORLD at the cancel position (NOT embedded — the dwell was armed, the
   abort must still refuse it), the menu is STILL OPEN (no dismissal), no click action fired,
   and a subsequent tap does not register as a double-click (`assertValuesEqual` oracles +
   1–2 screenshots).
3. New assertion-only test or a second scene in the same macro for the non-float case: press a
   slider button, cancel — `endOfNonFloatDrag` ran (button repaints un-pressed), no phantom
   `mouseButton`.
4. Capture the NEW references at dpr 1+2 (`capture-macro-test-references.js` full flow);
   `make-visualisation.js` for the new test.
5. **Gate:** `fg presuite` — all 316 pre-existing tests byte-identical, the new tests green;
   `fg menusweep` (the fixture opens menus). Commit.

### P3 — Deletions verified, docs, close, tail (~¼ day)

1. **Sonnet ×N (disjoint files):** the prose sweep — the ~8 test-dir intent/comment mentions
   (F12; tests are served live, no rebuild), `src/macros/MACRO-PATTERNS.md` (~5 sites),
   `docs/tooling/coalescing-measurement.md`, `docs/architecture/immutable-value-classes.md`
   (the family list + the now-pure construction note),
   `docs/plans/runtime-performance-optimization-plan.md` (live plan — weave the rename in,
   never a slapped-on note), the hand's ~:609 dispatch doc-comment if brief (a) left it.
   Archives untouched.
2. Program doc: STATUS box row for Plan 2; tail-ledger entries (below); `T4` remains BACKLOG
   ("after Plan 2" — its destination is already right; no action).
3. **Gate:** `fg doc-narration`; then the FULL close — `fg gauntlet` (18 legs; the
   settle/capstone legs also witness the prelude rename, F7) and `fg homepage` (the production
   page boots the new listener path + the snapshot round-trip). Both in background with
   verdict-file peeks.
4. Commit; coordinator runs the close-arc ritual (memory + program doc + owner review).

**Tail (drain before Plan 3 starts — program §5 rule 2):**
- `fg fuzz` is NOT required by this plan (no pixel-read/wait verb changed); if any P1/P2 edit
  touches `readyForMacroScreenshot`/wait plumbing after all, run it once — remembering its
  THREE outcomes: OK / FAILED / **INVALID (exit 2) is neither** (dead shards print `failed: 0`),
  and a fuzz failure is NEVER a recapture reason — fix the read.
- Expected tail items: none pre-filed. Anything discovered lands in the program ledger with a
  destination, per rule 1.

**ETA (owner preference: upfront):** P0 ¼ + P1 ½ + P2 ¼ + P3 ¼ ≈ **1¼ session-days + tail** —
matches the program's "Plan 2 ≈ 1 + tail" (§3). Status updates every ~5 min during long ops.

---

## §6 Central risks and how each is bounded

| risk | where | bound |
|---|---|---|
| Headless WebKit delivers no/false PointerEvents | everything | P0 probe A in BOTH engines is the go/no-go, before any product code |
| The down/up position head changes suite pixels | P1 | synthetic down/up carry `undefined` position → the head is skipped → byte-identical; `fg presuite` byte-identity is the gate, and any diff is a STOP, not a recapture |
| `setPointerCapture` throws on synthetic/dispatched events | P1 | guarded try/catch by design; P0 probe A2 documents the per-engine behaviour in the comment |
| preventDefault removal lets a browser default through (focus loss, page pan) | P1 | `touch-action: none` owns pan; NO mouse listeners remain to observe compatibility events; probe A3 + `fg smoke` + `fg homepage` boot the real pages |
| A missed caller/name-string of the old API | P1 | `check-unresolved-sends` (src+harness) fails the build; the two prelude STRINGS are enumerated here (F7) and re-checked by brief (b)'s grep + the gauntlet's settle/capstone legs |
| The cancel path fires a click or dismisses menus | P2 | §2.4 is a per-state table, implemented as its OWN method (never delegating to `processPointerUp`); the witness test asserts menu-still-open + no-action + no-double-click |
| drop-on-cancel arms the dwell at the last instant | P2 | `_endDragEmbedInteraction()` runs BEFORE the drop and the drop is the forced world-arm, bypassing `drop()`'s re-evaluation (§2.4) |
| Real-device touch behaviour drifts (vs. today's emulation) | P1 | the pointer stream carries the same button/buttons values the emulation synthesized (F8); position head reproduces the move+down pair; `isPrimary` filter reproduces `touches[0]`; nothing else in the hand changed |
| Coordinate-convention change breaks a non-origin canvas embed | P1 | today is ALREADY broken there (F9, masked); the new path is correct by construction; every shipped page pins the canvas at (0,0) either way |
| Cross-repo rename misses `Fizzygum-tests/scripts` readers | P1/P3 | F7/F12 enumerate them; the P9 lesson is a named brief step, not a hope |

---

## §7 Verification protocol

- Inner loop per step: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (build + dpr1
  suite ∥ paint audit ∥ fracplane). **Byte-identical is the gate for every phase** (the new P2
  tests' own references excepted).
- Cross-engine at P1: `cd Fizzygum-tests && npm run test:webkit` (same references, no
  re-baseline).
- Listener path (the suite cannot see it): `fg smoke` at P1; `fg homepage` at P3 close.
- Phase close P3: `fg gauntlet` (18 legs) in the background;
  `cat /tmp/fg-gauntlet.verdict` at a ~5-min cadence. `[shard N] did not start within 90s` /
  `CoffeeScript is not defined` = the boot-storm infra flake, not a bug; a leg passing its
  serial retry = a load-flake warning, not a FAIL.
- Docs: `fg doc-narration` after the P3 sweep.
- Never pipe a gating `fg` call; never edit mid-run; probes in `Fizzygum-tests/.scratch/` only.
- Gates that WILL fire if mishandled, and the correct response (F18): `check-coffee-syntax`
  (filename = class name for the 5 new files), `check-dead-methods` +
  `check-unresolved-sends` (the deletion/rename net — fix the caller, never allowlist),
  `check-stinks` comment-smell (present tense), `check-argument-holes` (use the two statics,
  §2.1 — never a 14-arg call with `undefined` filler in the middle), tests-repo
  `check-macro-source-discipline` (the new test's macro: no `world.evaluateString`, "Macro"
  only trailing).

---

## §8 Rejected alternatives — do not re-attempt

- **Axis-locked scrolling, scroll-by-background, two-finger-scroll models** — ruled OUT (I3):
  axis lock breaks 2-D grids/menus and would change mouse behaviour; `touches[0]` heuristics
  are the emulation this plan deletes. Do not re-derive.
- **Keeping `touches[0]`/any multi-touch logic** — T4 (BACKLOG, after this plan) owns
  multi-pointer; until then `isPrimary` IS the model.
- **Per-device geometry/behaviour forks** — G1 forbids them; the input-mode toggle is T11
  (Plan 3 deletes it). Plan 2 adds no `pointerType` branch anywhere (that is Plan 4's grammar).
- **A Mouse*→Pointer* shim/bridge period** — two vocabularies for one thing; the fan-in is 10
  sites (§4); retirements finish in-arc.
- **preventDefault on `pointerdown`** — kills click-to-focus (keyboard input dies) and buys
  nothing once no mouse listeners remain (§2.2). The P0/P1 smoke evidence stands in for the
  temptation.
- **Renaming the L1 macro verbs** (`syntheticEventsMouseMove_InputEvents` → "Pointer…") —
  hundreds of macro sources churn to pre-empt a vocabulary H2/Plan 4 owns (§2.6).
- **Renaming the widget-facing dispatch surface** (`mouseDownLeft` …) — Plan 4's, if anyone's;
  also the `check-raw-pointer-reads` HANDLER_NAMES set and every widget in the tree.
- **Routing cancel through `processPointerUp` with a flag** — up means "user chose this spot":
  clicks fire, menus dismiss, multi-click arms. Cancel is a different verb (§2.4).
- **Passing a drain-time-guessed position on synthetic down/up** — schedule-time code cannot
  know it (§3); `undefined` is the honest value and the pixel-neutrality proof.
- **An Automator version bump "to be safe"** — the version means "what the harness captures";
  captures are unchanged, and a bump obliges a full recapture (tests-repo CLAUDE.md).

---

## §9 Delegation map — coordinator and workers (program §3.1)

The coordinator (the session) never edits source or runs suites; it briefs, reads reports,
checks verdict files, decides at gates, and talks to the owner. Workers are fresh agents with
no conversation context: `Agent` with `subagent_type: general-purpose`, `model: "opus"` (phase
work) or `"sonnet"` (mechanical work). ⛔ Never `fork`, never `isolation: worktree`. **One code
worker at a time**; parallel workers only for read-only work and docs edits to disjoint files.

### 9.1 Per-phase map

| phase | worker | parallel? | brief = plan section + | gate the worker runs | coordinator decides |
|---|---|---|---|---|---|
| P0 fact re-verify + sweep counts | Sonnet ×2 | yes (read-only) | §1's F1–F21 commands; P0.6's grep list | none | records drift + counts into STATUS; amends §1 |
| P0 probes A/A2/A3 | Opus ×1 | no (browser runs) | P0 steps 3–5's assertion list | the probe script itself, both engines | GO/NO-GO for P1; a WebKit red goes to the owner |
| P1 brief (a) framework | Opus ×1 | no | §2.1–§2.5, §2.7; F3/F9/F21 | build only (tree non-green until (b)) | reads the report; F21 owner-flag noted |
| P1 brief (b) synthesis + scripts | same Opus ×1 | no | §2.6; F7/F10/F12; the sweep grep | `fg presuite` byte-identical; `npm run test:webkit`; `fg smoke` | verdict files; commit proposal |
| P2 cancel + witness tests | Opus ×1 | no | §2.4, P2 steps; `/author-macro-test` skill; `src/macros/CLAUDE.md` | `fg presuite`; `fg menusweep`; new-test capture at dpr 1+2 | reviews the new test's shots; commit proposal |
| P3 docs sweep | Sonnet ×N | yes (disjoint files) | per file: the F12 mention list + the present-tense paragraph | `fg doc-narration` | reviews diffs |
| P3 close | coordinator | — | — | `fg gauntlet`, `fg homepage` | close-arc ritual, program-doc STATUS/tail, memory, owner |
| tail | per item | per item | the ledger row + destination | as the item needs | ledger bookkeeping |

### 9.2 The worker brief (template — copy, fill the ⟨⟩, nothing else)

```
You are executing ⟨phase/sub-step⟩ of Fizzygum/docs/plans/pointer-events-plan.md.
Read that plan's §0, §0.5 and §⟨phase⟩ in full, then Fizzygum/docs/plans/frames-input-touch-program.md
§2.3 for rulings ⟨IDs⟩. Also read Fizzygum-all/CLAUDE.md and Fizzygum/CLAUDE.md. All commands through
/Users/davidedellacasa/code/Fizzygum-all/fg by absolute path. Probes under Fizzygum-tests/.scratch/.
Do: ⟨the phase's step list, or "every step of §⟨phase⟩"⟩.
Gate: ⟨exact fg command(s)⟩ → expected ⟨verdict⟩. Launch long ops with run_in_background and wait for
the notification; never poll; never pipe the gating call.
Pixel budget: ZERO existing references may change. ⟨P2 only: the NEW test's own references are
created, not recaptured.⟩ Any other diff = STOP (rule 3).
Stop and report (do not improvise) if: a §1 fact is false; a fix shape is falsified twice; a gate
fails for a reason you cannot state in one sentence; a diff appears outside the budget; you need a
decision the ledger does not cover. Never recapture, never commit, never push.
Comments you write: present tense only, no history narration (the build's comment-smell ratchet fails
on it). `undefined` is the one absence value.
Report (≤ 60 lines): files changed (git diff --stat); each gate's literal /tmp/fg-<cmd>.verdict line;
counts measured; tests added/changed; open questions; which stop rule fired, if any.
```

### 9.3 What the coordinator checks on every report (cheap, never a re-do)

1. `cat /tmp/fg-<cmd>.verdict` for each gate the report claims — the literal line, not prose.
2. `git -C <repo> status --short` + `git diff --stat` in BOTH repos — the changed-file list
   matches the phase (P1 touches `Fizzygum/src` + `src/index.html` + 4 tests-repo scripts and
   NOTHING else; a stray file is a question).
3. A reported pixel diff → `fg diffpage` was produced → the coordinator looks at it (the one
   visual judgement it keeps), then the owner.
4. A stop rule fired → read ONLY the quoted evidence; amend §1 or the brief; re-brief. Two
   stops on the same step → re-frame (never a third variant).
5. Then: commit proposal to the owner, or the next brief.

---

## §10 References

- Program: [`frames-input-touch-program.md`](frames-input-touch-program.md) — §2.3 rulings
  (I1/I2/I3/H1), §3 sequencing + §3.1 execution model, §4 recapture policy, §5 tail rules
  (T4/T7/T11 destinations), §6 just-in-time authoring.
- Plan 1 (closed, the seam's other half):
  [`../archive/frame-lifetime-and-docking-plan.md`](../archive/frame-lifetime-and-docking-plan.md)
  — §9 is the delegation-map shape this §9 instantiates.
- Living truth to update at P3:
  [`../architecture/immutable-value-classes.md`](../architecture/immutable-value-classes.md)
  (the family list + pure construction),
  [`../tooling/coalescing-measurement.md`](../tooling/coalescing-measurement.md),
  [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md)
  (only if a gate's own text names the old plumbing — none found at authoring).
- Doctrine the executor must hold: `Fizzygum-tests/DETERMINISM.md` (§1 the contract, §3 the
  cadence rule + case law), `Fizzygum/src/macros/CLAUDE.md` (rule 2: input through the queue —
  this plan's smoke-script exception is a PROBE, the one legitimate direct call left),
  `Fizzygum-tests/CLAUDE.md` (scripts read core internals — grep the WHOLE repo on a rename).
- Memory notes the executor should know exist: ask-before-commit/push; long-op ETA + ~5-min
  status; no conclusions before evidence; stop after two falsified fixes; a cross-repo rename
  must grep the tests scripts (connector P9); perl/sed blanket edits de-indent `.coffee` — use
  the Edit tool; multi-click event-time forget (the wall-clock ban's origin).

---

### Start-prompt for a fresh coordinator session (copy-paste)

> You are the COORDINATOR for Plan 2 of the frames·input·touch program. Read
> `Fizzygum/docs/plans/pointer-events-plan.md` IN FULL, then the program doc's §2.3/§3.1/§4/§5.
> Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` and verify heads ≥ the plan header's
> (Fizzygum `cada3c1c` / tests `08fec10fa`); if the tree moved, expect §1 drift and re-verify
> before briefing. Execute per the plan's §9 delegation map, phases P0→P3, one code worker at a
> time, briefs from the §9.2 template. Recapture budget ZERO. Ask the owner before every
> commit/push.
