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
# Global Functions ////////////////////////////////////////////////////

nop = ->
  # returns the function that does nothing
  ->    
    # this is the function that does nothing
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
    size += 1  if object.hasOwnProperty(key)
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
  y = 0
  while y < size
    x = 0
    while x < maxX
      data = ctx.getImageData(x, y, 1, 1)
      return size - y + 1  if data.data[3] isnt 0
      x += 1
    y += 1
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
  y = 0
  while y < size
    x = 0
    while x < maxX
      data = ctx.getImageData(x, y, 1, 1)
      return size - y + 1  if data.data[3] isnt 0
      x += 1
    y += 1
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
    return 0  if !@parent?
    @parent.depth() + 1
  
  allChildren: ->
    # includes myself
    result = [@]
    @children.forEach (child) ->
      result = result.concat(child.allChildren())
    #
    result
  
  forAllChildren: (aFunction) ->
    if @children.length
      @children.forEach (child) ->
        child.forAllChildren aFunction
    #
    aFunction.call null, @
  
  allLeafs: ->
    result = []
    @allChildren().forEach (element) ->
      result.push element  if !element.children.length
    #
    result
  
  allParents: ->
    # includes myself
    result = [@]
    result = result.concat(@parent.allParents())  if @parent?
    result
  
  siblings: ->
    return []  if !@parent?
    @parent.children.filter (child) =>
      child isnt @
  
  parentThatIsA: (constructor) ->
    # including myself
    return @  if @ instanceof constructor
    return null  unless @parent
    @parent.parentThatIsA constructor
  
  parentThatIsAnyOf: (constructors) ->
    # including myself
    yup = false
    constructors.forEach (each) =>
      if @constructor is each
        yup = true
        return
    #
    return @  if yup
    return null  unless @parent
    @parent.parentThatIsAnyOf constructors
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
  image: null
  
  constructor: () ->
    super()
    @bounds = new Rectangle(0, 0, 50, 40)
    @color = new Color(80, 80, 80)
    @drawNew()
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
    
    if timeRemainingToWaitedFrame < 1
      @lastTime = WorldMorph.currentTime
      @step()
      @children.forEach (child) ->
        child.runChildrensStepFunction()
  
  
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
      @changed()
      @silentSetExtent aPoint
      @changed()
      @drawNew()
  
  silentSetExtent: (aPoint) ->
    ext = aPoint.round()
    newWidth = Math.max(ext.x, 0)
    newHeight = Math.max(ext.y, 0)
    @bounds.corner = new Point(@bounds.origin.x + newWidth, @bounds.origin.y + newHeight)
  
  setWidth: (width) ->
    @setExtent new Point(width or 0, @height())
  
  silentSetWidth: (width) ->
    # do not drawNew() just yet
    w = Math.max(Math.round(width or 0), 0)
    @bounds.corner = new Point(@bounds.origin.x + w, @bounds.corner.y)
  
  setHeight: (height) ->
    @setExtent new Point(@width(), height or 0)
  
  silentSetHeight: (height) ->
    # do not drawNew() just yet
    h = Math.max(Math.round(height or 0), 0)
    @bounds.corner = new Point(@bounds.corner.x, @bounds.origin.y + h)
  
  setColor: (aColor) ->
    if aColor
      unless @color.eq(aColor)
        @color = aColor
        @changed()
        @drawNew()
  
  
  # Morph displaying:
  drawNew: ->
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
  
  drawCachedTexture: ->
    bg = @cachedTexture
    cols = Math.floor(@image.width / bg.width)
    lines = Math.floor(@image.height / bg.height)
    context = @image.getContext("2d")
    y = 0
    while y <= lines
      x = 0
      while x <= cols
        context.drawImage bg, Math.round(x * bg.width), Math.round(y * bg.height)
        x += 1
      y += 1
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
  drawOn: (aCanvas, aRect) ->
    return null  unless @isVisible
    rectangle = aRect or @bounds()
    area = rectangle.intersect(@bounds).round()
    if area.extent().gt(new Point(0, 0))
      delta = @position().neg()
      src = area.copy().translateBy(delta).round()
      context = aCanvas.getContext("2d")
      context.globalAlpha = @alpha
      sl = src.left()
      st = src.top()
      w = Math.min(src.width(), @image.width - sl)
      h = Math.min(src.height(), @image.height - st)
      return null  if w < 1 or h < 1

      context.drawImage @image,
        Math.round(src.left()),
        Math.round(src.top()),
        Math.round(w),
        Math.round(h),
        Math.round(area.left()),
        Math.round(area.top()),
        Math.round(w),
        Math.round(h)

      if WorldMorph.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)
        context.globalAlpha = 0.5
        context.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        context.fillRect(Math.round(area.left()),Math.round(area.top()),Math.round(w),Math.round(h));
  
  
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
  fullDrawOn: (aCanvas, aRect) ->
    return null  unless @isVisible
    rectangle = aRect or @boundsIncludingChildren()
    @drawOn aCanvas, rectangle
    @children.forEach (child) ->
      child.fullDrawOn aCanvas, rectangle
  
  
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
    @fullDrawOn img, fb
    img.globalAlpha = @alpha
    img
  
  fullImage: ->
    img = newCanvas(@boundsIncludingChildren().extent())
    ctx = img.getContext("2d")
    fb = @boundsIncludingChildren()
    @allChildren().forEach (morph) ->
      if morph.isVisible
        ctx.globalAlpha = morph.alpha
        ctx.drawImage morph.image,
          Math.round(morph.bounds.origin.x - fb.origin.x),
          Math.round(morph.bounds.origin.y - fb.origin.y)
    #
    img
  
  
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
    if useBlurredShadows
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
          entryField.text.drawNew()
          entryField.text.changed()
          entryField.text.edit()
      else
        slider.action = (num) ->
          entryField.changed()
          entryField.text.text = num.toString()
          entryField.text.drawNew()
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
    world = @world()
    inspectee = @
    inspectee = anotherObject  if anotherObject
    inspector = new InspectorMorph(inspectee)
    inspector.setPosition world.hand.position()
    inspector.keepWithin world
    world.add inspector
    inspector.changed()
  
  
  # Morph menus ////////////////////////////////////////////////////////////////
  
  contextMenu: ->
    return @customContextMenu  if @customContextMenu
    world = @world()
    if world and world.isDevMode
      return @developersMenu()  if @parent is world
      return @hierarchyMenu()
    @userMenu() or (@parent and @parent.userMenu())
  
  hierarchyMenu: ->
    parents = @allParents()
    world = @world()
    menu = new MenuMorph(@, null)
    parents.forEach (each) ->
      if each.developersMenu and (each isnt world)
        menu.addItem each.toString().slice(0, 50), ->
          each.developersMenu().popUpAtHand world
    #  
    menu
  
  developersMenu: ->
    # 'name' is not an official property of a function, hence:
    world = @world()
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
  setAlphaScaled: (alpha) ->
    # for context menu demo purposes
    if typeof alpha is "number"
      unscaled = alpha / 100
      @alpha = Math.min(Math.max(unscaled, 0.1), 1)
    else
      newAlpha = parseFloat(alpha)
      unless isNaN(newAlpha)
        unscaled = newAlpha / 100
        @alpha = Math.min(Math.max(unscaled, 0.1), 1)
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
  
  
  # Morph eval:
  evaluateString: (code) ->
    try
      result = eval(code)
      @drawNew()
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
#| FrameMorph //////////////////////////////////////////////////////////
#| 
#| I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
#| 
#| and event handling.

