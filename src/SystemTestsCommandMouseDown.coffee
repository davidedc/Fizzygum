# 


class SystemTestsCommandMouseDown extends SystemTestsCommand
  button: null
  ctrlKey: null
  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    systemTestsRecorderAndPlayer.handMorph.processMouseDown(commandBeingPlayed.button, commandBeingPlayed.ctrlKey)


  constructor: (@button, @ctrlKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandMouseDown"
