# Toggles the last-clicked widget's font between monospace and Arial.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class FormatAsCodeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  iconToolTipMessage: "format as code"

  createAppearance: -> new FormatAsCodeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  mouseClickLeft: ->
    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.setFontName?
      widgetClickedLast = world.lastNonTextPropertyChangerButtonClickedOrDropped
      if widgetClickedLast.fontName != widgetClickedLast.monoFontStack
        widgetClickedLast.setFontName nil, nil, widgetClickedLast.monoFontStack
      else
        widgetClickedLast.setFontName nil, nil, widgetClickedLast.justArialFontStack
