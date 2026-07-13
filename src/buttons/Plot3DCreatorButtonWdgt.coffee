class Plot3DCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "3D plot"

  createAppearance: -> new Plot3DIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt new Example3DPlotWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


