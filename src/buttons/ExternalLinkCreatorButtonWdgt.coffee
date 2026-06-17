class ExternalLinkCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "external link"

  createAppearance: -> new ExternalLinkIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcheroo = new SimpleLinkWdgt
    switcheroo.fullRawMoveTo @position()
    switcheroo.rawSetExtent new Point 330, 65
    return switcheroo


