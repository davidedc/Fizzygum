# Toggles bold on the last-clicked widget.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class BoldButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  iconToolTipMessage: "bold"

  createAppearance: -> new BoldIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  mouseClickLeft: ->
    if world.editorFocusWdgt?.toggleWeight?
      world.editorFocusWdgt.toggleWeight()
