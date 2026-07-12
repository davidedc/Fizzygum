class DashboardsWdgt extends StretchableEditableWdgt

  colloquialName: ->
    "Dashboards Maker"

  representativeIcon: ->
    new DashboardsIconWdgt


  _createToolsPanelNoSettle: ->
    # tools -------------------------------
    @toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    @toolsPanel._addManyNoSettle [
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



    @toolsPanel._disableDragsDropsAndEditingNoSettle()
    @_addNoSettle @toolsPanel
    @dragsDropsAndEditingEnabled = true
    @_invalidateLayout()

  # (_createNewStretchablePanelNoSettle is inherited from StretchableEditableWdgt — this class's
  # createNewStretchablePanel override was a byte-identical copy of the base and was deleted in the
  # rule-[S] convert, like the hoisted _reLayoutSelf below.)

  # (_reLayoutSelf is inherited from StretchableEditableWdgt — the byte-identical
  # Dashboards/PatchProgramming/SimpleSlide copies were hoisted there 2026-07-12.)

