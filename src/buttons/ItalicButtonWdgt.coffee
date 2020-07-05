class ItalicButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.create 230, 230, 230

  constructor: (@color) ->
    super
    @appearance = new ItalicIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "italic"

  mouseClickLeft: ->
    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.toggleItalic?
      world.lastNonTextPropertyChangerButtonClickedOrDropped.toggleItalic()
