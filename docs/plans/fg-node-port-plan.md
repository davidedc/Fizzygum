# `fg` as a Node program — the port, and every process situation it must handle

> **PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
> Authored 2026-11-15 as the owning plan of item §10 of
> `docs/plans/top-10-cleanups-round-3-plan.md` (read that item first: it has the evidence and the
> honest scope). The owner approved the item on 2026-11-15 and ruled its landing: **land and
> push when every proof below passes; the bash `fg` leaves the repo; a copy is kept in the
> loop's scratch directory.** The owner also asked that the port "covers ALL the edge and corner
> cases and handles processes in all situations (hangs, crashes etc)". §4 and §5 are that list.
>
> **Mandate.** Replace the bash program with a Node program that does everything the bash one
> does, byte for byte where a reader depends on it, and that is CORRECT in the process situations
> where the bash one is silent, leaks or hangs. Nothing is added that is not on the list in §5.
>
> **Baseline.** Fizzygum `58885ce0`, Fizzygum-tests `12bbcbdb2`. `Fizzygum/fg` is 856 lines of
> bash, run by macOS `/bin/bash` 3.2.57. Line numbers drift: a function's name is the authority.

---

## 0. Orientation

`fg` is the workflow wrapper of the workspace (`Fizzygum/fg`; the umbrella's `Fizzygum-all/fg`
is a two-line shim that execs it). It builds, runs the suite, and runs the commit-point check
(`fg gauntlet`: 20 legs in four parallel waves, a failed leg retried once alone). Its exit code
and its verdict file decide whether a commit point is green. Read `Fizzygum/CLAUDE.md`,
`Fizzygum-tests/CLAUDE.md`, the header of `fg`, `buildSystem/legs.js` (the leg table) and
`buildSystem/lib/what-runs.js` (which READS `fg` to learn what runs) before anything else.

**The critical reframe.** A shell gets process handling half right for free and half wrong
silently. A Node port gets none of it for free. The port is therefore specified as two lists:
what must stay EQUAL (§3), proven by comparing the two programs on the same inputs, and what
must be BETTER (§5), each proven by a drill that the bash program fails and the Node one passes.
A situation on neither list is a finding: stop and add it to one before coding around it.

## 1. What the bash `fg` does today (the inventory to port)

Re-derive this table from the source before trusting it; it was read on 2026-11-15.

**Shared machinery.**
- `ROOT` is the parent of the directory `fg` lives in; `FZ=$ROOT/Fizzygum`, `FT=$ROOT/Fizzygum-tests`.
  Missing `build_it_please.sh` or `Fizzygum-tests/scripts` is `fg FATAL`, exit 3.
- `ban`: a blank line, then `================================ <text> ================================`.
- `verdict_start <cmd>`: starts `caffeinate -dims -w <fg pid>` in the background when the
  program exists; reads the 1-minute load and the core count; prints a PRE-FLIGHT banner when
  load ≥ cores; writes `/tmp/fg-<cmd>.verdict` = `RUNNING since <YYYY-MM-DD HH:MM:SS> pid=<pid> load=<n>[ ⚠load≥cores]`.
- `verdict_end <cmd> <rc> <text>`: writes `<CMD upper-case> EXIT=<rc> <text> (<date>)`.
- `to <secs> <cmd…>`: `perl -e 'alarm shift; exec @ARGV'`. The alarm survives the exec, so the
  command ITSELF receives SIGALRM and dies with status 142. Its children are not signalled.
- `kill_browsers`: `pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"`, then one
  second's sleep. It is GLOBAL to the machine. Inside a wave it is suppressed (`FG_PARALLEL=1`).
- `fg_build [flags]`: `./build_it_please.sh` in `Fizzygum/`, all output to `/tmp/fg-build.log`,
  NO alarm. Prints up to ten summary lines; fails on a non-zero exit, on a log without `done!!!`,
  or on a log matching `[1-9][0-9]* violation`.
- `fg_suite [flags]`: kills browsers unless in a wave; `to 900 node scripts/run-all-headless.js <flags> --shards=8` in the tests repo.
- `run_lint`: `node --check` on every git-changed `tests/` or `scripts/` `.js`; the CoffeeScript
  syntax gate when any `.coffee` changed; the macro source-discipline gate when `tests/` moved.
- `suite_profile_or_refuse`: asks `buildSystem/lib/profile.js --shell`; a profile with no
  harness page is exit 2, nothing built.

**Legs** (`run_leg`, `run_wave`, `collect_and_retry`, `legs_pending`, `legs_all_ran`).
- A leg's row comes from `buildSystem/legs.js`: steps (a suite run, or a script with its working
  directory and its alarm), an optional pass line, a headline pattern, `infraExit`.
- `legs_pending`: at run start every leg log `/tmp/fg-<leg>.log` is stamped `PENDING — …` (three lines).
- `run_leg`: clears `/tmp/fg-<leg>.failure-images` and exports it as
  `FIZZYGUM_FAILURE_IMAGES_DIR`; truncates the log; runs the steps in order, each appending to
  the log, the first failing step ending the leg with its exit code; `{SUITE_SHARDS}` and
  `{GATE_SHARDS}` take `FG_SUITE_SHARDS` (default 4) and `FG_GATE_SHARDS` (default 6); a row it
  cannot read, or one with no step, is rc 1; a leg with a pass line passes only with rc 0 AND
  that line in its log; appends `fg-leg: <name> rc=<rc> <secs>s`; refreshes the leg's standalone
  verdict file ONLY if one exists (`OK`, `INVALID` for 2, `INFRA-FLAKE` for 3, else `FAILED`,
  each followed by ` (gauntlet leg)`).
- `run_wave`: every leg in the background with `FIZZYGUM_KEEP_STALE_BROWSERS=1 FG_PARALLEL=1`;
  waits for each IN LAUNCH ORDER; prints `--- <leg> (rc=<rc>, <secs>s) ---` and the last two
  headline matches.
- `collect_and_retry`: a passed leg tallies `PASS(<secs>s)`. A failed one: banner, the log's last
  15 lines, the log copied to `.parallel-fail.log`, its images moved to `.parallel-fail.images`,
  browsers killed, the leg run again alone. Pass: `PASS-serial-only` and a warning. Exit 3 on an
  `infraExit` leg: `INFRA-FLAKE` and a warning. Otherwise `FAIL`, the last 25 lines, the images' path.
- `legs_all_ran`: a leg named by the run with no result is `NEVER-RAN` and fails the run.

**Verbs, their exits and verdicts.** `help`/no argument: usage, exit 0. Unknown verb: usage,
exit 0 (see §5 row 14).

| Verb | Alarm | Exit codes | Verdict file |
|---|---|---|---|
| `build` | none | 0, 1 | yes |
| `suite`, `finger` | 900 | 0, 1 | yes |
| `census` | 300 | 0, 1 | yes |
| `revisits` (600), `storage` (900) | as shown | 0, 1, 3 = INFRA-FLAKE | yes |
| `vmtruth` | 900 | 0, 1, 2 = INVALID, 3 | yes |
| `test` | 240 | the runner's own (142 on alarm); usage and 2 with no name | no |
| `fuzz` | 5400 | 0, 1, any other = INVALID with that code | yes |
| `diffpage` | none | 0, 2 = INCOMPLETE, else the tool's | no |
| `classify`, `run-sequence`, `lazyprobe`, `whatpins` | none | the tool's | no |
| `cc` | none | 3 when the analyzer is absent, else the tool's | no |
| `recapture` | none | 0, 1; usage and 2 with no argument | yes |
| `recapture-inspector` | none | 0, 1, 2 = REFUSED | yes; two logs `/tmp/fg-recapture-inspector-<kind>.log` |
| `apps` | 300 | the tool's | no |
| `presuite` | per leg | 0, 1, 2 = REFUSED | yes |
| `gauntlet` | per leg | 0, 1, 2 = REFUSED | yes (`OK`, `OK(warn)`, `FAILED`, with the tally) |
| `homepage` | 300 on the smoke | 0, 1 | yes; always restores the dev build |
| `menusweep`, `pinsweep`, `graph` | none | the tool's, with a banner | no |
| `hypopart` | none | 2 with no path, else the tool's | no |
| `fingerprint` | none | 0 (a difference is not a failure), 1 | yes |
| `lint` | none | 0, 1 | no |
| `stinks` | none | 0, 1 (any failure is 1) | no |
| `doc-narration` | none | the tool's (2 = INVALID kept) | no |
| `status`, `critique`, `killz` | none | 0 | no |

