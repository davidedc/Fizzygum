# this is just the same as the "generic panel"

class ElasticWindowCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new ElasticWindowIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "elastic panel"

  createWidgetToBeHandled: ->
    genericPanel = new StretchableEditableWdgt
    switcherooWm = new WindowWdgt nil, nil, genericPanel, true, true
    switcherooWm.setTitleWithoutPrependedContentName "elastic panel"
    switcherooWm.rawSetExtent new Point 200, 200

    return switcherooWm


