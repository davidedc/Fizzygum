class CalculatingNodeCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new CalculatingNodeIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "link"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new CalculatingPatchNodeWdgt(), true
    switcherooWm.rawSetExtent new Point 260, 265
    return switcherooWm
