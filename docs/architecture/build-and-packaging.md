# Fizzygum build & packaging — reference

**What this is.** The durable, living reference for how a Fizzygum artifact is *assembled and selected*: the PARTITION
(what the shipped code is divided into), the PROFILES (which artifact you are building), what each profile
DERIVES rather than declares, and where every rule is implemented. Written to be picked up **cold**.

**What this is NOT.** It is not the *why* of the four arcs that produced this shape — that history, with its
falsified premises and its measurements, lives in `docs/archive/build-arc-{1,2,3,4}-*.md` and
`docs/archive/build-arc-5-packaging-profiles-plan.md`. It is not the build-time *checking* system either: for the gates
`build_it_please.sh` runs, see **`docs/architecture/lint-and-static-checks.md`**.

**Visual companions** (`docs/explainers/`, for a reader with light context): `build-and-packaging.html` walks through
this document; **`boot-and-lazy-parts.html` covers the RUNTIME half** — the boot sequence, the two boot paths, when the
reflective layer arrives, and how `PartsRegistry` brings a lazy part in behind a running world. §2 and §5 below are the
authoritative statements of what that page illustrates.

> **Orientation.** Fizzygum has no module system. Every class is a global, shipped as escaped TEXT and compiled
> **in the browser** at boot; only `src/boot/*` is compiled to JS at build time. That single fact is why "packaging"
> here is unusual: what an artifact ships is not a dependency graph's closure, it is a set of *named slices of source
> text*, plus which pages exist, plus whether the classes arrive as text-to-compile or as a pre-compiled image.

---

## 1. The two files that decide everything

| File | Answers | Read by |
|---|---|---|
| `buildSystem/parts.json` | what the parts ARE, and what each one OWNS | `buildSystem/buildProfile.py` (and through it, everything) |
| `buildSystem/profiles/<name>.json` | which of them ship, in what FORM, behind which PAGES | `buildSystem/buildProfile.py` |

The split is worth keeping straight, because it is the one distinction that makes the rest simple:
**`parts.json` is the partition; a profile is a flavour.** A part does not know which artifacts contain it, and a
profile does not know what a part is made of.

`buildSystem/buildProfile.py` is the ONE reader of both. It resolves a profile, validates it, and derives the rest.
Three consumers use it and none of them re-implement any of its rules:

- `buildSystem/build.py` imports it (`partShips`, `loadParts`, `ENTRY_PAGES`);
- `build_it_please.sh`, `build_and_smoke.sh` and `build_and_test.sh` `eval` its `--shell` output;
- it also owns `--profile` PARSING, so no caller has its own copy of that either.

---

## 2. A part

A named slice that comes and goes as a unit. Every directory that ships belongs to exactly one part, and a `.coffee`
file under `src/` that no part claims is a **build failure** (`buildSystem/check-shippable-coverage.js`).

A part can own four kinds of thing, and **all four appear or vanish together with it** — that is the whole mechanism
by which a flavour stops shipping something:

| Field | Owns |
|---|---|
| `dirs` | the `*.coffee` sources (not recursive: list each directory) |
| `assets` | files copied into the tree, as `[source, destination-dir]` pairs |
| `vendor` | payloads assembled from vendored pieces, as `{out, concat:[…]}` |
| `bootPrelude` | `src/boot/*.coffee` pieces concatenated into the boot bundle |

Plus two properties that are **not** the same question:

- `eager` (default true) — TIMING: at boot, or on demand? A lazy part is fetched by `PartsRegistry` when something
  launches it, and its source text arrives *with it*.
- `requiresFlag` — an additional per-invocation opt-in. One carrier: `videoPlayer`. (Deliberate stopping point:
  `--includeVideos` copies gigabytes from an external drive and `--keepPreviousPrivateVideos` exists to *not* re-copy
  them, which describes how you are running the build, not what the artifact is.)

**A part's absence must be a NO-OP at every call site**, through the class-existence guard idiom (`if DemoMenus?`,
`world.pinouts?.reset()`), and guarded where the class is NAMED rather than at the callers.
`buildSystem/check-part-edges.js` fails the build on an unguarded core reference to a part-owned class.
⚠ A *lazy* part is different: its entry point must await `world.parts.ensureLoaded`, because a guard answers
"is it here?" and a lazy part needs "get it here".

**PART→PART DEPENDENCIES: `requires`.** A part may name another part's classes, and `parts.json`'s
`requires: [...]` is where that is stated. One declaration, two readers:

