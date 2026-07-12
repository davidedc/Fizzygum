# this file is only needed for Macros

# MacroToolkit — the framework-side support for high-level "macro" SystemTests,
# lifted out of WorldWdgt so the macro machinery has a cohesive, documented home.
# Delegation, not a mixin: the world HAS-A one, reachable as world.macroToolkit
# (created in the WorldWdgt constructor, guarded by `if MacroToolkit?` so the
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

  # False-double-click guard state (see guardedClickStart). The most recent scheduled
  # CLICK gesture's last-release ABSOLUTE virtual time + the pointer position it landed
  # on; and currentPointerTarget = the last scheduled move's destination (= where the
  # next click lands). Used so two distinct same-spot single clicks can be pushed past
  # the hand's 300ms EVENT-TIME double-click window, now that fast-test recognition is ungated.
  # nil until the first move/click of a macro (fresh per test — ResetWorld rebuilds the
  # toolkit).
  lastClickGestureUpTime: nil
  lastClickGesturePosition: nil
  currentPointerTarget: nil

  # ─── Global playback SPEED ──────────────────────────────────────────────────
  # ONE global, three-level speed control the macro EVENT GENERATORS honour.
  # Set once at boot from ?speed=normal|fast|fastest (parsed in
  # src/boot/globalFunctions.coffee → window.FIZZYGUM_MACRO_SPEED); browser
  # default "normal" (watchable), the headless runner requests "fastest".
  #
  # There are TWO independent axes (do not conflate — see src/macros/CLAUDE.md):
  #   • SPAN  = a verb's gesture `milliseconds` × spanFactor. Because synthetic
  #     events drain over ~their timestamp span of REAL wall-clock (the per-cycle
  #     virtual clock IS wall-clock; see WorldWdgt.playQueuedEvents), span is the
  #     ONLY real speed lever — compressing it is what makes a headless sweep fast.
  #   • COUNT = events-per-millisecond → intra-gesture path smoothness / sampling
  #     fidelity. Thinning count is PATH-RISKY (a drag that must pass over a drop
  #     target, a hover-highlight along a path, the auto-scroll edge band can be
  #     skipped), so path-dependent verbs floor their own count.
  # Non-scaled timings (the real-time settle channel) live OUTSIDE this: a numeric
  # `yield N` in a macro waits N ms of real wall-clock and reads no speed level,
  # and readyForMacroScreenshot gates on atlas/momentum settle — both unaffected.
  # The default level when ?speed= is absent/invalid. The EFFECTIVE level is
  # resolved lazily (see @currentSpeed) — deliberately NOT in a static value
  # initializer, so nothing but a plain literal runs at class-definition time.
  @defaultSpeed: "normal"

  # spanFactor per level — multiplies EVERY gesture's time-offset from the cycle
  # start (→ wall-clock speed; applied at the single push chokepoint queueInputEvent).
  # "normal" = 1.0 reproduces the historical timing exactly, byte-for-byte. COUNT
  # (intra-gesture path sampling) is deliberately NOT thinned: it stays full at
  # every level, so the deduped pixel SET a gesture emits is speed-INVARIANT and
  # only the timestamps (hence drain rate) change. That invariance is what lets ONE
  # set of committed references pass at all three speeds.
  @spanFactors:
    normal:  1.0
    fast:    0.3
    fastest: 0.03

  # NON-scaled guard window, comfortably wider than the hand's 300ms EVENT-TIME double-click
  # recognition window (the forget gate in ActivePointerWdgt.processMouseUp). Two distinct
  # same-spot click gestures are spaced at least this far apart so they never fold into a
  # false double-click.
  @clickGuardWindowMs: 350

  # NON-scaled FLOOR on a press-drag-release's drag span. Some handlers sample the hand
  # once per FRAME (ScrollPanelWdgt's scroll-on-drag; drag-enter/leave on drop targets),
  # so a drag whose compressed span drains in <2 frames mis-scrolls / skips its target.
  # Flooring the drag span keeps it spanning several real frames at every speed; the
  # event path (and dedup) is unchanged so the gesture's RESULT is identical to a slow
  # drag (and to the committed reference). Plain moves/clicks aren't floored.
  @dragFloorMs: 300

  # NON-scaled FLOOR on a single click's HOLD (down→up). A click's down and up must land
  # in DIFFERENT world cycles so a per-cycle re-check runs WHILE the button is held — some
  # widgets read that mid-press frame (e.g. a SliderWdgt track-click jumps its button
  # under the pointer, and the hover highlight is resolved on a held-button frame; with no
  # such frame the button highlights spuriously after release). At normal a click already
  # holds 100ms; this only floors the COMPRESSED hold at fast/fastest. Timing only — the
  # click's effect is unchanged, so no reference moves.
  @clickHoldFloorMs: 100

  # The active speed level (a key of @spanFactors). Read LAZILY from
  # window.FIZZYGUM_MACRO_SPEED (set at boot from ?speed=), validated against
  # @spanFactors, falling back to @defaultSpeed — so an absent/invalid value is
  # "normal" and a console tweak to the global also takes effect.
  @currentSpeed: ->
    requested = window.FIZZYGUM_MACRO_SPEED
    if requested? and MacroToolkit.spanFactors[requested]? then requested else MacroToolkit.defaultSpeed

  # The active spanFactor (falls back to normal=1.0 for an unknown level).
  spanFactor: ->
    MacroToolkit.spanFactors[MacroToolkit.currentSpeed()] ? 1.0

  # The SINGLE push chokepoint for every synthetic input event the toolkit queues.
  # It compresses the event's time-OFFSET from the current cycle start by the active
  # spanFactor (the wall-clock speed lever) and then enqueues it. WHY this works as a
  # single uniform point: every verb schedules relative to
  # WorldWdgt.dateOfCurrentCycleStart.getTime() (its default startTime), and a whole
  # macro step runs synchronously inside ONE cycle — so that value is a stable BASE for
  # the step, and scaling (time − base) compresses the entire step's timeline at once
  # while preserving event ORDER and the final pointer position. Composite verbs that
  # chain with `startTime + milliseconds + 100` therefore need NO change: their
  # unscaled offsets are all compressed here, together, so the pieces stay adjacent in
  # scaled time. Only the timestamps move; the (deduped) pixel SET each gesture emits
  # is untouched — so references are speed-invariant. At "normal" (spanFactor 1) the
  # time is left exactly as-is, so playback stays byte-for-byte identical to before.
  queueInputEvent: (event, nonScaled = false) ->
    sf = @spanFactor()
    if (not nonScaled) and sf != 1 and event.time?
      base = WorldWdgt.dateOfCurrentCycleStart.getTime()
      event.time = base + (event.time - base) * sf
    world.inputEventsQueue.push event

  # Absolute virtual time that a startTime OFFSET maps to under the active spanFactor —
  # i.e. the timestamp queueInputEvent would stamp it as. The click verbs use this to
  # compute their FINAL (scaled) absolute times up front, then push NON-scaled, so the
  # false-double-click guard can reason in real ms and delay a click by a non-scaled
  # amount. At normal (spanFactor 1) this returns t unchanged.
  scaledAbs: (t) ->
    base = WorldWdgt.dateOfCurrentCycleStart.getTime()
    base + (t - base) * @spanFactor()

  # If a click scheduled at absolute time `downAbs` on `position` would land within the
  # hand's double-click window of the PREVIOUS distinct click gesture at the same
  # spot, push it out past @clickGuardWindowMs so the two never fold into a false
  # double-click. The absolute virtual time IS the event's `.time`, which is exactly what
  # the hand's 300ms event-time forget gate measures the gap against. Returns the (possibly
  # delayed) down time. Position-aware so distinct-spot clicks (the common case) are never
  # delayed; at normal, deliberate clicks are already far apart so this never fires.
  guardedClickStart: (downAbs, position) ->
    if @lastClickGestureUpTime? and @lastClickGesturePosition? and position? and
       (position.distanceTo(@lastClickGesturePosition) < WorldWdgt.preferencesAndSettings.grabDragThreshold) and
       ((downAbs - @lastClickGestureUpTime) < MacroToolkit.clickGuardWindowMs)
      return @lastClickGestureUpTime + MacroToolkit.clickGuardWindowMs
    downAbs

  # Remember a just-scheduled LEFT click gesture's last-release time + position for the
  # guard above (only left clicks fold into double/triple-clicks).
  rememberClickGesture: (upAbs, position) ->
    @lastClickGestureUpTime = upAbs
    @lastClickGesturePosition = position

  # Return the REQUESTED drag milliseconds, raised so that AFTER the chokepoint compresses
  # it (× spanFactor) the drag still spans ≥ @dragFloorMs of real time — i.e. several
  # frames — for the per-frame scroll-on-drag / drag-enter-leave samplers. Never alters the
  # normal baseline (spanFactor 1): there the requested span is returned untouched. The
  # inflated requested ms dedups to the same pixel path, so only the drag's DURATION grows,
  # not its trajectory — the gesture's result stays identical across speeds.
  dragSpanWithFloor: (requestedMs) ->
    sf = @spanFactor()
    return requestedMs if sf >= 1
    Math.max requestedMs, Math.ceil(MacroToolkit.dragFloorMs / sf)

  # The scaled down→up hold for a single click, floored to @clickHoldFloorMs of REAL time
  # so the down and up land in different world cycles (a per-cycle re-check then runs while
  # the button is held — see @clickHoldFloorMs). Returns an absolute ms gap (already
  # scaled), so callers add it directly to the down's absolute time. Human is unchanged
  # (the hold is already ≥ the floor at spanFactor 1).
  clickHoldWithFloor: (requestedMs) ->
    sf = @spanFactor()
    scaled = requestedMs * sf
    return scaled if sf >= 1
    Math.max scaled, MacroToolkit.clickHoldFloorMs

  # Install the linked macro code (pump header + linked verbs) with `@` = this
  # MacroToolkit instance, so the generator and the verbs it calls resolve their
  # @helpers against this collaborator. Mirrors Widget.evaluateString's
  # compile-then-eval, minus the _reLayoutSelf/changed tail (installing a macro paints
  # nothing, and this collaborator has no widget methods).
  evaluateString: (codeSource) ->
    eval compileFGCode codeSource, true

  progressOnMacroSteps: ->

  noCodeLoading: ->
    true

  # "no inputs ongoing" = the queue is drained AND no scroll-momentum glide is
  # still settling: a ScrollPanelWdgt's post-release glide is frame-cadence
  # driven and outlives the input queue, so without this gate a screenshot
  # races it (under the pacing control the glide is suppressed at the source —
  # ScrollPanelWdgt.mouseDownLeft — and this set stays empty; the gate is
  # defense-in-depth for any momentum that does run).
  noInputsOngoing: ->
    world.inputEventsQueue.isEmpty() and !world.anyScrollMomentumOngoing()

  # Used by a macro's screenshot step (the "waitForScreenshotReady" yield in
  # Macro's pump): decide, across cycles, when the canvas is safe to capture
  # deterministically. Native: capture immediately. SWCanvas: wait until glyph
  # atlases have loaded (no text dirty), then force ONE warm-atlas repaint into
  # the software surface and wait a single doOneCycle for updateBroken (which
  # runs AFTER progressOnMacroSteps) to flush it — so the captured pixels are
  # identical run-to-run. This is the single SWCanvas screenshot settle gate.
  readyForMacroScreenshot: ->
    # never capture while a scroll-momentum glide is settling (matters for
    # native captures too, hence before the SWCanvas-only early return)
    return false if world.anyScrollMomentumOngoing()
    return true unless window.FIZZYGUM_USE_SWCANVAS
    if world.anyTextDirty()
      return false
    if !@macroScreenshotWarmRepaintFrame?
      # resetImmutableBackBuffersCache resets the text cache AND bumps the island-buffer epoch, so a
      # rotated/scaled island buffer (a further cache downstream) rebuilds from warm text before capture (§4.4).
      world.resetImmutableBackBuffersCache?()
      world.fullChanged()
      @macroScreenshotWarmRepaintFrame = WorldWdgt.frameCount
      return false
    if WorldWdgt.frameCount <= @macroScreenshotWarmRepaintFrame
      return false
    @macroScreenshotWarmRepaintFrame = nil
    return true

  # other useful tween functions here:
  # https://github.com/ashblue/simple-tween-js/blob/master/tween.js
  expoOut: (i, origin, distance, numberOfEvents) ->
    distance * (-Math.pow(2, -10 * i/numberOfEvents) + 1) + origin

  bringUpTestMenu_InputEvents: (millisecondsBetweenKeys = 35, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
      @syntheticEventsShortcutsAndSpecialKeys_InputEvents "F2", millisecondsBetweenKeys, startTime

  # Synthesize a special key or modifier-combo keypress. Accepts a key name or a
  # "+"-joined combo: "F2", "Enter", "Backspace", "Escape", "Tab",
  # "ArrowLeft/Right/Up/Down", "Shift+ArrowRight" (select one right), "Ctrl+S",
  # "Meta+a" (Cmd+A select-all), … The modifier state rides on the key event itself
  # (the framework's keyboard handlers read the event's shift/ctrl/alt/meta flags).
  # Plain typed text should go through syntheticEventsStringKeys_InputEvents instead.
  syntheticEventsShortcutsAndSpecialKeys_InputEvents: (whichShortcutOrSpecialKey, millisecondsBetweenKeys = 35, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    parts = whichShortcutOrSpecialKey.split "+"
    key = parts.pop()
    shiftKey = ("Shift" in parts)
    ctrlKey  = ("Ctrl" in parts) or ("Control" in parts)
    altKey   = ("Alt" in parts)
    metaKey  = ("Meta" in parts) or ("Cmd" in parts)
    # the "code" is the physical key; a 1:1 key->code is fine for synthetic events
    # (Shift uses "ShiftLeft" to match syntheticEventsStringKeys_InputEvents).
    code = if key == "Shift" then "ShiftLeft" else key
    @queueInputEvent new KeydownInputEvent key, code, shiftKey, ctrlKey, altKey, metaKey, true, startTime
    @queueInputEvent new KeyupInputEvent  key, code, shiftKey, ctrlKey, altKey, metaKey, true, startTime + millisecondsBetweenKeys

  # Press a special key/combo `count` times, staggered in time so each press is a
  # distinct event (e.g. "ArrowLeft" ×8 to walk the caret). Composes
  # syntheticEventsShortcutsAndSpecialKeys_InputEvents.
  repeatSpecialKey_InputEvents: (keyName, count, millisecondsBetweenKeys = 70, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    t = startTime
    for i in [0...count]
      @syntheticEventsShortcutsAndSpecialKeys_InputEvents keyName, 35, t
      t += millisecondsBetweenKeys

  syntheticEventsStringKeys_InputEvents: (theString, millisecondsBetweenKeys = 35, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    scheduledTimeOfEvent = startTime

    for i in [0...theString.length]

      isUpperCase = theString.charAt(i) == theString.charAt(i).toUpperCase()

      if isUpperCase
        @queueInputEvent new KeydownInputEvent "Shift", "ShiftLeft", true, false, false, false, true, scheduledTimeOfEvent
        scheduledTimeOfEvent += millisecondsBetweenKeys

      # note that the second parameter (code) we are making up, assuming a hypothetical "1:1" key->code layout
      @queueInputEvent new KeydownInputEvent theString.charAt(i), theString.charAt(i), isUpperCase, false, false, false, true, scheduledTimeOfEvent
      scheduledTimeOfEvent += millisecondsBetweenKeys

      # note that the second parameter (code) we are making up, assuming a hypothetical "1:1" key->code layout
      @queueInputEvent new KeyupInputEvent theString.charAt(i), theString.charAt(i), isUpperCase, false, false, false, true, scheduledTimeOfEvent
      scheduledTimeOfEvent += millisecondsBetweenKeys

      if isUpperCase
        @queueInputEvent new KeyupInputEvent "Shift", "ShiftLeft", false, false, false, false, true, scheduledTimeOfEvent
        scheduledTimeOfEvent += millisecondsBetweenKeys

  syntheticEventsMouseMovePressDragRelease_InputEvents: (orig, dest, millisecondsForDrag = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1) ->
    # Floor the drag SPAN (so it spans enough real frames — see @dragFloorMs) while keeping
    # the event COUNT identical (drop events-per-ms by the same ratio): a floored drag must
    # follow the SAME deduped pixel path and land on the SAME final pixel, or the dropped
    # widget would shift ~1px (macroPromptShadowFollowsOnDrag). Only the duration grows.
    flooredDrag = @dragSpanWithFloor millisecondsForDrag
    dragEventsPerMs = numberOfEventsPerMillisecond * millisecondsForDrag / flooredDrag
    @syntheticEventsMouseMove_InputEvents orig, "left button", 100, nil, startTime, numberOfEventsPerMillisecond
    @syntheticEventsMouseDown_InputEvents "left button", startTime + 100
    @syntheticEventsMouseMove_InputEvents dest, "left button", flooredDrag, orig, startTime + 100 + 100, dragEventsPerMs
    @syntheticEventsMouseUp_InputEvents "left button", startTime + 100 + 100 + flooredDrag + 100

  # This should be used if you want to drag from point A to B to C ...
  # If rather you want to just drag from point A to point B,
  # then just use syntheticEventsMouseMovePressDragRelease_InputEvents
  syntheticEventsMouseMoveWhileDragging_InputEvents: (dest, milliseconds = 1000, orig = world.hand.position(), startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1) ->
    # floor the span, keep the count constant (see syntheticEventsMouseMovePressDragRelease)
    flooredMs = @dragSpanWithFloor milliseconds
    dragEventsPerMs = numberOfEventsPerMillisecond * milliseconds / flooredMs
    @syntheticEventsMouseMove_InputEvents dest, "left button", flooredMs, orig, startTime, dragEventsPerMs

  # mouse moves need an origin and a destination, so we
  # need to place the mouse in _some_ place to begin with
  # in order to do that.
  syntheticEventsMousePlace_InputEvents: (place = new Point(0,0), scheduledTimeOfEvent = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @currentPointerTarget = place
    @queueInputEvent new MousemoveInputEvent place.x, place.y, 0, 0, false, false, false, false, true, scheduledTimeOfEvent

  syntheticEventsMouseMove_InputEvents: (dest, whichButton = "no button", milliseconds = 1000, orig = world.hand.position(), startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1) ->
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

    # where the pointer ends up — read by the click verbs as the click position for the
    # false-double-click guard (a click lands wherever the last move left the pointer)
    @currentPointerTarget = dest

    # Math.round so a drag's span-floored fractional events-per-ms still yields EXACTLY the
    # un-floored integer sample count (so expoOut samples the identical path). A no-op for
    # the ordinary whole-number cases.
    numberOfEvents = Math.round(milliseconds * numberOfEventsPerMillisecond)
    for i in [0...numberOfEvents]
      scheduledTimeOfEvent = startTime + i/numberOfEventsPerMillisecond
      nextX = Math.round @expoOut i, orig.x, (dest.x-orig.x), numberOfEvents
      nextY = Math.round @expoOut i, orig.y, (dest.y-orig.y), numberOfEvents
      if nextX != prevX or nextY != prevY
        prevX = nextX
        prevY = nextY
        #console.log nextX + " " + nextY + " scheduled at: " + scheduledTimeOfEvent
        @queueInputEvent new MousemoveInputEvent nextX, nextY, button, buttons, false, false, false, false, true, scheduledTimeOfEvent

  # Schedules the down/up in ABSOLUTE (already-spanFactor-scaled) time and pushes them
  # NON-scaled, so a LEFT click can be pushed past the hand's real double-click window
  # of a previous same-spot click (the false-double-click guard). Right clicks don't fold,
  # so they skip the guard. At normal (spanFactor 1) this is byte-identical to before.
  syntheticEventsMouseClick_InputEvents: (whichButton = "left button", milliseconds = 100, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    isLeft = (whichButton == "left button")
    downAbs = if isLeft then (@guardedClickStart (@scaledAbs startTime), @currentPointerTarget) else (@scaledAbs startTime)
    upAbs = downAbs + @clickHoldWithFloor milliseconds
    if isLeft then @rememberClickGesture upAbs, @currentPointerTarget
    @syntheticEventsMouseDown_InputEvents whichButton, downAbs, true
    @syntheticEventsMouseUp_InputEvents whichButton, upAbs, true

  # A SHIFT-modified left click: the same down+up as syntheticEventsMouseClick_InputEvents, but with the
  # event's shiftKey flag set (the 4th boolean of Mouse{down,up}InputEvent — button, buttons, ctrlKey,
  # shiftKey, altKey, metaKey, isFromAutomator, time). A click carrying shiftKey makes an editable
  # StringWdgt/TextWdgt EXTEND its selection to the click point (mouseClickLeft reads shiftKey) instead
  # of just repositioning the caret. Left button only (down buttons=1, up buttons=0).
  syntheticEventsMouseShiftClick_InputEvents: (milliseconds = 100, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    # absolute (scaled) times + guard + non-scaled push, like syntheticEventsMouseClick —
    # a shift-click is still a left-button click and would otherwise fold into a false
    # double-click with a prior same-spot click once recognition is ungated.
    downAbs = @guardedClickStart (@scaledAbs startTime), @currentPointerTarget
    upAbs = downAbs + milliseconds * @spanFactor()
    @rememberClickGesture upAbs, @currentPointerTarget
    @queueInputEvent (new MousedownInputEvent 0, 1, false, true, false, false, true, downAbs), true
    @queueInputEvent (new MouseupInputEvent 0, 0, false, true, false, false, true, upAbs), true

  # nonScaled (default false): when true the startTime is already an absolute, scaled
  # time (the click verbs pre-compute it so the false-double-click guard can shift it),
  # so queueInputEvent must NOT scale it again.
  syntheticEventsMouseDown_InputEvents: (whichButton = "left button", startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), nonScaled = false) ->
    if whichButton == "left button"
      button = 0
      buttons = 1
    else if whichButton == "right button"
      button = 2
      buttons = 2
    else
      debugger
      throw "syntheticEventsMouseDown_InputEvents: whichButton is unknown"

    @queueInputEvent (new MousedownInputEvent button, buttons, false, false, false, false, true, startTime), nonScaled

  syntheticEventsMouseUp_InputEvents: (whichButton = "left button", startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), nonScaled = false) ->
    if whichButton == "left button"
      button = 0
      buttons = 0
    else if whichButton == "right button"
      button = 2
      buttons = 0
    else
      debugger
      throw "syntheticEventsMouseUp_InputEvents: whichButton is unknown"

    @queueInputEvent (new MouseupInputEvent button, buttons, false, false, false, false, true, startTime), nonScaled

  moveToAndClick_InputEvents: (positionOrWidget, whichButton = "left button", milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents positionOrWidget, "no button", milliseconds, nil, startTime, nil
    @syntheticEventsMouseClick_InputEvents whichButton, 100, startTime + milliseconds + 100

  # Move to a point/widget then MOUSE DOWN and HOLD — the press half of a click, scheduled AFTER the move
  # completes (like moveToAndClick_InputEvents, but with no release). Use it when the press ITSELF produces
  # the state to capture, so the screenshot must be taken before the release: a mouse-DOWN (not the full
  # click) dismisses an unpinned menu cascade (ActivePointerWdgt.cleanupMenuWdgts), and a mouse-DOWN drops a
  # float-dragged widget (processMouseDown -> drop). Pattern: `@moveToAndMouseDown_InputEvents target` ->
  # `yield "waitNoInputsOngoing"` -> `takeScreenshot_InputEvents_Macro "…"` (captures with the button still
  # held) -> `@syntheticEventsMouseUp_InputEvents()` -> `yield "waitNoInputsOngoing"`.
  moveToAndMouseDown_InputEvents: (positionOrWidget, whichButton = "left button", milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents positionOrWidget, "no button", milliseconds, nil, startTime, nil
    @syntheticEventsMouseDown_InputEvents whichButton, startTime + milliseconds + 100

  # Click a fractional point [fx, fy] inside a widget — located either by a widget
  # reference or by a text-description identifier [desc, occ, total]. The landing point
  # is (left + round(width*fx), top + round(height*fy)) of the LIVE widget, so it
  # follows the widget if it has moved/resized.
  # Resolve a [widget | text-description identifier | Point] + an [fx, fy] fraction to an
  # absolute world Point inside that widget. Shared by the fractional click/double/triple verbs.
  pointAtFractionOf: (widgetOrIdentifier, fraction) ->
    widget = if (typeof widgetOrIdentifier == "string") or (widgetOrIdentifier instanceof Array)
      @findWidgetByTextDescription widgetOrIdentifier
    else
      widgetOrIdentifier
    new Point (Math.round(widget.width() * fraction[0]) + widget.left()), (Math.round(widget.height() * fraction[1]) + widget.top())

  moveToAndClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction, whichButton = "left button", milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClick_InputEvents (@pointAtFractionOf widgetOrIdentifier, fraction), whichButton, milliseconds, startTime

  # Affine transforms (docs/affine-transforms-plan.md §4.6): the SCREEN-plane point at
  # fractional position [fx,fy] inside a widget. pointAtFractionOf gives the point in the
  # widget's OWN plane; a widget inside a scaled/rotated TransformFrameWdgt ("island") lives in
  # that island's VIRTUAL plane, so its plane point must be mapped UP through each ancestor
  # island's forward transform (Widget::localPointToScreen) to reach the on-screen pixel a user
  # would actually click — an island-inner widget's screen position is NOT its bounds position.
  # For a widget not inside any non-identity island this returns exactly what pointAtFractionOf
  # does, so it is safe for any widget. The mapped screen point can lie OUTSIDE the widget's
  # un-mapped bounds — that is the whole point: only the inverse-mapped hit-test (§4.6) lands it
  # back on the widget, so a click here is a genuine click-THROUGH test.
  screenPointAtFractionOf: (widgetOrIdentifier, fraction) ->
    widget = if (typeof widgetOrIdentifier == "string") or (widgetOrIdentifier instanceof Array)
      @findWidgetByTextDescription widgetOrIdentifier
    else
      widgetOrIdentifier
    widget.localPointToScreen (@pointAtFractionOf widget, fraction)

  # Move to a widget's SCREEN point at fraction [fx,fy] (default its centre) and click — the
  # island analogue of moveToAndClickAtFractionOf_InputEvents, whose point is in the widget's
  # own plane and would miss inside a scaled/rotated island. The pointer pipeline plane-maps the
  # dispatched position per-receiver (4A-1 click dispatch, R1 mouseMove, R4 drag consumers), so
  # island-inner sub-widget geometry that reads it (a caret slot, a slider fraction) is correct;
  # this verb's job is just to AIM the pointer at the right on-screen pixel.
  moveToAndClickAtScreenFractionOf_InputEvents: (widgetOrIdentifier, fraction = [0.5, 0.5], whichButton = "left button", milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClick_InputEvents (@screenPointAtFractionOf widgetOrIdentifier, fraction), whichButton, milliseconds, startTime

  # Push N consecutive left click-pairs (down+up) at the CURRENT pointer position, spaced so the hand
  # recognises them as a double-/triple-click. The hand only counts a fresh click as a double/triple while
  # the previous one is still "remembered" — a 300ms EVENT-TIME window (the forget gate in
  # ActivePointerWdgt.processMouseUp) — so the click UPs must fall within that window of each other; we space them ~120ms apart. No move
  # between the clicks (same widget, same point) — recognition also requires the clicks be on the same
  # widget within grabDragThreshold.
  # The APPROACH (startTime) is scaled by the speed level (it follows the scaled positioning move), but the
  # inter-click 120ms / 50ms spacing is kept NON-scaled so the clicks always land inside the 300ms
  # event-time window at every speed. The false-double-click guard is applied ONCE to the first click (vs a prior
  # distinct gesture); clicks 2..N are the DELIBERATE repeats that MUST fold, so they skip it.
  syntheticEventsConsecutiveLeftClicks_InputEvents: (numberOfClicks = 2, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), millisecondsBetweenClicks = 120, clickMilliseconds = 50) ->
    firstDownAbs = @guardedClickStart (@scaledAbs startTime), @currentPointerTarget
    for i in [0...numberOfClicks]
      t = firstDownAbs + i * millisecondsBetweenClicks
      @syntheticEventsMouseDown_InputEvents "left button", t, true
      @syntheticEventsMouseUp_InputEvents "left button", t + clickMilliseconds, true
    @rememberClickGesture (firstDownAbs + (numberOfClicks - 1) * millisecondsBetweenClicks + clickMilliseconds), @currentPointerTarget

  # Double- / triple-click at a fractional point inside a located widget, driven through the INPUT-EVENT
  # QUEUE like a real user — a positioning move (so the fake pointer shows) then two/three consecutive
  # queued left clicks that the HAND recognises and turns into processDoubleClick/processTripleClick itself
  # (ActivePointerWdgt). Recognition is purely proximity + the hand's 300ms EVENT-TIME window: the
  # consecutive-click verb deliberately spaces its clicks ~120ms
  # apart (NON-scaled, inside that window) so the hand folds them at EVERY global speed level — the test
  # carries no speed metadata. (A non-scaled minimum gap between DISTINCT click gestures, plus the hand's
  # event-time forget gate, keep two separate clicks from folding into a false double-click.)
  # Queues input events — follow with `yield "waitNoInputsOngoing"`.
  doubleClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction = [0.5, 0.5], milliseconds = 600, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents (@pointAtFractionOf widgetOrIdentifier, fraction), "no button", milliseconds, nil, startTime, nil
    @syntheticEventsConsecutiveLeftClicks_InputEvents 2, startTime + milliseconds + 100

  tripleClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction = [0.5, 0.5], milliseconds = 600, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents (@pointAtFractionOf widgetOrIdentifier, fraction), "no button", milliseconds, nil, startTime, nil
    @syntheticEventsConsecutiveLeftClicks_InputEvents 3, startTime + milliseconds + 100

  # SHIFT+left-click at a fractional point inside a located widget — move the pointer there (no button),
  # then click with Shift held. In editable text a plain click sets the caret while a shift-click EXTENDS the
  # selection from the caret to the click point; so the pattern is a plain moveToAndClickAtFractionOf to drop
  # the anchor caret, then one or more shiftClickAtFractionOf to grow the selection. The selection-extend
  # sibling of the double-/triple-click verbs. Queues input events — follow with `yield "waitNoInputsOngoing"`.
  shiftClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents (@pointAtFractionOf widgetOrIdentifier, fraction), "no button", milliseconds, nil, startTime, nil
    @syntheticEventsMouseShiftClick_InputEvents 100, startTime + milliseconds + 100

  # Push ONE synthetic WheelInputEvent onto the input queue — the queued primitive behind
  # wheelOn_InputEvents. This is exactly how the browser delivers a real wheel: WorldWdgt's onwheel
  # handler does `@inputEventsQueue.push WheelInputEvent.fromBrowserEvent event`, and WheelInputEvent.
  # processEvent calls world.hand.processWheel. The wheel is dispatched to whatever scrollable is under
  # the pointer WHEN THE EVENT IS CONSUMED, so position the pointer first (a queued move). A POSITIVE
  # deltaY scrolls content DOWN. isSynthetic=true so it is not re-recorded.
  syntheticEventsWheel_InputEvents: (deltaX = 0, deltaY = 0, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @queueInputEvent new WheelInputEvent deltaX, deltaY, 0, 0, 0, false, false, false, false, true, startTime

  # Mouse-WHEEL scroll over a located widget (by widget reference or a recorded text-description
  # identifier), driven entirely through the INPUT-EVENT QUEUE like a real wheel — NOT by poking the
  # hand. First a no-button move positions the pointer over the widget (so the fake playback pointer
  # shows and mouseEnter/hover fire, exactly as for a user), then a queued WheelInputEvent scrolls the
  # nearest scrollable under the pointer (ActivePointerWdgt.processWheel walks up to the nearest `wheel`
  # owner; ScrollPanelWdgt.wheel scrolls itself or escalates to its parent at the travel limit). A
  # POSITIVE deltaY scrolls content DOWN; deltaX scrolls horizontally. Queues input events — follow with
  # `yield "waitNoInputsOngoing"`.
  wheelOn_InputEvents: (widgetOrIdentifier, deltaY, deltaX = 0, fraction = [0.5, 0.5], milliseconds = 600, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents (@pointAtFractionOf widgetOrIdentifier, fraction), "no button", milliseconds, nil, startTime, nil
    @syntheticEventsWheel_InputEvents deltaX, deltaY, startTime + milliseconds + 100

  # Click a SliderWdgt's TRACK (its background, OUTSIDE the button) at a point a fraction along its
  # length, to JUMP the slider button there. For a scroll panel's scrollbar — a ScrollPanelWdgt's @vBar
  # / @hBar (both SliderWdgts) — this scrolls the content to that position: SliderWdgt.mouseDownLeft,
  # when the slider's parent is a ScrollPanelWdgt (or PromptWdgt), non-float-drags the button to the
  # click point (ActivePointerWdgt.nonFloatDragWdgtFarAwayToHere), and a click leaves it there. `fraction`
  # is [fx, fy] of the slider's bounds — for a vertical scrollbar pass e.g. [0.5, 0.8] (80% down the
  # track); for a horizontal one [0.8, 0.5]. Queues input events — follow with `yield
  # "waitNoInputsOngoing"`. A slider NOT parented to a scroll panel ignores the track click (it escalates
  # the event) — that is the negative companion behaviour (sliderNotOnScrollPanelBackground…). Composes
  # moveToAndClickAtFractionOf_InputEvents; sliderOrIdentifier may be a widget reference (e.g. doc.vBar)
  # or a recorded text-description identifier.
  clickOnSliderTrackAtFraction_InputEvents: (sliderOrIdentifier, fraction, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClickAtFractionOf_InputEvents sliderOrIdentifier, fraction, "left button", milliseconds, startTime

  # DRAG a SliderWdgt's button to a fractional position along its track — a press-drag-release ON THE
  # BUTTON (not the track). The button is a NON-float-drag child of the slider (SliderButtonWdgt.
  # detachesWhenDragged returns false while its parent is a SliderWdgt), so this moves the button within
  # the track via SliderButtonWdgt.nonFloatDragging, which calls SliderWdgt.updateValue -> setValue ->
  # updateTarget every frame the value changes — so if the slider has a controller target set (via
  # "set target"), it drives target[setter](value) LIVE as it is dragged. This is the controller-DRAG
  # sibling of clickOnSliderTrackAtFraction_InputEvents (which only JUMPS the button via a track click, and
  # only when the slider is parented to a ScrollPanelWdgt/PromptWdgt); a free-standing controller slider
  # responds to dragging its button, not to track clicks. `fraction` is a [fx, fy] point of the SLIDER's
  # bounds = the destination of the drag along the track (for a vertical slider, vary fy; default sliders
  # have smallestValueIsAtBottomEnd false, so a larger fy = a larger value). Queues input events — follow
  # with `yield "waitNoInputsOngoing"`. sliderOrIdentifier may be a widget reference or a recorded
  # text-description identifier.
  dragSliderButtonToFraction_InputEvents: (sliderOrIdentifier, fraction, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    slider = if (typeof sliderOrIdentifier == "string") or (sliderOrIdentifier instanceof Array)
      @findWidgetByTextDescription sliderOrIdentifier
    else
      sliderOrIdentifier
    buttonCentre = @pointAtFractionOf slider.button, [0.5, 0.5]
    trackPoint = @pointAtFractionOf slider, fraction
    @syntheticEventsMouseMovePressDragRelease_InputEvents buttonCentre, trackPoint, milliseconds, startTime

  # Clipboard CUT / COPY / PASTE for the active editing caret, driven through the INPUT-EVENT QUEUE like
  # the browser's real clipboard events (oncut/oncopy/onpaste → ClipboardInputEvent.fromBrowserEvent →
  # queue → world.caret.process{Cut,Copy,Paste}). Fizzygum keeps NO internal clipboard and synthetic
  # Meta+x/c/v can't fire the OS clipboard, so the TEXT is carried in the event itself (a macro-local
  # variable): cutSelection_InputEvents / copySelection_InputEvents read the current selection, RETURN it
  # (so you can paste it back later), and enqueue a Cut/CopyInputEvent carrying it; pasteText_InputEvents
  # enqueues a PasteInputEvent. The selection is read SYNCHRONOUSLY (it still exists at call time); the
  # cut/paste itself happens when the event is consumed. Select first (e.g. Shift+Arrow) and `yield
  # "waitNoInputsOngoing"`, then call these and `yield "waitNoInputsOngoing"` again before a screenshot.
  cutSelection_InputEvents: (startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    text = world.caret?.target?.selection()
    @queueInputEvent new CutInputEvent text, true, startTime
    text

  copySelection_InputEvents: (startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    text = world.caret?.target?.selection()
    @queueInputEvent new CopyInputEvent text, true, startTime
    text

  pasteText_InputEvents: (text, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @queueInputEvent new PasteInputEvent text, true, startTime

  # Drag a resize/move HANDLE (one of the handles shown after a widget's "resize/move..." menu
  # item) from its centre to a destination Point. Handles resize/move the target via NON-float
  # dragging (HandleWdgt.nonFloatDragging → setExtent / moveTo), so this is a real
  # press-drag-release. handleType picks the handle: "resizeBothDimensionsHandle" (bottom-right
  # corner — resizes both dimensions), "moveHandle", "resizeHorizontalHandle", "resizeVerticalHandle".
  dragResizeMoveHandleTo_InputEvents: (handleType, destination, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    handle = world.topWdgtSuchThat (item) -> (item instanceof HandleWdgt) and (item.type == handleType)
    # Press at the handle's ON-SCREEN centre. localPointToScreen forward-maps through any enclosing
    # non-identity island (affine transforms §6 4A-2), so a handle on a widget inside a scaled/rotated
    # island is pressed where it actually renders — not at its virtual bounds centre, which would miss.
    # Off every island localPointToScreen returns the same point ⇒ byte-identical for all existing tests.
    @syntheticEventsMouseMovePressDragRelease_InputEvents handle.localPointToScreen(handle.center()), destination, milliseconds, startTime

  # Float-DRAG a widget (by reference, or by a recorded text-description identifier) and drop it at a
  # destination — a Point, or another widget / identifier (dropped on that target's centre). Presses at
  # the widget's centre and drags past the grab threshold so the widget is picked up onto the hand, then
  # releases over the destination. Use it to drop a widget INTO a container that accepts drops — e.g. a
  # SimpleDocumentScrollPanel with editing enabled re-parents the dropped widget as a flowing paragraph.
  dragWidgetTo_InputEvents: (widgetOrIdentifier, destination, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    source = if (typeof widgetOrIdentifier == "string") or (widgetOrIdentifier instanceof Array)
      @findWidgetByTextDescription widgetOrIdentifier
    else
      widgetOrIdentifier
    dropPoint = if destination instanceof Point then destination else @pointAtFractionOf destination, [0.5, 0.5]
    @syntheticEventsMouseMovePressDragRelease_InputEvents source.center(), dropPoint, milliseconds, startTime

  openMenuOf_InputEvents: (widget, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClick_InputEvents widget, "right button", milliseconds, startTime

  # Close a WindowWdgt by clicking the close button (the X) in its window bar. Every WindowWdgt builds
  # a `.closeButton` (a CloseIconButtonWdgt at its top-left); clicking it runs the button's actOnClick
  # → the window's closeFromWindowBar()/close(). The reusable window-chrome pattern: get a window (by a
  # kept reference, or by class + its `internal` flag) and close it through its real control button, as
  # a user would. Queues input events — follow with `yield "waitNoInputsOngoing"`.
  closeWindow_InputEvents: (windowWidget) ->
    @moveToAndClick_InputEvents windowWidget.closeButton

  # Collapse or uncollapse a WindowWdgt by clicking the collapse/uncollapse control in its window bar.
  # Every WindowWdgt builds a `.collapseUncollapseSwitchButton` (a SwitchButtonWdgt that toggles between a
  # CollapseIconButtonWdgt and an UncollapseIconButtonWdgt): clicking it when expanded collapses the
  # window to just its bar (contents.collapse()), and clicking it again — the switch now shows the
  # uncollapse icon — restores it. So this one verb both collapses and uncollapses, depending on the
  # window's current state. The window-chrome sibling of closeWindow_InputEvents. Queues input events —
  # follow with `yield "waitNoInputsOngoing"`.
  collapseOrUncollapseWindow_InputEvents: (windowWidget) ->
    @moveToAndClick_InputEvents windowWidget.collapseUncollapseSwitchButton

  # Resize a WindowWdgt by dragging its resize handle to a destination. Every WindowWdgt builds a `.resizer`
  # (a HandleWdgt laid out at its bottom-right corner); a NON-float press-drag-release on it resizes the
  # window (HandleWdgt.nonFloatDragging → setExtent on the window). The window-chrome sibling of close/
  # collapse: reach the window's OWN resize control by reference (vs hunting a HandleWdgt by coordinates —
  # several windows each have one). destination may be a Point or another widget (dragged to its centre).
  # Queues input events — follow with `yield "waitNoInputsOngoing"`.
  dragWindowResizerTo_InputEvents: (windowWidget, destination, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
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
  # `<widget>.toString() + " ➜"`, so a RectangleWdgt reads "a RectangleWdgt#1 ➜" (an instance number +
  # a trailing arrow). Match the stable head ("a RectangleWdgt") instead of the exact string, and only
  # the intended target is hit even when the menu also lists the World and the widget's own handle.
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
  # via testNumberOfItems). A macro-level ASSERTION: it pushes no
  # input events and does not yield, so call it once the menu is open (`yield
  # "waitNoInputsOngoing"` first). Locates the menu by MEANING (not by pointer position) and
  # records PASS/FAIL via recordMacroAssertion, so a mismatch fails the test exactly as a
  # screenshot mismatch would.
  assertTopMenuItemCount: (expectedCount) ->
    theMenu = @getMostRecentlyOpenedMenu()
    found = theMenu?.testNumberOfItems()
    world.automator.player.recordMacroAssertion (found == expectedCount), "top menu item count", expectedCount, found

  # Assert the item LABEL STRINGS of the most-recently-opened menu, in order.
  # Like assertTopMenuItemCount it pushes no input events and does
  # not yield — call it once the menu is open. Reads each item's `labelString` via the menu's testItems() and
  # records PASS/FAIL via recordMacroAssertion on the ordered comparison, logging the expected-vs-found strings.
  # NB: this is a TOOLKIT method (called as `@assertTopMenuItemStrings […]`) precisely so the assertion sink
  # `recordMacroAssertion` is NOT written in the macro source — a literal "Macro" mid-token there would be mangled
  # by the macro invocation rewriter (which only allows "Macro" as a trailing suffix).
  assertTopMenuItemStrings: (expectedLabels) ->
    theMenu = @getMostRecentlyOpenedMenu()
    found = theMenu?.testItems().map (item) -> item.labelString
    passed = (found?) and (found.length == expectedLabels.length) and (expectedLabels.every (label, i) -> found[i] == label)
    world.automator.player.recordMacroAssertion passed, "top menu item strings", expectedLabels.join(" | "), (if found? then found.join(" | ") else "no menu")

  # Assert that two screenshots ALREADY TAKEN in this test are byte-identical — the explicit
  # form of the no-op / round-trip idiom (undo restores the pre-edit pixels, collapse →
  # uncollapse restores the window, a cancelled prompt leaves zero residue, …). Pass the two
  # FULL image names exactly as given to takeScreenshot_InputEvents_Macro, earlier shot
  # first, and call it right AFTER the later shot. Compares the LIVE fingerprints the player
  # recorded when it took each shot (AutomatorPlayer.liveScreenshotFingerprints — SWCanvas:
  # the raw-pixel SHA-256; native: the PNG data-URL string), so the identity is checked
  # IN-RUN rather than enforced transitively by the two committed references happening to
  # share a dataHash — which also means a `--clean` recapture after a regression can no
  # longer silently dissolve the pair (the capture script's legs replay in PLAYING state,
  # so a broken identity fails them loudly). A missing fingerprint (typo'd name, or the
  # assertion placed before the shot) FAILS, never silently passes. Like the other @assert…
  # methods it pushes no input events and reports via recordMacroAssertion.
  assertScreenshotsIdentical: (earlierImageName, laterImageName) ->
    fingerprints = world.automator.player.liveScreenshotFingerprints ? {}
    earlier = fingerprints[earlierImageName]
    later = fingerprints[laterImageName]
    description = "screenshots " + earlierImageName + " and " + laterImageName + " are byte-identical"
    if not earlier? or not later?
      missing = (name for name in [earlierImageName, laterImageName] when not fingerprints[name]?)
      world.automator.player.recordMacroAssertion false, description, "a live fingerprint for both screenshots", "no screenshot taken under: " + missing.join(", ")
      return
    # native fingerprints are whole PNG data-URLs — don't dump megabytes into the console
    shorten = (fp) -> if fp.length > 70 then fp.slice(0, 64) + "… (" + fp.length + " chars)" else fp
    world.automator.player.recordMacroAssertion (earlier == later), description, (shorten earlier), (shorten later)

  # Generic VALUE assertion for a non-visual invariant (e.g. a computed count read from the live
  # world). Records PASS/FAIL via recordMacroAssertion, so a mismatch fails the test exactly as a
  # screenshot mismatch would — WITHOUT stopping the macro (a bare `throw` in macro source would
  # surface as an uncaught error / shard stall). Compared with `==`. Like the other @assert…
  # methods it pushes no input events and does not yield. It is a TOOLKIT method precisely so the
  # sink `recordMacroAssertion` is not written in the macro source (its "Macro" mid-token would be
  # mangled by the invocation rewriter). Used e.g. to assert `world.dataflow.lastDrainRecomputeCount`
  # (a diamond recomputes its bottom ONCE — dataflow §1.18).
  assertValuesEqual: (description, expected, found) ->
    world.automator.player.recordMacroAssertion (found == expected), description, expected, found

  # Topmost widget matching either a class-name string (compared via
  # widgetClassString) or a class object (compared via instanceof).
  findTopWidgetByClassNameOrClass: (widgetNameOrClass) ->
    if typeof widgetNameOrClass == "string"
      world.topWdgtSuchThat (item) -> item.widgetClassString() == widgetNameOrClass
    else
      world.topWdgtSuchThat (item) -> item instanceof widgetNameOrClass

  # Topmost widget whose getTextDescription() matches an identifier triple
  # [textDescription, occurrenceIndex, totalOccurrences] — a stable locator
  # (world.getWidgetViaTextLabel / Widget.identifyViaTextLabel).
  # Accepts a bare string (treated as [string, 0, 1]).
  findWidgetByTextDescription: (identifier) ->
    identifier = [identifier, 0, 1] if typeof identifier == "string"
    world.getWidgetViaTextLabel identifier

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
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorWdgt
    list = inspectorNaked.list
    elements = list.elements

    vBar = list.vBar
    index = elements.indexOf listItemString
    total = elements.length
    [vBarCenterFromHere, vBarCenterToHere] = @calculateVertBarMovement vBar, index, total

    @syntheticEventsMouseMovePressDragRelease_InputEvents vBarCenterFromHere, vBarCenterToHere

  clickOnListItemFromTopInspector_InputEvents: (listItemString, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorWdgt

    list = inspectorNaked.list

    entry = list.topWdgtSuchThat (item) ->
      if item.text?
        item.text == listItemString
      else
        false
    entryTopLeft = entry.topLeft()

    @moveToAndClick_InputEvents entryTopLeft.translateBy(new Point 10, 2), "left button", milliseconds, startTime


  clickOnCodeBoxFromTopInspectorAtCodeString_InputEvents: (codeString, occurrenceNumber = 1, after = true,  milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorWdgt

    slotCoords = inspectorNaked.textWidget.text.getNthPositionInStringBeforeOrAfter codeString, occurrenceNumber, after

    clickPosition = inspectorNaked.textWidget.slotCoordinates(slotCoords).translateBy new Point 3,3

    @moveToAndClick_InputEvents clickPosition, "left button", milliseconds, startTime

  clickOnSaveButtonFromTopInspector_InputEvents: (milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorWdgt
    saveButton = inspectorNaked.saveButton
    @moveToAndClick_InputEvents saveButton, "left button", milliseconds, startTime

  bringcodeStringFromTopInspectorInView_InputEvents: (codeString, occurrenceNumber = 1, after = true) ->
    inspectorNaked = @findTopWidgetByClassNameOrClass InspectorWdgt

    slotCoords = inspectorNaked.textWidget.text.getNthPositionInStringBeforeOrAfter codeString, occurrenceNumber, after

    textScrollPane = inspectorNaked.topWdgtSuchThat (item) -> item.widgetClassString() == "SimplePlainTextScrollPanelWdgt"
    textWidget = inspectorNaked.textWidget

    vBar = textScrollPane.vBar
    index = textWidget.slotRowAndColumn(slotCoords)[0]
    total = textWidget.wrappedLines.length
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

    # Patch-programming "set target": wire a CONTROLLER widget (a ColorPaletteWdgt, GrayPaletteWdgt,
    # SliderWdgt, StringWdgt, … — anything augmented with ControllerMixin) to drive a property of
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
        # ancestor HIERARCHY menu ("a Slider ➜", "a Panel ➜", …) rather than the controller's own menu —
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
        extWin.setExtent new Point 290, 240
        extWin.moveTo new Point 75, 90
        world.add extWin
        intWin = new WindowWdgt nil, nil, nil, true
        intWin.setExtent new Point 250, 160
        intWin.moveTo new Point 600, 200
        world.add intWin
        yield "waitNoInputsOngoing"
        return [extWin, intWin]
    """

    macroSubroutines.add Macro.fromString """
      dropInternalWindowIntoExternalWindow_InputEvents_Macro = (extWin, intWin) ->
        intWin.pickUp()
        @syntheticEventsMouseMove_InputEvents (@pointAtFractionOf extWin, [0.5, 0.55]), "no button", 700
        yield "waitNoInputsOngoing"
        # Phase 3 (drag-embed dwell-to-arm, spec section 6): a WINDOW payload embeds only after the dwell.
        # The window is now held STILL over the external window's content, so a NON-SCALED linger past
        # dwellToArmMs of elapsed EVENT-time ARMS it (a numeric "yield N" is real wall-clock: queueInputEvent
        # scales event.time by spanFactor, so a scaled linger would arm at one speed but not another), and the
        # release then nests it — the pre-Phase-3 outcome. The affordances are torn down on release, so the
        # composite the callers screenshot AFTER the drop is byte-identical to before.
        yield 600
        @syntheticEventsMouseClick_InputEvents()
        yield "waitNoInputsOngoing"
        return extWin
    """

    # Phase 3 (drag-embed dwell-to-arm): float-drag a WINDOW by grabPoint (typically its title bar) and
    # DWELL-ARM-embed it at destPoint. After the rule flip a window payload nests ONLY after the dwell (spec
    # section 6/7: the internal/external gate is gone — the dwell alone decides), so this presses at grabPoint,
    # drags to destPoint (the window grabs past grabDragThreshold and rides the hand), LINGERS past dwellToArmMs
    # of NON-SCALED real wall-clock — a numeric "yield" (queueInputEvent scales event.time by spanFactor, so a
    # scaled linger would arm at one speed only) — then releases: the release is an evaluation point (ActivePointer
    # Wdgt.drop re-runs the state machine), so it ARMS and the window embeds at destPoint. The grab point + dest are
    # the SAME as a plain syntheticEventsMouseMovePressDragRelease, so the nested result is byte-identical; only the
    # (torn-down-on-release) linger differs. Use THIS wherever a window must NEST — the plain press-drag-release
    # drops with no linger, which after the flip lands a window on the WORLD. Takes NO screenshots.
    macroSubroutines.add Macro.fromString """
      dwellDragWindowByGrabToEmbed_InputEvents_Macro = (grabPoint, destPoint) ->
        @moveToAndMouseDown_InputEvents grabPoint, "left button", 200
        yield "waitNoInputsOngoing"
        @syntheticEventsMouseMove_InputEvents destPoint, "left button", 400
        yield "waitNoInputsOngoing"
        yield 600
        @syntheticEventsMouseUp_InputEvents "left button"
        yield "waitNoInputsOngoing"
    """

    # Overflowing-scroll-panel fixture, SHARED by the scroll-panel drag-behaviour tests (default → the panel MOVES;
    # locked-to-desktop → the contents SCROLL; in a window → the WINDOW moves) so the setup lives in ONE place. Builds a
    # ScrollPanelWdgt with a tall wrapping TextWdgt so it OVERFLOWS (a vertical scrollbar shows), adds it to the world at
    # topLeftPoint, and RETURNS the panel. Takes NO screenshots (only a test's own sources are scanned for reference names).
    macroSubroutines.add Macro.fromString """
      buildOverflowingScrollPanelWithText_Macro = (topLeftPoint) ->
        # Build entirely through the PUBLIC widget API (macros must not use the private / low-level _-prefixed API):
        # attach first, so the public setExtent/setWidth/moveTo SELF-SETTLE and apply in place.
        panel = new ScrollPanelWdgt
        world.add panel
        panel.setExtent new Point 270, 200
        panel.moveTo topLeftPoint
        text = new TextWdgt "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer rhoncus pharetra nulla, vel maximus lectus posuere a. Phasellus finibus blandit ex vitae varius. Vestibulum blandit velit elementum, ornare ipsum sollicitudin, blandit nunc. Mauris a sapien nibh. Nulla nec bibendum quam, eu condimentum nisl. Cras consequat efficitur nisi sed ornare. Pellentesque vitae urna vitae libero malesuada pharetra. Pellentesque commodo, nulla mattis vulputate porttitor, elit augue vestibulum est, nec congue ex dui a velit. Nullam lectus leo, lobortis eget erat ac, lobortis dignissim magna. Morbi ac odio in purus blandit dignissim. Maecenas at sagittis odio."
        # a bare TextWdgt SELF-SIZES as contained text: put it in
        # FIT_BOX_TO_TEXT and it wraps to its own width and grows its HEIGHT to the
        # wrapped content (FLOAT/SCALEDOWN = render at the set font size, never
        # crop). Wrap it to 185px so the tall result OVERFLOWS the 200px panel → a
        # vertical scrollbar shows. setWidth on the attached FIT_BOX_TO_TEXT text wraps it AND fits the height.
        text.fittingSpec = FittingSpecText.FIT_BOX_TO_TEXT
        text.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT
        text.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
        text.softWrap = true
        panel.add text
        text.setWidth 185
        text.moveTo new Point (topLeftPoint.x + 12), (topLeftPoint.y + 12)
        yield "waitNoInputsOngoing"
        return panel
    """

    macroSubroutines.add Macro.fromString """
      takeScreenshot_InputEvents_Macro = (screenShotImageName) ->
        yield "waitNoInputsOngoing"
        yield "waitForScreenshotReady"
        world.automator.player.compareScreenshots screenShotImageName
        yield "waitForScreenshotHash"
    """

    macroSubroutines

