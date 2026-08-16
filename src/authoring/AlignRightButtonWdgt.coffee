# Right-aligns the last-clicked widget (or its vertical-stack layout spec).
# See AlignButtonWdgt / EditorContentPropertyChangerButtonWdgt.

class AlignRightButtonWdgt extends AlignButtonWdgt

  toolTipMessage: "align right"
  alignDirectMethod: "alignRight"
  layoutAlignSetterMethod: "setAlignmentToRight"

  createAppearance: -> new AlignRightIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor
