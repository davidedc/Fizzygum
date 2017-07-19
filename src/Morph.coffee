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
# REQUIRES LayoutSpec

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

  # unused - can't afford the time right now to change a
  # script that hangs
  # TODO
  aspectRatio: null

  appearance: null

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
  color: new Color 80, 80, 80
  texture: null # optional url of a fill-image
  cachedTexture: null # internal cache of actual bg image
  lastTime: null

  # 1: fully opaque, 0: fully transparent
  alpha: 1

  # the padding area of a morph is INSIDE a morph and
  # responds to mouse events.
  # The padding area should be empty, not drawn, except
  # for debugging or "interim painting" purposes such
  # as highlights.
  # The padding's purpose is to give the option to morphs
  # to accommodate for spacing between their contents and
  # their bounds, so to enable consecutive morphs to
  # have some spacing in between them.
  # Note that paddings of consecutive morphs do add up.
  # The padding area reacts to mouse events ONLY IF
  # it's filled with color. Otherwise, it doesn't.
  # This is consistent with the concept that Morphs only
  # react within their "filled" region.
  paddingTop: 0
  paddingBottom: 0
  paddingLeft: 0
  paddingRight: 0

  # backgroundColor and backgroundTransparency fill the
  # entire rectangular bounds of the morph.
  # I.e. they area they fill is not affected by the
  # padding or the actual design of the morph.
  backgroundColor: null
  backgroundTransparency: 1

  # for a Morph, being visible and collapsed
  # are two separate things.
  # isVisible means that the morph is meant to show
  #  as empty or without any surface. BUT the morph
  #  will still take the usual space.
  # Collapsed means that the morph, whatever its
  #  content or appearance or design, is not drawn
  #  on the desktop AND it doesn't occupy any space.
  isVisible: true
  collapsed: false

  # if a morph is a "template" it means that
  # when you floatDrag it, it creates a copy of itself.
  # it's a nice shortcut instead of doing
  # right click and then "duplicate..."
  isTemplate: false
  _acceptsDrops: false
  noticesTransparentClick: false
  fps: 0
  customContextMenu: null
  shadowBlur: 10
  onNextStep: null # optional function to be run once. Not currently used in Fizzygum

  # contains all the reactive vals
  allValsInMorphByName: null
  morphValsDependingOnChildrenVals: null
  morphValsDirectlyDependingOnParentVals: null

  clickOutsideMeOrAnyOfMeChildrenCallback: [null]
  isMarkedForDestruction: false

  textDescription: null

  # note that not all the changed morphs have this flag set
  # because if a parent does a fullChange, we don't set this
  # flag in the children. This is intentionally so,
  # as we don't want to navigate the children too many times.
  # If you want to know whether a morph has changed its
  # position, use the hasMaybeChangedGeometryOrPosition:
  # method instead, which looks at this flag (and another one).
  # See comment below on fullGeometryOrPositionPossiblyChanged
  # for more information.
  geometryOrPositionPossiblyChanged: false
  clippedBoundsWhenLastPainted: null

  # you'd be tempted to check this flag to figure out
  # whether any morph has possibly changed position but
  # you can't. If a PARENT has done a fullChanged, the
  # children are NOT set this flag. This flag is set
  # only for the parent morph, and it's important that
  # it stays that way for how the mechanism for fleshing out
  # the broken rectangles works. We flesh out the rectangles
  # of the "fully broken" morphs separately looking at this
  # flag, and we remove the rectangles of the sub-morphs that
  # have a parent with this flag since we know that they are
  # already covered.
  # If you want to figure out whether a morph has changed,
  # use the hasMaybeChangedGeometryOrPosition: method,
  # which checks recursively with the parents both the
  # fullGeometryOrPositionPossiblyChanged flag and the
  # geometryOrPositionPossiblyChanged flag.
  # Another way of doing this is to mark with a special flag
  # all the morph that touch their bounds or positions, but
  # then it's sort of costly to un-set such flag in all such
  # morphs, as we'd have to keep the "changed" morphs in a special
  # array to do that. Seems quite a bit more work and complication,
  # so just use the method.
  fullGeometryOrPositionPossiblyChanged: false
  fullClippedBoundsWhenLastPainted: null

  cachedFullBounds: null
  childrenBoundsUpdatedAt: -1

  cachedFullClippedBounds: null
  checkFullClippedBoundsCache: null

  visibleBasedOnIsVisiblePropertyCache: null
  checkVisibleBasedOnIsVisiblePropertyCache: ""

  clippedThroughBoundsCache: null
  checkClippedThroughBoundsCache: ""

  clipThroughCache: null
  checkClipThroughCache: null

  srcBrokenRect: null
  dstBrokenRect: null

  layoutIsValid: true
  layoutSpec: LayoutSpec.ATTACHEDAS_FREEFLOATING

  _showsAdders: false

  highlighted: false
  # if this morph has the purpose of highlighting
  # another morph, then this field points to the
  # morph that this morph is supposed to highlight
  morphThisMorphIsHighlighting: null

  destroyed: false

  shadowInfo: null

  mouseClickRight: ->
    # you could bring up what you right-click,
    # however for example that's not how OSX works.
    # Perhaps this could be a system setting?
    #@bringToForegroud()

    world.hand.openContextMenuAtPointer @

  getTextDescription: ->
    if @textDescription?
      #console.log "got name: " + @textDescription + "" + @constructor.name + " (adhoc description of morph)"
      return @textDescription + "" + @constructor.name + " (adhoc description of morph)"
    else
      #console.log "got name: " + @constructor.name + " (class name)"
      return @constructor.name + " (class name)"

  identifyViaTextLabel: ->
    myTextDescription = @getTextDescription()
    allCandidateMorphsWithSameTextDescription = 
      world.allChildrenTopToBottomSuchThat (m) ->
        m.getTextDescription() == myTextDescription

    position = allCandidateMorphsWithSameTextDescription.indexOf @

    theLenght = allCandidateMorphsWithSameTextDescription.length
    #console.log [myTextDescription, position, theLenght]
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
    @constructor.name or @constructor.toString().split(" ")[1].split("(")[0]

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
    #console.log "@roundNumericIDsToNextThousand"
    # this if is because zero and multiples of 1000
    # don't go up to 1000
    if @lastBuiltInstanceNumericID % 1000 == 0
      @lastBuiltInstanceNumericID++
    @lastBuiltInstanceNumericID = 1000 * Math.ceil @lastBuiltInstanceNumericID / 1000

  constructor: ->
    super()
    @assignUniqueID()

    if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
      arr = window.world.automatorRecorderAndPlayer.tagsCollectedWhileRecordingTest
      if @constructor.name not in arr
        arr.push @constructor.name

    @bounds = Rectangle.EMPTY
    @minimumExtent = new Point 5,5

    @silentRawSetBounds new Rectangle 0,0,50,40

    @lastTime = Date.now()
    # Note that we don't call 
    # that's because the actual extending morph will probably
    # set more details of how it should look (e.g. size),
    # so we wait and we let the actual extending
    # morph to draw itself.

    @allValsInMorphByName = {}
    @morphValsDependingOnChildrenVals = {}
    @morphValsDirectlyDependingOnParentVals = {}

    @setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)

  isTransparentAt: (aPoint) ->
    @appearance?.isTransparentAt aPoint

  # useful for example when hovering over references
  # to morphs. Can only modify the rendering of a morph,
  # so any highlighting is only visible in the measure that
  # the morph is visible (as opposed to HighlighterMorph being
  # used to highlight a morph)
  paintHighlight: (aContext, al, at, w, h) ->
    @appearance?.paintHighlight aContext, al, at, w, h

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @appearance?.paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow

  addShapeSpecificMenus: (menu) ->
    if @appearance?.addShapeSpecificMenus?
      return @appearance.addShapeSpecificMenus menu
    return menu

  addShapeSpecificNumericalSetters: (list) ->
    if @appearance?.addShapeSpecificNumericalSetters?
      return @appearance.addShapeSpecificNumericalSetters list
    return list

  
  #
  #    damage list housekeeping
  #
  #	the trackChanges property of the Morph prototype is a Boolean switch
  #	that determines whether the World's damage list ('broken' rectangles)
  #	tracks changes. By default the switch is always on. If set to false,
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
  #	method of InspectorMorph
  
  
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

  close: ->
    if world.underTheCarpetMorph?
      world.underTheCarpetMorph.scrollFrame.addInPseudoRandomPosition @
    else
      world.inform "There is no\ncarpet to go under!"
  
  
  # Morph deleting:
  destroy: ->

    # remove instance from the instances tracker
    # in the class. To see this: just create an
    # AnalogClockMorph, see that
    # AnalogClockMorph.klass.instances[0] has one
    # element. Then delete the clock, and see that the
    # tracker is now an empty array.
    @constructor.klass.instances.remove @

    @destroyed = true
    @parent?.invalidateLayout()
    @breakNumberOfRawMovesAndResizesCaches()
    WorldMorph.numberOfAddsAndRemoves++

    world.removeSteppingMorph @

    # if there is anything being edited inside
    # what we are destroying, then also
    # invoke stopEditing()
    if world.caret?
      if @isAncestorOf world.caret.target
        world.stopEditing()

    # remove callback when user clicks outside
    # me or any of my children
    @onClickOutsideMeOrAnyOfMyChildren null

    if @parent?

      # if the morph contributes to a shadow, unfortunately
      # we have to walk towards the top to
      # break the morph that has the shadow.
      firstParentOwningMyShadow = @firstParentOwningMyShadow()
      if firstParentOwningMyShadow?
        firstParentOwningMyShadow.fullChanged()
      else
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
    if @children.length == 0
      return

    WorldMorph.numberOfAddsAndRemoves++
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    until @children.length == 0
      @children[0].fullDestroy()
    return null


  # not used within Fizzygum yet.
  nextSteps: (lst = []) ->
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
  
  # Morph accessing - geometry getting:
  leftTight: ->
    @bounds.left() + @paddingLeft
  
  rightTight: ->
    @bounds.right() - @paddingRight
  
  topTight: ->
    @bounds.top() + @paddingTop
  
  bottomTight: ->
    @bounds.bottom() - @paddingBottom
  
  bottomCenterTight: ->
    @bounds.bottomCenter().subtract new Point 0, @paddingBottom
  
  bottomLeftTight: ->
    @bounds.bottomLeft().add new Point @paddingLeft, -@paddingBottom
  
  bottomRightTight: ->
    @bounds.bottomRight().subtract new Point @paddingRight, @paddingBottom
  
  boundingBoxTight: ->
    new Rectangle @leftTight(), @topTight(), @rightTight(), @bottomTight()
  
  # note that using this one, the children
  # morphs attached as floating don't move
  rawSetBounds: (newBounds) ->
    if @bounds.eq newBounds
      return

    unless @bounds.origin.eq newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @breakNumberOfRawMovesAndResizesCaches()
      @changed()

    @rawSetExtent newBounds.extent()

  setBounds: (aRectangle, morphStartingTheChange = null) ->
    if @layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING
      return
    else
      @invalidateLayout()
      @rawSetBounds arguments...

  silentRawSetBounds: (newBounds) ->
    if @bounds.eq newBounds
      return

    unless @bounds.origin.eq newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @breakNumberOfRawMovesAndResizesCaches()

    @silentRawSetExtent newBounds.extent()
  
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

  cornersTight: ->
    [@topLeftTight(), @bottomLeftTight(), @bottomRightTight(), @topRightTight()]
  
  leftCenterTight: ->
    @bounds.leftCenter().add new Point @paddingLeft, 0
  
  rightCenterTight: ->
    @bounds.rightCenter().subtract new Point @paddingRight, 0
  
  topCenterTight: ->
    @bounds.topCenter().add new Point 0, @paddingTop
  
  # same as position()
  topLeftTight: ->
    @bounds.origin.add new Point @paddingLeft, @paddingTop
  
  topRightTight: ->
    @bounds.topRight.add new Point -@paddingRight, @paddingTop
  
  positionTight: ->
    @bounds.origin.add new Point @paddingLeft, @paddingTop
  
  extentTight: ->
    @bounds.extent().subtract new Point - (@paddingLeft + @paddingRight), - (@paddingTop + @paddingBottom)
  
  widthTight: ->
    @bounds.width() - (@paddingLeft + @paddingRight)
  
  heightTight: ->
    @bounds.height() - (@paddingTop + @paddingBottom)


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
    if @visibleBasedOnIsVisibleProperty() and
        !@isCollapsed() and
        !theMorph.isAncestorOf(@) and
        @areBoundsIntersecting(theMorph) and
        !@anyParentMarkedForDestruction()
      result = [@]

    @children.forEach (child) ->
      result = result.concat(child.plausibleTargetAndDestinationMorphs(theMorph))

    return result


  # both methods invoked in here
  # are cached
  # used in the method fleshOutBroken
  # to skip the "destination" broken rects
  # for morphs that marked themselves
  # as broken but at moment of destination
  # might be invisible
  surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage: ->
    if !@isVisible
      return true

    if @isOrphan()
      return true

    if !@visibleBasedOnIsVisibleProperty()
      return true

    if @isCollapsed()
      return true

    return false


  SLOWvisibleBasedOnIsVisibleProperty: ->
    if !@isVisible
      return false
    if @parent?
      return @parent.SLOWvisibleBasedOnIsVisibleProperty()
    else
      return true

  # doesn't check orphanage
  visibleBasedOnIsVisibleProperty: ->
    if !@isVisible
      # I'm not sure updating the cache here does
      # anything but it's two lines so let's do it
      @checkVisibleBasedOnIsVisiblePropertyCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges
      @visibleBasedOnIsVisiblePropertyCache = false
      result = @visibleBasedOnIsVisiblePropertyCache
    else # @isVisible is true
      if !@parent?
        result = true
      else
        if @checkVisibleBasedOnIsVisiblePropertyCache == WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges
          #console.log "cache hit visibleBasedOnIsVisibleProperty"
          result = @visibleBasedOnIsVisiblePropertyCache
        else
          #console.log "cache miss visibleBasedOnIsVisibleProperty"
          @checkVisibleBasedOnIsVisiblePropertyCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges
          @visibleBasedOnIsVisiblePropertyCache = @parent.visibleBasedOnIsVisibleProperty()
          result = @visibleBasedOnIsVisiblePropertyCache

    if world.doubleCheckCachedMethodsResults
      if result != @SLOWvisibleBasedOnIsVisibleProperty()
        debugger
        alert "visibleBasedOnIsVisibleProperty is broken"

    return result


  # Note that in a case of a fullMove*
  # you should also invalidate all the morphs in
  # the subtree as well.
  # This happens indirectly as the fullMove* methods
  # move all the children too, so *that*
  # invalidates them. Note that things might change
  # if you use a different coordinate system, in which
  # case you have to invalidate the caches in all the
  # submorphs manually or use some other cache
  # invalidation mechanism.
  invalidateFullBoundsCache: ->
    if !@cachedFullBounds?
      return
    @cachedFullBounds = null
    if @parent?.cachedFullBounds?
        @parent.invalidateFullBoundsCache @

  invalidateFullClippedBoundsCache: ->
    if !@checkFullClippedBoundsCache?
      return
    @checkFullClippedBoundsCache = null
    if @parent?.checkFullClippedBoundsCache?
        @parent.invalidateFullClippedBoundsCache @


  # doesn't take into account orphanage
  # or visibility
  SLOWfullBounds: ->
    result = @bounds
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and
      !child.isCollapsed()
        result = result.merge child.SLOWfullBounds()
    result

  SLOWfullClippedBounds: ->
    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
      return Rectangle.EMPTY
    result = @clippedThroughBounds()
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and !child.isCollapsed()
        result = result.merge child.SLOWfullClippedBounds()
    #if this != world and result.corner.x > 400 and result.corner.y > 100 and result.origin.x ==0 and result.origin.y ==0
    #  debugger
    result

  # for FrameMorph scrolling support
  subMorphsMergedFullBounds: ->
    result = null
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        result = result.merge child.fullBounds()
    result    
  
  # does not take into account orphanage or visibility
  fullBounds: ->
    if @cachedFullBounds?
      if world.doubleCheckCachedMethodsResults
        if !@cachedFullBounds.eq @SLOWfullBounds()
          debugger
          alert "fullBounds is broken (cached)"
      return @cachedFullBounds

    result = @bounds
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and !child.isCollapsed()
        result = result.merge child.fullBounds()

    if world.doubleCheckCachedMethodsResults
      if !result.eq @SLOWfullBounds()
        debugger
        alert "fullBounds is broken (uncached)"

    @cachedFullBounds = result

  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the smallest broken rectangle created by
  # a fullChanged(), which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  fullClippedBounds: ->
    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
      result = Rectangle.EMPTY
    else
      if @checkFullClippedBoundsCache == WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
        if world.doubleCheckCachedMethodsResults
          if !@cachedFullClippedBounds.eq @SLOWfullClippedBounds()
            debugger
            alert "fullClippedBounds is broken"
        return @cachedFullClippedBounds

      # you'd be thinking this is the same as
      #   result = @fullBounds().intersect @clipThrough()
      # but it's not, because fullBounds doesn't
      # take into account orphanage and visibility

      result = @clippedThroughBounds()
      @children.forEach (child) ->
        if child.visibleBasedOnIsVisibleProperty() and !child.isCollapsed()
          result = result.merge child.fullClippedBounds()

    if world.doubleCheckCachedMethodsResults
      if !result.eq @SLOWfullClippedBounds()
        debugger
        alert "fullClippedBounds is broken"

    @checkFullClippedBoundsCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
    @cachedFullClippedBounds = result
  
  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the smallest broken rectangle created by
  # a changed(), which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  clippedThroughBounds: ->

    if @checkClippedThroughBoundsCache == WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
      #console.log "cache hit @checkClippedThroughBoundsCache"
      return @clippedThroughBoundsCache
    #else
    #  console.log "cache miss @checkClippedThroughBoundsCache"
    #  #console.log (WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes) + " cache: " + @checkClippedThroughBoundsCache
    #  #debugger

    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
      @checkClippedThroughBoundsCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
      @clippedThroughBoundsCache = Rectangle.EMPTY
      return @clippedThroughBoundsCache 

    @checkClippedThroughBoundsCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
    @clippedThroughBoundsCache = @boundingBox().intersect @clipThrough()
    return @clippedThroughBoundsCache
  
  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the "smallest broken rectangles"
  # which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  clipThrough: ->
    # answer which part of me is not clipped by a Frame
    if @ == Window
      debugger

    if @checkClipThroughCache == WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
      #console.log "cache hit @checkClipThroughCache"
      return @clipThroughCache
    #else
    #  console.log "cache miss @checkClipThroughCache"
    #  #console.log (WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes) + " cache: " + @checkClipThroughCache
    #  #debugger

    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
      @checkClipThroughCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
      @clipThroughCache = Rectangle.EMPTY
      return @clipThroughCache 

    firstFrameParent = @firstFrameParent()
    if !firstFrameParent?
      firstFrameParent = world
    firstFrameClipThroughBounds = firstFrameParent.clipThrough()
    @checkClipThroughCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
    if @ instanceof FrameMorph
      @clipThroughCache = @boundingBox().intersect firstFrameClipThroughBounds
    else
      @clipThroughCache = firstFrameClipThroughBounds


    return @clipThroughCache
  
  
  # Morph accessing - simple changes:
  fullRawMoveBy: (delta) ->
    if delta.isZero() then return
    # note that changed() is called two times
    # because there are two areas of the screens
    # that are dirty: the starting
    # position and the end position.
    # Both need to be repainted.
    #console.log "move 4"
    @breakNumberOfRawMovesAndResizesCaches()
    @bounds = @bounds.translateBy delta
    @children.forEach (child) ->
      child.fullRawMoveBy delta
    @changed()

  silentFullRawMoveBy: (delta) ->
    #console.log "move 5"
    @breakNumberOfRawMovesAndResizesCaches()
    @bounds = @bounds.translateBy delta
    @children.forEach (child) ->
      child.silentFullRawMoveBy delta
  
  breakNumberOfRawMovesAndResizesCaches: ->
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    if @ instanceof HandMorph
      if @children.length == 0
        return
    WorldMorph.numberOfRawMovesAndResizes++

  
  fullRawMoveTo: (aPoint) ->
    aPoint.debugIfFloats()
    delta = aPoint.toLocalCoordinatesOf @
    if !delta.isZero()
      #console.log "move 6"
      @breakNumberOfRawMovesAndResizesCaches()
      @fullRawMoveBy delta
    @bounds.debugIfFloats()

  fullMoveTo: (aPoint) ->
    if @layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING
      return
    else
      @invalidateLayout()
      @fullRawMoveTo arguments...
  
  silentFullRawMoveTo: (aPoint) ->
    #console.log "move 7"
    @breakNumberOfRawMovesAndResizesCaches()
    delta = aPoint.toLocalCoordinatesOf @
    @silentFullRawMoveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  fullRawMoveLeftSideTo: (x) ->
    @fullRawMoveTo new Point x, @top()
  
  fullRawMoveRightSideTo: (x) ->
    @fullRawMoveTo new Point x - @width(), @top()
  
  fullRawMoveTopSideTo: (y) ->
    @fullRawMoveTo new Point @left(), y
  
  fullRawMoveBottomSideTo: (y) ->
    @fullRawMoveTo new Point @left(), y - @height()
  
  fullRawMoveCenterTo: (aPoint) ->
    @fullRawMoveTo aPoint.subtract @extent().floorDivideBy 2
  
  fullRawMoveFullCenterTo: (aPoint) ->
    @fullRawMoveTo aPoint.subtract @fullBounds().extent().floorDivideBy 2
  
  # make sure I am completely within another Morph's bounds
  fullRawMoveWithin: (aMorph) ->
    leftOff = @fullBounds().left() - aMorph.left()
    @fullRawMoveBy new Point -leftOff, 0  if leftOff < 0
    rightOff = @fullBounds().right() - aMorph.right()
    @fullRawMoveBy new Point -rightOff, 0  if rightOff > 0
    topOff = @fullBounds().top() - aMorph.top()
    @fullRawMoveBy new Point 0, -topOff  if topOff < 0
    bottomOff = @fullBounds().bottom() - aMorph.bottom()
    @fullRawMoveBy new Point 0, -bottomOff  if bottomOff > 0


  notifyChildrenThatParentHasReLayouted: ->
    for child in @children.slice()
      child.parentHasReLayouted()

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
    @notifyChildrenThatParentHasReLayouted()

  layoutInset: (morphStartingTheChange = null) ->
    if @insetMorph?
      if @insetMorph != morphStartingTheChange
        @insetMorph.fullRawMoveTo @insetPosition()
        @insetMorph.rawSetExtent @insetSpaceExtent(), @
  
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

    for child in @children.slice()
      if morphStartingTheChange != child
        child.parentHasReLayouted()
  

  # do nothing in most cases but for example for
  # layouts, if something inside a layout wants to
  # change extent, then the whole layout might need to
  # change extent.
  childChangedExtent: (theMorphChangingTheExtent) ->
    if @insetMorph == theMorphChangingTheExtent
      @rawSetExtent @extentBasedOnInsetExtent(theMorphChangingTheExtent), theMorphChangingTheExtent

  # more complex Morphs, e.g. layouts, might
  # do a more complex calculation to get the
  # minimum extent
  getMinimumExtent: ->
    @minimumExtent

  setMinimumExtent: (@minimumExtent) ->

  # Morph accessing - dimensional changes requiring a complete redraw
  rawSetExtent: (aPoint, morphStartingTheChange = null) ->
    #console.log "move 8"
    if @ == morphStartingTheChange
      return
    if morphStartingTheChange == null
      morphStartingTheChange = @
    # check whether we are actually changing the extent.
    unless aPoint.eq @extent()
      @breakNumberOfRawMovesAndResizesCaches()

      @silentRawSetExtent aPoint
      @changed()
      @reLayout()
      
      @layoutSubmorphs morphStartingTheChange
      if @parent?
        if @parent != morphStartingTheChange
          @parent.childChangedExtent @

  # Morph accessing - dimensional changes requiring a complete redraw
  setExtent: (aPoint, morphStartingTheChange = null) ->
    if @layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING
      return
    else
      @invalidateLayout()
      @rawSetExtent arguments...

  
  silentRawSetExtent: (aPoint) ->
    aPoint = aPoint.round()
    #console.log "move 9"

    minExtent = @getMinimumExtent()
    if ! aPoint.ge minExtent
      aPoint = aPoint.max minExtent

    newWidth = Math.max aPoint.x, 0
    newHeight = Math.max aPoint.y, 0

    newBounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + newWidth, @bounds.origin.y + newHeight

    unless @bounds.eq newBounds
      @bounds = newBounds
      @breakNumberOfRawMovesAndResizesCaches()
  
  rawSetWidth: (width) ->
    #console.log "move 10"
    @breakNumberOfRawMovesAndResizesCaches()
    @rawSetExtent new Point(width or 0, @height())

  setWidth: (width) ->
    if @layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING
      return
    else
      @invalidateLayout()
      @rawSetWidth arguments...
  
  silentRawSetWidth: (width) ->
    #console.log "move 11"
    @breakNumberOfRawMovesAndResizesCaches()
    w = Math.max Math.round(width or 0), 0
    @bounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + w, @bounds.corner.y
  
  rawSetHeight: (height) ->
    #console.log "move 12"
    @breakNumberOfRawMovesAndResizesCaches()
    @rawSetExtent new Point(@width(), height or 0)

  setHeight: (height) ->
    if @layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING
      return
    else
      @invalidateLayout()
      @rawSetHeight arguments...

  
  silentRawSetHeight: (height) ->
    #console.log "move 13"
    @breakNumberOfRawMovesAndResizesCaches()
    h = Math.max Math.round(height or 0), 0
    @bounds = new Rectangle @bounds.origin, new Point @bounds.corner.x, @bounds.origin.y + h
  
  setColor: (aColorOrAMorphGivingAColor, morphGivingColor) ->
    if morphGivingColor?.getColor?
      aColor = morphGivingColor.getColor()
    else
      aColor = aColorOrAMorphGivingAColor
    if aColor
      unless @color.eq aColor
        @color = aColor
        @changed()
        
    return aColor
  
  setBackgroundColor: (aColorOrAMorphGivingAColor, morphGivingColor) ->
    if morphGivingColor?.getColor?
      aColor = morphGivingColor.getColor()
    else
      aColor = aColorOrAMorphGivingAColor
    if aColor
      unless @color.eq aColor
        @backgroundColor = aColor
        @changed()
        
    return aColor
  
  # Morph displaying ---------------------------------------------------------

  # There are three fundamental methods for rendering and displaying anything.
  # * updateBackBuffer: this one creates/updates the local canvas of this morph only
  #   i.e. not the children. For example: a ColorPickerMorph is a Morph which
  #   contains three children Morphs (a color palette, a greyscale palette and
  #   a feedback). The updateBackBuffer method of ColorPickerMorph only creates
  #   a canvas for the container Morph. So that's just a canvas with a
  #   solid color. As the
  #   ColorPickerMorph constructor runs, the three childredn Morphs will
  #   run their own updateBackBuffer method, so each child will have its own
  #   canvas with their own contents.
  #   Note that updateBackBuffer should be called sparingly. A morph should repaint
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

  # tiles the texture - never used in Fizzygum at the moment.
  drawCachedTexture: ->
    bg = @cachedTexture
    cols = Math.floor @backBuffer.width / bg.width
    lines = Math.floor @backBuffer.height / bg.height
    context = @backBuffer.getContext "2d"
    for y in [0..lines]
      for x in [0..cols]
        context.drawImage bg, Math.round(x * bg.width), Math.round(y * bg.height)
    @changed()
  
  
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

  turnOnHighlight: ->
    if !@highlighted
      @highlighted = true
      world.morphsToBeHighlighted.push @
      @changed()

  turnOffHighlight: ->
    if @highlighted
      @highlighted = false
      world.morphsToBeHighlighted.remove @
      @changed()


  # paintRectangle can work in two patterns:
  #  * passing actual pixels, when used
  #    outside the effect of the scope of
  #    "scale pixelRatio, pixelRatio", or
  #  * passing logical pixels, when used
  #    inside the effect of the scope of
  #    "scale pixelRatio, pixelRatio", or
  # Mostly, the first pattern is used.
  # Note that the resulting rectangle WILL reflect
  # if it's being painted as a shadow or not,
  # so it can't be used to paint on a backbuffer,
  # since you always want to paint on a backbuffer
  # "pristine", since the shadow effect is applied
  # when the backbuffer is in turn blitte to
  # screen, LATER.

  paintRectangle: (
    aContext,
    al, at, w, h,
    color,
    transparency = null,
    pushAndPopContext = false,
    appliedShadow
  ) ->

      if !color?
        return

      if pushAndPopContext
        aContext.save()

      aContext.fillStyle = color.toString()
      if transparency?
        aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * transparency

      aContext.fillRect  Math.round(al),
          Math.round(at),
          Math.round(w),
          Math.round(h)

      if pushAndPopContext
        aContext.restore()


  preliminaryCheckNothingToDraw: (clippingRectangle, aContext) ->

    if !@isVisible
      return true

    if clippingRectangle.isEmpty()
      return true

    if aContext == world.worldCanvasContext and @isOrphan()
      return true

    if aContext == world.worldCanvasContext and !@visibleBasedOnIsVisibleProperty()
      return true

    if aContext == world.worldCanvasContext and @isCollapsed()
      return true

    return false

  recordDrawnAreaForNextBrokenRects: ->
    if @childrenBoundsUpdatedAt < WorldMorph.frameCount
      @childrenBoundsUpdatedAt = WorldMorph.frameCount
      @clippedBoundsWhenLastPainted = @clippedThroughBounds()
      #if (@ != world) and (@clippedBoundsWhenLastPainted.containsPoint (new Point(10,10)))
      #  debugger
      @fullClippedBoundsWhenLastPainted = @fullClippedBounds()
      #if (@ != world) and (@fullClippedBoundsWhenLastPainted.containsPoint (new Point(10,10)))
      #  debugger
      #if (@ instanceof MenuMorph) and (@fullClippedBoundsWhenLastPainted.containsPoint (new Point(10,10)))
      #  debugger

  # in general, the children of a Morph could be outside the
  # bounds of the parent (they could also be much larger
  # then the parent). This means that we have to traverse
  # all the children to find out whether any of those overlap
  # the clipping rectangle. Note that we can be smarter with
  # FrameMorphs, as their children are actually all contained
  # within the parent's boundary.
  #
  # Note that if we could dynamically and cheaply keep an updated
  # fullBounds property, then we could be smarter
  # in discarding whole sections of the scene graph.
  # (see https://github.com/davidedc/Fizzygum/issues/150 )

  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # if there is a shadow "property" object
    # then first draw the shadow of the treee
    if @shadowInfo?
      @fullPaintIntoAreaOrBlitFromBackBufferJustShadow aContext, clippingRectangle, @shadowInfo

    # draw the proper contents of the tree
    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      if aContext == world.worldCanvasContext
        @recordDrawnAreaForNextBrokenRects()
      @fullPaintIntoAreaOrBlitFromBackBufferJustContent aContext, clippingRectangle, appliedShadow


  fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
    clippingRectangle = clippingRectangle.translateBy -@shadowInfo.offset.x, -@shadowInfo.offset.y

    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      aContext.save()
      aContext.translate @shadowInfo.offset.x, @shadowInfo.offset.y

      @fullPaintIntoAreaOrBlitFromBackBufferJustContent aContext, clippingRectangle, appliedShadow

      aContext.restore()
  

  fullPaintIntoAreaOrBlitFromBackBufferJustContent: (aContext, clippingRectangle, appliedShadow) ->
    @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    @children.forEach (child) ->
      child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow

  hide: ->
    @isVisible = false
    WorldMorph.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @

    # TODO refactor this, it appears more than one time
    # if the morph contributes to a shadow, unfortunately
    # we have to walk towards the top to
    # break the morph that has the shadow.
    # ALSO there are many other "@fullChanged" that really
    # should do this instead.
    firstParentOwningMyShadow = @firstParentOwningMyShadow()
    if firstParentOwningMyShadow?
      firstParentOwningMyShadow.fullChanged()
    else
      @fullChanged()


  show: ->
    if @isVisible
      return
    if @visibleBasedOnIsVisibleProperty() == true
      return
    @isVisible = true
    WorldMorph.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @

    firstParentOwningMyShadow = @firstParentOwningMyShadow()
    debugger
    if firstParentOwningMyShadow?
      firstParentOwningMyShadow.fullChanged()
    else
      @fullChanged()
  
  toggleVisibility: ->
    @isVisible = not @isVisible
    WorldMorph.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    @fullChanged()

  collapse: ->
    @collapsed = true
    WorldMorph.numberOfCollapseFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    @invalidateLayout()
    @fullChanged()

  unCollapse: ->
    if !@collapsed
      return
    if !@isCollapsed()
      return
    @collapsed = false
    WorldMorph.numberOfCollapseFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    @invalidateLayout()
    @fullChanged()

  
  isCollapsed: ->
    if @collapsed
      return true
    else
      if @parent?
        return @parent.isCollapsed()
      else
        return false
  
  removeFromTree: ->
    @parent?.invalidateLayout()
    @breakNumberOfRawMovesAndResizesCaches()
    WorldMorph.numberOfAddsAndRemoves++
    @parent.removeChild @
    @fullChanged()

  createPointerMorph: ->
    myPosition = @positionAmongSiblings()
    morphToAdd = new PointerMorph @
    @parent.add morphToAdd, myPosition
    morphToAdd.fullMoveTo @position()
    morphToAdd.setExtent new Point 150, 20
    morphToAdd.fullChanged()
    @removeFromTree()

    
  # Morph full image:
  # Fixes https://github.com/jmoenig/morphic.js/issues/7
  # and https://github.com/davidedc/Fizzygum/issues/160
  fullImage: (bounds, noShadow = false) ->
    if !bounds?
      bounds = @fullBounds()

    img = newCanvas bounds.extent().scaleBy pixelRatio
    ctx = img.getContext "2d"
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
    @fullPaintIntoAreaOrBlitFromBackBuffer ctx, bounds
    img

  fullImageNoShadow: ->
    boundsWithNoShadow = @fullBounds()
    return @fullImage boundsWithNoShadow, true

  fullImageData: ->
    # returns a string like "data:image/png;base64,iVBORw0KGgoAA..."
    # note that "image/png" below could be omitted as it's
    # the default, but leaving it here for clarity.
    @fullImage().toDataURL "image/png"

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
    return hashCode @fullImageData()
  
  
  isBeingFloatDragged: ->

    if !world.hand?
      return false

    # first check if the hand is floatdragging
    # anything, in that case if it's floatdragging
    # it can't be non-floatdragging
    if world.hand.nonFloatDraggedMorph?
      return false

    # then check if my root is the hand
    if @root() instanceof HandMorph
      return true

    # if we are here it means we are not being
    # nonfloatdragged
    return false

  # shadow is added to a morph by
  # the HandMorph while floatDragging
  addShadow: (offset = new Point(4, 4), alpha = 0.2) ->
    @silentAddShadow offset, alpha    
    @fullChanged()

  silentAddShadow: (offset, alpha) ->
    @shadowInfo = new ShadowInfo offset, alpha
  
  hasShadow: ->
    @shadowInfo?
  
  removeShadow: ->
    if @hasShadow()
      @shadowInfo = null
      @fullChanged()
  
  
  
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

      # you could check directly if it's in the array
      # but we use a flag because it's faster.
      if !@geometryOrPositionPossiblyChanged
        # if we already issued a fullChanged on this morph
        # then there is no point issuing a change too.
        if !@fullGeometryOrPositionPossiblyChanged
          window.morphsThatMaybeChangedGeometryOrPosition.push @
          @geometryOrPositionPossiblyChanged = true

    @parent.childChanged @  if @parent

  # to actually make sure if a morph has changed
  # position, you need to check it and all its
  # parents.
  # See comment on the fullGeometryOrPositionPossiblyChanged
  # property above for more info.
  hasMaybeChangedGeometryOrPosition: ->
    if @fullGeometryOrPositionPossiblyChanged or @geometryOrPositionPossiblyChanged
      return true
    else
      if @parent?
        return @parent.hasMaybeChangedGeometryOrPosition()
      else
        return false
  
  # See comment on the fullGeometryOrPositionPossiblyChanged
  # property above for more info.
  fullChanged: ->
    if trackChanges[trackChanges.length - 1]
      # check if we already issued a fullChanged on this morph
      if !@fullGeometryOrPositionPossiblyChanged
        window.morphsThatMaybeChangedFullGeometryOrPosition.push @
        @fullGeometryOrPositionPossiblyChanged = true
  
  childChanged: ->
    # react to a  change in one of my children,
    # default is to just pass this message on upwards
    # override this method for Morphs that need to adjust accordingly
    @parent.childChanged @  if @parent
  
  
  # Morph accessing - structure //////////////////////////////////////////////

  # EXPLANATION of "silent" vs. "raw" vs. "normal" hierarchy/bounds change methods
  # ------------------------------------------------------------------------------
  # “normal”: these are the highest-level methods and take into account layouts.
  #           Should use these ones as much as possible. Call the "raw"
  #           versions below
  # “raw”: lower level. This is what the re-layout routines use. Usually call the
  #        silent version below.
  # “silent”: doesn’t mark the morph as changed
  #
  # It's important that lower-level functions don't ever call the higher-level
  # functions, as that's architecturally incorrect and can cause infinite loops in
  # the invocations.

  imBeingAddedTo: (newParentMorph) ->
    @reLayout()

  addAsSiblingAfterMe: (aMorph, position = null, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING) ->
    myPosition = @positionAmongSiblings()
    @parent.add aMorph, (myPosition + 1), layoutSpec

  addAsSiblingBeforeMe: (aMorph, position = null, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING) ->
    myPosition = @positionAmongSiblings()
    @parent.add aMorph, myPosition, layoutSpec

  # this level of indirection is needed because
  # you have a "raw" "tree" need of adding stuff
  # and a higher level way to "add".
  # For example, a ScrollFrameMorph does a "high-level"
  # add of things in a different way, as it actually adds
  # stuff to a frame inside it. Hence a need to have
  # both a high-level and a low-level.
  # For most morphs the two things coincide, and the
  # high-level just calls the low-level.
  add: (aMorph, position = null, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING) ->
    if (aMorph not instanceof HighlighterMorph) and (aMorph not instanceof CaretMorph)
      if @ == world
        aMorph.addShadow()
      else
        aMorph.removeShadow()

    @addRaw arguments...
  
  # attaches submorph on top
  # ??? TODO you should handle the case of Morph
  #     being added to itself and the case of
  # ??? TODO a Morph being added to one of its
  #     children
  addRaw: (aMorph, position = null, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING) ->

    # let's check if we are trying to add
    # an ancestor of me below me.
    # That would be impossible to do,
    # so we return null to signal the error.
    if aMorph.isAncestorOf @
      return null

    aMorph.parent?.invalidateLayout()

    # if the morph contributes to a shadow, unfortunately
    # we have to walk towards the top to
    # break the morph that has the shadow.
    firstParentOwningMyShadow = aMorph.firstParentOwningMyShadow()
    if firstParentOwningMyShadow?
      firstParentOwningMyShadow.fullChanged()
    else
      aMorph.fullChanged()


    aMorph.layoutSpec = layoutSpec
    if layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING
      @invalidateLayout()

    aMorph.fullChanged()
    @silentAdd aMorph, true, position
    aMorph.imBeingAddedTo @
    return aMorph

  addInset: (aMorph) ->

    if aMorph.parent?
      aMorph.changed()

    @insetMorph = aMorph

    if @children.length > 0
      @add aMorph, 0
    else
      @add aMorph, 0

    aMorph.fullRawMoveTo @insetPosition()
    aMorph.rawSetExtent @insetSpaceExtent(), @


  sourceChanged: ->
    @reLayout?() 
    @changed?()


  # this is done before the updating of the
  # backing store in some morphs that
  # need to figure out their whole
  # layout (which depends on the children)
  # before painting themselves
  # e.g. the MenuMorph
  reLayout: ->


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
    if owner?
      owner.removeChild aMorph
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

  # in case we copy a morph, if the original was in some
  # data structures related to broken morphs, then
  # we have to add the copy too.
  alignCopiedMorphToBrokenInfoDataStructures: (copiedMorph) ->
    if window.morphsThatMaybeChangedGeometryOrPosition.indexOf(@) != -1 and
     window.morphsThatMaybeChangedGeometryOrPosition.indexOf(copiedMorph) == -1
      window.morphsThatMaybeChangedGeometryOrPosition.push copiedMorph

    if window.morphsThatMaybeChangedFullGeometryOrPosition.indexOf(@) != -1 and
     window.morphsThatMaybeChangedFullGeometryOrPosition.indexOf(copiedMorph) == -1
      window.morphsThatMaybeChangedFullGeometryOrPosition.push copiedMorph

  # in case we copy a morph, if the original was in some
  # stepping structures, then we have to add the copy too.
  alignCopiedMorphToSteppingStructures: (copiedMorph) ->
    if world.steppingMorphs.indexOf(@) != -1
      world.addSteppingMorph copiedMorph

  # note that the entire copying mechanism
  # should also take care of inserting the copied
  # morph in whatever other data structures where the
  # original morph was.
  # For example, if the Morph appeared in a data
  # structure related to the broken rectangles mechanism,
  # we should place the copied morph there.
  fullCopy: ()->
    allMorphsInStructure = @allChildrenBottomToTop()
    copiedMorph = @deepCopy false, [], [], allMorphsInStructure
    if copiedMorph instanceof MenuMorph
      copiedMorph.onClickOutsideMeOrAnyOfMyChildren null
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
    objectsSerializations = serializationString.split /^\/\/.*$/gm
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
        ctx = theClone.getContext "2d"

        image = new Image();
        image.src = eachObject.data
        # if something doesn't get painted here,
        # it might be because the allocation of the image
        # would actually be asynchronous, in theory
        # you'd have to do the drawImage in a callback
        # on onLoad of the image...
        ctx.drawImage image, 0, 0

      else if eachObject.constructor != Array
        theClone = Object.create namedClasses[eachObject.className]
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

  # Injecting code /////////////////////////////////////////

  # if a function, the txt must contain the parameters and
  # the arrow and the body
  injectProperty: (propertyName, txt) ->
    try
      # this.target[propertyName] = evaluate txt
      @evaluateString "@" + propertyName + " = " + txt
      # if we are saving a function, we'd like to
      # keep the source code so we can edit Coffeescript
      # again.
      if isFunction @[propertyName]
        @[propertyName + "_source"] = txt
      @sourceChanged()
    catch err
      @inform err

  injectProperties: (codeBlurb) ->

    codeBlurb = codeBlurb.replace(/^[ \t]*$/gm,"\n")
    codeBlurb = codeBlurb + "\n# end injected code"

    # ([a-zA-Z_$][0-9a-zA-Z_$]*) is the variable name
    regex = /^([a-zA-Z_$][0-9a-zA-Z_$]*)[ \t]*=[ \t]*([^]*?)(?=^[\w#$])/gm

    while (m = regex.exec(codeBlurb)) != null
      # This is necessary to avoid infinite loops with zero-width matches
      if m.index == regex.lastIndex
        regex.lastIndex++
      # The result can be accessed through the `m`-variable.
      #m.forEach (match, groupIndex) ->
      #  console.log ''
      @injectProperty m[1],m[2]
  
  # Morph floatDragging and dropping /////////////////////////////////////////
  
  isFloatDraggable: ->
    if @parent?

      # an instance of ScrollFrameMorph is also an instance of FrameMorph
      # so gotta do this check first ahead of next paragraph.
      maybeScrollFrameMorphAncestor = @parentThatIsA ScrollFrameMorph
      if maybeScrollFrameMorphAncestor?
        maybeScrollFrameMorphAncestor = maybeScrollFrameMorphAncestor[0]
        if maybeScrollFrameMorphAncestor.canScrollByDraggingForeground and
        maybeScrollFrameMorphAncestor.anyScrollBarShowing()
          return false
        else
          return true

      if (@parent instanceof WorldMorph) or (@parent instanceof FrameMorph)
        return true
    return false

  rootForGrab: ->
    if @parent is null or
      @parent instanceof WorldMorph or
      ((@parent instanceof FrameMorph) and !(@parent instanceof ScrollFrameMorph))
        return @  
    @parent.rootForGrab()

  # the only trick here is that we stop at the first
  # clipping morph, because if a morph is inside a clipping
  # morph, it doesn't contribute to any shadow.
  firstParentOwningMyShadow: ->
    if @hasShadow()
      return @

    scanningMorphs = @
    while scanningMorphs.parent?
      scanningMorphs = scanningMorphs.parent
      # TODO actually stop at the first
      # CLIPPING morph (more generic), not
      # just a FrameMorph
      if scanningMorphs instanceof FrameMorph
        return null
      if scanningMorphs.hasShadow()
        return scanningMorphs

    return null


  # finds the first parent that is a menu
  firstParentThatIsAMenu: ->
    scanningMorphs = @
    while scanningMorphs.parent?
      scanningMorphs = scanningMorphs.parent
      if scanningMorphs instanceof MenuMorph
        if !scanningMorphs.isMarkedForDestruction
          return scanningMorphs
    return scanningMorphs

    if @parent is null or
      @parent instanceof WorldMorph
        return @  
    @parent.rootForFocus()

  rootForFocus: ->
    if @parent is null or
      @parent instanceof WorldMorph
        return @  
    @parent.rootForFocus()

  moveInFrontOfSiblings: ->
    @moveAsLastChild()
    @fullChanged()

  bringToForegroud: ->
    @rootForFocus()?.moveAsLastChild()
    @rootForFocus()?.fullChanged()

  propagateKillMenus: ->
    if @parent?
      @parent.propagateKillMenus()

  mouseDownLeft: (pos) ->
    @bringToForegroud()
    @escalateEvent "mouseDownLeft", pos

  mouseClickLeft: (pos) ->
    @escalateEvent "mouseClickLeft", pos

  onClickOutsideMeOrAnyOfMyChildren: (functionName, arg1, arg2, arg3)->
    if functionName?
      @clickOutsideMeOrAnyOfMeChildrenCallback = [functionName, arg1, arg2, arg3]
      if @ not in world.morphsDetectingClickOutsideMeOrAnyOfMeChildren
        world.morphsDetectingClickOutsideMeOrAnyOfMeChildren.push @
    else
      #console.log "****** onClickOutsideMeOrAnyOfMyChildren removing element"
      world.morphsDetectingClickOutsideMeOrAnyOfMeChildren.remove @

  justDropped: ->
    
  wantsDropOf: (aMorph) ->
    return @_acceptsDrops

  enableDrops: ->
    @_acceptsDrops = true

  disableDrops: ->
    @_acceptsDrops = false
  
  pickUp: ->
    world.hand.grab @
    @fullRawMoveTo world.hand.position().subtract @fullBounds().extent().floorDivideBy 2
  
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
        position: @position().subtract @parent.position()
      )
    null
  
  slideBackTo: (situation, steps = 5) ->
    pos = situation.origin.position().add situation.position
    xStep = -(@left() - pos.x) / steps
    yStep = -(@top() - pos.y) / steps
    stepCount = 0
    oldStep = @step
    oldFps = @fps
    @fps = 0
    world.addSteppingMorph @
    @step = =>
      @silentFullRawMoveBy new Point xStep, yStep
      @fullChanged()
      stepCount += 1
      if stepCount is steps
        situation.origin.add @
        situation.origin.reactToDropOf @  if situation.origin.reactToDropOf
        @step = oldStep
        @fps = oldFps
        if @step == noOperation or !@step?
          world.removeSteppingMorph @
  
  
  # Morph utilities ////////////////////////////////////////////////////////
  
  showResizeAndMoveHandlesAndLayoutAdjusters: ->
    if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
      world.temporaryHandlesAndLayoutAdjusters.push new HandleMorph(@, "resizeHorizontalHandle")
      world.temporaryHandlesAndLayoutAdjusters.push new HandleMorph(@, "resizeVerticalHandle")
      world.temporaryHandlesAndLayoutAdjusters.push new HandleMorph(@, "moveHandle")
      world.temporaryHandlesAndLayoutAdjusters.push new HandleMorph(@, "resizeBothDimensionsHandle")
    else
      if (@lastSiblingBeforeMeSuchThat((m) -> m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED)?) and !@siblingBeforeMeIsA(StackElementsSizeAdjustingMorph)
        world.temporaryHandlesAndLayoutAdjusters.push \
          @addAsSiblingBeforeMe \
            new StackElementsSizeAdjustingMorph(),
            null,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

      #console.log "@: " + @.toString() + " amITheLastSibling: " + @amITheLastSibling()

      if (@firstSiblingAfterMeSuchThat((m) -> m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED)?) and !@siblingAfterMeIsA(StackElementsSizeAdjustingMorph)
        world.temporaryHandlesAndLayoutAdjusters.push \
          @addAsSiblingAfterMe \
            new StackElementsSizeAdjustingMorph(),
            null,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
      if @parent?
        @parent.showResizeAndMoveHandlesAndLayoutAdjusters()
  
  showMoveHandle: ->
    world.temporaryHandlesAndLayoutAdjusters.push new HandleMorph @, "moveHandle"
  
  hint: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph @, false, @, true, true, text
    m.popUpCenteredAtHand world
  
  inform: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuMorph @, false, @, true, true, text
    m.addMenuItem "Ok"
    m.popUpCenteredAtHand world

  prompt: (msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded) ->

    prompt = new PromptMorph(@, msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded)

    prompt.popUpAtHand()
    prompt.tempPromptEntryField.text.edit()

  textPrompt: (msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded) ->

    prompt = new TextPromptMorph(msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded)

    prompt.setExtent new Point 600,400

    world.add prompt
    prompt.fullMoveTo world.hand.position().subtract new Point 50, 100
    prompt.fullRawMoveWithin world

    #prompt.popUpAtHand()
    #prompt.tempPromptEntryField.edit()

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
    colorPicker = new ColorPickerMorph defaultContents
    menu = new MenuMorph @, false, @, true, true, msg or "", colorPicker
    menu.silentAdd colorPicker
    menu.addLine 2
    menu.addMenuItem "Ok", true, @, callback

    menu.addMenuItem "Cancel", true, @, ""

    menu.popUpAtHand()

  inspect: (anotherObject) ->
    @spawnInspector @

  inspect2: (anotherObject) ->
    @spawnInspector2 @

  spawnInspector: (inspectee) ->
    inspector = new InspectorMorph inspectee
    inspector.fullRawMoveTo world.hand.position()
    inspector.fullRawMoveWithin world
    world.add inspector
    inspector.changed()

  spawnInspector2: (inspectee) ->
    inspector = new InspectorMorph2 inspectee
    inspector.fullRawMoveTo world.hand.position()
    inspector.setExtent new Point 560, 410
    inspector.fullRawMoveWithin world
    world.add inspector
    inspector.changed()

  spawnNextTo: (morphToBeNextTo) ->
    morphToBeNextTo.parent.add @
    @fullRawMoveTo \
      morphToBeNextTo.topRight().translateBy new Point 5, -5
    @fullRawMoveWithin morphToBeNextTo.parent
    
  
  # Morph menus ////////////////////////////////////////////////////////////////
  
  # context Menus are whatever appears when one right-clicks
  # on something. It could be a custom menu, or the standard
  # menu on the desktop, or a menu to disambiguate which
  # morph it's being selected...
  contextMenu: ->    
    # commented-out addendum for the implementation of 1):
    #show the normal menu in case there is text selected,
    #otherwise show the spacial multiplexing list
    #if !@world().caret
    #  if @world().hand.allMorphsAtPointer().length > 2
    #    return @hierarchyMenu()
    if @customContextMenu
      return @customContextMenu()
    if world.isDevMode
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
    menu = new MenuMorph @, false, @, true, true, null
    # show an entry for each of the morphs in the hierarchy.
    # each entry will open the developer menu for each morph.
    parents.forEach (each) ->
      if (each.developersMenu) and (each isnt world) and (!each.anyParentMarkedForDestruction())
        textLabelForMorph = each.toString().slice 0, 50
        menu.addMenuItem textLabelForMorph + " ➜", false, each, "popupDeveloperMenu", null, null, null, null, null, null, null, true

    menu

  popupDeveloperMenu: (morphOpeningTheMenu)->
    @developersMenu(morphOpeningTheMenu).popUpAtHand()


  popUpColorSetter: ->
    @pickColor "color:", "setColor", new Color 0,0,0

  popup: (morphToAttachTo, pos) ->
    # console.log "menu popup"
    @silentFullRawMoveTo pos
    morphToAttachTo.add @
    # the @fullRawMoveWithin method
    # needs to know the extent of the morph
    # so it must be called after the morphToAttachTo.add
    # method. If you call before, there is
    # nopainting happening and the morph doesn't
    # know its extent.
    @fullRawMoveWithin world
    if AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    # shadow must be added after the morph
    # has been placed somewhere because
    # otherwise there is no visible image
    # to base the shadow on
    # P.S. this is the thing that causes the MenuMorph buffer
    # to be painted after the creation.
    @addShadow()
    @fullChanged()


  popUpAtHand: (morphToAttachTo)->
    if !morphToAttachTo?
      morphToAttachTo = world
    @popup morphToAttachTo, world.hand.position()

  transparencyPopout: (menuItem)->
    @prompt menuItem.parent.title + "\nalpha\nvalue:",
      @,
      "setAlphaScaled",
      (@alpha * 100).toString(),
      null,
      1,
      100,
      true

  createNewStringMorph2WithBackground: ->
    #newMorph = new StringMorph2 "Hello World! ⎲ƒ⎳⎷ ⎸⎹ aaa",null,null,null,null,null,null,null, new Color(255, 255, 54), 0.5
    newMorph = new StringMorph2 "Hello World! ⎲ƒ⎳⎷ ⎸⎹ aaa",null,null,null,null,null,null,null, new Color(230, 230, 130), 1
    newMorph.isEditable = true
    world.create newMorph

  createNewStringMorph2WithoutBackground: ->
    newMorph = new StringMorph2 "Hello World! ⎲ƒ⎳⎷ ⎸⎹ aaa"
    newMorph.isEditable = true
    world.create newMorph

  createNewTextMorph2WithBackground: ->
    newMorph = new TextMorph2(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "lectus posuere a. Phasellus finibus blandit ex vitae " +
      "varius. Vestibulum blandit velit elementum, ornare " +
      "ipsum sollicitudin, blandit nunc. Mauris a sapien " +
      "nibh. Nulla nec bibendum quam, eu condimentum nisl. " +
      "Cras consequat efficitur nisi sed ornare. " +
      "Pellentesque vitae urna vitae libero malesuada " +
      "pharetra." +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "ex dui a velit. Nullam lectus leo, lobortis eget " +
      "erat ac, lobortis dignissim magna. Morbi ac odio " +
      "in purus blandit dignissim. Maecenas at sagittis " +
      "odio. Suspendisse tempus mattis erat id euismod. " +
      "Duis semper mauris nec odio sagittis vulputate. " +
      "Praesent varius ac erat id fringilla. Suspendisse " +
      "porta sollicitudin bibendum. Pellentesque imperdiet " +
      "at eros nec euismod. Etiam ac mattis odio, ac finibus " +
      "nisi.",null,null,null,null,null,new Color(230, 230, 130), 1)
    newMorph.isEditable = true
    #newMorph.maxTextWidth = 300
    world.create newMorph

  createNewTextMorph3WithBackground: ->
    newMorph = new TextMorph3(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "lectus posuere a. Phasellus finibus blandit ex vitae " +
      "varius. Vestibulum blandit velit elementum, ornare " +
      "ipsum sollicitudin, blandit nunc. Mauris a sapien " +
      "nibh. Nulla nec bibendum quam, eu condimentum nisl. " +
      "Cras consequat efficitur nisi sed ornare. " +
      "Pellentesque vitae urna vitae libero malesuada " +
      "pharetra." +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "ex dui a velit. Nullam lectus leo, lobortis eget " +
      "erat ac, lobortis dignissim magna. Morbi ac odio " +
      "in purus blandit dignissim. Maecenas at sagittis " +
      "odio. Suspendisse tempus mattis erat id euismod. " +
      "Duis semper mauris nec odio sagittis vulputate. " +
      "Praesent varius ac erat id fringilla. Suspendisse " +
      "porta sollicitudin bibendum. Pellentesque imperdiet " +
      "at eros nec euismod. Etiam ac mattis odio, ac finibus " +
      "nisi.",null,null,null,null,null,new Color(255, 255, 54), 0.5)
    newMorph.isEditable = true
    #newMorph.maxTextWidth = 300
    world.create newMorph

  createDestroyIconMorph: ->
    world.create new DestroyIconMorph()

  createUnderCarpetIconMorph: ->
    world.create new UnderCarpetIconMorph()

  createUncollapsedStateIconMorph: ->
    world.create new UncollapsedStateIconMorph()

  createCollapsedStateIconMorph: ->
    world.create new CollapsedStateIconMorph()

  createCloseIconButtonMorph: ->
    world.create new CloseIconButtonMorph()

  createScratchAreaIconMorph: ->
    world.create new ScratchAreaIconMorph()

  createFloraIconMorph: ->
    world.create new FloraIconMorph()

  createScooterIconMorph: ->
    world.create new ScooterIconMorph()

  createHeartIconMorph: ->
    world.create new HeartIconMorph()

  showOutputPins: (a,b,c,d) ->
    world.morphsToBePinouted.push b

  removeOutputPins: (a,b,c,d) ->
    world.morphsToBePinouted.remove b

  testMenu: (morphOpeningTheMenu,targetMorph)->
    debugger
    menu = new MenuMorph morphOpeningTheMenu,  false, targetMorph, true, true, null
    menu.addMenuItem "serialise morph to memory", true, targetMorph, "serialiseToMemory"
    menu.addMenuItem "deserialize from memory and attach to world", true, targetMorph, "deserialiseFromMemoryAndAttachToWorld"
    menu.addMenuItem "deserialize from memory and attach to hand", true, targetMorph, "deserialiseFromMemoryAndAttachToHand"
    menu.addMenuItem "attach with horizontal layout", true, @, "attachWithHorizLayout"
    menu.addMenuItem "make spacers transparent", true, @, "makeSpacersTransparent"
    menu.addMenuItem "make spacers opaque", true, @, "makeSpacersOpaque"
    menu.addMenuItem "show adders", true, @, "showAdders"
    menu.addMenuItem "remove adders", true, @, "removeAdders"
    menu.addMenuItem "StringMorph2 without background", true, @, "createNewStringMorph2WithoutBackground"
    menu.addMenuItem "StringMorph2 with background", true, @, "createNewStringMorph2WithBackground"
    menu.addMenuItem "TextMorph2 with background", true, @, "createNewTextMorph2WithBackground"
    menu.addMenuItem "TextMorph3 with background", true, @, "createNewTextMorph3WithBackground"
    if targetMorph in world.morphsToBePinouted
      menu.addMenuItem "remove output pins", true, @, "removeOutputPins"
    else
      menu.addMenuItem "show output pins", true, @, "showOutputPins"
    
    # unclear whether the "un-collapse" entry would ever be
    # visible.
    if targetMorph.collapsed
      menu.addMenuItem "un-collapse", true, @, "unCollapse"
    else
      menu.addMenuItem "collapse", true, @, "collapse"

    menu.addMenuItem "create pointer", true, @, "createPointerMorph"
    menu.addMenuItem "others ➜", false, @, "popUpSecondMenu", "others"


    menu.popUpAtHand()

  underTheCarpetIconAndText: ->
    world.create new UnderTheCarpetOpenerMorph()

  analogClock: ->
    world.create new AnalogClockMorph()

  popUpIconsMenu: (morphOpeningTheMenu) ->
    menu = new MenuMorph morphOpeningTheMenu,  false, @, true, true, "icons"
    menu.addMenuItem "Destroy icon", true, @, "createDestroyIconMorph"
    menu.addMenuItem "Under the carpet icon", true, @, "createUnderCarpetIconMorph"
    menu.addMenuItem "Collapsed state icon", true, @, "createCollapsedStateIconMorph"
    menu.addMenuItem "Uncollapsed state icon", true, @, "createUncollapsedStateIconMorph"
    menu.addMenuItem "Close icon", true, @, "createCloseIconButtonMorph"
    menu.addMenuItem "Scratch area icon", true, @, "createScratchAreaIconMorph"
    menu.addMenuItem "Flora icon", true, @, "createFloraIconMorph"
    menu.addMenuItem "Scooter icon", true, @, "createScooterIconMorph"
    menu.addMenuItem "Heart icon", true, @, "createHeartIconMorph"

    menu.popUpAtHand()

  popUpSecondMenu: (morphOpeningTheMenu) ->
    menu = new MenuMorph morphOpeningTheMenu,  false, @, true, true, "others"
    menu.addMenuItem "icons ➜", false, @, "popUpIconsMenu", "icons"
    menu.addMenuItem "under the carpet", true, @, "underTheCarpetIconAndText"
    menu.addMenuItem "analog clock", true, @, "analogClock"
    menu.addMenuItem "inspect 2", true, @, "inspect2", "open a window\non all properties"
    menu.addMenuItem "fizzytiles", true, menusHelper, "createFridgeMagnets"
    menu.addMenuItem "fizzypaint", true, menusHelper, "createReconfigurablePaint"
    menu.addMenuItem "simple button", true, menusHelper, "createSimpleButton"
    menu.addMenuItem "switch button", true, menusHelper, "createSwitchButtonMorph"
    

    menu.popUpAtHand()

  serialiseToMemory: ->
    world.lastSerializationString = @serialize()

  deserialiseFromMemoryAndAttachToHand: ->
    derezzedObject = world.deserialize world.lastSerializationString
    derezzedObject.pickUp()

  deserialiseFromMemoryAndAttachToWorld: ->
    derezzedObject = world.deserialize world.lastSerializationString
    world.add derezzedObject

  developersMenuOfMorph: (morphOpeningTheMenu) ->
    # 'name' is not an official property of a function, hence:
    userMenu = @userMenu() or (@parent and @parent.userMenu())
    menu = new MenuMorph(morphOpeningTheMenu, false, 
      @,
      true,
      true,
      @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])

    if window.location.href.contains "worldWithSystemTestHarness"
      menu.addMenuItem "color...", true, @, "popUpColorSetter" , "choose another color \nfor this morph"
      menu.addMenuItem "transparency...", true, @, "transparencyPopout", "set this morph's\nalpha value"
      menu.addMenuItem "resize/move...", true, @, "showResizeAndMoveHandlesAndLayoutAdjusters", "show a handle\nwhich can be floatDragged\nto change this morph's" + " extent"
      menu.addLine()
      menu.addMenuItem "duplicate", true, @, "duplicateMenuAction" , "make a copy\nand pick it up"
      menu.addMenuItem "pick up", true, @, "pickUp", "disattach and put \ninto the hand"
      menu.addMenuItem "attach...", true, @, "attach", "stick this morph\nto another one"
      menu.addMenuItem "move", true, @, "showMoveHandle", "show a handle\nwhich can be floatDragged\nto move this morph"
      menu.addMenuItem "inspect", true, @, "inspect", "open a window\non all properties"

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
        switch AutomatorRecorderAndPlayer.state
          when AutomatorRecorderAndPlayer.RECORDING
            # While recording a test, just trigger for
            # the takeScreenshot command to be recorded. 
            window.world.automatorRecorderAndPlayer.takeScreenshot @
          when AutomatorRecorderAndPlayer.PLAYING
            # While playing a test, this command puts the
            # screenshot of this morph in a special
            # variable of the system test runner.
            # The test runner will wait for this variable
            # to contain the morph screenshot before
            # doing the comparison as per command recorded
            # in the case above.
            window.world.automatorRecorderAndPlayer.imageDataOfAParticularMorph = @fullImageData()
          else
            # no system tests recording/playing ongoing,
            # just open new tab with image of morph.
            window.open @fullImageData()
      menu.addMenuItem "take pic", true, @, "takePic", "open a new window\nwith a picture of this morph"

      menu.addMenuItem "test menu ➜", false, @, "testMenu", "debugging and testing operations"

      menu.addLine()
      if @isFloatDraggable()
        menu.addMenuItem "lock", true, @, "toggleIsfloatDraggable", "make this morph\nunmovable"
      else
        menu.addMenuItem "unlock", true, @, "toggleIsfloatDraggable", "make this morph\nmovable"
      menu.addMenuItem "hide", true, @, "hide"
      menu.addMenuItem "delete", true, @, "fullDestroy"
    else
      menu.addMenuItem "color...", true, @, "popUpColorSetter" , "choose another color \nfor this morph"
      menu.addMenuItem "transparency...", true, @, "transparencyPopout", "set this morph's\nalpha value"
      menu.addMenuItem "resize/move...", true, @, "showResizeAndMoveHandlesAndLayoutAdjusters", "show a handle\nwhich can be floatDragged\nto change this morph's" + " extent"
      menu.addLine()
      menu.addMenuItem "duplicate", true, @, "duplicateMenuAction" , "make a copy\nand pick it up"
      menu.addMenuItem "pick up", true, @, "pickUp", "disattach and put \ninto the hand"
      menu.addMenuItem "attach...", true, @, "attach", "stick this morph\nto another one"
      menu.addMenuItem "inspect", true, @, "inspect2", "open a window\non all properties"
      menu.addLine()
      if @isFloatDraggable()
        menu.addMenuItem "lock", true, @, "toggleIsfloatDraggable", "make this morph\nunmovable"
      else
        menu.addMenuItem "unlock", true, @, "toggleIsfloatDraggable", "make this morph\nmovable"
      menu.addMenuItem "hide", true, @, "hide"
      menu.addMenuItem "delete", true, @, "fullDestroy"


    menu

  developersMenu: (morphOpeningTheMenu) ->
    menu = @developersMenuOfMorph(morphOpeningTheMenu)
    if @addShapeSpecificMenus?
      menu = @addShapeSpecificMenus menu
    menu

  userMenu: ->
    null  
  
  # Morph menu actions
  calculateAlphaScaled: (alpha) ->
    if typeof alpha is "number"
      unscaled = alpha / 100
      return Math.min Math.max(unscaled, 0.1), 1
    else
      newAlpha = parseFloat alpha
      unless isNaN newAlpha
        unscaled = newAlpha / 100
        return Math.min Math.max(unscaled, 0.1), 1

  setPadding: (paddingOrMorphGivingPadding, morphGivingPadding) ->
    if morphGivingPadding?.getValue?
      padding = morphGivingPadding.getValue()
    else
      padding = paddingOrMorphGivingPadding

    #console.log " >>>>>>>>>>>>> padding: " + padding
    #if padding == 1
    #  debugger
    if @paddingTop != padding or @paddingBottom != padding or @paddingLeft != padding or @paddingRight != padding
      @paddingTop = padding
      @paddingBottom = padding
      @paddingLeft = padding
      @paddingRight = padding
      @changed()

    return padding

  setPaddingTop: (paddingOrMorphGivingPadding, morphGivingPadding) ->
    if morphGivingPadding?.getValue?
      padding = morphGivingPadding.getValue()
    else
      padding = paddingOrMorphGivingPadding

    if padding
      unless @paddingTop == padding
        @paddingTop = padding
        @changed()

    return padding

  setPaddingBottom: (paddingOrMorphGivingPadding, morphGivingPadding) ->
    if morphGivingPadding?.getValue?
      padding = morphGivingPadding.getValue()
    else
      padding = paddingOrMorphGivingPadding

    if padding
      unless @paddingBottom == padding
        @paddingBottom = padding
        @changed()

    return padding

  setPaddingLeft: (paddingOrMorphGivingPadding, morphGivingPadding) ->
    if morphGivingPadding?.getValue?
      padding = morphGivingPadding.getValue()
    else
      padding = paddingOrMorphGivingPadding

    if padding
      unless @paddingLeft == padding
        @paddingLeft = padding
        @changed()

    return padding

  setPaddingRight: (paddingOrMorphGivingPadding, morphGivingPadding) ->
    if morphGivingPadding?.getValue?
      padding = morphGivingPadding.getValue()
    else
      padding = paddingOrMorphGivingPadding

    if padding
      unless @paddingRight == padding
        @paddingRight = padding
        @changed()

    return padding

  setAlphaScaled: (alphaOrMorphGivingAlpha, morphGivingAlpha) ->
    if morphGivingAlpha?.getValue?
      alpha = morphGivingAlpha.getValue()
    else
      alpha = alphaOrMorphGivingAlpha

    if alpha
      alpha = @calculateAlphaScaled alpha
      unless @alpha == alpha
        @alpha = alpha
        @changed()

    return alpha

  newParentChoice: (ignored, theMorphToBeAttached) ->
    # this is what happens when "each" is
    # selected: we attach the selected morph
    @add theMorphToBeAttached
    if @ instanceof ScrollFrameMorph
      @adjustContentsBounds()
      @adjustScrollBars()

  newParentChoiceWithHorizLayout: (ignored, theMorphToBeAttached) ->
    # this is what happens when "each" is
    # selected: we attach the selected morph
    @add theMorphToBeAttached, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    if @ instanceof ScrollFrameMorph
      @adjustContentsBounds()
      @adjustScrollBars()

  attach: ->
    choices = world.plausibleTargetAndDestinationMorphs @

    # my direct parent might be in the
    # options which is silly, leave that one out
    choicesExcludingParent = []
    choices.forEach (each) =>
      if each != @parent
        choicesExcludingParent.push each

    if choicesExcludingParent.length > 0
      menu = new MenuMorph @, false, @, true, true, "choose new parent:"
      choicesExcludingParent.forEach (each) =>
        menu.addMenuItem each.toString().slice(0, 50), true, each, "newParentChoice", null, null, null, null, null, null, null, true
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible morphs to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # morphs then show some kind of message.
      menu = new MenuMorph @, false, @, true, true, "no morphs to attach to"
    menu.popUpAtHand()

  attachWithHorizLayout: ->
    choices = world.plausibleTargetAndDestinationMorphs @

    # my direct parent might be in the
    # options which is silly, leave that one out
    choicesExcludingParent = []
    choices.forEach (each) =>
      if each != @parent
        choicesExcludingParent.push each

    if choicesExcludingParent.length > 0
      menu = new MenuMorph @, false, @, true, true, "choose new parent:"
      choicesExcludingParent.forEach (each) =>
        menu.addMenuItem each.toString().slice(0, 50), true, each, "newParentChoiceWithHorizLayout", null, null, null, null, null, null, null, true
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible morphs to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # morphs then show some kind of message.
      menu = new MenuMorph @, false, @, true, true, "no morphs to attach to"
    menu.popUpAtHand()
  
  # does nothing, keeping it for the peace of
  # some tests
  toggleIsfloatDraggable: ->
  #  # for context menu demo purposes
  #  @isfloatDraggable = not @isfloatDraggable
  
  colorSetters: ->
    # for context menu demo purposes
    ["color", "backgroundColor"]
  
  numericalSetters: ->
    # for context menu demo purposes
    list = ["fullRawMoveLeftSideTo", "fullRawMoveTopSideTo", "rawSetWidth", "rawSetHeight", "setAlphaScaled", "setPadding", "setPaddingTop", "setPaddingBottom", "setPaddingLeft", "setPaddingRight"]
    if @addShapeSpecificNumericalSetters?
      list = @addShapeSpecificNumericalSetters list
    list

  
  # Morph entry field tabbing //////////////////////////////////////////////
  
  allEntryFields: ->
    @collectAllChildrenBottomToTopSuchThat (each) ->
      each.isEditable and
      (each instanceof StringMorph or
        each instanceof StringMorph2 or
        each instanceof TextMorph)
  
  
  nextEntryField: (current) ->
    fields = @allEntryFields()
    idx = fields.indexOf current
    if idx isnt -1
      if fields.length > (idx + 1)
        return fields[idx + 1]
    return fields[0]
  
  previousEntryField: (current) ->
    fields = @allEntryFields()
    idx = fields.indexOf current
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
      result = eval CoffeeScript.compile code, {"bare":true}
      @reLayout()
      
      @changed()
    catch err
      @inform err
    result
  
  
  # Morph collision detection - not used anywhere at the moment ////////////////////////
  
  isTouching: (otherMorph) ->
    oImg = @overlappingImage otherMorph
    data = oImg.getContext("2d").getImageData(1, 1, oImg.width, oImg.height).data
    detect(data, (each) ->
      each isnt 0
    ) isnt null
  
  overlappingImage: (otherMorph) ->
    fb = @fullBounds()
    otherFb = otherMorph.fullBounds()
    oRect = fb.intersect(otherFb)
    oImg = newCanvas oRect.extent().scaleBy pixelRatio
    ctx = oImg.getContext "2d"
    ctx.scale pixelRatio, pixelRatio
    if oRect.width() < 1 or oRect.height() < 1
      return newCanvas (new Point 1, 1).scaleBy pixelRatio
    ctx.drawImage @fullImage(),
      Math.round(oRect.origin.x - fb.origin.x),
      Math.round(oRect.origin.y - fb.origin.y)
    ctx.globalCompositeOperation = "source-in"
    ctx.drawImage otherMorph.fullImage(),
      Math.round(otherFb.origin.x - oRect.origin.x),
      Math.round(otherFb.origin.y - oRect.origin.y)
    oImg


  # ------------------------------------------------------------------------------------
  # Layouts
  # ------------------------------------------------------------------------------------
  # So layouts in ZK work the following way:
  #  1) Any Morph can contain a number of other morphs
  #     according to a number of layouts *simultaneously*
  #     e.g. you can have two morphs being horizontally stacked
  #     and two other morphs being inset for example
  #  2) There is no need for an explicit special container. Any
  #     Morph can be a container when needed.
  #  3) The default attaching of Morphs to a Morph puts them
  #     under the effect of the most basic layout: the FREEFLOATING
  #     layout.
  #  3) A user can only do a high-level resize or move to a FREEFLOATING
  #     Morph. All other Morphs are under the effect of more complex
  #     layout strategies so they can't be moved willy nilly
  #     directly by the user via some high-level "resize" or "move"
  #     Control of size and placement can be done, but indirectly via other
  #     means below.
  #  4) You CAN control the size and location of Morphs under the
  #     effect of complex layouts, but only indirectly: by programmatically
  #     changing their layout spec properties.
  #  5) You CAN also manually control the size and location of Morphs
  #     under the effect of complex layouts by using special Adjusting
  #     Morphs, which are provided by the container, and give handles
  #     to manually control the content. These manual controls
  #     under the courtains go and programmatically modify the layout
  #     spec properties of the content.


  minWidth: 10
  desiredWidth: 20
  maxWidth: 100

  minHeight: 10
  desiredHeight: 20
  maxHeight: 100

  makeSpacersTransparent: ->
    for C in @children
      C.makeSpacersTransparent()

  makeSpacersOpaque: ->
    for C in @children
      C.makeSpacersOpaque()

  invalidateLayout: ->
    if @layoutIsValid
      window.morphsThatMaybeChangedLayout.push @
    @layoutIsValid = false
    if @parent?
      @parent.invalidateLayout()

  setMinAndMaxBoundsAndSpreadability: (minBounds, desiredBounds, spreadability = LayoutSpec.SPREADABILITY_MEDIUM) ->
    @minWidth = minBounds.x
    @minHeight = minBounds.y

    @desiredWidth = desiredBounds.x
    @desiredHeight = desiredBounds.y

    maxWidth = desiredBounds.x + spreadability * desiredBounds.x/100
    maxHeight = desiredBounds.y + spreadability * desiredBounds.y/100
    @setMaxDim new Point maxWidth, maxHeight

    @invalidateLayout()


  setMaxDim: (overridingMaxDim) ->

    ###
    currentMax = @getRecursiveMaxDim()
    ratio = currentMax.x / overridingMaxDim.x

    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        C.setMaxDim C.getRecursiveMaxDim().divideBy ratio
    ###


    @maxWidth = overridingMaxDim.x
    @maxHeight = overridingMaxDim.y

    @invalidateLayout()

  # if you use this paragraph, then
  # we have a system where you CAN easily resize things to any
  # size, so to have maximum flexibility we are not binding the
  # minimum of a container to the minimums of the contents.
  ###
  getDesiredDim: ->
    desiredDim = new Point @desiredWidth, @desiredHeight
    return desiredDim.min @getMaxDim()
  getMinDim: ->
    minDim = new Point @minWidth, @minHeight
    return minDim.min @getMaxDim()
  getMaxDim: ->
    maxDim = new Point @maxWidth, @maxHeight
    return maxDim
  ###

  # if you use this paragraph, then the container of further
  # layouts will have a minimum equal to the sum of minimums
  # of the contents.
  getDesiredDim: ->
    if @isCollapsed() then return new Point 0,0
    @getRecursiveDesiredDim()
  getMinDim: ->
    if @isCollapsed() then return new Point 0,0
    @getRecursiveMinDim()
  getMaxDim: ->
    if @isCollapsed() then return new Point 0,0
    maxDim = new Point @maxWidth, @maxHeight
    return maxDim.max @getDesiredDim()


  getRecursiveDesiredDim: ->
    if @isCollapsed() then return new Point 0,0
    
    # TBD the exact shape of @checkDesiredDimCache
    #if @checkDesiredDimCache
    #  return @desiredDimCache

    desiredWidth = null
    desiredHeight = null
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getDesiredDim()
        if !desiredWidth? then desiredWidth = 0
        desiredWidth += childSize.width()
        if desiredHeight < childSize.height()
          if !desiredHeight? then desiredHeight = 0
          desiredHeight = childSize.height()

    if !desiredWidth?
      desiredWidth = @desiredWidth

    if !desiredHeight?
      desiredHeight = @desiredHeight

    # TBD the exact shape of @checkDesiredDimCache
    @checkDesiredDimCache = true
    @desiredDimCache = new Point desiredWidth, desiredHeight

    return @desiredDimCache.min @getRecursiveMaxDim()


  getRecursiveMinDim: ->
    if @isCollapsed() then return new Point 0,0
    # TBD the exact shape of @checkMinDimCache
    #if @checkMinDimCache
    #  # the user might have forced the "desired" to
    #  # be smaller than the standard minimum set by
    #  # the widget
    #  return Math.min @minDimCache, @getRecursiveDesiredDim()

    minWidth = null
    minHeight = null
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getMinDim()
        minWidth += childSize.width()
        if minHeight < childSize.height()
          minHeight = childSize.height()

    if !minWidth?
      minWidth = @minWidth

    if !minHeight?
      minHeight = @minHeight

    # TBD the exact shape of @checkMinDimCache
    @checkMinDimCache = true
    @minDimCache = new Point minWidth, minHeight

    # the user might have forced the "desired" to
    # be smaller than the standard minimum set by
    # the widget
    return @minDimCache.min @getRecursiveMaxDim()

  getRecursiveMaxDim: ->
    if @isCollapsed() then return new Point 0,0

    # TBD the exact shape of @checkMaxDimCache
    #if @checkMaxDimCache
    #  # the user might have forced the "desired" to
    #  # be bigger than the standard maximum set by
    #  # the widget
    #  return Math.max @maxDimCache, @getRecursiveDesiredDim()

    maxWidth = null
    maxHeight = null
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getMaxDim()
        maxWidth += childSize.width()
        if maxHeight < childSize.height()
          maxHeight = childSize.height()

    if !maxWidth?
      maxWidth = @maxWidth

    if !maxHeight?
      maxHeight = @maxHeight

    # TBD the exact shape of @checkMaxDimCache
    @checkMaxDimCache = true
    @maxDimCache = new Point maxWidth, maxHeight

    # the user might have forced the "desired" to
    # be bigger than the standard maximum set by
    # the widget
    return @maxDimCache

  countOfChildrenToLayout: ->
    if @isCollapsed() then return 0
    count = 0
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED and
      !C.isCollapsed()
        count++
    return count

  doLayout: (newBoundsForThisLayout = @boundingBox()) ->
    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    #if (@ instanceof LayoutableMorph) and (newBoundsForThisLayout.eq @boundingBox())
    #  debugger

    # freefloating layouts never need
    # adjusting. We marked the @layoutIsValid
    # to false because it's an important breadcrumb
    # for finding the morphs that actually have a
    # layout to be recalculated but this Morph
    # now needs to do nothing.
    #if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
    #  @layoutIsValid = true
    #  return
    
    # todo should we do a fullChanged here?
    # rather than breaking what could be many
    # rectangles?

    # the fullRawMoveTo makes sure that all children
    # that are float-attached move together with the
    # morph.
    @fullRawMoveTo newBoundsForThisLayout.origin
    
    # bad kludge here but I think there will be more
    # of these as we move over to the new layouts, we'll
    # probably have split Morphs for the new layouts mechanism
    if @ instanceof TextMorph
      @rawSetBounds newBoundsForThisLayout
    else
      @rawSetExtent newBoundsForThisLayout.extent()

    if @countOfChildrenToLayout() == 0
      @layoutIsValid = true
      return

    @addOrRemoveAdders()


    min = @getRecursiveMinDim()
    desired = @getRecursiveDesiredDim()
    max = @getRecursiveMaxDim()
    
    # we are forced to be in a space smaller
    # than the minimum. We obey.
    if min.width() >= newBoundsForThisLayout.width()
      if @parent == world then console.log "case 1"
      # Give all children under minimum
      # this is unfortunate but
      # we don't want to rely on clipping what's
      # beyond the allocated space. Clipping
      # in this Morphic implementation has special
      # status and we don't want to meddle with
      # that.
      # example: if newBoundsForThisLayout.width() is 10 and min.width() is 50
      # then reductionFraction = 1/5 , i.e. all the minimums
      # will be further reduced to fit
      reductionFraction = newBoundsForThisLayout.width() / min.width()
      childLeft = newBoundsForThisLayout.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        childBounds = new Rectangle \
          childLeft,
          newBoundsForThisLayout.top(),
          childLeft + C.getMinDim().width() * reductionFraction,
          newBoundsForThisLayout.top() + newBoundsForThisLayout.height()
        childLeft += childBounds.width()
        C.doLayout childBounds

    # the min is within the bounds but the desired is just
    # equal or larger than the bounds.
    # give min to all and then what is left available
    # redistribute proportionally based on desired
    else if desired.width() >= newBoundsForThisLayout.width()
      if @parent == world then console.log "case 2"
      desiredMargin = desired.width() - min.width()
      if desiredMargin != 0
        fraction = (newBoundsForThisLayout.width() - min.width()) / desiredMargin
      else
        fraction = 0      
      childLeft = newBoundsForThisLayout.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        minWidth = C.getMinDim().width()
        desWidth = C.getDesiredDim().width()
        childBounds = new Rectangle \
          childLeft,
          newBoundsForThisLayout.top(),
          childLeft + minWidth + (desWidth - minWidth) * fraction,
          newBoundsForThisLayout.top() + newBoundsForThisLayout.height()
        childLeft += childBounds.width()
        C.doLayout childBounds

    # min and desired are strictly less than the bounds
    # hence we have more space than needed,
    # allocate all the desired spaces, and on top of that
    # give extra space based on maximum widths
    else
      maxMargin = max.width() - desired.width()
      totDesWidth = desired.width()
      maxWidth = null
      desWidth = null
      extraSpace = newBoundsForThisLayout.width() - desired.width()
      if extraSpace < 0
        alert "extraSpace is negative"
      if @parent == world then console.log "case 3 maxMargin: " + maxMargin

      if maxMargin > 0
        ssss = 0
      else if maxMargin == 0
        ssss = 1
      else
        alert "maxMargin negative"

      childLeft = newBoundsForThisLayout.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        maxWidth = C.getMaxDim().width()
        desWidth = C.getDesiredDim().width()
        if (maxWidth - desWidth) > 0
          xtra = extraSpace * ((maxWidth - desWidth)/maxMargin)
        else
          xtra = 0
        childBounds = new Rectangle \
          childLeft,
          newBoundsForThisLayout.top(),
          childLeft + desWidth + xtra + ssss * (newBoundsForThisLayout.width()-desired.width()) * (desWidth / totDesWidth),
          newBoundsForThisLayout.top() + newBoundsForThisLayout.height()
        childLeft += childBounds.width()
        if childLeft > newBoundsForThisLayout.right() + 5
          debugger
        C.doLayout childBounds

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

  removeAdders: ->
    @_showsAdders = false
    @invalidateLayout()

  showAdders: ->
    @_showsAdders = true
    if @children.length == 0
      @add \
        new LayoutElementAdderOrDropletMorph(),
        null,
        LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @invalidateLayout()

  addOrRemoveAdders: ->

    if !@_showsAdders
      allAddersToBeDestroyed =
        @collectAllChildrenBottomToTopSuchThat(
          (m) ->
            m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED and
            m instanceof LayoutElementAdderOrDropletMorph
        )
      for C in allAddersToBeDestroyed
        C.destroy()
      return

    if @children.length == 0
      @add \
        new LayoutElementAdderOrDropletMorph(),
        null,
        LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    while true
      leftToDo = @firstChildSuchThat(
        (m) ->
          if m.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            return false
          if m instanceof LayoutElementAdderOrDropletMorph
            return false
          debugger
          kkk = m.lastSiblingBeforeMeSuchThat(
              (mm) ->
                mm.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            )
          debugger
          if !kkk?
            return true
          if kkk instanceof LayoutElementAdderOrDropletMorph
            return false
          return true            
      )
      debugger
      if !leftToDo?
        break
      leftToDo.addAsSiblingBeforeMe \
            new LayoutElementAdderOrDropletMorph(),
            null,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    # this code is duplicate of the one above and is only needed for
    # adding the last adder/droplet.

    while true
      leftToDo = @firstChildSuchThat(
        (m) ->
          if m.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            return false
          if m instanceof LayoutElementAdderOrDropletMorph
            return false
          debugger
          kkk = m.firstSiblingAfterMeSuchThat(
              (mm) ->
                mm.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            )
          debugger
          if !kkk?
            return true
          if kkk instanceof LayoutElementAdderOrDropletMorph
            return false
          return true            
      )
      debugger
      if !leftToDo?
        break
      leftToDo.addAsSiblingAfterMe \
            new LayoutElementAdderOrDropletMorph(),
            null,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED



  @setupTestScreen1: ->

    ## draw some reference patterns to see the sizes

    for i in [0..5]
      lmHolder = new RectangleMorph()
      lmHolder.setExtent new Point 10 + i*10,10 + i*10
      lmHolder.fullRawMoveTo new Point 10 + 60 * i, 10 + 50 * 0

      world.add lmHolder

    # ----------------------------------------------

    lmHolder = new RectangleMorph()
    lmContent1 = new RectangleMorph()
    lmAdj = new StackElementsSizeAdjustingMorph()
    lmContent2 = new RectangleMorph()

    lmHolder.add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    lmContent1.setColor new Color 0, 255, 0
    lmContent2.setColor new Color 0, 0, 255

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), 2* LayoutSpec.SPREADABILITY_MEDIUM

    lmHolder.fullRawMoveTo new Point 10 + 60 * 0, 30 + 50 * 1

    world.add lmHolder
    new HandleMorph lmHolder 

    # ----------------------------------------------

    lmHolder = new RectangleMorph()
    lmContent1 = new RectangleMorph()
    lmAdj = new StackElementsSizeAdjustingMorph()
    lmContent2 = new RectangleMorph()

    lmHolder.add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    lmContent1.setColor new Color 0, 255, 0
    lmContent2.setColor new Color 0, 0, 255

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)

    lmHolder.fullRawMoveTo new Point 10 + 60 * 1, 30 + 50 * 1

    world.add lmHolder
    new HandleMorph lmHolder

    # ----------------------------------------------

    lmHolder = new RectangleMorph()
    lmContent1 = new RectangleMorph()
    lmAdj = new StackElementsSizeAdjustingMorph()
    lmContent2 = new RectangleMorph()
    lmContent3 = new RectangleMorph()

    lmHolder.add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    lmContent1.setColor new Color 0, 255, 0
    lmContent2.setColor new Color 0, 0, 255
    lmContent3.setColor new Color 255, 255, 0

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)

    lmHolder.fullRawMoveTo new Point 10 + 60 * 2, 30 + 50 * 1

    world.add lmHolder
    new HandleMorph lmHolder

    # ----------------------------------------------

    lmHolder = new RectangleMorph()
    lmContent1 = new RectangleMorph()
    lmAdj = new StackElementsSizeAdjustingMorph()
    lmContent2 = new RectangleMorph()
    lmAdj2 = new StackElementsSizeAdjustingMorph()
    lmContent3 = new RectangleMorph()

    lmHolder.add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    lmContent1.setColor new Color 0, 255, 0
    lmContent2.setColor new Color 0, 0, 255
    lmContent3.setColor new Color 255, 255, 0

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)

    lmHolder.fullRawMoveTo new Point 10 + 60 * 3, 30 + 50 * 1

    world.add lmHolder
    new HandleMorph lmHolder

    # ----------------------------------------------

    lmHolder = new RectangleMorph()

    lmSpacer1 = new LayoutSpacerMorph()
    lmAdj = new StackElementsSizeAdjustingMorph()
    lmContent1 = new RectangleMorph()
    lmAdj2 = new StackElementsSizeAdjustingMorph()
    lmContent2 = new RectangleMorph()
    lmAdj3 = new StackElementsSizeAdjustingMorph()
    lmContent3 = new RectangleMorph()
    lmAdj4 = new StackElementsSizeAdjustingMorph()
    lmSpacer2 = new LayoutSpacerMorph()

    lmHolder.add lmSpacer1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj4, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmSpacer2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    lmContent1.setColor new Color 0, 255, 0
    lmContent2.setColor new Color 0, 0, 255
    lmContent3.setColor new Color 255, 255, 0

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)

    lmHolder.fullRawMoveTo new Point 10 + 60 * 4, 30 + 50 * 1

    world.add lmHolder
    new HandleMorph lmHolder

    # ----------------------------------------------

    lmHolder = new RectangleMorph()

    lmSpacer1 = new LayoutSpacerMorph()
    lmAdj = new StackElementsSizeAdjustingMorph()
    lmContent1 = new RectangleMorph()
    lmAdj2 = new StackElementsSizeAdjustingMorph()
    lmContent2 = new RectangleMorph()
    lmAdj3 = new StackElementsSizeAdjustingMorph()
    lmContent3 = new RectangleMorph()
    lmAdj4 = new StackElementsSizeAdjustingMorph()
    lmSpacer2 = new LayoutSpacerMorph 2

    lmHolder.add lmSpacer1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj4, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmSpacer2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    lmContent1.setColor new Color 0, 255, 0
    lmContent2.setColor new Color 0, 0, 255
    lmContent3.setColor new Color 255, 255, 0

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)

    lmHolder.fullRawMoveTo new Point 10 + 60 * 5, 30 + 50 * 1

    world.add lmHolder
    new HandleMorph lmHolder

    # ----------------------------------------------

    lmHolder = new RectangleMorph()

    lmSpacer1 = new LayoutSpacerMorph()
    lmAdj = new StackElementsSizeAdjustingMorph()
    lmContent1 = new RectangleMorph()
    lmAdj2 = new StackElementsSizeAdjustingMorph()
    lmContent2 = new RectangleMorph()
    lmAdj3 = new StackElementsSizeAdjustingMorph()
    lmContent3 = new RectangleMorph()
    lmAdj4 = new StackElementsSizeAdjustingMorph()
    lmSpacer2 = new LayoutSpacerMorph 2

    lmHolder.add lmSpacer1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj4, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmSpacer2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    lmContent1.setColor new Color 0, 255, 0
    lmContent2.setColor new Color 0, 0, 255
    lmContent3.setColor new Color 255, 255, 0

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 60,60), LayoutSpec.SPREADABILITY_NONE
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 60,60)
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 60,60), 2 * LayoutSpec.SPREADABILITY_MEDIUM

    lmHolder.fullRawMoveTo new Point 10 + 60 * 6, 30 + 50 * 1

    world.add lmHolder
    new HandleMorph lmHolder

    # ----------------------------------------------

    lmHolder = new RectangleMorph()

    lmSpacer1 = new LayoutSpacerMorph()
    lmAdj = new StackElementsSizeAdjustingMorph()
    lmContent1 = new RectangleMorph()
    lmAdj2 = new StackElementsSizeAdjustingMorph()
    lmContent2 = new RectangleMorph()
    lmAdj3 = new StackElementsSizeAdjustingMorph()
    lmContent3 = new RectangleMorph()
    lmAdj4 = new StackElementsSizeAdjustingMorph()
    lmSpacer2 = new LayoutSpacerMorph 2

    lmHolder.add lmSpacer1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmContent3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmAdj4, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    lmHolder.add lmSpacer2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    lmContent1.setColor new Color 0, 255, 0
    lmContent2.setColor new Color 0, 0, 255
    lmContent3.setColor new Color 255, 255, 0

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30), LayoutSpec.SPREADABILITY_NONE
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30), LayoutSpec.SPREADABILITY_NONE
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30), LayoutSpec.SPREADABILITY_NONE

    lmHolder.fullRawMoveTo new Point 10 + 60 * 7, 30 + 50 * 1 

    world.add lmHolder
    new HandleMorph lmHolder