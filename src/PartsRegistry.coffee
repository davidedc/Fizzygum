# PartsRegistry -- loads a PART of the system into the running world, on demand.
#
# Reached as `world.parts`. A part is a named slice of the source (buildSystem/parts.json): its
# classes, and optionally a vendor payload they need. A part marked `eager` arrives during boot like
# everything else; a part marked `"eager": false` is not in the booted world at all until something
# asks for it, which is what this class is for.
#
# WHY THIS IS NOT AS BIG AS IT SOUNDS. The hard part of loading code into a live world -- fetching
# it over file:// with no fetch/XHR, then compiling it without stalling the frame loop -- already
# existed and runs on every --homepage boot: `loadJSFilePromise` injects a <script>, and the
# frame-paced ingest chain (waitNextTurn -> storeSourceAndPotentiallyCompileItAndExecuteIt, drained
# one step per cycle out of window.framePacedPromises) compiles a source per frame behind a world
# that is already running. This class is the bookkeeping around that: which sources belong to the
# part, in what order to compile them, and one promise per part so concurrent callers coalesce.
#
# ⚠ A PART IS CODE, NOT STATE. Parts load monotonically within a page session and are never
# unloaded: resetWorld resets STATE, and unloading CODE between tests would recompile ~10 classes
# per test for no isolation gain (all ~500 classes already stay resident across an entire shard).
# There is deliberately no `unload`.
#
# ⚠ THE TEST PROFILE EAGER-LOADS EVERYTHING. A part arriving mid-test would be frame-paced, hence
# cycle-count-dependent, hence exactly the nondeterminism class DETERMINISM.md is about (cycle
# counts diverge at dpr 2 under parallel load). The harness page and index-sw.html therefore set
# window.FIZZYGUM_EAGER_ALL_PARTS, so the suite's world is what it always was. The lazy path gets
# its own test, which AWAITS the load.
class PartsRegistry

  NOT_LOADED: 0
  LOADING: 1
  LOADED: 2

  constructor: ->
    # part name -> NOT_LOADED | LOADING | LOADED. Every part the build put in this artifact is
    # listed; the eager ones are already in, because boot loaded their batches before the world
    # existed (see loading-and-compiling-coffeescript-sources.coffee).
    @_state = {}
    @_promises = {}
    for own partName, spec of (window.FIZZYGUM_PARTS ? {})
      @_state[partName] = if @_isEagerHere spec then @LOADED else @NOT_LOADED

  # ⚠ ONE definition of "is this part here at boot?", shared with the boot batch loader that
  # actually fetches them (window.fizzygumPartIsEagerHere, in
  # src/boot/loading-and-compiling-coffeescript-sources.coffee). This class must not have its own
  # copy: it briefly did, the boot loader's copy did not honour the entry-page override, and every
  # Fizzytiles SystemTest stalled on an undefined class while this registry cheerfully reported the
  # part LOADED. Two places encoding one rule IS the bug.
  _isEagerHere: (spec) ->
    window.fizzygumPartIsEagerHere spec

  # (No `isLoaded` predicate: nothing needs one. The lazy-load rig asserts the OBSERVABLE fact --
  # whether the part's classes are defined in the page -- which is a better test than asking the
  # registry for its own opinion of itself, and it keeps this class free of API written ahead of a
  # caller. Add one when a real consumer appears, e.g. a UI that wants to show a spinner.)

  # Is this part in this artifact at all? A --homepage build ships no fizzytiles, so asking for it
  # is not an error to throw at the user -- it is a feature that is not in this product.
  # _-tier: only this class asks. A public `isAvailable` would be API written ahead of a caller,
  # which the call-separation gate [U] correctly refuses.
  _isAvailable: (partName) ->
    @_state[partName]?

  # The part a class belongs to, or nil for a core class (or a name we know nothing about).
  # _-tier: only this class asks (launch + partsNeededFor).
  #
  # ⚠ This reads the BUILD MANIFEST's per-part `classes` list, NOT SourceVault.partOf, and the
  # difference is the whole point. The vault only knows about sources it has been GIVEN, i.e. whose
  # batch has already loaded -- so for a lazy part it cannot answer until after the load, which is
  # exactly the one moment anything needs to ask (a snapshot naming a class from an unloaded part).
  # Asking the vault made partsNeededFor return [] and the snapshot load throw "this file references
  # the class 'FridgeMagnetsWdgt', which does not exist in this build"; the rig
  # ../Fizzygum-tests/scripts/parts-snapshot-load-headless.js is what caught it. Manifest data is
  # present from boot, so it can answer before the load. Do not "simplify" this back to the vault.
  _partOf: (className) ->
    for own partName, spec of (window.FIZZYGUM_PARTS ? {})
      continue unless spec.classes?
      return partName if className in spec.classes
    nil

  # Load a part (and, when it grows one, whatever it requires) if it is not already in. Returns a
  # promise that resolves when its classes are defined and usable. Concurrent callers get the SAME
  # promise, so a double-click cannot start two loads.
  ensureLoaded: (partName) ->
    return Promise.resolve() if @_state[partName] is @LOADED
    return @_promises[partName] if @_state[partName] is @LOADING
    unless @_isAvailable partName
      return Promise.reject new Error "Fizzygum: no such part '#{partName}' in this build."

    @_state[partName] = @LOADING
    @_promises[partName] = @_loadPartPromise(partName).then =>
      @_state[partName] = @LOADED
      delete @_promises[partName]
      return
    , (err) =>
      # a failed load must leave the part ASKABLE again rather than stuck in LOADING forever
      @_state[partName] = @NOT_LOADED
      delete @_promises[partName]
      throw err
    @_promises[partName]

  # Load several parts and resolve when all are in.
  ensureAllLoaded: (partNames) ->
    Promise.all (@ensureLoaded eachName for eachName in partNames)

  # ensureLoaded + construct. `new (window[className])` deliberately names the class as DATA:
  # buildSystem/check-part-edges.js cannot see through it, which is the point -- core is not
  # allowed to name a part's class as a symbol it needs already defined, and this is the sanctioned
  # way to construct one anyway.
  launch: (className) ->
    part = @_partOf className
    return Promise.resolve new (window[className]) unless part?
    @ensureLoaded(part).then -> new (window[className])

  # Which not-yet-loaded parts a set of class names needs. Used by the snapshot loader: a saved
  # world can name classes this page has never loaded.
  partsNeededFor: (classNames) ->
    needed = []
    for eachName in classNames
      part = @_partOf eachName
      continue unless part?
      continue if @_state[part] is @LOADED
      continue unless @_isAvailable part
      needed.push part unless part in needed
    needed

  # ---- the load itself -------------------------------------------------------------------------

  _loadPartPromise: (partName) ->
    spec = window.FIZZYGUM_PARTS[partName]
    # 1. vendor payloads first: a part's classes may need them at first use.
    chain = Promise.resolve()
    for eachVendorFile in (spec.vendor ? [])
      chain = chain.then @_createVendorLoadClosure eachVendorFile
    # 2. then its source batches, which are SourceVault.store calls.
    for eachBatch in spec.batches
      chain = chain.then -> waitNextTurn()
      chain = chain.then @_createBatchLoadClosure eachBatch
    # 3. then compile what just arrived, frame-paced like the boot ingest.
    chain.then => @_ingestPartPromise partName

  # A closure per file: without one, every step would see the loop variable's final value.
  _createBatchLoadClosure: (batchBaseName) ->
    -> loadJSFilePromise "js/coffeescript-sources/" + batchBaseName + ".js"

  # Vendor injection is IDEMPOTENT. The SW pages carry the full SWCanvas engine in their boot
  # bundle already (it is their renderer), so re-injecting the 3D-core build over it would replace
  # a superset with a subset. Skip when the payload's marker global is already present.
  _createVendorLoadClosure: (vendorFile) ->
    =>
      return Promise.resolve() if @_vendorAlreadyPresent vendorFile
      loadJSFilePromise vendorFile

  _vendorAlreadyPresent: (vendorFile) ->
    # fizzytiles' payload is the SWCanvas 3D core + SW3D; the SW backend's bundle has both already.
    if vendorFile.indexOf("fizzytiles-3d") isnt -1
      return window.SW3D? and window.SWCanvas?.Core?.Triangle3DOps?
    false

  # Compile+run the part's sources, in dependency order, one per frame.
  #
  # ⚠ Two constraints the boot path does not have. (a) findLoadOrder() scans EVERY source the vault
  # holds and is meant to run once, before anything is defined; here most classes already exist, so
  # we take its order and keep only the names this part just added. (b) A name that is already
  # defined must NOT be re-ingested: `new Class src` would redefine a live class underneath running
  # instances.
  _ingestPartPromise: (partName) ->
    fresh = (name for name in SourceVault.namesForPart partName when not window[name]?)
    ordered = (name for name from findLoadOrder() when name in fresh)
    # anything the load order did not mention (it skips Class/Mixin) still needs ingesting
    ordered = ordered.concat (name for name in fresh when name not in ordered)

    chain = Promise.resolve()
    for eachName in ordered
      chain = chain.then -> waitNextTurn()
      chain = chain.then @_createIngestClosure eachName
    chain

  _createIngestClosure: (fileName) ->
    -> storeSourceAndPotentiallyCompileItAndExecuteIt fileName, false
