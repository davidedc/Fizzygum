class DecreaseFontSizeButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.create 230, 230, 230

  constructor: ->
    super
    @appearance = new DecreaseFontSizeIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "decrease font size"

  mouseClickLeft: ->
    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.originallySetFontSize?
      widgetClickedLast = world.lastNonTextPropertyChangerButtonClickedOrDropped
      if widgetClickedLast.originallySetFontSize > 90
        widgetClickedLast.setFontSize widgetClickedLast.originallySetFontSize - 10
      else if widgetClickedLast.originallySetFontSize > 80
        widgetClickedLast.setFontSize 80
      else if widgetClickedLast.originallySetFontSize > 72
        widgetClickedLast.setFontSize 72
      else if widgetClickedLast.originallySetFontSize > 48
        widgetClickedLast.setFontSize 48
      else if widgetClickedLast.originallySetFontSize > 36
        widgetClickedLast.setFontSize 36
      else if widgetClickedLast.originallySetFontSize > 28
        widgetClickedLast.setFontSize 28
      else if widgetClickedLast.originallySetFontSize > 12
        widgetClickedLast.setFontSize widgetClickedLast.originallySetFontSize - 2
      else
        widgetClickedLast.setFontSize widgetClickedLast.originallySetFontSize - 1

