# 


class AutomatorCommandMouseButtonChange extends AutomatorCommand
  upOrDown: null
  button: null
  ctrlKey: null
  morphIdentifierViaTextLabel: null
  pointerPositionFractionalInMorph: null
  pointerPositionPixelsInMorph: null
  pointerPositionPixelsInWorld: null
  absoluteBoundsOfMorphRelativeToWorld: null
  morphUniqueIDString: null
  morphPathRelativeToWorld: null
  isPartOfListMorph: null

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    theMorph = world.getMorphViaTextLabel(commandBeingPlayed.morphIdentifierViaTextLabel)
    newX = Math.round((theMorph.width() * commandBeingPlayed.pointerPositionFractionalInMorph[0])) + theMorph.left()
    newY = Math.round((theMorph.height() * commandBeingPlayed.pointerPositionFractionalInMorph[1])) + theMorph.top()
    world.hand.fullMoveTo new Point(newX, newY)

    if commandBeingPlayed.button == "left"
      button = 0
    else if commandBeingPlayed.button == "middle"
      button = 1
    else if commandBeingPlayed.button == "right"
      button = 2

    if commandBeingPlayed.upOrDown == "up"
      # the mouse up doesn't need the control key info
      systemTestsRecorderAndPlayer.handMorph.processMouseUp(button)
    else
      systemTestsRecorderAndPlayer.handMorph.processMouseDown(button, commandBeingPlayed.ctrlKey)

  transformIntoDoNothingCommand: ->
    @automatorCommandName = "AutomatorCommandDoNothing"

  constructor: (@upOrDown, button, @ctrlKey, @morphUniqueIDString, @morphPathRelativeToWorld, @morphIdentifierViaTextLabel, @absoluteBoundsOfMorphRelativeToWorld, @pointerPositionFractionalInMorph, @pointerPositionPixelsInMorph, @pointerPositionPixelsInWorld, @isPartOfListMorph, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)

    if button == 0
      @button = "left"
    else if button == 1
      @button = "middle"
    else if button == 2
      @button = "right"

    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandMouseButtonChange"
