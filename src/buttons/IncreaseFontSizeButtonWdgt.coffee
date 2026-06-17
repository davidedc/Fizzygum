# Steps the last-clicked widget's font size up through a fixed ladder.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class IncreaseFontSizeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  iconToolTipMessage: "increase font size"

  createAppearance: -> new IncreaseFontSizeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

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
