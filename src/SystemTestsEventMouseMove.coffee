# 


class SystemTestsEventMouseMove extends SystemTestsEvent
  mouseX: null
  mouseY: null

  constructor: (@mouseX, @mouseY, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    @type = "mouseMove"
