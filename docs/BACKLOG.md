# BACKLOG.md — every open item, with its owning doc

Index only: the executable detail lives in the linked plan section. **OPEN items only** — an
item leaves this file when it closes, and lands in the `## BACKLOG ledger` section of the plan
that owns it (README rule 2). A subsection's owning plan lives in `plans/` while the arc is
active and in `archive/` once it closes; either way the open items it left behind stay here.
Closed items whose arc never had a plan file are collected in
`archive/backlog-closed-items-ledger.md`.
Generated 2026-07-17 from the docs restructure; closed items moved out 2026-08-18; keep current
per README rules 2 and 5.

## Open items by owning arc

### `archive/world-inventory-instruments-plan.md` — Arc A of the object-lifetime program (IN EXECUTION 2026-08-20; phases 1–4 done, see the plan's STATUS box)
The three-arc program (A in-band inventory instruments · B Chrome-only VM-truth riders · C the
two-lifetimes reset-by-reconstruction) is stated in that plan's §0; Phase-0 repairs (tooltip timeout
self-removal, dead `Class.allClasses`, the `@superClass` fix that makes `Class.subClasses` populate)
landed with the plan.
- [x] Arc A EXECUTED IN FULL 2026-08-20 (all phases incl. both D5 prove-it-fails plants;
      gauntlet 16/16) — doctrine doc: `architecture/world-lifetime-and-inventory.md`; execution
      ledger: the plan's STATUS box + §5.1/§5.2. Archive the plan at the close ritual.
- [ ] **OWNER DECISION (2026-08-21, from the async-rejection sweep): a failed async door tells the user NOTHING.** Every product promise chain was swept for missing `.catch` (13 `.then` in `boot/globalFunctions.coffee`, 10 in `PartsRegistry.coffee`, 3 each in `WorldWdgt.coffee` and `boot/loading-and-compiling-coffeescript-sources.coffee`, 2 in `Widget.coffee`, 1 each in `FileLoading`/`DemoMenus`/`VideoPlayerWithRecommendationsWdgt`/`SWCanvasElement-extensions`). ⭐ **The sweep's finding is that these are NOT N defects** — the subsystem has thought about rejection and handles the parts that matter: `PartsRegistry` neutralises unhandled rejections centrally (`inFlight.catch -> undefined`), `canEverProvideClass` keeps an icon off screen when its part can never arrive (the `lean` dead-icon rule), `whenOptionalPartsLoaded` exists precisely so a door cannot become "a click that can only reject", and `loadWorldSnapshot` bails out BEFORE mutating so a failed load "leaves the user with nothing instead of the desktop they still have". What is uniformly absent is USER FEEDBACK: on a TRANSIENT failure of a part the build does ship (a bad read over `file://`, a corrupt part file), the click silently does nothing — consistently, everywhere, which is what suggests it is a decision rather than an oversight. The question is whether a failed door should `inform`, and it is a product call. ⚠ Note this is a DIFFERENT shape from the `saveFailedScreenshots` bug fixed the same day: that one was PARTIAL failure discarding work that had already succeeded, which is a bug on any reading; these are all-or-nothing by design.
- [ ] StorageSorter-roots unification (plan D2's stated non-goal): `StorageSorter._runClassifier`'s
      phases build their own root/marking enumeration — examine folding it onto
      `WorldWdgt.graphLivenessRoots()` in a dedicated pass, NOT by side-effect of another arc.
- [x] DONE 2026-08-20 (post-arc rider): the two `Object.keys(window)` Wdgt/Widget SUFFIX scans
      (`WorldWdgt.fullDestroyChildren` id-zeroing — which provably MISSED
      `FrameContentsPlaceholderText` — and `Serializer.collectIdCounters`) now consume THE one
      marker enumeration, boot's `allClassFunctions()` (`src/boot/globalFunctions.coffee`), which
      `WorldInventory`'s roots consume too — three consumers, one definition of "a class".
- [x] Arc B EXECUTED 2026-08-20 (plan: `archive/world-vm-truth-riders-plan.md`; doctrine:
      `architecture/world-lifetime-and-inventory.md` §6): the `fg vmtruth` gauntlet leg
      (`vm-truth-gate.js` — forced-GC collectibility oracle + post-GC heap-floor gate +
      INVALID-on-unmeasured), the `heap-forensics.js` four-lens tool (incl. `--selftest`),
      the destroy-mid-load door race repaired at five funnel callbacks + gated in the
      `parts` leg. (The named FinalizationRegistry oracle was ABSORBED by the WeakRef
      sweep — same oracle made synchronous; see the plan's §8.)
- [x] **Arc C AUTHORED + EXECUTED 2026-08-20/21** (`archive/world-reset-by-reconstruction-plan.md`, STATUS box =
      the ledger): `resetWorld` SHIPS as destroy + `new WorldWdgt` + swap. Phases 1–4 done and pushed —
      spikes GO, eight pre-repairs, the flip (`21c638d7`/`43d503c3b`, suite 307/307 byte-identical, zero
      recaptures), then the acceptance tier. ⭐ The invariant this line anticipated ("is the old world
      collectible?") did NOT survive contact: collectibility is a PROXY with false positives by
      construction, and the residue it kept reporting had no retaining edge at all. The gate now asks
      REACHABILITY in two tiers and the grace period is DELETED (`054e7580`+`9f53e38c`/`98f38a592`+`8b89c9be2`,
      gauntlet 18/18). Remaining: Phase 5 only.
- [x] DONE 2026-08-20 (D-P2g, Arc C phase 2): meta-built constructors are NAMED — `Class`'s eval'd source
      carries a named constructor function, 513/513 byte-verified, `fg homepage` green (the precompiled image
      boots from the image, which naming could have broken). Heap-snapshot widget nodes now read their class
      (measured 2026-08-21: a retained world's retainer path prints `object "WorldWdgt"`, where it read
      `object ""` before). Prototype METHODS followed on 2026-08-21 — see the D3 line below.
      ⚠ **CORRECTED 2026-08-21: the precompiled image does NOT carry the names, and never did.** Measured on
      a `--profile homepage` tree: `pre-compiled.js` holds `WorldWdgt=function t(e` — terser mangles a
      function-expression name like any other binding, so neither constructor nor member names survive
      minification (82 named function expressions in the whole 733 KB image, all vendor). That costs nothing
      real: heap forensics runs on the harness/dev tree, which compiles from source text at boot and carries
      every name (verified 369/369 on `Widget.prototype`). ⛔ Do not
      let readable names tempt a by-NAME lookup: names are not unique and the emit is not a contract, so heap
      identity stays the object id (`lib/heapsnapshot.js` says so at `nodeIndexById`).
- [x] DONE 2026-08-20 (post-arc rider): the REACTIVATED `Class.subClasses` propagation now has
      durable regression coverage — `SystemTest_macroClassSubclassesPropagation`, an
      assertion-only macro test (6 assertions: registry populated, parent-knows-child,
      inherited-property propagation fires, the redefinition guard holds and is non-vacuous),
      running on both engines in every suite pass.
- [x] DONE 2026-08-20 (D-P2f): the `hasProp`/`indexOf`/`slice` window globals are NOT a leak — they
      are LOAD-BEARING and stay. `Class._removeHelperFunctions` strips CoffeeScript's helper `var`
      block out of every compiled fragment while keeping the uses, so member bodies reach all three
      as free identifiers resolved in the global scope the fragment is eval'd into (measured by
      driving the real meta-compiler over the tree: free `hasProp` and `indexOf` uses in shipped src
      AND harness classes; `slice` has none today but its declaration is stripped just the same, so
      the first splat destructuring would want it). The contract is now stated at the three
      assignments in `src/boot/loading-and-compiling-coffeescript-sources.coffee`.
- [x] DONE 2026-08-20 (D-P2f): `WorldWdgt.fullDestroyChildren` no longer writes `Automator.*`. It
      calls the existence-soaked `@_resetAutomatorTogglesNoSettle?()`, defined by the harness in
      `Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee`. The call stays in
      `fullDestroyChildren` rather than moving to `_resetWorldNoSettle` because both callers of the
      shared teardown core need the reset at that moment — a serialization test loads a whole-world
      snapshot mid-test.

### `archive/direct-shape-fastpaths-followups-plan.md` — ✅ EXECUTED IN FULL + CLOSED 2026-08-08 (P1–P6)
- [ ] FOLLOW-UP (owner, 2026-08-08): redesign the rotate-handle glyph as the four-swirlies square (the classic rotate glyph: square outline with four curled arrows at the corners — owner supplied reference screenshots). The current knob-ring paint in `HandleAppearance` is a single `strokeCircle` at the hairline `lineWidth` 0.5 (H1 made that sound — see `archive/hairline-direct-strokes-plan.md` § "BACKLOG ledger": a sub-1px direct stroke rasterizes as 1px geometry at opacity proportional to the true DEVICE width, so the ring's faintness scales with the island); the redesign replaces that paint wholesale. Candidate flow: the size-aware icon workflow.

### `archive/shared-base-layer-part-plan.md`
CLOSED 2026-08-02 — executed in full; the residue is in `architecture/build-and-packaging.md` §2/§5.
As-landed record (the `app-kit` part itself, and the `check-part-edges.js` gate gap it found in
passing): that plan's § "BACKLOG ledger". What stayed open is the two classes it could not move:
- [ ] **The last two, and they are a DECISION not a gap: `CanvasWdgt` + `PatchNodeWdgt` (4.3 KB) stay in core.** The EAGER `video-player` and `patch-programming-experimental` parts EXTEND them, and an eager part cannot derive from a lazy one at all. Unblocking is not packaging work: `video-player` is auto-launched AT BOOT (a product decision about a flag-gated draft feature), and `patch-programming-experimental`'s `FanoutWdgt`/`FanoutPinWdgt` are named from core's dataflow wiring where `ControllerMixin.ensureWireEdge` has no async seam. ⛔ Do not re-attempt for the bytes. Full pricing: `architecture/build-and-packaging.md` §5.

### `archive/stroke-flip-and-fracplane-coverage-plan.md`
CLOSED 2026-08-12 — executed in full the day it was authored; residue in `architecture/appearance-paint-convention.md` (stroke + overlay bullets) and the archive stamp. P1–P3 and the thin-stroke finding are in that plan's § "BACKLOG ledger". What remains open is one of the pre-existing defects the arc FOUND:
- [ ] **FOUND BY P1's recapture (P1 = the §4.4(B) border/overlay flip, in that plan's § "BACKLOG ledger"), pre-existing, owner-gated: a hand-carried window's pixels are NOT refreshed when a pending glyph atlas arrives mid-drag** — on a cold page the carry freezes placeholder blocks and `waitForScreenshotReady` truthfully reports settled (the live text DID settle; the carried pixels are stale), so the screenshot gate cannot see it. User-visible product behavior (drag a window before fonts settle), and the deterministic face of the open flake-A class (`suite-nondeterminism-flakes-arc`): solo-cadence repro = revert the pre-carry settle yield in `SystemTest_macroDragEmbedWindowTransitNeverArms` and run it on a fresh page. Test-side mitigation landed (that yield); the sibling mid-carry-screenshot tests share the race and can get the same wait if it ever bites.

### `archive/widget-practices-convergence-plan.md` — ✅ **CLOSED 2026-08-17 (W0–W10), two residuals below**
Acted on `measurements/widget-practices-survey-2026-08-14.md` (28 facets over all 270 widget classes)
to reach `architecture/widget-authoring-guidelines.md`. The per-phase log lives in the archived plan's
"As landed" blocks and in `archive/INDEX.md`; the survey now carries an appended **"state at close"**
delta table, and the mechanical half of it is re-runnable as `buildSystem/census-widget-conformance.js`.
Landed: undeclared instance fields 9 classes/11 fields → **0/0** (a true zero — the connector arc's P9
retired the last floor), `_reLayout` prologue copies 24 → **8** stated exceptions, W9's three
enforcement tiers, W6a (a LIVE BUG: three `SliderWdgt` prompts stored the slider's own value, not the
typed one), and W7 — which landed as ONE derivation instead of the 164 hand-written names the plan
asked for.
⭐ **The recapture rule this arc measured:** `InspectorWdgt.showingInherited` defaults to FALSE, so a
member list shows the inspected class's OWN members. A pull-up to a base class is inspector-FREE; a
declaration on a class some test OPENS is what costs. Predict from the plan's §11.1 per-surface test
lists, not from how many classes inherit the field.
- [ ] **RESIDUAL W6b (owner-gated, D3) — idempotence guards on the B/C/D pin setters.** Deliberately
      not done in-arc: the dataflow engine's equal-value cutoff already covers most of what the guard
      would buy, and `archive/connector-ubiquity-and-reflection-plan.md` §P2's bind-time precedence rule
      may change what the guard should DO. When it runs, it wants its own commit plus the
      patch-programming and °C↔°F converter macros run explicitly.
      **✅ RE-DERIVED AGAINST P2, 2026-08-17 (P2 landed): W6b is INDEPENDENT of P2 — the one
      P2-specific hazard is dissolved, not mitigated.** The archived plan §2.6 note 3 feared that
      *"P2's bind-time rule depends on both wires FIRING at bind time; an idempotence guard could
      swallow the second fire when the two sides already agree"*. That was written against the
      SKETCH, which had both wires fire and the later one win. As landed, `bindTo` fires exactly ONCE
      by construction — `wireTo` (pushes) + `declareWireTo` (moves nothing) — so there is no second
      fire for a guard to swallow, and precedence cannot depend on setter idempotence. The follow-on
      case is covered too: delivering A's value into B runs B's `updateTarget`, but that re-mark is
      the ECHO the engine already drops while B is the node being applied into, and if the two sides
      already agree the equal-value cutoff stops the walk with or without a guard.
      ⇒ **What remains is exactly what the plan's §2.6 note 2 already stated, unchanged by P2**: the
      cutoff decides only whether to traverse ONWARD, while `_applyWireValue` still CALLS the setter
      with an equal value — so the guard's whole remaining value is suppressing the SETTER'S OWN side
      effects (its `_changed()` repaint and any onward fire) on an equal write. That is a paint /
      redundant-work question, not a dataflow-correctness one, which is why it is a real behaviour
      change and still wants its own commit and its own evidence. **No connector dependency is left:
      whenever it runs, it runs on its own merits.**
- [ ] **RESIDUAL W7 other half (owner-gated, D4) — `representativeIcon`.** All but thirteen classes
      answer the base `new WidgetIconWdgt` — nine declare an override (`ScriptWdgt`, `FolderWindowWdgt`,
      `FrameWdgt`, `ImageWdgt`, `DashboardWdgt`, `SlideWdgt`, `GenericPanelWdgt`, `DocumentWdgt`,
      `PatchProgrammingWdgt`) and four inherit one. Unlike a colloquial name, an icon CANNOT be derived from a class
      name, so this stays the hand-written job the plan described — worth doing only for what can be
      referenced from the desktop, not as a sweep.

### `archive/menu-action-wiring-plan.md` — CLOSED, residual included; SIX live bugs fixed
Four found by reading (three `SliderWdgt` prompts that threw on every click; three demo "…launcher"
items that crashed), two more found by the rig that closed the arc's own residual (every widget
wearing a `BoxyAppearance` threw when its numerical-setters menu was built; `cornerRadiusPopout` read
a field only `BoxWdgt` declares). Both halves are gated: `buildSystem/check-menu-actions.js` on the
build, and `menu-click-sweep-headless.js` (`fg menusweep`) as a gauntlet wave-A leg. The two open
findings became `archive/menu-subject-routing-plan.md`, now CLOSED too (the two dead dev-tools items
fixed, the latent `triggeringWidget` mis-feed given its adapters).
- **Stated limits of the sweep, so nobody reads a green run as more than it is** (all printed every
  run, so a drift is visible rather than silent): it covers DISPATCH, not click plumbing (it fires the
  action directly — a real click tears the menu down under the walk; the suite covers the other side);
  its roots are **hand-picked representatives plus the world in both of the shapes it builds a menu
  in** — a coverage model, not exhaustion, and the rig prints the live root count and REPORTS any
  root it could not build; and ~51 items per run are skipped because an earlier item in the same walk DESTROYED the
  receiver. ⚠⚠ **A rig that mutates the world manufactures its own bugs** — `make pointer` looked like
  a find until it was re-run in ISOLATION and did not throw. **Re-run any sweep finding in isolation
  before believing it.**
- [ ] Expand the root list only when a bug is found in a class that has none — generic instantiation
      of ~270 widget classes is fragile, and the reported unbuilt-root count is what makes the gap visible.
- ⚠ **The gauntlet WIRING for this leg lives only in the local `fg`** (the umbrella is not a git repo),
  so the rig is committed but its enforcement is not — true of every `fg` leg, noted because "it is
  gated" holds on this machine only.
- ⚠ **The sweep's DISTINCT count is coverage BREADTH, not a ratchet** — it moves in BOTH directions on
  changes that lose no reach, because `Widget._attachToChosenParent` builds one menu row PER WIDGET
  CURRENTLY IN THE WORLD. `menus walked` is the stable reach number; `--verbose` prints the pair set so
  a move is diffed, not argued about. (Detail: `archive/menu-subject-routing-plan.md` §5.2.)

### `archive/constructor-parameter-conformance-plan.md` — **CLOSED, P0–P9 all landed**
The arc's narrative, decisions and standing lessons live in that plan's BACKLOG ledger.
- [ ] Plan §7d-D, deliberately left open: `Widget.textPrompt` keeps a `msg` operand its only
  receiver (`CodePromptWdgt`) has no title bar to display, so the value goes nowhere. The dead
  FIELD is gone; whether the door should shed the operand is an owner call, not a unilateral one.

### `plans/affine-transforms-plan.md`
Phase 4 + residuals + claimsSpace arc shipped/pushed; §7.7 appearance local-coords LANDED 2026-08-12
(`archive/appearance-local-coords-plan.md` — every appearance body now draws through the ctx matrix,
byte-identically; the vector-replay prerequisite is banked); §7.8 SWCanvas bilinear LANDED 2026-08-12/13
(both halves — the as-built record is that plan's §7 banked-item 8, and the closed BACKLOG line for
it now sits in the plan's § "BACKLOG ledger"); REMAINING = big §7.1-7.4 items, design-first, owner-gated.
- [ ] §7.1: transform policy engine (banked, not built)
- [ ] §7.2: leaf self-warp (non-island rotation)
- [ ] §7.3: quad-aware damage + occlusion behind transformed widgets
- [ ] §7.4: density folding (owner-downgraded priority)

### `plans/dataflow-engine-implementation-plan.md`
Phases 0-8 plus F1/F2/F4/F5/F6 all LANDED; remaining = F3 ('operate ➜' cell menu); the deferred `firesPerEvent` delivery lane is owned by `plans/wire-vocabulary-extensions-plan.md` W1.
- [ ] F3: 'operate ➜' cell menu — value-class method introspection into a formula

### `plans/wire-vocabulary-extensions-plan.md`
AUTHORED 2026-07-24, NOT STARTED, owner-gated; land the reserved wire semantics (per-event delivery, cold edges, buffer payloads) + record the deadline law. Demand side: `architecture/app-fit-criteria.md` facet 9.
- [ ] W1: `firesPerEvent` per-event mini-pass DELIVERY (spec §4/§13) — flag/menu/edge records landed, delivery still POOLS (`DataflowEngine.markStale` deferral note); resolve D1–D5 (scoping, settle, pool hygiene, re-entrancy, determinism); acceptance = CounterPatchNodeWdgt + t1–t3
- [ ] W2: cold edges (spec §8, attribute carried, zero readers) + cold-then-hot structured-event idiom; riders: Diffing `setInput2` bug, written-never-read `setInput*IsConnected` flags, plain/`Hot` setter-pair rationalization
- [ ] W3: buffer payloads as current values — immutable `BufferValue` handle (identity/generation equality), `bufferSetters()` fourth table; spikes S1 (serializer has NO typed-array arm today) + S2 (DeepCopy policy)
- [ ] W4: the deadline law — signal-rate stays below the floor; lands into spec/architecture as residue when W1–W3 land

### `archive/connector-ubiquity-and-reflection-plan.md` — ✅ CLOSED 2026-08-18 (P1–P9, P10(c)+(d))
Authored 2026-08-14; the law it landed is **a controller is a view of the value it controls, and
stays one however that value changes**. Every landed step, and every defect found while landing
one, is in that plan's "As landed" blocks and in its § "BACKLOG ledger" — read those before
trusting any section's original sketch (§2.4 in particular is history: P1 replaced the write-only
tables it surveys). Not the wire *vocabulary* (that is the plan above). What stayed open is one
by-catch defect, five follow-ons that each want their own decision or arc, and the two
re-homed/refused items:
- [ ] **`getPixelColor` returns a `Color` whose alpha is in the WRONG UNITS** (found alongside the `BackBufferMixin` per-pixel hit-test fix — `catchesPointerAt` today — in that plan's § "BACKLOG ledger"; NOT fixed). `Color._a` is documented as "opacity as a number between 0.0 and 1.0", but `getPixelColor` does `Color.create data.data[0], data.data[1], data.data[2], data.data[3]`, passing the raw 0..255 byte into a parameter declared `a = 1`, and `Color.create` does not normalise. Harmless for the fully-transparent test (0 is 0) but it hands every other consumer an out-of-contract value — `PaletteWdgt.pickColor` takes its picked colour straight from here, so a picked colour carries `_a: 255` instead of `1`. Check what that reaches before changing it: the divisor is a one-line fix, the blast radius is whoever compares or serializes that alpha.
- [ ] **THE SHADOW PASS HAS THREE COVERAGE STRATEGIES AND THEY DISAGREE** (found while landing the pop-up-overflow arc; owner-raised). `Widget.coffee` states the contract at the shadow entry point — *"a shadow is the caster's per-pixel COVERAGE"* — and coverage is an OPACITY, so two coincident opaque widgets have coverage 1, not 1.36. Three implementations exist: **(1) recursive re-paint** (the general path) draws every descendant as shadow, so overlapping opaque children STACK — 0.2 over 0.2 composites to 0.36, which is a visible doubly-dark core in the band under every menu and prompt; **(2) the opaque-panel short-circuit** (`ClippingAtRectangularBoundsMixin`, `if @alpha != 1` — a fully opaque clipping panel draws ONE rectangle and skips its children); **(3) the silhouette blit** (`HTMLCanvasElement.blackSilhouetteOf`, used by `BackBufferMixin` and the transform islands). ⭐ **The "optimisation" (2) and the buffer path (3) are the only ones that honour the contract; the general path (1) is the broken one** — so the shadow a subtree casts today depends on whether an ancestor happens to be an opaque clipping panel, which is not a property anyone reasons about. ⇒ unify on the silhouette. ⚠ Own arc: it changes EVERY shadow in the system (removing every doubled band), so it needs its own before/after evidence and a deliberate mass recapture, not a side effect of something else.
- [ ] **Menu LENGTH is now a pure UX question, and worth its own arc.** Widget context menus run 19–42 rows (measured 2026-08-17 at the harness world: `TextWdgt` 40, `StringWdgt` 36, `SimpleTextWdgt`/`TitleWdgt` 33, `SliderWdgt` 26, `RectangleWdgt` 19). Nobody scans 40 rows. Grouping related rows behind submenus — what §P2 did locally for `connect ➜`/`bind ⇄` — would shorten every menu. Deliberately NOT bundled with the overflow fix (owner call): the fix establishes the invariant so no row count can break reachability again, which is what makes the length question a taste question rather than a correctness one.
- [ ] **A2 residue — `SliderWdgt.value` is the one readable pin that still cannot declare `announces`, and closing it is the FOLLOWER arc's job.** Its value-producing paths announce; its two value-SHOWING paths (`_updateHandlePosition`, `_updateSpecs`) do not and must not yet — neither has an equal-value cutoff, so an announcement there would re-fire on every drain pass, a self-sustaining loop with **no cycle in it at all**. Three things belong together in that arc and none is worth doing alone: (a) the cutoff on those two; (b) a SECOND reflector — something that shows a value it does not own without needing a `SliderRange`, e.g. a label displaying a widget's value live — which is the only thing (a) would buy anything for; (c) ⚠ **the cycle rule**: two mutually-tracking controllers are prevented today by an ACCIDENT (`SliderWdgt` does not answer `sliderRangeForPin`, so slider-follows-slider cannot be built), not by a rule. The right shape is to refuse the cycle where it would be CREATED — `_canTrackWire` rejects a target that already follows me — rather than keeping the graph deaf so cycles cannot form, which is what the suppressed announcements did by accident.
- [ ] `FanoutWdgt` is now a visual affordance over a capability every citizen has, rather than the only way to fan out (P4). Nothing forces a rewrite and it lives in a part production does not ship — do it when something needs it.
- [ ] **The absorb-query CUT WIRE is a CLASS, not an instance — AUDITED 2026-08-18, root cause single, and DELIBERATELY NOT FIXED.** A parent-directed capability query (`@parent?.someQuery?()`) names its receiver by POSITION, so inserting a container between two collaborators silently re-points it: the `?.` returns undefined, the caller takes its "no opinion" arm, and nothing says a word. Fixing one instance of that (the pop-up rows pane, `9f4ba5d4`) raised the obvious question, so the whole family was measured. **The audit criterion is mechanical**: the DIRECT parent does not implement Q but a HIGHER ancestor does ⇒ cut. (If nobody in the chain implements Q, that is the ordinary "this class has no opinion" case the `?.` exists for, and is not a finding.) ⚠ It only bites queries with REACH intent — a query genuinely ABOUT the direct parent (`isFrame`, `showEditModeInBar`) makes a grandchild look "cut" when it is merely nested, which is why the raw criterion reported ~110 hits over 193 widgets and the reach-intent ones reported 4. Domain: **21 parent-directed query sites, 14 distinct names** (`grep -rn "@parent\??\.[a-zA-Z_]*?(" src/`). ⇒ **The absorb query `_reLayOutAfterContainedPanelChange` is cut everywhere the container is a plain `ScrollPanelWdgt`, and the root cause is ONE thing: a scroll panel's `@contents` is a plain `PanelWdgt`, which does not forward** — so `FrameWdgt` in a scroll panel, `SimpleVerticalStackPanelWdgt` in a scroll panel, and `MenuRowsPanelWdgt` in a `ListWdgt` all reach a silent `PanelWdgt` while the class that implements the absorb sits one level higher. ⚠⚠ **Measurement also overturned the reasoning that would have dismissed the frame case**: `ScrollPanelWdgt.add` redirects only non-frame children into `@contents`, from which it follows (wrongly) that a frame is a direct child of the scroll panel — a live frame dropped in one has parent `PanelWdgt`. ⇒ **NOT FIXED, and the reason is that NOT ALL ABSORBS ARE EQUAL.** `PopUpWdgt`'s absorb re-takes the POP-UP'S OWN EXTENT and nothing else ever does, so missing it left a wrong FINAL state — a menu drawn at its old height with a blank strip (measured: 255px, still 255px after 3 cycles, 210px when the absorb is forced). `ScrollPanelWdgt`'s absorb only runs synchronously what the deferred arm (`_reFitContainer`) runs at the next cycle anyway: measured, the cost is **ONE CYCLE of a stale scroll thumb** (52px in the absorb window, 61px after the cycle) and forcing the absorb after settle changes NOTHING. Nothing observes a within-cycle transient — screenshots are taken at settle points — which is why 304 tests are green. ⇒ **Next step if it is ever worked: it is a DESIGN choice, not a patch** — forward on `PanelWdgt` (broad, one line, but changes every scroll panel's flush timing), or give `ScrollPanelWdgt` its contents a class of its own as `PopUpRowsPaneWdgt` is (heavier, precedent exists), or change the asker contract to climb rather than ask the direct parent (touches all four askers). ⚠ `ListWdgt._reLayOutAfterContainedPanelChange` returns `undefined` DELIBERATELY (a stated opt-out) — so it is correct today by two independent routes, and any fix must keep it opted out. Probes: `Fizzygum-tests/.scratch/a3-parent-query-reach-audit.js` (whole family, 193 widgets), `a3-absorb-reach-nested.js` (the nestings where a receiver can exist — the general audit's fixture had every frame on the bare desktop, where "nobody answers" is correct and proves nothing), `a3-absorb-consequence.js` (the visible cost).
- [ ] ⛔ P10(a) RECORDED REFUSAL: `ButtonWdgt.trigger` does NOT get routed through the dataflow drain (pools destroy click counts; no value to pull; commands aren't pins; 328 menu actions would each need the `_*NoSettle` lattice the ONE 6c prompt slider needed). Revisit only after W1 lands, opt-in per button

### `plans/livecodelang-cleanup-and-extensions-plan.md`
AUTHORED 2026-07-07, NOT STARTED; owner-initiated execution only.
- [ ] T1 R1-R4: headless preprocessor test gate + corpus fixes — not started
- [ ] T2 R5-R10: correctness fixes: escaping, boundary guards, magnet geometry, tan collision
- [ ] T3: dead weight & duplication removal, corpus must stay 300/0 — not started
- [ ] T4: preprocessor structural refactor, behavior-preserving — not started
- [ ] T5: language/runtime extensions, owner picks which — not started

### `plans/occlusion-culling-plan.md`
P0-P3 (Avenue A) LANDED 2026-07-09; P4/P5/P5b/P5c OWNER-GATED, not started.
- [ ] P4: Avenue B maintained covered-rect list, replacing per-rect traversal — not started
- [ ] P5: descend to nested opaque panels/window bodies — optional, not started
- [ ] P5b: hand-carried drag coverer (hand paints last, uncounted today) — not started
- [ ] P5c: fringe decomposition of the dragged window's own rects — not started
- [ ] **`BubblyAppearance.shapeContainsPoint` OVER-CLAIMS its tail strip** (named in the class, not silent; found while re-homing the shape predicates onto the appearances, 2026-08-21). A bubble's rounded body occupies only the top `h - h/5`; the bottom fifth is empty except for the spike. It inherits `BoxyAppearance`'s rounded-box test, so a click in the empty corner beside the spike stops on the bubble instead of falling through. Harmless today (bubbles and tooltips are not things you click past), and correcting it needs an analytic body+spike point test — a BEHAVIOUR change with hover-pixel churn, not a rename. Its `opaqueCoveredRect` twin was NOT harmless and is already refused (it would have dropped pixels under a `ToolTipWdgt`).

### `plans/pixel-icons-plan.md`
AUTHORED 2026-07-18, NOT STARTED; replace ~79 vector `*IconAppearance` files with ASCII index-mask pixel icons (16/32/48 all supported, per-icon subset by usage cohort, coverage-rule variant selection; maps/gradients/logo-with-text stay vector); ⛔ two owner gates (P0 aesthetic, P4 mass recapture).
- [ ] §5 pre-step: owner re-judges the convert list against the crispness-audit tiers (`measurements/vector-icon-crispness-audit-2026-07-19.md` §7) — per icon now a THREE-way choice: keep-vector / pixel-grid / size-aware redraw (§5b; 9 icons LANDED by 2026-07-22 on the shared `SizeAwareIconAppearance` base — Typewriter/Folder/ShortcutArrow, super-toolbar, generic-panel, patch-programming, simple-slide, dashboards, Bin; process = local skill `/convert-icon-size-aware`)
- [ ] P0: spike (`PixelIconAppearance` + hand-converted Heart) + native≡SWCanvas byte-identity evidence + ⛔ owner aesthetic sign-off
- [ ] P1: rasterizer/parser hardening (variants, crop, literal palette entries)
- [ ] P2: sentinel-supersample authoring tool + all-icon draft contact sheet
- [ ] P3: mass conversion of ~79 appearance files (markers byte-verbatim; Wdgt files untouched)
- [ ] P4: red-set enumeration → diffpage → ⛔ owner recapture approval → serial mass recapture → gauntlet
- [ ] P5: WRITE `architecture/pixel-icons.md` (it does not exist yet — this step is what creates it), measurements, archive+close
- [ ] P6 (banked): dot-mode at large scale; in-system pixel editor; dead vector-helper prune (⚠ FanoutPin uses `_paintRoundedSquareBadge`)

### `plans/runtime-performance-optimization-plan.md`
H1/Arc2-4/W1-W2/A/C1/O1/O2/O4a landed; O4 attribution + correction DONE 2026-07-24; NEXT = O3
- [ ] §5B O3: per-widget/descend occlusion (plan P4/P5) — large, owner-gated
- [ ] §5B O4b: SWCanvas glyph-run batching — ⚠ DE-URGENTED by the O4a correction (steady-state glyph stream ≈ just the desktop logo); do not build on the pre-correction numbers. O4a's as-landed entry is in this plan's § "BACKLOG ledger"
- [ ] §8/top banner: S2 Tier 2, S6b, F1 (precompiled test-harness boot) still unlanded
- [ ] §5 F3: dirty-rect DOM present — deprioritized, not landed

### `plans/single-file-save-plan.md`
AUTHORED 2026-07-10, design LOCKED by owner, no code written yet; next = Phase 0 spikes S1/S2
- [ ] §5 Phase 0: S1 FizzyPaint round-trip spike + S2 hand-built prototype — not yet run
- [ ] §7: banked v1-excluded items: precompiled file, SWCanvas strip, baked edits, dirty guard

### `archive/onion-widget-composition-plan.md` — "The Frame model" — ✅ FLAGSHIP ARC COMPLETE 2026-07-20 (A·C·B·D·E); follow-ons below
Naked `Simple*` capability → framed `*Wdgt` citizen (`FrameWdgt`, was `WindowWdgt`) → App=launcher. Intrinsic-framing principle LOCKED (D1–D9). Correctness-first — no churn deferrals. Every landed phase (§5 P0, A, B, C and its two dock tails, D-1/D-2/D-3, E, E1's refusal, E3, plus the build-tooling and census riders) is in that plan's § "BACKLOG ledger".
- [ ] §5.B follow-ons: `DeckWdgt` = D2 reserved name, no substrate yet. Creation-menu wording ✅ 2026-07-20 — the citizen-creator dev-menu labels renamed to the kind ("simple document"→"document", "Simple slide"→"slide", + the two launchers "document launcher"/"slide launcher"); recapture-FREE (those labels are dev-menu-only, navigated/screenshotted by no test). The `simple plain text …` dev-menu cluster left as-is (out of scope, owner kept it tight)
- [ ] §5.D follow-ons: a load-image-FILE flow into `ImageWdgt` (owner decision D13: `SimpleImageWdgt`, the bitmap loader, stays a sibling payload with its one button-face consumer until such a flow exists — the stamp drop-flow already imports pixels). ⚠ 2026-08-02: `SimpleImageWdgt` moved out of core into the `video-player` part (nothing on the boot path reached it; its only consumers are that part's). Since `video-player` is `requiresFlag`-gated, it now ships ONLY with `--includeVideoPlayer` — so building this flow means first deciding where the loader belongs. The ungrammatical "a Image" hierarchy row ✅ FIXED 2026-07-20 — `Widget.toString` now derives the article ("an" before a vowel-initial class name, else "a"); probe-verified (`an Image`/`an AnalogClock`/`a Rectangle`), zero recaptures (no test screenshots a vowel-initial menu label)

### `plans/creation-and-templates-plan.md`
AUTHORED 2026-07-18, design-stage/exploratory, owner-gated; create = duplicate-a-template (Factory) | run-an-assembler (ScriptRunner); App = a Factory over an empty framed `*Wdgt` in edit mode. Supersedes the reference plan's launcher/Factory.
- [ ] §4.1: name `FactoryWdgt`/`ScriptRunnerWdgt` (use `isTemplate` + the `Duplicator`)
- [ ] §4.2: redefine "App" as a Factory over an empty framed `*Wdgt` in edit mode
- [ ] §4.3: fold the creator zoo (CreatorButton/WidgetFactory/MenusHelper "new X") onto the two primitives — second wave
- [ ] §4.4: (bank) templates as first-class editable objects

### `plans/reference-widgets-plan.md` — RE-SCOPED (UI + lifecycle areas only)
AUTHORED+RE-SCOPED 2026-07-18; link/GC → graph-edges plan, launcher/Factory → creation plan. Residual = the visible reference UI + desktop lifecycle areas, built on those two arcs.
- [x] §4.1: prefix retired 2026-08-19 — owner-ratified SHORT ROLE NAMES (`ShortcutWdgt`, `AppLauncherWdgt`, `WindowedApp`, …; the `Reference*` sketch was rejected — launcher ≠ reference); table in the plan's §4.1 as-executed block
- [ ] §4.2: minimise-to-a-bar, distinct from collapse-in-place (second wave)
- [x] §4.3: trash — RATIFIED 2026-08-18 as sever+close (one store, no views) and EXECUTED 2026-08-19 (`Widget.moveToTrash`, referent-death sever, conditional menu row, `fg graph` §5) + the R3 `bringUpReferencedWidget` rename
- [x] §4.3/R5: drop into the OPEN BIN = trash intent — EXECUTED 2026-08-19 (both drop surfaces run the sever core; the drop sticks; drop-specific relay so automatic filing never severs)
- [x] §4.4: the ARROW CONTRACT — ratified, pressure-tested AND EXECUTED 2026-08-19 (glyph = copy semantics via `ShortcutWdgt.representsContents`, ONE ctor assembly site; the closure `Widget.allWidgetsInStructureForCopy` feeds Duplicator AND `Serializer.buildEnvelope`; referent copies/restores filed to the shelf; the 6 wrong arrow wearers de-badged; bin refuses duplication; `fg graph` §6 = 19 checks, serialization rig +4) — see the plan's §4.4 as-executed block
- [ ] §4.4 follow-up: what does save-to-file mean for an ARROW'D shortcut (today: friendly error — no cross-file identity for a dangling-`.lnk` restore; needs its own decision)

## Residual / parked items (owning doc archived)

### Naming-gloss audit 2026-08-18 — names the comments had to apologise for
Session-scoped audit (no plan doc; detectors in `Fizzygum-tests/.scratch/naming-gloss-audit.js` +
`naming-dup-comments.js`), prompted by the `localArea` → `localDamageBox` rename: a comment that
must TRANSLATE a name into a different noun phrase at the point of use is a vote that the phrase
is right and the name is not — and the strongest signature is the WARNING comment ("X is NOT the
Y"). Eleven detectors over the 20k comment lines; 234 glossed identifiers triaged, most glosses
being legitimate role-explanations rather than name-apologies. Discipline: per the
menu-dispatch-residue lesson, every candidate's CONSUMER was read before calling the name a defect.
Everything the audit CLOSED — the seven renames, the dispatch-slot protocol, the damage-vocabulary
unification, the `p0` collapse, the F3 re-sweep and the declined list — is in
`archive/backlog-closed-items-ledger.md`. One filing is still open:
- [ ] **Glyph-drawing duplication the `p0` collapse made visible** (filed 2026-08-18; the `p0`
      collapse itself is in `archive/backlog-closed-items-ledger.md`; NEW filing, not
      a reopening of the closed duplication campaign): `SimpleDropletAppearance` and
      `LayoutElementAdderOrDropletWdgt` draw a near-identical plus sign (same `squareDim/15` flap
      arithmetic, same `0.5 +` stroke idiom), and `HandleAppearance.drawHandle`'s horizontal-arrow
      arm is the same drawing as `LayoutSpacerWdgt.drawReplacerWidget` (identical anchor
      `leftEdgeMiddle`, identical flap constants, one calls `drawArrow`, the other `doPath`). A
      small shared glyph-helper would fold both pairs. Work it only when one of these files is
      next touched for its own reasons — standalone it is churn without a consumer.

### One line each — every item names the archived plan and section that owns its detail

- [ ] `archive/atlas-delay-fuzz-tool-plan.md` §9: `fg fuzz` has NO working regression fixture — §5 test 3 (revert flake A's `waitForScreenshotReady` and expect a catch) does not reproduce: 13/13 passes under injection AND 3/3 with none, because a fresh page makes ~1 `loadFont` call against a ~one-frame window. A fixture needs a scenario with MANY atlas loads and a pixel read near one of them. Until then the tool's own failure paths are covered only by the canned-transcript corpus (`npm run selftest`) plus the two live INVALID drills.
- [ ] `archive/build-arc-4-dynamic-parts-plan.md` §5.4 (phase 3, DECLINED by the owner 2026-07-30 — optional by construction, NOT an unfinished retirement): flip further parts to `"eager": false`. Ready: `dev-icons` (14 classes, zero call-site work) and `patch-programming-experimental` (6 classes, check its menu entry points first). ⛔ `demos` / `dev-tools` are the bigger case and probably not worth it — both are constructed AT BOOT (`globalFunctions.coffee` builds `demoMenus`; `WorldWdgt` builds `world.widgetFactory` / `world.pinouts`), so laziness there means converting boot-time construction into on-demand construction, a different change from the pilot's. `meta-tools` (inspectors) additionally needs an ingestion-on-demand seam. Each flip = `"eager": false` + entry-point conversion (the promise API, NOT an `if X?` guard — that would swallow the click) + `fg gauntlet` + a smoke absence assertion.
- [ ] `archive/basement-dormant-layout-flag-plan.md` §5: design + implement the cached _inBasement flag
- [ ] `archive/basement-dormant-layout-flag-plan.md` §7: step-by-step build of the flag — not started
- [ ] `archive/basement-dormant-layout-flag-plan.md` §8: mandatory gauntlet + dpr2 torture verification — never run
- [ ] `archive/basement-to-bin-plan.md` §6 auto-empty: empty the bin automatically at snapshot/quit — DEFERRED, not rejected; revisit after living with the Bin (recoverability expectations; the doGC on-screen precondition it worried about is GONE since the bin/shelf split)
- [ ] `archive/basement-to-bin-plan.md` §4 Phase 3c: bin presentation — swap the pseudo-random scatter for a representativeIcon grid — cosmetic follow-up, owner kept scatter for the semantics arc
- [ ] `archive/caret-follow-in-place-settle-plan.md` §5: decisive first step: trace where typing's caret drains today
- [ ] `archive/caret-follow-in-place-settle-plan.md` §6: implement the fix shape once §5's trace is known
- [ ] `archive/caret-follow-in-place-settle-plan.md` §7: mandatory byte-exact verification protocol — not run
- [ ] `archive/claimsspace-footprint-default-and-scroll-reachability-plan.md` §5 S3 / G2: owner halo feel-check (desktop/document/scroll-panel), post-push
- [ ] `archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md` §8-C follow-up 4a: FizzyPaint canvas-resize ghost — fix identified, couldn't reproduce to verify
- [ ] `archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md` §8-C follow-up 4b: broader ScrollPanel resize-preservation — implemented, verified no-op, reverted
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: whether PNG export flattens over opaque background — uninspected
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: backfill blast radius (SWCanvas ref count, scriptability) — uncounted
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: cross-engine (V8 vs JSC) invisible-pixel residue identity — unverified
- [ ] `archive/god-class-decomposition-plan.md` Tier 3 / C21: context-menu construction relocation to menusHelper — deferred, screenshot label-strip risk
- [ ] `archive/hover-resync-after-flush-plan.md` § CAPSTONE GATE WEAKNESS note: paint-readonly gate shares the careless-push-count-only weakness — still open backlog
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.2 A3: must-call-super table-driven rule — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.4 A6: dead-class detector (ReClassNotReferencedRule) — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.5 C: per-file metrics ratchet for god-class line counts — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.9: empty-catch stink — needs multiline stink-engine extension
- [ ] `archive/lint-ratchet-static-checks-plan.md` Phase 4: encode tier in underscore prefix on immediate mutators — PARKED, owner-gated, low priority
- [ ] ⛔ `archive/paint-time-scroll-translation-plan.md` Phase 4 (OWNER-GATED): lift `scrollOffsetX/Y` + `_writeScrollOffset` + the paint interception + the `scrollTranslationOfChild` provider from `ViewportWdgt` to the clipping-mixin level — "scrollability as a property of every panel". Designed, deliberately unlifted until a second user exists (YAGNI; the seam is stated in that plan's STATUS BOX Phase-4 row). Phases 0–3 of the arc are EXECUTED (2026-08-20): the offset is stored truth, the plane is pinned, paint/hit/damage/clip/input all speak the translation; living truth = `architecture/viewports-and-planes.md`.
- [x] **RESOLVED 2026-08-20 — the menu sandwich is DISSOLVED** (`archive/menu-sandwich-dissolution-plan.md`, executed same-day from Phase 0): `PopUpRowsPaneWdgt` is deleted and `MenuRowsPanelWdgt` is the pop-up rows viewport's DIRECT contents, byte-identically (S2: 306/306, zero recaptures). The refusal below is answered not by removing the second writer but by making the writers AGREE in every state: the panel's `scrolledContentMeasure` answers its FULL self-box (the hug, bottom border included) and declares `scrolledContentMeasureIsMyFrame`, so the committer commits that measure VERBATIM — the content-sizing commit's window-floor + grow-to-fill (the round-1 livelocks' mechanism, re-measured through menu-compose and the duplication path) are skipped for such a plane. The refusal's own reopen condition ("the hug as a pure measure consumed by the committer") is exactly what landed; its "sole committer" phrasing was aspirational — the in-tree law is agreement-at-fixpoint (every stack under a committing viewport already self-writes its height). ⚠ `ListWdgt` KEEPS its interposed pane deliberately (Phase 2 ASSESS = KEEP): the list sizes its rows panel PAST the hug (anti-vacant-space `_applyExtent`), so the panel's unconditional hug self-write and the list's committed frame structurally disagree — there the pane is the load-bearing second surface. Falsification history preserved below; living truth: `architecture/viewports-and-planes.md` (the scrolled-content contract).
- [x] `archive/scroll-frame-role-architecture-plan.md` §7.2 RECORDED REFUSAL (revisited + RE-falsified 2026-08-19; **resolved by the line above 2026-08-20** — kept verbatim as the falsification record): menu rows panel as direct viewport contents livelocks EVEN WITH the P5 contract fully declared — the spike carried `viewportConstrainsMyWidth false` + `isContentSizing true` on the pop-up viewport + the absorb forward, built clean, and RECALC_NONCONVERGENCE fired on essentially every menu-opening test. Measured mechanism (probe `Fizzygum-tests/.scratch/sandwich-direct-livelock-probe.js`, instrumented ring buffer): a permanent two-writer oscillation — the viewport's contents-commit writes the pure measure (w 64→62, h 21→40: the base stack measure distributes padding INSIDE availW and the content-sizing arrange grows height to fill), then `MenuRowsPanelWdgt`'s own arrange re-asserts its hug (w 62→64 = widest row + 2·padding; the tight stack re-hugs h 40→21), forever. ⇒ The width-ownership declaration governs only the `_applyWidth` normalization; the REAL conflict is frame OWNERSHIP — the contract makes the viewport the plane's sole frame committer, and the menu panel is a SELF-frame-writing plane. The historical "width-constrain fights the hug" story was the shallow reading; a free-width stack survives as direct contents because it owns its width PASSIVELY. Reopen ONLY by redesigning the hug into a pure measure with the container as sole committer — which must also serve the pop-up's own `_layOutAndHugRowsPanel` path, where no viewport commits for the panel.
- [x] **DONE 2026-08-21** — **the construction-determinism ratchet's exemption list is 43 names → 1.** It was answering a question the arc retired: the fingerprint used to be taken AT TEARDOWN on the outgoing world, mid-cycle, so per-cycle transients (damage queues, paint-bounds flags, healing phase, last-painted footprints) were legitimately mid-flight and each needed exempting. Under reconstruction it is taken on a world that has just been BUILT and has not run a cycle, so all of those sit at their construction defaults identically every time and cannot be exceptions. ⭐ **Measured, not argued: with the entire list disabled, a full parallel dpr1 suite (307 tests, 8 shards) produced 239 gate violations naming exactly ONE field — `lastTime`**, the clock reading `Widget`'s constructor seeds, which is the one exemption reconstruction itself creates. ⚠ A 3-test SERIAL sequence was run first and also showed only `lastTime`, but that proves nothing on its own: the per-frame entries were originally added because they surfaced under PARALLEL load, where the teardown lands elsewhere in the cycle — so the parallel suite is the condition that can falsify, and the full gauntlet (whose audit legs arm instrument flags on every world through their preludes) is what validates the prune. ⭐ The census also found 3 names already covered by the `_isDerivedCacheFieldName` RULE (`check*Cache`) and 2 — `gcSessionId`, `broken` — naming no field the world has at all: the invisible dead weight the list's own comment warns about, since a sweep asks only about fields it FINDS and a stale name reads as diligence.
- [x] **DONE 2026-08-21** (D3, owner-approved) — **meta-built prototype and static MEMBERS are NAMED**, finishing what D-P2g started on constructors. `Class._nameTheMemberFunction` turns the compiled `(function(` into `(function <memberName>(`, so a heap-snapshot function node reads its member. ⭐ Measured: `Widget.prototype` carried 369 methods of which **367 were anonymous**, and a method reached through `.bind(this)` — the shape that actually retains a widget — snapshotted as `bound ` with nothing after it; now 369/369 are named and it reads `bound fullDestroy`. (JS does not infer a name for assignment to a MEMBER expression, which is why these were `""` while `var f = function(){}` would not have been.) ⚠ **Safety was censused before the edit, not after**: across 3202 members / 1899 distinct names there are no reserved-word names, no collisions with a class name or a boot/helper global, and **zero** members making a bare call to their own name — the hazard being that a named function expression binds its own name inside its own body. Three members assign to a local sharing their name (`Point.theta`, `TreeNode.siblings`, `Widget.prompt`); CoffeeScript declares each as a local `var`, which shadows the function-name binding, verified live (`theta` of (1,1) still 45°) — and that check mattered because the eval'd code is NOT strict, so a missing declaration would have been silently ignored rather than throwing. ⚠ The guard list holds only the three CoffeeScript helper globals (`hasProp`/`indexOf`/`slice`), which member bodies reach as FREE identifiers: that is the SILENT hazard. Reserved words are deliberately NOT listed — one would be an illegal function name and throws at class-build time for everyone, and a failure that loud needs no list. ⭐ Enumerating them also cost two stink baselines on the first attempt: the scanners are TEXTUAL, so the literals `"null"` and `"instanceof"` in a deny-list counted as a `null-literal` and an `instanceof-type-test`. ⛔ Still do not look widgets up BY name in a snapshot — names are not unique and the emit is not a contract; identity remains the object id. ⚠ **The names are a DEV-TREE fact.** Terser mangles a function-expression name like any other binding (`WorldWdgt=function t(e` in a `--profile homepage` image), so nothing named here survives into production — which is the right trade rather than a gap, since forensics runs on the harness tree that compiles from source text at boot. Payload cost is therefore bounded by the mangled form (`function t(` vs `function(`, ~2 bytes × 3202) rather than by the names themselves; do not reach for terser's `keep_fnames` to "fix" this, which would buy readability in the one tree nobody profiles.
- [x] **DONE 2026-08-21** — `AutomatorPlayer.createImageFromImageData`'s unreleased `img.onload`/`onerror` are **deliberately KEPT**, with the reason recorded at the method so the item cannot be re-filed; and the investigation found a **real defect beside it that is now fixed**. ⭐ On the filed half: the benign verdict is right, and the argument is structural, not empirical — everything pointing at the Image is also pointed at BY it (`img → onload → img`, and `→ resolve → promise → img`), so it is one cycle with nothing outside it, which a tracing collector reclaims. Nulling would buy no memory and would imply a hazard this shape does not have, unlike the `<script>` sites that leak because the DOCUMENT holds the element and the closure names a world. ⚠⚠ **Do not try to settle this class with WeakRef + forced GC**: measured, the identical shape reports collected on one run and retained on the next, because collectibility answers "has the collector got to it yet" — the proxy Arc B deleted the grace period over. REACHABILITY is the question with an answer (`heap-forensics.js --snapshot` retainer paths), which is why `fg vmtruth` asks it that way. ⭐⭐ **The real find:** `saveFailedScreenshots` ended `Promise.all(allSubtractionJobsPromises).then -> packUpForDownload zip` with NO `.catch`, and each job rejects if either of its two base64 Images will not decode — so ONE unreadable reference among dozens skipped `packUpForDownload` entirely and the user got no zip and no error, on the one path they reach for BECAUSE something is already wrong. Jobs are now absorbed individually, so a bad image costs its own diff and nothing else — the same rule the `or []` guard already applied to the synchronous half of that method. Proven with the real `subtractScreenshots`: raw `Promise.all` REJECTED, mapped-through-catch RESOLVED.
- [x] **DONE 2026-08-21** (`archive/world-reset-by-reconstruction-plan.md` A7): the six drag-affordance world slots (`dragEmbed{ChargeRing,Label,LockBadge}{Declared,Wdgt}`) are cleared by `_teardownWorldStructureNoSettle`, restoring the core's unconditional contract that after `fullDestroyChildren()` the world names nothing just destroyed. ⚠ Filed as a live bug; it is really a CONTRACT repair, and the measurement is worth keeping: the hand rewrites all three declarations every cycle and clears them in its else-branch, the `resetWorld` path discards the world holding any corpses, and even after a load-during-a-drag the next cycle SELF-HEALS. The violation is real only in the window between the teardown returning and the next cycle. ⭐ That window is also the only place a gate can see it: `world.teardownHygiene.dragAffordancesCleared` reads the six slots in the same turn as `loadWorldSnapshot` returns, because measured after a settle the assertion passes with the fix REMOVED — proven vacuous once, then proven to bite (it names all six) with the clearing disabled.
- [x] **DONE 2026-08-21** (`archive/world-reset-by-reconstruction-plan.md` §D5c(b), owner-approved): the two DEAD audit flags `WorldWdgt.auditTierAndApplyNaming` and `auditNotificationSettleNeutrality` are DELETED, with their two prelude arming lines, the two log lines that echoed them, their two `_worldStateAuditExemptions` entries, and the two shell headers claiming each gate "flips on" its flag. Nothing read either: both gates take every observation from their prelude's own prototype wrappers. ⭐ The blast radius was wider than filed — `architecture/layering-naming-convention.md` §5.1/§5.2 were TITLED after the flags and its §5 preamble taught the flag as the mechanism, and `lint-and-static-checks.md` identified both gates by flag; all now describe the wrapping, with the absence stated as a rule (`WorldWdgt` carries a note: any flag in this family needs a READER first). ⚠ `doubleCheckCachedMethodsResults` and `auditPaintTimeLayoutScheduling` STAY — the first has 17+ product readers, the second is live product code even though its own gate re-implements the predicate.
- [x] **DONE 2026-08-21** (`archive/world-reset-by-reconstruction-plan.md` §D5c(a), owner-approved): the capstone gate has a real positive-coverage assertion. The prelude emits one `LAYOUTAUDIT capstone-armed` line per test, read off the world the cycle is running on, and `run-capstone-gate.sh` requires that count to equal the per-test log count — symmetric with `run-paint-audit.js`'s `checked == expectedTotal`. Proven both ways: armed 307/307 ⇒ ✓ PASSED; arming lost on reconstructed worlds ⇒ armed 6/307 and ✗ FAILED, where the same configuration previously reported ✓ PASSED on 307 real careless pushes. Both arms still print `prelude installed=307/307` — that number is synthesised per test by the runner and can never see an unarmed flag.
- [x] **DONE 2026-08-21** (`architecture/lint-and-static-checks.md`, "a gate must be able to tell BLINDNESS from CLEANLINESS"): EVERY suite-wide audit gate now carries a positive-coverage assertion, in three shapes — "the flag is armed on THIS world" (`capstone`, `paint-readonly`), "the audit RAN TO COMPLETION" plus a `-SKIPPED:<what was missing>` marker on the silent early return (`storage`), and "the WRAPPERS actually fired" (`tiernaming`, `settle`, `revisits`). Each proven by plant BOTH ways: firing ⇒ 307/307 and the normal verdict; wrappers suppressed ⇒ 0/307 and INVALID (exit 2), while `prelude installed` still reads 307/307 — which is exactly why the install count was never coverage. ⭐ `revisit-gate`'s check deliberately precedes `--write-baseline`: banking a baseline from a blind run would neuter that gate permanently. ⚠ The `fg` wrapper's `leg_headline` grep had to learn the INVALID verdict; `fg` is uncommitted workspace tooling, so that edit is not in either repo.
- [x] **DONE 2026-08-21** (`archive/world-reset-by-reconstruction-plan.md` §6, the arc's one deliberate carry-over) — the ratchet is RENAMED, not retired: token `RESETWORLD_INCOMPLETE` → **`WORLD_CONSTRUCTION_DRIFT`** (sibling to `WORLD_INVENTORY_DRIFT`), method → `_auditWorldConstructionDeterminismNoSettle` (matching the "construction-determinism ratchet" the prose already called it), page baseline `_pristineWorldFingerprint` → `_firstWorldFingerprint`. `_worldStateAuditExemptions` and `_fingerprintWorldStateNoSettle` KEEP their names — "world state audit" is still exactly what they do. Proven by plant on ONE file, both arms: a pre-hook on `_afterWorldResetNoSettle` stamping a monotonic serial ⇒ 2 × `WORLD_CONSTRUCTION_DRIFT`, exit 1; the same file stamping a CONSTANT ⇒ zero lines, exit 0 — so the ratchet compares VALUES not presence, and the fire was the drift rather than the field's appearance. ⭐ **The filed blast radius was wrong in both directions, which is why the enumeration came before the first edit.** It named the fuzz parser and its selftest as lockstep consumers: both are token-AGNOSTIC (they match only the generic `GATE-TOKEN VIOLATIONS (lib/gate-tokens.js)` header and the `gate-violations:` summary field), so there was nothing to do there; and `Fizzygum/src` has ZERO hits. But it MISSED a real one — `scripts/heap-forensics.js` hard-codes the token in its console filter, and that tool would have gone on reporting a clean page. ⚠ The genuine lockstep set is three files: the emitter, `lib/gate-tokens.js`, and that filter; the three runners consume the shared list and name the token only in comments. ⚠ A by-STRING entry in `@staticMembersToInstall` carries the baseline static, so a symbol-only rename would have stopped it being carried onto `WorldWdgt` and blinded the gate silently.
- [x] **DONE 2026-08-21** — **the shared teardown core is re-motivated, and the premise it was queued under was wrong.** The worry was that post-flip the core has one live enforcer (`loadWorldSnapshot`) and one vestigial one (`resetWorld`), which invites the drift that rotted its hand-synchronised predecessors. It does not: the core discharges **TWO** obligations with different lifetimes, and only one of them is reset-path-free. **(A)** the world drops references to what `fullDestroyChildren()` destroyed — ~25 of ~28 actions, observable only where the world SURVIVES, enforced by `loadWorldSnapshot` + `world.teardownHygiene.*`. **(B)** page-lifetime state lets go of what was destroyed — exactly three actions (`WorldWdgt.timeOfEventBeingProcessed` a class static, `ToolTipWdgt.ongoingTimeouts` a class-level timer set, the module-level SWCanvas cold-glyph array): these **outlive every world the page builds, so discarding a world does not touch them** and they are owed on BOTH paths, enforced by `WORLD_INVENTORY_*` + `fg vmtruth`. ⭐ **Measured, not argued, and it runs backwards to intuition:** removing `@errorConsole = undefined` (A) leaves a 3-test reset sequence GREEN and fails only the snapshot rig on `noDanglingSlots`; removing `WorldWdgt.timeOfEventBeingProcessed = undefined` (B) FAILS the reset path with `WORLD_INVENTORY_DRIFT` although that world is dissolved a phase later. ⚠ NO structural split: both halves must run at the same seam for both callers, so splitting would scatter topically-cohesive code (the two tooltip clears) to buy nothing. The defect was the CONTRACT SENTENCE, which described (A) only — so a (B)-class addition had no stated home and a reader trusting it concludes the whole core is reset-path dead weight, which is exactly the wrong conclusion. The header now states both obligations with their gates and their plants; each (B) line is marked where an author edits. ⚠ The header was also still naming `_resetWorldNoSettle`, a verb Arc C DELETED, and describing the reset path as restoring a look it no longer restores; both repaired. Name kept: unlike a gate TOKEN nobody greps `_teardownWorldStructureNoSettle` out of an error message, and it is incomplete rather than false — the contract directly above it is what an author reads.
- [x] **DONE 2026-08-21** (`archive/world-reset-by-reconstruction-plan.md` §D4b tail) — the module binding `swCanvasPoisonedKeyRecorderInstalledOnCache` is **DELETED**, and the installer now asks the cache instead: the wrap installs `set`/`get` as OWN properties and an uninstrumented `LRUCache` carries both only on its prototype, so `hasOwnProperty(cache, "set")` **is** the record that this cache is wrapped — kept by the object the fact is about. ⭐ The filed constraint ("the identity-latch design that holds the cache object rather than a boolean is deliberate — any fix must keep that property") is kept in full: the decision is still PER CACHE, which is the property a once-true boolean would destroy. What goes is the second copy of that fact, and with it the retention. ⭐⭐ **Measured both ways with Arc B's oracle** (WeakRef + forced GC, swept off the world cycle): capture the live cache, put 40 entries in it, `resetWorld`, force GC — **before, `deadCacheStillReachable: true` with all 40 entries still held and still held three resets later; after, `false`.** Confirmed the retention was real, page-lifetime, and released only by a later cold-glyph draw onto a different cache — which cannot be counted on, because the installer runs ONLY from `swCanvasRecordColdGlyphDraw` and a warm-atlas page takes no cold draw. ⚠ A second measured reason to prefer asking the object: a note outlives anything that replaces the methods it describes, so it can DISAGREE with the cache; `hasOwnProperty` cannot. ⚠ All four behaviours re-proven after the change — unwrapped⇒wrapped, three further installs leave `set`/`get` the SAME function objects (no double-wrap), a reconstructed world's fresh cache starts unwrapped and gets wrapped, and the wrap still records a poisoned key during a cold window.
