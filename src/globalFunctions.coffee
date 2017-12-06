# Global Functions ////////////////////////////////////////////////////


# This is used for mixins: MixedClassKeywords is used
# to protect some methods so the are not copied to object,
# because they have special meaning
# (this comment from a stackOverflow answer from clyde
# here: http://stackoverflow.com/a/8728164/1318347 )
MixedClassKeywords = ['onceAddedClassProperties', 'included']

# this is so we can create objects from the object klass name 
# (for the deserialization process)
namedClasses = {}

# we use "nil" everywhere instead of "null"
# and this "nil" we use is really "undefined"
# The reason is the following: Coffeescript2 has the
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
# adds klass properties
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
    # we can't tell which klass this will be mixed in in advance,
    # i.e. at compile time it doesn't
    # belong to a klass, so at compile time it doesn't know which klass
    # it will be injected in.
    # So that's why _at time of injection_ we need
    # to store the klass it's injected in in a special
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
    return (
      x: 0
      y: 0
    )
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

howManySourcesLoaded = 0
howManyTestManifestsLoaded = 0
howManySourcesCompiledAndEvalled = 0

aSourceHasBeenLoaded = ->
  howManySourcesLoaded++
  # the -1 here is due to the fact that we load
  # "klass" separately in advance, so there is no
  # need to wait for it here.
  if howManySourcesLoaded == sourcesManifests.length - 1
    loadingLogDiv = document.getElementById 'loadingLog'
    loadingLogDiv.innerHTML = ""
    continueBooting()



loadAllSources = ->
  for eachClass in sourcesManifests

    if eachClass == "Klass_coffeSource" then continue
    script = document.createElement "script"
    script.src = "js/sourceCode/" + eachClass + ".js"

    script.onload = ->
      loadingLogDiv = document.getElementById 'loadingLog'
      loadingLogDiv.innerHTML += "loading " + this.src + "</br>"
      console.log "loading " + this.src
      aSourceHasBeenLoaded()

    document.head.appendChild script

aTestScriptHasBeenLoaded = ->
  howManyTestManifestsLoaded++
  if howManyTestManifestsLoaded == 2
    continueBooting2()

loadTestManifests = ->
  script = document.createElement "script"
  script.src = "js/tests/testsManifest.js"
  script.onload = =>
    aTestScriptHasBeenLoaded()
  document.head.appendChild script

  script2 = document.createElement "script"
  script2.src = "js/tests/testsAssetsManifest.js"
  script2.onload = =>
    aTestScriptHasBeenLoaded()
  document.head.appendChild script2

compileFGCode = (codeSource, bare, version = 1) ->
  t0 = performance.now()
  try
    switch version
      when 1
        compiled = CoffeeScript.compile codeSource,{"bare":bare}
      when 2
        compiled = CoffeeScript2.compile codeSource,{"bare":bare}
  catch err
    errorMessage =  "error in compiling:\n"
    errorMessage += codeSource + "\n"
    errorMessage += "error:\n"
    errorMessage += err + "\n"
    world.errorConsole?.popUpWithError errorMessage

  t1 = performance.now()
  console.log "compileFGCode time: " + (t1 - t0) + " milliseconds."

  return compiled

loadKlass = ->

  script = document.createElement "script"
  script.src = "js/sourceCode/Klass_coffeSource.js"

  script.onload = ->
    # give life to the loaded and translated coffeescript klass now!
    console.log "compiling and evalling Klass from souce code"
    eval.call window, compileFGCode window["Klass_coffeSource"], true, 2
    loadAllSources()


  document.head.appendChild script


boot = ->
  loadKlass()


# The whole idea here is that
#    a needs b,c,d
#    b needs c
# forms a tree. (a root with b,c,d as children,
# and b's node has C as child)
# You basically find out the correct inclusion order
# by just doing a depth-first visit of that tree
# and collecting the nodes in reverse "coming back" from
# the leafs.
visit = (dependencies, klass, inclusion_order) ->
  if dependencies[klass]?
    for key in dependencies[klass]
      if key in inclusion_order
        break
      visit dependencies, key, inclusion_order
  inclusion_order.push klass

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

