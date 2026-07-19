# The patch-programming palette -- ONE list for both homes (PatchProgrammingWdgt's
# docked column and PatchProgrammingComponentsToolbarCreatorButtonWdgt's floating
# window), per the one-variant-per-content-type rule (Frame-model plan §5.C).

class PatchProgrammingToolbarWdgt extends ToolbarWdgt

  _toolbarItems: -> [
    new TextBoxCreatorButtonWdgt
    new SliderNodeCreatorButtonWdgt

    new ColorPaletteNodeCreatorButtonWdgt
    new GrayscalePaletteNodeCreatorButtonWdgt
    new CalculatingNodeCreatorButtonWdgt
  ]
