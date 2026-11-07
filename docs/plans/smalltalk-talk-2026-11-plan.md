# Smalltalk talk, 25 Nov 2026: Lively-style demos, Smalltalk-style code organisation, a moldable inspector, in-world profiling, Fizzylogo

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
**STATUS: AUTHORED 2026-11-07. No code written. Every fact in §1 was re-verified against the tree at
Fizzygum `c619e504` / tests `ce9e3a339` on 2026-11-07.** Line numbers drift: the quoted method or
symbol name is authoritative, so grep it fresh before trusting a number.

**HARD DEADLINE.** The talk is on **2026-11-25**, in a **45-minute** slot, at a Smalltalk conference.
**Feature freeze is 2026-11-21**, leaving four days to rehearse. Everything here is ranked:
**★ = needed for the talk**, **☆ = only if time allows**, **☆☆ = after the talk**. When behind schedule,
cut in the order §5.2 gives. Never trade away a green gauntlet for a feature.

## Mandate

Make Fizzygum's live-programming story *stand next to* Lively Kernel's and Smalltalk's on stage, and
build it as real product code, not demo-ware:

- run the classic Lively/Squeak demos inside Fizzygum;
- close the three tool gaps a Smalltalk audience will notice, with each one actually closed rather
  than faked:
  1. **no method protocols / code organisation;**
  2. **an inspector that is not moldable;**
  3. **no profiling or tracing from inside the world.**

Everything built here ships through the normal gates, carries SystemTests, and stays in the product
after the talk. Nothing is a throwaway branch.

---

## 0. Orientation

### 0.1 What Fizzygum is (one paragraph, then go read the CLAUDE.md files)

Fizzygum is a CoffeeScript "web operating system" drawn on one HTML5 canvas, descended from
Morphic.js. Its lineage runs Squeak Morphic → Lively Kernel → Morphic.js (Jens Mönig's, which Snap! is
built on) → Zombie Kernel → Fizzygum.

Some properties that matter for this plan:
- **Every class's source text ships inside the image and is compiled in the browser.** It is stored in
  `SourceVault`, with no module system.
- **Edits are live.** The class inspector edits a method live, through `Class.applyMemberEdit`.
- **Edits are logged in a per-world change list** (`SourceEditsRegistry`), which is saved with a world
  snapshot and replayed on restore.
- **It runs from `file://`** with no server.

Workspace and build routing: the umbrella `CLAUDE.md` at `/Users/davidedellacasa/code/Fizzygum-all/`,
plus `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md`. Always use the `fg` wrapper by absolute
path: `/Users/davidedellacasa/code/Fizzygum-all/fg`.

### 0.2 Why this plan exists now

The owner (Davide Della Casa, who wrote Fizzygum) is giving a talk on 2026-11-25 to Smalltalkers. The
talk shows Fizzygum and its kinship with Lively Kernel. A research pass on 2026-11-07 compared:
- Lively's and Squeak's famous demos;
- Pharo/GT's moldable tools;
- Smalltalk code organisation;
- the owner's own design notes;

against the current tree. This plan is its executable distillation.

### 0.3 ⭐ Critical reframes: read these before anything else

1. **Most of Lively's headline demos already run in Fizzygum. The gaps are in the tools.**
   - *The clock edited live to run backwards:* a SystemTest already does it,
     `SystemTest_macroAnalogClockInspectEdit` (it negates `@secondsHandAngle` in `drawSecondsHand`).
   - *Rotating a live window:* `TransformFrameWdgt`, `Widget.setRotationDegrees`.
   - *Wiring widgets together* (Lively `connect` / Fabrik): pins and wires, plus patch nodes.
   - *Saving a world with its code edits:* `SourceEditsRegistry`.
   - *Editing the inspector with the inspector:* already works.

   What a Smalltalker will miss is method protocols, senders/implementors, a moldable inspector, and
   a profiler you start from inside the system. So the build effort goes into those, while the demos
   are mostly rehearsal (§6).
2. **Build the moldable inspector *alongside* today's inspector, and embed the old one as one of its
   views.**
   - `InspectorWdgt` is already "a first-class NAKED widget" (its header), so it can be one view, the
     *Members* view, of a new explorer pane.
   - The existing "Inspect" menu item, its 16 SystemTests and their reference screenshots stay
     untouched.
   - The new tool opens from **Dev tools → "Explore"**, the name early GT used for exactly this.

   Do not rewrite `InspectorWdgt` (§9).
3. **Name-based protocol inference covers only about two thirds of methods.**
   - Measured on 2026-11-07 with a generous 19-rule name classifier (Appendix D):
     - **64% of the tree's 4,242 methods** got a category and 36% did not;
     - on `Widget` (384 methods) it was 78% / 22%;
     - some of the "classified" ones were wrong (substring hits).
   - So protocols are a **hybrid**: written markers where a person has decided, and inference
     everywhere else. Anything left over goes into Pharo's own honest bucket, **"as yet unclassified"**.
     See D2 in §0.4.
4. **There is no in-world macro *recorder*.** SystemTests are hand-written CoffeeScript macros. So the
   "deterministic replay under the profiler" story is told with an *existing SystemTest*, not a fresh
   recording.
5. **Fizzylogo's published `dist/fizzylogo.js` is already the generator ("yielding") interpreter, but
   it also bundles and runs its whole test suite at load** (its tail is the test loop, ending
   `"all tests done…"`). Rebuild it from source without the tests (Appendix B).
   - Its turtle draws straight onto a 2D context, so a ~30-line fake-canvas adapter makes it draw
     through Fizzygum's own `CanvasWdgt.drawLine`. Fizzylogo itself needs no change.
6. **Class comments are already parsed, then thrown away.**
   `Class.findClassDescriptionHeaderCommentAndClassName` returns the header comment, and the `Class`
   constructor discards it (`[@name, ignored, sourceLines] = …`).
   `Class.getSourceOfAllProperties` likewise collects every member's preceding comment block
   (`propertyComment`) and never uses it. Keeping them is cheap, and protocol markers ride the same
   path (U4).
7. **Reference images must be loaded the harness's way**, as the `.js` asset wrappers, never by
   pointing an `<img>` at a `.png` over `file://`. Over `file://` a canvas drawn from a `file:` image
   can become *tainted*, and a tainted canvas makes the test harness's pixel reads throw. The harness
   loads references as `.js` files (`AutomatorLoader.loadImagesOfTest`) precisely for this reason.
   Verify in spike S6.

### 0.4 Owner decisions

| # | Decision | Status |
|---|---|---|
| D1 | Talk date and length | **LOCKED**: 2026-11-25, 45 min |
| D2 | Protocols: inferred, written markers, or hybrid | **OPEN. Default: HYBRID** (below) |
| D3 | Explorer shell: one pager window, or a window per object | **OPEN. Default: windows that line up, pager as ☆** (below) |
| D4 | The new tool's name and door | Default: **"Explore"** in the Dev tools submenu. "Inspect" stays as it is until after the talk |
| D5 | Commits | Per house rule, **ask before every commit/push**. At the start, ask the owner whether this plan gets a standing commit grant ("commit and continue while gates pass; ask before push"), as the affine-transforms plan did |
| D6 | Where talk-only assets live (stage snapshots, demo mbox, deck) | Default: **outside the three repos**, in `~/Desktop/talk-2026-11-25/` |

**D2 explained (protocols).**
- **Inferred:** the tool computes each method's protocol from its name every time it looks, the way
  Pharo's `MethodClassifier` suggests one. For example, `isFoo` goes to *testing*, `initialize` to
  *initialization*, `…Width` to *geometry*.
  - Pros: zero source changes, always complete, nothing to keep in sync.
  - Cons: about 36% lands in "as yet unclassified", some guesses are wrong, and it can only know what
    names say. "This is the PIN protocol" is a human decision that no name encodes.
- **Written markers:** the source says what the author decided. A line `  # protocol: geometry` sits
  at class-body indentation above a run of members, and the parser records it.
  - Pros: precise, intended, survives renames, and is what Pharo/Tonel do (each method carries
    `category:`).
  - Cons: it touches source. Widget's 384 methods are not grouped by topic today, so marking it
    properly means either about 150 marker lines or reordering members (a huge diff, against
    member-order constraints). Every new method also needs one.
- **Hybrid (recommended):** markers win where present and inference fills the rest. The view shows
  which is which (an inferred protocol is drawn dimmed), and leftovers go to "as yet unclassified".
  - For the talk, mark only the classes shown on stage (they are small).
  - `Widget` stays inferred, and its 22% unclassified is shown honestly: Pharo has the same bucket.
  - Markers are comments, so they change no pixel and no inspector screenshot.

**D3 explained (inspector shell).**
- **Pager (Glamorous Toolkit style):** one window holds a row of panes, one pane per object. Clicking
  an item in a pane's view opens the next object in a new pane to its right and drops any panes
  beyond.
  - Pros: the navigation path stays visible, there is no window clutter, and Smalltalkers know it
    from GT.
  - Cons: it needs a new horizontal container with its own layout, the riskiest kind of new code in
    this tree (settle tiers, layout gates). Comparing two unrelated objects also needs a way out of
    the strip.
- **Window per object (Squeak/Lively style):** each drill opens a new window.
  - Pros: no new container, it fits Fizzygum's desktop, and objects sit side by side.
  - Cons: clutter, and the path back is lost.
- **Recommended: windows that line up.**
  - Build the **pane** (`ObjectExplorerPaneWdgt`) first. It is the same widget in either shell.
  - Open each drilled pane in its own window, placed immediately to the right of its parent's window
    with the same top and height. On stage this reads as a pager made of windows, and any pane can be
    dragged away to compare.
  - The real pager container is ☆: no pane work is lost when it comes, and tear-off is free because
    every pane already lives happily in a window.

### 0.5 Cold-execution protocol (read and run in this order)

