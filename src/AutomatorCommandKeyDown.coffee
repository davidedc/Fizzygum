# 


class AutomatorCommandKeyDown extends AutomatorCommand
  scanCode: null
  shiftKey: null
  ctrlKey: null
  altKey: null
  metaKey: null

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    console.log "replaying key"
    automatorRecorderAndPlayer.worldMorph.processKeydown null, commandBeingPlayed.scanCode, commandBeingPlayed.shiftKey, commandBeingPlayed.ctrlKey, commandBeingPlayed.altKey, commandBeingPlayed.metaKey


  constructor: (@scanCode, @shiftKey, @ctrlKey, @altKey, @metaKey, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandKeyDown"