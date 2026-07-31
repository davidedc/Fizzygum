# Cutting Fizzygum's boot cost — the pre-compiled dev tree, and maximal laziness

**PLAN. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything needed
is embedded here or one named-doc hop away. Line numbers WILL drift — the quoted symbol or filename
is authoritative, re-grep before editing.

**Owner mandate, 2026-07-31:** *"I want to chase both. I want EVERYTHING that can be lazy-loaded to
be lazy loaded, and as well I'm happy to look into the precompiled build."*

---

## §0 Orientation

**Fizzygum** is a CoffeeScript GUI framework rendered on one HTML5 canvas. There is **no module
system**: every class is a global, shipped as escaped TEXT and compiled *in the browser* at boot —
unless the profile says `form: "precompiled"`, in which case the world starts from a pre-built image.
`buildSystem/parts.json` is the PARTITION (named slices that can be absent, or loaded on demand);
`buildSystem/profiles/*.json` selects which ship. **Read `docs/architecture/build-and-packaging.md`
first** — §2 (lazy-part rules) and §5 (the reflective layer) are load-bearing here. The runtime half
is illustrated by `docs/explainers/boot-and-lazy-parts.html`.

### §0.1 The measurement that started this — do not re-derive it
Full write-up + method: **`docs/measurements/boot-timing-2026-07-31.md`**. Probe (gitignored):
`Fizzygum-tests/.scratch/boot-timing-probe.js`. Marker = time to world-ready, which on the
compile-at-boot path means every eager source fetched, compiled AND executed.

| page | world ready |
|---|---:|
| `homepage` (precompiled, `sources: lazy`) | **54 ms** |
| `dev` `index.html` (compile-at-boot) — *the page the owner actually opens* | **3219 ms** |
| `dev` `index.html`, every non-core part flipped lazy — **the floor** | **2680 ms** |
| `dev` `index.html`, built PRE-COMPILED (spike) | **59 ms** |

- 97% of the 3219 ms is compile+execute; all 22 source files are fetched by 103 ms.
- Marginal cost **~8.6 ms per source**; core alone is **389 of 452 sources** and cannot be lazy.
- Pre-compiling `dev` cost **+5.3 s per build** (12.2 s → 17.5 s) for **−3.16 s per page load**.

⚠⚠ **THE TWO TRACKS INTERACT.** Track A takes dev boot to ~59 ms, which **removes the dev-boot
justification for Track B** (17% of 3.2 s is worth chasing; 17% of 59 ms is not). After Track A,
Track B must stand on its other two legs — production DOWNLOAD bytes, and partition UNIFORMITY —
both of which the owner has affirmed independently. **Do Track A first, and re-read this line before
justifying Track B's scope on speed.**

---

## §1 TRACK A — a pre-compiled `dev` tree

**Prize: 3219 ms → ~59 ms on the page the owner opens all day, with every class still present.**
Arc 5 (PR-D5) declined this for `dev` on the ground that it "would add a headless boot-and-harvest to
every ~18 s build" — a real cost, now measured at +5.3 s, against a saving that was never measured.

### §1.1 What it is
A profile is four facts, and adding a flavour is adding a file. The spike was literally:
```json
{ "parts": "all", "form": "precompiled", "sources": "lazy", "entries": "all" }
```
(The spike used `sources: "background"`; **use `"lazy"`** — see §1.3.)

### §1.1b ✅ EXECUTED 2026-07-31 — `buildSystem/profiles/dev-precompiled.json` exists and works

```json
{ "parts": "all", "form": "precompiled", "sources": "lazy", "entries": ["index.html"] }
```

**Measured: 60 ms** (from 3219 ms), all 227 `*Wdgt` classes present, every part shipped. Boot smoke
green on every assertion — all five lazy parts absent at boot, loading on demand, dragging in zero
eager batches; inspectors work (27 files, 500 sources ingested).