- **Inclusion** — `buildProfile.py` fails a profile that ships a part without what it requires. This is
  the both-or-neither rule — one that lived in prose until prose failed: `lean` once carried desktop
  icons whose click could only reject, because nothing checked the parts behind them shipped too.
  ⚠ Most such pairings are now stated per-CLASS instead, in `requiredParts`, and checked against the
  profile by the same pass (§8). That is deliberate: `requires` is the wrong tool for a door, because
  its second meaning below would drag the app in behind the door instead of behind the click.
- **Ordering** — for a LAZY part, `PartsRegistry.ensureLoaded` loads its requirements **fully first**,
  before ingesting its own batches. ⛔ **This is the only thing that makes cross-part inheritance
  safe.** A door naming several parts (`whenAllLoaded ["maps", "plots"]`) is enough for a *reference*
  but never for a base class: `ensureAllLoaded` is a `Promise.all`, so they arrive concurrently with
  nothing ordering them, and `class X extends Y` across that boundary is a race rather than a
  catchable error. Inside one part `findLoadOrder` orders; between parts, only `requires` does.

⚠ **`requires` does NOT excuse an EAGER part from guarding.** An eager part is already running at
boot, so the declaration can only promise the other part SHIPS, never that it has arrived — an
eager→lazy reference still needs a guard or an await where it stands. `check-part-edges.js` enforces
exactly that asymmetry, and its scope is every source present at boot (core **and** every eager
part), not core alone. ⚠ Cycles are rejected by the build: a cycle has no valid ingest order.

⚠ **A per-site await is the finer instrument, and `requires` is the one that reaches where an await
cannot.** Prefer the await when the reference sits somewhere with a seam: `demos` names `plots` from
six menu actions, each of which awaits, so opening a demo menu does not drag the charting part in.
But `demos` declares `requires: ["authoring", "maps"]`, and that is FORCED rather than chosen —
14 widgets in `src/demos-icons` reach their appearance through `createAppearance`, whose value
`CreatorButtonWdgt`'s constructor consumes synchronously (the no-async-seam rule below). At a site
with no seam there is nothing to await *in*, so ordering the load is the only mechanism left. The
rule that falls out: **a per-site await where a seam exists; `requires` where one does not, or where
a base class crosses the boundary.** Deciding it by taste instead is how a door ends up awaiting a
part it cannot wait for.

