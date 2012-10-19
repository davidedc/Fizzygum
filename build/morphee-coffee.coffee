# Global Functions ////////////////////////////////////////////////////

nop = ->
  # do explicitly nothing
  null

noOpFunction = ->
  # returns the function that does nothing
  ->    
    # this is the function that does nothing
    null

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
  i = undefined
  size = list.length
  i = 0
  while i < size
    return list[i]  if predicate.call(null, list[i])
    i += 1
  null
isString = (target) ->
  typeof target is "string" or target instanceof String
isObject = (target) ->
  target isnt null and (typeof target is "object" or target instanceof Object)
radians = (degrees) ->
  degrees * Math.PI / 180
degrees = (radians) ->
  radians * 180 / Math.PI
fontHeight = (height) ->
  Math.max height, MorphicPreferences.minimumFontHeight
newCanvas = (extentPoint) ->
  
  # answer a new empty instance of Canvas, don't display anywhere
  canvas = undefined
  ext = undefined
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
  ctx = undefined
  maxX = undefined
  data = undefined
  x = undefined
  y = undefined
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
  source = undefined
  target = undefined
  ctx = undefined
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
  pos = undefined
  offsetParent = undefined
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
  value = undefined
  c = undefined
  property = undefined
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
  ctx = undefined
  maxX = undefined
  data = undefined
  x = undefined
  y = undefined
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
  source = undefined
  target = undefined
  ctx = undefined
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
  pos = undefined
  offsetParent = undefined
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
  value = undefined
  c = undefined
  property = undefined
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
  constructor: (parent, childrenArray) ->
    @init parent or null, childrenArray or []

MorphicNode::init = (parent, childrenArray) ->
  @parent = parent or null
  @children = childrenArray or []


# MorphicNode string representation: e.g. 'a MorphicNode[3]'
MorphicNode::toString = ->
  "a MorphicNode" + "[" + @children.length.toString() + "]"


# MorphicNode accessing:
MorphicNode::addChild = (aMorphicNode) ->
  @children.push aMorphicNode
  aMorphicNode.parent = this

MorphicNode::addChildFirst = (aMorphicNode) ->
  @children.splice 0, null, aMorphicNode
  aMorphicNode.parent = this

MorphicNode::removeChild = (aMorphicNode) ->
  idx = @children.indexOf(aMorphicNode)
  @children.splice idx, 1  if idx isnt -1


# MorphicNode functions:
MorphicNode::root = ->
  return this  if @parent is null
  @parent.root()

MorphicNode::depth = ->
  return 0  if @parent is null
  @parent.depth() + 1

MorphicNode::allChildren = ->
  
  # includes myself
  result = [this]
  @children.forEach (child) ->
    result = result.concat(child.allChildren())
  
  result

MorphicNode::forAllChildren = (aFunction) ->
  if @children.length > 0
    @children.forEach (child) ->
      child.forAllChildren aFunction
  
  aFunction.call null, this

MorphicNode::allLeafs = ->
  result = []
  @allChildren().forEach (element) ->
    result.push element  if element.children.length is 0
  
  result

MorphicNode::allParents = ->
  
  # includes myself
  result = [this]
  result = result.concat(@parent.allParents())  if @parent isnt null
  result

MorphicNode::siblings = ->
  myself = this
  return []  if @parent is null
  @parent.children.filter (child) ->
    child isnt myself


MorphicNode::parentThatIsA = (constructor) ->
  
  # including myself
  return this  if this instanceof constructor
  return null  unless @parent
  @parent.parentThatIsA constructor

MorphicNode::parentThatIsAnyOf = (constructors) ->
  
  # including myself
  yup = false
  myself = this
  constructors.forEach (each) ->
    if myself.constructor is each
      yup = true
      return
  
  return this  if yup
  return null  unless @parent
  @parent.parentThatIsAnyOf constructors
# Morph //////////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class Morph extends MorphicNode
  constructor: () ->
    @init()


# Morphs //////////////////////////////////////////////////////////////

# Morph: referenced constructors

# Morph inherits from MorphicNode:

# Morph settings:

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
Morph::trackChanges = true
Morph::shadowBlur = 4

# Morph instance creation:

# Morph initialization:
Morph::init = ->
  super()
  @isMorph = true
  @bounds = new Rectangle(0, 0, 50, 40)
  @color = new Color(80, 80, 80)
  @texture = null # optional url of a fill-image
  @cachedTexture = null # internal cache of actual bg image
  @alpha = 1
  @isVisible = true
  @isDraggable = false
  @isTemplate = false
  @acceptsDrops = false
  @noticesTransparentClick = false
  @drawNew()
  @fps = 0
  @customContextMenu = null
  @lastTime = Date.now()


# Morph string representation: e.g. 'a Morph 2 [20@45 | 130@250]'
Morph::toString = ->
  "a " + (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0]) + " " + @children.length.toString() + " " + @bounds


# Morph deleting:
Morph::destroy = ->
  if @parent isnt null
    @fullChanged()
    @parent.removeChild this


# Morph stepping:
Morph::stepFrame = ->
  return null  unless @step
  current = undefined
  elapsed = undefined
  leftover = undefined
  current = Date.now()
  elapsed = current - @lastTime
  if @fps > 0
    leftover = (1000 / @fps) - elapsed
  else
    leftover = 0
  if leftover < 1
    @lastTime = current
    @step()
    @children.forEach (child) ->
      child.stepFrame()


Morph::step = ->
  nop()


# Morph accessing - geometry getting:
Morph::left = ->
  @bounds.left()

Morph::right = ->
  @bounds.right()

Morph::top = ->
  @bounds.top()

Morph::bottom = ->
  @bounds.bottom()

Morph::center = ->
  @bounds.center()

Morph::bottomCenter = ->
  @bounds.bottomCenter()

Morph::bottomLeft = ->
  @bounds.bottomLeft()

Morph::bottomRight = ->
  @bounds.bottomRight()

Morph::boundingBox = ->
  @bounds

Morph::corners = ->
  @bounds.corners()

Morph::leftCenter = ->
  @bounds.leftCenter()

Morph::rightCenter = ->
  @bounds.rightCenter()

Morph::topCenter = ->
  @bounds.topCenter()

Morph::topLeft = ->
  @bounds.topLeft()

Morph::topRight = ->
  @bounds.topRight()

Morph::position = ->
  @bounds.origin

Morph::extent = ->
  @bounds.extent()

Morph::width = ->
  @bounds.width()

Morph::height = ->
  @bounds.height()

Morph::fullBounds = ->
  result = undefined
  result = @bounds
  @children.forEach (child) ->
    result = result.merge(child.fullBounds())  if child.isVisible
  
  result

Morph::fullBoundsNoShadow = ->
  
  # answer my full bounds but ignore any shadow
  result = undefined
  result = @bounds
  @children.forEach (child) ->
    result = result.merge(child.fullBounds())  if (child not instanceof ShadowMorph) and (child.isVisible)
  
  result

Morph::visibleBounds = ->
  
  # answer which part of me is not clipped by a Frame
  visible = @bounds
  frames = @allParents().filter((p) ->
    p instanceof FrameMorph
  )
  frames.forEach (f) ->
    visible = visible.intersect(f.bounds)
  
  visible


# Morph accessing - simple changes:
Morph::moveBy = (delta) ->
  @changed()
  @bounds = @bounds.translateBy(delta)
  @children.forEach (child) ->
    child.moveBy delta
  
  @changed()

Morph::silentMoveBy = (delta) ->
  @bounds = @bounds.translateBy(delta)
  @children.forEach (child) ->
    child.silentMoveBy delta


Morph::setPosition = (aPoint) ->
  delta = aPoint.subtract(@topLeft())
  @moveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)

Morph::silentSetPosition = (aPoint) ->
  delta = aPoint.subtract(@topLeft())
  @silentMoveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)

Morph::setLeft = (x) ->
  @setPosition new Point(x, @top())

Morph::setRight = (x) ->
  @setPosition new Point(x - @width(), @top())

Morph::setTop = (y) ->
  @setPosition new Point(@left(), y)

Morph::setBottom = (y) ->
  @setPosition new Point(@left(), y - @height())

Morph::setCenter = (aPoint) ->
  @setPosition aPoint.subtract(@extent().floorDivideBy(2))

Morph::setFullCenter = (aPoint) ->
  @setPosition aPoint.subtract(@fullBounds().extent().floorDivideBy(2))

Morph::keepWithin = (aMorph) ->
  
  # make sure I am completely within another Morph's bounds
  leftOff = undefined
  rightOff = undefined
  topOff = undefined
  bottomOff = undefined
  leftOff = @fullBounds().left() - aMorph.left()
  @moveBy new Point(-leftOff, 0)  if leftOff < 0
  rightOff = @fullBounds().right() - aMorph.right()
  @moveBy new Point(-rightOff, 0)  if rightOff > 0
  topOff = @fullBounds().top() - aMorph.top()
  @moveBy new Point(0, -topOff)  if topOff < 0
  bottomOff = @fullBounds().bottom() - aMorph.bottom()
  @moveBy new Point(0, -bottomOff)  if bottomOff > 0


# Morph accessing - dimensional changes requiring a complete redraw
Morph::setExtent = (aPoint) ->
  unless aPoint.eq(@extent())
    @changed()
    @silentSetExtent aPoint
    @changed()
    @drawNew()

Morph::silentSetExtent = (aPoint) ->
  ext = undefined
  newWidth = undefined
  newHeight = undefined
  ext = aPoint.round()
  newWidth = Math.max(ext.x, 0)
  newHeight = Math.max(ext.y, 0)
  @bounds.corner = new Point(@bounds.origin.x + newWidth, @bounds.origin.y + newHeight)

Morph::setWidth = (width) ->
  @setExtent new Point(width or 0, @height())

Morph::silentSetWidth = (width) ->
  
  # do not drawNew() just yet
  w = Math.max(Math.round(width or 0), 0)
  @bounds.corner = new Point(@bounds.origin.x + (w), @bounds.corner.y)

Morph::setHeight = (height) ->
  @setExtent new Point(@width(), height or 0)

Morph::silentSetHeight = (height) ->
  
  # do not drawNew() just yet
  h = Math.max(Math.round(height or 0), 0)
  @bounds.corner = new Point(@bounds.corner.x, @bounds.origin.y + (h))

Morph::setColor = (aColor) ->
  if aColor
    unless @color.eq(aColor)
      @color = aColor
      @changed()
      @drawNew()


# Morph displaying:
Morph::drawNew = ->
  
  # initialize my surface property
  @image = newCanvas(@extent())
  context = @image.getContext("2d")
  context.fillStyle = @color.toString()
  context.fillRect 0, 0, @width(), @height()
  if @cachedTexture
    @drawCachedTexture()
  else @drawTexture @texture  if @texture

Morph::drawTexture = (url) ->
  myself = this
  @cachedTexture = new Image()
  @cachedTexture.onload = ->
    myself.drawCachedTexture()
  
  @cachedTexture.src = @texture = url # make absolute

Morph::drawCachedTexture = ->
  bg = @cachedTexture
  cols = Math.floor(@image.width / bg.width)
  lines = Math.floor(@image.height / bg.height)
  x = undefined
  y = undefined
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
Morph::drawOn = (aCanvas, aRect) ->
  rectangle = undefined
  area = undefined
  delta = undefined
  src = undefined
  context = undefined
  w = undefined
  h = undefined
  sl = undefined
  st = undefined
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
    context.drawImage @image, Math.round(src.left()), Math.round(src.top()), Math.round(w), Math.round(h), Math.round(area.left()), Math.round(area.top()), Math.round(w), Math.round(h)


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
Morph::fullDrawOn = (aCanvas, aRect) ->
  rectangle = undefined
  return null  unless @isVisible
  rectangle = aRect or @fullBounds()
  @drawOn aCanvas, rectangle
  @children.forEach (child) ->
    child.fullDrawOn aCanvas, rectangle


Morph::hide = ->
  @isVisible = false
  @changed()
  @children.forEach (child) ->
    child.hide()


Morph::show = ->
  @isVisible = true
  @changed()
  @children.forEach (child) ->
    child.show()


Morph::toggleVisibility = ->
  @isVisible = (not @isVisible)
  @changed()
  @children.forEach (child) ->
    child.toggleVisibility()



# Morph full image:
Morph::fullImageClassic = ->
  
  # why doesn't this work for all Morphs?
  fb = @fullBounds()
  img = newCanvas(fb.extent())
  @fullDrawOn img, fb
  img.globalAlpha = @alpha
  img

Morph::fullImage = ->
  img = undefined
  ctx = undefined
  fb = undefined
  img = newCanvas(@fullBounds().extent())
  ctx = img.getContext("2d")
  fb = @fullBounds()
  @allChildren().forEach (morph) ->
    if morph.isVisible
      ctx.globalAlpha = morph.alpha
      ctx.drawImage morph.image, Math.round(morph.bounds.origin.x - fb.origin.x), Math.round(morph.bounds.origin.y - fb.origin.y)
  
  img


# Morph shadow:
Morph::shadowImage = (off_, color) ->
  
  # fallback for Windows Chrome-Shadow bug
  fb = undefined
  img = undefined
  outline = undefined
  sha = undefined
  ctx = undefined
  offset = off_ or new Point(7, 7)
  clr = color or new Color(0, 0, 0)
  fb = @fullBounds().extent()
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

Morph::shadowImageBlurred = (off_, color) ->
  fb = undefined
  img = undefined
  sha = undefined
  ctx = undefined
  offset = off_ or new Point(7, 7)
  blur = @shadowBlur
  clr = color or new Color(0, 0, 0)
  fb = @fullBounds().extent().add(blur * 2)
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

Morph::shadow = (off_, a, color) ->
  shadow = new ShadowMorph()
  offset = off_ or new Point(7, 7)
  alpha = a or ((if (a is 0) then 0 else 0.2))
  fb = @fullBounds()
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

Morph::addShadow = (off_, a, color) ->
  shadow = undefined
  offset = off_ or new Point(7, 7)
  alpha = a or ((if (a is 0) then 0 else 0.2))
  shadow = @shadow(offset, alpha, color)
  @addBack shadow
  @fullChanged()
  shadow

Morph::getShadow = ->
  shadows = undefined
  shadows = @children.slice(0).reverse().filter((child) ->
    child instanceof ShadowMorph
  )
  return shadows[0]  if shadows.length isnt 0
  null

Morph::removeShadow = ->
  shadow = @getShadow()
  if shadow isnt null
    @fullChanged()
    @removeChild shadow


# Morph pen trails:
Morph::penTrails = ->
  
  # answer my pen trails canvas. default is to answer my image
  @image


# Morph updating:
Morph::changed = ->
  if @trackChanges
    w = @root()
    w.broken.push @visibleBounds().spread()  if w instanceof WorldMorph
  @parent.childChanged this  if @parent

Morph::fullChanged = ->
  if @trackChanges
    w = @root()
    w.broken.push @fullBounds().spread()  if w instanceof WorldMorph

Morph::childChanged = ->
  
  # react to a  change in one of my children,
  # default is to just pass this message on upwards
  # override this method for Morphs that need to adjust accordingly
  @parent.childChanged this  if @parent


# Morph accessing - structure:
Morph::world = ->
  root = @root()
  return root  if root instanceof WorldMorph
  return root.world  if root instanceof HandMorph
  null

Morph::add = (aMorph) ->
  owner = aMorph.parent
  owner.removeChild aMorph  if owner isnt null
  @addChild aMorph

Morph::addBack = (aMorph) ->
  owner = aMorph.parent
  owner.removeChild aMorph  if owner isnt null
  @addChildFirst aMorph

Morph::topMorphSuchThat = (predicate) ->
  next = undefined
  if predicate.call(null, this)
    next = detect(@children.slice(0).reverse(), predicate)
    return next.topMorphSuchThat(predicate)  if next
    return this
  null

Morph::morphAt = (aPoint) ->
  morphs = @allChildren().slice(0).reverse()
  result = null
  morphs.forEach (m) ->
    result = m  if m.fullBounds().containsPoint(aPoint) and (result is null)
  
  result


#
#	alternative -  more elegant and possibly more
#	performant - solution for morphAt.
#	Has some issues, commented out for now
#
#Morph.prototype.morphAt = function (aPoint) {
#	return this.topMorphSuchThat(function (m) {
#		return m.fullBounds().containsPoint(aPoint);
#	});
#};
#
Morph::overlappedMorphs = ->
  
  #exclude the World
  world = @world()
  fb = @fullBounds()
  myself = this
  allParents = @allParents()
  allChildren = @allChildren()
  morphs = undefined
  morphs = world.allChildren()
  morphs.filter (m) ->
    m.isVisible and m isnt myself and m isnt world and not contains(allParents, m) and not contains(allChildren, m) and m.fullBounds().intersects(fb)



# Morph pixel access:
Morph::getPixelColor = (aPoint) ->
  point = undefined
  context = undefined
  data = undefined
  point = aPoint.subtract(@bounds.origin)
  context = @image.getContext("2d")
  data = context.getImageData(point.x, point.y, 1, 1)
  new Color(data.data[0], data.data[1], data.data[2], data.data[3])

Morph::isTransparentAt = (aPoint) ->
  point = undefined
  context = undefined
  data = undefined
  if @bounds.containsPoint(aPoint)
    return false  if @texture
    point = aPoint.subtract(@bounds.origin)
    context = @image.getContext("2d")
    data = context.getImageData(Math.floor(point.x), Math.floor(point.y), 1, 1)
    return data.data[3] is 0
  false


# Morph duplicating:
Morph::copy = ->
  c = copy(this)
  c.parent = null
  c.children = []
  c.bounds = @bounds.copy()
  c

Morph::fullCopy = ->
  
  #
  #	Produce a copy of me with my entire tree of submorphs. Morphs
  #	mentioned more than once are all directed to a single new copy.
  #	Other properties are also *shallow* copied, so you must override
  #	to deep copy Arrays and (complex) Objects
  #	
  dict = {}
  c = undefined
  c = @copyRecordingReferences(dict)
  c.forAllChildren (m) ->
    m.updateReferences dict
  
  c

Morph::copyRecordingReferences = (dict) ->
  
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
  dict[this] = c
  @children.forEach (m) ->
    c.add m.copyRecordingReferences(dict)
  
  c

Morph::updateReferences = (dict) ->
  
  #
  #	Update intra-morph references within a composite morph that has
  #	been copied. For example, if a button refers to morph X in the
  #	orginal composite then the copy of that button in the new composite
  #	should refer to the copy of X in new composite, not the original X.
  #	
  property = undefined
  for property of this
    this[property] = dict[property]  if property.isMorph and dict[property]


