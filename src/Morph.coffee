# Morph //////////////////////////////////////////////////////////////

# A Morph (from the Greek "shape" or "form") is an interactive
# graphical object. General information on the Morphic system
# can be found at http://minnow.cc.gatech.edu/squeak/30. 

# Morphs exist in a tree, rooted at a World or at the Hand.
# The morphs owns submorphs. Morphs are drawn recursively;
# if a Morph has no owner it never gets drawn
# (but note that there are other ways to hide a Morph).

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions
# REQUIRES DeepCopierMixin

class Morph extends MorphicNode
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith DeepCopierMixin

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
  minimumExtent: null
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

  isfloatDraggable: false

  # if a morph is a "template" it means that
  # when you floatDrag it, it creates a copy of itself.
  # it's a nice shortcut instead of doing
  # right click and then "duplicate..."
  isTemplate: false
  acceptsDrops: false
  noticesTransparentClick: false
  fps: 0
  customContextMenu: null
  trackChanges: true
  shadowBlur: 10
  # note that image contains only the CURRENT morph, not the composition of this
  # morph with all of the submorphs. I.e. for an inspector, this will only
  # contain the background of the window pane. Not any of its contents.
  # for the worldMorph, this only contains the background
  image: null
  onNextStep: null # optional function to be run once. Not currently used in Zombie Kernel

  # contains all the reactive vals
  allValsInMorphByName: null
  morphValsDependingOnChildrenVals: null
  morphValsDirectlyDependingOnParentVals: null

  clickOutsideMeOrAnyOfMeChildrenCallback: [null]
  isMarkedForDestruction: false

  textDescription: null


  mouseClickRight: ->
    world.hand.openContextMenuAtPointer @

  getTextDescription: ->
    if @textDescription?
      return @textDescription + "" + @constructor.name + " (adhoc description of morph)"
    else
      return @constructor.name + " (class name)"

  identifyViaTextLabel: ->
    myTextDescription = @getTextDescription()
    allCandidateMorphsWithSameTextDescription = 
      world.allChildrenTopToBottomSuchThat( (m) ->
        m.getTextDescription() == myTextDescription
      )
    position = allCandidateMorphsWithSameTextDescription.indexOf @

    theLenght = allCandidateMorphsWithSameTextDescription.length
    console.log [myTextDescription, position, theLenght]
    return [myTextDescription, position, theLenght]

  setTextDescription: (@textDescription) ->


  ##
  # Reactive Values start
  ##

  markForDestruction: ->
    world.markedForDestruction.push @
    @isMarkedForDestruction = true

  anyParentMarkedForDestruction: ->
    if @isMarkedForDestruction
      return true
    else if @parent?
      return @parent.anyParentMarkedForDestruction() 
    return false


  ###
  connectValuesToAddedChild: (theChild) ->
    #if theChild.constructor.name == "RectangleMorph"
    #  debugger

    # we have a data structure that contains,
    # for each child valName, all vals of this
    # morph that depend on it. Go through
    # all child val names, find the
    # actual val in the child, and connect all
    # to the vals in this morph that depend on it.
    for nameOfChildrenVar, morphValsDependingOnChildrenVals of \
        @morphValsDependingOnChildrenVals
      childVal = theChild.allValsInMorphByName[ nameOfChildrenVar ]
      if childVal?
        for valNameNotUsed, valDependingOnChildrenVal of morphValsDependingOnChildrenVals
          valDependingOnChildrenVal.args.connectToChildVal valDependingOnChildrenVal, childVal

    # we have a data structure that contains,
    # for each parent (me) valName, all vals of the child
    # morph that depend on it. Go through
    # all parent (me) val names, find the
    # actual val in the parent (me), and connect it
    # to the vals in the child morph that depend on it.
    for nameOfParentVar, morphValsDirectlyDependingOnParentVals of \
        theChild.morphValsDirectlyDependingOnParentVals
      parentVal = @allValsInMorphByName[ nameOfParentVar ]
      if parentVal?
        for valNameNotUsed, valDependingOnParentVal of morphValsDirectlyDependingOnParentVals
          valDependingOnParentVal.args.connectToParentVal valDependingOnParentVal, parentVal

  disconnectValuesFromRemovedChild: (theChild) ->
    # we have a data structure that contains,
    # for each child valName, all vals of this
    # morph that depend on it. Go through
    # all child val names, find the
    # actual val in the child, and DISconnect it
    # FROM the vals in this morph that depended on it.
    for nameOfChildrenVar, morphValsDependingOnChildrenVals of \
        @morphValsDependingOnChildrenVals
      for valNameNotUsed, valDependingOnChildrenVal of morphValsDependingOnChildrenVals
        childArg = valDependingOnChildrenVal.args.argById[theChild.id]
        if childArg?
          childArg.disconnectChildArg()

    # we have a data structure that contains,
    # for each parent (me) valName, all vals of the child
    # morph that depend on it. Go through
    # all parent (me) val names, find the
    # actual val in the parent (me), and connect it
    # to the vals in the child morph that depend on it.
    for nameOfParentVar, morphValsDirectlyDependingOnParentVals of \
        theChild.morphValsDirectlyDependingOnParentVals
      for valNameNotUsed, valDependingOnParentVal of morphValsDirectlyDependingOnParentVals
        parentArg = valDependingOnParentVal.args.parentArgByName[ nameOfParentVar ]
        if parentArg?
          parentArg.disconnectParentArg()
  ###


  ## ------------ end of reactive values ----------------------

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

    if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
      arr = window.world.systemTestsRecorderAndPlayer.tagsCollectedWhileRecordingTest
      if (arr.indexOf @constructor.name) == -1
        arr.push @constructor.name

    # [TODO] why is there this strange non-zero default bound?
    @bounds = new Rectangle(0, 0, 50, 40)
    @minimumExtent = new Point 5,5
    @color = @color or new Color(80, 80, 80)
    @lastTime = Date.now()
    # Note that we don't call @updateBackingStore()
    # that's because the actual extending morph will probably
    # set more details of how it should look (e.g. size),
    # so we wait and we let the actual extending
    # morph to draw itself.

    @allValsInMorphByName = {}
    @morphValsDependingOnChildrenVals = {}
    @morphValsDirectlyDependingOnParentVals = {}


  
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

    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.hidingOfMorphsNumberIDInLabels
      firstPart = firstPart + @morphClassString()
    else
      firstPart = firstPart + @uniqueIDString()

    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.hidingOfMorphsGeometryInfoInLabels
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

    # remove callback when user clicks outside
    # me or any of my children
    console.log "****** destroying morph"
    @onClickOutsideMeOrAnyOfMyChildren null

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
        if !child.runChildrensStepFunction?
          debugger
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


  # used for example:
  # - to determine which morphs you can attach a morph to
  # - for a SliderMorph's "set target" so you can change properties of another Morph
  # - by the HandleMorph when you attach it to some other morph
  # Note that this method has a slightly different
  # version in FrameMorph (because it clips, so we need
  # to check that we don't consider overlaps with
  # morphs contained in a frame that are clipped and
  # hence *actually* not overlapping).
  plausibleTargetAndDestinationMorphs: (theMorph) ->
    # find if I intersect theMorph,
    # then check my children recursively
    # exclude me if I'm a child of theMorph
    # (cause it's usually odd to attach a Morph
    # to one of its submorphs or for it to
    # control the properties of one of its submorphs)
    result = []
    if !@isMinimised and
        @isVisible and
        !theMorph.containedInParentsOf(@) and
        @bounds.intersects(theMorph.bounds) and
        !@anyParentMarkedForDestruction()
      result = [@]

    @children.forEach (child) ->
      result = result.concat(child.plausibleTargetAndDestinationMorphs(theMorph))

    return result

  ###
  mergedBoundsOfChildren: ->
    result = new Rectangle(0,0)
    @children.forEach (child) ->
      if !child.isMinimised and child.isVisible
        result = result.merge(child.boundsIncludingChildren())
    result
  ###

  
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
    if @ == Window
      debugger
    visible = @bounds
    frames = @allParentsTopToBottomSuchThat (p) ->
      p instanceof FrameMorph
    frames.forEach (f) ->
      visible = visible.intersect(f.bounds)

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

    @changed()
  
  silentMoveBy: (delta) ->
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.silentMoveBy delta
  
  
  setPosition: (aPoint) ->
    aPoint.debugIfFloats()
    delta = aPoint.subtract(@topLeft())
    @moveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
    @bounds.debugIfFloats()
  
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
  # tweak many of their children...
  layoutSubmorphs: ->
  

  # do nothing in most cases but for example for
  # layouts, if something inside a layout wants to
  # change extent, then the whole layout might need to
  # change extent.
  childChangedExtent: (theMorphChangingTheExtent) ->

  # more complex Morphs, e.g. layouts, might
  # do a more complex calculation to get the
  # minimum extent
  getMinimumExtent: ->
    @minimumExtent

  setMinimumExtent: (@minimumExtent) ->

  # Morph accessing - dimensional changes requiring a complete redraw
  setExtent: (aPoint) ->
    # check whether we are actually changing the extent.
    unless aPoint.eq(@extent())
      @changed()
      minExtent = @getMinimumExtent()
      if ! aPoint.ge minExtent
        aPoint = aPoint.max minExtent
      @silentSetExtent aPoint
      @changed()
      @setLayoutBeforeUpdatingBackingStore()
      @updateBackingStore()
      @layoutSubmorphs()
      if @parent?
        @parent.childChangedExtent(@)
  
  silentSetExtent: (aPoint) ->
    ext = aPoint.round()
    newWidth = Math.max(ext.x, 0)
    newHeight = Math.max(ext.y, 0)
    @bounds.corner = new Point(@bounds.origin.x + newWidth, @bounds.origin.y + newHeight)
  
  setWidth: (width) ->
    @setExtent new Point(width or 0, @height())
  
  silentSetWidth: (width) ->
    # do not updateBackingStore() just yet
    w = Math.max(Math.round(width or 0), 0)
    @bounds.corner = new Point(@bounds.origin.x + w, @bounds.corner.y)
  
  setHeight: (height) ->
    @setExtent new Point(@width(), height or 0)
  
  silentSetHeight: (height) ->
    # do not updateBackingStore() just yet
    h = Math.max(Math.round(height or 0), 0)
    @bounds.corner = new Point(@bounds.corner.x, @bounds.origin.y + h)
  
  setColor: (aColorOrAMorphGivingAColor, morphGivingColor) ->
    if morphGivingColor?.getColor?
      aColor = morphGivingColor.getColor()
    else
      aColor = aColorOrAMorphGivingAColor
    if aColor
      unless @color.eq(aColor)
        @color = aColor
        @changed()
        @updateBackingStore()
    return aColor
  
  
  # Morph displaying ---------------------------------------------------------

  # There are three fundamental methods for rendering and displaying anything.
  # * updateBackingStore: this one creates/updates the local canvas of this morph only
  #   i.e. not the children. For example: a ColorPickerMorph is a Morph which
  #   contains three children Morphs (a color palette, a greyscale palette and
  #   a feedback). The updateBackingStore method of ColorPickerMorph only creates
  #   a canvas for the container Morph. So that's just a canvas with a
  #   solid color. As the
  #   ColorPickerMorph constructor runs, the three childredn Morphs will
  #   run their own updateBackingStore method, so each child will have its own
  #   canvas with their own contents.
  #   Note that updateBackingStore should be called sparingly. A morph should repaint
  #   its buffer pretty much only *after* it's been added to its first parent and
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

  # this is normally invoked form setExtent
  # and setExtent also invokes layoutSubmorphs
  # afterwards
  # no changes of position or extent
  updateBackingStore: ->
    @changed()
    @silentUpdateBackingStore()
    # to do you might be smarter here and ask the silentUpdateBackingStore
    # method whether a) there was any change at all and b) whether only
    # the buffer changed and not the bounds (in which case only one changed()
    # is needed)
    @changed()

  
  drawTexture: (url) ->
    @cachedTexture = new Image()
    @cachedTexture.onload = =>
      @drawCachedTexture()

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
  
  
  isTransparentAt: ->
    return false
  
  silentUpdateBackingStore: ->
    #console.log 'frame morph doing nothing with the backing store'

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by recursivelyBlit, which
  # eventually invokes blit.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  blit: (aCanvas, clippingRectangle) ->
    return null  if @isMinimised or !@isVisible
    area = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if area.isNotEmpty()
      delta = @position().neg()
      src = area.copy().translateBy(delta).round()
      context = aCanvas.getContext("2d")
      context.globalAlpha = @alpha
      sl = src.left() * pixelRatio
      st = src.top() * pixelRatio
      al = area.left() * pixelRatio
      at = area.top() * pixelRatio
      w = Math.min(src.width() * pixelRatio, @width() * pixelRatio - sl)
      h = Math.min(src.height() * pixelRatio, @height() * pixelRatio - st)
      return null  if w < 1 or h < 1

      # initialize my surface property
      #@image = newCanvas(@extent().scaleBy pixelRatio)
      #context = @image.getContext("2d")
      #context.scale pixelRatio, pixelRatio
      context.save()
      if !@color?
        debugger
      context.fillStyle = @color.toString()
      context.fillRect  Math.round(al),
          Math.round(at),
          Math.round(w),
          Math.round(h)
      context.restore()

      if world.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)

        context.save()
        context.globalAlpha = 0.5
        context.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        context.fillRect  Math.round(al),
            Math.round(at),
            Math.round(w),
            Math.round(h)
        context.restore()
  
  
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
  
  # Fixes https://github.com/jmoenig/morphic.js/issues/7
  # and https://github.com/davidedc/Zombie-Kernel/issues/160
  fullImage: (bounds) ->
    if !bounds?
      bounds = @boundsIncludingChildren()

    img = newCanvas(bounds.extent().scaleBy pixelRatio)
    ctx = img.getContext("2d")
    # ctx.scale pixelRatio, pixelRatio
    # we are going to draw this morph and its children into "img".
    # note that the children are not necessarily geometrically
    # contained in the morph (in which case it would be ok to
    # translate the context so that the origin of *this* morph is
    # at the top-left of the "img" canvas).
    # Hence we have to translate the context
    # so that the origin of the entire bounds is at the
    # very top-left of the "img" canvas.
    ctx.translate -bounds.origin.x * pixelRatio , -bounds.origin.y * pixelRatio
    @recursivelyBlit img, bounds
    img

  fullImageNoShadow: ->
    boundsWithNoShadow = @boundsIncludingChildrenNoShadow()
    return @fullImage(boundsWithNoShadow)

  fullImageData: ->
    # returns a string like "data:image/png;base64,iVBORw0KGgoAA..."
    # note that "image/png" below could be omitted as it's
    # the default, but leaving it here for clarity.
    @fullImage().toDataURL("image/png")

  # the way we take a picture here is different
  # than the way we usually take a picture.
  # Usually we ask the morph and submorphs to
  # paint themselves anew into a new canvas.
  # This is different: we take the area of the
  # screen *as it is* and we crop the part of
  # interest where the extent of our selected
  # morph is. This means that the morph might
  # be occluded by other things.
  # The advantage here is that we capture
  # the screen absolutely as is, without
  # causing any repaints. If streaks are on the
  # screen due to bad painting, we capture them
  # exactly as the user sees them.
  asItAppearsOnScreen: ->
    fullExtentOfMorph = @boundsIncludingChildren()
    destCanvas = newCanvas fullExtentOfMorph.extent().scaleBy pixelRatio
    destCtx = destCanvas.getContext '2d'
    destCtx.drawImage world.worldCanvas,
      fullExtentOfMorph.topLeft().x * pixelRatio,
      fullExtentOfMorph.topLeft().y * pixelRatio,
      fullExtentOfMorph.width() * pixelRatio,
      fullExtentOfMorph.height() * pixelRatio,
      0,
      0,
      fullExtentOfMorph.width() * pixelRatio,
      fullExtentOfMorph.height() * pixelRatio

    return destCanvas.toDataURL "image/png"

  fullImageHashCode: ->
    return hashCode(@fullImageData())
  
  # Morph shadow:
  shadowImage: (off_, color) ->
    # fallback for Windows Chrome-Shadow bug
    offset = off_ or new Point(7, 7)
    clr = color or new Color(0, 0, 0)
    fb = @boundsIncludingChildrenNoShadow().extent()
    img = @fullImage()
    outline = newCanvas(fb.scaleBy pixelRatio)
    ctx = outline.getContext("2d")
    #ctx.scale pixelRatio, pixelRatio
    ctx.drawImage img, 0, 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, Math.round(-offset.x * pixelRatio), Math.round(-offset.y * pixelRatio)
    sha = newCanvas(fb.scaleBy pixelRatio)
    ctx = sha.getContext("2d")
    #ctx.scale pixelRatio, pixelRatio
    ctx.drawImage outline, 0, 0
    ctx.globalCompositeOperation = "source-atop"
    ctx.fillStyle = clr.toString()
    ctx.fillRect 0, 0, fb.x * pixelRatio, fb.y * pixelRatio
    sha
  
  # the one used right now
  shadowImageBlurred: (off_, color) ->
    offset = off_ or new Point(7, 7)
    blur = @shadowBlur
    clr = color or new Color(0, 0, 0)
    fb = @boundsIncludingChildrenNoShadow().extent().add(blur * 2)
    img = @fullImageNoShadow()
    sha = newCanvas(fb.scaleBy pixelRatio)
    ctx = sha.getContext("2d")
    #ctx.scale pixelRatio, pixelRatio
    ctx.shadowOffsetX = offset.x * pixelRatio
    ctx.shadowOffsetY = offset.y * pixelRatio
    ctx.shadowBlur = blur * pixelRatio
    ctx.shadowColor = clr.toString()
    ctx.drawImage img, Math.round((blur - offset.x)*pixelRatio), Math.round((blur - offset.y)*pixelRatio)
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    ctx.shadowBlur = 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, Math.round((blur - offset.x)*pixelRatio), Math.round((blur - offset.y)*pixelRatio)
    sha
  
  
  # shadow is added to a morph by
  # the HandMorph while floatDragging
  addShadow: (offset, alpha, color) ->
    shadow = @silentAddShadow offset, alpha, color
    shadow.setLayoutBeforeUpdatingBackingStore()
    shadow.updateBackingStore()
    @fullChanged()
    shadow

  silentAddShadow: (offset, alpha, color) ->
    shadow = new ShadowMorph(@, offset, alpha, color)
    @addChildFirst shadow
    shadow
  
  getShadow: ->
    return @topmostChildSuchThat (child) ->
      child instanceof ShadowMorph
  
  removeShadow: ->
    shadow = @getShadow()
    if shadow?
      @fullChanged()
      @removeChild shadow
  
  
  
  # Morph updating ///////////////////////////////////////////////////////////////
  changed: ->
    if @trackChanges
      w = @root()
      # unless we are the main desktop, then if the morph has no parent
      # don't add the broken rect since the morph is not visible
      # also check whether we are attached to the hand cause that still counts
      # TODO this has to be made simpler and has to take into account
      # visibility as well?
      if (w instanceof HandMorph) or (w instanceof WorldMorph and ((@ instanceof WorldMorph or @parent?)))
        if (w instanceof HandMorph)
          w = w.world
          boundsToBeChanged = @boundsIncludingChildren().spread()
        else
          # @visibleBounds() should be smaller area
          # and cheaper to calculate than @boundsIncludingChildren()
          # cause it doesn't traverse the children and clips
          # the area based on the clipping morphs up the
          # hierarchy
          boundsToBeChanged = @visibleBounds().spread()

        w.broken.push boundsToBeChanged

    @parent.childChanged @  if @parent
  
  fullChanged: ->
    if @trackChanges
      w = @root()
      # unless we are the main desktop, then if the morph has no parent
      # don't add the broken rect since the morph is not visible
      # also check whether we are attached to the hand cause that still counts
      # TODO this has to be made simpler and has to take into account
      # visibility as well?
      if (w instanceof HandMorph) or (w instanceof WorldMorph and ((@ instanceof WorldMorph or @parent?)))
        if (w instanceof HandMorph)
          w = w.world

        w.broken.push @boundsIncludingChildren().spread()
  
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

  imBeingAddedTo: (newParentMorph) ->
    @setLayoutBeforeUpdatingBackingStore()
    @updateBackingStore()
  
  # attaches submorph on top
  # ??? TODO you should handle the case of Morph
  #     being added to itself and the case of
  # ??? TODO a Morph being added to one of its
  #     children
  add: (aMorph) ->
    # the morph that is being
    # attached might be attached to
    # a clipping morph. So we
    # need to do a "changed" here
    # to make sure that anything that
    # is outside the clipping Morph gets
    # painted over.
    if aMorph.parent?
      aMorph.changed()
    @silentAdd(aMorph, true)
    aMorph.imBeingAddedTo @

  # this is done before the updating of the
  # backing store in some morphs that
  # need to figure out their whole
  # layout before painting themselves
  # e.g. the MenuMorph
  setLayoutBeforeUpdatingBackingStore: ->


  calculateAndUpdateExtent: ->

  silentAdd: (aMorph, avoidExtentCalculation) ->
    # the morph that is being
    # attached might be attached to
    # a clipping morph. So we
    # need to do a "changed" here
    # to make sure that anything that
    # is outside the clipping Morph gets
    # painted over.
    owner = aMorph.parent
    owner.removeChild aMorph  if owner?
    aMorph.isMarkedForDestruction = false
    @addChild aMorph
    if !avoidExtentCalculation
      aMorph.calculateAndUpdateExtent()
  
  

  # never currently used in ZK
  # TBD whether this is 100% correct,
  # see "topMorphUnderPointer" implementation in
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

    result
  
  #
  #	potential alternative - solution for morphAt.
  #	Has some issues, commented out for now...
  #
  #Morph::morphAt = function (aPoint) {
  #	return this.topMorphSuchThat(function (m) {
  #		return m.boundsIncludingChildren().containsPoint(aPoint);
  #	});
  #};
  #
  
  # Morph pixel access:
  getPixelColor: (aPoint) ->
    point = aPoint.subtract(@bounds.origin)
    context = @image.getContext("2d")
    data = context.getImageData(point.x * pixelRatio, point.y * pixelRatio, 1, 1)
    new Color(data.data[0], data.data[1], data.data[2], data.data[3])
  
  

  # Duplication and Serialization /////////////////////////////////////////


  ### not currently used
  completelyRepaint: ()->
    allMorphsInStructure = @allChildrenBottomToTop()
    for eachMorph in allMorphsInStructure
      if eachMorph.updateBackingStore?
        eachMorph.updateBackingStore()
        eachMorph.changed()
  ###

  duplicateMenuAction: ->
    aFullCopy = @fullCopy()
    aFullCopy.pickUp()

  fullCopy: ()->
    allMorphsInStructure = @allChildrenBottomToTop()
    copiedMorph = @deepCopy false, [], [], allMorphsInStructure
    if copiedMorph instanceof MenuMorph
      copiedMorph.onClickOutsideMeOrAnyOfMyChildren(null)
      copiedMorph.killThisMenuIfClickOnDescendantsTriggers = false
      copiedMorph.killThisMenuIfClickOutsideDescendants = false

    return copiedMorph

  serialize: ()->
    allMorphsInStructure = @allChildrenBottomToTop()
    arr1 = []
    arr2 = []
    @deepCopy true, arr1, arr2, allMorphsInStructure
    totalJSON = ""

    for element in arr2
      try
        console.log JSON.stringify(element) + "\n// --------------------------- \n"
      catch e
        debugger

      totalJSON = totalJSON + JSON.stringify(element) + "\n// --------------------------- \n"
    return totalJSON


  # Deserialization /////////////////////////////////////////


  deserialize: (serializationString) ->
    # this is to ignore all the comment strings
    # that might be there for reading purposes
    objectsSerializations = serializationString.split(/^\/\/.*$/gm)
    # the serialization ends with a comment so
    # last element is empty, pop it
    objectsSerializations.pop()

    createdObjects = []
    for eachSerialization in objectsSerializations
      createdObjects.push JSON.parse eachSerialization

    clonedMorphs = []
    for eachObject in createdObjects
      # note that the constructor method is not run!
      #console.log "cloning:" + eachMorph.className
      #console.log "with:" + namedClasses[eachMorph.className]
      if eachObject.className == "Canvas"
        theClone = newCanvas new Point eachObject.width, eachObject.height
        ctx = theClone.getContext("2d");

        image = new Image();
        image.src = eachObject.data
        # if something doesn't get painted here,
        # it might be because the allocation of the image
        # would actually be asynchronous, in theory
        # you'd have to do the drawImage in a callback
        # on onLoad of the image...
        ctx.drawImage(image, 0, 0)

      else if eachObject.constructor != Array
        theClone = Object.create(namedClasses[eachObject.className])
        if theClone.assignUniqueID?
          theClone.assignUniqueID()
      else
        theClone = []
      clonedMorphs.push theClone
      #theClone.constructor()

    for i in [0... clonedMorphs.length]
      eachClonedMorph = clonedMorphs[i]
      if eachClonedMorph.constructor == HTMLCanvasElement
        # do nothing
      else if eachClonedMorph.constructor != Array
        for property of createdObjects[i]
          # also includes the "parent" property
          if createdObjects[i].hasOwnProperty property
            console.log "looking at property: " + property
            clonedMorphs[i][property] = createdObjects[i][property]
            if typeof clonedMorphs[i][property] is "string"
              if (clonedMorphs[i][property].indexOf "$") == 0
                referenceNumberAsString = clonedMorphs[i][property].substring(1)
                referenceNumber = parseInt referenceNumberAsString
                clonedMorphs[i][property] = clonedMorphs[referenceNumber]
      else
        for j in [0... createdObjects[i].length]
          eachArrayElement = createdObjects[i][j]
          clonedMorphs[i][j] = createdObjects[i][j]
          if typeof eachArrayElement is "string"
            if (eachArrayElement.indexOf "$") == 0
              referenceNumberAsString = eachArrayElement.substring(1)
              referenceNumber = parseInt referenceNumberAsString
              clonedMorphs[i][j] = clonedMorphs[referenceNumber]


    return clonedMorphs[0]

  
  # Morph floatDragging and dropping /////////////////////////////////////////
  
  rootForGrab: ->
    if @ instanceof ShadowMorph
      return @parent.rootForGrab()
    if @parent instanceof ScrollFrameMorph
      return @parent
    if @parent is null or
      @parent instanceof WorldMorph or
      @parent instanceof FrameMorph or
      @isfloatDraggable is true
        return @  
    @parent.rootForGrab()

  firstContainerMenu: ->
    scanningMorphs = @
    while scanningMorphs.parent?
      scanningMorphs = scanningMorphs.parent
      if scanningMorphs instanceof MenuMorph
        if !scanningMorphs.isMarkedForDestruction
          return scanningMorphs
    return scanningMorphs

    if @ instanceof ShadowMorph
      return @parent.rootForFocus()
    if @parent is null or
      @parent instanceof WorldMorph
        return @  
    @parent.rootForFocus()

  rootForFocus: ->
    if @ instanceof ShadowMorph
      return @parent.rootForFocus()
    if @parent is null or
      @parent instanceof WorldMorph
        return @  
    @parent.rootForFocus()

  bringToForegroud: ->
    @rootForFocus()?.moveAsLastChild()
    @rootForFocus()?.fullChanged()

  propagateKillMenus: ->
    if @parent?
      @parent.propagateKillMenus()

  mouseClickLeft: ->
    @bringToForegroud()

  onClickOutsideMeOrAnyOfMyChildren: (functionName, arg1, arg2, arg3)->
    if functionName?
      @clickOutsideMeOrAnyOfMeChildrenCallback = [functionName, arg1, arg2, arg3]
      if (world.morphsDetectingClickOutsideMeOrAnyOfMeChildren.indexOf @) < 0
        world.morphsDetectingClickOutsideMeOrAnyOfMeChildren.push @
    else
      console.log "****** onClickOutsideMeOrAnyOfMyChildren removing element"
      index = world.morphsDetectingClickOutsideMeOrAnyOfMeChildren.indexOf @
      if index >= 0
        world.morphsDetectingClickOutsideMeOrAnyOfMeChildren.splice index, 1

  wantsDropOf: (aMorph) ->
    # default is to answer the general flag - change for my heirs
    if (aMorph instanceof HandleMorph) or
      (aMorph instanceof MenuMorph)
        return false  
    @acceptsDrops
  
  pickUp: ->
    world.hand.grab @
    @setPosition world.hand.position().subtract(@boundsIncludingChildrenNoShadow().extent().floorDivideBy(2))
  
  # note how this verified that
  # at *any point* up in the
  # morphs hierarchy there is a HandMorph
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
    @world().activeHandle = new HandleMorph(@, "move")
  
  hint: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph(false, @, true, true, text)
    m.isfloatDraggable = true
    m.popUpCenteredAtHand @world()
  
  inform: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph(false, @, true, true, text)
    m.addItem "Ok"
    m.isfloatDraggable = true
    m.popUpCenteredAtHand @world()

  prompt: (msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded) ->
    isNumeric = true  if ceilingNum
    tempPromptEntryField = new StringFieldMorph(
      defaultContents or "",
      width or 100,
      WorldMorph.preferencesAndSettings.prompterFontSize,
      WorldMorph.preferencesAndSettings.prompterFontName,
      false,
      false,
      isNumeric)
    menu = new MenuMorph(false, target, true, true, msg or "", tempPromptEntryField)
    menu.tempPromptEntryField = tempPromptEntryField
    menu.items.push tempPromptEntryField
    if ceilingNum or WorldMorph.preferencesAndSettings.useSliderForInput
      slider = new SliderMorph(
        floorNum or 0,
        ceilingNum,
        parseFloat(defaultContents),
        Math.floor((ceilingNum - floorNum) / 4),
        "horizontal")
      slider.alpha = 1
      slider.color = new Color(225, 225, 225)
      slider.button.color = new Color 60,60,60
      slider.button.highlightColor = slider.button.color.copy()
      slider.button.highlightColor.b += 100
      slider.button.pressColor = slider.button.color.copy()
      slider.button.pressColor.b += 150
      slider.silentSetHeight WorldMorph.preferencesAndSettings.prompterSliderSize
      slider.target = @
      slider.argumentToAction = menu
      if isRounded
        slider.action = "reactToSliderAction1"
      else
        slider.action = "reactToSliderAction2"
      menu.items.push slider
    menu.addLine 2
    menu.addItem "Ok", true, target, callback

    menu.addItem "Cancel", true, @, ->
      null

    menu.isfloatDraggable = true
    menu.popUpAtHand(@firstContainerMenu())
    tempPromptEntryField.text.edit()

  reactToSliderAction1: (num, theMenu) ->
    theMenu.tempPromptEntryField.changed()
    theMenu.tempPromptEntryField.text.text = Math.round(num).toString()
    theMenu.tempPromptEntryField.text.setLayoutBeforeUpdatingBackingStore()
    theMenu.tempPromptEntryField.text.updateBackingStore()
    theMenu.tempPromptEntryField.text.changed()
    theMenu.tempPromptEntryField.text.edit()

  reactToSliderAction2: (num, theMenu) ->
    theMenu.tempPromptEntryField.changed()
    theMenu.tempPromptEntryField.text.text = num.toString()
    theMenu.tempPromptEntryField.text.setLayoutBeforeUpdatingBackingStore()
    theMenu.tempPromptEntryField.text.updateBackingStore()
    theMenu.tempPromptEntryField.text.changed()
  
  pickColor: (msg, callback, defaultContents) ->
    colorPicker = new ColorPickerMorph(defaultContents)
    menu = new MenuMorph(false, @, true, true, msg or "", colorPicker)
    menu.items.push colorPicker
    menu.addLine 2
    menu.addItem "Ok", true, @, callback

    menu.addItem "Cancel", true, @, ->
      null

    menu.isfloatDraggable = true
    menu.popUpAtHand(@firstContainerMenu())

  inspect: (anotherObject) ->
    @spawnInspector @

  spawnInspector: (inspectee) ->
    inspector = new InspectorMorph(inspectee)
    world = (if @world instanceof Function then @world() else (@root() or @world))
    inspector.setPosition world.hand.position()
    inspector.keepWithin world
    world.add inspector
    inspector.changed()
    
  
  # Morph menus ////////////////////////////////////////////////////////////////
  
  contextMenu: ->
    # Spacial multiplexing
    # (search "multiplexing" for the other parts of
    # code where this matters)
    # There are two interpretations of what this
    # list should be:
    #   1) all morphs "pierced through" by the pointer
    #   2) all morphs parents of the topmost morph under the pointer
    # 2 is what is used in Cuis
    
    # commented-out addendum for the implementation of 1):
    #show the normal menu in case there is text selected,
    #otherwise show the spacial multiplexing list
    #if !@world().caret
    #  if @world().hand.allMorphsAtPointer().length > 2
    #    return @hierarchyMenu()
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
    # Spacial multiplexing
    # (search "multiplexing" for the other parts of
    # code where this matters)
    # There are two interpretations of what this
    # list should be:
    #   1) all morphs "pierced through" by the pointer
    #   2) all morphs parents of the topmost morph under the pointer
    # 2 is what is used in Cuis
    # commented-out addendum for the implementation of 1):
    # parents = @world().hand.allMorphsAtPointer().reverse()
    parents = @allParentsTopToBottom()
    world = (if @world instanceof Function then @world() else (@root() or @world))
    menu = new MenuMorph(false, @, true, true, null)
    # show an entry for each of the morphs in the hierarchy.
    # each entry will open the developer menu for each morph.
    parents.forEach (each) ->
      if (each.developersMenu) and (each isnt world) and (!each.anyParentMarkedForDestruction())
        textLabelForMorph = each.toString().slice(0, 50)
        menu.addItem textLabelForMorph + " ➜", false, each, "popupDeveloperMenu"

    menu

  popupDeveloperMenu: (morphTriggeringThis)->
    @developersMenu().popUpAtHand(morphTriggeringThis.firstContainerMenu())


  popUpColorSetter: ->
    @pickColor "color:", "setColor", "color"

  transparencyPopout: (menuItem)->
    @prompt menuItem.parent.title + "\nalpha\nvalue:",
      @,
      "setAlphaScaled",
      (@alpha * 100).toString(),
      null,
      1,
      100,
      true

  testMenu: (ignored,targetMorph)->
    menu = new MenuMorph(false, targetMorph, true, true, null)
    menu.addItem "serialise morph to memory", true, targetMorph, "serialiseToMemory"
    menu.addItem "deserialize from memory and attach to world", true, targetMorph, "deserialiseFromMemoryAndAttachToWorld"
    menu.addItem "deserialize from memory and attach to hand", true, targetMorph, "deserialiseFromMemoryAndAttachToHand"
    menu.popUpAtHand(@firstContainerMenu())

  serialiseToMemory: ->
    world.lastSerializationString = @serialize()

  deserialiseFromMemoryAndAttachToHand: ->
    derezzedObject = world.deserialize world.lastSerializationString
    derezzedObject.pickUp()

  deserialiseFromMemoryAndAttachToWorld: ->
    derezzedObject = world.deserialize world.lastSerializationString
    world.add derezzedObject

  developersMenu: ->
    # 'name' is not an official property of a function, hence:
    userMenu = @userMenu() or (@parent and @parent.userMenu())
    menu = new MenuMorph(false, 
      @,
      true,
      true,
      @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    if userMenu
      menu.addItem "user features...", true, @, ->
        userMenu.popUpAtHand(@firstContainerMenu())

      menu.addLine()
    menu.addItem "color...", true, @, "popUpColorSetter" , "choose another color \nfor this morph"

    menu.addItem "transparency...", true, @, "transparencyPopout", "set this morph's\nalpha value"
    menu.addItem "resize...", true, @, "resize", "show a handle\nwhich can be floatDragged\nto change this morph's" + " extent"
    menu.addLine()
    menu.addItem "duplicate", true, @, "duplicateMenuAction" , "make a copy\nand pick it up"
    menu.addItem "pick up", true, @, "pickUp", "disattach and put \ninto the hand"
    menu.addItem "attach...", true, @, "attach", "stick this morph\nto another one"
    menu.addItem "move", true, @, "move", "show a handle\nwhich can be floatDragged\nto move this morph"
    menu.addItem "inspect", true, @, "inspect", "open a window\non all properties"

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
      if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
        # While recording a test, just trigger for
        # the takeScreenshot command to be recorded. 
        window.world.systemTestsRecorderAndPlayer.takeScreenshot(@)
      else if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
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
    menu.addItem "take pic", true, @, "takePic", "open a new window\nwith a picture of this morph"

    menu.addItem "test menu ➜", false, @, "testMenu", "debugging and testing operations"

    menu.addLine()
    if @isfloatDraggable
      menu.addItem "lock", true, @, "toggleIsfloatDraggable", "make this morph\nunmovable"
    else
      menu.addItem "unlock", true, @, "toggleIsfloatDraggable", "make this morph\nmovable"
    menu.addItem "hide", true, @, "minimise"
    menu.addItem "delete", true, @, "destroy"
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

  setAlphaScaled: (alphaOrMorphGivingAlpha, morphGivingAlpha) ->
    if morphGivingAlpha?.getValue?
      alpha = morphGivingAlpha.getValue()
    else
      alpha = alphaOrMorphGivingAlpha

    if alpha
      @alpha = @calculateAlphaScaled(alpha)
      @changed()
  
  newParentChoice: (ignored, theMorphToBeAttached) ->
    # this is what happens when "each" is
    # selected: we attach the selected morph
    @add theMorphToBeAttached
    if @ instanceof ScrollFrameMorph
      @adjustContentsBounds()
      @adjustScrollBars()
    else
      # you expect Morphs attached
      # inside a FrameMorph
      # to be floatDraggable out of it
      # (as opposed to the content of a ScrollFrameMorph)
      theMorphToBeAttached.isfloatDraggable = false

  attach: ->
    choices = world.plausibleTargetAndDestinationMorphs(@)

    # my direct parent might be in the
    # options which is silly, leave that one out
    choicesExcludingParent = []
    choices.forEach (each) =>
      if each != @parent
        choicesExcludingParent.push each

    if choicesExcludingParent.length > 0
      menu = new MenuMorph(false, @, true, true, "choose new parent:")
      choicesExcludingParent.forEach (each) =>
        menu.addItem each.toString().slice(0, 50), true, each, "newParentChoice"
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible morphs to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # morphs then show some kind of message.
      menu = new MenuMorph(false, @, true, true, "no morphs to attach to")
    menu.popUpAtHand(@firstContainerMenu())
  
  toggleIsfloatDraggable: ->
    # for context menu demo purposes
    @isfloatDraggable = not @isfloatDraggable
  
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
  #Morph::nextTab = function (editField) {
  #	var	next = this.nextEntryField(editField);
  #	editField.clearSelection();
  #	next.selectAll();
  #	next.edit();
  #};
  #
  #Morph::previousTab = function (editField) {
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
    if handler?
      handler = handler.parent  while not handler[functionName] and handler.parent?
      handler[functionName] arg  if handler[functionName]
  
  
  # Morph eval. Used by the Inspector and the TextMorph.
  evaluateString: (code) ->
    try
      result = eval(code)
      @setLayoutBeforeUpdatingBackingStore()
      @updateBackingStore()
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
    oImg = newCanvas(oRect.extent().scaleBy pixelRatio)
    ctx = oImg.getContext("2d")
    ctx.scale pixelRatio, pixelRatio
    if oRect.width() < 1 or oRect.height() < 1
      return newCanvas((new Point(1, 1)).scaleBy pixelRatio)
    ctx.drawImage @fullImage(),
      Math.round(oRect.origin.x - fb.origin.x),
      Math.round(oRect.origin.y - fb.origin.y)
    ctx.globalCompositeOperation = "source-in"
    ctx.drawImage otherMorph.fullImage(),
      Math.round(otherFb.origin.x - oRect.origin.x),
      Math.round(otherFb.origin.y - oRect.origin.y)
    oImg