**The gauntlet's two paths.** PARALLEL: verdict start, profile check, table read (a table it
cannot run is exit 2), leg logs stamped, lint, build, ONE browser kill, wave A (suites at 4
shards), wave B with `FG_GATE_SHARDS=4`, wave C with 6, wave D, then retries at
`FG_SUITE_SHARDS=8 FG_GATE_SHARDS=6`, the never-ran check, the verdict with the total seconds.
SERIAL (`FG_GAUNTLET_SERIAL=1`): NO lint; build; `FG_SUITE_SHARDS=8`; each leg after a browser
kill; exit 3 on an `infraExit` leg is `INFRA-FLAKE`; the verdict has no total. `presuite`: the
parallel shape with one wave at `FG_SUITE_SHARDS=8`.

**Who reads what `fg` writes** (a format they read must not move): the umbrella's guard hook
(`.claude/hooks/fizzygum-cmd-guard.py`: the `RUNNING` line and the verdict paths; NOT yours to
edit), the umbrella's `resume-arc` skill, `fg status`, `buildSystem/legs-selftest.js`, the
instruction files, and any agent that greps a leg log for `fg-leg:`. Exit 142 is read as
"killed by a signal, unmeasured" by `scripts/lib/audited-suite.js`.

## 2. Why it is shaped this way, and why it changes now

It grew from a ten-line cwd fix into the commit-point program, in the language the build script
already used. Round 2 moved its leg roster into a JavaScript table, which bash now reads by
running Node and parsing the output; the same round recorded two defects that came from the
shell itself (`Fizzygum-tests/.scratch/cleanups-loop-2/LEDGER.md`: a `case` inside `$( )` that
bash 3.2 misparses and `bash -n` passes; a reader taking stderr for table rows). The precedent
is the first survey's §10: the build's Python was ported to Node and proven by fingerprints.

## 3. What must stay EQUAL

1. Every verb, flag and environment variable of §1, with the same exit codes.
2. Every byte a reader depends on: the verdict lines, the `PENDING` stamp, the `fg-leg:` stamp,
   the banners, the tally (`<leg>:PASS(<n>s)`, `PASS-serial-only`, `INFRA-FLAKE`, `FAIL`,
   `NEVER-RAN`), the wave banners, the usage text, `fg status` and `fg critique` output.
3. Every file path under `/tmp` (the literal `/tmp`, never the OS temp directory).
4. Every program launched, with its arguments, its working directory, its alarm and the `FG_*`
   and `FIZZYGUM_*` variables it sees: for `presuite`, both gauntlet paths and each verb.
   `node` is found through `PATH`, as today.
5. The order of everything observable: lint before build, waves in order, legs waited for in
   launch order, the retry after all four waves.
6. The run set `what-runs.js` computes, and every gate's bite proof, unchanged.
7. What stays an external program: `git`, `pkill`, `pgrep`, `caffeinate`, `node`, the build
   script. What becomes plain JavaScript: `perl` (the alarm), `sysctl`, `awk`, `sed`, `grep`,
   `tail`, `date`, `ls`, `cp`, `mv`, `rm`, `find`. These are the ONLY launch differences allowed.

## 4. Process situations: the full matrix

For each row: what bash `fg` does today, and what the port MUST do. "Tree" means the process and
every descendant, found by walking parent links in a `ps` snapshot.

**A. A child's life.**

| # | Situation | Bash today | The port |
|---|---|---|---|
| A1 | Exits 0 or n | propagates n | the same |
| A2 | Killed by a signal (crash, OOM kill) | rc 128+n | rc 128+n, and the log says which signal |
| A3 | Hangs past its alarm | SIGALRM to the one process, rc 142; its children live on | SIGTERM to the tree, 5 s grace, SIGKILL to what is left; rc 142; one line in the log: timed out after N s, tree killed |
| A4 | Ignores SIGTERM | n/a | SIGKILL after the grace, same rc |
| A5 | Exits but leaves descendants (browsers) | orphans until the next global `pkill` | every descendant recorded while the leg ran and still alive (same pid AND same start time) is killed at leg end |
| A6 | Writes gigabytes | file redirection | the child's stdout and stderr are FILE DESCRIPTORS, never a Node pipe; no `exec`/`execSync` buffer anywhere on an unbounded output |
| A7 | Cannot be started (`node` missing, bad cwd, no file descriptors, no memory) | shell error, rc 127/126 | the `error` event is handled: rc 127 (not found) or 126 (other), the reason in the log; never a wait for an exit that will not come |
| A8 | Exits while a grandchild still holds its output open | the wait returns | wait for `exit`, never `close` |
| A9 | Ends at the same instant its alarm fires | one outcome | one outcome: a settled flag; no signal is ever sent to a pid after its `exit` |
| A10 | Passes, but its pass line is absent | rc 1 | the same |
| A11 | A leg log too large for one string (over 500 MB) | `grep` streams | the pass line, the headline and the "last N lines" are read by STREAMING or from the file's tail; the log is never read whole |
| A12 | Reads stdin | inherits the terminal | a leg gets no stdin; a passthrough verb (`diffpage` reads names on stdin) inherits it |
| A13 | A wave leg whose supervisor code throws | n/a | every leg resolves to an rc; a thrown error is rc 1 with its message in the log, and the other legs are still awaited |

**B. `fg`'s own life.**

| # | Situation | Bash today | The port |
|---|---|---|---|
| B1 | SIGINT, SIGTERM, SIGHUP, SIGQUIT | dies; children in other groups live; the verdict says `RUNNING` forever | stop launching; kill every live tree; verdict `<CMD> EXIT=<128+n> INTERRUPTED by <signal>`; exit 128+n. A second signal kills at once |
| B2 | Killed with SIGKILL, or the machine dies | the verdict says `RUNNING` forever | nothing can run, so the READER decides: a side file `/tmp/fg-<cmd>.running` holds the pid and its start time; `fg status` shows a `RUNNING` verdict whose process is gone as `STALE — fg is gone (killed or crashed); not a result` |
| B3 | `fg`'s own code throws | n/a | children killed; verdict `<CMD> EXIT=2 INVALID — fg internal error: <message>`; exit 2 (nothing was measured) |
| B4 | Its stdout is closed (`EPIPE`) | SIGPIPE kills it mid-run, children orphaned | stop writing to stdout, FINISH the run, write the verdict |
| B5 | The run is over but something keeps the event loop alive | n/a | no `process.exit` on the normal path; a watchdog names the handle that held the exit and then exits with the SAME code |
| B6 | A second `fg` long operation starts while one runs | both run; they share the build tree and kill each other's browsers | a long operation (one that builds or launches a browser) REFUSES, exit 2, naming the live one; `FG_ALLOW_CONCURRENT=1` overrides. Read-only verbs never refuse |
| B7 | The machine sleeps mid-run | `caffeinate` holds it awake | the same `caffeinate`; and a leg whose wall-clock time exceeds its monotonic time by over a minute says so in its log and in the tally (`slept <n>s`) |
| B8 | `/tmp` is unwritable or full | errors on the terminal | a verdict that cannot be written is a warning on stderr and never changes the exit code; a LEG LOG that cannot be opened fails that leg, with the reason |
| B9 | A verdict is read while being written | may read empty | written to a temporary file and renamed |
| B10 | A verb fails on a path that forgets its verdict (`fingerprint`'s two `|| exit 1`) | the verdict says `RUNNING` forever | every exit of a verb that started a verdict ends it |
| B11 | The build hangs | hangs forever | a ceiling, `FG_BUILD_ALARM_SECS` (default 1800, 0 for none); past it the tree is killed and the build FAILED, "timed out" |
| B12 | The leg table cannot be loaded, or names a leg twice, or a row cannot be run | exit 2 before anything runs | the same, and before the build |

**C. Input and environment.**

| # | Situation | The port |
|---|---|---|
| C1 | An argument with spaces or shell characters | passed as one argument: no shell is ever given an interpolated string |
| C2 | A leg name that is not `[a-z0-9-]+` | refused: names become file paths |
| C3 | `FG_SUITE_SHARDS` or `FG_GATE_SHARDS` set by the caller | the same effective counts as bash (the caller's value in wave A; fg's own values where bash assigns them); children see exactly the variables they see today |
| C4 | A headline pattern written for `grep -E` | every pattern in the table is proven to select the same lines as `grep -E` on a real log of its leg |
| C5 | Run from any directory, through the umbrella's shim, or from a fingerprint baseline worktree | the same `ROOT`; `fg fingerprint` still gives a baseline without `fg` a copy |
| C6 | An unknown verb | see §5 row 14 |

## 5. Deliberate differences (the whole list; each is a ruling for the owner's second look)

1. A3–A5: a timed-out or finished leg leaves no process behind. `kill_browsers` stays as it is,
   as the fallback for what an earlier crashed run left.
2. A2, A3: the log names the signal or the timeout.
3. B1: an interrupted run says INTERRUPTED and kills its children.
4. B2: `fg status` tells a dead run from a live one. The `RUNNING` line itself does not change.
5. B3: an error in `fg` is INVALID, exit 2, never a pass and never a test failure.
6. B4: a closed stdout no longer kills the run.
7. B5: the exit watchdog.
8. B6: the refusal of a second long operation.
9. B7: the sleep note.
10. B9: atomic verdict writes.
11. B10: `fingerprint` always ends its verdict.
12. B11: the build's ceiling.
13. `perl`, `sysctl` and the text utilities are no longer launched (§3 item 7).
14. An UNKNOWN verb prints the usage and exits 2 (today 0): a mistyped gating command must not
    read as a pass. `fg`, `fg help` stay 0.

## 6. Fix shape

- `Fizzygum/fg` stays the entry point, now a short Node launcher (`#!/usr/bin/env node`), so the
  umbrella's shim, the guard hook and every instruction keep working unchanged.
- The code lives under `buildSystem/` as a few modules. Their names and homes follow the nearest
  precedent there; two separations are REQUIRED:
  - **the commit-point half** (build, lint, suite, the leg runner, waves, retry) is one module,
    because `what-runs.js` takes exactly that half as a root today (the four functions it names).
    The on-demand verbs live apart, so the run set does not grow by their tools;
  - **the process supervisor** (spawn to file descriptors, the alarm, the tree snapshot and kill,
    the signal handlers, the exit watchdog) is one module with no knowledge of legs, so it can
    be tested alone.
- Every script `fg` launches is spelled as a string argument of `path.join(…)`, which is how
  `what-runs.js` already reads a JavaScript launcher's edges.
- `legs.js` loses its `--shell` printer and the self-test cases that exist for it; `what-runs.js`
  loses the `fg` half of its shell reading (its shell lexer stays for the two build scripts) and
  its "reader launches the table" case becomes "fg requires the table".
- Two test rails, in the new `fg` only, each refused outside a test: `FG_TMP=<dir>` in place of
  `/tmp`, and `FG_LEGS_TABLE=<file>` in place of the table. A third, `FG_CENSUS_LOG=<file>`,
  appends one JSON line per program started (argv, cwd, alarm, the `FG_*`/`FIZZYGUM_*` it sees).

## 7. Proof (all of it, in this order)

1. **Inventory.** §1 re-derived from the bash source into the unit's `PREP.md`, every verb and
   every branch, and compared with §1 here. A difference is corrected HERE first.
2. **Readers.** Every reader of a verdict file, a leg log or the `fg-leg:` stamp in both repos
   and in the umbrella's `.claude/` listed (grep `.verdict`, `fg-leg:`, `parallel-fail`,
   `failure-images`), and whether any script EXECUTES `fg` (UNVERIFIED that none does).
