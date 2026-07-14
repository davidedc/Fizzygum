class UncollapseIconAppearance extends IconAppearance

  paintFunction: (context) ->
    fillColor = @widget.color
    strokeColor = @widget.color

    # The circle
    @_paintButtonRing context, fillColor

    # The "open window" inside the circle
    context.beginPath()
    context.rect 65, 65, 65, 21
    context.closePath()
    context.fill()

    context.beginPath()
    context.rect 65, 65, 65, 65
    context.closePath()
    context.strokeStyle = strokeColor.toString()
    context.lineWidth = 10
    context.stroke()
