# 


class SystemTestsEventKeyDown extends SystemTestsEvent
  button: null
  ctrlKey: null
  @replayFunction: (systemTestsRecorderAndPlayer, queuedEvent) ->
    systemTestsRecorderAndPlayer.handMorph.processMouseDown(queuedEvent.button, queuedEvent.ctrlKey)


  constructor: (@button, @ctrlKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the event
    @type = "SystemTestsEventKeyDown"
