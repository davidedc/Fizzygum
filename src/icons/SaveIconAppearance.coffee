# this file is excluded from the fizzygum homepage build

class SaveIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    #// Group
    #// outline Drawing
    context.beginPath()
    context.moveTo 3.5, 2.5
    context.lineTo 80.62, 2.5
    context.lineTo 96.5, 18.33
    context.lineTo 96.5, 97.5
    context.lineTo 3.5, 97.5
    context.lineTo 3.5, 2.5
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// floppy silhouette Drawing
    context.beginPath()
    context.moveTo 7.63, 6.63
    context.lineTo 77.9, 6.63
    context.lineTo 92.37, 21.09
    context.lineTo 92.37, 93.37
    context.lineTo 7.63, 93.37
    context.lineTo 7.63, 6.63
    context.closePath()
    context.fillStyle = Color.WHITE.toString()
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.stroke()
    #// metal slot hole Drawing
    context.beginPath()
    context.rect 57.5, 14.5, 8, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// dot in line 2 Drawing
    @oval context, 52.5, 70.5, 4, 4
    context.fillStyle = iconColorString
    context.fill()
    #// line 2 Drawing
    context.beginPath()
    context.moveTo 29.63, 72.33
    context.lineTo 48.15, 72.33
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.stroke()
    #// line 1 Drawing
    context.beginPath()
    context.moveTo 29.63, 64.91
    context.lineTo 43.52, 64.91
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.stroke()
    #// metal disk cover Drawing
    context.beginPath()
    context.rect 24.5, 7.5, 47, 27
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// label Drawing
    context.beginPath()
    context.rect 21, 54.5, 58, 39
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
