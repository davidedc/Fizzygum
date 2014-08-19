# 


class SystemTestsCommandCopy extends SystemTestsCommand

  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    systemTestsRecorderAndPlayer.worldMorph.processCopy null

  constructor: (@clipboardText, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandCopy"