# The mouse cursor. Note that it's not a child of the WorldMorph, this widget
# is never added to any other widget. [TODO] Find out why and write explanation.
# Not to be confused with the HandleMorph

class ActivePointerWdgt extends Widget

  mouseButton: nil
  # used for example to check that
  # mouseDown and mouseUp happen on the
  # same Widget (otherwise clicks happen for
  # example when resizing a button via the
  # handle)
  mouseDownWdgt: nil
  mouseDownPosition: nil
  wdgtToGrab: nil
  grabOrigin: nil
  mouseOverList: nil
  doubleClickWdgt: nil
  tripleClickWdgt: nil
  nonFloatDraggedWdgt: nil
  nonFloatDragPositionWithinWdgtAtStart: nil
  # this is useful during nonFloatDrags to pass the widget
  # the delta position since the last invocation
  previousNonFloatDraggingPos: nil

  constructor: ->
    @mouseOverList = new Set
    super()
    @minimumExtent = new Point 0,0
    @silentRawSetBounds Rectangle.EMPTY

  clippedThroughBounds: ->
    @checkClippedThroughBoundsCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
    @clippedThroughBoundsCache = @boundingBox()
    return @clippedThroughBoundsCache

  clipThrough: ->
    @checkClipThroughCache = WorldMorph.numberOfAddsAndRemoves + "-" + WorldMorph.numberOfVisibilityFlagsChanges + "-" + WorldMorph.numberOfCollapseFlagsChanges + "-" + WorldMorph.numberOfRawMovesAndResizes
    @clipThroughCache = @boundingBox()
    return @clipThroughCache
  
  # ActivePointerWdgt navigation:
  topWdgtUnderPointer: ->
    result = world.topWdgtSuchThat (m) =>
      m.clippedThroughBounds().containsPoint(@position()) and
        m.visibleBasedOnIsVisibleProperty() and
        !m.isCollapsed() and
        (m.noticesTransparentClick or (not m.isTransparentAt(@position()))) and
        # we exclude the Caret here because
        #  a) it messes up things on double-click as it appears under
        #     the mouse after the first clicks
        #  b) the caret disappears as soon as a menu appears, so it
        #     would be confusing to select a caret.
        # I drafted an alternative implementation where we manage
        # those situations without being radical in this filtering-out
        # but it was quite a bit more complicated.
        (m not instanceof CaretMorph) and
        # exclude widgets we use for highlighting
        # other widgets
        !m.wdgtThisWdgtIsHighlighting? and
        !m.wdgtThisWdgtIsPinouting?
    if result?
      return result
    else
      return world

  # »>> this part is excluded from the fizzygum homepage build
  menuAtPointer: ->
    result = world.topWdgtSuchThat (m) =>
      m.clippedThroughBounds().containsPoint(@position()) and
        m.visibleBasedOnIsVisibleProperty() and
        !m.isCollapsed() and
        (m.noticesTransparentClick or
        (not m.isTransparentAt(@position()))) and (m instanceof MenuMorph)
    return result
  # this part is excluded from the fizzygum homepage build <<«



  openContextMenuAtPointer: (wdgtTheMenuIsAbout) ->
    # note that the widgets that the menu
    # belongs to might not be under the mouse.
    # It usually is, but in cases
    # where a system test is playing against
    # a world setup that has varied since the
    # recording, this could be the case.

    # these three are checks and actions that normally
    # would happen on MouseDown event, but we
    # removed that event as we collapsed the down and up
    # into this coalesced higher-level event,
    # but we still need to make these checks and actions
    @destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem wdgtTheMenuIsAbout
    @stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere wdgtTheMenuIsAbout

    if Automator? and
     Automator.state == Automator.PLAYING
      Automator.fade 'rightMouseButtonIndicator', 0, 1, 10, new Date().getTime()
      setTimeout \
        =>
          Automator.fade 'rightMouseButtonIndicator', 1, 0, 500, new Date().getTime()
        , 100
    
    contextMenu = wdgtTheMenuIsAbout.buildContextMenu()
    while !contextMenu and wdgtTheMenuIsAbout.parent
      wdgtTheMenuIsAbout = wdgtTheMenuIsAbout.parent
      contextMenu = wdgtTheMenuIsAbout.buildContextMenu()

    if contextMenu
      contextMenu.popUpAtHand()


  # »>> this part is excluded from the fizzygum homepage build
  # not used in Fizzygum yet
  allWdgtsAtPointer: ->
    return world.collectAllChildrenBottomToTopSuchThat (m) =>
      m.visibleBasedOnIsVisibleProperty() and
      !m.isCollapsed() and
      m.clippedThroughBounds().containsPoint @position()
  # this part is excluded from the fizzygum homepage build <<«
  
  
  
  # ActivePointerWdgt floatDragging and dropping:
  #
  # floatDrag 'n' drop events, method(arg) -> receiver:
  #
  #   prepareToBeGrabbed() -> grabTarget
  #   reactToGrabOf(grabbedWdgt) -> oldParent
  #   wantsDropOf(wdgtToDrop) ->  newParent
  #   justDropped(activePointerWdgt) -> droppedWdgt
  #   reactToDropOf(droppedWdgt, activePointerWdgt) -> newParent
  #
  dropTargetFor: (aWdgt) ->
    target = @topWdgtUnderPointer()
    until target.wantsDropOf aWdgt
      target = target.parent
    target
  
  grab: (aWdgt, displacementDueToGrabDragThreshold,  switcherooHappened) ->
    return nil  if aWdgt instanceof WorldMorph
    oldParent = aWdgt.parent
    if !@isThisPointerFloatDraggingSomething()

      world.stopEditing()

      # this paragraph deals with how to resize/reposition the widget
      # that we are grabbing in respect to the hand
      if switcherooHappened
        # in this case the widget being grabbed is created on the fly
        # so just like the next case it's OK to center it under the pointer
        aWdgt.fullMoveTo @position().subtract aWdgt.extent().floorDivideBy 2
        aWdgt.fullRawMoveWithin world # TODO no fullMoveWithin ?
      else if aWdgt.extentToGetWhenDraggedFromGlassBox? and (oldParent instanceof GlassBoxBottomWdgt)
        # in this case the widget is "inflating". So, all
        # visual references that the user might have around the
        # position of the grab go out of the window: just center
        # the widget under the pointer and fit it within the
        # desktop bounds since we are at it (useful in case the
        # widget is inflating near the screen edges)
        aWdgt.setExtent aWdgt.extentToGetWhenDraggedFromGlassBox
        aWdgt.fullMoveTo @position().subtract aWdgt.extent().floorDivideBy 2
        aWdgt.fullRawMoveWithin world
      else if displacementDueToGrabDragThreshold?
        # in this case keep some visual consistency and move
        # the widget accordingly to where the grab started
        # (remember: we actually grab a while after the user has
        # pressed, because we want to see an actual significant move
        # before we resolve that this is a grab)
        # Don't fit the widget within the world because it often
        # happens to pick up a widget that is partially outside the
        # screen and it's no good to make it jump within the screen
        # - I tried and it looks really strange -
        aWdgt.fullRawMoveTo aWdgt.position().add displacementDueToGrabDragThreshold

      @grabOrigin = aWdgt.situation()
      aWdgt.prepareToBeGrabbed?()

      @add aWdgt
      aWdgt.justBeenGrabbed? oldParent
      # you must add the shadow
      # after the widget has been added
      # because "@add aWdgt" causes
      # the widget to be painted potentially
      # for the first time.
      # The shadow needs the image of the
      # widget to make the shadow, so
      # this is why we add the shadow after
      # the widget has been added.
      # Note that Widgets can specify the look
      # (i.e. offset blur and color)
      # of their shadow (e.g. Menus have a particular one
      # so they all seem to float at a particular height)
      # but here when we grab widgets we
      # specify a particular look for the shadow.
      # This is a particularly "floaty" shadow
      # which illustrates how things being dragged
      # are above anything else.

      aWdgt.addShadow new Point(6, 6), 0.1
      
      #debugger
      @fullChanged()
      # this gives an occasion to the old parent
      # widget to adjust itself e.g. the ScrollPanelWdgt
      # readjusts itself if you take some widgets
      # out of it.
      oldParent?.reactToGrabOf? aWdgt

  isThisPointerDraggingSomething: ->
    @isThisPointerFloatDraggingSomething() or @isThisPointerNonFloatDraggingSomething()

  isThisPointerFloatDraggingSomething: ->
    if @children.length > 0 then true else false

  isThisPointerNonFloatDraggingSomething: ->
    return @nonFloatDraggedWdgt?


  drop: ->
    if @isThisPointerFloatDraggingSomething()

      wdgtToDrop = @children[0]

      if wdgtToDrop.rejectsBeingDropped?()
        target = world
      else
        target = @dropTargetFor wdgtToDrop

      @fullChanged()
      wdgtToDrop.aboutToBeDropped? target
      target.aboutToDrop? wdgtToDrop
      target.add wdgtToDrop, nil, nil, true, nil, @position()
      wdgtToDrop.fullChanged()

      # when you click the buttons, sometimes you end up
      # clicking between the buttons, and so the "proper"
      # widget "loses focus" so to speak. So avoiding that here.
      if !(wdgtToDrop instanceof HorizontalMenuPanelWdgt)
        world.lastNonTextPropertyChangerButtonClickedOrDropped = wdgtToDrop

      @children = []
      @rawSetExtent new Point

      # first we notify the recipient of the drop
      # this gives the chance to the recipient to
      # initialise a layout spec for the dropped widget
      target.reactToDropOf? wdgtToDrop, @

      # then we notify the dropped widget. This currently
      # is used to let the dropped widget tweak the layout
      # spec (some widgets suddenly become constrained by ratio
      # when they are dropped into a document)
      wdgtToDrop.justDropped? target

    #else
    #  alert "if you never see this alert then you can delete the test"
  
  # ActivePointerWdgt event dispatching:
  #
  #    mouse events:
  #
  #   mouseDownLeft
  #   mouseDownRight
  #   mouseClickLeft
  #   mouseClickRight
  #   mouseDoubleClick
  #   mouseEnter
  #   mouseLeave
  #   mouseEnterfloatDragging
  #   mouseLeavefloatDragging
  #   mouseMove
  #   wheel
  #
  # Note that some handlers don't want the event but the
  # interesting parameters of the event. This is because
  # the testing harness only stores the interesting parameters
  # rather than a multifaceted and sometimes browser-specific
  # event object.

  destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem: (actionedWdgt) ->
    if world.temporaryHandlesAndLayoutAdjusters.size > 0
      unless world.temporaryHandlesAndLayoutAdjusters.has actionedWdgt
        world.temporaryHandlesAndLayoutAdjusters.forEach (eachTemporaryHandlesAndLayoutAdjusters) =>
          eachTemporaryHandlesAndLayoutAdjusters.fullDestroy()
        world.temporaryHandlesAndLayoutAdjusters.clear()

  stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere: (actionedWdgt) ->
    if world.caret?

      # some actioning widgets rely on the
      # caret, for example to change the properties
      # of text (e.g. make it bold)
      if actionedWdgt.editorContentPropertyChangerButton? and actionedWdgt.editorContentPropertyChangerButton
        return

      # if you click anything directly inside a button that has
      # "editorContentPropertyChangerButton" set, then do nothing
      # This is needed because you might "down" on the label of the
      # button and you don't want to stopEditing in that case
      # either...
      if actionedWdgt.parent? and
       (actionedWdgt.parent instanceof SimpleButtonWdgt) and
       actionedWdgt.parent.editorContentPropertyChangerButton? and
       actionedWdgt.parent.editorContentPropertyChangerButton
        return

      # there is a caret on the screen
      # depending on what the user is clicking on,
      # we might need to close an ongoing edit
      # operation, which means deleting the
      # caret and un-selecting anything that was selected.
      #
      # This check is because we don't want to interrupt
      # an edit if the user is invoking/clicking on anything
      # inside a menu regarding text that is being edited
      # because the invoked function
      # might do something with the selection
      # (for example doSelection takes the current selection).
      #
      # In other words, if we are actioning on something that has
      # the text as an ancestor, then don't stop the
      # editing.
      if actionedWdgt isnt world.caret.target
        # user clicked on something other than what the
        # caret is attached to
        mostRecentlyCreatedPopUp = world.mostRecentlyCreatedPopUp()
        if mostRecentlyCreatedPopUp?
          unless mostRecentlyCreatedPopUp.isAncestorOf actionedWdgt
            # only dismiss editing if the actionedWdgt the user
            # clicked on is not part of a menu.
            world.stopEditing()
        # there is no menu at all, in which case
        # we know there was an editing operation going
        # on that we need to stop
        else
          world.stopEditing()


  processMouseDown: (button, buttons, ctrlKey, shiftKey, altKey, metaKey) ->
    world.destroyToolTips()
    @wdgtToGrab = nil

    if Automator? and Automator.state == Automator.PLAYING
      if button is 2 or ctrlKey
        Automator.fade 'rightMouseButtonIndicator', 0, 1, 10, new Date().getTime()
      else
        Automator.fade 'leftMouseButtonIndicator', 0, 1, 10, new Date().getTime()


    @mouseDownPosition = @position()

    # check whether we are in the middle
    # of a floatDrag/drop operation
    if @isThisPointerFloatDraggingSomething()
      @drop()
      @mouseButton = nil
    else
      w = @topWdgtUnderPointer()

      @destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem w
      # TODO it seems a little aggressive to stop any editing
      # just on the "down", probably something higher level
      # would be better? Like if any other object is brought to the
      # foreground?
      @stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere w

      # if we are doing a mousedown on anything outside a menu
      # then all the menus must go, whether or not they have
      # been freshly created or not. This came about because
      # small movements of the mouse while clicking on the
      # desktop would not dismiss menus.
      if !(w.firstParentThatIsAPopUp() instanceof MenuMorph)
        @cleanupMenuWdgts nil, w, true

      @wdgtToGrab = w.findRootForGrab()
      if button is 2 or ctrlKey
        @mouseButton = "right"
        actualClick = "mouseDownRight"
        expectedClick = "mouseClickRight"
      else
        @mouseButton = "left"
        actualClick = "mouseDownLeft"
        expectedClick = "mouseClickLeft"

      @mouseDownWdgt = w
      @mouseDownWdgt = @mouseDownWdgt.parent  until @mouseDownWdgt[expectedClick]

      
      while !w[actualClick]?
        if w.parent?
          w = w.parent
        else
          break

      if w[actualClick]?
        w[actualClick] @position()
      #w = w.parent  until w[actualClick]
      #w[actualClick] @position()
  
  
   # note that the button param is not used,
   # but adding it for consistency...
  processMouseUp: (button, buttons, ctrlKey, shiftKey, altKey, metaKey) ->
    if Automator? and Automator.state == Automator.PLAYING
      if button is 2
        Automator.fade 'rightMouseButtonIndicator', 1, 0, 500, new Date().getTime()
      else
        Automator.fade 'leftMouseButtonIndicator', 1, 0, 500, new Date().getTime()

    w = @topWdgtUnderPointer()

    world.destroyToolTips()
    world.freshlyCreatedPopUps.clear()


    if @isThisPointerFloatDraggingSomething()
      @drop()
    else

      # used right now for the slider button:
      # it's likely that the non-float drag will end
      # up outside of its bounds, and yet we need to
      # notify the button that the drag is over so it
      # can repaint itself of another color.
      if @isThisPointerNonFloatDraggingSomething()
        @nonFloatDraggedWdgt.endOfNonFloatDrag?()

      @previousNonFloatDraggingPos = nil

      if @mouseButton is "left"
        expectedClick = "mouseClickLeft"
      else
        expectedClick = "mouseClickRight"

      # trigger the action
      until w[expectedClick]
        w = w.parent
        if not w?
          break
      if w?
        if w == @mouseDownWdgt

          switch expectedClick
            when "mouseClickLeft"
              w.mouseUpLeft? @position(), button, buttons, ctrlKey, shiftKey, altKey, metaKey
            when "mouseClickRight"
              w.mouseUpRight? @position(), button, buttons, ctrlKey, shiftKey, altKey, metaKey

          # also send doubleclick if the
          # two clicks happen on the same widget
          doubleClickInvocation = false

          if @doubleClickWdgt?
            # three conditions:
            #  - both clicks are left-button clicks
            #  - both clicks on same widget
            #  - both clicks nearby
            if @mouseButton == "left" and
             @doubleClickWdgt == w and
             ((@doubleClickPosition.distanceTo @position()) < WorldMorph.preferencesAndSettings.grabDragThreshold)
              #console.log "@doubleClickPosition.distanceTo @position():" + @doubleClickPosition.distanceTo @position()
              #console.log "WorldMorph.preferencesAndSettings.grabDragThreshold:" + WorldMorph.preferencesAndSettings.grabDragThreshold
              @doubleClickWdgt = nil
              # remember we are going to send a double click
              # but let's do it after. That's because we first
              # want to send the normal click AND we want to tell
              # in the normal click that that normal click is part
              # of a double click. Recognition is purely proximity + the real 300ms
              # window now: synthetic macro clicks deliberately space their two clicks
              # ~120ms apart (inside the window) and keep a non-scaled minimum gap
              # between DISTINCT click gestures (MacroToolkit), so the old fast-test
              # recognition gate is gone.
              doubleClickInvocation = true
              # triple-click detection starts here, it's just
              # like chaining a second double-click detection
              # once this double-click has just been detected
              # right here.
              @rememberTripleClickWdgtsForAWhile w
            else
              # This click does NOT complete a double-click with the remembered widget
              # (different widget/position). Treat a LEFT click as the START of a fresh
              # double-click sequence rather than discarding it — otherwise, when a prior
              # gesture left a stale candidate (which fast macro playback makes possible,
              # since gestures then fall <300ms apart), this click would be wasted and a
              # deliberate double/triple-click would silently degrade (its first click
              # eaten). At normal speed the 300ms forget timer has already cleared any prior
              # candidate before the next gesture, so this branch isn't reached and
              # behaviour is unchanged. A non-left click just clears the (left) candidate.
              if @mouseButton == "left"
                @rememberDoubleClickWdgtsForAWhile w
              else
                @forgetDoubleClickWdgts()
          else
            @rememberDoubleClickWdgtsForAWhile w

          tripleClickInvocation = false

          # also send tripleclick if the
          # three clicks happen on the same widget
          # Don't do anything if a double-click has
          # just been invoked because you'd immediately
          # fire a tripleClick
          # This pargraph of code is basically the same
          # as the previous one.
          if !doubleClickInvocation
            # same three conditions as double click
            if @mouseButton == "left" and
             @tripleClickWdgt == w and
             ((@tripleClickPosition.distanceTo @position()) < WorldMorph.preferencesAndSettings.grabDragThreshold)
              #debugger
              if @tripleClickWdgt == w
                @tripleClickWdgt = nil
                # remember we are going to send a triple click
                # but let's do it after. That's because we first
                # want to send the normal click AND we want to tell
                # in the normal click that that normal click is part
                # of a triple click. (Recognition is proximity + the real 300ms window
                # only — see the double-click branch above.)
                tripleClickInvocation = true
              else
                @forgetTripleClickWdgts()

          # fire the click, sending info on whether this was part
          # of a double/triple click
          if !w.editorContentPropertyChangerButton and !(w instanceof HorizontalMenuPanelWdgt)
            world.lastNonTextPropertyChangerButtonClickedOrDropped = w
          w[expectedClick] @position(), button, buttons, ctrlKey, shiftKey, altKey, metaKey, doubleClickInvocation, tripleClickInvocation
          #console.log ">>> sent event " + expectedClick + " to: " + w

          # now send the double/triple clicks
          if doubleClickInvocation
            @processDoubleClick w
          if tripleClickInvocation
            @processTripleClick w


      # some pop-overs can contain horizontal sliders
      # and when the user interacts with them, it's easy
      # that she can "drag" them outside the range and
      # do the mouse-up outside the boundaries
      # of the pop-over. So we avoid that here, if there
      # is a non-float drag ongoing then we avoid
      # cleaning-up the pop-overs
      if !@nonFloatDraggedWdgt?
        @cleanupMenuWdgts expectedClick, w

    @mouseButton = nil
    @nonFloatDraggedWdgt = nil


  forgetDoubleClickWdgts: ->
    @doubleClickWdgt = nil
    @doubleClickPosition = nil

  rememberDoubleClickWdgtsForAWhile: (w) ->
    @doubleClickWdgt = w
    @doubleClickPosition = @position()
    # Generation token so a STALE forget-timer can't clobber a newer remembered widget.
    # The 300ms forget is a real-wall-clock setTimeout; when two DISTINCT click gestures
    # fall within one 300ms window (which fast macro playback can cause — the gestures'
    # synthetic events drain close together in real time), the earlier gesture's timer
    # would otherwise fire AFTER the later gesture re-armed this state and wipe it,
    # silently killing the later double-click. Only the latest timer (matching generation)
    # is allowed to forget.
    myGeneration = (@doubleClickGeneration ? 0) + 1
    @doubleClickGeneration = myGeneration
    setTimeout (=>
      if @doubleClickGeneration == myGeneration
        @forgetDoubleClickWdgts()
      return false
    ), 300

  # basically the same as rememberDoubleClickWdgtsForAWhile
  forgetTripleClickWdgts: ->
    @tripleClickWdgt = nil
    @tripleClickPosition = nil

  rememberTripleClickWdgtsForAWhile: (w) ->
    @tripleClickWdgt = w
    @tripleClickPosition = @position()
    # same stale-timer guard as rememberDoubleClickWdgtsForAWhile (a prior gesture's
    # 300ms timer must not wipe a newer gesture's remembered triple-click widget)
    myGeneration = (@tripleClickGeneration ? 0) + 1
    @tripleClickGeneration = myGeneration
    setTimeout (=>
      if @tripleClickGeneration == myGeneration
        @forgetTripleClickWdgts()
      return false
    ), 300

  cleanupMenuWdgts: (expectedClick, w, alsoKillFreshMenus)->

    world.hierarchyOfClickedWdgts.clear()
    world.hierarchyOfClickedMenus.clear()

    # note that all the actions due to the clicked
    # widgets have been performed, now we can destroy
    # widgets queued up for closure
    # which might include menus...
    # if we destroyed menus earlier, the
    # actions that come from the click
    # might be mangled, e.g. adding a menu
    # to a destroyed menu, etc.
    world.closePopUpsMarkedForClosure()

    # remove menus that have requested
    # to be removed when a click happens outside
    # of their bounds OR the bounds of their
    # children
    #if expectedClick == "mouseClickLeft"
    # collect all widgets up the hierarchy of
    # the one the user clicked on.
    # (including the one the user clicked on)
    ascendingWdgts = w
    world.hierarchyOfClickedWdgts.clear()
    world.hierarchyOfClickedWdgts.add ascendingWdgts
    while ascendingWdgts.parent?
      ascendingWdgts = ascendingWdgts.parent
      world.hierarchyOfClickedWdgts.add ascendingWdgts

    # remove menus that have requested
    # to be removed when a click happens outside
    # of their bounds OR the bounds of their
    # children
    #if expectedClick == "mouseClickLeft"
    # collect all the menus up the hierarchy of
    # the one the user clicked on.
    # (including the one the user clicked on)
    # note that the hierarchy of the menus is actually
    # via the getParentPopUp method
    firstParentThatIsAPopUp = w.firstParentThatIsAPopUp()
    if firstParentThatIsAPopUp?.hierarchyOfPopUps?
      world.hierarchyOfClickedMenus = firstParentThatIsAPopUp.hierarchyOfPopUps()
    
    # go through the widgets that wanted a notification
    # in case there is a click outside of them or any
    # of their children.
    # i.e. check from the notification list which ones are not
    # in the hierarchy of the clicked widgets
    # and call their callback.
    #console.log "widgets wanting to be notified: " + world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren
    #console.log "hierarchy of clicked widgets: " + world.hierarchyOfClickedWdgts
    #console.log "hierarchy of clicked menus: " + world.hierarchyOfClickedMenus
    

    # because we might remove elements of the set while we
    # iterate on it (as we destroy menus that want to be destroyed
    # when the user clicks outside of them or their children)
    world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.forEach (eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren) =>
      if (!world.hierarchyOfClickedMenus.has eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren) and
         (!world.hierarchyOfClickedWdgts.has eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren)
        # skip the freshly created menus as otherwise we might
        # destroy them immediately
        if alsoKillFreshMenus or !world.freshlyCreatedPopUps.has eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren
          if eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[0]?
            eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren[eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[0]].call eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren, eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[1], eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[2], eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[3]

  processDoubleClick: (w = @topWdgtUnderPointer()) ->
    world.destroyToolTips()
    if @isThisPointerFloatDraggingSomething()
      @drop()
    else
      w = w.parent  while w and not w.mouseDoubleClick
      w.mouseDoubleClick @position() if w
    @mouseButton = nil

  processTripleClick: (w = @topWdgtUnderPointer()) ->
    world.destroyToolTips()
    if @isThisPointerFloatDraggingSomething()
      @drop()
    else
      w = w.parent  while w and not w.mouseTripleClick
      w.mouseTripleClick @position() if w
    @mouseButton = nil
  
  # see https://developer.mozilla.org/en-US/docs/Web/Events/wheel
  processWheel: (deltaX, deltaY, deltaZ, altKey, button, buttons) ->
    w = @topWdgtUnderPointer()
    w = w.parent  while w and not w.wheel

    if w?
      w.wheel deltaX, deltaY, deltaZ, altKey, button, buttons
  
  

  ## Drop types:
  ##
  ##        droppedImage
  ##        droppedSVG
  ##        droppedAudio
  ##        droppedText
  ##
  #processDrop: (event) ->
  #  #
  #  #    find out whether an external image or audio file was dropped
  #  #    onto the world canvas, turn it into an offscreen canvas or audio
  #  #    element and dispatch the
  #  #
  #  #        droppedImage(canvas, name)
  #  #        droppedSVG(image, name)
  #  #        droppedAudio(audio, name)
  #  #
  #  #    events to interested Widgets at the mouse pointer
  #  #    if none of the above content types can be determined, the file contents
  #  #    is dispatched as an ArrayBuffer to interested Widgets:
  #  #
  #  #    ```droppedBinary(anArrayBuffer, name)```
  #
  #  files = (if event instanceof FileList then event else (event.target.files || event.dataTransfer.files))
  #  url = (if event.dataTransfer then event.dataTransfer.getData("URL") else nil)
  #  txt = (if event.dataTransfer then event.dataTransfer.getData("Text/HTML") else nil)
  #  targetDrop = @topWdgtUnderPointer()
  #  img = new Image
  #
  #  readSVG = (aFile) ->
  #    pic = new Image
  #    targetDrop = targetDrop.parent  until targetDrop.droppedSVG
  #    pic.onload = ->
  #      targetDrop.droppedSVG pic, aFile.name
  #    frd = new FileReader
  #    frd.onloadend = (e) ->
  #      pic.src = e.target.result
  #    frd.readAsDataURL aFile
  #
  #  readImage = (aFile) ->
  #    pic = new Image
  #    targetDrop = targetDrop.parent  until targetDrop.droppedImage
  #    pic.onload = ->
  #      canvas = HTMLCanvasElement.createOfPhysicalDimensions new Point pic.width, pic.height
  #      canvas.getContext("2d").drawImage pic, 0, 0
  #      targetDrop.droppedImage canvas, aFile.name
  #
  #    frd = new FileReader
  #    frd.onloadend = (e) ->
  #      pic.src = e.target.result
  #
  #    frd.readAsDataURL aFile
  #
  #  readAudio = (aFile) ->
  #    snd = new Audio
  #    frd = new FileReader
  #    targetDrop = targetDrop.parent  until targetDrop.droppedAudio
  #    frd.onloadend = (e) ->
  #      snd.src = e.target.result
  #      targetDrop.droppedAudio snd, aFile.name
  #    frd.readAsDataURL aFile
  #
  #  readText = (aFile) ->
  #    frd = new FileReader
  #    targetDrop = targetDrop.parent  until targetDrop.droppedText
  #    frd.onloadend = (e) ->
  #      targetDrop.droppedText e.target.result, aFile.name
  #    frd.readAsText aFile
  #
  #
  #  readBinary = (aFile) ->
  #    frd = new FileReader
  #    targetDrop = targetDrop.parent  until targetDrop.droppedBinary
  #    frd.onloadend = (e) ->
  #      targetDrop.droppedBinary e.target.result, aFile.name
  #    frd.readAsArrayBuffer aFile
  #
  #  parseImgURL = (html) ->
  #    url = ""
  #    start = html.indexOf "<img src=\""
  #    return nil  if start is -1
  #    start += 10
  #    for i in [start...html.length]
  #      c = html[i]
  #      return url  if c is "\""
  #      url = url.concat c
  #    nil
  #
  #  if files.length
  #    for file in files
  #      if file.type.includes("svg") && !WorldMorph.preferencesAndSettings.rasterizeSVGs
  #        readSVG file
  #      else if file.type.startsWith "image"
  #        readImage file
  #      else if file.type.startsWith "audio"
  #        readAudio file
  #      else if file.type.startsWith "text"
  #        readText file
  #      else
  #        readBinary file
  #  else if url
  #    if url.slice(url.lastIndexOf(".") + 1).toLowerCase() in ["gif", "png", "jpg", "jpeg", "bmp"]
  #      targetDrop = targetDrop.parent  until targetDrop.droppedImage
  #      img = new Image
  #      img.onload = ->
  #        canvas = HTMLCanvasElement.createOfPhysicalDimensions new Point img.width, img.height
  #        canvas.getContext("2d").drawImage img, 0, 0
  #        targetDrop.droppedImage canvas
  #      img.src = url
  #  else if txt
  #    targetDrop = targetDrop.parent  until targetDrop.droppedImage
  #    img = new Image
  #    img.onload = ->
  #      canvas = HTMLCanvasElement.createOfPhysicalDimensions new Point img.width, img.height
  #      canvas.getContext("2d").drawImage img, 0, 0
  #      targetDrop.droppedImage canvas
  #    src = parseImgURL txt
  #    img.src = src  if src

  
  # ActivePointerWdgt tools
  
  # ActivePointerWdgt floatDragging optimization
  fullRawMoveBy: (delta) ->
    if delta.isZero() then return
    world.disableTrackChanges()
    #console.log "move 2"
    @breakNumberOfRawMovesAndResizesCaches()
    super delta
    world.maybeEnableTrackChanges()
    @fullChanged()

  processMouseMove: (pageX, pageY, button, buttons, ctrlKey, shiftKey, altKey, metaKey) ->

    posInDocument = world.getCanvasPosition()
    # events from JS arrive in page coordinates,
    # we turn those into world coordinates
    # instead.
    worldX = pageX - posInDocument.x
    worldY = pageY - posInDocument.y

    #startProcessMouseMove = new Date().getTime()
    pos = new Point worldX, worldY
    @fullRawMoveTo pos

    if Automator? and Automator.state == Automator.PLAYING
      mousePointerIndicator = document.getElementById "mousePointerIndicator"
      mousePointerIndicator.style.display = 'block'
      posInDocument = world.getCanvasPosition()
      mousePointerIndicator.style.left = (posInDocument.x + worldX - (mousePointerIndicator.clientWidth/2)) + 'px'
      mousePointerIndicator.style.top = (posInDocument.y + worldY - (mousePointerIndicator.clientHeight/2)) + 'px'

    # determine the new mouse-over-list.
    # Spacial multiplexing
    # (search "multiplexing" for the other parts of
    # code where this matters)
    # There are two interpretations of what this
    # list should be:
    #   1) all widgets "pierced through" by the pointer
    #   2) all widgets parents of the topmost widgets under the pointer
    # 2 is what is used in Cuis
    
    # commented-out implementation of 1):
    # mouseOverNew = @allWdgtsAtPointer().reverse()
    topWdgt = @topWdgtUnderPointer()
    # allParentsTopToButton makes more logical sense but
    # allParentsBottomToTop is cheaper and it all ends up in a set anyways
    mouseOverNew = new Set topWdgt.allParentsBottomToTop()

    @determineGrabs pos, topWdgt, mouseOverNew

    @dispatchEventsFollowingMouseMove mouseOverNew

  checkDraggingTreshold: ->
    # UNFORTUNATELY OLD tests didn't take the correction into account,
    # pointers inevitably have some "noise", so to avoid that
    # a simple clicking (which could be done for example for
    # selection purposes or to pick a position for a cursor)
    # turns into a drag, so we add
    # a grab/drag distance threshold.
    # Note that even if the mouse moves a bit, we are still
    # picking up the correct widget that was under the mouse when
    # the mouse down happened.
    # Also we correct for the initial displacement
    # due to the threshold, so really when user starts dragging
    # it should pick up the EXACT point where the click happened,
    # not a "later" point once the threshold is passed.

    # so we have to bypass this mechanism for those.
    displacementDueToGrabDragThreshold = nil
    skipGrabDragThreshold = false
    
    if Automator? and Automator.state == Automator.PLAYING
      if !window["#{world.automator.player.currentlyPlayingTestName()}"].grabDragThreshold?
        skipGrabDragThreshold = true

    if !skipGrabDragThreshold
      if @wdgtToGrab.parent != world or (!@wdgtToGrab.isEditable? or @wdgtToGrab.isEditable )
        if (@mouseDownPosition.distanceTo @position()) < WorldMorph.preferencesAndSettings.grabDragThreshold
          return [true,nil]
      displacementDueToGrabDragThreshold = @position().subtract @mouseDownPosition

    return [false, displacementDueToGrabDragThreshold]

  determineGrabs: (pos, topWdgt, mouseOverNew) ->
    if !@isThisPointerDraggingSomething() and (@mouseButton is "left")
      w = topWdgt.findRootForGrab()
      topWdgt.mouseMove pos  if topWdgt.mouseMove

      # if a widget is marked for grabbing, grab it
      if @wdgtToGrab
        
        # these first two cases are for float dragging
        # the third case is non-float drag
        if @wdgtToGrab.isTemplate
          [skipDragging, displacementDueToGrabDragThreshold] = @checkDraggingTreshold()
          if skipDragging then return

          w = @wdgtToGrab.fullCopy()
          w.isTemplate = false
          @grab w, displacementDueToGrabDragThreshold
          @grabOrigin = @wdgtToGrab.situation()

        else if @wdgtToGrab.detachesWhenDragged()
          [skipDragging, displacementDueToGrabDragThreshold] = @checkDraggingTreshold()
          if skipDragging then return

          originalWdgtToGrab = @wdgtToGrab
          @wdgtToGrab = @wdgtToGrab.grabbedWidgetSwitcheroo()
          w = @wdgtToGrab
          @grab w, displacementDueToGrabDragThreshold, (originalWdgtToGrab != w)

        else
          # non-float drags are for things such as sliders
          # and resize handles.
          # you could have the concept of de-noising, but
          # actually it seems nicer to have a "springy"
          # reaction to a slider with some noise.
          # Users don't seem to click on a slider for any other
          # reason than to move it (as opposed to selecting them
          # or picking a position for a cursor), so it's OK.
          @nonFloatDraggedWdgt = @wdgtToGrab
          @nonFloatDragPositionWithinWdgtAtStart =
            # if we ever will need to compensate for the grab/drag
            # treshold here, just add .subtract displacementDueToGrabDragThreshold
            (pos.subtract @nonFloatDraggedWdgt.position())


        # if the mouse has left its fullBounds, center it
        if w
          fb = w.fullBounds()
          unless fb.containsPoint pos
            @rawSetExtent @extent().subtract fb.extent().floorDivideBy 2
            @grab w
            @fullRawMoveTo pos
    #endProcessMouseMove = new Date().getTime()
    #timeProcessMouseMove = endProcessMouseMove - startProcessMouseMove
    #console.log('Execution time ProcessMouseMove: ' + timeProcessMouseMove)


    if @isThisPointerNonFloatDraggingSomething()
      #console.log "nonFloatDraggedWdgt: " + @nonFloatDraggedWdgt

      # OK so this is an interesting choice. You can avoid
      # this next line and have Fizzygum to behave like OSX where you
      # can scroll on a panel without bringing its window in the
      # foreground. OR you can have the window to automatically
      # pop into the foreground. I'm liking the OSX style
      # so I'm leaving this commented-out, but it's there.
      # TODO this could be a setting somewhere in Fizzygum.
      # @nonFloatDraggedWdgt.bringToForeground()

      if @mouseButton
        if @previousNonFloatDraggingPos?
          deltaDragFromPreviousCall = pos.subtract @previousNonFloatDraggingPos
        else
          deltaDragFromPreviousCall = nil
        @previousNonFloatDraggingPos = pos.copy()
        @nonFloatDraggedWdgt.nonFloatDragging?(@nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall)
    

  # this is used by the ScrollMorph: clicking on the slider
  # (but OUTSIDE of the button), the (center of the) button
  # is immediately non-float dragged to where clicked.
  nonFloatDragWdgtFarAwayToHere: (wdgtFarAway, pos) ->
    # allParentsTopToButton makes more logical sense but
    # allParentsBottomToTop is cheaper and it all ends up in a set anyways
    mouseOverNew = new Set wdgtFarAway.allParentsBottomToTop()
    @previousNonFloatDraggingPos = wdgtFarAway.center()
    @nonFloatDragPositionWithinWdgtAtStart = (new Point wdgtFarAway.width()/2, wdgtFarAway.height()/2).round()
    @nonFloatDraggedWdgt = wdgtFarAway
    # this one calls the wdgtFarAway's nonFloatDragging method,
    # for example in case of a SliderMorph invoking this on its
    # button, this causes the movement of the button
    # and adjusting of the Slider values and potentially
    # adjusting scrollpanel etc.
    @determineGrabs pos, wdgtFarAway, mouseOverNew

    # The teleported widget is now under the (stationary) pointer. Resolve the
    # mouseEnter/mouseLeave consequence of that geometry change NOW, while the
    # non-float drag is active, so the widget's mouseEnter is consumed under the
    # drag guard (e.g. SliderButtonMorph.mouseEnter early-returns while the hand
    # is dragging) and the widget is recorded in @mouseOverList. Otherwise the
    # next per-cycle reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges
    # (WorldMorph.doOneCycle) can fire that mouseEnter AFTER mouse-up has already
    # un-dragged the widget — spuriously HIGHLIGHTing it. Deferring this caused a
    # dpr-2-only flake in SystemTest_macroSliderTrackClickMovesButton: a heavy
    # SWCanvas cycle drains the down+up together, so no held-button frame ever
    # interposes to absorb the enter. Resolving it here is cadence/density-independent.
    @dispatchEventsFollowingMouseMove mouseOverNew

  reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges: ->
    topWdgt = @topWdgtUnderPointer()
    # allParentsTopToButton makes more logical sense but
    # allParentsBottomToTop is cheaper and it all ends up in a set anyways
    mouseOverNew = new Set topWdgt.allParentsBottomToTop()
    @dispatchEventsFollowingMouseMove mouseOverNew

  dispatchEventsFollowingMouseMove: (mouseOverNew) ->

    @mouseOverList.forEach (old) =>
      unless mouseOverNew.has old
        old.mouseLeave?()
        old.mouseLeavefloatDragging?()  if @mouseButton

    mouseOverNew.forEach (newWdgt) =>
      
      # send mouseMove only if mouse actually moved,
      # otherwise it will fire also when the user
      # simply clicks
      if !@mouseDownPosition? or !@mouseDownPosition.equals @position()
        newWdgt.mouseMove?(@position(), @mouseButton)
      
      unless @mouseOverList.has newWdgt
        newWdgt.mouseEnter?()
        newWdgt.mouseEnterfloatDragging?()  if @mouseButton

      # autoScrolling support:
      if @isThisPointerFloatDraggingSomething()
        widgetBeingFloatDragged = @children[0]
        # if we are dragging stuff that can't be dropped
        # (e.g. external windows) then nothing happens
        if !widgetBeingFloatDragged.rejectsBeingDropped? or !widgetBeingFloatDragged.rejectsBeingDropped()
          if newWdgt instanceof ScrollPanelWdgt
            if newWdgt.wantsDropOf widgetBeingFloatDragged
              if !newWdgt.boundingBox().insetBy(
                WorldMorph.preferencesAndSettings.scrollBarsThickness * 3
                ).containsPoint @position()
                  newWdgt.startAutoScrolling()

    @mouseOverList = mouseOverNew
