# EraserIconMorph //////////////////////////////////////////////////////

# to try it:
#   world.create(new PencilIconMorph()
# or
#   world.create(new PencilIconMorph(new Point(200,200),"color = 'rgba(226, 0, 75, 1)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class EraserIconMorph extends IconMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  defaultPaintFunctionSource: """
    fillColor = @morph.color

    context.beginPath()
    context.moveTo 191.45, 32.27
    context.bezierCurveTo 190.62, 31.18, 189.31, 30.53, 187.94, 30.53
    context.lineTo 100.04, 30.53
    context.bezierCurveTo 99.26, 30.53, 98.5, 30.75, 97.84, 31.16
    context.lineTo 97.68, 31.02
    context.lineTo 23.59, 110.15
    context.lineTo 22.8, 111.05
    context.lineTo 22.9, 111.15
    context.bezierCurveTo 22.74, 111.45, 22.61, 111.75, 22.53, 112.06
    context.lineTo 8.79, 163.86
    context.bezierCurveTo 8.44, 165.19, 8.72, 166.64, 9.55, 167.73
    context.bezierCurveTo 10.38, 168.82, 11.69, 169.47, 13.05, 169.47
    context.lineTo 100.95, 169.47
    context.bezierCurveTo 102.36, 169.47, 103.61, 168.87, 104.9, 167.56
    context.lineTo 177.19, 90.19
    context.bezierCurveTo 177.41, 89.96, 178.23, 88.81, 178.46, 87.94
    context.lineTo 191.72, 37.95
    context.lineTo 192.21, 36.14
    context.bezierCurveTo 192.56, 34.79, 192.29, 33.38, 191.45, 32.27
    context.closePath()
    context.moveTo 108.95, 117.67
    context.lineTo 97.57, 160.56
    context.lineTo 18.8, 160.56
    context.lineTo 30.18, 117.67
    context.lineTo 108.95, 117.67
    context.closePath()
    context.moveTo 178.4, 39.44
    context.lineTo 113.49, 108.76
    context.lineTo 37.03, 108.76
    context.lineTo 101.94, 39.44
    context.lineTo 178.4, 39.44
    context.closePath()
    context.fillStyle = fillColor
    context.fill()
    """

  constructor: (@color) ->
    super @defaultPaintFunctionSource, @color
