class SimpleDropletAppearance extends RectangularAppearance

  # alreadyUsingCanvasClipping / alreadyUsingCanvasScaling: true when the caller
  # already clipped/scaled the canvas for the base rectangle by hand (the fast
  # path used for plain rectangles instead of native canvas clip/scale -- by-hand
  # is not feasible for arbitrary shapes), so this hook must not repeat that
  # work; false means this hook must do its own clipToRectangle /
  # useLogicalPixelsUntilRestore before drawing.

  drawAdditionalPartsOnBaseShape: (alreadyUsingCanvasClipping, alreadyUsingCanvasScaling, appliedShadow, context, al, at, w, h) ->

    # we refuse to paint the shadow of the plus sign
    # in the middle of a black rectangle. Just, no.
    if appliedShadow?
      return

    height = @widget.height()
    width = @widget.width()

    squareDim = Math.min width/2, height/2

    # p0 is the origin, the origin being in the bottom-left corner
    p0 = @widget.bottomLeft()

    # now the origin if on the left edge, in the middle height of the widget
    p0 = p0.subtract new Point 0, Math.ceil height/2
    
    # now the origin is in the middle height of the widget,
    # on the left edge of the square inscribed in the widget
    p0 = p0.add new Point (width -  squareDim)/2, 0

    
    plusSignLeft = p0.add new Point Math.ceil(squareDim/15), 0
    plusSignRight = p0.add new Point squareDim - Math.ceil(squareDim/15), 0
    plusSignTop = p0.add new Point Math.ceil(squareDim/2), -Math.ceil(squareDim/3)
    plusSignBottom = p0.add new Point Math.ceil(squareDim/2), Math.ceil(squareDim/3)

    color = Color.WHITE

    context.save()

    context.lineWidth = 1
    context.lineCap = "round"
    context.strokeStyle = color.toString()


    if !alreadyUsingCanvasClipping
      context.clipToRectangle al,at,w,h

    if !alreadyUsingCanvasScaling
      context.useLogicalPixelsUntilRestore()

    context.beginPath()
    context.moveTo 0.5 + plusSignLeft.x, 0.5 + plusSignLeft.y
    context.lineTo 0.5 + plusSignRight.x, 0.5 + plusSignRight.y
    context.moveTo 0.5 + plusSignTop.x, 0.5 + plusSignTop.y
    context.lineTo 0.5 + plusSignBottom.x, 0.5 + plusSignBottom.y


    context.closePath()
    context.stroke()

    context.restore()

