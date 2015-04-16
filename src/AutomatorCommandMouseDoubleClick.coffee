# 


class AutomatorCommandMouseDoubleClick extends AutomatorCommand
  ctrlKey: null
  morphIdentifierViaTextLabel: null
  pointerPositionFractionalInMorph: null
  pointerPositionPixelsInMorph: null
  pointerPositionPixelsInWorld: null
  absoluteBoundsOfMorphRelativeToWorld: null
  morphUniqueIDString: null
  morphPathRelativeToWorld: null


  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->

  transformIntoDoNothingCommand: ->
    @automatorCommandName = "AutomatorCommandDoNothing"

  constructor: (@ctrlKey, @morphUniqueIDString, @morphPathRelativeToWorld, @morphIdentifierViaTextLabel, @absoluteBoundsOfMorphRelativeToWorld, @pointerPositionFractionalInMorph, @pointerPositionPixelsInMorph, @pointerPositionPixelsInWorld, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandMouseDoubleClick"
