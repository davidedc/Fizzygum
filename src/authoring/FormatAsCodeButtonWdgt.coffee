# Toggles the last-clicked widget's font between monospace and Arial, and shows active while that
# text is monospaced.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class FormatAsCodeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "format as code"

  # a font set by name: the mono stack, or Arial back from it
  verb: "setFontName"

  createAppearance: -> new FormatAsCodeIconAppearance @

  # the mono stack, or Arial back from it, then that font set
  _actOn: (subject) ->
    fontName = if subject.fontName != subject.monoFontStack then subject.monoFontStack else subject.justArialFontStack
    # settling-call-sanctioned: a press at event time, outside any pass (activated, my one caller): my
    #   subject's own public font setter settles it, a text's the text, a SheetCellStyle's its cell through its sheet
    subject.setFontName fontName

  # ACTIVE while the text I act on is in its mono stack -- the very test my toggle above makes, so I
  # show active exactly when a press would set it back to Arial (the family's mirror)
  isActiveTool: ->
    subject = @_subjectOfferingMyVerb()
    subject?.monoFontStack? and subject.fontName is subject.monoFontStack
