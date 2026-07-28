# Arc 4 · Dynamic parts — lazy-loadable code slices (SourceVault, partition, runtime loader, Fizzytiles pilot)

**STATUS: PLAN ONLY — AUTHORED 2026-07-28. Written to be executed COLD by an LLM/engineer with
ZERO prior context.** Facts verified against the working tree on 2026-07-28 (Fizzygum
`master @ ae45e0ff`, 268 SystemTests). Line numbers drift — quoted symbols are authoritative;
re-grep before editing. **This is ARC 4 of the build-and-packaging program** (see §0.1); it
REQUIRES arc 2 (backend split, `archive/build-arc-2-backend-split-precompile-plan.md` — DONE 2026-07-28) landed,
and STRONGLY prefers arc 3 (world harmonization, `build-arc-3-world-harmonization-plan.md`)
landed first — partitioning before harmonization would freeze today's test-accreted topology
into the parts. **Re-validate every §2 fact against the post-arc-1/2/3 tree before executing**
(arc 1 replaces the tests copy with a symlink; arc 2 renames the boot bundles and deletes the
`?sw=1` fallback; arc 3 relocates test-support code).

**MANDATE.** Turn the monolithic "everything compiles at boot" code delivery into named,
lazily-loadable **parts** — and, per the completion doctrine (§0.2), *fully retire* the
mechanisms this replaces within this arc: the ~470 `window.<Name>_coffeSource` globals + the
`Object.keys(window)` suffix-scan (dead at end of Phase 0), and the whole-file
`# this file is excluded from the fizzygum homepage build` markers + build.py's
`FILE_NOT_IN_FIZZYGUM_HOMEPAGE` regex (dead at end of Phase 3).

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
| 3. World harmonization | `build-arc-3-world-harmonization-plan.md` | `»>>` region markers + `HOMEPAGE_EXCLUSION_PARTS` regex; homepage-vs-dev world-design divergence |
| **4. Dynamic parts (THIS PLAN)** | `build-arc-4-dynamic-parts-plan.md` | `_coffeSource` window globals + suffix-scan; whole-file exclusion markers + `FILE_NOT_IN_FIZZYGUM_HOMEPAGE` regex |
| 5. Packaging profiles | `build-arc-5-packaging-profiles-plan.md` | hard-coded `--homepage` flavour conditionals in `build_it_please.sh` |

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
- **R4: The one hard discipline: core must have NO build-time-visible edge into a part.**
  `dependencies-finding.coffee` regex-scans for `extends X`, `@augmentWith X`, `new X`. A
  literal `new FridgeMagnetsApp` in a core launcher is an edge that drags the part into core.
  Launch/instantiation sites for part classes go through the parts API
  (`new (window[name])` after ensure) — invisible to the scanner, and the partition validity
  check (§5.3) enforces it structurally.
- **R5: Per-class `instances` Sets make part-quiescence checkable.** Widgets register in their
  class AND every ancestor class (`Widget.coffee` ~:405-412) and deregister on destroy
  (`unregisterThisInstance`, delete at ~:428). Unload is NOT in this arc (§9), but the registry
  is designed unload-ready (part tagging) at zero extra cost.

---

## §1 Goal and locked decisions

End state: the build partitions src into a **core** plus named **parts** (pilot: `fizzytiles`);
`index.html` boots core only; launching a part's app loads it on demand (sub-second,
frame-paced); the harness entry eager-loads everything; a saved world snapshot referencing part
classes loads those parts before deserializing; the single-file assembler embeds exactly
core + loaded parts.

