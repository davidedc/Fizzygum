# not to be confused with the ActivePointerWdgt
# I am a resize / move handle that can be attached to any Widget
#
# A subclass that keeps every gesture of a handle but looks, sizes or sits differently supplies only
# what differs (the frame's own resize grip, FrameGripWdgt, is one):
#   createAppearance   -> new <Foo>Appearance @    (my look, and so the shape I react on)
#   _castMyShadow      -> …                        (the shadow I cast wherever I am added)
#   _cornerSide        -> <px>                     (the side of my square)
#   _cornerInsetFrom   (target) -> <Point>         (how far in from my target's edges I sit)
#   cornerFootprint    -> <px>                     (how much of my target's corner I take)

class HandleWdgt extends Widget

  target: undefined
  inset: undefined
  type: undefined
  # my carrier-owned corner knob — the layoutSpec I hand my parent at add() time,
  # and whose .inset I keep in step with @inset. LayoutSpec.coffee names this one
  # as the pattern's reference example.
  cornerSpec: undefined

  # Affine transforms (§6 Phase 4B): transient rotate-gesture reference frame — the island's rotation
  # and the pointer's angle about the anchor, both captured at grab-start (pressBegan), cleared at
  # the press's ending (pressEnded / pressCancelled). undefined at rest / for every non-rotate
  # handle, so nothing to serialize.
  _rotateGrabStartRotationDegrees: undefined
  _rotateGrabStartPointerAngleDegrees: undefined

  # MY POINTER STATE, two facts kept apart because they end apart: whether the pointer is over me
  # (hoverEntered / hoverExited), and whether a press that began on me still stands (pressBegan,
  # until its release or its cancel, the end of its drag, the pointer leaving me while nothing is
  # dragged, or my moving to another parent). My plate shows the press while it stands and the
  # hover otherwise (_plateFillForMyState), so its look after a gesture is a function of where the
  # gesture left the pointer and me, whatever order the events of a busy cycle arrive in: a handle
  # travels with its drag, so the pointer can leave and re-enter me under a press.
  _isHovered: false
  _isPressed: false

  # (No catchesPointerAt of my own: WHERE I react is my SHAPE, and the shape is my appearance's
  # business -- HandleAppearance answers my whole box for every type, the corner resizer's included,
  # the same way an icon button's appearance answers its whole box, and the way the frame grip's
  # glyph appearance answers its whole square.)

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
    # default inset; recomputed against the real target (_cornerInsetFrom) in _reactToBeingAdded when I
    # corner-attach
    @inset = new Point 2, 2
    super()
    @appearance = @createAppearance()

    @cornerSpec = new CornerInternalLayoutSpec @_anchorForType(), 0, @_cornerSide(), @inset

  # my look: the button's plate over my whole box with my type's glyph on it. A method, not a class
  # field, so the boot dependency finder sees the `new` edge (widget-authoring guidelines §5).
  createAppearance: -> new HandleAppearance @

  # THE SHADOW I CAST: my plate floats over whatever I stand on, so I cast the one desktop shadow
  # (visual-design-system §4.4) wherever I am added -- over the widget I resize as on the desktop.
  # Asked after every add (_reactToBeingAdded), because the add's own shadow management
  # (Widget._addNoSettle) leaves a widget added anywhere but the world without one; a hand that
  # carries me adds its lift after this. My appearance casts my plate's silhouette.
  _castMyShadow: ->
    theme = WorldWdgt.theme
    @__addShadow theme.desktopShadowOffset, theme.desktopShadowAlpha

  # the side of my square, which the corner pass sizes me to
  _cornerSide: -> WorldWdgt.theme.handleSize

  # HOW FAR IN FROM MY TARGET'S EDGES I SIT once attached to it: its padding, never less than 2.
  _cornerInsetFrom: (target) ->
    pad = Math.max (target.padding ? 2), 2
    new Point pad, pad

  # HOW MUCH OF MY TARGET'S BOTTOM-RIGHT CORNER I TAKE, along each axis: the length a viewport
  # running out to that corner stops its bars short of it by (ViewportWdgt._cornerReserveFor). A
  # plain handle answers its side.
  cornerFootprint: -> @_cornerSide()

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

  # I attach directly to a viewport (not its plane / inner contents) when added -- the
  # container add methods key off this instead of instanceof HandleWdgt. (type-test-elimination campaign)
  attachesToViewportDirectly: -> true

  detachesWhenDragged: ->
    if (@parent == world)
      return true
    else
      return false

  # HandleWdgts (and SliderButtonWdgts attached to a SliderWdgt) don't grab to their parent
  # when dragged, by default. The move handle could too, but stays uniform with the rest instead.
  grabsToParentWhenDragged: ->
    return false

  # I am CHROME: a drag that starts on me is the reshape/move/rotate gesture I exist for, and nothing
  # competes for it. The hand asks this of a press's ancestry (ActivePointerWdgt._touchPressArmsAtOnce)
  # to know whether a FINGER must press and hold before its drag means what a mouse drag means — on a
  # handle it never does (ruling I2: chrome drags need no hold on either device).
  ownsDragsStartingOnMe: -> true


  _reactToBeingAdded: (whereTo, beingDropped) ->
    # Adopt whoever I was just added to as my resize/move @target -- UNLESS I landed free-floating (on the
    # world or the hand: a naked desktop handle, or mid-detach), in which case I have no target. The spec was
    # already resolved by defaultLayoutSpecWhenAddedTo during the add, so @isFreeFloating() tells the two
    # apart. Recompute the corner inset against the real target now that I know it (the constructor only had
    # a default 2).
    unless @isFreeFloating()
      @target = whereTo
      @inset = @_cornerInsetFrom @target
      @cornerSpec.inset = @inset
    # a press does not survive a change of parent, whatever makes it: a lift also cancels my press,
    # but a drop or a builder moving me tells me nothing else
    @_setPointerState @_isHovered, false
    @_castMyShadow()
    @_moveInFrontOfSiblings()

  # WHETHER I SHOW. Two questions, both about my parent: does it own its own placement (a
  # host-owned widget is sized by its host, so a resizer on it would fight the host), and does it
  # have anything to size right now? The second is a capability asked via ?(), so only a parent
  # with an answer -- a frame, which has none while it is collapsed into its bar -- narrows it.
  # TODO rather than updating the visibility, we could
  # just make it "inactive" and by drawing it gray, which
  # would also look better (rather than a hole with
  # nothing)
  updateVisibility: ->
    showedBefore = @isVisible
    if @wouldShow()
      @show()
    else
      @hide()
    # I came or went, so the viewports keeping my parent's bottom-right corner free for me re-lay
    # what they keep clear of it: down my parent's corner chain (Widget.noteCornerChainChanged)
    @parent?.noteCornerChainChanged()  unless @isVisible is showedBefore

  # The two questions above, as a query: what my showing derives from, asked without asking whether I
  # show. A viewport that runs out to my parent's bottom-right corner keeps that corner free for me
  # by this answer (ViewportWdgt._resizerOverMyCorner) -- a visibility is never a layout input.
  wouldShow: ->
    @parent? and @parent.isFreeFloating() and (@parent.offersAResizeHandle?() ? true)


  # implement dummy methods in here
  # so the handle catches the clicks and
  # prevents the parent from doing anything.
  activated: ->
  # MY PRESS'S TWO ENDINGS (ActivePointerWdgt, the press's AUDIENCE) — the release, or the stroke
  # turning into something else: either way the press is over, and whether my plate then shows the
  # hover is the pointer's business (hoverEntered / hoverExited). Affine transforms (§6 Phase 4B): it
  # is also the end of a rotate gesture — clear the grab-start state so the next grab re-captures its
  # own reference angle. Harmless for the other handle types (fields stay undefined).
  pressEnded: ->
    @_setPointerState @_isHovered, false
    @_rotateGrabStartRotationDegrees = undefined
    @_rotateGrabStartPointerAngleDegrees = undefined

  pressCancelled: ->
    @_setPointerState @_isHovered, false
    @_rotateGrabStartRotationDegrees = undefined
    @_rotateGrabStartPointerAngleDegrees = undefined

  # same here, the handle doesn't want to propagate
  # anything, otherwise the handle on a button
  # will trigger the button when resizing: the press STOPS here.
  # The press shows on my plate whether or not I have a target.
  pressBegan: (pos) ->
    @_setPointerState @_isHovered, true
    return false  unless @target
    @target.bringToForeground()
    # Affine transforms (§6 Phase 4B): capture the rotate gesture's reference frame AT PRESS — the
    # island's current rotation plus the pointer's angle about the island's screen anchor. The drag
    # then rotates RELATIVE to this (no jump on grab). Captured here (hand is exactly at the press
    # point) rather than on the first drag sample, so the resulting angle is predictable from geometry.
    if @type is "rotateHandle"
      @_rotateGrabStartRotationDegrees = @target.rotationHalo_currentDegrees()
      @_rotateGrabStartPointerAngleDegrees = @_pointerAngleToTargetAnchorDegrees()
    false

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
      # re-capture if a drag ever arrives before pressBegan ran. Deferred-settle like the resize
      # family (a 'slot' island settles to nothing; a coupled one reflows once at end of cycle).
      when "rotateHandle"
        if !@_rotateGrabStartPointerAngleDegrees?
          @_rotateGrabStartRotationDegrees = @target.rotationHalo_currentDegrees()
          @_rotateGrabStartPointerAngleDegrees = @_pointerAngleToTargetAnchorDegrees()
        rawDegrees = @_rotateGrabStartRotationDegrees + (@_pointerAngleToTargetAnchorDegrees() - @_rotateGrabStartPointerAngleDegrees)
        @target.rotationHalo_apply @_quantizeRotationDegrees rawDegrees

  
  # HandleWdgt events:
  hoverEntered: ->
    @_setPointerState true, @_isPressed

  # The pointer leaving me ends my press unless it drags me: a drag carries me along, and the pointer
  # may outrun me while it does, but a press that left without dragging is abandoned (the button's
  # rule). A finger's stroke ends with this too, once its press and drag are cleared
  # (ActivePointerWdgt._dissolveHoverStateOfTouchStroke), which ends a press its hold took over.
  hoverExited: ->
    @_setPointerState false, @_isPressed and world.hand.isThisPointerDraggingSomething()

  # the drag that began on me is over, wherever the pointer is: so is my press
  endOfNonFloatDrag: ->
    @_setPointerState @_isHovered, false
    # RE-RECORD request (the F6 family, auto-bookkeeping arc): the drag resized/moved my target by
    # user intent, so its fractional bookkeeping is stale. Asked here, at the end of the DRAG — which
    # every drag of mine reaches, however its release lands or if the stroke is aborted — and not at
    # my press's ending, which a press that never dragged reaches too. Deferred to the world's
    # post-flush drain (my writes are deferred-settle, so the settled geometry is the gesture's
    # outcome) -- without it, a handle-resized stretch child snaps back to its pre-gesture
    # proportions on the next holder reflow.
    world.pendingFractionalReRecords.add @target  if @target?

  # my pointer state, and a repaint of me when it changes
  _setPointerState: (hovered, pressed) ->
    return if hovered is @_isHovered and pressed is @_isPressed
    @_isHovered = hovered
    @_isPressed = pressed
    @_changed()

  # my plate's fill and border for the pointer state I am in now, which my appearance reads as it
  # paints: the press look while a press stands, else the hover look while the pointer is over me,
  # else the rest look
  _plateFillForMyState: ->
    theme = WorldWdgt.theme
    if @_isPressed
      theme.handlePlatePressFill
    else if @_isHovered
      theme.handlePlateHoverFill
    else
      theme.handlePlateFill

  _plateStrokeForMyState: ->
    theme = WorldWdgt.theme
    if @_isPressed then theme.handlePlatePressStroke else theme.handlePlateStroke

  # Menu action ("Attach" -> the "target" chooser): corner-attach this handle to the chosen widget. A discrete
  # user action, so it goes through the public self-settling add() -- the corner placement comes from default
  # LayoutSpecWhenAddedTo and @target is adopted in _reactToBeingAdded (the destination IS the new target). add()
  # also unlinks me from any previous parent (e.g. the world, if I had been detached). Kept on this name + arg
  # position because the "Attach" chooser dispatches it by string with the chosen target as the 3rd argument.
  makeHandleSolidWithParentWidget: (ignored, ignored2, widgetAttachedTo) ->
    widgetAttachedTo?.add @

    
  # HandleWdgt menu:
  attach: ->
    choices = world.plausibleTargetAndDestinationWidgets @
    menu = new MenuWdgt @, target: @, title: "target"
    if choices.length > 0
      # each row names its widget (CommandPanelWdgt.rowLabelsNaming)
      labels = CommandPanelWdgt.rowLabelsNaming choices
      choices.forEach (each, i) =>
        menu.addMenuItem labels[i], @, 'makeHandleSolidWithParentWidget', arg1: each, representsAWidget: true
    else
      # Not pre-computed: finding eligible widgets is costly, so the list is calculated lazily
      # here, on menu-open; if none are found, show a message instead of hiding the entry.
      menu = new MenuWdgt @, target: @, title: "no widgets to attach to", titleIsAMessage: true
    menu.popUpAtHand() if choices.length
