class EmptyWindowCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new EmptyWindowIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "link"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, nil, true, true
    switcherooWm.rawSetExtent new Point 200, 200
    return switcherooWm