continueBooting = ->

  console.log "--------------------------------"
  # find out the dependencies looking at each klass'
  # source code and hints in it.
  dependencies = []
  REQUIRES = ///\sREQUIRES\s*(\w+)///
  EXTENDS = ///\sextends\s*(\w+)///
  DEPENDS = ///\s\w+:\s*new\s*(\w+)///
  IS_CLASS = ///\s*class\s+(\w+)///
  TRIPLE_QUOTES = ///'''///
  #debugger
  for eachClass in sourcesManifests

    eachClass = eachClass.replace "_coffeSource",""
    if eachClass == "Klass" then continue
    #if namedClasses.hasOwnProperty eachClass
    console.log eachClass + " - "
    dependencies[eachClass] = []
    lines = window[eachClass + "_coffeSource"].split '\n'
    i = 0
    while i < lines.length
      #console.log lines[i]

      matches = lines[i].match EXTENDS
      if matches?
        #console.log matches
        dependencies[eachClass].push matches[1]
        console.log eachClass + " extends " + matches[1]

      matches = lines[i].match REQUIRES
      if matches?
        #console.log matches
        dependencies[eachClass].push matches[1]
        console.log eachClass + " requires " + matches[1]

      matches = lines[i].match DEPENDS
      if matches?
        #console.log matches
        dependencies[eachClass].push matches[1]
        console.log eachClass + " has klass init in instance variable " + matches[1]

      i++
  inclusion_order = generate_inclusion_order dependencies
  console.log "--------------------------------"
  compileAndEvalAllSrcFiles 0, inclusion_order