⚠⚠ **THE FINDING THAT SHAPED IT — ONE IMAGE CANNOT SERVE TWO PAGES WITH DIFFERENT EAGERNESS.**
The first attempt shipped all three entry pages and FAILED on `index-sw.html` with
`Cannot set properties of undefined (setting 'class')`, twice. Root cause, traced not guessed: a
pre-compiled image is harvested by booting ONE page — `index.html?generatePreCompiled` — where lazy
parts do not load, so the image lacks their classes (48 today). `index-sw.html` and
`worldWithSystemTestHarness.html` preset `FIZZYGUM_EAGER_ALL_PARTS`, so on those pages the reflective
layer ingests EVERY part's sources, and ingest-only mode runs `window[@name].class = @`
(`src/meta/Class.coffee:455`) against a class the image never defined. Production never hit this
because it ships `index.html` alone. **Resolution: this profile ships `index.html` alone too** — which
also retires §1.2's questions 1 and 4 outright, since the suite keeps running on the untouched
compile-at-boot `dev`.

⇒ **A future profile that is `precompiled` AND ships an eager-all-parts page needs either two images
or an ingest that tolerates a class the image lacks. Neither exists. Do not spec one without
re-reading this.**

### §1.2 The open questions — questions 1 and 4 are RETIRED by §1.1b
1. **⚠⚠ Does the SystemTest suite survive a PRE-COMPILED `worldWithSystemTestHarness.html`?**
   Nobody has ever run it that way. The suite is byte-exact and cycle-sensitive
   (`../Fizzygum-tests/DETERMINISM.md`); a different boot path could shift cycle counts. **This is
   the whole risk of Track A.** Answer it with a full `fg gauntlet` against a dev-precompiled tree
   BEFORE anything else. If references churn, do NOT recapture — that is the finding.
2. **Does `?generatePreCompiled` work on a tree that ships the harness?** The production profile
   excludes `harness`, so the driver has never harvested a harness-carrying tree. The spike built
   clean with `parts: "all"`, so this is probably fine — confirm, don't assume.
3. **Is it a new profile, or does `dev` change?** A new `dev-precompiled` leaves the inner loop
   untouched and is opt-in; changing `dev` itself makes every build pay +5.3 s. Recommend: **new
   profile first**, promote later if it proves out.
4. **Does `build_and_test.sh` / `fg suite` need to know?** They gate on whether the profile ships
   tests, which is unchanged. Verify the suite runner accepts a precompiled tree.

