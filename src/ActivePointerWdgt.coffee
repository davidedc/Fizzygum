# The mouse cursor. Note that it's not a child of the WorldWdgt, this widget
# is never added to any other widget. [TODO] Find out why and write explanation.
# Not to be confused with the HandleWdgt

class ActivePointerWdgt extends Widget

  # The kind of pointer the stroke in progress belongs to ('mouse' | 'pen' | 'touch'), taken from
  # every down and every move. It is per-STROKE, not a device setting: a hybrid machine mixes a
  # trackpad, a pen and a finger in one session and each stroke answers for itself.
  pointerType: undefined
  mouseButton: undefined
  # used for example to check that
  # mouseDown and mouseUp happen on the
  # same Widget (otherwise clicks happen for
  # example when resizing a button via the
  # handle)
  mouseDownWdgt: undefined
  mouseDownPosition: undefined
  wdgtToGrab: undefined
  grabOrigin: undefined
  # --- drag-embed dwell-to-arm state (docs/specs/drag-embed-interaction-spec.md §6) -------------
  # Live only while float-dragging a payload; all cleared by _endDragEmbedInteraction on release.
  dragEmbedCandidate: undefined              # innermost receptive widget under the cursor (undefined = none / world)
  dragEmbedReluctant: undefined              # innermost view-mode editing-amenity widget, when NO candidate
  dragEmbedDockBand: undefined               # {host, side} when the candidate is a host's EDGE BAND, not its body
  dragEmbedLingerOriginPoint: undefined      # pointer position where the current linger began
  dragEmbedLingerOriginEventTime: undefined  # EVENT.time (never wall-clock) at that origin — the arm clock
  dragEmbedLingerOriginWallTime: undefined   # wall time at that origin (ring animation only, never the decision)
  dragEmbedArmed: false                # window payload: has the dwell elapsed?
  _dragEmbedOutlinedWdgt: undefined          # which widget we currently declare into the highlight style channel
  # --- press-and-hold recognizer (the touch grammar, ruling I2) ----------------------------------
  # Per STROKE, not per device: every field here is re-established at the press and answers for
  # that one press. Plain scalars and booleans — no widget references — so a teardown owes them
  # nothing beyond the shared press clear (_forgetPressBookkeeping) that a cancel also reaches.
  pressOriginPoint: undefined                # pointer position where the press began
  pressOriginEventTime: undefined            # EVENT.time at that press — the hold's ONE clock
  _pressArmedForMouseSemantics: false        # do this stroke's drags mean what a mouse's would?
  _pressHoldFired: false                     # the hold opened its menu, so this stroke owes no click
  _pressHoldMenuStands: false                # that menu is still up, and a move dismisses it
  _pressLeftHoldRadius: false                # the press travelled: it is a plain drag for its whole life
  # THE FINGER LEFT THE GLASS: between touch strokes NO pointer rests anywhere, and while that is
  # true nothing is under one. A mouse or a pen never leaves — it stops — so this is false for
  # their whole life and every path they take is the path they always took.
  _pointerIsAbsent: false
  mouseOverList: undefined
  # One multi-click candidate each — widget + position + EVENT-TIME armed; see
  # MultiClickRecognizer. Replaces the six hand-mirrored double/triple fields. Instantiated
  # per-instance in the constructor (mutable state — must not be shared prototype objects).
  doubleClick: undefined
  tripleClick: undefined
  # The multi-click recognition window: two same-spot left clicks fold into a double-
  # / triple-click only if they land within this many ms of each other. Enforced by the
  # EVENT-TIME forget gate in processPointerUp (deterministic, load-immune).
  doubleClickWindowMs: 300
  nonFloatDraggedWdgt: undefined
  nonFloatDragPositionWithinWdgtAtStart: undefined
  # this is useful during nonFloatDrags to pass the widget
  # the delta position since the last invocation
  previousNonFloatDraggingPos: undefined

  constructor: ->
    @mouseOverList = new Set
    @doubleClick = new MultiClickRecognizer 2
    @tripleClick = new MultiClickRecognizer 3
    super()
    @minimumExtent = new Point 0,0
    @_commitBounds Rectangle.EMPTY

  # Forget every widget-referencing piece of gesture bookkeeping. The hand OUTLIVES a
  # world teardown, so anything here would otherwise keep DEAD references to widgets the
  # teardown just destroyed -- and the armed multi-click records could even RECOGNIZE
  # across worlds once the event clock rewinds. Called from the shared teardown core
  # (WorldWdgt._teardownWorldStructureNoSettle), which BOTH teardown callers reach; the
  # error-recovery _softResetWorld keeps its own narrower clears. Plain scalars
  # (mouseButton, positions) are left alone: they hold no references and every gesture
  # start re-establishes them.
  _forgetGestureBookkeepingNoSettle: ->
    @_forgetPressBookkeeping()
    @grabOrigin = undefined
    @dragEmbedCandidate = undefined
    @dragEmbedReluctant = undefined
    @_dragEmbedOutlinedWdgt = undefined
    @dragEmbedLingerOriginPoint = undefined
    @dragEmbedLingerOriginEventTime = undefined
    @dragEmbedLingerOriginWallTime = undefined
    @mouseOverList.clear()
    # a replacement world has been walked over by nobody, so the hand meets it as it meets a fresh
    # page: whatever the last stroke left is not a fact about this world
    @_pointerIsAbsent = false
    return

  # The widget-referencing bookkeeping of a PRESS: which widget the button went down on, what a
  # drag would pick up, what is being non-float-dragged, and the armed multi-click candidates.
  # Shared by the two occasions a press ends without a release — a world teardown (above) and a
  # cancelled stroke (processPointerCancel) — each of which then clears what only it owns.
  _forgetPressBookkeeping: ->
    @mouseDownWdgt = undefined
    @wdgtToGrab = undefined
    @nonFloatDraggedWdgt = undefined
    @doubleClick.forget()
    @tripleClick.forget()
    @_forgetPressAndHoldRecognition()
    return

  # Forget the press-and-hold recognizer's whole per-stroke state. An ordinary release does NOT
  # come through here: the up still has to know whether the hold consumed the stroke, and the next
  # press re-establishes every field anyway.
  _forgetPressAndHoldRecognition: ->
    @pressOriginPoint = undefined
    @pressOriginEventTime = undefined
    @_pressArmedForMouseSemantics = false
    @_pressHoldFired = false
    @_pressHoldMenuStands = false
    @_pressLeftHoldRadius = false
    return

  # Capability query (with CanvasWdgt; replaces `whereTo instanceof ActivePointerWdgt or ... CanvasWdgt`
  # in PenWdgt._reactToBeingAdded): "can a pen draw onto me?" -- the hand counts because a pen mid-drag
  # lives on it. Dispatched via ?() (nothing on Widget). (type-test-elimination campaign)
  acceptsPenDrawing: ->
    true

  clippedThroughBounds: ->
    # always recompute -- the empty-hand carve-out means the version key can be stale for the hand; the compute is trivial
    return @boundingBox()

  clipThrough: ->
    # always recompute -- the empty-hand carve-out means the version key can be stale for the hand; the compute is trivial
    return @boundingBox()

  # SLOW-oracle mirrors of the two overrides above (Tier J2): the hand is painted on top of everything,
  # unclipped, so its clipped / clip-through bounds ARE its (possibly inside-out / empty) boundingBox --
  # exactly what the cached overrides return. The generic clip-through-world SLOW computation would
  # intersect that boundingBox with the world and normalize an inside-out hand boundingBox to EMPTY, so it
  # would diverge from the cached override; mirror the override explicitly instead.
  SLOWclippedThroughBounds: ->
    return @boundingBox()

  SLOWclipThrough: ->
    return @boundingBox()

  # The hand does not participate in the version-keyed caches: the empty-hand carve-out
  # (__breakMoveResizeCaches) skips the geometryVersion bump for a bare pointer move, so
  # a version-stamped cache on the hand itself would serve STALE bounds mid-hover.
  # Recompute fresh, like clippedThroughBounds/clipThrough above. With children (mid
  # float-drag) every move bumps the version anyway, so nothing is lost -- the children's
  # own caches below stay exact.
  fullBounds: ->
    result = @boundingBox()
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and !child.isInCollapsedSubtree()
        result = result.merge child.fullBounds()
    result

  fullClippedBounds: ->
    result = @clippedThroughBounds()
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and !child.isInCollapsedSubtree()
        result = result.merge child.fullClippedBounds()
    result

  # ActivePointerWdgt navigation:
  topWdgtUnderPointer: ->
    result = world.topWdgtSuchThat (m) =>
      # Affine transforms (§4.6): test each candidate against the pointer mapped INTO
      # that candidate's plane. For a widget inside a non-identity island this is the
      # inverse-mapped (virtual) point — where the candidate's virtual bounds/pixels
      # live; the exact rotated-quad / per-pixel test then falls out for free. For any
      # widget NOT inside an island (⇒ always, when dormant) mappedPointerPosition IS
      # @position(), so this is byte-identical.
      mappedPointerPosition = m.screenPointToMyPlane @position()
      m.isPointerTargetAt mappedPointerPosition
    if result?
      return result
    else
      return world

  openContextMenuAtPointer: (wdgtTheMenuIsAbout) ->
    # note that the widgets that the menu
    # belongs to might not be under the mouse.
    # It usually is, but in cases
    # where a system test is playing against
    # a world setup that has varied since the
    # recording, this could be the case.

    # these three are checks and actions that normally
    # would happen on MouseDown event, but we
    # removed that event as we collapsed the down and up
    # into this combined higher-level event,
    # but we still need to make these checks and actions
    @destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem wdgtTheMenuIsAbout
    @stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere wdgtTheMenuIsAbout

    if Automator? and
     Automator.state == Automator.PLAYING
      Automator.fade 'rightMouseButtonIndicator', 0, 1, 10, new Date().getTime()
      setTimeout \
        =>
          Automator.fade 'rightMouseButtonIndicator', 1, 0, 500, new Date().getTime()
        , 100
    
    contextMenu = wdgtTheMenuIsAbout.buildContextMenu()
    while !contextMenu and wdgtTheMenuIsAbout.parent
      wdgtTheMenuIsAbout = wdgtTheMenuIsAbout.parent
      contextMenu = wdgtTheMenuIsAbout.buildContextMenu()

    if contextMenu
      contextMenu.popUpAtHand()

  # ActivePointerWdgt floatDragging and dropping:
  #
  # floatDrag 'n' drop events, method(arg) -> receiver:
  #
  #   _beforeBeingGrabbed() -> grabTarget
  #   _reactToBeingGrabbed(oldParent) -> grabbedWdgt
  #   _reactToChildGrabbed(grabbedWdgt) -> oldParent
  #   wantsDropOfChild(wdgtToDrop) ->  newParent
  #   _beforeChildDropped(wdgtToDrop) -> newParent
  #   _reactToBeingDropped(whereIn) -> droppedWdgt
  #   _reactToChildDropped(droppedWdgt, activePointerWdgt) -> newParent
  #
  dropTargetFor: (aWdgt) ->
    # §6 4D-2b: a container decides acceptance by the payload's real class, not the transient sugar wrapper's
    # (a tilted window must still resolve to a window-accepting container). Climb by the payload-policy proxy;
    # the returned target is used by the caller for GEOMETRY on the figure itself (off any sugar figure the
    # proxy is the widget unchanged ⇒ byte-identical dormant).
    payloadPolicy = aWdgt._dropPolicyProxy()
    target = @topWdgtUnderPointer()
    until target.wantsDropOfChild payloadPolicy
      target = target.parent
    target

  # === drag-embed dwell-to-arm state machine (docs/specs/drag-embed-interaction-spec.md §6) =======
  # Runs once per pointer dispatch while float-dragging a payload (from dispatchEventsFollowingMouseMove,
  # which fires per move AND per cycle on the hover re-sync). The ARM DECISION is pure elapsed EVENT-time
  # (never wall-clock — the doubleClickWindowMs template, NOT the autoscroll anomaly). It only mutates
  # declarative state (candidate / linger origin / armed) and declares ephemeral visuals; it does NOT
  # touch drop() — Phase 2 PREVIEWS the interaction, Phase 3 makes the release obey it.

  # Resolve the candidates on the parent-climb from the cursor hit (spec §5): the innermost widget that
  # wantsDropOfChild wins (world is never a candidate); else the innermost view-mode editing-amenity
  # widget is the reluctant cue. Same climb dropTargetFor uses, so preview and outcome cannot disagree.
  # THE EDGE BAND under the pointer, if a host offers one there for THIS payload — the dock offer,
  # consulted BEFORE the ordinary drop climb below. Only a FRAME is ever offered a band (a band
  # holds chrome, not loose content), and a host never offers one to something it lives inside.
  # The point is handed to each host in ITS OWN plane, so a host inside a rotated island answers
  # about the band the user is actually pointing at.
  _dockBandUnderPointerFor: (payload) ->
    payloadPolicy = payload._dropPolicyProxy()
    return undefined unless payloadPolicy.isFrame?()
    wdgt = @topWdgtUnderPointer()
    while wdgt? and wdgt isnt world
      if wdgt.dockSideAt? and not payloadPolicy.isAncestorOf wdgt
        side = wdgt.dockSideAt wdgt.screenPointToMyPlane @position()
        return {host: wdgt, side: side} if side?
      wdgt = wdgt.parent
    undefined

  resolveDragEmbedCandidates: (payload) ->
    # §6 4D-2b: match candidates by the payload's real class (see dropTargetFor) so the dwell preview and the
    # drop outcome agree for a tilted window too.
    payloadPolicy = payload._dropPolicyProxy()
    # the DOCK OFFER wins where it applies: a band is a strip of a host's own body that the host
    # has declared means "place me here", so a frame released over one docks instead of landing in
    # the content underneath. Everything else — every plain payload, and a frame anywhere but a
    # band — resolves exactly as it always has.
    band = @_dockBandUnderPointerFor payload
    return {candidate: band.host, reluctant: undefined, dockBand: band} if band?
    wdgt = @topWdgtUnderPointer()
    reluctant = undefined
    while wdgt? and wdgt isnt world
      if wdgt.wantsDropOfChild payloadPolicy
        return {candidate: wdgt, reluctant: undefined}
      if !reluctant? and wdgt.providesAmenitiesForEditing and not wdgt.dragsDropsAndEditingEnabled
        reluctant = wdgt
      wdgt = wdgt.parent
    {candidate: undefined, reluctant: reluctant}

  _reAnchorDragEmbedLinger: (eventTime) ->
    @dragEmbedLingerOriginPoint = @position()
    @dragEmbedLingerOriginEventTime = eventTime
    @dragEmbedLingerOriginWallTime = WorldWdgt.dateOfCurrentCycleStart

  updateDragEmbedStateMachine: ->
    payload = @children[0]
    return unless payload?
    {candidate, reluctant, dockBand} = @resolveDragEmbedCandidates payload
    eventTime = WorldWdgt.timeOfEventBeingProcessed

    # candidate change => reset the linger + disarm (spec §5: per-candidate dwell, full reset).
    # Moving between two BANDS of the same host is a candidate change too — they are different
    # offers, so each earns its own dwell.
    if candidate isnt @dragEmbedCandidate or dockBand?.side isnt @dragEmbedDockBand?.side
      @dragEmbedCandidate = candidate
      @_reAnchorDragEmbedLinger eventTime
      @dragEmbedArmed = false
    @dragEmbedDockBand = dockBand
    @dragEmbedReluctant = if candidate? then undefined else reluctant

    if candidate? and payload._dropPolicyProxy().requiresDeliberateEmbedding()   # §6 4D-2b: a tilted WINDOW still needs the dwell
      unless @dragEmbedArmed
        # a >radius pointer move RE-ANCHORS the origin — a slow transit never arms (spec §6). After
        # arming this guard is skipped, so the user may move to aim within the SAME candidate.
        if @dragEmbedLingerOriginPoint? and
         (@dragEmbedLingerOriginPoint.distanceTo(@position()) > WorldWdgt.preferencesAndSettings.grabDragThreshold)
          @_reAnchorDragEmbedLinger eventTime
        # ARM = elapsed EVENT-time >= dwellToArmMs, evaluated at THIS event (incl. the release)
        if eventTime? and @dragEmbedLingerOriginEventTime? and
         (eventTime - @dragEmbedLingerOriginEventTime >= WorldWdgt.preferencesAndSettings.dwellToArmMs)
          @dragEmbedArmed = true
    else
      @dragEmbedArmed = false          # plain payloads have no armed state; free/reluctant never arm

    @_declareDragEmbedEphemerals payload

  # Turn the state into declarative ephemeral requests (the reconcilers turn these into pixels
  # pre-paint). Candidate/reluctant OUTLINE rides the Phase-1 highlight style channel; the ring / label /
  # lock badge ride WorldWdgt.addDragAffordanceWidgets. Non-interactable visuals only — the §8 pill is Phase 4.
  _declareDragEmbedEphemerals: (payload) ->
    isFrame = payload._dropPolicyProxy().requiresDeliberateEmbedding()   # §6 4D-2b: window affordances for a tilted window too

    # 0. the DOCK BAND, outlined WHOLE: over a band the offer is the strip, not the host, so the
    # host's own outline stands down and the band's rectangle takes its place (declared in the
    # host's plane; the reconciler maps it).
    if @dragEmbedDockBand?
      world.dragEmbedDockBandDeclared =
        host: @dragEmbedDockBand.host
        box: @dragEmbedDockBand.host.dockBandBoxAt @dragEmbedDockBand.side
    else
      world.dragEmbedDockBandDeclared = undefined

    # 1. candidate (accent) or reluctant (neutral) outline via the highlight style channel
    outlineTarget = if @dragEmbedDockBand? then undefined else (@dragEmbedCandidate ? @dragEmbedReluctant)
    if outlineTarget isnt @_dragEmbedOutlinedWdgt
      world.widgetsToBeHighlighted.delete @_dragEmbedOutlinedWdgt if @_dragEmbedOutlinedWdgt?
      @_dragEmbedOutlinedWdgt = outlineTarget
    if outlineTarget?
      style = if @dragEmbedCandidate? then HighlighterWdgt.candidateOutlineStyle() else HighlighterWdgt.reluctantOutlineStyle()
      world.widgetsToBeHighlighted.set outlineTarget, style

    # Affordance anchor: just BELOW the carried payload's bottom edge. The payload hangs from / around
    # the cursor, and the hand paints OVER the world's ephemeral overlays, so a cursor-anchored ring/label
    # would be hidden behind it — anchor them below the payload so they stay visible and follow the drag.
    affordanceTop = payload.bottom() + 6

    # 2. charging ring — window payload, over a candidate, not yet armed
    if isFrame and @dragEmbedCandidate? and not @dragEmbedArmed
      world.dragEmbedChargeRingDeclared =
        centerPoint: new Point(payload.left() + 12, affordanceTop + 11)
        lingerOriginEventTime: @dragEmbedLingerOriginEventTime
        lingerOriginWallTime: @dragEmbedLingerOriginWallTime
    else
      world.dragEmbedChargeRingDeclared = undefined

    # 3. armed label — window payload, armed
    if isFrame and @dragEmbedArmed and @dragEmbedCandidate?
      candidateTitle = @_dragEmbedCandidateTitle()   # hoisted out of the string so the ref is visible
      bandSide = @dragEmbedDockBand?.side            # ditto
      world.dragEmbedLabelDeclared =
        point: new Point(payload.left(), affordanceTop)
        text: if bandSide? then "Drop to dock at the #{bandSide} of '#{candidateTitle}'" else "Drop to insert into '#{candidateTitle}'"
    else
      world.dragEmbedLabelDeclared = undefined

    # 4. lock badge — reluctant (view-mode) target, no candidate
    if @dragEmbedReluctant?
      world.dragEmbedLockBadgeDeclared = target: @dragEmbedReluctant
    else
      world.dragEmbedLockBadgeDeclared = undefined

  _dragEmbedCandidateTitle: ->
    name = @dragEmbedCandidate?.colloquialName?() ? "here"
    if name.length > 24 then name.substr(0, 23) + "…" else name

  # Clear ALL drag-embed state + undeclare every ephemeral (on release, or if a drag ends without a
  # drop). The reconcilers destroy the overlays on the next pre-paint pass.
  _endDragEmbedInteraction: ->
    world.widgetsToBeHighlighted.delete @_dragEmbedOutlinedWdgt if @_dragEmbedOutlinedWdgt?
    @_dragEmbedOutlinedWdgt = undefined
    world.dragEmbedChargeRingDeclared = undefined
    world.dragEmbedLabelDeclared = undefined
    world.dragEmbedLockBadgeDeclared = undefined
    world.dragEmbedDockBandDeclared = undefined
    @dragEmbedDockBand = undefined
    @dragEmbedCandidate = undefined
    @dragEmbedReluctant = undefined
    @dragEmbedLingerOriginPoint = undefined
    @dragEmbedLingerOriginEventTime = undefined
    @dragEmbedLingerOriginWallTime = undefined
    @dragEmbedArmed = false

  grab: (aWdgt, displacementDueToGrabDragThreshold,  switcherooHappened) ->
    return undefined  if aWdgt == world
    oldParent = aWdgt.parent
    if !@isThisPointerFloatDraggingSomething()

      world.stopEditing()

      # this paragraph deals with how to resize/reposition the widget
      # that we are grabbing in respect to the hand
      if switcherooHappened
        # in this case the widget being grabbed is created on the fly
        # so just like the next case it's OK to center it under the pointer
        aWdgt.moveTo @position().subtract aWdgt.extent().floorDivideBy 2
        aWdgt._moveWithin world # raw flush+clamp here; a deferred moveWithin now exists, but switching this real-time grab to it is a Path-A determinism call
      else if aWdgt.extentToGetWhenDraggedFromGlassBox? and (oldParent instanceof GlassBoxBottomWdgt)
        # in this case the widget is "inflating". So, all
        # visual references that the user might have around the
        # position of the grab go out of the window: just center
        # the widget under the pointer and fit it within the
        # desktop bounds since we are at it (useful in case the
        # widget is inflating near the screen edges)
        aWdgt.setExtent aWdgt.extentToGetWhenDraggedFromGlassBox
        aWdgt.moveTo @position().subtract aWdgt.extent().floorDivideBy 2
        aWdgt._moveWithin world
      else if displacementDueToGrabDragThreshold?
        # keep visual consistency: move the widget to where the grab started (we grab only after a
        # significant move past the threshold). Don't fit within the world -- a widget picked up
        # partially off-screen should stay there, not jump into view.
        aWdgt._applyMoveTo aWdgt.position().add displacementDueToGrabDragThreshold

      @grabOrigin = aWdgt.situation()
      # I OWN the settle around this callback: _beforeBeingGrabbed releases the widget from its
      # host's layout (it unlocks from panels and drops its layout spec), which marks the widget
      # AND the holder chain it is leaving. A notification callback declares no settle of its own
      # (layering rule [J]), so without this the marks are an undeclared end-of-cycle push — the
      # dispatcher is the one that knows the gesture is one discrete mutation.
      @_settleLayoutsAfter => aWdgt._beforeBeingGrabbed?()

      # double-settle-sanctioned: the grab gesture hand-rolls FOUR deliberate sequential flushes —
      # the release above, then @add self-settling the re-home into the hand, then the grabbed
      # widget's own reaction below, then the trailing @_settleLayoutsAfter flushing the old parent's
      # _reactToChildGrabbed re-fit once (the drop's symmetric twin — see the comment there).
      @add aWdgt
      # I OWN this callback's settle too, for the same reason as the release above: a TRANSIENT frame
      # becomes furniture at the grab (program ruling C8), which re-derives its skin and marks its
      # title strip. A notification callback declares no settle of its own (layering rule [J]), so
      # the dispatcher declares it — the mark is part of this one discrete mutation, not an
      # undeclared end-of-cycle push.
      @_settleLayoutsAfter => aWdgt._reactToBeingGrabbed? oldParent
      # The shadow must be added after @add -- it needs the widget's painted image, which @add may
      # produce for the first time. This grab shadow uses its own "floaty" look (offset/blur/color),
      # distinct from a widget's own per-class shadow (e.g. Menus use a different one).

      aWdgt.addShadow new Point(6, 6), 0.1
      
      @_fullChanged()
      # Notify the old parent so it can re-fit itself (e.g. a ViewportWdgt re-snugs its contents +
      # scrollbars when you take a widget out of it). A grab is one discrete re-parent gesture, so settle it
      # HERE -- consistent on return, not on the next doOneCycle. This is the SYMMETRIC twin of the drop
      # (see ActivePointerWdgt.drop): @add above already self-settled the re-home (its _addNoSettle captured
      # the OLD container's _reactToChildRemoved re-fit inside add's settle), and this SINGLE settle flushes the
      # _reactToChildGrabbed re-fit once. Every _reactToChildGrabbed override re-fits through NON-settling paths -- Panel
      # Wdgt / ViewportWdgt via _reFitContainer (a raw invalidate, no public setter), FridgeWdgt via
      # compileTiles -> FizzytilesCodeWdgt.showCompiledCode -> _setTextNoSettle (core) -- so nothing re-enters
      # the flush guard mid-pass; the single tier flushes ONCE and THROWS if a future override sneaks in a
      # public setter (the wanted cores-call-cores discipline).
      @_settleLayoutsAfter => oldParent?._reactToChildGrabbed? aWdgt

  isThisPointerDraggingSomething: ->
    @isThisPointerFloatDraggingSomething() or @isThisPointerNonFloatDraggingSomething()

  isThisPointerFloatDraggingSomething: ->
    if @children.length > 0 then true else false

  # PUBLIC notification — a widget I am float-dragging changed. I carry the widget plus its
  # drop-shadow as one composite, so the whole carried assembly must repaint together. I
  # invalidate MYSELF here, in the method the carried widget's _changed() invokes on me
  # (widget-citizenship point 2) — widgets never reach into my _fullChanged().
  noteCarriedWidgetChanged: ->
    @_fullChanged()

  isThisPointerNonFloatDraggingSomething: ->
    return @nonFloatDraggedWdgt?


  # `forcedTarget`, when given, IS the destination and the release's own verdict is not consulted
  # at all — not the dwell, not the dock band, not the sticky re-embed. Its one caller is
  # processPointerCancel: a confiscated stroke states no intent, so the payload lands on the world
  # where it visibly is. An ordinary release passes nothing and the dwell state machine decides.
  drop: (forcedTarget) ->
    if @isThisPointerFloatDraggingSomething()

      wdgtToDrop = @children[0]

      dockSide = undefined

      if forcedTarget?
        target = forcedTarget
      else
        # THE RULE FLIP (spec §6/§7). The release is itself an evaluation point for the dwell (§6: the
        # arm decision is evaluated at EVERY event over the candidate, INCLUDING the release), so re-run
        # the state machine once more here: a frozen hold that has already reached DWELL_ARM_MS of elapsed
        # event-time then ARMS exactly on release, with no final micro-move needed — the S2-validated
        # still-hold case. Capture the verdict, THEN tear the affordances down (teardown clears the state
        # we just read).
        @updateDragEmbedStateMachine()
        wasArmed = @dragEmbedArmed
        overReluctantOnly = @dragEmbedReluctant?
        # the band the release resolved to, captured beside the arm verdict for the same reason: the
        # teardown below clears the state both are read from
        releasedOverBand = @dragEmbedDockBand
        @_endDragEmbedInteraction()

        # §6 4D-2b: the window-vs-plain drop decision keys off the payload's real class -- a tilted window rides
        # the hand as a sugar TransformFrameWdgt, so look THROUGH it (dropPolicy) for requiresDeliberateEmbedding /
        # wantsToBeDropped. Geometry + add still use wdgtToDrop (the figure); the @grabOrigin.origin sticky check
        # below compares the figure's pre-grab parent, which composes for a sole-content window figure (§7.5 brief).
        dropPolicy = wdgtToDrop._dropPolicyProxy()
        if overReluctantOnly
          # LOCKED_CUE (spec §7): the destination is in view mode — it never accepts a mid-drag drop, so the
          # payload lands on the WORLD at the release point (a plain move-over, NO offset). Applies to BOTH
          # window and plain payloads.
          target = world
        else if dropPolicy.requiresDeliberateEmbedding()
          # WINDOW payload over an eager/willing candidate (or nothing): the internal/external gate is GONE
          # — the dwell alone decides (spec §7). Armed → embed at the resolved candidate (the SAME climb
          # the preview used, so preview and outcome cannot disagree); not armed → plain move-over, lands
          # on the world at the release point (this IS the common gesture — no bounce, no scold).
          if wasArmed and releasedOverBand?
            # DOCK: the armed release was over an edge band, so the frame takes that slot. The side
            # is the DROP's, never the payload's own default — you docked it there.
            target = releasedOverBand.host
            dockSide = releasedOverBand.side
          else if wasArmed
            target = @dropTargetFor wdgtToDrop
          else
            # STICKY RE-EMBED (spec §7, Phase 3.5): an unarmed window normally lands on the world, but
            # merely REPOSITIONING a window within its OWN container must not require a dwell. If the
            # release resolves (the SAME climb dropTargetFor uses) to the very container the window was
            # grabbed from, keep it nested there — no dwell, no offset. Embedding into a DIFFERENT
            # container still needs arming; a release over the world / a non-container still lands on the
            # world. @grabOrigin.origin is the PRE-GRAB parent (situation() recorded it at grab time,
            # before @add reparented the payload to the hand — so it is NOT wdgtToDrop.parent, which is
            # the hand while float-dragging).
            stickyTarget = @dropTargetFor wdgtToDrop
            if stickyTarget isnt world and stickyTarget is @grabOrigin?.origin
              target = stickyTarget
            else
              target = world
        else
          # Plain payload, not over a view-mode-only target: unchanged accept behavior. Base
          # wantsToBeDropped is true (instant embed over an eager/willing target via the climb);
          # BinOpenerWdgt keeps its override that forces itself onto the world. (dropPolicy = the payload's
          # real class through any sugar wrapper, §6 4D-2b.)
          if not dropPolicy.wantsToBeDropped()
            target = world
          else
            target = @dropTargetFor wdgtToDrop

      @_fullChanged()

      # Affine transforms 4D-2b (§6): a dropped SUGAR FIGURE is re-spec'd RELATIVE to the destination plane, so
      # a rotated/scaled figure dropped INTO a rotated container composites to its original absolute look
      # instead of double-applying the plane transform on top of its own spec. Runs AFTER @_fullChanged (which
      # damages the hand's CURRENT footprint) but BEFORE the 4D-1 position map / target.add / _beforeChildDropped
      # so all of them see the re-spec'd figure; when the relative similitude is identity the figure becomes an
      # identity sugar island that _unwrapIfIdentitySugarNoSettle then dissolves AFTER target.add (below). Off
      # any sugar figure, or into an identity plane (target == world, or a plain container), returns wdgtToDrop
      # unchanged ⇒ byte-identical dormant.
      # DECLARED deferred settle (claimsSpace arc S2): the re-spec's _set*NoSettle cores fire the
      # island's claim reflow (_invalidateLayout) now that sugar figures default to 'footprint' —
      # an off-settle push whose settle target.add below carries, exactly as this seam's contract
      # always stated ("the drop's target.add carries the settle"). The declaration window makes
      # that contract explicit to the end-of-cycle capstone audit instead of implicit.
      wdgtToDrop = wdgtToDrop._deferredSettleDeclare => wdgtToDrop._reExpressFigureForPlaneOfNoSettle target

      # a DOCK is not a content drop, so the content pre-hook (which clears the target's current
      # payload to make room) does not apply: the band takes a slot the target keeps beside it.
      target._beforeChildDropped? wdgtToDrop unless dockSide?

      # Affine transforms 4D-1 (§6): DROP-IN into a widget whose plane is MAPPED — inside a
      # non-identity island, or (once the paint-time-scroll model is live) inside a scrolled pane.
      # The payload arrives in SCREEN space (it was float-dragged on the hand, a world-level widget),
      # but once it becomes target's child it renders THROUGH target's plane mapping — so its
      # bounds must be re-expressed in that plane or the mapping double-applies and the
      # payload jumps off the release point (lands rotated/scaled/offset away from where it was dropped).
      # Preserve the on-screen CENTRE (drag continuity): map it into target's plane and re-home the
      # payload's UNCHANGED-size bounds there, so it appears at its native virtual size, correctly
      # rotated/scaled, centred where it was released. (Centre-preserving, NOT a corner-bbox
      # inverseMapRect: a rotated rect's screen-corner bounding box would inflate + mis-centre — the
      # same reason 4A-2 point-maps instead of adding an inverseMapVector; extent is deliberately left
      # native, the payload simply becomes content of the transformed thing.) screenPointToMyPlane
      # composes ALL mapping ancestors (N-deep) and returns the point UNCHANGED off any mapped
      # plane, so the whole block is a no-op when dormant (byte-identical). The GATE stays (unlike
      # the always-mapped positionInPlane below) because the block's _applyMoveTo is a real
      # mutation the common unmapped drop must not pay. NoSettle mutator — the target.add below
      # carries the single settle.
      if target._isInsideMappedPlane()
        # §7.5 Bug-D interplay: an undefined anchor makes center() the rotation fixed point, so it IS the on-screen
        # visual centre — but a figure picked up after a resize can carry a PINNED anchor (anchor-stability),
        # and then its bounds center() is spun about the pinned anchor and is NOT the visual centre. Map the
        # bounds centre through the payload's OWN spec to get the true visual centre before mapping it into
        # target's plane (an undefined/centre anchor makes mapPoint the identity on the centre ⇒ unchanged for fresh
        # pick-out islands; a plain-widget payload has no transformSpec ⇒ bare center()).
        payloadVisualCentre = if wdgtToDrop.transformSpec? then wdgtToDrop.transformSpec.mapPoint(wdgtToDrop.center(), wdgtToDrop.bounds) else wdgtToDrop.center()
        virtualCentre = target.screenPointToMyPlane payloadVisualCentre
        wdgtToDrop._applyMoveTo virtualCentre.subtract wdgtToDrop.extent().floorDivideBy 2

      # Affine transforms §7.13: positionInPlane is consumed by the stack/menu panels
      # (VerticalStackPanelWdgt / ToolPanelWdgt) to derive a
      # child-INSERT index by comparing against their children's PLANE-LOCAL spans — for a target
      # inside a non-identity island or a scrolled pane the raw screen point picks the wrong slot
      # (a 180°-tilted stack inverts the visual order, so a drop on the first child inserted after
      # the last). ALWAYS mapped, no gate: screenPointToMyPlane is the identity (same object) off
      # any mapped plane, so the dormant path still passes @position() through, byte-identical.
      # This one call addresses every container in the add family: a receiver that does not read
      # positionInPlane simply ignores it, which is what the options tail buys over the six
      # positional slots (four of them holes) this used to need.
      dropPositionInTargetPlane = target.screenPointToMyPlane @position()
      # dockSide (undefined on every ordinary drop) routes the add into the target's EDGE SLOT
      # instead of its content slot — one structural entry either way.
      target.add wdgtToDrop, beingDropped: true, positionInPlane: dropPositionInTargetPlane, dockSide: dockSide
      # Affine transforms 4D-2b (§6): the UNWRAP half of the re-expression. _reExpressFigureForPlaneOfNoSettle
      # above re-spec'd a dropped sugar figure to its RELATIVE similitude; when that was identity the figure is
      # now a _materializedBySugar island at identity NESTED in target, so the 4C auto-unwrap dissolves it in
      # place (content becomes target's own child at the figure's slot). This runs AFTER target.add so the
      # figure is placed by the SAME proven path a non-identity re-expressed figure uses (no bespoke re-home).
      # _unwrapIfIdentitySugar SELF-SETTLES (its own thin wrap): the dematerialize's NoSettle re-home runs
      # after target.add's settle has closed, so a bare NoSettle call here would be a careless end-of-cycle
      # push (capstone gate). Gated on _materializedBySugar so a plain-widget drop -- the common path --
      # neither calls in nor pays the settle; a non-identity sugar figure (a cross-plane drop) returns
      # unchanged (the wrapper survives).
      if wdgtToDrop._materializedBySugar
        wdgtToDrop = wdgtToDrop._unwrapIfIdentitySugar()
      # cross-invalidation-sanctioned: drop dispatcher — the hand invalidates the widget
      # being dropped (structural-move orchestration, like _addNoSettle's)
      wdgtToDrop._fullChanged()

      # when you click the buttons, sometimes you end up
      # clicking between the buttons, and so the "proper"
      # widget "loses focus" so to speak. So avoiding that here.
      # (By ANCESTRY, §5.D: a drop into an excluded subtree must not steal
      # focus either -- same rule as the click site.)
      if !(@_excludedFromEditorFocusTrackingByAncestry wdgtToDrop)
        world.editorFocusWdgt = wdgtToDrop

      @children = []
      @_applyExtent new Point

      # Notify the recipient (it may initialise the dropped widget's layout spec) and then the dropped
      # widget (it may tweak its OWN spec -- e.g. _constrainToRatio when dropped into a ratio container).
      # Both run AFTER add()'s self-settle ON PURPOSE -- _reactToBeingDropped reads the dropped widget's SETTLED
      # geometry (_rememberFractionalSituationInHoldingPanel, _constrainToRatio's @width()/@height()), so we
      # must NOT absorb add's settle. The recipient re-fit (_reactToChildDropped) + the post-_reactToBeingDropped spec
      # change used to DEFER to end-of-cycle. A drop is one discrete re-parent gesture, so settle them HERE:
      # consistent on return, not on the next doOneCycle. SINGLE settle (_settleLayoutsAfter): every
      # _reactToChildDropped / _reactToBeingDropped override re-homes / rebuilds / re-fits through the NON-settling cores
      # (FrameWdgt._buildAndConnectChildrenNoSettle, _fullDestroyNoSettle, _addNoSettle / _addInPseudoRandom
      # PositionNoSettle, _createReferenceAndCloseNoSettle, and immediate
      # mutators), so nothing re-enters the flush guard mid-pass; the single tier flushes ONCE at the end and
      # THROWS if a future override sneaks in a public setter (the wanted cores-call-cores discipline -- the
      # batch tier used to silently absorb that).
      @_settleLayoutsAfter =>
        target._reactToChildDropped? wdgtToDrop, @
        wdgtToDrop._reactToBeingDropped? target

  
  # ActivePointerWdgt event dispatching:
  #
  #    the entry points — processPointerDown, processPointerMove, processPointerUp,
  #    processPointerCancel and processWheel — each take ONE immutable input event and turn it
  #    into the widget-facing dispatches below:
  #
  #   mouseDownLeft
  #   mouseDownRight
  #   mouseClickLeft
  #   mouseClickRight
  #   mouseDoubleClick
  #   mouseTripleClick
  #   mouseEnter
  #   mouseLeave
  #   mouseEnterfloatDragging
  #   mouseLeavefloatDragging
  #   mouseMove
  #   wheel
  #
  # Note that some handlers don't want the event but the
  # interesting parameters of the event. This is because
  # the testing harness only stores the interesting parameters
  # rather than a multifaceted and sometimes browser-specific
  # event object.

  destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem: (actionedWdgt) ->
    if world.temporaryHandlesAndLayoutAdjusters.size > 0
      unless world.temporaryHandlesAndLayoutAdjusters.has actionedWdgt
        world.temporaryHandlesAndLayoutAdjusters.forEach (eachTemporaryHandlesAndLayoutAdjusters) =>
          eachTemporaryHandlesAndLayoutAdjusters.fullDestroy()
        world.temporaryHandlesAndLayoutAdjusters.clear()

  stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere: (actionedWdgt) ->
    if world.caret?

      # editor CHROME keeps the caret alive (§5.D D2a): interacting with the
      # editing apparatus (a text button, a font-menu item, a toolbar, the
      # Console's run-selection — whose action READS the current selection) is
      # not leaving the edit. ONE ancestry-walked capability covers them all,
      # including a click that lands on a button's LABEL/icon face (the former
      # self + hand-rolled parent-of check the field needed).
      if @_excludedFromEditorFocusTrackingByAncestry actionedWdgt
        return

      # There is a caret on the screen: depending on what the user clicked, we may need to close the
      # ongoing edit (delete the caret, un-select). Don't interrupt editing if the click is inside the
      # most-recently-created popup/menu belonging to the edited text (e.g. doSelection reads the
      # current selection).
      if actionedWdgt isnt world.caret.target
        # user clicked on something other than what the
        # caret is attached to: ending an edit by acting elsewhere ACCEPTS it (caret.accept =
        # stopEditing + an "accept" escalation from the target). For an ordinary text field
        # this is byte-identical to the old bare stopEditing (its text is already live and
        # nothing on its chain implements accept); for an editor whose accept COMMITS — the
        # spreadsheet cell editor — this is what makes click-away-commits reach outside the
        # sheet too.
        mostRecentlyCreatedPopUp = world.mostRecentlyCreatedPopUp()
        if mostRecentlyCreatedPopUp?
          unless mostRecentlyCreatedPopUp.isAncestorOf actionedWdgt
            # only dismiss editing if the actionedWdgt the user
            # clicked on is not part of a menu.
            world.caret.accept()
        # there is no menu at all, in which case
        # we know there was an editing operation going
        # on that we need to stop
        else
          world.caret.accept()


  # Affine transforms (§4.6, Phase 4A): the pointer position expressed in the RECEIVER
  # widget's own plane, for handlers that consume it as in-widget geometry (caret slot via
  # StringWdgt.slotAt, position-dependent clicks). `screenPointToMyPlane` walks w's parent
  # chain and inverse-maps through each non-identity island; for ANY widget not inside a
  # non-identity island (⇒ always, when the feature is dormant) it returns @position()
  # UNCHANGED (same object), so click dispatch is byte-identical. Only the position PASSED to
  # a handler is mapped — the double/triple-click proximity recognition and @mouseDownPosition
  # stay in SCREEN space (they compare successive @position()s and must share one plane). NB
  # a handler that RE-EMITS the received position as SCREEN coords (open-a-menu-at-point) would
  # misplace for island-inner content; none do in the current suite (menus open at the hand) —
  # audit as such a case arises. The RECEIVER side of this convention is ENFORCED by the
  # build-time raw-pointer gate (buildSystem/check-raw-pointer-reads.js, 2026-07-17): a handler
  # body must consume this mapped argument — or map its own per-frame samples at the read site
  # — never the raw world.hand.position() (the tilted-selection bug class: correct aligned,
  # wrong-cell tilted).
  _pointerPositionInPlaneOf: (w) ->
    w.screenPointToMyPlane @position()

  # === press-and-hold recognizer (the touch grammar, ruling I2) ==================================
  # The dwell machine's sibling, built to the same law: the decision is ELAPSED EVENT-TIME from the
  # press origin while the pointer stays within grabDragThreshold of it — one notion of
  # "stationary", and never a wall-clock timer (Fizzygum-tests/DETERMINISM.md). It answers ONE
  # question for the whole grammar — do this stroke's drags mean what a mouse's would? — and, on a
  # finger that holds still, fires the right-click's own consequence: the pressed widget's context
  # menu, at the press point.
  #   A 'mouse' or 'pen' stroke arms at the press and consults no clock at all, so every path here
  # is the path those strokes have always taken.

  # Start the recognizer for a press on `pressedWdgt` (the widget the press hit).
  _beginPressAndHoldRecognition: (e, pressedWdgt) ->
    @_forgetPressAndHoldRecognition()
    @pressOriginPoint = @position()
    @pressOriginEventTime = WorldWdgt.timeOfEventBeingProcessed
    @_pressArmedForMouseSemantics = (e.pointerType isnt 'touch') or @_touchPressArmsAtOnce pressedWdgt

  # Does a TOUCH press here mean mouse semantics right away, with no hold? Two ways, both DERIVED
  # from what surfaces already declare rather than from a per-class "needs hold" flag:
  #  - a CHROME surface owns the press (ownsDragsStartingOnMe) — a window's title strip, a
  #    resize/move/rotate handle, a slider or a fattened scroll indicator, a stack's size adjuster,
  #    a palette: a drag there is that surface's own gesture and nothing competes for the finger;
  #  - or nothing here would take a plain drag for a SCROLL (claimsPlainDragsForScrolling) — the
  #    open desktop, a pane with nothing to scroll: a hold is demanded ONLY where a plain drag
  #    already means scroll (ruling I2).
  # Asked by ANCESTRY, like the editor-focus policy below: the top widget at a press on composed
  # chrome is a LEAF of it (a bar's close button, a slider's thumb), and the viewport that would
  # take the drag is an ancestor of whatever the press hit. Chrome answers first on the way up, so
  # a slider inside a scrolling pane still value-drags at once.
  _touchPressArmsAtOnce: (pressedWdgt) ->
    aScrollSurfaceWouldClaimIt = false
    ancestorOrHit = pressedWdgt
    while ancestorOrHit?
      return true if ancestorOrHit.ownsDragsStartingOnMe?()
      aScrollSurfaceWouldClaimIt ||= (ancestorOrHit.claimsPlainDragsForScrolling?() is true)
      ancestorOrHit = ancestorOrHit.parent
    not aScrollSurfaceWouldClaimIt

  # The time the hold decides against. At a drained event it is that EVENT's own time, and under
  # the harness that is the WHOLE decision: the pacing control suppresses the between-events
  # consultation below — the viewport momentum glide's own idiom — so a replayed stroke is purely
  # event-determined and its screenshots reproduce. Off the harness the per-cycle re-entry may also
  # consult the cycle clock, so a real finger holding PERFECTLY still, emitting no events at all,
  # still gets its menu on time.
  _holdDecisionTime: ->
    eventTime = WorldWdgt.timeOfEventBeingProcessed
    betweenEventsCheckSuppressed = Automator? and
      Automator.animationsPacingControl and
      Automator.state != Automator.IDLE
    return eventTime if betweenEventsCheckSuppressed
    cycleTime = WorldWdgt.dateOfCurrentCycleStart?.getTime()
    return eventTime unless cycleTime? and eventTime?
    Math.max eventTime, cycleTime

  # Advance the recognizer. Runs at every drained pointer event of a live press AND at the per-cycle
  # re-entry (the hover re-sync), exactly as the dwell machine does — a moving finger and a
  # motionless one both reach it.
  _advancePressAndHoldRecognition: ->
    return unless @pointerType is 'touch'
    return unless @mouseButton? and @pressOriginPoint? and @pressOriginEventTime?

    if @pressOriginPoint.distanceTo(@position()) > WorldWdgt.preferencesAndSettings.grabDragThreshold
      # THE TRAVELLING PRESS. Unlike the dwell, a move past the radius does NOT re-anchor: a finger
      # that has begun sliding must not arm mid-flick, so the stroke is a plain drag for the rest of
      # its life. And if the hold already opened a menu, this move IS the lift: the menu goes and
      # the drag proceeds with the mouse semantics the hold armed.
      @_pressLeftHoldRadius = true
      if @_pressHoldMenuStands
        @_pressHoldMenuStands = false
        if @mouseDownWdgt?
          # public-call-sanctioned: cleanupMenuWdgts IS my own dismissal sweep — the press path calls
          # it the same way. The hold menu is FRESH, so the sweep is asked to take fresh menus too,
          # exactly as the press path asks.
          @cleanupMenuWdgts @mouseDownWdgt, alsoKillFreshMenus: true
      return

    return if @_pressHoldFired or @_pressLeftHoldRadius
    # A press that has become a REAL drag belongs to what it is dragging — the dwell machine owns a
    # float-drag, a value control owns its own — so a hold never fires on top of one. The non-float
    # side asks whether the booked widget actually TAKES drag steps, and that precision is
    # load-bearing: a press on bare desktop books the WORLD as the non-float target and nothing
    # whatever follows from it (the world has no nonFloatDragging to receive), so reading that as a
    # drag would silence exactly the hold that opens the desktop's own menu.
    return if @isThisPointerFloatDraggingSomething()
    # ...but a BOOKED non-float target that has not MOVED is not being dragged either. A press books
    # its non-float target at the down, before a single step has been taken, so a finger resting on a
    # slider, a palette or a scrollbar would find its hold silenced by a drag that never happened —
    # and those are exactly the widgets whose own menu the hold exists to open. The booking suppresses
    # the hold only once the press has left the point it started from; a float-drag in progress
    # suppresses it unconditionally, because that one IS already carrying something.
    return if @nonFloatDraggedWdgt?.nonFloatDragging? and not @pressOriginPoint.equals @position()

    decisionTime = @_holdDecisionTime()
    return unless decisionTime?
    return if (decisionTime - @pressOriginEventTime) < WorldWdgt.preferencesAndSettings.pressAndHoldMs

    @_pressHoldFired = true
    @_pressHoldMenuStands = true
    # from the hold on, this stroke's drags mean what a mouse's would
    @_pressArmedForMouseSemantics = true
    if @mouseDownWdgt?
      # public-call-sanctioned: the hold is an alternate TRIGGER for the right-click's own verb, not
      # a parallel path — openContextMenuAtPointer is exactly what Widget.mouseClickRight fires, so
      # the titled menu, the dev-mode disambiguation and the world's own menu are inherited whole.
      @openContextMenuAtPointer @mouseDownWdgt

  # Do this stroke's drags mean what a MOUSE drag means — lift what detaches, value-drag a control —
  # or is it a plain finger drag the surface under it may take for a scroll? The grammar's two
  # consumers (my own grab arms below, a viewport's scroll-drag step) ask this and nothing else. A
  # 'mouse' or 'pen' stroke answers yes without consulting any state, so their paths are exactly
  # what they were.
  strokeMeansMouseDrag: ->
    @pointerType isnt 'touch' or @_pressArmedForMouseSemantics

  # THE FINGER LEFT THE GLASS. A touch stroke has no between-strokes position — nothing rests under
  # a lifted finger — so at its end every widget the stroke walked over is told the pointer left,
  # and the over-list empties. Without it the last-tapped widget keeps a hover highlight, and a
  # viewport a fattened indicator, with no pointer anywhere near them. A mouse or a pen DOES rest
  # where it stopped, so their strokes keep the over-list they built, untouched.
  _dissolveHoverStateOfTouchStroke: ->
    return unless @pointerType is 'touch'
    @mouseOverList.forEach (old) =>
      old.mouseLeave?()
      old.mouseLeavefloatDragging?()  if @mouseButton
    @mouseOverList.clear()
    # ...and the glass STAYS empty until a pointer comes back. Emptying the list alone would not
    # last: the per-cycle hover re-sync re-derives the set from where the hand happens to stand, so
    # a cycle later it would enter every widget the finger just left, tooltip and highlight and all.
    @_pointerIsAbsent = true
    return

  processPointerDown: (e) ->
    @pointerType = e.pointerType
    # a press begins: whatever the previous stroke recognized is spent (the press below re-establishes
    # it), and the position head right after must not advance a recognizer belonging to a dead stroke
    @_forgetPressAndHoldRecognition()
    # THE POINTER IS BACK — a down states where it is. The position head below then rebuilds the
    # over-list at the press point, which is the truth from here on.
    @_pointerIsAbsent = false
    # A pointer down states its own position, and for a finger or a pen it is the FIRST event that
    # states one — there is no hover to have walked the pointer there. So take the position from
    # the down itself, by running the move pipeline for it before the press. Skipped when the event
    # states no place (every synthesised down: see PointerInputEvent.worldX) or the pointer already
    # stands there, so a mouse stroke — where a move always precedes — is untouched.
    if e.worldX?
      pointerPosition = @position()
      if e.worldX isnt pointerPosition.x or e.worldY isnt pointerPosition.y
        @processPointerMove e

    world.destroyToolTips()
    @wdgtToGrab = undefined

    if Automator? and Automator.state == Automator.PLAYING
      if e.button is 2 or e.ctrlKey
        Automator.fade 'rightMouseButtonIndicator', 0, 1, 10, new Date().getTime()
      else
        Automator.fade 'leftMouseButtonIndicator', 0, 1, 10, new Date().getTime()


    @mouseDownPosition = @position()

    # check whether we are in the middle
    # of a floatDrag/drop operation
    if @isThisPointerFloatDraggingSomething()
      @drop()
      @mouseButton = undefined
    else
      w = @topWdgtUnderPointer()

      @destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem w
      @stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere w

      # if we are doing a mousedown on anything outside a menu
      # then all the menus must go, whether or not they have
      # been freshly created or not. This came about because
      # small movements of the mouse while clicking on the
      # desktop would not dismiss menus.
      if !(w.enclosingFrame()?.isMenu?())
        @cleanupMenuWdgts w, alsoKillFreshMenus: true

      @wdgtToGrab = w.findRootForGrab()
      # the press-and-hold recognizer starts here, on the widget the press hit: it is that widget's
      # own surroundings that decide whether a finger must hold before its drag means what a mouse
      # drag means, and that widget whose context menu a hold opens
      @_beginPressAndHoldRecognition e, w
      if e.button is 2 or e.ctrlKey
        @mouseButton = "right"
        actualClick = "mouseDownRight"
        expectedClick = "mouseClickRight"
      else
        @mouseButton = "left"
        actualClick = "mouseDownLeft"
        expectedClick = "mouseClickLeft"

      @mouseDownWdgt = w
      @mouseDownWdgt = @mouseDownWdgt.parent  until @mouseDownWdgt[expectedClick]

      
      while !w[actualClick]?
        if w.parent?
          w = w.parent
        else
          break

      if w[actualClick]?
        w[actualClick] @_pointerPositionInPlaneOf(w)
  
  
  processPointerUp: (e) ->
    # the same position head as the down (a browser pointerup states where it happened; a
    # synthesised one states no place, and then the pointer keeps the position it holds)
    if e.worldX?
      pointerPosition = @position()
      if e.worldX isnt pointerPosition.x or e.worldY isnt pointerPosition.y
        @processPointerMove e

    # the release is an evaluation point for the hold too (the dwell's rule, applied to the press):
    # a finger that held still and let go without ever emitting a move still gets its menu, at the
    # event time of the release
    @_advancePressAndHoldRecognition()

    if Automator? and Automator.state == Automator.PLAYING
      if e.button is 2
        Automator.fade 'rightMouseButtonIndicator', 1, 0, 500, new Date().getTime()
      else
        Automator.fade 'leftMouseButtonIndicator', 1, 0, 500, new Date().getTime()

    w = @topWdgtUnderPointer()

    world.destroyToolTips()
    world.freshlyCreatedPopUps.clear()


    if @isThisPointerFloatDraggingSomething()
      @drop()
    else if @_pressHoldFired
      # THE HOLD CONSUMED THIS STROKE. Its menu already happened, so the release dispatches no click
      # and dismisses nothing — the same shape a right press has, which never fires mouseClickLeft
      # either. A menu still standing (the finger let go without moving) stays: it is an ordinary
      # transient menu from here on, and the next tap outside it takes it away.
      #   The non-float contract still holds: the hold can be followed by a value-drag, and a control
      # left mid-drag must be told the drag is over (see the arm below).
      if @isThisPointerNonFloatDraggingSomething()
        @nonFloatDraggedWdgt.endOfNonFloatDrag?()
      @previousNonFloatDraggingPos = undefined
    else

      # used right now for the slider button:
      # it's likely that the non-float drag will end
      # up outside of its bounds, and yet we need to
      # notify the button that the drag is over so it
      # can repaint itself of another color.
      if @isThisPointerNonFloatDraggingSomething()
        @nonFloatDraggedWdgt.endOfNonFloatDrag?()

      @previousNonFloatDraggingPos = undefined

      if @mouseButton is "left"
        expectedClick = "mouseClickLeft"
      else
        expectedClick = "mouseClickRight"

      # trigger the action
      until w[expectedClick]
        w = w.parent
        if not w?
          break
      if w?
        if w == @mouseDownWdgt

          switch expectedClick
            when "mouseClickLeft"
              w.mouseUpLeft? @_pointerPositionInPlaneOf(w), e.button, e.buttons, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey
            when "mouseClickRight"
              w.mouseUpRight? @_pointerPositionInPlaneOf(w), e.button, e.buttons, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey

          # also send doubleclick if the
          # two clicks happen on the same widget
          doubleClickInvocation = false

          # Forget a STALE candidate on an EVENT-TIME gap BEFORE matching: if the
          # remembered double-click candidate was armed more than doubleClickWindowMs
          # of EVENT time ago it belongs to a PREVIOUS gesture, so drop it now and let
          # this click start fresh. This is the sole, authoritative, deterministic
          # recognition forget — load-immune because event times are the macro's
          # deterministic schedule (and real browser timestamps for users), unlike a
          # wall-clock timer that starves under heavy-cycle load (a dpr-2 SWCanvas render
          # under parallel test shards), the race this replaced. So two distinct same-spot
          # gestures — spaced > the window apart — never fold, while a gesture's own clicks
          # (~120ms apart, < the window) still do.
          if @doubleClick.isStale WorldWdgt.timeOfEventBeingProcessed, @doubleClickWindowMs
            @doubleClick.forget()

          if @doubleClick.wdgt?
            # three conditions:
            #  - both clicks are left-button clicks
            #  - both clicks on same widget
            #  - both clicks nearby
            if @mouseButton == "left" and
             @doubleClick.recognizes w, @position(), WorldWdgt.preferencesAndSettings.grabDragThreshold
              @doubleClick.forget()
              # remember we are going to send a double click
              # but let's do it after. That's because we first
              # want to send the normal click AND we want to tell
              # in the normal click that that normal click is part
              # of a double click. Recognition is proximity + a doubleClickWindowMs
              # EVENT-TIME window (the forget gate above; deterministic, NOT wall-clock):
              # synthetic macro clicks deliberately space their two clicks ~120ms apart
              # (inside the window) and keep a non-scaled minimum gap between DISTINCT
              # click gestures (MacroToolkit).
              doubleClickInvocation = true
              # triple-click detection starts here, it's just
              # like chaining a second double-click detection
              # once this double-click has just been detected
              # right here.
              @tripleClick.arm w, @position(), WorldWdgt.timeOfEventBeingProcessed
            else
              # This click does NOT complete a double-click with the remembered widget
              # (different widget/position — a SAME-spot stale candidate from a previous
              # gesture is already cleared by the event-time gate above). Treat a LEFT click
              # as the START of a fresh double-click sequence rather than discarding it,
              # otherwise a deliberate double/triple-click on a freshly-targeted widget would
              # silently degrade (its first click eaten). A non-left click just clears the
              # (left) candidate.
              if @mouseButton == "left"
                @doubleClick.arm w, @position(), WorldWdgt.timeOfEventBeingProcessed
              else
                @doubleClick.forget()
          else
            @doubleClick.arm w, @position(), WorldWdgt.timeOfEventBeingProcessed

          tripleClickInvocation = false

          # event-time forget for the triple-click candidate (same rationale as the
          # double-click gate above): a triple candidate armed more than doubleClickWindowMs
          # of event time ago belongs to a previous gesture — drop it before matching.
          if @tripleClick.isStale WorldWdgt.timeOfEventBeingProcessed, @doubleClickWindowMs
            @tripleClick.forget()

          # also send tripleclick if the three clicks happen on the same widget. Don't fire it if a
          # double-click was just invoked (same three-condition check as the double-click branch above).
          if !doubleClickInvocation
            # same three conditions as double click.
            if @mouseButton == "left" and
             @tripleClick.recognizes w, @position(), WorldWdgt.preferencesAndSettings.grabDragThreshold
              @tripleClick.forget()
              # remember we are going to send a triple click
              # but let's do it after. That's because we first
              # want to send the normal click AND we want to tell
              # in the normal click that that normal click is part
              # of a triple click. (Recognition is proximity + the doubleClickWindowMs
              # EVENT-TIME window — see the double-click branch above.)
              tripleClickInvocation = true

          # fire the click, sending info on whether this was part
          # of a double/triple click
          # ANCESTRY-aware (§5.D): the top widget at a click on composed chrome
          # is a LEAF of it (a tool button's icon face, a toolbar scrollbar, a
          # text button, a font-menu item), so the ONE editor-chrome capability
          # is honored over the whole opted-out subtree (D2a folded the former
          # editorContentPropertyChangerButton field into this same walk).
          if !(@_excludedFromEditorFocusTrackingByAncestry w)
            world.editorFocusWdgt = w
          w[expectedClick] @_pointerPositionInPlaneOf(w), e.button, e.buttons, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey, doubleClickInvocation, tripleClickInvocation

          # now send the double/triple clicks
          if doubleClickInvocation
            @processDoubleClick w
          if tripleClickInvocation
            @processTripleClick w


      # some pop-overs can contain horizontal sliders
      # and when the user interacts with them, it's easy
      # that she can "drag" them outside the range and
      # do the mouse-up outside the boundaries
      # of the pop-over. So we avoid that here, if there
      # is a non-float drag ongoing then we avoid
      # cleaning-up the pop-overs
      if !@nonFloatDraggedWdgt?
        @cleanupMenuWdgts w

    @_dissolveHoverStateOfTouchStroke()
    @mouseButton = undefined
    @nonFloatDraggedWdgt = undefined


  # An ABORT: the browser confiscated the stroke (a system gesture took it over, a palm was
  # rejected, the tab went away). The user never released deliberately, so nothing that means "the
  # user chose this spot / this target" may happen — no click dispatch, no menu dismissal (nothing
  # was clicked outside anything), no embed and no dock. Its OWN method rather than a flag on
  # processPointerUp: an up means exactly the thing a cancel does not.
  #
  # What the abort still owes is the payload of a float-drag — it may be the only copy of an object
  # the user made — so it lands on the world where it visibly is. Every decision here is state and
  # EVENT time only; a cancel reads no clock.
  processPointerCancel: (e) ->
    if @isThisPointerFloatDraggingSomething()
      # the dwell is a statement of INTENT and a confiscated stroke has none, so tear the
      # interaction down BEFORE the release — that also keeps drop() from re-evaluating the arm
      # clock at the cancel instant — and then force the landing.
      @_endDragEmbedInteraction()
      @drop world
    else if @isThisPointerNonFloatDraggingSomething()
      # the same contract processPointerUp honours: the slider button must repaint un-pressed even
      # though the release happened outside its bounds — or, here, never happened at all.
      @nonFloatDraggedWdgt.endOfNonFloatDrag?()

    # the stroke is dead: no phantom pressed state may linger, and a later tap must not fold with
    # this cancelled press into a double-click. The shared clear takes the press-and-hold recognizer
    # with it — a confiscated press states no intent, so it can neither arm nor open a menu. One
    # that ALREADY opened stays open: the cancel is not a click outside it.
    @_forgetPressBookkeeping()
    @_dissolveHoverStateOfTouchStroke()
    @mouseButton = undefined
    @previousNonFloatDraggingPos = undefined


  # Dismiss the open pop-up cascade around a click on `clickedWdgt`: everything that asked to be
  # told about a click outside itself, and is not in that widget's ancestry, gets its callback.
  # `alsoKillFreshMenus` rides opts because only the mouse-DOWN path wants it (a bare boolean is
  # never a head operand, R1) — the mouse-UP path passes the widget alone.
  cleanupMenuWdgts: (clickedWdgt, opts = {}) ->
    alsoKillFreshMenus = opts.alsoKillFreshMenus

    world.hierarchyOfClickedWdgts.clear()
    world.hierarchyOfClickedMenus.clear()

    # note that all the actions due to the clicked
    # widgets have been performed, now we can destroy
    # widgets queued up for closure
    # which might include menus...
    # if we destroyed menus earlier, the
    # actions that come from the click
    # might be mangled, e.g. adding a menu
    # to a destroyed menu, etc.
    world.closePopUpsMarkedForClosure()

    # remove menus that have requested to be removed when a click happens outside of their bounds OR
    # the bounds of their children: collect all widgets up the hierarchy of the one the user clicked on
    # (including the one the user clicked on).
    ascendingWdgts = clickedWdgt
    world.hierarchyOfClickedWdgts.clear()
    world.hierarchyOfClickedWdgts.add ascendingWdgts
    while ascendingWdgts.parent?
      ascendingWdgts = ascendingWdgts.parent
      world.hierarchyOfClickedWdgts.add ascendingWdgts

    # remove menus that have requested to be removed when a click happens outside of their bounds OR
    # the bounds of their children: collect all the menus up the hierarchy of the one the user clicked
    # on (including the one the user clicked on) -- note that the hierarchy of the menus is actually
    # via the getParentPopUp method.
    enclosingFrame = clickedWdgt.enclosingFrame()
    if enclosingFrame?.hierarchyOfPopUps?
      world.hierarchyOfClickedMenus = enclosingFrame.hierarchyOfPopUps()
    
    # go through the widgets that wanted a notification
    # in case there is a click outside of them or any
    # of their children.
    # i.e. check from the notification list which ones are not
    # in the hierarchy of the clicked widgets
    # and call their callback.
    

    # because we might remove elements of the set while we
    # iterate on it (as we destroy menus that want to be destroyed
    # when the user clicks outside of them or their children)
    world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.forEach (eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren) =>
      if (!world.hierarchyOfClickedMenus.has eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren) and
         (!world.hierarchyOfClickedWdgts.has eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren)
        # skip the freshly created menus as otherwise we might
        # destroy them immediately
        if alsoKillFreshMenus or !world.freshlyCreatedPopUps.has eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren
          if eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[0]?
            eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren[eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[0]].call eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren, eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[1], eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[2], eachWdgtWantingToBeNotifiedIfClickOutsideThemOrTheirChildren.clickOutsideMeOrAnyOfMeChildrenCallback[3]

  processDoubleClick: (w = @topWdgtUnderPointer()) ->
    world.destroyToolTips()
    if @isThisPointerFloatDraggingSomething()
      @drop()
    else
      w = w.parent  while w and not w.mouseDoubleClick
      w.mouseDoubleClick @_pointerPositionInPlaneOf(w) if w
    @mouseButton = undefined

  processTripleClick: (w = @topWdgtUnderPointer()) ->
    world.destroyToolTips()
    if @isThisPointerFloatDraggingSomething()
      @drop()
    else
      w = w.parent  while w and not w.mouseTripleClick
      w.mouseTripleClick @_pointerPositionInPlaneOf(w) if w
    @mouseButton = undefined
  
  # see https://developer.mozilla.org/en-US/docs/Web/Events/wheel
  processWheel: (deltaX, deltaY, deltaZ, altKey, button, buttons) ->
    w = @topWdgtUnderPointer()
    w = w.parent  while w and not w.wheel

    if w?
      w.wheel deltaX, deltaY, deltaZ, altKey, button, buttons
  
  


  
  # ActivePointerWdgt tools

  processPointerMove: (e) ->
    @pointerType = e.pointerType
    # A HOVER-CAPABLE POINTER HAS COME BACK: a mouse or a pen moving states that something rests on
    # the glass again, wherever it goes. A finger's own moves say nothing of the sort — they belong
    # to a press, which ended the absence at its down.
    @_pointerIsAbsent = false  if e.pointerType isnt 'touch'

    # the event already speaks WORLD coordinates: the page → world conversion happens once, at the
    # browser boundary (PointerInputEvent.fromBrowserEvent)
    pos = new Point e.worldX, e.worldY
    @_applyMoveTo pos

    if Automator? and Automator.state == Automator.PLAYING
      mousePointerIndicator = document.getElementById "mousePointerIndicator"
      mousePointerIndicator.style.display = 'block'
      posInDocument = world.getCanvasPosition()
      mousePointerIndicator.style.left = (posInDocument.x + e.worldX - (mousePointerIndicator.clientWidth/2)) + 'px'
      mousePointerIndicator.style.top = (posInDocument.y + e.worldY - (mousePointerIndicator.clientHeight/2)) + 'px'

    # determine the new mouse-over-list.
    # Spacial multiplexing
    # (search "multiplexing" for the other parts of
    # code where this matters)
    # There are two interpretations of what this
    # list should be:
    #   1) all widgets "pierced through" by the pointer
    #   2) all widgets parents of the topmost widgets under the pointer
    # 2 is what is used in Cuis
    
    topWdgt = @topWdgtUnderPointer()
    # allParentsTopToBottom makes more logical sense but
    # allParentsBottomToTop is cheaper and it all ends up in a set anyways
    mouseOverNew = new Set topWdgt.allParentsBottomToTop()

    @determineGrabs pos, topWdgt, mouseOverNew

    @dispatchEventsFollowingMouseMove mouseOverNew

  checkDraggingThreshold: ->
    # UNFORTUNATELY OLD tests didn't take the correction into account,
    # pointers inevitably have some "noise", so to avoid that
    # a simple clicking (which could be done for example for
    # selection purposes or to pick a position for a cursor)
    # turns into a drag, so we add
    # a grab/drag distance threshold.
    # Note that even if the mouse moves a bit, we are still
    # picking up the correct widget that was under the mouse when
    # the mouse down happened.
    # Also we correct for the initial displacement
    # due to the threshold, so really when user starts dragging
    # it should pick up the EXACT point where the click happened,
    # not a "later" point once the threshold is passed.

    # so we have to bypass this mechanism for those.
    displacementDueToGrabDragThreshold = undefined
    skipGrabDragThreshold = false

    # A TOUCH PRESS THAT HAS NOT MOVED IS NOT A DRAG, ahead of every carve-out below. A zero-delta
    # move event advances the clocks a live press runs on — the drag-embed dwell, the press-and-hold
    # recognizer — and must not float anything while doing it: a finger holding perfectly still
    # emits exactly such an event to cross its hold window, and picking the pressed widget up there
    # would end the gesture before it was recognised.
    #   Keyed on the STROKE's kind, like every other branch of the grammar. A mouse's zero-delta
    # pressed move DOES still grab, because for a mouse that move is the first sample of a gesture
    # the pointer walked to its origin before pressing — its grab point and the displacement
    # correction below are measured from there, and moving that decision one sample later moves
    # every dragged widget by the sample's own offset (measured: 41 references).
    return [true, undefined] if @pointerType is 'touch' and @mouseDownPosition? and @mouseDownPosition.equals @position()

    # ...and the Automator's own bypass (a test that declares no threshold gets none) is a MOUSE
    # carve-out too, for the same reason: a TOUCH stroke always takes the threshold, whatever the
    # test says, because the grammar's press-and-hold is DEFINED as staying inside it.
    if Automator? and Automator.state == Automator.PLAYING and @pointerType isnt 'touch'
      if !window["#{world.automator.player.currentlyPlayingTestName()}"].grabDragThreshold?
        skipGrabDragThreshold = true

    if !skipGrabDragThreshold
      # The instant-grab carve-out — no threshold at all for a non-editable widget sitting directly
      # on the desktop — is a MOUSE-FEEL rule: a mouse is steady, and a desktop widget that lifts on
      # the first pixel of travel feels immediate. A FINGER is noisy by nature, so a touch stroke
      # always takes the threshold: 7 px before a lift begins is imperceptible on glass, while
      # without it a trembling finger could never hold long enough to open anything.
      if @pointerType is 'touch' or @wdgtToGrab.parent != world or (!@wdgtToGrab.isEditable? or @wdgtToGrab.isEditable )
        if (@mouseDownPosition.distanceTo @position()) < WorldWdgt.preferencesAndSettings.grabDragThreshold
          return [true,undefined]
      displacementDueToGrabDragThreshold = @position().subtract @mouseDownPosition

    return [false, displacementDueToGrabDragThreshold]

  determineGrabs: (pos, topWdgt, mouseOverNew) ->
    if !@isThisPointerDraggingSomething() and (@mouseButton is "left")
      w = topWdgt.findRootForGrab()
      # R1 (§6 affine): map into the RECEIVER's plane so a mouseMove consumer inside a rotated/
      # scaled island (e.g. a paint canvas) draws under the cursor, not at the raw screen pos.
      # screenPointToMyPlane returns the same point off any island ⇒ byte-identical dormant.
      #   THE GRAMMAR'S THIRD CONSUMER (ruling I2): this arm runs only under a live press, and while
      # a touch stroke is UN-ARMED its moves mean scroll and nothing else — a finger sliding over
      # text must not extend a selection, and one sliding over a paint canvas must not draw, while
      # the pane beneath it is scrolling. A mouse or pen stroke always means a mouse drag, so the
      # test short-circuits and this dispatch is exactly what it was.
      topWdgt.mouseMove topWdgt.screenPointToMyPlane(pos)  if topWdgt.mouseMove and @strokeMeansMouseDrag()

      # if a widget is marked for grabbing, grab it
      if @wdgtToGrab
        
        # Grab/drag threshold, computed ONCE for all three arms below (was duplicated in the
        # two float-drag arms). checkDraggingThreshold is a pure read; the non-float else-arm
        # ignores the result, exactly as before (it never gated on the threshold).
        [skipDragging, displacementDueToGrabDragThreshold] = @checkDraggingThreshold()

        # these first two cases are for float dragging
        # the third case is non-float drag.
        # THE GRAMMAR'S FIRST CONSUMER: the two FLOAT arms are what a mouse drag means — pick the
        # thing up — so they run only while the stroke means a mouse drag. An un-armed finger drag
        # falls through to nothing here and the scroll surface under it takes the gesture instead
        # (ruling I2). The non-float arm below is untouched: reaching it means the press landed on a
        # value control or a handle, which is chrome and arms at the press.
        if @wdgtToGrab.isTemplate
          if skipDragging or !@strokeMeansMouseDrag() then return

          w = @wdgtToGrab.fullCopy()
          w.isTemplate = false
          @grab w, displacementDueToGrabDragThreshold
          @grabOrigin = @wdgtToGrab.situation()

        else if @wdgtToGrab.detachesWhenDragged()
          if skipDragging or !@strokeMeansMouseDrag() then return

          originalWdgtToGrab = @wdgtToGrab
          @wdgtToGrab = @wdgtToGrab.grabbedWidgetSwitcheroo()
          switcherooHappened = (originalWdgtToGrab != @wdgtToGrab)
          # Affine transforms (§6 Phase 4D-2a): PICK-OUT + Bug-F identity-wrapper dissolve. Resolve the
          # FIGURE that comes onto the hand — reuse the sole-content island, extract a genuine sub-part into
          # a fresh island, or (off any island) return the widget UNCHANGED ⇒ byte-identical dormant — then
          # dissolve an identity compensating sugar wrapper so the BARE content grabs. The whole two-step is
          # _resolvePickUpFigure, SHARED with the menu "pick up" entry point (pickUpMenuAction) so the two
          # cannot drift; its doc comment carries the full pick-out / Bug-F reasoning. Resolved HERE (once,
          # at drag-start) so BOTH the grab below and the "pointer left its bounds, re-centre" re-grab
          # further down in this method operate on the SAME figure. It does NOT set switcherooHappened
          # (the fresh figure is already positioned to stay put, then follows the cursor via
          # displacementDueToGrabDragThreshold — no centre-under-pointer snap).
          @wdgtToGrab = @wdgtToGrab._resolvePickUpFigure()
          w = @wdgtToGrab
          @grab w, displacementDueToGrabDragThreshold, switcherooHappened

        else
          # non-float drags are for things such as sliders
          # and resize handles.
          # you could have the concept of de-noising, but
          # actually it seems nicer to have a "springy"
          # reaction to a slider with some noise.
          # Users don't seem to click on a slider for any other
          # reason than to move it (as opposed to selecting them
          # or picking a position for a cursor), so it's OK.
          @nonFloatDraggedWdgt = @wdgtToGrab
          # Affine transforms (§6 4A-2): capture the grab offset IN THE GRABBED WIDGET'S OWN PLANE.
          # For a handle/slider inside a non-identity island the raw screen `pos` and the widget's
          # (virtual) position() live in different planes; screenPointToMyPlane maps the pointer into
          # the widget's plane so this offset — and the newPos differenced from it in nonFloatDragging
          # — are plane-consistent. Off every island screenPointToMyPlane returns the SAME point ⇒
          # byte-identical (dormant).
          @nonFloatDragPositionWithinWdgtAtStart =
            # if we ever will need to compensate for the grab/drag
            # threshold here, just add .subtract displacementDueToGrabDragThreshold
            (@nonFloatDraggedWdgt.screenPointToMyPlane(pos).subtract @nonFloatDraggedWdgt.position())


        # if the mouse has left its fullBounds, center it
        if w
          fb = w.fullBounds()
          # Affine transforms (§6 4A-2): w.fullBounds() is in w's OWN (virtual) plane, so test it
          # against the pointer mapped INTO that plane — otherwise, for a widget inside a non-identity
          # island, the on-screen pointer sits ON w yet lies outside w's virtual bounds, so this
          # mis-fires and @grabs w onto the hand (yanking it — and its handle — out of the island, which
          # then breaks the plane-mapped resize below). screenPointToMyPlane is identity off any island
          # ⇒ byte-identical (dormant).
          unless fb.containsPoint w.screenPointToMyPlane(pos)
            @_applyExtent @extent().subtract fb.extent().floorDivideBy 2
            @grab w
            @_applyMoveTo pos


    if @isThisPointerNonFloatDraggingSomething()

      # OK so this is an interesting choice. You can avoid
      # this next line and have Fizzygum to behave like OSX where you
      # can scroll on a panel without bringing its window in the
      # foreground. OR you can have the window to automatically
      # pop into the foreground. I'm liking the OSX style
      # so I'm leaving this commented-out, but it's there.
      # TODO this could be a setting somewhere in Fizzygum.
      # @nonFloatDraggedWdgt.bringToForeground()

      if @mouseButton
        if @previousNonFloatDraggingPos?
          deltaDragFromPreviousCall = pos.subtract @previousNonFloatDraggingPos
        else
          deltaDragFromPreviousCall = undefined
        @previousNonFloatDraggingPos = pos
        @nonFloatDraggedWdgt.nonFloatDragging?(@nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall)
    

  # this is used by the viewport: clicking on the slider
  # (but OUTSIDE of the button), the (center of the) button
  # is immediately non-float dragged to where clicked.
  nonFloatDragWdgtFarAwayToHere: (wdgtFarAway, pos) ->
    # allParentsTopToBottom makes more logical sense but
    # allParentsBottomToTop is cheaper and it all ends up in a set anyways
    mouseOverNew = new Set wdgtFarAway.allParentsBottomToTop()
    @previousNonFloatDraggingPos = wdgtFarAway.center()
    @nonFloatDragPositionWithinWdgtAtStart = (new Point wdgtFarAway.width()/2, wdgtFarAway.height()/2).round()
    @nonFloatDraggedWdgt = wdgtFarAway
    # this one calls the wdgtFarAway's nonFloatDragging method,
    # for example in case of a SliderWdgt invoking this on its
    # button, this causes the movement of the button
    # and adjusting of the Slider values and potentially
    # adjusting the viewport etc.
    @determineGrabs pos, wdgtFarAway, mouseOverNew

    # The teleported widget is now under the (stationary) pointer. Resolve the
    # mouseEnter/mouseLeave consequence of that geometry change NOW, while the
    # non-float drag is active, so the widget's mouseEnter is consumed under the
    # drag guard (e.g. SliderButtonWdgt.mouseEnter early-returns while the hand
    # is dragging) and the widget is recorded in @mouseOverList. Otherwise the
    # next per-cycle reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges
    # (WorldWdgt.doOneCycle) can fire that mouseEnter AFTER mouse-up has already
    # un-dragged the widget — spuriously HIGHLIGHTing it. Deferring this caused a
    # dpr-2-only flake in SystemTest_macroSliderTrackClickMovesButton: a heavy
    # SWCanvas cycle drains the down+up together, so no held-button frame ever
    # interposes to absorb the enter. Resolving it here is cadence/density-independent.
    @dispatchEventsFollowingMouseMove mouseOverNew

  # The focus-tracking exclusion policy (§5.D): a click/drop must not move the
  # editor focus pointer (world.editorFocusWdgt)
  # when the hit widget OR ANY ANCESTOR opted out via
  # excludedFromEditorFocusTracking. Ancestry matters because the top widget at a
  # click on composed chrome is a LEAF of it -- a paint tool click lands on the
  # button's icon FACE, a toolbar scroll on the scrollbar -- and a self-only
  # check let every such leaf silently steal the focus the press then needed
  # (probed, not assumed). Lives HERE, not on Widget: the pointer owns the
  # focus-tracking policy (widgets declare only the per-class opt-out), and a
  # Widget-level helper would churn the inherited-members inspector list.
  _excludedFromEditorFocusTrackingByAncestry: (aWdgt) ->
    ancestorOrHit = aWdgt
    while ancestorOrHit?
      if ancestorOrHit.excludedFromEditorFocusTracking?()
        return true
      ancestorOrHit = ancestorOrHit.parent
    false

  # Per-cycle hover re-sync for widgets that MOVED under a STATIONARY pointer (pointer MOTION is handled
  # per-event inside _playQueuedEvents; this catches stepping animations, event-driven relayouts, teleports,
  # opens/closes). It runs AFTER @recalculateLayouts() in WorldWdgt.doOneCycle, so it re-derives the
  # widgets-under-pointer set against SETTLED geometry (the same fixed point paint reads). Hover handlers
  # must not make a careless (off-settle) layout push -- self-settling mutations (e.g. a tooltip fullDestroy)
  # are fine; the end-of-cycle capstone gate enforces this. See docs/archive/hover-resync-after-flush-plan.md.
  reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges: ->
    topWdgt = @topWdgtUnderPointer()
    # allParentsTopToBottom makes more logical sense but
    # allParentsBottomToTop is cheaper and it all ends up in a set anyways
    mouseOverNew = new Set topWdgt.allParentsBottomToTop()
    @dispatchEventsFollowingMouseMove mouseOverNew

  dispatchEventsFollowingMouseMove: (mouseOverNew) ->

    # NOTHING IS UNDER A POINTER THAT IS NOT THERE. While the glass is empty (a touch stroke ended
    # and none has begun), the widgets the last stroke walked over stay LEFT: no enter, no move, and
    # an over-list that stays empty — so the per-cycle re-sync cannot undo, a cycle later, the sweep
    # that stroke's own end performed. The press machinery at the tail runs either way: a live press
    # cleared the absence at its down, so this can never starve one.
    mouseOverNew = new Set  if @_pointerIsAbsent

    @mouseOverList.forEach (old) =>
      unless mouseOverNew.has old
        old.mouseLeave?()
        old.mouseLeavefloatDragging?()  if @mouseButton

    # THE GRAMMAR'S THIRD CONSUMER (ruling I2), the other half of the one in determineGrabs: while a
    # touch stroke is UN-ARMED its moves mean scroll and nothing else, so no widget is handed a
    # PRESSED move — this is the site a selection would otherwise extend through, since the tap's own
    # mouseDownLeft already armed the string, and the site a paint tool or a plot rotation would
    # otherwise consume. HOVER moves (no button down) are not this stroke's business and pass through
    # untouched; a mouse or pen stroke always means a mouse drag, so this reads false for them and
    # every dispatch below is exactly what it was.
    pressedMovesAreWithheld = @mouseButton? and not @strokeMeansMouseDrag()

    mouseOverNew.forEach (newWdgt) =>

      # send mouseMove only if mouse actually moved,
      # otherwise it will fire also when the user
      # simply clicks
      if (!@mouseDownPosition? or !@mouseDownPosition.equals @position()) and not pressedMovesAreWithheld
        # R1 (§6 affine): map per-receiver into newWdgt's plane so a position-reading mouseMove
        # inside a rotated/scaled island lands on the cursor (dormant-safe: identity off any island).
        newWdgt.mouseMove?(newWdgt.screenPointToMyPlane(@position()), @mouseButton)
      
      unless @mouseOverList.has newWdgt
        newWdgt.mouseEnter?()
        newWdgt.mouseEnterfloatDragging?()  if @mouseButton

      # autoScrolling support:
      if @isThisPointerFloatDraggingSomething()
        widgetBeingFloatDragged = @children[0]
        # Window payloads never edge-auto-scroll a viewport (spec §12): dragging a window across a
        # big panel must not scroll it — the mouse wheel is the explicit, first-class way to reach an
        # off-view insertion point mid-drag (§6.1). Plain payloads keep edge-auto-scroll. (Was
        # `wantsToBeDropped()` — the old internal/external gate; the flip to the payload-class capability
        # is the drag-embed rule change, and it also drops the BinOpenerWdgt special-case here.)
        # §6 4D-2b: a tilted WINDOW rides the hand as a sugar wrapper, so classify through the payload-policy
        # proxy — a rotated window must not edge-auto-scroll either. The GEOMETRY arg below keeps the figure.
        if not widgetBeingFloatDragged._dropPolicyProxy().requiresDeliberateEmbedding()
          # a viewport decides whether to auto-scroll for the dragged widget near its edge
          # (instead of an inline `newWdgt instanceof ViewportWdgt` check + the
          # wantsDropOfChild / edge / start logic here). (type-test-elimination campaign)
          newWdgt.maybeStartAutoScrollForDraggedWidget? widgetBeingFloatDragged, @position()

    @mouseOverList = mouseOverNew

    # drag-embed dwell state machine (spec §6): resolve candidate + arm, declare the visuals. Runs per
    # move AND per cycle (via the hover re-sync), so a moving drag and a stationary hold both update.
    if @isThisPointerFloatDraggingSomething()
      @updateDragEmbedStateMachine()
    else if @_dragEmbedOutlinedWdgt? or world.dragEmbedChargeRingDeclared? or world.dragEmbedLabelDeclared? or world.dragEmbedLockBadgeDeclared?
      @_endDragEmbedInteraction()   # a drag ended some other way than drop() — clean up

    # press-and-hold recognizer, on the same seat and for the same reason: a finger that travels and
    # one that holds perfectly still must both be advanced, and only this method sees both.
    @_advancePressAndHoldRecognition()
