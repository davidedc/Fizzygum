# Top 10 code and architecture cleanups, round 4 — a survey, ordered by effort

> **PLAN ONLY. Written to be read and executed COLD by an LLM/engineer with ZERO prior context.**
> This is a SURVEY of ten candidate arcs, authored 2026-11-15 (late evening) and ordered by
> effort, smallest first. Each item is a proposal with its evidence. Three of the ten needed an
> owner decision before any code moved (marked in the table under "The list at a glance"), and
> one more was a re-listing the owner might have declined again (§10); STATUS, below, says how
> each was ruled.
>
> **Relation to the earlier surveys.** `docs/archive/top-10-cleanups-plan.md` (2026-11-11) took the
> framework's structure and the build. `docs/archive/top-10-cleanups-round-2-plan.md` (2026-11-13)
> took the test harness, the reference set and the verification tooling.
> `docs/archive/top-10-cleanups-round-3-plan.md` (2026-11-15, morning) took what the ratchets do
> not measure. Of their thirty items, twenty-five have landed and five wait on the owner (round
> 1's §9, round 2's §10, round 3's §4, §7 and §9). Nothing here repeats any of them: this round
> was surveyed on the tree as round 3's loop left it the same evening. Three items take up
> something already filed in `docs/BACKLOG.md` and say so (§2, §6, §7), and one re-lists
> something round 2 measured and left, with what has changed since (§10).
>
> **STOPPED 2026-11-16 (its loop, after §1, which archived it).** Landed: §1, §2, §3, §4, §5, §6, §8, §10, and §7 after
> the loop, on the owner's ruling (a). Waiting on the owner: §9 (skipped) — the BACKLOG line under this file's name.
>
> **STATUS (owner, 2026-11-15).** The owner skipped §9 for now (it stays on `docs/BACKLOG.md`
> and is not taken up until asked for) and approved the other nine "along your best
> recommendation", so each open decision is ruled as this survey recommended, and each ruling
> is written in its item's `**Ruled 2026-11-15 (owner).**` paragraph: §1 yes, a stopped survey
> is archived; §3 the lines go if a production artifact grows by no more than 2 KB; §4 npm;
> §7 lands only if it is not slower; §10 lands and is pushed when every proof of its own plan
> (`docs/archive/build-node-port-plan.md`) passes. An unattended `/loop`, launched by the owner,
> executes the nine one unit at a time; its brief and ledger are local to the loop
> (`Fizzygum-tests/.scratch/cleanups-loop-4/`). An item's section gains a `**Landed <date>.**`
> paragraph as it lands, and the table's last column says where each stands. Landed: §5
> (2026-11-16), §8 (2026-11-16), §4 (2026-11-16), §3 (2026-11-16), §6 (2026-11-16), §2 (2026-11-16), §10 (2026-11-16), §1 (2026-11-16), §7 (2026-11-16, after the loop, on the owner's ruling (a)).
>
> **Mandate.** Each item aims at ELIMINATING a duplicated mechanism or a dead one, not at making it
> easier to live with. Where an item stops short of elimination, it says why.
>
> **Baseline.** Every number below was measured on 2026-11-15 between 22:55 and 23:30 on the
> tree of Fizzygum `5e12b629` and Fizzygum-tests `dadc49208` (both clean but for this file; the
> last gauntlet, 23:17 the same day, green at 20 of 20 legs in 1,154 s). `5e12b629` raised the
> `selftests` leg's alarm and was committed by another session while this survey was being
> measured; its two files were already in the working tree for every measurement here. Line
> numbers drift: the method name or the quoted code is the authority, and every item carries the
> command that re-measures it. Statements are labelled **MEASURED** (a command was run),
> **READ** (the code was read) or **UNVERIFIED** (a hypothesis the item's first step must
> test).

---

## 0. Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework drawn on one `<canvas>`. Three sibling
git repos sit under an umbrella directory `Fizzygum-all/` (itself a small private repo of
workspace tooling): `Fizzygum/` (source, build, and the `fg` workflow wrapper), `Fizzygum-tests/`
(the SystemTest suite, the Automator harness and the headless rigs) and `Fizzygum-builds/`
(generated output). Read `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` before touching
anything.

**Why a fourth survey, and what it found.** The source itself now reads clean on every
instrument the project has, and this round added three probes of its own that came back all
but empty (§11 has the numbers): one class is unreferenced and an active plan already owns it,
exact duplication is 0.52% of the source lines and the largest clones are already triaged, and
no boot-level function is unused. So
seven of the ten items below are in the tooling and the harness, two are in the product's
source (§3 touches the build's treatment of it, §7 the text caches), and one is filing (§1).
That distribution is a finding, not a choice.

**Three reframes that shaped the list.**

1. **A port that had to stay equal is finished only when the equality rule is lifted.** Round
   3 moved `fg` from bash to Node under a rule that its output, and its help text, stay
   identical to the old program's, because that was the proof. The rule is why the help still
   says what the bash program did, why a Node program reads another Node module through shell
   text, and why the build script is now the only shell program left on the path to a commit
   (§2, §10).
2. **The same work done twice is the debt that is left.** Not the same code written twice,
   which the duplication scanner holds near zero, but the same computation run twice: a
   screenshot's pixels hashed by two implementations (§5), every source file read and masked by
   twenty processes in a row (§6), a text hashed natively by one table so that a weaker hash of
   it can key another (§7), one analyzer installed in two places (§4), six instruments each
   carrying the same helpers (§8).
3. **What only a person starts has no proof that it starts.** Round 3 said this of tools. It
   also holds for three of the five build profiles (§9).

**How the list was made.** `fg critique`; the stink baselines; a census of `src/` by directory
and by code lines; `./find_duplicated_code.sh` over the source and, with `--tests`, over the
tooling; a probe of which class no other code file names; a probe of boot-level functions
nothing calls; a timing of every static gate row run as the build runs it; the recorded
durations of every self-test; a read of `fg`'s three modules, the build script, the gate
runner, the harness's hashing and the text caches; byte counts of `docs/plans/`; a full read of
`docs/BACKLOG.md` (possible in one pass since round 3 made it an index). Each candidate was then
checked against the BACKLOG, the active plans and the three earlier surveys, and dropped if an
active plan already owns it (§12) or if earlier case law bounds it (§13).

**Order.** Effort, smallest first, so the cheap items can be taken without reading the expensive
ones. Effort means the whole item including its verification runs (one gauntlet is 18 to 28
minutes). The figures are ESTIMATES in working days; none is measured, and two items within half
a day of each other could swap. The table's "Payoff rank" keeps the other ordering: removed
mechanism, weighted by confidence in the evidence, divided by cost and risk (1 is the best
return).

---

## 0.5 Cold-execution protocol

1. **This document is a menu, not a script.** Pick ONE item. Items are independent except where
   one names a dependency: §3 before §10 (it removes four lines §10 would otherwise port) and
   §2 before §10 (both touch how the profile is read).
2. **Re-measure first.** Run the item's re-measure command and compare with the numbers here. If
   they differ materially, the tree moved: re-read the code before trusting the fix shape.
3. **Items marked "owner decision first" stop at the decision.** Present the evidence and the
   options; do not start the code.
4. **An item that is taken up becomes its own plan** in `docs/plans/` when it is more than a
   day's work (§9, §10), following `docs/README.md`'s filing rules; its line in
   `docs/BACKLOG.md` then points at the new plan and this survey's line for it is removed. §10
   has its plan already: `docs/archive/build-node-port-plan.md`.
5. **Verify with the shared protocol in §14**, plus whatever the item adds.
6. **Never commit or push without the owner's approval.** Present a summary and the proposed
   commit message and wait.
7. **`fg` runs one long operation at a time.** If `fg status` shows a RUNNING verdict, do not
   edit sources or run a build: a running operation owns its inputs, and a second one is
   refused (exit 2).
8. **A timing claim is measured on an idle machine and on the real methods.** §6 and §7 each
   rest on a speed measurement; §13 has the rule both follow.

---

## The list at a glance

Ordered by effort, smallest first. Effort is an estimate in working days for the whole item.
The fourth column says what is removed, then says the item again in plain words for a reader
who has never seen the code. The fifth says why the change is worth making and what it costs,
as one would explain it to a five-year-old; each item's own section has the precise version.

| # | Cleanup | Effort (estimate) | What goes away, and in plain words | Why, and the trade-offs (ELI5) | Pixel risk | Owner decision first | Payoff rank | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | Stopped surveys leave `plans/` | ¼ day | Three files, 278 KB, a quarter of the folder for active plans; 25 of their 30 items have landed. **In plain words:** the folder for work still to do holds three long reports that are almost entirely about work already done. Move them to the archive; the five items they left stay on the open-work index. | **Why:** a to-do drawer stuffed with finished homework makes the unfinished pages hard to find. Put the finished homework on the shelf and leave a note in the drawer for the five pages still to do. **Trade-offs:** a reader of an old item hops to the archive folder for its story; 28 lines in other files that name the old location must be corrected in the same change. | None | Yes (a filing ruling) | 8 | Landed 2026-11-16 (§1, "Landed") |
| 2 | `fg` says what it does, and asks the build's own modules | ½ day | Five stale lines and one missing line in `fg`'s help; a second way of judging "is the build fresh"; a Node program reading a Node module through shell text; a status count that can never read zero. **In plain words:** the command that runs every check was rewritten last round under a rule that its help text must not change by one byte. The rule has done its job. Now the help can say what the command does, and the command can ask its neighbours directly. | **Why:** the leaflet in the box still describes last year's toy. Nobody is hurt, but whoever reads the leaflet learns the wrong thing, and one page of it says "fresh" while the kitchen says "stale". **Trade-offs:** the help text changes, so anything that compares it with the old text has to be found first; nothing else. | None | No | 5 | Landed 2026-11-16 (§2, "Landed") |
| 3 | The build's last text-level strip | ½ day | Four `sed` lines that rewrite compiled JavaScript by pattern, a macOS-only flag, a comment about a class that no longer exists. **In plain words:** when the build makes the production version, it searches the finished code for six "is the test kit here?" questions and replaces each with "no", so the code behind the question can be thrown away. Each question already answers "no" by itself when the test kit is absent. | **Why:** somebody goes through the finished book with correction fluid, painting over six sentences that begin "if the teacher is in the room". The teacher is never in that room, so the sentences do nothing anyway. And if the printer ever changes the lettering, the fluid misses and nobody notices. Stop painting. **Trade-offs:** the production file grows by the size of those six passages (to be measured first; a few hundred bytes of 1.3 MB are expected). | None | No | 6 | Landed 2026-11-16 (§3, "Landed") |
| 4 | Build-time libraries from one place | ½ day | A second way of pinning a tool; one analyzer present twice, byte for byte; two hand-kept notes of where a copy came from. **In plain words:** some helper programs the build uses are fetched by one install command at exact versions; two others are pasted into the repository by hand; and one of those two is also fetched, so it exists twice. Pick one way. | **Why:** most of the kitchen tools come from the shop with a receipt, and two were copied by hand from a friend's, with a hand-written note of where they came from. One of those was also bought, so there are two of it. One way of getting tools means one list to check. **Trade-offs:** the shop way needs the network on a new machine (already true since round 3); the by-hand way keeps every upgrade a manual chore. | None | Yes (which place) | 9 | Landed 2026-11-16 (§4, "Landed") |
| 5 | One SHA-256 in the harness | ½ to 1 day | A hand-written SHA-256 (about 89 of the file's 109 code lines), a second hashing of pixels already hashed, one of three implementations that must agree. **In plain words:** to recognise a screenshot the test kit computes a fingerprint of its pixels. It has two fingerprint machines, the browser's own and a hand-written one, and for a screenshot that does not match it runs both on the same pixels. Use the browser's, and pass its answer along. | **Why:** two rulers that must agree to the last hair: if they ever differ, every saved picture gets the wrong name. One ruler cannot disagree with itself. **Trade-offs:** the two places that use the hand-written one cannot wait for an answer today, so one is handed the answer that already exists and the other compares the pixels directly; the saved pictures' names must be shown unchanged. | None (the same digest; proven on one capture) | No | 4 | Landed 2026-11-16 (§5, "Landed") |
| 6 | Gate rows run side by side; the tests syntax gate parses in-process | 1 day | 778 process launches per build; a one-at-a-time queue of 33 checks on a 16-core machine; the reason for a planned cache. **In plain words:** every build runs 34 checks one after another, and one of them starts a fresh program for each of 778 test files just to see whether the file parses. Parse them all in one program, and let checks that do not depend on each other run at the same time. | **Why:** thirty-three children wait in one line to wash their hands at one tap while fifteen taps stand unused, and one child walks to a different sink for each finger. Use the taps. Every build, and so every test run, waits for this line. **Trade-offs:** the printed report must still come out in the old order, so each check's output is held until its turn; and when one check fails, the ones after it have already run for nothing. | None | No | 1 | Landed 2026-11-16 (§6, "Landed") |
| 7 | Text cache keys are the text | 1 day | Seven cache keys built on a 32-bit hash, the hash's own memo table and its accounting, a filed bug. **In plain words:** to avoid measuring and drawing the same text again, results are filed under a short number computed from the text. Two different texts can get the same number ("Of" and "PG" do), and then the second shows the first's result. File results under the text itself, beside the font, size, alignment and the rest, which the label already carries and which do not change. | **Why:** coats in the cloakroom are hung by the first two letters of the owner's name, so Anna sometimes gets Andrew's coat. Hang them by the whole name. **Trade-offs:** whole names take longer to read than two letters, and this cloakroom is used thousands of times a second, so it must be timed on real use before and after; the labels also take a little more room. | None expected (a difference would be a collision being put right) | No | 2 | Landed 2026-11-16 on the owner's ruling (a) (§7, "Landed") |
| 8 | Audit preludes share one head | 1 day | 17 copied blocks (170 lines) across 13 instrument files. **In plain words:** six measuring instruments are slipped into the test page, each as one self-contained file, and each carries its own copy of the same small helpers. A fix made in one copy does not reach the others. Keep the helpers in one file and join it to each instrument when it is used. | **Why:** six toolboxes each hold their own copy of the same screwdriver, and one day one copy is found bent. Keep one good screwdriver and lend it to every box. **Trade-offs:** an instrument is no longer one file that can be handed over by itself; the joining step is one more thing that can go wrong, and has to be proven by the instruments' own planted faults. | None | No | 10 | Landed 2026-11-16 (§8, "Landed") |
| 9 | Every profile is built by something, or it goes | 1 to 1½ days | Three of five build flavours that no command, gate or test ever builds. **In plain words:** the project can be built in five flavours. The checks build two of them. The other three are built only when a person remembers to, so nothing would notice if one stopped working. Have a check build each flavour that is wanted, and delete the ones that are not. | **Why:** five doors lead out of the house and two are tried every day. The other three may be stuck, and nobody will know until the day one is needed. Try every door now and then, or brick up the ones nobody uses. **Trade-offs:** trying a door takes a minute or two each time; bricking one up loses a flavour somebody may want twice a year. | None | Yes (which flavours are products) | 7 | Left for a later day by the owner (2026-11-15) |
| 10 | The build is one Node program | 2 to 3 days | 260 lines of bash, the shell-text bridge out of the profile module, a hand list of the files the script reads, the flag mapping of a second script. **In plain words:** the build is a shell script that starts a JavaScript program seven times and has one of them print shell text for it to read back. Round 2 measured it and left it. Since then the command that calls it has moved to JavaScript, and it is the last shell program a commit depends on. | **Why:** the family now speaks one language at the table, except for one member who needs every sentence passed on a slip of paper, in both directions. **Trade-offs:** it rewrites the thing that makes the product, so every flavour's output must be shown identical byte for byte before and after (a tool for that exists); it adds no feature; and seven small shell helpers remain, so shell does not leave the repository. | None (byte-identical trees) | No (a re-listing: the owner may decline it again) | 3 | Landed 2026-11-16 (§10, "Landed") |

---

## §1. Stopped surveys leave `plans/`

**Owner decision first:** a filing ruling, stated under "Fix shape".

**Ruled 2026-11-15 (owner).** Yes: a survey is closed when its loop stops, and what it left
behind is BACKLOG lines pointing at its sections. The loop takes this item LAST, so that the
paths every other unit works with stay put until then, and it moves all four surveys in one
commit, this one included (stamped with what its own loop landed and what waits).

**Effort.** A quarter of a day: three moves, three stamps, the index lines and the references.

**Evidence.**
- MEASURED: `docs/plans/` holds 14 files and 1,137,607 bytes. The three cleanup surveys are
  277,598 of them (95,893 + 87,649 + 94,056), 24% of the folder. This survey adds a fourth.
- MEASURED: what the three still own is nine lines of `docs/BACKLOG.md` (two, three and four).
  Twenty-five of their thirty items have landed; the five that have not wait on the owner.
- READ: each survey's loop has stopped (2026-11-13, 2026-11-14 and 2026-11-15; each survey's
  STATUS header says so).
- READ: `docs/README.md` defines the bucket: "`plans/`: ACTIVE arcs only: plans with genuinely
  open, executable work". Its rule 2 moves a plan to `archive/` when its arc closes, and its
  rule 5 keeps an archived plan's open items on the BACKLOG, with their full text in the plan's
  own `## BACKLOG detail` section. Round 3's §8 built exactly that section into all three
  surveys.
- MEASURED, before this file existed: 28 lines in 14 files name one of the three by its
  `plans/` path (six files under `docs/plans/`, four under `docs/archive/`, the BACKLOG, one
  architecture document, `buildSystem/check-complexity-ratchets.js` and one file under
  `src/basic-data-structures/`). This file adds its own, and moves with them.
- MEASURED: a survey is 88 to 96 KB, and one read by the tooling takes about 100 KB at most, so
  a session that opens `plans/` to see what is open spends two or more reads per survey on what
  is closed.

**Why it matters.** `plans/` is where a session looks for what is open. A quarter of it is the
story of what has landed, and the next survey makes it a third.

**Fix shape.** The ruling asked of the owner: *a survey is closed when its loop stops; what it
left behind is BACKLOG lines pointing at its sections.* If yes: `git mv` the three surveys to
`docs/archive/`, stamp each STATUS (STOPPED, the date, what landed, what waits), add three
lines to `docs/archive/INDEX.md`, change the three BACKLOG section headings from `plans/…` to
`archive/…`, correct the 28 references, and add the ruling as one sentence to README rule 2.
This survey then follows the same rule when its own loop stops.

Not proposed: splitting the two largest plans (§11 says why).

**Risk.** A dead link. The proof is a grep for the three old paths that returns nothing, and
`fg doc-narration` passing.

**First step.** Ask the owner the ruling. The moves follow in one commit.

**Re-measure.** `ls Fizzygum/docs/plans | wc -l` and `cat Fizzygum/docs/plans/*.md | wc -c`.

**Landed 2026-11-16 (as ruled, taken last).** The four surveys, this one included, are in
`docs/archive/`, each STATUS header stamped STOPPED with the date its loop stopped, what landed and
what waits on the owner; `docs/archive/INDEX.md` has a line for each; the BACKLOG's four section
headings name `archive/…`, and their items are unchanged; every reference to the four old paths in
both repos is corrected (43, in 16 files); `docs/README.md` rule 2 says a survey is closed when its
loop stops. Proof: a grep of both repos and the umbrella's `CLAUDE.md` for the four old paths finds
nothing; `fg doc-narration` and the gauntlet (its build included) pass.

---

## §2. `fg` says what it does, and asks the build's own modules

**Effort.** Half a day. No owner decision.

**Evidence.**
- READ: round 3's §10 ported `fg` from bash to Node under a rule that its usage text stay
  byte-identical to the bash program's (`docs/archive/fg-node-port-plan.md` §3). The loop's
  ledger records three places where that rule kept a text from being corrected.
- MEASURED, in the usage text of `buildSystem/fg-verbs.js`:
  - `fg graph` still says "mixin super chains terminate". The mixin mechanism was deleted on
    2026-11-12 and the rule is `SUPER_CHAIN_TERMINATES` (a BACKLOG one-liner, open).
  - `fg killz` says "kill leftover headless test browsers". Since the port it also kills what
    a dead run left behind.
  - `fg critique` says "~5 s". It took 15 s today.
  - `fg doc-narration` names the narration ratchet and the closed-item rule, and not the item
    length ceiling or the two instruction-file ceilings the same script enforces.
  - `fg run-sequence` omits the stale-build refusal (a BACKLOG line, open).
  - Nothing in the usage says that a second long operation is refused, what
    `FG_ALLOW_CONCURRENT=1` does, what an INTERRUPTED or a STALE verdict is, or that an unknown
    verb exits 2. The file's own header comment says all four, and so does `Fizzygum/CLAUDE.md`.
- MEASURED: `fg status` decides FRESH or STALE by walking for a `.coffee` file newer than
  `latest/index.html` (`fg-verbs.js`, the `walk` inside the status verb). Every runner asks
  `buildStaleness()` in `buildSystem/lib/build-inputs.js` instead, which also covers
  `parts.json`, the profiles, `src/index.html`, the vendored engine, the font assets and the
  build script. The BACKLOG holds this as an open line, and the line itself still speaks of
  "the build's Python", which round 1 removed.
- MEASURED: the Node `fg` learns the build profile by launching
  `node buildSystem/lib/profile.js --shell` and reading back `PROFILE_NAME=…` assignments
  (`fg-commit-point.js`, beside the text "ships no harness page"). That format exists for
  bash's `eval`.
- MEASURED: `fg status` prints `Fizzygum-builds … dirty=2` on a clean workspace. The two
  entries are `.DS_Store` and `latest/`, both untracked; that repo has no `.gitignore`, so the
  count can never read 0.

**Why it matters.** `fg` invoked bare is the documented source of truth for the roster ("ask
it; a hand-copied list drifts"). `fg status` is the one command a session runs to orient
itself, and two of its lines cannot be trusted as printed.

**Fix shape.** Rewrite the six usage texts to the behaviour. `fg status` calls
`buildStaleness()` and prints what it answers. `fg` requires `lib/profile.js` and asks it
in-process. `Fizzygum-builds/` gains a two-line `.gitignore` (that repo's commit is the
owner's). Three BACKLOG lines close: "`fg`'s selftests-leg budget comment and its
`run-sequence` usage are stale" (`5e12b629` rewrote the comment with today's figures and left
the line open; the usage half is this item's), "`fg status` reads build freshness from the
sources alone", and "`fg` still names mixins in two places".

**Risk.** Something that compares the usage text with the old one. MEASURED: no self-test
file in either repo contains three of the stale strings ("mixin super chains", "kill leftover
headless", "ADVISORY code-critique"), and the port's own 109-scenario comparison was the loop's
proof, not a standing gate. UNVERIFIED for the other three texts. `lib/what-runs.js` reads
`fg`'s modules as roots; a `require` of `lib/profile.js` is an edge it already follows.

**First step.** Grep every `*-selftest*.js` for all six usage texts. Then list each text
beside the behaviour it should state, and show the owner the diff of the usage alone.

**Re-measure.** `/Users/davidedellacasa/code/Fizzygum-all/fg | grep -c mixin` (1 today), and
the `Fizzygum-builds` line of `fg status`.

**Landed 2026-11-16.** The six usage texts say the behaviour: `fg graph` names its rule,
`SUPER_CHAIN_TERMINATES` (and so does the leg's comment in `legs.js`); `fg killz` also kills what
a dead run left running; `fg critique` says about 15 s (14.0 s at load 52, 14.1 s at load 9, on
16 cores); `fg doc-narration` also names the BACKLOG item-length ceiling and the byte ceilings of
`Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md`; `fg run-sequence` says a STALE build is
refused, exit 2 (`--list` and `--before` excepted, `FIZZYGUM_ALLOW_STALE_BUILD=1` overriding);
and a new line beside the verdict note says that a second long operation is refused (exit 2,
`FG_ALLOW_CONCURRENT=1`), that an interrupted run says INTERRUPTED, that a run whose `fg` died
reads STALE, and that an unknown verb exits 2.
`fg status` prints what `buildStaleness()` answers: its build line keeps its first two words,
gives when the last completed build started (`lastBuildTime()`: `.build-stamp` carries the
start marker's time), and for a stale build says why, naming at most three inputs; its own walk
is gone. `fg` asks `lib/profile.js` in its own
process for the suite tiers' harness-page check (`--shell` stays for the build script). Both
modules are required where they are used, not when `fg` loads, so a reader that cannot load
refuses only what needs it: the suite tiers refuse, exit 2, and `fg status` and `fg help` still
answer (the same rule as the leg table's, B12); inputs `fg status` cannot list read STALE, as
the runners refuse such a build.

The evidence:
- the diff of bare `fg`'s output is the six texts and nothing else, and `fg | grep -c mixin`
  is 0;
- `touch buildSystem/parts.json` with no content change: `fg status` reads STALE and names
  `Fizzygum/buildSystem/parts.json (changed)`; after `fg build` it reads FRESH;
- `fg presuite --profile nosuch` and `--profile lean` print the same lines on each stream as
  before, exit 2;
- the run set (`what-runs.js --list-scripts`, and `runSet()`) is unchanged;
- `fg-gauntlet-selftest-headless.js` (the `selftests` leg) runs a copy of `fg` whose stand-in
  profile reader answers in process, and which holds no `lib/build-inputs.js`, so every case
  proves `fg` loads without it (a planted load of it when `fg` loads fails every case). Two new
  drills: a profile reader that cannot load refuses `presuite` before the build while
  `fg status` and `fg help` answer (a planted load of `lib/profile.js` when `fg` loads fails it
  and nothing else); and `fg status`'s build line on a copy with a tree reads STALE when no
  reader can list the inputs, names at most three inputs for a stale answer and says when the
  build started for a fresh one (a planted list of all four fails it and nothing else).

Not done (that repository is not the loop's): `Fizzygum-builds` gains no `.gitignore`, so its
`dirty=2` (`.DS_Store` and `latest/`, both untracked) stays.

---

## §3. The build's last text-level strip

**Effort.** Half a day, most of it the measurement and one `fg homepage`.

**Ruled 2026-11-15 (owner, on this survey's recommendation).** The four lines go if neither
production artifact (`homepage`, `lean`) grows by more than 2 KB, which is 0.15% of the
appliance. If either grows by more, the item is parked with the numbers.

**Evidence.**
- MEASURED: on a profile that ships no tests, `build_it_please.sh` runs two `sed -i ''`
  substitutions over the compiled boot code and the same two over the pre-compiled image (four
  lines). They rewrite `if (typeof Automator… !== "undefined" && Automator… !== null)` to
  `if (false)`, so that the minifier drops the branch.
- MEASURED: seven places in `src/` spell `Automator?`: three in `boot/globalFunctions.coffee`,
  two in `WorldWdgt`, one in `ButtonWdgt`, one in `TreeNode`. Six are `if` tests the patterns
  can match. The seventh is the body of `aTestIsPlaying`, an expression, which they cannot.
- READ: what the six guard: building the page's automator, handing it the two test manifests
  (twice), the "System tests" row of the desktop menu, a type tripwire in `ButtonWdgt.trigger`
  and an `INVARIANT_VIOLATED` report in `TreeNode.isAncestorOf`. On a tree without the harness
  part each test is false when it runs, so each branch is already unreachable.
- READ: the comment over the lines names `AutomatorRecorder`, a class removed with the
  recorder, and explains that `-i ''` is the macOS spelling (GNU sed reads it differently).
- READ: the pair that rewrites the image runs for EVERY pre-compiled profile, with no test of
  whether the profile ships the harness. Its comment says "a precompiled artifact is only
  built for a profile without the harness part", which stopped being true when
  `dev-precompiled` was added: that profile ships the harness, and the strip turns the
  harness's guards off in its image all the same. The same comment's "saves around 12kBs" was
  measured when 46 core lines named the harness; six do now.
- READ: `Fizzygum/CLAUDE.md`, "How a build flavour excludes code": two text-level exclusion
  mechanisms were retired and are gated at zero, and "the lesson is that invisible, text-level
  exclusion is the wrong tool, not that its spelling was wrong". This is a third one. It works
  on compiled output, nothing gates it, and if the compiler ever spells `X?` differently it
  stops matching without a word.
- UNVERIFIED: how many bytes it saves. A few hundred are expected, of an appliance artifact
  that is 1.3 MB in all.

**Why it matters.** It is the one place left where the build changes what code means by
editing its text, and the project has ruled that tool out twice.

**Fix shape.** Delete the four lines and their comment. The existence guards stay, and do at
run time what every other part's guards do. `ButtonWdgt`'s comment ("`if Automator?` ⇒ absent
from a production build") is corrected to say the branch cannot run there.

**Risk.** None to the product's behaviour: `homepage` and `lean` ship no harness, so each
guard is false there with or without the strip. The cost is bytes in those artifacts, which
the first step measures. One dev flavour does change: `dev-precompiled`'s image keeps its
harness guards live, as the `dev` page it mirrors does, so its boot smoke
(`./build_and_smoke.sh --profile dev-precompiled`) is part of this item's proof.

**First step.** Remove the four lines in a scratch worktree and run `fg fingerprint homepage`
and `fg fingerprint lean` against `HEAD`: the diff must be those six branches and nothing
else, and its size is the number to show the owner.

**Re-measure.** `grep -v '^\s*#' Fizzygum/build_it_please.sh | grep -c "sed -i"` (4 today) and
`grep -rn 'Automator?' Fizzygum/src --include='*.coffee' | grep -v ':\s*#' | wc -l` (7).

**Landed 2026-11-16 (the bytes within the ruling).** The four `sed` lines, their two comments and
the `if` that held the boot pair are gone from `build_it_please.sh`, and with them the strip's
row in the derivation table (`build-and-packaging.md` §4, `lib/profile.js`'s header,
`parts.json`'s note on the harness part). `ButtonWdgt.trigger`'s comment says the check cannot run
without the harness part. Measured with `fg fingerprint <profile> HEAD`, the four lines removed
and nothing else:

| profile | boot bundle | image | growth |
|---|---|---|---|
| `dev` | identical | identical | none |
| `homepage` | +280 | +764 | 1,044 bytes |
| `lean` | +280 | +764 | 1,044 bytes |
| `dev-notests` | +280 (each of two) | unchanged | 560 bytes |
| `dev-precompiled` | identical | +1,441 | 1,441 bytes |

Both production artifacts stay under the ruled 2 KB. A `homepage` built with the old and the new
script, both re-printed one statement a line, differs in exactly the six guarded branches:
- the two hand-offs of the test manifests (boot code);
- `TreeNode.isAncestorOf`'s invariant report;
- `ButtonWdgt.trigger`'s type tripwire;
- the world's automator;
- the desktop menu's "System tests" row.

No other line differs, apart from the build's own stamp. `dev-precompiled`'s image keeps its
harness guards live, as the `dev` page it mirrors does. The evidence besides the table:
`./build_and_smoke.sh` passes for `lean`, `dev-notests` and `dev-precompiled`; `fg homepage`
passes; the resolution map moves only `ButtonWdgt.trigger` (by its comment); the gauntlet passes.

---

## §4. Build-time libraries from one place

**Owner decision first:** which place.

**Ruled 2026-11-15 (owner, on this survey's recommendation).** Option (a): npm, pinned
exactly, checked by the build.

**Effort.** Half a day.

**Evidence.**
- MEASURED: the build's tools have two homes. Through npm (`package.json`, installed by
  `npm ci`, which the build has required since round 3's §3): `coffeescript` 2.7.0 and `terser`
  5.39.1, both pinned exactly and both checked by the build against what is installed, and
  `coffeescript-cognitive-complexity`, `jscpd`, `jsinspect` and a CoffeeScript 1 under caret
  ranges. Vendored (`vendor/`, tracked): acorn 8.19.0 (`acorn.js`, 246,643 bytes) and the
  complexity analyzer 1.0.0 (`index.js`, 17,838 bytes), each with a README that records the
  tarball, its integrity hash and the steps for moving to another release by hand.
- MEASURED: the analyzer is present twice. `vendor/coffeescript-cognitive-complexity/index.js`
  and `node_modules/coffeescript-cognitive-complexity/index.js` are byte-identical (`cmp`). The
  ratchet gate loads the vendored one; `fg cc` runs the npm package's command line, because the
  vendored copy has none.
- MEASURED: `node_modules/acorn` is 7.4.1, pulled in by another package. The gates load the
  vendored 8.19.0 (`lib/js-mask.js`, `lib/call-sites.js`).
- READ: the owner's two rulings touch this from both sides: "tooling may vendor" (which is how
  acorn came in, when the build needed no install step) and round 3's §3, "pins the tools
  through npm, not by vendoring".

`vendor/coffeescript/fizzygum-coffeescript-min.js` is not part of this: it is the compiler the
product ships and runs in the browser.

**Why it matters.** Two ways of pinning means two procedures for an upgrade and two places to
look when a gate's parser is in question. And one file exists twice with nothing holding the
copies equal.

**Fix shape.** Option (a), recommended because it is the direction of the owner's latest
ruling: acorn 8.19.0 and the analyzer 1.0.0 become exact `devDependencies`; the build's
installed-version check, which covers coffeescript and terser today, covers them too; the two
`vendor/` directories go. Option (b): keep both vendored, drop the npm analyzer, and give
`fg cc` a short command line over the vendored file. Either leaves one copy of each.

**Risk.** A gate changing its parser without anyone choosing to. Under (a) the lockfile's
integrity hash holds the bytes, and the proof is a `cmp` of each installed file against the
vendored one before the vendored one is deleted, then every static gate's self-test (one
build). A tests-repo gate would reach the parser through `Fizzygum/node_modules` instead of
`Fizzygum/vendor`; both already cross the repo boundary into `buildSystem/lib`.

**First step.** Put the two options to the owner with the `cmp` result.

**Re-measure.** `ls Fizzygum/vendor` and
`cmp Fizzygum/vendor/coffeescript-cognitive-complexity/index.js Fizzygum/node_modules/coffeescript-cognitive-complexity/index.js`.

**Landed 2026-11-16 (option (a), as ruled).** `package.json` pins `acorn` 8.19.0 and
`coffeescript-cognitive-complexity` 1.0.0 exactly (`npm install --save-dev --save-exact`), and
`vendor/acorn/` and `vendor/coffeescript-cognitive-complexity/` are gone. Before the vendored
files went, each installed file was `cmp`-identical to its vendored twin (`dist/acorn.js`,
`index.js`). The three readers load the installed packages by a path built from `__dirname`,
never by a bare name: `lib/js-mask.js` and `lib/call-sites.js` for acorn,
`lib/cognitive-complexity.js` for the analyzer (it keeps its contract: the pinned CoffeeScript
at the version its caller names, or INVALID). The build's installed-version check names all
four packages with one message, so a stale install stops the build with `run npm ci in
Fizzygum/`; a planted `"acorn": "8.18.0"` showed it doing so. The hoisted acorn is now 8.19.0
(was 7.4.1, which `jscpd`'s `is-expression` still gets, nested); `terser` already ran on its own
nested 8.19.0 and now shares the hoisted one, the same bytes, so the minifier is unchanged.

The evidence:
- the static gates' whole transcript (`run-gates.js`, as the build runs it) is unchanged but for
  its timings, and the gate census still reads 55 launched gates;
- `fg critique` is unchanged;
- `fg build`, the presuite, the gauntlet and `fg homepage` pass.

The tests repo's tools now need `npm ci` in `Fizzygum/` too: they parse with the pinned acorn
(its `CLAUDE.md` says so). `Fizzygum/CLAUDE.md`'s prerequisite line is four bytes shorter; its
ceiling is banked in `buildSystem/check-doc-narration-baseline.json`.

---

## §5. One SHA-256 in the harness

**Effort.** Half a day to a day, including one gauntlet.

**Evidence.**
- MEASURED: `Automator-and-test-harness-src/SHA256.coffee` is 170 lines, 109 of them code. About
  89 are a hand-written SHA-256 (the round constants, `hashBytes`, `hashRawPixels`); 19 are
  `hashRawPixelsAsync`, which hands the same bytes to the browser's `crypto.subtle.digest`.
- READ: its header says the two "MUST stay byte-for-byte compatible" with each other and with
  Node's `crypto` in `scripts/recompress-swcanvas-references.js`. That is three implementations
  of the digest that IS a reference image's identity; `scripts/lib/png-selftest.js` pins the
  Node one.
- MEASURED: the hand-written one has two callers, `SystemTestsReferenceImage`'s constructor and
  `AutomatorPlayer._liveCanvasFingerprintNow`.
- READ: the constructor is reached from `matchOrRecordSWCanvasScreenshot`, which is called with
  `liveHash`, the browser's digest of the same pixels, and builds the record from the same
  canvas. So for every screenshot that matches no reference and is kept with its pixels (which
  includes every capture) the pixels are hashed a second time, in JavaScript, to get a value
  already in hand.
- READ: the second caller takes a fingerprint before and after a full repaint and compares the
  two. That is an equality test of two pixel buffers.
- READ: the header also records that `crypto.subtle` is available over `file://` on both
  engines (verified 2026-07-08).

**Why it matters.** A screenshot's name is its digest. Two in-page implementations that must
agree is a standing way for a reference to be filed under a name its own test cannot match.
The second hashing is also the slow one, and runs on exactly the paths that are already slow.

**Fix shape.** The constructor takes the digest it is given. The paint audit compares the two
buffers byte by byte. `hashBytes`, `hashRawPixels`, the constants and the header's
compatibility warning between the two in-page twins go; `hashRawPixelsAsync` stays (in this
class or beside its one caller). One line a person can see changes, and only when a test
fails: `assertPaintTruthfulAfterFullRepaint` prints the two digests as "expected" and "got";
with no digests it says how many pixels differ and where the first one is.

**Risk.** A capture writing a different file name. The proof: capture one test into scratch on
the build before and on the build after and compare the names; then the gauntlet, whose `refs`
leg re-verifies every stored hash against its pixels and whose `selftests` leg plants the
paint audit's every rule. UNVERIFIED: that nothing outside the harness reads
`SHA256.hashRawPixels` (the grep over both repos' code found the two callers above and no
other).

**First step.** The grep again, then the constructor change alone and the two-build capture
comparison.

**Re-measure.**
`grep -rn 'SHA256\.' Fizzygum-tests/Automator-and-test-harness-src Fizzygum/src Fizzygum-tests/scripts --include='*.coffee' --include='*.js' | grep -v '/.scratch/' | grep -v 'SHA256.coffee'`.

**Landed 2026-11-16.** `SHA256.coffee` keeps its class and `hashRawPixelsAsync`, whose text is
untouched; the hand-written digest (`hashBytes`, `hashRawPixels`, the round constants, `rotr`,
`toHex8` and the self-test) is gone, and the header says there is one digest in the page, the
browser's, with its Node twin in the recompressor. `SystemTestsReferenceImage`'s constructor takes
`hashOfPixels`, the digest `compareScreenshots` already took of the same screenshot
(`matchOrRecordSWCanvasScreenshot` hands it `liveHash`); a name-only record past the failure
budget keeps the 32-bit string hash. `_liveCanvasFingerprintNow` is gone:
`_checkPaintTruthfulness` snapshots the canvas twice and compares the two through 32-bit views,
one RGBA pixel per element, answering `truthful`, how many pixels differ and where the first one
is. The failing assertion now ends `— expected: no pixel differs found: 16 pixels differ, the
first at device pixel (3, 3)` where it printed two digests; the audit tick's lines are
unchanged. The UNVERIFIED claim held: nothing outside the harness read `hashRawPixels`. One
consequence was not foreseen here: the self-test's error line was the only emitter of the
gate-token exclusion `SHA256` (`scripts/lib/gate-tokens.js` `NOT_GATED`, whose self-test fails an
entry nothing emits), so that entry went with it, and the suite gate's bite proof now plants its
not-distinctive word with the remaining one, `FIZZYGUM_USE_SWCANVAS`. The evidence: a plant that
changes one test's pixels dumped the same six file names, with byte-identical PNGs, before and
after the change at dpr 1 and 2, each name agreeing with the Node digest of its pixels; the paint
audit's and the suite gate's bite proofs pass; the resolution map moved exactly the four
`AutomatorPlayer` members; the presuite is green with no screenshot moved.

---

## §6. Gate rows run side by side; the tests syntax gate parses in-process

**Effort.** One day. Takes up the BACKLOG line "Every gate re-masks all of the compiled
sources" by another route.

**Evidence.**
- READ: `buildSystem/run-gates.js` runs the 34 rows of `buildSystem/gates.js` in order, each as
  one `spawnSync` of a Node process, the next starting when the last has exited.
- MEASURED: the 33 rows after the first, run exactly that way, took 38.1 s with no `fg`
  operation running (a load of 7 on 16 cores), and 42.9 s while another session's gauntlet ran
  (a load of 13 to 17). Each figure below says which run it is from.
- MEASURED: one row is close to a third of the total: `check-tests-syntax.js`, 11.5 s in the
  quiet run and 13.3 s in the loaded one. READ: it starts one `node --check` process per file,
  two files per test, 778 processes; its own header says "one parse-only node process each
  (~750 files, ~11 s on the real tree)". The next largest row is `check-call-arguments.js`, at
  3.2 s in the quiet run.
- MEASURED: in the loaded run nine rows sit between 0.72 and 0.76 s each and print one line. READ: the BACKLOG
  line explains the floor: masking `src/` takes about 650 ms and twenty gates each mask all of
  it, "about 13 s a build; a mask cache keyed by file content could win it back".
- MEASURED: the first row, the node-tier self-tests, already runs eight files at a time
  (`NODE_POOL` in `run-selftests.js`): 70 files, 165 s of work.
- MEASURED, with nothing else running (2026-11-15, 23:25): `fg build` took 60.3 s, and
  `run-gates.js` run by itself as the build runs it took 58.3 s. The gates are all but two
  seconds of a build. Row by row in a third run (59.8 s): the self-tests row 21.7 s, the other
  33 rows 38.0 s, of which `check-tests-syntax.js` 11.5 s.

**Why it matters.** Every `fg build`, `fg presuite` and `fg gauntlet` pays this, many times a
day. And a cache keyed by file content, the fix on file, adds a thing that can go stale to
gates whose whole job is not to be fooled.

**Fix shape.**
1. `check-tests-syntax.js` reads each file and parses it with `new vm.Script(text, { filename })`
   in its own process. That is the engine's own parser, as `node --check` is. MEASURED: all
   778 files parse that way in 40 ms with no failure, and a stray backtick (the fault the gate
   exists for) is a `SyntaxError` there. It is also the more faithful reading. MEASURED: a file
   holding only `return 1;` passes `node --check` (exit 0), because Node reads a `.js` file as a
   CommonJS module, and fails `new vm.Script`; the browser loads these files as classic
   scripts, where it fails too.
2. `run-gates.js` runs rows through a pool, as `run-selftests.js` does, captures each row's
   output, and prints the rows in table order. At the first failing row it prints that row's
   output and its failure line and prints nothing after it, as today. The self-tests row stays
   first and alone: a broken proof must stop the build before any verdict is read.

With the rows side by side the masking costs about two seconds of wall time and no cache is
needed; the BACKLOG line closes with that note.

**Risk.** The transcript, which `run-gates-selftest.js` pins (order, conditions, the stop, the
exit codes): every one of its cases is re-read against the pool. UNVERIFIED: that no row
writes a file another row reads (the first step lists what each row writes). Rows started
before a failure is known run for nothing; they only read. A row's output arrives when its
turn comes rather than as it is produced.

**First step.** Time the rows again with the command below, on a machine with nothing else
running. List every file each row writes. Then build the pool in scratch and compare its transcript with the sequential one,
byte for byte, on a green tree and on each planted failure of `run-gates-selftest.js`.

**Re-measure.** From `Fizzygum/`:

```
node -e "const {spawnSync}=require('child_process'),p=require('path');const {GATES,BUILD_ARGS}=require('./buildSystem/gates');let t=0;for(const r of GATES.slice(1)){const a=Date.now();spawnSync(process.execPath,[r.script,...(r.args===BUILD_ARGS?[]:r.args)],{stdio:'ignore'});const d=Date.now()-a;t+=d;console.log(d,p.basename(r.script))}console.log('total ms',t)"
```

**Landed 2026-11-16.** `run-gates.js` runs the first row (the self-tests) alone, its output
inherited as before. Every other row whose WHEN holds runs through a pool of eight (the
self-test runner's precedent), its stdout and stderr captured as one stream into a file of one
temporary directory. Each row is reported in table order: its banner as soon as every row before
it has been reported (so a row that hangs is the last banner printed), then, once it has
finished, its captured output and its OK line. At the first failing row the runner prints that
row's output, rings the bell, prints the failure line on stderr, stops the rows still running,
waits for them and exits 1; no row starts once any row has failed. The temporary directory is
removed when the runner exits and when SIGINT or SIGTERM stops it. A failure of the runner itself
stops every started row first and exits 2. `--noSyntaxCheck` and a malformed table behave as
before. No row writes a file another row reads (each row's script and libraries were
read for writes), so the rows' running order is free and only their report is ordered.

`check-tests-syntax.js` parses each file with `new vm.Script` in its own process. Its rule, its
summary line and its exit codes are unchanged, and a failing file is reported as the engine
reports it. It reads each file as a classic script, as the page does, so it now also fails a
top-level `return` (which `node --check` accepted; its self-test plants one), and an `export` or
a top-level `await` (which `node --check` read as a module). None of the 778 test files has
any of the three.

Two things a developer sees are different:
- a pooled row's stderr text arrives on the runner's stdout, in its place in that row's output;
- a pooled row no longer writes to a terminal.

The evidence:
- with the old and the new runner on one tree, the merged transcripts are identical, timings
  masked;
- `run-gates-selftest.js` (34 cases) proves the new facts on a table of its own and on real
  processes under a planted copy of the runner; a planted pool of one fails it, and so does a
  planted no-op stop;
- under `--noSyntaxCheck` both runners print nothing, exit 0;
- timings, three runs each, on a busier machine afterwards:

  | | before | after |
  |---|---|---|
  | `run-gates.js` as the build runs it | 58.2, 59.8, 60.1 s (load 27 to 31) | 25.9, 27.5, 28.6 s (load 53 to 64) |
  | `fg build` | 61.8, 62.0, 66.7 s | 30.8, 30.9, 36.0 s |

The BACKLOG line on re-masking closes with these numbers; no cache was built.

---

## §7. Text cache keys are the text

**Effort.** One day, half of it the speed measurement. Takes up the BACKLOG line "The text
caches key on a 32-bit `hashOfString` with no check that the text matches" (filed under
`plans/runtime-performance-optimization-plan.md` by round 3's loop).

**Ruled 2026-11-15 (owner, on this survey's recommendation).** It lands only if no measured
case is slower than the spread of an A/A run. If the joined key is slower, the two-level
shape under "Risk" is measured the same way. If that is slower too, the item is parked with
the numbers: a speed trade is the owner's, as it was for round 3's §2.

**Evidence.**
- MEASURED: seven cache keys in `StringWdgt` and `TextWdgt` hold `hashOfString(text)`, a 32-bit
  hash, where the text belongs (eight uses; the widest key holds two). Two of the seven,
  `TextWdgt.getParagraphs` and `getWordsOfParagraph`, use the hash as the WHOLE key.
- MEASURED: "Of" and "PG" hash alike under it (79·31 + 102 = 80·31 + 71 = 2551). The BACKLOG
  line records the consequence as reproduced: at one font and extent the two share an entry,
  and the second label draws the first's text. Medium, reached by typing.
- READ: `hashOfString` (`src/boot/globalFunctions.coffee`) keeps a memo, a `Map` keyed by the
  text itself, capped at 16,384 entries and at texts of 2,048 characters. Its comment gives the
  reason: the cache keys are rebuilt on every paint, and hashing them cost 1.5 to 5.4% of a
  busy frame. A porthole (`stringHashCacheForAudit`) and a policy row in `WorldInventory` exist
  to account for that memo.
- READ: since round 3's §2 each of the seven caches is a `Map` (`LRUCache`), which keys on a
  string by its value.

So a lookup today is: look the text up in one `Map` to get a weaker hash of it, join that into
a key, look the key up in another `Map`. The engine has already hashed the whole text for the
first lookup. The 32-bit number adds only the collision.

**Audited 2026-11-15 (at the owner's request): is any key missing a property its answer
depends on?** The seven caches are filled through nine key constructions: the seven above, a
font-box key in `StringWdgt.fontBoxAscentAndDescentOf` and `PaletteWdgt`'s key in the shared
buffer cache. For each, READ: every field and every global the cached computation reads,
against the key.
- **One gap, MEASURED by a probe** (`Fizzygum-tests/.scratch/cleanups-loop-4/key-audit-probe.js`,
  its output beside it). `TextWdgt.breakTextIntoLines` builds its key from the fit-check
  extent its CALLER passed. A text that sizes its box to its text (`FIT_BOX_TO_TEXT`: a
  `SimpleTextWdgt`, so every document paragraph) then ignores that extent and answers the
  wrapped lines, while a text fitted to its box (a plain `TextWdgt`) answers only true or
  false. The key does not say which kind asked. Two such texts with the same text, font and
  box share the entry: asked second, the paragraph's layout gets `true` where it reads lines,
  and `preferredExtentForWidth` throws ("Cannot read properties of undefined (reading
  'length')"); asked first, the plain text is handed the lines and takes them for "it fits".
  A different box, and each gets its own answer. The inner key (`getTextWrappingData`)
  applies the mode before it is built and has no such gap. Reach: both kinds of text, equal
  in text, font size and box, laid out within ten lookups of each other (the cache holds
  ten). Not seen in the suite.
- **Every other key holds what its answer reads.** The label's buffer key is listed under
  "Fix shape"; measuring reads the font and the text; a paragraph's wrap the font, the width
  and the paragraph; the whole text's wrap those plus the fit-check extent and the line box;
  the two splits the text alone; the font box the font alone. `FizzytilesCodeWdgt`, the one
  subclass that paints more (a border, an inset), extends the key with both.
- **Read and found sound, though not in any key:** the device pixel ratio, the browser's
  minimum font height and the theme object are fixed for a page's life; whether the glyph
  atlas has arrived is handled by evicting the entries painted before it did
  (`WorldWdgt.noteColdGlyphRegionsWarm`); code is handled by dropping every cache on a class
  edit (`noteCodeChanged`) and by the own-code suffix.
- **Two things a later change could trip on, neither a fault today.** A text's buffer key does
  not name its class (`PaletteWdgt`'s does), which is sound only while no subclass changes the
  paint without extending the key. And the own-code suffix is itself a 32-bit hash of the
  code a widget holds of its own: two different pieces of such code can collide as two texts
  do; only widgets a person has given code of their own are exposed, and this item leaves it.

**Why it matters.** It is a wrong-text bug a user reaches by typing, and the mechanism that
causes it is extra work, not saved work.

**Fix shape.** Only the hash part of each key changes: where a key holds
`hashOfString(text)`, it holds the text. Everything else a key is built from stays as it is.
READ: the label's back-buffer key (`StringWdgt.createBufferCacheKey`) is built from the
extent, the password and display-case settings, the font (weight, italic, size, family), the
header-line flag, the text ink, the background fill and its transparency, the two texts, the
selection's two marks and two colours, the horizontal and vertical alignment, the four
fitting settings, the line height, the item shape and the widget's own code; `TextWdgt` adds
its soft-wrap setting; the measuring and wrapping keys are built from the font, the width,
the text and the line box. `getParagraphs` and `getWordsOfParagraph` key on the text alone,
correctly, since a split depends on nothing else. In a composite key each text is written as
its length, a colon, then the text, so that nothing written after it can be read as part of
it (`TextWdgt` appends to `StringWdgt`'s key, so a text is not always last). The gap the
audit found is closed in the same line this item rewrites: `breakTextIntoLines` applies the
mode's override to the fit-check extent BEFORE it builds its key, as `getTextWrappingData`
does, so a text that sizes its box and a text fitted to its box never share an entry. Then,
if its remaining callers are cold, `hashOfString`'s memo, the porthole and
the inventory row go. UNVERIFIED: the remaining callers are `PanelWdgt`'s scatter (two),
`Widget`'s own-code key suffix (one), `StringWdgt`'s "modified since the reference text" pair
(which can compare the texts) and the harness's `HashCalculator`.

**Risk.** Speed, on the hottest path in text painting. UNVERIFIED, and it can go either way: a
joined key is a new string at every lookup, so the engine hashes it afresh, where the memo
answers a repeated text in one lookup; against that, a text over 2,048 characters is hashed in
a JavaScript loop at every lookup today and would be hashed natively. Measure as round 3's §2
did (§13): the real methods, on two builds, runs alternating, on each cache's own mix from the
suite. If a short-text mix is slower, the fallback is two levels (text, then the fixed
fields), which keeps the exact match. Memory: the keys now hold texts; the caches hold 10 to
1,000 entries each.

Pixels: none expected. A reference that changes would be a collision that was being drawn
wrong, and is a finding to show the owner, never a recapture to make the change pass.

**First step.** Reproduce the "Of"/"PG" collision in a scratch probe on the harness page (two
labels, one font, one extent) so the fix has a failing case to turn. Then the measurement,
before any key changes.

**Re-measure.**
`grep -rn 'hashOfString' Fizzygum/src --include='*.coffee' | grep -v ':\s*#' | wc -l` (17).

**OWNER DECISION (raised 2026-11-16 by the loop; RULED the same day by the owner: (a), and landed).** The loop built the change as ruled and
measured it, and it is slower, so it parked: the patch is
`Fizzygum-tests/.scratch/cleanups-loop-4/u2-text-keys/PARKED-Fizzygum.patch`, its evidence beside it.
- What the patch does, proven: every key holds its text (a composite key as `length:text`). The
  "Of"/"PG" collision is gone from all four caches it reaches: the paragraph split, the word split,
  measuring ("PG" measured 12 wide instead of 17) and the label's back buffer (two labels shared
  one). The line-break key gains its fitting mode (the probe's thrown layout is gone). And
  `hashOfString`'s memo, porthole and inventory row are deleted: after the change its only callers
  (1,745 calls a suite: a text's edit check, the bin's scatter, own-code edits) are on no paint or
  layout path. Hash values are unchanged.
- What a person would see: nothing, in normal use. With the patch, two labels whose texts collide
  (typed "Of" and "PG" into two cells of one width) each show their own text; today the second
  shows the first's.
- The measurement: the real methods, HEAD's build against the patch's, three runs each,
  alternating, blocks of at least 40,000 calls, on a replay of 98 tests' lookups. It was run twice,
  after an A/A run between two builds of HEAD read every case the same (spreads 0.3% to 9.3%). Per
  call:
  - slower: top-level line breaking 1,260 → 1,618 ns (+28%), back buffers 1,184 → 1,421 ns (+20%),
    paragraph wrapping +9%, whole-text wrapping +7%;
  - within the A/A spread: paragraph splits +8% (its spread 9.3%), measuring;
  - faster: word splits, a short label (1%), and a text of 3,000 characters (line breaking
    13.3 → 4.3 µs, its buffer key 26.9 → 9.1 µs, its paragraph split 13.2 µs → 25 ns).

  Weighted by one suite's lookups (1.30 M back-buffer keys, 0.56 M measures, 0.39 M line breaks),
  that is about +0.57 s of CPU over a whole suite run, about 0.07% of its ~800 shard-seconds.
- The two-level shape (the text, then the fixed fields) was not built, because it cannot reach the
  largest regression. The back-buffer cache is shared with `PaletteWdgt`'s flat keys, and the
  SWCanvas cold-glyph recorder (`SWCanvasElement-extensions.coffee`) wraps its `get`/`set` and
  evicts poisoned entries by their flat key string. A two-level buffer cache would change that
  protocol, a mechanism neither plan names, so the case with 1.3 M lookups a suite has no shape this
  item may build.
- Options:
  - (a) land the patch as measured;
  - (b) keep the hashes and check the text on a hit (each entry keeps its text, and a mismatch is a
    miss): exact, keys stay short, every hit compares texts; unmeasured;
  - (c) give each text a unique number from a counter instead of its hash, keeping the keys'
    shape: today's speed, but the memo stays as an intern table; unmeasured;
  - (d) land only the line-break key's fitting mode now (a correctness fix with no speed cost),
    leaving the collision filed.
- Recommendation: (a). The cost is a fraction of a microsecond per text painted, about 0.07% of a
  suite's CPU. Long texts get three times faster, a wrong text a person can type is gone, and one
  mechanism (the memo and its accounting) is deleted. If "not slower" stands, (d) now and (b) or
  (c) measured later.

**Landed 2026-11-16 (the owner's ruling (a), after the loop).** The parked patch, unchanged, on the tree as the
loop left it (it applied cleanly: none of the units after it touched these files). Re-proven there: the collision
probe and the key-audit probe print exactly what they printed on the proven after-run (four own answers; both
orders of the two kinds of text right, `preferredExtentForWidth` no longer throwing); `fg build` (the complexity
record 130 → 129 holds) and `fg gauntlet` pass. The runtime-performance plan's BACKLOG line on the collision closes
with it (this file's ledger).

---

## §8. Audit preludes share one head

**Effort.** One day.

**Evidence.**
- MEASURED: `./find_duplicated_code.sh --tests` finds 46 exact clones (388 lines) in the tests
  repo's tooling. Seventeen of them (170 lines) are between the files that are injected into
  the test page as audit instruments and their planted faults: 13 files across
  `scripts/audit-preludes/`, `tier-naming-audit/`, `notification-settle-audit/` and
  `end-of-cycle-audit/`. (Those four directories hold 17 such files; the preludes alone are
  1,735 lines.)
- READ: what is copied: the findings buffer (`finding`, `flushFindings`), `ownMethod` (a
  class's own prototype function, read without running an accessor), the test-boundary marker
  (`noteTestBoundary`, which prints `LAYOUTAUDIT_TESTSTART`), and in the plants a `playing()`
  test and an install-and-retry loop.
- READ: the boundary marker has a recorded fault behind it (`Fizzygum-tests/CLAUDE.md`: what
  "keeps an audit prelude's test-boundary marking from filing the boot's layout passes under
  some test"). A correction to one copy does not reach the others.
- READ: an instrument is handed to the runner as ONE file (`--audit-prelude=FILE`). The six
  gates that do so share one driver, `scripts/lib/audited-suite.js`, and the self-test tier
  already joins a prelude and a plant into one file before a run
  (`notification-settle-audit/cache-oracle-selftest-headless.js`, its `settle-plus-plant.js`).

**Why it matters.** These files decide what six gauntlet legs see. They are the one family of
tooling where the duplication scanner still finds the same helper written many times.

**Fix shape.** One file holds the shared helpers. `lib/audited-suite.js` joins it in front of
the instrument and passes the result, as the self-test tier does. Each prelude and plant loses
its copies. Whether the four directories then become one is a separate, optional `git mv`.

**Risk.** An instrument that sees something different. The proofs exist: each gate's bite
proof plants every one of its rules (the `selftests` leg), `preludes-install-selftest-headless.js`
installs every prelude through the real runner, and one full run of each gate must leave its
buckets byte-identical before and after.

**First step.** List the 17 clone pairs with the helper each one is, and confirm that the
copies are equal in meaning and not only in text (two with the same name and different bodies
would be the real finding).

**Re-measure.** `./find_duplicated_code.sh --tests` from `Fizzygum/`, then count the pairs in
`duplication-report/tests/jscpd-report.json` whose two files both sit under the four
directories.

**Landed 2026-11-16.** One page script, `scripts/audit-preludes/audit-head.js` (the head),
holds the helpers that meant the same thing in every copy: the test-boundary READ AND PRINT
(`testStarted`), the held install-time findings (`findingsBuffer`), `ownMethod`, a plant's
`playing()` and its install-and-retry loop (`applyPlant`). It defines one non-enumerable page
global, `window.__auditHead`, once a page, and prints nothing of its own. Eight preludes and
eight plants call it. Each of the eight test-boundary callers keeps its own seam (a world reset,
a layout flush or a paint), its own last-name variable and its own follow-ups, because the seam
decides which bucket a line lands in. Each instrument and plant that uses the head opens with
one guard: injected without it, it says `AUDIT_HEAD_MISSING` and installs nothing.

The join is ONE function, `joined` in `scripts/lib/audit-head.js`, lifted from the cache-oracle
proof's own join. Its callers:
- `lib/audited-suite.js` (the six audited gates);
- `preludes-install-selftest-headless.js`, which also proves the missing-head line fails a run;
- the cache-oracle proof;
- `lib/gate-bite-proof.js` `fileText`, which every leg proof reads its plant files through;
- a command line that the two person-run shells and the usage lines use.

The single-test and sequence runners take one `--prelude=`, so the join is in every caller, not
only in `audited-suite.js`; no runner gained a rail or a flag. Not moved, though equal in their
copies: `attachedClock`, `hook`, the READS check, the class enumerations, the install guards and
`poll`. Not merged, because they differ: tier-naming's console.log findings, storage's per-call
findings, the double-wrap markers.

The evidence:
- each gate's buckets before and after: settle, capstone, revisit and storage byte-identical;
- tier-naming byte-identical across four alternating runs of HEAD's scripts and the change's
  (its baseline and its first after-run each differed in one first-test bucket, a boot race
  that also varies between runs of HEAD's own scripts);
- vm-truth OK with no finding;
- the clone pairs between instrument files 17 → 14 (170 → 120 lines), none of them a moved
  helper;
- the install self-test and the audited-suite self-test pass.

The vm-truth gate's baseline run read INVALID by its pin cap, which is older than this round's
first unit: filed in `docs/BACKLOG.md` under the object-lifetime program.

---

## §9. Every profile is built by something, or it goes

**Owner decision first:** which profiles are products.

**Left for a later day by the owner (2026-11-15).** Not queued; it stays on `docs/BACKLOG.md`.

**Effort.** One to one and a half days.

**Evidence.**
- MEASURED: `buildSystem/profiles/` holds five profiles. `fg build`, `fg presuite` and
  `fg gauntlet` build `dev`. `fg homepage` builds `homepage`. No verb, no leg, no gate row and
  no npm script names `lean`, `dev-notests` or `dev-precompiled` (a grep over `fg`'s modules,
  `legs.js`, `gates.js`, `build_and_smoke.sh`, the tests repo's scripts and its
  `package.json`). `fg fingerprint <profile>` builds one when a person types its name.
- READ: `Fizzygum-tests/CLAUDE.md` on the boot smoke's `--lean` mode: "No `fg` verb drives it —
  it is the hand-typed check that the appliance still stands up."
- READ: `docs/architecture/build-and-packaging.md`: `homepage` and `lean` emit a byte-identical
  pre-compiled image; `lean` differs in shipping no class source text and no lazy part, and so
  in what it must say when a loaded file carries a class edit. That difference is what
  `--lean` asserts and what nothing runs.
- MEASURED: all five built on 2026-11-15 (round 3's §3 compared every profile's tree), and
  that evening `./build_and_smoke.sh --profile <name>` passed for each of the three by hand:
  `lean` in 53.3 s, `dev-notests` in 55.3 s, `dev-precompiled` in 72.9 s (build and boot smoke
  together). Nothing is broken today. Nothing would say so if one broke tomorrow.
- READ: the precedent is round 1's §3: a part no gate ran had five open defects when it was
  finally looked at.

**Why it matters.** `lean` is described as a product ("the appliance artifact"). A product
whose only check is typed by hand has the reliability of whoever last remembered.

**Fix shape, for the owner to choose per profile.**
- `lean`: `fg homepage` also builds it and runs the smoke's `--lean` mode. MEASURED: that is
  about 53 s more.
- `dev-notests` (dev without the harness part): delete it unless someone uses it; the profile
  mechanism's "no harness" derivations are already exercised by `homepage`.
- `dev-precompiled` (dev booting from an image, for a person at `index.html`): keep it only if
  the owner opens it; if kept, an on-demand `fg profiles` builds and boot-smokes every profile
  file it finds by name, never from a list.

**Risk.** A longer `fg homepage`. A deleted profile is one JSON file, its paragraphs in the
instruction files and the packaging document, and whatever in `lib/profile.js` only that
profile's combination reached, which must go with it and not stay as dead derivation.

**First step.** Ask the owner which of the three are products.

**Re-measure.** For each profile name, a grep for `--profile <name>` and the quoted name over
`Fizzygum/buildSystem/fg-*.js`, `legs.js`, `gates.js`, `Fizzygum/build_and_smoke.sh`,
`Fizzygum-tests/scripts/*.js` and `Fizzygum-tests/package.json`.

---

## §10. The build is one Node program

**A re-listing.** Round 2's §11 measured `build_it_please.sh` (665 lines then) and did not list
it: "What remains after the gate table is sequencing, the tests link and the boot bundle's
assembly. Not a second language for one fact any more." This section lists it with what has
changed since and what that round did not measure. The owner may decline it again, and the
evidence then stands as a record.

**Ruled 2026-11-15 (owner, on this survey's recommendation).** Approved. It has a plan of its
own, `docs/archive/build-node-port-plan.md`: the inventory of the script, what must stay equal,
the six differences allowed and ten proofs in order. It lands and is pushed when every one of
those proofs passes, and it is never landed partly proven.

**Effort.** Two to three days.

**Evidence.**
- MEASURED: `build_it_please.sh` is 669 lines: 260 of bash, 340 of comment. Since round 3's
  §10 it is the only shell program on the path to a commit: `fg` is Node, the gates are a table
  a Node runner executes, and the assembly is `build.js`.
- MEASURED, the bridges it needs:
  - `buildSystem/lib/profile.js --shell` prints bash assignments, two of them arrays, quoted by
    a `shellQuote` written for the purpose, for the script to `eval`. `build_and_smoke.sh`
    evals the same text, and since the port the Node `fg` reads it too (§2).
  - `buildSystem/lib/build-inputs.js` keeps `SHELL_INPUTS`, a hand list of "the files
    build_it_please.sh reads by name"; its own comment says that a name that no longer exists
    "is skipped, and that input goes unwatched".
  - `buildSystem/lib/what-runs.js` carries a shell lexer (115 code lines: quoting,
    substitutions, heredocs, interpreter words) whose first job is to read this script and
    `build_and_smoke.sh`.
- MEASURED, inside the script: four `sed -i ''` lines in the macOS spelling (§3 removes them),
  13 `rm` lines of which nine act on an unquoted path variable, 44 `build_failed` exits, and
  seven launches of `node` beside the compiler's and the minifier's.
- MEASURED: `build_and_smoke.sh` (36 code lines) turns the profile into the boot smoke's four
  flags by an if/elif chain. A person who runs the smoke directly on a non-dev tree must
  repeat that mapping by hand (`Fizzygum-tests/CLAUDE.md` says so).
- READ: `fg` launches `./build_it_please.sh` at three places, and
  `buildSystem/fg-gauntlet-selftest-headless.js` stands in for it with a `#!/bin/sh` file.
- READ: the proof instrument exists. `fg fingerprint <profile> <baseref>` builds a profile at
  two refs and diffs the trees, and round 3's §3 used it on all five profiles.

**Why it matters.** One fact (the profile, the list of inputs) is stated in JavaScript and then
re-stated in a second language for one reader. A build written in the language of its own
library can require the profile and record each input as it reads it.

**Fix shape.** A Node module under `buildSystem/` does the sequencing. `build_it_please.sh`
stays as a launcher of a few lines, as `Fizzygum/fg` did, so the documented command and every
caller keep working. The comments move with the code they explain (the project values them;
round 1 said so of the gate blocks). The profile is asked in-process and `--shell` goes with
`shellQuote`. The files the build reads by name are named once, by the module, and
`SHELL_INPUTS` goes. `build_and_smoke.sh` becomes a launcher too, and its mapping from the
profile to the boot smoke's flag is computed in Node. (This survey's first draft went
further and gave the smoke a `--profile` flag in place of its four. That was wrong: the
smoke's bite proof uses the four flags to read one dev tree as each other kind of tree, so
they stay. The port's plan records it under its rejected alternatives.)

What stays shell: the watcher one-liner, the two code scanners, the two vendoring scripts, two
profiling scripts and two audit loops. They are on-demand tools (the subject of round 3's §7),
so the lexer in `what-runs.js` stays for them until that item is decided.

**Risk.** It is the build. The acceptance is: for each of the five profiles,
`fg fingerprint <profile>` against the commit before reports no difference; the build's
transcript on a green tree is compared line for line; and each of the 44 failure exits is
shown to stop the build with today's message and code (a planted failure per exit, in
scratch; where an exit cannot be reached by a plant, the plan says so and why). It is never
landed partly proven, and until it lands the script in git is the build.

**First step.** The port plan's proofs P1 to P3: the inventory re-derived from the script as it
stands, every reader of it in both repos, and the baseline of all five profiles on the
untouched tree.

**Re-measure.**
`grep -v '^\s*#' Fizzygum/build_it_please.sh | grep -vc '^\s*$'` (260) and
`git -C Fizzygum ls-files | grep -c '\.sh$'` (9).

**Landed 2026-11-16 (every proof of the port's plan passed).** `build_it_please.sh` is a launcher
(seven lines of bash: it moves to `Fizzygum/`, checks for `node`, runs `buildSystem/run-build.js`);
the build's sequencing is that module, the script's 28 steps in 19 functions, the script's comments
above the step each explains. It LAUNCHES what the script launched — the compiler, the minifier, `node`, `git`, and
the file utilities `rm`, `mkdir`, `cp`, `ln`, `mv`, `touch`, `cat` and `tput` — with the script's
arguments, so a failing step says what it said; only the text work is JavaScript. A Ctrl-C is the
running program's to answer, as it was under the shell: one that handles it and exits is a step that
failed (exit 1), one that dies of it ends the build by the same signal. `build_and_smoke.sh`
launches `buildSystem/run-build-and-smoke.js`. The port plan's six differences hold: the profile is
asked in-process (`lib/profile.js` `profileForBuild`, which the build, build_and_smoke and `fg`'s suite
tiers ask; `--shell`, `shellQuote` and the command-line half of `profile.js` are gone); the files the
build reads by name are named once (`run-build.js` `READS_BY_NAME`, which `lib/build-inputs.js`
requires: `SHELL_INPUTS` is gone); the `node` check is the launchers'; build_and_smoke's flag is
computed in Node (`smokeFor`); the cleaner refuses a tree that is not `../Fizzygum-builds/latest` and
a recursive removal spelled with a trailing slash; the stamp is still made by `touch -r`. Two changes
the readings needed: `lib/what-runs.js` reads the gate table when ANY reached file launches
`run-gates.js` (it read it only when the script's own text did: the old reading of the ported tree
loses 70 files, every gate and its libraries), and `writeAll` moves to `lib/write-all.js` (re-exported
by `lib/gate-rules.js`, which loads acorn: the build writes before it can say acorn is missing), which
`finishCommandLine` now writes through (a pipe's `process.stderr.write` is not synchronous on macOS).
`run-build-selftest.js` (node tier, 18 cases, about 6 s) holds the green paths, one exit of each kind,
the cleaner's refusals and build_and_smoke's flag for each profile.

The evidence (the loop's ledger has the rest):
- P1: 28 steps and 54 exits (40 `build_failed` sites, not 44: §3 removed four); P2: every reader in
  both repos;
- P4, on a planted `Fizzygum-all` with stand-in programs and file utilities failing on demand: 92
  scenarios (every profile green, every reachable exit, three unchecked steps, a build killed and the
  next one, four Ctrl-C drills, `build_and_smoke.sh`), each run twice per side: 89 byte-identical in
  stdout, stderr, their merge, the exit code and every file left; the other three differ only in a
  diagnostic of the shell's own (a boot bundle that cannot be appended to, the tests repo gone before
  the pre-compile driver's `cd`, `build_and_smoke.sh` without `node`), which carries a line number of
  the script, `./build_it_please.sh: line 408: …`, that no other program can print;
- P5 on scratch: the suite behind the tests link untouched by every clean, a top-level dot file in
  `font-assets/` never copied, the stamp at the start marker's time, the cleaner's refusals;
- P6: `fg fingerprint <profile> HEAD` for all five profiles, no difference; the transcripts against
  the bash build's: stderr identical, stdout and the merge differing in the same seven lines for every
  profile, each the port's own (one more self-test; one more stated not-a-gate file, the two new
  modules launched and `lib/profile.js` no longer; four more scanned files); the record of the inputs differing only in the files the port changed and `run-build.js`;
- P7: the run set loses nothing, every file runs as before but `lib/profile.js` (launched → required);
- P8: `./build_and_smoke.sh` for each profile, `fg build`, `fg presuite`, `fg gauntlet`, `fg homepage`;
- P9: the new self-test, and `fg-gauntlet-selftest-headless.js` (its stand-in build script unedited;
  its stand-in profile reader answers `profileForBuild`, the one call `fg` makes now),
  `lib/what-runs-selftest.js` (two new cases: a gate runner launched by a JavaScript sequencing has its
  table read, one only required has none), `run-selftests-selftest.js`, `lib/build-inputs-selftest.js`;
- P10: a touched `run-build.js` reads STALE in `fg status` and to a runner, FRESH after a build; a
  build killed after its start marker leaves what the bash build left, and the next build does the
  same.

Re-measured: seven lines of bash in `build_it_please.sh` (254 before); nine tracked `.sh` files.

---

## 11. Measured and deliberately not listed

- **The source's own ratchets.** Every stink at its baseline; the hierarchy census at 0 and 0;
  11 dead methods, each allowlisted or exempt; zero unresolved sends; zero argument holes over
  51,363 calls. Exact duplication is 0.52% of `src/`'s lines (33 clones, 395 lines), and the
  largest (`WidgetFactory`'s six internal pairs, the three example plots) are recorded as
  leave-alone in the duplication triage. A probe of all 537 classes found one that no other
  code names: `LCLProgramRunner`, which a comment in its neighbour `LCLCodeCompiler` already
  calls dead code and the LiveCodeLang plan owns (§12). A probe of the 56 boot-level functions
  found none that nothing calls.
- **The 64 `instanceof` tests.** The tail of a finished campaign: value classes (`Point`), the
  widget root, exception classes.
- **The eight `_reLayout` prologue copies.** Each is a recorded exception
  (`census-widget-conformance.js`, over its baseline).
- **The `selftests` leg.** 2,100 s of work in 25 files, the gauntlet's longest leg. Much of it
  is waiting out a world that never starts (90 s each, one constant with deliberately no flag
  to shorten it). Its alarm was raised from 600 s to 900 s the same evening (`5e12b629`), after
  it ran past the old one in a loaded wave and passed alone.
- **The font copy.** A dev build copies 4,554 font files (90 MB) in 1.0 s. A link would save
  both, and would be a second link from the build tree into a source tree, with the hazard the
  tests link already carries.
- **The macro invocation rewriter.** Three regular-expression passes turn `fooMacro args` into
  a `yield from`, at 2,029 places in the tests. It is the test language, with a gate on its one
  trap.
- **The two largest plans.** `affine-transforms-plan.md` (260,733 bytes, four open items) and
  `dataflow-engine-implementation-plan.md` (181,134 bytes, one). Splitting off the landed story
  would fight the owner's rule that a plan can be executed cold from itself.
- **The instruction files.** Both `CLAUDE.md` files sit exactly at their byte ceilings (35,320
  and 67,015). Round 2's §9 applied its criterion sentence by sentence; a second pass was not
  attempted.
- **The local scratch.** `Fizzygum-tests/.scratch` is 11 GB in 1,214 entries, and
  `scripts/.scratch` holds one 930 MB log from 2026-11-06. Ignored by git, on the owner's
  machine, and holding every loop's ledger: the owner's to prune.
- **`serialization-roundtrip-headless.js`** (5,262 lines) and **the flat top level of `src/`**
  (101 class files). Same verdict as all three earlier surveys.

## 12. Already owned elsewhere (not listed again)

| Topic | Owner |
|---|---|
| Icon shells: one `IconWdgt` and a derived catalog | `archive/top-10-cleanups-plan.md` §9 (kept open by the owner) |
| The reference set: live path axes, one file per reference | `archive/top-10-cleanups-round-2-plan.md` §10 (left out for now by the owner) |
| The experimental patch-programming part; the on-demand tools roster; a test is one file | `archive/top-10-cleanups-round-3-plan.md` §4, §7, §9 (left for a later day by the owner) |
| The creator-button and toolbar-button classes | `plans/creation-and-templates-plan.md` §4.3 |
| Two icon-appearance generations and pixel icons | `plans/pixel-icons-plan.md` |
| LiveCodeLang, its five allowlisted dead methods and the unreferenced `LCLProgramRunner` | `plans/livecodelang-cleanup-and-extensions-plan.md` |
| The similar-code mirror nobody runs | BACKLOG, under `archive/argument-holes-both-repos-plan.md` |
| Classes still evaluated in sloppy mode | BACKLOG one-liner (`archive/mixin-removal-plan.md`) |
| A hook override that skips `super`; a must-call-super rule | BACKLOG, two lines |
| Context-menu construction inside `Widget` | BACKLOG one-liner, `archive/god-class-decomposition-plan.md` Tier 3 |

## 13. Case law that bounds these items (do not re-attempt blind)

- **A fair speed comparison is the real methods on two builds, runs alternating**, on the mix
  the suite really produces. A freshly evaluated copy timed against the live method is biased
  by the engine's inline caches (round 1's §6 and round 3's §2, "Landed"). §7 measures that
  way; §6 times on an idle machine.
- **A filed item is a hypothesis.** §7's collision is confirmed here by arithmetic and recorded
  as reproduced by round 3's review; its first step reproduces it again before anything
  changes.
- **Text-level exclusion is retired, and no replacement is to be invented**
  (`Fizzygum/CLAUDE.md`). §3 removes the last instance; it adds nothing in its place.
- **A gate that was changed is a gate that may have stopped biting.** Every gate's every rule
  is planted by a self-test (`docs/architecture/lint-and-static-checks.md` §3). §5, §6 and §8
  are done when those proofs pass unchanged, and §6 re-reads `run-gates-selftest.js` case by
  case.
- **`fg` is read, never executed, by the tools that reason about it** (`lib/what-runs.js`), and
  the build script is one of that reading's roots. §2 and §10 keep both readable by it.
- **A port is never landed partly proven** (`docs/archive/fg-node-port-plan.md` §8). §10
  follows it.
- **The port's equality rule ended with the port.** `fg`'s usage text was held byte-identical
  to the bash program's only as the proof of round 3's §10. §2 changes it on purpose.
- **Round 2 measured the build script and left it.** §10 says what changed; it does not argue
  that round 2 was wrong.
- **"Tooling may vendor", and "pins the tools through npm".** Both are the owner's. §4 asks
  which holds for a parser and an analyzer; it does not choose.
- **A plan is executable cold from itself.** §1 moves whole files and splits none.
- **A reference is never recaptured to make a change pass.** Every item here expects zero
  pixel changes; a difference is a finding about the change (`Fizzygum-tests/DETERMINISM.md`).
- **A running long operation owns its inputs.** This survey was measured while another
  session ran a gauntlet, so it edited no source and ran no build; each item's first step
  starts from `fg status`.

## 14. Shared verification protocol

Invoke the wrapper by absolute path; never pipe a gating call through a filter; one long
operation at a time.

```
/Users/davidedellacasa/code/Fizzygum-all/fg status      # orient: heads, dirty counts, build freshness, verdicts
/Users/davidedellacasa/code/Fizzygum-all/fg build       # every static gate and every gate's bite proof (§4, §6)
/Users/davidedellacasa/code/Fizzygum-all/fg presuite    # inner loop: build, dpr-1 suite, paint audit, fracplane rider
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet    # commit point: 20 legs, run in the background, log to a file
/Users/davidedellacasa/code/Fizzygum-all/fg homepage    # production profile boot and snapshot round-trip (§3, §9, §10)
/Users/davidedellacasa/code/Fizzygum-all/fg fingerprint # build-tree diff against a baseline ref (§3, §10)
/Users/davidedellacasa/code/Fizzygum-all/fg critique    # the advisory censuses and every ratchet
```

§1 is verified by `fg doc-narration` and a grep. §5 and §8 rely on the gauntlet's `selftests`,
`refs` and `paint` legs as much as on its suites.

## 15. References

- `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, `Fizzygum-tests/DETERMINISM.md`
- `docs/README.md` (filing rules; §1), `docs/BACKLOG.md`, `docs/archive/INDEX.md`
- `docs/archive/top-10-cleanups-plan.md`, `docs/archive/top-10-cleanups-round-2-plan.md`,
  `docs/archive/top-10-cleanups-round-3-plan.md` (the three earlier surveys; their "Landed"
  paragraphs are the precedents cited above)
- `docs/archive/fg-node-port-plan.md` (the port's rules; §2, §10)
- `docs/archive/build-node-port-plan.md` (§10's own plan)
- `docs/architecture/lint-and-static-checks.md` (the gate index and the bite-proof rule; §6)
- `docs/architecture/build-and-packaging.md` (parts and profiles; §3, §9, §10)
- `docs/tooling/duplicated-code-detection.md` (the scanner; §8, §11)
- `buildSystem/gates.js`, `buildSystem/run-gates.js`, `buildSystem/run-selftests.js` (§6)
- `buildSystem/fg-verbs.js`, `buildSystem/fg-commit-point.js`, `buildSystem/lib/profile.js`,
  `buildSystem/lib/build-inputs.js`, `buildSystem/lib/what-runs.js` (§2, §10)
- `Fizzygum-tests/scripts/lib/audited-suite.js` (§8)

## 16. Start prompt for a fresh session

```
Read Fizzygum/docs/archive/top-10-cleanups-round-4-plan.md in full (a survey of ten candidate
cleanups, ordered by effort). Then run /Users/davidedellacasa/code/Fizzygum-all/fg status and
confirm no long operation is running and both repos are clean.

I want to take up item §<N>. Do this, in order:
1. Run the item's "Re-measure" command and tell me whether the numbers still match the plan.
2. Read the code the item cites and tell me anything that contradicts its evidence or its
   fix shape. Treat every statement marked UNVERIFIED as a question to answer first.
3. If the item is marked "owner decision first", stop there and lay out the options.
4. Otherwise carry out the item's "First step" exactly as stated, show me what it found,
   and wait for my go-ahead before the change itself. Verify with the plan's §14 protocol.
Do not commit or push without asking me.
```

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] §5 (½ to 1 day): one SHA-256 in the harness — the hand-written one (89 code lines) re-hashes pixels the browser's digest already answered; its two callers take the digest or compare bytes
  — CLOSED 2026-11-16 (loop U1): the page has one digest, the browser's; a recorded screenshot is named by the digest
  its comparison already took, and the paint audit compares pixels (§5, "Landed").

- [x] §8 (1 day): audit preludes share one head — 17 copied blocks (170 lines) across 13 page-injected instrument files; `lib/audited-suite.js` joins the shared head to each
  — CLOSED 2026-11-16 (loop U3): the helpers equal in meaning live in `scripts/audit-preludes/audit-head.js`, joined in
  front of every instrument and plant that uses them by `scripts/lib/audit-head.js` (§8, "Landed").

- [x] §4 (½ day; ruled: npm): build-time libraries from one place — acorn and the complexity analyzer are vendored, the other tools npm-pinned; the analyzer exists twice, byte for byte
  — CLOSED 2026-11-16 (loop U4): both are exact npm devDependencies, checked by the build, and `vendor/` holds neither
  (§4, "Landed").

- [x] §3 (½ day; ruled: they go if no production artifact grows by more than 2 KB): the build's last text-level strip — four `sed` lines turn six compiled `Automator?` tests into `if (false)`
  — CLOSED 2026-11-16 (loop U5): the lines are gone; `homepage` and `lean` each grow by 1,044 bytes, the six guarded
  branches and nothing else (§3, "Landed").

- [x] §6 (1 day): gate rows run side by side, and the tests syntax gate parses in-process — the gates are 58 s of a 60 s build, 11.5 s of it 778 `node --check` launches; supersedes the mask-cache line
  — CLOSED 2026-11-16 (loop U6): the rows after the self-tests run eight at a time, reported in table order; the tests
  syntax gate parses in-process; `run-gates.js` 58–60 s → 26–29 s, `fg build` 62–67 s → 31–36 s (§6, "Landed").
- [x] **Every gate re-masks all of the compiled sources** — masking src takes about 650 ms and 20 build gates each mask all of it: about 13 s a build; a mask cache keyed by file content could win it back.
  — CLOSED 2026-11-16 (loop U6), filed under `archive/argument-holes-both-repos-plan.md` (its BACKLOG detail: masking
  src takes about 650 ms in each of 20 gates' processes, about 13 s a build): with the rows side by side the gates take
  26–29 s of wall time instead of 58–60, and no cache was built (§6, "Landed").

- [x] §2 (½ day): `fg` says what it does — five stale usage lines and one missing; `fg status` asks `buildStaleness()`; `fg` asks `lib/profile.js` in-process; closes three lines of this file
  — CLOSED 2026-11-16 (loop U7): the usage says what each verb does, `fg status` prints what `buildStaleness()`
  answers, and `fg` asks `lib/profile.js` in its own process (§2, "Landed").
- [x] **`fg`'s selftests-leg budget comment and its `run-sequence` usage are stale** — the comment budgets about 153 s alone, 212 s in wave A (measured 326 s, 2026-11-11); the usage omits the stale-build refusal.
  — CLOSED 2026-11-16 (loop U7), filed under `archive/argument-holes-both-repos-plan.md` (its BACKLOG detail: the
  comment budgeted 153 s alone and 212 s in wave A, measured 326 s; the usage did not say the runner refuses a stale
  build): `5e12b629` rewrote the comment with the measured figures, and `fg run-sequence`'s usage now says a build
  older than its inputs is refused, exit 2 (§2, "Landed").
- [x] **`fg status` reads build freshness from the sources alone** — an edit of `parts.json`, `src/index.html`, `vendor/` or the build's Python reads FRESH there while every runner refuses the build.
  — CLOSED 2026-11-16 (loop U7), filed under `archive/argument-holes-both-repos-plan.md` (its BACKLOG detail: the
  runners ask `lib/build-inputs.js` against `.build-stamp`, while `fg status` compared the sources' mtimes on its own):
  `fg status` asks `buildStaleness()` and `lastBuildTime()`, and its own walk is gone (§2, "Landed").
- [x] `fg` still names mixins in two places — the `fg graph` leg's comment ("…mixin chain") and its usage gloss ("mixin super chains terminate"); the rule is `SUPER_CHAIN_TERMINATES` now. Left to the owner by the mixin loop. → `archive/mixin-removal-plan.md`, "fg still names mixins in two places"
  — CLOSED 2026-11-16 (loop U7), filed under `archive/mixin-removal-plan.md` (its BACKLOG detail: the rule is
  `SUPER_CHAIN_TERMINATES`, `graphEdgesOut` terminating on SimpleTextWdgt and TitleWdgt): the usage gloss and the
  leg's comment name the rule, and `fg | grep -c mixin` is 0 (§2, "Landed").
- [x] §10 (2 to 3 days; ruled: lands when every proof passes): the build is one Node program — 260 lines of bash, the `--shell` bridge, the hand list `SHELL_INPUTS` → `archive/build-node-port-plan.md`
  — CLOSED 2026-11-16 (loop U8): `build_it_please.sh` is a launcher of `buildSystem/run-build.js`; the profile is
  asked in-process (`--shell` is gone) and the files read by name are named once (`SHELL_INPUTS` is gone); every proof
  of the port's plan passed (§10, "Landed").
- [x] §1 (¼ day; ruled: yes, taken last): the stopped cleanup surveys leave `plans/` for `archive/`, this one included — 278 KB, a quarter of the folder; their waiting items stay in this file
  — CLOSED 2026-11-16 (loop U9): the four surveys are in `docs/archive/`, stamped STOPPED; their waiting items stay on
  the BACKLOG under their `archive/` headings (§1, "Landed").
- [x] ⛔ §7 (1 day; PARKED 2026-11-16, owner: the measured speed trade, options in §7): text cache keys are the text — takes up the 32-bit `hashOfString` collision line under the runtime-performance plan; and the line-break key gains the fitting mode it omits
  — CLOSED 2026-11-16 (after the loop, on the owner's ruling (a)): every text cache keys on the text, the line-break
  key holds its fitting mode, the memo is gone (§7, "Landed").
- [x] The text caches key on a 32-bit `hashOfString` with no check that the text matches: colliding texts ("Of"/"PG") at one font and extent share one entry, so the second draws the first's text — medium, reached by typing. → "The text caches key on a 32-bit hash with no text check"
  — CLOSED 2026-11-16 (§7, on the owner's ruling (a)), filed under `plans/runtime-performance-optimization-plan.md`
  (its BACKLOG detail: two texts that collide, "Of"/"PG" or "Aa"/"BB", at the same font and extent share one entry,
  so the second widget draws the first's text): the keys hold the texts, and each text draws its own (§7, "Landed").
