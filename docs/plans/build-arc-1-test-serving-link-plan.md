# Arc 1 · Test-serving link — replace the per-build tests COPY with a symlink; manifests move to the tests repo

**STATUS: PLAN ONLY — AUTHORED 2026-07-28.** Written to be executed COLD by an LLM/engineer
with ZERO prior context. All facts verified against the working trees on 2026-07-28 (Fizzygum
`master @ ae45e0ff`, Fizzygum-tests `master @ 9e69fb19e`, 268 SystemTests, 4,150 files in
`Fizzygum-tests/tests/`). Line numbers drift — quoted code is authoritative; re-grep before
editing. **This is ARC 1 — the FIRST arc to execute — of the build-and-packaging
program** (program table + completion doctrine: `build-arc-4-dynamic-parts-plan.md`
§0.1/§0.2, binding here). It is independent of the later arcs; arc 2
(`build-arc-2-backend-split-precompile-plan.md`) edits the same `build_it_please.sh` in
disjoint sections and runs AFTER this one completes.

**MANDATE.** Tests stop being COPIED into every build. The build places ONE relative symlink
(`js/tests` → the tests repo's `tests/` directory); the flatten and the manifests move to
where the tests live. Per the completion doctrine, the following die IN THIS ARC: the ~4,150-
file copy step + its spinner, the flatten (body-file and asset-file `find`+`mv`), the
`--keepTestsDirectoryAsIs` flag and every workflow trap it spawned, `build.py`'s two
manifest-generation functions, and `fg recapture`'s publish-rebuild step.

---

## §0 Orientation

Fizzygum umbrella: three sibling repos (`Fizzygum` source, `Fizzygum-tests` suite,
`Fizzygum-builds` generated output; the umbrella dir itself is not a repo). Everything runs
over `file://`; all runtime loading is `<script>` injection (there is no fetch/XHR anywhere).
Use `/Users/davidedellacasa/code/Fizzygum-all/fg` (absolute path) for build/test commands.

### §0.1 Critical reframes (verified 2026-07-28 — the plan's spine)

- **R1: The "file:// pages can only load from their own folder or lower" belief is FALSE on
  both engines the suite uses.** Empirical probe (`Fizzygum-tests/.scratch/file-url-loading-probe.js`,
  re-runnable): headless Chromium (puppeteer, the default runner) AND Playwright WebKit (the
  `webkit` leg) both load `<script src>` through `../` paths escaping the page's directory AND
  through a symlinked directory pointing outside the tree — all four probes true, zero request
  failures (images load too). The folklore rule is Firefox's fetch/XHR restriction; Fizzygum
  never fetches. The copy exists for a constraint that does not bind here.
- **R2: The manifests ALREADY scan the repo, not the copy.** `build.py`'s
  `generateTestsManifests`/`generateTestsAssetsManifests` (build.py ~:88-160) list
  `../Fizzygum-tests/tests/` directly: `testsManifest` = sorted test DIRECTORY names;
  `testsAssetsManifest` = repo-relative NESTED paths of every `SystemTest_*…-dataHash….js`
  reference (extension stripped). Moving generation into the tests repo is the same scan,
  relocated.
- **R3: The flatten's only runtime trace is one line — and the pre-flatten form is still there,
  commented out.** `Automator-and-test-harness-src/AutomatorLoader.coffee:153`:
  `script.src = "js/tests/assets/" + eachAssetInManifest.split("/").pop() + ".js"` — with the
  natural nested form preserved at the commented :152. The flatten was a workaround for the
  Windows/Edge ~260-char path limit (build script comment, Nov 2018). Measured today: the
  longest natural relative path is **388 chars** (≈450 absolute) — fatal for 2018 Windows,
  irrelevant on macOS (PATH_MAX 1024) and for current browsers' file:// URLs.
- **R4: What the copy's death kills** (the staleness class the owner remembers): the
  `--keepTestsDirectoryAsIs` trap-space (stale tests riding inside a "fresh" build), the
  first-capture-of-a-brand-new-test trap (test absent from the build-time manifest →
  "did not select exactly one SystemTest"), `fg recapture`'s publish-rebuild (references
  captured into the repo become live on the next page load, no rebuild), and ~4,150 files of
  churn per build inside the `Fizzygum-builds` git repo.

