# Gesture grammar + finger harness — one grammar per pointer kind, and the Automator grows a finger

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-26 against Fizzygum `10bb66b2` / Fizzygum-tests `b6912bc54` (suite 321
SystemTests at 1920×880, Automator 0.3.0, 1,898 committed reference PNGs, gauntlet-green
heads). Every `file:line` was verified on that date — **line numbers DRIFT; the method name /
quoted code is authoritative, so `grep` before trusting a number.** Plan 4 — the LAST plan — of
the program [`frames-input-touch-program.md`](frames-input-touch-program.md): the decisions this
plan implements are **owner rulings recorded there — I2 (the gesture grammar, the core of this
plan), H1 (the harness's finger IS the product's touch path), H2 (intent verbs translate per
pointer kind; a pointer-kind reference axis; finger-only + tablet-extent tests; a `finger`
gauntlet leg), T6 (hover-dependent affordances → here), T7 (virtual keyboard keyed on the
starting tap's `pointerType` → here, tail), T18 (halo crowding — this plan must DECIDE
absorb-or-BACKLOG as an explicit owner decision, §2.9 OD4)** — plus the context rulings I1/I3
(Pointer Events, landed by Plan 2), G1 (one geometry — only the gesture→intent mapping may
differ per input) and G3/G4 (targets vs indicators). Cite these IDs; do not re-argue them.
Plans 1, 2, 3 and 3.5 are EXECUTED AND CLOSED (archived); this plan is authored against the
post-Plan-3.5 tree per the program's just-in-time rule (§6).

**Tail-row verification at authoring (the program's four stale-open rows, checked on this
tree — evidence in §1 F17; the coordinator marks the program ledger from this, it is not
re-work for a phase):** **T9 CLOSED** (the `PromptWdgt` comment now states the ONE `isMenu?()`
consumer, `ActivePointerWdgt.processPointerDown`); **T10 CLOSED** (`tight` has zero occurrences
in `FrameWdgt.coffee`; only `VerticalStackPanelWdgt` declares/reads it); **T14 CLOSED**
(`FrameBarWdgt._destroyEditButtonNoSettle` retires via `@editButton?._fullDestroyNoSettle()`,
and the witness `SystemTest_macroRetiredBarPieceTakesItsFaceWithIt` exists); **T15 CLOSED as
option (b)** (the `closeFromFrameBar` allowlist entry stands WITH its stated reason — "the
bar-press handler is its only in-tree caller (same shape as setScrollPolicy above)").

**STATUS BOX** (fill per phase as executed)
- PRE-RULED 2026-08-26 (owner, at the plan review): **OD1 = (b)** event-time decision + a
  per-cycle check suppressed under the Automator's pacing control (the glide's idiom) ·
  **OD4 = (a)** T18 → BACKLOG paired with the owner-pending G2 halo feel-check (one
  conversation; the P5 row records the pairing). OD3 (the hold dial, proposed 500) is felt
  at P2's eyes-on; OD2/OD5 wait on P3/P0's measured numbers as authored.
