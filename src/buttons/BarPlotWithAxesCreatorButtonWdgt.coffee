class BarPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new BarPlotIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "bar plot"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleBarPlotWdgt()), true, true
    switcherooWm.rawSetExtent new Point 200, 200

    return switcherooWm
