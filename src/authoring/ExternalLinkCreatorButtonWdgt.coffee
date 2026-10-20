class ExternalLinkCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "external link"

  createAppearance: -> new ExternalLinkIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->
    switcheroo = new SimpleLinkWdgt
    switcheroo._applyBounds @position(), new Point 330, 65
    return switcheroo


