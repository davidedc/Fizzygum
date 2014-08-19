# 


class SystemTestsCommandMouseMove extends SystemTestsCommand
  mouseX: null
  mouseY: null
  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    systemTestsRecorderAndPlayer.handMorph.processMouseMove(commandBeingPlayed.mouseX, commandBeingPlayed.mouseY)

  constructor: (@mouseX, @mouseY, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandMouseMove"
