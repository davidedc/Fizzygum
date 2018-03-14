class ExternalLinkIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    outlineColor = 'rgba(184, 184, 184, 1)'
    #// Group
    #// outline box Drawing
    context.beginPath()
    context.moveTo 54, 22
    context.lineTo 13.5, 22
    context.lineTo 13.5, 86.5
    context.lineTo 78, 86.5
    context.lineTo 78, 46
    context.strokeStyle = outlineColor
    context.lineWidth = 16
    context.lineJoin = 'round'
    context.stroke()
    #// outline arrow Drawing
    context.beginPath()
    context.moveTo 62.33, 23.13
    context.lineTo 65.3, 23.13
    context.lineTo 40.31, 47.17
    context.lineTo 52.82, 59.68
    context.lineTo 76.98, 34.68
    context.lineTo 76.98, 37.66
    context.lineTo 93.2, 37.66
    context.lineTo 93.2, 6.9
    context.lineTo 62.33, 6.9
    context.lineTo 62.33, 23.13
    context.closePath()
    context.fillStyle = outlineColor
    context.fill()
    #// box Drawing
    context.beginPath()
    context.moveTo 51, 22
    context.lineTo 14, 22
    context.lineTo 14, 86
    context.lineTo 78, 86
    context.lineTo 78, 49
    context.strokeStyle = black
    context.lineWidth = 11
    context.lineJoin = 'round'
    context.stroke()
    #// arrow Drawing
    context.beginPath()
    context.moveTo 64.57, 20.28
    context.lineTo 71.74, 20.28
    context.lineTo 44.31, 47.72
    context.lineTo 52.28, 55.68
    context.lineTo 79.82, 28.25
    context.lineTo 79.82, 35.42
    context.lineTo 91.2, 35.42
    context.lineTo 91.2, 8.9
    context.lineTo 64.57, 8.9
    context.lineTo 64.57, 20.28
    context.closePath()
    context.fillStyle = black
    context.fill()

