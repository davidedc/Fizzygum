# The Super toolbar's entry for the spreadsheet's toolbar (SheetToolbarWdgt): a click (or a drag out)
# opens it floating, acting on whichever sheet is the editor focus. Its face is Sheets Maker's desktop
# icon in the toolbar's ink, the Maker the toolbar belongs to.

class SheetToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Sheet tools"

  createAppearance: -> new SpreadsheetIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->
    @_buildToolWindow new SheetToolbarWdgt
