# TWO pacing mechanisms live in this file:
#
#  1. waitNextTurn -- paces the FETCHING of the sources batches (script-tag
#     loads), one batch per turn, in two modalities:
#     a) in "pre-compiled" mode a world is already running, so each wait parks
#        its "resolve" in window.framePacedPromises and doOneCycle releases one
#        per frame (progressFramePacedActions) -- a batch fetch gets a whole
#        frame of network time without creating gitter as the world is going.
#     b) in non-precompiled mode there is no running world (we are loading the
#        sources we will build it from), so each wait is just a timer turn --
#        and there is no gitter to care about.
#
#  2. window.SourceCompileScheduler -- compiles/ingests the fetched sources
#     themselves, in dependency order, under a TIME BUDGET rather than
#     one-per-turn:
#     a) behind a running world, WorldWdgt.doOneCycle drains it at END of
#        frame (after paint), fitting as many classes as the leftover frame
#        budget allows -- and at least one per frame, always.
#     b) with no world, the scheduler pumps itself on setTimeout in small
#        (~10ms) chunks, yielding between chunks so the loading log div
#        repaints -- and so sibling pages on a loaded machine get scheduled.
#     Per-class cost is ESTIMATED from the source's line count (recorded for
#     free by extractDependenciesFromSource) times an observed ms/line that
#     self-calibrates from each compile actually measured.
waitNextTurn = ->
  if window.preCompiled
    return waitNextWorldCycle()
  else
    return waitNextJSEventLoopCycle()

waitNextWorldCycle = ->
  # this promise is stored in a queue, and each frame
  # one is popped out and resolved
  return new Promise (resolve, reject) ->
    # at the moment using an array is overkill because
    # we only use this when loading the coffeescript sources batches
    # and we only load one batch at a time
    window.framePacedPromises.push resolve

waitNextJSEventLoopCycle = ->
  return new Promise (resolve, reject) ->
    setTimeout () ->
      resolve arguments
    , 1


createClosureForLoadingCoffeescriptSourceBatch = (batchBaseName) ->
  # this only creates the closure that will be run (later)
  -> loadJSFilePromise "js/coffeescript-sources/" + batchBaseName + ".js"

# The batch files to load at boot: every eager part's, in a stable part order. A part that is NOT
# eager here is skipped and fetched on demand by PartsRegistry instead -- the point of the partition.
# `window.FIZZYGUM_PARTS` is the build-written manifest (delete_me/partsManifest.coffee, concatenated
# into this boot bundle, so it is already here).
#
# ⚠ VENDOR payloads are NOT loaded here, only sources. A part's vendor files are injected by
# PartsRegistry.ensureLoaded, which can be idempotent about them; this loader cannot, and blindly
# injecting fizzytiles' SWCanvas 3D-CORE payload on an SW page would overwrite that page's FULL
# SWCanvas engine -- its renderer -- with a subset. So an eager part with a vendor payload requires
# the payload to be in the boot bundle already, which is exactly the case for fizzytiles on the two
# pages that force it eager (they carry the full engine + SW3D).
eagerSourceBatchNames = ->
  names = []
  for partName in Object.keys(window.FIZZYGUM_PARTS).sort()
    eachPart = window.FIZZYGUM_PARTS[partName]
    continue unless window.fizzygumPartIsEagerHere eachPart
    names = names.concat eachPart.batches
  names

