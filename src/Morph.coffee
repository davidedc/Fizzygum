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
      context.drawImage bg, x * bg.width, y * bg.height
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
    context.drawImage @image, src.left(), src.top(), w, h, area.left(), area.top(), w, h


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
      ctx.drawImage morph.image, morph.bounds.origin.x - fb.origin.x, morph.bounds.origin.y - fb.origin.y
  
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
  ctx.drawImage img, -offset.x, -offset.y
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
  ctx.drawImage img, blur - offset.x, blur - offset.y
  ctx.shadowOffsetX = 0
  ctx.shadowOffsetY = 0
  ctx.shadowBlur = 0
  ctx.globalCompositeOperation = "destination-out"
  ctx.drawImage img, blur - offset.x, blur - offset.y
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
  ctx.drawImage @fullImage(), oRect.origin.x - fb.origin.x, oRect.origin.y - fb.origin.y
  ctx.globalCompositeOperation = "source-in"
  ctx.drawImage otherMorph.fullImage(), otherFb.origin.x - oRect.origin.x, otherFb.origin.y - oRect.origin.y
  oImg
