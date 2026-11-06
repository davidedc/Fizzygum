# Unrun checks: every check the workspace relies on runs, and the two places reliance is written down are held to it

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**

**STATUS (2026-11-06): CLOSED — Units 0, A, B, C, D done in one session, ARCHIVED.** Owner rulings: D1–D4 all (a),
as recommended (§3). One independent review (R1–R10) folded in; its serious finding (R1: the prelude-install
self-test played no test) is fixed and proven by plant.

**Closing gates:** `fg gauntlet` 20/20, no retries, 904 s (after the review fixes); `fg presuite` OK; `npm run selftest`
OK (12 self-tests, 217 cases); `fg homepage` OK (build_it_please.sh changed; the new steps run under every profile).
The text below is the plan as written before execution (§1's numbers were measured on Fizzygum `cd24c28d` /
Fizzygum-tests `ad36d1185`); the ledger records where execution corrected it. The probes live under
`Fizzygum-tests/.scratch/unrun-checks/`. Filed residue: BACKLOG, section "archive/unrun-checks-plan.md".

**MANDATE.** Eliminate the class, not the two instances that were filed. The class is "a check that exists and that
nothing runs", which can rot (a self-test), go stale silently (a stale-name check), or, worst of all, be NAMED as the
guard that keeps something else honest while never firing (a sanction). Wiring up `aim-census.js` and five
`--self-test` flags by hand would close two BACKLOG lines and leave the class exactly as possible as before.

---

## 0. Orientation

