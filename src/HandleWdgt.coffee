# not to be confused with the ActivePointerWdgt
# I am a resize / move handle that can be attached to any Widget

class HandleWdgt extends Widget

  target: nil
  inset: nil
  type: nil

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1

  # Capability query (replaces `widgetStartingTheChange instanceof HandleWdgt` in Widget's raw move/resize
  # paths): a geometry change INITIATED by a handle makes the moved/resized child remember its fractional
  # position/extent in its holding panel. True here only; dispatched via ?() (nothing on Widget).
  # (type-test-elimination campaign)
  changeShouldRememberFractionalGeometry: ->
    true

  # I am NOT given a target to attach to, and I do NOT attach myself. Like every other widget I am built
  # here and ATTACHED by whoever adds me: `someWidget.add handle` (self-settling, the standard discrete
  # attach) or `someWidget._addNoSettle handle` (deferred, inside a builder's own settle). defaultLayoutSpec
  # WhenAddedTo (below) makes me corner-attach to whatever real widget I am added to -- so the caller writes
  # the uniform `target.add handle`, no layoutSpec and no target-passed-twice. (end-of-cycle CONVERT: a
  # standalone attach now self-settles -- placed by its OWN flush -- instead of the old off-settle constructor
  # side-effect that rode the shared per-frame end-of-cycle flush. @target + the padding-aware @inset are now
  # set in iHaveBeenAddedTo, once the destination -- which IS the target -- is known.)
  constructor: (@type = "resizeBothDimensionsHandle") ->
    # default inset; recomputed against the real target's padding in iHaveBeenAddedTo when I corner-attach
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


  iHaveBeenAddedTo: (whereTo, beingDropped) ->
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
    @moveInFrontOfSiblings()

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

    # paintHighlight is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @paintHighlight aContext, al, at, w, h

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
  mouseUpLeft: ->
  
  # same here, the handle doesn't want to propagate
  # anything, otherwise the handle on a button
  # will trigger the button when resizing.
  mouseDownLeft: (pos) ->
    return nil  unless @target
    @target.bringToForeground()

  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->
    newPos = pos.subtract nonFloatDragPositionWithinWdgtAtStart
    switch @type
      # 1. all these changes applied to the target are all deferred
      # 2. the position of this handle will be changed when the
      # _reLayout method of the parent of the handle will be called
      # ...i.e. *after* the parent has re-layouted (in the deferred layout phase).
      when "resizeBothDimensionsHandle"
        newExt = newPos.add(@extent().add(@inset)).subtract @target.position()
        @target.setExtent newExt, @
      when "moveHandle"
        @target.fullMoveTo (newPos.subtract @inset), @
      when "resizeHorizontalHandle"
        newWidth = newPos.x + @extent().x + @inset.x - @target.left()
        @target.setWidth newWidth
      when "resizeVerticalHandle"
        newHeight = newPos.y + @extent().y + @inset.y - @target.top()
        @target.setHeight newHeight
  
  
  # HandleWdgt events:
  mouseEnter: ->
    #console.log "<<<<<< handle mousenter"
    @state = @STATE_HIGHLIGHTED
    @changed()
  
  mouseLeave: ->
    #console.log "<<<<<< handle mouseleave"
    @state = @STATE_NORMAL
    @changed()

  # Menu action ("attach..." -> choose target): corner-attach this handle to the chosen widget. A discrete
  # user action, so it goes through the public self-settling add() -- the corner placement comes from default
  # LayoutSpecWhenAddedTo and @target is adopted in iHaveBeenAddedTo (the destination IS the new target). add()
  # also unlinks me from any previous parent (e.g. the world, if I had been detached). Kept on this name + arg
  # position because the "attach..." menu dispatches it by string with the chosen target as the 3rd argument.
  makeHandleSolidWithParentWidget: (ignored, ignored2, widgetAttachedTo) ->
    widgetAttachedTo?.add @

    
  # HandleWdgt menu:
  attach: ->
    choices = world.plausibleTargetAndDestinationWidgets @
    menu = new MenuWdgt @, false, @, true, true, "choose target:"
    if choices.length > 0
      choices.forEach (each) =>
        menu.addMenuItem (each.toString().replace "Wdgt", "").slice(0, 50) + " ➜", true, @, 'makeHandleSolidWithParentWidget', nil, nil, nil, nil, nil, each, nil, true
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible widgets to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # widgets then show some kind of message.
      menu = new MenuWdgt @, false, @, true, true, "no widgets to attach to"
    menu.popUpAtHand() if choices.length
