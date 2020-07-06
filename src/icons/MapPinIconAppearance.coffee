class MapPinIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 70, 100
    @specificationSize = new Point 70, 100

  paintFunction: (context) ->
    #// Color Declarations
    pinColorString = Color.RED.toString()
    #// Group
    #// map pin outline Drawing
    context.beginPath()
    context.moveTo 35, 3.5
    context.bezierCurveTo 18, 3.5, 4.2, 16.69, 4.2, 32.94
    context.bezierCurveTo 4.2, 37.95, 5.48, 42.65, 7.73, 46.74
    context.bezierCurveTo 14.36, 58.8, 35, 95.9, 35, 95.9
    context.lineTo 62.06, 46.94
    context.bezierCurveTo 62.06, 46.84, 65.8, 37.74, 65.8, 32.94
    context.bezierCurveTo 65.8, 16.69, 52, 3.5, 35, 3.5
    context.closePath()
    context.moveTo 35, 40.24
    context.bezierCurveTo 30.16, 40.12, 28.29, 37.8, 28.25, 33.21
    context.bezierCurveTo 28.21, 28.62, 31.13, 26.59, 35, 26.55
    context.bezierCurveTo 38.87, 26.5, 41.79, 29.58, 41.75, 33.21
    context.bezierCurveTo 41.71, 36.84, 39.84, 40.36, 35, 40.24
    context.closePath()
    context.fillStyle = 'rgb(170, 170, 170)'
    context.fill()
    #// map pin Drawing
    context.beginPath()
    context.moveTo 35, 6.79
    context.bezierCurveTo 20.07, 6.79, 7.96, 18.9, 7.96, 33.83
    context.bezierCurveTo 7.96, 38.43, 9.08, 42.75, 11.05, 46.51
    context.bezierCurveTo 16.88, 57.59, 35, 91.67, 35, 91.67
    context.bezierCurveTo 35, 91.67, 52.84, 57.87, 58.76, 46.79
    context.lineTo 58.76, 46.7
    context.bezierCurveTo 58.76, 46.6, 58.85, 46.6, 58.85, 46.51
    context.bezierCurveTo 58.95, 46.41, 58.95, 46.32, 59.04, 46.13
    context.bezierCurveTo 60.92, 42.47, 62.04, 38.24, 62.04, 33.83
    context.bezierCurveTo 62.04, 18.9, 49.93, 6.79, 35, 6.79
    context.closePath()
    context.moveTo 35, 43.22
    context.bezierCurveTo 29.84, 43.22, 25.61, 39, 25.61, 33.83
    context.bezierCurveTo 25.61, 28.67, 29.84, 24.44, 35, 24.44
    context.bezierCurveTo 40.16, 24.44, 44.39, 28.67, 44.39, 33.83
    context.bezierCurveTo 44.39, 39, 40.16, 43.22, 35, 43.22
    context.closePath()
    context.fillStyle = pinColorString
    context.fill()
