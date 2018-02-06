# Globals ////////////////////////////////////////////////////

world = {} # we make "world" global

window.srcLoadsSteps = []

window.srcLoadCompileDebugWrites = false


addLogDiv = ->
  # this "log" div shows info a) while loading all the source files and then
  # b) while compiling and evaluating them. Useful to give some feedback as these
  # can take in order of 10s of seconds. This div is removed after the last
  # log to it
  loadingLogDiv = document.createElement 'div'
  loadingLogDiv.id = 'loadingLog'
  loadingLogDiv.style.position = 'absolute'
  loadingLogDiv.style.width = "960px"
  loadingLogDiv.style.backgroundColor = "rgb(245, 245, 245)"
  loadingLogDiv.style.top = "0px"
  loadingLogDiv.style.top = "0px"
  document.getElementsByTagName('body')[0].appendChild(loadingLogDiv)

removeLogDiv = ->
  loadingLogDiv = document.getElementById 'loadingLog'
  loadingLogDiv?.parentElement.removeChild loadingLogDiv

emptyLogDiv = ->
  loadingLogDiv = document.getElementById 'loadingLog'
  loadingLogDiv?.innerHTML = ""

addLineToLogDiv = (content) ->
  loadingLogDiv = document.getElementById 'loadingLog'
  loadingLogDiv?.innerHTML += content + "</br>"

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

HTMLCanvasElement::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf(@)
  if  haveIBeenCopiedAlready >= 0
    if doSerialize
      return "$" + haveIBeenCopiedAlready
    else
      return objectClones[haveIBeenCopiedAlready]

  positionInObjClonesArray = objOriginalsClonedAlready.length
  objOriginalsClonedAlready.push @
  # with and height here are not the morph's,
  # which would be in logical units and hence would need pixelRatio
  # correction,
  # but in actual physical units i.e. the actual bugffer size
  cloneOfMe = newCanvas new Point @width, @height

  ctx = cloneOfMe.getContext "2d"
  ctx.drawImage @, 0, 0

  if doSerialize
    cloneOfMe = {}

  objectClones.push cloneOfMe

  if doSerialize
    cloneOfMe.className = "Canvas"
    cloneOfMe.width = @width
    cloneOfMe.height = @height
    cloneOfMe.data = @toDataURL()
    return "$" + positionInObjClonesArray


  return cloneOfMe

CanvasRenderingContext2D::rebuildDerivedValue = (objectIBelongTo, myPropertyName) ->
  objectIBelongTo[myPropertyName] = objectIBelongTo.backBuffer.getContext "2d"

# Extending Array's prototype if 'filter' doesn't exist
# already
unless Array::filter
  Array::filter = (callback) ->
    element for element in this when callback element

Array::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf @
  if haveIBeenCopiedAlready >= 0
    if doSerialize
      return "$" + haveIBeenCopiedAlready
    else
      return objectClones[haveIBeenCopiedAlready]

  positionInObjClonesArray = objOriginalsClonedAlready.length
  objOriginalsClonedAlready.push @
  cloneOfMe = []
  objectClones.push  cloneOfMe

  for i in [0... @.length]
    if !@[i]?
        cloneOfMe[i] = nil
    else if typeof @[i] == 'object'
      if !@[i].deepCopy?
        # this should never happen
        debugger
      cloneOfMe[i] = @[i].deepCopy doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure
    else
      cloneOfMe[i] = @[i]

  if doSerialize
    return "$" + positionInObjClonesArray

  return cloneOfMe

Array::chunk = (chunkSize) ->
  array = this
  [].concat.apply [], array.map (elem, i) ->
    if i % chunkSize then [] else [ array.slice(i, i + chunkSize) ]

# from http://stackoverflow.com/a/13895743
# removes the elements IN PLACE, i.e. the
# array IS modified
Array::remove = (args...) ->
  output = []
  for arg in args
    index = @indexOf arg
    output.push @splice index, 1 if index isnt -1
  output = output[0] if args.length is 1
  output

# deduplicates array entries
# doesn NOT modify array in place
Array::unique = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

# from https://gist.github.com/vjt/827679
if typeof String::camelize == 'undefined'
  String::camelize = ->
    @replace /(?:^|[-])(\w)/g, (_, c) ->
      if c then c.toUpperCase() else ''

if typeof String::contains == 'undefined'
  String::contains = (it) ->
    @indexOf(it) != -1

if typeof String::isLetter == 'undefined'
  String::isLetter = ->
    @length == 1 && @match /[a-z]/i

## -------------------------------------------------------

tick = "✓ "
untick = "    "

