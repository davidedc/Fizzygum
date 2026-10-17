class ScatterPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "scatter plot"

  createAppearance: -> new ScatterPlotIconAppearance @, WorldWdgt.theme.iconInk

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new PlotWithAxesWdgt(new ExampleScatterPlotWdgt)
    switcherooWm._applyExtent new Point 200, 200

    return switcherooWm


