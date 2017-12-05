# 


class AutomatorCommandKeyUp extends AutomatorCommand
  scanCode: nil
  shiftKey: nil
  ctrlKey: nil
  altKey: nil
  metaKey: nil

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    console.log "replaying key"
    automatorRecorderAndPlayer.worldMorph.processKeyup nil, commandBeingPlayed.scanCode, commandBeingPlayed.shiftKey, commandBeingPlayed.ctrlKey, commandBeingPlayed.altKey, commandBeingPlayed.metaKey


  constructor: (@scanCode, @shiftKey, @ctrlKey, @altKey, @metaKey, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandKeyUp"
