class CollapseIconAppearance extends IconAppearance

  paintFunction: (context) ->
    fillColor = @morph.color

    # The circle
    context.beginPath()
    context.moveTo 100.5, 196.5
    context.bezierCurveTo 153.91, 196.5, 197.5, 152.91, 197.5, 99.5
    context.bezierCurveTo 197.5, 46.09, 153.91, 2.5, 100.5, 2.5
    context.bezierCurveTo 47.09, 2.5, 3.5, 46.09, 3.5, 99.5
    context.bezierCurveTo 3.5, 152.91, 47.09, 196.5, 100.5, 196.5
    context.closePath()
    context.moveTo 100.5, 15.1
    context.bezierCurveTo 147.11, 15.1, 184.9, 52.89, 184.9, 99.5
    context.bezierCurveTo 184.9, 146.11, 147.11, 183.9, 100.5, 183.9
    context.bezierCurveTo 53.89, 183.9, 16.1, 146.11, 16.1, 99.5
    context.bezierCurveTo 16.1, 52.89, 53.89, 15.1, 100.5, 15.1
    context.closePath()
    context.fillStyle = fillColor.toString()
    context.fill()

    # The "open window" inside the circle
    context.beginPath()
    context.rect 65, 107, 65, 21
    context.closePath()
    context.fill()

