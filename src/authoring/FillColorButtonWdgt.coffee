# Fills the selected spreadsheet cell with a colour: the sheet toolbar's fill tool. It asks the colour
# prompt for the colour (SheetCellStyle.pickFillColor), and does nothing while the editor focus hands
# over no fill (a text, say). See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class FillColorButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "fill color"

  createAppearance: -> new PaintBucketIconAppearance @, WorldWdgt.theme.toolbarGlyph

  activated: ->
    @_styleSubject()?.pickFillColor?()
    return