| # | Decision | Choice | Status |
|---|---|---|---|
| P-D1 | Source registry | **SourceVault**: a plain boot-level registry object (NOT a Class-system class — src classes compile FROM it; chicken-and-egg), defined in `src/boot/`. API: `store(name, text, part)`, `get(name)`, `names()`, `namesForPart(part)`, `partOf(name)`, `forgetPart(part)` (unload-ready, unused in v1). Replaces the `window.<Name>_coffeSource` globals entirely. | LOCKED (owner proposed, 2026-07-28) |
| P-D2 | Partition representation | **Directory-based, with an explicit manifest for exceptions.** `src/fizzytiles/` = part `fizzytiles`. Mixed directories (e.g. `src/patch-programming` — `PatchNodeWdgt`+`CalculatingPatchNodeWdgt` ship, the Fanout/Diffing/Regex family doesn't) are RESOLVED BY MOVING FILES into a part directory, not by per-file tags — the owner rejects marker-style comments. The manifest (`buildSystem/parts.json` or similar) lists part → directories + vendor payloads. | LOCKED (marker-aversion: owner 2026-07-28) |
| P-D3 | Part→part dependencies | **Derived at build time** by aggregating the class-dependency regex scan to part granularity. A part→part cycle is a BUILD ERROR (the partition is drawn wrong). Runtime `requires` closure loads topo-ordered. | LOCKED |
| P-D4 | Test profile | Harness entry eager-loads ALL parts at boot (R2). | LOCKED |
| P-D5 | Unload | NOT in v1. Registry is unload-ready (part tagging, `forgetPart`); implement only when a use case (part hot-reload) demands. | LOCKED |
| P-D6 | Part code form | v1 parts load in SOURCE form (compile on load) in every profile, including precompiled ones — a part compile is small. Per-part precompiled chunks (accumulator tagging) are banked for arc 5+. | LOCKED |

---

## §2 Exact current state (verified 2026-07-28 — RE-VERIFY after arcs 1–3)

- **Source delivery**: `build.py` (STRING_BLOCK wrapper, ~:273) emits
  `window.<Name>_coffeSource = "…"` with exotic-char escaping (`"`→`＂`, `\`→`⧹`, `\n`→`⤶`),
  grouped into 14 `js/coffeescript-sources/sources_batch_*.js` (~2.5 MB); `Class_coffeSource`/
  `Mixin_coffeSource` are separate files loaded early (`globalFunctions.coffee` ~:213-221).
- **Readers of the globals — exactly three, all boot-side** (2026-07-28 inventory):
  `dependencies-finding.coffee:63-74` (suffix-scans `Object.keys(window)` → load order),
  `loading-and-compiling-coffeescript-sources.coffee:167`
  (`fileContents = window[fileName + "_coffeSource"]`), `globalFunctions.coffee:220-221`
  (Class/Mixin bootstrap). Inspectors do NOT read the globals (they read the parsed
  `nonStaticPropertiesSources`/`staticPropertiesSources` maps on Class/Mixin); the Serializer
  reads per-instance `<name>_source` fields — a DIFFERENT mechanism, stays out of the vault.
- **Post-boot load+ingest machinery** (what `--homepage` uses; parts reuse):
  `loadJSFilePromise` (script injection), batch chain
  (`loadJSFilesWithCoffeescriptSourcesBatchesPromise`), frame-paced pacing
  (`waitNextTurn`/`waitNextWorldCycle`/`window.framePacedPromises` drained in `doOneCycle`),
  per-file ingest/compile (`storeSourceAndPotentiallyCompileItAndExecuteIt` — `new Class src,
  genJS, create` / `new Mixin …`).
- **Whole-file exclusion markers**: 53 files carry
  `# this file is excluded from the fizzygum homepage build`; census by directory: 18
  `src/icons`, 15 src root, 10 `src/fizzytiles`, 6 `src/patch-programming` (MIXED dir), 2
  `src/basic-widgets`, 1 `src/boot`, 1 `src/video-player`. build.py applies
  `FILE_NOT_IN_FIZZYGUM_HOMEPAGE` (build.py:54). Arc 3's census report (in
  `build-arc-3-world-harmonization-plan.md`) classifies each — use it for the partition draft.
- **Fizzytiles**: 10 classes in `src/fizzytiles/`; its 3D vendor payload after arc 2 is
  `swcanvas-3d-core.min.js` + `sw3d.min.js` (~23 KB, in the native bundle). Its launcher:
  `FridgeMagnetsApp` desktop launcher (4-file family, see
  `docs/archive/fizzytiles-sw3d-port-plan.md`). LCL compiles CoffeeScript at runtime — the
  compiler ships in every interactive artifact anyway (2026-07-28 inventory).
- **Deserialization**: `Deserializer` resolves classes as globals; `WorldWdgt::loadWorldSnapshot`
  is async-shaped (`whenReady`). No part hook exists (this plan adds it).
- **Instances tracking**: R5 above.

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
(SourceVault), a build step that groups batches by part and derives part edges (the same regex
scan, aggregated), and a small runtime state machine. The pilot (Fizzytiles) is the cleanest
possible part: one directory, one launcher, a self-contained vendor payload, an existing
SystemTest. Doing the registry FIRST (Phase 0) means every later phase manipulates parts
through one interface instead of window-global archaeology.

---

## §5 Design

### 5.1 Phase 0 — SourceVault (behavior-neutral refactor, own gate)

- New `src/boot/source-vault.coffee` (compiled into the boot bundle like the other boot files;
  it must exist before any sources_batch runs): plain object `window.SourceVault` with the
  P-D1 API backed by a Map; `store` applies the same decode chain the wrappers use today (the
  escaping moves INTO the vault = single choke point).
- `build.py`: wrapper emission becomes `SourceVault.store "<Name>", "<escaped>", "<part>"`
  (part = `"core"` for everything, until Phase 1). Class/Mixin special files use the vault too;
  `globalFunctions.coffee:220-221` reads via `SourceVault.get`.
- `dependencies-finding.coffee`: enumerate `SourceVault.names()` instead of the window
  suffix-scan; `loading-…-sources.coffee:167` reads `SourceVault.get fileName`.
- The single-file-save plan's assembler design (its §4.3) enumerates the vault instead of
  `Object.keys(window)` — update that plan doc's two references in the same commit.
- **Gate + retirement (doctrine):** new `buildSystem/check-source-vault.js` forbids the literal
  `_coffeSource` emission pattern and any `Object.keys(window)` suffix-scan in src/; the three
  old readers are DELETED (not shimmed) in this phase. `fg gauntlet` must be zero-churn
  (pure plumbing). Also verify a dev boot's inspectors still show sources (ingestion unchanged).

### 5.2 Phase 1 — build-side partition (still zero runtime change)

- `buildSystem/parts.json`: `{ "fizzytiles": { "dirs": ["src/fizzytiles"], "vendor":
  ["js/vendor-parts/fizzytiles-3d.js"], "launcherClasses": ["FridgeMagnetsApp"] } }` — core =
  everything unlisted. (Vendor payload file = concat of `swcanvas-3d-core.min.js` +
  `sw3d.min.js`, emitted by the build; the native BOOT bundle then DROPS them — they arrive
  with the part. The harness/SW bundle keeps full SWCanvas as before.)
- `build.py` emits per-part batch files (`sources_batch_core_*.js`,
  `sources_batch_fizzytiles_0.js`), stores each class with its part name, and derives part→part
  `requires` by aggregating the class-dep scan; **cycle or core→part edge = build FAILURE**
  with the offending class pair named (this is the R4 enforcement — it will fire on the
  launcher's literal `new FridgeMagnetsApp` until Phase 2 converts it; sequence: land Phase 2's
  launch-site indirection in the same commit as enabling the check, or enable the check with
  the pilot part listed but the edge whitelisted for one commit — prefer the former).
- Boot (both entries) still loads ALL batches → behavior identical; gauntlet zero-churn.
- **Retirement (doctrine):** whole-file exclusion markers + `FILE_NOT_IN_FIZZYGUM_HOMEPAGE` die
  HERE: `--homepage` excludes by PART LIST (hardcoded `homepageParts` set in build.py until
  arc 5 turns it into a manifest). The 53 markers are deleted from the files; mixed
  `src/patch-programming` is resolved by `git mv` of the experimental family into its part dir
  (P-D2). Gate: `check-homepage-markers.js` (or extension of an existing gate) asserts ZERO
  occurrences of the marker string. NOTE: which non-fizzytiles files become parts vs stay
  core-but-experimental follows arc 3's census dispositions; anything arc 3 didn't re-home
  lands in an `experimental` part here.

### 5.3 Phase 2 — runtime loader + Fizzytiles pilot

- `src/PartsRegistry.coffee` (a normal core class, reachable as `world.parts` or a global):
  manifest injected by the build (part names, batch files, vendor files, requires, class→part
  map); per-part state machine `NOT_LOADED | LOADING(promise) | LOADED`;
  `ensureLoaded(name)` → resolve requires closure topo-ordered → for each: inject vendor
  file(s) then batch file(s) via `loadJSFilePromise` → incremental load-order over the part's
  new names (re-run the dependency scan restricted to not-yet-defined classes) → frame-paced
  ingest+compile via the existing per-file path → mark LOADED. Concurrent callers coalesce on
  the promise. `launch(className)` = `ensureLoaded(partOf(className)).then -> new (window[className])`.
- Launcher sites: the Fizzytiles desktop launcher/menu item calls `world.parts.launch
  "FridgeMagnetsApp"` (R4). Grep for remaining literal constructions of part classes from core
  — the Phase 1 build check is the enforcement.
- **Deserializer hook**: before deserializing, scan the envelope's class names against the
  class→part map; `Promise.all` the ensures, then proceed (`loadWorldSnapshot` is already
  async-shaped). A part-class widget in a snapshot on a part-less page thus loads its part
  transparently.
- **Entries**: `index.html` boots core only (native bundle no longer carries the 3D vendor —
  §5.2). Harness entry + `index-sw.html`: eager `ensureLoaded` of every part right after boot
  (P-D4) — the suite's world is byte-identical to today's.
- **Tests**: existing Fizzytiles SystemTests run on the harness (eager) — unchanged, zero
  churn expected. NEW SystemTest: on a core-booted world, trigger the launcher, AWAIT the load
  promise through the settle machinery, assert the app opens and renders (the lazy path's own
  test, per R2). New headless assertion in the smoke script: `index.html` boot does NOT define
  `FridgeMagnetsApp` (lazy-loading actually lazy).

### 5.4 Later parts (in-arc if cheap, else banked)

Candidates in likely order: `experimental` (the arc-3 leftovers), `dev-icons`, the
patch-programming experimental family, `meta-tools` (inspectors — needs the
ingestion-on-demand seam; bank to arc 5 if it drags). Each addition is: manifest entry +
launcher indirection + gauntlet.

---

## §6 Phases & gates

| Phase | Content | Gate |
|---|---|---|
| 0 | SourceVault + 3 readers switched + old pattern deleted + vault gate | `fg gauntlet` zero-churn; inspectors show sources; gate green |
| 1 | parts.json, per-part batches, derived requires + edge check, marker deletion, homepage-by-parts | `fg gauntlet` zero-churn; `fg homepage` green; marker count == 0 |
| 2 | PartsRegistry, launcher indirection, deserializer hook, eager harness, lazy pilot + new tests | `fg gauntlet` (268+1 tests); smoke lazy assertion; manual: open index, launch Fizzytiles, drag a box tile → lit cube |
| 3 | (optional in-arc) additional parts per §5.4 | gauntlet per part |

## §7 Risks

| # | Risk | Mitigation |
|---|---|---|
| R-1 | Mid-test lazy load breaks determinism | P-D4 eager harness; the lazy test AWAITS via settle (R2) |
| R-2 | Hidden core→part literal edge (drags part into core or breaks boot) | Phase 1 build check names the pair; launch-site indirection (R4) |
| R-3 | Vault boot-order (store called before vault exists) | vault is boot-bundle code, loaded before any batch; smoke catches inversion |
| R-4 | Snapshot with part classes on a slow load → double-load or race | single promise per part (coalescing); deserializer awaits ensures |
| R-5 | Part vendor payload globals collide with SW-full bundle on harness | harness loads full SWCanvas in the BOOT bundle; part vendor injection must be skipped when `window.SWCanvas.Core.Triangle3DOps` already exists (idempotent vendor step) |
| R-6 | Marker deletion breaks `--homepage` silently | homepage-by-parts lands in the SAME phase; `fg homepage` + homepage-tree assertions gate it |
| R-7 | Single-file assembler still window-scanning after Phase 0 | that plan doc updated in Phase 0's commit; its Phase-5 harness (when built) enumerates the vault |

## §8 Verification protocol

`fg presuite` inner loop; `fg gauntlet` at every phase close (background + log + verdict; never
foreground-poll); `fg homepage` at Phases 1–2; the new lazy SystemTest via
`fg test <name>`; `fg recapture` only if a diff is UNDERSTOOD and intended (zero-churn is the
expectation everywhere except the one new test's own references).

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

## §10 References

- Sibling plans: §0.1 table. Arc 3's census (region markers, file dispositions) feeds §5.2.
- `single-file-save-plan.md` — assembler enumerates the vault after Phase 0 (two refs to fix
  there); saved pages embed core + loaded parts by construction.
- `docs/archive/fizzytiles-sw3d-port-plan.md` — the pilot's history + vendor payload details.
- Memory: `backend-split-and-precompile-externalization.md` (program decisions, owner Q&A),
  `resetworld-state-leak-between-tests.md` (the state-vs-code case law).
- Old `SourceVault` name history: an UNRELATED source-analysis dev-tool cluster deleted in
  accidental-complexity P2-T3 (`fcd1bafb`); name is free, no ⛔ conflict.
