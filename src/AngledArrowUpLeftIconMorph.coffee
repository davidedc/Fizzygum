# AngledArrowUpLeftIconMorph //////////////////////////////////////////////////////

# to try it:
#   world.create(new PencilIconMorph()
# or
#   world.create(new PencilIconMorph(new Point(200,200),"color = 'rgba(226, 0, 75, 1)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class AngledArrowUpLeftIconMorph extends IconMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  defaultPaintFunctionSource: """
    fillColor = @morph.color

    context.save()
    context.translate 90, 37
    context.rotate 90 * Math.PI / 180

    context.beginPath()
    context.moveTo -25, -9.04
    context.lineTo 16.6, 32.5
    context.lineTo 16.6, 1.35
    context.lineTo 79, 1.35
    context.lineTo 79, -102.5
    context.lineTo 58.2, -102.5
    context.lineTo 58.2, -19.42
    context.lineTo 16.6, -19.42
    context.lineTo 16.6, -50.58
    context.bezierCurveTo -4.2, -29.81, -25, -9.04, -25, -9.04
    context.closePath()
    context.fillStyle = fillColor
    context.fill()

    context.restore()
    """

  constructor: (@color) ->
    super @defaultPaintFunctionSource, @color
