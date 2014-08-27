# 


class SystemTestsCommandTurnOnHidingOfMorphsGeometryInfoInLabels extends SystemTestsCommand

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    systemTestsRecorderAndPlayer.turnOnHidingOfMorphsGeometryInfoInLabels()


  constructor: (systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandTurnOnHidingOfMorphsGeometryInfoInLabels"
