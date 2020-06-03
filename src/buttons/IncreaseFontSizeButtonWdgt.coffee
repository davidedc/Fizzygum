# REQUIRES Color

class IncreaseFontSizeButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new IncreaseFontSizeIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "increase font size"

  mouseClickLeft: ->

    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.originallySetFontSize?
      widgetClickedLast = world.lastNonTextPropertyChangerButtonClickedOrDropped
      if widgetClickedLast.originallySetFontSize < 12
        widgetClickedLast.setFontSize widgetClickedLast.originallySetFontSize + 1
      else if widgetClickedLast.originallySetFontSize < 28
        widgetClickedLast.setFontSize widgetClickedLast.originallySetFontSize + 2
      else if widgetClickedLast.originallySetFontSize < 36
        widgetClickedLast.setFontSize 36
      else if widgetClickedLast.originallySetFontSize < 48
        widgetClickedLast.setFontSize 48
      else if widgetClickedLast.originallySetFontSize < 72
        widgetClickedLast.setFontSize 72
      else if widgetClickedLast.originallySetFontSize < 80
        widgetClickedLast.setFontSize 80
      else
        widgetClickedLast.setFontSize widgetClickedLast.originallySetFontSize + 10



