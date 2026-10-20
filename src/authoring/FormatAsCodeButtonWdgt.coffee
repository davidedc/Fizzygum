# Toggles the last-clicked widget's font between monospace and Arial, and shows active while that
# text is monospaced.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class FormatAsCodeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "format as code"

  createAppearance: -> new FormatAsCodeIconAppearance @, WorldWdgt.theme.toolbarGlyph

  activated: ->
    if world.editorFocusWdgt?.setFontName?
      widgetClickedLast = world.editorFocusWdgt
      if widgetClickedLast.fontName != widgetClickedLast.monoFontStack
        widgetClickedLast.setFontName widgetClickedLast.monoFontStack
      else
        widgetClickedLast.setFontName widgetClickedLast.justArialFontStack

  # ACTIVE while the text I act on is in its mono stack -- the very test my toggle above makes, so I
  # show active exactly when a press would set it back to Arial (the family's mirror)
  isActiveTool: ->
    focus = world.editorFocusWdgt
    focus?.setFontName? and focus.monoFontStack? and focus.fontName is focus.monoFontStack
