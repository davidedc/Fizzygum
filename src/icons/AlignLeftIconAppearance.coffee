class AlignLeftIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    #// Group
    #// outline
    #// outline line 2 Drawing
    context.beginPath()
    context.moveTo 15.5, 38.5
    context.lineTo 55.5, 38.5
    context.strokeStyle = outlineColorString
    context.lineWidth = 23
    context.lineCap = 'round'
    context.stroke()
    #// outline line 3 Drawing
    context.beginPath()
    context.moveTo 15.03, 61.25
    context.lineTo 65.66, 61.25
    context.strokeStyle = outlineColorString
    context.lineWidth = 23
    context.lineCap = 'round'
    context.stroke()
    #// outline line 1 Drawing
    context.beginPath()
    context.moveTo 14.5, 17.5
    context.lineTo 85.66, 17.46
    context.strokeStyle = outlineColorString
    context.lineWidth = 23
    context.lineCap = 'round'
    context.stroke()
    #// outline line 4 Drawing
    context.beginPath()
    context.moveTo 14.16, 82.54
    context.lineTo 81.66, 82.54
    context.strokeStyle = outlineColorString
    context.lineWidth = 23
    context.lineCap = 'round'
    context.stroke()
    #// lines
    #// line 1 Drawing
    context.beginPath()
    context.moveTo 13, 17
    context.lineTo 88, 17
    context.strokeStyle = black
    context.lineWidth = 8.5
    context.lineCap = 'round'
    context.stroke()
    #// line 4 Drawing
    context.beginPath()
    context.moveTo 12.75, 82
    context.lineTo 84, 82
    context.strokeStyle = black
    context.lineWidth = 8.5
    context.lineCap = 'round'
    context.stroke()
    #// line 3 Drawing
    context.beginPath()
    context.moveTo 13.69, 60.71
    context.lineTo 69, 60.71
    context.strokeStyle = black
    context.lineWidth = 8.5
    context.lineCap = 'round'
    context.stroke()
    #// line 2 Drawing
    context.beginPath()
    context.moveTo 13.88, 38.36
    context.lineTo 57, 38.36
    context.strokeStyle = black
    context.lineWidth = 8.5
    context.lineCap = 'round'
    context.stroke()
