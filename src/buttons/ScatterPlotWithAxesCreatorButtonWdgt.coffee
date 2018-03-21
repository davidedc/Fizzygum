class ScatterPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new ScatterPlotIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "link"

  createWidgetToBeHandled: ->

    exampleScatterPlot = new ExampleScatterPlotWdgt()
    switcherooWm = new PlotWithAxesWdgt exampleScatterPlot
    switcherooWm.rawSetExtent new Point 200, 200

    return switcherooWm


