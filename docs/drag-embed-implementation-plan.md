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

### Phase 4 — Reluctant flow: pill + hint (~1 day)
- Land-and-offer pill = MENU-family transient (NOT ephemeral; dismiss-on-outside-click is menu behavior):
  title line + [Insert] (programmatic add into the view-mode container, mode unchanged — reuse the drop
  reaction sequence `_beforeChildDropped`→`add`→`_reactToChildDropped`) + [✎ Edit & insert]
  (`enableDragsDropsAndEditing` then insert). §9 teaching hint = text ephemeral, dismissed by next
  pointer-down.
- Gates: gauntlet + `macroLockedDocumentRejectsDrop` extended (pill-Insert leg) + pill-Edit&insert macro +
  hint macro.

### Phase 5 — Title bar: pencil↔eye, eject, derived `internal`, dashboard default (~1.5 days + recapture sweep)
- Edit button → `SwitchButtonWdgt [pencil, eye]` (NEW `EyeIconWdgt`/`EyeIconAppearance`); retire
  `makePencilYellow/Clear` (grep: only WindowWdgt + StretchableEditableWdgt callbacks).
- `@internal` DERIVED (owner-chain query); `makeInternal` retires; `makeExternal` → the eject action behind a
  nested-only eject button (reuse/replace the internal/external `SwitchButtonWdgt` slot); deserialization of
  old snapshots ignores stored `internal` (S3 informs the exact migration; `@serializationTransients` is the
  protocol if it stays a cached prop). The 56 `new WindowWdgt nil, nil, …` arg-retirement sweep is DEFERRED
  (args become inert this phase, deleted in a later cleanup).
- `SampleDashboardApp.coffee:120`: drop the `disableDragsDropsAndEditing()` (dashboards open edit-ON).
- Gates: gauntlet + both serialization legs + `./fg homepage`. ⚠ **RECAPTURE SWEEP: every reference frame
  showing a view-mode pencil or the internal/external switch changes** — potentially a large fraction of 181.
  Pre-measure with a cheap grep/probe run at phase start; batch-recapture via full `fg recapture` (NOT
  `--no-build` — known multi-image skip trap); webkit-verify per the recapture-masks-crash safeguard.

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
