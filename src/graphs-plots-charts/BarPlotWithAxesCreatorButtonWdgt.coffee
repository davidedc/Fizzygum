class BarPlotWithAxesCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "bar plot"

  createAppearance: -> new BarPlotIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new PlotWithAxesWdgt(new ExampleBarPlotWdgt)
    switcherooWm._applyExtent new Point 200, 200

    return switcherooWm
