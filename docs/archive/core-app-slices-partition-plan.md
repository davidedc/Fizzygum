> **ARCHIVED — EXECUTED AND CLOSED (2026-07-30).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Extracting the app-like slices out of `core` — spreadsheet, maps, plots, dataflow

> ## ✅ EXECUTED AND CLOSED — 2026-07-30. Do not re-open P0; it was answered.
>
> **Owner's P0:** P0-a **yes, `maps` only** · P0-b **demo material, but production KEEPS it** ·
> P0-c **lazy**. That combination is a third end state §1's review note did not enumerate, and it is
> coherent: production must *have* `maps` (the samples build maps), but being LAZY it is absent from
> `js/pre-compiled.js`, so the Examples folder survives AND the artwork leaves the first load.
>
> **Ran, in three sessions:** Phase 0 (`samples`) · Phase 0.5 (measured) · Phase 1 (`maps`, lazy) ·
> Phase 4 — then, on a follow-up instruction, **Phase 2 (`plots`, lazy)** and **`meta-tools` made
> lazy** (not a phase of this plan; the inspectors were already a part, just an eager one) — then
> **Phase 3: the `spreadsheet` extracted and made lazy, with `dataflow` DELIBERATELY LEFT IN CORE.**
> **ALL PHASES ARE NOW DONE. §13 is Phase 3's execution record; §12 was its brief.**
>
> **Result:** production `pre-compiled.js` **1,101,733 → 955,796 B (−145.9 KB, −13.3%)** with the
> Examples folder unchanged; `lean` 1,074,170 → 945,796 B (−12.0%). Zero reference churn throughout.
> Gates: `fg gauntlet` 14/14, `fg homepage`, `build_and_smoke.sh --profile lean`, fingerprints across
> dev/homepage/lean with every delta predicted before being measured.
> Commits: `eed2f2f2` (samples + maps), `058ea35f` (plots + lazy inspectors + the meta-system fix),
> tests `3741b855b` (the gate).
>
> **⛔ `dataflow` IS NOT A PART AND MUST NOT BECOME ONE** — owner decision, with the enumeration
> behind it in §4 Phase 3's amendment box. It is the wiring substrate, not an app slice.
>
> **Two things Phase 3 found that outlive it:** §13.3, the payoff estimator is broken (source bytes
> do not predict image bytes — `src/spreadsheet` is 72% comments, `src/maps` is 2.5%); and §13.7, a
> PRE-EXISTING defect this phase did not cause and did not fix — `DashboardsApp` / `SimpleSlideApp`
> are dead icons on a `lean` tree.
>
> **Four authored facts were FALSIFIED in execution — see §11 before trusting anything below.**
> Most load-bearing: the "derived part→part `requires`" §1 leans on **does not exist**.
>
> Everything from here down is the ORIGINAL pre-execution plan, kept as written for the record.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything
needed is embedded here or one named-doc hop away. Line numbers WILL drift — the quoted code, symbol
or filename is authoritative, re-grep before editing.

**⛔ P0 — THIS PLAN IS OWNER-GATED AND MUST NOT BE STARTED WITHOUT AN ANSWER.** It came out of one
question, asked 2026-07-30 and still open:

> *is an appliance-with-spreadsheet a shape you care about?*

Everything below is the answer to "what would it cost and what would it buy", measured rather than
guessed. It is NOT a mandate to go and do it. §1 states exactly what the owner has to decide and what
each answer implies; §9 records the case for doing nothing, which is a real option here and may be
the right one.

**MANDATE (if it runs).** Not a survey: move each approved slice OUT of `core` into a named part,
wholly, in-arc — its directory, its edges guarded or awaited, its part named in the profiles that
should have it, and `check-part-edges.js` back at zero unguarded references. A slice half-extracted
(a part that exists but that production still cannot drop) is a worse state than not starting.

---

## §0 Orientation — what this repo is, and what just happened

**Fizzygum** is a CoffeeScript GUI framework — a "web operating system" rendered on a single HTML5
`<canvas>`. ~470 classes live in `Fizzygum/src/`. There is **no module system**: every class is a
global, shipped as escaped TEXT and compiled *in the browser* at boot. Only `src/boot/*` is compiled
to JS at build time.

**Read `docs/architecture/build-and-packaging.md` FIRST.** It is the current-state reference for
everything this plan touches: the PARTITION (`buildSystem/parts.json` — what the parts are and what
each owns) versus the PROFILES (`buildSystem/profiles/*.json` — which of them ship, in what form,
behind which pages), and the table of what a build DERIVES rather than declares.