### §0.2 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — clean trees, note test count.
2. Read this doc fully; re-grep every quoted symbol/line before editing.
3. This arc runs FIRST in the program; arc 2 (backend split) edits the same
   `build_it_please.sh` afterwards — do not interleave them.
4. ⚠⚠ **Symlink safety — MEASURED semantics (sandbox-verified on this macOS, 2026-07-28;
   re-runnable, throwaway dirs only, never on real repos):**

   | Spelling | Measured effect |
   |---|---|
   | `rm -rf <link>` (no slash) | removes the LINK only — target intact |
   | `rm -rf <link>/` (trailing slash) | **DELETES THE ENTIRE TARGET DIRECTORY**; the dangling link survives |
   | `find <link> …` | does not descend — safe |
   | `find <link>/ …` or `find -L …` | descends into the target — destructive when paired with `-delete`/`-exec rm` |
   | `rm -f <link>` (no `-r`) | removes the link; on a real directory it REFUSES ("is a directory") — **structurally incapable of recursion** |
   | `ln -sf <target> <link>` (no `-n`, link exists) | creates a STRAY LINK **inside the target** (junk injected into the tests repo) |
   | `ln -sfn <target> <link>` | idempotent, correct — the only creation form allowed |

   Rules that follow: the ONLY removal form ever used on the link is a guarded helper
   (`[ -L "$p" ] && rm -f "$p"` — `rm -f` cannot recurse even if the guard is wrong); the
   ONLY creation form is `ln -sfn`; recursive/`find` operations on `$BUILD_PATH/js/tests`
   are BANNED in any spelling (the safe-looking one is one keystroke from the fatal one).
   Blast-radius fact: the link targets the `tests/` SUBDIRECTORY — `.git` lives one level up
   and is unreachable through the link, so the worst case is a working-tree delete,
   restorable with `git -C ../Fizzygum-tests checkout -- tests/` (only uncommitted test
   changes would be lost). **Precondition for Phase 1: `fg status` shows Fizzygum-tests
   dirty=0**, so the git backstop is total during the cut. Audit
   `grep -n 'js/tests' build_it_please.sh buildSystem/*.py` at every phase close.
5. Owner gates: never commit/push without approval; the `Fizzygum-builds` history rewrite
   (untracking the old copied tests) is a separate owner-approved commit.

---

## §1 Goal and decisions

| # | Decision | Choice | Status |
|---|---|---|---|
| L-D1 | Link form | A RELATIVE symlink created by the build: `ln -sfn ../../../Fizzygum-tests/tests "$BUILD_PATH/js/tests"` (relative so the umbrella can relocate; `-n` so re-runs replace the link, never write through it). ⟨verify the exact ../ depth from `$BUILD_PATH/js` at execution⟩ Committed into `Fizzygum-builds` as a symlink entry; it dangles harmlessly on machines without the sibling (tests only run in the umbrella; homepage/gh-pages ship no tests). | LOCKED |
| L-D2 | Layout served | The tests repo's NATURAL per-test-directory layout. The flatten is deleted, not relocated (its 2018 Windows rationale is dead — R3). Loader adapts (§5.2, three lines). | LOCKED |
| L-D3 | Manifests | Generated INTO `Fizzygum-tests/tests/` (`testsManifest.js`, `testsAssetsManifest.js` — same filenames, so the boot loads at `globalFunctions.coffee:194-195` are untouched) by a new tests-repo script; **gitignored**; every headless runner + capture script regenerates them at startup (a millisecond `fs` scan) so manifest staleness is structurally impossible. `npm run manifests` for the manual-browser flow. An `--keep-manifests` escape hatch preserves the hand-edit affordance the manifest header documents (ordering / subsetting). | LOCKED |
| L-D4 | `--keepTestsDirectoryAsIs` | DELETED (flag, docs, and every `$keepTestsDirectoryAsIs` branch) — with a live link there is nothing to keep or refresh. `fg`'s related freshness machinery is retired in the same arc. | LOCKED |
| L-D5 | Homepage / `--notests` | Simply do not create the link (and `[ -L ]`-guarded `rm -f` any existing one). The homepage tree contains no `js/tests` entry at all. | LOCKED |
| L-D6 | Fizzygum-builds slimming | `git rm -r --cached` the previously committed copied tests from `Fizzygum-builds` in one owner-approved commit; the repo shrinks by the copied-test payload and stops churning per build. | LOCKED (execution owner-gated) |

Non-goals: changing what tests ARE or how they run; touching reference-image formats; any
Windows support work (noted as a future constraint only).

---

## §2 Exact current state (verified 2026-07-28)

### 2.1 The copy + flatten (`Fizzygum/build_it_please.sh`)

- `:748-776` — `cp -r ../Fizzygum-tests/tests/* $BUILD_PATH/js/tests/assets &` with a
  spinner polling file counts ("this could take a minute"; 4,150 files today).
- `:793` — body-file flatten: `find $BUILD_PATH/js/tests -iname 'SystemTest_*.js'
  ! -iname '*-dataHash*' -exec mv {} $BUILD_PATH/js/tests \;` (the `-dataHash` discriminator
  separates step files from reference files).
- `:802` — asset flatten: every `SystemTest_*.js` under `assets/` moved into flat
  `assets/` (the 2018 Windows path-length workaround; comment at ~:797-800).
- `:167-180` — `--keepTestsDirectoryAsIs` support: cleaning `$BUILD_PATH/js` while
  PRESERVING `js/tests`; `:237-238` — `mkdir $BUILD_PATH/js/tests` scaffolding.
- Homepage tail (~:812) — `rm $BUILD_PATH/worldWithSystemTestHarness.html`; and the
  non-homepage/no-tests conditionals guard the whole copy section.
- ⟨grep `keepTestsDirectoryAsIs` across the repo at execution — flag parsing, docs, and
  `capture-macro-test-references.js`'s first-drop build use it too⟩

### 2.2 Manifests (`Fizzygum/buildSystem/build.py` ~:88-160)

Both functions scan `../Fizzygum-tests/tests/` (the REPO) and write into
`../Fizzygum-builds/latest/js/tests/`. `testsManifest` entries = test names (directory
names). `testsAssetsManifest` entries = nested repo-relative paths, `.js` stripped, selected
by `-dataHash in filename` (hash-format-agnostic — the six-digit-suffix bug is case law,
comment preserved in the code). The manifest header documents the hand-edit affordance
(order / subset) — preserve that text in the relocated generator.

### 2.3 Consumers of the served layout

- Boot: `src/boot/globalFunctions.coffee:194-195` loads `js/tests/testsManifest.js` +
  `js/tests/testsAssetsManifest.js` (under `BUILDFLAG_LOAD_TESTS or ?generatePreCompiled` —
  arc 2 Phase C narrows this to `BUILDFLAG_LOAD_TESTS`).
