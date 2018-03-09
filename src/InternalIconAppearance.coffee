class InternalIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    fillColor = @morph.color
    #// box
    context.beginPath()
    context.moveTo 3, 66
    context.lineTo 15, 66
    context.lineTo 15, 72.56
    context.bezierCurveTo 15, 80.02, 20.97, 85.08, 28.46, 85.08
    context.lineTo 71.54, 85.08
    context.bezierCurveTo 79.03, 85.08, 85.12, 79.02, 85.12, 71.56
    context.lineTo 85.12, 27.43
    context.bezierCurveTo 85.12, 19.97, 79.03, 13.91, 71.54, 13.91
    context.lineTo 28.46, 13.91
    context.bezierCurveTo 20.97, 13.91, 15, 18.97, 15, 26.43
    context.lineTo 15, 33
    context.lineTo 3, 33
    context.lineTo 3, 26.43
    context.bezierCurveTo 3, 12.46, 14.42, 2.08, 28.46, 2.08
    context.lineTo 71.54, 2.08
    context.bezierCurveTo 85.57, 2.08, 97, 13.46, 97, 27.43
    context.lineTo 97, 71.56
    context.bezierCurveTo 97, 85.54, 85.57, 96.92, 71.54, 96.92
    context.lineTo 28.46, 96.92
    context.bezierCurveTo 14.42, 96.92, 3, 86.54, 3, 72.56
    context.lineTo 3, 66
    context.closePath()
    context.fillStyle = fillColor.toString()
    context.fill()
    #// arrow out
    context.beginPath()
    context.moveTo 75.62, 55.11
    context.lineTo 43.42, 55.11
    context.lineTo 43.42, 73.92
    context.lineTo 9.44, 49.19
    context.lineTo 43.42, 24.48
    context.lineTo 43.42, 43.29
    context.lineTo 75.62, 43.29
    context.lineTo 75.62, 55.11
    context.closePath()
    context.fillStyle = fillColor.toString()
    context.fill()