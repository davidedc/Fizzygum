# 


class AutomatorCommandPaste extends AutomatorCommand
  clipboardText: null

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    console.log "test player inserting text: " + commandBeingPlayed.clipboardText
    systemTestsRecorderAndPlayer.worldMorph.processPaste null, commandBeingPlayed.clipboardText


  constructor: (@clipboardText, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandPaste"