# The Super toolbar's entry for Draw's paint toolbar (PaintToolbarWdgt): a click (or a drag out) opens it
# floating, arming its tools for whichever drawing is in reach. Its face is Draw's desktop icon, the spray
# can, in the toolbar's ink.

class PaintToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Paint tools"

  createAppearance: -> new SprayCanIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->
    @_buildToolWindow new PaintToolbarWdgt