if typeof String::isTicked == 'undefined'
  String::isTicked = ->
    @startsWith tick

if typeof String::tick == 'undefined'
  String::tick = ->
    if @isTicked()
      return @
    else if @isUnticked()
      return @toggleTick()
    else
      return tick + @

if typeof String::untick == 'undefined'
  String::untick = ->
    if @startsWith untick
      return @
    else if @isTicked()
      return @toggleTick()
    else
      return untick + @

if typeof String::isUnticked == 'undefined'
  String::isUnticked = ->
    return !@isTicked()

if typeof String::toggleTick == 'undefined'
  String::toggleTick = ->
    if @isTicked()
      return @replace tick, untick
    else if @startsWith untick
      return @replace untick, tick
    else
      return tick + @

## -------------------------------------------------------

# used to clip any subsequent drawing on the context
# to the dirty rectangle.
CanvasRenderingContext2D::clipToRectangle = (al,at,w,h) ->
  @beginPath()
  @moveTo Math.round(al), Math.round(at)
  @lineTo Math.round(al) + Math.round(w), Math.round(at)
  @lineTo Math.round(al) + Math.round(w), Math.round(at) + Math.round(h)
  @lineTo Math.round(al), Math.round(at) + Math.round(h)
  @lineTo Math.round(al), Math.round(at)
  @closePath()
  @clip()

## -------------------------------------------------------

# utility function taken from:
# http://blog.abhranil.net/2011/11/03/simplest-javascript-fade-animation/

fade = (eid, initOp, finalOp, TimeToFade, time) ->
  if initOp == 0
    document.getElementById(eid).style.visibility = 'visible'
  curTick = new Date().getTime()
  elapsedTicks = curTick - time
  newOp = initOp + (finalOp - initOp) * elapsedTicks / TimeToFade
  if Math.abs(newOp - initOp) > Math.abs(finalOp - initOp)
    document.getElementById(eid).style.opacity = finalOp
    if finalOp == 0
      document.getElementById(eid).style.visibility = 'hidden'
    return
  document.getElementById(eid).style.opacity = newOp
  setTimeout 'fade( \'' + eid + '\',' + initOp + ',' + finalOp + ',' + TimeToFade + ',' + time + ')', TimeToFade / 100
  return

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

## -------------------------------------------------------
# These two methods are for mixins
## -------------------------------------------------------
# adds class properties
# these are added to the constructor
Object::augmentWith = (obj, fromClass) ->
  for key, value of obj when key not in MixedClassKeywords
    @[key] = value
  obj.onceAddedClassProperties?.apply @, [fromClass]
  this

# adds instance properties
# these are added to the prototype
Object::addInstanceProperties = (fromClass, obj) ->
  for own key, value of obj when key not in MixedClassKeywords
    # Assign properties to the prototype
    @::[key] = value

    # this is so we can use "super" in a mixin.
    # we normally can't compile "super" in a mixin because
    # we can't tell which class this will be mixed in in advance,
    # i.e. at compile time it doesn't
    # belong to a class, so at compile time it doesn't know which class
    # it will be injected in.
    # So that's why _at time of injection_ we need
    # to store the class it's injected in in a special
    # variable... and then at runtime we use that variable to
    # implement super
    if fromClass?
      if isFunction value
        @::[key + "_class_injected_in"] = fromClass
        console.log "addingClassToMixin " + key + "_class_injected_in"

  obj.included?.apply @
  this
##--------------- end of mixins methods -------------------


arrayShallowCopy = (anArray) ->
  anArray.concat()

arrayShallowCopyAndReverse = (anArray) ->
  anArray.concat().reverse()

# This is used a) for testing, we hash the
# data URL of a canvas object so to get a fingerprint
# of the image data, and compare it with "OK" pre-recorded
# values and b) to generate keys for some caches.
# adapted from http://werxltd.com/wp/2010/05/13/javascript-implementation-of-javas-string-hashcode-method/

hashCode = (stringToBeHashed) ->
  hash = 0
  return hash  if stringToBeHashed.length is 0
  for i in [0...stringToBeHashed.length]
    char = stringToBeHashed.charCodeAt i
    hash = ((hash << 5) - hash) + char
    hash = hash & hash # Convert to 32bit integer
  hash

# returns the function that does nothing
nop = ->
  # this is the function that does nothing:
  ->
    nil

noOperation = ->
    nil

isFunction = (functionToCheck) ->
  typeof(functionToCheck) is "function"

localize = (string) ->
  # override this function with custom localizations
  string

