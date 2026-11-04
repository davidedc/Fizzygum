# Shows the selected spreadsheet cell's number with one decimal place more (SheetCellStyle.moreDecimals):
# a display format, the value itself unchanged. See EditorContentPropertyChangerButtonWdgt for the shared
# family contract.

class MoreDecimalsButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "more decimals"

  createAppearance: -> new MoreDecimalsIconAppearance @, WorldWdgt.theme.toolbarGlyph

  activated: ->
    @_styleSubject()?.moreDecimals?()
    return
