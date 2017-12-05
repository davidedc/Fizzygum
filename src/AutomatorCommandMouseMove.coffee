# 


class AutomatorCommandMouseMove extends AutomatorCommand
  mouseX: nil
  mouseY: nil
  floatDraggingSomething: nil
  button: nil
  buttons: nil
  ctrlKey: nil
  shiftKey: nil
  altKey: nil
  metaKey: nil

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    automatorRecorderAndPlayer.handMorph.processMouseMove \
      commandBeingPlayed.mouseX,
      commandBeingPlayed.mouseY,
      commandBeingPlayed.button,
      commandBeingPlayed.buttons,
      commandBeingPlayed.ctrlKey,
      commandBeingPlayed.shiftKey,
      commandBeingPlayed.altKey,
      commandBeingPlayed.metaKey

  constructor: (@mouseX, @mouseY, @floatDraggingSomething, @button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandMouseMove"
