class IconWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  constructor: (@color = WorldWdgt.preferencesAndSettings.iconDarkLineColor) ->
    super()
    @appearance = @createAppearance()

  # the generic icon; subclasses override with their specific appearance.
  # (a method, not a class field, so the build's dependency-finder still sees
  # the `new <X>IconAppearance` edge and orders the appearance before the icon.)
  createAppearance: -> new IconAppearance @

  widthWithoutSpacing: ->
    @appearance.widthWithoutSpacing()

  rawResizeToWithoutSpacing: ->
    @rawSetExtent @appearance.calculateRectangleOfIcon().extent()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

   