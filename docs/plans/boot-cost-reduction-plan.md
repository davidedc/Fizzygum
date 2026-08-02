# Cutting Fizzygum's boot cost — the pre-compiled dev tree, and maximal laziness

**PLAN. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything needed
is embedded here or one named-doc hop away. Line numbers WILL drift — the quoted symbol or filename
is authoritative, re-grep before editing.

**Owner mandate, 2026-07-31:** *"I want to chase both. I want EVERYTHING that can be lazy-loaded to
be lazy loaded, and as well I'm happy to look into the precompiled build."* When told the boot-speed
case had evaporated (a precompiled dev tree boots in 60 ms), the owner reaffirmed the scope anyway:
*"This is about uniformity at this point."* ⇒ uniformity and production DOWNLOAD bytes are standing
reasons here; **boot speed is not** — see §0.1.

> ## ⏩ WHERE THIS ARC IS — read this first. **ALL SLICES DONE + PUSHED.**
> **Track A: DONE** (§1.1b, `f1ab5d40`). **Track B: DONE**, slices 1-4 plus two follow-ons that
> came out of the owner reviewing the result.
>
> | | | production `js/pre-compiled.js` |
> |---|---|---:|
> | arc start | | 936,920 B |
> | `50cbf48b` `e39392bf` `9acadaab` | icons re-homed · `demos` lazy · the `authoring` split | 845,004 B |
> | `eb2bd955` `510c1e74` `b6173e12` `b2f4e01d` | four broken doors · the `requires` mechanism + gate · palette fix + tooling | 844,517 B |
> | `4d42f8d2` | **slice 4** — unpin the 81 classes only lazy parts named (a FIXPOINT, §2.2d) | 724,991 B |
> | `7bcf3fa7` | the Examples folder's five doors, one class per part | 713,269 B |
> | `17e892ee` | every remaining app icon + the folder's own art | 699,228 B |
> | (this round) | the 9 classes no boot path reaches, found by the new `fg whatpins` | **682,031 B** |
>
> **Cumulative −27.2%.** ⭐ And a structural end state: **every non-core part in production is now
> lazy**, so the eager image IS the core image and `homepage`/`lean` emit a byte-identical
> `js/pre-compiled.js`.
>
> **THE IDEA THE LAST TWO COMMITS TURN ON, now in `build-and-packaging.md` §2: an icon is not its
> app.** `createDesktop` was constructing each app at boot only to ask it for a title and an icon,
> and the art is core — so a launcher holds the app's class NAME as a string and resolves it on the
> click. That deleted all three eager launcher parts and made every app icon lazy. A FOLDER adds a
> third moment, because its contents are not drawn until it is opened: boot → nothing, open →
> the folder's own art, click → that one app.
>
> **⏳ NEXT: nothing is designed. ASK `fg whatpins` FIRST.** `buildSystem/what-pins-core.js` walks out
> from `src/boot` and reports what no boot path reaches (movable, transitively, in ONE pass instead of
> the four move-rebuild-rerun rounds `pinned-by-lazy-parts.js` needs) plus the SOLE ROUTES that hold
> weight in the image. Its current answer: **11 classes / 14.2 KB code left, and none of them free** —
> each needs either a `requires` edge with a real click-time cost (`plots`/`maps` → `authoring`) or a
> guard added inside an EAGER part. The two deliberate leave-behinds it re-reports every run are
> `ToolbarWdgt`/`ToolbarCreatorButtonWdgt` and `IconicDesktopSystemWindowedApp`.
> ⛔ Its section 2's biggest block is **ANSWERED — do not re-raise** (owner, 2026-08-02): the ~18
> icon+appearance sole-route pairs, **62.8 KB across 38 classes**, drawn at boot by `createDesktop`
> and the desktop chrome. The art must be in the boot payload in SOME representation, and a data
> format (SVG, bitmaps) is not meaningfully smaller while LOSING what these classes buy — they are
> SIZE-AWARE, choosing level of detail and integer-pixel geometry from their actual device size,
> which is what makes them crisp under the non-AA SWCanvas backend. Deferring them would pop icons
> in after first paint. The only residue is prototype scaffolding for ~38 classes, and collecting it
> means writing an interpreter for a DSL strictly less expressive than CoffeeScript. ⇒ **that weight
> is what drawing 18 icons costs**, and the list will keep showing it every run.
> Other candidates, none automatic: a per-Maker split of `authoring`
> (§2.2d "why NOT per-Maker" — saves the production image nothing); the remaining `src/icons` tail;
> §2.3. ⚠ Any future estimate must be ITERATED to a fixpoint (§2.2d method step 4) and MEASURED.
> ⚠⚠ And note the image is now core-only: a slice can no longer be measured by comparing profiles,
> only by fingerprinting the same profile across a change.
> **Tools, all committed:** `node buildSystem/pinned-by-lazy-parts.js --list` (reports only the 2
> deliberately-kept files today), `fg hypopart <files…>`, `fg fingerprint [profile] [baseref]`,
> `fg lazyprobe` (the index.html invariants — the ONLY thing that can see any of this).
> **Rules that cost a re-run:** §2.5, and §2.2d's "the gate that does not exist" +
> "what execution changed about the design".

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
4. ✅ **DONE — slice 4, §2.2d. Unpin what only lazy parts name.** **81 files** out of `core` (a
   four-round FIXPOINT, not the 48 designed), into `authoring` (72), `plots` (5), `maps` (2) and
   `demos` (2), plus `demos requires ["authoring", "maps"]`. Production `js/pre-compiled.js`
   844,517 → **724,991 B (−14.15%)**, `lean` 821,770 → **702,244 B (−14.55%)** — the same −119,526 B
   in both. Gauntlet 14/14, zero churn; `index.html` probe 33/33.
   `pinned-by-lazy-parts.js` now reports only the two deliberately-kept files.