⚠⚠ **An awaiting entry point must keep its already-loaded path SYNCHRONOUS**, which is why there is
ONE idiom and every door uses it: `world.parts.whenAllLoaded ["maps", "plots"], => super()`.
`whenAllLoaded` runs its callback **inline** when the parts are already in, and only falls back to a
promise otherwise. On every build the SystemTest suite runs, the parts are eager and long since
present, so going through `.then` regardless would defer the launch by a microtask, which moves the
effect a whole world CYCLE later — and the suite measures cycles. (Same rule, same reason, as the
reflective layer's `reflectiveLayerIsLoaded()` fast path in §5.) It is one method rather than a
conditional copied into each door because one rule in two places is how arc 4 produced four bugs of
one shape.

⚠ **Two different questions, two different methods.** `isAvailable` asks "did this artifact ship this
part at all" — a `lean` build did not ship the inspectors, and there is genuinely nothing to open.
`_isLoaded` (private; `whenAllLoaded` is its only caller) asks "is it here YET". A class-existence
test answers NEITHER for a lazy part: an undefined class means both at once, and they want opposite
responses. That is why `Widget.spawnInspector` asks `world.parts.isAvailable "meta-tools"` and then
awaits, rather than guarding on `InspectorWdgt?`.

⚠⚠ **REQUIRED versus OPTIONAL is a real decision at every door, and getting it wrong is SILENT.**
Two await idioms, and the difference is what should happen on a profile that ships none of the parts
named:

| Idiom | On a part this artifact never shipped | Use when |
|---|---|---|
| `whenAllLoaded [names], -> …` | REJECTS; the callback never runs | the part CONSTITUTES the result — a `Sample*App` document that *builds* plots is broken without them, not reduced, so it must fail loudly rather than open half-assembled |
| `whenOptionalPartsLoaded [names], -> …` | loads what IS here, runs the callback anyway | the part ENRICHES the result — `DashboardsApp`/`SimpleSlideApp` merely offer its tools in a docked palette, and the toolbars already filter their own contents by class existence |

The failure mode is worth stating because it shipped: `DashboardsApp` and `SimpleSlideApp` are CORE
classes whose desktop openers `createDesktop` creates unguarded, and they used `whenAllLoaded ["maps",
…]`. On `lean`, which ships neither `maps` nor `plots`, the icon was therefore present and its click
could only reject — no window, ever, and an unhandled promise rejection. Fixed 2026-07-31; the
distinction now has a name so the next door has to choose deliberately.

⚠ **A lazy part needs an entry point that CAN await, and not every call site can.** A creator button
cannot: `WidgetCreatorAndSmartPlacerOnClickMixin.mouseClickLeft` and `Widget.grabbedWidgetSwitcheroo`
both consume `createWidgetToBeHandled()`'s RETURN VALUE synchronously, so there is no seam to defer
through. The resolution is partition, not cleverness — put the button in the part it creates from
(`maps` owns `USAMapCreatorButtonWdgt`), so the button's mere EXISTENCE proves its part is loaded and
a core toolbar can filter it with a plain `if USAMapCreatorButtonWdgt?`. An app is the easy case by
contrast, because `IconicDesktopSystemWindowedApp.launch` is fire-and-forget (the launcher invokes it
by reflection and ignores the result).

⭐ **AN ICON IS NOT ITS APP — which is why there are no launcher parts.** `WorldWdgt.createDesktop`
runs at boot and places every desktop and in-folder app icon — which looks like it forces each lazy
app to keep a tiny EAGER sliver beside it, purely so `createDesktop` has a class to construct. It
does not. `createDesktop` constructs the app only to ask it for a **title and an icon**, and the art
is core: **an icon needs the app's NAME, never the app.** So `IconicDesktopSystemWindowedAppLauncherWdgt` has a **lazy mode** that holds
`appClassName` as a string and, on the click, asks `PartsRegistry` which part owns that name, fetches
it, and only then constructs and launches. All three launcher parts are **deleted**; every app class
now lives in the lazy part it opens from, and a session that never clicks an icon never downloads or
compiles the app behind it.

Two things follow, and they are the ones to get right:

- **The boot site asks `world.parts.canEverProvideClass`, not `if SpreadsheetApp?`.** For a lazy
  class an existence test reads "not fetched yet" and would silently drop the icon for ever; the
  question being asked at boot is the *isAvailable* one — can this artifact EVER produce it — so a
  profile that ships neither the door nor its app (the `lean` appliance) simply draws no icon, rather
  than one whose click could only reject.
- **A profile must still name the door's part and its app's part together**, for the reason the
  launcher pairing always had. That is no longer remembered: `buildProfile.py` reads every shipped
  class's `requiredParts` against the profile's part list (§8).

⚠ **The lazy mode is also what makes a part per DOOR worth having.** The part is the loading unit, so
the Examples folder's five doors are five ONE-CLASS parts: with all five in one part, opening any one
would fetch the other four. The nine desktop Makers are the opposite case and live *inside*
`authoring` — they all declare `requiredParts: ["authoring"]` and build its widgets, so a click loads
that part regardless and separate parts would buy nothing while costing nine manifest entries.

⚠ **The EAGER mode is still live and still correct** — `IconicDesktopSystemWindowedApp.createOpener`
hands over a live app singleton, which is what `DemoMenus`' "launcher" menu items use. Choose it when
the app class is already in hand; choose the lazy mode when its arrival is the point.

⚠ **A launcher declares its parts as DATA, and the door is inherited.** `IconicDesktopSystemWindowedApp`
owns `launch`, which awaits `requiredParts` (and then `optionalParts`) before building the window, so a
subclass writes `requiredParts: ["authoring"]` and nothing else. That one line has two readers — the
await, and `check-part-edges.js`, which treats it as satisfying every reference the class makes into
those parts. Fourteen apps used to hand-write their own `launch` override instead; the gate could not
read any of them, so nine correct awaits still looked like violations. A declaration cannot drift from
the await, because the await IS the declaration. ⚠ Only `requiredParts` satisfies the gate: an optional
part may genuinely be absent, so references to one still need a guard where they stand.

⚠ **AN AWAIT IN ANOTHER METHOD IS INVISIBLE TO THE GATE, so a class in core cannot await its way
into a part.** The nine Maker apps had a correct
`launch: -> world.parts.whenAllLoaded ["authoring"], => super()` and the part still could not be
extracted, because each one's `buildWindow: -> world.openFrameWith (new DocumentWdgt), …` is an
unguarded core→part reference three lines below the await, and `check-part-edges.js` reads one line
at a time. That is the gate being right: a *reader* of that file cannot see the await either, and
nothing stops a future edit from calling `buildWindow` without going through `launch`. The fix is
partition, not an allowlist — the class moves into the part it builds from, and every one of those
references becomes intra-part.
⚠ The same rule bites inside one class: `ExamplesFolderWindowWdgt` builds its five openers *inside*
the `whenAllLoaded` callback rather than in a tidier `_populate` helper, because a reference three
methods from the await it depends on is indistinguishable from an unguarded one.

⚠ **A FOLDER IS A DOOR, and that is a third moment worth having.** Desktop icons are drawn at boot;
a folder's contents are not drawn until it is opened, and `IconicDesktopSystemShortcutWdgt.bringUpTarget`
is fire-and-forget, so it can await. `ExamplesFolderWindowWdgt` therefore fills itself on first open,
which buys a tier the desktop cannot have — the art that ONLY that folder draws
(`examples-icons`, 9.5 KB of C-F glyph) stays out of the boot image entirely:

| moment | what arrives |
|---|---|
| boot | the folder, EMPTY. No icon, no art, no app class |
| the folder is opened | `examples-icons`, and the five openers are built. Still no app |
| an opener is clicked | that one app's part — and no other's |

⚠ Only art that *nothing else* draws can move: the folder's other four icons (typewriter, slide,
dashboards, the generic shortcut frame) are drawn by desktop icons and by
`FolderWindowWdgt`/`BinOpenerWdgt` at boot, so they are core whatever the folder does.
⚠ KNOWN LIMIT: `bringUpTarget` is the shortcut-click ritual, so a folder window dragged straight out
of the shelf by hand shows empty once (`populated` stays false, so the next bring-up fills it). The
lifecycle alternative, `_reactToBeingAdded`, fires INSIDE the add's settle, and building children
there would re-enter the settle tier — it is not a seam content may be created in.

