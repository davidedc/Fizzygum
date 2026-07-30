# Arc 4 · Dynamic parts — lazy-loadable code slices (SourceVault, partition, runtime loader, Fizzytiles pilot)

**STATUS: EXECUTED IN FULL — COMPLETE 2026-07-30.** Phases 0, 1 and 2 all landed; phase 3 DECLINED
by the owner (it is optional by construction — see §5.4, and the two `docs/BACKLOG.md` lines that
carry its candidates forward). Both of the arc's mandated retirements finished IN-ARC and are gated
at zero: the 499 `_coffeSource` window globals + the `Object.keys(window)` suffix-scan
(`check-source-vault.js`), and all three whole-file exclusion markers + all three build.py regexes
(`check-whole-file-markers.js`, 45 → 0). A third new gate, `check-part-edges.js`, defends the
partition itself. Case law: `archive/INDEX.md`.

| Phase | Outcome | Commit |
|---|---|---|
| plan revision | §2 re-verified; 6 facts corrected, 2 of them design-changing | Fizzygum `ca854f86` (plan only) |
| 0 · SourceVault | `_coffeSource` globals + window suffix-scan RETIRED; 499 dead per-class files dropped | Fizzygum `7f4b2172` |
| 1 · partition | `buildSystem/parts.json` (10 parts, core included); **45 marker lines + 3 regexes → 0**; parity MEASURED | Fizzygum `e163ce65` |
| 2 · lazy pilot | Fizzytiles lazy on `index.html`; `world.parts`; snapshot pre-scan; 2 rigs | Fizzygum `65ce0182`, tests `c772dd39a` |
| 3 · more lazy parts | **DECLINED** — optional; every retirement completes at 1/2, so no mixed state | — |

Final gate: `fg gauntlet` **EXIT=0, 14/14 legs in-wave, no retries** (269 tests × dpr1/dpr2/webkit,
0 failed); `fg homepage` EXIT=0 with a clean snapshot round-trip on the production tree.

**Everything below is the plan AS EXECUTED.** The `[REVISED 2026-07-30]` notes record where the
2026-07-28 authoring was wrong; the **AS EXECUTED** blocks in §5.1–§5.4 record what actually
happened, including four bugs found during execution that are worth reading before touching this
area again (they share one shape: ONE RULE ENCODED IN TWO PLACES). Line numbers drift — quoted
symbols are authoritative; re-grep before editing.

**§11 (What is left) is kept verbatim as the closing checklist it was** — every item on it is now
done except the push itself, which is the owner's call.

**MANDATE.** Turn the monolithic "everything compiles at boot" code delivery into named,
lazily-loadable **parts** — and, per the completion doctrine (§0.2), *fully retire* the
mechanisms this replaces within this arc: the 499 `window.<Name>_coffeSource` globals + the
`Object.keys(window)` suffix-scan (dead at end of Phase 0), and ALL THREE whole-file exclusion
markers + their build.py regexes — `FILE_NOT_IN_FIZZYGUM_HOMEPAGE` (43 carriers),
`FILE_ONLY_FOR_MACROS` (2 carriers), `FILE_ONLY_FOR_VIDEOPLAYER` (**0 carriers — already a dead
regex**) — dead at end of Phase 1. **[REVISED 2026-07-30: the original plan named only the
homepage regex and dated its death to "Phase 3"; there are three regexes, they are one
mechanism, and §5.2/§6 already put the retirement in Phase 1.]**

---

## §0 Orientation

Fizzygum: CoffeeScript framework on one canvas; three sibling repos; no module system — every
class is a global; `build.py` wraps each class's source as an escaped JS string; the browser
compiles them at boot, load order discovered by regex-scanning source text
(`src/boot/dependencies-finding.coffee`). Build/test via the `fg` wrapper (absolute path
`/Users/davidedellacasa/code/Fizzygum-all/fg`).

### §0.1 The program this arc belongs to

Plan filenames are numbered by EXECUTION ORDER (`build-arc-N-…`):

| Arc | Plan doc | What it retires (wholly, in-arc) |
|---|---|---|
| 1. Test-serving link — **DONE 2026-07-28** | `archive/build-arc-1-test-serving-link-plan.md` | the per-build tests COPY + spinner; the flatten; `--keepTestsDirectoryAsIs`; build.py manifest generation; recapture's publish-rebuild |
| 2. Backend split + precompile externalization — **DONE 2026-07-28** | `archive/build-arc-2-backend-split-precompile-plan.md` | runtime `?sw=1` switch; WSL precompile script + in-page JSZip/saveAs drain |
| 3. World harmonization — **DONE + PUSHED 2026-07-30** (`Fizzygum 7c8f49a3`, tests `4bc119caf`) | `archive/build-arc-3-world-harmonization-plan.md` | `»>>` region markers (63 → 0) + all three region regexes; homepage-vs-dev world-design divergence |
| **4. Dynamic parts (THIS PLAN) — DONE 2026-07-30** | `archive/build-arc-4-dynamic-parts-plan.md` | `_coffeSource` window globals + suffix-scan; ALL THREE whole-file exclusion markers + their build.py regexes (`FILE_NOT_IN_FIZZYGUM_HOMEPAGE`, `FILE_ONLY_FOR_MACROS`, `FILE_ONLY_FOR_VIDEOPLAYER`) — **all confirmed at zero, all machinery deleted** |
| 5. Packaging profiles — **DONE + PUSHED 2026-07-30** (`Fizzygum f7fff678`, tests `3243b792a`) — **the program's LAST arc** | `archive/build-arc-5-packaging-profiles-plan.md` | the hard-coded `--homepage` flavour: its flag, all TEN `if $homepage` branches in `build_it_please.sh`, the per-part `inHomepage` boolean, `requiresFlag: "tests"`, and the per-flavour prune list — plus `--notests` — **all confirmed at zero, all machinery deleted**. A flavour is now `{parts, form, sources, entries}` in `buildSystem/profiles/*.json`; current state: `docs/architecture/build-and-packaging.md` |

### §0.2 Completion doctrine (owner-mandated 2026-07-28 — applies to every arc)

The owner is explicitly wary of progressive migrations whose old mechanism "disappears only
with the last move" and therefore never dies. Rules, enforced in this plan's phases:

1. **A retirement, once started, completes inside the same arc.** The old mechanism's deletion
   (code + build machinery + docs) is a numbered, gated phase — not a follow-up.
2. **Ratchet gates from day one.** When a phase starts converting a pattern, a build gate
   (`buildSystem/check-*.js`, wired into `build_it_please.sh` like the existing invalidation /
   syntax gates) immediately forbids NEW instances; the phase's close requires count == 0, and
   the gate then flips to forbid the pattern outright (cheap tombstone against resurrection).
3. **No mixed states between arcs.** Mixed old/new is legal only while a phase is open.
4. Each arc's close-out (the `close-arc` ritual) verifies the §0.1 table row: zero-counts
   confirmed, machinery deleted.

### §0.3 Critical reframes (the spine — do not re-derive)

- **R1: Parts are CODE; resetWorld resets STATE, never code.** All ~470 classes already stay
  resident across an entire test shard today. Parts load monotonically within a page session;
  unloading between tests would be pure loss. (Owner concern raised and resolved 2026-07-28.)
- **R2: The test/harness profile EAGER-LOADS all parts at boot.** A part loading mid-test is
  frame-paced through `doOneCycle` ⇒ cycle-count-dependent ⇒ exactly the DETERMINISM.md bug
  class (cycle counts diverge under parallel load). The suite must keep today's timing
  envelope. The lazy path gets its own dedicated tests that AWAIT the load promise.
- **R3: The lazy machinery mostly exists.** `loadJSFilePromise` (script injection, `file://`-
  safe — there is NO fetch/XHR anywhere) + the frame-paced post-boot ingest
  (`waitNextWorldCycle`/`framePacedPromises`, drained in `doOneCycle`) are what `--homepage`
  builds already use to load+ingest sources behind a running world. Parts reuse both.
- **R4: The one hard discipline: core must have NO UNGUARDED edge into a part** — and
  **[REVISED 2026-07-30]** the build-time dependency scanner is NOT what will catch one.
  As authored, R4 said the scanner sees `new X` and would therefore fail the build on a literal
  `new FridgeMagnetsApp` in a core launcher. **That is false.** `dependencies-finding.coffee:56-61`
  matches exactly five patterns, and only the first three are general:
  `\sextends\s*(\w+)` (anywhere on a line, comments included), `\sREQUIRES\s*(\w+)` (a hint the
  file itself documents as unused), `\s*@augmentWith\s+(\w+)`, and then two that are restricted
  to a **2-space-indented class-body field initialiser**: `^\s\s@?ident\s*:\s*new\s*(Ident)` and
  `^\s\s@?ident\s*:\s*([A-Z]…)`. A `new X` inside a **method body** — which is what every real
  launch site is, including `WorldWdgt.coffee:615` and `FridgeMagnetsApp`'s own
  `buildWindow: -> world.openFrameWith (new FridgeMagnetsWdgt), …` — is **invisible** to it.
  Two consequences, both load-bearing:
  1. The failure mode of a core→part edge is NOT "the part gets dragged into core" (that is what
     a *field-initialiser* edge would do); it is a **silent `ReferenceError` at the moment the
     user clicks**, on exactly the page (core-only `index.html`) that no gate boots into a deep
     UI. So the partition-validity check (§5.2) cannot be "aggregate the dependency scan" — it
     must be an **identifier-level scan of every core source for every part-owned class name**,
     with an occurrence inside a comment, or guarded by `if X?` / `X?.`, treated as legal. That
     guard-or-nothing rule IS R4, and it is checkable cheaply.
  2. §5.2's original sequencing worry — "the edge check will fire on the launcher until Phase 2
     converts it, so whitelist it for one commit" — is **moot**. Nothing fires. Drop the dance.
  The good news the revision also found: the tree ALREADY obeys R4. The only core reference to
  any fizzytiles class is `WorldWdgt.coffee:615`
  `(new FridgeMagnetsApp).createOpener()  if FridgeMagnetsApp?` — the guard idiom, verbatim.

