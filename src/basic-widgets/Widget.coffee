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
  # lastBuiltInstanceNumericID is the source of instanceNumericID (see assignUniqueID). Unlike
  # instancesCounter (the never-reset lifetime/profiling count) it is RESET to 0 per widget class
  # at ResetWorld (WorldWdgt), so SystemTest widget IDs restart deterministically each test.
  @lastBuiltInstanceNumericID: 0
  instanceNumericID: 0

  # Serialization: own properties the serializer must SKIP (frame timing + the
  # WorldWdgt.geometryVersion-keyed derived geometry caches — all re-derived on demand
  # after a restore). Merged up the class chain by Serializer.transientsForClass; a
  # subclass ADDS to this list. See docs/serialization-duplication-reference.md §5.
  @serializationTransients: [
    "lastTime"
    # the back-buffer render cache (BackBufferMixin) — rebuilt on demand by
    # createRefreshOrGetBackBuffer, so it is never serialized; the restored widget
    # re-renders it on its first paint.
    "backBuffer", "backBufferContext"
    "cachedFullBounds", "checkFullBoundsCache", "childrenBoundsUpdatedAt"
    "cachedFullClippedBounds", "checkFullClippedBoundsCache"
    "cachedVisibleBasedOnIsVisibleProperty", "checkVisibleBasedOnIsVisiblePropertyCache"
    "cachedClippedThroughBounds", "checkClippedThroughBoundsCache"
    "cachedClipThrough", "checkClipThroughCache"
    "cachedIsInCollapsedSubtree", "checkIsInCollapsedSubtreeCache"
    # §4.4 island buffer cache source-lane fields: ephemeral per-frame paint state (a widget ref +
    # a virtual rect), consumed at flesh-out — never persist them (a snapshot must not pin an island).
    "_islandBufferSourceIsland", "_islandBufferSourceVirtualRect"
  ]

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

  # menu merging is useful when you want a "parent"
  # menu to take over the menus of their children.
  # This assumes that for certain widgets is OK to just exist
  # "in their whole" without letting the user obviously take it
  # apart or mess with its parts.
  #
  # The best example is scrollable text: when one right-clicks
  # on scrollable text, the menu OF THE SCROLLFRAME that
  # contains it takes over.
  #
  # Otherwise, without merging, there would FIRST be a
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
  takesOverAndMergesChildrensMenus: false

  onNextStep: nil # optional function to be run once. Not currently used in Fizzygum

  clickOutsideMeOrAnyOfMeChildrenCallback: [nil]

  textDescription: nil

  # note that not all the changed widgets have this flag set
  # because if a parent does a fullChanged, we don't set this
  # flag in the children. This is intentionally so,
  # as we don't want to navigate the children too many times.
  # If you want to know whether a widget has changed its
  # position, use the hasMaybeChangedPaintBounds:
  # method instead, which looks at this flag (and another one).
  # See comment below on fullPaintBoundsMaybeChanged
  # for more information.
  paintBoundsMaybeChanged: false
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
  # use the hasMaybeChangedPaintBounds: method,
  # which checks recursively with the parents both the
  # fullPaintBoundsMaybeChanged flag and the
  # paintBoundsMaybeChanged flag.
  # Another way of doing this is to mark with a special flag
  # all the widget that touch their bounds or positions, but
  # then it's sort of costly to un-set such flag in all such
  # widgets, as we'd have to keep the "changed" widgets in a special
  # array to do that. Seems quite a bit more work and complication,
  # so just use the method.
  fullPaintBoundsMaybeChanged: false
  fullClippedBoundsWhenLastPainted: nil

  # §4.4 island buffer cache — the "source" (old-position) lane. When this widget last painted INTO
  # an island's buffer, these hold the PRE-mapping virtual full-bounds and that island, so a later
  # move-within-island can erase the vacated buffer region (recordDrawnAreaForNextBrokenRects sets
  # them; the flesh-out source lane consumes+clears them). nil on every ordinary (non-island) paint.
  _islandBufferSourceIsland: nil
  _islandBufferSourceVirtualRect: nil

  cachedFullBounds: nil
  checkFullBoundsCache: nil
  childrenBoundsUpdatedAt: -1

  cachedFullClippedBounds: nil
  checkFullClippedBoundsCache: nil

  cachedVisibleBasedOnIsVisibleProperty: nil
  checkVisibleBasedOnIsVisiblePropertyCache: nil

  cachedClippedThroughBounds: nil
  checkClippedThroughBoundsCache: nil

  cachedClipThrough: nil
  checkClipThroughCache: nil

  cachedIsInCollapsedSubtree: nil
  checkIsInCollapsedSubtreeCache: nil

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

  # I am a transient EPHEMERAL overlay (highlight / pinout / — future — drag affordance),
  # created and destroyed by the per-cycle reconciler in WorldWdgt.doOneCycle, not by normal
  # widget code. Dedicated overlay classes (HighlighterWdgt) set this on their prototype; ad-hoc
  # overlays (the pinout StringWdgt) set it per-instance at creation. Read via the isEphemeral()
  # capability, which drives hit-test exclusion, shadow-skip and world-snapshot exclusion (below).
  _ephemeralOverlay: false

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

  startCountdownForBubbleHelp: (contents) ->
    ToolTipWdgt.createInAWhileIfHandStillContainedInWidget @, contents

  constructor: ->
    super()
    @assignUniqueID()

    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED

    @bounds = Rectangle.EMPTY
    @minimumExtent = new Point 5,5

    @_commitBounds new Rectangle 0,0,50,40

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
    @parent?._beforeChildClosed? @
    if world.basementWdgt?
      # §7.5 Bug B (model a) + latent 2 (Option B): re-home the whole FIGURE, not just me -- if I am the
      # sole content of an island (sugar OR explicit), the island IS my transform, so sending only me to
      # the basement would strand the empty island and drop my transform. Only the re-homing TARGET
      # changes; my own close bookkeeping above still runs on me. Off any island this is me (byte-identical).
      world.basementWdgt._addLostWidgetNoSettle @_enclosingIslandFigure()
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
    # (_beforeChildDestroyed -> resetToDefaultContents) -- is safe inside this _inLayoutMutation:
    # resetToDefaultContents rebuilds through the non-settling @_buildAndConnectChildrenNoSettle (not the
    # public self-settler), and the chrome it constructs adds to ORPHANS, which are exempt from the
    # flush-throw (see _settleLayoutsAfter's orphan guard). So nothing re-enters a settle mid-destroy.
    @_settleLayoutsAfter => @_destroyNoSettle()

  _destroyNoSettle: ->

    @parent?._beforeChildDestroyed? @
    @unregisterThisInstance()
    world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.delete @
    world.keyboardEventsReceivers.delete @
    # a connection-bearing widget that became a dataflow node drops its edges from the shared engine index on
    # death — a dead node left in @edgesFrom/@edgesTo is a leak AND a ghost recompute (spec §2, the node-death
    # API). A cheap no-op for a widget that was never a node.
    world.dataflow?.removeAllEdgesOf @
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
    WorldWdgt.noteStructureChange()

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
      if previousParent._reactToChildRemoved?
        previousParent._reactToChildRemoved @

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
    WorldWdgt.noteStructureChange()
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
    WorldWdgt.noteStructureChange()
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

    WorldWdgt.noteStructureChange()
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
  
  boundingBoxTight: ->
    new Rectangle @leftTight(), @topTight(), @rightTight(), @bottomTight()

  _resizeToWithoutSpacing: ->

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
  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_applyWidth newWidth
    if @implementsDeferredLayout()
      # immediate mutator: APPLY the re-fit now (synchronous _reLayout), never SCHEDULE it
      # (no _invalidateLayout). See task #17 -- low-level mutators must not schedule layout.
      @_reLayout()
    @height()

  # §4.1 pure measure -- the side-effect-free counterpart of _setWidthSizeHeightAccordingly above:
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
  _applyBounds: (newBounds) ->
    if @bounds.equals newBounds
      return

    unless @bounds.origin.equals newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @__breakMoveResizeCaches()
      @changed()

    @_applyExtent newBounds.extent()

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
    # ALREADY inside a flush/pass?  Two cases, split by whether the receiver is part of the live world:
    #  - ORPHAN receiver -> DEFER (record the change, do NOT flush). This is the ONE remaining settle
    #    deferral, and it is framework-internal: a constructor that builds its innards (e.g. the icon
    #    buttons WindowWdgt._buildAndConnectChildren makes) runs INSIDE the enclosing mutation's settle and
    #    adds to an orphan; it must not re-enter recalculateLayouts (which would throw). It settles for real
    #    when that enclosing operation's flush completes -- or, for a widget that stays detached, on its next
    #    public call / on attach. (isOrphan() is false for the world itself and for anything on the hand, so
    #    world.add / dragged-widget mutations are NOT orphans and fall through to the throw.) See
    #    docs/orphan-settledness-plan.md and docs/deferred-layout-refit-and-add-design.md (D3).
    #  - ATTACHED receiver -> THROW. A public geometry setter reached on an attached widget mid flush/pass is
    #    a flow-soundness violation: internal layout (_reLayout / _reLayoutSelf / ...) must use the immediate
    #    (geometry) mutators, never the public deferred API -- otherwise recalculateLayouts would re-enter.
    #    The static gate buildSystem/check-layering.js catches the name-recognized internal methods at BUILD
    #    time ([A] the public geometry/text setters, [G] the structural self-settling wrappers
    #    destroy/close/fullDestroy/...); this runtime backstop covers what the name-scanner CANNOT: a
    #    structural add() (its name collides with Point#add, so [G] excludes it) and any wrapper reached
    #    TRANSITIVELY or via a dynamically-typed receiver.
    if world._inLayoutMutation or world._recalculatingLayouts
      return coreThunk() if @isOrphan()
      throw new Error "Fizzygum: a public geometry setter was reached during a layout flush/pass -- internal layout code (_reLayout / _reLayoutSelf / ...) must use the immediate (geometry) mutators, not the public deferred API (see buildSystem/check-layering.js)."
    # NOT in a flush: settle NOW -- for ATTACHED widgets (always have) AND for ORPHANS (orphan-settledness,
    # docs/orphan-settledness-plan.md): a public mutation leaves the receiver's OWN subtree settled on return,
    # so there is no "is it settled here?" question for a detached/under-construction widget either.
    # recalculateLayouts lays out the orphan's queued invalidations, which are its own subtree (an orphan's
    # _invalidateLayout can't climb into the world -- it stops at parent==nil), so when the world is already
    # settled this flushes ONLY the orphan. The orphan's intrinsic (parentless) geometry re-settles to its
    # in-context form when it is later added to the world.
    world._inLayoutMutation = true
    try
      result = coreThunk()
      world.recalculateLayouts()
      return result
    finally
      world._inLayoutMutation = false

  # The REACTIVE-CONNECTOR settle lane: like _settleLayoutsAfter, but when an enclosing settle's MUTATION WINDOW
  # is already open (world._inLayoutMutation) it JOINS it (runs the core in it) instead of throwing. A connection
  # cascade (a wired reactive circuit) legitimately reaches a self-settling connector entrypoint mid-window --
  # e.g. the C<->F converter: cText's connector opens the settle, and the calc renders + fText's connector hops
  # run inside it -- so the whole cascade settles ONCE, when the OUTERMOST connector returns.
  # Reached from INSIDE the flush walk itself (world._recalculatingLayouts -- only layout code can get here, e.g.
  # a wired AxisWdgt tick label re-titled by its _reLayout firing its connection) it KEEPS the strict lane's
  # orphan-defer + flow-violation throw: layout code must not fire settling entrypoints, cascade or not.
  # RESTRICTED to _<name>Connector callers by check-layering rule [P] -- general/internal code must keep using
  # _settleLayoutsAfter (which also throws mid-WINDOW, surfacing the violation) or a _<name>NoSettle core.
  _settleLayoutsAfterOrJoinEnclosingPass: (coreThunk) ->
    unless world?
      return coreThunk()
    if world._recalculatingLayouts
      return coreThunk() if @isOrphan()
      throw new Error "Fizzygum: a connector entrypoint was reached from inside the layout flush walk -- layout code (_reLayout / _reLayoutSelf / ...) must not fire a connection's settling entrypoint (see buildSystem/check-layering.js, rule [P])."
    if world._inLayoutMutation
      return coreThunk()          # JOIN the enclosing settle's mutation window (no nested settle, no throw)
    world._inLayoutMutation = true
    try
      result = coreThunk()
      world.recalculateLayouts()
      return result
    finally
      world._inLayoutMutation = false

  # The ONE-SHOT frame setter: position AND extent in a single public mutation (ONE flush --
  # prefer this over a setExtent-then-moveTo pair, which flushes twice). Two call shapes:
  #   setBounds aRectangle            -- the Morphic/Cocoa-setFrame form
  #   setBounds aPosition, anExtent   -- origin + size as Points (the friendly form)
  setBounds: (aRectangleOrPosition, extent = nil) ->
    @_settleLayoutsAfter => @_setBoundsNoSettle aRectangleOrPosition, extent

  # Non-settling bounds core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredExtent /
  # @desiredPosition + invalidate, no flush -- rides an OUTER settle. Was setBounds' inline thunk.
  _setBoundsNoSettle: (aRectangleOrPosition, extent = nil) ->
    aRectangle = if extent? then aRectangleOrPosition.extent extent else aRectangleOrPosition
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

  # Silently commit my bounds (origin + extent): translate my origin, then commit my extent via the __commitExtent
  # leaf -- NO repaint, NO self-relayout. Used for construction-time sizing and by the top-down arrange (a container
  # sizing my frame already knows my new bounds, so no repaint/relayout is owed here).
  # (Collapsed 2026-07-01) The old "non-notifying twin" _applyBounds and this method became byte-identical once the
  # re-fit seam was deleted -- both are just a silent origin+extent commit -- so they are ONE method now (_commitBounds).
  _commitBounds: (newBounds) ->
    if @bounds.equals newBounds
      return

    unless @bounds.origin.equals newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @__breakMoveResizeCaches()

    @__commitExtent newBounds.extent()
  
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
      @checkVisibleBasedOnIsVisiblePropertyCache = WorldWdgt.visibilityVersion
      @cachedVisibleBasedOnIsVisibleProperty = false
      result = @cachedVisibleBasedOnIsVisibleProperty
    else # @isVisible is true
      if !@parent?
        result = true
      else
        if @checkVisibleBasedOnIsVisiblePropertyCache == WorldWdgt.visibilityVersion
          result = @cachedVisibleBasedOnIsVisibleProperty
        else
          @checkVisibleBasedOnIsVisiblePropertyCache = WorldWdgt.visibilityVersion
          @cachedVisibleBasedOnIsVisibleProperty = @parent.visibleBasedOnIsVisibleProperty()
          result = @cachedVisibleBasedOnIsVisibleProperty

    if world.doubleCheckCachedMethodsResults
      if result != @SLOWvisibleBasedOnIsVisibleProperty()
        debugger
        alert "visibleBasedOnIsVisibleProperty is broken"

    return result


  # doesn't take into account orphanage
  # or visibility
  SLOWfullBounds: ->
    result = @bounds
    @children.forEach (child) ->
      if child.SLOWvisibleBasedOnIsVisibleProperty() and
      !child.SLOWisInCollapsedSubtree()
        result = result.merge child.SLOWfullBounds()
    result

  SLOWfullClippedBounds: ->
    if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
      return Rectangle.EMPTY
    result = @SLOWclippedThroughBounds()
    @children.forEach (child) ->
      if child.SLOWvisibleBasedOnIsVisibleProperty() and !child.SLOWisInCollapsedSubtree()
        result = result.merge child.SLOWfullClippedBounds()
    #if this != world and result.corner.x > 400 and result.corner.y > 100 and result.origin.x ==0 and result.origin.y ==0
    #  debugger
    result

  # Independent (de-circularized) re-derivations of the version-keyed clipThrough /
  # clippedThroughBounds, mirroring their CACHED bodies exactly. Like the cached clipThrough,
  # the recursion terminates at the two overriders -- world and the hand -- which return their
  # raw @boundingBox() via matching SLOW* overrides (WorldWdgt / ActivePointerWdgt), exactly as
  # their cached clippedThroughBounds/clipThrough overrides do. The hand's override is NOT the
  # same as the generic clip-through-world computation (the hand is painted on top of
  # everything, unclipped -- and its @boundingBox() can be inside-out/empty, which the generic
  # intersect would normalize to EMPTY), so it MUST be mirrored explicitly per overrider; a
  # base-only guard cannot reproduce it.
  SLOWclipThrough: ->
    if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
      return Rectangle.EMPTY
    firstClipping = @SLOWfirstParentClippingAtBounds()
    if !firstClipping?
      firstClipping = world
    upstream = firstClipping.SLOWclipThrough()
    if @clipsAtRectangularBounds
      @boundingBox().intersect upstream
    else
      upstream

  SLOWclippedThroughBounds: ->
    if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
      return Rectangle.EMPTY
    @boundingBox().intersect @SLOWclipThrough()

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
  # measure (min-extent-clamped, as __commitExtent applies on commit) instead of its just-mutated applied
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
    if @checkFullBoundsCache == WorldWdgt.geometryVersion
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

    @checkFullBoundsCache = WorldWdgt.geometryVersion
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
      if @checkFullClippedBoundsCache == WorldWdgt.geometryVersion
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

    @checkFullClippedBoundsCache = WorldWdgt.geometryVersion
    @cachedFullClippedBounds = result
  
  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the smallest broken rectangle created by
  # a changed(), which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  clippedThroughBounds: ->

    if @checkClippedThroughBoundsCache == WorldWdgt.geometryVersion
      result = @cachedClippedThroughBounds
    else if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      @checkClippedThroughBoundsCache = WorldWdgt.geometryVersion
      @cachedClippedThroughBounds = Rectangle.EMPTY
      result = @cachedClippedThroughBounds
    else
      @checkClippedThroughBoundsCache = WorldWdgt.geometryVersion
      @cachedClippedThroughBounds = @boundingBox().intersect @clipThrough()
      result = @cachedClippedThroughBounds

    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWclippedThroughBounds()
        debugger
        alert "clippedThroughBounds is broken"

    return result
  
  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the "smallest broken rectangles"
  # which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  clipThrough: ->
    # answer which part of me is not clipped by a Panel
    if @checkClipThroughCache == WorldWdgt.geometryVersion
      result = @cachedClipThrough
    else if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      @checkClipThroughCache = WorldWdgt.geometryVersion
      @cachedClipThrough = Rectangle.EMPTY
      result = @cachedClipThrough
    else
      firstParentClippingAtBounds = @firstParentClippingAtBounds()
      if !firstParentClippingAtBounds?
        firstParentClippingAtBounds = world
      firstParentClippingAtBoundsClipThroughBounds = firstParentClippingAtBounds.clipThrough()
      @checkClipThroughCache = WorldWdgt.geometryVersion
      if @clipsAtRectangularBounds
        @cachedClipThrough = @boundingBox().intersect firstParentClippingAtBoundsClipThroughBounds
      else
        @cachedClipThrough = firstParentClippingAtBoundsClipThroughBounds
      result = @cachedClipThrough

    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWclipThrough()
        debugger
        alert "clipThrough is broken"

    return result

  # Affine transforms (docs/affine-transforms-plan.md §4.5): map a damage rect from
  # THIS widget's plane up to the SCREEN plane, through each ancestor
  # TransformFrameWdgt ("island") on my parent chain that currently has a
  # non-identity transform. A widget not inside any non-identity island — the
  # overwhelming common case, and ALWAYS when the feature is dormant — gets its rect
  # back UNCHANGED (same object), so the broken-rect machinery stays byte-identical.
  # The pre-image is an axis-aligned virtual-plane rect; each island maps it to an
  # integer axis-aligned AABB (§4.3), so the result is a plain Rectangle safe to feed
  # the existing merge/dedupe. The mapped inner damage is clipped in the correct
  # (screen) plane against the OUTERMOST island's own visible rect (= its footprint ∩
  # its ancestor screen clips) — clipping the pre-image plane would not commute with
  # the transform (§4.11).
  mapRectToScreen: (aRect, depositBufferDirty = false) ->
    result = aRect
    outermostIsland = nil
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        # §4.4 buffer cache — the "destination" (new-position) deposit: the PRE-mapping rect is in
        # THIS island's virtual (buffer) plane, so it is exactly the region this widget now occupies
        # in the island's buffer. Deposit it as content-dirty. Only the two damage-flesh-out lanes
        # pass depositBufferDirty=true; the OTHER caller (recordDrawnAreaForNextBrokenRects, the
        # paint-time snapshot) passes false, so a mere repaint never dirties the buffer. Depositing
        # on EACH crossed island handles nesting for free. Zero dormant cost (off-island never enters).
        ancestor._depositIslandBufferDirtyRect result if depositBufferDirty
        result = ancestor.transformSpec.mapRect result, ancestor.bounds
        outermostIsland = ancestor
      ancestor = ancestor.parent
    if outermostIsland?
      result = result.intersect outermostIsland.clippedThroughBounds()
    result

  # Affine transforms (§4.6): map a SCREEN point down into THIS widget's plane, by
  # applying the INVERSE of each ancestor island's transform, OUTERMOST first (the
  # inverse of mapRectToScreen's innermost-first forward chain). A widget not inside
  # any non-identity island gets the point back UNCHANGED — so hit-testing is
  # byte-identical when dormant. Used by the hit-test predicate so a widget's
  # bounds/pixel test runs in the plane where its (virtual) geometry lives; corner
  # fall-through and per-pixel transparency then come out exact for free (§10.4).
  screenPointToMyPlane: (aPoint) ->
    islands = nil
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        islands ?= []
        islands.push ancestor            # innermost first
      ancestor = ancestor.parent
    return aPoint if !islands?
    result = aPoint
    for island in islands by -1          # apply inverses outermost → innermost
      result = island.transformSpec.inverseMapPoint result, island.bounds
    result

  # Affine transforms (§4.6): the exact inverse of screenPointToMyPlane — map a point in THIS
  # widget's (virtual) plane UP to the SCREEN plane, applying each ancestor island's FORWARD
  # transform innermost → outermost. A widget not inside any non-identity island gets the point
  # back UNCHANGED (same object), so this is byte-identical when dormant. Used by the macro
  # toolkit to click an island-inner widget at the on-screen pixel its virtual point maps to:
  # once an ancestor island scales/rotates, a widget's screen position is NOT its bounds
  # position, so `.center()` alone would click the wrong pixel (and miss).
  localPointToScreen: (aPoint) ->
    result = aPoint
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        result = ancestor.transformSpec.mapPoint result, ancestor.bounds
      ancestor = ancestor.parent
    result

  # Affine transforms (§4.6): true if a non-identity TransformFrameWdgt island is on my parent chain.
  # The shared predicate behind the Phase-1-symmetric interaction guards (handles refuse, float-drag
  # escalates to the island). Dormant returns false with no island. (This is the §9 memoization point:
  # a cached inside-an-island flag invalidated on reparent/spec change would replace this walk — banked.)
  _isInsideNonIdentityIsland: ->
    @_enclosingNonIdentityIsland()?

  # Affine transforms (§6 R2): the INNERMOST enclosing non-identity island (TransformFrameWdgt) on my
  # parent chain, or nil. My (virtual) geometry lives in THIS island's plane — clippedThroughBounds and
  # the mapRectToScreen / screenPointToMyPlane chain are all expressed there — so ephemeral chrome that
  # must track me (a highlight) is parented HERE to composite through the transform for free (rotates +
  # clips with me, §4.6 halo-handle model). Dormant returns nil (no island) ⇒ the highlight stays a
  # world child, byte-identical. Backs _isInsideNonIdentityIsland above (its one caller is boolean-context).
  _enclosingNonIdentityIsland: ->
    ancestor = @parent
    while ancestor?
      return ancestor if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
      ancestor = ancestor.parent
    nil

  # ---------------------------------------------------------------------------
  # PUBLIC GEOMETRY API UNDER TRANSFORMS — the two-vocabulary law.
  # Canonical spec: docs/affine-geometry-api-plan.md (§1 is the normative text).
  #
  # THE LAW: a widget's geometry API is split into two families distinguishable BY NAME:
  #  - LAYOUT-BOX family (width/height/extent/bounds/boundingBox/position/center/left/…): the
  #    widget's OWN-plane layout box — plane-local, untransformed, integer. Inside an island these
  #    are virtual-plane values; outside, screen values. Transforms NEVER affect them; layout /
  #    settle / arrange / content code operate on these (the load-bearing invariant, plan §4.1).
  #  - SCREEN family (every name contains "screen": screenBounds/localPointToScreen/screenPoint-
  #    ToMyPlane/…): post-transform screen-plane values, possibly FRACTIONAL. NEVER feed them to
  #    layout / moveTo.
  # No non-"screen" method ever returns transformed geometry; no "screen" method ever returns
  # plane-local geometry. (The island's clippedThroughBounds/fullClippedBounds two-faces overrides
  # are framework-internal damage/hit machinery, NOT a public screen-bounds proxy — that is exactly
  # why screenBounds() exists; plan §1.2 / §4.11.)
  # ---------------------------------------------------------------------------

  # SCREEN family. The screen-plane axis-aligned bounding box of my layout box under all ancestor
  # island transforms — an exact, possibly-FRACTIONAL Rectangle (never feed it to layout / moveTo).
  # Walk @parent innermost→outermost (same order as localPointToScreen), mapping the rect's 4
  # corners through each non-identity island's EXACT (unpadded) matrix. NO ancestor-clip
  # intersection (that is mapRectToScreen's damage-lane job) and NO padding. Identity fast path: no
  # non-identity ancestor island ⇒ return @boundingBox() (the same object — zero-alloc dormant,
  # matching boundingBox / localPointToScreen). For the ISLAND itself the walk starts at @parent, so
  # its OWN transform (which applies to its CONTENT, not its slot box) is correctly excluded.
  screenBounds: ->
    result = @boundingBox()
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        result = ancestor.transformSpec.mapRectExact result, ancestor.bounds
      ancestor = ancestor.parent
    result

  # My OWN sugar transform — getter symmetry with the 4C setters setRotationDegrees / setScaleFactor
  # (reads what they wrote). 0 / 1 for a bare widget AND for a widget that is CONTENT of an EXPLICIT
  # (non-sugar) island: the sugar getters mirror the sugar setters' scope. For the TOTAL visual
  # transform of my rendering (through explicit + nested islands) use accumulated*() below.
  rotationDegrees: ->
    @_enclosingSugarIsland()?.transformSpec.rotationDegrees ? 0

  scaleFactor: ->
    @_enclosingSugarIsland()?.transformSpec.scale ? 1

  # The TOTAL visual transform of my rendering: Σ rotationDegrees (normalized to [0,360)) and
  # ∏ scale over ALL ancestor non-identity islands (sugar AND explicit) — the linear part of the
  # accumulated similitude (plan 4D-2a: scalar rotations commute + multiply, so no matrix product /
  # decomposition; summing integer degrees is EXACT). The walk starts at @parent (STRICT ancestors),
  # and my own sugar island IS an ancestor, so my own transform is included. ONE greppable
  # accumulation shared with the pick-out (_pickOutRotatedFigureNoSettle) and drop-re-express
  # (_reExpressFigureForPlaneOfNoSettle) verbs. Off any island ⇒ 0 / 1.
  accumulatedRotationDegrees: ->
    total = 0
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        total = total + ancestor.transformSpec.rotationDegrees
      ancestor = ancestor.parent
    ((total % 360) + 360) % 360

  accumulatedScaleFactor: ->
    product = 1
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        product = product * ancestor.transformSpec.scale
      ancestor = ancestor.parent
    product

  # Public, macro-callable predicate: true iff at least one STRICT ancestor island has a non-identity
  # spec — i.e. "my layout-box geometry does not coincide with my screen appearance". For an island
  # itself: false (its slot box IS plane geometry — its CONTENT is what transforms). The blessed
  # public name for the private _isInsideNonIdentityIsland (macros cannot call `_`-prefixed members).
  isVisuallyTransformed: ->
    @_enclosingNonIdentityIsland()?

  # ---------------------------------------------------------------------------
  # Affine transforms (§6 Phase 4C): the Lively-flavoured property sugar. Rotate / scale ANY widget
  # by MATERIALIZING an enclosing TransformFrameWdgt island on demand, and REMOVING it when the
  # transform returns to identity — so the widget's structural identity is restored at identity (the
  # dormant guarantee + serialization cleanliness). These wrap the island's own setRotation/setScale.
  # The names are deliberately NOT the island's setRotation/setScale, so there is no layering-gate
  # name collision and calling them on a bare widget is unambiguous. Public tier owns the single
  # settle (the wrap/adjust/unwrap all run NoSettle inside it).
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  # Affine transforms (§6 Phase 4B-universal): the halo ROTATION PROTOCOL. The rotate handle drives
  # ANY widget through these three, so it needs no knowledge of whether its target is a plain widget
  # (rotates by MATERIALIZING a sugar island via setRotationDegrees) or an explicit TransformFrameWdgt
  # island (which overrides all three to drive its own spec directly). Base = the plain-widget case.
  # ---------------------------------------------------------------------------
  # The SCREEN pivot for a halo rotation: the FIXED POINT of my sugar island's rotation. That fixed
  # point is the island's ANCHOR (its transformSpec._anchorFor) — which for an un-pinned island is my
  # bounds centre, but after §7.5 Bug D a collapse/resize can PIN it OFF the centre, so we must ask the
  # island for its true anchor rather than assume the centre (that assumption was one of the two
  # trip-ups this API unit exists to close — geometry-api-plan §1.4). Delegate to the island's own
  # screenAnchor() (the authoritative anchor→screen map). Bare-widget (no island yet, e.g. the FIRST
  # halo grab) fallback: my centre mapped to screen — dormant that is my plain centre, and it matches
  # the slot-centre anchor the about-to-materialise sugar island will use.
  rotationHalo_screenAnchor: ->
    island = @_enclosingSugarIsland()
    return island.screenAnchor() if island?
    @localPointToScreen @center()

  # My current halo rotation in degrees: my own sugar transform (the public getter), or 0 if I am not
  # (yet) wrapped — so a re-grab continues from where a prior rotation left off. rotationHalo_* is the
  # documented halo-consumer family; this stays as its blessed alias of rotationDegrees().
  rotationHalo_currentDegrees: ->
    @rotationDegrees()

  # Apply a halo rotation: the 4C property sugar (materialises a sugar island on demand, removes it at
  # identity). Self-settling; called per drag from the (allowlisted) rotate-handle stream — a 'slot'
  # island settles to nothing, so per-call settling is a no-op there.
  rotationHalo_apply: (deg) ->
    @setRotationDegrees deg

  setRotationDegrees: (deg) ->
    @_settleLayoutsAfter => @_setRotationDegreesNoSettle deg

  _setRotationDegreesNoSettle: (deg) ->
    @_applyTransformSugarNoSettle deg, nil

  setScaleFactor: (s) ->
    @_settleLayoutsAfter => @_setScaleFactorNoSettle s

  _setScaleFactorNoSettle: (s) ->
    @_applyTransformSugarNoSettle nil, s

  # shared core: find-or-materialize the enclosing sugar island, apply the (partial) spec change,
  # then dematerialize if it returned to identity. degOrNil / sOrNil: nil means "leave unchanged".
  _applyTransformSugarNoSettle: (degOrNil, sOrNil) ->
    island = @_enclosingSugarIsland()
    if !island?
      # nothing exists yet: materialize only if the target is non-identity (else it is a no-op).
      deg = degOrNil ? 0
      s = sOrNil ? 1
      return if (deg % 360 == 0) and (s == 1)
      island = @_materializeSugarIslandNoSettle()
    island._setRotationNoSettle degOrNil if degOrNil?
    island._setScaleNoSettle sOrNil if sOrNil?
    @_dematerializeSugarIslandIfIdentityNoSettle island

  # the enclosing island IFF it was materialized by the sugar AND wraps EXACTLY me (so adjusting it
  # only affects me). An explicitly-authored island (or one wrapping a larger subtree) is NOT reused —
  # it stays put; the sugar wraps a fresh island around just me.
  _enclosingSugarIsland: ->
    p = @parent
    return nil if !(p instanceof TransformFrameWdgt) or !p._materializedBySugar
    kids = p.childrenNotHandlesNorCarets()
    return p if kids? and kids.length == 1 and kids[0] == @
    nil

  # wrap me in a fresh sugar island IN PLACE: the island's slot box becomes my current bounds and I
  # become its single free-floating child, keeping my absolute position (virtual ≡ screen at identity).
  # The island inherits MY former index AND layoutSpec in my parent — so wrapping is position-invariant
  # (no z-order raise on the desktop, no slot reshuffle in an arranged panel). Capture both BEFORE the
  # reparent (which shrinks the sibling list). Orphan-safe: a parentless widget just gets an orphan island.
  _materializeSugarIslandNoSettle: ->
    formerParent = @parent
    myIndex = formerParent?.children.indexOf @
    myLayoutSpec = @layoutSpec
    # A sugar island TRACKS its single content's size (rough edge R3): materialize the tracking capability
    # variant, so resizing the wrapped widget grows the slot instead of clipping. TrackingTransformFrameWdgt
    # IS-A TransformFrameWdgt (every instanceof / serialization / dematerialize path is unchanged).
    island = new TrackingTransformFrameWdgt()
    island._materializedBySugar = true
    island.bounds = new Rectangle @left(), @top(), @right(), @bottom()
    # HOME the (empty) island into MY former slot + spec FIRST, THEN reparent me into it. Order matters:
    # _addNoSettle fires the added widget's _reactToBeingAdded, and a widget whose appearance is DERIVED from
    # its nesting (a WindowWdgt's internal/external skin, via isInternal looking THROUGH this _materializedBySugar
    # island to the real parent) must derive against the island's TRUE parent -- so the island has to be homed
    # before I move in. The reverse order derived my skin while the island was still a detached root (parent
    # nil), flipping a tilted window to the wrong skin. The final tree is identical either way (island ends at
    # myIndex, me free-floating inside it); homing an empty tracking island is safe (its _reLayoutChildren
    # no-ops with no content, and __add skips the extent recalculation). Orphan-safe: no formerParent => the
    # island stays a detached root and I move into it, exactly as before.
    formerParent?._addNoSettle island, myIndex, myLayoutSpec   # drop the (empty) island into MY former slot + spec
    island._addNoSettle @                                      # then reparent me into the now-homed island (free-floating child)
    island

  # if the sugar island is back at identity, unwrap: reparent me back into the island's parent at the
  # island's index + layoutSpec (position-invariant, the exact inverse of the wrap), preserve my absolute
  # position (identity ⇒ screen-coincident), then drop the now-empty island. Restores the exact
  # pre-materialize structure — the round-trip leaves no island behind and no z-order/slot change.
  _dematerializeSugarIslandIfIdentityNoSettle: (island) ->
    return if !island._materializedBySugar or !island.transformSpec.isIdentity()
    islandParent = island.parent
    return if !islandParent?
    islandIndex = islandParent.children.indexOf island
    islandLayoutSpec = island.layoutSpec
    pos = @position()
    islandParent._addNoSettle @, islandIndex, islandLayoutSpec   # reparent me back into the island's slot + spec
    @_moveToNoSettle pos                                          # preserve my absolute position (desktop case)
    # R2 (§6 affine): a highlight (or any layout-inert ephemeral chrome, isEphemeral) parented INTO this
    # island while it was rotated must ride OUT before we drop it — else _destroyNoSettle just nulls
    # island.children (it does not orphan/clean them), leaving the world's highlight bookkeeping dangling
    # on a dead widget. Dematerialize only happens at identity, where virtual ≡ screen, so each inert
    # child's bounds are already screen-coincident: re-home it to the island's parent at unchanged
    # position (the reconciler re-derives the exact parent next tick regardless). Iterate a COPY since
    # _addNoSettle mutates island.children. (The content @ is already out, so these are only chrome.)
    for inertChild in island.children.slice() when inertChild.isLayoutInert?()
      inertChildPos = inertChild.position()
      islandParent._addNoSettle inertChild                       # free-floating (default layoutSpec)
      inertChild._moveToNoSettle inertChildPos
    island._destroyNoSettle()                                    # drop the now-empty island (I was inserted before it)

  # ---------------------------------------------------------------------------
  # Affine transforms (§6 Phase 4D-2a): PICK-OUT. When a widget inside a non-identity island is grabbed,
  # resolve the FIGURE that comes onto the hand. Two cases (the grab dispatch calls this on the loose unit
  # the normal grabsToParentWhenDragged rules already picked — a window title resolves to the window, a
  # loose content child to the child):
  #   • I am my innermost island's SOLE content ⇒ grabbing me ≡ grabbing that island (and any outer islands
  #     it is in turn the sole content of), so REUSE the existing island (climb to the outermost sole-content
  #     island) — no churn, Phase-1's whole-figure grab. macroTransformFrameScaledDragged relies on this.
  #   • I am a genuine SUB-part (my innermost island wraps a larger subtree) ⇒ extract me and wrap me in a
  #     FRESH island carrying the accumulated similitude (_pickOutRotatedFigureNoSettle).
  # Off any island ⇒ returns me unchanged (byte-identical dormant). NoSettle: the grab's own settle covers
  # the extraction's re-fit of my former container.
  _resolvePickOutFigureNoSettle: ->
    island = @_enclosingNonIdentityIsland()
    return @ if !island?
    kids = island.childrenNotHandlesNorCarets()
    if kids? and kids.length == 1 and kids[0] == @
      # sole content: reuse; climb to the outermost island of the sole-content chain
      figure = island
      loop
        outer = figure._enclosingNonIdentityIsland()
        break if !outer?
        outerKids = outer.childrenNotHandlesNorCarets()
        break if !(outerKids? and outerKids.length == 1 and outerKids[0] == figure)
        figure = outer
      # §7.5 Bug G (reparent-transparency, PICK-UP NORMALIZATION): a PINNED anchor (Bug-D
      # anchor-stability, set by a tracked resize) breaks every downstream apply-site that assumes the
      # pivot is the slot centre — the 2b-i relative re-spec pivots about the pinned anchor and the 4D-1
      # placement homes the SLOT centre, so a tilted+RESIZED figure dropped into a counter-tilted
      # container lands off by O((I−sR)(A−centre)) (probe: −50,+49 px at 45°/−45°; the un-resized
      # control is exact). Normalize at the pick-up seam: re-express the similitude as its equivalent
      # nil-anchor form (identical rendering, ≤1px rounding), so the ENTIRE hand-carry pipeline
      # (drag, re-spec, placement, re-home) runs its already-exact centre-pivot math.
      figure._normalizePinnedAnchorNoSettle()
      # §7.5 Bug F (reparent-transparency, PICK half): the reused figure keeps its user-observed look
      # when lifted to the hand (the identity plane). When the figure still has non-identity ANCESTOR
      # islands (e.g. a compensating wrapper living inside a tilted container), its own spec alone would
      # render differently on the hand than the accumulated look it had nested — so fold the ancestors
      # into its spec (degrees add, scales multiply — the 4D-2a scalar-composition finding) and re-home
      # so its visual centre stays put. Off nested planes (a figure sitting directly on the desktop — the
      # entire pre-Bug-F population) both accumulators are exactly 0/1 and this block is byte-identical
      # dormant. The transient mid-gesture re-spec is never painted (the synchronous-gesture argument):
      # both centre points below are NUMERIC values used only to compute the re-homed bounds that render
      # on the identity hand plane AFTER the grab reparents (which preserves numeric bounds), so they need
      # not share a coordinate frame here. NIL-anchor correct by that numeric argument; PINNED-anchor
      # correct because the move-level override (TransformFrameWdgt._applyMoveBy et al.) rides the anchor
      # on the re-home _applyMoveTo, restoring the fixed-point property (probe-verified 0.5px, scenarios
      # 4 + 5b — see docs §7.5 Bug F).
      degAnc = figure.accumulatedRotationDegrees()
      sAnc = figure.accumulatedScaleFactor()
      if !(degAnc == 0 and sAnc == 1)
        # visual centre BEFORE (pinned-anchor-safe READ: own-map via mapPoint honours a pinned anchor,
        # then up the ancestor planes)
        screenCentreBefore = figure.parent.localPointToScreen figure.transformSpec.mapPoint(figure.center(), figure.bounds)
        figure._setRotationNoSettle (((figure.transformSpec.rotationDegrees + degAnc) % 360) + 360) % 360
        figure._setScaleNoSettle figure.transformSpec.scale * sAnc
        if figure._materializedBySugar and figure.transformSpec.isIdentity()
          # the ancestors exactly cancel my spec (the drop→pick round-trip): the figure is now an IDENTITY
          # compensating sugar wrapper. Position it at the visual centre and RETURN it — determineGrabs
          # dissolves it self-settling before the grab, exactly as the drop side dissolves its re-expressed
          # sugar figure via the self-settling wrap AFTER target.add. The dissolve reparents the wrapper's
          # content into its ATTACHED parent (an off-settle layout mutation → a careless end-of-cycle push
          # if done bare), and this is a NoSettle method that must not self-settle (rule [G]) — so the
          # settle belongs at the non-NoSettle caller, NOT here. Dematerialize preserves the content's
          # position and the sugar wrapper hugs its content, so positioning the wrapper positions the
          # content. (The other pick-out paths reparent into a FRESH orphan island, which is audit-exempt.)
          figure._applyMoveTo screenCentreBefore.round().subtract figure.extent().floorDivideBy 2
          return figure
        # non-identity total: post-reparent the figure renders its own map at its numeric bounds — home
        # its visual centre back to where it was. The move-level anchor-ride (see the block comment)
        # keeps this exact for a pinned anchor too; nil anchor is exact by the numeric argument.
        centreAfter = figure.transformSpec.mapPoint(figure.center(), figure.bounds)
        figure._applyMoveTo figure.position().add (screenCentreBefore.subtract centreAfter).round()
      return figure
    # genuine sub-part: extract + wrap in a fresh island
    return @_pickOutRotatedFigureNoSettle()

  # Affine transforms (§6 Phase 4D-2a): extract me from my island chain into a FRESH sugar-style island that
  # carries the ACCUMULATED similitude of ALL my ancestor islands, positioned so I stay screen-coincident
  # (no jump). Returns the fresh island for the hand to grab. The accumulated map's LINEAR part is exactly
  # (scale = ∏ ancestor scales, rotation = Σ ancestor degrees) — scalar rotations commute + multiply, so no
  # matrix product / decomposition and no TransformSpec.compose is needed (and summing integer degrees is
  # EXACT, dodging the atan2 wobble 4B had to quantize). Two similitudes with the same linear part differ
  # only by a translation, so matching ONE point (my centre) makes the fresh figure coincide with the
  # original everywhere: the fresh island pivots on its slot centre (= my centre), which renders my centre at
  # my (virtual) centre, and localPointToScreen(centre) — which composes all N ancestors — is where it was,
  # so translating by their difference re-homes the whole figure. For n=1 this is pixel-identical; for n≥2 it
  # resamples once instead of per-level (crisper — a new state anyway).
  _pickOutRotatedFigureNoSettle: ->
    # the accumulated similitude of ALL my ancestor islands (∏ scales, Σ degrees normalized) — the
    # public getters ARE this walk, extracted (byte-equivalent). Read them BEFORE _addNoSettle re-parents
    # me (they walk MY current ancestors).
    accScale = @accumulatedScaleFactor()
    accDeg = @accumulatedRotationDegrees()
    screenCentreBefore = @localPointToScreen @center()     # my on-screen centre BEFORE extraction
    island = new TrackingTransformFrameWdgt()
    island._materializedBySugar = true                     # behaves as a sugar island (auto-unwrap at identity, scalar serialization)
    island.transformSpec = new TransformSpec accDeg, accScale
    island.bounds = new Rectangle @left(), @top(), @right(), @bottom()   # slot = my bounds ⇒ slot centre = my centre
    island._addNoSettle @                                  # extract me from my old container into the fresh island
    island._applyMoveTo island.position().add (screenCentreBefore.subtract @center())   # re-home so my centre lands where it was
    island

  # Affine transforms (§7.5 Bug B latent 2, Option B): the enclosing island IFF it wraps EXACTLY me —
  # sugar OR explicitly authored. The SOLE-CONTENT predicate of _enclosingSugarIsland minus the
  # `_materializedBySugar` requirement: for re-homing/classification, a sole-content transform island
  # is transform plumbing around ONE figure regardless of who authored it. Sugar-ONLY machinery
  # (materialize/dissolve/unwrap, halo anchor) keeps using _enclosingSugarIsland — an explicit island
  # must never auto-dissolve or be reused by the property sugar.
  _enclosingSoleContentIsland: ->
    p = @parent
    return nil if !(p instanceof TransformFrameWdgt)
    kids = p.childrenNotHandlesNorCarets()
    return p if kids? and kids.length == 1 and kids[0] == @
    nil

  # Affine transforms (§7.5 Bug B + latent 2, Option B): the outermost island of which I am (transitively)
  # the SOLE content — sugar or explicit — i.e. the whole "figure" that a RE-HOME (close-to-basement,
  # reopen, a future "send to desktop") must move AS A UNIT so its rotation/scale travels with it — or ME
  # when I am not island-wrapped. This is the re-home SIBLING of the pick-OUT verb
  # _resolvePickOutFigureNoSettle (4D-2a): pick-OUT may EXTRACT a sub-part onto the hand; re-home never
  # extracts — it moves the intact figure. ONE greppable home for every re-home site: route
  # close/reopen/eject through this, NEVER inline the climb. Pure (no mutation, no settle). Explicit
  # sole-content islands travel too (Option B): the island IS the authored transform, so leaving it behind
  # would strand an empty invisible frame AND lose the transform across close/reopen — the same principle
  # that locked Bug B's model (a) for sugar. A MULTI-child explicit island is not sole-content ⇒ not
  # climbed (content travels bare, siblings stay). Off any island ⇒ me.
  _enclosingIslandFigure: ->
    figure = @
    loop
      island = figure._enclosingSoleContentIsland()
      break if !island?
      figure = island
    figure

  # The container I really live in, seen THROUGH my sole-content island(s) — my @parent off any island
  # wrap, or the figure's parent when I am tilted/scaled (sugar) or explicitly islanded. The ONE
  # look-through idiom for "where does this widget really belong" (§7.5 Bug A/B + latent 2 Option B): a
  # widget's CLASSIFICATION must not be fooled by transform plumbing. WindowWdgt.isInternal
  # (internal/external skin) and BasementWdgt.holds (basement residency) both classify against THIS, so a
  # tilted or explicitly-islanded widget is judged by its real home, not the island.
  _parentThroughIslands: ->
    @_enclosingIslandFigure().parent

  # Affine transforms (§6 Phase 4D-2b): the PAYLOAD-side look-through for drop POLICY. When a widget is
  # rotated/scaled it rides the hand as a transient _materializedBySugar TransformFrameWdgt, which HIDES its
  # content's class from every drop-policy predicate -- so a tilted WINDOW arrives as a "transform frame" and
  # bypasses the dwell-to-arm gate (requiresDeliberateEmbedding), sticky re-embed, and the wantsDropOfChild
  # type checks. This returns my sole content THROUGH sugar wrapper(s) so those predicates see the real payload
  # class; off any sugar figure (a plain widget, or an EXPLICIT authored island -- a real container, not
  # sugar) it returns ME. The payload-side sibling of _parentThroughIslands (the container-side
  # look-through). Consult it ONLY where the payload's CLASS/policy is inspected -- NEVER at geometry/add sites,
  # which must keep the figure (it is what actually gets placed + parented).
  _dropPolicyProxy: ->
    figure = @
    loop
      break if !(figure instanceof TransformFrameWdgt) or !figure._materializedBySugar
      content = figure.childrenNotHandlesNorCarets()?[0]
      break if !content?
      figure = content
    figure

  # Affine transforms (§6 Phase 4D-2b): RE-EXPRESS a dropped SUGAR FIGURE relative to the plane it lands in.
  # When a _materializedBySugar figure (from a 4D-2a pick-out or a 4C rotate/scale) is float-dropped into a
  # container that lives inside a non-identity island, its spec is ABSOLUTE (Σ degrees / ∏ scales over its
  # former ancestor islands) but it is about to composite THROUGH the destination plane's transform as well --
  # so without re-expression a 30° figure dropped into a 30° window would render at 60° (transforms compose;
  # the 4D-1 block maps only POSITION). Re-express the figure's spec RELATIVE to the destination plane:
  #     rel_r = figure.deg − Σ(destination-plane island degrees),  rel_s = figure.scale ÷ ∏(… island scales)
  # so composited through the plane it renders at its ORIGINAL absolute look. When rel is identity (a
  # return-to-SAME-plane round-trip: x−x, x÷x are IEEE-exact and the absolute spec was BUILT as Σ/∏ over the
  # same chain in the same order at pick-out) the figure becomes an identity sugar island -- the drop's
  # post-add _unwrapIfIdentitySugarNoSettle then dissolves it (the 4C auto-unwrap), so a round-trip leaves no
  # island behind. Returns me (the re-spec'd figure) for the 4D-1 position-map + target.add to place. SCOPE
  # (locked): ONLY _materializedBySugar figures re-express; an EXPLICIT island nest-composes like any content
  # (the user authored that frame -- mutating its spec on drop would rewrite their structure). Off any sugar
  # figure, or into an identity plane, a no-op returning me unchanged: a non-island payload lacks
  # _materializedBySugar (⇒ byte-identical dormant), and a rotated figure dropped onto the plain desktop
  # re-specs to its own value (the setters early-return unchanged). Inverse of _pickOutRotatedFigureNoSettle's
  # accumulation; NoSettle -- the drop's target.add carries the settle.
  _reExpressFigureForPlaneOfNoSettle: (target) ->
    # §7.5 Bug F (reparent-transparency, DROP half): EVERY payload keeps the look it had on
    # the hand — not just sugar figures. A bare payload is a figure whose own transform is identity, so
    # its relative similitude vs the destination plane is (0 − plane, 1/plane): when the plane is
    # non-identity, wrap it in a fresh COMPENSATING sugar island at rel so it does not visibly rotate/
    # scale at the moment of drop ("what you see while dragging is what you get"). Explicit (non-sugar)
    # islands still nest-compose untouched (the 4D-2b scope rule).
    if !@_materializedBySugar
      return @ if @ instanceof TransformFrameWdgt   # explicit island payload: nest-compose, never re-spec
      degPlane = target.accumulatedRotationDegrees()
      sPlane = target.accumulatedScaleFactor()
      return @ if degPlane == 0 and sPlane == 1     # identity plane — the common path, byte-identical dormant
      relDeg = (((0 - degPlane) % 360) + 360) % 360
      island = new TrackingTransformFrameWdgt()
      island._materializedBySugar = true
      island.transformSpec = new TransformSpec relDeg, 1 / sPlane
      # slot = my bounds (I am on the hand, screen coords); the wrapper pivots on the slot centre so my
      # on-screen look is unchanged, and the 4D-1 block below places the wrapper by its visual centre.
      island.bounds = new Rectangle @left(), @top(), @right(), @bottom()
      island._addNoSettle @
      return island
    # The destination plane's linear part: the accumulated similitude over the non-identity islands the
    # dropped payload will composite through -- target's ancestors. target is never itself a non-identity
    # island (islands refuse drops, so dropTargetFor climbs past them), so target.accumulated*() (STRICT
    # ancestors) equals the target-inclusive walk this used to inline -- byte-equivalent (a normalized Σ
    # differs from the raw sum only by a multiple of 360, which relDeg's own mod cancels; the ∏ is the
    # same ordered product). Mirrors _pickOutRotatedFigureNoSettle's accumulation (this is its inverse).
    degPlane = target.accumulatedRotationDegrees()
    sPlane = target.accumulatedScaleFactor()
    relDeg = (((@transformSpec.rotationDegrees - degPlane) % 360) + 360) % 360
    relScale = @transformSpec.scale / sPlane
    @_setRotationNoSettle relDeg   # the island's own spec cores; each early-returns when unchanged (identity
    @_setScaleNoSettle relScale    # plane ⇒ no-op ⇒ dormant byte-identical). rel identity ⇒ I become identity.
    @

  # Affine transforms (§6 Phase 4D-2b): the UNWRAP half of the drop re-expression, invoked on a JUST-DROPPED
  # figure. Self-settling twin of _unwrapIfIdentitySugarNoSettle -- the drop calls it AFTER target.add's settle
  # has closed, so the dematerialize's NoSettle re-home needs its own settle (else a careless end-of-cycle
  # push). The canonical thin wrap; the core self-guards, so a non-identity / non-sugar receiver just returns
  # itself (the settle then flushes nothing).
  _unwrapIfIdentitySugar: ->
    @_settleLayoutsAfter => @_unwrapIfIdentitySugarNoSettle()

  # If _reExpressFigureForPlaneOfNoSettle re-spec'd me to identity (rel was identity) I am now a
  # _materializedBySugar island at identity nested in my drop target, so I should DISSOLVE -- my content
  # becomes the target's own child at my slot, no nested-island buildup (the 4D risk-2 round-trip guarantee).
  # This is EXACTLY the 4C auto-unwrap, so I delegate to the proven _dematerializeSugarIslandIfIdentityNoSettle
  # (which reparents my sole content into my parent at my slot + preserves its position + rides inert chrome
  # out + drops me) rather than re-homing by hand -- and I am placed by the SAME 4D-1 path a non-identity
  # re-expressed figure uses, so there is no bespoke positioning. Returns my content on unwrap, else me
  # unchanged (not a sugar island, or still non-identity ⇒ I stay a relative wrapper). Off any island ⇒ me.
  _unwrapIfIdentitySugarNoSettle: ->
    return @ if !(@_materializedBySugar and @transformSpec?.isIdentity())
    content = @childrenNotHandlesNorCarets()?[0]
    return @ if !content?
    content._dematerializeSugarIslandIfIdentityNoSettle @
    content

  # Widget accessing - simple changes: translate me + my children + repaint.
  # (Stage 5, 2026-07-01) The re-fit seam this used to fire is DELETED -- the settle loop now re-fits my tracking
  # container AFTER I settle (see _reFitMyTrackingContainerAfterSettle) -- so this immediate mutator is PURE geometry
  # now (what the FLOWRULE always wanted), a thin wrapper over the shared move core _applyMoveByBase. The "AndNotify"
  # suffix is historical -- but this twin is NOT collapsible into _applyMoveByBase (2026-07-01 twin-collapse verdict):
  # it is the polymorphic DISPATCH POINT for the ClippingAtRectangularBoundsMixin scroll-optimization and the
  # ActivePointerWdgt float-drag OVERRIDES (which repaint via @changed, not @fullChanged), whereas bare _applyMoveByBase
  # is the uniform base translate the top-down arrange calls for leaf children. Folding the overrides onto _applyMoveByBase
  # would route arrange moves through them on clipping panels and change their dirty regions -- so the two names are a
  # genuine dispatch distinction, not redundant twins. (Only the truly-redundant SILENT-commit twins collapsed in that
  # pass: _commitExtentAndNotify folded into the __commitExtent leaf, _commitBoundsAndNotify + _applyBounds into _commitBounds.)
  _applyMoveBy: (delta) ->
    @_applyMoveByBase delta

  # The bare move primitives _applyMoveByBase / _applyMoveToBase, used by the top-down arrange for LEAF children: translate me
  # + my children + repaint via the UNIFORM base translate. A leaf child is placed through these rather than
  # _applyMoveBy / _applyMoveTo precisely so its move takes the base path and NOT the
  # ClippingAtRectangularBoundsMixin / ActivePointerWdgt override those *AndNotify names dispatch to (see the
  # _applyMoveBy note above -- that override difference is why the two are not collapsible). _applyMoveByBase is
  # the shared move core (returns true iff it actually moved).
  _applyMoveByBase: (delta) ->
    return false if delta.isZero()
    @__breakMoveResizeCaches()
    @fullChanged()
    @bounds = @bounds.translateBy delta
    @children.forEach (child) ->
      child.__commitMoveBy delta
    return true

  _applyMoveToBase: (aPoint) ->
    aPoint.debugIfFloats()
    delta = aPoint.toLocalCoordinatesOf @
    if !delta.isZero()
      @_applyMoveByBase delta
    @bounds.debugIfFloats()

  __commitMoveBy: (delta) ->
    @__breakMoveResizeCaches()
    @bounds = @bounds.translateBy delta
    @children.forEach (child) ->
      child.__commitMoveBy delta
  
  __breakMoveResizeCaches: ->
    # EMPTY-HAND CARVE-OUT (load-bearing -- measured: hover hit-testing stays ~96%-cached
    # because of this): a BARE pointer move must NOT bump geometryVersion, or every mouse
    # move would invalidate every version-keyed bounds cache in the world. The hand
    # compensates locally: its fullBounds / fullClippedBounds / clippedThroughBounds /
    # clipThrough overrides all recompute fresh (ActivePointerWdgt), so the hand never
    # serves a stale version-keyed bounds. With children (mid float-drag) the bump proceeds
    # as normal.
    if @ == world.hand
      if @children.length == 0
        return
    WorldWdgt.geometryVersion++

  # moving to fractional position within the desktop is
  # different from the case below because the desktop can be
  # resized to any ratio
  _moveInDesktopToFractionalPosition: (boundsOfParent) ->
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
      @_applyMoveTo (new Point boundsOfParent.left() + (boundsOfParent.width() * @positionFractionalInHoldingPanel[0]), @top()).round()
    if @positionFractionalInHoldingPanel[1] > 0
      @_applyMoveTo (new Point @left(), boundsOfParent.top() + (boundsOfParent.height() * @positionFractionalInHoldingPanel[1])).round()

  _moveInStretchablePanelToFractionalPosition: (boundsOfParent) ->
    if !boundsOfParent?
      boundsOfParent = @parent.bounds

    @_applyMoveTo (
      new Point \
       boundsOfParent.left() + (boundsOfParent.width() * @positionFractionalInHoldingPanel[0]),
       boundsOfParent.top() + (boundsOfParent.height() * @positionFractionalInHoldingPanel[1])
    ).round()

  _setExtentToFractionalExtentInPaneUserHasSet: (boundsOfParent) ->
    if !boundsOfParent?
      boundsOfParent = @parent.bounds

    @_applyExtent new Point @extentFractionalInHoldingPanel[0] * boundsOfParent.width(), @extentFractionalInHoldingPanel[1] * boundsOfParent.height()

  
  # this one actually immediately changes the position and
  # bounds of widgets
  _applyMoveTo: (aPoint) ->
    aPoint.debugIfFloats()
    delta = aPoint.toLocalCoordinatesOf @
    if !delta.isZero()
      @_applyMoveBy delta
    @bounds.debugIfFloats()

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  moveTo: (aPoint, widgetStartingTheChange = nil) ->
    @_settleLayoutsAfter => @_moveToNoSettle aPoint, widgetStartingTheChange

  # Non-settling move core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredPosition + invalidate,
  # no flush -- rides an OUTER settle. Callers: public moveTo (self-settles) + _moveToDeferredSettle
  # (rides the ONE end-of-cycle flush). Feature code uses those PUBLIC entrypoints, never this core directly.
  _moveToNoSettle: (aPoint, widgetStartingTheChange = nil) ->
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

  # PRIVATE DEFERRED-SETTLE move entrypoint -- see the FAMILY comment on _setMaxDimDeferredSettle (rule [O]
  # caller-allowlist; world.deferredSettlingEnabled A/B switch; BOTH branches reach the _moveToNoSettle core).
  _moveToDeferredSettle: (aPoint, widgetStartingTheChange = nil) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_moveToNoSettle aPoint, widgetStartingTheChange
    else
      @_settleLayoutsAfter => @_moveToNoSettle aPoint, widgetStartingTheChange


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
    # no cache-break here: __commitMoveBy breaks the caches itself, so a zero-delta move
    # no longer bumps the cache version key (the Tier-D D4 discipline).
    delta = aPoint.toLocalCoordinatesOf @
    @__commitMoveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  _moveLeftSideTo: (x) ->
    @_applyMoveTo new Point x, @top()
  
  _moveRightSideTo: (x) ->
    @_applyMoveTo new Point x - @width(), @top()
  
  _moveTopSideTo: (y) ->
    @_applyMoveTo new Point @left(), y
  
  _moveBottomSideTo: (y) ->
    @_applyMoveTo new Point @left(), y - @height()
  
  _moveToSideOf: (aWidget) ->
    @_applyMoveTo aWidget.topRight().add new Point 10, -Math.round((@height() - aWidget.height())/2)
    @_moveWithin @parent
  
  _moveFullCenterTo: (aPoint) ->
    @_applyMoveTo aPoint.subtract @fullBounds().extent().floorDivideBy 2
  
  # make sure I am completely within another Widget's bounds
  _moveWithin: (aWdgt) ->
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
    @_applyBounds newBoundsForThisLayout

    # Clamp me inside aWdgt via the ONE clamp home, then bake the move (immediate twin).
    # Net translation is identical to the old per-axis _applyMoveBy quartet (per-axis,
    # right/bottom first + left/top last-wins); one _applyMoveTo replaces four incremental
    # bakes -- intermediate broken-rects differ, but repaint is idempotent over the settled world.
    @_applyMoveTo @_clampedPositionWithin aWdgt, @position(), @extent()
    return

  # ONE home for the keep-me-inside-aWdgt position clamp (consumed by the immediate
  # _moveWithin bake AND the deferred _moveWithinNoSettle core): clamp right/bottom FIRST,
  # left/top LAST (last-wins), so a too-big widget pins its top-left and window-bar
  # controls stay reachable. Pure -- no reads of @, no mutation.
  _clampedPositionWithin: (aWdgt, pos, ext) ->
    newX = pos.x
    newY = pos.y
    rightOff = (newX + ext.x) - aWdgt.right()
    if rightOff > 0 then newX = newX - rightOff
    if newX < aWdgt.left() then newX = aWdgt.left()
    bottomOff = (newY + ext.y) - aWdgt.bottom()
    if bottomOff > 0 then newY = newY - bottomOff
    if newY < aWdgt.top() then newY = aWdgt.top()
    new Point newX, newY

  # Deferred core of the public moveWithin (the _moveToNoSettle lattice pattern): clamp me
  # inside aWdgt using the not-yet-applied @desired* geometry when present, then DEFER the move
  # via the move CORE (cores call cores -- NOT the public moveTo, which would be the rule-[C]
  # public-calls-public shape), so it settles in the recalculateLayouts -> _reLayout phase
  # together with any other pending change.
  _moveWithinNoSettle: (aWdgt) ->
    ext = if @desiredExtent?   then @desiredExtent   else @extent()
    pos = if @desiredPosition? then @desiredPosition else @position()
    @_moveToNoSettle @_clampedPositionWithin aWdgt, pos, ext

  # Canonical thin wrap: the PUBLIC deferred "keep me inside aWdgt" -- one settle over the
  # _moveWithinNoSettle core. (_moveWithin is the IMMEDIATE sibling for bake-now callers.)
  moveWithin: (aWdgt) ->
    @_settleLayoutsAfter => @_moveWithinNoSettle aWdgt

  # more complex Widgets, e.g. layouts, might
  # do a more complex calculation to get the
  # minimum extent
  getMinimumExtent: ->
    @minimumExtent

  setMinimumExtent: (@minimumExtent) ->

  # Widget accessing - dimensional changes requiring a complete redraw
  # The polymorphic extent-apply -- the override DISPATCH POINT (SimpleVerticalStackPanelWdgt / ScrollPanelWdgt /
  # TextWdgt / SliderWdgt / ListWdgt / the stretchables specialize it). The base is a pure pass-through to
  # _applyExtentBase, exactly like _applyMoveBy -> _applyMoveByBase: ONE body per behaviour, two names for
  # dispatch (the bare twin is the override-BYPASSING base apply the top-down arrange uses). Nothing notifies:
  # the notify-by-mutation seam was deleted 2026-07-01 (the settle-time up-edge does any container re-fit), and
  # the historical *AndNotify names were renamed away 2026-07-02 (Tier B -- this method WAS _applyExtentAndNotify).
  _applyExtent: (aPoint) ->
    @_applyExtentBase aPoint

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setExtent: (aPoint, widgetStartingTheChange = nil) ->
    @_settleLayoutsAfter => @_setExtentNoSettle aPoint, widgetStartingTheChange

  # Non-settling extent core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredExtent + invalidate,
  # but do NOT flush -- so the mutation rides an OUTER settle. Two callers: the public setExtent (self-settles
  # via _settleLayoutsAfter) and the _setExtentDeferredSettle (rides the ONE end-of-cycle flush). Feature
  # code uses one of those PUBLIC entrypoints, never this core directly.
  _setExtentNoSettle: (aPoint, widgetStartingTheChange = nil) ->
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

  # PRIVATE DEFERRED-SETTLE extent entrypoint -- see the FAMILY comment on _setMaxDimDeferredSettle (rule [O]
  # caller-allowlist; world.deferredSettlingEnabled A/B switch; BOTH branches reach the _setExtentNoSettle core).
  _setExtentDeferredSettle: (aPoint, widgetStartingTheChange = nil) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setExtentNoSettle aPoint, widgetStartingTheChange
    else
      @_settleLayoutsAfter => @_setExtentNoSettle aPoint, widgetStartingTheChange

  
  # The silent extent-commit LEAF: round + min-extent clamp + commit @bounds, NO repaint / NO self-relayout. Returns
  # true iff @bounds actually changed. This is the bottom of the extent-sizing family -- external agents sizing a
  # widget (construction-time defaultSize / initial extent) call it directly, exactly like its __commitWidth /
  # __commitHeight siblings. (Collapsed 2026-07-01: the single-underscore _commitExtentAndNotify was a pure
  # pass-through to this leaf once the re-fit seam it used to fire was deleted -- it is gone, and its ~20 callers
  # reach the leaf directly. The §4.2 arrange still applies geometry through the non-notifying _apply* path; this
  # leaf is what those apply methods, and _commitBounds, commit through.)
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

  # Base extent-apply WITHOUT the polymorphic override: commit @bounds + @changed repaint + @_reLayoutSelf. THE
  # single body of the extent-apply pair -- the polymorphic _applyExtent base is a pure pass-through to
  # this. A container arranging a child top-down uses this to apply the child's measured extent while BYPASSING
  # the child's own _applyExtent override (e.g. SimpleVerticalStackPanelWdgt applies its arranged height
  # via _applyExtentBase so it does NOT re-enter its own _reLayoutChildren -- the frame commit that follows handles
  # that). The re-fit seam this pair used to differ on is gone (2026-07-01); the override-bypass keeps the two
  # NAMES distinct.
  _applyExtentBase: (aPoint) ->
    unless aPoint.equals @extent()
      # no cache-break here: __commitExtent breaks the caches itself, under its own did-anything-change
      # guard -- so a round/min-clamp no-op commit no longer bumps the clipped-bounds cache version key
      # (misses cost recompute, never values -- the Tier-D D4 discipline).
      @__commitExtent aPoint
      @changed()
      @_reLayoutSelf()


  # (proper-layouts, PROPERTY sub-seam DELETED 2026-07-01) The old _announceLayoutPropertyChangeToContainer seam
  # lived here: a freefloating content's layout-PROPERTY change (VerticalStackLayoutSpec alignment/elasticity/
  # base-width, SimplePlainTextWdgt soft-wrap, StringWdgt contained-text edit, WindowWdgt collapse) explicitly
  # re-fit its size-tracking container(s), because a freefloating child's _invalidateLayout does not climb. That
  # dependency now flows through the UNIFORM dirty-tree instead: _invalidateLayout climbs THROUGH a freefloating
  # boundary OFF-PASS when the parent is a size-tracking container (the "D1" branch below). The 9 call sites now
  # invalidate the container directly -- BARE (@parent._invalidateLayout(), no freefloating triggeringChild, so a
  # non-tracking intermediate parent doesn't drop it) for the freefloating-content callers, or @element._invalidateLayout()
  # for stack-child callers. The GEOMETRY seam (the immediate-mutator half) is now ALSO DELETED (Stage 5,
  # 2026-07-01): the settle loop re-fits a size-tracking container AFTER its content settles
  # (_reFitMyTrackingContainerAfterSettle), so the mutators are pure and nothing notifies by mutation anymore.

  # (proper-layouts §4.3 / Stage 5, 2026-07-01) Re-fit MY size-tracking container now that I have SETTLED.
  # Called by the settle loop (WorldWdgt._recalculateLayoutsBody) right after my chain-top _reLayout completes --
  # NOT by the geometry mutators. This is the ORDERED-settle successor to the DELETED notify-by-mutation geometry
  # seam (the old _announceGeometryChangeToContainer, which fired from the extent-commit and _applyMoveBy
  # mutators per mutation). A freefloating child's _invalidateLayout does not climb to its
  # size-tracking container, so the container must be re-fit explicitly when my geometry changes. The old seam
  # did that at MUTATION time -- while I was mid-settle -- so the container read my HALF-applied geometry and had
  # to re-fit again and again (an empirical fixpoint the old iteration cap backstopped). Firing at
  # SETTLE-completion instead, the container reads my FINAL geometry and re-fits correctly: for a simple chain a
  # bounded O(depth) up-walk (leaf content -> container -> its container -> ...), each widget re-fit once after its
  # content settles. (Constrained NESTED containers -- a width-capping stack of window cells inside a resized outer
  # window -- still re-negotiate size over a SMALL bounded number of re-visits; measured suite-wide peak 10, see
  # WorldWdgt._recalculateLayoutsBody.) The immediate mutators are now PURE (no layout side effect) -- what the
  # FLOWRULE always wanted. Reverse-probe: OLD-seam OFF + this up-edge = 165/165 byte-exact at dpr1/dpr2/webkit,
  # so §8's "irreducible in-pass seam" verdict was over-general. Both containers are covered: a NON-text-wrapping
  # scroll panel a level up past my non-tracking @contents PanelWdgt (@parent.parent), and my direct parent
  # (stack/window). _reFitContainer gates on _reLayoutChildren?, so a non-tracking parent is a no-op. OVERLAY
  # CHROME (carets, resize handles -- isLayoutInert) is excluded from every container's content-bounds
  # (TreeNode.childrenNotHandlesNorCarets), so re-fitting for it would be pure waste -- skip it. (Capability
  # `?()`, not a Widget base default -- type-test-elimination convention.) docs/proper-layouts-geometry-seam-removal-plan.md.
  _reFitMyTrackingContainerAfterSettle: ->
    return if @isLayoutInert?()
    return unless @parent?
    @_reFitContainer @parent.parent if @_amIDirectlyInsideNonTextWrappingScrollPanelWdgt()
    @_reFitContainer @parent

  # The ONE phase-dispatch primitive for the whole "re-fit a container at the next settle point" family:
  # the drag/drop gesture handlers (PanelWdgt / ScrollPanelWdgt / SimpleVerticalStackPanelWdgt
  # _reactToChildDropped / _reactToChildGrabbed / _reactToChildRemoved), the ORDERED settle-time re-fit
  # (_reFitMyTrackingContainerAfterSettle above, called by the settle loop after each chain-top settles), the
  # attach re-fit, and the newParentChoice* menu actions all route through here. Two states:
  #  - INSIDE a layout pass (world._recalculatingLayouts): ENQUEUE the container into the recalculateLayouts
  #    until-loop via the shared bare-push atom (__markForRelayout). Enqueuing is legal mid-pass -- unlike
  #    _invalidateLayout the atom neither throws (the freeze guard, see _invalidateLayout below) nor climbs to
  #    ancestors; it enqueues only the directly-affected container.
  #  - OUTSIDE a pass: _invalidateLayout() so the next doOneCycle re-fits the container.
  # Gated on _reLayoutChildren? so only a tracking container (Window / Stack / ScrollPanel -- the only
  # classes that define it) reacts; any other widget is a no-op. Low-level (leading underscore) so lint
  # rule [F] exempts it, and the callers read as pure intent (@_reFitContainer @parent / @_reFitContainer()).
  # DETERMINISM: the gesture + menu callers fire OUTSIDE passes, so their in-pass arm is dead (kept uniform
  # for safety); the settle-time re-fit's in-pass enqueue IS live and is the determinism-exempt path
  # (deferred-layout-OVERVIEW.md §11).
  #
  # (proper-layouts Phase D, 2026-06-28) The cross-method `return if container._adjustingContentsBounds`
  # suppression was DELETED here. Post-Phase-C every container arrange is a fixed point, so re-enqueuing a
  # container that is mid its OWN _positionAndResizeChildren now CONVERGES (one extra convergence pass instead
  # of being skipped) rather than looping forever -- which is why the skip is no longer needed for correctness.
  # (proper-layouts Phase E, 2026-06-28) The @_adjustingContentsBounds field itself is now GONE too: its last
  # use was the per-arrange re-entrancy guard, retired by having each container arrange apply its own geometry
  # through the override-bypassing _applyExtentBase (the interim _resizeOwn*SkippingChildRelayout helpers were
  # inlined away in Tier D, 2026-07-02).
  # (Stage 5, 2026-07-01) The notify-by-mutation geometry seam the immediate mutators used to fire is fully DELETED:
  # its in-pass half is now the ordered settle-time re-fit above (_reFitMyTrackingContainerAfterSettle -- see that
  # method's comment for the mechanism + the reverse-probe record), its off-pass half the uniform dirty-tree (bare
  # _invalidateLayout at the semantic points). docs/proper-layouts-geometry-seam-removal-plan.md.
  _reFitContainer: (container = @) ->
    return unless container?._reLayoutChildren?
    if world?._recalculatingLayouts
      container.__markForRelayout()   # in-pass: enqueue just this directly-affected container, no climb (shared atom)
    else
      container._invalidateLayout()


  _applyWidth: (width) ->
    @_applyExtent new Point(width or 0, @height())

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setWidth: (width) ->
    @_settleLayoutsAfter => @_setWidthNoSettle width

  # Non-settling width core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredExtent + invalidate,
  # no flush. Callers: public setWidth (self-settles) + _setWidthDeferredSettle (rides the end-of-cycle flush).
  _setWidthNoSettle: (width) ->
    if not @isFreeFloating()
      return
    else
      newWidth = Math.max width, 0
      newExtent = new Point newWidth, @height()
      unless @extent().equals newExtent
        @desiredExtent = newExtent
        @_invalidateLayout()

  # PRIVATE DEFERRED-SETTLE width entrypoint -- see the FAMILY comment on _setMaxDimDeferredSettle (rule [O]
  # caller-allowlist; world.deferredSettlingEnabled A/B switch; BOTH branches reach the _setWidthNoSettle core).
  _setWidthDeferredSettle: (width) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setWidthNoSettle width
    else
      @_settleLayoutsAfter => @_setWidthNoSettle width
  
  __commitWidth: (width) ->
    w = Math.max Math.round(width or 0), 0
    newBounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + w, @bounds.corner.y
    return if @bounds.equals newBounds
    @bounds = newBounds
    # cache-break under the did-anything-change guard, like __commitExtent (the D4/E1 discipline)
    @__breakMoveResizeCaches()
  
  _applyHeight: (height) ->
    @_applyExtent new Point(@width(), height or 0)

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setHeight: (height) ->
    @_settleLayoutsAfter => @_setHeightNoSettle height

  # Non-settling height core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredExtent + invalidate,
  # no flush. Callers: public setHeight (self-settles) + _setHeightDeferredSettle (rides the end-of-cycle flush).
  _setHeightNoSettle: (height) ->
    if not @isFreeFloating()
      return
    else
      newHeight = Math.max 0, height
      newExtent = new Point @width(), newHeight
      unless @extent().equals newExtent
        @desiredExtent = newExtent
        @_invalidateLayout()

  # PRIVATE DEFERRED-SETTLE height entrypoint -- see the FAMILY comment on _setMaxDimDeferredSettle (rule [O]
  # caller-allowlist; world.deferredSettlingEnabled A/B switch; BOTH branches reach the _setHeightNoSettle core).
  _setHeightDeferredSettle: (height) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setHeightNoSettle height
    else
      @_settleLayoutsAfter => @_setHeightNoSettle height
  
  __commitHeight: (height) ->
    h = Math.max Math.round(height or 0), 0
    newBounds = new Rectangle @bounds.origin, new Point @bounds.corner.x, @bounds.origin.y + h
    return if @bounds.equals newBounds
    @bounds = newBounds
    # cache-break under the did-anything-change guard, like __commitExtent (the D4/E1 discipline)
    @__breakMoveResizeCaches()
  
  setColor: (aColorOrAWidgetGivingAColor, widgetGivingColor) ->
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
  
  setBackgroundColor: (aColorOrAWidgetGivingAColor, widgetGivingColor) ->
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

  # The principal value this widget offers to a spreadsheet reference (dataflow spec §9.3): the
  # unified reader over today's duck-typed export cluster — a colour picker's colour, a field's
  # value, else its text. Widgets that export none of these answer nil here; the reference read then
  # falls back to the widget itself (that fallback lives at the read site — see the spreadsheet's
  # widget-valued-cell path, plan Phase 4). Only ColorPickerWdgt defines getColor and only
  # StringFieldWdgt defines getValue today; SliderWdgt gains getValue when it joins the protocol
  # (Phase 4), keeping this one uniform chain.
  exportedValue: ->
    @getColor?() ? @getValue?() ? @text

  # The dataflow node-protocol value reader (spec §3; DataflowEngine header): a widget node's current value IS
  # its exported value, so when a ported wire delivers, the engine PULLS the producer widget's exportedValue,
  # and the equal-value cutoff compares it after each edge apply.
  # Plain widgets (slider, text) inherit this; computing patch nodes override it to return their @output.
  dataflowValue: -> @exportedValue()

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

  # EPHEMERAL capability (owner's term). An ephemeral is a transient overlay owned wholly by the
  # per-cycle reconciler (WorldWdgt.addHighlightingWidgets / addPinoutingWidgets): it is
  # hit-test-excluded (never steals mouseEnter / clicks / drops — ActivePointerWdgt.topWdgtUnderPointer),
  # casts no shadow (skipsAddShadowManagement below), and is skipped by world-snapshot serialization
  # (Serializer.serializeWorld). Capability, not a type test (type-test-elimination convention): reads
  # the _ephemeralOverlay flag, so dedicated overlay classes AND ad-hoc reconciler-marked instances qualify.
  isEphemeral: -> @_ephemeralOverlay is true

  # A widget added to the world normally gains a drop-shadow (Widget._addNoSettle). Ephemerals opt
  # out — "not anything material the user clicks/drags". The caret ALSO opts out (it is not an
  # ephemeral — it is excluded from hit-testing separately — but is likewise immaterial), so it
  # overrides this directly. (Folded here from HighlighterWdgt's old dedicated override.)
  skipsAddShadowManagement: -> @isEphemeral()

  turnOnHighlight: ->
    if !@highlighted
      @highlighted = true
      # declare into the highlight style channel (target -> style descriptor) with the legacy
      # translucent-blue fill — the only style today; the drag arc (Phase 2+) adds outline styles.
      world.widgetsToBeHighlighted.set @, HighlighterWdgt.fillStyle(Color.BLUE, 50)
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
      # Affine transforms: record the SCREEN footprint (mapped through my ancestor islands WHILE I am still
      # attached and being painted), NOT the raw virtual rect. fleshOut(Full)Broken erases the "source"
      # (where-I-was) rect from these; if it re-mapped a stored VIRTUAL rect at flush time instead, a widget
      # DETACHED between paint and flush — a close/destroy (_destroyNoSettle / _closeNoSettle issue
      # fullChanged() then sever @parent, re-homing me to the basement) — would map through a nil/basement
      # chain (an identity) and erase the WRONG (un-transformed) rect, leaving the rotated on-screen footprint
      # stale (owner bug: closing a tilted converter's inner window). mapRectToScreen returns the SAME rect
      # off any island ⇒ byte-identical dormant. (Field names kept; they now hold the screen-plane footprint.)
      fullVirtual = @fullClippedBounds()
      @clippedBoundsWhenLastPainted = @mapRectToScreen @clippedThroughBounds()
      @fullClippedBoundsWhenLastPainted = @mapRectToScreen fullVirtual
      # §4.4 buffer cache — the "source" (old-position) lane. When painting INTO an island buffer,
      # stash the PRE-mapping virtual full-bounds and the island. If this widget later MOVES within
      # (or is removed from) the stationary island, the flesh-out source lane deposits this OLD
      # footprint as buffer-dirty so the partial rebuild erases the vacated region — the buffer-plane
      # twin of the screen-footprint erase above (the NEW footprint rides the mapRectToScreen deposit).
      # nil on every ordinary (non-island) paint ⇒ dormant-free; consumed+cleared at flesh-out.
      if world.paintingIntoIslandBuffer?
        @_islandBufferSourceIsland = world.paintingIntoIslandBuffer
        @_islandBufferSourceVirtualRect = fullVirtual
      else if @_islandBufferSourceIsland?
        @_islandBufferSourceIsland = nil

  # Occlusion culling (docs/occlusion-culling-plan.md P1): the axis-aligned rectangle this widget
  # provably paints FULLY OPAQUE, in LOGICAL px world coordinates, or nil. It is the geometry both
  # avenues of the plan share (Avenue A scans it per broken rect; Avenue B would cache it).
  # CONSERVATIVE BY DESIGN: any uncertainty MUST yield nil -- a wrong (too-big) rect silently drops
  # pixels of whatever is painted beneath the coverer, caught only by the pixel-exact SystemTests.
  # Every gate is evaluated at RUNTIME (never baked per class): appearances are swapped live
  # (e.g. WindowWdgt._deriveAndSetBodyAppearance flips Rectangular<->Boxy on re-parenting).
  opaqueCoveredRect: ->
    # (1) The paint must route through the plain appearance delegation. Widget::paintIntoAreaOrBlit-
    # FromBackBuffer just delegates to @appearance, but nine widget classes override it to draw
    # arbitrary pixels (HandleWdgt, LayoutChromeWdgt, LabelButtonWdgt, PenWdgt, CellWdgt,
    # SpreadsheetWdgt, AnalogClockWdgt, Example3DPlotWdgt, GraphsPlotsChartsWdgt) and BackBufferMixin
    # blits an offscreen buffer of unknown per-pixel opacity. This one prototype-identity check
    # excludes them ALL (it subsumes the back-buffer exclusion).
    return nil if @paintIntoAreaOrBlitFromBackBuffer isnt Widget::paintIntoAreaOrBlitFromBackBuffer
    # (2) ephemeral overlays (highlights, drag affordances) are translucent screen-toppers, never coverers
    return nil if @isEphemeral()
    # (3) the fill runs at globalAlpha = @alpha (RectangularAppearance), and (4) @color must be a
    # solid opaque colour (else fillStyle emits rgba(...) -- Color.toString gates on _a == 1)
    return nil if @alpha != 1
    return nil if !@color? or @color._a != 1
    # Dispatch on the EXACT appearance class (CoffeeScript switch compares with ===): a subclass
    # appearance may add arbitrary drawing (drawAdditionalPartsOnBaseShape) and must NOT inherit a
    # coverage claim. DesktopAppearance falls to the else -> nil (the world occludes nothing).
    switch @appearance?.constructor
      when RectangularAppearance
        if @backgroundColor? and @backgroundColor._a == 1
          # an opaque backgroundColor fills the FULL clipped bounds, padding ring included
          @boundingBox()
        else
          # the main @color fill clips to the tight box (bounds inset by the four paddings)
          @boundingBoxTight()
      when BoxyAppearance
        # inscribed box: the straight edges between corners fill crisply to the bounds, only the
        # corner arcs anti-alias -> inset every side by cornerRadius + 1 (conservative)
        @boundingBox().insetBy Math.max(@appearance.getCornerRadius(), 0) + 1
      else
        nil

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
      # Record last-painted bounds when drawing to the world canvas OR into a
      # TransformFrameWdgt island buffer (docs/affine-transforms-plan.md §4.5): a
      # widget inside a non-identity island paints into the island's buffer (not the
      # world canvas), so without this its virtual last-painted snapshot would never
      # update and the flesh-out "source" (cleanup-of-old-position) rect would be
      # missing. world.paintingIntoIslandBuffer is nil on every ordinary paint, so
      # this is byte-identical when the feature is dormant.
      if aContext == world.worldCanvasContext or world.paintingIntoIslandBuffer?
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
  __hide: ->
    if !@isVisible
      return
    @isVisible = false
    WorldWdgt.noteVisibilityOrCollapseChange()

  hide: ->
    if !@isVisible
      return

    @__hide()

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
    WorldWdgt.noteVisibilityOrCollapseChange()

    firstParentOwningMyShadow = @firstParentOwningMyShadow()
    if firstParentOwningMyShadow?
      firstParentOwningMyShadow.fullChanged()
    else
      @fullChanged()
  
  toggleVisibility: ->
    @isVisible = not @isVisible
    WorldWdgt.noteVisibilityOrCollapseChange()
    @fullChanged()

  # SELF-SETTLE (single-mutation tier). _beforeChildCollapsed now tears down the bar buttons through the
  # NON-settling core (_destroyNoSettle), and _reactToChildCollapsed re-fits via immediate mutators + _reFitContainer, so
  # _collapseNoSettle reaches no public setter. Anchored on (@parent ? @) (the container that re-lays-out).
  # THIN wrapper: the already-collapsed guard lives in the core (check-layering [H]), not before the settle.
  collapse: ->
    @_settleLayoutsAfter => @_collapseNoSettle()

  _collapseNoSettle: ->
    # IDEMPOTENT -- the SOLE collapse guard (the public collapse() is a thin settle wrapper). A direct caller --
    # a layout pass that decides collapse by width (WindowWdgt._positionAndResizeChildren,
    # HorizontalMenuPanelWdgt._reLayoutSelf) -- may collapse a NOT-yet-collapsed child MID-PASS (e.g. the FIRST
    # layout of an under-construction window, now that orphan construction settles -- see
    # docs/orphan-settledness-plan.md), so the re-layout the collapse schedules goes through the PHASE-VALVE
    # (in-pass -> the no-climb __markForRelayout; off-pass -> _invalidateLayout), exactly like the re-fit seam
    # _reFitContainer -- never a bare _invalidateLayout, which THROWS mid-pass. The no-op-when-already-collapsed
    # guard still short-circuits the common repeat call.
    return if @collapsed
    @parent?._beforeChildCollapsed? @
    @collapsed = true
    WorldWdgt.noteVisibilityOrCollapseChange()
    if world?._recalculatingLayouts then @__markForRelayout() else @_invalidateLayout()
    @fullChanged()
    @parent?._reactToChildCollapsed? @

  # SELF-SETTLE (single-mutation tier). _beforeChildUnCollapsed re-creates the bar buttons through the
  # NON-settling core (createAndAdd* -> @_addNoSettle; the button constructors add their innards on ORPHANS,
  # exempt from the flush-throw), and _reactToChildUnCollapsed re-fits via immediate mutators, so _unCollapseNoSettle reaches
  # no public setter. Anchored on @ (the canonical wrap; the global flush re-lays-out the container).
  # THIN wrapper: the guard lives in the core (check-layering [H]), not before the settle.
  unCollapse: ->
    @_settleLayoutsAfter => @_unCollapseNoSettle()

  _unCollapseNoSettle: ->
    # IDEMPOTENT -- the SOLE unCollapse guard (the public unCollapse() is a thin settle wrapper). See
    # _collapseNoSettle for why a direct layout-pass caller needs the no-op (avoid re-running the hooks
    # mid-pass) AND why the re-layout goes through the PHASE-VALVE (in-pass -> the no-climb
    # __markForRelayout; off-pass -> _invalidateLayout): a bare _invalidateLayout THROWS mid-pass, which a
    # width-driven uncollapse during the FIRST layout of an under-construction window now hits (orphan
    # construction settles -- see docs/orphan-settledness-plan.md), exactly symmetric to _collapseNoSettle.
    # Guard on @collapsed -- this widget's OWN collapse flag. The redundant `return if !@isInCollapsedSubtree()`
    # was REMOVED: isInCollapsedSubtree() is the RECURSIVE self-or-ancestor query, and once @collapsed is true
    # it necessarily returns true, so that second guard was DEAD code.
    return if !@collapsed
    @parent?._beforeChildUnCollapsed? @
    @collapsed = false
    WorldWdgt.noteVisibilityOrCollapseChange()
    if world?._recalculatingLayouts then @__markForRelayout() else @_invalidateLayout()
    @fullChanged()
    @parent?._reactToChildUnCollapsed? @

  
  SLOWisInCollapsedSubtree: ->
    if @collapsed
      return true
    if @parent?
      return @parent.SLOWisInCollapsedSubtree()
    return false

  # Cached on visibilityVersion, exactly like visibleBasedOnIsVisibleProperty: the only
  # two @collapsed writes (collapse/unCollapse cores) bump it, and a reparent bumps it
  # via noteStructureChange -- so the stamp invalidates in exactly the situations the
  # walk's inputs can change, and moves never touch it (no empty-hand interaction).
  # Measured before caching (2026-07-03): 310k node-visits / ~149 ms in one menu-hover
  # test -- an uncached O(depth) walk on every hit-test / broken-rect guard.
  isInCollapsedSubtree: ->
    if @checkIsInCollapsedSubtreeCache == WorldWdgt.visibilityVersion
      result = @cachedIsInCollapsedSubtree
    else
      if @collapsed
        result = true
      else if @parent?
        result = @parent.isInCollapsedSubtree()
      else
        result = false
      @checkIsInCollapsedSubtreeCache = WorldWdgt.visibilityVersion
      @cachedIsInCollapsedSubtree = result

    if world.doubleCheckCachedMethodsResults
      if result != @SLOWisInCollapsedSubtree()
        debugger
        alert "isInCollapsedSubtree is broken"

    return result
  
  removeFromTree: ->
    # FREEFLOATING-skip centralized in _invalidateLayout(triggeringChild): pass @ so the parent skips
    # when I'm freefloating -- removing a freefloating child doesn't change the parent's layout.
    @parent?._invalidateLayout(@)
    @__breakMoveResizeCaches()
    WorldWdgt.noteStructureChange()
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
    widgetToAdd.moveTo @position()
    widgetToAdd.setExtent new Point 150, 20
    widgetToAdd.fullChanged()
    @removeFromTree()
  # this part is excluded from the fizzygum homepage build <<«

  # PUBLIC self-settling entry (menus / triggers / double-clicks). The NON-settling core
  # _createReferenceNoSettle is what a drop recipient calls (it runs inside the drop's settle, so
  # a public add/setExtent would re-enter the flush guard and throw under the single-mutation tier).
  createReference: (referenceName, placeToDropItIn = world) ->
    @_settleLayoutsAfter => @_createReferenceNoSettle referenceName, placeToDropItIn

  # The COMPLETE createReference minus the settle. add -> _addNoSettle and setExtent -> _applyExtent
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
    widgetToAdd._applyExtent new Point 75, 75
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

  # this part is excluded from the fizzygum homepage build <<«
  
  # shadow is added to a widget by
  # the ActivePointerWdgt while floatDragging
  addShadow: (offset = new Point(4, 4), alpha = 0.2) ->
    @__addShadow offset, alpha
    @fullChanged()

  __addShadow: (offset, alpha) ->
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
      if !@paintBoundsMaybeChanged
        # if we already issued a fullChanged on this widget
        # then there is no point issuing a change too.
        if !@fullPaintBoundsMaybeChanged
          world.widgetsWithMaybeChangedPaintBounds.push @
          @paintBoundsMaybeChanged = true

  # to actually make sure if a widget has changed
  # position, you need to check it and all its
  # parents.
  # See comment on the fullPaintBoundsMaybeChanged
  # property above for more info.
  hasMaybeChangedPaintBounds: ->
    if @fullPaintBoundsMaybeChanged or @paintBoundsMaybeChanged
      return true
    else
      if @parent?
        return @parent.hasMaybeChangedPaintBounds()
      else
        return false
  
  # See comment on the fullPaintBoundsMaybeChanged
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
      if !@fullPaintBoundsMaybeChanged
        world.widgetsWithMaybeChangedFullPaintBounds.push @
        @fullPaintBoundsMaybeChanged = true
  
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

  _reactToBeingAdded: (whereTo, beingDropped) ->
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
  # private teardown chain). Full semantics: shadow management + invalidate + __add +
  # _reactToBeingAdded / _reactToChildAdded / _reactToChildRemoved callbacks + fractional-position, but never
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
    @__add aWdgt, true, position
    aWdgt._reactToBeingAdded @, beingDropped
    if previousParent?._reactToChildRemoved?
      previousParent._reactToChildRemoved aWdgt

    if @_reactToChildAdded?
      @_reactToChildAdded aWdgt

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

  __add: (aWdgt, avoidExtentCalculation, position = nil) ->
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
    aFullCopy._applyMoveTo @position().add new Point 10, 10
    aFullCopy.rememberFractionalSituationInHoldingPanel()

  duplicateMenuActionAndPickItUp: ->
    aFullCopy = @fullCopy()
    aFullCopy?.pickUp()

  # in case we copy a widget, if the original was in some
  # data structures related to broken widgets, then
  # we have to add the copy too.
  alignCopiedWidgetToBrokenInfoDataStructures: (copiedWidget) ->
    if world.widgetsWithMaybeChangedPaintBounds.includes(@) and
     !world.widgetsWithMaybeChangedPaintBounds.includes(copiedWidget)
      world.widgetsWithMaybeChangedPaintBounds.push copiedWidget

    if world.widgetsWithMaybeChangedFullPaintBounds.includes(@) and
     !world.widgetsWithMaybeChangedFullPaintBounds.includes(copiedWidget)
      world.widgetsWithMaybeChangedFullPaintBounds.push copiedWidget

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
    copiedWidget = @deepCopy [], [], allWidgetsInStructure
    return copiedWidget

  # Serialization — delegates to the src/serialization/ Serializer. Unlike the old dev-only
  # prototype this replaced, serialize/deserialize SHIP in all builds (including --homepage):
  # they are a product feature, so they carry NO homepage-strip markers. Only the dev
  # "test menu" entries that drive them (serialiseToMemory etc., MenusHelper.testMenu) stay
  # homepage-stripped. See docs/serialization-duplication-reference.md.
  serialize: (opts) ->
    Serializer.serializeWidget @, opts


  # Deserialization -----------------------------------


  # Returns the restored, DETACHED widget (the caller attaches it). Callers that need the
  # async-decode readiness promise (SWCanvas image/canvas decode) should call
  # Deserializer.deserialize directly and await its .whenReady; the widget returned here
  # fills its canvases in within a frame.
  deserialize: (serializationString) ->
    Deserializer.deserialize(serializationString).widget

  # Save this widget subtree to a downloaded *.fzw.json file over file:// (a product
  # feature — ships in all builds). A SerializationError (an external pointer that can't be
  # encoded, ...) becomes a friendly, path-carrying dialog rather than an uncaught throw.
  saveToFile: ->
    try
      envelope = @serialize prettyPrint: true
    catch error
      if error instanceof SerializationError
        world.inform error.toString()
        return
      else
        throw error
    baseName = (@colloquialName?() or @constructor.name.replace "Wdgt", "") or "widget"
    FileSaving.saveStringAsFile envelope, baseName + ".fzw.json"

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
      # log the instance-scope source edit so a world snapshot can carry it (§12). The edit
      # also rides serialization on its own via `<name>_source` -> {"$src"}; the registry adds
      # auditability. (A re-injection during a snapshot restore re-logs harmlessly — the loader
      # replaces the whole registry from the snapshot's records.)
      world?.sourceEditsRegistry?.recordInstanceEdit? @, propertyName, txt
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
    # Affine transforms (§6 Phase 4D-2a): the Phase-1-symmetric escalation guard that USED to force a
    # widget inside a non-identity island to grab-to-parent (so a float-drag lifted the whole island) is
    # REMOVED — the loose unit is now resolved by the normal rules below, and ActivePointerWdgt's grab
    # dispatch maps it to the on-hand figure via _resolvePickOutFigureNoSettle (reuse the existing island
    # when the grabbed widget is its sole content — the Phase-1 whole-figure grab, no jump — or extract +
    # re-wrap a genuine sub-part). This is what lets you pick a SUB-widget OUT of an island. (Non-float
    # drags — sliders/handles — are unaffected: findFirstLooseWidget checks nonFloatDragging FIRST.)
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
    
  wantsDropOfChild: (aWdgt) ->
    return @_acceptsDrops

  # the SELF drop gate (public, pure, positive — §9.2): the base default is "yes, droppable"; WindowWdgt
  # (external) / BasementOpenerWdgt override to refuse. (ex-rejectsBeingDropped, polarity-flipped — §9.7-3;
  # a base default is required so a widget with no override still defaults droppable — R4.)
  wantsToBeDropped: ->
    return true

  # Drag-embed PAYLOAD CLASS (docs/specs/drag-embed-interaction-spec.md §4). A payload that
  # requiresDeliberateEmbedding must be ARMED by a dwell (spec §6) before a release embeds it into a
  # receptive container; plain payloads embed instantly, as today. Base = plain (false); WindowWdgt
  # overrides true. (Capability, not `isWindow` at call sites — type-test-elimination convention.)
  requiresDeliberateEmbedding: ->
    return false

  enableDrops: ->
    @_acceptsDrops = true

  disableDrops: ->
    @_acceptsDrops = false
  
  pickUp: ->
    oldParent = @parent
    oldParent?._beforeChildPickedUp? @
    world.hand.grab @
    # if one uses the "deferred" API then we need to look
    # into the "desiredExtent" as the true extent has yet
    # to be settled
    if @desiredExtent?
      @_applyMoveTo world.hand.position().subtract @desiredExtent.floorDivideBy 2
    else
      @_applyMoveTo world.hand.position().subtract @fullBounds().extent().floorDivideBy 2
    oldParent?._reactToChildPickedUp? @

  grabbedWidgetSwitcheroo: ->
    @
  
  situation: ->
    # answer a dictionary specifying where I am right now, so
    # I can slide back to it if I'm dropped somewhere else
    if @parent
      return (
        origin: @parent
        position: @position().subtract @parent.position()
      )
    nil
  
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
    # Affine transforms (§6 4A-2): resize/move handles now work on a widget INSIDE a non-identity
    # island — HandleWdgt.nonFloatDragging (and the grab-start offset in ActivePointerWdgt) map the
    # drag pointer through screenPointToMyPlane, so the dragged edge follows the island's rotated/
    # scaled axes. The Phase-1 refusal guard that used to `return` here is therefore lifted. (Float-
    # drag still escalates to the whole island via grabsToParentWhenDragged/_isInsideNonIdentityIsland.)
    if @isFreeFloating()
      @addAndTrackHandle "resizeHorizontalHandle"
      @addAndTrackHandle "resizeVerticalHandle"
      @addAndTrackHandle "moveHandle"
      @addAndTrackHandle "resizeBothDimensionsHandle"
      # Affine transforms (§6 Phase 4B-universal): EVERY free-floating widget gets a rotate handle at
      # the top-right of its halo. Dragging it rotates the widget via the halo rotation protocol
      # (rotationHalo_apply → the 4C sugar materialises an island on demand; an explicit island drives
      # its own spec). Requires 4A-2 (drag-delta mapping) so the sibling resize/move handles stay
      # correct once a rotation is in play.
      @addAndTrackHandle "rotateHandle"
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
    menu.__add colorPicker
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
    @_applyMoveTo widgetToBeNextTo.center()
    @_moveWithin whereToAddIt
    
  
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
    #    return @buildHierarchyMenu()

    widgetToAskMenuTo = @

    # check if a parent wants to take over my menu (and hopefully
    # merge some of my entries!). In such case let it open the
    # menu. Used for example for scrollable text (which is text inside
    # a ScrollPanelWdgt).
    anyParentsTakingOverMyMenu = @allParentsTopToBottomSuchThat (m) ->
      (m instanceof ScrollPanelWdgt) and m.takesOverAndMergesChildrensMenus
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
    # Surface a SerializationError (an external pointer that can't be encoded, a function
    # with no source, ...) as a friendly, path-carrying dialog instead of an uncaught throw
    # (the §4.7 UX; the file-save action in Phase 4 does the same). Any other error is a real
    # bug and re-thrown.
    try
      world.lastSerializationString = @serialize()
    catch error
      if error instanceof SerializationError
        world.inform error.toString()
      else
        throw error

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
      menu.addMenuItem "save to file…", true, @, "saveToFile", "save this widget\nto a *.fzw.json file"
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

  # SELF-SETTLE (single-mutation tier): unlock the contents settle-free, then flush ONCE (mirror of
  # disableDragsDropsAndEditing). Any entry point self-settles, so ordering vs world.add no longer matters;
  # the idempotency guard + per-child work live in the core.
  enableDragsDropsAndEditing: ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle()

  _enableDragsDropsAndEditingNoSettle: ->

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


    @parent?.showEditModeInBar?()
    whereToAct.dragsDropsAndEditingEnabled = true

    whereToAct.enableDrops()

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets whereToAct

    if childrenNotHandlesNorCarets?
      for each in childrenNotHandlesNorCarets
        each.unlockFromPanels()
        each.contrastOutFromPanelColor?()
        if each.isEditable?
          each.isEditable = true


  # SELF-SETTLE (single-mutation tier): lock the contents settle-free, then flush ONCE. Any entry point (the edit
  # button, the "disable editing" menu, or a construction-time call) self-settles -- so calling this before or after
  # world.add is equally legal (an orphan defers in-flush, orphan-settledness). Idempotency guard + per-child work
  # live in the core; world.stopEditing routes to the NON-settling _stopEditingNoSettle (a caret teardown re-fits its
  # text, so the public stopEditing self-settles -- reaching it inside this flush would throw).
  disableDragsDropsAndEditing: ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle()

  _disableDragsDropsAndEditingNoSettle: ->
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


    @parent?.showViewModeInBar?()
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
            world._stopEditingNoSettle()


  # ---------------------------------------------------------------------

  _beforeBeingGrabbed: ->
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

  # The shared body of every controller widget's openTargetPropertySelector (Tier H3, 2026-07-03): pop up the
  # "choose target property" menu -- one item per (label, setter) pair the caller resolved from `theTarget`'s
  # setter table. WHICH table (stringSetters / numericalSetters / colorSetters / allSetters) is the ONLY thing
  # the 8 per-class openTargetPropertySelector stubs differ by, so they now each pass their table here and this
  # holds the once-copied menu-building body. Each item wires @action = that setter onto theTarget via
  # setTargetAndActionWithOnesPickedFromMenu (a ControllerMixin method -- every caller @augmentWith's it).
  # Deliberately on Widget, NOT ControllerMixin: as an INHERITED member it is hidden from the inspector's
  # default own-props view, so the 8 controllers' inspected member lists are unshifted -- a ControllerMixin
  # method would be copied in as an OWN member of all 8 and shift every one of them. (It DOES surface in the
  # rarer inherited-props inspector view; one such SystemTest, macroDuplicatedInspectorDrivesCopiedTargetOnly,
  # was recaptured.) The thin per-class openTargetPropertySelector stays (own, menu-dispatched).
  _popUpTargetPropertyMenu: (theTarget, setters) ->
    [menuEntriesStrings, functionNamesStrings] = setters
    menu = new MenuWdgt @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuWdgt @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()

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
    functionNamesStrings.push "_applyWidth", "_applyHeight", "setAlphaScaled", "setPadding", "setPaddingTop", "setPaddingBottom", "setPaddingLeft", "setPaddingRight"

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
    if triggeringChild?.isFreeFloating()
      # (proper-layouts, PROPERTY sub-seam deletion 2026-07-01) A freefloating child normally can't change its
      # parent's layout (positioned absolutely), so its invalidate does NOT climb. EXCEPTION: if I (the parent) am
      # a size-TRACKING container (scroll / stack / window -- I define _reLayoutChildren) then the child's SIZE
      # genuinely IS tracked, so OFF-PASS let the invalidate CLIMB THROUGH (fall past this return) so I re-fit.
      # This is the uniform dirty-tree replacement for the deleted _announceLayoutPropertyChangeToContainer seam.
      # IN-PASS this stays skipped: in-pass container re-fits are handled by the settle loop's ORDERED settle-time
      # re-fit (_reFitMyTrackingContainerAfterSettle, §4.3), and climbing in-pass would hit the FLOWRULE throw below.
      return unless (@_reLayoutChildren? and not world?._recalculatingLayouts)
    # INERT-RECEIVER branch: a free-floating + inert overlay (caret / resize handle) has no parent layout to climb
    # into, and is excluded from every container's content-bounds (childrenNotHandlesNorCarets), so re-running its
    # _reLayout re-fits NOTHING above it. The climb, the flow-rule throw, and the careless-push audit below are
    # therefore all structurally INAPPLICABLE -- they PASS here, they are not silenced (the worry this resolves:
    # docs/unify-layout-enqueue-primitives-plan.md §2). So enqueue just me, no climb. Gated on BOTH predicates so no
    # content widget can slip onto the no-climb path -- a content widget's container genuinely needs the climb. (This
    # is the single home of the caret's self-schedule, reached via CaretWdgt._requestScrollFollow -> here; today only
    # the caret exercises it -- handles are moved by drag machinery through immediate mutators, never self-invalidate.)
    if @isFreeFloating() and @isLayoutInert?()
      @__markForRelayout()
      return
    # FLOW-RULE INVARIANT (fail fast): the immediate geometry mutators (the _apply*/_commit* corners, __commit* leaves, _move*/_set*/_resize* convenience)
    # must not SCHEDULE layout -- they only mutate; scheduling a (re-)layout is the public
    # self-settling tier's job. If an invalidate reaches here while recalculateLayouts is running,
    # an immediate mutator is (re-)scheduling layout mid-pass -- the Phase 3b Slice 2 app-freeze (a
    # container resizing its children climbed an invalidate back into itself, so the until-loop
    # never converged). The immediate mutators were migrated to honour this and a build-time lint (rule
    # [E]) enforces it statically; this throw is the RUNTIME tripwire for anything that slips past
    # the lint (e.g. a dynamic/duck-typed call it can't see). The throw is safe to be hard now
    # (task #18): the recalculateLayouts catch is strictly non-flushing and defers recovery outside
    # the flush, so this throw is caught there, reported via the layout-error path (loud
    # console.error + in-world console), and the world keeps running -- never a freeze.
    if world?._recalculatingLayouts
      throw new Error "FLOWRULE_VIOLATION: _invalidateLayout() during a layout pass by " + (@constructor?.name) + " -- an immediate geometry mutator (an _apply*/_commit*/__commit* corner or _move*/_set* convenience) must not schedule layout (task #17)"
    # DEBUG (WorldWdgt.auditPaintTimeLayoutScheduling, default off): PAINT must be READ-ONLY. healingRectangles-
    # Phase is true only inside updateBroken's paint pass; reaching here then means a widget SCHEDULED layout while
    # being painted -- crossing the render/layout boundary. Record its ctor for the per-frame paint-schedules log.
    # (The caret's paint-time scroll-follow, the original such offender, was moved to a post-flush pre-paint step.)
    if world?.healingRectanglesPhase and world.auditPaintTimeLayoutScheduling and not @isOrphan()
      (world._paintTimeLayoutSchedules ?= []).push @constructor?.name
    # DEBUG (WorldWdgt.auditUndeclaredEndOfCycle, default off): an OFF-SETTLE push (not @_inLayoutMutation) on
    # an ATTACHED widget made OUTSIDE a *DeferredSettle declaration (_deferredSettleDeclarationDepth == 0) is the
    # "careless" set the eventual declared-deferred-settling gate will reject -- record its ctor for the end-of-cycle
    # log. ORPHAN pushes are excluded: an off-world (under-construction) widget legitimately defers and settles
    # when attached (the _reactToChildRemoved lesson) -- it is not careless, and is the bulk of the macro-driver noise.
    # Recorded BEFORE __markForRelayout flips @layoutIsValid, and only on an ACTUAL push (@layoutIsValid still
    # true) -- an already-invalid widget is not re-pushed, so it must not be re-counted.
    if @layoutIsValid and world.auditUndeclaredEndOfCycle and world._deferredSettleDeclarationDepth == 0 and not world._inLayoutMutation and not @isOrphan()
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
    # PanelWdgt._reactToChildRemoved). A disable-probe confirmed the orphan re-layout changes nothing (byte-identical).
    # (Sets @maxWidth/@maxHeight inline rather than via _setMaxDimNoSettle, which would re-introduce the very
    # construction invalidate this skips; setMaxDim's own callers are unaffected.)
    @_invalidateLayout() unless @isOrphan()


  # CONVERT (end-of-cycle-flush-drawdown): setMaxDim is the public "set the max dimension" mutator, so it must
  # SELF-SETTLE (one flush per outermost public mutation) like every other public geometry setter. Its only
  # high-frequency caller -- the stack-divider drag (StackElementsSizeAdjustingWdgt.nonFloatDragging) -- and the
  # construction-time setMinAndMaxBoundsAndSpreadability call the NON-settling _setMaxDimNoSettle core instead, so
  # the drag-move STREAM still defers into the one end-of-cycle flush (a core rides the cycle by design; the
  # goal is deferred settling WITHOUT a PUBLIC method skipping its settle).
  setMaxDim: (overridingMaxDim) ->
    @_settleLayoutsAfter => @_setMaxDimNoSettle overridingMaxDim

  # PRIVATE DEFERRED-SETTLE entrypoint -- the first of the *DeferredSettle family. THIS is the family's canonical comment
  # -- the four geometry entrypoints (_setExtentDeferredSettle / _moveToDeferredSettle / _setWidthDeferredSettle /
  # _setHeightDeferredSettle) reference it. Same EFFECT as the private
  # _setMaxDimNoSettle core, but INTENTION-REVEALING: it DECLARES that this is an intentional per-event-stream
  # mutation (a drag / scroll / key burst) whose layout flush should ride the ONE end-of-cycle settle instead of
  # self-settling per call -- so a stream draining many mutations per frame collapses N flushes into 1. RESTRICTED
  # to those stream handlers, NOT for discrete/programmatic callers (which must use the self-settling setMaxDim so
  # their settled layout is available in-cycle); the restriction is enforced statically by check-layering rule [O]
  # (DEFERRED_SETTLE_CALLER_ALLOWLIST), which is also why the whole *DeferredSettle family is _-private. Because the deferred settling
  # is DECLARED here, the end-of-cycle audit can tell an intentional deferred-settle mutation from a public method that
  # carelessly forgot to self-settle. world.deferredSettlingEnabled is the A/B switch: ON (default) defers via the core;
  # OFF self-settles per call (like the plain setMaxDim), so we can MEASURE whether deferred settling is warranted for a
  # given stream (docs/coalescing-measurement.md -- e.g. key-repeat rarely bursts enough to matter). Default ON =>
  # byte-identical to calling the _NoSettle core directly. BOTH branches reach the _setMaxDimNoSettle core directly
  # -- a _-private entrypoint must not call the public setMaxDim (it would reach UP into the self-flushing layer;
  # rules [A]/[G]).
  _setMaxDimDeferredSettle: (overridingMaxDim) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setMaxDimNoSettle overridingMaxDim
    else
      @_settleLayoutsAfter => @_setMaxDimNoSettle overridingMaxDim

  # Run a deferred-settle-mutation core inside a DECLARATION window: while it runs, world._deferredSettleDeclarationDepth
  # is > 0, so the off-settle invalidates the core schedules are marked INTENTIONAL and the end-of-cycle debug
  # check (WorldWdgt.auditUndeclaredEndOfCycle) does NOT flag them as "careless". Every *DeferredSettle entrypoint
  # wraps its core through here. Nestable; returns the core's value. (Default-off audit => ~zero overhead.)
  _deferredSettleDeclare: (coreThunk) ->
    return coreThunk() unless world?
    world._deferredSettleDeclarationDepth += 1
    try
      return coreThunk()
    finally
      world._deferredSettleDeclarationDepth -= 1

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


  # NB the .height() halves of the three getRecursive*Dim queries are currently CONSUMED NOWHERE outside the
  # queries' own cross-clamps -- every external reader takes .width() only (the horizontal 3-case distribution
  # in Widget._reLayout, and the stack-divider drag). Kept correct anyway: desiredHeight used to init to nil,
  # and `nil < h` is always false in JS, so the child-height max never accumulated (fixed with the dim-cache
  # scaffolding removal -- the caches were written but never read, and NOTHING ever reset their check-flags,
  # so enabling the commented-out reads would have served permanently stale sizes).
  # ONE recursive walker for the three min/desired/max queries below. They differed only
  # in WHICH per-child query recurses and WHICH own-field pair backstops a widget with no
  # horizontal-stack children (plus the desired/min clamp, applied by the wrappers below).
  # Width SUMS across the stack children; height takes the MAX.
  _getRecursiveStackDim: (childQueryName, ownWidth, ownHeight) ->
    width = 0
    height = 0
    gotAWidth = false
    gotAHeight = false
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C[childQueryName]()
        gotAWidth = true
        width += childSize.width()
        if height < childSize.height()
          gotAHeight = true
          height = childSize.height()
    width = ownWidth unless gotAWidth
    height = ownHeight unless gotAHeight
    new Point width, height

  getRecursiveDesiredDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    (@_getRecursiveStackDim "getDesiredDim", @desiredWidth, @desiredHeight).min @getRecursiveMaxDim()

  getRecursiveMinDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    # the user might have forced the "desired" to be smaller than the widget's standard minimum
    (@_getRecursiveStackDim "getMinDim", @minWidth, @minHeight).min @getRecursiveMaxDim()

  getRecursiveMaxDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    @_getRecursiveStackDim "getMaxDim", @maxWidth, @maxHeight

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

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # freefloating layouts never need
    # adjusting. We marked the @layoutIsValid
    # to false because it's an important breadcrumb
    # for finding the widgets that actually have a
    # layout to be recalculated but this Widget
    # now needs to do nothing.

    # the _applyMoveTo makes sure that all children
    # that are float-attached move together with the
    # widget.
    @_applyMoveTo newBoundsForThisLayout.origin
    
    # bad kludge here but I think there will be more
    # of these as we move over to the new layouts, we'll
    # probably have split Widgets for the new layouts mechanism.
    # FIT_BOX_TO_TEXT content re-sizes its OWN height to its text, so hand it the
    # full bounds (origin + extent) in one shot; everything else just takes the
    # new extent (its origin was already set by the _applyMoveTo above). ANY
    # contained TextWdgt qualifies (a non-text widget has no fittingSpec, so it
    # falls through to the else).
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
      @_applyBounds newBoundsForThisLayout
    else
      @_applyExtent newBoundsForThisLayout.extent()

    if LayoutSpec.isCornerOrEdgeInternal @layoutSpec
      if @parent
        xDim = @parent.width()
        yDim = @parent.height()
        minDim = Math.min(xDim, yDim) * @layoutSpec_cornerInternal_proportionOfParent + @layoutSpec_cornerInternal_fixedSize

        @__commitExtent new Point minDim, minDim

        # TODO this hack is because I couldn't initialise this properly
        # where I should, due to load dependency problems
        if !@layoutSpec_cornerInternal_inset?
          @layoutSpec_cornerInternal_inset = new Point 0, 0

        if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPLEFT
          @_applyMoveTo new Point @parent.left() + @layoutSpec_cornerInternal_inset.x, @parent.top() + @layoutSpec_cornerInternal_inset.y
        else if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT
          @_applyMoveTo new Point @parent.right() - minDim - @layoutSpec_cornerInternal_inset.x, @parent.top() + @layoutSpec_cornerInternal_inset.y
        else if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOMRIGHT
          @_applyMoveTo new Point @parent.right() - minDim - @layoutSpec_cornerInternal_inset.x, @parent.bottom() - minDim - @layoutSpec_cornerInternal_inset.y
        else if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_RIGHT
          @_applyMoveTo new Point @parent.right() - minDim - @layoutSpec_cornerInternal_inset.x, Math.floor(@parent.top() + (@parent.extent().y - minDim)/2)
        else if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOM
          @_applyMoveTo new Point Math.floor(@parent.left() + (@parent.extent().x - minDim)/2), @parent.bottom() - minDim - @layoutSpec_cornerInternal_inset.y

    # »>> this part is excluded from the fizzygum homepage build
    else if @countOfChildrenInHorizontalStackLayout() != 0

      @addOrRemoveAdders()

      min = @getRecursiveMinDim()
      desired = @getRecursiveDesiredDim()
      max = @getRecursiveMaxDim()
      
      # we are forced to be in a space smaller
      # than the minimum needed. We obey.
      # Each of the three width regimes below differs ONLY in the per-child WIDTH it hands out, so each
      # sets a childWidthFor(C) closure (case preamble math hoisted as before); the ONE shared placement
      # loop underneath walks the stack children and lays each out. (Was three copies of that same loop.)
      if min.width() >= newBoundsForThisLayout.width()
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
        childWidthFor = (C) -> C.getMinDim().width() * reductionFraction

      # the min is within the bounds but the desired is just
      # equal or larger than the bounds.
      # i.e. we have more space then what is strictly needed
      # but less of what is desired.
      # give min to all and then what is left available
      # redistribute proportionally based on desired
      else if desired.width() >= newBoundsForThisLayout.width()
        desiredMargin = desired.width() - min.width()
        if desiredMargin != 0
          fraction = (newBoundsForThisLayout.width() - min.width()) / desiredMargin
        else
          fraction = 0
        childWidthFor = (C) ->
          minWidth = C.getMinDim().width()
          desWidth = C.getDesiredDim().width()
          minWidth + (desWidth - minWidth) * fraction

      # min and desired are strictly less than the bounds
      # i.e. we have more space than needed or desired
      # allocate all the desired spaces, and on top of that
      # give extra space based on maximum widths
      else
        maxMargin = max.width() - desired.width()
        totDesWidth = desired.width()
        extraSpace = newBoundsForThisLayout.width() - desired.width()
        if extraSpace < 0
          console.error "this shouldn't happen, extraSpace is negative: " + extraSpace

        if maxMargin > 0
          fillByDesiredFraction = 0
        else if maxMargin == 0
          fillByDesiredFraction = 1
        else
          console.error "this shouldn't happen, maxMargin negative: " + maxMargin + " max.width(): " + max.width() + " desired.width(): " + desired.width()
          fillByDesiredFraction = 0

        childWidthFor = (C) ->
          maxWidth = C.getMaxDim().width()
          desWidth = C.getDesiredDim().width()
          if (maxWidth - desWidth) > 0
            xtra = extraSpace * ((maxWidth - desWidth)/maxMargin)
          else
            xtra = 0
          desWidth + xtra + fillByDesiredFraction * (newBoundsForThisLayout.width()-desired.width()) * (desWidth / totDesWidth)

      # ONE shared placement loop for all three cases (each set childWidthFor above). The overflow guard
      # runs for every case but only case 3's max-based fill can trip it: cases 1 and 2 distribute to EXACTLY
      # newBoundsForThisLayout.width() (their per-child widths telescope to the available width), so childLeft
      # lands on right() and never exceeds it.
      childLeft = newBoundsForThisLayout.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        childBounds = new Rectangle \
          childLeft,
          newBoundsForThisLayout.top(),
          childLeft + childWidthFor(C),
          newBoundsForThisLayout.top() + newBoundsForThisLayout.height()
        childLeft += childBounds.width()
        if childLeft > newBoundsForThisLayout.right() + 5
          console.error "horizontal stack distribution overflowed its allocated width by " + (childLeft - newBoundsForThisLayout.right())
        C._reLayout childBounds
    # this part is excluded from the fizzygum homepage build <<«

    @markLayoutAsFixed()

    # if I just did my layout, also do the layout
    # of all children that have position/size depending on mine
    allCornerLayoutedChildren = @children.filter (m) -> LayoutSpec.isCornerOrEdgeInternal m.layoutSpec
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

    @_insertAddersSuchThat "lastSiblingBeforeMeSuchThat", "addAsSiblingBeforeMe"
    # the second call scans the OTHER direction -- only needed to add the LAST adder/droplet.
    @_insertAddersSuchThat "firstSiblingAfterMeSuchThat", "addAsSiblingAfterMe"

  # ONE direction-parameterized scan for addOrRemoveAdders' two passes (was two ~20-line while-loops
  # identical bar the scan/insert verbs): repeatedly find the first stack child still needing an adder on
  # the given side (skipping adders/droplets themselves) and insert one there, until none remain.
  _insertAddersSuchThat: (scanVerbName, insertVerbName) ->
    while true
      leftToDo = @firstChildSuchThat (m) ->
          if m.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
            return false
          if m.isLayoutAdderOrDroplet?()
            return false
          kkk = m[scanVerbName](
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
      leftToDo[insertVerbName] \
            new LayoutElementAdderOrDropletWdgt,
            nil,
            LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
  # this part is excluded from the fizzygum homepage build <<«