---

## 3. A profile

Four facts. Everything else about the artifact follows from them.

```
buildSystem/profiles/homepage.json          # the FILE's name is the profile's name
{ "parts":   ["core", "meta-tools"],        # "all" | [names] | {"allExcept": [names]}
  "form":    "precompiled",                 # "compile-at-boot" | "precompiled"
  "sources": "lazy",                        # "background" | "lazy" | "none"
  "entries": ["index.html"] }               # "all" | [names], from buildProfile's ENTRY_PAGES
```

`parts` and `entries` share the same three spellings on purpose: `"all"` means a part or page added tomorrow joins
with no edit here (right for the dev build), while an explicit list means a shipped artifact's contents are readable
in one place and do NOT grow silently (right for production).

`sources` is required **iff** `form` is `precompiled`, and **forbidden** otherwise — a compile-at-boot build's sources
ARE its world, so it has no policy to state, and a field that can hold only one value would just mirror `form`.

### The shipped profiles

| Profile | Parts | Form | Sources | Entries | Shape |
|---|---|---|---|---|---|
| `dev` (default) | all | compile-at-boot | — | all | the inner loop and the whole SystemTest suite |
| `dev-notests` | all except `harness` | compile-at-boot | — | all | dev without the test machinery |
| `homepage` | `core` + LAZY `meta-tools` `examples-icons` `example-degrees-converter` `example-doc` `example-slide` `example-dashboard` `example-sheet` `authoring` `maps` `plots` `spreadsheet` | precompiled | `lazy` | `index.html` | **production** |
| `lean` | `core` | precompiled | `none` | `index.html` | the appliance |

⭐ **Production names ELEVEN parts beside core, and EVERY ONE OF THEM IS LAZY.** That is the whole
shape of production now: `meta-tools`, `maps`, `plots`, `spreadsheet`, `authoring`, `examples-icons`
and the five one-class `example-*` doors. Naming a lazy part is nearly free — its classes are absent
from `js/pre-compiled.js`, so it costs the image nothing and the first load carries none of it — and
the artifact still offers everything it always did.

⚠⚠ **A consequence worth knowing before you reason about either profile: `homepage` and `lean` now
emit a BYTE-IDENTICAL `js/pre-compiled.js`.** The image contains only what is EAGER, and after the
launcher parts were dissolved that set is exactly `core` in both. The two artifacts differ in what
they can FETCH (production ships eleven lazy parts and 2.28 MB of source text; the appliance ships
neither), not in what they start from. So an image-size measurement cannot distinguish them, and a
change that moves a class between core and any lazy part moves BOTH numbers identically.

