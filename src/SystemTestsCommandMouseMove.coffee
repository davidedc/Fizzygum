# 


class SystemTestsCommandMouseMove extends SystemTestsCommand
  mouseX: null
  mouseY: null
  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    systemTestsRecorderAndPlayer.handMorph.processMouseMove(queuedCommand.mouseX, queuedCommand.mouseY)

  constructor: (@mouseX, @mouseY, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandMouseMove"
