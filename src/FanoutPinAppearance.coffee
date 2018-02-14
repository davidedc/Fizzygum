
class FanoutPinAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    black = 'rgba(0, 0, 0, 1)'
    outlineColor = 'rgba(184, 184, 184, 1)'
    #// Group 4
    #// outline Drawing
    context.beginPath()
    context.moveTo 81.16, 4
    context.lineTo 19.84, 4
    context.lineTo 19.84, 4
    context.bezierCurveTo 11.09, 4, 4, 11.09, 4, 19.84
    context.lineTo 4, 81.16
    context.lineTo 4, 81.16
    context.bezierCurveTo 4, 89.91, 11.09, 97, 19.84, 97
    context.lineTo 81.16, 97
    context.lineTo 81.16, 97
    context.bezierCurveTo 89.91, 97, 97, 89.91, 97, 81.16
    context.lineTo 97, 19.84
    context.lineTo 97, 19.84
    context.bezierCurveTo 97, 11.09, 89.91, 4, 81.16, 4
    context.closePath()
    context.fillStyle = outlineColor
    context.fill()
    #// enclosing rect Drawing
    context.beginPath()
    context.moveTo 78.82, 7.72
    context.lineTo 22.83, 7.72
    context.lineTo 22.83, 7.72
    context.bezierCurveTo 14.84, 7.72, 8.37, 14.19, 8.37, 22.18
    context.lineTo 8.37, 78.17
    context.lineTo 8.37, 78.17
    context.bezierCurveTo 8.37, 86.16, 14.84, 92.63, 22.83, 92.63
    context.lineTo 78.82, 92.63
    context.lineTo 78.82, 92.63
    context.bezierCurveTo 86.81, 92.63, 93.28, 86.16, 93.28, 78.17
    context.lineTo 93.28, 22.18
    context.lineTo 93.28, 22.18
    context.bezierCurveTo 93.28, 14.19, 86.81, 7.72, 78.82, 7.72
    context.closePath()
    context.moveTo 85.39, 78.17
    context.lineTo 85.39, 78.17
    context.bezierCurveTo 85.39, 81.8, 82.45, 84.74, 78.82, 84.74
    context.lineTo 22.83, 84.74
    context.lineTo 22.83, 84.74
    context.bezierCurveTo 19.2, 84.74, 16.26, 81.8, 16.26, 78.17
    context.lineTo 16.26, 22.18
    context.lineTo 16.26, 22.18
    context.bezierCurveTo 16.26, 18.55, 19.2, 15.61, 22.83, 15.61
    context.lineTo 78.82, 15.61
    context.lineTo 78.82, 15.61
    context.bezierCurveTo 82.45, 15.61, 85.39, 18.55, 85.39, 22.18
    context.lineTo 85.39, 78.17
    context.closePath()
    context.fillStyle = black
    context.fill()
