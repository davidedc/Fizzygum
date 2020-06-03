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
    @defaultRejectDrags = true
    @isLockingToPanels = true

    @fps = 0
    world.steppingWdgts.add @

    @setColor new Color 255, 125, 125
    @rawSetExtent new Point 200, 200



    @edges = []

    @quads = []
    
    @currentAngle = 0

    @step()

  colloquialName: ->
    "3D plot"

  setParameter: (parameterValue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
    @parameterValue = parameterValue
    @calculateNewPlotValues()

  reactToTargetConnection: ->
    @calculateNewPlotValues()

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

  justDropped: (whereIn) ->
    super
    if (whereIn instanceof SimpleVerticalStackPanelWdgt) and !(whereIn instanceof WindowWdgt)
      @constrainToRatio()

  holderWindowJustDropped: (whereIn) ->
    if (whereIn instanceof SimpleVerticalStackPanelWdgt) and !(whereIn instanceof WindowWdgt)
      @constrainToRatio()

  constrainToRatio: ->
    if @layoutSpecDetails?
      @ratio = @width() / @height()
      @layoutSpecDetails.canSetHeightFreely = false
      # force a resize, so the slide and the window
      # it's in will take the right ratio, and hence
      # the content will take the whole window it's in.
      # Note that the height of 0 here is ignored since
      # "rawSetWidthSizeHeightAccordingly" will
      # calculate the height.
      @rawSetExtent new Point @width(), 0

  holderWindowJustBeenGrabbed: (whereFrom) ->
    if whereFrom instanceof SimpleVerticalStackPanelWdgt
      @freeFromRatioConstraints()

  justBeenGrabbed: (whereFrom) ->
    if whereFrom instanceof SimpleVerticalStackPanelWdgt
      @freeFromRatioConstraints()

  freeFromRatioConstraints: ->
    if @layoutSpecDetails?
      @layoutSpecDetails.canSetHeightFreely = true
      @ratio = nil

      availableHeight = world.height() - 20
      if @parent.height() > availableHeight
        @parent.rawSetExtent (new Point Math.min((@width()/@height()) * availableHeight, world.width()), availableHeight).round()
        @parent.fullRawMoveTo world.hand.position().subtract @parent.extent().floorDivideBy 2
        @parent.fullRawMoveWithin world

  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    if @ratio?
      @rawSetExtent new Point newWidth, Math.round(newWidth / @ratio)
    else
      super
  # -----------------------------------------------------------------

  step: ->
    if @autoRotate
      @currentAngle++
    @calculateNewPlotValues()

  
  # TODO seems like in a plot and a grid like these
  # one could really reuse past vertices and just modify them
  # and avoid aaaaaall these constructions every time
  calculateNewPlotValues: ->
    @vertices = []

    @graphGrid = new Grid3D 21, 21, []

    for i in [-1..1] by 0.1
      for j in [-1..1] by 0.1
        @vertices.push new Point3D i, j, (Math.sin(i*@parameterValue/30)) + (Math.sin(i*3 + @currentAngle/160) + Math.cos(j*3 + @currentAngle/160))/2
        @graphGrid.vertexIndexes.push @vertices.length - 1


    @planeGrid = new PlaneGrid3D 21, 21

    for i in [-1..1] by 0.1
      @vertices.push new Point3D i, -1, 0
      @planeGrid.vertexIndexes.push @vertices.length - 1
      @vertices.push new Point3D i, 1, 0
      @planeGrid.vertexIndexes.push @vertices.length - 1

    for j in [-1..1] by 0.1
      @vertices.push new Point3D -1, j, 0
      @planeGrid.vertexIndexes.push @vertices.length - 1
      @vertices.push new Point3D 1, j, 0
      @planeGrid.vertexIndexes.push @vertices.length - 1


    @changed()

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
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

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @backgroundTransparency

    # paintRectangle here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called before the scaling.
    @paintRectangle aContext, al, at, w, h, @backgroundColor
    aContext.scale ceilPixelRatio, ceilPixelRatio

    morphPosition = @position()
    aContext.translate morphPosition.x, morphPosition.y

    @renderingHelper aContext, new Color(255, 255, 255), appliedShadow

    aContext.restore()

    # paintHighlight here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called outside the effect of the scaling
    # (after the restore).
    @paintHighlight aContext, al, at, w, h

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

  renderingHelper: (context, color, appliedShadow) ->

    height = @height()
    width = @width()

    # clean the background
    if appliedShadow?
      context.globalAlpha = appliedShadow.alpha * @alpha
      context.fillStyle = (new Color 80, 80, 80).toString()
      context.fillRect 0, 0, width, height
      # let's avoid paint 3d stuff twice because
      # of the shadow
      return

    context.fillStyle = WorldMorph.preferencesAndSettings.editableItemBackgroundColor.toString()
    context.fillRect 0, 0, width, height


    squareDim = Math.min width, height
    context.translate (width-squareDim)/2, (height-squareDim)/2

    points = []

    context.strokeStyle = 'black'
    originalAlpha = context.globalAlpha
    context.globalAlpha = 0.6

    context.scale squareDim/300, squareDim/300

    for eachVertex in @vertices
      newPoint = eachVertex.rotateX(90).rotateY(@currentAngle/2).translateXYZ(0,0.5,0).project(300, 300, 220, 3)
      newPoint.y -= squareDim * 1/6
      points.push newPoint

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

    context.strokeStyle = 'black'
    context.stroke()



    context.beginPath()

    for i in [0...@planeGrid.width-1]
      context.moveTo points[@planeGrid.vertexIndexes[2*i]].x, points[@planeGrid.vertexIndexes[2*i]].y
      context.lineTo points[@planeGrid.vertexIndexes[2*i+1]].x, points[@planeGrid.vertexIndexes[2*i+1]].y

    for i in [@planeGrid.width-1...@planeGrid.width+@planeGrid.height]
      context.moveTo points[@planeGrid.vertexIndexes[2*i]].x, points[@planeGrid.vertexIndexes[2*i]].y
      context.lineTo points[@planeGrid.vertexIndexes[2*i+1]].x, points[@planeGrid.vertexIndexes[2*i+1]].y

    context.closePath()

    context.strokeStyle = 'grey'
    context.stroke()


    context.globalAlpha = originalAlpha

