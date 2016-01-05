# 


class AutomatorCommandMouseMove extends AutomatorCommand
  mouseX: null
  mouseY: null
  floatDraggingSomething: null
  button: null
  buttons: null
  ctrlKey: null
  shiftKey: null
  altKey: null
  metaKey: null

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    systemTestsRecorderAndPlayer.handMorph.processMouseMove \
      commandBeingPlayed.mouseX,
      commandBeingPlayed.mouseY,
      commandBeingPlayed.button,
      commandBeingPlayed.buttons,
      commandBeingPlayed.ctrlKey,
      commandBeingPlayed.shiftKey,
      commandBeingPlayed.altKey,
      commandBeingPlayed.metaKey

  constructor: (@mouseX, @mouseY, @floatDraggingSomething, @button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandMouseMove"