loadJSFilesWithCoffeescriptSourcesBatchesPromise = ->
  # "Head" of the promise. We'll chain to it the loading of all the
  # batches of sources.
  # This head "triggers" the chain immediately, however each next element
  # of the chain will wait for its turn.
  # I.e. all the batches are loaded one at a time to avoid requesting too many
  # concurrent file/network request. Not only that, but in fact they are loaded
  # in sequence, which is not strictly needed because we detect the
  # dependencies later on anyways.
  promiseChain = Promise.resolve()

  # "Class" and "Mixin" travel in their part's batch too (build.py piles every source into
  # its part's batch with no exceptions) even though both are already compiled by hand,
  # early, by loadMetaSystemPromise. Fetching that batch later just re-registers their text
  # in SourceVault -- storeSourcesAndPotentiallyCompileThemAndExecuteThem's "names" filter
  # excludes them from the actual compile step by name, so nothing ever recompiles them.
  batchNames = eagerSourceBatchNames()
  if srcLoadCompileDebugWrites then console.log "eager source batches: #{batchNames.length}"
  for eachBatchName in batchNames
    # give a chance to the main thread to breathe
    promiseChain = promiseChain.then -> waitNextTurn()
    # This immediately creates the closure that will be run (later) and chains it to the promise
    # chain. It has to be a closure over the name: without one, every step would see the loop
    # variable's FINAL value.
    promiseChain = promiseChain.then createClosureForLoadingCoffeescriptSourceBatch eachBatchName

  return promiseChain

compileFGCode = (codeSource, bare) ->
  try
    # Coffeescript v2 is used
    compiled = CoffeeScript.compile codeSource,{"bare":bare}
  catch err
    errorMessage =  "error in compiling:\n"
    errorMessage += codeSource + "\n"
    errorMessage += "error:\n"
    errorMessage += err + "\n"
    throw new Error errorMessage


  return compiled

# Compiles/ingests queued class sources under a TIME BUDGET -- the replacement for
# the old one-class-per-turn pacing (which was encoded twice, here and in
# PartsRegistry, and could never measure what a compile actually cost: each unit
# ran in a microtask the pacing never saw the end of). The drain is SYNCHRONOUS,
# so each item's actual cost is measured and feeds the estimator.
#
# A plain object, not a Class-system class, deliberately (the SourceVault
# pattern): it schedules the compiles that CREATE the class system, so on a
# compile-at-boot tree nothing of that system exists when it first runs.
# `window.`-qualified because a src class (PartsRegistry, WorldWdgt) cannot see a
# boot-file local.
window.SourceCompileScheduler =

  TARGET_FRAME_MS: 16.7      # rAF nominal at 60 Hz
  FRAME_HEADROOM_MS: 3       # compositor/rAF-dispatch slack
  NO_WORLD_CHUNK_MS: 10      # dev-boot pump chunk between yields. ⚠ Deliberately small:
                             # headless test runners boot SEVERAL of these pages while suite
                             # pages run beside them, and a page that holds its core in long
                             # uninterruptible blocks starves Chrome's protocol deadlines --
                             # 40ms chunks collapsed the whole parallel wave (measured
                             # 2026-08-04); ~10ms keeps the old per-class yield granularity
                             # while still batching ~10+ classes per turn
  EWMA_ALPHA: 0.2
  FALLBACK_LINE_COUNT: 150   # for a name extractDependenciesFromSource never saw
  MIN_ESTIMATE_MS: 0.5       # fixed per-class overhead floor: a flat per-class
                             # estimate over-predicts SMALL classes ~2x (measured,
                             # docs/measurements/boot-timing-2026-07-31.md), so we
                             # estimate per line -- but never below this floor

  _jobs: []                  # {names, nextIndex, justIngestSources, resolve, reject}
  _pumpScheduled: false
  # ms/line priors (compile-and-execute: 3116ms over ~52k lines, same doc; ingest-only
  # is far cheaper per line -- a guess the EWMA corrects from the first observation).
  # TWO slots because mixing the two modes in one average would corrupt both.
  _msPerLine: { compile: 0.06, ingest: 0.012 }
  _processedCount: 0
  _totalCount: 0
  _lastProcessedName: ""

  # One JOB per caller: an ordered list of source names, one completion promise.
  # Preserves the old per-caller promise-chain semantics exactly: in-order
  # execution, the first error rejects and drops THIS job's remainder (other
  # jobs unaffected), resolution in a microtask when the last name is done.
  enqueueJob: (names, justIngestSources) ->
    return Promise.resolve() if names.length is 0
    @_totalCount += names.length
    thePromise = new Promise (resolve, reject) =>
      @_jobs.push {names: names, nextIndex: 0, justIngestSources: justIngestSources, resolve: resolve, reject: reject}
    @_ensurePumpScheduled()
    thePromise

  # The end-of-frame drain station's entry point (WorldWdgt.doOneCycle, right
  # after paint): spend whatever the frame has left, but always make progress.
  drainAtEndOfCycle: (cycleStartPerfMs) ->
    return if @_jobs.length is 0        # dark-cheap, like the other cycle stations
    @_drain (@TARGET_FRAME_MS - @FRAME_HEADROOM_MS) - (performance.now() - cycleStartPerfMs)
    return

  _drain: (budgetMs) ->
    t0Drain = performance.now()
    itemsThisDrain = 0
    remainingMs = budgetMs
    loop
      job = @_nextJob()
      break unless job?
      name = job.names[job.nextIndex]
      # STRICT dependency order -- when the next-in-order class does not fit,
      # stop and resume next turn; never scan ahead for a smaller one (the
      # dependency map is approximate, findLoadOrder's sequence is the only
      # ordering ever exercised). And ALWAYS process at least one item, so an
      # over-budget frame degrades to the old one-per-frame, never to a stall.
      break if itemsThisDrain > 0 and (@_estimateMs name, job.justIngestSources) > remainingMs
      t0 = performance.now()
      try
        storeSourceAndPotentiallyCompileItAndExecuteIt name, job.justIngestSources
      catch err
        # must NOT propagate: a throw out of doOneCycle would unwind animloop.
        # console.error on purpose: every headless gate fails on it.
        console.error "SOURCE_COMPILE_FAILED: #{name}: " + (err?.stack ? err)
        @_removeJob job
        job.reject err
        itemsThisDrain++
        continue
      elapsed = performance.now() - t0
      @_observe name, job.justIngestSources, elapsed
      remainingMs -= elapsed
      itemsThisDrain++
      @_processedCount++
      @_lastProcessedName = name
      job.nextIndex++
      if job.nextIndex >= job.names.length
        @_removeJob job
        job.resolve()
    if srcLoadCompileDebugWrites and itemsThisDrain > 0
      console.log "compile drain: " + itemsThisDrain + " items in " + (performance.now() - t0Drain).toFixed(1) + " ms (budget " + budgetMs.toFixed(1) + ")"
    return

  # Two tiers: interactive compile-and-execute jobs (part loads, dev boot)
  # preempt background ingest-only jobs (the reflective-layer pass); FIFO
  # within a tier. ⚠ A part class needing a core class whose ingest-only
  # registration has not run yet was already possible under the old 1:1
  # interleave; the reordering does not worsen it.
  _nextJob: ->
    for eachJob in @_jobs
      return eachJob unless eachJob.justIngestSources
    @_jobs[0]

  _removeJob: (job) ->
    idx = @_jobs.indexOf job
    @_jobs.splice idx, 1 if idx >= 0
    return

  _modeKey: (justIngestSources) ->
    if justIngestSources then "ingest" else "compile"

  _lineCountOf: (name) ->
    window.sourceLineCounts?.get(name) ? @FALLBACK_LINE_COUNT

  _estimateMs: (name, justIngestSources) ->
    Math.max @MIN_ESTIMATE_MS, (@_lineCountOf name) * @_msPerLine[@_modeKey justIngestSources]

  _observe: (name, justIngestSources, elapsedMs) ->
    lines = @_lineCountOf name
    return if lines < 1
    key = @_modeKey justIngestSources
    @_msPerLine[key] = (1 - @EWMA_ALPHA) * @_msPerLine[key] + @EWMA_ALPHA * (elapsedMs / lines)
    return

  # ---- the no-world pump (compile-at-boot and ?generatePreCompiled boots) ----

  _ensurePumpScheduled: ->
    return if window.world?      # a stepping world's cycle drains us instead
    return if @_pumpScheduled
    @_pumpScheduled = true
    setTimeout (=> @_pumpTurn()), 0
    return

  _pumpTurn: ->
    @_pumpScheduled = false
    return if window.world? or @_jobs.length is 0
    @_drain @NO_WORLD_CHUNK_MS   # a chunk of compiles, then yield so the log div repaints
    @_updateBootLog()
    @_ensurePumpScheduled() if @_jobs.length > 0
    return

  # ONE DOM write per chunk (the old code wrote per class, but a synchronous
  # drain never paints intermediate states anyway). No-ops wherever the loading
  # log div does not exist -- every path but the compile-at-boot boot.
  _updateBootLog: ->
    return if @_lastProcessedName is ""
    emptyLogDiv()
    addLineToLogDiv "compiling and evalling " + @_lastProcessedName + " (" + @_processedCount + "/" + @_totalCount + ")"
    return

