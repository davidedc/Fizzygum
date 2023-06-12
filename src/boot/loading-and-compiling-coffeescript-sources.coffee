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


createClosureForLoadingCoffeescriptSourceBatch = (batchNumber) ->
  # this only creates the closure that will be run (later)
  # if srcLoadCompileDebugWrites then console.log "creating closure for batch #{batchNumber}"
  -> loadJSFilePromise "js/coffeescript-sources/sources_batch_" + batchNumber + ".js"

  
loadJSFilesWithCoffeescriptSourcesBatchesPromise = ->
  # "Head" of the promise. We'll chain to it the loading of all the
  # batches of sources.
  # This head "triggers" the chain immediately, however each next element
  # of the chain will wait for its turn.
  # I.e. all the batches are loaded one at a time to avoid requesting too many
  # concurrent file/network request. Not only that, but in fact they are loaded
  # in number sequence, which is not strictly needed because we detect the
  # dependencies later on anyways.
  promiseChain = Promise.resolve()

  # Note that the sources for "Class" and "Mixin" might end-up
  # being recompiled even though those are two of the few things that
  # we run from the start in the skeletal system.
  # It doesn't seem to cause problems though?
  if srcLoadCompileDebugWrites then console.log "number of source batches: #{numberOfSourceBatches}"
  for i in [0...numberOfSourceBatches]
    # give a change to the main thread to breathe
    promiseChain = promiseChain.then -> waitNextTurn()
    # if srcLoadCompileDebugWrites then console.log "building promise chain for batch #{i}"
    # This immediately creates the closure that will be run (later)
    # and chains it to the promise chain.
    # This is needed because it's the only ways to pass the
    # correct value of i in the loadJSFilePromise function, because otherwise the value of i
    # would be the one at the end of the loop, which is wrong.
    promiseChain = promiseChain.then createClosureForLoadingCoffeescriptSourceBatch i
  
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
  #console.log "compileFGCode time: " + (t1 - t0) + " milliseconds."

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

    if window.location.href.includes "generatePreCompiled"
      zip = new JSZip
      zip.file 'pre-compiled.js', "window.preCompiled = true;\n\n" + window.JSSourcesContainer.content
      zip.generateAsync(type: 'blob').then (content) ->
        saveAs content, 'pre-compiled.zip'
        return


    removeLogDiv()

  return promiseChain

storeSourceAndPotentiallyCompileItAndExecuteIt = (fileName, justIngestSources) ->

  if !window.JSSourcesContainer?
    window.JSSourcesContainer = {content: ""}

  fileContents = window[fileName + "_coffeSource"]

  if srcLoadCompileDebugWrites then t0 = performance.now()
  if srcLoadCompileDebugWrites then console.log "checking whether " + fileName + " is already in the system "

  # loading via Class means that we register all the source
  # code and manually create any extensions
  if /^class[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m.test fileContents
    if justIngestSources
      # registers the class, its superclasses, its augmentations and the
      # source code
      morphClass = new Class fileContents, false, false
    else
      morphClass = new Class fileContents, true, true
  # Loaded Mixins here:
  else if /^  onceAddedClassProperties:/m.test fileContents
    if justIngestSources
      new Mixin fileContents, false, false
    else
      new Mixin fileContents, true, true

  if srcLoadCompileDebugWrites then console.log "compiling and evalling " + fileName + " from source code"
  emptyLogDiv()
  addLineToLogDiv "compiling and evalling " + fileName

  if srcLoadCompileDebugWrites then t1 = performance.now()
  if srcLoadCompileDebugWrites then console.log "storeSourcesAndPotentiallyCompileThemAndExecuteThem call time: " + (t1 - t0) + " milliseconds."
