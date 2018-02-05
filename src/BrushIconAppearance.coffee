# IconAppearance //////////////////////////////////////////////////////////////
# REQUIRES Point

class BrushIconAppearance extends IconAppearance

  paintFunction: (context) ->
    fillColor = @morph.color

    context.save()
    context.translate 102.19, 100.77
    context.rotate -17.2 * Math.PI / 180

    # the brush
    context.beginPath()
    context.moveTo 96.31, -58.22
    context.bezierCurveTo 95.39, -59.15, 94.01, -59.15, 93.1, -58.22
    context.lineTo 31.06, 5.14
    context.bezierCurveTo 27.61, 4.91, 15.44, -8.6, 13.83, -12.1
    context.bezierCurveTo 13.83, -12.33, 13.6, -12.33, 13.6, -12.56
    context.lineTo 75.4, -76.39
    context.bezierCurveTo 76.32, -77.32, 76.32, -78.72, 75.4, -79.65
    context.bezierCurveTo 74.49, -80.58, 73.11, -80.58, 72.19, -79.65
    context.lineTo 9.69, -15.36
    context.bezierCurveTo 3.26, -17.69, -9.15, -15.83, -20.63, -12.1
    context.bezierCurveTo -32.81, -8.37, -45.68, 9.8, -56.25, 24.47
    context.bezierCurveTo -61.3, 31.46, -65.44, 37.52, -68.65, 40.31
    context.bezierCurveTo -73.25, 44.74, -78.07, 44.74, -82.9, 44.51
    context.bezierCurveTo -87.49, 44.27, -92.09, 44.27, -95.08, 48.93
    context.lineTo -95.08, 48.93
    context.bezierCurveTo -96.45, 51.03, -96.22, 53.59, -94.85, 56.15
    context.bezierCurveTo -89.1, 66.17, -62.45, 77.35, -36.72, 77.35
    context.bezierCurveTo -35.8, 77.35, -34.88, 77.35, -33.73, 77.35
    context.bezierCurveTo -2.02, 76.19, 19.8, 58.48, 28.99, 43.57
    context.bezierCurveTo 36.12, 31.69, 38.18, 14.22, 34.97, 8.17
    context.lineTo 96.31, -54.49
    context.bezierCurveTo 97.23, -55.89, 97.23, -57.29, 96.31, -58.22
    context.closePath()
    context.moveTo 25.09, 40.78
    context.bezierCurveTo 16.59, 54.75, -3.86, 71.29, -33.73, 72.46
    context.bezierCurveTo -59.69, 73.39, -86.11, 61.74, -90.71, 53.82
    context.bezierCurveTo -91.63, 52.43, -91.17, 51.73, -90.94, 51.49
    context.bezierCurveTo -89.56, 49.16, -87.26, 49.16, -82.9, 49.4
    context.bezierCurveTo -77.84, 49.63, -71.41, 49.86, -65.44, 44.04
    context.bezierCurveTo -61.99, 40.78, -57.62, 34.49, -52.57, 27.5
    context.bezierCurveTo -42.46, 13.52, -30.05, -3.95, -19.49, -7.44
    context.bezierCurveTo -1.79, -13.03, 8.32, -11.63, 9.23, -10
    context.bezierCurveTo 10.61, -6.51, 23.94, 9.8, 30.6, 10.26
    context.bezierCurveTo 32.67, 12.13, 32.44, 28.43, 25.09, 40.78
    context.closePath()
    context.fillStyle = fillColor.toString()
    context.fill()

    # highlight squiggle
    context.beginPath()
    context.moveTo 16.36, 14.69
    context.bezierCurveTo 10.15, 15.16, 12.68, 34.96, -8.46, 48.47
    context.bezierCurveTo -30.05, 62.44, -47.06, 62.44, -47.06, 62.44
    context.bezierCurveTo -47.06, 62.44, -20.17, 66.63, 2.11, 50.1
    context.bezierCurveTo 24.4, 33.32, 22.79, 14.69, 16.36, 14.69
    context.closePath()
    context.fillStyle = fillColor.toString()
    context.fill()
    context.restore()
