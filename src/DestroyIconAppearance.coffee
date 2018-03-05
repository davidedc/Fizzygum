class DestroyIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    # colors
    widgetColor = @morph.color
    colorString = 'rgba(0, 0, 0, 1)'

    # the drawing
    # icon adapted from
    # https://thenounproject.com/term/explosion/1255/

    context.beginPath()
    context.moveTo 42.5, 4.5
    context.lineTo 53.5, 29.5
    context.lineTo 72.5, 9.5
    context.lineTo 65.5, 35.5
    context.lineTo 94.5, 34.5
    context.lineTo 70.5, 51.5
    context.lineTo 96.5, 72.5
    context.lineTo 65.5, 66.5
    context.lineTo 73.5, 87.5
    context.lineTo 55.5, 73.5
    context.lineTo 43.5, 96.5
    context.lineTo 36.5, 67.5
    context.lineTo 9.5, 77.5
    context.lineTo 24.5, 59.5
    context.lineTo 3.5, 56.5
    context.lineTo 25.5, 48.5
    context.lineTo 5.5, 25.5
    context.lineTo 37.5, 32.5
    context.lineTo 42.5, 4.5
    context.closePath()
    context.fillStyle = colorString
    context.fill()
    context.strokeStyle = widgetColor
    context.lineWidth = 1
    context.stroke()


