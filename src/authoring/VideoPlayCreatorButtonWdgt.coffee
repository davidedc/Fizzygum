class VideoPlayCreatorButtonWdgt extends ExternalLinkCreatorButtonWdgt

  toolTipMessage: "link to video"

  createAppearance: -> new VideoPlayIconAppearance @

  createWidgetToBeHandled: ->
    switcheroo = new SimpleVideoLinkWdgt
    switcheroo._applyBounds @position(), new Point 330, 65
    return switcheroo
