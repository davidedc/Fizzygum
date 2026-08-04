# Budgeted source-compile scheduler — replace "one class per turn" with an end-of-frame time budget

**STATUS: EXECUTED + CLOSED 2026-08-04.** Landed as one change, full gauntlet green (14/14).
As-built deviations from the text below: the pump chunk is **10 ms, not 40** (§5.1's as-built note —
40 ms blocks collapsed the parallel test wave, twice), and the tests-repo comment sweep
(two lazy rigs, `staleness-census.js`, `Fizzygum-tests/CLAUDE.md`) rode along. Measured results:
`docs/measurements/budgeted-compile-scheduler-2026-08-04.md`.

**Originally: PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-02. Design fact-checked against src the same day; every `file:line` below was
verified then, but **lines drift — the quoted method names and code are authoritative; grep them
fresh before trusting a line number.**

**Mandate:** eliminate the one-class-per-turn pacing rule entirely — both copies of it — and replace
it with ONE budget-aware scheduler. Do not add a third pacing mechanism next to the two existing
ones, and do not special-case one path while leaving the rule alive on the other.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on a single canvas; ~470 classes ship as SOURCE
TEXT (`SourceVault`) and are compiled in the browser by the bundled CoffeeScript compiler — at boot
on a `dev` tree, or on demand when a LAZY part arrives behind a running world
(`docs/architecture/build-and-packaging.md` §2/§5, `docs/explainers/boot-and-lazy-parts.html`).
Production (`--profile homepage`) boots from a pre-compiled image in ~54 ms and compiles nothing at
boot; the dev tree compiles everything at boot: measured 3219 ms, 97% of it compile+execute of 452
sources over ~52k lines (`docs/measurements/boot-timing-2026-07-31.md`).

Today, runtime ingestion compiles **one class per turn** — a deliberately simple pacing that keeps
the page responsive. The owner wants it replaced with: (1) the compile stage moved to the END of the
frame, after paint; (2) a per-class compile-time estimate derived from line count; (3) multiple
classes compiled in one frame when the leftover frame budget allows.

**Critical reframe #1 — "one class per frame" is really two different pacings.** The pacing
primitive `waitNextTurn` has two modes. Behind a RUNNING world (lazy-part ingest, and background
source ingest on a `sources: "background"` tree) it is literally one class per world cycle. On the
dev compile-at-boot path there IS no world yet — the sources are being compiled to build one — so
it is one class per `setTimeout(…,1)` turn, and nested-timeout clamping makes each turn cost
~1–4 ms of dead wait (~450 turns).

**Critical reframe #2 — the compile already executes after paint.** Resolving a pacing promise only
schedules a microtask, which runs after `doOneCycle` returns — i.e. after `_updateBroken()` has
painted. Moving the drain to end-of-frame changes almost nothing about execution position; what it
changes is **measurability**: a synchronous drain loop can time each compile with `performance.now()`
and decide "does the next one fit?", which the promise-resolve mechanism structurally cannot.

## §0.5 Cold-execution protocol

1. Read this whole doc first. Then read, in full: `src/boot/loading-and-compiling-coffeescript-sources.coffee`
   (~205 lines), `src/PartsRegistry.coffee` (~280 lines), and `WorldWdgt.doOneCycle` +
   `progressFramePacedActions` + `_updateTimeReferences` in `src/WorldWdgt.coffee` (grep the names).
   Skim `src/boot/globalFunctions.coffee` around `loadReflectiveLayerPromise` and the
   `loading-and-compiling-coffeescript-sources-min.js` fetch.
2. Re-verify the §1 facts against what you just read (methods move; the mechanism has been stable).
3. Implement §5 as ONE change — the drain point and the two callers are interdependent; there is no
   useful intermediate commit.
4. Gate with §8 in order. Long ops (`fg gauntlet`) run in background with output redirected to a log;
   never foreground-poll (the guard hook blocks it).
5. Owner preferences in force: ask before commit/push; comments/docs are a deliverable (update every
   stale comment §10 lists, in the same change).

## §1 The mechanism as it stands today (verified 2026-08-02)

All paths relative to `Fizzygum/`.