detect = (list, predicate) ->
  # answer the first element of list for which predicate evaluates
  # true, otherwise answer nil
  for element in list
    return element  if predicate.call nil, element
  nil

sizeOf = (object) ->
  # answer the number of own properties
  size = 0
  key = undefined
  for key of object
    size += 1  if Object::hasOwnProperty.call object, key
  size

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
# corrected with pixelRatio before being passed here.
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

getMinimumFontHeight = ->
  # answer the height of the smallest font renderable in pixels
  str = "I"
  size = 50
  canvas = document.createElement "canvas"
  canvas.width = size
  canvas.height = size
  ctx = canvas.getContext "2d"
  ctx.font = "1px serif"
  maxX = Math.ceil ctx.measureText(str).width
  ctx.fillStyle = "black"
  ctx.textBaseline = "bottom"
  ctx.fillText str, 0, size
  for y in [0...size]
    for x in [0...maxX]
      data = ctx.getImageData x, y, 1, 1
      return size - y + 1  if data.data[3] isnt 0
  0


getDocumentPositionOf = (aDOMelement) ->
  # answer the absolute coordinates of a DOM element in the document
  if !aDOMelement?
    return {x: 0, y: 0}
  pos =
    x: aDOMelement.offsetLeft
    y: aDOMelement.offsetTop

  offsetParent = aDOMelement.offsetParent
  while offsetParent?
    pos.x += offsetParent.offsetLeft
    pos.y += offsetParent.offsetTop
    if offsetParent isnt document.body and offsetParent isnt document.documentElement
      pos.x -= offsetParent.scrollLeft
      pos.y -= offsetParent.scrollTop
    offsetParent = offsetParent.offsetParent
  pos

# -------------------------------------------

howManyTestManifestsLoaded = 0
howManySourcesCompiledAndEvalled = 0

# a helper function to use Promise style
# instead of callback style when loading a JS
loadJSFile = (fileName, dontLogToDiv) ->
  return new Promise (resolve, reject) ->

    script = document.createElement "script"
    script.src = fileName

    script.onload = ->
      addLineToLogDiv "loading " + this.src
      console.log "loading " + this.src
      resolve(script)

    document.head.appendChild script

    script.onerror = ->
        reject(script)


loadJSFilesWithCoffeescriptSources = ->

  allSourceLoadsPromises = []

  for eachFile in sourcesManifests
    
    # just skip this one cause it's already loaded
    if eachFile == "Class_coffeSource" then continue
    if eachFile == "Mixin_coffeSource" then continue
    
    allSourceLoadsPromises.push loadJSFile "js/sourceCode/" + eachFile + ".js"

  return (Promise.all allSourceLoadsPromises)


compileFGCode = (codeSource, bare) ->
  t0 = performance.now()
  try
    # Coffeescript v2 is used
    compiled = CoffeeScript.compile codeSource,{"bare":bare}
  catch err
    errorMessage =  "error in compiling:\n"
    errorMessage += codeSource + "\n"
    errorMessage += "error:\n"
    errorMessage += err + "\n"
    if !world.errorConsole? then world.createErrorConsole()
    world.errorConsole.popUpWithError errorMessage

  t1 = performance.now()
  #console.log "compileFGCode time: " + (t1 - t0) + " milliseconds."

  return compiled

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

  # First loaded batch ----------------------------------------
  #
  # note that we assume that all the parts of this first batch
  # can be loaded/"run" in any order.
  # The only thing that is loaded already is fizzygum-boot.js
  # which is this very file of globals.
  #
  # The advantage of doing this asynchronous loading
  # instead of plainly using script tags in the index
  # is that script tags in the index file tend to load
  # and execute in sequence (because the running of a
  # script could change the html afterwards that loads the
  # others, although browsers can speculatively
  # try to do everything in parallel).
  #
  # By doing this here instead we have exact control of what
  # is loaded and what the logic of the order is, all
  # in one place, and all this loading and parsing can be
  # done in parallel.
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
  # directives are well set). So for example a Morph can
  # initialise a "color" property doing something like
  #
  #   myCol: new Color(...)
  #
  # Also note that we load "Coffeescript" here.
  # Obviously if we don't have the pre-compiled file we need
  # that to create the Morphs and all that is needed to
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

  (Promise.all [
      loadJSFile("js/libs/FileSaver.min.js"),
      loadJSFile("js/libs/jszip.min.js"),
      loadJSFile("js/sourceCode/Class_coffeSource.js"),
      loadJSFile("js/sourceCode/Mixin_coffeSource.js"),
      loadJSFile("js/sourceCode/sourceCodeManifest.js"),
      loadJSFile("js/tests/testsManifest.js"),
      loadJSFile("js/tests/testsAssetsManifest.js"),
      loadJSFile("js/libs/coffee-script_2.0.3.js"),
      loadJSFile("js/pre-compiled.js"),
      loadJSFile("js/libs/Mousetrap.min.js"),
  ]).then ->

  # end of first batch
  # -----------------------------------------------------------

    if window.preCompiled
      createWorldAndStartStepping()
    else
      addLogDiv()
  .then ->
    eval.call window, compileFGCode window["Mixin_coffeSource"], true
  .then ->
    eval.call window, compileFGCode window["Class_coffeSource"], true
  .then ->
    loadJSFilesWithCoffeescriptSources()
  .then ->
    if window.preCompiled
      (loadSourcesAndPotentiallyCompileThem true).then ->
        window.stillLoadingSources = false
        if AutomatorRecorderAndPlayer?
          AutomatorRecorderAndPlayer.testsManifest = testsManifest
          AutomatorRecorderAndPlayer.testsAssetsManifest = testsAssetsManifest
        startupActions = getParameterByName "startupActions"
        console.log "startupActions: " + startupActions
        if startupActions?
          world.nextStartupAction()
    else
      (loadSourcesAndPotentiallyCompileThem false).then ->
        window.stillLoadingSources = false
        if AutomatorRecorderAndPlayer?
          AutomatorRecorderAndPlayer.testsManifest = testsManifest
          AutomatorRecorderAndPlayer.testsAssetsManifest = testsAssetsManifest
      .then ->
        createWorldAndStartStepping()
        startupActions = getParameterByName "startupActions"
        console.log "startupActions: " + startupActions
        if startupActions?
          world.nextStartupAction()

  


