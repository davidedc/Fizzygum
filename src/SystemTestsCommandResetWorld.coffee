# 

class SystemTestsCommandResetWorld extends SystemTestsCommand

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    systemTestsRecorderAndPlayer.worldMorph.destroyAll()
    # some tests might change the background
    # color of the world so let's reset it.
    systemTestsRecorderAndPlayer.worldMorph.setColor(new Color(205, 205, 205))

  constructor: (systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandResetWorld"
