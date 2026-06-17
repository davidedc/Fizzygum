# Left-aligns the last-clicked widget (or its vertical-stack layout spec).
# See AlignButtonWdgt / EditorContentPropertyChangerButtonWdgt.

class AlignLeftButtonWdgt extends AlignButtonWdgt

  iconToolTipMessage: "align left"
  alignDirectMethod: "alignLeft"
  layoutAlignSetterMethod: "setAlignmentToLeft"

  createAppearance: -> new AlignLeftIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor
