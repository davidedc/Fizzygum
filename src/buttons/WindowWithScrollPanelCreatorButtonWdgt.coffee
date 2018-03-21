class WindowWithScrollPanelCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new WindowWithScrollingPanelIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "link"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new ScrollPanelWdgt(), true, true
    switcherooWm.rawSetExtent new Point 200, 200
    return switcherooWm


