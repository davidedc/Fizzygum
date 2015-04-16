# 


class AutomatorCommandMouseButtonChange extends AutomatorCommand
  upOrDownTrueUpFalseDown: null
  button: null
  ctrlKey: null
  morphIdentifierViaTextLabel: null
  pointerPositionFractionalInMorph: null
  pointerPositionPixelsInMorph: null
  pointerPositionPixelsInWorld: null
  absoluteBoundsOfMorphRelativeToWorld: null
  morphUniqueIDString: null
  morphPathRelativeToWorld: null

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    theMorph = world.getMorphViaTextLabel(commandBeingPlayed.morphIdentifierViaTextLabel)
    newX = (theMorph.bounds.width() * commandBeingPlayed.pointerPositionFractionalInMorph[0]) + theMorph.bounds.origin.x
    newY = (theMorph.bounds.height() * commandBeingPlayed.pointerPositionFractionalInMorph[1]) + theMorph.bounds.origin.y
    world.hand.silentSetPosition new Point(newX, newY)

    if commandBeingPlayed.upOrDownTrueUpFalseDown
      # the mouse up doesn't need the control key info
      systemTestsRecorderAndPlayer.handMorph.processMouseUp(commandBeingPlayed.button)
    else
      systemTestsRecorderAndPlayer.handMorph.processMouseDown(commandBeingPlayed.button, commandBeingPlayed.ctrlKey)

  transformIntoDoNothingCommand: ->
    @automatorCommandName = "AutomatorCommandDoNothing"

  constructor: (@upOrDownTrueUpFalseDown, @button, @ctrlKey, @morphUniqueIDString, @morphPathRelativeToWorld, @morphIdentifierViaTextLabel, @absoluteBoundsOfMorphRelativeToWorld, @pointerPositionFractionalInMorph, @pointerPositionPixelsInMorph, @pointerPositionPixelsInWorld, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandMouseButtonChange"