- **Pacing primitive** — `src/boot/loading-and-compiling-coffeescript-sources.coffee:31-50`,
  `waitNextTurn()`:
  - if `window.preCompiled` → `waitNextWorldCycle()`: pushes its resolver onto
    `window.framePacedPromises` (declared `src/boot/globalFunctions.coffee:20`);
    `WorldWdgt.progressFramePacedActions` (`src/WorldWdgt.coffee:1674-1677`) shifts and resolves
    EXACTLY ONE per cycle, called EARLY in `doOneCycle` (`:1739`, before paint).
  - else → `waitNextJSEventLoopCycle()`: `setTimeout(…,1)`.
- **Boot ingest loop** — same file, `storeSourcesAndPotentiallyCompileThemAndExecuteThem`
  (`:119-166`): promise chain of `waitNextTurn()` + one
  `storeSourceAndPotentiallyCompileItAndExecuteIt(fileName, justIngestSources)` per file from
  `findLoadOrder()`, skipping `Class`/`Mixin`/`globalFunctions`. Also sets
  `window.hasProp/indexOf/slice` and manages the loading log div.
- **Per-class work unit** — `storeSourceAndPotentiallyCompileItAndExecuteIt` (`:168-206`):
  `new Class fileContents, …` (or `new Mixin …`); `justIngestSources` means register-only, no
  compile. Per-class progress-log writes at `:201-202`. Only `compileFGCode` throws;
  `Class`'s eval errors are caught internally (`src/meta/Class.coffee` ~`:445-447`).
- **Lazy-part ingest loop (the DUPLICATE of the rule)** — `src/PartsRegistry.coffee`
  `_ingestPartPromise` (`:265-278`): filters fresh names, orders them via `findLoadOrder()`, then
  the same waitNextTurn-per-class chain via `_createIngestClosure`. Batch FETCH pacing (script
  tags) also uses `waitNextTurn` (`:234-236` and boot loader `:93-99`) — that stays.
- **Error semantics** — a throw rejects the chain, skipping that chain's remaining compiles;
  `ensureLoaded`'s rejection handler resets the part to `NOT_LOADED` (`PartsRegistry.coffee:124-128`);
  the dev-boot chain has no handler (boot halts, loudly).
