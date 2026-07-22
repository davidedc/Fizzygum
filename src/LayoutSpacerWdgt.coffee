# this file is excluded from the fizzygum homepage build

class LayoutSpacerWdgt extends LayoutChromeWdgt

  constructor: (spacerWeight = 1) ->
    super()
    @setColor Color.BLACK
    @setMinAndMaxBoundsAndSpreadability (new Point 0,0) , (new Point 1,1), spacerWeight * LayoutSpec.SPREADABILITY_SPACERS
    @minimumExtent = new Point 0,0

  makeSpacersTransparent: ->
    if !@thisSpacerIsTransparent
      @thisSpacerIsTransparent = true
      @_changed()
    super

  makeSpacersOpaque: ->
    if @thisSpacerIsTransparent
      @thisSpacerIsTransparent = false
      @_changed()
    super

  # paintIntoAreaOrBlitFromBackBuffer is inherited from LayoutChromeWdgt; this
  # class supplies only its drawLayoutChrome tail (the base default, via
  # spacerWidgetRenderingHelper below) and toggles thisSpacerIsTransparent in
  # makeSpacersTransparent / makeSpacersOpaque above.

  doPath: (context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown) ->
    context.beginPath()
    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x, 0.5 + leftArrowPoint.y + arrowPieceLeftUp.y
    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftDown.x, 0.5 + leftArrowPoint.y + arrowPieceLeftDown.y

    #context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    #context.lineTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y

    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x, 0.5 + leftArrowPoint.y

    spaceInBetweenArrowAndMiddle =  Math.abs @width()/2 - (0.5 + leftArrowPoint.x + arrowPieceLeftUp.x)

    ## the squiggly part
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x + 1*spaceInBetweenArrowAndMiddle/3, 0.5 + leftArrowPoint.y + arrowPieceLeftUp.y/2
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x + 2*spaceInBetweenArrowAndMiddle/3, 0.5 + leftArrowPoint.y + arrowPieceLeftDown.y/2
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x + 3*spaceInBetweenArrowAndMiddle/3, 0.5 + leftArrowPoint.y + arrowPieceLeftUp.y/2
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x + 4*spaceInBetweenArrowAndMiddle/3, 0.5 + leftArrowPoint.y + arrowPieceLeftDown.y/2
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x + 5*spaceInBetweenArrowAndMiddle/3, 0.5 + leftArrowPoint.y + arrowPieceLeftUp.y/2
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x + 6*spaceInBetweenArrowAndMiddle/3, 0.5 + leftArrowPoint.y

    context.lineTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y

    context.moveTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y

    context.lineTo 0.5 + rightArrowPoint.x + arrowPieceRightUp.x, 0.5 + rightArrowPoint.y + arrowPieceRightUp.y
    context.moveTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y
    context.lineTo 0.5 + rightArrowPoint.x + arrowPieceRightDown.x, 0.5 + rightArrowPoint.y + arrowPieceRightDown.y

    context.closePath()
    context.stroke()

  drawReplacerWidget: (context) ->
    p0 = @bottomLeft().subtract @position()
    p0 = p0.subtract new Point 0, Math.ceil @height()/2
    
    leftArrowPoint = p0.add new Point Math.ceil(@width()/15), 0

    rightArrowPoint = p0.add new Point @width() - Math.ceil(@width()/14), 0
    arrowPieceLeftUp = new Point Math.ceil(@width()/5), -Math.ceil(@height()/5)
    arrowPieceLeftDown = new Point Math.ceil(@width()/5), Math.ceil(@height()/5)
    arrowPieceRightUp = new Point -Math.ceil(@width()/5), -Math.ceil(@height()/5)
    arrowPieceRightDown = new Point -Math.ceil(@width()/5), Math.ceil(@height()/5)
    @doPath(context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown)


  spacerWidgetRenderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 1
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()
    context.strokeStyle = shadowColor.toString()
    @drawReplacerWidget context
    context.restore()

    context.strokeStyle = color.toString()
    @drawReplacerWidget context