⚠⚠ **`lean` names none of them, and for `authoring` that is FORCED rather than chosen.** A profile
with `sources: "none"` may not ship a lazy part at all (`buildProfile.py` fails the build: a lazy
part's source *is* its code, since the image is harvested by booting `index.html`, where lazy parts
do not load). So the appliance has no spreadsheet and no Makers — no Docs, Slides, Dashboards, Draw,
Patch programming, Generic panel or Super Toolbar — and, correctly, no icons for them either: an
eager launcher on a tree without its engine is a desktop icon whose click can only reject. An
appliance that wants the Makers back wants `sources: "lazy"`, which is a different artifact.

---

## 4. What is DERIVED

This table is the heart of the design: every question the build used to answer by asking *"is this the homepage?"* is
now computed from the four facts above. Nothing in this column is declared anywhere.

| Derived | From |
|---|---|
| the `js/tests` symlink + `BUILDFLAG_LOAD_TESTS` | does the `harness` part ship? |
| the two tests-repo build gates (test `.js` syntax, reference-image strays) | same |
| stripping the dead `if Automator?` branches | same, inverted — no Automator, no checks to keep |
| assembling the SWCanvas boot bundle | does any shipped entry render through SWCanvas? |
| shipping the ~90 MB `font-assets/` (and re-pruning an inherited copy) | same |
| which assets and vendor payloads land in the tree | the shipping parts' own `assets` / `vendor` |
| which `src/boot/` pieces join the boot bundle | the shipping parts' own `bootPrelude` |
| running the pre-compile driver, then minifying in place | `form == "precompiled"` |
| whether `js/coffeescript-sources/` exists at all | `sources != "none"` |
| when the reflective layer loads, if ever | `sources` → `BUILDFLAG_SOURCES` in the bundle |
| which smoke a built tree gets | `form` + `sources` (`build_and_smoke.sh` asks the profile) |
| whether the suite runner may run at all | does the profile ship tests (`build_and_test.sh`) |

⚠ **`$BUILD_PATH` is shared across flavours**, and `font-assets/` survives the cleanup section. So the font-asset
decision has TWO directions in one place — copy it, or remove any copy a previous build left — and the second is not
belt-and-braces duplication.

---

## 5. The reflective layer, and the `sources` axis

"The reflective layer" is the class SOURCE TEXT plus the meta-system that parses it: the two individually-fetched
`Class`/`Mixin` sources, then every eager part's source batches, then an ingest-only pass
(`new Class src, false, false`) that registers each class's members and source text against the class the pre-compiled
image already defined. `src/boot/globalFunctions.coffee`'s `loadReflectiveLayerPromise()` is all five steps.

**It is what lets the system show and rewrite its own code. It is not what makes the world go** — a precompiled world
is already running before any of it. Hence the axis:

| `sources` | Behaviour |
|---|---|
| `background` | fetch it once the world is up, off the critical path |
| `lazy` | fetch it on first demand — opening an inspector, or restoring a snapshot carrying class-level source edits |
| `none` | never; ship none of it. No inspectors, and class-level source edits in a loaded snapshot are refused |

Facts worth knowing before touching any of this:

- **`Class` and `Mixin` are the only two classes ABSENT from `js/pre-compiled.js`** — they are the pair that compiled
  everything else, so nothing accumulated them into it. The meta-system reaches a precompiled world only through
  this layer.
- ⚠⚠ **A LAZY PART NEEDS THE META-SYSTEM, AND ONLY THE META-SYSTEM.** Ingesting a part's sources means `new Class` /
  `new Mixin`, and ordering them means `findLoadOrder` — none of which a precompiled tree has until something fetches
  them. So steps 1–3 are factored out as `ensureMetaSystemLoaded()` (~39 KB: the two meta sources plus
  `dependencies-finding-min.js`), and `PartsRegistry._loadPartPromise` awaits **that**, never
  `ensureReflectiveLayerLoaded()` — which would also fetch step 4, every eager batch, 2.29 MB, handing back the entire
  saving that made the part lazy. Both are memoized, so a part load and a later inspector open share one fetch.
  Before this split existed, any lazy part on a production tree died with `findLoadOrder is not defined`; nothing
  caught it, because the only lazy part until then (`fizzytiles`) does not ship in production, and the dev-tree rigs
  run compile-at-boot where the meta-system is present anyway. `fg homepage` now asserts it (§8).
- Its entire runtime consumer surface is **`Mixin.allMixines` in the two inspectors** (`meta-tools`) and in core's
  `SourceEditsRegistry`. There is no runtime `new Class`/`new Mixin` anywhere outside boot.
