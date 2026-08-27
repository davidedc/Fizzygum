# Toggles italic on the last-clicked widget.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class ItalicButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "italic"

  createAppearance: -> new ItalicIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  activated: ->
    if world.editorFocusWdgt?.toggleItalic?
      world.editorFocusWdgt.toggleItalic()
