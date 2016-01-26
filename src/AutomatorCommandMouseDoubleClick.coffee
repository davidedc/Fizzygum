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
  isPartOfListMorph: null


  # you'd ask why can't we *always* trigger the double click action
  # just by the standard mechanism of listening to the two
  # clicks in quick succession.
  # In fast mode we can't do that because the rapid
  # clicks would always turn into double-clicks, so we check
  # for that.
  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    debugger
    if !window.world.systemTestsRecorderAndPlayer.runningInSlowMode()
      console.log ">>>>>>>>>>>>> executing AutomatorCommandMouseDoubleClick"
      theMorph = world.getMorphViaTextLabel(commandBeingPlayed.morphIdentifierViaTextLabel)
      newX = Math.round((theMorph.width() * commandBeingPlayed.pointerPositionFractionalInMorph[0])) + theMorph.left()
      newY = Math.round((theMorph.height() * commandBeingPlayed.pointerPositionFractionalInMorph[1])) + theMorph.top()
      world.hand.fullRawMoveTo new Point(newX, newY)
      systemTestsRecorderAndPlayer.handMorph.processDoubleClick()
    else
      # in this case the system is going to detect (and process)
      # the double click by detecting 2 normal clicks in quick
      # succession.
      console.log "************* not executing AutomatorCommandMouseDoubleClick"

  transformIntoDoNothingCommand: ->
    @automatorCommandName = "AutomatorCommandDoNothing"

  constructor: (@ctrlKey, @morphUniqueIDString, @morphPathRelativeToWorld, @morphIdentifierViaTextLabel, @absoluteBoundsOfMorphRelativeToWorld, @pointerPositionFractionalInMorph, @pointerPositionPixelsInMorph, @pointerPositionPixelsInWorld, @isPartOfListMorph, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandMouseDoubleClick"