5. **The launcher icons stay eager forever** (~11 of them): `createDesktop` draws them at boot.

### §2.2c-post What slice 3 actually taught (read before attempting slice 4)

1. ⚠⚠ **THERE WAS NO PART→PART `requires` MECHANISM WHEN SLICE 3 STARTED — and two authored facts
   disagreed about whether there was.** `parts.json`'s spreadsheet note said there is none (right);
   `check-part-edges.js`'s header said part-to-part references are "legitimate when the manifest
   declares the dependency" (**wrong** — the manifest carried `{batches, eager, vendor, classes}` and
   nothing else). Both comments are fixed, and slice 3 closed by BUILDING the mechanism (`510c1e74`):
   `parts.json` `requires: [...]`, one declaration with two readers (inclusion + ordering), a gate
   whose scope is every source present at boot, and cycle/unknown-target rejection. **Present-tense
   contract: `docs/architecture/build-and-packaging.md` §2 — read that, not this bullet.** The lesson
   worth keeping is not the mechanism's absence but the shape of the failure: an authored claim about
   a mechanism outlived the mechanism, in TWO places, disagreeing with each other, and the only
   reason it was caught is that the owner asked "are you sure?".
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

### §2.2d SLICE 4 — ✅ DONE 2026-07-31. Unpin what only lazy parts name; do NOT split per Maker.

> **✅ EXECUTED. 81 files left `core`** (the design below predicted 48 — see "what execution changed"
> at the end of this section, which is the part worth reading if you are planning slice 5).
> **Measured, two trees built each side (`fg fingerprint <profile> b2f4e01d`):**
>
> | tree | `js/pre-compiled.js` | change |
> |---|---|---:|
> | `homepage` | 844,517 → 724,991 B | **−119,526 B (−14.15%)** |
> | `lean` | 821,770 → 702,244 B | **−119,526 B (−14.55%)** |
>
> The absolute delta is IDENTICAL on both, which is the consistency check that the same 81 classes
> left the same eager image. Boot bundle +1,935 B on `homepage` (the parts manifest carries 81 more
> class names) and −3 B on `lean` (which ships no lazy part, so no list grows).
> `js/coffeescript-sources/` −1,740 B. Gauntlet 14/14 zero churn · `fg homepage` · lean smoke ·
> `index.html` probes green (`.scratch/slice4-probe.js`, 33 assertions; `authoring-lazy-probe.js`).
>
> ⚠ **Production dropped two classes outright, and that is the one product-visible line:**
> `ClippingBoxWdgt` and `SimpleTextPanelWdgt` went to `demos`, which no production profile ships, so
> the shipped source count went 411 → 409. Nothing in production could reach them (that is *why* they
> were movable), but it is a real reduction rather than a re-packaging, unlike the other 79.

**Status: DONE.** Slice 3 closed with `parts.json` gaining a `requires` mechanism
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
(✅ Held on execution: these two are exactly what `pinned-by-lazy-parts.js` still reports. But "48"
was one round of a fixpoint — 81 files actually moved; see method step 4.)