class FrameMorph extends Morph

  @scrollFrame: null

  constructor: (@scrollFrame = null) ->
    super()
    @color = new Color(255, 250, 245)
    @drawNew()
    @acceptsDrops = true
    if @scrollFrame
      @isDraggable = false
      @noticesTransparentClick = false
      @alpha = 0
  
  boundsIncludingChildren: ->
    shadow = @getShadow()
    return @bounds.merge(shadow.bounds)  if shadow isnt null
    @bounds
  
  fullImage: ->
    # use only for shadows
    @image
  
  fullDrawOn: (aCanvas, aRect) ->
    return null  unless @isVisible
    boundsRectangle = aRect or @boundsIncludingChildren()
    
    # the part to be redrawn could be outside the frame entirely,
    # in which case we can stop going down the morphs inside the frame
    # since the whole point of the frame is to clip everything to a specific
    # rectangle.
    # So, check which part of the Frame should be redrawn:
    dirtyPartOfFrame = @bounds.intersect(boundsRectangle)
    
    # if there is no dirty part in the frame then do nothing
    return null unless dirtyPartOfFrame.extent().gt(new Point(0, 0))
    
    # this draws the background of the frame itself, which could
    # contain an image or a pentrail
    @drawOn aCanvas, dirtyPartOfFrame
    
    @children.forEach (child) =>
      if child instanceof ShadowMorph
        child.fullDrawOn aCanvas, boundsRectangle
      else
        child.fullDrawOn aCanvas, dirtyPartOfFrame
  
  
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
      @drawNew()
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
    super()
    @scrollBarSize = scrollBarSize or WorldMorph.MorphicPreferences.scrollBarSize
    @contents = contents or new FrameMorph(@)
    @add @contents
    #
    @hBar = new SliderMorph(null, null, null, null, "horizontal", sliderColor)
    @hBar.setHeight @scrollBarSize
    @hBar.action = (num) =>
      @contents.setPosition new Point(@left() - num, @contents.position().y)
    @hBar.isDraggable = false
    @add @hBar
    #
    @vBar = new SliderMorph(null, null, null, null, "vertical", sliderColor)
    @vBar.setWidth @scrollBarSize
    @vBar.action = (num) =>
      @contents.setPosition new Point(@contents.position().x, @top() - num)
    @vBar.isDraggable = false
    @add @vBar
  
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
      @hBar.drawNew()
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
      @vBar.drawNew()
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
    newX = l  if newX > l
    newX = r - cw  if newX + cw < r
    @contents.setLeft newX  if newX isnt cl
  
  scrollY: (steps) ->
    ct = @contents.top()
    t = @top()
    ch = @contents.height()
    b = @bottom()
    newY = ct + steps
    newY = t  if newY > t
    newY = b - ch  if newY + ch < b
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
  scrollCursorIntoView: (morph, padding) ->
    ft = @top() + padding
    fb = @bottom() - padding
    if morph.top() < ft
      morph.target.setTop morph.target.top() + ft - morph.top()
      morph.setTop ft
    else if morph.bottom() > fb
      morph.target.setBottom morph.target.bottom() + fb - morph.bottom()
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
# ListMorph ///////////////////////////////////////////////////////////