- **`compileFGCode` is NOT part of it.** It is defined in the same file the layer fetches
  (`js/src/loading-and-compiling-coffeescript-sources-min.js`) but `ScriptWdgt`, `Widget.evaluateStringAsScript` and
  the spreadsheet's `FormulaCompiler` all call it at runtime, in core, in every profile — runtime compilation is
  product behaviour, not a dev affordance. That file and `logging-div` always load.
- **The compiler ships in EVERY profile** for the same reason: FizzyPaint tools, spreadsheet formulas (including
  reloading a saved sheet), `$src` snapshot records and Fizzytiles' LiveCodeLang are all compiled from source strings
  at runtime. A compiler-less artifact is a non-interactive kiosk.
- ⚠ **On a `sources: "none"` build, the source text is a build INPUT.** The pre-compile driver harvests the image by
  booting the freshly-built tree at `?generatePreCompiled`, which is a COMPILE-AT-BOOT boot — so the text (and
  `js/src/dependencies-finding-min.js`) must exist during the build and is dropped *after* the driver runs, never
  skipped before it. This is also why `globalFunctions` skips the layer on
  `window.preCompiled and BUILDFLAG_SOURCES isnt "background"`: the `preCompiled` half is load-bearing.
- ⚠ A consumer that awaits the layer must keep its **already-loaded path synchronous**
  (`if reflectiveLayerIsLoaded() then … else ensureReflectiveLayerLoaded().then …`). On every non-lazy build the layer
  is long since present, and deferring by even a microtask moves the effect a world CYCLE later — which the
  SystemTest suite measures.

### Loading source per part

Already the case for a **lazy** part: `PartsRegistry._loadPartPromise` fetches that part's batches and ingests them at
launch, and `eagerSourceBatchNames()` never fetches them at boot. On a precompiled tree a lazy part's source is not an
extra — it IS the part's code, since the image is harvested by booting `index.html`, where lazy parts do not load. That
asymmetry is why the build refuses `sources: "none"` together with a lazy part.

For **eager** parts there is nothing worth dividing: on production, `core` IS the only eager part, so there is no split
to make. The levers that pay are `lazy` (the whole layer) and making MORE parts lazy — which yields per-part loading for
free, and is partition work rather than loading work. Core is **59.6% of all shippable source bytes** (73.7% of what
production ships), down from ~80% before the slices below — the ratio is worth re-measuring rather than quoting, since
every slice moves it.

That partition work has now been done for every app-like slice that was worth extracting — `maps`, `plots`,
`spreadsheet` and `authoring` — and the numbers are worth keeping, because they say what the lever is really worth and
how badly it can be mis-estimated. ⚠ Note first where the saving comes from: **not** from the source bytes — production is
`sources: "lazy"`, so nobody was downloading those anyway — but from the **IMAGE**, because a lazy part's classes are
absent from `js/pre-compiled.js`.

| Slice | Classes | Source text moved behind an on-demand fetch | Off production's `pre-compiled.js` |
|---|---:|---|---|
| `maps` | 4 | 95.0 KB (97.5% code) | **−55.8 KB (−5.1%)** |
| `spreadsheet` | 12 | 119.4 KB (27.9% code) | **−33.7 KB (−3.4%)** |
| `authoring` | 54 | 94.3 KB (75.3% code) | **−91.9 KB (−9.8%)** |
| unpinning what only lazy parts named | 81 | 100.6 KB (71.8% code) | **−119.5 KB (−14.15%)** |
| the Examples folder's five doors | 5 | 19.7 KB (64% code) | **−11.7 KB (−1.62%)** |
| every remaining app icon + the folder's own art | 11 | 29.3 KB | **−14.0 KB (−1.97%)** |
| what no boot path reaches (`fg whatpins`) | 9 | 20.1 KB (12.2 KB code) | **−16.8 KB (−2.46%)** |

⚠⚠ **The third row broke the estimator a second time, in the OTHER direction — the image cost tracks
CLASS COUNT at least as much as code bytes.** `authoring` and `maps` move almost exactly the same
source (94.3 vs 95.0 KB), yet `authoring` takes 1.65× as much off the image. It has 54 classes to
maps' 4, and every class compiles to its own prototype scaffolding, which the source bytes do not
show. Estimating `authoring` from maps' KB-of-code ratio predicted −42 KB against an actual −91.9 KB:
**2.2× LOW**, having been 33% low for maps and 50% high for the spreadsheet. The fourth row confirms
the class-count reading a second time and missed the same way (predicted order −70 KB, measured
−119.5 KB): 81 mostly one-method icon classes, the smallest-per-class slice yet, took the most off
the image of any of them. Four slices, four misses, in both directions. ⇒ **Do not promise a number
before the two builds are fingerprinted** (§8) — and when you must guess, a many-small-classes slice
will beat its byte estimate and a heavily-commented one will fall short of it.

