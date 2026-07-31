# Cutting Fizzygum's boot cost — the pre-compiled dev tree, and maximal laziness

**PLAN. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything needed
is embedded here or one named-doc hop away. Line numbers WILL drift — the quoted symbol or filename
is authoritative, re-grep before editing.

**Owner mandate, 2026-07-31:** *"I want to chase both. I want EVERYTHING that can be lazy-loaded to
be lazy loaded, and as well I'm happy to look into the precompiled build."* When told the boot-speed
case had evaporated (a precompiled dev tree boots in 60 ms), the owner reaffirmed the scope anyway:
*"This is about uniformity at this point."* ⇒ uniformity and production DOWNLOAD bytes are standing
reasons here; **boot speed is not** — see §0.1.

> ## ⏩ WHERE THIS ARC IS, 2026-07-31 — read this first
> **Track A: DONE** (§1.1b, `f1ab5d40`). **Track B slices 1-3: DONE and PUSHED.**
> `50cbf48b` icons re-homed · `e39392bf` `demos` lazy · `9acadaab` the `authoring` +
> `authoring-launcher` split (production `js/pre-compiled.js` **−9.8%**, `lean` **−11.4%**, dev
> `index.html` 3219 → 2711 ms) · `eb2bd955` four broken doors the new analysis found ·
> `510c1e74` a part→part **`requires` mechanism** and a gate that covers those edges ·
> `b6173e12` the palette fix + the tooling below.
>
> **⏳ NEXT: §2.2d — SLICE 4.** It is fully designed and self-contained; start there.
> **Tools it depends on, all committed:** `node buildSystem/pinned-by-lazy-parts.js --list` (the work
> list), `fg hypopart <files…>` (evaluate a grouping BEFORE moving a file), `fg fingerprint
> [profile] [baseref]` (measure the payoff instead of estimating it).
> **Rules that cost a re-run in slices 1-3:** §2.5, and §2.2d's own "the gate that does not exist".

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
1. ✅ **DONE — `50cbf48b`. Re-home the free icons** into `demos` / `meta-tools`. 25 files
   (20 `*IconWdgt` + the 5 `*IconAppearance` whose only namer was their own moving widget), into the
   new `src/demos-icons/` and into `src/meta-tools/`. Core 389 → 364 sources. Gauntlet 14/14, zero
   churn. ⚠ Two classes were pulled back OUT of the candidate list because an early filter excluded
   `src/icons/` and hid SIBLING references: `GenericCompositeIconWdgt` (base class of the BOOT icon
   `GenericShortcutIconWdgt`) and `ObjectIconWdgt`/`ShortcutArrowIconWdgt` (used by those same
   staying classes). ⚠ 13 `*IconAppearance` are named DIRECTLY by core toolbar buttons, so only
   their widget moved — the pair does NOT travel as a unit.
2. ✅ **DONE — `e39392bf`. `demos` is lazy.** 28 classes. dev `index.html` 3219 → **2931 ms**,
   vault 452 → 422. ⚠⚠ Its doors are MENU ITEMS, a shape no earlier lazy part had — see the
   `//eager` note in `parts.json` and `WorldWdgt.popUpDemoTestMenu`. ⚠⚠ **The doors live on
   WorldWdgt, NOT Widget, and must not move back**: a public member on `Widget.prototype` is listed
   by every inspector and failed `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`
   (fixture: a `RectangleWdgt`). The menu passes the widget through the ARGUMENTS, not the target,
   so `world` serves both call sites and the references stay untouched.
