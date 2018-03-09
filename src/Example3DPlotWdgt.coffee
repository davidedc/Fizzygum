# REQUIRES Point3D

class Example3DPlotWdgt extends Widget


  vertices: nil
  quads: nil
  currentAngle: nil
  grid: nil
  grids: nil
  previousMousePoint: nil
  autoRotate: true

  constructor: ->
    super()
    @defaultRejectDrags = true
    @isLockingToPanels = true

    @fps = 0
    world.addSteppingMorph @

    @setColor new Color 255, 125, 125
    @setExtent new Point 200, 200


    @vertices = []

    @grids = []

    XYPlaneGrid = new Grid3D 21, 21, []
    graphGrid = new Grid3D 21, 21, []

    for i in [-1..1] by 0.1
      for j in [-1..1] by 0.1
        @vertices.push new Point3D i, j, 0
        XYPlaneGrid.vertexIndexes.push @vertices.length - 1
        @vertices.push new Point3D i, j, (Math.sin(i*3) + Math.cos(j*3))/2
        graphGrid.vertexIndexes.push @vertices.length - 1

    @grids.push XYPlaneGrid
    @grids.push graphGrid

    @edges = []

    @quads = []
    
    @currentAngle = 0

  colloquialName: ->
    "3D plot"

  step: ->
    if @autoRotate
      @currentAngle++
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
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil

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
      aContext.scale pixelRatio, pixelRatio

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
    debugger
    if world.hand.draggingSomething() then return
    if mouseButton == 'left'
        if @previousMousePoint?
          @currentAngle +=  @previousMousePoint.x - pos.x
        @previousMousePoint = pos

  mouseDownLeft: (pos) ->
    super
    @autoRotate = false

  mouseUpLeft: ->
    @autoRotate = true

  mouseLeave: ->
    @autoRotate = true

  renderingHelper: (context, color, appliedShadow) ->


    height = @height()
    width = @width()


    # clean the background

    if appliedShadow?
      context.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha
      context.fillStyle = (new Color 80, 80, 80).toString()
      context.fillRect 0, 0, width, height
      # let's avoid paint 3d stuff twice because
      # of the shadow
      return


    context.fillStyle = (new Color 242,242,242).toString()
    context.fillRect 0, 0, width, height


    points = []

    context.strokeStyle = 'black'
    originalAlpha = context.globalAlpha
    context.globalAlpha = 0.6

    for eachVertex in @vertices
      newPoint = eachVertex.rotateX(90).rotateY(@currentAngle).translateXYZ(0,0.5,0).project(width, height, 528, 7)
      newPoint.y -= height * 1/6
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

    for k in [0...@grids.length]
      eachGrid = @grids[k]

      context.beginPath()

      # draw the "horizontals" in the grid (each point x,y with x+1,y)
      for i in [0...eachGrid.width-1]
        for j in [0...eachGrid.height]
          if eachGrid.vertexIndexes[i+1+j*eachGrid.width]?
            context.moveTo points[eachGrid.vertexIndexes[i+j*eachGrid.width]].x, points[eachGrid.vertexIndexes[i+j*eachGrid.width]].y
            context.lineTo points[eachGrid.vertexIndexes[(i+1)+j*eachGrid.width]].x, points[eachGrid.vertexIndexes[(i+1)+j*eachGrid.width]].y

      # draw the "verticals" in the grid (each point x,y with x,y+1)
      for i in [0...eachGrid.width]
        for j in [0...eachGrid.height-1]
          if eachGrid.vertexIndexes[i+(j+1)*eachGrid.width]?
            context.moveTo points[eachGrid.vertexIndexes[i+j*eachGrid.width]].x, points[eachGrid.vertexIndexes[i+j*eachGrid.width]].y
            context.lineTo points[eachGrid.vertexIndexes[i+(j+1)*eachGrid.width]].x, points[eachGrid.vertexIndexes[i+(j+1)*eachGrid.width]].y
            context.closePath()

      context.closePath()

      if k==0
        context.strokeStyle = 'grey'
      else
        context.strokeStyle = 'black'
      context.stroke()

    context.globalAlpha = originalAlpha