- P0 re-verification + probes + measurements: **DONE 2026-08-26.** Facts 19/19, NO drift (a
  program first repeated); F20/F21 added (probe-adjacent), F6/F14/F16/OD2 amended dated.
  Probes A/B/C GREEN both engines (`Fizzygum-tests/.scratch/p0-probe-{a,b,c}-*.js`, exit 0):
  A = touch delivery to the hand proven end-to-end (H1's listener path; hand.pointerType
  reads 'touch', press+click dispatched, no right path taken); B = the before-picture pinned
  (a touch tap clicks; a touch drag over detachable content in a viewport LIFTS like a
  mouse; dwell arming strictly EVENT-time — 1503 ms wall + 113 per-cycle re-entries did NOT
  arm, 500 ms event time DID) = OD1(b)'s confirmation evidence; C = per-test 1024×768 extent
  CLEAN at the reset seam (ZERO gate tokens, no residue; the ratchet is extent-blind by
  construction) ⇒ **OD5 resolved on the clean branch — tablet-extent set lands per §2.7, no
  owner decision needed.** Measurements: right-button gestures 194/108 tests, finger hold
  cost ≈116 s suite-wide / +5.4 s worst test; OD2 storage (a) +168.8 MB +91% · (b) +21 MB
  +11% · (c) +148.5 MB +80% (capture wall-clock, not storage, is what (c) halves);
  **scroll-drag edge exposure ZERO at 100% suite coverage** (plant-proven detector; the one
  token = the wheel's existing F7 escalation in a wheel-only test). Nothing committed
  (probes/detectors stay in `.scratch/`; plan amendments ride the P1 commit).
- P1 the grammar in the hand + T7, MOUSE-INERT: **DONE 2026-08-26** (one Opus worker + one
  corrective bounce). The recognizer on the hand (per-stroke scalars, cleared via
  `_forgetPressBookkeeping` + at every down; OD1(b) as `_holdDecisionTime` — event time, plus
  the cycle clock only when the pacing control is idle, the glide's verbatim triple); hold →
  `openContextMenuAtPointer` on the pressed widget (F2's path verbatim); hold-then-move
  dismisses via the F18 sweep; hold-consumed up dispatches no click; pre-arm travel commits
  plain-drag-for-life. Capabilities derived, neither falsified: `ownsDragsStartingOnMe`
  (FrameBarWdgt + the four `nonFloatDragging` owners: HandleWdgt, SliderWdgt,
  StackElementsSizeAdjustingWdgt, PaletteWdgt) and `claimsPlainDragsForScrolling`
  (ViewportWdgt = `@isScrollingByfloatDragging and @isScrollableNow()`), asked in ONE
  ancestry walk, chrome first. THREE consumers gated on `strokeMeansMouseDrag()` (the third
  — the pressed-move mouseMove channel, both dispatch sites — added by the corrective after
  the authored "falls out of the same arming" claim measured FALSE; §2.2/§2.3 amended
  dated). Scroll-drag at-edge escalation via `scrollByDragDelta` (wheel-rule twin, TODO
  retired with the mechanism). Touch hover dissolution at up+cancel. T7: both seams keyed on
  the starting tap's kind; `isTouchDevice` RETIRED. T6-title verification: every
  hold-reachable menu is the right-click's own (titled); NOTED for the owner — the dev-mode
  hierarchy-disambiguation menu is untitled (equally so for right-click) and titles use the
  class-derived name, not `colloquialName()`. Gates: build 28/28 ×2; presuite BYTE-IDENTICAL
  ×2 (321/0, zero diffs); menusweep OK (3749 items + 53 prompt Oks / 464 menus).
- P2 grammar witness tests (+ the hold-dial eyes-on): **DONE 2026-08-26** (same Opus worker,
  two coordinator-ruled follow-ups). §2.6 landed as `@syntheticTouch` (a SIBLING factory,
  not a kind argument — the per-kind DEVICE constants are the factory's content) + four L1
  touch verbs (tap / hold with `alsoRelease:` / drag / drag-from-held-press; the composed
  hold-then-drag verb DELETED as dead — the split pair is what lets a witness screenshot the
  held state). Per-test extent declaration `testScreenExtent` honoured by the reset seam
  (default 1920×880 byte-identical). EIGHT witness tests (the five planned + assertion-only
  keyboard + THREE tablet-extent at 1024×768 — owner ruled the third, the docked-toolbar
  chevron, in). All six gesture tests declare `grabDragThreshold: true` (the Automator's
  threshold skip would grab before a hold fires — the P1 report's trap, handled test-side).
  **OWNER RULINGS at eyes-on: OD3 = keep 500 ms; the dev-mode hierarchy-disambiguation menu
  STAYS UNTITLED (its committed reference shows it — right-click parity).** Two product
  defects found and fixed by the witnesses: the hold's drag guard read the desktop press's
  no-op world booking as "already dragging" (silenced the desktop hold — Automator-only
  manifestation); the virtual-keyboard DOM input was never removed from the page (class-(B)
  page-lifetime leak; cleared in `_dissolveWorldNoSettle`, `vmtruth` green twice). One plan
  gap measured and ruled mid-phase: the §2.4(4) sweep alone was UNDONE by the per-cycle
  re-sync (a touch tap's reference grew a tooltip) ⇒ the **pointer-absence state** (§2.4(4)
  as amended; one field, five sites; only the chevron's image_2 recaptured — the other
  seven tests' pixels never carried a hover artifact). Captures: 8 tests × dpr1+2, ~104
  files, visualisation pages generated, `check-refs` clean. Gates: build 28/28; presuite
  ALL 329 green with 321 pre-existing byte-identical (×3 through the phase); menusweep OK;
  P2-close gauntlet 18/18 twice — second run `OK(warn)`: the `serialization` leg failed
  in-wave and passed alone (file-save reads under wave load — the sanctioned load-flake
  path; not attributable to this delta: the prior gauntlet passed that leg in-wave on
  near-identical code; log kept at `/tmp/fg-serialization.parallel-fail.log`). Tail row
  filed: the boot-smoke does not cover the harness page (BACKLOG at P5).
- P3 the finger harness mode + the reference axis: **DONE 2026-08-26** (Sonnet runner flags +
  one fresh Opus, two ruling rounds). The mode: `?pointer=finger` → `FIZZYGUM_POINTER_KIND`
  (F13 pattern), toolkit reads lazily; `--pointer=` on run-all / run-macro / capture /
  run-sequence, `recapture.js` REFUSES it loudly (mouse-only until finger refs exist). The
  translation lives in the L1/L2 bodies (the per-verb table is in the P3 worker report;
  verb names + all committed macros untouched): click→tap, right family→hold,
  press-drag-release→hold-then-drag, wheel→plain drag (successive clamped swipes — a wheel
  notch has unlimited reach, a finger does not: `maxScrollSwipes`), no-button moves→aim only
  (no hover) EXCEPT a carried payload (a buttonless CARRY stream — `pickUp()` then move must
  still travel), chrome-locating drags (handles/thumbs/resizers)→plain drag no hold. The
  axis: `…/ceilPixRatio_<N>/finger/` through `refpaths.js` (the ONE parser); the loader
  REQUIRES/EXCLUDES the segment both ways (F15 closed); capture writers kind-scoped (⚠
  un-scoped `--clean` would have deleted mouse refs); visualisation excludes finger;
  manifests structural. Mouse-only-by-meaning: `pointerKinds`+`mouseOnlyReason`, loader
  filter in finger runs. THREE touch-gated product amendments ruled + landed in the hand
  (one shape falsified BY MEASUREMENT first — the categorical zero-delta-never-grabs form
  moved 41 mouse references, NOT recaptured, re-shaped per-kind): a touch stroke's
  zero-displacement move never grabs; the desktop instant-grab carve-out is mouse/pen-only
  (touch always takes `grabDragThreshold`); a booked-but-unmoved non-float target does not
  suppress the hold. DISCOVERY (full corpus, dpr1): **(i)=326 translate fine · (ii)=9
  declared with reasons** (4 hover/contrast incl. two of P2's own witnesses, 3
  spreadsheet-wheel — the sheet takes no drag-scroll, a finger-scrollable sheet is a
  PRODUCT feature → tail candidate — wheel-refusal, rotated-island hover delivery) **·
  (iii)=0 named causes**; finger selection 320; dpr1 finger wall-clock 1.96 min. ⚠ THREE
  load-sensitive tests (SimpleDocumentAllReflows, SimpleTextScrollPanel…,
  TiltedWindowDropRequiresDwell) fail ONLY in the sharded finger suite — deterministic
  under load, clean in isolation AND in sequence-repro (predecessor leak structurally
  excluded for one) — DEFERRED to P4's verify run per the timebox, unresolved on purpose.
  OD2 numbers over (i)=326: (a) dpr1+2 +170 MB (+90% of tests/ 189 MB) · (b) ~40-test
  subset +21 MB · (c) dpr2-only +149 MB (capture halves, storage only −12%) · capture 5–6 h.
  Gates: build 28/28; presuite BYTE-IDENTICAL 329/329 (×3); lint OK; ZERO reference diffs
  (the structural no-bump proof). The fg `finger` leg drafted (webkit+dpr2, own wave) —
  coordinator applies at P4.
- P4 the finger baseline + the `finger` gauntlet leg: —
- P5 T18 decision, docs, close, tail — and the PROGRAM close: —

---

## MANDATE

**Give the one landed geometry ONE gesture grammar that works for a mouse and a finger, and
give the test system a finger to witness it with.** At close: the hand branches per-stroke on
the `pointerType` Plan 2 installed — a finger can open a context menu (hold-as-right-click, the
canonical case), a plain finger drag scrolls where a mouse drag would lift, hold-then-move
lifts, chrome drags need no hold on either device, and every branch is INERT for
`pointerType: 'mouse'` (today's mouse behaviour byte-identical — the recapture budget for
existing references is ZERO in every phase); T6 resolved — the hold-opened menu's title names
the widget (the rest of hover declared out, each with its touch story); T7 resolved — the
virtual keyboard keyed on the STARTING tap's `pointerType`, the never-true
`isTouchDevice` retired; T18 DECIDED by the owner (absorb or BACKLOG, §2.9 OD4). AND the
finger harness: the macro toolkit synthesizes touch strokes through the same queue and event
classes (H1), the intent verbs translate per pointer kind under a run-level finger mode (H2),
finger runs match references on their OWN axis (new files — **no Automator version bump:
what the harness captures for a mouse run is unchanged, and §5's gates prove it
structurally**), a `finger` gauntlet leg exists, and the program's tail ledger is EMPTY so the
PROGRAM closes. Out of scope, each with its address: multi-pointer/pinch + retiring the
Safari `gesture*` listeners (T4, BACKLOG), desktop-edge docking (T5, BACKLOG), multi-user
input attribution (the Plan 3.5 `User` model's "Plan 4 at the earliest" marker — BACKLOG, see
§5 P5 tail), renaming the widget-facing dispatch surface or the L1 verb names (§8 — rejected,
recorded).

---

## §0 Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework ("web operating system") rendered on
one HTML5 canvas. Three sibling repos under `Fizzygum-all/`: `Fizzygum/` (source — this plan
edits `src/`), `Fizzygum-tests/` (the SystemTest suite + Automator harness source, served
through the `latest/js/tests` symlink — test edits need NO rebuild; harness `.coffee` edits
DO), `Fizzygum-builds/` (generated, never edited). Every build/test command goes through
`/Users/davidedellacasa/code/Fizzygum-all/fg` (ABSOLUTE path, never `./fg`); bare `fg` prints
the roster. Read the root `CLAUDE.md`, `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md`
before touching anything. No module system: every class is a global; one class per file,
filename = class name.

**The vocabulary:**
- **The hand** = `ActivePointerWdgt` (`src/ActivePointerWdgt.coffee`, 1,337 lines) — the ONE
  pointer: hit-testing, grabs/drops, multi-click recognition, the drag-embed dwell machine,
  pop-up dismissal. Since Plan 2 its entry points take the immutable event value:
  `processPointerDown/Move/Up/Cancel (e)`, and it records `@pointerType` per stroke — the
  carrier this plan finally branches on (Plan 2 installed it and deliberately branched
  NOWHERE).
- **The event family** = `src/events-input/PointerInputEvent.coffee` + the four
  down/move/up/cancel subclasses. Two construction boundaries: `@fromBrowserEvent` (page →
  world coords, real `pointerType` off the DOM event) and `@synthetic` (the macro boundary —
  today it BAKES `pointerType: 'mouse'`). The queue (`world.inputEventsQueue`) drains once per
  cycle by event-time (`event.time <= dateOfCurrentCycleStart`) — the determinism backbone.
- **The three stroke verbs a drag can mean:** FLOAT-drag (a widget rides the hand — lift),
  NON-float drag (sliders, handles, resizers — the widget stays, its value moves), and
  SCROLL-drag (`ViewportWdgt.mouseDownLeft` installs a per-frame step that scrolls the pane
  while the button is down and no float-drag is running — **drag-to-scroll already exists**,
  with a post-release momentum glide, F6).
- **The harness** = `Fizzygum-tests/Automator-and-test-harness-src/` (compiled into the
  harness page). `AutomatorPlayer.startTestPlaying` detaches the world's browser listeners, so
  **the suite exercises event constructors + the hand, never the listeners** (Plan 2's
  reframe 1 — still true, F12). Macros synthesize input ONLY through
  `world.macroToolkit` (`src/macros/MacroToolkit.coffee`, the `macros` part): L1 primitives
  push events, L2 locators/actions compose L1, L3 verb sources compose L2.
- **The reference grammar** = `Fizzygum-tests/tests/SystemTest_<name>/automation-assets/
  <OS>/<OSVer>/<Browser>/<Ver>/SWCanvas/ceilPixRatio_<N>/<img>-automatorV0_3_0-dataHash<h>.*`.
  Run axes (OS, browser, backend, pixel ratio) are DIRECTORY segments; the filename carries
  exactly one knob — the Automator version, meaning "what the harness captures".
  `scripts/lib/refpaths.js` is the ONE parser. **Bumping the version obliges a full
  ~1,898-file recapture — bump ONLY if the harness changes what it captures.**

**Why this plan exists now.** Plan 2 gave every stroke a `pointerType` and a cancel path; Plan
3 landed the touch-capable geometry (44 px targets, indicator scrollbars, 1920×880 test
world); Plan 3.5 stabilized the payload classes finger references would pin. What is still
true today: **a finger cannot open a context menu at all** (the only right-click path is
`e.button is 2 or e.ctrlKey`, F2), a finger drag over detachable content LIFTS it exactly like
a mouse (no way to scroll a list of draggable things by touch), and the virtual keyboard keys
on a session-level `isTouchDevice` that nothing ever sets true (F9). And nothing can TEST any
finger behaviour: the macro boundary bakes `pointerType: 'mouse'` (F10). This plan is the
program's last: when its tail drains, the program doc archives.

**Critical reframes — do not lose these:**
1. **The grammar is a per-stroke branch, not a mode.** G1 forbids per-device state; T11
   (the input-mode toggle) is already deleted. Every decision keys on the STROKE's
   `e.pointerType` / the hand's `@pointerType`, so a hybrid device gets every stroke right and
   `'mouse'` strokes take today's paths byte-identically. `'pen'` takes the mouse grammar
   (hover and a barrel button exist; I2's "lift delay = 0 for a pointer").
2. **Drag-to-scroll already exists — the grammar mostly re-gates it.** `ViewportWdgt`'s
   scroll-drag step scrolls whenever the pressed content does NOT detach
   (`!world.hand.wdgtToGrab?.detachesWhenDragged()`, F6) — a color palette already scrolls by
   mouse drag, and a live TODO at the wheel handler anticipates exactly this plan ("user could
   scroll WITHOUT wheel, by just touch-dragging the contents...", F7). The finger difference
   is ONE gate: over DETACHABLE content, an un-held touch drag scrolls instead of lifting, and
   a HELD one lifts. The hand grows one armed/un-armed state; the two existing consumers
   (`determineGrabs`'s float arms, the viewport step's detach test) read it.
3. **Hold is the dwell machine's sibling, and the dwell is the in-tree precedent for every
   hard part.** Elapsed EVENT-time within `grabDragThreshold` of the press origin (the dwell's
   exact "stationary" notion, F4); decision on event time, never wall clock; state updated per
   move AND per cycle (the hover re-sync already calls into the hand each cycle, F5); a
   wall-clock ANIMATION channel is allowed beside an event-time DECISION
   (`DragChargingRingWdgt`). The one genuinely new question — should the hold FIRE between
   events on a motionless finger — is OD1, with the momentum glide's pacing-suppression as the
   precedent for the recommended answer.
4. **The finger harness changes NO existing capture — that is the bump question, answered.**
   The mouse path through the toolkit stays byte-identical (translation is gated on a run mode
   that defaults off, F10/F13); finger references are NEW FILES on a NEW directory axis
   (§2.7), never rewrites of mouse ones. Therefore **no Automator version bump** — and this is
   not asserted but GATED: `fg presuite` byte-identity closes every phase that touches the
   toolkit or harness.
5. **Witness tests (P2) need no finger mode.** A macro may synthesize touch events directly
   (new L1 touch verbs), exactly as the pointer-cancel tests synthesize cancels — those tests
   are ordinary suite members with ordinary references. The finger MODE (P3) exists for a
   different job: replaying the EXISTING corpus under intent translation, against the new
   reference axis.
6. **The suite currently encodes mouse habits everywhere** — 55 test dirs press the right
   button, 23 use wheel verbs, 98 hover-move before acting (F14). Under finger translation,
   right-click → hold (each costing its non-scaled hold window of real wall-clock), wheel →
   plain drag, and hover pixels simply differ (no pre-hover highlight; a stale pointer-under
   state resolves differently). That is WHY finger runs get their own reference axis (H2), and
   why the finger suite's runtime and storage cost are MEASURED (P0/P3) before the owner
   decides the baseline scope (OD2).

---

## §0.5 Cold-execution protocol

**Who executes (program §3.1):** a **COORDINATOR** (the session model, Fable) delegates every
phase to a **WORKER on a cheaper model** — Opus for phase execution, Sonnet for mechanical
sub-steps — via the `Agent` tool (`subagent_type: general-purpose`, `model: "opus"`/`"sonnet"`;
never `fork`, never `isolation: worktree` — the build hard-codes the sibling layout and the
tests symlink). §9 is the delegation map. The steps below are written for the WORKER; the
coordinator runs step 1, briefs per §9, reads reports, decides at gates, hosts the owner
reviews, and talks to the owner. **The coordinator does not edit source or run suites
itself.**

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — orient (heads, build freshness, test
   count, zombie browsers → `fg killz`). Expect heads at or after the header's.
2. Read this plan in full, then the program doc §2.3 (I1/I2/I3/H1/H2) + §2.2 (G1/G3/G4
   context) + §4 (recapture policy) + §5 (the tail rows T4–T7, T18). Then read, in this
   order: `src/ActivePointerWdgt.coffee` IN FULL (1,337 lines — the file this plan edits
   most), every file in `src/events-input/` whose name starts with `Pointer` (5 files),
   `src/WorldWdgt.coffee` ~:1760–1800 (`_playQueuedEvents`), ~:1900–1915 (the per-cycle hover
   re-sync call), ~:2140–2200 (`_initVirtualKeyboard`), ~:2204–2300 (the pointer listener
   block + `gesturestart`), ~:3380–3420 (the caret/virtual-keyboard seam),
   `src/basic-widgets/ViewportWdgt.coffee` ~:960–1130 (`mouseDownLeft` scroll-drag + the
   glide) and ~:1213–1270 (`wheel`), `src/basic-widgets/SliderWdgt.coffee` :33–130 (the
   indicator presentation), `src/basic-widgets/Widget.coffee` `mouseClickRight` +
   `buildContextMenu` + `buildBaseWidgetClassContextMenu`, `src/PreferencesAndSettings.coffee`
   IN FULL (265 lines), `src/macros/MacroToolkit.coffee` IN FULL (1,280 lines) +
   `src/macros/CLAUDE.md` + `src/macros/MACRO-PATTERNS.md`; then `Fizzygum-tests/DETERMINISM.md`
   (the event-time doctrine — MANDATORY before touching the hand),
   `Fizzygum-tests/CLAUDE.md` (reference grammar, bump discipline, runner/capture tooling),
   `Fizzygum-tests/scripts/lib/refpaths.js`, `Fizzygum-tests/Automator-and-test-harness-src/
   AutomatorLoader.coffee` (`loadImagesOfTest`, the tag/test selection) and
   `WorldTestSupport.coffee` (`_sizeCanvasToTestScreenResolution`, the reset seam), and
   `docs/architecture/lint-and-static-checks.md` (the gate inventory).
3. Execute phases IN ORDER, P0 → P5. Each phase ends with its own gate (§7) and a proposed
   commit. **Owner preference: ask before every commit/push — present a summary and the
   proposed message (`git commit -F <file>`, never backticks in `-m`), then wait.** P2 and P4
   end with OWNER eyes-on before anything is captured for keeps (program §4 rule 2).
4. Long ops (`fg gauntlet`, `fg presuite`, captures, finger suite runs): launch ONCE with the
   Bash tool's `run_in_background` redirected to a log; peek `cat /tmp/fg-<cmd>.verdict` at a
   ~5-min cadence; never pipe the gating call through `| tail`/`| grep`; never edit
   src/tests/fg while a run is in flight.
5. If a fix shape is falsified twice, STOP and re-frame — never a third variant (owner rule).
6. Comments you write state what IS — present tense, no history narration (`check-stinks.js`
   fails the build on it). `undefined` is the one absence value (`nil` is retired and gated).
7. Probes live under `Fizzygum-tests/.scratch/` (gitignored) — NEVER the session scratchpad
   (Node resolves `require` from the script's directory).
8. Anything this plan defers goes into the program doc's tail ledger with a destination
   (program §5) — never a "for later" in this file.

---

## §1 The system as it stands (verified 2026-08-26; re-verify in P0)

Each fact records its verification command. Line numbers drift — grep the quoted code.

- **F1 — the hand's pointer entry points and the dormant carrier.**
  `ActivePointerWdgt.processPointerDown (e)` (:716), `processPointerUp (e)` (:783),
  `processPointerCancel (e)` (:955), `processPointerMove (e)` (:1064); `@pointerType` declared
  `undefined` (:10) and written at down (:717) and move (:1065) — **and read by NOTHING**
  (`grep -n "pointerType" src/ActivePointerWdgt.coffee` → declaration + 2 writes; `grep -rn
  "hand.pointerType" src/` → 0). Plan 2 installed the carrier and branched nowhere; this plan
  is its first consumer.
- **F2 — the ONLY right-click path is button/ctrl.** `processPointerDown`: `if e.button is 2
  or e.ctrlKey` → `@mouseButton = "right"` → `mouseDownRight`/`mouseClickRight` dispatch
  (:760–767); the same test picks the Automator's red indicator (:732). `Widget.mouseClickRight`
  (:398) → `world.hand.openContextMenuAtPointer @` (:404) → `buildContextMenu()` climb →
  `popUpAtHand()` (:148–178). A finger (no second button, no ctrl on a tablet) cannot reach
  it — I2's premise VERIFIED. The world's own menu opens through this exact path on a raw
  right-click over empty desktop (`WorldWdgt.mouseDownRight` is `noOperation` :2511; the CLICK
  climb reaches the world's `buildContextMenu`) — the Plan 3 case law (15 references show that
  menu).
- **F3 — the down/up position heads are in and touch-shaped.** A position-carrying down runs
  the move pipeline first ("for a finger or a pen it is the FIRST event that states one —
  there is no hover to have walked the pointer there", :718–726); ups the same (:784–789).
  Synthetic macro downs/ups are position-less (F10), so the head is skipped for the whole
  suite. Verify: `sed -n '716,730p;783,790p' src/ActivePointerWdgt.coffee`.
- **F4 — the dwell machine is the hold recognizer's template.**
  `updateDragEmbedStateMachine` (:254): "stationary" = within
  `WorldWdgt.preferencesAndSettings.grabDragThreshold` (7, `PreferencesAndSettings.coffee:112`)
  of the linger origin; a farther move RE-ANCHORS; **ARM = elapsed EVENT-time ≥
  `dwellToArmMs` (450, :119), "evaluated at THIS event (incl. the release)"** (:277–280);
  `_reAnchorDragEmbedLinger` stores BOTH an event-time origin (the decision clock) and a
  wall-time origin (the ring animation only, :249–252). Verify: read :249–284.
- **F5 — the hand is re-entered per CYCLE, not only per event.**
  `WorldWdgt.doOneCycle` calls
  `@hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()` (WorldWdgt :1908) →
  `dispatchEventsFollowingMouseMove` (:1293) whose tail runs the dwell machine — its own
  comment: "Runs per move AND per cycle (via the hover re-sync), so a moving drag and a
  stationary hold both update" (:1334–1337). `WorldWdgt.timeOfEventBeingProcessed` is written
  ONLY when an event drains (:1770) — between events it holds the LAST drained event's time.
  So an event-time recognizer advances only when events arrive; the per-cycle re-entry is the
  natural seat for any between-events check (OD1). Verify: grep the quoted comment.
- **F6 — drag-to-scroll EXISTS, gated on "the content does not detach."**
  `ViewportWdgt.mouseDownLeft` (:976; opt-in `isScrollingByfloatDragging: true` :33, only
  `scrollPolicy 'never'` and non-scrolling declines) installs a per-frame `@step` that scrolls
  by the hand's in-plane delta WHILE `world.hand.mouseButton` is down, **gated
  `!world.hand.wdgtToGrab?.detachesWhenDragged()`** ("a float-draggable widget under the hand
  is probably about to be detached, so hold steady instead of scrolling", :1004–1015); a
  cadence-collapse arm recovers a one-cycle gesture (:1042–1057); release seeds a
  POST-RELEASE MOMENTUM glide (friction 0.8, tracked in
  `world.wdgtsWithOngoingScrollMomentum`, **suppressed under
  `Automator.animationsPacingControl`** so screenshots are event-determined, :1078–1106).
  Doc comment: "Float-dragging a Viewport's contents scrolls it (particularly useful on touch
  devices)" (:973–975). Verify: read :973–1106. ⭐ P0 side-finding (2026-08-26, the edge
  detector's plant): pressing a NESTED viewport's background through the real press path
  resolves `grabsToParentWhenDragged`'s `@parent==world` fast-path differently — the press
  climbs and float-drags the ENCLOSING panel instead of scrolling the inner pane, a
  structural reason nested F6 scroll-drags do not arise in committed macros (edge exposure
  measured ZERO at 100% suite coverage).
- **F7 — the wheel path and its live touch TODO.** `ViewportWdgt.wheel` (:1213) scrolls with
  at-edge ESCALATION to an enclosing viewport; a 2010s-era TODO right in it: "this escalation
  should also be implemented in the touch case... user could scroll WITHOUT wheel, by just
  touch-dragging the contents..." (:1229–1230). The scroll-drag step (F6) does NOT escalate
  at the edge today. Verify: read the method.
- **F8 — hover-dependent affordances (T6's inventory), on this tree.** (a) TOOLTIPS:
  `ToolTipWdgt.createInAWhileIfHandStillContainedInWidget` — a **wall-clock `setTimeout`,
  default delay 500** (:48–60; class-level `ongoingTimeouts` registry :11), armed from
  `mouseEnter` on `LabelButtonWdgt:135` / `MenuItemWdgt:256` etc. via `toolTipMessage`
  (`grep -rn "startCountdownForBubbleHelp" src/`); tooltips never appear in references
  (`processPointerDown` runs `world.destroyToolTips()` :728, and macros never linger without
  pressing). (b) INDICATOR FATTENING: `ViewportWdgt`'s "HOVER PASS" (:453–463) fattens the
  overlay scroll indicators while a pointer hovers the scroll band; a thin indicator is
  INTANGIBLE (`SliderWdgt.indicatorIsIntangible` :115 — every state but `'fat'`), so **a
  finger, which never hovers, can never reach a scrollbar at all** — finger scrolling must be
  the F6 drag (I2's answer), not a fattened bar. (c) HOVER HIGHLIGHTS + the pointer-under
  state: `dispatchEventsFollowingMouseMove` diffs `@mouseOverList` and dispatches
  `mouseEnter`/`mouseLeave` (:1293–1310); after a touch stroke the "pointer" would rest where
  the finger LIFTED, leaving stale enter-state (hover highlight pinned on the last-tapped
  widget) — a finger has no between-strokes position (§2.5 resolves this). (d) the hold-menu
  TITLE: `buildBaseWidgetClassContextMenu` ALREADY titles every widget context menu with the
  widget's class name (`title: (@constructor.name.replace "Wdgt", "") …`, Widget.coffee
  :4605–4607) — T6's "the hold-menu's title can name the widget" is largely a VERIFICATION plus
  wording, not new mechanism.
- **F9 — T7's premise verified: the virtual keyboard is DEAD code keyed on a lie.**
  `WorldWdgt.edit` (the caret-creation seam) summons the DOM input iff
  `preferencesAndSettings.isTouchDevice and preferencesAndSettings.useVirtualKeyboard`
  (:3398); `_initVirtualKeyboard` bails on the same test (:2150). `isTouchDevice` is declared
  (:109), set `false` with the comment "turned on by touch events, don't set" (:240) — **and
  nothing anywhere sets it true** (`grep -rn "isTouchDevice" src/` → 2 reads + 1 false
  write + declaration). `useVirtualKeyboard` is `true` (:239). The sibling
  `useSliderForInput` (:238, false) has live readers (`Widget.coffee:4402`,
  `NumberPromptWdgt`) and is NOT this plan's business.
- **F10 — the macro boundary bakes 'mouse'.** `PointerInputEvent.synthetic (button, buttons,
  ctrlKey, shiftKey, altKey, metaKey, time, worldX, worldY)` bakes `pointerType: 'mouse'`,
  `pointerId: 1`, `isPrimary: true`, `pressure: 0` (read the static in
  `src/events-input/PointerInputEvent.coffee`; Plan 2 called Plan 4's use "a refinement, not a
  re-plumb"). Toolkit construction sites: moves :332/:375 (position-carrying), click pair
  :402–403 (non-scaled), down :419 / up :432, cancel :442, wheel :562 — the whole fan-in, all
  through the ONE chokepoint `queueInputEvent` (:124, spanFactor rescale). Non-scaled guard
  constants beside them: `@clickGuardWindowMs: 350`, `@dragFloorMs: 300`,
  `@clickHoldFloorMs: 100` — **the precedent for a non-scaled hold window** (a hold's span,
  like a click-guard's, is a RECOGNITION window the speed lever must not compress). Verify:
  `grep -n "Pointer.*InputEvent.synthetic\|clickGuardWindowMs\|dragFloorMs" src/macros/MacroToolkit.coffee`.
- **F11 — the L1/L2/L3 layering is the translation seam.** L1 `syntheticEvents…_InputEvents`
  primitives push events; L2 locators compose L1; L3 `standardMacroSubroutines()` returns
  generator SOURCE strings (:1067–1268). Committed macros call the VERB NAMES (they stay
  mouse-flavoured — Plan 2 §2.6's decision, re-affirmed §8): per-kind translation lands in
  the L1/L2 BODIES, keyed on the run's pointer mode, so 300+ macro sources are untouched.
  Verify: read MacroToolkit :1–20 (the layer doc) + `src/macros/CLAUDE.md`.
- **F12 — the suite never sees the browser listeners.**
  `AutomatorPlayer.coffee:772` — `world.removeEventListeners()` at test start (re-armed at
  test end). So the grammar + harness work is invisible to the listener layer, and the
  listener layer needs its own (smoke/probe) proof for the touch kind — H1's "booting is not
  exercising". Plan 2's P0 probe already proved dispatched `PointerEvent {pointerType:
  'touch'}` DELIVERY + field fidelity in BOTH engines, and noted for THIS plan: **trusted
  WebKit finger taps need a `hasTouch: true` context** — irrelevant to the queue-synthesized
  suite, relevant only if a probe drives trusted touch input
  (`grep -n "hasTouch" Fizzygum-tests/scripts/lib/headless-driver.js` → 0 today).
- **F13 — the run-mode plumbing pattern the finger mode copies.** Boot query params:
  `?dpr=N` → `window.FIZZYGUM_FORCE_PIXEL_RATIO` (globalFunctions :288), `?speed=` →
  `window.FIZZYGUM_MACRO_SPEED` (:302, read lazily by `MacroToolkit.currentSpeed`).
  Runner flags: `run-all-headless.js` `KNOWN_FLAGS = ['--browser','--shards','--dpr',
  '--speed', …]` (:66) composing the harness URL (:151); same shape in
  `run-macro-test-headless.js` / `capture-macro-test-references.js` / `recapture.js`.
  A `?pointer=finger` param + `--pointer=` flag is a mechanical rhyme. Verify: the greps
  above.
- **F14 — the corpus's gesture exposure (ballpark; P0 measures precisely).** Right-button
  gestures appear in **55** `_automationCommands.js` dirs, wheel verbs in **23**, plain
  move verbs in **98** (`grep -rl "right button" --include="*_automationCommands.js"
  Fizzygum-tests/tests | wc -l`, etc.). Suite 321 tests / 1,898 reference PNGs at
  Automator 0.3.0 (`ls tests | grep -c ^SystemTest_`; `find tests -name "*-dataHash*.png" |
  wc -l`; `SystemTestsSystemInfo.coffee:22–24`). ⭐ MEASURED at P0 (2026-08-26,
  `.scratch/gesture-count.py` over the full L1/L2/L3 right-button roster): right-button
  gesture INVOCATIONS = **194 across 108 tests** (max 9 in one test) — the 55-dir literal
  grep misses 53 tests that reach a right-click only through `openMenuOf_InputEvents`/L3
  wrappers that never spell "right button" (the census-axis lesson); wheel = 47 occurrences
  across 23 tests; plain-move tests = 98. Finger-translation hold cost at a non-scaled
  500+100 ms window: **≈116 s suite-wide, worst single test +5.4 s** — the known-tolerable
  cost class.
- **F15 — the reference machinery a new axis touches.** `refpaths.js` — `parseRefName`
  (filename grammar), `dprFromPath` (finds the `ceilPixRatio_<N>` SEGMENT anywhere in the
  path), `currentAutomatorVersion` (reads the harness source); `check-refs.js` groups by
  DIRECTORY ("the directory IS the OS/browser/backend/pixel-ratio axis", :41–44) — a new
  segment forms new groups with no code change to the duplicate gate;
  `AutomatorLoader.loadImagesOfTest` matches assets by OS + `"/ceilPixRatio_<N>/"` marker +
  `/SWCanvas/` (:56–64) — **it must additionally EXCLUDE the finger segment in mouse runs
  and REQUIRE it in finger runs**, or a wrong-pixel run could pass against the other kind's
  reference (`compareScreenshots` passes on ANY loaded candidate — the check-refs header
  states this hazard); `generate-tests-manifests.js` walks the tree (regenerated at every
  runner start — a new segment is picked up structurally); `make-visualisation.js` prefers
  SWCanvas dpr-1 refs (must EXCLUDE finger refs to keep committed pages stable);
  `SWCanvasBrokenTests` is the per-density skip-list precedent;
  `AutomatorLoader.selectTestsFromTagsOrTestNames` is the tag-selection mechanism.
- **F16 — the harness canvas is a constant, and the ratchet knows it.**
  `WorldTestSupport._sizeCanvasToTestScreenResolution` hard-codes 1920×880 × ceilPixelRatio
  (:127–133); the reference grammar's no-environment-facts law leans on that constancy, and
  the page-scoped `WORLD_CONSTRUCTION_DRIFT` ratchet fingerprints the first reconstructed
  world — **a per-test tablet extent (H2) must prove it does not trip the ratchet or fork
  the grammar's premise** (P0 probe C; §2.8). ⭐ MEASURED at P0 (2026-08-26, probe C green):
  the seam takes a mid-page 1024×768 excursion with ZERO gate tokens (no
  `WORLD_CONSTRUCTION_DRIFT`, no `WORLD_INVENTORY_*`), no residue (the 1920×880 test passes
  again after), and indifferent manifest/selection machinery — the ratchet is blind to extent
  BY CONSTRUCTION (`_summariseWorldStateValueNoSettle` reduces `bounds` to
  `"object:Rectangle"`, so no geometry field enters the fingerprint). OD5's clean branch:
  the tablet-extent set lands per §2.7, no owner decision needed. ⚠ The loader still OFFERS
  wrong-extent candidates (matching is by `dataHash` — a wrong-extent reference FAILS rather
  than being filtered), so extent-declaring tests rely on their own references existing.
- **F17 — the four stale-open tail rows are CLOSED on this tree** (the header's verification):
  T9 — `sed -n '32,36p' src/PromptWdgt.coffee` (the comment names the one consumer);
  T10 — `grep -c tight src/FrameWdgt.coffee` → 0;
  T14 — `sed -n '366,369p' src/FrameBarWdgt.coffee` (`_fullDestroyNoSettle`) + the witness
  test dir `SystemTest_macroRetiredBarPieceTakesItsFaceWithIt` exists;
  T15 — `grep -n closeFromFrameBar buildSystem/public-api-allowlist.txt` (entry + reason).
- **F18 — cancel/cleanup building blocks the grammar reuses.** `_forgetPressBookkeeping`
  (:79 — press bookkeeping shared by teardown + cancel), `cleanupMenuWdgts (clickedWdgt,
  opts)` (:978 — the dismissal sweep; down-path passes `alsoKillFreshMenus: true` :757),
  `world.freshlyCreatedPopUps.clear()` at up (:800), the dismissal guard
  `!(w.enclosingFrame()?.isMenu?())` (:756). Two cancel witness tests exist
  (`SystemTest_macroPointerCancelAbortsDragWithoutClick`, `…EndsNonFloatDrag`).
- **F19 — gates this plan meets** (index: `docs/architecture/lint-and-static-checks.md`):
  `check-coffee-syntax` (new/edited `.coffee`), `check-dead-methods` +
  `check-unresolved-sends` (the `isTouchDevice` retirement; any renamed helper),
  `check-argument-holes` (new verb signatures — no `undefined` filler),
  `check-raw-pointer-reads` (hand edits keep consuming mapped positions), `check-stinks`
  (present tense; `nil-literal`), `check-call-separation` [U], `NON_INTEGER_GEOMETRY` (any
  new geometry rounds), tests-repo `check-tests-syntax` + `check-macro-source-discipline`
  (new macros: no `world.evaluateString`, "Macro" only trailing) + `check-refs` +
  `check-visualisations` (new tests regenerate pages). Runtime twins: `fg menusweep` (the
  hold path opens menus), `fg vmtruth` (hold state must not pin widgets), the suite itself.
- **F20 (added at P0, 2026-08-26 — probe-adjacent) — `WorldWdgt.dateOfCurrentCycleStart` is
  cleared to `undefined` at the tail of every cycle** (WorldWdgt.coffee :1958–1959), so it
  reads `undefined` from any `page.evaluate` between cycles: anything driving the queue from
  OUTSIDE a cycle (probes, page-side tooling) must base its event times on `Date.now()`.
  Inside the drain, `timeOfEventBeingProcessed` remains the clock (F5).
- **F21 (added at P0, 2026-08-26 — probe-adjacent) —
  `AutomatorLoader.selectTestsFromTagsOrTestNames` is ASYNC and its `andThen` callback is the
  only honest wait**: polling `selectedTestsBasedOnTags.length` observes the PREVIOUS
  selection and runs the wrong test's commands (the loader's own comment states this; a P0
  probe draft reproduced it). Any P3/P4 runner or probe that drives selection waits on the
  callback, never on the array.

### 1.3 Why it is shaped this way

The input stack is one generation newer than the gesture set riding it. Morphic's grammar was
mouse-only (drag lifts, wheel scrolls, right button for menus); touch arrived as an emulation
layer that mapped one finger onto that mouse (deleted by Plan 2), so no touch-specific meaning
ever existed — a finger IS a buttonless mouse today. Meanwhile the pieces a real grammar needs
grew independently and are all in the tree already: per-stroke kind (Plan 2), a
stationary-hold recognizer with event-time discipline (the drag-embed dwell), drag-to-scroll
with a momentum glide (the viewport), a titled context menu on every widget (the framed
citizens), and 44 px targets (Plan 3). What is missing is only the BRANCH — and the finger to
test it with, which is missing for the same historical reason: the Automator was born
replaying recorded mouse events, and macros inherited the mouse vocabulary. This plan adds the
branch and teaches the harness the second kind; it deletes almost nothing because Plans 1–3.5
already deleted the per-device machinery (T11) this grammar replaces.

---

## §2 The mechanism this plan installs (target design)

### 2.1 The stroke model: one recognizer, one armed state

The hand gains a per-stroke **press-and-hold recognizer**, built exactly on the dwell
machine's pattern (F4):

- **State** (all cleared by `_forgetPressBookkeeping`'s callers and on cancel): the press
  origin point + press origin EVENT time (recorded at `processPointerDown`), and one derived
  boolean the grammar consumers read — call it the stroke's **mouse-semantics arming**:
  - `pointerType 'mouse'` or `'pen'` ⇒ armed AT THE DOWN (lift delay 0 — I2; today's
    behaviour byte-identical).
  - `pointerType 'touch'` ⇒ armed when elapsed EVENT-time since the press origin ≥
    **`pressAndHoldMs`** (a new named preference, proposed **500** — beside `dwellToArmMs`,
    same doc-comment discipline; the value is owner-re-turnable at P2's eyes-on, OD3) while
    the pointer has stayed within `grabDragThreshold` of the origin (the dwell's one notion
    of "stationary"). A pre-arm move beyond the threshold does NOT re-anchor (unlike the
    dwell): it commits the stroke as a PLAIN DRAG — scroll — for its remaining life (a
    finger that started scrolling must not accidentally arm mid-flick).
  - a touch press on **chrome** ⇒ armed AT THE DOWN (I2: "chrome drags need no hold on
    either device") — §2.3 defines chrome by capability, not by class list.
- **The decision clock is EVENT time**, evaluated at each drained event AND at the per-cycle
  re-entry the hand already has (F5) — never `Date.now()`/`setTimeout` (F4's law;
  DETERMINISM.md). Whether the between-events per-cycle check may consult the cycle clock on
  a motionless real finger is **OD1** (§2.9); under the Automator the macro verbs schedule
  event streams that CROSS the window non-scaled (F10's `clickGuardWindowMs` precedent), so
  the harness path is event-determined under every ruling of OD1.
- **Arming fires at most once per stroke**, and its firing has exactly two effects (§2.2):
  on a stationary touch press, the ARM ITSELF opens the context menu (hold-as-right-click);
  and from the arm on, the stroke's drags mean what a mouse's would.

### 2.2 The grammar, stated as the table the code implements

| gesture | `'mouse'` / `'pen'` (unchanged) | `'touch'` |
|---|---|---|
| tap (down+up, no threshold move) | click (down dispatch, up dispatch, multi-click recognition) | the SAME — a tap is a click (the down carries its position, F3; no prior hover exists) |
| plain drag over content whose drag a scroll surface claims | float-drag lifts detachable content; scroll-drag scrolls non-detachable content (F6, today) | **scroll** — the F6 scroll-drag runs regardless of detachability while the stroke is un-armed; at-edge behaviour gains the wheel's escalation (F7's TODO, discharged) |
| plain drag elsewhere (no claiming scroll surface — e.g. the desktop) | float-drag / non-float drag (today) | the SAME as mouse — nothing competes for the drag, so no hold is demanded (I2: hold is required ONLY where a plain drag already means scroll) |
| drag starting on chrome (bar, grip, handle, slider, fat scrollbar) | chrome's own drag (today) | the SAME — armed at the down (§2.3's capability) |
| stationary hold | nothing (dwell applies only mid-float-drag) | at `pressAndHoldMs`: **the context menu opens at the press point** — the exact `mouseClickRight` consequence (`openContextMenuAtPointer` on the press target, F2), titled with the widget's name (F8d). The press stays live. |
| hold, then move (> threshold) | n/a | **the lift**: the just-opened hold menu is dismissed (the F18 sweep, `alsoKillFreshMenus: true`) and the stroke's drag proceeds with MOUSE semantics — detachable content lifts (float-drag, the dwell-to-embed machine downstream unchanged), text extends selection (its `mouseMove` selection path, gated by the same arming — the THIRD consumer, §2.3; AMENDED 2026-08-26 at P1: "falls out of the same arming" was FALSE as authored, the dispatch was unconditional), a value control value-drags |
| release after hold, no move | n/a | the menu STAYS (it is an ordinary transient menu now — the next outside tap dismisses it; C8/pin rules untouched). **No click is dispatched** for the hold stroke's up — the hold consumed the stroke (the right-click precedent: a right press never fires `mouseClickLeft`). |
| wheel | scrolls (untouched) | n/a (no wheel exists; the plain drag IS the scroll) |
| `pointercancel` | the Plan 2 abort (untouched) | the same abort; additionally clears the hold state and any hold-opened menu stays (a cancel is not a click — Plan 2 §2.4's law extends unchanged) |

Ruled OUT by I3 and not re-derived: axis-locking, scroll-by-background, two-finger-scroll.

### 2.3 Where the branch lives — the two consumers and the chrome question

- **`determineGrabs` (:1129)** — the float arms (template copy, `detachesWhenDragged`) run
  only when the stroke is ARMED. The non-float arm (sliders/handles — chrome by construction)
  is untouched: reaching it means the press target neither detached nor templated, and a
  touch press on such a target arms at the down (chrome).
- **The press-move channel (the THIRD consumer — ADDED 2026-08-26 at P1, measured):** the
  hand's pressed-move `mouseMove` dispatch is unconditional at TWO sites
  (`determineGrabs`' `topWdgt.mouseMove`, and the over-list `mouseMove` in
  `dispatchEventsFollowingMouseMove`, which passes `@mouseButton`), and its consumers
  include text selection (`StringWdgt.mouseMove`) and the paint-tool handlers — so §2.2 row
  6's authored claim that selection "falls out of the same arming" was FALSE: an un-armed
  touch drag over text would BOTH scroll and extend selection. RULING (coordinator, from
  I2's letter): an un-armed touch stroke's press-moves mean SCROLL and nothing else — the
  pressed-move dispatch is gated on the stroke's arming; mouse/pen byte-identical by
  `strokeMeansMouseDrag()`'s short-circuit, and hover (no-button) moves are untouched.
- **`ViewportWdgt`'s scroll-drag step (F6)** — its detach gate widens by the stroke's kind:
  an un-armed TOUCH stroke scrolls even over detachable content (the mouse reading of the
  same gate is byte-identical). The step already handles cadence collapse and the glide;
  at-edge ESCALATION is added to the step's delta application, mirroring `wheel`'s at-edge
  test (F7) — mouse scroll-drags gain it too, which is invisible to the suite (P0 confirms:
  no committed macro scroll-drags a nested-viewport pane to its edge; if one does, that test
  joins P2's declared set — stop rule otherwise).
- **Chrome, asked as a capability.** The hand asks the press target's ancestry ONE derived
  question — "does a chrome surface own this press?" — answered `true` by the frame bar
  (`FrameBarWdgt`, which already declares `ownsDragsOfMyChildren` :87), the handle family,
  sliders/scrollbars (including the `'fat'` indicator presentation — a THIN one is intangible
  and can't be pressed at all, F8b), and the resizer. Dispatched `?()` with nothing on
  `Widget` (the house capability idiom); the EXACT member name and the definer list are the
  P1 worker's to derive against `layering-naming-convention.md`, with the candidates above as
  the starting set and the stop rule if the shape falsifies twice.
- **The scroll-surface question is the OTHER capability**: "would a plain drag here be
  claimed by a scroll surface?" — true iff an ancestor viewport would install the F6 step for
  this press (scrolling policy, `isScrollingByfloatDragging`, actual overflow). Where it is
  false (the desktop), a touch drag needs no hold (§2.2 row 3). The viewport can answer from
  what it already knows; the hand asks at the down and caches per stroke.

### 2.4 T6 resolved — hover's four faces, each with its touch story

1. **Widget identity on touch = the hold menu's TITLE.** Already true mechanically (F8d):
   every widget context menu is titled with the class-derived name. The phase work is a
   VERIFICATION (the hold path reaches the same titled menu) + a wording check (the title is
   the colloquial name a user reads — if any hold-reachable menu is untitled, fix it as part
   of P1). This is the program's own scope sentence for T6.
2. **Tooltips** — declared OUT for touch: they are wall-clock mouseEnter affordances (F8a)
   and their information duty on touch is discharged by (1). No code change; the declaration
   lands in the architecture docs at P5.
3. **Indicator fattening** — declared OUT for touch: a finger never hovers, so it never sees
   a `'fat'` bar; finger scrolling is the plain drag (§2.2), which is strictly more capable.
   No code change.
4. **The pointer-under state** — RESOLVED by dissolution: at a TOUCH stroke's up (and
   cancel), the hand dispatches `mouseLeave` to the whole `mouseOverList` and empties it —
   the finger left the glass; no widget may keep a hover highlight, no tooltip countdown may
   survive (`world.destroyToolTips()` already runs at down/up). Mouse strokes keep today's
   persistent pointer-under state byte-identically. (This is also what makes finger runs'
   pixels differ from mouse runs' — the H2 axis's raison d'être.)
   ⚠ AMENDED 2026-08-26 at P2 (measured: a touch tap's committed reference grew a TOOLTIP —
   the sweep alone is UNDONE one cycle later, because the hand stays parked at the tapped
   point and the per-cycle hover re-sync re-enters whatever is under it): the mechanism is
   the sweep PLUS a between-strokes **pointer-absence state** — set at a touch stroke's up
   and cancel (after the dissolution), cleared by the next `processPointerDown` of any kind
   (the down states a position: the pointer is back) and by any hover-capable move (a
   mouse/pen move — a real pointer returned). While absent, the per-cycle re-sync and the
   move pipeline dispatch NO enters/moves and the over-list stays empty: nothing is under a
   pointer that is not there. Mouse strokes never set it — byte-identical. §2.4(2)'s
   "tooltips: no code change" stands: the tooltip machinery is untouched; absence starves it
   of the spurious enter.

### 2.5 T7 resolved — the virtual keyboard keys on the STARTING tap

`WorldWdgt.edit`'s summon test (F9) becomes: the stroke that started this edit was a touch
stroke — `world.hand.pointerType is 'touch'` at the caret-creation seam — AND
`useVirtualKeyboard` (the surviving opt-out dial, default true). `_initVirtualKeyboard`'s
early-out (:2150) keys the same way. **`isTouchDevice` is RETIRED** (declaration, the false
write, both reads — nothing else exists, F9); `check-dead-methods`/`check-unresolved-sends`
police the residue. Inert for the suite (macros are mouse strokes); exercised by a P2 witness
(a touch tap into a text field summons the element; a mouse click does not) — the witness
asserts presence/absence of the DOM element, never pixels (it is transparent and outside the
canvas).

### 2.6 The finger harness — H1's proof obligation

The finger IS the product's touch path (H1): the L1 touch verbs construct
`Pointer*InputEvent`s with `pointerType: 'touch'` — the same classes, the same queue, the
same drain. Concretely:

- **`PointerInputEvent.synthetic` grows a trailing optional pointer-kind argument** (or a
  sibling `@syntheticTouch` factory — the P1 worker picks whichever the `check-argument-holes`
  gate and the family's positional convention prefer; the family's own convention says a hole
  means REORDER). Touch events bake `pointerId: 1, isPrimary: true, pressure: 0.5-ish
  deterministic constants` — refined, not re-plumbed (F10).
- **New L1 verbs** (names final at execution, discipline-gated): a touch tap (position-
  carrying down + up — NO hover move precedes, reframe 6), a touch hold (down + a
  non-scaled window-crossing same-position move + optional up — the `clickGuardWindowMs`
  non-scaled idiom, F10), a touch drag (down + move stream + up, `dragFloorMs` floored), a
  touch hold-then-drag (the hold prefix + the drag). Each pushes through `queueInputEvent`.
- **The listener-path proof** (H1's letter, F12): a probe/smoke assertion that a DISPATCHED
  browser `PointerEvent {pointerType:'touch'}` at the canvas reaches the hand as the same
  `PointerInputEvent` — Plan 2's delivery probe extended one assertion (the hand's
  `@pointerType` reads `'touch'` after the dispatch). Rides `smoke-boot-headless.js` or a
  `.scratch` probe per the P0 worker's judgement; the suite path needs no `hasTouch` context
  (queue-synthesized), noted for any future trusted-input probe.

### 2.7 The finger harness — H2's mode, translation, and reference axis

- **The run mode**: `?pointer=finger` boot param → `window.FIZZYGUM_POINTER_KIND` (default
  `'mouse'`), the F13 pattern; `--pointer=finger` on `run-all-headless.js`,
  `run-macro-test-headless.js`, `capture-macro-test-references.js` (and `recapture.js` left
  mouse-only — finger references are captured, never re-captured, until they exist). The
  toolkit reads it lazily (the `currentSpeed` idiom).
- **The intent translation lives in the L1/L2 BODIES** (F11; verb NAMES untouched — §8):
  under finger mode, `syntheticEventsMouseClick_InputEvents` emits a touch tap;
  `…"right button"…` down/up emit a touch HOLD (the grammar's right-click); the
  press-drag-release family emits hold-then-drag (the macro's intent is MOVE — it pressed a
  thing to relocate it) except where the L2 caller states scroll intent; the wheel verb
  emits a plain touch drag on the pane under the pointer (scroll intent by name); plain
  move verbs emit nothing before a tap (no hover) and a touch drag mid-gesture. The exact
  per-verb table is enumerated by the P3 worker from the toolkit's verb roster and recorded
  in the STATUS box — the design rule is one line: **the verb's NAME states the intent; the
  translation preserves intent, never the raw events.**
- **The reference axis is a DIRECTORY segment**, like every run axis (H2's "like `dpr`" —
  and the grammar's own law: environment facts and run axes are directory axes, the filename
  carries only the version): finger references live under
  `…/SWCanvas/ceilPixRatio_<N>/finger/` — BELOW the dpr segment so `dprFromPath` keeps
  working unchanged (F15), absence = mouse (the `[SWCanvas/]` optional-segment precedent).
  Touched: `refpaths.js` (the ONE parser learns the segment), `AutomatorLoader.loadImagesOfTest`
  (REQUIRE the segment in finger runs, EXCLUDE it in mouse runs — the F15 cross-match
  hazard), the capture writers, `make-visualisation.js` (exclude finger — committed pages
  stay stable), manifests (regenerated structurally). Existing mouse references DO NOT MOVE
  — **no Automator bump** (reframe 4).
- **Mouse-only-by-meaning is declared PER TEST, with a reason**: a metadata field (e.g.
  `pointerKinds: ["mouse"]` + a `mouseOnlyReason` string — the allowlist-with-reasons
  idiom) in `SystemTest_<name>.js`; the loader filters it in finger mode the way
  `SWCanvasBrokenTests` filters per density (F15). An UNdeclared test that cannot replay
  under finger is a finding, not a skip.
- **The `finger` gauntlet leg** = the suite under `--pointer=finger --browser=webkit
  --dpr=2` (H2's "for this suite's purposes, an iPad" — WebKit engine, HiDPI, finger), added
  to `fg`'s gauntlet roster by the COORDINATOR (fg is umbrella-local, uncommitted tooling;
  the menusweep/pinsweep legs are the precedent). References for it are captured on Chrome
  (capture stays chrome-only) and reused by WebKit, exactly as the mouse refs are.
- **Tablet-extent tests** (H2): a per-test extent DECLARATION in the test metadata, honoured
  by the reset seam (`_sizeCanvasToTestScreenResolution` reads the declared extent, default
  1920×880) — the extent is the TEST's fact, never the display's, so the grammar's
  no-environment-facts law holds. A small named set (2–3 finger-only tests at 1024×768:
  the world menu reachable, a docked toolbar + chevron, a window drag). ⚠ Gated on P0 probe
  C (F16): the page-scoped construction ratchet and the shard model must accept a mid-page
  extent change — if they resist, OD5 routes the item.

### 2.8 Disposition table — every current member this plan touches

| today | fate |
|---|---|
| `ActivePointerWdgt.@pointerType` (written, never read) | the grammar's key — read by the arming, §2.1 (its first consumer) |
| `processPointerDown` | + press-origin recording; + hold-arming init (mouse/pen/chrome arm at the down); mouse path byte-identical |
| `processPointerMove` / the per-cycle re-sync (F5) | + hold-recognizer advance (event-time; OD1 decides the between-events check); + the §2.4(4) touch hover dissolution rides the up, not here |
| `processPointerUp` | + touch: suppress click dispatch for a hold-consumed stroke; + dispatch `mouseLeave` sweep & clear `mouseOverList` for touch strokes; mouse path byte-identical |
| `processPointerCancel` | + clears hold state (the F18 shared clear grows one line) |
| `determineGrabs` float arms | gated on the stroke's arming (mouse: always armed ⇒ byte-identical) |
| `ViewportWdgt` scroll-drag step (F6) | detach gate widened for un-armed touch strokes; + at-edge escalation (F7's TODO discharged) |
| `ViewportWdgt.wheel` | untouched (the TODO comment retires with the escalation's arrival in the step) |
| `openContextMenuAtPointer` | untouched — the hold FIRES it (F2's path, reused verbatim) |
| `PreferencesAndSettings` | + `pressAndHoldMs` (proposed 500, OD3); − `isTouchDevice` (F9); `useVirtualKeyboard`/`useSliderForInput` untouched |
| `WorldWdgt.edit` + `_initVirtualKeyboard` | keyed on the starting tap's kind (§2.5) |
| `PointerInputEvent.synthetic` | grows the pointer-kind refinement (§2.6) |
| `MacroToolkit` | + L1 touch verbs (§2.6); L1/L2 bodies translate under finger mode (§2.7); verb names + committed macros untouched |
| `refpaths.js` / loader / capture / visualisation / manifests | the finger directory segment (§2.7) |
| `run-all-headless.js` + single-test runner + capture scripts | `--pointer=` flag (F13 pattern) |
| `WorldTestSupport._sizeCanvasToTestScreenResolution` | reads a per-test extent declaration, default unchanged (§2.7, gated on P0 probe C) |
| `fg` gauntlet roster (umbrella-local) | + the `finger` leg (coordinator's edit) |
| the Safari `gesturestart/gesturechange` no-op listeners | UNTOUCHED (T4's, BACKLOG) |
| the widget-facing dispatch names (`mouseDownLeft`…) and L1 verb names | UNTOUCHED (§8) |

### 2.9 Owner decisions this plan carries (each an OPTION set, decided at the named gate)

- **OD1 (P1 brief-time): the hold-fire clock on a motionless real finger.** The DECISION is
  event-time in every option; the question is whether anything checks between events.
  (a) event-time only: the hold fires at the first drained event whose time crosses the
  window (real fingers tremble under `touch-action: none`, so in practice it fires ~on
  time; a robotically still finger sees the menu at its next micro-move or at the up).
  Zero new clock discipline. (b — **recommended**) (a) PLUS a per-cycle check at the F5
  re-entry that may consult the cycle clock, SUPPRESSED under
  `Automator.animationsPacingControl` — the momentum glide's exact, sanctioned idiom (F6):
  real-device responsiveness is sharp, the harness path stays event-determined, and the
  suppressed path is accepted-untested exactly as the glide's is. (c) a wall-clock timer —
  ⛔ not an option (F4's law; listed to say so).
- **OD2 (P4 gate, with P0/P3's measured numbers in hand): the finger baseline's scope.**
  (a — **recommended**) the full non-mouse-only suite at dpr 1+2 — H2's letter; the finger
  leg then means what the mouse suite means; cost = the P3-measured capture wall-clock
  (Plan 3's full recapture ran 5h30m for 290 tests × 2 dprs; comparable order here) + an
  estimated up-to-~80% growth of `tests/` (from 184 MB; measured precisely in P3).
  (b) a curated grammar-relevant subset + the finger-only tests — cheaper, but "most
  existing macros replay under the finger" (H2) is then unmeasured forever after.
  (c) dpr2-only finger references (halves both costs; the leg is dpr2 — but no dpr1 finger
  inner loop exists thereafter). The owner rules on numbers, not estimates.
  ⚠ AMENDED at P0 (2026-08-26, measured): (c) halves CAPTURE wall-clock only — it does NOT
  halve storage, because dpr2 already carries 88% of committed reference bytes (a dpr2 file
  averages ~7× a dpr1 file, and each PNG pairs with a base64 `.js` loader; the committed
  reference footprint is 168.8 MB = 91% of tests/). Measured projections: (a) +168.8 MB
  (+91% of tests/), (b) ≈40 tests +21 MB (+11%), (c) +148.5 MB (+80%).
- **OD3 (P2 eyes-on): the hold dial.** `pressAndHoldMs` proposed **500** (iOS long-press
  convention); the owner feels it on the dev build at the P2 witness review and may re-turn
  (a pure-constant re-turn; the witness tests' references are captured after the ruling).
- **OD4 (P5): T18 — halo crowding at touch scale: absorb or BACKLOG.** The program requires
  this decided here, explicitly. (a — **recommended**) BACKLOG, paired with the
  owner-pending G2 halo feel-check (they are one conversation: how the halo should FEEL at
  44 px): this plan's gesture work does not restructure the halo — handles are chrome
  (§2.3), exempt from hold, and the Plan 3 z-order interim fix stands — while the T18 design
  question (fewer handles below a size floor? edge zones? a halo mode?) deserves its own
  owner-led design pass, not a rider on the program's last arc. (b) absorb a minimal
  size-floor rule (below ~2·handleSize show only resize + rotate) — small, but it PRE-EMPTS
  the G2 feel-check with a mechanical rule the owner has not felt. (c) absorb the full
  redesign — re-opens the program's scope at its close. A BACKLOG ruling writes the row with
  the G2 pairing and the evidence; an absorb ruling adds a phase to this plan before P5
  closes.
- **OD5 (P0 gate, conditional): tablet-extent tests.** If probe C (F16) shows the reset
  seam takes a per-test extent cleanly: land the small set (§2.7) — no decision needed. If
  it shows structural resistance (the construction ratchet, shard pages): (a — recommended)
  BACKLOG the tablet-extent tests with the measured evidence (the grammar and finger axis
  do not depend on them); (b) isolate them on their own shard/page (runner work, priced by
  the probe). The coordinator takes the probe result to the owner only in the resistance
  case.

---

## §3 The axes (why this shape)

- **Grammar first, witnesses second, harness third, baseline last.** The grammar (P1) is
  mouse-inert and provable byte-identical by the whole suite. Its witnesses (P2) are ordinary
  new tests — no new machinery. The finger mode (P3) is harness-only and mouse-inert by the
  same gate. The baseline (P4) is the one bulk artifact, taken only after the owner has seen
  the grammar work (P2) and the measured costs (OD2). Each cut point leaves a shippable,
  self-justifying tree (program §1's rule).
- **One armed state beats per-surface flags.** The alternatives — a per-widget "needs hold"
  marker, or per-gesture type tests in the viewport — scatter the grammar across consumers
  and re-grow the type-test weed. One stroke-scoped state, two readers (§2.3), keyed on the
  event's own kind, is the smallest thing that expresses I2 exactly.
- **The hold reuses the right-click CONSEQUENCE, not a parallel path.** Firing
  `openContextMenuAtPointer` (F2's exact method) means every context-menu behaviour —
  titles, dev-mode disambiguation, the world menu, menusweep's coverage — is inherited, not
  reimplemented. The hold is an alternate TRIGGER for an existing verb.
- **The translation lives under the verb names.** Renaming L1 verbs or macro sources to a
  pointer-neutral vocabulary would churn 300+ committed files to express nothing the mode
  key doesn't (Plan 2 §2.6 decided this once; H2's design confirms the verbs ARE the intent
  layer). The names stay; the bodies branch.
- **A directory axis, because that is what the grammar says an axis is.** The filename
  carries the one knob meaning "the harness changed what it captures"; a finger run is a run
  axis like dpr, and mouse references not moving is what makes the no-bump answer structural
  rather than argued.

---

## §4 The distilled argument

Every ingredient of a touch grammar already exists in this tree — per-stroke kind, an
event-time stationary-hold recognizer, drag-to-scroll with momentum, a titled context menu on
every widget, 44 px targets — and each was landed by an earlier arc of this same program with
the suite pinned byte-identical throughout. What remains is one branch (the arming), two gate
edits (the grab arms, the scroll-drag's detach test), one alternate trigger (hold →
the existing right-click consequence), and one retirement (`isTouchDevice`) — all inert for
the mouse, so the 321-test suite certifies the whole product surface unchanged while the new
behaviour gets its own witnesses. The harness half is the same story one level up: the
toolkit already funnels every synthetic event through one chokepoint and every intent through
named verbs, so a finger is a mode key and a translation table, and the reference grammar
already knows how to grow an axis without moving a file. The program sequenced four arcs so
that its last one would be exactly this small; closing it empties the tail ledger and closes
the program.

---

## §5 Phases

Each phase: goal · steps · pixel impact · gate · commit. **Recapture budget: ZERO existing
references change in ANY phase** (program §4 rule 1 — the grammar and harness are
mouse-inert; a diff on any existing reference at any gate is a STOP, worker rule 3, never a
recapture). New reference files: P2's witness tests' own captures; P4's finger-axis captures
(new files on a new axis, not recaptures). **No Automator version bump anywhere** (reframe 4;
`check-refs` enforces version-vs-harness agreement either way).

### P0 — Re-verification, probes, measurements (~½ session-day)

1. `fg status`; a green gauntlet baseline must exist for the current heads (run one in the
   background if the tree moved).
2. **Sonnet, read-only:** re-verify every §1 fact with its recorded command; report drift
   (the coordinator amends §1 before P1 briefs — this program's case law runs 0–8 falsified
   facts per fresh plan). Include the F17 tail-row evidence lines verbatim (the coordinator
   marks the program ledger's T9/T10/T14/T15 rows closed from them).
3. **Opus — probe A (touch delivery to the HAND):** extend Plan 2's delivery probe
   (`Fizzygum-tests/.scratch/pointer-delivery-probe.js` or a fresh sibling): on the built
   pages, dispatch `PointerEvent {pointerType:'touch', …}` down/move/up at the canvas and
   assert the hand's `@pointerType` reads `'touch'` and the press dispatched — H1's
   listener-path proof, both engines. Exit 0/1/2.
4. **Opus — probe B (queue-level touch stroke):** in the harness page, push hand-built
   `Pointer*InputEvent`s with `pointerType:'touch'` through `world.inputEventsQueue` and
   assert: a tap clicks; a drag over a detachable widget inside a viewport currently LIFTS
   (the pre-grammar truth, the contrast P2's witnesses will flip); the dwell machine's
   event-time arming behaves as F4 states. This probe is the grammar's before-picture.
5. **Opus — probe C (per-test extent, F16):** on one harness page, flip the canvas to
   1024×768 at a reset between two tests and back; record whether `WORLD_CONSTRUCTION_DRIFT`
   or any `WORLD_INVENTORY_*` fires and whether the suite machinery (shard reuse, manifests)
   objects. Result routes OD5.
6. **Sonnet — measurements:** (a) F14's counts re-run + the per-test count of right-button
   GESTURES (not dirs) — × the non-scaled hold window = the finger suite's added wall-clock,
   into the STATUS box; (b) `tests/` byte size today + the P4 storage projection per OD2
   option; (c) confirm by grep + one suite run that NO committed macro scroll-drags a nested
   viewport to its edge (the §2.3 escalation's exposure — expected zero; if non-zero, list
   the tests as a P1-declared set and STOP for the coordinator).
7. Nothing committed (probes stay in `.scratch/`).

**Go/no-go:** probes A and B green in both engines (a red half is a stop-the-arc finding —
escalate with the probe output); OD1 put to the owner with probe B's timing evidence; OD5
routed per probe C.

### P1 — The grammar in the hand + T7, MOUSE-INERT (~1 session-day; PIXEL-IDENTICAL)

One Opus worker. Steps: §2.1 (the recognizer + `pressAndHoldMs` + the OD1-ruled clock
shape), §2.2/§2.3 (the two consumer gates + the chrome and scroll-surface capabilities —
derive the names, stop on two falsifications), the hold→menu fire (§2.2 row 5–7, reusing F2
verbatim), the touch hover dissolution (§2.4 point 4), §2.5 (T7: the edit seam re-keyed,
`isTouchDevice` retired), the F7 TODO's escalation in the scroll-drag step (with P0.6c's
zero-exposure confirmation in hand). The T6 title verification (§2.4 point 1) rides the
hold-fire's own testing.
**Gate:** `fg build` (28 gates — dead-methods sees the retirement); `fg presuite`
**byte-identical** (every branch is touch-gated; all 321 green, zero diffs); `fg menusweep`
(menu machinery untouched but the sweep is cheap insurance). Commit.

### P2 — Grammar witness tests + the hold-dial eyes-on (~½–¾ session-day; NEW references only)

Same Opus worker (or a fresh one — the plan is the brief). Steps: the §2.6 L1 touch verbs
(+ their `check-macro-source-discipline`-clean doc comments); new SystemTests authored per
the `/author-macro-test` skill, using toolkit locators only:
1. `…FingerHoldOpensTitledContextMenu` — touch hold on a desktop widget: the titled menu
   appears at the press point (T6.1's witness); release; the menu stays; an outside tap
   dismisses it. Also: the same hold on empty desktop opens the WORLD menu (F2's raw-path
   parity).
2. `…FingerPlainDragScrollsWhereMouseLifts` — the flip of P0 probe B: a touch drag over a
   detachable widget inside an overflowing viewport SCROLLS the pane and the widget stays
   parented; the SAME gesture as a mouse stroke lifts it (both scenes in one macro — the
   non-vacuous contrast, the Plan 2 P2 idiom).
3. `…FingerHoldThenDragLifts` — hold past the window, then drag: the hold menu goes away,
   the widget lifts, lands (the dwell/embed machine downstream unchanged — drop on a
   receptive host embeds per the usual rules).
4. `…FingerChromeDragNeedsNoHold` — a touch drag on a window bar moves the window
   immediately; on a slider, value-drags immediately.
5. `…FingerTapEditSummonsVirtualKeyboard` (assertion-only) — §2.5's witness: DOM element
   present after a touch tap into a text field, absent after a mouse click (and gone at
   teardown — vmtruth is the judge).
   Plus, if OD5 landed them, the tablet-extent set (§2.7) rides HERE as finger-only tests.
**Owner eyes-on (OD3):** before capturing, the owner drives the dev build (real page,
DevTools device-emulation touch or the probe page) and feels `pressAndHoldMs` — re-turn is a
one-constant edit.
**Gate:** `fg presuite` — all 321 pre-existing tests byte-identical, the new tests green;
capture the new references at dpr 1+2 (`capture-macro-test-references.js`);
`make-visualisation.js` for each; `fg menusweep`; `fg vmtruth` rides the next gauntlet (the
hold state and the hold-menu must die with their strokes/worlds). Commit (src + the new
tests + their references together).

### P3 — The finger harness mode + the reference axis (~1 session-day; MOUSE-INERT)

One Opus worker for the toolkit translation + loader/refpaths axis; ONE Sonnet mechanical
sub-step for the runner-flag plumbing (`--pointer=` through the F13 files, from an enumerated
list). Steps: §2.7 in full EXCEPT the baseline capture — the mode, the per-verb translation
table (enumerated in the STATUS box as built), the directory segment through `refpaths.js` +
loader (require/exclude both ways) + capture writers + visualisation exclusion, the
mouse-only metadata field + loader filter, the `fg` leg definition drafted (coordinator
applies — fg is umbrella-local).
**Then the DISCOVERY run** (no finger references exist yet, so this run measures, it does not
gate): the full suite under `--pointer=finger --dpr=1` in the background; classify every
non-completing test — (i) translates fine, pixels differ only as §2.4 predicts (the normal
case: joins the P4 baseline), (ii) mouse-only by MEANING (hover-assertion tests, wheel-
mechanics tests — gets the declaration + reason), (iii) a GRAMMAR BUG (the find this run
exists for — fix or STOP per the rules). The classification table + the measured finger-suite
wall-clock and storage projection go to the coordinator for OD2.
**Gate:** `fg presuite` **byte-identical** (mouse mode untouched by all of it — the
structural no-bump proof); `fg lint` on the touched scripts; the discovery run COMPLETED with
every test classified (i)/(ii)/(iii) and zero unresolved (iii). Commit (toolkit + harness +
scripts + declarations; no finger references yet).

### P4 — The finger baseline + the `finger` gauntlet leg (~½–¾ session-day + capture wall-clock)

**OD2 first** — the owner rules on P3's measured numbers. Then one Opus worker: capture the
ruled scope (`capture-macro-test-references.js --pointer=finger`, background, hours — the
zopflipng single-thread note from Plan 3 applies; `caffeinate` rides fg); verify by a full
finger suite run at each captured dpr — green means every captured test matches its OWN
finger reference; spot-eyeball a sample of finger references against their mouse siblings
(`fg diffpage` has no finger mode — a small `.scratch` side-by-side page is the worker's
tool; the coordinator eyeballs the sample — consequence pixels: missing hover highlights,
hold menus where right-clicks were, nothing else). The coordinator adds the `finger` leg to
fg's gauntlet roster and runs the grown gauntlet.
**Gate:** finger suite green at the captured dprs (chrome) + under `--browser=webkit --dpr=2`
(the leg's own configuration); `fg presuite` byte-identical (mouse world untouched);
tests-repo `check-refs` green (version agreement; duplicates); full `fg gauntlet` including
the new leg. Commit (the finger references + declarations + the leg).

### P5 — T18 decision, docs, close, tail — and the PROGRAM close (~½ session-day)

1. **OD4 to the owner** (§2.9) — the T18 ruling recorded in the program ledger (BACKLOG row
   written with the G2 pairing, or the absorb phase inserted before this one closes).
2. **Sonnet ×N (disjoint files), weave never append:** the input/gesture story into the
   architecture corpus — the hand's grammar (the natural home: a new
   `docs/architecture/` input/gesture section or the widget-authoring input section —
   coordinator picks ONE home; no parallel truths), `viewports-and-planes.md` (scroll-drag's
   widened gate + escalation), `widget-authoring-guidelines.md` (the chrome capability, the
   input section), `Fizzygum-tests/CLAUDE.md` (the finger axis in the reference-grammar
   section + the mouse-only declaration + the leg), `src/macros/CLAUDE.md` +
   `MACRO-PATTERNS.md` (the touch verbs + translation), `lint-and-static-checks.md` only if
   gate text changed, `docs/BACKLOG.md` (the program section rewritten to the close state;
   the stale "Plan 1 P6 in progress" line retired). `fg doc-narration` after.
3. **Program doc (coordinator):** T6/T7 rows → closed (with this plan's §2.4/§2.5 as the
   record); T18 → per OD4; T9/T10/T14/T15 → closed per F17's evidence; the T4 row gains the
   note that the `gesture*` listeners survived this plan as ruled; the STATUS box's Plan 4
   line; **the tail table is now EMPTY ⇒ the program's own close rule fires**: this plan
   file and the program doc `git mv` to `docs/archive/` with INDEX lines at the close
   commit.
4. **Gate:** full `fg gauntlet` (with the finger leg) + `fg homepage` (the production tree
   knows nothing of any of this — the boot + snapshot round-trip is the no-contamination
   witness). Commit; coordinator runs the close-arc ritual (memory + docs + owner review) —
   for the PROGRAM, not just the plan.

**Tail (program §5 rule 2 — drain before the program closes):** pre-filed candidates, each
with a destination: `smoke-boot-headless.js` does not boot `worldWithSystemTestHarness.html`,
so a harness-page-only boot breakage is invisible to build+smoke and surfaces only on a real
test run (found at P2: two such breakages cost the worker a debug loop) — BACKLOG at P5, a
cheap third leg for the smoke; multi-user input attribution (BACKLOG — the Plan 3.5 `User` model's
"Plan 4 at the earliest" marker is discharged by an explicit row: strokes carry `pointerId`
now, a User-per-pointer mapping is designed when a second input DEVICE exists); pinch/T4
(BACKLOG row already exists — unchanged); T5 (BACKLOG — unchanged); tablet-extent tests if
OD5(b) routed them (BACKLOG with probe C's evidence). Anything discovered lands in the
ledger with a destination, per rule 1 — but the ledger must be EMPTY of OPEN rows at the
close: BACKLOG rows are destinations, not opens.

**ETA (owner preference: upfront):** P0 ½ + P1 1 + P2 ½–¾ (+ owner eyes) + P3 1 + P4 ½–¾
(+ owner ruling + capture wall-clock, hours-scale, backgrounded) + P5 ½ ≈ **3½–4½
session-days + two owner reviews + the OD2/OD4 rulings + tail.** The program's §3 estimate
was 2–3; the growth is the harness axis machinery (P3/P4), and OD2(b) is the descoping lever
if the owner wants the smaller arc. Status updates every ~5 min during long ops.

---

## §6 Central risks and how each is bounded

| risk | where | bound |
|---|---|---|
| The grammar leaks into mouse strokes (a pixel diff on an existing reference) | P1–P3 | every branch keyed on `'touch'`; `fg presuite` byte-identity gates EVERY phase; any diff = STOP, never recapture |
| The hold recognizer needs a clock the determinism doctrine forbids | P1 | OD1 decided BEFORE the brief, on probe B's evidence; the dwell (event-time) and the glide (pacing-suppressed) are the only two sanctioned shapes; (c) is pre-rejected |
| The chrome / scroll-surface capabilities fork per-class into a type-test weed | P1 | the capability idiom (`?()`, nothing on Widget) + the enumerated starting set (§2.3); two falsified shapes ⇒ STOP and re-frame (the pre-authorized fallback is per-consumer derivation from EXISTING declarations — `ownsDragsOfMyChildren`, the non-float arm, `indicatorMode`) |
| Hold-then-drag re-fires the menu or double-dispatches the click | P1/P2 | arming fires ONCE per stroke (§2.1); the up of a hold-consumed stroke dispatches no click (§2.2) — witness 1/3 assert both, and the multi-click recognizers see the hold stroke's forget |
| The scroll-drag's widened gate changes a MOUSE scroll-drag | P1 | the mouse reading of the gate is byte-identical by construction; P0.6c measured the escalation's exposure at zero (or declared it); presuite is the judge |
| The touch hover-dissolution (`mouseLeave` sweep at up) disturbs widgets that keep state across enters | P1/P2 | mouse strokes never take the sweep; the witnesses cover menus/buttons; `fg menusweep` + the suite cover the rest of the enter/leave surface |
| A finger run matches a MOUSE reference (or vice versa) and passes wrongly | P3 | the loader requires/excludes the axis segment BOTH ways (F15 — the stated cross-match hazard); `check-refs`'s per-directory duplicate gate stands behind it |
| The finger discovery run drowns in mouse-only failures | P3 | classification (i)/(ii)/(iii) is the run's PRODUCT, not its failure; (ii) gets declarations with reasons; only (iii) blocks |
| The finger baseline's cost surprises the owner | P4 | OD2 is ruled on P3's MEASURED wall-clock + storage numbers, never estimates; (b)/(c) are priced fallbacks |
| The non-scaled hold windows bloat the finger suite's runtime | P3/P4 | P0.6a measures it up front (55 right-button dirs × window); the `clickGuardWindowMs` precedent says the cost class is known-tolerable; if not, the finding goes to the owner with numbers before P4 |
| A per-test extent trips the page-scoped construction ratchet | P0/P2 | probe C measures BEFORE any design lands; OD5 routes the resistance case to BACKLOG or isolation — never a silent exemption |
| Virtual-keyboard summon breaks headless finger runs (focus/DOM) | P2/P3 | witness 5 asserts presence/absence + teardown; the element is transparent and off-canvas (zero pixels); vmtruth judges the teardown |
| The hold state or a hold-menu pins a destroyed widget | P1–P4 | `_forgetPressBookkeeping`'s callers + cancel clear it (§2.8); `fg vmtruth` is the lifetime judge at every gauntlet |

---

## §7 Verification protocol

- Inner loop: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` — **byte-identical on
  all pre-existing references is the gate for EVERY phase** (P2/P4's NEW files excepted —
  new captures, never recaptures).
- Runtime sweeps: `fg menusweep` at P1/P2 (the hold path opens menus); `fg vmtruth` rides
  each gauntlet (hold state + hold menus + finger-run teardowns).
- The finger side: the P3 discovery run and the P4 finger suite runs are
  `run-all-headless.js --pointer=finger` invocations in the background (verdict-file peeks);
  the P4 sample review page is the worker's `.scratch` tool, the coordinator's eyes are the
  gate (program §4 rule 2).
- Phase closes P2, P3, P4, P5: full `fg gauntlet` (18 legs; +the `finger` leg from P4 on) in
  the background, `cat /tmp/fg-gauntlet.verdict` at a ~5-min cadence. `[shard N] did not
  start within 90s` / `CoffeeScript is not defined` = the boot-storm infra flake; a
  serial-retry pass = load-flake warning, not FAIL. P5 additionally `fg homepage`.
- `fg fuzz` ONCE before the P5 close iff any phase touched `readyForMacroScreenshot`/wait
  plumbing (the momentum-settle gate is read by it): remember its THREE outcomes — OK /
  FAILED / INVALID(2) is neither — and a fuzz failure is NEVER a recapture reason, fix the
  read.
- Docs: `fg doc-narration` after the P5 sweep.
- Never pipe a gating `fg` call; never edit mid-run; probes in `Fizzygum-tests/.scratch/`.
- Gates that WILL fire if mishandled (F19): `check-dead-methods`/`check-unresolved-sends`
  (the `isTouchDevice` retirement — fix readers, never allowlist), `check-argument-holes`
  (the synthetic factory's growth — reorder, never a hole), `check-raw-pointer-reads` (hand
  edits consume the mapped param), `check-stinks` (present tense — the F7 TODO retires WITH
  its mechanism, not as a note), tests-repo `check-macro-source-discipline` +
  `check-visualisations` (new tests' pages), `check-refs` (axis + version agreement).

---

## §8 Rejected alternatives — do not re-attempt

- **A per-device mode or setting deciding the grammar** — G1's letter; T11 was deleted for
  exactly this. The stroke's `pointerType` is the ONLY key.
- **A wall-clock timer for the hold** — F4/F16's law and the DETERMINISM.md bug class; the
  dwell shows event-time suffices and OD1(b) shows how real-device sharpness is had without
  a timer.
- **Axis-locked scrolling, scroll-by-background, two-finger scroll** — ruled OUT (I3);
  re-recorded here so nobody re-derives them.
- **Renaming the widget-facing dispatch surface** (`mouseDownLeft` → `pointerDown`…) — every
  widget + the `check-raw-pointer-reads` HANDLER_NAMES set + hundreds of macro sources churn
  to express nothing the grammar needs; the names are the WIDGET vocabulary, and widgets
  never see pointer kinds (program §1). If the owner ever wants the rename it is its own
  mechanical arc — BACKLOG on request, not here.
- **Renaming the L1 macro verbs** to pointer-neutral names — 300+ committed macro sources;
  the verbs ARE the intent layer H2 translates UNDER (Plan 2 §2.6 decided this; confirmed).
- **A `finger` term in the reference FILENAME** — the filename carries exactly one knob (the
  version); run axes are directories (the grammar's own law, and `check-refs` groups by
  directory). The segment goes below `ceilPixRatio_<N>`.
- **Re-using the mouse references for finger runs "since most pixels agree"** — hover pixels
  differ by design (§2.4), and a shared baseline would make `compareScreenshots`'s
  any-candidate pass a standing false-green (the F15 hazard) — the axis exists precisely to
  keep the two truths apart.
- **An Automator version bump "to be safe"** — the version means "what the harness captures";
  mouse captures are unchanged (gated, not asserted), and a needless bump obliges a
  1,898-file recapture (tests-repo CLAUDE.md's letter).
- **Emulating hover on touch** (synthetic mouseEnter on tap-and-wait, hover-on-first-tap) —
  re-grows the emulation layer Plan 2 deleted; T6's resolution is the titled hold menu plus
  declared-out affordances.
- **A "needs hold" flag per widget class** — scatters the grammar; the two capability
  questions (§2.3) derive it from what surfaces already declare.
- **Absorbing the halo redesign by default** — T18 is an OWNER decision (OD4); the program's
  last plan does not silently inherit an unanswered design question.

---

## §9 Delegation map — coordinator and workers (program §3.1)

The coordinator (the session) never edits source or runs suites; it briefs, reads reports,
checks verdict files, decides at gates, hosts the owner reviews (OD1–OD5), applies the
fg-roster edit (P4), and talks to the owner. Workers are fresh agents with no conversation
context: `Agent` with `subagent_type: general-purpose`, `model: "opus"` (phase work) or
`"sonnet"` (mechanical work). ⛔ Never `fork`, never `isolation: worktree`. **One code worker
at a time**; parallel workers only for read-only work and docs edits to disjoint files.

### 9.1 Per-phase map

| phase | worker | parallel? | brief = plan section + | gate the worker runs | coordinator decides |
|---|---|---|---|---|---|
| P0 fact re-verify | Sonnet ×1 | yes (read-only) | §1's fact commands + F17 | none | records drift, amends §1; marks the program's T9/T10/T14/T15 rows |
| P0 probes A/B/C | Opus ×1 | no (browser runs) | P0 steps 3–5's assertion lists | the probe scripts, both engines | GO/NO-GO; OD1 to the owner with probe B; OD5 routing per probe C |
| P0 measurements | Sonnet ×1 | yes (read-only + one suite run) | P0 step 6 | the measurement runs | the numbers into STATUS |
| P1 the grammar + T7 | Opus ×1 | no | §2.1–§2.5, §2.8; F1–F9; OD1's ruling | `fg build`; `fg presuite` byte-identical; `fg menusweep` | verdicts; commit proposal |
| P2 witnesses + eyes-on | Opus ×1 | no | §2.6 (L1 verbs), P2's test list; `/author-macro-test`; F18 | presuite; capture (dpr 1+2); visualisations; menusweep | hosts OD3 with the owner BEFORE capture; reviews the shots; commit |
| P3 harness mode + axis | Opus ×1 + Sonnet (runner flags, enumerated) | no | §2.7; F10–F15; the discovery-run classification spec | presuite byte-identical; `fg lint`; the discovery run + classification | reads the classification; OD2 numbers to the owner; commit |
| P4 baseline + leg | Opus ×1 | no (capture is hours, background) | §2.7's capture scope per OD2; F15 | finger suites (chrome + webkit/dpr2); presuite; check-refs; gauntlet | rules applied OD2; eyeballs the sample page; edits fg's roster; commit |
| P5 docs sweep | Sonnet ×N | yes (disjoint files) | per file: the named weave | `fg doc-narration` | reviews diffs |
| P5 close | coordinator | — | — | `fg gauntlet` (+finger leg), `fg homepage` | OD4 with the owner; program ledger + tail EMPTY; archive moves; close-arc ritual for the PROGRAM |
| tail | per item | per item | the ledger row + destination | as the item needs | ledger bookkeeping |

### 9.2 The worker brief (template — copy, fill the ⟨⟩, nothing else)

```
You are executing ⟨phase/sub-step⟩ of Fizzygum/docs/plans/gesture-grammar-and-finger-harness-plan.md.
Read that plan's §0, §0.5 and §⟨phase⟩ in full, then Fizzygum/docs/plans/frames-input-touch-program.md
§2.3 for rulings ⟨IDs⟩ and §4 (recapture policy). Also read Fizzygum-all/CLAUDE.md, Fizzygum/CLAUDE.md,
Fizzygum-tests/CLAUDE.md and Fizzygum-tests/DETERMINISM.md. All commands through
/Users/davidedellacasa/code/Fizzygum-all/fg by absolute path. Probes under Fizzygum-tests/.scratch/.
Do: ⟨the phase's step list, or "every step of §⟨phase⟩"⟩.
Gate: ⟨exact fg command(s)⟩ → expected ⟨verdict⟩. Launch long ops with run_in_background and wait for
the notification; never poll; never pipe the gating call.
Pixel budget: ZERO existing references may change — the grammar and harness are mouse-inert and every
phase gates fg presuite byte-identity. ⟨P2: the NEW witness tests' own references are created, not
recaptured. P4: finger references are NEW FILES on the finger axis, per the OD2 ruling.⟩ Any diff on an
existing reference = STOP (rule 3). No Automator version bump, ever, in this plan.
Every grammar branch you write keys on the STROKE's pointerType ('touch'); 'mouse'/'pen' paths must be
byte-identical. Timing decisions are EVENT-time only (the dwell precedent) per the OD1 ruling in your
brief — never Date.now()/setTimeout.
Stop and report (do not improvise) if: a §1 fact is false; a fix shape is falsified twice; a gate fails
for a reason you cannot state in one sentence; a diff appears outside the budget; you need a decision
the ledger and §2.9's OD rulings do not cover. Never capture references without the coordinator's
approval, never commit, never push.
Comments you write: present tense only, no history narration. `undefined` is the one absence value.
Report (≤ 60 lines): files changed (git diff --stat, both repos); each gate's literal
/tmp/fg-<cmd>.verdict line; counts measured; tests added/changed + capture verdicts; open questions;
which stop rule fired, if any.
```

### 9.3 What the coordinator checks on every report (cheap, never a re-do)

1. `cat /tmp/fg-<cmd>.verdict` for each gate the report claims — the literal line, not prose.
2. `git -C <repo> status --short` + `git diff --stat` in BOTH repos — the changed-file list
   matches the phase (P1 touches the hand + ViewportWdgt + Preferences + WorldWdgt's edit
   seam and NOTHING in the tests repo; P2 touches macros/MacroToolkit + events-input's
   synthetic + new test dirs; P3 touches MacroToolkit + harness loader + scripts + metadata;
   P4 touches reference trees + fg (coordinator's own edit); a stray file is a question).
3. P2/P4: the owner's eyes-on happened BEFORE the capture (OD3/OD2) — the report's ordering
   proves it; the coordinator LOOKS at the witness shots / the P4 sample page itself.
4. A stop rule fired → read ONLY the quoted evidence; amend §1 or the brief; re-brief. Two
   stops on the same step → re-frame (never a third variant).
5. Then: commit proposal to the owner, or the next brief.

---

## §10 References

- Program: [`frames-input-touch-program.md`](frames-input-touch-program.md) — §2.3 rulings
  (I1/I2/I3/H1/H2), §2.2 context (G1/G3/G4), §3 sequencing ("2 → 4", "3 → 4") + §3.1
  execution model, §4 recapture policy, §5 tail rules + the rows this plan inherits
  (T4/T5/T6/T7/T18 + the F17-verified four), §6 the roster row naming this file.
- Plan 2 (closed, the family this consumes):
  [`../archive/pointer-events-plan.md`](../archive/pointer-events-plan.md) — §2.1 the event
  family + the synthetic boundary, §2.3 the hand's entry points + position heads, §2.4 the
  cancel table, the P0 probe findings (touch delivery both engines; `hasTouch` note).
- Plan 3 (closed, the geometry this assumes):
  [`../archive/single-geometry-visual-wave-plan.md`](../archive/single-geometry-visual-wave-plan.md)
  — the 44 targets, indicator scrollbars (G4 as amended), the 1920×880 extent, T18's origin.
- Plan 3.5 (closed): [`../archive/command-panel-unification-plan.md`](../archive/command-panel-unification-plan.md)
  — its §9 is the delegation shape this §9 copies; the `User` model's multi-user marker.
- Doctrine the executor must hold: `Fizzygum-tests/DETERMINISM.md` (event time, the cadence
  bug class), `Fizzygum-tests/CLAUDE.md` (reference grammar + BUMP discipline + runner/
  capture tooling + the tags/skip-list mechanisms), `Fizzygum/src/macros/CLAUDE.md` +
  `MACRO-PATTERNS.md` (the layer rules; input through the queue, never poke the hand),
  [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md),
  [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md)
  (capability-query idiom), [`../specs/drag-embed-interaction-spec.md`](../specs/drag-embed-interaction-spec.md)
  (the dwell §6 — the recognizer template), [`../architecture/viewports-and-planes.md`](../architecture/viewports-and-planes.md).
- Memory notes the executor should know exist: ask-before-commit/push; long-op ETA + ~5-min
  status; no conclusions before evidence; stop after two falsified fixes; a recapture is a
  decision to BELIEVE the pixels; a cross-repo rename must grep `Fizzygum-tests/scripts/`
  (P9); perl/sed blanket edits de-indent `.coffee` — use the Edit tool; multi-click
  event-time forget (the wall-clock ban's origin); `fg recapture --auto` needs a fresh build
  first.

---

### Start-prompt for a fresh coordinator session (copy-paste)

> You are the COORDINATOR for Plan 4 — the LAST plan — of the frames·input·touch program.
> Read `Fizzygum/docs/plans/gesture-grammar-and-finger-harness-plan.md` IN FULL, then the
> program doc's §2.3/§3.1/§4/§5. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` and
> verify heads ≥ the plan header's (Fizzygum `10bb66b2` / tests `b6912bc54`); if the tree
> moved, expect §1 drift and re-verify before briefing. First act: mark the program ledger's
> T9/T10/T14/T15 rows closed from the plan header's verified evidence (confirm via P0).
> Execute per the plan's §9 delegation map, phases P0→P5, one code worker at a time, briefs
> from the §9.2 template. Five owner decisions ride the phases (§2.9: OD1 hold clock at P0/P1,
> OD2 finger-baseline scope at P4 on measured numbers, OD3 the hold dial at P2's eyes-on, OD4
> T18 absorb-or-BACKLOG at P5, OD5 tablet-extent routing if P0's probe C resists) — present
> options, never decide them yourself. Pixel budget: ZERO existing references change in any
> phase (new witness/finger references are new files); NO Automator version bump. When P5's
> tail drains, the program's tail ledger is EMPTY — run the close-arc ritual for the PROGRAM:
> both this plan and the program doc archive with INDEX lines. Ask the owner before every
> commit/push.
