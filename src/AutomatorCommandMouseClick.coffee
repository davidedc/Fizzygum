# 


class AutomatorCommandMouseClick extends AutomatorCommand
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
