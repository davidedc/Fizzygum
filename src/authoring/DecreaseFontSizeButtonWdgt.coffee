# Steps the last-clicked widget's font size down through a fixed ladder.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class DecreaseFontSizeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "decrease font size"

  # a stated font size, the one I step down from (setFontSize sets the next)
  verb: "originallySetFontSize"

  createAppearance: -> new DecreaseFontSizeIconAppearance @

  # the next size down the ladder from the stated one, then that size set
  _actOn: (subject) ->
    size = subject.originallySetFontSize
    if size > 90
      nextSize = size - 10
    else if size > 80
      nextSize = 80
    else if size > 72
      nextSize = 72
    else if size > 48
      nextSize = 48
    else if size > 36
      nextSize = 36
    else if size > 28
      nextSize = 28
    else if size > 12
      nextSize = size - 2
    else
      nextSize = size - 1
    # settling-call-sanctioned: a press at event time, outside any pass (activated, my one caller): my
    #   subject's own public size setter settles it, a text's the text, a SheetCellStyle's its cell through its sheet
    subject.setFontSize nextSize
