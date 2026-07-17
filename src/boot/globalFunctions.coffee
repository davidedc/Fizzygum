# we use "nil" everywhere instead of "null"
# and this "nil" we use is really "undefined"
# The reason is the following: Coffeescript v2 has the
# same "default values" policy as ES2015 i.e.
# "null" values DON'T get defaults anymore.
# Since we used that a lot, we devise the trick that
# we replace "null" with "nil" everywhere and we get the
# same behaviour as before (because existential operators
# such as "?" work the same on "undefined" and "null").
# The only thing we have to do is to never use "undefined"
# and "null" explicitly.
nil = undefined

# globals -------------------------------------------------
world = nil

# At the moment using an array is overkill because
# we only use this when loading the coffeescript sources batches
# and we only load one batch at a time
framePacedPromises = []

srcLoadCompileDebugWrites = false
bootLoadingDebugWrites = false

stillLoadingSources = nil


# This is used for mixins: MixedClassKeywords is used
# to protect some methods so the are not copied to object,
# because they have special meaning
# (this comment from a stackOverflow answer from clyde
# here: http://stackoverflow.com/a/8728164/1318347 )
MixedClassKeywords = ['onceAddedClassProperties', 'included']

noOperation = ->
    nil

# -------------------------------------------

# Shared identity-bookkeeping for the deepCopy graph copier (DeepCopierMixin).
# Every *-extensions.coffee ::deepCopy that patches a native prototype
# (Array / CanvasGradient / Date / HTMLCanvasElement / HTMLVideoElement /
# Image / Map / Set) shared the same "seen-before -> return the existing clone;
# else register the original, build the clone, register it, return it" preamble
# (this is the old `# TODO id: DUPLICATED_CODE_IN_DEEPCOPY`). Factored here as a
# template-with-callback rather than a pull-up because those patches sit on
# distinct native prototypes with no shared base.
#   buildEmpty()    -> makes the clone: a fully-built value for leaf types, or an
#                      EMPTY container for Array/Map/Set.
#   populate(clone) -> optional; fills a container AFTER it is registered in
#                      objectClones, so a cyclic reference back to the original
#                      resolves to the (partially-built) clone. Leaf types (whose
#                      whole clone is built by buildEmpty) pass no populate, so
#                      the op order stays byte-identical to the old inline code.
# Both callbacks are fat-arrows at the call site so `@` stays the original being
# copied; `allWidgetsInStructure` is threaded by the populate closure, not here.
deepCopyWithIdentity = (original, objOriginalsClonedAlready, objectClones, buildEmpty, populate) ->
  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf original
  if haveIBeenCopiedAlready >= 0
    return objectClones[haveIBeenCopiedAlready]

  objOriginalsClonedAlready.push original
  cloneOfMe = buildEmpty()
  objectClones.push cloneOfMe
  populate? cloneOfMe

  return cloneOfMe

# -------------------------------------------

# Helper function to use Promise style
# instead of callback style when loading a JS
loadJSFilePromise = (fileName) ->
  return new Promise (resolve, reject) ->
    # try to load the file 3 times, then give up and reject the promise
    # load by creating a script tag and appending it to the head
    numberOfAttemptsRemaining = 3
    tryToLoadFile = ->
      numberOfAttemptsRemaining--
      if numberOfAttemptsRemaining < 0
        if bootLoadingDebugWrites then console.log "Could not load file #{fileName}, bailing out"
        reject "Could not load file #{fileName}, bailing out"
      else
        script = document.createElement 'script'
        script.src = fileName
        script.async = true # should be the default
        script.type = "text/javascript"
        script.onload = ->
          if bootLoadingDebugWrites then console.log "loaded file #{fileName}"
          resolve script
        script.onerror = ->
          if bootLoadingDebugWrites then console.log "Could not load file #{fileName}, retrying"
          tryToLoadFile()
        document.head.appendChild script
    tryToLoadFile()


