class WindowWithPanelCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new WindowWithCroppingPanelIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "cropping panel"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new PanelWdgt, true, true
    switcherooWm.rawSetExtent new Point 200, 200
    return switcherooWm


