# Toggles the last-clicked widget's font between monospace and Arial, and shows active while that
# text is monospaced.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class FormatAsCodeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "format as code"

  # a font set by name: the mono stack, or Arial back from it
  verb: "setFontName"

  createAppearance: -> new FormatAsCodeIconAppearance @

  actOn: (subject) ->
    if subject.fontName != subject.monoFontStack
      subject.setFontName subject.monoFontStack
    else
      subject.setFontName subject.justArialFontStack

  # ACTIVE while the text I act on is in its mono stack -- the very test my toggle above makes, so I
  # show active exactly when a press would set it back to Arial (the family's mirror)
  isActiveTool: ->
    subject = @_subjectOfferingMyVerb()
    subject?.monoFontStack? and subject.fontName is subject.monoFontStack