# there are two main ways of booting the world:
# 1. without pre-compiled files. In this case the
#    boot needs to load all the sources, compile
#    them and build all the classes and mixins.
#    The classes need to be appropriately chained
#    into a class hierarchy and they need to be
#    augmented with the desired mixins.
#    Only after all that the world will be able to
#    start.
# 2. with pre-compiled files. In this case there
#    is a JS file that contains all the compiled
#    JS versions of all the classes and mixins, plus
#    all the code to build the class hierarchy and
#    to augment the classes with the correct mixins.
#    So, no compilation of sources is needed for the
#    world to start, so this is much faster. After start,
#    the world will still asynchronously load all the
#    sources so one can view/edit the original
#    coffeescript sources.
boot = ->

  stillLoadingSources = true

  # Four related scaling questions: 1) physical size of a painted pixel (e.g. how
  # big a button needs to be for tapping) 2) the browser's current zoom level
  # 3) how to keep the canvas crisp, not blurry 4) how to size the UI big enough
  # for readability/touch. Answers below.

  # 1) Physical pixel size is NOT knowable via CSS/JS -- different screens (even
  # same-model iPads) report the same devicePixelRatio at different physical
  # densities. The only fallback is an interactive finger-spacing-style prompt.

  # 2) The browser's zoom level can't be read independently either --
  # devicePixelRatio conflates screen pixel density AND page zoom.

  # 3) A non-integer pixel ratio breaks pixel-accurate clipping/pointer-testing:
  # a logical N-unit widget would land on a fractional physical-pixel boundary
  # (e.g. 9 units -> 9.9px), making adjacent widgets bleed together or gaps
  # appear unpredictably; rounding/ceiling individual draws doesn't fix this
  # because the logical<->physical mismatch is systemic, not per-widget.
  # WHAT WE DO: ceil() devicePixelRatio (ceilPixelRatio, below) and paint at
  # that integer ratio -- more physical pixels than strictly needed, but crisp.

  # 4) Keep drawing crisp (answer 3) AND pick logical sizes (button/line
  # thickness) generous enough for touch/readability -- unmeasurable directly,
  # so this needs an interactive size-probe (see answer 1), not a formula.

  # --- SWCanvas software-rendering backend selection (optional) -------------
  #   ?sw=1   (or a preset window.FIZZYGUM_USE_SWCANVAS) routes every canvas made
  #           via HTMLCanvasElement.createOfPhysicalDimensions through SWCanvas
  #           instead of the DOM. When off, behaviour is identical to before.
  #   ?dpr=N  (or window.FIZZYGUM_FORCE_PIXEL_RATIO) forces ceilPixelRatio, so a
  #           HiDPI (e.g. retina, dpr 2) run can be exercised on a standard screen.
  #           This is exact for the SWCanvas backend (display-independent).
  bootQueryParams = nil
  try
    bootQueryParams = new URLSearchParams window.location.search
  catch err
    bootQueryParams = nil

  unless window.FIZZYGUM_USE_SWCANVAS?
    window.FIZZYGUM_USE_SWCANVAS = bootQueryParams? and (bootQueryParams.get("sw") is "1")

  forcedPixelRatio = nil
  if window.FIZZYGUM_FORCE_PIXEL_RATIO? and window.FIZZYGUM_FORCE_PIXEL_RATIO > 0
    forcedPixelRatio = window.FIZZYGUM_FORCE_PIXEL_RATIO
  else if bootQueryParams? and bootQueryParams.get("dpr")?
    parsedDpr = parseInt bootQueryParams.get("dpr"), 10
    if parsedDpr > 0 then forcedPixelRatio = parsedDpr

  window.ceilPixelRatio = if forcedPixelRatio? then forcedPixelRatio else Math.ceil window.devicePixelRatio

  # ?speed=normal|fast|fastest — the global macro PLAYBACK SPEED level, parsed here
  # as a plain query param alongside ?sw / ?dpr (NOT via ?startupActions). The macro
  # event generators (MacroToolkit) honour it: a higher level compresses gesture
  # time-spans (→ faster wall-clock) and thins event counts where path-safe. Browser
  # default is "normal" (a watchable run); the headless runner requests "fastest".
  # We only stash the raw string here — MacroToolkit validates it (the class isn't
  # loaded yet) and defaults to "normal" for an absent/invalid value.
  if bootQueryParams? and bootQueryParams.get("speed")?
    window.FIZZYGUM_MACRO_SPEED = bootQueryParams.get("speed")

  # ?intro=0|off — suppress the per-test faded TITLE/DESCRIPTION slide the test
  # player shows BEFORE each SystemTest (AutomatorPlayer.setUpIntroSlide). That
  # slide is purely for a HUMAN watching a run; it costs a fixed ~2.5s of real
  # wall-clock per test (a 2s dwell + a 0.5s fade), unaffected by ?speed=, so for
  # a headless/CI sweep it is ~half the total runtime and pure waste. It is
  # orthogonal to ?speed (speed compresses the gestures; this drops the preamble),
  # touches only DOM (not the world cycle, the command sequence, or the screenshot
  # pixels), so skipping it leaves every test's result byte-identical. Browser
  # default is SHOWN (watchable); the headless runners pass ?intro=0. Absent ⇒ true.
  window.FIZZYGUM_SHOW_TEST_INTRO = true
  if bootQueryParams? and bootQueryParams.get("intro")?
    introParam = bootQueryParams.get("intro")
    if introParam == "0" or introParam == "off" or introParam == "false"
      window.FIZZYGUM_SHOW_TEST_INTRO = false

  # SWCanvas's contexts/elements/gradients are not the native ones, so install
  # Fizzygum's prototype extensions onto them (see SWCanvasElement-extensions).
  if window.FIZZYGUM_USE_SWCANVAS and window.SWCanvas?
    installSWCanvasExtensions()

  # First loaded batch: assumed independently loadable/runnable in any order
  # (only fizzygum-boot.js -- this file -- is already loaded). None of these
  # entries may depend on another entry's code at CLASS-DEFINITION time: static/
  # non-static property initialisers run immediately when the class is defined,
  # so e.g. myCompiledCode: Coffeescript.compile(...) would need CoffeeScript
  # already loaded. Pre-compiled CLASSES, by contrast, load in dependency order,
  # so they CAN initialise properties from other classes (e.g. myCol: Color.create(...)).
  # A single bundled JS file was considered and rejected: pre-createWorldAndStartStepping
  # loading is already just the pre-compiled code + test manifests, everything else
  # loads in the background, so bundling wouldn't clearly help.

  # The case that we want to optimise is the pre-compiled case:
  # the pre-compiled pack should ideally only contain everything
  # that is needed to boot the world.
  bootLoadPromises = [
    loadJSFilePromise "js/pre-compiled.js",
    # coffeescript could nominally be loaded later
    # if it wasn't for the fact that the paint tool needs it
    # (see comment later to see where you can load it)
    loadJSFilePromise "js/libs/coffee-script_2.0.3.js"
  ]

  if BUILDFLAG_LOAD_TESTS or (window.location.href.includes "generatePreCompiled")
    bootLoadPromises.push loadJSFilePromise "js/libs/FileSaver.min.js"
    bootLoadPromises.push loadJSFilePromise "js/libs/jszip.min.js"
    bootLoadPromises.push loadJSFilePromise "js/tests/testsManifest.js"
    bootLoadPromises.push loadJSFilePromise "js/tests/testsAssetsManifest.js"

  # end of first batch
  # -----------------------------------------------------------

  Promise.all bootLoadPromises
  .then ->
    if bootLoadingDebugWrites then console.log "---- FileSaver, jszip, testsManifest, testsAssetsManifest, pre-compiled, coffeescript loaded"
    # this is the code path that we want to load/start fast.
    # All other situations (non-precompiled, or loading tests)
    # are not as important, they can take a few second more, we don't
    # care that much.
    if window.preCompiled
      createWorldAndStartStepping()
  .then ->
    Promise.all [
      # coffeescript could nominally be loaded here
      # if it wasn't for the fact that the paint tool needs it
      loadJSFilePromise("js/coffeescript-sources/Class_coffeSource.js"),
      loadJSFilePromise("js/coffeescript-sources/Mixin_coffeSource.js"),
      loadJSFilePromise("js/src/loading-and-compiling-coffeescript-sources-min.js"),
      loadJSFilePromise("js/src/logging-div-min.js")
    ]
  .then ->
    if bootLoadingDebugWrites then console.log "---- Class_coffeSource, Mixin_coffeSource, loading-and-compiling-coffeescript-sources-min, logging-div-min loaded"
    eval.call window, compileFGCode window["Mixin_coffeSource"], true
    eval.call window, compileFGCode window["Class_coffeSource"], true
  .then ->
    if bootLoadingDebugWrites then console.log "---- compiled Mixin_coffeSource, Class_coffeSource"
    loadJSFilePromise("js/src/dependencies-finding-min.js")
  .then ->
    if bootLoadingDebugWrites then console.log "---- dependencies-finding-min loaded"
    loadJSFilesWithCoffeescriptSourcesBatchesPromise()
  .then ->
    if bootLoadingDebugWrites then console.log "---- loaded all batches of coffeescript sources"
    if window.preCompiled
      # the world has already started stepping.
      # No need to compile the sources as we already got the pre-compiled code
      # (and it's already running).
      (storeSourcesAndPotentiallyCompileThemAndExecuteThem true).then ->
        stillLoadingSources = false
        if Automator?
          Automator.testsManifest = testsManifest
          Automator.testsAssetsManifest = testsAssetsManifest
        # world.getParameterPassedInURL is not included in the homepage build
        if startupActions = world.getParameterPassedInURL? "startupActions"
          world.nextStartupAction()
    else
      addLogDiv()
      # there is no world to speak of yet, and no stepping: in this case
      # we also compile all the sources to have something to build the world with!
      (storeSourcesAndPotentiallyCompileThemAndExecuteThem false).then ->
        stillLoadingSources = false
        if Automator?
          Automator.testsManifest = testsManifest
          Automator.testsAssetsManifest = testsAssetsManifest
      .then ->
        # returns a promise (world creation is deferred under the SWCanvas
        # backend), so chain the world-dependent code after it resolves.
        createWorldAndStartStepping()
      .then ->
        # world.getParameterPassedInURL is not included in the homepage build
        if startupActions = world.getParameterPassedInURL? "startupActions"
          world.nextStartupAction()


