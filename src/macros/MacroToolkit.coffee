# this file is only needed for Macros

# MacroToolkit — the framework-side support for high-level "macro" SystemTests,
# lifted out of WorldMorph so the macro machinery has a cohesive, documented home.
# Delegation, not a mixin: the world HAS-A one, reachable as world.macroToolkit
# (created in the WorldMorph constructor, guarded by `if MacroToolkit?` so the
# --homepage build — which strips this whole file — simply has none).
#
# It hosts four layers, told apart by naming convention (see src/macros/CLAUDE.md):
#   L1 input primitives   — syntheticEvents…_InputEvents / expoOut: push timed raw
#                           events onto world.inputEventsQueue.
#   L2 locators & actions  — …_InputEvents: read the live widget tree, compose L1.
#   L3 macro verbs         — standardMacroSubroutines(): reusable …_InputEvents_Macro
#                           generator SOURCE strings a test's main macro calls by name.
#   L4 driver + state      — the per-cycle pump (progressOnMacroSteps, installed by
#                           Macro._addHeaderCode at start) + the macro-step gates/fields.
#
# Authoring rule: a running macro has `@` = this MacroToolkit instance, so in these
# methods (and in macro source strings) `@x` is a MacroToolkit helper/field while
# `world.x` is the live world (world.add, world.inputEventsQueue, world.hand,
# world.topWdgtSuchThat, world.automator…). Full guide: src/macros/CLAUDE.md.

