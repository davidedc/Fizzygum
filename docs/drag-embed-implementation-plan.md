# Plan — drag-embed dwell-to-arm: spikes + phased implementation

**Status: SPIKES ✅ COMPLETE (findings §2), PHASES 1-6 NOT STARTED — START AT PHASE 1** (authored 2026-07-06;
tree at Fizzygum `b91cd9b5` / clean master, suite = 181/181 green, verified). Canonical DESIGN lives in
**`docs/specs/drag-embed-interaction-spec.md`** — every product decision there is owner-approved and LOCKED
(read the spec FIRST, in full; §6 carries the post-spike dwell-mechanic revision record); this file adds
execution structure: spike findings, phases, touch-lists, gates. **Line numbers drift: grep the named
symbol.** The two docs (spec + this plan) are currently UNTRACKED — propose committing them with Phase 1.

## §0a — EXECUTOR CONTRACT (binding working rules; a cold executor has no other source for these)

1. **NEVER commit or push autonomously.** End each phase with: what landed, gate results (actual numbers),
   deviations, proposed commit message — then WAIT for owner approval. Write commit messages to a file and
   `git commit -F <file>` (backticks/`$()` inside a double-quoted `-m` get command-substituted by the shell).
   Fizzygum and Fizzygum-tests commit in LOCKSTEP when both change.
2. **Gates.** Every phase: `./fg gauntlet` from the umbrella root (build + dpr1 + dpr2 + webkit ×181 + apps +
   gates). Phases that touch serialization or defaults additionally run the serialization legs + `./fg
   homepage` (boot check). A pass = completed:true + all shards N/N + failed:0. A test failing with ZERO
   failed screenshots = an uncaught error → shard stall, not a pixel diff. A single dropped shard under heavy
   churn is a known infra flake — re-run FRESH once before diagnosing. Debug one test:
   `./fg test <name>`; divergent-pixel capture: `cd Fizzygum-tests && node
   scripts/run-macro-test-headless.js SystemTest_<name> --dump-failures` (dumps PNGs under
   `Fizzygum-tests/.scratch/<test>/`). NOTE: the parallel suite runner forwards page `console.error` ONLY —
   `console.log` is invisible in suite logs.
3. **Recaptures.** Use the FULL `./fg recapture <name>` flow (never a hand-rolled `--clean`/`--no-build` —
   known multi-image skip trap). Benign inspector-member-list recaptures are pre-authorized by the owner;
   NEVER contort code to avoid one — clean code wins. After ANY recapture the webkit leg must be re-verified
   (a recapture can bake a crash frame into the references; Chrome then passes vacuously and only webkit
   surfaces it).
4. **No conclusions before evidence.** Never write "byte-identical"/"safe"/"0 recaptures" into a comment,
   doc, or commit message before the gate that proves it has actually passed.
5. **Stop conditions.** (a) Two falsified fix-shapes on one problem → STOP, reframe with the owner — do not
   try a third mechanism variant. (b) The revised dwell mechanic (spec §6) has 1 of its 2-falsification
   budget spent — NEW evidence against it means STOP and consult, not iterate. (c) Any behavior change
   outside the spec's scope → ask first.
6. **Hygiene.** Never edit `Fizzygum-builds/**` (regenerated wholesale); never grep from the workspace root
   (builds dir is ~1.3GB); `nil` not null/undefined; one class per file, filename = class name; no imports —
   classes are globals, and the dependency finder regex-scans for literal `extends X` / `new X` forms, so use
   them; the ephemerals/product code goes in the SHIPPED paths (no `if Automator?` guard, no
   homepage-excluded block). A PreToolUse guard hook blocks wrong-cwd build/test invocations — route
   everything through `./fg`. State an upfront ETA for long operations and post status every ~5 minutes.
7. **Record progress IN THIS FILE**: append a dated LANDED-STATUS line per phase (commit hashes, gate
   numbers, deviations) under the phase's heading, dataflow-arc style.

## §0 — Orientation (self-contained)

**Fizzygum** = CoffeeScript GUI framework on one `<canvas>` (Morphic descendant). Umbrella
`/Users/davidedellacasa/code/Fizzygum-all/` (NOT a git repo) holds siblings `Fizzygum/` (source),
`Fizzygum-tests/` (181 byte-exact screenshot macro SystemTests), `Fizzygum-builds/` (generated — never edit).
`nil`==`undefined`; one class per file; no imports. Commands from the umbrella root: `./fg build` · `./fg suite
[--dpr=2|--browser=webkit]` · `./fg gauntlet` (build + dpr1 + dpr2 + webkit + apps + gates) · `./fg test
<name>` · `./fg recapture <name>`. Determinism doctrine (`Fizzygum-tests/DETERMINISM.md`): input/layout/render
= pure function of the EVENT STREAM; wall-clock is a known bug-class (the 300ms `doubleClickWindowMs`
event-time gate is the template; the 500ms `Date.now()` autoscroll dwell is the documented anomaly). New
macros are authored via the `/author-macro-test` skill in `Fizzygum-tests`.

**What we're building (one paragraph; full spec in `docs/specs/drag-embed-interaction-spec.md`):** delete the
source-side "internal/external" droppable precondition (`@internal` becomes derived "am I nested"; the switch
becomes an eject button on nested windows); destination edit/view mode is the single gate; WINDOW payloads
embed only after dwell-to-arm (450ms of ELAPSED EVENT-TIME within a 7px linger circle, evaluated per event
incl. the release; >7px moves re-anchor the origin — REVISED post-S2, spec §6 revision record; armed latches
inside the same candidate; innermost-candidate rule at all depths; cursor anchor); plain-widget drops stay
instant everywhere they work today; view-mode destinations never accept mid-drag — lock cue, OFFSET landing
(24px), and a land-and-offer pill ("Insert" / "Edit & insert"); release-before-armed = plain move-over + a
one-line teaching hint; wheel-mid-drag scrolls the destination while elapsed keeps growing; all non-interactable visuals are EPHEMERALS (the declare-and-reconcile
`HighlighterWdgt`/pinout overlay system); pencil↔eye SwitchButton; dashboards default edit-ON.

## §1 — FRESH anchor table (verified 2026-07-06 on `b91cd9b5`)

| Symbol | Location |
|---|---|
| `WindowWdgt.wantsToBeDropped` (`return @internal`) | `src/WindowWdgt.coffee:256-257` |
| `makeInternal` / `makeExternal` | `WindowWdgt.coffee:177, 182` |
| `editButtonInBarPressed` · `makePencilYellow`/`makePencilClear` · `createAndAddEditButton` · `createAndAddInternalExternalSwitchButton` | `WindowWdgt.coffee:228 · 536/543 · 550 · 525` |
| Window drop-acceptance lifecycle (`disableDrops` full / `enableDrops` empty) | `WindowWdgt.coffee:130, 421 / 398` |
| `@internal` reads | `WindowWdgt.coffee:106(ctor), 109, 178-184, 257, 272(title skin)` |
| `ActivePointerWdgt.drop` (the `wantsToBeDropped`→world forcing + target resolution + add + reactions) | `ActivePointerWdgt.coffee:247-287` (forcing at `:252`) |
| `dropTargetFor` (release-time climb) · `topWdgtUnderPointer` (+ ephemeral markers) | `ActivePointerWdgt.coffee:154 · 87-110 (markers :105-106)` |
| `dispatchEventsFollowingMouseMove` (per-move dispatch; UNIMPLEMENTED `mouseEnterfloatDragging` at `:950`; autoscroll trigger + `wantsToBeDropped` gate at `:957-961`) | `ActivePointerWdgt.coffee:933-963` |
| `doubleClickWindowMs` event-time pattern | `ActivePointerWdgt.coffee:21-28, 488-616` |
| `processWheel` (no drag gate) | `ActivePointerWdgt.coffee:721-726` |
| `grabOrigin` — **WRITE-ONLY today** (set `:196, :830`, read nowhere; no Esc-cancel of drags exists anywhere in src) | `ActivePointerWdgt.coffee:16, 196, 830` |
| Base predicates: `_acceptsDrops:false` · `wantsDropOfChild` · `wantsToBeDropped` | `Widget.coffee:122 · 2887 · 2893` |
| Grab chain: `grabsToParentWhenDragged` · `findFirstLooseWidget` · `detachesWhenDragged` | `Widget.coffee:2710 · 2742 · 2806` |
| `turnOnHighlight`/`turnOffHighlight` (ephemeral producer API) | `Widget.coffee:1845-1855` |
| `grabDragThreshold: 7` | `PreferencesAndSettings.coffee:54` |
| Ephemeral reconciler: `addHighlightingWidgets` (shipped) · `addPinoutingWidgets` (homepage-EXCLUDED debug) · call sites pre-`updateBroken` · `widgetsToBeHighlighted` set | `WorldWdgt.coffee:1272 · 1245 · 1442-1444 · 214` |
| `HighlighterWdgt` (`skipsAddShadowManagement`) | `src/HighlighterWdgt.coffee` |
| Edit/view family: `providesAmenitiesForEditing` · `editButtonPressedFromWindowBar` · `_enable/_disableDragsDropsAndEditingNoSettle` | `StretchableEditableWdgt.coffee:20 · 111 · 132/172` |
| Autoscroll dwell (wall-clock anomaly) · `ScrollPanelWdgt.wheel` (chaining `escalateEvent`) | `ScrollPanelWdgt.coffee:675-708 · 761-830` |
| Dashboard's view-mode default to flip | `SampleDashboardApp.coffee:120` (`slideWdgt.disableDragsDropsAndEditing()`) |
| `BasementOpenerWdgt.wantsToBeDropped` (KEEPS its override) | `basic-widgets/BasementOpenerWdgt.coffee:60` |
| World snapshot roots = **ALL world children** (ephemerals NOT auto-excluded; per-class `@serializationTransients` protocol exists for props) | `serialization/Serializer.coffee:81-100 (roots loop) · 27-45` |
| Ctor-arg retirement blast radius: `new WindowWdgt nil, nil, …` sites | **56** (grep count) |

Two spec VERIFY items now CLOSED: (a) **Esc-cancel does not exist** — `grabOrigin` is dead state; any
snap-back/cancel is NEW functionality → OUT OF SCOPE (offset landing suffices; banked). (b) **Serializer
walks all world children** → ephemeral exclusion must be EXPLICIT (Phase 1 adds it via the `isEphemeral`
capability at root collection; witnessed by a snapshot-with-live-highlight probe).

## §2 — Phase 0: SPIKES (throwaway, no commits; findings appended HERE before Phase 1 starts)

Each spike is a falsifiable question, run on a scratch working tree (`git checkout -- .` / stash to revert;
nothing merges). Owner sees findings before any phase code.

