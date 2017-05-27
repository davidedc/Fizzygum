# ToothpasteIconMorph //////////////////////////////////////////////////////

# to try it:
#   world.create(new PencilIconMorph()
# or
#   world.create(new PencilIconMorph(new Point(200,200),"color = 'rgba(226, 0, 75, 1)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class ToothpasteIconMorph extends IconMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  defaultPaintFunctionSource: """
    fillColor = @morph.color

    # the toothpaste
    context.beginPath()
    context.moveTo 181.43, 78.29
    context.bezierCurveTo 165.67, 78.29, 152.86, 91.16, 152.86, 106.98
    context.lineTo 152.86, 119.03
    context.bezierCurveTo 152.86, 125.04, 147.99, 129.93, 142, 129.93
    context.bezierCurveTo 136.01, 129.93, 131.14, 125.04, 131.14, 119.03
    context.lineTo 131.14, 40.41
    context.bezierCurveTo 131.14, 19.53, 114.22, 2.54, 93.43, 2.54
    context.lineTo 85.43, 2.54
    context.bezierCurveTo 64.63, 2.54, 47.71, 19.53, 47.71, 40.41
    context.lineTo 47.71, 57.63
    context.lineTo 54.57, 57.63
    context.lineTo 54.57, 40.41
    context.bezierCurveTo 54.57, 23.33, 68.41, 9.43, 85.43, 9.43
    context.lineTo 93.43, 9.43
    context.bezierCurveTo 110.44, 9.43, 124.29, 23.33, 124.29, 40.41
    context.lineTo 124.29, 119.03
    context.bezierCurveTo 124.29, 128.84, 132.23, 136.82, 142, 136.82
    context.bezierCurveTo 151.77, 136.82, 159.71, 128.84, 159.71, 119.03
    context.lineTo 159.71, 106.98
    context.bezierCurveTo 159.71, 94.95, 169.46, 85.17, 181.43, 85.17
    context.bezierCurveTo 184.58, 85.17, 187.14, 87.75, 187.14, 90.91
    context.bezierCurveTo 187.14, 94.07, 184.58, 96.65, 181.43, 96.65
    context.bezierCurveTo 175.76, 96.65, 171.14, 101.28, 171.14, 106.98
    context.lineTo 171.14, 119.03
    context.bezierCurveTo 171.14, 135.16, 158.07, 148.29, 142, 148.29
    context.bezierCurveTo 125.93, 148.29, 112.86, 135.16, 112.86, 119.03
    context.lineTo 112.86, 40.41
    context.bezierCurveTo 112.86, 29.65, 104.14, 20.9, 93.43, 20.9
    context.lineTo 85.43, 20.9
    context.bezierCurveTo 74.72, 20.9, 66, 29.65, 66, 40.41
    context.lineTo 66, 57.63
    context.lineTo 72.86, 57.63
    context.lineTo 72.86, 40.41
    context.bezierCurveTo 72.86, 33.45, 78.5, 27.79, 85.43, 27.79
    context.lineTo 93.43, 27.79
    context.bezierCurveTo 100.36, 27.79, 106, 33.45, 106, 40.41
    context.lineTo 106, 119.03
    context.bezierCurveTo 106, 138.96, 122.15, 155.18, 142, 155.18
    context.bezierCurveTo 161.85, 155.18, 178, 138.96, 178, 119.03
    context.lineTo 178, 106.98
    context.bezierCurveTo 178, 105.08, 179.54, 103.53, 181.43, 103.53
    context.bezierCurveTo 188.36, 103.53, 194, 97.87, 194, 90.91
    context.bezierCurveTo 194, 83.95, 188.36, 78.29, 181.43, 78.29
    context.closePath()
    context.fillStyle = fillColor
    context.fill()

    # the tube
    context.beginPath()
    context.moveTo 24.86, 124.19
    context.lineTo 95.72, 124.19
    context.lineTo 95.72, 197.46
    context.lineTo 102.57, 197.46
    context.lineTo 102.57, 117.88
    context.lineTo 99.44, 111.09
    context.lineTo 85.81, 89.26
    context.lineTo 82.76, 84.37
    context.lineTo 82.76, 60.88
    context.lineTo 37.81, 60.88
    context.lineTo 37.81, 84.37
    context.lineTo 32.28, 93.21
    context.lineTo 21.33, 110.7
    context.lineTo 18, 117.88
    context.lineTo 18, 197.46
    context.lineTo 24.86, 197.46
    context.lineTo 24.86, 124.19
    context.closePath()
    context.moveTo 27.26, 114.18
    context.lineTo 40.38, 93.21
    context.lineTo 44.67, 86.35
    context.lineTo 44.67, 67.76
    context.lineTo 75.9, 67.76
    context.lineTo 75.91, 86.35
    context.lineTo 80.19, 93.21
    context.lineTo 93.31, 114.18
    context.lineTo 94.76, 117.31
    context.lineTo 25.82, 117.31
    context.lineTo 27.26, 114.18
    context.closePath()
    context.fillStyle = fillColor
    context.fill()
    """

  constructor: (@color) ->
    super @defaultPaintFunctionSource, @color
