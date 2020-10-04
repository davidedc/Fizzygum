# globals -------------------------------------------------
world = {}

srcLoadsSteps = []

srcLoadCompileDebugWrites = false

Automator = null
AutomatorRecorder = null
AutomatorPlayer = null


# This is used for mixins: MixedClassKeywords is used
# to protect some methods so the are not copied to object,
# because they have special meaning
# (this comment from a stackOverflow answer from clyde
# here: http://stackoverflow.com/a/8728164/1318347 )
MixedClassKeywords = ['onceAddedClassProperties', 'included']

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

CONSTANT_INIT_AFTER_CLASS_DEFINITION = undefined

## -------------------------------------------------------
# de-camelize
# taken from https://github.com/sindresorhus/decamelize/blob/master/index.js

decamelize = (str, sep) ->
  if (typeof str) != 'string'
    throw new TypeError "Expected a string"
  str.replace(/([a-z\d])([A-Z])/g, '$1' + (sep or '_') + '$2').toLowerCase()

## -------------------------------------------------------

getParameterByName = (name) ->
  name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]')
  regex = new RegExp '[\\?&]' + name + '=([^&#]*)'
  results = regex.exec location.search
  if results?
    return decodeURIComponent results[1].replace(/\+/g, ' ')
  else
    return nil

# returns the function that does nothing
nop = ->
  # this is the function that does nothing:
  ->
    nil

noOperation = ->
    nil

isFunction = (functionToCheck) ->
  typeof(functionToCheck) is "function"

isString = (target) ->
  typeof target is "string" or target instanceof String

isObject = (target) ->
  target? and (typeof target is "object" or target instanceof Object)

degreesToRadians = (degrees) ->
  degrees * Math.PI / 180

radiansToDegrees = (radians) ->
  radians * 180 / Math.PI

# this fontHeight is too thin.
# tall characters such as ⎲ƒ⎳⎷ ⎸⎹ are cut
# but hey they look cut also in this text editor I'm using.
fontHeight = (fontSize) ->
  minHeight = Math.max fontSize, WorldMorph.preferencesAndSettings.minimumFontHeight
  Math.ceil minHeight * 1.2 # assuming 1/5 font size for ascenders

# newCanvas takes physical size, i.e. actual buffer pixels
# on retina displays that's twice the amount of logical pixels,
# which are used for all other measures of morphs.
# So if the dimensions come from a canvas size, then those are
# already physical pixels.
# If the dimensions come form other measurements of the morphs
# then those are in logical coordinates and need to be
# corrected with ceilPixelRatio before being passed here.
newCanvas = (extentPoint) ->
  extentPoint?.debugIfFloats()
  # answer a new empty instance of Canvas, don't display anywhere
  ext = extentPoint or
    x: 0
    y: 0
  canvas = document.createElement "canvas"
  canvas.width = Math.ceil ext.x
  canvas.height = Math.ceil  ext.y
  canvas

# -------------------------------------------

howManyTestManifestsLoaded = 0
howManySourcesCompiledAndEvalled = 0

# a helper function to use Promise style
# instead of callback style when loading a JS
loadJSFilePromise = (fileName) ->
  return new Promise (resolve, reject) ->

    script = document.createElement "script"
    script.src = fileName
    script.async = true # should be the default

    # triggers after the script was loaded and executed
    # see https://javascript.info/onload-onerror#script-onload
    script.onload = ->
      addLineToLogDiv? "loaded and executed " + this.src
      if srcLoadCompileDebugWrites then console.log "loaded and executed " + this.src
      resolve(script)

    document.head.appendChild script

    script.onerror = ->
        reject(script)


