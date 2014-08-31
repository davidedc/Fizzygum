# Morph //////////////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class Morph extends MorphicNode

  # we want to keep track of how many instances we have
  # of each Morph for a few reasons:
  # 1) it gives us an identifier for each Morph
  # 2) profiling
  # 3) generate a uniqueIDString that we can use
  #    for example for hashtables
  # each subclass of Morph has its own static
  # instancesCounter which starts from zero. First object
  # has instanceNumericID of 1.
  # instanceNumericID is initialised in the constructor.
  @instancesCounter: 0
  # see roundNumericIDsToNextThousand method for an
  # explanation of why we need to keep this extra
  # count
  @lastBuiltInstanceNumericID: 0
  instanceNumericID: 0
  
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

  # for a Morph, being visible and minimised
  # are two separate things.
  # isVisible means that the morph is meant to show
  #  as empty or without any surface. For example
  #  a scrollbar "collapses" itself when there is no
  #  content to scroll and puts its isVisible = false
  # isMinimised means that the morph, whatever its
  #  content or appearance or design, is not drawn
  #  on the desktop. So a minimised or unminimised scrollbar
  #  can be independently either visible or not.
  # If we merge the two flags into one, then the
  # following happens: "hiding" a morph causes the
  # scrollbars in it to hide. Unhiding it causes the
  # scrollbars to show, even if they should be invisible.
  # Hence the need of two separate flags.
  # Also, it's semantically two
  # separate reasons of why a morph is not being
  # painted on screen, so it makes sense to have
  # two separate flags.
  isMinimised: false
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

  uniqueIDString: ->
    @morphClassString() + "#" + @instanceNumericID

  morphClassString: ->
    (@constructor.name or @constructor.toString().split(" ")[1].split("(")[0])

  @morphFromUniqueIDString: (theUniqueID) ->
    result = world.topMorphSuchThat (m) =>
      m.uniqueIDString() is theUniqueID
    if not result?
      alert "theUniqueID " + theUniqueID + " not found!"
    return result

  assignUniqueID: ->
    @constructor.instancesCounter++
    @constructor.lastBuiltInstanceNumericID++
    @instanceNumericID = @constructor.lastBuiltInstanceNumericID

  # some test commands specify morphs via
  # their uniqueIDString. This means that
  # if there is one more TextMorph anywhere during
  # the playback, for example because
  # one new menu item is added, then
  # all the subsequent IDs for the TextMorph will be off.
  # In order to sort that out, we occasionally re-align
  # the counts to the next 1000, so the next Morphs
  # being created will all be aligned and
  # minor discrepancies are ironed-out
  @roundNumericIDsToNextThousand: ->
    console.log "@roundNumericIDsToNextThousand"
    # this if is because zero and multiples of 1000
    # don't go up to 1000
    if @lastBuiltInstanceNumericID %1000 == 0
      @lastBuiltInstanceNumericID++
    @lastBuiltInstanceNumericID = 1000*Math.ceil(@lastBuiltInstanceNumericID/1000)

  constructor: ->
    super()
    @assignUniqueID()

    # [TODO] why is there this strange non-zero default bound?
    @bounds = new Rectangle(0, 0, 50, 40)
    @color = @color or new Color(80, 80, 80)
    @lastTime = Date.now()
    # Note that we don't call @updateRendering()
    # that's because the actual extending morph will probably
    # set more details of how it should look (e.g. size),
    # so we wait and we let the actual extending
    # morph to draw itself.

  
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
  #		layoutSubmorphs()
  #		
  #	method of InspectorMorph, or the
  #	
  #		startLayout()
  #		endLayout()
  #
  #	methods of SyntaxElementMorph in the Snap application.
  #
  
  
  # Morph string representation: e.g. 'a Morph#2 [20@45 | 130@250]'
  toString: ->
    firstPart = "a "

    if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.IDLE and SystemTestsRecorderAndPlayer.hidingOfMorphsNumberIDInLabels
      firstPart = firstPart + @morphClassString()
    else
      firstPart = firstPart + @uniqueIDString()

    if SystemTestsRecorderAndPlayer.state != SystemTestsRecorderAndPlayer.IDLE and SystemTestsRecorderAndPlayer.hidingOfMorphsGeometryInfoInLabels
      return firstPart
    else
      return firstPart + " " + @bounds

  # Morph string representation: e.g. 'a Morph#2'
  toStringWithoutGeometry: ->
    "a " +
      @uniqueIDString()
  
  
  # Morph deleting:
  destroy: ->
    # todo there is something to be figured out here
    # cause in theory ALL the morphs in here are not
    # visible, not just the parent... but it kind of
    # seems overkill...
    @visible = false
    if @parent?
      @fullChanged()
      @parent.removeChild @
    return null
  
  destroyAll: ->
    # we can't use forEach because we are iterating over
    # an array that changes its values (and length) while
    # we are iterating on it.
    until @children.length == 0
      @children[0].destroy()
    return null

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

  # not used within Zombie Kernel yet.
  nextSteps: (arrayOfFunctions) ->
    lst = arrayOfFunctions or []
    nxt = lst.shift()
    if nxt
      @onNextStep = =>
        nxt.call @
        @nextSteps lst  
  
  # leaving this function as step means that the morph wants to do nothing
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
      if !child.isMinimised and child.isVisible
        result = result.merge(child.boundsIncludingChildren())
    result
  
  boundsIncludingChildrenNoShadow: ->
    # answer my full bounds but ignore any shadow
    result = @bounds
    @children.forEach (child) ->
      if (child not instanceof ShadowMorph) and (!child.isMinimised) and (child.isVisible)
        result = result.merge(child.boundsIncludingChildrenNoShadow())
    result
  
  visibleBounds: ->
    # answer which part of me is not clipped by a Frame
    visible = @bounds
    frames = @allParentsTopToBottomSuchThat (p) ->
      p instanceof FrameMorph
    frames.forEach (f) ->
      visible = visible.intersect(f.bounds)
    #
    visible
  
  
  # Morph accessing - simple changes:
  moveBy: (delta) ->
    # note that changed() is called two times
    # because there are two areas of the screens
    # that are dirty: the starting
    # position and the end position.
    # Both need to be repainted.
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
  
  # the default of layoutSubmorphs
  # is to do nothing, but things like
  # the inspector might well want to
  # tweak many of theor children...
  layoutSubmorphs: ->
    null
  
  # Morph accessing - dimensional changes requiring a complete redraw
  setExtent: (aPoint) ->
    # check whether we are actually changing the extent.
    unless aPoint.eq(@extent())
      @changed()
      @silentSetExtent aPoint
      @changed()
      @updateRendering()
      @layoutSubmorphs()
  
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
  #   i.e. not the children. For example: a ColorPickerMorph is a Morph which
  #   contains three children Morphs (a color palette, a greyscale palette and
  #   a feedback). The updateRendering method of ColorPickerMorph only creates
  #   a canvas for the container Morph. So that's just a canvas with a
  #   solid color. As the
  #   ColorPickerMorph constructor runs, the three childredn Morphs will
  #   run their own updateRendering method, so each child will have its own
  #   canvas with their own contents.
  #   Note that updateRendering should be called sparingly. A morph should repaint
  #   its buffer pretty much only *after* it's been added to itf first parent and
  #   whenever it changes dimensions. Things like changing parent and updating
  #   the position shouldn't normally trigger an update of the buffer.
  #   Also note that before the buffer is painted for the first time, they
  #   might not know their extent. Typically text-related Morphs know their
  #   extensions after they painted the text for the first time...
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
    @changed()
  
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
    return null  if @isMinimised or !@isVisible or !@image?
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
    return null  if @isMinimised or !@isVisible

    # in general, the children of a Morph could be outside the
    # bounds of the parent (they could also be much larger
    # then the parent). This means that we have to traverse
    # all the children to find out whether any of those overlap
    # the clipping rectangle. Note that we can be smarter with
    # FrameMorphs, as their children are actually all contained
    # within the parent's boundary.

    # Note that if we could dynamically and cheaply keep an updated
    # boundsIncludingChildren property, then we could be smarter
    # in discarding whole sections of the scene graph.
    # (see https://github.com/davidedc/Zombie-Kernel/issues/150 )

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
  
  minimise: ->
    @isMinimised = true
    @changed()
    @children.forEach (child) ->
      child.minimise()
  
  unminimise: ->
    @isMinimised = false
    @changed()
    @children.forEach (child) ->
      child.unminimise()
  
  
  toggleVisibility: ->
    @isMinimised = (not @isMinimised)
    @changed()
    @children.forEach (child) ->
      child.toggleVisibility()
  
  
  # Morph full image:
  
  # This function is not used and is probably
  # not needed. After a couple of tweaks, the
  # "fullImage" method below seems to work well
  # in all situations, wherease before both the
  # "fullImageClassic" and "fullImage" methods
  # were needed to cover different cases.
  fullImageClassic: ->
    # why doesn't this work for all Morphs?
    fb = @boundsIncludingChildren()
    img = newCanvas(fb.extent())
    @recursivelyBlit img, fb
    img.globalAlpha = @alpha
    img

  # Fixes https://github.com/jmoenig/morphic.js/issues/7
  # and https://github.com/davidedc/Zombie-Kernel/issues/160
  fullImage: ->
    boundsIncludingChildren = @boundsIncludingChildren()
    img = newCanvas(boundsIncludingChildren.extent())
    ctx = img.getContext("2d")
    # we are going to draw this morph and its children into "img".
    # note that the children are not necessarily geometrically
    # contained in the morph (in which case it would be ok to
    # translate the context so that the origin of *this* morph is
    # at the top-left of the "img" canvas).
    # Hence we have to translate the context
    # so that the origin of the entire boundsIncludingChildren is at the
    # very top-left of the "img" canvas.
    ctx.translate -boundsIncludingChildren.origin.x , -boundsIncludingChildren.origin.y
    @recursivelyBlit img, boundsIncludingChildren
    img

  fullImageData: ->
    # returns a string like "data:image/png;base64,iVBORw0KGgoAA..."
    # note that "image/png" below could be omitted as it's
    # the default, but leaving it here for clarity.
    @fullImage().toDataURL("image/png")

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
  
  
  # shadow is added to a morph by
  # the HandMorph while dragging
  addShadow: (offset, alpha, color) ->
    shadow = new ShadowMorph(@, offset, alpha, color)
    @addBack shadow
    @fullChanged()
    shadow
  
  getShadow: ->
    return @topmostChildSuchThat (child) ->
      child instanceof ShadowMorph
  
  removeShadow: ->
    shadow = @getShadow()
    if shadow?
      @fullChanged()
      @removeChild shadow
  
  
  # Morph pen trails:
  penTrails: ->
    # answer my pen trails canvas. default is to answer my image
    # The implication is that by default every Morph in the system
    # (including the World) is able to act as turtle canvas and can
    # display pen trails.
    # BUT also this means that pen trails will be lost whenever
    # the trail's morph (the pen's parent) performs a "drawNew()"
    # operation. If you want to create your own pen trails canvas,
    # you may wish to modify its **penTrails()** property, so that
    # it keeps a separate offscreen canvas for pen trails
    # (and doesn't lose these on redraw).
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
  
  # attaches submorph ontop
  add: (aMorph) ->
    # the morph that is being
    # attached might be attached to
    # a clipping morph. So we
    # need to do a "changed" here
    # to make sure that anything that
    # is outside the clipping Morph gets
    # painted over.
    aMorph.changed()
    owner = aMorph.parent
    owner.removeChild aMorph  if owner?
    @addChild aMorph
    aMorph.updateRendering()
  
  # attaches submorph underneath
  addBack: (aMorph) ->
    owner = aMorph.parent
    owner.removeChild aMorph  if owner?
    aMorph.updateRendering()
    # this is a curious instance where
    # we first update the rendering and then
    # we add the morph. This is because
    # the rendering depends on the
    # full extent including children of
    # the morph we are attaching the shadow
    # to. So if we add the shadow we are going
    # to influence those measurements and
    # make our life very difficult for
    # ourselves.
    @addChildFirst aMorph
  

  # never currently used in ZK
  # TBD whether this is 100% correct,
  # see "morphAtPointer" implementation in
  # HandMorph.
  # Also there must be a quicker implementation
  # cause there is no need to create the entire
  # morph list. It would be sufficient to
  # navigate the structure and just return
  # at the first morph satisfying the test.
  morphAt: (aPoint) ->
    morphs = @allChildrenTopToBottom()
    result = null
    morphs.forEach (m) ->
      if m.boundsIncludingChildren().containsPoint(aPoint) and (result is null)
        result = m
    #
    result
  
  #
  #	potential alternative - solution for morphAt.
  #	Has some issues, commented out for now...
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
    allParentsTopToBottom = @allParentsTopToBottom()
    allChildrenBottomToTop = @allChildrenBottomToTop()
    morphs = world.collectAllChildrenBottomToTopSuchThat (m) =>
      !m.isMinimised and
        m.isVisible and
        m isnt @ and
        m isnt world and
        not contains(allParentsTopToBottom, m) and
        not contains(allChildrenBottomToTop, m) and
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

  # creates a new instance of target's type
  clone: (target) ->
    #alert "cloning a " + target.constructor.name
    if typeof target is "object"
      Clone = ->
      Clone:: = target
      # note that the constructor method is not run!
      theClone = new Clone()
      theClone.assignUniqueID()
      #theClone.constructor()
      return theClone
    target

  shallowCopy: (target) ->
    # answer a shallow copy of target
    c = @clone(target.constructor::)
    for property of target
      # there are a couple of properties that we don't want to copy over...
      if target.hasOwnProperty(property) and property != "instanceNumericID"
        c[property] = target[property]
        #if target.constructor.name == "SliderMorph"
        #  alert "copying property: " + property
    c
  
  copy: ->
    c = @shallowCopy(@)
    c.parent = null
    c.children = []
    c.bounds = @bounds.copy()
    c
  
  copyRecordingReferences: (dict) ->
    # copies a Morph, its properties and its submorphs. Properties
    # are shallow-copied, so for example values are actually copied,
    # but arrays are not deep-copied.
    # Also builds a correspndence of the morph and its submorphs to their
    # respective clones.

    c = @copy()
    # "dict" maps the correspondences from this object to the
    # copy one. So dict[propertyOfThisObject] = propertyOfCopyObject
    dict[@uniqueIDString()] = c
    @children.forEach (m) ->
      # the result of this loop is that all the children of this
      # object are (recursively) copied and attached to the copy of this
      # object. dict will contain all the mappings between the
      # children of this object and the copied children.
      c.add m.copyRecordingReferences(dict)
    c
  
  fullCopy: ->
    #
    #	Produce a copy of me with my entire tree of submorphs. Morphs
    #	mentioned more than once are all directed to a single new copy.
    #	Other properties are also *shallow* copied, so you must override
    #	to deep copy Arrays and (complex) Objects
    #	
    #alert "doing a full copy"
    dict = {}
    c = @copyRecordingReferences(dict)
    # note that child.updateReferences is invoked
    # from the bottom up, i.e. from the leaf children up to the
    # parents. This is important because it means that each
    # child can properly fix the connections between the "mapped"
    # children correctly.
    #alert "### updating references"
    #alert "number of children: " + c.children.length
    c.forAllChildrenBottomToTop (child) ->
      #alert ">>> updating reference of " + child
      child.updateReferences dict
    #alert ">>> updating reference of " + c
    c.updateReferences dict
    #
    c
  
  # if the constructor of the object you are copying performs
  # some complex building and connecting of the elements,
  # then you probably need to override this method. For example
  # in the inspectorMorph the constructor invokes a
  # "buildAndConnectChildren" function which attached callbacks
  # to the list so that the "detail" pane shows the content.
  # Since those connections are inside callbacks rather than
  # in properties of the inspector, those are not copied, so
  # the inspector needs to override this function so it
  # also calls buildAndConnectChildren
  updateReferences: (dict) ->
    #
    #	Update intra-morph references within a composite morph that has
    #	been copied. For example, if a button refers to morph X in the
    #	orginal composite then the copy of that button in the new composite
    #	should refer to the copy of X in new composite, not the original X.
    # This is done via scanning all the properties of the object and
    # checking whether any of those has a mapping. If so, then it is
    # replaced with its mapping.
    #	
    #alert "updateReferences of " + @toString()
    for property of @
      if @[property]?
        #if property == "button"
        #  alert "!! property: " + property + " is morph: " + (@[property]).isMorph
        #  alert "dict[property]: " + dict[(@[property]).uniqueIDString()]
        if (@[property]).isMorph and dict[(@[property]).uniqueIDString()]
          #if property == "button"
          #  alert "!! updating property: " + property + " to: " + dict[(@[property]).uniqueIDString()]
          @[property] = dict[(@[property]).uniqueIDString()]
  
  
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
  
  pickUp: ->
    @setPosition world.hand.position().subtract(@extent().floorDivideBy(2))
    world.hand.grab @
  
  isPickedUp: ->
    @parentThatIsA(HandMorph)?
  
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
      WorldMorph.preferencesAndSettings.prompterFontSize,
      WorldMorph.preferencesAndSettings.prompterFontName,
      false,
      false,
      isNumeric)
    menu.items.push entryField
    if ceilingNum or WorldMorph.preferencesAndSettings.useSliderForInput
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
      slider.setHeight WorldMorph.preferencesAndSettings.prompterSliderSize
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
    menu.popUpAtHand()
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
    menu.popUpAtHand()

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
    if @customContextMenu
      return @customContextMenu()
    world = (if @world instanceof Function then @world() else (@root() or @world))
    if world and world.isDevMode
      if @parent is world
        return @developersMenu()
      return @hierarchyMenu()
    @userMenu() or (@parent and @parent.userMenu())
  
  # When user right-clicks on a morph that is a child of other morphs,
  # then it's ambiguous which of the morphs she wants to operate on.
  # An example is right-clicking on a SpeechBubbleMorph: did she
  # mean to operate on the BubbleMorph or did she mean to operate on
  # the TextMorph contained in it?
  # This menu lets her disambiguate.
  hierarchyMenu: ->
    parents = @allParentsTopToBottom()
    world = (if @world instanceof Function then @world() else (@root() or @world))
    menu = new MenuMorph(@, null)
    # show an entry for each of the morphs in the hierarchy.
    # each entry will open the developer menu for each morph.
    parents.forEach (each) ->
      if each.developersMenu and (each isnt world)
        textLabelForMorph = each.toString().slice(0, 50)
        menu.addItem textLabelForMorph, ->
          each.developersMenu().popUpAtHand()
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
        userMenu.popUpAtHand()
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
    menu.addItem "resize...", (->@resize()), "show a handle\nwhich can be dragged\nto change this morph's" + " extent"
    menu.addLine()
    menu.addItem "duplicate", (->
      aFullCopy = @fullCopy()
      aFullCopy.pickUp()
    ), "make a copy\nand pick it up"
    menu.addItem "pick up", (->@pickUp()), "disattach and put \ninto the hand"
    menu.addItem "attach...", (->@attach()), "stick this morph\nto another one"
    menu.addItem "move", (->@move()), "show a handle\nwhich can be dragged\nto move this morph"
    menu.addItem "inspect", (->@inspect()), "open a window\non all properties"

    # A) normally, just take a picture of this morph
    # and open it in a new tab.
    # B) If a test is being recorded, then the behaviour
    # is slightly different: a system test command is
    # triggered to take a screenshot of this particular
    # morph.
    # C) If a test is being played, then the screenshot of
    # the particular morph is put in a special place
    # in the test player. The command recorded at B) is
    # going to replay but *waiting* for that screenshot
    # first.
    takePic = =>
      if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.RECORDING
        # While recording a test, just trigger for
        # the takeScreenshot command to be recorded. 
        window.world.systemTestsRecorderAndPlayer.takeScreenshot(@)
      else if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.PLAYING
        # While playing a test, this command puts the
        # screenshot of this morph in a special
        # variable of the system test runner.
        # The test runner will wait for this variable
        # to contain the morph screenshot before
        # doing the comparison as per command recorded
        # in the case above.
        window.world.systemTestsRecorderAndPlayer.imageDataOfAParticularMorph = @fullImageData()
      else
        # no system tests recording/playing ongoing,
        # just open new tab with image of morph.
        window.open @fullImageData()
    menu.addItem "take pic", takePic, "open a new window\nwith a picture of this morph"

    menu.addLine()
    if @isDraggable
      menu.addItem "lock", (->@toggleIsDraggable()), "make this morph\nunmovable"
    else
      menu.addItem "unlock", (->@toggleIsDraggable()), "make this morph\nmovable"
    menu.addItem "hide", (->@minimise())
    menu.addItem "delete", (->@destroy())
    unless @ instanceof WorldMorph
      menu.addLine()
      menu.addItem "World...", (->
        world.contextMenu().popUpAtHand()
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
    menu.popUpAtHand()  if choices.length
  
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
    @collectAllChildrenBottomToTopSuchThat (each) ->
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
