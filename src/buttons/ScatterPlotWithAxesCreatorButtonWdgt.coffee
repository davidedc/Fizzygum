class ScatterPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "scatter plot"

  createAppearance: -> new ScatterPlotIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleScatterPlotWdgt), true, true
    switcherooWm._applyExtent new Point 200, 200

    return switcherooWm


