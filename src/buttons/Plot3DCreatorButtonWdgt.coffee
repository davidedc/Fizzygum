class Plot3DCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "3D plot"

  createAppearance: -> new Plot3DIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new Example3DPlotWdgt, true, true
    switcherooWm.rawSetExtent new Point 200, 200
    return switcherooWm


