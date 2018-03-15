class ScriptIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->

    # Color Declarations
    widgetColorString = @morph.color
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString

    # paper outline
    context.beginPath()
    context.rect 14, 3, 73, 92
    context.fillStyle = outlineColorString
    context.fill()

    # paper
    context.beginPath()
    context.rect 18, 7, 65, 84
    context.strokeStyle = widgetColorString
    context.lineWidth = 2.5
    context.stroke()

    # script inside paper
    context.beginPath()
    context.rect 29, 11, 13, 3
    context.rect 45, 11, 5, 3
    context.rect 52, 11, 26, 3
    context.rect 29, 18, 3, 3
    context.rect 35, 18, 20, 3
    context.rect 57, 18, 3, 3
    context.rect 62, 18, 12, 3
    context.rect 29, 25, 21, 3
    context.rect 52, 25, 26, 3
    context.rect 29, 31, 3, 3
    context.rect 35, 31, 20, 3
    context.rect 57, 31, 3, 3
    context.rect 62, 31, 12, 3
    context.rect 29, 38, 21, 3
    context.rect 29, 44, 6, 3
    context.rect 38, 44, 17, 3
    context.rect 40, 51, 10, 3
    context.rect 40, 58, 15, 3
    context.rect 57, 58, 3, 3
    context.rect 40, 64, 15, 3
    context.rect 57, 64, 3, 3
    context.rect 40, 70, 5, 3
    context.rect 29, 77, 21, 3
    context.rect 52, 77, 5, 3
    context.rect 29, 83, 13, 3
    context.rect 45, 83, 20, 3
    context.rect 21, 11, 3, 3
    context.rect 21, 18, 3, 3
    context.rect 21, 25, 3, 3
    context.rect 21, 31, 3, 3
    context.rect 21, 38, 3, 3
    context.rect 21, 44, 3, 3
    context.rect 21, 51, 3, 3
    context.rect 21, 58, 3, 3
    context.rect 21, 64, 3, 3
    context.rect 21, 70, 3, 3
    context.rect 21, 77, 3, 3
    context.rect 21, 83, 3, 3
    context.fillStyle = widgetColorString
    context.fill()

    # Play button ------------------

    # outline
    @oval context, 66, 65, 33, 33
    context.fillStyle = outlineColorString
    context.fill()
    # play symbol
    context.beginPath()
    context.moveTo 78.35, 87.95
    context.lineTo 89.1, 80.95
    context.lineTo 78.35, 73.95
    context.lineTo 78.35, 87.95
    context.closePath()
    context.fillStyle = widgetColorString
    context.fill()
    # circle around play symbol
    @oval context, 69, 68, 27, 27
    context.strokeStyle = widgetColorString
    context.lineWidth = 3
    context.stroke()

