# 


class AutomatorCommandCopy extends AutomatorCommand

  clipboardText: ""

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    systemTestsRecorderAndPlayer.worldMorph.processCopy null, commandBeingPlayed.clipboardText

  constructor: (@clipboardText, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandCopy"