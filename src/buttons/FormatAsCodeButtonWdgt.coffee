class FormatAsCodeButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.create 230, 230, 230

  constructor: ->
    super
    @appearance = new FormatAsCodeIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "format as code"

  mouseClickLeft: ->
    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.setFontName?
      widgetClickedLast = world.lastNonTextPropertyChangerButtonClickedOrDropped
      if widgetClickedLast.fontName != widgetClickedLast.monoFontStack
        widgetClickedLast.setFontName nil, nil, widgetClickedLast.monoFontStack
      else
        widgetClickedLast.setFontName nil, nil, widgetClickedLast.justArialFontStack

