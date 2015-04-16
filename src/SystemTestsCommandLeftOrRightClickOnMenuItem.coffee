# 


class SystemTestsCommandLeftOrRightClickOnMenuItem extends SystemTestsCommand
  whichMouseButtonPressed = ""
  textLabelOfClickedItem: 0
  # there might be multiple instances of
  # the same text label so we count
  # which one it is
  textLabelOccurrenceNumber: 0

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    #systemTestsRecorderAndPlayer.handMorph.leftOrRightClickOnMenuItemWithText(commandBeingPlayed.whichMouseButtonPressed, commandBeingPlayed.textLabelOfClickedItem, commandBeingPlayed.textLabelOccurrenceNumber)

  constructor: (@whichMouseButtonPressed, @textLabelOfClickedItem, @textLabelOccurrenceNumber, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandLeftOrRightClickOnMenuItem"
