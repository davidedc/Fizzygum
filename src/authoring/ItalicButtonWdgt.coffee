# Toggles italic on the last-clicked widget, and shows active while that text is italic.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class ItalicButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "italic"

  verb: "toggleItalic"

  createAppearance: -> new ItalicIconAppearance @

  # ACTIVE while the text I act on is italic: what I would undo if pressed (the family's mirror)
  isActiveTool: ->
    @_subjectOfferingMyVerb()?.isItalic is true