- **The workspace.** `Fizzygum-all/` holds three sibling git repos: `Fizzygum/` (framework + `build_it_please.sh`, which
  runs ~31 static gates from `buildSystem/`), `Fizzygum-tests/` (the SystemTest suite + the Node rigs in `scripts/`),
  and the generated `Fizzygum-builds/`. The umbrella also holds `fg`, a LOCAL, UNCOMMITTED bash wrapper (in no repo)
  that owns the two verification tiers: `fg presuite` (build + dpr1 suite ∥ paint audit ∥ fracplane) and
  `fg gauntlet` (build + 19 legs in four waves; the leg bodies are the `run_leg` function's `case` arms). Gate index:
  `docs/architecture/lint-and-static-checks.md`.
- **The immediately prior arc** (`docs/archive/tests-repo-readers-plan.md`, CLOSED and pushed `cd24c28d` /
  `ad36d1185`) filed the two findings this plan exists for (BACKLOG, section "archive/tests-repo-readers-plan.md"):
  1. the buildSystem gates' `--self-test`s are run by nothing: not the build, not `fg`, not `npm run selftest`;
  2. `aim-census.js` is run by no gate, so its stale-name checks fire only on a hand run, although `check-hand-lists`
     accepts its 7 sanctions.
- **The sanction rule's origin.** `check-hand-lists.js` (hand-kept-lists arc, Tiers 3+4) makes every string list that
  names classes or members a DECLARATION, a SANCTIONED list (`# hand-list-sanctioned: <what fails>`) naming a REAL
  guard, or an UNSANCTIONED one counted against a per-repo ratchet. "Real" is resolved mechanically and means EXISTS.

### 0.1 THE CRITICAL REFRAME

The two filed findings are the visible half. Measured across both repos (§1), the class has nine members, and three of
them are claims in code or docs that a check runs when it does not:
- a sanction's guard resolves because its FILE EXISTS (18 of 40 sanctions rest on guards nothing runs);
- `layout.md` and `lint-and-static-checks.md` both say the paint-readonly gate runs under `fg gauntlet`; nothing runs it;
- the tier-naming gate's header describes "the live self-test" that plants a reacting leaf; no such code exists.

Reliance on a check is WRITTEN DOWN in exactly two machine-readable places: a SELF-TEST (the checker relies on it) and a
SANCTION (a hand list relies on its guard). Both can be held mechanically, by DERIVING what runs from the files that run
things, never by a list of what runs. Prose claims (a doc saying a gate runs) cannot be checked mechanically; this plan
corrects the two it found, and the rule makes them rarer, because a check the docs point at will now be one that runs.

---

## 1. Findings (code quotes; lines drift, grep the quoted text)

### F1. The buildSystem gates' self-tests: run by nothing (~0.1 s for all five)

Six buildSystem scripts carry a self-test as a CLI flag, and no invoker passes it:

| Script | Shape (quoted) | Module-safe? | Time |
|---|---|---|---|
| `check-dead-methods.js` | `if (process.argv.includes('--self-test')) {` at top level | no (top-level scan) | 0.02 s |
| `census-public-private-calls.js` | inside `if (require.main === module) {` | yes | 0.02 s |
| `check-hand-lists.js` | `function main(argv) { if (argv.includes('--self-test')) return selfTest();` | yes | 0.02 s |
| `check-part-edges.js` | `// ---- --self-test: every clause both ways` then a top-level `if` | no | 0.02 s |
| `check-unresolved-sends.js` | `// ─── --self-test: prove the pure parts` then a top-level `if` | no | 0.02 s |
| `what-pins-core.js` | `const SELFTEST = argv.includes('--selftest');` (a SECOND spelling) | no | **5.1 s** |

Two libs own cases that only these flags run: `lib/method-references.js` and `lib/tests-repo-code.js` each export
`selfTest(log)`, called by BOTH `check-dead-methods --self-test` and the census's (so twice, when anyone runs them).
`what-pins-core.js --selftest` takes 5.1 s because it calls `analyse()` ~8 times, each re-reading the whole tree
(the plain tool takes 0.65 s).

### F2. The tests repo's `*-selftest.js`: a hand list, run by hand (0.69 s for all twelve)

`Fizzygum-tests/package.json`:
```
"selftest": "node scripts/lib/png-selftest.js && node scripts/lib/safe-exit-selftest.js && node scripts/classify-diff-selftest.js && … && node scripts/lib/gate-tokens-selftest.js",
```
Twelve files match `scripts/**/*-selftest.js` and all twelve are on that line today, but the line is a HAND LIST: a
thirteenth file is silently omitted. And `npm run selftest` itself is run by nothing automatic: the build does not run
it, no `fg` leg does; arc briefs say "run it at close". The verdict lines vary (`gate-tokens-selftest OK`,
`[census] self-test PASS`, `SELFTEST OK`), so "printed nothing" and "passed" are not told apart.

### F3. `aim-census.js`: 7 sanctions on a census nothing runs (0.23 s)

Header: "A MEASUREMENT, NEVER A GATE: it exits 0 whatever it finds in the tests; 1 when its own tables disagree with
Fizzygum's source (an AIM-CENSUS problem); 2 only on its own operational error". Seven sanctions, e.g.
`// hand-list-sanctioned: aim-census.js reports AIM-CENSUS STALE NAME for a name here no class in src or the harness
declares`. Exit 0 today; a planted stale row was seen to print the token (2026-11-06).

### F4. `check-hand-lists.js`: a guard counts because its file EXISTS

Header, "HOW A SANCTION'S GUARD IS RESOLVED — mechanically, by at least one of: (a) the basename of an existing gate or
rig file … (b) `SystemTest_<name>` with an existing … directory; (c) an UPPER_SNAKE token … that occurs in some
scanned file OUTSIDE every sanction's own text". `gateFileNames()` adds every `.js` under `buildSystem/` and
`buildSystem/lib/` and every `.js`/`.sh` under `Fizzygum-tests/scripts/`. ⚠ The header already says "Resolution proves
the guard EXISTS, not that it covers the list"; it does not prove the guard RUNS either.

**Measured: the sanction census under "a guard must RUN"** (probe `.scratch/unrun-checks/runs-closure.js`, roots and
grammar in §4 Unit 0). 40 sanctions; **22 resolve to a guard that runs, 18 to guards that never run**:

| Sanctions | Guard named | Why it never runs |
|---|---|---|
| 7 × `Fizzygum-tests/scripts/aim-census.js` | `aim-census.js`, `AIM-CENSUS` | F3 |
| 1 × `Fizzygum/buildSystem/what-pins-core.js:423` | `what-pins-core.js` | its text says "(run on demand: fg whatpins --selftest)" |
| 1 × `Fizzygum/src/boot/globalFunctions.coffee:162` (`META_SYSTEM_SOURCES = ["Mixin", "Class"]`) | `smoke-boot-headless.js` | run by `fg homepage` and `build_and_smoke.sh` only, neither a tier |
| 6 × `scripts/end-of-cycle-audit/layout-audit-prelude.js` | `LAYOUTAUDIT_STALE_NAME` | the prelude is injected only by the hand-run `run-audit-loop.sh` / `audit-one.sh` |
| 3 × `scripts/audit-preludes/revisit-trace-prelude.js` | `LAYOUTAUDIT_STALE_NAME` | named only in `revisit-gate.js`'s failure MESSAGE ("PRELUDE_JS=…revisit-trace-prelude.js node …") |

A 19th, `classify-diff-selftest.js:58`, names `classify-diff-selftest.js` and resolves only once self-tests run (F2).

### F5. The paint-readonly gate: documented as a gauntlet gate, run by nothing (green today, 124 s)

`docs/architecture/layout.md`: "Plus the **paint-readonly gate**: paint schedules no layout (§1). These dynamic gates
run under `./fg gauntlet`". `lint-and-static-checks.md` §3: "siblings of the end-of-cycle / paint-readonly gates and
wired into `fg gauntlet`". `fg` names neither `run-paint-readonly-gate.sh` nor its prelude, and no other prelude arms
`auditPaintTimeLayoutScheduling`. Run by hand now: `PAINT-READ-ONLY GATE PASSED — zero layout schedules during paint
across 373 tests` (prelude installed 373/373, flag armed 373/373), 124 s standalone.

### F6. The cache-oracle gate: a superseded standalone, with the only bite-proof of the oracle

`run-cache-oracle-gate.sh` runs the suite with `doubleCheckCachedMethodsResults` on and describes the product as
"a mismatch fires `alert "<name> is broken"`, which the prelude reroutes to console.error('CACHEORACLE-FAIL …')". The
product now emits `console.error "CACHED_DERIVATION_DIVERGED -- root is broken"` (TreeNode.coffee and
TransformFrameWdgt.coffee), which the fail-closed runners gate; and the `settle` gauntlet leg's prelude already arms
the flag ("RIDER: the prelude also flips world.doubleCheckCachedMethodsResults … deliberately the gauntlet's ONLY
twins-live pass"). So the standalone gate is a stale twin of a rider that runs. Its `CACHE_ORACLE_SELFTEST=1` mode
(the plant `cache-oracle-selftest-plant.js`, "⛔ NOT a standalone prelude") is the only proof that the oracle BITES,
and nothing runs it.

### F7. `heap-forensics.js --selftest`: a tool's proof, run by hand (3.5 s, needs the built page)

"`--selftest` PLANTS a closure-held destroyed widget … and requires itself to find it end-to-end … run it after
touching the tool". Measured: `heap-forensics SELFTEST OK`, 3.5 s.

### F8. `check-doc-narration.js`: a HARD-ZERO ratchet nothing runs (sub-second)

`lint-and-static-checks.md` §3b-docs: "It is a RATCHET at a HARD ZERO … Not on the build — docs prose should not block
a build; run it with `fg doc-narration`." No gauntlet leg runs it, so a narrating line lands silently.

### F9. Prose that claims a check

The tier-naming gate's header: "The live self-test plants a __commit* that REACTS (fires a _reLayout*) and confirms the
audit throws." `grep -rniE "self-?test|PLANT" scripts/tier-naming-audit/` finds only that line.

### Also measured (not in the class, or by design)

- **The 12 audit preludes all install clean** on the current build: each, injected with `PRELUDE_JS` on
  `SystemTest_macroAnalogClockInspectEdit`, prints its `installed` line and the test passes (4–5 s each, 59 s serial).
  Eleven print `LAYOUTAUDIT installed …`; `coalescing-measure-prelude.js` prints `CMEAS: installed …`.
- The `census-*.js` tools are advisory by design (§3c: "all exit 0"): not checks.
- `run-atlas-fuzz.js` is owner-declined as a gate (nondeterministic by construction); its verdict logic's self-test is
  in F2's set.
- `derive-inspector-churn-set.js --check` (3 min) and `swcanvas-hidpi-headless-check.js` are on-demand checks that
  nothing relies on (no sanction, no doc claim that they run). They stay on demand.

---

## 2. The argument

A check's value is that its failure lands on the change that caused it. That needs the check to run where changes are
verified: the BUILD (every build) or the COMMIT POINT (every gauntlet). A check run only on demand defers its failure
to the next person who happens to run it, attributes the drift to the wrong change, and, when it is a self-test, lets
the checker be wrong on every build in between. The two filed findings are both this.

Reliance on a check is written into code in two forms, and each can be held mechanically:
1. **A SELF-TEST** is relied on by the checker it proves. Rule: every self-test is DISCOVERED by one naming convention
   and RUN at a tier; one that prints no case count fails. No list of which scripts have one.
2. **A SANCTION** relies on the guard it names. Rule: the guard must be one that RUNS, derived from the files that run
   things (the build script, the discovered self-tests, the `fg` legs), never from a list.

Everything else in §1 is an instance either rule exposes (F3, F4's 18) or one the survey found beside them
(F5–F9), fixed in place. Why now: the tests-repo readers arc found F1/F3 while relying on those self-tests and that
census; the next author to rely on one will not know it has not run.

---

## 3. Owner decisions (ONE round; recommendation first in each)

**D1. How self-tests are found and run.**
- **(a) RECOMMENDED: ONE file convention.** A self-test is a file `<subject>-selftest.js` beside its subject (the shape
  the tests repo already uses 12 times); one that needs the built page is `<subject>-selftest-headless.js` (the repo's
  `-headless` suffix already means "boots a page"). ONE runner, `Fizzygum/buildSystem/run-selftests.js`, discovers
  both repos' files from ONE table of conventions (`buildSystem/lib/what-runs.js`, Unit 0):
  - the BUILD runs every `-selftest.js` (both repos, ~1–2 s total), first among the gates;
  - a new gauntlet leg `selftests` runs every `-selftest-headless.js`;
  - `npm run selftest` becomes that runner over the tests repo's node tier, with no list.
  Every self-test ends with one verdict line carrying its case count; exit 0 without it, or with zero cases, fails.
  The flag spellings (`--self-test`, `--selftest`, `CACHE_ORACLE_SELFTEST=1`) are retired, and the runner fails on a
  self-test flag found in any script's code, so a self-test cannot hide outside the convention. Cost: the six gates'
  self-tests move into files, so three gates and what-pins-core become require-able (`require.main` guard, exported
  internals).
- (b) Discover BOTH shapes (files and a `--self-test` flag found in code). Less churn, but two conventions for one thing
  and a discovery that has to read code.
- (c) Name the self-tests in the build script. Rejected in advance: a hand list of exactly the kind this arc removes.

**D2. What a sanction's guard has to be.**
- **(a) RECOMMENDED: a guard counts only if it RUNS.** `check-hand-lists` asks `lib/what-runs.js` for the run set:
  - roots: `build_it_please.sh`, every discovered self-test, and, when the umbrella's `fg` is present, the scripts its
    `fg_build`/`fg_suite`/`run_lint`/`run_leg` bodies invoke;
  - edges are INVOCATIONS, not mentions: in shell, a script path on a code line that is not `echo`/`printf`; in JS, a
    `require()`, or a script named inside a `path.join(…)`/`path.resolve(…)` call, which is how every launch site
    locates what it runs (help messages never build a path; measured: the spawn of `run-all-headless.js` and every
    prelude injection in the gate scripts use it, and the one false "runs" a mention-based reading gave was a help
    message).
  Guard (a) must be a run file, (c) a token some run file emits (outside sanctions), and (b) a `SystemTest_` (every
  `tests/` dir runs in the suite). A sanction whose guards all fail is `SANCTION_GUARD_NEVER_RUNS`, never ratcheted.
  Without `fg` (a clone of the repos alone), a sanction resting on a gauntlet-only guard is a NOTE (`UNVERIFIED`), the
  same rule the gate already applies when the tests repo is absent.
- (b) Move the gauntlet's leg-to-command table into a committed file that both `fg` and the gate read. One source,
  but it reshapes `fg` (legs with bespoke post-processing, e.g. `apps` greps `APPS OK`) for a fact the gate reads in
  ~30 lines.
- (c) Keep "exists" and fix only the 18. The class stays possible.

**D3. The 9 sanctions on the two hand-run diagnostic preludes** (F4: `layout-audit-prelude.js`,
`revisit-trace-prelude.js`; their `LAYOUTAUDIT_STALE_NAME` checks run when the prelude installs).
- **(a) RECOMMENDED: a headless self-test installs EVERY `*-prelude.js`** (discovered, the 12 of §1) on the current
  build and fails on any console error or a missing `installed` line. It runs in the `selftests` leg, ~25 s with one
  browser and a page per prelude. The 9 sanctions then resolve (their token is emitted by a file the run set reaches
  through that self-test's discovery), and every instrument is proven to install at every commit point, including
  the ones only a person injects.
- (b) Count those 9 lists under `BASELINE_TESTS` (0 → 9) as unsanctioned. Honest, but the ratchet rises.
- (c) Delete the sanctions and keep the diagnostics' lists unexamined.

**D4. The other unrun checks the survey found (F5–F9).** Scope:
- **(a) RECOMMENDED: all in this arc.**
  - F5 paint-readonly rides the `capstone` leg: its flag is armed in the capstone prelude and the capstone gate counts
    paint-time schedules too, as `settle` carries the cache oracle. One suite pass, no new browsers. Its standalone
    script and prelude are deleted, and the two docs tell the truth.
  - F6: the standalone cache-oracle gate and its prelude are deleted, superseded by the `settle` rider. The plant
    becomes `cache-oracle-selftest-headless.js`: one test under the settle prelude plus the plant must FAIL with
    `CACHED_DERIVATION_DIVERGED`, and the control without the plant must pass.
  - F7: heap-forensics' proof becomes `heap-forensics-selftest-headless.js`.
  - F8: `check-doc-narration.js` rides the `refs` leg (sub-second, no browser; commit point, not build, as its doc
    asks).
  - F9: the tier-naming header states what exists.
- (b) The two rules and the 18 sanctions only. F5–F9 go to BACKLOG.

---

## 4. Units (each: edit → run the touched gates directly → plants seen to fail, then pass → `fg build` → `fg presuite`)

Order: 0, A, B, C, D, Docs. Units C and D assume D3/D4 = (a); under (b) they shrink as stated.

### Unit 0. `buildSystem/lib/what-runs.js` — the one statement of what runs

- `CONVENTIONS`: the discovery table, `{ selftest: /-selftest\.js$/, selftestHeadless: /-selftest-headless\.js$/,
  prelude: /-prelude\.js$/ }`, each with its scan roots (`Fizzygum/buildSystem/**`, `Fizzygum-tests/scripts/**`;
  dot-dirs, `node_modules`, `__pycache__` skipped). `discover(kind)` is what the runners call.
- `runSet({ fgPath })`: the roots and invocation grammar of D2(a). A runner reached by the closure invokes every file
  its convention discovers: `run-selftests.js` → self-tests; the prelude-install self-test → preludes. `.py` files are
  leaves (their docstrings name shell scripts; none launches one). It returns `{ files, fgPresent }` and exits 2
  (house idiom: "a derivation finding nothing") if `build_it_please.sh` yields no invocation, or if `fg` is present and
  none of its four functions is found.
- `lib/what-runs-selftest.js`: a corpus in a temp dir. A `.sh` echo line naming a script does not run it, and a code
  line does. A JS `console.error('… x.js …')` does not, and `path.join(__dirname, 'x.js')` does. Plus a `require`
  chain, a discovered file reached through its runner, and an empty root (exit 2).
- Proof: on the real tree it reproduces the probe's 18 (§1 F4) exactly.

### Unit A (D1). Self-tests discovered and run

- `buildSystem/run-selftests.js [--headless] [--repo=fizzygum|tests]`: discovers through `what-runs`, runs each with
  `node` (cwd = its repo), requires exit 0 AND a final stdout line matching `/^\[[\w.-]+\] SELFTEST PASS — (\d+) cases?$/`
  with n ≥ 1. A missing line is `SELFTEST_NO_VERDICT`, n = 0 is `SELFTEST_VACUOUS`, and a self-test flag in any
  script's CODE is `SELFTEST_OUTSIDE_CONVENTION` (read with `lib/js-mask.js`/shell comment-stripping, so prose may
  mention one). Prints one line per file with its time. Exit 0/1/2.
- The moves (bodies unchanged, only their home):
  - `check-dead-methods.js`, `check-part-edges.js`, `check-unresolved-sends.js`, `what-pins-core.js`: each gets a
    `require.main === module` guard around its CLI and exports what its self-test calls;
  - `census-public-private-calls.js` and `check-hand-lists.js` export what theirs call;
  - the bodies go to `<gate>-selftest.js`;
  - `lib/method-references.js`'s and `lib/tests-repo-code.js`'s `selfTest(log)` go to `lib/<lib>-selftest.js`, run
    once each, no longer by two gates.
  - `what-pins-core-selftest.js` reads the tree ONCE and overlays each plant (target ≤ 1.5 s; if it cannot get there,
    measure and report before choosing a tier).
- Verdict line: a 10-line `buildSystem/lib/selftest-verdict.js` (`verdict(name, passed, failed)` prints and exits),
  required by every self-test in both repos (tests-repo scripts already require `Fizzygum/buildSystem/lib/*`, e.g.
  `smoke-boot-headless.js`).
- `build_it_please.sh`: a new block FIRST among the gates (before the syntax gate: a gate whose proof fails gives
  verdicts not worth reading), same shape as every gate (`if ! $noSyntaxCheck`, `$?` check, loud `exit 1`), running
  `node ./buildSystem/run-selftests.js`; its tests half runs when `../Fizzygum-tests` is present, on every profile,
  like `check-hand-lists`' tests half.
- `Fizzygum-tests/package.json`: `"selftest": "node ../Fizzygum/buildSystem/run-selftests.js --repo=tests"` and the
  `//selftest` note rewritten (no list).
- `fg_build`'s summary grep gains the self-tests line.
- **Plants** (each seen to FAIL, then pass restored; files under `Fizzygum-tests/.scratch/unrun-checks/`):
  1. a case flipped in `check-hand-lists-selftest.js` → the BUILD fails at the self-tests block;
  2. a new `buildSystem/plant-selftest.js` printing no verdict → `SELFTEST_NO_VERDICT`, and one printing 0 cases →
     `SELFTEST_VACUOUS`;
  3. `argv.includes('--selftest')` added to a scratch copy of a buildSystem script → `SELFTEST_OUTSIDE_CONVENTION`;
  4. a thirteenth `scripts/lib/plant-selftest.js` that fails → `npm run selftest` fails (the list could not have).

### Unit B (D2). A sanction's guard must run

- `check-hand-lists.js`:
  - `gateFileNames()` and `guardTokensOf()` read the run set from `what-runs` (tokens only from run files' text
    outside sanctions);
  - new problem `SANCTION_GUARD_NEVER_RUNS` (always fails), with `SANCTION_UNVERIFIED` when `fg` is absent and only a
    gauntlet-only guard would resolve it;
  - the census prints each guard as `runs`/`never runs`;
  - the header's "HOW A SANCTION'S GUARD IS RESOLVED" states the rule and its blind spot: a guard that runs but does
    not COVER the list still passes, as today;
  - its self-test corpus gains a sanction naming an existing-but-never-run rig.
- The 18:
  - **aim-census ×7**: the build runs `node ../Fizzygum-tests/scripts/aim-census.js --tables-only` (new flag: skip the
    per-test report, keep the table checks and the exit code; 0.23 s today), when the tests repo is present. Its
    header changes from "NEVER A GATE" to say exactly which half gates.
  - **what-pins-core ×1**: its sanction names `what-pins-core-selftest.js` (Unit A runs it).
  - **globalFunctions ×1**: re-sanctioned to a guard that runs. A stale name fails every boot, so every SystemTest
    fails: name `run-all-headless.js`, and keep the smoke as the second witness.
  - **the 9 prelude sanctions**: resolved by Unit C (D3 a). Under D3 (b), `BASELINE_TESTS` 0 → 9 with the reason in the
    constant's comment.
- **Plants:**
  1. a sanction in a `.scratch` file (via `--files`) naming `torture-headless.js` (exists, never runs) →
     `SANCTION_GUARD_NEVER_RUNS`;
  2. the same naming `run-all-headless.js` → passes;
  3. `fg` hidden (`--fg=/nonexistent`) → the gauntlet-only sanctions turn to UNVERIFIED notes, not failures;
  4. a planted stale row in aim-census's `VERBS` → the BUILD fails.

### Unit C (D3, D4 a). The headless tier

- `scripts/preludes-install-selftest-headless.js`: one browser, a page per discovered prelude, harness page, the
  prelude by `PRELUDE_JS`-equivalent injection, waits for its `installed` line (all 12 print one;
  `coalescing-measure-prelude.js` is renamed from `CMEAS: installed` to `LAYOUTAUDIT installed` so ONE pattern holds),
  fails on any console error, on a missing `installed` line, and on zero preludes found.
- `scripts/heap-forensics-selftest-headless.js`: `heap-forensics.js` gets a `require.main` guard and exports its
  selftest flow; `--selftest` is retired.
- `scripts/cache-oracle-selftest-headless.js`: two runs of one test. Settle prelude + plant must FAIL with
  `CACHED_DERIVATION_DIVERGED`; settle prelude alone must PASS. The plant moves beside it. Deleted:
  `scripts/cache-oracle-audit/run-cache-oracle-gate.sh` and `cache-oracle-prelude.js`.
- `fg`: a new wave-A leg `selftests` → `node "$FZ/buildSystem/run-selftests.js" --headless` (timeout 300), listed in
  `legs_pending` and `leg_headline`. ⚠ `fg` is local; its edit is in no commit; the plan's ledger records it.
- **Plants:**
  1. a prelude in `.scratch` that `console.error`s at install, copied under `scripts/` as `zz-plant-prelude.js` →
     the leg FAILS naming it;
  2. the cache plant's control flipped (plant omitted from the "must fail" run) → the self-test FAILS as vacuous.

### Unit D (D4 a). The rest of the survey

- **F5** paint-readonly → capstone rider:
  - the capstone prelude also arms `auditPaintTimeLayoutScheduling` and re-emits paint-time schedules in the shape
    `paint-readonly-prelude.js` uses;
  - `run-capstone-gate.sh` counts them, fails on any, and adds "paint flag armed N/N" to its coverage line;
  - delete `scripts/paint-readonly-audit/`.
  - **Plant:** a `PRELUDE_JS`-free scratch copy of a test whose macro forces a layout schedule during paint is not
    available, so plant at the product seam: a `.scratch` prelude appended after the capstone prelude that calls
    `_invalidateLayout` from a paint method → the capstone gate FAILS on a paint-time schedule.
  - Time the leg before/after (wave B is load-sensitive; the rider measured noise-level for settle's).
- **F8**: the `refs` leg body gains `&& to 60 node "$FZ/buildSystem/check-doc-narration.js"`. **Plant:** a narrating
  line in a scratch copy of an architecture doc (via its `--files`, if it has one; else a temporary line in a real
  doc, reverted) → the leg fails.
- **F9**: the tier-naming header line is corrected to state the coverage assertions it really has.

### Docs (in the same arc)

- `lint-and-static-checks.md`:
  - §3: new rows for the self-tests step and aim-census's table half;
  - the hand-lists row ("a REAL guard … resolved mechanically") becomes "a guard that RUNS";
  - §3 per-gate intro and §5's markers section state the two reliance rules;
  - §3b-docs: doc-narration runs in the `refs` leg;
  - the "siblings of the end-of-cycle / paint-readonly gates" sentence is corrected.
- `layout.md`'s gauntlet sentence.
- `Fizzygum/CLAUDE.md` and the umbrella `CLAUDE.md`: the gate count and the gauntlet leg list (+`selftests`).
- `Fizzygum-tests/CLAUDE.md`'s `npm run selftest` paragraph (discovered, not listed; the verdict protocol) and the
  heap-forensics `--selftest` line.
- `.claude/skills/*` that tell a session to run `npm run selftest` at close: it still works, and is no longer the only
  thing that runs those tests.

---

## 5. Cold-execution protocol and verification

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status`: both repos clean at the SHAs in the STATUS line (or later,
   with this plan's ledger explaining the difference).
2. Read §0.1, §1, §3; the owner's rulings are in the ledger. Re-run the probe
   (`cd Fizzygum-tests && node .scratch/unrun-checks/runs-closure.js --with-selftest`) and check that the 18 still hold
   before changing anything.
3. Units in order. Per unit:
   - run the touched gates directly;
   - plants seen to FAIL, then pass once restored;
   - `fg build`, then `fg presuite` (background, ETA ~3 min).
4. Close:
   - `fg gauntlet` in the background (~16 min, 20 legs);
   - `cd Fizzygum-tests && npm run selftest`;
   - `fg homepage`, because the new build steps run under every profile (`buildProfile.py` gates only the tests-repo
     half on `PROFILE_SHIPS_TESTS`) and the homepage build must stay green with them;
   - ONE independent end-of-arc review (a fresh agent given §2, §3's rulings and the diffs, not the ledger);
   - archive this plan (untracked: plain `mv` to `docs/archive/`, INDEX line), move the two BACKLOG items into the
     ledger, update memory, draft commit messages, and WAIT for approval.

House rules that bind every step:
- `fg` only by absolute path, never piped when gating;
- `.coffee` edited with the Edit tool only;
- probes and plants under `Fizzygum-tests/.scratch/`;
- a check is believed only after a plant has failed it;
- zsh: pass name lists as arrays, quote globs (`--include='*.js'`), and quote anything containing `=`.

---

## 6. Rejected alternatives (do not re-attempt)

- **A list of self-tests or of guards that run.** The arc exists because lists of this kind fall behind (F2's
  `package.json` line is one, complete today only by luck).
- **"Mention = runs" for the run set.** Measured: it called `revisit-trace-prelude.js` run because `revisit-gate.js`
  prints its path in a hint, and `build_and_smoke.sh` run because a thrown `Error` message and a Python docstring name
  it. Excluding message calls one by one (`console.*`, `die`, `fail`, `Error`) is a list of shapes that never closes;
  the `path.join`/`path.resolve` launch form is how every real launch site is written.
- **Recording at runtime what ran** (each script stamping a file). Every script would have to remember to stamp, a
  hand convention again, and the gate would read the last gauntlet's stamps from `/tmp`: nondeterministic.
- **A standalone paint-readonly leg.** +124 s of suite in wave B, which has tipped once at 14 legs; the rider costs one
  more armed flag in a pass that already runs.

## 7. References

- `docs/architecture/lint-and-static-checks.md` (§3 gate index, §3b-docs, §3c, §5).
- `docs/archive/tests-repo-readers-plan.md` (the arc that filed F1/F3) and `docs/archive/hand-kept-lists-plan.md`
  (§6.2, the sanction rule).
- `Fizzygum-tests/CLAUDE.md` ("npm run selftest", the PLANT rail, heap-forensics).
- Probe: `Fizzygum-tests/.scratch/unrun-checks/runs-closure.js` (`--with-selftest`, `--unreached`, `--why`,
  `--mentions` for the rejected reading).

---

## Ledger

- **Owner rulings (2026-11-06), one round.** D1 = (a) one file convention, discovered; D2 = (a) a guard must RUN,
  derived; D3 = (a) a headless self-test installs every prelude; D4 = (a) all of F5–F9 in this arc.
- **Unit 0 (2026-11-06).** New `buildSystem/lib/what-runs.js`: `CONVENTIONS` (selftest / selftestHeadless / prelude,
  each with its runner), `scriptFiles`, `discover`, `runSet` (roots: build_it_please.sh, fg's four functions; edges:
  shell commands split on `&&`/`||`/`;`/`|` minus echo/printf/ban, JS `require` and `path.join`/`path.resolve`
  arguments; `.py` a leaf). On the real tree it reads one invocation the probe missed, and it is real:
  `run-capstone-gate.sh`'s backfill pipes `echo $missing | … | xargs … bash audit-one.sh` (the probe skipped the whole
  line as an echo). `lib/what-runs-selftest.js`: 32 cases on a temp-dir workspace. Plants (scratch copies, each FAILS
  by name): echo read as a command → 4 failures; `path.join` launches dropped → `launched.js` not run; `.py` read as
  shell → `orphan.js` run. ⚠ A first `.py` plant (deleting the leaf line) SURVIVED for the wrong reason — the file
  then falls to the JS reader, which finds nothing in Python — so the plant was re-aimed at the shape that matters.
- **Unit A (2026-11-06), D1 (a).** New `buildSystem/lib/selftest-verdict.js` (`VERDICT_RE`, `cases`, `verdict`; FAIL
  lines on stdout so a runner shows them in order) and `buildSystem/run-selftests.js` (`judge`, `offeredFlags`, both
  pure and exported; `--headless`, `--repo=`). Moves, bodies unchanged:
  - `check-dead-methods`, `check-part-edges`, `check-unresolved-sends`, `what-pins-core`: CLI wrapped in `main()`
    behind `require.main` (a scratch helper indents only lines that do not start inside a string), internals
    exported; each gate's output byte-identical before/after (`what-pins-core` in 6 modes);
  - `census-public-private-calls`, `check-hand-lists`: already module-safe; self-test blocks moved out;
  - the two libs' `selfTest(log)` → `lib/method-references-selftest.js` (19) and `lib/tests-repo-code-selftest.js`
    (33), run once each (they ran twice, through two gates' flags);
  - check-hand-lists now skips `check-hand-lists-selftest.js` (the corpus) and scans itself.
  - `what-pins-core`: 5.1 s → 1.0 s, outputs byte-identical. The time was a regex per class per line; a class name is
    all `\w`, so a line names it exactly when one of its maximal `\w` runs IS the name — a Set lookup, matches
    re-sorted into `names` order so every map fills as before.
  - The 12 tests-repo self-tests end with the shared verdict (each now counts what it judges). ⚠ The plan's claim
    that tests-repo scripts already required Fizzygum libs was WRONG (only comments named them); the require is new,
    and right: the line is a contract the runner reads, and `npm run selftest` runs that runner from Fizzygum anyway.
  - `npm run selftest` = `node ../Fizzygum/buildSystem/run-selftests.js --repo=tests` (12, 217 cases, 0.6 s).
  - build_it_please.sh: the self-tests block FIRST among the gates. Node tier: 22 self-tests, ~460 cases, ~2 s.
  - `run-selftests-selftest.js` (22 cases): the runner's own verdicts on canned runs and its flag scan on samples.
  Plants, each seen to FAIL then pass restored:
  - `check-dead-methods-selftest.js` case flipped → `fg build` FAILS at the self-tests block ("a self-test failed");
  - before conversion the scan caught every real outside-convention flag: `heap-forensics.js:57/64` and five
    `run-cache-oracle-gate.sh` lines (a first version missed the JS string because js-mask labels the quotes as part
    of the literal — fixed);
  - a runner that ignores the exit code (scratch copy) → `run-selftests-selftest` FAILS 2 of 22.
- **Unit B (2026-11-06), D2 (a).** `check-hand-lists`: `resolveGuard` → `{ runs, exists }`; universes from
  `runSet` (a script per (a); SystemTest_ dirs and world-source tokens when the suite runner runs);
  `SANCTION_GUARD_NEVER_RUNS`; without fg a NOTE; `--fg=<path>`; census shows "named, never run". Fixes:
  - aim-census: new `--tables-only` (0.24 s), run by the build when the sibling repo is present; header says which half
    gates;
  - what-pins-core's sanction names `what-pins-core-selftest.js`;
  - `globalFunctions.coffee` `META_SYSTEM_SOURCES` re-sanctioned to `run-all-headless.js` (the boot smoke kept as a
    second witness);
  - the 9 diagnostic-prelude sanctions resolve through Unit C's prelude self-test (and the 6 layout-audit ones also
    through the capstone backfill).
  Result: 40 sanctions, 0 resting only on never-run guards; gate OK. Self-test 46 cases (+ never-run file/token, a
  one-runs control, fg-absent notes). Plants: `--files` sanction naming `torture-headless.js` → FAILS
  `SANCTION_GUARD_NEVER_RUNS`; naming `run-all-headless.js` → OK; `--fg=/nonexistent` → the leg-only guards turn to
  UNVERIFIED notes, exit 0; a stale `VERBS` row in aim-census → `fg build` FAILS at "the aim census's tables are
  stale". Clean `fg build` OK after.
- **Unit C (2026-11-06), D3/D4 (a).** Headless tier (`fg` wave-A leg `selftests`, local; serial path too):
  - `preludes-install-selftest-headless.js`: every discovered `*-prelude.js` installs on the harness page, announces
    `<TOKEN> installed` (one pattern covers `LAYOUTAUDIT installed` and `CMEAS: installed`, so the planned CMEAS rename
    was unnecessary), and trips no fail-closed line. 11 preludes, 23 cases, 28 s. Plants under `scripts/` (removed):
    a prelude printing a `LAYOUTAUDIT_STALE_NAME` → FAILS "installs clean"; a silent one → FAILS "announces it".
  - `heap-forensics.js` → `forensics(opts)` module + CLI; `--selftest` retired; `heap-forensics-selftest-headless.js`
    5 cases, 3.9 s; the CLI's `--boot-only` still runs CLEAN.
  - cache oracle: `run-cache-oracle-gate.sh` + `cache-oracle-prelude.js` DELETED (superseded by the settle rider);
    the plant moved to `notification-settle-audit/cache-oracle-plant.js`; `cache-oracle-selftest-headless.js`: settle
    + plant FAILS on the token (it floods ~250 k lines), settle alone PASSES, plant alone PASSES (disarmed) — 3 cases,
    22 s. Headless tier total: 3 self-tests, 31 cases, 53 s.
- **Unit D (2026-11-06), D4 (a).**
  - F8: `check-doc-narration.js` rides the `refs` leg (0.04 s); fg's usage says so.
  - F5: paint-read-only folded into the capstone prelude/gate (both flags armed, per-test `capstone-armed` +
    `paint-armed`, records tagged `careless` / `paint-time`, both rules reported in one pass);
    `scripts/paint-readonly-audit/` DELETED; the two sibling gate headers that named it now name the capstone.
  - FOUND on the way (what-runs read the backfill): the capstone's shard-miss BACKFILL injected
    `layout-audit-prelude.js`, so a backfilled log had no `capstone-armed` line and its layout records counted as
    careless pushes — the backfill could only fail the gate, never re-measure. `audit-one.sh` takes the prelude as $3;
    the capstone passes its own. Proof: one test through the backfill path → installed 1, capstone-armed 1,
    paint-armed 1, 0 records.
  - First plant (every painted widget schedules its own layout during paint, suite-wide): counters saw it (13,554
    paint-time schedules, flags armed 373/373) but 3 tests' pixels moved, so the gate stopped at its suite check.
    Re-aimed (the hand and the world are orphans to the product and record nothing): the plant confined to
    `SystemTest_macroAnalogClockInspectEdit` (a desktop child re-laid during paint, once per frame) — suite PASSED
    373/373, flags armed 373/373, and the gate FAILED on BOTH rules, each naming the test and `AnalogClockWdgt`
    (31 paint-time schedules; the same 31 are careless pushes). Prelude restored and diffed clean.
  - F9: the tier-naming header said "the live self-test plants a __commit* that REACTS…"; no code does. It now says
    no standing plant exists and names what does run (TIERNAMING-OBSERVED in every test). A standing bite-proof for
    each audit gate (as the cache oracle now has) is filed, not done.
- **Gates after Units 0–D (2026-11-06).** `fg presuite` OK — dpr1:PASS(93s) paint:PASS(153s) fracplane:PASS(6s)
  total=177s (its build ran the new steps: self-tests 22/460 cases, hand-lists OK, aim-census tables OK).
- **`fg gauntlet` #1 (2026-11-06): 20/20 OK with ONE load-flake, on the new leg** — dpr1 169s, dpr2 189s, webkit 164s,
  apps 104s, parts 50s, menusweep 7s, pinsweep 5s, graph 13s, selftests PASS-serial-only, paint 166s, tiernaming 179s,
  settle 194s, capstone 180s (was 206s with the paint audit not riding it: the rider costs nothing measurable),
  refs 211s (doc-narration rides it), revisits 179s, census 10s, serialization 128s, storage 179s, vmtruth 128s,
  finger 303s; total 1019s. `selftests` hit fg's 300 s alarm in wave A: heap-forensics took 108 s (3.5 s alone), and
  the cache-oracle self-test FAILED its planted case — the planted run came back exit 0 with the token in its output,
  under a ~250 k-line error flood through the devtools protocol; alone, all 3 passed (50.8 s). The self-test kept no
  output to read it by. Fixes: the plant answers wrong 25 times, not forever (the planted run 22 s → 15 s alone);
  each run's status, signal and tail now go into its case detail; the verdict is matched as the runner's own closing
  line; per-run timeout 300 s; the leg's alarm 600 s. Re-run under a reproduced load (two suites, 8 + 4 shards,
  beside the headless tier): all 3 PASS, 29 cases, 50.7 s.
- **ONE independent end-of-arc review (2026-11-06)**, a fresh Opus agent given §2, the rulings and the diffs (not this
  ledger), read-only. Ten findings, eight confirmed by probe; every one addressed, each fix proven:
  - **R1 (HIGH).** The prelude-install self-test played no test, and the two table-holding preludes (layout-audit,
    revisit-trace) hold their `LAYOUTAUDIT_STALE_NAME` findings until the first test starts — so the 9 sanctions on them
    still leaned on a guard that could not fail. FIX: each prelude now runs one short test through the REAL
    single-test runner (fail-closed), its full console captured for the `installed` line. PLANT: copies of both preludes
    with one name made stale → both FAIL "runs … clean"; the real tree passes (21 cases, 50 s).
  - **R8.** The same runs get the VM-truth leg's Chrome dose: `run-macro-test-headless.js` gains `AUDIT_CHROME_ARGS`
    (the rail run-all-headless.js already had; refused with webkit), and the VM-truth prelude takes its real path
    (`gc=1`).
  - **R2.** `require` counted as running a command-line tool its self-test alone loads (classify-diff, heap-forensics,
    what-pins-core, run-atlas-fuzz read as "run"). FIX: a self-test's own edges are not followed. Corpus: a self-test
    requiring `cli-tool.js` leaves it unrun.
  - **R3.** check-hand-lists scanned itself, so its own token names vouched; and guard (c) accepted any capitalised token,
    comments and constant names included. FIX: tokens are harvested only from STRING literals in code (commentLayout
    now records string spans), never from the gate itself. Corpus +4 (a comment-only and a constant-only token →
    `SANCTION_NAMES_NO_GUARD`); the reviewer's probe (`SANCTION_GUARD_NEVER_RUNS`, `FG_FUNCTIONS` as guards) now fails.
    All 40 real sanctions still resolve.
  - **R4.** The six gates that had a self-test flag accepted it silently and ran the gate (exit 0 — read as a passing
    self-test). FIX: new `lib/cli-args.js` `rejectUnknownArgs`; each refuses an unknown argument with exit 2 and, for a
    self-test spelling, names its self-test file. Probed: all six exit 2 on the old flag; each runs normally without.
  - **R5.** The shell reading counted mentions (`then echo …`, `[ -f x ]`, bare assignments, heredocs, a multi-line echo)
    and missed real launches (`"$(dirname "$0")/x.js"`, a `${3:-x.js}` default — the latter live in audit-one.sh). FIX:
    a small shell lexer (`shellCommands`: quotes across lines, continuations, comments, heredocs, `$( )` as commands of
    their own) and a POSITIVE grammar (the program, a word after an interpreter, an assignment in a command that runs
    one). `fgRootText` handles a one-line function and fails unless all four functions are found (a corpus fg with
    `fg_build` on line 1 caught a `slice(-1)` bug in my first fix). what-runs self-test 32 → 47 cases; plants: the
    slice bug and dropping the printer rule each FAIL it (the printer plant first SURVIVED — under the positive grammar
    an echo launches nothing unless its unquoted words hold an interpreter, so that case was added).
  - **R6.** Discovery gaps. FIX: `SELFTEST_UNDISCOVERED` — a file anywhere in either repo named like a self-test that no
    tier runs (plant `buildSystem/zz-plant.selftest.js` → FAILS); the scan also catches `--selftest=1`, lib/cli.js
    readers, bracketed and destructured env switches, Python literals, and reads shell through the lexer (an echo is
    prose). Runner self-test 22 → 33 cases.
  - **R7.** The capstone counted only its two tags, dropping any other record. FIX: every record is counted; one tagged
    neither fails the gate, listed. Fixture: 4 records (careless, paint-time, `paint`, untagged) → 1/1/2 unclassified.
  - **R9 (accepted, not changed).** Some tests-repo self-tests' case counts are inexact in the FAIL direction only
    (failures counted outside a case); none can pass with a failed or zero cases.
  - **R10.** Docs/comments: "FIRST step" → first GATE; the what-runs header and lint doc describe the new grammar and
    blind spots; the capstone header's `_coalescedDeclarationDepth` → `_deferredSettleDeclarationDepth` (the product's
    field); history removed from two present-tense headers; plan pointers → `docs/archive/`; check-call-separation's
    "Self-test:" note relabelled as the by-hand plant it is; BACKLOG's paint-readonly line names the capstone.
- **Closing gates (2026-11-06), after the review fixes.**
  - `fg gauntlet` #2: 20/20, NO retries — dpr1 189s, dpr2 209s, webkit 175s, apps 125s, parts 62s, menusweep 23s,
    pinsweep 23s, graph 24s, selftests 101s (heap-forensics 23 s, cache-oracle 19 s, preludes-install 58 s, all inside
    wave A), paint 181s, tiernaming 194s, settle 209s, capstone 195s, refs 239s, revisits 194s, census 24s,
    serialization 170s, storage 194s, vmtruth 128s, finger 303s; total 904s.
  - `npm run selftest`: 12 self-tests, 217 cases, 0.7 s. Build node tier: 22 self-tests, 490 cases, ~1.9 s.

## BACKLOG ledger

The two items this arc was opened for, as BACKLOG held them (section "archive/tests-repo-readers-plan.md"):
- [x] **The buildSystem gates' `--self-test`s are run by nothing.** `check-dead-methods`,
      `census-public-private-calls` (which also runs the reader's cases), `check-unresolved-sends`, `check-hand-lists`
      and `check-part-edges` each prove their rules on fixtures, but neither the build, `fg` nor
      `npm run selftest` invokes them, so a self-test can rot unnoticed. Found 2026-11-06. — CLOSED: Unit A.
- [x] **`aim-census.js` is run by no gate, so its own stale-name checks fire only when someone runs it.** Its
      tables classify every MacroToolkit verb, and `check-hand-lists` accepts them as sanctioned on the strength of
      `AIM-CENSUS STALE NAME`. Deleting a verb leaves its row stale until a hand run. (It exits 0 today; a planted
      stale row was seen to print the token.) — CLOSED: Unit B (and 17 more sanctions on guards nothing ran).

Filed by this arc: "Standing bite-proofs for the checks proven only by hand" (BACKLOG, section
"archive/unrun-checks-plan.md").
