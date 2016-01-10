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


HTMLCanvasElement::deepCopy = (doSerialize, objOriginalsClonedAlready, objectClones, allMorphsInStructure) ->
  haveIBeenCopiedAlready = objOriginalsClonedAlready.indexOf(@)
  if  haveIBeenCopiedAlready >= 0
    if doSerialize
      return "$" + haveIBeenCopiedAlready
    else
      return objectClones[haveIBeenCopiedAlready]

  positionInObjClonesArray = objOriginalsClonedAlready.length
  objOriginalsClonedAlready.push @
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
  objectIBelongTo[myPropertyName] = @canvas.getContext "2d"

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
        cloneOfMe[i] = null
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

# from https://gist.github.com/vjt/827679
String::camelize = ->
  @replace /(?:^|[-])(\w)/g, (_, c) ->
    if c then c.toUpperCase() else ''

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
    return null

## -------------------------------------------------------
# These two methods are for mixins
## -------------------------------------------------------
# adds klass properties
# these are added to the constructor
Object::augmentWith = (obj) ->
  for key, value of obj when key not in MixedClassKeywords
    @[key] = value
  obj.onceAddedClassProperties?.apply @
  this

# adds instance properties
# these are added to the prototype
Object::addInstanceProperties= (obj) ->
  for key, value of obj when key not in MixedClassKeywords
    # Assign properties to the prototype
    @::[key] = value
  obj.included?.apply @
  this
##--------------- end of mixins methods -------------------


arrayShallowCopy = (anArray) ->
  anArray.concat()

arrayShallowCopyAndReverse = (anArray) ->
  anArray.concat().reverse()

# This is used for testing purposes, we hash the
# data URL of a canvas object so to get a fingerprint
# of the image data, and compare it with "OK" pre-recorded
# values.
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
    null

noOperation = ->
    null

isFunction = (functionToCheck) ->
  typeof(functionToCheck) is "function"

localize = (string) ->
  # override this function with custom localizations
  string

isNil = (thing) ->
  thing is `undefined` or thing is null

contains = (list, element) ->
  # answer true if element is a member of list
  list.some (any) ->
    any is element

detect = (list, predicate) ->
  # answer the first element of list for which predicate evaluates
  # true, otherwise answer null
  for element in list
    return element  if predicate.call null, element
  null

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


getBlurredShadowSupport = ->
  # check for Chrome issue 90001
  # http://code.google.com/p/chromium/issues/detail?id=90001
  source = document.createElement "canvas"
  source.width = 10
  source.height = 10
  ctx = source.getContext "2d"
  ctx.fillStyle = "rgb(255, 0, 0)"
  ctx.beginPath()
  ctx.arc 5, 5, 5, 0, Math.PI * 2, true
  ctx.closePath()
  ctx.fill()
  target = document.createElement "canvas"
  target.width = 10
  target.height = 10
  ctx = target.getContext "2d"
  ctx.shadowBlur = 10
  ctx.shadowColor = "rgba(0, 0, 255, 1)"
  ctx.drawImage source, 0, 0
  (if ctx.getImageData(0, 0, 1, 1).data[3] then true else false)

getDocumentPositionOf = (aDOMelement) ->
  # answer the absolute coordinates of a DOM element in the document
  if aDOMelement is null
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

aSourceHasBeenLoaded = ->
  howManySourcesLoaded++
  if howManySourcesLoaded == sourcesManifests.length
    continueBooting()



loadAllSources = ->
  for eachClass in sourcesManifests

    script = document.createElement "script"
    script.src = "js/sourceCode/" + eachClass + ".js"

    script.onload = =>
      aSourceHasBeenLoaded()

    document.head.appendChild script

aTestScriptHasBeenLoaded = ->
  howManyTestManifestsLoaded++
  if howManyTestManifestsLoaded == 2
    continueBooting2()


loadAllTestManifests = ->
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


boot = ->
  loadAllSources()


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

  for eachClass in inclusion_order
    console.log "checking whether " + eachClass + " is already in the system "
    if !window[eachClass]?
      if eachClass + "_coffeSource" in sourcesManifests
        console.log "loading " + eachClass + " from souce code"
        # give life to the loaded and translated coffeescript klass now!
        eval.call window, CoffeeScript.compile window[eachClass + "_coffeSource"],{"bare":true}

  loadAllTestManifests()


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
  if window.location.href.indexOf('worldWithSystemTestHarness') > -1
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
  if window.location.href.indexOf('runAllTests') > -1
    world.runAllSystemTests()
  # in case we want to set up the page
  # for the System Tests, then add a panel
  # to the right where helper commands can be
  # clicked.
  if window.location.href.indexOf('worldWithSystemTestHarness') > -1
    if SystemTestsControlPanelUpdater != null
      new SystemTestsControlPanelUpdater
  world.boot()



