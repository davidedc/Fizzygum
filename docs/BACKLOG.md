# BACKLOG.md — every open item, with its owning doc

Index only: the executable detail lives in the linked plan section. **OPEN items only** — an
item leaves this file when it closes, and lands in the `## BACKLOG ledger` section of the plan
that closed it (README rule 2). A subsection's owning plan lives in `plans/` while the arc is
active and in `archive/` once it closes; either way the open items it left behind stay here.
Closed items whose arc never had a plan file are collected in
`archive/backlog-closed-items-ledger.md`. Keep it current per README rules 2 and 5; a `- [x]` line
here fails `check-doc-narration` (`BACKLOG_CLOSED_ITEM`, the gauntlet's `refs` leg).

## Open items by owning arc

### `archive/argument-holes-both-repos-plan.md` — the hole test over both repos: a code parser, the callers test, the button family's head in opts (CLOSED 2026-11-07; Units 0, A–E done, see its ledger)
- [ ] **`heap-forensics.js` waits for its page to boot its own way** (found by the same review; by reading). A
      120 s loop of raw `page.evaluate` looks (`window.world && WorldWdgt.frameCount > 5`, no `answerWithin`), ending
      in a bare `Error('harness did not boot')`; it runs in the `selftests` leg through its proof.
- [ ] **The rigs wait for their pages to boot a dozen ways, most of them in-page and unbounded** (found closing "The
      suite's probe page waits for boot its own way", in the plan's ledger; by reading). A rig that boots a product
      page waits for its world its own way: `scripts/lib/headless-boot.js` `inPageWaitReady` (one raw in-page poll,
      given 60–120 s, bounded by `answerWithin` only in `smoke-apps-headless.js`; the graph and serialization rigs
      wait on it raw, and the menu and pin sweeps also discard its answer, so a world that never arrives meets their
      sweep as a raw TypeError), and local copies in `smoke-boot-headless.js` (`inPageWaitFor`),
      `parts-lazy-icons-headless.js` (its own `inPageWaitReady`), `parts-lazy-load-headless.js`,
      `parts-snapshot-load-headless.js`, `serialization-file-roundtrip-headless.js`,
      `staleness-census.js`, `derive-inspector-churn-set.js` and `generate-pre-compiled-headless.js`, each with its own
      predicate, bound and line. A page stuck while it boots is waited on until the protocol timeout. The runners'
      pages share `startedWithin` (`lib/headless-driver.js`); a rig's page asks a different question (a product world,
      no harness), so the rigs' one wait is `startedWithin` with a predicate of their own beside `HARNESS_WORLD_STANDS`.
