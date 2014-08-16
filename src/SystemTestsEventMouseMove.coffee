# 


class SystemTestsEventMouseMove extends SystemTestsEvent
  mouseX: null
  mouseY: null
  @replayFunction: (systemTestsRecorderAndPlayer, queuedEvent) ->
    systemTestsRecorderAndPlayer.handMorph.processMouseMove(queuedEvent.mouseX, queuedEvent.mouseY)

  constructor: (@mouseX, @mouseY, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the event
    @testCommand = "SystemTestsEventMouseMove"
