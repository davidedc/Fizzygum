# "Widget" is a more understandable name for the concept of "Morph"
# (from the Greek "shape" or "form"). A Widget is an interactive
# graphical object.
# (General information on the Morphic system
# can be found at http://wiki.squeak.org/squeak/30 )

# Widgets exist in a tree, rooted at a World or at the Hand.
# The widgets owns subwidgets. Widgets are drawn recursively;
# if a Widget has no owner it never gets drawn
# (but note that there are other ways to hide a Widget).

class Widget extends TreeNode

  @augmentWith DeepCopierMixin

  # we want to keep track of how many instances we have
  # of each Widget for a few reasons:
  # 1) it gives us an identifier for each Widget
  # 2) profiling
  # 3) generate a uniqueIDString that we can use
  #    for example for hashtables
  # each subclass of Widget has its own static
  # instancesCounter which starts from zero. First object
  # has instanceNumericID of 1.
  # instanceNumericID is initialised in the constructor.
  @instancesCounter: 0
  # see roundNumericIDsToNextThousand method for an
  # explanation of why we need to keep this extra
  # count
  @lastBuiltInstanceNumericID: 0
  instanceNumericID: 0

  appearance: nil

  dragsDropsAndEditingEnabled: true

  # we conveniently keep all geometry information
  # into a single property (a Rectangle). Only
  # a few geometry-related methods should directly
  # access this property.
  bounds: nil
  minimumExtent: nil
  color: Color.create 80, 80, 80
  strokeColor: nil
  texture: nil # optional url of a fill-image

  # unused
  #cachedTexture: nil # internal cache of actual bg image

  lastTime: nil
  # when you use the high-level geometry-change APIs
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it.
  # Here we store the desired extent and position.
  desiredExtent: nil
  desiredPosition: nil

  # 1: fully opaque, 0: fully transparent
  alpha: 1

  # the padding area of a widget is INSIDE a widget and
  # responds to mouse events.
  # The padding area should be empty, not drawn, except
  # for debugging or "interim painting" purposes such
  # as highlights.
  # The padding's purpose is to give the option to widgets
  # to accommodate for spacing between their contents and
  # their bounds, so to enable consecutive widgets to
  # have some spacing in between them.
  # Note that paddings of consecutive widgets do add up.
  # The padding area reacts to mouse events ONLY IF
  # it's filled with color. Otherwise, it doesn't.
  # This is consistent with the concept that Widgets only
  # react within their "filled" region.
  paddingTop: 0
  paddingBottom: 0
  paddingLeft: 0
  paddingRight: 0

  # backgroundColor and backgroundTransparency fill the
  # entire rectangular bounds of the widget.
  # I.e. they area they fill is not affected by the
  # padding or the actual design of the widget.
  backgroundColor: nil
  backgroundTransparency: 1

  # for a Widget, being visible and collapsed
  # are two separate things.
  # isVisible means that the widget is meant to show
  #  as empty or without any surface. BUT the widget
  #  will still take the usual space.
  # Collapsed means that the widget, whatever its
  #  content or appearance or design, is not drawn
  #  on the desktop AND it doesn't occupy any space.
  isVisible: true
  collapsed: false

  # if a widget is a "template" it means that
  # when you floatDrag it, it creates a copy of itself.
  # it's a nice shortcut instead of doing
  # right click and then "duplicate..."
  isTemplate: false
  _acceptsDrops: false
  noticesTransparentClick: false
  fps: 0

  # usually Widgets can be detached from Panels
  # by grabbing them (there are exceptions, for example
  # buttons don't stick to the world but stick to Panels,
  # widget that "select" based on dragging such as the colour palette).
  # However you can get them to stick to Panels (and the desktop)
  # by toggling this flag
  isLockingToPanels: false
  # even if a Widget is locked to its parent (which is
  # the default) or locks to Panels (because isLockingToPanels is
  # set to true), it could be STILL BE dragged
  # (if any of its parents is loose).
  #
  # Setting this flag prevents that: a Widget rejecting
  # a drag can never be part of a chain that is dragged.
  # An example is buttons that are part of a compound Widget
  # (such as the Inspector):
  # in those cases you can never drag the compound Widget by
  # dragging a button (because it is a common behaviour to
  # "drag away" from a button to avoid actioning it when one
  # mousedowns on it). (Note however that buttons on the desktop
  # are draggable).
  # Another example are widgets like the colour palette where
  # users can drag the mouse on them to pick a color: it would be
  # weird if that caused a drag of anything.
  defaultRejectDrags: false

  # if you place a menu construction function here,
  # it gets the priority over the normal context
  # menu. This is done for example in the Inspector
  # panes, where the context menu is about running the
  # code contained in the text panel, rather than
  # to fiddle with the properties of the text panel
  # itself.
  overridingContextMenu: nil

  # menu coalescing is useful when you want a "parent"
  # menu to take over the menus of their children.
  # This assumes that for certain widgets is OK to just exist
  # "in their whole" without letting the user obviously take it
  # apart or mess with its parts.
  #
  # The best example is scrollable text: when one right-clicks
  # on scrollable text, the menu OF THE SCROLLFRAME that
  # contains it takes over.
  #
  # Otherwise, without coalescing, there would FIRST be a
  # multiple-selection menu to spacially demultiplex which
  # widget is the one of interest
  # (the text widget, or the Panel, or the ScrollPanelWdgt?). And
  # if the user wanted to resize the scroll text, which Widget
  # would the user have to pick? It would be very confusing.
  #
  # Instead, in this example above, one can naturally
  # resize the ScrollPanel, or change its color, or delete it,
  # instead of operating on the text content.
  #
  # Note that, on the other side, for this to work the menu of
  # the ScrollPanelWdgt has to give menu entries "peeking" them
  # from the text widget it contains, e.g. to change the font size
  #
  # Note that this mechanism could be overridden for "advanced"
  # users who want to mangle with the sub-components of a scrollable
  # text
  takesOverAndCoalescesChildrensMenus: false

  onNextStep: nil # optional function to be run once. Not currently used in Fizzygum

  clickOutsideMeOrAnyOfMeChildrenCallback: [nil]

  textDescription: nil

  # note that not all the changed widgets have this flag set
  # because if a parent does a fullChanged, we don't set this
  # flag in the children. This is intentionally so,
  # as we don't want to navigate the children too many times.
  # If you want to know whether a widget has changed its
  # position, use the hasMaybeChangedGeometryOrPosition:
  # method instead, which looks at this flag (and another one).
  # See comment below on fullGeometryOrPositionPossiblyChanged
  # for more information.
  geometryOrPositionPossiblyChanged: false
  clippedBoundsWhenLastPainted: nil

  # you'd be tempted to check this flag to figure out
  # whether any widget has possibly changed position but
  # you can't. If a PARENT has done a fullChanged, the
  # children are NOT set this flag. This flag is set
  # only for the parent widget, and it's important that
  # it stays that way for how the mechanism for fleshing out
  # the broken rectangles works. We flesh out the rectangles
  # of the "fully broken" widgets separately looking at this
  # flag, and we remove the rectangles of the sub-widgets that
  # have a parent with this flag since we know that they are
  # already covered.
  # If you want to figure out whether a widget has changed,
  # use the hasMaybeChangedGeometryOrPosition: method,
  # which checks recursively with the parents both the
  # fullGeometryOrPositionPossiblyChanged flag and the
  # geometryOrPositionPossiblyChanged flag.
  # Another way of doing this is to mark with a special flag
  # all the widget that touch their bounds or positions, but
  # then it's sort of costly to un-set such flag in all such
  # widgets, as we'd have to keep the "changed" widgets in a special
  # array to do that. Seems quite a bit more work and complication,
  # so just use the method.
  fullGeometryOrPositionPossiblyChanged: false
  fullClippedBoundsWhenLastPainted: nil

  cachedFullBounds: nil
  childrenBoundsUpdatedAt: -1

  cachedFullClippedBounds: nil
  checkFullClippedBoundsCache: nil

  visibleBasedOnIsVisiblePropertyCache: nil
  checkVisibleBasedOnIsVisiblePropertyCache: ""

  clippedThroughBoundsCache: nil
  checkClippedThroughBoundsCache: ""

  clipThroughCache: nil
  checkClipThroughCache: nil

  srcBrokenRect: nil
  dstBrokenRect: nil

  layoutIsValid: true
  layoutSpec: LayoutSpec.ATTACHEDAS_FREEFLOATING
  layoutSpecDetails: nil

  _showsAdders: false

  highlighted: false
  # if this widget has the purpose of highlighting
  # another widget, then this field points to the
  # widget that this widget is supposed to highlight
  wdgtThisWdgtIsHighlighting: nil

  destroyed: false

  shadowInfo: nil

  # some widgets such as references are given a
  # default "computed" position on the screen.
  # As long as the user didn't manually
  # reposition them, then we keep giving them a
  # computed position. BUT as soon as the user manually
  # places them, then we quit giving the widget a
  # computed position and rather we stick with the
  # position the user gave.
  userMovedThisFromComputedPosition: false
  positionFractionalInHoldingPanel: nil
  wasPositionedSlightlyOutsidePanel: false

  connectionsCalculationToken: 0

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.THIS_ONE_I_HAVE_NOW , PreferredSize.THIS_ONE_I_HAVE_NOW, 1

  initialiseDefaultVerticalStackLayoutSpec: ->
    # use the existing VerticalStackLayoutSpec (if it's there)
    unless @layoutSpecDetails instanceof VerticalStackLayoutSpec
      @layoutSpecDetails = new VerticalStackLayoutSpec 1

  mouseClickRight: ->
    # you could bring up what you right-click,
    # however for example that's not how OSX works.
    # Perhaps this could be a system setting?
    #@bringToForeground()

    world.hand.openContextMenuAtPointer @

  getTextDescription: ->
    if @textDescription?
      #console.log "got name: " + @textDescription + "" + @constructor.name + " (adhoc description of widget)"
      return @textDescription + "" + (@constructor.name.replace "Wdgt", "") + " (adhoc description of widget)"
    else
      #console.log "got name: " + @constructor.name + " (class name)"
      return (@constructor.name.replace "Wdgt", "") + " (class name)"

  identifyViaTextLabel: ->
    myTextDescription = @getTextDescription()
    allCandidateWidgetsWithSameTextDescription =
      world.allChildrenTopToBottomSuchThat (m) ->
        m.getTextDescription() == myTextDescription

    position = allCandidateWidgetsWithSameTextDescription.indexOf @

    theLength = allCandidateWidgetsWithSameTextDescription.length
    #console.log [myTextDescription, position, theLength]
    return [myTextDescription, position, theLength]

  # »>> this part is excluded from the fizzygum homepage build
  setTextDescription: (@textDescription) ->
  # this part is excluded from the fizzygum homepage build <<«

  uniqueIDString: ->
    @widgetClassString() + "#" + @instanceNumericID

  widgetClassString: ->
    @constructor.name or @constructor.toString().split(" ")[1].split("(")[0]

  # »>> this part is excluded from the fizzygum homepage build
  @widgetFromUniqueIDString: (theUniqueID) ->
    result = world.topWdgtSuchThat (m) =>
      m.uniqueIDString() is theUniqueID
    if not result?
      alert "theUniqueID " + theUniqueID + " not found!"
    return result
  # this part is excluded from the fizzygum homepage build <<«

  assignUniqueID: ->
    @constructor.instancesCounter++
    @constructor.lastBuiltInstanceNumericID++
    @instanceNumericID = @constructor.lastBuiltInstanceNumericID

  # »>> this part is excluded from the fizzygum homepage build
  # some test commands specify widgets via
  # their uniqueIDString. This means that
  # if there is one more text widget anywhere during
  # the playback, for example because
  # one new menu item is added, then
  # all the subsequent IDs for the text widget will be off.
  # In order to sort that out, we occasionally re-align
  # the counts to the next 1000, so the next Widgets
  # being created will all be aligned and
  # minor discrepancies are ironed-out
  @roundNumericIDsToNextThousand: ->
    #console.log "@roundNumericIDsToNextThousand"
    # this if is because zero and multiples of 1000
    # don't go up to 1000
    if @lastBuiltInstanceNumericID % 1000 == 0
      @lastBuiltInstanceNumericID++
    @lastBuiltInstanceNumericID = 1000 * Math.ceil @lastBuiltInstanceNumericID / 1000
  # this part is excluded from the fizzygum homepage build <<«

  startCountdownForBubbleHelp: (contents) ->
    ToolTipWdgt.createInAWhileIfHandStillContainedInWidget @, contents

  constructor: ->
    super()
    @assignUniqueID()

    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED

    @bounds = Rectangle.EMPTY
    @minimumExtent = new Point 5,5

    @_commitBoundsAndNotify new Rectangle 0,0,50,40

    @lastTime = Date.now()
    # Note that we don't call
    # that's because the actual extending widget will probably
    # set more details of how it should look (e.g. size),
    # so we wait and we let the actual extending
    # widget to draw itself.

    # »>> this part is excluded from the fizzygum homepage build
    @setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
    # this part is excluded from the fizzygum homepage build <<«

  # this happens when the Widget's constructor runs
  # and also when the Widget is duplicated
  registerThisInstance: ->
    goingUpClassHierarchy = @constructor
    loop
      # __super__ will always get to Object,
      # which doesn't have the "instances" property
      if !goingUpClassHierarchy.instances?
        break
      goingUpClassHierarchy.instances.add @
      goingUpClassHierarchy = goingUpClassHierarchy.__super__.constructor

  # this happens when the Widget is destroyed
  unregisterThisInstance: ->
    # remove instance from the instances tracker
    # in the class. To see this: just create an
    # AnalogClockWdgt, see that
    # AnalogClockWdgt.instances has one
    # element. Then delete the clock, and see that the
    # tracker is now an empty array.
    goingUpClassHierarchy = @constructor
    loop
      # __super__ will always get to Object,
      # which doesn't have the "instances" property
      if !goingUpClassHierarchy.instances?
        break
      goingUpClassHierarchy.instances.delete @
      goingUpClassHierarchy = goingUpClassHierarchy.__super__.constructor


  isTransparentAt: (aPoint) ->
    @appearance?.isTransparentAt aPoint

  # useful for example when hovering over references
  # to widgets. Can only modify the rendering of a widget,
  # so any highlighting is only visible in the measure that
  # the widget is visible (as opposed to HighlighterWdgt being
  # used to highlight a widget)
  paintHighlight: (aContext, al, at, w, h) ->
    @appearance?.paintHighlight aContext, al, at, w, h

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @appearance?.paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow

  # painting strokes is a little delicate because they need to
  # be painted INSIDE the widget (otherwise a) adjacent widgets, of widgets
  # within a layout would make a mess and b) clipping widget would
  # present a problem).
  # Also, Panels are tricky
  # because they need to paint the strokes after they paint their
  # content (because the content could paint everywhere inside the
  # Panel).
  # If you are thinking that you could paint the stroke before
  # the contents, by just
  # painting the contents of the Panel slightly clipped "inside" the
  # border of the Panel, that could potentially work with enough
  # changes, but it would only be easy to do with rectangular Panels,
  # since clipping "on the inside" of a border of arbitrary shape is
  # not trivial, maybe you'd have to examine how the lines cross at
  # different angles to paint "inside" of the lines, looks very messy.
  # Much easier to just paint the stroke after the content.
  paintStroke: (aContext, clippingRectangle) ->
    if @appearance?
      if @appearance.paintStroke?
        @appearance.paintStroke aContext, clippingRectangle

  addShapeSpecificMenuItems: (menu) ->
    if @appearance?.addShapeSpecificMenuItems?
      return @appearance.addShapeSpecificMenuItems menu
    return menu


  addShapeSpecificNumericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    if !menuEntriesStrings?
      menuEntriesStrings = []
      functionNamesStrings = []

    if @appearance?.addShapeSpecificNumericalSetters?
      [menuEntriesStrings, functionNamesStrings] = @appearance.addShapeSpecificNumericalSetters menuEntriesStrings, functionNamesStrings
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  
  #
  #    damage list housekeeping
  #
  #	the world.trackChanges property of the Widget prototype is a Boolean switch
  #	that determines whether the World's damage list ('broken' rectangles)
  #	tracks changes. By default the switch is always on. If set to false,
  #	changes are not stored. This can be very useful for housekeeping of
  #	the damage list in situations where a large number of (sub-) widgets
  #	are changed more or less at once. Instead of keeping track of every
  #	single subwidget's changes tremendous performance improvements can be
  #	achieved by setting the world.trackChanges flag to false before propagating
  #	the layout changes, setting it to true again and then storing the full
  #	bounds of the surrounding widget.
  
  
  # Widget string representation: e.g. 'a Widget' or 'a Widget#2'
  toString: ->
    firstPart = "a "

    if Automator? and Automator.state != Automator.IDLE and Automator.hidingOfWidgetsNumberIDInLabels
      return firstPart + @widgetClassString()
    else
      return firstPart + @uniqueIDString()

  close: ->
    # SELF-SETTLE (single-mutation tier). _closeNoSettle re-homes me to the basement through the NON-settling
    # core _addLostWidgetNoSettle (-> _addInPseudoRandomPositionNoSettle -> _addNoSettle) and recurses
    # @parent._closeNoSettle(), so it reaches no public setter. Anchored on @ (the canonical wrap): I'm
    # attached at entry so the orphan guard passes, then the global flush re-lays-out my parent.
    @_settleLayoutsAfter => @_closeNoSettle()

  _closeNoSettle: ->

    # closing window content: also close the window
    # UNLESS we are an internal window, in such case
    # leave the parent one as is
    if !@isWindow?() and @parent?.isWindow?()
      # private chain: the core, not public close() -- we are already inside close()'s settle batch.
      @parent._closeNoSettle()
      return

    world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.delete @
    @parent?.childBeingClosed? @
    if world.basementWdgt?
      world.basementWdgt._addLostWidgetNoSettle @
    else
      world.inform "There is no\nbasement to go in!"

  closeFromContainerWindow: (containerWindow) ->
    containerWindow.close()
  
  # Widgets destroying ======
  # this is different from a widget being closed/deleted
  # when a widget is destroyed, it's removed from the stepping
  # list and marked as destroyed.
  # NOTE that the tree under this widget is kept intact,
  # so this widget could be duplicated and revived
  destroy: ->
    # SELF-SETTLE (single-mutation tier, the canonical wrap). _settleLayoutsAfter checks orphan at
    # the START (I'm still attached) then flushes globally, so my parent settles even though _destroyNoSettle
    # orphans me.
    # The one hook that rebuilds during destroy -- a window losing its @contents
    # (childBeingDestroyed -> resetToDefaultContents) -- is safe inside this _inLayoutMutation:
    # resetToDefaultContents rebuilds through the non-settling @_buildAndConnectChildrenNoSettle (not the
    # public self-settler), and the chrome it constructs adds to ORPHANS, which are exempt from the
    # flush-throw (see _settleLayoutsAfter's orphan guard). So nothing re-enters a settle mid-destroy.
    @_settleLayoutsAfter => @_destroyNoSettle()

  _destroyNoSettle: ->

    @parent?.childBeingDestroyed? @
    @unregisterThisInstance()
    world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.delete @
    world.keyboardEventsReceivers.delete @
    # TODO note that there might be other data structures that
    # reference this widget that should have that reference removed.
    # The duplication method deals with a similar situation, so you
    # should check that all the data structures that are updated
    # in the duplication method are also updated here.
    # Also, possibly you should have a similar pattern of updates
    # See the methods:
    #   alignCopiedWidgetToBrokenInfoDataStructures
    #   alignCopiedWidgetToSteppingStructures
    #   alignCopiedWidgetToReferenceTracker
    #   alignCopiedWidgetToKeyboardEventsReceiversSet

    @destroyed = true
    # FREEFLOATING-skip is centralized in _invalidateLayout(triggeringChild): passing @ lets the
    # parent skip when I'm freefloating (removing a freefloating child can't change the parent's
    # layout). Containers that MANAGE a freefloating child (e.g. LabelButton/MenuItem centring their
    # label) self-settle on the change itself (sizeToTextAndDisableFitting / setLabel), not here.
    @parent?._invalidateLayout(@)
    @__breakMoveResizeCaches()
    WorldWdgt.numberOfAddsAndRemoves++

    world.steppingWdgts.delete @

    # if there is anything being edited inside
    # what we are destroying, then also
    # stop editing -- through the NON-settling core, since _destroyNoSettle is a pure core that may run
    # under a layout flush (e.g. resetWorld / fullDestroyChildren): the public stopEditing tears the
    # caret down via fullDestroy (a self-settler) which would re-enter the flush and throw.
    if world.caret?
      if @isAncestorOf world.caret.target
        world._stopEditingNoSettle()

    # remove callback when user clicks outside
    # me or any of my children
    @onClickOutsideMeOrAnyOfMyChildren nil

    if @parent?
      previousParent = @parent
      # if the widget contributes to a shadow, unfortunately
      # we have to walk towards the top to
      # break the widget that has the shadow.
      firstParentOwningMyShadow = @firstParentOwningMyShadow()
      if firstParentOwningMyShadow?
        firstParentOwningMyShadow.fullChanged()
      else
        @fullChanged()

      previousParent.removeChild @
      if previousParent.childRemoved?
        previousParent.childRemoved @

    # in case I'm a destroy at the end of a fullDestroy,
    # the children array is already empty
    if @children.length != 0
      @children = []

    return nil
  
  # destroys the whole tree
  # from the bottom (leaf widgets, drawn on top
  # of everything) to the top
  fullDestroy: ->
    # SELF-SETTLE (single-mutation tier, the canonical wrap). _fullDestroyNoSettle is a PURE core (recurses
    # cores). Anchored on @: attached at entry so the orphan guard passes, then the global flush re-fits.
    @_settleLayoutsAfter => @_fullDestroyNoSettle()

  _fullDestroyNoSettle: ->
    WorldWdgt.numberOfAddsAndRemoves++
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    # core-to-core recursion (no public fullDestroy/destroy): a PURE core. The public fullDestroy
    # wrapper supplies the single settle, so _fullDestroyNoSettle is safe to call directly from another
    # private chain even under _inLayoutMutation (where the public destroy() would throw).
    until @children.length == 0
      @children[0]._fullDestroyNoSettle()
    @_destroyNoSettle()
    return nil

  closeChildren: ->
    WorldWdgt.numberOfAddsAndRemoves++
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    # bulk teardown through the non-settling core (see fullDestroyChildren): looping the public
    # self-settling close() would re-home + flush once PER child, and under the single-mutation tier
    # each immediate settle re-fits a half-emptied container. The caller settles once afterwards.
    until @children.length == 0
      @children[0]._closeNoSettle()
    return nil

  fullDestroyChildren: ->
    if @children.length == 0
      return

    WorldWdgt.numberOfAddsAndRemoves++
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    # Bulk teardown through the non-settling core, NOT the public self-settling fullDestroy(): looping
    # the public method would self-settle once PER child (O(children) flushes), and -- with fullDestroy
    # on the single-mutation tier -- each immediate settle re-fits a half-emptied container. Callers
    # (resetWorld / Inspector rebuild / video panes / basement) are reset/rebuild contexts that settle
    # once afterwards (or redraw an empty container), so no per-child flush is wanted.
    until @children.length == 0
      @children[0]._fullDestroyNoSettle()
    return nil

  isFreeFloating: ->
    @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING

  setLayoutSpec: (newLayoutSpec) ->
    if @layoutSpec == newLayoutSpec
      return

    @layoutSpec = newLayoutSpec

    # The resizing handle becomes visible/invisible
    # when the layout spec of the parent changes
    # (typically it's visible only when freefloating)
    # TODO unclear if we should rather have handles subscribe to the parent
    # layout change ??? What if there are multiple handles or they are
    # nested deeper?
    isThereAnHandle = @firstChildSuchThat (m) ->
      m instanceof HandleWdgt
    isThereAnHandle?.updateVisibility()


  # »>> this part is excluded from the fizzygum homepage build
  # not used within Fizzygum yet.
  nextSteps: (lst = []) ->
    nxt = lst.shift()
    if nxt
      @onNextStep = =>
        nxt.call @
        @nextSteps lst
  # this part is excluded from the fizzygum homepage build <<«
  
  # leaving this function as step means that the widget wants to do nothing
  # but the children *are* traversed and their step function is invoked.
  # If a Widget wants to do nothing and wants to prevent the children to be
  # traversed, then this function should be set to nil.
  step: noOperation
  
  
  # Widget accessing - geometry getting:
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
  
  # Widget accessing - geometry getting:
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

  rawResizeToWithoutSpacing: ->

  # Set my width and re-fit my height / children to it. The width->height POLICY is
  # POLYMORPHIC: shape-keepers override this WHOLE method (AnalogClockWdgt -> square,
  # KeepsRatioWhenInVerticalStackMixin -> ratio, the icons / Stretchable* -> their own
  # extent rule). The base just sets the width and lets a deferred-layout widget re-fit its
  # children. HOW that re-fit is triggered depends on WHETHER A LAYOUT PASS IS ALREADY RUNNING:
  #  - normally (from an event handler / the public-setter flush): @_invalidateLayout() --
  #    schedule the re-fit for the current frame's recalculateLayouts (the deferred path).
  #  - WHILE recalculateLayouts is running (a CONTAINER sizing this child from inside its own
  #    _reLayout / _positionAndResizeChildren -- Phase 3b's window/stack re-fit on the cycle):
  #    _invalidateLayout would, for a non-freefloating deferred-layout child, CLIMB back and
  #    re-dirty the container in the SAME pass -> the until-loop never converges. So settle
  #    this child IN PLACE with a synchronous @_reLayout() (no invalidate, no climb), making
  #    the container's _reLayout a FIXED POINT -- the same outcome ScrollPanelWdgt reaches via
  #    silent setters. (See docs/deferred-layout-refit-and-add-design.md, "Phase 3b -- Slice 2".)
  # RETURNS the RESULTING height (Path B de-read-back). A container re-fit that sizes a child this way
  # (WindowWdgt / SimpleVerticalStackPanelWdgt _positionAndResizeChildren) must NOT then read the child's
  # geometry back to learn its new height -- that synchronous mutate-then-read-back is exactly what forces
  # the container re-fit to stay on the synchronous seam (it broke C1; see
  # docs/softwrap-deferred-layout-conversion-plan.md §6b + docs/deferred-layout-OVERVIEW.md §5). Instead it
  # HANDS the height forward: read once HERE, at the source, immediately after the synchronous mutation (so
  # byte-equal to the caller's old `child.height()`), and returned. EVERY override must likewise return its
  # resulting height (the 8 overrides are the historical break point -- keep them in sync).
  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    @rawSetWidth newWidth
    if @implementsDeferredLayout()
      # raw setter: APPLY the re-fit now (synchronous _reLayout), never SCHEDULE it
      # (no _invalidateLayout). See task #17 -- low-level mutators must not schedule layout.
      @_reLayout()
    @height()

  # §4.1 pure measure -- the side-effect-free counterpart of rawSetWidthSizeHeightAccordingly above:
  # "what extent would I take at this available width?", computed WITHOUT mutating @bounds or firing the
  # re-fit seam, so a parent can MEASURE a child instead of sizing-it-then-reading-the-height-back. The
  # BASE default is for a widget whose height is INVARIANT under width (a plain box, an icon, a menu): its
  # height at any width is just its current height. Width->height-coupled widgets OVERRIDE it with their
  # real measure -- TextWdgt (wrapped-text height), SimpleVerticalStackPanelWdgt (Sigma of children's),
  # WindowWdgt (content + chrome), AnalogClockWdgt / KeepsRatioWhenInVerticalStackMixin (aspect). Reading
  # @height()/@width() here is allowed: those are STABLE applied geometry, NOT a mutate-then-read-back.
  preferredExtentForWidth: (availW) ->
    new Point (availW ? @width()), @height()

  # note that using this one, the children
  # widgets attached as floating don't move
  rawSetBounds: (newBounds) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    if @bounds.equals newBounds
      return

    unless @bounds.origin.equals newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @__breakMoveResizeCaches()
      @changed()

    @rawSetExtent newBounds.extent()

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  # ===== self-settling public geometry API (prototype, 2026-06-19) =====
  # A public geometry setter records the DESIRED change (@desired* + _invalidateLayout)
  # and then FLUSHES the layout (world.recalculateLayouts) before returning, so the
  # world's geometry is consistent between public calls -- the caller never needs a
  # "settle"/yield. (See docs/deferred-layout-16-macro-breakages.md.) Re-entrancy is
  # forbidden and THROWS: a public setter must not be called from within another
  # public setter (or a layout pass), which would flush more than once per logical
  # mutation. Calling several public setters in SEQUENCE is fine -- each completes,
  # flushing once, before the next begins.
  # The same wrapper also backs the public STRUCTURAL mutator add() (a tree
  # change re-fits layouts too), so it RETURNS the thunk's value -- those need to hand
  # back the added widget (see docs/deferred-layout-refit-and-add-design.md, D3).
  _settleLayoutsAfter: (coreThunk) ->
    # early world bootstrap: the `world` singleton isn't wired up yet, so there's
    # nothing to flush to -- just record the desired change; the first frame settles it.
    unless world?
      return coreThunk()
    # ORPHAN guard -- MUST precede the flow-violation throw below. A widget attached to neither the
    # world nor the hand is not part of the live layout, so a public setter on it cannot corrupt a
    # flush/pass in progress: it just records the change and settles for real when the finished widget
    # is added to the world. This is what makes CONSTRUCTION safe inside another mutation's settle -- a
    # constructor that builds its innards via add() (e.g. the icon buttons WindowWdgt.buildAndConnect
    # Children makes) adds to an orphan, and must DEFER, not throw. (isOrphan() is false for the world
    # itself and for anything on the hand, so world.add / dragged-widget mutations still reach the throw
    # + flush below.) See docs/deferred-layout-refit-and-add-design.md (D3).
    if @isOrphan()
      return coreThunk()
    # A public geometry setter reached on an ATTACHED widget while a flush or a layout pass is already
    # in progress is a flow-soundness violation: internal layout (_reLayout / _reLayoutSelf / ...) must
    # use the raw/silent setters, never the public deferred API -- otherwise recalculateLayouts would
    # re-enter. THROW so the violation is found and fixed. The static gate buildSystem/check-layering.js
    # catches the name-recognized internal methods at BUILD time -- [A] the public geometry/text setters,
    # [G] the structural self-settling wrappers (destroy/close/fullDestroy/...). This runtime backstop
    # still covers what the name-scanner CANNOT: a structural add() (its name collides with Point#add, so
    # [G] excludes it) and any wrapper reached TRANSITIVELY or via a dynamically-typed receiver.
    if world._inLayoutMutation or world._recalculatingLayouts
      throw new Error "Fizzygum: a public geometry setter was reached during a layout flush/pass -- internal layout code (_reLayout / _reLayoutSelf / ...) must use the raw/silent setters, not the public deferred API (see buildSystem/check-layering.js)."
    # BATCH guard: inside _settleLayoutsAfterBatch, DEFER the per-mutation flush -- the batch
    # does ONE settle at the end. This turns O(N) relayouts (building N children, each add
    # self-settling) into 1, and -- crucially -- stops a mid-build settle from re-fitting a
    # HALF-WIRED widget (e.g. a window whose contents' layoutSpec.stack isn't set yet, which
    # crashes the deferred re-fit in getWidthInStack). See _settleLayoutsAfterBatch. (Phase 3b.)
    if world._batchingLayoutSettling
      return coreThunk()
    world._inLayoutMutation = true
    try
      result = coreThunk()
      world.recalculateLayouts()
      return result
    finally
      world._inLayoutMutation = false

  # ⚠ CURRENTLY UNUSED (0 callers) — RETAINED as an available performance primitive, NOT dead-to-delete
  # (allowlisted in buildSystem/dead-method-allowlist.txt). The drag/drop gesture (ActivePointerWdgt.drop,
  # 61f527f0) and sizeToTextAndDisableFitting both moved to a SINGLE settle over non-settling cores, which
  # removed the last batch call-sites. Kept because a future multi-add bundle may want ONE O(1) flush
  # instead of N self-settles; the `_batchingLayoutSettling` flag + the guard in _settleLayoutsAfter stay
  # wired so it works as-is if reintroduced.
  #
  # Run several geometry/structural mutations as a BATCH that settles layouts only ONCE, at
  # the end, instead of each public add()/setExtent() self-settling. Use it for multi-add
  # builders (buildAndConnectChildren) and bulk content insertion: it makes O(N) relayouts
  # into 1, and keeps the re-fit from running on a half-built widget mid-batch (the
  # getWidthInStack-on-unset-@stack crash during an in-world rebuild). Nestable -- an inner
  # batch is absorbed by the outer; mirrors _settleLayoutsAfter's orphan/re-entrancy
  # guards for the final flush. Returns the thunk's value. (Phase 3b.)
  _settleLayoutsAfterBatch: (thunk) ->
    unless world?
      return thunk()
    if world._batchingLayoutSettling
      return thunk()
    world._batchingLayoutSettling = true
    try
      result = thunk()
    finally
      world._batchingLayoutSettling = false
    unless @isOrphan() or world._inLayoutMutation or world._recalculatingLayouts
      world._inLayoutMutation = true
      try
        world.recalculateLayouts()
      finally
        world._inLayoutMutation = false
    result

  setBounds: (aRectangle, widgetStartingTheChange = nil) ->
    @_settleLayoutsAfter =>
      if not @isFreeFloating()
        return
      else
        aRectangle = aRectangle.round()

        newExtent = new Point aRectangle.width(), aRectangle.height()
        unless @extent().equals newExtent
          @desiredExtent = newExtent
          @_invalidateLayout()

        newPos = aRectangle.origin.copy()
        unless @position().equals newPos
          @desiredPosition = newPos
          @_invalidateLayout()

  _commitBoundsAndNotify: (newBounds) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    if @bounds.equals newBounds
      return

    unless @bounds.origin.equals newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @__breakMoveResizeCaches()

    @_commitExtentAndNotify newBounds.extent()
  
  # »>> this part is excluded from the fizzygum homepage build
  # unused code
  corners: ->
    @bounds.corners()
  # this part is excluded from the fizzygum homepage build <<«
  
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

  positionFractionalInWidget: (theWidget) ->
    [relativeXPos, relativeYPos] = @positionPixelsInWidget theWidget
    fractionalXPos = relativeXPos / theWidget.width()
    fractionalYPos = relativeYPos / theWidget.height()
    return [fractionalXPos, fractionalYPos]

  extentFractionalInWidget: (theWidget) ->
    width = @width()
    height = @height()
    fractionalWidth = width / theWidget.width()
    fractionalHeight = height / theWidget.height()
    return [fractionalWidth, fractionalHeight]

  positionPixelsInWidget: (theWidget) ->
    relativePos = @position().toLocalCoordinatesOf theWidget
    return [relativePos.x, relativePos.y]
  
  extent: ->
    @bounds.extent()
  
  width: ->
    @bounds.width()

  # e.g. images can have a lot of spacing
  # around them, so here is a method to get
  # the width of the actual thing, ignoring all
  # the spacing that might be around
  widthWithoutSpacing: ->
    @width()
  
  height: ->
    @bounds.height()

  # »>> this part is excluded from the fizzygum homepage build
  # unused code
  cornersTight: ->
    [@topLeftTight(), @bottomLeftTight(), @bottomRightTight(), @topRightTight()]
  # this part is excluded from the fizzygum homepage build <<«
  
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
  # - to determine which widgets you can attach a widget to
  # - for a SliderWdgt's "set target" so you can change properties of another Widget
  # - by the HandleWdgt when you attach it to some other widget
  # Note that this method has a slightly different
  # version in PanelWdgt (because it clips, so we need
  # to check that we don't consider overlaps with
  # widgets contained in a Panel that are clipped and
  # hence *actually* not overlapping).
  plausibleTargetAndDestinationWidgets: (theWidget) ->
    # find if I intersect theWidget,
    # then check my children recursively
    # exclude me if I'm a child of theWidget
    # (cause it's usually odd to attach a Widget
    # to one of its subwidgets or for it to
    # control the properties of one of its subwidgets)
    result = []
    if @visibleBasedOnIsVisibleProperty() and
        !@isInCollapsedSubtree() and
        !theWidget.isAncestorOf(@) and
        @areBoundsIntersecting(theWidget) and
        !@anyParentPopUpMarkedForClosure()
      result = [@]

    @children.forEach (child) ->
      result = result.concat(child.plausibleTargetAndDestinationWidgets(theWidget))

    return result


  # both methods invoked in here
  # are cached
  # used in the method fleshOutBroken
  # to skip the "destination" broken rects
  # for widgets that marked themselves
  # as broken but at moment of destination
  # might be invisible
  # TODO for sure this should also check for the .destroyed flag
  surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage: ->
    if !@isVisible
      return true

    if @isOrphan()
      return true

    if !@visibleBasedOnIsVisibleProperty()
      return true

    if @isInCollapsedSubtree()
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
      @checkVisibleBasedOnIsVisiblePropertyCache = WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges
      @visibleBasedOnIsVisiblePropertyCache = false
      result = @visibleBasedOnIsVisiblePropertyCache
    else # @isVisible is true
      if !@parent?
        result = true
      else
        if @checkVisibleBasedOnIsVisiblePropertyCache == WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges
          #console.log "cache hit visibleBasedOnIsVisibleProperty"
          result = @visibleBasedOnIsVisiblePropertyCache
        else
          #console.log "cache miss visibleBasedOnIsVisibleProperty"
          @checkVisibleBasedOnIsVisiblePropertyCache = WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges
          @visibleBasedOnIsVisiblePropertyCache = @parent.visibleBasedOnIsVisibleProperty()
          result = @visibleBasedOnIsVisiblePropertyCache

    if world.doubleCheckCachedMethodsResults
      if result != @SLOWvisibleBasedOnIsVisibleProperty()
        debugger
        alert "visibleBasedOnIsVisibleProperty is broken"

    return result


  # Note that in a case of a fullMove*
  # you should also invalidate all the widgets in
  # the subtree as well.
  # This happens indirectly as the fullMove* methods
  # move all the children too, so *that*
  # invalidates them. Note that things might change
  # if you use a different coordinate system, in which
  # case you have to invalidate the caches in all the
  # subwidgets manually or use some other cache
  # invalidation mechanism.
  invalidateFullBoundsCache: ->
    if !@cachedFullBounds?
      return
    @cachedFullBounds = nil
    if @parent?.cachedFullBounds?
        @parent.invalidateFullBoundsCache @

  invalidateFullClippedBoundsCache: ->
    if !@checkFullClippedBoundsCache?
      return
    @checkFullClippedBoundsCache = nil
    if @parent?.checkFullClippedBoundsCache?
        @parent.invalidateFullClippedBoundsCache @


  # doesn't take into account orphanage
  # or visibility
  SLOWfullBounds: ->
    result = @bounds
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and
      !child.isInCollapsedSubtree()
        result = result.merge child.SLOWfullBounds()
    result

  SLOWfullClippedBounds: ->
    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      return Rectangle.EMPTY
    result = @clippedThroughBounds()
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and !child.isInCollapsedSubtree()
        result = result.merge child.SLOWfullClippedBounds()
    #if this != world and result.corner.x > 400 and result.corner.y > 100 and result.origin.x ==0 and result.origin.y ==0
    #  debugger
    result

  # for PanelWdgt scrolling support
  subWidgetsMergedFullBounds: ->
    result = nil
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        # we exclude the HandleWdgts because they
        # mangle how the Panel inside ScrollPanelWdgts
        # calculate their size when they are resized
        # (remember that the resizing handle of ScrollPanelWdgts
        # actually end up in the Panel inside them.)
        if !child.isLayoutInert?()
          # if a widget implements deferred layout, then
          # really we can't consider the sizes and positions
          # of its children, so stick to the parent bounds
          # only
          if child.implementsDeferredLayout()
            result = result.merge child.bounds
          else
            result = result.merge child.fullBounds()
    result

  # §4.1 Stage C (proper-layouts): the side-effect-free counterpart of subWidgetsMergedFullBounds above --
  # the merged bounds of my children with each child's SIZE taken from its pure preferredExtentForWidth
  # measure (min-extent-clamped, as _commitExtentAndNotify applies on commit) instead of its just-mutated applied
  # extent, at the child's current position. A scroll panel consumes this to size its content frame WITHOUT
  # first resizing my children and reading the result back -- the mutate-then-read-back the re-fit seam exists
  # for (assessment §2.4). Seeded IDENTICALLY to subWidgetsMergedFullBounds (child[0] even if inert) so a
  # leading inert child contributes the same; byte-identical to it at the fixed point, where measured extent
  # == applied extent (Stage-C probe: 0/1429 converged mismatches). childMeasureWidth = the width to measure
  # each child at (the caller subtracts its own padding). SimpleVerticalStackPanelWdgt overrides this to also
  # derive child POSITIONS from measures (its children's positions are layout-derived, not stable state).
  subWidgetsMergedPreferredBounds: (childMeasureWidth) ->
    result = nil
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        if !child.isLayoutInert?()
          measured = child.preferredExtentForWidth?(childMeasureWidth)
          ext = if measured? then measured else child.extent()
          minE = child.getMinimumExtent?()
          w = if minE? then Math.max(ext.x, minE.x) else ext.x
          h = if minE? then Math.max(ext.y, minE.y) else ext.y
          result = result.merge new Rectangle child.left(), child.top(), child.left() + w, child.top() + h
    result

  # does not take into account orphanage or visibility
  fullBounds: ->
    if @cachedFullBounds?
      if world.doubleCheckCachedMethodsResults
        if !@cachedFullBounds.equals @SLOWfullBounds()
          debugger
          alert "fullBounds is broken (cached)"
      return @cachedFullBounds

    result = @bounds
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and !child.isInCollapsedSubtree()
        result = result.merge child.fullBounds()

    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWfullBounds()
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
    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      result = Rectangle.EMPTY
    else
      if @checkFullClippedBoundsCache == WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
        if world.doubleCheckCachedMethodsResults
          if !@cachedFullClippedBounds.equals @SLOWfullClippedBounds()
            debugger
            alert "fullClippedBounds is broken"
        return @cachedFullClippedBounds

      # you'd be thinking this is the same as
      #   result = @fullBounds().intersect @clipThrough()
      # but it's not, because fullBounds doesn't
      # take into account orphanage and visibility

      result = @clippedThroughBounds()
      @children.forEach (child) ->
        if child.visibleBasedOnIsVisibleProperty() and !child.isInCollapsedSubtree()
          result = result.merge child.fullClippedBounds()

    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWfullClippedBounds()
        debugger
        alert "fullClippedBounds is broken"

    @checkFullClippedBoundsCache = WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
    @cachedFullClippedBounds = result
  
  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the smallest broken rectangle created by
  # a changed(), which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  clippedThroughBounds: ->

    if @checkClippedThroughBoundsCache == WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
      #console.log "cache hit @checkClippedThroughBoundsCache"
      return @clippedThroughBoundsCache
    #else
    #  console.log "cache miss @checkClippedThroughBoundsCache"
    #  #console.log (WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes) + " cache: " + @checkClippedThroughBoundsCache
    #  #debugger

    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      @checkClippedThroughBoundsCache = WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
      @clippedThroughBoundsCache = Rectangle.EMPTY
      return @clippedThroughBoundsCache

    @checkClippedThroughBoundsCache = WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
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
    # answer which part of me is not clipped by a Panel
    if @ == Window
      debugger

    if @checkClipThroughCache == WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
      #console.log "cache hit @checkClipThroughCache"
      return @clipThroughCache
    #else
    #  console.log "cache miss @checkClipThroughCache"
    #  #console.log (WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes) + " cache: " + @checkClipThroughCache
    #  #debugger

    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      @checkClipThroughCache = WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
      @clipThroughCache = Rectangle.EMPTY
      return @clipThroughCache

    firstParentClippingAtBounds = @firstParentClippingAtBounds()
    if !firstParentClippingAtBounds?
      firstParentClippingAtBounds = world
    firstParentClippingAtBoundsClipThroughBounds = firstParentClippingAtBounds.clipThrough()
    @checkClipThroughCache = WorldWdgt.numberOfAddsAndRemoves + "-" + WorldWdgt.numberOfVisibilityFlagsChanges + "-" + WorldWdgt.numberOfCollapseFlagsChanges + "-" + WorldWdgt.numberOfRawMovesAndResizes
    if @clipsAtRectangularBounds
      @clipThroughCache = @boundingBox().intersect firstParentClippingAtBoundsClipThroughBounds
    else
      @clipThroughCache = firstParentClippingAtBoundsClipThroughBounds


    return @clipThroughCache
  
  
  # Widget accessing - simple changes:
  # Translate me + my children + repaint, then fire the re-fit seam (Intent-1: notify the container tracking my
  # geometry to re-fit). The move body is shared with the NON-notifying arrange twin _applyMoveBy (below);
  # the seam fires iff I actually moved. (Byte-exact vs the prior in-the-middle seam fire: the seam only SCHEDULES
  # my container's re-fit -- reading my parent, not my children -- so firing it AFTER the children-translate rather
  # than before is geometry-identical, and the silent children-translate enqueues nothing in between.)
  fullRawMoveBy: (delta) ->
    @_reFitContainerAfterRawGeometryChange() if @_applyMoveBy delta

  # Non-notifying twins of fullRawMoveBy / fullRawMoveTo (§4.2 structural arrange-down): translate me + my children +
  # repaint WITHOUT firing the re-fit seam -- a container placing me top-down already knows my new position, so the
  # seam's Intent-2 self-re-enqueue is redundant. Used by the stack arrange for LEAF children (a leaf has no inner
  # convergence the move's re-enqueue would drive; a container child keeps the seam-firing fullRawMoveTo).
  # _applyMoveBy is fullRawMoveBy's shared core (returns true iff actually moved, so the wrapper fires the seam).
  _applyMoveBy: (delta) ->
    return false if delta.isZero()
    @__breakMoveResizeCaches()
    @fullChanged()
    @bounds = @bounds.translateBy delta
    @children.forEach (child) ->
      child.__commitMoveBy delta
    return true

  _applyMoveTo: (aPoint) ->
    aPoint.debugIfFloats()
    delta = aPoint.toLocalCoordinatesOf @
    if !delta.isZero()
      @__breakMoveResizeCaches()
      @_applyMoveBy delta
    @bounds.debugIfFloats()

  __commitMoveBy: (delta) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    #console.log "move 5"
    @__breakMoveResizeCaches()
    @bounds = @bounds.translateBy delta
    @children.forEach (child) ->
      child.__commitMoveBy delta
  
  __breakMoveResizeCaches: ->
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    if @ == world.hand
      if @children.length == 0
        return
    WorldWdgt.numberOfRawMovesAndResizes++

  # moving to fractional position within the desktop is
  # different from the case below because the desktop can be
  # resized to any ratio
  fullRawMoveInDesktopToFractionalPosition: (boundsOfParent) ->
    if !boundsOfParent?
      boundsOfParent = @parent.bounds

    # we do one dimension at a time here for a subtle reason: if
    # say a window has the left side beyond the left side of the desktop
    # then the x of positionFractionalInHoldingPanel is NEGATIVE
    # and as one shrinks the browser the window comes TO THE RIGHT.
    # This might make some mathematical sense but is very unintuitive so
    # we just don't move widgets along the dimensions that have a negative
    # fractional component
    if @positionFractionalInHoldingPanel[0] > 0
      @fullRawMoveTo (new Point boundsOfParent.left() + (boundsOfParent.width() * @positionFractionalInHoldingPanel[0]), @top()).round()
    if @positionFractionalInHoldingPanel[1] > 0
      @fullRawMoveTo (new Point @left(), boundsOfParent.top() + (boundsOfParent.height() * @positionFractionalInHoldingPanel[1])).round()

  fullRawMoveInStretchablePanelToFractionalPosition: (boundsOfParent) ->
    if !boundsOfParent?
      boundsOfParent = @parent.bounds

    @fullRawMoveTo (
      new Point \
       boundsOfParent.left() + (boundsOfParent.width() * @positionFractionalInHoldingPanel[0]),
       boundsOfParent.top() + (boundsOfParent.height() * @positionFractionalInHoldingPanel[1])
    ).round()

  rawSetExtentToFractionalExtentInPaneUserHasSet: (boundsOfParent) ->
    if !boundsOfParent?
      boundsOfParent = @parent.bounds

    @rawSetExtent new Point @extentFractionalInHoldingPanel[0] * boundsOfParent.width(), @extentFractionalInHoldingPanel[1] * boundsOfParent.height()

  
  # this one actually immediately changes the position and
  # bounds of widgets
  fullRawMoveTo: (aPoint) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    aPoint.debugIfFloats()
    delta = aPoint.toLocalCoordinatesOf @
    if !delta.isZero()
      #console.log "move 6"
      @__breakMoveResizeCaches()
      @fullRawMoveBy delta
    @bounds.debugIfFloats()

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  fullMoveTo: (aPoint, widgetStartingTheChange = nil) ->
    @_settleLayoutsAfter =>
      if not @isFreeFloating()
        return
      else
        aPoint = aPoint.round()
        newX = Math.max aPoint.x, 0
        newY = Math.max aPoint.y, 0
        newPos = new Point newX, newY
        unless @position().equals newPos
          @desiredPosition = newPos
          @_invalidateLayout()
          # all the moves via the handles arrive here,
          # where we remember the fractional position in the
          # holding panel. That is so for example moving
          # items inside a StretchablePanel causes their
          # relative position to be remembered, so resizing
          # the stretchable panel will get them to the
          # correct positions
          if widgetStartingTheChange?.changeShouldRememberFractionalGeometry?() and @parent?
            @rememberFractionalPositionInHoldingPanel()


  rememberFractionalPositionInHoldingPanel: ->
    @positionFractionalInHoldingPanel = @positionFractionalInWidget @parent

  rememberFractionalExtentInHoldingPanel: ->
    @extentFractionalInHoldingPanel = @extentFractionalInWidget @parent

  # TODO this is used a lot, where I suspect all we need to do
  # is to do this automatically ALSO when a widget is added/moved
  # to a new parent. I don't dare to do this now because I don't
  # have enough tests in the new environment to check for
  # bad implications.
  rememberFractionalSituationInHoldingPanel: ->
    @rememberFractionalPositionInHoldingPanel()
    @rememberFractionalExtentInHoldingPanel()
    @wasPositionedSlightlyOutsidePanel = ! @parent.bounds.containsRectangle @bounds
  
  __commitMoveTo: (aPoint) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    #console.log "move 7"
    @__breakMoveResizeCaches()
    delta = aPoint.toLocalCoordinatesOf @
    @__commitMoveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  fullRawMoveLeftSideTo: (x) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    @fullRawMoveTo new Point x, @top()
  
  fullRawMoveRightSideTo: (x) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    @fullRawMoveTo new Point x - @width(), @top()
  
  fullRawMoveTopSideTo: (y) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    @fullRawMoveTo new Point @left(), y
  
  fullRawMoveBottomSideTo: (y) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    @fullRawMoveTo new Point @left(), y - @height()
  
  fullRawMoveToSideOf: (aWidget) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    @fullRawMoveTo aWidget.topRight().add new Point 10, -Math.round((@height() - aWidget.height())/2)
    @fullRawMoveWithin @parent
  
  fullRawMoveFullCenterTo: (aPoint) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    @fullRawMoveTo aPoint.subtract @fullBounds().extent().floorDivideBy 2
  
  # make sure I am completely within another Widget's bounds
  fullRawMoveWithin: (aWdgt) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    # in case of widgets with deferred layouts we need
    # to look into desired extent and desired position
    if @desiredExtent?
      newBoundsForThisLayout = @desiredExtent
      @desiredExtent = nil
    else
      newBoundsForThisLayout = @extent()

    if @desiredPosition?
      newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
      @desiredPosition = nil
    else
      newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    # "bake" the "deferred" size and position
    # into the current size and position
    @rawSetBounds newBoundsForThisLayout

    # adjust the top side and the left side last, so that
    # the control buttons in the window bars are still
    # visible/reachable
    # Note that we have to update newBoundsForThisLayout as
    # we update the widget position!

    rightOff = newBoundsForThisLayout.right() - aWdgt.right()
    if rightOff > 0
      @fullRawMoveBy new Point -rightOff, 0
      newBoundsForThisLayout = @bounds

    leftOff = newBoundsForThisLayout.left() - aWdgt.left()
    if leftOff < 0
      @fullRawMoveBy new Point -leftOff, 0
      newBoundsForThisLayout = @bounds

    bottomOff = newBoundsForThisLayout.bottom() - aWdgt.bottom()
    if bottomOff > 0
      @fullRawMoveBy new Point 0, -bottomOff
      newBoundsForThisLayout = @bounds
    
    topOff = newBoundsForThisLayout.top() - aWdgt.top()
    if topOff < 0
      @fullRawMoveBy new Point 0, -topOff
      newBoundsForThisLayout = @bounds

    return

  # Deferred twin of fullRawMoveWithin: make sure I end up completely within
  # aWdgt's bounds, but DON'T bake the move now -- compute the clamped position
  # and DEFER it via fullMoveTo, so it settles in the recalculateLayouts ->
  # _reLayout phase (before paint), together with any other pending change.
  # Pending-aware like fullRawMoveWithin (it clamps the not-yet-applied
  # @desired* geometry when present); but, being deferred, it leaves
  # @desiredExtent for the cycle to apply rather than baking it now.
  fullMoveWithin: (aWdgt) ->
    # use the desired (not-yet-applied) geometry if present, else the applied one
    ext = if @desiredExtent?   then @desiredExtent   else @extent()
    pos = if @desiredPosition? then @desiredPosition else @position()

    newX = pos.x
    newY = pos.y

    # adjust the right and bottom first, the left and top LAST, so the control
    # buttons in window bars stay visible/reachable (mirrors fullRawMoveWithin)
    rightOff = (newX + ext.x) - aWdgt.right()
    if rightOff > 0 then newX = newX - rightOff
    if newX < aWdgt.left() then newX = aWdgt.left()

    bottomOff = (newY + ext.y) - aWdgt.bottom()
    if bottomOff > 0 then newY = newY - bottomOff
    if newY < aWdgt.top() then newY = aWdgt.top()

    @fullMoveTo new Point newX, newY

  # more complex Widgets, e.g. layouts, might
  # do a more complex calculation to get the
  # minimum extent
  getMinimumExtent: ->
    @minimumExtent

  setMinimumExtent: (@minimumExtent) ->

  # Widget accessing - dimensional changes requiring a complete redraw
  rawSetExtent: (aPoint, widgetStartingTheChange = nil) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    #console.log "move 8"
    if @ == widgetStartingTheChange
      return
    if !widgetStartingTheChange?
      widgetStartingTheChange = @
    # check whether we are actually changing the extent.
    unless aPoint.equals @extent()
      @__breakMoveResizeCaches()

      @_commitExtentAndNotify aPoint
      @changed()
      @_reLayoutSelf()

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setExtent: (aPoint, widgetStartingTheChange = nil) ->
    @_settleLayoutsAfter =>
      if not @isFreeFloating()
        return
      else
        aPoint = aPoint.round()
        newWidth = Math.max aPoint.x, 0
        newHeight = Math.max aPoint.y, 0
        newExtent = new Point newWidth, newHeight
        unless @extent().equals newExtent
          @desiredExtent = newExtent
          @_invalidateLayout()
          # all the resizes via the handles arrive here,
          # where we remember the fractional size in the
          # holding panel. That is so for example resizing
          # items inside a StretchablePanel causes their
          # relative size to be remembered, so resizing
          # the stretchable panel will get them to the
          # correct dimensions
          if widgetStartingTheChange?.changeShouldRememberFractionalGeometry?() and @parent?
            @extentFractionalInHoldingPanel = @extentFractionalInWidget @parent

  
  # The NOTIFY-ONLY corner: no repaint / no self-relayout, but it DOES fire the re-fit seam (Intent-1: notify the container
  # tracking my geometry to re-fit). The bounds-set body is shared with the NON-notifying arrange twin
  # _applyExtent (below) via __commitExtent; here we just add the seam fire iff the bounds changed.
  _commitExtentAndNotify: (aPoint) ->
    if @__commitExtent aPoint
      @_reFitContainerAfterRawGeometryChange()

  # The shared bounds-set core of _commitExtentAndNotify: round + min-extent clamp + commit @bounds, WITHOUT firing the
  # re-fit seam. Returns true iff @bounds actually changed (so the notifying wrapper knows to fire the seam).
  # (§4.2 structural arrange: the top-down arrange applies geometry via the non-notifying path -- _apply* --
  # since the arranger already knows the new geometry; only EXTERNAL agents notify by mutation via _commitExtentAndNotify.)
  __commitExtent: (aPoint) ->
    aPoint = aPoint.round()
    minExtent = @minimumExtent  # the __ leaf reads the field directly (getMinimumExtent is the non-overridden accessor -> @minimumExtent, so byte-identical); keeps __commitExtent a pure bottom (§3c)
    if ! aPoint.ge minExtent
      aPoint = aPoint.max minExtent
    newWidth = Math.max aPoint.x, 0
    newHeight = Math.max aPoint.y, 0
    newBounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + newWidth, @bounds.origin.y + newHeight
    if @bounds.equals newBounds then return false
    @bounds = newBounds
    @__breakMoveResizeCaches()
    return true

  # Non-notifying twin of rawSetExtent (§4.2 structural arrange-down): apply my extent the way rawSetExtent does
  # (commit @bounds + @changed repaint + @_reLayoutSelf), but WITHOUT firing the re-fit seam -- a container
  # arranging me top-down already knows my new geometry, so the seam's Intent-2 self-re-enqueue is redundant.
  # Byte-for-byte mirrors rawSetExtent except for the seam (rawSetExtent -> _commitExtentAndNotify which notifies).
  _applyExtent: (aPoint) ->
    unless aPoint.equals @extent()
      @__breakMoveResizeCaches()
      @__commitExtent aPoint
      @changed()
      @_reLayoutSelf()

  # Non-notifying twin of _commitBoundsAndNotify (§4.2 structural arrange-down): translate my origin + set my extent
  # the way _commitBoundsAndNotify does (silently -- no repaint, no self-relayout) but WITHOUT firing the re-fit seam.
  # A scroll panel sizing its content frame already knows the content's new bounds (it computed them from the §4.1
  # pure measure), so the seam's Intent-2 self-re-enqueue is redundant. Byte-for-byte mirrors _commitBoundsAndNotify
  # except it commits the extent via __commitExtent (no seam) instead of _commitExtentAndNotify.
  _applyBounds: (newBounds) ->
    return if @bounds.equals newBounds
    unless @bounds.origin.equals newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @__breakMoveResizeCaches()
    @__commitExtent newBounds.extent()


  # A re-fit "seam" (cf. _reFitContainerAfterRawGeometryChange): a freefloating content widget tells the
  # scroll-panel / vertical-stack it sits in to re-fit, after a layout-affecting property change
  # (VerticalStackLayoutSpec alignment/elasticity/base-width, SimplePlainTextWdgt soft-wrap, a
  # contained-text edit, collapse). A freefloating child's _invalidateLayout does NOT climb to its
  # container, which is why the container(s) are notified explicitly here. The phase dispatch (enqueue in
  # a pass, else invalidate) lives in the shared _reFitContainer; this seam only supplies which container(s).
  _refreshScrollPanelWdgtOrVerticalStackIfIamInIt: ->
    @_reFitContainer @parent.parent if @_amIDirectlyInsideScrollPanelWdgt()
    @_reFitContainer @parent

  # A re-fit "seam": an IMMEDIATE geometry mutator (_commitExtentAndNotify / fullRawMoveBy) notifies the
  # container that tracks my geometry to re-fit -- a NON-text-wrapping scroll panel (text-wrapping panels
  # drive their own content re-wrap in _positionAndResizeChildren, so they are excluded here), or a
  # stack/window container. A freefloating child's _invalidateLayout does NOT climb to its container, which
  # is why the container(s) are notified explicitly here. The phase dispatch lives in the shared
  # _reFitContainer (enqueue in a pass -- legal mid-pass, and the LIVE path for this immediate-mutator seam
  # since raw setters run during layout passes -- else invalidate); this seam only supplies which container(s).
  _reFitContainerAfterRawGeometryChange: ->
    # OVERLAY CHROME (carets, resize handles -- isLayoutInert) is excluded from every container's
    # content-bounds (TreeNode.childrenNotHandlesNorCarets, Widget._reLayout*, WindowWdgt.add), so a raw
    # move/resize of it CANNOT change the container's content-fit -- tripping this seam would only schedule a
    # WASTED container re-fit. Per-keystroke CARET repositioning (gotoSlot's @fullRawMoveTo) was the single
    # largest end-of-cycle layout-flush residual (~84 records); the genuine scroll-on-edit is already applied
    # SYNCHRONOUSLY by ScrollPanelWdgt.scrollCaretIntoView, so the deferred re-fit was pure redundancy. Skip
    # it for decoration. (Capability `?()`, not a Widget base default -- type-test-elimination convention.)
    return if @isLayoutInert?()
    @_reFitContainer @parent.parent if @_amIDirectlyInsideNonTextWrappingScrollPanelWdgt()
    @_reFitContainer @parent

  # The ONE phase-dispatch primitive for the whole "re-fit a container at the next settle point" family:
  # the drag/drop gesture handlers (PanelWdgt / ScrollPanelWdgt / SimpleVerticalStackPanelWdgt
  # _reactToChildDropped / _reactToChildGrabbed / childRemoved), the two freefloating-content "seams" above
  # (_refreshScrollPanelWdgtOrVerticalStackIfIamInIt, _reFitContainerAfterRawGeometryChange), and the
  # newParentChoice* menu actions all route through here. Two states:
  #  - INSIDE a layout pass (world._recalculatingLayouts): ENQUEUE the container into the recalculateLayouts
  #    until-loop via the shared bare-push atom (__markForRelayout). Enqueuing is legal mid-pass -- unlike
  #    _invalidateLayout the atom neither throws (the freeze guard, see _invalidateLayout below) nor climbs to
  #    ancestors; it enqueues only the directly-affected container.
  #  - OUTSIDE a pass: _invalidateLayout() so the next doOneCycle re-fits the container.
  # Gated on _reLayoutChildren? so only a tracking container (Window / Stack / ScrollPanel -- the only
  # classes that define it) reacts; any other widget is a no-op. Low-level (leading underscore) so lint
  # rule [F] exempts it, and the callers read as pure intent (@_reFitContainer @parent / @_reFitContainer()).
  # DETERMINISM: the gesture + menu callers fire OUTSIDE passes, so their in-pass arm is dead (kept uniform
  # for safety); the immediate-mutator seam's in-pass enqueue IS live and is the determinism-exempt path
  # (deferred-layout-OVERVIEW.md §11).
  #
  # (proper-layouts Phase D, 2026-06-28) The cross-method `return if container._adjustingContentsBounds`
  # suppression was DELETED here. Post-Phase-C every container arrange is a fixed point, so re-enqueuing a
  # container that is mid its OWN _positionAndResizeChildren now CONVERGES (one extra convergence pass instead
  # of being skipped) rather than looping forever -- which is why the skip is no longer needed for correctness.
  # (proper-layouts Phase E, 2026-06-28) The @_adjustingContentsBounds field itself is now GONE too: its last
  # use was the per-arrange re-entrancy guard, retired by giving each container arrange a NON-re-applying
  # self-resize (SimpleVerticalStackPanelWdgt._resizeOwnWidthSkippingChildRelayout/Height -> base Widget::rawSetExtent, which
  # fires THIS seam to notify the parent but does NOT re-enter @_reLayoutChildren). This notify-by-mutation seam
  # itself STAYS -- and its deletion was PROVEN INFEASIBLE 2026-06-29 (do NOT re-attempt; see
  # docs/proper-layouts-4.4-ordered-downwalk-plan.md §8): the container arrange is already single-pass/idempotent, so
  # the seam is NOT internal-convergence waste -- it is the irreducible MULTI-WIDGET notification that a freefloating
  # content's in-pass geometry change must re-fit its tracking container (a different settle visit). All deletion
  # paths were falsified (off-pass dirty-climb; ordered content-first pre-settle; analytic decoupling / synchronous
  # fixpoint). The convergence/suppression WASTE the elimination arc targeted was removed separately (§4.2 Stage 3,
  # non-notifying arrange -> end-of-cycle capstone GREEN); only this legitimate edge remains.
  _reFitContainer: (container = @) ->
    return unless container?._reLayoutChildren?
    if world?._recalculatingLayouts
      container.__markForRelayout()   # in-pass: enqueue just this directly-affected container, no climb (shared atom)
    else
      container._invalidateLayout()


  rawSetWidth: (width) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    #console.log "move 10"
    @__breakMoveResizeCaches()
    @rawSetExtent new Point(width or 0, @height())

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setWidth: (width) ->
    @_settleLayoutsAfter =>
      if not @isFreeFloating()
        return
      else
        newWidth = Math.max width, 0
        newExtent = new Point newWidth, @height()
        unless @extent().equals newExtent
          @desiredExtent = newExtent
          @_invalidateLayout()
  
  __commitWidth: (width) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    #console.log "move 11"
    @__breakMoveResizeCaches()
    w = Math.max Math.round(width or 0), 0
    @bounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + w, @bounds.corner.y
  
  rawSetHeight: (height) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    #console.log "move 12"
    @__breakMoveResizeCaches()
    @rawSetExtent new Point(@width(), height or 0)

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setHeight: (height) ->
    @_settleLayoutsAfter =>
      if not @isFreeFloating()
        return
      else
        newHeight = Math.max 0, height
        newExtent = new Point @width(), newHeight
        unless @extent().equals newExtent
          @desiredExtent = newExtent
          @_invalidateLayout()
  
  __commitHeight: (height) ->
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger

    #console.log "move 13"
    @__breakMoveResizeCaches()
    h = Math.max Math.round(height or 0), 0
    @bounds = new Rectangle @bounds.origin, new Point @bounds.corner.x, @bounds.origin.y + h
  
  setColor: (aColorOrAWidgetGivingAColor, widgetGivingColor, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken

    if widgetGivingColor?.getColor?
      aColor = widgetGivingColor.getColor()
    else
      aColor = aColorOrAWidgetGivingAColor

    if aColor
      if @color?.equals aColor
        return

      @color = aColor
      @changed()
        
    return aColor
  
  setBackgroundColor: (aColorOrAWidgetGivingAColor, widgetGivingColor, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken

    if widgetGivingColor?.getColor?
      aColor = widgetGivingColor.getColor()
    else
      aColor = aColorOrAWidgetGivingAColor
    if aColor

      if @backgroundColor?.equals aColor
        return

      @backgroundColor = aColor
      @changed()

    return aColor
  
  # Widget displaying ---------------------------------------------------------

  # There are three fundamental methods for rendering and displaying anything.
  # * updateBackBuffer: this one creates/updates the local canvas of this widget only
  #   i.e. not the children. For example: a ColorPickerWdgt is a Widget which
  #   contains three children Widgets (a color palette, a greyscale palette and
  #   a feedback). The updateBackBuffer method of ColorPickerWdgt only creates
  #   a canvas for the container Widget. So that's just a canvas with a
  #   solid color. As the
  #   ColorPickerWdgt constructor runs, the three childredn Widgets will
  #   run their own updateBackBuffer method, so each child will have its own
  #   canvas with their own contents.
  #   Note that updateBackBuffer should be called sparingly. A widget should repaint
  #   its buffer pretty much only *after* it's been added to its first parent and
  #   whenever it changes dimensions. Things like changing parent and updating
  #   the position shouldn't normally trigger an update of the buffer.
  #   Also note that before the buffer is painted for the first time, they
  #   might not know their extent. Typically text-related Widgets know their
  #   extensions after they painted the text for the first time...
  # * paintIntoAreaOrBlitFromBackBuffer: takes the local canvas and paints it to a specific area in a passed
  #   canvas. The local canvas doesn't contain any rendering of the children of
  #   this widget.
  # * fullPaintIntoAreaOrBlitFromBackBuffer: recursively draws all the local canvas of this widget and all
  #   its children into a specific area of a passed canvas.

  
  
  boundsContainPoint: (aPoint) ->
    @bounds.containsPoint aPoint

  areBoundsIntersecting: (aWdgt) ->
    @bounds.isIntersecting aWdgt.bounds

  calculateKeyValues: (aContext, clippingRectangle) ->
    area = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if area.isNotEmpty()
      delta = @position().neg()
      src = area.translateBy(delta).round()

      sl = src.left() * ceilPixelRatio
      st = src.top() * ceilPixelRatio
      al = area.left() * ceilPixelRatio
      at = area.top() * ceilPixelRatio
      w = Math.min(src.width() * ceilPixelRatio, @width() * ceilPixelRatio - sl)
      h = Math.min(src.height() * ceilPixelRatio, @height() * ceilPixelRatio - st)

    return [area,sl,st,al,at,w,h]

  turnOnHighlight: ->
    if !@highlighted
      @highlighted = true
      world.widgetsToBeHighlighted.add @
      @changed()

  turnOffHighlight: ->
    if @highlighted
      @highlighted = false
      world.widgetsToBeHighlighted.delete @
      @changed()


  # paintRectangle can work in two patterns:
  #  * passing actual pixels, when used
  #    outside the effect of the scope of
  #    "useLogicalPixelsUntilRestore()", or
  #  * passing logical pixels, when used
  #    inside the effect of the scope of
  #    "useLogicalPixelsUntilRestore()", or
  # Mostly, the first pattern is used.
  # Note that the resulting rectangle WILL reflect
  # if it's being painted as a shadow or not,
  # so it can't be used to paint on a backbuffer,
  # since you always want to paint on a backbuffer
  # "pristine", since the shadow effect is applied
  # when the backbuffer is in turn blitted to
  # screen, LATER.

  paintRectangle: (
    aContext,
    al, at, w, h,
    color,
    transparency = nil,
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

    if aContext == world.worldCanvasContext and @isInCollapsedSubtree()
      return true

    return false

  recordDrawnAreaForNextBrokenRects: ->
    if @childrenBoundsUpdatedAt < WorldWdgt.frameCount
      @childrenBoundsUpdatedAt = WorldWdgt.frameCount
      @clippedBoundsWhenLastPainted = @clippedThroughBounds()
      @fullClippedBoundsWhenLastPainted = @fullClippedBounds()

  # in general, the children of a Widget could be outside the
  # bounds of the parent (they could also be much larger
  # then the parent). This means that we have to traverse
  # all the children to find out whether any of those overlap
  # the clipping rectangle. Note that we can be smarter with
  # PanelWdgts, as their children are actually all contained
  # within the parent's boundary.
  #
  # Note that if we could dynamically and cheaply keep an updated
  # fullBounds property, then we could be smarter
  # in discarding whole sections of the scene graph.
  # (see https://github.com/davidedc/Fizzygum/issues/150 )
  #
  # To draw a widget, basically you first have to draw its shadow
  # and then you draw the contents. See methods below.
  #
  # How the shadow painting works -----------------
  # IMPORTANT: a widget NEVER bakes its own shadow into its back-buffer. The ONLY
  # shadow mechanism is this unified recursive re-paint: a widget that has a shadow
  # (@shadowInfo) re-paints its WHOLE subtree once more, faintly and offset, BEHIND
  # the normal paint. It is NOT a hard "silhouette"/outline — each widget is
  # re-painted with its actual (possibly semi-transparent) pixels at
  # appliedShadow.alpha, so a transparent text widget casts a faint copy of its
  # GLYPHS and a semi-transparent panel-with-text casts a faint copy of fill AND
  # content together. (There is no per-glyph / per-widget baked shadow: a
  # per-glyph shadowOffset/shadowColor route is deliberately not reintroduced.)
  # If appliedShadow is defined, it means that we are painting the whole
  # of the widget recursively AS SHADOW. Since there are no shadows of a shadow
  # so we can skip the "just shadow" part, and we paint the widget as shadow.
  # If appliedShadow is NOT defined, then it means that we just have to paint the widget,
  # which might have a shadow. If it does have a shadow, then we first paint it
  # as shadow, then we paint it as non-shadow. If it doesn't have a shadow, then
  # we just paint it as non-shadow.

  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # used to track which widget has been throwing
    # an error while painting
    world.paintingWidget = @

    # if there is a shadow "property" object
    # then first draw the shadow of the tree
    # If appliedShadow is defined, then we just want to paint the
    # content as shadow, so we skip this paragraph because we don't have
    # to paint a shadow for a shadow.
    if !appliedShadow? and @shadowInfo?
      @fullPaintIntoAreaOrBlitFromBackBufferJustShadow aContext, clippingRectangle, @shadowInfo

    # draw the proper contents of the tree. Potentially, draw them faintly as shadow.
    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      if aContext == world.worldCanvasContext
        @recordDrawnAreaForNextBrokenRects()
      @fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow aContext, clippingRectangle, appliedShadow


  # to draw the shadow, most of the times you have to draw the whole
  # of the contents, but with a darker/fainter color, and with
  # transparency.
  #
  # The only variant is that if a Panel if fully opaque, then the shadow is just
  # a rectangle, we don't need to draw anything inside the panel to
  # contribute to the shadow of the panel
  #
  # In this function the parameter "appliedShadow" MUST contain a shadow info.
  # This parameter will cause the whole widget to be painted recursively as shadow.
  fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
    clippingRectangle = clippingRectangle.translateBy -appliedShadow.offset.x, -appliedShadow.offset.y

    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      aContext.save()
      aContext.translate appliedShadow.offset.x * ceilPixelRatio, appliedShadow.offset.y * ceilPixelRatio

      @fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow aContext, clippingRectangle, appliedShadow

      aContext.restore()
  

  # this just draws the tree of the widgets recursively, potentially "normally" or
  # potentially more faintly to draw a shadow.
  # The only variant is that the Panel
  # draws its background, then its contents AND THEN its stroke
  # (because otherwise its content would paint over its stroke)
  fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    @children.forEach (child) ->
      child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow

  # ... when you want to hide something
  # but you don't want to generate any
  # broken rectangles
  silentHide: ->
    if !@isVisible
      return
    @isVisible = false
    WorldWdgt.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @

  hide: ->
    if !@isVisible
      return

    @silentHide()

    # TODO refactor this, it appears more than one time
    # if the widget contributes to a shadow, unfortunately
    # we have to walk towards the top to
    # break the widget that has the shadow.
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
    WorldWdgt.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @

    firstParentOwningMyShadow = @firstParentOwningMyShadow()
    if firstParentOwningMyShadow?
      firstParentOwningMyShadow.fullChanged()
    else
      @fullChanged()
  
  toggleVisibility: ->
    @isVisible = not @isVisible
    WorldWdgt.numberOfVisibilityFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    @fullChanged()

  # SELF-SETTLE (single-mutation tier). childBeingCollapsed now tears down the bar buttons through the
  # NON-settling core (_destroyNoSettle), and childCollapsed re-fits via raw setters + _reFitContainer, so
  # _collapseNoSettle reaches no public setter. Anchored on (@parent ? @) (the container that re-lays-out).
  # THIN wrapper: the already-collapsed guard lives in the core (check-layering [H]), not before the settle.
  collapse: ->
    @_settleLayoutsAfter => @_collapseNoSettle()

  _collapseNoSettle: ->
    # IDEMPOTENT -- the SOLE collapse guard (the public collapse() is a thin settle wrapper). A direct caller --
    # a layout pass that decides collapse by width (WindowWdgt._positionAndResizeChildren,
    # HorizontalMenuPanelWdgt._reLayoutSelf) -- relies on this no-op when already in state, so the core never
    # re-runs the hooks / @_invalidateLayout (which would THROW mid-pass). The public path now settles-then-no-ops
    # for an already-collapsed widget -- byte-identical (a no-op flush).
    return if @collapsed
    @parent?.childBeingCollapsed? @
    @collapsed = true
    WorldWdgt.numberOfCollapseFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    @_invalidateLayout()
    @fullChanged()
    @parent?.childCollapsed? @

  # SELF-SETTLE (single-mutation tier). childBeingUnCollapsed re-creates the bar buttons through the
  # NON-settling core (createAndAdd* -> @_addNoSettle; the button constructors add their innards on ORPHANS,
  # exempt from the flush-throw), and childUnCollapsed re-fits via raw setters, so _unCollapseNoSettle reaches
  # no public setter. Anchored on @ (the canonical wrap; the global flush re-lays-out the container).
  # THIN wrapper: the guard lives in the core (check-layering [H]), not before the settle.
  unCollapse: ->
    @_settleLayoutsAfter => @_unCollapseNoSettle()

  _unCollapseNoSettle: ->
    # IDEMPOTENT -- the SOLE unCollapse guard (the public unCollapse() is a thin settle wrapper). See
    # _collapseNoSettle for why a direct layout-pass caller needs the no-op (avoid re-running hooks /
    # @_invalidateLayout mid-pass). Guard on @collapsed -- this widget's OWN collapse flag. The redundant
    # `return if !@isInCollapsedSubtree()` was REMOVED: isInCollapsedSubtree() is the RECURSIVE self-or-ancestor query, and once
    # @collapsed is true it necessarily returns true, so that second guard was DEAD code.
    return if !@collapsed
    @parent?.childBeingUnCollapsed? @
    @collapsed = false
    WorldWdgt.numberOfCollapseFlagsChanges++
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    @_invalidateLayout()
    @fullChanged()
    @parent?.childUnCollapsed? @

  
  isInCollapsedSubtree: ->
    if @collapsed
      return true
    else
      if @parent?
        return @parent.isInCollapsedSubtree()
      else
        return false
  
  removeFromTree: ->
    # FREEFLOATING-skip centralized in _invalidateLayout(triggeringChild): pass @ so the parent skips
    # when I'm freefloating -- removing a freefloating child doesn't change the parent's layout.
    @parent?._invalidateLayout(@)
    @__breakMoveResizeCaches()
    WorldWdgt.numberOfAddsAndRemoves++
    @parent.removeChild @
    @fullChanged()

  colloquialName: ->
    "generic widget"

  representativeIcon: ->
    new WidgetIconWdgt

  # »>> this part is excluded from the fizzygum homepage build
  createPointerWdgt: ->
    myPosition = @positionAmongSiblings()
    widgetToAdd = new PointerWdgt @
    @parent.add widgetToAdd, myPosition
    widgetToAdd.fullMoveTo @position()
    widgetToAdd.setExtent new Point 150, 20
    widgetToAdd.fullChanged()
    @removeFromTree()
  # this part is excluded from the fizzygum homepage build <<«

  # PUBLIC self-settling entry (menus / triggers / double-clicks). The NON-settling core
  # _createReferenceNoSettle is what a drop recipient calls (it runs inside the drop's settle, so
  # a public add/setExtent would re-enter the flush guard and throw under the single-mutation tier).
  createReference: (referenceName, placeToDropItIn = world) ->
    @_settleLayoutsAfter => @_createReferenceNoSettle referenceName, placeToDropItIn

  # The COMPLETE createReference minus the settle. add -> _addNoSettle and setExtent -> rawSetExtent
  # (the shortcut is freshly added freefloating, so the immediate raw size is byte-identical to the
  # deferred desired-extent path; same add-then-size order as the public version, so the icon grid
  # positions identically once the enclosing settle re-fits).
  _createReferenceNoSettle: (referenceName, placeToDropItIn = world) ->
    # this function can also be called as a callback
    # of a trigger, in which case the first parameter
    # here is a menuItem. We take that parameter away
    # in that case.
    if referenceName? and typeof(referenceName) != "string"
      referenceName = nil
      placeToDropItIn = world

    # don't create new reference if it exists already
    for w in placeToDropItIn.children
      if w.isShortcutTo?(@)
        return

    widgetToAdd = new IconicDesktopSystemDocumentShortcutWdgt @, referenceName
    # this "add" is going to try to position the
    # new icon into a grid
    placeToDropItIn._addNoSettle widgetToAdd
    widgetToAdd.rawSetExtent new Point 75, 75
    widgetToAdd.fullChanged()
    @bringToForeground()

  # PUBLIC self-settling entry; _createReferenceAndCloseNoSettle is the core a drop recipient calls
  # (IconicDesktopSystemFolderShortcutWdgt / CreateShortcutOfDroppedItemsMixin, inside the drop's settle).
  createReferenceAndClose: (referenceName, placeToDropItIn = world) ->
    @_settleLayoutsAfter => @_createReferenceAndCloseNoSettle referenceName, placeToDropItIn

  _createReferenceAndCloseNoSettle: (referenceName, placeToDropItIn = world) ->
    @_createReferenceNoSettle referenceName, placeToDropItIn
    @_closeNoSettle()

  # Widget full image:
  # Fixes https://github.com/jmoenig/morphic.js/issues/7
  # and https://github.com/davidedc/Fizzygum/issues/160
  #
  # if you want to forceShadow that noShadow must be
  # sent as false
  fullImage: (bounds, noShadow = false, forceShadow = false) ->

    shadowHadBeenReplacedOrAdded = false

    if noShadow
      originalShadow = @shadowInfo
      @shadowInfo = ShadowInfo.noShadow()
      shadowHadBeenReplacedOrAdded = true
    else if forceShadow and !@hasShadow()
      # in this case originalShadow is nil
      # because the widget has no shadow
      # and the widget will get nil shadow back
      # again at the end of this method
      originalShadow = nil
      @shadowInfo = new ShadowInfo new Point(4, 4), 0.2
      shadowHadBeenReplacedOrAdded = true


    if !bounds?
      bounds = @fullBounds()
      # if we do want the shadow, and there is one, then
      # we have to consider bigger bounds for the full widget
      if !noShadow and @hasShadow()
        bounds = bounds.growBy @shadowInfo.offset


    img = HTMLCanvasElement.createOfPhysicalDimensions bounds.extent().scaleBy ceilPixelRatio
    ctx = img.getContext "2d"
    # ctx.useLogicalPixelsUntilRestore()
    # we are going to draw this widget and its children into "img".
    # note that the children are not necessarily geometrically
    # contained in the widget (in which case it would be ok to
    # translate the context so that the origin of *this* widget is
    # at the top-left of the "img" canvas).
    # Hence we have to translate the context
    # so that the origin of the entire bounds is at the
    # very top-left of the "img" canvas.
    ctx.translate -bounds.origin.x * ceilPixelRatio , -bounds.origin.y * ceilPixelRatio
    @fullPaintIntoAreaOrBlitFromBackBuffer ctx, bounds

    if shadowHadBeenReplacedOrAdded
      @shadowInfo = originalShadow

    img

  # »>> this part is excluded from the fizzygum homepage build
  # unused code
  fullImageNoShadow: ->
    boundsWithNoShadow = @fullBounds()
    return @fullImage boundsWithNoShadow, true

  # unused code
  fullImageData: ->
    # returns a string like "data:image/png;base64,iVBORw0KGgoAA..."
    # note that "image/png" below could be omitted as it's
    # the default, but leaving it here for clarity.
    @fullImage().toDataURL "image/png"

  # the way we take a picture here is different
  # than the way we usually take a picture.
  # Usually we ask the widget and subwidgets to
  # paint themselves anew into a new canvas.
  # This is different: we take the area of the
  # screen *as it is* and we crop the part of
  # interest where the extent of our selected
  # widget is. This means that the widget might
  # be occluded by other things.
  # The advantage here is that we capture
  # the screen absolutely as is, without
  # causing any repaints. If streaks are on the
  # screen due to bad painting, we capture them
  # exactly as the user sees them.
  # Returns the canvas holding this widget's region exactly as it appears on
  # screen (an SWCanvasElement under the software backend, else a DOM canvas).
  # Both the screenshot data-URL (fullImageAsItAppearsOnScreen) and the SystemTest
  # raw-pixel hash are derived from this single capture, so they never diverge and
  # the region is only cropped once.
  fullRenderCanvasAsItAppearsOnScreen: ->
    fullExtentOfWidget = @fullBounds()
    destCanvas = HTMLCanvasElement.createOfPhysicalDimensions fullExtentOfWidget.extent().scaleBy ceilPixelRatio
    destCtx = destCanvas.getContext '2d'
    # Read from the render canvas, not the DOM canvas: under SWCanvas this is the
    # pristine software surface (deterministic, non-premultiplied — avoids the DOM
    # canvas's premultiplied round-trip). When the flag is off it IS the DOM canvas.
    destCtx.drawImage world.worldRenderCanvas,
      fullExtentOfWidget.topLeft().x * ceilPixelRatio,
      fullExtentOfWidget.topLeft().y * ceilPixelRatio,
      fullExtentOfWidget.width() * ceilPixelRatio,
      fullExtentOfWidget.height() * ceilPixelRatio,
      0,
      0,
      fullExtentOfWidget.width() * ceilPixelRatio,
      fullExtentOfWidget.height() * ceilPixelRatio

    return destCanvas

  fullImageAsItAppearsOnScreen: ->
    return @fullRenderCanvasAsItAppearsOnScreen().toDataURL "image/png"

  # unused code
  fullImageHashCode: ->
    return @fullImageData().hashCode()
  # this part is excluded from the fizzygum homepage build <<«
  
  # shadow is added to a widget by
  # the ActivePointerWdgt while floatDragging
  addShadow: (offset = new Point(4, 4), alpha = 0.2) ->
    @silentAddShadow offset, alpha
    @fullChanged()

  silentAddShadow: (offset, alpha) ->
    @shadowInfo = new ShadowInfo offset, alpha
  
  hasShadow: ->
    @shadowInfo?
  
  removeShadow: ->
    if @hasShadow()
      @shadowInfo = nil
      @fullChanged()
  
  
  
  # Widget updating ///////////////////////////////////////////////////////////////
  changed: ->
    # tests should all pass even if you don't
    # use the world.trackChanges flag, perhaps things
    # should just be a bit slower (but probably not
    # significantly). This is because there is no
    # harm into changing children of a widget
    # that is fullChanged, the checks should
    # simplify the situation.
    # I tested this was OK in December 2017
    if world.trackChanges[world.trackChanges.length - 1]

      # if the widget is attached to a hand then
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
        # if we already issued a fullChanged on this widget
        # then there is no point issuing a change too.
        if !@fullGeometryOrPositionPossiblyChanged
          world.widgetsThatMaybeChangedGeometryOrPosition.push @
          @geometryOrPositionPossiblyChanged = true

  # to actually make sure if a widget has changed
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
    # tests should all pass even if you don't
    # use the world.trackChanges flag, perhaps things
    # should just be a bit slower (but probably not
    # significantly). This is because there is no
    # harm into changing children of a widget
    # that is fullChanged, the checks should
    # simplify the situation.
    # I tested this was OK in December 2017
    if world.trackChanges[world.trackChanges.length - 1]
      # check if we already issued a fullChanged on this widget
      if !@fullGeometryOrPositionPossiblyChanged
        world.widgetsThatMaybeChangedFullGeometryOrPosition.push @
        @fullGeometryOrPositionPossiblyChanged = true
  
  # Widget accessing - structure //////////////////////////////////////////////

  # EXPLANATION of "silent" vs. "raw" vs. "normal" hierarchy/bounds change methods
  # ------------------------------------------------------------------------------
  # “normal”: these are the highest-level methods and take into account layouts.
  #           Should use these ones as much as possible. Call the "raw"
  #           versions below
  # “raw”: lower level. This is what the re-layout routines use. Usually call the
  #        silent version below.
  # “silent”: doesn't mark the widget as changed
  #
  # It's important that lower-level functions don't ever call the higher-level
  # functions, as that's architecturally incorrect and can cause infinite loops in
  # the invocations.

  iHaveBeenAddedTo: (whereTo, beingDropped) ->
    @_reLayoutSelf()

  # »>> this part is excluded from the fizzygum homepage build
  # _addNoSettle (NOT add): these run from addOrRemoveAdders during a layout pass, so a
  # self-settle would re-enter the flush guard; for the other caller
  # (showResizeAndMoveHandlesAndLayoutAdjusters, a menu action) it is byte-identical
  # because the frame settles anyway.
  addAsSiblingAfterMe: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING) ->
    myPosition = @positionAmongSiblings()
    @parent._addNoSettle aWdgt, (myPosition + 1), layoutSpec

  addAsSiblingBeforeMe: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING) ->
    myPosition = @positionAmongSiblings()
    @parent._addNoSettle aWdgt, myPosition, layoutSpec
  # this part is excluded from the fizzygum homepage build <<«

  # The layoutSpec a widget takes when added with NO explicit one -- the default for add() / _addNoSettle()'s
  # layoutSpec argument. Plain widgets are free-floating; a widget with an intrinsic placement overrides this
  # so a caller can write the uniform `parent.add child` (no spec at the call site) and still get the right
  # attachment. The destination is passed so the placement can depend on it (e.g. a HandleWdgt corner-attaches
  # only to the very widget it resizes -- its @target -- and is free-floating on the world / hand otherwise).
  defaultLayoutSpecWhenAddedTo: (destination) ->
    LayoutSpec.ATTACHEDAS_FREEFLOATING

  # ===== structural add =====
  # add() is the PUBLIC self-settling entry: it links the widget in through the private,
  # NON-settling _addNoSettle and then flushes layouts once (_settleLayoutsAfter), so a
  # top-level caller (app / macro / event handler) is left with a consistent world -- no manual
  # settle/yield. _addNoSettle is the COMPLETE add minus the settle (shadow management + structural
  # link-in + fractional-position recording); add() is just the settle-wrap over it. Callers that
  # run INSIDE a layout pass (_reLayout / _reLayoutSelf), build their own innards during
  # construction, or tear down / re-home from a private chain call _addNoSettle DIRECTLY (it does not
  # settle, so it neither re-enters the flush guard nor triggers a redundant relayout). They are
  # byte-identical to going through add(): for a fresh non-world child the shadow step is a no-op
  # removeShadow and the fractional step is skipped. See docs/deferred-layout-refit-and-add-design.md (D3).
  add: (aWdgt, position = nil, layoutSpec = aWdgt.defaultLayoutSpecWhenAddedTo(@), beingDropped) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, position, layoutSpec, beingDropped

  # _addNoSettle -- the COMPLETE add minus the settle. The single NON-settling core behind add() and
  # every internal layout-time / construction-time / teardown adder (it must NOT
  # flush layouts: it runs inside another mutation's settle, during construction, or from a
  # private teardown chain). Full semantics: shadow management + invalidate + silentAdd +
  # iHaveBeenAddedTo / childAdded / childRemoved callbacks + fractional-position, but never
  # recalculateLayouts. (The shadow/fractional steps fold in what add() used to do in its
  # settle-wrap; they are no-ops for the fresh non-world children the internal adders pass.)
  # ??? TODO you should handle the case of Widget
  #     being added to itself and the case of
  # ??? TODO a Widget being added to one of its
  #     children
  _addNoSettle: (aWdgt, position = nil, layoutSpec = aWdgt.defaultLayoutSpecWhenAddedTo(@), beingDropped) ->

    # let's check if we are trying to add
    # an ancestor of me below me.
    # That would be impossible to do,
    # so we return nil to signal the error.
    if aWdgt.isAncestorOf @
      return nil

    # shadow management (folded in from add()'s old settle-wrap): added to the world a widget
    # gains a drop-shadow; added anywhere else it loses one. Transient overlays (highlighter,
    # caret) opt out via skipsAddShadowManagement. For a fresh non-world child removeShadow is a
    # no-op, so the internal adders that call _addNoSettle directly stay byte-identical.
    unless aWdgt.skipsAddShadowManagement?()
      if @ == world
        aWdgt.addShadow()
        # adding to the world cancels scheduled tooltips, so a tooltip doesn't pop over what the
        # button just opened (e.g. the Simple Document "snippets" button).
        if !(aWdgt instanceof ToolTipWdgt)
          ToolTipWdgt.cancelAllScheduledToolTips()
      else
        aWdgt.removeShadow()

    previousParent = aWdgt.parent
    # FREEFLOATING-skip via _invalidateLayout(triggeringChild): pass aWdgt so its OLD parent skips
    # when aWdgt is freefloating (removing it only changes that parent's layout if it laid it out).
    # This runs BEFORE setLayoutSpec below, so the param reads aWdgt's OLD spec -- correct. (The NEW
    # container is invalidated AFTER setLayoutSpec, further down, also via the param.)
    aWdgt.parent?._invalidateLayout(aWdgt)

    # if the widget contributes to a shadow, unfortunately
    # we have to walk towards the top to
    # break the widget that has the shadow.
    firstParentOwningMyShadow = aWdgt.firstParentOwningMyShadow()
    if firstParentOwningMyShadow?
      firstParentOwningMyShadow.fullChanged()
    else
      aWdgt.fullChanged()

    aWdgt.setLayoutSpec layoutSpec
    # NEW-container invalidate via the param: setLayoutSpec above set aWdgt.layoutSpec to the NEW
    # spec, so passing aWdgt makes me (the new container) skip iff aWdgt is now freefloating -- same
    # as the old `if layoutSpec != FREEFLOATING` guard, now centralized in _invalidateLayout.
    @_invalidateLayout(aWdgt)

    aWdgt.fullChanged()
    @silentAdd aWdgt, true, position
    aWdgt.iHaveBeenAddedTo @, beingDropped
    if previousParent?.childRemoved?
      previousParent.childRemoved @

    if @childAdded?
      @childAdded aWdgt

    # fractional-position recording (folded in from add()): only meaningful for a world-level
    # widget, skipped otherwise -- so a no-op for the internal adders.
    if @ == world
      aWdgt.rememberFractionalPositionInHoldingPanel()

    return aWdgt

  sourceChanged: ->
    @_reLayoutSelf?()
    @changed?()

  # this is done before the updating of the
  # backing store in some widgets that
  # need to figure out their whole
  # layout (which depends on the children)
  # before painting themselves
  # e.g. the MenuWdgt
  _reLayoutSelf: ->

  calculateAndUpdateExtent: ->

  silentAdd: (aWdgt, avoidExtentCalculation, position = nil) ->
    # the widget that is being
    # attached might be attached to
    # a clipping widget. So we
    # need to do a "changed" here
    # to make sure that anything that
    # is outside the clipping Widget gets
    # painted over.
    owner = aWdgt.parent
    if owner?
      owner.removeChild aWdgt
    if aWdgt.isPopUpMarkedForClosure?
      aWdgt.isPopUpMarkedForClosure = false
    @addChild aWdgt, position
    if !avoidExtentCalculation
      aWdgt.calculateAndUpdateExtent()
    

  # Duplication and Serialization /////////////////////////////////////////


  duplicateMenuAction: ->
    aFullCopy = @fullCopy()
    aFullCopy.unlockFromPanels()
    world.add aFullCopy
    aFullCopy.fullRawMoveTo @position().add new Point 10, 10
    aFullCopy.rememberFractionalSituationInHoldingPanel()

  duplicateMenuActionAndPickItUp: ->
    aFullCopy = @fullCopy()
    aFullCopy?.pickUp()

  # in case we copy a widget, if the original was in some
  # data structures related to broken widgets, then
  # we have to add the copy too.
  alignCopiedWidgetToBrokenInfoDataStructures: (copiedWidget) ->
    if world.widgetsThatMaybeChangedGeometryOrPosition.includes(@) and
     !world.widgetsThatMaybeChangedGeometryOrPosition.includes(copiedWidget)
      world.widgetsThatMaybeChangedGeometryOrPosition.push copiedWidget

    if world.widgetsThatMaybeChangedFullGeometryOrPosition.includes(@) and
     !world.widgetsThatMaybeChangedFullGeometryOrPosition.includes(copiedWidget)
      world.widgetsThatMaybeChangedFullGeometryOrPosition.push copiedWidget

  # in case we copy a widget, if the original was in some
  # stepping structures, then we have to add the copy too.
  alignCopiedWidgetToSteppingStructures: (copiedWidget) ->
    if world.steppingWdgts.has @
      world.steppingWdgts.add copiedWidget

  # in case we copy a widget, if the original was receiving
  # keyboard events, then we have to add the copy too.
  alignCopiedWidgetToKeyboardEventsReceiversSet: (copiedWidget) ->
    if world.keyboardEventsReceivers.has @ 
      world.keyboardEventsReceivers.add copiedWidget

  # note that the entire copying mechanism
  # should also take care of inserting the copied
  # widget in whatever other data structures where the
  # original widget was.
  # For example, if the Widget appeared in a data
  # structure related to the broken rectangles mechanism,
  # we should place the copied widget there.
  fullCopy: ->
    if @destroyed
      @inform "The item you are\ntrying to copy\nis dead!"
      return nil
    allWidgetsInStructure = @allChildrenBottomToTop()
    copiedWidget = @deepCopy false, [], [], allWidgetsInStructure
    return copiedWidget

  # »>> this part is excluded from the fizzygum homepage build
  serialize: ->
    allWidgetsInStructure = @allChildrenBottomToTop()
    arr1 = []
    arr2 = []
    @deepCopy true, arr1, arr2, allWidgetsInStructure
    totalJSON = ""

    for element in arr2
      try
        console.log JSON.stringify(element) + "\n// --------------------------- \n"
      catch e
        debugger

      totalJSON = totalJSON + JSON.stringify(element) + "\n// --------------------------- \n"
    return totalJSON


  # Deserialization -----------------------------------


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

    clonedWidgets = []
    for eachObject in createdObjects
      # note that the constructor method is not run!
      #console.log "cloning:" + eachWidget.className
      #console.log "with:" + window[eachObject.className].prototype
      if eachObject.className == "Canvas"
        theClone = HTMLCanvasElement.createOfPhysicalDimensions new Point eachObject.width, eachObject.height
        ctx = theClone.getContext "2d"

        image = new Image
        # Under the SWCanvas backend, drawImage rasterises an <img> by decoding
        # it into a scratch canvas, which requires the image to be decoded first;
        # drawing it before decode would throw. So paint on load instead (the
        # clone starts blank and fills in within a frame). The native path below
        # is left exactly as-is so flag-off output is unchanged.
        if window.FIZZYGUM_USE_SWCANVAS
          image.onload = ->
            try ctx.drawImage image, 0, 0
        image.src = eachObject.data
        unless window.FIZZYGUM_USE_SWCANVAS
          # if something doesn't get painted here,
          # it might be because the allocation of the image
          # would actually be asynchronous, in theory
          # you'd have to do the drawImage in a callback
          # on onLoad of the image...
          ctx.drawImage image, 0, 0

      else if eachObject.constructor != Array
        theClone = Object.create window[eachObject.className].prototype
        if theClone.assignUniqueID?
          theClone.assignUniqueID()
      else
        theClone = []
      clonedWidgets.push theClone
      #theClone.constructor()

    for i in [0... clonedWidgets.length]
      eachClonedWidget = clonedWidgets[i]
      if eachClonedWidget.constructor == HTMLCanvasElement
        # do nothing
      else if eachClonedWidget.constructor != Array
        for property of createdObjects[i]
          # also includes the "parent" property
          if createdObjects[i].hasOwnProperty property
            console.log "looking at property: " + property
            clonedWidgets[i][property] = createdObjects[i][property]
            if typeof clonedWidgets[i][property] is "string"
              if clonedWidgets[i][property].startsWith "$"
                referenceNumberAsString = clonedWidgets[i][property].substring(1)
                referenceNumber = parseInt referenceNumberAsString
                clonedWidgets[i][property] = clonedWidgets[referenceNumber]
      else
        for j in [0... createdObjects[i].length]
          eachArrayElement = createdObjects[i][j]
          clonedWidgets[i][j] = createdObjects[i][j]
          if typeof eachArrayElement is "string"
            if eachArrayElement.startsWith "$"
              referenceNumberAsString = eachArrayElement.substring(1)
              referenceNumber = parseInt referenceNumberAsString
              clonedWidgets[i][j] = clonedWidgets[referenceNumber]


    return clonedWidgets[0]
  # this part is excluded from the fizzygum homepage build <<«

  # Injecting code /////////////////////////////////////////

  # if a function, the txt must contain the parameters and
  # the arrow and the body
  injectProperty: (propertyName, txt) ->
    # this.target[propertyName] = evaluate txt
    @evaluateString "@" + propertyName + " = " + txt
    # if we are saving a function, we'd like to
    # keep the source code so we can edit Coffeescript
    # again.
    if Utils.isFunction @[propertyName]
      @[propertyName + "_source"] = txt
    @sourceChanged()

  injectProperties: (codeBlurb) ->

    codeBlurb = codeBlurb.replace(/^[ \t]*$/gm,"\n")
    codeBlurb = codeBlurb + "\n# end injected code"

    # ([a-zA-Z_$][0-9a-zA-Z_$]*) is the variable name
    regex = /^([a-zA-Z_$][0-9a-zA-Z_$]*)[ \t]*=[ \t]*([^]*?)(?=^[\w#$])/gm

    while (m = regex.exec(codeBlurb))?
      # This is necessary to avoid infinite loops with zero-width matches
      if m.index == regex.lastIndex
        regex.lastIndex++
      # The result can be accessed through the `m`-variable.
      #m.forEach (match, groupIndex) ->
      #  console.log ''
      @injectProperty m[1],m[2]
  
  # Widget dragging (and dropping) /////////////////////////////////////////
  
  # (In this comment section "non-float" dragging and "dragging" are
  # interchangeable unless made explicit)
  #
  # Usually when you "stick" a Widget A onto another B, it
  # remains "solid" to its parent, so A grabs to B when dragged.
  #
  # On the other hand, a SliderButton doesn't grab to the parent when
  # dragged, rather it's loose, as expected. (The fact that it
  # stays within the bounds of the parent when dragged is another matter).
  #
  # So via this method the system can determine what the
  # "top of the drag" is starting from any Widget.
  # The process of finding the top of the drag involves going up
  # the chain and finding the first Widget that is loose. Then that
  # will be the top of the drag, and the whole TREE under that widget
  # will be dragged.
  #
  # If the widgets grab each other up to the WorldWdgt, then the World
  # can't be dragged, so there is no drag happening.
  #
  # Usually though at some point up the chain a widget won't
  # grab to its parent, so a dragging top is indeed found.
  #
  # Example chain: A grabs to parent B doesn't grab to parent C.
  # So A can be dragged: the whole tree under B is dragged (i.e. A B in
  # this case).
  #
  # If going up the chain of "grabbing" Widgets a Widget rejects being
  # dragged then the drag will be prevented. This rejection happens
  # via the "rejectDrags" method. In that way, for example
  # for the ColorPaletteWdgt, you can avoid grabs (because drags on
  # a ColorPaletteWdgt are expected to pick colors).
  #
  # So in the case above if B returns true in rejectDrags, then B
  # can be dragged and none of the children of B can be dragged either
  # (so: nor A nor B can't be dragged).
  #
  # Note that there is no away to prevent users from "picking up"
  # a Widget and then do a drag (which in that case would be a FLOATING drag).

  grabsToParentWhenDragged: ->
    if @parent?

      if @parent == world
        return @isLockingToPanels

      if @_amIDirectlyInsideScrollPanelWdgt()
        if @parent.parent.canScrollByDraggingForeground and @parent.parent.anyScrollBarShowing()
          return true
        else
          return @isLockingToPanels

      if @parent instanceof PanelWdgt
        return @isLockingToPanels

      # not attached to desktop, not inside a scrollable Panel
      # and not inside a Panel.
      # So, for example, when this widget is attached to another widget
      # attached to the world (because then it should remain solid
      # with the parent)
      return true

    # doesn't have a parent
    return false

  rejectDrags: ->
    @defaultRejectDrags

  # finds the first widget (including this one)
  # that doesn't grab to its parent
  # returns nil if going up the grabbing chain
  # a widget rejects the drag
  findFirstLooseWidget: ->
    if @rejectDrags()
      return nil

    if @nonFloatDragging?
      return @

    if !@grabsToParentWhenDragged()
      return @

    scanningWidgets = @
    while scanningWidgets.parent?
      scanningWidgets = scanningWidgets.parent

      if scanningWidgets.rejectDrags()
        return nil

      if scanningWidgets.nonFloatDragging?
        return scanningWidgets

      if !scanningWidgets.grabsToParentWhenDragged()
        return scanningWidgets

    return nil

  findRootForGrab: ->
    return @findFirstLooseWidget()

  _amIDirectlyInsideScrollPanelWdgt: ->
    if @parent?
      if (@parent instanceof PanelWdgt) or (@parent instanceof SimpleVerticalStackPanelWdgt)
        if @parent.parent?
          if (@parent.parent instanceof ScrollPanelWdgt) and !(@parent.parent instanceof ListWdgt)
            return true
    return false

  _amIDirectlyInsideNonTextWrappingScrollPanelWdgt: ->
    if @_amIDirectlyInsideScrollPanelWdgt()
      if !@parent.parent.isTextLineWrapping
        return true
    return false

  # the only trick here is that we stop at the first
  # clipping widget, because if a widget is inside a clipping
  # widget, it doesn't contribute to any shadow.
  firstParentOwningMyShadow: ->
    if @hasShadow()
      return @

    scanningWidgets = @
    while scanningWidgets.parent?
      scanningWidgets = scanningWidgets.parent
      # TODO actually stop at the first
      # CLIPPING widget (more generic), not
      # just a PanelWdgt
      if scanningWidgets.clipsAtRectangularBounds
        return nil
      if scanningWidgets.hasShadow()
        return scanningWidgets

    return nil

  # if true, then the drag will be a float drag
  # otherwise it will be a nonfloating drag
  detachesWhenDragged: ->
    true
  
  isBeingFloatDragged: ->

    if !world.hand?
      return false

    # first check if the hand is floatdragging
    # anything, in that case if it's floatdragging
    # it can't be non-floatdragging
    if world.hand.nonFloatDraggedWdgt?
      return false

    # then check if my root is the hand
    if @root() == world.hand
      return true

    # if we are here it means we are not being
    # nonfloatdragged
    return false

  # Widget dragging (and dropping) /////////////////////////////////////////

  # finds the first parent that is a PopUp
  firstParentThatIsAPopUp: ->
    if !@parent? then return @
    return @parent.firstParentThatIsAPopUp()

  anyParentPopUpMarkedForClosure: ->
    if @isPopUpMarkedForClosure
      return true
    else if @parent?
      return @parent.anyParentPopUpMarkedForClosure()
    return false

  rootForFocus: ->
    if !@parent? or
      @parent == world
        return @
    @parent.rootForFocus()

  moveInFrontOfSiblings: ->
    @moveAsLastChild()
    @fullChanged()

  isInForeground: ->
    @rootForFocus()?.isLastChild()

  bringToForeground: ->
    @rootForFocus()?.moveAsLastChild()
    @rootForFocus()?.fullChanged()


  # note that "propagateKillPopUps" doesn't necessarily
  # go up the "parent" trail, for pop ups this method goes up
  # another trail of pop up ownership named via the
  # "widgetOpeningThePopUp" property, that is
  # independent of the parent trail
  propagateKillPopUps: ->
    if @parent?
      @parent.propagateKillPopUps()

  mouseDownLeft: (pos) ->
    @bringToForeground()
    @escalateEvent "mouseDownLeft", pos

  mouseClickLeft: (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    @escalateEvent "mouseClickLeft", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

  onClickOutsideMeOrAnyOfMyChildren: (functionName, arg1, arg2, arg3)->
    if functionName?
      @clickOutsideMeOrAnyOfMeChildrenCallback = [functionName, arg1, arg2, arg3]
      world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.add @
    else
      #console.log "****** onClickOutsideMeOrAnyOfMyChildren removing element"
      world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.delete @

  _reactToBeingDropped: (whereIn) ->
    @rememberFractionalSituationInHoldingPanel()
    
  wantsDropOf: (aWdgt) ->
    return @_acceptsDrops

  enableDrops: ->
    @_acceptsDrops = true

  disableDrops: ->
    @_acceptsDrops = false
  
  pickUp: ->
    oldParent = @parent
    oldParent?.childBeingPickedUp? @
    world.hand.grab @
    # if one uses the "deferred" API then we need to look
    # into the "desiredExtent" as the true extent has yet
    # to be settled
    if @desiredExtent?
      @fullRawMoveTo world.hand.position().subtract @desiredExtent.floorDivideBy 2
    else
      @fullRawMoveTo world.hand.position().subtract @fullBounds().extent().floorDivideBy 2
    oldParent?.childPickedUp? @

  grabbedWidgetSwitcheroo: ->
    @
  
  # »>> this part is excluded from the fizzygum homepage build
  # note how this checks whether
  # at *any point* up in the
  # widgets hierarchy there is an ActivePointerWdgt
  # unused code
  isPickedUp: ->
    @parentThatIsA(ActivePointerWdgt)?
  # this part is excluded from the fizzygum homepage build <<«
  
  situation: ->
    # answer a dictionary specifying where I am right now, so
    # I can slide back to it if I'm dropped somewhere else
    if @parent
      return (
        origin: @parent
        position: @position().subtract @parent.position()
      )
    nil
  
  # »>> this part is excluded from the fizzygum homepage build
  # unused code
  slideBackTo: (situation, steps = 5) ->
    pos = situation.origin.position().add situation.position
    xStep = -(@left() - pos.x) / steps
    yStep = -(@top() - pos.y) / steps
    stepCount = 0
    oldStep = @step
    oldFps = @fps
    @fps = 0
    world.steppingWdgts.add @
    @step = =>
      @__commitMoveBy new Point xStep, yStep
      @fullChanged()
      stepCount += 1
      if stepCount is steps
        situation.origin.add @
        # _reactToChildDropped is cores-only now (non-settling), so it needs an enclosing settle -- the live
        # drop settles it in ActivePointerWdgt.drop; this (dead / homepage-excluded slide-back) path must
        # too. add above already self-settled the re-home.
        if situation.origin._reactToChildDropped
          situation.origin._settleLayoutsAfter => situation.origin._reactToChildDropped @
        @step = oldStep
        @fps = oldFps
        if @step == noOperation or !@step?
          world.steppingWdgts.delete @
  # this part is excluded from the fizzygum homepage build <<«
  
  
  # Widget utilities ////////////////////////////////////////////////////////
  
  # Create a resize/move HandleWdgt of `type` and corner-attach it to myself (I become its @target), tracking
  # it in the temporary-adjusters set so it is torn down when handles are hidden. _addNoSettle (not add): a
  # hover-shown handle rides the showResize caller's frame, byte-identical to the old in-constructor corner-
  # attach. The explicit defaultLayoutSpecWhenAddedTo(@) is needed because a DIRECT _addNoSettle bypasses add()'s
  # default-arg resolution (and an intermediate container _addNoSettle, e.g. a windowed target, would otherwise
  # re-default the unset spec to FREEFLOATING before it reaches the handle).
  addAndTrackHandle: (type) ->
    handle = new HandleWdgt type
    @_addNoSettle handle, nil, handle.defaultLayoutSpecWhenAddedTo(@)
    world.temporaryHandlesAndLayoutAdjusters.add handle

  # CONVERT (end-of-cycle-flush-drawdown): showing the resize/move handles is a DISCRETE menu/click action, so it
  # SELF-SETTLES (one flush per outermost public mutation). The handles attach via _addNoSettle (addAndTrackHandle /
  # addAsSibling*), which only RIDE a settle; the trigger chain (mouseClickLeft -> trigger) provided none, so the
  # _addNoSettle invalidate rode the per-frame end-of-cycle flush. The recursion to @parent goes through the
  # NON-settling core so the whole show-handles tree flushes ONCE. (ScrollPanelWdgt overrides the core, not this.)
  showResizeAndMoveHandlesAndLayoutAdjusters: ->
    @_settleLayoutsAfter => @_showResizeAndMoveHandlesAndLayoutAdjustersNoSettle()

  _showResizeAndMoveHandlesAndLayoutAdjustersNoSettle: ->
    if @isFreeFloating()
      @addAndTrackHandle "resizeHorizontalHandle"
      @addAndTrackHandle "resizeVerticalHandle"
      @addAndTrackHandle "moveHandle"
      @addAndTrackHandle "resizeBothDimensionsHandle"
    else
      if (@lastSiblingBeforeMeSuchThat((m) -> m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED)?) and !@siblingBeforeMeIsA(StackElementsSizeAdjustingWdgt)
        world.temporaryHandlesAndLayoutAdjusters.add \
          @addAsSiblingBeforeMe \
            new StackElementsSizeAdjustingWdgt,
            nil,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

      #console.log "@: " + @.toString() + " amITheLastSibling: " + @amITheLastSibling()

      if (@firstSiblingAfterMeSuchThat((m) -> m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED)?) and !@siblingAfterMeIsA(StackElementsSizeAdjustingWdgt)
        world.temporaryHandlesAndLayoutAdjusters.add \
          @addAsSiblingAfterMe \
            new StackElementsSizeAdjustingWdgt,
            nil,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
      if @parent?
        @parent._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle()

  
  inform: (msg) ->
    text = msg
    if msg
      text = msg.toString()  if msg.toString
    else
      text = "NULL"
    m = new MenuWdgt @, false, @, true, true, text
    m.addMenuItem "Ok"
    m.popUpCenteredAtHand world

  prompt: (msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded) ->

    prompt = new PromptWdgt(@, msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded)

    prompt.popUpAtHand()
    prompt.tempPromptEntryField.text.edit()

  textPrompt: (msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded) ->

    prompt = new CodePromptWdgt(msg, target, callback, defaultContents, width, floorNum,
    ceilingNum, isRounded)
    world.openWindowWith prompt, (new Point 460, 400), world.hand.position().subtract(new Point 50, 100)


  
  pickColor: (msg, callback, defaultContents) ->
    colorPicker = new ColorPickerWdgt defaultContents
    menu = new MenuWdgt @, false, @, true, true, msg or "", colorPicker
    menu.silentAdd colorPicker
    menu.addLine 2

    menu.addMenuItem "Ok", true, @, callback
    # we name the button "Close" instead of "Cancel"
    # because we are not undoing any change we made
    # that would be rather difficult in case of
    # multiple prompts being pinned down and changing
    # the property concurrently
    menu.addMenuItem "Close", true, menu, "close"

    menu.popUpAtHand()

  inspect: ->
    @spawnInspector @

  # the single inspector entry point. Every inspect path routes here:
  # the world menu and widget context-menu "inspect" items, the "dev -> inspect"
  # item (MenusHelper), and a text editor's "inspect selection". This is the
  # convenience wrapper that opens the inspector WINDOWED — its content fills a
  # 560x410 WindowWdgt that supplies the chrome + background + resizer. The
  # InspectorWdgt also renders and resizes correctly on its OWN now
  # (`world.add new InspectorWdgt target`): when free-floating it paints its own
  # background and is resized via its @resizer handle. This wrapper stays the
  # default for the menu/inspect paths; the naked path is the additional mode.
  spawnInspector: (inspectee) ->
    inspector = new InspectorWdgt inspectee
    world.openWindowWith inspector, (new Point 560, 410), world.hand.position().subtract(new Point 50, 100)

  createConsole: ->
    inspector = new ConsoleWdgt @
    world.openWindowWith inspector, (new Point 285, 290), world.hand.position().subtract(new Point 50, 100)

  spawnNextTo: (widgetToBeNextTo, whereToAddIt) ->
    if !whereToAddIt?
      whereToAddIt = widgetToBeNextTo.parent
    whereToAddIt.add @
    @fullRawMoveTo widgetToBeNextTo.center()
    @fullRawMoveWithin whereToAddIt
    
  
  # Widget menus ////////////////////////////////////////////////////////////////
  
  # context Menus are whatever appears when one right-clicks
  # on something. It could be a custom menu, or the standard
  # menu on the desktop, or a menu to disambiguate which
  # widget it's being selected...
  buildContextMenu: ->
    # commented-out addendum for the implementation of 1):
    #show the normal menu in case there is text selected,
    #otherwise show the spacial multiplexing list
    #if !@world().caret
    #  if @world().hand.allWdgtsAtPointer().length > 2
    #    return @buildHierarchyMenu()

    widgetToAskMenuTo = @

    # check if a parent wants to take over my menu (and hopefully
    # coalesce some of my entries!). In such case let it open the
    # menu. Used for example for scrollable text (which is text inside
    # a ScrollPanelWdgt).
    anyParentsTakingOverMyMenu = @allParentsTopToBottomSuchThat (m) ->
      (m instanceof ScrollPanelWdgt) and m.takesOverAndCoalescesChildrensMenus
    if anyParentsTakingOverMyMenu? and anyParentsTakingOverMyMenu.length > 0
      widgetToAskMenuTo = anyParentsTakingOverMyMenu[0]

    if widgetToAskMenuTo.overridingContextMenu
      return widgetToAskMenuTo.overridingContextMenu()

    if world.isDevMode
      hierarchyMenuWidgets = widgetToAskMenuTo.getHierarchyMenuWidgets()
      # if the widget is attached to the world then there is no
      # disambiguation to do, just build the context menu.
      # Same if there would be one only entry in the hierarchyMenu
      # then again just build the context menu for that entry.
      # Otherwise we actually have to build the spacial
      # demultiplexing menu.
      if widgetToAskMenuTo.parent is world
        return widgetToAskMenuTo.buildWidgetContextMenu()
      else if hierarchyMenuWidgets.length < 2
        return hierarchyMenuWidgets[0].buildWidgetContextMenu()
      else
        return widgetToAskMenuTo.buildHierarchyMenu hierarchyMenuWidgets

  getHierarchyMenuWidgets: ->
    hierarchyMenuWidgets = []
    # Spacial multiplexing
    # (search "multiplexing" for the other parts of
    # code where this matters)
    # There are two interpretations of what this
    # list should be:
    #   1) all widgets "pierced through" by the pointer
    #   2) all widgets parents of the topmost widget under the pointer
    # 2 is what is used in Cuis
    # commented-out addendum for the implementation of 1):
    # parents = @world().hand.allWdgtsAtPointer().reverse()
    parents = @allParentsTopToBottom()
    parents.forEach (each) ->
      # only add widgets that have a menu, and
      # leave out the world itself and the widgets that are about
      # to be destroyed
      if (each.buildWidgetContextMenu) and (each isnt world) and (!each.anyParentPopUpMarkedForClosure())
        # * leave out SimpleVerticalStackPanelWdgt when
        #   inside a SimpleVerticalStackScrollPanelWdgt
        # * also leave out PanelWdgt when
        #   inside a ScrollPanelWdgt
        # * also leave out ScrollPanelWdgt when
        #   inside a FolderWindowWdgt
        # ...because they would be redundant - there is no need for the
        # user to know or have access to the internal structure of
        # those constructs
        if (!((each instanceof SimpleVerticalStackPanelWdgt) and (each.parent instanceof SimpleVerticalStackScrollPanelWdgt))) and
         (!((each instanceof PanelWdgt) and (each.parent instanceof ScrollPanelWdgt))) and
         (!((each instanceof ScrollPanelWdgt) and (each.parent instanceof FolderWindowWdgt)))
          hierarchyMenuWidgets.push each

    hierarchyMenuWidgets
  
  # When user right-clicks on a widget that is a child of other widgets,
  # then it's ambiguous which of the widgets she wants to operate on.
  # An example is right-clicking on a ToolTipWdgt: did she
  # mean to operate on the speech bubble or did she mean to operate on
  # the text widget contained in it?
  # This menu lets her disambiguate.
  buildHierarchyMenu: (widgetsHierarchy) ->
    if !widgetsHierarchy?
      widgetsHierarchy = @getHierarchyMenuWidgets()
    menu = new MenuWdgt @, false, @, true, true, nil
    widgetsHierarchy.forEach (each) ->
      textLabelForWidget = each.toString().slice 0, 50
      textLabelForWidget = textLabelForWidget.replace "Wdgt", ""
      menu.addMenuItem textLabelForWidget + " ➜", false, each, "popupDeveloperMenu", nil, nil, nil, nil, nil, nil, nil, true

    menu

  popupDeveloperMenu: (widgetOpeningThePopUp)->
    @buildWidgetContextMenu(widgetOpeningThePopUp).popUpAtHand()

  popUpColorSetter: ->
    @pickColor "color:", "setColor", Color.BLACK


  transparencyPopout: (menuItem)->
    @prompt menuItem.parent.title + "\nalpha\nvalue:",
      @,
      "setAlphaScaled",
      (@alpha * 100).toString(),
      nil,
      1,
      100,
      true

  # »>> this part is excluded from the fizzygum homepage build
  showOutputPins: (a,b,c,d) ->
    world.widgetsToBePinouted.add b

  removeOutputPins: (a,b,c,d) ->
    world.widgetsToBePinouted.delete b

  serialiseToMemory: ->
    world.lastSerializationString = @serialize()

  deserialiseFromMemoryAndAttachToHand: ->
    derezzedObject = world.deserialize world.lastSerializationString
    derezzedObject.pickUp()

  deserialiseFromMemoryAndAttachToWorld: ->
    derezzedObject = world.deserialize world.lastSerializationString
    world.add derezzedObject
  # this part is excluded from the fizzygum homepage build <<«

  buildBaseWidgetClassContextMenu: (widgetOpeningThePopUp) ->

    menu = new MenuWdgt(widgetOpeningThePopUp, false,
      @,
      true,
      true,
      (@constructor.name.replace "Wdgt", "") or (@constructor.toString().replace "Wdgt", "").split(" ")[1].split("(")[0])

    if world.isIndexPage
      menu.addMenuItem "color...", true, @, "popUpColorSetter" , "choose another color \nfor this widget"
      menu.addMenuItem "transparency...", true, @, "transparencyPopout", "set this widget's\nalpha value"
      menu.addMenuItem "resize/move...", true, @, "showResizeAndMoveHandlesAndLayoutAdjusters", "show a handle\nwhich can be floatDragged\nto change this widget's" + " extent"
      menu.addLine()
      menu.addMenuItem "duplicate", true, @, "duplicateMenuAction" , "make a copy"
      menu.addMenuItem "create shortcut", true, @, "createReference", "creates a reference to this wdgt and leaves it on the desktop"
      menu.addMenuItem "pick up", true, @, "pickUp", "disattach and put \ninto the hand"
    else
      menu.addMenuItem "color...", true, @, "popUpColorSetter" , "choose another color \nfor this widget"
      menu.addMenuItem "transparency...", true, @, "transparencyPopout", "set this widget's\nalpha value"
      menu.addMenuItem "resize/move...", true, @, "showResizeAndMoveHandlesAndLayoutAdjusters", "show a handle\nwhich can be floatDragged\nto change this widget's" + " extent"
      menu.addLine()
      menu.addMenuItem "duplicate", true, @, "duplicateMenuActionAndPickItUp" , "make a copy\nand pick it up"
      menu.addMenuItem "pick up", true, @, "pickUp", "disattach and put \ninto the hand"
      menu.addMenuItem "attach...", true, @, "attach", "stick this widget\nto another one"
      menu.addMenuItem "inspect", true, @, "inspect", "open a window\non all properties"
      menu.addMenuItem "create shortcut", true, @, "createReference", "creates a reference to this wdgt and leaves it on the desktop"
      menu.addMenuItem "test menu ➜", false, menusHelper, "testMenu", "debugging and testing operations"
      menu.addLine()

    if (@parent instanceof PanelWdgt) and !(@parent instanceof ScrollPanelWdgt)
      if @parent == world
        whereToOrFrom = "desktop"
      else
        whereToOrFrom = "panel"
      if @isLockingToPanels
        menu.addMenuItem "unlock from " + whereToOrFrom, true, @, "toggleIsLockingToPanels", "make this widget\nunmovable"
      else
        menu.addMenuItem "lock to " + whereToOrFrom, true, @, "toggleIsLockingToPanels", "make this widget\nmovable"

    if !world.isIndexPage
      menu.addMenuItem "hide", true, @, "hide"

    if @isWindow?()
      menu.addMenuItem "close", true, @, "close"
    else
      menu.addMenuItem "delete", true, @, "close"

    if world.isIndexPage or world.macroToolkit?.aMacroIsRunning?
      menu.addLine()
      menu.addMenuItem "dev ➜", false, menusHelper, "popUpDevToolsMenu", "dev tools"
    else
      menu.addMenuItem "destroy", true, @, "fullDestroy"

    menu

  # Widget-specific menu entries are basically the ones
  # beyond the generic entries above.
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    if @layoutSpec == LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT
      # it could be possible to figure out layouts when the vertical
      # stack doesn't contrain the content widths but it's rather
      # more complicated so we are not doing it for the time
      # being
      if @parent?.constrainContentWidth
        @layoutSpecDetails.addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu

  buildWidgetContextMenu: (widgetOpeningThePopUp) ->
    menu = @buildBaseWidgetClassContextMenu widgetOpeningThePopUp
    @addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu

    if @addShapeSpecificMenuItems?
      menu = @addShapeSpecificMenuItems menu
    menu

  # Widget menu actions
  calculateAlphaScaled: (alpha) ->
    if typeof alpha is "number"
      unscaled = alpha / 100
      return Math.min Math.max(unscaled, 0.1), 1
    else
      newAlpha = parseFloat alpha
      unless isNaN newAlpha
        unscaled = newAlpha / 100
        return Math.min Math.max(unscaled, 0.1), 1

  # »>> this part is excluded from the fizzygum homepage build
  setPadding: (paddingOrWidgetGivingPadding, widgetGivingPadding) ->
    if widgetGivingPadding?.getValue?
      padding = widgetGivingPadding.getValue()
    else
      padding = paddingOrWidgetGivingPadding

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

  setPaddingTop: (paddingOrWidgetGivingPadding, widgetGivingPadding) ->
    if widgetGivingPadding?.getValue?
      padding = widgetGivingPadding.getValue()
    else
      padding = paddingOrWidgetGivingPadding

    if padding
      unless @paddingTop == padding
        @paddingTop = padding
        @changed()

    return padding

  setPaddingBottom: (paddingOrWidgetGivingPadding, widgetGivingPadding) ->
    if widgetGivingPadding?.getValue?
      padding = widgetGivingPadding.getValue()
    else
      padding = paddingOrWidgetGivingPadding

    if padding
      unless @paddingBottom == padding
        @paddingBottom = padding
        @changed()

    return padding

  setPaddingLeft: (paddingOrWidgetGivingPadding, widgetGivingPadding) ->
    if widgetGivingPadding?.getValue?
      padding = widgetGivingPadding.getValue()
    else
      padding = paddingOrWidgetGivingPadding

    if padding
      unless @paddingLeft == padding
        @paddingLeft = padding
        @changed()

    return padding

  setPaddingRight: (paddingOrWidgetGivingPadding, widgetGivingPadding) ->
    if widgetGivingPadding?.getValue?
      padding = widgetGivingPadding.getValue()
    else
      padding = paddingOrWidgetGivingPadding

    if padding
      unless @paddingRight == padding
        @paddingRight = padding
        @changed()

    return padding
  # this part is excluded from the fizzygum homepage build <<«

  setAlphaScaled: (alphaOrWidgetGivingAlpha, widgetGivingAlpha) ->
    if widgetGivingAlpha?.getValue?
      alpha = widgetGivingAlpha.getValue()
    else
      alpha = alphaOrWidgetGivingAlpha

    if alpha
      alpha = @calculateAlphaScaled alpha
      unless @alpha == alpha
        @alpha = alpha
        @changed()

    return alpha

  newParentChoice: (ignored, theWidgetToBeAttached) ->
    # this is what happens when "each" is
    # selected: we attach the selected widget
    @add theWidgetToBeAttached
    # I just attached the selected widget; if I am a scroll panel my contents changed, so re-fit my contents +
    # scrollbars. SELF-SETTLE it (CONVERT, end-of-cycle-flush-drawdown): this menu action is a DISCRETE public
    # mutation, so the re-fit must flush at the action, not ride the per-frame end-of-cycle flush. @add already
    # self-settled the attach; the _reFitContainer re-fit (NEEDED when the widget attaches directly, so @add took
    # the no-re-fit `super` path) now self-settles too -- one extra flush, idempotent with @add's. The
    # _reLayoutChildrenAndScrollbars? pre-guard keeps this ScrollPanel-only -- only ScrollPanelWdgt + subclasses
    # (incl. ListWdgt) define it; any other widget is a no-op (replacing `if @ instanceof ScrollPanelWdgt`). NB it
    # is intentionally narrower than _reFitContainer's own _reLayoutChildren? gate (which also matches Window/Stack).
    @_settleLayoutsAfter(=> @_reFitContainer()) if @_reLayoutChildrenAndScrollbars?

  # »>> this part is excluded from the fizzygum homepage build
  newParentChoiceWithHorizLayout: (ignored, theWidgetToBeAttached) ->
    # this is what happens when "each" is
    # selected: we attach the selected widget
    @add theWidgetToBeAttached, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    # SELF-SETTLE my contents/scrollbar re-fit exactly as newParentChoice above (CONVERT, discrete menu action;
    # ScrollPanel-only pre-guard; @add already self-settled the attach).
    @_settleLayoutsAfter(=> @_reFitContainer()) if @_reLayoutChildrenAndScrollbars?
  # this part is excluded from the fizzygum homepage build <<«

  attach: ->
    choices = world.plausibleTargetAndDestinationWidgets @

    # my direct parent might be in the
    # options which is silly, leave that one out
    choicesExcludingParent = []
    choices.forEach (each) =>
      if each != @parent
        choicesExcludingParent.push each

    if choicesExcludingParent.length > 0
      menu = new MenuWdgt @, false, @, true, true, "choose new parent:"
      choicesExcludingParent.forEach (each) =>
        menu.addMenuItem each.toString().slice(0, 50), true, each, "newParentChoice", nil, nil, nil, nil, nil, nil, nil, true
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible widgets to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # widgets then show some kind of message.
      menu = new MenuWdgt @, false, @, true, true, "no widgets to attach to"
    menu.popUpAtHand()

  # »>> this part is excluded from the fizzygum homepage build
  attachWithHorizLayout: ->
    choices = world.plausibleTargetAndDestinationWidgets @

    # my direct parent might be in the
    # options which is silly, leave that one out
    choicesExcludingParent = []
    choices.forEach (each) =>
      if each != @parent
        choicesExcludingParent.push each

    if choicesExcludingParent.length > 0
      menu = new MenuWdgt @, false, @, true, true, "choose new parent:"
      choicesExcludingParent.forEach (each) =>
        menu.addMenuItem each.toString().slice(0, 50), true, each, "newParentChoiceWithHorizLayout", nil, nil, nil, nil, nil, nil, nil, true
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible widgets to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # widgets then show some kind of message.
      menu = new MenuWdgt @, false, @, true, true, "no widgets to attach to"
    menu.popUpAtHand()
  # this part is excluded from the fizzygum homepage build <<«
  
  toggleIsLockingToPanels: ->
    @isLockingToPanels = not @isLockingToPanels

  lockToPanels: ->
    @isLockingToPanels = true

  unlockFromPanels: ->
    @isLockingToPanels = false

  # ---------------------------------------------------------------------
  # locking of contents

  enableDragsDropsAndEditing: ->

    if @dragsDropsAndEditingEnabled
      return
    @dragsDropsAndEditingEnabled = true

    if @contents?
      whereToAct = @contents
      if whereToAct.dragsDropsAndEditingEnabled
        return
      whereToAct.dragsDropsAndEditingEnabled = true
    else
      whereToAct = @


    @parent?.makePencilYellow?()
    whereToAct.dragsDropsAndEditingEnabled = true

    whereToAct.enableDrops()

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets whereToAct

    if childrenNotHandlesNorCarets?
      for each in childrenNotHandlesNorCarets
        each.unlockFromPanels()
        each.contrastOutFromPanelColor?()
        if each.isEditable?
          each.isEditable = true


  disableDragsDropsAndEditing: ->
    if !@dragsDropsAndEditingEnabled
      return
    @dragsDropsAndEditingEnabled = false

    if @contents?
      whereToAct = @contents
      if !whereToAct.dragsDropsAndEditingEnabled
        return
      whereToAct.dragsDropsAndEditingEnabled = false
    else
      whereToAct = @


    @parent?.makePencilClear?()
    whereToAct.disableDrops()

    whereToAct.dragsDropsAndEditingEnabled = false

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets whereToAct

    if childrenNotHandlesNorCarets?
      for each in childrenNotHandlesNorCarets
        each.lockToPanels()
        each.blendInWithPanelColor?()
        if each.isEditable?
          each.isEditable = false
          if world.caret?.target == each
            world.stopEditing()


  # ---------------------------------------------------------------------

  prepareToBeGrabbed: ->
    @userMovedThisFromComputedPosition = true
    @unlockFromPanels()
    @setLayoutSpec LayoutSpec.ATTACHEDAS_FREEFLOATING

  deduplicateSettersAndSortByMenuEntryString: (menuEntriesStrings, functionNamesStrings) ->
    menuEntriesStrings = menuEntriesStrings.uniqueKeepOrder()
    functionNamesStrings = functionNamesStrings.uniqueKeepOrder()

    #1) combine the arrays:
    list = []
    j = 0
    while j < menuEntriesStrings.length
      list.push
        'menuEntriesStrings': menuEntriesStrings[j]
        'functionNamesStrings': functionNamesStrings[j]
      j++
    #2) sort:
    list.sort (a, b) ->
      if a.menuEntriesStrings < b.menuEntriesStrings then -1 else if a.menuEntriesStrings == b.menuEntriesStrings then 0 else 1
      #Sort could be modified to, for example, sort on the age
      # if the name is the same.
    #3) separate them back out:
    k = 0
    while k < list.length
      menuEntriesStrings[k] = list[k].menuEntriesStrings
      functionNamesStrings[k] = list[k].functionNamesStrings
      k++

    return [menuEntriesStrings, functionNamesStrings]

  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    if !menuEntriesStrings?
      menuEntriesStrings = []
      functionNamesStrings = []
    menuEntriesStrings.push "color", "background color"
    functionNamesStrings.push "setColor", "setBackgroundColor"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    if !menuEntriesStrings?
      menuEntriesStrings = []
      functionNamesStrings = []
    # we don't add anything so no need to sort/deduplicate
    return [menuEntriesStrings, functionNamesStrings]

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    if !menuEntriesStrings?
      menuEntriesStrings = []
      functionNamesStrings = []
    menuEntriesStrings.push "width", "height", "alpha 0-100", "padding", "padding top", "padding bottom", "padding left", "padding right"
    functionNamesStrings.push "rawSetWidth", "rawSetHeight", "setAlphaScaled", "setPadding", "setPaddingTop", "setPaddingBottom", "setPaddingLeft", "setPaddingRight"

    if @addShapeSpecificNumericalSetters?
      [menuEntriesStrings, functionNamesStrings] = @addShapeSpecificNumericalSetters menuEntriesStrings, functionNamesStrings

    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  # »>> this part is excluded from the fizzygum homepage build
  allSetters: (menuEntriesStrings, functionNamesStrings) ->
    if !menuEntriesStrings?
      menuEntriesStrings = []
      functionNamesStrings = []

    [menuEntriesStrings, functionNamesStrings] = @colorSetters menuEntriesStrings, functionNamesStrings
    [menuEntriesStrings, functionNamesStrings] = @stringSetters menuEntriesStrings, functionNamesStrings
    [menuEntriesStrings, functionNamesStrings] = @numericalSetters menuEntriesStrings, functionNamesStrings

    # already sorted and deduplicated by the last of the calls above
    return [menuEntriesStrings, functionNamesStrings]
  # this part is excluded from the fizzygum homepage build <<«
  
  # Widget entry field tabbing //////////////////////////////////////////////
  
  allEntryFields: ->
    # an entry field is any editable StringWdgt-family widget. isTextEntryField (on StringWdgt,
    # inherited by SimplePlainTextWdgt et al.) replaces the `instanceof StringWdgt or instanceof
    # SimplePlainTextWdgt` test -- whose second clause was already redundant, since
    # SimplePlainTextWdgt is-a StringWdgt. (type-test-elimination campaign)
    @collectAllChildrenBottomToTopSuchThat (each) ->
      each.isEditable and each.isTextEntryField?()
  
  
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
  #	levels in the Widgetic tree (e.g. dialog boxes) for a more fine-grained
  #	control over the tabbing cycle.
  #
  # Widget::nextTab = function (editField) {
  #	var	next = this.nextEntryField(editField);
  #	editField.clearSelection();
  #	next.selectAll();
  #	next.edit();
  #};
  #
  # Widget::previousTab = function (editField) {
  #	var	prev = this.previousEntryField(editField);
  #	editField.clearSelection();
  #	prev.selectAll();
  #	prev.edit();
  #};
  #
  #
  
  # Widget events --------------------------------------------

  # TODO I'm sure there is a cleaner way to handle arbitrary
  # number of arguments here
  escalateEvent: (functionName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    handler = @parent
    if handler?
      handler = handler.parent  while not handler[functionName] and handler.parent?
      handler[functionName] arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9  if handler[functionName]
  
  
  # Widget eval. Used by the Inspector and the text widget.
  evaluateString: (codeSource) ->
    JSCode = compileFGCode codeSource, true
    #console.log JSCode
    result = eval JSCode
    @_reLayoutSelf()
    @changed()
  
  


  # ------------------------------------------------------------------------------------
  # Layouts
  # ------------------------------------------------------------------------------------
  # So layouts in Fizzygum work the following way:
  #  1) Any Widget can contain a number of other widgets
  #     according to a number of layouts *simultaneously*
  #     e.g. you can have two widgets being horizontally stacked
  #     and two other widgets being inset for example
  #  2) There is no need for an explicit special container. Any
  #     Widget can be a container when needed.
  #  3) The default attaching of Widgets to a Widget puts them
  #     under the effect of the most basic layout: the FREEFLOATING
  #     layout.
  #  3) A user can only do a high-level resize or move to a FREEFLOATING
  #     Widget. All other Widgets are under the effect of more complex
  #     layout strategies so they can't be moved willy nilly
  #     directly by the user via some high-level "resize" or "move"
  #     Control of size and placement can be done, but indirectly via other
  #     means below.
  #  4) You CAN control the size and location of Widgets under the
  #     effect of complex layouts, but only indirectly: by programmatically
  #     changing their layout spec properties.
  #  5) You CAN also manually control the size and location of Widgets
  #     under the effect of complex layouts by using special Adjusting
  #     Widgets, which are provided by the container, and give handles
  #     to manually control the content. These manual controls
  #     under the courtains go and programmatically modify the layout
  #     spec properties of the content.


  # »>> this part is excluded from the fizzygum homepage build
  minWidth: 10
  desiredWidth: 20
  maxWidth: 100
  # this part is excluded from the fizzygum homepage build <<«

  # »>> this part is excluded from the fizzygum homepage build
  minHeight: 10
  # this part is excluded from the fizzygum homepage build <<«
  desiredHeight: 20
  # »>> this part is excluded from the fizzygum homepage build
  maxHeight: 100
  # this part is excluded from the fizzygum homepage build <<«

  # »>> this part is excluded from the fizzygum homepage build
  makeSpacersTransparent: ->
    for C in @children
      C.makeSpacersTransparent()

  makeSpacersOpaque: ->
    for C in @children
      C.makeSpacersOpaque()
  # this part is excluded from the fizzygum homepage build <<«

  # The bare layout-enqueue ATOM: put me into the recalculateLayouts until-loop and mark my layout invalid, WITHOUT
  # climbing to ancestors and WITHOUT the flow-rule throw / careless-push audit that _invalidateLayout wraps around it
  # for the climbing content-widget case. This is the ONE primitive under all three enqueue paths: _invalidateLayout
  # (calls it, THEN climbs), _reFitContainer's in-pass arm (enqueue one directly-affected container, no climb --
  # up-propagation is restored by that container's own seam re-firing if its geometry moves), and the caret's
  # scroll-follow (an inert free-floating overlay, reached via _invalidateLayout's inert-receiver branch). NO CLIMB
  # (the ex-"NoClimb" suffix, dropped in the __ rename): this alone does NOT tell my container I changed -- a CONTENT widget must use
  # _invalidateLayout, which climbs. Only framework layout machinery calls this (the two methods above); feature code
  # schedules via _invalidateLayout. (docs/unify-layout-enqueue-primitives-plan.md.)
  __markForRelayout: ->
    if @layoutIsValid then world.widgetsThatMaybeChangedLayout.push @
    @layoutIsValid = false

  _invalidateLayout: (triggeringChild = nil) ->
    # FREEFLOATING-skip -- THE single home of the rule: a freefloating child's add/remove/resize
    # cannot change its parent's layout (it's positioned absolutely, not laid out by the parent).
    # The climb and every teardown/move site pass the child whose change triggered this invalidate;
    # a nil triggeringChild is a direct self-invalidate from feature code. This return MUST stay
    # BEFORE the _recalculatingLayouts throw below: a freefloating teardown is a silent no-op today
    # (the inline `unless …isFreeFloating()` guard meant _invalidateLayout wasn't even called for it),
    # so it has to keep being a silent no-op even if it happens mid-pass -- it must never throw.
    return if triggeringChild?.isFreeFloating()
    # INERT-RECEIVER branch: a free-floating + inert overlay (caret / resize handle) has no parent layout to climb
    # into, and is excluded from every container's content-bounds (childrenNotHandlesNorCarets), so re-running its
    # _reLayout re-fits NOTHING above it. The climb, the flow-rule throw, and the careless-push audit below are
    # therefore all structurally INAPPLICABLE -- they PASS here, they are not silenced (the worry this resolves:
    # docs/unify-layout-enqueue-primitives-plan.md §2). So enqueue just me, no climb. Gated on BOTH predicates so no
    # content widget can slip onto the no-climb path -- a content widget's container genuinely needs the climb. (This
    # is the single home of the caret's self-schedule, reached via CaretWdgt._requestScrollFollow -> here; today only
    # the caret exercises it -- handles are moved by drag machinery through raw setters, never self-invalidate.)
    if @isFreeFloating() and @isLayoutInert?()
      @__markForRelayout()
      return
    # FLOW-RULE INVARIANT (fail fast): the low-level geometry mutators (raw*/silent*/fullRaw*)
    # must not SCHEDULE layout -- they only mutate; scheduling a (re-)layout is the public
    # self-settling tier's job. If an invalidate reaches here while recalculateLayouts is running,
    # a raw setter is (re-)scheduling layout mid-pass -- the Phase 3b Slice 2 app-freeze (a
    # container resizing its children climbed an invalidate back into itself, so the until-loop
    # never converged). The raw setters were migrated to honour this and a build-time lint (rule
    # [E]) enforces it statically; this throw is the RUNTIME tripwire for anything that slips past
    # the lint (e.g. a dynamic/duck-typed call it can't see). The throw is safe to be hard now
    # (task #18): the recalculateLayouts catch is strictly non-flushing and defers recovery outside
    # the flush, so this throw is caught there, reported via the layout-error path (loud
    # console.error + in-world console), and the world keeps running -- never a freeze.
    if world?._recalculatingLayouts
      throw new Error "FLOWRULE_VIOLATION: _invalidateLayout() during a layout pass by " + (@constructor?.name) + " -- a raw/silent/fullRaw setter must not schedule layout (task #17)"
    # DEBUG (WorldWdgt.auditPaintTimeLayoutScheduling, default off): PAINT must be READ-ONLY. healingRectangles-
    # Phase is true only inside updateBroken's paint pass; reaching here then means a widget SCHEDULED layout while
    # being painted -- crossing the render/layout boundary. Record its ctor for the per-frame paint-schedules log.
    # (The caret's paint-time scroll-follow, the original such offender, was moved to a post-flush pre-paint step.)
    if world?.healingRectanglesPhase and world.auditPaintTimeLayoutScheduling and not @isOrphan()
      (world._paintTimeLayoutSchedules ?= []).push @constructor?.name
    # DEBUG (WorldWdgt.auditUndeclaredEndOfCycle, default off): an OFF-SETTLE push (not @_inLayoutMutation) on
    # an ATTACHED widget made OUTSIDE a *Coalesced declaration (_coalescedDeclarationDepth == 0) is the
    # "careless" set the eventual declared-coalescing gate will reject -- record its ctor for the end-of-cycle
    # log. ORPHAN pushes are excluded: an off-world (under-construction) widget legitimately defers and settles
    # when attached (the childRemoved lesson) -- it is not careless, and is the bulk of the macro-driver noise.
    # Recorded BEFORE __markForRelayout flips @layoutIsValid, and only on an ACTUAL push (@layoutIsValid still
    # true) -- an already-invalid widget is not re-pushed, so it must not be re-counted.
    if @layoutIsValid and world.auditUndeclaredEndOfCycle and world._coalescedDeclarationDepth == 0 and not world._inLayoutMutation and not @isOrphan()
      (world._undeclaredEndOfCyclePushes ?= []).push @constructor?.name
    # the bare enqueue (+ mark invalid): the shared primitive. The climb is this method's OWN extra responsibility,
    # added explicitly below -- __markForRelayout deliberately does not climb (see its comment).
    @__markForRelayout()
    # CLIMB: tell my parent that a child (me) changed. Pass @ so the parent short-circuits via the
    # return at the top iff I'm freefloating -- this replaces the old inline `unless @isFreeFloating()
    # and @parent?` climb-guard (the freefloating rule now lives in ONE place, the param check above).
    @parent?._invalidateLayout(@)

  # »>> this part is excluded from the fizzygum homepage build
  setMinAndMaxBoundsAndSpreadability: (minBounds, desiredBounds, spreadability = LayoutSpec.SPREADABILITY_MEDIUM) ->
    @minWidth = minBounds.x
    @minHeight = minBounds.y

    @desiredWidth = desiredBounds.x
    @desiredHeight = desiredBounds.y

    @maxWidth = desiredBounds.x + spreadability * desiredBounds.x/100
    @maxHeight = desiredBounds.y + spreadability * desiredBounds.y/100

    # ELIMINATE (end-of-cycle-flush-drawdown): every caller is a CONSTRUCTOR, so @ is an ORPHAN here -- the
    # widget is just sized now and re-fit TOP-DOWN when it is later added to the world (a self-settling add
    # re-lays-out its subtree). So scheduling a re-layout DURING construction is WASTED work: it only rode the
    # per-frame end-of-cycle flush (~12 records -- the resize HandleWdgt sizing itself, plus the new-HandleWdgt
    # cell/button construction in the layout/resize tests). Skip it for the orphan. An ATTACHED caller (there is
    # none today, but the method is public) still schedules via _invalidateLayout, so the public contract holds.
    # The skip is SAFE specifically at THIS sizing-then-add seam -- NOT as a blanket _invalidateLayout
    # orphan-skip, which broke 63 tests because orphan invalidates are generally load-bearing (cf.
    # PanelWdgt.childRemoved). A disable-probe confirmed the orphan re-layout changes nothing (byte-identical).
    # (Sets @maxWidth/@maxHeight inline rather than via _setMaxDimNoSettle, which would re-introduce the very
    # construction invalidate this skips; setMaxDim's own callers are unaffected.)
    @_invalidateLayout() unless @isOrphan()


  # CONVERT (end-of-cycle-flush-drawdown): setMaxDim is the public "set the max dimension" mutator, so it must
  # SELF-SETTLE (one flush per outermost public mutation) like every other public geometry setter. Its only
  # high-frequency caller -- the stack-divider drag (StackElementsSizeAdjustingWdgt.nonFloatDragging) -- and the
  # construction-time setMinAndMaxBoundsAndSpreadability call the NON-settling _setMaxDimNoSettle core instead, so
  # the drag-move STREAM still COALESCES into the one end-of-cycle flush (a core rides the cycle by design; the
  # goal is coalescing WITHOUT a PUBLIC method skipping its settle).
  setMaxDim: (overridingMaxDim) ->
    @_settleLayoutsAfter => @_setMaxDimNoSettle overridingMaxDim

  # PUBLIC COALESCED entrypoint -- the first of the *Coalesced family. Same EFFECT as the private
  # _setMaxDimNoSettle core, but PUBLIC (anyone, incl. programmatic callers, may use it) and INTENTION-REVEALING:
  # it DECLARES that this is an intentional per-event-stream mutation (a drag / scroll / key burst) whose layout
  # flush should ride the ONE end-of-cycle settle instead of self-settling per call -- so a stream draining many
  # mutations per frame collapses N flushes into 1. (Contrast: the bare public setMaxDim self-settles, for a
  # single discrete mutation; the _NoSettle core is internal-only and feature code should NOT reach into it.)
  # Because the coalescing is DECLARED here, the end-of-cycle settle/audit can eventually tell an intentional
  # coalesced mutation from a public method that carelessly forgot to self-settle -- the hook for that
  # "allowed in the final settle" flag/mode goes right here. world.coalescingEnabled is the A/B switch: ON
  # (default) coalesces via the core; OFF self-settles per call (the plain setMaxDim), so we can MEASURE whether
  # coalescing is warranted for a given stream (docs/coalescing-measurement.md -- e.g. key-repeat rarely bursts
  # enough to matter). Default ON => byte-identical to calling the _NoSettle core directly.
  setMaxDimCoalesced: (overridingMaxDim) ->
    if world?.coalescingEnabled
      @_coalescedDeclare => @_setMaxDimNoSettle overridingMaxDim
    else
      @setMaxDim overridingMaxDim

  # Run a coalesced-mutation core inside a DECLARATION window: while it runs, world._coalescedDeclarationDepth
  # is > 0, so the off-settle invalidates the core schedules are marked INTENTIONAL and the end-of-cycle debug
  # check (WorldWdgt.auditUndeclaredEndOfCycle) does NOT flag them as "careless". Every *Coalesced entrypoint
  # wraps its core through here. Nestable; returns the core's value. (Default-off audit => ~zero overhead.)
  _coalescedDeclare: (coreThunk) ->
    return coreThunk() unless world?
    world._coalescedDeclarationDepth += 1
    try
      return coreThunk()
    finally
      world._coalescedDeclarationDepth -= 1

  _setMaxDimNoSettle: (overridingMaxDim) ->

    #   currentMax = @getRecursiveMaxDim()
    #   ratio = currentMax.x / overridingMaxDim.x
    #
    #   for C in @children
    #     if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    #       C.setMaxDim C.getRecursiveMaxDim().divideBy ratio


    @maxWidth = overridingMaxDim.x
    @maxHeight = overridingMaxDim.y

    @_invalidateLayout()

  # if you use this paragraph, then
  # we have a system where you CAN easily resize things to any
  # size, so to have maximum flexibility we are not binding the
  # minimum of a container to the minimums of the contents.
  # getDesiredDim: ->
  #   desiredDim = new Point @desiredWidth, @desiredHeight
  #   return desiredDim.min @getMaxDim()
  # getMinDim: ->
  #   minDim = new Point @minWidth, @minHeight
  #   return minDim.min @getMaxDim()
  # getMaxDim: ->
  #   maxDim = new Point @maxWidth, @maxHeight
  #   return maxDim

  # if you use this paragraph, then the container of further
  # layouts will have a minimum equal to the sum of minimums
  # of the contents.
  getDesiredDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    @getRecursiveDesiredDim()
  getMinDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    @getRecursiveMinDim()
  getMaxDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    maxDim = new Point @maxWidth, @maxHeight
    return maxDim.max @getDesiredDim()


  getRecursiveDesiredDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    
    # TBD the exact shape of @checkDesiredDimCache
    #if @checkDesiredDimCache
    #  return @desiredDimCache

    desiredWidth = nil
    desiredHeight = nil
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
    if @isInCollapsedSubtree() then return new Point 0,0
    # TBD the exact shape of @checkMinDimCache
    #if @checkMinDimCache
    #  # the user might have forced the "desired" to
    #  # be smaller than the standard minimum set by
    #  # the widget
    #  return Math.min @minDimCache, @getRecursiveDesiredDim()

    minWidth = 0
    minHeight = 0
    gotAMinWidth = false
    gotAMinHeight = false
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getMinDim()
        gotAMinWidth = true
        minWidth += childSize.width()
        if minHeight < childSize.height()
          gotAMinHeight = true
          minHeight = childSize.height()

    if !gotAMinWidth
      minWidth = @minWidth

    if !gotAMinHeight
      minHeight = @minHeight

    # TBD the exact shape of @checkMinDimCache
    @checkMinDimCache = true
    @minDimCache = new Point minWidth, minHeight

    # the user might have forced the "desired" to
    # be smaller than the standard minimum set by
    # the widget
    return @minDimCache.min @getRecursiveMaxDim()

  getRecursiveMaxDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0

    # TBD the exact shape of @checkMaxDimCache
    #if @checkMaxDimCache
    #  # the user might have forced the "desired" to
    #  # be bigger than the standard maximum set by
    #  # the widget
    #  return Math.max @maxDimCache, @getRecursiveDesiredDim()

    maxWidth = 0
    maxHeight = 0
    gotAMaxWidth = false
    gotAMaxHeight = false
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getMaxDim()
        gotAMaxWidth = true
        maxWidth += childSize.width()
        if maxHeight < childSize.height()
          gotAMaxHeight = true
          maxHeight = childSize.height()

    if !gotAMaxWidth
      maxWidth = @maxWidth

    if !gotAMaxHeight
      maxHeight = @maxHeight

    # TBD the exact shape of @checkMaxDimCache
    @checkMaxDimCache = true
    @maxDimCache = new Point maxWidth, maxHeight

    # the user might have forced the "desired" to
    # be bigger than the standard maximum set by
    # the widget
    return @maxDimCache

  countOfChildrenInHorizontalStackLayout: ->
    if @isInCollapsedSubtree() then return 0
    count = 0
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED and
      !C.isInCollapsedSubtree()
        count++
    return count
  # this part is excluded from the fizzygum homepage build <<«

  # it's useful to know when a widget defers its layout
  # because it means that its current size is indicative
  # (particularly the children's sizes and position)
  implementsDeferredLayout: ->
    @_reLayout != Widget::_reLayout

  __calculateNewBoundsWhenDoingLayout: (newBoundsForThisLayout) ->
    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      # stuff that is being floatDragged ignores any @desiredPosition,
      # the relationship between the Active Pointer and its "dragged" widgets
      # is not quite a layout relationship
      if !@isBeingFloatDragged() and @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    return newBoundsForThisLayout

  _handleCollapsedStateShouldWeReturn: ->
    if @isInCollapsedSubtree()
      @markLayoutAsFixed()
      return true
    return false

  markLayoutAsFixed: ->
    @layoutIsValid = true

  _reLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # freefloating layouts never need
    # adjusting. We marked the @layoutIsValid
    # to false because it's an important breadcrumb
    # for finding the widgets that actually have a
    # layout to be recalculated but this Widget
    # now needs to do nothing.
    #if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
    #  @markLayoutAsFixed()
    #  return
    
    # TODO should we do a fullChanged here?
    # rather than breaking what could be many
    # rectangles?

    # the fullRawMoveTo makes sure that all children
    # that are float-attached move together with the
    # widget.
    @fullRawMoveTo newBoundsForThisLayout.origin
    
    # bad kludge here but I think there will be more
    # of these as we move over to the new layouts, we'll
    # probably have split Widgets for the new layouts mechanism.
    # FIT_BOX_TO_TEXT content re-sizes its OWN height to its text, so hand it the
    # full bounds (origin + extent) in one shot; everything else just takes the
    # new extent (its origin was already set by the fullRawMoveTo above). ANY
    # contained TextWdgt qualifies (a non-text widget has no fittingSpec, so it
    # falls through to the else).
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
      @rawSetBounds newBoundsForThisLayout
    else
      @rawSetExtent newBoundsForThisLayout.extent()

    if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPLEFT or @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT or @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOMRIGHT or @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_RIGHT or @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOM
      if @parent
        xDim = @parent.width()
        yDim = @parent.height()
        minDim = Math.min(xDim, yDim) * @layoutSpec_cornerInternal_proportionOfParent + @layoutSpec_cornerInternal_fixedSize

        @_commitExtentAndNotify new Point minDim, minDim

        # TODO this hack is because I couldn't initialise this properly
        # where I should, due to load dependency problems
        if !@layoutSpec_cornerInternal_inset?
          @layoutSpec_cornerInternal_inset = new Point 0, 0

        if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPLEFT
          @fullRawMoveTo new Point @parent.left() + @layoutSpec_cornerInternal_inset.x, @parent.top() + @layoutSpec_cornerInternal_inset.y
        else if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT
          @fullRawMoveTo new Point @parent.right() - minDim - @layoutSpec_cornerInternal_inset.x, @parent.top() + @layoutSpec_cornerInternal_inset.y
        else if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOMRIGHT
          @fullRawMoveTo new Point @parent.right() - minDim - @layoutSpec_cornerInternal_inset.x, @parent.bottom() - minDim - @layoutSpec_cornerInternal_inset.y
        else if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_RIGHT
          @fullRawMoveTo new Point @parent.right() - minDim - @layoutSpec_cornerInternal_inset.x, Math.floor(@parent.top() + (@parent.extent().y - minDim)/2)
        else if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOM
          @fullRawMoveTo new Point Math.floor(@parent.left() + (@parent.extent().x - minDim)/2), @parent.bottom() - minDim - @layoutSpec_cornerInternal_inset.y

    # »>> this part is excluded from the fizzygum homepage build
    else if @countOfChildrenInHorizontalStackLayout() != 0

      @addOrRemoveAdders()

      min = @getRecursiveMinDim()
      desired = @getRecursiveDesiredDim()
      max = @getRecursiveMaxDim()
      
      # we are forced to be in a space smaller
      # than the minimum needed. We obey.
      if min.width() >= newBoundsForThisLayout.width()
        if @parent == world then console.log "case 1"
        # Give all children under minimum
        # this is unfortunate but
        # we don't want to rely on clipping what's
        # beyond the allocated space. Clipping
        # in this Widgetic implementation has special
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
          C._reLayout childBounds

      # the min is within the bounds but the desired is just
      # equal or larger than the bounds.
      # i.e. we have more space then what is strictly needed
      # but less of what is desired.
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
          C._reLayout childBounds

      # min and desired are strictly less than the bounds
      # i.e. we have more space than needed or desired
      # allocate all the desired spaces, and on top of that
      # give extra space based on maximum widths
      else
        maxMargin = max.width() - desired.width()
        totDesWidth = desired.width()
        extraSpace = newBoundsForThisLayout.width() - desired.width()
        if extraSpace < 0
          console.log "this shouldn't happen, extraSpace is negative: " + extraSpace
          debugger
        if @parent == world then console.log "case 3 maxMargin: " + maxMargin

        if maxMargin > 0
          ssss = 0
        else if maxMargin == 0
          ssss = 1
        else
          console.log "this shouldn't happen, maxMargin negative: " + maxMargin + " max.width(): " + max.width() + " desired.width(): " + desired.width()
          debugger

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
          C._reLayout childBounds
    # this part is excluded from the fizzygum homepage build <<«

    @markLayoutAsFixed()

    # if I just did my layout, also do the layout
    # of all children that have position/size depending on mine
    allCornerLayoutedChildren = @children.filter (m) -> m.layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPLEFT or m.layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT or m.layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOMRIGHT or m.layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_RIGHT or m.layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOM
    for w in allCornerLayoutedChildren
      w._reLayout()


  # »>> this part is excluded from the fizzygum homepage build
  removeAdders: ->
    @_showsAdders = false
    @_invalidateLayout()

  showAdders: ->
    @_showsAdders = true
    if @children.length == 0
      @_addNoSettle \
        new LayoutElementAdderOrDropletWdgt,
        nil,
        LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @_invalidateLayout()

  addOrRemoveAdders: ->

    if !@_showsAdders
      allAddersToBeDestroyed =
        @collectAllChildrenBottomToTopSuchThat (m) ->
          m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED and
          m.isLayoutAdderOrDroplet?()
      for C in allAddersToBeDestroyed
        C.fullDestroy()
      return

    if @children.length == 0
      @_addNoSettle \
        new LayoutElementAdderOrDropletWdgt,
        nil,
        LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    while true
      leftToDo = @firstChildSuchThat (m) ->
          if m.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            return false
          if m.isLayoutAdderOrDroplet?()
            return false
          kkk = m.lastSiblingBeforeMeSuchThat(
              (mm) ->
                mm.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            )
          if !kkk?
            return true
          if kkk.isLayoutAdderOrDroplet?()
            return false
          return true
      if !leftToDo?
        break
      leftToDo.addAsSiblingBeforeMe \
            new LayoutElementAdderOrDropletWdgt,
            nil,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    # this code is duplicate of the one above and is only needed for
    # adding the last adder/droplet.

    while true
      leftToDo = @firstChildSuchThat (m) ->
          if m.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            return false
          if m.isLayoutAdderOrDroplet?()
            return false
          kkk = m.firstSiblingAfterMeSuchThat(
              (mm) ->
                mm.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            )
          if !kkk?
            return true
          if kkk.isLayoutAdderOrDroplet?()
            return false
          return true
      if !leftToDo?
        break
      leftToDo.addAsSiblingAfterMe \
            new LayoutElementAdderOrDropletWdgt,
            nil,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
  # this part is excluded from the fizzygum homepage build <<«
