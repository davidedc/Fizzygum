class UncollapseIconAppearance extends IconAppearance

  paintFunction: (context) ->
    fillColor = @widget.color
    strokeColor = @widget.color

    # The circle
    @_paintButtonRing context, fillColor

    # The "open window" inside the circle. Sets its own fillStyle: the ring is
    # a STROKE, so nothing upstream leaves a fill colour behind for this fill.
    context.fillStyle = fillColor.toString()
    context.fillRect 65, 65, 65, 21

    context.strokeStyle = strokeColor.toString()
    context.lineWidth = 10
    context.strokeRect 65, 65, 65, 65