- [ ] **The boot files are a hand-list in the build script** (found closing "Every build tool walks src for itself",
      in the plan's ledger). `build_it_please.sh` cats and compiles the 14 `src/boot` files by name, and
      `check-shippable-coverage.js` exempts `src/boot/` whole, so a new boot file ships nothing and no gate notices.
      Boot's order as data, one list the build and the gates read, is its own design.
- [ ] **Every gate re-masks all of the compiled sources** (found closing the same item; measured). Masking src takes
      about 650 ms (`lib/coffee-mask.js`), and 20 build gates each mask all of it in their own process: about 13 s a
      build, most of the +15.2 s the comment-masker item accepted. A mask cache keyed by file content could win it back.
- [ ] **`find_similar_code.sh` stops at its mirror** (found closing the same item; measured).
      `buildSystem/coffee-to-js-mirror.js` fails on `src/meta/Class.coffee` under CoffeeScript 1 ("unexpected ."),
      exits 1, and the script stops at "mirror compile FAILED". Class.coffee last changed in 7891f3a8, 2243cab7 and
      57959d14 (2026-11-08).
- [ ] **Build freshness reads only the sources' mtimes** (found closing the same item; by reading). An edit to
      `parts.json`, `buildSystem/*`, `src/index.html` or the runtime prelude leaves a stale build reading FRESH, to
      `lib/assert-build-fresh.js` (and every runner that asks it) and to the umbrella `fg status`.
- [ ] **Every tool walks the tooling's own files for itself** (found closing the same item; by reading). About seven
      walks list the `.js` files of `buildSystem/` and `scripts/`, with different skip rules: `lib/what-runs.js`,
      `run-selftests.js` and `check-hand-lists.js` pass over dot directories, `node_modules` and `__pycache__`;
      `lib/tests-repo-code.js`'s scripts walk, dot directories and `node_modules`; `lib/cli-selftest.js`, `node_modules`
      in one walk and dot directories too in another; `find_similar_code.sh`, `node_modules` and `.scratch`. Latent
      today (`scripts/` holds no dot directory). It is the compiled sources' defect on another tree, where
      `node_modules` is real, so it wants a definition of its own.
- [ ] **The wall-clock stink does not see `new Date` without parentheses** (found closing the same item; by reading).
      Its pattern is `new Date\s*\(`, so a paren-less read of the clock is not counted: `WorldWdgt`'s cycle-start
      `new Date`, `AnalogClockWdgt`'s constructor, the harness's command pacing (`(new Date).getTime()` in
      `AutomatorPlayer.replayTestCommands`) and `EventCommand`'s `@date = new Date`.
- [ ] **A widget file runs the code it carries at load, with no confirm** (found closing "The widget-file door never
      loads the lazy part a file needs", in the plan's ledger; measured). A `{"$src"}` is restored with
      `injectProperty`, which evaluates `@<name> = <text>`, and nothing requires the text to be a bare function
      literal: a file whose method source is `(window.x = 1; -> 42)` set `window.x` on load, through the drop and
      "Open from file…". The world door asks first ("…can run code the snapshot carries"); the widget door asks
      nothing. Whether a widget file carrying a `{"$src"}` should confirm, or a `{"$src"}` be held to a function
      literal, is a product call.
- [ ] **A save refused for a function a run left does not offer its way out** (found closing "A run that sets a
      widget field to a function blocks every world snapshot", in the plan's ledger; OWNER DECISION). The refusal names
      the widget, the field and the gestures that clear it (an inspector's Remove, or its Save as
      CoffeeScript), and every later save is refused until the person takes one. Whether the refusal should also
      OFFER that way out (a button that removes the field, or opens an inspector on the widget), whether a save
      should instead LEAVE such a function out and say so (a told drop, against the serializer's "never a silent
      drop" unless a told drop is ruled not silent), or whether a run should WARN when it leaves one, is a UX call.
- [ ] **An object inspector hides a widget's own field that shadows a member it inherits** (found by the independent
      review closing "A run that sets a widget field to a function blocks every world snapshot", in the plan's ledger;
      by reading). With "inherited" off (the default), `InspectorWdgt._filteredMemberNames` keeps a member only if the
      subject's own class's prototype defines it or no prototype up the chain does, so a run's `@step = -> …` (an own
      field named like `Widget.step`) is not listed; with "inherited" on, selecting it shows the CLASS's recorded
      source, not the widget's own function (`selectionFromList` walks the class chain before the value's own text).
      What "inherited" should hide for an own field that shadows a declaration is a question for the inspector's
      design: every widget's own state fields (`color`, `bounds`, …) shadow a prototype declaration the same way.
- [ ] **A save writes NaN and ±Infinity as null** (found by the same review; by reading). `Serializer`'s `refFor`
      answers a number as itself, and `JSON.stringify` writes `NaN`, `Infinity` and `-Infinity` as `null`, so a field
      holding one restores as `null`, with no word: the silent drop the serializer otherwise refuses.
- [ ] **A snapshot's source edits of a lazy part's classes are dropped when the file holds none of its widgets**
      (found by the independent review closing "A class a lazy part defines after a mixin edit takes the mixin's boot
      member", in the plan's ledger; by reading, not measured). `Deserializer.classNamesIn` reads the object records
      and the well-known keys, never `world.sourceEdits`, so `loadWhatItNeeds` does not load the part a class- or
      mixin-scope record names; `replayClassEdits` / `replayMixinEdits` then pass over a class or mixin the page does
      not have without a word, while the file's registry is installed whole: a re-save carries the record the page
      never ran. On the dev `index.html`: edit `ParentStainerMixin._updateColor` (app-kit) or a `CreatorButtonWdgt`
      member, close every app-kit widget, save, and load the file in a fresh page.
- [ ] **A runtime object stamped derived is dropped from an inspector holding it** (found by the independent review
      closing "A value answering `rebuildDerivedValue` is dropped from a save, and breaks a copy, wherever it
      stands", in the plan's ledger; by reading, not measured). A value a class stamps with a no-op
      `rebuildDerivedValue` (`FridgeMagnets3DCanvasWdgt._markTransient`: its `transforms`, `meshCache`,
      `lclCodeCompiler`, `surface`, `depth`, `engine`, `imageData`) is derived wherever it stands
      (`NativeValueKinds.isDerivedAt`), so an inspector opened on one (a 3D pane's member row, double-clicked) loses
      its subject on a Duplicate (the copy's first re-lay throws in `_subjectIsEditable`) and on a world save (the
      restored inspector throws at every re-lay) — what a canvas context did before it became derived only beside its
      canvas. Such a value is derived where its holder rebuilds it: the class that stamps it (its
      `@serializationTransients` names the same fields), not an inspector.
- [ ] **A load judges an app key's kind by the page's edited members, then returns them to boot** (found by the
      independent review closing "An `app:` key naming a class that is no app is `new`-ed during a restore", in the
      plan's ledger; by reading; low, contrived). `WellKnownObjects.isAppClass` reads a class's LIVE `wellKnownKey`, and
      the world door asks it before its teardown, while the load returns the page's class edits to boot
      (`SourceEditsRegistry.returnThePageToBootSources`) after it: a page that added or edited a class's
      `wellKnownKey` passes the up-front judgement, and the restore's own `resolveApp` then throws after the teardown.
      The up-front predicate is otherwise a pure read of the file; this one depends on page state the load is about
      to change.
- [ ] **A text's measurement, wrapping and split caches name no code of its own** (found by the independent review
      closing "A palette's back-buffer key names its class and extent, not code of its own", in the plan's ledger; by
      reading, not measured). `Widget._ownCodeKeySuffix` keys a text's back buffer and its two top-level text caches
      (TextWdgt's wrap and line breaks), but four shared caches its code also fills do not carry it:
      `cacheForParagraphsWrappingData` (`TextWdgt.coffee`, filled through `@measureText`), `cacheForTextMeasurements`
      (`StringWdgt.coffee`), and the paragraph and word split caches. Twin texts of one font, width and paragraph: an
      inspector Save of A's own `measureText` misses at A's top-level key and then hits the paragraph entry B filled,
      so A's edit never shows; after a flush, whichever wraps first fills the entry for both.
- [ ] **`fg recapture-inspector` recaptures a churn-set test's behaviour shots blindly** (found by the independent
      review closing "The inspector churn set cannot see a class inspector's member list move", in the plan's ledger;
      by reading; low). The churn set and its readers act per TEST, not per shot: a test in the set is recaptured whole,
      so a shot that proves BEHAVIOUR rather than renders a member list (the hover colours in
      `MixinEditDonorAndOverride` / `MixinFieldEditDonorAndOverride` images 3 and 5) is re-recorded with the member
      list's churn, whatever it now shows. The set gained those two tests; the hazard is older and wider.
- [ ] **A scrolled pane keeps its height when its content shrinks in the same settle** (found closing "A class edit
      refreshes only what a repaint shows", in the plan's ledger; measured). In that item's world census, an edit of
      `MenuItemWdgt.preferredExtentForWidth` refreshed every widget in one settle (`WorldWdgt.noteCodeChanged`): the
      class inspector's member rows shrank, and their `ScrolledPaneWdgt` stayed 9164 px tall where a second refresh
      makes it 7420, after which it is stable. At rest no pixel differs, but the scroll range is wrong until then. A
      settled world that a second re-lay still moves is a question for the engine.

### `archive/every-gate-bites-plan.md` — every gate's every rule bites, and the build refuses a gate without a proof (CLOSED 2026-11-07; Units 0, A–F done, see its ledger)
- [ ] **The masks Unit 0 found that are heuristic by design (plan §8.3, "File").** Each is a reading the gate makes
      on purpose, filed with what it misses:
  - [ ] `check-raw-pointer-reads`: a column-0 line inside a handler ends its body, and any `screenPointToMyPlane` on
        a line excuses every raw read on it.
  - [ ] `vm-truth-gate.js` skips its heap-floor ceiling below 20 samples per page, so a short (`--tests=`) run never
        judges it; its proof plants `HEAP_FLOOR` on a fabricated `--audit-dir=` instead.

### `archive/tests-repo-readers-plan.md` — one definition of a method reference, read from code (CLOSED 2026-11-06; Units 0, A, B, C, E done, see its ledger)
- [ ] **`census-property-placement`'s exclusion 1 counts every WORD inside any string** (`STRING_WORDS`, 3429)
      as a possible by-name access. By the method-reference rule (`buildSystem/lib/method-references.js`) only a
      whole-name string can reach a member. Advisory census; its tests-repo reading is already right.

### `archive/hand-kept-lists-plan.md` — hand-kept lists: derive them, or make them fail when stale (2026-11-05; CLOSED 2026-11-06, all four tiers landed)
- [ ] **Tier 4's residue (plan §6 ledger):**
  - [ ] **The four LiveCodeLang vocabulary lists are the hand-list gate's whole Fizzygum baseline (4)**
        (`LCLCodePreprocessor`'s `qualifyingCommands` / `primitives` / `commandsExcludingScaleRotateMove` /
        `colorCommands`): they mirror the commands `FridgeMagnets3DCanvasWdgt` implements, and only six of the 29 are
        exercised by a test. Their guard is `plans/livecodelang-cleanup-and-extensions-plan.md`'s R1 (the
        headless preprocessor gate reading the canvas's methods); then sanction them and drop the baseline to 0.

### `archive/world-inventory-instruments-plan.md` — the object-lifetime program, stated in that plan's §0 (Arcs A, B and C CLOSED 2026-08-20/21)
- [ ] **OWNER DECISION (2026-08-21, from the async-rejection sweep): a failed async door tells the user NOTHING.** Every product promise chain was swept for missing `.catch` (13 `.then` in `boot/globalFunctions.coffee`, 10 in `PartsRegistry.coffee`, 3 each in `WorldWdgt.coffee` and `boot/loading-and-compiling-coffeescript-sources.coffee`, 2 in `Widget.coffee`, 1 each in `FileLoading`/`DemoMenus`/`VideoPlayerWithRecommendationsWdgt`/`SWCanvasElement-extensions`). ⭐ **The sweep's finding is that these are NOT N defects** — the subsystem has thought about rejection and handles the parts that matter: `PartsRegistry` neutralises unhandled rejections centrally (`inFlight.catch -> undefined`), `canEverProvideClass` keeps an icon off screen when its part can never arrive (the `lean` dead-icon rule), `whenOptionalPartsLoaded` exists precisely so a door cannot become "a click that can only reject", and `loadWorldSnapshot` bails out BEFORE mutating so a failed load "leaves the user with nothing instead of the desktop they still have". What is uniformly absent is USER FEEDBACK: on a TRANSIENT failure of a part the build does ship (a bad read over `file://`, a corrupt part file), the click silently does nothing — consistently, everywhere, which is what suggests it is a decision rather than an oversight. The question is whether a failed door should `inform`, and it is a product call. ⚠ Note this is a DIFFERENT shape from the `saveFailedScreenshots` bug fixed the same day: that one was PARTIAL failure discarding work that had already succeeded, which is a bug on any reading; these are all-or-nothing by design. The two FILE doors are settled: a drop or "Open from file…" reports a load's asynchronous failure as it reports a synchronous one (`FileLoading._reportingSerializationErrors`, argument-holes ledger, "The widget-file door never loads the lazy part a file needs"). The question stands for every other async door.
- [ ] StorageSorter-roots unification (plan D2's stated non-goal): `StorageSorter._runClassifier`'s
      phases build their own root/marking enumeration — examine folding it onto
      `WorldWdgt.graphLivenessRoots()` in a dedicated pass, NOT by side-effect of another arc.

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

### `archive/frames-input-touch-program.md` — the frames·input·touch PROGRAM (CLOSED 2026-08-27; all five plans executed and archived)
One chrome container (`FrameWdgt`) with a runtime `lifetime` state and manifestations derived from lifetime × parentage; Pointer Events; the single-geometry visual wave; the command-panel/`User` model; the gesture grammar + finger harness (the `finger` gauntlet leg, wave D). The living truth is in the architecture corpus (`input-and-gestures.md`, `viewports-and-planes.md`, `widget-authoring-guidelines.md`, the macros CLAUDE docs, the tests-repo reference grammar); rulings and the drained tail ledger are in the archived program doc. Residue rows, each with its origin:
- [ ] **icons on ordinary menus** (world menu, context menus): owner taste, not built; land only when a
      consumer asks. The mechanism already exists — `CommandSpec.icon` — so a consumer costs one call
      site, not a new axis. Origin: `archive/command-panel-unification-plan.md` §2.2.
- [ ] **remainder-menu alternative projections**: the chevron's overflow menu ships icon+label rows;
      a grid pop ("a vertical toolbar") or a label-only pop are available BY DERIVATION on the same
      `CommandSpec` rows, one line each — land when a consumer asks. Origin:
      `archive/command-panel-unification-plan.md` §2.2/OD2.
- [ ] **T4 — multi-pointer**: pinch derived from two `pointerId`s, retiring the Safari `gesturestart`/`gesturechange` no-op listeners kept beside the pointer listeners until then (ruling I1). Origin: program tail T4, filed at the Plan 4 close.
- [ ] **T5 — desktop-edge docking**: the world's edges as dock slots, a taskbar strip. `EdgeDockLayoutSpec` is world-CAPABLE (names no host type) but the world grows no slots — a desktop dock needs a dock loop in the world's arrange, a fill gesture, and a stated precedence against the `StretchLayoutSpec`s the world already consumes, all unruled. Origin: program tail T5.
- [ ] **T18 — halo crowding at touch scale, PAIRED with the owner-pending G2 halo feel-check (one conversation)**: at `handleSize 44` the five corner-internal handles fully overlap on any widget below ~2·handleSize (~92 px); the Plan 3 z-order interim (corner resizer frontmost) stands, handles are hold-exempt chrome under the grammar, and the open DESIGN question (fewer handles below a size floor? edge zones? a halo mode?) is the same conversation as how the halo should FEEL at 44 px. Origin: program tail T18, owner-ruled OD4(a) at the Plan 4 review.
- [ ] **multi-user input attribution**: strokes carry `pointerId` and the `User` model exists (`world.users`); a User-per-pointer mapping is designed when a second input DEVICE exists. Origin: the Plan 3.5 `User` model's "Plan 4 at the earliest" marker, discharged at the Plan 4 close.
- [ ] **finger scrolling for the spreadsheet**: the sheet takes no drag-scroll (wheel/scrollbar only), which is exactly why its three wheel tests are declared mouse-only on the finger axis; a finger-scrollable sheet is a product FEATURE (the grammar re-gates existing scroll surfaces, it adds none). Origin: Plan 4 P3 discovery classification.
- [ ] **inspector row-locator: scroll-further beyond 3 nudges**: `clickOnListItemFromTopInspector` aims inside the row∩pane slice and the L3 locator nudges up to 3× toward an off-window row; a row still unreachable after that throws a named error (the honest floor — it has never fired in a green run). If a legitimately deeper list ever trips it, extend the nudge loop rather than the aim. Origin: `archive/widget-input-vocabulary-plan.md` P3.

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
Phases 0-8 plus F1/F2/F4/F5/F6 all LANDED; remaining = F3 (the 'operate' cell submenu); the deferred `firesPerEvent` delivery lane is owned by `plans/wire-vocabulary-extensions-plan.md` W1.
- [ ] F3: the 'operate' cell submenu (a row built with `opensSubmenu: true`, never a typed arrow) — value-class method introspection into a formula

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
tables it surveys). Not the wire *vocabulary* (that is the plan above). What stayed open is
five follow-ons that each want their own decision or arc, and the two re-homed/refused items
(its one by-catch defect, the `getPixelColor` alpha units, is CLOSED — see that plan's ledger):
- [ ] **THE SHADOW PASS HAS THREE COVERAGE STRATEGIES AND THEY DISAGREE** (found while landing the pop-up-overflow arc; owner-raised). `Widget.coffee` states the contract at the shadow entry point — *"a shadow is the caster's per-pixel COVERAGE"* — and coverage is an OPACITY, so two coincident opaque widgets have coverage 1, not 1.36. Three implementations exist: **(1) recursive re-paint** (the general path) draws every descendant as shadow, so overlapping opaque children STACK — 0.2 over 0.2 composites to 0.36, which is a visible doubly-dark core in the band under every menu and prompt; **(2) the opaque-panel short-circuit** (`ClippingAtRectangularBoundsMixin`, `if @alpha != 1` — a fully opaque clipping panel draws ONE rectangle and skips its children); **(3) the silhouette blit** (`HTMLCanvasElement.blackSilhouetteOf`, used by `BackBufferMixin` and the transform islands). ⭐ **The "optimisation" (2) and the buffer path (3) are the only ones that honour the contract; the general path (1) is the broken one** — so the shadow a subtree casts today depends on whether an ancestor happens to be an opaque clipping panel, which is not a property anyone reasons about. ⇒ unify on the silhouette. ⚠ Own arc: it changes EVERY shadow in the system (removing every doubled band), so it needs its own before/after evidence and a deliberate mass recapture, not a side effect of something else.
- [ ] **Menu LENGTH is now a pure UX question, and worth its own arc.** Widget context menus run 19–42 rows (measured 2026-08-17 at the harness world: `TextWdgt` 40, `StringWdgt` 36, `SimpleTextWdgt`/`TitleWdgt` 33, `SliderWdgt` 26, `RectangleWdgt` 19). Nobody scans 40 rows. Grouping related rows behind submenus — what §P2 did locally for `connect`/`bind ⇄` — would shorten every menu. Deliberately NOT bundled with the overflow fix (owner call): the fix establishes the invariant so no row count can break reachability again, which is what makes the length question a taste question rather than a correctness one.
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

### `archive/redesign/redesign-plan.md` — the visual redesign (COMPLETE 2026-10-22; its open follow-ups stay here)
One design system (a `Theme` token layer, seam rules, drawn chrome icons, size-aware icons) reaching the draft (`archive/redesign/`, beside the plan) surface by surface, with the suite made aim-by-meaning first. The look as built is `architecture/visual-design-system.md`; the owner decisions are in the plan's §0.5. The items below are the arc's open follow-ups; "the plan" in them is the archived plan.
- [ ] T follow-up — a hidden or collapsed title piece keeps a STALE box: a pinned menu's `label` is a hidden StringWdgt at (0,0), and a collapsed window title keeps the centre it had (three never-delivered tests aimed there, plan §4 T Findings). Harmless to the product (nothing paints or hits it); decide at W1/W2, which rebuild the strip, whether a not-shown piece should answer geometry at all.
- [ ] W3 follow-up — the owner-review points W3 left open, listed in the plan's §4 W3 "Open review points": an instance's own property dimmed like an inherited one; the code pane's line pitch 15 (no line-height knob; W5's documents need one too); the toggle and chip hover/press looks; the prompt buttons' placement; wrapped breadcrumb rows' indent; a taken-apart pane's transparent look; a disabled button's shadow on the desktop; `injectProperty` removed from the chain leaving the footer; the error log's two-label pause toggle.
- [ ] W2 follow-up — the owner-review points W2 left open, listed in the plan's §4 W2 "Open review points": the fat scroll indicator's look; tooltip placement over the menu it explains; the 20 px tick column; narrow pinned menus hiding their title (since 2026-10-25 every pinned menu takes its rows' width at the pin — a title wider than the rows hid in the strip already, and now the extra width goes too, `visual-design-system.md` §5 "A pop-up"). (The prompt slider's thumb that returned to black after one hover is fixed in G-C1: the prompt slider wears the content slider's look, read at paint.)
- [ ] W1 follow-up — the owner-review points W1 left open, listed in the plan's §4 W1 "Open review points": collapsed-strip corners; the crescent inside a window's bottom corners; card corners under a host's strip; pinned-menu rows under the border (W2); what the grip's square covers; whether the grip should compensate the drag-threshold lag; the "grip" name clash with ruling C12.
- [ ] G-E follow-up — a ROW's look is chosen once, in `MenuItemWdgt._lookFor` (and `MemberRowWdgt`'s), and COPIED into the row, its label and its indicators at construction (~16 own fields: fills, plate geometry, insets, fonts, inks), so a saved or duplicated row keeps the look of the day it was built; every other G surface reads its role where it is painted. Moving the menu, list and member rows to a read at paint (a row-kind record and every reader asking the theme through it: `LabelButtonAppearance`, the rows' layout, the label's ink, the indicators) is pixel-neutral but rewires every row the suite shows (167 shots of 63 tests). Census: `Fizzygum-tests/.scratch/g/RE-report.md` §2.4. (plan `archive/redesign/redesign-plan.md` §4 G)
- [ ] G-E follow-up — the demo pointer (`dev-tools/PointerWdgt`, "Make pointer") keeps its own chrome: a 160-grey box and a white label, outside the redesign's palette, and its close button now wears the off-strip icon button's `muted` glyph on that grey (low contrast). Give it the plate look or a role of its own. (plan `archive/redesign/redesign-plan.md` §4 G)
- [ ] G-D follow-up — a finger does not hover, and two tests about the hover WASH replay under a finger without ever showing it: `macroHierarchyMenuHoverHighlightsExactSubtree` (its whole subject is the wash; its finger references hold no wash pixel) is not declared mouse-only, and `macroTargetingHighlightsCandidateWidget`'s highlight shots show none under a finger (its menu flows do run). Declare the first `pointerKinds: ["mouse"]` with its reason (and drop its finger references), and decide whether the second's finger run should assert what a finger CAN show. The same holds for the two live mixin-editing tests (`macroMixinFieldEditDonorAndOverride`, `macroMixinEditDonorAndOverride`): they prove each edit by HOVERING a plain button (red, then blue), and their finger references show it at rest in both shots (found at G-E1) — their editing flows run under a finger, so the decision is whether to prove the edit there by another reading (the button's `color_hover`, asserted) or to declare the hover shots mouse-only.
- [ ] G-C follow-up — UNEXPLAINED: the `menusweep` leg hung silently in parallel wave A twice (the G-C close gauntlet 2026-10-21 and the Z close 2026-10-22: the leg's 300 s alarm, rc 142, no output), passing its serial retry each time; 8 instrumented sweeps beside a full parallel suite did not reproduce it. The sweep stamps its stages and every root on stderr as it reaches them (2026-10-29), so the next sighting's log tail names the root it stopped in — read it then.
- [ ] R0 follow-up — a MASS recapture is dominated by its discovery pass: `recapture.js --auto` re-verifies EVERY parallel suite failure single-process, at each density, before capturing. W1 measured about 45 min of discovery for the mouse wave (297 tests × 2 dprs) and about 55 for the finger wave, of 1 h 49 min and 2 h 00 min in all; the recompress pass took about 33 min each. When the parallel failures are all pixel mismatches, a parallel re-verify (or none) would save most of it.
- [ ] F follow-up — the S2 symbols W6 left (W6 kept the wire rows' ➜ / ⇄, "Bind ⇄" and the text menu's pictograms as wording and appended them, with ↔ and °, to the symbols atlas, plan §4 W6): (the Templates "useful characters" palette was TRIMMED at G-E to characters the atlases carry, owner, and its quote to straight quotes and an em dash) the font sets lack ¹ ² “ ” ‘ ― (and Arial's own °, drawn from the symbols atlas meanwhile, a little wide); `StringWdgt.toString`'s newline mark "↵" boxes in dev displays. A font-set addition regenerates every font atlas (~4,200; plan §4 W6, R4).
- [ ] W5 follow-up — a document paragraph being DRAGGED is plain in the hand (square, text flush, re-wrapped at its full width), because the item shape is asked of the text's container and the hand is not a page; it takes the shape again where it lands. Keeping the item look in flight needs the hand to know where the drag came from.
- [ ] W5 follow-up — the document's drop rule (a dropped widget goes before the first item whose middle is below the drop point) cannot append after an item whose middle lies below the visible page without scrolling the page while dragging; seven tests were re-aimed around it. An auto-scroll at the page's edges while carrying (the list's `macroListWdgtAutoScrollsNearDraggedEdge` precedent) would close it.
- [ ] W5 follow-up — with the caret 1 px after its slot's boundary and 2 px wide (owner decision), a click ON the drawn caret in front of a glyph narrower than 5 px (Arial 13 `t`, `i`, `l`, `.`) picks the next slot; a caret at the end of a tight label paints 1–3 px outside the label's box.
- [ ] W5 follow-up — a caret at the right edge of a scrolling viewport with no padding (a loose string in a scroll panel) has its last column under the viewport's 1 px border: `ViewportWdgt.scrollCaretIntoView` follows with a margin of `padding + extraPadding` (0 there), and the caret's band clamp stands aside inside a viewport plane (W5b: two clamps disagreed and cost a settle re-visit). Making the caret fully visible there needs the follow's margin to include the border.
- [ ] W5 follow-up — `Theme.titleBarTextHeight` (the window title's stand-in before its label exists) could go: its two readers answer only before the title piece exists, and the pop-up band is floored at `menuRowHeight` anyway; removing it needs a class-side "line pitch of a role" query `StringWdgt.linePitch` would share.
- [ ] W5 follow-ups (W5e, pre-existing, found on the tool cells) — the press lifecycle (2026-10-24: every widget the press's `pressBegan` reached is told its ending, `input-and-gestures.md`) closed the stuck PRESSED looks this line used to list (the edit mark's tool cell, the frame-strip icon buttons whose empty face caught the release). Still open: a copied or loaded toolbar keeps its items' saved pointer state; and a view/edit switch (`_engageDocksNoSettle`) does not tell a docked band's corner chain (no observed case).
- [ ] W6 follow-up — a text that sizes its box to its contents measures its STORED text, not what it shows (`TextWdgt.preferredExtentForWidth` / `_reLayoutSelf` read `@text`, not `transformTextOneToOne @text`), so a display case or a password on such a text would size the box to the wrong form. No title uses that mode today (W6a).
- [ ] W6 follow-up (BitmapText) — the shipped font-assets release carries 124 dpr-2 bold/italic font atlases at 73–84.5 px (Arial 49, Courier New 32, Times New Roman 43) whose single-row image sits under two-row positioning data, so glyphs past the wrap draw blank (a recovery regenerated their bundles and kept the old images). A font-set regeneration rewrites them (R4, `Fizzygum-tests/.scratch/w6/R4-report.md` §3).
- [ ] W6 follow-up (owner review points) — 11 px capitals in a menu header show uneven letter gaps at dpr 1; "Empty window" (sentence case, 2 px wider) drops below the title crop grade in a 72 px title box, so two shots show no title; the symbols atlas's glyphs are small, sit high and are never bold (⍿ is a dot at 13 px dpr 1); a rotated widget's hierarchy reads "Rectangle" / "Rectangle 2" (the transform island names itself after its content); the test fixtures' own labels stay lowercase ("hover me", "hide the box", "beta"…).
- [ ] W6 follow-up — wording leftovers: a pinned menu's or prompt's `colloquialName` is a quoted form that lands in a saved file's name ('"Desktop" window.fzw.json'); the dev menu spells "Serialise widget to memory" beside "Deserialize…".
- [ ] W6 follow-up (design note) — a menu ROW that opened a confirmation would need both the submenu chevron and "…", which the two rules forbid together; no row does today (the bin's confirmation comes from a button). Decide before one is added (the menu-click sweep's flag proof and "…" proof would disagree).
- [ ] F follow-up — S3 ladder anomalies for W4's icon work: Bin draws lopsided ridges at even S 18–32 (pre-existing: its ridge drop rule measures the left ridge by its left edge and the right by its right edge); GenericPanel (halo erases the border) and Typewriter (no keys) degenerate at 14.
- [ ] G-A follow-up — the C-F converter's DEMO variant (`CFDegreesConverterIconAppearance`, demos-icons) paints its parent's art: its grey F degree sign went with the redraw, because the size-aware base has no secondary-ink helper (a raw fill style breaks the shadow pass). Add a `_useDetail`-style role helper if a second ink is ever wanted.
- [ ] G-A follow-up — a Fizzytiles magnet's label is a `StringWdgt` that keeps its own font and ink, so a magnet loaded from a snapshot keeps the label look it was saved with (the magnet's box and border are read at paint).
- [ ] G-B follow-up (owner G2, still open) — on a widget smaller than ~92 px on a side the halo's five 44 px plates overlap (the corner plate on top); accepted at G-B, decided with the halo feel-check.

### `archive/window-page-gutter-plan.md` — one gutter around a window's page, its bands and its selection ring (✅ CLOSED 2026-10-23: Fizzygum 6e4946cd, Fizzygum-tests cc9aa0e1e, pushed)
A window's PAGE keeps one 8 px gutter on every side and between it and its bands; PANES stay flush; a document's inset yields to the gutter; a page's selection ring lies in the gutter, painted by the window; gutter and letterbox-margin drops go to the page; a Stretchable page in a gutter is a four-edged sheet; a document's caret scroll margin is its own. Rule: `architecture/visual-design-system.md` §4.10.
- [ ] Observation — a world snapshot restores bounds as saved and re-lays nothing, so a window saved under another theme shows its old geometry until something re-lays it (measured by the U1/U2 probes: a Docs Maker saved at gutter 0 loads flush until re-laid).
- [ ] Naming follow-up — `StretchablePanelWdgt._insetEdgeRects` now also answers all four edges in a gutter, and `ActivePointerWdgt._targetReachedThroughAGutter` / `_moveGutterDropInsideTarget` / `releasedInAGutter` also cover a letterboxed page's margin: names narrower than what they do. `Widget._clampedPositionWithin`'s comment says `aWdgt` where `_moveGutterDropInsideTarget` passes a `Rectangle` (same four accessors).

### `archive/spreadsheet-ux-plan.md` — the spreadsheet as a page, with a formula bar, zoom, its own toolbar and the Sheets Maker (✅ COMPLETE 2026-11-04)
Owner rulings R1–R13 (the plan's §1); what the arc left out on purpose:
- [ ] Per-row heights: text bigger than its row is clipped (rows are one height). Plan §1 "Not in this arc".
- [ ] A view (non-edit) mode for the spreadsheet: every other Maker has the edit/view toggle. Plan §1.
- [ ] Ranges: a multi-cell selection (the style subject would hand over a range's style), SUM over a range. Plan §1.
- [ ] Insert / delete a row or column (every formula's references rewritten), and fill down. Plan §1.
- [ ] Pinch-to-zoom as a world-wide gesture any zoomable widget answers (the sheet's zoom is a menu today). Plan §1.
- [ ] Observation — a number wider than its column shows ellipsised ("12345…"), since numbers never spill (R12): a reader can take the shown digits for the value. Mainstream spreadsheets show `###` or switch to scientific notation; which one fits here is the owner's call. The formula bar shows the cell's source, so a computed value is shown nowhere in full.

### `archive/collapsed-bar-grip.md` — a collapsed window keeps its grip, and its bar can have a width of its own (✅ COMPLETE 2026-11-01)
- [ ] Observation, pre-existing — a band collapsed in its dock and then lifted out gains its edit toggle while still collapsed (`FrameWdgt._reDeriveBarRosterNoSettle` re-creates it, where a collapse in place destroys it), so its bar wears a toggle other collapsed bars do not, and shows no grip at any width because the toggle holds that corner. Harmless: expanding it puts everything right.

### `archive/window-grip-strip.md` — every window's grip in a strip of its own (✅ COMPLETE 2026-10-31; what it dissolved is in that record)
- [ ] Owner's call, stands at "one rule" until told otherwise — a floating toolbar is a window, so it wears the strip: a floating row goes from 103 to 145 px tall and gains 31 px of run. The alternative, a floating toolbar without a strip, needs back the keep-clear code this arc retired (`_farAlongPadding`, `cornerResizerFootprint`, the frame's corner chain) and a second grip look. Comparison pictures were shown to the owner in the arc.
- [ ] Observation — a plain panel already holding a window, added by code to the content of a window in view mode, leaves that inner window's grip showing until the outer window next changes mode: a mount re-asks the window being mounted and a mode change walks down to every window in the content (`FrameWdgt._noteMyModeToWindowsInMe`), but here only the panel is added, so no window is told. No gesture reaches this, since a window in view mode refuses drops.
- [ ] Observation — the Examples folder's "New York City" slide in EDIT mode: the map window's viewport is 42 px shorter, so the nested "NYC: traffic" plot is mostly cut off. It opens in view mode, which is unaffected.

### `archive/focus-and-selection-plan.md` — the focused window and the selected desktop icon (✅ CLOSED 2026-10-23: every unit landed as one commit pair; closed items in the plan's ledger. Its four residue items were closed by the focus-residue arc the same day — ledger in the plan; the items below are what that arc found)
The FOCUS arc the redesign deferred (its plan §0.5.2): focus derived once per cycle from z-order, the draft's focused-window look through `FrameWdgt._frameLook()`, and the selected icon as the existing editor focus drawn the icon's own way. Owner decisions D1–D11 LOCKED 2026-10-23, every recommendation (plan §2); D11, added from the owner seeing a dropped Docs Maker window ringed: a top-level window is focused, never selected (unit S0).

### `plans/occlusion-culling-plan.md`
P0-P3 (Avenue A) LANDED 2026-07-09; P4/P5/P5b/P5c OWNER-GATED, not started.
- [ ] P4: Avenue B maintained covered-rect list, replacing per-rect traversal — not started
- [ ] P5: descend to nested opaque panels/window bodies — optional, not started
- [ ] P5b: hand-carried drag coverer (hand paints last, uncounted today) — not started
- [ ] P5c: fringe decomposition of the dragged window's own rects — not started

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

### `plans/mixin-removal-plan.md`
AUTHORED 2026-11-10 on the owner's direction: all eight mixins to ordinary homes, then the mechanism deleted. No code written. D2 (Controller = a base class) and D5 (the talk plan drops mixins) are decided; the three investigations have paper verdicts (its §13). It supersedes the keep position of `architecture/mixins.md` §1/§7.
- [ ] §6 S1: the back buffer — empirical half (a build and a gauntlet on the paper verdict); open: where the fields are declared, the shadow twin's home, whether text keeps the shadowing `calculateKeyValues`
- [ ] §6 S2: one pointer-state mechanism — empirical half, after D1
- [ ] §6 S3: the edit-mode relay into `StretchablePanelWdgt` — empirical half
- [ ] §0.4: owner decisions D1 (pointer-state shape, three candidates), D3 (class names), D4 (the inspector's donor vocabulary)
- [ ] §7 Phases 1–9: the base-class moves (Clipping, KeepsRatio, Controller, the app-kit shared base) wait on nothing; then the back buffer, the edit-mode relay, pointer state, the mechanism teardown, docs

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
- [ ] §4.2: minimise-to-a-bar, distinct from collapse-in-place (second wave)
- [ ] §4.4 follow-up: what does save-to-file mean for an ARROW'D shortcut (today: friendly error — no cross-file identity for a dangling-`.lnk` restore; needs its own decision)

## Residual / parked items (owning doc archived)

### Pointer hit-test rework 2026-08-21 — residue (no plan doc; the arc ran assessment → execution)
`isTransparentAt` + the `noticesTransparentClick` flag retired for three single-meaning members —
`Appearance.shapeContainsPoint` (outline) / `Widget.catchesPointerAt` (does my surface stop the
pointer) / `Widget.isPointerTargetAt` (the whole question) — and `opaqueCoveredRect`'s exact-class
switch dissolved onto the appearances. Living truth: `architecture/widget-authoring-guidelines.md` §5
and `architecture/occlusion-culling.md` §2a. What it deliberately did not take on:
- [ ] **`BubblyAppearance.shapeContainsPoint` OVER-CLAIMS its tail strip** (named in the class, not
      silent). A bubble's rounded body occupies only the top `h - h/5`; the bottom fifth is empty
      except for the spike. It inherits `BoxyAppearance`'s rounded-box test, so a click in the empty
      corner beside the spike stops on the bubble instead of falling through. Harmless today (a speech
      bubble is not a thing you click past; the tooltip is a plain rounded plate since W2), and correcting it needs an analytic body+spike
      point test — a BEHAVIOUR change with hover-pixel churn, not a rename. ⭐ Its `opaqueCoveredRect`
      twin was NOT harmless and is already refused: `BoxyAppearance`'s `insetBy cornerRadius + 1`
      reaches BELOW the fill for any bubble taller than ~5×(cornerRadius+1), and a `ToolTipWdgt` is a
      direct child of the world, so the culler asks it and would have dropped real pixels.
- [ ] **A `VideoPlayerCanvasWdgt` with no loadable video is invisible with no visible hider, and
      `show()`ing it HANGS a headless page** (pre-existing; surfaced 2026-08-21 while giving the two
      video-player widgets their first-ever runtime exercise). It constructs with an OWN
      `isVisible = false` (prototype and `Widget` base are both `true`; a plain `CanvasWdgt` is
      visible) at `video.readyState 0` — yet the only `isVisible = false` in src is `Widget.__hide`,
      and nothing in `src/video-player/` calls `hide()`/`__hide`, so what hides it is unlocated.
      Forcing `show()` then hung a headless page (2-min timeout, killed). ⚠ Note the `video-player`
      part carries `requiresFlag: videoPlayer`, so NO profile builds it by default and NO gate ever
      runs these classes — anything here is invisible to the suite, the gauntlet and the smoke.

### SliderTrackClickMovesButton side-problems arc 2026-10-15 — residue (no plan doc; case law in `../../Fizzygum-tests/DETERMINISM.md` §3j)
- The three measured residue items (the list verb's thin-geometry drag, the pixel-short move, the ~1 px bars
  in short viewports) are CLOSED: `archive/backlog-closed-items-ledger.md` § "Residue arc 2026-10-16".
  Its follow-ups are filed under "Residue arc 2026-10-16 — follow-ups" below.
- [ ] (optional, owner to decide) the gauntlet's `refs` leg hits fg's own leg alarm in-wave on a loaded machine
      (twice on 2026-10-15; the second time wave B's legs ran ~280 s each) — a budget question, not a reference
      problem. ⚠ The log line `Alarm clock: 14` names SIGALRM by its signal NUMBER: the budgets are `to 300`
      (`check-refs.js --pixels`) and `to 120` (`check-visualisations.js --strict`), not 14 s.

### Residue arc 2026-10-16 — follow-ups (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
- Six of its follow-ups are CLOSED: `archive/backlog-closed-items-ledger.md` § "Residue arc 2026-10-16 — its six
  follow-ups".
- [ ] **The corner-occupancy protocol does not see the temporary resize/move halo** (2026-10-16). A halo's
      bottom-right handle is not a declared occupant, so a bar runs under it while the halo is up (its side
      handles already sat on the bars). Related, pre-existing: `Widget._setLayoutSpec` updates the
      visibility of only its FIRST handle child, so a halo handle that precedes a frame's resizer would
      keep the resizer's visibility, and its corner reserve, stale.

### Residue-2 arc 2026-10-25 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
The arc that closed the residue arc's five items (the image widget's back-buffer memo and the back-buffer-memos gate, a saved raster's pixel ratio, SWCanvas's deflate encoder, the finger wheel's held swipes and a scroll stroke ending at its release, the shared method grouping's class-side keys) measured these on the way and left them open:
- [ ] **A world holding the video player cannot be saved**: `SimpleRasterImageButtonWdgt` (~:24) assigns `activated` as an INSTANCE function, which the serializer refuses, so "Save world snapshot…" throws at `… → .imageWdgt → .activated` on any `--includeVideoPlayer` world, and so does saving the thumbnail, the face or the player (`Fizzygum-tests/.scratch/arc-r2/R12/logs/p8-vp-*.log`).
- [ ] **A `--includeVideoPlayer` boot logs 304 `NON_INTEGER_GEOMETRY` errors** (same logs) — the integer-placement funnel is violated somewhere in the video-player part, which no gated build ships.
- [ ] **The sw3d work is not vendored**: SWCanvas branch `sw3d-game` (6 commits, `examples/` only) forked from `main` before the pinned font-symbols commit and its `dist/sw3d.min.js` was never rebuilt; bring it in as its own pin bump, from a branch rebased onto `main` with a rebuilt dist, with its own whole-suite check (it reaches Fizzytiles).
- [ ] `census-widget-conformance.js` facet 1 (`declarationsOf`): its `(?!\(|->|=>)` lookahead is defeated by backtracking, so every class-level key counts as a declaration — and that is LOAD-BEARING (a naive fix makes the ratcheted gate report `FridgeMagnets3DCanvasWdgt`'s function-valued fields); its mixin branch counts `ControllerMixin`'s option-object keys as donated fields. Fix both together, or not at all.

### Save/restore-fidelity arc 2026-10-25 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
The arc that closed five save/restore and scroll items (a frame's placeholder exists only while shown; an element the page loads is derived from its holder's path, gate #30; a menu re-takes its width at a lifetime change; a viewport's frame covers its own box) measured these on the way and left them open:
- [ ] **A demo `PointerWdgt` holds its `target` only through a field** (demos part): the world inventory reads the target as ESCAPED the moment a pointer is made (`RectangleWdgt#1@world.children.[0].target`) and after the pointers die; a single-widget save of a pointer is refused (`→ .target`) and a world snapshot CAPTURES the target as an off-tree record (`Fizzygum-tests/.scratch/arc-r3/R12/q2-pointer.js`). Same shape as the placeholder this arc dissolved: an owned widget kept off the tree.
- [ ] **The overflow (») menu's miniature of a text-bearing tool races the glyph atlas on SWCanvas pages**: `OverflowChevronButtonWdgt._miniatureOf` pictures each hidden tool ONCE; the Slides toolbar's "Fizzygum logo with text" icon (`FizzygumLogoWithTextIconAppearance` types with `fillText`, no live-picture escape) shot while text is still loading keeps 36 px of placeholder boxes until the menu's next opening (`.scratch/arc-r3/R3b/logs/overflow-*.log`). The same one-shot picture of a plain `StringWdgt` in an `InertIconHolderWdgt` keeps them for good. Native pages are unaffected; no test opens an overflow holding a text tool.
- [ ] (video-player part) **`SimpleRasterImageButtonWdgt.imagePath` is a second copy of its face's path and goes stale**: after `setThumbnailAndVideoPath` it still reads `icons/splashScreenFakeDesktop.png` while the face shows `icons/xPointerImage.png`; the face's own `imagePath` is the truth since this arc (`.scratch/arc-r3/R34/logs/i4-census-*`).
- [ ] (video-player part) **A `VideoPlayerCanvasWdgt` with no video yet throws under SWCanvas on every paint** (`CanvasCompatibleContext2D._elementToImageLike`; INFERRED a 0×0 `getImageData`), and the error console it opens rides a world snapshot (107 KB → 966 KB in 120 frames, stack entries carrying `file://` paths) — `.scratch/arc-r3/R34/logs/i4-g-harness-dpr1.log`.
- [ ] **On `index-sw.html` in an ordinary browser, SWCanvas's `drawImage` of an image loaded over `file://` throws `SecurityError`** (it reads the image's pixels; the harness runs with `--allow-file-access-from-files`), so an image widget cannot paint on the SW page outside the harness. Nothing shipped draws an `HTMLImageElement` today (`.scratch/arc-r3/R34/logs/i4-noflag-sw.log`).

### SWCanvas correctness arc 2026-10-27 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
The arc that fixed SWCanvas's queued defects and the egregious ones it found (owner triage rule: fix what reaches Fizzygum's tests or usage, or is egregious — a missing shape or row, a hole, paint in the wrong place, a throw or a hang; the minors stay here) measured these and left them open. Each is SWCanvas-repo work, then a re-vendor, and none reaches Fizzygum's current tests unless it says so. Evidence is under `Fizzygum-tests/.scratch/arc-sw/` (research notes `R-A3/NOTES.md`, `R-B2/NOTES.md`, `R-C2/NOTES.md`).
- [ ] **Ellipses are flattened by their MINOR radius** (`Context2D._bakeEllipse`, `PathFlattener._flattenEllipse`): uniform-angle chords miss the major-axis ends by up to (a/b)×0.25 px — worst 0.52 px filled and 0.50 px stroked, against the 0.25 px tolerance. Fix, prototyped in `R-B2/v-chords`: size the count by the device semi-major radius (0.21 / 0.18 px). Fizzygum draws no ellipse.
- [ ] **Path2D curves are flattened with a USER-space tolerance** (`PathFlattener.flattenPath` takes no transform), so the device error grows with the scale: at scale 4 a Path2D arc misses by 0.92 px and an ellipse by 1.53 px (a device tolerance through the CTM's largest singular value gives 0.25 / 0.22). Béziers too (`R-A2/logs/bezier-scale-tolerance.log`). Fizzygum uses no Path2D.
- [ ] **Arc segment counts read the CTM's largest COLUMN length, not its largest singular value** (`Context2D`'s `max(scaleX, scaleY)`): under scale-then-rotate they under-count. It moves 2 SWCanvas PNGs (51 px); no assertion catches it at test sizes (worst 0.125 px).
- [ ] **Two `arcTo` flatteners disagree**: `Context2D._bakeArcTo` (a device-space count) and `PathFlattener._handleArcTo` (a user-space count, which also skips t1 within 0.01 and ends at cos/sin(end) rather than exactly at t2). `fillStadium` (a Path2D) differs from the path `roundRect` in 84 of 5376 cases, and from a `roundRect` clip in 42 (ties, scales 1 and 2). Fix: one sampler and one count (then 0 and 0). An in-page Fizzygum sample did not change.
- [ ] **Open thick strokes end square to the last CHORD, not to the curve** (`StrokeGenerator._generateCaps` takes the first and last segments' tangents): the error is ≈ halfWidth·sin(chord angle / 2), 0.76 / 1.51 / 2.31 px at lw 20 / 40 / 60 on r 60 open arcs (0.25 with the curve's own tangents). Closed rings are fine.
- [ ] **`fillArc` / `outerStrokeArc` / `fillStrokeOuter` drop sub-0.5 px segments near the apex** (`ArcOps`'s `segRight - segLeft < MIN_EDGE_LENGTH`, six sites): `fillArc` misses 24 pixel centres (worst 0.39 px) and `outerStrokeArc` 23 (worst 0.31); and the pie keeps the half-open rule on the circle where `fillCircle` contracts by `FILL_EPSILON`. Fizzygum calls none of them.
- [ ] **Path curves are inscribed chords**: a filled curve misses pixel centres up to 0.25 px inside the true curve (arc fills: 1075 px; `fillStadium` ≤ 0.023 px). Exact crossings are prototyped (`R-B/swc`, "EC9"; a start on the active-edge filler in `R-B2/v-exact/swc`, its curve layer not begun); they want the curve-tag layer two items down.
- [ ] **Stroke flattening ignores the line width, and a curve's vertices are stroked as user joins**: arcs flatten for their radius alone, Béziers at 0.25 USER units, and every flattened vertex takes the stroke's `lineJoin` (miter spikes, bevel facets). Design in `R-A2/NOTES.md`: ONE curve-tag layer feeding the exact fills above, a sweep join at a vertex inside one curve, and flattening for max(r, halfWidth) device px. On 54 arc cases the stroke misses 5169–9544 px today and 1244 with all three. Test draft `R-A2/tests-draft/0NN-thick-curve-stroke-is-its-sweep.js`.
- [ ] **A FILL's pixel at an exact tie can depend on where the fill is drawn** (strokes are anchored since the follow-ons: SWCanvas §9 entry 32). Fills, clips and `isPointInPath` keep absolute device arithmetic, so an integer-vertex fill decides a pixel centre exactly on its edge by rounding at its own magnitude (10 of 836 renders differ between positions, 1 px each; 34 of 3576 integer-edge tie crossings). A device frame for fills was built and REFUSED (`Fizzygum-tests/.scratch/arc-sw/U17/NOTES.md`): a caller that computes its vertices at the device position (`FolderIconAppearance`'s slant, before it drew from its own box) is re-rounded consistently by absolute arithmetic, and the frame made such fills depend on position. It wants the path stored translation-free first: the default path is kept in DEVICE space and mapped back through the inverse, which is inexact at non-dyadic scales (0.75, 1.5, 3), so two spellings of one shape disagree on ties there (fill 232 / clip 116 of 5376 cases at scale 3). The rotated `strokeRect` (`RectOpsRot`) is not framed either. Fizzygum runs at dpr 1 and 2 only.
- [ ] **A semi-transparent rotated `strokeRect` blends some pixels twice** (`RectOpsRot._stroke_Rot_Alpha`: the two opposite edges of a pair share a role, so where they overlap they blend twice): 48 of 648 cases, 1171 px, every one a rect with min(w, h) < lineWidth. The axis-aligned direct `strokeRect` does the same on tiny rects (lw 6 on a 4×4 rect paints alpha 193 for a 0.5 colour).
- [ ] **`Color` stores premultiplied 8-bit components**, so a translucent colour's straight components drift: up to 127 levels at alpha 1–15, 7 at 16–63, 1 at ≥ 128 (rgba(200,100,50,1/255) reads back (255,0,0,1)). Fix prototyped in `R-C2/N2c-keep/` (exact straight storage, and `copy` of a transparent colour gives 0,0,0,0; faster; a core test draft): over opaque destinations it then matches Chrome (0 of 1270 samples differ, main 526 at 1 level). Fizzygum: ±1 level, INFERRED ~30–40 tests per density to recapture (from a 62-test sample).
- [ ] **`putImageData` of (255,0,0,0) keeps its RGB**, where Chrome reads back 0,0,0,0. Invisible (alpha 0).
- [ ] **`xor` is binary on partial alpha** (it gives 0,0,0,0; off by up to 127–178 levels), and **`lighter` and the blend modes fall back to source-over** (off by up to 220). Fizzygum uses only source-over, source-in and destination-out.
- [ ] (Fizzygum) **`PaletteAppearance`'s rings sit at a radius ± 0.5 about a pixel centre** (~:45-46), which puts both ring edges ON pixel centres, so the 3.5 ring is asymmetric at dpr 1. An integer radius 3 is symmetric at dpr 1 and 2 under every variant (`R-B2/logs/ring-symmetry.log`). Cosmetic; a fix moves the palette's pixels (a recapture).

### Tooling arc 2026-10-29 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
- [ ] **A screenshot whose reference never LOADED reports as a pixel mismatch.** `AutomatorPlayer.compareScreenshots`
      falls through to "FAIL - no screenshots like this one" when `candidates` is EMPTY, the same words as a real
      mismatch. Seen at the arc's closing gauntlet (machine at load 54, battery 7%): the `settle` leg's parallel run
      failed `SystemTest_macroLockedCompositeWidgetPreventsDrag` image_1, and the picture the leg kept
      (`FIZZYGUM_FAILURE_IMAGES_DIR`) is pixel-identical to the committed reference (its hash `a329fa14…` IS the
      reference's) — so no reference was there to match, on a shard that had needed a boot-storm reload. Fix: an empty
      candidate set gets its own failure line ("no reference loaded for X — its pixels were not compared"), still a
      failure, so the next one classifies itself as infra at a glance; then ask why a reference record can go missing
      mid-run (the loader proceeds on the reference scripts' onload — does an onerror go unreported?).

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
- [ ] `archive/hover-resync-after-flush-plan.md` § CAPSTONE GATE WEAKNESS note: the capstone's paint-time half (the paint-read-only audit, which now rides the capstone pass) shares the careless-push-count-only weakness — still open backlog
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.2 A3: must-call-super table-driven rule — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.4 A6: dead-class detector (ReClassNotReferencedRule) — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.5 C: per-file metrics ratchet for god-class line counts — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.9: empty-catch stink — needs multiline stink-engine extension
- [ ] `archive/lint-ratchet-static-checks-plan.md` Phase 4: encode tier in underscore prefix on immediate mutators — PARKED, owner-gated, low priority
- [ ] ⛔ `archive/paint-time-scroll-translation-plan.md` Phase 4 (OWNER-GATED): lift `scrollOffsetX/Y` + `_writeScrollOffset` + the paint interception + the `scrollTranslationOfChild` provider from `ViewportWdgt` to the clipping-mixin level — "scrollability as a property of every panel". Designed, deliberately unlifted until a second user exists (YAGNI; the seam is stated in that plan's STATUS BOX Phase-4 row). Phases 0–3 of the arc are EXECUTED (2026-08-20): the offset is stored truth, the plane is pinned, paint/hit/damage/clip/input all speak the translation; living truth = `architecture/viewports-and-planes.md`.
