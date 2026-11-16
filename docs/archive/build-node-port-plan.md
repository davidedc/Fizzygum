# The build as a Node program — the plan for round 4's §10

> **STATUS: COMPLETE 2026-11-16 (cleanups loop 4, U8).** Every proof of §5 passed and the port landed.
> `Fizzygum/build_it_please.sh` is a launcher; the build's sequencing is `buildSystem/run-build.js`, and
> `build_and_smoke.sh` launches `buildSystem/run-build-and-smoke.js`. The six differences of §3 hold (difference 5 in
> the script's order: the tests link goes just before the removal of `js/` that holds it, after the removals of the
> pages and icons, which never meet it), with two readings the port needed: `lib/what-runs.js` reads the gate table when any reached file launches `run-gates.js`
> (§0's warning, measured: the old reading of the ported tree loses 70 files), and `writeAll` lives in
> `lib/write-all.js`. The module LAUNCHES the file utilities the script launched, so a failing one says what it said
> (E3), and a Ctrl-C is the running program's to answer, as under the shell; P4's only differences (3 of 92
> scenarios) are diagnostics of the shell's own — a file it could not open, a `cd` that failed, a `node` it could not
> find — which carry a line number of the script. Its standing cases are `run-build-selftest.js` (node tier: the green paths, one exit of
> each kind, the cleaner's refusals, build_and_smoke's flag per profile). §1's count drifted before the port: 40
> `build_failed` sites, not 44 (round 4's §3 removed four). The evidence — the inventory, the readers, the baseline of
> the bash build, the planted layout's 84 scenarios, the fingerprints, the run sets, the real runs — is local to the
> loop, `Fizzygum-tests/.scratch/cleanups-loop-4/u8-build-node/`, beside the scripts it replaced (`*.before`). The
> summary of what landed: `docs/archive/top-10-cleanups-round-4-plan.md` §10, "Landed".

> **PLAN ONLY. Written to be read and executed COLD by an LLM/engineer with ZERO prior context.**
> Authored 2026-11-15 for item §10 of `docs/archive/top-10-cleanups-round-4-plan.md` (read that
> section first: it holds the evidence and the reasons). The owner approved the item the same
> day ("approve all the others along your best recommendation"), and the recommendation was:
> land it and push it when EVERY proof of §5 below passes, and never land it partly proven.
>
> **Mandate.** `build_it_please.sh` stops being a program and becomes a launcher. The build's
> sequencing is a Node module that asks the profile in-process and names the files it reads in
> one place. The trees it writes, the lines it prints and the ways it fails do not change.
>
> **Baseline.** Fizzygum `5e12b629`, Fizzygum-tests `dadc49208`. The script is 669 lines, 260 of
> bash. If round 4's §3 has landed before this starts, the four `sed` lines are already gone;
> port the script as it then stands. Line numbers drift: re-derive §1 from the file.

---

## 0. Orientation

**What the build is.** `Fizzygum/build_it_please.sh [--profile <name>] [--noSyntaxCheck]` writes
`Fizzygum-builds/latest/`. It checks the layout and the toolchain, reads the profile, cleans
the tree, links the tests, runs `buildSystem/build.js` (the assembly: sources, pages, assets),
runs `buildSystem/run-gates.js` (every static gate and every gate's proof), compiles and
minifies the boot code, assembles the boot bundles, copies the fonts, and for a pre-compiled
profile harvests and minifies the image. On 2026-11-15 a dev build took 60.3 s, of which the
gates took 58.3 s.

**Who runs it.** A person; `fg` at three places (`fg build` through `fg-commit-point.js`, and
`fg fingerprint` twice in `fg-verbs.js`); `build_and_smoke.sh`; the watcher one-liner
`build_as_soon_as_anything_changes.sh`. `fg fingerprint` builds its BASE ref in a throwaway
sibling worktree with THAT ref's own script, which is what makes it the proof instrument here:
the base builds with the bash script and the candidate with the Node program.

**Who reads it without running it.**
- `buildSystem/lib/what-runs.js`: the script is a ROOT of its reading (through a shell lexer),
  and `build_and_smoke.sh` is another. The build's census of gates (`run-selftests.js`:
  `GATE_WITHOUT_REGISTRY`, `GATE_WITHOUT_PROOF`) is computed over what that reading reaches. A
  launch the reading stops seeing is a gate that silently leaves the census.
- `buildSystem/lib/build-inputs.js`: `BUILD_FILES` names the script as an input of every build,
  and `SHELL_INPUTS` is a hand list of the files the script reads by name.
- `buildSystem/check-hand-lists.js` names the script; `buildSystem/run-selftests.js` checks it
  exists; `fg-verbs.js` refuses to start without it.
- Three self-tests write a stand-in for it: `fg-gauntlet-selftest-headless.js` (a `#!/bin/sh`
  file at the script's path), `lib/what-runs-selftest.js` and `run-selftests-selftest.js`.

## 1. Inventory: what the script does, in order (re-derive before trusting)

Every exit is 1. `build_failed "<what>"` rings the terminal bell (`tput bel`), prints
`!!!!!!!!!!! error: <what> failed` on stderr and exits 1; the script calls it at 44 places.

1. `cd` to its own directory (a FATAL line on stderr if it cannot).
2. Arguments: `--profile <name>` (a missing name is a one-line error), `--profile=<name>`,
   `--noSyntaxCheck`. Anything else prints four lines on stderr, one of which lists the
   profile files found in `buildSystem/profiles/`. The whole original argument list is kept
   and passed on unchanged to `profile.js`, `build.js` and `run-gates.js`.
3. Layout: the parent must be named `Fizzygum-all` and `../Fizzygum-tests` must exist (each
   failure is a block of lines on STDOUT, not stderr). A missing `../Fizzygum-builds` is a
   warning and is created.
4. The vendored engine: if any of five files under `vendor/swcanvas/` is missing it runs
   `./scripts/vendor-swcanvas.sh`; otherwise, if `vendor/swcanvas.pin` differs from the
   vendored `VERSION`, it prints a two-line warning and goes on.
5. `node` must be on the `PATH`.
6. `mkdir -p` the tree, `touch` its `.build-start`, and record the inputs:
   `node buildSystem/lib/build-inputs.js --record <.build-start>` into
   `.latest-build-inputs.reading` (in `Fizzygum/`).
7. The toolchain: the installed `coffeescript`, `terser`, `acorn` and
   `coffeescript-cognitive-complexity` must be the versions `package.json` pins (a one-line
   message naming `npm ci`). It prints
   `coffeescript version -------------` and the compiler's own version line.
8. The profile: `node buildSystem/lib/profile.js --shell <args>`, `eval`'d. It prints one
   `profile: …` line.
9. Clean: the stamp and the record; `latest/*.html`; `latest/icons`; the tests link, by a
   guarded removal (`[ -L p ] && rm -f p`); `latest/js`. Then it makes `js`, `icons`,
   `js/libs`, `js/coffeescript-sources`, `js/src`, and a fresh scratch directory
   `latest/delete_me`.
10. Tests: a profile that ships them gets `ln -sfn ../../../Fizzygum-tests/tests latest/js/tests`
    and `node ../Fizzygum-tests/scripts/generate-tests-manifests.js --quiet` (a failure exits 1
    with no line of the script's own); any other profile gets the guarded removal again.
11. `node buildSystem/build.js <args>` (a failure: the bell and one line).
12. `node buildSystem/run-gates.js --noSyntaxCheck=<…> --shipsTests=<…> -- <args>` (a failure
    exits 1; the runner has already said why).
13. The boot source, in the scratch directory: `BUILDFLAG_LOAD_TESTS`, `BUILDFLAG_SOURCES`, a
    blank line, the parts manifest `build.js` left there, then each piece of the profile's
    boot prelude, each preceded by a newline.
14. Three facts from git for the build stamp: the short sha, the commit date, and
    ` +local-changes` when the repo is dirty (`no-git` and `unknown-date` without git).
15. The compiler (`-b -c`) on the boot source; the minifier (`--compress --mangle`); then
    `;var buildVersion='Fizzygum <sha> (<when>)<dirty>';` appended AFTER the minifier.
16. The bundles: for a profile with an SWCanvas page, the deterministic trig, its install line,
    the engine, `\n;\n`, SW3D, `\n;\n`, the boot code; for every profile the native bundle,
    which is the boot code alone. The bare minified boot file is then removed.
17. Fonts: a profile with an SWCanvas page removes `latest/font-assets` and copies
    `font-assets/*` afresh (the shell glob skips a top-level dot file); any other profile
    removes `latest/font-assets`.
18. Boot scripts: each of the profile's list is compiled, then minified with `--compress` and
    NO `--mangle`, to `js/src/<name>-min.js`.
19. The pre-compiled stub is copied, four progress lines are printed, the scratch directory is
    removed.
20. A pre-compiled profile: `node scripts/generate-pre-compiled-headless.js` run from the tests
    repo; the minifier (`--compress --mangle`) on the image, moved into place; and for
    `sources: none`, `js/coffeescript-sources` removed and `js/src/dependencies-finding-min.js`
    required to exist and then removed.
21. The stamp: `.build-start` must still exist (else "another build in this tree?"); the
    record's `.reading` file is moved to `.latest-build-inputs`; `.build-stamp` is given the
    START marker's modification time (`touch -r`); the start marker is removed.
22. The bell, and `done!!!!!!!!!!!!`.

`build_and_smoke.sh` (36 lines of bash): reads the profile the same way, chooses the boot
smoke's flag by an if/elif chain (`--lean`, `--production`, `--native-only`,
`--no-harness-page`, or none) and says which, runs the build, runs
`node ../Fizzygum-tests/scripts/smoke-boot-headless.js <flag>`, and reports each stage's
failure in its own words.

## 2. What must stay EQUAL

- **E1, the trees.** For each of the five profiles the tree is byte-identical.
- **E2, the transcript.** On a green build of each profile, stdout and stderr are each
  identical, and so is their merge as `fg`'s log holds it.
- **E3, the failures.** Each exit keeps its code, its text and its stream.
- **E4, the files beside the tree.** `.latest-build-inputs` (the same lines for the same
  inputs), the `.reading` file's life, `.build-start` (there while a build runs, gone after),
  and a `.build-stamp` whose modification time is the start marker's, exactly as the record's
  first line states it.
- **E5, the reading.** Every file `what-runs.js` reaches today it reaches afterwards, each
  running the same way; the gate census is unchanged.
- **E6, the callers.** `./build_it_please.sh <args>` and `./build_and_smoke.sh <args>` keep
  their command lines; `fg`'s three launch sites, the watcher and the three stand-ins in
  self-tests keep working unedited.
- **E7, staleness.** An edit of the new module makes the build STALE for every runner, as an
  edit of the script does today.

## 3. The deliberate differences (the ONLY ones allowed)

1. **The profile is asked in-process.** `lib/profile.js`'s `--shell` mode, `shellQuote` and
   `shellAssignments` go once nothing reads them. Their readers today: this script,
   `build_and_smoke.sh` and `fg-commit-point.js` (round 4's §2 moves the last one; if §2 did
   not land, this unit moves it). If any other reader turns up, `--shell` stays and the ledger
   says who.
2. **The files the build reads by name are named once.** The module exports the list;
   `lib/build-inputs.js` requires it and its `SHELL_INPUTS` goes. The record's lines do not
   change.
3. **The `node` check stays in the launcher**, the only place it can still fail.
4. **`build_and_smoke.sh` computes the smoke's flag in Node** from the resolved profile. Its
   command line, its lines and its exit codes are unchanged, and so are the boot smoke's own
   flags (the smoke's bite proof uses them to read a dev tree as each other kind of tree).
5. **The cleaner is safer than the shell's.** It unlinks `js/tests` after an `lstat`, before
   any recursive removal; its recursive removals never follow a symbolic link; and it refuses
   a tree path that does not end in `Fizzygum-builds/latest`. None of the three can be observed
   on the real layout.
6. **The stamp may be made by renaming the start marker**, which carries its modification time
   exactly. The end state is the one E4 states.

Nothing else: no new flag, no step run in parallel, no change to a tool's arguments, no
message reworded. The compiler and the minifier are still LAUNCHED with today's command
lines; their JavaScript APIs are not used (§7).

## 4. Shape

- A sequencing module under `buildSystem/` (name it by the nearest precedent, `run-gates.js`
  and `run-selftests.js`), with a header that says what it is and `not-a-gate:` as the gate
  runner's does. Its steps are functions that take the layout and the tools as arguments, so a
  self-test can drive them on a planted layout with stand-in tools.
- `build_it_please.sh` becomes a launcher of a few lines: `cd` to its directory, the `node`
  check with today's message, `exec node` the module with `"$@"`. `build_and_smoke.sh` becomes
  a launcher of a second small module.
- The comments move with the code they explain. The script has 340 comment lines that the
  project treats as documentation: each lands above the step it describes, reworded only
  where it speaks of shell.
- Every line the module prints is written straight to its descriptor (`fs.writeSync`), as
  `run-gates.js` does, so it lands in order with what its children write.
- A node-tier self-test, found by name, proves the pieces no real build can exercise on
  demand (§5, P4 and P6).

## 5. The proofs, in order

The unit is done when all ten pass. Each one's evidence is kept in the unit's scratch
directory and summarised in the ledger.

- **P1, the inventory.** §1 re-derived from the script as it stands: one row per step, and one
  row per exit with its condition, its stream, its text and its code.
- **P2, the readers.** Every file in both repos that names `build_it_please.sh`,
  `build_and_smoke.sh`, `--shell`, `SHELL_INPUTS` or a `PROFILE_` variable, each with what it
  needs from the port.
- **P3, the baseline, on the untouched tree.** For each of the five profiles: stdout, stderr,
  their merge, the exit code, the tree's fingerprint, `.latest-build-inputs`. For
  `build_and_smoke.sh`: its transcript for each profile.
- **P4, old against new on a planted layout.** A scratch directory named `Fizzygum-all`
  holding a stand-in `Fizzygum/`, `Fizzygum-tests/` and `Fizzygum-builds/`, with stand-in
  tools that pass or fail on demand. The bash script and the Node program are each run there
  through every exit of P1 and through the green path: the same stdout, the same stderr, the
  same code, the same files left. An exit no plant can reach is named with the reason.
- **P5, the dangerous steps, on scratch only, BEFORE the first run on the real layout.** A tree
  whose `js/tests` links to a directory holding a sentinel file: after the clean the sentinel
  stands, the link is gone, and nothing under the link's target changed. A `font-assets`
  holding a top-level dot file: not copied. A tree path that does not end in
  `Fizzygum-builds/latest`: refused. The stamp's modification time equals the start marker's.
- **P6, old against new on the real layout.** `fg fingerprint <profile> <the commit before>`
  for `dev`, `dev-precompiled`, `dev-notests`, `homepage` and `lean`: no differing entry. The
  transcripts of P3 against the new ones: identical. `.latest-build-inputs`: identical but for
  the lines of the files this unit added or changed.
- **P7, the reading.** `what-runs.js`'s run set before and after: nothing lost, each file
  running the same way, the new modules added. The build's gate census passes, and
  `lib/what-runs-selftest.js` still tells a launch from a mention.
- **P8, the real runs.** `fg build`, `fg presuite`, `fg gauntlet`, `fg homepage`, and
  `./build_and_smoke.sh` for each of the five profiles (the same flag chosen as in P3).
- **P9, the standing self-tests.** The new one, and unedited: `fg-gauntlet-selftest-headless.js`
  (the gauntlet's `selftests` leg), `lib/what-runs-selftest.js`, `run-selftests-selftest.js`,
  `lib/build-inputs-selftest.js`.
- **P10, staleness and the interrupted build.** An edit of the new module reads STALE in
  `fg status` and to a runner, and FRESH after a build. On the planted layout, a build killed
  after its start marker is written leaves what the bash script leaves, and the next build
  does what the bash script's next build does.

## 6. Risks

- **A recursive delete through the tests link.** `rm -rf <link>/` with a trailing slash deletes
  the real suite (`docs/archive/build-arc-1-test-serving-link-plan.md` §0.2(4) has the matrix).
  P5 comes before any real run for this reason. If it ever happens: the working tree only is
  lost, and `git -C Fizzygum-tests checkout -- tests/` restores it.
- **Landing it partly proven.** Forbidden. If the time box ends before P8, or any exit of P4
  differs, the unit is parked with its patch and its evidence, and the script in git stays the
  build.
- **A build that cannot build.** Keep `<scratch>/build_it_please.sh.before` and
  `<scratch>/build_and_smoke.sh.before` from the first minute; restore them before anything
  else if the Node build fails to produce a tree.
- **Output order.** A child inherits the descriptors and the module writes synchronously; a
  buffered `console.log` beside a child's output would reorder the merged transcript.
- **The watcher and the stand-ins** depend on the launcher's path and on its being a shell
  file. Both are kept.

## 7. Rejected alternatives (do not re-attempt)

- **The compiler's and the minifier's JavaScript APIs in place of their command lines.** Not
  provably the same bytes: the command lines parse their options their own way.
- **Deleting `build_it_please.sh`.** It is the documented command, a root of `what-runs.js`,
  `fg`'s launch target and what three self-tests stand in for.
- **Giving the boot smoke a `--profile` flag in place of its four.** The survey's first draft
  proposed it. The smoke's bite proof uses the four flags to read one dev tree as each other
  kind of tree, so they stay; only the bash mapping moves (§3, difference 4).
- **Running steps in parallel.** Not this item. Round 4's §6 owns the gates' speed.
- **A test rail in the environment to point the build at another tree.** The retired runner
  rails are the precedent against it; the steps take the layout as an argument instead, and
  only a self-test passes another.

## 8. Start prompt for a fresh session

```
Read Fizzygum/docs/archive/build-node-port-plan.md in full, then §10 of
Fizzygum/docs/archive/top-10-cleanups-round-4-plan.md. Run
/Users/davidedellacasa/code/Fizzygum-all/fg status and confirm nothing is running and both
repos are clean.

Carry out the plan's proofs P1 to P3 (all read-only or on the untouched tree) and show me the
inventory table and the list of readers. Wait for my go-ahead before writing the module.
Never land it partly proven. Do not commit or push without asking me.
```
