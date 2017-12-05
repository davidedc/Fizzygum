# 


class AutomatorCommandMouseTripleClick extends AutomatorCommand
  ctrlKey: nil
  morphIdentifierViaTextLabel: nil
  pointerPositionFractionalInMorph: nil
  pointerPositionPixelsInMorph: nil
  pointerPositionPixelsInWorld: nil
  absoluteBoundsOfMorphRelativeToWorld: nil
  morphUniqueIDString: nil
  morphPathRelativeToWorld: nil
  isPartOfListMorph: nil


  # you'd ask why can't we *always* trigger the triple click action
  # just by the standard mechanism of listening to the three
  # clicks in quick succession.
  # In fast mode we can't do that because the rapid
  # clicks would always turn into triple-clicks, so we check
  # for that.
  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    debugger
    if !window.world.automatorRecorderAndPlayer.runningInSlowMode()
      console.log ">>>>>>>>>>>>> executing AutomatorCommandMouseTripleClick"
      theMorph = world.getMorphViaTextLabel(commandBeingPlayed.morphIdentifierViaTextLabel)
      newX = Math.round((theMorph.width() * commandBeingPlayed.pointerPositionFractionalInMorph[0])) + theMorph.left()
      newY = Math.round((theMorph.height() * commandBeingPlayed.pointerPositionFractionalInMorph[1])) + theMorph.top()
      world.hand.fullRawMoveTo new Point(newX, newY)
      automatorRecorderAndPlayer.handMorph.processTripleClick()
    else
      # in this case the system is going to detect (and process)
      # the double click by detecting 2 normal clicks in quick
      # succession.
      console.log "************* not executing AutomatorCommandMouseTripleClick"

  transformIntoDoNothingCommand: ->
    @automatorCommandName = "AutomatorCommandDoNothing"

  constructor: (@ctrlKey, @morphUniqueIDString, @morphPathRelativeToWorld, @morphIdentifierViaTextLabel, @absoluteBoundsOfMorphRelativeToWorld, @pointerPositionFractionalInMorph, @pointerPositionPixelsInMorph, @pointerPositionPixelsInWorld, @isPartOfListMorph, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandMouseTripleClick"
