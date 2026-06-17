# Steps the last-clicked widget's font size down through a fixed ladder.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class DecreaseFontSizeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  iconToolTipMessage: "decrease font size"

  createAppearance: -> new DecreaseFontSizeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

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
