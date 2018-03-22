# REQUIRES HighlightableMixin

class BasementOpenerWdgt extends IconicDesktopSystemLinkWdgt

  @augmentWith HighlightableMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 0, 0, 0

  _acceptsDrops: true

  constructor: ->
    super "Basement", new GenericShortcutIconWdgt new BasementIconWdgt()
    @target = world.basementWdgt
    @rawSetExtent new Point 75, 75

  iHaveBeenAddedTo: (whereTo, beingDropped) ->
    super
    if whereTo == world and !@userMovedThisFromComputedPosition
      @fullMoveTo world.bottomRight().subtract @extent().add world.desktopSidesPadding

  justDropped: (whereIn) ->
    super
    if whereIn == world
      @userMovedThisFromComputedPosition = true


  mouseDoubleClick: ->

    if @target.isOrphan()
      @target.unCollapse()
      windowedBasementWdgt = new WindowWdgt nil, nil, @target
      world.add windowedBasementWdgt
      windowedBasementWdgt.rawSetExtent new Point 460, 400
      windowedBasementWdgt.fullRawMoveTo new Point 140, 90
      windowedBasementWdgt.rememberFractionalSituationInHoldingPanel()
      menusHelper.createBasementOneOffInfoWindowNextTo windowedBasementWdgt
    else
      # if the basement is not an orphan, then it's
      # visible somewhere and it's in a window
      @target.parent.spawnNextTo @
      @target.parent.rememberFractionalSituationInHoldingPanel()


  reactToDropOf: (droppedWidget) ->
    debugger
    @target.scrollPanel.contents.addInPseudoRandomPosition droppedWidget

  rejectsBeingDropped: ->
    true