class ListMorph extends ScrollFrameMorph
  
  elements: null
  labelGetter: null
  format: null
  listContents: null
  selected: null
  action: null

  constructor: (@elements = [], labelGetter, @format = []) ->
    #
    #    passing a format is optional. If the format parameter is specified
    #    it has to be of the following pattern:
    #
    #        [
    #            [<color>, <single-argument predicate>],
    #            ...
    #        ]
    #
    #    multiple color conditions can be passed in such a format list, the
    #    last predicate to evaluate true when given the list element sets
    #    the given color. If no condition is met, the default color (black)
    #    will be assigned.
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
      @format.forEach (pair) ->
        color = pair[0]  if pair[1].call(null, element)
      #
      # label string
      # action
      # hint
      @listContents.addItem @labelGetter(element), element, null, color
    #
    @listContents.setPosition @contents.position()
    @listContents.isListContents = true
    @listContents.drawNew()
    @addContents @listContents
  
  select: (item) ->
    @selected = item
    @action.call null, item  if @action
  
  setExtent: (aPoint) ->
    lb = @listContents.bounds
    nb = @bounds.origin.copy().corner(@bounds.origin.add(aPoint))
    if nb.right() > lb.right() and nb.width() <= lb.width()
      @listContents.setRight nb.right()
    if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
      @listContents.setBottom nb.bottom()
    super aPoint
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
  
  drawNew: ->
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
    @drawNew()
    @changed()
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
  
  
  # this.drawNew();
  autoOrientation: ->
      noOperation
  
  rangeSize: ->
    @stop - @start
  
  ratio: ->
    @size / @rangeSize()
  
  unitSize: ->
    return (@height() - @button.height()) / @rangeSize()  if @orientation is "vertical"
    (@width() - @button.width()) / @rangeSize()
  
  drawNew: ->
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
    @button.drawNew()
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
    @drawNew()
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
    @drawNew()
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
    @drawNew()
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
# ColorPaletteMorph ///////////////////////////////////////////////////

class ColorPaletteMorph extends Morph

  target: null
  targetSetter: "color"
  choice: null

  constructor: (@target = null, sizePoint) ->
    super()
    @silentSetExtent sizePoint or new Point(80, 50)
    @drawNew()
  
  drawNew: ->
    ext = @extent()
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    @choice = new Color()
    x = 0
    while x <= ext.x
      h = 360 * x / ext.x
      y = 0
      while y <= ext.y
        l = 100 - (y / ext.y * 100)
        context.fillStyle = "hsl(" + h + ",100%," + l + "%)"
        context.fillRect x, y, 1, 1
        y += 1
      x += 1
  
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
        @target.drawNew()
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
# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text cursors

class BlinkerMorph extends Morph
  constructor: (@fps = 2) ->
    super()
    @color = new Color(0, 0, 0)
    @drawNew()
  
  # BlinkerMorph stepping:
  step: ->
    @toggleVisibility()
# CursorMorph /////////////////////////////////////////////////////////

# I am a String/Text editing widget

class CursorMorph extends BlinkerMorph

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
    @drawNew()
    @image.getContext("2d").font = @target.font()
    if (@target instanceof TextMorph && (@target.alignment != 'left'))
      @target.setAlignmentToLeft()
    @gotoSlot @slot
  
  # CursorMorph event processing:
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
        if @target instanceof StringMorph
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
  
  
  # CursorMorph navigation - simple version
  #gotoSlot: (newSlot) ->
  #  @setPosition @target.slotPosition(newSlot)
  #  @slot = Math.max(newSlot, 0)

  gotoSlot: (slot) ->
    length = @target.text.length
    pos = @target.slotPosition(slot)
    @slot = (if slot < 0 then 0 else (if slot > length then length else slot))
    if @parent
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
    if @parent and @parent.parent instanceof ScrollFrameMorph
      @parent.parent.scrollCursorIntoView @, 6
  
  goLeft: (shift) ->
    @updateSelection shift
    @gotoSlot @slot - 1
    @updateSelection shift
  
  goRight: (shift) ->
    @updateSelection shift
    @gotoSlot @slot + 1
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
      if not @target.endMark and not @target.startMark
        @target.startMark = @slot
        @target.endMark = @slot
      else if @target.endMark isnt @slot
        @target.endMark = @slot
        @target.drawNew()
        @target.changed()
    else
      @target.clearSelection()  
  
  # CursorMorph editing:
  accept: ->
    world = @root()
    world.stopEditing()  if world
    @escalateEvent "accept", null
  
  cancel: ->
    world = @root()
    @undo()
    world.stopEditing()  if world
    @escalateEvent 'cancel', null
    
  undo: ->
    @target.text = @originalContents
    @target.changed()
    @target.drawNew()
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
      @target.drawNew()
      @target.changed()
      @goRight()
  
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
      @target.drawNew()
  
  deleteLeft: ->
    if @target.selection()
      @gotoSlot @target.selectionStartSlot()
      return @target.deleteSelection()
    text = @target.text
    @target.changed()
    @target.text = text.substring(0, @slot - 1) + text.substr(@slot)
    @target.drawNew()
    @goLeft()

  # CursorMorph destroying:
  destroy: ->
    if @target.alignment isnt @originalAlignment
      @target.alignment = @originalAlignment
      @target.drawNew()
      @target.changed()
    super  
  
  # CursorMorph utilities:
  inspectKeyEvent: (event) ->
    # private
    @inform "Key pressed: " + String.fromCharCode(event.charCode) + "\n------------------------" + "\ncharCode: " + event.charCode.toString() + "\nkeyCode: " + event.keyCode.toString() + "\naltKey: " + event.altKey.toString() + "\nctrlKey: " + event.ctrlKey.toString()  + "\ncmdKey: " + event.metaKey.toString()
# GrayPaletteMorph ///////////////////////////////////////////////////

class GrayPaletteMorph extends ColorPaletteMorph

  constructor: (@target = null, sizePoint) ->
    super @target, sizePoint or new Point(80, 10)
  
  drawNew: ->
    ext = @extent()
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    @choice = new Color()
    gradient = context.createLinearGradient(0, 0, ext.x, ext.y)
    gradient.addColorStop 0, "black"
    gradient.addColorStop 1, "white"
    context.fillStyle = gradient
    context.fillRect 0, 0, ext.x, ext.y
morphicVersion = "2012-October-22"
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
  drawNew: ->
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
    @drawNew()
    @changed()
  
  setBorderColor: (color) ->
    # for context menu demo purposes
    if color
      @borderColor = color
      @drawNew()
      @changed()
  
  setCornerSize: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @edge = Math.max(size, 0)
    else
      newSize = parseFloat(size)
      @edge = Math.max(newSize, 0)  unless isNaN(newSize)
    @drawNew()
    @changed()
  
  colorSetters: ->
    # for context menu demo purposes
    ["color", "borderColor"]
  
  numericalSetters: ->
    # for context menu demo purposes
    list = super()
    list.push "setBorderWidth", "setCornerSize"
    list
