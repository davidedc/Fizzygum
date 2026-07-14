class SlidesToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "items for slides"

  createAppearance: -> new SlidesToolbarIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->

    toolsPanel = new SlidesToolPanelWdgt

    toolsPanel.disableDragsDropsAndEditing()

    return @_buildToolWindow toolsPanel, new Point 105, 300

