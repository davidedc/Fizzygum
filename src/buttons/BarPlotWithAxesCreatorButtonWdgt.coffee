class BarPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new BarPlotIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "link"

  createWidgetToBeHandled: ->
    exampleScatterPlot = new ExampleBarPlotWdgt()
    switcherooWm = new PlotWithAxesWdgt exampleScatterPlot
    switcherooWm.rawSetExtent new Point 200, 200

    return switcherooWm
