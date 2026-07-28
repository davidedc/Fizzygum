# Suite nondeterminism — two OPEN non-boot flakes (discovered 2026-07-28)

**STATUS: PLAN ONLY — AUTHORED 2026-07-28. Written to be executed COLD by an LLM/engineer with
ZERO prior context.** Every fact below was verified against the working trees on 2026-07-28
(Fizzygum `master`, Fizzygum-tests `master`, suite = 268 SystemTests). Line numbers WILL drift —
**the quoted method/variable names and code snippets are authoritative; re-grep before trusting any
`file:line`.**

**MANDATE.** Eliminate both flakes at the root. The standing project bar is that a SystemTest
failure means a real defect: boot-storm infra flakes are tolerated (a shard that never starts), and
**nothing else is**. Neither flake here is a boot flake. Do not "fix" either by loosening an
assertion, widening a tolerance, adding a retry, or moving a test out of `tests/` — those are all
explicitly out of bounds. Either find the defect, or prove the test/rig is asking a question it has
no right to ask and fix the QUESTION (with evidence, recorded here).

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on one HTML5 canvas; three sibling repos
(`Fizzygum` source, `Fizzygum-tests` suite, `Fizzygum-builds` output). Read the root `CLAUDE.md`,
then `Fizzygum-tests/CLAUDE.md`, then **`Fizzygum-tests/DETERMINISM.md`** — that last one is the
subject-matter doc for this plan and already carries a condensed record of both flakes in its §2c;
this plan is the executable long form.

Use the `fg` wrapper (`/Users/davidedellacasa/code/Fizzygum-all/fg`) for every build/test
invocation — absolute path, never `./fg`.

**Why this plan exists now.** Both flakes surfaced during the execution of build arc 2 (backend
split + precompile externalization, `docs/archive/build-arc-2-backend-split-precompile-plan.md`).
Neither is caused by that arc — flake A was proven to fail on a fully reverted tree — but the arc's
gauntlet runs are what exposed them, and the investigation done there is captured below so nobody
repeats it. Arc 2 landed green and is closed; these two are the residue.

### Critical reframes — do not re-derive these

- **R1: "It passed on the serial retry" is not a diagnosis.** `fg gauntlet` retries a failed leg
  once, serially, and reports a pass as a "load-flake warning" (exit 0). That mechanism exists to
  absorb *boot storms*. Both flakes here reach the retry path while being something else entirely.
  A leg that fails in-wave and passes alone is a **finding to chase**, not a result to accept.
- **R2: a converged render is not necessarily the CORRECT render.** Flake B's capture helper already
  waits for two consecutive frames to hash identically. Both of the two observed states satisfy that.
  Frame-to-frame stability is a *weaker* condition than "finished" — see §2.3, where the framework
  itself caches a half-finished render into a back buffer that then re-blits stably forever.
