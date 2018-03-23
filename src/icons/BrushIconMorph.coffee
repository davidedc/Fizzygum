# to try it:
#   world.create(new PencilIconMorph()
# or
#   world.create(new PencilIconMorph(new Point(200,200),"color = 'rgb(226, 0, 75)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class BrushIconMorph extends IconMorph


  constructor: (@color) ->
    super
    @appearance = new BrushIconAppearance @
    @toolTipMessage = "brush"