1. **Orient:** `/Users/davidedellacasa/code/Fizzygum-all/fg status`.
   - If `Fizzygum`/`Fizzygum-tests` are dirty with another arc's work (on 2026-11-07, the
     every-gate-bites arc had 89 and 87 dirty files), **stop and ask the owner**. This plan touches
     `src/`, `parts.json`, `buildSystem/` and the tests repo, and must not interleave with an
     uncommitted arc.
   - Docs-only edits are always safe.
2. **Read** the three CLAUDE.md files, then:
   - `Fizzygum/docs/architecture/lint-and-static-checks.md` §3 and §8 (the 33 build gates: a new
     class or method must satisfy them);
   - `widget-authoring-guidelines.md`;
   - `build-and-packaging.md` (parts, lazy doors, vendor payloads);
   - `world-lifetime-and-inventory.md` (teardown: the profiler must not leak);
   - `constructor-and-parameter-conventions.md`;
   - `visual-design-system.md` (**colours come from `Theme` roles only; the `raw-chrome-color` stink
     is HARD at 0**).
3. **Ask the owner** D2, D3, D5 and D6 if they are still OPEN, and use the defaults if told "go".
4. **Run U0** (the spikes). Each spike either confirms its unit's design or rewrites it *in this doc*
   before code is written.
5. **Run the units in §4 in order, ★ first.** Each unit ends with these steps:
   1. `fg presuite`.
   2. The unit's own SystemTest(s) pass.
   3. Commit per D5.
   4. Tick its row in §5.1.

   At the freeze (§5): `fg gauntlet`, then the push request.
6. **Never** call a failing reference "benign churn" without looking at it. Inspector member-list
   churn is the one owner-sanctioned benign recapture class (`fg recapture-inspector`). Anything else
   gets a pixel look first (`fg recapture --auto`, after a fresh build).
