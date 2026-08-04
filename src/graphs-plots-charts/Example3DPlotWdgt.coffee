class Example3DPlotWdgt extends Widget


  vertices: nil
  quads: nil
  currentAngle: nil
  planeGrid: nil
  graphGrid: nil
  previousMousePoint: nil
  autoRotate: true
  ratio: nil

  # a parameter for a slider to control,
  # so to show interactive graph/plot
  parameterValue: 0

  constructor: ->
    super()
    @appearance = new Example3DPlotAppearance @
    @defaultRejectDrags = true
    @isLockingToPanels = true

    @fps = 0
    world.steppingWdgts.add @

    @setColor Color.create 255, 125, 125
    @_applyExtent new Point 200, 200



    @edges = []

    @quads = []
    
    @currentAngle = 0

    @step()

  colloquialName: ->
    "3D plot"

  setParameter: (parameterValue, ignored) ->
    @parameterValue = parameterValue
    @_calculateNewPlotValues()

  reactToTargetConnection: ->
    @_calculateNewPlotValues()

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    if !menuEntriesStrings?
      menuEntriesStrings = []
      functionNamesStrings = []
    menuEntriesStrings.push "param"
    functionNamesStrings.push "setParameter"

    if @addShapeSpecificNumericalSetters?
      [menuEntriesStrings, functionNamesStrings] = @addShapeSpecificNumericalSetters menuEntriesStrings, functionNamesStrings

    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  # ---------------------------------------------------------------
  # Outside of a stack, the plot can take any dimension.
  # When IN a stack, then we
  # want the content to force the ratio of the window so that the
  # plot grows/shrinks in both dimensions harmoniously as the
  # page is widened/narrowed.
  # The stack/window checks below ask the container capabilities
  # imposesRatioConstraintOnDroppedChildren / releasesRatioConstraintOnGrabbedChildren
  # rather than testing its class. (type-test-elimination campaign)
  # Hand-written, NOT KeepsRatioWhenInVerticalStackMixin -- deliberately: this is
  # the PINNED @ratio variant (captured at _constrainToRatio time, super-fallback
  # when unpinned, vs the mixin's stateless current-aspect sizing), and it
  # additionally wires the DIRECT drop/grab hooks (_reactToBeingDropped/
  # _reactToBeingGrabbed) alongside the holder-frame pair. Augmenting would inject
  # six members and have every one of them immediately shadowed by this class body
  # -- legal (class body wins over injections) but a misleading read.

  _reactToBeingDropped: (whereIn) ->
    super
    if whereIn?.imposesRatioConstraintOnDroppedChildren?()
      @_constrainToRatio()

  _reactToHolderFrameDropped: (whereIn) ->
    if whereIn?.imposesRatioConstraintOnDroppedChildren?()
      @_constrainToRatio()

  _constrainToRatio: ->
    if @_stackElementSpec?
      @ratio = @width() / @height()
      @_stackElementSpec.canSetHeightFreely = false
      # force a resize, so the slide and the window
      # it's in will take the right ratio, and hence
      # the content will take the whole window it's in.
      # Note that the height of 0 here is ignored since
      # "_setWidthSizeHeightAccordingly" will
      # calculate the height.
      @_applyExtent new Point @width(), 0

  _reactToHolderFrameGrabbed: (whereFrom) ->
    if whereFrom?.releasesRatioConstraintOnGrabbedChildren?()
      @_freeFromRatioConstraints()

  _reactToBeingGrabbed: (whereFrom) ->
    if whereFrom?.releasesRatioConstraintOnGrabbedChildren?()
      @_freeFromRatioConstraints()

  _freeFromRatioConstraints: ->
    if @_stackElementSpec?
      @_stackElementSpec.canSetHeightFreely = true
      @ratio = nil

      availableHeight = world.height() - 20
      if @parent.height() > availableHeight
        @parent._applyExtent (new Point Math.min((@width()/@height()) * availableHeight, world.width()), availableHeight).round()
        @parent._applyMoveTo world.hand.position().subtract @parent.extent().floorDivideBy 2
        @parent._moveWithin world

  _setWidthSizeHeightAccordingly: (newWidth) ->
    if @ratio?
      @_applyExtent new Point newWidth, Math.round(newWidth / @ratio)
      @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.
    else
      super

  # §4.1 pure measure (sizing-model unification U3-B): mirrors _setWidthSizeHeightAccordingly
  # above -- ratio-locked while a ratio is pinned, base width-invariant otherwise. No mutation,
  # no seam.
  preferredExtentForWidth: (availW) ->
    if @ratio?
      new Point availW, Math.round(availW / @ratio)
    else
      super
  # -----------------------------------------------------------------

  step: ->
    # freeze the auto-rotation under SystemTest replay so the mesh renders a fixed frame -- mirrors
    # AnalogClockWdgt._calculateHandsAngles / GraphsPlotsChartsWdgt. (Inlined, not shared: unlike the 2D
    # plots I extend Widget directly, not GraphsPlotsChartsWdgt -- I keep my own paint/anim copy.)
    frozenForReplay = Automator? and Automator.animationsPacingControl and Automator.state == Automator.PLAYING
    if @autoRotate and not frozenForReplay
      @currentAngle++
    @_calculateNewPlotValues()

  
  # TODO seems like in a plot and a grid like these
  # one could really reuse past vertices and just modify them
  # and avoid aaaaaall these constructions every time
  _calculateNewPlotValues: ->
    @vertices = []

    graphGridIndexes = []
    for i in [-1..1] by 0.1
      for j in [-1..1] by 0.1
        @vertices.push new Point3D i, j, (Math.sin(i*@parameterValue/30)) + (Math.sin(i*3 + @currentAngle/160) + Math.cos(j*3 + @currentAngle/160))/2
        graphGridIndexes.push @vertices.length - 1
    @graphGrid = new Grid3D 21, 21, graphGridIndexes


    planeGridIndexes = []
    for i in [-1..1] by 0.1
      @vertices.push new Point3D i, -1, 0
      planeGridIndexes.push @vertices.length - 1
      @vertices.push new Point3D i, 1, 0
      planeGridIndexes.push @vertices.length - 1

    for j in [-1..1] by 0.1
      @vertices.push new Point3D -1, j, 0
      planeGridIndexes.push @vertices.length - 1
      @vertices.push new Point3D 1, j, 0
      planeGridIndexes.push @vertices.length - 1
    @planeGrid = new PlaneGrid3D 21, 21, planeGridIndexes


    @_changed()

  mouseMove: (pos, mouseButton) ->
    if world.hand.isThisPointerDraggingSomething() then return
    if mouseButton == 'left'
        if @previousMousePoint?
          @currentAngle +=  @previousMousePoint.x - pos.x
        @previousMousePoint = pos

  mouseDownLeft: (pos) ->
    @autoRotate = false
    @bringToForeground()

  mouseUpLeft: ->
    @autoRotate = true

  mouseLeave: ->
    @autoRotate = true

  # the drawing tail: the PUBLIC per-plot body Example3DPlotAppearance dispatches to
  # (the drawLayoutChrome / drawPlot family precedent)
  drawPlot: (context, color, appliedShadow) ->

    height = @height()
    width = @width()

    # clean the background
    if appliedShadow?
      context.globalAlpha = appliedShadow.alpha * @alpha
      # shadow-pass paint contract (Widget.coffee "How the shadow painting works"):
      # the plot box's shadow is BLACK, like every other caster's
      context.fillStyle = Color.BLACK.toString()
      context.fillRect 0, 0, width, height
      # let's avoid paint 3d stuff twice because
      # of the shadow
      return

    context.fillStyle = WorldWdgt.preferencesAndSettings.editableItemBackgroundColor.toString()
    context.fillRect 0, 0, width, height


    squareDim = Math.min width, height
    context.translate (width-squareDim)/2, (height-squareDim)/2

    points = []

    context.strokeStyle = Color.BLACK.toString()
    originalAlpha = context.globalAlpha
    context.globalAlpha = 0.6

    context.scale squareDim/300, squareDim/300

    for eachVertex in @vertices
      projected = eachVertex.rotateX(90).rotateY(@currentAngle/2).translateXYZ(0,0.5,0).project(300, 300, 220, 3)
      points.push new Point projected.x, projected.y - squareDim * 1/6

    for eachQuad in @quads
      context.beginPath()
      context.moveTo points[eachQuad[0]].x, points[eachQuad[0]].y
      context.lineTo points[eachQuad[1]].x, points[eachQuad[1]].y
      context.lineTo points[eachQuad[2]].x, points[eachQuad[2]].y
      context.lineTo points[eachQuad[3]].x, points[eachQuad[3]].y
      context.closePath()
      context.stroke()

    for eachEdge in @edges
      context.beginPath()
      context.moveTo points[eachEdge[0]].x, points[eachEdge[0]].y
      context.lineTo points[eachEdge[1]].x, points[eachEdge[1]].y
      context.closePath()
      context.stroke()


    context.beginPath()

    # draw the "horizontals" in the grid (each point x,y with x+1,y)
    for i in [0...@graphGrid.width-1]
      for j in [0...@graphGrid.height]
        if i+1+j*@graphGrid.width < @graphGrid.vertexIndexes.length
          context.moveTo points[@graphGrid.vertexIndexes[i+j*@graphGrid.width]].x, points[@graphGrid.vertexIndexes[i+j*@graphGrid.width]].y
          context.lineTo points[@graphGrid.vertexIndexes[(i+1)+j*@graphGrid.width]].x, points[@graphGrid.vertexIndexes[(i+1)+j*@graphGrid.width]].y

    # draw the "verticals" in the grid (each point x,y with x,y+1)
    for i in [0...@graphGrid.width]
      for j in [0...@graphGrid.height-1]
        if i+(j+1)*@graphGrid.width < @graphGrid.vertexIndexes.length
          context.moveTo points[@graphGrid.vertexIndexes[i+j*@graphGrid.width]].x, points[@graphGrid.vertexIndexes[i+j*@graphGrid.width]].y
          context.lineTo points[@graphGrid.vertexIndexes[i+(j+1)*@graphGrid.width]].x, points[@graphGrid.vertexIndexes[i+(j+1)*@graphGrid.width]].y

    context.closePath()

    context.strokeStyle = Color.BLACK.toString()
    context.stroke()



    context.beginPath()

    for i in [0...@planeGrid.width-1]
      context.moveTo points[@planeGrid.vertexIndexes[2*i]].x, points[@planeGrid.vertexIndexes[2*i]].y
      context.lineTo points[@planeGrid.vertexIndexes[2*i+1]].x, points[@planeGrid.vertexIndexes[2*i+1]].y

    for i in [@planeGrid.width-1...@planeGrid.width+@planeGrid.height]
      context.moveTo points[@planeGrid.vertexIndexes[2*i]].x, points[@planeGrid.vertexIndexes[2*i]].y
      context.lineTo points[@planeGrid.vertexIndexes[2*i+1]].x, points[@planeGrid.vertexIndexes[2*i+1]].y

    context.closePath()

    context.strokeStyle = Color.GRAY.toString()
    context.stroke()


    context.globalAlpha = originalAlpha

