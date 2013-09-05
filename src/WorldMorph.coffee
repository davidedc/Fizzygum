# WorldMorph //////////////////////////////////////////////////////////

# these comments below needed to figure our dependencies between classes
# REQUIRES globalFunctions
# REQUIRES globalSettings

# I represent the <canvas> element
class WorldMorph extends FrameMorph

  # these variables shouldn't be static to the WorldMorph, because
  # in pure theory you could have multiple worlds in the same
  # page with different settings
  # (but anyways, it was global before, so it's not any worse than before)
  @MorphicPreferences: standardSettings
  @currentTime: null
  @showRedraws: false
  systemTestsRecorderAndPlayer: null

  constructor: (aCanvas, fillPage) ->
    super()
    @color = new Color(205, 205, 205) # (130, 130, 130)
    @alpha = 1
    @bounds = new Rectangle(0, 0, aCanvas.width, aCanvas.height)
    @updateRendering()
    @isVisible = true
    @isDraggable = false
    @currentKey = null # currently pressed key code
    @worldCanvas = aCanvas

    # additional properties:
    @stamp = Date.now() # reference in multi-world setups
    @useFillPage = fillPage
    @useFillPage = true  if @useFillPage is `undefined`
    @isDevMode = false
    @broken = []
    @hand = new HandMorph(@)
    @keyboardReceiver = null
    @lastEditedText = null
    @caret = null
    @activeMenu = null
    @activeHandle = null
    @virtualKeyboard = null
    @initEventListeners()
    @systemTestsRecorderAndPlayer = new SystemTestsRecorderAndPlayer(@, @hand)
  
  # World Morph display:
  brokenFor: (aMorph) ->
    # private
    fb = aMorph.boundsIncludingChildren()
    @broken.filter (rect) ->
      rect.intersects fb
  
  
  # all fullDraws result into actual blittings of images done
  # by the blit function.
  # The blit function is defined in Morph and is not overriden by
  # any morph.
  recursivelyBlit: (aCanvas, aRect) ->
    # invokes the Morph's recursivelyBlit, which has only two implementations:
    # the default one by Morph which just invokes the blit of all children
    # and the interesting one in FrameMorph which 
    super aCanvas, aRect
    # the mouse cursor is always drawn on top of everything
    # and it'd not attached to the WorldMorph.
    @hand.recursivelyBlit aCanvas, aRect
  
  updateBroken: ->
    #console.log "number of broken rectangles: " + @broken.length
    @broken.forEach (rect) =>
      @recursivelyBlit @worldCanvas, rect  if rect.isNotEmpty()
    @broken = []
  
  doOneCycle: ->
    WorldMorph.currentTime = Date.now();
    @runChildrensStepFunction()
    @updateBroken()
  
  fillPage: ->
    pos = getDocumentPositionOf(@worldCanvas)
    clientHeight = window.innerHeight
    clientWidth = window.innerWidth
    if pos.x > 0
      @worldCanvas.style.position = "absolute"
      @worldCanvas.style.left = "0px"
      pos.x = 0
    if pos.y > 0
      @worldCanvas.style.position = "absolute"
      @worldCanvas.style.top = "0px"
      pos.y = 0
    # scrolled down b/c of viewport scaling
    clientHeight = document.documentElement.clientHeight  if document.body.scrollTop
    # scrolled left b/c of viewport scaling
    clientWidth = document.documentElement.clientWidth  if document.body.scrollLeft
    if @worldCanvas.width isnt clientWidth
      @worldCanvas.width = clientWidth
      @setWidth clientWidth
    if @worldCanvas.height isnt clientHeight
      @worldCanvas.height = clientHeight
      @setHeight clientHeight
    @children.forEach (child) =>
      child.reactToWorldResize @bounds.copy()  if child.reactToWorldResize
  
  
  
  # WorldMorph global pixel access:
  getGlobalPixelColor: (point) ->
    
    #
    #	answer the color at the given point.
    #
    #	Note: for some strange reason this method works fine if the page is
    #	opened via HTTP, but *not*, if it is opened from a local uri
    #	(e.g. from a directory), in which case it's always null.
    #
    #	This behavior is consistent throughout several browsers. I have no
    #	clue what's behind this, apparently the imageData attribute of
    #	canvas context only gets filled with meaningful data if transferred
    #	via HTTP ???
    #
    #	This is somewhat of a showstopper for color detection in a planned
    #	offline version of Snap.
    #
    #	The issue has also been discussed at: (join lines before pasting)
    #	http://stackoverflow.com/questions/4069400/
    #	canvas-getimagedata-doesnt-work-when-running-locally-on-windows-
    #	security-excep
    #
    #	The suggestion solution appears to work, since the settings are
    #	applied globally.
    #
    dta = @worldCanvas.getContext("2d").getImageData(point.x, point.y, 1, 1).data
    new Color(dta[0], dta[1], dta[2])
  
  
  # WorldMorph events:
  initVirtualKeyboard: ->
    if @virtualKeyboard
      document.body.removeChild @virtualKeyboard
      @virtualKeyboard = null
    unless (WorldMorph.MorphicPreferences.isTouchDevice and WorldMorph.MorphicPreferences.useVirtualKeyboard)
      return
    @virtualKeyboard = document.createElement("input")
    @virtualKeyboard.type = "text"
    @virtualKeyboard.style.color = "transparent"
    @virtualKeyboard.style.backgroundColor = "transparent"
    @virtualKeyboard.style.border = "none"
    @virtualKeyboard.style.outline = "none"
    @virtualKeyboard.style.position = "absolute"
    @virtualKeyboard.style.top = "0px"
    @virtualKeyboard.style.left = "0px"
    @virtualKeyboard.style.width = "0px"
    @virtualKeyboard.style.height = "0px"
    @virtualKeyboard.autocapitalize = "none" # iOS specific
    document.body.appendChild @virtualKeyboard

    @virtualKeyboard.addEventListener "keydown", ((event) =>
      # remember the keyCode in the world's currentKey property
      @currentKey = event.keyCode

      @keyboardReceiver.processKeyDown event  if @keyboardReceiver
      #
      # supress backspace override
      if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
        event.preventDefault()  
      #
      # supress tab override and make sure tab gets
      # received by all browsers
      if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
        @keyboardReceiver.processKeyPress event  if @keyboardReceiver
        event.preventDefault()
    ), false
    @virtualKeyboard.addEventListener "keyup", ((event) =>
      # flush the world's currentKey property
      @currentKey = null
      #
      # dispatch to keyboard receiver
      if @keyboardReceiver
        if @keyboardReceiver.processKeyUp
          @keyboardReceiver.processKeyUp event  
      event.preventDefault()
    ), false
    @virtualKeyboard.addEventListener "keypress", ((event) =>
      @keyboardReceiver.processKeyPress event  if @keyboardReceiver
      event.preventDefault()
    ), false
  
  initEventListeners: ->
    canvas = @worldCanvas
    if @useFillPage
      @fillPage()
    else
      @changed()
    canvas.addEventListener "dblclick", ((event) =>
      event.preventDefault()
      @hand.processDoubleClick event
    ), false
    canvas.addEventListener "mousedown", ((event) =>
      @hand.processMouseDown event.button, event.ctrlKey
    ), false
    canvas.addEventListener "touchstart", ((event) =>
      @hand.processTouchStart event
    ), false
    canvas.addEventListener "mouseup", ((event) =>
      event.preventDefault()
      @hand.processMouseUp event
    ), false
    canvas.addEventListener "touchend", ((event) =>
      @hand.processTouchEnd event
    ), false
    canvas.addEventListener "mousemove", ((event) =>
      @hand.processMouseMove  event.pageX, event.pageY
    ), false
    canvas.addEventListener "touchmove", ((event) =>
      @hand.processTouchMove event
    ), false
    canvas.addEventListener "contextmenu", ((event) ->
      # suppress context menu for Mac-Firefox
      event.preventDefault()
    ), false
    canvas.addEventListener "keydown", ((event) =>
      # remember the keyCode in the world's currentKey property
      @currentKey = event.keyCode
      @keyboardReceiver.processKeyDown event  if @keyboardReceiver
      #
      # supress backspace override
      if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
        event.preventDefault()
      #
      # supress tab override and make sure tab gets
      # received by all browsers
      if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
        @keyboardReceiver.processKeyPress event  if @keyboardReceiver
        event.preventDefault()
    ), false
    #
    canvas.addEventListener "keyup", ((event) =>  
      # flush the world's currentKey property
      @currentKey = null
      #
      # dispatch to keyboard receiver
      if @keyboardReceiver
        if @keyboardReceiver.processKeyUp
          @keyboardReceiver.processKeyUp event    
      event.preventDefault()
    ), false
    canvas.addEventListener "keypress", ((event) =>
      @keyboardReceiver.processKeyPress event  if @keyboardReceiver
      event.preventDefault()
    ), false
    # Safari, Chrome
    canvas.addEventListener "mousewheel", ((event) =>
      @hand.processMouseScroll event
      event.preventDefault()
    ), false
    # Firefox
    canvas.addEventListener "DOMMouseScroll", ((event) =>
      @hand.processMouseScroll event
      event.preventDefault()
    ), false

    # snippets of clipboard-handling code taken from
    # http://codebits.glennjones.net/editing/setclipboarddata.htm
    # Note that this works only in Chrome. Firefox and Safari need a piece of
    # text to be selected in order to even trigger the copy event. Chrome does
    # enable clipboard access instead even if nothing is selected.
    # There are a couple of solutions to this - one is to keep a hidden textfield that
    # handles all copy/paste operations.
    # Another one is to not use a clipboard, but rather an internal string as
    # local memory. So the OS clipboard wouldn't be used, but at least there would
    # be some copy/paste working. Also one would need to intercept the copy/paste
    # key combinations manually instead of from the copy/paste events.
    document.body.addEventListener "copy", ((event) =>
      if @caret
        selectedText = @caret.target.selection()
        if event.clipboardData
          event.preventDefault()
          setStatus = event.clipboardData.setData("text/plain", selectedText)

        if window.clipboardData
          event.returnValue = false
          setStatus = window.clipboardData.setData "Text", selectedText

    ), false

    document.body.addEventListener "paste", ((event) =>
      if @caret
        if event.clipboardData
          # Look for access to data if types array is missing
          text = event.clipboardData.getData("text/plain")
          #url = event.clipboardData.getData("text/uri-list")
          #html = event.clipboardData.getData("text/html")
          #custom = event.clipboardData.getData("text/xcustom")
        # IE event is attached to the window object
        if window.clipboardData
          # The schema is fixed
          text = window.clipboardData.getData("Text")
          #url = window.clipboardData.getData("URL")
        
        # Needs a few msec to excute paste
        window.setTimeout ( => (@caret.insert text)), 50, true
    ), false

    #console.log "binding with mousetrap"
    Mousetrap.bind ["command+k", "ctrl+k"], (e) =>
      @systemTestsRecorderAndPlayer.takeScreenshot()
      false

    window.addEventListener "dragover", ((event) ->
      event.preventDefault()
    ), false
    window.addEventListener "drop", ((event) =>
      @hand.processDrop event
      event.preventDefault()
    ), false
    window.addEventListener "resize", (=>
      @fillPage()  if @useFillPage
    ), false
    window.onbeforeunload = (evt) ->
      e = evt or window.event
      msg = "Are you sure you want to leave?"
      #
      # For IE and Firefox
      e.returnValue = msg  if e
      #
      # For Safari / chrome
      msg
  
  mouseDownLeft: ->
    noOperation
  
  mouseClickLeft: ->
    noOperation
  
  mouseDownRight: ->
    noOperation
  
  mouseClickRight: ->
    noOperation
  
  wantsDropOf: ->
    # allow handle drops if any drops are allowed
    @acceptsDrops
  
  droppedImage: ->
    null

  droppedSVG: ->
    null  

  # WorldMorph text field tabbing:
  nextTab: (editField) ->
    next = @nextEntryField(editField)
    if next
      editField.clearSelection()
      next.selectAll()
      next.edit()
  
  previousTab: (editField) ->
    prev = @previousEntryField(editField)
    if prev
      editField.clearSelection()
      prev.selectAll()
      prev.edit()
  
  testsList: () ->
    # Check which objects have the right name start
    console.log Object.keys(window)
    (Object.keys(window)).filter (i) ->
      console.log i.indexOf("SystemTest_")
      i.indexOf("SystemTest_") == 0

  runSystemTests: () ->
    console.log @testsList()
    for i in @testsList()
      console.log window[i]
      @systemTestsRecorderAndPlayer.eventQueue = (window[i]).testData
      # the Zombie kernel safari pop-up is painted weird, needs a refresh
      # for some unknown reason
      @changed()
      # start from clean slate
      @destroyAll()
      @systemTestsRecorderAndPlayer.startTestPlaying()

  # WorldMorph menu:
  contextMenu: ->
    if @isDevMode
      menu = new MenuMorph(
        @, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    else
      menu = new MenuMorph(@, "Morphic")
    if @isDevMode
      menu.addItem "demo...", "userCreateMorph", "sample morphs"
      menu.addLine()
      menu.addItem "hide all...", "hideAll"
      menu.addItem "delete all...", "destroyAll"
      menu.addItem "show all...", "showAllHiddens"
      menu.addItem "move all inside...", "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
      menu.addItem "inspect...", "inspect", "open a window on\nall properties"
      menu.addLine()
      menu.addItem "restore display", "changed", "redraw the\nscreen once"
      menu.addItem "fill page...", "fillPage", "let the World automatically\nadjust to browser resizings"
      if useBlurredShadows
        menu.addItem "sharp shadows...", "toggleBlurredShadows", "sharp drop shadows\nuse for old browsers"
      else
        menu.addItem "blurred shadows...", "toggleBlurredShadows", "blurry shades,\n use for new browsers"
      menu.addItem "color...", (->
        @pickColor menu.title + "\ncolor:", @setColor, @, @color
      ), "choose the World's\nbackground color"
      if WorldMorph.MorphicPreferences is standardSettings
        menu.addItem "touch screen settings", "togglePreferences", "bigger menu fonts\nand sliders"
      else
        menu.addItem "standard settings", "togglePreferences", "smaller menu fonts\nand sliders"
      menu.addLine()
    menu.addItem "run system tests",  "runSystemTests", "runs all the system tests"
    menu.addItem "start test rec",  "startTestRecording", "start recording a test"
    menu.addItem "stop test rec",  "stopTestRecording", "stop recording the test"
    menu.addItem "play test",  "startTestPlaying", "start playing the test"
    menu.addItem "show test source",  "showTestSource", "opens a window with the source of the latest test"
    menu.addLine()
    if @isDevMode
      menu.addItem "user mode...", "toggleDevMode", "disable developers'\ncontext menus"
    else
      menu.addItem "development mode...", "toggleDevMode"
    menu.addItem "about Zombie Kernel...", "about"
    menu

  startTestRecording: ->
    @systemTestsRecorderAndPlayer.startTestRecording()

  stopTestRecording: ->
    @systemTestsRecorderAndPlayer.stopTestRecording()

  startTestPlaying: ->
    @systemTestsRecorderAndPlayer.startTestPlaying()

  showTestSource: ->
    @systemTestsRecorderAndPlayer.showTestSource()
  
  userCreateMorph: ->
    create = (aMorph) =>
      aMorph.isDraggable = true
      aMorph.pickUp @
    menu = new MenuMorph(@, "make a morph")
    menu.addItem "rectangle", ->
      create new Morph()
    
    menu.addItem "box", ->
      create new BoxMorph()
    
    menu.addItem "circle box", ->
      create new CircleBoxMorph()
    
    menu.addLine()
    menu.addItem "slider", ->
      create new SliderMorph()
    
    menu.addItem "frame", ->
      newMorph = new FrameMorph()
      newMorph.setExtent new Point(350, 250)
      create newMorph
    
    menu.addItem "scroll frame", ->
      newMorph = new ScrollFrameMorph()
      newMorph.contents.acceptsDrops = true
      newMorph.contents.adjustBounds()
      newMorph.setExtent new Point(350, 250)
      create newMorph
    
    menu.addItem "handle", ->
      create new HandleMorph()
    
    menu.addLine()
    menu.addItem "string", ->
      newMorph = new StringMorph("Hello, World!")
      newMorph.isEditable = true
      create newMorph
    
    menu.addItem "text", ->
      newMorph = new TextMorph("Ich weiß nicht, was soll es bedeuten, dass ich so " +
        "traurig bin, ein Märchen aus uralten Zeiten, das " +
        "kommt mir nicht aus dem Sinn. Die Luft ist kühl " +
        "und es dunkelt, und ruhig fließt der Rhein; der " +
        "Gipfel des Berges funkelt im Abendsonnenschein. " +
        "Die schönste Jungfrau sitzet dort oben wunderbar, " +
        "ihr gold'nes Geschmeide blitzet, sie kämmt ihr " +
        "goldenes Haar, sie kämmt es mit goldenem Kamme, " +
        "und singt ein Lied dabei; das hat eine wundersame, " +
        "gewalt'ge Melodei. Den Schiffer im kleinen " +
        "Schiffe, ergreift es mit wildem Weh; er schaut " +
        "nicht die Felsenriffe, er schaut nur hinauf in " +
        "die Höh'. Ich glaube, die Wellen verschlingen " +
        "am Ende Schiffer und Kahn, und das hat mit ihrem " +
        "Singen, die Loreley getan.")
      newMorph.isEditable = true
      newMorph.maxWidth = 300
      newMorph.updateRendering()
      create newMorph
    
    menu.addItem "speech bubble", ->
      newMorph = new SpeechBubbleMorph("Hello, World!")
      create newMorph
    
    menu.addLine()
    menu.addItem "gray scale palette", ->
      create new GrayPaletteMorph()
    
    menu.addItem "color palette", ->
      create new ColorPaletteMorph()
    
    menu.addItem "color picker", ->
      create new ColorPickerMorph()
    
    menu.addLine()
    menu.addItem "sensor demo", ->
      newMorph = new MouseSensorMorph()
      newMorph.setColor new Color(230, 200, 100)
      newMorph.edge = 35
      newMorph.border = 15
      newMorph.borderColor = new Color(200, 100, 50)
      newMorph.alpha = 0.2
      newMorph.setExtent new Point(100, 100)
      create newMorph
    
    menu.addItem "animation demo", ->
      foo = new BouncerMorph()
      foo.setPosition new Point(50, 20)
      foo.setExtent new Point(300, 200)
      foo.alpha = 0.9
      foo.speed = 3
      bar = new BouncerMorph()
      bar.setColor new Color(50, 50, 50)
      bar.setPosition new Point(80, 80)
      bar.setExtent new Point(80, 250)
      bar.type = "horizontal"
      bar.direction = "right"
      bar.alpha = 0.9
      bar.speed = 5
      baz = new BouncerMorph()
      baz.setColor new Color(20, 20, 20)
      baz.setPosition new Point(90, 140)
      baz.setExtent new Point(40, 30)
      baz.type = "horizontal"
      baz.direction = "right"
      baz.speed = 3
      garply = new BouncerMorph()
      garply.setColor new Color(200, 20, 20)
      garply.setPosition new Point(90, 140)
      garply.setExtent new Point(20, 20)
      garply.type = "vertical"
      garply.direction = "up"
      garply.speed = 8
      fred = new BouncerMorph()
      fred.setColor new Color(20, 200, 20)
      fred.setPosition new Point(120, 140)
      fred.setExtent new Point(20, 20)
      fred.type = "vertical"
      fred.direction = "down"
      fred.speed = 4
      bar.add garply
      bar.add baz
      foo.add fred
      foo.add bar
      create foo
    
    menu.addItem "pen", ->
      create new PenMorph()
    
    menu.addLine()
    menu.addItem "view all...", ->
      newMorph = new MorphsListMorph()
      create newMorph
    menu.addItem "closing window", ->
      newMorph = new WorkspaceMorph()
      create newMorph

    if @customMorphs
      menu.addLine()
      @customMorphs().forEach (morph) ->
        menu.addItem morph.toString(), ->
          create morph
    
    menu.popUpAtHand @
  
  toggleDevMode: ->
    @isDevMode = not @isDevMode
  
  hideAll: ->
    @children.forEach (child) ->
      child.hide()
  
  showAllHiddens: ->
    @forAllChildren (child) ->
      child.show()  unless child.isVisible
  
  about: ->
    versions = ""
    for module of modules
      if Object.prototype.hasOwnProperty.call(modules, module)
        versions += ("\n" + module + " (" + modules[module] + ")")  
    if versions isnt ""
      versions = "\n\nmodules:\n\n" + "morphic (" + morphicVersion + ")" + versions  
    @inform "Zombie kernel\n\n" +
      "a lively Web GUI\ninspired by Squeak\n" +
      morphicVersion +
      "\n\nby Davide Della Casa" +
      "\n\nbased on morphic.js by" +
      "\nJens Mönig (jens@moenig.org)"
  
  edit: (aStringMorphOrTextMorph) ->
    # first off, if the Morph is not editable
    # then there is nothing to do
    return null  unless aStringMorphOrTextMorph.isEditable

    # there is only one caret in the World, so destroy
    # the previous one if there was one.
    if @caret
      # empty the previously ongoing selection
      # if there was one.
      @lastEditedText = @caret.target
      @lastEditedText.clearSelection()  if @lastEditedText
      @caret.destroy()

    # create the new Caret
    @caret = new CaretMorph(aStringMorphOrTextMorph)
    aStringMorphOrTextMorph.parent.add @caret
    @keyboardReceiver = @caret
    @initVirtualKeyboard()
    if WorldMorph.MorphicPreferences.isTouchDevice and WorldMorph.MorphicPreferences.useVirtualKeyboard
      pos = getDocumentPositionOf(@worldCanvas)
      @virtualKeyboard.style.top = @caret.top() + pos.y + "px"
      @virtualKeyboard.style.left = @caret.left() + pos.x + "px"
      @virtualKeyboard.focus()
    if WorldMorph.MorphicPreferences.useSliderForInput
      if !aStringMorphOrTextMorph.parentThatIsA(MenuMorph)
        @slide aStringMorphOrTextMorph
  
  # Editing can stop because of three reasons:
  #   cancel (user hits ESC)
  #   accept (on stringmorph, user hits enter)
  #   user clicks/drags another morph
  stopEditing: ->
    if @caret
      @lastEditedText = @caret.target
      @lastEditedText.clearSelection()
      @lastEditedText.escalateEvent "reactToEdit", @lastEditedText
      @caret.destroy()
      @caret = null
    @keyboardReceiver = null
    if @virtualKeyboard
      @virtualKeyboard.blur()
      document.body.removeChild @virtualKeyboard
      @virtualKeyboard = null
    @worldCanvas.focus()
  
  slide: (aStringMorphOrTextMorph) ->
    # display a slider for numeric text entries
    val = parseFloat(aStringMorphOrTextMorph.text)
    val = 0  if isNaN(val)
    menu = new MenuMorph()
    slider = new SliderMorph(val - 25, val + 25, val, 10, "horizontal")
    slider.alpha = 1
    slider.color = new Color(225, 225, 225)
    slider.button.color = menu.borderColor
    slider.button.highlightColor = slider.button.color.copy()
    slider.button.highlightColor.b += 100
    slider.button.pressColor = slider.button.color.copy()
    slider.button.pressColor.b += 150
    slider.silentSetHeight WorldMorph.MorphicPreferences.scrollBarSize
    slider.silentSetWidth WorldMorph.MorphicPreferences.menuFontSize * 10
    slider.updateRendering()
    slider.action = (num) ->
      aStringMorphOrTextMorph.changed()
      aStringMorphOrTextMorph.text = Math.round(num).toString()
      aStringMorphOrTextMorph.updateRendering()
      aStringMorphOrTextMorph.changed()
      aStringMorphOrTextMorph.escalateEvent(
          'reactToSliderEdit',
          aStringMorphOrTextMorph
      )
    #
    menu.items.push slider
    menu.popup @, aStringMorphOrTextMorph.bottomLeft().add(new Point(0, 5))
  
  toggleBlurredShadows: ->
    useBlurredShadows = not useBlurredShadows
  
  togglePreferences: ->
    if WorldMorph.MorphicPreferences is standardSettings
      WorldMorph.MorphicPreferences = touchScreenSettings
    else
      WorldMorph.MorphicPreferences = standardSettings