# MorphsListMorph //////////////////////////////////////////////////////

class MorphsListMorph extends BoxMorph

  # panes:
  morphsList: null
  buttonClose: null
  resizer: null

  constructor: (target) ->
    super()
    #
    @silentSetExtent new Point(
      WorldMorph.MorphicPreferences.handleSize * 10,
      WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @drawNew()
    @buildPanes()
  
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
    @label = new TextMorph("Morphs List")
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.drawNew()
    @add @label
    #
    ListOfMorphs = []
    for i of window
      theWordMorph = "Morph"
      if i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
        ListOfMorphs.push i
    @morphsList = new ListMorph(ListOfMorphs, null)
    #
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
    #
    @morphsList.hBar.alpha = 0.6
    @morphsList.vBar.alpha = 0.6
    @add @morphsList
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
      @drawNew()
      @changed()
      @resizer.drawNew()
    #
    # morphsList
    y = @label.bottom() + 2
    w = @width() - @edge
    w -= @edge
    b = @bottom() - (2 * @edge) - WorldMorph.MorphicPreferences.handleSize
    h = b - y
    @morphsList.setPosition new Point(x, y)
    @morphsList.setExtent new Point(w, h)
    #
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
    @drawNew()
  
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
      @drawNew()
  
  
  # SpeechBubbleMorph invoking:
  popUp: (world, pos, isClickable) ->
    @drawNew()
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
  drawNew: ->
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
    @drawNew()
    @addShadow new Point(2, 2), 80# BouncerMorph ////////////////////////////////////////////////////////
# fishy constructor
# I am a Demo of a stepping custom Morph

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
# ColorPickerMorph ///////////////////////////////////////////////////

class ColorPickerMorph extends Morph

  choice: null

  constructor: (defaultColor) ->
    @choice = defaultColor or new Color(255, 255, 255)
    super()
    @color = new Color(255, 255, 255)
    @silentSetExtent new Point(80, 80)
    @drawNew()
  
  drawNew: ->
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
    # Note that Morph does a drawNew upon creation (TODO Why?), so we need
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
  
  addItem: (labelString, action, hint, color) ->
    # labelString is normally a single-line string. But it can also be one
    # of the following:
    #     * a multi-line string (containing line breaks)
    #     * an icon (either a Morph or a Canvas)
    #     * a tuple of format: [icon, string]
    @items.push [localize(labelString or "close"), action or nop, hint, color]
  
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
    text.drawNew()
    @label = new BoxMorph(3, 0)
    @label.color = @borderColor
    @label.borderColor = @borderColor
    @label.setExtent text.extent().add(4)
    @label.drawNew()
    @label.add text
    @label.text = text
  
  drawNew: ->
    isLine = false
    @children.forEach (m) ->
      m.destroy()
    #
    @children = []
    unless @isListContents
      @edge = 5
      @border = 2
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
        item = new MenuItemMorph(@target, tuple[1], tuple[0],
          @fontSize or WorldMorph.MorphicPreferences.menuFontSize,
          WorldMorph.MorphicPreferences.menuFontName, @environment,
          tuple[2], tuple[3]) # color
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
        w = @parent.width()    
    @children.forEach (item) ->
      if (item instanceof MenuItemMorph) or
        (item instanceof StringFieldMorph) or
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
        item.createBackgrounds()
      else
        item.drawNew()
        if item is @label
          item.text.setPosition item.center().subtract(item.text.extent().floorDivideBy(2))
  
  
  unselectAllItems: ->
    @children.forEach (item) ->
      item.image = item.normalImage  if item instanceof MenuItemMorph
    #
    @changed()
  
  popup: (world, pos) ->
    @drawNew()
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
    @drawNew()
    @popup wrrld, wrrld.hand.position().subtract(@extent().floorDivideBy(2))
  
  popUpCenteredInWorld: (world) ->
    wrrld = world or @world
    @drawNew()
    @popup wrrld, wrrld.center().subtract(@extent().floorDivideBy(2))
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

  constructor: (aCanvas, fillPage) ->
    super()
    @color = new Color(205, 205, 205) # (130, 130, 130)
    @alpha = 1
    @bounds = new Rectangle(0, 0, aCanvas.width, aCanvas.height)
    @drawNew()
    @isVisible = true
    @isDraggable = false
    @currentKey = null # currently pressed key code
    @worldCanvas = aCanvas
    #
    # additional properties:
    @useFillPage = fillPage
    @useFillPage = true  if @useFillPage is `undefined`
    @isDevMode = false
    @broken = []
    @hand = new HandMorph(@)
    @keyboardReceiver = null
    @lastEditedText = null
    @cursor = null
    @activeMenu = null
    @activeHandle = null
    @virtualKeyboard = null
    @initEventListeners()
  
  # World Morph display:
  brokenFor: (aMorph) ->
    # private
    fb = aMorph.boundsIncludingChildren()
    @broken.filter (rect) ->
      rect.intersects fb
  
  
  # all fullDraws result into actual blittings of images done
  # by the drawOn function.
  # The drawOn function is defined in Morph and is not overriden by
  # any morph.
  fullDrawOn: (aCanvas, aRect) ->
    # invokes the Morph's fullDrawOn, which has only two implementations:
    # the default one by Morph which just invokes the drawOn of all children
    # and the interesting one in FrameMorph which 
    super aCanvas, aRect
    # the mouse cursor is always drawn on top of everything
    # and it'd not attached to the WorldMorph.
    @hand.fullDrawOn aCanvas, aRect
  
  updateBroken: ->
    #console.log "number of broken rectangles: " + @broken.length
    @broken.forEach (rect) =>
      @fullDrawOn @worldCanvas, rect  if rect.extent().gt(new Point(0, 0))
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
    return  unless WorldMorph.MorphicPreferences.useVirtualKeyboard
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
    canvas.addEventListener "mousedown", ((event) =>
      @hand.processMouseDown event
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
      @hand.processMouseMove event
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
    if @isDevMode
      menu.addItem "user mode...", "toggleDevMode", "disable developers'\ncontext menus"
    else
      menu.addItem "development mode...", "toggleDevMode"
    menu.addItem "about morphic.js...", "about"
    menu
  
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
      newMorph.drawNew()
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
      if modules.hasOwnProperty(module)
        versions += ("\n" + module + " (" + modules[module] + ")")  
    if versions isnt ""
      versions = "\n\nmodules:\n\n" + "morphic (" + morphicVersion + ")" + versions  
    @inform "morphic.js\n\n" +
      "a lively Web GUI\ninspired by Squeak\n" +
      morphicVersion +
      "\n\original from Jens Mönig's (jens@moenig.org) morphic.js\n" +
      "\n\nported and extended by Davide Della Casa\n" +
      versions
  
  edit: (aStringOrTextMorph) ->
    pos = getDocumentPositionOf(@worldCanvas)
    return null  unless aStringOrTextMorph.isEditable
    @cursor.destroy()  if @cursor
    @lastEditedText.clearSelection()  if @lastEditedText
    @cursor = new CursorMorph(aStringOrTextMorph)
    aStringOrTextMorph.parent.add @cursor
    @keyboardReceiver = @cursor
    @initVirtualKeyboard()
    if WorldMorph.MorphicPreferences.useVirtualKeyboard
      @virtualKeyboard.style.top = @cursor.top() + pos.y + "px"
      @virtualKeyboard.style.left = @cursor.left() + pos.x + "px"
      @virtualKeyboard.focus()
    if WorldMorph.MorphicPreferences.useSliderForInput
      if !aStringOrTextMorph.parentThatIsA(MenuMorph)
        @slide aStringOrTextMorph
  
  slide: (aStringOrTextMorph) ->
    # display a slider for numeric text entries
    val = parseFloat(aStringOrTextMorph.text)
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
    slider.drawNew()
    slider.action = (num) ->
      aStringOrTextMorph.changed()
      aStringOrTextMorph.text = Math.round(num).toString()
      aStringOrTextMorph.drawNew()
      aStringOrTextMorph.changed()
      aStringOrTextMorph.escalateEvent(
          'reactToSliderEdit',
          aStringOrTextMorph
      )
    #
    menu.items.push slider
    menu.popup @, aStringOrTextMorph.bottomLeft().add(new Point(0, 5))
  
  stopEditing: ->
    if @cursor
      @lastEditedText = @cursor.target
      @cursor.destroy()
      @cursor = null
      @lastEditedText.escalateEvent "reactToEdit", @lastEditedText
    @keyboardReceiver = null
    if @virtualKeyboard
      @virtualKeyboard.blur()
      document.body.removeChild @virtualKeyboard
      @virtualKeyboard = null
    @worldCanvas.focus()
  
  toggleBlurredShadows: ->
    useBlurredShadows = not useBlurredShadows
  
  togglePreferences: ->
    if WorldMorph.MorphicPreferences is standardSettings
      WorldMorph.MorphicPreferences = touchScreenSettings
    else
      WorldMorph.MorphicPreferences = standardSettings
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
  is3D: true
  hasMiddleDip: true

  constructor: (orientation) ->
    @color = new Color(80, 80, 80)
    super orientation
  
  autoOrientation: ->
      noOperation
  
  drawNew: ->
    colorBak = @color.copy()
    super()
    @drawEdges()  if @is3D
    @normalImage = @image
    @color = @highlightColor.copy()
    super()
    @drawEdges()  if @is3D
    @highlightImage = @image
    @color = @pressColor.copy()
    super()
    @drawEdges()  if @is3D
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
# PenMorph ////////////////////////////////////////////////////////////

# I am a simple LOGO-wise turtle.

class PenMorph extends Morph
  
  heading: 0
  penSize: null
  isWarped: false # internal optimization
  wantsRedraw: false # internal optimization
  isDown: true
  
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
  drawNew: (facing) ->
    #
    #    my orientation can be overridden with the "facing" parameter to
    #    implement Scratch-style rotation styles
    #    
    #
    direction = facing or @heading
    if @isWarped
      @wantsRedraw = true
      return null
    @image = newCanvas(@extent())
    context = @image.getContext("2d")
    len = @width() / 2
    start = @center().subtract(@bounds.origin)
    dest = start.distanceAngle(len * 0.75, direction - 180)
    left = start.distanceAngle(len, direction + 195)
    right = start.distanceAngle(len, direction - 195)
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
    if @isWarped is false
      @drawNew()
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
    @parent.drawNew()
    @parent.changed()
  
  
  # PenMorph optimization for atomic recursion:
  startWarp: ->
    @isWarped = true
  
  endWarp: ->
    @drawNew()  if @wantsRedraw
    @changed()
    @parent.changed()
    @isWarped = false
  
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
      i = 0
      while i < 3
        @sierpinski length * 0.5, min
        @turn 120
        @forward length
        i += 1
  
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
# StringMorph /////////////////////////////////////////////////////////

# I am a single line of text

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
  currentlySelecting: false
  startMark: 0
  endMark: 0
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
    @drawNew()
  
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
  
  drawNew: ->
    text = (if @isPassword then @password("*", @text.length) else @text)
    # initialize my surface property
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    #
    # set my extent
    width = Math.max(context.measureText(text).width + Math.abs(@shadowOffset.x), 1)
    @bounds.corner = @bounds.origin.add(new Point(
      width, fontHeight(@fontSize) + Math.abs(@shadowOffset.y)))
    @image.width = width
    @image.height = @height()
    #
    # prepare context for drawing text
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"
    #
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
    i = start
    while i < stop
      p = @slotPosition(i).subtract(@position())
      c = text.charAt(i)
      context.fillStyle = @markedBackgoundColor.toString()
      context.fillRect p.x, p.y, context.measureText(c).width + 1 + x,
        fontHeight(@fontSize) + y
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x + x, fontHeight(@fontSize) + y
      i += 1
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
  slotPosition: (slot) ->
    # answer the position point of the given index ("slot")
    # where the cursor should be placed
    text = (if @isPassword then @password("*", @text.length) else @text)
    dest = Math.min(Math.max(slot, 0), text.length)
    context = @image.getContext("2d")
    xOffset = 0
    idx = 0
    while idx < dest
      xOffset += context.measureText(text[idx]).width
      idx += 1
    @pos = dest
    x = @left() + xOffset
    y = @top()
    new Point(x, y)
  
  slotAt: (aPoint) ->
    # answer the slot (index) closest to the given point
    # so the cursor can be moved accordingly
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
    @drawNew()
    @changed()
  
  toggleWeight: ->
    @isBold = not @isBold
    @changed()
    @drawNew()
    @changed()
  
  toggleItalic: ->
    @isItalic = not @isItalic
    @changed()
    @drawNew()
    @changed()
  
  toggleIsPassword: ->
    @isPassword = not @isPassword
    @changed()
    @drawNew()
    @changed()
  
  setSerif: ->
    @fontStyle = "serif"
    @changed()
    @drawNew()
    @changed()
  
  setSansSerif: ->
    @fontStyle = "sans-serif"
    @changed()
    @drawNew()
    @changed()
  
  setFontSize: (size) ->
    # for context menu demo purposes
    if typeof size is "number"
      @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
    else
      newSize = parseFloat(size)
      @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
    @changed()
    @drawNew()
    @changed()
  
  setText: (size) ->
    # for context menu demo purposes
    @text = Math.round(size).toString()
    @changed()
    @drawNew()
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
    @startMark = 0
    @endMark = 0
    @drawNew()
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
    @drawNew()
    @changed()

  mouseDownLeft: (pos) ->
    if @isEditable
      @clearSelection()
    else
      @escalateEvent "mouseDownLeft", pos

  mouseClickLeft: (pos) ->
    cursor = @root().cursor;
    if @isEditable
      @edit()  unless @currentlySelecting
      if cursor then cursor.gotoPos pos
      @root().cursor.gotoPos pos
      @currentlySelecting = true
    else
      @escalateEvent "mouseClickLeft", pos
  
  enableSelecting: ->
    @mouseDownLeft = (pos) ->
      @clearSelection()
      if @isEditable and (not @isDraggable)
        @edit()
        @root().cursor.gotoPos pos
        @startMark = @slotAt(pos)
        @endMark = @startMark
        @currentlySelecting = true
    
    @mouseMove = (pos) ->
      if @isEditable and @currentlySelecting and (not @isDraggable)
        newMark = @slotAt(pos)
        if newMark isnt @endMark
          @endMark = newMark
          @drawNew()
          @changed()
  
  disableSelecting: ->
    # re-establish the original definition of the method
    @mouseDownLeft = StringMorph::mouseDownLeft
    delete @mouseMove
# TriggerMorph ////////////////////////////////////////////////////////

# I provide basic button functionality

class TriggerMorph extends Morph

  target: null
  action: null
  environment: null
  labelString: null
  label: null
  hint: null
  fontSize: null
  fontStyle: null
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(192, 192, 192)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(128, 128, 128)
  labelColor: null

  constructor: (@target = null, @action = null, @labelString = null,
    fontSize, fontStyle, @environment = null, @hint = null, labelColor) ->
    
    # additional properties:
    @fontSize = fontSize or WorldMorph.MorphicPreferences.menuFontSize
    @fontStyle = fontStyle or "sans-serif"
    @labelColor = labelColor or new Color(0, 0, 0)
    #
    super()
    #
    @color = new Color(255, 255, 255)
    @drawNew()
  
  
  # TriggerMorph drawing:
  drawNew: ->
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
      @labelString, @fontSize, @fontStyle, false, false, false, null, null, @labelColor)
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
    #	for selections, Yes/No Choices etc:
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
        @target.call @environment, @action.call()
      else
        @target.call @environment, @action
    else
      if typeof @action is "function"
        @action.call @target
      else # assume it's a String
        @target[@action]()
  
  
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
# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph

  # labelString can also be a Morph or a Canvas or a tuple: [icon, string]
  constructor: (target, action, labelString, fontSize, fontStyle, environment, hint, color) ->
    super target, action, labelString, fontSize, fontStyle, environment, hint, color
  
  createLabel: ->
    @label.destroy()  if @label isnt null

    if isString(@labelString)
      @label = @createLabelString(@labelString)
    else if @labelString instanceof Array      
      # assume its pattern is: [icon, string] 
      @label = new Morph()
      @label.alpha = 0 # transparent
      @label.add icon = @createIcon(@labelString[0])
      @label.add lbl = @createLabelString(@labelString[1])
      lbl.setCenter icon.center()
      lbl.setLeft icon.right() + 4
      @label.bounds = (icon.bounds.merge(lbl.bounds))
      @label.drawNew()
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
# ShadowMorph /////////////////////////////////////////////////////////

class ShadowMorph extends Morph
  constructor: () ->
    super()
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
  #		mouseEnter
  #		mouseLeave
  #		mouseEnterDragging
  #		mouseLeaveDragging
  #		mouseMove
  #		mouseScroll
  #
  processMouseDown: (event) ->
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
      if @world.cursor
        if morph isnt @world.cursor.target  
          @world.stopEditing()  
      @morphToGrab = morph.rootForGrab()  unless morph.mouseMove
      if event.button is 2 or event.ctrlKey
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
    clearInterval @touchHoldTimeout
    @processMouseUp button: 0
  
  processMouseUp: ->
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
  
  processMouseScroll: (event) ->
    morph = @morphAtPointer()
    morph = morph.parent  while morph and not morph.mouseScroll
    morph.mouseScroll (event.detail / -3) or ((if event.hasOwnProperty("wheelDeltaY") then event.wheelDeltaY / 120 else event.wheelDelta / 120)), event.wheelDeltaX / 120 or 0  if morph
  
  
  #
  #	drop event:
  #
  #        droppedImage
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
    #        droppedAudio(audio, name)
    #    
    #    events to interested Morphs at the mouse pointer
    #    if none of the above content types can be determined, the file contents
    #    is dispatched as an ArrayBuffer to interested Morphs:
    #
    #    ```droppedBinary(anArrayBuffer, name)```

    files = (if event instanceof FileList then event else (event.target.files || event.dataTransfer.files))
    txt = (if event.dataTransfer then event.dataTransfer.getData("Text/HTML") else null)
    targetDrop = @morphAtPointer()
    img = new Image()
    #
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
      i = start
      while i < html.length
        c = html[i]
        return url  if c is "\""
        url = url.concat(c)
        i += 1
      null
    
    if files.length
      for file in files
        if file.type.indexOf("image") is 0
          readImage file
        else if file.type.indexOf("audio") is 0
          readAudio file
        else if file.type.indexOf("text") is 0
          readText file
        else
          readBinary file
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
  
  processMouseMove: (event) ->
    #startProcessMouseMove = new Date().getTime()
    posInDocument = getDocumentPositionOf(@world.worldCanvas)
    pos = new Point(event.pageX - posInDocument.x, event.pageY - posInDocument.y)
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
    #	retained in case of needing	to fall back:
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
    @mouseOverList.forEach (old) ->
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
    @edge = 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @drawNew()
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
    @label.drawNew()
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
              (@target.hasOwnProperty element)
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
    ))
    @list.action = (selected) =>
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
      @drawNew()
      @changed()
      @resizer.drawNew()
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
      if @target.drawNew
        @target.changed()
        @target.drawNew()
        @target.changed()
    catch err
      @inform err
  
  addProperty: ->
    @prompt "new property name:", ((prop) =>
      if prop
        @target[prop] = null
        @buildPanes()
        if @target.drawNew
          @target.changed()
          @target.drawNew()
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
      if @target.drawNew
        @target.changed()
        @target.drawNew()
        @target.changed()
    ), @, propertyName
  
  removeProperty: ->
    prop = @list.selected
    try
      delete (@target[prop])
      #
      @currentProperty = null
      @buildPanes()
      if @target.drawNew
        @target.changed()
        @target.drawNew()
        @target.changed()
    catch err
      @inform err
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
  drawNew: ->
    @normalImage = newCanvas(@extent())
    @highlightImage = newCanvas(@extent())
    @drawOnCanvas @normalImage, @color, new Color(100, 100, 100)
    @drawOnCanvas @highlightImage, new Color(100, 100, 255), new Color(255, 255, 255)
    @image = @normalImage
    if @target
      @setPosition @target.bottomRight().subtract(@extent().add(@inset))
      @target.add @
      @target.changed()
  
  drawOnCanvas: (aCanvas, color, shadowColor) ->
    context = aCanvas.getContext("2d")
    context.lineWidth = 1
    context.lineCap = "round"
    context.strokeStyle = color.toString()
    if @type is "move"
      p1 = @bottomLeft().subtract(@position())
      p11 = p1.copy()
      p2 = @topRight().subtract(@position())
      p22 = p2.copy()
      i = 0
      while i <= @height()
        p11.y = p1.y - i
        p22.y = p2.y - i
        context.beginPath()
        context.moveTo p11.x, p11.y
        context.lineTo p22.x, p22.y
        context.closePath()
        context.stroke()
        i = i + 6
    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    i = 0
    while i <= @width()
      p11.x = p1.x + i
      p22.x = p2.x + i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()
      i = i + 6
    context.strokeStyle = shadowColor.toString()
    if @type is "move"
      p1 = @bottomLeft().subtract(@position())
      p11 = p1.copy()
      p2 = @topRight().subtract(@position())
      p22 = p2.copy()
      i = -2
      while i <= @height()
        p11.y = p1.y - i
        p22.y = p2.y - i
        context.beginPath()
        context.moveTo p11.x, p11.y
        context.lineTo p22.x, p22.y
        context.closePath()
        context.stroke()
        i = i + 6
    p1 = @bottomLeft().subtract(@position())
    p11 = p1.copy()
    p2 = @topRight().subtract(@position())
    p22 = p2.copy()
    i = 2
    while i <= @width()
      p11.x = p1.x + i
      p22.x = p2.x + i
      context.beginPath()
      context.moveTo p11.x, p11.y
      context.lineTo p22.x, p22.y
      context.closePath()
      context.stroke()
      i = i + 6
  
  
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
        @drawNew()
        @noticesTransparentClick = true
    menu.popUpAtHand @world()  if choices.length
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
    @drawNew()
  
  drawNew: ->
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
  
  mouseClickLeft: ->
    @text.edit()  if @isEditable
  
  
  # StringFieldMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.text = (dict[@text])  if c.text and dict[@text]
    c
