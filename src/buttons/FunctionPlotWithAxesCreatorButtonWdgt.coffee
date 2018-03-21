class FunctionPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new FunctionPlotIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "link"

  createWidgetToBeHandled: ->

    exampleScatterPlot = new ExampleFunctionPlotWdgt()
    switcherooWm = new PlotWithAxesWdgt exampleScatterPlot
    switcherooWm.rawSetExtent new Point 200, 200

    return switcherooWm


