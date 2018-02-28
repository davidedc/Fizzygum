class SimpleVideoLinkWdgt extends SimpleLinkWdgt

  constructor: (@descriptionString, @linkString = "https://www.youtube.com/watch?v=cU8HrO7XuiE") ->
    super @descriptionString, @linkString

  createLinkIcon: ->
    @externalLinkIcon = new VideoPlayButtonWdgt()

