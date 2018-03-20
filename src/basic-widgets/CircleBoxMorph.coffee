# I can be used for sliders

class CircleBoxMorph extends Widget


  constructor: ->
    super()
    @appearance = new CircleBoxyAppearance(@)
    @silentRawSetExtent new Point 20, 100

  colloquialName: ->
    return "circle-box"
  
  autoOrientation: ->
    if @height() > @width()
      orientation = "vertical"
    else
      orientation = "horizontal"
