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

# Paces the FETCHING of the coffeescript sources batches: each waitNextTurn
# parks its resolver here and the world's doOneCycle releases one per frame
# (progressFramePacedActions). Compiling the fetched sources goes through
# window.SourceCompileScheduler instead, drained at END of frame under a time
# budget. An array is overkill -- batches load one at a time -- but harmless.
framePacedPromises = []

srcLoadCompileDebugWrites = false
bootLoadingDebugWrites = false

stillLoadingSources = nil


# This is used for mixins: MixedClassKeywords is used
# to protect some methods so the are not copied to object,
# because they have special meaning
# (this comment from a stackOverflow answer from clyde
# here: http://stackoverflow.com/a/8728164/1318347 )
MixedClassKeywords = ['onceAddedClassProperties', 'included', 'consumerClassNames']

noOperation = ->
    nil

# -------------------------------------------

# IS THIS PART LOADED AT BOOT? The ONE answer to that question, for the whole system: the boot batch
# loader asks it (loading-and-compiling-coffeescript-sources.coffee, deciding which source batches to
# fetch) and so does PartsRegistry (deciding which parts to report as already resident).
#
# A part is here at boot if buildSystem/parts.json says `eager` (the default), OR if this entry page
# overrides every part to eager. The override is a build-time page preset (build.py's ENTRY_PAGES),
# set by worldWithSystemTestHarness.html and index-sw.html: a part arriving MID-TEST would be
# frame-paced, hence cycle-count-dependent, which is exactly the nondeterminism class
# ../Fizzygum-tests/DETERMINISM.md is about.
#
# ⚠ TWO REASONS IT LIVES HERE, in the boot BUNDLE, rather than next to either caller:
#  1. It was briefly implemented TWICE -- the entry-page override in PartsRegistry only -- so on the
#     harness page the boot loader still skipped the lazy part's batch and every Fizzytiles
#     SystemTest STALLED on an undefined class, while the registry reported the part LOADED. Two
#     places encoding one rule IS the bug. Do not re-split it.
#  2. It must exist before the WORLD does. On a pre-compiled boot,
#     createWorldAndStartStepping() runs as soon as js/pre-compiled.js has loaded -- BEFORE the
#     separately-fetched js/src/loading-and-compiling-coffeescript-sources-min.js. Defining this
#     there made a production tree die at boot with "window.fizzygumPartIsEagerHere is not a
#     function" (caught by fg homepage). The bundle is the entry page's first script, so anything
#     the world's constructor needs belongs in it.
# `window.`-qualified because a src class cannot see a boot-file local.
window.fizzygumPartIsEagerHere = (spec) ->
  spec.eager or window.FIZZYGUM_EAGER_ALL_PARTS is true

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
#    world to start, so this is much faster. Whether the
#    original coffeescript sources follow it -- so one can
#    view/edit them -- is then the profile's `sources`
#    policy: right away in the background, on first demand,
#    or never (see loadReflectiveLayerPromise below and
#    buildSystem/buildProfile.py's SOURCES_POLICIES).
# THE REFLECTIVE LAYER: the class SOURCE TEXT, plus the meta-system that parses it.
#
# It is what lets the running system show and rewrite its own code -- the inspectors' member maps,
# and a snapshot's class/mixin source edits. It is NOT what makes the world go: a pre-compiled world
# is already running before any of this, and (arc 5) a profile with sources: "none" never calls this
# at all and ships none of the files it fetches.
#
# On the COMPILE-AT-BOOT path it is not optional and not "reflective" either -- there the sources ARE
# the world, so the final step compiles and EXECUTES them (justIngestSources = false) and only then
# is there a world to start. Both paths share the same five steps, which is why this is one function:
#   1. the Class and Mixin sources, the only two classes a pre-compiled image does not contain
#      (they are compiled here by hand, so nothing accumulated them into it)
#   2. compile + eval those two: the meta-system must exist before any batch can be ingested
#   3. dependencies-finding, which computes the load order from the source text
#   4. every eager part's source batches (window.FIZZYGUM_PARTS drives which)
#   5. ingest-only (true) against the already-running classes, or compile-and-execute (false) to
#      CREATE them
# THE META-SYSTEM: steps 1-3 on their own, because a LAZY PART needs exactly them and nothing else.
#
# ⚠⚠ WHY THIS IS SPLIT OUT. Ingesting any source means `new Class` / `new Mixin` (see
# storeSourceAndPotentiallyCompileItAndExecuteIt), and ordering a batch means findLoadOrder -- and on
# a PRECOMPILED tree none of the three exist: Class and Mixin are the only two classes absent from
# js/pre-compiled.js, and findLoadOrder ships in a file nothing has injected yet. A lazy part loading
# on such a tree therefore died with "findLoadOrder is not defined" until this split existed.
# PartsRegistry._loadPartPromise awaits this, and MUST NOT await the whole reflective layer instead:
# step 4 below is every eager batch, 2.29 MB on production, which would hand back the entire saving
# that made the part lazy. These three files are ~39 KB.
loadMetaSystemPromise = ->
  Promise.all [
    loadJSFilePromise("js/coffeescript-sources/Class-source.js"),
    loadJSFilePromise("js/coffeescript-sources/Mixin-source.js")
  ]
  .then ->
    if bootLoadingDebugWrites then console.log "---- Class + Mixin sources loaded"
    # the two meta-system sources are the only ones fetched individually and compiled by hand:
    # everything else needs Class/Mixin to already exist before it can be ingested.
    eval.call window, compileFGCode SourceVault.get("Mixin"), true
    eval.call window, compileFGCode SourceVault.get("Class"), true
  .then ->
    if bootLoadingDebugWrites then console.log "---- compiled the Mixin and Class sources"
    loadJSFilePromise("js/src/dependencies-finding-min.js")