3. **The theatre.** A scratch directory of stand-in programs placed first on `PATH` (`node`,
   `git`, `pkill`, `pgrep`, `caffeinate`, `perl`, the build script), each scripted by a scenario
   file: exit n, print or omit a pass line, sleep, hang, die by a signal, ignore SIGTERM, leave a
   child behind, write 600 MB. The stand-in `node` passes through for `fg` itself and for a data
   read (round 2's lesson: a stand-in that answers the refactor's own data reads makes it pass
   vacuously).
4. **Equal behaviour, old against new.** For every row of §1's verb table and every branch of
   the leg machinery (pass; fail 1, 2, 3; pass line missing; table refuses; profile refuses; lint
   fails; build without `done!!!`; build with a violation; a wave with one failing leg whose
   retry passes, fails, exits 3; a leg that never ran; the serial path; `presuite`), run the bash
   `fg` and the Node `fg` in the theatre and compare, after normalising times, pids and
   durations: stdout, stderr, the exit code, and every file under the temp directory. The bash
   side writes into the real `/tmp`: save and restore the real `/tmp/fg-*` around it, and run it
   only while no `fg` operation runs.
5. **Launch census.** Old (stand-ins logging) against new (`FG_CENSUS_LOG`), for `presuite`, the
   parallel gauntlet, the serial gauntlet and each verb: identical after §3 item 7's differences.
   Round 2's instrument is kept at `Fizzygum-tests/.scratch/cleanups-loop-2/u9-fg-leg-table/census/`.
6. **Better behaviour.** One drill per row of §4 marked as a difference in §5, in the theatre,
   each run on the bash `fg` first (recording what it does) and then on the Node one (which must
   do what §4 says). The drills become the standing self-tests of step 9.
7. **The run set.** `what-runs.js`'s run set saved before and after: the same files, apart from
   `fg`'s own new modules.
