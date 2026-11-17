# Center-aligns the last-clicked widget (or its vertical-stack layout spec).
# See AlignButtonWdgt / EditorContentPropertyChangerButtonWdgt.

class AlignCenterButtonWdgt extends AlignButtonWdgt

  toolTipMessage: "align center"
  verb: "alignCenter"
  layoutAlignSetterMethod: "setAlignmentToCenter"
  horizontalAlignmentName: "CENTER"

  createAppearance: -> new AlignCenterIconAppearance @
