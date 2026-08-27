# Widget input vocabulary — rename the dispatch surface by TIER (facts vs gestures)

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-27 against Fizzygum `ea7a3312` / Fizzygum-tests `8ffcd83ba` (suite **329**
SystemTests, Automator 0.3.0, gauntlet-green heads — `fg gauntlet` 19/19 incl. the `finger`
leg on 2026-08-27). Every `file:line` was verified on that date — **line numbers DRIFT; the
method name / quoted code is authoritative, so `grep` before trusting a number.**

**This arc is STANDALONE.** The frames·input·touch PROGRAM is CLOSED (all five plans executed
and archived); this rename was explicitly deferred OUT of it —
[`../archive/gesture-grammar-and-finger-harness-plan.md`](../archive/gesture-grammar-and-finger-harness-plan.md)
§8: *"Renaming the widget-facing dispatch surface (`mouseDownLeft` → `pointerDown`…) — … If the
owner ever wants the rename it is its own mechanical arc — BACKLOG on request, not here."* The
owner has now requested it, with a design ruling (§2) that goes beyond the device-word cleanup
that §8 rejected: the rename is by TIER, and it carries two semantic riders. The grammar this
plan renames on top of is the one that plan landed; its living truth is
[`../architecture/input-and-gestures.md`](../architecture/input-and-gestures.md).

**STATUS BOX** (fill per phase as executed)
- Plan authored 2026-08-27. ODs 1–4 are presented for the owner's plan review (§2.7); OD5
  (execute-now vs BACKLOG) is decided on P0's measured numbers.
- **ODs RULED 2026-08-27 (the owner delegated the rulings to the coordinator under the
  standing Do-The-Right-Thing directive — churn, recaptures and legacy carry no weight):**
  - **OD1 — the name scheme is STROKE-PHASE narration for facts, CERTIFIED-MEANING for
    gestures**, so the tier boundary is legible in the name shape itself (the unmarked-tier
    defect this arc fixes). The ruled table AMENDS §2.2's proposed column:
    `mouseDownLeft → pressBegan(pos)` · `mouseUpLeft → pressEnded(pos, …)` · the pressed
    half of `mouseMove → pressMoved(pos[, button — the fact-param, §2.4])` · the hover half
    `→ hoverMoved(pos)` · `mouseEnter → hoverEntered()` · `mouseLeave → hoverExited()`
    (not "hoverLeave"/"hoverLeft" — direction-ambiguous). Gestures as §2.2 proposes:
    `activated` / `doubleActivated` / `tripleActivated` / `contextMenuRequested` /
    `scrolledBy`. Rationale: the "you were X-ed" frame (`pressed`/`released`) is
    internally inconsistent at motion (the POINTER moved, not the widget) and carries the
    state-query reading risk §2.2 itself flags; began/moved/ended narrates phases
    unambiguously (the touchesBegan/Ended lineage). ⚠ P0 must COLLISION-GREP the ruled
    spellings (`pressBegan/pressMoved/pressEnded/hoverEntered/hoverExited/hoverMoved`) —
    F17 cleared the superseded spellings, not these; a real collision falls back per-name
    to the §2.2 alternates, never to an alias.
  - **OD2 — DELETE all four dead channels** as §2.2 proposes (no fallback renames; a dead
    extension point is re-added deliberately when a consumer exists).
  - **OD3 — R1 option (a): UNIFY** — both triggers dispatch `contextMenuRequested` on the
    widget (zero overriders today = pixel-free; the seam closes before it can bite).
  - **OD4 — R2: SPLIT** `hoverMoved`/`pressMoved`. The double-dispatch question (F-noted:
    both hand sites fire per pressed move) is DATA-GATED at P0: measure every pressed-move
    consumer's idempotency; if single-dispatch is pixel-free across the suite, LAND
    single-dispatch (the clean model); otherwise keep the double dispatch and document it
    as a stated fact where the split lands.
  - **OD5 — GO**: execute immediately after P0 unless P0 surfaces a STRUCTURAL blocker
    (size alone is not one, per the directive).
- P0 re-verification + measurements + rename REHEARSAL: **DONE 2026-08-27, GO (OD5).**
  Facts: 13 hold, 5 INCOMPLETE (0 false) — **this entry SUPPLEMENTS §1**: (F5) four live
  sites outside the hand: `OverflowChevronButtonWdgt:82` duck `?()` click dispatch,
  `ScrolledPaneWdgt:90` direct call, `SimpleRasterImageButtonWdgt:24` an INSTANCE-ASSIGNED
  `mouseClickLeft` definition (invisible to header greps), `LabelButtonWdgt:130` `@mouseLeave()`;
  (F7) a third caller of the determineGrabs+dispatch pair: `nonFloatDragWdgtFarAwayToHere`;
  (F9) `TOOTHPASTE_TOOL_SOURCE` also defines `mouseUpLeft` (a P2 string-source site);
  (F11) `serialization-roundtrip-headless.js` carries 5 live `.wheel()` calls (P6); script
  clicks = 10; escalate strings = 8; (F12) **P1's pixel budget is NOT zero** —
  `macroMixinEditDonorAndOverride` drives the inspector with THREE `"mouseEnter"` strings
  (the specimen member): the macro's specimen renames with the member and the test joins
  P1's declared set; (F18) +4 living docs, + `Fizzygum-tests/MIGRATION-PLAN.md`, + the
  `author-macro-test` SKILL (teaches the old vocabulary — the instruction-as-root-cause
  class, P6 updates it). Silent-failure string to sweep: `layout-audit-prelude.js`
  `tagClass('SwitchButtonWdgt', ['mouseClickLeft',…])` (a stale name there attributes
  nothing and stays green). LIVE-SITE census: P1=40 · P2=31 · P3=77 · P4=6 · P5=15 ·
  P6=13 ≈ **182** (below §4's ~300); prose ≈550 lines/60+ files = P6's sweep. COLLISIONS:
  **zero** for every ruled spelling (`activated` appears only in English prose). REHEARSAL
  (`mouseClickLeft`→`activated`, 84 occurrences/53 files, reverted + revert PROVEN by a
  0-diff diffpage): build 28/28 with all three gate name-sets renamed; suite fails exactly
  **4 inspector tests / 13 images** — ⚠ NOT all pure text shifts: `scrollInspectorListItemIntoView`
  derives its scroll fraction from the member's list INDEX, so member-order changes move the
  visible window (one test lands in a different VIEW STATE) ⇒ P3's set gets coordinator
  crop-eyeballs BEFORE capture. R2: all pressed-move consumers measured IDEMPOTENT and
  **single dispatch is pixel-free (suite 329/329 byte-identical with the determineGrabs
  dispatch off)** ⇒ OD4's clean model LANDS at P5 — ⚠ with one evidence gap: zero suite
  coverage of a left-button paint drag (both paint tests move "no button" only), so P5 ADDS
  a left-drag paint witness before the de-duplication lands.
- P1 hover facts + dead-channel deletions: **DONE 2026-08-27** (one Opus worker, zero
  falsifications). `mouseEnter → hoverEntered`, `mouseLeave → hoverExited` across both repos
  in one batch (20 Fizzygum files incl. both gate name-sets; the F5 extras and the injected
  handler swept); the four dead channels DELETED per OD2 — zero-implementor status
  re-verified immediately before each deletion; the down/up dispatch restructured honestly
  (the string indirection with one live arm each became explicit `if`s; the
  `…floatDragging?()` dispatch lines died with their channels). Declared set exactly as P0
  predicted: `macroMixinEditDonorAndOverride` (specimen member renamed in the macro, incl.
  a `_source` key F12 missed), 5 images × 2 dprs, coordinator-eyeballed (member-list shift
  only; the RED/BLUE mixin-edit claims render identically), recaptured COMPLETE.
  ⭐ TOOL DEFECT found and fixed by first use: `recapture.js`'s cleanRefs was NOT
  kind-scoped — it deleted the test's `finger/` sub-axis and restored only the mouse axis
  (287/329 tests carry finger refs: any future `--auto` would have bitten); now scoped via
  `pointerKindFromPath(p) === 'mouse'` with the rule stated in place. The test's finger
  references re-captured fresh (they were stale anyway — the old pixels showed the old
  specimen; eyeballed: `hoverEntered`/`hoverExited` render on the finger axis identically).
  Gates: build 28/28; recapture COMPLETE; presuite 329/329 zero further diffs; gauntlet
  19/19 `OK(warn)` — tiernaming (the known inspector-resize lag flake) + serialization (the
  file-download rig under parallel load, a recurring shape) both serial-pass, logs kept.
  ⚠ P6 SWEEP ADDITION (owner-caught at the P1 gate): the UNCOMMITTED explainer
  `docs/explainers/input-and-gestures.html` (+ its README entry) is HELD OUT of every
  landing until P6 — its intro states the vocabulary is "kept mouse-named on purpose" and
  its funnel diagram's widgets box lists the old names, both falsified by this arc; at P6
  it is rewritten to the final vocabulary (where its story IMPROVES: the funnel ends in
  intent names, dissolving the one admitted wart) and lands then, together with
  `docs/architecture/input-and-gestures.md`'s own sweep (the P1-noted drift at its
  :144/:164 plus the tier vocabulary throughout).
- P2 press/release facts: **DONE 2026-08-27** (same Opus worker, zero falsifications, zero
  pixels). `mouseDownLeft → pressBegan`, `mouseUpLeft → pressEnded` in one batch: 16 class
  defs + the 5th `pressEnded` inside `TOOTHPASTE_TOOL_SOURCE`'s source STRING, 4 escalate
  strings, the hand's climb + release dispatch, both gate name-sets, 4 tests-repo script
  calls; `HighlightableMixin`'s `_class_injected_in` key follows by CONSTRUCTION
  (`Mixin.coffee` derives it from `memberName`). Declared set EMPTY — the m→p rename stays
  in the same alphabetical tail so no pinned member-list window moves (the pixels are the
  oracle: suite 329/329). Positive controls that the rename is LIVE: the raw-pointer gate
  still scans 83 handler bodies (it can only enter a body whose header is in the renamed
  name-set), and every press-dependent pixel test passes. Gates: build 28/28; suite
  329/329; P2-close gauntlet **19/19 CLEAN — no warn legs, no retries** (P1's two warn legs
  passed in-wave: load flakes confirmed).
