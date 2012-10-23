# HandMorph ///////////////////////////////////////////////////////////

# The mouse cursor. Note that it's not a child of the WorldMorph, this Morph
# is never added to any other morph. [TODO] Find out why and write explanation.

class HandMorph extends Morph

  world: null
  mouseButton: null
  mouseOverList: []
  mouseDownMorph: null
  morphToGrab: null
  grabOrigin: null
  temporaries: []
  touchHoldTimeout: null

  constructor: (@world) ->
    super()
    @bounds = new Rectangle()
  
  changed: ->
    b = undefined
    if @world isnt null
      b = @fullBounds()
      @world.broken.push @fullBounds().spread()  unless b.extent().eq(new Point())
  
  
  # HandMorph navigation:
  morphAtPointer: ->
    morphs = @world.allChildren().slice(0).reverse()
    result = null
    morphs.forEach (m) =>
      result = m  if m.visibleBounds().containsPoint(@bounds.origin) and result is null and m.isVisible and (m.noticesTransparentClick or (not m.isTransparentAt(@bounds.origin))) and (m not instanceof ShadowMorph)
    #
    return result  if result isnt null
    @world
  
  #
  #    alternative -  more elegant and possibly more
  #	performant - solution for morphAtPointer.
  #	Has some issues, commented out for now
  #
  #HandMorph.prototype.morphAtPointer = function () {
  #	var myself = this;
  #	return this.world.topMorphSuchThat(function (m) {
  #		return m.visibleBounds().containsPoint(myself.bounds.origin) &&
  #			m.isVisible &&
  #			(m.noticesTransparentClick ||
  #				(! m.isTransparentAt(myself.bounds.origin))) &&
  #			(! (m instanceof ShadowMorph));
  #	});
  #};
  #
  allMorphsAtPointer: ->
    morphs = @world.allChildren()
    morphs.filter (m) =>
      m.isVisible and m.visibleBounds().containsPoint(@bounds.origin)
  
  
  
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
    if @children.length is 0
      @world.stopEditing()
      @grabOrigin = aMorph.situation()
      aMorph.addShadow()
      aMorph.prepareToBeGrabbed @  if aMorph.prepareToBeGrabbed
      @add aMorph
      @changed()
      oldParent.reactToGrabOf aMorph  if oldParent and oldParent.reactToGrabOf
  
  drop: ->
    target = undefined
    morphToDrop = undefined
    if @children.length isnt 0
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
  #		mouseEnter
  #		mouseLeave
  #		mouseEnterDragging
  #		mouseLeaveDragging
  #		mouseMove
  #		mouseScroll
  #
  processMouseDown: (event) ->
    morph = undefined
    expectedClick = undefined
    actualClick = undefined
    @destroyTemporaries()
    @morphToGrab = null
    if @children.length isnt 0
      @drop()
      @mouseButton = null
    else
      morph = @morphAtPointer()
      if @world.activeMenu
        unless contains(morph.allParents(), @world.activeMenu)
          @world.activeMenu.destroy()
        else
          clearInterval @touchHoldTimeout
      @world.activeHandle.destroy()  if morph isnt @world.activeHandle  if @world.activeHandle
      @world.stopEditing()  if morph isnt @world.cursor.target  if @world.cursor
      @morphToGrab = morph.rootForGrab()  unless morph.mouseMove
      if event.button is 2 or event.ctrlKey
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
  
  processTouchStart: (event) ->
    clearInterval @touchHoldTimeout
    if event.touches.length is 1
      # simulate mouseRightClick
      @touchHoldTimeout = setInterval(=>
        @processMouseDown button: 2
        @processMouseUp button: 2
        event.preventDefault()
        clearInterval @touchHoldTimeout
      , 400)
      @processMouseMove event.touches[0] # update my position
      @processMouseDown button: 0
      event.preventDefault()
  
  processTouchMove: (event) ->
    if event.touches.length is 1
      touch = event.touches[0]
      @processMouseMove touch
      clearInterval @touchHoldTimeout
  
  processTouchEnd: (event) ->
    clearInterval @touchHoldTimeout
    @processMouseUp button: 0
  
  processMouseUp: ->
    morph = @morphAtPointer()
    context = undefined
    contextMenu = undefined
    expectedClick = undefined
    @destroyTemporaries()
    if @children.length isnt 0
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
  
  processMouseScroll: (event) ->
    morph = @morphAtPointer()
    morph = morph.parent  while morph and not morph.mouseScroll
    morph.mouseScroll (event.detail / -3) or ((if event.hasOwnProperty("wheelDeltaY") then event.wheelDeltaY / 120 else event.wheelDelta / 120)), event.wheelDeltaX / 120 or 0  if morph
  
  
  #
  #	drop event:
  #
  #        droppedImage
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
    #        droppedAudio(audio, name)
    #    
    #    events to interested Morphs at the mouse pointer
    #
    files = (if event instanceof FileList then event else (event.target.files || event.dataTransfer.files))
    file = undefined
    txt = (if event.dataTransfer then event.dataTransfer.getData("Text/HTML") else null)
    src = undefined
    targetDrop = @morphAtPointer()
    img = new Image()
    canvas = undefined
    i = undefined
    #
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
    
    parseImgURL = (html) ->
      url = ""
      i = undefined
      c = undefined
      start = html.indexOf("<img src=\"")
      return null  if start is -1
      start += 10
      i = start
      while i < html.length
        c = html[i]
        return url  if c is "\""
        url = url.concat(c)
        i += 1
      null
    
    if files.length > 0
      i = 0
      while i < files.length
        file = files[i]
        if file.type.indexOf("image") is 0
          readImage file
        else if file.type.indexOf("audio") is 0
          readAudio file
        else readText file  if file.type.indexOf("text") is 0
        i += 1
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
    @temporaries.forEach (morph) ->
      morph.destroy()
    @temporaries = []
  
  
  # HandMorph dragging optimization
  moveBy: (delta) ->
    Morph::trackChanges = false
    super delta
    Morph::trackChanges = true
    @fullChanged()
  
  processMouseMove: (event) ->
    pos = undefined
    posInDocument = getDocumentPositionOf(@world.worldCanvas)
    mouseOverNew = undefined
    morph = undefined
    topMorph = undefined
    fb = undefined
    pos = new Point(event.pageX - posInDocument.x, event.pageY - posInDocument.y)
    @setPosition pos
    #
    # determine the new mouse-over-list:
    # mouseOverNew = this.allMorphsAtPointer();
    mouseOverNew = @morphAtPointer().allParents()
    if (@children.length is 0) and (@mouseButton is "left")
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
        # if the mouse has left its fullBounds, center it
        fb = morph.fullBounds()
        unless fb.containsPoint(pos)
          @bounds.origin = fb.center()
          @grab morph
          @setPosition pos
    
    #
    #	original, more cautious code for grabbing Morphs,
    #	retained in case of needing	to fall back:
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
    @mouseOverList.forEach (old) ->
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
      if @children.length > 0
          if newMorph instanceof ScrollFrameMorph
              if !newMorph.bounds.insetBy( WorldMorph.MorphicPreferences.scrollBarSize * 3).containsPoint(@bounds.origin)
                  newMorph.startAutoScrolling();
    #
    @mouseOverList = mouseOverNew
