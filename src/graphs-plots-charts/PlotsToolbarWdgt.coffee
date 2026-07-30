# The plots/graphs palette (floating home: PlotsToolbarCreatorButtonWdgt).

class PlotsToolbarWdgt extends ToolbarWdgt

  _toolbarItems: -> [
    new ScatterPlotWithAxesCreatorButtonWdgt
    new FunctionPlotWithAxesCreatorButtonWdgt
    new BarPlotWithAxesCreatorButtonWdgt
    new Plot3DCreatorButtonWdgt
  ]
