# 


class AutomatorCommandPaste extends AutomatorCommand
  clipboardText: nil

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    console.log "test player inserting text: " + commandBeingPlayed.clipboardText
    automatorRecorderAndPlayer.worldMorph.processPaste commandBeingPlayed.clipboardText


  constructor: (@clipboardText, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandPaste"