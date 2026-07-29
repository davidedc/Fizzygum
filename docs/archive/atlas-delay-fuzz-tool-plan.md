# `fg fuzz` — promote the glyph-atlas delay injector to a real tool

**STATUS: EXECUTED 2026-07-29 — the tool is built, gated and verified. See §9 for the execution
record, including the ONE §5 test that could not be demonstrated and why.** Gauntlet green after
the work (13/13 legs, zero reference churn).

**AUTHORED 2026-07-29. Written to be executed COLD by an LLM/engineer with ZERO prior
context.** Every fact below was verified against the working trees on 2026-07-29 (Fizzygum `master`
@ `44ace557`, Fizzygum-tests `master` @ `fc07ae2e6`, suite = 268 SystemTests). **Line numbers WILL
drift — the quoted file/function/flag names are authoritative; re-grep before trusting any
`file:line`.**

**MANDATE.** Turn a throwaway scratch probe into a tool that can be trusted *unattended*. The bar is
not "it runs" — it is **a tool that can never report a false green**. The prototype produced FOUR
invalid runs in one morning, three of which printed `failed: 0` and would have been read as a clean
pass. If you build only one thing from this plan, build the validity gate (§3.2).

⛔ **NOT a gauntlet leg. NOT a gate.** See §6.1 — this is settled, do not re-propose.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on one HTML5 canvas; three sibling repos
(`Fizzygum` source, `Fizzygum-tests` suite + harness, `Fizzygum-builds` generated output). Read the
root `CLAUDE.md`, then `Fizzygum-tests/CLAUDE.md`, then **`Fizzygum-tests/DETERMINISM.md` §3g and
§3i** — those two are the bugs this tool exists to catch.

Use the `fg` wrapper (`/Users/davidedellacasa/code/Fizzygum-all/fg`) for every build/test
invocation — absolute path, never `./fg`.

### What this is, in one paragraph

SWCanvas loads glyph **atlases lazily** and paints **placeholder boxes** until they arrive; the
clearing repaint is deferred to a `requestAnimationFrame`. The framework's contract is that this is
invisible: every pixel read waits on `world.anyTextDirty()` (in practice via
`MacroToolkit.readyForMacroScreenshot`). **The tool falsifies that contract by force** — it delays
every atlas load by a seeded-random 0..`MAX_MS`, and any test that then fails has a pixel read the
gate does not cover.

### Why now — the invariant has been violated THREE times

| when | where | how it was found |
|---|---|---|
| 2026-07-27 | `serialization-file-roundtrip-headless.js` (`dropPixelParity`) | accident; misdiagnosed as a mid-settle sample and "fixed" with a convergence loop that could not have cured it |
| 2026-07-28 | `serialization-roundtrip-headless.js` (`pixelParity` BISTABLE) | a ~1-in-3 gauntlet flake; cost a full investigation (DETERMINISM.md §3g) |
| 2026-07-29 | `macroClosingRotatedIslandChildClearsFootprint` | **223 torture iterations (~65,000 test-executions) never caught it**; solved only by abandoning sampling and measuring the mechanism directly (§3i) |

That is a bug **class**, not three coincidences, and it is not reliably catchable by sampling. A
5-minute fault-injection run reproduces the mechanism that a 12-hour torture run misses.

### Critical reframes — do not re-derive these

- **R1: this is a COVERAGE MEASUREMENT, not a test with an expected output.** If the gate is correct,
  *when* an atlas arrives is unobservable and the suite is exactly as green as without injection. A
  failure means "this pixel read is not gated", never "the reference is wrong". **Never recapture a
  reference because of a fuzz failure.**
- **R2: it must never live in `tests/`.** It is deliberately nondeterministic — precisely what the
  suite's byte-exact contract forbids (`DETERMINISM.md` §1.4). `tests/` membership IS the enabled
  set; a seeded-random test there would poison every gate.
- **R3: `failed: 0` is NOT a pass.** The runner reports `failed: 0` when shards die before running
  anything. **The only trustworthy signal is `shards complete: N/N` plus `played 67/67` per shard.**
  This defeated the prototype three times in one morning (§4).
- **R4: the injector must not perturb what it measures.** A `setInterval(fn, 0)` poll in the
  prototype starved the boot thread across 4 shards and killed every CDP connection. Fault injection
  that changes the system's timing profile beyond the injected fault is measuring itself.

---

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — confirm clean trees, note the suite count.
2. Read this doc fully, then `DETERMINISM.md` §3g + §3i (the two bugs), then §4 below (the traps).
3. Build in order: §3.1 (script) → §3.2 (validity gate) → §3.3 (`fg` subcommand). **§3.2 is the
   point of the exercise** — a tool without it is worse than no tool.
4. §5 verification: the tool must PROVE it injected, and must FAIL LOUDLY on an invalid run.
5. **Never commit or push without explicit owner approval** (standing rule).
6. Budget: each suite run at 4 shards is ~1.8 min under injection. The whole plan is a few hours
   including the deliberate-failure tests in §5.

---

## §1 Exact current state (what exists TODAY)

- **The prototype:** `Fizzygum-tests/.scratch/atlas-delay-prelude.js`. **`.scratch/` is gitignored —
  this file is LOCAL to the machine that made it and may not exist in your checkout.** If it is
  gone, §3.1 is a from-scratch write; the full working source is reproduced in §2.
- **Config is edited IN THE SOURCE** (`var SEED`, `var MAX_MS` at the top). The prototype was re-run
  by `perl -pi`-ing those constants — a smell, and the first thing §3.1 fixes.
- **Injection rails already exist and need no new plumbing:** `run-all-headless.js` reads
  `AUDIT_PRELUDE=<file>` (grep `AUDIT_SRC`) and injects it with `page.addInitScript(...)` **before
  the shard navigates**, persisting across that shard's tests and any stall-recovery reloads.
  `AUDIT_DIR` is optional (it only buckets `LAYOUTAUDIT`-prefixed console lines into per-test logs,
  keyed on a `LAYOUTAUDIT_TESTSTART` marker the injector does not emit — so do NOT rely on it for
  proof-of-injection; see §3.2).
  The single-test runner `run-macro-test-headless.js` uses `PRELUDE_JS=<abs path>` instead.
- **`fg` is LOCAL, UNCOMMITTED umbrella tooling** (root `CLAUDE.md`; verified: `git ls-files` does
  not track it). **Consequence for this plan:** the *script* is committed to `Fizzygum-tests`, but
  the `fg fuzz` *subcommand* is a local edit that no repo will carry. Write §3.3 so the script is
  fully usable without `fg` (documented env-var invocation in its own header).

### Measured behaviour of the prototype (do not re-derive)

- Injection **is** live through the suite rails: `patched=true` in all 4 shards, up to **55 delayed
  atlas loads** per page.
- **`MAX_MS=250` is the workable dose. `MAX_MS=1000` is too aggressive** — early tests pay the whole
  warm-up serially and legitimately exceed even a 180 s per-test stall cap (`--test-stall-secs`).
- Clean runs achieved: seed `1234567` @1000 (before the probe fix), seed `424242` @250, seed `55555`
  @1000 (after the probe fix) — each 268/268, 4/4 shards.
- **It has already earned its keep:** seed `55555` @1000 exposed a real defect — both
  `probeTotalTests` implementations (`run-all-headless.js`, `run-paint-audit.js`) awaited a
  readiness `until(...)` and **discarded its result**, then dereferenced `world.automator`, so a slow
  boot died with a bare `Cannot read properties of undefined (reading 'automator')`. That same error
  had killed the gauntlet's `paint` leg in-wave the day before with no known trigger. Fixed
  2026-07-29 (check + one retry + an actionable message).

---

## §2 The prototype source (reproduce from here if `.scratch/` is gone)

Mechanism, so you can rebuild it without archaeology:

- Seed a **mulberry32** PRNG (NOT `Math.random` — a hit must be reproducible from the seed alone).
- Poll until `window.SWCanvas.fonts._raw.BitmapText` exists — the prelude runs at `document_start`,
  long before the boot bundle defines it. **Poll at 5 ms, never 0** (R4).
- Wrap `BitmapText.loadFont(idString, opts)` so it **delays the RESOLUTION, not the request**: the
  atlas still loads normally; only *when the framework learns about it* moves. That is exactly the
  window `swCanvasAtlasPending` covers, which is what makes the injected fault the real one.
- Announce `LAYOUTAUDIT installed atlas-delay seed=… maxMs=…` once (the marker
  `run-all-headless.js` keys on), and log `patched=`/`delayedLoads=` periodically.

```js
var _s = SEED >>> 0;
function rnd() {                                   // mulberry32
  _s = (_s + 0x6D2B79F5) >>> 0;
  var t = _s;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}
bt.loadFont = function (idString, opts) {
  var ms = Math.floor(rnd() * MAX_MS);
  delayed++;
  return orig(idString, opts).then(
    function (v) { return new Promise(function (res) { setTimeout(function () { res(v); }, ms); }); },
    function (e) { return new Promise(function (_, rej) { setTimeout(function () { rej(e); }, ms); }); });
};
```

---

## §3 The work

### 3.1 Promote the script — `Fizzygum-tests/scripts/atlas-delay-prelude.js`

Move it out of `.scratch/` (so it survives and is reviewable) and make it **configurable without
editing source**. The prelude is injected as raw text into the page and cannot read `process.env`,
so the runner-side wrapper must **substitute** the values (simplest: `String.replace` on two
`__SEED__` / `__MAX_MS__` placeholders, or prepend a `var` line). Requirements:

- `FUZZ_SEED` (default: a *printed* fixed value — never an unprinted random one, or a hit is
  unreproducible) and `FUZZ_MAX_MS` (default **250**, per §1).
- Keep the full header comment explaining the invariant, R1, R2 and the 5 ms trap.
- Keep the `patched=`/`delayedLoads=` heartbeat: it is the proof-of-injection §3.2 consumes.

### 3.2 THE VALIDITY GATE — `Fizzygum-tests/scripts/run-atlas-fuzz.js` (the point of this plan)

A Node wrapper that runs the suite under injection and classifies the outcome into **three** states,
never two:

| verdict | condition | exit |
|---|---|---|
| **PASS** | injection proven live AND `shards complete: N/N` AND every shard `played X/X` AND `failed: 0` | 0 |
| **FAIL** | run valid AND one or more tests failed → the finding; print names + seed to reproduce | 1 |
| **INVALID** | injection NOT proven, or any shard `DISCONNECTED`/`STALLED`/incomplete | **2** — neither pass nor fail |

- **Proof-of-injection is mandatory**, not optional: the wrapper must observe `patched=true` from
  the page (e.g. run with the console relay and grep the heartbeat, or have the prelude write a
  marker the wrapper can read). **A run where the prelude silently patched nothing is INVALID.** A
  no-op injector reporting 268/268 is the worst possible outcome — it certifies coverage that was
  never tested.
- Print the **seed** on every line that matters, so any result is reproducible.
- Do `kill_browsers` first and export `FIZZYGUM_KEEP_STALE_BROWSERS=1` (§4.3).
- Use a generous `--test-stall-secs` (≥300); a gate that *correctly* waits for text now legitimately
  waits longer, and a watchdog trip is a false positive (`DETERMINISM.md` §2b).
- Optional `--rounds=N` to re-roll the seed N times (`seed+1`, `seed+2`, …) — one delay schedule
  exercises one interleaving.

### 3.3 The `fg fuzz` subcommand (LOCAL — see §1)

Follow the existing subcommand shape (`fg suite` / `fg census` are the models):
`verdict_start fuzz` → `kill_browsers` → `( cd "$FT" && to <secs> node scripts/run-atlas-fuzz.js "$@" )`
→ `ban "FUZZ OK"` / `verdict_end fuzz`. Map the INVALID exit (2) to its **own** loud banner —
`FUZZ INVALID (not a result)` — never to OK and never to FAILED.

### 3.4 Extend to the two serialization rigs (the paths that were actually exposed)

The suite is not the whole surface: **both serialization rigs sat entirely outside the text gate
until 2026-07-28**, and this harness does not exercise them. They boot their own pages
(`serialization-roundtrip-headless.js`, `serialization-file-roundtrip-headless.js` — both use
`puppeteer.launch` directly, not `AUDIT_PRELUDE`), so injecting there needs a
`page.evaluateOnNewDocument` hook wired into each rig behind the same env vars. **Do this** — it is
the part that covers the code that actually broke.

---

## §4 The traps (all four cost real time on 2026-07-29 — do not rediscover them)

### 4.1 `setInterval(fn, 0)` in the prelude starves the boot
A 0 ms poll busy-spins the main thread in EVERY page until `SWCanvas` appears. Across 4 shards it
dropped every CDP connection: 4 shards `DISCONNECTED`, `failed: 0`, `shards complete: 0/4`. **Use
5 ms.** (R4.)

### 4.2 `--verbose` at 4 shards is itself destabilising
It relays every console line over CDP; with 4 shards it reliably produced 4/4 `DISCONNECTED` with
the *same* prelude that runs clean without it. **Never use `--verbose` for a run whose result you
intend to trust.** This is a property of the runner, not of the injector.

### 4.3 Concurrent runners cull each other's browsers
`run-all-headless.js` kills stale headless browsers at startup, so two concurrent runs `pkill` each
other — every shard ends `DISCONNECTED` with `failed: 0`. Export `FIZZYGUM_KEEP_STALE_BROWSERS=1`
and `fg killz` once up front. **Also `killz` BETWEEN rounds**: the prototype's 3-seed loop did not,
and runs 2 and 3 were invalid.

### 4.4 `MAX_MS=1000` makes early tests exceed the stall cap
Not a bug and not a finding — the dose is too high. Early tests in a shard pay the entire warm-up
serially. Symptom: `STALLED on <test>` with 2–11 of 67 played, ~17 min. Use **250**.

**All four share one signature: `failed: 0` next to `shards complete: 0/4`.** That is why §3.2 exists.

---

## §5 Verification protocol

```
/Users/davidedellacasa/code/Fizzygum-all/fg status      # orientation
/Users/davidedellacasa/code/Fizzygum-all/fg build       # only if src/harness .coffee changed
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
node scripts/run-atlas-fuzz.js --rounds=3               # or: fg fuzz --rounds=3
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet    # standing gate — the tool must not perturb it
```

**Test the tool's FAILURE modes deliberately — an untested error path is what breaks when needed:**

1. **INVALID on no-injection:** point it at a prelude that patches nothing (or a build with the
   native page). It MUST exit 2, not 0. *This is the single most important test in the plan.*
2. **INVALID on dead shards:** force it — e.g. add `--verbose` at 4 shards (§4.2), a reliable
   producer of `DISCONNECTED`. It MUST exit 2, not 0.
3. **FAIL on a real finding:** temporarily revert flake A's fix (drop the
   `yield "waitForScreenshotReady"` from
   `tests/SystemTest_macroClosingRotatedIslandChildClearsFootprint/...automationCommands.js`) and
   confirm the tool catches it and names the test. **Restore it afterwards** — verify with
   `git -C Fizzygum-tests status`. This is the tool's own regression fixture: a known,
   already-diagnosed member of the exact bug class.
4. **PASS on a clean tree**, with the seed printed.

Long-op discipline: launch minutes-long runs ONCE with the Bash tool's `run_in_background: true`,
redirect to a log, and wait for the task notification — never a foreground poll loop (the guard hook
blocks them). ⚠ While a long op runs, `fg`, `src/**` and `tests/**` are READ-ONLY: editing `src`
mid-gauntlet trips the stale-build guard and invalidates the entire run.

