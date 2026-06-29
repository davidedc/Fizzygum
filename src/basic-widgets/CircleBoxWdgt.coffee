# I can be used for sliders

class CircleBoxWdgt extends Widget


  constructor: ->
    super()
    @appearance = new CircleBoxyAppearance(@)
    @_commitExtentAndNotify new Point 20, 100

  colloquialName: ->
    return "circle-box"
  
  autoOrientation: ->
    if @height() > @width()
      return "vertical"
    else
      return "horizontal"
