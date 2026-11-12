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

  # "Class" travels in its part's batch too (build.py piles every source into its part's
  # batch with no exceptions) even though it is already compiled by hand, early, by
  # loadMetaSystemPromise. Fetching that batch later just re-registers its text in
  # SourceVault -- storeSourcesAndPotentiallyCompileThemAndExecuteThem's "names" filter
  # excludes it from the actual compile step by name, so nothing ever recompiles it.
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

# opts.typedFrom: the index in codeSource where text a PERSON TYPED begins (default 0, the whole
# source) -- a save that compiles the typed text behind an assignment ("@name = " + text) passes the
# prefix's length. A compile error then carries its place in THAT text as `typedLocation` ({line,
# column}, 0-based like the compiler's own): the compiler counts from the start of codeSource, so
# behind a prefix its line-1 column is off by the prefix's length. A place inside the prefix itself
# gets no typedLocation, and neither does a failure the compiler gives no place for (this minimal
# compiler throws a plain TypeError on `import`/`export`). Every error thrown here is marked
# `isCompileError`: whatever the compiler threw -- or the engine, parsing what the compiler wrote --
# the text did not compile, which is what a gesture over typed code reports
# (Widget._informOfCompileErrorOrRethrow), apart from code that compiled and then threw.
# opts.fromTheBuild: the source is the build's own (a class's, the meta-system's), which
# skips the engine's parse below -- see there.
compileFGCode = (codeSource, bare, opts = {}) ->
  try
    # Coffeescript v2 is used
    compiled = CoffeeScript.compile codeSource,{"bare":bare}
  catch err
    errorMessage =  "error in compiling:\n"
    errorMessage += codeSource + "\n"
    errorMessage += "error:\n"
    errorMessage += err + "\n"
    # the compiler's own SyntaxError rides along as the cause: its `location` says where the text
    # stops being CoffeeScript, which a gesture reporting to a person reads
    # (Widget._reportingCompileErrors / _savingTypedCode)
    error = new Error errorMessage, cause: err
    error.isCompileError = true
    if err?.location?
      linesBefore = codeSource.slice(0, opts.typedFrom ? 0).split "\n"
      typedLine = err.location.first_line - (linesBefore.length - 1)
      typedColumn = err.location.first_column
      typedColumn -= linesBefore[linesBefore.length - 1].length  if typedLine is 0
      if typedLine >= 0 and typedColumn >= 0
        error.typedLocation = line: typedLine, column: typedColumn
    throw error

  # ...and the ENGINE must be able to parse what it compiled: CoffeeScript passes through text the engine
  # refuses (a top-level `return`, a regex it cannot read, a strict-mode error under a 'use strict' the
  # text opens with), whose SyntaxError would reach a gesture unmarked and take the crash path. The
  # engine's refusal is a compile error like any above, with no typed location (the engine names no place
  # in the CoffeeScript). Not for the build's own sources: its syntax gate compiled them, one the engine
  # refused fails loudly at its own eval, and parsing them again would only lengthen every boot and every
  # lazy part's arrival.
  unless opts.fromTheBuild
    refusal = engineRefusalOf compiled
    if refusal?
      error = new Error "error in compiling:\n" + codeSource + "\nerror:\n" + textOfThrownValue(refusal) + "\n", cause: refusal
      error.isCompileError = true
      throw error

  compiled

# What the engine says when it parses `javaScript` -- its SyntaxError -- or undefined when it parses. Read
# two ways, neither of which can run anything: as a FUNCTION BODY (`new Function`, which honours the text's
# own directive prologue, so a text opening with 'use strict' is read strict), and as EVAL CODE in a
# function (a direct eval whose first statement throws, which refuses what only a function body takes: a
# top-level `return`). A run reads a text as one of the two (Widget.evaluateString evals it in a function;
# a sheet's formula is a function) or as global code (a class's member edit), and a text either reading
# refuses is one a run would refuse -- back-ticked JavaScript the person wrote aside (`new.target` reads
# differently in global code). The function body is read FIRST: the eval hoists what the text declares
# into this function, so after it nothing is read but `thrown`, which its catch assigns once the eval has
# thrown; the eval's own throw is a primitive compared by value, so nothing the text declares and nothing
# on the page's prototypes can pass for it.
engineRefusalOf = (javaScript) ->
  try
    new Function javaScript
  catch thrown
    return thrown
  try
    eval "throw 'it parses';\n" + javaScript
  catch thrown
    return thrown unless thrown is "it parses"
  undefined

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


  # THE THREE COFFEESCRIPT HELPER GLOBALS — the ONE shared definition every compiled member body
  # resolves against, and page-lifetime by design.
  # CoffeeScript emits `hasProp`/`indexOf`/`slice` as a `var` block at the head of whatever it
  # compiles (`for own` wants hasProp, `x in list` wants indexOf, `[a, b..., c] = arr` wants slice),
  # and the meta-compiler STRIPS that block out of every fragment while keeping the USES in the body
  # (src/meta/Class.coffee _removeHelperFunctions). So a compiled member reaches all three as FREE
  # identifiers, resolved in the global scope its fragment is eval'd into (`eval.call window, …`) —
  # which is what these three assignments are here to be. They cannot be taken back down afterwards
  # either: the world compiles members long after boot (live class editing, a lazily arriving part).
  # ⚠ ALL THREE, including one no current source happens to need: the strip is helper-AGNOSTIC — it
  # removes the whole `var` block whatever that block declared — so dropping a global arms a
  # ReferenceError for the first member written in the shape that wants it.
  # ⚠ And ONLY these three exist. Any other name the compiler declares in that block is stripped
  # just the same and then missing — `%%` compiles to a `modulo` helper nobody defines, and a
  # parameter default like `(c = @color ? @fallback()) ->` hoists a `ref` temporary there — so the
  # build's syntax gate (buildSystem/check-coffee-syntax.js) compiles every class member the way
  # boot does and FAILS one whose stripped block declares anything else. It reads this set from
  # Class._memberNamesThatMustStayAnonymous and holds it against the three assignments below: to
  # provide a fourth helper, assign it here AND add it to that list, or the gate stops.
  # (`extend`, the fourth helper name emitted class code calls, is not one of these — globalFunctions
  # defines it as a real function.)
  # ⚠ THIS IS THE COMPILE-AT-BOOT PATH. A precompiled artifact runs js/pre-compiled.js — the same
  # stripped bodies — before it reaches here, and on a `sources: "lazy"` profile may never reach here
  # at all; there the free `hasProp`/`indexOf` land on the boot bundle's own top-level `var` block
  # (the boot sources use `for own` and `in` too), which is a property of that code, not a guarantee.
  window.hasProp = {}.hasOwnProperty
  window.indexOf = [].indexOf
  window.slice = [].slice

  # one job, in dependency order; the scheduler fits as many per turn as its
  # time budget allows. The returned promise resolves when everything is in
  # (or rejects on the first compile error), just like the old chain did.
  # the meta-system's own source was compiled by hand before any batch (META_SYSTEM_SOURCES), and a
  # name with no source in the vault -- globalFunctions, the boot code every source depends on -- has
  # nothing to compile
  names = (eachFile for eachFile from loadOrder when eachFile not in META_SYSTEM_SOURCES and SourceVault.get(eachFile)?)
  window.SourceCompileScheduler.enqueueJob(names, justIngestSources).then ->
    removeLogDiv()

storeSourceAndPotentiallyCompileItAndExecuteIt = (fileName, justIngestSources) ->

  if !window.JSSourcesContainer?
    window.JSSourcesContainer = {content: ""}

  fileContents = SourceVault.get fileName

  if srcLoadCompileDebugWrites then t0 = performance.now()
  if srcLoadCompileDebugWrites then console.log "checking whether " + fileName + " is already in the system "

  # Only a ?generatePreCompiled boot wants Class to ACCUMULATE the JS it compiles
  # (window.JSSourcesContainer.content, which the external driver reads back out —
  # ../Fizzygum-tests/scripts/generate-pre-compiled-headless.js). An ordinary boot compiles
  # to CREATE the classes and never reads that string, so it must not build it.
  generatePreCompiledJS = window.location.href.includes "generatePreCompiled"

  # loading via Class means that we register all the source
  # code and manually create any extensions
  if /^class[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m.test fileContents
    if justIngestSources
      # gives the class its metaobject: its source, its members' sources and the name of
      # the class it extends
      widgetClass = new Class fileContents, false, false
    else
      widgetClass = new Class fileContents, generatePreCompiledJS, true

  if srcLoadCompileDebugWrites then console.log "compiling and evalling " + fileName + " from source code"
  # (the loading log div is written by SourceCompileScheduler, once per drain
  # chunk -- not here, once per class)

  if srcLoadCompileDebugWrites then t1 = performance.now()
  if srcLoadCompileDebugWrites then console.log "storeSourcesAndPotentiallyCompileThemAndExecuteThem call time: " + (t1 - t0) + " milliseconds."