# The whole idea here is that
#    a needs b,c,d
#    b needs c
# forms a tree. (a root with b,c,d as children,
# and b's node has C as child)
# You basically find out the correct inclusion order
# by just doing a depth-first visit of that tree
# and collecting the nodes in reverse "coming back" from
# the leafs.
visit = (dependencies, theClass, inclusion_order) ->
  if dependencies[theClass]?
    for key in dependencies[theClass]
      if key in inclusion_order
        break
      visit dependencies, key, inclusion_order
  inclusion_order.push theClass

# we still need to evaluate the classes in the
# correct order. We do that by looking at the sources
# and some hints in the sources.
generate_inclusion_order = (dependencies) ->
  """
  Returns a list of the coffee files. The list is ordered in such a way  that
  the dependencies between the files are respected.
  """
  inclusion_order = []


  for key of dependencies
    if key == 'length' or !dependencies.hasOwnProperty key
      continue
    #value = dependencies[key]
    #console.log value
    visit dependencies, key, inclusion_order
  console.log "inclusion_order: " + inclusion_order
  return inclusion_order


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
# the gitter because there is no running world,
# so we can just wait each compilation step on
# a timer.
waitNextTurn = ->
  (args...) ->
    if window.preCompiled
      prms = new Promise (resolve, reject) ->
        window.srcLoadsSteps.push resolve
    else
      # see https://gist.github.com/joepie91/2664c85a744e6bd0629c
      prms = new Promise (resolve, reject) ->
        setTimeout () ->
          resolve args...
        , 1
    return prms

generateInclusionOrder = ->
  # find out the dependencies looking at each class'
  # source code and hints in it.
  dependencies = []
  REQUIRES = ///\sREQUIRES\s*(\w+)///
  EXTENDS = ///\sextends\s*(\w+)///
  DEPENDS = ///\s\w+:\s*new\s*(\w+)///
  IS_CLASS = ///\s*class\s+(\w+)///
  TRIPLE_QUOTES = ///'''///
  #debugger
  for eachFile in sourcesManifests

    eachFile = eachFile.replace "_coffeSource",""
    if eachFile == "Class" then continue
    if eachFile == "Mixin" then continue
    console.log eachFile + " - "
    dependencies[eachFile] = []
    lines = window[eachFile + "_coffeSource"].split '\n'
    i = 0
    while i < lines.length
      #console.log lines[i]

      matches = lines[i].match EXTENDS
      if matches?
        #console.log matches
        dependencies[eachFile].push matches[1]
        console.log eachFile + " extends " + matches[1]

      matches = lines[i].match REQUIRES
      if matches?
        #console.log matches
        dependencies[eachFile].push matches[1]
        console.log eachFile + " requires " + matches[1]

      matches = lines[i].match DEPENDS
      if matches?
        #console.log matches
        dependencies[eachFile].push matches[1]
        console.log eachFile + " has class init in instance variable " + matches[1]

      i++
  inclusion_order = generate_inclusion_order dependencies

