class CFDegreesConverterIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    #// degrees writings
    #// degrees F
    #// degrees of F outline Drawing
    @oval context, 67, 6.5, 13, 13
    context.fillStyle = 'rgb(170, 170, 170)'
    context.fill()
    #// F letter outline Drawing
    context.beginPath()
    context.moveTo 82, 16
    context.lineTo 82, 37
    context.moveTo 82, 16
    context.lineTo 93.5, 16
    context.moveTo 82, 26
    context.lineTo 87, 26
    context.strokeStyle = outlineColorString
    context.lineWidth = 7
    context.lineCap = 'round'
    context.stroke()
    #// degrees of F Drawing
    @oval context, 70, 9.5, 7, 7
    context.strokeStyle = black
    context.lineWidth = 2.5
    context.stroke()
    #// F letter Drawing
    context.beginPath()
    context.moveTo 95, 16.49
    context.bezierCurveTo 95, 17.35, 94.26, 18.06, 93.36, 18.06
    context.lineTo 83.53, 18.06
    context.bezierCurveTo 83.53, 18.06, 83.53, 20.47, 83.53, 23.56
    context.bezierCurveTo 83.68, 23.52, 83.84, 23.5, 84, 23.5
    context.lineTo 86, 23.5
    context.bezierCurveTo 87.1, 23.5, 88, 24.4, 88, 25.5
    context.bezierCurveTo 88, 26.6, 87.1, 27.5, 86, 27.5
    context.lineTo 84, 27.5
    context.bezierCurveTo 83.84, 27.5, 83.68, 27.48, 83.53, 27.44
    context.bezierCurveTo 83.53, 32.18, 83.53, 36.94, 83.53, 36.94
    context.bezierCurveTo 83.53, 37.81, 82.79, 38.52, 81.89, 38.52
    context.bezierCurveTo 80.99, 38.52, 80.25, 37.81, 80.25, 36.94
    context.bezierCurveTo 80.25, 36.94, 80.25, 36.14, 80.25, 34.86
    context.bezierCurveTo 80.25, 29.66, 80.25, 16.49, 80.25, 16.49
    context.bezierCurveTo 80.25, 15.62, 80.99, 14.92, 81.89, 14.92
    context.lineTo 93.36, 14.92
    context.bezierCurveTo 94.26, 14.92, 95, 15.62, 95, 16.49
    context.closePath()
    context.fillStyle = black
    context.fill()
    #// degrees C
    #// degrees of C outline Drawing
    @oval context, 2.5, 6.5, 13, 13
    context.fillStyle = outlineColorString
    context.fill()
    #// C letter outline Drawing
    context.beginPath()
    context.moveTo 23.94, 40.02
    context.bezierCurveTo 16.42, 40.02, 10.28, 33.76, 10.28, 26.07
    context.bezierCurveTo 10.28, 18.39, 16.42, 12.13, 23.94, 12.13
    context.bezierCurveTo 27.56, 12.13, 32.1, 14.34, 33.55, 16.17
    context.bezierCurveTo 35, 18, 34.15, 19.76, 33.56, 20.36
    context.bezierCurveTo 32.99, 20.97, 31.82, 21.91, 29.42, 21.37
    context.bezierCurveTo 27.01, 20.84, 28.89, 18.46, 23.94, 18.23
    context.bezierCurveTo 19, 18, 16, 23, 16.32, 26.07
    context.bezierCurveTo 16.64, 29.15, 18.09, 33.92, 23.94, 33.92
    context.bezierCurveTo 26.76, 33.92, 27.01, 31.56, 29.42, 30.78
    context.bezierCurveTo 31.82, 30, 32.99, 31.19, 33.56, 31.79
    context.bezierCurveTo 34.15, 32.39, 34.14, 35.38, 33.55, 35.98
    context.bezierCurveTo 30.97, 38.58, 27.56, 40.02, 23.94, 40.02
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// C letter Drawing
    context.beginPath()
    context.moveTo 23.64, 38.02
    context.bezierCurveTo 17.38, 38.02, 12.28, 32.66, 12.28, 26.07
    context.bezierCurveTo 12.28, 19.49, 17.38, 14.13, 23.64, 14.13
    context.bezierCurveTo 26.65, 14.13, 29.48, 15.36, 31.63, 17.59
    context.bezierCurveTo 32.12, 18.11, 32.13, 18.96, 31.64, 19.47
    context.bezierCurveTo 31.16, 19.99, 30.35, 20, 29.85, 19.48
    context.bezierCurveTo 28.19, 17.75, 25.99, 16.79, 23.64, 16.79
    context.bezierCurveTo 18.77, 16.79, 14.81, 20.95, 14.81, 26.07
    context.bezierCurveTo 14.81, 31.2, 18.77, 35.36, 23.64, 35.36
    context.bezierCurveTo 25.98, 35.36, 28.19, 34.41, 29.85, 32.67
    context.bezierCurveTo 30.35, 32.16, 31.16, 32.17, 31.64, 32.68
    context.bezierCurveTo 32.13, 33.2, 32.12, 34.05, 31.63, 34.56
    context.bezierCurveTo 29.48, 36.79, 26.65, 38.02, 23.64, 38.02
    context.closePath()
    context.fillStyle = black
    context.fill()
    #// degrees of C Drawing
    @oval context, 5.5, 9.5, 7, 7
    context.strokeStyle = black
    context.lineWidth = 2.5
    context.stroke()
    #// thermometer with lines
    #// thermometer outline Drawing
    context.beginPath()
    context.moveTo 51.3, 2
    context.bezierCurveTo 44.58, 1.97, 38.95, 6.05, 38.92, 12.2
    context.lineTo 38.92, 64.3
    context.bezierCurveTo 34.19, 67.67, 32, 72.85, 32, 78.71
    context.bezierCurveTo 32, 88.82, 40.17, 98, 51.34, 98
    context.bezierCurveTo 62.5, 98, 70.67, 88.82, 70.67, 78.71
    context.bezierCurveTo 70.67, 72.84, 68.47, 67.64, 63.72, 64.27
    context.bezierCurveTo 63.52, 45.14, 64, 30.33, 63.69, 12.2
    context.bezierCurveTo 63.72, 6.05, 58.09, 1.97, 51.3, 2
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// thermometer Drawing
    context.beginPath()
    context.moveTo 51.31, 4.82
    context.bezierCurveTo 45.82, 4.79, 41.22, 8.56, 41.19, 14.24
    context.lineTo 41.19, 64.94
    context.bezierCurveTo 37.33, 68.05, 34.78, 72.83, 34.78, 78.24
    context.bezierCurveTo 34.78, 87.57, 42.22, 95.18, 51.34, 95.18
    context.bezierCurveTo 60.46, 95.18, 67.89, 87.57, 67.89, 78.24
    context.bezierCurveTo 67.89, 72.82, 65.33, 68.02, 61.45, 64.91
    context.bezierCurveTo 61.29, 47.26, 61.68, 30.98, 61.42, 14.24
    context.bezierCurveTo 61.45, 8.56, 56.85, 4.79, 51.31, 4.82
    context.closePath()
    context.moveTo 51.28, 8.59
    context.bezierCurveTo 54.1, 8.56, 57.77, 10.44, 57.74, 14.24
    context.bezierCurveTo 57.8, 31.68, 57.77, 48.05, 57.77, 65.76
    context.bezierCurveTo 57.77, 66.38, 58.08, 66.98, 58.58, 67.32
    context.bezierCurveTo 61.98, 69.69, 64.21, 73.69, 64.21, 78.24
    context.bezierCurveTo 64.21, 85.53, 58.47, 91.41, 51.34, 91.41
    context.bezierCurveTo 44.2, 91.41, 38.46, 85.53, 38.46, 78.24
    context.bezierCurveTo 38.46, 73.71, 40.68, 69.7, 44.07, 67.32
    context.bezierCurveTo 44.55, 66.99, 44.86, 66.4, 44.87, 65.79
    context.lineTo 44.87, 14.24
    context.bezierCurveTo 44.9, 10.44, 47.66, 8.56, 51.28, 8.59
    context.closePath()
    context.moveTo 47.4, 49.18
    context.bezierCurveTo 46.76, 49.82, 46.74, 50.5, 46.74, 50.97
    context.lineTo 46.74, 70.18
    context.bezierCurveTo 44.02, 71.81, 42.14, 74.76, 42.14, 78.21
    context.bezierCurveTo 42.14, 83.38, 46.28, 87.62, 51.34, 87.62
    context.bezierCurveTo 56.39, 87.62, 60.53, 83.38, 60.53, 78.21
    context.bezierCurveTo 60.53, 74.77, 58.65, 71.84, 55.93, 70.21
    context.lineTo 55.93, 50.97
    context.bezierCurveTo 55.94, 50.29, 55.55, 49.61, 54.96, 49.29
    context.bezierCurveTo 54.37, 48.98, 53.61, 49.03, 53.06, 49.41
    context.bezierCurveTo 51.61, 49.96, 50.53, 48.82, 49.38, 48.59
    context.bezierCurveTo 48.61, 48.43, 47.98, 48.79, 47.4, 49.18
    context.closePath()
    context.fillStyle = black
    context.fill()
    #// thermometer lines
    #// thermometer line 9 Drawing
    context.beginPath()
    context.moveTo 47, 16
    context.lineTo 56, 16
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// thermometer line 7 Drawing
    context.beginPath()
    context.moveTo 47, 23.5
    context.lineTo 56, 23.5
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// thermometer line 5 Drawing
    context.beginPath()
    context.moveTo 47, 31
    context.lineTo 56, 31
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// thermometer line 3 Drawing
    context.beginPath()
    context.moveTo 47, 38.5
    context.lineTo 56, 38.5
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// thermometer line 1 Drawing
    context.beginPath()
    context.moveTo 47, 46
    context.lineTo 56, 46
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// thermometer line 8 Drawing
    context.beginPath()
    context.moveTo 51.5, 19.75
    context.lineTo 56, 19.75
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// thermometer line 6 Drawing
    context.beginPath()
    context.moveTo 51.5, 27.25
    context.lineTo 56, 27.25
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// thermometer line 4 Drawing
    context.beginPath()
    context.moveTo 51.5, 34.75
    context.lineTo 56, 34.75
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// thermometer line 2 Drawing
    context.beginPath()
    context.moveTo 51.5, 42.25
    context.lineTo 56, 42.25
    context.strokeStyle = black
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