**The immediately-prior work.** A five-arc build-and-packaging program closed on 2026-07-30
(`archive/build-arc-{1..5}-*.md`; the arc-4 plan's §0.1 has the program table). Arc 4 created the
partition; arc 5 turned a build flavour into data — `{parts, form, sources, entries}` — deleted the
`--homepage`/`--notests` flags, and added two things this plan depends on:

- **`sources: "lazy"`, which production now uses.** A precompiled tree ships the class source text
  but does not fetch it until something reflects (opening an inspector). ⇒ **2.28 MB, 62.7% of the
  production tree, is already not downloaded.**
- **The `meta-tools` precedent**: the inspectors were split out of `core` into their own part, and
  the whole cost was **2 live lines** — the 26-file grep was almost all comments. That split is the
  worked example this plan follows.

**WHY THIS PLAN EXISTS NOW.** Closing arc 5 left one lever unpulled. Per-part *source* loading was
measured and found not worth building (core is 80% of all source bytes, so on production the split is
96% / 2%), and the recorded conclusion was: *the levers that pay are `lazy` — done — and making MORE
parts lazy, which is partition work rather than loading work.* This plan is that partition work,
scoped to the four app-like slices still sitting inside `core`.

### §0.1 The critical reframe — do not skip this

**The naive reading of this task is wrong, and the measurement says so.** "Extract the spreadsheet"
sounds like *core depends on the spreadsheet, cut the dependency*. It does not. Of the **24**
cross-boundary references the four slices have, **22 are core's own SAMPLE CONTENT reaching into
them** — three `src/apps/Sample*App` files and seven `src/buttons/*CreatorButtonWdgt` files. Only
**2** are the product proper (`WorldWdgt` building the desktop, and the world's dataflow
collaborator).

⇒ **The coupling is demo-shaped, not architectural.** That changes the order of work (§4) and it
changes what "success" means: the interesting question is not "can the spreadsheet leave core" (it
can, easily) but "**does the sample content belong in core at all?**" — and that is a question with
its own answer, independent of any appliance profile.

---

## §1 The decision the owner has to make (P0)

Three separable questions. The plan can execute any subset.

| # | Question | If YES | If NO |
|---|---|---|---|
| **P0-a** | Should a shipped artifact be able to OMIT the spreadsheet / maps / plots / dataflow? | run §4 Phases 1-3 for the approved slices | stop — nothing else here is worth doing on its own |
| **P0-b** | Should the SAMPLE CONTENT (`Sample*App`, `*CreatorButtonWdgt`, the toolbars that host them) be part of the product, or demo material? | run §4 Phase 0 — which is worth doing **even if P0-a is NO**, see §3.2 | leave them in core; Phases 1-3 get more expensive but stay possible |
| **P0-c** | If a slice leaves core, should it be EAGER (present unless a profile drops it) or LAZY (arrives on demand, like fizzytiles)? | see §5 — this is the one with a real runtime risk | default EAGER; lazy is a later, separate step |

**Recommended answers, with the reasoning in §3 and §9:** P0-b **yes** (it stands on its own),
P0-a **yes for `maps`, probably no for the rest**, P0-c **eager**. If the owner wants only one thing
from this document, it is P0-b.

**`[REVIEW 2026-07-30]` ⚠ P0-a and P0-b are COUPLED, and the coupling is the real decision.** The
samples part Phase 0 creates will carry derived part→part `requires` on ALL FOUR slices — its
content *instantiates* them, and a sample document cannot guard-degrade (a dashboard without plots
is broken, not reduced). So a profile that ships the Examples must ship every slice. Concretely:
**you cannot both keep the Examples folder in production and drop any slice from production.**
The two coherent end states are (i) production drops the Examples (Phase 0's default reading —
the visible change R-1 flags), after which Phases 1–3 can actually shrink the production
download; or (ii) production keeps the Examples, ships all four slices forever, and Phases 1–3
only ever benefit OTHER profiles (`lean`-style artifacts). Decide which one at P0 — it determines
whether the ~130 KB estimate in §2.5 is even reachable for `homepage`.

---

## §2 Exact current state — MEASURED 2026-07-30, at `Fizzygum master @ 4daded29`

### §2.1 The four slices

| Slice | Directory | Files | Source bytes | Contents |
|---|---|---|---|---|
| spreadsheet | `src/spreadsheet/` | 13 | **113.5 KB** | `CellWdgt`, `CellAppearance`, `FormulaCompiler`, `FormulaHelpers`, `SheetCellRecord`, `SheetCellsPanelWdgt`, `SpreadsheetApp`, … |
| maps | `src/maps/` | 4 | **85.4 KB** | `SimpleUSAMapIconWdgt` + `…Appearance`, `SimpleWorldMapIconWdgt` + `…Appearance` |
| plots | `src/graphs-plots-charts/` | 12 | **30.6 KB** | `AxisWdgt`, `PlotWithAxesWdgt`, `Example{Bar,Scatter,Function,3D}Plot*` |
| dataflow | `src/dataflow/` | 4 | **35.6 KB** | `DataflowEngine`, `DataflowSource`, `FrameSource`, `SecondsSource` |
| | | **33** | **265 KB** | = 12.8% of core's 2.07 MB |

⚠ **`maps` is 4 files but 85 KB** — the two `*Appearance` classes are vector map artwork. It is the
best bytes-per-edge of the four by a wide margin, and the least likely to be missed by a user who
never opens it. If only one slice is ever extracted, this is the one.

### §2.2 The edges — from the REAL gate, not from a grep

Method (repeat it before trusting any number here): copy `buildSystem/parts.json`, move the
candidate's directory out of `core`'s `dirs` into a new part, run
`node buildSystem/check-part-edges.js`, restore the file. That gate is the authority — it is an
identifier-level scan that STRIPS `#` comments by design ("prose may name anything"), which is
exactly why the `meta-tools` 26-file grep turned out to be 2 real lines.

| Slice | Unguarded core edges | Inheritance edges |
|---|---|---|
| spreadsheet | **1** | **0** |
| dataflow | **1** | **0** |
| maps | **5** | **0** |
| plots | **17** | **0** |
| **all four together** | **24** | **0** |

**ZERO inheritance edges in every case, individually and combined.** This is the load-bearing
result: arc 4's rule is that an `extends` / `@augmentWith` edge from core into a part is *not
guardable at all* — there is no "skip it" branch — so it means the partition is drawn wrong. There
are none here. **The partition is drawable.** Everything else is work, not risk.

### §2.3 The 24 edges, by SHAPE (this is the actionable table)

**Shape A — the desktop opener (1 edge).** `src/WorldWdgt.coffee:626`:
```coffee
    (new SpreadsheetApp).createOpener exampleDocsFolder
```
The established fix sits **four lines above it**, already in the file:
```coffee
    (new FridgeMagnetsApp).createOpener()  if FridgeMagnetsApp?
```

**Shape B — the world collaborator (1 edge).** `src/WorldWdgt.coffee:466`:
```coffee
    @dataflow = new DataflowEngine
```
Precedent: `world.pinouts` (arc 3 extracted `PinoutsOverlay` the same way) — an optional collaborator
constructed behind a guard and reached as `world.dataflow?.…` thereafter. ⚠ Every call site of
`@dataflow` must then tolerate its absence; enumerate them before touching this one (§4 Phase 3).

**Shape C — sample content and creator buttons (22 edges, 92%).**

| File | Edges | What it is |
|---|---|---|
| `src/apps/SampleDashboardApp.coffee` | 9 | a showcase document, built from plots + maps |
| `src/apps/SampleSlideApp.coffee` | 3 | ditto |
| `src/apps/SampleDocApp.coffee` | 1 | ditto |
| `src/buttons/{Bar,Function,Scatter}PlotWithAxesCreatorButtonWdgt.coffee` | 6 | one toolbar button each |
| `src/buttons/Plot3DCreatorButtonWdgt.coffee` | 1 | ditto |
| `src/buttons/{USA,World}MapCreatorButtonWdgt.coffee` | 2 | ditto |

A creator button is ~12 lines whose whole body is "make one of these and hand it to the pointer":
```coffee
class WorldMapCreatorButtonWdgt extends CreatorButtonWdgt
  iconToolTipMessage: "world map"
  createAppearance: -> new LittleWorldIconAppearance @, …
  createWidgetToBeHandled: ->
    switcheroo = new SimpleWorldMapIconWdgt
    …
```
The buttons are hosted by `src/toolbars/PlotsToolbarWdgt`, `DashboardsToolbarWdgt`, … and reached
through `src/ToolPanelWdgt.coffee`. The three `Sample*App`s are instantiated by
`WorldWdgt.createDesktop` into an "Examples" folder.

⇒ **Every one of these 22 is a widget-creating convenience whose *only* job is to demonstrate the
slice it references.** They are the same category of thing arc 3 extracted into `DemoMenus` and arc 4
made the `demos` part.

### §2.4 Suite exposure

`ls Fizzygum-tests/tests/` matches: **19** spreadsheet, **7** plot, **2** map, **1** dataflow.
This is NOT a blocker — the `dev` profile ships `"parts": "all"`, so every part is present for the
suite, and the two SWCanvas entry pages preset `FIZZYGUM_EAGER_ALL_PARTS`, so even a LAZY part is
eager there (that preset exists precisely because a part arriving mid-test would be frame-paced and
cycle-count-dependent). ⚠ It IS a blocker for making a slice lazy on `index.html` *and* deleting its
tests — nobody is proposing that.

### §2.5 What extraction would actually SAVE — and why the obvious number is wrong

⚠⚠ **Do not quote the 265 KB of source as the saving.** Production is `sources: "lazy"` since arc 5:
that source text is shipped but **not downloaded** unless someone opens an inspector. What a
production visitor actually downloads is `js/pre-compiled.js` — the compiled image, 1,073,630 B.

So the payoff of dropping a slice from a profile is its share of the IMAGE, not of the source. Rough
estimate from the whole-tree ratio (1.07 MB image / 2.19 MB source ≈ 0.49): the four slices together
are **~130 KB of image, ~12% of the production download**. For `maps` alone, ~42 KB.

**⚠ That estimate is unverified and Phase 0.5 must replace it with a measurement** (§4). It is a
uniform-density assumption, and these slices are not uniform — `maps` is mostly long vector-path
literals, which minify differently from ordinary class code.

---

## §3 The distilled argument

### §3.1 For extraction (P0-a)
The partition is drawable at zero risk (§2.2: no inheritance edges), the mechanism is finished and
proven (arc 5), and a `lean`-style appliance that also drops app slices would be meaningfully
smaller. `maps` in particular is 85 KB of decorative artwork behind 5 demo-shaped edges.

### §3.2 For re-homing the sample content (P0-b) — the strongest argument here, and it is independent
**22 of the 24 edges exist because core ships demonstrations of itself.** That is worth fixing on its
own terms, whatever the owner decides about appliances:
- it is the same judgment arc 3 and arc 4 already made twice (`DemoMenus`, the `demos` part), so
  it makes the tree *more* consistent, not less;
- it makes every future slice extraction cheap — after Phase 0, spreadsheet and dataflow are **1 edge
  each** and maps/plots are **0**;
- and it answers a question the current partition answers inconsistently: `demos` exists as a part,
  yet the sample apps and creator buttons — which are demos — sit in core.

### §3.3 Against (why §9 is a live option)
These are **product features**, not scaffolding. A general Fizzygum build wants a spreadsheet the way
it wants windows. The appliance profile that would drop them (`lean`) already exists and is already
small (10 files, 1.3 MB), and nobody has yet asked for an appliance-with-fewer-apps. Extracting four
slices adds four parts to a partition that is meant to be readable at a glance, in exchange for ~12%
of a download that is already 62.7% lighter than it was this morning.

---

## §4 Phases

Each phase is independently correct, independently gated, and independently abandonable.

### Phase 0 — re-home the sample content `[P0-b]`
Move `SampleDashboardApp`, `SampleSlideApp`, `SampleDocApp` and the seven `*CreatorButtonWdgt` files
into the **existing `demos` part** (or a new `samples` part — decide on whether the demo menus and
these belong together; `demos` currently holds `DemoMenus` plus the bouncer/pen/pointer sample
widgets, which is the same species).

⚠ **A moved file changes its part, and `src/apps/` and `src/buttons/` are MIXED directories** — they
hold product apps and product buttons too. Arc 4's rule P-D2: **a mixed directory is resolved by
MOVING FILES, never by tagging them.** So this is a `git mv` into the part's directory, not a new
field.

Then guard what core still reaches: `WorldWdgt.createDesktop`'s three `(new Sample*App).createOpener`
calls, and whatever `ToolPanelWdgt` / the toolbars do to build their button rows (read them first —
a toolbar that builds a row from a list of classes needs the list filtered, not each use guarded).

**Predicted delta:** dev tree byte-identical except that ~10 sources move part; production tree loses
those sources IF production's profile does not name the part (`demos` is not in `profiles/homepage.json`,
so **production would stop shipping the sample apps — CONFIRM THAT IS WANTED**, it is a visible
product change: the "Examples" folder on the desktop would lose three of its documents).
⇒ **This is the phase with a user-visible consequence. It is a P0-b question in its own right.**