loadSourcesAndPotentiallyCompileThem = (justLoadSources) ->

  emptyLogDiv()


  console.log "--------------------------------"
  inclusion_order = generateInclusionOrder()


  # We remove these Coffeescript helper functions from
  # all compiled code, so make sure that they are available.
  # It's rather crude to add them to the global scope but
  # it works.
  window.hasProp = {}.hasOwnProperty
  window.indexOf = [].indexOf
  window.slice = [].slice

  # to return a function where the argument is bound
  createCompileSourceFunction = (fileName, justLoadSources2) ->
    return -> compileSource fileName, justLoadSources2


  # start of the promise. It will "trigger" the chain
  # in 1 ms
  promiseChain = new Promise (resolve) ->
    setTimeout ->
      resolve()
    , 1

  # chain two steps for each file, one to compile the file
  # and one to wait for the next turn
  for eachFile in inclusion_order
    if eachFile == "Class" or eachFile == "Mixin" or eachFile == "globalFunctions"
      continue
    compileEachFileFunction = createCompileSourceFunction eachFile, justLoadSources
    promiseChain = promiseChain.then compileEachFileFunction
    promiseChain = promiseChain.then waitNextTurn()

  # final step, proceed with the boot sequence
  promiseChain.then ->

    if window.location.href.contains "generatePreCompiled"
      zip = new JSZip
      zip.file 'pre-compiled.js', "window.preCompiled = true;\n\n" + window.JSSourcesContainer.content
      zip.generateAsync(type: 'blob').then (content) ->
        saveAs content, 'pre-compiled.zip'
        return


    removeLogDiv()

  return promiseChain


compileSource = (fileName, justLoadSources) ->

  if !window.CS1CompiledClasses?
    window.CS1CompiledClasses = []

  if !window.JSSourcesContainer?
    window.JSSourcesContainer = {content: ""}

  fileContents = window[fileName + "_coffeSource"]

  t0 = performance.now()

  console.log "checking whether " + fileName + " is already in the system "

  # loading via Class means that we register all the source
  # code and manually create any extensions
  if /^class[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m.test fileContents
    if justLoadSources
      morphClass = new Class fileContents, false, false
    else
      morphClass = new Class fileContents, true, true
  # Loaded Mixins here:
  else if /^  onceAddedClassProperties:/m.test fileContents
    if justLoadSources
      new Mixin fileContents, false, false
    else
      new Mixin fileContents, true, true

  console.log "compiling and evalling " + fileName + " from souce code"
  emptyLogDiv()
  addLineToLogDiv "compiling and evalling " + fileName

  t1 = performance.now()
  console.log "loadSourcesAndPotentiallyCompileThem call time: " + (t1 - t0) + " milliseconds."


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
  if window.location.href.contains "worldWithSystemTestHarness"
    # the user is here to record a system test so
    # don't fill entire page cause there are some
    # controls on the right side of the canvas
    world = new WorldMorph worldCanvas, false
  else
    world = new WorldMorph worldCanvas, true
  world.isDevMode = true
  # shim layer with setTimeout fallback
  window.requestAnimFrame = do ->
    window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback) ->
      window.setTimeout callback, 1000 / 60
      return
  # usage: 
  # instead of setInterval(render, 16) ....
  (animloop = ->
    requestAnimFrame animloop
    world.doOneCycle()
    return
  )()

  # in case we want to set up the page
  # for the System Tests, then add a panel
  # to the right where helper commands can be
  # clicked.
  if window.location.href.contains "worldWithSystemTestHarness"
    if SystemTestsControlPanelUpdater?
      new SystemTestsControlPanelUpdater

  window.menusHelper = new MenusHelper()
  world.boot()

# a helper function to use Promise style
# instead of callback style when creating
# an Image from the image data
createImageFromImageData = (theImageData) ->
  return new Promise (resolve, reject) ->
    img = new Image()
    img.onload = ->
        resolve(img)
    img.onerror = ->
        reject(img)
    img.src = theImageData

# these two are to build classes
extend = (child, parent) ->
  ctor = ->
    @constructor = child
    return

  for own key of parent
    child[key] = parent[key]
  ctor.prototype = parent.prototype
  child.prototype = new ctor()
  child.__super__ = parent.prototype
  return child

getRandomInt = (min, max) ->
  min = Math.ceil min
  max = Math.floor max
  Math.floor Math.random() * (max - min) + min
