class ExternalLinkCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new ExternalLinkIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "external link"

  createWidgetToBeHandled: ->
    switcheroo = new SimpleLinkWdgt
    switcheroo.fullRawMoveTo @position()
    switcheroo.rawSetExtent new Point 330, 65
    return switcheroo


