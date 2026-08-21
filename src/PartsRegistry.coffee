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
# unloaded: resetWorld replaces the WORLD — every bit of state, by reconstruction — while the
# classes that world is built out of are PAGE-lifetime, shared by every world the page ever has.
# Unloading CODE between tests would recompile ~10 classes per test for no isolation gain (all ~500
# classes already stay resident across an entire shard). There is deliberately no `unload`.
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

  # ⚠⚠ WHICH LAZY PARTS THIS PAGE HAS ALREADY INGESTED. A CLASS static, not a field of any one
  # registry, because "part X's classes are defined in this page" is a fact about the page's CODE
  # and code is not world state: a part loads monotonically and is never unloaded (see the header),
  # so the fact outlives every world that observed it -- including a world REPLACED by a fresh one.
  # `@_state` below is the per-world VIEW of the same truth, rebuilt from scratch by every
  # constructor; this is the truth itself, and a registry that could not consult it would re-fetch
  # and re-ingest a sources batch this page already has. (`_ingestPartPromise`'s
  # `when not window[name]?` filter keeps a re-ingest from redefining a live class, so forgetting
  # costs a fetch and a frame-paced compile pass rather than corruption -- but that is waste on the
  # one path whose entire reason to exist is being cheap.)
  #
  # ⚠ ONLY A COMPLETED INGEST BELONGS HERE. Eagerness is not recorded: `_isEagerHere` re-derives it
  # from the manifest and the entry page, and a fact stated twice will eventually disagree. Nor is a
  # STARTING load recorded: a part written down when its load begins reads LOADED forever after that
  # load fails, and a record that can be wrong is worse than one that is merely incomplete. So the
  # single write is in ensureLoaded's success continuation, and every path that concludes "this part
  # is now present" reaches it through there.
  @ingestedParts: new Set

  # ⚠⚠ THE LOADS CURRENTLY IN FLIGHT, part name -> promise. A CLASS static for the same reason
  # @ingestedParts above is one, and it closes that record's one hole: a completed ingest is a fact
  # about the page, but so is an ingest still ON ITS WAY, and resetWorld replaces the world
  # underneath it (WorldWdgt._dissolveWorldNoSettle). A successor's registry rebuilds @_state from
  # eagerness plus @ingestedParts, so a part fetched-but-not-yet-ingested at the moment of a reset
  # would read NOT_LOADED, and the next ask would start the SAME load a second time: two fetches of
  # one batch, and the same sources enqueued twice (SourceCompileScheduler.enqueueJob does not
  # dedupe, and `new Class src` on a live class redefines it under the widgets already built from
  # it). So a load in flight is ADOPTED, never restarted -- which also subsumes, at page level, the
  # coalescing @_promises does for concurrent callers inside one world.
  #
  # ⚠ An entry lives exactly as long as the load: it is deleted on success AND on failure, so a
  # part whose load failed is askable again rather than pinned to a promise that will never
  # resolve. (@ingestedParts, by contrast, is written on success only -- a load that failed must
  # not read as present.)
  @inFlightLoads: new Map

  constructor: ->
    # part name -> NOT_LOADED | LOADING | LOADED. Every part the build put in this artifact is
    # listed; the eager ones are already in, because boot loaded their batches before the world
    # existed (see loading-and-compiling-coffeescript-sources.coffee) -- and so is any part a
    # PREVIOUS world in this page already ingested, which is what @ingestedParts remembers on the
    # page's behalf. Two facts, one view: this map is derived, never a fresh start.
    @_state = {}
    @_promises = {}
    for own partName, spec of (window.FIZZYGUM_PARTS ? {})
      alreadyHere = @_isEagerHere(spec) or PartsRegistry.ingestedParts.has partName
      @_state[partName] = if alreadyHere then @LOADED else @NOT_LOADED

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
    # Adopt the page's in-flight load if there is one (see @inFlightLoads): the fetch-and-ingest
    # belongs to the page, so a world that arrived mid-load waits on the load already running
    # rather than starting a second one.
    inFlight = PartsRegistry.inFlightLoads.get partName
    unless inFlight?
      required = @_requiredPartsOf partName
      withRequirements =
        if required.length
          @ensureAllLoaded(required).then => @_loadPartPromise partName
        else
          @_loadPartPromise partName
      inFlight = withRequirements.then ->
        # ⚠ THE ONE PLACE A PART BECOMES PRESENT, so the one place the page-lifetime record is
        # written. `ensureAllLoaded`, `whenAllLoaded`, `whenOptionalPartsLoaded`, `launch`,
        # `whenClassAvailable` and the snapshot loader's pre-scan all reach a part through
        # `ensureLoaded`, and a required part is loaded by its own trip through it -- so one write
        # here covers every caller AND the transitive closure. A path that ever flips a part to
        # LOADED without coming through this continuation must record it here too, or a later world
        # in this page will re-fetch what the page already holds.
        PartsRegistry.ingestedParts.add partName
        PartsRegistry.inFlightLoads.delete partName
        return
      , (err) ->
        # a failed load must leave the part ASKABLE again rather than pinned to a promise that
        # will never resolve
        PartsRegistry.inFlightLoads.delete partName
        throw err
      PartsRegistry.inFlightLoads.set partName, inFlight
      # The page-level record is a RECORD, not a caller: every asker chains its own continuation
      # below and owns the rejection it gets. This no-op handler is what keeps a failed load from
      # ALSO surfacing as an unhandled rejection, which the headless runners fail a test on.
      inFlight.catch -> undefined
    @_promises[partName] = inFlight.then =>
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
  #
  # ⚠⚠ THE DOOR-CALLBACK LAW: a callback that acts ON A WIDGET must open with a
  # destroyed-check (`return if theWidget.destroyed`) — the wait is exactly when the subject
  # can die (the user closes the window while the part is in flight), and acting anyway
  # silently mutates a corpse: measured on index.html, editLayout + destroy-mid-load BUILT
  # fresh chrome on the destroyed widget — an escaped widget no destroy cascade can ever
  # reach, pinning its corpse parent, with no error anywhere
  # (docs/archive/world-vm-truth-riders-plan.md §5 S3; the runtime gate is the
  # destroy-mid-load race in ../Fizzygum-tests/scripts/parts-lazy-load-headless.js). The
  # guard lives at the CALLBACK head, not here: only the call site knows its subject (some
  # have two, spawnInspector's acts after a second await), and on the all-eager pages the
  # inline fast path makes the check dead weight this funnel would pay on every door.
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
  # (DashboardsApp and SimpleSlideApp ship inside the lazy `authoring` part — so wherever their
  # opener is drawn they are there — while the `maps`/`plots` tools their palettes offer are parts
  # a profile may leave out; hence `optionalParts` on both, `["maps", "plots"]` and `["maps"]`).
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
    # part's batches (core's numbered batches, ≈1.9 MB on production), which is the entire saving
    # this part being lazy bought. ~39 KB versus ≈1.9 MB. A compile-at-boot tree has already loaded it, and the
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