class MacroToolkit

  msSinceLastExecutedMacroStep: nil
  #macroVars: nil # a dedicated global space for macros. Unused so far.
  aMacroIsRunning: nil
  returnFromLastMacroStep: nil
  # latches the frame on which we forced a warm-atlas repaint before a macro
  # screenshot, so readyForMacroScreenshot waits exactly one cycle for it to
  # flush. nil when no macro screenshot is settling.
  macroScreenshotWarmRepaintFrame: nil
  # the running macro's generator; (re)created at macro start by the pump header
  # in Macro._addHeaderCode, cleared (nil) between macros.
  macroGenerator: nil

  # Install the linked macro code (pump header + linked verbs) with `@` = this
  # MacroToolkit instance, so the generator and the verbs it calls resolve their
  # @helpers against this collaborator. Mirrors Widget.evaluateString's
  # compile-then-eval, minus the reLayout/changed tail (installing a macro paints
  # nothing, and this collaborator has no widget methods).
  evaluateString: (codeSource) ->
    eval compileFGCode codeSource, true

  progressOnMacroSteps: ->

  noCodeLoading: ->
    true

  noInputsOngoing: ->
    world.inputEventsQueue.isEmpty()

  # Used by a macro's screenshot step (the "waitForScreenshotReady" yield in
  # Macro's pump): decide, across cycles, when the canvas is safe to capture
  # deterministically. Native: capture immediately. SWCanvas: wait until glyph
  # atlases have loaded (no text dirty), then force ONE warm-atlas repaint into
  # the software surface and wait a single doOneCycle for updateBroken (which
  # runs AFTER progressOnMacroSteps) to flush it — so the captured pixels are
  # identical run-to-run. Mirrors the screenshot settle gate in
  # AutomatorPlayer.replayTestCommands.
  readyForMacroScreenshot: ->
    return true unless window.FIZZYGUM_USE_SWCANVAS
    if world.anyTextDirty()
      return false
    if !@macroScreenshotWarmRepaintFrame?
      world.cacheForImmutableBackBuffers?.reset?()
      world.fullChanged()
      @macroScreenshotWarmRepaintFrame = WorldMorph.frameCount
      return false
    if WorldMorph.frameCount <= @macroScreenshotWarmRepaintFrame
      return false
    @macroScreenshotWarmRepaintFrame = nil
    return true

  # other useful tween functions here:
  # https://github.com/ashblue/simple-tween-js/blob/master/tween.js
  expoOut: (i, origin, distance, numberOfEvents) ->
    distance * (-Math.pow(2, -10 * i/numberOfEvents) + 1) + origin

  bringUpTestMenu_InputEvents: (millisecondsBetweenKeys = 35, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
      @syntheticEventsShortcutsAndSpecialKeys_InputEvents "F2", millisecondsBetweenKeys, startTime

  # Synthesize a special key or modifier-combo keypress. Accepts a key name or a
  # "+"-joined combo: "F2", "Enter", "Backspace", "Escape", "Tab",
  # "ArrowLeft/Right/Up/Down", "Shift+ArrowRight" (select one right), "Ctrl+S",
  # "Meta+a" (Cmd+A select-all), … The modifier state rides on the key event itself
  # (the framework's keyboard handlers read the event's shift/ctrl/alt/meta flags).
  # Plain typed text should go through syntheticEventsStringKeys_InputEvents instead.
  syntheticEventsShortcutsAndSpecialKeys_InputEvents: (whichShortcutOrSpecialKey, millisecondsBetweenKeys = 35, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    parts = whichShortcutOrSpecialKey.split "+"
    key = parts.pop()
    shiftKey = ("Shift" in parts)
    ctrlKey  = ("Ctrl" in parts) or ("Control" in parts)
    altKey   = ("Alt" in parts)
    metaKey  = ("Meta" in parts) or ("Cmd" in parts)
    # the "code" is the physical key; a 1:1 key->code is fine for synthetic events
    # (Shift uses "ShiftLeft" to match syntheticEventsStringKeys_InputEvents).
    code = if key == "Shift" then "ShiftLeft" else key
    world.inputEventsQueue.push new KeydownInputEvent key, code, shiftKey, ctrlKey, altKey, metaKey, true, startTime
    world.inputEventsQueue.push new KeyupInputEvent  key, code, shiftKey, ctrlKey, altKey, metaKey, true, startTime + millisecondsBetweenKeys

  # Press a special key/combo `count` times, staggered in time so each press is a
  # distinct event (e.g. "ArrowLeft" ×8 to walk the caret). Composes
  # syntheticEventsShortcutsAndSpecialKeys_InputEvents.
  repeatSpecialKey_InputEvents: (keyName, count, millisecondsBetweenKeys = 70, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    t = startTime
    for i in [0...count]
      @syntheticEventsShortcutsAndSpecialKeys_InputEvents keyName, 35, t
      t += millisecondsBetweenKeys

  syntheticEventsStringKeys_InputEvents: (theString, millisecondsBetweenKeys = 35, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    scheduledTimeOfEvent = startTime

    for i in [0...theString.length]

      isUpperCase = theString.charAt(i) == theString.charAt(i).toUpperCase()

      if isUpperCase
        world.inputEventsQueue.push new KeydownInputEvent "Shift", "ShiftLeft", true, false, false, false, true, scheduledTimeOfEvent
        scheduledTimeOfEvent += millisecondsBetweenKeys

      # note that the second parameter (code) we are making up, assuming a hypothetical "1:1" key->code layout
      world.inputEventsQueue.push new KeydownInputEvent theString.charAt(i), theString.charAt(i), isUpperCase, false, false, false, true, scheduledTimeOfEvent
      scheduledTimeOfEvent += millisecondsBetweenKeys

      # note that the second parameter (code) we are making up, assuming a hypothetical "1:1" key->code layout
      world.inputEventsQueue.push new KeyupInputEvent theString.charAt(i), theString.charAt(i), isUpperCase, false, false, false, true, scheduledTimeOfEvent
      scheduledTimeOfEvent += millisecondsBetweenKeys

      if isUpperCase
        world.inputEventsQueue.push new KeyupInputEvent "Shift", "ShiftLeft", false, false, false, false, true, scheduledTimeOfEvent
        scheduledTimeOfEvent += millisecondsBetweenKeys

  syntheticEventsMouseMovePressDragRelease_InputEvents: (orig, dest, millisecondsForDrag = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1) ->
    @syntheticEventsMouseMove_InputEvents orig, "left button", 100, nil, startTime, numberOfEventsPerMillisecond
    @syntheticEventsMouseDown_InputEvents "left button", startTime + 100
    @syntheticEventsMouseMove_InputEvents dest, "left button", millisecondsForDrag, orig, startTime + 100 + 100, numberOfEventsPerMillisecond
    @syntheticEventsMouseUp_InputEvents "left button", startTime + 100 + 100 + millisecondsForDrag + 100

  # This should be used if you want to drag from point A to B to C ...
  # If rather you want to just drag from point A to point B,
  # then just use syntheticEventsMouseMovePressDragRelease_InputEvents
  syntheticEventsMouseMoveWhileDragging_InputEvents: (dest, milliseconds = 1000, orig = world.hand.position(), startTime = WorldMorph.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1) ->
    @syntheticEventsMouseMove_InputEvents dest, "left button", milliseconds, orig, startTime, numberOfEventsPerMillisecond

  # mouse moves need an origin and a destination, so we
  # need to place the mouse in _some_ place to begin with
  # in order to do that.
  syntheticEventsMousePlace_InputEvents: (place = new Point(0,0), scheduledTimeOfEvent = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    world.inputEventsQueue.push new MousemoveInputEvent place.x, place.y, 0, 0, false, false, false, false, true, scheduledTimeOfEvent

  syntheticEventsMouseMove_InputEvents: (dest, whichButton = "no button", milliseconds = 1000, orig = world.hand.position(), startTime = WorldMorph.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1) ->
    if whichButton == "left button"
      button = 0
      buttons = 1
    else if whichButton == "no button"
      button = 0
      buttons = 0
    else if whichButton == "right button"
      button = 0
      buttons = 2
    else
      debugger
      throw "syntheticEventsMouseMove_InputEvents: whichButton is unknown"

    if dest instanceof Widget
      dest = dest.center()

    if orig instanceof Widget
      orig = orig.center()

    numberOfEvents = milliseconds * numberOfEventsPerMillisecond
    for i in [0...numberOfEvents]
      scheduledTimeOfEvent = startTime + i/numberOfEventsPerMillisecond
      nextX = Math.round @expoOut i, orig.x, (dest.x-orig.x), numberOfEvents
      nextY = Math.round @expoOut i, orig.y, (dest.y-orig.y), numberOfEvents
      if nextX != prevX or nextY != prevY
        prevX = nextX
        prevY = nextY
        #console.log nextX + " " + nextY + " scheduled at: " + scheduledTimeOfEvent
        world.inputEventsQueue.push new MousemoveInputEvent nextX, nextY, button, buttons, false, false, false, false, true, scheduledTimeOfEvent

  syntheticEventsMouseClick_InputEvents: (whichButton = "left button", milliseconds = 100, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseDown_InputEvents whichButton, startTime
    @syntheticEventsMouseUp_InputEvents whichButton, startTime + milliseconds

  # A SHIFT-modified left click: the same down+up as syntheticEventsMouseClick_InputEvents, but with the
  # event's shiftKey flag set (the 4th boolean of Mouse{down,up}InputEvent — button, buttons, ctrlKey,
  # shiftKey, altKey, metaKey, isFromAutomator, time). A click carrying shiftKey makes an editable
  # StringMorph2/TextMorph2 EXTEND its selection to the click point (mouseClickLeft reads shiftKey) instead
  # of just repositioning the caret. Left button only (down buttons=1, up buttons=0).
  syntheticEventsMouseShiftClick_InputEvents: (milliseconds = 100, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    world.inputEventsQueue.push new MousedownInputEvent 0, 1, false, true, false, false, true, startTime
    world.inputEventsQueue.push new MouseupInputEvent 0, 0, false, true, false, false, true, startTime + milliseconds

  syntheticEventsMouseDown_InputEvents: (whichButton = "left button", startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    if whichButton == "left button"
      button = 0
      buttons = 1
    else if whichButton == "right button"
      button = 2
      buttons = 2
    else
      debugger
      throw "syntheticEventsMouseDown_InputEvents: whichButton is unknown"

    world.inputEventsQueue.push new MousedownInputEvent button, buttons, false, false, false, false, true, startTime

  syntheticEventsMouseUp_InputEvents: (whichButton = "left button", startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    if whichButton == "left button"
      button = 0
      buttons = 0
    else if whichButton == "right button"
      button = 2
      buttons = 0
    else
      debugger
      throw "syntheticEventsMouseUp_InputEvents: whichButton is unknown"

    world.inputEventsQueue.push new MouseupInputEvent button, buttons, false, false, false, false, true, startTime

  moveToAndClick_InputEvents: (positionOrWidget, whichButton = "left button", milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents positionOrWidget, "no button", milliseconds, nil, startTime, nil
    @syntheticEventsMouseClick_InputEvents whichButton, 100, startTime + milliseconds + 100

  # Move to a point/widget then MOUSE DOWN and HOLD — the press half of a click, scheduled AFTER the move
  # completes (like moveToAndClick_InputEvents, but with no release). Use it when the press ITSELF produces
  # the state to capture, so the screenshot must be taken before the release: a mouse-DOWN (not the full
  # click) dismisses an unpinned menu cascade (ActivePointerWdgt.cleanupMenuWdgts), and a mouse-DOWN drops a
  # float-dragged morph (processMouseDown -> drop). Pattern: `@moveToAndMouseDown_InputEvents target` ->
  # `yield "waitNoInputsOngoing"` -> `takeScreenshot_InputEvents_Macro "…"` (captures with the button still
  # held) -> `@syntheticEventsMouseUp_InputEvents()` -> `yield "waitNoInputsOngoing"`.
  moveToAndMouseDown_InputEvents: (positionOrWidget, whichButton = "left button", milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents positionOrWidget, "no button", milliseconds, nil, startTime, nil
    @syntheticEventsMouseDown_InputEvents whichButton, startTime + milliseconds + 100

  # Click a fractional point [fx, fy] inside a widget — located either by a widget
  # reference or by a recorded text-description identifier [desc, occ, total]. Mirrors
  # how a recorded MouseButtonChange replays (AutomatorEventCommandMouseButtonChange):
  # the landing point is (left + round(width*fx), top + round(height*fy)) of the LIVE
  # widget, so it follows the widget if it has moved/resized. The linchpin verb for
  # migrating a recorded click whose target isn't a menu item.
  # Resolve a [widget | text-description identifier | Point] + an [fx, fy] fraction to an
  # absolute world Point inside that widget. Shared by the fractional click/double/triple verbs.
  pointAtFractionOf: (widgetOrIdentifier, fraction) ->
    widget = if (typeof widgetOrIdentifier == "string") or (widgetOrIdentifier instanceof Array)
      @findWidgetByTextDescription widgetOrIdentifier
    else
      widgetOrIdentifier
    new Point (Math.round(widget.width() * fraction[0]) + widget.left()), (Math.round(widget.height() * fraction[1]) + widget.top())

  moveToAndClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction, whichButton = "left button", milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClick_InputEvents (@pointAtFractionOf widgetOrIdentifier, fraction), whichButton, milliseconds, startTime

  # Double- / triple-click at a fractional point inside a located widget. Mirrors
  # AutomatorEventCommandMouse{Double,Triple}Click: it moves the hand and calls
  # world.hand.process{Double,Triple}Click() DIRECTLY — double/triple clicks are recognised by
  # the hand, NOT replayed as queued input events — so these take effect immediately (hence no
  # `_InputEvents` suffix and no yield needed before a following screenshot, which waits anyway).
  # Call after `yield "waitNoInputsOngoing"`. Effective only in turbo playback (macro tests use it).
  doubleClickAtFractionOf: (widgetOrIdentifier, fraction = [0.5, 0.5]) ->
    world.hand.fullRawMoveTo (@pointAtFractionOf widgetOrIdentifier, fraction)
    world.hand.processDoubleClick()

  tripleClickAtFractionOf: (widgetOrIdentifier, fraction = [0.5, 0.5]) ->
    world.hand.fullRawMoveTo (@pointAtFractionOf widgetOrIdentifier, fraction)
    world.hand.processTripleClick()

  # SHIFT+left-click at a fractional point inside a located widget — move the pointer there (no button),
  # then click with Shift held. In editable text a plain click sets the caret while a shift-click EXTENDS the
  # selection from the caret to the click point; so the pattern is a plain moveToAndClickAtFractionOf to drop
  # the anchor caret, then one or more shiftClickAtFractionOf to grow the selection. The selection-extend
  # sibling of the double-/triple-click verbs. Queues input events — follow with `yield "waitNoInputsOngoing"`.
  shiftClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents (@pointAtFractionOf widgetOrIdentifier, fraction), "no button", milliseconds, nil, startTime, nil
    @syntheticEventsMouseShiftClick_InputEvents 100, startTime + milliseconds + 100

  # Mouse-WHEEL scroll over a located widget (by widget reference or a recorded text-description
  # identifier). Mirrors AutomatorEventCommandWheel: it moves the hand over the widget and calls
  # world.hand.processWheel() DIRECTLY — a wheel is dispatched by the hand to the nearest widget under
  # the pointer that owns a `wheel` method (e.g. a ScrollPanelWdgt), NOT replayed as a queued input
  # event — so, like the multi-click verbs, this is a direct hand op (no `_InputEvents` suffix, no
  # yield needed before a following screenshot, which waits anyway). A POSITIVE deltaY scrolls the
  # content DOWN; deltaX scrolls horizontally. Effective only in turbo playback (macro tests use it);
  # call after `yield "waitNoInputsOngoing"`.
  wheelOn: (widgetOrIdentifier, deltaY, deltaX = 0, fraction = [0.5, 0.5]) ->
    world.hand.fullRawMoveTo (@pointAtFractionOf widgetOrIdentifier, fraction)
    world.hand.processWheel deltaX, deltaY, 0, false, nil, nil

  # Click a SliderMorph's TRACK (its background, OUTSIDE the button) at a point a fraction along its
  # length, to JUMP the slider button there. For a scroll panel's scrollbar — a ScrollPanelWdgt's @vBar
  # / @hBar (both SliderMorphs) — this scrolls the content to that position: SliderMorph.mouseDownLeft,
  # when the slider's parent is a ScrollPanelWdgt (or PromptMorph), non-float-drags the button to the
  # click point (ActivePointerWdgt.nonFloatDragWdgtFarAwayToHere), and a click leaves it there. `fraction`
  # is [fx, fy] of the slider's bounds — for a vertical scrollbar pass e.g. [0.5, 0.8] (80% down the
  # track); for a horizontal one [0.8, 0.5]. Queues input events — follow with `yield
  # "waitNoInputsOngoing"`. A slider NOT parented to a scroll panel ignores the track click (it escalates
  # the event) — that is the negative companion behaviour (sliderNotOnScrollPanelBackground…). Composes
  # moveToAndClickAtFractionOf_InputEvents; sliderOrIdentifier may be a widget reference (e.g. doc.vBar)
  # or a recorded text-description identifier.
  clickOnSliderTrackAtFraction_InputEvents: (sliderOrIdentifier, fraction, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClickAtFractionOf_InputEvents sliderOrIdentifier, fraction, "left button", milliseconds, startTime

  # DRAG a SliderMorph's button to a fractional position along its track — a press-drag-release ON THE
  # BUTTON (not the track). The button is a NON-float-drag child of the slider (SliderButtonMorph.
  # detachesWhenDragged returns false while its parent is a SliderMorph), so this moves the button within
  # the track via SliderButtonMorph.nonFloatDragging, which calls SliderMorph.updateValue -> setValue ->
  # updateTarget every frame the value changes — so if the slider has a controller target set (via
  # "set target"), it drives target[setter](value) LIVE as it is dragged. This is the controller-DRAG
  # sibling of clickOnSliderTrackAtFraction_InputEvents (which only JUMPS the button via a track click, and
  # only when the slider is parented to a ScrollPanelWdgt/PromptMorph); a free-standing controller slider
  # responds to dragging its button, not to track clicks. `fraction` is a [fx, fy] point of the SLIDER's
  # bounds = the destination of the drag along the track (for a vertical slider, vary fy; default sliders
  # have smallestValueIsAtBottomEnd false, so a larger fy = a larger value). Queues input events — follow
  # with `yield "waitNoInputsOngoing"`. sliderOrIdentifier may be a widget reference or a recorded
  # text-description identifier.
  dragSliderButtonToFraction_InputEvents: (sliderOrIdentifier, fraction, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    slider = if (typeof sliderOrIdentifier == "string") or (sliderOrIdentifier instanceof Array)
      @findWidgetByTextDescription sliderOrIdentifier
    else
      sliderOrIdentifier
    buttonCentre = @pointAtFractionOf slider.button, [0.5, 0.5]
    trackPoint = @pointAtFractionOf slider, fraction
    @syntheticEventsMouseMovePressDragRelease_InputEvents buttonCentre, trackPoint, milliseconds, startTime

  # Clipboard CUT / COPY / PASTE for the active editing caret. Fizzygum keeps NO internal clipboard —
  # cut/copy/paste are normally driven by the browser's real clipboard EVENTS, which synthetic key
  # events can't fire (and Meta+x/c/v have no caret key-handler). So, exactly like the harness'
  # AutomatorEventCommandCut/Copy/Paste, these call world.caret.process{Cut,Copy,Paste} DIRECTLY and
  # carry the text in a macro-local variable (no OS clipboard involved). cutSelection / copySelection
  # RETURN the currently-selected text (capture it, paste it back later); pasteText inserts text at the
  # caret. Direct ops (no `_InputEvents` suffix): select first (Shift+Arrow) and `yield
  # "waitNoInputsOngoing"` so the selection is realised before cutting/copying.
  cutSelection: ->
    text = world.caret?.target?.selection()
    world.caret?.processCut text
    text

  copySelection: ->
    text = world.caret?.target?.selection()
    world.caret?.processCopy text
    text

  pasteText: (text) ->
    world.caret?.processPaste text

  # Drag a resize/move HANDLE (one of the handles shown after a widget's "resize/move..." menu
  # item) from its centre to a destination Point. Handles resize/move the target via NON-float
  # dragging (HandleMorph.nonFloatDragging → setExtent / fullMoveTo), so this is a real
  # press-drag-release. handleType picks the handle: "resizeBothDimensionsHandle" (bottom-right
  # corner — resizes both dimensions), "moveHandle", "resizeHorizontalHandle", "resizeVerticalHandle".
  dragResizeMoveHandleTo_InputEvents: (handleType, destination, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    handle = world.topWdgtSuchThat (item) -> (item instanceof HandleMorph) and (item.type == handleType)
    @syntheticEventsMouseMovePressDragRelease_InputEvents handle.center(), destination, milliseconds, startTime

  # Float-DRAG a widget (by reference, or by a recorded text-description identifier) and drop it at a
  # destination — a Point, or another widget / identifier (dropped on that target's centre). Presses at
  # the widget's centre and drags past the grab threshold so the widget is picked up onto the hand, then
  # releases over the destination. Use it to drop a widget INTO a container that accepts drops — e.g. a
  # SimpleDocumentScrollPanel with editing enabled re-parents the dropped widget as a flowing paragraph.
  dragWidgetTo_InputEvents: (widgetOrIdentifier, destination, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    source = if (typeof widgetOrIdentifier == "string") or (widgetOrIdentifier instanceof Array)
      @findWidgetByTextDescription widgetOrIdentifier
    else
      widgetOrIdentifier
    dropPoint = if destination instanceof Point then destination else @pointAtFractionOf destination, [0.5, 0.5]
    @syntheticEventsMouseMovePressDragRelease_InputEvents source.center(), dropPoint, milliseconds, startTime

  openMenuOf_InputEvents: (widget, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClick_InputEvents widget, "right button", milliseconds, startTime

  # Close a WindowWdgt by clicking the close button (the X) in its window bar. Every WindowWdgt builds
  # a `.closeButton` (a CloseIconButtonMorph at its top-left); clicking it runs the button's actOnClick
  # → the window's closeFromWindowBar()/close(). The reusable window-chrome pattern: get a window (by a
  # kept reference, or by class + its `internal` flag) and close it through its real control button, as
  # a user would. Queues input events — follow with `yield "waitNoInputsOngoing"`.
  closeWindow_InputEvents: (windowWidget) ->
    @moveToAndClick_InputEvents windowWidget.closeButton

  # Collapse or uncollapse a WindowWdgt by clicking the collapse/uncollapse control in its window bar.
  # Every WindowWdgt builds a `.collapseUncollapseSwitchButton` (a SwitchButtonMorph that toggles between a
  # CollapseIconButtonMorph and an UncollapseIconButtonMorph): clicking it when expanded collapses the
  # window to just its bar (contents.collapse()), and clicking it again — the switch now shows the
  # uncollapse icon — restores it. So this one verb both collapses and uncollapses, depending on the
  # window's current state. The window-chrome sibling of closeWindow_InputEvents. Queues input events —
  # follow with `yield "waitNoInputsOngoing"`.
  collapseOrUncollapseWindow_InputEvents: (windowWidget) ->
    @moveToAndClick_InputEvents windowWidget.collapseUncollapseSwitchButton

  # Resize a WindowWdgt by dragging its resize handle to a destination. Every WindowWdgt builds a `.resizer`
  # (a HandleMorph laid out at its bottom-right corner); a NON-float press-drag-release on it resizes the
  # window (HandleMorph.nonFloatDragging → setExtent on the window). The window-chrome sibling of close/
  # collapse: reach the window's OWN resize control by reference (vs hunting a HandleMorph by coordinates —
  # several windows each have one). destination may be a Point or another widget (dragged to its centre).
  # Queues input events — follow with `yield "waitNoInputsOngoing"`.
  dragWindowResizerTo_InputEvents: (windowWidget, destination, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    dropPoint = if destination instanceof Point then destination else @pointAtFractionOf destination, [0.5, 0.5]
    @syntheticEventsMouseMovePressDragRelease_InputEvents windowWidget.resizer.center(), dropPoint, milliseconds, startTime

  getMostRecentlyOpenedMenu: ->
    # gets the last element added to the "freshlyCreatedPopUps" set
    # (Sets keep order of insertion)
    Array.from(world.freshlyCreatedPopUps).pop()

  getTextMenuItemFromMenu: (theMenu, theLabel) ->
    theMenu.topWdgtSuchThat (item) ->
      if item.labelString?
        item.labelString == theLabel
      else
        false

  # Like getTextMenuItemFromMenu but matches by label PREFIX. Use it when a menu item's full label
  # carries a suffix you should not depend on — e.g. the "attach..." target menu labels each candidate
  # `<morph>.toString() + " ➜"`, so a RectangleMorph reads "a RectangleMorph#1 ➜" (an instance number +
  # a trailing arrow). Match the stable head ("a RectangleMorph") instead of the exact string, and only
  # the intended target is hit even when the menu also lists the World and the morph's own handle.
  getTextMenuItemFromMenuByPrefix: (theMenu, thePrefix) ->
    theMenu.topWdgtSuchThat (item) ->
      if item.labelString?
        item.labelString.startsWith thePrefix
      else
        false

  getTextMenuItemFromMenuByContains: (theMenu, theSubstring) ->
    theMenu.topWdgtSuchThat (item) ->
      if item.labelString?
        item.labelString.includes theSubstring
      else
        false

  # Move to and click a menu/prompt item by its label, in a SPECIFIC menu you already hold a reference
  # to. Prefer this over moveToItemOfTopMenuAndClick_InputEvents whenever you interact with a popup more
  # than once (e.g. click a slider/palette INSIDE a prompt, THEN click its "Ok"): getMostRecentlyOpenedMenu
  # reads world.freshlyCreatedPopUps, which EVERY mouseUp clears (ActivePointerWdgt.processMouseUp), so it
  # is only valid for the FIRST interaction after a popup opens. Capture the popup reference while it is
  # still fresh (right after it opens) and drive its later items through this method.
  moveToItemOfMenuAndClick_InputEvents: (theMenu, theLabel) ->
    theItem = @getTextMenuItemFromMenu theMenu, theLabel
    @moveToAndClick_InputEvents theItem

  moveToItemOfTopMenuAndClick_InputEvents: (theLabel) ->
    @moveToItemOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), theLabel

  # Move to and click the menu item whose label STARTS WITH a prefix, in a menu you hold a reference to.
  # The prefix sibling of moveToItemOfMenuAndClick_InputEvents — for menus whose item labels carry a
  # variable suffix (the "attach..."/"choose target:" menu labels each target `toString() + " ➜"`), match
  # the stable class-name head so you pick the intended target rather than the first/Nth item.
  moveToItemStartingWithOfMenuAndClick_InputEvents: (theMenu, thePrefix) ->
    theItem = @getTextMenuItemFromMenuByPrefix theMenu, thePrefix
    @moveToAndClick_InputEvents theItem

  # Move to and click the menu item whose label CONTAINS a substring, in a menu you hold a reference to.
  # The substring sibling of the prefix verb — for items whose label carries a leading decoration the prefix
  # can't match, e.g. a checkmark toggle ("soft wrap".tick() renders "✓ soft wrap"): match "soft wrap".
  moveToItemContainingOfMenuAndClick_InputEvents: (theMenu, theSubstring) ->
    theItem = @getTextMenuItemFromMenuByContains theMenu, theSubstring
    @moveToAndClick_InputEvents theItem

  # Click a menu's title bar (its MenuHeader, reachable as menu.label) to PIN the menu open.
  # MenuHeader.mouseClickLeft -> firstParentThatIsAPopUp().pinPopUp: a pinned menu clears its
  # kill-on-click-outside flags and removes itself from world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren,
  # so a subsequent click on the empty desktop no longer dismisses it (an UNpinned menu would vanish);
  # the pinned menu also gets a tighter shadow. Pass a menu reference (e.g. getMostRecentlyOpenedMenu()).
  clickMenuHeaderToPin_InputEvents: (theMenu) ->
    @moveToAndClick_InputEvents theMenu.label

  # Assert the number of items in the most-recently-opened menu (separators counted too,
  # matching the recorded harness' testNumberOfItems). A macro-level ASSERTION: it pushes no
  # input events and does not yield, so call it once the menu is open (`yield
  # "waitNoInputsOngoing"` first). Locates the menu by MEANING (not by pointer position) and
  # records PASS/FAIL via recordMacroAssertion, so a mismatch fails the test exactly as a
  # screenshot mismatch would.
  assertTopMenuItemCount: (expectedCount) ->
    theMenu = @getMostRecentlyOpenedMenu()
    found = theMenu?.testNumberOfItems()
    world.automator.player.recordMacroAssertion (found == expectedCount), "top menu item count", expectedCount, found

  # Topmost widget matching either a class-name string (compared via
  # morphClassString) or a class object (compared via instanceof).
  findTopWidgetByClassNameOrClass: (widgetNameOrClass) ->
    if typeof widgetNameOrClass == "string"
      world.topWdgtSuchThat (item) -> item.morphClassString() == widgetNameOrClass
    else
      world.topWdgtSuchThat (item) -> item instanceof widgetNameOrClass

  # Topmost widget whose getTextDescription() matches a recorded identifier triple
  # [textDescription, occurrenceIndex, totalOccurrences] — the SAME stable locator the
  # old recorded tests use (world.getMorphViaTextLabel / Widget.identifyViaTextLabel).
  # Accepts a bare string (treated as [string, 0, 1]). This is the linchpin for migrating
  # recorded tests: every recorded click already stores this triple (as
  # morphIdentifierViaTextLabel), so a migrated macro can re-find the very same widget.
  findWidgetByTextDescription: (identifier) ->
    identifier = [identifier, 0, 1] if typeof identifier == "string"
    world.getMorphViaTextLabel identifier

  calculateVertBarMovement: (vBar, index, total) ->
    vBarHandle = vBar.children[0]
    vBarHandleCenter = vBarHandle.center()

    highestHandlePosition = vBar.top()
    lowestHandlePosition = vBar.bottom() - vBarHandle.height()


    highestHandleCenterPosition = highestHandlePosition + vBarHandle.height()/2
    lowestHandleCenterPosition = lowestHandlePosition + vBarHandle.height()/2

    handleCenterRange = lowestHandleCenterPosition - highestHandleCenterPosition

    handleCenterOffset = Math.round index * handleCenterRange / (total-1)

    [vBarHandleCenter, vBarHandleCenter.translateBy new Point(0,handleCenterOffset)]

  bringListItemFromTopInspectorInView_InputEvents: (listItemString) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorMorph2
    list = inspectorNaked.list
    elements = list.elements

    vBar = list.vBar
    index = elements.indexOf listItemString
    total = elements.length
    [vBarCenterFromHere, vBarCenterToHere] = @calculateVertBarMovement vBar, index, total

    @syntheticEventsMouseMovePressDragRelease_InputEvents vBarCenterFromHere, vBarCenterToHere

  clickOnListItemFromTopInspector_InputEvents: (listItemString, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorMorph2

    list = inspectorNaked.list

    entry = list.topWdgtSuchThat (item) ->
      if item.text?
        item.text == listItemString
      else
        false
    entryTopLeft = entry.topLeft()

    @moveToAndClick_InputEvents entryTopLeft.translateBy(new Point 10, 2), "left button", milliseconds, startTime


  clickOnCodeBoxFromTopInspectorAtCodeString_InputEvents: (codeString, occurrenceNumber = 1, after = true,  milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorMorph2

    slotCoords = inspectorNaked.textMorph.text.getNthPositionInStringBeforeOrAfter codeString, occurrenceNumber, after

    clickPosition = inspectorNaked.textMorph.slotCoordinates(slotCoords).translateBy new Point 3,3

    @moveToAndClick_InputEvents clickPosition, "left button", milliseconds, startTime

  clickOnSaveButtonFromTopInspector_InputEvents: (milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorMorph2
    saveButton = inspectorNaked.saveButton
    @moveToAndClick_InputEvents saveButton, "left button", milliseconds, startTime

  bringcodeStringFromTopInspectorInView_InputEvents: (codeString, occurrenceNumber = 1, after = true) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorMorph2

    slotCoords = inspectorNaked.textMorph.text.getNthPositionInStringBeforeOrAfter codeString, occurrenceNumber, after

    textScrollPane = inspectorNaked.topWdgtSuchThat (item) -> item.morphClassString() == "SimplePlainTextScrollPanelWdgt"
    textMorph = inspectorNaked.textMorph

    vBar = textScrollPane.vBar
    index = textMorph.slotRowAndColumn(slotCoords)[0]
    total = textMorph.wrappedLines.length
    [vBarCenterFromHere, vBarCenterToHere] = @calculateVertBarMovement vBar, index, total

    @syntheticEventsMouseMovePressDragRelease_InputEvents vBarCenterFromHere, vBarCenterToHere

  # The reusable "verb" library for high-level macro tests: returns a Set of
  # macro SUBROUTINES (bringUpInspector, clickMenuItemOfWidget, takeScreenshot,
  # …) that any test's main macro can call by name. A macro test ships only its
  # own main macro (as a string on its AutomatorEventCommandStartMacro command);
  # that command links the main macro against THIS shared set, so the common
  # navigation/assertion verbs aren't copied into every test. The verbs compose
  # the @..._InputEvents primitives defined above.
  standardMacroSubroutines: ->
    # When does it make sense to generate events "just via functions" vs.
    # needing a macro?
    #
    # A function is completely executed on the spot (i.e. right at the moment
    # of invocation, within a specific world cycle). So it can generate events
    # in the future (as those are put in the events queue), but since it's
    # completely executed on the spot, it can't see the
    # state of the world in the future. E.g. a function can generate
    # several mouse actions in the future, but it can't check the
    # existence/position of a menu item in the future.
    #
    # Conversely, a macro is executed in steps across multiple cycles,
    # and can see the state of the world as it changes across cycles.
    # E.g. a macro can open a menu, then check the existence and position
    # of a menu item, then click on it.
    #
    # So, if one needs to generate events for the future and can do so
    # "blindly" (e.g. a
    # mouse drag/drop between two known position), then use a function
    # (and not a macro). If, conversely, one needs to check the state
    # of the world as the actions unfold, then use a macro.
    #
    # Note that behind the scenes the macros are implemented as generators,
    # and the "cross-cycle" execution is done via yields/next()
    #
    # The implications:
    #   * a macro can call functions, but functions can't call macros
    #   * a macro should either call another macro or have a yield of some
    #     sort. If it doesn't do either thing, something is off as it will
    #     be executed one-shot in a single call (and single cycle)
    #     so it should probably be a function.
    #
    # Examples of macros (potentially using functions):
    #   - opening a menu of a widget AND clicking on one of its items
    #   - opening inspector for a widget
    #   - opening inspector for a widget, changing a method, then
    #     clicking "save"
    #   - scrolling via wheel till the end of a document (as it needs to
    #     check status of scroll)
    #
    # Examples of functions:
    #   - moving an icon to the bin
    #   - closing the top window
    #   - opening the menu of a widget (by moving on it and right-clicking)
    #   - moving pointer to a specific entry of top menu and clicking it
    #   - scrolling via vertical bar till the end of a document (no need to check
    #     status, can just move the bar till the known end of its vertical extent)
    #
    # A macro should take care of "finishing" when the whole macro is executed
    # i.e. with all the intended actions completed and no inputs remaining in
    # the "future events" queue. Hence, the caller of a macro
    # can assume that no further "waits" are needed after calling it.

    macroSubroutines = new Set

    macroSubroutines.add Macro.fromString """
      bringUpInspector_InputEvents_Macro = (whichWidget) ->
        clickMenuItemOfWidget_InputEvents_Macro whichWidget, "dev ➜"
        @moveToItemOfTopMenuAndClick_InputEvents "inspect"
        yield "waitNoInputsOngoing"
    """

    macroSubroutines.add Macro.fromString """
      bringUpInspectorAndSelectListItem_InputEvents_Macro  = (whichWidget, whichItem) ->
        bringUpInspector_InputEvents_Macro whichWidget
        bringInViewAndClickOnListItemFromTopInspector_InputEvents_Macro whichItem
    """

    macroSubroutines.add Macro.fromString """
      bringInViewAndClickOnListItemFromTopInspector_InputEvents_Macro = (whichItem) ->
        @bringListItemFromTopInspectorInView_InputEvents whichItem
        yield "waitNoInputsOngoing" 
        @clickOnListItemFromTopInspector_InputEvents whichItem
        yield "waitNoInputsOngoing" 
    """

    macroSubroutines.add Macro.fromString """
      clickMenuItemOfWidget_InputEvents_Macro = (whichWidget, whichItem) ->
        @openMenuOf_InputEvents whichWidget
        yield "waitNoInputsOngoing"
        @moveToItemOfTopMenuAndClick_InputEvents whichItem
        yield "waitNoInputsOngoing"
    """

    # Patch-programming "set target": wire a CONTROLLER widget (a ColorPaletteMorph, GrayPaletteMorph,
    # SliderMorph, StringMorph2, … — anything augmented with ControllerMixin) to drive a property of
    # another widget. Right-click the controller -> "set target" (openTargetSelector) opens a
    # "choose target:" menu of the widgets whose bounds INTERSECT the controller (so the controller must
    # OVERLAP the intended target), each labelled `target.toString() + " ➜"`; pick it by class-name PREFIX.
    # That opens a "choose target property:" menu of the target's setters (e.g. "color"); pick the property.
    # Afterwards, acting on the controller (clicking a palette, dragging a slider) calls
    # target[setter](value). Each menu is captured fresh from getMostRecentlyOpenedMenu() right after it
    # opens (every mouseUp clears world.freshlyCreatedPopUps).
    macroSubroutines.add Macro.fromString """
      setControllerTargetToWidgetProperty_InputEvents_Macro = (controllerWidget, targetClassNamePrefix, propertyLabel, controllerMenuFraction = [0.5, 0.5], controllerHierarchyPrefix = nil) ->
        @moveToAndClickAtFractionOf_InputEvents controllerWidget, controllerMenuFraction, "right button"
        yield "waitNoInputsOngoing"
        # When the controller is INSIDE a container (its parent is not the world), right-clicking it opens the
        # ancestor HIERARCHY menu ("a SliderMorph ➜", "a Panel ➜", …) rather than the controller's own menu —
        # so first navigate into the controller's own submenu by its class-name prefix. (A world-child
        # controller opens its menu directly, so this is skipped.)
        if controllerHierarchyPrefix?
          @moveToItemStartingWithOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), controllerHierarchyPrefix
          yield "waitNoInputsOngoing"
        @moveToItemOfTopMenuAndClick_InputEvents "set target"
        yield "waitNoInputsOngoing"
        @moveToItemStartingWithOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), targetClassNamePrefix
        yield "waitNoInputsOngoing"
        @moveToItemOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), propertyLabel
        yield "waitNoInputsOngoing"
    """

    # Window-in-window fixture, SHARED by the window-content tests so the setup lives in ONE place (a fix is made
    # once; both tests build the identical composite). buildExternalAndFreeInternalWindow_Macro constructs an empty
    # EXTERNAL window (left) and a free INTERNAL window (right) at a canonical geometry and RETURNS both, so a caller
    # can screenshot the separate state first (a macro subroutine can return a value — `x = aMacro()` is rewritten to
    # `x = yield from aMacro.call this`, and yield-from propagates the generator's return value).
    # dropInternalWindowIntoExternalWindow_InputEvents_Macro then carries the internal window on the hand (pickUp +
    # a no-button move to the external window's content area + a click to drop) so it becomes the external window's
    # fitted CONTENT, and RETURNS the (now composite) external window for the caller to screenshot/resize.
    # NB: these shared verbs deliberately take NO screenshots — only a test's own mainMacroSource/extraSubroutineSources
    # are scanned for reference-image names, so the per-test assertions stay in each test's main macro.
    macroSubroutines.add Macro.fromString """
      buildExternalAndFreeInternalWindow_Macro = ->
        extWin = new WindowWdgt nil, nil, nil
        extWin.rawSetExtent new Point 290, 240
        extWin.fullRawMoveTo new Point 75, 90
        world.add extWin
        intWin = new WindowWdgt nil, nil, nil, true
        intWin.rawSetExtent new Point 250, 160
        intWin.fullRawMoveTo new Point 600, 200
        world.add intWin
        yield "waitNoInputsOngoing"
        return [extWin, intWin]
    """

    macroSubroutines.add Macro.fromString """
      dropInternalWindowIntoExternalWindow_InputEvents_Macro = (extWin, intWin) ->
        intWin.pickUp()
        @syntheticEventsMouseMove_InputEvents (@pointAtFractionOf extWin, [0.5, 0.55]), "no button", 700
        yield "waitNoInputsOngoing"
        @syntheticEventsMouseClick_InputEvents()
        yield "waitNoInputsOngoing"
        return extWin
    """

    macroSubroutines.add Macro.fromString """
      takeScreenshot_InputEvents_Macro = (screenShotImageName) ->
        yield "waitNoInputsOngoing"
        yield "waitForScreenshotReady"
        world.automator.player.compareScreenshots screenShotImageName
    """

    macroSubroutines