#### ⚠ THE `maps` PAIR NEEDS `requires`, NOT AN AWAIT
`LittleUSAIconAppearance` / `LittleWorldIconAppearance` move to `maps`, and `demos-icons`'
`LittleUSAIconWdgt` / `LittleWorldIconWdgt` then name them from `createAppearance: ->`. That reads
like a method that could await, and it cannot: `CreatorButtonWdgt`'s constructor does
`@appearance = @createAppearance()` and consumes the value synchronously — the same no-async-seam
rule that governs creator buttons. So this one is `demos` declaring `requires: ["maps"]`, full stop.

#### ✅ RESOLVED — the "open design decision" was never open
It was framed as taste — `demos requires ["authoring"]` (one line) versus a `whenAllLoaded` in each
of ~32 `DemoMenus` actions (finer-grained) — with the first recommended. **Execution showed the
second is not merely worse, it is IMPOSSIBLE.** 14 widgets in `src/demos-icons` reach their
appearance through `createAppearance: -> new FooIconAppearance @`, and `CreatorButtonWdgt`'s
constructor does `@appearance = @createAppearance()`, consuming the value synchronously. **There is
no seam to await through at those 14 sites**, so no per-site await can exist there at all — exactly
the reasoning already written down for the `maps` pair, which turned out to generalise. Landed as
`demos requires ["dev-icons", "patch-programming-experimental", "authoring-launcher", "authoring",
"maps"]`, and the four per-site `authoring` awaits slice 3 added to `DemoMenus` were deleted as
ceremony over a part that is now always in.

⚠ **The general rule this yields, now in `build-and-packaging.md` §2:** a per-site await where a seam
exists; `requires` where one does not, or where a base class crosses the boundary. `plots` is the
contrast that proves it is not "always declare `requires`" — every `demos`→`plots` reference sits in
a menu action with a real seam, so those six still await per site and a demo menu does not drag the
charting part in. The `index.html` probe asserts exactly that asymmetry.

⚠ `dev-tools requires ["demos"]` already existed, so the chain is now
dev-tools → demos → authoring; `checkRequiresGraph` rejects a cycle, so if that ever closes into one,
the partition is wrong rather than the gate. ⚠ **`requires` is NOT transitive for the GATE**
(`check-part-edges.js` allows `[partName, ...requires]`, one level) although it IS for ordering
(`ensureLoaded` recurses, memoized) and effectively is for inclusion (`buildProfile` fixpoints over
the shipped set). So `demos` had to name `authoring` DIRECTLY even though it already required
`authoring-launcher`, which requires `authoring` — and that is the right answer anyway: `demos` names
`authoring`'s classes itself, so relying on a third part's declaration would be a silent coupling.

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
4. ⚠⚠ **RE-RUN STEP 1 AND ITERATE — THE PINNED SET IS A FIXPOINT, NOT A LIST.** Every file that
   leaves `core` takes its references with it, so classes it was the last core namer of become
   pinned-by-lazy in their turn. This was NOT in the original design and it is where the slice's
   payoff actually came from: 50 → move 48 → **30 remain** (28 new arrivals, mostly the
   `*IconAppearance` siblings of the icons just moved) → move 28 → 6 → move 4 → 3 → move 1 → **2**,
   the deliberately-kept pair. **81 files, four rounds**, against a design that predicted 48 in one.
   Each round needs its own `fg hypopart` check; do not batch them on faith.
5. `fg gauntlet` 14/14 with **ZERO reference churn** — a screenshot diff is a finding, never a
   recapture. Then `fg homepage` and `cd Fizzygum && ./build_and_smoke.sh --profile lean`.
6. `fg fingerprint homepage` and `fg fingerprint lean` — **predict every delta IN WORDS first**, and
   treat any unpredicted line as a finding. (It earned its keep: the prediction "shipped source count
   is unchanged at 411" was WRONG — two classes went to `demos`, which production does not ship, so
   they left the build outright at 409. A predicted-first delta turns that into a noticed fact rather
   than a number nobody read.)

#### ⚠⚠ THE GATE THAT DID NOT EXIST — it does now: `fg lazyprobe`
**`Fizzygum-tests/scripts/parts-lazy-icons-headless.js`, in the gauntlet's `parts` leg.** Everything
below is why it had to exist; it is no longer something to hand-roll per slice. It asserts, on
`index.html`, that every app icon is drawn with NO app class defined, that the Examples folder is
empty at boot and fetches only its own art when opened, and that one click fetches one app.


