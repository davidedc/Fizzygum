class FizzygumLogoWithTextIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  # TODO this should be a composition of the existing logo
  # and the text, we are duplicating the logo data instead...
  paintFunction: (context) ->
    #// Color Declarations
    white = 'rgb(255, 255, 255)'
    #// Text Drawing
    context.fillStyle = 'rgb(0, 0, 0)'
    context.font = 'bold 17px Arial-BoldMT, Arial, "Helvetica Neue", Helvetica, sans-serif'
    context.textAlign = 'center'
    textTotalHeight = 17 * 1.3
    context.fillText 'Fizzygum', 9 + 85 / 2, 75 + 15 + 24 / 2 - (textTotalHeight / 2)
    #// bubblegum
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 86.65, 39.23
    context.bezierCurveTo 86.65, 18.83, 71.39, 5.33, 52.57, 5.33
    context.bezierCurveTo 33.74, 5.33, 18.48, 20.51, 18.48, 39.23
    context.bezierCurveTo 18.48, 46.41, 22.83, 55.16, 24.57, 58.56
    context.bezierCurveTo 26.32, 61.95, 27.04, 68.39, 18.48, 73.13
    context.bezierCurveTo 18.48, 73.13, 48.71, 74.77, 59.45, 71.85
    context.bezierCurveTo 70.2, 68.93, 86.65, 59.63, 86.65, 39.23
    context.closePath()
    context.fillStyle = 'rgb(255, 0, 0)'
    context.fill()
    #// twinkles and bubbles 2
    #// bubbles 2
    #// bubble Drawing
    @oval context, 63, 22, 4, 4
    context.fillStyle = white
    context.fill()
    #// bubble 6 Drawing
    @oval context, 59, 35, 7, 7
    context.fillStyle = white
    context.fill()
    #// bubble 11 Drawing
    @oval context, 53, 27, 5, 5
    context.fillStyle = white
    context.fill()
    #// bubble 14 Drawing
    @oval context, 43, 35, 6, 6
    context.fillStyle = white
    context.fill()
    #// bubble 15 Drawing
    @oval context, 43, 23, 4, 4
    context.fillStyle = white
    context.fill()
    #// bubble 16 Drawing
    @oval context, 34, 28, 3, 3
    context.fillStyle = white
    context.fill()
    #// bubble 17 Drawing
    @oval context, 33, 40, 4, 4
    context.fillStyle = white
    context.fill()
    #// bubble 18 Drawing
    @oval context, 37, 54, 3, 3
    context.fillStyle = white
    context.fill()
    #// bubble 19 Drawing
    @oval context, 51, 58, 2, 2
    context.fillStyle = white
    context.fill()
    #// bubble 21 Drawing
    @oval context, 68, 43, 3, 3
    context.fillStyle = white
    context.fill()
    #// bubble 22 Drawing
    @oval context, 54, 45, 3, 3
    context.fillStyle = white
    context.fill()
    #// bubble 23 Drawing
    @oval context, 61, 52, 4, 4
    context.fillStyle = white
    context.fill()
    #// twinkles 2
    #// twinkle
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 52, 13.98
    context.lineTo 52, 15.48
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 49, 17
    context.lineTo 50.5, 17
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 53.5, 17
    context.lineTo 55, 17
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 52, 18.48
    context.lineTo 52, 19.98
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// twinkle 4
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 46, 47.48
    context.lineTo 46, 48.91
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 43.5, 49.99
    context.lineTo 44.93, 49.99
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 47.07, 49.99
    context.lineTo 48.5, 49.99
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 46, 51.05
    context.lineTo 46, 52.48
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1
    context.lineCap = 'round'
    context.stroke()
    #// twinkle 5
    #// Bezier 12 Drawing
    context.beginPath()
    context.moveTo 72.5, 30.98
    context.lineTo 72.5, 32.48
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 13 Drawing
    context.beginPath()
    context.moveTo 69.5, 34
    context.lineTo 71, 34
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 14 Drawing
    context.beginPath()
    context.moveTo 74, 34
    context.lineTo 75.5, 34
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 15 Drawing
    context.beginPath()
    context.moveTo 72.5, 35.48
    context.lineTo 72.5, 36.98
    context.strokeStyle = 'rgb(255, 255, 255)'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
