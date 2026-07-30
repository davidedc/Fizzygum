# Arc 5 · Packaging profiles — parts × code-form manifests replacing the hard-coded `--homepage` flavour

**STATUS: IN PROGRESS — the arc's CENTRAL STEP IS DONE: profiles ship, and both flavour flags are
deleted. What remains is phase 2 (the new `sources` axes + the `lean` profile) and phase 3
(consumers + docs).** This is **ARC 5 — the LAST arc — of the build-and-packaging program**
(program table + completion doctrine: §0.1/§0.2 of `archive/build-arc-4-dynamic-parts-plan.md` —
read those first; they are not repeated here in full).

| Phase / decision | State | Commit |
|---|---|---|
| plan revision (§2 re-verified cold; 4 authored facts wrong) | DONE | `7b773269` (plan only) |
| −1 · promote the parity tool | DONE | tests `6757cb55c` |
| 0.5 · dissolve the pruning tail (steps 1-3) | DONE | `14a1fe54` |
| — · `build.py`'s exit code was never checked | DONE (latent bug, predates the arc) | `b569822e` |
| D1 + D2 · stop shipping 1.9 MB of dead weight | DONE | `d14a3d0d` |
| 1.5 · split the inspectors into `meta-tools` | DONE (moved BEFORE 0/1 — see the sequencing note in §4) | `f7364e95` |
| **0 + 1 · profiles; `--homepage` and `--notests` DELETED** | **DONE** (merged, as §4 argued) | the commit adding `buildSystem/profiles/` |
| 0.5 step 4 · font-assets derived from the entry set | DONE, inside phase 0 as planned | (same commit) |
| 2 · `sources: lazy` / `none` + the `lean` profile | not started (1.5 unblocked it) | — |
| 3 · consumers + docs | not started | — |

Gates after phase 0+1: `fg gauntlet` **EXIT=0, 14/14 legs in-wave, no retries** (256s), ZERO
reference churn; `fg homepage` **EXIT=0** (production tree: booted from the pre-compiled image, no
SWCanvas payload, snapshot round-trip clean). PR-D4 parity across the whole rewrite: **dev and
homepage byte-IDENTICAL, dev-notests differing by exactly its one predicted delta.** Production tree
**5.36 MB / 28 files → 3.47 MB / 26 files (−35.4%)**.
Six owner rulings are LOCKED (PR-D1, PR-D6, R-3, D1, D2, D3) — **do not re-litigate any of them.**

**WHAT A FLAVOUR IS NOW, in one place:** `buildSystem/profiles/<name>.json` = `{parts, form,
entries}`, read by `buildSystem/buildProfile.py` — which derives everything else and is the only code
that parses `--profile`. `parts.json` is the PARTITION (what the parts are and what they own); a
profile is the FLAVOUR (which of them ship). `build_it_please.sh` now contains zero flavour branches:
it asks the reader for `PROFILE_FORM` / `PROFILE_SHIPS_TESTS` / `PROFILE_SHIPS_SWCANVAS_ENTRY` /
`PROFILE_BOOT_PRELUDE` and branches on those.

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

