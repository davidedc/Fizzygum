# Suite nondeterminism — non-boot flakes (discovered 2026-07-28)

**STATUS (updated 2026-07-28, same day): FLAKE B — root-caused, FIXED, gated and PUSHED (§3.6).
FLAKE A — **SOLVED 2026-07-29 (§2.6.1)**: hypothesis A3 CONFIRMED by direct measurement — a glyph
atlas warming between the macro's two pixel reads, not a dropped invalidation. FLAKE C (§2.7) — **SOLVED**: a `resetWorld` state leak
(`UntitledNamingService` counters) that made a default name render "Untitled 2"; it was invisible to
every standing gate because none of them runs 1 shard (§2.7.2).** Authored 2026-07-28, written to be executed COLD by an LLM/engineer with
ZERO prior context. Every fact below was verified against the working trees on 2026-07-28
(Fizzygum `master`, Fizzygum-tests `master`, suite = 268 SystemTests). Line numbers WILL drift —
**the quoted method/variable names and code snippets are authoritative; re-grep before trusting any
`file:line`.**

**Read §3.6 before §3.1–3.5.** Those sections are preserved as the pre-fix investigation record
(they are what made the fix findable), but §3.5's proposed one-line fix was **falsified at
execution** — see §3.6.

**MANDATE.** Eliminate these flakes at the root. The standing project bar is that a SystemTest
failure means a real defect: boot-storm infra flakes are tolerated (a shard that never starts), and
**nothing else is**. None of these is a boot flake. Do not "fix" either by loosening an
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
3. **ALL THREE FLAKES ARE SOLVED** — A (§2.5.1), B (§3.6), C (§2.7.1). This doc is now a record, not
   a work list. Read §2.5.1 and §3.6 before trusting any hypothesis in a future flake hunt: each
   contains a step that was FALSIFIED at execution, and §2.5.1 also shows a probe that was
   inconclusive in a way that nearly read as a refutation.
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

