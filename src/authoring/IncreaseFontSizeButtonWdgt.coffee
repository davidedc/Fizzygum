# Steps the last-clicked widget's font size up through a fixed ladder.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class IncreaseFontSizeButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "increase font size"

  # a stated font size, the one I step up from (setFontSize sets the next)
  verb: "originallySetFontSize"

  createAppearance: -> new IncreaseFontSizeIconAppearance @

  actOn: (subject) ->
    if subject.originallySetFontSize < 12
      subject.setFontSize subject.originallySetFontSize + 1
    else if subject.originallySetFontSize < 28
      subject.setFontSize subject.originallySetFontSize + 2
    else if subject.originallySetFontSize < 36
      subject.setFontSize 36
    else if subject.originallySetFontSize < 48
      subject.setFontSize 48
    else if subject.originallySetFontSize < 72
      subject.setFontSize 72
    else if subject.originallySetFontSize < 80
      subject.setFontSize 80
    else
      subject.setFontSize subject.originallySetFontSize + 10
