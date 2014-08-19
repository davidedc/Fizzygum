# 


class SystemTestsCommandPaste extends SystemTestsCommand
  clipboardText: null

  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    console.log "test player inserting text: " + queuedCommand.clipboardText
    systemTestsRecorderAndPlayer.worldMorph.processPaste null, queuedCommand.clipboardText


  constructor: (@clipboardText, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandPaste"