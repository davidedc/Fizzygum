# PartsRegistry -- loads a PART of the system into the running world, on demand.
#
# Reached as `world.parts`. A part is a named slice of the source (buildSystem/parts.json): its
# classes, and optionally a vendor payload they need. A part marked `eager` arrives during boot like
# everything else; a part marked `"eager": false` is not in the booted world at all until something
# asks for it, which is what this class is for.
#
# WHY THIS IS NOT AS BIG AS IT SOUNDS. The hard part of loading code into a live world -- fetching
# it over file:// with no fetch/XHR, then compiling it without stalling the frame loop -- already
# existed and runs on every production boot: `loadJSFilePromise` injects a <script> (fetch pacing:
# waitNextTurn, one batch per frame out of window.framePacedPromises), and
# window.SourceCompileScheduler compiles sources behind the running world at END of frame, fitting
# as many per frame as the leftover frame budget allows (at least one). This class is the
# bookkeeping around that: which sources belong to the part, in what order to compile them, and one
# promise per part so concurrent callers coalesce.
#
# ⚠ A PART IS CODE, NOT STATE. Parts load monotonically within a page session and are never
# unloaded: resetWorld resets STATE, and unloading CODE between tests would recompile ~10 classes
# per test for no isolation gain (all ~500 classes already stay resident across an entire shard).
# There is deliberately no `unload`.
#
# ⚠ THE TEST PROFILE EAGER-LOADS EVERYTHING. A part arriving mid-test would be ingested under a
# WALL-CLOCK frame budget -- how many classes land in which cycle depends on machine load -- which
# is exactly the nondeterminism class DETERMINISM.md is about (cycle counts diverge at dpr 2 under
# parallel load). The harness page and index-sw.html therefore set
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

  # Is this part in the page RIGHT NOW? _-tier: `whenAllLoaded` is the only caller, and it is the
  # method call sites are meant to reach for -- a door that asks this itself would be re-deriving
  # the fast-path rule that whenAllLoaded already encodes, and the call-separation gate [U] catches
  # exactly that (a public query nothing but @-self calls).
  #
  # ⚠ NOT the same question as the guard at an absent-part call site: this answers "is it here
  # yet?", which for a part this artifact never shipped is false forever. `isAvailable` is that one.
  # (The lazy-load RIG still asserts the observable fact -- whether the classes are defined in the
  # page -- rather than asking the registry for its own opinion of itself.)
  _isLoaded: (partName) ->
    @_state[partName] is @LOADED

  # Is this part in this artifact at all? A production build ships no fizzytiles, so asking for it
  # is not an error to throw at the user -- it is a feature that is not in this product.
  #
  # PUBLIC: the lazy doors ask it (Widget.spawnInspector, Widget.createConsole). A class-existence
  # test cannot answer this question for a LAZY part, which is why those doors ask a PART instead: an
  # undefined class means BOTH "this artifact does not ship it" and "nobody has fetched it yet", and
  # those two want opposite responses -- do nothing, versus go and get it. Only a part-level question
  # separates them. So a lazy door asks this first, and then awaits.
  isAvailable: (partName) ->
    @_state[partName]?

  # The part a class belongs to, or undefined for a core class (or a name we know nothing about).
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
    undefined

  # The parts this one's code names, from the build manifest (parts.json `requires`). They are
  # loaded FULLY FIRST -- see ensureLoaded.
  _requiredPartsOf: (partName) ->
    (window.FIZZYGUM_PARTS?[partName]?.requires) ? []

  # Load a part, and whatever it requires, if it is not already in. Returns a promise that resolves
  # when its classes are defined and usable. Concurrent callers get the SAME promise, so a
  # double-click cannot start two loads.
  #
  # ⚠⚠ THE REQUIRED PARTS RESOLVE BEFORE THIS PART'S OWN BATCHES ARE INGESTED, and the ordering is
  # the whole point rather than tidiness. Within one part `_ingestPartPromise` orders classes by
  # findLoadOrder, so `class X extends Y` is safe; ACROSS parts nothing ordered anything, because
  # the only cross-part idiom was a door naming several parts and `ensureAllLoaded` is a
  # `Promise.all` -- they arrive concurrently, and a base class that has not been defined yet is a
  # race, not an error you can catch. Sequencing here is what makes a lazy part able to extend
  # another lazy part's class at all. Each requirement's own promise chain handles ITS requirements,
  # and every one is memoized, so the transitive closure loads once and a diamond costs nothing.
  ensureLoaded: (partName) ->
    return Promise.resolve() if @_state[partName] is @LOADED
    return @_promises[partName] if @_state[partName] is @LOADING
    unless @isAvailable partName
      return Promise.reject new Error "Fizzygum: no such part '#{partName}' in this build."

    @_state[partName] = @LOADING
    required = @_requiredPartsOf partName
    withRequirements =
      if required.length
        @ensureAllLoaded(required).then => @_loadPartPromise partName
      else
        @_loadPartPromise partName
    @_promises[partName] = withRequirements.then =>
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

  # ⚠⚠ THE IDIOM for a call site that needs one or more LAZY parts. Run `thenDo` once they are all
  # in — and run it SYNCHRONOUSLY when they already are, which is the whole point and the reason this
  # exists as one method instead of a conditional copy-pasted into every door.
  #
  # Why the fast path is not an optimisation but a CORRECTNESS requirement: on every build the
  # SystemTest suite runs, the harness page presets FIZZYGUM_EAGER_ALL_PARTS, so every part is here
  # long before anything asks. Going through `.then` regardless would defer the effect by a
  # microtask, and a microtask moves it a whole world CYCLE later — which the suite measures, cycle
  # by cycle (../Fizzygum-tests/DETERMINISM.md). Half a dozen doors need exactly this shape; one rule
  # encoded in two places is how arc 4 produced four bugs of one shape, so it is encoded here, once.
  #
  # ⚠ Ask `isAvailable` FIRST at any door that a profile may not ship at all: this method assumes the
  # parts exist and will reject (via ensureLoaded) if they do not.
  whenAllLoaded: (partNames, thenDo) ->
    for eachName in partNames
      return @ensureAllLoaded(partNames).then thenDo unless @_isLoaded eachName
    thenDo()

  # THE SAME IDIOM FOR PARTS THAT MERELY ENRICH THE CALLER, rather than ones it cannot work without.
  # Loads the ones this artifact actually has and runs `thenDo` regardless — so on a profile that
  # ships none of them, this is simply `thenDo()`.
  #
  # ⚠ WHICH OF THE TWO A DOOR WANTS IS A REAL DECISION, not a style preference, and getting it wrong
  # is silent. `whenAllLoaded` REJECTS on a part this build never shipped, which is right when the
  # part is load-bearing: a Sample* document that BUILDS plots is broken without them, not reduced,
  # so it must fail loudly rather than open half-assembled. But a door whose window merely offers a
  # part's tools in a palette is fine without them — the toolbars already filter their own contents
  # by class existence — and there `whenAllLoaded` would turn a shipped desktop icon into one whose
  # click can only reject: no window, ever, and an unhandled rejection. That is the trap this method
  # exists to close, and it is only reachable when the DOOR always ships while its parts may not
  # (DashboardsApp and SimpleSlideApp are core, with unguarded openers, naming parts `lean` omits).
  # A door behind a guarded opener cannot hit it, because the opener is absent with the part.
  #
  # It is a method rather than a comprehension copied into each door for the reason the whole class
  # exists: one rule encoded in two places is how arc 4 produced four bugs of one shape.
  whenOptionalPartsLoaded: (partNames, thenDo) ->
    @whenAllLoaded (eachName for eachName in partNames when @isAvailable eachName), thenDo

  # ensureLoaded + construct. `new (window[className])` deliberately names the class as DATA:
  # buildSystem/check-part-edges.js cannot see through it, which is the point -- core is not
  # allowed to name a part's class as a symbol it needs already defined, and this is the sanctioned
  # way to construct one anyway.
  launch: (className) ->
    part = @_partOf className
    return Promise.resolve new (window[className]) unless part?
    @ensureLoaded(part).then -> new (window[className])

  # Can this artifact EVER produce this class -- is it already here, or does a part this build
  # ships own it? Asked by whoever is deciding whether to put a control on screen at all: an icon
  # whose class can never arrive is a button whose only possible outcome is a rejected load, which
  # is worse than no icon (the `lean` dead-icon bug). ⚠ This is the isAvailable question, keyed by
  # CLASS instead of by part -- not "is it here yet", which is whenClassAvailable's business.
  canEverProvideClass: (className) ->
    return true if window[className]?
    part = @_partOf className
    part? and @isAvailable part

  # Run `callback` with this class present, fetching whatever part owns it if need be. The caller
  # names a CLASS, never a part: which slice of the partition holds it is not its business, and
  # keying off the name is what lets a launcher be built at boot out of a string.
  # ⚠ INLINE when the class is already defined -- correctness, not economy. Deferring by a microtask
  # moves the effect a whole world CYCLE later and the SystemTest suite measures cycles
  # (../Fizzygum-tests/DETERMINISM.md), the same rule as whenAllLoaded's fast path.
  whenClassAvailable: (className, callback) ->
    return callback() if window[className]?
    part = @_partOf className
    # nothing owns it: a build that simply does not have this class. The caller decided whether to
    # offer the control at all (canEverProvideClass); reaching here means it is genuinely absent.
    return unless part?
    @whenAllLoaded [part], callback

  # Which not-yet-loaded parts a set of class names needs. Used by the snapshot loader: a saved
  # world can name classes this page has never loaded.
  partsNeededFor: (classNames) ->
    needed = []
    for eachName in classNames
      part = @_partOf eachName
      continue unless part?
      continue if @_state[part] is @LOADED
      continue unless @isAvailable part
      needed.push part unless part in needed
    needed

  # ---- the load itself -------------------------------------------------------------------------

  _loadPartPromise: (partName) ->
    spec = window.FIZZYGUM_PARTS[partName]
    # 0. THE META-SYSTEM. Ingesting this part's sources means `new Class` / `new Mixin`, and
    # ordering them means findLoadOrder -- and a PRECOMPILED tree has none of the three until
    # something asks: Class and Mixin are the only two classes absent from js/pre-compiled.js.
    # ⚠⚠ Do NOT "simplify" this to ensureReflectiveLayerLoaded(): that also fetches every EAGER
    # part's batches (2.29 MB on production), which is the entire saving this part being lazy
    # bought. ~39 KB versus 2.29 MB. A compile-at-boot tree has already loaded it, and the
    # promise is memoized, so there it costs nothing.
    chain = ensureMetaSystemLoaded()
    # 1. vendor payloads next: a part's classes may need them at first use.
    for eachVendorFile in (spec.vendor ? [])
      chain = chain.then @_createVendorLoadClosure eachVendorFile
    # 2. then its source batches, which are SourceVault.store calls.
    for eachBatch in spec.batches
      chain = chain.then -> waitNextTurn()
      chain = chain.then @_createBatchLoadClosure eachBatch
    # 3. then compile what just arrived, through the budgeted scheduler like the boot ingest.
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

  # Compile+run the part's sources, in dependency order, through the budgeted
  # end-of-frame scheduler -- as many per frame as the leftover frame budget
  # fits, at least one (window.SourceCompileScheduler, drained by doOneCycle
  # right after paint).
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
    window.SourceCompileScheduler.enqueueJob ordered, false
