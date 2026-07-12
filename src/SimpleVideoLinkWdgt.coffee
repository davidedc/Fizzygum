class SimpleVideoLinkWdgt extends SimpleLinkWdgt

  constructor: (@descriptionString, @linkString = "https://goo.gl/9xZrmG") ->
    super @descriptionString, @linkString

  _createLinkIcon: ->
    @externalLinkIcon = new VideoPlayButtonWdgt

