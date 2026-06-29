class ExternalLinkCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "external link"

  createAppearance: -> new ExternalLinkIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcheroo = new SimpleLinkWdgt
    switcheroo._applyMoveToAndNotify @position()
    switcheroo._applyExtentAndNotify new Point 330, 65
    return switcheroo


