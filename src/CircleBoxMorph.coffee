# CircleBoxMorph //////////////////////////////////////////////////////

# I can be used for sliders

class CircleBoxMorph extends Morph


  constructor: ->
    super()
    @appearance = new CircleBoxyAppearance(@)
    @silentRawSetExtent new Point 20, 100

  
  autoOrientation: ->
    if @height() > @width()
      orientation = "vertical"
    else
      orientation = "horizontal"
