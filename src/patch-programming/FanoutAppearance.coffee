
class FanoutAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    highlightColorString = 'rgb(184, 184, 184)'
    #// highlight Drawing
    context.beginPath()
    context.moveTo 51.38, 22.81
    context.lineTo 78.36, 48.57
    context.bezierCurveTo 79.09, 49.3, 79.09, 50.47, 78.36, 51.2
    context.lineTo 51.61, 78.36
    context.bezierCurveTo 50.89, 79.09, 49.71, 79.09, 48.98, 78.36
    context.lineTo 21.64, 51.09
    context.bezierCurveTo 20.91, 50.37, 20.91, 49.19, 21.64, 48.47
    context.bezierCurveTo 21.64, 48.47, 31.37, 39.38, 32.83, 38.02
    context.bezierCurveTo 31.58, 36.83, 31.47, 36.71, 30.73, 36.01
    context.bezierCurveTo 29.98, 35.31, 30.33, 32.98, 31.73, 31.64
    context.bezierCurveTo 33.12, 30.29, 35.61, 30.27, 36.3, 30.64
    context.bezierCurveTo 37, 31, 38.19, 32.44, 38.54, 32.78
    context.bezierCurveTo 38.98, 32.35, 48.75, 22.81, 48.75, 22.81
    context.bezierCurveTo 48.75, 22.81, 50.66, 22.09, 51.38, 22.81
    context.closePath()
    context.moveTo 52.82, 42.51
    context.bezierCurveTo 52.82, 45.15, 52.82, 49.97, 52.82, 49.97
    context.bezierCurveTo 52.82, 50.96, 51.97, 51.76, 50.92, 51.76
    context.bezierCurveTo 50.92, 51.76, 44.65, 51.76, 42.2, 51.76
    context.bezierCurveTo 43, 55.33, 46.19, 58, 50, 58
    context.bezierCurveTo 54.42, 58, 58, 54.42, 58, 50
    context.bezierCurveTo 58, 46.57, 55.85, 43.65, 52.82, 42.51
    context.closePath()
    context.fillStyle = highlightColorString
    context.fill()
    #// circle Drawing
    @oval context, 37, 37, 26, 26
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.stroke()
    #// arrows
    #// input arrow Drawing
    context.beginPath()
    context.moveTo 49.01, 41.08
    context.bezierCurveTo 48.33, 41.08, 47.78, 41.6, 47.78, 42.23
    context.lineTo 47.78, 45.32
    context.lineTo 35.8, 33.92
    context.bezierCurveTo 35.32, 33.48, 34.54, 33.48, 34.06, 33.93
    context.bezierCurveTo 33.58, 34.37, 33.58, 35.1, 34.06, 35.55
    context.lineTo 46.03, 46.95
    context.lineTo 42.71, 46.95
    context.bezierCurveTo 42.03, 46.95, 41.48, 47.46, 41.48, 48.1
    context.bezierCurveTo 41.48, 48.73, 42.03, 49.25, 42.71, 49.25
    context.lineTo 49.01, 49.24
    context.bezierCurveTo 49.7, 49.24, 50.25, 48.73, 50.25, 48.09
    context.lineTo 50.25, 42.23
    context.bezierCurveTo 50.25, 41.6, 49.7, 41.08, 49.01, 41.08
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// arrow up Drawing
    context.beginPath()
    context.moveTo 45.6, 30.47
    context.bezierCurveTo 46, 30.87, 46.65, 30.88, 47.06, 30.47
    context.lineTo 49.02, 28.51
    context.lineTo 49.03, 33.06
    context.bezierCurveTo 49.03, 33.63, 49.49, 34.09, 50.06, 34.09
    context.bezierCurveTo 50.63, 34.09, 51.1, 33.62, 51.1, 33.05
    context.lineTo 51.09, 28.51
    context.lineTo 53.06, 30.47
    context.bezierCurveTo 53.46, 30.87, 54.12, 30.87, 54.52, 30.47
    context.bezierCurveTo 54.92, 30.07, 54.92, 29.41, 54.52, 29.01
    context.lineTo 50.79, 25.29
    context.bezierCurveTo 50.39, 24.88, 49.73, 24.88, 49.33, 25.29
    context.lineTo 45.6, 29.01
    context.bezierCurveTo 45.19, 29.41, 45.19, 30.07, 45.6, 30.47
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// arrow right Drawing
    context.beginPath()
    context.moveTo 69.69, 45.43
    context.bezierCurveTo 69.28, 45.83, 69.28, 46.48, 69.69, 46.89
    context.lineTo 71.65, 48.85
    context.lineTo 67.1, 48.85
    context.bezierCurveTo 66.53, 48.85, 66.07, 49.31, 66.07, 49.88
    context.bezierCurveTo 66.07, 50.45, 66.53, 50.92, 67.1, 50.92
    context.lineTo 71.65, 50.92
    context.lineTo 69.69, 52.88
    context.bezierCurveTo 69.29, 53.28, 69.29, 53.94, 69.69, 54.34
    context.bezierCurveTo 70.09, 54.74, 70.75, 54.74, 71.15, 54.34
    context.lineTo 74.88, 50.61
    context.bezierCurveTo 75.28, 50.21, 75.28, 49.56, 74.88, 49.15
    context.lineTo 71.15, 45.43
    context.bezierCurveTo 70.75, 45.02, 70.09, 45.02, 69.69, 45.43
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// arrow down Drawing
    context.beginPath()
    context.moveTo 54.76, 69.7
    context.bezierCurveTo 54.36, 69.29, 53.7, 69.29, 53.3, 69.7
    context.lineTo 51.33, 71.66
    context.lineTo 51.33, 67.11
    context.bezierCurveTo 51.33, 66.54, 50.87, 66.08, 50.3, 66.08
    context.bezierCurveTo 49.73, 66.08, 49.26, 66.54, 49.26, 67.11
    context.lineTo 49.26, 71.66
    context.lineTo 47.3, 69.7
    context.bezierCurveTo 46.9, 69.29, 46.24, 69.3, 45.84, 69.7
    context.bezierCurveTo 45.43, 70.1, 45.43, 70.76, 45.84, 71.16
    context.lineTo 49.57, 74.88
    context.bezierCurveTo 49.97, 75.29, 50.63, 75.29, 51.03, 74.88
    context.lineTo 54.76, 71.16
    context.bezierCurveTo 55.17, 70.76, 55.17, 70.1, 54.76, 69.7
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// arrow left Drawing
    context.beginPath()
    context.moveTo 30.31, 54.24
    context.bezierCurveTo 30.72, 53.83, 30.72, 53.18, 30.31, 52.78
    context.lineTo 28.35, 50.81
    context.lineTo 32.9, 50.81
    context.bezierCurveTo 33.47, 50.81, 33.93, 50.35, 33.93, 49.78
    context.bezierCurveTo 33.93, 49.21, 33.47, 48.75, 32.9, 48.74
    context.lineTo 28.35, 48.75
    context.lineTo 30.31, 46.79
    context.bezierCurveTo 30.71, 46.38, 30.71, 45.73, 30.31, 45.33
    context.bezierCurveTo 29.91, 44.92, 29.25, 44.92, 28.85, 45.33
    context.lineTo 25.12, 49.05
    context.bezierCurveTo 24.72, 49.45, 24.72, 50.11, 25.12, 50.51
    context.lineTo 28.85, 54.24
    context.bezierCurveTo 29.25, 54.64, 29.91, 54.64, 30.31, 54.24
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
