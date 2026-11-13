# BrowserInputBridge -- the page's DOM input adapter. It installs the browser's event listeners on
# the world canvas, document.body and window. The pointer, key down/up, wheel, clipboard and resize
# listeners turn their browser event into an InputEvent record on the world's queue
# (world.inputEventsQueue), which the world drains in its own cycle -- that is what keeps input
# deterministic; a file dropped on the page goes straight to FileLoading, and the context-menu,
# gesture and dragover listeners only stop the browser's own default. It also builds the hidden DOM
# <input> the on-screen keyboard types into, for an edit a finger began.
#
# A plain collaborator (no widget), built by its world (world.browserInput) and holding a
# reference to that world, which every listener here feeds. No listener outlives its world: the
# world's dissolution removes them (WorldWdgt._dissolveWorldNoSettle), and the harness removes and
# re-installs them around every SystemTest (AutomatorPlayer), so a macro's synthetic events are the
# only input.
class BrowserInputBridge

  # the world this bridge feeds (see above)
  world: undefined

  # We need to add and remove
  # the event listeners so we are
  # going to put them all in properties
  # here.
  # dblclickEventListener: undefined
  pointerdownBrowserEventListener: undefined
  pointermoveBrowserEventListener: undefined
  pointerupBrowserEventListener: undefined
  pointercancelBrowserEventListener: undefined
  contextmenuEventListener: undefined

  gesturestartBrowserEventListener: undefined
  gesturechangeBrowserEventListener: undefined

  # Note how there can be two handlers for
  # keyboard events.
  # This one is attached
  # to the canvas and reaches the currently
  # blinking caret if there is one.
  # See below for the other potential
  # handler. See "initVirtualKeyboard"
  # method to see where and when this input and
  # these handlers are set up.
  keydownBrowserEventListener: undefined
  keyupBrowserEventListener: undefined
  keypressBrowserEventListener: undefined
  wheelBrowserEventListener: undefined

  cutBrowserEventListener: undefined
  copyBrowserEventListener: undefined
  pasteBrowserEventListener: undefined

  # Note how there can be two handlers
  # for keyboard events. This one is
  # attached to a hidden
  # "input" div which keeps track of the
  # text that is being input. This is that hidden element; it is created on demand (when a
  # caret wants keyboard input) and torn down with the caret, so it is undefined most of the time.
  inputDOMElementForVirtualKeyboard: undefined
  inputDOMElementForVirtualKeyboardKeydownBrowserEventListener: undefined
  inputDOMElementForVirtualKeyboardKeyupBrowserEventListener: undefined
  inputDOMElementForVirtualKeyboardKeypressBrowserEventListener: undefined

  dragoverEventListener: undefined
  resizeBrowserEventListener: undefined
  dropBrowserEventListener: undefined

  constructor: (@world) ->

  # The hidden DOM input the on-screen keyboard types into. It exists for the STROKE that opened
  # the edit: a finger has no physical keyboard behind it, so a tap into a text field summons one,
  # while a mouse or pen click leaves the canvas's own keyboard listeners to do the typing. A
  # machine that mixes the two answers per stroke — @world.hand.pointerType is the stroke's own fact,
  # never a device setting (ruling G1). useVirtualKeyboard is the opt-out for a touch machine that
  # has a real keyboard anyway.
  initVirtualKeyboard: ->
    if @inputDOMElementForVirtualKeyboard
      document.body.removeChild @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard = undefined
    unless (@world.hand.pointerType is 'touch' and WorldWdgt.preferencesAndSettings.useVirtualKeyboard)
      return
    @inputDOMElementForVirtualKeyboard = document.createElement "input"
    @inputDOMElementForVirtualKeyboard.type = "text"
    @inputDOMElementForVirtualKeyboard.style.color = Color.TRANSPARENT.toString()
    @inputDOMElementForVirtualKeyboard.style.backgroundColor = Color.TRANSPARENT.toString()
    @inputDOMElementForVirtualKeyboard.style.border = "none"
    @inputDOMElementForVirtualKeyboard.style.outline = "none"
    @inputDOMElementForVirtualKeyboard.style.position = "absolute"
    @inputDOMElementForVirtualKeyboard.style.top = "0px"
    @inputDOMElementForVirtualKeyboard.style.left = "0px"
    @inputDOMElementForVirtualKeyboard.style.width = "0px"
    @inputDOMElementForVirtualKeyboard.style.height = "0px"
    @inputDOMElementForVirtualKeyboard.autocapitalize = "none" # iOS specific
    document.body.appendChild @inputDOMElementForVirtualKeyboard

    @inputDOMElementForVirtualKeyboardKeydownBrowserEventListener = (event) =>
      @world.inputEventsQueue.push InputDOMElementForVirtualKeyboardKeydownInputEvent.fromBrowserEvent event

      # Default in several browsers
      # is for the backspace button to trigger
      # the "back button", so we prevent that
      # default here. The key is read as the canvas's own keydown listener reads it, by
      # `event.key`.
      if event.key is "Backspace"
        event.preventDefault()

      # suppress tab override and make sure tab gets
      # received by all browsers
      if event.key is "Tab"
        event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keydown",
      @inputDOMElementForVirtualKeyboardKeydownBrowserEventListener, false

    @inputDOMElementForVirtualKeyboardKeyupBrowserEventListener = (event) =>
      @world.inputEventsQueue.push InputDOMElementForVirtualKeyboardKeyupInputEvent.fromBrowserEvent event
      event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keyup",
      @inputDOMElementForVirtualKeyboardKeyupBrowserEventListener, false

    # Keypress events are deprecated in the JS specs and are not needed
    @inputDOMElementForVirtualKeyboardKeypressBrowserEventListener = (event) =>
      #@world.inputEventsQueue.push event
      event.preventDefault()

    @inputDOMElementForVirtualKeyboard.addEventListener "keypress",
      @inputDOMElementForVirtualKeyboardKeypressBrowserEventListener, false

  # -----------------------------------------------------
  # clipboard events processing
  # -----------------------------------------------------


  # ONE listener set for every pointer kind. A mouse, a pen and a finger all arrive as W3C
  # Pointer Events carrying pointerType / pointerId / pressure, so the hand reads the kind off
  # each EVENT — a hybrid device gets every stroke right — and there is one stream to reason
  # about rather than a real one and an emulated one.
  #
  # ⚠ NO preventDefault on any of the four pointer listeners, deliberately. Two reasons, both
  # load-bearing: (a) the canvas takes keyboard focus by click (it carries tabindex and the
  # keyboard listeners sit ON it) and engines suppress that focus when a pointerdown is
  # cancelled, so preventing the default here kills keyboard input; (b) browser panning and
  # zooming are not preventDefault's to stop under pointer events at all — the canvas's
  # `touch-action: none` (src/index.html) is what owns them.
  _initPointerEventListeners: ->
    canvas = @world.worldCanvas
    # there is indeed a "dblclick" JS event
    # but we reproduce it internally.
    # The reason is that we do so for "click"
    # because we want to check that the mouse
    # button was released in the same widget
    # where it was pressed (cause in the DOM you'd
    # be pressing and releasing on the same
    # element i.e. the canvas anyways
    # so we receive clicks even though they aren't
    # so we have to take care of the processing
    # ourselves).
    # So we also do the same internal
    # processing for dblclick.
    # Hence, don't register this event listener
    # below...
    #@dblclickEventListener = (event) =>
    #  event.preventDefault()
    #  @world.hand.processDoubleClick event
    #canvas.addEventListener "dblclick", @dblclickEventListener, false

    # The hand is a single-pointer machine, so only each kind's PRIMARY pointer reaches the queue
    # and the queue stays an honest record of what the world processed.
    @pointerdownBrowserEventListener = (event) =>
      return unless event.isPrimary
      # Capture routes the WHOLE stroke to the canvas: without it a drag that wanders off the
      # canvas loses its moves and its up (the listeners are ON the canvas), and the hand keeps a
      # pressed phantom button. A pointerdown made by dispatchEvent has no ACTIVE pointer behind
      # it, and both engines the suite runs on throw NotFoundError when asked to capture one, so
      # the call is guarded; real user input always has an active pointer and always captures.
      try
        canvas.setPointerCapture event.pointerId
      catch error
        # a dispatched pointer has no stroke to route — the page keeps delivering it either way
      @world.inputEventsQueue.push PointerdownInputEvent.fromBrowserEvent event

    canvas.addEventListener "pointerdown", @pointerdownBrowserEventListener, false

    @pointermoveBrowserEventListener = (event) =>
      return unless event.isPrimary
      @world.inputEventsQueue.push PointermoveInputEvent.fromBrowserEvent event

    canvas.addEventListener "pointermove", @pointermoveBrowserEventListener, false

    # no explicit releasePointerCapture: the spec releases an implicit capture on up and on cancel
    @pointerupBrowserEventListener = (event) =>
      return unless event.isPrimary
      @world.inputEventsQueue.push PointerupInputEvent.fromBrowserEvent event

    canvas.addEventListener "pointerup", @pointerupBrowserEventListener, false

    @pointercancelBrowserEventListener = (event) =>
      return unless event.isPrimary
      @world.inputEventsQueue.push PointercancelInputEvent.fromBrowserEvent event

    canvas.addEventListener "pointercancel", @pointercancelBrowserEventListener, false

    @gesturestartBrowserEventListener = (event) =>
      # we don't do anything with gestures for the time being
      event.preventDefault() # (unsure that this one is needed)

    canvas.addEventListener "gesturestart", @gesturestartBrowserEventListener, false

    @gesturechangeBrowserEventListener = (event) =>
      # we don't do anything with gestures for the time being
      event.preventDefault() # (unsure that this one is needed)

    canvas.addEventListener "gesturechange", @gesturechangeBrowserEventListener, false


  _initKeyboardEventListeners: ->
    canvas = @world.worldCanvas
    @keydownBrowserEventListener = (event) =>
      @world.inputEventsQueue.push KeydownInputEvent.fromBrowserEvent event

      # this paragraph is to prevent the browser going
      # "back button" when the user presses delete backspace.
      # taken from http://stackoverflow.com/a/2768256
      doPrevent = false
      if event.key == "Backspace"
        d = event.srcElement or event.target
        if d.tagName.toUpperCase() == 'INPUT' and
        (d.type.toUpperCase() == 'TEXT' or
          d.type.toUpperCase() == 'PASSWORD' or
          d.type.toUpperCase() == 'FILE' or
          d.type.toUpperCase() == 'SEARCH' or
          d.type.toUpperCase() == 'EMAIL' or
          d.type.toUpperCase() == 'NUMBER' or
          d.type.toUpperCase() == 'DATE') or
        d.tagName.toUpperCase() == 'TEXTAREA'
          doPrevent = d.readOnly or d.disabled
        else
          doPrevent = true

      # this paragraph is to prevent the browser scrolling when
      # user presses spacebar, see
      # https://stackoverflow.com/a/22559917
      if event.key == " " and event.target == @world.worldCanvas
        # Note that doing a preventDefault on the spacebar
        # causes it not to generate the keypress event
        # (just the keydown), so we had to modify the keydown
        # to also process the space.
        # (I tried to use stopPropagation instead/inaddition but
        # it didn't work).
        doPrevent = true

      # also browsers tend to do special things when "tab"
      # is pressed, so let's avoid that
      if event.key == "Tab" and event.target == @world.worldCanvas
        doPrevent = true

      if doPrevent
        event.preventDefault()

    canvas.addEventListener "keydown", @keydownBrowserEventListener, false

    @keyupBrowserEventListener = (event) =>
      @world.inputEventsQueue.push KeyupInputEvent.fromBrowserEvent event

    canvas.addEventListener "keyup", @keyupBrowserEventListener, false

    # keypress is deprecated in the latest specs, and it's really not needed/used,
    # since all keys really have an effect when they are pushed down
    @keypressBrowserEventListener = (event) =>

    canvas.addEventListener "keypress", @keypressBrowserEventListener, false

  _initClipboardEventListeners: ->
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

    # -----------------------------------------------------
    # clipboard events listeners
    # -----------------------------------------------------
    # we deal with the clipboard here in the event listeners
    # because for security reasons the runtime is not allowed
    # access to the clipboards outside of here. So we do all
    # we have to do with the clipboard here, and in every
    # other place we work with text.

    @cutBrowserEventListener = (event) =>
      @world.inputEventsQueue.push CutInputEvent.fromBrowserEvent event

    document.body.addEventListener "cut", @cutBrowserEventListener, false
    
    @copyBrowserEventListener = (event) =>
      @world.inputEventsQueue.push CopyInputEvent.fromBrowserEvent event

    document.body.addEventListener "copy", @copyBrowserEventListener, false

    @pasteBrowserEventListener = (event) =>
      @world.inputEventsQueue.push PasteInputEvent.fromBrowserEvent event

    document.body.addEventListener "paste", @pasteBrowserEventListener, false

  _initOtherMiscEventListeners: ->
    canvas = @world.worldCanvas

    @contextmenuEventListener = (event) ->
      # suppress context menu for Mac-Firefox
      event.preventDefault()
    canvas.addEventListener "contextmenu", @contextmenuEventListener, false
    

    # Safari, Chrome
    
    @wheelBrowserEventListener = (event) =>
      @world.inputEventsQueue.push WheelInputEvent.fromBrowserEvent event
      event.preventDefault()

    canvas.addEventListener "wheel", @wheelBrowserEventListener, false

    # (Mobile-Safari wheel-event workaround, Oct 2020. The Jan-2021 re-check reminder went
    # unactioned 4+ yrs with no reported regression — reviewed & retained 2026-07-14.)
    # As of Oct 2020, using mouse/trackpad in
    # Mobile Safari, the wheel event is not sent.
    # See:
    #   https://github.com/cdr/code-server/issues/1455
    #   https://bugs.webkit.org/show_bug.cgi?id=210071
    # However, the scroll event is sent, and when that is sent,
    # we can use the window.pageYOffset
    # to re-create a passable, fake wheel event.
    if Utils.runningInMobileSafari()
      window.addEventListener "scroll", @wheelBrowserEventListener, false

    @dragoverEventListener = (event) ->
      event.preventDefault()
    window.addEventListener "dragover", @dragoverEventListener, false
    
    @dropBrowserEventListener = (event) =>
      event.preventDefault()
      # a Fizzygum file (*.fzw.json) dropped on the desktop is deserialised and attached at
      # the drop point; FileLoading sniffs the envelope and rejects non-Fizzygum files.
      # (Image-file drag-ingestion is a banked future extension.)
      files = event.dataTransfer?.files
      if files? and files.length > 0
        FileLoading.loadFile files[0], new Point event.clientX, event.clientY
    window.addEventListener "drop", @dropBrowserEventListener, false

    @resizeBrowserEventListener = (event) =>
      # a window resize can move the canvas within the document even when it does
      # not route through stretchWorldToFillEntirePage — invalidate eagerly
      @world._invalidateCanvasPositionCache()
      @world.inputEventsQueue.push ResizeInputEvent.fromBrowserEvent event

    # this is a DOM thing, little to do with other r e s i z e methods
    window.addEventListener "resize", @resizeBrowserEventListener, false

  # note that we don't register the normal click,
  # we figure that out independently.
  initEventListeners: ->
    @_initPointerEventListeners()
    @_initKeyboardEventListeners()
    @_initClipboardEventListeners()
    @_initOtherMiscEventListeners()

  # Detach every browser event listener the _init*EventListeners family attached.
  #
  # This is the DETACH half of a PAIR: initEventListeners above (plus initVirtualKeyboard) is the one
  # place listeners are attached and this is the one place they are detached, so the two must enumerate
  # the SAME listener set — a listener added in an _init* and forgotten here leaks on every
  # detach/attach cycle.
  #
  # ⚠ IT SERVES TWO CONTRACTS. DETERMINISM: the harness calls it at the START of every SystemTest
  # (AutomatorPlayer.startTestPlaying, and WorldTestSupport._afterWorldResetNoSettle on the world each
  # test's reset constructs) so that the macro's synthetic events are the ONLY input: a listener that
  # survives here can push a REAL browser event into @world.inputEventsQueue mid-test and break the
  # byte-exact contract (../Fizzygum-tests/DETERMINISM.md). LIFETIME: the world's dissolution
  # (WorldWdgt._dissolveWorldNoSettle) calls it, so a dead world's listeners stop delivering to it.
  #
  # ⚠⚠ EVERY LISTENER MUST BE REMOVED FROM THE SAME TARGET IT WAS ADDED TO — the listeners are spread
  # over THREE targets (@world.worldCanvas / document.body / window) and removeEventListener on the wrong
  # target is a SILENT NO-OP: no error, nothing removed, nothing logged. That is exactly the bug this
  # method shipped with (fixed 2026-07-15): it removed EVERY listener from `canvas`, so the ones
  # added to document.body (cut/copy/paste) or window (scroll/dragover/drop/resize) were never
  # detached at all, and stayed live through every test — including @resizeBrowserEventListener, which
  # pushes a ResizeInputEvent into the queue.
  #
  # So: keep the GROUPS below in sync with their _init* counterparts, and match the target exactly.
  removeEventListeners: ->
    canvas = @world.worldCanvas

    # ── added to @world.worldCanvas ────────────────────────────────────────────────────────────────
    # canvas.removeEventListener 'dblclick', @dblclickEventListener
    canvas.removeEventListener 'pointerdown', @pointerdownBrowserEventListener
    canvas.removeEventListener 'pointermove', @pointermoveBrowserEventListener
    canvas.removeEventListener 'pointerup', @pointerupBrowserEventListener
    canvas.removeEventListener 'pointercancel', @pointercancelBrowserEventListener
    canvas.removeEventListener 'contextmenu', @contextmenuEventListener

    canvas.removeEventListener "gesturestart", @gesturestartBrowserEventListener
    canvas.removeEventListener "gesturechange", @gesturechangeBrowserEventListener

    canvas.removeEventListener 'keydown', @keydownBrowserEventListener
    canvas.removeEventListener 'keyup', @keyupBrowserEventListener
    canvas.removeEventListener 'keypress', @keypressBrowserEventListener
    canvas.removeEventListener 'wheel', @wheelBrowserEventListener

    # ── added to document.body by _initClipboardEventListeners ─────────────────────────────────────
    document.body.removeEventListener 'cut', @cutBrowserEventListener
    document.body.removeEventListener 'copy', @copyBrowserEventListener
    document.body.removeEventListener 'paste', @pasteBrowserEventListener

    # ── added to window by _initOtherMiscEventListeners ────────────────────────────────────────────
    # the mobile-Safari fake-wheel workaround; guarded to mirror the add site (removing a listener
    # that was never added is a harmless no-op, but keep the pair symmetric so the reason stays visible)
    if Utils.runningInMobileSafari()
      window.removeEventListener 'scroll', @wheelBrowserEventListener
    window.removeEventListener 'dragover', @dragoverEventListener
    window.removeEventListener 'drop', @dropBrowserEventListener
    window.removeEventListener 'resize', @resizeBrowserEventListener

    # ── added to @inputDOMElementForVirtualKeyboard by initVirtualKeyboard ─────────────────────────
    # Defensive completeness, not a leak fix: that hidden input only exists for an edit a TOUCH
    # stroke opened, with useVirtualKeyboard on and a caret still up, and closing the caret already
    # removes it from the DOM and clears it (taking its listeners to GC), so this is a no-op in every
    # environment tests run in. It is here so the "detach everything" contract holds regardless.
    if @inputDOMElementForVirtualKeyboard
      @inputDOMElementForVirtualKeyboard.removeEventListener 'keydown', @inputDOMElementForVirtualKeyboardKeydownBrowserEventListener
      @inputDOMElementForVirtualKeyboard.removeEventListener 'keyup', @inputDOMElementForVirtualKeyboardKeyupBrowserEventListener
      @inputDOMElementForVirtualKeyboard.removeEventListener 'keypress', @inputDOMElementForVirtualKeyboardKeypressBrowserEventListener