**Exit criteria:** all four §5 tests behave as specified (especially #1 and #2), `fg gauntlet` still
green, and §3.4 done or explicitly deferred with a reason. Then `git mv` this doc to
`docs/archive/`, stamp it, and add an `archive/INDEX.md` line.

---

## §6 Rejected / do-not-re-attempt

1. ⛔ **Making it a `fg gauntlet` leg / any standing gate.** Owner-declined 2026-07-29. It is
   nondeterministic by construction; a gate that fails randomly gets ignored, and its failure modes
   (STALLED/DISCONNECTED) overlap infra noise so triage is expensive. Context: an `--shards=1` leg
   was already declined on cost alone (~6 min) — this is slower *and* flaky. **On-demand only.**
2. **Putting it in `tests/`** — R2. It would poison every gate that runs the suite.
3. **`Math.random()` instead of a seeded PRNG** — an unreproducible hit is worthless.
4. **Trusting `failed: 0`** — R3, §4.
5. **Using `AUDIT_DIR` per-test logs as proof-of-injection** — the injector emits no
   `LAYOUTAUDIT_TESTSTART` marker, so the audit dir comes back EMPTY even when injection is live
   (measured 2026-07-29). Use the heartbeat instead.
6. **`MAX_MS=1000`** — §4.4.

---

## §7 References

- **`Fizzygum-tests/DETERMINISM.md` §3g** (bistable half-warm atlas) and **§3i** (the frame-boundary
  pixel read) — the two bugs. §2b (stall watchdog false positives), §1.4 (speed/shard invariance).
- `Fizzygum/docs/archive/suite-nondeterminism-flakes-plan.md` — flakes A/B/C end to end, including
  §2.5.1's "match the cadence you are investigating" lesson.
- `Fizzygum-tests/scripts/run-all-headless.js` — `AUDIT_PRELUDE`/`AUDIT_SRC` rails, `probeTotalTests`.
- `Fizzygum-tests/scripts/audit-preludes/revisit-prelude.js` — the model for a well-behaved prelude.
- `Fizzygum/src/boot/extensions/SWCanvasElement-extensions.coffee` — `swCanvasAtlasPending`,
  `swCanvasScheduleTextRefresh`, `swCanvasAnyTextDirty`; `MacroToolkit.readyForMacroScreenshot` is
  the gate under test.

## §9 EXECUTION RECORD (2026-07-29)

### What was built

| file | role |
|---|---|
| `Fizzygum-tests/scripts/audit-preludes/atlas-delay-prelude.js` | the injector. **Filed in `audit-preludes/`, not `scripts/` as §3.1 said** — that is where the three sibling injected preludes live and where §7 itself points for the model. |
| `Fizzygum-tests/scripts/lib/atlas-fuzz.js` | loader: config by PREPENDING `window.__ATLAS_FUZZ_CONFIG` rather than substituting `__SEED__` placeholders, so the prelude stays valid standalone JS (a placeholder file would fail `fg lint`'s `node --check` over changed `scripts/*.js`). |
| `Fizzygum-tests/scripts/run-atlas-fuzz.js` | **the validity gate (§3.2)** — PASS/FAIL/INVALID, exit 0/1/2. |
| `Fizzygum-tests/scripts/run-atlas-fuzz-selftest.js` | 31-case canned-transcript corpus; wired into `npm run selftest`. |
| `Fizzygum-tests/scripts/run-all-headless.js` | new `AUDIT_ECHO=1` rail (below). |
| both serialization rigs | §3.4 done: `FUZZ_ATLAS=1` injection + **hard exit 2** when injection cannot be proven. |
| `fg fuzz` | §3.3, local/uncommitted; INVALID gets its own banner, never OK/FAILED. |

### The proof-of-injection channel (the thing §3.2 turns on)

A sharded run gives the wrapper **no page handle**, so it cannot read `window.__atlasFuzz`. §6.5
already ruled out `AUDIT_DIR`. The remaining channel was the console — but `run-all-headless.js`
relays a prelude's lines only if they match `/FAIL|UNCAUGHT|UNHANDLED|STALL/i`. So a one-line,
env-gated `AUDIT_ECHO=1` rail was added, **byte-identical behaviour when unset**. Two channels now
exist and both are mandatory where available: console heartbeat (suite), `window.__atlasFuzz`
(rigs, read directly).

⚠ **`LAYOUTAUDIT installed` contains the substring "stall"** (in-**stall**-ed), so it *also* matched
that relay regex and printed twice per shard. That looks exactly like a prelude running twice and
double-wrapping `loadFont` — i.e. a silently doubled fault dose — and cost real time to rule out
(probes proved one execution, one frame, one wrapper). The echo now relays once and returns, **only
under `AUDIT_ECHO`**, so no standing gate's output changes.

### §5 verification — results

| # | test | result |
|---|---|---|
| 1 | **INVALID on no-injection** | ✅ **both paths.** Prelude neutered to never find `BitmapText`. Suite printed `ALL TESTS PASSED`, `failed: 0`, `shards complete: 4/4`; rig printed `SERIALIZATION RIG OK`. **Both exited 2.** This is the plan's headline test and it holds. |
| 2 | **INVALID on dead shards** | ✅ Forced via §4.3's real trap (culling the browsers mid-run) rather than `--verbose`, which is not deterministic: 4/4 `DISCONNECTED`, `failed: 0` → exit 2. Injection *was* proven here, so the refusal came purely from the structural check. |
| 3 | **FAIL on flake A reverted** | ❌ **NOT DEMONSTRATED — see below. Fix restored; `tests/` verified byte-identical to HEAD.** |
| 4 | **PASS on a clean tree** | ✅ 268/268, 4/4 shards, injection proven in all four, 197 atlas loads delayed, seed printed. Suite leg 1.74 min. |

### §5 test 3: why the regression fixture did not work (measured, not assumed)

With `yield "waitForScreenshotReady"` removed, `macroClosingRotatedIslandChildClearsFootprint`
**passed 13/13 under injection** (6 seeds @250 ms, 4 @3000, 3 @12000) — **and 3/3 in a control with
no injection at all.** It does not reproduce on an idle box in a single-test run either way, which
matches its own history (~223 torture iterations never caught it; only ever seen in bursts under
irregular load).

The mechanism, worth keeping because it is counter-intuitive:

- A freshly booted page makes **about ONE `BitmapText.loadFont` call**; a whole shard (one page,
  67 tests) accumulates ~50. A single-test run therefore buys roughly **one lottery ticket**.
- The §3i failure needs the resolution to land **between** two reads that straddle a frame
  boundary — a target window of about one frame.
- Therefore **a bigger dose is NOT more sensitive**: too small and the atlas resolves before the
  read; too large and it resolves after BOTH reads, so both see placeholder boxes and the diff is
  0 again. The 12000 ms runs were *less* likely to hit than the 250 ms ones.

**Consequence for how to read a PASS** (now in the tool's own header): it means "across a suite run
with ~200 atlas resolutions displaced, every exercised pixel read stayed correct". It is not proof
of absence, and this tool is **not a reliable reproducer for any one known race**.

### Deviations from the plan, and why

1. **Prelude filed in `audit-preludes/`** (§3.1 said `scripts/`) — see the table above.
2. **Config by prepend, not placeholder substitution** — keeps the file lint-clean standalone.
3. **`AUDIT_ECHO` rail added to `run-all-headless.js`** — not foreseen by the plan, but §3.2's
   "proof-of-injection is mandatory" is unimplementable for a sharded run without it.
4. **ONE retry for an INFRA-ONLY invalid round**, mirroring `fg`'s serial load-flake retry. Added
   after a real occurrence: a shard dropped its CDP connection on its 67th test and aborted a
   multi-round hunt that had found nothing. Invalid reasons are tagged by kind; **an
   injection-proof failure or a dose stall is NEVER retried**, and the retry is classified from
   scratch by the same rules, so it cannot manufacture a pass. Pinned by 3 selftest cases.
5. **Prelude announces the FIRST delayed load immediately** — a run shorter than the 5 s heartbeat
   could otherwise report `installed=true, delayedLoads=unknown`, i.e. injection unprovable. Found
   by the §5 test-3 drill, which the wrapper's own strictness correctly flagged as INVALID.

### Residual / not done

- §5 test 3 has **no working regression fixture**. If one is wanted, it needs a scenario with many
  atlas loads and a read near one of them, not this test. Recorded in `docs/BACKLOG.md`.
- ⛔ §6.1 stands: **not a gauntlet leg, not a gate.** Nothing here changes that.

---

## §8 Provenance

Authored 2026-07-29 immediately after the prototype's first serious outing: 7 suite runs under
injection (3 valid/clean, 4 invalid), which validated flake A's fix under fault conditions and
exposed the `probeTotalTests` readiness defect. Every trap in §4 was hit that morning. **No tool
code has been written** — only the gitignored `.scratch/` prototype described in §1/§2.