A profile manifest declares — **`[AS BUILT 2026-07-30]` three keys, not the five sketched here**; the
other two turned out to be derivable or redundant and were dropped rather than written (the reasoning,
key by key, is in §4 Phase 0+1's as-executed block, and it is PR-D6 applied to the schema itself):

```
buildSystem/profiles/homepage.json               // the FILE's name is the profile's name
{ "parts": ["core", "meta-tools"],               // "all" | [names] | {"allExcept": [names]}
  "form": "precompiled",                         // "compile-at-boot" | "precompiled"
  "entries": ["index.html"] }                    // "all" | [names], from buildProfile's ENTRY_PAGES
```

What was sketched and is NOT there: `name` (the filename already says it), `extras.fontAssets` and
`extras.tests` (both derived — from the shipped entries and from whether the `harness` part ships),
and `sources` (deferred to phase 2, which is when it gets a consumer). `extras.videos` did not
arrive either: the video flags are per-invocation opt-ins, and phase 3 decides where they land.

**`[REVISED 2026-07-30]` This schema never covered the largest piece of what `--homepage` meant** —
the pruning tail at `build_it_please.sh:904` (8 Automator icons, 2 libs, 3 compiled boot helpers, the
unminified bundle, the re-prune of font-assets). **It does not need to: PR-D6 rules that the tail is
DERIVED, and Phase 0.5 dissolved it (§2.2.1, §4) — assets now belong to the part that owns them
(a new `assets` field in `parts.json`), intermediates never enter the tree, and 5 of those icons
turned out to be dead and were deleted.** What remains for a manifest to express is `form`,
`entries`, and the `extras` above. Also note `parts: ["core"]` is exactly right today — every one of
the other 9 parts carries `inHomepage: false`.

| # | Decision | Choice | Status |
|---|---|---|---|
| PR-D1 | Invocation | `./build_it_please.sh --profile homepage` (manifest in `buildSystem/profiles/`). Plain `./build_it_please.sh` = the dev profile (compile-at-boot, all parts, all entries, tests). **`[OWNER RULING 2026-07-30]` `--homepage` DIES IMMEDIATELY in Phase 1 — there is no alias period.** No deletion note, no BACKLOG tail, and R-4 (the never-dying alias) is thereby eliminated rather than mitigated. Every call site changes in the same commit; all of them are local workspace tooling or the tests repo, enumerated in §4 Phase 1. **`[REVISED 2026-07-30]` PR-D1's stated premise — "a hardcoded part list from arc 4" — is FALSE (§2.0(1)): part selection is already declarative in `parts.json`. The invocation decision stands; what the manifest ADDS over today is form + entries + extras + the pruning tail, not part selection. ⚠ `--notests` must be answered here too (§2.1) or it survives as the last flag.** **`[OWNER RULING 2026-07-30]` `--notests` becomes a NAMED PROFILE** (`buildSystem/profiles/dev-notests.json`: every part except `harness`/`macros`, compile-at-boot, all entries). The flag dies with `--homepage`; zero flavour flags survive. Informing the choice: nothing in the workspace ever PASSES `--notests` — `fg` never does, `build_and_smoke.sh` only recognises it to drop the SW leg, `build_and_test.sh` only to reject it — so it is a hand-typed option whose capability is cheap to keep as data, and deleting it outright risked removing something the owner uses by hand. | LOCKED (owner) |
| PR-D2 | `form: precompiled` | Runs arc 2's external puppeteer driver against the freshly built tree (native entry) and writes `pre-compiled.js`. Per-part precompiled chunks (accumulator tagged by part) are **banked** — v1 profiles load parts in source form (arc-4 P-D6). | LOCKED |
| PR-D3 | `sources: "lazy"` | New seam: source batches not loaded at boot; first consumer of the Class/Mixin member maps (opening an inspector) triggers load+ingest of the needed part's batch (frame-paced, existing machinery). `"none"` = the lean/appliance profile: no batches shipped at all, inspectors/meta-tools part excluded. **`[REVISED 2026-07-30]` ⚠⚠ it CANNOT just call arc 4's `ensureLoaded` — that path is built for a part whose classes DO NOT EXIST YET, and both of its defining choices are wrong here. `PartsRegistry._ingestPartPromise` (a) filters to `fresh = (name for name in SourceVault.namesForPart partName when not window[name]?)`, and on a precompiled tree EVERY core class is already defined, so `fresh` is empty and it would ingest NOTHING; and (b) its closure passes `justIngestSources = false`, i.e. compile-and-execute, which is precisely what must not happen to a live class (`new Class src` would redefine it underneath running instances — the comment at `PartsRegistry.coffee:160-164` says so). What `sources: lazy` needs is the OTHER mode, the one the precompiled boot already uses: `storeSourceAndPotentiallyCompileItAndExecuteIt name, true` over ALL of the part's names. So the seam is a SECOND ingest mode on the registry (`ensureSourcesIngested`, ingest-only, no freshness filter), not a reuse of the existing one. Cheap, but it is real work and it must not be estimated as "already built".** ⚠⚠ THE COMPILER SHIPS IN EVERY PROFILE — the 2026-07-28 inventory proved it product-critical (FizzyPaint tools are CS source strings; spreadsheet formulas incl. RELOAD of saved sheets; `$src` snapshot records; Fizzytiles LCL). A compiler-less artifact is a non-interactive kiosk and is OUT OF SCOPE. | LOCKED |
| PR-D4 ✅ | Flavour parity gate (DISCHARGED — see §5 R-1) | Before deleting the `$homepage` branches: build old-`--homepage` and `--profile homepage` from the same tree and assert the output TREES are equivalent (file list + key byte-compares; timestamps/build-info exempt). Only then delete the branches. **`[REVISED 2026-07-30]` THE TOOL ALREADY EXISTS**: arc 4 borrowed this pattern early and wrote `Fizzygum-tests/.scratch/homepage-fingerprint.js` (stored-source NAMES + file list + sizes + SHA-256, build-stamped boot bundles exempt), which is what proved arc 4's partition byte-equivalent (433 sources both sides). It was in a **gitignored** `.scratch/`, so step one of this arc PROMOTED it to `Fizzygum-tests/scripts/build-tree-fingerprint.js` (see Phase −1 as-executed) — a gate cannot live in scratch. ⚠ Arc 4's case law: `buildVersion` embeds the commit SHA in both bundles, so a DIRTY tree changes bundle bytes; compare at a clean tree or keep the bundles exempt. | LOCKED |
| PR-D5 | Dev-build default form | Stays compile-at-boot (fast inner loop: pre-building adds a headless boot-and-harvest to every 18 s build; worth paying once per shipped artifact, not per iteration). | LOCKED |
| PR-D6 ✅ | The pruning tail (§2.2) — **acceptance test MET: nothing in the tail is declared anywhere**, and the schema itself shrank by the same rule | **DERIVE it; never declare it. No omit-list, and no omit-list fallback** — owner ruling, three reasons + the escape valve in §2.2.1. Assets attribute to their owning **part** (`parts.json` already carries per-part `vendor`, so an assets key is a precedented extension); `font-assets` derives from the shipped **entry** set; build **intermediates stop being emitted into the tree** rather than being pruned from it; an item that resists attribution is a smell about the item (delete it or re-home it), never a reason for a list. **Acceptance test: at close, nothing in the tail is declared anywhere.** | LOCKED (owner) |

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

**`[RETIRED 2026-07-30]` Every row of this table is GONE** — phase 0+1 replaced all ten branches, and
the flag itself, with the profile facts named in the right-hand column below. The table is kept as
the record of what "the homepage" actually meant in shell code, because that inventory is what made
the replacement checkable: ten branches in, ten derivations out, and a parity gate across the join.

`$homepage` appeared 31 times, but only **10 were branch sites**; the other 21 were comments (many of
them saying "this gate runs for every flavour incl. --homepage", i.e. deliberately NOT conditional).
The authored §2 line ranges (`:590-660`, `:748+`, `:811-850`) were all stale. Measured at `10cc6129`:

| Line | Condition | What it decides | ⇒ NOW DERIVED FROM |
|---|---|---|---|
| `:44` | flag parse | `--homepage` → `homepage=true` | `--profile <name>`, parsed by `buildProfile.py` |
| `:250` | `$homepage \|\| $notests` | tests symlink: `remove_tests_link` vs `ln -sfn` + manifest generation | `PROFILE_SHIPS_TESTS` (the `harness` part) |
| `:622` | `! $noSyntaxCheck && ! $homepage && ! $notests && [ -d ../Fizzygum-tests ]` | the tests-repo-dependent syntax gate | same |
| `:645` | (same) | the second such gate | same |
| `:658` | `$notests \|\| $homepage` | `BUILDFLAG_LOAD_TESTS = false/true` into the boot bundle | same |
| `:713` | `! $homepage` | appends `src/boot/numbertimes.coffee` to the bundle | `PROFILE_BOOT_PRELUDE` — fizzytiles' new `bootPrelude` in `parts.json` |
| `:737` | `$homepage` | the Automator `if (false)` sed on `fizzygum-boot.js` | `! PROFILE_SHIPS_TESTS` (all three `Automator*` classes are harness-owned) |
| `:780` | `! $homepage` | assembles the **SW** boot bundle (det-trig + SWCanvas + SW3D) | `PROFILE_SHIPS_SWCANVAS_ENTRY` |
| `:858` | `[ -d font-assets ] && ! $homepage` | copies the ~90 MB SWCanvas font assets | same — and its `else` is the idempotent re-prune, moved up from `:904` |
| `:904` | `$homepage` | **the pruning tail + precompile generation** (§2.2) | `PROFILE_FORM = precompiled` — and that is ALL that is left of the block: the tail itself was dissolved in phase 0.5 / D1 / D2 |

The other flavour axes the arc must subsume — the authored plan mentions them only in passing:
- **`--notests`** — 4 sites, all four shared with `$homepage` (`:250`, `:622`, `:645`, `:658`). It is
  a real second flavour, so "profiles" must express it or it becomes the last surviving flag.
  **`[DONE 2026-07-30]` `profiles/dev-notests.json` = `{"allExcept": ["harness"]}`.** ⚠ MEASURED, and
  it corrects PR-D1's parenthetical: the old `--notests` tree shipped `macros` — only the part
  carrying `requiresFlag: "tests"` (harness) dropped out — so "every part except harness/macros"
  would have been a silent behaviour change. The fingerprint is what settled it (notests baseline:
  477 sources across 9 parts, `macros` among them), not a reading of `partShipsInThisFlavour`.
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

### §2.2.2 `[FOUND AT EXECUTION 2026-07-30]` Two further tail items the survey MISSED

Fingerprinting a real `--homepage` tree (28 files) surfaced two shipped-but-unused items that §2.2's
line-by-line reading of `:904` did not, because neither is pruned there — nothing removes them at all.
**Both change what PRODUCTION ships, so both were raised as owner decisions rather than applied
silently. Both were APPROVED and DONE on 2026-07-30 — together they take the production tree from
5.36 MB / 28 files to 3.47 MB / 26 files, −1.90 MB (−35.4%):**

1. **`js/pre-compiled-max.js` — 1,969,846 bytes, 35.0% of the entire production tree (5.36 MB / 28
   files), loaded by nothing.** The tail does `terser … -o pre-compiled-min.js; mv pre-compiled.js pre-compiled-max.js;
   mv pre-compiled-min.js pre-compiled.js` — so the unminified image is *renamed and kept*. Its only
   mention anywhere in either repo is that `mv`. By PR-D6's own axis it is an intermediate and should
   never enter the tree; the counter-argument is that someone may want a readable image deployed for
   debugging — but that is void: this tree **already ships all 434 class sources AS TEXT** in
   `js/coffeescript-sources/` (2.28 MB, 40.5% of it), which is what the in-world inspectors read, so
   `-max` was a redundant second copy of the same information in compiled form. **✅ DONE: no longer
   emitted** (minify in place, one `mv` instead of two).
2. **`js/vendor-parts/fizzytiles-3d.js` — 18,879 bytes of software-3D engine in a tree that ships no
   fizzytiles.** Its block's own comment says "Emitted for every flavour that ships the part", but the
   only condition on it is `[ -f $SWCANVAS_VENDOR/swcanvas-3d-core.min.js ]` — **no part or flavour
   test at all**, so it ships everywhere. This is the same species as arc 4's
   `FILE_ONLY_FOR_VIDEOPLAYER`: a rule that documents a gate it never implements. The fix is exactly
   PR-D6 (`vendor` payloads ship iff their part ships). **✅ DONE**: the payload moved from a shell
   `cat` into `build.py`, the only place that knows which parts ship. `parts.json`'s `vendor` entries
   became `{ out, concat: [pieces] }`; build.py assembles them for shipping parts and emits **only
   `out`** into `window.FIZZYGUM_PARTS`, because `PartsRegistry` consumes vendor entries as URLs to
   inject (`loadJSFilePromise`) — so the runtime contract is untouched. Verified byte-for-byte: the
   DEV tree came out IDENTICAL, which is what proves the Python concatenation reproduces the old
   `cat` + `printf '\n;\n'` pipeline exactly; and the homepage build now reports
   `assembled 0 vendor payload(s)`.

⚖ Lesson worth keeping: **the tail was surveyed by reading the prune block, so it could only ever
find things that were pruned.** The complete picture came from fingerprinting the actual output tree
and asking of each file "who loads this?". Do that first next time.

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

  **AS EXECUTED 2026-07-30.** Promoted as `Fizzygum-tests/scripts/build-tree-fingerprint.js` — NOT
  `homepage-fingerprint.js`, because Phases 0/0.5 fingerprint the **dev** tree too and a name that
  says "homepage" would be a lie in most of its uses. Modes: `write <out>` and
  `compare <baseline> <candidate>`. Three verdicts, deliberately: **0 equivalent / 1 differs /
  2 INVALID**, where INVALID means a fingerprint could not be fully read (its own recorded counts
  disagree with what parsed) — a gate that cannot read its inputs has measured nothing and must not
  say PASS (`fg fuzz`'s lesson, arc 4). All three proven live: identity → 0, planted damage → 1,
  truncated input → 2.

  ⚠⚠ **The prove-it-fails drill caught a real bug in the gate itself, and it is worth knowing why.**
  The comparer keyed sources in a `Map` by NAME — but **source names are not unique**: `Class` and
  `Mixin` are each stored TWICE in a tree (once in their own individually-fetched
  `js/coffeescript-sources/<Name>-source.js`, which the compile bootstrap loads by hand before any
  batch, and again inside a regular batch). The Map silently collapsed those pairs, so the parse read
  500 of 502 sources AND the later entry overwrote the earlier — meaning a planted part change on
  `Class` was reported as *"identical"*. A parity gate blind to the meta-system is worse than none.
  Fixed by comparing a **multiset** of `(name, part)`, plus the self-check that turned it up: the
  parse must account for every source the fingerprint says it recorded.
  (Also simplified while promoting: extraction is now ONE regex capturing name and part together,
  replacing a per-call 4 MB slice heuristic. Safe because build.py's `STRING_BLOCK` escapes the stored
  text so it can contain no raw `"`, `\` or newline — verified byte-identical to the old tool's output
  over a 502-source tree before trusting it.)

  **⚠⚠ TWO CONSTRAINTS ON HOW A PARITY BASELINE MAY BE USED — both discovered while building it
  (2026-07-30). Get either wrong and the gate becomes decorative:**
  1. **A fingerprint is only valid at ONE commit, with no `src/` edits.** `js/pre-compiled.js` and
     every source batch EMBED class source text, so any `src/**.coffee` change legitimately changes
     the tree. ⇒ a parity comparison must be old-mechanism vs new-mechanism **built from identical
     `src/`** — take the baseline immediately before a machinery-only change and compare immediately
     after. This is exactly how arc 4 did it (three builds, `src/` untouched between them). A
     baseline therefore must NOT be committed as a standing file: it would be stale at the next
     source commit and would then be actively misleading. Keep it in `.scratch/` (gitignored),
     re-take it per comparison. (Contrast `scripts/revisit-baseline.json`, which is committed because
     it records a *behavioural profile*, not a byte image.)
  2. **Each Phase 0.5 step has a PREDICTED delta — state it before running, then check it.** These
     steps deliberately change the tree, so "unchanged" is the wrong expectation; "changed in exactly
     this way and no other" is the gate. Note the useful asymmetry: deleting the 5 dead pointer icons
     changes the **dev** tree only (homepage already pruned them), and moving the intermediates out of
     the tree changes **both** — by exactly the 4 files that the homepage prune used to delete.
**`[SEQUENCING, 2026-07-30]` Phases 0 and 1 should be executed as ONE step, and Phase 1.5 should
come BEFORE them.** Two reasons, both learned inside this arc:
- **0 and 1 merge** because Phase 0 as authored ("the loader, no behaviour change") builds a
  mechanism whose only caller arrives in Phase 1 — the exact anti-pattern this arc has already
  corrected twice (arc 4's "don't write API ahead of its callers"; Phase 0.5 step 4's deferral). A
  loader nothing reads cannot be meaningfully gated either: "the dev tree is byte-identical" is
  satisfied trivially by dead code. Introduce the profile mechanism and switch BOTH flavours onto it
  in one step, gated by PR-D4 parity.
- **1.5 first** because it is orthogonal partition work (it does not touch flavour logic at all), and
  doing it first means Phase 1's parity comparison is made against the FINAL partition rather than
  one that is about to change again.

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
  4. ~~Derive font-assets from the entry set~~ **MOVED TO PHASE 0 `[2026-07-30, at execution]`.**
     Deriving it needs the build to know *which entry pages ship* — which is precisely what the
     Phase 0 profile loader computes and hands to the shell. Doing it inside Phase 0.5 would mean
     inventing a one-off channel (build.py writing a `SHIPS_SWCANVAS_ENTRY` fact file) that Phase 0
     replaces immediately — arc 4's case law: **do not write a mechanism ahead of its caller.** The
     `! $homepage` condition therefore stays put for one more phase, and Phase 0 removes it along
     with the rest. ⚠ Whatever does it must keep the idempotent re-prune (§2.2.1).
  Gate each step with `fg build` + the Phase −1 fingerprint (dev tree must change ONLY in the ways
  intended, homepage tree not at all), then `fg gauntlet` once at the end of Phase 0.5 — step 3
  touches what the harness page ships, which the suite runs on.

  **AS EXECUTED 2026-07-30 — steps 1-3 done, step 4 deferred to Phase 0 (above). Each step's
  predicted delta was stated first, then measured:**
  | Step | Predicted | Measured |
  |---|---|---|
  | 1 · delete 5 dead icons | dev −5 files, homepage unchanged (already pruned there) | dev 4607 → **4602**, exactly those 5 `icons/*.png`, sources identical |
  | 2 · intermediates to scratch | dev −4 files, homepage unchanged (already pruned there) | dev 4602 → **4598**, exactly `js/fizzygum-boot.js` + the 3 `js/src/*.js`, sources identical, both boot bundles unchanged in size |
  | 3 · assets → owning part | **pure refactor: dev tree byte-IDENTICAL** | 4598 → 4598, `[FILES] identical`, `[SOURCES] identical` — which also proves build.py copied exactly the right 9 assets, since nothing else copies them any more |
  | all three | production tree byte-unchanged | 28 files, sources identical; the ONLY delta was `fizzygum-boot-native-min.js` +15 bytes — proven to be the dirty-tree stamp (`" +local-changes"` is 15 chars; same commit `7b773269`, same timestamp), i.e. the exemption's documented caveat, not a content change |

  **⚠⚠ A LATENT MASKED FAILURE, found by insisting the new hard-fail be PROVEN (2026-07-30).**
  `copyPartAssets` aborts on a declared-but-missing asset — so I planted one. **The build printed the
  ERROR, `build.py` exited 1, and `fg build` still reported `BUILD EXIT=0 OK`.** Cause:
  `build_it_please.sh` called `python3 ./buildSystem/build.py "${args[@]}"` with **no `$?` check at
  all**, and had done for years — so the single most important step of the build (wrapping every
  source into the batches, writing the parts manifest, generating the entry pages, and now copying
  assets) could fail outright while the build printed `done!!!` and exited 0. Every downstream gate
  passes because none of them depend on build.py's status. Fixed in the same commit, in the style of
  the neighbouring syntax gate, and re-proven: planted asset ⇒ `EXIT=1 FAILED`; restored ⇒ `EXIT=0`
  with `copied 9 part asset(s)` and a byte-identical tree.
  ⚖ **The general lesson is not about assets.** It is that a new failure path is not delivered until
  it has been observed to fail; had I trusted the code, this arc would have added a check that could
  never fire, on top of a build step whose failures were already invisible. Same masked-failure class
  as `build_it_please.sh`'s own umbrella-directory `exit 1` comment.

  Mechanism notes for whoever picks this up: the boot intermediate is now `$BOOT_JS` in
  `$SCRATCH_PATH` (the Automator sed and terser both read it there), the three helpers compile into
  `$JSSRC_SCRATCH`, and `js/src/` is now `mkdir -p`'d explicitly because it used to be created as a
  side effect of compiling into it — terser will not create its output's directory. Assets are copied
  by `build.py`'s `copyPartAssets()`, which **hard-fails on a declared-but-missing asset** rather than
  warning: an asset silently not copied is the exact failure mode this replaced (tree looks fine, an
  `<img>` 404s at runtime).
- **Phase 1 — homepage as data:** author `profiles/homepage.json` reproducing today's flavour
  exactly (parts: core; form: precompiled; sources: background; entries: index.html; extras
  off). Run the PR-D4 parity gate against Phase −1's baseline. Then DELETE every `$homepage` branch
  **and the `--homepage` flag itself — no alias (PR-D1, owner ruling 2026-07-30)**. Gates: parity,
  `fg homepage` green (it now builds via the profile), `fg gauntlet`.
  ⚠ `fg homepage` is the ONLY gate that exercises a production tree at all (boot + no-SW-payload +
  `preCompiled === true` + a whole-world snapshot round-trip) — arc 4 shipped a bug that ONLY it
  could catch. Treat a green `fg gauntlet` as saying nothing about this arc.

  **AS EXECUTED 2026-07-30 — phases 0 and 1 as ONE step. Both flavours moved onto profiles, and
  `--homepage`/`--notests` are gone; a stale one now fails the build loudly (proven, below).**

  **⚖ THE SCHEMA SHRANK FROM FIVE KEYS TO THREE, by applying PR-D6 to the manifest itself.** §1
  sketched `{name, parts, form, sources, entries, extras{fontAssets, tests, videos}}`. Written that
  way, four of those would have been fields that mirror something the build can already compute —
  the exact species this program exists to kill — so each was tested against "what reads it?":
  - **`name`** — the FILE's basename already is the name. A field that must agree with the filename
    is a mirror with two spellings. DROPPED.
  - **`extras.fontAssets`** — derivable, and PR-D6 §2.2.1 already said so: font assets exist only to
    serve an SWCanvas page, so the fact is "does any shipped ENTRY render through SWCanvas". DROPPED
    (this is phase 0.5 step 4, delivered here as planned).
  - **`extras.tests`** — derivable from the `parts` selection itself: a build is test-capable iff it
    ships the `harness` part. Keeping the field would have meant TWO mechanisms deciding one thing,
    with nothing making them agree. DROPPED — and with it `requiresFlag: "tests"` on the harness
    part, which was the same question asked a second time. (`requiresFlag` survives for exactly one
    carrier, `videoPlayer`: a per-invocation opt-in is genuinely not a property of an artifact.)
  - **`sources`** — has NO consumer until phase 2 implements `lazy`/`none`; today `background` is
    what a precompiled boot does by construction. Writing it now would be arc 4's "don't write API
    ahead of its callers" — and a field nothing reads is how `FILE_ONLY_FOR_VIDEOPLAYER` happened.
    DEFERRED to phase 2, to arrive WITH its consumer.
  ⇒ **a profile is `{parts, form, entries}`** — three facts, and a flavour is a file:
  `profiles/dev.json` (`"all"` / compile-at-boot / `"all"`), `profiles/homepage.json`
  (`["core","meta-tools"]` / precompiled / `["index.html"]`), `profiles/dev-notests.json`
  (`{"allExcept":["harness"]}` / compile-at-boot / `"all"`). Both `parts` and `entries` take the same
  three spellings — `"all"`, a list, `{"allExcept":[…]}` — so `"all"` means a new part or entry page
  joins the dev build with no edit anywhere, while the production profile lists its contents
  explicitly (a shipped artifact should be readable in one place, and should NOT silently grow).

  **⚖ ONE READER, THREE CALLERS.** `buildSystem/buildProfile.py` resolves and VALIDATES the profile;
  `build.py` imports it (`partShips`, `loadParts`, `ENTRY_PAGES`), and `build_it_please.sh` +
  `build_and_smoke.sh` + `build_and_test.sh` `eval` its `--shell` output
  (`PROFILE_NAME/FORM/SHIPS_TESTS/SHIPS_SWCANVAS_ENTRY/BOOT_PRELUDE`). It also owns `--profile`
  PARSING, so no caller re-implements it. Two consequences worth keeping: `ENTRY_PAGES` moved OUT of
  build.py into the reader, because the shell needs its SWCanvas column to decide the SW bundle and
  the font assets; and `build_and_test.sh`'s guard now asks "does this profile ship tests" instead of
  matching flavour NAMES, so a future tests-stripped profile cannot sail past it.
  ⚠ `PROFILE_VARS=$(…)` then `eval "$PROFILE_VARS"`, never `eval "$(…)"`: the latter reports the
  EVAL's exit code, so a failed profile read would leave every variable unset and the build would
  cheerfully make a nameless flavour. Same masked-exit-code class as the `build.py` call above.

  **⚖ THE LAST TWO FLAVOUR FACTS IN THE SHELL WERE RE-HOMED, not re-conditioned.** Two `$homepage`
  branches were not derivable from the profile as such, and both turned out to be facts about a PART
  that the build script happened to know:
  - `if ! $homepage` appending `src/boot/numbertimes.coffee` — that file extends `Number` for the
    fizzytiles LiveCodeLang preprocessor, i.e. it exists for ONE part. New `bootPrelude` field in
    `parts.json` (fourth sibling of `dirs`/`assets`/`vendor`), and the shell now cats whatever the
    SHIPPING parts contribute. No part name appears in the build script.
  - the Automator dead-branch `sed` — its real precondition is "no `Automator*` class exists", and
    all three live in the `harness` part, so it derives from `! $PROFILE_SHIPS_TESTS`. This is the
    arc's ONE deliberate behaviour change (see the measured deltas below).
  And the font-assets re-prune moved to the copy site as its `else` branch: `$BUILD_PATH` is shared
  across flavours and `font-assets/` survives the cleanup section, so both directions of ONE decision
  now sit together instead of ~50 lines apart, where the second read as belt-and-braces duplication.

  **MEASURED, against the three baselines taken before anything was touched (PR-D4):**
  | Flavour | Predicted | Measured |
  |---|---|---|
  | dev | byte-identical | **identical** — 502 sources, 4598 entries, `[SOURCES]` and `[FILES]` both identical |
  | homepage | byte-identical (this is the parity gate that licenses deleting the branches) | **identical** — 434 sources, 26 entries |
  | dev-notests | ONE deliberate delta: both boot bundles shrink, because the Automator strip now runs where `--notests` never did it | **exactly that** — `fizzygum-boot-native-min.js` 16551→16266 and `-sw-min.js` 317496→317211, the same −285 B (it is one boot JS fronted twice); source multiset identical; nothing else moved |
  The −285 B is worth noting against the old comment's "~12 KB": that figure was for the strip's
  OTHER application, to `pre-compiled.js`, which carries every class. And because a tests-stripped
  tree is not otherwise exercised anywhere, the stripped bundles were BOOTED to prove them —
  `smoke-boot-headless.js` on the dev-notests tree, both entry pages, clean.

  **⚠ A GENERATED ARTIFACT APPEARED IN THE SOURCE TREE, and the obvious fix did not fix it.**
  `build.py` now IMPORTS a module, so CPython started writing `buildSystem/__pycache__/` — bytecode
  inside a source tree, in an arc about not doing exactly that. `python3 -B` on this script's own two
  calls left it appearing anyway: the build reaches python3 by FOUR paths, and the other three are JS
  gates that `execFileSync('python3', ['buildSystem/build.py', '--list-shippable', …])`. Fixed at the
  root with an exported `PYTHONDONTWRITEBYTECODE=1` (plus `-B` in the three gates for hand-runs, and a
  `.gitignore` line as a backstop). ⚖ The lesson is the same one this arc keeps re-learning at a
  different scale: fix the fact where it is TRUE for every reader, not at the caller you happened to
  notice — and verify by looking at the tree, not at the change.

  **⚠⚠ FIVE NEW FAILURE PATHS, EACH OBSERVED TO FAIL before being called delivered** (the arc's
  standing rule — the two gates that were caught lying were both found this way): a retired
  `--homepage` on the command line ⇒ `unknown argument` + exit 1 (the arg loop's old `*) break`
  forwarded junk silently); a typo'd profile name ⇒ names the available profiles, exit 1; `--profile`
  with no value ⇒ exit 1; a profile naming a part that does not exist ⇒ exit 1 (this is the guard
  that matters at a RENAME: it turns "production silently ships less" into a build failure); a
  profile with an unknown KEY ⇒ exit 1, because a silently-ignored `"from": "precompiled"` would
  ship a compile-at-boot tree while claiming otherwise.

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

  **AS EXECUTED 2026-07-30 (done BEFORE phases 0/1, per the sequencing note above).** New part
  `meta-tools` = `src/meta-tools/` holding `InspectorWdgt`, `ClassInspectorWdgt` and `ConsoleWdgt`;
  `Class`/`Mixin` stay in `src/meta`. Verified before moving anything: the two meta-system files
  reference the three classes in COMMENTS only, and the sole inheritance edge
  (`ClassInspectorWdgt extends InspectorWdgt`) is INSIDE the new part, so nothing crosses the
  boundary. The two core sites are guarded (`return unless InspectorWdgt?` in `Widget.spawnInspector`,
  `return unless ConsoleWdgt?` in `Widget.createConsole`) — at the site that NAMES the class, not at
  the callers. `inHomepage: true`, so production still carries the inspectors.
  Gates: `check-part-edges` went from 432 core sources vs 77 part-owned classes in 9 parts to
  **429 vs 80 in 10**, still 0 unguarded references and 0 inheritance edges; `check-shippable-coverage`
  0 gaps. Tree delta exactly as predicted: the same 502 source NAMES with 3 re-parted, one new
  `sources_batch_meta-tools_0.js`, and the core batches repacked.
  Ghost refs swept: `docs/plans/container-regularization-plan.md` and `Fizzygum/CLAUDE.md` (archived
  plans keep the old paths — they are immutable history).
- **Phase 2 — the new axes:** implement `sources: lazy` (the ingest-only seam, per PR-D3 — NOT
  `ensureLoaded`) and `sources: none` (excluding the `meta-tools` part Phase 1.5 created); add a
  `lean` profile; headless boot-smoke for each shipped profile (console-error-free, `preCompiled`
  state asserted, forbidden-file assertions per profile). Gate: gauntlet + per-profile smokes.
- **Phase 3 — consumers:** re-point the single-file-save plan's banked §7.1 at
  `form: precompiled`; video player flags → profile extras/part; document in CLAUDE.md +
  `docs/architecture/` (build/packaging section) — present-tense, no history prose.
  **`[INHERITED FROM PHASE 0+1, 2026-07-30]` three named leftovers, all deliberate:**
  1. **The `--homepage` mentions in `src/**/*.coffee` comments** (~12, phrases like "ships in
     `--homepage`" meaning "ships in production"). NOT swept in phases 0+1 on purpose: editing shipped
     source text changes the batches and would have destroyed that commit's byte-identical parity
     proof. Two of them are worse than stale and should be fixed first — `FittingSpecText.coffee:16`
     ("or `--homepage` will strip it", referring to the whole-file marker mechanism arc 4 DELETED) and
     `PatchNodeWdgt.coffee:15` ("keep their own exclusion markers"). Also `src/macros/CLAUDE.md`
     (4 sites, incl. a heading "Build-exclusion contract (`--homepage`)").
  2. **The video flags** (`--includeVideoPlayer`, `--includeVideos`, `--keepPreviousPrivateVideos`).
     Left as flags: they are per-invocation opt-ins, and `requiresFlag` now has exactly one carrier
     (`videoPlayer`) which is honest about that. If phase 3 moves them into profiles, `requiresFlag`
     disappears entirely — that is the shape of its retirement, and it should be decided on whether
     "with the video player" is a property of an ARTIFACT or of an invocation.
  3. **`smoke-boot-headless.js --homepage` was renamed to `--production`** (kind 2 in the call-site
     list below, "optional"). Done in-arc after all: a gate whose CLI names a deleted flavour sends
     its next reader looking for a flag, which is the ghost-reference species the doctrine kills.

## §5 Risks

| # | Risk | Mitigation |
|---|---|---|
| ~~R-1~~ | ~~Parity drift while rewriting flavour logic~~ | **DISCHARGED 2026-07-30.** Three baselines taken before anything was touched; dev and homepage came out byte-identical and dev-notests differed in exactly the one predicted way. ⚠ The two constraints on HOW a baseline may be used (Phase −1) both bit in practice and are worth restating: compare at the SAME commit AND the same cleanliness — these three comparisons were all made on a tree that stayed dirty by one docs file throughout, at `f7364e95`, with no `src/` edit between them (which is also why the `src/**.coffee` comments that still say "--homepage" were deliberately NOT swept in this commit: editing shipped source text would have destroyed the parity proof). |
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
| PR-D4 | `node scripts/build-tree-fingerprint.js compare <baseline> <candidate>` | tree equivalence BEFORE deleting any `$homepage` branch |

**`[AS RUN 2026-07-30]` The parity workflow, concretely** — worth copying for phase 2, which changes
what a tree contains and therefore needs the same treatment:
1. BEFORE touching anything, build and fingerprint EVERY flavour the change can reach — for phases
   0+1 that was three (`fg build`, `fg build --profile homepage`, `fg build --profile dev-notests`),
   each into `Fizzygum-tests/.scratch/base-<flavour>.txt`, then restore the dev build. ~2 min, and it
   is the only moment at which the baseline is takeable: after the first edit it is gone.
2. State each flavour's PREDICTED delta in words before running the comparison. "Identical" and
   "these two files, this much smaller, nothing else" are both fine; "let's see" is not — a
   comparison you have not predicted cannot surprise you.
3. Compare, and treat any unpredicted line as a finding, not as noise. (Arc 5 has now been bitten
   twice here: a 15-byte boot-bundle delta that was the dirty-tree stamp, and a comparer that
   reported a planted change as "identical".)
4. Keep baselines in `.scratch/` (gitignored) and re-take them per comparison — a committed baseline
   is stale at the next source commit and then actively misleading.

**`[STANDING 2026-07-30]` Any new failure path must be OBSERVED to fail.** Not reasoned about:
planted, run, and seen to exit non-zero, then restored. This arc caught two gates that could not
fail — `build_it_please.sh` ignoring `build.py`'s exit code for years, and the parity comparer keying
sources by a non-unique name — and both were found by insisting on this and nothing else.
| per profile (Phase 2) | `smoke-boot-headless.js` with per-profile forbidden-file assertions | a profile that ships something it declared absent must fail loudly |

Zero reference churn is the expectation throughout: this arc repackages, it does not change
rendering. A screenshot diff means something is wrong — **do not recapture**; find the cause.

## §8 References

`archive/build-arc-4-dynamic-parts-plan.md` §0.1/§0.2 (program + doctrine),
`archive/build-arc-3-world-harmonization-plan.md`, `archive/build-arc-2-backend-split-precompile-plan.md`,
`archive/build-arc-1-test-serving-link-plan.md` (DONE), `single-file-save-plan.md` (§7.1 consumer), memory
`backend-split-and-precompile-externalization.md` (compiler inventory, owner directions).
