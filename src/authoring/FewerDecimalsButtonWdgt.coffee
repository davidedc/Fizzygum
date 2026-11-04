# Shows the selected spreadsheet cell's number with one decimal place fewer (SheetCellStyle.fewerDecimals):
# a display format, the value itself unchanged. See EditorContentPropertyChangerButtonWdgt for the shared
# family contract.

class FewerDecimalsButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "fewer decimals"

  createAppearance: -> new FewerDecimalsIconAppearance @, WorldWdgt.theme.toolbarGlyph

  activated: ->
    @_styleSubject()?.fewerDecimals?()
    return
