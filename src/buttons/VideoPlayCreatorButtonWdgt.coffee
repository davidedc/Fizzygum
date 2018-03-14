class VideoPlayCreatorButtonWdgt extends ExternalLinkCreatorButtonWdgt

  constructor: (@color) ->
    super
    @appearance = new VideoPlayIconAppearance @
    @toolTipMessage = "link to video"

  grabbedWidgetSwitcheroo: ->
    switcheroo = new SimpleVideoLinkWdgt()
    switcheroo.fullRawMoveTo @position()
    switcheroo.rawSetExtent new Point 330, 65
    return switcheroo
