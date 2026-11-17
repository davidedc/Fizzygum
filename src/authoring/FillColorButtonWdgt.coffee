# Fills the selected spreadsheet cell with a colour: the sheet toolbar's fill tool. It asks the colour
# prompt for the colour (SheetCellStyle.pickFillColor), and has nothing to act on while the editor
# focus hands over no fill (a text, say). See EditorContentPropertyChangerButtonWdgt for the shared
# family contract.

class FillColorButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "fill color"

  verb: "pickFillColor"

  createAppearance: -> new PaintBucketIconAppearance @
