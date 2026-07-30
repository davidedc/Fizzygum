# The dashboard-authoring palette -- DashboardsWdgt's tool column (docked-only
# today; the class is home-agnostic like every ToolbarWdgt).

class DashboardsToolbarWdgt extends ToolbarWdgt

  # The plot tools and the map tools belong to the LAZY 'plots' and 'maps' parts, so they are absent
  # on a profile without them and not yet here on a profile that has them but has not loaded them
  # (the hosting app awaits both when it launches, so a docked palette has the lot). Filtering the
  # LIST is what keeps the palette's ORDER intact when some are missing -- appending them behind a
  # guard would silently reshuffle the whole strip.
  _toolbarItems: ->
    items = [
      new TextBoxCreatorButtonWdgt
      new ExternalLinkCreatorButtonWdgt

      (new ScatterPlotWithAxesCreatorButtonWdgt  if ScatterPlotWithAxesCreatorButtonWdgt?)
      (new FunctionPlotWithAxesCreatorButtonWdgt if FunctionPlotWithAxesCreatorButtonWdgt?)
      (new BarPlotWithAxesCreatorButtonWdgt      if BarPlotWithAxesCreatorButtonWdgt?)
      (new Plot3DCreatorButtonWdgt               if Plot3DCreatorButtonWdgt?)

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
