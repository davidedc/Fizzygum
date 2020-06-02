# to try it:
#   world.create(new IconMorph(nil))
# or
#   world.create(new IconMorph("color = 'rgb(226, 0, 75)'\ncontext.beginPath()\ncontext.moveTo 23, 103\ncontext.lineTo 93, 178\ncontext.strokeStyle = color\ncontext.stroke()"))

class IconMorph extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  constructor: (@color = WorldMorph.preferencesAndSettings.iconDarkLineColor) ->
    super()
    @appearance = new IconAppearance @

  widthWithoutSpacing: ->
    @appearance.widthWithoutSpacing()

  rawResizeToWithoutSpacing: ->
    @rawSetExtent @appearance.calculateRectangleOfIcon().extent()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

   