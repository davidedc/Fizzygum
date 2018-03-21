class ExternalLinkCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new ExternalLinkIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "link"

  createWidgetToBeHandled: ->
    switcheroo = new SimpleLinkWdgt()
    switcheroo.fullRawMoveTo @position()
    switcheroo.rawSetExtent new Point 330, 65
    return switcheroo