7. Long ops (`fg presuite`, `fg gauntlet`) run in the background with a log. Peek at the
   `/tmp/fg-<cmd>.verdict` file every ~5 min, never in a polling loop (umbrella CLAUDE.md, "Long
   ops").

---

## 1. Current state (verified 2026-11-07)

### 1.1 Meta-system and edit path

- `src/meta/Class.coffee` (574 lines):
  - **Regexes:**
    - `classRegex`;
    - `propertyRegex: /^  (@?[a-zA-Z_$][0-9a-zA-Z_$]*) *: *(.*)/m` (a member is a 2-space-indented
      `name:` line);
    - `augmentRegex`;
    - `topLevelCommentRegex: /^  #.*/m`.
  - **`getSourceOfAllProperties`:** walks the body with `findUpTo` and stores each member's source in
    `nonStaticPropertiesSources` / `staticPropertiesSources`. The comment lines *before* a member come
    back as `propertyComment = returned[1]` and are discarded.
  - **`findClassDescriptionHeaderCommentAndClassName`:** returns the header comment, which the
    constructor drops.
  - **`applyMemberEdit(memberName, source)`:**
    - compiles the member;
    - sets `proto[memberName] = fn` and `proto[memberName + "_source"] = source`;
    - does not notify instances, which is the caller's job.
  - **`_equivalentforSuper`:** rewrites `super` to `<ClassName>.__super__.<member>.call(this, …)`. It
    is a **dynamic** lookup at call time, so a function swapped onto a superclass prototype *is* seen
    by subclass `super` calls (this matters for U2).
  - **Instance tracking:** `_addInstancesTracker` makes `window.<Class>.instances` work (widgets only;
    see the class's header).
- `src/meta/Mixin.coffee`:
  - **Members are copied onto each consumer prototype.**
  - **A mixin's fake `super` resolves through
    `window[@[arguments.callee.name + '_class_injected_in']].__super__[arguments.callee.name]`.** It
    relies on the executing function's `.name`. A wrapper that calls the original with `.apply` keeps
    that intact.
  - **`Mixin.applyMemberEdit`** re-injects the edited member into every consumer that does not shadow
    it.
- `src/serialization/SourceEditsRegistry.coffee`:
  - `recordInstanceEdit`, `recordClassEdit`, `recordMixinEdit`, `recordMixinMemberRemoval`,
    `serializableRecords`, `replayClassEdits`, `replayMixinEdits`.
  - A record is `{scope, className|mixinName, uniqueID?, propertyName, source?, deleted?}`.
- `src/boot/source-vault.coffee`: `SourceVault.store(name, escapedText, part)`, `.get(name)`,
  `.names()`. It holds only sources whose part batch has loaded.

### 1.2 Inspector and doors

- **`src/meta-tools/InspectorWdgt.coffee`** (905 lines), in the **lazy `meta-tools` part**:
  - **Layout:** a breadcrumb of class chips, a toggles band (Methods / Fields / Inherited / Own props
    only), the member list (`ListWdgt` with `memberFactsQuery: "memberFactsOf"`), the code pane, and a
    footer (Add… Rename… Remove… Save).
  - **Member list:** `_filteredMemberNames` walks every enumerable property, and **`showingInherited`
    defaults to false**. A member added to a *base* class therefore does not appear in a subclass
    inspector's default list, while one added to the inspected class does.
  - **Source display:** `selectionFromList` shows the *recorded CoffeeScript source*, never
    `fn.toString()`, unless no source is recorded. So a wrapped method still shows its CoffeeScript.
  - **Drilling:** `inspectMemberValue` opens a **naked** inspector at the pointer.
- **`ClassInspectorWdgt`** (subclass): adds "Override in this class" for mixin-donated members.
- **Doors** (`src/basic-widgets/Widget.coffee`):
  - `inspect` → `spawnInspector`. The lazy-door pattern is:
    1. `world.parts.isAvailable "meta-tools"`;
    2. `world.parts.whenAllLoaded ["meta-tools"], …`;
    3. `ensureReflectiveLayerLoaded()`;
    4. `new (window["InspectorWdgt"]) inspectee` (the class is named **as data** because
       `buildSystem/check-part-edges.js` forbids core naming a lazy part's class as a symbol);
    5. `world.openFrameWith inspector, new Point(560, 410), …`.

    Copy this pattern for every new door, **but spell step 4 `new (classNamed "X")`**. `classNamed`
    is boot's helper (`src/boot/globalFunctions.coffee`), which `PartsRegistry.launch` already uses,
    and the root CLAUDE.md asks for it over `window[name]`: a plain `window` lookup also answers
    inherited properties and native globals. Both spellings pass the part-edge gate, because it
    deliberately does not chase string names.
  - `createConsole` follows the same pattern.
  - **Dev tools submenu:** `MenusHelper.popUpDevToolsMenu` (`src/basic-widgets/menu-system/MenusHelper.coffee`)
    offers "Inspect" and "Console". It is reached from a widget's context menu as "Dev", shown only
    when `world.isDevMode` (boot sets it true in `finishWorldSetup`).
  - **Doors on `world`:** the comment at `Widget.buildBaseWidgetClassContextMenu`'s "Test menu" line
    explains why doors are put on `world` and not on `Widget`: every public member added to `Widget`
    is listed by the inspector and churns references.
- **Inspector SystemTests (16):** AnalogClockInspectEdit, ClassInspectorSaveRefusesCodeThatDoesNotCompile,
  DuplicatedInspectorDrivesCopiedTargetOnly, DuplicatedInspectorsCloseIndependently,
  ErrorConsolePopsClean, InspectorBreadcrumbChipOpensClassInspector, InspectorOnNonWidgetIsReadOnly,
  InspectorRejectsDrops, InspectorResizingOKEvenWhenTakenApart,
  InspectorSaveRefusesCodeThatDoesNotCompile, InspectorScrollbarUnplugged,
  InspectorWorkAreaEvaluatesCoffeeScript, NakedInspectorRendersResizesAndEdits,
  PickingUpPartsFromInspector, ResizingPristineInspector, SimpleDocumentHandlesOldInspector (each with
  the `SystemTest_macro` prefix).
  - `fg recapture-inspector` recaptures the member-list churn set.
  - One test file names the `"Dev"` menu item.

### 1.3 The composed-declaration precedent: pins

- `Widget.pins` returns `PinSpec` records, and subclasses extend them with
  `pins: -> super().concat [ new PinSpec "value", "numerical", set: "setValue", get: "getValue" ]`.
- `PinSpec` (`src/basic-widgets/PinSpec.coffee`) is a shallowly immutable record that names its
  setter and getter **as strings** (late binding by name: it survives serialization, and the dataflow
  dispatches by name).
- The runtime twin gate is `Fizzygum-tests/scripts/pin-sweep-headless.js` (`fg pinsweep`). It boots
  the page and asks every instantiable class's composed `pins()` whether each named method resolves,
  because a composed list can *narrow*, which a static scan cannot see.
- **This is the mechanism U3 reuses for explorer views** (owner principle: reuse the existing
  mechanism, one of each thing).

### 1.4 World loop, stepping, errors

`WorldWdgt.doOneCycle` runs the following in order:
1. `_showErrorsHappenedInRepaintingStepInPreviousCycle` / `_showLayoutErrorsFromPreviousCycle`;
2. `macroToolkit?.progressOnMacroSteps`;
3. `_playQueuedEvents`;
4. the automator replay;
5. `progressFramePacedActions`;
6. **`_runChildrensStepFunction`**;
7. `dataflow.recalculateDataflow`;
8. `storageSorter.drainPendingSort`;
9. `_updateFocusedFrameNoSettle`;
10. **`recalculateLayouts`**;
11. hover re-sync;
12. `pinouts?.reconcile`;
13. overlays;
14. **`_repaintDamagedRects`**;
15. end-of-cycle captures;
16. `_closeCycleBookkeepingNoSettle`.

It already reads `performance.now()` for the compile budget (`cycleStartPerfMs`), which is the
precedent for U2's timer.

- **Stepping:** a widget steps when it is in `world.steppingWdgts`, at its `fps` (`fps <= 0` = every
  cycle). `AnalogClockWdgt` adds itself in its constructor.
- **Step errors:** `_stepWidget` wraps `step()` in a try/catch that calls `_softResetWorld()` and shows
  the error console. The widget stays in the stepping set.
- **Paint errors:** these queue the error, **hide the offending widget** (`_hideOffendingWidget`) and
  repaint.

### 1.5 Demos and apps that exist

- **`AnalogClockWdgt`** (`src/apps/`):
  - `step` stamps `dateLastTicked` and calls `_changed`;
  - the hand angles are computed in `AnalogClockAppearance._calculateHandsAngles`;
  - the hands are drawn by the public `drawHoursHand` / `drawMinutesHand` / `drawSecondsHand`, whose
    comment calls them "the live-edit demo target".
- **`TextAreaWdgt extends ViewportWdgt`** (`src/TextAreaWdgt.coffee`). The demo menu builds one with
  `new TextAreaWdgt(@LOREM_LONG, true, 10)` (`DemoMenus.createWrappingTextAreaWdgt`).
- **`ViewportWdgt.scrolledBy(xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg)`:**
  1. normalises deltas (`WorldWdgt.preferencesAndSettings.normalizedWheelDeltas`);
  2. escalates at the scroll ends;
  3. otherwise calls `@scrollY y * WorldWdgt.preferencesAndSettings.wheelScaleY`.
- **Demo menu actions:** `src/demos/DemoMenus.coffee` (lazy `demos` part) includes `throwAnError`,
  `createCalculatingPatchNode`, `createDiffingPatchNode`, `createRegexSubstitutionPatchNodeWdgt`,
  `createFanout`, `makeBouncingParticle`, and more.
- **Pen and bouncer:**
  - `PenWdgt` (`turn`, `forward`, `down`, `up`, `clear`, `sierpinski`, `tree`) draws through its
    parent's `CanvasWdgt.drawLine(start, dest, lineWidth, color)`, in the canvas's logical pixels
    with points relative to the canvas. The comment says drawLine is the *only* turtle primitive on
    the canvas: keep it that way.
  - `BouncerWdgt` also lives in `src/demos`.
- **Save/restore:** world-menu items "Save world snapshot…" (`saveWorldSnapshotToFile`) and "Open from
  file…" (`openFromFile`).
- **File drop:** a file dropped on the page goes to `FileLoading.loadFile`, which accepts only
  Fizzygum `*.fzw.json` envelopes.
- **Slides:** `SlideWdgt`, `SimpleSlideApp`, `SlidesToolbarWdgt` (`src/authoring`).
- **Rotation:** `Widget.setRotationDegrees` materialises a `TransformFrameWdgt` island.

### 1.6 Parts, vendor payloads, profiles

- `buildSystem/parts.json`: `core` plus named parts, each with `dirs`, `eager`, `requires`, and
  optionally `vendor`.
  - **`fizzytiles` is the model for a lazy part with a vendored JS payload:**
    `vendor: [{out: "js/vendor-parts/fizzytiles-3d.js", concat: ["vendor/swcanvas/…min.js", …]}]`.
  - `build.py` assembles the payload, and `PartsRegistry` injects it with `loadJSFilePromise` before
    the part's classes run.
  - `PartsRegistry._vendorAlreadyPresent` hard-codes its idempotence check for `"fizzytiles-3d"` and
    must learn the new payload.
- Vendored third-party code lives in `Fizzygum/vendor/` with a `.pin` file naming the source commit
  (`vendor/swcanvas.pin` holds a sha).
- `profiles/dev.json`: `"parts": "all"`, compile at boot. A new part joins the dev build with no
  profile edit. `homepage` lists its parts explicitly, so a new part stays out of production unless
  added.
- The harness and `index-sw.html` load all parts eagerly (`FIZZYGUM_EAGER_ALL_PARTS`); `index.html`
  loads lazy parts on demand.

### 1.7 The test suite as a domain

- **373 SystemTests**, one directory each under `Fizzygum-tests/tests/`, served to the build through
  the `latest/js/tests` **symlink** (never `rm -rf` it with a trailing slash; umbrella CLAUDE.md).
- **Test definition file:** `SystemTest_<name>/SystemTest_<name>.js` defines a global
  `SystemTest_<name>` with these fields:
  - `description`, `intent`, `scenario`, `assertions`, `provenance` (strings);
  - `tags` (array);
  - `testDuration`.
- **Reference images:** these live under
  `automation-assets/<OS>/<ver>/Chrome/<ver>/SWCanvas/ceilPixRatio_<N>/[finger/]`. Each image comes as
  both a `.png` and a `.js` wrapper.
- **Manifests:**
  - The world reads `Automator.testsManifest` (test names) and `Automator.testsAssetsManifest` (asset
    paths without extension), loaded in `src/boot/globalFunctions.coffee` (`loadJSFilePromise
    "js/tests/testsManifest.js"`).
  - **Which entry pages load the manifests is unverified: spike S6.**
- **Running a test from the world:** `world.automator.loader.loadAndRunSingleTestFromName(name)`, on
  the harness page. **Running a test resets the world.**
- **Macro assertions:** `MacroToolkit.assertValuesEqual(description, expected, found)` (in
  `src/macros/MacroToolkit.coffee`), which a test uses to assert numbers without screenshots.

### 1.8 Gates any new code meets (the ones this plan's code is most likely to trip)

| Gate | What it means here |
|---|---|
| `check-dead-methods.js` | Every new method must be reached by a property access, a whole-name string (`"m"`) or a name template. Menu actions named as strings count |
| `check-unresolved-sends.js` | Every sent name must be defined somewhere (the `aView` builder API included) |
| `check-part-edges.js` | Core may not name a lazy part's class as a symbol. Use the door pattern of §1.2 (`new (classNamed "X")` after the part loads) |
| `check-menu-actions.js` + `fg menusweep` | Every new menu row must resolve, and the runtime sweep *fires it*. A row that cannot run headless goes in the sweep's `SKIP` table **with its reason** |
| `check-stinks.js` | `timer` (setTimeout/setInterval, baseline 4: **do not add one**); `wall-clock` (`Date.now()`/`new Date(`, baseline 19: use `performance.now()`); `instanceof-type-test` (baseline 74: use capability queries); `raw-chrome-color` (HARD 0: Theme roles only) |
| `check-layering.js` / call separation | The `NoSettle` / settle-tier naming and the public/private split (`_` prefix). Read lint doc §4 and §6 |
| constructor conformance / argument holes | Identity args are positional, optional ones go in `opts` (PinSpec's constructor is the model) |
| runtime legs: paint audit, settle, capstone, revisits, census, serialization, storage, vmtruth | A new widget must settle, paint truthfully, serialize (or declare transients), and be GC-collectible after destroy |

---

## 2. Why things are shaped this way

- **The inspector lists enumerable members of the whole prototype chain.** That is why core doors
  avoid adding public members to `Widget`: each one shows up in inspector screenshots. It is also why
  the new explorer's *default* views live in the lazy `meta-tools` part, keyed by capability, and not
  as methods on `Widget`.
- **PinSpec names methods as strings** so that declarations survive serialization and duplication. A
  composed `super().concat` list lets a subclass narrow what it inherits. Views have the same needs:
  ordered, narrowable, late-bound.
- **Lazy parts and the part-edge gate exist so production does not pay for dev tools.**
  - Every dev tool here goes into a *lazy* part (`meta-tools` or a new `fizzylogo` part).
  - Every door follows the `spawnInspector` pattern.
- **Determinism is the suite's contract** (`Fizzygum-tests/DETERMINISM.md`). The world is driven
  cycle by cycle on a virtual clock. That is why:
  - nothing may use `setTimeout`;
  - wall-clock numbers (profiler milliseconds) must never be in a reference screenshot;
  - the Fizzylogo interpreter is driven from `step`, not from timers.

---

## 3. The distilled argument

- **Instrumentation without DevTools.**
  - Lively proved that "the system instruments itself" is a half-page of code: Ingalls's
    `Object.profiler` wraps each method in a counting proxy (Appendix A).
  - Fizzygum's meta-system knows every class's members, every mixin donor and every source text, so
    the same idea is *more* complete here, and needs no CDP or server, which the owner rules out.
  - The existing `docs/profiling/` Puppeteer/CDP harness stays an offline measuring tool.
- **A moldable inspector without rewriting the inspector.**
  - Pharo/GT made the inspector generic by letting each class contribute views.
  - Fizzygum already has the exact declaration pattern (pins), and a naked-capable inspector that can
    be embedded as one view. So the cost is one pane widget, one view builder, and a handful of
    views.
  - This also delivers the owner's long-standing "browsers are just lists" design (Appendix C) at
    almost no extra cost: a query result is just another object with a list view.
- **Protocols honestly.** Inference alone overpromises (64%), and markers alone are a 561-file churn.
  The hybrid gives a Smalltalk-shaped browse today, with an honest "as yet unclassified" bucket.
- **Fizzylogo** is the owner's Smalltalk-72/Rosetta-Smalltalk-style language, where objects parse
  their own message streams. Running it inside a Morphic world, with its turtle drawing on a Fizzygum
  canvas in a rotated window, is the talk's Smalltalk-lineage closer. The integration is small
  because Fizzylogo already exposes a generator API.

---

## 4. Work units

Each unit lists its priority, effort, steps, files, tests and done-when. Effort is in working days for
one focused session. Units are ordered by dependency and stage value.

### U0. Setup and spikes ★ (0.5 day)

Every spike runs in the dev build's browser console or a scratch `.coffee` that is **not committed**.
Each spike's finding is written back into this doc, in the relevant unit, before that unit starts.

- **S1. Method wrapping (for U2).**
  1. In the console, wrap every own function member of `AnalogClockWdgt.prototype` (skip
     `constructor`) with a counting wrapper that calls the original with `.apply(this, arguments)`
     inside `try/finally`.
  2. Confirm that:
     - the clock keeps ticking and painting;
     - `super` calls into wrapped superclass members still work (wrap one `Widget.prototype` method
       the clock reaches through `super`);
     - a mixin-donated member wrapped on a consumer prototype still resolves its fake super;
     - the inspector still shows CoffeeScript for a wrapped method.
  3. Measure `performance.now()` granularity on `file://` in Chrome and Safari.
  4. Then edit `drawSecondsHand` through the class inspector *while wrapped*, and confirm the edit
     replaces the wrapper. This is why stop must check identity before restoring (U2 rule 3).
- **S2. Fizzylogo boot (for U5).**
  1. Clone `https://github.com/davidedc/Fizzylogo` to `~/code/Fizzylogo` (the owner's MIT repo) and
     run its yielding build without tests (Appendix B).
  2. In the dev page console, load the output with a `<script>` tag.
  3. Call `Fizzylogo.init({value: ""}, fakeCanvas, 1)`, then drive `gen = Fizzylogo.runOneStep("console
     print 2+3")` with `gen.next()` until `done`, and read the output shim's `.value`.
  4. Then run the star program (Appendix B) against a `fakeCanvas` whose `getContext("2d")` logs
     `moveTo`/`lineTo`.
  5. Confirm that only `window.Fizzylogo` is exported, and that nothing runs tests at load.
- **S3. Step-error fix-and-retry (for the §6 optional beat).**
  1. Add a demo widget whose `step` throws.
  2. Fix the method in the class inspector and observe whether the next step succeeds. The widget
     stays in `steppingWdgts`; check whether `_softResetWorld` disturbs it.
  3. Record the behaviour. If it heals, it is a 30-second stage beat. If not, drop the beat and file
     the finding in `docs/BACKLOG.md`.
- **S4. Protocol markers (for U4).** In a scratch copy of `Class.getSourceOfAllProperties`, confirm
  that a `  # protocol: geometry` line placed between two members arrives in the *following* member's
  `propertyComment`. Run `node buildSystem/check-coffee-syntax.js` (via the build) to confirm the
  build-time syntax gate, which drives this parser in Node, is unaffected.
- **S5. Jobs scroll arithmetic (for U1).** Log `yArg` per wheel event in `ViewportWdgt.scrolledBy`,
  for a mouse wheel and for a trackpad, together with `wheelScaleY` and the text's line height.
  Decide the quantisation unit (§U1).
- **S6. Tests as data (for U6).**
  1. On `index.html` *and* `index-sw.html` of the dev build, check that `Automator.testsManifest` and
     `Automator.testsAssetsManifest` exist.
  2. Load one test's definition with `loadJSFilePromise "js/tests/<name>/<name>.js"` and read its
     `intent`.
  3. Load one reference `.js` wrapper and find where the image lands (`AutomatorPlayer.loadedImages`;
     read `SystemTestsReferenceImage.createJSContent`).
  4. Draw it into a canvas and confirm `getImageData` does not throw (no taint).
  5. Find where a macro test's *macro source* lives (the definition `.js`, or
     `_automationCommands.js`) and how to read it as text.

**Done when:** each spike's result is written into its unit below, and any design change is reflected
in this doc.

### U1. Stage kit and the Jobs 1979 re-enactment ★ (1 day)

**Story (verified, HOPL-IV "The Evolution of Smalltalk", 2020).**
- In December 1979 Steve Jobs's team visited PARC. The machine was a Dorado, running Smalltalk-76.
- Jobs asked for the text selection to show as an outline instead of inverted video, and Dan Ingalls
  changed it live.
- Jobs then disliked the jumpy line-by-line scrolling, and Ingalls made it smooth while they watched,
  by changing `TextImage>>scrollUp:` from `delta / self lineheight` to
  `delta asFloat / self lineheight`.
- The Computer History Museum re-enacted it in 2018.

**Fizzygum re-enactment.** Add a demos-part class, `src/demos/JobsScrollTextAreaWdgt.coffee`:

```coffee
# Re-enacts the 1979 Jobs demo (HOPL-IV, "The Evolution of Smalltalk"): a wheel delta becomes WHOLE
# lines of scroll, as Smalltalk-76's TextImage>>scrollUp: did with integer division, so the text
# jumps a line at a time. Deleting `Math.trunc` below, live in the class inspector, makes it smooth,
# as `asFloat` did.
class JobsScrollTextAreaWdgt extends TextAreaWdgt
  # the part of a wheel delta not yet worth a whole line
  _pendingWheelY: 0

  scrolledBy: (xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg) ->
    @_pendingWheelY += yArg
    lines = Math.trunc(@_pendingWheelY / @_wheelUnitsPerLine())
    @_pendingWheelY -= lines * @_wheelUnitsPerLine()
    super xArg, lines * @_wheelUnitsPerLine(), zArg, altKeyArg, buttonArg, buttonsArg
```

- **Unit conversion:** `_wheelUnitsPerLine` converts the text's line height into raw wheel units:
  divide by `wheelScaleY`, and account for `normalizedWheelDeltas`, per S5. Write it as its own small
  method.
- **Why a trackpad:** a mouse notch (about 100 px) is already several lines, so the jumpiness only
  *shows* with a trackpad's small deltas. **Rehearse on the talk laptop's trackpad.**
- **The live edit:**
  1. Change `Math.trunc(@_pendingWheelY / @_wheelUnitsPerLine())` to
     `@_pendingWheelY / @_wheelUnitsPerLine()`.
  2. Lines become fractional, the remainder becomes zero, and every delta passes straight through,
     so the scrolling turns smooth.
- **Content:** the text to scroll is Fizzygum's own `Widget` source,
  `SourceVault.get("Widget")`, 6,209 lines. That is a nice line for the talk: "the text is the
  system's own source".
- **Door:** a demo-menu entry, "Jobs 1979 scrolling", following `createWrappingTextAreaWdgt`.
- **Field rules:** `_pendingWheelY` is per-gesture input state. Read
  `serialization-duplication-reference.md` and declare it a serialization transient if the
  `storage`/`serialization` legs require it.
- **The selection-outline half** of the story is ☆☆. Text selection paint is Theme-role driven, and
  changing it live is not a one-token edit.

**Stage kit:**
1. Create `~/Desktop/talk-2026-11-25/` (D6).
2. Add a `stage/` subfolder with one saved world snapshot per act of §6 ("Save world snapshot…"), so
   that any act can be restarted with "Open from file…" if a demo goes wrong.
3. Re-save the snapshots after the freeze build.

**Tests:** `SystemTest_macroJobsScrollIsLineQuantized`. Open the demo, send N small wheel deltas
through the macro toolkit, and assert with `assertValuesEqual` that the scroll offset is a whole
multiple of the line height. Then apply the edit through the class inspector (as
`SystemTest_macroAnalogClockInspectEdit` does) and assert that the offset follows the deltas exactly.
Take one screenshot of the final state.

**Done when:** the demo works by mouse and by trackpad, the test is green, and `fg presuite` is
green.

### U2. In-world profiler: the Ingalls homage ★ (2 days), with the tracer ☆ (+1.5 days)

**Design.** All of this lives in the lazy `meta-tools` part, so `lean` drops it.

- **`MethodTally`** (the engine).
  - **Size constraint:** `start`/`stop` and the wrapper **fit on one screen**. The talk shows it next
    to Ingalls's original half page (Appendix A).
  - **API:**
    - `start(classes)`;
    - `stop()`;
    - `reset()`;
    - `rows()` → `[{className, memberName, calls, inclusiveMs, selfMs}]`.
  - **Rule 1, what gets wrapped:** every own *function* member of each listed class's prototype,
    except `constructor`. Strings such as `<name>_source` and `<name>_class_injected_in` are skipped.
  - **Rule 2, where the originals live:** in a `Map` keyed `"Class.member"`, **never on the
    prototype**, so inspector member lists do not change.
  - **Rule 3, restoring:** on stop, put the original back **only if `proto[member]` is still our
    wrapper**. A live edit made while profiling has replaced the wrapper, and the edit must win (S1
    proves this).
  - **Rule 4, timing:** use `performance.now()` (doOneCycle's precedent). Do not use `Date.now()`
    (wall-clock stink) or timers.
  - **Rule 5, self time:** keep a shared stack. On entry push a frame; on exit (in `finally`) pop it,
    add the inclusive time to the parent frame's child time, and set self = inclusive − child time.
    `finally` keeps the stack balanced through exceptions.
  - **Rule 6, names:** wrappers get `Object.defineProperty(w, "name", value: member)` so stack traces
    stay readable.
- **`ProfilerWdgt`** (the window).
  - It shows rows as formatted strings in a `ListWdgt`, sorted by inclusive ms, plus Start / Stop /
    Reset controls.
  - It refreshes at `fps: 2` via `step`.
  - Its title names the profiled classes.
  - **Teardown:** destroying the window **stops profiling**. Also verify that `resetWorld` (the
    world-dissolution path in `world-lifetime-and-inventory.md`) destroys it, or that the profiler
    unwraps itself on dissolution. **A wrapper must never outlive its world**, or it leaks into the
    next SystemTest.
- **Doors** (Dev tools submenu, `MenusHelper.popUpDevToolsMenu`):
  - **"Profile this class"** profiles the subject widget's own class.
  - **"Profile class + superclasses"** profiles the class chain up to, and excluding, `Widget`. The
    `Widget` methods run thousands of times per cycle, so they are opt-in.
  - Door shape: `spawnInspector`'s pattern.
- **Stage line:** "Ingalls did this in half a page in 2008, with millisecond `Date`s. Ours is one
  screen, with sub-millisecond `performance.now`. It is attributed through mixins, and it needs no
  DevTools."

**Tracer ☆ ("Trace next cycle"), U2b:**
- **Mechanism:** the same wrappers, recording a call tree for exactly one world cycle. Arm it, and
  the next `doOneCycle` runs traced.
- **Display:** a MessageTally-style indented list (`ticks %` and `Class>>member`), pruned at 1%, with
  a leaf self-time list below, like `lively.Tracing`.
- **Deterministic replay beat:** on the harness page, trace a cycle in the middle of an existing
  SystemTest. The SystemTest replays identical input every run, which Lively had no way to do.

**Tests:** `SystemTest_macroProfilerCountsClockSteps`.
1. Open a clock, profile it, and let N world cycles run.
2. Assert with `assertValuesEqual` that the `step` call count equals the expected tick count. The
   virtual clock makes this deterministic; derive N from `fps: 1` and the cycle clock, reading
   `DETERMINISM.md` first.
3. Stop, and assert that `AnalogClockWdgt.prototype.step` is the original function again.
4. **Take no screenshot of the profiler window**, because its milliseconds are wall-clock.

Also update `menusweep`: the new rows must run headless, start and stop cleanly, and leave nothing
wrapped. If one cannot, add a `SKIP` entry with its reason.

**Done when:**
- profiling a clock while dragging it shows live counts;
- stop restores every prototype;
- tests, menusweep and `fg presuite` are green.

### U3. The explorer: pane, view builder, default views ★ (3 days)

**Classes** (lazy `meta-tools` unless noted):

- **`ExplorerViewSpec`** (**core**, `src/basic-data-structures/`; a ~30-line record modelled on
  `PinSpec`).
  - Shape: `new ExplorerViewSpec "Storyboard", build: "explorerViewStoryboard", priority: 20`.
  - The title is positional. `build` names a method of the subject, which receives the view builder.
    `priority` orders the views.
  - It must be in core because any part (harness, fizzylogo) may declare views, and core is always
    present; that keeps part edges clean.
  - Its constructor refuses a spec without `build`.
- **The declaration hook:** `explorerViews: -> super().concat [ … ]` on any class that wants
  domain views. The base declaration is `explorerViews: -> []`, on the class that roots each family.
  - **Do not add it to `Widget`.** Widget-level views are *defaults* that the pane computes (below).
  - A class that declares views adds one member to its own inspector list; accept
    `fg recapture-inspector` churn only for classes that an inspector test inspects.
- **`ObjectExplorerViewBuilder`:** the `aView` handed to `build` methods (GT's `aView`). It has the
  smallest API the views below need:
  - `list(items, label: fn, drill: fn)` builds a `ListWdgt` of label strings. `drill(item)` returns
    the object for the next pane, or `undefined` to drill nothing.
  - `text(string)` gives read-only text.
  - `widget(w)` embeds a widget it was handed. It must be a *new* widget: a widget has one parent,
    so never embed the subject itself.
  - `image(canvasOrImage)`.
  - `pending(promise, thenBuild)` shows "loading…" and builds when the promise resolves, for views
    whose data loads lazily (U6).
  - Every `build` method returns what the builder returns.
- **`ObjectExplorerPaneWdgt`:** one pane per subject.
  - **Title strip:** the subject's `colloquialName?()` or class name, plus its class, in Smalltalk
    style ("an AnalogClockWdgt").
  - **View chooser:** one button per view, in priority order.
  - **Body:** the selected view.
  - **The view list:** `@_viewsFor(subject)` = defaults by capability, followed by
    `subject.explorerViews?() ? []`. One list, composed the way `Widget.pins` concatenates the
    appearance's pins.
  - **Missing build methods:** if a spec names a method the subject lacks, show a visible error row
    and do not silently skip it (the pinsweep lesson). A runtime "viewsweep" gate is ☆☆.
  - **Drilling:** a `drill` opens the next pane per D3 (windows that line up: `world.openFrameWith`
    to the right of the parent's frame, same top and height).
  - **Layout:** this is the riskiest new code in the plan. Mirror `InspectorWdgt._reLayout` /
    `_bandsIn` (bands top to bottom). Read `layout.md` and `widget-authoring-guidelines.md` first, and
    use Theme roles for every colour.
- **Default views** (meta-tools, chosen by *capability*, never `instanceof`, which is the stink
  ratchet):

| Subject (capability test) | Views |
|---|---|
| any widget (`subject.pins?`) | **Members**: an embedded `new InspectorWdgt(subject)`, the existing inspector, editing included. **Picture**: `subject.fullImage()`. **Children**: list, drill → child. **Pins**: one row per `pins()` entry (label · kinds · set/get · announces). **Class**: drill → the class meta-object |
| class meta-object (`subject.nonStaticPropertiesSources?`) | U4's views |
| Array | **Items** (index · preview, drill → element) |
| plain object | **Items** (key · preview, drill → value) |
| string | **Text** |

- **Door:** Dev tools → **"Explore"**. The door targets `world`, not `Widget`; follow the comment at
  the "Test menu" row. It awaits `meta-tools` and `ensureReflectiveLayerLoaded()` like
  `spawnInspector`.

**Tests:**
- `SystemTest_macroExploreWidgetDrillsToChild`: explore a window, Children view, drill, and the new
  pane opens to the right. Screenshots.
- `SystemTest_macroExploreMembersViewEdits`: the Members view edits a method like the inspector does.

**Done when:** the views above work for a clock, a window and a plain object, the tests are green, and
`fg presuite` is green.

**Pager ☆ (`ObjectExplorerWdgt`):** a horizontal strip of panes in one frame. A drill replaces the
panes to the right, and a pane's title strip can be dragged out into a window. Only after U4–U6.

### U4. Smalltalk-style organisation: class views, protocols, senders/implementors ★ (2 days)

**`Class.coffee` changes** (core; small; S4 proves the parser path):
1. Keep the header comment: `@classComment`.
2. While walking members, keep a running `currentProtocol`. A `propertyComment` containing a line
   matching `/^  # protocol: (.+)$/m` sets it, and each member gets
   `@memberProtocols[name] = currentProtocol` when one is set.
3. ☆ Keep `@memberComments[name] = propertyComment`, the method comment Smalltalk shows above a
   method's source.

The build-time syntax gate loads this file in Node. Re-read the file's top comment about the shim
before adding any global.

**`ProtocolInference`** (meta-tools):
- an ordered rule list (Appendix D, refined);
- names are normalised first: strip a leading `_` and a trailing `NoSettle`;
- the fallback is **"as yet unclassified"**;
- **privacy is not a protocol.** `_` members get a "private" *badge*. On `Widget` they are 148 of 453
  members, and a "private" protocol would hide their real topic.

**Class views** (the defaults for a class meta-object):

| View | Content |
|---|---|
| **Comment** | `classComment` (the class's header) |
| **Protocols** | protocol · method count, with written ones in ink and inferred ones dimmed, then the computed groups: *overrides* (also defined up the chain), *from mixins* (`augmentedWith`), *edited this session* (`world.sourceEditsRegistry.records` for this class). Drill → a protocol group → **Methods** list → drill → a method |
| **Hierarchy** | superclasses (base first), then `subClasses` (a `Set`); drill → class |
| **Instances** | `window[name].instances` (widgets only); drill → instance |
| **Edits** | this class's `SourceEditsRegistry` records (the ChangeSet view) |

**Method objects** (`MethodRef {className, memberName}`, meta-tools):

| View | Content |
|---|---|
| **Source** | An embedded `ClassInspectorWdgt` on the class, with that member selected. Construct it the way `InspectorWdgt.openClassInspector` does, then `selectionFromList memberName`. So saving uses the existing edit path (`applyMemberEdit` + `recordClassEdit` + `notifyInstancesOfSourceChange`) |
| **Senders** | Every member, across `SourceVault.names()` → class/mixin member sources, whose body references the name. Mirror `buildSystem/lib/method-references.js`: a property access `@m` / `.m` and a whole-name string `"m"` count, while a bare word or a comment does not. Rows read Smalltalk-style, `AnalogClockWdgt>>step`; drill → MethodRef |
| **Implementors** | Classes whose `nonStaticPropertiesSources` has the name, plus mixins (`Mixin.allMixines`) |

**Query lists** (the owner's "browsers are just lists" note, Appendix C):
- `SourceQueries` returns `QueryResult {title, items}` objects, which explore as lists.
- ★: senders, implementors, instances, hierarchy.
- ☆: subclasses of, users of a mixin, longest methods (by line count), methods calling `super`.
- **Footer row:** if any lazy part is not loaded, a "N parts not loaded" row whose action loads them
  all (`world.parts.whenAllLoaded`). Searches see only stored sources (§1.1).

**Markers for the talk:** write `# protocol:` markers by hand in the classes shown on stage:
`AnalogClockWdgt`, `PenWdgt`, `JobsScrollTextAreaWdgt`, `MethodTally`, `ProfilerWdgt`. Use Pharo's
vocabulary where it fits (Appendix D). Markers are comments, so there is no pixel churn. Leave
`Widget` inferred.

**Packages and categories ☆:** part = package and folder = class category. Show "Package: meta-tools ·
Category: src/meta-tools" in the class Comment view.
- The part is the vault entry's `part` tag.
- The folder needs build data: emit `window.FIZZYGUM_CLASS_FOLDERS = {ClassName: "src/…"}` next to
  the parts manifest (`build.py`, where `partsManifest.coffee` is written).
- Moving the 101 root-level `src/` classes into folders is ☆☆ (§9).

**Tests:**
- `SystemTest_macroExploreClassProtocols`: explore the clock's class, check that Protocols shows the
  written markers and an inferred row, drill to a method's Source. Screenshot.
- `SystemTest_macroExploreSendersOfStep`: assert the senders count with `assertValuesEqual`, and
  check that the first rows show `Class>>member`.

**Done when:** a Smalltalker can go class → protocol → method → senders → method entirely in
explorer panes.

### U5. Fizzylogo inside Fizzygum ★ (2 days)

**Vendoring:**
1. Build `vendor/fizzylogo/fizzylogo.js` from `~/code/Fizzylogo` with the README's yielding command,
   excluding tests (Appendix B).
2. Record the commit in `vendor/fizzylogo.pin`.
3. Check that the output does *not* end in the test loop and does contain `function*`.

**Part:** in `parts.json`, add `"fizzylogo": {"dirs": ["src/fizzylogo"], "eager": false, "requires":
["app-kit"], "vendor": [{"out": "js/vendor-parts/fizzylogo.js", "concat":
["vendor/fizzylogo/fizzylogo.js"]}]}`.
- Write its `//` comments in the house style; read the `fizzytiles` entry.
- Drop `requires` if the door is not a `WindowedApp`.
- Teach `PartsRegistry._vendorAlreadyPresent` the new payload (`window.Fizzylogo?`).
- The `homepage` profile does not name it, so it ships in dev only.

**Classes** (`src/fizzylogo/`):

- **`FizzylogoTurtleCanvasAdapter`:** a plain object passed to `Fizzylogo.init` as the canvas. Its
  members are what Fizzylogo actually touches (Appendix B):
  - `clientWidth` / `clientHeight` give the canvas widget's size;
  - `getContext("2d")` returns a context adapter. Its `scale` does nothing, `beginPath`/`moveTo`
    record a start point, and `lineTo` records an end point.
  - `stroke()` calls the canvas widget's `drawLine(start, end, lineWidth, color)`, in the canvas's
    logical pixels. The colour comes from a Theme role, never a literal.
- **`FizzylogoWorkspaceWdgt`:** code text, Run / Stop, an output text, and a `CanvasWdgt` for the
  turtle.
  - **Run:**
    1. `Fizzylogo.init(outputShim, adapter, 1)`, where `outputShim` is `{value: ""}`;
    2. `@_gen = Fizzylogo.runOneStep(code)`;
    3. add itself to `world.steppingWdgts` with `fps: 0`.
  - **`step`:** up to BATCH `@_gen.next()` calls per cycle (start with 200; tune for a smooth turtle),
    then copy `outputShim.value` into the output text. When `done`, leave the stepping set.
  - **Stop:** leave the stepping set and drop the generator.
  - **No `setTimeout`** (timer stink, determinism).
  - **Limitation, stated in its header:** the interpreter is a module-level singleton (`rWorkspace`,
    `outerMostContext`, `mainTurtle`, the canvas). One workspace runs at a time, and Run re-binds it.
- **The door:** a `FizzylogoApp` door if `WindowedApp` fits (read `app-fit-criteria.md` and
  `FridgeMagnetsApp`). Otherwise a Dev tools / demo-menu row that opens the workspace in a frame.

**Stage demos** (Appendix B has the code):
1. `2+3`;
2. **redefine `+`** to print its operands. It needs `Number answer with priority 4:` or precedence
   changes;
3. the **five-point star** with the turtle;
4. the same, **in a rotated window** (`setRotationDegrees` on the frame) while it draws;
5. a `repeat forever:` program that keeps drawing while the world stays live.

**FL object views ☆:**
- Fizzylogo exports only `Fizzylogo` (`init`, `runOneStep`). Exploring its objects needs an accessor
  export, e.g. `Fizzylogo.outerMostContext = -> outerMostContext`.
- That is a change in the owner's Fizzylogo repo, **so ask first**. Then add an explorer wrapper
  object declaring `explorerViews` (temps of a context, methods/matchers of a class), after reading
  `fizzylogo_Context.coffee` and `fizzylogo_Classes.coffee`.

**Single-step debugger ☆☆:** a Step button that calls `next()` once and shows the state.

**Tests:** `SystemTest_macroFizzylogoDrawsStar`. Open the workspace, type the star program through the
macro toolkit, Run, wait until done, and take a screenshot of the canvas. It is deterministic because
`drawLine` on SWCanvas is deterministic and stepping is per cycle.

**Done when:** the star, the redefinition of `+` and the rotated window all work, and the test and
`fg presuite` are green.

### U6. Domains: the moldable payoff

**U6a. The SystemTest suite as a domain ★ (1.5 days).**

- **Classes** (harness part, `Fizzygum/src/macros/` so the commit stays in one repo; it is the part
  that owns test machinery):
  - **`SystemTestCatalog`** `{names}`: views **Tests** (list, drill → entry) and ☆ **By tag**.
  - **`SystemTestEntry`** `{name}`:
    - **About:** `pending(loadJSFilePromise "js/tests/<name>/<name>.js")`, then the description,
      intent, scenario, assertions, provenance and tags;
    - **Storyboard:** the dpr-1, mouse (non-`finger`), SWCanvas reference images for this test, from
      `Automator.testsAssetsManifest`, loaded **as the `.js` wrappers** per S6. Never load the
      `.png` straight over `file://` (taint);
    - **Macro:** the macro source text, located per S6.
- **Door:** Dev tools → "System tests", offered only if `world.parts.isAvailable "harness"` and the
  manifests exist (S6).
- **"Run" is ☆, harness page only, with a warning row.** Running a test resets the world, so never
  offer it on `index.html`.

**U6b. Files and email ☆ (2 days).** This is the owner's "browse the filesystem, read email" ask, done
honestly under `file://`.
- **Door:** "Open folder…" opens a hidden `<input type=file webkitdirectory multiple>`, in the same
  style as `FileLoading`'s hidden input.
- **Data:** the `File` list with its `webkitRelativePath` becomes an in-memory `FolderNode` tree.
- **Views:**
  - Folder **Items**: name · size; drill → file or folder.
  - File **Text** (FileReader).
  - **JSON** (parse → Items).
  - **Picture**: `readAsDataURL`, never a `file:` URL.
  - **Messages** for `.mbox`: split on `/^From /m` and parse the headers; rows read "date · from ·
    subject"; drill → **Headers** / **Body**.
- **GT has no email inspector**, so this is new. Squeak once shipped Celeste, a mail client.
- **⚠ For the talk, use a synthetic demo `.mbox`** with fictional people, kept in D6's folder. **Never
  show real mail.**
- The menusweep must SKIP "Open folder…", with the reason: a headless file picker never resolves.

**U6c. Dropping non-Fizzygum files ☆☆.** Make `FileLoading.loadFile` open non-`fzw` files in the
explorer instead of rejecting them.

### U7. The deck ☆ (1 day, owner-heavy)

Giving the talk from Fizzygum's own Slides app (`SimpleSlideApp`) echoes Ingalls presenting from
inside Lively at JSConf 2012. The owner decides. The fallback is external slides, with the demos in a
browser window. If it is built, save it as a snapshot in D6's folder.

### U8. Freeze and rehearsal ★

1. **Freeze day:**
   1. `fg gauntlet` green.
   2. Get push approval.
   3. **Copy `Fizzygum-builds/latest/` to `~/Desktop/talk-2026-11-25/build/`.** `latest/` is
      overwritten by every build, and the talk must run a pinned copy. Copy with `cp -RL` so the tests
      symlink becomes real files, and **never** `rm` the source link.
2. Re-save the stage snapshots from the pinned build.
3. Rehearse §6 twice on the talk laptop, at the projector's resolution if known, with a trackpad.
   Note the timings.
4. Rehearse once from `index-sw.html` too. It loads every part eagerly, so senders searches see all
   sources; pick the page that looks and performs best.
5. After the freeze, bug fixes only, each one followed by `fg presuite`.

---

## 5. Schedule

### 5.1 Calendar (start the day after the blocking arc is committed)

| Date (2026) | Units | Gate at end |
|---|---|---|
| Mon 11-09 | U0 spikes; U1 Jobs + stage kit | presuite |
| Tue 11-10 – Wed 11-11 | U2 profiler (U2b if ahead) | presuite |
| Thu 11-12 – Sat 11-14 | U3 explorer | presuite |
| Sun 11-15 – Mon 11-16 | U4 protocols, senders, implementors | presuite + **gauntlet** (midpoint) |
| Tue 11-17 – Wed 11-18 | U5 Fizzylogo | presuite |
| Thu 11-19 – Fri 11-20 | U6a test suite domain (U6b if ahead) | presuite |
| **Sat 11-21** | **FREEZE**: U8 step 1 | **gauntlet**, push approval, pinned build |
| Sun 11-22 – Tue 11-24 | U7 deck (if chosen), rehearsals, bug fixes | presuite per fix |
| **Wed 11-25** | **Talk** | |

### 5.2 Cut order when behind (cut from the top)

1. U6c, U6b (files/email), U4's ☆ query lists, the pager.
2. U2b tracer.
3. U7 deck (use external slides).
4. U6a's Storyboard view (keep About).
5. U4's senders/implementors. Keep Comment, Protocols and Hierarchy.

Never cut: U1, U2, U3's pane with Members/Children/Class, U5's star and redefinition of `+`, and the
freeze gauntlet.

---

## 6. The 45-minute running order

Each act has a snapshot in `stage/` to restart from. Times are targets.

| Min | Act | What happens on screen | Built by |
|---|---|---|---|
| 0–3 | **Lineage** | Smalltalk-80 → Squeak Morphic (Maloney) → Lively (Ingalls) → Morphic.js / Snap! (Mönig) → Zombie Kernel → Fizzygum. Shown in Fizzygum Slides or external slides | U7/none |
| 3–7 | **Jobs, 1979** | Tell the story, scroll Fizzygum's own source with the trackpad (jumpy), open the class inspector, delete `Math.trunc`, Save, and it is smooth | U1 |
| 7–12 | **Lively's clock** | Create a clock, inspect `drawSecondsHand`, negate the angle, and it runs backwards. Rotate its window while it ticks. Save a world snapshot, reload the page, open the file, and the edit is replayed (the ChangeSet: `SourceEditsRegistry`) | exists |
| 12–16 | **Wiring (Fabrik, Lively `connect`)** | A slider drives a widget's pin; a calculating patch node in between | exists |
| 16–20 | **The system edits itself** | Inspect an inspector, change its code live. Throw an error from the demo menu, and the error console appears. (Optional S3 beat: fix a failing `step` and watch it heal) | exists (+S3) |
| 20–26 | **Smalltalk organisation** | Explore the clock's class: Comment, Protocols (written vs inferred, "as yet unclassified"), Hierarchy, then `step` → Senders → `Class>>member` → Source → edit | U3, U4 |
| 26–32 | **One inspector, many worlds** | The same explorer on the 373-test suite (About, Storyboard), (☆) on a folder and a demo mailbox, on an array or a plain object | U3, U6 |
| 32–37 | **Instrumenting from inside** | "Profile this class" on a list or clock, drag it and watch the counts grow. Show `MethodTally`'s one screen next to Ingalls's 2008 half page. (☆) Trace one cycle | U2 |
| 37–42 | **Smalltalk-72's grandchild** | A Fizzylogo workspace: `2+3`, redefine `+`, the turtle star, the same in a rotated window, `repeat forever` drawing while the world stays live | U5 |
| 42–45 | **Close** | `file://`, no server; 373 deterministic tests in Chrome and WebKit; what's next (pager, Smalltalk-78 or SqueakJS in a window). Questions | – |

---

## 7. Central risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | Another arc is uncommitted in the same tree | §0.5 step 1: stop and ask |
| R2 | The explorer pane's layout trips settle, paint or capstone gates | Mirror `InspectorWdgt`'s band layout. Windows mode first (D3). Build the pane alone and run presuite before any drilling |
| R3 | Profiler wrappers outlive the world and leak into the next test | Teardown stops profiling, plus an unwrap on world dissolution. The test asserts prototypes are restored. The `vmtruth`/`revisits` legs catch leaks |
| R4 | Live edits while profiling | Restore-by-identity rule (U2 rule 3), proven in S1 |
| R5 | Recapture churn | Inspector member lists (`fg recapture-inspector`, owner-sanctioned); the one test touching the "Dev" menu; any demo-menu screenshot. Look at each diff first |
| R6 | menusweep fires the new rows headless | Each new row is idempotent and cleans up, or gets a `SKIP` entry with its reason |
| R7 | Fizzylogo's global singleton; its published dist runs its tests at load | One workspace at a time; rebuild without tests (Appendix B) |
| R8 | Wrapping overhead skews timings (the observer effect) | Say so on stage; counts are exact, milliseconds are indicative |
| R9 | Reference images taint a canvas over `file://` | Load the `.js` wrappers (§0.3 item 7, S6) |
| R10 | `latest/` is overwritten after the freeze | Pinned copy (U8) |
| R11 | `performance.now()` is coarsened (Chrome isolates high-resolution time without cross-origin isolation; Safari is coarser) | S1 measures it. Inclusive time over many calls is still meaningful |

---

## 8. Verification protocol

- **Inner loop per unit:** `/Users/davidedellacasa/code/Fizzygum-all/fg presuite > /tmp/fg-presuite-run.log 2>&1`
  in the background, then `cat /tmp/fg-presuite.verdict`.
- **One test:** `fg suite --tests=SystemTest_macro<Name>`. Check `fg` with no arguments for the
  current flags.
- **Recapture after a deliberate visual change:** build first, then
  `fg recapture --auto` / `fg recapture-inspector`. Look at each diff.
- **Midpoint and freeze:** `fg gauntlet > /tmp/fg-gauntlet-run.log 2>&1` (about 15 min, background).
- **Proving a regression test bites:** plant the bug through `PRELUDE_JS` and watch the test fail
  (memory: bite-proofs). Do this at least for the profiler-restore assertion.
- **Never** pipe a gating `fg` call through `tail`/`grep`.

---

## 9. Rejected alternatives (do not re-attempt)

| Alternative | Why rejected |
|---|---|
| In-world profiling through Chrome DevTools/CDP | The owner rules out servers and DevTools ("I like Fizzygum to be able to work from filesystem"). The CDP harness in `docs/profiling/` stays an offline tool |
| Sampling profiler through the JS Self-Profiling API | It needs a `Document-Policy: js-profiling` response header, which a `file://` page cannot send |
| Rewriting `InspectorWdgt` into the moldable shell before the talk | 16 tests' flows and references change, for no stage gain. Embed it as the Members view instead |
| Views discovered by name prefix (`explorerView*`) | Loses explicit order and subclass narrowing. The house mechanism is the composed list (pins) |
| "private" as a protocol for `_` members | 148 of Widget's 453 members would land there, hiding their topic. Privacy is a badge |
| Reordering `Widget` into protocol sections now | A huge diff against member-order constraints, with no demo value |
| Driving Fizzylogo with `setTimeout` (as its sandbox page does) | The `timer` stink, and determinism. Use world stepping |
| Pointing `<img>` at reference `.png`s over `file://` | Canvas taint breaks pixel reads. Use the `.js` wrappers |
| Showing real email in the talk | Privacy. Use a synthetic mbox |
| Embedding a Smalltalk-78 VM or SqueakJS for this talk | Image bytes must ride `file://`, the licence and availability of a Smalltalk-78 VM are unchecked, and it does not fit the time. Post-talk ☆☆ |
| Moving the 101 root-level `src/` classes into folders now | Churn with no demo value. Post-talk |
| Switching "Inspect" to the explorer before the talk | Changes 16 tests' flows. Post-talk owner decision |

---

## 10. After the talk (☆☆, not part of this plan's done-ness)

- Pager container plus tear-off.
- The viewsweep runtime gate.
- A stink ratchet for "as yet unclassified" methods, plus marking `Widget`.
- The "make button" from a method pane (owner note: "wherever you have *do it*, have *make button*").
- Uniform verbs across package / class / protocol / method (new, cut, copy, paste, delete, duplicate,
  move; owner note).
- Inline rename in member lists.
- The Fizzylogo stepping debugger.
- Dropping non-Fizzygum files into the explorer (U6c).
- SqueakJS or Smalltalk-78 in a window.
- Making "Inspect" open the explorer.
- File these in `docs/BACKLOG.md` at the end of the arc.

---

## 11. References

**In-repo:**
- `docs/architecture/lint-and-static-checks.md`
- `build-and-packaging.md`
- `widget-authoring-guidelines.md`
- `layout.md`
- `visual-design-system.md`
- `world-lifetime-and-inventory.md`
- `serialization-duplication-reference.md` (§12 covers `SourceEditsRegistry`)
- `constructor-and-parameter-conventions.md`
- `app-fit-criteria.md`
- `Fizzygum-tests/DETERMINISM.md`
- `docs/profiling/README.md` (the offline CDP harness)
- `docs/archive/inspector-read-only-subjects-plan.md` (the last inspector arc)

**Memory** (`~/.claude/projects/-Users-davidedellacasa-code-Fizzygum-all/memory/`):
- ask-before-commit-push
- byte-identical-not-sacred-for-benign-inspector-recapture
- clean-minimal-uniform-architecture
- plans-must-be-fully-self-contained
- bite-proofs
- macro test system

**Owner's design notes** (`~/Desktop/notes/notes-vault/`; excerpts in Appendix C):
- `Potentially-new-meaning-of-inspector-browser-in-Fizzygum-compared-to-Smalltalk.md`
- `Object-Class-inspector-with-source-code-awareness-no-mixins.md`
- `these-buttons-should-work-across-packages-classes-method-families-methods.md`
- `wherever-you-have-do-it-menu-entry-you-should-have-make-button-and.md`
- `Smalltalk-Browsers-as-general-data-handling-paradigm-make-your-custom-browsers.md`
- `ZombieKernel-and-inspecting-objects-as-if-they-were-remote-filesystems.md`
- `Dan-Ingalls-showing-wrapping-of-debug-profiling-functions-around-parts-of-Lively-kernel.md`
- `smooth-scrolling-modification-demo-by-using-Smalltalk-78.md`
- `GTInspector-Pharo-inspector.md`

**External** (each verified during the 2026-11-07 research pass):
- **Lively Kernel:**
  - Lively S3 paper (clock live edit, half-page profiler, per-world change list):
    https://lively-kernel.org/repository/webwerkstatt2011/draft/NewWorld/LivelyS3.pdf
  - Google Tech Talk, 2008: https://rosetta.to/u/googletechtalks/the-lively-kernel
  - "A World of Active Objects… The First Ten Years of Lively" (Onward! 2016):
    https://www.hpi.uni-potsdam.de/swa/publications/media/IngallsFelgentreffHirschfeldKrahnLinckeRoederTaivalsaariMikkonen_2016_AWorldOfActiveObjectsForWorkAndPlayTheFirstTenYearsOfLively_AuthorsVersion.pdf
  - Lively Fabrik (2009):
    https://www.hpi.uni-potsdam.de/swa/publications/media/LinckeKrahnIngallsHirschfeld_2009_LivelyFabrik-AWebBasedEndUserProgrammingEnvironment_IEEE.pdf
  - `lively.Tracing`: https://github.com/LivelyKernel/LivelyKernel/blob/master/core/lively/Tracing.js
    and https://lively-kernel.org/repository/webwerkstatt/documentation/Tracing.xhtml
  - The local old Lively checkout: `~/code/lively-kerner-old/kernel/lively/Tools.js`
    (`Object.profiler`)
- **Squeak and Smalltalk history:**
  - HOPL-IV "The Evolution of Smalltalk" (Ingalls 2020; the Jobs demo):
    https://smalltalkzoo.computerhistory.org/papers/EvolutionOfSmalltalk.pdf
  - Smalltalk Zoo: https://smalltalkzoo.computerhistory.org/
  - SqueakJS: https://smalltalkzoo.computerhistory.org/users/bert/SqueakJS/run/index.html
- **Moldable tools:**
  - Moldable Inspector paper: https://scg.unibe.ch/archive/papers/Chis15a-MoldableInspector.pdf
  - GT `FileReference` views:
    https://github.com/feenkcom/gtoolkit-inspector/blob/main/src/GToolkit-Inspector/AbstractFileReference.extension.st
  - Pharo `MethodClassifier`:
    https://github.com/pharo-project/pharo/blob/Pharo15/src/Tool-Base/MethodClassifier.class.st
  - Pharo `Morph` protocols:
    https://github.com/pharo-project/pharo/blob/Pharo15/src/Morphic-Core/Morph.class.st
- **Fizzylogo:** https://github.com/davidedc/Fizzylogo (MIT, CoffeeScript 2.3.2)

---

## 12. Background: famous Lively and Squeak demos, with Fizzygum status

Effort scale: ✅ exists · S ≤ 1 day · M 2–5 days · L more. This is context for choosing beats, not a
work list.

| Demo | Origin | Fizzygum |
|---|---|---|
| Clock edited live to run backwards, still ticking when rotated | Lively 2008 | ✅ |
| Jobs 1979 smooth scrolling | Smalltalk-76 | U1 (S) |
| Inspector edits itself | Lively and Smalltalk | ✅ |
| World saved with its code edits (change list) | Lively S3 paper | ✅ `SourceEditsRegistry` |
| `connect` bindings and Fabrik | Lively, Fabrik 1988 | ✅ pins, wires, patch nodes |
| Wrapping profiler, MessageTally tracer | Lively 2008 / 2012 | U2 |
| Moldable views (GT) | Pharo/GT | U3–U6 |
| Turtle and pen drawing | Blue Book, Logo | ✅ `PenWdgt`; U5 for Fizzylogo |
| BouncingAtoms | Squeak | ✅ `BouncerWdgt` (infection rule: S) |
| Radial engine (odd cylinder count) | Lively 2008 | M, not planned |
| Asteroids | Lively 2008 | M, not planned |
| Etoys car and steering wheel | Squeak Etoys | M, not planned |
| Full halo ring | Squeak | partial (move, resize, rotate); G2 halo feel-check owner-pending |
| PartsBin | Lively | M, not planned |
| Projects (nested worlds) | Squeak | M–L, not planned |
| SqueakJS or Smalltalk-78 in a window | Ingalls, Freudenberg | M–L, post-talk |
| Lively-to-Lively, weather and stock widgets | Lively | ✗ (server-bound; `file://` stance) |

---

## Appendix A. Ingalls's profiler, verbatim

From `~/code/lively-kerner-old/kernel/lively/Tools.js`, the 2008-era Lively Kernel:

```js
Object.profiler = function (object, service) {
    // The wondrous Ingalls profiler...
    // Invoke as, eg, Object.profiler(Color, "start"), or Object.profiler(Color.prototype, "start")
    var stats = {};
    var fnames = object.constructor.localFunctionNames();
    for (var i = 0; i < fnames.length; i++) {
        var fname = fnames[i];
        if (fname == "constructor") {} // leave the constructor alone
        else if (service == "stop")
            object[fname] = object[fname].originalFunction;  // restore original functions
        else if (service == "tallies")
            stats[fname] = object[fname].tally;  // collect the tallies
        else if (service == "ticks")
            stats[fname] = object[fname].ticks;  // collect the real-time ticks
        else if (service == "reset") {
            object[fname].tally = 0; object[fname].ticks = 0; // reset the stats
        } else if (service == "start") { // Make a proxy function object that just calls the original
            var tallyFunc = function () {
                var tallyFunc = arguments.callee;
                tallyFunc.tally++;
                msTime = new Date().getTime();
                var result = tallyFunc.originalFunction.apply(this, arguments);
                tallyFunc.ticks += (new Date().getTime() - msTime);
                return result;
            }
            if (object[fname].tally == null)
                tallyFunc.originalFunction = object[fname];
            else
                tallyFunc = object[fname]; // So repeated "start" will work as "reset"
            tallyFunc.tally = 0;
            tallyFunc.ticks = 0;
            object[fname] = tallyFunc;
        }
    }
    return stats;
};
```

Differences in U2's `MethodTally`:
- originals live in a Map, not on the function;
- restore is by identity;
- self time comes from a stack;
- `performance.now()`;
- `try/finally`;
- mixin-donated members are covered because they are copied onto the prototype.

## Appendix B. Fizzylogo facts (verified 2026-11-07 against GitHub `davidedc/Fizzylogo`, last push 2018-12)

- **About 40 sources**, `fizzylogo_*.coffee`, concatenated in the order of `sourceFilesOrder.txt`.
  `fizzylogo_coda.coffee` defines the API.
- **The yielding build:** `makeYieldingVersion.sh` turns `# yield` / `# yield from` comment tags into
  real `yield` / `yield from`.
  - The README's browser build is: `sh makeYieldingVersion.sh; cd yielding-version; cat $(grep -v
    '^tests' sourceFilesOrder.txt) | coffee --stdio -c > ../dist/fizzylogo.js`.
  - It needs `npm install` first (`coffeescript`, `replace`).
  - Local `coffee` is 2.7.0, which should compile CoffeeScript 2.3.2 code; S2 confirms.
- **The published `dist/fizzylogo.js` (290,283 B) contains 120 `yield`s and ends by running the
  tests.** Rebuild it; do not vendor it as published.
- **The output is an IIFE** that exports only `Fizzylogo`
  (`(exports ? this).Fizzylogo = Fizzylogo`).
- **API:**
  - `Fizzylogo.init(textOutElem, canvasOutElem, devPixRatio)`: `textOutElem.value +=` receives
    output and errors; it calls `canvasOutElem.getContext('2d').scale(dpr, dpr)`, then `reset()`.
  - `Fizzylogo.runOneStep(code)`: a **generator**; drive it with `gen.next()` until `.done`. The
    sandbox page (`sandbox/sandbox.htm`) runs batches with `setTimeout(…, 0)`; Fizzygum uses world
    stepping instead.
- **Turtle** (`fizzylogo_Turtle.coffee` and the Turtle section of `fizzylogo_populateMethods.coffee`):
  - state: `x`, `y`, `direction` (degrees, 0 = up), `penDown`;
  - `home` (centre, via `canvasOutputElement.clientWidth/2`, `clientHeight/2`);
  - `forward ( distance )`: `getContext("2d")`, `strokeStyle = "#000"`, `lineWidth = 1`,
    `beginPath`, `moveTo`, `lineTo`, `stroke`;
  - `right ( degrees )` / `left ( degrees )`.
- **Programs** (from the repo's own sandbox and tests):

```
for each n in:
    0...5
  do:
    turtle forward 50
    turtle right 144
```

```
console print 2+3
Number answer with priority 4:
  + (operandum)
 by:
  console print self
  console print "+"
  console print operandum
2+3
Number answer with priority 4:
  + (operandum)
 by:
  self $plus_binary_default operandum
```

  - The second program redefines `+`, uses it, then restores it. The tests write indentation with a
    `﹍` marker; check the exact indentation against `tests.coffee` in S2.
  - `repeat forever:` with `if … : done else: …` is in the tests around "repeat forever".
  - Operator precedence differs from Smalltalk-72's; read the header comment of `tests.coffee`
    before saying anything about it on stage.

## Appendix C. The owner's design notes (excerpts that shape U3 and U4)

- **"Potentially new meaning of inspector/browser"** (2019):
  - Inspectors pin down a class or an object, show its contents and let you edit it.
  - "Browsers" are *just lists*: a hierarchy, all classes extending a class, all places invoking a
    method, all implementors, all classes using a mixin, all methods longer than x, classes or
    methods by cognitive complexity, all methods invoking `super`, all classes in a category, all
    instances of a class.
  - Clicking an item opens the related inspector, or the list becomes an extra first pane.
  - U4's `QueryResult` lists are exactly this.
- **"these buttons should work across packages/classes/method families/methods":** new, cut, copy,
  paste, delete, duplicate, move.
- **"wherever you have the 'do it' menu entry, you should have a 'make button'":** a clickable
  shortcut of any command.
- **Owner, 2026-11-07:**
  - Creating or renaming packages, classes and methods is "quite clunky" in Smalltalk/Lively, so
    don't copy those flows.
  - Wants a generic inspector specialised per object, Pharo-style, that can also read email, browse
    the filesystem, browse resources and documentation.
  - No DevTools servers: Fizzygum works from the filesystem.

## Appendix D. Protocol vocabulary and the inference spike

**Pharo names to reuse** (from `MethodClassifier` and Pharo's `Morph`): instance creation,
initialization, accessing, testing, printing, converting, comparing, copying, geometry, layout,
drawing, event handling, stepping, menus, and **as yet unclassified**.

**Fizzygum additions:**
- pins & dataflow;
- serialization & copying;
- structure (the widget tree);
- invalidation;
- gestures, separate from raw input events (the input-vocabulary tiers; read `input-and-gestures.md`);
- lifecycle;
- editing (text/caret).

**The 2026-11-07 spike**, re-runnable, over the members of `src/**/*.coffee` defined as
`^  name: (…) ->` or `=>`:
- **Normalisation:** strip a leading `_`.
- **First matching rule wins:**
  1. `^constructor$` → instance creation;
  2. `^(init|initialise|initialize|build)` → initialization;
  3. `^(is|has|can|does|was|will|should|accepts|wants|needs|rejects|refuses|allows|contains|includes)[A-Z]`
     → testing;
  4. raw input prefixes (`press|release|pointer|mouse|hover|wheel|key|touch|drag|drop`) → events;
  5. gesture names (`activated|scrolledBy|click|doubleClick|floatDrag|reactTo|onClick`) → gestures;
  6. `paint|draw|render` → drawing;
  7. `step|fps` → stepping;
  8. `Menu|PopUp|Popout|Prompt` → menus;
  9. `pin|connect|wire|Target|dataflow|bang` → pins & dataflow;
  10. `serial|duplicat|Copy|restore|save` → serialization & copying;
  11. `Layout|reLayout|arrange|settle|Spec` → layout;
  12. `Extent|Width|Height|Bounds|Position|moveTo|resize|left|right|top|bottom|center|corner|Rect|Point|scale|rotat`
      → geometry;
  13. `add|remove|child|parent|sibling|root|descendant|ancestor` → structure;
  14. `destroy|close|open|show|hide|collapse` → lifecycle;
  15. `^(set|get)[A-Z]` → accessing;
  16. `changed|invalidat|damage` → invalidation;
  17. `cache` → caching;
  18. `toString|String$|Name$|print` → printing;
  19. `caret|edit|select|text` → editing.
- **Results:**
  - **tree: 4,242 methods, 64% classified, 36% unclassified;**
  - **`Widget`: 384 methods, 78% classified, 22% unclassified.**
  - Substring rules misfile some methods (for example `left` inside unrelated names). U4's
    `ProtocolInference` must use word-boundary rules and the normalisation above, and its results
    need eyeballing on the stage classes.
