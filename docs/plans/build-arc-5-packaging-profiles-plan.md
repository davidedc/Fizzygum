# Arc 5 · Packaging profiles — parts × code-form manifests replacing the hard-coded `--homepage` flavour

**STATUS: PLAN ONLY — AUTHORED 2026-07-28; §2 REVISED AGAINST THE TREE 2026-07-30 (arcs 1–4 all
landed and pushed). NOT STARTED.** This is **ARC 5 — the LAST arc — of the build-and-packaging
program** (program table + completion doctrine: §0.1/§0.2 of
`archive/build-arc-4-dynamic-parts-plan.md` — read those first; they are not repeated here in full).

**The 2026-07-30 revision pass re-verified §2 cold against `Fizzygum master @ 10cc6129` and found
FOUR authored facts wrong — two of them premises that reshape the work. Read §2.0 first.** In
summary: part selection is already declarative, so the `parts` axis is a rename, not a mechanism
(§2.0(1)); arc 3 produced guards, NOT registration hooks (§2.0(2)); `sources: lazy` cannot reuse
arc 4's `ensureLoaded` (PR-D3); and there is no `meta-tools` part to exclude, so the lean profile
needs a part split first or must leave scope (R-3). Two pieces of good news: PR-D4's parity tool is
already written (it just lives in a gitignored `.scratch/`), and `sources: background` already ships.

**THREE design calls were RESOLVED by the owner on 2026-07-30. All are LOCKED — do not re-litigate:**
1. **The pruning tail is DERIVED, never declared** (PR-D6 + §2.2.1; an omit-list is rejected in §6.0
   *including* as a "first cut"). Verifying its four proposed attributions found three sound and one
   falsified, and fired the owner's own escape valve once — 5 of the 8 pointer icons are referenced
   NOWHERE and simply get deleted. Upshot: a new **Phase 0.5** dissolves the whole tail *before*
   profiles exist, so `homepage.json` has almost nothing left to express.
2. **`--homepage` dies immediately in Phase 1 — no alias period** (PR-D1). This eliminates R-4 rather
   than mitigating it. Phase 1 enumerates all call sites and which of the three kinds must change.
3. **`lean` / `sources: "none"` STAYS in scope, and the inspector part gets created in-arc** — new
   **Phase 1.5**. Measurement made this cheap: the core→inspector edge surface is **2 lines**, not the
   26 files a raw grep suggests (the rest are comments, which the edge gate strips by design).

