class HeartIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    colorString = 'rgba(0, 0, 0)'

    context.strokeStyle = colorString
    context.fillStyle = colorString

    #// Oval Drawing
    @arc context, 11, 21, 99, 99, 136, 326, false
    context.lineWidth = 8
    context.stroke()
    #// Oval 2 Drawing
    @arc context, 91, 21, 99, 99, 214, 46, false
    context.lineWidth = 8
    context.stroke()
    #// Oval 3 Drawing
    @oval context, 98, 41, 4, 4
    context.fill()
    context.lineWidth = 1
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 23, 103
    context.lineTo 93, 178
    context.lineWidth = 8
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 178, 103
    context.lineTo 107, 179
    context.lineWidth = 8
    context.stroke()
    #// Oval 4 Drawing
    @arc context, 87.5, 154.5, 26, 26, 26, 143, false
    context.lineWidth = 7.5
    context.stroke()
    #// Oval 5 Drawing
    @arc context, 33.5, 44, 53, 54, 181, 273, false
    context.lineWidth = 10
    context.stroke()
    #// Oval 6 Drawing
    @oval context, 57, 40, 8.5, 8.5
    context.fill()
    context.lineWidth = 1
    context.stroke()
    #// Oval 7 Drawing
    @oval context, 29.5, 66, 8.5, 8.5
    context.fill()
    context.lineWidth = 1
    context.stroke()
