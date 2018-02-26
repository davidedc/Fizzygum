class AlignCenterIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    outlineColor = 'rgba(184, 184, 184, 1)'
    #// Group
    #// outline
    #// outline line 2 Drawing
    context.beginPath()
    context.moveTo 30.5, 38.5
    context.lineTo 70.5, 38.5
    context.strokeStyle = outlineColor
    context.lineWidth = 23
    context.lineCap = 'round'
    context.stroke()
    #// outline line 3 Drawing
    context.beginPath()
    context.moveTo 25.03, 61.25
    context.lineTo 75.66, 61.25
    context.strokeStyle = outlineColor
    context.lineWidth = 23
    context.lineCap = 'round'
    context.stroke()
    #// outline line 1 Drawing
    context.beginPath()
    context.moveTo 15.5, 17.5
    context.lineTo 86.66, 17.46
    context.strokeStyle = outlineColor
    context.lineWidth = 23
    context.lineCap = 'round'
    context.stroke()
    #// outline line 4 Drawing
    context.beginPath()
    context.moveTo 17.16, 82.54
    context.lineTo 84.66, 82.54
    context.strokeStyle = outlineColor
    context.lineWidth = 23
    context.lineCap = 'round'
    context.stroke()
    #// lines
    #// line 1 Drawing
    context.beginPath()
    context.moveTo 14, 17
    context.lineTo 89, 17
    context.strokeStyle = black
    context.lineWidth = 8.5
    context.lineCap = 'round'
    context.stroke()
    #// line 4 Drawing
    context.beginPath()
    context.moveTo 15.75, 82
    context.lineTo 87, 82
    context.strokeStyle = black
    context.lineWidth = 8.5
    context.lineCap = 'round'
    context.stroke()
    #// line 3 Drawing
    context.beginPath()
    context.moveTo 23.69, 60.71
    context.lineTo 79, 60.71
    context.strokeStyle = black
    context.lineWidth = 8.5
    context.lineCap = 'round'
    context.stroke()
    #// line 2 Drawing
    context.beginPath()
    context.moveTo 29.88, 38.36
    context.lineTo 73, 38.36
    context.strokeStyle = black
    context.lineWidth = 8.5
    context.lineCap = 'round'
    context.stroke()

