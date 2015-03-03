# ColorPickerMorph ///////////////////////////////////////////////////

class ColorPickerMorph extends Morph

  feedback: null
  choice: null

  constructor: (defaultColor) ->
    @choice = defaultColor or new Color(255, 255, 255)
    super()
    @color = new Color(255, 255, 255)
    @setExtent new Point(80, 80)
    @buildSubmorphs()

  buildSubmorphs: ->
    @destroyAll()
    @feedback = new RectangleMorph(new Point(20, 20), @choice)
    cpal = new ColorPaletteMorph(@feedback, new Point(@width(), 50))
    gpal = new GrayPaletteMorph(@feedback, new Point(@width(), 5))
    cpal.setPosition @bounds.origin
    @add cpal
    gpal.setPosition cpal.bottomLeft()
    @add gpal
    x = (gpal.left() + Math.floor((gpal.width() - @feedback.width()) / 2))
    y = gpal.bottom() + Math.floor((@bottom() - gpal.bottom() - @feedback.height()) / 2)
    @feedback.setPosition new Point(x, y)
    @add @feedback
  
  getColor: ->
    @feedback.color
  
  rootForGrab: ->
    @
