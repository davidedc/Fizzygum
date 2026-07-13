class BarPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "bar plot"

  createAppearance: -> new BarPlotIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt new PlotWithAxesWdgt(new ExampleBarPlotWdgt)
    switcherooWm._applyExtent new Point 200, 200

    return switcherooWm
