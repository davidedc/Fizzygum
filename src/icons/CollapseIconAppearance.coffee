class CollapseIconAppearance extends IconAppearance

  paintFunction: (context) ->
    fillColor = @widget.color

    # The circle
    @_paintButtonRing context, fillColor

    # The "open window" inside the circle
    context.beginPath()
    context.rect 65, 107, 65, 21
    context.closePath()
    context.fill()

