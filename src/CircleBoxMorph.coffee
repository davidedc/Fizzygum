# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders

class CircleBoxMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype


  constructor: ->
    super()
    @appearance = new CircleBoxyAppearance(@)
    @silentRawSetExtent new Point 20, 100

  
  autoOrientation: ->
    if @height() > @width()
      orientation = "vertical"
    else
      orientation = "horizontal"