### §1.3 ⚠ A gate false-positive this WILL hit
The spike's boot smoke reported `loading "fizzytiles" pulled 8 EAGER batch(es) — that is the whole
saving handed back`. Diagnosis (believed, **not yet proven**): on `precompiled + sources:
"background"` the reflective layer fetches core's eager batches *behind the running world*, and
`smoke-boot-headless.js`'s per-part counter attributes those concurrent fetches to the part load.
Production is `precompiled + lazy`, where nothing fetches in the background, so the gate is correct
there. **Two fixes, pick one:** use `sources: "lazy"` for the new profile (recommended — it also
matches production), or teach the counter to discount fetches already in flight. Either way,
**prove the diagnosis** (e.g. build the same profile with `sources: "lazy"` and watch the FAIL
disappear) rather than assuming it.

### §1.4 Exit criteria
`fg gauntlet` green against the dev-precompiled tree with **zero reference churn**; boot smoke clean
on all three entry pages; the boot-timing probe reproducing ~59 ms; build-time delta re-measured.

---

## §2 TRACK B — everything that can be lazy, actually lazy

### §2.1 Where core's mass actually is (measured 2026-07-31)
`core` = **389 files**. By directory, sorted by file count:

| dir | files | CODE bytes | lazy-able? |
|---|---:|---:|---|
| **`src/icons`** | **143** | **198,247** | **⭐ THE BIG ONE — see §2.2** |
| `src` (root) | 99 | 274,085 | mostly not: WorldWdgt + the widget substrate |
| `src/buttons` | 38 | 19,469 | mostly yes — creator buttons for toolbars |
| `src/basic-widgets` | 21 | 206,177 | no — the substrate |
| `src/events-input` | 21 | 6,168 | no |
| `src/apps` | 19 | 32,567 | yes — the §2.3 family |
| `src/toolbars` | 8 | 18,862 | likely, with their buttons |
| `src/serialization` | 8 | 25,152 | no |
| others (mixins, menu-system, basic-data-structures, dataflow, patch-programming, meta, info-widgets, duplication) | 32 | ~110,000 | no — substrate; ⛔ `src/dataflow` is settled core, see `core-app-slices-partition-plan.md` §4 |

### §2.2a ✅ THE ICONS ANALYSIS — done 2026-07-31, with the gate, not a grep

`src/icons` = **143 files: 62 `*IconWdgt` + 81 `*IconAppearance`** (not 1:1 — several widgets carry
more than one appearance). Moving the whole directory to a scratch part and running
`check-part-edges.js`:

> **111 unguarded references, 0 inheritance edges.** Structurally extractable; the work is all
> references, no partition error.

**Core names 70 of the 143** (39 Wdgt + 31 Appearance), and the naming is concentrated:

| namer | refs | can it await? |
|---|---:|---|
| `src/buttons` (creator buttons) | 37 | ⛔ **NO** — no async seam, so button and icon must land in the SAME part |
| `src/toolbars` | 35 | the palette itself can, but it hosts the buttons |
| `src/apps` | 25 | yes — but the ~11 desktop launcher icons are needed AT BOOT and stay eager |
| the rest (bin, folder/document/script shortcuts, `IconWdgt`, `ScriptWdgt`, …) | 14 | genuinely core |

⇒ **"Make the icons lazy" is not one job.** Because a creator button cannot await, the unit that can
move is **a toolbar + its buttons + their icons, together** — exactly the shape `plots` already has
(`PlotsToolbarWdgt` + its four buttons live inside the part). Icons alone cannot be a part.

**The 23 `*IconWdgt` classes core never names** — where they actually belong:

| home | count | note |
|---|---:|---|
| `demos` (`DemoMenus` names them) | **21** | Align*/Bold/Italic/font-size/Text/Templates/Welcome/… |
| `meta-tools` | 1 | `AngledArrowUpLeftIconWdgt` |
| nobody outside `src/icons` | 1 | `GenericCompositeIconWdgt` — sibling-used or dead; check before moving |

⚠ **A pair can be split across parts, and one already would be:** `maps` names
`LittleWorldIconAppearance` while only `demos` names `LittleWorldIconWdgt`. Verify each Appearance's
users independently of its Wdgt before moving either.

⚠⚠ **Moving those 21 into `demos` saves NOTHING on its own** — `demos` is an EAGER part, so its
classes compile at boot exactly as core's do. The saving needs `demos` to become LAZY as well, which
means its doors (`demoMenus.createX()`, currently reached behind `if DemoMenus?`) must await. That is
a separate decision from re-homing the icons, and it should be taken deliberately rather than as a
side effect.

### §2.2b The decomposition that follows (pick per slice; each is independently gated)
1. **Re-home the 23 free icons** into `demos` / `meta-tools`. Zero core edges, pure tidying, no
   speed win by itself. Cheapest, safest, makes every later slice smaller.
2. **Make `demos` lazy** — with 21 icon pairs re-homed it is a large eager block; needs awaiting
   doors on the demo menu items.
3. **Toolbar-shaped parts** — a toolbar + its buttons + their icons, per toolbar. This is where the
   37+35 references live and where the real class count is. The `plots` part is the worked example.
4. **The launcher icons stay eager forever** (~11 of them): `createDesktop` draws them at boot.

### §2.2 ⭐ `src/icons` is 37% of core's files — the original note
143 icon classes; only the handful drawn on the desktop **at boot** (the app launcher icons —
`FloppyDiskIconWdgt`, `TypewriterIconWdgt`, `PaintBucketIconWdgt`, `GenericShortcutIconWdgt`, …) are
needed eagerly. If ~128 of them can move behind a lazy part, that is **the single biggest item in
this plan** — order 500 ms–1.1 s of dev boot depending on whether compile cost tracks files or bytes
(unmeasured; measure before promising).
**First step is analysis, not code:** for each icon class, is it constructed at boot? The authority
is `check-part-edges.js`, never a grep (it strips comments — prose naming a class caused two false
hits in a previous arc). ⚠ An icon reached from a creator button cannot await (a creator button has
no async seam), so button and icon must land in the same part.

### §2.3 The GenericPanel / Document family — already analysed
Moving these **together** collapses the inheritance web: `GenericPanelWdgt` alone shows 4 inheritance
edges, but the whole family shows **1** (only `WelcomeMessageInfoWdgt extends DocumentWdgt`, fixed by
moving that file too). 10 files, 14.1 KB code. ⚠ Needs **no** part→part `requires` mechanism: within
ONE part, `_ingestPartPromise` already orders by `findLoadOrder()`.
Members: `GenericPanelWdgt`, `DashboardWdgt`, `ImageWdgt`, `PatchProgrammingWdgt`, `SlideWdgt`,
`DocumentWdgt`, `PatchNodeWdgt`, `CalculatingPatchNodeWdgt`, `SuperToolbarWdgt`,
`WelcomeMessageInfoWdgt`. Residual: 14 references — 9 app `buildWindow`s (launcher-split doors),
2 creator buttons (must move INTO the part), `InfoDocs:178` (needs a look).

### §2.4 `samples` — a timing change plus three splits
Already a part, currently EAGER. ⚠ It cannot simply be flipped: each `Sample*App` holds its
document-assembly in its own `buildWindow`, and the class is needed at boot for its icon — so each
needs a launcher/builder split (3 new classes) for 9.4 KB of code.

### §2.5 The rules every item obeys (all established, all with precedent)
- **Anything reached at BOOT forces a launcher split** — `createDesktop` builds each icon by
  constructing its app. Precedents: `fizzytiles`/`fizzytiles-launcher`,
  `spreadsheet`/`spreadsheet-launcher`. A profile must name both parts or neither.
- **A creator button CANNOT await** (`mouseClickLeft`/`grabbedWidgetSwitcheroo` consume
  `createWidgetToBeHandled()`'s return value synchronously) ⇒ put it IN the part it creates from.
- **`whenAllLoaded` vs `whenOptionalPartsLoaded`** — required vs optional; getting it wrong is
  silent (it made two desktop icons dead on `lean`). See `build-and-packaging.md` §2.
- **The inline already-loaded path is CORRECTNESS**, not optimisation — the suite measures cycles.
- **Inheritance from EAGER core into a lazy part is fatal**; move the whole family and it dissolves.

### §2.6 Exit criteria per item
`check-part-edges.js` at 0 unguarded / 0 inheritance · `fg gauntlet` green with **zero reference
churn** · `fg homepage` · `build_and_smoke.sh --profile lean` · fingerprints for dev/homepage/lean
with every delta predicted IN WORDS before measuring · the boot probe re-run to book the actual win.

---

## §3 Verification protocol (both tracks)
All via `/Users/davidedellacasa/code/Fizzygum-all/fg`. Long ops: launch ONCE in the background with a
log and wait for the notification; peek with `cat /tmp/fg-<cmd>.verdict`.
⚠ **A running `fg` op OWNS its inputs AND the build tree** — never edit `src/`/`tests/` mid-run, and
never run two builds at once (both write `Fizzygum-builds/latest`; doing so once produced a spurious
lean-smoke FAIL).
⚠ **Estimate payoff from CODE bytes, never source bytes** — `src/spreadsheet` is 72% comments,
`src/maps` 2.5%, and comments never reach a compiled image. The one ratio calibrated on maps ran 33%
low for maps and 50% high for the spreadsheet. Treat every estimate as a guess until two builds have
been fingerprinted.

## §4 Rejected / do-not-re-attempt
1. **Extracting `src/dataflow`** — settled core (owner decision; `core-app-slices-partition-plan.md`
   §4 Phase 3). It is the wiring substrate, and its absence is silently accepted rather than caught.
2. **Justifying laziness by PRODUCTION boot speed** — measured at 54 ms; a 1.6% slice buys ~0.5 ms.
3. **Expecting the SUITE to benefit from laziness** — the harness and SWCanvas pages preset
   `FIZZYGUM_EAGER_ALL_PARTS` on purpose, so they compile everything regardless.