> ### ✅ FINDINGS (2026-07-06 — S1 + S3 RUN; S2 instrumented, awaiting the owner's hardware pass)
> Clean baseline first verified green (181/181, 1.33 min). Source fully reverted after (the probe build may
> still sit in `Fizzygum-builds/latest` until the next build; the full probe code is inlined in APPENDIX A
> for instant re-creation — e.g. to re-check visual feel before Phase 2's styling).
>
> **S3 — blast radius: SMALLER than predicted. Exactly ONE test depends on the internal/external gate.**
> `wantsToBeDropped -> true` + full suite → **1 failure: `macroInternalVsExternalWindowDrop`** (3 frames,
> pure pixel semantic change — the external window now nests; re-run singly: no errors). The OTHER
> window-drop macros all use internal windows and passed untouched. **⚠ READ THE SCOPE PRECISELY: S3
> measured the GATE REMOVAL only (external windows becoming droppable). The DWELL ADDITION is a separate
> delta with the opposite sign: once Phase 3 requires arming, every macro that today drops a WINDOW payload
> into a container WITHOUT lingering will land on the world instead — spec §13's changed-list
> (`macroInternalWindowDroppedIntoWindowFits`, `macroWindowWithAClockInAWindowConstructionTwo`,
> `macroResizeWindowContainingInternalWindow`, `macroClosingInnerWindowKeepsOuter`, …) is the PREDICTION for
> those; Phase 3 re-enumerates empirically (flip + dwell in place, run suite, fix the failures by inserting
> synthesized linger time ≥ DWELL_ARM_MS before each window-drop release).**
> A scary `recalculateDataflow` stack trace in the suite log was chased and ATTRIBUTED: it is
> `macroSpreadsheetErrorPropagation`'s DELIBERATE `ReferenceError: boom` (#ERR-propagation test), present on
> the clean baseline too, test passes — unrelated. **`@internal` audit: ZERO consumers outside
> `WindowWdgt.coffee`** (call sites pass it positionally at construction only) — the Phase 5 derivation has
> no hidden dependents. `internal` is a ctor-assigned own-prop → presumed captured in snapshots as an
> ordinary record field (Phase 5: derive-on-restore).
>
> **S1 — live candidate highlight: WORKS, cheap, and the recapture exposure is TINY.**
> Probe = `dropTargetFor` climb per move in `dispatchEventsFollowingMouseMove` (world excluded) + declare
> into `widgetsToBeHighlighted`. Suite with probe: **only 3 tests screenshot mid-drag over a candidate**
> (`macroCompositeDragsAsUnitIntoScrollPanel`, `macroListWdgtAutoScrollsNearDraggedEdge`,
> `macroSubMenuDroppedIntoPanelPinsItself`) — ALL plain payloads, **ZERO window-drag tests** → Phase 2's
> always-on candidate highlight costs ~3 recaptures; window-payload-only visuals cost ~0. Suite wall-clock
> with the per-move climb: 1.32 min vs 1.33 baseline — **no measurable cost**. Visual artifact captured
> (`Fizzygum-tests/.scratch/SystemTest_macroSubMenuDroppedIntoPanelPinsItself/dpr1/…png` via
> `--dump-failures`): highlight renders mid-drag, on top, correct candidate. **Style verdict: the default
> whole-target blue wash is far TOO LOUD for a drag affordance — §11's outline style channel is REQUIRED,
> not cosmetic.** (Candidate-change flicker: not assessable headless; owner eyeballs it in the probe build.)
> NOTE: the suite runner forwards only `console.error` — probe `console.log` lines are invisible in suite
> logs (single-test runner + live browser show them fine).
>
> **S2 — ✅ RUN by the owner (2026-07-06). VERDICT: GAP-CREDIT FALSIFIED; mechanic REVISED (spec §6 revision
> record).** 9 drags of telemetry. Two sincere still-holds: `finalStillGap=3762ms / 3644ms` with all-zero
> move gaps beforehand — **a genuinely still mouse emits ZERO move events**; per-event credit freezes during
> the hold (`gapCreditTotal` stuck at 373/265ms, earned in the approach), and the release top-up would have
> made the two holds INCONSISTENT (373+100 arms, 265+100 doesn't). Same data VALIDATES the elapsed-time
> measurement itself: `finalStillGap` IS `release.time − lingerOrigin.time`, captured both holds exactly;
> flowing quick releases measured 15-72ms (would never arm). Secondary: during motion gaps are ~0ms
> (median 0, under100=100% in all 9) — event.time is coarse/coalesced mid-motion, harmless to the revised
> design. S1 candidate transitions in the same session were clean (panel↔none), no flicker storms.
> **REVISED MECHANIC (the one pre-authorized reframe; falsification count = 1, do NOT iterate further
> without new evidence): DECISION = elapsed event-time since the linger origin ≥ 450ms, evaluated at every
> event incl. the release; >7px moves re-anchor the origin. FEEDBACK = the ring as a STEPPING ephemeral on
> the analog-clock pattern (`AnalogClockWdgt.coffee:99-108`: wall-time animation in production,
> `Automator.animationsPacingControl` virtual pacing under tests — the SAME mechanism that keeps live clocks
> byte-exact in the suite today).** Still-holds arm; transits never arm; the ring visibly fills during a
> sincere hold because cycles never stop, so armed releases are never a surprise.

### S1 — Feel probe: live candidate tracking + highlight (~0.5 day)
Wire the `dropTargetFor` climb into `dispatchEventsFollowingMouseMove` for float-drags and declare the
resolved candidate into `world.widgetsToBeHighlighted` (raw blue fill is fine for the probe).
**Questions:** per-move cost of the climb (imperceptible? measure); does the reconciler's
`hasMaybeChangedPaintBounds` repositioning track a wheel-scrolled destination as §6.1 predicts; does
cursor-anchored innermost-candidate resolution FEEL right dragging over slide → nested panel → empty window;
does the highlight flicker when crossing candidate boundaries (reconciler churn)?
**Falsifies:** the §5 candidate-resolution UX and the free-tracking claim. **Deliverable:** findings + (if
possible) a short screen recording for the owner.

### S2 — THE critical unknown: real event streams vs. GAP-CREDIT (~0.5 day)
Gap-credit assumes a "still" hover produces a STREAM of input events (hand tremor) whose gaps are mostly
< 100ms. **A physically dead-still mouse produces ZERO mousemove events → never arms.** Instrument
`processMouseMove` (log event-timestamp gaps during held-button hovers), test on real hardware: mouse
(still-as-possible + natural hold), trackpad (finger resting; finger lifted), and under the Automator at
`speed=fastest`. **Decision rule (per the stop-after-2-falsifications memory): if natural mouse-holds fill
450ms of credit within ~1s of real time → gap-credit STANDS. If not, do NOT iterate constants; reframe once:**
fallback = the SATURATION-EXCEPTION shape (autoscroll precedent, `ScrollPanelWdgt.coffee:683-691`): a
wall-clock dwell whose determinism relies on the suite's saturation, with the Automator driving a virtual
clock — documented as the second sanctioned exception. If BOTH shapes falsify, stop and re-frame with the
owner (e.g. docking-target bullseye from spec §4 Family A, which needs no timer at all).
**Deliverable:** gap histograms per device + the verdict.

### S3 — Blast-radius probe: who really depends on the internal/external gate (~0.25 day)
Change `WindowWdgt.wantsToBeDropped` to `return true`, `./fg build && ./fg suite`, enumerate failures.
**Questions:** does the failure set match spec §13's predicted changed-set (esp.
`macroInternalVsExternalWindowDrop`); any HIDDEN dependents of the forcing branch (autoscroll gate `:957`,
`macroScrollPanelInWindowMovesWindowWhenDragged`, sample apps)? Also grep-audit `@internal` consumers outside
`WindowWdgt` and check whether `internal` round-trips through world snapshots today (informs the Phase 5
migration). **Deliverable:** the EMPIRICAL changed-test list replacing §13's predictions.

## §3 — Phases 1–6 (each: `./fg gauntlet` green + any listed extra gates; commit on owner approval)

### Phase 1 — Ephemeral infrastructure (DARK: no visible change intended) (~1 day)

> **LANDED 2026-07-06 (DARK; gates all green; awaiting commit approval).** `isEphemeral()` capability
> on `Widget` (reads the `_ephemeralOverlay` flag — `HighlighterWdgt` sets it on the prototype, the
> pinout `StringWdgt` per-instance) now expresses "reconciler-owned overlay" in ONE place:
> (a) hit-test exclusion — `ActivePointerWdgt.topWdgtUnderPointer` → `!m.isEphemeral()`, replacing the
> two per-marker predicates (markers kept as target back-references); (b) shadow-skip —
> `Widget.skipsAddShadowManagement -> @isEphemeral()` (base), `HighlighterWdgt`'s dedicated override
> RETIRED, `CaretWdgt` keeps its own (immaterial but not an ephemeral); (c) world-snapshot exclusion —
> `Serializer.serializeWorld` skips ephemeral children from BOTH the roots walk AND `section.children`
> (closes the §1 finding; `onExternal:"capture"` would otherwise re-pull an excluded overlay).
> STYLE CHANNEL: `widgetsToBeHighlighted` Set→Map (target→descriptor `{form,color,alphaScaled}`);
> `HighlighterWdgt.applyHighlightStyle` renders per descriptor; `@fillStyle` = the legacy
> translucent-blue fill (only style today; outline styles land Phase 2). Touch-list exactly as planned
> + the 3 arc docs. **Gates:** `fg gauntlet` — dpr1 181/0 · dpr2 181/0 · webkit 181/0 · apps ·
> tiernaming · settle · capstone ALL PASS; serialization legs (roundtrip rig incl. the NEW
> `world.ephemeral.excludedFromSnapshot`/`restoreClean` witness + file roundtrip) PASS; `fg homepage`
> native BOOT OK. **DEVIATION from the "expect NO reference changes" prediction: exactly ONE benign
> inspector member-list recapture** — `macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2/3
> (dpr1+dpr2). Its inspector shows inherited `Widget` members ("inherited: on") and scrolls to
> `alpha`, so the 3 new Widget-base members grow the list and the scroll-to-`alpha` view shifts ~1 row;
> pixel-verified the alpha-fade behaviour is unchanged, image_1 recaptured BYTE-IDENTICAL, and the
> failure was identical across dpr1/dpr2/webkit (a deterministic member-count change, not a flake).
> Also: the (homepage-excluded, untested) pinout debug overlay is now shadow-free (spec §2/§11
> classify pinout as an ephemeral). Pre-existing non-fatal `[H]` layering warning on
> `loadWorldSnapshot` is unrelated (untouched by this phase).

- NEW `isEphemeral` capability (base returns false; adopt the owner's term): consulted by
  (a) `topWdgtUnderPointer` — REPLACES the two enumerated marker predicates `:105-106` (markers stay as the
  per-type target back-references, they just stop being the exclusion mechanism);
  (b) `Widget.add` shadow management (fold `skipsAddShadowManagement` semantics — keep the old method
  delegating or retire it if `HighlighterWdgt` is its only definer — VERIFY by grep);
  (c) **`Serializer.serializeWorld` root collection — skip `isEphemeral` children** (closes the §1 finding).
- STYLE CHANNEL: reconciler generalization — `widgetsToBeHighlighted` becomes (or gains a parallel)
  `Map target→styleDescriptor` (`{form: fill|outline, color, alpha, thicknessLogicalPx}`); `HighlighterWdgt`
  renders per descriptor; the existing menu hover-highlight declares the legacy blue-fill descriptor.
- Gates: gauntlet (expect NO reference changes — the legacy descriptor must reproduce today's pixels; verify,
  don't assume) + a serialization probe: declare a highlight (`someWidget.turnOnHighlight()` in the console),
  snapshot the world, assert the ephemeral is absent from the file + restore is clean. The whole-world
  snapshot API + envelope format is documented in `docs/serialization-duplication-reference.md` (§11
  world-snapshot section; the root-collection loop to modify is `Serializer.serializeWorld`,
  `serialization/Serializer.coffee` — grep the roots loop). Touch-list: `Widget.coffee`,
  `ActivePointerWdgt.coffee`, `WorldWdgt.coffee`, `HighlighterWdgt.coffee`,
  `serialization/Serializer.coffee`.

### Phase 2 — Dwell state machine + all drag visuals; RULES UNCHANGED (~1.5 days)

> **✅ LANDED 2026-07-06 — Phase 2 COMPLETE; all gates green.** Commits: Fizzygum `1f36e63c` (WIP —
> the code below) + a completion commit (affordance positioning + label sizing + this doc);
> Fizzygum-tests commit (the 2 dwell macros + 4 benign recaptures). **Gates:** `fg gauntlet` — dpr1
> 183/0 · dpr2 183/0 · webkit 183/0 · apps · tiernaming · settle · capstone ALL PASS; `fg homepage`
> native BOOT OK. **2 NEW macros** — `macroDragEmbedWindowLingerArms` (still hold → armed label +
> candidate outline) and `macroDragEmbedWindowTransitNeverArms` (>7px sweep → candidate outline +
> EMPTY ring, no label) — arm deterministically at ALL three backends/densities (the linger is a
> NON-SCALED `yield`, the ring's fill is event-time under the harness / wall-time in production).
> **4 BENIGN recaptures**: the candidate outline now shows mid-drag in
> `macroCompositeDragsAsUnitIntoScrollPanel` / `macroListWdgtAutoScrollsNearDraggedEdge` /
> `macroSubMenuDroppedIntoPanelPinsItself`, and `macroDuplicatedInspectorDrivesCopiedTargetOnly`'s
> inherited-member list gains `requiresDeliberateEmbedding`. **DEVIATIONS from spec §11 (visual only,
> no rule change):** (1) the ring/label anchor just BELOW the carried payload's bottom edge, not at
> cursor+(16,16) — the hand paints OVER the world's ephemeral overlays, so a cursor-anchored overlay
> is hidden behind the carried window; below-payload keeps them visible and following the drag. (2)
> the armed label (a StringWdgt) gets an explicit `setWidth 320`, else it crops. Suite 181 → 183.
>
> Code below is as originally committed in `1f36e63c` (the completion commit only tweaks the ring/label
> anchor + label width):
> - **Capabilities + constants:** `Widget.requiresDeliberateEmbedding -> false` / `WindowWdgt -> true`;
>   `PreferencesAndSettings.dwellToArmMs:450 / dwellRingSteps:5 / dwellOffsetLandingPx:24` (LINGER_RADIUS
>   reuses `grabDragThreshold:7`).
> - **State machine on the hand** (`ActivePointerWdgt.coffee`): fields `dragEmbed{Candidate,Reluctant,
>   LingerOriginPoint,LingerOriginEventTime,LingerOriginWallTime,Armed}` + `_dragEmbedOutlinedWdgt`;
>   methods `resolveDragEmbedCandidates` (innermost-receptive climb, world excluded, records innermost
>   reluctant), `_reAnchorDragEmbedLinger`, `updateDragEmbedStateMachine` (ARM = elapsed EVENT-time ≥
>   dwellToArmMs, >7px move re-anchors, armed latches while candidate unchanged), `_declareDragEmbed
>   Ephemerals`, `_dragEmbedCandidateTitle`, `_endDragEmbedInteraction`. Hooked at the END of
>   `dispatchEventsFollowingMouseMove` (runs per move AND per-cycle hover re-sync); torn down at the top
>   of `drop()`'s drag block. **`drop()` OUTCOME is UNCHANGED (Phase 3 branches it on `dragEmbedArmed`).**
> - **Visuals = ephemerals.** Candidate/reluctant OUTLINE rides the Phase-1 highlight style channel:
>   `HighlighterWdgt.candidateOutlineStyle` (accent 248,188,58) / `reluctantOutlineStyle` (gray) +
>   `applyHighlightStyle` grew a `form:"outline"` branch (transparent fill + `@strokeColor` → the built-in
>   `RectangularAppearance.paintStroke`; NO new appearance needed). Ring/label/lock-badge ride a NEW
>   declare-and-reconcile slot: `WorldWdgt.dragEmbed{ChargeRing,Label,LockBadge}Declared` + live widgets,
>   reconciled by NEW `WorldWdgt.addDragAffordanceWidgets` (wired into `doOneCycle` right after
>   `addHighlightingWidgets`). Label/badge are `StringWdgt`s marked `_ephemeralOverlay` (Phase-1 flag).
>   Ring = NEW `DragChargingRingWdgt` + `DragChargingRingAppearance` (radial arc segments); NOT a stepping
>   widget — the reconciler calls `updateChargeDeclaration` every cycle, which recomputes the fill from
>   the analog-clock dual time source (event-time under `Automator.animationsPacingControl`, wall-time in
>   production) so it fills smoothly during a frozen hold yet stays byte-exact under tests.
> - **VERIFIED:** candidate outline renders correctly (pencil-yellow border around the drop target,
>   dumped `macroCompositeDragsAsUnitIntoScrollPanel` image_4 — clean, not a loud wash, S1 concern met).
> - **BLAST RADIUS = exactly S1's prediction, 4 tests (all benign/expected):** the 3 plain-payload
>   mid-drag tests now show the outline (`macroCompositeDragsAsUnitIntoScrollPanel`,
>   `macroListWdgtAutoScrollsNearDraggedEdge`, `macroSubMenuDroppedIntoPanelPinsItself`) + the recurring
>   `macroDuplicatedInspectorDrivesCopiedTargetOnly` inspector member-list shift (`requiresDeliberate
>   Embedding` is one more inherited Widget row). No window-drag test screenshots mid-drag (S1), so the
>   ring/label cost 0 existing recaptures.
>
> **REMAINING (the context-expensive, DETERMINISM-CRITICAL tail — ideal for a fresh budget):**
> 1. Author 2 macros via `/author-macro-test`: **linger-arms** (window over an edit-mode/empty-window
>    candidate → non-scaled linger → armed LABEL shot) + **transit-never-arms** (>7px moves → empty ring
>    + outline, NO label). **KEY DETERMINISM CONSTRAINT (verified in MacroToolkit):** `queueInputEvent`
>    SCALES event.time by `spanFactor` (0.03 at fastest), so the dwell linger MUST be built from the
>    NON-SCALED real-wall-clock channel — `yield N` waits (like `clickGuardWindowMs`), or push events at
>    explicit absolute times with `nonScaled=true` — else the arm/ring differs across speeds. The feature
>    itself is correct (production events carry real times); only the macro timing needs this. To avoid
>    the ring's step-boundary jitter at dpr2, DON'T byte-assert a partial ring — assert the armed LABEL
>    (elapsed comfortably ≥450) and the transit EMPTY ring (elapsed ~0); the partial fill is eyeballed.
> 2. `./fg recapture` the 4 blast-radius tests (all benign; webkit-verify after).
> 3. `./fg gauntlet` (dpr2 is the ring-determinism stress test) + `./fg homepage`.
> 4. LANDED-STATUS line + commit (lockstep). Suite 181 → 183.

- Hand-side state machine (spec §6, POST-S2 REVISION): candidate resolution per move (S1's wiring,
  productionized), elapsed-event-time arming with >7px re-anchor, FREE/CANDIDATE/CHARGING/ARMED/LOCKED_CUE,
  `requiresDeliberateEmbedding()` on Widget (false) + `WindowWdgt` (true).
- NEW ephemeral types (all via the Phase-1 channel, shipped path NOT the pinout path): cursor-anchored
  charging ring — a STEPPING ephemeral on the analog-clock pattern (`AnalogClockWdgt.coffee:99-108`,
  `Automator.animationsPacingControl` under tests) — · text label ("Drop to insert into '<title>'") · lock
  badge + amber eye-pulse overlays · candidate outline styles (eager/willing/reluctant).
- `drop()` is NOT touched — an armed release still obeys today's internal/external rule. The visuals are
  therefore honest previews only for already-internal windows; acceptable for one phase (build-internal
  staging, owner sees the feel with zero behavioural risk).
- Gates: gauntlet. Mid-drag screenshots of window drags WILL change — expected recaptures limited to macros
  that screenshot DURING a window drag over a receptive target (S3/grep enumerates; predicted:
  `macroInternalVsExternalWindowDrop`, `macroInternalWindowDroppedIntoWindowFits` family). Plus 2 new macros:
  linger-arms (visual assert) · transit-never-arms.

### Phase 3 — THE RULE FLIP (~1.5 days)

> **✅ LANDED 2026-07-06 — Phase 3 COMPLETE; all gates green.** Commits: Fizzygum `<this commit>` + Fizzygum-tests
> `18ff1976e` (lockstep). **Gates:** `fg gauntlet` — dpr1 186/0 · dpr2 186/0 · webkit 186/0 · apps · tiernaming ·
> settle · capstone ALL PASS; `fg homepage` native BOOT OK. Suite 183 → **186**.
>
> **SOURCE (`ActivePointerWdgt.coffee`, ~2 surgical edits):**
> - `drop()` THE RULE FLIP: the release is re-run through `updateDragEmbedStateMachine` FIRST (spec §6 — the
>   release is an evaluation point, so a frozen hold arms on release with no final micro-move; this is what the
>   armed leg of `macroInternalVsExternalWindowDrop` exercises). Then the verdict is captured and the branch is:
>   `overReluctantOnly` → world + OFFSET by `dwellOffsetLandingPx` · else window (`requiresDeliberateEmbedding`)
>   → armed ? `@dropTargetFor` : world · else plain payload → unchanged (`wantsToBeDropped` — BasementOpenerWdgt
>   keeps forcing world). **DEVIATION (offset application):** `add()`'s position is its 2nd arg, not the (dead,
>   ignored) 6th arg that the old code passed `@position()` into — so the offset is applied by a post-add
>   `wdgtToDrop.moveTo` (the `duplicateMenuAction` idiom), not by a position arg. The offset direction is a fixed
>   down-right diagonal (spec §7's "nearest free direction" is a banked refinement; the fixed offset suffices and
>   is deterministic). Both `wantsToBeDropped` (base + BasementOpenerWdgt) SURVIVE as planned; `WindowWdgt.wants
>   ToBeDropped` is now unreferenced-for-windows but left in place (Phase 5 deletes it).
> - Autoscroll gate flips `wantsToBeDropped()` → `!requiresDeliberateEmbedding()` (windows never edge-autoscroll
>   a panel; §6.1 wheel is their scroll channel).
>
> **EMPIRICAL BLAST RADIUS = 10 tests (not the ~4–5 predicted); enumerated by running the suite post-flip:**
> - `macroInternalVsExternalWindowDrop` → REWRITTEN as the armed/unarmed pair (two IDENTICAL `new WindowWdgt`s;
>   one released at once → world, one held with a non-scaled `yield 600` → nests; proven by moving the panel).
>   image_1 stayed BYTE-IDENTICAL (the unarmed external window is the same as the old external); image_2/3
>   recaptured. Metadata fully rewritten.
> - `macroLockedDocumentRejectsDrop` → box2 (a PLAIN payload) over the LOCKED (view-mode/reluctant) doc now takes
>   the LOCKED_CUE offset landing (the reluctant detection fires: `providesAmenitiesForEditing && !dragsDrops
>   AndEditingEnabled`). image_2 recaptured (box now offset + overhanging), assertion text updated. image_1
>   unchanged.
> - **8 window-drop tests restored by LINGER INSERTION** (they dropped a window that used to nest; now they must
>   arm): 5 via the SHARED verb `dropInternalWindowIntoExternalWindow_InputEvents_Macro` (a single `yield 600`
>   fixed all 5 — `macroInternalWindowDroppedIntoWindowFits`, `…WindowWithAClockInAWindowConstructionTwo`,
>   `…ResizeWindowContainingInternalWindow`, `…ClosingInnerWindowKeepsOuter`, `…WindowsNestedCollapsingUncollapsing`);
>   `macroScrollPanelUpdates…` via a `yield 600` before its pickUp+click drop; and 3 title-bar press-drag-release
>   drops via a NEW reusable verb `dwellDragWindowByGrabToEmbed_InputEvents_Macro` (`macroMenuInWindowInScrollStack
>   StaysLive`, `macroWindowCellsInConstrainedScrollStackReflow` ×2, `macroSimpleDocumentHandlesOldInspector`
>   drag-in). ALL 8 post-drop screenshots stayed BYTE-IDENTICAL (the linger is transient; the nested result is
>   unchanged) → **zero recaptures** for the 8.
>
> **⚠ EMERGENT UX CONSEQUENCE (flagged for owner, not a bug): repositioning a NESTED window by its title-drag now
> DETACHES it to the world unless you dwell** — because `drop()`'s unarmed→world applies to re-parenting too
> (`macroScrollPanelUpdates…`'s "park the collapsed bar" step exposed this: without a dwell the window popped out
> of the panel). Fixed in-test by using the dwell-embed drag for the repositions. This is the literal spec §7
> (unarmed→world), but a "sticky re-embed over the CURRENT parent" refinement (keep a window nested when released
> over its own container, no dwell) is the fix — **OWNER-APPROVED 2026-07-06, now scheduled as Phase 3.5** (which
> also lets the in-test reposition workaround revert to a plain no-dwell drag).
>
> **3 NEW macros** (plan gate list): `macroDragEmbedArmedPersistsWhileAiming` (arm, then a big aiming move within
> the candidate stays armed → nests at the aimed spot), `macroDragEmbedCandidateChangeResets` (armed over A →
> moved onto B, the armed label is gone + a fresh EMPTY ring shows = disarmed; asserts the mid-drag DISARM, not a
> post-drop frame), `macroDragEmbedReleaseWhileChargingLandsOnWorld` (held ~250ms < dwell, released → world).
> All arm deterministically at dpr1/dpr2/webkit. **The 4th gate macro (wheel-charges / scroll-chaining-disarms,
> §6.1) is DEFERRED to Phase 6** (more complex; the 3 core behaviors are covered).
>
> **DETERMINISM NOTE (no falsification budget spent):** the dwell DECISION + ring are byte-deterministic at
> dpr1/dpr2/webkit (gauntlet 186/0 ×3). ONE transient snag — `macroDragEmbedCandidateChangeResets`'s ORIGINAL
> post-drop frame flaked at dpr2 (capture vs run) — was diagnosed to INVISIBLE alpha=0 charging-ring teardown
> residue from a rapid move→immediate-release (the two PNGs were pixel-identical; fresh runs were STABLE, so NOT a
> decision nondeterminism — image_0/the armed state passed dpr2). Resolved by asserting the mid-drag DISARM
> directly instead of the post-drop frame (a sharper proof anyway). The dwell mechanic's 1-of-2 falsification
> budget is INTACT.

- `drop()`: remove the `wantsToBeDropped`→world forcing for windows (base `wantsToBeDropped` and the
  `BasementOpenerWdgt:60` override SURVIVE); armed→embed / unarmed→world-at-release; OFFSET landing (24px)
  for LOCKED_CUE releases; autoscroll gate at `:957` flips from `wantsToBeDropped()` to
  `!requiresDeliberateEmbedding()` (windows never autoscroll panels).
- Rework the changed tests, enumerated EMPIRICALLY (see the §2 S3 scope note): `macroInternalVsExternalWindowDrop`
  → rewrite as the armed/unarmed pair (CONFIRMED by S3); plus linger insertion (synthesized stationary
  event-time ≥ DWELL_ARM_MS before release) into every macro the suite run flags for dropping a window
  payload unarmed — spec §13 predicts ~4; `macroLockedDocumentRejectsDrop` gains the offset assert (pill
  comes in Phase 4).
- Gates: gauntlet + 3 new macros (release-while-charging→world · armed-persists-while-aiming ·
  candidate-change-resets · wheel-charges/scroll-chaining-disarms — from spec §13).

### Phase 3.5 — Sticky re-embed over the current parent (~0.5 day) — OWNER-APPROVED 2026-07-06

> **✅ LANDED 2026-07-06 — Phase 3.5 COMPLETE; all gates green.** Commits: Fizzygum `<this commit>` + Fizzygum-tests
> `709b54736` (lockstep). **Gates:** `fg gauntlet` — dpr1 187/0 · dpr2 187/0 · webkit 187/0 · apps · tiernaming
> (0 leaks) · settle (0 violations) · capstone (0 careless pushes) ALL PASS. Suite 186 → **187**. No serialization/
> defaults touched, so gauntlet is the full gate (no homepage/serialization legs — per this phase's gate line).
>
> **SPIKE (done first, as required):** the window's OWN container = its PRE-grab parent, read as `@grabOrigin.origin`.
> `situation()` records `{origin: @parent, …}` in `grab()` JUST BEFORE `@add aWdgt` reparents the payload to the hand,
> so at `drop()` time `wdgtToDrop.parent` is the HAND (useless) but `@grabOrigin.origin` is the real source container.
> `grabOrigin` is set on every hand-grab path (direct `grab()`, `pickUp()` → `grab()`) and overwritten each grab, so
> it is always the current payload's origin. `world.hand` is NOT in `world.children`, so `topWdgtUnderPointer`/
> `dropTargetFor` already exclude the dragged payload (the fact the armed-embed path relies on) — the climb resolves
> to the real container under the cursor. This turned `grabOrigin` from write-only dead state into a live read.
>
> **SOURCE (`ActivePointerWdgt.drop`, the window / not-armed branch, ~6 lines):** before defaulting to `world`,
> `stickyTarget = @dropTargetFor wdgtToDrop`; if `stickyTarget isnt world and stickyTarget is @grabOrigin?.origin`
> → nest there (no dwell, no offset); else `world`. The armed branch and the reluctant/offset branch are untouched.
>
> **TESTS (mostly a SIMPLIFICATION):** `macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow`'s
> TWO reposition title-drags REVERTED from `dwellDragWindowByGrabToEmbed_InputEvents_Macro` back to the plain
> `@syntheticEventsMouseMovePressDragRelease_InputEvents` (no dwell) — sticky re-embed keeps them nested, and the test
> passed against the EXISTING references BYTE-IDENTICAL at dpr1 AND dpr2 (incl. the image_5≡image_7 assertion) → ZERO
> recaptures. (The INITIAL carry-drop into the panel keeps its `yield 600` — embedding into a NEW container still
> arms.) NEW macro `macroDragEmbedRepositionNestedWindowStaysWithoutDwell` (4 shots): dwell-embed a window into a left
> panel, then prove three unarmed outcomes by MOVING the relevant container — (A) reposition WITHIN → travels (sticky);
> (B) drag OUT to desktop → stays (detached to world); (C) drag into a DIFFERENT panel → stays (lands on world on top,
> no sticky). Every shot is taken AFTER the settling `panel.moveTo` (never the raw post-drag frame), both a clean
> nesting proof and a dodge of the parked charging-ring invisible-alpha teardown residue — stable across 3 fresh dpr2
> runs. **DOCS:** spec §12 (grabOrigin.origin mechanism + hand-exclusion) + §14 (grabOrigin no longer dead) updated;
> §7's sticky clause was already in place (de99a89e). MACRO-PATTERNS.md: the title-bar entry's ⚠ tail corrected + a new
> "Sticky re-embed" pattern entry. No new verb (the quick drags use the plain press-drag-release, unarmed at every speed).
>
> **FALSIFICATION BUDGET (dwell mechanic, spec §6): 1-of-2 INTACT.** No new evidence against the dwell — the plain
> reposition drags never arm (linger origin re-anchors every ~7px), and the sticky rule is orthogonal to arming.

**Motivation:** Phase 3's rule flip made an unarmed release land on the world — which, applied to a window that
is ALREADY nested and merely being REPOSITIONED within its container, DETACHES it to the desktop unless the user
dwells (the emergent UX consequence flagged in the Phase 3 LANDED box; `macroScrollPanelUpdates…`'s "park the
collapsed bar" step had to be switched to the dwell-embed drag to keep the window nested). Owner approved a
"sticky re-embed" refinement so repositioning-within-the-current-container needs NO dwell; only embedding into a
NEW container (or from the desktop into one) requires the dwell.

- **The rule (spec §7 gains this clause — update the release matrix too):** on an UNARMED window release, if the
  resolved drop-target (the innermost `wantsDropOfChild` container under the point — i.e. what `@dropTargetFor`
  would return, EXCLUDING `world`) **IS the payload's CURRENT parent** (`wdgtToDrop.parent`), keep it nested there
  (embed as normal, no dwell) instead of landing on the world. Embedding into a DIFFERENT container still requires
  the dwell (armed); releasing over the world / a non-container still lands on the world; the LOCKED_CUE (view-mode)
  offset landing is unchanged (a view-mode container never `wantsDropOfChild`, so it can't be a sticky parent).
- **`drop()` change (`ActivePointerWdgt.coffee`, the window branch):** in the `requiresDeliberateEmbedding` /
  `not wasArmed` case, before defaulting to `world`, compute `stickyTarget = @dropTargetFor wdgtToDrop` and, if
  `stickyTarget isnt world and stickyTarget is wdgtToDrop.parent`, use it as the target (nest, no offset). Keep it
  a tight, well-commented clause; the armed branch and the reluctant/offset branch are untouched. VERIFY the
  drag-detach mechanics: a nested window dragged by its title becomes a hand float-drag whose `.parent` is the
  hand — so capture the ORIGINAL parent (before `grab`/`pickUp` reparents it to the hand) if `wdgtToDrop.parent`
  is no longer the container at drop time. (`ActivePointerWdgt.grab`/`_reactToChildGrabbed` record the old parent;
  reuse or stash it — spike this first.)
- **Test impact (mostly a SIMPLIFICATION):** `macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosing
  Window`'s two reposition title-drags can REVERT from `dwellDragWindowByGrabToEmbed_InputEvents_Macro` back to the
  plain `@syntheticEventsMouseMovePressDragRelease_InputEvents` (no dwell) and the window stays nested → should be
  BYTE-IDENTICAL to the pre-Phase-3 references (VERIFY; recapture only if not). NEW macro
  `macroDragEmbedRepositionNestedWindowStaysWithoutDwell`: nest a window (dwell), then a quick un-dwelled title-drag
  to a new spot WITHIN the same container → it stays nested (proven by moving the container). Contrast macro (or a
  second leg): a quick un-dwelled drag OUT to the desktop → detaches (lands on world), and a quick drag into a
  DIFFERENT container → lands on world (no sticky, since the target isn't the current parent).
- Gates: gauntlet + the new macro(s); no serialization/defaults touched. Spec §7 + §12 updated to record the clause.

### Phase 4 — Reluctant flow: pill + hint — ❌ REJECTED 2026-07-06

> **BUILT, WORKING, then OWNER-REJECTED 2026-07-06 — fully reverted, nothing committed.** The pill (a MenuWdgt
> transient with Insert / Edit & insert) and the §9 teaching hint (a click-through text ephemeral) both worked,
> but the hint fired on EVERY unarmed window release over a container ("so often it's ridiculous") and the owner
> found the whole popup flow too intrusive. **Replacement decision (owner-approved):** a reluctant (view-mode)
> drop now simply LANDS THE PAYLOAD ON THE WORLD AT THE RELEASE POINT — no offset, no pill, no hint (the offset
> "false-success killer" was also dropped; the un-clipped overhang already proves the payload isn't nested).
> Landed: `drop()` reluctant branch = `target = world` with NO post-add offset; `dwellOffsetLandingPx` retired
> from `PreferencesAndSettings`; spec §7 updated + §8/§9 marked DROPPED; `macroLockedDocumentRejectsDrop` image_2
> recaptured (box at the release point, not offset). LESSON: `MenuItemWdgt.trigger` does `@target[@action]` — a
> menu-item action must be a STRING method name + `arg1`/`arg2`, NOT a function closure.

### Phase 5 (SLIMMED, owner-approved 2026-07-06) — derived `internal` + remove the internal/external switch
**Scope trimmed by owner:** NO pencil↔eye glyph swap (the edit-button pencil stays as-is), and NO eject button —
dragging a nested window OUT to the desktop already ejects it (Phase 3's rule flip: an unarmed release over the
world detaches; sticky re-embed only keeps it nested when released over its OWN container). So the internal/
external switch has no remaining job and is simply DELETED, not repurposed.
- **`@internal` DERIVED** — replace the stored/constructor flag with an owner-chain query ("am I nested" = a
  non-world container ancestor exists). The title-bar skin (`setAppearanceAndColorOfTitleBackground`) then follows
  automatically whenever a window is dragged in or out — no manual re-skin call.
- **Delete the internal/external `SwitchButtonWdgt`** (`createAndAddInternalExternalSwitchButton`, its button
  field, and the `alwaysShowInternalExternalButton` handling). **Retire BOTH `makeInternal` and `makeExternal`**
  (nesting = drag-with-dwell; un-nesting = drag-out; skin = the derived query). `WindowWdgt.wantsToBeDropped`
  (already unreferenced-for-windows since Phase 3) is deleted here too.
- **Deserialization** of old snapshots ignores any stored `internal` (derive from parentage on load). VERIFY vs
  `docs/serialization-duplication-reference.md`. The `internal` / `alwaysShowInternalExternalButton` constructor
  args become inert (the 56 `new WindowWdgt nil, nil, …` arg-retirement sweep stays DEFERRED to a later cleanup).
- **`SampleDashboardApp.coffee:120`**: drop the `disableDragsDropsAndEditing()` (dashboards open edit-ON) — keep
  IF the owner still wants it; confirm at phase start (it's an independent default flip).
- Gates: gauntlet + both serialization legs + `./fg homepage`. ⚠ **RECAPTURE SWEEP: every window frame that shows
  the internal/external switch changes** (the switch disappears). Pre-measure with a grep/probe at phase start;
  batch-recapture via full `fg recapture` (NOT `--no-build` — multi-image skip trap); webkit-verify per the
  recapture-masks-crash safeguard. (Smaller sweep than the original Phase 5, since the pencil is untouched.)

### Phase 6 — Test completion + docs closeout (~1.5 days)
- Author the remaining spec-§13 macros not yet landed (target: all ~13, incl.
  frozen-then-release-does-not-retroactively-arm · eager-empty-window-still-requires-dwell ·
  eject-button · dashboard-edit-on · window-drag-no-autoscroll).
- Docs: spec header → IMPLEMENTED (+ deviations list, dataflow-arc style); breadcrumbs in root/Fizzygum
  CLAUDE.md (one line + link); this plan gets the LANDED-STATUS box; memory updated.
- Gates: full `./fg gauntlet` + serialization legs + homepage; suite count 181 → ~194.

## §4 — Risks & pre-committed fallbacks
1. ~~Gap-credit vs. real mice~~ — **RESOLVED by S2 (falsified) + the one pre-authorized reframe (spec §6
   revision record): elapsed event-time decision + clock-pattern ring feedback.** Falsification budget spent:
   1 of 2. If implementation surfaces NEW evidence against the revised mechanic, STOP and re-frame with the
   owner (docking-targets need no timer at all).
2. **Phase-5 recapture sweep size** — measured before starting the phase; if it approaches whole-suite scale,
   owner may choose to split glyph-swap (pencil↔eye) from eject/derived-internal into separate commits for
   reviewability. Benign-recapture policy per owner memory: never contort code to avoid one.
3. **Hidden `internal` dependents / silent behavior deltas** — S3 enumerates empirically before any rule code.
4. **Ephemeral serialization** — explicit exclusion + witness probe in Phase 1 (never rely on "a save can't
   coexist with a drag").
5. **Determinism regressions** — every new mechanism is event-time; any `Date.now()` (S2-fallback excepted,
   documented) is a review-reject; dpr2 + webkit legs run every phase (gauntlet), torture loop only if a
   phase touches the settle/paint path (none should).

**Rough total: ~8 days of phases remain** (spikes done; calendar, single-session-per-phase cadence like the
dataflow arc; Phase 5's recapture sweep is the wall-clock wildcard).

## APPENDIX A — the S1/S2 throwaway probe (verbatim; re-apply to `ActivePointerWdgt.coffee` + `./fg build`
to regenerate the feel/telemetry build; REVERT before any phase work — never commit)

At the TOP of `dispatchEventsFollowingMouseMove: (mouseOverNew) ->` (before the `@mouseOverList.forEach`):

```coffee
    # »»»» THROWAWAY S1/S2 PROBE (docs/drag-embed-implementation-plan.md §2) — NEVER COMMIT »»»»
    if @isThisPointerFloatDraggingSomething()
      __probeNewCandidate = @dropTargetFor @children[0]
      __probeNewCandidate = nil if __probeNewCandidate is world
      if __probeNewCandidate isnt @__probeCandidate
        world.widgetsToBeHighlighted.delete @__probeCandidate if @__probeCandidate?
        world.widgetsToBeHighlighted.add __probeNewCandidate if __probeNewCandidate?
        __probeName = if __probeNewCandidate? then __probeNewCandidate.toString() else "none"
        console.log "[S1 PROBE] candidate -> " + __probeName
        @__probeCandidate = __probeNewCandidate
      if WorldWdgt.timeOfEventBeingProcessed?
        if @__probeLastMoveT?
          @__probeGaps.push WorldWdgt.timeOfEventBeingProcessed - @__probeLastMoveT
        else
          @__probeGaps = []
        @__probeLastMoveT = WorldWdgt.timeOfEventBeingProcessed
    # ««« THROWAWAY S1/S2 PROBE «««
```

In `drop: ->`, immediately inside `if @isThisPointerFloatDraggingSomething()` (before `wdgtToDrop = @children[0]`):

```coffee
      # »»»» THROWAWAY S1/S2 PROBE cleanup + telemetry dump — NEVER COMMIT »»»»
      if @__probeCandidate?
        world.widgetsToBeHighlighted.delete @__probeCandidate
        @__probeCandidate = nil
      if @__probeGaps? and @__probeGaps.length > 0
        __gaps = @__probeGaps
        __credit = 0
        __credit += Math.min(g, 100) for g in __gaps
        __under = (__gaps.filter (g) -> g <= 100).length
        __sorted = __gaps.slice().sort (a, b) -> a - b
        __median = __sorted[Math.floor(__sorted.length / 2)]
        __span = 0
        __span += g for g in __gaps
        __finalGap = if WorldWdgt.timeOfEventBeingProcessed? and @__probeLastMoveT? then Math.round(WorldWdgt.timeOfEventBeingProcessed - @__probeLastMoveT) else -1
        __last10 = (__gaps.slice(-10).map (g) -> Math.round g).join ','
        console.log "[S2 PROBE] moves=#{__gaps.length} medianGap=#{Math.round __median}ms under100=#{Math.round(100 * __under / __gaps.length)}% maxGap=#{Math.round __sorted[__sorted.length - 1]}ms gapCreditTotal=#{Math.round __credit}ms wallSpan=#{Math.round __span}ms finalStillGap=#{__finalGap}ms last10=[#{__last10}]"
      @__probeGaps = nil
      @__probeLastMoveT = nil
      # ««« THROWAWAY S1/S2 PROBE «««
```

(The `gapCreditTotal` fields refer to the RETIRED v1 mechanic — kept so re-runs stay comparable with the §2
telemetry; the live decision metric is `finalStillGap`-style elapsed event-time.)