- P3 activation gestures: **DONE 2026-08-27** (same Opus worker; the arc's biggest family,
  and its richest findings). `mouseClickLeft → activated` (36 defs + the three off-pattern
  sites: the chevron's duck `?()`, ScrolledPane's direct call, the INSTANCE-ASSIGNED def),
  `mouseDoubleClick → doubleActivated`, `mouseTripleClick → tripleActivated`; 8 escalate
  strings, the hand's expectedClick strings + multi-click dispatch, both gate name-sets, 10
  script calls + the `tagClass` silent-failure string. Zero-grep clean (prose → P6, incl.
  parts.json's `"//buttons"` dangling doc-key). ⭐⭐ TWO latent defects surfaced by the
  rename's list-geometry shift and fixed at the root, NEVER blessed: (1) the row-aim CLAMP
  (`clickOnListItemFromTopInspector`) could aim above the pane onto the toggle strip — the
  committed AddEdit references (BOTH axes) had frozen that blind chrome-click (methods
  toggled OFF, nothing selected) since capture; now the aim stays inside the row∩pane slice
  and an empty slice THROWS, and the fix is proven pixel-inert (pre/post renders
  hash-identical); (2) the L3 locator now SCROLLS-UNTIL-AIMABLE (3 bounded nudge+yield
  attempts) — required because the finger axis undershoots the asked thumb fraction by
  ~1 thumb-px ≈ 77 content px, DIAGNOSED as intrinsic quantization (fraction arithmetic
  digit-identical across kinds; delivered thumb within 1 px; a 5 px thumb drives ~75
  content px/px, and mouse hover FATTENS the bar at click time where a finger cannot) —
  NOT a touch-tracking product defect. The never-true AddEdit round-trip comment reworded
  to the claim that holds (selection+value return; chrome is not byte-exact — the old refs
  themselves differed 0.771%). Declared sets, all coordinator-eyeballed: mouse recapture =
  the rehearsal's 4 + AddEdit (22 images, COMPLETE, kind-scoping proven: zero finger
  deletions); finger recaptures = 8 tests (the five + THREE more whose committed finger
  refs carried the same blind-click signature, found by the finger leg). Gates: build
  28/28; presuite 329/329; P3-close gauntlet **19/19 clean, no warn legs** (settle+finger
  passed in-wave — prior fails were the load flake and the stale refs). P6 tail adds: the
  macro-level scroll-further beyond 3 nudges (the named error is the floor and never fired
  in the final run).
- P4 R1 — `contextMenuRequested` unifies the two triggers: **DONE 2026-08-27** (same
  worker, zero pixels, no recapture). `mouseClickRight → contextMenuRequested(pos)` (the
  ruled signature; the arg was always passed and always ignored — now declared); the HOLD
  funnel dispatches the verb on the pressed widget via the same implementor-climb shape as
  the up-path (mirrors rather than assumes), so an override is reached by BOTH triggers —
  the seam closed structurally, pixel-free by measurement (suite 329/329: no reference
  anywhere shows the old name in a member list). The finger leg's hold witness now
  exercises the hold THROUGH the verb. Gates: build 28/28; suite 329/329; menusweep OK
  (3749 items / 464 menus through the renamed verb); P4-close gauntlet 19/19 clean, no
  retries.
- P5 R2 — the move split (`hoverMove` / `pressedMove`): **DONE 2026-08-27** (fresh Opus
  worker; landed as `hoverMoved`/`pressMoved` per the ruled table). The last multiplexed
  channel split; the hand's over-list loop dispatches by button state; determineGrabs'
  duplicate dispatch REMOVED (the P0-proven single-dispatch model — one `pressMoved` per
  pressed move). ⚠ TWO premises falsified by measurement, both amended here dated: (1) the
  brief's "StringWdgt = pressed only" — the hover half (`_disableSelecting`, the
  selecting-gesture expiry) is LOAD-BEARING (dropping it turned a tap's edit into a
  pop-out; caught by the keyboard witness) ⇒ StringWdgt takes BOTH channels into one
  `_stepSelectionAt` body, as do the four paint-tool sources (byte-unchanged bodies); (2)
  **the plan's "P5 = ZERO existing refs" budget — a channel ADDITION grows member lists**
  (a pure-rename assumption; the worker measured the alternative shape produces the
  IDENTICAL churn), so the member-list window shift re-touched 5 inspector tests (16 dpr1
  images; the P0-rehearsal mechanism) — declared, coordinator-eyeballed (one-row shift,
  same member selected), recaptured on BOTH axes. ⭐ THE WITNESS
  (`macroPencilPaintsStrokeOnLeftDrag`, the P0 coverage gap): paints by left-drag, and its
  FINGER replay paints too (hold-then-drag arms the stroke) — initially NOT byte-stable
  (one 4×4 dab at the arming point, cycle-timing dependent: the per-cycle re-sync
  re-delivers a pressed move across the arming boundary), FIXED by the third application
  of the OD1(b) suppression idiom (re-sync-originated pressed moves suppressed under the
  pacing control; `atDrainedEvent` distinguishes the callers): 6/6 identical finger runs,
  mouse-inert measured (the pre/post failing set identical). Full both-axes references
  captured. Gates: build 28/28; presuite **330/330**; P5-close gauntlet 19/19 `OK(warn)` —
  paint+storage serial-only (the load-flake shape). P6 note: `input-and-gestures.md`'s
  consumers section is stale in MECHANISM now (two dispatch sites → one; the re-sync
  suppression is new doctrine to record), not just vocabulary.
- P6 `scrolledBy` + docs weave + tests-prose sweep + arc close: —

---

## MANDATE

Eliminate the problem, do not bury it: the widget-facing pointer-dispatch surface must come out
of this arc named by what each verb CERTIFIES, with the fact/gesture tier boundary visible in
the names, with the two channels that multiplex two meanings split, with the one dispatch-level
asymmetry (the context-menu double funnel) closed, and with the dead channels DELETED rather
than renamed. No aliases, no facade, no partial vocabulary: at the arc's close the old names
have ZERO live occurrences in either repo outside `docs/archive/` (§7 gate). A transitional
`?()` fallback in the hand is permitted only INSIDE a batch sequence and must be gone at the
arc's close.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on one canvas; read
`Fizzygum-all/CLAUDE.md` + `Fizzygum/CLAUDE.md` first (build/test commands, the `fg` wrapper,
the umbrella layout). All pointer input arrives as W3C Pointer Events, is queued, and is
dispatched by **the hand** (`src/ActivePointerWdgt.coffee`) onto widgets through a fixed set of
widget-facing handler names. The recent input program made the pipeline kind-agnostic (mouse /
pen / finger all drive one grammar; a `finger` gauntlet leg replays the whole suite through
touch) — but the **names** the hand dispatches are still mouse-named: `mouseDownLeft`,
`mouseClickLeft`, `mouseMove`, `mouseEnter`…

**The critical reframe — the defect is not the word "mouse", it is an UNMARKED TIER BOUNDARY.**
The surface already has two tiers with different guarantees, and the names hide the split:

- **The FACT tier** — raw stroke phases, no interpretation: `mouseDownLeft` = "a primary press
  landed at pos"; a pressed `mouseMove` = "the pointer moved while down"; `mouseEnter`/
  `mouseLeave` = the pointer-under lifecycle; `mouseUpLeft` = "the primary press released".
  Consumers: drawing canvases (the paint tools), sliders, text selection, hover highlights.
  These must STAY uninterpreted — a paint canvas wants every raw move.
- **The GESTURE tier** — recognizer OUTPUTS with guarantees the hand certifies before
  dispatching: `mouseClickLeft` = "the stroke, examined, meant a click" (multi-click
  recognition ran; a drag away suppressed it via `w == @mouseDownWdgt`; a hold or a
  drag-scroll suppressed it via `_strokeOwesNoClick()`); `mouseClickRight` = "the context
  gesture happened" (and since the touch grammar landed, a press-and-hold is a second trigger
  of the same gesture); `mouseDoubleClick`/`mouseTripleClick` = the folded multi-click;
  `wheel` = "a scroll step was asked of you". Consumers: buttons, toggles, menus — anything
  activation-shaped.

`mouseDownLeft` and `mouseClickLeft` LOOK like siblings and live on different tiers — a widget
author reading `Widget.coffee` cannot see which handler carries a certified gesture and which
is a raw phase. That unmarked boundary is the naming defect this plan removes.

Two real seams ride along (each an owner-ruled semantic rider, §2.3/§2.4):
- **R1**: the context-menu gesture has TWO trigger funnels that meet BELOW the widget dispatch
  instead of at it — a right-click dispatches `mouseClickRight` on the widget, while the hold
  calls the hand's `openContextMenuAtPointer` directly, BYPASSING any `mouseClickRight`
  override (verified §1 F6; latent today — zero overrides exist — but structural).
- **R2**: `mouseMove` multiplexes two meanings (hover motion vs pressed motion), distinguished
  only by a `mouseButton` argument one dispatch site passes and the other does not (§1 F7).

Everything else here is a mechanical whole-tree rename with the cross-repo discipline the
`*Morph`→`*Wdgt` migration, the P9 `@target` rename and the Plan-3.5 P0 rehearsal established.

---

## §0.5 Cold-execution protocol

1. Read, in order: `Fizzygum-all/CLAUDE.md` · `Fizzygum/CLAUDE.md` ·
   `Fizzygum-tests/CLAUDE.md` · this plan in FULL ·
   [`../architecture/input-and-gestures.md`](../architecture/input-and-gestures.md) ·
   [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md)
   (gate index — three gates carry handler-name sets, §1 F10).
2. `/Users/davidedellacasa/code/Fizzygum-all/fg status` (absolute path, never `./fg`). A green
   gauntlet baseline must exist for the current heads; if the tree moved since `ea7a3312` /
   `8ffcd83ba`, run one in the background before P1.
