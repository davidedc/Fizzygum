# ScratchAreaIconMorph //////////////////////////////////////////////////////


# based on https://thenounproject.com/term/organization/153374/
class ScratchAreaIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    colorString = 'rgba(0, 0, 0, 1)'
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 40.5, 118.5
    context.lineTo 40.5, 184.5
    context.lineTo 145.5, 184.5
    context.lineTo 145.5, 92.5
    context.lineTo 40.5, 92.5
    context.lineTo 67.5, 67.5
    context.lineTo 78.5, 67.5
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 146, 185
    context.lineTo 172.83, 159.74
    context.lineTo 172.29, 102.66
    context.lineTo 190, 87
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 172.5, 102.5
    context.lineTo 161.5, 112.5
    context.strokeStyle = colorString
    context.lineWidth = 5.5
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 19.5, 117.5
    context.bezierCurveTo 127.5, 117.5, 127.5, 117.5, 127.5, 117.5
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Oval Drawing
    @arc context, 128.5, 94.5, 33, 49, 180, 273, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 2 Drawing
    @arc context, 22, 93, 33, 49, 180, 273, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 3 Drawing
    @arc context, 135, 93, 26, 49, 266, 355, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 4 Drawing
    @arc context, 162.5, 67.5, 26, 49, 266, 355, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 103.5, 67.5
    context.lineTo 172, 67.5
    context.lineTo 146, 92.5
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 5 Drawing
    @arc context, -9.5, 76, 51, 49, 254, 339, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 6 Drawing
    @arc context, 17, 52.5, 51, 49, 254, 339, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 10, 77
    context.lineTo 37, 53
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 65.5, 68
    context.lineTo 72, 56
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 89.5, 45.5
    context.lineTo 105.5, 45.5
    context.strokeStyle = colorString
    context.lineWidth = 4
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 150.5, 45.5
    context.lineTo 188, 45
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 4
    context.stroke()
    #// Oval 7 Drawing
    @arc context, 171.5, 45.5, 33, 49, 180, 273, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 8 Drawing
    @arc context, 92, 80, 18, 18.5, 181, 0, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 83, 59.5
    context.lineTo 83.5, 73.5
    context.lineTo 98.5, 73.5
    context.lineTo 98, 58
    context.lineTo 83, 59.5
    context.closePath()
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 106.5, 39.5
    context.lineTo 117.5, 20.5
    context.lineTo 139.5, 20.5
    context.lineTo 149.5, 38.5
    context.lineTo 138.5, 57.5
    context.lineTo 116.5, 57.5
    context.lineTo 106.5, 39.5
    context.closePath()
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 9 Drawing
    @arc context, 64.5, 27, 22.5, 23.5, 181, 180, false
    context.strokeStyle = colorString
    context.lineWidth = 4.5
    context.stroke()

