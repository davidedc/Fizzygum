# Toggles the last-clicked widget's font between monospace and Arial.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class FormatAsCodeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "format as code"

  createAppearance: -> new FormatAsCodeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  activated: ->
    if world.editorFocusWdgt?.setFontName?
      widgetClickedLast = world.editorFocusWdgt
      if widgetClickedLast.fontName != widgetClickedLast.monoFontStack
        widgetClickedLast.setFontName widgetClickedLast.monoFontStack
      else
        widgetClickedLast.setFontName widgetClickedLast.justArialFontStack