# TextMorph ///////////////////////////////////////////////////////////

# I am a multi-line, word-wrapping String

# Jens has made this quasi-inheriting from StringMorph i.e. he is copying
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

  text: null
  words: []
  lines: []
  lineSlots: []
  fontSize: null
  fontName: null
  fontStyle: null
  isBold: null
  isItalic: null
  alignment: null
  shadowOffset: null
  shadowColor: null
  maxWidth: null
  maxLineWidth: 0
  backgroundColor: null
  isEditable: false

  #additional properties for ad-hoc evaluation:
  receiver: null

  # additional properties for text-editing:
  currentlySelecting: false
  startMark: 0
  endMark: 0
  markedTextColor: null
  markedBackgoundColor: null

  constructor: (
    text, @fontSize = 12, @fontStyle = "sans-serif", @isBold = false,
    @isItalic = false, @alignment = "left", @maxWidth = 0, fontName, shadowOffset,
    @shadowColor = null
    ) ->    
      @markedTextColor = new Color(255, 255, 255)
      @markedBackgoundColor = new Color(60, 60, 120)
      #
      super()
      #
      # override inherited properites:
      @text = text or ((if text is "" then text else "TextMorph"))
      @fontName = fontName or WorldMorph.MorphicPreferences.globalFontFamily
      @shadowOffset = shadowOffset or new Point(0, 0)
      @color = new Color(0, 0, 0)
      @noticesTransparentClick = true
      @drawNew()

  toString: ->
    # e.g. 'a TextMorph("Hello World")'
    "a TextMorph" + "(\"" + @text.slice(0, 30) + "...\")"
  
  
  parse: ->
    paragraphs = @text.split("\n")
    canvas = newCanvas()
    context = canvas.getContext("2d")
    oldline = ""
    slot = 0
    context.font = @font()
    @maxLineWidth = 0
    @lines = []
    @lineSlots = [0]
    @words = []
    paragraphs.forEach (p) =>
      @words = @words.concat(p.split(" "))
      @words.push "\n"
    #
    @words.forEach (word) =>
      if word is "\n"
        @lines.push oldline
        @lineSlots.push slot
        @maxLineWidth = Math.max(@maxLineWidth, context.measureText(oldline).width)
        oldline = ""
      else
        if @maxWidth > 0
          newline = oldline + word + " "
          w = context.measureText(newline).width
          if w > @maxWidth
            @lines.push oldline
            @lineSlots.push slot
            @maxLineWidth = Math.max(@maxLineWidth, context.measureText(oldline).width)
            oldline = word + " "
          else
            oldline = newline
        else
          oldline = oldline + word + " "
        slot += word.length + 1
  
  
  drawNew: ->
    @image = newCanvas()
    context = @image.getContext("2d")
    context.font = @font()
    @parse()
    #
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
    #
    # prepare context for drawing text
    context = @image.getContext("2d")
    context.font = @font()
    context.textAlign = "left"
    context.textBaseline = "bottom"
    #
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
    #
    # draw the selection
    start = Math.min(@startMark, @endMark)
    stop = Math.max(@startMark, @endMark)
    i = start
    while i < stop
      p = @slotPosition(i).subtract(@position())
      c = @text.charAt(i)
      context.fillStyle = @markedBackgoundColor.toString()
      context.fillRect p.x, p.y, context.measureText(c).width + 1, fontHeight(@fontSize)
      context.fillStyle = @markedTextColor.toString()
      context.fillText c, p.x, p.y + fontHeight(@fontSize)
      i += 1
    #
    # notify my parent of layout change
    @parent.layoutChanged()  if @parent.layoutChanged  if @parent
  
  setExtent: (aPoint) ->
    @maxWidth = Math.max(aPoint.x, 0)
    @changed()
    @drawNew()
  
  # TextMorph mesuring:
  columnRow: (slot) ->
    # answer the logical position point of the given index ("slot")
    idx = 0
    row = 0
    while row < @lines.length
      idx = @lineSlots[row]
      col = 0
      while col < @lines[row].length
        return new Point(col, row)  if idx is slot
        idx += 1
        col += 1
      row += 1
    #
    # return new Point(0, 0);
    new Point(@lines[@lines.length - 1].length - 1, @lines.length - 1)
  
  slotPosition: (slot) ->
    # answer the physical position point of the given index ("slot")
    # where the cursor should be placed
    colRow = @columnRow(slot)
    context = @image.getContext("2d")
    shadowHeight = Math.abs(@shadowOffset.y)
    xOffset = 0
    yOffset = colRow.y * (fontHeight(@fontSize) + shadowHeight)
    idx = 0
    while idx < colRow.x
      xOffset += context.measureText(@lines[colRow.y][idx]).width
      idx += 1
    x = @left() + xOffset
    y = @top() + yOffset
    new Point(x, y)
  
  slotAt: (aPoint) ->
    # answer the slot (index) closest to the given point
    # so the cursor can be moved accordingly
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
    colRow = @columnRow(slot)
    return slot  if colRow.y < 1
    above = @lines[colRow.y - 1]
    return @lineSlots[colRow.y - 1] + above.length  if above.length < colRow.x - 1
    @lineSlots[colRow.y - 1] + colRow.x
  
  downFrom: (slot) ->
    # answer the slot below the given one
    colRow = @columnRow(slot)
    return slot  if colRow.y > @lines.length - 2
    below = @lines[colRow.y + 1]
    return @lineSlots[colRow.y + 1] + below.length  if below.length < colRow.x - 1
    @lineSlots[colRow.y + 1] + colRow.x
  
  startOfLine: (slot) ->
    # answer the first slot (index) of the line for the given slot
    @lineSlots[@columnRow(slot).y]
  
  endOfLine: (slot) ->
    # answer the slot (index) indicating the EOL for the given slot
    @startOfLine(slot) + @lines[@columnRow(slot).y].length - 1
  
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
    @drawNew()
    @changed()
  
  setAlignmentToRight: ->
    @alignment = "right"
    @drawNew()
    @changed()
  
  setAlignmentToCenter: ->
    @alignment = "center"
    @drawNew()
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
    result = @receiver.evaluateString(@selection())
    world = @world()
    if result?
      inspector = new InspectorMorph(result)
      inspector.setPosition world.hand.position()
      inspector.keepWithin world
      world.add inspector
      inspector.changed()