# useful function to pace "then" steps,
# we use it in two modes:
#
# 1. in "pre-compiled" mode we load all the
# sources and we pace those loads triggering
# the "waits" on animationFrames, so that
# we don't create too much gitter as the
# world is going.
# We achieve this by storing the "resolve"
# method in an array that we check in
# doOneCycle. So when there is a frame running
# we see if we can resolve one such "gate" so
# that the next source can be loaded.
#
# 2. In non-precompiled mode we don't care about
# the gitter because there is no running world
# (because we still have to build it from the
# sources we are loading now),
# so we can just wait each compilation step on
# a timer.
waitNextTurn = ->
  () ->
    if window.preCompiled
      prms = new Promise (resolve, reject) ->
        window.srcLoadsSteps.push resolve
    else
      # see https://gist.github.com/joepie91/2664c85a744e6bd0629c
      prms = new Promise (resolve, reject) ->
        setTimeout () ->
          resolve arguments
        , 1
    return prms


# there are two main ways of booting the world:
# 1. without pre-compiled files. In this case the
#    boot needs to load all the sources, compile
#    them and build all the classes and mixins.
#    The classes need to be appropriately chained
#    into a class hyerarchy and they need to be
#    augmented with the desired mixins.
#    Only after all that the world will be able to
#    start.
# 2. with pre-compiled files. In this case there
#    is a JS file that containes all the compiled
#    JS versions of all the classes and mixins, plus
#    all the code to build the class hyerarchy and
#    to augment the classes with the correct mixins.
#    So, no compilation of sources is needed for the
#    world to start, so this is much faster. The
#    world will still asynchronously load all the
#    sources so one can edit the original coffeescript.
boot = ->

  window.stillLoadingSources = true

  # There are four separate but related questions related to scaling:
  # -----------------------------------------------------------------
  # 1) how do I know the physical measurement (e.g. actual inches)
  #    of something I paint on screen (e.g. how to make a button
  #    big enough for tapping)
  # 2) how do I know the current zoom level of the browser
  # 3) how do I make the fizzygum canvas not blurry
  # 4) how do I make the fizzygum UI big enough for good readibility
  #    and touch input?

  # The answer to 1) is easy:
  #   it can't be done with CSS or JS alone. Deal with it. Some screens
  #   are more dense and report the same pixelRatio as normal ones.
  #   Even iPad models have slightly different retina densities.
  #   This is not exposed via CSS or JS in any way. We can put in place
  #   _an interacive_ way to ask the user to tell us how far apart are
  #    her fingers for example, so we can draw the UI well.

  # The answer to 2) is:
  #   There is no way to ONLY know the zoom level independently.
  #   devicePixelRatio takes into account both the pixel density of the
  #   display and the current zoom level of the browser.

  # Answer to 3):
  #   Device pixel ratio reflects not only the pixel density on screen
  #   (e.g. for retina displays and high-dpi displays), BUT ALSO the current
  #   zoom level of the page. So for example many windows setups have a
  #   default page zoom of 110% or 125% ... this means that on a
  #   "standard-dpi" screen the devicePixelRatio would be 1.1 and
  #   1.25 respectively.
  #
  #   So at 110% zoom level, the browser gives the canvas THE SAME LOGICAL PIXELS,
  #   BUT it makes it physically bigger on the screen and it changes the
  #   device pixel ratio. So if Fizzygum plays its cards well, it will give
  #   more physical pixels to the canvas accordingly to the device pixel ratio,
  #   and paint on that, keeping the canvas crisp even if it's larger than normal.
  #
  #   While in theory knowing the device pixel ratio would allow us to give the
  #   canvas the exact amount of extra physical pixels and we could draw the
  #   canvas crisply, it's impossible to deal simply and effectively with
  #   non-integer pixel ratios, because, say, a 9-units large widget would
  #   become 9.9 physical units which is difficult to draw sharply and clip
  #   and pointer-test. So, logical 9-units would become 10 physical units...
  #   and you see the kind of complications you'd get as you are trying to
  #   make pixel-accurate clipping and drawing...
  #
  #   E.g. a logical 9-units widget would effectlively paint contiguously next
  #   to a widget to its right that has a logical 10-units displacement
  #   (instead of leaving one empty pixel between the two).
  #
  #   Other forms of approximation (e.g. use ceil instead of round) would incur
  #   in similar problems.
  #
  #   Expecially clipping and pointer-testing would be prone to error because
  #   they are done in logical coordinates where that complication is not
  #   visible... so the problem is that the logical and physical coordinates
  #   would be out-of-step in subtle ways.
  #
  #   Also for example a 5-unit widget would need rounding of its pixels, but
  #   a 5+5 unit widget wouldn't (cause it would be precisely 11 physical pixels).
  #
  #   WHAT WE DO INSTEAD is the following: just ceil the devicePixelRatio and
  #   use that. The canvas then has *more* pixels than needed, and will fill
  #   its assigned area quite crisply in my experiments.

  # Answer to 4):
  #   So our job in terms of this question consists of:
  #     a) first and foremost, keep the drawing crisp because a blurry screen
  #       is terrible - see answer to 3) AND
  #     b) to find the "big enough" logical sizing of things (buttons,
  #       thickness of lines etc).
  #   As mentioned there is no way in CSS/JS to actually know the real-world
  #   measurement of things. What you _can_ do though is some interactive tests
  #   where the user can directly or indirectly tell a good size for things
  #   (e.g. place index and middle finger attached to each other and tap in a space).
  #   THEN our job is just to make the UI elements of the comfortable logical units.

  window.ceilPixelRatio = Math.ceil window.devicePixelRatio

  # First loaded batch ----------------------------------------
  #
  # note that we assume that all the parts of this first batch
  # can be loaded/"run" in any order.
  # The only thing that is loaded already is fizzygum-boot.js
  # which is this very file of globals.
  #
  # You could probably do the same loading here by
  # plainly using script tags in the index file.
  #
  # Note that it's important that none of the code in each
  # of these entries of this batch uses the code of any
  # of the other entries of this batch. E.g. the pre-compiled
  # classes can't instantiate static or non-static properties
  # with, say, the result of running the coffeescript compiler.
  # (when you define a class, all static and nonstatic properties
  #  are immediately initialised so for example doing
  #
  #    myCompiledCode: Coffeescript.compile(...)
  #
  # would run the compilation immediately during the class
  # definition and would hence depend on Coffeescript being
  # loaded already.
  #
  # Note however that since the pre-compiled classes are pre-
  # compiled in the correct dependency order (following the
  # REQUIRES directives), each class *can*
  # initialise static/nonstatic properties with objects
  # created from other classes (as long as the REQUIRES
  # directives are well set). So for example a Widget can
  # initialise a "color" property doing something like
  #
  #   myCol: Color.create(...)
  #
  # Also note that we load "Coffeescript" here.
  # Obviously if we don't have the pre-compiled file we need
  # that to create the Widgets and all that is needed to
  # start the world, that's a given.
  # But *also* we need it now if we have the pre-compiled file,
  # that's because actually the Fizzypaint application
  # compiles the paint instruments on start, so we
  # really need to have the Coffeescript compiler on
  # world start if we open the world with Fizzypaint in it.
  # If it wasn't for that, we could
  # postpone the loading of the compiler to after
  # world start.
  #
  # An alternative way of doing things here would be
  # to try to generate at build time a SINGLE big JS file
  # that includes all these parts, and hence loading all in
  # one go.
  # That wouldn't necessarily be more performant but it could
  # be tried.
  # (it could be better to load a few files in parallel
  # and parse them ideally in parallel but I didn't measure
  # that).

  bootLoadPromises = [loadJSFilePromise "js/pre-compiled.js"]

  # TODO rather than relying on this test to load these .js at boot,
  # we should really just dynamically load these when needed
  # (e.g. when tests are run, or when pre-compiled generation is invoked)

  if BUILDFLAG_LOAD_TESTS
    bootLoadPromises.push loadJSFilePromise "js/libs/Mousetrap.min.js"

  if BUILDFLAG_LOAD_TESTS or (window.location.href.includes "generatePreCompiled")
    bootLoadPromises.push loadJSFilePromise "js/libs/FileSaver.min.js"
    bootLoadPromises.push loadJSFilePromise "js/libs/jszip.min.js"
    bootLoadPromises.push loadJSFilePromise "js/tests/testsManifest.js"
    bootLoadPromises.push loadJSFilePromise "js/tests/testsAssetsManifest.js"

  (Promise.all bootLoadPromises).then ->

  # end of first batch
  # -----------------------------------------------------------

    if window.preCompiled
      createWorldAndStartStepping()
  .then ->
    Promise.all [
      loadJSFilePromise("js/libs/coffee-script_2.0.3.js"),
      loadJSFilePromise("js/coffeescript-sources/Class_coffeSource.js"),
      loadJSFilePromise("js/coffeescript-sources/Mixin_coffeSource.js"),
      loadJSFilePromise("js/src/loading-and-compiling-coffeescript-sources-min.js"),
      loadJSFilePromise("js/src/logging-div-min.js")
    ]
  .then ->
    eval.call window, compileFGCode window["Mixin_coffeSource"], true
    eval.call window, compileFGCode window["Class_coffeSource"], true
  .then ->
    loadJSFilePromise("js/src/dependencies-finding-min.js")
  .then ->
    loadJSFilesWithCoffeescriptSourcesPromise()
  .then ->
    if window.preCompiled
      (storeSourcesAndPotentiallyCompileThemAndExecuteThem true).then ->
        window.stillLoadingSources = false
        if Automator
          Automator.testsManifest = testsManifest
          Automator.testsAssetsManifest = testsAssetsManifest
        startupActions = getParameterByName "startupActions"
        if startupActions?
          world.nextStartupAction()
    else
      addLogDiv()
      (storeSourcesAndPotentiallyCompileThemAndExecuteThem false).then ->
        window.stillLoadingSources = false
        if Automator
          Automator.testsManifest = testsManifest
          Automator.testsAssetsManifest = testsAssetsManifest
      .then ->
        createWorldAndStartStepping()
        startupActions = getParameterByName "startupActions"
        if startupActions?
          world.nextStartupAction()


# we use the trackChanges array as a stack to
# keep track whether a whole segment of code
# (including all function calls in it) will
# record the broken rectangles.
# This was previously done only by using one global
# flag but this was not entirely correct because it
# wouldn't account for nesting of "disabling track
# changes" correctly.
trackChanges = [true]
window.healingRectanglesPhase = false
window.morphsThatMaybeChangedGeometryOrPosition = []
window.morphsThatMaybeChangedFullGeometryOrPosition = []
window.morphsThatMaybeChangedLayout = []

createWorldAndStartStepping = ->

  # Add "false" as second parameter below
  # to fit the world in canvas as per dimensions
  # specified in the canvas element. Fill entire
  # page otherwise.
  if window.location.href.includes "worldWithSystemTestHarness"
    # the user is here to record a system test so
    # don't fill entire page cause there are some
    # controls on the right side of the canvas
    world = new WorldMorph worldCanvas, false
  else
    world = new WorldMorph worldCanvas, true
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
  world.createDesktop()

# a helper function to use Promise style
# instead of callback style when creating
# an Image from the image data
createImageFromImageData = (theImageData) ->
  return new Promise (resolve, reject) ->
    img = new Image
    img.onload = ->
        resolve(img)
    img.onerror = ->
        reject(img)
    img.src = theImageData

# these two are to build classes

# this is a classic extention mechanism in JS,
# also used by the CoffeeScript versions 1.x
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

getRandomInt = (min, max) ->
  min = Math.ceil min
  max = Math.floor max
  Math.floor Math.random() * (max - min) + min
