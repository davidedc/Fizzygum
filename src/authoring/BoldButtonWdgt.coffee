# Toggles bold on the last-clicked widget, and shows active while that text is bold.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class BoldButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "bold"

  verb: "toggleWeight"

  createAppearance: -> new BoldIconAppearance @

  # ACTIVE while the text I act on is bold: what I would undo if pressed (the family's mirror)
  isActiveTool: ->
    @_subjectOfferingMyVerb()?.isBold is true