**Gate:** `fg build` (check-part-edges back at 0, check-shippable-coverage 0 gaps) · `fg gauntlet`
· `fg homepage` · fingerprints per §7.

### Phase 0.5 — measure the real payoff before committing to Phases 1-3
Replace §2.5's estimate with a number. Cheapest honest method: add the four candidate parts, exclude
them from a scratch profile copied from `homepage.json`, build it, and compare `js/pre-compiled.js`
sizes. ⚠ The build's `check-part-edges` gate will REFUSE the tree until the edges are guarded, so do
this AFTER Phase 0 (when only 2 edges remain) or with the guards from Phases 1-3 in place. If the
measured saving is materially below ~130 KB, re-read §9 before continuing.

### Phase 1 — `maps` (the best value, do it first)
`src/maps/` → its own part. After Phase 0 it has **0** remaining core edges; without Phase 0 it has
5 (2 creator buttons + 3 sample-app sites). Name it in `dev`'s `"all"` automatically; decide
per-profile for `homepage`.

### Phase 2 — `plots` (`src/graphs-plots-charts/`)
17 edges before Phase 0, **0** after. ⚠ Check whether `AxisWdgt` and `PlotWithAxesWdgt` are used by
anything outside the plots family (a chart axis is the kind of thing that gets reused) — the gate
will say, but read the hits rather than guarding blindly.

### Phase 3 — `spreadsheet` and `dataflow` (1 edge each, but the two riskiest)

