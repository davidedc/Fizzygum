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

   