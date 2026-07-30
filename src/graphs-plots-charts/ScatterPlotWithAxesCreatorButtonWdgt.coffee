class ScatterPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "scatter plot"

  createAppearance: -> new ScatterPlotIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new PlotWithAxesWdgt(new ExampleScatterPlotWdgt)
    switcherooWm._applyExtent new Point 200, 200

    return switcherooWm