- **R3: wall-clock slowness is not the trigger.** The tempting story ("the machine was slow, so it
  flaked") is falsified: a dpr2 leg ran at 1.91 min — the exact wall-clock of a *failing* run — and
  passed 268/268. What matters is *irregular* load (`DETERMINISM.md` class 3a), not mean slowness.
- **R4: flake A is NOT reference churn.** The test has **zero reference PNGs**. It cannot fail a
  screenshot comparison. Only one of its two `assertValuesEqual` calls can fail. Anyone who
  "recaptures references" for this test has misunderstood it and will change nothing.

---

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — confirm clean trees, note the suite count.
2. Read this doc fully, then `Fizzygum-tests/DETERMINISM.md` §2c, §3a, §3e and §4 (the playbook).
3. **Flake B first (§3).** It has a mechanically-supported hypothesis, a one-line candidate fix, and
   reproduces ~1 in 3 full gauntlets — it is by far the more tractable of the two. Flake A (§2) is a
   burst-mode 3a-class race that resisted every forcing technique tried; do not start there.
4. Every phase ends with its gate green (§5) before the next begins.
5. **Never commit or push without explicit owner approval** (standing rule).
6. Budget: assume gauntlet runs are ~5–6 min each and that confirming/refuting flake B costs
   several of them. Do not burn the budget re-running ad-hoc load loops that §2.4/§3.4 already
   record as ineffective.

---

## §1 Shared context: how a suite failure is (and is not) reported

Read this before either flake — it explains why the evidence below is thinner than you'd expect.

- `run-all-headless.js` polls the page for `world.automator.failedTests`, which holds **test names
  only**. It relays browser-console lines matching `/FAIL|UNCAUGHT|UNHANDLED|STALL/i` (or any
  `console.error`) with the current test name prefixed; `--verbose` relays every console line.
- A **screenshot** failure is self-documenting (reference vs obtained images, dumpable with
  `--dump-failures`). An **assertion-only** failure historically was not: `AutomatorPlayer`'s
  `recordMacroAssertion` wrote the FAIL text *only* to the in-page control-panel div
  (`SystemTestsControlPanelUpdater.addMessageToSystemTestsConsole`), which the parallel runner never
  reads. So a suite run could report "this test failed" and nothing more.
- **FIXED 2026-07-28** (`Fizzygum-tests/Automator-and-test-harness-src/AutomatorPlayer.coffee`, in
  `recordMacroAssertion`'s failure branch): it now ALSO `console.log`s
  `FAIL (assertion) <test>: <description> — expected: <e> found: <f>`, which the runner's existing
  `/FAIL/i` relay surfaces inline. **This is why the next occurrence of flake A self-documents.**
  Verify it is still present before relying on it:
  `grep -n "FAIL (assertion)" Fizzygum-tests/Automator-and-test-harness-src/AutomatorPlayer.coffee`

---

## §2 FLAKE A — `SystemTest_macroClosingRotatedIslandChildClearsFootprint`

### 2.1 What the test asserts

`Fizzygum-tests/tests/SystemTest_macroClosingRotatedIslandChildClearsFootprint/` — a macro test with
**no screenshots and no reference PNGs** (verify: `find <thatdir> -name '*.png' | wc -l` → 0). It
exists because a dropped invalidation *cannot* be caught by a screenshot: `readyForMacroScreenshot`
forces `world._fullChanged()` before every capture, repainting exactly the staleness being hunted
(`DETERMINISM.md` §2c). So it asserts a VALUE instead:

1. `assertValuesEqual "two inner calculating-patch-node windows exist; closing the top one", 2, calcWins.length`
2. `assertValuesEqual "closing a calc-node window in a tilted converter leaves NO broken-rect staleness (incremental render == full repaint)", 0, diff`

Assertion 2 is the flaky one (assertion 1 is structural). Its shape, from the macro source:

```coffee
calcWin.close()
yield "waitNoInputsOngoing"
ctx = world.worldCanvasContext
pixelsA = (ctx.getImageData 0, 0, W, H).data     # the INCREMENTAL (broken-rect) canvas
world._fullChanged()                             # ground-truth full repaint
yield "waitNoInputsOngoing"
pixelsB = (ctx.getImageData 0, 0, W, H).data
diff = <count of differing pixels>               # asserted == 0
```

**The structural risk is visible right there:** `yield "waitNoInputsOngoing"` drains the INPUT queue.
It does not guarantee a paint has flushed. See `DETERMINISM.md` §3e ("observing pixels requires
COMPLETING THE FRAME"). If the close's broken rects have not been painted when `pixelsA` is read,
`pixelsA` is a mid-flight canvas compared against a later full repaint — a false positive with no
framework defect behind it.

### 2.2 The two candidate mechanisms (unresolved — this is the whole question)

| # | Mechanism | Predicted `found:` value | Fix location |
|---|---|---|---|
| A1 | **Real broken-rect staleness** — the close genuinely drops an invalidation under some cycle interleaving | large, roughly the rotated footprint area (thousands) | framework (`_closeNoSettle` / `_fleshOutFullBroken` / island buffer) |
| A2 | **The macro reads mid-flush** — a test-side synchronization gap (§2.1) | small and variable (single/double digits, differing run to run) | the macro (wait for a completed frame, not just input drain) |

**Getting the `found:` value decides between them.** That is the single most valuable next datum,
and it is now automatic (§1).

### 2.3 Evidence timeline (2026-07-28)

All on one build unless noted. All nine failures fell inside ONE ~20-minute window; ~50 clean
full-suite runs followed in the next hour.

| Time | Run | Result |
|---|---|---|
| 14:51–15:04 | gauntlet #1 wave A: dpr1, dpr2, webkit (4 shards, 3 suites concurrent) | PASS ×3 |
| 14:51–15:04 | gauntlet #1 wave B: 6 prelude suites concurrent | **FAIL in settle, capstone, revisits, storage**; tiernaming + paint PASS |
| 15:04–15:08 | gauntlet #1 serial retries, each leg alone at 6 shards | **FAIL ×4** |
| ~15:06 | settle gate, 6 shards, **both repos reverted to `master`** | **FAIL** (1.91 min) |
| ~15:09 | settle gate, 6 shards, arc-2 code restored | PASS (1.40 min) |
| 15:10–15:28 | gauntlets #2 and #3 | PASS (13/13 and 12/13 + unrelated flake B) |
| 16:17–16:23 | gauntlet #4 | PASS — all four previously-failing legs green |

**⚠ The reverted-tree failure is the load-bearing fact: this flake exists on unmodified `master`.**
Do not attribute it to whatever you are currently changing without repeating that A/B (§4.1).

### 2.4 Everything that does NOT reproduce it (do not re-run these blind)

| Attempt | Runs | Result |
|---|---|---|
| The test alone, no prelude | several | PASS, `found: 0` |
| The test alone + the settle prelude (`PRELUDE_JS=`) | 1 | PASS, `found: 0` |
| `DETERMINISM.md` §4 Step-1 heavy-cycle injection, 2e6 spins/cycle | 1 | PASS, `found: 0` |
| …same at 2e7 spins/cycle (a very heavy cycle) | 1 | PASS, `found: 0` |
| Observed settle leg + 4 concurrent full suites as load | 1 valid | PASS — and at **1.41 min, no slower than idle** |
| **The exact wave-B shape: settle+capstone+revisits+storage concurrently, 4 shards each** | **4 rounds = 16 full suite runs** | **all clean** |

**The heavy-cycle result is the informative one.** `DETERMINISM.md` §4 states the render-state
classes (3b, 3c) reproduce **6/6** under that injection. This reproduces **0/2**, which places it in
**class 3a — the pure timer-starvation race that needs *irregular* load** and which the playbook
explicitly says may not be forcible that way. Combined with R3, do not expect to reproduce it by
making the machine uniformly slow or uniformly busy.

### 2.5 Next steps for flake A

1. **Net it, don't chase it.** Run the standing hunter overnight — it exists for exactly this and
   writes durable, disk-bounded evidence:
   ```
   cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
   caffeinate -i node scripts/torture-headless.js --dprs=1,2 --speeds=fast,fastest --shards=1,2,4,8
   # morning: cat .scratch/torture/REPORT.md ; ls .scratch/torture/failures/
   ```
   It rotates dpr × speed × shard-count round-robin — *irregular* load, which is what class 3a needs.
2. **Read the `found:` value** from the captured run (§1 makes it inline in the leg log). Then:
   - small/variable ⇒ **A2**. Fix the macro: replace the bare `yield "waitNoInputsOngoing"` before
     the `pixelsA` read with a wait that guarantees a completed frame. Check what the paint audit
     (`scripts/run-paint-audit.js`) and `AutomatorPlayer`'s own paint-truthfulness assertion use —
     they solve this exact "observe the canvas only when the frame is done" problem already, and the
     macro should reuse that verb rather than invent one.
   - large/constant ⇒ **A1**. A real dropped invalidation. Start from the plan that created this
     test (`docs/plans/affine-transforms-plan.md`, the `recordDrawnAreaForNextBrokenRects` fix) and
     from `docs/archive/menu-slider-ctor-conversion-plan.md`'s P4 closeout, which characterises this
     same test as "the suite's most load-sensitive incremental-repaint assertion".
3. If torture cannot catch it in a full night, say so in this doc and stop — an uncatchable 1-in-50
   flake with a self-documenting failure path is a known, bounded liability, not an open wound.

---

## §3 FLAKE B — serialization-rig `pixelParity` is BISTABLE  ← **START HERE**

### 3.1 The observations

`Fizzygum-tests/scripts/serialization-roundtrip-headless.js` (the `serialization` gauntlet leg).
Two occurrences, both **SWCanvas leg only — the native leg passed every one of its 37 checks both
times**:

```
2026-07-28 15:27
  [MISMATCH] world.samePage.pixelParity       before#1260335209 after#1077227077 (clock masked)
  [MISMATCH] world.crossSession.pixelParity   origA#1260335209  restoredB#1077227077

2026-07-28 16:21
  [MISMATCH] window.pixelParity.samePage      orig#3394276982  vs restored#1949127884 (360000 bytes)
  [MISMATCH] window.pixelParity.crossSession  origA#1949127884 vs restoredB#3394276982
```

**Read the second block carefully: exactly two hash values, appearing in both roles, SWAPPED.** A
widget settles into one of exactly two stable images and which one it lands in varies per
instantiation. 360000 bytes = 300×300×4 — the fixture is
`R.fixtures.window` = `new FrameWdgt(nil, { labelContent: 'my window' })`, i.e. a **text-bearing**
widget.

### 3.2 Why "it sampled too early" is already ruled out

`R.captureSettled` (grep it; ~line 220) does **not** take one sample:

```js
R.captureSettled = async function (w) {
  let prev = R.capture(w);
  for (let i = 0; i < 120; i++) {
    await R.settle(1);
    const cur = R.capture(w);
    if (cur.hash === prev.hash) return cur;   // two consecutive identical frames
    prev = cur;
  }
  return prev;
};
```

Both recorded values are therefore **converged**. Its own header comment records that a *previous*
flake in this family (`dropPixelParity`, 2026-07-27 — one day BEFORE arc 2, so this family predates
it) was a mid-settle sample, and this convergence loop was the fix. **That fix is insufficient here**,
because both states are stable (R2).

### 3.3 Leading hypothesis: lazily-loaded glyph atlases — mechanically confirmed, not yet caught in the act

The framework documents the exact mechanism that produces two stable renders of text. From
`Fizzygum/src/boot/extensions/SWCanvasElement-extensions.coffee` (grep `swCanvasAtlasPending`):

> `fillText` is always safe: SWCanvas paints **placeholder boxes when an atlas is cold**. After each
> `fillText` we make sure the atlas for the current font … is loaded; when the bytes arrive we
> repaint so the boxes become real glyphs. `swCanvasAtlasPending` counts in-flight loads — **it backs
> `world.anyTextDirty()` (the test screenshot gate)**.

and, crucially, why the cold state is *stable*:

> When a cold atlas was drawn its glyphs went into a **CACHED back buffer as placeholder boxes. A
> plain repaint just re-blits that cache**, so once the atlas is warm we must reset the
> immutable-back-buffer cache … and repaint.

That reset is scheduled through `requestAnimationFrame` (`swCanvasScheduleTextRefresh` →
`world.resetImmutableBackBuffersCache()`). So the sequence is:

**state X** (placeholder glyphs, cached, re-blits identically every frame → *converges*) → atlas
bytes arrive → rAF → cache reset + repaint → **state Y** (real glyphs, also stable).

Two stable states, and a capture that only checks frame-to-frame equality can land on either.

`WorldWdgt.anyTextDirty` (grep it) is the designated gate, and its own comment says so: *"The
SystemTest screenshot gate waits on this so it never captures un-settled text. Always false under
the native backend."* — which also explains why only the SW leg flakes.

**The smoking gun:** this rig is the only SWCanvas rig that never consults it.

```
grep -c anyTextDirty Fizzygum-tests/scripts/serialization-roundtrip-headless.js   # → 0
grep -c anyTextDirty Fizzygum-tests/scripts/swcanvas-hidpi-headless-check.js      # → 4
grep -c anyTextDirty Fizzygum-tests/scripts/smoke-boot-headless.js                # → 1
```

Load-sensitivity follows: atlases load by `<script>` injection over `file://`, so heavy parallel
load stretches precisely the window between state X and state Y.

**Status: mechanically supported, NOT empirically confirmed.** Nobody has yet observed
`anyTextDirty() === true` at the moment of a mismatching capture. Confirm that before fixing (§3.5).

### 3.4 What does NOT reproduce it

| Attempt | Runs | Result |
|---|---|---|
| The rig + 4 concurrent full suites as load | 6 | all clean |
| The rig alone | several | all clean |

It **does** reproduce at roughly **1 in 3 full `fg gauntlet` runs** — the gauntlet's wave B runs the
rig concurrently with ~8 other legs including several prelude-carrying suites, which is heavier and
more irregular than hand-rolled load. **Use `fg gauntlet` as the repro vehicle; do not rebuild a
bespoke load harness.**

### 3.5 Next steps for flake B (in order)

1. **Confirm the mechanism.** Temporarily record `world.anyTextDirty()` (and, if useful,
   `window.swCanvasAtlasPending`) alongside every hash `R.capture` returns, so a mismatch line shows
   the text state at capture time. Run `fg gauntlet` until the rig fails (expect ~3 runs). If the
   mismatching capture shows text dirty / atlases pending, the hypothesis is confirmed.
2. **Fix the rig, not the assertion.** Make `R.captureSettled` **and** `R.captureWorldMaskedSettled`
   require `world.anyTextDirty() === false` in addition to consecutive-frame hash equality — the
   same readiness condition the other two SW rigs already use. This is a strengthening of the
   convergence condition, not a tolerance: the checks still demand exact hash equality.
3. **Re-gate:** `fg gauntlet` ×3 clean (it fails ~1-in-3 unfixed, so three clean runs is a
   meaningful, if not conclusive, signal), plus `fg homepage`.
4. **Then ask the harder question — is the WORLD also exposed?** The rig is a test harness, but
   `anyTextDirty()` guards the *SystemTest screenshot gate* too. Audit whether any other pixel-reading
   path (the paint audit; `AutomatorPlayer`'s paint-truthfulness assertion; the file round-trip rig
   `serialization-file-roundtrip-headless.js`) captures without that gate. If one does, it has the
   same latent bistability. **This is the part that turns a rig fix into an actual elimination** —
   do not skip it.
5. If step 1 REFUTES the hypothesis (mismatch with text clean), record that here as a falsified idea
   and re-open: the next suspects are any other lazily-warmed cache that a repaint re-blits
   (the island buffer cache / `immutableBackBufferGeneration`, `docs/architecture/transforms.md`).

---

## §4 Techniques that worked (reuse these), and traps

### 4.1 The revert-and-rebuild A/B — do it EARLY

The single highest-value move of the whole 2026-07-28 investigation. When four gauntlet legs failed
and every serial retry reproduced it, it looked exactly like a regression from the in-flight arc.
Hours went into reasoning about which code path *could* matter. The A/B took ~8 minutes and settled
it outright: **the same gate failed on a fully reverted tree.**

```bash
# ⚠ NEVER `git stash` in these repos (2026-07-05: a stash pop silently emptied BOTH the working
# tree and the stash list). Use a patch + checkout.
git -C <repo> diff HEAD > /tmp/wip.patch     # HEAD, so STAGED changes are captured too
git -C <repo> checkout -- .                  # (and unstage anything staged)
/Users/davidedellacasa/code/Fizzygum-all/fg build
# …run the failing gate…
git -C <repo> apply /tmp/wip.patch           # restore
```
**Trap:** plain `git diff` misses staged changes (`git rm` / `git mv` land in the index). Use
`diff HEAD`, and re-save the patch immediately before reverting — not one saved earlier.

### 4.2 Concurrent runners kill each other's browsers

`run-all-headless.js` culls stale headless browsers at startup. Two concurrent runs therefore
`pkill` each other: every shard ends `[DISCONNECTED]` with `failed: 0`, which reads as a clean pass
and silently invalidates the experiment. **Export `FIZZYGUM_KEEP_STALE_BROWSERS=1` for every run in
a concurrent harness, do one `fg killz` up front, and treat any log containing `DISCONNECTED` as
INVALID — neither pass nor fail.** (`fg gauntlet` handles this itself; the trap is only for
hand-rolled harnesses.)

### 4.3 The heavy-cycle recipe needs a spin COUNT, not `Date.now()`

`DETERMINISM.md` §4 Step 1's original snippet used a `Date.now()`-bounded busy-wait. Two `Date.now()`
calls in `doOneCycle` trip the build's `timer` stink gate — **the build fails before you can run it.**
The doc has been corrected to a spin-count variant (which is also the more honest probe: no
wall-clock dependence). Re-read it there rather than reconstructing it.

### 4.4 Local repro harnesses

Two harnesses were written under `Fizzygum-tests/.scratch/` (gitignored, so they are LOCAL to the
machine that made them and may not exist in your checkout — recreate from §4.2's rules if needed):
`flake-repro.sh` (observed leg + N load generators) and `waveb-repro.sh` (the four prelude legs
concurrently). Both are recorded as **ineffective** for these two flakes (§2.4, §3.4). `fg gauntlet`
is the working repro vehicle for flake B; `torture-headless.js` is the right net for flake A.

---

## §5 Verification protocol

```
/Users/davidedellacasa/code/Fizzygum-all/fg status              # orientation, every phase
/Users/davidedellacasa/code/Fizzygum-all/fg build                # after any src/harness edit
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet             # the repro vehicle AND the gate
/Users/davidedellacasa/code/Fizzygum-all/fg homepage             # production-tree gate
cd Fizzygum-tests && node scripts/torture-headless.js …          # the overnight net (flake A)
```

Long-run discipline: launch minutes-long ops ONCE with the Bash tool's `run_in_background: true`,
redirect to a log, and wait for the task notification. Never hand-roll a foreground poll loop (the
guard hook blocks them). Peek with single commands: `cat /tmp/fg-<cmd>.verdict` or `tail -5` the log.

**Exit criteria for this plan:** flake B eliminated with the mechanism confirmed and §3.5 step 4's
audit done; flake A either fixed (with its `found:` value recorded here as the evidence that chose
A1 vs A2) or explicitly parked with a stated reason. Then `git mv` this doc to `docs/archive/`,
stamp it, and add an `archive/INDEX.md` line.

---

## §6 Rejected / do-not-re-attempt

1. **"It's a boot flake."** No: the boot-storm signature (`[shard N] did not start within 90s`,
   `ReferenceError: CoffeeScript is not defined`) appears in NONE of the logs. Every failing shard
   booted and ran its full segment.
2. **"Recapture the references"** for flake A — it has none (R4).
3. **Making the machine uniformly slow/busy** to reproduce either — falsified in §2.4 and §3.4, and
   contradicted by R3 (a 1.91-min leg passed 268/268).
4. **Heavy-cycle injection for flake A** — 0/2 at 2e6 and 2e7 spins (§2.4). It is class 3a.
5. **Accepting the `fg` load-flake warning as the answer** — that mechanism is for boot storms (R1).
6. **Widening the pixel-parity check to a tolerance** for flake B — it would hide a genuine
   two-state render. The check is right; the capture's readiness condition is what is wrong (§3.5).

---

## §7 References

- **`Fizzygum-tests/DETERMINISM.md`** — the subject-matter doc. §2c carries the condensed record of
  both flakes; §3a/§3e the relevant bug classes; §4 the diagnosis playbook (heavy-cycle injection,
  pixel forensics, disable-the-mechanism proof).
- `Fizzygum-tests/scripts/torture-headless.js` — the overnight nondeterminism hunter (flake A's net).
- `Fizzygum-tests/scripts/run-sequence-headless.js` — `--before=<name>` lists a test's in-suite
  predecessors; the tool for the §2d "passes-alone-but-fails-in-suite" class if flake A turns out to
  be a cross-test leak rather than a race.
- `docs/archive/build-arc-2-backend-split-precompile-plan.md` §12.8 — the arc during which both
  flakes surfaced, and the record of the false-alarm diagnosis.
- `docs/archive/menu-slider-ctor-conversion-plan.md` (P4 closeout) — the earlier characterisation of
  flake A's test as the suite's most load-sensitive incremental-repaint assertion.
- `Fizzygum/docs/architecture/transforms.md` — the island buffer cache, the other lazily-warmed
  cache in the system (flake B fallback suspect, §3.5 step 5).

## §8 Provenance

Authored 2026-07-28 from a live investigation during build arc 2: 4 full gauntlets, ~50 full suite
runs, a revert-and-rebuild A/B against unmodified `master`, heavy-cycle injection at two magnitudes,
16 suite runs at the exact wave-B concurrency shape, and 6 loaded serialization-rig runs. The
`recordMacroAssertion` console diagnostic and the `DETERMINISM.md` §2c records + §4 Step-1
correction were landed in the same session.
