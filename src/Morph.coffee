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

  # some visual cues work best if they are always in
  # the same aspect ratio. E.g. icons are much less
  # recognisable when they come with different aspect
  # ratios. So there is a way to keep the same aspect
  # ratio when resizing
  aspectRatio: null
  
  # Just some tests here ////////////////////
  propertyUpTheChain: [1,2,3]
  morphMethod: ->
    3.14
  @morphStaticMethod: ->
    3.14
  # End of tests here ////////////////////

  isMorph: true

  # we conveniently keep all geometry information
  # into a single property (a Rectangle). Only
  # a few geometry-related methods should directly
  # access this property.
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
  shadowBlur: 10
  onNextStep: null # optional function to be run once. Not currently used in Zombie Kernel

  # contains all the reactive vals
  allValsInMorphByName: null
  morphValsDependingOnChildrenVals: null
  morphValsDirectlyDependingOnParentVals: null

  clickOutsideMeOrAnyOfMeChildrenCallback: [null]
  isMarkedForDestruction: false

  textDescription: null

  geometryOrPositionPossiblyChanged: false
  boundsWhenLastPainted: null

  fullGeometryOrPositionPossiblyChanged: false
  fullClippedBoundsWhenLastPainted: null

  cachedFullBounds: null
  childrenBoundsUpdatedAt: -1

  checkFullClippedBoundsCache: null
  cachedFullClippedBounds: null

  checkVisibilityCache: null
  checkVisibilityCacheChecker: ""

  checkClippingVisibilityCache: null
  checkClippingVisibilityCacheChecker: ""

  visibleBoundsCache: null
  clipThroughBoundsCache: null
  visibleBoundsCacheChecker: ""

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

    @silentSetBounds new Rectangle()
    @minimumExtent = new Point 5,5
    @silentFullMoveTo(new Point 0,0)
    # [TODO] why is there this strange non-zero default extent?
    @silentSetExtent(new Point 50, 40)

    @color = @color or new Color(80, 80, 80)
    @lastTime = Date.now()
    # Note that we don't call 
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
      return firstPart + " " + @boundingBox()

  # Morph string representation: e.g. 'a Morph#2'
  toStringWithoutGeometry: ->
    "a " +
      @uniqueIDString()
  
  
  # Morph deleting:
  destroy: ->
    WorldMorph.numberOfAddsAndRemoves++
    # remove callback when user clicks outside
    # me or any of my children
    @onClickOutsideMeOrAnyOfMyChildren null

    if @parent?
      @fullChanged()
      @parent.removeChild @
    return null
  
  fullDestroy: ->
    WorldMorph.numberOfAddsAndRemoves++
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    until @children.length == 0
      @children[0].fullDestroy()
    @destroy()
    return null

  fullDestroyChildren: ->
    WorldMorph.numberOfAddsAndRemoves++
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    until @children.length == 0
      @children[0].fullDestroy()
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
  
  setBounds: (newBounds) ->
    @breakNumberOfMovesAndResizesCaches()
    @bounds = newBounds
    @changed()
    @invalidateFullBoundsCache(@)
    @invalidateFullClippedBoundsCache(@)


  silentSetBounds: (newBounds) ->
    @bounds = newBounds
    @invalidateFullBoundsCache(@)
    @invalidateFullClippedBoundsCache(@)
  
  corners: ->
    @bounds.corners()
  
  leftCenter: ->
    @bounds.leftCenter()
  
  rightCenter: ->
    @bounds.rightCenter()
  
  topCenter: ->
    @bounds.topCenter()
  
  # same as position()
  topLeft: ->
    @bounds.origin
  
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
    if @checkVisibility() and
        !theMorph.containedInParentsOf(@) and
        @areBoundsIntersecting(theMorph) and
        !@anyParentMarkedForDestruction()
      result = [@]

    @children.forEach (child) ->
      result = result.concat(child.plausibleTargetAndDestinationMorphs(theMorph))

    return result


  # both methods invoked in here
  # are cached
  surelyNotShowingUpOnScreen: ->
    if @isOrphan()
      return true
    if !@checkVisibility()
      return true
    return false

  SLOWcheckVisibility: ->
    if !@isVisible
      return false
    if @parent?
      return @parent.SLOWcheckVisibility()
    else
      return true

  SLOWcheckClippingVisibility: ->
    if !@isVisible or @isOrphan()
      return false
    if @parent?
      return @parent.SLOWcheckClippingVisibility()
    else
      return true

  checkVisibility: ->
    if !@isVisible
      # I'm not sure updating the cache here does
      # anything but it's two lines so let's do it
      @checkVisibilityCacheChecker = WorldMorph.numberOfAddsAndRemoves + "" + WorldMorph.numberOfVisibilityFlagsChanges
      @checkVisibilityCache = false
      result = @checkVisibilityCache
    else
      if !@parent?
        result = true
      else
        if @checkVisibilityCacheChecker == WorldMorph.numberOfAddsAndRemoves + "" + WorldMorph.numberOfVisibilityFlagsChanges
          #console.log "cache hit checkVisibility"
          result = @checkVisibilityCache
        else
          #console.log "cache miss checkVisibility"
          @checkVisibilityCacheChecker = WorldMorph.numberOfAddsAndRemoves + "" + WorldMorph.numberOfVisibilityFlagsChanges
          @checkVisibilityCache = @parent.checkVisibility()
          result = @checkVisibilityCache

    if result != @SLOWcheckVisibility()
      debugger
      alert "checkVisibility is broken"

    return result

  checkClippingVisibility: ->
    if !@isVisible or @isOrphan()
      # I'm not sure updating the cache here does
      # anything but it's two lines so let's do it
      @checkClippingVisibilityCacheChecker = WorldMorph.numberOfAddsAndRemoves + "" + WorldMorph.numberOfVisibilityFlagsChanges
      @checkClippingVisibilityCache = false
      result = @checkClippingVisibilityCache
    else
      if !@parent?
        result = true
      else
        if @checkClippingVisibilityCacheChecker == WorldMorph.numberOfAddsAndRemoves + "" + WorldMorph.numberOfVisibilityFlagsChanges
          #console.log "cache hit checkClippingVisibility"
          result = @checkClippingVisibilityCache
        else
          #console.log "cache miss checkClippingVisibility"
          @checkClippingVisibilityCacheChecker = WorldMorph.numberOfAddsAndRemoves + "" + WorldMorph.numberOfVisibilityFlagsChanges
          @checkClippingVisibilityCache = @parent.checkClippingVisibility()
          result = @checkClippingVisibilityCache

    if result != @SLOWcheckClippingVisibility()
      debugger
      alert "checkClippingVisibility is broken"

    return result

  # Note that in a case of a move
  # you should also invalidate all the morphs in
  # the subtree
  # as well. This happens indirectly as the
  # fullMoveBy moves all the children too, so *that*
  # invalidates them. Note that things might change
  # if you use a different coordinate system, in which
  # case you have to invalidate the caches in all the
  # submorphs manually.
  invalidateFullBoundsCache: ->
    if !@cachedFullBounds?
      return
    @cachedFullBounds = null
    if @parent?.cachedFullBounds?
        @parent.invalidateFullBoundsCache(@)

  invalidateFullClippedBoundsCache: ->
    if !@cachedFullClippedBounds?
      return
    @cachedFullClippedBounds = null
    if @parent?.cachedFullClippedBounds?
        @parent.invalidateFullClippedBoundsCache(@)


  SLOWfullBounds: ->
    result = @bounds
    @children.forEach (child) ->
      if child.checkVisibility()
        result = result.merge(child.SLOWfullBounds())
    result

  SLOWfullClippedBounds: ->
    if @isOrphan() or !@checkClippingVisibility()
      return new Rectangle()
    result = @bounds
    @children.forEach (child) ->
      if child.checkClippingVisibility()
        result = result.merge(child.SLOWfullClippedBounds())
    result

  # for FrameMorph scrolling support:
  subMorphsMergedFullBounds: ->
    result = null
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        result = result.merge(child.fullBounds())
    result    
  
  fullBounds: ->
    if @cachedFullBounds?
      if !@cachedFullBounds.eq @SLOWfullBounds()
        debugger
        alert "fullBounds is broken"
      return @cachedFullBounds

    result = @bounds
    @children.forEach (child) ->
      if child.checkVisibility()
        result = result.merge(child.fullBounds())

    if !result.eq @SLOWfullBounds()
      debugger
      alert "fullBounds is broken"

    @cachedFullBounds = result

  fullClippedBounds: ->
    if @isOrphan() or !@checkClippingVisibility()
      result = new Rectangle()
    else
      if @cachedFullClippedBounds?
        if @checkFullClippedBoundsCache == WorldMorph.numberOfAddsAndRemoves + "" + WorldMorph.numberOfVisibilityFlagsChanges
          if !@cachedFullClippedBounds.eq @SLOWfullClippedBounds()
            debugger
            alert "fullClippedBounds is broken"
          return @cachedFullClippedBounds

      result = @bounds
      @children.forEach (child) ->
        if child.checkClippingVisibility()
          result = result.merge(child.fullClippedBounds())

    if !result.eq @SLOWfullClippedBounds()
      debugger
      alert "fullClippedBounds is broken"

    @checkFullClippedBoundsCache = WorldMorph.numberOfAddsAndRemoves + "" + WorldMorph.numberOfVisibilityFlagsChanges
    @cachedFullClippedBounds = result
  
  fullBoundsNoShadow: ->
    # answer my full bounds but ignore any shadow
    result = @bounds
    @children.forEach (child) ->
      if (child not instanceof ShadowMorph) and (child.checkVisibility())
        result = result.merge(child.fullBoundsNoShadow())
    result

  clipThroughBounds: ->
    @visibleBounds()
    return @clipThroughBoundsCache
  
  visibleBounds: ->
    # answer which part of me is not clipped by a Frame
    if @ == Window
      debugger

    if @visibleBoundsCacheChecker == (WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfMovesAndResizes)
      #console.log "cache hit @visibleBoundsCacheChecker"
      return @visibleBoundsCache
    #else
    #  console.log "cache miss @visibleBoundsCacheChecker"
    #  #console.log (WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfMovesAndResizes) + " cache: " + @visibleBoundsCacheChecker
    #  #debugger


    chainFromRoot = @allParentsBottomToTop()

    visible = chainFromRoot[0].bounds
    for eachElement in chainFromRoot

      if @isOrphan()
        visible = new Rectangle()
        eachElement.visibleBoundsCacheChecker = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfMovesAndResizes
        eachElement.visibleBoundsCache = visible
        eachElement.clipThroughBoundsCache = visible
      else
        if eachElement instanceof FrameMorph
          visible = visible.intersect eachElement.bounds
        eachElement.visibleBoundsCacheChecker = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfMovesAndResizes
        eachElement.visibleBoundsCache = visible.intersect eachElement.bounds
        eachElement.clipThroughBoundsCache = visible.copy()

    return @visibleBoundsCache
  
  
  # Morph accessing - simple changes:
  fullMoveBy: (delta) ->
    if delta.isZero() then return
    # note that changed() is called two times
    # because there are two areas of the screens
    # that are dirty: the starting
    # position and the end position.
    # Both need to be repainted.
    #console.log "move 4"
    @breakNumberOfMovesAndResizesCaches()
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.fullMoveBy delta
    @changed()

  silentFullMoveBy: (delta) ->
    #console.log "move 5"
    @breakNumberOfMovesAndResizesCaches()
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.silentFullMoveBy delta
  
  breakNumberOfMovesAndResizesCaches: ->
    @invalidateFullBoundsCache(@)
    @invalidateFullClippedBoundsCache(@)
    if @ instanceof HandMorph
      if @children.length == 0
        return
    WorldMorph.numberOfMovesAndResizes++

  
  fullMoveTo: (aPoint) ->
    aPoint.debugIfFloats()
    delta = aPoint.toLocalCoordinatesOf @
    if !delta.isZero()
      #console.log "move 6"
      @breakNumberOfMovesAndResizesCaches()
      @fullMoveBy delta
    @bounds.debugIfFloats()
  
  silentFullMoveTo: (aPoint) ->
    #console.log "move 7"
    @breakNumberOfMovesAndResizesCaches()
    delta = aPoint.toLocalCoordinatesOf @
    @silentFullMoveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  fullMoveLeftSideTo: (x) ->
    @fullMoveTo new Point(x, @top())
  
  fullMoveRightSideTo: (x) ->
    @fullMoveTo new Point(x - @width(), @top())
  
  fullMoveTopSideTo: (y) ->
    @fullMoveTo new Point(@left(), y)
  
  fullMoveBottomSideTo: (y) ->
    @fullMoveTo new Point(@left(), y - @height())
  
  fullMoveCenterTo: (aPoint) ->
    @fullMoveTo aPoint.subtract(@extent().floorDivideBy(2))
  
  fullMoveFullCenterTo: (aPoint) ->
    @fullMoveTo aPoint.subtract(@fullBounds().extent().floorDivideBy(2))
  
  # make sure I am completely within another Morph's bounds
  fullMoveWithin: (aMorph) ->
    leftOff = @fullBounds().left() - aMorph.left()
    @fullMoveBy new Point(-leftOff, 0)  if leftOff < 0
    rightOff = @fullBounds().right() - aMorph.right()
    @fullMoveBy new Point(-rightOff, 0)  if rightOff > 0
    topOff = @fullBounds().top() - aMorph.top()
    @fullMoveBy new Point(0, -topOff)  if topOff < 0
    bottomOff = @fullBounds().bottom() - aMorph.bottom()
    @fullMoveBy new Point(0, -bottomOff)  if bottomOff > 0

  # normally morphs do nothing when the
  # parent is layouting, as they are
  # placed with absolute positioning.
  # In some cases though, such as in the
  # case of the HandleMorph, a Morph
  # make take the occasion to do special things
  # In the case of the HandleMorph, it's going
  # to place itself in the bottom-right
  # corner.
  parentHasReLayouted: ->

  layoutInset: (morphStartingTheChange = null) ->
    if @insetMorph?
      if @insetMorph != morphStartingTheChange
        @insetMorph.fullMoveTo @insetPosition()
        @insetMorph.setExtent @insetSpaceExtent(), @
  
  # the default of layoutSubmorphs
  # is to do nothing apart from notifying
  # the children (in case, for example,
  # there is a HandleMorph in this morph
  # which will cause the HandleMorph to
  # replace itself in the new position)
  # , but things like
  # the inspector might well want to
  # tweak many of their children...
  layoutSubmorphs: (morphStartingTheChange = null) ->
    @layoutInset morphStartingTheChange

    @children.forEach (child) ->
      if morphStartingTheChange != child
        child.parentHasReLayouted()
  

  # do nothing in most cases but for example for
  # layouts, if something inside a layout wants to
  # change extent, then the whole layout might need to
  # change extent.
  childChangedExtent: (theMorphChangingTheExtent) ->
    if @insetMorph == theMorphChangingTheExtent
      @setExtent(@extentBasedOnInsetExtent(theMorphChangingTheExtent), theMorphChangingTheExtent)

  # more complex Morphs, e.g. layouts, might
  # do a more complex calculation to get the
  # minimum extent
  getMinimumExtent: ->
    @minimumExtent

  setMinimumExtent: (@minimumExtent) ->

  # Morph accessing - dimensional changes requiring a complete redraw
  setExtent: (aPoint, morphStartingTheChange = null) ->
    #console.log "move 8"
    @breakNumberOfMovesAndResizesCaches()
    if @ == morphStartingTheChange
      return
    if morphStartingTheChange == null
      morphStartingTheChange = @
    # check whether we are actually changing the extent.
    unless aPoint.eq(@extent())
      @silentSetExtent aPoint
      @changed()
      @reLayout()
      
      @layoutSubmorphs(morphStartingTheChange)
      if @parent?
        if @parent != morphStartingTheChange
          @parent.childChangedExtent(@)
  
  silentSetExtent: (aPoint) ->
    aPoint = aPoint.round()
    #console.log "move 9"
    @breakNumberOfMovesAndResizesCaches()

    minExtent = @getMinimumExtent()
    if ! aPoint.ge minExtent
      aPoint = aPoint.max minExtent
    if @aspectRatio?
      if @aspectRatio >= 1
        if aPoint.y >= aPoint.x
          aPoint = new Point aPoint.y * @aspectRatio, aPoint.y
        else
          aPoint = new Point aPoint.x, aPoint.x * (1/@aspectRatio)
      else if @aspectRatio < 1
        if aPoint.y >= aPoint.x
          aPoint = new Point aPoint.y * (1/@aspectRatio), aPoint.y
        else
          aPoint = new Point aPoint.x, aPoint.x * (1/@aspectRatio)

    newWidth = Math.max(aPoint.x, 0)
    newHeight = Math.max(aPoint.y, 0)
    @bounds = new Rectangle @bounds.origin, new Point(@bounds.origin.x + newWidth, @bounds.origin.y + newHeight)
  
  setWidth: (width) ->
    #console.log "move 10"
    @breakNumberOfMovesAndResizesCaches()
    @setExtent new Point(width or 0, @height())
  
  silentSetWidth: (width) ->
    #console.log "move 11"
    @breakNumberOfMovesAndResizesCaches()
    w = Math.max(Math.round(width or 0), 0)
    @bounds = new Rectangle @bounds.origin, new Point(@bounds.origin.x + w, @bounds.corner.y)
  
  setHeight: (height) ->
    #console.log "move 12"
    @breakNumberOfMovesAndResizesCaches()
    @setExtent new Point(@width(), height or 0)
  
  silentSetHeight: (height) ->
    #console.log "move 13"
    @breakNumberOfMovesAndResizesCaches()
    h = Math.max(Math.round(height or 0), 0)
    @bounds = new Rectangle @bounds.origin, new Point(@bounds.corner.x, @bounds.origin.y + h)
  
  setColor: (aColorOrAMorphGivingAColor, morphGivingColor) ->
    if morphGivingColor?.getColor?
      aColor = morphGivingColor.getColor()
    else
      aColor = aColorOrAMorphGivingAColor
    if aColor
      unless @color.eq(aColor)
        @color = aColor
        if @backBufferIsPotentiallyDirty? then @backBufferIsPotentiallyDirty = true
        @changed()
        
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
  # * paintIntoAreaOrBlitFromBackBuffer: takes the local canvas and paints it to a specific area in a passed
  #   canvas. The local canvas doesn't contain any rendering of the children of
  #   this morph.
  # * fullPaintIntoAreaOrBlitFromBackBuffer: recursively draws all the local canvas of this morph and all
  #   its children into a specific area of a passed canvas.

  
  # tiles the texture
  drawCachedTexture: ->
    bg = @cachedTexture
    cols = Math.floor(@backBuffer.width / bg.width)
    lines = Math.floor(@backBuffer.height / bg.height)
    context = @backBuffer.getContext("2d")
    for y in [0..lines]
      for x in [0..cols]
        context.drawImage bg, Math.round(x * bg.width), Math.round(y * bg.height)
    @changed()
  
  
  # a morph by default is considered as completely
  # opaque and rectangular. This method is called when
  # the mouse if within the bounds of the morph.
  # There are two possible implementations of this
  # method - one is raster-based and looks up the
  # backing store contents. The other one calculated
  # mathematically whether there is anything under
  # the mouse.
  isTransparentAt: ->
    return false
  
  boundsContainPoint: (aPoint) ->
    @bounds.containsPoint aPoint

  areBoundsIntersecting: (aMorph) ->
    @bounds.isIntersecting aMorph.bounds

  calculateKeyValues: (aContext, clippingRectangle) ->
    area = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if area.isNotEmpty()
      delta = @position().neg()
      src = area.translateBy(delta).round()
      sl = src.left() * pixelRatio
      st = src.top() * pixelRatio
      al = area.left() * pixelRatio
      at = area.top() * pixelRatio
      w = Math.min(src.width() * pixelRatio, @width() * pixelRatio - sl)
      h = Math.min(src.height() * pixelRatio, @height() * pixelRatio - st)
    return [area,sl,st,al,at,w,h]

  # This method only paints this very morph
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

    if !@checkVisibility()
      return null

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null
      aContext.globalAlpha = @alpha

      aContext.save()
      if !@color?
        debugger
      aContext.fillStyle = @color.toString()
      aContext.fillRect  Math.round(al),
          Math.round(at),
          Math.round(w),
          Math.round(h)
      aContext.restore()

      if world.showRedraws
        randomR = Math.round(Math.random()*255)
        randomG = Math.round(Math.random()*255)
        randomB = Math.round(Math.random()*255)

        aContext.save()
        aContext.globalAlpha = 0.5
        aContext.fillStyle = "rgb("+randomR+","+randomG+","+randomB+")";
        aContext.fillRect  Math.round(al),
            Math.round(at),
            Math.round(w),
            Math.round(h)
        aContext.restore()

  preliminaryCheckNothingToDraw: (noShadow, clippingRectangle) ->
    if clippingRectangle.isEmpty()
      return true

    if !@checkVisibility()
      return true

    if noShadow and (@ instanceof ShadowMorph)
      return true

    return false

  recordDrawnAreaForNextBrokenRects: ->
    if @childrenBoundsUpdatedAt < WorldMorph.frameCount
      @childrenBoundsUpdatedAt = WorldMorph.frameCount
      @boundsWhenLastPainted = @visibleBounds()
      if @!= world and (@boundsWhenLastPainted.containsPoint (new Point(10,10)))
        debugger
      @fullClippedBoundsWhenLastPainted = @fullClippedBounds()


  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle = @fullClippedBounds(), noShadow = false) ->

    if @preliminaryCheckNothingToDraw noShadow, clippingRectangle
      return

    # in general, the children of a Morph could be outside the
    # bounds of the parent (they could also be much larger
    # then the parent). This means that we have to traverse
    # all the children to find out whether any of those overlap
    # the clipping rectangle. Note that we can be smarter with
    # FrameMorphs, as their children are actually all contained
    # within the parent's boundary.

    # Note that if we could dynamically and cheaply keep an updated
    # fullBounds property, then we could be smarter
    # in discarding whole sections of the scene graph.
    # (see https://github.com/davidedc/Zombie-Kernel/issues/150 )
    

    if aContext == world.worldCanvas.getContext("2d")
      @recordDrawnAreaForNextBrokenRects()
    @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle
    @children.forEach (child) ->
      child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, noShadow
  

  hide: ->
    @isVisible = false
    WorldMorph.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache(@)
    @invalidateFullClippedBoundsCache(@)
    @fullChanged()

  show: ->
    if @checkVisibility() == true
      return
    @isVisible = true
    WorldMorph.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache(@)
    @invalidateFullClippedBoundsCache(@)
    @fullChanged()
  
  minimise: ->
    @hide()
  
  unminimise: ->
    @show()
  
  
  toggleVisibility: ->
    @isVisible = (not @isVisible)
    WorldMorph.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache(@)
    @invalidateFullClippedBoundsCache(@)
    @fullChanged()
  
  
  # Morph full image:
  
  # Fixes https://github.com/jmoenig/morphic.js/issues/7
  # and https://github.com/davidedc/Zombie-Kernel/issues/160
  fullImage: (bounds, noShadow = false) ->
    if !bounds?
      bounds = @fullBounds()

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
    @fullPaintIntoAreaOrBlitFromBackBuffer ctx, bounds, noShadow
    img

  fullImageNoShadow: ->
    boundsWithNoShadow = @fullBoundsNoShadow()
    return @fullImage(boundsWithNoShadow, true)

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
  fullImageAsItAppearsOnScreen: ->
    fullExtentOfMorph = @fullBounds()
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
  
  # Morph shadow.
  # The canvas with the shadow is completely
  # transparent apart from the shadow
  # "overflowing" from the edges.
  # For example if you create the shadow for
  # a blue rectangle by running this method,
  # you'll get a canvas with
  # a transparent rectangle in the middle and the
  # "leaking" shadow.
  # The "completely" transparent bit is actually
  # partially transparent if the fill of the
  # rectangle is semi-transparent, i.e. you can
  # see the shadow through a semitransparent
  # morph.
  # So, the shadow of a blue semi-transparent box
  # *will* contain some semi-transparent fill of
  # the box.
  shadowImage: (off_, color, blurred) ->
    offset = off_ or new Point(7, 7)
    blur = @shadowBlur
    clr = color or new Color(0, 0, 0)
    fb = @fullBoundsNoShadow().extent().add(blur * 2)

    # take "the image" which is the image of all the
    # morphs. This image contains no shadows, the shadow
    # will be made starting from this image in a second.
    img = @fullImageNoShadow()

    # draw the image in special "shadowBlur" mode
    # http://www.w3schools.com/tags/canvas_shadowblur.asp
    sha = newCanvas(fb.scaleBy pixelRatio)
    ctx = sha.getContext("2d")
    #ctx.scale pixelRatio, pixelRatio
    ctx.shadowOffsetX = offset.x * pixelRatio
    ctx.shadowOffsetY = offset.y * pixelRatio
    if blurred
      ctx.shadowBlur = blur * pixelRatio
    ctx.shadowColor = clr.toString()
    ctx.drawImage img, Math.round((blur - offset.x)*pixelRatio), Math.round((blur - offset.y)*pixelRatio)
    # now redraw the image in destination-out mode so that
    # it "cuts-out" everything that is not the actual shadow
    # around the edges. This is so we can draw the shadow ON TOP
    # of the morph and it's gonna loook OK (cause there is a hole
    # where the morph can peek through as it's drawn after the
    # shadow)
    ctx.shadowOffsetX = 0
    ctx.shadowOffsetY = 0
    ctx.shadowBlur = 0
    ctx.globalCompositeOperation = "destination-out"
    ctx.drawImage img, Math.round((blur - offset.x)*pixelRatio), Math.round((blur - offset.y)*pixelRatio)
    sha
  
  isBeingFloatDragged: ->
    # first check if the hand is nonfloatdragging
    # anything at all
    if !@nonFloatDraggedMorph?
      return false

    # then check if my root is the hand
    if root() instanceof HandMorph
      return true

    # if we are here it means we are not being
    # nonfloatdragged
    return false

  # shadow is added to a morph by
  # the HandMorph while floatDragging
  addFullShadow: (offset, alpha, color) ->
    shadow = @silentAddFullShadow offset, alpha, color
    shadow.reLayout()
    
    @fullChanged()
    shadow

  silentAddFullShadow: (offset, alpha, color) ->
    shadow = new ShadowMorph(@, offset, alpha, color)
    @addChildFirst shadow
    shadow
  
  getShadowMorph: ->
    return @topmostChildSuchThat (child) ->
      child instanceof ShadowMorph
  
  removeShadowMorph: ->
    shadow = @getShadowMorph()
    if shadow?
      @fullChanged()
      @removeChild shadow
  
  
  
  # Morph updating ///////////////////////////////////////////////////////////////
  changed: ->
    if trackChanges[trackChanges.length - 1]

      # if the morph is attached to a hand then
      # there is also a shadow to change, so we
      # change everything that is attached
      # to the hand, which means we issue a
      # fullChanged()
      if @isBeingFloatDragged()
        world.hand.fullChanged()
        return

      if !@geometryOrPositionPossiblyChanged
        window.morphsThatMaybeChangedGeometryOrPosition.push @
        @geometryOrPositionPossiblyChanged = true

    @parent.childChanged @  if @parent
  
  fullChanged: ->
    if trackChanges[trackChanges.length - 1]
      if !@fullGeometryOrPositionPossiblyChanged
        window.morphsThatMaybeChangedFullGeometryOrPosition.push @
        @fullGeometryOrPositionPossiblyChanged = true
  
  childChanged: ->
    # react to a  change in one of my children,
    # default is to just pass this message on upwards
    # override this method for Morphs that need to adjust accordingly
    @parent.childChanged @  if @parent
  
  
  # Morph accessing - structure //////////////////////////////////////////////

  imBeingAddedTo: (newParentMorph) ->
    @reLayout()
    
  
  # attaches submorph on top
  # ??? TODO you should handle the case of Morph
  #     being added to itself and the case of
  # ??? TODO a Morph being added to one of its
  #     children
  add: (aMorph, position = null) ->
    # the morph that is being
    # attached might be attached to
    # a clipping morph. So we
    # need to do a "changed" here
    # to make sure that anything that
    # is outside the clipping Morph gets
    # painted over.
    if aMorph.parent?
      aMorph.changed()
    @silentAdd(aMorph, true, position)
    aMorph.imBeingAddedTo @

  addInset: (aMorph) ->

    if aMorph.parent?
      aMorph.changed()

    @insetMorph = aMorph

    if @children.length > 0
      if @children[0] instanceof ShadowMorph
        @add aMorph, 1
      else
        @add aMorph, 0
    else
      @add aMorph, 0

    aMorph.fullMoveTo @insetPosition()
    aMorph.setExtent @insetSpaceExtent(), @



  # this is done before the updating of the
  # backing store in some morphs that
  # need to figure out their whole
  # layout (which depends on the children)
  # before painting themselves
  # e.g. the MenuMorph
  reLayout: ->
    if @backBufferIsPotentiallyDirty?
      @backBufferIsPotentiallyDirty = true


  calculateAndUpdateExtent: ->

  silentAdd: (aMorph, avoidExtentCalculation, position = null) ->
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
    @addChild aMorph, position
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
      if m.fullBounds().containsPoint(aPoint) and (result is null)
        result = m

    result
  
  #
  #	potential alternative - solution for morphAt.
  #	Has some issues, commented out for now...
  #
  #Morph::morphAt = function (aPoint) {
  #	return this.topMorphSuchThat(function (m) {
  #		return m.fullBounds().containsPoint(aPoint);
  #	});
  #};
  #
  

  # Duplication and Serialization /////////////////////////////////////////


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
    @fullMoveTo world.hand.position().subtract(@fullBoundsNoShadow().extent().floorDivideBy(2))
  
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
      @silentFullMoveBy new Point(xStep, yStep)
      @fullChanged()
      stepCount += 1
      if stepCount is steps
        situation.origin.add @
        situation.origin.reactToDropOf @  if situation.origin.reactToDropOf
        @step = oldStep
        @fps = oldFps
  
  
  # Morph utilities ////////////////////////////////////////////////////////
  
  resize: ->
    world.activeHandle.push new HandleMorph(@, "resizeRight")
    world.activeHandle.push new HandleMorph(@, "resizeDown")
    world.activeHandle.push new HandleMorph(@, "move")
    world.activeHandle.push new HandleMorph(@, "resize")
  
  move: ->
    world.activeHandle.push new HandleMorph(@, "move")
  
  hint: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph(false, @, true, true, text)
    m.isfloatDraggable = true
    m.popUpCenteredAtHand world
  
  inform: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph(false, @, true, true, text)
    m.addItem "Ok"
    m.isfloatDraggable = true
    m.popUpCenteredAtHand world

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
    theMenu.tempPromptEntryField.text.reLayout()
    
    theMenu.tempPromptEntryField.text.changed()
    theMenu.tempPromptEntryField.text.edit()

  reactToSliderAction2: (num, theMenu) ->
    alert "I thought this wasn't used, add a note in the code about how this comes about"
    theMenu.tempPromptEntryField.changed()
    theMenu.tempPromptEntryField.text.text = num.toString()
    theMenu.tempPromptEntryField.text.reLayout()
    
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
    inspector.fullMoveTo world.hand.position()
    inspector.fullMoveWithin world
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
    @pickColor "color:", "setColor", new Color 0,0,0

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
      alpha = @calculateAlphaScaled(alpha)
      unless @alpha == alpha
        @alpha = alpha
        if @backBufferIsPotentiallyDirty? then @backBufferIsPotentiallyDirty = true
        @changed()

    return alpha

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
    ["fullMoveLeftSideTo", "fullMoveTopSideTo", "setWidth", "setHeight", "setAlphaScaled"]
  
  
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
      @reLayout()
      
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
    fb = @fullBounds()
    otherFb = otherMorph.fullBounds()
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
