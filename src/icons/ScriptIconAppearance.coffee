class ScriptIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->

    # Color Declarations
    iconColorString = @_iconColorString()
    outlineColorString = @_outlineColorString()

    # paper outline
    context.fillStyle = outlineColorString
    context.fillRect 14, 3, 73, 92

    # paper
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.strokeRect 18, 7, 65, 84

    # script inside paper
    context.fillStyle = iconColorString
    context.fillRect 29, 11, 13, 3
    context.fillRect 45, 11, 5, 3
    context.fillRect 52, 11, 26, 3
    context.fillRect 29, 18, 3, 3
    context.fillRect 35, 18, 20, 3
    context.fillRect 57, 18, 3, 3
    context.fillRect 62, 18, 12, 3
    context.fillRect 29, 25, 21, 3
    context.fillRect 52, 25, 26, 3
    context.fillRect 29, 31, 3, 3
    context.fillRect 35, 31, 20, 3
    context.fillRect 57, 31, 3, 3
    context.fillRect 62, 31, 12, 3
    context.fillRect 29, 38, 21, 3
    context.fillRect 29, 44, 6, 3
    context.fillRect 38, 44, 17, 3
    context.fillRect 40, 51, 10, 3
    context.fillRect 40, 58, 15, 3
    context.fillRect 57, 58, 3, 3
    context.fillRect 40, 64, 15, 3
    context.fillRect 57, 64, 3, 3
    context.fillRect 40, 70, 5, 3
    context.fillRect 29, 77, 21, 3
    context.fillRect 52, 77, 5, 3
    context.fillRect 29, 83, 13, 3
    context.fillRect 45, 83, 20, 3
    context.fillRect 21, 11, 3, 3
    context.fillRect 21, 18, 3, 3
    context.fillRect 21, 25, 3, 3
    context.fillRect 21, 31, 3, 3
    context.fillRect 21, 38, 3, 3
    context.fillRect 21, 44, 3, 3
    context.fillRect 21, 51, 3, 3
    context.fillRect 21, 58, 3, 3
    context.fillRect 21, 64, 3, 3
    context.fillRect 21, 70, 3, 3
    context.fillRect 21, 77, 3, 3
    context.fillRect 21, 83, 3, 3

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
    context.fillStyle = iconColorString
    context.fill()
    # circle around play symbol
    @oval context, 69, 68, 27, 27
    context.strokeStyle = iconColorString
    context.lineWidth = 3
    context.stroke()