# Load the SWCanvas bitmap-font metrics + the positioning bundle for the active
# density BEFORE the world is built. measureText (which drives ALL text layout)
# returns null until the metrics bundle is loaded, so the world can't even boot
# under the SWCanvas backend without this. Glyph atlases are loaded lazily later
# (text shows placeholder boxes until then). Over file:// these load via
# BitmapText's <script> injection.
bootstrapSWCanvasFontsThen = (callback) ->
  # Run the world-start callback exactly once, whether the fonts loaded or not.
  callbackFired = false
  finish = ->
    return if callbackFired
    callbackFired = true
    callback()
  try
    raw = window.SWCanvas.fonts._raw
    bitmapText = raw.BitmapText
    bitmapText.setFontDirectory "font-assets/"
    # SWCanvas is a software renderer, so atlases must be stored as ImageData
    # (raw pixels it can composite), NOT as HTMLImageElements. Over file:// the
    # loader decodes each wrapped-webp <img> to ImageData via a same-origin
    # data: URL (so getImageData is untainted).
    bitmapText.setAtlasFormat? "imageData"
    Promise.all([
      bitmapText.ensureMetricsBundleLoaded()
      bitmapText.ensurePositioningBundleLoaded ceilPixelRatio
    ]).then finish, (err) ->
      # onRejected — do NOT also run finish() on a callback throw (that would
      # double-fire). A genuine load failure still boots the world (text broken).
      console.error "Fizzygum: SWCanvas font bootstrap failed (text may be broken):", err
      finish()
  catch err
    console.error "Fizzygum: SWCanvas font bootstrap threw (text may be broken):", err
    finish()