The harness page and `index-sw.html` preset `FIZZYGUM_EAGER_ALL_PARTS`, so every part is present
there and the references record a world in which nothing is lazy. **Laziness is only real on
`index.html`, which no test drives.** That blind spot produced three separate defects on 2026-07-31 —
four throwing menu doors, a Super Toolbar offering five palettes instead of six, and a
`SlidesToolbarWdgt` whose contents depended on which door opened it — **every one with a green
gauntlet.** ⇒ "14/14, zero churn" is NOT evidence the lazy path works. Before claiming this slice
done, run `fg lazyprobe` — and if the slice touches a door the probe does not cover, add it there
rather than writing a new scratch script. Assert each class is `undefined` BEFORE and `function`
AFTER — absence alone is also what a broken build looks like.

✅ **Done for slice 4 as `../Fizzygum-tests/.scratch/slice4-probe.js` (33 assertions, all green):**
every one of the 81 movers absent at boot and present after its part loads (checked per part, from
`movers.json` beside it, so it cannot drift into checking a hand-picked sample); the `requires`
ordering — after the `demos` door, `authoring` and `maps` are entirely present and `plots` entirely
absent; and all 12 demo-menu actions that build a moved class produce a live instance.
⚠ **Writing it reproduced the "probe that cannot fail" trap twice, in one sitting**, which is worth
knowing because both versions LOOKED right:
  1. It first asserted `world.children` grew. But `world.create` is `aWdgt.pickUp()`, which puts the
     widget in the HAND — so nine assertions failed for a reason that had nothing to do with the
     product, and had the count happened to grow for any other reason they would have PASSED
     meaninglessly.
  2. Fixed to "a live instance of the expected class exists", the FIRST hand case passed and every
     later one failed: `pickUp` is a **no-op while the hand is already full**, so the probe had to
     `world.hand.drop()` between actions. Without that, one real assertion and eight vacuous ones.
⇒ when a probe fails, establish whether the ASSERTION or the product is wrong before touching either;
and prefer an assertion that names the expected object over one that counts things.

#### Exit criteria — ✅ ALL MET
`pinned-by-lazy-parts.js` reports **only the two deliberately-kept files** (`ToolbarWdgt`,
`ToolbarCreatorButtonWdgt`) ✅ · `fg build` 0 unguarded / 0 inheritance ✅ · `fg gauntlet` 14/14 zero
churn ✅ · `fg homepage` (which independently re-derives the win: `authoring` 126 classes absent at
boot, `maps` 8, `plots` 23, each "dragged in 0 eager batches", snapshot round-trip clean) ✅ · lean
smoke ✅ · both fingerprints with predictions written first ✅ · `index.html` probes green ✅ ·
§2.2b ledger updated ✅.

#### ⚠ What execution changed about the DESIGN — read this before planning slice 5
1. **The pinned set is a FIXPOINT** (method step 4). The design's "48 files" was one round of a
   four-round convergence to 81. Any future "which files can leave core" estimate must be iterated.
2. **The `demos` decision was forced, not chosen** — see the RESOLVED section above. The general rule
   (seam ⇒ await, no seam ⇒ `requires`) is now in `build-and-packaging.md` §2.
3. **`requires` is non-transitive for the gate** but transitive for ordering and inclusion. Declare
   the direct edge.
4. **The payoff beat the estimate again, and again in the same direction** — predicted order −70 KB
   for 48 files, measured −119.5 KB for 81. Class count drives the image; these were small classes.
   That is now THREE slices in a row where a bytes-of-code estimate was low. It still does not make
   the estimator trustworthy: it was 2× low here and 50% HIGH for the spreadsheet.
5. **`fg hypopart` needs the destination part's dirs**, and the right reading is a DIFF against the
   destination alone — the destination's own pre-existing references otherwise swamp the signal
   (`authoring` alone reports 23 unguarded references; the 7-file group adds exactly 0).

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
- ⛔ **SUPERSEDED — "anything reached at BOOT forces a launcher split".** This rule held for most of
  the arc and is FALSE. It read `createDesktop`'s icon-building as *constructing each app*, so every
  lazy app seemed to need an eager sliver (`fizzytiles`/`fizzytiles-launcher`,
  `spreadsheet`/`spreadsheet-launcher`, `authoring`/`authoring-launcher`) and a profile had to name
  both parts or neither. But that construction only ever asked the app for a **title and an icon**,
  and the art is core: ⭐ **an icon is not its app.** A launcher holds `appClassName` as a STRING and
  asks `PartsRegistry` for its part on the click, so all three launcher parts were DELETED. The
  surviving rule is the sharper one — **what forces eagerness is boot-time REACHABILITY, and reading
  a name is not reaching a class.** Corollary the arc then exploited: a FOLDER is a door too, giving a
  third moment (boot → open → click). Current statement: `build-and-packaging.md` §2.
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
