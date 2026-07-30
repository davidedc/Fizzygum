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
| `homepage` | `core` + `meta-tools` | precompiled | `lazy` | `index.html` | **production** |
| `lean` | `core` | precompiled | `none` | `index.html` | the appliance: 10 files, 1.3 MB |

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
| `fg homepage` | the ONLY gate that exercises a production tree: boots it, asserts `preCompiled === true`, no SWCanvas payload, a whole-world snapshot round-trip, and (when the tree says `BUILDFLAG_SOURCES === "lazy"`) that nothing is fetched at boot AND an inspector works after one open |
| `build_and_smoke.sh --profile lean` | the appliance boots and ships no source text |
| `node scripts/build-tree-fingerprint.js compare <a> <b>` (tests repo) | tree equivalence: the stored-source multiset + every file's size and hash |

⚠ **How to use the fingerprint.** Take baselines for every flavour a change can reach BEFORE touching anything, state
each one's PREDICTED delta in words, then compare and treat any unpredicted line as a finding. Compare at the SAME
commit and the same cleanliness — the boot bundles carry a build stamp that gains `" +local-changes"` on a dirty tree.
Keep baselines in `.scratch/` (gitignored) and re-take them per comparison: a committed baseline is stale at the next
source commit and then actively misleading.