## §2 FLAKE A — **SOLVED 2026-07-29** (`SystemTest_macroClosingRotatedIslandChildClearsFootprint`)

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
| A3 | **A glyph atlas warms BETWEEN the two reads** — added 2026-07-28, see §2.6 | moderate and text-shaped (the glyph pixels of the converter's labels) | the macro (measure on a text-settled canvas) |

**Getting the `found:` value decides between them.** That is the single most valuable next datum,
and it is now automatic (§1) — as of 2026-07-28 it is accompanied by the text state that separates
A3 from the other two (§2.6).

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

### 2.5.1 RESOLVED 2026-07-29 — A3 CONFIRMED; the framework was innocent

**The flake was never caught; it was MEASURED.** The overnight net ran **223 iterations
(~65,000 test-executions)** without reproducing it — consistent with §2.4, and the reason the
netting strategy was abandoned in favour of forcing the mechanism (`DETERMINISM.md` §4 Step 1).

A scratch probe (`Fizzygum-tests/.scratch/a3-probe.js`, gitignored) replays the macro's steps as
plain API calls — legitimate, because this macro queues **no synthetic input events**, so
`yield "waitNoInputsOngoing"` returns after ~1 frame. Running in the HARNESS world post-`resetWorld`
(never `index-sw.html` — the desktop clock contaminates a hand-rolled diff, §3e):

| measurement at the macro's own cadence | result |
|---|---|
| read A vs a forced warm repaint | **7798 px**, bbox = the whole converter window |
| warm vs B | **0 px** — *no broken-rect staleness whatsoever* |
| A vs B (what the test asserts `== 0`) | **7798 px** ⇒ FAIL, 3/3 |

**A1 is therefore refuted and A2 is beside the point: the framework's invalidation is correct.** Only
the deferred atlas-warm repaint's timing decided pass vs fail.

⚠ **The first version of the probe was INCONCLUSIVE and nearly read as a refutation** — it settled
6–10 frames per step, which let the atlases warm and measured a text-final canvas (`A vs WARM = 0`).
The macro's real cadence is ~1 frame per yield. **Match the cadence you are investigating, or you
measure a different system.**

⚠ **The magnitude misleads** (this retires the §2.2 table's split): 7798 px is LARGE, exactly the
"large constant ⇒ A1" signature. **Read `gen` first**, always.

**Fix** (`Fizzygum-tests/tests/.../SystemTest_macroClosingRotatedIslandChildClearsFootprint_automationCommands.js`):
one line, `yield "waitForScreenshotReady"`, before `calcWin.close()` — the framework's own single
SWCanvas settle gate (`MacroToolkit.readyForMacroScreenshot`: text settled → one forced warm-atlas
repaint → a frame to flush). **Do not hand-roll a wait on `world.anyTextDirty()`**: that flag is a
weaker condition (the refresh only queues damage via `_fullChanged()`; pixels land at the next
`_updateBroken()`), and it is consumed from a macro only through this sentinel. Glyph-atlas warm-up is
ORTHOGONAL to broken-rect staleness, so this is a measurement PRECONDITION, not a tolerance — the
assertion still demands exactly 0.

**Proven load-bearing** (§4 Step-4 two-way control): at the identical cadence, without the line 3/3
diff 7798 px; with it 3/3 diff 0. **Gates:** standalone PASS with the diagnostic now reading
`textDirty=false gen=3` at BOTH reads (was `textDirty=true gen=1`); `fg gauntlet` 13/13, every leg
in-wave, `refs:PASS` (zero reference churn).

**Why §2.4's forcing techniques all failed:** uniform load (heavy-cycle injection, concurrent suites)
delays *both* reads equally. This needs the deferred refresh landing precisely BETWEEN them — only
*irregular* load does that, which is exactly the burst-then-silence epidemiology of §2.3.

### 2.5 (superseded) Next steps for flake A

> **STATE 2026-07-28 17:42 — the net is RUNNING.** `torture-headless.js` was launched with the
> command below, against the fresh post-fix build (`harness @ 17:41:20`, both trees dirty with the
> flake-B fix + the new §2.6 diagnostic — so anything it catches carries the `gen` datum).
> **Morning: `cat Fizzygum-tests/.scratch/torture/REPORT.md` then `ls .scratch/torture/failures/`,
> and read the `found:`/`gen` values per §2.6.** It is resumable and disk-capped; Ctrl-C writes a
> final report.

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

### 2.6 NEW HYPOTHESIS A3 (2026-07-28), a by-product of solving flake B

Flake B established that a SWCanvas canvas has a **stable but half-finished** state while glyph
atlases warm (§3.6), and that anything reading raw pixels must gate on text-settledness. **This
macro reads raw pixels and does not gate on it at all.** Its measurement spans a frame boundary:

```coffee
pixelsA = (ctx.getImageData 0, 0, W, H).data   # ← if a label here is still a placeholder BOX …
world._fullChanged()
yield "waitNoInputsOngoing"                    # … and the atlas lands during this gap …
pixelsB = (ctx.getImageData 0, 0, W, H).data   # … this repaint draws the REAL glyph
```

The fixture is `(new DegreesConverterApp).buildWindow()` — a text-heavy window (two labelled
calculating patch nodes). An atlas landing in that gap yields a **non-zero `diff` with no framework
defect behind it**, and it fits the observed epidemiology better than "the machine was slow":
atlases load by `<script>` injection over `file://`, so a machine-wide stall stretches exactly that
window — which explains the burst (nine failures in ONE ~20-minute window, then ~50 clean runs)
that uniform-load forcing never reproduced (§2.4, R3).

**It is cheap to tell apart, and now automatic.** `WorldWdgt.immutableBackBufferGeneration` bumps
once per atlas-warm cache reset, so the assertion now carries the text state at BOTH reads:

- `gen` **differs** between the reads ⇒ **A3 confirmed** — an atlas-warm repaint landed mid-measurement.
  Fix: make the macro wait for `world.anyTextDirty() === false` *before* `calcWin.close()`, so the
  whole A/B is measured on a text-settled canvas. That is a measurement PRECONDITION, not a
  tolerance — glyph-atlas warm-up is orthogonal to the broken-rect staleness under test, and the
  assertion stays `== 0`.
- `gen` **equal** and text clean ⇒ A3 refuted; fall back to the A1-vs-A2 split on the `found:` magnitude.

⚠ Do **not** pre-emptively apply the A3 fix. It would mask A1 (a real dropped invalidation) just as
effectively as it would cure A3, and A1 is the reason this test exists. Wait for the datum.

**First reading of the new diagnostic (2026-07-28, standalone PASS) makes A3 more than speculative:**

```
PASS … (incremental render == full repaint) [read A: textDirty=true gen=1 | read B: textDirty=true gen=1] (found: 0)
```

**Text is un-settled at BOTH reads even on an idle, passing run.** The measurement is routinely taken
while a glyph-atlas refresh is still pending — it passed only because the deferred refresh did not
happen to land in the gap (`gen` equal). The test builds a `DegreesConverterApp` window, which draws
fonts a freshly-reset world may not have warmed yet, so the whole warm-up can run *during* the
measurement. Whether the rAF lands between read A and read B is exactly the kind of irregular,
load-sensitive coin-flip that produces a burst of failures in one 20-minute window and nothing for
the next hour (§2.3) while resisting every *uniform*-load forcing technique (§2.4).

⚠ **Consequence for reading the `found:` value — this weakens the §2.2 magnitude test.** A3 would
repaint every label in the window from placeholder box to real glyph, so it can produce a LARGE diff,
not a small one. "Large ⇒ A1" is therefore no longer safe on its own: **check `gen` first**, and only
fall back to the magnitude split once A3 is excluded.

One question still open and cheap to answer when the datum arrives: at read A, is the text actually
still showing placeholder boxes? (`textDirty` is true for either "atlas in flight" or "refresh
scheduled"; only the former guarantees boxes.) The decisive probe is whether a forced
`resetImmutableBackBuffersCache()` at read A changes the pixels — do it in `.scratch/`, not in the
committed test.

---

## §2.7 FLAKE C — **SOLVED 2026-07-28** (found by the flake-A net; a DETERMINISTIC `shards=1` failure)

`SystemTest_macroSaveAsPromptAboveTiltedWindow` fails **100% at every `shards=1` config** and
passes at every other shard count. From the first 9 torture iterations:

| config | result |
|---|---|
| `dpr1-fast-s1`, `dpr1-fastest-s1`, `dpr2-fast-s1` | **FAIL 3/3** |
| `dpr1-{fast,fastest}-s{2,4,8}` | PASS 6/6 |

Signature: `FAIL - no screenshots like this one` and **the test COMPLETES** — so it is a REAL pixel
mismatch, not the §2b stall-watchdog false positive. Torture classifies it "DETERMINISTIC fail".

**⚠ This is NOT a flake and NOT caused by the flake-B fix.** Established by the §4.1 revert A/B
(the pre-fix tree, rebuilt, `--shards=1 --dpr=1 --speed=fastest`): **it fails identically on
unmodified `master`** — 268 tests, `failed: 1`, same test. Do not attribute it to the flake-B commits
(Fizzygum `e798b2c5`, tests `7cb613c3c`).

**⚠⚠ The standing gates are STRUCTURALLY BLIND to it.** `fg gauntlet` runs its suites at 4 shards
and `fg suite` at 8; nothing in the routine loop ever runs `shards=1`. This bug has therefore been
invisible to every green gate. That blind spot is arguably the more important finding than the bug.

**Torture bookkeeping.** After this finding the net was resumed as `--shards=2,4,8`: flake C is now
KNOWN and 100% deterministic, so leaving s1 in would burn ~11 min per s1 iteration re-proving it and
bury flake A's signal. Flake A has only ever been seen at 4–6 shards, so s2/4/8 is the right net for
it. The resumed run warns that its tallies "MIX builds" (`e0d3ce80-dirty` vs `e798b2c5-dirty`) —
**benign here:** `e0d3ce80-dirty` WAS the flake-B fix, uncommitted at the time, so the two labels
denote identical code.

**Where to start.** The shard count is the whole variable, and it is not a load axis — it is a
*predecessor-set* axis: at s1 the victim runs after all 267 other tests in ONE page; at s8 after only
~33. That is precisely **DETERMINISM.md §2d, the cross-test STATE LEAK class** (a world-level
ephemeral Set/Map that `_resetWorldNoSettle` leaves uncleared), and the leaking predecessor must be
one that does NOT share the victim's shard at s2/s4/s8 — a strong constraint that makes a bisect
cheap. Tool: `run-sequence-headless.js --before=SystemTest_macroSaveAsPromptAboveTiltedWindow`
to list predecessors, then bisect them.

⚠ **§2d's "SaveAs corollary" (2026-07-20) must be re-read, not trusted.** It records this same test
as an unreproducible low-frequency flake that did NOT reproduce under its exact in-suite prefix, and
concludes "do NOT recapture it". The 100%-at-s1 result contradicts the "unreproducible" half. The
"do not recapture" half still stands — recapturing would bake in whatever the leak produces.

### 2.7.1 RESOLVED — the `UntitledNamingService` counters survive `resetWorld`

**The pixels named it.** Neither existing runner could produce them (the suite runner has no
`--dump-failures`; `run-sequence`, which dumps, cannot reproduce), so a ~40-line probe booted the REAL
shard URL and read `world.automator.collectedFailureImages`. The delta was **46 pixels in one 11×15
character cell**: reference `Untitled`, live `Untitled 2`. Not a rendering bug at all — the default
document NAME.

**Root cause.** `UntitledNamingService` (`world.untitledNamingService`) counts the "Untitled" names
handed out. It is built in the `WorldWdgt` ctor and its own class comment calls the counters per-world
— but `resetWorld` REUSES the world object and `_resetWorldNoSettle` never reset them. A number is
consumed just by OPENING a save prompt (`SaveShortcutPromptWdgt` seeds `defaultContents` from
`getNextUntitledShortcutName()`), so one earlier prompt anywhere in the page shifts every later
default name. Shard count was the whole variable because it is a **predecessor-set** axis, not a load
axis: at s1 all 268 tests share one page.

**Fix** (reference-preserving — a fresh world SHOULD say `Untitled`; the leak was the defect):
`UntitledNamingService.resetCounters()`, called from `_resetWorldNoSettle` beside the highlight/pinout
set-clears whose comment already says *"resetWorld must reset ALL world state"*. Same product-safe
path; the snapshot serializer, which legitimately persists these counters, is untouched.

**Gates:** `--shards=1` **268/268** (was 6/6 failing); `fg gauntlet` 13/13 with `refs:PASS` (zero
reference churn). The gauntlet's `paint` leg was `PASS-serial-only` — its in-wave failure was
`audit ERROR: Cannot read properties of undefined (reading 'automator')` at 32 s during "probing test
count", i.e. a boot-readiness race in the audit's own probe BEFORE any test ran, not a paint offender;
the serial run checked all 268 with **0 offenders**. (`ReferenceError: boom is not defined` in that log
is the deliberate `#ERR` spreadsheet fixture.)

### 2.7.2 ⚠ Two findings bigger than the bug

1. **The gates are blind at `shards=1`.** `fg gauntlet` runs 4 shards, `fg suite` 8. Nothing in the
   routine loop runs 1. A fully deterministic failure therefore lived on `master` unseen; only
   `torture-headless.js`, which rotates `--shards`, caught it.
   ⛔ **OWNER DECISION 2026-07-28: NO s1 gate — too expensive (~6 min serial). Do not re-propose.**
   The residual coverage is `torture-headless.js`, which rotates `--shards=1,2,4,8` and is the tool
   that caught this one; run it when hunting, not on every commit.
2. **`_resetWorldNoSettle` deserves an AUDIT, not another patch.** Its comment says it must reset ALL
   world state, yet it has grown reactively — highlight sets, pinout sets, editor focus, now these
   counters — each added after a leak was caught in the field. The 2026-07-10 `widgetsToBeHighlighted`
   leak and this one are the same shape. Enumerate world-level mutable state and check it against that
   teardown; expect more.

⚖ **Method case law (this one cost real time — see DETERMINISM.md §2d's WITHDRAWN corollary).** The
state-leak hypothesis was declared FALSIFIED mid-investigation because replaying all 268 tests through
`run-sequence-headless.js` passed. That was wrong: `run-sequence` cannot reproduce this failure at all,
so its green said nothing about the hypothesis. **A green from an instrument you have not seen
reproduce the failure is not evidence of absence — confirm the tool reproduces before using its
silence to rule anything out.**

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

### 3.3 Hypothesis: lazily-loaded glyph atlases — **CONFIRMED 2026-07-28, then fixed (§3.6)**

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

**Status: CONFIRMED EMPIRICALLY 2026-07-28 — and reproduced DETERMINISTICALLY, no gauntlet needed.**
See §3.6 for the evidence, and for the one thing the hypothesis got WRONG (the proposed
one-line `anyTextDirty()` fix would NOT have worked).

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

### 3.6 EXECUTED 2026-07-28 — confirmed, fixed, audited

**The whole flake was cracked without a single gauntlet reproduction.** Rather than wait for a
~1-in-3 stochastic failure, the atlas warm-up was observed DIRECTLY: boot `index-sw.html`, place the
rig's exact fixture (`new FrameWdgt(nil, {labelContent: 'my window'})`) immediately at world-ready,
and hash it EVERY FRAME alongside `world.anyTextDirty()` and `WorldWdgt.immutableBackBufferGeneration`
(the counter that bumps once per atlas-warm cache reset). The warm-up walks through **three** stable
renders, and two of them are the flake's two hashes:

| frames | hash | `anyTextDirty()` | `gen` | what it looks like |
|---|---|---|---|---|
| 3–5 | `#2592767031` | true | 0 | **every** string is a placeholder box |
| 6–8 | `#3394276982` | true, **then false at frame 8** | 1 | icon captions real; the **title bar + "Drop a widget in here" still boxes** |
| 9+ | `#1949127884` | false | 2 | fully warm |

`#3394276982` and `#1949127884` are EXACTLY the pair from the 2026-07-28 16:21 occurrence
(`orig#3394276982 vs restored#1949127884`, then the same two swapped). The 15:27 occurrence's
`#1077227077` likewise turns out to be the fully-warm masked-world render (it is what the fixed rig
converges on every time), so `#1260335209` was its half-warm twin. **Mechanism: not in doubt.**

**⚠ What the hypothesis got WRONG — the proposed one-line fix was INSUFFICIENT.** §3.5 step 2
proposed gating the capture on `anyTextDirty() === false`. Look at frame 8 above: the half-warm
render is on screen and **`anyTextDirty()` already reads false**. The predicate under-reported,
because `swCanvasAtlasPending--` runs in the atlas `.then` *before* `swCanvasScheduleTextRefresh()`
defers the placeholder-clearing repaint to a rAF. So the counter hits 0 a frame or more before the
boxes are actually gone — and those boxes live in a cached back buffer that re-blits identically,
so the state is stable and a convergence capture converges on it. A rig gated only on the old
predicate would still have flaked. **This is why §3.5 step 1 (confirm before fixing) is in the plan:
the mechanism was right and the fix derived from it was not.**

**The fix, in two parts.**

1. **Framework — make the predicate honest** (`src/boot/extensions/SWCanvasElement-extensions.coffee`):
   `swCanvasAnyTextDirty` now returns `swCanvasAtlasPending > 0 or swCanvasRefreshScheduled`, and
   `doRefresh` clears `swCanvasRefreshScheduled` only AFTER applying the reset. `anyTextDirty()` now
   means what its doc always claimed — "the screen may still be showing placeholder boxes" — for the
   whole window, not just the loading half. Re-running the frame probe on the fixed build shows the
   half-warm render now carrying `textDirty=true`; the predicate goes false only on the frame the
   fully-warm render appears. `WorldWdgt.anyTextDirty`'s doc-comment was updated to match.
2. **Both serialization rigs — use the framework's own gate** instead of convergence alone.
   `R.captureSettled` / `R.captureWorldMaskedSettled` (`serialization-roundtrip-headless.js`) and
   `R.captureSettled` (`serialization-file-roundtrip-headless.js`) now `await R.awaitScreenshotReady()`
   first, which polls **`world.macroToolkit.readyForMacroScreenshot()`** — the framework's single
   SWCanvas screenshot settle gate (wait text-settled → force ONE warm-atlas repaint via
   `resetImmutableBackBuffersCache` → wait a frame to flush it) — and only then runs the existing
   consecutive-frame convergence loop. Forcing the repaint is what makes the result independent of
   *when* the deferred refresh happens to land, so part 2 does not merely lean on part 1. Reuse, not
   re-derivation: the rigs and the suite's screenshot gate can no longer drift apart. (The gate ships
   in every build that emits `index-sw.html` — only `--homepage` strips `src/macros`, and a
   `--homepage` build has no SWCanvas page for these rigs to boot — so its absence now throws loudly
   rather than silently degrading.)
   Neither part loosens anything: the checks still demand exact hash equality.

**Self-documenting from now on.** Every capture records `textDirty` and `gen`, and every
`pixelParity` detail line prints them for both sides — e.g.
`orig#1949127884 [textDirty=false gen=3] vs restored#1949127884 [textDirty=false gen=4]`. A future
recurrence names its own cause instead of costing another investigation. (`gen` differing by one
between the two sides is normal and expected — it is the gate's own forced reset.)

**§3.5 step 4 — the audit of every other pixel-reading path.** This is what makes it an elimination
rather than a rig patch:

| path | gated? | verdict |
|---|---|---|
| SystemTest screenshots (`compareScreenshots` ← `takeScreenshot_InputEvents_Macro`) | `readyForMacroScreenshot` — full protocol | **safe** (and it survived the old under-reporting predicate only because it forces the reset itself) |
| `AutomatorPlayer.checkPaintTruthfulness` / `assertPaintTruthfulAfterFullRepaint` (paint audit) | no text gate | **safe** — `before`/`after` are read SYNCHRONOUSLY with no await between them, so no atlas can land mid-measurement |
| `serialization-roundtrip-headless.js` | was convergence-only | **was exposed — FIXED** (flake B itself) |
| `serialization-file-roundtrip-headless.js` | was convergence-only | **was exposed — FIXED.** Same `captureSettled` shape, same text-bearing `FrameWdgt` fixture. Its 2026-07-27 `dropPixelParity` flake was diagnosed as a mid-settle sample and "fixed" with the convergence loop; on this evidence that was very likely the SAME bistability, and convergence alone would not have cured it |
| `swcanvas-hidpi-headless-check.js` | gates on `anyTextDirty()` | **safe** — reads canvas *dimensions* only, never pixel hashes |
| `smoke-boot-headless.js` | gates on `anyTextDirty()` | **safe** — boot readiness only, no pixel hashes |

**Gates (§5).** `fg gauntlet` ×3 back to back, all **13/13 PASS, zero reference churn** —
17:27 (253s), 17:36 (251s), 17:40 (259s) — plus `fg homepage`. The meaningful detail is not just
"green": the `serialization` leg now reads **`serialization:PASS` IN-WAVE** in all three, where the
pre-fix baseline run (16:41) read `serialization:PASS-serial-only` — i.e. it had failed inside the
concurrent wave and passed only on `fg`'s serial retry. That retry-shaped signature is exactly what
this flake looked like, and it is gone. Three runs is a meaningful, not conclusive, signal against a
~1-in-3 flake (P(3 clean by luck) ≈ 30%) — but combined with a root cause reproduced deterministically
and a fix that removes the mechanism, not the symptom, the case is closed.

⚠ **One process trap cost a run.** Gauntlet #2 was invalidated by editing a `src/*.coffee` file
*while it ran*: `fg gauntlet` builds ONCE up front, so wave B's stale-build guard refused to run and
`settle`/`capstone` failed at 0s/3s with `runner exit=2` / `prelude installed 0/0` — which reads like
a serious regression and is not. During a long op, treat `fg`, `src/**`, and `tests/**` as read-only
(docs and plans are fine). If it happens: kill the run and restart clean; do not try to salvage it.

**A lead for flake A fell out of this** — see §2.6.

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
