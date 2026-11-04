# Toggles bold on the last-clicked widget, and shows active while that text is bold.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class BoldButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "bold"

  createAppearance: -> new BoldIconAppearance @, WorldWdgt.theme.toolbarGlyph

  activated: ->
    @_styleSubject()?.toggleWeight?()
    return

  # ACTIVE while the text I act on is bold: what I would undo if pressed (the family's mirror)
  isActiveTool: ->
    focus = @_styleSubject()
    focus?.toggleWeight? and focus.isBold is true
