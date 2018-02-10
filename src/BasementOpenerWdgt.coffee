# BasementOpenerWdgt //////////////////////////////////////////////////////

# REQUIRES HighlightableMixin

class BasementOpenerWdgt extends WidgetHolderWithCaption

  @augmentWith HighlightableMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 0, 0, 0

  _acceptsDrops: true

  constructor: ->
    super "Basement", new GenericShortcutIconWdgt new BasementIconWdgt()
    @target = world.basementWdgt
    @setExtent new Point 75, 75

  imBeingAddedTo: (whereTo) ->
    if whereTo == world and !@userMovedThisFromComputedPosition
      @fullMoveTo world.bottomRight().subtract @extent().add world.desktopSidesPadding

  justDropped: (whereIn) ->
    super
    if whereIn == world
      @userMovedThisFromComputedPosition = true


  mouseClickLeft: ->

    if @target.isOrphan()
      @target.unCollapse()
      windowedBasementWdgt = new WindowWdgt nil, nil, @target
      windowedBasementWdgt.setExtent new Point 460, 400
      windowedBasementWdgt.spawnNextTo @
    else
      # if the basement is not an orphan, then it's
      # visible somewhere and it's in a window
      @target.parent.spawnNextTo @


  reactToDropOf: (droppedWidget) ->
    debugger
    @target.scrollPanel.contents.addInPseudoRandomPosition droppedWidget

  rejectsBeingDropped: ->
    true