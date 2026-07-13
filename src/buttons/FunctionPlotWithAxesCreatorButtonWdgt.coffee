class FunctionPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "function plot"

  createAppearance: -> new FunctionPlotIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt new PlotWithAxesWdgt(new ExampleFunctionPlotWdgt)
    switcherooWm._applyExtent new Point 200, 200

    return switcherooWm


