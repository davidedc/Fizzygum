# 


class SystemTestsEventPaste extends SystemTestsEvent
  clipboardText: null

  @replayFunction: (systemTestsRecorderAndPlayer, queuedEvent) ->
    console.log "test player inserting text: " + queuedEvent.clipboardText
    systemTestsRecorderAndPlayer.worldMorph.processPaste null, queuedEvent.clipboardText


  constructor: (@clipboardText, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the event
    @testCommand = "SystemTestsEventPaste"