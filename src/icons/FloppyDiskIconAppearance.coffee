class FloppyDiskIconAppearance extends IconAppearance

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
    context.moveTo 8.5, 6.5
    context.lineTo 78.16, 6.5
    context.lineTo 92.5, 20.83
    context.lineTo 92.5, 92.5
    context.lineTo 8.5, 92.5
    context.lineTo 8.5, 6.5
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// floppy silhouette Drawing
    context.beginPath()
    context.moveTo 12.23, 10.24
    context.lineTo 75.7, 10.24
    context.lineTo 88.77, 23.33
    context.lineTo 88.77, 88.76
    context.lineTo 12.23, 88.76
    context.lineTo 12.23, 10.24
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.stroke()
    #// metal slot hole Drawing
    context.beginPath()
    context.rect 57.5, 16.5, 7, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// dot in line 2 Drawing
    @oval context, 52.5, 67.5, 4, 4
    context.fillStyle = iconColorString
    context.fill()
    #// line 2 Drawing
    context.beginPath()
    context.moveTo 32.11, 69.71
    context.lineTo 48.83, 69.71
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.stroke()
    #// line 1 Drawing
    context.beginPath()
    context.moveTo 32.11, 63
    context.lineTo 44.65, 63
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.stroke()
    #// metal disk cover Drawing
    context.beginPath()
    context.rect 27.5, 11.5, 42, 24
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// label Drawing
    context.beginPath()
    context.rect 24, 53.5, 53, 35
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()

