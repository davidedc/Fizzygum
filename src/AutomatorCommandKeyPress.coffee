# 


class AutomatorCommandKeyPress extends AutomatorCommand
  charCode: null
  symbol: null
  shiftKey: null
  ctrlKey: null
  altKey: null
  metaKey: null

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    console.log "replaying key"
    systemTestsRecorderAndPlayer.worldMorph.processKeypress null, commandBeingPlayed.charCode, commandBeingPlayed.symbol, commandBeingPlayed.shiftKey, commandBeingPlayed.ctrlKey, commandBeingPlayed.altKey, commandBeingPlayed.metaKey


  constructor: (@charCode, @symbol, @shiftKey, @ctrlKey, @altKey, @metaKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandKeyPress"
