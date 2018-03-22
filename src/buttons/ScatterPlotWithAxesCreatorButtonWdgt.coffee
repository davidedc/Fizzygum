class ScatterPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new ScatterPlotIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "scatter plot"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleScatterPlotWdgt()), true, true
    switcherooWm.rawSetExtent new Point 200, 200

    return switcherooWm


