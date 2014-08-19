# 


class SystemTestsCommandMouseUp extends SystemTestsCommand
  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    systemTestsRecorderAndPlayer.handMorph.processMouseUp()

  constructor: (systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandMouseUp"