> **⛔ AMENDED 2026-07-30 BY OWNER DECISION D2 — `dataflow` STAYS IN CORE. Do not re-attempt its
> extraction.** The R-2 enumeration this phase demanded was done, and it is the reason: `world.dataflow`
> has **14 call sites, almost all core** — `Widget.coffee`, `ControllerMixin` ×3 (`ensureWireEdge`,
> i.e. how ANY widget wires itself to any other), `SliderWdgt`, `SimpleTextWdgt`, `StringWdgt`,
> `PaletteWdgt`, the core `PatchNodeWdgt`, `WellKnownObjects` — plus the every-cycle drain station
> `WorldWdgt.recalculateDataflow`. They soak SYNTACTICALLY (they are already `world.dataflow?.…`) but
> **not SEMANTICALLY**: with the engine absent, wires silently never fire, sliders stop driving their
> targets, patch nodes go dead. That is BROKEN, not reduced, and it fails arc 4's rule that a part's
> absence must be a NO-OP. **`dataflow` is the wiring substrate, not an app slice** — the same
> judgment as "`src/meta` cannot be a part". §12.2's item 4 (the missing part→part `requires`) is
> therefore moot for this phase: the spreadsheet's door names ONE part.
>
> The `spreadsheet` half below still runs, with one addition forced by owner decision D1 (lazy, not
> eager): see §12.

- **spreadsheet**: guard `WorldWdgt.createDesktop`'s `(new SpreadsheetApp).createOpener` exactly like
  the `FridgeMagnetsApp` line above it. ⚠ `FormulaCompiler` calls `compileFGCode` at runtime — that is
  product machinery present in every profile (arc 5 PR-D3), so no new dependency, but re-read
  `docs/architecture/build-and-packaging.md` §5 before assuming anything about what a lean tree has.
- **dataflow**: `@dataflow = new DataflowEngine` in `WorldWdgt` is a WORLD COLLABORATOR, so the guard
  is only step one — **enumerate every `@dataflow` / `world.dataflow` call site and make each tolerate
  absence** (`world.dataflow?.…`). The enumeration includes the DRAIN STATION: `doOneCycle` runs
  `recalculateDataflow` between the step functions and the layout pass — that call site must soak
  too. This is the one slice whose absence is not obviously inert; if the enumeration turns up a
  call site that cannot be soaked, STOP: the partition is wrong there.
- `[REVIEW 2026-07-30]` **These two are not siblings — spreadsheet REQUIRES dataflow** (the engine
  is the spreadsheet's substrate; cells register with it). The derived part→part `requires` will
  record that automatically, but state it in the profiles work (Phase 4): any profile naming
  `spreadsheet` must name `dataflow`; the reverse is free (dataflow alone serves patch-programming).

### Phase 4 — profiles + docs
Name the new parts in the profiles that should have them; update
`docs/architecture/build-and-packaging.md` (the partition table and the profile table); add each
part's line to `parts.json`'s header if it needs explaining. Then the `close-arc` ritual.

---

## §5 Eager or lazy? (P0-c)

**Default EAGER.** An eager part is inclusion-only: present, or absent-and-inert-behind-a-guard.
That is the whole of Phases 0-4.

**Lazy is a different, later decision with a real runtime cost**, and arc 5 measured the traps:
- a lazy part's classes are **NOT in the pre-compiled image** (the image is harvested by booting
  `index.html`, where lazy parts by definition do not load) — so on a precompiled tree its source
  text IS its code, and `sources: "none"` + a lazy part is refused by the build;
- **`if TheClass?` is the WRONG guard for a lazy part** — for a part that never shipped it correctly
  means "no-op", but for one that merely has not loaded yet it silently swallows the user's click.
  A lazy part's entry point must `await world.parts.ensureLoaded(...)`;
- a lazy part that a snapshot names is handled — `loadWorldSnapshot` pre-scans
  `Serializer.classNamesIn` and loads the missing parts before touching the world — but that path is
  worth re-reading (`WorldWdgt.loadWorldSnapshot` step 0) before relying on it.

⇒ If the goal is "a smaller production download", **eager + a profile that omits the part achieves it
outright**, with none of the above. Lazy only earns its complexity if the goal is "one build that has
everything but starts fast", which is a different product decision.

---

## §6 Risks

| # | Risk | Mitigation |
|---|---|---|
| R-1 | Phase 0 silently removes the "Examples" desktop documents from production | it is a VISIBLE product change; P0-b must answer it explicitly, and `fg homepage`'s boot is where you would see it |
| R-2 | A `@dataflow` call site cannot tolerate absence | enumerate them ALL before guarding the constructor (Phase 3); an un-soakable site means the partition is wrong there, not that the guard needs to be cleverer |
| R-3 | A moved file changes its part and therefore its BATCH, so every fingerprint differs | expected: predict "these N sources change part, nothing else" and check exactly that (§7) |
| R-4 | `AxisWdgt`/`PlotWithAxesWdgt` are reused outside the plots family | the edge gate reports it; read the hits, do not guard blindly |
| R-5 | Extraction lands but no profile ever drops the part | that is the half-done state the MANDATE forbids — either a profile omits it or the phase was pointless |
| R-6 | The suite's 19 spreadsheet / 7 plot tests churn | they should NOT: `dev` ships all parts and the harness page forces eager. ANY reference churn means something moved that should not have — do not recapture, find the cause |
| R-7 `[REVIEW 2026-07-30]` | A saved `.fzw.json` naming a slice's classes is loaded on a profile that DROPPED that slice | `loadWorldSnapshot`'s step-0 pre-scan hits `ensureAllLoaded` → rejects with "no such part in this build". Acceptable by the no-serialization-compat policy, but if any slice is actually dropped from a shipping profile (Phase 4), verify the rejection surfaces as a clean `world.inform`, not an unhandled promise |

---

## §7 Verification protocol

All via `/Users/davidedellacasa/code/Fizzygum-all/fg` (cwd-correct from anywhere, gates on real exit
codes). Long ops: launch ONCE in the background with a log and wait for the notification; peek with
`cat /tmp/fg-<cmd>.verdict`. ⚠ A running `fg` op OWNS its inputs — never edit `fg`, `src/` or
`tests/` mid-run.

| When | Command | Why |
|---|---|---|
| every step | `fg build` | `check-part-edges` (0 unguarded), `check-shippable-coverage` (every dir claimed), syntax |
| inner loop | `fg presuite` (~3.5 min) | build + dpr1 suite ∥ paint audit |
| phase close | `fg gauntlet` (~5 min, 14 legs) | full behavioural gate — but it NEVER builds a production tree |
| **the real gate** | `fg homepage` | the only production-tree gate: boot, `preCompiled === true`, no SW payload, snapshot round-trip, and the `sources: "lazy"` assertions |
| appliance | `Fizzygum/build_and_smoke.sh --profile lean` | the tree that would benefit most |
| parity | `node scripts/build-tree-fingerprint.js compare <base> <cand>` (tests repo) | what moved, exactly |

**How to use the fingerprint without fooling yourself** (arc 5's case law, learned twice the hard
way): take baselines for EVERY flavour the change can reach BEFORE touching anything; state each
one's PREDICTED delta in words; then compare, and treat any unpredicted line as a finding. Compare at
the SAME commit and the same cleanliness — the boot bundles carry a build stamp that gains
`" +local-changes"` on a dirty tree. Keep baselines in `.scratch/` (gitignored), re-take per
comparison.

**Zero reference churn is the expectation throughout.** This plan repackages; it does not change
rendering. A screenshot diff means something is wrong — **do not recapture**, find the cause.

---

## §8 Rejected / do-not-re-attempt

1. **Per-part SOURCE loading as the lever** — measured and rejected 2026-07-30: core is 80% of all
   source bytes, so on a production tree the per-part split is 96% / 2%. And for a LAZY part the
   source already travels with the part (`PartsRegistry._loadPartPromise`). The mechanism was never
   the problem; the partition is.
2. **Tagging files instead of moving them** to resolve a mixed directory — arc 4's P-D2. The
   whole-file exclusion markers are retired and gated at zero (`check-whole-file-markers.js`); do not
   invent a replacement syntax.
3. **Making a slice lazy in the same step as extracting it** — two different risks in one commit, and
   the guard idiom differs between them (§5).
4. **Quoting the source-KB as the saving** — production is `sources: "lazy"`; the source text is not
   downloaded. Only the pre-compiled image is (§2.5).

---

## §9 The case for doing nothing (read this before starting)

It is a real option and it may be right:

- The download problem this would attack **has already been 62.7% solved** by `sources: "lazy"`, this
  morning, at zero cost to what the artifact can do. The remaining prize is ~12%.
- These are **product features**. Every extraction adds a part to a partition whose value is that a
  reader can see the whole thing at a glance, and adds a guard to a call site that currently just
  works.
- **No one has asked for the artifact this enables.** `lean` exists, and its purpose was proving the
  `sources: "none"` axis, not serving a known deployment.
- The one piece with an argument that does not depend on any of this is **Phase 0** — the sample
  content — and that argument is about consistency, not bytes.

⇒ **A defensible outcome of P0 is: do Phase 0, skip Phases 1-3, close the plan.** Say so explicitly
if that is the decision, so the next session does not re-open it.

---

## §11 EXECUTION RECORD — 2026-07-30 (what was actually true)

### §11.1 The four falsified facts

1. **⚠⚠ "The samples part will carry derived part→part `requires`" (§1's review note) — FALSE.
   There is no such mechanism.** `parts.json` has no `requires` field, `buildProfile.py`/`build.py`
   derive none, and `PartsRegistry.ensureLoaded`'s own comment says *"Load a part (and, **when it
   grows one**, whatever it requires)"* — it is explicitly future work. `check-part-edges.js` also
   states outright that part→part references are NOT checked. **Consequence:** nothing in the build
   would have caught a `samples`→`maps` mistake; the whole correctness burden sits on the call sites,
   which is why Phase 1 put the awaits in by hand and documented them.
2. **§2.5's "~42 KB for `maps`" — understated by ~33%.** Measured: **55,793 B**. The plan predicted
   its own error's direction (`maps` is long vector-path literals, which minify unlike class code).
3. **§4 Phase 0's "move them into the existing `demos` part" — not possible under P0-b.** Production
   keeps the samples ⇒ the part must be named in `homepage.json` ⇒ naming `demos` would *add*
   `DemoMenus` + the bouncer/pen/pointer widgets to production, which nobody asked for. Hence a NEW
   `samples` part. Two species of demo, two parts.
4. **§2.3's Shape C lumps the 7 creator buttons in with the 3 sample apps — they are not one
   category.** The 5 PLOT buttons were deliberately LEFT IN CORE: `graphs-plots-charts` is not being
   extracted, so moving them would add 10 core→`samples` edges for zero bytes and would strip `lean`'s
   dashboard editor of its plot tools while the plot code itself stayed. The 2 MAP buttons moved into
   **`maps`**, not `samples` — see §11.2.

### §11.2 The design decision P0-c forced

**A creator button has no async seam.** `WidgetCreatorAndSmartPlacerOnClickMixin.mouseClickLeft`
(click) and `Widget.grabbedWidgetSwitcheroo` (drag) both consume `createWidgetToBeHandled()`'s RETURN
VALUE synchronously, so a map button outside the `maps` part could not await it. The `FridgeMagnetsApp`
precedent does not transfer — it works only because `IconicDesktopSystemWindowedApp.launch` is
fire-and-forget. **Resolution: partition, not cleverness.** The two map creator buttons live IN
`maps`, so a button's existence proves its part is loaded, and the core toolbars filter the LIST
(`(new USAMapCreatorButtonWdgt if USAMapCreatorButtonWdgt?)` inside the array, then compact) rather
than appending behind a guard — appending would silently reshuffle the palette.

**⚠ The microtask trap, which would have churned references.** Four SystemTests call
`new SampleSlideApp().launch()` / `new SampleDashboardApp().launch()` directly. The naive
`ensureLoaded(...).then => super()` defers by a microtask = a whole world CYCLE, which the suite
measures — and §7 forbids recapturing to hide that. Every awaiting door therefore uses the
already-loaded FAST PATH, which needed a new (and explicitly pre-sanctioned) `PartsRegistry.isLoaded`:

```coffee
launch: ->
  if world.parts.isLoaded "maps" then super()
  else world.parts.ensureLoaded("maps").then => super()
```

Four doors carry it: `SampleDashboardApp`, `SampleSlideApp` (they BUILD maps) and `DashboardsApp`,
`SimpleSlideApp` (their windows dock a map-bearing palette). `SampleDocApp` needs none — it touches
only `Example3DPlotWdgt`, which stayed in core.

### §11.3 The one accepted wart

