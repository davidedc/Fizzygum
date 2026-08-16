# not to be confused with the ActivePointerWdgt
# I am a resize / move handle that can be attached to any Widget

class HandleWdgt extends Widget

  target: undefined
  inset: undefined
  type: undefined
  # my carrier-owned corner knob — the layoutSpec I hand my parent at add() time,
  # and whose .inset I keep in step with @inset. LayoutSpec.coffee names this one
  # as the pattern's reference example.
  cornerSpec: undefined

  # Affine transforms (§6 Phase 4B): transient rotate-gesture reference frame — the island's rotation
  # and the pointer's angle about the anchor, both captured at grab-start (mouseDownLeft), cleared at
  # mouseUpLeft. undefined at rest / for every non-rotate handle, so nothing to serialize.
  _rotateGrabStartRotationDegrees: undefined
  _rotateGrabStartPointerAngleDegrees: undefined

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1

  # Resize / move / rotate handles are CHROME, never editor content (§5.D D-3/D21). Clicking or dragging a
  # handle to reshape a widget must NOT make the handle world.editorFocusWdgt -- otherwise the editor-focus
  # SELECTION overlay frames the HANDLE (it sits inside the reshaped widget's editing-amenity frame, so the
  # D21 walk would reach it). Same exemption as the frame-bar chrome (IconButtonWdgt / FrameBarWdgt);
  # honored by ancestry at ActivePointerWdgt's focus-set sites.
  excludedFromEditorFocusTracking: -> true

  # I am NOT given a target to attach to, and I do NOT attach myself. Like every other widget I am built
  # here and ATTACHED by whoever adds me: `someWidget.add handle` (self-settling, the standard discrete
  # attach) or `someWidget._addNoSettle handle` (deferred, inside a builder's own settle). defaultLayoutSpec
  # WhenAddedTo (below) makes me corner-attach to whatever real widget I am added to -- so the caller writes
  # the uniform `target.add handle`, no layoutSpec and no target-passed-twice; @target + the padding-aware
  # @inset are set in _reactToBeingAdded once the destination -- which IS the target -- is known (history:
  # see docs/archive/end-of-cycle-flush-final-records-plan.md).
  constructor: (@type = "resizeBothDimensionsHandle") ->
    # default inset; recomputed against the real target's padding in _reactToBeingAdded when I corner-attach
    @inset = new Point 2, 2
    super()
    @appearance = new HandleAppearance @
    @color = Color.WHITE
    @noticesTransparentClick = true

    @cornerSpec = new CornerInternalLayoutSpec @_anchorForType(), 0, WorldWdgt.preferencesAndSettings.handleSize, @inset

  # I corner-attach (the corner fixed by my @type) to whatever widget I am added to -- that widget becomes my
  # resize/move @target. Added to the WORLD or the HAND (a naked desktop handle, or while detached / picked
  # up) I am free-floating like any grabbed widget. Keying the placement off the destination is what lets
  # every caller use the uniform `target.add handle` -- no explicit layoutSpec -- and a detach-to-desktop drop
  # stay free-floating. (The base Widget answer is FREEFLOATING, so only handles place themselves on add.)
  defaultLayoutSpecWhenAddedTo: (destination) ->
    if destination == world or destination == world.hand
      return undefined
    @cornerSpec

  # my corner anchor, fixed by @type at construction (the spec carries it for the corner pass)
  _anchorForType: ->
    switch @type
      when "resizeBothDimensionsHandle" then 'bottomRight'
      when "moveHandle"                 then 'topLeft'
      when "resizeHorizontalHandle"     then 'rightMiddle'
      when "resizeVerticalHandle"       then 'bottomMiddle'
      # Affine transforms (§6 Phase 4B): the rotate handle takes the free TOP-RIGHT corner (the four
      # resize/move handles hold the other corners/edges). Corner-INTERNAL like the rest, so on an
      # island it is in-plane content painted into the island buffer — it warps with the content and
      # tracks the transformed corner for free (§4.6 halo model).
      when "rotateHandle"               then 'topRight'

  # HandleWdgt is overlay chrome (a resize/move handle), not a content child, so
  # it is excluded from content-bounds and real-children calculations (see
  # Widget.fullBounds and TreeNode.childrenNotHandlesNorCarets). Answered via
  # `?()` at the call sites, so no default lands on the Widget base.
  isLayoutInert: -> true

  # I attach directly to a scroll panel's frame (not its inner contents) when added -- the
  # container add methods key off this instead of `instanceof HandleWdgt`. (type-test-elimination campaign)
  attachesToScrollFrameDirectly: -> true

  detachesWhenDragged: ->
    if (@parent == world)
      return true
    else
      return false

  # HandleWdgts are one of the few widgets that
  # by default don't stick to their parents.
  # Also SliderButtonWdgts tend do the same (if
  # they are attached to a SliderWdgt)
  # The "move" HandleWdgt COULD grab to its
  # parent, in fact it would be easier, however for
  # uniformity we don't do that
  grabsToParentWhenDragged: ->
    return false


  _reactToBeingAdded: (whereTo, beingDropped) ->
    # Adopt whoever I was just added to as my resize/move @target -- UNLESS I landed free-floating (on the
    # world or the hand: a naked desktop handle, or mid-detach), in which case I have no target. The spec was
    # already resolved by defaultLayoutSpecWhenAddedTo during the add, so @isFreeFloating() tells the two
    # apart. Recompute the corner inset from the real target's padding now that I know it (the constructor only
    # had a default 2; for every non-menu attach the construction target used to supply this -- same value).
    unless @isFreeFloating()
      @target = whereTo
      pad = Math.max (@target.padding ? 2), 2
      @inset = new Point pad, pad
      @cornerSpec.inset = @inset
    @_moveInFrontOfSiblings()

  updateVisibility: ->
    # TODO rather than updating the visibility, we could
    # just make it "inactive" and by drawing it gray, which
    # would also look better (rather than a hole with
    # nothing)
    if @parent.isFreeFloating()
      @show()
    else
      @hide()


  # implement dummy methods in here
  # so the handle catches the clicks and
  # prevents the parent from doing anything.
  mouseClickLeft: ->
  # Affine transforms (§6 Phase 4B): end of a rotate gesture — clear the grab-start state so the next
  # grab re-captures its own reference angle. Harmless for the other handle types (fields stay undefined).
  mouseUpLeft: ->
    @_rotateGrabStartRotationDegrees = undefined
    @_rotateGrabStartPointerAngleDegrees = undefined
    # RE-RECORD request (the F6 family, auto-bookkeeping arc): this gesture resized/moved my
    # target by user intent, so its fractional bookkeeping is stale. Deferred to the world's
    # post-flush drain (my writes are deferred-settle, so the settled geometry is the
    # gesture's outcome) -- without it, a handle-resized stretch child snapped back to its
    # pre-gesture proportions on the next holder reflow (a long-standing product bug, the
    # arc's P0 probe GAP A).
    world.pendingFractionalReRecords.add @target  if @target?

  # same here, the handle doesn't want to propagate
  # anything, otherwise the handle on a button
  # will trigger the button when resizing.
  mouseDownLeft: (pos) ->
    return undefined  unless @target
    @target.bringToForeground()
    # Affine transforms (§6 Phase 4B): capture the rotate gesture's reference frame AT PRESS — the
    # island's current rotation plus the pointer's angle about the island's screen anchor. The drag
    # then rotates RELATIVE to this (no jump on grab). Captured here (hand is exactly at the press
    # point) rather than on the first drag sample, so the resulting angle is predictable from geometry.
    if @type is "rotateHandle"
      @_rotateGrabStartRotationDegrees = @target.rotationHalo_currentDegrees()
      @_rotateGrabStartPointerAngleDegrees = @_pointerAngleToTargetAnchorDegrees()

  # Affine transforms (§6 Phase 4B): angle (degrees) of the RAW screen pointer about my island
  # target's SCREEN anchor. DELIBERATELY screen-plane: the rotate handle is in-plane content that
  # spins with the island, so reading its 4A-1-mapped position would measure the angle in the very
  # plane it is rotating — a feedback loop (plan §4.6 / §6 4B). world.hand.position() is the raw
  # pointer (never plane-mapped), immune to 4A-2 mapping the `pos` passed to nonFloatDragging.
  # DETERMINISM (§6 4B risk note): Math.atan2 here is the fdlibm port on every reference-matched page
  # — the boot bundle those pages load runs DetTrig.install(Math) before any class source compiles, so
  # this call site cannot observe the platform's own atan2 there. On the native page it IS the
  # platform's, deliberately: those pixels are not reference-matched (owner call 2026-07-30). Never
  # name the DetTrig global here — the native bundle does not define it.
  _pointerAngleToTargetAnchorDegrees: ->
    anchor = @target.rotationHalo_screenAnchor()
    p = world.hand.position()
    Math.atan2(p.y - anchor.y, p.x - anchor.x) * 180 / Math.PI

  # Affine transforms (§6 Phase 4B): quantize a raw (float) rotation onto an integer-degree grid,
  # snapping to a cardinal angle (0/90/180/270) within ~3°. Integer quantization is the determinism
  # belt-and-braces over the atan2 above — any sub-ULP wobble rounds to the same integer, so the
  # committed rotationDegrees (hence every rotated pixel) is cross-engine identical.
  _quantizeRotationDegrees: (deg) ->
    d = ((deg % 360) + 360) % 360                    # JS % can be negative — normalise into [0, 360)
    for cardinal in [0, 90, 180, 270, 360]
      return (cardinal % 360)  if Math.abs(d - cardinal) <= 3   # 360 → 0
    Math.round d

  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->
    # Affine transforms (§6 4A-2): map the drag pointer into MY plane (my target's plane) before
    # differencing the grab-start offset — so a resize/move handle on a widget inside a non-identity
    # island drags the correct edge along the island's rotated/scaled axes. Because both operands are
    # now affine-mapped points, the translation cancels in the subtraction, leaving the pointer DELTA
    # mapped through the inverse LINEAR part only — exactly right for a vector displacement (plan §4.6).
    # Off every island screenPointToMyPlane returns the same point ⇒ byte-identical (dormant). The
    # "rotateHandle" case below ignores newPos (its angle uses the RAW pointer, deliberately screen-plane).
    newPos = (@screenPointToMyPlane pos).subtract nonFloatDragPositionWithinWdgtAtStart
    switch @type
      # 1. all these changes applied to the target are all deferred
      # 2. the position of this handle will be changed when the
      # _reLayout method of the parent of the handle will be called
      # ...i.e. *after* the parent has re-layouted (in the deferred layout phase).
      when "resizeBothDimensionsHandle"
        newExt = newPos.add(@extent().add(@inset)).subtract @target.position()
        @target._setExtentDeferredSettle newExt
      when "moveHandle"
        @target._moveToDeferredSettle newPos.subtract @inset
      when "resizeHorizontalHandle"
        newWidth = newPos.x + @extent().x + @inset.x - @target.left()
        @target._setWidthDeferredSettle newWidth
      when "resizeVerticalHandle"
        newHeight = newPos.y + @extent().y + @inset.y - @target.top()
        @target._setHeightDeferredSettle newHeight
      # Affine transforms (§6 Phase 4B): rotate the island target. newRot = rotation-at-grab + (current
      # pointer angle − pointer angle at grab), all in the SCREEN plane about the island's anchor. Lazy
      # re-capture if a drag ever arrives before mouseDownLeft ran. Deferred-settle like the resize
      # family (a 'slot' island settles to nothing; a coupled one reflows once at end of cycle).
      when "rotateHandle"
        if !@_rotateGrabStartPointerAngleDegrees?
          @_rotateGrabStartRotationDegrees = @target.rotationHalo_currentDegrees()
          @_rotateGrabStartPointerAngleDegrees = @_pointerAngleToTargetAnchorDegrees()
        rawDegrees = @_rotateGrabStartRotationDegrees + (@_pointerAngleToTargetAnchorDegrees() - @_rotateGrabStartPointerAngleDegrees)
        @target.rotationHalo_apply @_quantizeRotationDegrees rawDegrees

  
  # HandleWdgt events:
  mouseEnter: ->
    @state = @STATE_HIGHLIGHTED
    @_changed()
  
  mouseLeave: ->
    @state = @STATE_NORMAL
    @_changed()

  # Menu action ("attach..." -> choose target): corner-attach this handle to the chosen widget. A discrete
  # user action, so it goes through the public self-settling add() -- the corner placement comes from default
  # LayoutSpecWhenAddedTo and @target is adopted in _reactToBeingAdded (the destination IS the new target). add()
  # also unlinks me from any previous parent (e.g. the world, if I had been detached). Kept on this name + arg
  # position because the "attach..." menu dispatches it by string with the chosen target as the 3rd argument.
  makeHandleSolidWithParentWidget: (ignored, ignored2, widgetAttachedTo) ->
    widgetAttachedTo?.add @

    
  # HandleWdgt menu:
  attach: ->
    choices = world.plausibleTargetAndDestinationWidgets @
    menu = new MenuWdgt @, target: @, title: "choose target:"
    if choices.length > 0
      choices.forEach (each) =>
        menu.addMenuItem (each.toString().replace "Wdgt", "").slice(0, 50) + " ➜", @, 'makeHandleSolidWithParentWidget', arg1: each, representsAWidget: true
    else
      # Not pre-computed: finding eligible widgets is costly, so the list is calculated lazily
      # here, on menu-open; if none are found, show a message instead of hiding the entry.
      menu = new MenuWdgt @, target: @, title: "no widgets to attach to"
    menu.popUpAtHand() if choices.length
