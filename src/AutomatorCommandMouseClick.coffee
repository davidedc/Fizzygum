# 


class AutomatorCommandMouseClick extends AutomatorCommand
  button: nil
  ctrlKey: nil
  morphIdentifierViaTextLabel: nil
  pointerPositionFractionalInMorph: nil
  pointerPositionPixelsInMorph: nil
  pointerPositionPixelsInWorld: nil
  absoluteBoundsOfMorphRelativeToWorld: nil
  morphUniqueIDString: nil
  morphPathRelativeToWorld: nil
  isPartOfListMorph: nil

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->

  transformIntoDoNothingCommand: ->
    @automatorCommandName = "AutomatorCommandDoNothing"

  constructor: (button, @ctrlKey, @morphUniqueIDString, @morphPathRelativeToWorld, @morphIdentifierViaTextLabel, @absoluteBoundsOfMorphRelativeToWorld, @pointerPositionFractionalInMorph, @pointerPositionPixelsInMorph, @pointerPositionPixelsInWorld, @isPartOfListMorph, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    
    if button == 0
      @button = "left"
    else if button == 1
      @button = "middle"
    else if button == 2
      @button = "right"

    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandMouseClick"
