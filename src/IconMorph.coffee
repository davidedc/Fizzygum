# IconMorph //////////////////////////////////////////////////////

# to try it:
#   world.create(new IconMorph(null))
# or
#   world.create(new IconMorph("color = 'rgba(226, 0, 75, 1)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class IconMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype


  constructor: (paintFunction, @color = new Color 0,0,0) ->
    super()
    @appearance = new IconAppearance @, paintFunction
