# The dashboard-authoring palette -- DashboardsWdgt's tool column (docked-only
# today; the class is home-agnostic like every ToolbarWdgt).

class DashboardsToolbarWdgt extends ToolbarWdgt

  # The two map tools belong to the LAZY 'maps' part, so they are absent on a profile without it
  # and not yet here on a profile that has it but has not loaded it (the hosting app awaits the
  # load when it launches, so a docked palette has them). Filtering the LIST is what keeps the
  # palette's ORDER intact when they are missing -- appending them behind a guard would silently
  # reshuffle the whole strip.
  _toolbarItems: ->
    items = [
      new TextBoxCreatorButtonWdgt
      new ExternalLinkCreatorButtonWdgt

      new ScatterPlotWithAxesCreatorButtonWdgt
      new FunctionPlotWithAxesCreatorButtonWdgt
      new BarPlotWithAxesCreatorButtonWdgt
      new Plot3DCreatorButtonWdgt

      (new WorldMapCreatorButtonWdgt if WorldMapCreatorButtonWdgt?)
      (new USAMapCreatorButtonWdgt   if USAMapCreatorButtonWdgt?)
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
    (eachItem for eachItem in items when eachItem?)
