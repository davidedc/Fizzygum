# 


class AutomatorCommandTurnOffHidingOfMorphsGeometryInfoInLabels extends AutomatorCommand

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    systemTestsRecorderAndPlayer.turnOffHidingOfMorphsGeometryInfoInLabels()


  constructor: (systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandTurnOffHidingOfMorphsGeometryInfoInLabels"
