# Top 10 code and architecture cleanups — a survey, ordered by effort

> **PLAN ONLY. Written to be read and executed COLD by an LLM/engineer with ZERO prior context.**
> This is a SURVEY of ten candidate arcs, authored 2026-11-11 and ordered by effort, smallest
> first. Each item is a proposal with its evidence, and four of the ten need an owner decision
> before any code moves (marked in the table under "The list at a glance").
>
> **STATUS.** Since 2026-11-12 an unattended `/loop`, launched by the owner, executes these items or
> their parts, one unit at a time: §1 but for its owner questions, §4, §5, §6, §7's first step, both
> steps of §8, and §10. Its brief (local to the loop) rules their small choices and leaves §2, §3,
> §9 and §7's second step to the owner. The table's last column and a `**Landed <date>.**`
> paragraph in each item's section say what has landed; the trailing `## BACKLOG ledger` holds the
> closed BACKLOG lines.
>
> **Mandate.** Each item aims at ELIMINATING a duplicated mechanism or a dead one, not at making it
> easier to live with. Where an item stops short of elimination, it says why.
>
> **Baseline.** Every number below was measured on 2026-11-11 at Fizzygum `cecd7891` and
> Fizzygum-tests `bd13abcb0`. Line numbers drift: the method name or the quoted code is the
> authority, and every item carries the command that re-measures it. Statements are labelled
> **MEASURED** (a command was run), **READ** (the code was read) or **UNVERIFIED** (a hypothesis
> the item's first step must test).

---

## 0. Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework drawn on one `<canvas>`. Three sibling
git repos sit under an umbrella directory `Fizzygum-all/` that is not itself a repo: `Fizzygum/`
(source and build), `Fizzygum-tests/` (the SystemTest suite, the harness and the headless rigs)
and `Fizzygum-builds/` (generated output). Read `Fizzygum/CLAUDE.md` and
`Fizzygum-tests/CLAUDE.md` before touching anything.

**Why a survey now.** The tree is unusually well policed. The build runs 33 static gates, the
commit-point check (`fg gauntlet`) runs 20 legs, and the usual local smells sit at ratcheted
baselines: duplicated text, dead methods, unresolved sends, call-argument holes and thin wraps are
all at or near zero. A cleanup list made by grepping for smells would therefore find little. What
is left is structural, and no gate measures it. That is what this survey looked for.

**Two reframes that shaped the list.**

1. **Line counts mislead here; method counts and mechanisms do not.** `Widget.coffee` is 6,291
   lines, but 2,497 of them are code (the rest are comments and blank lines, which this project
   treats as a deliverable). Against the base of the June god-class arc (`4c684991`, 2026-06-17)
   its code SHRANK from 2,623 lines, while its method count GREW from 310 to 382. Across `src/`
   the split is 38,332 code lines to 31,425 comment lines in 561 files. So "the file is huge" is
   not a finding; "the class gained 72 methods and nothing counts them" is (§8).
2. **The remaining debt is duplicated MECHANISM, not duplicated text.** The exact-clone and
   near-clone scanners have been run to exhaustion. What they cannot see is two different ways of
   asking one question (§6), one pattern written out by hand eight times with small variations
   (§7), or one fact stated in two languages (§10).

**How the list was made.** Sizes, class and method censuses, the existing censuses
(`census-hierarchy-duplication.js`, `census-widget-conformance.js`), the stink ratchets
(`check-stinks.js`), the cognitive-complexity tool (`coffee-cc`), reference counts for every
suspect file, and a read of the code behind each candidate. Then each candidate was checked
against `docs/BACKLOG.md`, the active plans and `docs/archive/INDEX.md`, and dropped if an active
plan already owns it (§12) or if earlier case law rejected it without new evidence (§13).

**Order.** The items are ordered by effort, smallest first, so the cheap ones can be taken without
reading the expensive ones. Effort means the whole item, both steps where it has two, including
its verification runs (one gauntlet is 15 to 20 minutes). The figures are ESTIMATES in working
days, made from the evidence in each item; none is measured, and two items within half a day of
each other could swap. Two items (§7, §8) have a small first step that stands alone, and the
table shows it.

The table's last column keeps the other useful ordering, by payoff: removed mechanism, weighted by
confidence in the evidence, divided by cost and pixel risk (1 is the best return).

---

## 0.5 Cold-execution protocol

1. **This document is a menu, not a script.** Pick ONE item. Do not batch items; they are
   independent except where an item names a dependency.
2. **Re-measure first.** Run the item's re-measure command and compare with the numbers here. If
   they differ materially, the tree moved: re-read the code before trusting the fix shape.
3. **Items marked "owner decision first" stop at the decision.** Present the evidence and the
   options; do not start the code.
4. **An item that is taken up becomes its own plan** in `docs/plans/` when it is more than a day's
   work (§5 to §10; for §7 and §8, their second steps), following `docs/README.md`'s filing
   rules; its line in `docs/BACKLOG.md` then points at the new plan and this survey's line for
   it is removed.
5. **Verify with the shared protocol in §14**, plus whatever the item adds.
6. **Never commit or push without the owner's approval.** Present a summary and the proposed
   commit message and wait.
7. **If a long operation is running in another session** (`cat /tmp/fg-*.verdict` shows
   `RUNNING`), do not edit sources or run a build: a running `fg` operation owns its inputs.

---

## The list at a glance

Ordered by effort, smallest first. Effort is an estimate in working days for the whole item.
"Payoff rank" is the order by return on that effort (1 is the best).

| # | Cleanup | Effort (estimate) | What goes away | Pixel risk | Owner decision first | Payoff rank | Status |
|---|---|---|---|---|---|---|---|
| 1 | Repository hygiene | ½ day | 9 orphan files, a second vendoring directory, closed plans in the wrong repo, an empty skip-list mechanism | None | Partly | 10 | Orphans, closed plans, the stub header and the two vendoring homes landed 2026-11-13; the rest open |
| 2 | Put `fg` and the guard hook under version control | ½ day | An unversioned 929-line definition of the whole verification pipeline; an "fg absent" branch in the build's own tooling | None | Yes: which repo | 1 | Not started |
| 3 | The video-player part: delete it or gate it | ½ to 1 day (deletion) | A part no gate runs, the one-carrier `requiresFlag` mechanism, 3 build flags, 9 scripts, 5 open defects | None | Yes | 7 | Not started |
| 4 | Silent invariant traps report, or go | 1 day | 15 invariant checks that cannot fail a run | May expose live faults | No | 6 | Landed 2026-11-13; no trap fired |
| 5 | Lift the browser-input bridge off `WorldWdgt` | 2 days | 7 methods and the listener closures from the world class | Low | No | 9 | Landed 2026-11-13 |
| 6 | One plane-mapping protocol for the ancestor walk | 3 days | 8 hand-written walks, 10 type tests of a subclass inside the base class, a second way of asking one question | Low, hot path | No | 3 | Landed 2026-11-13 (built and parked on a speed trade; landed on the owner's ruling) |
| 7 | Derived-geometry caches: one oracle, then one memo | ½ day (step 1 alone), then 3 days | 17 copies of the oracle block, 17 `debugger` lines, 8 hand-kept field pairs | None, then hot path | No | 4 | Step 1 (one oracle) landed 2026-11-13; step 2 open (owner) |
| 8 | Ratchets for method count and complexity; split the sequential giants | 1 day (ratchets alone), then 2 to 3 days | Unbounded regrowth of the four largest classes | None for the ratchets | No | 8 | Landed 2026-11-13 (both steps; three giants split, three left) |
| 9 | Icon shells: one `IconWdgt` and a derived icon catalog | 4 to 5 days | About 69 class files (12% of all source files), 58 creator methods, 55 hand-written menu rows | Low to medium | Yes | 5 | Not started |
| 10 | Build logic in one language; the gate sequence as data | 5 to 6 days | Python from the toolchain (1,067 lines), 11 cross-language process bridges, about 36 copies of one bash block | None (byte-identical trees) | No | 2 | Landed 2026-11-13 (both steps) |

---

## §1. Repository hygiene

**Effort.** About half a day, in independent commits. The orphan deletions are minutes. The
vendoring move is nine `parts.json` rows, two library paths and one `fg fingerprint`. The three
plan documents are a move plus their `INDEX.md` lines.

Each line was checked for references across both repos, `fg` and the local tooling, excluding
`docs/archive/`. MEASURED unless marked.

**Orphan files in `Fizzygum/` (no reference anywhere):**

| File | Note |
|---|---|
| `open_all_sources_in_TextWrangler.sh` | 57 bytes, last commit 2017-04-12 |
| `buildSystem/OBSOLETE generateOverviewDoc.py` | named obsolete |
| `buildSystem/generate-JSON-Manifest-for-directory.js` | |
| `buildSystem/jsonToCoffeescriptVariable.js`, `buildSystem/jsonToJSVariable.js` | reference only each other |
| `auxiliary files/find-tokens-used-only-once.sh` | |
| `auxiliary files/all-color-literals-rgb-values-regexp.txt` | |
| `auxiliary files/additional-icons/xPointerImage4.psd` | 138,970-byte Photoshop source |
| `.gitmodules` | tracked, 0 bytes |

**Stale but live.** `auxiliary files/pre-compiled.js` is a real build input (the "not
pre-compiled" stub), but its header describes a flow that no longer exists (a zip download and
the deleted `--homepage` flag). `package.json` names `"main": "index.js"`, which does not exist,
and its `test` script is the `npm init` stub (see §2).

**Two vendoring homes.** `vendor/` holds acorn, the SWCanvas builds and their pins.
`auxiliary files/` holds three more third-party libraries (the CoffeeScript compiler, FileSaver,
JSZip) and the `additional-icons/` images. The directory name contains a space and is quoted at
every use (nine asset rows in `parts.json`, `lib/meta-compiler.js`, `lib/build-inputs.js`). One
home for third-party code (`vendor/`) and one for images.

**Closed plans in the wrong repo.** `Fizzygum-tests/` keeps three closed plan documents at its
root: `MIGRATION-PLAN.md` (1,274 lines, closed 2026-06-12), `REFERENCE-FILENAME-GRAMMAR-PLAN.md`
(448, closed 2026-08-22) and `SCREENSHOT-EQUALITY-PLAN.md` (157, closed 2026-06-12).
`docs/README.md`'s filing rule sends a closed plan to `Fizzygum/docs/archive/` with an
`INDEX.md` line. Check for inbound links before moving them.

**An exclusion mechanism that excludes nothing (owner decision).** `SWCanvasBrokenTests` in the
harness holds two skip lists, both empty (`testNamesDpi1: []`, `testNamesDpi2: []`). The loader
filter, the stale-name report and two runner branches exist to serve them. Delete the mechanism,
or keep it as a deliberate valve and say so in its header.

**First step.** One commit per repo for the orphan files; the vendoring move as its own commit
with an `fg fingerprint` showing only path changes.

**Re-measure.** For any file `F`:
`grep -rIl --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=archive -e "F" Fizzygum Fizzygum-tests fg`
from the umbrella directory.

**Landed 2026-11-13 (the loop's U1): the orphans, the closed plans, the stub's header.** Eight of the
nine orphans are deleted; the re-measure grep, re-run over both repos, `fg` and the umbrella's
`.claude/`, found each named only here, in its own text or its sibling's, or in an archived record.
`xPointerImage4.psd` is KEPT: a design source has no code reference by nature, so "unreferenced" is no
evidence it is dead, and whether the repo keeps design sources is the owner's call (BACKLOG). The three
closed plans moved to `docs/archive/` as `recorded-to-macro-migration-plan.md`,
`screenshot-equality-plan.md` and `reference-filename-grammar-plan.md`, byte-for-byte (their relative
links stay written from the tests repo's root; their INDEX lines say so and name the repo that holds
their history); the one living mention, in the tests repo's `CLAUDE.md`, points at the archive. The
stub `auxiliary files/pre-compiled.js` says what is true: every build copies it, a compile-at-boot tree
ships that copy, a precompiled profile replaces it with the image the pre-compile driver harvests.
Evidence: a build-tree fingerprint against the unchanged HEAD for all five profiles, made by hand
because `fg fingerprint` cannot build its baseline today (BACKLOG, under §2): `dev` and `dev-notests`
differ in `js/pre-compiled.js` alone (257 → 569 bytes, the new header), `dev-precompiled`,
`homepage` and `lean` not at all.

**Landed 2026-11-13 (the loop's U2): one home for third-party code, one for the build's own files.**
`auxiliary files/` is gone. The three third-party libraries live in `vendor/`, lower-case like
`vendor/acorn`: `vendor/coffeescript/` (the compiler and its README), `vendor/filesaver/`,
`vendor/jszip/`. What the project made and the build copies verbatim lives in a new `assets/`
(the build copies it through `parts.json`'s `assets` rows, as it does the vendored libraries): the six images, with the kept
`xPointerImage4.psd` beside the `xPointerImage.png` exported from it, in `assets/icons/`, and the
not-pre-compiled stub as `assets/pre-compiled.js`. Every file moved with `git mv`. The readers: nine
asset rows of `parts.json`, `lib/meta-compiler.js` (the compiler the build's CoffeeScript-reading tools load),
`lib/build-inputs.js` (the stub, an input the staleness record watches by name) and
`build_it_please.sh` (which spelled the old name with an escaped space); `vendor/acorn/README.md`
now says `vendor/` is read through `parts.json`'s asset rows and the tools' `require`s too.
Evidence: the hand-made build-tree fingerprint against the unchanged HEAD is byte-identical for all
five profiles (`build.py` copies an asset by its basename, so no shipped path moved). Left of §1:
`package.json`'s `main`, the empty `SWCanvasBrokenTests` lists (owner), and the `.psd` (owner).

---

## §2. Put `fg` and the guard hook under version control

**Effort.** About half a day: one file moved, a two-line shim left behind, one path derivation
changed, the `fgPresent` branch and its self-test fixtures deleted, the guard hook re-tested, and
the documents that say `fg` is in no repo corrected.

**Evidence.**
- MEASURED: `Fizzygum-all/fg` is a 929-line, 73,948-byte bash script with 32 subcommands. It is
  the only definition of the two verification tiers (`fg presuite`, `fg gauntlet` and its 20
  legs), the recapture flow, the fuzz runner and the status report. It lives in the umbrella
  directory, which is not a git repo, so it has no history, no blame and no backup. The same is
  true of `.claude/hooks/fizzygum-cmd-guard.py` (15,662 bytes), the umbrella `CLAUDE.md`, and 15
  skill directories under `.claude/skills/`.
- READ: committed code depends on this uncommitted file. `buildSystem/lib/what-runs.js` locates
  it at `path.join(path.dirname(FIZZYGUM), 'fg')`, parses the bodies of four of its functions
  (`fg_build`, `fg_suite`, `run_lint`, `run_leg`) to learn which scripts the commit-point legs
  launch, and carries an `fgPresent: false` branch for a clone that lacks it; its header says the
  readers then "treat a commit-point-only fact as undecidable, never as false".
  `buildSystem/run-selftests.js` addresses the same file as `DIR/fg` in the workspace layout it
  reads.
- MEASURED: the committed docs and tools tell their reader to run `fg <subcommand>` well over a
  hundred times (`fg recapture` 16, `fg homepage` 13, `fg diffpage` 12, `fg gauntlet` 10, …),
  naming a tool the reader's clone does not contain.
- READ: `build_and_test.sh` (32 code lines) and `build_and_smoke.sh` (36) are the committed
  predecessors of `fg test` and the smoke leg, and `package.json`'s `test` script is still the
  `npm init` stub that prints an error and exits 1.

**Why it matters.** The gates are this project's main asset, and the file that says which gates
run at a commit point can be lost with one `rm` or one dead disk, and can change without a trace.
The build's own tooling already pays for the arrangement with a three-valued answer (present,
absent, undecidable).

**Fix shape.** Move `fg` into a repo and leave a two-line `exec` shim at
`Fizzygum-all/fg`, so every absolute-path invocation and the guard hook keep working. `fg` finds
its repos from its own location (`ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`), so the
move changes that one derivation. Then delete `what-runs.js`'s `fgPresent` branch and its readers'
"undecidable" handling, fold `build_and_test.sh` and `build_and_smoke.sh` into `fg` subcommands or
make them call it, and point `npm test` at the real suite.

**Owner decision.** Where it lives. Recommended: the `Fizzygum` repo root, because the build
tooling there already reads it and every command already routes through that repo. Alternative:
make the umbrella itself a small repo that ignores the three child repos, which also versions the
hook, the skills and the umbrella `CLAUDE.md` without moving anything, at the cost of a fourth
repo. The two can be combined.

**Risk.** None to pixels. The guard hook blocks some command spellings by path; re-test it after
the move.

**First step.** `git -C Fizzygum log --oneline -1 -- buildSystem/lib/what-runs.js`, read
`what-runs.js`'s header (it documents every root), then make the move in one commit together with
the `fgPresent` deletion.

**Re-measure.** `wc -lc /Users/davidedellacasa/code/Fizzygum-all/fg` and
`grep -n "fgPresent\|layout.fg" Fizzygum/buildSystem/lib/what-runs.js Fizzygum/buildSystem/run-selftests.js`.

---

## §3. The video-player part: delete it or gate it

**Effort.** For deletion, half a day to a day: one directory and nine scripts removed, the flag
taken out of `parts.json`, `lib/profile.js`, `build.js` and `build_it_please.sh`, two core guards
removed, `SimpleImageWdgt` re-homed, and five BACKLOG items moved to a ledger. The gate option is
larger and open-ended, since five defects have to be fixed first.

**Evidence.**
- MEASURED: the `video-player` part is `src/video-player/`, 12 files and 799 lines. In
  `buildSystem/parts.json` it is the only part carrying `requiresFlag`, and
  `lib/profile.js`'s `partShips` says the mechanism "survives profiles for exactly one carrier".
  The `dev` profile selects every part (`"parts": "all"`), and the flag requirement is what keeps
  this one out of it, so no default build ships the part and no gate has ever run its classes.
- READ: it costs three build flags (`--includeVideoPlayer`, `--includeVideos`,
  `--keepPreviousPrivateVideos`), an `includeVideoPlayer` parameter threaded through four
  functions of `lib/profile.js`, two guards in core (`WorldWdgt.createDesktop`'s auto-launch and
  `WorldWdgt.draftRunVideoPlayer`), and `video-related-scripts/` (nine shell scripts, last
  committed 2025-05-16, referenced by nothing).
- READ: `docs/BACKLOG.md` holds five open defects that live entirely inside the part: a world
  holding the player cannot be saved; a boot with the part logs 304 `NON_INTEGER_GEOMETRY`
  errors; a player with no loadable video is invisible and hangs a headless page when shown; it
  throws under SWCanvas on every paint; `SimpleRasterImageButtonWdgt.imagePath` is a stale second
  copy of its face's path.
- READ: `SimpleImageWdgt`, the bitmap loader, was moved into this part because only the part used
  it, and BACKLOG notes that building a load-image flow "means first deciding where the loader
  belongs".

**Why it matters.** This is code outside every guarantee the project enforces, known to be broken
in five ways, kept reachable by a build mechanism that exists only for it.

**Owner decision.** Two coherent answers:
- **Delete** the part, the `requiresFlag` mechanism, the three flags, the two core guards and the
  nine scripts; move `SimpleImageWdgt` to where the image flow will want it. Git keeps the rest.
  The five BACKLOG items close as moot. Recommended unless the player is wanted again.
- **Gate** it: drop `requiresFlag` and the flags, so `dev` ships the part like any other and the
  suite page carries it, and fix the five defects under the normal gates. The 304 geometry
  errors alone would fail the suite on the first run, so the fixes come first.

Either answer removes the one-carrier mechanism. The related classes outside the part
(`VideoPlayIconWdgt`, `VideoPlayIconAppearance`, `VideoPlayCreatorButtonWdgt`,
`VideoPlayButtonWdgt`, `SimpleVideoLinkWdgt`) follow whichever answer is chosen.

**First step after the decision.** For deletion:
`grep -rn "Video\|video" Fizzygum/src --include='*.coffee' -l` to list every file to visit, then
one commit, then `fg gauntlet` and `fg homepage`.

**Re-measure.**
`grep -n "requiresFlag" Fizzygum/buildSystem/parts.json Fizzygum/buildSystem/lib/profile.js`.

---

## §4. Silent invariant traps report, or go

**Effort.** About a day: a counting prelude and two suite runs to learn which traps fire, fifteen
small edits, one token added to the runners' fail list with its bite proof, and the stink's
pattern widened. Longer if a trap turns out to be firing today.

**Evidence.**
- MEASURED: 36 lines in `src/` are a `debugger` statement: 32 standing alone and 4 written as
  `if <condition> then debugger`. The `debugger-statement` stink's pattern is anchored at the
  start of the line (`/^\s*debugger\b/`), so it counts 32 and does not see the other 4.
- MEASURED: 21 of the 36 are followed by a report (17 `CACHED_DERIVATION_DIVERGED` errors, which
  §7 removes, and 4 `throw`s). The other 15 are followed by nothing. Each sits in a branch that
  has just detected a broken invariant, and its only action is a breakpoint, which does nothing
  unless a developer has devtools open. The headless suite never does and neither does a user.
- The 15, by method (line numbers as of the baseline): `WorldWdgt` damage-rectangle bookkeeping
  (975, 999, 1013) and an input event without a time (2130); `TreeNode` (315); `StringWdgt`
  text fitting (806, 900); `CaretWdgt` key handling (161); `BoxyAppearance` (152) and
  `RectangularAppearance` (60), both `if !fill? then debugger` on the paint path;
  `Class._removeHelperFunctions` (257) and `Mixin._removeHelperFunctions` (71);
  `Mixin` (299); `ClippingAtRectangularBoundsMixin` (114); `HighlightableMixin` (59). (The three in
  `Mixin` and `HighlightableMixin` left with the mechanism, `archive/mixin-removal-plan.md`; the
  clipping one is `ClippingWdgt`'s now.)

**Why it matters.** A check that cannot fail a run gives false comfort. Two of these guard the
paint path, where this project has already lost time to a fill that painted nothing "with no
error anywhere" (`Fizzygum/CLAUDE.md`, the `@param` convention).

**Fix shape.** One reporter, a `console.error` with a token that the headless runners fail on, in
the same way they fail on `NON_INTEGER_GEOMETRY` (the tokens are listed in
`Fizzygum-tests/scripts/lib/gate-tokens.js`). Each of the 15 then becomes a reporting check, or
is deleted with the evidence that its condition cannot occur. With §7 done as well, the stink's
baseline goes from 32 to 0, its pattern is widened to see the `then debugger` form, and it becomes
a hard zero.

**Risk.** A trap that starts reporting may be firing today, unseen. That is the purpose, and it
sets the order of work.

**First step.** A temporary prelude that counts how often each of the 15 branches is entered over
one suite run, at dpr 1 and dpr 2. Branches never entered are converted directly; any that fire
are a finding to bring to the owner before the token is wired into the fail-gate.

**Re-measure.**
`grep -rnE '^\s*debugger\s*$|then debugger\s*$' Fizzygum/src --include='*.coffee' | grep -v ':\s*#' | wc -l`.

**Landed 2026-11-13 (the loop's U4): no trap is silent, and the stink is a hard zero.** One gate
token, `INVARIANT_VIOLATED`, joins `GATE_TOKENS` (its bite proof is the suite-gate proofs, which
plant every entry). Ten traps report under it, each saying which invariant broke: the two damage
rects an ancestor's index names, a queued input event with no time, a cropped text that should fit
and does not (its `alert` stays, being what a person sees), a text with no `measureText`, a
rectangular and a boxy appearance painting with no fill colour, a clipping widget's border re-draw
with no `paintStroke`, a keystroke with no key, and a macro looking for a widget that is not there.
Each report takes the breakpoint's place and what ran after it still runs (five of them then throw
a `TypeError`, as before); the text-fitting trap's re-call, there only to step into, goes, and so
do the macro trap's two log lines, folded into its report. One trap is deleted with its evidence:
`WorldWdgt._pushDamageRect`'s `!theRect?` can never be reached, because the method's first line,
`theRect.toString()`, throws first on an undefined rect. `Class._removeHelperFunctions`' breakpoint
goes (it already reports `HELPER_VAR_NOT_STRIPPED`), and so do the three in `MacroToolkit` that
precede a `throw`. The `debugger-statement` stink sees the statement in any spelling (`… then
debugger` among them), and its baseline is 0, a hard rule. The counting run was the gauntlet
itself, at every axis it has: no converted trap fired.

---

## §5. Lift the browser-input bridge off `WorldWdgt`

**Effort.** About two days: one new class whose roughly 160 code lines are moved, not written;
the world's construction and both teardown paths rewired; the harness's call sites; then the
lifetime gates.

**Evidence.**
- READ: seven adjacent methods of `WorldWdgt` (`_initVirtualKeyboard`,
  `_initPointerEventListeners`, `_initKeyboardEventListeners`, `_initClipboardEventListeners`,
  `_initOtherMiscEventListeners`, `initEventListeners`, `removeEventListeners`; 158 code lines)
  install and remove the DOM listeners and keep their closures in fields of the world.
- MEASURED: the family's outside surface is two calls, `initEventListeners()` and
  `removeEventListeners()`, made from the harness (`AutomatorPlayer`, `WorldTestSupport`).
- READ: `Serializer.serializeWorld`'s comment gives "a dozen event-listener CLOSURES" as one
  reason the world cannot be serialised as an ordinary record.
- READ: this is the established direction. `UntitledNamingService`, `WidgetFactory` and
  `Wallpaper` left the world in the June arc, and `world.macroToolkit`, `world.pinouts`,
  `world.parts`, `world.dataflow` and `WorldInventory` are collaborators of the same kind.

**Why it matters.** The world is at once the root widget, the cycle driver and the page's DOM
adapter. The DOM half is the one with a narrow seam and no determinism logic of its own: it
translates browser events into `InputEvent` records for the queue.

**Fix shape.** A plain collaborator class, constructed by the world, that owns the listener
closures and feeds the world's input queue. The world keeps two delegating methods, or the
harness calls the collaborator directly.

**Risk.** The listeners are page-lifetime resources, so the teardown contract in
`Fizzygum/CLAUDE.md` ("ONE world teardown, two callers, TWO obligations") applies: both
`resetWorld` and `loadWorldSnapshot` must still release them, and `fg vmtruth` will name a leaked
closure. Removing members from `WorldWdgt` can move an inspector reference if a test inspects the
world (same case law as §7).

**A second candidate, not yet examined.** `FrameWdgt`'s docking family (`dockSideAt` to
`floatOutOfDock`, 131 code lines) is UNVERIFIED as a seam. Assess it in the same spike; do not
assume it.

**First step.** List every field the seven methods write and every reader of those fields
outside them. If any reader is in the cycle or the hand, the seam is wider than it looks and the
item should be re-scoped.

**Re-measure.**
`grep -nE '^  (_init[A-Za-z]+|initEventListeners|removeEventListeners):' Fizzygum/src/WorldWdgt.coffee`.

**Landed 2026-11-13 (the loop's U7): the input bridge is `world.browserInput`.** The first step found the seam
as narrow as stated: the 20 listener closures are read nowhere outside the seven methods, and the one other
field, the on-screen keyboard's hidden `<input>`, is read by the world's `edit`, its stop-editing body, its
dissolution and two tests — none of them the cycle or the hand. The seven methods and the 21 fields moved, as
copied lines, into `BrowserInputBridge` (`src/events-input/`, beside the queue it feeds): a plain collaborator
the world builds with `new BrowserInputBridge @` where it used to call `initEventListeners`, holding a reference
to that world rather than reading the global. Inside the moved bodies only `@x` → `@world.x` changed (26 sites),
`_initVirtualKeyboard` became `initVirtualKeyboard`, because its one caller is now outside its class, and the
comment over `removeEventListeners` was corrected (it said its only caller was the harness; the world's
dissolution calls it too). The harness calls `world.browserInput.initEventListeners()` / `removeEventListeners()`
directly; the world keeps no delegating pair. Of the two teardown paths only the dissolution releases the
listeners — `loadWorldSnapshot` keeps its world and its listeners, as it always did (the Risk paragraph above
says otherwise). Evidence: a script proved the moved lines equal HEAD's once those rewrites are undone, and the
world equal HEAD's minus them; the resolution map shows 28 members leaving `WorldWdgt` (7 methods, 21 fields)
for the bridge and, besides, only six re-pointed functions changing (the map lists no constructors, so the
world's constructor change shows in the diff alone); a listener census by CDP (`DOMDebugger.getEventListeners`
on `window`, `document`, `document.body` and the canvas, on `index.html` and the harness page, at boot, after
`resetWorld`, after `loadWorldSnapshot` and around the harness's own pair) is byte-identical before and after
— it reads each listener's type and options, not which closure it is, and the object-lifetime gate (`fg
vmtruth`) is what sees a retained one; no reference moved on any gauntlet leg. The docking family (`FrameWdgt`,
the second candidate) was not examined here.

---

## §6. One plane-mapping protocol for the ancestor walk

**Effort.** About three days: a day's spike to settle the protocol's shape, a day to convert the
eight methods and the two implementers, and up to a day of A/A performance measurement and dpr-2
verification.

**Evidence.**
- READ: `Widget.coffee` contains eight hand-written loops that climb `@parent` and ask each
  ancestor how it maps its child's plane: `mapRectToScreen`, `screenPointToMyPlane`,
  `localPointToScreen`, `_enclosingNonIdentityIsland`, `_enclosingMappedPlaneRoot`,
  `screenBounds`, `accumulatedRotationDegrees` and `accumulatedScaleFactor`.
- READ: each loop asks the question in two different ways. For a transform island it tests the
  type and reaches into a field: `ancestor instanceof TransformFrameWdgt and
  !ancestor.transformSpec.isIdentity()` (eight occurrences). For a scrolled plane, five of the
  same loops ask a capability: `ancestor.scrollTranslationOfChild?(previous)` (one implementer,
  `ViewportWdgt.scrollTranslationOfChild`).
- MEASURED: 10 of `Widget.coffee`'s 13 `instanceof` tests name `TransformFrameWdgt`. The base
  class names one of its own subclasses, and those ten are all the `instanceof TransformFrameWdgt`
  tests in `src/`. The `instanceof-type-test` stink stands at 74.

**Why it matters.** "How does this ancestor map its child?" is one question with two kinds of
answer (an affine map, a translation). The scroll half already has the right shape: the ancestor
answers for itself and the walker does not care what class it is. The island half predates that
shape. A third kind of plane would today mean editing eight loops.

**Fix shape.** One protocol that both ancestors answer, for example
`planeMappingOfChild?(child)`, returning nothing for an ancestor that maps nothing (an identity
island included). One upward iterator in `Widget` yields `(mapping, ancestor)` pairs, innermost
first. The eight methods become short folds over it. The ten type tests and the `transformSpec`
reach-ins disappear from the base class, and `TransformFrameWdgt` and `ViewportWdgt` each state
their own mapping.

**What stays different, on purpose.** READ: the loops are not identical. `screenBounds` maps
exactly (`TransformSpec.mapRectExact`, raw float corners) where `mapRectToScreen` uses
`mapRect`, which floors, ceils and pads by one pixel, and also deposits buffer damage on each
island and tracks the outermost island clip. `TransformSpec`'s own comment keeps those two
mapping bodies parallel so that the damage path "stays byte-untouched"; this item does not merge
them. So the target is one iterator and eight small bodies, not one function.

**Risk.** These are hot: `screenPointToMyPlane` runs per pointer event and `mapRectToScreen` per
damage rectangle. The mapping an ancestor returns must not allocate per call; returning the
island's own `transformSpec` and the viewport's existing translation `Point`, with the ancestor
supplying the pivot, avoids it (UNVERIFIED: the two answers have different call shapes today,
`spec.mapPoint(p, ancestor.bounds)` against `p.add(translation)`, and the spike must find one
shape that costs nothing). Measure before and after with an A/A run first, since run-to-run noise
on this machine is not small.

**First step.** A spike on `localPointToScreen` and `screenBounds` only, behind the existing
methods, with a temporary check that old and new agree on every call across one suite run.

**Verification.** `fg presuite` (its `fracplane` rider is the inner loop's only dpr-2 view of
rotated containers), then `fg gauntlet`. Expect zero reference changes.

**Not owned elsewhere.** `plans/affine-transforms-plan.md`'s open items (§7.1 to §7.4) are
features; none restructures the walk.

**Re-measure.**
`grep -n "instanceof TransformFrameWdgt" Fizzygum/src/basic-widgets/Widget.coffee | wc -l` and
`grep -rn "scrollTranslationOfChild" Fizzygum/src --include='*.coffee' | grep -v ":\s*#"`.

**Landed 2026-11-13 (the loop's U8, built and parked on a speed trade, landed on the owner's ruling).** The
existing `_enclosingMappedPlaneRoot` is the one upward iterator. Every ancestor that maps a plane answers
`mapsPlaneOfChild(child)` and maps through its own verbs (`mapPointFromChildPlane`,
`mapPointIntoChildPlane`, `mapDamageRectFromChildPlane`, `mapClipFromChildPlane`,
`mapRectExactFromChildPlane`, `rotationDegreesOfChildPlane`, `scaleOfChildPlane`), on `TransformFrameWdgt` and
`ViewportWdgt`. The eight walks are short folds over the iterator: `screenPointToMyPlane` recurses for its
outermost-first order, and the accumulators iterate islands innermost first. All ten `instanceof
TransformFrameWdgt` leave `Widget`. The two outside the walks go through a `TransformFrameWdgt` override of
`_reExpressFigureForPlaneOfNoSettle` and through the existing `_materializedBySugar?` test. The `instanceof` stink
falls from 74 to 64. The protocol's present-tense description is in `architecture/transforms.md` and
`architecture/viewports-and-planes.md`.

- **Exact.** An instrument ran the OLD compiled walks beside the new ones on every call of the eight walks and of
  `scrollTranslationOfChild`, comparing every number with `Object.is`. On the tree that landed it covered
  218,331,467 calls over the whole suite at dpr 1 and 2, as mouse and as finger, with zero disagreements and every
  test passing. A planted error was reported, per test.
- **Speed.** Measured on the real methods, HEAD's build against the change's, three alternating runs each; ns per
  call:

  | Case | Change |
  |---|---|
  | No mapping ancestor (the common case) | 13–50 % faster |
  | A scrolled pane | 22–47 % faster |
  | A scrolled pane inside a rotated island | up to 37 % faster (two methods the same) |
  | Content of islands nested directly (no viewport between): the value walks | 3–14 % slower: `screenPointToMyPlane` 221 → 229, `mapRectToScreen` 268 → 288, `screenBounds` 185 → 196 |
  | The same content: the two root queries | ×1.4–1.5 (12.5 → 17.5–19) |

  The slower cases pay for one more call layer per mapping ancestor: the capability, the verb, the iterator's
  restart. One attempt removed another slowdown: an island walk was stepping through a viewport's scroll test. The
  two alternatives were declined:
  - keeping the eight loops and the ten type tests;
  - an island fast path in the iterator, which would put the type test back.

  One allocation trade goes the other way, and it was declared before the build. `mapRectToScreen` for an island
  inside a scrolled pane builds two translation `Point`s per viewport crossed, where one was built before; every
  other state allocates the same or less. `Widget` no longer type-tests for `TransformFrameWdgt`, and a third kind
  of plane is a class answering the protocol, not eight loops. What the protocol does not reach is the island
  machinery that re-specs or picks out a figure (`_reExpressFigureForPlaneOfNoSettle`'s bare-payload branch,
  `_resolvePickOutFigureNoSettle`). It still reads an island's own `transformSpec` and constructs
  `TrackingTransformFrameWdgt`: twelve reach-ins outside the walks, which this item never meant to move.
- **Gates.** The presuite and an independent review. The review found no behaviour difference; its findings were
  comments and test texts made stale, and all of them are fixed. Then the gauntlet (20 of 20), a presuite on the
  comment-fixed tree, and `fg homepage`.

---

## §7. Derived-geometry caches: one oracle, then one memo

**Effort.** Step 1 is about half a day and stands alone. Step 2 is about three days and may be
abandoned on its measurements: it needs a class-level declaration form that the meta-system
understands, and an A/A performance comparison.

**Evidence.**
- READ: eight derived queries are memoised by hand against a global version counter: `root` and
  `firstParentClippingAtBounds` in `TreeNode`; `visibleBasedOnIsVisibleProperty`, `fullBounds`,
  `fullClippedBounds`, `clippedThroughBounds`, `clipThrough` and `isInCollapsedSubtree` in
  `Widget`. Each keeps a `check<Name>Cache` stamp and a `cached<Name>` value and compares the
  stamp with `WorldWdgt.geometryVersion`, `structureVersion` or `visibilityVersion`.
- MEASURED: each has an uncached twin for verification. There are 16 `SLOW<name>` definitions,
  because `WorldWdgt`, `ActivePointerWdgt`, `TransformFrameWdgt` and
  `ClippingWdgt` override the fast query and must override its twin with
  it (`TransformFrameWdgt`'s comment: the twins "are overridden IN LOCKSTEP").
- MEASURED: the comparison is written out 17 times, as
  `if world.doubleCheckCachedMethodsResults` / compare / `debugger` /
  `console.error "CACHED_DERIVATION_DIVERGED -- <name> is broken"`, some queries carrying it on
  both the cached and the uncached path. Those are 17 of the 32 lines the `debugger-statement`
  stink counts.
- READ: the oracle is live, not vestigial. The gauntlet's `settle` leg arms the flag on the
  world's prototype (`notification-settle-prelude.js`), and the runners fail on the token.

**Why it matters.** The pattern is correct and worth keeping. Its expression is not: every query
interleaves three concerns (compute, cache, verify), a new query means copying about twenty lines,
and an override that forgets its twin weakens the oracle without any signal.

**Fix shape, two steps.**
1. **One oracle.** A single private method, for example `_reportIfCachedDiverges name, result,
   slow`, holds the flag test, the comparison (`equals` for rectangles, identity otherwise) and
   the `console.error`. The token text does not change, so the gate does not change. Seventeen
   blocks and seventeen `debugger` lines go. No hot-path cost: the flag test already exists at
   every site.
2. **One memo.** Declare each derived query once: its name, the version counter it depends on,
   its compute body, its slow twin. Generate the accessor at class-definition time so the fast
   path stays a monomorphic field compare with no closure per call. An overriding class then
   overrides a declaration, and the twin cannot be forgotten.

**Risk.** Step 1 adds a member to `Widget`. The inspector's member lists are screenshotted, and a
member added to or removed from a core prototype has moved inspector references before
(`docs/archive/god-class-decomposition-plan.md`, guardrail 1); budget for a benign inspector
recapture and confirm it is only that. Step 2 touches the hottest reads in the paint loop and has
to pass the meta-system, which compiles class members from source text member by member
(`src/meta/Class.coffee`): a class-level declaration helper must be something that pipeline and
the inspector's source view both handle. If step 2 measures slower, stop after step 1.

**First step.** Step 1 on `fullBounds` alone, then the whole family in one commit.

**Verification.** The settle leg's own bite proof (`cache-oracle-selftest-headless.js`, run by the
gauntlet's `selftests` leg) must still see a planted divergence. Then `fg gauntlet`.

**Re-measure.**
`grep -rn "doubleCheckCachedMethodsResults" Fizzygum/src --include='*.coffee' | grep -v ":\s*#" | wc -l`
(17 branches plus the field's declaration) and
`grep -rnE "^\s+SLOW[A-Za-z]+:" Fizzygum/src --include='*.coffee' | wc -l`.

**Landed 2026-11-13 (the loop's U3): step 1, one oracle.** `TreeNode._reportIfCachedDiverges
queryName, answer, slowAnswer, path` holds the comparison and the report: an answer with `equals` (a
Rectangle) is compared by it, any other (a node, a boolean) by identity, and a disagreement prints
`CACHED_DERIVATION_DIVERGED -- <queryName> is broken` plus ` (<path>)` where the query names its
paths ("cached", "uncached", or the island's "island"). The seventeen sites keep their
`if world.doubleCheckCachedMethodsResults` test and call it inside, so a disarmed read pays exactly
what it did (one field test, no call, no twin); their `debugger` lines are gone, and the
`debugger-statement` stink falls from 28 to 11. Evidence: an old-versus-new probe that, for each of
the twelve query bodies, arms the oracle, plants that body's SLOW twin to answer wrong, and records
every message of an uncached and then a cached call — the two builds print byte-identical
sequences, all seventeen messages on their own paths, and an honest twin prints nothing; the
resolution map changes those twelve bodies and adds the oracle, nothing else; the cache-oracle
self-test still sees its planted divergence. One inspector test moved: the oracle is one more
member in an object inspector's list, which scrolls the selected row's window by one row
(`macroDuplicatedInspectorDrivesCopiedTargetOnly`, recaptured mouse and finger at dpr 1 and 2).
Step 2 stays the owner's: it adds a class-level declaration that generates accessors.

---

## §8. Ratchets for method count and complexity; split the sequential giants

**Effort.** The ratchets are about a day and stand alone: a new gate needs its rule registry
entry and its bite proof, and `coffee-cc` is an npm devDependency today (`fg cc` asks for an
`npm install` when it is missing), so the complexity half either makes it a build requirement or
vendors it. The splits are two to three days more, one function at a time.

**Evidence.**
- MEASURED, method counts (a line matching a two-space-indented `name: … ->` definition) against
  the June god-class arc's base `4c684991`:

  | Class | Methods then | Methods now | Code lines now |
  |---|---|---|---|
  | `Widget` | 310 | 382 | 2,497 |
  | `WorldWdgt` | 109 | 128 | 1,584 |
  | `ActivePointerWdgt` | 30 | 65 | 730 |
  | `FrameWdgt` | (class did not exist) | 173 | 1,044 |

- MEASURED, cognitive complexity (`coffee-cc`, the tool behind `fg cc`): 4,446 functions, total
  9,709. The top of the list: `WorldInventory#takeInventory` 130,
  `Serializer#_buildObjectTable` 106, `ViewportWdgt#takeStrokeScrollFrom` 93,
  `ActivePointerWdgt#processPointerUp` 80, `Deserializer#_worldSectionProblem` 76,
  `Class#constructor` 70, `WorldWdgt#loadWorldSnapshot` 67, `Deserializer#deserialize` 61,
  `Deserializer#_envelopeShapeProblem` 59,
  `StringWdgt#searchLongestFittingTextByMultiCroppingIt` 55. (Two mixin bodies also scored above
  70 at the survey, because the tool counted a whole mixin body as one function;
  `archive/mixin-removal-plan.md` re-homed their members as class methods.)
- READ: nothing holds either number. `docs/BACKLOG.md` carries the unbuilt item "per-file metrics
  ratchet for god-class line counts" (`archive/lint-generic-rules-carryover-plan.md` §8.5 C).

**Why it matters.** The June arc lifted what it could and judged the determinism core best left
alone. Since then the three classes that existed took on 126 methods between them, and
`FrameWdgt` arrived at 173, with no signal either way. Without a ratchet every future
decomposition is a one-off.

**Fix shape.**
1. **Two ratchets, in the `check-stinks.js` style** (a recorded value that may fall and may not
   rise): a method-count ceiling for the four classes, and a per-function complexity ceiling
   where the functions already above it are recorded at today's value. Count methods, not lines:
   a line ratchet would punish the comments this project asks for. This closes the BACKLOG item
   in a better form.
2. **Split the sequential giants.** UNVERIFIED, since these bodies were not read for this survey:
   `takeInventory`, `_buildObjectTable`, `loadWorldSnapshot`, `deserialize` and the two
   `Deserializer` validators look like phase-after-phase code, which splits into named phases
   without changing behaviour. Test that per function before promising it.

**Do not include.** `processPointerUp` and `takeStrokeScrollFrom` are input-recognition state
machines in the determinism core. The June arc's Tier 4 verdict (LEAVE, no determinism-safe seam)
covers them, and this survey found no new argument.

**First step.** The ratchets, since they are small and stop the drift whatever else happens.

**Re-measure.** `Fizzygum/node_modules/.bin/coffee-cc src` run from `Fizzygum/` (read-only), and
`grep -cE '^  [A-Za-z_$][A-Za-z0-9_$]*: *(\([^)]*\))? *[-=]>' Fizzygum/src/basic-widgets/Widget.coffee`.

**Landed 2026-11-13 (the loop's U9): step 1, the ratchets.** `buildSystem/check-complexity-ratchets.js`, the
build's last gate row, a gate of its own (a stink counts one pattern over every file against one number; these
hold a number per class and per function), in the stinks' style: a recorded value that may fall and may not rise,
printing UNDER when it can be lowered. METHOD COUNT, by the ONE definition of a method header
(`lib/coffee-method-header.js`, instance and class side — not this section's re-measure regex, which misses
class-side methods, wrapped signatures and a parameter default holding a call, and which the lint index forbids
re-declaring): `Widget` 391, `WorldWdgt` 127, `ActivePointerWdgt` 74, `FrameWdgt` 173. COGNITIVE COMPLEXITY, one
ceiling, 15 (the published default of S3776): the 4,589 functions of src and the harness are scored, and the 106 above
15 are recorded at their values, keyed `Class#method`, `Class.method` on the class side, `<file>#name` outside any
class (the top three `WorldInventory#takeInventory` 130, `Serializer._buildObjectTable` 106,
`ViewportWdgt#takeStrokeScrollFrom` 93); a new one above 15, or a recorded one rising, fails; an entry excusing
nothing (a class file gone, a function at 15 or below, or gone) is stale and fails; the harness's six records are
judged only when the harness is read. The analyzer, the owner's npm package `coffeescript-cognitive-complexity`
1.0.0, is vendored as acorn is (`vendor/coffeescript-cognitive-complexity/`: its `index.js` verbatim, its `LICENSE`,
a README). It walks the AST by node class name, which the build's minified compiler mangles, so
`buildSystem/lib/cognitive-complexity.js` loads it only on the CoffeeScript the records were measured on — 2.7.0,
the global install the build already requires, found behind a `coffee` on PATH or in Node's global prefix, another
version or a wrapper passed over, none found an INVALID run — with nothing from `node_modules`; its scores equal the
published run's, function for function, over all 580 sources. Its bite proof plants every rule, harness included
(19 cases). `fg critique` does not show it yet: `fg` is the owner's local tooling, outside the loop's reach
(BACKLOG has the one step to add).

**Landed 2026-11-13 (the loop's U10): step 2, the sequential giants — three split, three left.** Each candidate
was read first. Split, its statements MOVED (by a script copying lines, every original line accounted for) into
class-side helpers in their order — a pass filling the restore's shared tables, a check returning its clause or
`undefined`: `Deserializer.deserialize` (61 → 15: the
envelope's vetting and four passes, `_vettedEnvelope` / `_instantiatePass` / `_populatePass` / `_registerPass` /
`_fixupPass`, at most four of the restore's own tables crossing a boundary; the reference reader stays, since
`deserialize` returns it), `Deserializer._envelopeShapeProblem` (59 → 14: the per-record loop stays, so a file still
reports its first defect, and its body becomes `_tableEntryProblem` with `_membershipsProblem`; the second-identity,
well-known-key and id-count checks each their own `…Problem`, the three one-line checks inline) and
`Deserializer._worldSectionProblem` (82 → 10: one `_section…Problem` per field block — nine, the four single-widget
references and the three scalars one block each — the reference closure a method).
Their three records left the ratchet. No message changed: the file's string literals are the same multiset before
and after. Left, with what binds each: `WorldInventory#takeInventory` (its walk is six locals shared through six
closures; only two small tail phases could move), `Serializer._buildObjectTable` (eight closures over six shared values,
its mutually recursive reference and slot encoders among them, two of them handed back to its callers — nothing in
it runs in sequence) and `WorldWdgt#loadWorldSnapshot` (its class sits at its
method ceiling, and its locals cross a try/catch/finally).

---

## §9. Icon shells: one `IconWdgt` and a derived icon catalog

**Effort.** Four to five days: about 70 files deleted, 139 construction sites and 17 test files
edited, the menu and its creators derived from one list, the colloquial-name derivation moved,
and very likely a reference review with the owner.

**Evidence.**
- MEASURED: 72 classes extend `IconWdgt`. Fifty of them are exactly two code lines: the class
  line and `createAppearance: -> new <X>IconAppearance @`. Sixty-nine are six code lines or
  fewer; the extra lines are a stated `colloquialName` or a tooltip. The drawing lives in the
  106 `*IconAppearance` files, which this item does not touch.
- MEASURED: `src/demos/DemoMenus.coffee` carries 58 methods of the form
  `create<X>IconWdgt: -> world.create new <X>IconWdgt` and 55 hand-written menu rows that name
  them by string.
- So one icon is stated four times in three files: the appearance, the shell class, the creator
  method, the menu row.
- READ: `docs/archive/oo-smells-refactoring-backlog.md` Phase 2 (2026-06-17) thinned the shells
  to today's form and explicitly deferred "the aggressive form", collapsing the classes to a
  registry, as "only worth it if a future need (e.g. data-driven icon menus) appears. Flag for an
  owner decision." The hand-written menu and its 58 creators are that need, present in the tree.

**Why it matters.** The shells are 12% of the files in `src/` and carry no behaviour. A shell
class has to be compiled at boot on a compile-at-boot page, ordered by the dependency scanner,
assigned to a part, and kept in step with the menu by hand.

**Fix shape.** `IconWdgt` takes its appearance as its identity argument and the shells are
deleted. The icon menu and its creators are generated from one ordered list of appearance
classes. Two spellings are possible and the spike chooses:
- `new IconWdgt new HeartIconAppearance`: keeps the `new X` spelling that the boot dependency
  scanner reads (`src/boot/dependencies-finding.coffee`), but appearances are constructed with
  their widget today (`new FooAppearance @`), so the widget would be bound after construction.
- `new IconWdgt HeartIconAppearance`: reads better, but a bare class name passed as an argument
  may be invisible to the dependency scanner and to `check-part-edges.js` (UNVERIFIED for the
  gate; check both before choosing).

**Costs, stated plainly.** MEASURED: 139 `new <X>IconWdgt` sites in `src/` and 17 test files that
name an icon widget class (`HeartIconWdgt` 40 times, `GenericObjectIconWdgt` 13,
`GenericShortcutIconWdgt` 9). A saved snapshot that names a deleted shell class stops loading.
The colloquial name is derived from the class name today and is DRAWN in hierarchy menus, so it
must be derived from the appearance class to the same string or those references move; the menu's
row order must be kept by the list, not by enumeration.

**Owner decision.** Whether class identity per icon is worth keeping for its own sake (an icon
inspected in the running world shows `HeartIconWdgt` today and would show `IconWdgt` with a
`HeartIconAppearance`).

**Coordination.** `plans/pixel-icons-plan.md` P3 converts appearance files and leaves "Wdgt files
untouched". The two compose; if both run, do this one first so P3 has fewer files to reason about.
The creator-button shells (16 `CreatorButtonWdgt` subclasses and their kin) look alike but are
owned by `plans/creation-and-templates-plan.md` §4.3 and are not part of this item.

**First step.** Convert the eight `Arrow*IconWdgt` shells only (three code lines each, a stated
colloquial name, about 25 construction sites between them) and take one `fg presuite`.

**Re-measure.**
`grep -rlE '^class [A-Za-z0-9_]+ extends IconWdgt' Fizzygum/src | wc -l` and
`grep -cE '^  create[A-Za-z0-9]+IconWdgt: ' Fizzygum/src/demos/DemoMenus.coffee`.

---

## §10. Build logic in one language; the gate sequence as data

**Effort.** Five to six days, in two parts that land separately. About three for the port: 614
code lines of Python, seven gates and three shell scripts re-pointed, and a fingerprint per
profile. About three for the gate table: the runner, `what-runs.js`, the bite-proof runner, and
re-homing the per-gate comments.

**Evidence.**
- MEASURED: the build is written in three languages. `build_it_please.sh` is 1,302 lines of bash
  (598 code, 598 comment). `buildSystem/build.py` and `buildSystem/buildProfile.py` are 1,067
  lines of Python (614 code). Everything else under `buildSystem/` is Node: 118 scripts and
  libraries, self-tests included.
- MEASURED: seven Node scripts start a Python process to ask the partition a question:
  `check-coffee-syntax.js`, `check-part-edges.js`, `check-shippable-coverage.js`,
  `what-pins-core.js`, `pinned-by-lazy-parts.js`, `hypothetical-part.js` and
  `lib/boot-pieces.js` each call `execFileSync('python3', ['-B', 'buildSystem/build.py',
  '--list-shippable' | '--list-boot', …])`. Four shell sites start Python too
  (`build_it_please.sh` twice, `build_and_test.sh`, `build_and_smoke.sh`), and three of them
  `eval` its output as shell assignments.
- READ: one definition is stated twice across the language boundary. `check-coffee-syntax.js`
  defines `IS_CLASS` with the comment "same test build.py uses", and
  `lib/call-sites.js` repeats `IS_CLASS` with "the tests build.py and check-coffee-syntax.js use".
- READ: the bridge has already cost real defects. The script's own comments record that
  `build.py`'s exit code went unchecked "for years", that `eval "$(cmd)"` had to be rewritten as
  substitute-then-eval so a failed profile read could not build "a nameless flavour", and that
  `PYTHONDONTWRITEBYTECODE` is exported because "the build reaches python3 by four paths".
  MEASURED: `buildSystem/__pycache__/buildProfile.cpython-311.pyc` is on disk today regardless
  (git-ignored).
- MEASURED: the gate sequence is bash boilerplate. `build_it_please.sh` contains 36
  `if [ "$?" != "0" ]` blocks, 39 `tput bel` lines and 27 `if ! $noSyntaxCheck` guards: one copy
  of the same block per gate. `buildSystem/lib/what-runs.js` (343 lines) contains a shell lexer
  whose job is to recover from that text which scripts the build launches.

**Why it matters.** The partition (`parts.json`) and the profiles are data. Reading them is
simple. Today the answer crosses a process boundary and a language boundary at eleven sites, a
regex is kept in step by comment, and the list of gates, which is the thing the bite-proof
machinery most needs to know, has to be reverse-engineered from a shell script.

**Fix shape, two steps that land separately.**
1. **Port the two Python files to Node** as `buildSystem/lib/profile.js` (the reader and the
   derivations) and `buildSystem/build.js` (source wrapping, entry pages, assets). The seven
   gates `require` the reader instead of spawning it; the shell scripts call
   `node buildSystem/lib/profile.js --shell`. Delete both `.py` files, the `__pycache__` ignore
   line, the bytecode export, and `python3` from the prerequisites. One `IS_CLASS`.
2. **State the gate sequence as a table** (`buildSystem/gates.json` or a `.js` module): one row
   per gate with its script, its arguments, its condition (always, unless `--noSyntaxCheck`,
   profile ships the tests, tests repo present) and its banner. One runner executes the rows in
   order and stops at the first failure with today's messages. `build_it_please.sh` keeps the
   steps that really are shell (concatenate, `coffee`, `terser`, copy) and calls the runner once.
   `what-runs.js` reads the table instead of lexing bash for the build's gates.

**Why this will work when the bridge has been patched repeatedly.** Earlier fixes hardened the
bridge (exit-code checks, the eval ordering, the bytecode export). This removes it, and the
project has the instrument that makes a port safe: `fg fingerprint` builds a profile at a baseline
ref and from the working tree and diffs the two build trees.

**Risk.** The per-gate comments in `build_it_please.sh` are documentation the project values.
They move into the table rows (a `why` field) or stay where
`docs/architecture/lint-and-static-checks.md` already holds the complete index; they must not be
dropped. The bite-proof runner (`run-selftests.js`) finds gates through `what-runs.js`, so step 2
changes both in one commit.

**Verification.** `fg fingerprint` clean for all five profiles after step 1; `fg build` (which
runs every gate's bite proof) and `fg gauntlet` after each step.

**Re-measure.**
`grep -rn "execFileSync('python3'" Fizzygum/buildSystem --include='*.js' | grep -v selftest` and
`grep -c 'if \[ "\$?" != "0" \]' Fizzygum/build_it_please.sh`.

**Landed 2026-11-13 (the loop's U5): step 1, the build's Python is Node.** `buildSystem/build.js`
(source wrapping, the parts manifest, entry pages, assets and vendor payloads, and the two listings)
and `buildSystem/lib/profile.js` (the profile reader and every derivation, with its `--shell`
command line) replace `build.py` and `buildProfile.py`, which are deleted with the bytecode export
and the `__pycache__` ignore line; `python3` leaves the build's prerequisites. The seven Node tools
that started Python now `require` the listing in-process (`listShippable` / `listBoot`, a refusal
thrown with its text), the three shell scripts call `node`, and `IS_CLASS` is defined once, in
`build.js`. The port keeps the Python's semantics exactly, so it carries a layer (about 650 lines) that
reproduces them — argparse's parsing and usage text, Python's `repr` and `json.dumps`, its `glob`
order, JSON numbers that remember whether they were integers, truthiness on malformed input. That
layer exists only to keep every refusal's words identical, and could go once that no longer binds
(BACKLOG). Evidence: the 65 answers a caller can ask for (`--list-shippable`, `--list-boot` and
`--shell` for five profiles under four flag sets, plus the defaults and the rails) are byte-identical
to the Python's; a corpus of 151 planted inputs gives every refusal the same exit code and, but for
ruled cases, the same text (the program name in argparse's text and in the missing-placeholder
refusal, and two messages that named a deleted file and now name the real one; five JSON/UTF-8 cases keep the build's words with Node's parser
diagnostic after them; Python's tracebacks are crashes, kept as non-zero exits); build-tree
fingerprints against the Python build are byte-identical for all five profiles and for
`--includeVideoPlayer` and `--noSyntaxCheck` builds, and every full build transcript is equal but
for timings. A second step changed the shipped files that named the Python in a comment (the page
source, three boot files, two class sources, one harness file, and one boot error message); its
fingerprints differ from the first step's in exactly those files.

**Landed 2026-11-13 (the loop's U6): step 2, the gate sequence is a table.** `buildSystem/gates.js` holds one row
per static gate, in the order the build runs them — the script, its arguments, WHEN it runs (`checked`, unless
`--noSyntaxCheck`; `testsShipped`, and the profile ships the tests and the tests repo is present; `testsRepo`, and
the tests repo is present), the line printed before it, its failure line and its OK line — with the comment that sat
beside its shell block above each row, every line of it verbatim. `buildSystem/run-gates.js` runs the rows and stops at
the first failure with that row's failure line, the bell and exit 1; a row naming a WHEN it does not know stops it
before any row runs, `--noSyntaxCheck` included (exit 2). `build_it_please.sh` calls it once, where the 27 blocks that
held the 33 gates stood (36 `$?` checks became 4). `lib/what-runs.js` reads the table once it sees the build launch
the runner: each row is a launch by the command line the runner gives it, so a convention keyed to the invoking
command still applies. Reached only through a JavaScript edge, `run-selftests.js` loses its discovery of the node-tier
self-tests: measured with the reading planted off, every one drops out of the run set and `check-hand-lists` refuses
the two sanctions that rest on one (row 7 fails). A row is resolved by its tail, like every other edge; a row whose
script lives in the tests repo, in a layout without that repo, launches nothing (as the runner passes it over), and
any other row naming a script it does not scan is an error. Evidence: the table was GENERATED from the blocks it replaced, and a script proves it equal to them (order,
script, arguments, condition, banner, failure, OK) and every one of their 265 comment lines present; what-runs' answer
equals its answer on the unchanged tree plus the runner, the table and the runner's self-test; `run-gates-selftest.js`,
the new `what-runs-selftest.js` cases and a census case in `run-selftests-selftest.js` (a gate reached only as a row),
each seen failing with what it guards planted away; build-tree fingerprints for the five profiles and `dev
--noSyntaxCheck`, taken on the final tree, equal to the shell's, and their transcripts equal but for timings, the
lines that count the self-tests and the tooling's files (which the unit's own new files change) and the baseline
worktree's own vendor fetch and paths — the aim census running on every profile and the four gates over the tests
only where the tests ship, on both sides, and no gate under `--noSyntaxCheck`. Planted builds, on HEAD and on the change:
trailing whitespace in a source, and a macro calling a method nobody declares, stop both at row 1 (each gate's
self-test runs it on a copy of the planted input); an orphan reference image runs rows 1–30 in both and stops both at
row 31, check-refs, with the same lines, bell and exit. No planted build reaches the `testsRepo` row (the last, and
every input it reads is read earlier or copied by its own self-test); its condition is proven by the runner's
self-test and by every clean transcript.

---

## 11. Measured and deliberately not listed

- **Comment volume.** 31,425 comment lines against 38,332 code lines; in `Widget.coffee`,
  `WorldWdgt.coffee` and `FrameWdgt.coffee` comments outnumber code. The project treats comments
  as a deliverable and audits them with its own rubric, so this is a choice, not debt. It is
  recorded here because it explains why line counts are the wrong instrument (§0, §8).
- **The settle-tier method families.** Each geometry verb in `Widget` exists in up to six
  spellings (`setExtent`, `_setExtentNoSettle`, `_setExtentDeferredSettle`, `_applyExtent`,
  `_applyExtentBase`, `__commitExtent`). This is the layering convention of
  `docs/architecture/layout.md`, held by the layering and tier-naming gates. Not a cleanup.
- **The flat top level of `src/`.** 101 class files sit directly in `src/` (layout specs,
  appearances, prompts, the frame, the world). Grouping them into subsystem directories is cheap
  for the build, since parts own directories, but every path reference in the docs changes for a
  navigation benefit only. Worth doing opportunistically when a subsystem is being reworked.
- **`serialization-roundtrip-headless.js`.** 5,023 lines in one file, about 25 in-page check
  functions, already selectable by `--sections=`. Splitting it by section is mechanical and
  would help its readers, but nothing depends on it.
- **The rest of the `instanceof` ratchet.** After §6 it stands at 64. Twenty of those test
  for `Widget` itself and eleven for `Point`, which are mostly value checks, not layering
  problems. The existing ratchet is the right tool.
- **Orphan classes.** A scan for classes that no other file's code names found one,
  `LCLProgramRunner`, which `buildSystem/dead-method-allowlist.txt` already records as awaiting
  the LiveCodeLang decision.

## 12. Already owned elsewhere (not listed again)

| Topic | Owner |
|---|---|
| Removing the eight mixins and then the mixin mechanism (including the duplicated members of `Class.coffee` and `Mixin.coffee`) | `archive/mixin-removal-plan.md` |
| The creator-button and toolbar-button record classes ("the creator zoo") | `plans/creation-and-templates-plan.md` §4.3 |
| Two icon-appearance generations (legacy fixed design space, size-aware) and pixel icons | `plans/pixel-icons-plan.md` |
| LiveCodeLang and the unreferenced `LCLProgramRunner` | `plans/livecodelang-cleanup-and-extensions-plan.md` |
| Context-menu construction inside `Widget` | BACKLOG one-liner, `archive/god-class-decomposition-plan.md` Tier 3 / C21 |
| Eager parts that could be lazy | BACKLOG one-liner, `archive/build-arc-4-dynamic-parts-plan.md` §5.4 (declined by the owner) |

## 13. Case law that bounds these items (do not re-attempt blind)

- **The determinism core of `Widget`, `WorldWdgt` and the hand was assessed and left.**
  `docs/archive/god-class-decomposition-plan.md`, Tier 4: no determinism-safe seam. §5 and §8
  stay outside it on purpose.
- **Removing or adding a member on a core prototype is not automatically pixel-free.** The same
  plan's guardrail 1 corrected the assumption that pure moves need no recapture: inspector member
  lists are screenshotted. §5 and §7 budget for it.
- **The icon shells were kept on purpose once.** `docs/archive/oo-smells-refactoring-backlog.md`
  Phase 2 chose the keep-the-classes form and named the condition for revisiting it. §9 argues
  the condition is met; it does not claim the earlier choice was wrong.
- **Text-level exclusion markers are retired and gated at zero** (`Fizzygum/CLAUDE.md`, "How a
  build flavour excludes code"). Whatever §3 chooses, it must not introduce a marker or a new
  flag.
- **A class rename or removal can move drawn labels.** Menu and hierarchy labels are derived from
  class names (`Fizzygum/CLAUDE.md`, the `Wdgt` suffix note). §9 depends on this.
- **A "pixel-neutral" expectation is a hypothesis until measured.** Every item above that expects
  zero reference changes says how to confirm it.

## 14. Shared verification protocol

Invoke the wrapper by absolute path; never pipe a gating call through a filter.

```
/Users/davidedellacasa/code/Fizzygum-all/fg status      # orient: heads, dirty counts, build freshness, verdicts
/Users/davidedellacasa/code/Fizzygum-all/fg build       # every static gate and every gate's bite proof
/Users/davidedellacasa/code/Fizzygum-all/fg presuite    # inner loop: build, dpr-1 suite, paint audit, fracplane rider (about 3 min)
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet    # commit point: 20 legs (about 15 to 20 min), run in the background, log to a file
/Users/davidedellacasa/code/Fizzygum-all/fg homepage    # production profile boot and snapshot round-trip
/Users/davidedellacasa/code/Fizzygum-all/fg fingerprint # build-tree diff against a baseline ref (§1, §10)
/Users/davidedellacasa/code/Fizzygum-all/fg cc          # cognitive complexity, read-only (§8)
```

A reference image is recaptured only after the changed pixels have been attributed to the change
and the owner has seen them. A fuzz or audit failure is never a reason to recapture.

## 15. References

- `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, `Fizzygum-tests/DETERMINISM.md`
- `docs/README.md` (filing rules), `docs/BACKLOG.md`, `docs/archive/INDEX.md`
- `docs/architecture/build-and-packaging.md` (§1, §3, §10)
- `docs/architecture/lint-and-static-checks.md` (the gate index; §4, §8, §10)
- `docs/architecture/transforms.md`, `docs/architecture/viewports-and-planes.md` (§6)
- `docs/architecture/layout.md`, `docs/architecture/world-lifetime-and-inventory.md` (§5, §7)
- `docs/architecture/widget-authoring-guidelines.md`, its §5 on the appearance factory (item §9)
- `docs/archive/god-class-decomposition-plan.md`, `docs/archive/oo-smells-refactoring-backlog.md`
  (the two earlier arcs this survey builds on)
- `buildSystem/lib/what-runs.js` (its header documents every root of "what runs"; §2, §10)

## 16. Start prompt for a fresh session

```
Read Fizzygum/docs/plans/top-10-cleanups-plan.md in full (it is a survey of ten candidate
cleanups, ordered by effort; its STATUS says what has landed). Then run
/Users/davidedellacasa/code/Fizzygum-all/fg status and confirm no long operation is running.

I want to take up item §<N>. Do this, in order:
1. Run the item's "Re-measure" command and tell me whether the numbers still match the plan.
2. Read the code the item cites and tell me anything that contradicts its evidence or its
   fix shape. Treat every statement marked UNVERIFIED as a question to answer first.
3. If the item is marked "owner decision first", stop there and lay out the options.
4. Otherwise propose the first step exactly as the item states it, wait for my go-ahead,
   and verify with the plan's §14 protocol.
Do not commit or push without asking me.
```

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- §1, in part — the line read: "§1 (½ day): repository hygiene — nine orphan files, two vendoring homes, three
  closed plans at the tests-repo root, the empty `SWCanvasBrokenTests` lists (⛔ owner on the last)". — LANDED IN
  PART 2026-11-13 (loop U1): eight orphan files deleted, the three closed plans archived, the pre-compiled stub's
  header made true (§1, the first "Landed"). BACKLOG keeps the rest: the vendoring homes, `SWCanvasBrokenTests` (owner), the
  kept `.psd` (owner).
- §1, the next part — the line then read "… two vendoring homes; …". — LANDED IN PART 2026-11-13 (loop U2): the
  third-party libraries in `vendor/`, the build's own copied files in `assets/`, `auxiliary files/` gone (§1, the
  second "Landed"). BACKLOG keeps `package.json`'s `main`, `SWCanvasBrokenTests` (owner) and the `.psd` (owner).
- §7, in part — the line read: "§7 (½ day, then 3 days): derived-geometry caches — one oracle method (17 copies
  today), then one declared memo (perf-gated)". — LANDED IN PART 2026-11-13 (loop U3): step 1, one oracle
  (`TreeNode._reportIfCachedDiverges`; §7, "Landed"). BACKLOG keeps step 2, the declared memo (owner).
- [x] §4 (1 day): the 15 `debugger`-only invariant traps report through a gated token, or are deleted with evidence
  — CLOSED 2026-11-13 (loop U4): ten report under `INVARIANT_VIOLATED`, one deleted with its evidence, the rest
  (one already reporting, three before a throw) simply go; the stink is a hard zero (§4, "Landed").
- §10, in part — the line read: "§10 (5 to 6 days): build logic in one language (port `build.py` + `buildProfile.py` to
  Node) and the gate sequence as a table". — LANDED IN PART 2026-11-13 (loop U5): step 1, the port (§10, "Landed").
  BACKLOG keeps step 2, the gate table.
- [x] §10 step 2 (about 3 days): the gate sequence as a table (`build_it_please.sh`'s gate blocks become rows a runner executes; `lib/what-runs.js` reads the table). Step 1, the Node port, landed (the plan's `## BACKLOG ledger`)
  — CLOSED 2026-11-13 (loop U6): `buildSystem/gates.js` + `buildSystem/run-gates.js` (§10, the step-2 "Landed").
- §8, in part — the line read: "§8 (1 day, then 2 to 3 days): method-count and cognitive-complexity ratchets; split the
  sequential giants (supersedes the `lint-generic-rules-carryover-plan.md` §8.5 C line below once built)". — LANDED IN
  PART 2026-11-13 (loop U9): step 1, the ratchets, `buildSystem/check-complexity-ratchets.js` (§8, "Landed"); the §8.5 C
  line closed as superseded into its own plan's ledger. BACKLOG keeps step 2, the splits.
- [x] §8 step 2 (2 to 3 days): split the sequential giants. Step 1, the ratchets, landed (the plan's `## BACKLOG ledger`)
  — CLOSED 2026-11-13 (loop U10): three split
  (`Deserializer.deserialize`, `._envelopeShapeProblem`, `._worldSectionProblem`), three left with what binds each
  (§8, the step-2 "Landed").
- [x] §5 (2 days): lift the browser-input bridge (seven listener methods) off `WorldWdgt`
  — CLOSED 2026-11-13 (loop U7): `world.browserInput`, `src/events-input/BrowserInputBridge.coffee` (§5, "Landed").
  BACKLOG keeps §5's unexamined second candidate, `FrameWdgt`'s docking family.
- [x] **The `debugger-statement` stink counts only a `debugger` that opens its line** (same review; by reading; low).
      Four `if … then debugger` sites go uncounted (`WorldWdgt`, `CaretWdgt`, `RectangularAppearance`,
      `BoxyAppearance`), and the static-checks table states no blind spot for it.
  — CLOSED 2026-11-13 (loop U4; filed under `archive/argument-holes-both-repos-plan.md`'s section, "found by the
  independent review closing" another item): the stink sees the statement in any spelling, the four sites are gone
  (§4, "Landed"), and the static-checks table states its one blind spot (embedded JavaScript).
- [x] §6 (3 days): one plane-mapping protocol for the ancestor walk (8 loops and 10 `instanceof TransformFrameWdgt` in
  `Widget`) (⛔ owner: built, proven exact and PARKED on a speed trade by the loop's U8 — §6's OWNER DECISION, the patch
  in the loop's scratch)
  — CLOSED 2026-11-13 (loop U8, landed on the owner's ruling): `mapsPlaneOfChild` and its verbs on `TransformFrameWdgt`
  and `ViewportWdgt`, the eight walks folds over `_enclosingMappedPlaneRoot` (§6, "Landed").
