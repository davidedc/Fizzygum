# Dev-workflow optimization plan — post transcript audit of 2026-07-05 → 07-12

**Status: AUTHORED 2026-07-12, phases P1–P8 not started. §0.4 quick wins are ALREADY LANDED — do not redo them.**

This plan is written to be executed COLD by an agent with NO prior context. Everything needed —
history, measured evidence, file paths, exact failure strings, acceptance gates — is embedded here.
Read §0 fully before touching anything.

---

## §0 Context a cold executor must have

### §0.1 The workspace (three sibling git repos + local-only tooling)

`/Users/davidedellacasa/code/Fizzygum-all/` is an umbrella directory, **not itself a git repo**. It holds:

- `Fizzygum/` — framework source (~470 `.coffee` files) + build (`build_it_please.sh` → `buildSystem/build.py`). The build also runs a battery of static gates: `buildSystem/check-coffee-syntax.js`, `check-layering.js`, `check-dead-methods.js` (+ `dead-method-allowlist.txt`), `check-stinks.js`, `check-thin-wraps.js`, `check-constructors-build.js`, and relayout gates — see the `node ./buildSystem/…` call sites in `build_it_please.sh`.
- `Fizzygum-tests/` — 238 screenshot-diff "macro" SystemTests + the headless runner scripts in `scripts/`. Key scripts: `run-all-headless.js` (parallel suite, default `--shards=8`, see `REQUESTED_SHARDS` around line 61; shards are cut by driving the harness URL with `?startupActions=<json>` carrying `numberOfGroups`/`groupToBeRun`), `run-macro-test-headless.js` (one test), `capture-macro-test-references.js` (reference capture), `run-paint-audit.js` (suite-wide paint-truthfulness gate, **single-process**, ~7 min), `smoke-apps-headless.js`, and three shell gates under `scripts/tier-naming-audit/`, `scripts/notification-settle-audit/`, `scripts/end-of-cycle-audit/`. `scripts/lib/kill-stale-browsers.js` pkills ALL test browsers at every runner startup, **unless `FIZZYGUM_KEEP_STALE_BROWSERS=1`** (an escape hatch whose own comment says it exists for "deliberately run two suites concurrently"). `.scratch/` in this repo is gitignored (`.gitignore` line 9).
- `Fizzygum-builds/` — generated output; never hand-edit.
- `fg` (umbrella root) + `.claude/hooks/fizzygum-cmd-guard.py` + the umbrella `CLAUDE.md` — **local-only tooling, committed to NO repo**. `fg` subcommands: `build | suite | gauntlet | test <name> | recapture <name> | apps | homepage`.

**The gauntlet** (`fg gauntlet`) is the standard verification gate, run before every commit point. It is strictly SEQUENTIAL today: build → suite dpr1 → suite dpr2 → suite webkit → apps smoke → paint audit → tiernaming gate → settle gate → capstone gate, each leg logging to `/tmp/fg-<leg>.log`. Measured on 2026-07-11 (16-core Apple Silicon, `sysctl hw.ncpu`=16): build ~2 min; each suite leg 1.5–1.6 min at `--shards=5`; apps ~1 min; **paint audit ~7 min (the longest leg — single browser, whole suite)**; gates ~1–2 min each. Best case **~17 min**; 20–30 min under load.

### §0.2 Owner's standing rules (violating these is worse than any speedup)

- **Never commit or push autonomously.** Present a summary + proposed message, wait for explicit approval. Never `git push` without it.
- References are **byte-identical** by policy; the ONE tolerated exception is the "benign inspector member-list recapture" (see P2). A MASS visual recapture always requires asking the owner first.
- End-of-arc ritual: full gauntlet ×3 (serial, for nondeterminism sampling) + `fg homepage` green.
- **Never `git stash` in these repos** — on 2026-07-05 a `stash pop` silently emptied the working tree AND the stash list (a `.gitattributes` warning is implicated); recovery required digging git dangling blobs. Use a WIP commit or a worktree for clean-build A/B tests.

### §0.3 The evidence (from the 2026-07-05→12 transcript audit; 19 sessions, ~8,600 tool calls)

| Fact | Number |
|---|---|
| Full gauntlet runs in the week | ~87 (113 background launches) — **~25–40 h wall** |
| Reference recaptures | 199 invocations; `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` alone recaptured 20×, run singly 29× |
| Standalone suite runs | 163 (~1.6 min each) |
| Builds | 254, median 17 s → **the build is NOT a bottleneck; do not parallelize it** |
| Foreground poll loops waiting on gauntlets | 174 calls, 6.3 h (now hook-blocked, see §0.4) |
| Guard-hook false positives | 19 (fixed, see §0.4) |
| Extra gauntlet RE-runs caused by inspector member-list churn, masked exits, incomplete batch recapture, capstone shard-drops | ≥10 across the week (each ~17 min) |

Explicitly **parked — do not re-attempt**: the "SWCanvas invisible-pixel hash" fix (hashing only visible pixels). It was investigated and CONTRADICTED (the hashed desktop buffer is always opaque; Option A was a no-op). See memory note `swcanvas-invisible-pixel-hash-confirmation`. Do not resurrect without a fresh repro.

### §0.4 Already landed on 2026-07-12 (quick wins) — do NOT redo

1. `.claude/hooks/fizzygum-cmd-guard.py`: cd-target parsing stops at whitespace (multi-line `cd` false-positive fixed), quoted-with-space targets handled, `$VAR` targets fail open, build detection anchored to command position, piped-build check scoped to the same command segment, and a new **Rule 0** blocking FOREGROUND `until|while grep … sleep` pollers that watch for GAUNTLET/SUITE verdicts (backgrounded waiters allowed). A 19-case battery passed.
2. `fg`: `build|suite|gauntlet|homepage` now maintain **`/tmp/fg-<cmd>.verdict`** — `RUNNING since …` written at start (stale-proof), `<CMD> EXIT=<rc> …` at end.
3. Umbrella `CLAUDE.md`: new section "Long ops & shell discipline" (background + notification recipe, verdict files, absolute-paths/`git -C` rule, `Fizzygum-tests/.scratch/` for ad-hoc Node probes).

---

## P1 — Parallel gauntlet + sharded paint audit + `fg presuite` (highest ROI: ~17 → ≤8 min × ~90 runs/wk)

### P1.1 Why it is currently sequential, and why that's fixable

Every leg starts by pkilling ALL headless test browsers (`kill_browsers()` in `fg`; `scripts/lib/kill-stale-browsers.js` in every runner). Two legs running concurrently would kill each other's browsers. The escape hatch already exists: `FIZZYGUM_KEEP_STALE_BROWSERS=1` suppresses the runner-side pkill. All legs only READ the build output, write to distinct `/tmp/fg-*.log` files, and (suites/paint) match references by hash — no shared mutable state besides the browsers.

### P1.2 Design

In `fg`'s `gauntlet)` case:

1. Do ONE global `kill_browsers` up front (as `fg_build` completes).
2. Run the legs in **two waves**, each leg a background job with `FIZZYGUM_KEEP_STALE_BROWSERS=1` exported, its own log, and its exit code collected via `wait`:
   - **Wave A:** suite dpr1, suite dpr2, suite webkit — each at `--shards=4` (12 browsers on 16 cores) — plus apps smoke (1 browser). Expected wall: ~2–3 min (suites are ~1.6 min at 5 shards uncontended; measure at 4 shards contended).
   - **Wave B:** paint audit (sharded, see P1.3, 5 browsers), tiernaming gate, settle gate, capstone gate. Expected wall: ~3 min (bounded by the sharded paint audit or the slowest gate).
   Rationale for two waves rather than one: ≥21 concurrent browsers oversubscribes 16 cores and the whole point is wall-clock; also the gates' `kill_browsers` semantics inside their own shell scripts must be audited (see P1.4) before they share a wave with suites.
3. Inside a parallel leg, fg's own `kill_browsers` calls (in `fg_suite`, the `apps` invocation, gate loops) must be SKIPPED: gate them behind `[ "${FG_PARALLEL:-0}" = 1 ] ||`.
4. **Failed-leg serial retry:** if a leg fails in parallel mode, re-run THAT LEG alone serially once. If it passes serially, report `<leg>: FAILED-parallel/PASSED-serial — possible load-sensitive nondeterminism (see Fizzygum-tests/DETERMINISM.md)` and count the gauntlet as PASSED-with-warning (exit 0 but a loud banner + verdict note). If it fails serially too, the gauntlet FAILS. This preserves the gate's meaning while keeping load-flakes diagnosable instead of alarming.
5. **Escape hatch:** `FG_GAUNTLET_SERIAL=1 fg gauntlet` runs the old sequential path (keep the old code intact behind the flag). Parallel becomes the default only after the P1.6 acceptance gate.
6. Keep the per-leg `to <seconds>` perl-alarm timeouts as today (suite 900, apps 300, paint 720, gates via their scripts). Keep writing `/tmp/fg-gauntlet.verdict` (already landed) — extend the final tally with per-leg wall-clock.

### P1.3 Shard the paint audit (~7 → ~2 min)

`scripts/run-paint-audit.js` (132 lines) boots ONE browser, selects all tests (`selectTestsFromTagsOrTestNames(['all'])`), runs the whole suite with `window.FIZZYGUM_PAINT_AUDIT = true`, then reads `world.automator.player.paintTruthfulnessAuditChecked` / `.paintTruthfulnessAuditOffenders`. The suite runner already knows how to shard via the harness URL's `?startupActions=<url-encoded json>` with `numberOfGroups`/`groupToBeRun` (see `run-all-headless.js` for the exact JSON shape and the probe/clamp logic).

Add `--shards=N` (default 5) to `run-paint-audit.js`: launch N pages/browsers, each with the SAME init script (`FIZZYGUM_PAINT_AUDIT=true`) and UA spoof (canonical Chrome `148.0.0.0` — copy the existing `CANONICAL_CHROME_VERSION` handling verbatim), each driving one group; sum `checked` and concatenate `offenders` across shards; the gate condition (`offenders.length > 0` → exit 1, `checked` must equal the filtered total) is unchanged. Keep `--shards=1` as the old path.

**Do NOT fold the audit into the dpr1 suite leg** (tempting — it would delete the leg entirely): the audit's per-test forced `fullChanged()+updateBroken()` fingerprinting is designed not to change verdicts, but coupling it to the reference-matching leg makes any future audit bug corrupt the suite gate too. Separate legs, parallel wave, is the safe shape.

### P1.4 Pre-work audit (do this FIRST, ~30 min)

- Read the three gate shell scripts (`run-tier-naming-gate.sh`, `run-notification-settle-gate.sh`, `run-capstone-gate.sh`): confirm each honors `FIZZYGUM_KEEP_STALE_BROWSERS` (they call the node runners which use `kill-stale-browsers.js`, but the SCRIPTS may also pkill directly — fg's gauntlet loop pkills before each; those are the calls to gate behind `FG_PARALLEL`).
- Confirm the three suite legs + paint audit write ZERO shared files (grep the runners for `/tmp/` writes; per-leg logs are parameterized by fg, but check for hardcoded temp paths, e.g. probe artifacts).
- Confirm memory pressure: 17 concurrent Chromes at dpr2 was the historical fan-spinner; wave A holds 13 browsers at dpr≤2. If the box swaps, drop suites to `--shards=3`.

### P1.5 `fg presuite` — the documented inner-loop tier

Add: `fg presuite` = build + suite dpr1 (`--shards=8`) + sharded paint audit, in parallel after the build; target ≤4 min. Update the umbrella `CLAUDE.md` and root-repo docs: **iterate with `fg presuite`, close a phase/commit point with the full `fg gauntlet`**. (The transcript audit shows sessions already drift toward exactly this split informally; naming it removes ~⅓ of full gauntlet runs.) Also bump standalone `fg suite`'s default `--shards=5` → `8` (the runner's own default is 8 and its header says "this machine ran 8 cleanly"); verify with 3 consecutive clean runs at 8.

### P1.6 Acceptance gate (do not flip the default before ALL of this passes)

1. `bash -n fg` clean.
2. On the SAME clean build: 3× `FG_GAUNTLET_SERIAL=1 fg gauntlet` and 3× parallel `fg gauntlet` — all 6 green, identical per-leg failed-test counts (0), paint audit `checked` count identical (238 at time of writing).
3. Parallel wall-clock ≤8 min on an otherwise idle box (report the number; stretch goal 6).
4. One induced-failure drill: break a reference on purpose (e.g. temporarily rename one reference PNG), confirm the parallel gauntlet FAILS loudly with the right leg named, restore, confirm green. (No commit of the breakage, obviously.)
5. `fg homepage` still green (it reuses `fg_build` twice — untouched by this work, but it shares the verdict/kill plumbing).

