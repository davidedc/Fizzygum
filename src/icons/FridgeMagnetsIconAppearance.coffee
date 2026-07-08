# this file is excluded from the fizzygum homepage build
# The fridge-magnets ("Fizzytiles") launcher icon: a minimal fridge --
# body outline, freezer split, door handles, three magnet dots -- drawn
# in the same halo-fill + widget-color stroke idiom as the other desktop
# app icons (cf. PatchProgrammingIconAppearance).
class FridgeMagnetsIconAppearance extends IconAppearance

  constructor: (@widget) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @widget.color.toString()
    outlineColorString = WorldWdgt.preferencesAndSettings.outlineColorString

    #// fridge body: light halo fill so the glyph reads on the wallpaper
    #// dots, then the outline stroke
    context.beginPath()
    context.rect 33, 8, 34, 84
    context.fillStyle = outlineColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.lineJoin = 'round'
    context.stroke()

    #// freezer / main door split
    context.beginPath()
    context.moveTo 33, 34
    context.lineTo 67, 34
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.stroke()

    #// door handles (hinges on the right, handles on the left)
    context.beginPath()
    context.moveTo 40, 20
    context.lineTo 40, 28
    context.moveTo 40, 42
    context.lineTo 40, 56
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.lineCap = 'round'
    context.stroke()

    #// the magnets
    context.beginPath()
    @circle context, 54, 62, 4
    @circle context, 59, 76, 4
    @circle context, 46, 80, 4
    context.fillStyle = iconColorString
    context.fill()
