# IconMorph //////////////////////////////////////////////////////

# to try it:
#   world.create(new IconMorph(nil))
# or
#   world.create(new IconMorph("color = 'rgba(226, 0, 75, 1)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class IconMorph extends Morph


  constructor: (paintFunction, @color = new Color 0,0,0) ->
    super()
    @appearance = new IconAppearance @, paintFunction

  widthWithoutSpacing: ->
    @appearance.widthWithoutSpacing()

  rawResizeToWithoutSpacing: ->
    @rawSetExtent @appearance.calculateRectangleOfIcon()

  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    @rawResizeToWithoutSpacing()
    ratio = @height()/@width()
    @rawSetExtent new Point newWidth, newWidth * ratio
   