# Morph dragging and dropping:
Morph::rootForGrab = ->
  return @parent.rootForGrab()  if this instanceof ShadowMorph
  return @parent  if @parent instanceof ScrollFrameMorph
  return this  if @parent is null or @parent instanceof WorldMorph or @parent instanceof FrameMorph or @isDraggable is true
  @parent.rootForGrab()

Morph::wantsDropOf = (aMorph) ->
  
  # default is to answer the general flag - change for my heirs
  return false  if (aMorph instanceof HandleMorph) or (aMorph instanceof MenuMorph) or (aMorph instanceof InspectorMorph)
  @acceptsDrops

Morph::pickUp = (wrrld) ->
  world = wrrld or @world()
  @setPosition world.hand.position().subtract(@extent().floorDivideBy(2))
  world.hand.grab this

Morph::isPickedUp = ->
  @parentThatIsA(HandMorph) isnt null

Morph::situation = ->
  
  # answer a dictionary specifying where I am right now, so
  # I can slide back to it if I'm dropped somewhere else
  if @parent
    return (
      origin: @parent
      position: @position().subtract(@parent.position())
    )
  null

Morph::slideBackTo = (situation, inSteps) ->
  steps = inSteps or 5
  pos = situation.origin.position().add(situation.position)
  xStep = -(@left() - pos.x) / steps
  yStep = -(@top() - pos.y) / steps
  stepCount = 0
  oldStep = @step
  oldFps = @fps
  myself = this
  @fps = 0
  @step = ->
    myself.fullChanged()
    myself.silentMoveBy new Point(xStep, yStep)
    myself.fullChanged()
    stepCount += 1
    if stepCount is steps
      situation.origin.add myself
      situation.origin.reactToDropOf myself  if situation.origin.reactToDropOf
      myself.step = oldStep
      myself.fps = oldFps


# Morph utilities:
Morph::nop = ->
  nop()

Morph::resize = ->
  @world().activeHandle = new HandleMorph(this)

Morph::move = ->
  @world().activeHandle = new HandleMorph(this, null, null, null, null, "move")

Morph::hint = (msg) ->
  m = undefined
  text = undefined
  text = msg
  if msg
    text = msg.toString()  if msg.toString
  else
    text = "NULL"
  m = new MenuMorph(this, text)
  m.isDraggable = true
  m.popUpCenteredAtHand @world()

Morph::inform = (msg) ->
  m = undefined
  text = undefined
  text = msg
  if msg
    text = msg.toString()  if msg.toString
  else
    text = "NULL"
  m = new MenuMorph(this, text)
  m.addItem "Ok"
  m.isDraggable = true
  m.popUpCenteredAtHand @world()

Morph::prompt = (msg, callback, environment, defaultContents, width, floorNum, ceilingNum, isRounded) ->
  menu = undefined
  entryField = undefined
  slider = undefined
  isNumeric = undefined
  isNumeric = true  if ceilingNum
  menu = new MenuMorph(callback or null, msg or "", environment or null)
  entryField = new StringFieldMorph(defaultContents or "", width or 100, MorphicPreferences.prompterFontSize, MorphicPreferences.prompterFontName, false, false, isNumeric)
  menu.items.push entryField
  if ceilingNum or MorphicPreferences.useSliderForInput
    slider = new SliderMorph(floorNum or 0, ceilingNum, parseFloat(defaultContents), Math.floor((ceilingNum - floorNum) / 4), "horizontal")
    slider.alpha = 1
    slider.color = new Color(225, 225, 225)
    slider.button.color = menu.borderColor
    slider.button.highlightColor = slider.button.color.copy()
    slider.button.highlightColor.b += 100
    slider.button.pressColor = slider.button.color.copy()
    slider.button.pressColor.b += 150
    slider.setHeight MorphicPreferences.prompterSliderSize
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
  
  menu.addItem "Cancel", ->
    null
  
  menu.isDraggable = true
  menu.popUpAtHand @world()
  entryField.text.edit()

Morph::pickColor = (msg, callback, environment, defaultContents) ->
  menu = undefined
  colorPicker = undefined
  menu = new MenuMorph(callback or null, msg or "", environment or null)
  colorPicker = new ColorPickerMorph(defaultContents)
  menu.items.push colorPicker
  menu.addLine 2
  menu.addItem "Ok", ->
    colorPicker.getChoice()
  
  menu.addItem "Cancel", ->
    null
  
  menu.isDraggable = true
  menu.popUpAtHand @world()

Morph::inspect = (anotherObject) ->
  world = @world()
  inspector = undefined
  inspectee = this
  inspectee = anotherObject  if anotherObject
  inspector = new InspectorMorph(inspectee)
  inspector.setPosition world.hand.position()
  inspector.keepWithin world
  world.add inspector
  inspector.changed()


# Morph menus:
Morph::contextMenu = ->
  world = undefined
  return @customContextMenu  if @customContextMenu
  world = @world()
  if world and world.isDevMode
    return @developersMenu()  if @parent is world
    return @hierarchyMenu()
  @userMenu() or (@parent and @parent.userMenu())

Morph::hierarchyMenu = ->
  parents = @allParents()
  world = @world()
  menu = new MenuMorph(this, null)
  parents.forEach (each) ->
    if each.developersMenu and (each isnt world)
      menu.addItem each.toString().slice(0, 50), ->
        each.developersMenu().popUpAtHand world
  
  
  menu

