class IconWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  constructor: (@color = WorldWdgt.preferencesAndSettings.iconDarkLineColor) ->
    super()
    @appearance = new IconAppearance @

  widthWithoutSpacing: ->
    @appearance.widthWithoutSpacing()

  rawResizeToWithoutSpacing: ->
    @rawSetExtent @appearance.calculateRectangleOfIcon().extent()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

   