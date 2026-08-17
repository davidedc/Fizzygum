class Plot3DCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "3D plot"

  # stated rather than derived: the camelCase split reads "3" and "D" as separate humps
  colloquialName: -> "3D plot creator button"

  createAppearance: -> new Plot3DIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new Example3DPlotWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


