# Steps the last-clicked widget's font size up through a fixed ladder.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class IncreaseFontSizeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "increase font size"

  # a stated font size, the one I step up from (setFontSize sets the next)
  verb: "originallySetFontSize"

  createAppearance: -> new IncreaseFontSizeIconAppearance @

  # the next size up the ladder from the stated one, then that size set
  _actOn: (subject) ->
    size = subject.originallySetFontSize
    if size < 12
      nextSize = size + 1
    else if size < 28
      nextSize = size + 2
    else if size < 36
      nextSize = 36
    else if size < 48
      nextSize = 48
    else if size < 72
      nextSize = 72
    else if size < 80
      nextSize = 80
    else
      nextSize = size + 10
    # settling-call-sanctioned: a press at event time, outside any pass (activated, my one caller): my
    #   subject's own public size setter settles it, a text's the text, a SheetCellStyle's its cell through its sheet
    subject.setFontSize nextSize
