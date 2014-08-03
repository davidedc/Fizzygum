# HandMorph ///////////////////////////////////////////////////////////

# The mouse cursor. Note that it's not a child of the WorldMorph, this Morph
# is never added to any other morph. [TODO] Find out why and write explanation.

class HandMorph extends Morph

  world: null
  mouseButton: null
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
    if @world isnt null
      b = @boundsIncludingChildren()
      @world.broken.push @boundsIncludingChildren().spread()  unless b.extent().eq(new Point())
  
  
  # HandMorph navigation:
  morphAtPointer: ->
    result = @world.topMorphSuchThat (m) =>
      m.visibleBounds().containsPoint(@bounds.origin) and
        !m.isMinimised and m.isVisible and (m.noticesTransparentClick or
        (not m.isTransparentAt(@bounds.origin))) and (m not instanceof ShadowMorph)
    if result?
      return result
    else
      return @world
  
  #
  #    alternative -  more elegant and possibly more
  #	performant - solution for morphAtPointer.
  #	Has some issues, commented out for now
  #
  #HandMorph.prototype.morphAtPointer = function () {
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
    target = @morphAtPointer()
    target = target.parent  until target.wantsDropOf(aMorph)
    target
  
  grab: (aMorph) ->
    oldParent = aMorph.parent
    return null  if aMorph instanceof WorldMorph
    if !@children.length
      @world.stopEditing()
      @grabOrigin = aMorph.situation()
      aMorph.addShadow()
      aMorph.prepareToBeGrabbed @  if aMorph.prepareToBeGrabbed
      @add aMorph
      @changed()
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

  processMouseDown: (button, ctrlKey) ->
    @world.systemTestsRecorderAndPlayer.addMouseDownEvent(button, ctrlKey)

    @destroyTemporaries()
    @morphToGrab = null
    if @children.length
      @drop()
      @mouseButton = null
    else
      morph = @morphAtPointer()
      if @world.activeMenu
        unless contains(morph.allParents(), @world.activeMenu)
          # if there is a menu open and the user clicked on
          # something that is not part of the menu then
          # destroy the menu 
          @world.activeMenu.destroy()
        else
          clearInterval @touchHoldTimeout
      if @world.activeHandle
        if morph isnt @world.activeHandle
          @world.activeHandle.destroy()    
      if @world.caret
        # there is a caret on the screen
        # depending on what the user is clicking on,
        # we might need to close an ongoing edit
        # operation, which means deleting the
        # caret and un-selecting anything that was selected.
        # Note that we don't want to interrupt an edit
        # if the user is invoking/clicking on anything
        # inside a menu, because the invoked function
        # might do something with the selection
        # (for example doIt takes the current selection).
        if morph isnt @world.caret.target
          # user clicked on something other than what the
          # caret is attached to
          unless contains(morph.allParents(), @world.activeMenu)
            # only dismiss editing if the morph the user
            # clicked on is not part of a menu.
            @world.stopEditing()  
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
    WorldMorph.preferencesAndSettings.isTouchDevice = true
    clearInterval @touchHoldTimeout
    @processMouseUp 0 # button zero is the left button, we don't use this parameter
  
   # note that the button param is not used,
   # but adding it for consistency...
   processMouseUp: (button) ->
    @world.systemTestsRecorderAndPlayer.addMouseUpEvent()

    morph = @morphAtPointer()
    @destroyTemporaries()
    if @children.length
      @drop()
    else
      if @mouseButton is "left"
        expectedClick = "mouseClickLeft"
      else
        expectedClick = "mouseClickRight"
        if @mouseButton
          context = morph
          contextMenu = context.contextMenu()
          while (not contextMenu) and context.parent
            context = context.parent
            contextMenu = context.contextMenu()
          contextMenu.popUpAtHand @world  if contextMenu
      morph = morph.parent  until morph[expectedClick]
      morph[expectedClick] @bounds.origin
    @mouseButton = null

  processDoubleClick: ->
    morph = @morphAtPointer()
    @destroyTemporaries()
    if @children.length isnt 0
      @drop()
    else
      morph = morph.parent  while morph and not morph.mouseDoubleClick
      morph.mouseDoubleClick @bounds.origin  if morph
    @mouseButton = null
  
  processMouseScroll: (event) ->
    morph = @morphAtPointer()
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
    targetDrop = @morphAtPointer()
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
      #
      frd = new FileReader()
      frd.onloadend = (e) ->
        pic.src = e.target.result
      #
      frd.readAsDataURL aFile
    #
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
        morph.destroy()
        @temporaries.splice @temporaries.indexOf(morph), 1
  
  
  # HandMorph dragging optimization
  moveBy: (delta) ->
    Morph::trackChanges = false
    super delta
    Morph::trackChanges = true
    @fullChanged()

  processMouseMove: (pageX, pageY) ->
    @world.systemTestsRecorderAndPlayer.addMouseMoveEvent(pageX, pageY)
    
    #startProcessMouseMove = new Date().getTime()
    posInDocument = getDocumentPositionOf(@world.worldCanvas)
    pos = new Point(pageX - posInDocument.x, pageY - posInDocument.y)
    @setPosition pos
    #
    # determine the new mouse-over-list:
    # mouseOverNew = this.allMorphsAtPointer();
    mouseOverNew = @morphAtPointer().allParents()
    if (!@children.length) and (@mouseButton is "left")
      topMorph = @morphAtPointer()
      morph = topMorph.rootForGrab()
      topMorph.mouseMove pos  if topMorph.mouseMove
      #
      # if a morph is marked for grabbing, just grab it
      if @morphToGrab
        if @morphToGrab.isDraggable
          morph = @morphToGrab
          @grab morph
        else if @morphToGrab.isTemplate
          morph = @morphToGrab.fullCopy()
          morph.isTemplate = false
          morph.isDraggable = true
          @grab morph
          @grabOrigin = @morphToGrab.situation()
        #
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
    #
    mouseOverNew.forEach (newMorph) =>
      unless contains(@mouseOverList, newMorph)
        newMorph.mouseEnter()  if newMorph.mouseEnter
        newMorph.mouseEnterDragging()  if newMorph.mouseEnterDragging and @mouseButton
      #
      # autoScrolling support:
      if @children.length
          if newMorph instanceof ScrollFrameMorph
              if !newMorph.bounds.insetBy(
                WorldMorph.preferencesAndSettings.scrollBarSize * 3
                ).containsPoint(@bounds.origin)
                  newMorph.startAutoScrolling();
    #
    @mouseOverList = mouseOverNew
