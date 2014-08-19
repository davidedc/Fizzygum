# 


class SystemTestsCommandMouseDown extends SystemTestsCommand
  button: null
  ctrlKey: null
  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    systemTestsRecorderAndPlayer.handMorph.processMouseDown(queuedCommand.button, queuedCommand.ctrlKey)


  constructor: (@button, @ctrlKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandMouseDown"