- **R6: INCLUSION and EAGERNESS are two different properties. [NEW 2026-07-30]** The mechanism
  being retired (a whole-file marker) only ever expressed ONE thing: *does this file ship in this
  flavour?* A part system must express two: **inclusion** (does the part ship at all) and
  **timing** (is it loaded at boot, or on demand). Conflating them is what makes the pilot look
  hard, because `src/fizzytiles/` genuinely contains both a slice that must be present eagerly
  (the desktop launcher + its icon: an icon the user cannot click does not exist) and a slice
  that should be lazy (the engine, ~10 classes + the LCL compiler + the 3D vendor payload).
  Splitting the two properties makes the whole arc fall out cleanly:
  - **Phase 1 changes inclusion only.** Every part is eager on every page ⇒ boot loads exactly
    the same classes in the same order ⇒ zero runtime change, which is what makes "markers die
    here" a safe, gate-able step by itself.
  - **Phase 2 flips exactly one part to lazy on exactly one page.** Nothing else moves.
  - **P-D4 (harness eager-loads everything) stops being a special case** — it is just the
    harness entry page setting "ignore laziness", the same shape as arc 2's per-entry-page
    `window.FIZZYGUM_USE_SWCANVAS` preset (build.py's `ENTRY_PAGES` table).
- **R5: Per-class `instances` Sets make part-quiescence checkable.** Widgets register in their
  class AND every ancestor class (`Widget.coffee` ~:405-412) and deregister on destroy
  (`unregisterThisInstance`, delete at ~:428). Unload is NOT in this arc (§9), but the registry
  is designed unload-ready (part tagging) at zero extra cost.

### §0.4 Cold-execution protocol (how a fresh session runs this doc)

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — expect all three repos clean, build
   FRESH, 269 tests, gauntlet verdict OK. If a repo is dirty, find out why before touching
   anything.
2. Read §0.3 (the reframes R1–R6) and §2 in full. **§2 is the contract**: if a count or symbol
   there does not match the tree, STOP and re-verify before writing code — the 2026-07-30 pass
   exists because two authored facts were wrong in ways that would have produced a vacuous gate
   and a broken hook.
3. Run the phases IN ORDER, 0 → 1 → 2 (→ 3 optional). Each phase closes on its §6 gate row; do not
   start the next phase on a red or unrun gate. Phases 0 and 1 are **zero-churn**: any pixel diff
   is a bug in the phase, never a reference to recapture.
4. Long ops: launch `fg gauntlet` / `fg homepage` ONCE in the background with a log redirect and
   wait for the notification (§8). Absolute paths everywhere; the Bash cwd is not reliable.
5. Never edit `../Fizzygum-builds/**` (regenerated every build). Never `git stash` in these repos.
6. Commit points are per phase, presented for owner approval — never commit or push autonomously.

---

## §1 Goal and locked decisions

End state: the build partitions ALL shipped source into a **core** plus named **parts** (every
directory in exactly one part), each part declaring its own INCLUSION per profile and its own
EAGERNESS (R6); `index.html` boots core + the eager parts only; launching the lazy pilot
(`fizzytiles`) loads it on demand (sub-second, frame-paced); the harness entry eager-loads
everything by page preset; a saved world snapshot referencing part classes loads those parts before
deserializing; the single-file assembler embeds exactly core + loaded parts. No whole-file
exclusion marker and no `_coffeSource` window global survives anywhere.

| # | Decision | Choice | Status |
|---|---|---|---|
| P-D1 | Source registry | **SourceVault**: a plain boot-level registry object (NOT a Class-system class — src classes compile FROM it; chicken-and-egg), defined in `src/boot/`. API: `store(name, text, part)`, `get(name)`, `names()`, `namesForPart(part)`, `partOf(name)`, `forgetPart(part)` (unload-ready, unused in v1). Replaces the `window.<Name>_coffeSource` globals entirely. | LOCKED (owner proposed, 2026-07-28) |
| P-D2 | Partition representation | **Directory-based, with an explicit manifest for exceptions.** `src/fizzytiles/` = part `fizzytiles`. Mixed directories (e.g. `src/patch-programming` — `PatchNodeWdgt`+`CalculatingPatchNodeWdgt` ship, the Fanout/Diffing/Regex family doesn't) are RESOLVED BY MOVING FILES into a part directory, not by per-file tags — the owner rejects marker-style comments. The manifest (`buildSystem/parts.json` or similar) lists part → directories + vendor payloads. | LOCKED (marker-aversion: owner 2026-07-28) |
| P-D3 | Part→part dependencies | **Derived at build time** by aggregating the class-dependency regex scan to part granularity. A part→part cycle is a BUILD ERROR (the partition is drawn wrong). Runtime `requires` closure loads topo-ordered. ⚠ The same aggregate is NOT sufficient for the core→part edge check — see R4/§5.2. | LOCKED (scope narrowed 2026-07-30) |
| P-D4 | Test profile | Harness entry eager-loads ALL parts at boot (R2) — expressed as the per-entry-page preset of P-D7, not as harness-specific code. | LOCKED |
| P-D7 | Eagerness | **A separate property from inclusion (R6), on two axes.** Per part: `"eager": true` (default) \| `false` in `parts.json`. Per entry page: `window.FIZZYGUM_EAGER_ALL_PARTS`, written into the page by build.py's `ENTRY_PAGES` table exactly like the arc-2 `FIZZYGUM_USE_SWCANVAS` preset. A part loads at boot iff `eager or FIZZYGUM_EAGER_ALL_PARTS`. `worldWithSystemTestHarness.html` and `index-sw.html` set the preset; `index.html` does not. | ADDED 2026-07-30 (follows from R6) |
| P-D5 | Unload | NOT in v1. Registry is unload-ready (part tagging, `forgetPart`); implement only when a use case (part hot-reload) demands. | LOCKED |
| P-D6 | Part code form | v1 parts load in SOURCE form (compile on load) in every profile, including precompiled ones — a part compile is small. Per-part precompiled chunks (accumulator tagging) are banked for arc 5+. | LOCKED |

---

## §2 Exact current state (RE-VERIFIED 2026-07-30 against `master @ 44053c76` — post arcs 1/2/3)

Every count and `file:line` below was re-measured on 2026-07-30. Where the 2026-07-28 authoring
was wrong or has drifted, the correction is marked **[REVISED]** with the old value, so an
executor who has read an older copy of this plan is not silently misled.

- **Source delivery**: `build.py` wraps each class/mixin source as
  `window.<Name>_coffeSource = "…"` via `STRING_BLOCK` (**`build.py:225`**, applied at
  `:294-295`) with exotic-char escaping (`"`→`＂`, `\`→`⧹`, `\n`→`⤶`), and a build-time guard
  that aborts if any of the three replacement characters already occurs in a source.
  **[REVISED: `~:273` → `:225`/`:294-295`.]**
  - **499 wrapped sources in a dev build** = **474** class/mixin files under `src/` + **25**
    sources globbed from the SIBLING TESTS REPO
    (`../Fizzygum-tests/Automator-and-test-harness-src/*.coffee` = 15, plus its
    `AutomatorEventCommands/*.coffee` = 10). `--homepage` wraps **433** (its 474-file list minus
    the 41 marker-carrying files in it). Authoritative command:
    `python3 buildSystem/build.py --list-shippable [--homepage]` — note it prints the file LIST
    *before* the marker filter, so its homepage count (474) is not the wrapped count (433).
    **[REVISED: "~470" → 499/433, and the tests-repo contribution was not stated at all.]**
  - **15 batches**, `js/coffeescript-sources/sources_batch_0..14.js`, cut whenever the
    accumulator passes `minimumSourcesBatchSize = 150000` chars (`build.py:238`). The count is
    handed to the boot code by writing `delete_me/numberOfSourceBatches.coffee`, which
    `build_it_please.sh:637` `cat`s into the boot bundle. **[REVISED: 14 → 15; and the
    numberOfSourceBatches hand-off was not documented.]**
  - **build.py ALSO emits one `<Name>_coffeSource.js` file per class — 499 of them — that
    NOTHING EVER LOADS.** Its own comment says they are generated "for completeness even if we
    end up loading the batches only". Only `--homepage` prunes them
    (`build_it_please.sh:857`, a `ls | grep -v | xargs rm -f` that keeps the batches plus
    `Class_coffeSource.js`/`Mixin_coffeSource.js`). Measured: `js/coffeescript-sources/` is
    **6.6 MB / 514 files** in a dev build, of which ~half is that dead per-class copy.
    **Phase 0 stops emitting them** (see §5.1) — free, and it halves what the vault would
    otherwise have to duplicate. **[NEW — not in the authored plan.]**
  - `Class_coffeSource.js` + `Mixin_coffeSource.js` are the two exceptions that ARE loaded
    individually and early: `globalFunctions.coffee:225-226` loads them, `:232-233` compiles and
    `eval`s them, because `Class`/`Mixin` must exist before any other source can be ingested.
  - **Boot bundles (arc 2)**: `js/fizzygum-boot-native-min.js` (SWCanvas 3D-core + SW3D + boot)
    and `js/fizzygum-boot-sw-min.js` (det-trig + full SWCanvas + SW3D + boot), both fronting the
    ONE terser output `js/fizzygum-boot-min.js` (`build_it_please.sh:719-786`). **A new boot file
    is added by `cat`-ing it into `$SCRATCH_PATH/fizzygum-boot.coffee`** in the block at
    `build_it_please.sh:637-687` (compiled `coffee -b -c` at `:689`) — that block is where
    `src/boot/source-vault.coffee` goes. Three boot files are instead compiled STANDALONE to
    `js/src/*-min.js` and loaded later by name (`:812-820`): `dependencies-finding`,
    `loading-and-compiling-coffeescript-sources`, `logging-div`. ⚠ Because the bundle is
    compiled with `coffee -b` and evaluated as a top-level classic script, its top-level names
    (`nil`, `loadJSFilePromise`, `numberOfSourceBatches`, …) ARE globals — so a normal `src/`
    class such as `PartsRegistry` can call `loadJSFilePromise` directly, with no plumbing.
    **[NEW — the authored plan predates the arc-2 bundle names and never said where a boot file
    is registered.]**
- **Readers of the globals — exactly three, all boot-side** (re-inventoried 2026-07-30; a
  whole-workspace grep for `coffeSource` finds nothing outside these three, `build.py`'s emission
  and `build_it_please.sh:857`'s prune — in particular **zero** readers in `Fizzygum-tests/` and
  zero in any entry page):
  - `dependencies-finding.coffee:63-74` — `Object.keys(window)` filtered on the `_coffeSource`
    suffix → the load order (`:74` reads each source's text back out to scan it).
  - `loading-and-compiling-coffeescript-sources.coffee:158` —
    `fileContents = window[fileName + "_coffeSource"]`. **[REVISED: `:167` → `:158`.]**
  - `globalFunctions.coffee:225-233` — the Class/Mixin bootstrap above.
    **[REVISED: `:220-221` → `:225-233`.]**
  Inspectors do NOT read the globals (they read the parsed `nonStaticPropertiesSources` /
  `staticPropertiesSources` maps on Class/Mixin); the Serializer reads per-instance
  `<name>_source` fields — a DIFFERENT mechanism, stays out of the vault. Both confirmed 2026-07-30.
- **Post-boot load+ingest machinery** (what `--homepage` uses; parts reuse — R3):
  `loadJSFilePromise` (`globalFunctions.coffee:42`, `<script>` injection, `file://`-safe: there
  is NO fetch/XHR anywhere); the batch chain
  `loadJSFilesWithCoffeescriptSourcesBatchesPromise` (`loading-…:59-86`); the pacing pair
  `waitNextTurn` (`:31`) → `waitNextWorldCycle` (`:37`, pushes its `resolve` onto
  `window.framePacedPromises`, drained one per frame in `doOneCycle`) when `window.preCompiled`,
  else `waitNextJSEventLoopCycle` (`:46`, `setTimeout … 1`); the whole-world driver
  `storeSourcesAndPotentiallyCompileThemAndExecuteThem justIngestSources` (`:104`, note the
  PLURAL name) and the per-file worker `storeSourceAndPotentiallyCompileItAndExecuteIt fileName,
  justIngestSources` (`:153` — `new Class fileContents, genJS, create` / `new Mixin …`).
  - ⚠ **Two properties of that driver constrain the runtime loader (§5.3), and neither was
    stated in the authored plan.** (a) It calls `findLoadOrder()` ONCE over the whole window scan
    and then walks the result; an incremental part ingest must therefore run a load-order pass
    **restricted to the part's newly-arrived names** (and must NOT re-`new Class` a name that is
    already defined — that would redefine a live class under running instances). (b) It skips
    `Class`, `Mixin` and `globalFunctions` by name (`:141-142`).
  - `justIngestSources = true` is the precompiled path (classes already exist from
    `pre-compiled.js`; ingest only registers sources for the inspectors);
    `false` compiles AND executes. A lazily-loaded part on a dev build takes the `false` path.
- **Whole-file exclusion markers — 43 carriers, not 53. [REVISED: arc 3 re-homed 10.]**
  `# this file is excluded from the fizzygum homepage build`, applied by
  `FILE_NOT_IN_FIZZYGUM_HOMEPAGE` (**`build.py:86`**, used at `:274`).
  **[REVISED: `build.py:54` → `:86`.]** Census by directory, re-counted 2026-07-30
  (was: 18 icons / 15 src root / 10 fizzytiles / 6 patch-programming / 2 basic-widgets /
  1 boot / 1 video-player):

  | dir | n | files |
  |---|---|---|
  | `src/icons` | 16 | Chapter{X,XX,XXX}Icon{Appearance,Wdgt}, FridgeMagnetsIcon{Appearance,Wdgt}, InformationIcon{…}, RasterPicIcon{…}, SaveIcon{…}, UnderCarpetIcon{…} |
  | `src/fizzytiles` | 10 | the whole directory (see below) |
  | `src` (root) | 8 | `BouncerWdgt`, **`DemoMenus`**, `LayoutElementAdderOrDropletWdgt`, `LayoutSpacerWdgt`, `PenAppearance`, `PenWdgt`, **`PinoutsOverlay`**, **`WidgetFactory`** |
  | `src/patch-programming` | 6 | `DiffingPatchNodeWdgt`, `Fanout{Appearance,PinAppearance,PinWdgt,Wdgt}`, `RegexSubstitutionPatchNodeWdgt` (MIXED dir — `PatchNodeWdgt`/`CalculatingPatchNodeWdgt` ship) |
  | `src/basic-widgets` | 1 | `PointerWdgt` |
  | `src/boot` | 1 | `numbertimes` |
  | `src/video-player` | 1 | `VideoPlayerCanvasWdgt` |

  - The three **bolded** files are the collaborators **arc 3 extracted** (`DemoMenus`,
    `PinoutsOverlay`, `WidgetFactory`) — each already reached ONLY behind a class-existence
    guard (`WorldWdgt.coffee:450` `if WidgetFactory?`, `:454` `if PinoutsOverlay?`, `:2563`/`:2568`
    and `Widget.coffee:4153` `… if DemoMenus?`, `globalFunctions.coffee:357`
    `window.demoMenus = new DemoMenus  if DemoMenus?`). They are the natural first non-pilot part
    members and need **no** call-site work. Arc 3's own `DemoMenus.coffee:10` comment says
    "arc 4 turns that into part membership". **[NEW — these files did not exist on 2026-07-28.]**
  - **2 of the 43 markers are effectively no-ops** (belt-and-braces documentation):
    `src/boot/numbertimes.coffee` is never globbed by build.py at all (the shell decides, at
    `build_it_please.sh:671`), and `src/video-player/VideoPlayerCanvasWdgt.coffee` only enters the
    list behind `--includeVideoPlayer`. Hence "41 marker files in the homepage list" above.
  - **Two SIBLING regexes are the same mechanism and die with it**: `FILE_ONLY_FOR_MACROS`
    (`build.py:88`) — 2 carriers, `src/macros/Macro.coffee` and `src/macros/MacroToolkit.coffee`;
    and `FILE_ONLY_FOR_VIDEOPLAYER` (`build.py:90`) — **0 carriers, i.e. already dead code**. All
    three are consulted in the SAME condition at `build.py:274`, so "exclude by part list" retires
    all three at once: **45 marker occurrences, 3 regexes → 0**. **[NEW.]**
  - **The precedent that already works**: the 25 harness sources are excluded from `--homepage`
    and `--notests` builds NOT by markers but by a PROFILE CONDITION around their glob
    (`build.py:142-146`), and their absence is absorbed by exactly the guard idiom this arc
    adopts — `globalFunctions.coffee:322-326` installs the five `*TestSupport` extension classes
    (`WorldTestSupport`, `WidgetTestSupport`, `MenuTestSupport`, `MenuRowsPanelTestSupport`,
    `MenusHelperTestSupport`, all new in arc 3) with `… .installOnto X  if XTestSupport?`.
    Exclusion-by-list + existence-guard is therefore not a new idea to be invented here; it is
    the tree's established idiom and this arc just generalises the list. **[NEW.]**
  - ⚠ **build.py's shipped-file list is a hand-maintained sequence of per-directory `glob()`
    calls** (`:140-185`), and `buildSystem/check-shippable-coverage.js` exists precisely because
    forgetting to add one ships a directory as nothing. `parts.json` (§5.2) subsumes that list, so
    that gate must be re-pointed at the manifest in the same phase. **[NEW.]**
- **Fizzytiles**: 10 classes in `src/fizzytiles/` (`FizzytilesCodeWdgt`,
  `FridgeMagnets3DCanvasWdgt`, `FridgeMagnetsApp`, `FridgeMagnetsWdgt`, `FridgeWdgt`,
  `LCLCodeCompiler`, `LCLCodePreprocessor`, `LCLProgramRunner`, `LCLTransforms`, `MagnetWdgt`;
  plus a non-shipped `LCLCodePreprocessor_Testing.coffee.txt`), all 10 marker-carrying. Its 3D
  vendor payload after arc 2 is `swcanvas-3d-core.min.js` + `sw3d.min.js`, **prepended into
  `js/fizzygum-boot-native-min.js`** at `build_it_please.sh:781-785` (the SW bundle instead gets
  full `swcanvas.min.js` + `sw3d.js` at `:756-761`). LCL compiles CoffeeScript at runtime — the
  compiler ships in every interactive artifact anyway.
  - **The full core→fizzytiles edge set, re-measured 2026-07-30 (this is the whole of it):**
    `WorldWdgt.coffee:615` `(new FridgeMagnetsApp).createOpener()  if FridgeMagnetsApp?` (already
    guarded — R4 is already satisfied), and `DemoMenus.coffee:53` `fmm = new FridgeMagnetsWdgt`
    inside `createFridgeMagnets` (a **part→part** edge once `DemoMenus` is itself a part). Every
    other hit in `src/` is a prose comment. **[REVISED: the authored plan asserted the launcher
    edge would fail the Phase-1 build check; it will not — see R4.]**
  - **`FridgeMagnetsApp` is a 6-line launcher declaration**: `title`, `toolTip`,
    `buildIcon: -> new FridgeMagnetsIconWdgt`, `buildWindow: -> world.openFrameWith (new
    FridgeMagnetsWdgt), (new Point 570, 400), world.hand.position()`. Its base
    `IconicDesktopSystemWindowedApp` (`src/IconicDesktopSystemWindowedApp.coffee`) owns
    `createOpener inWhichFolder` (builds an `IconicDesktopSystemWindowedAppLauncherWdgt` whose
    reflection action is the string `"launch"`) and a **synchronous** `launch` whose return value
    nobody reads. `WorldWdgt.createDesktop` (`:594-627`) builds one opener per app, fizzytiles'
    at `:615`. **⇒ the launcher + its icon must be present EAGERLY for the desktop icon to exist
    at all, while the engine is what should be lazy — this is the R6 split, and it is why §5.2's
    pilot partition is now a 3-file eager launcher part plus the lazy engine part.** `launch`
    being fire-and-forget is what lets the lazy override be async without touching the base.
    **[NEW — the authored plan called this a "4-file family" and did not notice the launcher
    cannot itself be lazy.]**
- **Deserialization**: `Deserializer.coffee:188` resolves each record's class as
  `klass = window[record.class]`. App singletons additionally resolve by symbolic key —
  `WellKnownObjects.coffee:59-78`, `{"$wk":"app:<ClassName>"}` → `@resolveApp`, which does
  `window[className]`, memoises one instance per class, and returns `nil` if the class is absent
  (the deserializer then raises a rich error). So a snapshot carrying a fizzytiles launcher needs
  the launcher class present — another reason the launcher slice is eager.
  - ⚠ **`WorldWdgt::loadWorldSnapshot` (`:2334-2414`) is NOT async-shaped. [REVISED — this was
    simply wrong as authored.]** Its body is synchronous top-to-bottom (teardown → id counters →
    replay source edits → `Deserializer.deserialize` → scalars → containers → attach children →
    colour → registry) and it returns nothing. `result.whenReady` at `:2409` is a promise for
    ASYNC IMAGE/CANVAS DECODE only, used to schedule a second repaint — it is not a load
    completion hook and cannot carry a parts await. §5.3's hook is therefore re-shaped as a
    **synchronous pre-scan + tail re-entry**, not as "await inside the existing async shape".
    Callers: `FileLoading.coffee:63-64` (guarded `if world.loadWorldSnapshot?`), the menu path,
    macros, and `../Fizzygum-tests/scripts/serialization-roundtrip-headless.js`.
- **Instances tracking (R5)**: `Widget.coffee:393-403` `registerThisInstance` walks
  `@constructor` up `__super__.constructor` adding `@` to every ancestor's `instances` Set;
  `:404+` `unregisterThisInstance` mirrors it; called from `destroy` at `:618`.
  **[REVISED: `~:405-412` / `:428` → `:393-403` / `:404+` / `:618`.]**
- **Suite size**: **269** SystemTests (`Fizzygum-tests/tests`), two of them fizzytiles —
  `SystemTest_macroFizzytilesBoxTileRendersStaticCube` and
  `SystemTest_macroFizzytilesBlockScoping`. Both construct the engine class DIRECTLY in the macro
  (`fmm = new FridgeMagnetsWdgt`, deliberately not the menu path, for deterministic placement) —
  so they need the part resident at macro time, which P-D4/P-D7 gives them, and they should be
  zero-churn. **[REVISED: 268 → 269; the direct-construction detail is new and it is what makes
  P-D4 mandatory rather than merely preferable.]**
- **`fg gauntlet` is now 13 legs**: dpr1, dpr2, webkit, apps, paint, tiernaming, settle, capstone,
  refs, revisits, census, serialization, storage (~390 s parallel). **[NEW: `serialization` and
  `storage` were added after this plan was authored.]**
- **A DRY-RUN of the R4 edge check, done by hand on 2026-07-30 [NEW].** Every marker-carrying
  class name was grepped (with `\b` word boundaries — note `PointerWdgt` is a SUFFIX of
  `ActivePointerWdgt`, so a naive substring scan reports 29 false hits for it) against all
  non-marker-carrying sources. Result: **the tree is almost clean, with exactly one exception**.
  - Guarded and correct: `Widget.coffee:3060` `return unless PointerWdgt?` before
    `new PointerWdgt @`; `WorldWdgt.coffee:450/454/615`; `globalFunctions.coffee:357`;
    `WorldWdgt.coffee:2563/2568` + `Widget.coffee:4153` (`… if DemoMenus?`). Everything else is
    prose in comments.
  - **The one exception: `Widget.coffee:5083`, `:5101`, `:5131` construct
    `LayoutElementAdderOrDropletWdgt` UNGUARDED**, in `showAdders`, `addOrRemoveAdders` and
    `_insertAddersSuchThat` — three public/one private method on the core `Widget` class that
    SHIPS in `--homepage` while the class they instantiate does not. It is not a live crash today
    only because the *callers* are all excluded too (`DemoMenus.coffee:677-678`,
    `LayoutElementAdderOrDropletWdgt.coffee:97`, and `MenusHelperTestSupport.coffee:30` in the
    tests repo) — i.e. these are **four dead methods in a production build**, the same
    "core carries a stub of a stripped feature" shape arc 3 hunted. Phase 1 must resolve it; the
    cheap resolution consistent with the chosen idiom is a guard
    (`return unless LayoutElementAdderOrDropletWdgt?`) at the two public entry points, and the
    deeper one (banked, §5.4) is to move all four members onto the part via
    `…Support.installOnto Widget` — the mechanism arc 3 already built for `WidgetTestSupport`.
- **⚠ An existence guard is the right tool for INCLUSION and the WRONG tool for LAZINESS [NEW].**
  `if X?` means "the part was never shipped, so silently skip" — correct for an eager part
  (present at boot or absent forever), but for a LAZY part it would silently swallow the user's
  click. Only a part that is actually lazy needs the promise-shaped parts API at its entry points.
  Since Phase 2 makes exactly ONE part lazy, only fizzytiles' TWO entry points
  (`WorldWdgt.coffee:615`'s launch action and `DemoMenus.createFridgeMagnets`) ever change shape.
  Every other part in this arc keeps its existing guard untouched.

## §3 Why it is shaped this way

No module system by design (live-editable source-as-text, in-browser compilation, zero build
imports); load order derived, not declared. The homepage build already split "boot the world"
from "deliver the sources" (pre-compiled image + background ingestion) — proving the world
tolerates code arriving late. Parts generalize that from "all sources, eagerly, in the
background" to "named slices, on demand".

## §4 The distilled argument

The expensive and coupling-prone piece of any part system — loading code into a running world
and compiling it without jank — already exists and is exercised on every homepage boot (R3).
What's missing is pure bookkeeping: a registry that knows which source belongs to which part
(SourceVault), a build step that groups batches by part and derives part edges, and a small
runtime state machine. The pilot (Fizzytiles) is the cleanest possible part: one directory, one
6-line launcher, a self-contained vendor payload, two existing SystemTests. Doing the registry
FIRST (Phase 0) means every later phase manipulates parts through one interface instead of
window-global archaeology.

And — the 2026-07-30 revision's contribution to the argument — **the destination is closer than the
authored plan assumed**. The tree already exclusion-by-list (the 25 harness sources, the
video-player), already absorbs an absent class with a guard at every one of ~a dozen sites, already
has arc 3's `installOnto` mechanism for part-owned members on a core class, and already routes the
one core→fizzytiles reference through `if FridgeMagnetsApp?`. What is genuinely new in this arc is
therefore small: name the slices, make the marker mechanism's job into the manifest's job, and add
ONE promise where a click currently assumes the code is already there. Separating inclusion from
eagerness (R6) is what lets that arrive in two independently-gated steps, the first of which cannot
change a single pixel.

---

## §5 Design

### 5.1 Phase 0 — SourceVault (behavior-neutral refactor, own gate)

- New `src/boot/source-vault.coffee`: plain object `window.SourceVault` with the P-D1 API backed
  by a Map; `store` applies the same decode chain the wrappers apply today (the escaping moves
  INTO the vault = single choke point, one place instead of 499 inline `.replace` chains).
  **It must exist before any `sources_batch_*.js` runs, so it goes into the BOOT BUNDLE**: add a
  `cat src/boot/source-vault.coffee >> $SCRATCH_PATH/fizzygum-boot.coffee` line to the block at
  `build_it_please.sh:637-687` (put it FIRST, right after `numberOfSourceBatches`, so nothing in
  the bundle can precede it). Do NOT make it one of the standalone `js/src/*-min.js` files
  (`:812-820`) — those are loaded later, after the batches would already have needed it.
- `build.py`: `STRING_BLOCK` (`:225`) emission becomes
  `SourceVault.store("<Name>", "<escaped>", "<part>")` — keeping the identical three `.replace`
  calls *inside* `SourceVault.store` rather than in each emitted line — with `part = "core"` for
  everything until Phase 1. The Class/Mixin special files go through the vault too, so
  `globalFunctions.coffee:225-233` becomes `SourceVault.get "Mixin"` / `"Class"`.
- **Also in Phase 0: stop emitting the 499 dead per-class `<Name>_coffeSource.js` files**
  (`build.py:294-297`) — nothing loads them (§2), and the only thing that acknowledged them was
  the `--homepage` prune line, `build_it_please.sh:857`, which is DELETED with them (keep the
  `Class`/`Mixin` singles, which ARE loaded). This is not scope creep: it is the same mechanism
  being retired, it removes ~3 MB per dev build, and leaving it would mean writing 499 files of
  `SourceVault.store` calls that no page ever executes.
- `dependencies-finding.coffee:63-74`: enumerate `SourceVault.names()` instead of the
  `Object.keys(window)` suffix-scan, and read each text via `SourceVault.get`;
  `loading-and-compiling-coffeescript-sources.coffee:158` reads `SourceVault.get fileName`.
- The single-file-save plan (`docs/plans/single-file-save-plan.md`) describes the assembler
  enumerating the window globals — **update its two references in this phase's commit**
  (its `:62` "every class/mixin source as `window.<Name>_coffeSource` (never deleted; enumerated
  by …)" and its `:264-265` "enumerate `Object.keys(window)` for the `_coffeSource` suffix (same
  enumeration as `dependencies-finding.coffee:64-66`)" → enumerate the vault). Its `:58` mention
  of `sources_batch_0..13.js` is also stale (15 batches) — fix while there. Required by §5.1's own
  cross-plan obligation and by R-7.
- **Gate + retirement (doctrine):** new `buildSystem/check-source-vault.js`, modelled on
  `buildSystem/check-region-markers.js` (the arc-3 tombstone gate: an inline baseline that may
  only fall, at 0 = hard rule), forbids the `_coffeSource` identifier anywhere in `src/` and any
  `Object.keys(window)` suffix-scan. Wire it into `build_it_please.sh` beside the other
  `check-*.js` gates. The three old readers are DELETED, not shimmed.
- **Gate:** `fg gauntlet` zero-churn (pure plumbing — no pixel may move). Additionally boot
  `index.html` and confirm an inspector on any widget still shows its class source (the ingestion
  path is what feeds `nonStaticPropertiesSources`), and confirm `fg homepage` still asserts
  `window.preCompiled === true` (the `?generatePreCompiled` boot goes through the same wrapper
  emission this phase rewrites).

### 5.2 Phase 1 — build-side partition (still zero runtime change)

**[REVISED 2026-07-30 — three changes: the manifest subsumes build.py's glob list; the edge check
is an identifier scan, not a dependency-scan aggregate (R4); and every part is EAGER in this
phase (P-D7/R6), which is what makes "zero runtime change" literally true rather than hopeful.]**

- **`buildSystem/parts.json` owns the whole partition, core included** — because build.py's
  shipped-file list is today a hand-maintained sequence of ~25 `glob("src/<dir>/*.coffee")` calls
  (`:140-185`) whose omissions `check-shippable-coverage.js` exists to catch. Shape:
  ```
  { "core":       { "dirs": ["src", "src/mixins", "src/basic-widgets", …] },
    "fizzytiles": { "dirs": ["src/fizzytiles"], "eager": false,
                    "vendor": ["js/vendor-parts/fizzytiles-3d.js"] },
    "fizzytiles-launcher": { "dirs": ["src/fizzytiles-launcher"] },
    "harness":    { "dirs": ["../Fizzygum-tests/Automator-and-test-harness-src",
                             "../Fizzygum-tests/Automator-and-test-harness-src/AutomatorEventCommands"] },
    … }
  ```
  Every directory that ships appears in exactly ONE part; `check-shippable-coverage.js` is
  re-pointed to assert that (its allowlist for `src/boot/**`, which the shell compiles by name,
  and `src/video-player/**` stays as-is). A file in no part is a build FAILURE — strictly stronger
  than today's gate, which only checks build.py's globs.
  (Vendor payload file = concat of `swcanvas-3d-core.min.js` + `sw3d.min.js`, emitted by the
  build; the native BOOT bundle then DROPS them, `build_it_please.sh:781-785` — they arrive with
  the part. The harness/SW bundle keeps full SWCanvas as before, hence R-5's idempotent vendor
  step.)
- **The partition draft (do the file moves HERE, none in Phase 2).** P-D2 resolves a mixed
  directory by `git mv`, never by a per-file tag. A `git mv` of a class file is cheap and safe:
  nothing in the tree references a source PATH — no imports, tests name CLASSES, and the only
  path consumers are build.py's globs (now parts.json) and the two gates that read
  `--list-shippable`. The 43 marker files + 2 macros markers become:
  | part | dirs (after moves) | eager | notes |
  |---|---|---|---|
  | `fizzytiles` | `src/fizzytiles` (9 files) | **no** (Phase 2) | the engine + LCL + vendor payload |
  | `fizzytiles-launcher` | `src/fizzytiles-launcher` (3: `FridgeMagnetsApp` + `FridgeMagnetsIcon{Appearance,Wdgt}` moved out of `src/icons`) | yes | must be present for the desktop icon to exist (§2) |
  | `dev-icons` | `src/icons-dev` (14 marker icons moved out of the 159-file `src/icons`) | yes | Chapter{X,XX,XXX}, Information, RasterPic, Save, UnderCarpet |
  | `demos` | `src/demos` (`DemoMenus`, `BouncerWdgt`, `PenWdgt`, `PenAppearance`, `PointerWdgt` moved from `src/basic-widgets`) | yes | all already existence-guarded |
  | `dev-tools` | `src/dev-tools` (`WidgetFactory`, `PinoutsOverlay`) | yes | arc-3 collaborators, already guarded |
  | `layout-chrome` | `src/layout-chrome` (`LayoutSpacerWdgt`, `LayoutElementAdderOrDropletWdgt`) | yes | ⚠ carries the ONE unguarded core edge found by the §2 dry-run — fix in this phase |
  | `patch-programming-experimental` | `src/patch-programming-experimental` (6 files) | yes | resolves the MIXED `src/patch-programming` |
  | `macros` | `src/macros` (already its own dir — retires `FILE_ONLY_FOR_MACROS` with no move) | yes | |
  | `video-player` | `src/video-player` | yes | inclusion already keyed to `--includeVideoPlayer`; marker was redundant |
  | `harness` | the 2 tests-repo dirs | yes | inclusion already keyed to the `not (homepage or notests)` condition; never had a marker |
  `src/boot/numbertimes.coffee`'s marker is deleted with no other change (build.py never sees
  `src/boot`; `build_it_please.sh:671` is what excludes it). Part names are the ONLY new
  vocabulary; keep them lowercase-hyphenated, matching the directory.
- `build.py` emits **per-part batch files** (`sources_batch_core_*.js`,
  `sources_batch_fizzytiles_0.js`, …) and stores each class with its part name via
  `SourceVault.store(name, text, part)`. Part→part `requires` are derived by aggregating the
  class-dependency scan to part granularity; **a part→part CYCLE is a build FAILURE** naming the
  offending class pair (the partition is drawn wrong).
- **The core→part edge check — an IDENTIFIER scan, not a dependency-scan aggregate.** Per R4 the
  dependency scanner is blind to `new X` in a method body, so aggregating it would find nothing
  and give false comfort. The check: for every part-owned class name, scan every CORE source for a
  `\b<Name>\b` occurrence (word boundaries matter — `PointerWdgt` is a suffix of
  `ActivePointerWdgt`), and FAIL unless each occurrence is (a) inside a `#` comment, or (b) on a
  line that also carries `if <Name>?` / `<Name>?.`, or (c) within a method whose body starts
  `return unless <Name>?` — i.e. **guard-or-nothing**. Run it as
  `buildSystem/check-part-edges.js` from `build_it_please.sh`. Expected first-run output on the
  draft partition above: **exactly one failure**, `Widget.coffee:5083/:5101/:5131` →
  `LayoutElementAdderOrDropletWdgt` (§2's dry-run). Fix it in this phase with guards at
  `showAdders` and `addOrRemoveAdders` (`_insertAddersSuchThat` is private and only reached
  through the latter); the deeper move-onto-the-part option is banked in §5.4.
  ⚠ Do NOT weaken this check to a warning and do NOT add an allowlist: it is the only structural
  defence for the failure mode (a click that throws on `index.html`) that no gate boots into.
  - **Two kinds of edge, two different verdicts.** A *construction/reference* edge
    (`new X`, `X.someStatic()`) is fixable at the call site — guard it (eager part) or route it
    through `ensureLoaded` (lazy part). An `extends X` or `@augmentWith X` edge from core into a
    part is **not guardable at all** (you cannot conditionally derive a class), so it means the
    PARTITION IS DRAWN WRONG: the base class or mixin belongs in core. The check must report those
    two cases with different messages and the second must never suggest a guard. These are the
    edges the derived part→part aggregate (P-D3) also sees, so they get caught twice — good; the
    identifier scan is what adds the method-body construction sites that the aggregate cannot see.
  - ⚠ **The check has ONE deliberate blind spot, and it must be documented IN the check's own
    header so a later session does not "close the hole":** `new (window[className])` after an
    `ensureLoaded` — the sanctioned lazy-construction path — contains no literal class name and is
    therefore invisible to an identifier scan **by design**. That indirection is not an evasion of
    R4, it IS R4's prescribed shape: the whole point is that core names the class as *data* (from
    the manifest / from the caller) rather than as a *symbol* the loader must have already defined.
    Making the scan chase string literals through `window[…]` would flag the correct pattern and
    push authors back toward the incorrect one.
- Boot (every entry page) still loads ALL part batches, because every part is eager in this phase
  (P-D7 default `"eager": true`, and `fizzytiles`'s `false` has no effect until Phase 2 teaches
  the boot to honour it) → identical classes in identical order → **gauntlet zero-churn**.
- **Retirement (doctrine): all three whole-file marker mechanisms die HERE.** `--homepage`
  excludes by PART LIST (a hardcoded `homepageParts` set in build.py until arc 5 turns it into a
  profile manifest); the 45 marker lines are deleted from their 45 files; the three regexes
  (`build.py:86/88/90`) and the composite condition at `:274` are deleted. Gate:
  `buildSystem/check-whole-file-markers.js`, modelled on `check-region-markers.js`, asserting ZERO
  occurrences of all three marker strings (baseline 0 = hard rule from the start, since the count
  goes to zero within this phase).
- **⚠ THE PARITY GATE — this is the doctrine's zero-count moment, and it must be a MEASURED
  COMPARISON, not census arithmetic.** "The homepage tree should still wrap 433 sources" is a
  derived number; it can be right while the *contents* are wrong (a swapped pair nets to zero).
  So, applying arc 5's PR-D4 pattern early, in this exact order:
  1. **BEFORE touching anything**, on the current tree (markers still live), build
     `--homepage` and record a fingerprint of the output: the sorted list of every file under
     `../Fizzygum-builds/latest` with its size and SHA-256, plus the sorted list of source NAMES
     the batches store (extract with a grep over `sources_batch_*.js`). Save it under
     `Fizzygum-tests/.scratch/` (gitignored — NOT the session scratchpad, per the repo's Node/cwd
     rule). Timestamp/build-info-bearing entries (`buildVersion`, `pre-compiled.js`) are exempt and
     must be listed as exempt explicitly, not silently skipped.
  2. Implement parts-list exclusion **with the three regexes still in place and still winning**
     (i.e. exclusion applied twice, same answer) and re-fingerprint: it must match step 1 exactly.
  3. **Only then** delete the 45 marker lines, the three regexes and the `:274` condition, and
     re-fingerprint a third time: still identical to step 1. That third comparison is what proves
     the part list — and nothing else — now carries the exclusion.
  4. `fg homepage` green at steps 2 and 3 (it additionally asserts the precompiled image, the
     absent SWCanvas payload, and the snapshot round-trip on the production tree).
  If step 2 or 3 differs, the diff names the exact file — do NOT "explain" a difference, fix the
  part list until the fingerprint matches. The 433 count stays in §2 as a sanity check on the
  fingerprint, never as a substitute for it.

  **AS EXECUTED (2026-07-30) — the result, and two honest deviations.**
  - Baseline `fp-1-markers.txt` taken on the marker-era tree (Phase 0 committed, `7f4b2172`):
    **433 stored sources, 27 tree entries.** Final `fp-3-parts.txt` on the parts-era tree:
    **433 stored sources, 27 tree entries, `[SOURCES]` section byte-identical** — same names, same
    order. That is the exclusion decision, and it did not move.
  - **Deviation 1: steps 2 and 3 were collapsed into one comparison.** Running with both mechanisms
    live was a debugging convenience, not extra proof: the baseline is captured and immutable, so
    fp-1-vs-fp-3 already establishes that the part list reproduces the marker mechanism. Had it
    differed, the diff would have named the file just as well.
  - **Deviation 2: `[FILES]` is NOT byte-identical, and should not be.** Six entries differ, each
    accounted for: `sources_batch_3.js` and `sources_batch_6.js` (the only two batches that moved —
    they carry `WorldWdgt` and `Widget`, which are exactly the two files the edge check made this
    phase add guards to); `js/pre-compiled.js` + `js/pre-compiled-max.js` (the compiled image of
    those same edited sources); `js/src/loading-and-compiling-coffeescript-sources-min.js` (rewritten
    to load per-part batches); and the build-stamped boot bundle (already exempt). Every other batch
    and every other file is byte-identical.
  - Because "two batches differ" would ALSO be the symptom of an escaping bug — a far worse failure
    than a source edit — the deltas were not argued from byte arithmetic but checked directly:
    `Fizzygum-tests/.scratch/verify-stored-sources.js` decodes all 433 stored sources out of the
    built batches and asserts each is byte-identical to its `.coffee` file on disk. It passes. Keep
    that script: it is the right first move whenever a batch hash moves unexpectedly.

### 5.3 Phase 2 — runtime loader + Fizzytiles pilot

- `src/PartsRegistry.coffee` (a normal core class, reachable as `world.parts`):
  manifest injected by the build (part names, batch files, vendor files, requires, eagerness,
  class→part map); per-part state machine `NOT_LOADED | LOADING(promise) | LOADED`;
  `ensureLoaded(name)` → resolve requires closure topo-ordered → for each: inject vendor
  file(s) then batch file(s) via `loadJSFilePromise` (a top-level boot-bundle global, directly
  callable from a src class — §2) → incremental load-order over the part's new names → frame-paced
  ingest+compile via the existing per-file path → mark LOADED. Concurrent callers coalesce on the
  promise. `launch(className)` = `ensureLoaded(partOf(className)).then -> new (window[className])`.
  ⚠ **Two constraints from §2 that the incremental ingest must respect**: run the load-order pass
  over the part's NEW names only (`findLoadOrder()` today scans everything, once), and never
  re-`new Class` a name that is already defined (it would redefine a live class under running
  instances). Reuse `storeSourceAndPotentiallyCompileItAndExecuteIt fileName, false`, driven by
  the same `waitNextTurn()` pacing — on a running world that resolves through
  `window.framePacedPromises`, i.e. one file per frame, which is what keeps the load jank-free.
- **Entry-page eagerness (P-D7)**: at the end of boot, `ensureLoaded` every part for which
  `part.eager or window.FIZZYGUM_EAGER_ALL_PARTS`. Add `FIZZYGUM_EAGER_ALL_PARTS` to build.py's
  `ENTRY_PAGES` substitution (the exact mechanism arc 2 built for `FIZZYGUM_USE_SWCANVAS`): true
  for `worldWithSystemTestHarness.html` and `index-sw.html`, false for `index.html`. The suite's
  world is then byte-identical to today's (R2/P-D4), and `index.html` alone is lazy.
- **The two fizzytiles entry points become promise-shaped** (the ONLY call sites this arc converts
  — §2's inclusion-vs-laziness note): `FridgeMagnetsApp` overrides `launch` as
  `world.parts.ensureLoaded("fizzytiles").then => super()` — safe because the base `launch` is
  synchronous *and* fire-and-forget (the launcher widget's reflection call ignores the return
  value), so no other app and no base-class code changes; and `DemoMenus.createFridgeMagnets`
  becomes `world.parts.launch("FridgeMagnetsWdgt").then (fmm) -> world.openFrameWith fmm, …`.
  `index.html`'s native bundle also stops carrying the 3D vendor payload (§5.2).
- **Deserializer hook — a synchronous PRE-SCAN plus tail re-entry, NOT an await inside the
  existing shape [REVISED 2026-07-30: `loadWorldSnapshot` is not async, see §2].**
  **⚠ THE ORDERING IS THE WHOLE CORRECTNESS ARGUMENT — get it wrong and the re-entry runs as a
  second pass over a half-torn-down world.** `loadWorldSnapshot`'s step 1 is
  `_teardownWorldStructureNoSettle()`: it destroys the entire desktop. So the re-entry point must
  sit strictly BEFORE any mutation of any kind. Exact order inside the method:
  1. parse + `format`/`kind` check (already there; pure).
  2. **the pre-scan — the first new thing in the method, and PURE**: collect the envelope's class
     names (each record's `class` field, plus any `{"$wk":"app:<Name>"}` key), map them through the
     class→part map, keep the parts that are not LOADED. Reads the envelope, touches nothing.
  3. the confirm (already there) — unchanged position, so the user is asked exactly once, before
     any part is fetched and before anything is destroyed.
  4. **the bail-out**, still before step 1-of-the-old-body:
     ```
     if missingParts.length
       return @parts.ensureLoaded(missingParts...).then =>
         @loadWorldSnapshot envelope, Object.assign {}, opts, skipConfirm: true
     ```
     On re-entry the format check passes again, the pre-scan now finds nothing missing, the confirm
     is skipped, and the method proceeds into the ORIGINAL body for the first and only time — with
     every needed class already resident. Nothing has been torn down, nothing double-runs.
  5. the entire existing synchronous body, untouched.
  The method returns a promise ONLY in the lazy case; callers that ignore the return
  (`FileLoading.coffee:63-64`, the menu path) keep working unchanged, and
  `serialization-roundtrip-headless.js` can await it.
  ⚠ Regression-test the ordering, not just the outcome: a test that loads a part-bearing snapshot on
  a core-only page must assert the desktop is INTACT if the ensure rejects (a failed part load must
  leave the old world standing, which is exactly what putting the bail-out before the teardown
  buys). If you find yourself needing `skipConfirm` to suppress a SECOND teardown, the bail-out has
  drifted below step 1 — move it back up rather than patching the symptom.
- **Tests**: the two existing Fizzytiles SystemTests run on the harness (eager) and construct
  `new FridgeMagnetsWdgt` directly — unchanged, zero churn expected. The lazy path needs its own
  coverage (R2/R-9).
  **AS EXECUTED (2026-07-30): NOT a SystemTest — two headless rigs in the tests repo, and the suite
  stays at 269.** R-9 left this open deliberately; the resolution is that a SystemTest *cannot*
  test laziness. Every SystemTest runs on `worldWithSystemTestHarness.html`, which presets
  `FIZZYGUM_EAGER_ALL_PARTS` **on purpose** — so on the only page a SystemTest can use, nothing is
  ever lazy, and a "lazy" SystemTest would pass while proving nothing. Forcing a part to
  `NOT_LOADED` mid-suite was rejected too: it would mean un-defining live classes, which the design
  forbids (a part is code, not state) and which is not the real path anyway. So:
  - `../Fizzygum-tests/scripts/parts-lazy-load-headless.js` — drives `index.html`. Asserts the
    pre-state as a PAIR (engine absent + launcher present + 3D vendor absent + the desktop icon
    exists anyway), triggers the **product's own** launch path (`launcher.target[launcher.callback]`
    — literally what `mouseClickLeft` calls, not a hand-rolled `ensureLoaded`), then asserts the
    part compiled, the whole part arrived (not one class), the vendor payload arrived, the window is
    on the desktop, **and the 3D pane rasterized actual pixels** — the last is what proves the
    payload works rather than merely that a `<script>` was appended.
  - `../Fizzygum-tests/scripts/parts-snapshot-load-headless.js` — the snapshot path, in TWO halves.
    (A) a snapshot carrying a part-owned widget, produced in one page, loads in a FRESH page that
    never loaded the part. (B) **THE ORDERING**: with `ensureAllLoaded` stubbed to reject, the load
    must report the failure AND leave the desktop intact (12 children before, 12 after). (B) is the
    assertion that actually locates the bail-out above the teardown — (A) passes either way, because
    a successful load hides the ordering completely.
  - Both are wired into `fg gauntlet` as the **`parts` leg** (wave B), so they are gated rather than
    remembered.
- **New smoke assertion** (`../Fizzygum-tests/scripts/smoke-boot-headless.js`): on the
  `index.html` native leg, assert `typeof FridgeMagnetsWdgt === 'undefined'` (the engine really is
  absent) AND `typeof FridgeMagnetsApp !== 'undefined'` (the launcher really is present) — the
  pair is what proves the split, where either alone can pass for the wrong reason. Also asserts
  `index.html` does NOT preset `FIZZYGUM_EAGER_ALL_PARTS`, since that alone would make the pair
  meaningless. Skipped in `--homepage` mode: that profile carries neither part.
- **⚠ THREE MORE BUGS FOUND AT EXECUTION (2026-07-30), all the same shape: ONE RULE, TWO PLACES.**
  Worth reading before writing anything else in this arc, because the shape recurs.
  1. **"Is this part eager here?" was implemented twice.** `PartsRegistry._isEagerHere` honoured the
     entry-page override; the boot batch loader's own test (`eagerSourceBatchNames`) did not. The
     boot loader is what actually FETCHES batches, so on the harness page — which presets the
     override — fizzytiles' batch was skipped and **every Fizzytiles SystemTest STALLED on an
     undefined class**, while the registry cheerfully reported the part LOADED. Fix: ONE function,
     `window.fizzygumPartIsEagerHere`; the registry delegates to it.
  2. **That function then had to move into the boot BUNDLE.** Defined in
     `loading-and-compiling-coffeescript-sources.coffee` it did not exist early enough: on a
     pre-compiled (`--homepage`) boot, `createWorldAndStartStepping()` runs as soon as
     `js/pre-compiled.js` lands — BEFORE that separately-fetched file — so the production tree died
     at boot with *"window.fizzygumPartIsEagerHere is not a function"*. **`fg homepage` is what
     caught it, and nothing else would have**: the suite and both serialization rigs only ever run
     non-homepage builds. General rule: anything the WORLD'S CONSTRUCTOR needs belongs in the bundle.
  3. **The `census` gate failed on a coverage hole my own change created**: its battery opens a
     fridge-magnets window, which is unreachable on `index.html` now that fizzytiles is lazy, and the
     gate (rightly) treats a skipped battery entry as hidden coverage. Fix: the census loads every
     lazy part before building its battery — coverage went UP, 1684 → 1713 targets.
- **⚠ A FOURTH, in the rig rather than the product**: the lazy rig sampled the 3D pane's pixels as
  soon as the window appeared. The pane rasterizes on a LATER world cycle, so it passed standalone
  and failed inside a gauntlet wave (13 concurrent browsers). The rig now WAITS for the first frame.
  A rig that reads a value before it can exist is a broken rig, not a flaky product.
- **⚠ ONE DESIGN CORRECTION FOUND AT EXECUTION (2026-07-30) — the class→part map cannot live in the
  SourceVault.** `PartsRegistry.partOf` first read `SourceVault.partOf` (the vault tags every source
  with its part). That is unusable for the one case it exists for: the vault only knows sources it
  has been GIVEN, i.e. whose batch has already loaded, so for a LAZY part it cannot answer until
  after the load — while the question ("which part owns `FridgeMagnetsWdgt`?") has to be answered
  BEFORE it. Symptom: `partsNeededFor` returned `[]` and the snapshot load threw *"this file
  references the class 'FridgeMagnetsWdgt', which does not exist in this build"* on a build that had
  the part sitting right there. Fix: the build emits a per-part `classes` list into
  `window.FIZZYGUM_PARTS` (core's omitted — ~430 names nothing reads), and `_partOf` consults that.
  §5.3 always said "class→part map" in the manifest; taking it from the vault instead was the error.
  The snapshot rig is what caught it — nothing else would have.

### 5.4 Phase 3 — later parts (in-arc if cheap, else banked)

**[REVISED 2026-07-30: the parts themselves all get CREATED in Phase 1 (inclusion), so what is
left for Phase 3 is flipping selected ones to LAZY (timing) — a much smaller and safer step than
"add a part".]** Candidates for `"eager": false`, in likely order:
1. `dev-icons` (14 classes, zero call-site work — nothing outside the `demos` menus names them).
2. `patch-programming-experimental` (6 classes; check its menu entry points first).
3. `demos` / `dev-tools` — ⛔ probably NOT worth it: both are instantiated at boot
   (`globalFunctions.coffee:357` builds `demoMenus`; `WorldWdgt.coffee:450/454` build
   `world.widgetFactory` / `world.pinouts`), so making them lazy means converting boot-time
   construction into on-demand construction. That is a different (and bigger) change than the
   pilot's; bank it unless it turns out trivial.
4. `meta-tools` (inspectors) — needs the ingestion-on-demand seam. Bank to arc 5 if it drags.
Also banked here: moving the four `LayoutElementAdderOrDropletWdgt`-touching `Widget` members
(§2's dry-run finding) out of core onto the **`dev-tools`** part (where the class itself landed —
the authoring-time name "layout-chrome" was a guess for a part that was never created) via a
`…Support.installOnto Widget` extension class — the arc-3 `WidgetTestSupport` mechanism reused for
a part instead of the harness. Phase 1 only guards them.
Each flip is: `"eager": false` + entry-point conversion (only if the part has one) + `fg gauntlet`
+ a smoke absence assertion. **Phase 3 is explicitly OPTIONAL** — the arc's retirements are all
complete at the end of Phase 1/2, so stopping after Phase 2 leaves no mixed state.

---

## §6 Phases & gates

| Phase | Content | Gate |
|---|---|---|
| 0 | SourceVault + 3 readers switched + per-class dead files dropped + old pattern deleted + vault gate | `fg gauntlet` zero-churn (269 tests); `fg homepage` green (precompiled image still generated); inspectors show sources; `check-source-vault.js` green |
| 1 | parts.json (core included), file moves, per-part batches, derived requires + cycle check + **identifier-level** edge check, all 45 marker lines + 3 regexes deleted, homepage-by-parts | **the 3-step homepage-tree fingerprint PARITY gate (§5.2) — the doctrine's zero-count moment**; `fg gauntlet` zero-churn; `fg homepage` green; `check-whole-file-markers.js` == 0; `check-part-edges.js` green; `check-shippable-coverage.js` re-pointed and green |
| 2 | PartsRegistry, `FIZZYGUM_EAGER_ALL_PARTS` entry preset, 2 fizzytiles entry points, snapshot pre-scan hook, lazy pilot + new test | `fg gauntlet` (**270** tests); smoke's absence+presence pair on `index.html`; re-verify the `fg homepage` snapshot-round-trip leg (homepage-by-parts changed what ships in that tree); manual: open `index.html`, launch Fizzytiles, drag a box tile → lit cube |
| 3 | (OPTIONAL) flip selected parts to lazy per §5.4 | gauntlet + smoke absence assertion per part |

## §7 Risks

| # | Risk | Mitigation |
|---|---|---|
| R-1 | Mid-test lazy load breaks determinism | P-D4/P-D7 eager harness (a page preset, not test code); the lazy test AWAITS via settle (R2) |
| R-2 | Hidden core→part edge — **a click that throws on `index.html`**, not (as originally feared) a part dragged into core | Phase 1's IDENTIFIER-level `check-part-edges.js`, guard-or-nothing, no allowlist (R4). The dependency scanner CANNOT catch this — do not rely on it |
| R-3 | Vault boot-order (store called before vault exists) | vault is FIRST in the boot-bundle concatenation, before `numberOfSourceBatches` and every batch; smoke catches inversion |
| R-4 | Snapshot with part classes on a slow load → double-load or race | single promise per part (coalescing); the pre-scan re-enters ONCE with `skipConfirm` after `Promise.all` |
| R-10 | **The snapshot bail-out drifts BELOW the teardown**, so a lazy load re-enters over a destroyed desktop (and a failed part load leaves the user with nothing) | §5.3's numbered ordering: pre-scan is PURE and FIRST, bail-out precedes `_teardownWorldStructureNoSettle`; regression-test asserts the desktop survives a REJECTED ensure |
| R-11 | **Parity claimed from census arithmetic** — the homepage tree "still wraps 433 sources" while the SET differs (a swapped pair nets to zero) | §5.2's 3-step fingerprint gate (file list + sizes + SHA-256 + stored source NAMES), measured BEFORE the change, again with both mechanisms live, and again after the regexes die |
| R-5 | Part vendor payload globals collide with SW-full bundle on harness | harness loads full SWCanvas in the BOOT bundle; part vendor injection must be skipped when `window.SWCanvas.Core.Triangle3DOps` already exists (idempotent vendor step) |
| R-6 | Marker deletion breaks `--homepage` silently | homepage-by-parts lands in the SAME phase; `fg homepage` + the 433-wrapped-source count + the homepage-tree assertions gate it |
| R-7 | Single-file assembler still window-scanning after Phase 0 | that plan doc's `:62` and `:264-265` updated in Phase 0's commit; its Phase-5 harness (when built) enumerates the vault |
| R-8 | **The `git mv`s in Phase 1 look free and are not** — 30-ish class files change directory. Nothing references source PATHS (no imports; tests name classes), but the build's per-directory globs, `check-coffee-syntax.js` and `check-shippable-coverage.js` all read `--list-shippable`, and a directory that ends up in NO part ships as nothing — the exact failure `check-shippable-coverage.js` was written for | do the moves and the parts.json entry in ONE step per part, then `fg build` before moving the next; the re-pointed coverage gate FAILS on an unassigned directory rather than shipping silence |
| R-9 | **The new "lazy path" SystemTest silently exercises the EAGER path** (the harness page eager-loads everything by construction), so it passes while proving nothing | §5.3: either force the part NOT_LOADED at test start or drive `index.html` from a headless script; assert the pre-state (`FridgeMagnetsWdgt` undefined) inside the test, so a test that ran eagerly FAILS |

## §8 Verification protocol

`fg presuite` (build + dpr1 suite ∥ paint audit, ~3.5 min) as the inner loop; **`fg gauntlet` at
every phase close** — 13 legs, ~4.5–5 min parallel — launched ONCE in the background with a log
redirect (`/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet > /tmp/fg-gauntlet-run.log 2>&1`)
and read via the task notification or `cat /tmp/fg-gauntlet.verdict`; never hand-roll a foreground
poller, and never pipe an `fg` call whose exit code gates a decision through `tail`/`grep`.
`fg homepage` at Phases 0 (the precompiled image is generated through the rewritten wrapper
emission), 1 and 2. The new lazy SystemTest via `fg test <name>`. `fg recapture` only if a diff is
UNDERSTOOD and intended (zero-churn is the expectation everywhere except the one new test's own
references). ⚠ A running `fg` op OWNS its inputs: do not edit `src/`, `tests/` or `fg` while one is
in flight — the suite is served through the `js/tests` symlink and picks up test edits live.

## §9 Rejected alternatives (do NOT re-attempt)

1. **Per-file part tags as comments** — rejected by owner (marker aversion); mixed dirs are
   resolved by moving files (P-D2).
2. **Unload in v1** — feasible (instances Sets) but no use case; registry is unload-ready,
   implement on demand (owner Q&A 2026-07-28).
3. **Lazy loading in the test profile** — determinism hazard (R2), zero benefit.
4. **resetWorld unloading parts between tests** — parts are code, not state; would recompile
   per test for no isolation gain (owner concern, resolved 2026-07-28).
5. **A SourceVault as a Class-system class** — chicken-and-egg with the compile bootstrap.
6. **Keeping `window.<Name>_coffeSource` alongside the vault "for compatibility"** — the
   doctrine forbids the mixed end state; three readers exist, all switched in Phase 0.
7. **Deriving the core→part edge check from the dependency scanner** (`extends` / `@augmentWith` /
   field-initialiser `new`) — FALSIFIED 2026-07-30: the scanner does not see `new X` in a method
   body, which is what every real launch site is, so the check would pass vacuously. Use an
   identifier-level scan (R4 / §5.2).
8. **Awaiting the parts load "inside `loadWorldSnapshot`'s existing async shape"** — FALSIFIED
   2026-07-30: that method is synchronous; `result.whenReady` is an image-decode promise, not a
   completion hook. Use the pre-scan + tail re-entry (§5.3).
9. **A registration hook / part-declares-itself callback for optional parts** — the chosen idiom is
   the plain class-existence guard (`if DemoMenus?`), which the tree already uses at every optional
   collaborator and every `*TestSupport` install (owner-confirmed 2026-07-30). ⚠ It covers
   INCLUSION only; a LAZY part's entry point needs the promise-shaped parts API instead (§2).
10. **Making `demos` / `dev-tools` lazy in this arc** — their collaborators are constructed at boot
    (`globalFunctions.coffee:357`, `WorldWdgt.coffee:450/454`), so laziness there means converting
    boot-time construction to on-demand construction: a different change, banked (§5.4).

## §10 References

- Sibling plans: §0.1 table. Arc 3's census (`docs/archive/build-arc-3-world-harmonization-plan.md`
  — moved to archive when arc 3 closed on 2026-07-30) classifies the re-homed files and feeds §5.2.
- `docs/plans/single-file-save-plan.md` — assembler enumerates the vault after Phase 0 (fix its
  `:62` and `:264-265`, and its stale `sources_batch_0..13` at `:58`); saved pages embed core +
  loaded parts by construction.
- `docs/archive/fizzytiles-sw3d-port-plan.md` — the pilot's history + vendor payload details.
- Memory: `backend-split-and-precompile-externalization.md` (program decisions, owner Q&A),
  `resetworld-state-leak-between-tests.md` (the state-vs-code case law).
- Old `SourceVault` name history: an UNRELATED source-analysis dev-tool cluster deleted in
  accidental-complexity P2-T3 (`fcd1bafb`); name is free, no ⛔ conflict.

---

## §11 What is left (2026-07-30) — the arc is not CLOSED until these are done

**[CLOSED 2026-07-30: items 2 and 3 are DONE — the two `docs/BACKLOG.md` lines and the
`Fizzygum-tests/CLAUDE.md` rig entry landed, and this doc is now archived + stamped + indexed. Item 1
(push) is the owner's call and is the only thing outstanding. Kept verbatim below as the record of
what closing this arc required.]**

Phases 0–2 are committed and green; phase 3 is declined. What remains is not implementation:

1. **PUSH** — owner approval required (standing rule: never push autonomously).
   Fizzygum `ahead=5` (`0f17d782` stamped this doc EXECUTED), Fizzygum-tests `ahead=1`.
2. **Docs residue** (the convention: durable residue lands in the same arc):
   - `docs/BACKLOG.md` — a line for the declined phase 3 (§5.4 candidates: `dev-icons`,
     `patch-programming-experimental`, and the bigger `demos`/`dev-tools` boot-construction case),
     and a line for the banked `…Support.installOnto Widget` idea (moving the four
     `LayoutElementAdderOrDropletWdgt`-touching `Widget` members onto the `dev-tools` part instead of
     guarding them). Both must point at their owning section here.
   - `../Fizzygum-tests/CLAUDE.md` — its maintenance-scripts list does not yet mention
     `scripts/parts-lazy-load-headless.js` or `scripts/parts-snapshot-load-headless.js`, nor the
     reason they exist (the harness page presets `FIZZYGUM_EAGER_ALL_PARTS`, so a SystemTest
     structurally cannot observe laziness).
   - Consider whether the partition deserves a `docs/architecture/` page. DEFERRED on purpose: arc 5
     (packaging profiles) replaces `inHomepage` with a profile matrix and would rewrite it
     immediately. `buildSystem/parts.json`'s own header + `Fizzygum/CLAUDE.md` carry it meanwhile.
3. **`close-arc`** — `git mv` this doc to `docs/archive/`, status-stamp it, add its
   `docs/archive/INDEX.md` line, and confirm the §0.1 program-table row (row 4's retirements: zero
   counts confirmed, machinery deleted — both true).

⛔ Do NOT re-do phase 3 as "finishing the arc". The completion doctrine (§0.2) is about
RETIREMENTS finishing in-arc, and they did: `check-source-vault.js`,
`check-whole-file-markers.js` and `check-part-edges.js` all hold at zero. Making more parts lazy is
new capability, not an unfinished retirement.
