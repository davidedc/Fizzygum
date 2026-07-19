# The dashboard-authoring palette -- DashboardsWdgt's tool column (docked-only
# today; the class is home-agnostic like every ToolbarWdgt).

class DashboardsToolbarWdgt extends ToolbarWdgt

  _toolbarItems: -> [
    new TextBoxCreatorButtonWdgt
    new ExternalLinkCreatorButtonWdgt

    new ScatterPlotWithAxesCreatorButtonWdgt
    new FunctionPlotWithAxesCreatorButtonWdgt
    new BarPlotWithAxesCreatorButtonWdgt
    new Plot3DCreatorButtonWdgt

    new WorldMapCreatorButtonWdgt
    new USAMapCreatorButtonWdgt
    new MapPinIconWdgt

    new SpeechBubbleWdgt

    new ArrowNIconWdgt
    new ArrowSIconWdgt
    new ArrowWIconWdgt
    new ArrowEIconWdgt
    new ArrowNWIconWdgt
    new ArrowNEIconWdgt
    new ArrowSWIconWdgt
    new ArrowSEIconWdgt
  ]
