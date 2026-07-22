class BinOpenerWdgt extends IconicDesktopSystemLinkWdgt

  @augmentWith HighlightableMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.BLACK

  _acceptsDrops: true

  constructor: ->
    super "Bin", new GenericShortcutIconWdgt new BinIconWdgt
    @target = world.binWdgt

  # I am a desktop icon but the desktop positions me itself (bottom-right corner), so I do
  # NOT take part in the auto icon grid -- override of WidgetHolderWithCaptionWdgt (was the
  # `!(aWdgt instanceof BinOpenerWdgt)` exclusion). (type-test-elimination campaign)
  participatesInIconGrid: ->
    false

  _reactToBeingAdded: (whereTo, beingDropped) ->
    super
    if whereTo == world and !@userMovedThisFromComputedPosition
      # _applyMoveTo (NOT the public moveTo): _reactToBeingAdded is fired by the add
      # core INSIDE the add's settle, so a public setter here would re-enter the flush
      # guard and throw. The freefloating position is not changed by the outer settle,
      # so this is byte-equivalent to the old deferred moveTo.
      @_applyMoveTo world.bottomRight().subtract @extent().add world.desktopSidesPadding

  _reactToBeingDropped: (whereIn) ->
    super
    if whereIn == world
      @userMovedThisFromComputedPosition = true


  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    if @target.isOrphan()
      @target.unCollapse()
      windowedBinWdgt = new FrameWdgt @target
      world.add windowedBinWdgt
      windowedBinWdgt._applyBounds (new Point 140, 90), new Point 460, 400
      windowedBinWdgt._rememberFractionalSituationInHoldingPanel()
      InfoDocs.createNextTo "bin", windowedBinWdgt
    else
      # if the bin is not an orphan, then it's
      # visible somewhere and it's in a window
      @target.parent.spawnNextTo @
      @target.parent._rememberFractionalSituationInHoldingPanel()

    # references can die while the bin is closed (and doGC classifies chains through the
    # bin correctly only while it is ON-screen), so the view is refreshed at every open.
    @target.refreshLostOnlyView()


  # Runs inside the drop's single settle, so add through the non-settling core.
  _reactToChildDropped: (droppedWidget) ->
    @target.scrollPanel.contents._addInPseudoRandomPositionNoSettle droppedWidget

  wantsToBeDropped: ->
    false