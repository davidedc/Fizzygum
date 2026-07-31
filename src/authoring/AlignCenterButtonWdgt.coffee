# Center-aligns the last-clicked widget (or its vertical-stack layout spec).
# See AlignButtonWdgt / EditorContentPropertyChangerButtonWdgt.

class AlignCenterButtonWdgt extends AlignButtonWdgt

  iconToolTipMessage: "align center"
  alignDirectMethod: "alignCenter"
  layoutAlignSetterMethod: "setAlignmentToCenter"

  createAppearance: -> new AlignCenterIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor
