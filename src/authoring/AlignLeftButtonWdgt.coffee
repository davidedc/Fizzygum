# Left-aligns the last-clicked widget (or its vertical-stack layout spec).
# See AlignButtonWdgt / EditorContentPropertyChangerButtonWdgt.

class AlignLeftButtonWdgt extends AlignButtonWdgt

  toolTipMessage: "align left"
  alignDirectMethod: "alignLeft"
  layoutAlignSetterMethod: "setAlignmentToLeft"
  horizontalAlignmentName: "LEFT"

  createAppearance: -> new AlignLeftIconAppearance @, WorldWdgt.theme.toolbarGlyph
