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

  # Click a fractional point [fx, fy] inside a widget — located either by a widget
  # reference or by a recorded text-description identifier [desc, occ, total]. Mirrors
  # how a recorded MouseButtonChange replays (AutomatorEventCommandMouseButtonChange):
  # the landing point is (left + round(width*fx), top + round(height*fy)) of the LIVE
  # widget, so it follows the widget if it has moved/resized. The linchpin verb for
  # migrating a recorded click whose target isn't a menu item.
  moveToAndClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction, whichButton = "left button", milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    widget = if (typeof widgetOrIdentifier == "string") or (widgetOrIdentifier instanceof Array)
      @findWidgetByTextDescription widgetOrIdentifier
    else
      widgetOrIdentifier
    x = Math.round(widget.width() * fraction[0]) + widget.left()
    y = Math.round(widget.height() * fraction[1]) + widget.top()
    @moveToAndClick_InputEvents (new Point x, y), whichButton, milliseconds, startTime

  openMenuOf_InputEvents: (widget, milliseconds = 1000, startTime = WorldMorph.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClick_InputEvents widget, "right button", milliseconds, startTime

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

  moveToItemOfTopMenuAndClick_InputEvents: (theLabel) ->
    theMenu = @getMostRecentlyOpenedMenu()
    theItem = @getTextMenuItemFromMenu theMenu, theLabel
    @moveToAndClick_InputEvents theItem

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

    macroSubroutines.add Macro.fromString """
      takeScreenshot_InputEvents_Macro = (screenShotImageName) ->
        yield "waitNoInputsOngoing"
        yield "waitForScreenshotReady"
        world.automator.player.compareScreenshots screenShotImageName
    """

    macroSubroutines

