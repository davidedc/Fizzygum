class FunctionPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "function plot"

  createAppearance: -> new FunctionPlotIconAppearance @, WorldWdgt.theme.iconInk

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new PlotWithAxesWdgt(new ExampleFunctionPlotWdgt)
    switcherooWm._applyExtent new Point 200, 200

    return switcherooWm


