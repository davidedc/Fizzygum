class PatchProgrammingComponentsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "components that can be connected"

  createAppearance: -> new PatchProgrammingComponentsIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    # the ONE patch-programming list (§5.C): this floating palette shares
    # PatchProgrammingWdgt's docked one, incl. the text-box creator
    @_buildToolWindow new PatchProgrammingToolbarWdgt, new Point 61, 192