createWorldAndStartStepping = ->

  # ALL world-dependent setup lives here, because under the SWCanvas backend the
  # world is created asynchronously (after the font metrics load) — so nothing
  # that touches `world` may run before this.
  startWorld = ->
    # "false" as second parameter below
    #   fits the world in canvas as per dimensions
    #   specified in the canvas element.
    #   I.e. the user is here to record a system test so
    #   don't fill entire page cause there are some
    #   controls on the right side of the canvas.
    # "true" will make the world fill the entire page.
    # Also note that the first thing that this constructor does
    # is to initialise the global "world" variable with... the world.
    new WorldWdgt worldCanvas, !(window.location.href.includes "worldWithSystemTestHarness")
    world.isDevMode = true

    # ref https://www.google.com/search?q=requestanimationframe
    animloop = ->
      world.doOneCycle()
      window.requestAnimationFrame animloop
    animloop()

    # in case we want to set up the page
    # for the System Tests, then add a panel
    # to the right where helper commands can be
    # clicked.
    if window.location.href.includes "worldWithSystemTestHarness"
      if SystemTestsControlPanelUpdater?
        new SystemTestsControlPanelUpdater

    window.menusHelper = new MenusHelper
    world.removeSpinnerAndFakeDesktop()

    world.basementWdgt = new BasementWdgt

    #ProfilingDataCollector.enableProfiling()
    #ProfilingDataCollector.enableBrokenRectsProfiling()

    if world.isIndexPage
      world.createDesktop()

  # Under the SWCanvas backend, font metrics must be loaded before the world is
  # built (see bootstrapSWCanvasFontsThen), so world creation is deferred. Return
  # a promise so the boot chain waits for `world` to exist before using it.
  if window.FIZZYGUM_USE_SWCANVAS and window.SWCanvas?
    new Promise (resolve) ->
      bootstrapSWCanvasFontsThen ->
        startWorld()
        resolve()
  else
    startWorld()
    Promise.resolve()