3. ✅ **DONE — the `authoring` + `authoring-launcher` pair.** ⚠ **This slice's PLANNED SHAPE WAS
   FALSIFIED before a line was written.** "A toolbar + its buttons + their icons, per toolbar" is
   not extractable, and the measurement said so twice over:
   - Each docked palette is reached from its host's **synchronous `buildToolbar` hook** — a pure
     factory with no seam to await through (`DocumentWdgt`→`TextToolbarWdgt`,
     `SlideWdgt`→`SlidesToolbarWdgt`, `DashboardWdgt`→`DashboardsToolbarWdgt`,
     `ImageWdgt`→`PaintToolbarWdgt`). A toolbar cannot leave without its host.
   - Those hosts are ONE INHERITANCE FAMILY (`… extends GenericPanelWdgt`), and cross-part
     inheritance is a race whatever the doors say — `ensureAllLoaded` is a `Promise.all`, so two
     parts named at one door load concurrently and nothing orders them. **An inheritance family is
     indivisible.** ⇒ one part, forced, not chosen.

   Landed as **54 lazy classes** (7 content widgets + 7 toolbars + 28 buttons + `InfoDocs` + 11 icon
   appearances, 94.3 KB source / **71.0 KB code**) behind an EAGER 9-class launcher part. Core
   **364 → 301** sources. ⚠ Left behind, each for a stated reason: `ToolbarWdgt` /
   `CreatorButtonWdgt` / `ToolbarCreatorButtonWdgt` (the lazy `plots` part extends all three), the 8
   window-chrome buttons, and `PatchNodeWdgt` + `CalculatingPatchNodeWdgt` (the EAGER
   `patch-programming-experimental` part extends them, so they must exist at boot).
4. **The launcher icons stay eager forever** (~11 of them): `createDesktop` draws them at boot.

### §2.2c-post What slice 3 actually taught (read before attempting slice 4)

1. ⚠⚠ **THERE IS NO PART→PART `requires` MECHANISM — and two authored facts disagreed about it.**
   `parts.json`'s spreadsheet note said there is none (right); `check-part-edges.js`'s header said
   part-to-part references are "legitimate when the manifest declares the dependency" (**wrong** —
   the manifest carries `{batches, eager, vendor, classes}` and nothing else; that comment is now
   fixed). What stands in for one is a DOOR naming several parts, `whenAllLoaded ["maps", "plots",
   "authoring"]`, and **nothing verifies the pairing** because the gate scans core only. When you add
   a part→part edge, say so at the door. ⛔ And it does **not** cover inheritance — see item 3.
2. ⚠⚠ **A LAUNCHER LEFT IN CORE CANNOT AWAIT ITS WAY OUT.** All nine Maker apps had a correct
   `launch: -> world.parts.whenAllLoaded ["authoring"], => super()` and the build still failed: each
   `buildWindow: -> world.openFrameWith (new DocumentWdgt), …` is an unguarded core→part reference,
   and the gate reads one line at a time. That is the gate being RIGHT — a human reader cannot see
   the await either, and nothing forces `buildWindow` to be reached through `launch`. The fix is
   partition (move the launchers into their own eager part), never an allowlist. **So the
   launcher-split rule has a second reason nobody had written down: it is what makes the await
   legible to the gate.**
3. ⚠ **A CLASS NAMED BY ANY LAZY PART IS PINNED TO CORE.** This is what shrank the icon follow-on
   from 71 files to 11: `demos` names `ArrowNIconWdgt`, `BrushIconWdgt`, `MapPinIconWdgt` and ~57
   more, and part→core is the safe direction that has to keep working. Moving them would need every
   door that pulls `demos` in to also name the new part. **Slice 2 therefore made slice 3 smaller** —
   worth knowing before assuming slices compose additively.
4. ⚠ **`lean` COULD NOT TAKE THIS PART, and that is a product-visible consequence:**
   `buildProfile.py` refuses a lazy part on `sources: "none"`. So the appliance now has no Makers and
   (correctly) no icons for them. An appliance that wants them back wants `sources: "lazy"`.
