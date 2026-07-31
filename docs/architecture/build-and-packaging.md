# Fizzygum build & packaging — reference

**What this is.** The durable, living reference for how a Fizzygum artifact is *assembled and selected*: the PARTITION
(what the shipped code is divided into), the PROFILES (which artifact you are building), what each profile
DERIVES rather than declares, and where every rule is implemented. Written to be picked up **cold**.

**What this is NOT.** It is not the *why* of the four arcs that produced this shape — that history, with its
falsified premises and its measurements, lives in `docs/archive/build-arc-{1,2,3,4}-*.md` and
`docs/archive/build-arc-5-packaging-profiles-plan.md`. It is not the build-time *checking* system either: for the gates
`build_it_please.sh` runs, see **`docs/architecture/lint-and-static-checks.md`**.

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

⚠ **THE LAUNCHER SPLIT — the same rule one level up, for anything reached at BOOT.** A door can only
await if something reaches it *later*; `WorldWdgt.createDesktop` runs at boot and places every
desktop/Examples icon by constructing its app, so an app class living inside the lazy directory it
opens means no icon at all — nothing would ever pull the part in. So the LAUNCHER becomes its own
tiny EAGER part and the engine stays lazy: `fizzytiles` / `fizzytiles-launcher`
(`FridgeMagnetsApp` + its icon) and `spreadsheet` / `spreadsheet-launcher` (`SpreadsheetApp` alone —
its icon is built from core widgets). Two consequences worth stating: the boot site keeps a plain
`if SpreadsheetApp?` guard — correct, because it is asked of the EAGER half — and a profile must
name **both parts or neither**, since the launcher alone is an icon whose click can only reject and
the engine alone is code nothing can open. `maps` and `plots` needed no such split: their doors are
apps that already lived in core.

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
| `homepage` | `core` + `meta-tools` + `samples` + `maps` + `plots` + `spreadsheet` + `spreadsheet-launcher` | precompiled | `lazy` | `index.html` | **production** |
| `lean` | `core` | precompiled | `none` | `index.html` | the appliance: 10 files, 1.3 MB |

⚠ **Production names seven parts, and they are named for two different reasons.** Four of them —
`maps`, `plots`, `meta-tools`, `spreadsheet` — are named because production genuinely offers what
they do, and they are all **lazy**, which is what makes naming them nearly free: a lazy part's
classes are absent from `js/pre-compiled.js`, so it costs the image nothing and the first load
carries none of it. `maps` and `plots` *have* to be named (the sample dashboard and the NYC slide
BUILD maps and plots, so production cannot drop those parts); `meta-tools` is lazy for the plainest
reason of all — nobody opens an inspector during a normal session, and opening one already had to
await the reflective layer, so the part load joins a wait that existed anyway; `spreadsheet` is the
same shape, behind a desktop icon.

The other two are EAGER, and named so that splitting them out of core stays a PACKAGING change
rather than a visible one: `samples` (the three Examples documents) and `spreadsheet-launcher`
(`SpreadsheetApp` alone). ⚠ **`spreadsheet` and `spreadsheet-launcher` are one decision spelled as
two parts** — see §2's launcher-split rule — and a profile should name both or neither. `lean` names
none of the seven, so it has no spreadsheet at all; that is deliberate, because the eager launcher
alone would put a desktop icon on a tree whose click could only reject.

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

For **eager** parts there is nothing worth dividing: **core is ~80% of all source bytes**, so on a production tree the
per-part split is 96% / 2%. The levers that pay are `lazy` (the whole layer) and making MORE parts lazy — which yields
per-part loading for free, and is partition work rather than loading work.

That partition work has now been done for every app-like slice that was worth extracting — `maps`, `plots` and
`spreadsheet` — and the numbers are worth keeping, because they say what the lever is really worth and how badly it can
be mis-estimated. ⚠ Note first where the saving comes from: **not** from the source bytes — production is
`sources: "lazy"`, so nobody was downloading those anyway — but from the **IMAGE**, because a lazy part's classes are
absent from `js/pre-compiled.js`.

| Slice | Source text moved behind an on-demand fetch | Off production's `pre-compiled.js` |
|---|---|---|
| `maps` | 95.0 KB | **−55.8 KB (−5.1%)** |
| `spreadsheet` | 119.4 KB | **−33.7 KB (−3.4%)** |

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
