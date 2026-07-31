# Toggles italic on the last-clicked widget.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class ItalicButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  iconToolTipMessage: "italic"

  createAppearance: -> new ItalicIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  mouseClickLeft: ->
    if world.editorFocusWdgt?.toggleItalic?
      world.editorFocusWdgt.toggleItalic()
