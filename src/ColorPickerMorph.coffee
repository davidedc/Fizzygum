# ColorPickerMorph ///////////////////////////////////////////////////

class ColorPickerMorph extends Morph

  choice: null

  constructor: (defaultColor) ->
    @choice = defaultColor or new Color(255, 255, 255)
    super()
    @color = new Color(255, 255, 255)
    @silentSetExtent new Point(80, 80)
    @drawNew()
  
  drawNew: ->
    super()
    @buildSubmorphs()
  
  buildSubmorphs: ->
    @children.forEach (child) ->
      child.destroy()
    @children = []
    @feedback = new Morph()
    @feedback.color = @choice
    @feedback.setExtent new Point(20, 20)
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
  
  getChoice: ->
    @feedback.color
  
  rootForGrab: ->
    @
