# this file is excluded from the fizzygum homepage build

class UnderCarpetIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 400, 400

  paintFunction: (context) ->
    #// Color Declarations
    colorString = 'rgb(0, 0, 0)'
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 96.5, 32.5
    context.lineTo 304.5, 113.5
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Oval Drawing
    @arc context, 264, 112, 61, 61, 285, 21, false
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 252, 335
    context.lineTo 324, 150
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Oval 2 Drawing
    @arc context, 188, 297, 63, 63, 285, 86, false
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 22.5, 218.5
    context.lineTo 230.5, 299.5
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 108, 360
    context.lineTo 223, 360
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 142, 266
    context.lineTo 142, 360
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 108, 340
    context.lineTo 143, 340
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 108, 318
    context.lineTo 143, 318
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 108, 296
    context.lineTo 143, 296
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 108, 274
    context.lineTo 143, 274
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 128, 47
    context.lineTo 58, 226
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 12 Drawing
    context.beginPath()
    context.moveTo 32, 197
    context.lineTo 62, 209
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 13 Drawing
    context.beginPath()
    context.moveTo 41, 177
    context.lineTo 71, 189
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 48, 156
    context.lineTo 78, 168
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 14 Drawing
    context.beginPath()
    context.moveTo 57, 136
    context.lineTo 87, 148
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 15 Drawing
    context.beginPath()
    context.moveTo 64, 115
    context.lineTo 94, 127
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 16 Drawing
    context.beginPath()
    context.moveTo 73, 95
    context.lineTo 103, 107
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 17 Drawing
    context.beginPath()
    context.moveTo 80, 74
    context.lineTo 110, 86
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 18 Drawing
    context.beginPath()
    context.moveTo 89, 54
    context.lineTo 119, 66
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Oval 3 Drawing
    @oval context, 312, 275, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 4 Drawing
    @oval context, 332, 350, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 5 Drawing
    @oval context, 321, 324, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 6 Drawing
    @oval context, 302, 314, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 7 Drawing
    @oval context, 313, 300, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 8 Drawing
    @oval context, 342, 314, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 9 Drawing
    @oval context, 334, 286, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 10 Drawing
    @oval context, 353, 271, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 11 Drawing
    @oval context, 327, 262, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 12 Drawing
    @oval context, 341, 251, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 13 Drawing
    @oval context, 356, 243, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 14 Drawing
    @oval context, 322, 238, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 15 Drawing
    @oval context, 338, 224, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 16 Drawing
    @oval context, 361, 225, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 17 Drawing
    @oval context, 348, 206, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 18 Drawing
    @oval context, 372, 198, 10, 9
    context.fillStyle = colorString
    context.fill()
