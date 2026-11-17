# Right-aligns the last-clicked widget (or its vertical-stack layout spec).
# See AlignButtonWdgt / EditorContentPropertyChangerButtonWdgt.

class AlignRightButtonWdgt extends AlignButtonWdgt

  toolTipMessage: "align right"
  verb: "alignRight"
  layoutAlignSetterMethod: "setAlignmentToRight"
  horizontalAlignmentName: "RIGHT"

  createAppearance: -> new AlignRightIconAppearance @