# This is a classic extension mechanism in JS,
# also used by the CoffeeScript versions 1.x.
# Nominally CoffeeScript v2 (which we use) just uses the ES6
# native implementation, however we scrap what CoffeeScript v2
# does and we use this (a more "manual" way)
extend = (child, parent) ->
  # starting situation: both child and parent are classes
  # i.e. constructors with their own prototype. Those prototypes
  # have .constructor and _proto_ that points to their
  # respective class.

  # what we want to do is to create a new prototype for the child,
  # where its constructor still points to child, however its
  # _proto_ points to the parent prototype, so there is the
  # inheritance chain that we want.

  # create a temporary function. we'll use it as
  # a constructor (with new) to construct a new prototype for the
  # child, and then throw it a way
  ctor = ->
    # the prototype associated with this constructor
    # will have its .constructor that
    # will point to child (instead of pointing at this very
    # constructor function)
    @constructor = child
    return

  # copy over static fields/methods from parent to child
  for own key of parent
    child[key] = parent[key]

  # by doing this, anything created with new ctor
  # will have the _proto_ pointing to parent.prototype
  # which is indeed what we want for the new child
  # prototype we are going to create via the temp constructor
  ctor.prototype = parent.prototype

  # invoke the temp constructor so it creates a new object
  # where its .constructor will point to child, and its _proto_
  # will point to the parent prototype.
  # For this object will be the new child.prototype,
  # just make child.prototype to actually point to it
  child.prototype = new ctor

  # just a service field to be able to use super
  child.__super__ = parent.prototype

  return child
