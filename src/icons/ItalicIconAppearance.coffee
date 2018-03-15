class ItalicIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    #// outline Drawing
    context.beginPath()
    context.moveTo 37.67, 4
    context.lineTo 37.67, 13.56
    context.lineTo 51.84, 13.56
    context.bezierCurveTo 53.54, 13.56, 52.14, 15.67, 52.14, 17.34
    context.lineTo 33.06, 83.66
    context.bezierCurveTo 32.5, 85.33, 30.86, 85.44, 29.16, 85.44
    context.lineTo 16, 85.44
    context.lineTo 16, 95
    context.lineTo 64.33, 95
    context.lineTo 64.33, 85.44
    context.lineTo 51.16, 85.44
    context.bezierCurveTo 49.46, 85.44, 48.86, 85.33, 48.86, 83.66
    context.lineTo 68.94, 15.34
    context.bezierCurveTo 69.5, 13.67, 71.13, 13.56, 72.83, 13.56
    context.lineTo 86, 13.56
    context.lineTo 86, 4
    context.lineTo 37.67, 4
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// letter I in italic Drawing
    context.beginPath()
    context.moveTo 40, 6
    context.lineTo 40, 11.44
    context.lineTo 53.75, 11.44
    context.bezierCurveTo 55.4, 11.44, 55.98, 12.52, 55.98, 14.16
    context.lineTo 35.53, 84.84
    context.bezierCurveTo 34.98, 86.48, 33.4, 87.56, 31.75, 87.56
    context.lineTo 18, 87.56
    context.lineTo 18, 93
    context.lineTo 62, 93
    context.lineTo 62, 87.56
    context.lineTo 48.25, 87.56
    context.bezierCurveTo 46.6, 87.56, 46.01, 86.48, 46.01, 84.84
    context.lineTo 66.47, 14.16
    context.bezierCurveTo 67.02, 12.52, 68.6, 11.44, 70.25, 11.44
    context.lineTo 84, 11.44
    context.lineTo 84, 6
    context.lineTo 40, 6
    context.closePath()
    context.fillStyle = black
    context.fill()