# Memoized like the layer itself: a part load and a later inspector open share ONE fetch of these.
metaSystemLoadPromise = nil

ensureMetaSystemLoaded = ->
  metaSystemLoadPromise ?= loadMetaSystemPromise()
  metaSystemLoadPromise

loadReflectiveLayerPromise = ->
  ensureMetaSystemLoaded()
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
        runPostBootActionsOnce()
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
        runPostBootActionsOnce()

# WHO ASKED FOR THE REFLECTIVE LAYER, and has it arrived?
#
# Memoized: whoever asks first starts the load, everyone else joins the same promise, and a build
# that never asks never fetches a byte of it. That is what makes sources: "lazy" possible.
#
# ⚠ `reflectiveLayerIsLoaded` exists so that a caller can keep its fast path SYNCHRONOUS. On every
# build except a lazy one the layer is already here by the time anything asks, and deferring such a
# caller by even a microtask would move its effect a world cycle later -- which the SystemTest suite
# measures, since it drives the world cycle by cycle (../Fizzygum-tests/DETERMINISM.md).
reflectiveLayerLoadPromise = nil
reflectiveLayerHasLoaded = false

ensureReflectiveLayerLoaded = ->
  reflectiveLayerLoadPromise ?= loadReflectiveLayerPromise().then -> reflectiveLayerHasLoaded = true
  reflectiveLayerLoadPromise

reflectiveLayerIsLoaded = -> reflectiveLayerHasLoaded

# Can it ever arrive? No, for exactly one policy: "none" ships none of the text.
reflectiveLayerCanLoad = -> BUILDFLAG_SOURCES isnt "none"

