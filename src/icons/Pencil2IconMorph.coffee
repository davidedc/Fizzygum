# to try it:
#   world.create(new PencilIconMorph(new Point(200,200),nil))
# or
#   world.create(new PencilIconMorph(new Point(200,200),"color = 'rgb(226, 0, 75)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class Pencil2IconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new Pencil2IconAppearance @
    @toolTipMessage = "pencil"

