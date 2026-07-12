class PatchProgrammingWdgt extends StretchableEditableWdgt

  colloquialName: ->
    "Patch Programming"

  representativeIcon: ->
    new PatchProgrammingIconWdgt


  _createToolsPanelNoSettle: ->
    # tools -------------------------------
    @toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    @toolsPanel._addManyNoSettle [
      new TextBoxCreatorButtonWdgt
      new SliderNodeCreatorButtonWdgt

      new ColorPaletteNodeCreatorButtonWdgt
      new GrayscalePaletteNodeCreatorButtonWdgt
      new CalculatingNodeCreatorButtonWdgt
    ]

    @toolsPanel._disableDragsDropsAndEditingNoSettle()
    @_addNoSettle @toolsPanel
    @dragsDropsAndEditingEnabled = true
    @_invalidateLayout()

  createNewStretchablePanel: ->
    @stretchableWidgetContainer = new StretchableWidgetContainerWdgt
    @add @stretchableWidgetContainer


  # (_reLayoutSelf is inherited from StretchableEditableWdgt — the byte-identical
  # Dashboards/PatchProgramming/SimpleSlide copies were hoisted there 2026-07-12.)

