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
        !m.isMinimised and m.isVisible and (m.noticesTransparentClick or
        (not m.isTransparentAt(@bounds.origin))) and (m not instanceof ShadowMorph)
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

  leftOrRightClickOnMenuItemWithText: (whichMouseButtonPressed, textLabelOfClickedItem, textLabelOccurrenceNumber) ->
    itemToTrigger = @world.activeMenu.nthChildSuchThat textLabelOccurrenceNumber, (m) ->
      m.labelString == textLabelOfClickedItem

    # these three are checks and actions that normally
    # would happen on MouseDown event, but we
    # removed that event as we collapsed the down and up
    # into this colasesced higher-level event,
    # but we still need to make these checks and actions
    @destroyActiveMenuIfHandHasNotActionedIt itemToTrigger
    @destroyActiveHandleIfHandHasNotActionedIt itemToTrigger
    @stopEditingIfActionIsElsewhere itemToTrigger

    if whichMouseButtonPressed == "left"
      itemToTrigger.mouseClickLeft()
    else if whichMouseButtonPressed == "right"
      @openContextMenuAtPointer itemToTrigger.children[0]


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
    # into this colasesced higher-level event,
    # but we still need to make these checks and actions
    @destroyActiveMenuIfHandHasNotActionedIt morphTheMenuIsAbout
    @destroyActiveHandleIfHandHasNotActionedIt morphTheMenuIsAbout
    @stopEditingIfActionIsElsewhere morphTheMenuIsAbout

    contextMenu = morphTheMenuIsAbout.contextMenu()
    while (not contextMenu) and morphTheMenuIsAbout.parent
      morphTheMenuIsAbout = morphTheMenuIsAbout.parent
      contextMenu = morphTheMenuIsAbout.contextMenu()

    if contextMenu 
      contextMenu.popUpAtHand() 

  #
  #    alternative -  more elegant and possibly more
  #	performant - solution for topMorphUnderPointer.
  #	Has some issues, commented out for now
  #
  #HandMorph.prototype.topMorphUnderPointer = function () {
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
  dropTargetFor: (aMorph) ->
    target = @topMorphUnderPointer()
    target = target.parent  until target.wantsDropOf(aMorph)
    target
  
  grab: (aMorph) ->
    oldParent = aMorph.parent
    return null  if aMorph instanceof WorldMorph
    if !@children.length
      @world.stopEditing()
      @grabOrigin = aMorph.situation()
      aMorph.prepareToBeGrabbed @  if aMorph.prepareToBeGrabbed
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
      #aMorph.addShadow()
      shadow = aMorph.addShadow()
      
      #debugger
      @changed()
      # this gives an occasion to the old parent
      # morph to adjust itself e.g. the scrollmorph
      # readjusts itself if you take some morphs
      # out of it.
      oldParent.reactToGrabOf aMorph  if oldParent and oldParent.reactToGrabOf
  
  drop: ->
    if @children.length
      morphToDrop = @children[0]
      target = @dropTargetFor(morphToDrop)
      @changed()
      target.add morphToDrop
      morphToDrop.changed()
      morphToDrop.removeShadow()
      @children = []
      @setExtent new Point()
      morphToDrop.justDropped @  if morphToDrop.justDropped
      target.reactToDropOf morphToDrop, @  if target.reactToDropOf
      @dragOrigin = null
  
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
  #		mouseEnterDragging
  #		mouseLeaveDragging
  #		mouseMove
  #		mouseScroll
  #
  # Note that some handlers don't want the event but the
  # interesting parameters of the event. This is because
  # the testing harness only stores the interesting parameters
  # rather than a multifaceted and sometimes browser-specific
  # event object.

  destroyActiveHandleIfHandHasNotActionedIt: (actionedMorph) ->
    if @world.activeHandle?
      if actionedMorph isnt @world.activeHandle
        @world.activeHandle = @world.activeHandle.destroy()    

  destroyActiveMenuIfHandHasNotActionedIt: (actionedMorph) ->
    if @world.activeMenu?
      unless @world.activeMenu.containedInParentsOf(actionedMorph)
        # if there is a menu open and the user clicked on
        # something that is not part of the menu then
        # destroy the menu 
        @world.activeMenu = @world.activeMenu.destroy()
      else
        clearInterval @touchHoldTimeout

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
        if @world.activeMenu?
          unless @world.activeMenu.containedInParentsOf(actionedMorph)
            # only dismiss editing if the actionedMorph the user
            # clicked on is not part of a menu.
            @world.stopEditing()
        # there is no menu at all, in which case
        # we know there was an editing operation going
        # on that we need to stop
        else
          @world.stopEditing()

  processMouseDown: (button, ctrlKey) ->
    @destroyTemporaries()
    @morphToGrab = null
    # check whether we are in the middle
    # of a drag/drop operation
    if @children.length
      @drop()
      @mouseButton = null
    else
      morph = @topMorphUnderPointer()
      @destroyActiveMenuIfHandHasNotActionedIt morph
      @destroyActiveHandleIfHandHasNotActionedIt morph
      @stopEditingIfActionIsElsewhere morph

      @morphToGrab = morph.rootForGrab()  unless morph.mouseMove
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
    morph = @topMorphUnderPointer()
    alreadyRecordedLeftOrRightClickOnMenuItem = false
    @destroyTemporaries()
    if @children.length
      @drop()
    else
      # let's check if the user clicked on a menu item,
      # in which case we add a special dedicated command
      # [TODO] you need to do some of this only if you
      # are recording a test, it's worth saving
      # these steps...
      menuItemMorph = morph.parentThatIsA(MenuItemMorph)
      if menuItemMorph
        # we check whether the menuitem is actually part
        # of an activeMenu. Keep in mind you could have
        # detached a menuItem and placed it on any other
        # morph so you need to ascertain that you'll
        # find it in the activeMenu later on...
        if @world.activeMenu == menuItemMorph.parent
          labelString = menuItemMorph.labelString
          morphSpawningTheMenu = menuItemMorph.parent.parent
          occurrenceNumber = menuItemMorph.howManySiblingsBeforeMeSuchThat (m) ->
            m.labelString == labelString
          # this method below is also going to remove
          # the mouse down/up commands that have
          # recently/jsut been added.
          @world.systemTestsRecorderAndPlayer.addCommandLeftOrRightClickOnMenuItem(@mouseButton, labelString, occurrenceNumber + 1)
          alreadyRecordedLeftOrRightClickOnMenuItem = true
      if @mouseButton is "left"
        expectedClick = "mouseClickLeft"
      else
        expectedClick = "mouseClickRight"
        if @mouseButton
          if !alreadyRecordedLeftOrRightClickOnMenuItem
            # this being a right click, pop
            # up a menu as needed.
            @world.systemTestsRecorderAndPlayer.addOpenContextMenuCommand morph.uniqueIDString()
          @openContextMenuAtPointer morph
      until morph[expectedClick]
        morph = morph.parent
        if not morph?
          break
      if morph?
        if morph == @mouseDownMorph
          morph[expectedClick] @bounds.origin
    @mouseButton = null

  processDoubleClick: ->
    morph = @topMorphUnderPointer()
    @destroyTemporaries()
    if @children.length isnt 0
      @drop()
    else
      morph = morph.parent  while morph and not morph.mouseDoubleClick
      morph.mouseDoubleClick @bounds.origin  if morph
    @mouseButton = null
  
  processMouseScroll: (event) ->
    morph = @topMorphUnderPointer()
    morph = morph.parent  while morph and not morph.mouseScroll

    morph.mouseScroll (event.detail / -3) or ((if Object.prototype.hasOwnProperty.call(event,'wheelDeltaY') then event.wheelDeltaY / 120 else event.wheelDelta / 120)), event.wheelDeltaX / 120 or 0  if morph
  
  
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
  
  
  # HandMorph dragging optimization
  moveBy: (delta) ->
    Morph::trackChanges = false
    super delta
    Morph::trackChanges = true
    @fullChanged()

  processMouseMove: (pageX, pageY) ->
    #startProcessMouseMove = new Date().getTime()
    posInDocument = getDocumentPositionOf(@world.worldCanvas)
    pos = new Point(pageX - posInDocument.x, pageY - posInDocument.y)
    @setPosition pos

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
    mouseOverNew = @topMorphUnderPointer().allParentsTopToBottom()

    if (!@children.length) and (@mouseButton is "left")
      topMorph = @topMorphUnderPointer()
      morph = topMorph.rootForGrab()
      topMorph.mouseMove pos  if topMorph.mouseMove

      # if a morph is marked for grabbing, just grab it
      if @morphToGrab
        if @morphToGrab.isDraggable
          morph = @morphToGrab
          @grab morph
        # templates create a copy of
        # themselves when dragged
        else if @morphToGrab.isTemplate
          morph = @morphToGrab.fullCopy()
          morph.isTemplate = false
          morph.isDraggable = true
          @grab morph
          @grabOrigin = @morphToGrab.situation()

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
    
    #
    #	original, more cautious code for grabbing Morphs,
    #	retained in case of needing to fall back:
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
    @mouseOverList.forEach (old) =>
      unless contains(mouseOverNew, old)
        old.mouseLeave()  if old.mouseLeave
        old.mouseLeaveDragging()  if old.mouseLeaveDragging and @mouseButton

    mouseOverNew.forEach (newMorph) =>
      unless contains(@mouseOverList, newMorph)
        newMorph.mouseEnter()  if newMorph.mouseEnter
        newMorph.mouseEnterDragging()  if newMorph.mouseEnterDragging and @mouseButton

      # autoScrolling support:
      if @children.length
          if newMorph instanceof ScrollFrameMorph
              if !newMorph.bounds.insetBy(
                WorldMorph.preferencesAndSettings.scrollBarSize * 3
                ).containsPoint(@bounds.origin)
                  newMorph.startAutoScrolling();

    @mouseOverList = mouseOverNew
