class Plot3DCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new Plot3DIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "3D plot"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new Example3DPlotWdgt(), true, true
    switcherooWm.rawSetExtent new Point 200, 200
    return switcherooWm


