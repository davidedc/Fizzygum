# Toggles bold on the last-clicked widget.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class BoldButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "bold"

  createAppearance: -> new BoldIconAppearance @, WorldWdgt.theme.iconInk

  activated: ->
    if world.editorFocusWdgt?.toggleWeight?
      world.editorFocusWdgt.toggleWeight()
