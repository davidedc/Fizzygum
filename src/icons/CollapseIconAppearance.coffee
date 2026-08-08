class CollapseIconAppearance extends IconAppearance

  paintFunction: (context) ->
    fillColor = @widget.color

    # The circle
    @_paintButtonRing context, fillColor

    # The "open window" inside the circle. Sets its own fillStyle: the ring is
    # a STROKE, so nothing upstream leaves a fill colour behind for this fill.
    context.fillStyle = fillColor.toString()
    context.fillRect 65, 107, 65, 21

