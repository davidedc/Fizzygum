# not used anymore, we are not showing morph geometry anymore


class AutomatorCommandTurnOffHidingOfMorphsGeometryInfoInLabels extends AutomatorCommand

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    automatorRecorderAndPlayer.turnOffHidingOfMorphsGeometryInfoInLabels()


  constructor: (automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandTurnOffHidingOfMorphsGeometryInfoInLabels"