Morph::developersMenu = ->
  
  # 'name' is not an official property of a function, hence:
  world = @world()
  userMenu = @userMenu() or (@parent and @parent.userMenu())
  menu = new MenuMorph(this, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
  if userMenu
    menu.addItem "user features...", ->
      userMenu.popUpAtHand world
    
    menu.addLine()
  menu.addItem "color...", (->
    @pickColor menu.title + "\ncolor:", @setColor, this, @color
  ), "choose another color \nfor this morph"
  menu.addItem "transparency...", (->
    @prompt menu.title + "\nalpha\nvalue:", @setAlphaScaled, this, (@alpha * 100).toString(), null, 1, 100, true
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
  unless this instanceof WorldMorph
    menu.addLine()
    menu.addItem "World...", (->
      world.contextMenu().popUpAtHand world
    ), "show the\nWorld's menu"
  menu

Morph::userMenu = ->
  null


# Morph menu actions
Morph::setAlphaScaled = (alpha) ->
  
  # for context menu demo purposes
  newAlpha = undefined
  unscaled = undefined
  if typeof alpha is "number"
    unscaled = alpha / 100
    @alpha = Math.min(Math.max(unscaled, 0.1), 1)
  else
    newAlpha = parseFloat(alpha)
    unless isNaN(newAlpha)
      unscaled = newAlpha / 100
      @alpha = Math.min(Math.max(unscaled, 0.1), 1)
  @changed()

Morph::attach = ->
  choices = @overlappedMorphs()
  menu = new MenuMorph(this, "choose new parent:")
  myself = this
  choices.forEach (each) ->
    menu.addItem each.toString().slice(0, 50), ->
      each.add myself
      myself.isDraggable = false


  menu.popUpAtHand @world()  if choices.length > 0

Morph::toggleIsDraggable = ->
  
  # for context menu demo purposes
  @isDraggable = not @isDraggable

Morph::colorSetters = ->
  
  # for context menu demo purposes
  ["color"]

Morph::numericalSetters = ->
  
  # for context menu demo purposes
  ["setLeft", "setTop", "setWidth", "setHeight", "setAlphaScaled"]


# Morph entry field tabbing:
Morph::allEntryFields = ->
  @allChildren().filter (each) ->
    each.isEditable


Morph::nextEntryField = (current) ->
  fields = @allEntryFields()
  idx = fields.indexOf(current)
  if idx isnt -1
    return fields[idx + 1]  if fields.length > (idx - 1)
    fields[0]

Morph::previousEntryField = (current) ->
  fields = @allEntryFields()
  idx = fields.indexOf(current)
  if idx isnt -1
    return fields[idx - 1]  if (idx - 1) > fields.length
    fields[fields.length + 1]

Morph::tab = (editField) ->
  
  #
  #	the <tab> key was pressed in one of my edit fields.
  #	invoke my "nextTab()" function if it exists, else
  #	propagate it up my owner chain.
  #
  if @nextTab
    @nextTab editField
  else @parent.tab editField  if @parent

Morph::backTab = (editField) ->
  
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
Morph::escalateEvent = (functionName, arg) ->
  handler = @parent
  handler = handler.parent  while not handler[functionName] and handler.parent isnt null
  handler[functionName] arg  if handler[functionName]


# Morph eval:
Morph::evaluateString = (code) ->
  result = undefined
  try
    result = eval(code)
    @drawNew()
    @changed()
  catch err
    @inform err
  result


# Morph collision detection:
Morph::isTouching = (otherMorph) ->
  oImg = @overlappingImage(otherMorph)
  data = oImg.getContext("2d").getImageData(1, 1, oImg.width, oImg.height).data
  detect(data, (each) ->
    each isnt 0
  ) isnt null

Morph::overlappingImage = (otherMorph) ->
  fb = @fullBounds()
  otherFb = otherMorph.fullBounds()
  oRect = fb.intersect(otherFb)
  oImg = newCanvas(oRect.extent())
  ctx = oImg.getContext("2d")
  return newCanvas(new Point(1, 1))  if oRect.width() < 1 or oRect.height() < 1
  ctx.drawImage @fullImage(), Math.round(oRect.origin.x - fb.origin.x), Math.round(oRect.origin.y - fb.origin.y)
  ctx.globalCompositeOperation = "source-in"
  ctx.drawImage otherMorph.fullImage(), Math.round(otherFb.origin.x - oRect.origin.x), Math.round(otherFb.origin.y - oRect.origin.y)
  oImg
# ColorPaletteMorph ///////////////////////////////////////////////////

class ColorPaletteMorph extends Morph
  constructor: (target, sizePoint) ->
    @init target or null, sizePoint or new Point(80, 50)

# ColorPaletteMorph instance creation:
ColorPaletteMorph::init = (target, size) ->
  super()
  @target = target
  @targetSetter = "color"
  @silentSetExtent size
  @choice = null
  @drawNew()

ColorPaletteMorph::drawNew = ->
  context = undefined
  ext = undefined
  x = undefined
  y = undefined
  h = undefined
  l = undefined
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

ColorPaletteMorph::mouseMove = (pos) ->
  @choice = @getPixelColor(pos)
  @updateTarget()

ColorPaletteMorph::mouseDownLeft = (pos) ->
  @choice = @getPixelColor(pos)
  @updateTarget()

ColorPaletteMorph::updateTarget = ->
  if @target instanceof Morph and @choice isnt null
    if @target[@targetSetter] instanceof Function
      @target[@targetSetter] @choice
    else
      @target[@targetSetter] = @choice
      @target.drawNew()
      @target.changed()


# ColorPaletteMorph duplicating:
ColorPaletteMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.target = (dict[@target])  if c.target and dict[@target]
  c


# ColorPaletteMorph menu:
ColorPaletteMorph::developersMenu = ->
  menu = super()
  menu.addLine()
  menu.addItem "set target", "setTarget", "choose another morph\nwhose color property\n will be" + " controlled by this one"
  menu

ColorPaletteMorph::setTarget = ->
  choices = @overlappedMorphs()
  menu = new MenuMorph(this, "choose target:")
  myself = this
  choices.push @world()
  choices.forEach (each) ->
    menu.addItem each.toString().slice(0, 50), ->
      myself.target = each
      myself.setTargetSetter()
  
  
  if choices.length is 1
    @target = choices[0]
    @setTargetSetter()
  else menu.popUpAtHand @world()  if choices.length > 0

ColorPaletteMorph::setTargetSetter = ->
  choices = @target.colorSetters()
  menu = new MenuMorph(this, "choose target property:")
  myself = this
  choices.forEach (each) ->
    menu.addItem each, ->
      myself.targetSetter = each
  
  
  if choices.length is 1
    @targetSetter = choices[0]
  else menu.popUpAtHand @world()  if choices.length > 0
# GrayPaletteMorph ///////////////////////////////////////////////////

class GrayPaletteMorph extends ColorPaletteMorph
  constructor: (target, sizePoint) ->
    @init target or null, sizePoint or new Point(80, 10)

# GrayPaletteMorph instance creation:
GrayPaletteMorph::drawNew = ->
  context = undefined
  ext = undefined
  gradient = undefined
  ext = @extent()
  @image = newCanvas(@extent())
  context = @image.getContext("2d")
  @choice = new Color()
  gradient = context.createLinearGradient(0, 0, ext.x, ext.y)
  gradient.addColorStop 0, "black"
  gradient.addColorStop 1, "white"
  context.fillStyle = gradient
  context.fillRect 0, 0, ext.x, ext.y
# FrameMorph //////////////////////////////////////////////////////////

# I clip my submorphs at my bounds

class FrameMorph extends Morph
  constructor: (aScrollFrame) ->
    @init aScrollFrame

FrameMorph::init = (aScrollFrame) ->
  @scrollFrame = aScrollFrame or null
  super()
  @color = new Color(255, 250, 245)
  @drawNew()
  @acceptsDrops = true
  if @scrollFrame
    @isDraggable = false
    @noticesTransparentClick = false
    @alpha = 0

FrameMorph::fullBounds = ->
  shadow = @getShadow()
  return @bounds.merge(shadow.bounds)  if shadow isnt null
  @bounds

FrameMorph::fullImage = ->
  
  # use only for shadows
  @image

FrameMorph::fullDrawOn = (aCanvas, aRect) ->
  myself = this
  rectangle = undefined
  return null  unless @isVisible
  rectangle = aRect or @fullBounds()
  @drawOn aCanvas, rectangle
  @children.forEach (child) ->
    if child instanceof ShadowMorph
      child.fullDrawOn aCanvas, rectangle
    else
      child.fullDrawOn aCanvas, myself.bounds.intersect(rectangle)



# FrameMorph scrolling optimization:
FrameMorph::moveBy = (delta) ->
  @changed()
  @bounds = @bounds.translateBy(delta)
  @children.forEach (child) ->
    child.silentMoveBy delta
  
  @changed()


# FrameMorph scrolling support:
FrameMorph::submorphBounds = ->
  result = null
  if @children.length > 0
    result = @children[0].bounds
    @children.forEach (child) ->
      result = result.merge(child.fullBounds())
  
  result

FrameMorph::keepInScrollFrame = ->
  return null  if @scrollFrame is null
  @moveBy new Point(@scrollFrame.left() - @left(), 0)  if @left() > @scrollFrame.left()
  @moveBy new Point(@scrollFrame.right() - @right(), 0)  if @right() < @scrollFrame.right()
  @moveBy new Point(0, @scrollFrame.top() - @top())  if @top() > @scrollFrame.top()
  @moveBy 0, new Point(@scrollFrame.bottom() - @bottom(), 0)  if @bottom() < @scrollFrame.bottom()

FrameMorph::adjustBounds = ->
  subBounds = undefined
  newBounds = undefined
  myself = this
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
    @children.forEach (morph) ->
      if morph instanceof TextMorph
        morph.setWidth myself.width()
        myself.setHeight Math.max(morph.height(), myself.scrollFrame.height())
  
  @scrollFrame.adjustScrollBars()


# FrameMorph dragging & dropping of contents:
FrameMorph::reactToDropOf = ->
  @adjustBounds()

FrameMorph::reactToGrabOf = ->
  @adjustBounds()


# FrameMorph duplicating:
FrameMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.frame = (dict[@scrollFrame])  if c.frame and dict[@scrollFrame]
  c


# FrameMorph menus:
FrameMorph::developersMenu = ->
  menu = super()
  if @children.length > 0
    menu.addLine()
    menu.addItem "move all inside...", "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
  menu

FrameMorph::keepAllSubmorphsWithin = ->
  myself = this
  @children.forEach (m) ->
    m.keepWithin myself
# ScrollFrameMorph ////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class ScrollFrameMorph extends FrameMorph
  constructor: (scroller, size, sliderColor) ->
    @init scroller, size, sliderColor


ScrollFrameMorph::init = (scroller, size, sliderColor) ->
  myself = this
  super()
  @scrollBarSize = size or MorphicPreferences.scrollBarSize
  @autoScrollTrigger = null
  @isScrollingByDragging = true # change if desired
  @hasVelocity = true # dto.
  @padding = 0 # around the scrollable area
  @growth = 0 # pixels or Point to grow right/left when near edge
  @isTextLineWrapping = false
  @contents = scroller or new FrameMorph(this)
  @add @contents
  # start
  # stop
  # value
  # size
  @hBar = new SliderMorph(null, null, null, null, "horizontal", sliderColor)
  @hBar.setHeight @scrollBarSize
  @hBar.action = (num) ->
    myself.contents.setPosition new Point(myself.left() - num, myself.contents.position().y)
  
  @hBar.isDraggable = false
  @add @hBar
  # start
  # stop
  # value
  # size
  @vBar = new SliderMorph(null, null, null, null, "vertical", sliderColor)
  @vBar.setWidth @scrollBarSize
  @vBar.action = (num) ->
    myself.contents.setPosition new Point(myself.contents.position().x, myself.top() - num)
  
  @vBar.isDraggable = false
  @add @vBar

ScrollFrameMorph::adjustScrollBars = ->
  hWidth = @width() - @scrollBarSize
  vHeight = @height() - @scrollBarSize
  @changed()
  if @contents.width() > @width() + MorphicPreferences.scrollBarSize
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

ScrollFrameMorph::addContents = (aMorph) ->
  @contents.add aMorph
  @contents.adjustBounds()

ScrollFrameMorph::setContents = (aMorph) ->
  @contents.children.forEach (m) ->
    m.destroy()
  
  @contents.children = []
  aMorph.setPosition @position().add(new Point(2, 2))
  @addContents aMorph

ScrollFrameMorph::setExtent = (aPoint) ->
  @contents.setPosition @position().copy()  if @isTextLineWrapping
  super aPoint
  @contents.adjustBounds()


# ScrollFrameMorph scrolling by dragging:
ScrollFrameMorph::scrollX = (steps) ->
  cl = @contents.left()
  l = @left()
  cw = @contents.width()
  r = @right()
  newX = undefined
  newX = cl + steps
  newX = l  if newX > l
  newX = r - cw  if newX + cw < r
  @contents.setLeft newX  if newX isnt cl

ScrollFrameMorph::scrollY = (steps) ->
  ct = @contents.top()
  t = @top()
  ch = @contents.height()
  b = @bottom()
  newY = undefined
  newY = ct + steps
  newY = t  if newY > t
  newY = b - ch  if newY + ch < b
  @contents.setTop newY  if newY isnt ct

ScrollFrameMorph::step = noOpFunction

ScrollFrameMorph::mouseDownLeft = (pos) ->
  return null  unless @isScrollingByDragging
  world = @root()
  oldPos = pos
  myself = this
  deltaX = 0
  deltaY = 0
  friction = 0.8
  @step = ->
    newPos = undefined
    if world.hand.mouseButton and (world.hand.children.length is 0) and (myself.bounds.containsPoint(world.hand.position()))
      newPos = world.hand.bounds.origin
      deltaX = newPos.x - oldPos.x
      myself.scrollX deltaX  if deltaX isnt 0
      deltaY = newPos.y - oldPos.y
      myself.scrollY deltaY  if deltaY isnt 0
      oldPos = newPos
    else
      unless myself.hasVelocity
        myself.step = noOpFunction
      else
        if (Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5)
          myself.step = noOpFunction
        else
          deltaX = deltaX * friction
          myself.scrollX Math.round(deltaX)
          deltaY = deltaY * friction
          myself.scrollY Math.round(deltaY)
    @adjustScrollBars()

ScrollFrameMorph::startAutoScrolling = ->
  myself = this
  inset = MorphicPreferences.scrollBarSize * 3
  world = @world()
  hand = undefined
  inner = undefined
  pos = undefined
  return null  unless world
  hand = world.hand
  @autoScrollTrigger = Date.now()  unless @autoScrollTrigger
  @step = ->
    pos = hand.bounds.origin
    inner = myself.bounds.insetBy(inset)
    if (myself.bounds.containsPoint(pos)) and (not (inner.containsPoint(pos))) and (hand.children.length > 0)
      myself.autoScroll pos
    else
      myself.step = noOpFunction
      
      myself.autoScrollTrigger = null

ScrollFrameMorph::autoScroll = (pos) ->
  inset = undefined
  area = undefined
  return null  if Date.now() - @autoScrollTrigger < 500
  inset = MorphicPreferences.scrollBarSize * 3
  area = @topLeft().extent(new Point(@width(), inset))
  @scrollY inset - (pos.y - @top())  if area.containsPoint(pos)
  area = @topLeft().extent(new Point(inset, @height()))
  @scrollX inset - (pos.x - @left())  if area.containsPoint(pos)
  area = (new Point(@right() - inset, @top())).extent(new Point(inset, @height()))
  @scrollX -(inset - (@right() - pos.x))  if area.containsPoint(pos)
  area = (new Point(@left(), @bottom() - inset)).extent(new Point(@width(), inset))
  @scrollY -(inset - (@bottom() - pos.y))  if area.containsPoint(pos)
  @adjustScrollBars()


# ScrollFrameMorph events:
ScrollFrameMorph::mouseScroll = (y, x) ->
  @scrollY y * MorphicPreferences.mouseScrollAmount  if y
  @scrollX x * MorphicPreferences.mouseScrollAmount  if x
  @adjustScrollBars()

ScrollFrameMorph::copyRecordingReferences = (dict) ->
  
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

ScrollFrameMorph::developersMenu = ->
  menu = super()
  if @isTextLineWrapping
    menu.addItem "auto line wrap off...", "toggleTextLineWrapping", "turn automatic\nline wrapping\noff"
  else
    menu.addItem "auto line wrap on...", "toggleTextLineWrapping", "enable automatic\nline wrapping"
  menu

ScrollFrameMorph::toggleTextLineWrapping = ->
  @isTextLineWrapping = not @isTextLineWrapping
# TextMorph ///////////////////////////////////////////////////////////

# I am a multi-line, word-wrapping String

class TextMorph extends Morph
  constructor: (text, fontSize, fontStyle, bold, italic, alignment, width, fontName, shadowOffset, shadowColor) ->
    @init text, fontSize, fontStyle, bold, italic, alignment, width, fontName, shadowOffset, shadowColor


# TextMorph instance creation:
TextMorph::init = (text, fontSize, fontStyle, bold, italic, alignment, width, fontName, shadowOffset, shadowColor) ->
  
  # additional properties:
  @text = text or ((if text is "" then text else "TextMorph"))
  @words = []
  @lines = []
  @lineSlots = []
  @fontSize = fontSize or 12
  @fontName = fontName or MorphicPreferences.globalFontFamily
  @fontStyle = fontStyle or "sans-serif"
  @isBold = bold or false
  @isItalic = italic or false
  @alignment = alignment or "left"
  @shadowOffset = shadowOffset or new Point(0, 0)
  @shadowColor = shadowColor or null
  @maxWidth = width or 0
  @maxLineWidth = 0
  @backgroundColor = null
  @isEditable = false
  
  #additional properties for ad-hoc evaluation:
  @receiver = null
  
  # additional properties for text-editing:
  @currentlySelecting = false
  @startMark = 0
  @endMark = 0
  @markedTextColor = new Color(255, 255, 255)
  @markedBackgoundColor = new Color(60, 60, 120)
  
  # initialize inherited properties:
  super()
  
  # override inherited properites:
  @color = new Color(0, 0, 0)
  @noticesTransparentClick = true
  @drawNew()

TextMorph::toString = ->
  
  # e.g. 'a TextMorph("Hello World")'
  "a TextMorph" + "(\"" + @text.slice(0, 30) + "...\")"

TextMorph::font = ->
  
  # answer a font string, e.g. 'bold italic 12px sans-serif'
  font = ""
  font = font + "bold "  if @isBold
  font = font + "italic "  if @isItalic
  font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle

TextMorph::parse = ->
  myself = this
  paragraphs = @text.split("\n")
  canvas = newCanvas()
  context = canvas.getContext("2d")
  oldline = ""
  newline = undefined
  w = undefined
  slot = 0
  context.font = @font()
  @maxLineWidth = 0
  @lines = []
  @lineSlots = [0]
  @words = []
  paragraphs.forEach (p) ->
    myself.words = myself.words.concat(p.split(" "))
    myself.words.push "\n"
  
  @words.forEach (word) ->
    if word is "\n"
      myself.lines.push oldline
      myself.lineSlots.push slot
      myself.maxLineWidth = Math.max(myself.maxLineWidth, context.measureText(oldline).width)
      oldline = ""
    else
      if myself.maxWidth > 0
        newline = oldline + word + " "
        w = context.measureText(newline).width
        if w > myself.maxWidth
          myself.lines.push oldline
          myself.lineSlots.push slot
          myself.maxLineWidth = Math.max(myself.maxLineWidth, context.measureText(oldline).width)
          oldline = word + " "
        else
          oldline = newline
      else
        oldline = oldline + word + " "
      slot += word.length + 1


TextMorph::drawNew = ->
  context = undefined
  height = undefined
  i = undefined
  line = undefined
  width = undefined
  shadowHeight = undefined
  shadowWidth = undefined
  offx = undefined
  offy = undefined
  x = undefined
  y = undefined
  start = undefined
  stop = undefined
  p = undefined
  c = undefined
  @image = newCanvas()
  context = @image.getContext("2d")
  context.font = @font()
  @parse()
  
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
  
  # prepare context for drawing text
  context = @image.getContext("2d")
  context.font = @font()
  context.textAlign = "left"
  context.textBaseline = "bottom"
  
  # fill the background, if desired
  if @backgroundColor
    context.fillStyle = @backgroundColor.toString()
    context.fillRect 0, 0, @width(), @height()
  
  # draw the shadow, if any
  if @shadowColor
    offx = Math.max(@shadowOffset.x, 0)
    offy = Math.max(@shadowOffset.y, 0)
    context.fillStyle = @shadowColor.toString()
    i = 0
    while i < @lines.length
      line = @lines[i]
      width = context.measureText(line).width + shadowWidth
      if @alignment is "right"
        x = @width() - width
      else if @alignment is "center"
        x = (@width() - width) / 2
      else # 'left'
        x = 0
      y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
      context.fillText line, x + offx, y + offy
      i = i + 1
  
  # now draw the actual text
  offx = Math.abs(Math.min(@shadowOffset.x, 0))
  offy = Math.abs(Math.min(@shadowOffset.y, 0))
  context.fillStyle = @color.toString()
  i = 0
  while i < @lines.length
    line = @lines[i]
    width = context.measureText(line).width + shadowWidth
    if @alignment is "right"
      x = @width() - width
    else if @alignment is "center"
      x = (@width() - width) / 2
    else # 'left'
      x = 0
    y = (i + 1) * (fontHeight(@fontSize) + shadowHeight) - shadowHeight
    context.fillText line, x + offx, y + offy
    i = i + 1
  
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
  
  # notify my parent of layout change
  @parent.layoutChanged()  if @parent.layoutChanged  if @parent

TextMorph::setExtent = (aPoint) ->
  @maxWidth = Math.max(aPoint.x, 0)
  @changed()
  @drawNew()


# TextMorph mesuring:
TextMorph::columnRow = (slot) ->
  
  # answer the logical position point of the given index ("slot")
  row = undefined
  col = undefined
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
  
  # return new Point(0, 0);
  new Point(@lines[@lines.length - 1].length - 1, @lines.length - 1)

TextMorph::slotPosition = (slot) ->
  
  # answer the physical position point of the given index ("slot")
  # where the cursor should be placed
  colRow = @columnRow(slot)
  context = @image.getContext("2d")
  shadowHeight = Math.abs(@shadowOffset.y)
  xOffset = 0
  yOffset = undefined
  x = undefined
  y = undefined
  idx = undefined
  yOffset = colRow.y * (fontHeight(@fontSize) + shadowHeight)
  idx = 0
  while idx < colRow.x
    xOffset += context.measureText(@lines[colRow.y][idx]).width
    idx += 1
  x = @left() + xOffset
  y = @top() + yOffset
  new Point(x, y)

TextMorph::slotAt = (aPoint) ->
  
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

TextMorph::upFrom = (slot) ->
  
  # answer the slot above the given one
  above = undefined
  colRow = @columnRow(slot)
  return slot  if colRow.y < 1
  above = @lines[colRow.y - 1]
  return @lineSlots[colRow.y - 1] + above.length  if above.length < colRow.x - 1
  @lineSlots[colRow.y - 1] + colRow.x

TextMorph::downFrom = (slot) ->
  
  # answer the slot below the given one
  below = undefined
  colRow = @columnRow(slot)
  return slot  if colRow.y > @lines.length - 2
  below = @lines[colRow.y + 1]
  return @lineSlots[colRow.y + 1] + below.length  if below.length < colRow.x - 1
  @lineSlots[colRow.y + 1] + colRow.x

TextMorph::startOfLine = (slot) ->
  
  # answer the first slot (index) of the line for the given slot
  @lineSlots[@columnRow(slot).y]

TextMorph::endOfLine = (slot) ->
  
  # answer the slot (index) indicating the EOL for the given slot
  @startOfLine(slot) + @lines[@columnRow(slot).y].length - 1


# TextMorph editing:
TextMorph::edit = ->
  @root().edit this

TextMorph::selection = ->
  start = undefined
  stop = undefined
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  @text.slice start, stop

TextMorph::selectionStartSlot = ->
  Math.min @startMark, @endMark

TextMorph::clearSelection = ->
  @currentlySelecting = false
  @startMark = 0
  @endMark = 0
  @drawNew()
  @changed()

TextMorph::deleteSelection = ->
  start = undefined
  stop = undefined
  text = undefined
  text = @text
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  @text = text.slice(0, start) + text.slice(stop)
  @changed()
  @clearSelection()

TextMorph::selectAll = ->
  @startMark = 0
  @endMark = @text.length
  @drawNew()
  @changed()

TextMorph::selectAllAndEdit = ->
  @edit()
  @selectAll()

TextMorph::mouseClickLeft = (pos) ->
  if @isEditable
    @edit()  unless @currentlySelecting
    @root().cursor.gotoPos pos
    @currentlySelecting = false
  else
    @escalateEvent "mouseClickLeft", pos

TextMorph::enableSelecting = ->
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

TextMorph::disableSelecting = ->
  delete @mouseDownLeft
  delete @mouseMove


# TextMorph menus:
TextMorph::developersMenu = ->
  menu = super()
  menu.addLine()
  menu.addItem "edit", "edit"
  menu.addItem "font size...", (->
    @prompt menu.title + "\nfont\nsize:", @setFontSize, this, @fontSize.toString(), null, 6, 100, true
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

TextMorph::toggleIsDraggable = ->
  
  # for context menu demo purposes
  @isDraggable = not @isDraggable
  if @isDraggable
    @disableSelecting()
  else
    @enableSelecting()

TextMorph::setAlignmentToLeft = ->
  @alignment = "left"
  @drawNew()
  @changed()

TextMorph::setAlignmentToRight = ->
  @alignment = "right"
  @drawNew()
  @changed()

TextMorph::setAlignmentToCenter = ->
  @alignment = "center"
  @drawNew()
  @changed()

TextMorph::toggleWeight = ->
  @isBold = not @isBold
  @changed()
  @drawNew()
  @changed()

TextMorph::toggleItalic = ->
  @isItalic = not @isItalic
  @changed()
  @drawNew()
  @changed()

TextMorph::setSerif = ->
  @fontStyle = "serif"
  @changed()
  @drawNew()
  @changed()

TextMorph::setSansSerif = ->
  @fontStyle = "sans-serif"
  @changed()
  @drawNew()
  @changed()

TextMorph::setText = (size) ->
  
  # for context menu demo purposes
  @text = Math.round(size).toString()
  @changed()
  @drawNew()
  @changed()

TextMorph::setFontSize = (size) ->
  
  # for context menu demo purposes
  newSize = undefined
  if typeof size is "number"
    @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
  else
    newSize = parseFloat(size)
    @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
  @changed()
  @drawNew()
  @changed()

TextMorph::numericalSetters = ->
  
  # for context menu demo purposes
  ["setLeft", "setTop", "setAlphaScaled", "setFontSize", "setText"]


# TextMorph evaluation:
TextMorph::evaluationMenu = ->
  menu = new MenuMorph(this, null)
  menu.addItem "do it", "doIt", "evaluate the\nselected expression"
  menu.addItem "show it", "showIt", "evaluate the\nselected expression\nand show the result"
  menu.addItem "inspect it", "inspectIt", "evaluate the\nselected expression\nand inspect the result"
  menu.addLine()
  menu.addItem "select all", "selectAllAndEdit"
  menu

TextMorph::setReceiver = (obj) ->
  @receiver = obj
  @customContextMenu = @evaluationMenu()

TextMorph::doIt = ->
  @receiver.evaluateString @selection()
  @edit()

TextMorph::showIt = ->
  result = @receiver.evaluateString(@selection())
  @inform result  if result isnt null

TextMorph::inspectIt = ->
  result = @receiver.evaluateString(@selection())
  world = @world()
  inspector = undefined
  if result isnt null
    inspector = new InspectorMorph(result)
    inspector.setPosition world.hand.position()
    inspector.keepWithin world
    world.add inspector
    inspector.changed()
# BouncerMorph ////////////////////////////////////////////////////////

# I am a Demo of a stepping custom Morph

class BouncerMorph extends Morph
  constructor: () ->
    @init()

# BouncerMorph instance creation:

# BouncerMorph initialization:
BouncerMorph::init = (type, speed) ->
  super()
  @fps = 50
  
  # additional properties:
  @isStopped = false
  @type = type or "vertical"
  if @type is "vertical"
    @direction = "down"
  else
    @direction = "right"
  @speed = speed or 1


# BouncerMorph moving:
BouncerMorph::moveUp = ->
  @moveBy new Point(0, -@speed)

BouncerMorph::moveDown = ->
  @moveBy new Point(0, @speed)

BouncerMorph::moveRight = ->
  @moveBy new Point(@speed, 0)

BouncerMorph::moveLeft = ->
  @moveBy new Point(-@speed, 0)


# BouncerMorph stepping:
BouncerMorph::step = ->
  unless @isStopped
    if @type is "vertical"
      if @direction is "down"
        @moveDown()
      else
        @moveUp()
      @direction = "down"  if @fullBounds().top() < @parent.top() and @direction is "up"
      @direction = "up"  if @fullBounds().bottom() > @parent.bottom() and @direction is "down"
    else if @type is "horizontal"
      if @direction is "right"
        @moveRight()
      else
        @moveLeft()
      @direction = "right"  if @fullBounds().left() < @parent.left() and @direction is "left"
      @direction = "left"  if @fullBounds().right() > @parent.right() and @direction is "right"
# HandleMorph ////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

# I am a resize / move handle that can be attached to any Morph

class HandleMorph extends Morph
  constructor: (target, minX, minY, insetX, insetY, type) ->
    # if insetY is missing, it will be the same as insetX
    @init target, minX, minY, insetX, insetY, type

# HandleMorph instance creation:
HandleMorph::init = (target, minX, minY, insetX, insetY, type) ->
  size = MorphicPreferences.handleSize
  @target = target or null
  @minExtent = new Point(minX or 0, minY or 0)
  @inset = new Point(insetX or 0, insetY or insetX or 0)
  @type = type or "resize" # can also be 'move'
  super()
  @color = new Color(255, 255, 255)
  @isDraggable = false
  @noticesTransparentClick = true
  @setExtent new Point(size, size)


# HandleMorph drawing:
HandleMorph::drawNew = ->
  @normalImage = newCanvas(@extent())
  @highlightImage = newCanvas(@extent())
  @drawOnCanvas @normalImage, @color, new Color(100, 100, 100)
  @drawOnCanvas @highlightImage, new Color(100, 100, 255), new Color(255, 255, 255)
  @image = @normalImage
  if @target
    @setPosition @target.bottomRight().subtract(@extent().add(@inset))
    @target.add this
    @target.changed()

HandleMorph::drawOnCanvas = (aCanvas, color, shadowColor) ->
  context = aCanvas.getContext("2d")
  p1 = undefined
  p11 = undefined
  p2 = undefined
  p22 = undefined
  i = undefined
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
HandleMorph::step = null
HandleMorph::mouseDownLeft = (pos) ->
  world = @root()
  offset = pos.subtract(@bounds.origin)
  myself = this
  return null  unless @target
  @step = ->
    newPos = undefined
    newExt = undefined
    if world.hand.mouseButton
      newPos = world.hand.bounds.origin.copy().subtract(offset)
      if @type is "resize"
        newExt = newPos.add(myself.extent().add(myself.inset)).subtract(myself.target.bounds.origin)
        newExt = newExt.max(myself.minExtent)
        myself.target.setExtent newExt
        myself.setPosition myself.target.bottomRight().subtract(myself.extent().add(myself.inset))
      else # type === 'move'
        myself.target.setPosition newPos.subtract(@target.extent()).add(@extent())
    else
      @step = null
  
  unless @target.step
    @target.step = noOpFunction


# HandleMorph dragging and dropping:
HandleMorph::rootForGrab = ->
  this


# HandleMorph events:
HandleMorph::mouseEnter = ->
  @image = @highlightImage
  @changed()

HandleMorph::mouseLeave = ->
  @image = @normalImage
  @changed()


# HandleMorph duplicating:
HandleMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.target = (dict[@target])  if c.target and dict[@target]
  c


# HandleMorph menu:
HandleMorph::attach = ->
  choices = @overlappedMorphs()
  menu = new MenuMorph(this, "choose target:")
  myself = this
  choices.forEach (each) ->
    menu.addItem each.toString().slice(0, 50), ->
      myself.isDraggable = false
      myself.target = each
      myself.drawNew()
      myself.noticesTransparentClick = true
  
  
  menu.popUpAtHand @world()  if choices.length > 0
# BoxMorph ////////////////////////////////////////////////////////////

# I can have an optionally rounded border

class BoxMorph extends Morph
  constructor: (edge, border, borderColor) ->
    @init edge, border, borderColor

# BoxMorph instance creation:
BoxMorph::init = (edge, border, borderColor) ->
  @edge = edge or 4
  @border = border or ((if (border is 0) then 0 else 2))
  @borderColor = borderColor or new Color()
  super()


# BoxMorph drawing:
BoxMorph::drawNew = ->
  context = undefined
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

BoxMorph::outlinePath = (context, radius, inset) ->
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
BoxMorph::developersMenu = ->
  menu = super()
  menu.addLine()
  menu.addItem "border width...", (->
    @prompt menu.title + "\nborder\nwidth:", @setBorderWidth, this, @border.toString(), null, 0, 100, true
  ), "set the border's\nline size"
  menu.addItem "border color...", (->
    @pickColor menu.title + "\nborder color:", @setBorderColor, this, @borderColor
  ), "set the border's\nline color"
  menu.addItem "corner size...", (->
    @prompt menu.title + "\ncorner\nsize:", @setCornerSize, this, @edge.toString(), null, 0, 100, true
  ), "set the corner's\nradius"
  menu

BoxMorph::setBorderWidth = (size) ->
  
  # for context menu demo purposes
  newSize = undefined
  if typeof size is "number"
    @border = Math.max(size, 0)
  else
    newSize = parseFloat(size)
    @border = Math.max(newSize, 0)  unless isNaN(newSize)
  @drawNew()
  @changed()

BoxMorph::setBorderColor = (color) ->
  
  # for context menu demo purposes
  if color
    @borderColor = color
    @drawNew()
    @changed()

BoxMorph::setCornerSize = (size) ->
  
  # for context menu demo purposes
  newSize = undefined
  if typeof size is "number"
    @edge = Math.max(size, 0)
  else
    newSize = parseFloat(size)
    @edge = Math.max(newSize, 0)  unless isNaN(newSize)
  @drawNew()
  @changed()

BoxMorph::colorSetters = ->
  
  # for context menu demo purposes
  ["color", "borderColor"]

BoxMorph::numericalSetters = ->
  
  # for context menu demo purposes
  list = super()
  list.push "setBorderWidth", "setCornerSize"
  list
# SpeechBubbleMorph ///////////////////////////////////////////////////

#
#	I am a comic-style speech bubble that can display either a string,
#	a Morph, a Canvas or a toString() representation of anything else.
#	If I am invoked using popUp() I behave like a tool tip.
#

class SpeechBubbleMorph extends BoxMorph
  constructor: (contents, color, edge, border, borderColor, padding, isThought) ->
    @init contents, color, edge, border, borderColor, padding, isThought

# SpeechBubbleMorph: referenced constructors

# SpeechBubbleMorph instance creation:
SpeechBubbleMorph::init = (contents, color, edge, border, borderColor, padding, isThought) ->
  @isPointingRight = true # orientation of text
  @contents = contents or ""
  @padding = padding or 0 # additional vertical pixels
  @isThought = isThought or false # draw "think" bubble
  super edge or 6, border or ((if (border is 0) then 0 else 1)), borderColor or new Color(140, 140, 140)
  @color = color or new Color(230, 230, 230)
  @drawNew()


# SpeechBubbleMorph invoking:
SpeechBubbleMorph::popUp = (world, pos) ->
  @drawNew()
  @setPosition pos.subtract(new Point(0, @height()))
  @addShadow new Point(2, 2), 80
  @keepWithin world
  world.add this
  @changed()
  world.hand.destroyTemporaries()
  world.hand.temporaries.push this
  @mouseEnter = ->
    @destroy()


# SpeechBubbleMorph drawing:
SpeechBubbleMorph::drawNew = ->
  
  # re-build my contents
  @contentsMorph.destroy()  if @contentsMorph
  if @contents instanceof Morph
    @contentsMorph = @contents
  else if isString(@contents)
    @contentsMorph = new TextMorph(@contents, MorphicPreferences.bubbleHelpFontSize, null, false, true, "center")
  else if @contents instanceof HTMLCanvasElement
    @contentsMorph = new Morph()
    @contentsMorph.silentSetWidth @contents.width
    @contentsMorph.silentSetHeight @contents.height
    @contentsMorph.image = @contents
  else
    @contentsMorph = new TextMorph(@contents.toString(), MorphicPreferences.bubbleHelpFontSize, null, false, true, "center")
  @add @contentsMorph
  
  # adjust my layout
  @silentSetWidth @contentsMorph.width() + ((if @padding then @padding * 2 else @edge * 2))
  @silentSetHeight @contentsMorph.height() + @edge + @border * 2 + @padding * 2 + 2
  
  # draw my outline
  super()
  
  # position my contents
  @contentsMorph.setPosition @position().add(new Point(@padding or @edge, @border + @padding + 1))

SpeechBubbleMorph::outlinePath = (context, radius, inset) ->
  circle = (x, y, r) ->
    context.moveTo x + r, y
    context.arc x, y, r, radians(0), radians(360)
  offset = radius + inset
  w = @width()
  h = @height()
  rad = undefined
  
  # top left:
  context.arc offset, offset, radius, radians(-180), radians(-90), false
  
  # top right:
  context.arc w - offset, offset, radius, radians(-90), radians(-0), false
  
  # bottom right:
  context.arc w - offset, h - offset - radius, radius, radians(0), radians(90), false
  unless @isThought # draw speech bubble hook
    if @isPointingRight
      context.lineTo offset + radius, h - offset
      context.lineTo radius / 2 + inset, h - inset
    else # pointing left
      context.lineTo w - (radius / 2 + inset), h - inset
      context.lineTo w - (offset + radius), h - offset
  
  # bottom left:
  context.arc offset, h - offset - radius, radius, radians(90), radians(180), false
  if @isThought
    
    # close large bubble:
    context.lineTo inset, offset
    
    # draw thought bubbles:
    if @isPointingRight
      
      # tip bubble:
      rad = radius / 4
      circle rad + inset, h - rad - inset, rad
      
      # middle bubble:
      rad = radius / 3.2
      circle rad * 2 + inset, h - rad - inset * 2, rad
      
      # top bubble:
      rad = radius / 2.8
      circle rad * 3 + inset * 2, h - rad - inset * 4, rad
    else # pointing left
      # tip bubble:
      rad = radius / 4
      circle w - (rad + inset), h - rad - inset, rad
      
      # middle bubble:
      rad = radius / 3.2
      circle w - (rad * 2 + inset), h - rad - inset * 2, rad
      
      # top bubble:
      rad = radius / 2.8
      circle w - (rad * 3 + inset * 2), h - rad - inset * 4, rad
# WorldMorph //////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class WorldMorph extends FrameMorph
  constructor: (aCanvas, fillPage) ->
    @init aCanvas, fillPage

# I represent the <canvas> element

# WorldMorph instance creation:

# WorldMorph initialization:
WorldMorph::init = (aCanvas, fillPage) ->
  super()
  @color = new Color(205, 205, 205) # (130, 130, 130)
  @alpha = 1
  @bounds = new Rectangle(0, 0, aCanvas.width, aCanvas.height)
  @drawNew()
  @isVisible = true
  @isDraggable = false
  @currentKey = null # currently pressed key code
  @worldCanvas = aCanvas
  
  # additional properties:
  @useFillPage = fillPage
  @useFillPage = true  if @useFillPage is `undefined`
  @isDevMode = false
  @broken = []
  @hand = new HandMorph(this)
  @keyboardReceiver = null
  @lastEditedText = null
  @cursor = null
  @activeMenu = null
  @activeHandle = null
  @virtualKeyboard = null
  @initEventListeners()

# World Morph display:
WorldMorph::brokenFor = (aMorph) ->
  
  # private
  fb = aMorph.fullBounds()
  @broken.filter (rect) ->
    rect.intersects fb


WorldMorph::fullDrawOn = (aCanvas, aRect) ->
  super aCanvas, aRect
  @hand.fullDrawOn aCanvas, aRect

WorldMorph::updateBroken = ->
  myself = this
  @broken.forEach (rect) ->
    myself.fullDrawOn myself.worldCanvas, rect  if rect.extent().gt(new Point(0, 0))
  
  @broken = []

WorldMorph::doOneCycle = ->
  @stepFrame()
  @updateBroken()

WorldMorph::fillPage = ->
  pos = getDocumentPositionOf(@worldCanvas)
  clientHeight = window.innerHeight
  clientWidth = window.innerWidth
  myself = this
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
  @children.forEach (child) ->
    child.reactToWorldResize myself.bounds.copy()  if child.reactToWorldResize



# WorldMorph global pixel access:
WorldMorph::getGlobalPixelColor = (point) ->
  
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
WorldMorph::initVirtualKeyboard = ->
  myself = this
  if @virtualKeyboard
    document.body.removeChild @virtualKeyboard
    @virtualKeyboard = null
  return  unless MorphicPreferences.useVirtualKeyboard
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
  @virtualKeyboard.addEventListener "keydown", ((event) ->
    
    # remember the keyCode in the world's currentKey property
    myself.currentKey = event.keyCode
    myself.keyboardReceiver.processKeyDown event  if myself.keyboardReceiver
    
    # supress backspace override
    event.preventDefault()  if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
    
    # supress tab override and make sure tab gets
    # received by all browsers
    if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
      myself.keyboardReceiver.processKeyPress event  if myself.keyboardReceiver
      event.preventDefault()
  ), false
  @virtualKeyboard.addEventListener "keyup", ((event) ->
    
    # flush the world's currentKey property
    myself.currentKey = null
    
    # dispatch to keyboard receiver
    myself.keyboardReceiver.processKeyUp event  if myself.keyboardReceiver.processKeyUp  if myself.keyboardReceiver
    event.preventDefault()
  ), false
  @virtualKeyboard.addEventListener "keypress", ((event) ->
    myself.keyboardReceiver.processKeyPress event  if myself.keyboardReceiver
    event.preventDefault()
  ), false

WorldMorph::initEventListeners = ->
  canvas = @worldCanvas
  myself = this
  if myself.useFillPage
    myself.fillPage()
  else
    @changed()
  canvas.addEventListener "mousedown", ((event) ->
    myself.hand.processMouseDown event
  ), false
  canvas.addEventListener "touchstart", ((event) ->
    myself.hand.processTouchStart event
  ), false
  canvas.addEventListener "mouseup", ((event) ->
    event.preventDefault()
    myself.hand.processMouseUp event
  ), false
  canvas.addEventListener "touchend", ((event) ->
    myself.hand.processTouchEnd event
  ), false
  canvas.addEventListener "mousemove", ((event) ->
    myself.hand.processMouseMove event
  ), false
  canvas.addEventListener "touchmove", ((event) ->
    myself.hand.processTouchMove event
  ), false
  canvas.addEventListener "contextmenu", ((event) ->
    
    # suppress context menu for Mac-Firefox
    event.preventDefault()
  ), false
  canvas.addEventListener "keydown", ((event) ->
    
    # remember the keyCode in the world's currentKey property
    myself.currentKey = event.keyCode
    myself.keyboardReceiver.processKeyDown event  if myself.keyboardReceiver
    
    # supress backspace override
    event.preventDefault()  if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
    
    # supress tab override and make sure tab gets
    # received by all browsers
    if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
      myself.keyboardReceiver.processKeyPress event  if myself.keyboardReceiver
      event.preventDefault()
  ), false
  canvas.addEventListener "keyup", ((event) ->
    
    # flush the world's currentKey property
    myself.currentKey = null
    
    # dispatch to keyboard receiver
    myself.keyboardReceiver.processKeyUp event  if myself.keyboardReceiver.processKeyUp  if myself.keyboardReceiver
    event.preventDefault()
  ), false
  canvas.addEventListener "keypress", ((event) ->
    myself.keyboardReceiver.processKeyPress event  if myself.keyboardReceiver
    event.preventDefault()
  ), false
  # Safari, Chrome
  canvas.addEventListener "mousewheel", ((event) ->
    myself.hand.processMouseScroll event
    event.preventDefault()
  ), false
  # Firefox
  canvas.addEventListener "DOMMouseScroll", ((event) ->
    myself.hand.processMouseScroll event
    event.preventDefault()
  ), false
  window.addEventListener "dragover", ((event) ->
    event.preventDefault()
  ), false
  window.addEventListener "drop", ((event) ->
    myself.hand.processDrop event
    event.preventDefault()
  ), false
  window.addEventListener "resize", (->
    myself.fillPage()  if myself.useFillPage
  ), false
  window.onbeforeunload = (evt) ->
    e = evt or window.event
    msg = "Are you sure you want to leave?"
    
    # For IE and Firefox
    e.returnValue = msg  if e
    
    # For Safari / chrome
    msg

WorldMorph::mouseDownLeft = noOpFunction

WorldMorph::mouseClickLeft = noOpFunction

WorldMorph::mouseDownRight = noOpFunction

WorldMorph::mouseClickRight = noOpFunction

WorldMorph::wantsDropOf = ->
  
  # allow handle drops if any drops are allowed
  @acceptsDrops

WorldMorph::droppedImage = ->
  null


# WorldMorph text field tabbing:
WorldMorph::nextTab = (editField) ->
  next = @nextEntryField(editField)
  editField.clearSelection()
  next.selectAll()
  next.edit()

WorldMorph::previousTab = (editField) ->
  prev = @previousEntryField(editField)
  editField.clearSelection()
  prev.selectAll()
  prev.edit()


# WorldMorph menu:
WorldMorph::contextMenu = ->
  menu = undefined
  if @isDevMode
    menu = new MenuMorph(this, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
  else
    menu = new MenuMorph(this, "Morphic")
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
      @pickColor menu.title + "\ncolor:", @setColor, this, @color
    ), "choose the World's\nbackground color"
    if MorphicPreferences is standardSettings
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

WorldMorph::userCreateMorph = ->
  create = (aMorph) ->
    aMorph.isDraggable = true
    aMorph.pickUp myself
  myself = this
  menu = undefined
  newMorph = undefined
  menu = new MenuMorph(this, "make a morph")
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
    newMorph = new TextMorph("Ich weiß nicht, was soll es bedeuten, dass ich so " + "traurig bin, ein Märchen aus uralten Zeiten, das " + "kommt mir nicht aus dem Sinn. Die Luft ist kühl " + "und es dunkelt, und ruhig fließt der Rhein; der " + "Gipfel des Berges funkelt im Abendsonnenschein. " + "Die schönste Jungfrau sitzet dort oben wunderbar, " + "ihr gold'nes Geschmeide blitzet, sie kämmt ihr " + "goldenes Haar, sie kämmt es mit goldenem Kamme, " + "und singt ein Lied dabei; das hat eine wundersame, " + "gewalt'ge Melodei. Den Schiffer im kleinen " + "Schiffe, ergreift es mit wildem Weh; er schaut " + "nicht die Felsenriffe, er schaut nur hinauf in " + "die Höh'. Ich glaube, die Wellen verschlingen " + "am Ende Schiffer und Kahn, und das hat mit ihrem " + "Singen, die Loreley getan.")
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
    foo = undefined
    bar = undefined
    baz = undefined
    garply = undefined
    fred = undefined
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
  
  if myself.customMorphs
    menu.addLine()
    myself.customMorphs().forEach (morph) ->
      menu.addItem morph.toString(), ->
        create morph
  
  
  menu.popUpAtHand this

WorldMorph::toggleDevMode = ->
  @isDevMode = not @isDevMode

WorldMorph::hideAll = ->
  @children.forEach (child) ->
    child.hide()


WorldMorph::showAllHiddens = ->
  @forAllChildren (child) ->
    child.show()  unless child.isVisible


WorldMorph::about = ->
  versions = ""
  module = undefined
  for module of modules
    versions += ("\n" + module + " (" + modules[module] + ")")  if modules.hasOwnProperty(module)
  versions = "\n\nmodules:\n\n" + "morphic (" + morphicVersion + ")" + versions  if versions isnt ""
  @inform "morphic.js\n\n" + "a lively Web GUI\ninspired by Squeak\n" + morphicVersion + "\n\nwritten by Jens Mönig\njens@moenig.org" + versions

WorldMorph::edit = (aStringOrTextMorph) ->
  pos = getDocumentPositionOf(@worldCanvas)
  return null  unless aStringOrTextMorph.isEditable
  @cursor.destroy()  if @cursor
  @lastEditedText.clearSelection()  if @lastEditedText
  @cursor = new CursorMorph(aStringOrTextMorph)
  aStringOrTextMorph.parent.add @cursor
  @keyboardReceiver = @cursor
  @initVirtualKeyboard()
  if MorphicPreferences.useVirtualKeyboard
    @virtualKeyboard.style.top = @cursor.top() + pos.y + "px"
    @virtualKeyboard.style.left = @cursor.left() + pos.x + "px"
    @virtualKeyboard.focus()
  if MorphicPreferences.useSliderForInput
    if !aStringOrTextMorph.parentThatIsA(MenuMorph)
      @slide aStringOrTextMorph

WorldMorph::slide = (aStringOrTextMorph) ->
  
  # display a slider for numeric text entries
  val = parseFloat(aStringOrTextMorph.text)
  menu = undefined
  slider = undefined
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
  slider.silentSetHeight MorphicPreferences.scrollBarSize
  slider.silentSetWidth MorphicPreferences.menuFontSize * 10
  slider.drawNew()
  slider.action = (num) ->
    aStringOrTextMorph.changed()
    aStringOrTextMorph.text = Math.round(num).toString()
    aStringOrTextMorph.drawNew()
    aStringOrTextMorph.changed()
  
  menu.items.push slider
  menu.popup this, aStringOrTextMorph.bottomLeft().add(new Point(0, 5))

WorldMorph::stopEditing = ->
  if @cursor
    @lastEditedText = @cursor.target
    @cursor.destroy()
    @lastEditedText.escalateEvent "reactToEdit", @lastEditedText
  @keyboardReceiver = null
  if @virtualKeyboard
    @virtualKeyboard.blur()
    document.body.removeChild @virtualKeyboard
    @virtualKeyboard = null
  @worldCanvas.focus()

WorldMorph::toggleBlurredShadows = ->
  useBlurredShadows = not useBlurredShadows

WorldMorph::togglePreferences = ->
  if MorphicPreferences is standardSettings
    MorphicPreferences = touchScreenSettings
  else
    MorphicPreferences = standardSettings
# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text cursors

class BlinkerMorph extends Morph
  constructor: (rate) ->
    @init rate

# BlinkerMorph instance creation:
BlinkerMorph::init = (rate) ->
  super()
  @color = new Color(0, 0, 0)
  @fps = rate or 2
  @drawNew()


# BlinkerMorph stepping:
BlinkerMorph::step = ->
  @toggleVisibility()
# CursorMorph /////////////////////////////////////////////////////////

# I am a String/Text editing widget

class CursorMorph extends BlinkerMorph
  constructor: (aStringOrTextMorph) ->
    @init aStringOrTextMorph

# CursorMorph: referenced constructors

# CursorMorph instance creation:
CursorMorph::init = (aStringOrTextMorph) ->
  ls = undefined
  
  # additional properties:
  @keyDownEventUsed = false
  @target = aStringOrTextMorph
  @originalContents = @target.text
  @slot = @target.text.length
  super()
  ls = fontHeight(@target.fontSize)
  @setExtent new Point(Math.max(Math.floor(ls / 20), 1), ls)
  @drawNew()
  @image.getContext("2d").font = @target.font()
  @gotoSlot @slot


# CursorMorph event processing:
CursorMorph::processKeyPress = (event) ->
  
  # this.inspectKeyEvent(event);
  if @keyDownEventUsed
    @keyDownEventUsed = false
    return null
  if (event.keyCode is 40) or event.charCode is 40
    @insert "("
    return null
  if (event.keyCode is 37) or event.charCode is 37
    @insert "%"
    return null
  navigation = [8, 13, 18, 27, 35, 36, 37, 38, 40]
  if event.keyCode # Opera doesn't support charCode
    unless contains(navigation, event.keyCode)
      if event.ctrlKey
        @ctrl event.keyCode
      else
        @insert String.fromCharCode(event.keyCode)
  else if event.charCode # all other browsers
    unless contains(navigation, event.charCode)
      if event.ctrlKey
        @ctrl event.charCode
      else
        @insert String.fromCharCode(event.charCode)
  
  # notify target's parent of key event
  @target.escalateEvent "reactToKeystroke", event

CursorMorph::processKeyDown = (event) ->
  
  # this.inspectKeyEvent(event);
  @keyDownEventUsed = false
  if event.ctrlKey
    @ctrl event.keyCode
    
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", event
    return
  switch event.keyCode
    when 37
      @goLeft()
      @keyDownEventUsed = true
    when 39
      @goRight()
      @keyDownEventUsed = true
    when 38
      @goUp()
      @keyDownEventUsed = true
    when 40
      @goDown()
      @keyDownEventUsed = true
    when 36
      @goHome()
      @keyDownEventUsed = true
    when 35
      @goEnd()
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


# CursorMorph navigation:
CursorMorph::gotoSlot = (newSlot) ->
  @setPosition @target.slotPosition(newSlot)
  @slot = Math.max(newSlot, 0)

CursorMorph::goLeft = ->
  @target.clearSelection()
  @gotoSlot @slot - 1

CursorMorph::goRight = ->
  @target.clearSelection()
  @gotoSlot @slot + 1

CursorMorph::goUp = ->
  @target.clearSelection()
  @gotoSlot @target.upFrom(@slot)

CursorMorph::goDown = ->
  @target.clearSelection()
  @gotoSlot @target.downFrom(@slot)

CursorMorph::goHome = ->
  @target.clearSelection()
  @gotoSlot @target.startOfLine(@slot)

CursorMorph::goEnd = ->
  @target.clearSelection()
  @gotoSlot @target.endOfLine(@slot)

CursorMorph::gotoPos = (aPoint) ->
  @gotoSlot @target.slotAt(aPoint)
  @show()


# CursorMorph editing:
CursorMorph::accept = ->
  world = @root()
  world.stopEditing()  if world
  @escalateEvent "accept", null

CursorMorph::cancel = ->
  world = @root()
  world.stopEditing()  if world
  @target.text = @originalContents
  @target.changed()
  @target.drawNew()
  @target.changed()
  @escalateEvent "cancel", null

CursorMorph::insert = (aChar) ->
  text = undefined
  return @target.tab(@target)  if aChar is "\t"
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

CursorMorph::ctrl = (aChar) ->
  if (aChar is 97) or (aChar is 65)
    @target.selectAll()
    return null
  if aChar is 123
    @insert "{"
    return null
  if aChar is 125
    @insert "}"
    return null
  if aChar is 91
    @insert "["
    return null
  if aChar is 93
    @insert "]"
    null

CursorMorph::deleteRight = ->
  text = undefined
  if @target.selection() isnt ""
    @gotoSlot @target.selectionStartSlot()
    @target.deleteSelection()
  else
    text = @target.text
    @target.changed()
    text = text.slice(0, @slot) + text.slice(@slot + 1)
    @target.text = text
    @target.drawNew()

CursorMorph::deleteLeft = ->
  text = undefined
  if @target.selection() isnt ""
    @gotoSlot @target.selectionStartSlot()
    @target.deleteSelection()
  text = @target.text
  @target.changed()
  text = text.slice(0, Math.max(@slot - 1, 0)) + text.slice(@slot)
  @target.text = text
  @target.drawNew()
  @goLeft()


# CursorMorph utilities:
CursorMorph::inspectKeyEvent = (event) ->
  
  # private
  @inform "Key pressed: " + String.fromCharCode(event.charCode) + "\n------------------------" + "\ncharCode: " + event.charCode.toString() + "\nkeyCode: " + event.keyCode.toString() + "\naltKey: " + event.altKey.toString() + "\nctrlKey: " + event.ctrlKey.toString()
# InspectorMorph //////////////////////////////////////////////////////

class InspectorMorph extends BoxMorph
  constructor: (target) ->
    @init target

# InspectorMorph instance creation:
InspectorMorph::init = (target) ->
  
  # additional properties:
  @target = target
  @currentProperty = null
  @showing = "attributes"
  @markOwnProperties = false
  
  # initialize inherited properties:
  super()
  
  # override inherited properties:
  @silentSetExtent new Point(MorphicPreferences.handleSize * 20, MorphicPreferences.handleSize * 20 * 2 / 3)
  @isDraggable = true
  @border = 1
  @edge = 5
  @color = new Color(60, 60, 60)
  @borderColor = new Color(95, 95, 95)
  @drawNew()
  
  # panes:
  @label = null
  @list = null
  @detail = null
  @work = null
  @buttonInspect = null
  @buttonClose = null
  @buttonSubset = null
  @buttonEdit = null
  @resizer = null
  @buildPanes()  if @target

InspectorMorph::setTarget = (target) ->
  @target = target
  @currentProperty = null
  @buildPanes()

InspectorMorph::buildPanes = ->
  attribs = []
  property = undefined
  myself = this
  ctrl = undefined
  ev = undefined
  
  # remove existing panes
  @children.forEach (m) ->
    # keep work pane around
    m.destroy()  if m isnt @work
  
  @children = []
  
  # label
  @label = new TextMorph(@target.toString())
  @label.fontSize = MorphicPreferences.menuFontSize
  @label.isBold = true
  @label.color = new Color(255, 255, 255)
  @label.drawNew()
  @add @label
  
  # properties list
  for property of @target
    # dummy condition, to be refined
    attribs.push property  if property
  if @showing is "attributes"
    attribs = attribs.filter((prop) ->
      typeof myself.target[prop] isnt "function"
    )
  else if @showing is "methods"
    attribs = attribs.filter((prop) ->
      typeof myself.target[prop] is "function"
    )
  # otherwise show all properties
  # label getter
  # format list
  # format element: [color, predicate(element]
  @list = new ListMorph((if @target instanceof Array then attribs else attribs.sort()), null, (if @markOwnProperties then [[new Color(0, 0, 180), (element) ->
    myself.target.hasOwnProperty element
  ]] else null))
  @list.action = (selected) ->
    val = undefined
    txt = undefined
    cnts = undefined
    val = myself.target[selected]
    myself.currentProperty = val
    if val is null
      txt = "NULL"
    else if isString(val)
      txt = val
    else
      txt = val.toString()
    cnts = new TextMorph(txt)
    cnts.isEditable = true
    cnts.enableSelecting()
    cnts.setReceiver myself.target
    myself.detail.setContents cnts
  
  @list.hBar.alpha = 0.6
  @list.vBar.alpha = 0.6
  @add @list
  
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
  
  # properties button
  @buttonSubset = new TriggerMorph()
  @buttonSubset.labelString = "show..."
  @buttonSubset.action = ->
    menu = undefined
    menu = new MenuMorph()
    menu.addItem "attributes", ->
      myself.showing = "attributes"
      myself.buildPanes()
    
    menu.addItem "methods", ->
      myself.showing = "methods"
      myself.buildPanes()
    
    menu.addItem "all", ->
      myself.showing = "all"
      myself.buildPanes()
    
    menu.addLine()
    menu.addItem ((if myself.markOwnProperties then "un-mark own" else "mark own")), (->
      myself.markOwnProperties = not myself.markOwnProperties
      myself.buildPanes()
    ), "highlight\n'own' properties"
    menu.popUpAtHand myself.world()
  
  @add @buttonSubset
  
  # inspect button
  @buttonInspect = new TriggerMorph()
  @buttonInspect.labelString = "inspect..."
  @buttonInspect.action = ->
    menu = undefined
    world = undefined
    inspector = undefined
    if isObject(myself.currentProperty)
      menu = new MenuMorph()
      menu.addItem "in new inspector...", ->
        world = myself.world()
        inspector = new InspectorMorph(myself.currentProperty)
        inspector.setPosition world.hand.position()
        inspector.keepWithin world
        world.add inspector
        inspector.changed()
      
      menu.addItem "here...", ->
        myself.setTarget myself.currentProperty
      
      menu.popUpAtHand myself.world()
    else
      myself.inform ((if myself.currentProperty is null then "null" else typeof myself.currentProperty)) + "\nis not inspectable"
  
  @add @buttonInspect
  
  # edit button
  @buttonEdit = new TriggerMorph()
  @buttonEdit.labelString = "edit..."
  @buttonEdit.action = ->
    menu = undefined
    menu = new MenuMorph(myself)
    menu.addItem "save", "save", "accept changes"
    menu.addLine()
    menu.addItem "add property...", "addProperty"
    menu.addItem "rename...", "renameProperty"
    menu.addItem "remove...", "removeProperty"
    menu.popUpAtHand myself.world()
  
  @add @buttonEdit
  
  # close button
  @buttonClose = new TriggerMorph()
  @buttonClose.labelString = "close"
  @buttonClose.action = ->
    myself.destroy()
  
  @add @buttonClose
  
  # resizer
  @resizer = new HandleMorph(this, 150, 100, @edge, @edge)
  
  # update layout
  @fixLayout()

InspectorMorph::fixLayout = ->
  x = undefined
  y = undefined
  r = undefined
  b = undefined
  w = undefined
  h = undefined
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
    @drawNew()
    @changed()
    @resizer.drawNew()
  
  # list
  y = @label.bottom() + 2
  w = Math.min(Math.floor(@width() / 3), @list.listContents.width())
  w -= @edge
  b = @bottom() - (2 * @edge) - MorphicPreferences.handleSize
  h = b - y
  @list.setPosition new Point(x, y)
  @list.setExtent new Point(w, h)
  
  # detail
  x = @list.right() + @edge
  r = @right() - @edge
  w = r - x
  @detail.setPosition new Point(x, y)
  @detail.setExtent new Point(w, (h * 2 / 3) - @edge)
  
  # work
  y = @detail.bottom() + @edge
  @work.setPosition new Point(x, y)
  @work.setExtent new Point(w, h / 3)
  
  # properties button
  x = @list.left()
  y = @list.bottom() + @edge
  w = @list.width()
  h = MorphicPreferences.handleSize
  @buttonSubset.setPosition new Point(x, y)
  @buttonSubset.setExtent new Point(w, h)
  
  # inspect button
  x = @detail.left()
  w = @detail.width() - @edge - MorphicPreferences.handleSize
  w = w / 3 - @edge / 3
  @buttonInspect.setPosition new Point(x, y)
  @buttonInspect.setExtent new Point(w, h)
  
  # edit button
  x = @buttonInspect.right() + @edge
  @buttonEdit.setPosition new Point(x, y)
  @buttonEdit.setExtent new Point(w, h)
  
  # close button
  x = @buttonEdit.right() + @edge
  r = @detail.right() - @edge - MorphicPreferences.handleSize
  w = r - x
  @buttonClose.setPosition new Point(x, y)
  @buttonClose.setExtent new Point(w, h)
  Morph::trackChanges = true
  @changed()

InspectorMorph::setExtent = (aPoint) ->
  super aPoint
  @fixLayout()


#InspectorMorph editing ops:
InspectorMorph::save = ->
  txt = @detail.contents.children[0].text.toString()
  prop = @list.selected
  try
    
    # this.target[prop] = evaluate(txt);
    @target.evaluateString "this." + prop + " = " + txt
    if @target.drawNew
      @target.changed()
      @target.drawNew()
      @target.changed()
  catch err
    @inform err

InspectorMorph::addProperty = ->
  myself = this
  @prompt "new property name:", ((prop) ->
    if prop
      myself.target[prop] = null
      myself.buildPanes()
      if myself.target.drawNew
        myself.target.changed()
        myself.target.drawNew()
        myself.target.changed()
  ), this, "property" # Chrome cannot handle empty strings (others do)

InspectorMorph::renameProperty = ->
  myself = this
  propertyName = @list.selected
  @prompt "property name:", ((prop) ->
    try
      delete (myself.target[propertyName])
      
      myself.target[prop] = myself.currentProperty
    catch err
      myself.inform err
    myself.buildPanes()
    if myself.target.drawNew
      myself.target.changed()
      myself.target.drawNew()
      myself.target.changed()
  ), this, propertyName

InspectorMorph::removeProperty = ->
  prop = @list.selected
  try
    delete (@target[prop])
    
    @currentProperty = null
    @buildPanes()
    if @target.drawNew
      @target.changed()
      @target.drawNew()
      @target.changed()
  catch err
    @inform err
# ColorPickerMorph ///////////////////////////////////////////////////

class ColorPickerMorph extends Morph
  constructor: (defaultColor) ->
    @init defaultColor or new Color(255, 255, 255)

# ColorPickerMorph instance creation:
ColorPickerMorph::init = (defaultColor) ->
  @choice = defaultColor
  super
  @color = new Color(255, 255, 255)
  @silentSetExtent new Point(80, 80)
  @drawNew()

ColorPickerMorph::drawNew = ->
  super
  @buildSubmorphs()

ColorPickerMorph::buildSubmorphs = ->
  cpal = undefined
  gpal = undefined
  x = undefined
  y = undefined
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

ColorPickerMorph::getChoice = ->
  @feedback.color

ColorPickerMorph::rootForGrab = ->
  this
# ShadowMorph /////////////////////////////////////////////////////////

class ShadowMorph extends Morph
  constructor: () ->
    @init()
# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders

class CircleBoxMorph extends Morph
  constructor: (orientation) ->
    @init orientation or "vertical"

CircleBoxMorph::init = (orientation) ->
  super()
  @orientation = orientation
  @autoOrient = true
  @setExtent new Point(20, 100)

CircleBoxMorph::autoOrientation = ->
  if @height() > @width()
    @orientation = "vertical"
  else
    @orientation = "horizontal"

CircleBoxMorph::drawNew = ->
  radius = undefined
  center1 = undefined
  center2 = undefined
  rect = undefined
  points = undefined
  x = undefined
  y = undefined
  context = undefined
  ext = undefined
  myself = this
  @autoOrientation()  if @autoOrient
  @image = newCanvas(@extent())
  context = @image.getContext("2d")
  if @orientation is "vertical"
    radius = @width() / 2
    x = @center().x
    center1 = new Point(x, @top() + radius)
    center2 = new Point(x, @bottom() - radius)
    rect = @bounds.origin.add(new Point(0, radius)).corner(@bounds.corner.subtract(new Point(0, radius)))
  else
    radius = @height() / 2
    y = @center().y
    center1 = new Point(@left() + radius, y)
    center2 = new Point(@right() - radius, y)
    rect = @bounds.origin.add(new Point(radius, 0)).corner(@bounds.corner.subtract(new Point(radius, 0)))
  points = [center1.subtract(@bounds.origin), center2.subtract(@bounds.origin)]
  points.forEach (center) ->
    context.fillStyle = myself.color.toString()
    context.beginPath()
    context.arc center.x, center.y, radius, 0, 2 * Math.PI, false
    context.closePath()
    context.fill()
  
  rect = rect.translateBy(@bounds.origin.neg())
  ext = rect.extent()
  context.fillRect rect.origin.x, rect.origin.y, rect.width(), rect.height()  if ext.x > 0 and ext.y > 0


# CircleBoxMorph menu:
CircleBoxMorph::developersMenu = ->
  menu = super()
  menu.addLine()
  if @orientation is "vertical"
    menu.addItem "horizontal...", "toggleOrientation", "toggle the\norientation"
  else
    menu.addItem "vertical...", "toggleOrientation", "toggle the\norientation"
  menu

CircleBoxMorph::toggleOrientation = ->
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
  constructor: (start, stop, value, size, orientation, color) ->
    @init start or 1, stop or 100, value or 50, size or 10, orientation or "vertical", color

SliderMorph::init = (start, stop, value, size, orientation, color) ->
  @target = null
  @action = null
  @start = start
  @stop = stop
  @value = value
  @size = size
  @offset = null
  @button = new SliderButtonMorph()
  @button.isDraggable = false
  @button.color = new Color(200, 200, 200)
  @button.highlightColor = new Color(210, 210, 255)
  @button.pressColor = new Color(180, 180, 255)
  super orientation
  @add @button
  @alpha = 0.3
  @color = color or new Color(0, 0, 0)
  @setExtent new Point(20, 100)


# this.drawNew();
SliderMorph::autoOrientation = noOpFunction

SliderMorph::rangeSize = ->
  @stop - @start

SliderMorph::ratio = ->
  @size / @rangeSize()

SliderMorph::unitSize = ->
  return (@height() - @button.height()) / @rangeSize()  if @orientation is "vertical"
  (@width() - @button.width()) / @rangeSize()

SliderMorph::drawNew = ->
  bw = undefined
  bh = undefined
  posX = undefined
  posY = undefined
  super()
  @button.orientation = @orientation
  if @orientation is "vertical"
    bw = @width() - 2
    bh = Math.max(bw, Math.round(@height() * @ratio()))
    @button.silentSetExtent new Point(bw, bh)
    posX = 1
    posY = Math.min(Math.round((@value - @start) * @unitSize()), @height() - @button.height())
  else
    bh = @height() - 2
    bw = Math.max(bh, Math.round(@width() * @ratio()))
    @button.silentSetExtent new Point(bw, bh)
    posY = 1
    posX = Math.min(Math.round((@value - @start) * @unitSize()), @width() - @button.width())
  @button.setPosition new Point(posX, posY).add(@bounds.origin)
  @button.drawNew()
  @button.changed()

SliderMorph::updateValue = ->
  relPos = undefined
  if @orientation is "vertical"
    relPos = @button.top() - @top()
  else
    relPos = @button.left() - @left()
  @value = Math.round(relPos / @unitSize() + @start)
  @updateTarget()

SliderMorph::updateTarget = ->
  if @action
    if typeof @action is "function"
      @action.call @target, @value
    else # assume it's a String
      @target[@action] @value


# SliderMorph duplicating:
SliderMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.target = (dict[@target])  if c.target and dict[@target]
  c.button = (dict[@button])  if c.button and dict[@button]
  c


# SliderMorph menu:
SliderMorph::developersMenu = ->
  menu = super()
  menu.addItem "show value...", "showValue", "display a dialog box\nshowing the selected number"
  menu.addItem "floor...", (->
    @prompt menu.title + "\nfloor:", @setStart, this, @start.toString(), null, 0, @stop - @size, true
  ), "set the minimum value\nwhich can be selected"
  menu.addItem "ceiling...", (->
    @prompt menu.title + "\nceiling:", @setStop, this, @stop.toString(), null, @start + @size, @size * 100, true
  ), "set the maximum value\nwhich can be selected"
  menu.addItem "button size...", (->
    @prompt menu.title + "\nbutton size:", @setSize, this, @size.toString(), null, 1, @stop - @start, true
  ), "set the range\ncovered by\nthe slider button"
  menu.addLine()
  menu.addItem "set target", "setTarget", "select another morph\nwhose numerical property\nwill be " + "controlled by this one"
  menu

SliderMorph::showValue = ->
  @inform @value

SliderMorph::userSetStart = (num) ->
  
  # for context menu demo purposes
  @start = Math.max(num, @stop)

SliderMorph::setStart = (num) ->
  
  # for context menu demo purposes
  newStart = undefined
  if typeof num is "number"
    @start = Math.min(Math.max(num, 0), @stop - @size)
  else
    newStart = parseFloat(num)
    @start = Math.min(Math.max(newStart, 0), @stop - @size)  unless isNaN(newStart)
  @value = Math.max(@value, @start)
  @updateTarget()
  @drawNew()
  @changed()

SliderMorph::setStop = (num) ->
  
  # for context menu demo purposes
  newStop = undefined
  if typeof num is "number"
    @stop = Math.max(num, @start + @size)
  else
    newStop = parseFloat(num)
    @stop = Math.max(newStop, @start + @size)  unless isNaN(newStop)
  @value = Math.min(@value, @stop)
  @updateTarget()
  @drawNew()
  @changed()

SliderMorph::setSize = (num) ->
  
  # for context menu demo purposes
  newSize = undefined
  if typeof num is "number"
    @size = Math.min(Math.max(num, 1), @stop - @start)
  else
    newSize = parseFloat(num)
    @size = Math.min(Math.max(newSize, 1), @stop - @start)  unless isNaN(newSize)
  @value = Math.min(@value, @stop - @size)
  @updateTarget()
  @drawNew()
  @changed()

SliderMorph::setTarget = ->
  choices = @overlappedMorphs()
  menu = new MenuMorph(this, "choose target:")
  myself = this
  choices.push @world()
  choices.forEach (each) ->
    menu.addItem each.toString().slice(0, 50), ->
      myself.target = each
      myself.setTargetSetter()
  
  
  if choices.length is 1
    @target = choices[0]
    @setTargetSetter()
  else menu.popUpAtHand @world()  if choices.length > 0

SliderMorph::setTargetSetter = ->
  choices = @target.numericalSetters()
  menu = new MenuMorph(this, "choose target property:")
  myself = this
  choices.forEach (each) ->
    menu.addItem each, ->
      myself.action = each
  
  
  if choices.length is 1
    @action = choices[0]
  else menu.popUpAtHand @world()  if choices.length > 0

SliderMorph::numericalSetters = ->
  # for context menu demo purposes
  list = super()
  list.push "setStart", "setStop", "setSize"
  list


# SliderMorph stepping:
SliderMorph::step = null
SliderMorph::mouseDownLeft = (pos) ->
  world = undefined
  myself = this
  unless @button.bounds.containsPoint(pos)
    @offset = new Point() # return null;
  else
    @offset = pos.subtract(@button.bounds.origin)
  world = @root()
  @step = ->
    mousePos = undefined
    newX = undefined
    newY = undefined
    if world.hand.mouseButton
      mousePos = world.hand.bounds.origin
      if myself.orientation is "vertical"
        newX = myself.button.bounds.origin.x
        newY = Math.max(Math.min(mousePos.y - myself.offset.y, myself.bottom() - myself.button.height()), myself.top())
      else
        newY = myself.button.bounds.origin.y
        newX = Math.max(Math.min(mousePos.x - myself.offset.x, myself.right() - myself.button.width()), myself.left())
      myself.button.setPosition new Point(newX, newY)
      myself.updateValue()
    else
      @step = null
# Colors //////////////////////////////////////////////////////////////

# Color instance creation:
Color = (r, g, b, a) ->
  
  # all values are optional, just (r, g, b) is fine
  @r = r or 0
  @g = g or 0
  @b = b or 0
  @a = a or ((if (a is 0) then 0 else 1))

# Color string representation: e.g. 'rgba(255,165,0,1)'
Color::toString = ->
  "rgba(" + Math.round(@r) + "," + Math.round(@g) + "," + Math.round(@b) + "," + @a + ")"


# Color copying:
Color::copy = ->
  new Color(@r, @g, @b, @a)


# Color comparison:
Color::eq = (aColor) ->
  
  # ==
  aColor and @r is aColor.r and @g is aColor.g and @b is aColor.b


# Color conversion (hsv):
Color::hsv = ->
  
  # ignore alpha
  max = undefined
  min = undefined
  h = undefined
  s = undefined
  v = undefined
  d = undefined
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

Color::set_hsv = (h, s, v) ->
  
  # ignore alpha, h, s and v are to be within [0, 1]
  i = undefined
  f = undefined
  p = undefined
  q = undefined
  t = undefined
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
Color::mixed = (proportion, otherColor) ->
  
  # answer a copy of this color mixed with another color, ignore alpha
  frac1 = Math.min(Math.max(proportion, 0), 1)
  frac2 = 1 - frac1
  new Color(@r * frac1 + otherColor.r * frac2, @g * frac1 + otherColor.g * frac2, @b * frac1 + otherColor.b * frac2)

Color::darker = (percent) ->
  
  # return an rgb-interpolated darker copy of me, ignore alpha
  fract = 0.8333
  fract = (100 - percent) / 100  if percent
  @mixed fract, new Color(0, 0, 0)

Color::lighter = (percent) ->
  
  # return an rgb-interpolated lighter copy of me, ignore alpha
  fract = 0.8333
  fract = (100 - percent) / 100  if percent
  @mixed fract, new Color(255, 255, 255)

Color::dansDarker = ->
  
  # return an hsv-interpolated darker copy of me, ignore alpha
  hsv = @hsv()
  result = new Color()
  vv = Math.max(hsv[2] - 0.16, 0)
  result.set_hsv hsv[0], hsv[1], vv
  result
# ListMorph ///////////////////////////////////////////////////////////

class ListMorph extends ScrollFrameMorph
  constructor: (elements, labelGetter, format) ->
  
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
    @init elements or [], labelGetter or (element) ->
      return element  if isString(element)
      return element.toSource()  if element.toSource
      element.toString()
    , format or []

ListMorph::init = (elements, labelGetter, format) ->
  super()
  @contents.acceptsDrops = false
  @color = new Color(255, 255, 255)
  @hBar.alpha = 0.6
  @vBar.alpha = 0.6
  @elements = elements or []
  @labelGetter = labelGetter
  @format = format
  @listContents = null
  @selected = null
  @action = null
  @acceptsDrops = false
  @buildListContents()

ListMorph::buildListContents = ->
  myself = this
  @listContents.destroy()  if @listContents
  @listContents = new MenuMorph(@select, null, this)
  @elements = ["(empty)"]  if @elements.length is 0
  @elements.forEach (element) ->
    color = null
    myself.format.forEach (pair) ->
      color = pair[0]  if pair[1].call(null, element)
    
    # label string
    # action
    # hint
    myself.listContents.addItem myself.labelGetter(element), element, null, color

  @listContents.setPosition @contents.position()
  @listContents.isListContents = true
  @listContents.drawNew()
  @addContents @listContents

ListMorph::select = (item) ->
  @selected = item
  @action.call null, item  if @action

ListMorph::setExtent = (aPoint) ->
  lb = @listContents.bounds
  nb = @bounds.origin.copy().corner(@bounds.origin.add(aPoint))
  @listContents.setRight nb.right()  if nb.right() > lb.right() and nb.width() <= lb.width()
  @listContents.setBottom nb.bottom()  if nb.bottom() > lb.bottom() and nb.height() <= lb.height()
  super aPoint# StringMorph /////////////////////////////////////////////////////////

# I am a single line of text

class StringMorph extends Morph
  constructor: (text, fontSize, fontStyle, bold, italic, isNumeric, shadowOffset, shadowColor, color, fontName) ->
    @init text, fontSize, fontStyle, bold, italic, isNumeric, shadowOffset, shadowColor, color, fontName


# StringMorph instance creation:
StringMorph::init = (text, fontSize, fontStyle, bold, italic, isNumeric, shadowOffset, shadowColor, color, fontName) ->
  
  # additional properties:
  @text = text or ((if (text is "") then "" else "StringMorph"))
  @fontSize = fontSize or 12
  @fontName = fontName or MorphicPreferences.globalFontFamily
  @fontStyle = fontStyle or "sans-serif"
  @isBold = bold or false
  @isItalic = italic or false
  @isEditable = false
  @isNumeric = isNumeric or false
  @shadowOffset = shadowOffset or new Point(0, 0)
  @shadowColor = shadowColor or null
  @isShowingBlanks = false
  @blanksColor = new Color(180, 140, 140)
  
  # additional properties for text-editing:
  @currentlySelecting = false
  @startMark = 0
  @endMark = 0
  @markedTextColor = new Color(255, 255, 255)
  @markedBackgoundColor = new Color(60, 60, 120)
  
  # initialize inherited properties:
  super()
  
  # override inherited properites:
  @color = color or new Color(0, 0, 0)
  @noticesTransparentClick = true
  @drawNew()

StringMorph::toString = ->
  
  # e.g. 'a StringMorph("Hello World")'
  "a " + (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0]) + "(\"" + @text.slice(0, 30) + "...\")"

StringMorph::font = ->
  
  # answer a font string, e.g. 'bold italic 12px sans-serif'
  font = ""
  font = font + "bold "  if @isBold
  font = font + "italic "  if @isItalic
  font + @fontSize + "px " + ((if @fontName then @fontName + ", " else "")) + @fontStyle

StringMorph::drawNew = ->
  context = undefined
  width = undefined
  start = undefined
  stop = undefined
  i = undefined
  p = undefined
  c = undefined
  x = undefined
  y = undefined
  
  # initialize my surface property
  @image = newCanvas()
  context = @image.getContext("2d")
  context.font = @font()
  
  # set my extent
  width = Math.max(context.measureText(@text).width + Math.abs(@shadowOffset.x), 1)
  @bounds.corner = @bounds.origin.add(new Point(width, fontHeight(@fontSize) + Math.abs(@shadowOffset.y)))
  @image.width = width
  @image.height = @height()
  
  # prepare context for drawing text
  context.font = @font()
  context.textAlign = "left"
  context.textBaseline = "bottom"
  
  # first draw the shadow, if any
  if @shadowColor
    x = Math.max(@shadowOffset.x, 0)
    y = Math.max(@shadowOffset.y, 0)
    context.fillStyle = @shadowColor.toString()
    context.fillText @text, x, fontHeight(@fontSize) + y
  
  # now draw the actual text
  x = Math.abs(Math.min(@shadowOffset.x, 0))
  y = Math.abs(Math.min(@shadowOffset.y, 0))
  context.fillStyle = @color.toString()
  if @isShowingBlanks
    @renderWithBlanks context, x, fontHeight(@fontSize) + y
  else
    context.fillText @text, x, fontHeight(@fontSize) + y
  
  # draw the selection
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  i = start
  while i < stop
    p = @slotPosition(i).subtract(@position())
    c = @text.charAt(i)
    context.fillStyle = @markedBackgoundColor.toString()
    context.fillRect p.x, p.y, context.measureText(c).width + 1 + x, fontHeight(@fontSize) + y
    context.fillStyle = @markedTextColor.toString()
    context.fillText c, p.x + x, fontHeight(@fontSize) + y
    i += 1
  
  # notify my parent of layout change
  @parent.fixLayout()  if @parent.fixLayout  if @parent

StringMorph::renderWithBlanks = (context, startX, y) ->
  
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
  
  # render my text inserting blanks
  words.forEach (word) ->
    drawBlank()  unless isFirst
    isFirst = false
    if word isnt ""
      context.fillText word, x, y
      x += context.measureText(word).width



# StringMorph mesuring:
StringMorph::slotPosition = (slot) ->
  
  # answer the position point of the given index ("slot")
  # where the cursor should be placed
  dest = Math.min(Math.max(slot, 0), @text.length)
  context = @image.getContext("2d")
  xOffset = undefined
  x = undefined
  y = undefined
  idx = undefined
  xOffset = 0
  idx = 0
  while idx < dest
    xOffset += context.measureText(@text[idx]).width
    idx += 1
  @pos = dest
  x = @left() + xOffset
  y = @top()
  new Point(x, y)

StringMorph::slotAt = (aPoint) ->
  
  # answer the slot (index) closest to the given point
  # so the cursor can be moved accordingly
  idx = 0
  charX = 0
  context = @image.getContext("2d")
  while aPoint.x - @left() > charX
    charX += context.measureText(@text[idx]).width
    idx += 1
    return idx  if (context.measureText(@text).width - (context.measureText(@text[idx - 1]).width / 2)) < (aPoint.x - @left())  if idx is @text.length
  idx - 1

StringMorph::upFrom = (slot) ->
  
  # answer the slot above the given one
  slot

StringMorph::downFrom = (slot) ->
  
  # answer the slot below the given one
  slot

StringMorph::startOfLine = ->
  
  # answer the first slot (index) of the line for the given slot
  0

StringMorph::endOfLine = ->
  
  # answer the slot (index) indicating the EOL for the given slot
  @text.length


# StringMorph menus:
StringMorph::developersMenu = ->
  menu = super()
  menu.addLine()
  menu.addItem "edit", "edit"
  menu.addItem "font size...", (->
    @prompt menu.title + "\nfont\nsize:", @setFontSize, this, @fontSize.toString(), null, 6, 500, true
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
  menu

StringMorph::toggleIsDraggable = ->
  
  # for context menu demo purposes
  @isDraggable = not @isDraggable
  if @isDraggable
    @disableSelecting()
  else
    @enableSelecting()

StringMorph::toggleShowBlanks = ->
  @isShowingBlanks = not @isShowingBlanks
  @changed()
  @drawNew()
  @changed()

StringMorph::toggleWeight = ->
  @isBold = not @isBold
  @changed()
  @drawNew()
  @changed()

StringMorph::toggleItalic = ->
  @isItalic = not @isItalic
  @changed()
  @drawNew()
  @changed()

StringMorph::setSerif = ->
  @fontStyle = "serif"
  @changed()
  @drawNew()
  @changed()

StringMorph::setSansSerif = ->
  @fontStyle = "sans-serif"
  @changed()
  @drawNew()
  @changed()

StringMorph::setFontSize = (size) ->
  
  # for context menu demo purposes
  newSize = undefined
  if typeof size is "number"
    @fontSize = Math.round(Math.min(Math.max(size, 4), 500))
  else
    newSize = parseFloat(size)
    @fontSize = Math.round(Math.min(Math.max(newSize, 4), 500))  unless isNaN(newSize)
  @changed()
  @drawNew()
  @changed()

StringMorph::setText = (size) ->
  
  # for context menu demo purposes
  @text = Math.round(size).toString()
  @changed()
  @drawNew()
  @changed()

StringMorph::numericalSetters = ->
  
  # for context menu demo purposes
  ["setLeft", "setTop", "setAlphaScaled", "setFontSize", "setText"]


# StringMorph editing:
StringMorph::edit = ->
  @root().edit this

StringMorph::selection = ->
  start = undefined
  stop = undefined
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  @text.slice start, stop

StringMorph::selectionStartSlot = ->
  Math.min @startMark, @endMark

StringMorph::clearSelection = ->
  @currentlySelecting = false
  @startMark = 0
  @endMark = 0
  @drawNew()
  @changed()

StringMorph::deleteSelection = ->
  start = undefined
  stop = undefined
  text = undefined
  text = @text
  start = Math.min(@startMark, @endMark)
  stop = Math.max(@startMark, @endMark)
  @text = text.slice(0, start) + text.slice(stop)
  @changed()
  @clearSelection()

StringMorph::selectAll = ->
  if @mouseDownLeft # make sure selecting is enabled
    @startMark = 0
    @endMark = @text.length
    @drawNew()
    @changed()

StringMorph::mouseClickLeft = (pos) ->
  if @isEditable
    @edit()  unless @currentlySelecting
    @root().cursor.gotoPos pos
    @currentlySelecting = false
  else
    @escalateEvent "mouseClickLeft", pos

StringMorph::enableSelecting = ->
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

StringMorph::disableSelecting = ->
  delete @mouseDownLeft
  delete @mouseMove
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

MorphicPreferences = standardSettings
# TriggerMorph ////////////////////////////////////////////////////////

# I provide basic button functionality

class TriggerMorph extends Morph
  constructor: (target, action, labelString, fontSize, fontStyle, environment, hint, labelColor) ->
    @init target, action, labelString, fontSize, fontStyle, environment, hint, labelColor


# TriggerMorph instance creation:
TriggerMorph::init = (target, action, labelString, fontSize, fontStyle, environment, hint, labelColor) ->
  
  # additional properties:
  @target = target or null
  @action = action or null
  @environment = environment or null
  @labelString = labelString or null
  @label = null
  @hint = hint or null
  @fontSize = fontSize or MorphicPreferences.menuFontSize
  @fontStyle = fontStyle or "sans-serif"
  @highlightColor = new Color(192, 192, 192)
  @pressColor = new Color(128, 128, 128)
  @labelColor = labelColor or new Color(0, 0, 0)
  
  # initialize inherited properties:
  super()
  
  # override inherited properites:
  @color = new Color(255, 255, 255)
  @drawNew()


# TriggerMorph drawing:
TriggerMorph::drawNew = ->
  @createBackgrounds()
  @createLabel()  if @labelString isnt null

TriggerMorph::createBackgrounds = ->
  context = undefined
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

TriggerMorph::createLabel = ->
  @label.destroy()  if @label isnt null
  # bold
  # italic
  # numeric
  # shadow offset
  # shadow color
  @label = new StringMorph(@labelString, @fontSize, @fontStyle, false, false, false, null, null, @labelColor)
  @label.setPosition @center().subtract(@label.extent().floorDivideBy(2))
  @add @label


# TriggerMorph duplicating:
TriggerMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.label = (dict[@label])  if c.label and dict[@label]
  c


# TriggerMorph action:
TriggerMorph::trigger = ->
  
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
TriggerMorph::mouseEnter = ->
  @image = @highlightImage
  @changed()
  @bubbleHelp @hint  if @hint

TriggerMorph::mouseLeave = ->
  @image = @normalImage
  @changed()
  @world().hand.destroyTemporaries()  if @hint

TriggerMorph::mouseDownLeft = ->
  @image = @pressImage
  @changed()

TriggerMorph::mouseClickLeft = ->
  @image = @highlightImage
  @changed()
  @trigger()


# TriggerMorph bubble help:
TriggerMorph::bubbleHelp = (contents) ->
  myself = this
  @fps = 2
  @step = ->
    myself.popUpbubbleHelp contents  if @bounds.containsPoint(@world().hand.position())
    myself.fps = 0
    delete myself.step

TriggerMorph::popUpbubbleHelp = (contents) ->
  new SpeechBubbleMorph(localize(contents), null, null, 1).popUp @world(), @rightCenter().add(new Point(-8, 0))
# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph
  constructor: (target, action, labelString, fontSize, fontStyle, environment, hint, color) ->
    @init target, action, labelString, fontSize, fontStyle, environment, hint, color

# MenuItemMorph instance creation:
MenuItemMorph::createLabel = ->
  np = undefined
  @label.destroy()  if @label isnt null
  # bold
  # italic
  # numeric
  # shadow offset
  # shadow color
  @label = new StringMorph(@labelString, @fontSize, @fontStyle, false, false, false, null, null, @labelColor)
  @silentSetExtent @label.extent().add(new Point(8, 0))
  np = @position().add(new Point(4, 0))
  @label.bounds = np.extent(@label.extent())
  @add @label


# MenuItemMorph events:
MenuItemMorph::mouseEnter = ->
  unless @isListItem()
    @image = @highlightImage
    @changed()
  @bubbleHelp @hint  if @hint

MenuItemMorph::mouseLeave = ->
  unless @isListItem()
    @image = @normalImage
    @changed()
  @world().hand.destroyTemporaries()  if @hint

MenuItemMorph::mouseDownLeft = (pos) ->
  if @isListItem()
    @parent.unselectAllItems()
    @escalateEvent "mouseDownLeft", pos
  @image = @pressImage
  @changed()

MenuItemMorph::mouseMove = ->
  @escalateEvent "mouseMove"  if @isListItem()

MenuItemMorph::mouseClickLeft = ->
  unless @isListItem()
    @parent.destroy()
    @root().activeMenu = null
  @trigger()

MenuItemMorph::isListItem = ->
  return @parent.isListContents  if @parent
  false

MenuItemMorph::isSelectedListItem = ->
  return @image is @pressImage  if @isListItem()
  false
morphicVersion = "2012-October-16"
# HandMorph ///////////////////////////////////////////////////////////

# I represent the Mouse cursor

# HandMorph inherits from Morph:

class HandMorph extends Morph
  constructor: (aWorld) ->
    @init aWorld

# HandMorph instance creation:

# HandMorph initialization:
HandMorph::init = (aWorld) ->
  super()
  @bounds = new Rectangle()
  
  # additional properties:
  @world = aWorld
  @mouseButton = null
  @mouseOverList = []
  @mouseDownMorph = null
  @morphToGrab = null
  @grabOrigin = null
  @temporaries = []
  @touchHoldTimeout = null

HandMorph::changed = ->
  b = undefined
  if @world isnt null
    b = @fullBounds()
    @world.broken.push @fullBounds().spread()  unless b.extent().eq(new Point())


# HandMorph navigation:
HandMorph::morphAtPointer = ->
  morphs = @world.allChildren().slice(0).reverse()
  myself = this
  result = null
  morphs.forEach (m) ->
    result = m  if m.visibleBounds().containsPoint(myself.bounds.origin) and result is null and m.isVisible and (m.noticesTransparentClick or (not m.isTransparentAt(myself.bounds.origin))) and (m not instanceof ShadowMorph)
  
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
HandMorph::allMorphsAtPointer = ->
  morphs = @world.allChildren()
  myself = this
  morphs.filter (m) ->
    m.isVisible and m.visibleBounds().containsPoint(myself.bounds.origin)



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
HandMorph::dropTargetFor = (aMorph) ->
  target = @morphAtPointer()
  target = target.parent  until target.wantsDropOf(aMorph)
  target

HandMorph::grab = (aMorph) ->
  oldParent = aMorph.parent
  return null  if aMorph instanceof WorldMorph
  if @children.length is 0
    @world.stopEditing()
    @grabOrigin = aMorph.situation()
    aMorph.addShadow()
    aMorph.prepareToBeGrabbed this  if aMorph.prepareToBeGrabbed
    @add aMorph
    @changed()
    oldParent.reactToGrabOf aMorph  if oldParent and oldParent.reactToGrabOf

HandMorph::drop = ->
  target = undefined
  morphToDrop = undefined
  if @children.length isnt 0
    morphToDrop = @children[0]
    target = @dropTargetFor(morphToDrop)
    @changed()
    target.add morphToDrop
    morphToDrop.changed()
    morphToDrop.removeShadow()
    @children = []
    @setExtent new Point()
    morphToDrop.justDropped this  if morphToDrop.justDropped
    target.reactToDropOf morphToDrop, this  if target.reactToDropOf
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
HandMorph::processMouseDown = (event) ->
  morph = undefined
  expectedClick = undefined
  actualClick = undefined
  @destroyTemporaries()
  @morphToGrab = null
  if @children.length isnt 0
    @drop()
    @mouseButton = null
  else
    morph = @morphAtPointer()
    if @world.activeMenu
      unless contains(morph.allParents(), @world.activeMenu)
        @world.activeMenu.destroy()
      else
        clearInterval @touchHoldTimeout
    @world.activeHandle.destroy()  if morph isnt @world.activeHandle  if @world.activeHandle
    @world.stopEditing()  if morph isnt @world.cursor.target  if @world.cursor
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

HandMorph::processTouchStart = (event) ->
  myself = this
  clearInterval @touchHoldTimeout
  if event.touches.length is 1
    # simulate mouseRightClick
    @touchHoldTimeout = setInterval(->
      myself.processMouseDown button: 2
      myself.processMouseUp button: 2
      event.preventDefault()
      clearInterval myself.touchHoldTimeout
    , 400)
    @processMouseMove event.touches[0] # update my position
    @processMouseDown button: 0
    event.preventDefault()

HandMorph::processTouchMove = (event) ->
  if event.touches.length is 1
    touch = event.touches[0]
    @processMouseMove touch
    clearInterval @touchHoldTimeout

HandMorph::processTouchEnd = (event) ->
  clearInterval @touchHoldTimeout
  @processMouseUp button: 0

HandMorph::processMouseUp = ->
  morph = @morphAtPointer()
  context = undefined
  contextMenu = undefined
  expectedClick = undefined
  @destroyTemporaries()
  if @children.length isnt 0
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

HandMorph::processMouseScroll = (event) ->
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
HandMorph::processDrop = (event) ->
  
  #
  #    find out whether an external image or audio file was dropped
  #    onto the world canvas, turn it into an offscreen canvas or audio
  #    element and dispatch the
  #    
  #        droppedImage(canvas, name)
  #        droppedAudio(audio, name)
  #    
  #    events to interested Morphs at the mouse pointer
  #
  
  files = (if event instanceof FileList then event else (event.target.files || event.dataTransfer.files))
  file = undefined
  txt = (if event.dataTransfer then event.dataTransfer.getData("Text/HTML") else null)
  src = undefined
  targetDrop = @morphAtPointer()
  img = new Image()
  canvas = undefined
  i = undefined
  
  readImage = (aFile) ->
    pic = new Image()
    frd = new FileReader()
    targetDrop = targetDrop.parent  until targetDrop.droppedImage
    pic.onload = ->
      canvas = newCanvas(new Point(pic.width, pic.height))
      canvas.getContext("2d").drawImage pic, 0, 0
      targetDrop.droppedImage canvas, aFile.name
    
    frd = new FileReader()
    frd.onloadend = (e) ->
      pic.src = e.target.result
    
    frd.readAsDataURL aFile
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
  parseImgURL = (html) ->
    url = ""
    i = undefined
    c = undefined
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
  if files.length > 0
    i = 0
    while i < files.length
      file = files[i]
      if file.type.indexOf("image") is 0
        readImage file
      else if file.type.indexOf("audio") is 0
        readAudio file
      else readText file  if file.type.indexOf("text") is 0
      i += 1
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
HandMorph::destroyTemporaries = ->
  
  #
  #	temporaries are just an array of morphs which will be deleted upon
  #	the next mouse click, or whenever another temporary Morph decides
  #	that it needs to remove them. The primary purpose of temporaries is
  #	to display tools tips of speech bubble help.
  #
  @temporaries.forEach (morph) ->
    morph.destroy()
  
  @temporaries = []


# HandMorph dragging optimization
HandMorph::moveBy = (delta) ->
  Morph::trackChanges = false
  super delta
  Morph::trackChanges = true
  @fullChanged()

HandMorph::processMouseMove = (event) ->
  pos = undefined
  posInDocument = getDocumentPositionOf(@world.worldCanvas)
  mouseOverNew = undefined
  myself = this
  morph = undefined
  topMorph = undefined
  fb = undefined
  pos = new Point(event.pageX - posInDocument.x, event.pageY - posInDocument.y)
  @setPosition pos
  
  # determine the new mouse-over-list:
  # mouseOverNew = this.allMorphsAtPointer();
  mouseOverNew = @morphAtPointer().allParents()
  if (@children.length is 0) and (@mouseButton is "left")
    topMorph = @morphAtPointer()
    morph = topMorph.rootForGrab()
    topMorph.mouseMove pos  if topMorph.mouseMove
    
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
      
      # if the mouse has left its fullBounds, center it
      fb = morph.fullBounds()
      unless fb.containsPoint(pos)
        @bounds.origin = fb.center()
        @grab morph
        @setPosition pos
  
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
  
  mouseOverNew.forEach (newMorph) ->
    unless contains(myself.mouseOverList, newMorph)
      newMorph.mouseEnter()  if newMorph.mouseEnter
      newMorph.mouseEnterDragging()  if newMorph.mouseEnterDragging and @mouseButton
    
    # autoScrolling support:
    if myself.children.length > 0
        if newMorph instanceof ScrollFrameMorph
            if !newMorph.bounds.insetBy( MorphicPreferences.scrollBarSize * 3).containsPoint(myself.bounds.origin)
                newMorph.startAutoScrolling();
  
  @mouseOverList = mouseOverNew
# MorphsListMorph //////////////////////////////////////////////////////

class MorphsListMorph extends BoxMorph
  constructor: (target) ->
    @init target

# MorphsListMorph instance creation:
MorphsListMorph::init = () ->
  # additional properties:
  
  # initialize inherited properties:
  super()
  
  # override inherited properties:
  @silentSetExtent new Point(MorphicPreferences.handleSize * 10, MorphicPreferences.handleSize * 20 * 2 / 3)
  @isDraggable = true
  @border = 1
  @edge = 5
  @color = new Color(60, 60, 60)
  @borderColor = new Color(95, 95, 95)
  @drawNew()
  
  # panes:
  @morphsList = null
  @buttonClose = null
  @resizer = null
  @buildPanes()

MorphsListMorph::setTarget = (target) ->
  @target = target
  @currentProperty = null
  @buildPanes()

MorphsListMorph::buildPanes = ->
  attribs = []
  property = undefined
  myself = this
  ctrl = undefined
  ev = undefined
  
  # remove existing panes
  @children.forEach (m) ->
    # keep work pane around
    m.destroy()  if m isnt @work
  
  @children = []
  
  # label
  @label = new TextMorph("Morphs List")
  @label.fontSize = MorphicPreferences.menuFontSize
  @label.isBold = true
  @label.color = new Color(255, 255, 255)
  @label.drawNew()
  @add @label
  
  ListOfMorphs = []
  for i of window
    theWordMorph = "Morph"
    ListOfMorphs.push i  if i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
  @morphsList = new ListMorph(ListOfMorphs, null)
  
  # so far nothing happens when items are selected
  #@morphsList.action = (selected) ->
  #  val = undefined
  #  txt = undefined
  #  cnts = undefined
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
  @buttonClose.action = ->
    myself.destroy()
  
  @add @buttonClose
  
  # resizer
  @resizer = new HandleMorph(this, 150, 100, @edge, @edge)
  
  # update layout
  @fixLayout()

MorphsListMorph::fixLayout = ->
  x = undefined
  y = undefined
  r = undefined
  b = undefined
  w = undefined
  h = undefined
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
    @drawNew()
    @changed()
    @resizer.drawNew()
  
  # morphsList
  y = @label.bottom() + 2
  w = @width() - @edge
  w -= @edge
  b = @bottom() - (2 * @edge) - MorphicPreferences.handleSize
  h = b - y
  @morphsList.setPosition new Point(x, y)
  @morphsList.setExtent new Point(w, h)
  
  # close button
  x = @morphsList.left()
  y = @morphsList.bottom() + @edge
  h = MorphicPreferences.handleSize
  w = @morphsList.width() - h - @edge
  @buttonClose.setPosition new Point(x, y)
  @buttonClose.setExtent new Point(w, h)
  Morph::trackChanges = true
  @changed()

MorphsListMorph::setExtent = (aPoint) ->
  super aPoint
  @fixLayout()

# SliderButtonMorph ///////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class SliderButtonMorph extends CircleBoxMorph
  constructor: (orientation) ->
    @init orientation

SliderButtonMorph::init = (orientation) ->
  @color = new Color(80, 80, 80)
  @highlightColor = new Color(90, 90, 140)
  @pressColor = new Color(80, 80, 160)
  @is3D = true
  @hasMiddleDip = true
  super orientation

SliderButtonMorph::autoOrientation = noOpFunction

SliderButtonMorph::drawNew = ->
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

SliderButtonMorph::drawEdges = ->
  context = @image.getContext("2d")
  gradient = undefined
  radius = undefined
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
      gradient = context.createLinearGradient(context.lineWidth, 0, w - context.lineWidth, 0)
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
      gradient = context.createLinearGradient(0, context.lineWidth, 0, h - context.lineWidth)
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
SliderButtonMorph::mouseEnter = ->
  @image = @highlightImage
  @changed()

SliderButtonMorph::mouseLeave = ->
  @image = @normalImage
  @changed()

SliderButtonMorph::mouseDownLeft = (pos) ->
  @image = @pressImage
  @changed()
  @escalateEvent "mouseDownLeft", pos

SliderButtonMorph::mouseClickLeft = ->
  @image = @highlightImage
  @changed()

# prevent my parent from getting picked up
SliderButtonMorph::mouseMove = noOpFunction
# MouseSensorMorph ////////////////////////////////////////////////////

# for demo and debuggin purposes only, to be removed later
class MouseSensorMorph extends BoxMorph
  constructor: (edge, border, borderColor) ->
    @init edge, border, borderColor

# MouseSensorMorph instance creation:
MouseSensorMorph::init = (edge, border, borderColor) ->
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

MouseSensorMorph::touch = ->
  myself = this
  unless @isTouched
    @isTouched = true
    @alpha = 0.6
    @step = ->
      if myself.isTouched
        myself.alpha = myself.alpha + myself.upStep  if myself.alpha < 1
      else if myself.alpha > (myself.downStep)
        myself.alpha = myself.alpha - myself.downStep
      else
        myself.alpha = 0
        myself.step = null
      myself.changed()

MouseSensorMorph::unTouch = ->
  @isTouched = false

MouseSensorMorph::mouseEnter = ->
  @touch()

MouseSensorMorph::mouseLeave = ->
  @unTouch()

MouseSensorMorph::mouseDownLeft = ->
  @touch()

MouseSensorMorph::mouseClickLeft = ->
  @unTouch()
# MenuMorph ///////////////////////////////////////////////////////////

class MenuMorph extends BoxMorph
  constructor: (target, title, environment, fontSize) ->
    @init target, title, environment, fontSize


# MenuMorph: referenced constructors

# MenuMorph instance creation:
MenuMorph::init = (target, title, environment, fontSize) ->
  
  # additional properties:
  @target = target
  @title = title or null
  @environment = environment or null
  @fontSize = fontSize or null
  @items = []
  @label = null
  @world = null
  @isListContents = false
  
  # initialize inherited properties:
  super()
  
  # override inherited properties:
  @isDraggable = false
  
  # immutable properties:
  @border = null
  @edge = null

MenuMorph::addItem = (labelString, action, hint, color) ->
  @items.push [localize(labelString or "close"), action or nop, hint, color]

MenuMorph::addLine = (width) ->
  @items.push [0, width or 1]

MenuMorph::createLabel = ->
  text = undefined
  @label.destroy()  if @label isnt null
  text = new TextMorph(localize(@title), @fontSize or MorphicPreferences.menuFontSize, MorphicPreferences.menuFontName, true, false, "center")
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

MenuMorph::drawNew = ->
  myself = this
  item = undefined
  fb = undefined
  x = undefined
  y = undefined
  isLine = false
  @children.forEach (m) ->
    m.destroy()
  
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
  @items.forEach (tuple) ->
    isLine = false
    if tuple instanceof StringFieldMorph or tuple instanceof ColorPickerMorph or tuple instanceof SliderMorph
      item = tuple
    else if tuple[0] is 0
      isLine = true
      item = new Morph()
      item.color = myself.borderColor
      item.setHeight tuple[1]
    else
      # bubble help hint
      item = new MenuItemMorph(myself.target, tuple[1], tuple[0], myself.fontSize or MorphicPreferences.menuFontSize, MorphicPreferences.menuFontName, myself.environment, tuple[2], tuple[3]) # color
    y += 1  if isLine
    item.setPosition new Point(x, y)
    myself.add item
    y = y + item.height()
    y += 1  if isLine
  
  fb = @fullBounds()
  @silentSetExtent fb.extent().add(4)
  @adjustWidths()
  super()

MenuMorph::maxWidth = ->
  w = 0
  w = @parent.width()  if @parent.scrollFrame instanceof ScrollFrameMorph  if @parent instanceof FrameMorph
  @children.forEach (item) ->
    w = Math.max(w, item.width())  if (item instanceof MenuItemMorph) or (item instanceof StringFieldMorph) or (item instanceof ColorPickerMorph) or (item instanceof SliderMorph)
  
  w = Math.max(w, @label.width())  if @label
  w

MenuMorph::adjustWidths = ->
  w = @maxWidth()
  myself = this
  @children.forEach (item) ->
    item.silentSetWidth w
    if item instanceof MenuItemMorph
      item.createBackgrounds()
    else
      item.drawNew()
      item.text.setPosition item.center().subtract(item.text.extent().floorDivideBy(2))  if item is myself.label


MenuMorph::unselectAllItems = ->
  @children.forEach (item) ->
    item.image = item.normalImage  if item instanceof MenuItemMorph
  
  @changed()

MenuMorph::popup = (world, pos) ->
  @drawNew()
  @setPosition pos
  @addShadow new Point(2, 2), 80
  @keepWithin world
  world.activeMenu.destroy()  if world.activeMenu
  world.add this
  world.activeMenu = this
  @fullChanged()

MenuMorph::popUpAtHand = (world) ->
  wrrld = world or @world
  @popup wrrld, wrrld.hand.position()

MenuMorph::popUpCenteredAtHand = (world) ->
  wrrld = world or @world
  @drawNew()
  @popup wrrld, wrrld.hand.position().subtract(@extent().floorDivideBy(2))

MenuMorph::popUpCenteredInWorld = (world) ->
  wrrld = world or @world
  @drawNew()
  @popup wrrld, wrrld.center().subtract(@extent().floorDivideBy(2))

# PenMorph ////////////////////////////////////////////////////////////

# I am a simple LOGO-wise turtle.

class PenMorph extends Morph
  constructor: () ->
    @init()

# PenMorph: referenced constructors

# PenMorph instance creation:
PenMorph::init = ->
  size = MorphicPreferences.handleSize * 4
  
  # additional properties:
  @isWarped = false # internal optimization
  @wantsRedraw = false # internal optimization
  @heading = 0
  @isDown = true
  @size = 1
  super()
  @setExtent new Point(size, size)


# PenMorph updating - optimized for warping, i.e atomic recursion
PenMorph::changed = ->
  if @isWarped is false
    w = @root()
    w.broken.push @visibleBounds().spread()  if w instanceof WorldMorph
    @parent.childChanged this  if @parent


# PenMorph display:
PenMorph::drawNew = (facing) ->
  
  #
  #    my orientation can be overridden with the "facing" parameter to
  #    implement Scratch-style rotation styles
  #    
  #
  context = undefined
  start = undefined
  dest = undefined
  left = undefined
  right = undefined
  len = undefined
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
PenMorph::setHeading = (degrees) ->
  @heading = parseFloat(degrees) % 360
  if @isWarped is false
    @drawNew()
    @changed()


# PenMorph drawing:
PenMorph::drawLine = (start, dest) ->
  context = @parent.penTrails().getContext("2d")
  from = start.subtract(@parent.bounds.origin)
  to = dest.subtract(@parent.bounds.origin)
  if @isDown
    context.lineWidth = @size
    context.strokeStyle = @color.toString()
    context.lineCap = "round"
    context.lineJoin = "round"
    context.beginPath()
    context.moveTo from.x, from.y
    context.lineTo to.x, to.y
    context.stroke()
    @world().broken.push start.rectangle(dest).expandBy(Math.max(@size / 2, 1)).intersect(@parent.visibleBounds()).spread()  if @isWarped is false


# PenMorph turtle ops:
PenMorph::turn = (degrees) ->
  @setHeading @heading + parseFloat(degrees)

PenMorph::forward = (steps) ->
  start = @center()
  dest = undefined
  dist = parseFloat(steps)
  if dist >= 0
    dest = @position().distanceAngle(dist, @heading)
  else
    dest = @position().distanceAngle(Math.abs(dist), (@heading - 180))
  @setPosition dest
  @drawLine start, @center()

PenMorph::down = ->
  @isDown = true

PenMorph::up = ->
  @isDown = false

PenMorph::clear = ->
  @parent.drawNew()
  @parent.changed()


# PenMorph optimization for atomic recursion:
PenMorph::startWarp = ->
  @isWarped = true

PenMorph::endWarp = ->
  @drawNew()  if @wantsRedraw
  @changed()
  @parent.changed()
  @isWarped = false

PenMorph::warp = (fun) ->
  @startWarp()
  fun.call this
  @endWarp()

PenMorph::warpOp = (selector, argsArray) ->
  @startWarp()
  this[selector].apply this, argsArray
  @endWarp()


# PenMorph demo ops:
# try these with WARP eg.: this.warp(function () {tree(12, 120, 20)})
PenMorph::warpSierpinski = (length, min) ->
  @warpOp "sierpinski", [length, min]

PenMorph::sierpinski = (length, min) ->
  i = undefined
  if length > min
    i = 0
    while i < 3
      @sierpinski length * 0.5, min
      @turn 120
      @forward length
      i += 1

PenMorph::warpTree = (level, length, angle) ->
  @warpOp "tree", [level, length, angle]

PenMorph::tree = (level, length, angle) ->
  if level > 0
    @size = level
    @forward length
    @turn angle
    @tree level - 1, length * 0.75, angle
    @turn angle * -2
    @tree level - 1, length * 0.75, angle
    @turn angle
    @forward -length
# Points //////////////////////////////////////////////////////////////

# Point instance creation:
Point = (x, y) ->
  @x = x or 0
  @y = y or 0

# Point string representation: e.g. '12@68'
Point::toString = ->
  Math.round(@x.toString()) + "@" + Math.round(@y.toString())


# Point copying:
Point::copy = ->
  new Point(@x, @y)


# Point comparison:
Point::eq = (aPoint) ->
  
  # ==
  @x is aPoint.x and @y is aPoint.y

Point::lt = (aPoint) ->
  
  # <
  @x < aPoint.x and @y < aPoint.y

Point::gt = (aPoint) ->
  
  # >
  @x > aPoint.x and @y > aPoint.y

Point::ge = (aPoint) ->
  
  # >=
  @x >= aPoint.x and @y >= aPoint.y

Point::le = (aPoint) ->
  
  # <=
  @x <= aPoint.x and @y <= aPoint.y

Point::max = (aPoint) ->
  new Point(Math.max(@x, aPoint.x), Math.max(@y, aPoint.y))

Point::min = (aPoint) ->
  new Point(Math.min(@x, aPoint.x), Math.min(@y, aPoint.y))


# Point conversion:
Point::round = ->
  new Point(Math.round(@x), Math.round(@y))

Point::abs = ->
  new Point(Math.abs(@x), Math.abs(@y))

Point::neg = ->
  new Point(-@x, -@y)

Point::mirror = ->
  new Point(@y, @x)

Point::floor = ->
  new Point(Math.max(Math.floor(@x), 0), Math.max(Math.floor(@y), 0))

Point::ceil = ->
  new Point(Math.ceil(@x), Math.ceil(@y))


# Point arithmetic:
Point::add = (other) ->
  return new Point(@x + other.x, @y + other.y)  if other instanceof Point
  new Point(@x + other, @y + other)

Point::subtract = (other) ->
  return new Point(@x - other.x, @y - other.y)  if other instanceof Point
  new Point(@x - other, @y - other)

Point::multiplyBy = (other) ->
  return new Point(@x * other.x, @y * other.y)  if other instanceof Point
  new Point(@x * other, @y * other)

Point::divideBy = (other) ->
  return new Point(@x / other.x, @y / other.y)  if other instanceof Point
  new Point(@x / other, @y / other)

Point::floorDivideBy = (other) ->
  return new Point(Math.floor(@x / other.x), Math.floor(@y / other.y))  if other instanceof Point
  new Point(Math.floor(@x / other), Math.floor(@y / other))


# Point polar coordinates:
Point::r = ->
  t = (@multiplyBy(this))
  Math.sqrt t.x + t.y

Point::degrees = ->
  
  #
  #    answer the angle I make with origin in degrees.
  #    Right is 0, down is 90
  #
  tan = undefined
  theta = undefined
  if @x is 0
    return 90  if @y >= 0
    return 270
  tan = @y / @x
  theta = Math.atan(tan)
  if @x >= 0
    return degrees(theta)  if @y >= 0
    return 360 + (degrees(theta))
  180 + degrees(theta)

Point::theta = ->
  
  #
  #    answer the angle I make with origin in radians.
  #    Right is 0, down is 90
  #
  tan = undefined
  theta = undefined
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
Point::crossProduct = (aPoint) ->
  @multiplyBy aPoint.mirror()

Point::distanceTo = (aPoint) ->
  (aPoint.subtract(this)).r()

Point::rotate = (direction, center) ->
  
  # direction must be 'right', 'left' or 'pi'
  offset = @subtract(center)
  return new Point(-offset.y, offset.y).add(center)  if direction is "right"
  return new Point(offset.y, -offset.y).add(center)  if direction is "left"
  
  # direction === 'pi'
  center.subtract offset

Point::flip = (direction, center) ->
  
  # direction must be 'vertical' or 'horizontal'
  return new Point(@x, center.y * 2 - @y)  if direction is "vertical"
  
  # direction === 'horizontal'
  new Point(center.x * 2 - @x, @y)

Point::distanceAngle = (dist, angle) ->
  deg = angle
  x = undefined
  y = undefined
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
Point::scaleBy = (scalePoint) ->
  @multiplyBy scalePoint

Point::translateBy = (deltaPoint) ->
  @add deltaPoint

Point::rotateBy = (angle, centerPoint) ->
  center = centerPoint or new Point(0, 0)
  p = @subtract(center)
  r = p.r()
  theta = angle - p.theta()
  new Point(center.x + (r * Math.cos(theta)), center.y - (r * Math.sin(theta)))


# Point conversion:
Point::asArray = ->
  [@x, @y]

# creating Rectangle instances from Points:
Point::corner = (cornerPoint) ->
  
  # answer a new Rectangle
  new Rectangle(@x, @y, cornerPoint.x, cornerPoint.y)

Point::rectangle = (aPoint) ->
  
  # answer a new Rectangle
  org = undefined
  crn = undefined
  org = @min(aPoint)
  crn = @max(aPoint)
  new Rectangle(org.x, org.y, crn.x, crn.y)

Point::extent = (aPoint) ->
  
  #answer a new Rectangle
  crn = @add(aPoint)
  new Rectangle(@x, @y, crn.x, crn.y)
# Rectangles //////////////////////////////////////////////////////////

class Rectangle
  constructor: (left, top, right, bottom) ->
    @init new Point((left or 0), (top or 0)), new Point((right or 0), (bottom or 0))


# Rectangle instance creation:
Rectangle::init = (originPoint, cornerPoint) ->
  @origin = originPoint
  @corner = cornerPoint


# Rectangle string representation: e.g. '[0@0 | 160@80]'
Rectangle::toString = ->
  "[" + @origin.toString() + " | " + @extent().toString() + "]"


# Rectangle copying:
Rectangle::copy = ->
  new Rectangle(@left(), @top(), @right(), @bottom())


# Rectangle accessing - setting:
Rectangle::setTo = (left, top, right, bottom) ->
  
  # note: all inputs are optional and can be omitted
  @origin = new Point(left or ((if (left is 0) then 0 else @left())), top or ((if (top is 0) then 0 else @top())))
  @corner = new Point(right or ((if (right is 0) then 0 else @right())), bottom or ((if (bottom is 0) then 0 else @bottom())))


# Rectangle accessing - getting:
Rectangle::area = ->
  
  #requires width() and height() to be defined
  w = @width()
  return 0  if w < 0
  Math.max w * @height(), 0

Rectangle::bottom = ->
  @corner.y

Rectangle::bottomCenter = ->
  new Point(@center().x, @bottom())

Rectangle::bottomLeft = ->
  new Point(@origin.x, @corner.y)

Rectangle::bottomRight = ->
  @corner.copy()

Rectangle::boundingBox = ->
  this

Rectangle::center = ->
  @origin.add @corner.subtract(@origin).floorDivideBy(2)

Rectangle::corners = ->
  [@origin, @bottomLeft(), @corner, @topRight()]

Rectangle::extent = ->
  @corner.subtract @origin

Rectangle::height = ->
  @corner.y - @origin.y

Rectangle::left = ->
  @origin.x

Rectangle::leftCenter = ->
  new Point(@left(), @center().y)

Rectangle::right = ->
  @corner.x

Rectangle::rightCenter = ->
  new Point(@right(), @center().y)

Rectangle::top = ->
  @origin.y

Rectangle::topCenter = ->
  new Point(@center().x, @top())

Rectangle::topLeft = ->
  @origin

Rectangle::topRight = ->
  new Point(@corner.x, @origin.y)

Rectangle::width = ->
  @corner.x - @origin.x

Rectangle::position = ->
  @origin


# Rectangle comparison:
Rectangle::eq = (aRect) ->
  @origin.eq(aRect.origin) and @corner.eq(aRect.corner)

Rectangle::abs = ->
  newOrigin = undefined
  newCorner = undefined
  newOrigin = @origin.abs()
  newCorner = @corner.max(newOrigin)
  newOrigin.corner newCorner


# Rectangle functions:
Rectangle::insetBy = (delta) ->
  
  # delta can be either a Point or a Number
  result = new Rectangle()
  result.origin = @origin.add(delta)
  result.corner = @corner.subtract(delta)
  result

Rectangle::expandBy = (delta) ->
  
  # delta can be either a Point or a Number
  result = new Rectangle()
  result.origin = @origin.subtract(delta)
  result.corner = @corner.add(delta)
  result

Rectangle::growBy = (delta) ->
  
  # delta can be either a Point or a Number
  result = new Rectangle()
  result.origin = @origin.copy()
  result.corner = @corner.add(delta)
  result

Rectangle::intersect = (aRect) ->
  result = new Rectangle()
  result.origin = @origin.max(aRect.origin)
  result.corner = @corner.min(aRect.corner)
  result

Rectangle::merge = (aRect) ->
  result = new Rectangle()
  result.origin = @origin.min(aRect.origin)
  result.corner = @corner.max(aRect.corner)
  result

Rectangle::round = ->
  @origin.round().corner @corner.round()

Rectangle::spread = ->
  
  # round me by applying floor() to my origin and ceil() to my corner
  @origin.floor().corner @corner.ceil()

Rectangle::amountToTranslateWithin = (aRect) ->
  
  #
  #    Answer a Point, delta, such that self + delta is forced within
  #    aRectangle. when all of me cannot be made to fit, prefer to keep
  #    my topLeft inside. Taken from Squeak.
  #
  dx = undefined
  dy = undefined
  dx = aRect.right() - @right()  if @right() > aRect.right()
  dy = aRect.bottom() - @bottom()  if @bottom() > aRect.bottom()
  dx = aRect.left() - @right()  if (@left() + dx) < aRect.left()
  dy = aRect.top() - @top()  if (@top() + dy) < aRect.top()
  new Point(dx, dy)


# Rectangle testing:
Rectangle::containsPoint = (aPoint) ->
  @origin.le(aPoint) and aPoint.lt(@corner)

Rectangle::containsRectangle = (aRect) ->
  aRect.origin.gt(@origin) and aRect.corner.lt(@corner)

Rectangle::intersects = (aRect) ->
  ro = aRect.origin
  rc = aRect.corner
  (rc.x >= @origin.x) and (rc.y >= @origin.y) and (ro.x <= @corner.x) and (ro.y <= @corner.y)


# Rectangle transforming:
Rectangle::scaleBy = (scale) ->
  
  # scale can be either a Point or a scalar
  o = @origin.multiplyBy(scale)
  c = @corner.multiplyBy(scale)
  new Rectangle(o.x, o.y, c.x, c.y)

Rectangle::translateBy = (factor) ->
  
  # factor can be either a Point or a scalar
  o = @origin.add(factor)
  c = @corner.add(factor)
  new Rectangle(o.x, o.y, c.x, c.y)


# Rectangle converting:
Rectangle::asArray = ->
  [@left(), @top(), @right(), @bottom()]

Rectangle::asArray_xywh = ->
  [@left(), @top(), @width(), @height()]
# StringFieldMorph ////////////////////////////////////////////////////

class StringFieldMorph extends FrameMorph
  constructor: (defaultContents, minWidth, fontSize, fontStyle, bold, italic, isNumeric) ->
    @init defaultContents or "", minWidth or 100, fontSize or 12, fontStyle or "sans-serif", bold or false, italic or false, isNumeric

StringFieldMorph::init = (defaultContents, minWidth, fontSize, fontStyle, bold, italic, isNumeric) ->
  @defaultContents = defaultContents
  @minWidth = minWidth
  @fontSize = fontSize
  @fontStyle = fontStyle
  @isBold = bold
  @isItalic = italic
  @isNumeric = isNumeric or false
  @text = null
  super()
  @color = new Color(255, 255, 255)
  @isEditable = true
  @acceptsDrops = false
  @drawNew()

StringFieldMorph::drawNew = ->
  txt = undefined
  txt = (if @text then @string() else @defaultContents)
  @text = null
  @children.forEach (child) ->
    child.destroy()
  
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

StringFieldMorph::string = ->
  @text.text

StringFieldMorph::mouseClickLeft = ->
  @text.edit()  if @isEditable


# StringFieldMorph duplicating:
StringFieldMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.text = (dict[@text])  if c.text and dict[@text]
  c