5. **MEASURED payoff** (fingerprints `s3base-*` / `s3cand-*`, both trees built, nothing estimated):

   | tree | `js/pre-compiled.js` | change |
   |---|---|---:|
   | `homepage` | 936,920 → 845,004 B | **−91,916 B (−9.8%)** |
   | `lean` | 926,920 → 821,162 B | **−105,758 B (−11.4%)** |

   Production ships 411 sources on both sides, the same names, only their `part=` differing for 63 —
   a packaging change, not a visible one. dev `index.html` 2931 → **2711 ms**, vault 422 → 368.
   ⚠ Two estimates missed: the image saving was **2.2× LARGER** than a bytes-of-code estimate
   (class count drives the image, not source bytes) and the boot saving **2× SMALLER** than the flat
   8.6 ms/source rate (these are small classes). ⚠ The boot bundle GREW 1,857 B — the parts manifest
   must carry both new parts' class-name lists. Both recorded in `build-and-packaging.md` §5.
6. ⚠ **HOW TO GET A REAL "BEFORE" FINGERPRINT, and the trap in it.** There was no pre-slice baseline
   on disk, and `git stash` is banned here. What works is a sibling worktree —
   `git worktree add ../../Fizzygum-baseline/Fizzygum HEAD` plus a **worktree (never a symlink)** of
   `Fizzygum-tests`, with only `node_modules` symlinked. ⚠⚠ The first attempt symlinked the whole
   tests repo and the baseline homepage build wrote its 1.85 MB image **into the real
   `Fizzygum-builds/latest`**: `generate-pre-compiled-headless.js` and `build-tree-fingerprint.js`
   both resolve their paths from `__dirname`, so through a symlink they address the REAL tree while
   the build addresses the baseline one. The measurement was void and the live build tree was
   clobbered (harmless — the next build overwrites it — but silent).
7. Tooling built for this, reusable and gitignored, in `../Fizzygum-tests/.scratch/`:
   `hypo-part-edges.js` (reuses the gate's own guard classification against a HYPOTHETICAL part, so
   a grouping can be evaluated before a file is moved), `hypo-icon-followers.js` (greatest-fixpoint
   "which icons could follow"), `hypo-crosspart-edges.js` (the part→part edges the gate does not
   check), `authoring-lazy-probe.js` (drives all nine doors on `index.html`).

### §2.2d SLICE 4 — THE NEXT ONE, designed 2026-07-31. Unpin 48 of the 50; do NOT split per Maker.

**Status: designed, not started.** Slice 3 closed with `parts.json` gaining a `requires` mechanism
(`510c1e74`), and the obvious follow-on — "cross-part inheritance is safe now, so split `authoring`
per Maker" — is **the wrong slice**. The measurement says so.