# The two things that must happen ONCE, after the world is up, no matter where this boot finished:
# the test manifests the Automator reads, and the `?startupActions=` URL parameter. They live here
# rather than in the tail of the source-ingest chain because a "lazy" or "none" build never runs that
# chain at boot, and a startup action that fires on some profiles but not others is exactly the class
# of bug a per-flavour code path breeds. The guard is what lets a lazy build call this at boot AND
# again when the layer eventually lands, and still fire once.
postBootActionsHaveRun = false
runPostBootActionsOnce = ->
  return if postBootActionsHaveRun
  postBootActionsHaveRun = true
  if Automator?
    Automator.testsManifest = testsManifest
    Automator.testsAssetsManifest = testsAssetsManifest
  if startupActions = world.getParameterPassedInURL? "startupActions"
    world.nextStartupAction()

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

  # --- rendering backend + pixel ratio --------------------------------------
  #   window.FIZZYGUM_USE_SWCANVAS  routes every canvas made via
  #           HTMLCanvasElement.createOfPhysicalDimensions through SWCanvas
  #           instead of the DOM. It is PRESET by the entry page, never chosen
  #           here — see below.
  #   ?dpr=N  (or window.FIZZYGUM_FORCE_PIXEL_RATIO) forces ceilPixelRatio, so a
  #           HiDPI (e.g. retina, dpr 2) run can be exercised on a standard screen.
  #           This is exact for the SWCanvas backend (display-independent).
  bootQueryParams = nil
  try
    bootQueryParams = new URLSearchParams window.location.search
  catch err
    bootQueryParams = nil

  # The rendering backend is a BUILD-TIME property of the entry page: every page
  # buildSystem/build.py emits presets FIZZYGUM_USE_SWCANVAS in an inline script
  # right before its boot bundle, and that bundle carries exactly the engine the
  # preset names (the full SWCanvas engine, or just the 3D core SW3D needs). So
  # a missing preset is not a case to default sensibly for — it means the page
  # is about to drive an engine it did not load. Say so.
  unless window.FIZZYGUM_USE_SWCANVAS?
    console.error "FIZZYGUM_USE_SWCANVAS is not preset: this page was not generated by buildSystem/build.py (see its ENTRY_PAGES). Assuming the native backend."
    window.FIZZYGUM_USE_SWCANVAS = false

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
    loadJSFilePromise "js/libs/fizzygum-coffeescript-min.js"
  ]

  # FileSaver + jszip + the two test manifests are TEST machinery, so they load only for a
  # tests-carrying build. A ?generatePreCompiled boot needs none of it: it just accumulates
  # window.JSSourcesContainer.content, which an external headless driver reads back out and
  # writes to disk from Node (../Fizzygum-tests/scripts/generate-pre-compiled-headless.js).
  if BUILDFLAG_LOAD_TESTS
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
    # ⚠ These two are NOT part of the reflective layer and load in EVERY artifact.
    # loading-and-compiling-coffeescript-sources defines compileFGCode, which is PRODUCT machinery,
    # not a dev affordance: ScriptWdgt, Widget.evaluateString and the spreadsheet's
    # FormulaCompiler all compile user-written CoffeeScript at runtime (arc 5 PR-D3 -- the compiler
    # ships everywhere for the same reason). A build that dropped this would look fine until someone
    # typed a formula.
    Promise.all [
      loadJSFilePromise("js/src/loading-and-compiling-coffeescript-sources-min.js"),
      loadJSFilePromise("js/src/logging-div-min.js")
    ]
  .then ->
    if bootLoadingDebugWrites then console.log "---- loading-and-compiling-coffeescript-sources-min, logging-div-min loaded"
    # WHEN does the reflective layer load? (buildProfile.py SOURCES_POLICIES)
    #   "none"        never: this artifact ships no class source text at all, so there is nothing to
    #                 fetch, nothing to ingest and no meta-system. The flag has to be answered here
    #                 rather than by an empty parts manifest, because the Class and Mixin sources are
    #                 fetched BY NAME, not through the manifest, and would 404.
    #   "lazy"        not now: the first consumer calls ensureReflectiveLayerLoaded() and waits.
    #                 Today that is opening an inspector (Widget.spawnInspector) or restoring a
    #                 snapshot that carries class-level source edits (WorldWdgt.loadWorldSnapshot).
    #   "background"  now, behind the running world -- the historical behaviour.
    #
    # ⚠ `window.preCompiled` is load-bearing in this condition, not defensive. The ONE boot that must
    # run the layer whatever the policy says is the artifact's own pre-compile pass: the driver boots
    # the freshly-built tree at ?generatePreCompiled while js/pre-compiled.js is still the
    # `preCompiled = false` stub, and compiling those sources is how the image gets harvested. Drop
    # this clause and a lean build fails with "pre-compiled generation failed" (measured).
    if window.preCompiled and BUILDFLAG_SOURCES isnt "background"
      # Nothing is loading, so say so -- and do the post-boot work the ingest tail would have done.
      stillLoadingSources = false
      runPostBootActionsOnce()
      return
    ensureReflectiveLayerLoaded()


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
    # TEST-ONLY machinery lives with the harness (../Fizzygum-tests/Automator-and-test-harness-src),
    # not inside the shipped classes, and is grafted onto the core prototypes here. Each *TestSupport
    # class only exists in a build that ships the harness, so the existence checks ARE the mechanism
    # that keeps a product build free of all this -- the same pattern as `Automator?` / `MacroToolkit?`
    # / `SystemTestsControlPanelUpdater?` below. (Before arc 3 these members sat in the core files
    # wrapped in `»>>` region markers and were textually stripped at packaging time.)
    #
    # ⚠ This must run BEFORE `new WorldWdgt`: the world's own constructor calls
    # `_sizeCanvasToTestScreenResolution`, which is one of the members installed here.
    WorldTestSupport.installOnto WorldWdgt  if WorldTestSupport?
    WidgetTestSupport.installOnto Widget  if WidgetTestSupport?
    MenuTestSupport.installOnto MenuWdgt  if MenuTestSupport?
    MenuRowsPanelTestSupport.installOnto MenuRowsPanelWdgt  if MenuRowsPanelTestSupport?
    MenusHelperTestSupport.installOnto MenusHelper  if MenusHelperTestSupport?

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
    # The demo/parts-bin catalogue. `demos` is a LAZY part, so this line is deliberately BOTH
    # things at once and the guard is load-bearing in two different ways:
    #   - on a page that forces every part eager (the harness, index-sw.html) the class is here at
    #     boot, so `demoMenus` is built exactly when it always was and every test sees the world it
    #     always saw;
    #   - on index.html the class is absent, this is a no-op, and the singleton is instead built on
    #     first use by the doors that await the part (WorldWdgt.popUpDemoTestMenu,
    #     WorldWdgt.createDemoAnalogClock), which name the class as data to construct it.
    # A build that does not ship `demos` at all simply never gets one, as before.
    window.demoMenus = new DemoMenus  if DemoMenus?
    world.removeSpinnerAndFakeDesktop()

    world.binWdgt = new BinWdgt
    world.shelfWdgt = new ShelfWdgt

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