8. **Real runs, new `fg`.** `fg presuite`, a parallel `fg gauntlet`, ONE serial gauntlet,
   `fg homepage`: green, 20 legs each. Before the switch, one parallel gauntlet under the OLD
   `fg` on the same tree, for the tally to compare with.
9. **Standing self-tests.** The supervisor's cases as a node-tier `*-selftest.js` (alarms in
   milliseconds, the whole file under five seconds, run on every build), and one end-to-end fake
   gauntlet through the real entry point as a `*-selftest-headless.js` (the gauntlet's
   `selftests` leg). The build refuses a launched script with no rule registry or proof: read
   `docs/architecture/lint-and-static-checks.md` §3, and state `not-a-gate: <reason>` in a
   module that judges nothing.
10. **Live drills on the real tree**, each recorded in the LEDGER with the `ps` evidence:
    (i) SIGTERM to `fg gauntlet` in wave A: within 15 seconds no process of the run is alive and
    no browser it launched; the verdict says INTERRUPTED; (ii) SIGKILL to `fg gauntlet` in wave
    A: `fg status` says STALE; `fg killz` clears what is left; (iii) a second `fg build` started
    during a gauntlet is refused; (iv) SIGINT to the process group, as a terminal would send it.
    After the drills: `fg build`, and a clean `fg status`.

## 8. Central risks

- **The check that proves the port is the thing being ported.** Until step 8 passes, the bash
  `fg` (kept as `<scratch>/fg.before`) is the judge. If the Node `fg` cannot run a gate at any
  point, restore `fg.before` before doing anything else.
- **A pass that is not one.** The worst outcome is a Node `fg` that says OK when a leg failed.
  Step 4's failing branches and step 9's fake gauntlet exist for exactly this; none may be
  skipped for time. If the time box ends before step 8, PARK: never land a partly proven `fg`.
- **Killing too much.** The tree kill signals only pids from a snapshot taken at that moment
  whose start times match; it never signals a pid after its own `exit`; it never signals `fg`'s
  ancestors. Each has a self-test case.
- **The guard hook.** It is not the loop's to edit. If it needs a change to keep working, PARK.

## 9. Rejected alternatives

- **Process groups for the kill** (`detached` children, signal the group): rejected. Puppeteer
  starts Chrome in its own group, so a group kill misses the browsers; and detached children no
  longer die when a person kills `fg`'s own group, which is the documented way to stop a run.
  Children stay in `fg`'s group, and the kill walks the tree.
- **Promoting `--shell` and keeping bash for the verbs**: it keeps both languages.
- **A new name or path for the Node program**: every instruction, the hook and the shim name `fg`.
- **Changing the `RUNNING` line** to carry liveness: the hook reads it. The side file does it.

## 10. Verification commands

```
/Users/davidedellacasa/code/Fizzygum-all/fg status
/Users/davidedellacasa/code/Fizzygum-all/fg build       # runs every self-test, the new ones included
/Users/davidedellacasa/code/Fizzygum-all/fg presuite
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet    # background, log to a file
FG_GAUNTLET_SERIAL=1 /Users/davidedellacasa/code/Fizzygum-all/fg gauntlet   # once, about 37 min
/Users/davidedellacasa/code/Fizzygum-all/fg homepage
```

## 11. References

- `docs/plans/top-10-cleanups-round-3-plan.md` §10 (the item), §13 (its case law)
- `docs/plans/top-10-cleanups-round-2-plan.md` §6 and §7, "Landed" (the Node gate driver and the
  leg table: the two precedents, with what each proof looked like)
- `buildSystem/legs.js`, `buildSystem/legs-selftest.js`, `buildSystem/lib/what-runs.js`,
  `buildSystem/run-selftests.js`
- `Fizzygum-tests/scripts/lib/safe-exit.js` (exiting without losing a large final write),
  `scripts/lib/headless-driver.js` (`closedWithin`: the existing bounded-wait idiom)
- `Fizzygum-tests/CLAUDE.md`, the paragraph on the progress reporter keyed off promises settling
  (the same class of hang as §4 B5)

## 12. Start prompt for a fresh session

```
Read Fizzygum/docs/plans/fg-node-port-plan.md in full, then Fizzygum/fg and buildSystem/legs.js.
Run /Users/davidedellacasa/code/Fizzygum-all/fg status and confirm no long operation is running.
Carry out §7 step 1 and step 2 only (the inventory and the readers), show me every difference
from the plan's §1, and wait for my go-ahead. Do not commit or push without asking me.
```