storeSourcesAndPotentiallyCompileThemAndExecuteThem = (justIngestSources) ->

  emptyLogDiv()

  if bootLoadingDebugWrites then console.log "------------ starting to read into the sources, ordering them and compiling them "
  loadOrder = findLoadOrder()


  # We remove these Coffeescript helper functions from
  # all compiled code, so make sure that they are available.
  # It's rather crude to add them to the global scope but
  # it works.
  window.hasProp = {}.hasOwnProperty
  window.indexOf = [].indexOf
  window.slice = [].slice

  # one job, in dependency order; the scheduler fits as many per turn as its
  # time budget allows. The returned promise resolves when everything is in
  # (or rejects on the first compile error), just like the old chain did.
  names = (eachFile for eachFile from loadOrder when eachFile not in ["Class", "Mixin", "globalFunctions"])
  window.SourceCompileScheduler.enqueueJob(names, justIngestSources).then ->
    removeLogDiv()

storeSourceAndPotentiallyCompileItAndExecuteIt = (fileName, justIngestSources) ->

  if !window.JSSourcesContainer?
    window.JSSourcesContainer = {content: ""}

  fileContents = SourceVault.get fileName

  if srcLoadCompileDebugWrites then t0 = performance.now()
  if srcLoadCompileDebugWrites then console.log "checking whether " + fileName + " is already in the system "

  # Only a ?generatePreCompiled boot wants Class/Mixin to ACCUMULATE the JS they compile
  # (window.JSSourcesContainer.content, which the external driver reads back out —
  # ../Fizzygum-tests/scripts/generate-pre-compiled-headless.js). An ordinary boot compiles
  # to CREATE the classes and never reads that string, so it must not build it.
  generatePreCompiledJS = window.location.href.includes "generatePreCompiled"

  # loading via Class means that we register all the source
  # code and manually create any extensions
  if /^class[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m.test fileContents
    if justIngestSources
      # registers the class, its superclasses, its augmentations and the
      # source code
      widgetClass = new Class fileContents, false, false
    else
      widgetClass = new Class fileContents, generatePreCompiledJS, true
  # Loaded Mixins here:
  else if /^  onceAddedClassProperties:/m.test fileContents
    if justIngestSources
      new Mixin fileContents, false, false
    else
      new Mixin fileContents, generatePreCompiledJS, true

  if srcLoadCompileDebugWrites then console.log "compiling and evalling " + fileName + " from source code"
  # (the loading log div is written by SourceCompileScheduler, once per drain
  # chunk -- not here, once per class)

  if srcLoadCompileDebugWrites then t1 = performance.now()
  if srcLoadCompileDebugWrites then console.log "storeSourcesAndPotentiallyCompileThemAndExecuteThem call time: " + (t1 - t0) + " milliseconds."
