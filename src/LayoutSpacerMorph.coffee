# this file is excluded from the fizzygum homepage build

class LayoutSpacerMorph extends Widget
  thisSpacerIsTransparent: false

  constructor: (spacerWeight = 1) ->
    super()
    @setColor new Color 0, 0, 0
    @setMinAndMaxBoundsAndSpreadability (new Point 0,0) , (new Point 1,1), spacerWeight * LayoutSpec.SPREADABILITY_SPACERS
    @minimumExtent = new Point 0,0

  makeSpacersTransparent: ->
    if !@thisSpacerIsTransparent
      @thisSpacerIsTransparent = true
      @changed()
    super

  makeSpacersOpaque: ->
    if @thisSpacerIsTransparent
      @thisSpacerIsTransparent = false
      @changed()
    super

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @thisSpacerIsTransparent
      return

    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

    # paintRectangle here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called before the scaling.
    @paintRectangle aContext, al, at, w, h, @color
    aContext.useLogicalPixelsUntilRestore()


    morphPosition = @position()
    aContext.translate morphPosition.x, morphPosition.y

    @spacerMorphRenderingHelper aContext, new Color(255, 255, 255), new Color(200, 200, 255)

    aContext.restore()

    # paintHighlight is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @paintHighlight aContext, al, at, w, h

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

  drawReplacerMorph: (context) ->
    p0 = @bottomLeft().subtract @position()
    p0 = p0.subtract new Point 0, Math.ceil @height()/2
    
    leftArrowPoint = p0.add new Point Math.ceil(@width()/15), 0

    rightArrowPoint = p0.add new Point @width() - Math.ceil(@width()/14), 0
    arrowPieceLeftUp = new Point Math.ceil(@width()/5), -Math.ceil(@height()/5)
    arrowPieceLeftDown = new Point Math.ceil(@width()/5), Math.ceil(@height()/5)
    arrowPieceRightUp = new Point -Math.ceil(@width()/5), -Math.ceil(@height()/5)
    arrowPieceRightDown = new Point -Math.ceil(@width()/5), Math.ceil(@height()/5)
    @doPath(context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown)


  spacerMorphRenderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 1
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()
    context.strokeStyle = shadowColor.toString()
    @drawReplacerMorph context
    context.restore()

    context.strokeStyle = color.toString()
    @drawReplacerMorph context
