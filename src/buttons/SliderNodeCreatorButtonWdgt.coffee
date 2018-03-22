class SliderNodeCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new SliderNodeIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "slider node"

  createWidgetToBeHandled: ->
    switcherooWdgt = new SliderMorph nil, nil, nil, nil, nil, true
    return switcherooWdgt


