# FloraIconMorph //////////////////////////////////////////////////////


class FloraIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 200, 200

  paintFunction: (context) ->
    #// Color Declarations
    colorString = 'rgba(0, 0, 0, 1)'
    #// Oval Drawing
    @arc context, 101.5, 46.5, 77, 77, 193, 259, false
    context.strokeStyle = colorString
    context.lineWidth = 3
    context.stroke()
    #// Oval 2 Drawing
    @arc context, 25.5, 46.5, 77, 77, 281, 347, false
    context.strokeStyle = colorString
    context.lineWidth = 3
    context.stroke()
    #// Oval 3 Drawing
    @arc context, 71.5, 16.5, 62, 62, 357, 183, false
    context.strokeStyle = colorString
    context.lineWidth = 3
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 101.5, 73.5
    context.lineTo 101.5, 110.5
    context.strokeStyle = colorString
    context.lineWidth = 3
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 48.5, 108.5
    context.lineTo 154.5, 108.5
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 4
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 47.5, 108.5
    context.lineTo 54.5, 133.5
    context.lineTo 150.5, 133.5
    context.lineTo 154.5, 109.5
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 4
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 57, 134
    context.lineTo 74, 192
    context.lineTo 132, 192
    context.lineTo 147, 133
    context.strokeStyle = colorString
    context.lineWidth = 4
    context.stroke()
    #// Oval 4 Drawing
    @oval context, 99, 7, 4, 4
    context.fillStyle = colorString
    context.fill()
    #// Oval 5 Drawing
    @oval context, 86, 19, 4, 4
    context.fillStyle = colorString
    context.fill()
    #// Oval 6 Drawing
    @oval context, 86, 32, 4, 4
    context.fillStyle = colorString
    context.fill()
    #// Oval 7 Drawing
    @oval context, 99, 19, 4, 4
    context.fillStyle = colorString
    context.fill()
    #// Oval 8 Drawing
    @oval context, 112, 19, 4, 4
    context.fillStyle = colorString
    context.fill()
    #// Oval 9 Drawing
    @oval context, 99, 32, 4, 4
    context.fillStyle = colorString
    context.fill()
    #// Oval 10 Drawing
    @oval context, 112, 32, 4, 4
    context.fillStyle = colorString
    context.fill()
    #// Oval 11 Drawing
    @oval context, 99, 44, 4, 4
    context.fillStyle = colorString
    context.fill()
