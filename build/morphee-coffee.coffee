# Global Functions ////////////////////////////////////////////////////

# This is used for testing purposes, we hash the
# data URL of a canvas object so to get a fingerprint
# of the image data, and compare it with "OK" pre-recorded
# values.
# adapted from http://werxltd.com/wp/2010/05/13/javascript-implementation-of-javas-string-hashcode-method/

hashCode = (stringToBeHashed) ->
  hash = 0
  return hash  if stringToBeHashed.length is 0
  for i in [0...stringToBeHashed.length]
    char = stringToBeHashed.charCodeAt(i)
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
    return element  if predicate.call(null, element)
  null

sizeOf = (object) ->
  # answer the number of own properties
  size = 0
  key = undefined
  for key of object
    size += 1  if Object.prototype.hasOwnProperty.call(object, key)
  size

isString = (target) ->
  typeof target is "string" or target instanceof String

isObject = (target) ->
  target? and (typeof target is "object" or target instanceof Object)

radians = (degrees) ->
  degrees * Math.PI / 180

degrees = (radians) ->
  radians * 180 / Math.PI

fontHeight = (height) ->
  minHeight = Math.max(height, WorldMorph.MorphicPreferences.minimumFontHeight)
  minHeight * 1.2 # assuming 1/5 font size for ascenders

newCanvas = (extentPoint) ->
  # answer a new empty instance of Canvas, don't display anywhere
  ext = extentPoint or
    x: 0
    y: 0
  canvas = document.createElement("canvas")
  canvas.width = ext.x
  canvas.height = ext.y
  canvas

getMinimumFontHeight = ->
  # answer the height of the smallest font renderable in pixels
  str = "I"
  size = 50
  canvas = document.createElement("canvas")
  canvas.width = size
  canvas.height = size
  ctx = canvas.getContext("2d")
  ctx.font = "1px serif"
  maxX = ctx.measureText(str).width
  ctx.fillStyle = "black"
  ctx.textBaseline = "bottom"
  ctx.fillText str, 0, size
  for y in [0...size]
    for x in [0...maxX]
      data = ctx.getImageData(x, y, 1, 1)
      return size - y + 1  if data.data[3] isnt 0
  0


getBlurredShadowSupport = ->
  # check for Chrome issue 90001
  # http://code.google.com/p/chromium/issues/detail?id=90001
  source = document.createElement("canvas")
  source.width = 10
  source.height = 10
  ctx = source.getContext("2d")
  ctx.fillStyle = "rgb(255, 0, 0)"
  ctx.beginPath()
  ctx.arc 5, 5, 5, 0, Math.PI * 2, true
  ctx.closePath()
  ctx.fill()
  target = document.createElement("canvas")
  target.width = 10
  target.height = 10
  ctx = target.getContext("2d")
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
  while offsetParent isnt null
    pos.x += offsetParent.offsetLeft
    pos.y += offsetParent.offsetTop
    if offsetParent isnt document.body and offsetParent isnt document.documentElement
      pos.x -= offsetParent.scrollLeft
      pos.y -= offsetParent.scrollTop
    offsetParent = offsetParent.offsetParent
  pos

clone = (target) ->
  # answer a new instance of target's type
  if typeof target is "object"
    Clone = ->

    Clone:: = target
    return new Clone()
  target

copy = (target) ->
  # answer a shallow copy of target
  return target  if typeof target isnt "object"
  value = target.valueOf()
  return new target.constructor(value)  if target isnt value
  if target instanceof target.constructor and target.constructor isnt Object
    c = clone(target.constructor::)
    for property of target
      c[property] = target[property]  if target.hasOwnProperty(property)
  else
    c = {}
    for property of target
      c[property] = target[property]  unless c[property]
  c

class MorphicNode

  parent: null
  children: null

  constructor: (@parent = null, @children = []) ->
  
  
  # MorphicNode string representation: e.g. 'a MorphicNode[3]'
  toString: ->
    "a MorphicNode" + "[" + @children.length.toString() + "]"
  
  
  # MorphicNode accessing:
  addChild: (aMorphicNode) ->
    @children.push aMorphicNode
    aMorphicNode.parent = @
  
  addChildFirst: (aMorphicNode) ->
    @children.splice 0, null, aMorphicNode
    aMorphicNode.parent = @
  
  removeChild: (aMorphicNode) ->
    idx = @children.indexOf(aMorphicNode)
    @children.splice idx, 1  if idx isnt -1
  
  
  # MorphicNode functions:
  root: ->
    return @parent.root() if @parent?
    @
  
  # currently unused
  depth: ->
    return 0  unless @parent
    @parent.depth() + 1
  
  # Returns all the internal/terminal nodes in the subtree starting
  # at this node - including this node
  allChildren: ->
    result = [@] # includes myself
    @children.forEach (child) ->
      result = result.concat(child.allChildren())
    result
  
  # A shorthand to run a function on all the internal/terminal nodes in the subtree
  # starting at this node - including this node.
  # Note that the function is run starting form the "bottom" leaf and the all the
  # way "up" to the current node.
  forAllChildren: (aFunction) ->
    if @children.length
      @children.forEach (child) ->
        child.forAllChildren aFunction
    aFunction.call null, @
  
  allLeafs: ->
    result = []
    @allChildren().forEach (element) ->
      result.push element  if !element.children.length
    #
    result
  
  # Return all "parent" nodes from this node up to the root (including both)
  allParents: ->
    # includes myself
    result = [@]
    result = result.concat(@parent.allParents())  if @parent?
    result
  
  # The direct children of the parent of this node. (current node not included)
  siblings: ->
    return []  unless @parent
    @parent.children.filter (child) =>
      child isnt @
  
  # returns the first parent (going up from this node) that is of a particular class
  # (includes this particular node)
  # This is a subcase of "parentThatIsAnyOf".
  parentThatIsA: (constructor) ->
    # including myself
    return @ if @ instanceof constructor
    return null  unless @parent
    @parent.parentThatIsA constructor
  
  # returns the first parent (going up from this node) that belongs to a set
  # of classes. (includes this particular node).
  parentThatIsAnyOf: (constructors) ->
    # including myself
    constructors.forEach (each) =>
      if @constructor is each
        return @
    #
    return null  unless @parent
    @parent.parentThatIsAnyOf constructors

  @coffeeScriptSourceOfThisClass: '''
class MorphicNode

  parent: null
  children: null

  constructor: (@parent = null, @children = []) ->
  
  
  # MorphicNode string representation: e.g. 'a MorphicNode[3]'
  toString: ->
    "a MorphicNode" + "[" + @children.length.toString() + "]"
  
  
  # MorphicNode accessing:
  addChild: (aMorphicNode) ->
    @children.push aMorphicNode
    aMorphicNode.parent = @
  
  addChildFirst: (aMorphicNode) ->
    @children.splice 0, null, aMorphicNode
    aMorphicNode.parent = @
  
  removeChild: (aMorphicNode) ->
    idx = @children.indexOf(aMorphicNode)
    @children.splice idx, 1  if idx isnt -1
  
  
  # MorphicNode functions:
  root: ->
    return @parent.root() if @parent?
    @
  
  # currently unused
  depth: ->
    return 0  unless @parent
    @parent.depth() + 1
  
  # Returns all the internal/terminal nodes in the subtree starting
  # at this node - including this node
  allChildren: ->
    result = [@] # includes myself
    @children.forEach (child) ->
      result = result.concat(child.allChildren())
    result
  
  # A shorthand to run a function on all the internal/terminal nodes in the subtree
  # starting at this node - including this node.
  # Note that the function is run starting form the "bottom" leaf and the all the
  # way "up" to the current node.
  forAllChildren: (aFunction) ->
    if @children.length
      @children.forEach (child) ->
        child.forAllChildren aFunction
    aFunction.call null, @
  
  allLeafs: ->
    result = []
    @allChildren().forEach (element) ->
      result.push element  if !element.children.length
    #
    result
  
  # Return all "parent" nodes from this node up to the root (including both)
  allParents: ->
    # includes myself
    result = [@]
    result = result.concat(@parent.allParents())  if @parent?
    result
  
  # The direct children of the parent of this node. (current node not included)
  siblings: ->
    return []  unless @parent
    @parent.children.filter (child) =>
      child isnt @
  
  # returns the first parent (going up from this node) that is of a particular class
  # (includes this particular node)
  # This is a subcase of "parentThatIsAnyOf".
  parentThatIsA: (constructor) ->
    # including myself
    return @ if @ instanceof constructor
    return null  unless @parent
    @parent.parentThatIsA constructor
  
  # returns the first parent (going up from this node) that belongs to a set
  # of classes. (includes this particular node).
  parentThatIsAnyOf: (constructors) ->
    # including myself
    constructors.forEach (each) =>
      if @constructor is each
        return @
    #
    return null  unless @parent
    @parent.parentThatIsAnyOf constructors
  '''
# Morph //////////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class Morph extends MorphicNode
  
  # Just some tests here ////////////////////
  propertyUpTheChain: [1,2,3]
  morphMethod: ->
    3.14
  @morphStaticMethod: ->
    3.14
  # End of tests here ////////////////////

  isMorph: true
  bounds: null
  color: null
  texture: null # optional url of a fill-image
  cachedTexture: null # internal cache of actual bg image
  lastTime: null
  alpha: 1
  isVisible: true
  isDraggable: false
  isTemplate: false
  acceptsDrops: false
  noticesTransparentClick: false
  fps: 0
  customContextMenu: null
  trackChanges: true
  shadowBlur: 4
  # note that image contains only the CURRENT morph, not the composition of this
  # morph with all of the submorphs. I.e. for an inspector, this will only
  # contain the background of the window pane. Not any of its contents.
  # for the worldMorph, this only contains the background
  image: null
  onNextStep: null # optional function to be run once. Not currently used in Zombie Kernel
  
  constructor: () ->
    super()
    # [TODO] why is there this strange non-zero default bound?
    @bounds = new Rectangle(0, 0, 50, 40)
    @color = new Color(80, 80, 80)
    @updateRendering()
    @lastTime = Date.now()
  
  #
  #    damage list housekeeping
  #
  #	the trackChanges property of the Morph prototype is a Boolean switch
  #	that determines whether the World's damage list ('broken' rectangles)
  #	tracks changes. By default the switch is always on. If set to false
  #	changes are not stored. This can be very useful for housekeeping of
  #	the damage list in situations where a large number of (sub-) morphs
  #	are changed more or less at once. Instead of keeping track of every
  #	single submorph's changes tremendous performance improvements can be
  #	achieved by setting the trackChanges flag to false before propagating
  #	the layout changes, setting it to true again and then storing the full
  #	bounds of the surrounding morph. An an example refer to the
  #
  #		fixLayout()
  #		
  #	method of InspectorMorph, or the
  #	
  #		startLayout()
  #		endLayout()
  #
  #	methods of SyntaxElementMorph in the Snap application.
  #
  
  
  # Morph string representation: e.g. 'a Morph 2 [20@45 | 130@250]'
  toString: ->
    "a " +
      (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0]) +
      " " +
      @children.length.toString() +
      " " +
      @bounds
  
  
  # Morph deleting:
  destroy: ->
    if @parent isnt null
      @fullChanged()
      @parent.removeChild @
  
  destroyAll: ->
    # this is a typical case: we need to make a copy of the children
    # array first pecause we are iterating over an array that changes
    # its values (and length) while we are iterating on it.
    childrenCopy = @children.filter (x) -> true
    childrenCopy.forEach (child) =>
      child.destroy()
    
  # Morph stepping:
  runChildrensStepFunction: ->
    # step is the function that this Morph wants to run at each step.
    # If the Morph wants to do nothing and let no-one of the children do nothing,
    # then step is set to null.
    # If the morph wants to do nothing but the children might want to do something,
    # then step is set to the function that does nothing (i.e. a function noOperation that
    # only returns null) 
    return null  unless @step

    # for objects where @fps is defined, check which ones are due to be stepped
    # and which ones want to wait. 
    elapsed = WorldMorph.currentTime - @lastTime
    if @fps > 0
      timeRemainingToWaitedFrame = (1000 / @fps) - elapsed
    else
      timeRemainingToWaitedFrame = 0
    
    # Question: why 1 here below?
    if timeRemainingToWaitedFrame < 1
      @lastTime = WorldMorph.currentTime
      if @onNextStep
        nxt = @onNextStep
        @onNextStep = null
        nxt.call(@)
      @step()
      @children.forEach (child) ->
        child.runChildrensStepFunction()

  nextSteps: (arrayOfFunctions) ->
    lst = arrayOfFunctions or []
    nxt = lst.shift()
    if nxt
      @onNextStep = =>
        nxt.call @
        @nextSteps lst  
  
  # leaving this function as step means that the morph want to do nothing
  # but the children *are* traversed and their step function is invoked.
  # If a Morph wants to do nothing and wants to prevent the children to be
  # traversed, then this function should be set to null.
  step: noOperation
  
  
  # Morph accessing - geometry getting:
  left: ->
    @bounds.left()
  
  right: ->
    @bounds.right()
  
  top: ->
    @bounds.top()
  
  bottom: ->
    @bounds.bottom()
  
  center: ->
    @bounds.center()
  
  bottomCenter: ->
    @bounds.bottomCenter()
  
  bottomLeft: ->
    @bounds.bottomLeft()
  
  bottomRight: ->
    @bounds.bottomRight()
  
  boundingBox: ->
    @bounds
  
  corners: ->
    @bounds.corners()
  
  leftCenter: ->
    @bounds.leftCenter()
  
  rightCenter: ->
    @bounds.rightCenter()
  
  topCenter: ->
    @bounds.topCenter()
  
  topLeft: ->
    @bounds.topLeft()
  
  topRight: ->
    @bounds.topRight()
  
  position: ->
    @bounds.origin
  
  extent: ->
    @bounds.extent()
  
  width: ->
    @bounds.width()
  
  height: ->
    @bounds.height()
  
  boundsIncludingChildren: ->
    result = @bounds
    @children.forEach (child) ->
      result = result.merge(child.boundsIncludingChildren())  if child.isVisible
    #
    result
  
  boundsIncludingChildrenNoShadow: ->
    # answer my full bounds but ignore any shadow
    result = @bounds
    @children.forEach (child) ->
      if (child not instanceof ShadowMorph) and (child.isVisible)
        result = result.merge(child.boundsIncludingChildren())
    #
    result
  
  visibleBounds: ->
    # answer which part of me is not clipped by a Frame
    visible = @bounds
    frames = @allParents().filter((p) ->
      p instanceof FrameMorph
    )
    frames.forEach (f) ->
      visible = visible.intersect(f.bounds)
    #
    visible
  
  
  # Morph accessing - simple changes:
  moveBy: (delta) ->
    # question: why is changed() called two times?
    # question: can't we use silentMoveBy?
    @changed()
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.moveBy delta
    #
    @changed()
  
  silentMoveBy: (delta) ->
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.silentMoveBy delta
  
  
  setPosition: (aPoint) ->
    delta = aPoint.subtract(@topLeft())
    @moveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  silentSetPosition: (aPoint) ->
    delta = aPoint.subtract(@topLeft())
    @silentMoveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  setLeft: (x) ->
    @setPosition new Point(x, @top())
  
  setRight: (x) ->
    @setPosition new Point(x - @width(), @top())
  
  setTop: (y) ->
    @setPosition new Point(@left(), y)
  
  setBottom: (y) ->
    @setPosition new Point(@left(), y - @height())
  
  setCenter: (aPoint) ->
    @setPosition aPoint.subtract(@extent().floorDivideBy(2))
  
  setFullCenter: (aPoint) ->
    @setPosition aPoint.subtract(@boundsIncludingChildren().extent().floorDivideBy(2))
  
  # make sure I am completely within another Morph's bounds
  keepWithin: (aMorph) ->
    leftOff = @boundsIncludingChildren().left() - aMorph.left()
    @moveBy new Point(-leftOff, 0)  if leftOff < 0
    rightOff = @boundsIncludingChildren().right() - aMorph.right()
    @moveBy new Point(-rightOff, 0)  if rightOff > 0
    topOff = @boundsIncludingChildren().top() - aMorph.top()
    @moveBy new Point(0, -topOff)  if topOff < 0
    bottomOff = @boundsIncludingChildren().bottom() - aMorph.bottom()
    @moveBy new Point(0, -bottomOff)  if bottomOff > 0
  
  
  # Morph accessing - dimensional changes requiring a complete redraw
  setExtent: (aPoint) ->
    unless aPoint.eq(@extent())
      # question: why two "changed" invocations?
      @changed()
      @silentSetExtent aPoint
      @changed()
      @updateRendering()
  
  silentSetExtent: (aPoint) ->
    ext = aPoint.round()
    newWidth = Math.max(ext.x, 0)
    newHeight = Math.max(ext.y, 0)
    @bounds.corner = new Point(@bounds.origin.x + newWidth, @bounds.origin.y + newHeight)
  
  setWidth: (width) ->
    @setExtent new Point(width or 0, @height())
  
  silentSetWidth: (width) ->
    # do not updateRendering() just yet
    w = Math.max(Math.round(width or 0), 0)
    @bounds.corner = new Point(@bounds.origin.x + w, @bounds.corner.y)
  
  setHeight: (height) ->
    @setExtent new Point(@width(), height or 0)
  
  silentSetHeight: (height) ->
    # do not updateRendering() just yet
    h = Math.max(Math.round(height or 0), 0)
    @bounds.corner = new Point(@bounds.corner.x, @bounds.origin.y + h)
  
  setColor: (aColor) ->
    if aColor
      unless @color.eq(aColor)
        @color = aColor
        @changed()
        @updateRendering()
  
  
  # Morph displaying ###########################################################

  # There are three fundamental methods for rendering and displaying anything.
  # * updateRendering: this one creates/updates the local canvas of this morph only
  #   i.e. not the children
  # * blit: takes the local canvas and blits it to a specific area in a passed
  #   canvas. The local canvas doesn't contain any rendering of the children of
  #   this morph.
  # * recursivelyBlit: recursively draws all the local canvas of this morph and all
  #   its children into a specific area of a passed canvas.

  updateRendering: ->
    # initialize my surface property
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    context.fillStyle = @color.toString()
    context.fillRect 0, 0, @width(), @height()
    if @cachedTexture
      @drawCachedTexture()
    else @drawTexture @texture  if @texture
  
  drawTexture: (url) ->
    @cachedTexture = new Image()
    @cachedTexture.onload = =>
      @drawCachedTexture()
    #
    @cachedTexture.src = @texture = url # make absolute
  
  # tiles the texture
  drawCachedTexture: ->
    bg = @cachedTexture
    cols = Math.floor(@image.width / bg.width)
    lines = Math.floor(@image.height / bg.height)
    context = @image.getContext("2d")
    for y in [0..lines]
      for x in [0..cols]
        context.drawImage bg, Math.round(x * bg.width), Math.round(y * bg.height)
    @changed()
  
  
  #
  #Morph.prototype.drawCachedTexture = function () {
  #    var context = this.image.getContext('2d'),
  #        pattern = context.createPattern(this.cachedTexture, 'repeat');
  #	context.fillStyle = pattern;
  #    context.fillRect(0, 0, this.image.width, this.image.height);
  #    this.changed();
  #};
  #
  
  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by recursivelyBlit, which
  # eventually invokes blit.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  blit: (aCanvas, clippingRectangle = @bounds) ->
    return null  unless @isVisible
    area = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if area.isNotEmpty()
      delta = @position().neg()
      src = area.copy().translateBy(delta).round()
      context = aCanvas.getContext("2d")
      context.globalAlpha = @alpha
      sl = src.left()
      st = src.top()
      al = area.left()
      at = area.top()
      w = Math.min(src.width(), @image.width - sl)
      h = Math.min(src.height(), @image.height - st)
      return null  if w < 1 or h < 1

      context.drawImage @image,
        Math.round(sl),
        Math.round(st),
        Math.round(w),
        Math.round(h),
        Math.round(al),
        Math.round(at),
        Math.round(w),
        Math.round(h)

      if WorldMorph.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)
        context.globalAlpha = 0.5
        context.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        context.fillRect(Math.round(al),Math.round(at),Math.round(w),Math.round(h));
  
  
  # "for debugging purposes:"
  #
  #		try {
  #			context.drawImage(
  #				this.image,
  #				src.left(),
  #				src.top(),
  #				w,
  #				h,
  #				area.left(),
  #				area.top(),
  #				w,
  #				h
  #			);
  #		} catch (err) {
  #			alert('internal error\n\n' + err
  #				+ '\n ---'
  #				+ '\n canvas: ' + aCanvas
  #				+ '\n canvas.width: ' + aCanvas.width
  #				+ '\n canvas.height: ' + aCanvas.height
  #				+ '\n ---'
  #				+ '\n image: ' + this.image
  #				+ '\n image.width: ' + this.image.width
  #				+ '\n image.height: ' + this.image.height
  #				+ '\n ---'
  #				+ '\n w: ' + w
  #				+ '\n h: ' + h
  #				+ '\n sl: ' + sl
  #				+ '\n st: ' + st
  #				+ '\n area.left: ' + area.left()
  #				+ '\n area.top ' + area.top()
  #				);
  #		}
  #	
  recursivelyBlit: (aCanvas, clippingRectangle = @boundsIncludingChildren()) ->
    return null  unless @isVisible
    @blit aCanvas, clippingRectangle
    @children.forEach (child) ->
      child.recursivelyBlit aCanvas, clippingRectangle
  
  
  hide: ->
    @isVisible = false
    @changed()
    @children.forEach (child) ->
      child.hide()
  
  
  show: ->
    @isVisible = true
    @changed()
    @children.forEach (child) ->
      child.show()
  
  
  toggleVisibility: ->
    @isVisible = (not @isVisible)
    @changed()
    @children.forEach (child) ->
      child.toggleVisibility()
  
  
  # Morph full image:
  
  # this function is not used.
  fullImageClassic: ->
    # why doesn't this work for all Morphs?
    fb = @boundsIncludingChildren()
    img = newCanvas(fb.extent())
    @recursivelyBlit img, fb
    img.globalAlpha = @alpha
    img

  # fixes https://github.com/jmoenig/morphic.js/issues/7
  fullImage: ->
    boundsIncludingChildren = @boundsIncludingChildren()
    img = newCanvas(boundsIncludingChildren.extent())
    ctx = img.getContext("2d")
    ctx.translate -@bounds.origin.x , -@bounds.origin.y
    @recursivelyBlit img, boundsIncludingChildren
    img

  fullImageData: ->
    @fullImage().toDataURL()

  fullImageHashCode: ->
    return hashCode(@fullImageData())
  
  # Morph shadow:
  shadowImage: (off_, color) ->
    # fallback for Windows Chrome-Shadow bug
    offset = off_ or new Point(7, 7)
    clr = color or new Color(0, 0, 0)
    fb = @boundsIncludingChildren().extent()
    img = @fullImage()
    outline = newCanvas(fb)
    ctx = outline.getContext("2d")
    ctx.drawImage img, 0, 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, Math.round(-offset.x), Math.round(-offset.y)
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.drawImage outline, 0, 0
    ctx.globalCompositeOperation = "source-atop"
    ctx.fillStyle = clr.toString()
    ctx.fillRect 0, 0, fb.x, fb.y
    sha
  
  shadowImageBlurred: (off_, color) ->
    offset = off_ or new Point(7, 7)
    blur = @shadowBlur
    clr = color or new Color(0, 0, 0)
    fb = @boundsIncludingChildren().extent().add(blur * 2)
    img = @fullImage()
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.shadowOffsetX = offset.x
    ctx.shadowOffsetY = offset.y
    ctx.shadowBlur = blur
    ctx.shadowColor = clr.toString()
    ctx.drawImage img, Math.round(blur - offset.x), Math.round(blur - offset.y)
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    ctx.shadowBlur = 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, Math.round(blur - offset.x), Math.round(blur - offset.y)
    sha
  
  shadow: (off_, a, color) ->
    shadow = new ShadowMorph()
    offset = off_ or new Point(7, 7)
    alpha = a or ((if (a is 0) then 0 else 0.2))
    fb = @boundsIncludingChildren()
    shadow.setExtent fb.extent().add(@shadowBlur * 2)
    if useBlurredShadows and  !WorldMorph.MorphicPreferences.isFlat
      shadow.image = @shadowImageBlurred(offset, color)
      shadow.alpha = alpha
      shadow.setPosition fb.origin.add(offset).subtract(@shadowBlur)
    else
      shadow.image = @shadowImage(offset, color)
      shadow.alpha = alpha
      shadow.setPosition fb.origin.add(offset)
    shadow
  
  addShadow: (off_, a, color) ->
    offset = off_ or new Point(7, 7)
    alpha = a or ((if (a is 0) then 0 else 0.2))
    shadow = @shadow(offset, alpha, color)
    @addBack shadow
    @fullChanged()
    shadow
  
  getShadow: ->
    shadows = @children.slice(0).reverse().filter((child) ->
      child instanceof ShadowMorph
    )
    return shadows[0]  if shadows.length
    null
  
  removeShadow: ->
    shadow = @getShadow()
    if shadow isnt null
      @fullChanged()
      @removeChild shadow
  
  
  # Morph pen trails:
  penTrails: ->
    # answer my pen trails canvas. default is to answer my image
    @image
  
  
  # Morph updating ///////////////////////////////////////////////////////////////
  changed: ->
    if @trackChanges
      w = @root()
      w.broken.push @visibleBounds().spread()  if w instanceof WorldMorph
    @parent.childChanged @  if @parent
  
  fullChanged: ->
    if @trackChanges
      w = @root()
      w.broken.push @boundsIncludingChildren().spread()  if w instanceof WorldMorph
  
  childChanged: ->
    # react to a  change in one of my children,
    # default is to just pass this message on upwards
    # override this method for Morphs that need to adjust accordingly
    @parent.childChanged @  if @parent
  
  
  # Morph accessing - structure //////////////////////////////////////////////
  world: ->
    root = @root()
    return root  if root instanceof WorldMorph
    return root.world  if root instanceof HandMorph
    null
  
  add: (aMorph) ->
    owner = aMorph.parent
    owner.removeChild aMorph  if owner?
    @addChild aMorph
  
  addBack: (aMorph) ->
    owner = aMorph.parent
    owner.removeChild aMorph  if owner?
    @addChildFirst aMorph
  
  topMorphSuchThat: (predicate) ->
    if predicate.call(null, @)
      next = detect(@children.slice(0).reverse(), predicate)
      return next.topMorphSuchThat(predicate)  if next
      return @
    null
  
  morphAt: (aPoint) ->
    morphs = @allChildren().slice(0).reverse()
    result = null
    morphs.forEach (m) ->
      result = m  if m.boundsIncludingChildren().containsPoint(aPoint) and (result is null)
    #
    result
  
  #
  #	alternative -  more elegant and possibly more
  #	performant - solution for morphAt.
  #	Has some issues, commented out for now
  #
  #Morph.prototype.morphAt = function (aPoint) {
  #	return this.topMorphSuchThat(function (m) {
  #		return m.boundsIncludingChildren().containsPoint(aPoint);
  #	});
  #};
  #
  
  # used for example:
  # - to determine which morphs you can attach a morph to
  # - for a SliderMorph's "set target" so you can change properties of another Morph
  # - by the HandleMorph when you attach it to some other morph
  overlappedMorphs: ->
    # find all morphs in the world that intersect me,
    # excluding myself and the World
    # and any of my parents
    #    (cause I'm already attached to them directly or indirectly)
    # or any of my children
    #    (cause they are already attached to me directly or indirectly)
    world = @world()
    fb = @boundsIncludingChildren()
    allParents = @allParents()
    allChildren = @allChildren()
    morphs = world.allChildren()
    morphs.filter (m) =>
      m.isVisible and
        m isnt @ and
        m isnt world and
        not contains(allParents, m) and
        not contains(allChildren, m) and
        m.boundsIncludingChildren().intersects(fb)
  
  # Morph pixel access:
  getPixelColor: (aPoint) ->
    point = aPoint.subtract(@bounds.origin)
    context = @image.getContext("2d")
    data = context.getImageData(point.x, point.y, 1, 1)
    new Color(data.data[0], data.data[1], data.data[2], data.data[3])
  
  isTransparentAt: (aPoint) ->
    if @bounds.containsPoint(aPoint)
      return false  if @texture
      point = aPoint.subtract(@bounds.origin)
      context = @image.getContext("2d")
      data = context.getImageData(Math.floor(point.x), Math.floor(point.y), 1, 1)
      # check the 4th byte - the Alpha (RGBA)
      return data.data[3] is 0
    false
  
  # Morph duplicating ////////////////////////////////////////////////////
  
  copy: ->
    c = copy(@)
    c.parent = null
    c.children = []
    c.bounds = @bounds.copy()
    c
  
  fullCopy: ->
    #
    #	Produce a copy of me with my entire tree of submorphs. Morphs
    #	mentioned more than once are all directed to a single new copy.
    #	Other properties are also *shallow* copied, so you must override
    #	to deep copy Arrays and (complex) Objects
    #	
    dict = {}
    c = @copyRecordingReferences(dict)
    c.forAllChildren (m) ->
      m.updateReferences dict
    #
    c
  
  copyRecordingReferences: (dict) ->
    #
    #	Recursively copy this entire composite morph, recording the
    #	correspondence between old and new morphs in the given dictionary.
    #	This dictionary will be used to update intra-composite references
    #	in the copy. See updateReferences().
    #	Note: This default implementation copies ONLY morphs in the
    #	submorph hierarchy. If a morph stores morphs in other properties
    #	that it wants to copy, then it should override this method to do so.
    #	The same goes for morphs that contain other complex data that
    #	should be copied when the morph is duplicated.
    #	
    c = @copy()
    dict[@] = c
    @children.forEach (m) ->
      c.add m.copyRecordingReferences(dict)
    #
    c
  
  updateReferences: (dict) ->
    #
    #	Update intra-morph references within a composite morph that has
    #	been copied. For example, if a button refers to morph X in the
    #	orginal composite then the copy of that button in the new composite
    #	should refer to the copy of X in new composite, not the original X.
    #	
    for property of @
      @[property] = dict[property]  if property.isMorph and dict[property]
  
  
  # Morph dragging and dropping /////////////////////////////////////////
  
  rootForGrab: ->
    return @parent.rootForGrab()  if @ instanceof ShadowMorph
    return @parent  if @parent instanceof ScrollFrameMorph
    if @parent is null or
      @parent instanceof WorldMorph or
      @parent instanceof FrameMorph or
      @isDraggable is true
        return @  
    @parent.rootForGrab()
  
  wantsDropOf: (aMorph) ->
    # default is to answer the general flag - change for my heirs
    if (aMorph instanceof HandleMorph) or
      (aMorph instanceof MenuMorph) or
      (aMorph instanceof InspectorMorph)
        return false  
    @acceptsDrops
  
  pickUp: (wrrld) ->
    world = wrrld or @world()
    @setPosition world.hand.position().subtract(@extent().floorDivideBy(2))
    world.hand.grab @
  
  isPickedUp: ->
    @parentThatIsA(HandMorph) isnt null
  
  situation: ->
    # answer a dictionary specifying where I am right now, so
    # I can slide back to it if I'm dropped somewhere else
    if @parent
      return (
        origin: @parent
        position: @position().subtract(@parent.position())
      )
    null
  
  slideBackTo: (situation, inSteps) ->
    steps = inSteps or 5
    pos = situation.origin.position().add(situation.position)
    xStep = -(@left() - pos.x) / steps
    yStep = -(@top() - pos.y) / steps
    stepCount = 0
    oldStep = @step
    oldFps = @fps
    @fps = 0
    @step = =>
      @fullChanged()
      @silentMoveBy new Point(xStep, yStep)
      @fullChanged()
      stepCount += 1
      if stepCount is steps
        situation.origin.add @
        situation.origin.reactToDropOf @  if situation.origin.reactToDropOf
        @step = oldStep
        @fps = oldFps
  
  
  # Morph utilities ////////////////////////////////////////////////////////
  
  resize: ->
    @world().activeHandle = new HandleMorph(@)
  
  move: ->
    @world().activeHandle = new HandleMorph(@, null, null, null, null, "move")
  
  hint: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph(@, text)
    m.isDraggable = true
    m.popUpCenteredAtHand @world()
  
  inform: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph(@, text)
    m.addItem "Ok"
    m.isDraggable = true
    m.popUpCenteredAtHand @world()
  
  prompt: (msg, callback, environment, defaultContents, width, floorNum,
    ceilingNum, isRounded) ->
    isNumeric = true  if ceilingNum
    menu = new MenuMorph(callback or null, msg or "", environment or null)
    entryField = new StringFieldMorph(
      defaultContents or "",
      width or 100,
      WorldMorph.MorphicPreferences.prompterFontSize,
      WorldMorph.MorphicPreferences.prompterFontName,
      false,
      false,
      isNumeric)
    menu.items.push entryField
    if ceilingNum or WorldMorph.MorphicPreferences.useSliderForInput
      slider = new SliderMorph(
        floorNum or 0,
        ceilingNum,
        parseFloat(defaultContents),
        Math.floor((ceilingNum - floorNum) / 4),
        "horizontal")
      slider.alpha = 1
      slider.color = new Color(225, 225, 225)
      slider.button.color = menu.borderColor
      slider.button.highlightColor = slider.button.color.copy()
      slider.button.highlightColor.b += 100
      slider.button.pressColor = slider.button.color.copy()
      slider.button.pressColor.b += 150
      slider.setHeight WorldMorph.MorphicPreferences.prompterSliderSize
      if isRounded
        slider.action = (num) ->
          entryField.changed()
          entryField.text.text = Math.round(num).toString()
          entryField.text.updateRendering()
          entryField.text.changed()
          entryField.text.edit()
      else
        slider.action = (num) ->
          entryField.changed()
          entryField.text.text = num.toString()
          entryField.text.updateRendering()
          entryField.text.changed()
      menu.items.push slider
    menu.addLine 2
    menu.addItem "Ok", ->
      entryField.string()
    #
    menu.addItem "Cancel", ->
      null
    #
    menu.isDraggable = true
    menu.popUpAtHand @world()
    entryField.text.edit()
  
  pickColor: (msg, callback, environment, defaultContents) ->
    menu = new MenuMorph(callback or null, msg or "", environment or null)
    colorPicker = new ColorPickerMorph(defaultContents)
    menu.items.push colorPicker
    menu.addLine 2
    menu.addItem "Ok", ->
      colorPicker.getChoice()
    #
    menu.addItem "Cancel", ->
      null
    #
    menu.isDraggable = true
    menu.popUpAtHand @world()

  inspect: (anotherObject) ->
    inspectee = @
    inspectee = anotherObject  if anotherObject
    @spawnInspector inspectee

  spawnInspector: (inspectee) ->
    inspector = new InspectorMorph(inspectee)
    world = (if @world instanceof Function then @world() else (@root() or @world))
    inspector.setPosition world.hand.position()
    inspector.keepWithin world
    world.add inspector
    inspector.changed()
    
  
  # Morph menus ////////////////////////////////////////////////////////////////
  
  contextMenu: ->
    return @customContextMenu  if @customContextMenu
    world = (if @world instanceof Function then @world() else (@root() or @world))
    if world and world.isDevMode
      return @developersMenu()  if @parent is world
      return @hierarchyMenu()
    @userMenu() or (@parent and @parent.userMenu())
  
  hierarchyMenu: ->
    parents = @allParents()
    world = (if @world instanceof Function then @world() else (@root() or @world))
    menu = new MenuMorph(@, null)
    parents.forEach (each) ->
      if each.developersMenu and (each isnt world)
        menu.addItem each.toString().slice(0, 50), ->
          each.developersMenu().popUpAtHand world
    #  
    menu
  
  developersMenu: ->
    # 'name' is not an official property of a function, hence:
    world = (if @world instanceof Function then @world() else (@root() or @world))
    userMenu = @userMenu() or (@parent and @parent.userMenu())
    menu = new MenuMorph(
      @,
      @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    if userMenu
      menu.addItem "user features...", ->
        userMenu.popUpAtHand world
      #
      menu.addLine()
    menu.addItem "color...", (->
      @pickColor menu.title + "\ncolor:", @setColor, @, @color
    ), "choose another color \nfor this morph"
    menu.addItem "transparency...", (->
      @prompt menu.title + "\nalpha\nvalue:",
        @setAlphaScaled, @, (@alpha * 100).toString(),
        null,
        1,
        100,
        true
    ), "set this morph's\nalpha value"
    menu.addItem "resize...", "resize", "show a handle\nwhich can be dragged\nto change this morph's" + " extent"
    menu.addLine()
    menu.addItem "duplicate", (->
      @fullCopy().pickUp @world()
    ), "make a copy\nand pick it up"
    menu.addItem "pick up", "pickUp", "disattach and put \ninto the hand"
    menu.addItem "attach...", "attach", "stick this morph\nto another one"
    menu.addItem "move...", "move", "show a handle\nwhich can be dragged\nto move this morph"
    menu.addItem "inspect...", "inspect", "open a window\non all properties"
    menu.addItem "pic...", (()->window.open(@fullImageData())), "open a new window\nwith a picture of this morph"
    menu.addLine()
    if @isDraggable
      menu.addItem "lock", "toggleIsDraggable", "make this morph\nunmovable"
    else
      menu.addItem "unlock", "toggleIsDraggable", "make this morph\nmovable"
    menu.addItem "hide", "hide"
    menu.addItem "delete", "destroy"
    unless @ instanceof WorldMorph
      menu.addLine()
      menu.addItem "World...", (->
        world.contextMenu().popUpAtHand world
      ), "show the\nWorld's menu"
    menu
  
  userMenu: ->
    null
  
  
  # Morph menu actions
  calculateAlphaScaled: (alpha) ->
    if typeof alpha is "number"
      unscaled = alpha / 100
      return Math.min(Math.max(unscaled, 0.1), 1)
    else
      newAlpha = parseFloat(alpha)
      unless isNaN(newAlpha)
        unscaled = newAlpha / 100
        return Math.min(Math.max(unscaled, 0.1), 1)

  setAlphaScaled: (alpha) ->
    @alpha = @calculateAlphaScaled(alpha)
    @changed()
  
  attach: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose new parent:")
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), =>
        each.add @
        @isDraggable = false
    #
    menu.popUpAtHand @world()  if choices.length
  
  toggleIsDraggable: ->
    # for context menu demo purposes
    @isDraggable = not @isDraggable
  
  colorSetters: ->
    # for context menu demo purposes
    ["color"]
  
  numericalSetters: ->
    # for context menu demo purposes
    ["setLeft", "setTop", "setWidth", "setHeight", "setAlphaScaled"]
  
  
  # Morph entry field tabbing //////////////////////////////////////////////
  
  allEntryFields: ->
    @allChildren().filter (each) ->
      each.isEditable && (each instanceof StringMorph || each instanceof TextMorph);
  
  
  nextEntryField: (current) ->
    fields = @allEntryFields()
    idx = fields.indexOf(current)
    if idx isnt -1
      if fields.length > (idx + 1)
        return fields[idx + 1]
    return fields[0]
  
  previousEntryField: (current) ->
    fields = @allEntryFields()
    idx = fields.indexOf(current)
    if idx isnt -1
      if idx > 0
        return fields[idx - 1]
      return fields[fields.length - 1]
    return fields[0]
  
  tab: (editField) ->
    #
    #	the <tab> key was pressed in one of my edit fields.
    #	invoke my "nextTab()" function if it exists, else
    #	propagate it up my owner chain.
    #
    if @nextTab
      @nextTab editField
    else @parent.tab editField  if @parent
  
  backTab: (editField) ->
    #
    #	the <back tab> key was pressed in one of my edit fields.
    #	invoke my "previousTab()" function if it exists, else
    #	propagate it up my owner chain.
    #
    if @previousTab
      @previousTab editField
    else @parent.backTab editField  if @parent
  
  
  #
  #	the following are examples of what the navigation methods should
  #	look like. Insert these at the World level for fallback, and at lower
  #	levels in the Morphic tree (e.g. dialog boxes) for a more fine-grained
  #	control over the tabbing cycle.
  #
  #Morph.prototype.nextTab = function (editField) {
  #	var	next = this.nextEntryField(editField);
  #	editField.clearSelection();
  #	next.selectAll();
  #	next.edit();
  #};
  #
  #Morph.prototype.previousTab = function (editField) {
  #	var	prev = this.previousEntryField(editField);
  #	editField.clearSelection();
  #	prev.selectAll();
  #	prev.edit();
  #};
  #
  #
  
  # Morph events:
  escalateEvent: (functionName, arg) ->
    handler = @parent
    handler = handler.parent  while not handler[functionName] and handler.parent?
    handler[functionName] arg  if handler[functionName]
  
  
  # Morph eval. Used by the Inspector and the TextMorph.
  evaluateString: (code) ->
    try
      result = eval(code)
      @updateRendering()
      @changed()
    catch err
      @inform err
    result
  
  
  # Morph collision detection - not used anywhere at the moment ////////////////////////
  
  isTouching: (otherMorph) ->
    oImg = @overlappingImage(otherMorph)
    data = oImg.getContext("2d").getImageData(1, 1, oImg.width, oImg.height).data
    detect(data, (each) ->
      each isnt 0
    ) isnt null
  
  overlappingImage: (otherMorph) ->
    fb = @boundsIncludingChildren()
    otherFb = otherMorph.boundsIncludingChildren()
    oRect = fb.intersect(otherFb)
    oImg = newCanvas(oRect.extent())
    ctx = oImg.getContext("2d")
    return newCanvas(new Point(1, 1))  if oRect.width() < 1 or oRect.height() < 1
    ctx.drawImage @fullImage(),
      Math.round(oRect.origin.x - fb.origin.x),
      Math.round(oRect.origin.y - fb.origin.y)
    ctx.globalCompositeOperation = "source-in"
    ctx.drawImage otherMorph.fullImage(),
      Math.round(otherFb.origin.x - oRect.origin.x),
      Math.round(otherFb.origin.y - oRect.origin.y)
    oImg

  @coffeeScriptSourceOfThisClass: '''
# Morph //////////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class Morph extends MorphicNode
  
  # Just some tests here ////////////////////
  propertyUpTheChain: [1,2,3]
  morphMethod: ->
    3.14
  @morphStaticMethod: ->
    3.14
  # End of tests here ////////////////////

  isMorph: true
  bounds: null
  color: null
  texture: null # optional url of a fill-image
  cachedTexture: null # internal cache of actual bg image
  lastTime: null
  alpha: 1
  isVisible: true
  isDraggable: false
  isTemplate: false
  acceptsDrops: false
  noticesTransparentClick: false
  fps: 0
  customContextMenu: null
  trackChanges: true
  shadowBlur: 4
  # note that image contains only the CURRENT morph, not the composition of this
  # morph with all of the submorphs. I.e. for an inspector, this will only
  # contain the background of the window pane. Not any of its contents.
  # for the worldMorph, this only contains the background
  image: null
  onNextStep: null # optional function to be run once. Not currently used in Zombie Kernel
  
  constructor: () ->
    super()
    # [TODO] why is there this strange non-zero default bound?
    @bounds = new Rectangle(0, 0, 50, 40)
    @color = new Color(80, 80, 80)
    @updateRendering()
    @lastTime = Date.now()
  
  #
  #    damage list housekeeping
  #
  #	the trackChanges property of the Morph prototype is a Boolean switch
  #	that determines whether the World's damage list ('broken' rectangles)
  #	tracks changes. By default the switch is always on. If set to false
  #	changes are not stored. This can be very useful for housekeeping of
  #	the damage list in situations where a large number of (sub-) morphs
  #	are changed more or less at once. Instead of keeping track of every
  #	single submorph's changes tremendous performance improvements can be
  #	achieved by setting the trackChanges flag to false before propagating
  #	the layout changes, setting it to true again and then storing the full
  #	bounds of the surrounding morph. An an example refer to the
  #
  #		fixLayout()
  #		
  #	method of InspectorMorph, or the
  #	
  #		startLayout()
  #		endLayout()
  #
  #	methods of SyntaxElementMorph in the Snap application.
  #
  
  
  # Morph string representation: e.g. 'a Morph 2 [20@45 | 130@250]'
  toString: ->
    "a " +
      (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0]) +
      " " +
      @children.length.toString() +
      " " +
      @bounds
  
  
  # Morph deleting:
  destroy: ->
    if @parent isnt null
      @fullChanged()
      @parent.removeChild @
  
  destroyAll: ->
    # this is a typical case: we need to make a copy of the children
    # array first pecause we are iterating over an array that changes
    # its values (and length) while we are iterating on it.
    childrenCopy = @children.filter (x) -> true
    childrenCopy.forEach (child) =>
      child.destroy()
    
  # Morph stepping:
  runChildrensStepFunction: ->
    # step is the function that this Morph wants to run at each step.
    # If the Morph wants to do nothing and let no-one of the children do nothing,
    # then step is set to null.
    # If the morph wants to do nothing but the children might want to do something,
    # then step is set to the function that does nothing (i.e. a function noOperation that
    # only returns null) 
    return null  unless @step

    # for objects where @fps is defined, check which ones are due to be stepped
    # and which ones want to wait. 
    elapsed = WorldMorph.currentTime - @lastTime
    if @fps > 0
      timeRemainingToWaitedFrame = (1000 / @fps) - elapsed
    else
      timeRemainingToWaitedFrame = 0
    
    # Question: why 1 here below?
    if timeRemainingToWaitedFrame < 1
      @lastTime = WorldMorph.currentTime
      if @onNextStep
        nxt = @onNextStep
        @onNextStep = null
        nxt.call(@)
      @step()
      @children.forEach (child) ->
        child.runChildrensStepFunction()

  nextSteps: (arrayOfFunctions) ->
    lst = arrayOfFunctions or []
    nxt = lst.shift()
    if nxt
      @onNextStep = =>
        nxt.call @
        @nextSteps lst  
  
  # leaving this function as step means that the morph want to do nothing
  # but the children *are* traversed and their step function is invoked.
  # If a Morph wants to do nothing and wants to prevent the children to be
  # traversed, then this function should be set to null.
  step: noOperation
  
  
  # Morph accessing - geometry getting:
  left: ->
    @bounds.left()
  
  right: ->
    @bounds.right()
  
  top: ->
    @bounds.top()
  
  bottom: ->
    @bounds.bottom()
  
  center: ->
    @bounds.center()
  
  bottomCenter: ->
    @bounds.bottomCenter()
  
  bottomLeft: ->
    @bounds.bottomLeft()
  
  bottomRight: ->
    @bounds.bottomRight()
  
  boundingBox: ->
    @bounds
  
  corners: ->
    @bounds.corners()
  
  leftCenter: ->
    @bounds.leftCenter()
  
  rightCenter: ->
    @bounds.rightCenter()
  
  topCenter: ->
    @bounds.topCenter()
  
  topLeft: ->
    @bounds.topLeft()
  
  topRight: ->
    @bounds.topRight()
  
  position: ->
    @bounds.origin
  
  extent: ->
    @bounds.extent()
  
  width: ->
    @bounds.width()
  
  height: ->
    @bounds.height()
  
  boundsIncludingChildren: ->
    result = @bounds
    @children.forEach (child) ->
      result = result.merge(child.boundsIncludingChildren())  if child.isVisible
    #
    result
  
  boundsIncludingChildrenNoShadow: ->
    # answer my full bounds but ignore any shadow
    result = @bounds
    @children.forEach (child) ->
      if (child not instanceof ShadowMorph) and (child.isVisible)
        result = result.merge(child.boundsIncludingChildren())
    #
    result
  
  visibleBounds: ->
    # answer which part of me is not clipped by a Frame
    visible = @bounds
    frames = @allParents().filter((p) ->
      p instanceof FrameMorph
    )
    frames.forEach (f) ->
      visible = visible.intersect(f.bounds)
    #
    visible
  
  
  # Morph accessing - simple changes:
  moveBy: (delta) ->
    # question: why is changed() called two times?
    # question: can't we use silentMoveBy?
    @changed()
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.moveBy delta
    #
    @changed()
  
  silentMoveBy: (delta) ->
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.silentMoveBy delta
  
  
  setPosition: (aPoint) ->
    delta = aPoint.subtract(@topLeft())
    @moveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  silentSetPosition: (aPoint) ->
    delta = aPoint.subtract(@topLeft())
    @silentMoveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  setLeft: (x) ->
    @setPosition new Point(x, @top())
  
  setRight: (x) ->
    @setPosition new Point(x - @width(), @top())
  
  setTop: (y) ->
    @setPosition new Point(@left(), y)
  
  setBottom: (y) ->
    @setPosition new Point(@left(), y - @height())
  
  setCenter: (aPoint) ->
    @setPosition aPoint.subtract(@extent().floorDivideBy(2))
  
  setFullCenter: (aPoint) ->
    @setPosition aPoint.subtract(@boundsIncludingChildren().extent().floorDivideBy(2))
  
  # make sure I am completely within another Morph's bounds
  keepWithin: (aMorph) ->
    leftOff = @boundsIncludingChildren().left() - aMorph.left()
    @moveBy new Point(-leftOff, 0)  if leftOff < 0
    rightOff = @boundsIncludingChildren().right() - aMorph.right()
    @moveBy new Point(-rightOff, 0)  if rightOff > 0
    topOff = @boundsIncludingChildren().top() - aMorph.top()
    @moveBy new Point(0, -topOff)  if topOff < 0
    bottomOff = @boundsIncludingChildren().bottom() - aMorph.bottom()
    @moveBy new Point(0, -bottomOff)  if bottomOff > 0
  
  
  # Morph accessing - dimensional changes requiring a complete redraw
  setExtent: (aPoint) ->
    unless aPoint.eq(@extent())
      # question: why two "changed" invocations?
      @changed()
      @silentSetExtent aPoint
      @changed()
      @updateRendering()
  
  silentSetExtent: (aPoint) ->
    ext = aPoint.round()
    newWidth = Math.max(ext.x, 0)
    newHeight = Math.max(ext.y, 0)
    @bounds.corner = new Point(@bounds.origin.x + newWidth, @bounds.origin.y + newHeight)
  
  setWidth: (width) ->
    @setExtent new Point(width or 0, @height())
  
  silentSetWidth: (width) ->
    # do not updateRendering() just yet
    w = Math.max(Math.round(width or 0), 0)
    @bounds.corner = new Point(@bounds.origin.x + w, @bounds.corner.y)
  
  setHeight: (height) ->
    @setExtent new Point(@width(), height or 0)
  
  silentSetHeight: (height) ->
    # do not updateRendering() just yet
    h = Math.max(Math.round(height or 0), 0)
    @bounds.corner = new Point(@bounds.corner.x, @bounds.origin.y + h)
  
  setColor: (aColor) ->
    if aColor
      unless @color.eq(aColor)
        @color = aColor
        @changed()
        @updateRendering()
  
  
  # Morph displaying ###########################################################

  # There are three fundamental methods for rendering and displaying anything.
  # * updateRendering: this one creates/updates the local canvas of this morph only
  #   i.e. not the children
  # * blit: takes the local canvas and blits it to a specific area in a passed
  #   canvas. The local canvas doesn't contain any rendering of the children of
  #   this morph.
  # * recursivelyBlit: recursively draws all the local canvas of this morph and all
  #   its children into a specific area of a passed canvas.

  updateRendering: ->
    # initialize my surface property
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    context.fillStyle = @color.toString()
    context.fillRect 0, 0, @width(), @height()
    if @cachedTexture
      @drawCachedTexture()
    else @drawTexture @texture  if @texture
  
  drawTexture: (url) ->
    @cachedTexture = new Image()
    @cachedTexture.onload = =>
      @drawCachedTexture()
    #
    @cachedTexture.src = @texture = url # make absolute
  
  # tiles the texture
  drawCachedTexture: ->
    bg = @cachedTexture
    cols = Math.floor(@image.width / bg.width)
    lines = Math.floor(@image.height / bg.height)
    context = @image.getContext("2d")
    for y in [0..lines]
      for x in [0..cols]
        context.drawImage bg, Math.round(x * bg.width), Math.round(y * bg.height)
    @changed()
  
  
  #
  #Morph.prototype.drawCachedTexture = function () {
  #    var context = this.image.getContext('2d'),
  #        pattern = context.createPattern(this.cachedTexture, 'repeat');
  #	context.fillStyle = pattern;
  #    context.fillRect(0, 0, this.image.width, this.image.height);
  #    this.changed();
  #};
  #
  
  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by recursivelyBlit, which
  # eventually invokes blit.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  blit: (aCanvas, clippingRectangle = @bounds) ->
    return null  unless @isVisible
    area = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if area.isNotEmpty()
      delta = @position().neg()
      src = area.copy().translateBy(delta).round()
      context = aCanvas.getContext("2d")
      context.globalAlpha = @alpha
      sl = src.left()
      st = src.top()
      al = area.left()
      at = area.top()
      w = Math.min(src.width(), @image.width - sl)
      h = Math.min(src.height(), @image.height - st)
      return null  if w < 1 or h < 1

      context.drawImage @image,
        Math.round(sl),
        Math.round(st),
        Math.round(w),
        Math.round(h),
        Math.round(al),
        Math.round(at),
        Math.round(w),
        Math.round(h)

      if WorldMorph.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)
        context.globalAlpha = 0.5
        context.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        context.fillRect(Math.round(al),Math.round(at),Math.round(w),Math.round(h));
  
  
  # "for debugging purposes:"
  #
  #		try {
  #			context.drawImage(
  #				this.image,
  #				src.left(),
  #				src.top(),
  #				w,
  #				h,
  #				area.left(),
  #				area.top(),
  #				w,
  #				h
  #			);
  #		} catch (err) {
  #			alert('internal error\n\n' + err
  #				+ '\n ---'
  #				+ '\n canvas: ' + aCanvas
  #				+ '\n canvas.width: ' + aCanvas.width
  #				+ '\n canvas.height: ' + aCanvas.height
  #				+ '\n ---'
  #				+ '\n image: ' + this.image
  #				+ '\n image.width: ' + this.image.width
  #				+ '\n image.height: ' + this.image.height
  #				+ '\n ---'
  #				+ '\n w: ' + w
  #				+ '\n h: ' + h
  #				+ '\n sl: ' + sl
  #				+ '\n st: ' + st
  #				+ '\n area.left: ' + area.left()
  #				+ '\n area.top ' + area.top()
  #				);
  #		}
  #	
  recursivelyBlit: (aCanvas, clippingRectangle = @boundsIncludingChildren()) ->
    return null  unless @isVisible
    @blit aCanvas, clippingRectangle
    @children.forEach (child) ->
      child.recursivelyBlit aCanvas, clippingRectangle
  
  
  hide: ->
    @isVisible = false
    @changed()
    @children.forEach (child) ->
      child.hide()
  
  
  show: ->
    @isVisible = true
    @changed()
    @children.forEach (child) ->
      child.show()
  
  
  toggleVisibility: ->
    @isVisible = (not @isVisible)
    @changed()
    @children.forEach (child) ->
      child.toggleVisibility()
  
  
  # Morph full image:
  
  # this function is not used.
  fullImageClassic: ->
    # why doesn't this work for all Morphs?
    fb = @boundsIncludingChildren()
    img = newCanvas(fb.extent())
    @recursivelyBlit img, fb
    img.globalAlpha = @alpha
    img

  # fixes https://github.com/jmoenig/morphic.js/issues/7
  fullImage: ->
    boundsIncludingChildren = @boundsIncludingChildren()
    img = newCanvas(boundsIncludingChildren.extent())
    ctx = img.getContext("2d")
    ctx.translate -@bounds.origin.x , -@bounds.origin.y
    @recursivelyBlit img, boundsIncludingChildren
    img

  fullImageData: ->
    @fullImage().toDataURL()

  fullImageHashCode: ->
    return hashCode(@fullImageData())
  
  # Morph shadow:
  shadowImage: (off_, color) ->
    # fallback for Windows Chrome-Shadow bug
    offset = off_ or new Point(7, 7)
    clr = color or new Color(0, 0, 0)
    fb = @boundsIncludingChildren().extent()
    img = @fullImage()
    outline = newCanvas(fb)
    ctx = outline.getContext("2d")
    ctx.drawImage img, 0, 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, Math.round(-offset.x), Math.round(-offset.y)
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.drawImage outline, 0, 0
    ctx.globalCompositeOperation = "source-atop"
    ctx.fillStyle = clr.toString()
    ctx.fillRect 0, 0, fb.x, fb.y
    sha
  
  shadowImageBlurred: (off_, color) ->
    offset = off_ or new Point(7, 7)
    blur = @shadowBlur
    clr = color or new Color(0, 0, 0)
    fb = @boundsIncludingChildren().extent().add(blur * 2)
    img = @fullImage()
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.shadowOffsetX = offset.x
    ctx.shadowOffsetY = offset.y
    ctx.shadowBlur = blur
    ctx.shadowColor = clr.toString()
    ctx.drawImage img, Math.round(blur - offset.x), Math.round(blur - offset.y)
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    ctx.shadowBlur = 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, Math.round(blur - offset.x), Math.round(blur - offset.y)
    sha
  
  shadow: (off_, a, color) ->
    shadow = new ShadowMorph()
    offset = off_ or new Point(7, 7)
    alpha = a or ((if (a is 0) then 0 else 0.2))
    fb = @boundsIncludingChildren()
    shadow.setExtent fb.extent().add(@shadowBlur * 2)
    if useBlurredShadows and  !WorldMorph.MorphicPreferences.isFlat
      shadow.image = @shadowImageBlurred(offset, color)
      shadow.alpha = alpha
      shadow.setPosition fb.origin.add(offset).subtract(@shadowBlur)
    else
      shadow.image = @shadowImage(offset, color)
      shadow.alpha = alpha
      shadow.setPosition fb.origin.add(offset)
    shadow
  
  addShadow: (off_, a, color) ->
    offset = off_ or new Point(7, 7)
    alpha = a or ((if (a is 0) then 0 else 0.2))
    shadow = @shadow(offset, alpha, color)
    @addBack shadow
    @fullChanged()
    shadow
  
  getShadow: ->
    shadows = @children.slice(0).reverse().filter((child) ->
      child instanceof ShadowMorph
    )
    return shadows[0]  if shadows.length
    null
  
  removeShadow: ->
    shadow = @getShadow()
    if shadow isnt null
      @fullChanged()
      @removeChild shadow
  
  
  # Morph pen trails:
  penTrails: ->
    # answer my pen trails canvas. default is to answer my image
    @image
  
  
  # Morph updating ///////////////////////////////////////////////////////////////
  changed: ->
    if @trackChanges
      w = @root()
      w.broken.push @visibleBounds().spread()  if w instanceof WorldMorph
    @parent.childChanged @  if @parent
  
  fullChanged: ->
    if @trackChanges
      w = @root()
      w.broken.push @boundsIncludingChildren().spread()  if w instanceof WorldMorph
  
  childChanged: ->
    # react to a  change in one of my children,
    # default is to just pass this message on upwards
    # override this method for Morphs that need to adjust accordingly
    @parent.childChanged @  if @parent
  
  
  # Morph accessing - structure //////////////////////////////////////////////
  world: ->
    root = @root()
    return root  if root instanceof WorldMorph
    return root.world  if root instanceof HandMorph
    null
  
  add: (aMorph) ->
    owner = aMorph.parent
    owner.removeChild aMorph  if owner?
    @addChild aMorph
  
  addBack: (aMorph) ->
    owner = aMorph.parent
    owner.removeChild aMorph  if owner?
    @addChildFirst aMorph
  
  topMorphSuchThat: (predicate) ->
    if predicate.call(null, @)
      next = detect(@children.slice(0).reverse(), predicate)
      return next.topMorphSuchThat(predicate)  if next
      return @
    null
  
  morphAt: (aPoint) ->
    morphs = @allChildren().slice(0).reverse()
    result = null
    morphs.forEach (m) ->
      result = m  if m.boundsIncludingChildren().containsPoint(aPoint) and (result is null)
    #
    result
  
  #
  #	alternative -  more elegant and possibly more
  #	performant - solution for morphAt.
  #	Has some issues, commented out for now
  #
  #Morph.prototype.morphAt = function (aPoint) {
  #	return this.topMorphSuchThat(function (m) {
  #		return m.boundsIncludingChildren().containsPoint(aPoint);
  #	});
  #};
  #
  
  # used for example:
  # - to determine which morphs you can attach a morph to
  # - for a SliderMorph's "set target" so you can change properties of another Morph
  # - by the HandleMorph when you attach it to some other morph
  overlappedMorphs: ->
    # find all morphs in the world that intersect me,
    # excluding myself and the World
    # and any of my parents
    #    (cause I'm already attached to them directly or indirectly)
    # or any of my children
    #    (cause they are already attached to me directly or indirectly)
    world = @world()
    fb = @boundsIncludingChildren()
    allParents = @allParents()
    allChildren = @allChildren()
    morphs = world.allChildren()
    morphs.filter (m) =>
      m.isVisible and
        m isnt @ and
        m isnt world and
        not contains(allParents, m) and
        not contains(allChildren, m) and
        m.boundsIncludingChildren().intersects(fb)
  
  # Morph pixel access:
  getPixelColor: (aPoint) ->
    point = aPoint.subtract(@bounds.origin)
    context = @image.getContext("2d")
    data = context.getImageData(point.x, point.y, 1, 1)
    new Color(data.data[0], data.data[1], data.data[2], data.data[3])
  
  isTransparentAt: (aPoint) ->
    if @bounds.containsPoint(aPoint)
      return false  if @texture
      point = aPoint.subtract(@bounds.origin)
      context = @image.getContext("2d")
      data = context.getImageData(Math.floor(point.x), Math.floor(point.y), 1, 1)
      # check the 4th byte - the Alpha (RGBA)
      return data.data[3] is 0
    false
  
  # Morph duplicating ////////////////////////////////////////////////////
  
  copy: ->
    c = copy(@)
    c.parent = null
    c.children = []
    c.bounds = @bounds.copy()
    c
  
  fullCopy: ->
    #
    #	Produce a copy of me with my entire tree of submorphs. Morphs
    #	mentioned more than once are all directed to a single new copy.
    #	Other properties are also *shallow* copied, so you must override
    #	to deep copy Arrays and (complex) Objects
    #	
    dict = {}
    c = @copyRecordingReferences(dict)
    c.forAllChildren (m) ->
      m.updateReferences dict
    #
    c
  
  copyRecordingReferences: (dict) ->
    #
    #	Recursively copy this entire composite morph, recording the
    #	correspondence between old and new morphs in the given dictionary.
    #	This dictionary will be used to update intra-composite references
    #	in the copy. See updateReferences().
    #	Note: This default implementation copies ONLY morphs in the
    #	submorph hierarchy. If a morph stores morphs in other properties
    #	that it wants to copy, then it should override this method to do so.
    #	The same goes for morphs that contain other complex data that
    #	should be copied when the morph is duplicated.
    #	
    c = @copy()
    dict[@] = c
    @children.forEach (m) ->
      c.add m.copyRecordingReferences(dict)
    #
    c
  
  updateReferences: (dict) ->
    #
    #	Update intra-morph references within a composite morph that has
    #	been copied. For example, if a button refers to morph X in the
    #	orginal composite then the copy of that button in the new composite
    #	should refer to the copy of X in new composite, not the original X.
    #	
    for property of @
      @[property] = dict[property]  if property.isMorph and dict[property]
  
  
  # Morph dragging and dropping /////////////////////////////////////////
  
  rootForGrab: ->
    return @parent.rootForGrab()  if @ instanceof ShadowMorph
    return @parent  if @parent instanceof ScrollFrameMorph
    if @parent is null or
      @parent instanceof WorldMorph or
      @parent instanceof FrameMorph or
      @isDraggable is true
        return @  
    @parent.rootForGrab()
  
  wantsDropOf: (aMorph) ->
    # default is to answer the general flag - change for my heirs
    if (aMorph instanceof HandleMorph) or
      (aMorph instanceof MenuMorph) or
      (aMorph instanceof InspectorMorph)
        return false  
    @acceptsDrops
  
  pickUp: (wrrld) ->
    world = wrrld or @world()
    @setPosition world.hand.position().subtract(@extent().floorDivideBy(2))
    world.hand.grab @
  
  isPickedUp: ->
    @parentThatIsA(HandMorph) isnt null
  
  situation: ->
    # answer a dictionary specifying where I am right now, so
    # I can slide back to it if I'm dropped somewhere else
    if @parent
      return (
        origin: @parent
        position: @position().subtract(@parent.position())
      )
    null
  
  slideBackTo: (situation, inSteps) ->
    steps = inSteps or 5
    pos = situation.origin.position().add(situation.position)
    xStep = -(@left() - pos.x) / steps
    yStep = -(@top() - pos.y) / steps
    stepCount = 0
    oldStep = @step
    oldFps = @fps
    @fps = 0
    @step = =>
      @fullChanged()
      @silentMoveBy new Point(xStep, yStep)
      @fullChanged()
      stepCount += 1
      if stepCount is steps
        situation.origin.add @
        situation.origin.reactToDropOf @  if situation.origin.reactToDropOf
        @step = oldStep
        @fps = oldFps
  
  
  # Morph utilities ////////////////////////////////////////////////////////
  
  resize: ->
    @world().activeHandle = new HandleMorph(@)
  
  move: ->
    @world().activeHandle = new HandleMorph(@, null, null, null, null, "move")
  
  hint: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph(@, text)
    m.isDraggable = true
    m.popUpCenteredAtHand @world()
  
  inform: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph(@, text)
    m.addItem "Ok"
    m.isDraggable = true
    m.popUpCenteredAtHand @world()
  
  prompt: (msg, callback, environment, defaultContents, width, floorNum,
    ceilingNum, isRounded) ->
    isNumeric = true  if ceilingNum
    menu = new MenuMorph(callback or null, msg or "", environment or null)
    entryField = new StringFieldMorph(
      defaultContents or "",
      width or 100,
      WorldMorph.MorphicPreferences.prompterFontSize,
      WorldMorph.MorphicPreferences.prompterFontName,
      false,
      false,
      isNumeric)
    menu.items.push entryField
    if ceilingNum or WorldMorph.MorphicPreferences.useSliderForInput
      slider = new SliderMorph(
        floorNum or 0,
        ceilingNum,
        parseFloat(defaultContents),
        Math.floor((ceilingNum - floorNum) / 4),
        "horizontal")
      slider.alpha = 1
      slider.color = new Color(225, 225, 225)
      slider.button.color = menu.borderColor
      slider.button.highlightColor = slider.button.color.copy()
      slider.button.highlightColor.b += 100
      slider.button.pressColor = slider.button.color.copy()
      slider.button.pressColor.b += 150
      slider.setHeight WorldMorph.MorphicPreferences.prompterSliderSize
      if isRounded
        slider.action = (num) ->
          entryField.changed()
          entryField.text.text = Math.round(num).toString()
          entryField.text.updateRendering()
          entryField.text.changed()
          entryField.text.edit()
      else
        slider.action = (num) ->
          entryField.changed()
          entryField.text.text = num.toString()
          entryField.text.updateRendering()
          entryField.text.changed()
      menu.items.push slider
    menu.addLine 2
    menu.addItem "Ok", ->
      entryField.string()
    #
    menu.addItem "Cancel", ->
      null
    #
    menu.isDraggable = true
    menu.popUpAtHand @world()
    entryField.text.edit()
  
  pickColor: (msg, callback, environment, defaultContents) ->
    menu = new MenuMorph(callback or null, msg or "", environment or null)
    colorPicker = new ColorPickerMorph(defaultContents)
    menu.items.push colorPicker
    menu.addLine 2
    menu.addItem "Ok", ->
      colorPicker.getChoice()
    #
    menu.addItem "Cancel", ->
      null
    #
    menu.isDraggable = true
    menu.popUpAtHand @world()

  inspect: (anotherObject) ->
    inspectee = @
    inspectee = anotherObject  if anotherObject
    @spawnInspector inspectee

  spawnInspector: (inspectee) ->
    inspector = new InspectorMorph(inspectee)
    world = (if @world instanceof Function then @world() else (@root() or @world))
    inspector.setPosition world.hand.position()
    inspector.keepWithin world
    world.add inspector
    inspector.changed()
    
  
  # Morph menus ////////////////////////////////////////////////////////////////
  
  contextMenu: ->
    return @customContextMenu  if @customContextMenu
    world = (if @world instanceof Function then @world() else (@root() or @world))
    if world and world.isDevMode
      return @developersMenu()  if @parent is world
      return @hierarchyMenu()
    @userMenu() or (@parent and @parent.userMenu())
  
  hierarchyMenu: ->
    parents = @allParents()
    world = (if @world instanceof Function then @world() else (@root() or @world))
    menu = new MenuMorph(@, null)
    parents.forEach (each) ->
      if each.developersMenu and (each isnt world)
        menu.addItem each.toString().slice(0, 50), ->
          each.developersMenu().popUpAtHand world
    #  
    menu
  
  developersMenu: ->
    # 'name' is not an official property of a function, hence:
    world = (if @world instanceof Function then @world() else (@root() or @world))
    userMenu = @userMenu() or (@parent and @parent.userMenu())
    menu = new MenuMorph(
      @,
      @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    if userMenu
      menu.addItem "user features...", ->
        userMenu.popUpAtHand world
      #
      menu.addLine()
    menu.addItem "color...", (->
      @pickColor menu.title + "\ncolor:", @setColor, @, @color
    ), "choose another color \nfor this morph"
    menu.addItem "transparency...", (->
      @prompt menu.title + "\nalpha\nvalue:",
        @setAlphaScaled, @, (@alpha * 100).toString(),
        null,
        1,
        100,
        true
    ), "set this morph's\nalpha value"
    menu.addItem "resize...", "resize", "show a handle\nwhich can be dragged\nto change this morph's" + " extent"
    menu.addLine()
    menu.addItem "duplicate", (->
      @fullCopy().pickUp @world()
    ), "make a copy\nand pick it up"
    menu.addItem "pick up", "pickUp", "disattach and put \ninto the hand"
    menu.addItem "attach...", "attach", "stick this morph\nto another one"
    menu.addItem "move...", "move", "show a handle\nwhich can be dragged\nto move this morph"
    menu.addItem "inspect...", "inspect", "open a window\non all properties"
    menu.addItem "pic...", (()->window.open(@fullImageData())), "open a new window\nwith a picture of this morph"
    menu.addLine()
    if @isDraggable
      menu.addItem "lock", "toggleIsDraggable", "make this morph\nunmovable"
    else
      menu.addItem "unlock", "toggleIsDraggable", "make this morph\nmovable"
    menu.addItem "hide", "hide"
    menu.addItem "delete", "destroy"
    unless @ instanceof WorldMorph
      menu.addLine()
      menu.addItem "World...", (->
        world.contextMenu().popUpAtHand world
      ), "show the\nWorld's menu"
    menu
  
  userMenu: ->
    null
  
  
  # Morph menu actions
  calculateAlphaScaled: (alpha) ->
    if typeof alpha is "number"
      unscaled = alpha / 100
      return Math.min(Math.max(unscaled, 0.1), 1)
    else
      newAlpha = parseFloat(alpha)
      unless isNaN(newAlpha)
        unscaled = newAlpha / 100
        return Math.min(Math.max(unscaled, 0.1), 1)

  setAlphaScaled: (alpha) ->
    @alpha = @calculateAlphaScaled(alpha)
    @changed()
  
  attach: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose new parent:")
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), =>
        each.add @
        @isDraggable = false
    #
    menu.popUpAtHand @world()  if choices.length
  
  toggleIsDraggable: ->
    # for context menu demo purposes
    @isDraggable = not @isDraggable
  
  colorSetters: ->
    # for context menu demo purposes
    ["color"]
  
  numericalSetters: ->
    # for context menu demo purposes
    ["setLeft", "setTop", "setWidth", "setHeight", "setAlphaScaled"]
  
  
  # Morph entry field tabbing //////////////////////////////////////////////
  
  allEntryFields: ->
    @allChildren().filter (each) ->
      each.isEditable && (each instanceof StringMorph || each instanceof TextMorph);
  
  
  nextEntryField: (current) ->
    fields = @allEntryFields()
    idx = fields.indexOf(current)
    if idx isnt -1
      if fields.length > (idx + 1)
        return fields[idx + 1]
    return fields[0]
  
  previousEntryField: (current) ->
    fields = @allEntryFields()
    idx = fields.indexOf(current)
    if idx isnt -1
      if idx > 0
        return fields[idx - 1]
      return fields[fields.length - 1]
    return fields[0]
  
  tab: (editField) ->
    #
    #	the <tab> key was pressed in one of my edit fields.
    #	invoke my "nextTab()" function if it exists, else
    #	propagate it up my owner chain.
    #
    if @nextTab
      @nextTab editField
    else @parent.tab editField  if @parent
  
  backTab: (editField) ->
    #
    #	the <back tab> key was pressed in one of my edit fields.
    #	invoke my "previousTab()" function if it exists, else
    #	propagate it up my owner chain.
    #
    if @previousTab
      @previousTab editField
    else @parent.backTab editField  if @parent
  
  
  #
  #	the following are examples of what the navigation methods should
  #	look like. Insert these at the World level for fallback, and at lower
  #	levels in the Morphic tree (e.g. dialog boxes) for a more fine-grained
  #	control over the tabbing cycle.
  #
  #Morph.prototype.nextTab = function (editField) {
  #	var	next = this.nextEntryField(editField);
  #	editField.clearSelection();
  #	next.selectAll();
  #	next.edit();
  #};
  #
  #Morph.prototype.previousTab = function (editField) {
  #	var	prev = this.previousEntryField(editField);
  #	editField.clearSelection();
  #	prev.selectAll();
  #	prev.edit();
  #};
  #
  #
  
  # Morph events:
  escalateEvent: (functionName, arg) ->
    handler = @parent
    handler = handler.parent  while not handler[functionName] and handler.parent?
    handler[functionName] arg  if handler[functionName]
  
  
  # Morph eval. Used by the Inspector and the TextMorph.
  evaluateString: (code) ->
    try
      result = eval(code)
      @updateRendering()
      @changed()
    catch err
      @inform err
    result
  
  
  # Morph collision detection - not used anywhere at the moment ////////////////////////
  
  isTouching: (otherMorph) ->
    oImg = @overlappingImage(otherMorph)
    data = oImg.getContext("2d").getImageData(1, 1, oImg.width, oImg.height).data
    detect(data, (each) ->
      each isnt 0
    ) isnt null
  
  overlappingImage: (otherMorph) ->
    fb = @boundsIncludingChildren()
    otherFb = otherMorph.boundsIncludingChildren()
    oRect = fb.intersect(otherFb)
    oImg = newCanvas(oRect.extent())
    ctx = oImg.getContext("2d")
    return newCanvas(new Point(1, 1))  if oRect.width() < 1 or oRect.height() < 1
    ctx.drawImage @fullImage(),
      Math.round(oRect.origin.x - fb.origin.x),
      Math.round(oRect.origin.y - fb.origin.y)
    ctx.globalCompositeOperation = "source-in"
    ctx.drawImage otherMorph.fullImage(),
      Math.round(otherFb.origin.x - oRect.origin.x),
      Math.round(otherFb.origin.y - oRect.origin.y)
    oImg
  '''
# Colors //////////////////////////////////////////////////////////////

class Color

  a: null
  r: null
  g: null
  b: null

  constructor: (@r = 0, @g = 0, @b = 0, a) ->
    # all values are optional, just (r, g, b) is fine
    @a = a or ((if (a is 0) then 0 else 1))
  
  # Color string representation: e.g. 'rgba(255,165,0,1)'
  toString: ->
    "rgba(" + Math.round(@r) + "," + Math.round(@g) + "," + Math.round(@b) + "," + @a + ")"
  
  # Color copying:
  copy: ->
    new Color(@r, @g, @b, @a)
  
  # Color comparison:
  eq: (aColor) ->
    # ==
    aColor and @r is aColor.r and @g is aColor.g and @b is aColor.b
  
  
  # Color conversion (hsv):
  hsv: ->
    # ignore alpha
    rr = @r / 255
    gg = @g / 255
    bb = @b / 255
    max = Math.max(rr, gg, bb)
    min = Math.min(rr, gg, bb)
    h = max
    s = max
    v = max
    d = max - min
    s = (if max is 0 then 0 else d / max)
    if max is min
      h = 0
    else
      switch max
        when rr
          h = (gg - bb) / d + ((if gg < bb then 6 else 0))
        when gg
          h = (bb - rr) / d + 2
        when bb
          h = (rr - gg) / d + 4
      h /= 6
    [h, s, v]
  
  set_hsv: (h, s, v) ->
    # ignore alpha, h, s and v are to be within [0, 1]
    i = Math.floor(h * 6)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    switch i % 6
      when 0
        @r = v
        @g = t
        @b = p
      when 1
        @r = q
        @g = v
        @b = p
      when 2
        @r = p
        @g = v
        @b = t
      when 3
        @r = p
        @g = q
        @b = v
      when 4
        @r = t
        @g = p
        @b = v
      when 5
        @r = v
        @g = p
        @b = q
    @r *= 255
    @g *= 255
    @b *= 255
  
  
  # Color mixing:
  mixed: (proportion, otherColor) ->
    # answer a copy of this color mixed with another color, ignore alpha
    frac1 = Math.min(Math.max(proportion, 0), 1)
    frac2 = 1 - frac1
    new Color(
      @r * frac1 + otherColor.r * frac2,
      @g * frac1 + otherColor.g * frac2,
      @b * frac1 + otherColor.b * frac2)
  
  darker: (percent) ->
    # return an rgb-interpolated darker copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, new Color(0, 0, 0)
  
  lighter: (percent) ->
    # return an rgb-interpolated lighter copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, new Color(255, 255, 255)
  
  dansDarker: ->
    # return an hsv-interpolated darker copy of me, ignore alpha
    hsv = @hsv()
    result = new Color()
    vv = Math.max(hsv[2] - 0.16, 0)
    result.set_hsv hsv[0], hsv[1], vv
    result

  @coffeeScriptSourceOfThisClass: '''
# Colors //////////////////////////////////////////////////////////////

class Color

  a: null
  r: null
  g: null
  b: null

  constructor: (@r = 0, @g = 0, @b = 0, a) ->
    # all values are optional, just (r, g, b) is fine
    @a = a or ((if (a is 0) then 0 else 1))
  
  # Color string representation: e.g. 'rgba(255,165,0,1)'
  toString: ->
    "rgba(" + Math.round(@r) + "," + Math.round(@g) + "," + Math.round(@b) + "," + @a + ")"
  
  # Color copying:
  copy: ->
    new Color(@r, @g, @b, @a)
  
  # Color comparison:
  eq: (aColor) ->
    # ==
    aColor and @r is aColor.r and @g is aColor.g and @b is aColor.b
  
  
  # Color conversion (hsv):
  hsv: ->
    # ignore alpha
    rr = @r / 255
    gg = @g / 255
    bb = @b / 255
    max = Math.max(rr, gg, bb)
    min = Math.min(rr, gg, bb)
    h = max
    s = max
    v = max
    d = max - min
    s = (if max is 0 then 0 else d / max)
    if max is min
      h = 0
    else
      switch max
        when rr
          h = (gg - bb) / d + ((if gg < bb then 6 else 0))
        when gg
          h = (bb - rr) / d + 2
        when bb
          h = (rr - gg) / d + 4
      h /= 6
    [h, s, v]
  
  set_hsv: (h, s, v) ->
    # ignore alpha, h, s and v are to be within [0, 1]
    i = Math.floor(h * 6)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    switch i % 6
      when 0
        @r = v
        @g = t
        @b = p
      when 1
        @r = q
        @g = v
        @b = p
      when 2
        @r = p
        @g = v
        @b = t
      when 3
        @r = p
        @g = q
        @b = v
      when 4
        @r = t
        @g = p
        @b = v
      when 5
        @r = v
        @g = p
        @b = q
    @r *= 255
    @g *= 255
    @b *= 255
  
  
  # Color mixing:
  mixed: (proportion, otherColor) ->
    # answer a copy of this color mixed with another color, ignore alpha
    frac1 = Math.min(Math.max(proportion, 0), 1)
    frac2 = 1 - frac1
    new Color(
      @r * frac1 + otherColor.r * frac2,
      @g * frac1 + otherColor.g * frac2,
      @b * frac1 + otherColor.b * frac2)
  
  darker: (percent) ->
    # return an rgb-interpolated darker copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, new Color(0, 0, 0)
  
  lighter: (percent) ->
    # return an rgb-interpolated lighter copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, new Color(255, 255, 255)
  
  dansDarker: ->
    # return an hsv-interpolated darker copy of me, ignore alpha
    hsv = @hsv()
    result = new Color()
    vv = Math.max(hsv[2] - 0.16, 0)
    result.set_hsv hsv[0], hsv[1], vv
    result
  '''
# TriggerMorph ////////////////////////////////////////////////////////

# I provide basic button functionality

class TriggerMorph extends Morph

  target: null
  action: null
  environment: null
  label: null
  labelString: null
  labelColor: null
  labelBold: null
  labelItalic: null
  doubleClickAction: null
  hint: null
  fontSize: null
  fontStyle: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(192, 192, 192)
  highlightImage: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(128, 128, 128)
  normalImage: null
  pressImage: null

  constructor: (
      @target = null,
      @action = null,
      @labelString = null,
      fontSize,
      fontStyle,
      @environment = null,
      @hint = null,
      labelColor,
      @labelBold = false,
      @labelItalic = false
      @doubleClickAction = null) ->

    # additional properties:
    @fontSize = fontSize or WorldMorph.MorphicPreferences.menuFontSize
    @fontStyle = fontStyle or "sans-serif"
    @labelColor = labelColor or new Color(0, 0, 0)
    #
    super()
    #
    @color = new Color(255, 255, 255)
    @updateRendering()
  
  
  # TriggerMorph drawing:
  updateRendering: ->
    @createBackgrounds()
    @createLabel()  if @labelString isnt null
  
  createBackgrounds: ->
    ext = @extent()
    @normalImage = newCanvas(ext)
    context = @normalImage.getContext("2d")
    context.fillStyle = @color.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @highlightImage = newCanvas(ext)
    context = @highlightImage.getContext("2d")
    context.fillStyle = @highlightColor.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @pressImage = newCanvas(ext)
    context = @pressImage.getContext("2d")
    context.fillStyle = @pressColor.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @image = @normalImage
  
  createLabel: ->
    @label.destroy()  if @label isnt null
    # bold
    # italic
    # numeric
    # shadow offset
    # shadow color
    @label = new StringMorph(
      @labelString,
      @fontSize,
      @fontStyle,
      false,
      false,
      false,
      null,
      null,
      @labelColor,
      @labelBold,
      @labelItalic
    )
    @label.setPosition @center().subtract(@label.extent().floorDivideBy(2))
    @add @label
  
  
  # TriggerMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.label = (dict[@label])  if c.label and dict[@label]
    c
  
  
  # TriggerMorph action:
  trigger: ->
    #
    #	if target is a function, use it as callback:
    #	execute target as callback function with action as argument
    #	in the environment as optionally specified.
    #	Note: if action is also a function, instead of becoming
    #	the argument itself it will be called to answer the argument.
    #	for selections, Yes/No Choices etc. As second argument pass
    # myself, so I can be modified to reflect status changes, e.g.
    # inside a list box:
    #
    #	else (if target is not a function):
    #
    #		if action is a function:
    #		execute the action with target as environment (can be null)
    #		for lambdafied (inline) actions
    #
    #		else if action is a String:
    #		treat it as function property of target and execute it
    #		for selector-like actions
    #	
    if typeof @target is "function"
      if typeof @action is "function"
        @target.call @environment, @action.call(), @
      else
        @target.call @environment, @action, @
    else
      if typeof @action is "function"
        @action.call @target
      else # assume it's a String
        @target[@action]()

  triggerDoubleClick: ->
    # same as trigger() but use doubleClickAction instead of action property
    # note that specifying a doubleClickAction is optional
    return  unless @doubleClickAction
    if typeof @target is "function"
      if typeof @doubleClickAction is "function"
        @target.call @environment, @doubleClickAction.call(), this
      else
        @target.call @environment, @doubleClickAction, this
    else
      if typeof @doubleClickAction is "function"
        @doubleClickAction.call @target
      else # assume it's a String
        @target[@doubleClickAction]()  
  
  # TriggerMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
    @bubbleHelp @hint  if @hint
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
    @world().hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: ->
    @image = @pressImage
    @changed()
  
  mouseClickLeft: ->
    @image = @highlightImage
    @changed()
    @trigger()

  mouseDoubleClick: ->
    @triggerDoubleClick()

  # Disable dragging compound Morphs by Triggers
  # User can still move the trigger itself though
  # (it it's unlocked)
  rootForGrab: ->
    if @isDraggable
      return super()
    null
  
  # TriggerMorph bubble help:
  bubbleHelp: (contents) ->
    @fps = 2
    @step = =>
      @popUpbubbleHelp contents  if @bounds.containsPoint(@world().hand.position())
      @fps = 0
      delete @step
  
  popUpbubbleHelp: (contents) ->
    new SpeechBubbleMorph(
      localize(contents), null, null, 1).popUp @world(),
      @rightCenter().add(new Point(-8, 0))

  @coffeeScriptSourceOfThisClass: '''
# TriggerMorph ////////////////////////////////////////////////////////

# I provide basic button functionality

class TriggerMorph extends Morph

  target: null
  action: null
  environment: null
  label: null
  labelString: null
  labelColor: null
  labelBold: null
  labelItalic: null
  doubleClickAction: null
  hint: null
  fontSize: null
  fontStyle: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(192, 192, 192)
  highlightImage: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(128, 128, 128)
  normalImage: null
  pressImage: null

  constructor: (
      @target = null,
      @action = null,
      @labelString = null,
      fontSize,
      fontStyle,
      @environment = null,
      @hint = null,
      labelColor,
      @labelBold = false,
      @labelItalic = false
      @doubleClickAction = null) ->

    # additional properties:
    @fontSize = fontSize or WorldMorph.MorphicPreferences.menuFontSize
    @fontStyle = fontStyle or "sans-serif"
    @labelColor = labelColor or new Color(0, 0, 0)
    #
    super()
    #
    @color = new Color(255, 255, 255)
    @updateRendering()
  
  
  # TriggerMorph drawing:
  updateRendering: ->
    @createBackgrounds()
    @createLabel()  if @labelString isnt null
  
  createBackgrounds: ->
    ext = @extent()
    @normalImage = newCanvas(ext)
    context = @normalImage.getContext("2d")
    context.fillStyle = @color.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @highlightImage = newCanvas(ext)
    context = @highlightImage.getContext("2d")
    context.fillStyle = @highlightColor.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @pressImage = newCanvas(ext)
    context = @pressImage.getContext("2d")
    context.fillStyle = @pressColor.toString()
    context.fillRect 0, 0, ext.x, ext.y
    @image = @normalImage
  
  createLabel: ->
    @label.destroy()  if @label isnt null
    # bold
    # italic
    # numeric
    # shadow offset
    # shadow color
    @label = new StringMorph(
      @labelString,
      @fontSize,
      @fontStyle,
      false,
      false,
      false,
      null,
      null,
      @labelColor,
      @labelBold,
      @labelItalic
    )
    @label.setPosition @center().subtract(@label.extent().floorDivideBy(2))
    @add @label
  
  
  # TriggerMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.label = (dict[@label])  if c.label and dict[@label]
    c
  
  
  # TriggerMorph action:
  trigger: ->
    #
    #	if target is a function, use it as callback:
    #	execute target as callback function with action as argument
    #	in the environment as optionally specified.
    #	Note: if action is also a function, instead of becoming
    #	the argument itself it will be called to answer the argument.
    #	for selections, Yes/No Choices etc. As second argument pass
    # myself, so I can be modified to reflect status changes, e.g.
    # inside a list box:
    #
    #	else (if target is not a function):
    #
    #		if action is a function:
    #		execute the action with target as environment (can be null)
    #		for lambdafied (inline) actions
    #
    #		else if action is a String:
    #		treat it as function property of target and execute it
    #		for selector-like actions
    #	
    if typeof @target is "function"
      if typeof @action is "function"
        @target.call @environment, @action.call(), @
      else
        @target.call @environment, @action, @
    else
      if typeof @action is "function"
        @action.call @target
      else # assume it's a String
        @target[@action]()

  triggerDoubleClick: ->
    # same as trigger() but use doubleClickAction instead of action property
    # note that specifying a doubleClickAction is optional
    return  unless @doubleClickAction
    if typeof @target is "function"
      if typeof @doubleClickAction is "function"
        @target.call @environment, @doubleClickAction.call(), this
      else
        @target.call @environment, @doubleClickAction, this
    else
      if typeof @doubleClickAction is "function"
        @doubleClickAction.call @target
      else # assume it's a String
        @target[@doubleClickAction]()  
  
  # TriggerMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
    @bubbleHelp @hint  if @hint
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
    @world().hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: ->
    @image = @pressImage
    @changed()
  
  mouseClickLeft: ->
    @image = @highlightImage
    @changed()
    @trigger()

  mouseDoubleClick: ->
    @triggerDoubleClick()

  # Disable dragging compound Morphs by Triggers
  # User can still move the trigger itself though
  # (it it's unlocked)
  rootForGrab: ->
    if @isDraggable
      return super()
    null
  
  # TriggerMorph bubble help:
  bubbleHelp: (contents) ->
    @fps = 2
    @step = =>
      @popUpbubbleHelp contents  if @bounds.containsPoint(@world().hand.position())
      @fps = 0
      delete @step
  
  popUpbubbleHelp: (contents) ->
    new SpeechBubbleMorph(
      localize(contents), null, null, 1).popUp @world(),
      @rightCenter().add(new Point(-8, 0))
  '''
# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph

  # labelString can also be a Morph or a Canvas or a tuple: [icon, string]
  constructor: (target, action, labelString, fontSize, fontStyle, environment, hint, color, bold, italic, doubleClickAction) ->
    super target, action, labelString, fontSize, fontStyle, environment, hint, color, bold, italic, doubleClickAction 
  
  createLabel: ->
    @label.destroy()  if @label isnt null

    if isString(@labelString)
      @label = @createLabelString(@labelString)
    else if @labelString instanceof Array      
      # assume its pattern is: [icon, string] 
      @label = new Morph()
      @label.alpha = 0 # transparent

      icon = @createIcon(@labelString[0])
      @label.add icon
      lbl = @createLabelString(@labelString[1])
      @label.add lbl

      lbl.setCenter icon.center()
      lbl.setLeft icon.right() + 4
      @label.bounds = (icon.bounds.merge(lbl.bounds))
      @label.updateRendering()
    else # assume it's either a Morph or a Canvas
      @label = @createIcon(@labelString)
  
    @silentSetExtent @label.extent().add(new Point(8, 0))
    np = @position().add(new Point(4, 0))
    @label.bounds = np.extent(@label.extent())
    @add @label
  
  createIcon: (source) ->
    # source can be either a Morph or an HTMLCanvasElement
    icon = new Morph()
    icon.image = (if source instanceof Morph then source.fullImage() else source)

    # adjust shadow dimensions
    if source instanceof Morph and source.getShadow()
      src = icon.image
      icon.image = newCanvas(
        source.fullBounds().extent().subtract(
          @shadowBlur * ((if useBlurredShadows then 1 else 2))))
      icon.image.getContext("2d").drawImage src, 0, 0

    icon.silentSetWidth icon.image.width
    icon.silentSetHeight icon.image.height
    icon

  createLabelString: (string) ->
    lbl = new TextMorph(string, @fontSize, @fontStyle)
    lbl.setColor @labelColor
    lbl  

  # MenuItemMorph events:
  mouseEnter: ->
    unless @isListItem()
      @image = @highlightImage
      @changed()
    @bubbleHelp @hint  if @hint
  
  mouseLeave: ->
    unless @isListItem()
      @image = @normalImage
      @changed()
    @world().hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    @image = @pressImage
    @changed()
  
  mouseMove: ->
    @escalateEvent "mouseMove"  if @isListItem()
  
  mouseClickLeft: ->
    unless @isListItem()
      @parent.destroy()
      @root().activeMenu = null
    @trigger()
  
  isListItem: ->
    return @parent.isListContents  if @parent
    false
  
  isSelectedListItem: ->
    return @image is @pressImage  if @isListItem()
    false

  @coffeeScriptSourceOfThisClass: '''
# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph

  # labelString can also be a Morph or a Canvas or a tuple: [icon, string]
  constructor: (target, action, labelString, fontSize, fontStyle, environment, hint, color, bold, italic, doubleClickAction) ->
    super target, action, labelString, fontSize, fontStyle, environment, hint, color, bold, italic, doubleClickAction 
  
  createLabel: ->
    @label.destroy()  if @label isnt null

    if isString(@labelString)
      @label = @createLabelString(@labelString)
    else if @labelString instanceof Array      
      # assume its pattern is: [icon, string] 
      @label = new Morph()
      @label.alpha = 0 # transparent

      icon = @createIcon(@labelString[0])
      @label.add icon
      lbl = @createLabelString(@labelString[1])
      @label.add lbl

      lbl.setCenter icon.center()
      lbl.setLeft icon.right() + 4
      @label.bounds = (icon.bounds.merge(lbl.bounds))
      @label.updateRendering()
    else # assume it's either a Morph or a Canvas
      @label = @createIcon(@labelString)
  
    @silentSetExtent @label.extent().add(new Point(8, 0))
    np = @position().add(new Point(4, 0))
    @label.bounds = np.extent(@label.extent())
    @add @label
  
  createIcon: (source) ->
    # source can be either a Morph or an HTMLCanvasElement
    icon = new Morph()
    icon.image = (if source instanceof Morph then source.fullImage() else source)

    # adjust shadow dimensions
    if source instanceof Morph and source.getShadow()
      src = icon.image
      icon.image = newCanvas(
        source.fullBounds().extent().subtract(
          @shadowBlur * ((if useBlurredShadows then 1 else 2))))
      icon.image.getContext("2d").drawImage src, 0, 0

    icon.silentSetWidth icon.image.width
    icon.silentSetHeight icon.image.height
    icon

  createLabelString: (string) ->
    lbl = new TextMorph(string, @fontSize, @fontStyle)
    lbl.setColor @labelColor
    lbl  

  # MenuItemMorph events:
  mouseEnter: ->
    unless @isListItem()
      @image = @highlightImage
      @changed()
    @bubbleHelp @hint  if @hint
  
  mouseLeave: ->
    unless @isListItem()
      @image = @normalImage
      @changed()
    @world().hand.destroyTemporaries()  if @hint
  
  mouseDownLeft: (pos) ->
    if @isListItem()
      @parent.unselectAllItems()
      @escalateEvent "mouseDownLeft", pos
    @image = @pressImage
    @changed()
  
  mouseMove: ->
    @escalateEvent "mouseMove"  if @isListItem()
  
  mouseClickLeft: ->
    unless @isListItem()
      @parent.destroy()
      @root().activeMenu = null
    @trigger()
  
  isListItem: ->
    return @parent.isListContents  if @parent
    false
  
  isSelectedListItem: ->
    return @image is @pressImage  if @isListItem()
    false
  '''
# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders

class CircleBoxMorph extends Morph

  orientation: null
  autoOrient: true

  constructor: (@orientation = "vertical") ->
    super()
    @setExtent new Point(20, 100)
  
  autoOrientation: ->
    if @height() > @width()
      @orientation = "vertical"
    else
      @orientation = "horizontal"
  
  updateRendering: ->
    @autoOrientation()  if @autoOrient
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    if @orientation is "vertical"
      radius = @width() / 2
      x = @center().x
      center1 = new Point(x, @top() + radius)
      center2 = new Point(x, @bottom() - radius)
      rect = @bounds.origin.add(
        new Point(0, radius)).corner(@bounds.corner.subtract(new Point(0, radius)))
    else
      radius = @height() / 2
      y = @center().y
      center1 = new Point(@left() + radius, y)
      center2 = new Point(@right() - radius, y)
      rect = @bounds.origin.add(
        new Point(radius, 0)).corner(@bounds.corner.subtract(new Point(radius, 0)))
    points = [center1.subtract(@bounds.origin), center2.subtract(@bounds.origin)]
    points.forEach (center) =>
      context.fillStyle = @color.toString()
      context.beginPath()
      context.arc center.x, center.y, radius, 0, 2 * Math.PI, false
      context.closePath()
      context.fill()
    rect = rect.translateBy(@bounds.origin.neg())
    ext = rect.extent()
    if ext.x > 0 and ext.y > 0
      context.fillRect rect.origin.x, rect.origin.y, rect.width(), rect.height()
  
  
  # CircleBoxMorph menu:
  developersMenu: ->
    menu = super()
    menu.addLine()
    if @orientation is "vertical"
      menu.addItem "horizontal...", "toggleOrientation", "toggle the\norientation"
    else
      menu.addItem "vertical...", "toggleOrientation", "toggle the\norientation"
    menu
  
  toggleOrientation: ->
    center = @center()
    @changed()
    if @orientation is "vertical"
      @orientation = "horizontal"
    else
      @orientation = "vertical"
    @silentSetExtent new Point(@height(), @width())
    @setCenter center
    @updateRendering()
    @changed()

  @coffeeScriptSourceOfThisClass: '''
# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders

class CircleBoxMorph extends Morph

  orientation: null
  autoOrient: true

  constructor: (@orientation = "vertical") ->
    super()
    @setExtent new Point(20, 100)
  
  autoOrientation: ->
    if @height() > @width()
      @orientation = "vertical"
    else
      @orientation = "horizontal"
  
  updateRendering: ->
    @autoOrientation()  if @autoOrient
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    if @orientation is "vertical"
      radius = @width() / 2
      x = @center().x
      center1 = new Point(x, @top() + radius)
      center2 = new Point(x, @bottom() - radius)
      rect = @bounds.origin.add(
        new Point(0, radius)).corner(@bounds.corner.subtract(new Point(0, radius)))
    else
      radius = @height() / 2
      y = @center().y
      center1 = new Point(@left() + radius, y)
      center2 = new Point(@right() - radius, y)
      rect = @bounds.origin.add(
        new Point(radius, 0)).corner(@bounds.corner.subtract(new Point(radius, 0)))
    points = [center1.subtract(@bounds.origin), center2.subtract(@bounds.origin)]
    points.forEach (center) =>
      context.fillStyle = @color.toString()
      context.beginPath()
      context.arc center.x, center.y, radius, 0, 2 * Math.PI, false
      context.closePath()
      context.fill()
    rect = rect.translateBy(@bounds.origin.neg())
    ext = rect.extent()
    if ext.x > 0 and ext.y > 0
      context.fillRect rect.origin.x, rect.origin.y, rect.width(), rect.height()
  
  
  # CircleBoxMorph menu:
  developersMenu: ->
    menu = super()
    menu.addLine()
    if @orientation is "vertical"
      menu.addItem "horizontal...", "toggleOrientation", "toggle the\norientation"
    else
      menu.addItem "vertical...", "toggleOrientation", "toggle the\norientation"
    menu
  
  toggleOrientation: ->
    center = @center()
    @changed()
    if @orientation is "vertical"
      @orientation = "horizontal"
    else
      @orientation = "vertical"
    @silentSetExtent new Point(@height(), @width())
    @setCenter center
    @updateRendering()
    @changed()
  '''
# PenMorph ////////////////////////////////////////////////////////////

# I am a simple LOGO-wise turtle.

class PenMorph extends Morph
  
  heading: 0
  penSize: null
  isWarped: false # internal optimization
  isDown: true
  wantsRedraw: false # internal optimization
  penPoint: 'tip' # or 'center'
  
  constructor: () ->
    @penSize = WorldMorph.MorphicPreferences.handleSize * 4
    super()
    @setExtent new Point(@penSize, @penSize)
    # todo we need to change the size two times, for getting the right size
    # of the arrow and of the line. Probably should make the two distinct
    @penSize = 1
    #alert @morphMethod() # works
    # doesn't work cause coffeescript doesn't support static inheritance
    #alert @morphStaticMethod()

  @staticVariable: 1
  @staticFunction: -> 3.14
    
  # PenMorph updating - optimized for warping, i.e atomic recursion
  changed: ->
    if @isWarped is false
      w = @root()
      w.broken.push @visibleBounds().spread()  if w instanceof WorldMorph
      @parent.childChanged @  if @parent
  
  
  # PenMorph display:
  updateRendering: (facing) ->
    #
    #    my orientation can be overridden with the "facing" parameter to
    #    implement Scratch-style rotation styles
    #    
    #
    direction = facing or @heading
    if @isWarped
      @wantsRedraw = true
      return
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    len = @width() / 2
    start = @center().subtract(@bounds.origin)

    if @penPoint is "tip"
      dest = start.distanceAngle(len * 0.75, direction - 180)
      left = start.distanceAngle(len, direction + 195)
      right = start.distanceAngle(len, direction - 195)
    else # 'middle'
      dest = start.distanceAngle(len * 0.75, direction)
      left = start.distanceAngle(len * 0.33, direction + 230)
      right = start.distanceAngle(len * 0.33, direction - 230)

    context.fillStyle = @color.toString()
    context.beginPath()

    context.moveTo start.x, start.y
    context.lineTo left.x, left.y
    context.lineTo dest.x, dest.y
    context.lineTo right.x, right.y

    context.closePath()
    context.strokeStyle = "white"
    context.lineWidth = 3
    context.stroke()
    context.strokeStyle = "black"
    context.lineWidth = 1
    context.stroke()
    context.fill()
    @wantsRedraw = false
  
  
  # PenMorph access:
  setHeading: (degrees) ->
    @heading = parseFloat(degrees) % 360
    @updateRendering()
    @changed()
  
  
  # PenMorph drawing:
  drawLine: (start, dest) ->
    context = @parent.penTrails().getContext("2d")
    from = start.subtract(@parent.bounds.origin)
    to = dest.subtract(@parent.bounds.origin)
    if @isDown
      context.lineWidth = @penSize
      context.strokeStyle = @color.toString()
      context.lineCap = "round"
      context.lineJoin = "round"
      context.beginPath()
      context.moveTo from.x, from.y
      context.lineTo to.x, to.y
      context.stroke()
      if @isWarped is false
        @world().broken.push start.rectangle(dest).expandBy(Math.max(@penSize / 2, 1)).intersect(@parent.visibleBounds()).spread()
  
  
  # PenMorph turtle ops:
  turn: (degrees) ->
    @setHeading @heading + parseFloat(degrees)
  
  forward: (steps) ->
    start = @center()
    dist = parseFloat(steps)
    if dist >= 0
      dest = @position().distanceAngle(dist, @heading)
    else
      dest = @position().distanceAngle(Math.abs(dist), (@heading - 180))
    @setPosition dest
    @drawLine start, @center()
  
  down: ->
    @isDown = true
  
  up: ->
    @isDown = false
  
  clear: ->
    @parent.updateRendering()
    @parent.changed()
  
  
  # PenMorph optimization for atomic recursion:
  startWarp: ->
    @wantsRedraw = false
    @isWarped = true
  
  endWarp: ->
    @isWarped = false
    if @wantsRedraw
      @updateRendering()
      @wantsRedraw = false
    @parent.changed()
  
  warp: (fun) ->
    @startWarp()
    fun.call @
    @endWarp()
  
  warpOp: (selector, argsArray) ->
    @startWarp()
    @[selector].apply @, argsArray
    @endWarp()
  
  
  # PenMorph demo ops:
  # try these with WARP eg.: this.warp(function () {tree(12, 120, 20)})
  warpSierpinski: (length, min) ->
    @warpOp "sierpinski", [length, min]
  
  sierpinski: (length, min) ->
    if length > min
      for i in [0...3]
        @sierpinski length * 0.5, min
        @turn 120
        @forward length
  
  warpTree: (level, length, angle) ->
    @warpOp "tree", [level, length, angle]
  
  tree: (level, length, angle) ->
    if level > 0
      @penSize = level
      @forward length
      @turn angle
      @tree level - 1, length * 0.75, angle
      @turn angle * -2
      @tree level - 1, length * 0.75, angle
      @turn angle
      @forward -length

  @coffeeScriptSourceOfThisClass: '''
# PenMorph ////////////////////////////////////////////////////////////

# I am a simple LOGO-wise turtle.

class PenMorph extends Morph
  
  heading: 0
  penSize: null
  isWarped: false # internal optimization
  isDown: true
  wantsRedraw: false # internal optimization
  penPoint: 'tip' # or 'center'
  
  constructor: () ->
    @penSize = WorldMorph.MorphicPreferences.handleSize * 4
    super()
    @setExtent new Point(@penSize, @penSize)
    # todo we need to change the size two times, for getting the right size
    # of the arrow and of the line. Probably should make the two distinct
    @penSize = 1
    #alert @morphMethod() # works
    # doesn't work cause coffeescript doesn't support static inheritance
    #alert @morphStaticMethod()

  @staticVariable: 1
  @staticFunction: -> 3.14
    
  # PenMorph updating - optimized for warping, i.e atomic recursion
  changed: ->
    if @isWarped is false
      w = @root()
      w.broken.push @visibleBounds().spread()  if w instanceof WorldMorph
      @parent.childChanged @  if @parent
  
  
  # PenMorph display:
  updateRendering: (facing) ->
    #
    #    my orientation can be overridden with the "facing" parameter to
    #    implement Scratch-style rotation styles
    #    
    #
    direction = facing or @heading
    if @isWarped
      @wantsRedraw = true
      return
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    len = @width() / 2
    start = @center().subtract(@bounds.origin)

    if @penPoint is "tip"
      dest = start.distanceAngle(len * 0.75, direction - 180)
      left = start.distanceAngle(len, direction + 195)
      right = start.distanceAngle(len, direction - 195)
    else # 'middle'
      dest = start.distanceAngle(len * 0.75, direction)
      left = start.distanceAngle(len * 0.33, direction + 230)
      right = start.distanceAngle(len * 0.33, direction - 230)

    context.fillStyle = @color.toString()
    context.beginPath()

    context.moveTo start.x, start.y
    context.lineTo left.x, left.y
    context.lineTo dest.x, dest.y
    context.lineTo right.x, right.y

    context.closePath()
    context.strokeStyle = "white"
    context.lineWidth = 3
    context.stroke()
    context.strokeStyle = "black"
    context.lineWidth = 1
    context.stroke()
    context.fill()
    @wantsRedraw = false
  
  
  # PenMorph access:
  setHeading: (degrees) ->
    @heading = parseFloat(degrees) % 360
    @updateRendering()
    @changed()
  
  
  # PenMorph drawing:
  drawLine: (start, dest) ->
    context = @parent.penTrails().getContext("2d")
    from = start.subtract(@parent.bounds.origin)
    to = dest.subtract(@parent.bounds.origin)
    if @isDown
      context.lineWidth = @penSize
      context.strokeStyle = @color.toString()
      context.lineCap = "round"
      context.lineJoin = "round"
      context.beginPath()
      context.moveTo from.x, from.y
      context.lineTo to.x, to.y
      context.stroke()
      if @isWarped is false
        @world().broken.push start.rectangle(dest).expandBy(Math.max(@penSize / 2, 1)).intersect(@parent.visibleBounds()).spread()
  
  
  # PenMorph turtle ops:
  turn: (degrees) ->
    @setHeading @heading + parseFloat(degrees)
  
  forward: (steps) ->
    start = @center()
    dist = parseFloat(steps)
    if dist >= 0
      dest = @position().distanceAngle(dist, @heading)
    else
      dest = @position().distanceAngle(Math.abs(dist), (@heading - 180))
    @setPosition dest
    @drawLine start, @center()
  
  down: ->
    @isDown = true
  
  up: ->
    @isDown = false
  
  clear: ->
    @parent.updateRendering()
    @parent.changed()
  
  
  # PenMorph optimization for atomic recursion:
  startWarp: ->
    @wantsRedraw = false
    @isWarped = true
  
  endWarp: ->
    @isWarped = false
    if @wantsRedraw
      @updateRendering()
      @wantsRedraw = false
    @parent.changed()
  
  warp: (fun) ->
    @startWarp()
    fun.call @
    @endWarp()
  
  warpOp: (selector, argsArray) ->
    @startWarp()
    @[selector].apply @, argsArray
    @endWarp()
  
  
  # PenMorph demo ops:
  # try these with WARP eg.: this.warp(function () {tree(12, 120, 20)})
  warpSierpinski: (length, min) ->
    @warpOp "sierpinski", [length, min]
  
  sierpinski: (length, min) ->
    if length > min
      for i in [0...3]
        @sierpinski length * 0.5, min
        @turn 120
        @forward length
  
  warpTree: (level, length, angle) ->
    @warpOp "tree", [level, length, angle]
  
  tree: (level, length, angle) ->
    if level > 0
      @penSize = level
      @forward length
      @turn angle
      @tree level - 1, length * 0.75, angle
      @turn angle * -2
      @tree level - 1, length * 0.75, angle
      @turn angle
      @forward -length
  '''
# Point2 //////////////////////////////////////////////////////////////
# like Point, but it tries not to create new objects like there is
# no tomorrow. Any operation that returned a new point now directly
# modifies the current point.
# Note that the arguments passed to any of these functions are never
# modified.

class Point2

  x: null
  y: null
   
  constructor: (@x = 0, @y = 0) ->
  
  # Point2 string representation: e.g. '12@68'
  toString: ->
    Math.round(@x.toString()) + "@" + Math.round(@y.toString())
  
  # Point2 copying:
  copy: ->
    new Point2(@x, @y)
  
  # Point2 comparison:
  eq: (aPoint2) ->
    # ==
    @x is aPoint2.x and @y is aPoint2.y
  
  lt: (aPoint2) ->
    # <
    @x < aPoint2.x and @y < aPoint2.y
  
  gt: (aPoint2) ->
    # >
    @x > aPoint2.x and @y > aPoint2.y
  
  ge: (aPoint2) ->
    # >=
    @x >= aPoint2.x and @y >= aPoint2.y
  
  le: (aPoint2) ->
    # <=
    @x <= aPoint2.x and @y <= aPoint2.y
  
  max: (aPoint2) ->
    #new Point2(Math.max(@x, aPoint2.x), Math.max(@y, aPoint2.y))
    @x = Math.max(@x, aPoint2.x)
    @y = Math.max(@y, aPoint2.y)
  
  min: (aPoint2) ->
    #new Point2(Math.min(@x, aPoint2.x), Math.min(@y, aPoint2.y))
    @x = Math.min(@x, aPoint2.x)
    @y = Math.min(@y, aPoint2.y)
  
  
  # Point2 conversion:
  round: ->
    #new Point2(Math.round(@x), Math.round(@y))
    @x = Math.round(@x)
    @y = Math.round(@y)
  
  abs: ->
    #new Point2(Math.abs(@x), Math.abs(@y))
    @x = Math.abs(@x)
    @y = Math.abs(@y)
  
  neg: ->
    #new Point2(-@x, -@y)
    @x = -@x
    @y = -@y
  
  mirror: ->
    #new Point2(@y, @x)
    # note that coffeescript would allow [@x,@y] = [@y,@x]
    # but we want to be faster here
    tmpValueForSwappingXAndY = @x
    @x = @y
    @y = tmpValueForSwappingXAndY 
  
  floor: ->
    #new Point2(Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0))
    @x = Math.max(Math.floor(@x), 0)
    @y = Math.max(Math.floor(@y), 0)
  
  ceil: ->
    #new Point2(Math.ceil(@x), Math.ceil(@y))
    @x = Math.ceil(@x)
    @y = Math.ceil(@y)
  
  
  # Point2 arithmetic:
  add: (other) ->
    if other instanceof Point2
      @x = @x + other.x
      @y = @y + other.y
      return
    @x = @x + other
    @y = @y + other
  
  subtract: (other) ->
    if other instanceof Point2
      @x = @x - other.x
      @y = @y - other.y
      return
    @x = @x - other
    @y = @y - other
  
  multiplyBy: (other) ->
    if other instanceof Point2
      @x = @x * other.x
      @y = @y * other.y
      return
    @x = @x * other
    @y = @y * other
  
  divideBy: (other) ->
    if other instanceof Point2
      @x = @x / other.x
      @y = @y / other.y
      return
    @x = @x / other
    @y = @y / other
  
  floorDivideBy: (other) ->
    if other instanceof Point2
      @x = Math.floor(@x / other.x)
      @y = Math.floor(@y / other.y)
      return
    @x = Math.floor(@x / other)
    @y = Math.floor(@y / other)
  
  
  # Point2 polar coordinates:
  # distance from the origin
  r: ->
    t = @copy()
    t.multiplyBy(t)
    Math.sqrt t.x + t.y
  
  degrees: ->
    #
    #    answer the angle I make with origin in degrees.
    #    Right is 0, down is 90
    #
    if @x is 0
      return 90  if @y >= 0
      return 270
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return degrees(theta)  if @y >= 0
      return 360 + (degrees(theta))
    180 + degrees(theta)
  
  theta: ->
    #
    #    answer the angle I make with origin in radians.
    #    Right is 0, down is 90
    #
    if @x is 0
      return radians(90)  if @y >= 0
      return radians(270)
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return theta  if @y >= 0
      return radians(360) + theta
    radians(180) + theta
  
  
  # Point2 functions:
  
  # this function is a bit fishy.
  # a cross product in 2d is probably not a vector
  # see https://github.com/jmoenig/morphic.js/issues/6
  # this function is not used
  crossProduct: (aPoint2) ->
    @multiplyBy aPoint2.copy().mirror()
  
  distanceTo: (aPoint2) ->
    (aPoint2.copy().subtract(@)).r()
  
  rotate: (direction, center) ->
    # direction must be 'right', 'left' or 'pi'
    offset = @copy().subtract(center)
    if direction is "right"
      @x = -offset.y + center.x
      @y = offset.y + center.y
      return
    if direction is "left"
      @x = offset.y + center.x
      @y = -offset.y + center.y
      return
    #
    # direction === 'pi'
    tmpPointForRotate = center.copy().subtract offset
    @x = tmpPointForRotate.x
    @y = tmpPointForRotate.y
  
  flip: (direction, center) ->
    # direction must be 'vertical' or 'horizontal'
    if direction is "vertical"
      @y = center.y * 2 - @y
      return
    #
    # direction === 'horizontal'
    @x = center.x * 2 - @x
  
  distanceAngle: (dist, angle) ->
    deg = angle
    if deg > 270
      deg = deg - 360
    else deg = deg + 360  if deg < -270
    if -90 <= deg and deg <= 90
      x = Math.sin(radians(deg)) * dist
      y = Math.sqrt((dist * dist) - (x * x))
      @x = x + @x
      @y = @y - y
      return
    x = Math.sin(radians(180 - deg)) * dist
    y = Math.sqrt((dist * dist) - (x * x))
    @x = x + @x
    @y = @y + y
  
  
  # Point2 transforming:
  scaleBy: (scalePoint2) ->
    @multiplyBy scalePoint2
  
  translateBy: (deltaPoint2) ->
    @add deltaPoint2
  
  rotateBy: (angle, centerPoint2) ->
    center = centerPoint2 or new Point2(0, 0)
    p = @copy().subtract(center)
    r = p.r()
    theta = angle - p.theta()
    @x = center.x + (r * Math.cos(theta))
    @y = center.y - (r * Math.sin(theta))
  
  
  # Point2 conversion:
  asArray: ->
    [@x, @y]
  
  # creating Rectangle instances from Point2:
  corner: (cornerPoint2) ->
    # answer a new Rectangle
    new Rectangle(@x, @y, cornerPoint2.x, cornerPoint2.y)
  
  rectangle: (aPoint2) ->
    # answer a new Rectangle
    org = @copy().min(aPoint2)
    crn = @copy().max(aPoint2)
    new Rectangle(org.x, org.y, crn.x, crn.y)
  
  extent: (aPoint2) ->
    #answer a new Rectangle
    crn = @copy().add(aPoint2)
    new Rectangle(@x, @y, crn.x, crn.y)

  @coffeeScriptSourceOfThisClass: '''
# Point2 //////////////////////////////////////////////////////////////
# like Point, but it tries not to create new objects like there is
# no tomorrow. Any operation that returned a new point now directly
# modifies the current point.
# Note that the arguments passed to any of these functions are never
# modified.

class Point2

  x: null
  y: null
   
  constructor: (@x = 0, @y = 0) ->
  
  # Point2 string representation: e.g. '12@68'
  toString: ->
    Math.round(@x.toString()) + "@" + Math.round(@y.toString())
  
  # Point2 copying:
  copy: ->
    new Point2(@x, @y)
  
  # Point2 comparison:
  eq: (aPoint2) ->
    # ==
    @x is aPoint2.x and @y is aPoint2.y
  
  lt: (aPoint2) ->
    # <
    @x < aPoint2.x and @y < aPoint2.y
  
  gt: (aPoint2) ->
    # >
    @x > aPoint2.x and @y > aPoint2.y
  
  ge: (aPoint2) ->
    # >=
    @x >= aPoint2.x and @y >= aPoint2.y
  
  le: (aPoint2) ->
    # <=
    @x <= aPoint2.x and @y <= aPoint2.y
  
  max: (aPoint2) ->
    #new Point2(Math.max(@x, aPoint2.x), Math.max(@y, aPoint2.y))
    @x = Math.max(@x, aPoint2.x)
    @y = Math.max(@y, aPoint2.y)
  
  min: (aPoint2) ->
    #new Point2(Math.min(@x, aPoint2.x), Math.min(@y, aPoint2.y))
    @x = Math.min(@x, aPoint2.x)
    @y = Math.min(@y, aPoint2.y)
  
  
  # Point2 conversion:
  round: ->
    #new Point2(Math.round(@x), Math.round(@y))
    @x = Math.round(@x)
    @y = Math.round(@y)
  
  abs: ->
    #new Point2(Math.abs(@x), Math.abs(@y))
    @x = Math.abs(@x)
    @y = Math.abs(@y)
  
  neg: ->
    #new Point2(-@x, -@y)
    @x = -@x
    @y = -@y
  
  mirror: ->
    #new Point2(@y, @x)
    # note that coffeescript would allow [@x,@y] = [@y,@x]
    # but we want to be faster here
    tmpValueForSwappingXAndY = @x
    @x = @y
    @y = tmpValueForSwappingXAndY 
  
  floor: ->
    #new Point2(Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0))
    @x = Math.max(Math.floor(@x), 0)
    @y = Math.max(Math.floor(@y), 0)
  
  ceil: ->
    #new Point2(Math.ceil(@x), Math.ceil(@y))
    @x = Math.ceil(@x)
    @y = Math.ceil(@y)
  
  
  # Point2 arithmetic:
  add: (other) ->
    if other instanceof Point2
      @x = @x + other.x
      @y = @y + other.y
      return
    @x = @x + other
    @y = @y + other
  
  subtract: (other) ->
    if other instanceof Point2
      @x = @x - other.x
      @y = @y - other.y
      return
    @x = @x - other
    @y = @y - other
  
  multiplyBy: (other) ->
    if other instanceof Point2
      @x = @x * other.x
      @y = @y * other.y
      return
    @x = @x * other
    @y = @y * other
  
  divideBy: (other) ->
    if other instanceof Point2
      @x = @x / other.x
      @y = @y / other.y
      return
    @x = @x / other
    @y = @y / other
  
  floorDivideBy: (other) ->
    if other instanceof Point2
      @x = Math.floor(@x / other.x)
      @y = Math.floor(@y / other.y)
      return
    @x = Math.floor(@x / other)
    @y = Math.floor(@y / other)
  
  
  # Point2 polar coordinates:
  # distance from the origin
  r: ->
    t = @copy()
    t.multiplyBy(t)
    Math.sqrt t.x + t.y
  
  degrees: ->
    #
    #    answer the angle I make with origin in degrees.
    #    Right is 0, down is 90
    #
    if @x is 0
      return 90  if @y >= 0
      return 270
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return degrees(theta)  if @y >= 0
      return 360 + (degrees(theta))
    180 + degrees(theta)
  
  theta: ->
    #
    #    answer the angle I make with origin in radians.
    #    Right is 0, down is 90
    #
    if @x is 0
      return radians(90)  if @y >= 0
      return radians(270)
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return theta  if @y >= 0
      return radians(360) + theta
    radians(180) + theta
  
  
  # Point2 functions:
  
  # this function is a bit fishy.
  # a cross product in 2d is probably not a vector
  # see https://github.com/jmoenig/morphic.js/issues/6
  # this function is not used
  crossProduct: (aPoint2) ->
    @multiplyBy aPoint2.copy().mirror()
  
  distanceTo: (aPoint2) ->
    (aPoint2.copy().subtract(@)).r()
  
  rotate: (direction, center) ->
    # direction must be 'right', 'left' or 'pi'
    offset = @copy().subtract(center)
    if direction is "right"
      @x = -offset.y + center.x
      @y = offset.y + center.y
      return
    if direction is "left"
      @x = offset.y + center.x
      @y = -offset.y + center.y
      return
    #
    # direction === 'pi'
    tmpPointForRotate = center.copy().subtract offset
    @x = tmpPointForRotate.x
    @y = tmpPointForRotate.y
  
  flip: (direction, center) ->
    # direction must be 'vertical' or 'horizontal'
    if direction is "vertical"
      @y = center.y * 2 - @y
      return
    #
    # direction === 'horizontal'
    @x = center.x * 2 - @x
  
  distanceAngle: (dist, angle) ->
    deg = angle
    if deg > 270
      deg = deg - 360
    else deg = deg + 360  if deg < -270
    if -90 <= deg and deg <= 90
      x = Math.sin(radians(deg)) * dist
      y = Math.sqrt((dist * dist) - (x * x))
      @x = x + @x
      @y = @y - y
      return
    x = Math.sin(radians(180 - deg)) * dist
    y = Math.sqrt((dist * dist) - (x * x))
    @x = x + @x
    @y = @y + y
  
  
  # Point2 transforming:
  scaleBy: (scalePoint2) ->
    @multiplyBy scalePoint2
  
  translateBy: (deltaPoint2) ->
    @add deltaPoint2
  
  rotateBy: (angle, centerPoint2) ->
    center = centerPoint2 or new Point2(0, 0)
    p = @copy().subtract(center)
    r = p.r()
    theta = angle - p.theta()
    @x = center.x + (r * Math.cos(theta))
    @y = center.y - (r * Math.sin(theta))
  
  
  # Point2 conversion:
  asArray: ->
    [@x, @y]
  
  # creating Rectangle instances from Point2:
  corner: (cornerPoint2) ->
    # answer a new Rectangle
    new Rectangle(@x, @y, cornerPoint2.x, cornerPoint2.y)
  
  rectangle: (aPoint2) ->
    # answer a new Rectangle
    org = @copy().min(aPoint2)
    crn = @copy().max(aPoint2)
    new Rectangle(org.x, org.y, crn.x, crn.y)
  
  extent: (aPoint2) ->
    #answer a new Rectangle
    crn = @copy().add(aPoint2)
    new Rectangle(@x, @y, crn.x, crn.y)
  '''
# Global settings /////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

#global window, HTMLCanvasElement, getMinimumFontHeight, FileReader, Audio,
#FileList, getBlurredShadowSupport

modules = {} # keep track of additional loaded modules

useBlurredShadows = getBlurredShadowSupport() # check for Chrome-bug

standardSettings =
  minimumFontHeight: getMinimumFontHeight() # browser settings
  globalFontFamily: ""
  menuFontName: "sans-serif"
  menuFontSize: 12
  bubbleHelpFontSize: 10
  prompterFontName: "sans-serif"
  prompterFontSize: 12
  prompterSliderSize: 10
  handleSize: 15
  scrollBarSize: 12
  mouseScrollAmount: 40
  useSliderForInput: false
  useVirtualKeyboard: true
  isTouchDevice: false # turned on by touch events, don't set
  rasterizeSVGs: false
  isFlat: false

touchScreenSettings =
  minimumFontHeight: standardSettings.minimumFontHeight
  globalFontFamily: ""
  menuFontName: "sans-serif"
  menuFontSize: 24
  bubbleHelpFontSize: 18
  prompterFontName: "sans-serif"
  prompterFontSize: 24
  prompterSliderSize: 20
  handleSize: 26
  scrollBarSize: 24
  mouseScrollAmount: 40
  useSliderForInput: true
  useVirtualKeyboard: true
  isTouchDevice: false
  rasterizeSVGs: false
  isFlat: false


#| FrameMorph //////////////////////////////////////////////////////////
#| 
#| I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
#| 
#| and event handling.

class FrameMorph extends Morph

  @scrollFrame: null

  # if this frame belongs to a scrollFrame, then
  # the @scrollFrame points to it
  constructor: (@scrollFrame = null) ->
    super()
    @color = new Color(255, 250, 245)
    @acceptsDrops = true
    if @scrollFrame
      @isDraggable = false
      @noticesTransparentClick = false
    @updateRendering()

  setColor: (aColor) ->
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container srollFrame
    # is actually not painted.
    if @scrollFrame
      @scrollFrame.color = aColor
    super(aColor)

  setAlphaScaled: (alpha) ->
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container srollFrame
    # is actually not painted.
    if @scrollFrame
      @scrollFrame.alpha = @calculateAlphaScaled(alpha)
    super(alpha)
  
  boundsIncludingChildren: ->
    shadow = @getShadow()
    return @bounds.merge(shadow.bounds)  if shadow isnt null
    @bounds
  
  # This was in the original Morphic.js, but
  # it would cause the frame (or scrollframe) not to paint its
  # contents when "pic..." command is invoked.
  #fullImage: ->
  #  # use only for shadows
  #  @image
  
  recursivelyBlit: (aCanvas, clippingRectangle = @bounds) ->
    return null  unless @isVisible
    
    # the part to be redrawn could be outside the frame entirely,
    # in which case we can stop going down the morphs inside the frame
    # since the whole point of the frame is to clip everything to a specific
    # rectangle.
    # So, check which part of the Frame should be redrawn:
    dirtyPartOfFrame = @bounds.intersect(clippingRectangle)
    
    # if there is no dirty part in the frame then do nothing
    return null if dirtyPartOfFrame.isEmpty()
    
    # this draws the background of the frame itself, which could
    # contain an image or a pentrail
    @blit aCanvas, dirtyPartOfFrame
    
    @children.forEach (child) =>
      if child instanceof ShadowMorph
        child.recursivelyBlit aCanvas, clippingRectangle
      else
        child.recursivelyBlit aCanvas, dirtyPartOfFrame
  
  
  # FrameMorph scrolling optimization:
  moveBy: (delta) ->
    @changed()
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.silentMoveBy delta
    @changed()
  
  
  # FrameMorph scrolling support:
  submorphBounds: ->
    result = null
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        result = result.merge(child.boundsIncludingChildren())
    result
  
  keepInScrollFrame: ->
    return null  if @scrollFrame is null
    if @left() > @scrollFrame.left()
      @moveBy new Point(@scrollFrame.left() - @left(), 0)
    if @right() < @scrollFrame.right()
      @moveBy new Point(@scrollFrame.right() - @right(), 0)  
    if @top() > @scrollFrame.top()
      @moveBy new Point(0, @scrollFrame.top() - @top())  
    if @bottom() < @scrollFrame.bottom()
      @moveBy 0, new Point(@scrollFrame.bottom() - @bottom(), 0)
  
  adjustBounds: ->
    return null  if @scrollFrame is null
    subBounds = @submorphBounds()
    if subBounds and (not @scrollFrame.isTextLineWrapping)
      newBounds = subBounds.expandBy(@scrollFrame.padding).growBy(@scrollFrame.growth).merge(@scrollFrame.bounds)
    else
      newBounds = @scrollFrame.bounds.copy()
    unless @bounds.eq(newBounds)
      @bounds = newBounds
      @updateRendering()
      @keepInScrollFrame()
    if @scrollFrame.isTextLineWrapping
      @children.forEach (morph) =>
        if morph instanceof TextMorph
          morph.setWidth @width()
          @setHeight Math.max(morph.height(), @scrollFrame.height())
    @scrollFrame.adjustScrollBars()
  
  
  # FrameMorph dragging & dropping of contents:
  reactToDropOf: ->
    @adjustBounds()
  
  reactToGrabOf: ->
    @adjustBounds()
  
  
  # FrameMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.frame = (dict[@scrollFrame])  if c.frame and dict[@scrollFrame]
    c
  
  
  # FrameMorph menus:
  developersMenu: ->
    menu = super()
    if @children.length
      menu.addLine()
      menu.addItem "move all inside...", "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
    menu
  
  keepAllSubmorphsWithin: ->
    @children.forEach (m) =>
      m.keepWithin @

  @coffeeScriptSourceOfThisClass: '''
#| FrameMorph //////////////////////////////////////////////////////////
#| 
#| I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
#| 
#| and event handling.

class FrameMorph extends Morph

  @scrollFrame: null

  # if this frame belongs to a scrollFrame, then
  # the @scrollFrame points to it
  constructor: (@scrollFrame = null) ->
    super()
    @color = new Color(255, 250, 245)
    @acceptsDrops = true
    if @scrollFrame
      @isDraggable = false
      @noticesTransparentClick = false
    @updateRendering()

  setColor: (aColor) ->
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container srollFrame
    # is actually not painted.
    if @scrollFrame
      @scrollFrame.color = aColor
    super(aColor)

  setAlphaScaled: (alpha) ->
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container srollFrame
    # is actually not painted.
    if @scrollFrame
      @scrollFrame.alpha = @calculateAlphaScaled(alpha)
    super(alpha)
  
  boundsIncludingChildren: ->
    shadow = @getShadow()
    return @bounds.merge(shadow.bounds)  if shadow isnt null
    @bounds
  
  # This was in the original Morphic.js, but
  # it would cause the frame (or scrollframe) not to paint its
  # contents when "pic..." command is invoked.
  #fullImage: ->
  #  # use only for shadows
  #  @image
  
  recursivelyBlit: (aCanvas, clippingRectangle = @bounds) ->
    return null  unless @isVisible
    
    # the part to be redrawn could be outside the frame entirely,
    # in which case we can stop going down the morphs inside the frame
    # since the whole point of the frame is to clip everything to a specific
    # rectangle.
    # So, check which part of the Frame should be redrawn:
    dirtyPartOfFrame = @bounds.intersect(clippingRectangle)
    
    # if there is no dirty part in the frame then do nothing
    return null if dirtyPartOfFrame.isEmpty()
    
    # this draws the background of the frame itself, which could
    # contain an image or a pentrail
    @blit aCanvas, dirtyPartOfFrame
    
    @children.forEach (child) =>
      if child instanceof ShadowMorph
        child.recursivelyBlit aCanvas, clippingRectangle
      else
        child.recursivelyBlit aCanvas, dirtyPartOfFrame
  
  
  # FrameMorph scrolling optimization:
  moveBy: (delta) ->
    @changed()
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.silentMoveBy delta
    @changed()
  
  
  # FrameMorph scrolling support:
  submorphBounds: ->
    result = null
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        result = result.merge(child.boundsIncludingChildren())
    result
  
  keepInScrollFrame: ->
    return null  if @scrollFrame is null
    if @left() > @scrollFrame.left()
      @moveBy new Point(@scrollFrame.left() - @left(), 0)
    if @right() < @scrollFrame.right()
      @moveBy new Point(@scrollFrame.right() - @right(), 0)  
    if @top() > @scrollFrame.top()
      @moveBy new Point(0, @scrollFrame.top() - @top())  
    if @bottom() < @scrollFrame.bottom()
      @moveBy 0, new Point(@scrollFrame.bottom() - @bottom(), 0)
  
  adjustBounds: ->
    return null  if @scrollFrame is null
    subBounds = @submorphBounds()
    if subBounds and (not @scrollFrame.isTextLineWrapping)
      newBounds = subBounds.expandBy(@scrollFrame.padding).growBy(@scrollFrame.growth).merge(@scrollFrame.bounds)
    else
      newBounds = @scrollFrame.bounds.copy()
    unless @bounds.eq(newBounds)
      @bounds = newBounds
      @updateRendering()
      @keepInScrollFrame()
    if @scrollFrame.isTextLineWrapping
      @children.forEach (morph) =>
        if morph instanceof TextMorph
          morph.setWidth @width()
          @setHeight Math.max(morph.height(), @scrollFrame.height())
    @scrollFrame.adjustScrollBars()
  
  
  # FrameMorph dragging & dropping of contents:
  reactToDropOf: ->
    @adjustBounds()
  
  reactToGrabOf: ->
    @adjustBounds()
  
  
  # FrameMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.frame = (dict[@scrollFrame])  if c.frame and dict[@scrollFrame]
    c
  
  
  # FrameMorph menus:
  developersMenu: ->
    menu = super()
    if @children.length
      menu.addLine()
      menu.addItem "move all inside...", "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
    menu
  
  keepAllSubmorphsWithin: ->
    @children.forEach (m) =>
      m.keepWithin @
  '''
# WorldMorph //////////////////////////////////////////////////////////

# these comments below needed to figure our dependencies between classes
# REQUIRES globalFunctions
# REQUIRES globalSettings

# I represent the <canvas> element
class WorldMorph extends FrameMorph

  # these variables shouldn't be static to the WorldMorph, because
  # in pure theory you could have multiple worlds in the same
  # page with different settings
  # (but anyways, it was global before, so it's not any worse than before)
  @MorphicPreferences: standardSettings
  @currentTime: null
  @showRedraws: false
  systemTestsRecorderAndPlayer: null

  constructor: (aCanvas, fillPage) ->
    super()
    @color = new Color(205, 205, 205) # (130, 130, 130)
    @alpha = 1
    @bounds = new Rectangle(0, 0, aCanvas.width, aCanvas.height)
    @updateRendering()
    @isVisible = true
    @isDraggable = false
    @currentKey = null # currently pressed key code
    @worldCanvas = aCanvas

    # additional properties:
    @stamp = Date.now() # reference in multi-world setups
    @useFillPage = fillPage
    @useFillPage = true  if @useFillPage is `undefined`
    @isDevMode = false
    @broken = []
    @hand = new HandMorph(@)
    @keyboardReceiver = null
    @lastEditedText = null
    @caret = null
    @activeMenu = null
    @activeHandle = null
    @virtualKeyboard = null
    @initEventListeners()
    @systemTestsRecorderAndPlayer = new SystemTestsRecorderAndPlayer(@, @hand)
  
  # World Morph display:
  brokenFor: (aMorph) ->
    # private
    fb = aMorph.boundsIncludingChildren()
    @broken.filter (rect) ->
      rect.intersects fb
  
  
  # all fullDraws result into actual blittings of images done
  # by the blit function.
  # The blit function is defined in Morph and is not overriden by
  # any morph.
  recursivelyBlit: (aCanvas, aRect) ->
    # invokes the Morph's recursivelyBlit, which has only two implementations:
    # the default one by Morph which just invokes the blit of all children
    # and the interesting one in FrameMorph which 
    super aCanvas, aRect
    # the mouse cursor is always drawn on top of everything
    # and it'd not attached to the WorldMorph.
    @hand.recursivelyBlit aCanvas, aRect
  
  updateBroken: ->
    #console.log "number of broken rectangles: " + @broken.length
    @broken.forEach (rect) =>
      @recursivelyBlit @worldCanvas, rect  if rect.isNotEmpty()
    @broken = []
  
  doOneCycle: ->
    WorldMorph.currentTime = Date.now();
    @runChildrensStepFunction()
    @updateBroken()
  
  fillPage: ->
    pos = getDocumentPositionOf(@worldCanvas)
    clientHeight = window.innerHeight
    clientWidth = window.innerWidth
    if pos.x > 0
      @worldCanvas.style.position = "absolute"
      @worldCanvas.style.left = "0px"
      pos.x = 0
    if pos.y > 0
      @worldCanvas.style.position = "absolute"
      @worldCanvas.style.top = "0px"
      pos.y = 0
    # scrolled down b/c of viewport scaling
    clientHeight = document.documentElement.clientHeight  if document.body.scrollTop
    # scrolled left b/c of viewport scaling
    clientWidth = document.documentElement.clientWidth  if document.body.scrollLeft
    if @worldCanvas.width isnt clientWidth
      @worldCanvas.width = clientWidth
      @setWidth clientWidth
    if @worldCanvas.height isnt clientHeight
      @worldCanvas.height = clientHeight
      @setHeight clientHeight
    @children.forEach (child) =>
      child.reactToWorldResize @bounds.copy()  if child.reactToWorldResize
  
  
  
  # WorldMorph global pixel access:
  getGlobalPixelColor: (point) ->
    
    #
    #	answer the color at the given point.
    #
    #	Note: for some strange reason this method works fine if the page is
    #	opened via HTTP, but *not*, if it is opened from a local uri
    #	(e.g. from a directory), in which case it's always null.
    #
    #	This behavior is consistent throughout several browsers. I have no
    #	clue what's behind this, apparently the imageData attribute of
    #	canvas context only gets filled with meaningful data if transferred
    #	via HTTP ???
    #
    #	This is somewhat of a showstopper for color detection in a planned
    #	offline version of Snap.
    #
    #	The issue has also been discussed at: (join lines before pasting)
    #	http://stackoverflow.com/questions/4069400/
    #	canvas-getimagedata-doesnt-work-when-running-locally-on-windows-
    #	security-excep
    #
    #	The suggestion solution appears to work, since the settings are
    #	applied globally.
    #
    dta = @worldCanvas.getContext("2d").getImageData(point.x, point.y, 1, 1).data
    new Color(dta[0], dta[1], dta[2])
  
  
  # WorldMorph events:
  initVirtualKeyboard: ->
    if @virtualKeyboard
      document.body.removeChild @virtualKeyboard
      @virtualKeyboard = null
    unless (WorldMorph.MorphicPreferences.isTouchDevice and WorldMorph.MorphicPreferences.useVirtualKeyboard)
      return
    @virtualKeyboard = document.createElement("input")
    @virtualKeyboard.type = "text"
    @virtualKeyboard.style.color = "transparent"
    @virtualKeyboard.style.backgroundColor = "transparent"
    @virtualKeyboard.style.border = "none"
    @virtualKeyboard.style.outline = "none"
    @virtualKeyboard.style.position = "absolute"
    @virtualKeyboard.style.top = "0px"
    @virtualKeyboard.style.left = "0px"
    @virtualKeyboard.style.width = "0px"
    @virtualKeyboard.style.height = "0px"
    @virtualKeyboard.autocapitalize = "none" # iOS specific
    document.body.appendChild @virtualKeyboard

    @virtualKeyboard.addEventListener "keydown", ((event) =>
      # remember the keyCode in the world's currentKey property
      @currentKey = event.keyCode

      @keyboardReceiver.processKeyDown event  if @keyboardReceiver
      #
      # supress backspace override
      if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
        event.preventDefault()  
      #
      # supress tab override and make sure tab gets
      # received by all browsers
      if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
        @keyboardReceiver.processKeyPress event  if @keyboardReceiver
        event.preventDefault()
    ), false
    @virtualKeyboard.addEventListener "keyup", ((event) =>
      # flush the world's currentKey property
      @currentKey = null
      #
      # dispatch to keyboard receiver
      if @keyboardReceiver
        if @keyboardReceiver.processKeyUp
          @keyboardReceiver.processKeyUp event  
      event.preventDefault()
    ), false
    @virtualKeyboard.addEventListener "keypress", ((event) =>
      @keyboardReceiver.processKeyPress event  if @keyboardReceiver
      event.preventDefault()
    ), false
  
  initEventListeners: ->
    canvas = @worldCanvas
    if @useFillPage
      @fillPage()
    else
      @changed()
    canvas.addEventListener "dblclick", ((event) =>
      event.preventDefault()
      @hand.processDoubleClick event
    ), false
    canvas.addEventListener "mousedown", ((event) =>
      @hand.processMouseDown event.button, event.ctrlKey
    ), false
    canvas.addEventListener "touchstart", ((event) =>
      @hand.processTouchStart event
    ), false
    canvas.addEventListener "mouseup", ((event) =>
      event.preventDefault()
      @hand.processMouseUp event
    ), false
    canvas.addEventListener "touchend", ((event) =>
      @hand.processTouchEnd event
    ), false
    canvas.addEventListener "mousemove", ((event) =>
      @hand.processMouseMove  event.pageX, event.pageY
    ), false
    canvas.addEventListener "touchmove", ((event) =>
      @hand.processTouchMove event
    ), false
    canvas.addEventListener "contextmenu", ((event) ->
      # suppress context menu for Mac-Firefox
      event.preventDefault()
    ), false
    canvas.addEventListener "keydown", ((event) =>
      # remember the keyCode in the world's currentKey property
      @currentKey = event.keyCode
      @keyboardReceiver.processKeyDown event  if @keyboardReceiver
      #
      # supress backspace override
      if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
        event.preventDefault()
      #
      # supress tab override and make sure tab gets
      # received by all browsers
      if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
        @keyboardReceiver.processKeyPress event  if @keyboardReceiver
        event.preventDefault()
    ), false
    #
    canvas.addEventListener "keyup", ((event) =>  
      # flush the world's currentKey property
      @currentKey = null
      #
      # dispatch to keyboard receiver
      if @keyboardReceiver
        if @keyboardReceiver.processKeyUp
          @keyboardReceiver.processKeyUp event    
      event.preventDefault()
    ), false
    canvas.addEventListener "keypress", ((event) =>
      @keyboardReceiver.processKeyPress event  if @keyboardReceiver
      event.preventDefault()
    ), false
    # Safari, Chrome
    canvas.addEventListener "mousewheel", ((event) =>
      @hand.processMouseScroll event
      event.preventDefault()
    ), false
    # Firefox
    canvas.addEventListener "DOMMouseScroll", ((event) =>
      @hand.processMouseScroll event
      event.preventDefault()
    ), false

    # snippets of clipboard-handling code taken from
    # http://codebits.glennjones.net/editing/setclipboarddata.htm
    # Note that this works only in Chrome. Firefox and Safari need a piece of
    # text to be selected in order to even trigger the copy event. Chrome does
    # enable clipboard access instead even if nothing is selected.
    # There are a couple of solutions to this - one is to keep a hidden textfield that
    # handles all copy/paste operations.
    # Another one is to not use a clipboard, but rather an internal string as
    # local memory. So the OS clipboard wouldn't be used, but at least there would
    # be some copy/paste working. Also one would need to intercept the copy/paste
    # key combinations manually instead of from the copy/paste events.
    document.body.addEventListener "copy", ((event) =>
      if @caret
        selectedText = @caret.target.selection()
        if event.clipboardData
          event.preventDefault()
          setStatus = event.clipboardData.setData("text/plain", selectedText)

        if window.clipboardData
          event.returnValue = false
          setStatus = window.clipboardData.setData "Text", selectedText

    ), false

    document.body.addEventListener "paste", ((event) =>
      if @caret
        if event.clipboardData
          # Look for access to data if types array is missing
          text = event.clipboardData.getData("text/plain")
          #url = event.clipboardData.getData("text/uri-list")
          #html = event.clipboardData.getData("text/html")
          #custom = event.clipboardData.getData("text/xcustom")
        # IE event is attached to the window object
        if window.clipboardData
          # The schema is fixed
          text = window.clipboardData.getData("Text")
          #url = window.clipboardData.getData("URL")
        
        # Needs a few msec to excute paste
        window.setTimeout ( => (@caret.insert text)), 50, true
    ), false

    #console.log "binding with mousetrap"
    Mousetrap.bind ["command+k", "ctrl+k"], (e) =>
      @systemTestsRecorderAndPlayer.takeScreenshot()
      false

    window.addEventListener "dragover", ((event) ->
      event.preventDefault()
    ), false
    window.addEventListener "drop", ((event) =>
      @hand.processDrop event
      event.preventDefault()
    ), false
    window.addEventListener "resize", (=>
      @fillPage()  if @useFillPage
    ), false
    window.onbeforeunload = (evt) ->
      e = evt or window.event
      msg = "Are you sure you want to leave?"
      #
      # For IE and Firefox
      e.returnValue = msg  if e
      #
      # For Safari / chrome
      msg
  
  mouseDownLeft: ->
    noOperation
  
  mouseClickLeft: ->
    noOperation
  
  mouseDownRight: ->
    noOperation
  
  mouseClickRight: ->
    noOperation
  
  wantsDropOf: ->
    # allow handle drops if any drops are allowed
    @acceptsDrops
  
  droppedImage: ->
    null

  droppedSVG: ->
    null  

  # WorldMorph text field tabbing:
  nextTab: (editField) ->
    next = @nextEntryField(editField)
    if next
      editField.clearSelection()
      next.selectAll()
      next.edit()
  
  previousTab: (editField) ->
    prev = @previousEntryField(editField)
    if prev
      editField.clearSelection()
      prev.selectAll()
      prev.edit()
  
  testsList: () ->
    # Check which objects have the right name start
    console.log Object.keys(window)
    (Object.keys(window)).filter (i) ->
      console.log i.indexOf("SystemTest_")
      i.indexOf("SystemTest_") == 0

  runSystemTests: () ->
    console.log @testsList()
    for i in @testsList()
      console.log window[i]
      @systemTestsRecorderAndPlayer.eventQueue = (window[i]).testData
      # the Zombie kernel safari pop-up is painted weird, needs a refresh
      # for some unknown reason
      @changed()
      # start from clean slate
      @destroyAll()
      @systemTestsRecorderAndPlayer.startTestPlaying()

  # WorldMorph menu:
  contextMenu: ->
    if @isDevMode
      menu = new MenuMorph(
        @, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    else
      menu = new MenuMorph(@, "Morphic")
    if @isDevMode
      menu.addItem "demo...", "userCreateMorph", "sample morphs"
      menu.addLine()
      menu.addItem "hide all...", "hideAll"
      menu.addItem "delete all...", "destroyAll"
      menu.addItem "show all...", "showAllHiddens"
      menu.addItem "move all inside...", "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
      menu.addItem "inspect...", "inspect", "open a window on\nall properties"
      menu.addLine()
      menu.addItem "restore display", "changed", "redraw the\nscreen once"
      menu.addItem "fill page...", "fillPage", "let the World automatically\nadjust to browser resizings"
      if useBlurredShadows
        menu.addItem "sharp shadows...", "toggleBlurredShadows", "sharp drop shadows\nuse for old browsers"
      else
        menu.addItem "blurred shadows...", "toggleBlurredShadows", "blurry shades,\n use for new browsers"
      menu.addItem "color...", (->
        @pickColor menu.title + "\ncolor:", @setColor, @, @color
      ), "choose the World's\nbackground color"
      if WorldMorph.MorphicPreferences is standardSettings
        menu.addItem "touch screen settings", "togglePreferences", "bigger menu fonts\nand sliders"
      else
        menu.addItem "standard settings", "togglePreferences", "smaller menu fonts\nand sliders"
      menu.addLine()
    menu.addItem "run system tests",  "runSystemTests", "runs all the system tests"
    menu.addItem "start test rec",  "startTestRecording", "start recording a test"
    menu.addItem "stop test rec",  "stopTestRecording", "stop recording the test"
    menu.addItem "play test",  "startTestPlaying", "start playing the test"
    menu.addItem "show test source",  "showTestSource", "opens a window with the source of the latest test"
    menu.addLine()
    if @isDevMode
      menu.addItem "user mode...", "toggleDevMode", "disable developers'\ncontext menus"
    else
      menu.addItem "development mode...", "toggleDevMode"
    menu.addItem "about Zombie Kernel...", "about"
    menu

  startTestRecording: ->
    @systemTestsRecorderAndPlayer.startTestRecording()

  stopTestRecording: ->
    @systemTestsRecorderAndPlayer.stopTestRecording()

  startTestPlaying: ->
    @systemTestsRecorderAndPlayer.startTestPlaying()

  showTestSource: ->
    @systemTestsRecorderAndPlayer.showTestSource()
  
  userCreateMorph: ->
    create = (aMorph) =>
      aMorph.isDraggable = true
      aMorph.pickUp @
    menu = new MenuMorph(@, "make a morph")
    menu.addItem "rectangle", ->
      create new Morph()
    
    menu.addItem "box", ->
      create new BoxMorph()
    
    menu.addItem "circle box", ->
      create new CircleBoxMorph()
    
    menu.addLine()
    menu.addItem "slider", ->
      create new SliderMorph()
    
    menu.addItem "frame", ->
      newMorph = new FrameMorph()
      newMorph.setExtent new Point(350, 250)
      create newMorph
    
    menu.addItem "scroll frame", ->
      newMorph = new ScrollFrameMorph()
      newMorph.contents.acceptsDrops = true
      newMorph.contents.adjustBounds()
      newMorph.setExtent new Point(350, 250)
      create newMorph
    
    menu.addItem "handle", ->
      create new HandleMorph()
    
    menu.addLine()
    menu.addItem "string", ->
      newMorph = new StringMorph("Hello, World!")
      newMorph.isEditable = true
      create newMorph
    
    menu.addItem "text", ->
      newMorph = new TextMorph("Ich weiß nicht, was soll es bedeuten, dass ich so " +
        "traurig bin, ein Märchen aus uralten Zeiten, das " +
        "kommt mir nicht aus dem Sinn. Die Luft ist kühl " +
        "und es dunkelt, und ruhig fließt der Rhein; der " +
        "Gipfel des Berges funkelt im Abendsonnenschein. " +
        "Die schönste Jungfrau sitzet dort oben wunderbar, " +
        "ihr gold'nes Geschmeide blitzet, sie kämmt ihr " +
        "goldenes Haar, sie kämmt es mit goldenem Kamme, " +
        "und singt ein Lied dabei; das hat eine wundersame, " +
        "gewalt'ge Melodei. Den Schiffer im kleinen " +
        "Schiffe, ergreift es mit wildem Weh; er schaut " +
        "nicht die Felsenriffe, er schaut nur hinauf in " +
        "die Höh'. Ich glaube, die Wellen verschlingen " +
        "am Ende Schiffer und Kahn, und das hat mit ihrem " +
        "Singen, die Loreley getan.")
      newMorph.isEditable = true
      newMorph.maxWidth = 300
      newMorph.updateRendering()
      create newMorph
    
    menu.addItem "speech bubble", ->
      newMorph = new SpeechBubbleMorph("Hello, World!")
      create newMorph
    
    menu.addLine()
    menu.addItem "gray scale palette", ->
      create new GrayPaletteMorph()
    
    menu.addItem "color palette", ->
      create new ColorPaletteMorph()
    
    menu.addItem "color picker", ->
      create new ColorPickerMorph()
    
    menu.addLine()
    menu.addItem "sensor demo", ->
      newMorph = new MouseSensorMorph()
      newMorph.setColor new Color(230, 200, 100)
      newMorph.edge = 35
      newMorph.border = 15
      newMorph.borderColor = new Color(200, 100, 50)
      newMorph.alpha = 0.2
      newMorph.setExtent new Point(100, 100)
      create newMorph
    
    menu.addItem "animation demo", ->
      foo = new BouncerMorph()
      foo.setPosition new Point(50, 20)
      foo.setExtent new Point(300, 200)
      foo.alpha = 0.9
      foo.speed = 3
      bar = new BouncerMorph()
      bar.setColor new Color(50, 50, 50)
      bar.setPosition new Point(80, 80)
      bar.setExtent new Point(80, 250)
      bar.type = "horizontal"
      bar.direction = "right"
      bar.alpha = 0.9
      bar.speed = 5
      baz = new BouncerMorph()
      baz.setColor new Color(20, 20, 20)
      baz.setPosition new Point(90, 140)
      baz.setExtent new Point(40, 30)
      baz.type = "horizontal"
      baz.direction = "right"
      baz.speed = 3
      garply = new BouncerMorph()
      garply.setColor new Color(200, 20, 20)
      garply.setPosition new Point(90, 140)
      garply.setExtent new Point(20, 20)
      garply.type = "vertical"
      garply.direction = "up"
      garply.speed = 8
      fred = new BouncerMorph()
      fred.setColor new Color(20, 200, 20)
      fred.setPosition new Point(120, 140)
      fred.setExtent new Point(20, 20)
      fred.type = "vertical"
      fred.direction = "down"
      fred.speed = 4
      bar.add garply
      bar.add baz
      foo.add fred
      foo.add bar
      create foo
    
    menu.addItem "pen", ->
      create new PenMorph()
    
    menu.addLine()
    menu.addItem "view all...", ->
      newMorph = new MorphsListMorph()
      create newMorph
    menu.addItem "closing window", ->
      newMorph = new WorkspaceMorph()
      create newMorph

    if @customMorphs
      menu.addLine()
      @customMorphs().forEach (morph) ->
        menu.addItem morph.toString(), ->
          create morph
    
    menu.popUpAtHand @
  
  toggleDevMode: ->
    @isDevMode = not @isDevMode
  
  hideAll: ->
    @children.forEach (child) ->
      child.hide()
  
  showAllHiddens: ->
    @forAllChildren (child) ->
      child.show()  unless child.isVisible
  
  about: ->
    versions = ""
    for module of modules
      if Object.prototype.hasOwnProperty.call(modules, module)
        versions += ("\n" + module + " (" + modules[module] + ")")  
    if versions isnt ""
      versions = "\n\nmodules:\n\n" + "morphic (" + morphicVersion + ")" + versions  
    @inform "Zombie kernel\n\n" +
      "a lively Web GUI\ninspired by Squeak\n" +
      morphicVersion +
      "\n\nby Davide Della Casa" +
      "\n\nbased on morphic.js by" +
      "\nJens Mönig (jens@moenig.org)"
  
  edit: (aStringMorphOrTextMorph) ->
    # first off, if the Morph is not editable
    # then there is nothing to do
    return null  unless aStringMorphOrTextMorph.isEditable

    # there is only one caret in the World, so destroy
    # the previous one if there was one.
    if @caret
      # empty the previously ongoing selection
      # if there was one.
      @lastEditedText = @caret.target
      @lastEditedText.clearSelection()  if @lastEditedText
      @caret.destroy()

    # create the new Caret
    @caret = new CaretMorph(aStringMorphOrTextMorph)
    aStringMorphOrTextMorph.parent.add @caret
    @keyboardReceiver = @caret
    @initVirtualKeyboard()
    if WorldMorph.MorphicPreferences.isTouchDevice and WorldMorph.MorphicPreferences.useVirtualKeyboard
      pos = getDocumentPositionOf(@worldCanvas)
      @virtualKeyboard.style.top = @caret.top() + pos.y + "px"
      @virtualKeyboard.style.left = @caret.left() + pos.x + "px"
      @virtualKeyboard.focus()
    if WorldMorph.MorphicPreferences.useSliderForInput
      if !aStringMorphOrTextMorph.parentThatIsA(MenuMorph)
        @slide aStringMorphOrTextMorph
  
  # Editing can stop because of three reasons:
  #   cancel (user hits ESC)
  #   accept (on stringmorph, user hits enter)
  #   user clicks/drags another morph
  stopEditing: ->
    if @caret
      @lastEditedText = @caret.target
      @lastEditedText.clearSelection()
      @lastEditedText.escalateEvent "reactToEdit", @lastEditedText
      @caret.destroy()
      @caret = null
    @keyboardReceiver = null
    if @virtualKeyboard
      @virtualKeyboard.blur()
      document.body.removeChild @virtualKeyboard
      @virtualKeyboard = null
    @worldCanvas.focus()
  
  slide: (aStringMorphOrTextMorph) ->
    # display a slider for numeric text entries
    val = parseFloat(aStringMorphOrTextMorph.text)
    val = 0  if isNaN(val)
    menu = new MenuMorph()
    slider = new SliderMorph(val - 25, val + 25, val, 10, "horizontal")
    slider.alpha = 1
    slider.color = new Color(225, 225, 225)
    slider.button.color = menu.borderColor
    slider.button.highlightColor = slider.button.color.copy()
    slider.button.highlightColor.b += 100
    slider.button.pressColor = slider.button.color.copy()
    slider.button.pressColor.b += 150
    slider.silentSetHeight WorldMorph.MorphicPreferences.scrollBarSize
    slider.silentSetWidth WorldMorph.MorphicPreferences.menuFontSize * 10
    slider.updateRendering()
    slider.action = (num) ->
      aStringMorphOrTextMorph.changed()
      aStringMorphOrTextMorph.text = Math.round(num).toString()
      aStringMorphOrTextMorph.updateRendering()
      aStringMorphOrTextMorph.changed()
      aStringMorphOrTextMorph.escalateEvent(
          'reactToSliderEdit',
          aStringMorphOrTextMorph
      )
    #
    menu.items.push slider
    menu.popup @, aStringMorphOrTextMorph.bottomLeft().add(new Point(0, 5))
  
  toggleBlurredShadows: ->
    useBlurredShadows = not useBlurredShadows
  
  togglePreferences: ->
    if WorldMorph.MorphicPreferences is standardSettings
      WorldMorph.MorphicPreferences = touchScreenSettings
    else
      WorldMorph.MorphicPreferences = standardSettings

  @coffeeScriptSourceOfThisClass: '''
# WorldMorph //////////////////////////////////////////////////////////

# these comments below needed to figure our dependencies between classes
# REQUIRES globalFunctions
# REQUIRES globalSettings

# I represent the <canvas> element
class WorldMorph extends FrameMorph

  # these variables shouldn't be static to the WorldMorph, because
  # in pure theory you could have multiple worlds in the same
  # page with different settings
  # (but anyways, it was global before, so it's not any worse than before)
  @MorphicPreferences: standardSettings
  @currentTime: null
  @showRedraws: false
  systemTestsRecorderAndPlayer: null

  constructor: (aCanvas, fillPage) ->
    super()
    @color = new Color(205, 205, 205) # (130, 130, 130)
    @alpha = 1
    @bounds = new Rectangle(0, 0, aCanvas.width, aCanvas.height)
    @updateRendering()
    @isVisible = true
    @isDraggable = false
    @currentKey = null # currently pressed key code
    @worldCanvas = aCanvas

    # additional properties:
    @stamp = Date.now() # reference in multi-world setups
    @useFillPage = fillPage
    @useFillPage = true  if @useFillPage is `undefined`
    @isDevMode = false
    @broken = []
    @hand = new HandMorph(@)
    @keyboardReceiver = null
    @lastEditedText = null
    @caret = null
    @activeMenu = null
    @activeHandle = null
    @virtualKeyboard = null
    @initEventListeners()
    @systemTestsRecorderAndPlayer = new SystemTestsRecorderAndPlayer(@, @hand)
  
  # World Morph display:
  brokenFor: (aMorph) ->
    # private
    fb = aMorph.boundsIncludingChildren()
    @broken.filter (rect) ->
      rect.intersects fb
  
  
  # all fullDraws result into actual blittings of images done
  # by the blit function.
  # The blit function is defined in Morph and is not overriden by
  # any morph.
  recursivelyBlit: (aCanvas, aRect) ->
    # invokes the Morph's recursivelyBlit, which has only two implementations:
    # the default one by Morph which just invokes the blit of all children
    # and the interesting one in FrameMorph which 
    super aCanvas, aRect
    # the mouse cursor is always drawn on top of everything
    # and it'd not attached to the WorldMorph.
    @hand.recursivelyBlit aCanvas, aRect
  
  updateBroken: ->
    #console.log "number of broken rectangles: " + @broken.length
    @broken.forEach (rect) =>
      @recursivelyBlit @worldCanvas, rect  if rect.isNotEmpty()
    @broken = []
  
  doOneCycle: ->
    WorldMorph.currentTime = Date.now();
    @runChildrensStepFunction()
    @updateBroken()
  
  fillPage: ->
    pos = getDocumentPositionOf(@worldCanvas)
    clientHeight = window.innerHeight
    clientWidth = window.innerWidth
    if pos.x > 0
      @worldCanvas.style.position = "absolute"
      @worldCanvas.style.left = "0px"
      pos.x = 0
    if pos.y > 0
      @worldCanvas.style.position = "absolute"
      @worldCanvas.style.top = "0px"
      pos.y = 0
    # scrolled down b/c of viewport scaling
    clientHeight = document.documentElement.clientHeight  if document.body.scrollTop
    # scrolled left b/c of viewport scaling
    clientWidth = document.documentElement.clientWidth  if document.body.scrollLeft
    if @worldCanvas.width isnt clientWidth
      @worldCanvas.width = clientWidth
      @setWidth clientWidth
    if @worldCanvas.height isnt clientHeight
      @worldCanvas.height = clientHeight
      @setHeight clientHeight
    @children.forEach (child) =>
      child.reactToWorldResize @bounds.copy()  if child.reactToWorldResize
  
  
  
  # WorldMorph global pixel access:
  getGlobalPixelColor: (point) ->
    
    #
    #	answer the color at the given point.
    #
    #	Note: for some strange reason this method works fine if the page is
    #	opened via HTTP, but *not*, if it is opened from a local uri
    #	(e.g. from a directory), in which case it's always null.
    #
    #	This behavior is consistent throughout several browsers. I have no
    #	clue what's behind this, apparently the imageData attribute of
    #	canvas context only gets filled with meaningful data if transferred
    #	via HTTP ???
    #
    #	This is somewhat of a showstopper for color detection in a planned
    #	offline version of Snap.
    #
    #	The issue has also been discussed at: (join lines before pasting)
    #	http://stackoverflow.com/questions/4069400/
    #	canvas-getimagedata-doesnt-work-when-running-locally-on-windows-
    #	security-excep
    #
    #	The suggestion solution appears to work, since the settings are
    #	applied globally.
    #
    dta = @worldCanvas.getContext("2d").getImageData(point.x, point.y, 1, 1).data
    new Color(dta[0], dta[1], dta[2])
  
  
  # WorldMorph events:
  initVirtualKeyboard: ->
    if @virtualKeyboard
      document.body.removeChild @virtualKeyboard
      @virtualKeyboard = null
    unless (WorldMorph.MorphicPreferences.isTouchDevice and WorldMorph.MorphicPreferences.useVirtualKeyboard)
      return
    @virtualKeyboard = document.createElement("input")
    @virtualKeyboard.type = "text"
    @virtualKeyboard.style.color = "transparent"
    @virtualKeyboard.style.backgroundColor = "transparent"
    @virtualKeyboard.style.border = "none"
    @virtualKeyboard.style.outline = "none"
    @virtualKeyboard.style.position = "absolute"
    @virtualKeyboard.style.top = "0px"
    @virtualKeyboard.style.left = "0px"
    @virtualKeyboard.style.width = "0px"
    @virtualKeyboard.style.height = "0px"
    @virtualKeyboard.autocapitalize = "none" # iOS specific
    document.body.appendChild @virtualKeyboard

    @virtualKeyboard.addEventListener "keydown", ((event) =>
      # remember the keyCode in the world's currentKey property
      @currentKey = event.keyCode

      @keyboardReceiver.processKeyDown event  if @keyboardReceiver
      #
      # supress backspace override
      if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
        event.preventDefault()  
      #
      # supress tab override and make sure tab gets
      # received by all browsers
      if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
        @keyboardReceiver.processKeyPress event  if @keyboardReceiver
        event.preventDefault()
    ), false
    @virtualKeyboard.addEventListener "keyup", ((event) =>
      # flush the world's currentKey property
      @currentKey = null
      #
      # dispatch to keyboard receiver
      if @keyboardReceiver
        if @keyboardReceiver.processKeyUp
          @keyboardReceiver.processKeyUp event  
      event.preventDefault()
    ), false
    @virtualKeyboard.addEventListener "keypress", ((event) =>
      @keyboardReceiver.processKeyPress event  if @keyboardReceiver
      event.preventDefault()
    ), false
  
  initEventListeners: ->
    canvas = @worldCanvas
    if @useFillPage
      @fillPage()
    else
      @changed()
    canvas.addEventListener "dblclick", ((event) =>
      event.preventDefault()
      @hand.processDoubleClick event
    ), false
    canvas.addEventListener "mousedown", ((event) =>
      @hand.processMouseDown event.button, event.ctrlKey
    ), false
    canvas.addEventListener "touchstart", ((event) =>
      @hand.processTouchStart event
    ), false
    canvas.addEventListener "mouseup", ((event) =>
      event.preventDefault()
      @hand.processMouseUp event
    ), false
    canvas.addEventListener "touchend", ((event) =>
      @hand.processTouchEnd event
    ), false
    canvas.addEventListener "mousemove", ((event) =>
      @hand.processMouseMove  event.pageX, event.pageY
    ), false
    canvas.addEventListener "touchmove", ((event) =>
      @hand.processTouchMove event
    ), false
    canvas.addEventListener "contextmenu", ((event) ->
      # suppress context menu for Mac-Firefox
      event.preventDefault()
    ), false
    canvas.addEventListener "keydown", ((event) =>
      # remember the keyCode in the world's currentKey property
      @currentKey = event.keyCode
      @keyboardReceiver.processKeyDown event  if @keyboardReceiver
      #
      # supress backspace override
      if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
        event.preventDefault()
      #
      # supress tab override and make sure tab gets
      # received by all browsers
      if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
        @keyboardReceiver.processKeyPress event  if @keyboardReceiver
        event.preventDefault()
    ), false
    #
    canvas.addEventListener "keyup", ((event) =>  
      # flush the world's currentKey property
      @currentKey = null
      #
      # dispatch to keyboard receiver
      if @keyboardReceiver
        if @keyboardReceiver.processKeyUp
          @keyboardReceiver.processKeyUp event    
      event.preventDefault()
    ), false
    canvas.addEventListener "keypress", ((event) =>
      @keyboardReceiver.processKeyPress event  if @keyboardReceiver
      event.preventDefault()
    ), false
    # Safari, Chrome
    canvas.addEventListener "mousewheel", ((event) =>
      @hand.processMouseScroll event
      event.preventDefault()
    ), false
    # Firefox
    canvas.addEventListener "DOMMouseScroll", ((event) =>
      @hand.processMouseScroll event
      event.preventDefault()
    ), false

    # snippets of clipboard-handling code taken from
    # http://codebits.glennjones.net/editing/setclipboarddata.htm
    # Note that this works only in Chrome. Firefox and Safari need a piece of
    # text to be selected in order to even trigger the copy event. Chrome does
    # enable clipboard access instead even if nothing is selected.
    # There are a couple of solutions to this - one is to keep a hidden textfield that
    # handles all copy/paste operations.
    # Another one is to not use a clipboard, but rather an internal string as
    # local memory. So the OS clipboard wouldn't be used, but at least there would
    # be some copy/paste working. Also one would need to intercept the copy/paste
    # key combinations manually instead of from the copy/paste events.
    document.body.addEventListener "copy", ((event) =>
      if @caret
        selectedText = @caret.target.selection()
        if event.clipboardData
          event.preventDefault()
          setStatus = event.clipboardData.setData("text/plain", selectedText)

        if window.clipboardData
          event.returnValue = false
          setStatus = window.clipboardData.setData "Text", selectedText

    ), false

    document.body.addEventListener "paste", ((event) =>
      if @caret
        if event.clipboardData
          # Look for access to data if types array is missing
          text = event.clipboardData.getData("text/plain")
          #url = event.clipboardData.getData("text/uri-list")
          #html = event.clipboardData.getData("text/html")
          #custom = event.clipboardData.getData("text/xcustom")
        # IE event is attached to the window object
        if window.clipboardData
          # The schema is fixed
          text = window.clipboardData.getData("Text")
          #url = window.clipboardData.getData("URL")
        
        # Needs a few msec to excute paste
        window.setTimeout ( => (@caret.insert text)), 50, true
    ), false

    #console.log "binding with mousetrap"
    Mousetrap.bind ["command+k", "ctrl+k"], (e) =>
      @systemTestsRecorderAndPlayer.takeScreenshot()
      false

    window.addEventListener "dragover", ((event) ->
      event.preventDefault()
    ), false
    window.addEventListener "drop", ((event) =>
      @hand.processDrop event
      event.preventDefault()
    ), false
    window.addEventListener "resize", (=>
      @fillPage()  if @useFillPage
    ), false
    window.onbeforeunload = (evt) ->
      e = evt or window.event
      msg = "Are you sure you want to leave?"
      #
      # For IE and Firefox
      e.returnValue = msg  if e
      #
      # For Safari / chrome
      msg
  
  mouseDownLeft: ->
    noOperation
  
  mouseClickLeft: ->
    noOperation
  
  mouseDownRight: ->
    noOperation
  
  mouseClickRight: ->
    noOperation
  
  wantsDropOf: ->
    # allow handle drops if any drops are allowed
    @acceptsDrops
  
  droppedImage: ->
    null

  droppedSVG: ->
    null  

  # WorldMorph text field tabbing:
  nextTab: (editField) ->
    next = @nextEntryField(editField)
    if next
      editField.clearSelection()
      next.selectAll()
      next.edit()
  
  previousTab: (editField) ->
    prev = @previousEntryField(editField)
    if prev
      editField.clearSelection()
      prev.selectAll()
      prev.edit()
  
  testsList: () ->
    # Check which objects have the right name start
    console.log Object.keys(window)
    (Object.keys(window)).filter (i) ->
      console.log i.indexOf("SystemTest_")
      i.indexOf("SystemTest_") == 0

  runSystemTests: () ->
    console.log @testsList()
    for i in @testsList()
      console.log window[i]
      @systemTestsRecorderAndPlayer.eventQueue = (window[i]).testData
      # the Zombie kernel safari pop-up is painted weird, needs a refresh
      # for some unknown reason
      @changed()
      # start from clean slate
      @destroyAll()
      @systemTestsRecorderAndPlayer.startTestPlaying()

  # WorldMorph menu:
  contextMenu: ->
    if @isDevMode
      menu = new MenuMorph(
        @, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    else
      menu = new MenuMorph(@, "Morphic")
    if @isDevMode
      menu.addItem "demo...", "userCreateMorph", "sample morphs"
      menu.addLine()
      menu.addItem "hide all...", "hideAll"
      menu.addItem "delete all...", "destroyAll"
      menu.addItem "show all...", "showAllHiddens"
      menu.addItem "move all inside...", "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
      menu.addItem "inspect...", "inspect", "open a window on\nall properties"
      menu.addLine()
      menu.addItem "restore display", "changed", "redraw the\nscreen once"
      menu.addItem "fill page...", "fillPage", "let the World automatically\nadjust to browser resizings"
      if useBlurredShadows
        menu.addItem "sharp shadows...", "toggleBlurredShadows", "sharp drop shadows\nuse for old browsers"
      else
        menu.addItem "blurred shadows...", "toggleBlurredShadows", "blurry shades,\n use for new browsers"
      menu.addItem "color...", (->
        @pickColor menu.title + "\ncolor:", @setColor, @, @color
      ), "choose the World's\nbackground color"
      if WorldMorph.MorphicPreferences is standardSettings
        menu.addItem "touch screen settings", "togglePreferences", "bigger menu fonts\nand sliders"
      else
        menu.addItem "standard settings", "togglePreferences", "smaller menu fonts\nand sliders"
      menu.addLine()
    menu.addItem "run system tests",  "runSystemTests", "runs all the system tests"
    menu.addItem "start test rec",  "startTestRecording", "start recording a test"
    menu.addItem "stop test rec",  "stopTestRecording", "stop recording the test"
    menu.addItem "play test",  "startTestPlaying", "start playing the test"
    menu.addItem "show test source",  "showTestSource", "opens a window with the source of the latest test"
    menu.addLine()
    if @isDevMode
      menu.addItem "user mode...", "toggleDevMode", "disable developers'\ncontext menus"
    else
      menu.addItem "development mode...", "toggleDevMode"
    menu.addItem "about Zombie Kernel...", "about"
    menu

  startTestRecording: ->
    @systemTestsRecorderAndPlayer.startTestRecording()

  stopTestRecording: ->
    @systemTestsRecorderAndPlayer.stopTestRecording()

  startTestPlaying: ->
    @systemTestsRecorderAndPlayer.startTestPlaying()

  showTestSource: ->
    @systemTestsRecorderAndPlayer.showTestSource()
  
  userCreateMorph: ->
    create = (aMorph) =>
      aMorph.isDraggable = true
      aMorph.pickUp @
    menu = new MenuMorph(@, "make a morph")
    menu.addItem "rectangle", ->
      create new Morph()
    
    menu.addItem "box", ->
      create new BoxMorph()
    
    menu.addItem "circle box", ->
      create new CircleBoxMorph()
    
    menu.addLine()
    menu.addItem "slider", ->
      create new SliderMorph()
    
    menu.addItem "frame", ->
      newMorph = new FrameMorph()
      newMorph.setExtent new Point(350, 250)
      create newMorph
    
    menu.addItem "scroll frame", ->
      newMorph = new ScrollFrameMorph()
      newMorph.contents.acceptsDrops = true
      newMorph.contents.adjustBounds()
      newMorph.setExtent new Point(350, 250)
      create newMorph
    
    menu.addItem "handle", ->
      create new HandleMorph()
    
    menu.addLine()
    menu.addItem "string", ->
      newMorph = new StringMorph("Hello, World!")
      newMorph.isEditable = true
      create newMorph
    
    menu.addItem "text", ->
      newMorph = new TextMorph("Ich weiß nicht, was soll es bedeuten, dass ich so " +
        "traurig bin, ein Märchen aus uralten Zeiten, das " +
        "kommt mir nicht aus dem Sinn. Die Luft ist kühl " +
        "und es dunkelt, und ruhig fließt der Rhein; der " +
        "Gipfel des Berges funkelt im Abendsonnenschein. " +
        "Die schönste Jungfrau sitzet dort oben wunderbar, " +
        "ihr gold'nes Geschmeide blitzet, sie kämmt ihr " +
        "goldenes Haar, sie kämmt es mit goldenem Kamme, " +
        "und singt ein Lied dabei; das hat eine wundersame, " +
        "gewalt'ge Melodei. Den Schiffer im kleinen " +
        "Schiffe, ergreift es mit wildem Weh; er schaut " +
        "nicht die Felsenriffe, er schaut nur hinauf in " +
        "die Höh'. Ich glaube, die Wellen verschlingen " +
        "am Ende Schiffer und Kahn, und das hat mit ihrem " +
        "Singen, die Loreley getan.")
      newMorph.isEditable = true
      newMorph.maxWidth = 300
      newMorph.updateRendering()
      create newMorph
    
    menu.addItem "speech bubble", ->
      newMorph = new SpeechBubbleMorph("Hello, World!")
      create newMorph
    
    menu.addLine()
    menu.addItem "gray scale palette", ->
      create new GrayPaletteMorph()
    
    menu.addItem "color palette", ->
      create new ColorPaletteMorph()
    
    menu.addItem "color picker", ->
      create new ColorPickerMorph()
    
    menu.addLine()
    menu.addItem "sensor demo", ->
      newMorph = new MouseSensorMorph()
      newMorph.setColor new Color(230, 200, 100)
      newMorph.edge = 35
      newMorph.border = 15
      newMorph.borderColor = new Color(200, 100, 50)
      newMorph.alpha = 0.2
      newMorph.setExtent new Point(100, 100)
      create newMorph
    
    menu.addItem "animation demo", ->
      foo = new BouncerMorph()
      foo.setPosition new Point(50, 20)
      foo.setExtent new Point(300, 200)
      foo.alpha = 0.9
      foo.speed = 3
      bar = new BouncerMorph()
      bar.setColor new Color(50, 50, 50)
      bar.setPosition new Point(80, 80)
      bar.setExtent new Point(80, 250)
      bar.type = "horizontal"
      bar.direction = "right"
      bar.alpha = 0.9
      bar.speed = 5
      baz = new BouncerMorph()
      baz.setColor new Color(20, 20, 20)
      baz.setPosition new Point(90, 140)
      baz.setExtent new Point(40, 30)
      baz.type = "horizontal"
      baz.direction = "right"
      baz.speed = 3
      garply = new BouncerMorph()
      garply.setColor new Color(200, 20, 20)
      garply.setPosition new Point(90, 140)
      garply.setExtent new Point(20, 20)
      garply.type = "vertical"
      garply.direction = "up"
      garply.speed = 8
      fred = new BouncerMorph()
      fred.setColor new Color(20, 200, 20)
      fred.setPosition new Point(120, 140)
      fred.setExtent new Point(20, 20)
      fred.type = "vertical"
      fred.direction = "down"
      fred.speed = 4
      bar.add garply
      bar.add baz
      foo.add fred
      foo.add bar
      create foo
    
    menu.addItem "pen", ->
      create new PenMorph()
    
    menu.addLine()
    menu.addItem "view all...", ->
      newMorph = new MorphsListMorph()
      create newMorph
    menu.addItem "closing window", ->
      newMorph = new WorkspaceMorph()
      create newMorph

    if @customMorphs
      menu.addLine()
      @customMorphs().forEach (morph) ->
        menu.addItem morph.toString(), ->
          create morph
    
    menu.popUpAtHand @
  
  toggleDevMode: ->
    @isDevMode = not @isDevMode
  
  hideAll: ->
    @children.forEach (child) ->
      child.hide()
  
  showAllHiddens: ->
    @forAllChildren (child) ->
      child.show()  unless child.isVisible
  
  about: ->
    versions = ""
    for module of modules
      if Object.prototype.hasOwnProperty.call(modules, module)
        versions += ("\n" + module + " (" + modules[module] + ")")  
    if versions isnt ""
      versions = "\n\nmodules:\n\n" + "morphic (" + morphicVersion + ")" + versions  
    @inform "Zombie kernel\n\n" +
      "a lively Web GUI\ninspired by Squeak\n" +
      morphicVersion +
      "\n\nby Davide Della Casa" +
      "\n\nbased on morphic.js by" +
      "\nJens Mönig (jens@moenig.org)"
  
  edit: (aStringMorphOrTextMorph) ->
    # first off, if the Morph is not editable
    # then there is nothing to do
    return null  unless aStringMorphOrTextMorph.isEditable

    # there is only one caret in the World, so destroy
    # the previous one if there was one.
    if @caret
      # empty the previously ongoing selection
      # if there was one.
      @lastEditedText = @caret.target
      @lastEditedText.clearSelection()  if @lastEditedText
      @caret.destroy()

    # create the new Caret
    @caret = new CaretMorph(aStringMorphOrTextMorph)
    aStringMorphOrTextMorph.parent.add @caret
    @keyboardReceiver = @caret
    @initVirtualKeyboard()
    if WorldMorph.MorphicPreferences.isTouchDevice and WorldMorph.MorphicPreferences.useVirtualKeyboard
      pos = getDocumentPositionOf(@worldCanvas)
      @virtualKeyboard.style.top = @caret.top() + pos.y + "px"
      @virtualKeyboard.style.left = @caret.left() + pos.x + "px"
      @virtualKeyboard.focus()
    if WorldMorph.MorphicPreferences.useSliderForInput
      if !aStringMorphOrTextMorph.parentThatIsA(MenuMorph)
        @slide aStringMorphOrTextMorph
  
  # Editing can stop because of three reasons:
  #   cancel (user hits ESC)
  #   accept (on stringmorph, user hits enter)
  #   user clicks/drags another morph
  stopEditing: ->
    if @caret
      @lastEditedText = @caret.target
      @lastEditedText.clearSelection()
      @lastEditedText.escalateEvent "reactToEdit", @lastEditedText
      @caret.destroy()
      @caret = null
    @keyboardReceiver = null
    if @virtualKeyboard
      @virtualKeyboard.blur()
      document.body.removeChild @virtualKeyboard
      @virtualKeyboard = null
    @worldCanvas.focus()
  
  slide: (aStringMorphOrTextMorph) ->
    # display a slider for numeric text entries
    val = parseFloat(aStringMorphOrTextMorph.text)
    val = 0  if isNaN(val)
    menu = new MenuMorph()
    slider = new SliderMorph(val - 25, val + 25, val, 10, "horizontal")
    slider.alpha = 1
    slider.color = new Color(225, 225, 225)
    slider.button.color = menu.borderColor
    slider.button.highlightColor = slider.button.color.copy()
    slider.button.highlightColor.b += 100
    slider.button.pressColor = slider.button.color.copy()
    slider.button.pressColor.b += 150
    slider.silentSetHeight WorldMorph.MorphicPreferences.scrollBarSize
    slider.silentSetWidth WorldMorph.MorphicPreferences.menuFontSize * 10
    slider.updateRendering()
    slider.action = (num) ->
      aStringMorphOrTextMorph.changed()
      aStringMorphOrTextMorph.text = Math.round(num).toString()
      aStringMorphOrTextMorph.updateRendering()
      aStringMorphOrTextMorph.changed()
      aStringMorphOrTextMorph.escalateEvent(
          'reactToSliderEdit',
          aStringMorphOrTextMorph
      )
    #
    menu.items.push slider
    menu.popup @, aStringMorphOrTextMorph.bottomLeft().add(new Point(0, 5))
  
  toggleBlurredShadows: ->
    useBlurredShadows = not useBlurredShadows
  
  togglePreferences: ->
    if WorldMorph.MorphicPreferences is standardSettings
      WorldMorph.MorphicPreferences = touchScreenSettings
    else
      WorldMorph.MorphicPreferences = standardSettings
  '''
# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text caret

class BlinkerMorph extends Morph
  constructor: (@fps = 2) ->
    super()
    @color = new Color(0, 0, 0)
    @updateRendering()
  
  # BlinkerMorph stepping:
  step: ->
    @toggleVisibility()

  @coffeeScriptSourceOfThisClass: '''
# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text caret

class BlinkerMorph extends Morph
  constructor: (@fps = 2) ->
    super()
    @color = new Color(0, 0, 0)
    @updateRendering()
  
  # BlinkerMorph stepping:
  step: ->
    @toggleVisibility()
  '''
# CaretMorph /////////////////////////////////////////////////////////

# I am a String/Text editing widget

class CaretMorph extends BlinkerMorph

  keyDownEventUsed: false
  target: null
  originalContents: null
  slot: null
  viewPadding: 1

  constructor: (@target) ->
    # additional properties:
    @originalContents = @target.text
    @originalAlignment = @target.alignment
    @slot = @target.text.length
    super()
    ls = fontHeight(@target.fontSize)
    @setExtent new Point(Math.max(Math.floor(ls / 20), 1), ls)
    @updateRendering()
    @image.getContext("2d").font = @target.font()
    if (@target instanceof TextMorph && (@target.alignment != 'left'))
      @target.setAlignmentToLeft()
    @gotoSlot @slot
  
  # CaretMorph event processing:
  processKeyPress: (event) ->
    # @inspectKeyEvent event
    if @keyDownEventUsed
      @keyDownEventUsed = false
      return null
    if (event.keyCode is 40) or event.charCode is 40
      @insert "("
      return null
    if (event.keyCode is 37) or event.charCode is 37
      @insert "%"
      return null
    if event.keyCode # Opera doesn't support charCode
      if event.ctrlKey
        @ctrl event.keyCode
      else if event.metaKey
        @cmd event.keyCode
      else
        @insert String.fromCharCode(event.keyCode), event.shiftKey
    else if event.charCode # all other browsers
      if event.ctrlKey
        @ctrl event.charCode
      else if event.metaKey
        @cmd event.keyCode
      else
        @insert String.fromCharCode(event.charCode), event.shiftKey
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", event
  
  processKeyDown: (event) ->
    # this.inspectKeyEvent(event);
    shift = event.shiftKey
    @keyDownEventUsed = false
    if event.ctrlKey
      @ctrl event.keyCode
      # notify target's parent of key event
      @target.escalateEvent "reactToKeystroke", event
      return
    else if event.metaKey
      @cmd event.keyCode
      # notify target's parent of key event
      @target.escalateEvent "reactToKeystroke", event
      return
    switch event.keyCode
      when 37
        @goLeft(shift)
        @keyDownEventUsed = true
      when 39
        @goRight(shift)
        @keyDownEventUsed = true
      when 38
        @goUp(shift)
        @keyDownEventUsed = true
      when 40
        @goDown(shift)
        @keyDownEventUsed = true
      when 36
        @goHome(shift)
        @keyDownEventUsed = true
      when 35
        @goEnd(shift)
        @keyDownEventUsed = true
      when 46
        @deleteRight()
        @keyDownEventUsed = true
      when 8
        @deleteLeft()
        @keyDownEventUsed = true
      when 13
        # we can't check the class using instanceOf
        # because TextMorphs are instances of StringMorphs
        # but they want the enter to insert a carriage return.
        if @target.constructor.name == "StringMorph"
          @accept()
        else
          @insert "\n"
        @keyDownEventUsed = true
      when 27
        @cancel()
        @keyDownEventUsed = true
      else
    # this.inspectKeyEvent(event);
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", event
  
  
  # CaretMorph navigation - simple version
  #gotoSlot: (newSlot) ->
  #  @setPosition @target.slotCoordinates(newSlot)
  #  @slot = Math.max(newSlot, 0)

  gotoSlot: (slot) ->
    # check that slot is within the allowed boundaries of
    # of zero and text length.
    length = @target.text.length
    @slot = (if slot < 0 then 0 else (if slot > length then length else slot))

    pos = @target.slotCoordinates(@slot)
    if @parent and @target.isScrollable
      right = @parent.right() - @viewPadding
      left = @parent.left() + @viewPadding
      if pos.x > right
        @target.setLeft @target.left() + right - pos.x
        pos.x = right
      if pos.x < left
        left = Math.min(@parent.left(), left)
        @target.setLeft @target.left() + left - pos.x
        pos.x = left
      if @target.right() < right and right - @target.width() < left
        pos.x += right - @target.right()
        @target.setRight right
    @show()
    @setPosition pos

    if @parent and @parent.parent instanceof ScrollFrameMorph and @target.isScrollable
      @parent.parent.scrollCaretIntoView @
  
  goLeft: (shift) ->
    @updateSelection shift
    @gotoSlot @slot - 1
    @updateSelection shift
  
  goRight: (shift, howMany) ->
    @updateSelection shift
    @gotoSlot @slot + (howMany || 1)
    @updateSelection shift
  
  goUp: (shift) ->
    @updateSelection shift
    @gotoSlot @target.upFrom(@slot)
    @updateSelection shift
  
  goDown: (shift) ->
    @updateSelection shift
    @gotoSlot @target.downFrom(@slot)
    @updateSelection shift
  
  goHome: (shift) ->
    @updateSelection shift
    @gotoSlot @target.startOfLine(@slot)
    @updateSelection shift
  
  goEnd: (shift) ->
    @updateSelection shift
    @gotoSlot @target.endOfLine(@slot)
    @updateSelection shift
  
  gotoPos: (aPoint) ->
    @gotoSlot @target.slotAt(aPoint)
    @show()

  updateSelection: (shift) ->
    if shift
      if (@target.endMark is null) and (@target.startMark is null)
        @target.startMark = @slot
        @target.endMark = @slot
      else if @target.endMark isnt @slot
        @target.endMark = @slot
        @target.updateRendering()
        @target.changed()
    else
      @target.clearSelection()  
  
  # CaretMorph editing.

  # User presses enter on a stringMorph
  accept: ->
    world = @root()
    world.stopEditing()  if world
    @escalateEvent "accept", null
  
  # User presses ESC
  cancel: ->
    world = @root()
    @undo()
    world.stopEditing()  if world
    @escalateEvent 'cancel', null
    
  # User presses CTRL-Z or CMD-Z
  # Note that this is not a real undo,
  # what we are doing here is just reverting
  # all the changes and sort-of-resetting the
  # state of the target.
  undo: ->
    @target.text = @originalContents
    @target.clearSelection()
    
    # in theory these three lines are not
    # needed because clearSelection runs them
    # already, but I'm leaving them here
    # until I understand better this changed
    # vs. updateRendering semantics.
    @target.changed()
    @target.updateRendering()
    @target.changed()

    @gotoSlot 0
  
  insert: (aChar, shiftKey) ->
    if aChar is "\t"
      @target.escalateEvent 'reactToEdit', @target
      if shiftKey
        return @target.backTab(@target);
      return @target.tab(@target)
    if not @target.isNumeric or not isNaN(parseFloat(aChar)) or contains(["-", "."], aChar)
      if @target.selection() isnt ""
        @gotoSlot @target.selectionStartSlot()
        @target.deleteSelection()
      text = @target.text
      text = text.slice(0, @slot) + aChar + text.slice(@slot)
      @target.text = text
      @target.updateRendering()
      @target.changed()
      @goRight false, aChar.length
  
  ctrl: (aChar) ->
    if (aChar is 97) or (aChar is 65)
      @target.selectAll()
    else if aChar is 90
      @undo()
    else if aChar is 123
      @insert "{"
    else if aChar is 125
      @insert "}"
    else if aChar is 91
      @insert "["
    else if aChar is 93
      @insert "]"
    else if aChar is 64
      @insert "@"
  
  cmd: (aChar) ->
    if aChar is 65
      @target.selectAll()
    else if aChar is 90
      @undo()
  
  deleteRight: ->
    if @target.selection() isnt ""
      @gotoSlot @target.selectionStartSlot()
      @target.deleteSelection()
    else
      text = @target.text
      @target.changed()
      text = text.slice(0, @slot) + text.slice(@slot + 1)
      @target.text = text
      @target.updateRendering()
  
  deleteLeft: ->
    if @target.selection()
      @gotoSlot @target.selectionStartSlot()
      return @target.deleteSelection()
    text = @target.text
    @target.changed()
    @target.text = text.substring(0, @slot - 1) + text.substr(@slot)
    @target.updateRendering()
    @goLeft()

  # CaretMorph destroying:
  destroy: ->
    if @target.alignment isnt @originalAlignment
      @target.alignment = @originalAlignment
      @target.updateRendering()
      @target.changed()
    super  
  
  # CaretMorph utilities:
  inspectKeyEvent: (event) ->
    # private
    @inform "Key pressed: " + String.fromCharCode(event.charCode) + "\n------------------------" + "\ncharCode: " + event.charCode.toString() + "\nkeyCode: " + event.keyCode.toString() + "\naltKey: " + event.altKey.toString() + "\nctrlKey: " + event.ctrlKey.toString()  + "\ncmdKey: " + event.metaKey.toString()

  @coffeeScriptSourceOfThisClass: '''
# CaretMorph /////////////////////////////////////////////////////////

# I am a String/Text editing widget

class CaretMorph extends BlinkerMorph

  keyDownEventUsed: false
  target: null
  originalContents: null
  slot: null
  viewPadding: 1

  constructor: (@target) ->
    # additional properties:
    @originalContents = @target.text
    @originalAlignment = @target.alignment
    @slot = @target.text.length
    super()
    ls = fontHeight(@target.fontSize)
    @setExtent new Point(Math.max(Math.floor(ls / 20), 1), ls)
    @updateRendering()
    @image.getContext("2d").font = @target.font()
    if (@target instanceof TextMorph && (@target.alignment != 'left'))
      @target.setAlignmentToLeft()
    @gotoSlot @slot
  
  # CaretMorph event processing:
  processKeyPress: (event) ->
    # @inspectKeyEvent event
    if @keyDownEventUsed
      @keyDownEventUsed = false
      return null
    if (event.keyCode is 40) or event.charCode is 40
      @insert "("
      return null
    if (event.keyCode is 37) or event.charCode is 37
      @insert "%"
      return null
    if event.keyCode # Opera doesn't support charCode
      if event.ctrlKey
        @ctrl event.keyCode
      else if event.metaKey
        @cmd event.keyCode
      else
        @insert String.fromCharCode(event.keyCode), event.shiftKey
    else if event.charCode # all other browsers
      if event.ctrlKey
        @ctrl event.charCode
      else if event.metaKey
        @cmd event.keyCode
      else
        @insert String.fromCharCode(event.charCode), event.shiftKey
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", event
  
  processKeyDown: (event) ->
    # this.inspectKeyEvent(event);
    shift = event.shiftKey
    @keyDownEventUsed = false
    if event.ctrlKey
      @ctrl event.keyCode
      # notify target's parent of key event
      @target.escalateEvent "reactToKeystroke", event
      return
    else if event.metaKey
      @cmd event.keyCode
      # notify target's parent of key event
      @target.escalateEvent "reactToKeystroke", event
      return
    switch event.keyCode
      when 37
        @goLeft(shift)
        @keyDownEventUsed = true
      when 39
        @goRight(shift)
        @keyDownEventUsed = true
      when 38
        @goUp(shift)
        @keyDownEventUsed = true
      when 40
        @goDown(shift)
        @keyDownEventUsed = true
      when 36
        @goHome(shift)
        @keyDownEventUsed = true
      when 35
        @goEnd(shift)
        @keyDownEventUsed = true
      when 46
        @deleteRight()
        @keyDownEventUsed = true
      when 8
        @deleteLeft()
        @keyDownEventUsed = true
      when 13
        # we can't check the class using instanceOf
        # because TextMorphs are instances of StringMorphs
        # but they want the enter to insert a carriage return.
        if @target.constructor.name == "StringMorph"
          @accept()
        else
          @insert "\n"
        @keyDownEventUsed = true
      when 27
        @cancel()
        @keyDownEventUsed = true
      else
    # this.inspectKeyEvent(event);
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", event
  
  
  # CaretMorph navigation - simple version
  #gotoSlot: (newSlot) ->
  #  @setPosition @target.slotCoordinates(newSlot)
  #  @slot = Math.max(newSlot, 0)

  gotoSlot: (slot) ->
    # check that slot is within the allowed boundaries of
    # of zero and text length.
    length = @target.text.length
    @slot = (if slot < 0 then 0 else (if slot > length then length else slot))

    pos = @target.slotCoordinates(@slot)
    if @parent and @target.isScrollable
      right = @parent.right() - @viewPadding
      left = @parent.left() + @viewPadding
      if pos.x > right
        @target.setLeft @target.left() + right - pos.x
        pos.x = right
      if pos.x < left
        left = Math.min(@parent.left(), left)
        @target.setLeft @target.left() + left - pos.x
        pos.x = left
      if @target.right() < right and right - @target.width() < left
        pos.x += right - @target.right()
        @target.setRight right
    @show()
    @setPosition pos

    if @parent and @parent.parent instanceof ScrollFrameMorph and @target.isScrollable
      @parent.parent.scrollCaretIntoView @
  
  goLeft: (shift) ->
    @updateSelection shift
    @gotoSlot @slot - 1
    @updateSelection shift
  
  goRight: (shift, howMany) ->
    @updateSelection shift
    @gotoSlot @slot + (howMany || 1)
    @updateSelection shift
  
  goUp: (shift) ->
    @updateSelection shift
    @gotoSlot @target.upFrom(@slot)
    @updateSelection shift
  
  goDown: (shift) ->
    @updateSelection shift
    @gotoSlot @target.downFrom(@slot)
    @updateSelection shift
  
  goHome: (shift) ->
    @updateSelection shift
    @gotoSlot @target.startOfLine(@slot)
    @updateSelection shift
  
  goEnd: (shift) ->
    @updateSelection shift
    @gotoSlot @target.endOfLine(@slot)
    @updateSelection shift
  
  gotoPos: (aPoint) ->
    @gotoSlot @target.slotAt(aPoint)
    @show()

  updateSelection: (shift) ->
    if shift
      if (@target.endMark is null) and (@target.startMark is null)
        @target.startMark = @slot
        @target.endMark = @slot
      else if @target.endMark isnt @slot
        @target.endMark = @slot
        @target.updateRendering()
        @target.changed()
    else
      @target.clearSelection()  
  
  # CaretMorph editing.

  # User presses enter on a stringMorph
  accept: ->
    world = @root()
    world.stopEditing()  if world
    @escalateEvent "accept", null
  
  # User presses ESC
  cancel: ->
    world = @root()
    @undo()
    world.stopEditing()  if world
    @escalateEvent 'cancel', null
    
  # User presses CTRL-Z or CMD-Z
  # Note that this is not a real undo,
  # what we are doing here is just reverting
  # all the changes and sort-of-resetting the
  # state of the target.
  undo: ->
    @target.text = @originalContents
    @target.clearSelection()
    
    # in theory these three lines are not
    # needed because clearSelection runs them
    # already, but I'm leaving them here
    # until I understand better this changed
    # vs. updateRendering semantics.
    @target.changed()
    @target.updateRendering()
    @target.changed()

    @gotoSlot 0
  
  insert: (aChar, shiftKey) ->
    if aChar is "\t"
      @target.escalateEvent 'reactToEdit', @target
      if shiftKey
        return @target.backTab(@target);
      return @target.tab(@target)
    if not @target.isNumeric or not isNaN(parseFloat(aChar)) or contains(["-", "."], aChar)
      if @target.selection() isnt ""
        @gotoSlot @target.selectionStartSlot()
        @target.deleteSelection()
      text = @target.text
      text = text.slice(0, @slot) + aChar + text.slice(@slot)
      @target.text = text
      @target.updateRendering()
      @target.changed()
      @goRight false, aChar.length
  
  ctrl: (aChar) ->
    if (aChar is 97) or (aChar is 65)
      @target.selectAll()
    else if aChar is 90
      @undo()
    else if aChar is 123
      @insert "{"
    else if aChar is 125
      @insert "}"
    else if aChar is 91
      @insert "["
    else if aChar is 93
      @insert "]"
    else if aChar is 64
      @insert "@"
  
  cmd: (aChar) ->
    if aChar is 65
      @target.selectAll()
    else if aChar is 90
      @undo()
  
  deleteRight: ->
    if @target.selection() isnt ""
      @gotoSlot @target.selectionStartSlot()
      @target.deleteSelection()
    else
      text = @target.text
      @target.changed()
      text = text.slice(0, @slot) + text.slice(@slot + 1)
      @target.text = text
      @target.updateRendering()
  
  deleteLeft: ->
    if @target.selection()
      @gotoSlot @target.selectionStartSlot()
      return @target.deleteSelection()
    text = @target.text
    @target.changed()
    @target.text = text.substring(0, @slot - 1) + text.substr(@slot)
    @target.updateRendering()
    @goLeft()

  # CaretMorph destroying:
  destroy: ->
    if @target.alignment isnt @originalAlignment
      @target.alignment = @originalAlignment
      @target.updateRendering()
      @target.changed()
    super  
  
  # CaretMorph utilities:
  inspectKeyEvent: (event) ->
    # private
    @inform "Key pressed: " + String.fromCharCode(event.charCode) + "\n------------------------" + "\ncharCode: " + event.charCode.toString() + "\nkeyCode: " + event.keyCode.toString() + "\naltKey: " + event.altKey.toString() + "\nctrlKey: " + event.ctrlKey.toString()  + "\ncmdKey: " + event.metaKey.toString()
  '''
# ColorPickerMorph ///////////////////////////////////////////////////

class ColorPickerMorph extends Morph

  choice: null

  constructor: (defaultColor) ->
    @choice = defaultColor or new Color(255, 255, 255)
    super()
    @color = new Color(255, 255, 255)
    @silentSetExtent new Point(80, 80)
    @updateRendering()
  
  updateRendering: ->
    super()
    @buildSubmorphs()
  
  buildSubmorphs: ->
    @children.forEach (child) ->
      child.destroy()
    @children = []
    @feedback = new Morph()
    @feedback.color = @choice
    @feedback.setExtent new Point(20, 20)
    cpal = new ColorPaletteMorph(@feedback, new Point(@width(), 50))
    gpal = new GrayPaletteMorph(@feedback, new Point(@width(), 5))
    cpal.setPosition @bounds.origin
    @add cpal
    gpal.setPosition cpal.bottomLeft()
    @add gpal
    x = (gpal.left() + Math.floor((gpal.width() - @feedback.width()) / 2))
    y = gpal.bottom() + Math.floor((@bottom() - gpal.bottom() - @feedback.height()) / 2)
    @feedback.setPosition new Point(x, y)
    @add @feedback
  
  getChoice: ->
    @feedback.color
  
  rootForGrab: ->
    @

  @coffeeScriptSourceOfThisClass: '''
# ColorPickerMorph ///////////////////////////////////////////////////

class ColorPickerMorph extends Morph

  choice: null

  constructor: (defaultColor) ->
    @choice = defaultColor or new Color(255, 255, 255)
    super()
    @color = new Color(255, 255, 255)
    @silentSetExtent new Point(80, 80)
    @updateRendering()
  
  updateRendering: ->
    super()
    @buildSubmorphs()
  
  buildSubmorphs: ->
    @children.forEach (child) ->
      child.destroy()
    @children = []
    @feedback = new Morph()
    @feedback.color = @choice
    @feedback.setExtent new Point(20, 20)
    cpal = new ColorPaletteMorph(@feedback, new Point(@width(), 50))
    gpal = new GrayPaletteMorph(@feedback, new Point(@width(), 5))
    cpal.setPosition @bounds.origin
    @add cpal
    gpal.setPosition cpal.bottomLeft()
    @add gpal
    x = (gpal.left() + Math.floor((gpal.width() - @feedback.width()) / 2))
    y = gpal.bottom() + Math.floor((@bottom() - gpal.bottom() - @feedback.height()) / 2)
    @feedback.setPosition new Point(x, y)
    @add @feedback
  
  getChoice: ->
    @feedback.color
  
  rootForGrab: ->
    @
  '''
# ColorPaletteMorph ///////////////////////////////////////////////////

class ColorPaletteMorph extends Morph

  target: null
  targetSetter: "color"
  choice: null

  constructor: (@target = null, sizePoint) ->
    super()
    @silentSetExtent sizePoint or new Point(80, 50)
    @updateRendering()
  
  updateRendering: ->
    ext = @extent()
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    @choice = new Color()
    for x in [0..ext.x]
      h = 360 * x / ext.x
      y = 0
      for y in [0..ext.y]
        l = 100 - (y / ext.y * 100)
        context.fillStyle = "hsl(" + h + ",100%," + l + "%)"
        context.fillRect x, y, 1, 1
  
  mouseMove: (pos) ->
    @choice = @getPixelColor(pos)
    @updateTarget()
  
  mouseDownLeft: (pos) ->
    @choice = @getPixelColor(pos)
    @updateTarget()
  
  updateTarget: ->
    if @target instanceof Morph and @choice isnt null
      if @target[@targetSetter] instanceof Function
        @target[@targetSetter] @choice
      else
        @target[@targetSetter] = @choice
        @target.updateRendering()
        @target.changed()
  
  
  # ColorPaletteMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.target = (dict[@target])  if c.target and dict[@target]
    c
  
  # ColorPaletteMorph menu:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "set target", "setTarget", "choose another morph\nwhose color property\n will be" + " controlled by this one"
    menu
  
  setTarget: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.push @world()
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), =>
        @target = each
        @setTargetSetter()
    if choices.length is 1
      @target = choices[0]
      @setTargetSetter()
    else menu.popUpAtHand @world()  if choices.length
  
  setTargetSetter: ->
    choices = @target.colorSetters()
    menu = new MenuMorph(@, "choose target property:")
    choices.forEach (each) =>
      menu.addItem each, =>
        @targetSetter = each
    if choices.length is 1
      @targetSetter = choices[0]
    else menu.popUpAtHand @world()  if choices.length

  @coffeeScriptSourceOfThisClass: '''
# ColorPaletteMorph ///////////////////////////////////////////////////

class ColorPaletteMorph extends Morph

  target: null
  targetSetter: "color"
  choice: null

  constructor: (@target = null, sizePoint) ->
    super()
    @silentSetExtent sizePoint or new Point(80, 50)
    @updateRendering()
  
  updateRendering: ->
    ext = @extent()
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    @choice = new Color()
    for x in [0..ext.x]
      h = 360 * x / ext.x
      y = 0
      for y in [0..ext.y]
        l = 100 - (y / ext.y * 100)
        context.fillStyle = "hsl(" + h + ",100%," + l + "%)"
        context.fillRect x, y, 1, 1
  
  mouseMove: (pos) ->
    @choice = @getPixelColor(pos)
    @updateTarget()
  
  mouseDownLeft: (pos) ->
    @choice = @getPixelColor(pos)
    @updateTarget()
  
  updateTarget: ->
    if @target instanceof Morph and @choice isnt null
      if @target[@targetSetter] instanceof Function
        @target[@targetSetter] @choice
      else
        @target[@targetSetter] = @choice
        @target.updateRendering()
        @target.changed()
  
  
  # ColorPaletteMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.target = (dict[@target])  if c.target and dict[@target]
    c
  
  # ColorPaletteMorph menu:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "set target", "setTarget", "choose another morph\nwhose color property\n will be" + " controlled by this one"
    menu
  
  setTarget: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.push @world()
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), =>
        @target = each
        @setTargetSetter()
    if choices.length is 1
      @target = choices[0]
      @setTargetSetter()
    else menu.popUpAtHand @world()  if choices.length
  
  setTargetSetter: ->
    choices = @target.colorSetters()
    menu = new MenuMorph(@, "choose target property:")
    choices.forEach (each) =>
      menu.addItem each, =>
        @targetSetter = each
    if choices.length is 1
      @targetSetter = choices[0]
    else menu.popUpAtHand @world()  if choices.length
  '''
# GrayPaletteMorph ///////////////////////////////////////////////////

class GrayPaletteMorph extends ColorPaletteMorph

  constructor: (@target = null, sizePoint) ->
    super @target, sizePoint or new Point(80, 10)
  
  updateRendering: ->
    ext = @extent()
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    @choice = new Color()
    gradient = context.createLinearGradient(0, 0, ext.x, ext.y)
    gradient.addColorStop 0, "black"
    gradient.addColorStop 1, "white"
    context.fillStyle = gradient
    context.fillRect 0, 0, ext.x, ext.y

  @coffeeScriptSourceOfThisClass: '''
# GrayPaletteMorph ///////////////////////////////////////////////////

class GrayPaletteMorph extends ColorPaletteMorph

  constructor: (@target = null, sizePoint) ->
    super @target, sizePoint or new Point(80, 10)
  
  updateRendering: ->
    ext = @extent()
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    @choice = new Color()
    gradient = context.createLinearGradient(0, 0, ext.x, ext.y)
    gradient.addColorStop 0, "black"
    gradient.addColorStop 1, "white"
    context.fillStyle = gradient
    context.fillRect 0, 0, ext.x, ext.y
  '''
# BoxMorph ////////////////////////////////////////////////////////////

# I can have an optionally rounded border

class BoxMorph extends Morph

  edge: null
  border: null
  borderColor: null

  constructor: (@edge = 4, border, borderColor) ->
    @border = border or ((if (border is 0) then 0 else 2))
    @borderColor = borderColor or new Color()
    super()
  
  # BoxMorph drawing:
  updateRendering: ->
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    if (@edge is 0) and (@border is 0)
      super()
      return null
    context.fillStyle = @color.toString()
    context.beginPath()
    @outlinePath context, Math.max(@edge - @border, 0), @border
    context.closePath()
    context.fill()
    if @border > 0
      context.lineWidth = @border
      context.strokeStyle = @borderColor.toString()
      context.beginPath()
      @outlinePath context, @edge, @border / 2
      context.closePath()
      context.stroke()
  
  outlinePath: (context, radius, inset) ->
    offset = radius + inset
    w = @width()
    h = @height()
    # top left:
    context.arc offset, offset, radius, radians(-180), radians(-90), false
    # top right:
    context.arc w - offset, offset, radius, radians(-90), radians(-0), false
    # bottom right:
    context.arc w - offset, h - offset, radius, radians(0), radians(90), false
    # bottom left:
    context.arc offset, h - offset, radius, radians(90), radians(180), false
  
  
  # BoxMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "border width...", (->
      @prompt menu.title + "\nborder\nwidth:",
        @setBorderWidth,
        @,
        @border.toString(),
        null,
        0,
        100,
        true
    ), "set the border's\nline size"
    menu.addItem "border color...", (->
      @pickColor menu.title + "\nborder color:", @setBorderColor, @, @borderColor
    ), "set the border's\nline color"
    menu.addItem "corner size...", (->
      @prompt menu.title + "\ncorner\nsize:",
        @setCornerSize,
        @,
        @edge.toString(),
        null,
        0,
        100,
        true
    ), "set the corner's\nradius"
    menu
  
  setBorderWidth: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @border = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @border = Math.max(newSize, 0)  unless isNaN(newSize)
    @updateRendering()
    @changed()
  
  setBorderColor: (color) ->
    # for context menu demo purposes
    if color
      @borderColor = color
      @updateRendering()
      @changed()
  
  setCornerSize: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @edge = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @edge = Math.max(newSize, 0)  unless isNaN(newSize)
    @updateRendering()
    @changed()
  
  colorSetters: ->
    # for context menu demo purposes
    ["color", "borderColor"]
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setBorderWidth", "setCornerSize"
    list

  @coffeeScriptSourceOfThisClass: '''
# BoxMorph ////////////////////////////////////////////////////////////

# I can have an optionally rounded border

class BoxMorph extends Morph

  edge: null
  border: null
  borderColor: null

  constructor: (@edge = 4, border, borderColor) ->
    @border = border or ((if (border is 0) then 0 else 2))
    @borderColor = borderColor or new Color()
    super()
  
  # BoxMorph drawing:
  updateRendering: ->
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    if (@edge is 0) and (@border is 0)
      super()
      return null
    context.fillStyle = @color.toString()
    context.beginPath()
    @outlinePath context, Math.max(@edge - @border, 0), @border
    context.closePath()
    context.fill()
    if @border > 0
      context.lineWidth = @border
      context.strokeStyle = @borderColor.toString()
      context.beginPath()
      @outlinePath context, @edge, @border / 2
      context.closePath()
      context.stroke()
  
  outlinePath: (context, radius, inset) ->
    offset = radius + inset
    w = @width()
    h = @height()
    # top left:
    context.arc offset, offset, radius, radians(-180), radians(-90), false
    # top right:
    context.arc w - offset, offset, radius, radians(-90), radians(-0), false
    # bottom right:
    context.arc w - offset, h - offset, radius, radians(0), radians(90), false
    # bottom left:
    context.arc offset, h - offset, radius, radians(90), radians(180), false
  
  
  # BoxMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "border width...", (->
      @prompt menu.title + "\nborder\nwidth:",
        @setBorderWidth,
        @,
        @border.toString(),
        null,
        0,
        100,
        true
    ), "set the border's\nline size"
    menu.addItem "border color...", (->
      @pickColor menu.title + "\nborder color:", @setBorderColor, @, @borderColor
    ), "set the border's\nline color"
    menu.addItem "corner size...", (->
      @prompt menu.title + "\ncorner\nsize:",
        @setCornerSize,
        @,
        @edge.toString(),
        null,
        0,
        100,
        true
    ), "set the corner's\nradius"
    menu
  
  setBorderWidth: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @border = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @border = Math.max(newSize, 0)  unless isNaN(newSize)
    @updateRendering()
    @changed()
  
  setBorderColor: (color) ->
    # for context menu demo purposes
    if color
      @borderColor = color
      @updateRendering()
      @changed()
  
  setCornerSize: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @edge = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @edge = Math.max(newSize, 0)  unless isNaN(newSize)
    @updateRendering()
    @changed()
  
  colorSetters: ->
    # for context menu demo purposes
    ["color", "borderColor"]
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setBorderWidth", "setCornerSize"
    list
  '''
# MouseSensorMorph ////////////////////////////////////////////////////

# for demo and debuggin purposes only, to be removed later
class MouseSensorMorph extends BoxMorph
  constructor: (edge, border, borderColor) ->
    super
    @edge = edge or 4
    @border = border or 2
    @color = new Color(255, 255, 255)
    @borderColor = borderColor or new Color()
    @isTouched = false
    @upStep = 0.05
    @downStep = 0.02
    @noticesTransparentClick = false
    @updateRendering()
  
  touch: ->
    unless @isTouched
      @isTouched = true
      @alpha = 0.6
      @step = =>
        if @isTouched
          @alpha = @alpha + @upStep  if @alpha < 1
        else if @alpha > (@downStep)
          @alpha = @alpha - @downStep
        else
          @alpha = 0
          @step = null
        @changed()
  
  unTouch: ->
    @isTouched = false
  
  mouseEnter: ->
    @touch()
  
  mouseLeave: ->
    @unTouch()
  
  mouseDownLeft: ->
    @touch()
  
  mouseClickLeft: ->
    @unTouch()

  @coffeeScriptSourceOfThisClass: '''
# MouseSensorMorph ////////////////////////////////////////////////////

# for demo and debuggin purposes only, to be removed later
class MouseSensorMorph extends BoxMorph
  constructor: (edge, border, borderColor) ->
    super
    @edge = edge or 4
    @border = border or 2
    @color = new Color(255, 255, 255)
    @borderColor = borderColor or new Color()
    @isTouched = false
    @upStep = 0.05
    @downStep = 0.02
    @noticesTransparentClick = false
    @updateRendering()
  
  touch: ->
    unless @isTouched
      @isTouched = true
      @alpha = 0.6
      @step = =>
        if @isTouched
          @alpha = @alpha + @upStep  if @alpha < 1
        else if @alpha > (@downStep)
          @alpha = @alpha - @downStep
        else
          @alpha = 0
          @step = null
        @changed()
  
  unTouch: ->
    @isTouched = false
  
  mouseEnter: ->
    @touch()
  
  mouseLeave: ->
    @unTouch()
  
  mouseDownLeft: ->
    @touch()
  
  mouseClickLeft: ->
    @unTouch()
  '''
class SystemTestsRecorderAndPlayer
  eventQueue: []
  recordingASystemTest: false
  replayingASystemTest: false
  lastRecordedEventTime: null
  handMorph: null
  systemInfo: null

  constructor: (@worldMorph, @handMorph) ->

  initialiseSystemInfo: ->
    @systemInfo = {}
    @systemInfo.zombieKernelTestHarnessVersionMajor = 0
    @systemInfo.zombieKernelTestHarnessVersionMinor = 1
    @systemInfo.zombieKernelTestHarnessVersionRelease = 0
    @systemInfo.userAgent = navigator.userAgent
    @systemInfo.screenWidth = window.screen.width
    @systemInfo.screenHeight = window.screen.height
    @systemInfo.screenColorDepth = window.screen.colorDepth
    if window.devicePixelRatio?
      @systemInfo.screenPixelRatio = window.devicePixelRatio
    else
      @systemInfo.screenPixelRatio = window.devicePixelRatio
    @systemInfo.appCodeName = navigator.appCodeName
    @systemInfo.appName = navigator.appName
    @systemInfo.appVersion = navigator.appVersion
    @systemInfo.cookieEnabled = navigator.cookieEnabled
    @systemInfo.platform = navigator.platform
    @systemInfo.systemLanguage = navigator.systemLanguage

  startTestRecording: ->
    # clean up the world so we start from clean slate
    @worldMorph.destroyAll()
    @eventQueue = []
    @lastRecordedEventTime = new Date().getTime()
    @recordingASystemTest = true
    @replayingASystemTest = false

    @initialiseSystemInfo()
    systemTestEvent = {}
    systemTestEvent.type = "systemInfo"
    systemTestEvent.time = 0
    systemTestEvent.systemInfo = @systemInfo
    @eventQueue.push systemTestEvent

  stopTestRecording: ->
    @recordingASystemTest = false

  startTestPlaying: ->
    @recordingASystemTest = false
    @replayingASystemTest = true
    @replayEvents()

  stopPlaying: ->
    @replayingASystemTest = false

  showTestSource: ->
    window.open("data:text/text;charset=utf-8," + encodeURIComponent(JSON.stringify( @eventQueue )))

  addMouseMoveEvent: (pageX, pageY) ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseMove"
    systemTestEvent.mouseX = pageX
    systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  addMouseDownEvent: (button, ctrlKey) ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseDown"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    systemTestEvent.button = button
    systemTestEvent.ctrlKey = ctrlKey
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  addMouseUpEvent: () ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseUp"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  takeScreenshot: () ->
    console.log "taking screenshot"
    if @systemInfo is null
      @initialiseSystemInfo()
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "takeScreenshot"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    systemTestEvent.screenShotImageData = []
    systemTestEvent.screenShotImageData.push [@systemInfo, @worldMorph.fullImageData()]
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime
    if not @recordingASystemTest
      return systemTestEvent

  compareScreenshots: (expected) ->
   i = 0
   console.log "expected length " + expected.length
   for a in expected
     console.log "trying to match screenshot: " + i
     i++
     if a[1] == @worldMorph.fullImageData()
      console.log "PASS - screenshot (" + i + ") matched"
      return
   console.log "FAIL - no screenshots like this one"

  replayEvents: () ->
   lastPlayedEventTime = 0
   console.log "events: " + @eventQueue
   for queuedEvent in @eventQueue
      lastPlayedEventTime += queuedEvent.time
      @scheduleEvent(queuedEvent, lastPlayedEventTime)

  scheduleEvent: (queuedEvent, lastPlayedEventTime) ->
    if queuedEvent.type == 'mouseMove'
      callback = => @handMorph.processMouseMove(queuedEvent.mouseX, queuedEvent.mouseY)
    else if queuedEvent.type == 'mouseDown'
      callback = => @handMorph.processMouseDown(queuedEvent.button, queuedEvent.ctrlKey)
    else if queuedEvent.type == 'mouseUp'
      callback = => @handMorph.processMouseUp()
    else if queuedEvent.type == 'takeScreenshot'
      callback = => @compareScreenshots(queuedEvent.screenShotImageData)
    else return

    setTimeout callback, lastPlayedEventTime
    #console.log "scheduling " + queuedEvent.type + "event for " + lastPlayedEventTime

  @coffeeScriptSourceOfThisClass: '''
class SystemTestsRecorderAndPlayer
  eventQueue: []
  recordingASystemTest: false
  replayingASystemTest: false
  lastRecordedEventTime: null
  handMorph: null
  systemInfo: null

  constructor: (@worldMorph, @handMorph) ->

  initialiseSystemInfo: ->
    @systemInfo = {}
    @systemInfo.zombieKernelTestHarnessVersionMajor = 0
    @systemInfo.zombieKernelTestHarnessVersionMinor = 1
    @systemInfo.zombieKernelTestHarnessVersionRelease = 0
    @systemInfo.userAgent = navigator.userAgent
    @systemInfo.screenWidth = window.screen.width
    @systemInfo.screenHeight = window.screen.height
    @systemInfo.screenColorDepth = window.screen.colorDepth
    if window.devicePixelRatio?
      @systemInfo.screenPixelRatio = window.devicePixelRatio
    else
      @systemInfo.screenPixelRatio = window.devicePixelRatio
    @systemInfo.appCodeName = navigator.appCodeName
    @systemInfo.appName = navigator.appName
    @systemInfo.appVersion = navigator.appVersion
    @systemInfo.cookieEnabled = navigator.cookieEnabled
    @systemInfo.platform = navigator.platform
    @systemInfo.systemLanguage = navigator.systemLanguage

  startTestRecording: ->
    # clean up the world so we start from clean slate
    @worldMorph.destroyAll()
    @eventQueue = []
    @lastRecordedEventTime = new Date().getTime()
    @recordingASystemTest = true
    @replayingASystemTest = false

    @initialiseSystemInfo()
    systemTestEvent = {}
    systemTestEvent.type = "systemInfo"
    systemTestEvent.time = 0
    systemTestEvent.systemInfo = @systemInfo
    @eventQueue.push systemTestEvent

  stopTestRecording: ->
    @recordingASystemTest = false

  startTestPlaying: ->
    @recordingASystemTest = false
    @replayingASystemTest = true
    @replayEvents()

  stopPlaying: ->
    @replayingASystemTest = false

  showTestSource: ->
    window.open("data:text/text;charset=utf-8," + encodeURIComponent(JSON.stringify( @eventQueue )))

  addMouseMoveEvent: (pageX, pageY) ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseMove"
    systemTestEvent.mouseX = pageX
    systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  addMouseDownEvent: (button, ctrlKey) ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseDown"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    systemTestEvent.button = button
    systemTestEvent.ctrlKey = ctrlKey
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  addMouseUpEvent: () ->
    return if not @recordingASystemTest
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "mouseUp"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    #systemTestEvent.screenShotImageData
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime

  takeScreenshot: () ->
    console.log "taking screenshot"
    if @systemInfo is null
      @initialiseSystemInfo()
    currentTime = new Date().getTime()
    systemTestEvent = {}
    systemTestEvent.type = "takeScreenshot"
    #systemTestEvent.mouseX = pageX
    #systemTestEvent.mouseY = pageY
    systemTestEvent.time = currentTime - @lastRecordedEventTime
    #systemTestEvent.button
    #systemTestEvent.ctrlKey
    systemTestEvent.screenShotImageData = []
    systemTestEvent.screenShotImageData.push [@systemInfo, @worldMorph.fullImageData()]
    @eventQueue.push systemTestEvent
    @lastRecordedEventTime = currentTime
    if not @recordingASystemTest
      return systemTestEvent

  compareScreenshots: (expected) ->
   i = 0
   console.log "expected length " + expected.length
   for a in expected
     console.log "trying to match screenshot: " + i
     i++
     if a[1] == @worldMorph.fullImageData()
      console.log "PASS - screenshot (" + i + ") matched"
      return
   console.log "FAIL - no screenshots like this one"

  replayEvents: () ->
   lastPlayedEventTime = 0
   console.log "events: " + @eventQueue
   for queuedEvent in @eventQueue
      lastPlayedEventTime += queuedEvent.time
      @scheduleEvent(queuedEvent, lastPlayedEventTime)

  scheduleEvent: (queuedEvent, lastPlayedEventTime) ->
    if queuedEvent.type == 'mouseMove'
      callback = => @handMorph.processMouseMove(queuedEvent.mouseX, queuedEvent.mouseY)
    else if queuedEvent.type == 'mouseDown'
      callback = => @handMorph.processMouseDown(queuedEvent.button, queuedEvent.ctrlKey)
    else if queuedEvent.type == 'mouseUp'
      callback = => @handMorph.processMouseUp()
    else if queuedEvent.type == 'takeScreenshot'
      callback = => @compareScreenshots(queuedEvent.screenShotImageData)
    else return

    setTimeout callback, lastPlayedEventTime
    #console.log "scheduling " + queuedEvent.type + "event for " + lastPlayedEventTime
  '''
# SliderMorph ///////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class SliderMorph extends CircleBoxMorph

  target: null
  action: null
  start: null
  stop: null
  value: null
  size: null
  offset: null
  button: null
  step: null

  constructor: (@start = 1, @stop = 100, @value = 50, @size = 10, orientation, color) ->
    @button = new SliderButtonMorph()
    @button.isDraggable = false
    @button.color = new Color(200, 200, 200)
    @button.highlightColor = new Color(210, 210, 255)
    @button.pressColor = new Color(180, 180, 255)
    super orientation # if null, then a vertical one will be created
    @add @button
    @alpha = 0.3
    @color = color or new Color(0, 0, 0)
    @setExtent new Point(20, 100)
  
  
  # this.updateRendering();
  autoOrientation: ->
      noOperation
  
  rangeSize: ->
    @stop - @start
  
  ratio: ->
    @size / @rangeSize()
  
  unitSize: ->
    return (@height() - @button.height()) / @rangeSize()  if @orientation is "vertical"
    (@width() - @button.width()) / @rangeSize()
  
  updateRendering: ->
    super()
    @button.orientation = @orientation
    if @orientation is "vertical"
      bw = @width() - 2
      bh = Math.max(bw, Math.round(@height() * @ratio()))
      @button.silentSetExtent new Point(bw, bh)
      posX = 1
      posY = Math.min(
        Math.round((@value - @start) * @unitSize()),
        @height() - @button.height())
    else
      bh = @height() - 2
      bw = Math.max(bh, Math.round(@width() * @ratio()))
      @button.silentSetExtent new Point(bw, bh)
      posY = 1
      posX = Math.min(
        Math.round((@value - @start) * @unitSize()),
        @width() - @button.width())
    @button.setPosition new Point(posX, posY).add(@bounds.origin)
    @button.updateRendering()
    @button.changed()
  
  updateValue: ->
    if @orientation is "vertical"
      relPos = @button.top() - @top()
    else
      relPos = @button.left() - @left()
    @value = Math.round(relPos / @unitSize() + @start)
    @updateTarget()
  
  updateTarget: ->
    if @action
      if typeof @action is "function"
        @action.call @target, @value
      else # assume it's a String
        @target[@action] @value
  
  
  # SliderMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.target = (dict[@target])  if c.target and dict[@target]
    c.button = (dict[@button])  if c.button and dict[@button]
    c
  
  
  # SliderMorph menu:
  developersMenu: ->
    menu = super()
    menu.addItem "show value...", "showValue", "display a dialog box\nshowing the selected number"
    menu.addItem "floor...", (->
      @prompt menu.title + "\nfloor:",
        @setStart,
        @,
        @start.toString(),
        null,
        0,
        @stop - @size,
        true
    ), "set the minimum value\nwhich can be selected"
    menu.addItem "ceiling...", (->
      @prompt menu.title + "\nceiling:",
        @setStop,
        @,
        @stop.toString(),
        null,
        @start + @size,
        @size * 100,
        true
    ), "set the maximum value\nwhich can be selected"
    menu.addItem "button size...", (->
      @prompt menu.title + "\nbutton size:",
        @setSize,
        @,
        @size.toString(),
        null,
        1,
        @stop - @start,
        true
    ), "set the range\ncovered by\nthe slider button"
    menu.addLine()
    menu.addItem "set target", "setTarget", "select another morph\nwhose numerical property\nwill be " + "controlled by this one"
    menu
  
  showValue: ->
    @inform @value
  
  userSetStart: (num) ->
    # for context menu demo purposes
    @start = Math.max(num, @stop)
  
  setStart: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @start = Math.min(Math.max(num, 0), @stop - @size)
    else
      newStart = parseFloat(num)
      @start = Math.min(Math.max(newStart, 0), @stop - @size)  unless isNaN(newStart)
    @value = Math.max(@value, @start)
    @updateTarget()
    @updateRendering()
    @changed()
  
  setStop: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @stop = Math.max(num, @start + @size)
    else
      newStop = parseFloat(num)
      @stop = Math.max(newStop, @start + @size)  unless isNaN(newStop)
    @value = Math.min(@value, @stop)
    @updateTarget()
    @updateRendering()
    @changed()
  
  setSize: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @size = Math.min(Math.max(num, 1), @stop - @start)
    else
      newSize = parseFloat(num)
      @size = Math.min(Math.max(newSize, 1), @stop - @start)  unless isNaN(newSize)
    @value = Math.min(@value, @stop - @size)
    @updateTarget()
    @updateRendering()
    @changed()
  
  setTarget: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.push @world()
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), =>
        @target = each
        @setTargetSetter()
    #
    if choices.length is 1
      @target = choices[0]
      @setTargetSetter()
    else menu.popUpAtHand @world()  if choices.length
  
  setTargetSetter: ->
    choices = @target.numericalSetters()
    menu = new MenuMorph(@, "choose target property:")
    choices.forEach (each) =>
      menu.addItem each, =>
        @action = each
    #
    if choices.length is 1
      @action = choices[0]
    else menu.popUpAtHand @world()  if choices.length
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setStart", "setStop", "setSize"
    list
  
  
  # SliderMorph stepping:
  mouseDownLeft: (pos) ->
    unless @button.bounds.containsPoint(pos)
      @offset = new Point() # return null;
    else
      @offset = pos.subtract(@button.bounds.origin)
    world = @root()
    # this is to create the "drag the slider" effect
    # basically if the mouse is pressing within the boundaries
    # then in the next step you remember to check again where the mouse
    # is and update the scrollbar. As soon as the mouse is unpressed
    # then the step function is set to null to save cycles.
    @step = =>
      if world.hand.mouseButton
        mousePos = world.hand.bounds.origin
        if @orientation is "vertical"
          newX = @button.bounds.origin.x
          newY = Math.max(
            Math.min(mousePos.y - @offset.y,
            @bottom() - @button.height()), @top())
        else
          newY = @button.bounds.origin.y
          newX = Math.max(
            Math.min(mousePos.x - @offset.x,
            @right() - @button.width()), @left())
        @button.setPosition new Point(newX, newY)
        @updateValue()
      else
        @step = null

  @coffeeScriptSourceOfThisClass: '''
# SliderMorph ///////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class SliderMorph extends CircleBoxMorph

  target: null
  action: null
  start: null
  stop: null
  value: null
  size: null
  offset: null
  button: null
  step: null

  constructor: (@start = 1, @stop = 100, @value = 50, @size = 10, orientation, color) ->
    @button = new SliderButtonMorph()
    @button.isDraggable = false
    @button.color = new Color(200, 200, 200)
    @button.highlightColor = new Color(210, 210, 255)
    @button.pressColor = new Color(180, 180, 255)
    super orientation # if null, then a vertical one will be created
    @add @button
    @alpha = 0.3
    @color = color or new Color(0, 0, 0)
    @setExtent new Point(20, 100)
  
  
  # this.updateRendering();
  autoOrientation: ->
      noOperation
  
  rangeSize: ->
    @stop - @start
  
  ratio: ->
    @size / @rangeSize()
  
  unitSize: ->
    return (@height() - @button.height()) / @rangeSize()  if @orientation is "vertical"
    (@width() - @button.width()) / @rangeSize()
  
  updateRendering: ->
    super()
    @button.orientation = @orientation
    if @orientation is "vertical"
      bw = @width() - 2
      bh = Math.max(bw, Math.round(@height() * @ratio()))
      @button.silentSetExtent new Point(bw, bh)
      posX = 1
      posY = Math.min(
        Math.round((@value - @start) * @unitSize()),
        @height() - @button.height())
    else
      bh = @height() - 2
      bw = Math.max(bh, Math.round(@width() * @ratio()))
      @button.silentSetExtent new Point(bw, bh)
      posY = 1
      posX = Math.min(
        Math.round((@value - @start) * @unitSize()),
        @width() - @button.width())
    @button.setPosition new Point(posX, posY).add(@bounds.origin)
    @button.updateRendering()
    @button.changed()
  
  updateValue: ->
    if @orientation is "vertical"
      relPos = @button.top() - @top()
    else
      relPos = @button.left() - @left()
    @value = Math.round(relPos / @unitSize() + @start)
    @updateTarget()
  
  updateTarget: ->
    if @action
      if typeof @action is "function"
        @action.call @target, @value
      else # assume it's a String
        @target[@action] @value
  
  
  # SliderMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.target = (dict[@target])  if c.target and dict[@target]
    c.button = (dict[@button])  if c.button and dict[@button]
    c
  
  
  # SliderMorph menu:
  developersMenu: ->
    menu = super()
    menu.addItem "show value...", "showValue", "display a dialog box\nshowing the selected number"
    menu.addItem "floor...", (->
      @prompt menu.title + "\nfloor:",
        @setStart,
        @,
        @start.toString(),
        null,
        0,
        @stop - @size,
        true
    ), "set the minimum value\nwhich can be selected"
    menu.addItem "ceiling...", (->
      @prompt menu.title + "\nceiling:",
        @setStop,
        @,
        @stop.toString(),
        null,
        @start + @size,
        @size * 100,
        true
    ), "set the maximum value\nwhich can be selected"
    menu.addItem "button size...", (->
      @prompt menu.title + "\nbutton size:",
        @setSize,
        @,
        @size.toString(),
        null,
        1,
        @stop - @start,
        true
    ), "set the range\ncovered by\nthe slider button"
    menu.addLine()
    menu.addItem "set target", "setTarget", "select another morph\nwhose numerical property\nwill be " + "controlled by this one"
    menu
  
  showValue: ->
    @inform @value
  
  userSetStart: (num) ->
    # for context menu demo purposes
    @start = Math.max(num, @stop)
  
  setStart: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @start = Math.min(Math.max(num, 0), @stop - @size)
    else
      newStart = parseFloat(num)
      @start = Math.min(Math.max(newStart, 0), @stop - @size)  unless isNaN(newStart)
    @value = Math.max(@value, @start)
    @updateTarget()
    @updateRendering()
    @changed()
  
  setStop: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @stop = Math.max(num, @start + @size)
    else
      newStop = parseFloat(num)
      @stop = Math.max(newStop, @start + @size)  unless isNaN(newStop)
    @value = Math.min(@value, @stop)
    @updateTarget()
    @updateRendering()
    @changed()
  
  setSize: (num) ->
    # for context menu demo purposes
    if typeof num is "number"
      @size = Math.min(Math.max(num, 1), @stop - @start)
    else
      newSize = parseFloat(num)
      @size = Math.min(Math.max(newSize, 1), @stop - @start)  unless isNaN(newSize)
    @value = Math.min(@value, @stop - @size)
    @updateTarget()
    @updateRendering()
    @changed()
  
  setTarget: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.push @world()
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), =>
        @target = each
        @setTargetSetter()
    #
    if choices.length is 1
      @target = choices[0]
      @setTargetSetter()
    else menu.popUpAtHand @world()  if choices.length
  
  setTargetSetter: ->
    choices = @target.numericalSetters()
    menu = new MenuMorph(@, "choose target property:")
    choices.forEach (each) =>
      menu.addItem each, =>
        @action = each
    #
    if choices.length is 1
      @action = choices[0]
    else menu.popUpAtHand @world()  if choices.length
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setStart", "setStop", "setSize"
    list
  
  
  # SliderMorph stepping:
  mouseDownLeft: (pos) ->
    unless @button.bounds.containsPoint(pos)
      @offset = new Point() # return null;
    else
      @offset = pos.subtract(@button.bounds.origin)
    world = @root()
    # this is to create the "drag the slider" effect
    # basically if the mouse is pressing within the boundaries
    # then in the next step you remember to check again where the mouse
    # is and update the scrollbar. As soon as the mouse is unpressed
    # then the step function is set to null to save cycles.
    @step = =>
      if world.hand.mouseButton
        mousePos = world.hand.bounds.origin
        if @orientation is "vertical"
          newX = @button.bounds.origin.x
          newY = Math.max(
            Math.min(mousePos.y - @offset.y,
            @bottom() - @button.height()), @top())
        else
          newY = @button.bounds.origin.y
          newX = Math.max(
            Math.min(mousePos.x - @offset.x,
            @right() - @button.width()), @left())
        @button.setPosition new Point(newX, newY)
        @updateValue()
      else
        @step = null
  '''
# CloseCircleButtonMorph //////////////////////////////////////////////////////

# This is basically a circle with an x inside, it's for
# the little icon on the top left of a window, to close
# the window.
# TODO: this little widget doesn't scale well into
# touch mode.

class CloseCircleButtonMorph extends CircleBoxMorph

  constructor: (@orientation = "vertical") ->
    super()
  
  updateRendering: ->
    super()

    # TODO: this context has already been created
    # and used in the superclass, there is no
    # reason why we have to re-create another
    # one here. Ideally we wanto to save the
    # first one into an instance variable, and
    # just reuse it here.
    context = @image.getContext("2d")

    # Now stroke the "x" inside the circle button
    # that closes the window.
    context.beginPath()
    context.moveTo 3,3
    context.lineTo 7,7
    context.moveTo 7,3
    context.lineTo 3,7
    context.strokeStyle = '#000'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
  
  @coffeeScriptSourceOfThisClass: '''
# CloseCircleButtonMorph //////////////////////////////////////////////////////

# This is basically a circle with an x inside, it's for
# the little icon on the top left of a window, to close
# the window.
# TODO: this little widget doesn't scale well into
# touch mode.

class CloseCircleButtonMorph extends CircleBoxMorph

  constructor: (@orientation = "vertical") ->
    super()
  
  updateRendering: ->
    super()

    # TODO: this context has already been created
    # and used in the superclass, there is no
    # reason why we have to re-create another
    # one here. Ideally we wanto to save the
    # first one into an instance variable, and
    # just reuse it here.
    context = @image.getContext("2d")

    # Now stroke the "x" inside the circle button
    # that closes the window.
    context.beginPath()
    context.moveTo 3,3
    context.lineTo 7,7
    context.moveTo 7,3
    context.lineTo 3,7
    context.strokeStyle = '#000'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
  
  '''
# ScrollFrameMorph ////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class ScrollFrameMorph extends FrameMorph

  autoScrollTrigger: null
  hasVelocity: true # dto.
  padding: 0 # around the scrollable area
  growth: 0 # pixels or Point to grow right/left when near edge
  isTextLineWrapping: false
  isScrollingByDragging: true
  scrollBarSize: null
  contents: null
  vBar: null
  hBar: null

  constructor: (contents, scrollBarSize, sliderColor) ->
    # super() paints the scrollframe, which we don't want,
    # so we set 0 opacity here.
    @alpha = 0
    super()
    @scrollBarSize = scrollBarSize or WorldMorph.MorphicPreferences.scrollBarSize
    @contents = contents or new FrameMorph(@)
    @add @contents

    # the scrollFrame is never going to paint itself,
    # but its values are going to mimick the values of the
    # contained frame
    @color = @contents.color
    @alpha = @contents.alpha
    # the scrollFrame is a container, it redirects most
    # commands to the "contained" frame
    @updateRendering = @contents.updateRendering
    #@setColor = @contents.setColor
    #@setAlphaScaled = @contents.setAlphaScaled

    @hBar = new SliderMorph(null, null, null, null, "horizontal", sliderColor)
    @hBar.setHeight @scrollBarSize
    @hBar.action = (num) =>
      @contents.setPosition new Point(@left() - num, @contents.position().y)
    @hBar.isDraggable = false
    @add @hBar

    @vBar = new SliderMorph(null, null, null, null, "vertical", sliderColor)
    @vBar.setWidth @scrollBarSize
    @vBar.action = (num) =>
      @contents.setPosition new Point(@contents.position().x, @top() - num)
    @vBar.isDraggable = false
    @add @vBar


  setColor: (aColor) ->
    # update the color of the scrollFrame - note
    # that we are never going to paint the scrollFrame
    # we are updating the color so that its value is the same as the
    # contained frame
    @color = aColor
    @contents.setColor(aColor)

  setAlphaScaled: (alpha) ->
    # update the alpha of the scrollFrame - note
    # that we are never going to paint the scrollFrame
    # we are updating the alpha so that its value is the same as the
    # contained frame
    @alpha = @calculateAlphaScaled(alpha)
    @contents.setAlphaScaled(alpha)

  adjustScrollBars: ->
    hWidth = @width() - @scrollBarSize
    vHeight = @height() - @scrollBarSize
    @changed()
    if @contents.width() > @width() + WorldMorph.MorphicPreferences.scrollBarSize
      @hBar.show()
      @hBar.setWidth hWidth  if @hBar.width() isnt hWidth
      @hBar.setPosition new Point(@left(), @bottom() - @hBar.height())
      @hBar.start = 0
      @hBar.stop = @contents.width() - @width()
      @hBar.size = @width() / @contents.width() * @hBar.stop
      @hBar.value = @left() - @contents.left()
      @hBar.updateRendering()
    else
      @hBar.hide()
    if @contents.height() > @height() + @scrollBarSize
      @vBar.show()
      @vBar.setHeight vHeight  if @vBar.height() isnt vHeight
      @vBar.setPosition new Point(@right() - @vBar.width(), @top())
      @vBar.start = 0
      @vBar.stop = @contents.height() - @height()
      @vBar.size = @height() / @contents.height() * @vBar.stop
      @vBar.value = @top() - @contents.top()
      @vBar.updateRendering()
    else
      @vBar.hide()
  
  addContents: (aMorph) ->
    @contents.add aMorph
    @contents.adjustBounds()
  
  setContents: (aMorph) ->
    @contents.children.forEach (m) ->
      m.destroy()
    #
    @contents.children = []
    aMorph.setPosition @position().add(@padding + 2)
    @addContents aMorph
  
  setExtent: (aPoint) ->
    @contents.setPosition @position().copy()  if @isTextLineWrapping
    super aPoint
    @contents.adjustBounds()
  
  
  # ScrollFrameMorph scrolling by dragging:
  scrollX: (steps) ->
    cl = @contents.left()
    l = @left()
    cw = @contents.width()
    r = @right()
    newX = cl + steps
    newX = r - cw  if newX + cw < r
    newX = l  if newX > l
    @contents.setLeft newX  if newX isnt cl
  
  scrollY: (steps) ->
    ct = @contents.top()
    t = @top()
    ch = @contents.height()
    b = @bottom()
    newY = ct + steps
    if newY + ch < b
      newY = b - ch
    # prevents content to be scrolled to the frame's
    # bottom if the content is otherwise empty
    newY = t  if newY > t
    @contents.setTop newY  if newY isnt ct
  
  mouseDownLeft: (pos) ->
    return null  unless @isScrollingByDragging
    world = @root()
    oldPos = pos
    deltaX = 0
    deltaY = 0
    friction = 0.8
    @step = =>
      if world.hand.mouseButton and
        (!world.hand.children.length) and
        (@bounds.containsPoint(world.hand.position()))
          newPos = world.hand.bounds.origin
          deltaX = newPos.x - oldPos.x
          @scrollX deltaX  if deltaX isnt 0
          deltaY = newPos.y - oldPos.y
          @scrollY deltaY  if deltaY isnt 0
          oldPos = newPos
      else
        unless @hasVelocity
          @step = noOperation
        else
          if (Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5)
            @step = noOperation
          else
            deltaX = deltaX * friction
            @scrollX Math.round(deltaX)
            deltaY = deltaY * friction
            @scrollY Math.round(deltaY)
      @adjustScrollBars()
  
  startAutoScrolling: ->
    inset = WorldMorph.MorphicPreferences.scrollBarSize * 3
    world = @world()
    return null  unless world
    hand = world.hand
    @autoScrollTrigger = Date.now()  unless @autoScrollTrigger
    @step = =>
      pos = hand.bounds.origin
      inner = @bounds.insetBy(inset)
      if (@bounds.containsPoint(pos)) and
        (not (inner.containsPoint(pos))) and
        (hand.children.length)
          @autoScroll pos
      else
        @step = noOperation
        @autoScrollTrigger = null
  
  autoScroll: (pos) ->
    return null  if Date.now() - @autoScrollTrigger < 500
    inset = WorldMorph.MorphicPreferences.scrollBarSize * 3
    area = @topLeft().extent(new Point(@width(), inset))
    @scrollY inset - (pos.y - @top())  if area.containsPoint(pos)
    area = @topLeft().extent(new Point(inset, @height()))
    @scrollX inset - (pos.x - @left())  if area.containsPoint(pos)
    area = (new Point(@right() - inset, @top())).extent(new Point(inset, @height()))
    @scrollX -(inset - (@right() - pos.x))  if area.containsPoint(pos)
    area = (new Point(@left(), @bottom() - inset)).extent(new Point(@width(), inset))
    @scrollY -(inset - (@bottom() - pos.y))  if area.containsPoint(pos)
    @adjustScrollBars()  
  
  # ScrollFrameMorph scrolling by editing text:
  scrollCaretIntoView: (morph) ->
    txt = morph.target
    offset = txt.position().subtract(@contents.position())
    ft = @top() + @padding
    fb = @bottom() - @padding
    @contents.setExtent txt.extent().add(offset).add(@padding)
    if morph.top() < ft
      @contents.setTop @contents.top() + ft - morph.top()
      morph.setTop ft
    else if morph.bottom() > fb
      @contents.setBottom @contents.bottom() + fb - morph.bottom()
      morph.setBottom fb
    @adjustScrollBars()

  # ScrollFrameMorph events:
  mouseScroll: (y, x) ->
    @scrollY y * WorldMorph.MorphicPreferences.mouseScrollAmount  if y
    @scrollX x * WorldMorph.MorphicPreferences.mouseScrollAmount  if x
    @adjustScrollBars()
  
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.contents = (dict[@contents])  if c.contents and dict[@contents]
    if c.hBar and dict[@hBar]
      c.hBar = (dict[@hBar])
      c.hBar.action = (num) ->
        c.contents.setPosition new Point(c.left() - num, c.contents.position().y)
    if c.vBar and dict[@vBar]
      c.vBar = (dict[@vBar])
      c.vBar.action = (num) ->
        c.contents.setPosition new Point(c.contents.position().x, c.top() - num)
    c
  
  developersMenu: ->
    menu = super()
    if @isTextLineWrapping
      menu.addItem "auto line wrap off...", "toggleTextLineWrapping", "turn automatic\nline wrapping\noff"
    else
      menu.addItem "auto line wrap on...", "toggleTextLineWrapping", "enable automatic\nline wrapping"
    menu
  
  toggleTextLineWrapping: ->
    @isTextLineWrapping = not @isTextLineWrapping

  @coffeeScriptSourceOfThisClass: '''
# ScrollFrameMorph ////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class ScrollFrameMorph extends FrameMorph

  autoScrollTrigger: null
  hasVelocity: true # dto.
  padding: 0 # around the scrollable area
  growth: 0 # pixels or Point to grow right/left when near edge
  isTextLineWrapping: false
  isScrollingByDragging: true
  scrollBarSize: null
  contents: null
  vBar: null
  hBar: null

  constructor: (contents, scrollBarSize, sliderColor) ->
    # super() paints the scrollframe, which we don't want,
    # so we set 0 opacity here.
    @alpha = 0
    super()
    @scrollBarSize = scrollBarSize or WorldMorph.MorphicPreferences.scrollBarSize
    @contents = contents or new FrameMorph(@)
    @add @contents

    # the scrollFrame is never going to paint itself,
    # but its values are going to mimick the values of the
    # contained frame
    @color = @contents.color
    @alpha = @contents.alpha
    # the scrollFrame is a container, it redirects most
    # commands to the "contained" frame
    @updateRendering = @contents.updateRendering
    #@setColor = @contents.setColor
    #@setAlphaScaled = @contents.setAlphaScaled

    @hBar = new SliderMorph(null, null, null, null, "horizontal", sliderColor)
    @hBar.setHeight @scrollBarSize
    @hBar.action = (num) =>
      @contents.setPosition new Point(@left() - num, @contents.position().y)
    @hBar.isDraggable = false
    @add @hBar

    @vBar = new SliderMorph(null, null, null, null, "vertical", sliderColor)
    @vBar.setWidth @scrollBarSize
    @vBar.action = (num) =>
      @contents.setPosition new Point(@contents.position().x, @top() - num)
    @vBar.isDraggable = false
    @add @vBar


  setColor: (aColor) ->
    # update the color of the scrollFrame - note
    # that we are never going to paint the scrollFrame
    # we are updating the color so that its value is the same as the
    # contained frame
    @color = aColor
    @contents.setColor(aColor)

  setAlphaScaled: (alpha) ->
    # update the alpha of the scrollFrame - note
    # that we are never going to paint the scrollFrame
    # we are updating the alpha so that its value is the same as the
    # contained frame
    @alpha = @calculateAlphaScaled(alpha)
    @contents.setAlphaScaled(alpha)

  adjustScrollBars: ->
    hWidth = @width() - @scrollBarSize
    vHeight = @height() - @scrollBarSize
    @changed()
    if @contents.width() > @width() + WorldMorph.MorphicPreferences.scrollBarSize
      @hBar.show()
      @hBar.setWidth hWidth  if @hBar.width() isnt hWidth
      @hBar.setPosition new Point(@left(), @bottom() - @hBar.height())
      @hBar.start = 0
      @hBar.stop = @contents.width() - @width()
      @hBar.size = @width() / @contents.width() * @hBar.stop
      @hBar.value = @left() - @contents.left()
      @hBar.updateRendering()
    else
      @hBar.hide()
    if @contents.height() > @height() + @scrollBarSize
      @vBar.show()
      @vBar.setHeight vHeight  if @vBar.height() isnt vHeight
      @vBar.setPosition new Point(@right() - @vBar.width(), @top())
      @vBar.start = 0
      @vBar.stop = @contents.height() - @height()
      @vBar.size = @height() / @contents.height() * @vBar.stop
      @vBar.value = @top() - @contents.top()
      @vBar.updateRendering()
    else
      @vBar.hide()
  
  addContents: (aMorph) ->
    @contents.add aMorph
    @contents.adjustBounds()
  
  setContents: (aMorph) ->
    @contents.children.forEach (m) ->
      m.destroy()
    #
    @contents.children = []
    aMorph.setPosition @position().add(@padding + 2)
    @addContents aMorph
  
  setExtent: (aPoint) ->
    @contents.setPosition @position().copy()  if @isTextLineWrapping
    super aPoint
    @contents.adjustBounds()
  
  
  # ScrollFrameMorph scrolling by dragging:
  scrollX: (steps) ->
    cl = @contents.left()
    l = @left()
    cw = @contents.width()
    r = @right()
    newX = cl + steps
    newX = r - cw  if newX + cw < r
    newX = l  if newX > l
    @contents.setLeft newX  if newX isnt cl
  
  scrollY: (steps) ->
    ct = @contents.top()
    t = @top()
    ch = @contents.height()
    b = @bottom()
    newY = ct + steps
    if newY + ch < b
      newY = b - ch
    # prevents content to be scrolled to the frame's
    # bottom if the content is otherwise empty
    newY = t  if newY > t
    @contents.setTop newY  if newY isnt ct
  
  mouseDownLeft: (pos) ->
    return null  unless @isScrollingByDragging
    world = @root()
    oldPos = pos
    deltaX = 0
    deltaY = 0
    friction = 0.8
    @step = =>
      if world.hand.mouseButton and
        (!world.hand.children.length) and
        (@bounds.containsPoint(world.hand.position()))
          newPos = world.hand.bounds.origin
          deltaX = newPos.x - oldPos.x
          @scrollX deltaX  if deltaX isnt 0
          deltaY = newPos.y - oldPos.y
          @scrollY deltaY  if deltaY isnt 0
          oldPos = newPos
      else
        unless @hasVelocity
          @step = noOperation
        else
          if (Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5)
            @step = noOperation
          else
            deltaX = deltaX * friction
            @scrollX Math.round(deltaX)
            deltaY = deltaY * friction
            @scrollY Math.round(deltaY)
      @adjustScrollBars()
  
  startAutoScrolling: ->
    inset = WorldMorph.MorphicPreferences.scrollBarSize * 3
    world = @world()
    return null  unless world
    hand = world.hand
    @autoScrollTrigger = Date.now()  unless @autoScrollTrigger
    @step = =>
      pos = hand.bounds.origin
      inner = @bounds.insetBy(inset)
      if (@bounds.containsPoint(pos)) and
        (not (inner.containsPoint(pos))) and
        (hand.children.length)
          @autoScroll pos
      else
        @step = noOperation
        @autoScrollTrigger = null
  
  autoScroll: (pos) ->
    return null  if Date.now() - @autoScrollTrigger < 500
    inset = WorldMorph.MorphicPreferences.scrollBarSize * 3
    area = @topLeft().extent(new Point(@width(), inset))
    @scrollY inset - (pos.y - @top())  if area.containsPoint(pos)
    area = @topLeft().extent(new Point(inset, @height()))
    @scrollX inset - (pos.x - @left())  if area.containsPoint(pos)
    area = (new Point(@right() - inset, @top())).extent(new Point(inset, @height()))
    @scrollX -(inset - (@right() - pos.x))  if area.containsPoint(pos)
    area = (new Point(@left(), @bottom() - inset)).extent(new Point(@width(), inset))
    @scrollY -(inset - (@bottom() - pos.y))  if area.containsPoint(pos)
    @adjustScrollBars()  
  
  # ScrollFrameMorph scrolling by editing text:
  scrollCaretIntoView: (morph) ->
    txt = morph.target
    offset = txt.position().subtract(@contents.position())
    ft = @top() + @padding
    fb = @bottom() - @padding
    @contents.setExtent txt.extent().add(offset).add(@padding)
    if morph.top() < ft
      @contents.setTop @contents.top() + ft - morph.top()
      morph.setTop ft
    else if morph.bottom() > fb
      @contents.setBottom @contents.bottom() + fb - morph.bottom()
      morph.setBottom fb
    @adjustScrollBars()

  # ScrollFrameMorph events:
  mouseScroll: (y, x) ->
    @scrollY y * WorldMorph.MorphicPreferences.mouseScrollAmount  if y
    @scrollX x * WorldMorph.MorphicPreferences.mouseScrollAmount  if x
    @adjustScrollBars()
  
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.contents = (dict[@contents])  if c.contents and dict[@contents]
    if c.hBar and dict[@hBar]
      c.hBar = (dict[@hBar])
      c.hBar.action = (num) ->
        c.contents.setPosition new Point(c.left() - num, c.contents.position().y)
    if c.vBar and dict[@vBar]
      c.vBar = (dict[@vBar])
      c.vBar.action = (num) ->
        c.contents.setPosition new Point(c.contents.position().x, c.top() - num)
    c
  
  developersMenu: ->
    menu = super()
    if @isTextLineWrapping
      menu.addItem "auto line wrap off...", "toggleTextLineWrapping", "turn automatic\nline wrapping\noff"
    else
      menu.addItem "auto line wrap on...", "toggleTextLineWrapping", "enable automatic\nline wrapping"
    menu
  
  toggleTextLineWrapping: ->
    @isTextLineWrapping = not @isTextLineWrapping
  '''
# StringFieldMorph ////////////////////////////////////////////////////

class StringFieldMorph extends FrameMorph

  defaultContents: null
  minWidth: null
  fontSize: null
  fontStyle: null
  isBold: null
  isItalic: null
  isNumeric: null
  text: null
  isEditable: true

  constructor: (
      @defaultContents = "",
      @minWidth = 100,
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false
      ) ->
    super()
    @color = new Color(255, 255, 255)
    @updateRendering()
  
  updateRendering: ->
    txt = (if @text then @string() else @defaultContents)
    @text = null
    @children.forEach (child) ->
      child.destroy()
    #
    @children = []
    @text = new StringMorph(txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric)
    @text.isNumeric = @isNumeric # for whichever reason...
    @text.setPosition @bounds.origin.copy()
    @text.isEditable = @isEditable
    @text.isDraggable = false
    @text.enableSelecting()
    @silentSetExtent new Point(Math.max(@width(), @minWidth), @text.height())
    super()
    @add @text
  
  string: ->
    @text.text
  
  mouseClickLeft: (pos)->
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos
  
  
  # StringFieldMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.text = (dict[@text])  if c.text and dict[@text]
    c

  @coffeeScriptSourceOfThisClass: '''
# StringFieldMorph ////////////////////////////////////////////////////

class StringFieldMorph extends FrameMorph

  defaultContents: null
  minWidth: null
  fontSize: null
  fontStyle: null
  isBold: null
  isItalic: null
  isNumeric: null
  text: null
  isEditable: true

  constructor: (
      @defaultContents = "",
      @minWidth = 100,
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false
      ) ->
    super()
    @color = new Color(255, 255, 255)
    @updateRendering()
  
  updateRendering: ->
    txt = (if @text then @string() else @defaultContents)
    @text = null
    @children.forEach (child) ->
      child.destroy()
    #
    @children = []
    @text = new StringMorph(txt, @fontSize, @fontStyle, @isBold, @isItalic, @isNumeric)
    @text.isNumeric = @isNumeric # for whichever reason...
    @text.setPosition @bounds.origin.copy()
    @text.isEditable = @isEditable
    @text.isDraggable = false
    @text.enableSelecting()
    @silentSetExtent new Point(Math.max(@width(), @minWidth), @text.height())
    super()
    @add @text
  
  string: ->
    @text.text
  
  mouseClickLeft: (pos)->
    if @isEditable
      @text.edit()
    else
      @escalateEvent 'mouseClickLeft', pos
  
  
  # StringFieldMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.text = (dict[@text])  if c.text and dict[@text]
    c
  '''
# Points //////////////////////////////////////////////////////////////

class Point

  x: null
  y: null
   
  constructor: (@x = 0, @y = 0) ->
  
  # Point string representation: e.g. '12@68'
  toString: ->
    Math.round(@x.toString()) + "@" + Math.round(@y.toString())
  
  # Point copying:
  copy: ->
    new Point(@x, @y)
  
  # Point comparison:
  eq: (aPoint) ->
    # ==
    @x is aPoint.x and @y is aPoint.y
  
  lt: (aPoint) ->
    # <
    @x < aPoint.x and @y < aPoint.y
  
  gt: (aPoint) ->
    # >
    @x > aPoint.x and @y > aPoint.y
  
  ge: (aPoint) ->
    # >=
    @x >= aPoint.x and @y >= aPoint.y
  
  le: (aPoint) ->
    # <=
    @x <= aPoint.x and @y <= aPoint.y
  
  max: (aPoint) ->
    new Point(Math.max(@x, aPoint.x), Math.max(@y, aPoint.y))
  
  min: (aPoint) ->
    new Point(Math.min(@x, aPoint.x), Math.min(@y, aPoint.y))
  
  
  # Point conversion:
  round: ->
    new Point(Math.round(@x), Math.round(@y))
  
  abs: ->
    new Point(Math.abs(@x), Math.abs(@y))
  
  neg: ->
    new Point(-@x, -@y)
  
  mirror: ->
    new Point(@y, @x)
  
  floor: ->
    new Point(Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0))
  
  ceil: ->
    new Point(Math.ceil(@x), Math.ceil(@y))
  
  
  # Point arithmetic:
  add: (other) ->
    return new Point(@x + other.x, @y + other.y)  if other instanceof Point
    new Point(@x + other, @y + other)
  
  subtract: (other) ->
    return new Point(@x - other.x, @y - other.y)  if other instanceof Point
    new Point(@x - other, @y - other)
  
  multiplyBy: (other) ->
    return new Point(@x * other.x, @y * other.y)  if other instanceof Point
    new Point(@x * other, @y * other)
  
  divideBy: (other) ->
    return new Point(@x / other.x, @y / other.y)  if other instanceof Point
    new Point(@x / other, @y / other)
  
  floorDivideBy: (other) ->
    if other instanceof Point
      return new Point(Math.floor(@x / other.x), Math.floor(@y / other.y))
    new Point(Math.floor(@x / other), Math.floor(@y / other))
  
  
  # Point polar coordinates:
  r: ->
    t = (@multiplyBy(@))
    Math.sqrt t.x + t.y
  
  degrees: ->
    #
    #    answer the angle I make with origin in degrees.
    #    Right is 0, down is 90
    #
    if @x is 0
      return 90  if @y >= 0
      return 270
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return degrees(theta)  if @y >= 0
      return 360 + (degrees(theta))
    180 + degrees(theta)
  
  theta: ->
    #
    #    answer the angle I make with origin in radians.
    #    Right is 0, down is 90
    #
    if @x is 0
      return radians(90)  if @y >= 0
      return radians(270)
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return theta  if @y >= 0
      return radians(360) + theta
    radians(180) + theta
  
  
  # Point functions:
  crossProduct: (aPoint) ->
    @multiplyBy aPoint.mirror()
  
  distanceTo: (aPoint) ->
    (aPoint.subtract(@)).r()
  
  rotate: (direction, center) ->
    # direction must be 'right', 'left' or 'pi'
    offset = @subtract(center)
    return new Point(-offset.y, offset.y).add(center)  if direction is "right"
    return new Point(offset.y, -offset.y).add(center)  if direction is "left"
    #
    # direction === 'pi'
    center.subtract offset
  
  flip: (direction, center) ->
    # direction must be 'vertical' or 'horizontal'
    return new Point(@x, center.y * 2 - @y)  if direction is "vertical"
    #
    # direction === 'horizontal'
    new Point(center.x * 2 - @x, @y)
  
  distanceAngle: (dist, angle) ->
    deg = angle
    if deg > 270
      deg = deg - 360
    else deg = deg + 360  if deg < -270
    if -90 <= deg and deg <= 90
      x = Math.sin(radians(deg)) * dist
      y = Math.sqrt((dist * dist) - (x * x))
      return new Point(x + @x, @y - y)
    x = Math.sin(radians(180 - deg)) * dist
    y = Math.sqrt((dist * dist) - (x * x))
    new Point(x + @x, @y + y)
  
  
  # Point transforming:
  scaleBy: (scalePoint) ->
    @multiplyBy scalePoint
  
  translateBy: (deltaPoint) ->
    @add deltaPoint
  
  rotateBy: (angle, centerPoint) ->
    center = centerPoint or new Point(0, 0)
    p = @subtract(center)
    r = p.r()
    theta = angle - p.theta()
    new Point(center.x + (r * Math.cos(theta)), center.y - (r * Math.sin(theta)))
  
  
  # Point conversion:
  asArray: ->
    [@x, @y]
  
  # creating Rectangle instances from Points:
  corner: (cornerPoint) ->
    # answer a new Rectangle
    new Rectangle(@x, @y, cornerPoint.x, cornerPoint.y)
  
  rectangle: (aPoint) ->
    # answer a new Rectangle
    org = @min(aPoint)
    crn = @max(aPoint)
    new Rectangle(org.x, org.y, crn.x, crn.y)
  
  extent: (aPoint) ->
    #answer a new Rectangle
    crn = @add(aPoint)
    new Rectangle(@x, @y, crn.x, crn.y)

  @coffeeScriptSourceOfThisClass: '''
# Points //////////////////////////////////////////////////////////////

class Point

  x: null
  y: null
   
  constructor: (@x = 0, @y = 0) ->
  
  # Point string representation: e.g. '12@68'
  toString: ->
    Math.round(@x.toString()) + "@" + Math.round(@y.toString())
  
  # Point copying:
  copy: ->
    new Point(@x, @y)
  
  # Point comparison:
  eq: (aPoint) ->
    # ==
    @x is aPoint.x and @y is aPoint.y
  
  lt: (aPoint) ->
    # <
    @x < aPoint.x and @y < aPoint.y
  
  gt: (aPoint) ->
    # >
    @x > aPoint.x and @y > aPoint.y
  
  ge: (aPoint) ->
    # >=
    @x >= aPoint.x and @y >= aPoint.y
  
  le: (aPoint) ->
    # <=
    @x <= aPoint.x and @y <= aPoint.y
  
  max: (aPoint) ->
    new Point(Math.max(@x, aPoint.x), Math.max(@y, aPoint.y))
  
  min: (aPoint) ->
    new Point(Math.min(@x, aPoint.x), Math.min(@y, aPoint.y))
  
  
  # Point conversion:
  round: ->
    new Point(Math.round(@x), Math.round(@y))
  
  abs: ->
    new Point(Math.abs(@x), Math.abs(@y))
  
  neg: ->
    new Point(-@x, -@y)
  
  mirror: ->
    new Point(@y, @x)
  
  floor: ->
    new Point(Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0))
  
  ceil: ->
    new Point(Math.ceil(@x), Math.ceil(@y))
  
  
  # Point arithmetic:
  add: (other) ->
    return new Point(@x + other.x, @y + other.y)  if other instanceof Point
    new Point(@x + other, @y + other)
  
  subtract: (other) ->
    return new Point(@x - other.x, @y - other.y)  if other instanceof Point
    new Point(@x - other, @y - other)
  
  multiplyBy: (other) ->
    return new Point(@x * other.x, @y * other.y)  if other instanceof Point
    new Point(@x * other, @y * other)
  
  divideBy: (other) ->
    return new Point(@x / other.x, @y / other.y)  if other instanceof Point
    new Point(@x / other, @y / other)
  
  floorDivideBy: (other) ->
    if other instanceof Point
      return new Point(Math.floor(@x / other.x), Math.floor(@y / other.y))
    new Point(Math.floor(@x / other), Math.floor(@y / other))
  
  
  # Point polar coordinates:
  r: ->
    t = (@multiplyBy(@))
    Math.sqrt t.x + t.y
  
  degrees: ->
    #
    #    answer the angle I make with origin in degrees.
    #    Right is 0, down is 90
    #
    if @x is 0
      return 90  if @y >= 0
      return 270
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return degrees(theta)  if @y >= 0
      return 360 + (degrees(theta))
    180 + degrees(theta)
  
  theta: ->
    #
    #    answer the angle I make with origin in radians.
    #    Right is 0, down is 90
    #
    if @x is 0
      return radians(90)  if @y >= 0
      return radians(270)
    tan = @y / @x
    theta = Math.atan(tan)
    if @x >= 0
      return theta  if @y >= 0
      return radians(360) + theta
    radians(180) + theta
  
  
  # Point functions:
  crossProduct: (aPoint) ->
    @multiplyBy aPoint.mirror()
  
  distanceTo: (aPoint) ->
    (aPoint.subtract(@)).r()
  
  rotate: (direction, center) ->
    # direction must be 'right', 'left' or 'pi'
    offset = @subtract(center)
    return new Point(-offset.y, offset.y).add(center)  if direction is "right"
    return new Point(offset.y, -offset.y).add(center)  if direction is "left"
    #
    # direction === 'pi'
    center.subtract offset
  
  flip: (direction, center) ->
    # direction must be 'vertical' or 'horizontal'
    return new Point(@x, center.y * 2 - @y)  if direction is "vertical"
    #
    # direction === 'horizontal'
    new Point(center.x * 2 - @x, @y)
  
  distanceAngle: (dist, angle) ->
    deg = angle
    if deg > 270
      deg = deg - 360
    else deg = deg + 360  if deg < -270
    if -90 <= deg and deg <= 90
      x = Math.sin(radians(deg)) * dist
      y = Math.sqrt((dist * dist) - (x * x))
      return new Point(x + @x, @y - y)
    x = Math.sin(radians(180 - deg)) * dist
    y = Math.sqrt((dist * dist) - (x * x))
    new Point(x + @x, @y + y)
  
  
  # Point transforming:
  scaleBy: (scalePoint) ->
    @multiplyBy scalePoint
  
  translateBy: (deltaPoint) ->
    @add deltaPoint
  
  rotateBy: (angle, centerPoint) ->
    center = centerPoint or new Point(0, 0)
    p = @subtract(center)
    r = p.r()
    theta = angle - p.theta()
    new Point(center.x + (r * Math.cos(theta)), center.y - (r * Math.sin(theta)))
  
  
  # Point conversion:
  asArray: ->
    [@x, @y]
  
  # creating Rectangle instances from Points:
  corner: (cornerPoint) ->
    # answer a new Rectangle
    new Rectangle(@x, @y, cornerPoint.x, cornerPoint.y)
  
  rectangle: (aPoint) ->
    # answer a new Rectangle
    org = @min(aPoint)
    crn = @max(aPoint)
    new Rectangle(org.x, org.y, crn.x, crn.y)
  
  extent: (aPoint) ->
    #answer a new Rectangle
    crn = @add(aPoint)
    new Rectangle(@x, @y, crn.x, crn.y)
  '''
# StringMorph /////////////////////////////////////////////////////////

# A StringMorph is a single line of text. It can only be left-aligned.

class StringMorph extends Morph

  text: null
  fontSize: null
  fontName: null
  fontStyle: null
  isBold: null
  isItalic: null
  isEditable: false
  isNumeric: null
  isPassword: false
  shadowOffset: null
  shadowColor: null
  isShowingBlanks: false
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  blanksColor: new Color(180, 140, 140)
  #
  # Properties for text-editing
  isScrollable: true
  currentlySelecting: false
  startMark: null
  endMark: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  markedTextColor: new Color(255, 255, 255)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  markedBackgoundColor: new Color(60, 60, 120)

  constructor: (
      text,
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false,
      shadowOffset,
      @shadowColor,
      color,
      fontName
      ) ->
    # additional properties:
    @text = text or ((if (text is "") then "" else "StringMorph"))
    @fontName = fontName or WorldMorph.MorphicPreferences.globalFontFamily
    @shadowOffset = shadowOffset or new Point(0, 0)
    #
    super()
    #
    # override inherited properites:
    @color = color or new Color(0, 0, 0)
    @noticesTransparentClick = true
    @updateRendering()
  
  toString: ->
    # e.g. 'a StringMorph("Hello World")'
    "a " + (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0]) + "(\"" + @text.slice(0, 30) + "...\")"
  
  password: (letter, length) ->
    ans = ""
    for i in [0...length]
      ans += letter
    ans

  font: ->
    # answer a font string, e.g. 'bold italic 12px sans-serif'
    font = ""
    font = font + "bold "  if @isBold
    font = font + "italic "  if @isItalic
    font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle
  
  updateRendering: ->
    text = (if @isPassword then @password("*", @text.length) else @text)
    # initialize my surface property
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # set my extent based on the size of the text
    width = Math.max(context.measureText(text).width + Math.abs(@shadowOffset.x), 1)
    @bounds.corner = @bounds.origin.add(new Point(
      width, fontHeight(@fontSize) + Math.abs(@shadowOffset.y)))
    @image.width = width
    @image.height = @height()

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # first draw the shadow, if any
    if @shadowColor
      x = Math.max(@shadowOffset.x, 0)
      y = Math.max(@shadowOffset.y, 0)
      context.fillStyle = @shadowColor.toString()
      context.fillText text, x, fontHeight(@fontSize) + y
    #
    # now draw the actual text
    x = Math.abs(Math.min(@shadowOffset.x, 0))
    y = Math.abs(Math.min(@shadowOffset.y, 0))
    context.fillStyle = @color.toString()
    if @isShowingBlanks
      @renderWithBlanks context, x, fontHeight(@fontSize) + y
    else
      context.fillText text, x, fontHeight(@fontSize) + y
    #
    # draw the selection
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = text.charAt(i)
      context.fillStyle = @markedBackgoundColor.toString()
      context.fillRect p.x, p.y, context.measureText(c).width + 1 + x,
        fontHeight(@fontSize) + y
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x + x, fontHeight(@fontSize) + y
    #
    # notify my parent of layout change
    @parent.fixLayout()  if @parent.fixLayout  if @parent
  
  renderWithBlanks: (context, startX, y) ->
    # create the blank form
    drawBlank = ->
      context.drawImage blank, Math.round(x), 0
      x += space
    space = context.measureText(" ").width
    blank = newCanvas(new Point(space, @height()))
    ctx = blank.getContext("2d")
    words = @text.split(" ")
    x = startX or 0
    isFirst = true
    ctx.fillStyle = @blanksColor.toString()
    ctx.arc space / 2, blank.height / 2, space / 2, radians(0), radians(360)
    ctx.fill()
    #
    # render my text inserting blanks
    words.forEach (word) ->
      drawBlank()  unless isFirst
      isFirst = false
      if word isnt ""
        context.fillText word, x, y
        x += context.measureText(word).width
  
  
  # StringMorph mesuring:
  slotCoordinates: (slot) ->
    # answer the position point of the given index ("slot")
    # where the caret should be placed
    text = (if @isPassword then @password("*", @text.length) else @text)
    dest = Math.min(Math.max(slot, 0), text.length)
    context = @image.getContext("2d")
    xOffset = context.measureText(text.substring(0,dest)).width
    @pos = dest
    x = @left() + xOffset
    y = @top()
    new Point(x, y)
  
  slotAt: (aPoint) ->
    # answer the slot (index) closest to the given point
    # so the caret can be moved accordingly
    text = (if @isPassword then @password("*", @text.length) else @text)
    idx = 0
    charX = 0
    context = @image.getContext("2d")
    while aPoint.x - @left() > charX
      charX += context.measureText(text[idx]).width
      idx += 1
      if idx is text.length
        if (context.measureText(text).width - (context.measureText(text[idx - 1]).width / 2)) < (aPoint.x - @left())  
          return idx
    idx - 1
  
  upFrom: (slot) ->
    # answer the slot above the given one
    slot
  
  downFrom: (slot) ->
    # answer the slot below the given one
    slot
  
  startOfLine: ->
    # answer the first slot (index) of the line for the given slot
    0
  
  endOfLine: ->
    # answer the slot (index) indicating the EOL for the given slot
    @text.length

  rawHeight: ->
    # answer my corrected fontSize
    @height() / 1.2
    
  # StringMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "edit", "edit"
    menu.addItem "font size...", (->
      @prompt menu.title + "\nfont\nsize:",
        @setFontSize, @, @fontSize.toString(), null, 6, 500, true
    ), "set this String's\nfont point size"
    menu.addItem "serif", "setSerif"  if @fontStyle isnt "serif"
    menu.addItem "sans-serif", "setSansSerif"  if @fontStyle isnt "sans-serif"

    if @isBold
      menu.addItem "normal weight", "toggleWeight"
    else
      menu.addItem "bold", "toggleWeight"

    if @isItalic
      menu.addItem "normal style", "toggleItalic"
    else
      menu.addItem "italic", "toggleItalic"

    if @isShowingBlanks
      menu.addItem "hide blanks", "toggleShowBlanks"
    else
      menu.addItem "show blanks", "toggleShowBlanks"

    if @isPassword
      menu.addItem "show characters", "toggleIsPassword"
    else
      menu.addItem "hide characters", "toggleIsPassword"

    menu
  
  toggleIsDraggable: ->
    # for context menu demo purposes
    @isDraggable = not @isDraggable
    if @isDraggable
      @disableSelecting()
    else
      @enableSelecting()
  
  toggleShowBlanks: ->
    @isShowingBlanks = not @isShowingBlanks
    @changed()
    @updateRendering()
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @changed()
    @updateRendering()
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @changed()
    @updateRendering()
    @changed()
  
  toggleIsPassword: ->
    @isPassword = not @isPassword
    @changed()
    @updateRendering()
    @changed()
  
  setSerif: ->
    @fontStyle = "serif"
    @changed()
    @updateRendering()
    @changed()
  
  setSansSerif: ->
    @fontStyle = "sans-serif"
    @changed()
    @updateRendering()
    @changed()
  
  setFontSize: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
    else
      newSize = parseFloat(size)
      @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
    @changed()
    @updateRendering()
    @changed()
  
  setText: (size) ->
    # for context menu demo purposes
    @text = Math.round(size).toString()
    @changed()
    @updateRendering()
    @changed()
  
  numericalSetters: ->
    # for context menu demo purposes
    ["setLeft", "setTop", "setAlphaScaled", "setFontSize", "setText"]
  
  
  # StringMorph editing:
  edit: ->
    @root().edit @
  
  selection: ->
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    @text.slice start, stop
  
  selectionStartSlot: ->
    Math.min @startMark, @endMark
  
  clearSelection: ->
    @currentlySelecting = false
    @startMark = null
    @endMark = null
    @changed()
    @updateRendering()
    @changed()
  
  deleteSelection: ->
    text = @text
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    @text = text.slice(0, start) + text.slice(stop)
    @changed()
    @clearSelection()
  
  selectAll: ->
    @startMark = 0
    @endMark = @text.length
    @updateRendering()
    @changed()

  mouseDownLeft: (pos) ->
    if @isEditable
      @clearSelection()
    else
      @escalateEvent "mouseDownLeft", pos

  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  mouseClickLeft: (pos) ->
    caret = @root().caret;
    if @isEditable
      @edit()  unless @currentlySelecting
      if caret then caret.gotoPos pos
      @root().caret.gotoPos pos
      @currentlySelecting = true
    else
      @escalateEvent "mouseClickLeft", pos
  
  #mouseDoubleClick: ->
  #  alert "mouseDoubleClick!"

  enableSelecting: ->
    @mouseDownLeft = (pos) ->
      @clearSelection()
      if @isEditable and (not @isDraggable)
        @edit()
        @root().caret.gotoPos pos
        @startMark = @slotAt(pos)
        @endMark = @startMark
        @currentlySelecting = true
    
    @mouseMove = (pos) ->
      if @isEditable and @currentlySelecting and (not @isDraggable)
        newMark = @slotAt(pos)
        if newMark isnt @endMark
          @endMark = newMark
          @updateRendering()
          @changed()
  
  disableSelecting: ->
    # re-establish the original definition of the method
    @mouseDownLeft = StringMorph::mouseDownLeft
    delete @mouseMove

  @coffeeScriptSourceOfThisClass: '''
# StringMorph /////////////////////////////////////////////////////////

# A StringMorph is a single line of text. It can only be left-aligned.

class StringMorph extends Morph

  text: null
  fontSize: null
  fontName: null
  fontStyle: null
  isBold: null
  isItalic: null
  isEditable: false
  isNumeric: null
  isPassword: false
  shadowOffset: null
  shadowColor: null
  isShowingBlanks: false
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  blanksColor: new Color(180, 140, 140)
  #
  # Properties for text-editing
  isScrollable: true
  currentlySelecting: false
  startMark: null
  endMark: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  markedTextColor: new Color(255, 255, 255)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  markedBackgoundColor: new Color(60, 60, 120)

  constructor: (
      text,
      @fontSize = 12,
      @fontStyle = "sans-serif",
      @isBold = false,
      @isItalic = false,
      @isNumeric = false,
      shadowOffset,
      @shadowColor,
      color,
      fontName
      ) ->
    # additional properties:
    @text = text or ((if (text is "") then "" else "StringMorph"))
    @fontName = fontName or WorldMorph.MorphicPreferences.globalFontFamily
    @shadowOffset = shadowOffset or new Point(0, 0)
    #
    super()
    #
    # override inherited properites:
    @color = color or new Color(0, 0, 0)
    @noticesTransparentClick = true
    @updateRendering()
  
  toString: ->
    # e.g. 'a StringMorph("Hello World")'
    "a " + (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0]) + "(\"" + @text.slice(0, 30) + "...\")"
  
  password: (letter, length) ->
    ans = ""
    for i in [0...length]
      ans += letter
    ans

  font: ->
    # answer a font string, e.g. 'bold italic 12px sans-serif'
    font = ""
    font = font + "bold "  if @isBold
    font = font + "italic "  if @isItalic
    font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle
  
  updateRendering: ->
    text = (if @isPassword then @password("*", @text.length) else @text)
    # initialize my surface property
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # set my extent based on the size of the text
    width = Math.max(context.measureText(text).width + Math.abs(@shadowOffset.x), 1)
    @bounds.corner = @bounds.origin.add(new Point(
      width, fontHeight(@fontSize) + Math.abs(@shadowOffset.y)))
    @image.width = width
    @image.height = @height()

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # first draw the shadow, if any
    if @shadowColor
      x = Math.max(@shadowOffset.x, 0)
      y = Math.max(@shadowOffset.y, 0)
      context.fillStyle = @shadowColor.toString()
      context.fillText text, x, fontHeight(@fontSize) + y
    #
    # now draw the actual text
    x = Math.abs(Math.min(@shadowOffset.x, 0))
    y = Math.abs(Math.min(@shadowOffset.y, 0))
    context.fillStyle = @color.toString()
    if @isShowingBlanks
      @renderWithBlanks context, x, fontHeight(@fontSize) + y
    else
      context.fillText text, x, fontHeight(@fontSize) + y
    #
    # draw the selection
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = text.charAt(i)
      context.fillStyle = @markedBackgoundColor.toString()
      context.fillRect p.x, p.y, context.measureText(c).width + 1 + x,
        fontHeight(@fontSize) + y
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x + x, fontHeight(@fontSize) + y
    #
    # notify my parent of layout change
    @parent.fixLayout()  if @parent.fixLayout  if @parent
  
  renderWithBlanks: (context, startX, y) ->
    # create the blank form
    drawBlank = ->
      context.drawImage blank, Math.round(x), 0
      x += space
    space = context.measureText(" ").width
    blank = newCanvas(new Point(space, @height()))
    ctx = blank.getContext("2d")
    words = @text.split(" ")
    x = startX or 0
    isFirst = true
    ctx.fillStyle = @blanksColor.toString()
    ctx.arc space / 2, blank.height / 2, space / 2, radians(0), radians(360)
    ctx.fill()
    #
    # render my text inserting blanks
    words.forEach (word) ->
      drawBlank()  unless isFirst
      isFirst = false
      if word isnt ""
        context.fillText word, x, y
        x += context.measureText(word).width
  
  
  # StringMorph mesuring:
  slotCoordinates: (slot) ->
    # answer the position point of the given index ("slot")
    # where the caret should be placed
    text = (if @isPassword then @password("*", @text.length) else @text)
    dest = Math.min(Math.max(slot, 0), text.length)
    context = @image.getContext("2d")
    xOffset = context.measureText(text.substring(0,dest)).width
    @pos = dest
    x = @left() + xOffset
    y = @top()
    new Point(x, y)
  
  slotAt: (aPoint) ->
    # answer the slot (index) closest to the given point
    # so the caret can be moved accordingly
    text = (if @isPassword then @password("*", @text.length) else @text)
    idx = 0
    charX = 0
    context = @image.getContext("2d")
    while aPoint.x - @left() > charX
      charX += context.measureText(text[idx]).width
      idx += 1
      if idx is text.length
        if (context.measureText(text).width - (context.measureText(text[idx - 1]).width / 2)) < (aPoint.x - @left())  
          return idx
    idx - 1
  
  upFrom: (slot) ->
    # answer the slot above the given one
    slot
  
  downFrom: (slot) ->
    # answer the slot below the given one
    slot
  
  startOfLine: ->
    # answer the first slot (index) of the line for the given slot
    0
  
  endOfLine: ->
    # answer the slot (index) indicating the EOL for the given slot
    @text.length

  rawHeight: ->
    # answer my corrected fontSize
    @height() / 1.2
    
  # StringMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "edit", "edit"
    menu.addItem "font size...", (->
      @prompt menu.title + "\nfont\nsize:",
        @setFontSize, @, @fontSize.toString(), null, 6, 500, true
    ), "set this String's\nfont point size"
    menu.addItem "serif", "setSerif"  if @fontStyle isnt "serif"
    menu.addItem "sans-serif", "setSansSerif"  if @fontStyle isnt "sans-serif"

    if @isBold
      menu.addItem "normal weight", "toggleWeight"
    else
      menu.addItem "bold", "toggleWeight"

    if @isItalic
      menu.addItem "normal style", "toggleItalic"
    else
      menu.addItem "italic", "toggleItalic"

    if @isShowingBlanks
      menu.addItem "hide blanks", "toggleShowBlanks"
    else
      menu.addItem "show blanks", "toggleShowBlanks"

    if @isPassword
      menu.addItem "show characters", "toggleIsPassword"
    else
      menu.addItem "hide characters", "toggleIsPassword"

    menu
  
  toggleIsDraggable: ->
    # for context menu demo purposes
    @isDraggable = not @isDraggable
    if @isDraggable
      @disableSelecting()
    else
      @enableSelecting()
  
  toggleShowBlanks: ->
    @isShowingBlanks = not @isShowingBlanks
    @changed()
    @updateRendering()
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @changed()
    @updateRendering()
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @changed()
    @updateRendering()
    @changed()
  
  toggleIsPassword: ->
    @isPassword = not @isPassword
    @changed()
    @updateRendering()
    @changed()
  
  setSerif: ->
    @fontStyle = "serif"
    @changed()
    @updateRendering()
    @changed()
  
  setSansSerif: ->
    @fontStyle = "sans-serif"
    @changed()
    @updateRendering()
    @changed()
  
  setFontSize: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
    else
      newSize = parseFloat(size)
      @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
    @changed()
    @updateRendering()
    @changed()
  
  setText: (size) ->
    # for context menu demo purposes
    @text = Math.round(size).toString()
    @changed()
    @updateRendering()
    @changed()
  
  numericalSetters: ->
    # for context menu demo purposes
    ["setLeft", "setTop", "setAlphaScaled", "setFontSize", "setText"]
  
  
  # StringMorph editing:
  edit: ->
    @root().edit @
  
  selection: ->
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    @text.slice start, stop
  
  selectionStartSlot: ->
    Math.min @startMark, @endMark
  
  clearSelection: ->
    @currentlySelecting = false
    @startMark = null
    @endMark = null
    @changed()
    @updateRendering()
    @changed()
  
  deleteSelection: ->
    text = @text
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    @text = text.slice(0, start) + text.slice(stop)
    @changed()
    @clearSelection()
  
  selectAll: ->
    @startMark = 0
    @endMark = @text.length
    @updateRendering()
    @changed()

  mouseDownLeft: (pos) ->
    if @isEditable
      @clearSelection()
    else
      @escalateEvent "mouseDownLeft", pos

  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  mouseClickLeft: (pos) ->
    caret = @root().caret;
    if @isEditable
      @edit()  unless @currentlySelecting
      if caret then caret.gotoPos pos
      @root().caret.gotoPos pos
      @currentlySelecting = true
    else
      @escalateEvent "mouseClickLeft", pos
  
  #mouseDoubleClick: ->
  #  alert "mouseDoubleClick!"

  enableSelecting: ->
    @mouseDownLeft = (pos) ->
      @clearSelection()
      if @isEditable and (not @isDraggable)
        @edit()
        @root().caret.gotoPos pos
        @startMark = @slotAt(pos)
        @endMark = @startMark
        @currentlySelecting = true
    
    @mouseMove = (pos) ->
      if @isEditable and @currentlySelecting and (not @isDraggable)
        newMark = @slotAt(pos)
        if newMark isnt @endMark
          @endMark = newMark
          @updateRendering()
          @changed()
  
  disableSelecting: ->
    # re-establish the original definition of the method
    @mouseDownLeft = StringMorph::mouseDownLeft
    delete @mouseMove
  '''
# How to play a test:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# window.world.systemTestsRecorderAndPlayer.eventQueue = SystemTestsRepo_NAMEOFTHETEST.testData
# window.world.systemTestsRecorderAndPlayer.startTestPlaying()

# How to save a test:
# window.world.systemTestsRecorderAndPlayer.startTestRecording()
# ...do the test...
# window.world.systemTestsRecorderAndPlayer.stopTestRecording()
# if you want to verify the test on the spot:
# window.world.systemTestsRecorderAndPlayer.startTestPlaying()
# then to save the test:
# console.log(JSON.stringify( window.world.systemTestsRecorderAndPlayer.eventQueue ))
# copy that blurb
# For recording screenshot data at any time:
# console.log(JSON.stringify(window.world.systemTestsRecorderAndPlayer.takeScreenshot()))
# Note for Chrome: You have to replace the data URL because
# it contains an ellipsis for more comfortable viewing in the console.
# Workaround: find that url and right-click: open in new tab and then copy the
# full data URL from the location bar and substitute it with the one
# of the ellipses.
# Then pass the JSON into http://js2coffee.org/
# and save it in this file.

# Tests name must start with "SystemTest_"
class SystemTest_SimpleMenuTest
  @testData = [
    type: "systemInfo"
    time: 0
    systemInfo:
      zombieKernelTestHarnessVersionMajor: 0
      zombieKernelTestHarnessVersionMinor: 1
      zombieKernelTestHarnessVersionRelease: 0
      userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31"
      screenWidth: 1920
      screenHeight: 1080
      screenColorDepth: 24
      screenPixelRatio: 1
      appCodeName: "Mozilla"
      appName: "Netscape"
      appVersion: "5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31"
      cookieEnabled: true
      platform: "MacIntel"
  ,
    type: "mouseMove"
    mouseX: 604
    mouseY: 4
    time: 1742
  ,
    type: "mouseMove"
    mouseX: 592
    mouseY: 14
    time: 17
  ,
    type: "mouseMove"
    mouseX: 581
    mouseY: 21
    time: 16
  ,
    type: "mouseMove"
    mouseX: 556
    mouseY: 25
    time: 17
  ,
    type: "mouseMove"
    mouseX: 544
    mouseY: 28
    time: 16
  ,
    type: "mouseMove"
    mouseX: 529
    mouseY: 37
    time: 17
  ,
    type: "mouseMove"
    mouseX: 513
    mouseY: 44
    time: 17
  ,
    type: "mouseMove"
    mouseX: 492
    mouseY: 55
    time: 17
  ,
    type: "mouseMove"
    mouseX: 482
    mouseY: 59
    time: 16
  ,
    type: "mouseMove"
    mouseX: 472
    mouseY: 64
    time: 17
  ,
    type: "mouseMove"
    mouseX: 464
    mouseY: 66
    time: 17
  ,
    type: "mouseMove"
    mouseX: 461
    mouseY: 67
    time: 16
  ,
    type: "mouseMove"
    mouseX: 460
    mouseY: 68
    time: 17
  ,
    type: "mouseMove"
    mouseX: 460
    mouseY: 69
    time: 17
  ,
    type: "mouseMove"
    mouseX: 458
    mouseY: 70
    time: 17
  ,
    type: "mouseMove"
    mouseX: 456
    mouseY: 72
    time: 18
  ,
    type: "mouseMove"
    mouseX: 455
    mouseY: 72
    time: 15
  ,
    type: "mouseMove"
    mouseX: 452
    mouseY: 74
    time: 16
  ,
    type: "mouseMove"
    mouseX: 450
    mouseY: 74
    time: 17
  ,
    type: "mouseMove"
    mouseX: 449
    mouseY: 75
    time: 50
  ,
    type: "mouseMove"
    mouseX: 448
    mouseY: 76
    time: 17
  ,
    type: "mouseMove"
    mouseX: 447
    mouseY: 77
    time: 16
  ,
    type: "mouseMove"
    mouseX: 445
    mouseY: 79
    time: 17
  ,
    type: "mouseMove"
    mouseX: 444
    mouseY: 80
    time: 17
  ,
    type: "mouseMove"
    mouseX: 444
    mouseY: 81
    time: 16
  ,
    type: "mouseMove"
    mouseX: 442
    mouseY: 83
    time: 17
  ,
    type: "mouseMove"
    mouseX: 436
    mouseY: 91
    time: 17
  ,
    type: "mouseMove"
    mouseX: 433
    mouseY: 95
    time: 17
  ,
    type: "mouseMove"
    mouseX: 423
    mouseY: 106
    time: 16
  ,
    type: "mouseMove"
    mouseX: 417
    mouseY: 115
    time: 17
  ,
    type: "mouseMove"
    mouseX: 414
    mouseY: 118
    time: 17
  ,
    type: "mouseMove"
    mouseX: 408
    mouseY: 123
    time: 16
  ,
    type: "mouseMove"
    mouseX: 396
    mouseY: 131
    time: 17
  ,
    type: "mouseMove"
    mouseX: 387
    mouseY: 135
    time: 16
  ,
    type: "mouseMove"
    mouseX: 380
    mouseY: 138
    time: 17
  ,
    type: "mouseMove"
    mouseX: 379
    mouseY: 139
    time: 66
  ,
    type: "mouseMove"
    mouseX: 378
    mouseY: 141
    time: 17
  ,
    type: "mouseMove"
    mouseX: 375
    mouseY: 142
    time: 17
  ,
    type: "mouseMove"
    mouseX: 373
    mouseY: 145
    time: 17
  ,
    type: "mouseMove"
    mouseX: 368
    mouseY: 149
    time: 16
  ,
    type: "mouseMove"
    mouseX: 365
    mouseY: 154
    time: 17
  ,
    type: "mouseMove"
    mouseX: 364
    mouseY: 154
    time: 17
  ,
    type: "mouseMove"
    mouseX: 364
    mouseY: 155
    time: 16
  ,
    type: "mouseDown"
    time: 145
    button: 2
    ctrlKey: false
  ,
    type: "mouseUp"
    time: 113
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 165
    time: 1809
  ,
    type: "takeScreenshot"
    time: 801
    screenShotImageData: [[
      zombieKernelTestHarnessVersionMajor: 0
      zombieKernelTestHarnessVersionMinor: 1
      zombieKernelTestHarnessVersionRelease: 0
      userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31"
      screenWidth: 1920
      screenHeight: 1080
      screenColorDepth: 24
      screenPixelRatio: 1
      appCodeName: "Mozilla"
      appName: "Netscape"
      appVersion: "5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31"
      cookieEnabled: true
      platform: "MacIntel"
      , "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAyAAAAJYCAYAAACadoJwAAAgAElEQVR4XuzdCZhU1Z338T+KLKIgOrggjMiAoyDLgASIedkGRxxAEGVTUAMBF5AJIxNlBzPRQFRAGRWBCYtsKoJBgUQWFUSRfVE0rogsIkuUsBhF3vf3n7n1Fk03Vd1ddauq63ufpx8a6t5zzv2cmzz185xzT7F169adMA4EEEAAAQQQQAABBBBAIASBYgSQEJSpAgEEEEAAAQQQQAABBFyAAMKDgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIz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A0jWwWTpDRNAsrTjuW0EioAAAaQIdCK3gAAC2SFAAMmOfo73Lgkg8UpxHgIIpJsAASTdeoT2IIAAAnkIEEB4NKIFCCA8DwggkKkCBJBM7TnajQACWSeQM4AEX0CzDiLLb3jFihUuQADJ8geB20cggwUIIBnceTQdAQSyS4ARkOzq71h3SwCJJcTnCCCQrgIEkHTtGdqFAAII5BAggPBIRAsQQHgeEEAgUwUIIJnac7QbAQSyToAAknVdftobJoDwPCCAQKYKEEAytedoNwIIZJ1ArACSc0PBaKBt27b5buebN2+2M8888yQ77ZLeqFEj39G8fPnyhXb9+OOPrXnz5vb+++/bV199Ffn93HPPLXTZFPD/BQggPA0IIJCpAgSQTO052o0AAlknEE8AUcjYuHGjFStW7CQfbUCoHdEbN258itvnn39u2u08kQHk2muv9fL2799vwe+JCDdZ1+mnuWECCE8DAghkqgABJFN7jnYjgEDWCcQTQFq1amUDBw60Xr16WaVKley1116zK6+80r788kubM2eO9e/f33dJf/fdd61r1652wQUXeECYOXNmJIBoROT++++3efPmWb9+/WzYsGF+Xs7j9ddft549e9qnn35qnTp1sjFjxljFihVNIyAEkOQ/ngSQ5BtTAwIIJEeAAJIcV0pFAAEEEi4QK4Doi3/16tWtY8eONnjwYJsyZYqtW7fOFBQ+/PBD69Kli61fv96nRtWuXdsDg6ZetWvXztuqEQsdCiwKHipn6NChtnv3blu2bJkVL148ck8KNJUrV7ZZs2b5qMrYsWNt79699txzz9knn3xCAEl4759aIAEkBGSqQACBpAgQQJLCSqEIIIBA4gXiCSD16tUzTak6//zz/c9gatW+fft8DciGDRs8NCxcuNBmzJgRCR5Nmzb1ALJkyRIbMmSIT9dS4FD40KiGRjkuv/zyyE1pSpdGUVq0aGHff/+9TZ8+3aZNm2bLly83jaAwApL4/s9ZIgEk+cbUgAACyREggCTHlVIRQACBhAvECiBahN6+ffvIQvPoqVDRAeTuu++2a665xnr37u1tjD5v6dKlPvKR81izZo1fExxHjhyxRx991IYPHx75t7Zt29r8+fM9rBBAEt79pxRIAEm+MTUggEByBAggyXGlVAQQQCDhAvEEkGCUQ+s88gogWt+hNR0a6dAR/RYsjYxM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FiCAJBiU4hBAAIFkCcQKIHrTlfbr0B4a2m1cr7bVpoPRu43rzVHRGwgmq62Um3wBAkjyjakBAQSSI0AASY4rpSKAAAIJF4gVQB555BHf2K9evXq+i7k2+9PO49oLIwgdeQWQHTt22JNPPmkXX3yx7yB+/fXX+y7ql112md+H9ubQHh0qq1OnTr4pYcWKFf0zbVT485//3F9127t3b9/YT5sA6u8afVF52tiwX79+NmzYMN8JnaPwAgSQwhtSAgIIpEaAAJIad2pFAAEE8i0QK4AocOjNTpp+pSDRo0cP0w7lCgGxAohGSbTBn67RxoOayvXWW2/5a2oVWipXruzlakRl7NixtnfvXt/BXGFD1z377LNWs2ZNr0f7hWi/Dh0akVHw6Nixow0dOtR2795ty5Yti7mfSL5xsvACAkgWdjq3jEARESCAFJGO5DYQQKDoC8QKIJqCdfXVV3vo0AZ+2i9jw4YNcY2AfPTRR9aqVavIvhh63a3Cw6uvvmpXXHGFj3Jo4z7VMX36dJs2bZrvYK7fVZ92GNexZcsWa9mypQcQ7ZquMKOpYNr8T+FDoyYaRbn88suLfocl+Q4JIEkGpngEEEiaAAEkabQUjAACCCRWIFYA0cZ6derUsXfeece010V+A4imT2mHce1QrrLq169vU6dOtRo1atijjz7qoyLB0bZtW5s/f77ddtttvqhd1+qIXm+isjTykfNYs2aNr1HhKJwAAaRwflyNAAKpEyCApM6emhFAAIF8CSQ7gLRv395HMIIAoilVc+bMsS+//NLXcShQVKlSxVatWmUPPvigrwv53e9+Zz/88IMNHjzY70UjH02bNvU/Fy5c6OtINBKic/SjERlN4ypRokS+7p2TTxUggPBUIIBApgoQQDK152g3AghknUAyA0iwBuSll16ym266ySZNmmQjR460bdu2+a7hWlS+adMmO3TokLVu3drXeWgE5I033vDztV7k0ksv9Wlc27dv9wCitSfasXzlypVWu3Ztn641YMAA+/zzz+2ss87yhfLt2rXzUJPb79WqVcu6Ps7PDRNA8qPFuQggkE4CBJB06g3aggACCJxGIL8BRG+t0ihF8BYshQztA6KF4vo9eh+QIIBEV681HgoQGgHRqIbK0TFixAj/0bqP++67z8NKr169/LNGjRrZgQMHbOPGjVa6dOmTPtPna9eu9aldmuKlEZbZs2dbrVq1cv29QYMGPA+nESCA8HgggECmChBAMrXnaDcCCGSdQKwAUhgQjVjcc889Ps1Kb70655xzPEAEx/Hjxz1YKLTo9bpHjx71UQyNcuhHb98qVqyYL0jXK3k11UpTuXR8++23vni9XLlyvP2qMJ2U41oCSAIxKQoBBEIVIICEyk1lCCCAQMEFkhlANNVKi9a1c/qZZ54ZdyO1u7pGMrRAvWrVqnbHHXf463q7dOkSdxmcWDABAkjB3LgKAQRSL0AASX0f0AIEEEAgLoFkBhC9dlfTpjTlSiMZ+Tn0Ct/XXnvNdu7cirzqbQAAIABJREFUaW3atPFF5hzJFyCAJN+YGhBAIDkCBJDkuFIqAgggkHCBZAaQhDeWApMuQABJOjEVIIBAkgQIIEmCpVgEEEAg0QIEkESLZnZ5BJDM7j9aj0A2CxBAsrn3uXcEEMgogVgBRFOhgjdfBQvAgxvUW660YaDWbES//SqZAFqcrrdiaYF7+fLlY1Z1uvbHvDjqhPzWm5+y0+lcAkg69QZtQQCB/AgQQPKjxbkIIIBACgViBZDgTVbLli07ZR1H9A7l8YSBRNym9vto2LBhvgKIFsJrLUp+16FEtze/9SbiXlNRBgEkFerUiQACiRAggCRCkTIQQACBEARiBZAgZPziF7+whx9+2K6//np75plnfKO/6ADyzTff2Pjx42306NH+qlx9YQ/+roXkTz/9tG8cqPr0Wt6ZM2dG/q6Q85e//MV3Rp83b57169fPhg0bZhdccIELvPvuu9a1a1f/u/Yb0bU5R0C0I/qUKVMie4dMmzbNunXr5m3URoYDBw70zypVquSL26+88kovW3uaaIRH+5F06tTJxowZYxUrVoxZr14N3LFjR7+uR48eft/nn3++PfDAA3bjjTfaz372M1u9erU98sgj9txzz/kriHWO3u4lw9zaWpiAlKhHhQCSKEnKQQCBsAUIIGGLUx8CCCBQQIF4Akj16tXt3nvv9R9tFLhkyRLbunWrv6FKgUBhQJsRdu7c2ffs0Ct39W/B3zV9SWVop/OnnnrKatSo4T/B3/WlVxsHKnjoS/3QoUNt9+7dplEXvcpXwUXBQFOvtMu5jpwBZM2aNdahQwdbtGiR7xGidilcaCd11a1yBw8e7F/8161b55/t2rXLKleu7K/41Vu2xo4da3v37vXAoPvLq16FJb0eeOLEidayZUsvV5shvvfee972H3/80UaNGmW//e1vPfho9EX3W7duXQ9Pf/vb33JtqzZmTPVBAEl1D1A/AggUVIAAUlA5rkMAAQRCFogVQLSGQiMI+sKvTQIPHz7sX75fffVVO++88yIBZN++fb7nR7BZoK4L/q5Rgnr16vlohEKH/oz++wsvvGBDhgzxL/DFixf38KFRCF23atUqW7hwoc2YMSMSPPRFPWcAefnll61v3762ePFi/7KvOrTpoXZHV10akdEIRfRUKgUlja60aNHCNzWcPn26aeREu7VrN/W86p0/f76HsKBNCjwKOQpMGgnSSMumTZt8pEP/poCjNv/kJz+xP//5z/anP/0p17ZqdCbVBwEk1T1A/QggUFABAkhB5bgOAQQQCFkgngASvQhdX+jr169vU6dOPW0AUQC4+eabPZAoSAQjJVorknPtyIsvvugjFDkPjWo8++yzds0111jv3r3947zWnRw5csRHUCZPnuzn6fdBgwb5aEj79u0jmyFGX1+yZEl79NFHfcPD4Gjbtq0pYNx999151quRIC2+D9oUmGh0pVq1aj69S+FFn6vsP/zhDz4t65VXXvH7yautF110Uci9f2p1BJCUdwENQACBAgoQQAoIx2UIIIBA2ALxBBB9gd+yZYuv7dCXba1jmDNnzikBJPqLvsKD1nRoqlOsAKKRhAkTJviogtZy6EfBRdOitKZCaz80QqIjr7dR7dmzx0dPypQp49On+vTp41PA9MU/emQmOoC88cYb3katSdGaFo22PPjgg95m/Xte9Wpti9ZrBG0KRoU02qHRF4UpTR1r3bq1t1//pkOjKxoVyautqjPVBwEk1T1A/QggUFABAkhB5bgOAQQQCFkgVgDRF3ZNL5o7d67ddNNNPsKghdW5rQG56qqrfC2ERgGaNGlil112mY8mxAogWjei3dJXrlzp6y40FWrAgAE+XUpTpDQqoQXdmvqlUQ2t0cg5BUsBRkFGC8xLlCjhay8qVKhw2gCiUYqHHnrIp0sdOnTIA4OmiKnNb731Vp71bt682T9T2zTaofUpCiXBNDWt87jtttsiZpripVcVay3IJZdc4mErt7aqL8aNG+frXBSIcvtdtsk8CCDJ1KVsBBBIpgABJJm6lI0AAggkUCDeABJUqf0+NEIQrOHQ1CqFFL3lSaHh8ccf91Ov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CAQEDJBASSISIECAAAECBAgQWBEwQFaadAcBAgQIECBAgACBgIABEihJRAIECBAgQIAAAQIrAgbISpPuIECAAAECBAgQIBAQMEACJYlIgAABAgQIECBAYEXAAFlp0h0ECBAgQIAAAQIEAgIGSKAkEQkQIECAAAECBAisCBggK026gwABAgQIECBAgEBAwAAJlCQiAQIECBAgQIAAgRUBA2SlSXcQIECAAAECBAgQCAgYIIGSRCRAgAABAgQIECCwImCArDTpDgIECBAgQIAAAQIBAQMkUJKIBAgQIECAAAECBFYEDJCVJt1BgAABAgQIECBAICBggARKEpEAAQIECBAgQIDAioABstKkOwgQIECAAAECBAgEBAyQQEkiEiBAgAABAgQIEFgRMEBWmnQHAQIECBAgQIAAgYCAARIoSUQCBAgQIECAAAECKwIGyEqT7iBAgAABAgQIECAQEDBAAiWJSIAAAQIECBAgQGBFwABZadIdBAgQIECAAAECBAICBkigJBEJECBAgAABAgQIrAgYICtNuoMAAQIECBAgQIBAQMAACZQkIgECBAgQIECAAIEVAQNkpUl3ECBAgAABAgQIEAgIGCCBkkQkQIAAAQIECBAgsCJggKw06Q4CBAgQIECAAAECAQEDJFCSiAQIECBAgAABAgRWBAyQlSbdQYAAAQIECBAgQCAgYIAEShKRAAECBAgQIECAwIqAAbLSpDsIECBAgAABAgQIBAQMkEBJIhIgQIAAAQIECBBYETBAVpp0BwECBAgQIECAAIGAgAESKElEAgQIECBAgAABAisCBshKk+4gQIAAAQIECBAgEBAwQAIliUiAAAECBAgQIEBgRcAAWWnSHQQIECBAgAABAgQCAgZIoCQRCRAgQIAAAQIECKwIGCArTbqDAAECBAgQIECAQEDAAAmUJCIBAgQIECBAgACBFQEDZKVJdxAgQIAAAQIECBAICBgggZJEJECAAAECBAgQILAiYICsNOkOAgQIECBAgAABAgEBAyRQkogECBAgQIAAAQIEVgQMkJUm3UGAAAECBAgQIEAgIGCABEoSkQABAgQIECBAgMCKgAGy0qQ7CBAgQIAAAQIECAQEDJBASSISIECAAAECBAgQWBEwQFaadAcBAgQIECBAgACBgIABEihJRAIECBAgQIAAAQIrAgbISpPuIECAAAECBAgQIBAQMEACJYlIgAABAgQIECBAYEXAAFlp0h0ECBAgQIAAAQIEAgIGSKAkEQkQIECAAAECBAisCBggK026gwABAgQIECBAgEBAwAAJlCQiAQIECBAgQIAAgRUBA2SlSXcQIECAAAECBAgQCAgYIIGSRCRAgAABAgQIECCwImCArDTpDgIECBAgQIAAAQIBAQMkUJKIBAgQIECAAAECBFYEDJCVJt1BgAABAgQIECBAICBggARKEpEAAQIECBAgQIDAioABstKkOwgQIECAAAECBAgEBAyQQEkiEiBAgAABAgQIEFgRMEBWmnQHAQIECBAgQIAAgYCAARIoSUQCBAgQIECAAAECKwIGyEqT7iBAgAABAgQIECAQEDBAAiWJSIAAAQIECBAgQGBFwABZadIdBAgQIECAAAECBAICBkigJBEJECBAgAABAgQIrAgYICtNuoMAAQIECBAgQIBAQMAACZQkIgECBAgQIECAAIEVAQNkpUl3ECBAgAABAgQIEAgIGCCBkkQkQIAAAQIECBAgsCJggKw06Q4CBAgQIECAAAECAQEDJFCSiAQIECBAgAABAgRWBAyQlSbdQYAAAQIECBAgQCAgYIAEShKRAAECBAgQIECAwIqAAbLSpDsIECBAgAABAgQIBAQMkEBJIhIgQIAAAQIECBBYETBAVpp0BwECBAgQIECAAIGAgAESKElEAgQIECBAgAABAisCBshKk+4gQIAAAQIECBAgEBAwQAIliUiAAAECBAgQIEBgRcAAWWnSHQQIECBAgAABAgQCAgZIoCQRCRAgQIAAAQIECKwIGCArTbqDAAECBAgQIECAQEDAAAmUJCIBAgQIECBAgACBFQEDZKVJdxAgQIAAAQIECBAICBgggZJEJECAAAECBAgQILAiYICsNOkOAgQIECBAgAABAgEBAyRQkogECBAgQIAAAQIEVgQMkJUm3UGAAAECBAgQIEAgIGCABEoSkQABAgQIECBAgMCKgAGy0qQ7CBAgQIAAAQIECAQEDJBASSISIECAAAECBAgQWBEwQFaadAcBAgQIECBAgACBgIABEihJRAIECBAgQIAAAQIrAgbISpPuIECAAAECBAgQIBAQMEACJYlIgAABAgQIECBAYEXAAFlp0h0ECBAgQIAAAQIEAgIGSKAkEQkQIECAAAECBAisCBggK026gwABAgQIECBAgEBAwAAJlCQiAQIECBAgQIAAgRUBA2SlSXcQIECAAAECBAgQCAgYIIGSRCRAgAABAgQIECCwImCArDTpDgIECBAgQIAAAQIBAQMkUJKIBAgQIECAAAECBFYEDJCVJt1BgAABAgQIECBAICBggARKEpEAAQIECBAgQIDAioABstKkOwgQIECAAAECBAgEBAyQQEkiEiBAgAABAgQIEFgRMEBWmnQHAQIECBAgQIAAgYCAARIoSUQCBAgQIECAAAECKwIGyEqT7iBAgAABAgQIECAQEDBAAiWJSIAAAQIECBAgQGBFwABZadIdBAgQIECAAAECBAICBkigJBEJECBAgAABAgQIrAgYICtNuoMAAQIECBAgQIBAQMAACZQkIgECBAgQIECAAIEVAQNkpUl3ECBAgAABAgQIEAgIGCCBkkQkQIAAAQIECBAgsCJggKw06Q4CBAgQIECAAAECAQEDJFCSiAQIECBAgAABAgRWBAyQlSbdQYAAAQIECBAgQCAgYIAEShKRAAECBAgQIECAwIqAAbLSpDsIECBAgAABAgQIBAQMkEBJIhIgQIAAAQIECBBYETBAVpp0BwECBAgQIECAAIGAgAESKElEAgQIECBAgAABAisCBshKk+4gQIAAAQIECBAgEBAwQAIliUiAAAECBAgQIEBgRcAAWWnSHQQIECBAgAABAgQCAgZIoCQRCRAgQIAAAQIECKwIGCArTbqDAAECBAgQIECAQEDAAAmUJCIBAgQIECBAgACBFQEDZKVJdxAgQIAAAQIECBAICBgggZJEJECAAAECBAgQILAiYICsNOkOAgQIECBAgAABAgEBAyRQkogECBAgQIAAAQIEVgQMkJUm3UGAAAECBAgQIEAgIGCABEoSkQABAgQIECBAgMCKgAGy0qQ7CBAgQIAAAQIECAQEDJBASSISIECAAAECBAgQWBEwQFaadAcBAgQIECBAgACBgIABEihJRAIECBAgQIAAAQIrAgbISpPuIECAAAECBAgQIBAQMEACJYlIgAABAgQIECBAYEXAAFlp0h0ECBAgQIAAAQIEAgIGSKAkEQkQIECAAAECBAisCBggK026gwABAgQIECBAgEBAwAAJlCQiAQIECBAgQIAAgRUBA2SlSXcQIECAAAECBAgQCAgYIIGSRCRAgAABAgQIECCwImCArDTpDgIECBAgQIAAAQIBAQMkUJKIBAgQIECAAAECBFYEDJCVJt1BgAABAgQIECBAICBggARKEpEAAQIECBAgQIDAioABstKkOwgQIECAAAECBAgEBAyQQEkiEiBAgAABAgQIEFgRMEBWmnQHAQIECBAgQIAAgYCAARIoSUQCBAgQIECAAAECKwIGyEqT7iBAgAABAgQIECAQEDBAAiWJSIAAAQIECBAgQGBFwABZadIdBAgQIECAAAECBAICBkigJBEJECBAgAABAgQIrAgYICtNuoMAAQIECBAgQIBAQMAACZQkIgECBAgQIECAAIEVAQNkpUl3ECBAgAABAgQIEAgIGCCBkkQkQIAAAQIECBAgsCJggKw06Q4CBAgQIECAAAECAQEDJFCSiAQIECBAgAABAgRWBAyQlSbdQYAAAQIECBAgQCAgYIAEShKRAAECBAgQIECAwIqAAbLSpDsIECBAgAABAgQIBAQMkEBJIhIgQIAAAQIECBBYETBAVpp0BwECBAgQIECAAIGAgAESKElEAgQIECBAgAABAisCBshKk+4gQIAAAQIECBAgEBAwQAIliUiAAAECBAgQIEBgRcAAWWnSHQQIECBAgAABAgQCAgZIoCQRCRAgQIAAAQIECKwIGCArTbqDAAECBAgQIECAQEDAAAmUJCIBAgQIECBAgACBFQEDZKVJdxAgQIAAAQIECBAICBgggZJEJECAAAECBAgQILAiYICsNOkOAgQIECBAgAABAgEBAyRQkogECBAgQIAAAQIEVgQMkJUm3UGAAAECBAgQIEAgIGCABEoSkQABAgQIECBAgMCKgAGy0qQ7CBAgQIAAAQIECAQEDJBASSISIECAAAECBAgQWBH4DTLBE+1uQpVLAAAAAElFTkSuQmCC"
      ],[
      zombieKernelTestHarnessVersionMajor: 0
      zombieKernelTestHarnessVersionMinor: 1
      zombieKernelTestHarnessVersionRelease: 0
      userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17"
      screenWidth: 1920
      screenHeight: 1080
      screenColorDepth: 24
      screenPixelRatio: 1
      appCodeName: "Mozilla"
      appName: "Netscape"
      appVersion: "5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17"
      cookieEnabled: true
      platform: "MacIntel"
      , "data:image/png;base64,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kSOtWbNmftfqiqVgQ+NA1AUraAHRM0NCAAEEElWAhQgT9ZuhXggggMDfBGKn3NUuDThWUssHKX8JBN+5WkGU1DKmWdHOnj1r6pp1+fJl36dnhoQAAggkqgABSKJ+M9QLAQQQiBHQD83kiW5XyUXy/ueUvvPz58+bXpqkQGOFUnpW8r4Md4gAArlJgAAkN31b1BUBBPKlgLrT5OcuNRpQfbNSbhhL8e2335peGhOkACS/Py8361nhugggkH4BApD0W5ETAQQQuCkCifKD8tlnn7VRo0aFBrfffru9/fbb1rdv33Bfw4YNbdOmTRmaoatu3br2xhtvhGXEbmjGr4ULF/ouTTerWcCef/752Cy+PXHiRD9WuXLlHxzL7I4GDRrY7NmzM3t6ZOcFrR7qdqVXojwvkQFwIQQQyHUCBCC57iujwgggkB8FEqEF5MMPPzT9KA9SkyZNTAPj9R4kHddsXeoOlBNJP7a1CrgGXQdJMz/9+Mc/9laAYF9+e48NOhLhWclv/twvAghkTIAAJGNe5EYAAQTyrYACkBo1aoStGwo8FixY4EFJ0E1KAcif//xnN9JsXXPnzrU1a9aYWijuuOMO31+1alX793//d+vZs6e99NJLP/D8u7/7O3v11VftlVdesVatWv3guBbga9myZbi/efPmprrFDrxO77UVuIwYMcKGDRtm//u//2vTp0+3ihUrhmVrRfEhQ4bY4sWLvU66/0RLQfARvCda/agPAgggkFyAACS5CJ8RQAABBFIUOHDggM+4pMXvlBSA/OEPfzCt0K2uV0p6VzCg7lITJkzwAENdtDRT07/92795niJFingAoeDi9ddf933BH00j+//+3/+zt956y/7zP//TunTpEhzyd43J+P3vf29t2rQJ97du3dq7ghUo8Nf/pWXk2pq6VoHQN99842tsHDx40B577LGw7OrVq1upUqVs7Nixpvv/p3/6p/AYGwgggAACmRMgAMmcG2chgAAC+VJArRsKMqpUqeItDl9++aVt3brVgxH98Fcrx/bt233RvE8++cS2bNliZ86csddee83UUhFMH3vLLbf4Qnp//OMfb3Bs3Lix7dq1y958801vSQnGfwSZ1CKhFpB77rnHW2K0AJ8Coc2bNwdZMnxtraUxZ84cX1l8xowZptYTXUdJs0upVURB1pIlS3zV8fBCbCCAAAIIZErg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BAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBAaU0YynAt9EwgAAAABJRU5ErkJggg=="
      ]
    ]
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 175
    time: 915
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 185
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 195
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 205
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 215
    time: 16
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 225
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 235
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 245
    time: 16
  ]

  @coffeeScriptSourceOfThisClass: '''
# How to play a test:
# from the Chrome console (Option-Command-J) OR Safari console (Option-Command-C):
# window.world.systemTestsRecorderAndPlayer.eventQueue = SystemTestsRepo_NAMEOFTHETEST.testData
# window.world.systemTestsRecorderAndPlayer.startTestPlaying()

# How to save a test:
# window.world.systemTestsRecorderAndPlayer.startTestRecording()
# ...do the test...
# window.world.systemTestsRecorderAndPlayer.stopTestRecording()
# if you want to verify the test on the spot:
# window.world.systemTestsRecorderAndPlayer.startTestPlaying()
# then to save the test:
# console.log(JSON.stringify( window.world.systemTestsRecorderAndPlayer.eventQueue ))
# copy that blurb
# For recording screenshot data at any time:
# console.log(JSON.stringify(window.world.systemTestsRecorderAndPlayer.takeScreenshot()))
# Note for Chrome: You have to replace the data URL because
# it contains an ellipsis for more comfortable viewing in the console.
# Workaround: find that url and right-click: open in new tab and then copy the
# full data URL from the location bar and substitute it with the one
# of the ellipses.
# Then pass the JSON into http://js2coffee.org/
# and save it in this file.

# Tests name must start with "SystemTest_"
class SystemTest_SimpleMenuTest
  @testData = [
    type: "systemInfo"
    time: 0
    systemInfo:
      zombieKernelTestHarnessVersionMajor: 0
      zombieKernelTestHarnessVersionMinor: 1
      zombieKernelTestHarnessVersionRelease: 0
      userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31"
      screenWidth: 1920
      screenHeight: 1080
      screenColorDepth: 24
      screenPixelRatio: 1
      appCodeName: "Mozilla"
      appName: "Netscape"
      appVersion: "5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31"
      cookieEnabled: true
      platform: "MacIntel"
  ,
    type: "mouseMove"
    mouseX: 604
    mouseY: 4
    time: 1742
  ,
    type: "mouseMove"
    mouseX: 592
    mouseY: 14
    time: 17
  ,
    type: "mouseMove"
    mouseX: 581
    mouseY: 21
    time: 16
  ,
    type: "mouseMove"
    mouseX: 556
    mouseY: 25
    time: 17
  ,
    type: "mouseMove"
    mouseX: 544
    mouseY: 28
    time: 16
  ,
    type: "mouseMove"
    mouseX: 529
    mouseY: 37
    time: 17
  ,
    type: "mouseMove"
    mouseX: 513
    mouseY: 44
    time: 17
  ,
    type: "mouseMove"
    mouseX: 492
    mouseY: 55
    time: 17
  ,
    type: "mouseMove"
    mouseX: 482
    mouseY: 59
    time: 16
  ,
    type: "mouseMove"
    mouseX: 472
    mouseY: 64
    time: 17
  ,
    type: "mouseMove"
    mouseX: 464
    mouseY: 66
    time: 17
  ,
    type: "mouseMove"
    mouseX: 461
    mouseY: 67
    time: 16
  ,
    type: "mouseMove"
    mouseX: 460
    mouseY: 68
    time: 17
  ,
    type: "mouseMove"
    mouseX: 460
    mouseY: 69
    time: 17
  ,
    type: "mouseMove"
    mouseX: 458
    mouseY: 70
    time: 17
  ,
    type: "mouseMove"
    mouseX: 456
    mouseY: 72
    time: 18
  ,
    type: "mouseMove"
    mouseX: 455
    mouseY: 72
    time: 15
  ,
    type: "mouseMove"
    mouseX: 452
    mouseY: 74
    time: 16
  ,
    type: "mouseMove"
    mouseX: 450
    mouseY: 74
    time: 17
  ,
    type: "mouseMove"
    mouseX: 449
    mouseY: 75
    time: 50
  ,
    type: "mouseMove"
    mouseX: 448
    mouseY: 76
    time: 17
  ,
    type: "mouseMove"
    mouseX: 447
    mouseY: 77
    time: 16
  ,
    type: "mouseMove"
    mouseX: 445
    mouseY: 79
    time: 17
  ,
    type: "mouseMove"
    mouseX: 444
    mouseY: 80
    time: 17
  ,
    type: "mouseMove"
    mouseX: 444
    mouseY: 81
    time: 16
  ,
    type: "mouseMove"
    mouseX: 442
    mouseY: 83
    time: 17
  ,
    type: "mouseMove"
    mouseX: 436
    mouseY: 91
    time: 17
  ,
    type: "mouseMove"
    mouseX: 433
    mouseY: 95
    time: 17
  ,
    type: "mouseMove"
    mouseX: 423
    mouseY: 106
    time: 16
  ,
    type: "mouseMove"
    mouseX: 417
    mouseY: 115
    time: 17
  ,
    type: "mouseMove"
    mouseX: 414
    mouseY: 118
    time: 17
  ,
    type: "mouseMove"
    mouseX: 408
    mouseY: 123
    time: 16
  ,
    type: "mouseMove"
    mouseX: 396
    mouseY: 131
    time: 17
  ,
    type: "mouseMove"
    mouseX: 387
    mouseY: 135
    time: 16
  ,
    type: "mouseMove"
    mouseX: 380
    mouseY: 138
    time: 17
  ,
    type: "mouseMove"
    mouseX: 379
    mouseY: 139
    time: 66
  ,
    type: "mouseMove"
    mouseX: 378
    mouseY: 141
    time: 17
  ,
    type: "mouseMove"
    mouseX: 375
    mouseY: 142
    time: 17
  ,
    type: "mouseMove"
    mouseX: 373
    mouseY: 145
    time: 17
  ,
    type: "mouseMove"
    mouseX: 368
    mouseY: 149
    time: 16
  ,
    type: "mouseMove"
    mouseX: 365
    mouseY: 154
    time: 17
  ,
    type: "mouseMove"
    mouseX: 364
    mouseY: 154
    time: 17
  ,
    type: "mouseMove"
    mouseX: 364
    mouseY: 155
    time: 16
  ,
    type: "mouseDown"
    time: 145
    button: 2
    ctrlKey: false
  ,
    type: "mouseUp"
    time: 113
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 165
    time: 1809
  ,
    type: "takeScreenshot"
    time: 801
    screenShotImageData: [[
      zombieKernelTestHarnessVersionMajor: 0
      zombieKernelTestHarnessVersionMinor: 1
      zombieKernelTestHarnessVersionRelease: 0
      userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31"
      screenWidth: 1920
      screenHeight: 1080
      screenColorDepth: 24
      screenPixelRatio: 1
      appCodeName: "Mozilla"
      appName: "Netscape"
      appVersion: "5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31"
      cookieEnabled: true
      platform: "MacIntel"
      , "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAyAAAAJYCAYAAACadoJwAAAgAElEQVR4XuzdCZhU1Z338T+KLKIgOrggjMiAoyDLgASIedkGRxxAEGVTUAMBF5AJIxNlBzPRQFRAGRWBCYtsKoJBgUQWFUSRfVE0rogsIkuUsBhF3vf3n7n1Fk03Vd1ddauq63ufpx8a6t5zzv2cmzz185xzT7F169adMA4EEEAAAQQQQAABBBBAIASBYgSQEJSpAgEEEEAAAQQQQAABBFyAAMKDgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIzgAACCCCAAAIIIIAAAqEJEEBCo6YiBBBAAAEEEEAAAQQQIIDwDCCAAAIIIIAAAggggEBoAgSQ0KipCAEEEEAAAQQQQAABBAggPAMIIIAAAggggAACCCAQmgABJDRqKkIAAQQQQAABBBBAAAECCM8AAggggAACCCCAAAIIhCZAAAmNmooQQAABBBBAAAEEEECAAMIz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A0jWwWTpDRNAsrTjuW0EioAAAaQIdCK3gAAC2SFAAMmOfo73Lgkg8UpxHgIIpJsAASTdeoT2IIAAAnkIEEB4NKIFCCA8DwggkKkCBJBM7TnajQACWSeQM4AEX0CzDiLLb3jFihUuQADJ8geB20cggwUIIBnceTQdAQSyS4ARkOzq71h3SwCJJcTnCCCQrgIEkHTtGdqFAAII5BAggPBIRAsQQHgeEEAgUwUIIJnac7QbAQSyToAAknVdftobJoDwPCCAQKYKEEAytedoNwIIZJ1ArACSc0PBaKBt27b5buebN2+2M8888yQ77ZLeqFEj39G8fPnyhXb9+OOPrXnz5vb+++/bV199Ffn93HPPLXTZFPD/BQggPA0IIJCpAgSQTO052o0AAlknEE8AUcjYuHGjFStW7CQfbUCoHdEbN258itvnn39u2u08kQHk2muv9fL2799vwe+JCDdZ1+mnuWECCE8DAghkqgABJFN7jnYjgEDWCcQTQFq1amUDBw60Xr16WaVKley1116zK6+80r788kubM2eO9e/f33dJf/fdd61r1652wQUXeECYOXNmJIBoROT++++3efPmWb9+/WzYsGF+Xs7j9ddft549e9qnn35qnTp1sjFjxljFihVNIyAEkOQ/ngSQ5BtTAwIIJEeAAJIcV0pFAAEEEi4QK4Doi3/16tWtY8eONnjwYJsyZYqtW7fOFBQ+/PBD69Kli61fv96nRtWuXdsDg6ZetWvXztuqEQsdCiwKHipn6NChtnv3blu2bJkVL148ck8KNJUrV7ZZs2b5qMrYsWNt79699txzz9knn3xCAEl4759aIAEkBGSqQACBpAgQQJLCSqEIIIBA4gXiCSD16tUzTak6//zz/c9gatW+fft8DciGDRs8NCxcuNBmzJgRCR5Nmzb1ALJkyRIbMmSIT9dS4FD40KiGRjkuv/zyyE1pSpdGUVq0aGHff/+9TZ8+3aZNm2bLly83jaAwApL4/s9ZIgEk+cbUgAACyREggCTHlVIRQACBhAvECiBahN6+ffvIQvPoqVDRAeTuu++2a665xnr37u1tjD5v6dKlPvKR81izZo1fExxHjhyxRx991IYPHx75t7Zt29r8+fM9rBBAEt79pxRIAEm+MTUggEByBAggyXGlVAQQQCDhAvEEkGCUQ+s88gogWt+hNR0a6dAR/RYsjYxM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FiCAJBiU4hBAAIFkCcQKIHrTlfbr0B4a2m1cr7bVpoPRu43rzVHRGwgmq62Um3wBAkjyjakBAQSSI0AASY4rpSKAAAIJF4gVQB555BHf2K9evXq+i7k2+9PO49oLIwgdeQWQHTt22JNPPmkXX3yx7yB+/fXX+y7ql112md+H9ubQHh0qq1OnTr4pYcWKFf0zbVT485//3F9127t3b9/YT5sA6u8afVF52tiwX79+NmzYMN8JnaPwAgSQwhtSAgIIpEaAAJIad2pFAAEE8i0QK4AocOjNTpp+pSDRo0cP0w7lCgGxAohGSbTBn67RxoOayvXWW2/5a2oVWipXruzlakRl7NixtnfvXt/BXGFD1z377LNWs2ZNr0f7hWi/Dh0akVHw6Nixow0dOtR2795ty5Yti7mfSL5xsvACAkgWdjq3jEARESCAFJGO5DYQQKDoC8QKIJqCdfXVV3vo0AZ+2i9jw4YNcY2AfPTRR9aqVavIvhh63a3Cw6uvvmpXXHGFj3Jo4z7VMX36dJs2bZrvYK7fVZ92GNexZcsWa9mypQcQ7ZquMKOpYNr8T+FDoyYaRbn88suLfocl+Q4JIEkGpngEEEiaAAEkabQUjAACCCRWIFYA0cZ6derUsXfeece010V+A4imT2mHce1QrrLq169vU6dOtRo1atijjz7qoyLB0bZtW5s/f77ddtttvqhd1+qIXm+isjTykfNYs2aNr1HhKJwAAaRwflyNAAKpEyCApM6emhFAAIF8CSQ7gLRv395HMIIAoilVc+bMsS+//NLXcShQVKlSxVatWmUPPvigrwv53e9+Zz/88IMNHjzY70UjH02bNvU/Fy5c6OtINBKic/SjERlN4ypRokS+7p2TTxUggPBUIIBApgoQQDK152g3AghknUAyA0iwBuSll16ym266ySZNmmQjR460bdu2+a7hWlS+adMmO3TokLVu3drXeWgE5I033vDztV7k0ksv9Wlc27dv9wCitSfasXzlypVWu3Ztn641YMAA+/zzz+2ss87yhfLt2rXzUJPb79WqVcu6Ps7PDRNA8qPFuQggkE4CBJB06g3aggACCJxGIL8BRG+t0ihF8BYshQztA6KF4vo9eh+QIIBEV681HgoQGgHRqIbK0TFixAj/0bqP++67z8NKr169/LNGjRrZgQMHbOPGjVa6dOmTPtPna9eu9aldmuKlEZbZs2dbrVq1cv29QYMGPA+nESCA8HgggECmChBAMrXnaDcCCGSdQKwAUhgQjVjcc889Ps1Kb70655xzPEAEx/Hjxz1YKLTo9bpHjx71UQyNcuhHb98qVqyYL0jXK3k11UpTuXR8++23vni9XLlyvP2qMJ2U41oCSAIxKQoBBEIVIICEyk1lCCCAQMEFkhlANNVKi9a1c/qZZ54ZdyO1u7pGMrRAvWrVqnbHHXf463q7dOkSdxmcWDABAkjB3LgKAQRSL0AASX0f0AIEEEAgLoFkBhC9dlfTpjTlSiMZ+Tn0Ct/XXnvNdu7cirzqbQAAIABJREFUaW3atPFF5hzJFyCAJN+YGhBAIDkCBJDkuFIqAgggkHCBZAaQhDeWApMuQABJOjEVIIBAkgQIIEmCpVgEEEAg0QIEkESLZnZ5BJDM7j9aj0A2CxBAsrn3uXcEEMgogVgBRFOhgjdfBQvAgxvUW660YaDWbES//SqZAFqcrrdiaYF7+fLlY1Z1uvbHvDjqhPzWm5+y0+lcAkg69QZtQQCB/AgQQPKjxbkIIIBACgViBZDgTVbLli07ZR1H9A7l8YSBRNym9vto2LBhvgKIFsJrLUp+16FEtze/9SbiXlNRBgEkFerUiQACiRAggCRCkTIQQACBEARiBZAgZPziF7+whx9+2K6//np75plnfKO/6ADyzTff2Pjx42306NH+qlx9YQ/+roXkTz/9tG8cqPr0Wt6ZM2dG/q6Q85e//MV3Rp83b57169fPhg0bZhdccIELvPvuu9a1a1f/u/Yb0bU5R0C0I/qUKVMie4dMmzbNunXr5m3URoYDBw70zypVquSL26+88kovW3uaaIRH+5F06tTJxowZYxUrVoxZr14N3LFjR7+uR48eft/nn3++PfDAA3bjjTfaz372M1u9erU98sgj9txzz/kriHWO3u4lw9zaWpiAlKhHhQCSKEnKQQCBsAUIIGGLUx8CCCBQQIF4Akj16tXt3nvv9R9tFLhkyRLbunWrv6FKgUBhQJsRdu7c2ffs0Ct39W/B3zV9SWVop/OnnnrKatSo4T/B3/WlVxsHKnjoS/3QoUNt9+7dplEXvcpXwUXBQFOvtMu5jpwBZM2aNdahQwdbtGiR7xGidilcaCd11a1yBw8e7F/8161b55/t2rXLKleu7K/41Vu2xo4da3v37vXAoPvLq16FJb0eeOLEidayZUsvV5shvvfee972H3/80UaNGmW//e1vPfho9EX3W7duXQ9Pf/vb33JtqzZmTPVBAEl1D1A/AggUVIAAUlA5rkMAAQRCFogVQLSGQiMI+sKvTQIPHz7sX75fffVVO++88yIBZN++fb7nR7BZoK4L/q5Rgnr16vlohEKH/oz++wsvvGBDhgzxL/DFixf38KFRCF23atUqW7hwoc2YMSMSPPRFPWcAefnll61v3762ePFi/7KvOrTpoXZHV10akdEIRfRUKgUlja60aNHCNzWcPn26aeREu7VrN/W86p0/f76HsKBNCjwKOQpMGgnSSMumTZt8pEP/poCjNv/kJz+xP//5z/anP/0p17ZqdCbVBwEk1T1A/QggUFABAkhB5bgOAQQQCFkgngASvQhdX+jr169vU6dOPW0AUQC4+eabPZAoSAQjJVorknPtyIsvvugjFDkPjWo8++yzds0111jv3r3947zWnRw5csRHUCZPnuzn6fdBgwb5aEj79u0jmyFGX1+yZEl79NFHfcPD4Gjbtq0pYNx999151quRIC2+D9oUmGh0pVq1aj69S+FFn6vsP/zhDz4t65VXXvH7yautF110Uci9f2p1BJCUdwENQACBAgoQQAoIx2UIIIBA2ALxBBB9gd+yZYuv7dCXba1jmDNnzikBJPqLvsKD1nRoqlOsAKKRhAkTJviogtZy6EfBRdOitKZCaz80QqIjr7dR7dmzx0dPypQp49On+vTp41PA9MU/emQmOoC88cYb3katSdGaFo22PPjgg95m/Xte9Wpti9ZrBG0KRoU02qHRF4UpTR1r3bq1t1//pkOjKxoVyautqjPVBwEk1T1A/QggUFABAkhB5bgOAQQQCFkgVgDRF3ZNL5o7d67ddNNNPsKghdW5rQG56qqrfC2ERgGaNGlil112mY8mxAogWjei3dJXrlzp6y40FWrAgAE+XUpTpDQqoQXdmvqlUQ2t0cg5BUsBRkFGC8xLlCjhay8qVKhw2gCiUYqHHnrIp0sdOnTIA4OmiKnNb731Vp71bt682T9T2zTaofUpCiXBNDWt87jtttsiZpripVcVay3IJZdc4mErt7aqL8aNG+frXBSIcvtdtsk8CCDJ1KVsBBBIpgABJJm6lI0AAggkUCDeABJUqf0+NEIQrOHQ1CqFFL3lSaHh8ccf91Ov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CAQEDJBASSISIECAAAECBAgQWBEwQFaadAcBAgQIECBAgACBgIABEihJRAIECBAgQIAAAQIrAgbISpPuIECAAAECBAgQIBAQMEACJYlIgAABAgQIECBAYEXAAFlp0h0ECBAgQIAAAQIEAgIGSKAkEQkQIECAAAECBAisCBggK026gwABAgQIECBAgEBAwAAJlCQiAQIECBAgQIAAgRUBA2SlSXcQIECAAAECBAgQCAgYIIGSRCRAgAABAgQIECCwImCArDTpDgIECBAgQIAAAQIBAQMkUJKIBAgQIECAAAECBFYEDJCVJt1BgAABAgQIECBAICBggARKEpEAAQIECBAgQIDAioABstKkOwgQIECAAAECBAgEBAyQQEkiEiBAgAABAgQIEFgRMEBWmnQHAQIECBAgQIAAgYCAARIoSUQCBAgQIECAAAECKwIGyEqT7iBAgAABAgQIECAQEDBAAiWJSIAAAQIECBAgQGBFwABZadIdBAgQIECAAAECBAICBkigJBEJECBAgAABAgQIrAgYICtNuoMAAQIECBAgQIBAQMAACZQkIgECBAgQIECAAIEVAQNkpUl3ECBAgAABAgQIEAgIGCCBkkQkQIAAAQIECBAgsCJggKw06Q4CBAgQIECAAAECAQEDJFCSiAQIECBAgAABAgRWBAyQlSbdQYAAAQIECBAgQCAgYIAEShKRAAECBAgQIECAwIqAAbLSpDsIECBAgAABAgQIBAQMkEBJIhIgQIAAAQIECBBYETBAVpp0BwECBAgQIECAAIGAgAESKElEAgQIECBAgAABAisCBshKk+4gQIAAAQIECBAgEBAwQAIliUiAAAECBAgQIEBgRcAAWWnSHQQIECBAgAABAgQCAgZIoCQRCRAgQIAAAQIECKwIGCArTbqDAAECBAgQIECAQEDAAAmUJCIBAgQIECBAgACBFQEDZKVJdxAgQIAAAQIECBAICBgggZJEJECAAAECBAgQILAiYICsNOkOAgQIECBAgAABAgEBAyRQkogECBAgQIAAAQIEVgQMkJUm3UGAAAECBAgQIEAgIGCABEoSkQABAgQIECBAgMCKgAGy0qQ7CBAgQIAAAQIECAQEDJBASSISIECAAAECBAgQWBEwQFaadAcBAgQIECBAgACBgIABEihJRAIECBAgQIAAAQIrAgbISpPuIECAAAECBAgQIBAQMEACJYlIgAABAgQIECBAYEXAAFlp0h0ECBAgQIAAAQIEAgIGSKAkEQkQIECAAAECBAisCBggK026gwABAgQIECBAgEBAwAAJlCQiAQIECBAgQIAAgRUBA2SlSXcQIECAAAECBAgQCAgYIIGSRCRAgAABAgQIECCwImCArDTpDgIECBAgQIAAAQIBAQMkUJKIBAgQIECAAAECBFYEDJCVJt1BgAABAgQIECBAICBggARKEpEAAQIECBAgQIDAioABstKkOwgQIECAAAECBAgEBAyQQEkiEiBAgAABAgQIEFgRMEBWmnQHAQIECBAgQIAAgYCAARIoSUQCBAgQIECAAAECKwIGyEqT7iBAgAABAgQIECAQEDBAAiWJSIAAAQIECBAgQGBFwABZadIdBAgQIECAAAECBAICBkigJBEJECBAgAABAgQIrAgYICtNuoMAAQIECBAgQIBAQMAACZQkIgECBAgQIECAAIEVAQNkpUl3ECBAgAABAgQIEAgIGCCBkkQkQIAAAQIECBAgsCJggKw06Q4CBAgQIECAAAECAQEDJFCSiAQIECBAgAABAgRWBAyQlSbdQYAAAQIECBAgQCAgYIAEShKRAAECBAgQIECAwIqAAbLSpDsIECBAgAABAgQIBAQMkEBJIhIgQIAAAQIECBBYETBAVpp0BwECBAgQIECAAIGAgAESKElEAgQIECBAgAABAisCBshKk+4gQIAAAQIECBAgEBAwQAIliUiAAAECBAgQIEBgRcAAWWnSHQQIECBAgAABAgQCAgZIoCQRCRAgQIAAAQIECKwIGCArTbqDAAECBAgQIECAQEDAAAmUJCIBAgQIECBAgACBFQEDZKVJdxAgQIAAAQIECBAICBgggZJEJECAAAECBAgQILAiYICsNOkOAgQIECBAgAABAgEBAyRQkogECBAgQIAAAQIEVgQMkJUm3UGAAAECBAgQIEAgIGCABEoSkQABAgQIECBAgMCKgAGy0qQ7CBAgQIAAAQIECAQEDJBASSISIECAAAECBAgQWBEwQFaadAcBAgQIECBAgACBgIABEihJRAIECBAgQIAAAQIrAgbISpPuIECAAAECBAgQIBAQMEACJYlIgAABAgQIECBAYEXAAFlp0h0ECBAgQIAAAQIEAgIGSKAkEQkQIECAAAECBAisCBggK026gwABAgQIECBAgEBAwAAJlCQiAQIECBAgQIAAgRUBA2SlSXcQIECAAAECBAgQCAgYIIGSRCRAgAABAgQIECCwImCArDTpDgIECBAgQIAAAQIBAQMkUJKIBAgQIECAAAECBFYEDJCVJt1BgAABAgQIECBAICBggARKEpEAAQIECBAgQIDAioABstKkOwgQIECAAAECBAgEBAyQQEkiEiBAgAABAgQIEFgRMEBWmnQHAQIECBAgQIAAgYCAARIoSUQCBAgQIECAAAECKwIGyEqT7iBAgAABAgQIECAQEDBAAiWJSIAAAQIECBAgQGBFwABZadIdBAgQIECAAAECBAICBkigJBEJECBAgAABAgQIrAgYICtNuoMAAQIECBAgQIBAQMAACZQkIgECBAgQIECAAIEVAQNkpUl3ECBAgAABAgQIEAgIGCCBkkQkQIAAAQIECBAgsCJggKw06Q4CBAgQIECAAAECAQEDJFCSiAQIECBAgAABAgRWBAyQlSbdQYAAAQIECBAgQCAgYIAEShKRAAECBAgQIECAwIqAAbLSpDsIECBAgAABAgQIBAQMkEBJIhIgQIAAAQIECBBYETBAVpp0BwECBAgQIECAAIGAgAESKElEAgQIECBAgAABAisCBshKk+4gQIAAAQIECBAgEBAwQAIliUiAAAECBAgQIEBgRcAAWWnSHQQIECBAgAABAgQCAgZIoCQRCRAgQIAAAQIECKwIGCArTbqDAAECBAgQIECAQEDAAAmUJCIBAgQIECBAgACBFQEDZKVJdxAgQIAAAQIECBAICBgggZJEJECAAAECBAgQILAiYICsNOkOAgQIECBAgAABAgEBAyRQkogECBAgQIAAAQIEVgQMkJUm3UGAAAECBAgQIEAgIGCABEoSkQABAgQIECBAgMCKgAGy0qQ7CBAgQIAAAQIECAQEDJBASSISIECAAAECBAgQWBEwQFaadAcBAgQIECBAgACBgIABEihJRAIECBAgQIAAAQIrAgbISpPuIECAAAECBAgQIBAQMEACJYlIgAABAgQIECBAYEXAAFlp0h0ECBAgQIAAAQIEAgIGSKAkEQkQIECAAAECBAisCBggK026gwABAgQIECBAgEBAwAAJlCQiAQIECBAgQIAAgRUBA2SlSXcQIECAAAECBAgQCAgYIIGSRCRAgAABAgQIECCwImCArDTpDgIECBAgQIAAAQIBAQMkUJKIBAgQIECAAAECBFYEDJCVJt1BgAABAgQIECBAICBggARKEpEAAQIECBAgQIDAioABstKkOwgQIECAAAECBAgEBAyQQEkiEiBAgAABAgQIEFgRMEBWmnQHAQIECBAgQIAAgYCAARIoSUQCBAgQIECAAAECKwIGyEqT7iBAgAABAgQIECAQEDBAAiWJSIAAAQIECBAgQGBFwABZadIdBAgQIECAAAECBAICBkigJBEJECBAgAABAgQIrAgYICtNuoMAAQIECBAgQIBAQMAACZQkIgECBAgQIECAAIEVAQNkpUl3ECBAgAABAgQIEAgIGCCBkkQkQIAAAQIECBAgsCJggKw06Q4CBAgQIECAAAECAQEDJFCSiAQIECBAgAABAgRWBAyQlSbdQYAAAQIECBAgQCAgYIAEShKRAAECBAgQIECAwIqAAbLSpDsIECBAgAABAgQIBAQMkEBJIhIgQIAAAQIECBBYETBAVpp0BwECBAgQIECAAIGAgAESKElEAgQIECBAgAABAisCBshKk+4gQIAAAQIECBAgEBAwQAIliUiAAAECBAgQIEBgRcAAWWnSHQQIECBAgAABAgQCAgZIoCQRCRAgQIAAAQIECKwIGCArTbqDAAECBAgQIECAQEDAAAmUJCIBAgQIECBAgACBFQEDZKVJdxAgQIAAAQIECBAICBgggZJEJECAAAECBAgQILAiYICsNOkOAgQIECBAgAABAgEBAyRQkogECBAgQIAAAQIEVgQMkJUm3UGAAAECBAgQIEAgIGCABEoSkQABAgQIECBAgMCKgAGy0qQ7CBAgQIAAAQIECAQEDJBASSISIECAAAECBAgQWBH4DTLBE+1uQpVLAAAAAElFTkSuQmCC"
      ],[
      zombieKernelTestHarnessVersionMajor: 0
      zombieKernelTestHarnessVersionMinor: 1
      zombieKernelTestHarnessVersionRelease: 0
      userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17"
      screenWidth: 1920
      screenHeight: 1080
      screenColorDepth: 24
      screenPixelRatio: 1
      appCodeName: "Mozilla"
      appName: "Netscape"
      appVersion: "5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17"
      cookieEnabled: true
      platform: "MacIntel"
      , "data:image/png;base64,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kSOtWbNmftfqiqVgQ+NA1AUraAHRM0NCAAEEElWAhQgT9ZuhXggggMDfBGKn3NUuDThWUssHKX8JBN+5WkGU1DKmWdHOnj1r6pp1+fJl36dnhoQAAggkqgABSKJ+M9QLAQQQiBHQD83kiW5XyUXy/ueUvvPz58+bXpqkQGOFUnpW8r4Md4gAArlJgAAkN31b1BUBBPKlgLrT5OcuNRpQfbNSbhhL8e2335peGhOkACS/Py8361nhugggkH4BApD0W5ETAQQQuCkCifKD8tlnn7VRo0aFBrfffru9/fbb1rdv33Bfw4YNbdOmTRmaoatu3br2xhtvhGXEbmjGr4ULF/ouTTerWcCef/752Cy+PXHiRD9WuXLlHxzL7I4GDRrY7NmzM3t6ZOcFrR7qdqVXojwvkQFwIQQQyHUCBCC57iujwgggkB8FEqEF5MMPPzT9KA9SkyZNTAPj9R4kHddsXeoOlBNJP7a1CrgGXQdJMz/9+Mc/9laAYF9+e48NOhLhWclv/twvAghkTIAAJGNe5EYAAQTyrYACkBo1aoStGwo8FixY4EFJ0E1KAcif//xnN9JsXXPnzrU1a9aYWijuuOMO31+1alX793//d+vZs6e99NJLP/D8u7/7O3v11VftlVdesVatWv3guBbga9myZbi/efPmprrFDrxO77UVuIwYMcKGDRtm//u//2vTp0+3ihUrhmVrRfEhQ4bY4sWLvU66/0RLQfARvCda/agPAgggkFyAACS5CJ8RQAABBFIUOHDggM+4pMXvlBSA/OEPfzCt0K2uV0p6VzCg7lITJkzwAENdtDRT07/92795niJFingAoeDi9ddf933BH00j+//+3/+zt956y/7zP//TunTpEhzyd43J+P3vf29t2rQJ97du3dq7ghUo8Nf/pWXk2pq6VoHQN99842tsHDx40B577LGw7OrVq1upUqVs7Nixpvv/p3/6p/AYGwgggAACmRMgAMmcG2chgAAC+VJArRsKMqpUqeItDl9++aVt3brVgxH98Fcrx/bt233RvE8++cS2bNliZ86csddee83UUhFMH3vLLbf4Qnp//OMfb3Bs3Lix7dq1y958801vSQnGfwSZ1CKhFpB77rnHW2K0AJ8Coc2bNwdZMnxtraUxZ84cX1l8xowZptYTXUdJs0upVURB1pIlS3zV8fBCbCCAAAIIZErg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BAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBByQqzmVIUCAAAECBAgQINAWcEDa+0hHgAABAgQIECBA4ErAAbmaUxkCBAgQIECAAAECbQEHpL2PdAQIECBAgAABAgSuBAaU0YynAt9EwgAAAABJRU5ErkJggg=="
      ]
    ]
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 175
    time: 915
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 185
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 195
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 205
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 215
    time: 16
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 225
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 235
    time: 17
  ,
    type: "mouseMove"
    mouseX: 374
    mouseY: 245
    time: 16
  ]
  '''
# MorphsListMorph //////////////////////////////////////////////////////

class MorphsListMorph extends BoxMorph

  # panes:
  morphsList: null
  buttonClose: null
  resizer: null

  constructor: (target) ->
    super()

    @silentSetExtent new Point(
      WorldMorph.MorphicPreferences.handleSize * 10,
      WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @updateRendering()
    @buildPanes()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []

    # remove existing panes
    @children.forEach (m) ->
      # keep work pane around
      m.destroy()  if m isnt @work

    @children = []

    # label
    @label = new TextMorph("Morphs List")
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.updateRendering()
    @add @label

    # Check which objects end with the word Morph
    theWordMorph = "Morph"
    ListOfMorphs = (Object.keys(window)).filter (i) ->
      i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
    @morphsList = new ListMorph(ListOfMorphs, null)

    # so far nothing happens when items are selected
    #@morphsList.action = (selected) ->
    #  val = myself.target[selected]
    #  myself.currentProperty = val
    #  if val is null
    #    txt = "NULL"
    #  else if isString(val)
    #    txt = val
    #  else
    #    txt = val.toString()
    #  cnts = new TextMorph(txt)
    #  cnts.isEditable = true
    #  cnts.enableSelecting()
    #  cnts.setReceiver myself.target
    #  myself.detail.setContents cnts

    @morphsList.hBar.alpha = 0.6
    @morphsList.vBar.alpha = 0.6
    @add @morphsList

    # close button
    @buttonClose = new TriggerMorph()
    @buttonClose.labelString = "close"
    @buttonClose.action = =>
      @destroy()

    @add @buttonClose

    # resizer
    @resizer = new HandleMorph(@, 150, 100, @edge, @edge)

    # update layout
    @fixLayout()
  
  fixLayout: ->
    Morph::trackChanges = false

    # label
    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x
    @label.setPosition new Point(x, y)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @silentSetHeight @label.height() + 50
      @updateRendering()
      @changed()
      @resizer.updateRendering()

    # morphsList
    y = @label.bottom() + 2
    w = @width() - @edge
    w -= @edge
    b = @bottom() - (2 * @edge) - WorldMorph.MorphicPreferences.handleSize
    h = b - y
    @morphsList.setPosition new Point(x, y)
    @morphsList.setExtent new Point(w, h)

    # close button
    x = @morphsList.left()
    y = @morphsList.bottom() + @edge
    h = WorldMorph.MorphicPreferences.handleSize
    w = @morphsList.width() - h - @edge
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
    @fixLayout()

  @coffeeScriptSourceOfThisClass: '''
# MorphsListMorph //////////////////////////////////////////////////////

class MorphsListMorph extends BoxMorph

  # panes:
  morphsList: null
  buttonClose: null
  resizer: null

  constructor: (target) ->
    super()

    @silentSetExtent new Point(
      WorldMorph.MorphicPreferences.handleSize * 10,
      WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @updateRendering()
    @buildPanes()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []

    # remove existing panes
    @children.forEach (m) ->
      # keep work pane around
      m.destroy()  if m isnt @work

    @children = []

    # label
    @label = new TextMorph("Morphs List")
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.updateRendering()
    @add @label

    # Check which objects end with the word Morph
    theWordMorph = "Morph"
    ListOfMorphs = (Object.keys(window)).filter (i) ->
      i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
    @morphsList = new ListMorph(ListOfMorphs, null)

    # so far nothing happens when items are selected
    #@morphsList.action = (selected) ->
    #  val = myself.target[selected]
    #  myself.currentProperty = val
    #  if val is null
    #    txt = "NULL"
    #  else if isString(val)
    #    txt = val
    #  else
    #    txt = val.toString()
    #  cnts = new TextMorph(txt)
    #  cnts.isEditable = true
    #  cnts.enableSelecting()
    #  cnts.setReceiver myself.target
    #  myself.detail.setContents cnts

    @morphsList.hBar.alpha = 0.6
    @morphsList.vBar.alpha = 0.6
    @add @morphsList

    # close button
    @buttonClose = new TriggerMorph()
    @buttonClose.labelString = "close"
    @buttonClose.action = =>
      @destroy()

    @add @buttonClose

    # resizer
    @resizer = new HandleMorph(@, 150, 100, @edge, @edge)

    # update layout
    @fixLayout()
  
  fixLayout: ->
    Morph::trackChanges = false

    # label
    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x
    @label.setPosition new Point(x, y)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @silentSetHeight @label.height() + 50
      @updateRendering()
      @changed()
      @resizer.updateRendering()

    # morphsList
    y = @label.bottom() + 2
    w = @width() - @edge
    w -= @edge
    b = @bottom() - (2 * @edge) - WorldMorph.MorphicPreferences.handleSize
    h = b - y
    @morphsList.setPosition new Point(x, y)
    @morphsList.setExtent new Point(w, h)

    # close button
    x = @morphsList.left()
    y = @morphsList.bottom() + @edge
    h = WorldMorph.MorphicPreferences.handleSize
    w = @morphsList.width() - h - @edge
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
    @fixLayout()
  '''
###
Copyright 2013 Craig Campbell
coffeescript port by Davide Della Casa

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Mousetrap is a simple keyboard shortcut library for Javascript with
no external dependencies

@version 1.3.1
@url craig.is/killing/mice
###

###
mapping of special keycodes to their corresponding keys

everything in this dictionary cannot use keypress events
so it has to be here to map to the correct keycodes for
keyup/keydown events

@type {Object}
###

_MAP =
  8: "backspace"
  9: "tab"
  13: "enter"
  16: "shift"
  17: "ctrl"
  18: "alt"
  20: "capslock"
  27: "esc"
  32: "space"
  33: "pageup"
  34: "pagedown"
  35: "end"
  36: "home"
  37: "left"
  38: "up"
  39: "right"
  40: "down"
  45: "ins"
  46: "del"
  91: "meta"
  93: "meta"
  224: "meta"

###
mapping for special characters so they can support

this dictionary is only used incase you want to bind a
keyup or keydown event to one of these keys

@type {Object}
###
_KEYCODE_MAP =
  106: "*"
  107: "+"
  109: "-"
  110: "."
  111: "/"
  186: ";"
  187: "="
  188: ","
  189: "-"
  190: "."
  191: "/"
  192: "`"
  219: "["
  220: "\\"
  221: "]"
  222: "'"

###
this is a mapping of keys that require shift on a US keypad
back to the non shift equivelents

this is so you can use keyup events with these keys

note that this will only work reliably on US keyboards

@type {Object}
###
_SHIFT_MAP =
  "~": "`"
  "!": "1"
  "@": "2"
  "#": "3"
  $: "4"
  "%": "5"
  "^": "6"
  "&": "7"
  "*": "8"
  "(": "9"
  ")": "0"
  _: "-"
  "+": "="
  ":": ";"
  "\"": "'"
  "<": ","
  ">": "."
  "?": "/"
  "|": "\\"

###
this is a list of special strings you can use to map
to modifier keys when you specify your keyboard shortcuts

@type {Object}
###
_SPECIAL_ALIASES =
  option: "alt"
  command: "meta"
  return: "enter"
  escape: "esc"

###
variable to store the flipped version of _MAP from above
needed to check if we should use keypress or not when no action
is specified

@type {Object|undefined}
###
_REVERSE_MAP = undefined

###
a list of all the callbacks setup via Mousetrap.bind()

@type {Object}
###
_callbacks = {}

###
direct map of string combinations to callbacks used for trigger()

@type {Object}
###
_directMap = {}

###
keeps track of what level each sequence is at since multiple
sequences can start out with the same sequence

@type {Object}
###
_sequenceLevels = {}

###
variable to store the setTimeout call

@type {null|number}
###
_resetTimer = undefined

###
temporary state where we will ignore the next keyup

@type {boolean|string}
###
_ignoreNextKeyup = false

###
are we currently inside of a sequence?
type of action ("keyup" or "keydown" or "keypress") or false

@type {boolean|string}
###
_sequenceType = false

###
loop through the f keys, f1 to f19 and add them to the map
programatically
###
i = 1
while i < 20
  _MAP[111 + i] = "f" + i
  ++i

###
loop through to map numbers on the numeric keypad
###
i = 0
while i <= 9
  _MAP[i + 96] = i
  ++i


###
cross browser add event method

@param {Element|HTMLDocument} object
@param {string} type
@param {Function} callback
@returns void
###
_addEvent = (object, type, callback) ->
  if object.addEventListener
    object.addEventListener type, callback, false
    return
  object.attachEvent "on" + type, callback

###
takes the event and returns the key character

@param {Event} e
@return {string}
###
_characterFromEvent = (e) ->
  
  # for keypress events we should return the character as is
  return String.fromCharCode(e.which)  if e.type is "keypress"
  
  # for non keypress events the special maps are needed
  return _MAP[e.which]  if _MAP[e.which]
  return _KEYCODE_MAP[e.which]  if _KEYCODE_MAP[e.which]
  
  # if it is not in the special map
  String.fromCharCode(e.which).toLowerCase()

###
checks if two arrays are equal

@param {Array} modifiers1
@param {Array} modifiers2
@returns {boolean}
###
_modifiersMatch = (modifiers1, modifiers2) ->
  modifiers1.sort().join(",") is modifiers2.sort().join(",")

###
resets all sequence counters except for the ones passed in

@param {Object} doNotReset
@returns void
###
_resetSequences = (doNotReset, maxLevel) ->
  doNotReset = doNotReset or {}
  activeSequences = false
  key = undefined
  for key of _sequenceLevels
    if doNotReset[key] and _sequenceLevels[key] > maxLevel
      activeSequences = true
      continue
    _sequenceLevels[key] = 0
  _sequenceType = false  unless activeSequences

###
finds all callbacks that match based on the keycode, modifiers,
and action

@param {string} character
@param {Array} modifiers
@param {Event|Object} e
@param {boolean=} remove - should we remove any matches
@param {string=} combination
@returns {Array}
###
_getMatches = (character, modifiers, e, remove, combination) ->
  i = undefined
  callback = undefined
  matches = []
  action = e.type
  
  # if there are no events related to this keycode
  return []  unless _callbacks[character]
  
  # if a modifier key is coming up on its own we should allow it
  modifiers = [character]  if action is "keyup" and _isModifier(character)
  
  # loop through all callbacks for the key that was pressed
  # and see if any of them match
  for i in [0..._callbacks[character].length]
    callback = _callbacks[character][i]
    
    # if this is a sequence but it is not at the right level
    # then move onto the next match
    continue  if callback.seq and _sequenceLevels[callback.seq] isnt callback.level
    
    # if the action we are looking for doesn't match the action we got
    # then we should keep going
    continue  unless action is callback.action
    
    # if this is a keypress event and the meta key and control key
    # are not pressed that means that we need to only look at the
    # character, otherwise check the modifiers as well
    #
    # chrome will not fire a keypress if meta or control is down
    # safari will fire a keypress if meta or meta+shift is down
    # firefox will fire a keypress if meta or control is down
    if (action is "keypress" and not e.metaKey and not e.ctrlKey) or _modifiersMatch(modifiers, callback.modifiers)
      
      # remove is used so if you change your mind and call bind a
      # second time with a new function the first one is overwritten
      _callbacks[character].splice i, 1  if remove and callback.combo is combination
      matches.push callback
  matches

###
takes a key event and figures out what the modifiers are

@param {Event} e
@returns {Array}
###
_eventModifiers = (e) ->
  modifiers = []
  modifiers.push "shift"  if e.shiftKey
  modifiers.push "alt"  if e.altKey
  modifiers.push "ctrl"  if e.ctrlKey
  modifiers.push "meta"  if e.metaKey
  modifiers

###
actually calls the callback function

if your callback function returns false this will use the jquery
convention - prevent default and stop propogation on the event

@param {Function} callback
@param {Event} e
@returns void
###
_fireCallback = (callback, e, combo) ->
  
  # if this event should not happen stop here
  return  if Mousetrap.stopCallback(e, e.target or e.srcElement, combo)
  if callback(e, combo) is false
    e.preventDefault()  if e.preventDefault
    e.stopPropagation()  if e.stopPropagation
    e.returnValue = false
    e.cancelBubble = true

###
handles a character key event

@param {string} character
@param {Event} e
@returns void
###
_handleCharacter = (character, e) ->
  callbacks = _getMatches(character, _eventModifiers(e), e)
  i = undefined
  doNotReset = {}
  maxLevel = 0
  processedSequenceCallback = false
  
  # loop through matching callbacks for this key event
  i = 0
  while i < callbacks.length
    
    # fire for all sequence callbacks
    # this is because if for example you have multiple sequences
    # bound such as "g i" and "g t" they both need to fire the
    # callback for matching g cause otherwise you can only ever
    # match the first one
    if callbacks[i].seq
      processedSequenceCallback = true
      
      # as we loop through keep track of the max
      # any sequence at a lower level will be discarded
      maxLevel = Math.max(maxLevel, callbacks[i].level)
      
      # keep a list of which sequences were matches for later
      doNotReset[callbacks[i].seq] = 1
      _fireCallback callbacks[i].callback, e, callbacks[i].combo
      continue
    
    # if there were no sequence matches but we are still here
    # that means this is a regular match so we should fire that
    _fireCallback callbacks[i].callback, e, callbacks[i].combo  if not processedSequenceCallback and not _sequenceType
    ++i
  
  # if you are inside of a sequence and the key you are pressing
  # is not a modifier key then we should reset all sequences
  # that were not matched by this key event
  _resetSequences doNotReset, maxLevel  if e.type is _sequenceType and not _isModifier(character)

###
handles a keydown event

@param {Event} e
@returns void
###
_handleKey = (e) ->
  
  # normalize e.which for key events
  # @see http://stackoverflow.com/questions/4285627/javascript-keycode-vs-charcode-utter-confusion
  e.which = e.keyCode  if typeof e.which isnt "number"
  character = _characterFromEvent(e)
  
  # no character found then stop
  return  unless character
  if e.type is "keyup" and _ignoreNextKeyup is character
    _ignoreNextKeyup = false
    return
  _handleCharacter character, e

###
determines if the keycode specified is a modifier key or not

@param {string} key
@returns {boolean}
###
_isModifier = (key) ->
  key is "shift" or key is "ctrl" or key is "alt" or key is "meta"

###
called to set a 1 second timeout on the specified sequence

this is so after each key press in the sequence you have 1 second
to press the next key before you have to start over

@returns void
###
_resetSequenceTimer = ->
  clearTimeout _resetTimer
  _resetTimer = setTimeout(_resetSequences, 1000)

###
reverses the map lookup so that we can look for specific keys
to see what can and can't use keypress

@return {Object}
###
_getReverseMap = ->
  unless _REVERSE_MAP
    _REVERSE_MAP = {}
    for key of _MAP
      
      # pull out the numeric keypad from here cause keypress should
      # be able to detect the keys from the character
      continue  if key > 95 and key < 112
      _REVERSE_MAP[_MAP[key]] = key  if _MAP.hasOwnProperty(key)
  _REVERSE_MAP

###
picks the best action based on the key combination

@param {string} key - character for key
@param {Array} modifiers
@param {string=} action passed in
###
_pickBestAction = (key, modifiers, action) ->
  
  # if no action was picked in we should try to pick the one
  # that we think would work best for this key
  action = (if _getReverseMap()[key] then "keydown" else "keypress")  unless action
  
  # modifier keys don't work as expected with keypress,
  # switch to keydown
  action = "keydown"  if action is "keypress" and modifiers.length
  action

###
binds a key sequence to an event

@param {string} combo - combo specified in bind call
@param {Array} keys
@param {Function} callback
@param {string=} action
@returns void
###
_bindSequence = (combo, keys, callback, action) ->
  
  # start off by adding a sequence level record for this combination
  # and setting the level to 0
  _sequenceLevels[combo] = 0
  
  # if there is no action pick the best one for the first key
  # in the sequence
  action = _pickBestAction(keys[0], [])  unless action
  
  ###
  callback to increase the sequence level for this sequence and reset
  all other sequences that were active
  
  @param {Event} e
  @returns void
  ###
  _increaseSequence = ->
    _sequenceType = action
    ++_sequenceLevels[combo]
    _resetSequenceTimer()

  
  ###
  wraps the specified callback inside of another function in order
  to reset all sequence counters as soon as this sequence is done
  
  @param {Event} e
  @returns void
  ###
  _callbackAndReset = (e) ->
    _fireCallback callback, e, combo
    
    # we should ignore the next key up if the action is key down
    # or keypress.  this is so if you finish a sequence and
    # release the key the final key will not trigger a keyup
    _ignoreNextKeyup = _characterFromEvent(e)  if action isnt "keyup"
    
    # weird race condition if a sequence ends with the key
    # another sequence begins with
    setTimeout _resetSequences, 10

  i = undefined
  
  # loop through keys one at a time and bind the appropriate callback
  # function.  for any key leading up to the final one it should
  # increase the sequence. after the final, it should reset all sequences
  i = 0
  while i < keys.length
    _bindSingle keys[i], (if i < keys.length - 1 then _increaseSequence else _callbackAndReset), action, combo, i
    ++i

###
binds a single keyboard combination

@param {string} combination
@param {Function} callback
@param {string=} action
@param {string=} sequenceName - name of sequence if part of sequence
@param {number=} level - what part of the sequence the command is
@returns void
###
_bindSingle = (combination, callback, action, sequenceName, level) ->
  
  # store a direct mapped reference for use with Mousetrap.trigger
  _directMap[combination + ":" + action] = callback
  
  # make sure multiple spaces in a row become a single space
  combination = combination.replace(/\s+/g, " ")
  sequence = combination.split(" ")
  i = undefined
  key = undefined
  keys = undefined
  modifiers = []
  
  # if this pattern is a sequence of keys then run through this method
  # to reprocess each pattern one key at a time
  if sequence.length > 1
    _bindSequence combination, sequence, callback, action
    return
  
  # take the keys from this pattern and figure out what the actual
  # pattern is all about
  keys = (if combination is "+" then ["+"] else combination.split("+"))
  i = 0
  while i < keys.length
    key = keys[i]
    
    # normalize key names
    key = _SPECIAL_ALIASES[key]  if _SPECIAL_ALIASES[key]
    
    # if this is not a keypress event then we should
    # be smart about using shift keys
    # this will only work for US keyboards however
    if action and action isnt "keypress" and _SHIFT_MAP[key]
      key = _SHIFT_MAP[key]
      modifiers.push "shift"
    
    # if this key is a modifier then add it to the list of modifiers
    modifiers.push key  if _isModifier(key)
    ++i
  
  # depending on what the key combination is
  # we will try to pick the best event for it
  action = _pickBestAction(key, modifiers, action)
  
  # make sure to initialize array if this is the first time
  # a callback is added for this key
  _callbacks[key] = []  unless _callbacks[key]
  
  # remove an existing match if there is one
  _getMatches key, modifiers,
    type: action
  , not sequenceName, combination
  
  # add this call back to the array
  # if it is a sequence put it at the beginning
  # if not put it at the end
  #
  # this is important because the way these are processed expects
  # the sequence ones to come first
  _callbacks[key][(if sequenceName then "unshift" else "push")]
    callback: callback
    modifiers: modifiers
    action: action
    seq: sequenceName
    level: level
    combo: combination


###
binds multiple combinations to the same callback

@param {Array} combinations
@param {Function} callback
@param {string|undefined} action
@returns void
###
_bindMultiple = (combinations, callback, action) ->
  i = 0

  while i < combinations.length
    _bindSingle combinations[i], callback, action
    ++i


# start!
_addEvent document, "keypress", _handleKey
_addEvent document, "keydown", _handleKey
_addEvent document, "keyup", _handleKey
Mousetrap =
  
  ###
  binds an event to mousetrap
  
  can be a single key, a combination of keys separated with +,
  an array of keys, or a sequence of keys separated by spaces
  
  be sure to list the modifier keys first to make sure that the
  correct key ends up getting bound (the last key in the pattern)
  
  @param {string|Array} keys
  @param {Function} callback
  @param {string=} action - 'keypress', 'keydown', or 'keyup'
  @returns void
  ###
  bind: (keys, callback, action) ->
    keys = (if keys instanceof Array then keys else [keys])
    _bindMultiple keys, callback, action
    this

  
  ###
  unbinds an event to mousetrap
  
  the unbinding sets the callback function of the specified key combo
  to an empty function and deletes the corresponding key in the
  _directMap dict.
  
  TODO: actually remove this from the _callbacks dictionary instead
  of binding an empty function
  
  the keycombo+action has to be exactly the same as
  it was defined in the bind method
  
  @param {string|Array} keys
  @param {string} action
  @returns void
  ###
  unbind: (keys, action) ->
    Mousetrap.bind keys, (->
    ), action

  
  ###
  triggers an event that has already been bound
  
  @param {string} keys
  @param {string=} action
  @returns void
  ###
  trigger: (keys, action) ->
    _directMap[keys + ":" + action] {}, keys  if _directMap[keys + ":" + action]
    this

  
  ###
  resets the library back to its initial state.  this is useful
  if you want to clear out the current keyboard shortcuts and bind
  new ones - for example if you switch to another page
  
  @returns void
  ###
  reset: ->
    _callbacks = {}
    _directMap = {}
    this

  
  ###
  should we stop this event before firing off callbacks
  
  @param {Event} e
  @param {Element} element
  @return {boolean}
  ###
  stopCallback: (e, element) ->
    
    # if the element has the class "mousetrap" then no need to stop
    return false  if (" " + element.className + " ").indexOf(" mousetrap ") > -1
    
    # stop for input, select, and textarea
    element.tagName is "INPUT" or element.tagName is "SELECT" or element.tagName is "TEXTAREA" or (element.contentEditable and element.contentEditable is "true")

window.Mousetrap = Mousetrap

# SpeechBubbleMorph ///////////////////////////////////////////////////

#
#	I am a comic-style speech bubble that can display either a string,
#	a Morph, a Canvas or a toString() representation of anything else.
#	If I am invoked using popUp() I behave like a tool tip.
#

class SpeechBubbleMorph extends BoxMorph

  isPointingRight: true # orientation of text
  contents: null
  padding: null # additional vertical pixels
  isThought: null # draw "think" bubble
  isClickable: false

  constructor: (
    @contents="",
    color,
    edge,
    border,
    borderColor,
    @padding = 0,
    @isThought = false) ->
      super edge or 6, border or ((if (border is 0) then 0 else 1)), borderColor or new Color(140, 140, 140)
      @color = color or new Color(230, 230, 230)
      @updateRendering()
  
  
  # SpeechBubbleMorph invoking:
  popUp: (world, pos, isClickable) ->
    @updateRendering()
    @setPosition pos.subtract(new Point(0, @height()))
    @addShadow new Point(2, 2), 80
    @keepWithin world
    world.add @
    @changed()
    world.hand.destroyTemporaries()
    world.hand.temporaries.push @
    if isClickable
      @mouseEnter = ->
        @destroy()
    else
      @isClickable = false
    
  
  
  # SpeechBubbleMorph drawing:
  updateRendering: ->
    # re-build my contents
    @contentsMorph.destroy()  if @contentsMorph
    if @contents instanceof Morph
      @contentsMorph = @contents
    else if isString(@contents)
      @contentsMorph = new TextMorph(
        @contents,
        WorldMorph.MorphicPreferences.bubbleHelpFontSize,
        null,
        false,
        true,
        "center")
    else if @contents instanceof HTMLCanvasElement
      @contentsMorph = new Morph()
      @contentsMorph.silentSetWidth @contents.width
      @contentsMorph.silentSetHeight @contents.height
      @contentsMorph.image = @contents
    else
      @contentsMorph = new TextMorph(
        @contents.toString(),
        WorldMorph.MorphicPreferences.bubbleHelpFontSize,
        null,
        false,
        true,
        "center")
    @add @contentsMorph
    #
    # adjust my layout
    @silentSetWidth @contentsMorph.width() + ((if @padding then @padding * 2 else @edge * 2))
    @silentSetHeight @contentsMorph.height() + @edge + @border * 2 + @padding * 2 + 2
    #
    # draw my outline
    super()
    #
    # position my contents
    @contentsMorph.setPosition @position().add(
      new Point(@padding or @edge, @border + @padding + 1))
  
  outlinePath: (context, radius, inset) ->
    circle = (x, y, r) ->
      context.moveTo x + r, y
      context.arc x, y, r, radians(0), radians(360)
    offset = radius + inset
    w = @width()
    h = @height()
    #
    # top left:
    context.arc offset, offset, radius, radians(-180), radians(-90), false
    #
    # top right:
    context.arc w - offset, offset, radius, radians(-90), radians(-0), false
    #
    # bottom right:
    context.arc w - offset, h - offset - radius, radius, radians(0), radians(90), false
    unless @isThought # draw speech bubble hook
      if @isPointingRight
        context.lineTo offset + radius, h - offset
        context.lineTo radius / 2 + inset, h - inset
      else # pointing left
        context.lineTo w - (radius / 2 + inset), h - inset
        context.lineTo w - (offset + radius), h - offset
    #
    # bottom left:
    context.arc offset, h - offset - radius, radius, radians(90), radians(180), false
    if @isThought
      #
      # close large bubble:
      context.lineTo inset, offset
      #
      # draw thought bubbles:
      if @isPointingRight
        #
        # tip bubble:
        rad = radius / 4
        circle rad + inset, h - rad - inset, rad
        #
        # middle bubble:
        rad = radius / 3.2
        circle rad * 2 + inset, h - rad - inset * 2, rad
        #
        # top bubble:
        rad = radius / 2.8
        circle rad * 3 + inset * 2, h - rad - inset * 4, rad
      else # pointing left
        # tip bubble:
        rad = radius / 4
        circle w - (rad + inset), h - rad - inset, rad
        #
        # middle bubble:
        rad = radius / 3.2
        circle w - (rad * 2 + inset), h - rad - inset * 2, rad
        #
        # top bubble:
        rad = radius / 2.8
        circle w - (rad * 3 + inset * 2), h - rad - inset * 4, rad

  # SpeechBubbleMorph shadow
  #
  #    only take the 'plain' image, so the box rounding and the
  #    shadow doesn't become conflicted by embedded scrolling panes
  #
  shadowImage: (off_, color) ->
    
    # fallback for Windows Chrome-Shadow bug
    fb = undefined
    img = undefined
    outline = undefined
    sha = undefined
    ctx = undefined
    offset = off_ or new Point(7, 7)
    clr = color or new Color(0, 0, 0)
    fb = @extent()
    img = @image
    outline = newCanvas(fb)
    ctx = outline.getContext("2d")
    ctx.drawImage img, 0, 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, -offset.x, -offset.y
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.drawImage outline, 0, 0
    ctx.globalCompositeOperation = "source-atop"
    ctx.fillStyle = clr.toString()
    ctx.fillRect 0, 0, fb.x, fb.y
    sha

  shadowImageBlurred: (off_, color) ->
    fb = undefined
    img = undefined
    sha = undefined
    ctx = undefined
    offset = off_ or new Point(7, 7)
    blur = @shadowBlur
    clr = color or new Color(0, 0, 0)
    fb = @extent().add(blur * 2)
    img = @image
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.shadowOffsetX = offset.x
    ctx.shadowOffsetY = offset.y
    ctx.shadowBlur = blur
    ctx.shadowColor = clr.toString()
    ctx.drawImage img, blur - offset.x, blur - offset.y
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    ctx.shadowBlur = 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, blur - offset.x, blur - offset.y
    sha

  # SpeechBubbleMorph resizing
  fixLayout: ->
    @removeShadow()
    @updateRendering()
    @addShadow new Point(2, 2), 80

  @coffeeScriptSourceOfThisClass: '''
# SpeechBubbleMorph ///////////////////////////////////////////////////

#
#	I am a comic-style speech bubble that can display either a string,
#	a Morph, a Canvas or a toString() representation of anything else.
#	If I am invoked using popUp() I behave like a tool tip.
#

class SpeechBubbleMorph extends BoxMorph

  isPointingRight: true # orientation of text
  contents: null
  padding: null # additional vertical pixels
  isThought: null # draw "think" bubble
  isClickable: false

  constructor: (
    @contents="",
    color,
    edge,
    border,
    borderColor,
    @padding = 0,
    @isThought = false) ->
      super edge or 6, border or ((if (border is 0) then 0 else 1)), borderColor or new Color(140, 140, 140)
      @color = color or new Color(230, 230, 230)
      @updateRendering()
  
  
  # SpeechBubbleMorph invoking:
  popUp: (world, pos, isClickable) ->
    @updateRendering()
    @setPosition pos.subtract(new Point(0, @height()))
    @addShadow new Point(2, 2), 80
    @keepWithin world
    world.add @
    @changed()
    world.hand.destroyTemporaries()
    world.hand.temporaries.push @
    if isClickable
      @mouseEnter = ->
        @destroy()
    else
      @isClickable = false
    
  
  
  # SpeechBubbleMorph drawing:
  updateRendering: ->
    # re-build my contents
    @contentsMorph.destroy()  if @contentsMorph
    if @contents instanceof Morph
      @contentsMorph = @contents
    else if isString(@contents)
      @contentsMorph = new TextMorph(
        @contents,
        WorldMorph.MorphicPreferences.bubbleHelpFontSize,
        null,
        false,
        true,
        "center")
    else if @contents instanceof HTMLCanvasElement
      @contentsMorph = new Morph()
      @contentsMorph.silentSetWidth @contents.width
      @contentsMorph.silentSetHeight @contents.height
      @contentsMorph.image = @contents
    else
      @contentsMorph = new TextMorph(
        @contents.toString(),
        WorldMorph.MorphicPreferences.bubbleHelpFontSize,
        null,
        false,
        true,
        "center")
    @add @contentsMorph
    #
    # adjust my layout
    @silentSetWidth @contentsMorph.width() + ((if @padding then @padding * 2 else @edge * 2))
    @silentSetHeight @contentsMorph.height() + @edge + @border * 2 + @padding * 2 + 2
    #
    # draw my outline
    super()
    #
    # position my contents
    @contentsMorph.setPosition @position().add(
      new Point(@padding or @edge, @border + @padding + 1))
  
  outlinePath: (context, radius, inset) ->
    circle = (x, y, r) ->
      context.moveTo x + r, y
      context.arc x, y, r, radians(0), radians(360)
    offset = radius + inset
    w = @width()
    h = @height()
    #
    # top left:
    context.arc offset, offset, radius, radians(-180), radians(-90), false
    #
    # top right:
    context.arc w - offset, offset, radius, radians(-90), radians(-0), false
    #
    # bottom right:
    context.arc w - offset, h - offset - radius, radius, radians(0), radians(90), false
    unless @isThought # draw speech bubble hook
      if @isPointingRight
        context.lineTo offset + radius, h - offset
        context.lineTo radius / 2 + inset, h - inset
      else # pointing left
        context.lineTo w - (radius / 2 + inset), h - inset
        context.lineTo w - (offset + radius), h - offset
    #
    # bottom left:
    context.arc offset, h - offset - radius, radius, radians(90), radians(180), false
    if @isThought
      #
      # close large bubble:
      context.lineTo inset, offset
      #
      # draw thought bubbles:
      if @isPointingRight
        #
        # tip bubble:
        rad = radius / 4
        circle rad + inset, h - rad - inset, rad
        #
        # middle bubble:
        rad = radius / 3.2
        circle rad * 2 + inset, h - rad - inset * 2, rad
        #
        # top bubble:
        rad = radius / 2.8
        circle rad * 3 + inset * 2, h - rad - inset * 4, rad
      else # pointing left
        # tip bubble:
        rad = radius / 4
        circle w - (rad + inset), h - rad - inset, rad
        #
        # middle bubble:
        rad = radius / 3.2
        circle w - (rad * 2 + inset), h - rad - inset * 2, rad
        #
        # top bubble:
        rad = radius / 2.8
        circle w - (rad * 3 + inset * 2), h - rad - inset * 4, rad

  # SpeechBubbleMorph shadow
  #
  #    only take the 'plain' image, so the box rounding and the
  #    shadow doesn't become conflicted by embedded scrolling panes
  #
  shadowImage: (off_, color) ->
    
    # fallback for Windows Chrome-Shadow bug
    fb = undefined
    img = undefined
    outline = undefined
    sha = undefined
    ctx = undefined
    offset = off_ or new Point(7, 7)
    clr = color or new Color(0, 0, 0)
    fb = @extent()
    img = @image
    outline = newCanvas(fb)
    ctx = outline.getContext("2d")
    ctx.drawImage img, 0, 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, -offset.x, -offset.y
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.drawImage outline, 0, 0
    ctx.globalCompositeOperation = "source-atop"
    ctx.fillStyle = clr.toString()
    ctx.fillRect 0, 0, fb.x, fb.y
    sha

  shadowImageBlurred: (off_, color) ->
    fb = undefined
    img = undefined
    sha = undefined
    ctx = undefined
    offset = off_ or new Point(7, 7)
    blur = @shadowBlur
    clr = color or new Color(0, 0, 0)
    fb = @extent().add(blur * 2)
    img = @image
    sha = newCanvas(fb)
    ctx = sha.getContext("2d")
    ctx.shadowOffsetX = offset.x
    ctx.shadowOffsetY = offset.y
    ctx.shadowBlur = blur
    ctx.shadowColor = clr.toString()
    ctx.drawImage img, blur - offset.x, blur - offset.y
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    ctx.shadowBlur = 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, blur - offset.x, blur - offset.y
    sha

  # SpeechBubbleMorph resizing
  fixLayout: ->
    @removeShadow()
    @updateRendering()
    @addShadow new Point(2, 2), 80
  '''
# HandMorph ///////////////////////////////////////////////////////////

# The mouse cursor. Note that it's not a child of the WorldMorph, this Morph
# is never added to any other morph. [TODO] Find out why and write explanation.

class HandMorph extends Morph

  world: null
  mouseButton: null
  mouseDownMorph: null
  morphToGrab: null
  grabOrigin: null
  mouseOverList: null
  temporaries: null
  touchHoldTimeout: null

  constructor: (@world) ->
    @mouseOverList = []
    @temporaries = []
    super()
    @bounds = new Rectangle()
  
  changed: ->
    if @world isnt null
      b = @boundsIncludingChildren()
      @world.broken.push @boundsIncludingChildren().spread()  unless b.extent().eq(new Point())
  
  
  # HandMorph navigation:
  morphAtPointer: ->
    morphs = @world.allChildren().slice(0).reverse()
    result = null
    morphs.forEach (m) =>
      result = m  if m.visibleBounds().containsPoint(@bounds.origin) and
        result is null and m.isVisible and (m.noticesTransparentClick or
        (not m.isTransparentAt(@bounds.origin))) and (m not instanceof ShadowMorph)
    #
    return result  if result isnt null
    @world
  
  #
  #    alternative -  more elegant and possibly more
  #	performant - solution for morphAtPointer.
  #	Has some issues, commented out for now
  #
  #HandMorph.prototype.morphAtPointer = function () {
  #	var myself = this;
  #	return this.world.topMorphSuchThat(function (m) {
  #		return m.visibleBounds().containsPoint(myself.bounds.origin) &&
  #			m.isVisible &&
  #			(m.noticesTransparentClick ||
  #				(! m.isTransparentAt(myself.bounds.origin))) &&
  #			(! (m instanceof ShadowMorph));
  #	});
  #};
  #
  allMorphsAtPointer: ->
    morphs = @world.allChildren()
    morphs.filter (m) =>
      m.isVisible and m.visibleBounds().containsPoint(@bounds.origin)
  
  
  
  # HandMorph dragging and dropping:
  #
  #	drag 'n' drop events, method(arg) -> receiver:
  #
  #		prepareToBeGrabbed(handMorph) -> grabTarget
  #		reactToGrabOf(grabbedMorph) -> oldParent
  #		wantsDropOf(morphToDrop) ->  newParent
  #		justDropped(handMorph) -> droppedMorph
  #		reactToDropOf(droppedMorph, handMorph) -> newParent
  #
  dropTargetFor: (aMorph) ->
    target = @morphAtPointer()
    target = target.parent  until target.wantsDropOf(aMorph)
    target
  
  grab: (aMorph) ->
    oldParent = aMorph.parent
    return null  if aMorph instanceof WorldMorph
    if !@children.length
      @world.stopEditing()
      @grabOrigin = aMorph.situation()
      aMorph.addShadow()
      aMorph.prepareToBeGrabbed @  if aMorph.prepareToBeGrabbed
      @add aMorph
      @changed()
      oldParent.reactToGrabOf aMorph  if oldParent and oldParent.reactToGrabOf
  
  drop: ->
    if @children.length
      morphToDrop = @children[0]
      target = @dropTargetFor(morphToDrop)
      @changed()
      target.add morphToDrop
      morphToDrop.changed()
      morphToDrop.removeShadow()
      @children = []
      @setExtent new Point()
      morphToDrop.justDropped @  if morphToDrop.justDropped
      target.reactToDropOf morphToDrop, @  if target.reactToDropOf
      @dragOrigin = null
  
  # HandMorph event dispatching:
  #
  #    mouse events:
  #
  #		mouseDownLeft
  #		mouseDownRight
  #		mouseClickLeft
  #		mouseClickRight
  #   mouseDoubleClick
  #		mouseEnter
  #		mouseLeave
  #		mouseEnterDragging
  #		mouseLeaveDragging
  #		mouseMove
  #		mouseScroll
  #
  processMouseDown: (button, ctrlKey) ->
    @world.systemTestsRecorderAndPlayer.addMouseDownEvent(button, ctrlKey)

    @destroyTemporaries()
    @morphToGrab = null
    if @children.length
      @drop()
      @mouseButton = null
    else
      morph = @morphAtPointer()
      if @world.activeMenu
        unless contains(morph.allParents(), @world.activeMenu)
          @world.activeMenu.destroy()
        else
          clearInterval @touchHoldTimeout
      if @world.activeHandle
        if morph isnt @world.activeHandle
          @world.activeHandle.destroy()    
      if @world.caret
        # there is a caret on the screen
        # depending on what the user is clicking on,
        # we might need to close an ongoing edit
        # operation, which means deleting the
        # caret and un-selecting anything that was selected.
        # Note that we don't want to interrupt an edit
        # if the user is invoking/clicking on anything
        # inside a menu, because the invoked function
        # might do something with the selection
        # (for example doIt takes the current selection).
        if morph isnt @world.caret.target
          # user clicked on something other than what the
          # caret is attached to
          unless contains(morph.allParents(), @world.activeMenu)
            # only dismiss editing if the morph the user
            # clicked on is not part of a menu.
            @world.stopEditing()  
      @morphToGrab = morph.rootForGrab()  unless morph.mouseMove
      if button is 2 or ctrlKey
        @mouseButton = "right"
        actualClick = "mouseDownRight"
        expectedClick = "mouseClickRight"
      else
        @mouseButton = "left"
        actualClick = "mouseDownLeft"
        expectedClick = "mouseClickLeft"
      @mouseDownMorph = morph
      @mouseDownMorph = @mouseDownMorph.parent  until @mouseDownMorph[expectedClick]
      morph = morph.parent  until morph[actualClick]
      morph[actualClick] @bounds.origin
  
  processTouchStart: (event) ->
    WorldMorph.MorphicPreferences.isTouchDevice = true
    clearInterval @touchHoldTimeout
    if event.touches.length is 1
      # simulate mouseRightClick
      @touchHoldTimeout = setInterval(=>
        @processMouseDown button: 2
        @processMouseUp button: 2
        event.preventDefault()
        clearInterval @touchHoldTimeout
      , 400)
      @processMouseMove event.touches[0] # update my position
      @processMouseDown button: 0
      event.preventDefault()
  
  processTouchMove: (event) ->
    if event.touches.length is 1
      touch = event.touches[0]
      @processMouseMove touch
      clearInterval @touchHoldTimeout
  
  processTouchEnd: (event) ->
    WorldMorph.MorphicPreferences.isTouchDevice = true
    clearInterval @touchHoldTimeout
    @processMouseUp button: 0
  
  processMouseUp: ->
    @world.systemTestsRecorderAndPlayer.addMouseUpEvent()

    morph = @morphAtPointer()
    @destroyTemporaries()
    if @children.length
      @drop()
    else
      if @mouseButton is "left"
        expectedClick = "mouseClickLeft"
      else
        expectedClick = "mouseClickRight"
        if @mouseButton
          context = morph
          contextMenu = context.contextMenu()
          while (not contextMenu) and context.parent
            context = context.parent
            contextMenu = context.contextMenu()
          contextMenu.popUpAtHand @world  if contextMenu
      morph = morph.parent  until morph[expectedClick]
      morph[expectedClick] @bounds.origin
    @mouseButton = null

  processDoubleClick: ->
    morph = @morphAtPointer()
    @destroyTemporaries()
    if @children.length isnt 0
      @drop()
    else
      morph = morph.parent  while morph and not morph.mouseDoubleClick
      morph.mouseDoubleClick @bounds.origin  if morph
    @mouseButton = null
  
  processMouseScroll: (event) ->
    morph = @morphAtPointer()
    morph = morph.parent  while morph and not morph.mouseScroll

    morph.mouseScroll (event.detail / -3) or ((if Object.prototype.hasOwnProperty.call(event,'wheelDeltaY') then event.wheelDeltaY / 120 else event.wheelDelta / 120)), event.wheelDeltaX / 120 or 0  if morph
  
  
  #
  #	drop event:
  #
  #        droppedImage
  #        droppedSVG
  #        droppedAudio
  #        droppedText
  #
  processDrop: (event) ->
    #
    #    find out whether an external image or audio file was dropped
    #    onto the world canvas, turn it into an offscreen canvas or audio
    #    element and dispatch the
    #    
    #        droppedImage(canvas, name)
    #        droppedSVG(image, name)
    #        droppedAudio(audio, name)
    #    
    #    events to interested Morphs at the mouse pointer
    #    if none of the above content types can be determined, the file contents
    #    is dispatched as an ArrayBuffer to interested Morphs:
    #
    #    ```droppedBinary(anArrayBuffer, name)```

    files = (if event instanceof FileList then event else (event.target.files || event.dataTransfer.files))
    url = (if event.dataTransfer then event.dataTransfer.getData("URL") else null)
    txt = (if event.dataTransfer then event.dataTransfer.getData("Text/HTML") else null)
    targetDrop = @morphAtPointer()
    img = new Image()

    readSVG = (aFile) ->
      pic = new Image()
      frd = new FileReader()
      target = target.parent  until target.droppedSVG
      pic.onload = ->
        target.droppedSVG pic, aFile.name
      frd = new FileReader()
      frd.onloadend = (e) ->
        pic.src = e.target.result
      frd.readAsDataURL aFile

    readImage = (aFile) ->
      pic = new Image()
      frd = new FileReader()
      targetDrop = targetDrop.parent  until targetDrop.droppedImage
      pic.onload = ->
        canvas = newCanvas(new Point(pic.width, pic.height))
        canvas.getContext("2d").drawImage pic, 0, 0
        targetDrop.droppedImage canvas, aFile.name
      #
      frd = new FileReader()
      frd.onloadend = (e) ->
        pic.src = e.target.result
      #
      frd.readAsDataURL aFile
    #
    readAudio = (aFile) ->
      snd = new Audio()
      frd = new FileReader()
      targetDrop = targetDrop.parent  until targetDrop.droppedAudio
      frd.onloadend = (e) ->
        snd.src = e.target.result
        targetDrop.droppedAudio snd, aFile.name
      frd.readAsDataURL aFile
    
    readText = (aFile) ->
      frd = new FileReader()
      targetDrop = targetDrop.parent  until targetDrop.droppedText
      frd.onloadend = (e) ->
        targetDrop.droppedText e.target.result, aFile.name
      frd.readAsText aFile


    readBinary = (aFile) ->
      frd = new FileReader()
      targetDrop = targetDrop.parent  until targetDrop.droppedBinary
      frd.onloadend = (e) ->
        targetDrop.droppedBinary e.target.result, aFile.name
      frd.readAsArrayBuffer aFile

    parseImgURL = (html) ->
      url = ""
      start = html.indexOf("<img src=\"")
      return null  if start is -1
      start += 10
      for i in [start...html.length]
        c = html[i]
        return url  if c is "\""
        url = url.concat(c)
      null
    
    if files.length
      for file in files
        if file.type.indexOf("svg") != -1 && !WorldMorph.MorphicPreferences.rasterizeSVGs
          readSVG file
        else if file.type.indexOf("image") is 0
          readImage file
        else if file.type.indexOf("audio") is 0
          readAudio file
        else if file.type.indexOf("text") is 0
          readText file
        else
          readBinary file
    else if url
      if contains(["gif", "png", "jpg", "jpeg", "bmp"], url.slice(url.lastIndexOf(".") + 1).toLowerCase())
        target = target.parent  until target.droppedImage
        img = new Image()
        img.onload = ->
          canvas = newCanvas(new Point(img.width, img.height))
          canvas.getContext("2d").drawImage img, 0, 0
          target.droppedImage canvas
        img.src = url
    else if txt
      targetDrop = targetDrop.parent  until targetDrop.droppedImage
      img = new Image()
      img.onload = ->
        canvas = newCanvas(new Point(img.width, img.height))
        canvas.getContext("2d").drawImage img, 0, 0
        targetDrop.droppedImage canvas
      src = parseImgURL(txt)
      img.src = src  if src
  
  
  # HandMorph tools
  destroyTemporaries: ->
    #
    #	temporaries are just an array of morphs which will be deleted upon
    #	the next mouse click, or whenever another temporary Morph decides
    #	that it needs to remove them. The primary purpose of temporaries is
    #	to display tools tips of speech bubble help.
    #
    @temporaries.forEach (morph) =>
      unless morph.isClickable and morph.bounds.containsPoint(@position())
        morph.destroy()
        @temporaries.splice @temporaries.indexOf(morph), 1
  
  
  # HandMorph dragging optimization
  moveBy: (delta) ->
    Morph::trackChanges = false
    super delta
    Morph::trackChanges = true
    @fullChanged()

  processMouseMove: (pageX, pageY) ->
    @world.systemTestsRecorderAndPlayer.addMouseMoveEvent(pageX, pageY)
    
    #startProcessMouseMove = new Date().getTime()
    posInDocument = getDocumentPositionOf(@world.worldCanvas)
    pos = new Point(pageX - posInDocument.x, pageY - posInDocument.y)
    @setPosition pos
    #
    # determine the new mouse-over-list:
    # mouseOverNew = this.allMorphsAtPointer();
    mouseOverNew = @morphAtPointer().allParents()
    if (!@children.length) and (@mouseButton is "left")
      topMorph = @morphAtPointer()
      morph = topMorph.rootForGrab()
      topMorph.mouseMove pos  if topMorph.mouseMove
      #
      # if a morph is marked for grabbing, just grab it
      if @morphToGrab
        if @morphToGrab.isDraggable
          morph = @morphToGrab
          @grab morph
        else if @morphToGrab.isTemplate
          morph = @morphToGrab.fullCopy()
          morph.isTemplate = false
          morph.isDraggable = true
          @grab morph
          @grabOrigin = @morphToGrab.situation()
        #
        # if the mouse has left its boundsIncludingChildren, center it
        if morph
          fb = morph.boundsIncludingChildren()
          unless fb.containsPoint(pos)
            @bounds.origin = fb.center()
            @grab morph
            @setPosition pos
    #endProcessMouseMove = new Date().getTime()
    #timeProcessMouseMove = endProcessMouseMove - startProcessMouseMove;
    #console.log('Execution time ProcessMouseMove: ' + timeProcessMouseMove);
    
    #
    #	original, more cautious code for grabbing Morphs,
    #	retained in case of needing to fall back:
    #
    #		if (morph === this.morphToGrab) {
    #			if (morph.isDraggable) {
    #				this.grab(morph);
    #			} else if (morph.isTemplate) {
    #				morph = morph.fullCopy();
    #				morph.isTemplate = false;
    #				morph.isDraggable = true;
    #				this.grab(morph);
    #			}
    #		}
    #
    @mouseOverList.forEach (old) =>
      unless contains(mouseOverNew, old)
        old.mouseLeave()  if old.mouseLeave
        old.mouseLeaveDragging()  if old.mouseLeaveDragging and @mouseButton
    #
    mouseOverNew.forEach (newMorph) =>
      unless contains(@mouseOverList, newMorph)
        newMorph.mouseEnter()  if newMorph.mouseEnter
        newMorph.mouseEnterDragging()  if newMorph.mouseEnterDragging and @mouseButton
      #
      # autoScrolling support:
      if @children.length
          if newMorph instanceof ScrollFrameMorph
              if !newMorph.bounds.insetBy(
                WorldMorph.MorphicPreferences.scrollBarSize * 3
                ).containsPoint(@bounds.origin)
                  newMorph.startAutoScrolling();
    #
    @mouseOverList = mouseOverNew

  @coffeeScriptSourceOfThisClass: '''
# HandMorph ///////////////////////////////////////////////////////////

# The mouse cursor. Note that it's not a child of the WorldMorph, this Morph
# is never added to any other morph. [TODO] Find out why and write explanation.

class HandMorph extends Morph

  world: null
  mouseButton: null
  mouseDownMorph: null
  morphToGrab: null
  grabOrigin: null
  mouseOverList: null
  temporaries: null
  touchHoldTimeout: null

  constructor: (@world) ->
    @mouseOverList = []
    @temporaries = []
    super()
    @bounds = new Rectangle()
  
  changed: ->
    if @world isnt null
      b = @boundsIncludingChildren()
      @world.broken.push @boundsIncludingChildren().spread()  unless b.extent().eq(new Point())
  
  
  # HandMorph navigation:
  morphAtPointer: ->
    morphs = @world.allChildren().slice(0).reverse()
    result = null
    morphs.forEach (m) =>
      result = m  if m.visibleBounds().containsPoint(@bounds.origin) and
        result is null and m.isVisible and (m.noticesTransparentClick or
        (not m.isTransparentAt(@bounds.origin))) and (m not instanceof ShadowMorph)
    #
    return result  if result isnt null
    @world
  
  #
  #    alternative -  more elegant and possibly more
  #	performant - solution for morphAtPointer.
  #	Has some issues, commented out for now
  #
  #HandMorph.prototype.morphAtPointer = function () {
  #	var myself = this;
  #	return this.world.topMorphSuchThat(function (m) {
  #		return m.visibleBounds().containsPoint(myself.bounds.origin) &&
  #			m.isVisible &&
  #			(m.noticesTransparentClick ||
  #				(! m.isTransparentAt(myself.bounds.origin))) &&
  #			(! (m instanceof ShadowMorph));
  #	});
  #};
  #
  allMorphsAtPointer: ->
    morphs = @world.allChildren()
    morphs.filter (m) =>
      m.isVisible and m.visibleBounds().containsPoint(@bounds.origin)
  
  
  
  # HandMorph dragging and dropping:
  #
  #	drag 'n' drop events, method(arg) -> receiver:
  #
  #		prepareToBeGrabbed(handMorph) -> grabTarget
  #		reactToGrabOf(grabbedMorph) -> oldParent
  #		wantsDropOf(morphToDrop) ->  newParent
  #		justDropped(handMorph) -> droppedMorph
  #		reactToDropOf(droppedMorph, handMorph) -> newParent
  #
  dropTargetFor: (aMorph) ->
    target = @morphAtPointer()
    target = target.parent  until target.wantsDropOf(aMorph)
    target
  
  grab: (aMorph) ->
    oldParent = aMorph.parent
    return null  if aMorph instanceof WorldMorph
    if !@children.length
      @world.stopEditing()
      @grabOrigin = aMorph.situation()
      aMorph.addShadow()
      aMorph.prepareToBeGrabbed @  if aMorph.prepareToBeGrabbed
      @add aMorph
      @changed()
      oldParent.reactToGrabOf aMorph  if oldParent and oldParent.reactToGrabOf
  
  drop: ->
    if @children.length
      morphToDrop = @children[0]
      target = @dropTargetFor(morphToDrop)
      @changed()
      target.add morphToDrop
      morphToDrop.changed()
      morphToDrop.removeShadow()
      @children = []
      @setExtent new Point()
      morphToDrop.justDropped @  if morphToDrop.justDropped
      target.reactToDropOf morphToDrop, @  if target.reactToDropOf
      @dragOrigin = null
  
  # HandMorph event dispatching:
  #
  #    mouse events:
  #
  #		mouseDownLeft
  #		mouseDownRight
  #		mouseClickLeft
  #		mouseClickRight
  #   mouseDoubleClick
  #		mouseEnter
  #		mouseLeave
  #		mouseEnterDragging
  #		mouseLeaveDragging
  #		mouseMove
  #		mouseScroll
  #
  processMouseDown: (button, ctrlKey) ->
    @world.systemTestsRecorderAndPlayer.addMouseDownEvent(button, ctrlKey)

    @destroyTemporaries()
    @morphToGrab = null
    if @children.length
      @drop()
      @mouseButton = null
    else
      morph = @morphAtPointer()
      if @world.activeMenu
        unless contains(morph.allParents(), @world.activeMenu)
          @world.activeMenu.destroy()
        else
          clearInterval @touchHoldTimeout
      if @world.activeHandle
        if morph isnt @world.activeHandle
          @world.activeHandle.destroy()    
      if @world.caret
        # there is a caret on the screen
        # depending on what the user is clicking on,
        # we might need to close an ongoing edit
        # operation, which means deleting the
        # caret and un-selecting anything that was selected.
        # Note that we don't want to interrupt an edit
        # if the user is invoking/clicking on anything
        # inside a menu, because the invoked function
        # might do something with the selection
        # (for example doIt takes the current selection).
        if morph isnt @world.caret.target
          # user clicked on something other than what the
          # caret is attached to
          unless contains(morph.allParents(), @world.activeMenu)
            # only dismiss editing if the morph the user
            # clicked on is not part of a menu.
            @world.stopEditing()  
      @morphToGrab = morph.rootForGrab()  unless morph.mouseMove
      if button is 2 or ctrlKey
        @mouseButton = "right"
        actualClick = "mouseDownRight"
        expectedClick = "mouseClickRight"
      else
        @mouseButton = "left"
        actualClick = "mouseDownLeft"
        expectedClick = "mouseClickLeft"
      @mouseDownMorph = morph
      @mouseDownMorph = @mouseDownMorph.parent  until @mouseDownMorph[expectedClick]
      morph = morph.parent  until morph[actualClick]
      morph[actualClick] @bounds.origin
  
  processTouchStart: (event) ->
    WorldMorph.MorphicPreferences.isTouchDevice = true
    clearInterval @touchHoldTimeout
    if event.touches.length is 1
      # simulate mouseRightClick
      @touchHoldTimeout = setInterval(=>
        @processMouseDown button: 2
        @processMouseUp button: 2
        event.preventDefault()
        clearInterval @touchHoldTimeout
      , 400)
      @processMouseMove event.touches[0] # update my position
      @processMouseDown button: 0
      event.preventDefault()
  
  processTouchMove: (event) ->
    if event.touches.length is 1
      touch = event.touches[0]
      @processMouseMove touch
      clearInterval @touchHoldTimeout
  
  processTouchEnd: (event) ->
    WorldMorph.MorphicPreferences.isTouchDevice = true
    clearInterval @touchHoldTimeout
    @processMouseUp button: 0
  
  processMouseUp: ->
    @world.systemTestsRecorderAndPlayer.addMouseUpEvent()

    morph = @morphAtPointer()
    @destroyTemporaries()
    if @children.length
      @drop()
    else
      if @mouseButton is "left"
        expectedClick = "mouseClickLeft"
      else
        expectedClick = "mouseClickRight"
        if @mouseButton
          context = morph
          contextMenu = context.contextMenu()
          while (not contextMenu) and context.parent
            context = context.parent
            contextMenu = context.contextMenu()
          contextMenu.popUpAtHand @world  if contextMenu
      morph = morph.parent  until morph[expectedClick]
      morph[expectedClick] @bounds.origin
    @mouseButton = null

  processDoubleClick: ->
    morph = @morphAtPointer()
    @destroyTemporaries()
    if @children.length isnt 0
      @drop()
    else
      morph = morph.parent  while morph and not morph.mouseDoubleClick
      morph.mouseDoubleClick @bounds.origin  if morph
    @mouseButton = null
  
  processMouseScroll: (event) ->
    morph = @morphAtPointer()
    morph = morph.parent  while morph and not morph.mouseScroll

    morph.mouseScroll (event.detail / -3) or ((if Object.prototype.hasOwnProperty.call(event,'wheelDeltaY') then event.wheelDeltaY / 120 else event.wheelDelta / 120)), event.wheelDeltaX / 120 or 0  if morph
  
  
  #
  #	drop event:
  #
  #        droppedImage
  #        droppedSVG
  #        droppedAudio
  #        droppedText
  #
  processDrop: (event) ->
    #
    #    find out whether an external image or audio file was dropped
    #    onto the world canvas, turn it into an offscreen canvas or audio
    #    element and dispatch the
    #    
    #        droppedImage(canvas, name)
    #        droppedSVG(image, name)
    #        droppedAudio(audio, name)
    #    
    #    events to interested Morphs at the mouse pointer
    #    if none of the above content types can be determined, the file contents
    #    is dispatched as an ArrayBuffer to interested Morphs:
    #
    #    ```droppedBinary(anArrayBuffer, name)```

    files = (if event instanceof FileList then event else (event.target.files || event.dataTransfer.files))
    url = (if event.dataTransfer then event.dataTransfer.getData("URL") else null)
    txt = (if event.dataTransfer then event.dataTransfer.getData("Text/HTML") else null)
    targetDrop = @morphAtPointer()
    img = new Image()

    readSVG = (aFile) ->
      pic = new Image()
      frd = new FileReader()
      target = target.parent  until target.droppedSVG
      pic.onload = ->
        target.droppedSVG pic, aFile.name
      frd = new FileReader()
      frd.onloadend = (e) ->
        pic.src = e.target.result
      frd.readAsDataURL aFile

    readImage = (aFile) ->
      pic = new Image()
      frd = new FileReader()
      targetDrop = targetDrop.parent  until targetDrop.droppedImage
      pic.onload = ->
        canvas = newCanvas(new Point(pic.width, pic.height))
        canvas.getContext("2d").drawImage pic, 0, 0
        targetDrop.droppedImage canvas, aFile.name
      #
      frd = new FileReader()
      frd.onloadend = (e) ->
        pic.src = e.target.result
      #
      frd.readAsDataURL aFile
    #
    readAudio = (aFile) ->
      snd = new Audio()
      frd = new FileReader()
      targetDrop = targetDrop.parent  until targetDrop.droppedAudio
      frd.onloadend = (e) ->
        snd.src = e.target.result
        targetDrop.droppedAudio snd, aFile.name
      frd.readAsDataURL aFile
    
    readText = (aFile) ->
      frd = new FileReader()
      targetDrop = targetDrop.parent  until targetDrop.droppedText
      frd.onloadend = (e) ->
        targetDrop.droppedText e.target.result, aFile.name
      frd.readAsText aFile


    readBinary = (aFile) ->
      frd = new FileReader()
      targetDrop = targetDrop.parent  until targetDrop.droppedBinary
      frd.onloadend = (e) ->
        targetDrop.droppedBinary e.target.result, aFile.name
      frd.readAsArrayBuffer aFile

    parseImgURL = (html) ->
      url = ""
      start = html.indexOf("<img src=\"")
      return null  if start is -1
      start += 10
      for i in [start...html.length]
        c = html[i]
        return url  if c is "\""
        url = url.concat(c)
      null
    
    if files.length
      for file in files
        if file.type.indexOf("svg") != -1 && !WorldMorph.MorphicPreferences.rasterizeSVGs
          readSVG file
        else if file.type.indexOf("image") is 0
          readImage file
        else if file.type.indexOf("audio") is 0
          readAudio file
        else if file.type.indexOf("text") is 0
          readText file
        else
          readBinary file
    else if url
      if contains(["gif", "png", "jpg", "jpeg", "bmp"], url.slice(url.lastIndexOf(".") + 1).toLowerCase())
        target = target.parent  until target.droppedImage
        img = new Image()
        img.onload = ->
          canvas = newCanvas(new Point(img.width, img.height))
          canvas.getContext("2d").drawImage img, 0, 0
          target.droppedImage canvas
        img.src = url
    else if txt
      targetDrop = targetDrop.parent  until targetDrop.droppedImage
      img = new Image()
      img.onload = ->
        canvas = newCanvas(new Point(img.width, img.height))
        canvas.getContext("2d").drawImage img, 0, 0
        targetDrop.droppedImage canvas
      src = parseImgURL(txt)
      img.src = src  if src
  
  
  # HandMorph tools
  destroyTemporaries: ->
    #
    #	temporaries are just an array of morphs which will be deleted upon
    #	the next mouse click, or whenever another temporary Morph decides
    #	that it needs to remove them. The primary purpose of temporaries is
    #	to display tools tips of speech bubble help.
    #
    @temporaries.forEach (morph) =>
      unless morph.isClickable and morph.bounds.containsPoint(@position())
        morph.destroy()
        @temporaries.splice @temporaries.indexOf(morph), 1
  
  
  # HandMorph dragging optimization
  moveBy: (delta) ->
    Morph::trackChanges = false
    super delta
    Morph::trackChanges = true
    @fullChanged()

  processMouseMove: (pageX, pageY) ->
    @world.systemTestsRecorderAndPlayer.addMouseMoveEvent(pageX, pageY)
    
    #startProcessMouseMove = new Date().getTime()
    posInDocument = getDocumentPositionOf(@world.worldCanvas)
    pos = new Point(pageX - posInDocument.x, pageY - posInDocument.y)
    @setPosition pos
    #
    # determine the new mouse-over-list:
    # mouseOverNew = this.allMorphsAtPointer();
    mouseOverNew = @morphAtPointer().allParents()
    if (!@children.length) and (@mouseButton is "left")
      topMorph = @morphAtPointer()
      morph = topMorph.rootForGrab()
      topMorph.mouseMove pos  if topMorph.mouseMove
      #
      # if a morph is marked for grabbing, just grab it
      if @morphToGrab
        if @morphToGrab.isDraggable
          morph = @morphToGrab
          @grab morph
        else if @morphToGrab.isTemplate
          morph = @morphToGrab.fullCopy()
          morph.isTemplate = false
          morph.isDraggable = true
          @grab morph
          @grabOrigin = @morphToGrab.situation()
        #
        # if the mouse has left its boundsIncludingChildren, center it
        if morph
          fb = morph.boundsIncludingChildren()
          unless fb.containsPoint(pos)
            @bounds.origin = fb.center()
            @grab morph
            @setPosition pos
    #endProcessMouseMove = new Date().getTime()
    #timeProcessMouseMove = endProcessMouseMove - startProcessMouseMove;
    #console.log('Execution time ProcessMouseMove: ' + timeProcessMouseMove);
    
    #
    #	original, more cautious code for grabbing Morphs,
    #	retained in case of needing to fall back:
    #
    #		if (morph === this.morphToGrab) {
    #			if (morph.isDraggable) {
    #				this.grab(morph);
    #			} else if (morph.isTemplate) {
    #				morph = morph.fullCopy();
    #				morph.isTemplate = false;
    #				morph.isDraggable = true;
    #				this.grab(morph);
    #			}
    #		}
    #
    @mouseOverList.forEach (old) =>
      unless contains(mouseOverNew, old)
        old.mouseLeave()  if old.mouseLeave
        old.mouseLeaveDragging()  if old.mouseLeaveDragging and @mouseButton
    #
    mouseOverNew.forEach (newMorph) =>
      unless contains(@mouseOverList, newMorph)
        newMorph.mouseEnter()  if newMorph.mouseEnter
        newMorph.mouseEnterDragging()  if newMorph.mouseEnterDragging and @mouseButton
      #
      # autoScrolling support:
      if @children.length
          if newMorph instanceof ScrollFrameMorph
              if !newMorph.bounds.insetBy(
                WorldMorph.MorphicPreferences.scrollBarSize * 3
                ).containsPoint(@bounds.origin)
                  newMorph.startAutoScrolling();
    #
    @mouseOverList = mouseOverNew
  '''
# ListMorph ///////////////////////////////////////////////////////////

class ListMorph extends ScrollFrameMorph
  
  elements: null
  labelGetter: null
  format: null
  listContents: null
  selected: null # actual element currently selected
  active: null # menu item representing the selected element
  action: null
  doubleClickAction: null

  constructor: (@elements = [], labelGetter, @format = [], @doubleClickAction = null) ->
    #
    #    passing a format is optional. If the format parameter is specified
    #    it has to be of the following pattern:
    #
    #        [
    #            [<color>, <single-argument predicate>],
    #            ['bold', <single-argument predicate>],
    #            ['italic', <single-argument predicate>],
    #            ...
    #        ]
    #
    #    multiple conditions can be passed in such a format list, the
    #    last predicate to evaluate true when given the list element sets
    #    the given format category (color, bold, italic).
    #    If no condition is met, the default format (color black, non-bold,
    #    non-italic) will be assigned.
    #    
    #    An example of how to use fomats can be found in the InspectorMorph's
    #    "markOwnProperties" mechanism.
    #
    super()
    @contents.acceptsDrops = false
    @color = new Color(255, 255, 255)
    @hBar.alpha = 0.6
    @vBar.alpha = 0.6
    @labelGetter = labelGetter or (element) ->
        return element  if isString(element)
        return element.toSource()  if element.toSource
        element.toString()
    @buildListContents()
    # it's important to leave the step as the default noOperation
    # instead of null because the scrollbars (inherited from scrollframe)
    # need the step function to react to mouse drag.
  
  buildListContents: ->
    @listContents.destroy()  if @listContents
    @listContents = new MenuMorph(@select, null, @)
    @elements = ["(empty)"]  if !@elements.length
    @elements.forEach (element) =>
      color = null
      bold = false
      italic = false
      @format.forEach (pair) ->
        if pair[1].call(null, element)
          if pair[0] == 'bold'
            bold = true
          else if pair[0] == 'italic'
            italic = true
          else # assume it's a color
            color = pair[0]
      #
      # label string
      # action
      # hint
      @listContents.addItem @labelGetter(element), element, null, color, bold, italic, @doubleClickAction
    #
    @listContents.setPosition @contents.position()
    @listContents.isListContents = true
    @listContents.updateRendering()
    @addContents @listContents
  
  select: (item, trigger) ->
    @selected = item
    @active = trigger
    @action.call null, item  if @action
  
  setExtent: (aPoint) ->
    lb = @listContents.bounds
    nb = @bounds.origin.copy().corner(@bounds.origin.add(aPoint))
    if nb.right() > lb.right() and nb.width() <= lb.width()
      @listContents.setRight nb.right()
    if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
      @listContents.setBottom nb.bottom()
    super aPoint

  @coffeeScriptSourceOfThisClass: '''
# ListMorph ///////////////////////////////////////////////////////////

class ListMorph extends ScrollFrameMorph
  
  elements: null
  labelGetter: null
  format: null
  listContents: null
  selected: null # actual element currently selected
  active: null # menu item representing the selected element
  action: null
  doubleClickAction: null

  constructor: (@elements = [], labelGetter, @format = [], @doubleClickAction = null) ->
    #
    #    passing a format is optional. If the format parameter is specified
    #    it has to be of the following pattern:
    #
    #        [
    #            [<color>, <single-argument predicate>],
    #            ['bold', <single-argument predicate>],
    #            ['italic', <single-argument predicate>],
    #            ...
    #        ]
    #
    #    multiple conditions can be passed in such a format list, the
    #    last predicate to evaluate true when given the list element sets
    #    the given format category (color, bold, italic).
    #    If no condition is met, the default format (color black, non-bold,
    #    non-italic) will be assigned.
    #    
    #    An example of how to use fomats can be found in the InspectorMorph's
    #    "markOwnProperties" mechanism.
    #
    super()
    @contents.acceptsDrops = false
    @color = new Color(255, 255, 255)
    @hBar.alpha = 0.6
    @vBar.alpha = 0.6
    @labelGetter = labelGetter or (element) ->
        return element  if isString(element)
        return element.toSource()  if element.toSource
        element.toString()
    @buildListContents()
    # it's important to leave the step as the default noOperation
    # instead of null because the scrollbars (inherited from scrollframe)
    # need the step function to react to mouse drag.
  
  buildListContents: ->
    @listContents.destroy()  if @listContents
    @listContents = new MenuMorph(@select, null, @)
    @elements = ["(empty)"]  if !@elements.length
    @elements.forEach (element) =>
      color = null
      bold = false
      italic = false
      @format.forEach (pair) ->
        if pair[1].call(null, element)
          if pair[0] == 'bold'
            bold = true
          else if pair[0] == 'italic'
            italic = true
          else # assume it's a color
            color = pair[0]
      #
      # label string
      # action
      # hint
      @listContents.addItem @labelGetter(element), element, null, color, bold, italic, @doubleClickAction
    #
    @listContents.setPosition @contents.position()
    @listContents.isListContents = true
    @listContents.updateRendering()
    @addContents @listContents
  
  select: (item, trigger) ->
    @selected = item
    @active = trigger
    @action.call null, item  if @action
  
  setExtent: (aPoint) ->
    lb = @listContents.bounds
    nb = @bounds.origin.copy().corner(@bounds.origin.add(aPoint))
    if nb.right() > lb.right() and nb.width() <= lb.width()
      @listContents.setRight nb.right()
    if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
      @listContents.setBottom nb.bottom()
    super aPoint
  '''
# ShadowMorph /////////////////////////////////////////////////////////

class ShadowMorph extends Morph
  constructor: () ->
    super()

  @coffeeScriptSourceOfThisClass: '''
# ShadowMorph /////////////////////////////////////////////////////////

class ShadowMorph extends Morph
  constructor: () ->
    super()
  '''
# HandleMorph ////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

# I am a resize / move handle that can be attached to any Morph

class HandleMorph extends Morph

  target: null
  minExtent: null
  inset: null
  type: null # "resize" or "move"

  constructor: (@target = null, minX = 0, minY = 0, insetX, insetY, @type = "resize") ->
    # if insetY is missing, it will be the same as insetX
    @minExtent = new Point(minX, minY)
    @inset = new Point(insetX or 0, insetY or insetX or 0)
    super()
    @color = new Color(255, 255, 255)
    @noticesTransparentClick = true
    size = WorldMorph.MorphicPreferences.handleSize
    @setExtent new Point(size, size)  
  
  # HandleMorph drawing:
  updateRendering: ->
    @normalImage = newCanvas(@extent())
    @highlightImage = newCanvas(@extent())
    @handleMorphRenderingHelper @normalImage, @color, new Color(100, 100, 100)
    @handleMorphRenderingHelper @highlightImage, new Color(100, 100, 255), new Color(255, 255, 255)
    @image = @normalImage
    if @target
      @setPosition @target.bottomRight().subtract(@extent().add(@inset))
      @target.add @
      @target.changed()
  
  handleMorphRenderingHelper: (aCanvas, color, shadowColor) ->
    context = aCanvas.getContext("2d")
    context.lineWidth = 1
    context.lineCap = "round"
    context.strokeStyle = color.toString()
    if @type is "move"
      p1 = @bottomLeft().subtract(@position())
      p11 = p1.copy()
      p2 = @topRight().subtract(@position())
      p22 = p2.copy()
      for i in [0..@height()] by 6
        p11.y = p1.y - i
        p22.y = p2.y - i
        context.beginPath()
        context.moveTo p11.x, p11.y
        context.lineTo p22.x, p22.y
        context.closePath()
        context.stroke()

    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    for i in [0..@width()] by 6
      p11.x = p1.x + i
      p22.x = p2.x + i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()

    context.strokeStyle = shadowColor.toString()
    if @type is "move"
      p1 = @bottomLeft().subtract(@position())
      p11 = p1.copy()
      p2 = @topRight().subtract(@position())
      p22 = p2.copy()
      for i in [-1..@height()] by 6
        p11.y = p1.y - i
        p22.y = p2.y - i
        context.beginPath()
        context.moveTo p11.x, p11.y
        context.lineTo p22.x, p22.y
        context.closePath()
        context.stroke()

    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    for i in [2..@width()] by 6
      p11.x = p1.x + i
      p22.x = p2.x + i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()
  
  
  # HandleMorph stepping:
  step = null
  mouseDownLeft: (pos) ->
    world = @root()
    offset = pos.subtract(@bounds.origin)
    return null  unless @target
    @step = =>
      if world.hand.mouseButton
        newPos = world.hand.bounds.origin.copy().subtract(offset)
        if @type is "resize"
          newExt = newPos.add(@extent().add(@inset)).subtract(@target.bounds.origin)
          newExt = newExt.max(@minExtent)
          @target.setExtent newExt
          @setPosition @target.bottomRight().subtract(@extent().add(@inset))
        else # type === 'move'
          @target.setPosition newPos.subtract(@target.extent()).add(@extent())
      else
        @step = null
    
    unless @target.step
      @target.step = noOperation
  
  
  # HandleMorph dragging and dropping:
  rootForGrab: ->
    @
  
  
  # HandleMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
  
  
  # HandleMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.target = (dict[@target])  if c.target and dict[@target]
    c
  
  
  # HandleMorph menu:
  attach: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), ->
        @isDraggable = false
        @target = each
        @updateRendering()
        @noticesTransparentClick = true
    menu.popUpAtHand @world()  if choices.length

  @coffeeScriptSourceOfThisClass: '''
# HandleMorph ////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

# I am a resize / move handle that can be attached to any Morph

class HandleMorph extends Morph

  target: null
  minExtent: null
  inset: null
  type: null # "resize" or "move"

  constructor: (@target = null, minX = 0, minY = 0, insetX, insetY, @type = "resize") ->
    # if insetY is missing, it will be the same as insetX
    @minExtent = new Point(minX, minY)
    @inset = new Point(insetX or 0, insetY or insetX or 0)
    super()
    @color = new Color(255, 255, 255)
    @noticesTransparentClick = true
    size = WorldMorph.MorphicPreferences.handleSize
    @setExtent new Point(size, size)  
  
  # HandleMorph drawing:
  updateRendering: ->
    @normalImage = newCanvas(@extent())
    @highlightImage = newCanvas(@extent())
    @handleMorphRenderingHelper @normalImage, @color, new Color(100, 100, 100)
    @handleMorphRenderingHelper @highlightImage, new Color(100, 100, 255), new Color(255, 255, 255)
    @image = @normalImage
    if @target
      @setPosition @target.bottomRight().subtract(@extent().add(@inset))
      @target.add @
      @target.changed()
  
  handleMorphRenderingHelper: (aCanvas, color, shadowColor) ->
    context = aCanvas.getContext("2d")
    context.lineWidth = 1
    context.lineCap = "round"
    context.strokeStyle = color.toString()
    if @type is "move"
      p1 = @bottomLeft().subtract(@position())
      p11 = p1.copy()
      p2 = @topRight().subtract(@position())
      p22 = p2.copy()
      for i in [0..@height()] by 6
        p11.y = p1.y - i
        p22.y = p2.y - i
        context.beginPath()
        context.moveTo p11.x, p11.y
        context.lineTo p22.x, p22.y
        context.closePath()
        context.stroke()

    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    for i in [0..@width()] by 6
      p11.x = p1.x + i
      p22.x = p2.x + i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()

    context.strokeStyle = shadowColor.toString()
    if @type is "move"
      p1 = @bottomLeft().subtract(@position())
      p11 = p1.copy()
      p2 = @topRight().subtract(@position())
      p22 = p2.copy()
      for i in [-1..@height()] by 6
        p11.y = p1.y - i
        p22.y = p2.y - i
        context.beginPath()
        context.moveTo p11.x, p11.y
        context.lineTo p22.x, p22.y
        context.closePath()
        context.stroke()

    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    for i in [2..@width()] by 6
      p11.x = p1.x + i
      p22.x = p2.x + i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()
  
  
  # HandleMorph stepping:
  step = null
  mouseDownLeft: (pos) ->
    world = @root()
    offset = pos.subtract(@bounds.origin)
    return null  unless @target
    @step = =>
      if world.hand.mouseButton
        newPos = world.hand.bounds.origin.copy().subtract(offset)
        if @type is "resize"
          newExt = newPos.add(@extent().add(@inset)).subtract(@target.bounds.origin)
          newExt = newExt.max(@minExtent)
          @target.setExtent newExt
          @setPosition @target.bottomRight().subtract(@extent().add(@inset))
        else # type === 'move'
          @target.setPosition newPos.subtract(@target.extent()).add(@extent())
      else
        @step = null
    
    unless @target.step
      @target.step = noOperation
  
  
  # HandleMorph dragging and dropping:
  rootForGrab: ->
    @
  
  
  # HandleMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
  
  
  # HandleMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.target = (dict[@target])  if c.target and dict[@target]
    c
  
  
  # HandleMorph menu:
  attach: ->
    choices = @overlappedMorphs()
    menu = new MenuMorph(@, "choose target:")
    choices.forEach (each) =>
      menu.addItem each.toString().slice(0, 50), ->
        @isDraggable = false
        @target = each
        @updateRendering()
        @noticesTransparentClick = true
    menu.popUpAtHand @world()  if choices.length
  '''
# InspectorMorph //////////////////////////////////////////////////////

class InspectorMorph extends BoxMorph

  target: null
  currentProperty: null
  showing: "attributes"
  markOwnershipOfProperties: false
  # panes:
  label: null
  list: null
  detail: null
  work: null
  buttonInspect: null
  buttonClose: null
  buttonSubset: null
  buttonEdit: null
  resizer: null

  constructor: (@target) ->
    super()
    # override inherited properties:
    @silentSetExtent new Point(WorldMorph.MorphicPreferences.handleSize * 20,
      WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = if WorldMorph.MorphicPreferences.isFlat then 1 else 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @updateRendering()
    @buildPanes()  if @target
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []
    #
    # remove existing panes
    @children.forEach (m) ->
      # keep work pane around
      m.destroy()  if m isnt @work
    #
    @children = []
    #
    # label
    @label = new TextMorph(@target.toString())
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.updateRendering()
    @add @label
    
    # properties list. Note that this picks up ALL properties
    # (enumerable such as strings and un-enumerable such as functions)
    # of the whole prototype chain.
    #
    #   a) some of these are DECLARED as part of the class that defines the object
    #   and are proprietary to the object. These are shown RED
    # 
    #   b) some of these are proprietary to the object but are initialised by
    #   code higher in the prototype chain. These are shown GREEN
    #
    #   c) some of these are not proprietary, i.e. they belong to an object up
    #   the chain of prototypes. These are shown BLUE
    #
    # todo: show the static methods and variables in yet another color.
    
    for property of @target
      # dummy condition, to be refined
      attribs.push property  if property
    if @showing is "attributes"
      attribs = attribs.filter((prop) =>
        not isFunction @target[prop]
      )
    else if @showing is "methods"
      attribs = attribs.filter((prop) =>
        isFunction @target[prop]
      )
    # otherwise show all properties
    # label getter
    # format list
    # format element: [color, predicate(element]
    
    staticProperties = Object.getOwnPropertyNames(@target.constructor)
    # get rid of all the standar fuff properties that are in classes
    staticProperties = staticProperties.filter((prop) =>
        prop not in ["name","length","prototype","caller","__super__","arguments"]
    )
    if @showing is "attributes"
      staticFunctions = []
      staticAttributes = staticProperties.filter((prop) =>
        not isFunction(@target.constructor[prop])
      )
    else if @showing is "methods"
      staticFunctions = staticProperties.filter((prop) =>
        isFunction(@target.constructor[prop])
      )
      staticAttributes = []
    else
      staticFunctions = staticProperties.filter((prop) =>
        isFunction(@target.constructor[prop])
      )
      staticAttributes = staticProperties.filter((prop) =>
        prop not in staticFunctions
      )
    #alert "stat fun " + staticFunctions + " stat attr " + staticAttributes
    attribs = (attribs.concat staticFunctions).concat staticAttributes
    #alert " all attribs " + attribs
    
    # caches the own methods of the object
    if @markOwnershipOfProperties
      targetOwnMethods = Object.getOwnPropertyNames(@target.constructor.prototype)
      #alert targetOwnMethods

    doubleClickAction = =>
      if (!isObject(@currentProperty))
        return
      world = @world()
      inspector = new InspectorMorph @currentProperty
      inspector.setPosition world.hand.position()
      inspector.keepWithin world
      world.add inspector
      inspector.changed()

    @list = new ListMorph((if @target instanceof Array then attribs else attribs.sort()), null,(
      if @markOwnershipOfProperties
        [
          # give color criteria from the most general to the most specific
          [new Color(0, 0, 180),
            (element) =>
              # if the element is either an enumerable property of the object
              # or it belongs to the own methods, then it is highlighted.
              # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
              # functions.
              # In theory, getOwnPropertyNames should give ALL the properties but the methods
              # are still not picked up, maybe because of the coffeescript construction system, I am not sure
              true
          ],
          [new Color(255, 165, 0),
            (element) =>
              # if the element is either an enumerable property of the object
              # or it belongs to the own methods, then it is highlighted.
              # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
              # functions.
              # In theory, getOwnPropertyNames should give ALL the properties but the methods
              # are still not picked up, maybe because of the coffeescript construction system, I am not sure
              element in staticProperties
          ],
          [new Color(0, 180, 0),
            (element) =>
              # if the element is either an enumerable property of the object
              # or it belongs to the own methods, then it is highlighted.
              # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
              # functions.
              # In theory, getOwnPropertyNames should give ALL the properties but the methods
              # are still not picked up, maybe because of the coffeescript construction system, I am not sure
              (Object.prototype.hasOwnProperty.call(@target, element))
          ],
          [new Color(180, 0, 0),
            (element) =>
              # if the element is either an enumerable property of the object
              # or it belongs to the own methods, then it is highlighted.
              # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
              # functions.
              # In theory, getOwnPropertyNames should give ALL the properties but the methods
              # are still not picked up, maybe because of the coffeescript construction system, I am not sure
              (element in targetOwnMethods)
          ]
        ]
      else null
    ),doubleClickAction)

    @list.action = (selected) =>
      if (selected == undefined) then return
      val = @target[selected]
      # this is for finding the static variables
      if val is undefined
        val = @target.constructor[selected]
      @currentProperty = val
      if val is null
        txt = "NULL"
      else if isString(val)
        txt = val
      else
        txt = val.toString()
      cnts = new TextMorph(txt)
      cnts.isEditable = true
      cnts.enableSelecting()
      cnts.setReceiver @target
      @detail.setContents cnts
    #
    @list.hBar.alpha = 0.6
    @list.vBar.alpha = 0.6
    # we know that the content of this list in this pane is not going to need the
    # step function, so we disable that from here by setting it to null, which
    # prevents the recursion to children. We could have disabled that from the
    # constructor of MenuMorph, but who knows, maybe someone might intend to use a MenuMorph
    # with some animated content? We know that in this specific case it won't need animation so
    # we set that here. Note that the ListMorph itself does require animation because of the
    # scrollbars, but the MenuMorph (which contains the actual list contents)
    # in this context doesn't.
    @list.listContents.step = null
    @add @list
    #
    # details pane
    @detail = new ScrollFrameMorph()
    @detail.acceptsDrops = false
    @detail.contents.acceptsDrops = false
    @detail.isTextLineWrapping = true
    @detail.color = new Color(255, 255, 255)
    @detail.hBar.alpha = 0.6
    @detail.vBar.alpha = 0.6
    ctrl = new TextMorph("")
    ctrl.isEditable = true
    ctrl.enableSelecting()
    ctrl.setReceiver @target
    @detail.setContents ctrl
    @add @detail
    #
    # work ('evaluation') pane
    # don't refresh the work pane if it already exists
    if @work is null
      @work = new ScrollFrameMorph()
      @work.acceptsDrops = false
      @work.contents.acceptsDrops = false
      @work.isTextLineWrapping = true
      @work.color = new Color(255, 255, 255)
      @work.hBar.alpha = 0.6
      @work.vBar.alpha = 0.6
      ev = new TextMorph("")
      ev.isEditable = true
      ev.enableSelecting()
      ev.setReceiver @target
      @work.setContents ev
    @add @work
    #
    # properties button
    @buttonSubset = new TriggerMorph()
    @buttonSubset.labelString = "show..."
    @buttonSubset.action = =>
      menu = new MenuMorph()
      menu.addItem "attributes", =>
        @showing = "attributes"
        @buildPanes()
      #
      menu.addItem "methods", =>
        @showing = "methods"
        @buildPanes()
      #
      menu.addItem "all", =>
        @showing = "all"
        @buildPanes()
      #
      menu.addLine()
      menu.addItem ((if @markOwnershipOfProperties then "un-mark ownership" else "mark ownership")), (=>
        @markOwnershipOfProperties = not @markOwnershipOfProperties
        @buildPanes()
      ), "highlight\nownership of properties"
      menu.popUpAtHand @world()
    #
    @add @buttonSubset
    #
    # inspect button
    @buttonInspect = new TriggerMorph()
    @buttonInspect.labelString = "inspect..."
    @buttonInspect.action = =>
      if isObject(@currentProperty)
        menu = new MenuMorph()
        menu.addItem "in new inspector...", =>
          world = @world()
          inspector = new InspectorMorph(@currentProperty)
          inspector.setPosition world.hand.position()
          inspector.keepWithin world
          world.add inspector
          inspector.changed()
        #
        menu.addItem "here...", =>
          @setTarget @currentProperty
        #
        menu.popUpAtHand @world()
      else
        @inform ((if @currentProperty is null then "null" else typeof @currentProperty)) + "\nis not inspectable"
    #
    @add @buttonInspect
    #
    # edit button
    @buttonEdit = new TriggerMorph()
    @buttonEdit.labelString = "edit..."
    @buttonEdit.action = =>
      menu = new MenuMorph(@)
      menu.addItem "save", "save", "accept changes"
      menu.addLine()
      menu.addItem "add property...", "addProperty"
      menu.addItem "rename...", "renameProperty"
      menu.addItem "remove...", "removeProperty"
      menu.popUpAtHand @world()
    #
    @add @buttonEdit
    #
    # close button
    @buttonClose = new TriggerMorph()
    @buttonClose.labelString = "close"
    @buttonClose.action = =>
      @destroy()
    #
    @add @buttonClose
    #
    # resizer
    @resizer = new HandleMorph(@, 150, 100, @edge, @edge)
    #
    # update layout
    @fixLayout()
  
  fixLayout: ->
    Morph::trackChanges = false
    #
    # label
    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x
    @label.setPosition new Point(x, y)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @silentSetHeight @label.height() + 50
      @updateRendering()
      @changed()
      @resizer.updateRendering()
    #
    # list
    y = @label.bottom() + 2
    w = Math.min(Math.floor(@width() / 3), @list.listContents.width())
    w -= @edge
    b = @bottom() - (2 * @edge) - WorldMorph.MorphicPreferences.handleSize
    h = b - y
    @list.setPosition new Point(x, y)
    @list.setExtent new Point(w, h)
    #
    # detail
    x = @list.right() + @edge
    r = @right() - @edge
    w = r - x
    @detail.setPosition new Point(x, y)
    @detail.setExtent new Point(w, (h * 2 / 3) - @edge)
    #
    # work
    y = @detail.bottom() + @edge
    @work.setPosition new Point(x, y)
    @work.setExtent new Point(w, h / 3)
    #
    # properties button
    x = @list.left()
    y = @list.bottom() + @edge
    w = @list.width()
    h = WorldMorph.MorphicPreferences.handleSize
    @buttonSubset.setPosition new Point(x, y)
    @buttonSubset.setExtent new Point(w, h)
    #
    # inspect button
    x = @detail.left()
    w = @detail.width() - @edge - WorldMorph.MorphicPreferences.handleSize
    w = w / 3 - @edge / 3
    @buttonInspect.setPosition new Point(x, y)
    @buttonInspect.setExtent new Point(w, h)
    #
    # edit button
    x = @buttonInspect.right() + @edge
    @buttonEdit.setPosition new Point(x, y)
    @buttonEdit.setExtent new Point(w, h)
    #
    # close button
    x = @buttonEdit.right() + @edge
    r = @detail.right() - @edge - WorldMorph.MorphicPreferences.handleSize
    w = r - x
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
    @fixLayout()
  
  
  #InspectorMorph editing ops:
  save: ->
    txt = @detail.contents.children[0].text.toString()
    prop = @list.selected
    try
      #
      # this.target[prop] = evaluate(txt);
      @target.evaluateString "this." + prop + " = " + txt
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    catch err
      @inform err
  
  addProperty: ->
    @prompt "new property name:", ((prop) =>
      if prop
        @target[prop] = null
        @buildPanes()
        if @target.updateRendering
          @target.changed()
          @target.updateRendering()
          @target.changed()
    ), @, "property" # Chrome cannot handle empty strings (others do)
  
  renameProperty: ->
    propertyName = @list.selected
    @prompt "property name:", ((prop) =>
      try
        delete (@target[propertyName])
        @target[prop] = @currentProperty
      catch err
        @inform err
      @buildPanes()
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    ), @, propertyName
  
  removeProperty: ->
    prop = @list.selected
    try
      delete (@target[prop])
      #
      @currentProperty = null
      @buildPanes()
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    catch err
      @inform err

  @coffeeScriptSourceOfThisClass: '''
# InspectorMorph //////////////////////////////////////////////////////

class InspectorMorph extends BoxMorph

  target: null
  currentProperty: null
  showing: "attributes"
  markOwnershipOfProperties: false
  # panes:
  label: null
  list: null
  detail: null
  work: null
  buttonInspect: null
  buttonClose: null
  buttonSubset: null
  buttonEdit: null
  resizer: null

  constructor: (@target) ->
    super()
    # override inherited properties:
    @silentSetExtent new Point(WorldMorph.MorphicPreferences.handleSize * 20,
      WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = if WorldMorph.MorphicPreferences.isFlat then 1 else 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @updateRendering()
    @buildPanes()  if @target
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []
    #
    # remove existing panes
    @children.forEach (m) ->
      # keep work pane around
      m.destroy()  if m isnt @work
    #
    @children = []
    #
    # label
    @label = new TextMorph(@target.toString())
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.updateRendering()
    @add @label
    
    # properties list. Note that this picks up ALL properties
    # (enumerable such as strings and un-enumerable such as functions)
    # of the whole prototype chain.
    #
    #   a) some of these are DECLARED as part of the class that defines the object
    #   and are proprietary to the object. These are shown RED
    # 
    #   b) some of these are proprietary to the object but are initialised by
    #   code higher in the prototype chain. These are shown GREEN
    #
    #   c) some of these are not proprietary, i.e. they belong to an object up
    #   the chain of prototypes. These are shown BLUE
    #
    # todo: show the static methods and variables in yet another color.
    
    for property of @target
      # dummy condition, to be refined
      attribs.push property  if property
    if @showing is "attributes"
      attribs = attribs.filter((prop) =>
        not isFunction @target[prop]
      )
    else if @showing is "methods"
      attribs = attribs.filter((prop) =>
        isFunction @target[prop]
      )
    # otherwise show all properties
    # label getter
    # format list
    # format element: [color, predicate(element]
    
    staticProperties = Object.getOwnPropertyNames(@target.constructor)
    # get rid of all the standar fuff properties that are in classes
    staticProperties = staticProperties.filter((prop) =>
        prop not in ["name","length","prototype","caller","__super__","arguments"]
    )
    if @showing is "attributes"
      staticFunctions = []
      staticAttributes = staticProperties.filter((prop) =>
        not isFunction(@target.constructor[prop])
      )
    else if @showing is "methods"
      staticFunctions = staticProperties.filter((prop) =>
        isFunction(@target.constructor[prop])
      )
      staticAttributes = []
    else
      staticFunctions = staticProperties.filter((prop) =>
        isFunction(@target.constructor[prop])
      )
      staticAttributes = staticProperties.filter((prop) =>
        prop not in staticFunctions
      )
    #alert "stat fun " + staticFunctions + " stat attr " + staticAttributes
    attribs = (attribs.concat staticFunctions).concat staticAttributes
    #alert " all attribs " + attribs
    
    # caches the own methods of the object
    if @markOwnershipOfProperties
      targetOwnMethods = Object.getOwnPropertyNames(@target.constructor.prototype)
      #alert targetOwnMethods

    doubleClickAction = =>
      if (!isObject(@currentProperty))
        return
      world = @world()
      inspector = new InspectorMorph @currentProperty
      inspector.setPosition world.hand.position()
      inspector.keepWithin world
      world.add inspector
      inspector.changed()

    @list = new ListMorph((if @target instanceof Array then attribs else attribs.sort()), null,(
      if @markOwnershipOfProperties
        [
          # give color criteria from the most general to the most specific
          [new Color(0, 0, 180),
            (element) =>
              # if the element is either an enumerable property of the object
              # or it belongs to the own methods, then it is highlighted.
              # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
              # functions.
              # In theory, getOwnPropertyNames should give ALL the properties but the methods
              # are still not picked up, maybe because of the coffeescript construction system, I am not sure
              true
          ],
          [new Color(255, 165, 0),
            (element) =>
              # if the element is either an enumerable property of the object
              # or it belongs to the own methods, then it is highlighted.
              # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
              # functions.
              # In theory, getOwnPropertyNames should give ALL the properties but the methods
              # are still not picked up, maybe because of the coffeescript construction system, I am not sure
              element in staticProperties
          ],
          [new Color(0, 180, 0),
            (element) =>
              # if the element is either an enumerable property of the object
              # or it belongs to the own methods, then it is highlighted.
              # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
              # functions.
              # In theory, getOwnPropertyNames should give ALL the properties but the methods
              # are still not picked up, maybe because of the coffeescript construction system, I am not sure
              (Object.prototype.hasOwnProperty.call(@target, element))
          ],
          [new Color(180, 0, 0),
            (element) =>
              # if the element is either an enumerable property of the object
              # or it belongs to the own methods, then it is highlighted.
              # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
              # functions.
              # In theory, getOwnPropertyNames should give ALL the properties but the methods
              # are still not picked up, maybe because of the coffeescript construction system, I am not sure
              (element in targetOwnMethods)
          ]
        ]
      else null
    ),doubleClickAction)

    @list.action = (selected) =>
      if (selected == undefined) then return
      val = @target[selected]
      # this is for finding the static variables
      if val is undefined
        val = @target.constructor[selected]
      @currentProperty = val
      if val is null
        txt = "NULL"
      else if isString(val)
        txt = val
      else
        txt = val.toString()
      cnts = new TextMorph(txt)
      cnts.isEditable = true
      cnts.enableSelecting()
      cnts.setReceiver @target
      @detail.setContents cnts
    #
    @list.hBar.alpha = 0.6
    @list.vBar.alpha = 0.6
    # we know that the content of this list in this pane is not going to need the
    # step function, so we disable that from here by setting it to null, which
    # prevents the recursion to children. We could have disabled that from the
    # constructor of MenuMorph, but who knows, maybe someone might intend to use a MenuMorph
    # with some animated content? We know that in this specific case it won't need animation so
    # we set that here. Note that the ListMorph itself does require animation because of the
    # scrollbars, but the MenuMorph (which contains the actual list contents)
    # in this context doesn't.
    @list.listContents.step = null
    @add @list
    #
    # details pane
    @detail = new ScrollFrameMorph()
    @detail.acceptsDrops = false
    @detail.contents.acceptsDrops = false
    @detail.isTextLineWrapping = true
    @detail.color = new Color(255, 255, 255)
    @detail.hBar.alpha = 0.6
    @detail.vBar.alpha = 0.6
    ctrl = new TextMorph("")
    ctrl.isEditable = true
    ctrl.enableSelecting()
    ctrl.setReceiver @target
    @detail.setContents ctrl
    @add @detail
    #
    # work ('evaluation') pane
    # don't refresh the work pane if it already exists
    if @work is null
      @work = new ScrollFrameMorph()
      @work.acceptsDrops = false
      @work.contents.acceptsDrops = false
      @work.isTextLineWrapping = true
      @work.color = new Color(255, 255, 255)
      @work.hBar.alpha = 0.6
      @work.vBar.alpha = 0.6
      ev = new TextMorph("")
      ev.isEditable = true
      ev.enableSelecting()
      ev.setReceiver @target
      @work.setContents ev
    @add @work
    #
    # properties button
    @buttonSubset = new TriggerMorph()
    @buttonSubset.labelString = "show..."
    @buttonSubset.action = =>
      menu = new MenuMorph()
      menu.addItem "attributes", =>
        @showing = "attributes"
        @buildPanes()
      #
      menu.addItem "methods", =>
        @showing = "methods"
        @buildPanes()
      #
      menu.addItem "all", =>
        @showing = "all"
        @buildPanes()
      #
      menu.addLine()
      menu.addItem ((if @markOwnershipOfProperties then "un-mark ownership" else "mark ownership")), (=>
        @markOwnershipOfProperties = not @markOwnershipOfProperties
        @buildPanes()
      ), "highlight\nownership of properties"
      menu.popUpAtHand @world()
    #
    @add @buttonSubset
    #
    # inspect button
    @buttonInspect = new TriggerMorph()
    @buttonInspect.labelString = "inspect..."
    @buttonInspect.action = =>
      if isObject(@currentProperty)
        menu = new MenuMorph()
        menu.addItem "in new inspector...", =>
          world = @world()
          inspector = new InspectorMorph(@currentProperty)
          inspector.setPosition world.hand.position()
          inspector.keepWithin world
          world.add inspector
          inspector.changed()
        #
        menu.addItem "here...", =>
          @setTarget @currentProperty
        #
        menu.popUpAtHand @world()
      else
        @inform ((if @currentProperty is null then "null" else typeof @currentProperty)) + "\nis not inspectable"
    #
    @add @buttonInspect
    #
    # edit button
    @buttonEdit = new TriggerMorph()
    @buttonEdit.labelString = "edit..."
    @buttonEdit.action = =>
      menu = new MenuMorph(@)
      menu.addItem "save", "save", "accept changes"
      menu.addLine()
      menu.addItem "add property...", "addProperty"
      menu.addItem "rename...", "renameProperty"
      menu.addItem "remove...", "removeProperty"
      menu.popUpAtHand @world()
    #
    @add @buttonEdit
    #
    # close button
    @buttonClose = new TriggerMorph()
    @buttonClose.labelString = "close"
    @buttonClose.action = =>
      @destroy()
    #
    @add @buttonClose
    #
    # resizer
    @resizer = new HandleMorph(@, 150, 100, @edge, @edge)
    #
    # update layout
    @fixLayout()
  
  fixLayout: ->
    Morph::trackChanges = false
    #
    # label
    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x
    @label.setPosition new Point(x, y)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @silentSetHeight @label.height() + 50
      @updateRendering()
      @changed()
      @resizer.updateRendering()
    #
    # list
    y = @label.bottom() + 2
    w = Math.min(Math.floor(@width() / 3), @list.listContents.width())
    w -= @edge
    b = @bottom() - (2 * @edge) - WorldMorph.MorphicPreferences.handleSize
    h = b - y
    @list.setPosition new Point(x, y)
    @list.setExtent new Point(w, h)
    #
    # detail
    x = @list.right() + @edge
    r = @right() - @edge
    w = r - x
    @detail.setPosition new Point(x, y)
    @detail.setExtent new Point(w, (h * 2 / 3) - @edge)
    #
    # work
    y = @detail.bottom() + @edge
    @work.setPosition new Point(x, y)
    @work.setExtent new Point(w, h / 3)
    #
    # properties button
    x = @list.left()
    y = @list.bottom() + @edge
    w = @list.width()
    h = WorldMorph.MorphicPreferences.handleSize
    @buttonSubset.setPosition new Point(x, y)
    @buttonSubset.setExtent new Point(w, h)
    #
    # inspect button
    x = @detail.left()
    w = @detail.width() - @edge - WorldMorph.MorphicPreferences.handleSize
    w = w / 3 - @edge / 3
    @buttonInspect.setPosition new Point(x, y)
    @buttonInspect.setExtent new Point(w, h)
    #
    # edit button
    x = @buttonInspect.right() + @edge
    @buttonEdit.setPosition new Point(x, y)
    @buttonEdit.setExtent new Point(w, h)
    #
    # close button
    x = @buttonEdit.right() + @edge
    r = @detail.right() - @edge - WorldMorph.MorphicPreferences.handleSize
    w = r - x
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
    @fixLayout()
  
  
  #InspectorMorph editing ops:
  save: ->
    txt = @detail.contents.children[0].text.toString()
    prop = @list.selected
    try
      #
      # this.target[prop] = evaluate(txt);
      @target.evaluateString "this." + prop + " = " + txt
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    catch err
      @inform err
  
  addProperty: ->
    @prompt "new property name:", ((prop) =>
      if prop
        @target[prop] = null
        @buildPanes()
        if @target.updateRendering
          @target.changed()
          @target.updateRendering()
          @target.changed()
    ), @, "property" # Chrome cannot handle empty strings (others do)
  
  renameProperty: ->
    propertyName = @list.selected
    @prompt "property name:", ((prop) =>
      try
        delete (@target[propertyName])
        @target[prop] = @currentProperty
      catch err
        @inform err
      @buildPanes()
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    ), @, propertyName
  
  removeProperty: ->
    prop = @list.selected
    try
      delete (@target[prop])
      #
      @currentProperty = null
      @buildPanes()
      if @target.updateRendering
        @target.changed()
        @target.updateRendering()
        @target.changed()
    catch err
      @inform err
  '''
# MenuMorph ///////////////////////////////////////////////////////////

class MenuMorph extends BoxMorph

  target: null
  title: null
  environment: null
  fontSize: null
  items: null
  label: null
  world: null
  isListContents: false

  constructor: (@target, @title = null, @environment = null, @fontSize = null) ->
    # Note that Morph does a updateRendering upon creation (TODO Why?), so we need
    # to initialise the items before calling super. We can't initialise it
    # outside the constructor because the array would be shared across instantiated
    # objects.
    @items = []
    super()
    @border = null # the Box Morph constructor puts this to 2
    # important not to traverse all the children for stepping through, because
    # there could be a lot of entries for example in the inspector the number
    # of properties of an object - there could be a 100 of those and we don't
    # want to traverse them all. Setting step to null (as opposed to nop) means
    # that
  
  addItem: (
      labelString,
      action,
      hint,
      color,
      bold = false,
      italic = false,
      doubleClickAction # optional, when used as list contents
      ) ->
    # labelString is normally a single-line string. But it can also be one
    # of the following:
    #     * a multi-line string (containing line breaks)
    #     * an icon (either a Morph or a Canvas)
    #     * a tuple of format: [icon, string]
    @items.push [
      localize(labelString or "close"),
      action or nop,
      hint,
      color,
      bold,
      italic,
      doubleClickAction
    ]
  
  addLine: (width) ->
    @items.push [0, width or 1]
  
  createLabel: ->
    @label.destroy()  if @label isnt null
    text = new TextMorph(localize(@title),
      @fontSize or WorldMorph.MorphicPreferences.menuFontSize,
      WorldMorph.MorphicPreferences.menuFontName, true, false, "center")
    text.alignment = "center"
    text.color = new Color(255, 255, 255)
    text.backgroundColor = @borderColor
    text.updateRendering()
    @label = new BoxMorph(3, 0)
    if WorldMorph.MorphicPreferences.isFlat
      @label.edge = 0
    @label.color = @borderColor
    @label.borderColor = @borderColor
    @label.setExtent text.extent().add(4)
    @label.updateRendering()
    @label.add text
    @label.text = text
  
  updateRendering: ->
    isLine = false
    @children.forEach (m) ->
      m.destroy()
    #
    @children = []
    unless @isListContents
      @edge = if WorldMorph.MorphicPreferences.isFlat then 0 else 5
      @border = if WorldMorph.MorphicPreferences.isFlat then 1 else 2
    @color = new Color(255, 255, 255)
    @borderColor = new Color(60, 60, 60)
    @silentSetExtent new Point(0, 0)
    y = 2
    x = @left() + 4
    unless @isListContents
      if @title
        @createLabel()
        @label.setPosition @bounds.origin.add(4)
        @add @label
        y = @label.bottom()
      else
        y = @top() + 4
    y += 1
    @items.forEach (tuple) =>
      isLine = false
      if tuple instanceof StringFieldMorph or
        tuple instanceof ColorPickerMorph or
        tuple instanceof SliderMorph
          item = tuple
      else if tuple[0] is 0
        isLine = true
        item = new Morph()
        item.color = @borderColor
        item.setHeight tuple[1]
      else
        # bubble help hint
        item = new MenuItemMorph(
          @target,
          tuple[1],
          tuple[0],
          @fontSize or WorldMorph.MorphicPreferences.menuFontSize,
          WorldMorph.MorphicPreferences.menuFontName, @environment,
          tuple[2],
          tuple[3], # color
          tuple[4], # bold
          tuple[5], # italic
          tuple[6]  # doubleclick action
          )
      y += 1  if isLine
      item.setPosition new Point(x, y)
      @add item
      y = y + item.height()
      y += 1  if isLine
    #
    fb = @boundsIncludingChildren()
    @silentSetExtent fb.extent().add(4)
    @adjustWidths()
    super()
  
  maxWidth: ->
    w = 0
    if @parent instanceof FrameMorph
      if @parent.scrollFrame instanceof ScrollFrameMorph
        w = @parent.scrollFrame.width()    
    @children.forEach (item) ->
      if (item instanceof MenuItemMorph)
        w = Math.max(w, item.children[0].width() + 8)
      else if (item instanceof StringFieldMorph) or
        (item instanceof ColorPickerMorph) or
        (item instanceof SliderMorph)
          w = Math.max(w, item.width())  
    #
    w = Math.max(w, @label.width())  if @label
    w
  
  adjustWidths: ->
    w = @maxWidth()
    @children.forEach (item) =>
      item.silentSetWidth w
      if item instanceof MenuItemMorph
        isSelected = (item.image == item.pressImage)
        item.createBackgrounds()
        if isSelected then item.image = item.pressImage          
      else
        item.updateRendering()
        if item is @label
          item.text.setPosition item.center().subtract(item.text.extent().floorDivideBy(2))
  
  
  unselectAllItems: ->
    @children.forEach (item) ->
      item.image = item.normalImage  if item instanceof MenuItemMorph
    #
    @changed()
  
  popup: (world, pos) ->
    @updateRendering()
    @setPosition pos
    @addShadow new Point(2, 2), 80
    @keepWithin world
    world.activeMenu.destroy()  if world.activeMenu
    world.add @
    world.activeMenu = @
    @fullChanged()
  
  popUpAtHand: (world) ->
    wrrld = world or @world
    @popup wrrld, wrrld.hand.position()
  
  popUpCenteredAtHand: (world) ->
    wrrld = world or @world
    @updateRendering()
    @popup wrrld, wrrld.hand.position().subtract(@extent().floorDivideBy(2))
  
  popUpCenteredInWorld: (world) ->
    wrrld = world or @world
    @updateRendering()
    @popup wrrld, wrrld.center().subtract(@extent().floorDivideBy(2))

  @coffeeScriptSourceOfThisClass: '''
# MenuMorph ///////////////////////////////////////////////////////////

class MenuMorph extends BoxMorph

  target: null
  title: null
  environment: null
  fontSize: null
  items: null
  label: null
  world: null
  isListContents: false

  constructor: (@target, @title = null, @environment = null, @fontSize = null) ->
    # Note that Morph does a updateRendering upon creation (TODO Why?), so we need
    # to initialise the items before calling super. We can't initialise it
    # outside the constructor because the array would be shared across instantiated
    # objects.
    @items = []
    super()
    @border = null # the Box Morph constructor puts this to 2
    # important not to traverse all the children for stepping through, because
    # there could be a lot of entries for example in the inspector the number
    # of properties of an object - there could be a 100 of those and we don't
    # want to traverse them all. Setting step to null (as opposed to nop) means
    # that
  
  addItem: (
      labelString,
      action,
      hint,
      color,
      bold = false,
      italic = false,
      doubleClickAction # optional, when used as list contents
      ) ->
    # labelString is normally a single-line string. But it can also be one
    # of the following:
    #     * a multi-line string (containing line breaks)
    #     * an icon (either a Morph or a Canvas)
    #     * a tuple of format: [icon, string]
    @items.push [
      localize(labelString or "close"),
      action or nop,
      hint,
      color,
      bold,
      italic,
      doubleClickAction
    ]
  
  addLine: (width) ->
    @items.push [0, width or 1]
  
  createLabel: ->
    @label.destroy()  if @label isnt null
    text = new TextMorph(localize(@title),
      @fontSize or WorldMorph.MorphicPreferences.menuFontSize,
      WorldMorph.MorphicPreferences.menuFontName, true, false, "center")
    text.alignment = "center"
    text.color = new Color(255, 255, 255)
    text.backgroundColor = @borderColor
    text.updateRendering()
    @label = new BoxMorph(3, 0)
    if WorldMorph.MorphicPreferences.isFlat
      @label.edge = 0
    @label.color = @borderColor
    @label.borderColor = @borderColor
    @label.setExtent text.extent().add(4)
    @label.updateRendering()
    @label.add text
    @label.text = text
  
  updateRendering: ->
    isLine = false
    @children.forEach (m) ->
      m.destroy()
    #
    @children = []
    unless @isListContents
      @edge = if WorldMorph.MorphicPreferences.isFlat then 0 else 5
      @border = if WorldMorph.MorphicPreferences.isFlat then 1 else 2
    @color = new Color(255, 255, 255)
    @borderColor = new Color(60, 60, 60)
    @silentSetExtent new Point(0, 0)
    y = 2
    x = @left() + 4
    unless @isListContents
      if @title
        @createLabel()
        @label.setPosition @bounds.origin.add(4)
        @add @label
        y = @label.bottom()
      else
        y = @top() + 4
    y += 1
    @items.forEach (tuple) =>
      isLine = false
      if tuple instanceof StringFieldMorph or
        tuple instanceof ColorPickerMorph or
        tuple instanceof SliderMorph
          item = tuple
      else if tuple[0] is 0
        isLine = true
        item = new Morph()
        item.color = @borderColor
        item.setHeight tuple[1]
      else
        # bubble help hint
        item = new MenuItemMorph(
          @target,
          tuple[1],
          tuple[0],
          @fontSize or WorldMorph.MorphicPreferences.menuFontSize,
          WorldMorph.MorphicPreferences.menuFontName, @environment,
          tuple[2],
          tuple[3], # color
          tuple[4], # bold
          tuple[5], # italic
          tuple[6]  # doubleclick action
          )
      y += 1  if isLine
      item.setPosition new Point(x, y)
      @add item
      y = y + item.height()
      y += 1  if isLine
    #
    fb = @boundsIncludingChildren()
    @silentSetExtent fb.extent().add(4)
    @adjustWidths()
    super()
  
  maxWidth: ->
    w = 0
    if @parent instanceof FrameMorph
      if @parent.scrollFrame instanceof ScrollFrameMorph
        w = @parent.scrollFrame.width()    
    @children.forEach (item) ->
      if (item instanceof MenuItemMorph)
        w = Math.max(w, item.children[0].width() + 8)
      else if (item instanceof StringFieldMorph) or
        (item instanceof ColorPickerMorph) or
        (item instanceof SliderMorph)
          w = Math.max(w, item.width())  
    #
    w = Math.max(w, @label.width())  if @label
    w
  
  adjustWidths: ->
    w = @maxWidth()
    @children.forEach (item) =>
      item.silentSetWidth w
      if item instanceof MenuItemMorph
        isSelected = (item.image == item.pressImage)
        item.createBackgrounds()
        if isSelected then item.image = item.pressImage          
      else
        item.updateRendering()
        if item is @label
          item.text.setPosition item.center().subtract(item.text.extent().floorDivideBy(2))
  
  
  unselectAllItems: ->
    @children.forEach (item) ->
      item.image = item.normalImage  if item instanceof MenuItemMorph
    #
    @changed()
  
  popup: (world, pos) ->
    @updateRendering()
    @setPosition pos
    @addShadow new Point(2, 2), 80
    @keepWithin world
    world.activeMenu.destroy()  if world.activeMenu
    world.add @
    world.activeMenu = @
    @fullChanged()
  
  popUpAtHand: (world) ->
    wrrld = world or @world
    @popup wrrld, wrrld.hand.position()
  
  popUpCenteredAtHand: (world) ->
    wrrld = world or @world
    @updateRendering()
    @popup wrrld, wrrld.hand.position().subtract(@extent().floorDivideBy(2))
  
  popUpCenteredInWorld: (world) ->
    wrrld = world or @world
    @updateRendering()
    @popup wrrld, wrrld.center().subtract(@extent().floorDivideBy(2))
  '''
# BouncerMorph ////////////////////////////////////////////////////////
# fishy constructor
# I am a Demo of a stepping custom Morph
# Bounces vertically or horizontally within the parent

class BouncerMorph extends Morph

  isStopped: false
  type: null
  direction: null
  speed: null

  constructor: (@type = "vertical", @speed = 1) ->
    super()
    @fps = 50
    # additional properties:
    if @type is "vertical"
      @direction = "down"
    else
      @direction = "right"
  
  
  # BouncerMorph moving:
  moveUp: ->
    @moveBy new Point(0, -@speed)
  
  moveDown: ->
    @moveBy new Point(0, @speed)
  
  moveRight: ->
    @moveBy new Point(@speed, 0)
  
  moveLeft: ->
    @moveBy new Point(-@speed, 0)
  
  
  # BouncerMorph stepping:
  step: ->
    unless @isStopped
      if @type is "vertical"
        if @direction is "down"
          @moveDown()
        else
          @moveUp()
        @direction = "down"  if @boundsIncludingChildren().top() < @parent.top() and @direction is "up"
        @direction = "up"  if @boundsIncludingChildren().bottom() > @parent.bottom() and @direction is "down"
      else if @type is "horizontal"
        if @direction is "right"
          @moveRight()
        else
          @moveLeft()
        @direction = "right"  if @boundsIncludingChildren().left() < @parent.left() and @direction is "left"
        @direction = "left"  if @boundsIncludingChildren().right() > @parent.right() and @direction is "right"

  @coffeeScriptSourceOfThisClass: '''
# BouncerMorph ////////////////////////////////////////////////////////
# fishy constructor
# I am a Demo of a stepping custom Morph
# Bounces vertically or horizontally within the parent

class BouncerMorph extends Morph

  isStopped: false
  type: null
  direction: null
  speed: null

  constructor: (@type = "vertical", @speed = 1) ->
    super()
    @fps = 50
    # additional properties:
    if @type is "vertical"
      @direction = "down"
    else
      @direction = "right"
  
  
  # BouncerMorph moving:
  moveUp: ->
    @moveBy new Point(0, -@speed)
  
  moveDown: ->
    @moveBy new Point(0, @speed)
  
  moveRight: ->
    @moveBy new Point(@speed, 0)
  
  moveLeft: ->
    @moveBy new Point(-@speed, 0)
  
  
  # BouncerMorph stepping:
  step: ->
    unless @isStopped
      if @type is "vertical"
        if @direction is "down"
          @moveDown()
        else
          @moveUp()
        @direction = "down"  if @boundsIncludingChildren().top() < @parent.top() and @direction is "up"
        @direction = "up"  if @boundsIncludingChildren().bottom() > @parent.bottom() and @direction is "down"
      else if @type is "horizontal"
        if @direction is "right"
          @moveRight()
        else
          @moveLeft()
        @direction = "right"  if @boundsIncludingChildren().left() < @parent.left() and @direction is "left"
        @direction = "left"  if @boundsIncludingChildren().right() > @parent.right() and @direction is "right"
  '''
# Rectangles //////////////////////////////////////////////////////////

class Rectangle

  origin: null
  corner: null
  
  constructor: (left, top, right, bottom) ->
    
    @origin = new Point((left or 0), (top or 0))
    @corner = new Point((right or 0), (bottom or 0))
  
  
  # Rectangle string representation: e.g. '[0@0 | 160@80]'
  toString: ->
    "[" + @origin.toString() + " | " + @extent().toString() + "]"
  
  # Rectangle copying:
  copy: ->
    new Rectangle(@left(), @top(), @right(), @bottom())
  
  # Rectangle accessing - setting:
  setTo: (left, top, right, bottom) ->
    # note: all inputs are optional and can be omitted
    @origin = new Point(
      left or ((if (left is 0) then 0 else @left())),
      top or ((if (top is 0) then 0 else @top())))
    @corner = new Point(
      right or ((if (right is 0) then 0 else @right())),
      bottom or ((if (bottom is 0) then 0 else @bottom())))
  
  # Rectangle accessing - getting:
  area: ->
    #requires width() and height() to be defined
    w = @width()
    return 0  if w < 0
    Math.max w * @height(), 0
  
  bottom: ->
    @corner.y
  
  bottomCenter: ->
    new Point(@center().x, @bottom())
  
  bottomLeft: ->
    new Point(@origin.x, @corner.y)
  
  bottomRight: ->
    @corner.copy()
  
  boundingBox: ->
    @
  
  center: ->
    @origin.add @corner.subtract(@origin).floorDivideBy(2)
  
  corners: ->
    [@origin, @bottomLeft(), @corner, @topRight()]
  
  extent: ->
    @corner.subtract @origin
  
  isEmpty: ->
    # The subtract method creates a new Point
    theExtent = @corner.subtract @origin
    theExtent.x = 0 or theExtent.y = 0

  isNotEmpty: ->
    # The subtract method creates a new Point
    theExtent = @corner.subtract @origin
    theExtent.x > 0 and theExtent.y > 0
  
  height: ->
    @corner.y - @origin.y
  
  left: ->
    @origin.x
  
  leftCenter: ->
    new Point(@left(), @center().y)
  
  right: ->
    @corner.x
  
  rightCenter: ->
    new Point(@right(), @center().y)
  
  top: ->
    @origin.y
  
  topCenter: ->
    new Point(@center().x, @top())
  
  topLeft: ->
    @origin
  
  topRight: ->
    new Point(@corner.x, @origin.y)
  
  width: ->
    @corner.x - @origin.x
  
  position: ->
    @origin
  
  # Rectangle comparison:
  eq: (aRect) ->
    @origin.eq(aRect.origin) and @corner.eq(aRect.corner)
  
  abs: ->
    newOrigin = @origin.abs()
    newCorner = @corner.max(newOrigin)
    newOrigin.corner newCorner
  
  # Rectangle functions:
  insetBy: (delta) ->
    # delta can be either a Point or a Number
    result = new Rectangle()
    result.origin = @origin.add(delta)
    result.corner = @corner.subtract(delta)
    result
  
  expandBy: (delta) ->
    # delta can be either a Point or a Number
    result = new Rectangle()
    result.origin = @origin.subtract(delta)
    result.corner = @corner.add(delta)
    result
  
  growBy: (delta) ->
    # delta can be either a Point or a Number
    result = new Rectangle()
    result.origin = @origin.copy()
    result.corner = @corner.add(delta)
    result
  
  intersect: (aRect) ->
    result = new Rectangle()
    result.origin = @origin.max(aRect.origin)
    result.corner = @corner.min(aRect.corner)
    result
  
  merge: (aRect) ->
    result = new Rectangle()
    result.origin = @origin.min(aRect.origin)
    result.corner = @corner.max(aRect.corner)
    result
  
  round: ->
    @origin.round().corner @corner.round()
  
  spread: ->
    # round me by applying floor() to my origin and ceil() to my corner
    @origin.floor().corner @corner.ceil()
  
  amountToTranslateWithin: (aRect) ->
    #
    #    Answer a Point, delta, such that self + delta is forced within
    #    aRectangle. when all of me cannot be made to fit, prefer to keep
    #    my topLeft inside. Taken from Squeak.
    #
    dx = aRect.right() - @right()  if @right() > aRect.right()
    dy = aRect.bottom() - @bottom()  if @bottom() > aRect.bottom()
    dx = aRect.left() - @right()  if (@left() + dx) < aRect.left()
    dy = aRect.top() - @top()  if (@top() + dy) < aRect.top()
    new Point(dx, dy)
  
  
  # Rectangle testing:
  containsPoint: (aPoint) ->
    @origin.le(aPoint) and aPoint.lt(@corner)
  
  containsRectangle: (aRect) ->
    aRect.origin.gt(@origin) and aRect.corner.lt(@corner)
  
  intersects: (aRect) ->
    ro = aRect.origin
    rc = aRect.corner
    (rc.x >= @origin.x) and
      (rc.y >= @origin.y) and
      (ro.x <= @corner.x) and
      (ro.y <= @corner.y)
  
  
  # Rectangle transforming:
  scaleBy: (scale) ->
    # scale can be either a Point or a scalar
    o = @origin.multiplyBy(scale)
    c = @corner.multiplyBy(scale)
    new Rectangle(o.x, o.y, c.x, c.y)
  
  translateBy: (factor) ->
    # factor can be either a Point or a scalar
    o = @origin.add(factor)
    c = @corner.add(factor)
    new Rectangle(o.x, o.y, c.x, c.y)
  
  
  # Rectangle converting:
  asArray: ->
    [@left(), @top(), @right(), @bottom()]
  
  asArray_xywh: ->
    [@left(), @top(), @width(), @height()]

  @coffeeScriptSourceOfThisClass: '''
# Rectangles //////////////////////////////////////////////////////////

class Rectangle

  origin: null
  corner: null
  
  constructor: (left, top, right, bottom) ->
    
    @origin = new Point((left or 0), (top or 0))
    @corner = new Point((right or 0), (bottom or 0))
  
  
  # Rectangle string representation: e.g. '[0@0 | 160@80]'
  toString: ->
    "[" + @origin.toString() + " | " + @extent().toString() + "]"
  
  # Rectangle copying:
  copy: ->
    new Rectangle(@left(), @top(), @right(), @bottom())
  
  # Rectangle accessing - setting:
  setTo: (left, top, right, bottom) ->
    # note: all inputs are optional and can be omitted
    @origin = new Point(
      left or ((if (left is 0) then 0 else @left())),
      top or ((if (top is 0) then 0 else @top())))
    @corner = new Point(
      right or ((if (right is 0) then 0 else @right())),
      bottom or ((if (bottom is 0) then 0 else @bottom())))
  
  # Rectangle accessing - getting:
  area: ->
    #requires width() and height() to be defined
    w = @width()
    return 0  if w < 0
    Math.max w * @height(), 0
  
  bottom: ->
    @corner.y
  
  bottomCenter: ->
    new Point(@center().x, @bottom())
  
  bottomLeft: ->
    new Point(@origin.x, @corner.y)
  
  bottomRight: ->
    @corner.copy()
  
  boundingBox: ->
    @
  
  center: ->
    @origin.add @corner.subtract(@origin).floorDivideBy(2)
  
  corners: ->
    [@origin, @bottomLeft(), @corner, @topRight()]
  
  extent: ->
    @corner.subtract @origin
  
  isEmpty: ->
    # The subtract method creates a new Point
    theExtent = @corner.subtract @origin
    theExtent.x = 0 or theExtent.y = 0

  isNotEmpty: ->
    # The subtract method creates a new Point
    theExtent = @corner.subtract @origin
    theExtent.x > 0 and theExtent.y > 0
  
  height: ->
    @corner.y - @origin.y
  
  left: ->
    @origin.x
  
  leftCenter: ->
    new Point(@left(), @center().y)
  
  right: ->
    @corner.x
  
  rightCenter: ->
    new Point(@right(), @center().y)
  
  top: ->
    @origin.y
  
  topCenter: ->
    new Point(@center().x, @top())
  
  topLeft: ->
    @origin
  
  topRight: ->
    new Point(@corner.x, @origin.y)
  
  width: ->
    @corner.x - @origin.x
  
  position: ->
    @origin
  
  # Rectangle comparison:
  eq: (aRect) ->
    @origin.eq(aRect.origin) and @corner.eq(aRect.corner)
  
  abs: ->
    newOrigin = @origin.abs()
    newCorner = @corner.max(newOrigin)
    newOrigin.corner newCorner
  
  # Rectangle functions:
  insetBy: (delta) ->
    # delta can be either a Point or a Number
    result = new Rectangle()
    result.origin = @origin.add(delta)
    result.corner = @corner.subtract(delta)
    result
  
  expandBy: (delta) ->
    # delta can be either a Point or a Number
    result = new Rectangle()
    result.origin = @origin.subtract(delta)
    result.corner = @corner.add(delta)
    result
  
  growBy: (delta) ->
    # delta can be either a Point or a Number
    result = new Rectangle()
    result.origin = @origin.copy()
    result.corner = @corner.add(delta)
    result
  
  intersect: (aRect) ->
    result = new Rectangle()
    result.origin = @origin.max(aRect.origin)
    result.corner = @corner.min(aRect.corner)
    result
  
  merge: (aRect) ->
    result = new Rectangle()
    result.origin = @origin.min(aRect.origin)
    result.corner = @corner.max(aRect.corner)
    result
  
  round: ->
    @origin.round().corner @corner.round()
  
  spread: ->
    # round me by applying floor() to my origin and ceil() to my corner
    @origin.floor().corner @corner.ceil()
  
  amountToTranslateWithin: (aRect) ->
    #
    #    Answer a Point, delta, such that self + delta is forced within
    #    aRectangle. when all of me cannot be made to fit, prefer to keep
    #    my topLeft inside. Taken from Squeak.
    #
    dx = aRect.right() - @right()  if @right() > aRect.right()
    dy = aRect.bottom() - @bottom()  if @bottom() > aRect.bottom()
    dx = aRect.left() - @right()  if (@left() + dx) < aRect.left()
    dy = aRect.top() - @top()  if (@top() + dy) < aRect.top()
    new Point(dx, dy)
  
  
  # Rectangle testing:
  containsPoint: (aPoint) ->
    @origin.le(aPoint) and aPoint.lt(@corner)
  
  containsRectangle: (aRect) ->
    aRect.origin.gt(@origin) and aRect.corner.lt(@corner)
  
  intersects: (aRect) ->
    ro = aRect.origin
    rc = aRect.corner
    (rc.x >= @origin.x) and
      (rc.y >= @origin.y) and
      (ro.x <= @corner.x) and
      (ro.y <= @corner.y)
  
  
  # Rectangle transforming:
  scaleBy: (scale) ->
    # scale can be either a Point or a scalar
    o = @origin.multiplyBy(scale)
    c = @corner.multiplyBy(scale)
    new Rectangle(o.x, o.y, c.x, c.y)
  
  translateBy: (factor) ->
    # factor can be either a Point or a scalar
    o = @origin.add(factor)
    c = @corner.add(factor)
    new Rectangle(o.x, o.y, c.x, c.y)
  
  
  # Rectangle converting:
  asArray: ->
    [@left(), @top(), @right(), @bottom()]
  
  asArray_xywh: ->
    [@left(), @top(), @width(), @height()]
  '''
# SliderButtonMorph ///////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class SliderButtonMorph extends CircleBoxMorph

  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(90, 90, 140)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(80, 80, 160)
  is3D: false
  hasMiddleDip: true

  constructor: (orientation) ->
    @color = new Color(80, 80, 80)
    super orientation
  
  autoOrientation: ->
      noOperation
  
  updateRendering: ->
    colorBak = @color.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @normalImage = @image
    @color = @highlightColor.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @highlightImage = @image
    @color = @pressColor.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @pressImage = @image
    @color = colorBak
    @image = @normalImage
  
  drawEdges: ->
    context = @image.getContext("2d")
    w = @width()
    h = @height()
    context.lineJoin = "round"
    context.lineCap = "round"
    if @orientation is "vertical"
      context.lineWidth = w / 3
      gradient = context.createLinearGradient(0, 0, context.lineWidth, 0)
      gradient.addColorStop 0, "white"
      gradient.addColorStop 1, @color.toString()
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo context.lineWidth * 0.5, w / 2
      context.lineTo context.lineWidth * 0.5, h - w / 2
      context.stroke()
      gradient = context.createLinearGradient(w - context.lineWidth, 0, w, 0)
      gradient.addColorStop 0, @color.toString()
      gradient.addColorStop 1, "black"
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo w - context.lineWidth * 0.5, w / 2
      context.lineTo w - context.lineWidth * 0.5, h - w / 2
      context.stroke()
      if @hasMiddleDip
        gradient = context.createLinearGradient(
          context.lineWidth, 0, w - context.lineWidth, 0)
        radius = w / 4
        gradient.addColorStop 0, "black"
        gradient.addColorStop 0.35, @color.toString()
        gradient.addColorStop 0.65, @color.toString()
        gradient.addColorStop 1, "white"
        context.fillStyle = gradient
        context.beginPath()
        context.arc w / 2, h / 2, radius, radians(0), radians(360), false
        context.closePath()
        context.fill()
    else if @orientation is "horizontal"
      context.lineWidth = h / 3
      gradient = context.createLinearGradient(0, 0, 0, context.lineWidth)
      gradient.addColorStop 0, "white"
      gradient.addColorStop 1, @color.toString()
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo h / 2, context.lineWidth * 0.5
      context.lineTo w - h / 2, context.lineWidth * 0.5
      context.stroke()
      gradient = context.createLinearGradient(0, h - context.lineWidth, 0, h)
      gradient.addColorStop 0, @color.toString()
      gradient.addColorStop 1, "black"
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo h / 2, h - context.lineWidth * 0.5
      context.lineTo w - h / 2, h - context.lineWidth * 0.5
      context.stroke()
      if @hasMiddleDip
        gradient = context.createLinearGradient(
          0, context.lineWidth, 0, h - context.lineWidth)
        radius = h / 4
        gradient.addColorStop 0, "black"
        gradient.addColorStop 0.35, @color.toString()
        gradient.addColorStop 0.65, @color.toString()
        gradient.addColorStop 1, "white"
        context.fillStyle = gradient
        context.beginPath()
        context.arc @width() / 2, @height() / 2, radius, radians(0), radians(360), false
        context.closePath()
        context.fill()
  
  
  #SliderButtonMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
  
  mouseDownLeft: (pos) ->
    @image = @pressImage
    @changed()
    @escalateEvent "mouseDownLeft", pos
  
  mouseClickLeft: ->
    @image = @highlightImage
    @changed()
  
  # prevent my parent from getting picked up
  mouseMove: ->
      noOperation

  @coffeeScriptSourceOfThisClass: '''
# SliderButtonMorph ///////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class SliderButtonMorph extends CircleBoxMorph

  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(90, 90, 140)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(80, 80, 160)
  is3D: false
  hasMiddleDip: true

  constructor: (orientation) ->
    @color = new Color(80, 80, 80)
    super orientation
  
  autoOrientation: ->
      noOperation
  
  updateRendering: ->
    colorBak = @color.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @normalImage = @image
    @color = @highlightColor.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @highlightImage = @image
    @color = @pressColor.copy()
    super()
    if @is3D or !WorldMorph.MorphicPreferences.isFlat
      @drawEdges()
    @pressImage = @image
    @color = colorBak
    @image = @normalImage
  
  drawEdges: ->
    context = @image.getContext("2d")
    w = @width()
    h = @height()
    context.lineJoin = "round"
    context.lineCap = "round"
    if @orientation is "vertical"
      context.lineWidth = w / 3
      gradient = context.createLinearGradient(0, 0, context.lineWidth, 0)
      gradient.addColorStop 0, "white"
      gradient.addColorStop 1, @color.toString()
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo context.lineWidth * 0.5, w / 2
      context.lineTo context.lineWidth * 0.5, h - w / 2
      context.stroke()
      gradient = context.createLinearGradient(w - context.lineWidth, 0, w, 0)
      gradient.addColorStop 0, @color.toString()
      gradient.addColorStop 1, "black"
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo w - context.lineWidth * 0.5, w / 2
      context.lineTo w - context.lineWidth * 0.5, h - w / 2
      context.stroke()
      if @hasMiddleDip
        gradient = context.createLinearGradient(
          context.lineWidth, 0, w - context.lineWidth, 0)
        radius = w / 4
        gradient.addColorStop 0, "black"
        gradient.addColorStop 0.35, @color.toString()
        gradient.addColorStop 0.65, @color.toString()
        gradient.addColorStop 1, "white"
        context.fillStyle = gradient
        context.beginPath()
        context.arc w / 2, h / 2, radius, radians(0), radians(360), false
        context.closePath()
        context.fill()
    else if @orientation is "horizontal"
      context.lineWidth = h / 3
      gradient = context.createLinearGradient(0, 0, 0, context.lineWidth)
      gradient.addColorStop 0, "white"
      gradient.addColorStop 1, @color.toString()
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo h / 2, context.lineWidth * 0.5
      context.lineTo w - h / 2, context.lineWidth * 0.5
      context.stroke()
      gradient = context.createLinearGradient(0, h - context.lineWidth, 0, h)
      gradient.addColorStop 0, @color.toString()
      gradient.addColorStop 1, "black"
      context.strokeStyle = gradient
      context.beginPath()
      context.moveTo h / 2, h - context.lineWidth * 0.5
      context.lineTo w - h / 2, h - context.lineWidth * 0.5
      context.stroke()
      if @hasMiddleDip
        gradient = context.createLinearGradient(
          0, context.lineWidth, 0, h - context.lineWidth)
        radius = h / 4
        gradient.addColorStop 0, "black"
        gradient.addColorStop 0.35, @color.toString()
        gradient.addColorStop 0.65, @color.toString()
        gradient.addColorStop 1, "white"
        context.fillStyle = gradient
        context.beginPath()
        context.arc @width() / 2, @height() / 2, radius, radians(0), radians(360), false
        context.closePath()
        context.fill()
  
  
  #SliderButtonMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
  
  mouseDownLeft: (pos) ->
    @image = @pressImage
    @changed()
    @escalateEvent "mouseDownLeft", pos
  
  mouseClickLeft: ->
    @image = @highlightImage
    @changed()
  
  # prevent my parent from getting picked up
  mouseMove: ->
      noOperation
  '''
# TextMorph ///////////////////////////////////////////////////////////

# I am a multi-line, word-wrapping String

# Note that in the original Jens' Morphic.js version he
# has made this quasi-inheriting from StringMorph i.e. he is copying
# over manually the following methods like so:
#
#  TextMorph::font = StringMorph::font
#  TextMorph::edit = StringMorph::edit
#  TextMorph::selection = StringMorph::selection
#  TextMorph::selectionStartSlot = StringMorph::selectionStartSlot
#  TextMorph::clearSelection = StringMorph::clearSelection
#  TextMorph::deleteSelection = StringMorph::deleteSelection
#  TextMorph::selectAll = StringMorph::selectAll
#  TextMorph::mouseClickLeft = StringMorph::mouseClickLeft
#  TextMorph::enableSelecting = StringMorph::enableSelecting 
#  TextMorph::disableSelecting = StringMorph::disableSelecting
#  TextMorph::toggleIsDraggable = StringMorph::toggleIsDraggable
#  TextMorph::toggleWeight = StringMorph::toggleWeight
#  TextMorph::toggleItalic = StringMorph::toggleItalic
#  TextMorph::setSerif = StringMorph::setSerif
#  TextMorph::setSansSerif = StringMorph::setSansSerif
#  TextMorph::setText = StringMorph::setText
#  TextMorph::setFontSize = StringMorph::setFontSize
#  TextMorph::numericalSetters = StringMorph::numericalSetters


class TextMorph extends StringMorph

  words: []
  lines: []
  lineSlots: []
  alignment: null
  maxWidth: null
  maxLineWidth: 0
  backgroundColor: null

  #additional properties for ad-hoc evaluation:
  receiver: null

  constructor: (
    text, @fontSize = 12, @fontStyle = "sans-serif", @isBold = false,
    @isItalic = false, @alignment = "left", @maxWidth = 0, fontName, shadowOffset,
    @shadowColor = null
    ) ->
      super()
      # override inherited properites:
      @markedTextColor = new Color(255, 255, 255)
      @markedBackgoundColor = new Color(60, 60, 120)
      @text = text or ((if text is "" then text else "TextMorph"))
      @fontName = fontName or WorldMorph.MorphicPreferences.globalFontFamily
      @shadowOffset = shadowOffset or new Point(0, 0)
      @color = new Color(0, 0, 0)
      @noticesTransparentClick = true
      @updateRendering()
  
  breakTextIntoLines: ->
    paragraphs = @text.split("\n")
    canvas = newCanvas()
    context = canvas.getContext("2d")
    currentLine = ""
    slot = 0
    context.font = @font()
    @maxLineWidth = 0
    @lines = []
    @lineSlots = [0]
    @words = []
    
    # put all the text in an array, word by word
    paragraphs.forEach (p) =>
      @words = @words.concat(p.split(" "))
      @words.push "\n"

    # takes the text, word by word, and re-flows
    # it according to the available width for the
    # text (if there is such limit).
    # The end result is an array of lines
    # called @lines, which contains the string for
    # each line (excluding the end of lines).
    # Also another array is created, called
    # @lineSlots, which memorises how many characters
    # of the text have been consumed up to each line
    #  example: original text: "Hello\nWorld"
    # then @lines[0] = "Hello" @lines[1] = "World"
    # and @lineSlots[0] = 6, @lineSlots[1] = 11
    # Note that this algorithm doesn't work in case
    # of single non-spaced words that are longer than
    # the allowed width.
    @words.forEach (word) =>
      if word is "\n"
        # we reached the end of the line in the
        # original text, so push the line and the
        # slots count in the arrays
        @lines.push currentLine
        @lineSlots.push slot
        @maxLineWidth = Math.max(@maxLineWidth, context.measureText(currentLine).width)
        currentLine = ""
      else
        if @maxWidth > 0
          # there is a width limit, so we need
          # to check whether we overflowed it. So create
          # a prospective line and then check its width.
          lineForOverflowTest = currentLine + word + " "
          w = context.measureText(lineForOverflowTest).width
          if w > @maxWidth
            # ok we just overflowed the available space,
            # so we need to push the old line and its
            # "slot" number to the respective arrays.
            # the new line is going to only contain the
            # word that has caused the overflow.
            @lines.push currentLine
            @lineSlots.push slot
            @maxLineWidth = Math.max(@maxLineWidth, context.measureText(currentLine).width)
            currentLine = word + " "
          else
            # no overflow happened, so just proceed as normal
            currentLine = lineForOverflowTest
        else
          currentLine = currentLine + word + " "
        slot += word.length + 1
  
  
  updateRendering: ->
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    @breakTextIntoLines()

    # set my extent
    shadowWidth = Math.abs(@shadowOffset.x)
    shadowHeight = Math.abs(@shadowOffset.y)
    height = @lines.length * (fontHeight(@fontSize) + shadowHeight)
    if @maxWidth is 0
      @bounds = @bounds.origin.extent(new Point(@maxLineWidth + shadowWidth, height))
    else
      @bounds = @bounds.origin.extent(new Point(@maxWidth + shadowWidth, height))
    @image.width = @width()
    @image.height = @height()

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # fill the background, if desired
    if @backgroundColor
      context.fillStyle = @backgroundColor.toString()
      context.fillRect 0, 0, @width(), @height()
    #
    # draw the shadow, if any
    if @shadowColor
      offx = Math.max(@shadowOffset.x, 0)
      offy = Math.max(@shadowOffset.y, 0)
      #console.log 'shadow x: ' + offx + " y: " + offy
      context.fillStyle = @shadowColor.toString()
      i = 0
      for line in @lines
        width = context.measureText(line).width + shadowWidth
        if @alignment is "right"
          x = @width() - width
        else if @alignment is "center"
          x = (@width() - width) / 2
        else # 'left'
          x = 0
        y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
        i++
        context.fillText line, x + offx, y + offy
    #
    # now draw the actual text
    offx = Math.abs(Math.min(@shadowOffset.x, 0))
    offy = Math.abs(Math.min(@shadowOffset.y, 0))
    #console.log 'maintext x: ' + offx + " y: " + offy
    context.fillStyle = @color.toString()
    i = 0
    for line in @lines
      width = context.measureText(line).width + shadowWidth
      if @alignment is "right"
        x = @width() - width
      else if @alignment is "center"
        x = (@width() - width) / 2
      else # 'left'
        x = 0
      y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
      i++
      context.fillText line, x + offx, y + offy

    # Draw the selection. This is done by re-drawing the
    # selected text, one character at the time, just with
    # a background rectangle.
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = @text.charAt(i)
      context.fillStyle = @markedBackgoundColor.toString()
      context.fillRect p.x, p.y, context.measureText(c).width + 1, fontHeight(@fontSize)
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x, p.y + fontHeight(@fontSize)
    #
    # notify my parent of layout change
    @parent.layoutChanged()  if @parent.layoutChanged  if @parent
  
  setExtent: (aPoint) ->
    @maxWidth = Math.max(aPoint.x, 0)
    @changed()
    @updateRendering()
  
  # TextMorph measuring ////

  # answer the logical position point of the given index ("slot")
  # i.e. the row and the column where a particular character is.
  slotRowAndColumn: (slot) ->
    idx = 0
    # Note that this solution scans all the characters
    # in all the rows up to the slot. This could be
    # done a lot quicker by stopping at the first row
    # such that @lineSlots[theRow] <= slot
    # You could even do a binary search if one really
    # wanted to, because the contents of @lineSlots are
    # in order, as they contain a cumulative count...
    for row in [0...@lines.length]
      idx = @lineSlots[row]
      for col in [0...@lines[row].length]
        return [row, col]  if idx is slot
        idx += 1
    [@lines.length - 1, @lines[@lines.length - 1].length - 1]
  
  # Answer the position (in pixels) of the given index ("slot")
  # where the caret should be placed.
  # This is in absolute world coordinates.
  # This function assumes that the text is left-justified.
  slotCoordinates: (slot) ->
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    context = @image.getContext("2d")
    shadowHeight = Math.abs(@shadowOffset.y)
    yOffset = slotRow * (fontHeight(@fontSize) + shadowHeight)
    xOffset = context.measureText((@lines[slotRow]).substring(0,slotColumn)).width
    x = @left() + xOffset
    y = @top() + yOffset
    new Point(x, y)
  
  # Returns the slot (index) closest to the given point
  # so the caret can be moved accordingly
  # This function assumes that the text is left-justified.
  slotAt: (aPoint) ->
    charX = 0
    row = 0
    col = 0
    shadowHeight = Math.abs(@shadowOffset.y)
    context = @image.getContext("2d")
    row += 1  while aPoint.y - @top() > ((fontHeight(@fontSize) + shadowHeight) * row)
    row = Math.max(row, 1)
    while aPoint.x - @left() > charX
      charX += context.measureText(@lines[row - 1][col]).width
      col += 1
    @lineSlots[Math.max(row - 1, 0)] + col - 1
  
  upFrom: (slot) ->
    # answer the slot above the given one
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    return slot  if slotRow < 1
    above = @lines[slotRow - 1]
    return @lineSlots[slotRow - 1] + above.length  if above.length < slotColumn - 1
    @lineSlots[slotRow - 1] + slotColumn
  
  downFrom: (slot) ->
    # answer the slot below the given one
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    return slot  if slotRow > @lines.length - 2
    below = @lines[slotRow + 1]
    return @lineSlots[slotRow + 1] + below.length  if below.length < slotColumn - 1
    @lineSlots[slotRow + 1] + slotColumn
  
  startOfLine: (slot) ->
    # answer the first slot (index) of the line for the given slot
    @lineSlots[@slotRowAndColumn(slot).y]
  
  endOfLine: (slot) ->
    # answer the slot (index) indicating the EOL for the given slot
    @startOfLine(slot) + @lines[@slotRowAndColumn(slot).y].length - 1
  
  # TextMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "edit", "edit"
    menu.addItem "font size...", (->
      @prompt menu.title + "\nfont\nsize:",
        @setFontSize, @, @fontSize.toString(), null, 6, 100, true
    ), "set this Text's\nfont point size"
    menu.addItem "align left", "setAlignmentToLeft"  if @alignment isnt "left"
    menu.addItem "align right", "setAlignmentToRight"  if @alignment isnt "right"
    menu.addItem "align center", "setAlignmentToCenter"  if @alignment isnt "center"
    menu.addLine()
    menu.addItem "serif", "setSerif"  if @fontStyle isnt "serif"
    menu.addItem "sans-serif", "setSansSerif"  if @fontStyle isnt "sans-serif"
    if @isBold
      menu.addItem "normal weight", "toggleWeight"
    else
      menu.addItem "bold", "toggleWeight"
    if @isItalic
      menu.addItem "normal style", "toggleItalic"
    else
      menu.addItem "italic", "toggleItalic"
    menu
  
  setAlignmentToLeft: ->
    @alignment = "left"
    @updateRendering()
    @changed()
  
  setAlignmentToRight: ->
    @alignment = "right"
    @updateRendering()
    @changed()
  
  setAlignmentToCenter: ->
    @alignment = "center"
    @updateRendering()
    @changed()  
  
  # TextMorph evaluation:
  evaluationMenu: ->
    menu = new MenuMorph(@, null)
    menu.addItem "do it", "doIt", "evaluate the\nselected expression"
    menu.addItem "show it", "showIt", "evaluate the\nselected expression\nand show the result"
    menu.addItem "inspect it", "inspectIt", "evaluate the\nselected expression\nand inspect the result"
    menu.addLine()
    menu.addItem "select all", "selectAllAndEdit"
    menu

  selectAllAndEdit: ->
    @edit()
    @selectAll()
   
  setReceiver: (obj) ->
    @receiver = obj
    @customContextMenu = @evaluationMenu()
  
  doIt: ->
    @receiver.evaluateString @selection()
    @edit()
  
  showIt: ->
    result = @receiver.evaluateString(@selection())
    if result? then @inform result
  
  inspectIt: ->
    # evaluateString is a pimped-up eval in
    # the Morph class.
    result = @receiver.evaluateString(@selection())
    if result? then @spawnInspector result

  @coffeeScriptSourceOfThisClass: '''
# TextMorph ///////////////////////////////////////////////////////////

# I am a multi-line, word-wrapping String

# Note that in the original Jens' Morphic.js version he
# has made this quasi-inheriting from StringMorph i.e. he is copying
# over manually the following methods like so:
#
#  TextMorph::font = StringMorph::font
#  TextMorph::edit = StringMorph::edit
#  TextMorph::selection = StringMorph::selection
#  TextMorph::selectionStartSlot = StringMorph::selectionStartSlot
#  TextMorph::clearSelection = StringMorph::clearSelection
#  TextMorph::deleteSelection = StringMorph::deleteSelection
#  TextMorph::selectAll = StringMorph::selectAll
#  TextMorph::mouseClickLeft = StringMorph::mouseClickLeft
#  TextMorph::enableSelecting = StringMorph::enableSelecting 
#  TextMorph::disableSelecting = StringMorph::disableSelecting
#  TextMorph::toggleIsDraggable = StringMorph::toggleIsDraggable
#  TextMorph::toggleWeight = StringMorph::toggleWeight
#  TextMorph::toggleItalic = StringMorph::toggleItalic
#  TextMorph::setSerif = StringMorph::setSerif
#  TextMorph::setSansSerif = StringMorph::setSansSerif
#  TextMorph::setText = StringMorph::setText
#  TextMorph::setFontSize = StringMorph::setFontSize
#  TextMorph::numericalSetters = StringMorph::numericalSetters


class TextMorph extends StringMorph

  words: []
  lines: []
  lineSlots: []
  alignment: null
  maxWidth: null
  maxLineWidth: 0
  backgroundColor: null

  #additional properties for ad-hoc evaluation:
  receiver: null

  constructor: (
    text, @fontSize = 12, @fontStyle = "sans-serif", @isBold = false,
    @isItalic = false, @alignment = "left", @maxWidth = 0, fontName, shadowOffset,
    @shadowColor = null
    ) ->
      super()
      # override inherited properites:
      @markedTextColor = new Color(255, 255, 255)
      @markedBackgoundColor = new Color(60, 60, 120)
      @text = text or ((if text is "" then text else "TextMorph"))
      @fontName = fontName or WorldMorph.MorphicPreferences.globalFontFamily
      @shadowOffset = shadowOffset or new Point(0, 0)
      @color = new Color(0, 0, 0)
      @noticesTransparentClick = true
      @updateRendering()
  
  breakTextIntoLines: ->
    paragraphs = @text.split("\n")
    canvas = newCanvas()
    context = canvas.getContext("2d")
    currentLine = ""
    slot = 0
    context.font = @font()
    @maxLineWidth = 0
    @lines = []
    @lineSlots = [0]
    @words = []
    
    # put all the text in an array, word by word
    paragraphs.forEach (p) =>
      @words = @words.concat(p.split(" "))
      @words.push "\n"

    # takes the text, word by word, and re-flows
    # it according to the available width for the
    # text (if there is such limit).
    # The end result is an array of lines
    # called @lines, which contains the string for
    # each line (excluding the end of lines).
    # Also another array is created, called
    # @lineSlots, which memorises how many characters
    # of the text have been consumed up to each line
    #  example: original text: "Hello\nWorld"
    # then @lines[0] = "Hello" @lines[1] = "World"
    # and @lineSlots[0] = 6, @lineSlots[1] = 11
    # Note that this algorithm doesn't work in case
    # of single non-spaced words that are longer than
    # the allowed width.
    @words.forEach (word) =>
      if word is "\n"
        # we reached the end of the line in the
        # original text, so push the line and the
        # slots count in the arrays
        @lines.push currentLine
        @lineSlots.push slot
        @maxLineWidth = Math.max(@maxLineWidth, context.measureText(currentLine).width)
        currentLine = ""
      else
        if @maxWidth > 0
          # there is a width limit, so we need
          # to check whether we overflowed it. So create
          # a prospective line and then check its width.
          lineForOverflowTest = currentLine + word + " "
          w = context.measureText(lineForOverflowTest).width
          if w > @maxWidth
            # ok we just overflowed the available space,
            # so we need to push the old line and its
            # "slot" number to the respective arrays.
            # the new line is going to only contain the
            # word that has caused the overflow.
            @lines.push currentLine
            @lineSlots.push slot
            @maxLineWidth = Math.max(@maxLineWidth, context.measureText(currentLine).width)
            currentLine = word + " "
          else
            # no overflow happened, so just proceed as normal
            currentLine = lineForOverflowTest
        else
          currentLine = currentLine + word + " "
        slot += word.length + 1
  
  
  updateRendering: ->
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    @breakTextIntoLines()

    # set my extent
    shadowWidth = Math.abs(@shadowOffset.x)
    shadowHeight = Math.abs(@shadowOffset.y)
    height = @lines.length * (fontHeight(@fontSize) + shadowHeight)
    if @maxWidth is 0
      @bounds = @bounds.origin.extent(new Point(@maxLineWidth + shadowWidth, height))
    else
      @bounds = @bounds.origin.extent(new Point(@maxWidth + shadowWidth, height))
    @image.width = @width()
    @image.height = @height()

    # changing the canvas size resets many of
    # the properties of the canvas, so we need to
    # re-initialise the font and alignments here
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"

    # fill the background, if desired
    if @backgroundColor
      context.fillStyle = @backgroundColor.toString()
      context.fillRect 0, 0, @width(), @height()
    #
    # draw the shadow, if any
    if @shadowColor
      offx = Math.max(@shadowOffset.x, 0)
      offy = Math.max(@shadowOffset.y, 0)
      #console.log 'shadow x: ' + offx + " y: " + offy
      context.fillStyle = @shadowColor.toString()
      i = 0
      for line in @lines
        width = context.measureText(line).width + shadowWidth
        if @alignment is "right"
          x = @width() - width
        else if @alignment is "center"
          x = (@width() - width) / 2
        else # 'left'
          x = 0
        y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
        i++
        context.fillText line, x + offx, y + offy
    #
    # now draw the actual text
    offx = Math.abs(Math.min(@shadowOffset.x, 0))
    offy = Math.abs(Math.min(@shadowOffset.y, 0))
    #console.log 'maintext x: ' + offx + " y: " + offy
    context.fillStyle = @color.toString()
    i = 0
    for line in @lines
      width = context.measureText(line).width + shadowWidth
      if @alignment is "right"
        x = @width() - width
      else if @alignment is "center"
        x = (@width() - width) / 2
      else # 'left'
        x = 0
      y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
      i++
      context.fillText line, x + offx, y + offy

    # Draw the selection. This is done by re-drawing the
    # selected text, one character at the time, just with
    # a background rectangle.
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    for i in [start...stop]
      p = @slotCoordinates(i).subtract(@position())
      c = @text.charAt(i)
      context.fillStyle = @markedBackgoundColor.toString()
      context.fillRect p.x, p.y, context.measureText(c).width + 1, fontHeight(@fontSize)
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x, p.y + fontHeight(@fontSize)
    #
    # notify my parent of layout change
    @parent.layoutChanged()  if @parent.layoutChanged  if @parent
  
  setExtent: (aPoint) ->
    @maxWidth = Math.max(aPoint.x, 0)
    @changed()
    @updateRendering()
  
  # TextMorph measuring ////

  # answer the logical position point of the given index ("slot")
  # i.e. the row and the column where a particular character is.
  slotRowAndColumn: (slot) ->
    idx = 0
    # Note that this solution scans all the characters
    # in all the rows up to the slot. This could be
    # done a lot quicker by stopping at the first row
    # such that @lineSlots[theRow] <= slot
    # You could even do a binary search if one really
    # wanted to, because the contents of @lineSlots are
    # in order, as they contain a cumulative count...
    for row in [0...@lines.length]
      idx = @lineSlots[row]
      for col in [0...@lines[row].length]
        return [row, col]  if idx is slot
        idx += 1
    [@lines.length - 1, @lines[@lines.length - 1].length - 1]
  
  # Answer the position (in pixels) of the given index ("slot")
  # where the caret should be placed.
  # This is in absolute world coordinates.
  # This function assumes that the text is left-justified.
  slotCoordinates: (slot) ->
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    context = @image.getContext("2d")
    shadowHeight = Math.abs(@shadowOffset.y)
    yOffset = slotRow * (fontHeight(@fontSize) + shadowHeight)
    xOffset = context.measureText((@lines[slotRow]).substring(0,slotColumn)).width
    x = @left() + xOffset
    y = @top() + yOffset
    new Point(x, y)
  
  # Returns the slot (index) closest to the given point
  # so the caret can be moved accordingly
  # This function assumes that the text is left-justified.
  slotAt: (aPoint) ->
    charX = 0
    row = 0
    col = 0
    shadowHeight = Math.abs(@shadowOffset.y)
    context = @image.getContext("2d")
    row += 1  while aPoint.y - @top() > ((fontHeight(@fontSize) + shadowHeight) * row)
    row = Math.max(row, 1)
    while aPoint.x - @left() > charX
      charX += context.measureText(@lines[row - 1][col]).width
      col += 1
    @lineSlots[Math.max(row - 1, 0)] + col - 1
  
  upFrom: (slot) ->
    # answer the slot above the given one
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    return slot  if slotRow < 1
    above = @lines[slotRow - 1]
    return @lineSlots[slotRow - 1] + above.length  if above.length < slotColumn - 1
    @lineSlots[slotRow - 1] + slotColumn
  
  downFrom: (slot) ->
    # answer the slot below the given one
    [slotRow, slotColumn] = @slotRowAndColumn(slot)
    return slot  if slotRow > @lines.length - 2
    below = @lines[slotRow + 1]
    return @lineSlots[slotRow + 1] + below.length  if below.length < slotColumn - 1
    @lineSlots[slotRow + 1] + slotColumn
  
  startOfLine: (slot) ->
    # answer the first slot (index) of the line for the given slot
    @lineSlots[@slotRowAndColumn(slot).y]
  
  endOfLine: (slot) ->
    # answer the slot (index) indicating the EOL for the given slot
    @startOfLine(slot) + @lines[@slotRowAndColumn(slot).y].length - 1
  
  # TextMorph menus:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "edit", "edit"
    menu.addItem "font size...", (->
      @prompt menu.title + "\nfont\nsize:",
        @setFontSize, @, @fontSize.toString(), null, 6, 100, true
    ), "set this Text's\nfont point size"
    menu.addItem "align left", "setAlignmentToLeft"  if @alignment isnt "left"
    menu.addItem "align right", "setAlignmentToRight"  if @alignment isnt "right"
    menu.addItem "align center", "setAlignmentToCenter"  if @alignment isnt "center"
    menu.addLine()
    menu.addItem "serif", "setSerif"  if @fontStyle isnt "serif"
    menu.addItem "sans-serif", "setSansSerif"  if @fontStyle isnt "sans-serif"
    if @isBold
      menu.addItem "normal weight", "toggleWeight"
    else
      menu.addItem "bold", "toggleWeight"
    if @isItalic
      menu.addItem "normal style", "toggleItalic"
    else
      menu.addItem "italic", "toggleItalic"
    menu
  
  setAlignmentToLeft: ->
    @alignment = "left"
    @updateRendering()
    @changed()
  
  setAlignmentToRight: ->
    @alignment = "right"
    @updateRendering()
    @changed()
  
  setAlignmentToCenter: ->
    @alignment = "center"
    @updateRendering()
    @changed()  
  
  # TextMorph evaluation:
  evaluationMenu: ->
    menu = new MenuMorph(@, null)
    menu.addItem "do it", "doIt", "evaluate the\nselected expression"
    menu.addItem "show it", "showIt", "evaluate the\nselected expression\nand show the result"
    menu.addItem "inspect it", "inspectIt", "evaluate the\nselected expression\nand inspect the result"
    menu.addLine()
    menu.addItem "select all", "selectAllAndEdit"
    menu

  selectAllAndEdit: ->
    @edit()
    @selectAll()
   
  setReceiver: (obj) ->
    @receiver = obj
    @customContextMenu = @evaluationMenu()
  
  doIt: ->
    @receiver.evaluateString @selection()
    @edit()
  
  showIt: ->
    result = @receiver.evaluateString(@selection())
    if result? then @inform result
  
  inspectIt: ->
    # evaluateString is a pimped-up eval in
    # the Morph class.
    result = @receiver.evaluateString(@selection())
    if result? then @spawnInspector result
  '''
# WorkspaceMorph //////////////////////////////////////////////////////

class WorkspaceMorph extends BoxMorph

  # panes:
  morphsList: null
  buttonClose: null
  resizer: null
  closeIcon: null

  constructor: (target) ->
    super()

    @silentSetExtent new Point(
      WorldMorph.MorphicPreferences.handleSize * 10,
      WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @updateRendering()
    @buildPanes()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []

    # remove existing panes
    @children.forEach (m) ->
      # keep work pane around
      m.destroy()  if m isnt @work

    @children = []

    # label
    @label = new TextMorph("Morphs List")
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.updateRendering()
    @add @label

    @closeIcon = new CloseCircleButtonMorph()
    @closeIcon.color = new Color(255, 255, 255)
    @add @closeIcon
    @closeIcon.mouseClickLeft = =>
        @destroy()

    # Check which objects end with the word Morph
    theWordMorph = "Morph"
    ListOfMorphs = (Object.keys(window)).filter (i) ->
      i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
    @morphsList = new ListMorph(ListOfMorphs, null)

    # so far nothing happens when items are selected
    #@morphsList.action = (selected) ->
    #  val = myself.target[selected]
    #  myself.currentProperty = val
    #  if val is null
    #    txt = "NULL"
    #  else if isString(val)
    #    txt = val
    #  else
    #    txt = val.toString()
    #  cnts = new TextMorph(txt)
    #  cnts.isEditable = true
    #  cnts.enableSelecting()
    #  cnts.setReceiver myself.target
    #  myself.detail.setContents cnts

    @morphsList.hBar.alpha = 0.6
    @morphsList.vBar.alpha = 0.6
    @add @morphsList

    # close button
    @buttonClose = new TriggerMorph()
    @buttonClose.labelString = "close"
    @buttonClose.action = =>
      @destroy()

    @add @buttonClose

    # resizer
    @resizer = new HandleMorph(@, 150, 100, @edge, @edge)

    # update layout
    @fixLayout()
  
  fixLayout: ->
    Morph::trackChanges = false

    handleSize = WorldMorph.MorphicPreferences.handleSize;

    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x

    # close icon
    @closeIcon.setPosition new Point(x, y)
    closeIconScale = 2/3
    @closeIcon.setExtent new Point(handleSize * closeIconScale, handleSize * closeIconScale)

    # label
    @label.setPosition new Point(x + handleSize * closeIconScale + @edge, y - @edge/2)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @silentSetHeight @label.height() + 50
      @updateRendering()
      @changed()
      @resizer.updateRendering()

    # morphsList
    y = @label.bottom() + @edge/2
    w = @width() - @edge
    w -= @edge
    b = @bottom() - (2 * @edge) - handleSize
    h = b - y
    @morphsList.setPosition new Point(x, y)
    @morphsList.setExtent new Point(w, h)

    # close button
    x = @morphsList.left()
    y = @morphsList.bottom() + @edge
    h = handleSize
    w = @morphsList.width() - h - @edge
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
    @fixLayout()

  @coffeeScriptSourceOfThisClass: '''
# WorkspaceMorph //////////////////////////////////////////////////////

class WorkspaceMorph extends BoxMorph

  # panes:
  morphsList: null
  buttonClose: null
  resizer: null
  closeIcon: null

  constructor: (target) ->
    super()

    @silentSetExtent new Point(
      WorldMorph.MorphicPreferences.handleSize * 10,
      WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @updateRendering()
    @buildPanes()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []

    # remove existing panes
    @children.forEach (m) ->
      # keep work pane around
      m.destroy()  if m isnt @work

    @children = []

    # label
    @label = new TextMorph("Morphs List")
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.updateRendering()
    @add @label

    @closeIcon = new CloseCircleButtonMorph()
    @closeIcon.color = new Color(255, 255, 255)
    @add @closeIcon
    @closeIcon.mouseClickLeft = =>
        @destroy()

    # Check which objects end with the word Morph
    theWordMorph = "Morph"
    ListOfMorphs = (Object.keys(window)).filter (i) ->
      i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
    @morphsList = new ListMorph(ListOfMorphs, null)

    # so far nothing happens when items are selected
    #@morphsList.action = (selected) ->
    #  val = myself.target[selected]
    #  myself.currentProperty = val
    #  if val is null
    #    txt = "NULL"
    #  else if isString(val)
    #    txt = val
    #  else
    #    txt = val.toString()
    #  cnts = new TextMorph(txt)
    #  cnts.isEditable = true
    #  cnts.enableSelecting()
    #  cnts.setReceiver myself.target
    #  myself.detail.setContents cnts

    @morphsList.hBar.alpha = 0.6
    @morphsList.vBar.alpha = 0.6
    @add @morphsList

    # close button
    @buttonClose = new TriggerMorph()
    @buttonClose.labelString = "close"
    @buttonClose.action = =>
      @destroy()

    @add @buttonClose

    # resizer
    @resizer = new HandleMorph(@, 150, 100, @edge, @edge)

    # update layout
    @fixLayout()
  
  fixLayout: ->
    Morph::trackChanges = false

    handleSize = WorldMorph.MorphicPreferences.handleSize;

    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x

    # close icon
    @closeIcon.setPosition new Point(x, y)
    closeIconScale = 2/3
    @closeIcon.setExtent new Point(handleSize * closeIconScale, handleSize * closeIconScale)

    # label
    @label.setPosition new Point(x + handleSize * closeIconScale + @edge, y - @edge/2)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @silentSetHeight @label.height() + 50
      @updateRendering()
      @changed()
      @resizer.updateRendering()

    # morphsList
    y = @label.bottom() + @edge/2
    w = @width() - @edge
    w -= @edge
    b = @bottom() - (2 * @edge) - handleSize
    h = b - y
    @morphsList.setPosition new Point(x, y)
    @morphsList.setExtent new Point(w, h)

    # close button
    x = @morphsList.left()
    y = @morphsList.bottom() + @edge
    h = handleSize
    w = @morphsList.width() - h - @edge
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
    @fixLayout()
  '''

morphicVersion = 'version of 2013-09-06 22:51:08'
