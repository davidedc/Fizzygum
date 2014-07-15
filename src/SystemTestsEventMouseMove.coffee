# 


class SystemTestsEventMouseMove extends SystemTestsEvent
  button: null
  ctrlKey: null
  mouseX: null
  mouseY: null



  constructor: (pageX, pageY, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    @type = "mouseMove"
    @mouseX = pageX
    @mouseY = pageY
