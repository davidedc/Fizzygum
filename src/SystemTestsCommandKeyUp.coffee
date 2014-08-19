# 


class SystemTestsCommandKeyUp extends SystemTestsCommand
  scanCode: null
  shiftKey: null
  ctrlKey: null
  altKey: null
  metaKey: null

  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    console.log "replaying key"
    systemTestsRecorderAndPlayer.worldMorph.processKeyup null, queuedCommand.scanCode, queuedCommand.shiftKey, queuedCommand.ctrlKey, queuedCommand.altKey, queuedCommand.metaKey


  constructor: (@scanCode, @shiftKey, @ctrlKey, @altKey, @metaKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandKeyUp"
