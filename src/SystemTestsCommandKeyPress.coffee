# 


class SystemTestsCommandKeyPress extends SystemTestsCommand
  charCode: null
  symbol: null
  shiftKey: null
  ctrlKey: null
  altKey: null
  metaKey: null

  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    console.log "replaying key"
    systemTestsRecorderAndPlayer.worldMorph.processKeypress null, queuedCommand.charCode, queuedCommand.symbol, queuedCommand.shiftKey, queuedCommand.ctrlKey, queuedCommand.altKey, queuedCommand.metaKey


  constructor: (@charCode, @symbol, @shiftKey, @ctrlKey, @altKey, @metaKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandKeyPress"