⚠ **A class is pinned to `core` by being named there, so a slice UNPINS more than it moves.** The
fourth row is not an app slice at all: it is the classes whose only namers were already-lazy parts,
which stayed in `core` only because moving them would have made an unordered cross-part edge — the
thing `requires` now orders. Because each mover takes its own references with it, the pinned set is a
**FIXPOINT**: 48 files qualified, moving them qualified 28 more, then 4, then 1. Re-run
`buildSystem/pinned-by-lazy-parts.js` after every round.

⚠⚠ **"WHO NAMES IT" IS A WEAKER QUESTION THAN "WHAT REACHES IT", and the gap has a body count.**
`pinned-by-lazy-parts.js` reads ONE level over the partition as it stands, so a class two hops behind
an EAGER namer reads back "must not move" even when the whole chain is on-demand. That is how
`DegreesConverterIconAppearance` — 9.5 KB of art nothing draws but one icon inside a folder — stayed
in the production image until it was spotted BY EYE. `buildSystem/what-pins-core.js` (`fg whatpins`)
asks the transitive form: walk out from `src/boot/*` following every reference not behind a door, and
whatever the walk never arrives at is movable, transitively, in one pass instead of over four
move-rebuild-rerun rounds. It also ranks the **SOLE ROUTES** — where every boot path to a group of
classes goes through one class, so a door in front of that class takes the whole group with it. ⚠ That
second list is QUESTIONS, not findings: its top entries (`WorldWdgt`, `Widget`) are structural, which
is what its `refs` column is for. And it is honest about its own ceiling — no static tool over the old
partition could have called that art movable, because the app really was eager and "pinned" really was
the right verdict. What it can do is price the pinning so the design question gets asked.
The sixth row is its first harvest. Deliberately left behind, and reported every run: `ToolbarWdgt`
and `ToolbarCreatorButtonWdgt` (`plots` extends both; moving them would oblige
`plots requires ["authoring"]` for 1.2 KB), and `IconicDesktopSystemWindowedApp`, the base class of
every app across seven doors.

⚠ **A lazy part is not free on the critical path: it ADDS to the boot bundle.** The runtime parts
manifest carries each part's `classes` name list — it must, since the vault cannot answer
"which part owns this class?" before the part loads — so extracting `authoring` grew
`js/fizzygum-boot-native-min.js` by **1,857 bytes** (17,158 → 19,015; the manifest is 3,554 B of it).
That is a 2% toll on the thing that must arrive first, to take 92 KB off the thing that arrives
next, so it is a good trade at this size — but it scales with class count, and a partition of many
tiny parts would eventually spend more on the manifest than it saves. Moving 81 more classes into
existing parts cost another **1,935 B** (19,158 → 21,093) without creating a single new part: the
toll is per CLASS NAME, not per part. On `lean`, which ships no lazy part and therefore no such list,
the same change moved the boot bundle by **−3 B** — which is the cleanest statement of where the
cost actually lives. ⚠ Six MORE parts (five one-class doors plus `examples-icons`) then cost only
**+397 B** between them, which is what settles the "many tiny parts" worry at this scale: the
per-part overhead is a name and a batch list, and it is the CLASS names that dominate.

⭐ **Cumulatively, `js/pre-compiled.js` went 936,920 → 682,031 B — −27.2% — and production's eager
image is now exactly core.**

⚠⚠ **THE BOOT-SPEED PAYOFF DEPENDS ENTIRELY ON WHICH PAGE, AND THE TWO DIFFER BY 60×.** Measured
2026-07-31 (`docs/measurements/boot-timing-2026-07-31.md`): **production** reaches world-ready in
**54 ms**, of which the whole image parse+execute is ~46 ms — so a further slice worth ~1.6% of the
image buys about half a millisecond, and there is nothing to win. The **compile-at-boot `dev`
`index.html`** takes **3219 ms**, 97% of it compiling, ~8.6 ms per source — so laziness genuinely
helps *there*, bounded by a measured floor of 2680 ms (core alone is 389 of the 452 sources and
cannot be lazy). ⚠ The SystemTest suite benefits either way: the harness and SWCanvas pages preset
`FIZZYGUM_EAGER_ALL_PARTS`, so they compile everything regardless. ⇒ extract further parts for
download size, partition uniformity, or dev-page boot — not for production startup.

