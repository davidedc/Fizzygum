# Paints the resize / move / rotate HandleWdgt: the striped-triangle resizer, the
# horizontal/vertical/move arrows or the rotate knob ring, drawn twice translated in a
# darker colour for a shadow so the handle reads on light backgrounds too, with the
# widget's hover state picking the highlighted colour pair.

class HandleAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      # Shadow-pass paint contract (Widget.coffee "How the shadow painting works"): both
      # art colours go BLACK under appliedShadow — the scope's alpha already carries the
      # shadow's faintness.
      if appliedShadow?
        @handleWidgetRenderingHelper ctx, Color.BLACK, Color.BLACK
      else if @widget.state == @widget.STATE_NORMAL
        @handleWidgetRenderingHelper ctx, @widget.color, Color.create 150, 150, 150
      else if @widget.state == @widget.STATE_HIGHLIGHTED
        @handleWidgetRenderingHelper ctx, Color.WHITE, Color.create 200, 200, 255

  drawArrow: (context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown) ->
    context.beginPath()
    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftUp.x, 0.5 + leftArrowPoint.y + arrowPieceLeftUp.y
    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + leftArrowPoint.x + arrowPieceLeftDown.x, 0.5 + leftArrowPoint.y + arrowPieceLeftDown.y

    context.moveTo 0.5 + leftArrowPoint.x, 0.5 + leftArrowPoint.y
    context.lineTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y

    context.lineTo 0.5 + rightArrowPoint.x + arrowPieceRightUp.x, 0.5 + rightArrowPoint.y + arrowPieceRightUp.y
    context.moveTo 0.5 + rightArrowPoint.x, 0.5 + rightArrowPoint.y
    context.lineTo 0.5 + rightArrowPoint.x + arrowPieceRightDown.x, 0.5 + rightArrowPoint.y + arrowPieceRightDown.y

    context.closePath()
    context.stroke()

  # the per-type arrow art -- called once per paint state (three of them) by
  # handleWidgetRenderingHelper, i.e. on every handle render
  drawHandle: (context) ->

    # horizontal arrow
    if @widget.type is "resizeHorizontalHandle" or @widget.type is "moveHandle"
      p0 = @widget.bottomLeft().subtract(@widget.position())
      p0 = p0.subtract new Point 0, Math.ceil(@widget.height()/2)

      leftArrowPoint = p0.add new Point Math.ceil(@widget.width()/15), 0

      rightArrowPoint = p0.add new Point @widget.width() - Math.ceil(@widget.width()/14), 0
      arrowPieceLeftUp = new Point Math.ceil(@widget.width()/5),-Math.ceil(@widget.height()/5)
      arrowPieceLeftDown = new Point Math.ceil(@widget.width()/5),Math.ceil(@widget.height()/5)
      arrowPieceRightUp = new Point -Math.ceil(@widget.width()/5),-Math.ceil(@widget.height()/5)
      arrowPieceRightDown = new Point -Math.ceil(@widget.width()/5),Math.ceil(@widget.height()/5)
      @drawArrow context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown

    # vertical arrow
    if @widget.type is "resizeVerticalHandle" or @widget.type is "moveHandle"
      p0 = @widget.bottomCenter().subtract @widget.position()

      leftArrowPoint = p0.add new Point 0, -Math.ceil(@widget.height()/14)

      rightArrowPoint = p0.add new Point 0, -@widget.height() + Math.ceil(@widget.height()/15)
      arrowPieceLeftUp = new Point -Math.ceil(@widget.width()/5), -Math.ceil(@widget.height()/5)
      arrowPieceLeftDown = new Point Math.ceil(@widget.width()/5), -Math.ceil(@widget.height()/5)
      arrowPieceRightUp = new Point -Math.ceil(@widget.width()/5), Math.ceil(@widget.height()/5)
      arrowPieceRightDown = new Point Math.ceil(@widget.width()/5), Math.ceil(@widget.height()/5)
      @drawArrow context, leftArrowPoint, rightArrowPoint, arrowPieceLeftUp, arrowPieceLeftDown, arrowPieceRightUp, arrowPieceRightDown


    # Affine transforms (§6 Phase 4B): the rotate handle draws a small "knob" ring — visually
    # distinct from the resize arrows / striped triangle. The ring strokes at the hairline
    # lineWidth 0.5 set by handleWidgetRenderingHelper: every SWCanvas direct stroke dispatcher
    # renders a sub-1px width as 1px geometry at opacity proportional to the true DEVICE width
    # (the generic pipeline's sub-pixel rule, restated at the dispatch layer), so this is a
    # faint 1px Bresenham ring whose faintness scales with the island and whose closure holds
    # at ANY uniform scale — the transform-robustness that qualifies a hairline for the direct
    # path at all (case law: docs/archive/direct-shape-fastpaths-followups-plan.md). The ring
    # involves no trig, so its cross-engine byte-identity (the suite asserts exact pixels under
    # WebKit) is independent of the fdlibm shim. The native page rasterises strokeCircle through
    # the arc polyfill on the platform canvas, and matches no reference. (The rotate glyph is
    # due the four-swirlies redesign — BACKLOG — at which point this paint goes away wholesale.)
    if @widget.type is "rotateHandle"
      cx = @widget.width() / 2
      cy = @widget.height() / 2
      r  = Math.min(@widget.width(), @widget.height()) / 2 - 1
      context.strokeCircle cx, cy, r

    # draw the traditional "striped triangle" resizer
    if @widget.type is "resizeBothDimensionsHandle"
      bottomLeft = @widget.bottomLeft().subtract(@widget.position())
      topRight = @widget.topRight().subtract(@widget.position())

      # draw the lines sweeping from long lines
      # down to the short ones at the corner: the start point
      # sweeps right along the bottom edge, the end point
      # sweeps down the right edge
      for i in [0..@widget.height()] by 6
        context.beginPath()
        context.moveTo bottomLeft.x + i, bottomLeft.y
        context.lineTo topRight.x, topRight.y + i
        context.closePath()
        context.stroke()


  handleWidgetRenderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 0.5
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()
    context.strokeStyle = shadowColor.toString()
    context.translate 1,1
    @drawHandle context
    context.translate 1,0
    @drawHandle context
    context.restore()

    context.strokeStyle = color.toString()
    @drawHandle context
