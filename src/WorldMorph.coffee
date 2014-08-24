# WorldMorph //////////////////////////////////////////////////////////

# these comments below needed to figure our dependencies between classes
# REQUIRES globalFunctions
# REQUIRES PreferencesAndSettings
# REQUIRES Color

# The WorldMorph takes over the canvas on the page
class WorldMorph extends FrameMorph

  # We need to add and remove
  # the event listeners so we are
  # going to put them all in properties
  # here.
  dblclickEventListener: null
  mousedownEventListener: null
  touchstartEventListener: null
  mouseupEventListener: null
  touchendEventListener: null
  mousemoveEventListener: null
  touchmoveEventListener: null
  gesturestartEventListener: null
  gesturechangeEventListener: null
  contextmenuEventListener: null
  # Note how there can be two handlers for
  # keyboard events.
  # This one is attached
  # to the canvas and reaches the currently
  # blinking caret if there is one.
  # See below for the other potential
  # handler. See "initVirtualKeyboard"
  # method to see where and when this input and
  # these handlers are set up.
  keydownEventListener: null
  keyupEventListener: null
  keypressEventListener: null
  mousewheelEventListener: null
  DOMMouseScrollEventListener: null
  copyEventListener: null
  pasteEventListener: null

  # Note how there can be two handlers
  # for keyboard events. This one is
  # attached to a hidden
  # "input" div which keeps track of the
  # text that is being input.
  inputDOMElementForVirtualKeyboardKeydownEventListener: null
  inputDOMElementForVirtualKeyboardKeyupEventListener: null
  inputDOMElementForVirtualKeyboardKeypressEventListener: null

  keyComboStartRecordingTestEventListener: null
  keyComboResetWorldEventListener: null
  keyComboTieAnimationsToTestCommandNumber: null
  keyComboUntieAnimationsFromTestCommandNumber: null
  keyComboTakeScreenshotEventListener: null
  keyComboStopTestRecordingEventListener: null
  keyComboReplayTestEventListener: null
  keyComboSaveTestEventListener: null
  keyComboTakeScreenshotEventListener: null
  keyComboSaveFailedScreenshotsEventListener: null
  keyComboAddTestCommentEventListener: null
  keyComboCheckNumberOfMenuItemsEventListener: null

  dragoverEventListener: null
  dropEventListener: null
  resizeEventListener: null
  otherTasksToBeRunOnStep: []

  # these variables shouldn't be static to the WorldMorph, because
  # in pure theory you could have multiple worlds in the same
  # page with different settings
  # (but anyways, it was global before, so it's not any worse than before)
  @preferencesAndSettings: null
  @currentTime: null
  @showRedraws: false
  systemTestsRecorderAndPlayer: null

  # this is the actual reference to the canvas
  # on the html page, where the world is
  # finally painted to.
  worldCanvas: null

  # By default the world will always fill
  # the entire page, also when browser window
  # is resized.
  # When this flag is set, the onResize callback
  # automatically adjusts the world size.
  automaticallyAdjustToFillEntireBrowserAlsoOnResize: true

  # keypad keys map to special characters
  # so we can trigger test actions
  # see more comments below
  @KEYPAD_TAB_mappedToThaiKeyboard_A: "ฟ"
  @KEYPAD_SLASH_mappedToThaiKeyboard_B: "ิ"
  @KEYPAD_MULTIPLY_mappedToThaiKeyboard_C: "แ"
  @KEYPAD_DELETE_mappedToThaiKeyboard_D: "ก"
  @KEYPAD_7_mappedToThaiKeyboard_E: "ำ"
  @KEYPAD_8_mappedToThaiKeyboard_F: "ด"
  @KEYPAD_9_mappedToThaiKeyboard_G: "เ"
  @KEYPAD_MINUS_mappedToThaiKeyboard_H: "้"
  @KEYPAD_4_mappedToThaiKeyboard_I: "ร"
  @KEYPAD_5_mappedToThaiKeyboard_J: "่" # looks like empty string but isn't :-)
  @KEYPAD_6_mappedToThaiKeyboard_K: "า"
  @KEYPAD_PLUS_mappedToThaiKeyboard_L: "ส" 
  @KEYPAD_1_mappedToThaiKeyboard_M: "ท"
  @KEYPAD_2_mappedToThaiKeyboard_N: "ท"
  @KEYPAD_3_mappedToThaiKeyboard_O: "ื"
  @KEYPAD_ENTER_mappedToThaiKeyboard_P: "น"
  @KEYPAD_0_mappedToThaiKeyboard_Q: "ย"
  @KEYPAD_DOT_mappedToThaiKeyboard_R: "พ"

  constructor: (
      @worldCanvas,
      @automaticallyAdjustToFillEntireBrowserAlsoOnResize = true
      ) ->

    # The WorldMorph is the very first morph to
    # be created.

    # We first need to initialise
    # some Color constants, like
    #   Color.red
    # See the comment at the beginning of the
    # color class on why this piece of code
    # is here instead of somewhere else.
    for colorName, colorValue of Color.colourNamesValues
      Color["#{colorName}"] = new Color(colorValue[0],colorValue[1], colorValue[2])
    # The colourNamesValues data structure is
    # redundant at this point.
    delete Color.colourNamesValues

    super()
    WorldMorph.preferencesAndSettings = new PreferencesAndSettings()
    console.log WorldMorph.preferencesAndSettings.menuFontName
    @color = new Color(205, 205, 205) # (130, 130, 130)
    @alpha = 1
    @isMinimised = false
    @isDraggable = false

    # additional properties:
    @stamp = Date.now() # reference in multi-world setups
    @isDevMode = false
    @broken = []
    @hand = new HandMorph(@)
    @keyboardEventsReceiver = null
    @lastEditedText = null
    @caret = null
    @activeMenu = null
    @activeHandle = null
    @inputDOMElementForVirtualKeyboard = null

    if @automaticallyAdjustToFillEntireBrowserAlsoOnResize
      @stretchWorldToFillEntirePage()
    @bounds = new Rectangle(0, 0, @worldCanvas.width, @worldCanvas.height)

    @initEventListeners()
    @systemTestsRecorderAndPlayer = new SystemTestsRecorderAndPlayer(@, @hand)

    @changed()
    @updateRendering()

  
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

    # each broken rectangle requires traversing the scenegraph to
    # redraw what's overlapping it. Not all Morphs are traversed
    # in particular the following can stop the recursion:
    #  - invisible Morphs
    #  - FrameMorphs that don't overlap the broken rectangle
    # Since potentially there is a lot of traversal ongoin for
    # each broken rectangle, one might want to consolidate overlapping
    # and nearby rectangles.

    @broken.forEach (rect) =>
      @recursivelyBlit @worldCanvas, rect  if rect.isNotEmpty()
    @broken = []
  
  doOneCycle: ->
    WorldMorph.currentTime = Date.now();
    #console.log TextMorph.instancesCounter + " " + StringMorph.instancesCounter
    @runOtherTasksStepFunction()
    @runChildrensStepFunction()
    @updateBroken()
  
  runOtherTasksStepFunction : ->
    for task in @otherTasksToBeRunOnStep
      #console.log "running a task: " + task
      task()

  stretchWorldToFillEntirePage: ->
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
    if @inputDOMElementForVirtualKeyboard
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = null
    unless (WorldMorph.preferencesAndSettings.isTouchDevice and WorldMorph.preferencesAndSettings.useVirtualKeyboard)
      return
    @inputDOMElementForVirtualKeyboard = document.createElement("input")
    @inputDOMElementForVirtualKeyboard.type = "text"
    @inputDOMElementForVirtualKeyboard.style.color = "transparent"
    @inputDOMElementForVirtualKeyboard.style.backgroundColor = "transparent"
    @inputDOMElementForVirtualKeyboard.style.border = "none"
    @inputDOMElementForVirtualKeyboard.style.outline = "none"
    @inputDOMElementForVirtualKeyboard.style.position = "absolute"
    @inputDOMElementForVirtualKeyboard.style.top = "0px"
    @inputDOMElementForVirtualKeyboard.style.left = "0px"
    @inputDOMElementForVirtualKeyboard.style.width = "0px"
    @inputDOMElementForVirtualKeyboard.style.height = "0px"
    @inputDOMElementForVirtualKeyboard.autocapitalize = "none" # iOS specific
    document.body.appendChild @inputDOMElementForVirtualKeyboard

    @inputDOMElementForVirtualKeyboardKeydownEventListener = (event) =>

      @keyboardEventsReceiver.processKeyDown event  if @keyboardEventsReceiver

      # Default in several browsers
      # is for the backspace button to trigger
      # the "back button", so we prevent that
      # default here.
      if event.keyIdentifier is "U+0008" or event.keyIdentifier is "Backspace"
        event.preventDefault()  

      # suppress tab override and make sure tab gets
      # received by all browsers
      if event.keyIdentifier is "U+0009" or event.keyIdentifier is "Tab"
        @keyboardEventsReceiver.processKeyPress event  if @keyboardEventsReceiver
        event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keydown",
      @inputDOMElementForVirtualKeyboardKeydownEventListener, false

    @inputDOMElementForVirtualKeyboardKeyupEventListener = (event) =>
      # dispatch to keyboard receiver
      if @keyboardEventsReceiver
        # so far the caret is the only keyboard
        # event handler and it has no keyup
        # handler
        if @keyboardEventsReceiver.processKeyUp
          @keyboardEventsReceiver.processKeyUp event  
      event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keyup",
      @inputDOMElementForVirtualKeyboardKeyupEventListener, false

    @inputDOMElementForVirtualKeyboardKeypressEventListener = (event) =>
      @keyboardEventsReceiver.processKeyPress event  if @keyboardEventsReceiver
      event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keypress",
      @inputDOMElementForVirtualKeyboardKeypressEventListener, false

  processMouseDown: (button, ctrlKey) ->
    # the recording of the test command (in case we are
    # recording a test) is handled inside the function
    # here below.
    # This is different from the other methods similar
    # to this one but there is a little bit of
    # logic we apply in case there is a right-click,
    # or user left or right-clicks on a menu,
    # in which case we record a more specific test
    # commands.

    # we might eliminate this command afterwards if
    # we find out user is clicking on a menu item
    # or right-clicking on a morph
    @systemTestsRecorderAndPlayer.addMouseDownCommand(button, ctrlKey)

    @hand.processMouseDown event.button, event.ctrlKey

  processMouseUp: (button) ->
    event.preventDefault()

    # we might eliminate this command afterwards if
    # we find out user is clicking on a menu item
    # or right-clicking on a morph
    @systemTestsRecorderAndPlayer.addMouseUpCommand()

    @hand.processMouseUp event.button

  processMouseMove: (pageX, pageY) ->
    @systemTestsRecorderAndPlayer.addMouseMoveCommand(pageX, pageY)
    @hand.processMouseMove  event.pageX, event.pageY

  # event.type must be keypress
  getChar: (event) ->
    unless event.which?
      String.fromCharCode event.keyCode # IE
    else if event.which isnt 0 and event.charCode isnt 0
      String.fromCharCode event.which # the rest
    else
      null # special key

  processKeydown: (event, scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    @systemTestsRecorderAndPlayer.addKeyDownCommand scanCode, shiftKey, ctrlKey, altKey, metaKey
    if @keyboardEventsReceiver
      @keyboardEventsReceiver.processKeyDown scanCode, shiftKey, ctrlKey, altKey, metaKey

    # suppress backspace override
    if event? and scanCode is 8
      event.preventDefault()

    # suppress tab override and make sure tab gets
    # received by all browsers
    if event? and scanCode is 9
      if @keyboardEventsReceiver
        @keyboardEventsReceiver.processKeyPress scanCode, "\t", shiftKey, ctrlKey, altKey, metaKey
      event.preventDefault()

  processKeyup: (event, scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    @systemTestsRecorderAndPlayer.addKeyUpCommand scanCode, shiftKey, ctrlKey, altKey, metaKey
    # dispatch to keyboard receiver
    if @keyboardEventsReceiver
      # so far the caret is the only keyboard
      # event handler and it has no keyup
      # handler
      if @keyboardEventsReceiver.processKeyUp
        @keyboardEventsReceiver.processKeyUp scanCode, shiftKey, ctrlKey, altKey, metaKey    
    if event?
      event.preventDefault()

  processKeypress: (event, charCode, symbol, shiftKey, ctrlKey, altKey, metaKey) ->
    @systemTestsRecorderAndPlayer.addKeyPressCommand charCode, symbol, shiftKey, ctrlKey, altKey, metaKey
    # This if block adapted from:
    # http://stackoverflow.com/a/16033129
    # it rejects the
    # characters from the special
    # test-command-triggering external
    # keypad. Also there is a "00" key
    # in such keypads which is implemented
    # buy just a double-press of the zero.
    # We manage that case - if that key is
    # pressed twice we understand that it's
    # that particular key. Managing this
    # special case within Zombie Kernel
    # is not best, but there aren't any
    # good alternatives.
    if event?
      # don't manage external keypad if we are playing back
      # the tests (i.e. when event is null)
      if symbol == @constructor.KEYPAD_0_mappedToThaiKeyboard_Q
        unless @doublePressOfZeroKeypadKey?
          @doublePressOfZeroKeypadKey = 1
          setTimeout (=>
            if @doublePressOfZeroKeypadKey is 1
              console.log "single keypress"
            @doublePressOfZeroKeypadKey = null
            event.keyCode = 0
            return false
          ), 300
        else
          @doublePressOfZeroKeypadKey = null
          console.log "double keypress"
          event.keyCode = 0
        return false

    if @keyboardEventsReceiver
      @keyboardEventsReceiver.processKeyPress charCode, symbol, shiftKey, ctrlKey, altKey, metaKey
    if event?
      event.preventDefault()

  processCopy: (event) ->
    @systemTestsRecorderAndPlayer.addCopyCommand
    console.log "processing copy"
    if @caret
      selectedText = @caret.target.selection()
      if event.clipboardData
        event.preventDefault()
        setStatus = event.clipboardData.setData("text/plain", selectedText)

      if window.clipboardData
        event.returnValue = false
        setStatus = window.clipboardData.setData "Text", selectedText

  processPaste: (event, text) ->
    if @caret
      if event?
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
      
      # Needs a few msec to execute paste
      console.log "about to insert text: " + text
      @systemTestsRecorderAndPlayer.addPasteCommand text
      window.setTimeout ( => (@caret.insert text)), 50, true


  initEventListeners: ->
    canvas = @worldCanvas

    @dblclickEventListener = (event) =>
      event.preventDefault()
      @hand.processDoubleClick event
    canvas.addEventListener "dblclick", @dblclickEventListener, false

    @mousedownEventListener = (event) =>
      @processMouseDown event.button, event.ctrlKey
    canvas.addEventListener "mousedown", @mousedownEventListener, false

    @touchstartEventListener = (event) =>
      @hand.processTouchStart event
    canvas.addEventListener "touchstart", @touchstartEventListener , false
    
    @mouseupEventListener = (event) =>
      @processMouseUp event.button
    canvas.addEventListener "mouseup", @mouseupEventListener, false
    
    @touchendEventListener = (event) =>
      @hand.processTouchEnd event
    canvas.addEventListener "touchend", @touchendEventListener, false
    
    @mousemoveEventListener = (event) =>
      @processMouseMove  event.pageX, event.pageY
    canvas.addEventListener "mousemove", @mousemoveEventListener, false
    
    @touchmoveEventListener = (event) =>
      @hand.processTouchMove event
    canvas.addEventListener "touchmove", @touchmoveEventListener, false
    
    @gesturestartEventListener = (event) =>
      # Disable browser zoom
      event.preventDefault()
    canvas.addEventListener "gesturestart", @gesturestartEventListener, false
    
    @gesturechangeEventListener = (event) =>
      # Disable browser zoom
      event.preventDefault()
    canvas.addEventListener "gesturechange", @gesturechangeEventListener, false
    
    @contextmenuEventListener = (event) ->
      # suppress context menu for Mac-Firefox
      event.preventDefault()
    canvas.addEventListener "contextmenu", @contextmenuEventListener, false
    
    @keydownEventListener = (event) =>
      @processKeydown event, event.keyCode, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey
    canvas.addEventListener "keydown", @keydownEventListener, false

    @keyupEventListener = (event) =>
      @processKeyup event, event.keyCode, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey
    canvas.addEventListener "keyup", @keyupEventListener, false

    # This method also handles keypresses from a special
    # external keypad which is used to
    # record tests commands (such as capture screen, etc.).
    # These external keypads are inexpensive
    # so they are a good device for this kind
    # of stuff.
    # http://www.amazon.co.uk/Perixx-PERIPAD-201PLUS-Numeric-Keypad-Laptop/dp/B001R6FZLU/
    # They keypad is mapped
    # to Thai keyboard characters via an OSX app
    # called keyremap4macbook (also one needs to add the
    # Thai keyboard, which is just a click from System Preferences)
    # Those Thai characters are used to trigger test
    # commands. The only added complexity is about
    # the "00" key of such keypads - see
    # note below.
    doublePressOfZeroKeypadKey: null
    
    @keypressEventListener = (event) =>
      @processKeypress event, event.keyCode, @getChar(event), event.shiftKey, event.ctrlKey, event.altKey, event.metaKey
    canvas.addEventListener "keypress", @keypressEventListener, false

    # Safari, Chrome
    
    @mousewheelEventListener = (event) =>
      @hand.processMouseScroll event
      event.preventDefault()
    canvas.addEventListener "mousewheel", @mousewheelEventListener, false
    # Firefox
    
    @DOMMouseScrollEventListener = (event) =>
      @hand.processMouseScroll event
      event.preventDefault()
    canvas.addEventListener "DOMMouseScroll", @DOMMouseScrollEventListener, false

    # in theory there should be no scroll event on the page
    # window.addEventListener "scroll", ((event) =>
    #  nop # nothing to do, I just need this to set an interrupt point.
    # ), false

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
    
    @copyEventListener = (event) =>
      @processCopy event
    document.body.addEventListener "copy", @copyEventListener, false

    @pasteEventListener = (event) =>
      @processPaste event
    document.body.addEventListener "paste", @pasteEventListener, false

    #console.log "binding via mousetrap"

    @keyComboStartRecordingTestEventListener = (event) =>
      @systemTestsRecorderAndPlayer.startTestRecording()
      false
    Mousetrap.bind ["alt+n"], @keyComboStartRecordingTestEventListener

    @keyComboResetWorldEventListener = (event) =>
      @systemTestsRecorderAndPlayer.resetWorld()
      false
    Mousetrap.bind ["alt+d"], @keyComboResetWorldEventListener

    @keyComboTieAnimationsToTestCommandNumber = (event) =>
      @systemTestsRecorderAndPlayer.tieAnimationsToTestCommandNumber()
      false
    Mousetrap.bind ["alt+e"], @keyComboTieAnimationsToTestCommandNumber

    @keyComboUntieAnimationsFromTestCommandNumber = (event) =>
      @systemTestsRecorderAndPlayer.untieAnimationsFromTestCommandNumber()
      false
    Mousetrap.bind ["alt+u"], @keyComboUntieAnimationsFromTestCommandNumber

    @keyComboTakeScreenshotEventListener = (event) =>
      @systemTestsRecorderAndPlayer.takeScreenshot()
      false
    Mousetrap.bind ["alt+c"], @keyComboTakeScreenshotEventListener

    @keyComboStopTestRecordingEventListener = (event) =>
      @systemTestsRecorderAndPlayer.stopTestRecording()
      false
    Mousetrap.bind ["alt+t"], @keyComboStopTestRecordingEventListener

    @keyComboReplayTestEventListener = (event) =>
      @systemTestsRecorderAndPlayer.startTestPlaying()
      false
    Mousetrap.bind ["alt+p"], @keyComboReplayTestEventListener

    @keyComboSaveTestEventListener = (event) =>
      @systemTestsRecorderAndPlayer.saveTest()
      false
    Mousetrap.bind ["alt+s"], @keyComboSaveTestEventListener

    @keyComboSaveFailedScreenshotsEventListener = (event) =>
      @systemTestsRecorderAndPlayer.saveFailedScreenshots()
      false
    Mousetrap.bind ["alt+f"], @keyComboSaveFailedScreenshotsEventListener

    @keyComboAddTestCommentEventListener = (event) =>
      @systemTestsRecorderAndPlayer.addTestComment()
      false
    Mousetrap.bind ["alt+m"], @keyComboAddTestCommentEventListener

    @keyComboCheckNumberOfMenuItemsEventListener = (event) =>
      @systemTestsRecorderAndPlayer.checkNumberOfItemsInMenu()
      false
    Mousetrap.bind ["alt+k"], @keyComboCheckNumberOfMenuItemsEventListener

    @dragoverEventListener = (event) ->
      event.preventDefault()
    window.addEventListener "dragover", @dragoverEventListener, false
    
    @dropEventListener = (event) =>
      @hand.processDrop event
      event.preventDefault()
    window.addEventListener "drop", @dropEventListener, false
    
    @resizeEventListener = =>
      @stretchWorldToFillEntirePage()  if @automaticallyAdjustToFillEntireBrowserAlsoOnResize
    window.addEventListener "resize", @resizeEventListener, false
    
    window.onbeforeunload = (evt) ->
      e = evt or window.event
      msg = "Are you sure you want to leave?"
      #
      # For IE and Firefox
      e.returnValue = msg  if e
      #
      # For Safari / chrome
      msg
  
  removeEventListeners: ->
    canvas = @worldCanvas
    canvas.removeEventListener 'dblclick', @dblclickEventListener
    canvas.removeEventListener 'mousedown', @mousedownEventListener
    canvas.removeEventListener 'touchstart', @touchstartEventListener
    canvas.removeEventListener 'mouseup', @mouseupEventListener
    canvas.removeEventListener 'touchend', @touchendEventListener
    canvas.removeEventListener 'mousemove', @mousemoveEventListener
    canvas.removeEventListener 'touchmove', @touchmoveEventListener
    canvas.removeEventListener 'gesturestart', @gesturestartEventListener
    canvas.removeEventListener 'gesturechange', @gesturechangeEventListener
    canvas.removeEventListener 'contextmenu', @contextmenuEventListener
    canvas.removeEventListener 'keydown', @keydownEventListener
    canvas.removeEventListener 'keyup', @keyupEventListener
    canvas.removeEventListener 'keypress', @keypressEventListener
    canvas.removeEventListener 'mousewheel', @mousewheelEventListener
    canvas.removeEventListener 'DOMMouseScroll', @DOMMouseScrollEventListener
    canvas.removeEventListener 'copy', @copyEventListener
    canvas.removeEventListener 'paste', @pasteEventListener
    Mousetrap.reset()
    canvas.removeEventListener 'dragover', @dragoverEventListener
    canvas.removeEventListener 'drop', @dropEventListener
    canvas.removeEventListener 'resize', @resizeEventListener
  
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
  
  # There is something special that the
  # "world" version of destroyAll does:
  # it resets the counter used to count
  # how many morphs exist of each Morph class.
  # That counter is also used to determine the
  # unique ID of a Morph. So, destroying
  # all morphs from the world causes the
  # counts and IDs of all the subsequent
  # morphs to start from scratch again.
  destroyAll: ->
    # Check which objects end with the word Morph
    theWordMorph = "Morph"
    ListOfMorphs = (Object.keys(window)).filter (i) ->
      i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
    for eachMorphClass in ListOfMorphs
      if eachMorphClass != "WorldMorph"
        console.log "resetting " + eachMorphClass + " from " + window[eachMorphClass].instancesCounter
        window[eachMorphClass].instancesCounter = 0
    super()

  # WorldMorph menu:
  contextMenu: ->
    if @isDevMode
      menu = new MenuMorph(
        @, @constructor.name or @constructor.toString().split(" ")[1].split("(")[0])
    else
      menu = new MenuMorph(@, "Morphic")
    if @isDevMode
      menu.addItem "demo...", (->@userCreateMorph()), "sample morphs"
      menu.addLine()
      menu.addItem "hide all...", (->@minimiseAll())
      menu.addItem "delete all...", (->@destroyAll())
      menu.addItem "show all...", (->@showAllMinimised())
      menu.addItem "move all inside...", (->@keepAllSubmorphsWithin()), "keep all submorphs\nwithin and visible"
      menu.addItem "inspect...", (->@inspect()), "open a window on\nall properties"
      menu.addLine()
      menu.addItem "restore display", (->@changed()), "redraw the\nscreen once"
      menu.addItem "fill page...", (->@stretchWorldToFillEntirePage()), "let the World automatically\nadjust to browser resizings"
      if WorldMorph.preferencesAndSettings.useBlurredShadows
        menu.addItem "sharp shadows...", (->WorldMorph.preferencesAndSettings.toggleBlurredShadows()), "sharp drop shadows\nuse for old browsers"
      else
        menu.addItem "blurred shadows...", (->WorldMorph.preferencesAndSettings.toggleBlurredShadows()), "blurry shades,\n use for new browsers"
      menu.addItem "color...", (->
        @pickColor menu.title + "\ncolor:", @setColor, @, @color
      ), "choose the World's\nbackground color"
      if WorldMorph.preferencesAndSettings.inputMode is PreferencesAndSettings.INPUT_MODE_MOUSE
        menu.addItem "touch screen settings", (->WorldMorph.preferencesAndSettings.toggleInputMode()), "bigger menu fonts\nand sliders"
      else
        menu.addItem "standard settings", (->WorldMorph.preferencesAndSettings.toggleInputMode()), "smaller menu fonts\nand sliders"
      menu.addLine()
    
    if window.location.href.indexOf("worldWithSystemTestHarness") != -1
      menu.addItem "run system tests",  (->@systemTestsRecorderAndPlayer.runAllSystemTests()), "runs all the system tests"
      menu.addItem "start test rec",  (->@systemTestsRecorderAndPlayer.startTestRecording()), "start recording a test"
      menu.addItem "stop test rec",  (->@systemTestsRecorderAndPlayer.stopTestRecording()), "stop recording the test"
      menu.addItem "play test",  (->@systemTestsRecorderAndPlayer.startTestPlaying()), "start playing the test"
      menu.addItem "show test source",  (->@systemTestsRecorderAndPlayer.showTestSource()), "opens a window with the source of the latest test"
      menu.addLine()
    if @isDevMode
      menu.addItem "user mode...", (->@toggleDevMode()), "disable developers'\ncontext menus"
    else
      menu.addItem "development mode...", (->@toggleDevMode())
    menu.addItem "about Zombie Kernel...", (->@about())
    menu
  
  userCreateMorph: ->
    create = (aMorph) =>
      aMorph.isDraggable = true
      aMorph.pickUp @
    menu = new MenuMorph(@, "make a morph")
    menu.addItem "rectangle", ->
      create new RectangleMorph()
    
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
    menu.addItem "Layout tests", (->@layoutTestsMenu()), "sample morphs"
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

  layoutTestsMenu: ->
    create = (aMorph) =>
      aMorph.isDraggable = true
      aMorph.pickUp @
    menu = new MenuMorph(@, "Layout tests")
    menu.addItem "test1", ->
      LayoutMorph.test1()
    menu.addItem "test2", ->
      LayoutMorph.test2()
    menu.addItem "test3", ->
      LayoutMorph.test3()
    menu.addItem "test4", ->
      LayoutMorph.test4()
    menu.popUpAtHand @
    
  
  toggleDevMode: ->
    @isDevMode = not @isDevMode
  
  minimiseAll: ->
    @children.forEach (child) ->
      child.minimise()
  
  showAllMinimised: ->
    @forAllChildrenBottomToTop (child) ->
      child.unminimise() if child.isMinimised
  
  about: ->
    @inform "Zombie Kernel\n\n" +
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
    # this is the only place where the @keyboardEventsReceiver is set
    @keyboardEventsReceiver = @caret

    if WorldMorph.preferencesAndSettings.isTouchDevice and WorldMorph.preferencesAndSettings.useVirtualKeyboard
      @initVirtualKeyboard()
      # For touch devices, giving focus on the textbox causes
      # the keyboard to slide up, and since the page viewport
      # shrinks, the page is scrolled to where the texbox is.
      # So, it is important to position the textbox around
      # where the caret is, so that the changed text is going to
      # be visible rather than out of the viewport.
      pos = getDocumentPositionOf(@worldCanvas)
      @inputDOMElementForVirtualKeyboard.style.top = @caret.top() + pos.y + "px"
      @inputDOMElementForVirtualKeyboard.style.left = @caret.left() + pos.x + "px"
      @inputDOMElementForVirtualKeyboard.focus()
    if WorldMorph.preferencesAndSettings.useSliderForInput
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
    # the only place where the @keyboardEventsReceiver is unset
    # (and the hidden input is removed)
    @keyboardEventsReceiver = null
    if @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard.blur()
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = null
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
    slider.silentSetHeight WorldMorph.preferencesAndSettings.scrollBarSize
    slider.silentSetWidth WorldMorph.preferencesAndSettings.menuFontSize * 10
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
  
  