3. Execute phases IN ORDER, P0 → P6, under the §9 delegation model (coordinator briefs
   workers; the coordinator never edits src). Each phase ends with its own gate (§7), a
   proposed commit message, and the OWNER's approval before committing — never push without
   asking (standing preference).
4. Every §1 fact is a HYPOTHESIS to re-verify in P0 (this workspace's case law: plan premises
   fall at a rate of 0–8 per plan). A falsified fact ⇒ amend §1 IN PLACE with a dated note
   before any brief that depends on it.
5. Stop rules: a fix shape falsified twice ⇒ re-frame, never a third variant. Any pixel diff
   outside the phase's declared budget ⇒ STOP, `fg diffpage`, eyeball the CONSEQUENCE pixels
   — never call a diff "benign churn" unseen. A recapture is a decision to BELIEVE the pixels.
6. Long ops (`fg presuite`, `fg gauntlet`, discovery suite runs): launch ONCE with
   `run_in_background: true` redirected to a log; wait for the notification; peek at most
   every ~5 min via `cat /tmp/fg-<cmd>.verdict`. ⛔ Never pipe a gating fg call through
   `tail`/`grep`. ⛔ Never hand-roll `until`/`while … sleep` pollers (the guard hook blocks
   them).
7. Edits to `.coffee` files go through the Edit tool — ⛔ never blanket `perl`/`sed` (measured:
   de-indents CoffeeScript silently). A rename batch is Edit-tool work over an ENUMERATED site
   list, then a `grep -rnw` zero-check of the old name.
