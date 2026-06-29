class BasementOpenerWdgt extends IconicDesktopSystemLinkWdgt

  @augmentWith HighlightableMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.BLACK

  _acceptsDrops: true

  constructor: ->
    super "Basement", new GenericShortcutIconWdgt new BasementIconWdgt
    @target = world.basementWdgt
    @rawSetExtent new Point 75, 75

  # I am a desktop icon but the desktop positions me itself (bottom-right corner), so I do
  # NOT take part in the auto icon grid -- override of WidgetHolderWithCaptionWdgt (was the
  # `!(aWdgt instanceof BasementOpenerWdgt)` exclusion). (type-test-elimination campaign)
  participatesInIconGrid: ->
    false

  iHaveBeenAddedTo: (whereTo, beingDropped) ->
    super
    if whereTo == world and !@userMovedThisFromComputedPosition
      # fullRawMoveTo (NOT the public moveTo): iHaveBeenAddedTo is fired by the add
      # core INSIDE the add's settle, so a public setter here would re-enter the flush
      # guard and throw. The freefloating position is not changed by the outer settle,
      # so this is byte-equivalent to the old deferred moveTo.
      @fullRawMoveTo world.bottomRight().subtract @extent().add world.desktopSidesPadding

  _reactToBeingDropped: (whereIn) ->
    super
    if whereIn == world
      @userMovedThisFromComputedPosition = true


  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    if @target.isOrphan()
      @target.unCollapse()
      windowedBasementWdgt = new WindowWdgt nil, nil, @target
      world.add windowedBasementWdgt
      windowedBasementWdgt.rawSetExtent new Point 460, 400
      windowedBasementWdgt.fullRawMoveTo new Point 140, 90
      windowedBasementWdgt.rememberFractionalSituationInHoldingPanel()
      BasementInfoWdgt.createNextTo windowedBasementWdgt
    else
      # if the basement is not an orphan, then it's
      # visible somewhere and it's in a window
      @target.parent.spawnNextTo @
      @target.parent.rememberFractionalSituationInHoldingPanel()


  # Runs inside the drop's single settle, so add through the non-settling core.
  _reactToChildDropped: (droppedWidget) ->
    @target.scrollPanel.contents._addInPseudoRandomPositionNoSettle droppedWidget

  rejectsBeingDropped: ->
    true