`SlidesToolbarCreatorButtonWdgt` pops a floating `SlidesToolbarWdgt` through a synchronous click path
with no hosting app to await at. On a build that HAS `maps` but has not loaded it yet, that palette
opens **without its two map tools** until something else pulls the part in. Invisible on dev/harness
(eager) and on `lean` (no maps at all); reachable only on production, and only before any dashboard or
slide has been opened. Accepted rather than fixed: closing it means either making the whole toolbar
build async or eagerly pre-fetching the part, and the second would forfeit the saving that motivated
laziness in the first place.

### §11.4 Measured

| Tree | Before | After | Δ |
|---|---|---|---|
| `homepage` `js/pre-compiled.js` | 1,101,733 B | **1,046,121 B** | **−55,612 B (−5.05%)** |
| `lean` `js/pre-compiled.js` | 1,074,170 B | 1,009,518 B | −64,652 B (−6.02%) |
| `maps` source batch (ships, fetched on demand) | — | 94,995 B | new |
| Stored sources, dev / homepage | 502 / 434 | 502 / 434 | unchanged |

Every delta was predicted in words before it was measured; no unpredicted line appeared in any of the
three fingerprints. Baselines and the driver script are in `Fizzygum-tests/.scratch/` (gitignored).

⚠ **§2.5's 1,073,630 B figure for the production image is stale** — it was 1,101,733 B at execution.

### §11.5 ⚠⚠ THE DEFECT THAT SHIPPED, AND THE GATE THAT NOW CATCHES IT

The `maps` work (commit `eed2f2f2`) shipped **broken on production** and every gate stayed green.
Ingesting a lazy part's sources calls `new Class` / `new Mixin` and orders them with `findLoadOrder`
— and a PRECOMPILED tree has none of the three until something fetches them (`Class` and `Mixin` are
the only two classes absent from `js/pre-compiled.js`; `findLoadOrder` was loaded only as step 3 of
`loadReflectiveLayerPromise`). So `world.parts.ensureLoaded("maps")` rejected with
`findLoadOrder is not defined` on the production tree. Proved, not inferred: restoring the pre-fix
line for one build reproduces it.

**Why nothing caught it.** `fizzytiles`, the only lazy part before `maps`, is not in production; the
dev-tree rigs (`parts-lazy-load-headless.js`) run compile-at-boot, where the meta-system is loaded at
boot anyway; and `fg homepage`'s inspector probe cannot see it because `spawnInspector` awaits the
whole reflective layer, which loads the meta-system on its way past. **No gate loaded a lazy part on
a precompiled tree.** It only surfaced when `meta-tools` itself became lazy, putting a part load
directly in the gate's path.

**Fix.** Layer steps 1–3 factored out as `ensureMetaSystemLoaded()` (~39 KB: the two meta sources +
`dependencies-finding-min.js`), awaited by `PartsRegistry._loadPartPromise`. ⚠ It must NOT await
`ensureReflectiveLayerLoaded()` instead — that also runs step 4, every eager batch, 2.29 MB, which is
precisely the saving that made the part lazy.

**Gate.** `smoke-boot-headless.js --production` now takes whatever the manifest says is lazy, loads
it, and asserts: absent at boot, all its classes arrive, and ZERO of core's numbered eager batches
came with it. It runs BEFORE the inspector probe deliberately. The gate was verified by planting the
pre-fix behaviour and watching it fail with the exact error — a gate nobody has seen fail is not a
gate.

⚖ **The transferable lesson:** a capability's FIRST use on a given artifact shape is untested by
construction, however well the mechanism is covered elsewhere. `maps` was the first lazy part
production ever shipped, and every existing rig tested laziness on a tree where the prerequisite
happened to be present already.

---

## §12 WHAT IS LEFT: Phase 3 — the spreadsheet (for a COLD session)

Everything else in this plan is done. This section is the brief for the one remaining piece; it
assumes nothing but `docs/architecture/build-and-packaging.md`.

> **⛔ SCOPE, FIXED BY OWNER DECISIONS 2026-07-30 — do not re-open any of the three:**
> **D1** the spreadsheet is `"eager": false` in `parts.json`, NAMED in `homepage.json` (production
> ships it lazily) and NOT named in `lean.json` (the appliance drops it outright) — the exact
> `maps`/`plots` shape; inclusion and timing are different axes.
> **D2** **`dataflow` STAYS IN CORE** — see the amendment box on §4 Phase 3 for the enumeration that
> settled it. Items 3 and 4 below are therefore struck.
> **D3** `SpreadsheetApp` becomes its own EAGER launcher mini-part, `fizzytiles-launcher`-style
> (item 2 below) — forced by D1. ⚠ `lean` must name NEITHER part: a desktop icon that opens nothing
> is worse than no icon, so the guard on the `createOpener` line stays.

### §12.1 State you are starting from
`src/spreadsheet/` (14 files, 116 KB) and `src/dataflow/` (4 files, 36 KB) are still inside `core`'s
`dirs` in `buildSystem/parts.json`. Production (`profiles/homepage.json`) ships
`["core", "meta-tools", "samples", "maps", "plots"]`, of which **`meta-tools`, `maps` and `plots` are
lazy** and `samples` is eager. The production image is 989,482 B.

Everything the earlier phases built is available and should be reused:
- **`world.parts.whenAllLoaded [names], -> …`** — THE await idiom. Runs the callback INLINE when the
  parts are already in; that synchronous fast path is a correctness requirement, not an optimisation
  (§11.2).
- **`world.parts.isAvailable name`** — "did this artifact ship it at all", the question a class
  guard cannot answer for a lazy part.
- **`ensureMetaSystemLoaded()`** — awaited by `_loadPartPromise`; a precompiled tree has no
  `Class`/`Mixin`/`findLoadOrder` until it runs (§11.5).
- **`fg homepage` loads a lazy part and asserts zero eager batches** — the gate that would have
  caught §11.5. It picks whatever the manifest says is lazy, so it will cover a new lazy part free.

### §12.2 The four things that make this one harder than maps and plots
1. **1 core edge each, but neither is sample content.** `WorldWdgt.coffee:626`
   `(new SpreadsheetApp).createOpener exampleDocsFolder` and `:466` `@dataflow = new DataflowEngine`.
   Re-verify with `node buildSystem/check-part-edges.js`, never a grep.
2. **⚠⚠ A LAUNCHER SPLIT IS MANDATORY for a lazy spreadsheet.** `SpreadsheetApp.coffee` lives INSIDE
   `src/spreadsheet/`, and `createDesktop` calls `createOpener` on it AT BOOT to place the Examples
   icon. Make that directory lazy and the icon disappears. This is exactly the
   `fizzytiles` / `fizzytiles-launcher` shape: the launcher class (and its icon) must be its own
   EAGER part, the engine lazy. `maps` and `plots` needed no such split because their doors are apps
   that already existed in core.
