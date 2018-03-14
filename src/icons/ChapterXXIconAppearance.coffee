# this file is excluded from the fizzygum homepage build

class ChapterXXIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    #// Group 2
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 34.04, 41.55
    context.bezierCurveTo 28.42, 41.07, 19.34, 38.97, 19.68, 25.88
    context.bezierCurveTo 20.01, 13.24, 28.95, 10.58, 34.05, 10.14
    context.bezierCurveTo 39.16, 9.7, 43.49, 12.4, 43.98, 12.66
    context.lineTo 43.98, 19.87
    context.lineTo 43.23, 19.87
    context.bezierCurveTo 42.87, 19.54, 41.72, 15.37, 35.24, 15.81
    context.bezierCurveTo 27.51, 16.32, 27.28, 24.11, 27.28, 25.9
    context.bezierCurveTo 27.28, 27.78, 27.07, 35.11, 34.24, 35.88
    context.bezierCurveTo 41.72, 36.7, 42.94, 32.18, 43.31, 31.84
    context.lineTo 43.98, 31.84
    context.lineTo 43.98, 38.95
    context.bezierCurveTo 43.44, 39.21, 39.65, 42.03, 34.04, 41.55
    context.closePath()
    context.moveTo 68.62, 40.96
    context.lineTo 61.69, 40.96
    context.lineTo 61.69, 29.65
    context.bezierCurveTo 61.69, 28.73, 61.36, 27.1, 60.16, 25.91
    context.bezierCurveTo 58.96, 24.71, 55.46, 24.33, 54.8, 24.8
    context.lineTo 54.8, 40.96
    context.lineTo 47.91, 40.96
    context.lineTo 47.91, 9.37
    context.lineTo 54.8, 9.37
    context.lineTo 54.8, 20.68
    context.bezierCurveTo 55.93, 19.69, 58.25, 18, 61.66, 18.6
    context.bezierCurveTo 67.57, 19.64, 68.62, 23.33, 68.62, 26.12
    context.lineTo 68.62, 40.96
    context.closePath()
    context.moveTo 80.87, 40.96
    context.lineTo 73.9, 40.96
    context.lineTo 73.9, 32.98
    context.lineTo 80.87, 32.98
    context.lineTo 80.87, 40.96
    context.closePath()
    context.fillStyle = black
    context.fill()
    #// Group
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 43.9, 88
    context.lineTo 35.83, 88
    context.lineTo 31.62, 81.27
    context.lineTo 27.29, 88
    context.lineTo 19.37, 88
    context.lineTo 27.5, 76.32
    context.lineTo 19.51, 64.61
    context.lineTo 27.58, 64.61
    context.lineTo 31.71, 71.22
    context.lineTo 35.87, 64.61
    context.lineTo 43.8, 64.61
    context.lineTo 35.79, 76.13
    context.lineTo 43.9, 88
    context.closePath()
    context.moveTo 53.6, 88
    context.lineTo 46.63, 88
    context.lineTo 46.63, 79.82
    context.lineTo 53.6, 79.82
    context.lineTo 53.6, 88
    context.closePath()
    context.moveTo 80.86, 88
    context.lineTo 72.79, 88
    context.lineTo 68.58, 81.27
    context.lineTo 64.25, 88
    context.lineTo 56.34, 88
    context.lineTo 64.47, 76.32
    context.lineTo 56.48, 64.61
    context.lineTo 64.55, 64.61
    context.lineTo 68.68, 71.22
    context.lineTo 72.83, 64.61
    context.lineTo 80.77, 64.61
    context.lineTo 72.75, 76.13
    context.lineTo 80.86, 88
    context.closePath()
    context.fillStyle = black
    context.fill()