⚠⚠ **Those two rows are the warning: source bytes do not predict image bytes, and the ratio between them varies by
2.5×.** `maps` is vector-path artwork — 2.5% comment bytes, essentially all code. `src/spreadsheet` is 72.1% COMMENT
bytes, and comments never reach a compiled, minified image. So a per-KB-of-source estimate calibrated on one slice was
33% LOW for `maps` and 50% HIGH for `spreadsheet`. **Estimate from a slice's CODE bytes, and treat even that as a
guess until the two builds have been diffed** (`scripts/build-tree-fingerprint.js`, §8).

**What is deliberately NOT a part.** `src/dataflow/` looks like the obvious fourth slice and is not one: it is the
wiring substrate (`ControllerMixin.ensureWireEdge` is how any widget wires to any other, and `WorldWdgt.doOneCycle`
drains it every cycle), and all 14 of its call sites are already written `world.dataflow?.…` — so its absence would be
silently ACCEPTED rather than caught. Wires would simply stop firing. That fails the absence-must-be-a-no-op rule in §2,
which is the test for whether something can be a part at all; the same judgment keeps `src/meta` out. Recorded so it is
not re-attempted: `docs/plans/core-app-slices-partition-plan.md` §4 Phase 3.

---

## 6. Invocation

```
./build_it_please.sh                                  # the dev profile
./build_it_please.sh --profile homepage               # production
./build_it_please.sh --profile lean                   # the appliance
./build_it_please.sh --includeVideoPlayer --includeVideos
./build_it_please.sh --noSyntaxCheck                  # a gate switch, NOT a profile field:
                                                      # a profile describes an artifact, not how
                                                      # carefully you checked it
```

There are **no flavour flags**. An unknown argument is a hard error that lists the available profiles.

## 7. Adding things

- **A new part** — add it to `parts.json` with its `dirs`; `"parts": "all"` picks it up for the dev builds. Name it in
  `homepage.json` only if production should have it. Guard every core reference to its classes.
- **A new profile** — add a file. Validation refuses: an unknown key, a missing/forbidden `sources`, a part or entry
  page that does not exist (this is the one that matters at a RENAME — it turns "production silently ships less" into
  a build failure), a profile without `core`, `precompiled` without `index.html`, and `sources: "none"` with either
  `meta-tools` or a lazy part.
- **A new entry page** — add a row to `ENTRY_PAGES` in `buildProfile.py` (filename, renders-through-SWCanvas,
  loads-every-part-at-boot). `"entries": "all"` picks it up.
- **A new non-source file** — give it to the part that owns it (`assets`), never to the build script. A
  declared-but-missing asset is a hard build failure, because an asset silently not copied is the failure mode this
  replaced: the tree looks fine and an `<img>` 404s at runtime.

## 8. Verifying a packaging change

`fg build` runs the gates. `fg gauntlet` is the behavioural gate but **never builds a production tree**, so it says
nothing about packaging on its own. The ones that do:

| Command | What it proves |
|---|---|
| `fg homepage` | the ONLY gate that exercises a production tree: boots it, asserts `preCompiled === true`, no SWCanvas payload, a whole-world snapshot round-trip, and (when the tree says `BUILDFLAG_SOURCES === "lazy"`) that nothing is fetched at boot AND an inspector works after one open. ⚠ It also **loads a LAZY PART** — whichever the manifest says is lazy — and asserts it was absent at boot, that all its classes arrive, and that **zero eager batches** came with it. That check runs BEFORE the inspector one on purpose: opening an inspector pulls the meta-system in on its way past and would mask a broken part load entirely |
| `build_and_smoke.sh --profile lean` | the appliance boots and ships no source text |
| `node scripts/build-tree-fingerprint.js compare <a> <b>` (tests repo) | tree equivalence: the stored-source multiset + every file's size and hash |

⚠ **How to use the fingerprint.** Take baselines for every flavour a change can reach BEFORE touching anything, state
each one's PREDICTED delta in words, then compare and treat any unpredicted line as a finding. Compare at the SAME
commit and the same cleanliness — the boot bundles carry a build stamp that gains `" +local-changes"` on a dirty tree.
Keep baselines in `.scratch/` (gitignored) and re-take them per comparison: a committed baseline is stale at the next
source commit and then actively misleading.