compileAndEvalAllSrcFiles = (srcNumber, inclusion_order) ->

  if !window.CS1CompiledClasses?
    window.CS1CompiledClasses = []

  if srcNumber == inclusion_order.length

    # remove the log div
    loadingLogDiv = document.getElementById 'loadingLog'
    loadingLogDiv.parentElement.removeChild loadingLogDiv

    loadTestManifests()
    return

  t0 = performance.now()

  eachClass = inclusion_order[srcNumber]
  console.log "checking whether " + eachClass + " is already in the system "

  # loading via Klass means that we register all the source
  # code and manually create any extensions
  if eachClass in [
   "MorphicNode",
   "Morph",
   # --------
   "AnalogClockMorph",
   "BlinkerMorph",
   "BouncerMorph",
   "BoxMorph",
   "CircleBoxMorph",
   "CollapsedStateIconMorph",
   "ColorPaletteMorph",
   "ColorPickerMorph",
   "DestroyIconMorph",
   "EmptyButtonMorph",
   "FloraIconMorph",
   "FrameMorph",
   "HandMorph",
   "HandleMorph",
   "HeartIconMorph",
   "IconMorph",
   "LayoutElementAdderOrDropletMorph",
   "LayoutSpacerMorph",
   "MenuMorph",
   "PenMorph",
   "RadioButtonsHolderMorph",
   "ReactiveValuesTestsRectangleMorph",
   "RectangleMorph",
   "ScooterIconMorph",
   "ScratchAreaIconMorph",
   "SpeechBubbleMorph",
   "StackElementsSizeAdjustingMorph",
   "StringMorph",
   "StringMorph2",
   "StringMorph3",
   "SwitchButtonMorph",
   "TriggerMorph",
   "UncollapsedStateIconMorph",
   "UnderCarpetIconMorph",
   # --------
   "TextMorph",
   "TextMorph2",
   # --------
   "AngledArrowUpLeftIconMorph",
   "BrushIconMorph",
   "CanvasMorph",
   "CaretMorph",
   "WindowMorph",
   "InspectorMorph2",
   "ClassInspectorMorph",
   "CloseIconButtonMorph",
   "SimpleRectangularButtonMorph",
   "CodeInjectingSimpleRectangularButtonMorph",
   "EditableMarkMorph",
   "EraserIconMorph",
   "ErrorsLogViewerMorph",
   "WorldMorph",
   "FizzytilesCodeMorph",
   "FridgeMagnetsCanvasMorph",
   "FridgeMagnetsMorph",
   "FridgeMorph",
   "GrayPaletteMorph",
   "HideIconButtonMorph",
   "HighlighterMorph",
   "InspectorMorph",
   "ScrollFrameMorph",
   "ListMorph",
   "MagnetMorph",
   "MenuItemMorph",
   "MorphsListMorph",
   "MouseSensorMorph",
   "OverlayCanvasMorph",
   "Pencil2IconMorph",
   "PencilIconMorph",
   "PointerMorph",
   "PromptMorph",
   "ReconfigurablePaintMorph",
   "SimpleButtonMorph",
   "SliderButtonMorph",
   "SliderMorph",
   "SliderMorph2",
   "StringFieldMorph",
   "TextPromptMorph",
   "ToggleButtonMorph",
   "ToothpasteIconMorph",
   "UnderTheCarpetMorph",
   "UnderTheCarpetOpenerMorph",
   "WorkspaceMorph",
   # --------
   "AlignmentSpecHorizontal",
   "AlignmentSpecVertical",
   "LayoutSpec",
   #"Color",
   "Appearance",
   "ProfilerData",
   "Arg",
   "Args",
   "AutomatorCommand",
   "AutomatorCommandCheckNumberOfItemsInMenu",
   "AutomatorCommandCheckStringsOfItemsInMenuOrderImportant",
   "AutomatorCommandCheckStringsOfItemsInMenuOrderUnimportant",
   "AutomatorCommandCopy",
   "AutomatorCommandCut",
   "AutomatorCommandDoNothing",
   "AutomatorCommandDrop",
   "AutomatorCommandEvaluateString",
   "AutomatorCommandGrab",
   "AutomatorCommandKeyDown",
   "AutomatorCommandKeyPress",
   "AutomatorCommandKeyUp",
   "AutomatorCommandLeftOrRightClickOnMenuItem",
   "AutomatorCommandMouseButtonChange",
   "AutomatorCommandMouseClick",
   "AutomatorCommandMouseDoubleClick",
   "AutomatorCommandMouseMove",
   "AutomatorCommandMouseTripleClick",
   "AutomatorCommandOpenContextMenu",
   "AutomatorCommandPaste",
   "AutomatorCommandResetWorld",
   "AutomatorCommandScreenshot",
   "AutomatorCommandShowComment",
   "AutomatorCommandTurnOffAlignmentOfMorphIDsMechanism",
   "AutomatorCommandTurnOffAnimationsPacingControl",
   "AutomatorCommandTurnOffHidingOfMorphsContentExtractInLabels",
   "AutomatorCommandTurnOffHidingOfMorphsGeometryInfoInLabels",
   "AutomatorCommandTurnOffHidingOfMorphsNumberIDInLabels",
   "AutomatorCommandTurnOnAlignmentOfMorphIDsMechanism",
   "AutomatorCommandTurnOnAnimationsPacingControl",
   "AutomatorCommandTurnOnHidingOfMorphsContentExtractInLabels",
   "AutomatorCommandTurnOnHidingOfMorphsGeometryInfoInLabels",
   "AutomatorCommandTurnOnHidingOfMorphsNumberIDInLabels",
   "HashCalculator",
   "SystemTestsReferenceImage",
   "SystemInfo",
   "SystemTestsSystemInfo",
   "AutomatorRecorderAndPlayer",
   "GroundVal",
   "BasicCalculatedValue",
   "BoxyAppearance",
   "BubblyAppearance",
   "RectangularAppearance",
   "CircleBoxyAppearance",
   #"CodePreprocessor",
   #"ColourLiterals",
   "DoubleLinkedList",
   "UpperRightTriangle",
   "UpperRightTriangleAnnotation",
   "FittingSpecText",
   "FittingSpecTextBoxFittingTextTightOrLoose",
   "FittingSpecTextBoxFittingTextWitchDimensionAdjusts",
   "FittingSpecTextInLargerBounds",
   "FittingSpecTextInSmallerBounds",
   "LRUCache",
   "PreferencesAndSettings",
   "ProfilingDataCollector",
   "SystemTestsControlPanelUpdater",
   #"LCLCodeCompiler",
   "IconAppearance",
   "LCLProgramRunner",
   "MenuAppearance",
   "MenuHeader",
   "MenusHelper",
   "PinType",
   "Pin",
   "Point",
   "ReactiveValuesTests",
   "Rectangle",
   "ShadowInfo",
   "UpperRightTriangleAppearance",
   # --------
   #"DeepCopierMixin",
   #"BackBufferMixin",
   #"HighlightableMixin",
   #"ControllerMixin",
   #"ContainerMixin",
   #"UpperRightInternalHaloMixin",
   ]
    morphKlass = new Klass(window[eachClass + "_coffeSource"])


  if !window[eachClass]?
    if eachClass + "_coffeSource" in sourcesManifests

      window.CS1CompiledClasses.push eachClass
      # CS1CompiledClasses.filter((each) => each.indexOf("Morph")!= -1).map((each) => console.log(each + "\n"))

      console.log "compiling and evalling " + eachClass + " from souce code"
      loadingLogDiv = document.getElementById 'loadingLog'
      loadingLogDiv.innerHTML = "compiling and evalling " + eachClass

      # give life to the loaded and translated coffeescript klass now!
      try
        compiled = compileFGCode window[eachClass + "_coffeSource"], true, 1
      catch err
        console.log "source:"
        console.log window[eachClass + "_coffeSource"]
        console.log "error:"
        console.log err

      eval.call window, compiled

  t1 = performance.now()
  console.log "compileAndEvalAllSrcFiles call time: " + (t1 - t0) + " milliseconds."


  setTimeout ( ->
    compileAndEvalAllSrcFiles srcNumber+1 , inclusion_order
  ), 1




world = {} # we make "world" global

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

continueBooting2 = ->
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
  # place the rAF *before* the render() to assure as close to 
  # 60fps with the setTimeout fallback.
  if window.location.href.contains "runAllTests"
    world.runAllSystemTests()
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

# these two are to build klasses
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
