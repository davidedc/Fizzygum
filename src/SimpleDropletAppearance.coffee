class SimpleDropletAppearance extends RectangularAppearance

  # The plus-sign glyph, drawn INSIDE the base paint's logical-pixels scope (already switched
  # to logical pixels and translated to the widget position), so the geometry below is
  # widget-local logical coordinates. The base rectangular scope runs UNCLIPPED (opts.clip
  # false — its fills self-bound), so this hook clips its strokes to the damage box itself,
  # as its legacy device-space self-clip did.

  drawAdditionalPartsOnBaseShape: (appliedShadow, context, localArea) ->

    # we refuse to paint the shadow of the plus sign
    # in the middle of a black rectangle. Just, no.
    if appliedShadow?
      return

    height = @widget.height()
    width = @widget.width()

    squareDim = Math.min width/2, height/2

    # p0 is the origin, the origin being in the bottom-left corner (widget-local)
    p0 = new Point 0, height

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

    # bound the affordance to the damage box (the legacy self-clip, now in local coords)
    context.clipToRectangle localArea.left(), localArea.top(), localArea.width(), localArea.height()

    context.lineWidth = 1
    context.lineCap = "round"
    context.strokeStyle = color.toString()

    context.beginPath()
    context.moveTo 0.5 + plusSignLeft.x, 0.5 + plusSignLeft.y
    context.lineTo 0.5 + plusSignRight.x, 0.5 + plusSignRight.y
    context.moveTo 0.5 + plusSignTop.x, 0.5 + plusSignTop.y
    context.lineTo 0.5 + plusSignBottom.x, 0.5 + plusSignBottom.y


    context.closePath()
    context.stroke()

    context.restore()

