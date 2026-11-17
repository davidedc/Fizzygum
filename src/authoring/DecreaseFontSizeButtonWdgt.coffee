# Steps the last-clicked widget's font size down through a fixed ladder.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class DecreaseFontSizeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "decrease font size"

  # a stated font size, the one I step down from (setFontSize sets the next)
  verb: "originallySetFontSize"

  createAppearance: -> new DecreaseFontSizeIconAppearance @

  actOn: (subject) ->
    if subject.originallySetFontSize > 90
      subject.setFontSize subject.originallySetFontSize - 10
    else if subject.originallySetFontSize > 80
      subject.setFontSize 80
    else if subject.originallySetFontSize > 72
      subject.setFontSize 72
    else if subject.originallySetFontSize > 48
      subject.setFontSize 48
    else if subject.originallySetFontSize > 36
      subject.setFontSize 36
    else if subject.originallySetFontSize > 28
      subject.setFontSize 28
    else if subject.originallySetFontSize > 12
      subject.setFontSize subject.originallySetFontSize - 2
    else
      subject.setFontSize subject.originallySetFontSize - 1