Rollback: `FG_GAUNTLET_SERIAL=1`, or `git`-less revert of `fg` (it's uncommitted local tooling — take a copy `fg.bak` before editing).

---

## P2 — Stop the Object-Inspector member-list recapture churn (biggest recapture driver)

### P2.1 The problem, precisely

Several macro tests screenshot an open Object-Inspector whose left pane lists the target widget's members. **Any method added to or removed from a widely-inherited class (especially `Widget`) shifts that rendered list**, breaking 1–11 of these tests with pixel diffs that are 100% benign. Measured cost: in one week, ~8+ separate "re-derive that it's benign → recapture → re-run gauntlet" episodes; the headline test `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` was recaptured 20×. Two dataflow-arc phases each churned 11 inspector tests at ~2 min/test recapture plus a full gauntlet re-run. Owner policy already says benign inspector recapture is acceptable (memory: `byte-identical-not-sacred-for-benign-inspector-recapture`) — the cost is the RITUAL, not the policy.

### P2.2 Investigate first (~1 h)

- Find the inspector's member-list rendering: `grep -rn "class InspectorWdgt" Fizzygum/src/` and locate where the member list is built (look for sorting/filtering of `Object.getOwnPropertyNames` / prototype walks). Prior art in memory (`oo-smells-backlog`): "adding to a common base is inspector-safe only when the panel hides inherited members" — i.e., a hide-inherited mode already exists or existed; find it.
- Derive the full affected-test set empirically: add a throwaway no-op method to `Widget`, build, run the dpr1 suite, list the failing tests. Record the list in this doc. Remove the method.

### P2.3 Options (pick after P2.2; (i) is the durable fix)

- **(i) Make the inspected fixtures churn-proof:** have the affected macros open the inspector in a "hide inherited members" mode (if the panel supports it), or inspect an instance of a leaf fixture class whose OWN member list is what renders. Adding a method to `Widget` then changes nothing visually. Requires one recapture of the affected set, ever. **This is a MASS visual recapture → ask the owner before executing** (§0.2).
- **(ii) `fg recapture-inspector`:** a new fg subcommand that recaptures the recorded affected set (from P2.2) at `--dprs=1,2` in one shot and then re-runs ONLY the dpr1 suite as a sanity leg. Turns the ritual into one command (~10 min) without touching the framework. No owner approval needed beyond the existing benign-recapture grant.
- **(iii) Diff classifier:** a script that, given a failed inspector test, crops the diff to the member-list rect and reports "benign member-list shift" vs "real". Cheapest, but still leaves recapture + gauntlet re-run costs. Only do this if (i) is rejected and (ii) feels insufficient.

Acceptance: after the chosen fix, adding a no-op method to `Widget` + full gauntlet = **zero** screenshot failures (option i), or one command + ≤10 min to green (option ii).

---

## P3 — Harden the recapture pipeline (4 known scripted gaps)

All in `Fizzygum-tests/scripts/capture-macro-test-references.js` (209 lines) unless noted. Each gap recurred ≥3× in the audited week; each costs a wasted run or a wasted gauntlet.

1. **Manifest-miss on a NEW test.** First capture of a freshly created `tests/SystemTest_<name>/` dir fails `did not select exactly one SystemTest` because the built `testsManifest.js` predates the dir (the capture flow's initial build path uses `--keepTestsDirectoryAsIs`). Fix: when test selection fails, check whether `tests/<name>/` exists on disk but not in the built manifest; if so, print what happened, run ONE full build (no `--keepTestsDirectoryAsIs`), and retry once automatically.
2. **Pre-settle capture flake.** Resize/window-open-heavy tests sometimes capture a not-yet-settled frame; the script's own advice today is literally "just RE-RUN". Fix: after capturing, capture the same frame AGAIN and byte-compare; on mismatch, wait + retry (bounded, e.g. 2 retries), and only then fail with "unstable capture — likely pre-settle; see Fizzygum-tests/CLAUDE.md".
3. **Batch multi-image gap.** The hand-rolled `--no-build --no-verify` batch path silently captured only `image_1` of multi-image tests (2026-07-05, cost a full extra gauntlet). Fix: either make batch mode iterate ALL images per test, or make `--no-build --no-verify` a hard error (memory already warns "run the capture script's FULL flow — no --no-build"; a hard guard beats a warning).
4. **Silent empty output.** One run left `automation-assets/` empty without a non-zero exit. Fix: after capture, assert the expected reference files exist and are non-empty for every image name extracted from the macro source; retry once; then fail loudly.

Acceptance: (a) create a throwaway test dir, first `fg recapture` of it succeeds with zero manual intervention, then delete it; (b) recapture a known 2-image test and assert both images written; (c) `--no-build` path either captures all images or refuses to run; (d) suite green afterwards. No framework code touched → dpr1 suite + one full gauntlet at the end is sufficient verification.

---

## P4 — `fg lint`: pre-build static checks in seconds + two scanner precision fixes

### P4.1 `fg lint` (new subcommand)

Runs in ~seconds, BEFORE any build, over the files changed per `git -C <repo> status --porcelain`:

- Changed `Fizzygum-tests/tests/**/*.js` → `node --check` each. Catches the recurring **backtick-inside-a-macro-comment** bug ("the classic gotcha": a backtick in a JS template-literal macro comment prematurely closes the string; one instance was masked by a `; echo $?` and cost a redundant ~12-min gauntlet). The build has a test-`.js` syntax gate, but it fires minutes into a build — `fg lint` fires in seconds.
- Changed `Fizzygum/src/**/*.coffee` → run `buildSystem/check-coffee-syntax.js` scoped to those files if it supports per-file args (read its arg parsing; if it only does the full tree, the full tree run is still ~seconds-fast — measure, and scope only if needed).

Wire `fg gauntlet`/`fg presuite` to run `fg lint` first (fail fast). Acceptance: introduce a backtick into a scratch copy of a test comment → `fg lint` catches it in <10 s; clean tree → `fg lint` exits 0 quietly.

### P4.2 Dead-method scanner: string-interpolation blind spot

`buildSystem/check-dead-methods.js` strips string literals before counting references, so a method referenced ONLY inside CoffeeScript interpolation (`"…#{@_dragEmbedCandidateTitle()}…"`, the 2026-07-06 incident) is falsely flagged dead. Fix: before stripping a double-quoted string, extract every `#{…}` body and append it to the code text being scanned. Add a regression fixture (a method called only from interpolation must NOT be flagged). Verification: full build green; deliberately add such a method+call in a scratch branch of the check's test input if it has one, else verify against the live incident pattern.

### P4.3 Layering gate: name-qualified matching

`buildSystem/check-layering.js` matched by bare method NAME, so `TransformSpec.setScale` (a plain data-holder setter) was confused with `TransformFrameWdgt.setScale` (a self-settling public wrapper) — a false positive that forced deleting legitimate setters (2026-07-09 22:04). Fix: where the scanner attributes a definition/call, key by (class, method) — the codebase is one-class-per-file with `filename == class name` (build invariant), so the defining class is derivable from the file. Where the RECEIVER class of a call is not inferable (dynamic dispatch), keep today's conservative behavior. Add the TransformSpec/TransformFrameWdgt pair as a regression fixture comment. Verification: full build green on the current tree; the gate must still catch a deliberately-planted true violation (plant one in scratch, confirm FAIL, remove).

**Gate changes are risky** (they gatekeep every future build): each of P4.2/P4.3 needs a full gauntlet + a planted true-positive check before landing.

---

## P5 — `fg status` + `fg killz` (re-grounding one-liner; 32 compactions/week × 5–15 min re-orientation)

New fg subcommands, pure read-only:

- `fg status` prints, in one shot: per repo (`Fizzygum`, `Fizzygum-tests`, `Fizzygum-builds`) the HEAD short-sha + branch + ahead/behind vs origin (`git -C <repo> status -sb` + `rev-parse`) + dirty-file count; build freshness (mtime of `Fizzygum-builds/latest/index.html` vs newest `Fizzygum/src/**/*.coffee` mtime → "FRESH"/"STALE"); test count (`ls Fizzygum-tests/tests | grep -c '^SystemTest_'`); zombie test-browser count (`pgrep -cf "Chrome for Testing|chrome-headless|ms-playwright"`); the current content of every `/tmp/fg-*.verdict`. Target: <2 s from any cwd.
- `fg killz` = the existing internal `kill_browsers()` exposed as a command (audit sessions found ~160 accumulated Chromes once — from manual harness invocations that bypassed the runners' startup reaper).

Then update the umbrella `CLAUDE.md`: post-compaction / session-start re-orientation = `fg status`, not hand-rolled git/greps (the audit found this ritual re-derived by hand ~6×/day). Acceptance: run it, verify every field against manual checks once.

---

## P6 — Capstone/gate shard-drop auto-retry (two false alarms + one 22-min hang in the week)

The capstone gate (`Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh`) runs an embedded suite (historically `--shards=6`) that occasionally **drops/stalls a shard under load** ("shards done 4/6", one 22-min 0%-CPU coordinator hang on 2026-07-05; both times the isolated re-run passed in ~1.2 min). Fix in the gate script (and check the tiernaming/settle gates for the same embedded-suite pattern):

1. Detect the incomplete-shard outcome distinctly from a real test failure (the runner already reports "shards complete: D/N" and per-shard stall kills — parse that).
2. On shard-drop with zero failed tests: retry ONCE with `--shards=3`.
3. Exit codes: 0 = pass; 1 = real failure; **3 = infra (shard-drop twice)** — and make fg's gauntlet report exit 3 as "gate infra flake — re-run" rather than a red FAIL.

Acceptance: normal green run unchanged; simulate a drop by killing one shard's browser mid-run (pkill one PID) → gate retries and passes; wall-clock overhead on the retry path bounded (~+2 min).

---

## P7 — The lessons ledger: promote hard-won diagnostics into repo docs + two runtime asserts

Each item below cost 30 min–2 h once in the audited week and lives only in session memory today. Docs changes are zero-risk; the two asserts need a gauntlet.

| # | Where | What to add |
|---|---|---|
| a | `Fizzygum-tests/DETERMINISM.md` | "Buffer+blit vs direct-draw is NOT float-associative even at integer offsets: direct draw bakes position into the CTM (`a·dim + pos + w/2`) while buffer+blit computes at origin and adds the offset — IEEE-754 rounding diverges for some sizes (W=200 diverged, W=70 didn't; C1 clock incident 2026-07-09, ~2 h). Never trust an analytic byte-identity argument for a back-buffer change: brute-force sweep sizes/positions first." |
| b | `Fizzygum-tests/DETERMINISM.md` | "Screenshot macros CANNOT catch broken-rect staleness: `readyForMacroScreenshot` forces `world.fullChanged()` before every capture, erasing exactly the staleness you're hunting. Use an incremental-vs-full-repaint `getImageData` pixel-diff value assertion; worked example: `SystemTest_macroClosingRotatedIslandChildClearsFootprint`." (Exists as memory `broken-rect-staleness-invisible-to-screenshots`; copy it into the repo doc.) |
| c | `Fizzygum-tests/DETERMINISM.md` | "Passes-alone-but-MIS-RENDERS-in-suite ⇒ suspect `_resetWorldNoSettle` leaving a world-level ephemeral Set/Map uncleared (2026-07-10 R2: `widgetsToBeHighlighted` family). Check teardown BEFORE hypothesizing load-sensitivity." (memory: `resetworld-state-leak-between-tests`) |
| d | `Fizzygum-tests/DETERMINISM.md` | "Pixel forensics: exclude the desktop clock region (or any `steppingWdgts` member) from diffs — clock ticks repeatedly masqueraded as the bug under investigation (2026-07-10, three separate times)." |
| e | `Fizzygum-tests/CLAUDE.md` (conventions) | "Before hypothesizing a paint/latency bug in a widget, check `world.steppingWdgts` membership and any `step()`/`@fps` — example: the sample plots animate BY DESIGN (2026-07-07, ~40 min misdiagnosis)." |
| f | `Fizzygum/docs/serialization-duplication-reference.md` | "`@serializationTransients` covers the file Serializer ONLY. The in-memory DeepCopier skips a property iff its VALUE exposes `rebuildDerivedValue` — a transient without it crashes `deepCopy` (`this[property].deepCopy is not a function`, SW3D port 2026-07-08). Stamp a no-op `rebuildDerivedValue` on runtime-only objects." |
| g | Root `CLAUDE.md` of BOTH source repos | The never-`git stash` rule from §0.2, with the incident date. |
| h | assert in `Widget.add` (find it: `grep -n "  add:" Fizzygum/src/basic-widgets/Widget.coffee`) | The signature takes (widget, position, layoutSpec, beingDropped); a 5th/6th positional arg was silently ignored and a caller relied on it (2026-07-06, offset no-op bug). Add an arguments-length check that throws in the harness/dev build. |
| i | assert in `MenuItemWdgt.trigger` | `@target[@action]` requires `@action` to be a STRING method name; passing a function closure fails obscurely (2026-07-06; `SliderWdgt` had the same latent misuse). Assert `typeof @action is 'string'` with a pointed message. |

⚠ Items h/i add methods/lines to widely-shared classes → they may trip the P2 inspector churn; sequence P7 h/i AFTER P2, or budget one benign inspector recapture. Verification for h/i: full gauntlet; for docs: none.

---

## P8 — Multi-session hygiene (OPTIONAL — lowest priority)

Evidence: parallel Claude sessions on the same tree caused stray uncommitted files from a sibling session to hover around ~6 consecutive commits (explicit-path staging + verify each time), ~10 "file modified since read" edit failures on shared plan/memory docs, and repeated MEMORY.md trim loops. Options, cheapest first:

1. **Append-only convention for shared plan docs:** live status goes in a dated `## Status ledger` section at the BOTTOM (append-only); prose above is edited only by the session that owns the arc. Document in the plan-authoring conventions.
2. **MEMORY.md index lines:** fixed terse template (one line: title + hook, all detail in the topic file) — stops the over-budget trim-check-trim loops.
3. **Commit-time stray-file guard:** a LOCAL, uncommitted `.git/hooks/pre-commit` in each source repo that prints the staged file list and aborts if it contains paths under `docs/` not named on an `FG_COMMIT_DOCS_OK` allowlist env var. (Heavier; only if 1–2 prove insufficient.)
4. Per-session git worktrees: rejected for now — the build hard-codes `../` sibling paths, so worktrees need a full parallel umbrella; revisit only if contamination actually bites a commit.

---

## §9 Execution order, effort, and the verification matrix

| Phase | Effort | Verification needed | Depends on |
|---|---|---|---|
| P1 pre-audit + parallel gauntlet + paint shards + presuite | 3–5 h | §P1.6 gate (3×serial vs 3×parallel + induced failure + homepage) | — |
| P3 recapture hardening | 1–2 h | §P3 acceptance + 1 gauntlet | — |
| P5 `fg status`/`killz` | 30 min | manual field check | — |
| P6 gate shard-drop retry | 1 h | simulated drop + green run | — |
| P4 `fg lint` + scanner fixes | 2–4 h | planted true/false positives + gauntlet | — |
| P2 inspector churn | 2–6 h (investigation-dependent) | no-op-method probe → zero churn (or one-command ritual) | owner approval if option (i) |
| P7 lessons ledger | 1–2 h | docs: none; asserts: gauntlet | P2 (for h/i) |
| P8 hygiene | 0.5–2 h | none | — |

Suggested order: **P1 → P3 → P5 → P6 → P4 → P2 → P7 → (P8)**. Each phase is independently landable; stop-anywhere is safe. Nothing here changes reference images except P2 option (i) — which requires explicit owner approval per §0.2.

Standing rules while executing: verify with `fg presuite`/`fg suite` during iteration, full gauntlet at each phase close; never write "verified"/"byte-identical" into this doc before the corresponding gate actually passed (owner rule, memory: `no-conclusions-before-evidence`); after 2 failed fix-shapes on any item, STOP and re-frame rather than trying a third variant (memory: `stop-iterating-fix-shapes-after-two-falsifications`).

---

## Status ledger (append-only)

- **2026-07-12 16:45 — ARC COMPLETE (P1 P3 P5 P6 P4 P2 P7 all closed; P8 skipped as optional —
  its cheapest item, the append-only status-ledger convention, is adopted de facto by this very
  section).** End-of-arc ritual on the final tree: 3× `fg gauntlet` all-green with zero retries
  (**4m14s / 4m44s / 4m28s** — vs ~17 min before this arc) + `fg homepage` green. Headline numbers:
  full gauntlet ~17 → ~4.5 min; inner loop `fg presuite` ~2–3.5 min; `fg lint` ~2 s pre-build;
  `fg status` 0.3 s re-orientation; inspector-churn ritual = one ~20 min background command.
  All changes uncommitted, awaiting owner review; umbrella-local tooling (fg + hook + root
  CLAUDE.md) is repo-external by design.

- **2026-07-12 ~15:00 — P1 COMPLETE, §P1.6 acceptance gate PASSED.** Suite is now **243 tests** (the
  238 above was written a day earlier). Implemented exactly as designed plus three additions the
  acceptance runs motivated: (a) `run-paint-audit.js --shards` got a per-shard 1 s boot stagger + one
  fresh-browser re-boot retry, and its sharded gate additionally requires sum(checked)==probed total;
  (b) `run-all-headless.js` got a shard boot stagger (i×750 ms) + ONE reload retry on boot-timeout —
  the "boot storm" class (`ReferenceError: CoffeeScript is not defined`, a dropped `<script>` over
  `file://` under many concurrent browser boots) fired twice during acceptance; (c) the serial path
  preserves a failed leg's log as `/tmp/fg-<leg>.log.serial-fail.log` (a SER-run false-red was
  undiagnosable because later runs overwrote the leg log). Gate results: 3× parallel all-green
  (4m12s / 4m22s / 5m10s — target was ≤8, stretch 6), 3× serial all-green, failed-test counts 0 and
  paint checked=243 identical everywhere; induced-failure drill (reference pair renamed) correctly
  hard-FAILED dpr1+webkit+capstone after each leg's solo serial retry also failed, exit 1; `fg
  homepage` green; `bash -n` clean. Honest caveats: (i) one parallel run passed via the designed
  retry path (boot-storm shard, 0 failed tests) and one serial run false-redded on the PRE-EXISTING
  shard-drop class (7/8 complete, all 243 played, 0 failed) — both BEFORE the boot hardening; the
  final 3+3 tally uses the post-hardening reruns for the affected cells, verdict logic unchanged
  throughout. (ii) The drill also discovered the build's `check-refs` gate catches a HALF-broken
  reference (orphaned .js or .png) at build time — only a fully-absent pair reaches the suite legs.
  `fg presuite` measured **3m32s** (target ≤4). Bonus finding for P6: the shard-drop false-red on the
  serial path is exactly the class P6's exit-3 semantics will declassify; ALSO
  `end-of-cycle-audit/audit-one.sh` hardcodes `AUDIT=scripts/.scratch/audit` while the capstone gate
  counts `scripts/.scratch/capstone-gate` — its shard-miss recovery loop can never repopulate the
  counted dir (currently masked by the gate's suite_rc hard-fail). Fix in P6.
- **2026-07-12 ~15:00 — P3 IMPLEMENTED, acceptance pending** (ran during the P1 matrix, machine-idle
  time): pre-flight manifest check + one auto full build (gap 1), silent-empty per-image guard using
  the harness's own `takeScreenshot_InputEvents_Macro` extraction (gap 4), bounded auto-retry
  clean→drop-rebuild→capture→publish→verify, max 2, default-clean flow only (gap 2), `--no-build`
  HARD ERROR (gap 3 — no consumer scripts existed; the author-macro-test skill doc already warns
  against it). §P3 acceptance drills still to run.
- **2026-07-12 ~15:00 — P7 docs a–g LANDED** (zero-risk, done while the P1 matrix ran):
  DETERMINISM.md §2c/§2d/§3f + the §4-step-2 clock-exclusion bullet; never-git-stash in both repos'
  CLAUDE.md; steppingWdgts animate-by-design note in Fizzygum-tests/CLAUDE.md; the
  `@serializationTransients`-vs-DeepCopier asymmetry in `docs/serialization-duplication-reference.md`
  §5. Items h/i (runtime asserts) remain, sequenced per the P2 note below.
- **2026-07-12 ~15:15 — P3 acceptance PASSED** (all four drills): (c) `--no-build` hard-refused exit 2;
  (a) brand-new cloned test dir → first `fg recapture` succeeded with ZERO manual intervention (the
  pre-flight detected it missing from the built manifest and auto-built once); (b) 2-image test
  (`macroBoxTransparencyAndColorChanging`) recaptured — all 4 js+png pairs written, and the recapture
  was **byte-identical to the committed refs** (git clean afterwards — deterministic capture
  confirmed); (d) throwaway deleted, `fg presuite` green (115 s). P3 COMPLETE.
- **2026-07-12 ~15:10 — P5 COMPLETE.** `fg status` (read-only, 0.27 s measured: per-repo
  branch/sha/dirty/ahead-behind, build FRESH/STALE via find-newer, test count, leftover-browser
  count, all fg verdicts) + `fg killz`; umbrella CLAUDE.md re-orientation recipe updated. One bug
  found live (exit-1 from a trailing `[ … ] &&` guard) and fixed.
- **2026-07-12 ~15:40 — P6 COMPLETE.** New shared `scripts/lib/audited-suite-with-infra-retry.sh`
  (`run_audited_suite`): the infra shape = runner exit≠0 AND "failed: 0" AND "shards complete D/N"
  with D<N → ONE retry at `--shards=3`; second drop → exit 3. Wired into all THREE gate scripts
  (tier-naming + settle gates additionally now HARD-fail on a real embedded-suite failure — parity
  with capstone's 2026-07-04 hardening; previously they silently ignored suite_rc). `audit-one.sh`
  takes the audit dir as arg 2 (fixes the wrong-dir recovery found in P1.4). fg maps a gate exit 3
  to `INFRA-FLAKE` (pass-with-warning) in both gauntlet paths. Drills: settle gate green through the
  helper (243/243); capstone with a shard's MAIN browser killed at T+55 → "lost the page mid-run",
  5/6+0-failed classified INFRA → `--shards=3` retry → PASSED exit 0 (~+2.4 min, within budget).
  NOT physically drilled: the double-drop exit-3 path (needs two synchronized kills; wiring is the
  same helper's tail + fg's rc==3 branch, both bash-n'd and code-reviewed). NB the victim-selection
  lesson for future drills: `pgrep -f "Chrome for Testing"` matches YOUR OWN command wrapper (the
  pattern text is in its cmdline) — select main browsers with the self-excluding bracket pattern
  `[C]hrome for Testing.app/Contents/MacOS` + `grep -v -- --type=`.
- **2026-07-12 ~15:50 — P4 COMPLETE.** (P4.1) `fg lint`: node --check every git-CHANGED test .js +
  the coffee syntax gate (measured 1.5 s FULL-tree, so no per-file scoping needed) when any .coffee
  is dirty; wired fail-fast into gauntlet+presuite; planted backtick-in-macro-comment caught
  instantly with a pointed error. (P4.2) dead-methods scanner: the blind spot was the naive
  `stripComment` cutting each line at the FIRST `#` — so `"#{@foo()}"` interpolation was discarded
  as a comment; now cuts at the first `#` not followed by `{`; self-test extended (10/10); live
  proof: allowlisted `getName` (sole ref = `Macro.coffee:81` inside `#{@getName()}`) is now seen as
  referenced — stale allowlist entry deleted; planted probe: interpolation-only ref NOT flagged,
  truly-dead still flagged exit 1. (P4.3) layering [G] is now NAME-QUALIFIED: definitions keyed
  (class, method) via the one-class-per-file invariant, split settling/plain; @-SELF calls resolve
  up the `class X extends Y` chain to the nearest definer (a 'plain' hit — the TransformSpec.setScale
  shape — is clean); dotted calls stay conservative but the violation now NAMES the plain definers +
  the sanction recipe. Tree scans identical pre/post (48 wrappers, 0 violations); planted probes:
  plain-self SKIPPED, settling-self FLAGGED, inherited-through-extends FLAGGED, dotted FLAGGED with
  the note. Probe gotcha for posterity: checkFile skips method HEADER lines, so a probe's call must
  sit on a BODY line, not inline after `->`.
- **2026-07-12 ~15:30 — P2 PROBED (both shapes) + option (ii) IMPLEMENTED.** Empirical churn sets
  (probe = build + dpr1 suite with a no-op addition to Widget, then reverted; tree restored
  byte-identically):
  - **no-op PROTOTYPE METHOD on Widget → exactly 1 failing test**:
    `macroDuplicatedInspectorDrivesCopiedTargetOnly` — it inspects a DIRECT Widget instance, so
    Widget:: members are its own-prototype members and the default inherited:off filter does not
    hide them. Every other inspector test is already method-churn-proof (the §P2.1 premise was
    wrong for methods).
  - **no-op CONSTRUCTOR-ASSIGNED INSTANCE FIELD on Widget → 15 failing tests** (the real churn
    class): macroAddEditSaveRenameRemoveProperty, macroAnalogClockInspectEdit,
    macroDuplicateComplexWidgetRidesHand, macroDuplicatedInspectorDrivesCopiedTargetOnly,
    macroDuplicatedInspectorsCloseIndependently, macroInspectorRejectsDrops,
    macroInspectorResizingOKEvenWhenTakenApart, macroInspectorScrollbarUnplugged,
    macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways, macroMultilineTextInputScrollsWell,
    macroNakedInspectorRendersResizesAndEdits, macroPickingUpPartsFromInspector,
    macroResizingPristineInspector, macroSimpleDocumentHandlesOldInspector,
    macroWrappingTextFieldResizesOK.
  Option (i) as planned is MOOT (hide-inherited is already the inspector default and cannot hide
  instance fields). **Implemented option (ii): `fg recapture-inspector`** — one command recapturing
  the probed 15-test set at dprs 1+2 through the P3-hardened flow (~2.5 min/test ≈ ~40 min,
  backgroundable; deterministic capture ⇒ an unchanged member list recaptures byte-identically).
  OPEN OWNER QUESTION (no action taken): the one method-churn test could become method-churn-proof
  by inspecting a leaf-fixture instance instead of a direct Widget — a semantic test change + 1
  recapture; and a "hide _-prefixed fields" inspector default would shrink the field-churn set —
  a visible framework change + mass recapture. Both left undone pending an explicit owner decision.
- **2026-07-12 ~16:00 — P7 h FALSIFIED and REVERTED; P7 i retained.** The P7h arity assert in
  `Widget.add` (throw on >4 positional args) fired across dozens of tests — and the failures were
  CORRECT arity-5/6 calls: the tree has a live polymorphic drop-position contract,
  `add(aWdgt, position, layoutSpec, beingDropped, unused, positionOnScreen)`, whose 6th arg is
  genuinely CONSUMED by the SimpleVerticalStackPanelWdgt / HorizontalMenuPanelWdgt / ToolPanelWdgt /
  ScrollPanelWdgt overrides (insertion-point from the drop's screen position; callers:
  `ActivePointerWdgt.coffee:494`, `ScrollPanelWdgt.coffee:226`). The base `Widget.add` ignoring the
  extras IS the design (dispatch may land on any override), so an arity tripwire on the base is
  wrong in kind — reverted, not re-tuned; do NOT re-attempt. (The 2026-07-06 incident evidently
  predates/motivated this convention.) Two build-gate lessons from the attempt: the thin-wraps gate
  demands the canonical one-liner wrap — a pre-settle assert needs `# thin-wrap-exempt: <reason>`;
  and the dead-methods gate would flag a no-op probe method, so probes need a self-reference.
  P7 i (ButtonWdgt.trigger string-action assert — the plan said MenuItemWdgt, but the live
  `@target[@action]` dispatch is in ButtonWdgt, which menu items inherit) drew ZERO hits across the
  same full suite run and stays in.
- **2026-07-12 16:19 — P2 option (ii) acceptance PASSED.** `fg recapture-inspector` ran the full
  15-test set end-to-end: exit 0, **19.6 min** (not the estimated ~40 — the hardened per-test flow
  is faster than budgeted), every test re-verified at both dprs, and `git status` over tests/ came
  back EMPTY — the recapture of the unchanged member lists was byte-identical, as determinism
  predicts. The churn ritual is now: one backgrounded command + the task notification. P2 CLOSED
  (the two option-(i)-variant owner questions above remain open, no action taken).
- **2026-07-12 ~15:00 — P2 premise CORRECTED by code investigation (probe still to run):**
  `InspectorWdgt` defaults `showingInherited: false` (line ~39; filter at ~199; `spawnInspector` uses
  defaults), so §P2.1's "any method added to Widget shifts the rendered list" is likely WRONG for
  prototype methods — those are filtered out by default. The churn driver is almost certainly
  **constructor-assigned INSTANCE FIELDS** on widely-instantiated classes: they pass the
  `prop not of @target.constructor.prototype` disjunct regardless of the inherited toggle. The §P2.2
  probe must therefore test BOTH shapes (no-op `Widget::` method AND no-op Widget instance field);
  option (i)'s "hide inherited members mode" is ALREADY the default and cannot fix field churn.
  Implication for P7 h/i: method-only additions may cause zero churn (verify via the probe before
  budgeting a recapture).
