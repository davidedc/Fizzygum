class BoldButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.create 128, 128, 128
  color_normal: Color.create 230, 230, 230

  constructor: ->
    super
    @appearance = new BoldIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "bold"

  mouseClickLeft: ->
    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.toggleWeight?
      world.lastNonTextPropertyChangerButtonClickedOrDropped.toggleWeight()
