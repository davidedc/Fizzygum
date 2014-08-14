# 


class SystemTestsEventKeyPress extends SystemTestsEvent
  charCode: null
  symbol: null
  shiftKey: null
  ctrlKey: null
  altKey: null
  metaKey: null

  @replayFunction: (systemTestsRecorderAndPlayer, queuedEvent) ->
    console.log "replaying key"
    systemTestsRecorderAndPlayer.worldMorph.processKeypress null, queuedEvent.charCode, queuedEvent.symbol, queuedEvent.shiftKey, queuedEvent.ctrlKey, queuedEvent.altKey, queuedEvent.metaKey


  constructor: (@charCode, @symbol, @shiftKey, @ctrlKey, @altKey, @metaKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the event
    @type = "SystemTestsEventKeyPress"