3. ~~**dataflow is a WORLD COLLABORATOR, not an app**~~ — **STRUCK by D2.** The R-2 enumeration was
   run and it is exactly why: `doOneCycle` drains `recalculateDataflow` every cycle, and 14 call
   sites across `Widget`, `ControllerMixin`, `SliderWdgt`, `SimpleTextWdgt`, `StringWdgt`,
   `PaletteWdgt`, `PatchNodeWdgt` and `WellKnownObjects` soak the engine's absence syntactically but
   not semantically. The plan's own instruction was *"if one cannot be soaked, STOP: the partition is
   drawn wrong there"* — that is the finding, and D2 is it. dataflow stays in core.
4. ~~**spreadsheet REQUIRES dataflow** … the door must name BOTH~~ — **MOOT under D2.** dataflow is
   core, so it is always present, and the spreadsheet's door names ONE part. The missing part→part
   `requires` mechanism (§11.1) does not matter for this phase.

### §12.3 Suite exposure
19 spreadsheet + 1 dataflow SystemTests. They should NOT churn: `dev` ships `"parts": "all"` and the
harness page presets `FIZZYGUM_EAGER_ALL_PARTS`. **Any reference churn means something moved that
should not have — do not recapture, find the cause** (R-6).

### §12.4 Expected payoff
~68 KB (spreadsheet) off the production image, ESTIMATED from the 59% source→image ratio the `maps`
split actually produced. (The ~21 KB that `dataflow` would have added is off the table under D2.)
⚠ Treat as unverified until measured — the same estimate understated `maps` by 33%.

### §12.5 Verification
Unchanged from §7, plus: take fingerprint baselines for dev/homepage/lean BEFORE touching anything
(`Fizzygum-tests/.scratch/take-baselines-slices.sh <tag>`, gitignored), predict each delta in words,
then compare. `fg gauntlet` · `fg homepage` · `build_and_smoke.sh --profile lean`.

---

## §13 PHASE 3 EXECUTION RECORD — 2026-07-30 (the spreadsheet; dataflow deliberately NOT extracted)

**Ran under owner decisions D1 (lazy, production ships it, `lean` drops it), D2 (dataflow stays in
core) and D3 (a separate eager launcher part).** All three held; nothing in execution argued back.

### §13.1 What landed
| | |
|---|---|
| `src/spreadsheet-launcher/SpreadsheetApp.coffee` | moved out of `src/spreadsheet/` (`git mv`) — the whole of the new EAGER part |
| `parts.json` | `src/spreadsheet` leaves `core`; new `spreadsheet` (12 classes, `eager: false`) + `spreadsheet-launcher` (1 class, eager) |
| `WorldWdgt.createDesktop` | the ONE core edge gains `if SpreadsheetApp?` — asked of the EAGER half, so a plain guard is right |
| `SpreadsheetApp.launch` | `world.parts.whenAllLoaded ["spreadsheet"], => super()` |
| `profiles/homepage.json` | names both new parts; `lean.json` names neither, by design |
| `smoke-boot-headless.js` | the lazy-part probe now LOOPS over every lazy part (see §13.4) |

### §13.2 The edges, re-measured with the gate (never a grep)
`node buildSystem/check-part-edges.js` with `src/spreadsheet` moved to a scratch part:
**1 unguarded reference** (`src/WorldWdgt.coffee:629`), **0 inheritance edges** — exactly what
§12.2 predicted. After the work: **0 unguarded, 0 inheritance**, and `check-shippable-coverage`
clean with the new directory claimed.

### §13.3 ⚠⚠ MEASURED — AND THE PAYOFF ESTIMATE WAS 50% HIGH (the finding of this phase)

| Tree | Before | After | Δ |
|---|---|---|---|
| `homepage` `js/pre-compiled.js` | 989,482 B | **955,796 B** | **−33,686 B (−3.40%)** |
| `lean` `js/pre-compiled.js` | 980,440 B | **945,796 B** | **−34,644 B (−3.53%)** |
| `spreadsheet` source batch (ships, fetched on demand) | — | 119,408 B | new |
| `spreadsheet-launcher` source batch (eager) | — | 3,407 B | new |
| Stored sources, dev / homepage | 502 / 434 | 502 / 434 | unchanged |
| production tree | 29 files / 3,539,265 B | 30 files / 3,507,984 B | −31,281 B |

§12.4 predicted **~68 KB** off the image. The truth is **33.7 KB — half of it.** The cause is
measurable and worth carrying forward, because it invalidates the estimator, not just the estimate:

| Slice | total source | comment bytes | code bytes |
|---|---|---|---|
| `src/maps` | 88,247 | 2,175 (**2.5%**) | 86,047 |
| `src/spreadsheet` | 112,095 | 80,873 (**72.1%**) | 31,079 |

§12.4's ratio was calibrated on `maps`, which is vector-path ARTWORK and essentially all code. The
spreadsheet is 72% comment bytes, and **comments never reach a compiled, minified image**. ⇒ the
same estimator was 33% LOW for `maps` and 50% HIGH here. ⚖ **Estimate from CODE bytes, not source
bytes — and treat even that as a guess until two builds have been fingerprinted.**

The `lean` drop is 958 B LARGER than production's, and that number is exactly `SpreadsheetApp`'s
compiled contribution: production keeps the eager launcher in its image, `lean` ships neither part.
Cross-checked independently — the homepage-minus-lean image gap went 9,042 → 10,000 B.

**Every other delta was predicted before being measured**, in `.scratch/p3-predictions.md`. Two were
not exactly right, both benign and in the same mechanism: the predicted file count was +2 per tree
but is **+1**, because core losing ~116 KB of source made its numbered batches re-pack from 12 into
11 — `sources_batch_11.js` disappears while the two part batches appear; and only TWO core batches
changed content (`_10` −86 KB, `_3` +458 B) rather than "many". The boot bundles grew +405 B on the
trees that gained parts (the `FIZZYGUM_PARTS` manifest is concatenated into them) and SHRANK 19 B on
`lean` — one dropped `"sources_batch_11",` entry. Nothing unaccounted-for appeared in any of the
three fingerprints.