Everything corrected is marked `[REVISED 2026-07-30]` in place. Both original ⟨verify⟩ markers are
resolved and gone; the one surviving ⟨…⟩ (R-3's error path) is a design task, not a verification
debt. Line numbers were re-measured at that commit and WILL drift again — the quoted code, flag or
symbol is authoritative, re-grep before editing.

**MANDATE.** Replace the ONE hard-coded shipping flavour (`--homepage`, a thicket of
`if $homepage` conditionals in `build_it_please.sh` + a hardcoded part list from arc 4) with
declarative **profile manifests**: `profile = { parts, form, sources, entries }`. Per the
completion doctrine: the `--homepage` conditional thicket is RETIRED IN THIS ARC — at close,
`build_it_please.sh` contains zero `$homepage` branches; "homepage" is exactly
`buildSystem/profiles/homepage.json`.

---

## §1 Goal and decisions

A profile manifest declares:

```
{ "name": "homepage",
  "parts": ["core"],                        // which parts ship (arc-4 partition)
  "form": "precompiled",                    // "compile-at-boot" | "precompiled"
  "sources": "background",                  // "eager" | "background" | "lazy" | "none"
  "entries": ["index.html"],                // which entry pages ship (arc-1 pages)
  "extras": { "fontAssets": false, "tests": false, "videos": false } }
```

**`[REVISED 2026-07-30]` This schema does not yet cover the largest piece of what `--homepage`
means** — the pruning tail at `build_it_please.sh:904` (8 Automator icons, 2 libs, 3 compiled boot
helpers, the unminified bundle, the re-prune of font-assets). See §2.2: either an explicit `omit`
list or derivation from `parts` + `form`, decided at kickoff. Also note `parts: ["core"]` is exactly
right today — every one of the other 9 parts carries `inHomepage: false`.

| # | Decision | Choice | Status |
|---|---|---|---|
| PR-D1 | Invocation | `./build_it_please.sh --profile homepage` (manifest in `buildSystem/profiles/`). Plain `./build_it_please.sh` = the dev profile (compile-at-boot, all parts, all entries, tests). **`[OWNER RULING 2026-07-30]` `--homepage` DIES IMMEDIATELY in Phase 1 — there is no alias period.** No deletion note, no BACKLOG tail, and R-4 (the never-dying alias) is thereby eliminated rather than mitigated. Every call site changes in the same commit; all of them are local workspace tooling or the tests repo, enumerated in §4 Phase 1. **`[REVISED 2026-07-30]` PR-D1's stated premise — "a hardcoded part list from arc 4" — is FALSE (§2.0(1)): part selection is already declarative in `parts.json`. The invocation decision stands; what the manifest ADDS over today is form + entries + extras + the pruning tail, not part selection. ⚠ `--notests` must be answered here too (§2.1) or it survives as the last flag.** | LOCKED (owner) **except the `--notests` question** |
| PR-D2 | `form: precompiled` | Runs arc 2's external puppeteer driver against the freshly built tree (native entry) and writes `pre-compiled.js`. Per-part precompiled chunks (accumulator tagged by part) are **banked** — v1 profiles load parts in source form (arc-4 P-D6). | LOCKED |
| PR-D3 | `sources: "lazy"` | New seam: source batches not loaded at boot; first consumer of the Class/Mixin member maps (opening an inspector) triggers load+ingest of the needed part's batch (frame-paced, existing machinery). `"none"` = the lean/appliance profile: no batches shipped at all, inspectors/meta-tools part excluded. **`[REVISED 2026-07-30]` ⚠⚠ it CANNOT just call arc 4's `ensureLoaded` — that path is built for a part whose classes DO NOT EXIST YET, and both of its defining choices are wrong here. `PartsRegistry._ingestPartPromise` (a) filters to `fresh = (name for name in SourceVault.namesForPart partName when not window[name]?)`, and on a precompiled tree EVERY core class is already defined, so `fresh` is empty and it would ingest NOTHING; and (b) its closure passes `justIngestSources = false`, i.e. compile-and-execute, which is precisely what must not happen to a live class (`new Class src` would redefine it underneath running instances — the comment at `PartsRegistry.coffee:160-164` says so). What `sources: lazy` needs is the OTHER mode, the one the precompiled boot already uses: `storeSourceAndPotentiallyCompileItAndExecuteIt name, true` over ALL of the part's names. So the seam is a SECOND ingest mode on the registry (`ensureSourcesIngested`, ingest-only, no freshness filter), not a reuse of the existing one. Cheap, but it is real work and it must not be estimated as "already built".** ⚠⚠ THE COMPILER SHIPS IN EVERY PROFILE — the 2026-07-28 inventory proved it product-critical (FizzyPaint tools are CS source strings; spreadsheet formulas incl. RELOAD of saved sheets; `$src` snapshot records; Fizzytiles LCL). A compiler-less artifact is a non-interactive kiosk and is OUT OF SCOPE. | LOCKED |
| PR-D4 | Flavour parity gate | Before deleting the `$homepage` branches: build old-`--homepage` and `--profile homepage` from the same tree and assert the output TREES are equivalent (file list + key byte-compares; timestamps/build-info exempt). Only then delete the branches. **`[REVISED 2026-07-30]` THE TOOL ALREADY EXISTS**: arc 4 borrowed this pattern early and wrote `Fizzygum-tests/.scratch/homepage-fingerprint.js` (stored-source NAMES + file list + sizes + SHA-256, build-stamped boot bundles exempt), which is what proved arc 4's partition byte-equivalent (433 sources both sides). It is in a **gitignored** `.scratch/`, so step one of this arc is to PROMOTE it to `Fizzygum-tests/scripts/` — a gate cannot live in scratch. ⚠ Arc 4's case law: `buildVersion` embeds the commit SHA in both bundles, so a DIRTY tree changes bundle bytes; compare at a clean tree or keep the bundles exempt. | LOCKED |
| PR-D5 | Dev-build default form | Stays compile-at-boot (fast inner loop: pre-building adds a headless boot-and-harvest to every 18 s build; worth paying once per shipped artifact, not per iteration). | LOCKED |
| PR-D6 `[NEW 2026-07-30]` | The pruning tail (§2.2) | **DERIVE it; never declare it. No omit-list, and no omit-list fallback** — owner ruling, three reasons + the escape valve in §2.2.1. Assets attribute to their owning **part** (`parts.json` already carries per-part `vendor`, so an assets key is a precedented extension); `font-assets` derives from the shipped **entry** set; build **intermediates stop being emitted into the tree** rather than being pruned from it; an item that resists attribution is a smell about the item (delete it or re-home it), never a reason for a list. **Acceptance test: at close, nothing in the tail is declared anywhere.** | LOCKED (owner) |

## §2 Baseline

### §2.0 `[REVISED 2026-07-30]` The two FALSE premises — read this first

**1. Part selection is ALREADY DATA. Arc 4 did not leave "a hardcoded part list".** PR-D1 and §2's
"after arc 4" bullet both said the profile manifest would replace a hardcoded homepage part list.
There is no such list. `buildSystem/parts.json` declares `inHomepage` and `requiresFlag` per part,
and `build.py:196 partShipsInThisFlavour(partName, part, args)` is the whole of flavour part
selection — 8 lines, already declarative:

```python
def partShipsInThisFlavour(partName, part, args):
    if args.homepage and not part.get("inHomepage", True):  return False
    flag = part.get("requiresFlag")
    if flag == "tests" and (args.homepage or args.notests):  return False
    if flag == "videoPlayer" and not args.includeVideoPlayer: return False
    return True
```

⇒ **The `parts` axis of a profile is a rename of an existing mechanism, not a new one** (turn
`inHomepage: false` into membership in a named profile's `parts` list). The arc's real remaining
target is the OTHER four things `--homepage` still means in *shell code*: the **form** (precompiled),
the **entries**, the **extras** (font-assets/tests/videos), and — the biggest and least-designed
part — the **pruning tail** (§2.2). Scope this arc accordingly: it is more "delete the shell
thicket" and less "invent a partition mechanism" than the authored plan assumes.

**2. Arc 3 did NOT produce "part-registered hooks".** §2's after-arc-3 bullet said test/dev
contributions are part-registered hooks. The registration hook (arc 3's H-R3, `world.menuContributors`)
was **deliberately NOT built** — it was rejected in favour of the plain class-existence guard
(`if DemoMenus?`, `world.pinouts?.…`), and arc 4 re-confirmed that idiom as the standing one for
optional parts (its §9 rejected alternative 9). ⇒ **Do not design any part of arc 5 around a
registration hook.** A guard is right for INCLUSION; a *lazy* part's entry point awaits
`world.parts.ensureLoaded` (arc 4's rule, gated by `check-part-edges.js`).

### §2.1 `[REVISED 2026-07-30]` The real flavour-conditional surface (`build_it_please.sh`, 969 lines)

`$homepage` appears 31 times, but only **10 are branch sites**; the other 21 are comments (many of
them saying "this gate runs for every flavour incl. --homepage", i.e. deliberately NOT conditional).
The authored §2 line ranges (`:590-660`, `:748+`, `:811-850`) are all stale. Measured at `10cc6129`:

| Line | Condition | What it decides |
|---|---|---|
| `:44` | flag parse | `--homepage` → `homepage=true` |
| `:250` | `$homepage \|\| $notests` | tests symlink: `remove_tests_link` vs `ln -sfn` + manifest generation |
| `:622` | `! $noSyntaxCheck && ! $homepage && ! $notests && [ -d ../Fizzygum-tests ]` | the tests-repo-dependent syntax gate |
| `:645` | (same) | the second such gate |
| `:658` | `$notests \|\| $homepage` | `BUILDFLAG_LOAD_TESTS = false/true` into the boot bundle |
| `:713` | `! $homepage` | appends `src/boot/numbertimes.coffee` to the bundle |
| `:737` | `$homepage` | the Automator `if (false)` sed on `fizzygum-boot.js` |
| `:780` | `! $homepage` | assembles the **SW** boot bundle (det-trig + SWCanvas + SW3D) |
| `:858` | `[ -d font-assets ] && ! $homepage` | copies the ~90 MB SWCanvas font assets |
| `:904` | `$homepage` | **the pruning tail + precompile generation** (§2.2) |

The other flavour axes the arc must subsume — the authored plan mentions them only in passing:
- **`--notests`** — 4 sites, all four shared with `$homepage` (`:250`, `:622`, `:645`, `:658`). It is
  a real second flavour, so "profiles" must express it or it becomes the last surviving flag.
- **`--includeVideoPlayer`** — no shell branch at all; it reaches `build.py` and is consumed purely
  by `requiresFlag: "videoPlayer"` on the `video-player` part. **Already data** (see §2.0).
- **`--includeVideos` / `--keepPreviousPrivateVideos`** — 2 shell sites (`:222`, `:893`) plus `:191`;
  asset copying, unrelated to code form. Natural `extras`.
- **`--noSyntaxCheck`** — a gate switch, not a flavour. Leave it a flag; it must NOT become a
  profile field (a profile describes an artifact, not how carefully you checked it).
- `--keepTestsDirectoryAsIs` is **gone** (deleted by arc 1), as authored. ✓

### §2.2 `[REVISED 2026-07-30]` The pruning tail — the part the manifest schema does NOT cover

`:904`'s block is the single biggest piece of flavour code, and §1's schema has no vocabulary for
most of it. In order, it: removes `font-assets/` again (it survives the cleanup section, so a
homepage build following a dev build would inherit 90 MB); removes **8 Automator pointer icons**
(`doubleClickLeft`, `middleButtonPressed`, `scrollUp`, `doubleClickRight`, `rightButtonPressed`,
`xPointerImage`, `leftButtonPressed`, `scrollDown`); removes the unminified `js/fizzygum-boot.js`;
runs the **precompile driver** (`cd ../Fizzygum-tests && node scripts/generate-pre-compiled-headless.js`,
which MUST run while `js/pre-compiled.js` is still the `preCompiled = false` stub); removes 2 libs
(`FileSaver.min.js`, `jszip.min.js`); removes 3 compiled boot helpers (`dependencies-finding.js`,
`loading-and-compiling-coffeescript-sources.js`, `logging-div.js`); re-runs the Automator sed on
`pre-compiled.js`; then terser + the `pre-compiled-max.js`/`pre-compiled.js` swap.

### §2.2.1 `[OWNER RULING 2026-07-30]` DERIVE the tail — never declare it

**Decided: derivation, with no omit-list fallback.** The owner's three reasons, in their order:
(a) an omit-list per profile is a hand-maintained mirror of facts the build already knows — *precisely
the species this program exists to kill*; (b) it fails the doctrine test this plan itself poses — an
omit-list is `:904` surviving under a new name; (c) most decisively, **every item in the tail already
has a natural owning axis**. Parts already carry `vendor` payloads in `parts.json`, so attributing
assets to a part is a **precedented schema extension, not an invention**.

**Escape valve (owner):** if a single item resists attribution, that is a **smell about the item** —
it probably belongs in a part — *not* a reason to fall back to a list.

**Attribution verified against the tree 2026-07-30. Three of the four hold; one is falsified and the
escape valve fires once:**

| Tail item | Proposed axis | Verified verdict |
|---|---|---|
| 8 Automator pointer icons | test-part assets | **PARTLY.** Only **3** are referenced anywhere — `xPointerImage`, `leftButtonPressed`, `rightButtonPressed`, all three from `Automator-and-test-harness-src/SystemTestsControlPanelUpdater.coffee:54/69/80`. Those attribute cleanly to the `harness` part. **The other 5 (`doubleClickLeft`, `doubleClickRight`, `middleButtonPressed`, `scrollUp`, `scrollDown`) are referenced NOWHERE in either repo** — no dynamic name construction either; they are dead assets shipped in every dev build since forever. ⇒ **the escape valve fires: delete the 5, attribute the 3.** |
| `FileSaver.min.js` + `jszip.min.js` | test machinery | **CONFIRMED, and already half-done.** `globalFunctions.coffee:224-230` gates their *loading* on `BUILDFLAG_LOAD_TESTS`, under a comment that already says "FileSaver + jszip … are TEST machinery"; and product `src/serialization/FileSaving.coffee` states in its header that it does NOT depend on them. Only the *copy* (`build_it_please.sh:869-870`) is unattributed. ⇒ `harness`-part assets. |
| 3 compiled boot helpers (`dependencies-finding.js`, `loading-and-compiling-coffeescript-sources.js`, `logging-div.js`) + the unminified `js/fizzygum-boot.js` | form-derived (compile-at-boot needs them, precompiled doesn't) | **FALSIFIED.** They are **unminified INTERMEDIATES that no page loads in any flavour.** Every boot loads only the minified twins — `globalFunctions.coffee:252/253/263` fetch `loading-and-compiling-coffeescript-sources-min.js`, `logging-div-min.js`, `dependencies-finding-min.js`, and it does so on the **precompiled** path too (a precompiled tree still background-loads batches and ingests, so it needs them just as much); the entry pages load `fizzygum-boot-{native,sw}-min.js` (`build.py:148`), never `fizzygum-boot.js`. `build_it_please.sh:874-882` compiles each `.coffee` → `.js` **into the build tree** and then minifies alongside it. ⇒ the axis is not `form` at all. **Correct resolution: stop emitting intermediates into the build tree** (compile to `$SCRATCH_PATH`, minify into `js/`), which makes this prune *disappear* rather than be attributed — the owner's reason (a) applied one level deeper. A dev tree keeping them is not a feature; it is the same untidiness, unpruned. |
| `font-assets/` (~90 MB) | entry-derived (SW pages only) | **CONFIRMED**, with the axis sharpened: it is "does any shipped entry use SWCanvas", not the entry count. ⚠ **The apparent double-handling is NOT redundant and must survive derivation**: `:858` skips the copy, and `:904` deletes the directory *again*, because `$BUILD_PATH` is shared across flavours and `font-assets/` survives the cleanup section (unlike `js/`, `icons/`, `*.html`, which are wiped) — so a homepage build following a dev build would otherwise inherit 90 MB. Derivation must keep an idempotent re-prune, or this regresses silently. |

⇒ **Net effect on the tail:** 5 items deleted outright, 5 attributed to the `harness` part (3 icons +
2 libs), 4 dissolved by not emitting intermediates, 1 derived from the entry set. **Nothing left to
declare** — which is the test that the derivation is real and not a list in disguise.

### §2.3 Committed arc outcomes, as verified 2026-07-30

- **After arc 1:** tests served through the `js/tests` symlink; the two manifests are generated by
  tests-repo tooling; homepage/notests trees carry no link. ✓ as authored.
- **After arc 2:** two boot bundles from one terser pass, up to three entry pages from
  `build.py`'s `ENTRY_PAGES`; a homepage tree skips the SW pages (`build.py:409
  if args.homepage and useSWCanvas: continue`); font-assets copy already homepage-gated;
  precompile = external driver + the `preCompiled === true` smoke assertion. ✓ as authored.
- **After arc 3:** no `»>>` region markers (63 → 0, all three regexes deleted). ✗ but see §2.0(2) —
  **not** "part-registered hooks".
- **After arc 4:** `SourceVault` (part-tagged, first in the boot bundle); `parts.json` (10 parts,
  core included); per-part batches; `window.FIZZYGUM_PARTS` manifest carrying per-part
  `batches`/`eager`/`vendor` + a class→part map (**core's class list deliberately omitted** —
  "no part owns this name" already means core); `PartsRegistry` (`world.parts`) doing coalesced
  load + frame-paced ingest + idempotent vendor injection; `window.fizzygumPartIsEagerHere` as the
  ONE eagerness predicate, honouring the per-entry-page `FIZZYGUM_EAGER_ALL_PARTS` preset.
- **`sources: "background"` is a real, already-shipping behaviour, not a new axis to build.** A
  precompiled boot (`globalFunctions.coffee:244-293`) starts the world FIRST, *then* loads the
  source batches, *then* calls `storeSourcesAndPotentiallyCompileThemAndExecuteThem true` —
  ingest-only registration, which is what gives the inspectors their member maps without redefining
  the running classes. So `homepage` today = `form: precompiled` + `sources: background`, exactly as
  §1 guesses. ✓
- The Automator-`if (false)` sed is an optimization, not a mechanism to retire — and note it exists
  **TWICE** (`:737` on the boot bundle, `:954` on `pre-compiled.js`), worth ~12 KB. It becomes a
  profile flag or is dropped on measurement; decide at execution.

## §3 The distilled argument

After arc 4 `[REVISED 2026-07-30: arc 4, not arc 3 — the partition is what made this true]`, "a
build flavour" is fully describable as data: which parts, which form, which sources policy, which
entries, which extras. The only reason `--homepage` is code is history — and, per §2.0(1), the
`parts` half of it is ALREADY data; what is left as code is form, entries, extras and the pruning
tail.
Turning it into data (a) makes the owner's "package a build with whatever I want in it" a
one-manifest job, (b) deletes the last flavour-specific conditionals from the build script,
and (c) gives the single-file-save arc's banked §7.1 (precompiled single file) and the lean
profile a common mechanism instead of two more bespoke flags.

## §4 Design + phases

- **Phase −1 `[NEW, REVISED 2026-07-30]` — promote the parity tool:** move arc 4's
  `Fizzygum-tests/.scratch/homepage-fingerprint.js` into `Fizzygum-tests/scripts/`, give it a
  two-tree compare mode (fingerprint A vs B, not just "print a fingerprint"), and capture the
  BASELINE fingerprint of today's `--homepage` tree at a clean tree **before touching anything**.
  Without this, PR-D4 has nothing to compare against and Phase 1 cannot close. Gate: the tool
  reports a tree identical to itself, and reports a planted difference (prove it can FAIL).
- **Phase 0 — profile loader:** `build_it_please.sh` (or a small python helper) reads the
  manifest into shell vars; plain invocation synthesizes the dev profile. No behavior change;
  gate: byte-identical dev tree vs pre-phase build (same fingerprint tool, dev flavour).
- **Phase 0.5 `[NEW 2026-07-30, from PR-D6]` — dissolve the tail BEFORE profiles exist.** Each of
  these is independently correct, flavour-agnostic, and verifiable on its own; doing them first means
  Phase 1's `homepage.json` has almost nothing left to express. In dependency order:
  1. **Delete the 5 dead pointer icons** from `auxiliary files/additional-icons/` (`doubleClickLeft`,
     `doubleClickRight`, `middleButtonPressed`, `scrollUp`, `scrollDown` — referenced nowhere in
     either repo; re-grep before deleting, per §2.2.1). Removes 5 prune lines and 5 shipped files
     from EVERY build.
  2. **Stop emitting build intermediates into the tree**: `build_it_please.sh:874-882` compiles the
     3 boot helpers into `$BUILD_PATH/js/src/` and minifies alongside; compile to `$SCRATCH_PATH`
     instead and minify into `js/src/`. Same for the unminified `js/fizzygum-boot.js`. Removes 4
     prune lines and shrinks every dev tree. ⚠ verify no runner/script reads the unminified twins.
  3. **Attribute the 3 live icons + the 2 libs to the `harness` part** (an `assets` key next to the
     existing `vendor`), so their copy is part-driven rather than flavour-driven. `BUILDFLAG_LOAD_TESTS`
     already gates the libs' *loading*; this makes the *copy* agree with it.
  4. **Derive font-assets from the entry set** ("any shipped entry uses SWCanvas"), keeping the
     idempotent re-prune — §2.2.1 explains why that second removal is load-bearing, not redundant.
  Gate each step with `fg build` + the Phase −1 fingerprint (dev tree must change ONLY in the ways
  intended, homepage tree not at all), then `fg gauntlet` once at the end of Phase 0.5 — step 3
  touches what the harness page ships, which the suite runs on.
- **Phase 1 — homepage as data:** author `profiles/homepage.json` reproducing today's flavour
  exactly (parts: core; form: precompiled; sources: background; entries: index.html; extras
  off). Run the PR-D4 parity gate against Phase −1's baseline. Then DELETE every `$homepage` branch
  **and the `--homepage` flag itself — no alias (PR-D1, owner ruling 2026-07-30)**. Gates: parity,
  `fg homepage` green (it now builds via the profile), `fg gauntlet`.
  ⚠ `fg homepage` is the ONLY gate that exercises a production tree at all (boot + no-SW-payload +
  `preCompiled === true` + a whole-world snapshot round-trip) — arc 4 shipped a bug that ONLY it
  could catch. Treat a green `fg gauntlet` as saying nothing about this arc.

  **`[NEW 2026-07-30]` Every `--homepage` call site, enumerated — three kinds, only the first MUST
  change:**
  1. **Real build invocations (must become `--profile homepage`):** `fg:502` (`fg_build --homepage`,
     the `homepage` leg) and `build_and_smoke.sh:27-29` (matches `--homepage` in its forwarded args to
     choose the smoke's mode). Also `build_and_test.sh:28`, which *rejects* `--homepage`/`--notests`
     with an explanatory error — its guard must reject the new spelling too, or a tests-stripped
     profile silently reaches the suite runner.
  2. **`smoke-boot-headless.js --homepage`** — a **smoke-mode flag, not a build flag** (`fg:503` passes
     it to the script, not to the build). Renaming it is OPTIONAL and independent of PR-D1; recommended
     in the same commit for one vocabulary, but not required for correctness.
  3. **Comment/prose mentions** (dozens across both repos: `generate-pre-compiled-headless.js`'s
     header, `serialization-file-roundtrip-headless.js:70`, `build.py`, `CLAUDE.md`…): prose may name
     history. Update only where a reader would be MISLED about current behaviour — do not sweep.
  ⚠ `fg` is uncommitted local umbrella tooling, so editing it appears in no repo's diff — and **never
  edit it while an `fg` op is running** (arc 4 lost a full gauntlet to exactly that).
- **Phase 1.5 `[NEW 2026-07-30, owner ruling]` — split the inspectors out of core.** Required by the
  owner's decision to keep `lean` / `sources: "none"` in scope (R-3): there is no `meta-tools` part
  today, and `src/meta/` cannot become one wholesale because `Class`/`Mixin` live there and are the
  compile bootstrap. So: move `InspectorWdgt`, `ClassInspectorWdgt` and `ConsoleWdgt` into a new part
  (`src/meta-tools/`), leaving `Class`/`Mixin` in core.

  **Measured 2026-07-30 — the edge surface is 2 lines.** A raw grep says 26 core files name
  `InspectorWdgt`, which looks prohibitive; **almost all of those are COMMENTS** (case-law citations
  like "the InspectorWdgt 2026-06-16 bug", "see InspectorWdgt._reLayout"), and
  `check-part-edges.js` strips `#` comments by design ("prose may name anything", its §32/:120-132).
  The live-code references are exactly:
  - `src/basic-widgets/Widget.coffee:3957` — `inspector = new InspectorWdgt inspectee`
  - `src/basic-widgets/Widget.coffee:3961` — `inspector = new ConsoleWdgt @`
  - `src/macros/MacroToolkit.coffee:855/859/874/883/888` — `findTopWidgetByClassNameOrClass InspectorWdgt`
    ×5, which are **NOT core edges**: `src/macros` is its own part (`inHomepage: false`, harness-only),
    so this is a part→part reference between two parts that ship together everywhere they ship at all.
  - `ClassInspectorWdgt`: **zero** live references outside `src/meta/`.
  ⇒ smaller than arc 4's 4-site `LayoutElementAdderOrDropletWdgt` case. Guard the two `Widget` sites
  (`return unless InspectorWdgt?` on the methods that name them, per arc 4's rule: guard where the
  class is NAMED, not at the callers).

  ⚠⚠ **This is the FIRST part that must ship in production.** Every one of the 9 existing non-core
  parts carries `inHomepage: false`; `meta-tools` needs `inHomepage: true` (the homepage ships
  inspectors today, and this phase must not change that) — only the `lean` profile excludes it. Verify
  `partShipsInThisFlavour` and the homepage fingerprint both agree BEFORE and AFTER: this phase is
  supposed to be pure repartitioning, so PR-D4 parity must hold across it.
  ⚠ Expect churn in the ~15-test inspector set only if a class NAME changes — it does not here, so
  zero-churn is the expectation; a screenshot diff means something moved that shouldn't have.
- **Phase 2 — the new axes:** implement `sources: lazy` (the ingest-only seam, per PR-D3 — NOT
  `ensureLoaded`) and `sources: none` (excluding the `meta-tools` part Phase 1.5 created); add a
  `lean` profile; headless boot-smoke for each shipped profile (console-error-free, `preCompiled`
  state asserted, forbidden-file assertions per profile). Gate: gauntlet + per-profile smokes.
- **Phase 3 — consumers:** re-point the single-file-save plan's banked §7.1 at
  `form: precompiled`; video player flags → profile extras/part; document in CLAUDE.md +
  `docs/architecture/` (build/packaging section) — present-tense, no history prose.

## §5 Risks

| # | Risk | Mitigation |
|---|---|---|
| R-1 | Parity drift while rewriting flavour logic | PR-D4 tree-equivalence gate BEFORE deleting branches |
| R-2 | `sources: lazy` first-inspect jank or race | reuse frame-paced ingest; inspector open awaits the ensure promise (same pattern as part launch) |
| R-3 | Lean profile ships something that needs sources at runtime | inventory says only inspectors/class-editing/sourceEdits-replay do; lean excludes meta-tools and REFUSES class-level `sourceEdits` snapshots with a clear error ⟨design the error path⟩. **`[REVISED 2026-07-30]` ⚠ THERE IS NO `meta-tools` PART.** `src/meta/` (`Class`, `Mixin`, `ClassInspectorWdgt`, `InspectorWdgt`, `ConsoleWdgt`) is in **core**'s `dirs`, and `Class`/`Mixin` are load-bearing for the whole compile bootstrap — they can never leave core. So "lean excludes the meta-tools part" is not a config change: it first requires SPLITTING the inspector widgets out of `src/meta/` into a new part, leaving the meta-system behind. Arc 4 listed the same item as a phase-3 candidate and banked it for exactly this reason. **`[OWNER RULING 2026-07-30]` lean STAYS in scope and the part gets created IN-ARC — new Phase 1.5**, which also measured the edge surface at just **2 live core lines** (the 26-file grep is almost all comments; `check-part-edges.js` strips them). |
| ~~R-4~~ | ~~Long-tail alias (`--homepage`) never dies~~ | **ELIMINATED `[OWNER RULING 2026-07-30]`** — there is no alias: the flag dies in Phase 1 (PR-D1). A risk removed by design beats a risk mitigated by a checklist. |
| R-5 `[NEW 2026-07-30]` | Phase 1.5's part split changes what production ships | `meta-tools` is the FIRST non-core part with `inHomepage: true`; a wrong default silently drops the inspectors from the homepage. PR-D4 parity must hold ACROSS Phase 1.5 (it is pure repartitioning), and `fg homepage` must still boot with inspectors reachable. |

## §6 Rejected

0. **A per-profile `omit` / prune list for the tail** — REJECTED by the owner 2026-07-30 (PR-D6,
   §2.2.1), including as a "first cut, note it for later". It is a hand-maintained mirror of what the
   build already knows, and it is `build_it_please.sh:904` surviving under a new name — the exact
   failure the completion doctrine exists to prevent. If an item seems to need it, the item is the
   problem: delete it or give it a part.
1. **Compiler-less profiles** — product-critical inventory (PR-D3); do not re-litigate.
2. **Per-part precompiled chunks in v1** — accumulator tagging + chunk plumbing for no current
   consumer; banked until a profile measurably needs faster part loads.
3. **Keeping `--homepage` as code "because it works"** — the completion doctrine exists
   precisely for this.

## §7 `[NEW, REVISED 2026-07-30]` Verification protocol — concrete commands

All via the umbrella wrapper, absolute-pathed (`/Users/davidedellacasa/code/Fizzygum-all/fg`), which
is cwd-correct and gates on real exit codes. Long ops go to the background with a log; read
`/tmp/fg-<cmd>.verdict` for the one-line result. ⚠ A running `fg` op OWNS its inputs — never edit
`fg`, `src/` or `tests/` mid-run.

| When | Command | Why this one |
|---|---|---|
| every step | `fg build` | the syntax gate + `check-shippable-coverage` (every `src/` dir must belong to a part) + `check-part-edges` |
| inner loop | `fg presuite` (~3.5 min) | build + dpr1 suite ∥ paint audit |
| phase close | `fg gauntlet` (~5 min, 14 legs) | full behavioural gate — but see the ⚠ on Phase 1: it never builds a production tree |
| **the arc's real gate** | `fg homepage` | the ONLY production-tree gate: boot + no-SW-payload + `preCompiled === true` + snapshot round-trip |
| PR-D4 | the promoted `homepage-fingerprint.js`, two-tree mode | tree equivalence BEFORE deleting any `$homepage` branch |
| per profile (Phase 2) | `smoke-boot-headless.js` with per-profile forbidden-file assertions | a profile that ships something it declared absent must fail loudly |

Zero reference churn is the expectation throughout: this arc repackages, it does not change
rendering. A screenshot diff means something is wrong — **do not recapture**; find the cause.

## §8 References

`archive/build-arc-4-dynamic-parts-plan.md` §0.1/§0.2 (program + doctrine),
`archive/build-arc-3-world-harmonization-plan.md`, `archive/build-arc-2-backend-split-precompile-plan.md`,
`archive/build-arc-1-test-serving-link-plan.md` (DONE), `single-file-save-plan.md` (§7.1 consumer), memory
`backend-split-and-precompile-externalization.md` (compiler inventory, owner directions).
