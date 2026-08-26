# MacroToolkit — the framework-side support for high-level "macro" SystemTests,
# lifted out of WorldWdgt so the macro machinery has a cohesive, documented home.
# Delegation, not a mixin: the world HAS-A one, reachable as world.macroToolkit
# (created in the WorldWdgt constructor, guarded by `if MacroToolkit?` so a
# build that does not ship the `macros` part simply has none).
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

  msSinceLastExecutedMacroStep: undefined
  aMacroIsRunning: undefined
  returnFromLastMacroStep: undefined
  # the running macro's generator; (re)created at macro start by the pump header
  # in Macro._addHeaderCode, cleared (undefined) between macros.
  macroGenerator: undefined

  # False-double-click guard state (see guardedClickStart). The most recent scheduled
  # CLICK gesture's last-release ABSOLUTE virtual time + the pointer position it landed
  # on; and currentPointerTarget = the last scheduled move's destination (= where the
  # next click lands). Used so two distinct same-spot single clicks can be pushed past
  # the hand's 300ms EVENT-TIME double-click window, now that fast-test recognition is ungated.
  # undefined until the first move/click of a macro (fresh per test — ResetWorld rebuilds the
  # toolkit).
  lastClickGestureUpTime: undefined
  lastClickGesturePosition: undefined
  currentPointerTarget: undefined

  # ─── Global playback SPEED ──────────────────────────────────────────────────
  # ONE global, three-level speed control the macro EVENT GENERATORS honour.
  # Set once at boot from ?speed=normal|fast|fastest (parsed in
  # src/boot/globalFunctions.coffee → window.FIZZYGUM_MACRO_SPEED); browser
  # default "normal" (watchable), the headless runner requests "fastest".
  #
  # There are TWO independent axes (do not conflate — see src/macros/CLAUDE.md):
  #   • SPAN  = a verb's gesture `milliseconds` × spanFactor. Because synthetic
  #     events drain over ~their timestamp span of REAL wall-clock (the per-cycle
  #     virtual clock IS wall-clock; see WorldWdgt._playQueuedEvents), span is the
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
  # recognition window (the forget gate in ActivePointerWdgt.processPointerUp). Two distinct
  # same-spot click gestures are spaced at least this far apart so they never fold into a
  # false double-click.
  @clickGuardWindowMs: 350

  # NON-scaled FLOOR on a press-drag-release's drag span. Some handlers sample the hand
  # once per FRAME (ViewportWdgt's scroll-on-drag; drag-enter/leave on drop targets),
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

  # NON-scaled SLACK a finger's press-and-hold schedules past pressAndHoldMs before it counts on
  # the hold having fired, and again before the release that follows it. The hold window is a
  # RECOGNITION window, exactly like the multi-click one @clickGuardWindowMs guards, so the speed
  # lever must not compress it: a window that shrank with the gesture would be recognised at one
  # speed and not another. The recognizer decides on each event's OWN time, so the slack only has
  # to make the crossing unambiguous.
  @holdWindowMarginMs: 60

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
  _rememberClickGesture: (upAbs, position) ->
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
  # still settling: a ViewportWdgt's post-release glide is frame-cadence
  # driven and outlives the input queue, so without this gate a screenshot
  # races it (under the pacing control the glide is suppressed at the source —
  # ViewportWdgt.mouseDownLeft — and this set stays empty; the gate is
  # defense-in-depth for any momentum that does run).
  noInputsOngoing: ->
    world.inputEventsQueue.isEmpty() and !world.anyScrollMomentumOngoing()

  # Used by a macro's screenshot step (the "waitForScreenshotReady" yield in
  # Macro's pump) and polled by the page-side rigs: decide, across cycles, when
  # the canvas is safe to capture deterministically. Native: capture immediately.
  # SWCanvas: wait until glyph atlases have loaded (no text dirty — that
  # predicate also covers a landed atlas whose placeholder-clearing refresh has
  # not been APPLIED yet). The refresh-APPLIED-but-repaint-not-yet-painted
  # window needs no gate term: every pixel read rides the end-of-cycle seam
  # (captureAtEndOfCycle below, delivered after _repaintDamagedRects), so any repaint
  # requested earlier in the read's cycle has landed by the read. Deliberately
  # NO forced pre-capture full repaint: the capture reads the INCREMENTAL
  # (damage-rect) canvas, keeping screenshots sensitive to repaint/staleness
  # defects a forced full repaint would erase. This is the single SWCanvas
  # screenshot settle gate.
  readyForMacroScreenshot: ->
    # never capture while a scroll-momentum glide is settling (matters for
    # native captures too, hence before the SWCanvas-only early return)
    return false if world.anyScrollMomentumOngoing()
    return true unless window.FIZZYGUM_USE_SWCANVAS
    if world.anyTextDirty()
      return false
    return true

  # The END-OF-CYCLE pixel-read seam: a caller registers a capture thunk and doOneCycle
  # delivers every pending one right after _repaintDamagedRects — so a delivered thunk reads a
  # fully-flushed, just-painted frame, with any repaint requested earlier in the SAME cycle
  # (e.g. a warm-atlas cache reset) already landed. Registered by the macro screenshot verb
  # (which routes compareScreenshots through it) and callable from page-side riggery as
  # world.macroToolkit.captureAtEndOfCycle(fn) — the serialization rigs wrap it in a Promise.
  # undefined when empty, so the per-cycle drain costs one existence check.
  endOfCycleCaptureRequests: undefined

  captureAtEndOfCycle: (fn) ->
    (@endOfCycleCaptureRequests ?= []).push fn
    return

  drainEndOfCycleCaptures: ->
    return unless @endOfCycleCaptureRequests?
    requests = @endOfCycleCaptureRequests
    @endOfCycleCaptureRequests = undefined
    fn() for fn in requests
    return

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
    @syntheticEventsMouseMove_InputEvents orig, "left button", 100, startTime, numberOfEventsPerMillisecond
    @syntheticEventsMouseDown_InputEvents "left button", startTime + 100
    @syntheticEventsMouseMove_InputEvents dest, "left button", flooredDrag, startTime + 100 + 100, dragEventsPerMs, orig
    @syntheticEventsMouseUp_InputEvents "left button", startTime + 100 + 100 + flooredDrag + 100

  # This should be used if you want to drag from point A to B to C ...
  # If rather you want to just drag from point A to point B,
  # then just use syntheticEventsMouseMovePressDragRelease_InputEvents
  # same optional-parameter ordering as syntheticEventsMouseMove_InputEvents, which this delegates to
  syntheticEventsMouseMoveWhileDragging_InputEvents: (dest, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1, orig = world.hand.position()) ->
    # floor the span, keep the count constant (see syntheticEventsMouseMovePressDragRelease)
    flooredMs = @dragSpanWithFloor milliseconds
    dragEventsPerMs = numberOfEventsPerMillisecond * milliseconds / flooredMs
    @syntheticEventsMouseMove_InputEvents dest, "left button", flooredMs, startTime, dragEventsPerMs, orig

  # mouse moves need an origin and a destination, so we
  # need to place the mouse in _some_ place to begin with
  # in order to do that.
  _syntheticEventsMousePlace_InputEvents: (place = new Point(0,0), scheduledTimeOfEvent = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @currentPointerTarget = place
    @queueInputEvent PointermoveInputEvent.synthetic 0, 0, false, false, false, false, scheduledTimeOfEvent, place.x, place.y

  # Optional parameters are ordered by how often a caller actually specifies one, most-specified
  # first, so no caller ever has to pass a hole to reach a later argument. `orig` is last because
  # it is almost always the default: the move starts wherever the hand currently is.
  syntheticEventsMouseMove_InputEvents: (dest, whichButton = "no button", milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1, orig = world.hand.position()) ->
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

    dest = @_screenPointOfTarget dest
    orig = @_screenPointOfTarget orig

    # where the pointer ends up — read by the click verbs as the click position for the
    # false-double-click guard (a click lands wherever the last move left the pointer)
    @currentPointerTarget = dest

    @_sampleMovePath orig, dest, milliseconds, startTime, numberOfEventsPerMillisecond, (scheduledTimeOfEvent, nextX, nextY) =>
      @queueInputEvent PointermoveInputEvent.synthetic button, buttons, false, false, false, false, scheduledTimeOfEvent, nextX, nextY

  # WHERE A GESTURE AIMS, resolved to a screen point. A WIDGET aims at its on-screen centre: the
  # plane centre mapped up through every mapping ancestor (island transforms AND scroll
  # translations) — identity (the same point) for the common unmapped widget, the on-screen pixel
  # for a scrolled or tilted one. A Point is taken as given. Every verb that accepts either kind of
  # target asks this, so a mouse gesture and a finger's aim at exactly the same pixel.
  _screenPointOfTarget: (positionOrWidget) ->
    if positionOrWidget instanceof Widget
      positionOrWidget.localPointToScreen positionOrWidget.center()
    else
      positionOrWidget

  # THE SAMPLED PATH of a pointer move, written once: expoOut-eased, rounded to whole pixels and
  # DEDUPED, one call to `queueOneSample (time, x, y)` per surviving sample. What differs between a
  # mouse's move and a finger's is only how a sample is queued — which KIND constructs it, and
  # whether its time is scaled — so the caller hands that one step in and both kinds follow the
  # identical trajectory, which is what lets a test contrast them.
  #   Math.round on the count so a drag's span-floored fractional events-per-ms still yields EXACTLY
  # the un-floored integer sample count (so expoOut samples the identical path). A no-op for the
  # ordinary whole-number cases.
  _sampleMovePath: (orig, dest, milliseconds, startTime, numberOfEventsPerMillisecond, queueOneSample) ->
    numberOfEvents = Math.round(milliseconds * numberOfEventsPerMillisecond)
    for i in [0...numberOfEvents]
      scheduledTimeOfEvent = startTime + i/numberOfEventsPerMillisecond
      nextX = Math.round @expoOut i, orig.x, (dest.x-orig.x), numberOfEvents
      nextY = Math.round @expoOut i, orig.y, (dest.y-orig.y), numberOfEvents
      if nextX != prevX or nextY != prevY
        prevX = nextX
        prevY = nextY
        queueOneSample scheduledTimeOfEvent, nextX, nextY
    return

  # Schedules the down/up in ABSOLUTE (already-spanFactor-scaled) time and pushes them
  # NON-scaled, so a LEFT click can be pushed past the hand's real double-click window
  # of a previous same-spot click (the false-double-click guard). Right clicks don't fold,
  # so they skip the guard. At normal (spanFactor 1) this is byte-identical to before.
  syntheticEventsMouseClick_InputEvents: (whichButton = "left button", milliseconds = 100, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    isLeft = (whichButton == "left button")
    downAbs = if isLeft then (@guardedClickStart (@scaledAbs startTime), @currentPointerTarget) else (@scaledAbs startTime)
    upAbs = downAbs + @clickHoldWithFloor milliseconds
    if isLeft then @_rememberClickGesture upAbs, @currentPointerTarget
    @syntheticEventsMouseDown_InputEvents whichButton, downAbs, true
    @syntheticEventsMouseUp_InputEvents whichButton, upAbs, true

  # A SHIFT-modified left click: the same down+up as syntheticEventsMouseClick_InputEvents, but with the
  # event's shiftKey flag set (the 4th parameter of Pointer{down,up}InputEvent.synthetic — button, buttons,
  # ctrlKey, shiftKey, altKey, metaKey, time, and the optional worldX/worldY a down/up omits: a synthesised
  # press states no place, so the pointer keeps the position it holds). A click carrying shiftKey makes an editable
  # StringWdgt/TextWdgt EXTEND its selection to the click point (mouseClickLeft reads shiftKey) instead
  # of just repositioning the caret. Left button only (down buttons=1, up buttons=0).
  syntheticEventsMouseShiftClick_InputEvents: (milliseconds = 100, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    # absolute (scaled) times + guard + non-scaled push, like syntheticEventsMouseClick —
    # a shift-click is still a left-button click and would otherwise fold into a false
    # double-click with a prior same-spot click once recognition is ungated.
    downAbs = @guardedClickStart (@scaledAbs startTime), @currentPointerTarget
    upAbs = downAbs + milliseconds * @spanFactor()
    @_rememberClickGesture upAbs, @currentPointerTarget
    @queueInputEvent (PointerdownInputEvent.synthetic 0, 1, false, true, false, false, downAbs), true
    @queueInputEvent (PointerupInputEvent.synthetic 0, 0, false, true, false, false, upAbs), true

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

    @queueInputEvent (PointerdownInputEvent.synthetic button, buttons, false, false, false, false, startTime), nonScaled

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

    @queueInputEvent (PointerupInputEvent.synthetic button, buttons, false, false, false, false, startTime), nonScaled

  # The browser CONFISCATING the stroke in progress (a system gesture takes it over, a palm is
  # rejected, the tab goes away). It states no place — like a synthesised down/up, so the hand keeps
  # the position it holds (see PointerInputEvent.worldX) — and no button, because a cancelled stroke
  # presses nothing any more. The hand ABORTS on it: no click dispatch, no menu dismissal, a
  # non-float drag ended, a carried payload landed on the world where it visibly is
  # (ActivePointerWdgt.processPointerCancel). The only synthetic event with no user gesture behind
  # it — nothing a user does produces a cancel; the browser does.
  syntheticEventsPointerCancel_InputEvents: (startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @queueInputEvent PointercancelInputEvent.synthetic 0, 0, false, false, false, false, startTime

  # ── THE FINGER'S PRIMITIVES ─────────────────────────────────────────────────────────────────
  # A finger's stroke is not a mouse's, in three ways these verbs reproduce faithfully:
  #  - EVERY event states its own place, and no positioning move precedes a press. There is no
  #    hover to have walked the pointer there, so the down carries the position (the position head
  #    in ActivePointerWdgt.processPointerDown is what consumes it).
  #  - The KIND rides each event (PointerInputEvent.syntheticTouch), so the hand answers per
  #    STROKE — which is the whole of the gesture grammar's key (ruling I2).
  #  - The whole stroke is scheduled in ABSOLUTE (already-scaled) time and pushed NON-SCALED, the
  #    click verbs' idiom one gesture wider: a finger's press-and-hold must cross
  #    `pressAndHoldMs` of REAL time, and a recognition window the speed lever compressed would be
  #    recognised at one speed and not another.

  # The three one-event pushes every touch verb below composes. Each states its place, and each
  # takes an ABSOLUTE time its caller has already scaled (hence the non-scaled push).
  _queueTouchDown: (place, timeAbs) ->
    @queueInputEvent (PointerdownInputEvent.syntheticTouch 0, 1, false, false, false, false, timeAbs, place.x, place.y), true

  _queueTouchMove: (place, timeAbs) ->
    @queueInputEvent (PointermoveInputEvent.syntheticTouch 0, 1, false, false, false, false, timeAbs, place.x, place.y), true

  _queueTouchUp: (place, timeAbs) ->
    @queueInputEvent (PointerupInputEvent.syntheticTouch 0, 0, false, false, false, false, timeAbs, place.x, place.y), true

  # A TAP: a position-carrying down and up with nothing before either — the grammar's "a tap is a
  # click" row. Guarded and hold-floored exactly like a mouse click, so two taps in the same spot
  # never fold into a false double-click and the pressed frame is still sampled.
  # Returns the absolute time of the release (a caller sequencing a later gesture reads it).
  syntheticEventsTouchTap_InputEvents: (positionOrWidget, milliseconds = 100, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    place = @_screenPointOfTarget positionOrWidget
    @currentPointerTarget = place
    downAbs = @guardedClickStart (@scaledAbs startTime), place
    upAbs = downAbs + @clickHoldWithFloor milliseconds
    @_rememberClickGesture upAbs, place
    @_queueTouchDown place, downAbs
    @_queueTouchUp place, upAbs
    upAbs

  # A PRESS-AND-HOLD: the down, then a SAME-POSITION move scheduled past `pressAndHoldMs` of real
  # time. That move is the drained event whose own time crosses the window, and crossing it is what
  # fires the hold — the recognizer decides at every drained event and at every cycle re-entry
  # (ActivePointerWdgt), so a stationary finger needs an event to decide ON.
  # `alsoRelease` (default true) ends the stroke with the up; pass false to keep the finger down —
  # the hold-then-drag verb below does. Returns the absolute time of the last event scheduled.
  syntheticEventsTouchHold_InputEvents: (positionOrWidget, alsoRelease = true, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    place = @_screenPointOfTarget positionOrWidget
    @currentPointerTarget = place
    downAbs = @scaledAbs startTime
    holdCrossedAbs = downAbs + WorldWdgt.preferencesAndSettings.pressAndHoldMs + MacroToolkit.holdWindowMarginMs
    @_queueTouchDown place, downAbs
    @_queueTouchMove place, holdCrossedAbs
    return holdCrossedAbs unless alsoRelease
    upAbs = holdCrossedAbs + MacroToolkit.holdWindowMarginMs
    @_queueTouchUp place, upAbs
    upAbs

  # A DRAG: the down, the sampled path to the destination, the up there. The span is floored to
  # @dragFloorMs — DIRECTLY, not through dragSpanWithFloor, which inflates a span so it survives
  # the speed lever and would inflate a non-scaled one into seconds — so the per-frame samplers a
  # drag drives (a viewport's scroll step above all) see several frames whatever the speed.
  # Returns the absolute time of the release.
  syntheticEventsTouchDrag_InputEvents: (orig, dest, millisecondsForDrag = 600, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1) ->
    downAbs = @scaledAbs startTime
    @_queueTouchDown (@_screenPointOfTarget orig), downAbs
    @_dragTouchFromHeldPress orig, dest, millisecondsForDrag, downAbs + MacroToolkit.holdWindowMarginMs, numberOfEventsPerMillisecond

  # CARRY A FINGER THAT IS ALREADY DOWN, then let go — the second half of the grammar's LIFT.
  # HOLD-THEN-DRAG is these two verbs in sequence and deliberately NOT one composed verb: hold with
  # `alsoRelease` false, drain the queue, assert or screenshot the open menu, then continue THE SAME
  # stroke with this (no release happens in between, which is the whole point — a released-and-
  # re-pressed pair would witness nothing). `orig` is where the press is standing (a Widget resolves
  # to its centre, as everywhere else).
  # Returns the absolute time of the release.
  syntheticEventsTouchDragFromHeldPress_InputEvents: (orig, dest, millisecondsForDrag = 600, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), numberOfEventsPerMillisecond = 1) ->
    @_dragTouchFromHeldPress orig, dest, millisecondsForDrag, (@scaledAbs startTime), numberOfEventsPerMillisecond

  # The move stream + release shared by the drag verbs above: the press is already down and
  # held at `orig` when this runs, so it only carries the finger and lets go.
  _dragTouchFromHeldPress: (orig, dest, millisecondsForDrag, moveStartAbs, numberOfEventsPerMillisecond) ->
    origPlace = @_screenPointOfTarget orig
    destPlace = @_screenPointOfTarget dest
    dragSpan = Math.max millisecondsForDrag, MacroToolkit.dragFloorMs
    @_sampleMovePath origPlace, destPlace, dragSpan, moveStartAbs, numberOfEventsPerMillisecond, (timeAbs, x, y) =>
      @_queueTouchMove (new Point x, y), timeAbs
    @currentPointerTarget = destPlace
    upAbs = moveStartAbs + dragSpan + MacroToolkit.holdWindowMarginMs
    @_queueTouchUp destPlace, upAbs
    upAbs

  moveToAndClick_InputEvents: (positionOrWidget, whichButton = "left button", milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents positionOrWidget, "no button", milliseconds, startTime
    @syntheticEventsMouseClick_InputEvents whichButton, 100, startTime + milliseconds + 100

  # Move to a point/widget then MOUSE DOWN and HOLD — the press half of a click, scheduled AFTER the move
  # completes (like moveToAndClick_InputEvents, but with no release). Use it when the press ITSELF produces
  # the state to capture, so the screenshot must be taken before the release: a mouse-DOWN (not the full
  # click) dismisses an unpinned menu cascade (ActivePointerWdgt.cleanupMenuWdgts), and a mouse-DOWN drops a
  # float-dragged widget (processPointerDown -> drop). Pattern: `@moveToAndMouseDown_InputEvents target` ->
  # `yield "waitNoInputsOngoing"` -> `takeScreenshot_InputEvents_Macro "…"` (captures with the button still
  # held) -> `@syntheticEventsMouseUp_InputEvents()` -> `yield "waitNoInputsOngoing"`.
  moveToAndMouseDown_InputEvents: (positionOrWidget, whichButton = "left button", milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents positionOrWidget, "no button", milliseconds, startTime
    @syntheticEventsMouseDown_InputEvents whichButton, startTime + milliseconds + 100

  # Resolve a [widget | text-description identifier | Point] + an [fx, fy] fraction to an absolute
  # world Point inside that widget: (left + round(width*fx), top + round(height*fy)) of the LIVE widget,
  # so it follows the widget if it has moved/resized. Shared by the fractional click/double/triple-click
  # verbs (and any other verb that needs to aim at a point inside a widget).
  pointAtFractionOf: (widgetOrIdentifier, fraction) ->
    widget = if (typeof widgetOrIdentifier == "string") or (widgetOrIdentifier instanceof Array)
      @findWidgetByTextDescription widgetOrIdentifier
    else
      widgetOrIdentifier
    # PLANE-local by contract — macros consume this as a geometry VALUE (e.g. deriving an
    # expected caret slot from the same virtual point they click). AIMING always goes
    # through screenPointAtFractionOf / the Screen verbs, which map this up to the pixel.
    new Point (Math.round(widget.width() * fraction[0]) + widget.left()), (Math.round(widget.height() * fraction[1]) + widget.top())

  moveToAndClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction, whichButton = "left button", milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClick_InputEvents (@screenPointAtFractionOf widgetOrIdentifier, fraction), whichButton, milliseconds, startTime

  # Affine transforms (docs/plans/affine-transforms-plan.md §4.6): the SCREEN-plane point at
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
  # ActivePointerWdgt.processPointerUp) — so the click UPs must fall within that window of each other; we space them ~120ms apart. No move
  # between the clicks (same widget, same point) — recognition also requires the clicks be on the same
  # widget within grabDragThreshold.
  # The APPROACH (startTime) is scaled by the speed level (it follows the scaled positioning move), but the
  # inter-click 120ms / 50ms spacing is kept NON-scaled so the clicks always land inside the 300ms
  # event-time window at every speed. The false-double-click guard is applied ONCE to the first click (vs a prior
  # distinct gesture); clicks 2..N are the DELIBERATE repeats that MUST fold, so they skip it.
  _syntheticEventsConsecutiveLeftClicks_InputEvents: (numberOfClicks = 2, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime(), millisecondsBetweenClicks = 120, clickMilliseconds = 50) ->
    firstDownAbs = @guardedClickStart (@scaledAbs startTime), @currentPointerTarget
    for i in [0...numberOfClicks]
      t = firstDownAbs + i * millisecondsBetweenClicks
      @syntheticEventsMouseDown_InputEvents "left button", t, true
      @syntheticEventsMouseUp_InputEvents "left button", t + clickMilliseconds, true
    @_rememberClickGesture (firstDownAbs + (numberOfClicks - 1) * millisecondsBetweenClicks + clickMilliseconds), @currentPointerTarget

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
    @_nLeftClicksAtFractionOf_InputEvents 2, widgetOrIdentifier, fraction, milliseconds, startTime

  tripleClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction = [0.5, 0.5], milliseconds = 600, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @_nLeftClicksAtFractionOf_InputEvents 3, widgetOrIdentifier, fraction, milliseconds, startTime

  # Shared body of double/tripleClickAtFractionOf_InputEvents: position the pointer at the fractional point
  # (so the fake pointer shows), then fire `numberOfClicks` consecutive left clicks that the hand folds into a
  # double/triple click. The +100ms lead-in after the positioning move is non-scaled at every speed level (see
  # the comment above on the deterministic event-time recognition window).
  _nLeftClicksAtFractionOf_InputEvents: (numberOfClicks, widgetOrIdentifier, fraction = [0.5, 0.5], milliseconds = 600, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    # public-call-sanctioned: syntheticEventsMouseMove_InputEvents is an L1 event-synthesis primitive (it
    # pushes a queued mouse-move, not any settling/orchestration) — this is the SAME call the public
    # double/tripleClick verbs made inline before their shared body was factored here; behaviour is unchanged.
    @syntheticEventsMouseMove_InputEvents (@screenPointAtFractionOf widgetOrIdentifier, fraction), "no button", milliseconds, startTime
    @_syntheticEventsConsecutiveLeftClicks_InputEvents numberOfClicks, startTime + milliseconds + 100

  # SHIFT+left-click at a fractional point inside a located widget — move the pointer there (no button),
  # then click with Shift held. In editable text a plain click sets the caret while a shift-click EXTENDS the
  # selection from the caret to the click point; so the pattern is a plain moveToAndClickAtFractionOf to drop
  # the anchor caret, then one or more shiftClickAtFractionOf to grow the selection. The selection-extend
  # sibling of the double-/triple-click verbs. Queues input events — follow with `yield "waitNoInputsOngoing"`.
  shiftClickAtFractionOf_InputEvents: (widgetOrIdentifier, fraction, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents (@screenPointAtFractionOf widgetOrIdentifier, fraction), "no button", milliseconds, startTime
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
  # owner; ViewportWdgt.wheel scrolls itself or escalates to its parent at the travel limit). A
  # POSITIVE deltaY scrolls content DOWN; deltaX scrolls horizontally. Queues input events — follow with
  # `yield "waitNoInputsOngoing"`.
  wheelOn_InputEvents: (widgetOrIdentifier, deltaY, deltaX = 0, fraction = [0.5, 0.5], milliseconds = 600, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @syntheticEventsMouseMove_InputEvents (@screenPointAtFractionOf widgetOrIdentifier, fraction), "no button", milliseconds, startTime
    @syntheticEventsWheel_InputEvents deltaX, deltaY, startTime + milliseconds + 100

  # Click a SliderWdgt's TRACK (its background, OUTSIDE the button) at a point a fraction along its
  # length, to JUMP the slider button there. For a viewport's scrollbar — a ViewportWdgt's @vBar
  # / @hBar (both SliderWdgts) — this scrolls the content to that position: SliderWdgt.mouseDownLeft,
  # when the slider's parent is a ViewportWdgt (or PromptWdgt), non-float-drags the button to the
  # click point (ActivePointerWdgt.nonFloatDragWdgtFarAwayToHere), and a click leaves it there. `fraction`
  # is [fx, fy] of the slider's bounds — for a vertical scrollbar pass e.g. [0.5, 0.8] (80% down the
  # track); for a horizontal one [0.8, 0.5]. Queues input events — follow with `yield
  # "waitNoInputsOngoing"`. A slider NOT parented to a viewport ignores the track click (it escalates
  # the event) — that is the negative companion behaviour (sliderNotOnViewportBackground…). Composes
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
  # only when the slider is parented to a ViewportWdgt/PromptWdgt); a free-standing controller slider
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
    buttonCentre = @screenPointAtFractionOf slider.button, [0.5, 0.5]
    trackPoint = @screenPointAtFractionOf slider, fraction
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
    @_selectionToClipboardEvent_InputEvents CutInputEvent, startTime

  copySelection_InputEvents: (startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @_selectionToClipboardEvent_InputEvents CopyInputEvent, startTime

  # Shared body of cut/copySelection_InputEvents: read the current selection synchronously (it still exists
  # at call time), enqueue a Cut/Copy event CARRYING that text (Fizzygum keeps no internal clipboard — see the
  # comment above), and RETURN the text so the caller can paste it back. `eventClass` is CutInputEvent or
  # CopyInputEvent, passed as a value; both still load and are ordered correctly (build.py bundles every class;
  # the dependency finder orders by new/extends/@augmentWith edges, and each carries its own `extends
  # ClipboardInputEvent` edge — so dropping the two literal `new`s here changes nothing).
  _selectionToClipboardEvent_InputEvents: (eventClass, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    text = world.caret?.target?.selection()
    @queueInputEvent new eventClass text, true, startTime
    text

  pasteText_InputEvents: (text, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @queueInputEvent new PasteInputEvent text, true, startTime

  # WHERE A SYNTHESISED PRESS GRABS A HANDLE, and where its drag must then end. Answers the
  # [pressPoint, dropPoint] pair both handle-drag verbs push, in SCREEN coordinates.
  #
  # A handle reacts on the shape its appearance paints (HandleAppearance.shapeContainsPoint). Every
  # type but the corner resizer paints its whole box, so its centre is deep inside its shape and the
  # centre IS the press point — including the rotate handle, whose gesture reads the RAW pointer's
  # angle about the target's anchor, so moving its press point would move the angle it measures.
  #
  # The corner resizer's shape is the striped triangle whose diagonal runs exactly through the box
  # CENTRE — so there the centre is the shape's BOUNDARY, and a press a single pixel up or left of it
  # falls through to the frame, which float-drags instead of resizing. A synthesised approach lands
  # exactly there: syntheticEventsMouseMove_InputEvents samples its easing at i in [0, N), so the
  # pointer stops ~0.1% of the travel short of its destination — a whole pixel once the travel passes
  # ~470, which a park-then-aim move across the test world easily does. So aim a quarter-box deeper
  # into the corner: that clears the diagonal by handleSize/4 on each axis, far past any shortfall.
  #
  # The destination shifts by the SAME on-screen vector, so the drag vector — hence the extent the
  # gesture produces — is the centre-to-destination one the caller asks for, and the handle's CENTRE
  # still lands on the destination. localPointToScreen forward-maps through any enclosing
  # non-identity island (affine transforms §6 4A-2), so a handle inside a scaled/rotated island is
  # pressed where it actually renders and the shift is mapped with it; both operands then carry the
  # same vector through nonFloatDragging's inverse map, which cancels it exactly.
  _handlePressAndDropPoints: (handle, destination) ->
    screenCentre = handle.localPointToScreen handle.center()
    return [screenCentre, destination]  unless handle.type is "resizeBothDimensionsHandle"
    pressPoint = handle.localPointToScreen handle.center().add handle.extent().floorDivideBy 4
    [pressPoint, (destination.add pressPoint.subtract screenCentre)]

  # Drag a resize/move HANDLE (one of the handles shown after a widget's "resize/move..." menu
  # item) to a destination Point (the handle's centre lands there). Handles resize/move the target
  # via NON-float dragging (HandleWdgt.nonFloatDragging → setExtent / moveTo), so this is a real
  # press-drag-release. handleType picks the handle: "resizeBothDimensionsHandle" (bottom-right
  # corner — resizes both dimensions), "moveHandle", "resizeHorizontalHandle", "resizeVerticalHandle".
  dragResizeMoveHandleTo_InputEvents: (handleType, destination, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    handle = world.topWdgtSuchThat (item) -> (item instanceof HandleWdgt) and (item.type == handleType)
    [pressPoint, dropPoint] = @_handlePressAndDropPoints handle, destination
    @syntheticEventsMouseMovePressDragRelease_InputEvents pressPoint, dropPoint, milliseconds, startTime

  # Float-DRAG a widget (by reference, or by a recorded text-description identifier) and drop it at a
  # destination — a Point, or another widget / identifier (dropped on that target's centre). Presses at
  # the widget's centre and drags past the grab threshold so the widget is picked up onto the hand, then
  # releases over the destination. Use it to drop a widget INTO a container that accepts drops — e.g. a
  # DocumentViewport with editing enabled re-parents the dropped widget as a flowing paragraph.
  dragWidgetTo_InputEvents: (widgetOrIdentifier, destination, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    source = if (typeof widgetOrIdentifier == "string") or (widgetOrIdentifier instanceof Array)
      @findWidgetByTextDescription widgetOrIdentifier
    else
      widgetOrIdentifier
    dropPoint = if destination instanceof Point then destination else @screenPointAtFractionOf destination, [0.5, 0.5]
    @syntheticEventsMouseMovePressDragRelease_InputEvents (source.localPointToScreen source.center()), dropPoint, milliseconds, startTime

  openMenuOf_InputEvents: (widget, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    @moveToAndClick_InputEvents widget, "right button", milliseconds, startTime

  # Close a FrameWdgt by clicking the close button (the X) in its window bar. Every FrameWdgt builds
  # a `.closeButton` (a CloseIconButtonWdgt at its top-left); clicking it runs the button's actOnClick
  # → the window's closeFromFrameBar()/close(). The reusable window-chrome pattern: get a window (by a
  # kept reference, or by class + its `internal` flag) and close it through its real control button, as
  # a user would. Queues input events — follow with `yield "waitNoInputsOngoing"`.
  closeWindow_InputEvents: (windowWidget) ->
    @moveToAndClick_InputEvents windowWidget.closeButton

  # Collapse or uncollapse a FrameWdgt by clicking the collapse/uncollapse control in its window bar.
  # Every FrameWdgt builds a `.collapseUncollapseSwitchButton` (a SwitchButtonWdgt that toggles between a
  # CollapseIconButtonWdgt and an UncollapseIconButtonWdgt): clicking it when expanded collapses the
  # window to just its bar (contents.collapse()), and clicking it again — the switch now shows the
  # uncollapse icon — restores it. So this one verb both collapses and uncollapses, depending on the
  # window's current state. The window-chrome sibling of closeWindow_InputEvents. Queues input events —
  # follow with `yield "waitNoInputsOngoing"`.
  collapseOrUncollapseWindow_InputEvents: (windowWidget) ->
    @moveToAndClick_InputEvents windowWidget.collapseUncollapseSwitchButton

  # Resize a FrameWdgt by dragging its resize handle to a destination. Every FrameWdgt builds a `.resizer`
  # (a HandleWdgt laid out at its bottom-right corner); a NON-float press-drag-release on it resizes the
  # window (HandleWdgt.nonFloatDragging → setExtent on the window). The window-chrome sibling of close/
  # collapse: reach the window's OWN resize control by reference (vs hunting a HandleWdgt by coordinates —
  # several windows each have one). destination may be a Point or another widget (dragged to its centre).
  # Queues input events — follow with `yield "waitNoInputsOngoing"`.
  dragWindowResizerTo_InputEvents: (windowWidget, destination, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    dropPoint = if destination instanceof Point then destination else @screenPointAtFractionOf destination, [0.5, 0.5]
    [pressPoint, dropPoint] = @_handlePressAndDropPoints windowWidget.resizer, dropPoint
    @syntheticEventsMouseMovePressDragRelease_InputEvents pressPoint, dropPoint, milliseconds, startTime

  getMostRecentlyOpenedMenu: ->
    # gets the last element added to the "freshlyCreatedPopUps" set
    # (Sets keep order of insertion)
    Array.from(world.freshlyCreatedPopUps).pop()

  # THE ROW LOCATORS' LAST STEP: hand back the row the caller named, at a place the caller can
  # actually reach it. A pop-up taller (or wider) than the world does not grow past it — its rows
  # viewport caps itself at the world less the frame's chrome (PopUpRowsViewportWdgt's measure) and
  # scrolls the remainder — so a row past the fold is fully present in the rows panel (the locators
  # walk the TREE, which scrolling never moves) yet lies OUTSIDE the viewport's visible box. Its
  # centre is then a screen pixel the viewport clips away, and the click every caller aims there
  # lands on whatever sits behind the menu: the submenu never opens and the macro unravels a step
  # later on the menu that isn't there.
  #   A user reaches such a row by scrolling it into view first, so the toolkit does the same —
  # minimally (the row is brought just inside the nearer edge, a row taller than the box aligned to
  # its top), and through the viewport's own public scroll pin, `setScrollY`/`setScrollX`: the very
  # setters a scrollbar drag drives, which clamp at the movement cores and re-lay the content and
  # bars exactly as a gesture does. Never a raw offset write.
  #   The scroll is CONDITIONAL on the row being out of view, and that is the point: a row inside
  # the box takes no scroll at all, so every menu that fits behaves as it always has.
  _menuRowScrolledIntoView: (theItem) ->
    return theItem unless theItem?
    foundViewport = theItem.parentThatIsA PopUpRowsViewportWdgt
    return theItem unless foundViewport?
    viewport = foundViewport[0]
    return theItem unless viewport.isScrollableNow()
    # both boxes expressed on the SCREEN, since the row's plane is the scrolled one and the
    # viewport's is not — localPointToScreen is what carries the scroll translation between them
    rowTopLeft = theItem.localPointToScreen new Point theItem.left(), theItem.top()
    rowBottomRight = theItem.localPointToScreen new Point theItem.right(), theItem.bottom()
    boxTopLeft = viewport.localPointToScreen new Point viewport.left(), viewport.top()
    boxBottomRight = viewport.localPointToScreen new Point viewport.right(), viewport.bottom()
    deltaY = @_scrollDeltaBringingIntoView rowTopLeft.y, rowBottomRight.y, boxTopLeft.y, boxBottomRight.y
    deltaX = @_scrollDeltaBringingIntoView rowTopLeft.x, rowBottomRight.x, boxTopLeft.x, boxBottomRight.x
    viewport.setScrollY viewport.getScrollY() + deltaY  if deltaY != 0
    viewport.setScrollX viewport.getScrollX() + deltaX  if deltaX != 0
    theItem

  # How far one axis' scroll offset must move so the span [rowStart, rowEnd] lies inside the window
  # [boxStart, boxEnd]: nothing when it already does; otherwise just enough to bring the overshooting
  # end back to the window's matching edge. A row LONGER than the window overshoots at BOTH ends and
  # takes the start arm, so it shows its beginning rather than its end. A positive offset scrolls the
  # content toward its end, which is why a row past the window's end yields a positive delta.
  _scrollDeltaBringingIntoView: (rowStart, rowEnd, boxStart, boxEnd) ->
    return rowStart - boxStart if rowStart < boxStart
    return rowEnd - boxEnd if rowEnd > boxEnd
    0

  getTextMenuItemFromMenu: (theMenu, theLabel) ->
    theItem = theMenu.topWdgtSuchThat (item) ->
      if item.labelString?
        item.labelString == theLabel
      else
        false
    @_menuRowScrolledIntoView theItem

  # Like getTextMenuItemFromMenu but matches by label PREFIX. Use it when a menu item's full label
  # carries a suffix you should not depend on — e.g. the "attach..." target menu labels each candidate
  # `<widget>.toString().replace("Wdgt","") + " ➜"`, so a RectangleWdgt reads "a Rectangle#1 ➜" (an
  # instance number + a trailing arrow). Match the stable head ("a Rectangle") instead of the exact
  # string, and only the intended target is hit even when the menu also lists the World and the widget's
  # own handle.
  getTextMenuItemFromMenuByPrefix: (theMenu, thePrefix) ->
    theItem = theMenu.topWdgtSuchThat (item) ->
      if item.labelString?
        item.labelString.startsWith thePrefix
      else
        false
    @_menuRowScrolledIntoView theItem

  getTextMenuItemFromMenuByContains: (theMenu, theSubstring) ->
    theItem = theMenu.topWdgtSuchThat (item) ->
      if item.labelString?
        item.labelString.includes theSubstring
      else
        false
    @_menuRowScrolledIntoView theItem

  # Move to and click a menu/prompt item by its label, in a SPECIFIC menu you already hold a reference
  # to. Prefer this over moveToItemOfTopMenuAndClick_InputEvents whenever you interact with a popup more
  # than once (e.g. click a slider/palette INSIDE a prompt, THEN click its "Ok"): getMostRecentlyOpenedMenu
  # reads world.freshlyCreatedPopUps, which EVERY pointer-up clears (ActivePointerWdgt.processPointerUp), so it
  # is only valid for the FIRST interaction after a popup opens. Capture the popup reference while it is
  # still fresh (right after it opens) and drive its later items through this method.
  moveToItemOfMenuAndClick_InputEvents: (theMenu, theLabel) ->
    theItem = @getTextMenuItemFromMenu theMenu, theLabel
    @moveToAndClick_InputEvents theItem

  moveToItemOfTopMenuAndClick_InputEvents: (theLabel) ->
    @moveToItemOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), theLabel

  # Move to and click the menu item whose label STARTS WITH a prefix, in a menu you hold a reference to.
  # The prefix sibling of moveToItemOfMenuAndClick_InputEvents — for menus whose item labels carry a
  # variable suffix (the "attach..."/"choose target:" menu labels each target
  # `toString().replace("Wdgt","") + " ➜"`), match the stable Wdgt-stripped class-name head so you pick
  # the intended target rather than the first/Nth item.
  moveToItemStartingWithOfMenuAndClick_InputEvents: (theMenu, thePrefix) ->
    theItem = @getTextMenuItemFromMenuByPrefix theMenu, thePrefix
    @moveToAndClick_InputEvents theItem

  # Move to and click the menu item whose label CONTAINS a substring, in a menu you hold a reference to.
  # The substring sibling of the prefix verb — for items whose label carries a leading decoration the prefix
  # can't match, e.g. a checkmark toggle ("soft wrap".tick() renders "✓ soft wrap"): match "soft wrap".
  moveToItemContainingOfMenuAndClick_InputEvents: (theMenu, theSubstring) ->
    theItem = @getTextMenuItemFromMenuByContains theMenu, theSubstring
    @moveToAndClick_InputEvents theItem

  # Click a menu's title bar (its frame bar's title piece, reachable as menu.label) to PIN the menu open.
  # The piece escalates its click to the strip, and FrameBarWdgt.mouseClickLeft -> frame.pinPopUp on a
  # transient frame: pinning takes the menu's lifetime
  # to 'persistent' and removes it from world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren,
  # so a subsequent click on the empty desktop no longer dismisses it (a still-transient menu would vanish);
  # the pinned menu is then furniture on the desktop and wears the WINDOW manifestation -- window strip with
  # close and collapse, boxy body, desktop shadow. Pass a menu reference (e.g. getMostRecentlyOpenedMenu()).
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

  # Assert how many resize/move HandleWdgts are currently attached to a widget
  # (the "resize/move..." chrome). Pushes no input events and does not yield.
  # A toolkit method for the same reason as the menu assertions above: the
  # assertion sink's mid-name "Macro" must not appear in macro source.
  assertHandleCountOn: (aWdgt, expectedCount) ->
    found = (aWdgt.children.filter (c) -> c instanceof HandleWdgt).length
    world.automator.player.recordMacroAssertion (found == expectedCount), "handle count on " + aWdgt.toString(), expectedCount, found

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

  # The BARE label of the one ticked row of a menu -- the tick prefix stripped, so a test can say
  # what the menu currently SHOWS rather than assert a decorated string. For the ticked-menu family
  # (wallpapers, fonts, and any row carrying a MenuRowReflectionSpec built by tickWhen): those menus
  # tick exactly one row, so "which one" is the whole state. undefined when none is ticked.
  tickedRowLabelOfMenu: (menu) ->
    for row in menu.rowsPanel.children
      if row.isTicked?()
        return row.label.text.replace tick, ""
    return undefined

  # Topmost widget matching either a class-name string (compared via
  # widgetClassString) or a class object (compared via instanceof).
  # ⚠ InspectorWdgt is the LAZY 'meta-tools' part, and this class is the EAGER 'macros' one, so the
  # bare name would be an unguarded reference into something a profile may not ship and a page may
  # not yet have fetched. The bail-out is exact rather than defensive: this asks "is an inspector
  # already OPEN", and without the part no inspector can exist, so undefined is the true answer.
  # ⚠ It keeps the CLASS rather than the string "InspectorWdgt", because the string form matches an
  # exact widgetClassString() and would quietly stop finding ClassInspectorWdgt, its subclass.
  _findTopInspector: ->
    return undefined unless InspectorWdgt?
    @findTopWidgetByClassNameOrClass InspectorWdgt

  findTopWidgetByClassNameOrClass: (widgetNameOrClass) ->
    if typeof widgetNameOrClass == "string"
      world.topWdgtSuchThat (item) -> item.widgetClassString() == widgetNameOrClass
    else
      world.topWdgtSuchThat (item) -> item instanceof widgetNameOrClass

  # Topmost widget whose getTextDescription() matches an identifier triple
  # [textDescription, occurrenceIndex, totalOccurrences] — a stable locator
  # (world.getWidgetViaTextLabel).
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

    # a one-line content collapses the fraction to 0/0 — the top of the (zero) travel
    handleCenterOffset = if total > 1 then Math.round index * handleCenterRange / (total-1) else 0

    # geometry above is the BAR's plane; the returned pair AIMS a drag, so map both
    # endpoints to the screen (identity unless the bar's viewport is itself on a mapped plane)
    [(vBarHandle.localPointToScreen vBarHandleCenter),
     (vBarHandle.localPointToScreen vBarHandleCenter.translateBy new Point(0,handleCenterOffset))]

  # Robustly scroll an inspector member/property `list` so `itemString`'s row lands a couple of rows
  # BELOW the pane's top edge -- clear of both clip edges and reliably clickable -- regardless of how
  # long the list is. It uses the REAL row height + visible pane height (not the vBar handle-fraction
  # heuristic in calculateVertBarMovement, which maps index/(total-1) and so lands the target at the
  # pane's BOTTOM edge for large indices; adding a single inherited member then tips it out of view and
  # a click on the clipped row selects the wrong property). Number of scroll positions = total -
  # visibleRows (rows you can put at the top), so aiming (index - 2) at the top puts the target 2 rows
  # down. Robust to member-list length: the target always lands at the same safe offset.
  scrollInspectorListItemIntoView_InputEvents: (list, itemString) ->
    index = list.elements.indexOf itemString
    vBar = list.vBar
    vBarHandle = vBar.children[0]

    # a currently-rendered row gives the true row PITCH (the list shows its top rows before any
    # scroll). Ask for the ROW — a widget carrying a labelString — and not for the label inside it:
    # a row is at least menuRowHeight tall while its label is only as tall as its glyphs, so
    # measuring the label under-counts the pitch and over-counts how many rows the pane shows,
    # which lands the target well below the fold on any list long enough to need scrolling.
    sampleRow = list.topWdgtSuchThat (m) -> m.labelString?
    rowHeight = if sampleRow? and sampleRow.height() > 0 then sampleRow.height() else 1
    visibleRows = Math.max 1, Math.floor(list.height() / rowHeight)
    scrollPositions = Math.max 1, list.elements.length - visibleRows
    topIndex = Math.max 0, Math.min(scrollPositions, index - 2)
    scrollFraction = topIndex / scrollPositions

    handleTravel = (vBar.bottom() - vBarHandle.height()) - vBar.top()
    handleTargetCenterY = vBar.top() + Math.round(scrollFraction * handleTravel) + vBarHandle.height()/2
    handleCurrentCenter = vBarHandle.center()
    # bar-plane geometry aimed at the screen (identity unless the bar's viewport is nested
    # on a mapped plane)
    @syntheticEventsMouseMovePressDragRelease_InputEvents (vBarHandle.localPointToScreen handleCurrentCenter), (vBarHandle.localPointToScreen new Point handleCurrentCenter.x, handleTargetCenterY)

  bringListItemFromTopInspectorInView_InputEvents: (listItemString) ->
    inspectorNaked = @_findTopInspector()
    @scrollInspectorListItemIntoView_InputEvents inspectorNaked.list, listItemString

  clickOnListItemFromTopInspector_InputEvents: (listItemString, milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @_findTopInspector()

    list = inspectorNaked.list

    entry = list.topWdgtSuchThat (item) ->
      if item.text?
        item.text == listItemString
      else
        false

    # Clamp the click into the pane's visible box: the scroll verb's handle-drag is
    # quantized to scrollbar pixels, so a member-list length change can leave the found
    # row EDGE-CLIPPED at the pane top — a click 2px under a clipped top lands off-pane
    # and selects nothing (measured 2026-08-06, kept-spec arc P1, via the inspector-alpha
    # test's local twin of this click). Identical to the plain top-edge click whenever
    # the row is fully visible.
    # the clamp compares the row's PLANE geometry with the pane's visible window, so express
    # the window's top in the ROW'S plane (screenPointToMyPlane — identity when the list is
    # unscrolled), do the arithmetic there, and AIM at the resulting point's on-screen pixel
    windowTopInEntryPlane = (entry.screenPointToMyPlane new Point list.left(), list.top()).y
    clickY = Math.max (entry.top() + 2), (windowTopInEntryPlane + 2)
    clickY = Math.min clickY, (entry.bottom() - 2)
    @moveToAndClick_InputEvents (entry.localPointToScreen new Point (entry.left() + 10), clickY), "left button", milliseconds, startTime


  clickOnCodeBoxFromTopInspectorAtCodeString_InputEvents: (codeString, occurrenceNumber = 1, after = true,  milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @_findTopInspector()

    slotCoords = inspectorNaked.textWidget.text.getNthPositionInStringBeforeOrAfter codeString, occurrenceNumber, after

    # slotCoordinates is PLANE-local to the detail text — aim at its on-screen pixel
    # (identity when the detail pane is unscrolled)
    clickPosition = inspectorNaked.textWidget.localPointToScreen inspectorNaked.textWidget.slotCoordinates(slotCoords).translateBy new Point 3,3

    @moveToAndClick_InputEvents clickPosition, "left button", milliseconds, startTime

  clickOnSaveButtonFromTopInspector_InputEvents: (milliseconds = 1000, startTime = WorldWdgt.dateOfCurrentCycleStart.getTime()) ->
    inspectorNaked = @_findTopInspector()
    saveButton = inspectorNaked.saveButton
    @moveToAndClick_InputEvents saveButton, "left button", milliseconds, startTime

  bringcodeStringFromTopInspectorInView_InputEvents: (codeString, occurrenceNumber = 1, after = true) ->
    inspectorNaked = @_findTopInspector()

    slotCoords = inspectorNaked.textWidget.text.getNthPositionInStringBeforeOrAfter codeString, occurrenceNumber, after

    textScrollPane = inspectorNaked.topWdgtSuchThat (item) -> item.widgetClassString() == "TextAreaWdgt"
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
    # Function vs macro: a function executes fully within the CURRENT cycle, so it can push future events
    # "blindly" but cannot observe how the world looks after they run; a macro is a generator that yields
    # across cycles, so it CAN check world state between steps (open a menu, confirm an item exists, then
    # click it). Implication: a macro may call functions, but a function cannot call a macro. A macro must
    # call another macro or `yield` itself — one that does neither runs one-shot in a single cycle and
    # should just be a function. A well-formed macro drains the input queue itself before returning, so
    # its caller never needs an extra wait after calling it.

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

    # Patch-programming "connect to ➜": wire a CONTROLLER widget (a ColorPaletteWdgt, GrayPaletteWdgt,
    # SliderWdgt, StringWdgt, … — anything augmented with ControllerMixin) to drive a property of
    # another widget. Right-click the controller -> "connect to ➜" (openTargetSelector) opens a
    # "choose target:" menu of the widgets whose bounds INTERSECT the controller (so the controller must
    # OVERLAP the intended target), each labelled `target.toString().replace("Wdgt","") + " ➜"`
    # (Wdgt-stripped); pick it by class-name PREFIX. That opens a "choose target property:" menu of the
    # target's setters (e.g. "color"); pick the property. Afterwards, acting on the controller (clicking
    # a palette, dragging a slider) calls target[setter](value). Each menu is captured fresh from
    # getMostRecentlyOpenedMenu() right after it opens (every mouseUp clears world.freshlyCreatedPopUps).
    macroSubroutines.add Macro.fromString """
      setControllerTargetToWidgetProperty_InputEvents_Macro = (controllerWidget, targetClassNamePrefix, propertyLabel, controllerMenuFraction = [0.5, 0.5], controllerHierarchyPrefix) ->
        @moveToAndClickAtFractionOf_InputEvents controllerWidget, controllerMenuFraction, "right button"
        yield "waitNoInputsOngoing"
        # When the controller is INSIDE a container (its parent is not the world), right-clicking it opens the
        # ancestor HIERARCHY menu ("a Slider ➜", "a Panel ➜", …) rather than the controller's own menu —
        # so first navigate into the controller's own submenu by its class-name prefix. (A world-child
        # controller opens its menu directly, so this is skipped.)
        if controllerHierarchyPrefix?
          @moveToItemStartingWithOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), controllerHierarchyPrefix
          yield "waitNoInputsOngoing"
        @moveToItemOfTopMenuAndClick_InputEvents "connect ➜"
        yield "waitNoInputsOngoing"
        @moveToItemOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), "connect to ➜"
        yield "waitNoInputsOngoing"
        @moveToItemStartingWithOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), targetClassNamePrefix
        yield "waitNoInputsOngoing"
        @moveToItemOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), propertyLabel
        yield "waitNoInputsOngoing"
    """

    # The TWO-WAY gesture (connector plan §P2): bind this controller's value to another widget's, so
    # each drives the other. Shorter than the connect gesture above because a bind has NO property
    # step — both pins are forced to be the two widgets' principal ones — and the target menu lists
    # only widgets that can actually be bound. The controller whose menu is opened is the one whose
    # value wins at bind time.
    macroSubroutines.add Macro.fromString """
      bindControllerTo_InputEvents_Macro = (controllerWidget, targetClassNamePrefix, controllerMenuFraction = [0.5, 0.5], controllerHierarchyPrefix) ->
        @moveToAndClickAtFractionOf_InputEvents controllerWidget, controllerMenuFraction, "right button"
        yield "waitNoInputsOngoing"
        if controllerHierarchyPrefix?
          @moveToItemStartingWithOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), controllerHierarchyPrefix
          yield "waitNoInputsOngoing"
        @moveToItemOfTopMenuAndClick_InputEvents "connect ➜"
        yield "waitNoInputsOngoing"
        @moveToItemOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), "bind ⇄"
        yield "waitNoInputsOngoing"
        @moveToItemStartingWithOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), targetClassNamePrefix
        yield "waitNoInputsOngoing"
    """

    # The INVERSE gesture (connector plan §P4): cut one of a controller's connections and leave the rest
    # standing. A controller's own menu carries one row PER LIVE WIRE, labelled by what it drives —
    # `WireSpec.describeConnection()` plus an arrow, i.e. the Wdgt-stripped target then the PIN's label,
    # "a Panel . color ➜" — so name the wire by that prefix. The row opens that wire's own little menu
    # ("fires per event", "disconnect"); this clicks "disconnect".
    # ⚠ Pass the prefix WITHOUT the trailing arrow (prefix matching), which is also what makes this verb
    # blind to the arrow's DIRECTION: a two-way wire's row ends " ⇄" rather than " ➜" (§P2), and cutting
    # one ends the relationship in both directions.
    # ⚠ The pin LABEL is what appears, not the setter name: "a Panel . color", never "a Panel . setColor".
    macroSubroutines.add Macro.fromString """
      disconnectControllerWire_InputEvents_Macro = (controllerWidget, wireRowPrefix, controllerMenuFraction = [0.5, 0.5], controllerHierarchyPrefix) ->
        @moveToAndClickAtFractionOf_InputEvents controllerWidget, controllerMenuFraction, "right button"
        yield "waitNoInputsOngoing"
        if controllerHierarchyPrefix?
          @moveToItemStartingWithOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), controllerHierarchyPrefix
          yield "waitNoInputsOngoing"
        @moveToItemStartingWithOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), wireRowPrefix
        yield "waitNoInputsOngoing"
        @moveToItemOfMenuAndClick_InputEvents @getMostRecentlyOpenedMenu(), "disconnect"
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
        extWin = new FrameWdgt()
        extWin.setBounds (new Point 75, 90), new Point 290, 240
        world.add extWin
        intWin = new FrameWdgt()
        intWin.setBounds (new Point 600, 200), new Point 250, 160
        world.add intWin
        yield "waitNoInputsOngoing"
        return [extWin, intWin]
    """

    macroSubroutines.add Macro.fromString """
      dropInternalWindowIntoExternalWindow_InputEvents_Macro = (extWin, intWin) ->
        intWin.pickUp()
        @syntheticEventsMouseMove_InputEvents (@screenPointAtFractionOf extWin, [0.5, 0.55]), "no button", 700
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

    # Overflowing-viewport fixture, SHARED by the viewport drag-behaviour tests (default → the panel MOVES;
    # locked-to-desktop → the contents SCROLL; in a window → the WINDOW moves) so the setup lives in ONE place. Builds a
    # ViewportWdgt with a tall wrapping TextWdgt so it OVERFLOWS (a vertical scrollbar shows), adds it to the world at
    # topLeftPoint, and RETURNS the panel. Takes NO screenshots (only a test's own sources are scanned for reference names).
    macroSubroutines.add Macro.fromString """
      buildOverflowingViewportWithText_Macro = (topLeftPoint) ->
        # Build entirely through the PUBLIC widget API (macros must not use the private / low-level _-prefixed API):
        # attach first, so the public setExtent/setWidth/moveTo SELF-SETTLE and apply in place.
        panel = new ViewportWdgt
        world.add panel
        panel.setBounds topLeftPoint, new Point 270, 200
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
        # capture at the END of this cycle (right after _repaintDamagedRects) — the natural end of
        # a painted frame. The hash wait below cannot pass before the capture ran: the pump
        # re-checks it only next cycle, and the pending count increments synchronously
        # inside the delivered compareScreenshots.
        @captureAtEndOfCycle -> world.automator.player.compareScreenshots screenShotImageName
        yield "waitForScreenshotHash"
    """

    macroSubroutines

