# Useful function to pace "then" steps,
# used in two occasions:
#    1. when loading the coffeescript sources batches
#    2. when storing/compiling the coffeescript sources
#
# Also, we use it in two modalities:
#    1. in "pre-compiled" mode we load all the
#       sources and we pace those loads triggering
#       the "waits" on animationFrames, so that
#       we don't create too much gitter as the
#       world is going.
#       We achieve this by storing the "resolve"
#       method in an array that we check in
#       doOneCycle. So when there is a frame running
#       we see if we can resolve one such "gate" so
#       that the next source can be loaded.
#       Note that for now the array of promises
#       can only have one element max, because we
#       load the sources batches one at a time.
#       So, an array is overkill at this time.
#
#    2. In non-precompiled mode
#       a) we don't have a running world
#          so there is no concept of doing things "on next frame"
#          (because we still have to build it from the
#          sources we are loading now),
#          so we can just wait each compilation step on
#          a timer.
#       b) we don't care about the gitter again because
#          there is no running world
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

  # Note that the sources for "Class" and "Mixin" might end-up
  # being recompiled even though those are two of the few things that
  # we run from the start in the skeletal system.
  # It doesn't seem to cause problems though?
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
  #t0 = performance.now()
  try
    # Coffeescript v2 is used
    compiled = CoffeeScript.compile codeSource,{"bare":bare}
  catch err
    errorMessage =  "error in compiling:\n"
    errorMessage += codeSource + "\n"
    errorMessage += "error:\n"
    errorMessage += err + "\n"
    throw new Error errorMessage

  #t1 = performance.now()

  return compiled

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

  # closure: a function where the arguments are bound.
  # This is because you want to freeze the arguments now at
  # function creation time, because when the closure be called, you want
  # the value of the two arguments to be the ones at closure creation time
  # (rather than at closure invocation)
  createStoreSourceAndPotentiallyCompileItAndExecuteItClosure = (fileName, justIngestSources) ->
    # this is the closure being created and returned
    # when the closure will be run (later), fileName and justIngestSources
    # will be have the values of now when we are creating it
    -> storeSourceAndPotentiallyCompileItAndExecuteIt fileName, justIngestSources


  # start of the promise. It will "trigger" the chain
  # immediately, however the first step is to wait for
  # a turn, so we are not really immediately starting
  # to compile.
  promiseChain = Promise.resolve()

  # chain two steps for each file, one to compile the file
  # and one to wait for the next turn
  for eachFile from loadOrder
    if eachFile == "Class" or eachFile == "Mixin" or eachFile == "globalFunctions"
      continue
    promiseChain = promiseChain.then -> waitNextTurn()
    promiseChain = promiseChain.then \
      createStoreSourceAndPotentiallyCompileItAndExecuteItClosure eachFile, justIngestSources

  # final step, proceed with the boot sequence
  promiseChain.then ->
    removeLogDiv()

  return promiseChain

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
  emptyLogDiv()
  addLineToLogDiv "compiling and evalling " + fileName

  if srcLoadCompileDebugWrites then t1 = performance.now()
  if srcLoadCompileDebugWrites then console.log "storeSourcesAndPotentiallyCompileThemAndExecuteThem call time: " + (t1 - t0) + " milliseconds."
