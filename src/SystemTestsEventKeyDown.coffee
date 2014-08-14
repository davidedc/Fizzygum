# 


class SystemTestsEventKeyDown extends SystemTestsEvent
  scanCode: null
  shiftKey: null
  ctrlKey: null
  altKey: null
  metaKey: null

  @replayFunction: (systemTestsRecorderAndPlayer, queuedEvent) ->
    console.log "replaying key"
    systemTestsRecorderAndPlayer.worldMorph.processKeydown null, queuedEvent.scanCode, queuedEvent.shiftKey, queuedEvent.ctrlKey, queuedEvent.altKey, queuedEvent.metaKey


  constructor: (@scanCode, @shiftKey, @ctrlKey, @altKey, @metaKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the event
    @type = "SystemTestsEventKeyDown"