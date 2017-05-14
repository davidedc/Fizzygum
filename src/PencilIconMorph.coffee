# PencilIconMorph //////////////////////////////////////////////////////

# to try it:
#   world.create(new PencilIconMorph(new Point(200,200),null))
# or
#   world.create(new PencilIconMorph(new Point(200,200),"color = 'rgba(226, 0, 75, 1)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class PencilIconMorph extends IconMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # default icon is a circle
  paintFunctionSource: """
    fillColor = new Color 0,0,0
    context.beginPath()
    context.moveTo 117.5, 26.01
    context.lineTo 160.87, 55.9
    context.lineTo 172.73, 36.73
    context.lineTo 171.05, 22.06
    context.lineTo 143.88, 3.57
    context.lineTo 129.21, 7.1
    context.lineTo 117.5, 26.01
    context.closePath()
    context.moveTo 111.23, 36.13
    context.lineTo 154.73, 65.75
    context.lineTo 83.12, 181.37
    context.lineTo 43.71, 195.07
    context.lineTo 39.62, 151.75
    context.lineTo 111.23, 36.13
    context.closePath()
    context.fillStyle = fillColor
    context.fill()
    """
