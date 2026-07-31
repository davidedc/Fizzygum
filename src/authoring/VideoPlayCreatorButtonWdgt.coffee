class VideoPlayCreatorButtonWdgt extends ExternalLinkCreatorButtonWdgt

  iconToolTipMessage: "link to video"

  createAppearance: -> new VideoPlayIconAppearance @

  # keeps a constructor only to capture @color (the base ctor takes none); the
  # base then sets @appearance via createAppearance + the tooltip after super.
  constructor: (@color) ->
    super

  createWidgetToBeHandled: ->
    switcheroo = new SimpleVideoLinkWdgt
    switcheroo._applyBounds @position(), new Point 330, 65
    return switcheroo
