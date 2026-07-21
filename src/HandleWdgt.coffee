# not to be confused with the ActivePointerWdgt
# I am a resize / move handle that can be attached to any Widget

class HandleWdgt extends Widget

  target: nil
  inset: nil
  type: nil

  # Affine transforms (§6 Phase 4B): transient rotate-gesture reference frame — the island's rotation
  # and the pointer's angle about the anchor, both captured at grab-start (mouseDownLeft), cleared at
  # mouseUpLeft. nil at rest / for every non-rotate handle, so nothing to serialize.
  _rotateGrabStartRotationDegrees: nil
  _rotateGrabStartPointerAngleDegrees: nil

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1

  # Capability query (replaces `widgetStartingTheChange instanceof HandleWdgt` in Widget's raw move/resize
  # paths): a geometry change INITIATED by a handle makes the moved/resized child remember its fractional
  # position/extent in its holding panel. True here only; dispatched via ?() (nothing on Widget).
  # (type-test-elimination campaign)
  changeShouldRememberFractionalGeometry: ->
    true

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
    @color = Color.WHITE
    @noticesTransparentClick = true

    @layoutSpec_cornerInternal_proportionOfParent = 0
    @layoutSpec_cornerInternal_fixedSize = WorldWdgt.preferencesAndSettings.handleSize
    @layoutSpec_cornerInternal_inset = @inset

  # I corner-attach (the corner fixed by my @type) to whatever widget I am added to -- that widget becomes my
  # resize/move @target. Added to the WORLD or the HAND (a naked desktop handle, or while detached / picked
  # up) I am free-floating like any grabbed widget. Keying the placement off the destination is what lets
  # every caller use the uniform `target.add handle` -- no explicit layoutSpec -- and a detach-to-desktop drop
  # stay free-floating. (The base Widget answer is FREEFLOATING, so only handles place themselves on add.)
  defaultLayoutSpecWhenAddedTo: (destination) ->
    if destination == world or destination == world.hand
      return LayoutSpec.ATTACHEDAS_FREEFLOATING
    switch @type
      when "resizeBothDimensionsHandle" then LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOMRIGHT
      when "moveHandle"                 then LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPLEFT
      when "resizeHorizontalHandle"     then LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_RIGHT
      when "resizeVerticalHandle"       then LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_BOTTOM
      # Affine transforms (§6 Phase 4B): the rotate handle takes the free TOP-RIGHT corner (the four
      # resize/move handles hold the other corners/edges). Corner-INTERNAL like the rest, so on an
      # island it is in-plane content painted into the island buffer — it warps with the content and
      # tracks the transformed corner for free (§4.6 halo model).
      when "rotateHandle"               then LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT

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
      @layoutSpec_cornerInternal_inset = @inset
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


  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

    aContext.useLogicalPixelsUntilRestore()
    widgetPosition = @position()
    aContext.translate widgetPosition.x, widgetPosition.y

    if @state == @STATE_NORMAL
      @handleWidgetRenderingHelper aContext, @color, Color.create 150, 150, 150
    if @state == @STATE_HIGHLIGHTED
      @handleWidgetRenderingHelper aContext, Color.WHITE, Color.create 200, 200, 255

    aContext.restore()

    # _drawHighlightOverlay is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @_drawHighlightOverlay aContext, al, at, w, h

  drawArrow: (context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown) ->
    context.beginPath()
    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x, 0.5 + leftArrowPoint.y + arrowPieceLeftUp.y
    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftDown.x, 0.5 + leftArrowPoint.y + arrowPieceLeftDown.y

    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y

    context.lineTo 0.5 + rightArrowPoint.x + arrowPieceRightUp.x, 0.5 + rightArrowPoint.y + arrowPieceRightUp.y
    context.moveTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y
    context.lineTo 0.5 + rightArrowPoint.x + arrowPieceRightDown.x, 0.5 + rightArrowPoint.y + arrowPieceRightDown.y

    context.closePath()
    context.stroke()

  # from Chrome code coverage - it doesn't seem tha this is used?
  # TODO check and remove if not needed
  drawHandle: (context) ->

    # horizontal arrow
    if @type is "resizeHorizontalHandle" or @type is "moveHandle"
      p0 = @bottomLeft().subtract(@position())
      p0 = p0.subtract new Point 0, Math.ceil(@height()/2)
      
      leftArrowPoint = p0.add new Point Math.ceil(@width()/15), 0

      rightArrowPoint = p0.add new Point @width() - Math.ceil(@width()/14), 0
      arrowPieceLeftUp = new Point Math.ceil(@width()/5),-Math.ceil(@height()/5)
      arrowPieceLeftDown = new Point Math.ceil(@width()/5),Math.ceil(@height()/5)
      arrowPieceRightUp = new Point -Math.ceil(@width()/5),-Math.ceil(@height()/5)
      arrowPieceRightDown = new Point -Math.ceil(@width()/5),Math.ceil(@height()/5)
      @drawArrow context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown

    # vertical arrow
    if @type is "resizeVerticalHandle" or @type is "moveHandle"
      p0 = @bottomCenter().subtract @position()
      
      leftArrowPoint = p0.add new Point 0, -Math.ceil(@height()/14)

      rightArrowPoint = p0.add new Point 0, -@height() + Math.ceil(@height()/15)
      arrowPieceLeftUp = new Point -Math.ceil(@width()/5), -Math.ceil(@height()/5)
      arrowPieceLeftDown = new Point Math.ceil(@width()/5), -Math.ceil(@height()/5)
      arrowPieceRightUp = new Point -Math.ceil(@width()/5), Math.ceil(@height()/5)
      arrowPieceRightDown = new Point Math.ceil(@width()/5), Math.ceil(@height()/5)
      @drawArrow context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown


    # Affine transforms (§6 Phase 4B): the rotate handle draws a small "knob" ring — visually distinct
    # from the resize arrows / striped triangle. The arc rasterises via SWCanvas (the tested backend),
    # whose transcendentals are the deterministic DetTrig (installed over Math.* before SWCanvas at
    # boot), so the ring is cross-engine byte-identical (the suite asserts exact pixels under WebKit).
    if @type is "rotateHandle"
      cx = @width() / 2
      cy = @height() / 2
      r  = Math.min(@width(), @height()) / 2 - 1
      context.beginPath()
      context.arc cx, cy, r, 0, 2 * Math.PI
      context.stroke()

    # draw the traditional "striped triangle" resizer
    if @type is "resizeBothDimensionsHandle"
      bottomLeft = @bottomLeft().subtract(@position())
      topRight = @topRight().subtract(@position())

      bottomLeftSweep = bottomLeft.copy()
      topRightSweep = topRight.copy()

      # draw the lines sweeping from long lines
      # down to the short ones at the corner
      for i in [0..@height()] by 6
        # bottomLeftSweep moves right
        bottomLeftSweep.x = bottomLeft.x + i
        # topRightSweep moves down
        topRightSweep.y = topRight.y + i
        context.beginPath()
        context.moveTo bottomLeftSweep.x, bottomLeftSweep.y
        context.lineTo topRightSweep.x, topRightSweep.y
        context.closePath()
        context.stroke()


  handleWidgetRenderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 0.5
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()
    context.strokeStyle = shadowColor.toString()
    context.translate 1,1
    @drawHandle context
    context.translate 1,0
    @drawHandle context
    context.restore()

    context.strokeStyle = color.toString()
    @drawHandle context


  

  # implement dummy methods in here
  # so the handle catches the clicks and
  # prevents the parent from doing anything.
  mouseClickLeft: ->
  # Affine transforms (§6 Phase 4B): end of a rotate gesture — clear the grab-start state so the next
  # grab re-captures its own reference angle. Harmless for the other handle types (fields stay nil).
  mouseUpLeft: ->
    @_rotateGrabStartRotationDegrees = nil
    @_rotateGrabStartPointerAngleDegrees = nil

  # same here, the handle doesn't want to propagate
  # anything, otherwise the handle on a button
  # will trigger the button when resizing.
  mouseDownLeft: (pos) ->
    return nil  unless @target
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
  # DetTrig.atan2 (not Math.atan2) keeps it cross-engine deterministic (§6 4B risk note).
  _pointerAngleToTargetAnchorDegrees: ->
    anchor = @target.rotationHalo_screenAnchor()
    p = world.hand.position()
    DetTrig.atan2(p.y - anchor.y, p.x - anchor.x) * 180 / Math.PI

  # Affine transforms (§6 Phase 4B): quantize a raw (float) rotation onto an integer-degree grid,
  # snapping to a cardinal angle (0/90/180/270) within ~3°. Integer quantization is the determinism
  # belt-and-braces over DetTrig.atan2 — any sub-ULP wobble rounds to the same integer, so the
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
        @target._setExtentDeferredSettle newExt, @
      when "moveHandle"
        @target._moveToDeferredSettle (newPos.subtract @inset), @
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
    @changed()
  
  mouseLeave: ->
    @state = @STATE_NORMAL
    @changed()

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