### §13.4 The gate would NOT have covered this part — so the gate changed
`fg homepage`'s lazy-part assertion took `Object.keys(FIZZYGUM_PARTS).find(eager === false)`, and
the manifest is written `sort_keys=True` — so it always picked the alphabetically first lazy part,
`maps`, and would have gone on picking it. `spreadsheet` would have shipped in production **never
once loaded by any gate** — precisely the §11.5 shape ("a capability's FIRST use on a given artifact
shape is untested by construction"). **Decision: loop it over every lazy part.** It now reports
`maps`, `meta-tools`, `plots` and `spreadsheet`, asserting per part: absent at boot, all classes
arrive, zero eager batches dragged in. ⚠ Coverage is deliberately not uniform and the code says so:
only the FIRST load runs on a tree with no meta-system, so only it proves the §11.5 bootstrap.
The probe is also now skipped on pages presetting `FIZZYGUM_EAGER_ALL_PARTS`, where "absent at boot"
is false by design.

### §13.5 Zero reference churn
As required by R-6, and it held: `fg gauntlet` green with no recapture — dpr1, dpr2 and webkit each
269 tests, 0 failed, 0 geometry violations. `dev` ships `"parts": "all"` and the harness page presets
`FIZZYGUM_EAGER_ALL_PARTS`, so `whenAllLoaded` takes its inline path and the 19 spreadsheet tests —
several of which do `world.evaluateString "(new SpreadsheetApp).launch()"` and then read the sheet in
the same macro step — see exactly the cycles they saw before.

### §13.6 ⚠ THE GATE THAT DID FIRE: the serialization rig, and why it was RIGHT to
The first full gauntlet came back **13/14, with `serialization` a hard FAIL** — 11 mismatches, all
`SimpleSpreadsheetWdgt is not defined`, all on the NATIVE leg, while the SWCanvas leg passed clean.
That asymmetry is the whole diagnosis: `serialization-roundtrip-headless.js` builds its fixtures by
naming classes directly (`new SimpleSpreadsheetWdgt()`), it boots **`index.html`** — the one dev-tree
page where laziness is REAL — and `index-sw.html` presets `FIZZYGUM_EAGER_ALL_PARTS`. Until this
phase the rig had never touched a lazy part's class on the native page (the one phase that uses
`ClassInspectorWdgt` is SW-only), so the gap had never been visible.

**This was the rig catching up with the product, not a product defect** — the product's own paths
both do the right thing already (`SpreadsheetApp.launch` awaits; `loadWorldSnapshot` pre-scans a
snapshot's class names and loads the parts they need). A harness naming the class as a bare symbol
has to do what those doors do. Fix: `bootPage` — the single funnel every rig page goes through — now
loads **every** lazy part the tree ships, before any fixture is built. Self-maintaining (a new lazy
part joins for free), and it restores the rig's own premise: the same structural checks under both
backends, differing in the renderer and not in which parts happen to be resident.
⚖ **Net gain in coverage:** the 22 spreadsheet checks now run against classes that arrived through
an ON-DEMAND part load, which is closer to the shipped path than what they exercised before.

### §13.7 ⚠ A PRE-EXISTING DEFECT FOUND, NOT INTRODUCED — two core doors are dead on `lean`
Found while reasoning about whether the spreadsheet door needed an `isAvailable` check, then
**verified empirically** on a built `lean` tree (`Fizzygum-tests/.scratch/lean-door-probe.js`):

```
partsShipped: ["core"] · dashboardsAppExists: true · mapsAvailable: false
(new DashboardsApp()).launch()  ->  windows before 0, after 0
pageerror: Fizzygum: no such part 'maps' in this build.
```

`DashboardsApp.launch` and `SimpleSlideApp.launch` are CORE classes whose openers `createDesktop`
creates unguarded, and they call `world.parts.whenAllLoaded ["maps", "plots"]` / `["maps"]` with no
`isAvailable` check first. On `lean`, which ships neither part, `ensureLoaded` REJECTS, `super()`
never runs, and the icon is dead — an unhandled rejection and no window. `PartsRegistry`'s own header
states the rule that would have prevented it: *"Ask `isAvailable` FIRST at any door that a profile may
not ship at all"* — which `Widget.spawnInspector` does and these two do not.

It predates Phase 3 (it arrived with the `maps` and `plots` phases, `eed2f2f2` / `058ea35f`) and
Phase 3's own door was never affected — `lean` ships neither spreadsheet part, so there is no icon to
click. **FIXED 2026-07-31 on owner instruction**, and the fix names the rule rather than repeating it:

```coffee
# PartsRegistry — next to whenAllLoaded, because the choice between them is the point
whenOptionalPartsLoaded: (partNames, thenDo) ->
  @whenAllLoaded (eachName for eachName in partNames when @isAvailable eachName), thenDo
```

`DashboardsApp.launch` and `SimpleSlideApp.launch` now call it. ⚖ **The general rule, now recorded in
`docs/architecture/build-and-packaging.md` §2:** `whenAllLoaded` is for parts that CONSTITUTE the
result (a `Sample*App` builds plots — without them it is broken, not reduced, so rejecting is
right); `whenOptionalPartsLoaded` is for parts that ENRICH it (a docked palette with fewer tools).
Only the two core doors changed: the six `DemoMenus` sites and the three `Sample*App`s genuinely
require their parts — filtering there would run the callback and then throw on an undefined class,
which is strictly worse than a clean rejection.

**Verified both directions.** On a rebuilt `lean` tree the probe now reports
`new children: DashboardWdgt, DocumentWdgt` and zero page errors, where before it reported no window
and `pageerror: no such part 'maps' in this build`. Where the parts ARE available (dev, homepage) the
filter is the identity, so behaviour is unchanged — and the inline already-loaded fast path is
untouched, since `whenOptionalPartsLoaded` delegates straight to `whenAllLoaded`.

---

## §10 References

- `docs/architecture/build-and-packaging.md` — **the current-state reference; read first**
- `docs/archive/build-arc-4-dynamic-parts-plan.md` — the partition, §0.1 program table, P-D2
  (mixed directories), R6 (inclusion ≠ eagerness)
- `docs/archive/build-arc-5-packaging-profiles-plan.md` — profiles, the `sources` axis, the
  `meta-tools` split as the worked example, and the per-part-sources measurement this plan follows on
  from
- `buildSystem/check-part-edges.js` — the gate that produced §2.2; read its header before trusting a
  grep over it
- memory: `build-arc-5-packaging-profiles-arc.md`, `build-arc-4-dynamic-parts-arc.md`