#### ⛔ Why NOT per-Maker (do not re-derive this)
The whole `authoring` part is ALREADY absent from `js/pre-compiled.js`. Splitting it into
`docs` / `slides` / `dashboards` / `draw` / `patch` / `super-toolbar` therefore saves the production
image **nothing at all** — it only narrows what a user fetches when they open ONE Maker, once, on a
click they made deliberately. It also costs: `GenericPanelWdgt` is the base of four of them and
`DocumentWdgt` backs `InfoDocs` (every Maker's info window), so the shared substrate would need its
own part that all six `require`, and the `//` prose for six parts has to explain a partition whose
payoff is a single on-demand fetch. Keep it on the table for *uniformity* if the owner wants it; do
not sell it on bytes.

#### ⭐ What slice 4 IS: the 50 files pinned to core by lazy parts
`node buildSystem/pinned-by-lazy-parts.js [--list]` measures it: **50 core files, 76.8 KB source /
55.1 KB code, whose ONLY namers are lazy parts.** They sat in core because moving them would have
created an unordered cross-part edge — which is precisely what `requires` now orders.

| pinned by | files | code | where they go |
|---|---:|---:|---|
| `authoring` + `demos` | 32 | 31.0 KB | `authoring`; `demos` then declares `requires: ["authoring"]` |
| `authoring` only | 7 | 9.4 KB | `authoring` — free, no declaration needed |
| `plots` only | 5 | 9.2 KB | `plots` — free (the plot `*IconAppearance`) |
| `demos` + `maps` | 2 | 3.5 KB | `maps`; `demos` declares `requires: ["maps"]` |
| `authoring` + `plots` | 2 | 1.2 KB | ⛔ **STAY IN CORE** — see below |
| `demos` only | 2 | 0.8 KB | `demos` — free |

**Predicted production win.** `demos` ships in NO production profile, so for the 32 the only namer
that survives into production is `authoring` — they leave the image outright. Summing the rows that
production actually carries: **~54 KB of code off `js/pre-compiled.js`** (the 48; the 1.2 KB pair stays), which at slice 3's measured
ratio (71 KB code → 91.9 KB image) is order **−70 KB, roughly another −8%**. ⚠ That ratio is a guess
from one data point and has been wrong in both directions three times — **measure it with
`fg fingerprint homepage` before promising anything.**

#### The DESTINATION of each group — parts own DIRECTORIES, so every move is a `git mv`
There is no per-file membership: a part lists `dirs`. The receiving directories already exist.

| group | → directory | note |
|---|---|---|
| icons + `*IconAppearance` going to `authoring` | `src/authoring-icons/` | the dir slice 3 created for exactly this |
| non-icon widgets going to `authoring` | `src/authoring/` | e.g. `StretchableWidgetContainerWdgt`, `RadioButtonsHolderWdgt` |
| the 5 plot appearances | `src/graphs-plots-charts/` | `plots`' only dir |
| the 2 demo-only widgets | `src/demos/` | |
| the 2 little-map appearances | `src/maps/` | |

#### ⛔ TWO OF THE 50 DO NOT MOVE — decided, do not re-open
`src/toolbars/ToolbarWdgt.coffee` and `src/buttons/ToolbarCreatorButtonWdgt.coffee` (the
`authoring`+`plots` row, 1.2 KB) **stay in core**. `PlotsToolbarWdgt extends ToolbarWdgt` and
`PlotsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt`, so moving them into `authoring`
makes `plots` INHERIT across a part boundary, which would oblige `plots` to declare
`requires: ["authoring"]` — every chart in the system then dragging in the whole Makers part. That is
a large, permanent coupling bought for 1.2 KB. **Not worth it.** ⇒ the real target is **48 files**.

#### ⚠ THE `maps` PAIR NEEDS `requires`, NOT AN AWAIT
`LittleUSAIconAppearance` / `LittleWorldIconAppearance` move to `maps`, and `demos-icons`'
`LittleUSAIconWdgt` / `LittleWorldIconWdgt` then name them from `createAppearance: ->`. That reads
like a method that could await, and it cannot: `CreatorButtonWdgt`'s constructor does
`@appearance = @createAppearance()` and consumes the value synchronously — the same no-async-seam
rule that governs creator buttons. So this one is `demos` declaring `requires: ["maps"]`, full stop.

#### The one open design decision, and the argument both ways
The 32 need `demos` to name `authoring`. Two shapes:
- **`demos requires ["authoring"]`** — one line. Opening any demo menu then pulls the whole Makers
  part in. Costs nothing in production (`demos` ships nowhere) and **deletes** the four per-site
  awaits slice 3 added to `DemoMenus` (`createImageWdgt`, `createSlideWdgt`, `createDocumentWdgt`,
  `createWelcomeMessageWindowAndShortcut`). Recommended.
- **A `whenAllLoaded ["authoring"]` in each of ~32 DemoMenus menu actions** — finer-grained, keeps
  the demo catalogue cheap on the dev page. Mechanical but 32× the edit.
Recommendation: the first. The finer grain buys dev-page bytes on a page that already boots in 60 ms
when built `dev-precompiled`. ⚠ Either way `dev-tools requires ["demos"]` already exists, so the
chain becomes dev-tools → demos → authoring; `checkRequiresGraph` rejects a cycle, so if that ever
closes into one, the partition is wrong rather than the gate.

#### Method (each step independently gated)
1. `node buildSystem/pinned-by-lazy-parts.js --list` → the CURRENT list (the table above is a
   2026-07-31 snapshot and WILL drift; the tool is the authority).
2. Per destination part, **`fg hypopart <files…>` FIRST** — it reports inheritance edges and
   cross-part callers using the gate's own classifier. An inheritance edge means the group is wrong,
   or `requires` must be declared. ⚠ Never answer this with a grep: the classifier strips comments
   and string literals, and prose naming a class produced false verdicts in two previous arcs.
   ⚠⚠ **PASS THE DESTINATION PART'S DIRS TOO** when moving files INTO an existing part —
   `fg hypopart src/authoring src/authoring-icons <the files…>`. The tool models the argument set as
   ONE new part, so without them the destination's own references to the movers read as violations:
   the 7-file `authoring` group alone reports 1 inheritance edge and 18 unguarded references (all
   from `PaintToolbarWdgt`, which is *already* in `authoring`), and reports **0 and 0** once the
   destination is included. Verified 2026-07-31.
3. `git mv` into the directories above, declare `requires` where stated, then `fg build`
   (expect: 0 unguarded references, 0 inheritance edges).
4. `fg gauntlet` 14/14 with **ZERO reference churn** — a screenshot diff is a finding, never a
   recapture. Then `fg homepage` and `cd Fizzygum && ./build_and_smoke.sh --profile lean`.
5. `fg fingerprint homepage` and `fg fingerprint lean` — **predict every delta IN WORDS first**, and
   treat any unpredicted line as a finding.

#### ⚠⚠ THE GATE THAT DOES NOT EXIST: the suite cannot see a laziness defect
The harness page and `index-sw.html` preset `FIZZYGUM_EAGER_ALL_PARTS`, so every part is present
there and the references record a world in which nothing is lazy. **Laziness is only real on
`index.html`, which no test drives.** That blind spot produced three separate defects on 2026-07-31 —
four throwing menu doors, a Super Toolbar offering five palettes instead of six, and a
`SlidesToolbarWdgt` whose contents depended on which door opened it — **every one with a green
gauntlet.** ⇒ "14/14, zero churn" is NOT evidence the lazy path works. Before claiming this slice
done, drive `index.html` with a probe: reuse `../Fizzygum-tests/.scratch/crosspart-door-probe.js`
(menu doors) and `authoring-lazy-probe.js` (the nine Maker doors), and add the demo-menu items whose
icons moved. Assert each class is `undefined` BEFORE and `function` AFTER — absence alone is also
what a broken build looks like.

#### Exit criteria
`pinned-by-lazy-parts.js` reports **only the two deliberately-kept files**; `fg build` 0/0;
`fg gauntlet` 14/14 zero churn; `fg homepage`; lean smoke; both fingerprints taken with predictions
written first; an `index.html` probe green on every door whose classes moved; §2.2d marked DONE with
the measured image delta and this plan's ledger (§2.2b) updated.

### §2.2c Slice 3's starting facts (measured; re-verify with the gate, never a grep)
- `src/toolbars` = 8 files / 18.9 KB code; `src/buttons` = 38 files / 19.5 KB code. Both in `core`,
  so both ship in EVERY profile today.
- 118 files remain in `src/icons`; core names ~39 `*IconWdgt` + ~31 `*IconAppearance` of them.
- ⛔ **A creator button CANNOT await** — `WidgetCreatorAndSmartPlacerOnClickMixin.mouseClickLeft` and
  `CreatorButtonWdgt.grabbedWidgetSwitcheroo` both consume `createWidgetToBeHandled()`'s RETURN
  VALUE synchronously (`ActivePointerWdgt` line ~1026; `ButtonWdgt` dispatches
  `@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, …`). So button and icon
  must land in the SAME part, and a core toolbar filters the LIST in place
  (`(new XCreatorButtonWdgt if XCreatorButtonWdgt?)` inside the array, then compact) — appending
  behind a guard reshuffles the palette and churns screenshots.
- ⚠ If every item of a palette belongs to one part, move the PALETTE and its opener in too —
  filtering its contents would pop an EMPTY window (`plots` did exactly this).
- ⚠ Adding a public member to `Widget.prototype` churns the inspector-list references. Put new doors
  on `WorldWdgt` (or the narrowest class that works).

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