8. Scratch probes live in `Fizzygum-tests/.scratch/` (gitignored), never the session
   scratchpad (`require()` resolves from the script's dir).

---

## §1 The system as it stands (verified 2026-08-27; re-verify in P0)

Re-verification command for any fact: the quoted grep beside it. The per-name census command
(used for F1/F2, re-run in P0):

```
# totals per area (run from Fizzygum-all); add -l for file lists
grep -rnwE "<name>" Fizzygum/src --include="*.coffee" | wc -l
grep -rnwE "<name>" Fizzygum-tests/tests Fizzygum-tests/scripts \
  Fizzygum-tests/Automator-and-test-harness-src | wc -l
# definition sites (CoffeeScript method headers)
grep -rnE "^\s*<name>\s*:\s*(\(|->)" Fizzygum/src --include="*.coffee"
```

- **F1 — the COMPLETE dispatch surface is sixteen names.** The hand's entry points
  (`processPointerDown/Move/Up/Cancel`, `processWheel`, `processDoubleClick`,
  `processTripleClick`, `dispatchEventsFollowingMouseMove`, `determineGrabs`,
  `_dissolveHoverStateOfTouchStroke`) dispatch exactly: `mouseDownLeft`, `mouseDownRight`,
  `mouseUpLeft`, `mouseUpRight`, `mouseClickLeft`, `mouseClickRight`, `mouseDoubleClick`,
  `mouseTripleClick`, `mouseMove`, `mouseEnter`, `mouseLeave`, `mouseEnterfloatDragging`,
  `mouseLeavefloatDragging`, `nonFloatDragging`, `endOfNonFloatDrag`, `wheel`. This equals
  `check-raw-pointer-reads.js`'s `HANDLER_NAMES` set exactly (F10). The hand's own comment
  block above `destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem` lists the
  twelve non-drag names. Verify: read `src/ActivePointerWdgt.coffee` end to end (~1600
  lines); grep each name.

- **F2 — measured occurrence/definition census (2026-08-27), whole word, per area.**
  `t` = total word hits (code + comments + prose), `d` = definition headers, `f` = files.

  | name | src | tests/tests | tests/scripts | harness src | buildSystem | docs/ |
  |---|---|---|---|---|---|---|
  | mouseDownLeft | 43t/12d/16f | 54t/37f (prose) | 3t/2f (2 calls) | 0 | 2f | 23f |
  | mouseDownRight | 3t/1d/2f | 0 | 0 | 0 | 2f | 2f |
  | mouseUpLeft | 10t/4d/9f | 2t (prose) | 3t/2f (2 calls) | 0 | 2f | 7f |
  | mouseUpRight | 1t/**0d**/1f | 0 | 0 | 0 | 2f | 1f |
  | mouseClickLeft | 80t/36d/45f | 52t/35f (prose) | 12t/7f (**9 calls**) | 0 | 3f | 42f |
  | mouseClickRight | 8t/**1d**/3f | 12t/9f (prose) | 0 | 0 | 2f | 5f |
  | mouseDoubleClick | 13t/3d/6f | 10t/5f (prose) | 0 | 0 | 2f | 4f |
  | mouseTripleClick | 7t/2d/4f | 12t/3f (prose) | 0 | 0 | 2f | 2f |
  | mouseMove | 21t/4d/8f (+5 string defs, F9) | 35t/8f (**1 live assignment**, F12) | 2t (prose) | 0 | 2f | 13f |
  | mouseEnter | 25t/8d/14f | 55t/19f (prose) | 0 | 0 | 1f | 11f |
  | mouseLeave | 25t/10d/15f (+1 injectProperty, F9) | 16t/13f (prose) | 0 | 0 | 1f | 11f |
  | mouseEnterfloatDragging | 2t/**0d**/1f | 0 | 0 | 0 | 1f | 3f |
  | mouseLeavefloatDragging | 3t/**0d**/1f | 0 | 0 | 0 | 1f | 3f |
  | nonFloatDragging | 33t/4d/10f | 139t/64f (prose+tags) | 1 call | 0 | 3f | 21f |
  | endOfNonFloatDrag | 8t/2d/4f | 15t/5f (prose) | 0 | 0 | 1f | 2f |
  | wheel | ~103t/2d/12f (word incl. prose) | 374t/78f (prose+tags+L1 verb) | 8t/1f | 1t/1f | 3f | 36f |

  ⚠ The tests-repo totals are dominated by PROSE (`intent`/`provenance`/`assertions` strings,
  macro comments, `tags` arrays) — the LIVE tests-repo code references are exactly the ones
  F11/F12 enumerate. Docs counts include `docs/archive/` (not edited, §5 P6).

- **F3 — three channels are DEAD (dispatched, zero implementors).**
  `mouseUpRight` — its only src occurrence is the hand's dispatch
  `w.mouseUpRight? @_pointerPositionInPlaneOf(w), e.button, …` in `processPointerUp`.
  `mouseEnterfloatDragging` / `mouseLeavefloatDragging` — occurrences are the hand's `?()`
  dispatches (`newWdgt.mouseEnterfloatDragging?()  if @mouseButton`, and the twin `old.
  mouseLeavefloatDragging?()` at two sites) plus the hand's comment roster. NOTHING in src,
  tests, scripts or harness defines any of the three. A fourth is dead-in-effect:
  `mouseDownRight`'s ONE implementor is `WorldWdgt.mouseDownRight: -> noOperation`, so every
  right press climbs the whole parent chain and dispatches a no-op at the world.
  Verify: `grep -rnwE "mouseUpRight|mouseEnterfloatDragging|mouseLeavefloatDragging|mouseDownRight" Fizzygum/src Fizzygum-tests --include="*.coffee" --include="*.js"`.

- **F4 — the gesture tier's guarantees are real, quoted.** `processPointerUp`: the click
  dispatch runs only `if w == @mouseDownWdgt` (drag-away suppression), after
  `else if @_strokeOwesNoClick()` short-circuits the whole click branch (hold-consumed or
  plain-drag-scroll strokes — `_strokeOwesNoClick: -> return true if @_pressHoldFired;
  @pointerType is 'touch' and @_pressLeftHoldRadius and not @_pressArmedForMouseSemantics`).
  Multi-click recognition (the two `MultiClickRecognizer`s + the event-time stale forget)
  runs before `w[expectedClick] … doubleClickInvocation, tripleClickInvocation`.

- **F5 — the dispatch MECHANICS are three shapes** (each a different rename hazard):
  1. **String-keyed climbs in the hand**: `actualClick = "mouseDownLeft"` /
     `"mouseDownRight"`, `expectedClick = "mouseClickLeft"` / `"mouseClickRight"` (8 string
     literals in `ActivePointerWdgt`), then `@mouseDownWdgt.parent until
     @mouseDownWdgt[expectedClick]`, `while !w[actualClick]?`, `until w[expectedClick]`, and
     the `switch expectedClick` dispatching `w.mouseUpLeft?` / `w.mouseUpRight?`.
  2. **Truthiness climbs**: `w = w.parent while w and not w.mouseDoubleClick` (and
     `mouseTripleClick`, `wheel`, plus `topWdgt.mouseMove` gated `if topWdgt.mouseMove`).
  3. **`?()` duck dispatches** (silent if the name dangles): `old.mouseLeave?()`,
     `old.mouseLeavefloatDragging?()`, `newWdgt.mouseMove?(…)`, `newWdgt.mouseEnter?()`,
     `newWdgt.mouseEnterfloatDragging?()`, `@nonFloatDraggedWdgt.nonFloatDragging?(…)`,
     `@nonFloatDraggedWdgt.endOfNonFloatDrag?()` (×3 incl. the cancel path), and the probe
     `@nonFloatDraggedWdgt?.nonFloatDragging?` in `_advancePressAndHoldRecognition`.
  ⚠ NO static gate sees a dangling `?()` send: `check-unresolved-sends.js` harvests
  paren-calls of the form `[@.]name(` only (its header: "PAREN-CALLS ONLY … STRING-DISPATCHED
  sends are invisible"), and `check-dead-methods.js` counts a name as referenced if it
  appears ANYWHERE in src + harness + macro `.js` — including prose (F13). The real nets for
  a missed site are the enumerated sweep + the §7 zero-grep + the pixel suite.

- **F6 — R1's asymmetry, verified (LATENT, not yet biting).** Right-click funnel:
  `processPointerUp` climbs to a `mouseClickRight` implementor and calls it →
  `Widget.mouseClickRight: -> world.hand.openContextMenuAtPointer @` (`Widget.coffee`, the
  only implementor in the tree — 1 def). Hold funnel: `_advancePressAndHoldRecognition`
  fires `@openContextMenuAtPointer @mouseDownWdgt` DIRECTLY, with the comment *"the hold is
  an alternate TRIGGER for the right-click's own verb, not a parallel path —
  openContextMenuAtPointer is exactly what Widget.mouseClickRight fires"*. So the funnels
  merge one level BELOW the widget dispatch: a subclass overriding `mouseClickRight` would be
  reached by right-click and BYPASSED by the hold. ⚠ AMENDMENT to the design brief's premise:
  **no widget overrides `mouseClickRight` today** (grep: 1 def, `Widget` itself), so the seam
  is structural/latent, not a live bug — R1 closes it before the first override appears.
  `openContextMenuAtPointer`'s other callers: none besides these two (src grep: def + the
  hold + `Widget.mouseClickRight` + 2 comments).

- **F7 — R2's multiplexing, verified — and a THIRD wrinkle: the pressed move DOUBLE-fires.**
  Two `mouseMove` dispatch sites:
  (a) `determineGrabs` (pressed-left only, pre-grab): `topWdgt.mouseMove
  topWdgt.screenPointToMyPlane(pos)  if topWdgt.mouseMove and @strokeMeansMouseDrag()` —
  ONE argument, no button.
  (b) `dispatchEventsFollowingMouseMove` (every move, hover or pressed):
  `newWdgt.mouseMove?(newWdgt.screenPointToMyPlane(@position()), @mouseButton)` — the
  `@mouseButton` argument (`undefined` / `"left"` / `"right"`) is the ONLY thing telling a
  receiver which meaning it got; gated by `pressedMovesAreWithheld = @mouseButton? and not
  @strokeMeansMouseDrag()` (the touch grammar's third consumer) and by the
  did-it-actually-move check.
  ⚠ Because `determineGrabs` runs first inside `processPointerMove` and `topWdgt` is in the
  over-list, a pressed-left move over an ungrabbed widget dispatches `mouseMove` to it
  TWICE per event — once as (a) with no button (the paint tools' preview branch), once as (b)
  with `"left"` (the paint branch). The paint canvas's per-stroke behavior is built on this
  double dispatch (F9). R2 must preserve or knowingly re-shape it (§2.4).

- **F8 — the `mouseMove` implementor set and which meaning each consumes** (4 method defs +
  the string-defined tool handlers of F9 + 1 test fixture of F12):
  | implementor | reads | meaning consumed |
  |---|---|---|
  | `StringWdgt.mouseMove(pos)` | pos | pressed (extend selection while `currentlySelecting()`); the `else @_disableSelecting()` arm also runs on hover moves |
  | `ViewportWdgt.mouseMove()` | neither (re-derives via `@screenPointToMyPlane world.hand.position()`) | hover (scroll-band fatten) — also fires on pressed moves |
  | `SliderButtonWdgt.mouseMove()` | neither | hover (highlight), self-guards pressed state |
  | `Example3DPlotWdgt.mouseMove(pos, mouseButton)` | both | pressed only (`if mouseButton == 'left'` rotate) |
  | paint tool sources (F9) | both | BOTH: `'left'` paints, else draws the hover preview |
  | test fixture (F12) | pos | hover (records the mapped pos) |

- **F9 — the META-SYSTEM string surface.** `PaintToolbarWdgt` defines the paint handlers as
  SOURCE STRINGS: `@TOOL_OFF_SOURCE: "mouseMove = -> return"` plus `@PENCIL_TOOL_SOURCE` /
  `@BRUSH_TOOL_SOURCE` / `@TOOTHPASTE_TOOL_SOURCE` / `@ERASER_TOOL_SOURCE`, each beginning
  `mouseMove = (pos, mouseButton) ->` — injected onto the paint overlay via
  `overlayCanvas.injectProperties PaintToolbarWdgt.sourceForToolKey …`
  (`src/authoring/ImageWdgt.coffee`), where `Widget.injectProperties` regex-parses the
  `name = source` head and calls `@injectProperty m[1], m[2]`. `ImageWdgt` also injects
  `overlayCanvas.injectProperty "mouseLeave", """ … """` (clears the preview). Each injection
  stores a `<name>_source` companion field that RIDES SERIALIZATION as `{"$src"}` and
  re-injects on load. ⚠ No committed test asset carries one (the tests repo holds only
  `.js`/`.png`/`.html`), and the standing owner rule is **NO serialization compat
  obligations** — so old snapshot files that carry a `mouseMove_source` may break, sanctioned.
  Verify: `grep -rn "TOOL_SOURCE\|injectProperty" Fizzygum/src/authoring/PaintToolbarWdgt.coffee Fizzygum/src/authoring/ImageWdgt.coffee`.

- **F10 — THREE build files carry handler-name sets/allowlists** (each must move IN THE SAME
  COMMIT as the family it names):
  1. `buildSystem/check-raw-pointer-reads.js` — `HANDLER_NAMES` (all 16).
  2. `buildSystem/check-plane-discipline.js` — `POS_HANDLER_NAMES` (the 10 positional ones:
     down/up/click/double/triple/move/nonFloatDragging; `wheel` deliberately absent — deltas).
  3. `buildSystem/check-layering.js` — `DEFERRED_SETTLE_CALLER_ALLOWLIST = new
     Set(['nonFloatDragging'])` (unchanged unless that name moves — §2.2 keeps it).
  No handler name appears in `dead-method-allowlist.txt`, `unresolved-sends-allowlist.txt` or
  `public-api-allowlist.txt` (verified empty grep).

- **F11 — tests-repo LIVE code references (the P9 class: scripts drive `index.html`, which
  the suite never touches — the `apps`/`parts` gauntlet legs are their judge).** Direct
  handler CALLS inside `page.evaluate` bodies:
  `smoke-apps-headless.js` — `folderShortcut.mouseClickLeft()`, `fs.mouseClickLeft()`,
  `icon.mouseClickLeft()`; `parts-lazy-icons-headless.js` — 4 × `.mouseClickLeft()`;
  `parts-lazy-load-headless.js` — `launcher.mouseClickLeft()`; `staleness-census.js` —
  `opener.mouseClickLeft()`; `serialization-roundtrip-headless.js` —
  `saveItem.mouseDownLeft(saveItem.center())`, `if (saveItem.mouseUpLeft)
  saveItem.mouseUpLeft(…)`, `saveItem.mouseClickLeft()`; `smoke-boot-headless.js` —
  `rot.mouseDownLeft(grip)`, `rot.nonFloatDragging(new Point(0,0), p, new Point(0,0))`,
  `rot.mouseUpLeft()`; `end-of-cycle-audit/layout-audit-prelude.js` —
  `tagClass('SwitchButtonWdgt', ['mouseClickLeft', …])` (a STRING list). Plus comments in
  `menu-click-sweep-headless.js` and `check-macro-source-discipline.js` (prose).

- **F12 — tests-repo MACRO-SOURCE references: exactly ONE is live code.**
  `SystemTest_macroMouseMovePositionMappedInRotatedIsland_automationCommands.js`:
  `box.mouseMove = (pos) -> @recordedMouseMovePos = pos` (a hover-probe fixture asserting R1
  plane mapping). Every other tests/tests hit is prose (intent/provenance/assertions
  strings, macro comments) or a `tags` array entry (`"nonFloatDragging"`, `"wheel"` — tags
  are topical labels, not dispatch). ⚠ Macro source is CoffeeScript inside a JS template
  literal — a `.coffee`-scoped search cannot see it; grep `.js` (standing memory rule).

- **F13 — `escalateEvent` is a STRING-dispatch escalator with 16 handler-name call sites.**
  `Widget.escalateEvent: (functionName, args...) ->` climbs `handler.parent while not
  handler[functionName]` and calls. Sites by string: `"mouseDownLeft"` — `LabelButtonWdgt`,
  `SliderWdgt`, `Widget` (its own `mouseDownLeft` re-escalates), `MenuItemWdgt`;
  `"mouseClickLeft"` — `TransformFrameWdgt`, `ButtonWdgt`, `SwitchButtonWdgt`, `StringWdgt`,
  `StringFieldWdgt`, `Widget`, `SheetCellsPanelWdgt`, `SimpleRasterImageButtonWdgt`;
  `"mouseDoubleClick"` — `StringWdgt`; `'wheel'` — `ViewportWdgt` (×2, the at-edge
  escalation), `SimpleSpreadsheetWdgt`. (The non-pointer strings — `"reactToKeystroke"`,
  `"accept"`, `"cancel"`, `'scrollByDragDelta'` — are out of scope.)

- **F14 — the Widget-level defaults (the inspector-churn carriers).** `Widget` itself defines
  three of the sixteen: `mouseDownLeft: (pos) -> @bringToForeground(); @escalateEvent
  "mouseDownLeft", pos` · `mouseClickLeft: (…9 args…) -> @escalateEvent "mouseClickLeft", …`
  · `mouseClickRight` (F6). `WorldWdgt` adds no-op terminators `mouseDownLeft` /
  `mouseClickLeft` / `mouseDownRight`. `HighlightableMixin` donates `mouseDownLeft`,
  `mouseUpLeft`, `mouseEnter`, `mouseLeave` to 7 consumers (`ButtonWdgt`,
  `DesktopLinkWdgt`, `SimpleDropletWdgt`, `EditorContentPropertyChangerButtonWdgt`,
  `UpperRightTriangleIconicButtonWdgt`, `GlassBoxTopWdgt`, `CreatorButtonWdgt`) — the
  inspector lists OWN-prototype members only, and a mixin-donated member costs 2 rows
  (standing memory note), so churn shows on the DONORS' consumers too. Renaming a
  Widget-prototype member churns any test whose screenshots include an inspector member
  list around that alphabet region — the set is MEASURED by P0's rehearsal, never assumed.

- **F15 — the wheel channel.** Definitions: `ViewportWdgt.wheel: (xArg, yArg, zArg,
  altKeyArg, buttonArg, buttonsArg) ->` and `SimpleSpreadsheetWdgt.wheel` (same six-arg
  shape); dispatch: `WheelInputEvent.processEvent` → `world.hand.processWheel` → the
  truthiness climb → `w.wheel deltaX, deltaY, deltaZ, altKey, button, buttons`; plus the
  three `escalateEvent 'wheel'` at-edge sites (F13). ⚠ TRAP: `WorldWdgt` also carries the
  DOM strings `canvas.addEventListener "wheel", @wheelBrowserEventListener` /
  `removeEventListener 'wheel'` — browser API, MUST NOT be renamed; likewise
  `WheelInputEvent` and `processWheel` name the W3C stream at the boundary and stay. The
  macro L1 verb layer (`wheelOn_InputEvents` etc., plus `"wheel"` tags) is the TEST-side
  intent vocabulary — decided twice, stays (§8).

- **F16 — full implementor rosters** (rename site lists; re-derive with the F2 def-grep):
  `mouseDownLeft` (12): Widget, WorldWdgt, HighlightableMixin, MenuItemWdgt,
  SliderButtonWdgt, SliderWdgt, StringWdgt, ViewportWdgt, Example3DPlotWdgt, HandleWdgt,
  LabelButtonWdgt, PaletteWdgt. `mouseUpLeft` (4): HighlightableMixin, Example3DPlotWdgt,
  HandleWdgt, LabelButtonWdgt. `mouseClickLeft` (36): Widget, WorldWdgt, ButtonWdgt,
  LabelButtonWdgt, SwitchButtonWdgt, ToggleButtonWdgt, TransformFrameWdgt, PanelWdgt,
  ScrolledPaneWdgt, SliderButtonWdgt, StringFieldWdgt, StringWdgt, FrameBarWdgt, HandleWdgt,
  BinOpenerWdgt, AppLauncherWdgt, DocumentShortcutWdgt, FolderShortcutWdgt,
  ScriptShortcutWdgt, SheetCellsPanelWdgt, SimpleSpreadsheetWdgt, PointerWdgt (demos),
  ToolbarCreatorButtonWdgt, WidgetCreatorAndSmartPlacerOnClickMixin,
  LayoutElementAdderOrDropletWdgt, EditableMarkWdgt, ExternalLinkButtonWdgt,
  TemplatesButtonWdgt, CodeInjectingSimpleRectangularButtonWdgt, and the 7 authoring
  format buttons (Align/Bold/ChangeFont/DecreaseFontSize/FormatAsCode/IncreaseFontSize/
  Italic). `mouseClickRight` (1): Widget. `mouseDoubleClick` (3): StringWdgt, ButtonWdgt,
  CellWdgt. `mouseTripleClick` (2): StringWdgt, TextWdgt. `mouseEnter` (8) /
  `mouseLeave` (10): HighlightableMixin, MenuItemWdgt, SliderButtonWdgt, HandleWdgt,
  LabelButtonWdgt, StackElementsSizeAdjustingWdgt, ExternalLinkButtonWdgt,
  LayoutElementAdderOrDropletWdgt (+ mouseLeave only: ViewportWdgt, Example3DPlotWdgt).
  `nonFloatDragging` (4): SliderButtonWdgt, HandleWdgt, PaletteWdgt,
  StackElementsSizeAdjustingWdgt. `endOfNonFloatDrag` (2): SliderButtonWdgt,
  StackElementsSizeAdjustingWdgt. `wheel` (2): F15.

- **F17 — no candidate NEW name collides.** `activated`, `doubleActivated`,
  `tripleActivated`, `hoverEnter`, `hoverLeave`, `hoverMove`, `pressedMove`,
  `contextMenuRequested`, `scrolledBy`, `secondaryPressed`: ZERO whole-word occurrences in
  either repo. `pressed` / `released` occur ONLY as English words in comments/prose (no
  identifier `pressed:`/`.pressed(` anywhere) — usable as method names, but see OD1's
  reading-risk note.

- **F18 — docs surface.** Living docs mentioning handler names: 9 in `docs/architecture/`
  (input-and-gestures, widget-authoring-guidelines, viewports-and-planes, transforms,
  lint-and-static-checks, layering-naming-convention, mixins,
  serialization-duplication-reference, build-and-packaging), `docs/specs/
  drag-embed-interaction-spec.md`, 2 active plans (affine-transforms,
  dataflow-engine-implementation), plus `src/macros/CLAUDE.md`, `src/macros/
  MACRO-PATTERNS.md`, `src/spreadsheet/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`,
  `Fizzygum-tests/DETERMINISM.md`. `docs/archive/` (30+ files) and dated
  `docs/measurements/` snapshots are NOT edited (bucket rules, `docs/README.md`).

### 1.3 Why it is shaped this way

The names are Morphic.js inheritance: Morphic dispatched literal DOM mouse events, and the
left/right suffixes date from when the button was the only "kind" an input had. Every
subsequent arc (Pointer Events, the touch grammar, the finger harness) deliberately left this
surface untouched to keep its own diff mouse-inert — the gesture-grammar plan §8 records the
deferral verbatim. The result: a kind-agnostic pipeline whose FINAL hop wears device-era
names, with the tier boundary (facts vs certified gestures) invisible precisely where widget
authors meet it (`widget-authoring-guidelines.md` §9 today documents the surface by listing
mouse names).

---

## §2 The mechanism this plan installs (target design)

### 2.1 The naming RULE (the owner's ruling — cite it, do not re-argue)

Rename by TIER:
- **Facts stay flat facts** — named for the raw phase, carrying no interpretation:
  a press, a release, a hover entry, a motion while down.
- **Gestures are named for the GUARANTEE the hand certifies** — never for the presumed use.
  `activated` describes the certified gesture ("this stroke, examined, meant an
  activation"); `chosen` / `buttonPressed` would presume the consumer's role — **banned**.
- Channels nobody implements are DELETED, not renamed (the mandate: eliminate, don't
  transliterate).

### 2.2 The name table (OD1 — RULED 2026-08-27, see the STATUS box: the fact-tier spellings
below are SUPERSEDED by the stroke-phase scheme — `pressBegan`/`pressMoved`/`pressEnded`/
`hoverEntered`/`hoverExited`/`hoverMoved`; gesture-tier spellings and all DELETE/KEEP rows
stand as proposed)

| old | tier | proposed | signature (unchanged unless noted) | notes |
|---|---|---|---|---|
| mouseDownLeft | fact | **pressed** | `(pos)` | "a primary press landed at pos" |
| mouseUpLeft | fact | **released** | `(pos, button, buttons, ctrl, shift, alt, meta)` | primary release fact |
| mouseDownRight | fact | **DELETE** | — | F3: sole implementor is a world no-op; the hand's right-press bookkeeping (`@mouseButton = "right"`, the `expectedClick` climb) is untouched. Fallback option: `secondaryPressed` |
| mouseUpRight | fact | **DELETE** | — | F3: zero implementors. Fallback: `secondaryReleased` |
| mouseMove | fact | **hoverMove** + **pressedMove** | R2, §2.4 | the one channel that SPLITS |
| mouseEnter | fact | **hoverEnter** | `()` | pointer-under lifecycle |
| mouseLeave | fact | **hoverLeave** | `()` | ditto (incl. the injected handler, F9) |
| mouseEnterfloatDragging | fact | **DELETE** | — | F3: zero implementors. Fallback: `hoverEnterWhileCarrying` |
| mouseLeavefloatDragging | fact | **DELETE** | — | F3: zero implementors. Fallback: `hoverLeaveWhileCarrying` |
| nonFloatDragging | fact | **KEEP** | — | already device-neutral and grammar-named (the in-place drag channel); renaming it buys nothing this arc is for. The layering allowlist (F10.3) then stands unchanged |
| endOfNonFloatDrag | fact | **KEEP** | — | ditto |
| mouseClickLeft | gesture | **activated** | `(pos, …, isPartOfDouble, isPartOfTriple)` | the certified click |
| mouseDoubleClick | gesture | **doubleActivated** | `(pos)` | folded multi-click |
| mouseTripleClick | gesture | **tripleActivated** | `(pos)` | exists (2 defs) |
| mouseClickRight | gesture | **contextMenuRequested** | `(pos)` | R1, §2.3 — the certified context gesture, BOTH triggers |
| wheel | gesture | **scrolledBy** | `(deltaX, deltaY, deltaZ, altKey, button, buttons)` | "a scroll step was asked of you"; the DOM `"wheel"` listener strings, `WheelInputEvent`, `processWheel` and the macro `wheel` verbs all STAY (F15) |

Reading-risk note for the owner at OD1: `pressed`/`released` can read as state QUERIES
(`isPressed?`) rather than event hooks. The tree's collision check clears them (F17), and the
flat-fact rule favors them; if the owner prefers unambiguous hook-reading spellings, the
fallback pair is `pressLanded`/`pressReleased` — decide at OD1, one spelling, no aliases.
Hand-side names (`mouseButton`, `mouseDownWdgt`, `mouseOverList`,
`dispatchEventsFollowingMouseMove`, `reCheckMouseEntersAndMouseLeaves…`, `processDoubleClick`…)
are the hand's INTERNAL vocabulary, not the widget-facing surface — out of scope, recorded as
a BACKLOG tail candidate at close (a partial-rename argument does not apply across that
boundary; the widget-facing surface itself converts whole).

### 2.3 R1 — `contextMenuRequested` unifies the two triggers at the dispatch level (OD3)

Target: BOTH funnels dispatch the ONE widget verb, and the hand method stays the shared
consequence:

- `Widget.contextMenuRequested: (pos) -> world.hand.openContextMenuAtPointer @` (the renamed
  F6 base — its body is unchanged).
- Right-click funnel: unchanged shape — `processPointerUp` climbs to a `contextMenuRequested`
  implementor and calls it (`expectedClick = "contextMenuRequested"`).
- Hold funnel: `_advancePressAndHoldRecognition` REPLACES its direct
  `@openContextMenuAtPointer @mouseDownWdgt` with a dispatch of the SAME widget verb on the
  pressed widget (climb from `@mouseDownWdgt` until the implementor — every widget inherits
  the base, so the climb terminates immediately), passing `@_pointerPositionInPlaneOf(w)`.
  The `# public-call-sanctioned:` comment moves with it and now states the unification.

Consequence: a future `contextMenuRequested` override is reached by BOTH triggers — the seam
closes before it ever bites (F6: it is latent today, so this rider is **pixel-free for the
mouse suite and the finger suite alike**; the hold path reaches the identical code it
reaches today, one dispatch hop earlier). Witness (new test, new refs only): a fixture widget
overriding `contextMenuRequested` (e.g. counting invocations + opening the standard menu),
driven once by right-click and once by `syntheticEventsTouchHold_InputEvents` — both must hit
the override. Options at OD3: **(a) unify as above (proposed)**; (b) rename-only, keep the
hold's direct call and a comment documenting the seam — rejected-by-default because it
preserves the one real behavioral trap the current naming hides (§4).

### 2.4 R2 — split `mouseMove`'s two meanings into `hoverMove` / `pressedMove` (OD4)

The hand already distinguishes the meanings internally (F7's `pressedMovesAreWithheld` gate,
the grammar's third consumer). The split makes the boundary STRUCTURAL:

- **`hoverMove(pos)`** — dispatched from `dispatchEventsFollowingMouseMove` to the over-list
  when NO button is down (and never while `_pointerIsAbsent`).
- **`pressedMove(pos, button)`** — dispatched (i) from `determineGrabs` to `topWdgt` (the
  pre-grab site, today's one-arg call — now passing `@mouseButton` too), and (ii) from
  `dispatchEventsFollowingMouseMove` to the over-list when a button IS down and the stroke
  means a mouse drag. The `button` parameter stays A FACT (`"left"`/`"right"`): the current
  channel delivers right-pressed moves (paint preview branch, F8) and the split must not
  silently drop them. The unarmed-touch withhold becomes simply "no pressedMove is
  dispatched" — same gate, now visible in the channel name.
- **The F7 double-fire is PRESERVED verbatim in the mechanical step** (both sites dispatch,
  exactly as both dispatch `mouseMove` today) — de-duplicating the two pressed sites is a
  MEASURED follow-up inside the phase, taken only if the suite proves it pixel-free, and
  dropped without argument if it is not (it is not what this arc is for).
- **Faithful-then-tighten, per implementor** (the two-step rule — the mechanical step must be
  provably behavior-preserving BEFORE any body is simplified):
  1. Mechanical: every F8 implementor gets `hoverMove` and `pressedMove` derived from its old
     body — bodies that read `mouseButton` split along that branch (paint tools:
     `pressedMove` = the `'left'` paint arm with the shared clear/translate preamble,
     buttoned-else preview kept under its `button` test; `hoverMove` = the preview arm);
     bodies that ignored the button get the SAME body on BOTH channels (StringWdgt,
     ViewportWdgt, SliderButtonWdgt — their internal guards keep doing the discriminating,
     e.g. SliderButtonWdgt's pressed-state early-return). `TOOL_OFF_SOURCE` becomes the
     two-line no-op pair. The F12 test fixture becomes `box.hoverMove = …` (assertion-side,
     pixel-free).
  2. Tightening (same phase, per-implementor, each with its own suite discovery run +
     eyeball): drop the channel a body provably ignores (Example3DPlotWdgt → `pressedMove`
     only, its hover call is a no-op by its own `if mouseButton == 'left'`; candidates
     measured for the rest). A tightening that diffs ANY pixel is dropped, not argued with.
- Gate for the whole rider: `fg presuite` byte-identical (the paint tests —
  pencil/brush/eraser/toothpaste and the pencil-eye toggle family — plus the selection-drag
  and hover-highlight tests are the live witnesses; the rotated-island `mouseMove` test
  pins the R1-mapping through the new hover channel).

Options at OD4: **(a) the split as above (proposed)**; (b) rename-only (`pointerMove(pos,
button)`) — keeps the multiplex, fails the brief's tier rule for the one channel where the
two tiers of consumer (paint canvas vs hover chrome) genuinely collide; recorded as the
fallback if the split is falsified twice in execution (§0.5 stop rule).

### 2.5 What does NOT change (scope fence)

- The hand's ENTRY points and event family: `processPointerDown/Move/Up/Cancel`,
  `processWheel`, `PointerInputEvent`/`WheelInputEvent`, the queue, the recognizers.
- The DOM boundary strings (`addEventListener "wheel"`, pointer listeners) — browser API.
- The macro layer: L1/L2 verb names (`syntheticEventsMouse*`, `wheelOn_InputEvents`,
  touch verbs), all committed macro sources' verbs, test `tags`. (Decided twice; §8.)
- `nonFloatDragging` / `endOfNonFloatDrag` (§2.2), `openContextMenuAtPointer` (accurate,
  hand-side), `scrollByDragDelta`, the capability queries (`ownsDragsStartingOnMe`,
  `claimsPlainDragsForScrolling`), `escalateEvent` itself (only its 16 string ARGUMENTS
  move, F13).
- The Automator version: NO bump — the harness captures nothing differently; inspector-churn
  recaptures are per-test, standard (`fg recapture --auto`).

### 2.6 Batching law

A family lands in ONE verifiable batch per repo pair (the `*Morph`→`*Wdgt` precedent):
definitions + hand dispatches + escalateEvent strings + tests-repo script calls + the
family's rows in the THREE gate name-sets (F10), in the SAME commit (Fizzygum) with the
paired tests-repo commit landing together. During a batch the hand MAY dispatch
`w.newName?(…) ? w.oldName?(…)`-style fallbacks to keep intermediate states green — but
every fallback is gone by that batch's own commit (not merely by arc close): the §7
zero-grep for that family is part of the batch gate. ⚠ Do not lean on `check-dead-methods`
to police residue — F5: prose mentions in macro `.js` count as references there, so the gate
can NOT see an orphaned old-name definition this arc leaves; the enumerated F2/F11/F12/F13
site lists + the per-family `grep -rnw` are the real net.

### 2.7 Owner decisions this plan carries

| OD | question | options | decided at |
|---|---|---|---|
| OD1 | the full name table §2.2 (incl. `pressed`/`released` vs `pressLanded`/`pressReleased`) | table as proposed / amended spellings | plan review, before P1 |
| OD2 | dead channels: DELETE (proposed) vs rename-and-keep | per-row §2.2 | plan review |
| OD3 | R1 shape | (a) unify (proposed) / (b) rename-only | plan review; witness at P4 |
| OD4 | R2 shape + the `button` param + per-implementor tightenings | (a) split (proposed) / (b) rename-only | plan review; tightenings at P5 eyes-on |
| OD5 | EXECUTE NOW vs BACKLOG | go / park | on P0's measured numbers: total live-site count, the rehearsal's inspector-recapture set size, the ETA (§5) |

---

## §3 The axes (why this shape)

- **Tier-first, not device-first.** `pointerDown` would trade a device word for a plumbing
  word and still leave `pointerDown` vs `pointerClick` looking like siblings. The tier rule
  makes the guarantee the name: a widget author choosing between `pressed` and `activated`
  is choosing between "raw phase" and "certified gesture" — the exact decision the current
  names hide.
- **Guarantee-named gestures, use-named nothing.** The hand certifies "this meant an
  activation"; whether the consumer treats it as "chosen" is the consumer's business. This
  is the same doctrine as the intent-named public repaint verbs (no general-purpose verb,
  each name states what the CALLER knows).
- **Delete the dead channels.** Four names (F3) dispatch into nothing. Renaming them would
  launder dead API into the new vocabulary; deleting them is the only move consistent with
  the mandate — and reversible in a line if a consumer ever appears (the fallback names are
  reserved in §2.2).
- **Riders ride the rename, not the reverse.** R1/R2 are each one seam wide and land as
  their own phases with their own witnesses; the mechanical families around them stay
  pixel-free-verifiable. If a rider is falsified twice it falls back (§2.3/§2.4 options b)
  without dragging the vocabulary with it.

---

## §4 The distilled argument

Why now: the input program just closed — the grammar is fresh, gauntlet-green on BOTH pointer
kinds (the `finger` leg replays the whole suite through touch), and every dispatch site was
re-enumerated by that program's plans, so the surface is better-mapped today than it will be
again. The names are the LAST mouse-era stratum in a pipeline that is otherwise
kind-agnostic end to end, and the docs now teach the mismatch (`input-and-gestures.md` must
explain that "mouseClickLeft" means a certified, possibly-finger activation). The one
behavioral seam (F6) is latent ONLY because no `mouseClickRight` override exists yet; the
first person to write one inherits a hold-bypass bug nothing will flag. Why it will work
where "rename it all" was rejected in the gesture plan's §8: that rejection priced the
rename as churn "to express nothing the grammar needs" — correct THEN, mid-program; this arc
is the owner electing the churn for its own sake (vocabulary truth), and the measured price
(F2: ~300 live code sites across both repos, three gate sets, one string-source subsystem,
one rehearsal-measured inspector set) is a bounded, family-batched mechanical cost with a
proven de-risk pattern (Plan 3.5's P0 rehearsal measured a rename's suite exposure exactly;
its execution then matched the measurement).

---

## §5 Phases

Each phase: goal · steps · pixel budget · gate · ONE commit pair (src / tests repo as
touched), owner approval before each commit. **Recapture budget: P1–P3 = ONLY the
P0/discovery-measured inspector sets (declared per phase, eyeballed); P4–P5 = ZERO existing
references (new witness refs in P4 are created, not recaptured); P6 = zero.** The finger
baseline obeys the same budgets (its references live on the finger axis and replay the same
tests). Any diff outside a declared set = STOP.

### P0 — Re-verification + measurements + the rename REHEARSAL (~½ session-day; commits NOTHING)

1. `fg status`; confirm a green gauntlet for the current heads (run one in the background
   if the tree moved).
2. **Sonnet, read-only:** re-verify every §1 fact with its recorded command; report drift;
   the coordinator amends §1 dated before any P1 brief.
3. **Sonnet, measurements:** re-run the F2 census (the command block in §1); enumerate any
   NEW `?()` dispatch, string-keyed reference (`grep -rn '"mouse\|'\''mouse\|"wheel'` over
   src + buildSystem + scripts), `injectProperty`/`injectProperties` site, or handler-name
   string in a gate that appeared since authoring. Deliverable: the updated per-family site
   lists (the executor's rename checklists).
4. **Opus, the REHEARSAL (the Plan-3.5 P0(c) pattern, in-place-and-revert, never
   committed):** apply the P3-family rename (`mouseClickLeft` → `activated`, all F2/F11/F13
   sites incl. the three gate sets) as a spike; `fg build` must pass 28/28 (proves the gate
   edits + the sweep's completeness); run the full suite (`fg suite`); the failed array IS
   the inspector-churn set — record it per test + image + dpr, then `fg diffpage` and
   EYEBALL that every diff is member-list text. Revert by plain file restore (⛔ never
   `git stash` — standing rule). This measures the WORST family (36 defs, Widget prototype,
   9 escalate strings, 9 script calls); the other Widget-prototype families (P2's `pressed`,
   P4's `contextMenuRequested`) inherit the measurement method, not the numbers — each
   phase's discovery run declares its own set.
5. Findings + numbers into the STATUS box. **OD5 to the owner**: total live sites, the
   rehearsal set size, the §5 ETA — go / park.

### P1 — Hover facts + dead-channel deletions (~⅓ session-day)

One Opus worker. `mouseEnter`→`hoverEnter`, `mouseLeave`→`hoverLeave` (18 defs incl. the
mixin donations + the hand's `?()` dispatches + the `injectProperty "mouseLeave"` string in
`ImageWdgt` F9 + `HANDLER_NAMES`); DELETE `mouseUpRight`, `mouseEnterfloatDragging`,
`mouseLeavefloatDragging` (the hand's dispatch lines + comment roster + their `HANDLER_NAMES`
rows) and `mouseDownRight` per OD2 (the world's no-op def + the right-branch `actualClick`
climb — the down path keeps its right-press bookkeeping and simply dispatches no down-fact
for a secondary press; `POS_HANDLER_NAMES` rows go too).
**Pixel budget:** expected ZERO (no Widget-prototype member moves — F14) — but MEASURED: run
suite discovery; a non-empty set = declare + eyeball + recapture only if member-list-only.
**Gate:** `fg build` 28/28 (the three gate files edited in-commit); family zero-grep
(`grep -rnw` each old name over BOTH repos → archive/prose-only); `fg presuite`; `fg
menusweep` (hover affordances feed menus nothing, the sweep proves no throw). Commit pair.

### P2 — Press/release facts (~⅓ session-day)

Same worker. `mouseDownLeft`→`pressed` (12 defs incl. Widget + World + mixin; 4 escalate
strings; the hand's `actualClick` string + climb; 2 script calls in
`serialization-roundtrip-headless.js` + `smoke-boot-headless.js`; gate rows),
`mouseUpLeft`→`released` (4 defs; the `switch` dispatch; 2 script calls; gate rows).
**Pixel budget:** the discovery-measured inspector set (Widget-prototype member — expect the
rehearsal's shape, not its numbers). **Gate:** as P1 + `fg diffpage` on the declared set +
owner-visible crops if non-empty; recapture `fg recapture --auto --dprs=1,2` (⚠ BUILD FIRST
— standing memory rule); the `apps`+`parts`+`serialization` gauntlet legs at the phase-close
gauntlet prove the F11 script edits (the P9 class). Commit pair.

### P3 — Activation gestures (~⅓ session-day)

Same worker. `mouseClickLeft`→`activated` (the rehearsed family: 36 defs, 9 escalate
strings, hand strings/climbs, 9 F11 script calls incl. the `tagClass` string list,
gate rows), `mouseDoubleClick`→`doubleActivated` (3 defs + `escalateEvent
"mouseDoubleClick"` + `processDoubleClick`'s climb), `mouseTripleClick`→`tripleActivated`
(2 defs + climb). **Pixel budget:** exactly the P0 rehearsal set (one more or fewer test =
STOP). **Gate:** as P2; the rehearsal already proved the build accepts this family. Commit
pair.

### P4 — R1: `contextMenuRequested` (~⅓–½ session-day + owner eyes on the witness)

Same worker. `mouseClickRight`→`contextMenuRequested` per §2.3 (1 def + the hand's
`expectedClick` strings + gate rows), the hold funnel re-pointed through the widget verb;
author the two-trigger override witness test (`/author-macro-test` skill, new refs only,
dpr 1+2 + visualisation page). **Pixel budget:** ZERO existing refs (F6: latent seam, both
paths reach identical code); the witness's own refs are new files. **Gate:** as P1 +
`fg gauntlet` green incl. `finger` (the hold funnel is the finger's context-menu path —
this phase is the one that could regress it) + the witness verified at both dprs. Commit
pair.

### P5 — R2: the move split (~½–¾ session-day)

Same worker, two steps in one phase per §2.4: mechanical faithful split (both dispatch
sites, 4 method defs, the 5 tool-source strings + `TOOL_OFF_SOURCE`, the F12 fixture,
gate rows: `mouseMove` row → `hoverMove` + `pressedMove` in BOTH name-sets), then the
measured per-implementor tightenings. **Pixel budget:** ZERO (each tightening that diffs is
dropped). **Gate:** `fg build`; family zero-grep; `fg presuite` byte-identical ×2 (once
after the mechanical step, once after tightenings); eyes on the paint-family and
selection-family tests' verdicts specifically; phase-close `fg gauntlet`. Commit pair.

### P6 — `scrolledBy` + docs weave + prose sweep + arc close (~½ session-day)

1. `wheel`→`scrolledBy` (2 defs, the hand's climb + call in `processWheel`, 3 escalate
   strings, `HANDLER_NAMES` row; the F15 traps STAY — DOM strings, `WheelInputEvent`,
   `processWheel`, macro verbs, tags). Pixel budget ZERO.
2. **Docs weave (Sonnet ×N, disjoint files):** the F18 living set — rewrite the vocabulary
   as present-tense truth (never a "renamed from" narration; the old names appear once each
   in `input-and-gestures.md`'s provenance note at most). `docs/archive/` +
   `docs/measurements/` untouched (bucket law).
3. **Tests-repo PROSE sweep (Sonnet, enumerated):** update handler-name mentions in test
   `intent`/`provenance`/`assertions` strings + macro comments (F2's prose columns, ~120
   files) — they document the tests and must state the live vocabulary; `tags` arrays may
   keep topical labels (owner's call in the brief review, default: update `"wheel"`-like
   tags only where they named the handler, not the gesture). Pixel-free by construction
   (metadata strings; `fg lint` for JS syntax).
4. **Arc-close gate:** the §7 full battery + the FINAL zero-grep (every old name, both
   repos, `--include` all extensions: hits ONLY under `docs/archive/`); confirm no `?()`
   fallback survived (grep the hand for every old name). `git mv` this plan to
   `docs/archive/` + stamp + `INDEX.md` line; BACKLOG line for the hand-internal vocabulary
   tail (§2.2); memory topic note; close-arc ritual (commit proposals, owner approval,
   ask-before-push).

**ETA (owner preference: upfront):** P0 ½ + P1 ⅓ + P2 ⅓ + P3 ⅓ + P4 ⅓–½ + P5 ½–¾ + P6 ½
≈ **2¾–3¼ session-days**, plus owner review points (OD1–OD4 at plan review; OD5 after P0;
witness eyes-on at P4; recapture-set eyeballs at P2/P3). Status updates every ~5 min during
long ops (standing preference).

---

## §6 Central risks and how each is bounded

| risk | why real | bound |
|---|---|---|
| A missed `?()` site silently kills a behavior (hover highlight, enter/leave) | F5: no static gate sees an optional or paren-less send of a dangled name | the F2/F11/F12/F13 enumerated lists ARE the edit checklist; per-family zero-grep in the SAME batch; presuite pixels as the behavioral net (hover/highlight/selection are heavily screenshot-covered) |
| Inspector member-list churn bigger than expected | F14: three families touch Widget's prototype; mixin donations double rows | P0 REHEARSAL measures the worst family exactly (the 3.5 pattern); per-phase discovery runs declare each set; owner sees crops; recapture only member-list-only diffs |
| The paint-tool string sources drift from the split (R2) | F9: handlers defined in STRINGS, invisible to header-greps; the double-fire (F7) is load-bearing for the preview | the tool sources are enumerated sites in P5's checklist; faithful-then-tighten with presuite between the steps; paint tests are the witnesses |
| Scripts-repo breakage invisible to the suite | F11 + P9 case law: `apps`/`parts`/`serialization` rigs drive `index.html` | script edits land in the same batch; the phase-close gauntlet runs those legs |
| R1 changes hold-menu behavior on finger | the hold funnel is re-pointed | F6: both funnels reach identical code today ⇒ pixel-free claim is testable — `finger` leg at P4's gauntlet + the two-trigger witness |
| Old vocabulary re-enters via muscle memory / docs | 42 docs files + hundreds of prose mentions teach the old names (the evalstring lesson: an INSTRUCTION is a root cause) | P6 rewrites every LIVING doc; the three gate name-sets hold only new names, so an old-name handler is no longer gate-scanned (visible in review) and the arc-close zero-grep is the ratchet's floor |
| Serialized `<name>_source` fields in user files | F9: injected handlers ride snapshots | standing owner rule: NO serialization compat obligations; no committed asset carries one (verified) |

---

## §7 Verification protocol

- **Per batch:** `fg build` (28/28 — includes the three edited gate files running on the
  renamed tree) · family zero-grep: `grep -rnw "<oldName>" Fizzygum Fizzygum-tests
  --include="*.coffee" --include="*.js" --include="*.json"` → hits only in `docs/archive/`
  and (until P6) prose · `fg presuite` — byte-identical except the phase's declared set.
- **Per phase close:** `fg gauntlet` (19 legs incl. `finger`), backgrounded, verdict read
  from `/tmp/fg-gauntlet.verdict` — never through a pipe. `fg menusweep` verdict
  specifically after P3 (every menu item still dispatches through the renamed activation
  path) and `fg pinsweep` after P4.
- **Recaptures:** only within a declared, eyeballed set; `fg recapture --auto --dprs=1,2`
  on a FRESH build; `check-refs`/`check-visualisations` ride the next build.
- **Arc close:** the P6 battery + `fg homepage` (production tree round-trip — the injected
  `hoverLeave`/tool sources ride a snapshot there) + the final all-names zero-grep + a
  read-through of `input-and-gestures.md` against the shipped hand (the doc IS the contract
  now).

---

## §8 Rejected alternatives — do not re-attempt

- **Aliases / a facade (old names forwarding to new)** — two names for one fact WILL
  disagree; the `nil` retirement is the case law (a convenience alias became load-bearing,
  leaked into emitted source, and cost a gated eradication arc). The mandate bans it.
- **Partial rename (only the "worst" names)** — a mixed vocabulary is worse than either
  pole: the tier boundary this arc exists to mark would run THROUGH the vocabulary.
- **Device-neutral-but-intent-free names (`pointerDown`, `pointerClick`)** — trades a device
  word for a plumbing word and gains nothing; the tier rule is the point (§3).
- **Renaming the L1 macro verbs / macro sources' vocabulary** — the verbs are the TEST-side
  intent layer the finger mode translates UNDER; decided twice (Plan 2 §2.6, Plan 4 P3) and
  confirmed here: 300+ committed macros stay.
- **Renaming `nonFloatDragging`/`endOfNonFloatDrag` "while we're here"** — already
  device-neutral, grammar-named, and pinned by a layering allowlist; churn with no tier
  gain. (Revisitable as its own request.)
- **A deprecation window / transitional double-dispatch left in the tree** — the fallback
  is a batch-internal tool only (§2.6); left standing it is an alias with extra steps, and
  F5 shows no gate would ever flag its residue.
- **An Automator version bump "to be safe"** — the version means "what the harness
  captures"; nothing captured changes. A needless bump obliges a full recapture
  (tests-repo CLAUDE.md's letter).
- **Trusting `check-dead-methods` to police residue** — F5/F13: prose in macro `.js` counts
  as a reference there; the zero-grep is the real gate. (Recorded so nobody "verifies" with
  the wrong instrument.)

---

## §9 Delegation map — coordinator and workers

The coordinator (the session) never edits source and never runs suites in-line; it briefs,
reads reports, checks verdict files, decides at gates, hosts the OD reviews, and talks to
the owner. Workers are fresh `Agent` calls, `subagent_type: general-purpose`, `model:
"opus"` for phase work, `"sonnet"` for enumerated mechanical/read-only work. ⛔ Never
`fork`, never `isolation: worktree`. ONE code worker at a time; parallel workers only for
read-only P0 sub-steps and P6's disjoint docs files.

### 9.1 Per-phase map

| phase | worker | parallel? | brief = this plan's §§ plus | gate the worker runs | coordinator decides |
|---|---|---|---|---|---|
| P0 facts+census | Sonnet ×1 | yes (read-only) | §1's commands | none | amends §1 dated |
| P0 rehearsal | Opus ×1 | no (suite runs) | §5 P0.4, §1 F2/F10/F11/F13 | `fg build`, `fg suite`, diffpage | records the set; hosts OD5 |
| P1–P5 | Opus ×1 each | no | the phase §, §2.2's rows, the family site lists from P0 | per-phase §5 gates | verdict lines; declared-set eyeballs; commit proposal to owner |
| P6 rename step | Opus ×1 | no | §5 P6.1, F15's traps | as P1 | commit proposal |
| P6 docs+prose | Sonnet ×N | yes (disjoint files) | F18 / P6.3 lists | `fg lint`, doc-narration | reviews diffs |
| P6 close | coordinator | — | §7 arc close | `fg gauntlet`, `fg homepage` | archive move, BACKLOG, memory, owner ritual |

### 9.2 The worker brief (template — copy, fill the ⟨⟩, nothing else)

```
You are executing ⟨phase⟩ of Fizzygum/docs/plans/widget-input-vocabulary-plan.md.
Read that plan's §0, §0.5, §1, §2 and §⟨phase⟩ in full, then Fizzygum-all/CLAUDE.md,
Fizzygum/CLAUDE.md and Fizzygum-tests/CLAUDE.md. All commands through
/Users/davidedellacasa/code/Fizzygum-all/fg by absolute path. Probes under
Fizzygum-tests/.scratch/.
Do: ⟨the phase's step list⟩, editing ONLY the enumerated site list handed in this brief
(from §1 F2/F5/F9/F10/F11/F12/F13 as re-verified in P0). Edits via the Edit tool — never
perl/sed blanket passes. The three gate name-sets (check-raw-pointer-reads HANDLER_NAMES,
check-plane-discipline POS_HANDLER_NAMES, check-layering's allowlist) move in the SAME
commit as the family. Any batch-internal `?()` fallback you add must be deleted before the
batch's own gate runs.
Gate: ⟨exact fg commands⟩ → expected ⟨verdicts⟩, plus the family zero-grep
(`grep -rnw "⟨oldName⟩" Fizzygum Fizzygum-tests` → archive/prose-only). Launch long ops
with run_in_background and wait for the notification; never poll; never pipe a gating call.
Pixel budget: ⟨ZERO | exactly the declared set: …⟩. Any diff outside it = STOP (rule §0.5.5).
No Automator version bump, ever. The DOM "wheel" listener strings, WheelInputEvent,
processWheel, and every macro-verb name are OUT OF SCOPE (plan §2.5).
Stop and report (do not improvise) if: a §1 fact is false; a fix shape is falsified twice; a
gate fails for a reason you cannot state in one sentence; a diff appears outside the budget;
you need a decision §2.7's rulings do not cover. Never capture references without the
coordinator's approval, never commit, never push.
Comments you write: present tense only, no history narration; `undefined` is the one
absence value.
Report (≤ 60 lines): files changed (git diff --stat, BOTH repos); each gate's literal
/tmp/fg-<cmd>.verdict line; the zero-grep tail; counts (sites edited per name); tests
added/changed + capture verdicts; open questions; which stop rule fired, if any.
```

### 9.3 What the coordinator checks on every report (cheap, never a re-do)

1. `cat /tmp/fg-<cmd>.verdict` for each claimed gate — the literal line, not prose.
2. `git -C <repo> diff --stat` in BOTH repos — the file list matches the phase's enumerated
   surface (a stray file is a question; gate-file edits present in every rename phase).
3. The family zero-grep re-run by the coordinator's own hand (it is one command).
4. Declared-set phases: the diffpage was eyeballed BEFORE any recapture, and the owner saw
   the crops (P2/P3) / the witness (P4).
5. A stop rule fired → read only the quoted evidence; amend §1 dated; re-brief. Two stops
   on one step → re-frame, never a third variant.
6. Then: the commit proposal to the owner (message drafted via `git commit -F` file — ⛔
   backticks corrupt Bash-written messages), or the next brief.

---

## §10 References

- Living truth this plan renames on top of:
  [`../architecture/input-and-gestures.md`](../architecture/input-and-gestures.md) ·
  [`../architecture/widget-authoring-guidelines.md`](../architecture/widget-authoring-guidelines.md) §9 ·
  [`../architecture/viewports-and-planes.md`](../architecture/viewports-and-planes.md) ·
  [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md)
  (F10's gates; the unresolved-sends/dead-methods reach limits).
- The deferral + the grammar this surface fronts:
  [`../archive/gesture-grammar-and-finger-harness-plan.md`](../archive/gesture-grammar-and-finger-harness-plan.md)
  (§8 the deferral; §2.2 the grammar table; STATUS = the finger baseline + 19-leg gauntlet)
  · [`../archive/pointer-events-plan.md`](../archive/pointer-events-plan.md) (the event
  family) · [`../archive/frames-input-touch-program.md`](../archive/frames-input-touch-program.md)
  (rulings I2/H1/H2/G1).
- The de-risk pattern this plan copies:
  [`../archive/command-panel-unification-plan.md`](../archive/command-panel-unification-plan.md)
  — P0(c) the rename rehearsal (spike → suite → declared set → revert); §9 the delegation
  shape.
- Rename case law: the `*Morph`→`*Wdgt` migration note (`Fizzygum/CLAUDE.md` — one family,
  one batch; a rename is not always pixel-free) · connector P9 (`@target` — grep
  `Fizzygum-tests/scripts/`) · the `nil` retirement (aliases; an instruction as root cause)
  · `../archive/public-private-call-separation-plan.md` (renames churn the inspector).
- Harness doctrine: `Fizzygum-tests/CLAUDE.md` (reference grammar, BUMP discipline, the
  `*TestSupport` installOnto pattern) · `Fizzygum-tests/DETERMINISM.md` ·
  `src/macros/CLAUDE.md` + `MACRO-PATTERNS.md` (the layer rules — macros drive the queue,
  never the hand).
- Standing owner preferences the executor must hold: ask before commit/push; upfront ETA +
  ~5-min status on long ops; no conclusions before evidence; stop after two falsified
  fixes; recapture churn must not dictate design; comments/docs are a deliverable,
  present-tense only.

---

### Start-prompt for a fresh coordinator session (copy-paste)

```
You are coordinating the widget-input-vocabulary rename arc for Fizzygum.
Read /Users/davidedellacasa/code/Fizzygum-all/CLAUDE.md, Fizzygum/CLAUDE.md,
Fizzygum-tests/CLAUDE.md, then Fizzygum/docs/plans/widget-input-vocabulary-plan.md IN FULL.
Then: run /Users/davidedellacasa/code/Fizzygum-all/fg status; verify the plan's §1 tree
state still holds (heads, gauntlet-green baseline) and check the STATUS box for the next
open phase. The plan's owner decisions OD1–OD4 must be RULED before P1 — if the STATUS box
does not record rulings, present §2.2/§2.3/§2.4/§2.7 to the owner first and record the
rulings dated in the STATUS box. Then execute the next open phase per §5 under the §9
delegation model (you brief workers; you never edit src; owner approval before every
commit; never push without asking). Every §1 fact is a hypothesis — P0 re-verifies before
anything is edited.
```