- Loader: `AutomatorLoader.coffee:17` (`js/tests/<name>_automationCommands.js`), `:182`
  (`js/tests/<name>.js`), `:153` (assets, basename-popped — the flatten's trace, R3).
- Headless scripts: NO direct `js/tests` references (they drive the page's own APIs).
- `check-refs.js` and the capture pipeline operate on `Fizzygum-tests/tests/` directly
  ⟨verify check-refs' base path at execution⟩; capture's "publish" today = rebuilding so the
  copy picks up new references.

### 2.4 The probe (R1) — result matrix

| Load | Chromium headless | Playwright WebKit |
|---|---|---|
| `<script src="../outside/...">` (escapes page dir) | ✓ executes | ✓ executes |
| `<script src="linkdir/...">` (symlink → outside) | ✓ executes | ✓ executes |
| `new Image()` both ways | ✓ loads | ✓ loads |

## §3 Why it is shaped this way

The copy predates this machine and this decade: Nov-2018 Windows (Edge + Chrome) enforced the
~260-char path limit that the natural nested reference paths (388 chars relative today)
exceeded — hence copy-then-flatten; and the same-folder folklore made a sibling-repo link feel
impossible. Both constraints are gone (R1, R3); the copy survived because it worked, and the
staleness traps it created were patched around (`--keepTestsDirectoryAsIs`, fg freshness
gates, recapture's publish rebuild) rather than removed.

## §4 The distilled argument

One symlink + a relocated directory scan replace a 4,150-file copy, a two-stage flatten, a
flag, and an entire class of freshness bugs — and the change surface is tiny and enumerable:
three loader lines (one of which is a revert to code still present in a comment), two boot
lines untouched, one build-script section deleted, one small Node script added where the
tests (and their authors' tooling) already live. Every staleness trap this kills is one the
project has case law for; none of that case law needs to exist afterwards.

---

## §5 Design & phases

### Phase 0 — manifest tooling in the tests repo (transition-safe: build.py still active)

- New `Fizzygum-tests/scripts/generate-tests-manifests.js`: ports the two build.py scans
  verbatim (same sorting, same `-dataHash` selection, same header comments incl. the
  hand-edit note), writing `Fizzygum-tests/tests/testsManifest.js` +
  `…/testsAssetsManifest.js`. Add both filenames to the tests repo `.gitignore`; add
  `npm run manifests`.
- Hook it into every entry point that opens the harness: `run-all-headless.js`,
  `run-macro-test-headless.js`, `capture-macro-test-references.js`, `run-sequence-headless.js`,
  the gate/audit runners that load tests ⟨enumerate by grepping `worldWithSystemTestHarness`
  in `scripts/` at execution⟩ — each regenerates at startup unless `--keep-manifests`.
  ⚠ The generator must EXCLUDE its own two output files from the asset scan (they live inside
  `tests/` now) — they don't match the `-dataHash` filter, so the port is naturally safe;
  assert it with a self-check.
- Gate: generated manifests byte-match build.py's output (modulo the documented header), diffed
  against a fresh build's copies.

### Phase 1 — the link + loader + deletion (one coordinated cut across the three repos)

1. **Loader** (`AutomatorLoader.coffee`, tests repo): `:17` and `:182` gain the per-test
   directory (`"js/tests/" + name + "/" + name + "…"`); `:153` reverts to the nested form
   (`"js/tests/" + eachAssetInManifest + ".js"` — note: relative to `tests/` root, NOT
   `assets/`). Delete the flatten-era comments (:135-152) — present-tense code only.
2. **Build** (`build_it_please.sh`): delete the copy+spinner+flatten section (:748-806) and
   the `--keepTestsDirectoryAsIs` flag with all its branches (:167-180, flag parsing, usage
   text); replace `:237-238` scaffolding with the L-D1 `ln -sfn` (non-homepage, non-notests)
   or the L-D5 guarded removal (homepage/notests). Audit every surviving
   `$BUILD_PATH/js/tests` reference per §0.2(4).
3. **build.py**: delete `generateTestsManifests`/`generateTestsAssetsManifests` and their
   call sites.
4. **fg** (umbrella, uncommitted tooling): `fg recapture` drops its publish-rebuild step
   (captured references are live through the link); freshness checks tied to the tests copy
   removed; `fg status` test count now reads the repo (⟨verify — it likely already does⟩).
5. **Guard hook (structural protection for future sessions)**: extend the umbrella's
   PreToolUse hook (`.claude/hooks/fizzygum-cmd-guard.py`, local/uncommitted like `fg`) to
   BLOCK any Bash command that combines `js/tests` with a recursive-destructive shape:
   `rm -r`-family with `js/tests/` (trailing slash), `find` + (`-delete`|`-exec`) touching
   `js/tests`, and `find -L` touching the build tree — with a message pointing at the §0.2(4)
   safe forms. This turns the discipline into a machine check at the most likely typo source
   (LLM sessions).
6. **Build-script helper**: one `remove_tests_link()` function (`[ -L … ] && rm -f …`) and
   one `ln -sfn` site — no other code ever spells an operation on the link.
7. **Docs**: root + Fizzygum + Fizzygum-tests `CLAUDE.md` sections describing the copy,
   `--keepTestsDirectoryAsIs`, and recapture's rebuild — present-tense rewrite; the §0.2(4)
   matrix's rules land in the root CLAUDE.md's shell-discipline section (one line + pointer).
- Gates: full `fg gauntlet` (dpr1/dpr2/**webkit**) — zero reference churn expected (same
  bytes served through a link); `fg homepage` + assert NO `js/tests` entry in the homepage
  tree; `fg recapture <one test>` end-to-end WITHOUT any rebuild, prints COMPLETE; author a
  throwaway test dir + run the single-test flow to prove the new-test path needs no build.

### Phase 2 — Fizzygum-builds slimming + close-out

- Owner-approved commit in `Fizzygum-builds`: untrack the previously committed copied tests
  (`git rm -r --cached`), commit the symlink entry. (History stays; the repo stops growing
  per build.)
- Close-out checklist (doctrine): `grep -rn keepTestsDirectoryAsIs` across all three repos +
  umbrella = 0 hits; `grep -n 'cp -r ../Fizzygum-tests' build_it_please.sh` = 0; build.py has
  no tests-manifest code; the two case-law memory notes about copy-staleness traps get their
  "resolved by test-serving link" annotations.

## §6 Risks & mitigations

| # | Risk | Mitigation |
|---|---|---|
| R-1 | ⚠⚠ A trailing-slash `rm -rf`/`find -L` on the symlink deletes REAL tests (measured — §0.2(4)) | Defense in depth: steady state contains ZERO recursive ops on the path (they die with the copy machinery); the only surviving ops are `ln -sfn` + the `remove_tests_link()` helper whose `rm -f` cannot recurse; the guard hook blocks dangerous spellings in LLM sessions; blast radius is the `tests/` working tree only (`.git` is outside the link target) with `dirty=0` as the Phase-1 precondition — git restores it in seconds |
| R-2 | A consumer of the flat layout survives unnoticed | §2.3 enumeration + execution-time grep of `js/tests` across all three repos; the suite itself is the detector (a missed site 404s loudly and fails a shard) |
| R-3 | Manifest regenerate-always breaks the hand-edit (order/subset) affordance | `--keep-manifests` escape hatch (L-D3); header comment documents it |
| R-4 | Capture writing references while a suite reads them (now the SAME files, live) | Same-machine workflows already serialize via `fg` (killz + verdicts); add a note to the capture script banner; do not run capture and suite concurrently — previously the copy isolated them, now discipline does |
| R-5 | Fresh clone / missing manifests on manual browser open | Any runner invocation (or `npm run manifests`) creates them; harness page fails loudly (manifest 404) otherwise |
| R-6 | Windows ever returns (symlink privileges + 260-char paths) | Banked: the bare-`../`-paths variant (loader prefix instead of a link) avoids symlinks; long-path support is OS-configurable now; not this arc's problem |
| R-7 | gh-pages / non-umbrella clone sees a dangling symlink | Harmless by design (L-D1); homepage trees have no link at all (L-D5) |

## §7 Verification protocol

`fg presuite` inner loop; Phase-1 close = full `fg gauntlet` in background + log + verdict
(never foreground-poll; boot-storm flake ≠ code bug) + `fg homepage` + the no-rebuild
recapture proof. Re-run the R1 probe (`node .scratch/file-url-loading-probe.js` from
`Fizzygum-tests/`) if any engine is updated and file:// behaviour is in doubt. (`.scratch/` is
gitignored; if the probe file is gone, reconstruct it: a temp dir with `pageroot/index.html`
loading one `<script src="../outside/p1.js">` and one script through a symlinked
`pageroot/linkdir → ../outside`, driven headless by puppeteer AND playwright-webkit, asserting
both scripts set their `window` flags with zero request failures.)

## §8 Rejected alternatives (do NOT re-attempt)

1. **A derived "served view" in the tests repo (symlink-farm or hardlink flatten)** — keeps
   the flatten concept alive in new clothes for a dead constraint; doctrine prefers deletion.
2. **Bare `../../Fizzygum-tests/…` loader paths, no symlink** — works (R1 proved it), but
   bakes the umbrella layout into runtime URLs and complicates homepage/notests handling;
   the link centralizes layout knowledge in one build-script line. Banked as the Windows
   fallback (R-6).
3. **Committed manifests + a staleness gate** — weaker than regenerate-always; reintroduces
   the freshness-check species this arc exists to kill.
4. **Incremental copy (rsync)** — kills the copy's cost, keeps the staleness class. Misses
   the point.

## §9 References

Program + doctrine: `build-arc-4-dynamic-parts-plan.md` §0.1/§0.2. Case law being retired:
memory `fizzygum-recapture-masks-crash-webkit-safeguard` (publish-rebuild era),
the first-capture manifest trap (`fizzytiles-sw3d-port` memory, lesson 3),
`build-cwd-stale-build-trap`. Probe: `Fizzygum-tests/.scratch/file-url-loading-probe.js`
(results §2.4). Next arc: `build-arc-2-backend-split-precompile-plan.md`
(shares `build_it_please.sh`; runs after this arc closes).
