# HandMorph ///////////////////////////////////////////////////////////

# The mouse cursor. Note that it's not a child of the WorldMorph, this Morph
# is never added to any other morph. [TODO] Find out why and write explanation.
# Not to be confused with the HandleMorph

class HandMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  world: null
  mouseButton: null
  # used for example to check that
  # mouseDown and mouseUp happen on the
  # same Morph (otherwise clicks happen for
  # example when resizing a button via the
  # handle)
  mouseDownMorph: null
  morphToGrab: null
  grabOrigin: null
  mouseOverList: null
  temporaries: null
  touchHoldTimeout: null
  doubleClickMorph: null
  nonFloatDraggedMorph: null
  nonFloatDragPositionWithinMorphAtStart: null

  constructor: (@world) ->
    @mouseOverList = []
    @temporaries = []
    super()
    @bounds = new Rectangle()
  
  changed: ->
    if @world?
      b = @boundsIncludingChildren()
      if !b.extent().eq(new Point())
        @world.broken.push @boundsIncludingChildren().spread()
  
  
  # HandMorph navigation:
  topMorphUnderPointer: ->
    result = @world.topMorphSuchThat (m) =>
      m.visibleBounds().containsPoint(@bounds.origin) and
        !m.isMinimised and
        m.isVisible and
        (m.noticesTransparentClick or (not m.isTransparentAt(@bounds.origin))) and
        (m not instanceof ShadowMorph)
    if result?
      return result
    else
      return @world

  menuAtPointer: ->
    result = @world.topMorphSuchThat (m) =>
      m.visibleBounds().containsPoint(@bounds.origin) and
        !m.isMinimised and m.isVisible and (m.noticesTransparentClick or
        (not m.isTransparentAt(@bounds.origin))) and (m instanceof MenuMorph)
    return result



  openContextMenuAtPointer: (morphTheMenuIsAbout) ->
    # note that the morphs that the menu
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
    @destroyActiveHandleIfHandHasNotActionedIt morphTheMenuIsAbout
    @stopEditingIfActionIsElsewhere morphTheMenuIsAbout

    if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
      fade('rightMouseButtonIndicator', 0, 1, 10, new Date().getTime());
      setTimeout \
        =>
          fade('rightMouseButtonIndicator', 1, 0, 500, new Date().getTime())
        , 100
    
    contextMenu = morphTheMenuIsAbout.contextMenu()
    while (not contextMenu) and morphTheMenuIsAbout.parent
      morphTheMenuIsAbout = morphTheMenuIsAbout.parent
      contextMenu = morphTheMenuIsAbout.contextMenu()

    if contextMenu 
      contextMenu.popUpAtHand(morphTheMenuIsAbout.firstContainerMenu()) 

  #
  #    alternative -  more elegant and possibly more
  #	performant - solution for topMorphUnderPointer.
  #	Has some issues, commented out for now
  #
  #HandMorph::topMorphUnderPointer = function () {
  #	var myself = this;
  #	return this.world.topMorphSuchThat(function (m) {
  #		return m.visibleBounds().containsPoint(myself.bounds.origin) &&
  #			!m.isMinimised &&
  #     m.isVisible &&
  #			(m.noticesTransparentClick ||
  #				(! m.isTransparentAt(myself.bounds.origin))) &&
  #			(! (m instanceof ShadowMorph));
  #	});
  #};
  #


  # not used in ZK yet
  allMorphsAtPointer: ->
    return @world.collectAllChildrenBottomToTopSuchThat (m) =>
      !m.isMinimised and m.isVisible and m.visibleBounds().containsPoint(@bounds.origin)
  
  
  
  # HandMorph floatDragging and dropping:
  #
  #	floatDrag 'n' drop events, method(arg) -> receiver:
  #
  #		prepareToBeGrabbed(handMorph) -> grabTarget
  #		reactToGrabOf(grabbedMorph) -> oldParent
  #		wantsDropOf(morphToDrop) ->  newParent
  #		justDropped(handMorph) -> droppedMorph
  #		reactToDropOf(droppedMorph, handMorph) -> newParent
  #
  dropTargetFor: (aMorph) ->
    target = @topMorphUnderPointer()
    target = target.parent  until target.wantsDropOf(aMorph)
    target
  
  grab: (aMorph) ->
    oldParent = aMorph.parent
    return null  if aMorph instanceof WorldMorph
    if !@floatDraggingSomething()

      @world.systemTestsRecorderAndPlayer.addGrabCommand()
      if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
        action = "grab"
        arr = window.world.systemTestsRecorderAndPlayer.tagsCollectedWhileRecordingTest
        if (arr.indexOf action) == -1
          arr.push action


      @world.stopEditing()
      @grabOrigin = aMorph.situation()
      aMorph.prepareToBeGrabbed? @
      @add aMorph
      # you must add the shadow
      # after the morph has been added
      # because "@add aMorph" causes
      # the morph to be painted potentially
      # for the first time.
      # The shadow needs the image of the
      # morph to make the shadow, so
      # this is why we add the shadow after
      # the morph has been added.
      # Note that Morphs can specify the look
      # (i.e. offset blur and color)
      # of their shadow (e.g. Menus have a particular one
      # so they all seem to float at a particular height)
      # but here when we grab morphs we
      # specify a particular look for the shadow.
      aMorph.addShadow(new Point(7,7),0.2)
      
      #debugger
      @changed()
      # this gives an occasion to the old parent
      # morph to adjust itself e.g. the scrollmorph
      # readjusts itself if you take some morphs
      # out of it.
      oldParent.reactToGrabOf aMorph  if oldParent and oldParent.reactToGrabOf

  floatDraggingSomething: ->
    if @children.length > 0 then true else false

  nonFloatDraggingSomething: ->
    return @nonFloatDraggedMorph?


  drop: ->
    if @floatDraggingSomething()

      @world.systemTestsRecorderAndPlayer.addDropCommand()
      if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
        action = "drop"
        arr = window.world.systemTestsRecorderAndPlayer.tagsCollectedWhileRecordingTest
        if (arr.indexOf action) == -1
          arr.push action

      morphToDrop = @children[0]
      target = @dropTargetFor(morphToDrop)
      @changed()
      target.add morphToDrop
      morphToDrop.changed()

      doRemoveShadow = true
      if (morphToDrop instanceof MenuMorph)
        console.log "dropping menu morph which with pinned status: " + morphToDrop.isPinned()
        if (morphToDrop.isPinned())
          doRemoveShadow = true
        else
          doRemoveShadow = false
      else
        doRemoveShadow = true

      if doRemoveShadow
        morphToDrop.removeShadow()
      else
        # TODO adding of the shadow
        # is not really legit because it
        # ignores the original color and opacity
        # of the shadow...
        shadow = morphToDrop.getShadow()
        if !shadow?
          morphToDrop.addShadow()

      @children = []
      @setExtent new Point()
      morphToDrop.justDropped? @
      target.reactToDropOf morphToDrop, @  if target.reactToDropOf
      @floatDragOrigin = null
  
  # HandMorph event dispatching:
  #
  #    mouse events:
  #
  #		mouseDownLeft
  #		mouseDownRight
  #		mouseClickLeft
  #		mouseClickRight
  #   mouseDoubleClick
  #		mouseEnter
  #		mouseLeave
  #		mouseEnterfloatDragging
  #		mouseLeavefloatDragging
  #		mouseMove
  #		mouseScroll
  #
  # Note that some handlers don't want the event but the
  # interesting parameters of the event. This is because
  # the testing harness only stores the interesting parameters
  # rather than a multifaceted and sometimes browser-specific
  # event object.

  destroyActiveHandleIfHandHasNotActionedIt: (actionedMorph) ->
    if @world.activeHandle.length > 0
      debugger
      if @world.activeHandle.indexOf(actionedMorph) == -1
        for eachActiveHandle in @world.activeHandle
          eachActiveHandle.destroy()
        @world.activeHandle = []

  stopEditingIfActionIsElsewhere: (actionedMorph) ->
    if @world.caret?
      # there is a caret on the screen
      # depending on what the user is clicking on,
      # we might need to close an ongoing edit
      # operation, which means deleting the
      # caret and un-selecting anything that was selected.
      # Note that we don't want to interrupt an edit
      # if the user is invoking/clicking on anything
      # inside a menu, because the invoked function
      # might do something with the selection
      # (for example doSelection takes the current selection).
      if actionedMorph isnt @world.caret.target
        # user clicked on something other than what the
        # caret is attached to
        mostRecentlyCreatedMenu = world.mostRecentlyCreatedMenu()
        if mostRecentlyCreatedMenu?
          unless mostRecentlyCreatedMenu.containedInParentsOf(actionedMorph)
            # only dismiss editing if the actionedMorph the user
            # clicked on is not part of a menu.
            @world.stopEditing()
        # there is no menu at all, in which case
        # we know there was an editing operation going
        # on that we need to stop
        else
          @world.stopEditing()

  pointerPositionFractionalInMorph: (theMorph) ->
    [relativeXPos, relativeYPos] = @pointerPositionPixelsInMorph theMorph
    fractionalXPos = relativeXPos / theMorph.bounds.width()
    fractionalYPos = relativeYPos / theMorph.bounds.height()
    return [fractionalXPos, fractionalYPos]

  pointerPositionPixelsInMorph: (theMorph) ->
    relativeXPos = @bounds.origin.x - theMorph.bounds.origin.x
    relativeYPos = @bounds.origin.y - theMorph.bounds.origin.y
    return [relativeXPos, relativeYPos]

  processMouseDown: (button, ctrlKey) ->
    @destroyTemporaries()
    @morphToGrab = null

    if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
      if button is 2 or ctrlKey
        fade('rightMouseButtonIndicator', 0, 1, 10, new Date().getTime());
      else
        fade('leftMouseButtonIndicator', 0, 1, 10, new Date().getTime());

    # check whether we are in the middle
    # of a floatDrag/drop operation
    if @floatDraggingSomething()
      @drop()
      @mouseButton = null
    else
      morph = @topMorphUnderPointer()
      @destroyActiveHandleIfHandHasNotActionedIt morph
      @stopEditingIfActionIsElsewhere morph

      @morphToGrab = morph.rootForGrab()
      if button is 2 or ctrlKey
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
  
  # touch events, see:
  # https://developer.apple.com/library/safari/documentation/appleapplications/reference/safariwebcontent/HandlingEvents/HandlingEvents.html
  # A long touch emulates a right click. This is done via
  # setting a timer 400ms after the touch which triggers
  # a right mouse click. Any touch event before then just
  # resets the timer, so one has to hold the finger in
  # position for the right click to happen.
  processTouchStart: (event) ->
    event.preventDefault()
    WorldMorph.preferencesAndSettings.isTouchDevice = true
    clearInterval @touchHoldTimeout
    if event.touches.length is 1
      # simulate mouseRightClick
      @touchHoldTimeout = setInterval(=>
        @processMouseDown 2 # button 2 is the right one
        @processMouseUp 2 # button 2 is the right one, we don't use this parameter
        event.preventDefault() # I don't think that this is needed
        clearInterval @touchHoldTimeout
      , 400)
      @processMouseMove event.touches[0].pageX, event.touches[0].pageY # update my position
      @processMouseDown 0 # button zero is the left button
  
  processTouchMove: (event) ->
    # Prevent scrolling on this element
    event.preventDefault()

    if event.touches.length is 1
      touch = event.touches[0]
      @processMouseMove touch.pageX, touch.pageY
      clearInterval @touchHoldTimeout
  
  processTouchEnd: (event) ->
    # note that the mouse down event handler
    # that is calling this method has ALREADY
    # added a mousedown command

    WorldMorph.preferencesAndSettings.isTouchDevice = true
    clearInterval @touchHoldTimeout
    @processMouseUp 0 # button zero is the left button, we don't use this parameter
  
   # note that the button param is not used,
   # but adding it for consistency...
  processMouseUp: (button) ->

    if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
      if button is 2
        fade('rightMouseButtonIndicator', 1, 0, 500, new Date().getTime());
      else
        fade('leftMouseButtonIndicator', 1, 0, 500, new Date().getTime());

    morph = @topMorphUnderPointer()
    alreadyRecordedLeftOrRightClickOnMenuItem = false
    @destroyTemporaries()
    world.freshlyCreatedMenus = []

    @nonFloatDraggedMorph = null

    if @floatDraggingSomething()
      @drop()
    else
      # let's check if the user clicked on a menu item,
      # in which case we add a special dedicated command
      # [TODO] you need to do some of this only if you
      # are recording a test, it's worth saving
      # these steps...
      #debugger
      ignored = null
      toDestructure = morph.parentThatIsA(MenuItemMorph)
      if toDestructure?
        [menuItemMorph, ignored]= toDestructure
        if menuItemMorph
          # we check whether the menuitem is actually part
          # of an activeMenu. Keep in mind you could have
          # detached a menuItem and placed it on any other
          # morph so you need to ascertain that you'll
          # find it in the activeMenu later on...
          mostRecentlyCreatedMenu = world.mostRecentlyCreatedMenu()
          if mostRecentlyCreatedMenu == menuItemMorph.parent
            labelString = menuItemMorph.labelString
            occurrenceNumber = menuItemMorph.howManySiblingsBeforeMeSuchThat (m) ->
              m.labelString == labelString
            # this method below is also going to remove
            # the mouse down/up commands that have
            # recently/just been added.
            @world.systemTestsRecorderAndPlayer.addCommandLeftOrRightClickOnMenuItem(@mouseButton, labelString, occurrenceNumber + 1)
            alreadyRecordedLeftOrRightClickOnMenuItem = true

      # TODO check if there is any other
      # possibility other than mouseButton being "left"
      # or "right". If it can only be one of those
      # that you can simplify this nested if below
      # and avoid using actionAlreadyProcessed
      if @mouseButton is "left"
        expectedClick = "mouseClickLeft"
      else
        expectedClick = "mouseClickRight"
        if @mouseButton
          if !alreadyRecordedLeftOrRightClickOnMenuItem
            # this being a right click, pop
            # up a menu as needed.
            @world.systemTestsRecorderAndPlayer.addOpenContextMenuCommand morph.uniqueIDString()

      # trigger the action
      until morph[expectedClick]
        morph = morph.parent
        if not morph?
          break
      if morph?
        if morph == @mouseDownMorph

          if expectedClick == "mouseClickLeft"
            pointerAndMorphInfo = world.getPointerAndMorphInfo()
            world.systemTestsRecorderAndPlayer.addMouseClickCommand 0, null, pointerAndMorphInfo...
          else if expectedClick == "mouseClickRight"
            pointerAndMorphInfo = world.getPointerAndMorphInfo()
            world.systemTestsRecorderAndPlayer.addMouseClickCommand 2, null, pointerAndMorphInfo...

          morph[expectedClick] @bounds.origin
          # also send doubleclick if the
          # two clicks happen on the same morph
          unless @doubleClickMorph?
            @doubleClickMorph = morph
            setTimeout (=>
              if @doubleClickMorph?
                console.log "single click"
              @doubleClickMorph = null
              return false
            ), 300
          else
            if @doubleClickMorph == morph
              @doubleClickMorph = null
              console.log "double click"
              @processDoubleClick()


      @cleanupMenuMorphs(expectedClick, morph)
    @mouseButton = null

  cleanupMenuMorphs: (expectedClick, morph)->

    world.hierarchyOfClickedMorphs = []

    # not that all the actions due to the clicked
    # morphs have been performed, now we can destroy
    # morphs queued up for destruction
    # which might include menus...
    # if we destroyed menus earlier, the
    # actions that come from the click
    # might be mangled, e.g. adding a menu
    # to a destroyed menu, etc.
    world.destroyMorphsMarkedForDestruction()

    # remove menus that have requested
    # to be removed when a click happens outside
    # of their bounds OR the bounds of their
    # children
    #if expectedClick == "mouseClickLeft"
    # collect all morphs up the hierarchy of
    # the one the user clicked on.
    # (including the one the user clicked on)
    world.hierarchyOfClickedMorphs = [morph]
    ascendingMorphs = morph
    while ascendingMorphs.parent?
      ascendingMorphs = ascendingMorphs.parent
      world.hierarchyOfClickedMorphs.push ascendingMorphs
    
    # go through the morphs that wanted a notification
    # in case there is a click outside of them or any
    # of their children morphs.
    # Check which ones are not in the hierarchy of the clicked morphs
    # and call their callback.
    console.log "morphs wanting to be notified: " + world.morphsDetectingClickOutsideMeOrAnyOfMeChildren
    console.log "hierarchy of clicked morphs: " + world.hierarchyOfClickedMorphs
    


    # here we do a shallow copy of world.morphsDetectingClickOutsideMeOrAnyOfMeChildren
    # because we might remove elements of the array while we
    # iterate on it (as we destroy menus that want to be destroyed
    # when the user clicks outside of them or their children)
    # so we need to do a shallow copy to avoid to mangle the for loop
    morphsDetectingClickOutsideMeOrAnyOfMeChildren = arrayShallowCopy world.morphsDetectingClickOutsideMeOrAnyOfMeChildren
    for eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren in morphsDetectingClickOutsideMeOrAnyOfMeChildren
      if (world.hierarchyOfClickedMorphs.indexOf eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren) < 0
        # skip the freshly created menus as otherwise we might
        # destroy them immediately
        if (world.freshlyCreatedMenus.indexOf eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren) < 0
          if eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[0]?
            eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren[eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[0]].call eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren, eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[1], eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[2], eachMorphWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[3]

  processDoubleClick: ->

    pointerAndMorphInfo = world.getPointerAndMorphInfo()
    world.systemTestsRecorderAndPlayer.addMouseDoubleClickCommand null, pointerAndMorphInfo...

    morph = @topMorphUnderPointer()
    @destroyTemporaries()
    if @floatDraggingSomething()
      @drop()
    else
      morph = morph.parent  while morph and not morph.mouseDoubleClick
      morph.mouseDoubleClick @bounds.origin  if morph
    @mouseButton = null
  
  processMouseScroll: (event) ->
    morph = @topMorphUnderPointer()
    morph = morph.parent  while morph and not morph.mouseScroll

    morph.mouseScroll (event.detail / -3) or ((if Object::hasOwnProperty.call(event,'wheelDeltaY') then event.wheelDeltaY / 120 else event.wheelDelta / 120)), event.wheelDeltaX / 120 or 0  if morph
  
  
  #
  #	drop event:
  #
  #        droppedImage
  #        droppedSVG
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
    #        droppedSVG(image, name)
    #        droppedAudio(audio, name)
    #    
    #    events to interested Morphs at the mouse pointer
    #    if none of the above content types can be determined, the file contents
    #    is dispatched as an ArrayBuffer to interested Morphs:
    #
    #    ```droppedBinary(anArrayBuffer, name)```

    files = (if event instanceof FileList then event else (event.target.files || event.dataTransfer.files))
    url = (if event.dataTransfer then event.dataTransfer.getData("URL") else null)
    txt = (if event.dataTransfer then event.dataTransfer.getData("Text/HTML") else null)
    targetDrop = @topMorphUnderPointer()
    img = new Image()

    readSVG = (aFile) ->
      pic = new Image()
      frd = new FileReader()
      target = target.parent  until target.droppedSVG
      pic.onload = ->
        target.droppedSVG pic, aFile.name
      frd = new FileReader()
      frd.onloadend = (e) ->
        pic.src = e.target.result
      frd.readAsDataURL aFile

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
      for i in [start...html.length]
        c = html[i]
        return url  if c is "\""
        url = url.concat(c)
      null
    
    if files.length
      for file in files
        if file.type.indexOf("svg") != -1 && !WorldMorph.preferencesAndSettings.rasterizeSVGs
          readSVG file
        else if file.type.indexOf("image") is 0
          readImage file
        else if file.type.indexOf("audio") is 0
          readAudio file
        else if file.type.indexOf("text") is 0
          readText file
        else
          readBinary file
    else if url
      if contains(["gif", "png", "jpg", "jpeg", "bmp"], url.slice(url.lastIndexOf(".") + 1).toLowerCase())
        target = target.parent  until target.droppedImage
        img = new Image()
        img.onload = ->
          canvas = newCanvas(new Point(img.width, img.height))
          canvas.getContext("2d").drawImage img, 0, 0
          target.droppedImage canvas
        img.src = url
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
        morph = morph.destroy()
        @temporaries.splice @temporaries.indexOf(morph), 1
  
  
  # HandMorph floatDragging optimization
  moveBy: (delta) ->
    Morph::trackChanges = false
    super delta
    Morph::trackChanges = true
    @fullChanged()

  processMouseMove: (worldX, worldY) ->
    #startProcessMouseMove = new Date().getTime()
    pos = new Point(worldX, worldY)
    delta = pos.subtract @position()
    @setPosition pos

    if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
      mousePointerIndicator = document.getElementById('mousePointerIndicator')
      mousePointerIndicator.style.display = 'block'
      posInDocument = getDocumentPositionOf(@world.worldCanvas)
      mousePointerIndicator.style.left = (posInDocument.x + worldX - (mousePointerIndicator.clientWidth/2)) + 'px'
      mousePointerIndicator.style.top = (posInDocument.y + worldY - (mousePointerIndicator.clientHeight/2)) + 'px'

    # determine the new mouse-over-list.
    # Spacial multiplexing
    # (search "multiplexing" for the other parts of
    # code where this matters)
    # There are two interpretations of what this
    # list should be:
    #   1) all morphs "pierced through" by the pointer
    #   2) all morphs parents of the topmost morph under the pointer
    # 2 is what is used in Cuis
    
    # commented-out implementation of 1):
    # mouseOverNew = @allMorphsAtPointer().reverse()
    topMorph = @topMorphUnderPointer()
    mouseOverNew = topMorph.allParentsTopToBottom()

    @determineGrabs pos, delta, topMorph, mouseOverNew
    @dispatchEventsFollowingMouseMove mouseOverNew

  determineGrabs: (pos, delta, topMorph, mouseOverNew) ->
    if (!@nonFloatDraggingSomething()) and (!@floatDraggingSomething()) and (@mouseButton is "left")
      morph = topMorph.rootForGrab()
      topMorph.mouseMove pos  if topMorph.mouseMove

      # if a morph is marked for grabbing, just grab it
      if @morphToGrab
        if @morphToGrab.isfloatDraggable
          morph = @morphToGrab
          @grab morph
        # templates create a copy of
        # themselves when floatDragged
        else if @morphToGrab.isTemplate
          morph = @morphToGrab.fullCopy()
          morph.isTemplate = false
          morph.isfloatDraggable = true
          @grab morph
          @grabOrigin = @morphToGrab.situation()
        else
          @nonFloatDraggedMorph = @morphToGrab
          @nonFloatDragPositionWithinMorphAtStart = pos.subtract @nonFloatDraggedMorph.position()


        # if the mouse has left its boundsIncludingChildren, center it
        if morph
          fb = morph.boundsIncludingChildren()
          unless fb.containsPoint(pos)
            @bounds.origin = fb.center()
            @grab morph
            @setPosition pos
    #endProcessMouseMove = new Date().getTime()
    #timeProcessMouseMove = endProcessMouseMove - startProcessMouseMove;
    #console.log('Execution time ProcessMouseMove: ' + timeProcessMouseMove);


    if @nonFloatDraggingSomething()
      console.log "nonFloatDraggedMorph: " + @nonFloatDraggedMorph
      @nonFloatDraggedMorph.nonFloatDragging?(@nonFloatDragPositionWithinMorphAtStart, pos, delta)  if @mouseButton
    
    #
    #	original, more cautious code for grabbing Morphs,
    #	retained in case of needing to fall back:
    #
    #		if (morph === this.morphToGrab) {
    #			if (morph.isfloatDraggable) {
    #				this.grab(morph);
    #			} else if (morph.isTemplate) {
    #				morph = morph.fullCopy();
    #				morph.isTemplate = false;
    #				morph.isfloatDraggable = true;
    #				this.grab(morph);
    #			}
    #		}
    #

  reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges: ->
    topMorph = @topMorphUnderPointer()
    mouseOverNew = topMorph.allParentsTopToBottom()
    @dispatchEventsFollowingMouseMove mouseOverNew

  dispatchEventsFollowingMouseMove: (mouseOverNew) ->

    @mouseOverList.forEach (old) =>
      unless contains(mouseOverNew, old)
        old.mouseLeave?()
        old.mouseLeavefloatDragging?()  if @mouseButton

    mouseOverNew.forEach (newMorph) =>
      unless contains(@mouseOverList, newMorph)
        newMorph.mouseEnter?()
        newMorph.mouseEnterfloatDragging?()  if @mouseButton

      # autoScrolling support:
      if @floatDraggingSomething()
          if newMorph instanceof ScrollFrameMorph
              if !newMorph.bounds.insetBy(
                WorldMorph.preferencesAndSettings.scrollBarSize * 3
                ).containsPoint(@bounds.origin)
                  newMorph.startAutoScrolling();

    @mouseOverList = mouseOverNew