- **Frame loop** — `animloop` (rAF → `world.doOneCycle()`, `src/boot/globalFunctions.coffee:467-471`).
  Paint is `@_updateBroken()` (`src/WorldWdgt.coffee:1786`); then `WorldWdgt.frameCount++` (`:1788`).
  NO frame-budget machinery exists; the only cycle clock is `WorldWdgt.dateOfCurrentCycleStart`
  (a `Date`, set `:1709`, nil'd `:1791`).
- **File delivery** — `loading-and-compiling-coffeescript-sources.coffee` is compiled standalone to
  `js/src/loading-and-compiling-coffeescript-sources-min.js` and loads in EVERY artifact (it defines
  `compileFGCode`, product machinery — `globalFunctions.coffee:365-374`). Its top-level bindings are
  window properties (classic-script `var` hoisting) — that is how `PartsRegistry` already calls
  `waitNextTurn`. ⚠ On a precompiled boot, `createWorldAndStartStepping()` runs at `:362-363`,
  BEFORE that file's fetch at `:371-374` — the world steps while the scheduler does not exist yet.
  (Precedent for this exact failure: `globalFunctions.coffee:55-60`, "window.fizzygumPartIsEagerHere
  is not a function".) On the dev path, `createWorldAndStartStepping()` runs only AFTER the compile
  job resolves (`:180-188`) — pump and world can never coexist mid-ingest there.
- **Boot tails** — `globalFunctions.coffee:169-190`: the `.then` after the ingest sets
  `stillLoadingSources = false` (a completion latch polled by
  `../Fizzygum-tests/scripts/generate-pre-compiled-headless.js`) and runs
  `runPostBootActionsOnce()` / `createWorldAndStartStepping()`. These call sites must keep working
  UNCHANGED — the new enqueue API must return an equivalent promise.
- **Line counts** — nothing stored anywhere, but `extractDependenciesFromSource`
  (`src/boot/dependencies-finding.coffee:72`) already does `SourceVault.get(eachFile).split '\n'`
  for every source and throws the array away.
- **Progress UI** — dev boot only: `<div id="loadingLog">` (`src/boot/logging-div.coffee`), created
  at `globalFunctions.coffee:177`; the lazy-part path never creates it (all helpers no-op).
- **Determinism boundary** — the harness pages preset `FIZZYGUM_EAGER_ALL_PARTS`
  (`globalFunctions.coffee:40-63`), so the queue is EMPTY for the entire SystemTest suite. The three
  lazy-part rigs (`../Fizzygum-tests/scripts/parts-lazy-load-headless.js`, `parts-lazy-icons-headless.js`,
  `parts-snapshot-load-headless.js`) poll observable conditions under wall-clock timeouts — no
  frame-count assertions (verified 2026-08-02).

## §2 Why it is shaped this way

One-per-turn was chosen for simplicity and to keep the page responsive: on the dev boot the yield
lets the loading log repaint; behind a live world it avoids jitter ("we don't cause gitter",
`WorldWdgt.coffee:1667-1673`). The promise-chain shape made "yield between units" trivial to
express — at the cost of making elapsed-time measurement impossible (each unit runs in a microtask
the scheduler never sees the end of) and of encoding the rule twice.

## §3 The distilled argument for the fix

- **The rule is duplicated** (boot ingest + `_ingestPartPromise`), and this repo's own case law says
  extract before changing (`PartsRegistry.coffee:41-46`: "Two places encoding one rule IS the bug").
- **One-per-frame is far too conservative behind a world.** Mean compile ≈ 7 ms/source against a
  16.7 ms frame that is mostly idle during a lazy-part load; a 10-class part takes 10 frames where
  ~3 would do. Worse: a REFLECTIVE-LAYER ingest on a production tree (opening an inspector) is ~450
  ingest-only items = 450 frames ≈ **7.5 s**, when the items are so cheap that tens of frames would
  do.
- **One-per-setTimeout is worse than too conservative at dev boot** — ~450 clamped timer turns are
  pure dead time on the critical path of every dev iteration.
- **A synchronous budgeted drain solves both with one mechanism**, and the measured per-item actuals
  make the estimator self-calibrating (the flat-average trap — a per-class constant over-predicts
  small classes ~2×, `docs/measurements/boot-timing-2026-07-31.md` — is avoided by estimating per
  LINE and correcting with an EWMA of observed ms/line).

## §4 Owner-locked decisions (2026-08-02 — do not re-litigate)

1. **Both paths, one shared queue** — the scheduler serves the running-world drain AND the dev-boot
   pump.
2. **Always process at least 1 item per drain** — guaranteed progress; an over-budget frame degrades
   to exactly today's behavior, never worse.
3. **STRICT dependency order — no size-based cherry-picking.** When the next-in-order class's
   estimate doesn't fit the remaining budget, STOP and resume next frame. Never scan ahead for a
   smaller class that would fit. Rationale: `findLoadOrder()`'s sequence is a correctness input and
   the only ordering ever exercised; the dependency map is known-approximate (arc 4: the scanner
   cannot see method-body `new X`); packing payoff is a few ms/frame. Explicitly asked and declined
   — see §9.

## §5 Fix shape

### §5.1 `window.SourceCompileScheduler` — a boot-level plain object

Lives in `src/boot/loading-and-compiling-coffeescript-sources.coffee`, next to the work unit it
drives. It CANNOT be a Class-system class (it schedules the compiles that create the class system;
on the dev path nothing exists when it first runs) — the `SourceVault` plain-object pattern.
`waitNextTurn`/`framePacedPromises`/`progressFramePacedActions` REMAIN, but only for batch-fetch
pacing — their "only batches" comments finally become true.

**Job** = one caller's ordered compile list. Preserves today's chain semantics exactly: in-order
execution, first-error-drops-this-job's-remainder, one completion promise per caller.

```coffee
# {names: [...], nextIndex: 0, justIngestSources: bool, resolve:, reject:}
```

**Public API** (keep minimal — the dead-method build gate): `enqueueJob(names, justIngestSources) -> Promise`
(callers: boot ingest, `_ingestPartPromise`; empty list resolves immediately) and
`drainAtEndOfCycle(cycleStartPerfMs)` (caller: `doOneCycle`).

**Drain loop** — synchronous, so actual elapsed is measurable per item:

```coffee
TARGET_FRAME_MS: 16.7      # rAF nominal at 60 Hz (see §7 risk 3)
FRAME_HEADROOM_MS: 3       # compositor/rAF-dispatch slack
NO_WORLD_CHUNK_MS: 10      # dev-boot pump chunk — AS-BUILT: 10, not the 40 first proposed here.
                           # 40ms chunks COLLAPSED the presuite's parallel wave twice (2026-08-04):
                           # all 8 suite shards lost their pages at once mid-run and all 5 paint
                           # shards hit "world never booted" (180s protocol timeouts), while either
                           # leg alone passed — a booting page holding its core in 40ms
                           # uninterruptible blocks starves Chrome's protocol deadlines when ~13
                           # dense pages compete. ~10ms restores the old per-class yield
                           # granularity (one ~7ms compile per timer turn) that co-existed fine,
                           # while still batching ~10+ classes per turn (measured ~0.7ms/class).

drainAtEndOfCycle: (cycleStartPerfMs) ->
  return if @_jobs.length is 0        # dark-cheap, like the other cycle stations
  @_drain (@TARGET_FRAME_MS - @FRAME_HEADROOM_MS) - (performance.now() - cycleStartPerfMs)

_drain: (budgetMs) ->
  processedAtLeastOne = false
  loop
    job = @_nextJob()
    break unless job?
    name = job.names[job.nextIndex]
    # owner decision §4.2: ALWAYS process at least one item
    break if processedAtLeastOne and (@_estimateMs name, job.justIngestSources) > budgetMs
    t0 = performance.now()
    try
      storeSourceAndPotentiallyCompileItAndExecuteIt name, job.justIngestSources
    catch err
      # must NOT propagate: a throw out of doOneCycle would unwind animloop.
      # console.error on purpose: every headless gate fails on it.
      console.error "SOURCE_COMPILE_FAILED: #{name}: " + (err?.stack ? err)
      @_removeJob job
      job.reject err                  # this job's remaining names are DROPPED (old chain semantics)
      processedAtLeastOne = true
      continue
    elapsed = performance.now() - t0
    @_observe name, job.justIngestSources, elapsed
    budgetMs -= elapsed
    processedAtLeastOne = true
    job.nextIndex++
    if job.nextIndex >= job.names.length
      @_removeJob job
      job.resolve()                   # a microtask — same position as today's chain resolution
  return

# Two tiers: interactive compile-and-execute jobs (part loads, dev boot) preempt background
# ingest-only jobs (the reflective-layer pass); FIFO within a tier.
_nextJob: ->
  for eachJob in @_jobs
    return eachJob unless eachJob.justIngestSources
  @_jobs[0]
```

**Estimator** — static prior refined by a per-mode EWMA of observed ms/line. Two modes because
ingest-only (`new Class src, false, false` — register, no compile) is far cheaper per line than
compile-and-execute; mixing them in one average would corrupt both:

```coffee
_msPerLine: { compile: 0.06, ingest: 0.012 }   # priors: 3116 ms / ~52k lines; ingest is a guess —
EWMA_ALPHA: 0.2                                 # the EWMA corrects both from the first observation
FALLBACK_LINE_COUNT: 150
MIN_ESTIMATE_MS: 0.5    # fixed per-class overhead floor (the measured 2× small-class caveat, inverted)

_lineCountOf: (name) -> window.sourceLineCounts?.get(name) ? @FALLBACK_LINE_COUNT
_estimateMs: (name, justIngestSources) ->
  Math.max @MIN_ESTIMATE_MS, (@_lineCountOf name) * @_msPerLine[@_modeKey justIngestSources]
_observe: (name, justIngestSources, elapsedMs) ->
  lines = @_lineCountOf name
  return if lines < 1
  key = @_modeKey justIngestSources
  @_msPerLine[key] = (1 - @EWMA_ALPHA) * @_msPerLine[key] + @EWMA_ALPHA * (elapsedMs / lines)
```

Over-prediction on small classes errs SAFE (fewer compiles per frame, never a blown frame). An
affine `fixed + lines*rate` model is a possible later refinement, deliberately not required.

**Dev-boot pump** (no world; also serves `?generatePreCompiled` boots, where `js/pre-compiled.js`
is the `preCompiled = false` stub):

```coffee
_ensurePumpScheduled: ->
  return if window.world?      # a stepping world's cycle drains us instead
  return if @_pumpScheduled
  @_pumpScheduled = true
  setTimeout (=> @_pumpTurn()), 0

_pumpTurn: ->
  @_pumpScheduled = false
  return if window.world? or @_jobs.length is 0
  @_drain @NO_WORLD_CHUNK_MS   # a small chunk of compiles, then yield so the log div repaints
  @_updateBootLog()            # ONE DOM write per chunk: "compiling and evalling <lastName> (N/M)"
  @_ensurePumpScheduled() if @_jobs.length > 0
```

`enqueueJob` calls `_ensurePumpScheduled()`. This collapses ~450 clamped `setTimeout(1)` turns into
~80 chunked turns — expect a measurable dev-boot improvement (MEASURE it, §8.7; do not write a
number down anywhere before measuring — "no conclusions before evidence"). The per-class log writes
at `:201-202` move OUT of the work unit into `_updateBootLog` (they were no-ops on the lazy path
anyway), and the `(N/M)` counter is finally meaningful because it repaints between chunks.

**Line counts** — recorded where the split already happens, inside `extractDependenciesFromSource`
(`src/boot/dependencies-finding.coffee:72`):

```coffee
window.sourceLineCounts ?= new Map    # a Map, not an object: Object.prototype is extended here
window.sourceLineCounts.set eachFile, lines.length
```

Both enqueue sites run `findLoadOrder()` immediately before enqueueing, so the map is warm for
every queued name. NO new `SourceVault` API (its header's dead-method-gate warning stands; the
vault stays a text registry).

### §5.2 Caller rewiring

`storeSourcesAndPotentiallyCompileThemAndExecuteThem` becomes:

```coffee
storeSourcesAndPotentiallyCompileThemAndExecuteThem = (justIngestSources) ->
  emptyLogDiv()
  loadOrder = findLoadOrder()
  window.hasProp = {}.hasOwnProperty
  window.indexOf = [].indexOf
  window.slice = [].slice
  names = (f for f from loadOrder when f not in ["Class", "Mixin", "globalFunctions"])
  window.SourceCompileScheduler.enqueueJob(names, justIngestSources).then -> removeLogDiv()
```

Return/rejection semantics identical ⇒ the `globalFunctions.coffee:169-190` boot tails
(`stillLoadingSources = false`, `runPostBootActionsOnce()`, `createWorldAndStartStepping()`) need
NO changes.

`PartsRegistry._ingestPartPromise` becomes:

```coffee
_ingestPartPromise: (partName) ->
  fresh = (name for name in SourceVault.namesForPart partName when not window[name]?)
  ordered = (name for name from findLoadOrder() when name in fresh)
  ordered = ordered.concat (name for name in fresh when name not in ordered)
  window.SourceCompileScheduler.enqueueJob ordered, false
```

Delete `_createIngestClosure`. Batch-fetch pacing stays on `waitNextTurn`. `ensureLoaded`
bookkeeping/rejection handling and `whenAllLoaded`'s SYNCHRONOUS fast path (correctness, not
optimisation — `PartsRegistry.coffee:135-151`): untouched.

### §5.3 The end-of-frame drain point

In `WorldWdgt.doOneCycle`: capture `cycleStartPerfMs = performance.now()` as a **local** at the top
(no new statics — nothing for the resetWorld completeness ratchet to see), and insert between
`@_updateBroken()` and `WorldWdgt.frameCount++`:

```coffee
# END-OF-FRAME compile station: budget-drain pending class-source compiles AFTER paint, so a
# load burst spends only the frame time paint left over, and at least one source per frame
# regardless. Guarded: on a precompiled boot the world steps before
# js/src/loading-and-compiling-coffeescript-sources-min.js arrives.
window.SourceCompileScheduler?.drainAtEndOfCycle cycleStartPerfMs
```

`progressFramePacedActions` stays where it is (early in the cycle — gives a batch fetch the whole
frame of network time), with its comment corrected to "batch fetches only".

### §5.4 Files to modify (one change)

1. `src/boot/dependencies-finding.coffee` — record `window.sourceLineCounts` (2 lines + a comment
   naming the consumer).
2. `src/boot/loading-and-compiling-coffeescript-sources.coffee` — add `window.SourceCompileScheduler`;
   rewrite `storeSourcesAndPotentiallyCompileThemAndExecuteThem`; remove the per-class log calls
   from the work unit; rewrite the header comment (`:1-31`). Add a `srcLoadCompileDebugWrites`-gated
   per-drain line — `"compile drain: N items in X ms (budget B)"` — the §8.7 probe instrument.
3. `src/WorldWdgt.coffee` — `cycleStartPerfMs` local + drain call; fix the stale comment at
   `:1667-1673`.
4. `src/PartsRegistry.coffee` — `_ingestPartPromise` rewrite; delete `_createIngestClosure`; update
   comments `:8-14`, `:21-25`, `:237`, `:258-264` (see §10).
5. `src/boot/globalFunctions.coffee` — `:17-19` comment (`framePacedPromises` now genuinely only
   paces batch fetches).
6. `docs/explainers/boot-and-lazy-parts.html` — see §10.

## §6 Edge cases

- **Empty queue**: `drainAtEndOfCycle` early-returns on a length check. `enqueueJob([])` resolves
  immediately (overlapping `requires` chains can leave a part with zero fresh names).
- **World not yet existing**: the pump self-schedules on `setTimeout(0)`; exclusion vs the world
  drain is structural on the dev path (the world is created only after the job resolves) plus the
  belt-and-braces `window.world?` guards in the pump.
- **Scheduler not yet existing** (precompiled boot, first cycles): the `?.` guard in `doOneCycle`.
- **Part load racing background ingest** (`sources: "background"` trees — none shipped today): the
  two-tier `_nextJob` lets the user-triggered job preempt the ~450-item ingest-only job — strictly
  better than today's 1:1 interleave. ⚠ A pre-existing hazard is NOT worsened and NOT fixed here: a
  part class compiling before a core superclass's ingest-only item has registered its metadata was
  already possible under the interleave; flag it in the PartsRegistry comment.
- **Error mid-batch**: per-item try/catch (a throw out of `doOneCycle` would unwind `animloop`); the
  job rejects, its remainder drops, other jobs continue; `console.error` fails every headless gate.
  Dev-boot rejection halts boot exactly as today.
- **A compile whose execution enqueues more work**: the drain re-reads `@_jobs` each iteration;
  true synchronous re-entry is impossible (part loads begin with async fetches; only `doOneCycle`
  and the pump call `_drain`).
- **`?generatePreCompiled` boot**: pump path; `JSSourcesContainer` accumulation and the driver's
  `stillLoadingSources === false` poll are unchanged, just faster.
- **Reflective-layer ingest on a lazy (production) tree** (opening an inspector): ~450 ingest-only
  items drain in tens of frames instead of ~450 frames (≈7.5 s) — a real product win; note it in
  the change description.

## §7 Risks

1. **One heavy class still blows a frame** — inherent in the ≥1-per-frame guarantee; no regression
   vs today's one-per-frame.
2. **Estimator underestimate → frame overrun** — bounded by the EWMA's adaptation and the 3 ms
   headroom; worst case is a dropped frame during a load burst, outside any test's observation.
3. **High-refresh displays** — the static 16.7 ms target overruns 8.3 ms frames during bursts.
   Accepted for now; a later refinement could derive the target from the measured cycle interval.
4. **Determinism** — budgeted batching is wall-clock-dependent BY CONSTRUCTION. It is permissible
   only because (a) the suite pages preset `FIZZYGUM_EAGER_ALL_PARTS`, so the queue is empty for
   the entire suite, and (b) the lazy rigs await promises / poll conditions, never frame counts.
   The per-cycle `performance.now()` feeds nothing downstream of render/layout. State this
   invariant in the PartsRegistry comment (§10).
5. **`stillLoadingSources` flips earlier** — all consumers treat it as a completion latch, not a
   schedule; safe.

## §8 Verification protocol (in order)

1. `/Users/davidedellacasa/code/Fizzygum-all/fg build` — syntax gate, dead-method gate (deleted
   `_createIngestClosure`; every new scheduler method must have a consumer), part-edges gate.
2. `fg presuite` — dpr1 suite + paint audit (~2 min): proves the empty-queue drain changes zero
   pixels/cycles.
3. Dev boot by hand: open `../Fizzygum-builds/latest/index.html` — chunked progress log with a
   moving `(N/M)`, world comes up; with `srcLoadCompileDebugWrites = true`, confirm multi-class
   drain lines.
4. The three lazy-part rigs (also the gauntlet `parts` leg):
   `cd ../Fizzygum-tests && node scripts/parts-lazy-load-headless.js && node scripts/parts-snapshot-load-headless.js && node scripts/parts-lazy-icons-headless.js`.
5. `fg lazyprobe` — laziness invariants unchanged.
6. `fg homepage` — builds the precompiled production tree, which EXERCISES the modified
   `?generatePreCompiled` pump at build time, then production smoke + snapshot round-trip.
7. Timing probe: recreate the boot-timing probe in `../Fizzygum-tests/.scratch/` (methodology in
   `docs/measurements/boot-timing-2026-07-31.md`; ad-hoc Node scripts must live there, not a session
   scratchpad — `require()` resolution): (a) dev world-ready vs the 3219 ms baseline; (b) on a
   homepage tree, click a lazy icon (e.g. a Maker app) and read the drain debug lines — assert >1
   class per frame and no drain-attributable frame beyond ~20 ms. Write the results as a dated
   `docs/measurements/` note.
8. Close with `fg gauntlet` in the background (`… > /tmp/fg-gauntlet-run.log 2>&1`, check
   `/tmp/fg-gauntlet.verdict`) — dpr2 + webkit legs re-prove determinism under load.
9. Owner gate: present summary + proposed commit message; ask before commit/push.

## §9 Rejected alternatives — do not re-attempt without new evidence

- **Size-based cherry-picking / dependency-safe look-ahead** (when the next class doesn't fit, scan
  ahead for a smaller one whose known deps are all defined): owner explicitly declined 2026-08-02.
  It would create compile orderings never exercised in any boot, guarded only by the
  known-approximate dependency map (arc 4: `extractDependenciesFromSource` cannot see method-body
  `new X`; its class-level-use regexes are pattern-based), for a payoff bounded by a few ms of
  leftover budget per frame.
- **Keeping the promise-chain shape and resolving N resolvers per frame**: structurally cannot
  measure per-item actuals (each item runs in a microtask after the drain returns), so N could only
  come from estimates never corrected by observation — the whole self-calibration story dies. The
  synchronous drain is the design.
- **A flat per-class time estimate**: measured 2× over-prediction on small classes
  (`docs/measurements/boot-timing-2026-07-31.md` — "compile cost tracks a source's SIZE").
  Per-line + EWMA instead.
- **Budgeting the batch FETCH pacing too**: out of scope — network-bound script-tag loads, one per
  turn is fine, and `waitNextTurn` keeps one honest consumer.

## §10 Comments & docs that assert the old rule (update in the SAME change)

- `src/boot/loading-and-compiling-coffeescript-sources.coffee:1-31` — header: `waitNextTurn` paces
  only batch fetches now; compiles go through `SourceCompileScheduler`.
- `src/WorldWdgt.coffee:1667-1673` — `progressFramePacedActions` comment ("one per frame so we
  don't cause gitter") → batch fetches only.
- `src/PartsRegistry.coffee:8-14` ("compiles a source per frame") → budgeted end-of-frame scheduler;
  `:21-25` — a part arriving mid-test is now budget-paced, i.e. wall-clock-dependent — the
  determinism rationale for `FIZZYGUM_EAGER_ALL_PARTS` STANDS, reword, don't delete; `:237`
  ("frame-paced like the boot ingest"); `:258-264` (`_ingestPartPromise` header — also flag the
  pre-existing ingest-vs-part ordering hazard, §6).
- `src/boot/globalFunctions.coffee:17-19` — `framePacedPromises` comment.
- `docs/explainers/boot-and-lazy-parts.html:274` — diagram box "one class per FRAME" → budgeted
  wording; `:282-285` — figcaption (resolver queue → synchronous budget drain after paint, at least
  one per frame); `:118` — reword "frame-paced".
- `docs/architecture/build-and-packaging.md` §5 — verified 2026-08-02: never asserts one-per-frame;
  NO change needed (re-verify at execution time).
- Post-landing: `/docs-sync` ritual + the dated measurements note from §8.7.

## §11 References

- `docs/architecture/build-and-packaging.md` — partition/profiles/runtime boot paths.
- `docs/explainers/boot-and-lazy-parts.html` — the boot + lazy-part timelines.
- `docs/measurements/boot-timing-2026-07-31.md` — the calibration data and the flat-estimate caveat.
- `../Fizzygum-tests/DETERMINISM.md` — why wall-clock-dependent behavior must stay outside the suite.
- Memory notes (session-local): `boot-cost-reduction-arc`, `core-app-slices-partition-arc`
  (`whenAllLoaded` fast path is CORRECTNESS), `build-arc-4-dynamic-parts-arc` (dep scanner blind
  spots).
