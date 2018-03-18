class SlidesToolbarIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// external link
    #// box Drawing
    context.beginPath()
    context.moveTo 75.36, 60.27
    context.lineTo 59.71, 60.27
    context.lineTo 59.71, 87.29
    context.lineTo 86.77, 87.29
    context.lineTo 86.77, 71.67
    context.strokeStyle = iconColorString
    context.lineWidth = 6
    context.lineJoin = 'round'
    context.stroke()
    #// arrow Drawing
    context.beginPath()
    context.moveTo 81.09, 59.55
    context.lineTo 84.13, 59.55
    context.lineTo 72.53, 71.13
    context.lineTo 75.9, 74.49
    context.lineTo 87.54, 62.91
    context.lineTo 87.54, 65.94
    context.lineTo 92.35, 65.94
    context.lineTo 92.35, 54.74
    context.lineTo 81.09, 54.74
    context.lineTo 81.09, 59.55
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Aa
    #// second a Drawing
    context.beginPath()
    context.moveTo 44.48, 40.52
    context.lineTo 44.48, 39.41
    context.bezierCurveTo 43.59, 40.04, 43.53, 40.01, 42.46, 40.32
    context.bezierCurveTo 41.38, 40.64, 40.41, 40.8, 39.53, 40.8
    context.bezierCurveTo 37.63, 40.8, 36.08, 40.12, 34.89, 38.77
    context.bezierCurveTo 33.71, 37.42, 33.11, 35.93, 33.11, 34.29
    context.bezierCurveTo 33.11, 32.29, 33.87, 30.44, 35.39, 28.74
    context.bezierCurveTo 36.91, 27.03, 38.08, 26.68, 40.75, 26.68
    context.bezierCurveTo 41.83, 26.68, 43.07, 27.35, 44.48, 27.66
    context.lineTo 44.48, 26.52
    context.bezierCurveTo 44.48, 25.81, 44.25, 24.72, 43.79, 24.27
    context.bezierCurveTo 43.34, 23.83, 42.47, 23.09, 41.19, 23.09
    context.bezierCurveTo 40.14, 23.09, 38.78, 23.37, 37.1, 23.93
    context.bezierCurveTo 36.48, 24.13, 35.99, 24.23, 35.65, 24.23
    context.bezierCurveTo 35.18, 24.23, 34.77, 24, 34.45, 23.55
    context.bezierCurveTo 34.12, 23.09, 33.95, 22.51, 33.95, 21.8
    context.bezierCurveTo 33.95, 21.39, 34.01, 21.05, 34.13, 20.75
    context.bezierCurveTo 34.24, 20.46, 34.4, 20.22, 34.61, 20.05
    context.bezierCurveTo 34.82, 19.87, 35.25, 19.66, 35.91, 19.41
    context.bezierCurveTo 36.79, 19.08, 37.68, 18.83, 38.59, 18.63
    context.bezierCurveTo 39.5, 18.44, 40.33, 18.34, 41.07, 18.34
    context.bezierCurveTo 43.27, 18.34, 44.98, 19.49, 46.2, 20.76
    context.bezierCurveTo 47.41, 22.04, 48.02, 23.78, 48.02, 25.99
    context.lineTo 48.02, 35.77
    context.lineTo 48.63, 35.77
    context.bezierCurveTo 49.48, 35.77, 50.09, 35.99, 50.45, 36.43
    context.bezierCurveTo 50.82, 36.87, 51, 37.45, 51, 38.16
    context.bezierCurveTo 51, 38.85, 50.82, 39.42, 50.45, 39.86
    context.bezierCurveTo 50.09, 40.3, 49.48, 40.52, 48.63, 40.52
    context.lineTo 44.48, 40.52
    context.closePath()
    context.moveTo 44.48, 31.51
    context.bezierCurveTo 43.06, 31.14, 41.75, 30.44, 40.55, 30.44
    context.bezierCurveTo 39.1, 30.44, 38.79, 30.91, 37.75, 31.86
    context.bezierCurveTo 37.1, 32.46, 36.78, 33.58, 36.78, 34.19
    context.bezierCurveTo 36.78, 34.64, 37.4, 36.02, 37.71, 36.3
    context.bezierCurveTo 38.29, 36.81, 38.62, 37.06, 39.62, 37.06
    context.bezierCurveTo 40.47, 37.06, 41.44, 36.84, 42.52, 36.39
    context.bezierCurveTo 43.6, 35.94, 43.63, 35.84, 44.48, 35.07
    context.lineTo 44.48, 31.51
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// first A Drawing
    context.beginPath()
    context.moveTo 24.67, 32.94
    context.lineTo 15.56, 32.94
    context.lineTo 14.64, 35.92
    context.lineTo 15.56, 35.92
    context.bezierCurveTo 16.46, 35.92, 17.1, 36.14, 17.49, 36.59
    context.bezierCurveTo 17.87, 37.05, 18.06, 37.64, 18.06, 38.37
    context.bezierCurveTo 18.06, 39.08, 17.87, 39.67, 17.49, 40.12
    context.bezierCurveTo 17.1, 40.57, 16.46, 40.8, 15.56, 40.8
    context.lineTo 10.51, 40.8
    context.bezierCurveTo 9.6, 40.8, 8.96, 40.57, 8.58, 40.12
    context.bezierCurveTo 8.19, 39.67, 8, 39.08, 8, 38.35
    context.bezierCurveTo 8, 37.62, 8.2, 37.02, 8.6, 36.56
    context.bezierCurveTo 9.01, 36.1, 9.67, 35.88, 10.6, 35.92
    context.lineTo 16.49, 16.81
    context.lineTo 14.04, 16.81
    context.bezierCurveTo 13.14, 16.81, 12.49, 16.58, 12.11, 16.13
    context.bezierCurveTo 11.72, 15.68, 11.53, 15.08, 11.53, 14.35
    context.bezierCurveTo 11.53, 13.62, 11.72, 13.03, 12.11, 12.58
    context.bezierCurveTo 12.49, 12.13, 13.14, 11.9, 14.04, 11.9
    context.lineTo 22.14, 11.92
    context.lineTo 29.61, 35.92
    context.bezierCurveTo 30.49, 35.92, 31.07, 36.04, 31.35, 36.3
    context.bezierCurveTo 31.91, 36.82, 32.19, 37.51, 32.19, 38.37
    context.bezierCurveTo 32.19, 39.08, 32, 39.67, 31.62, 40.12
    context.bezierCurveTo 31.24, 40.57, 30.6, 40.8, 29.7, 40.8
    context.lineTo 24.65, 40.8
    context.bezierCurveTo 23.75, 40.8, 23.1, 40.57, 22.72, 40.12
    context.bezierCurveTo 22.34, 39.67, 22.14, 39.08, 22.14, 38.35
    context.bezierCurveTo 22.14, 37.63, 22.34, 37.05, 22.72, 36.59
    context.bezierCurveTo 23.1, 36.14, 23.75, 35.92, 24.65, 35.92
    context.lineTo 25.56, 35.92
    context.lineTo 24.67, 32.94
    context.closePath()
    context.moveTo 23.11, 28.05
    context.lineTo 20.09, 18.38
    context.lineTo 17.06, 28.05
    context.lineTo 23.11, 28.05
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// heart
    #// Oval Drawing
    @arc context, 11, 59, 19, 18, 136, -34, false
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Oval 2 Drawing
    @arc context, 26, 59, 19, 18, -146, 46, false
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Oval 3 Drawing
    @oval context, 27, 61.9, 2, 2
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 13.28, 73.85
    context.lineTo 26.58, 87.72
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 42.72, 73.85
    context.lineTo 29.23, 87.91
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Oval 4 Drawing
    @arc context, 25.5, 83.1, 5, 5, 37, 143, false
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Oval 5 Drawing
    @arc context, 15.5, 63, 10, 10, -179, -87, false
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// arrow down Drawing
    context.beginPath()
    context.moveTo 91.44, 26.84
    context.lineTo 85.61, 20.95
    context.bezierCurveTo 85.61, 20.95, 82.34, 24.26, 79.13, 27.51
    context.lineTo 79.13, 10.21
    context.lineTo 70.88, 10.21
    context.lineTo 70.88, 27.51
    context.lineTo 64.39, 20.95
    context.lineTo 58.56, 26.84
    context.lineTo 75, 43.43
    context.lineTo 91.44, 26.84
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()

