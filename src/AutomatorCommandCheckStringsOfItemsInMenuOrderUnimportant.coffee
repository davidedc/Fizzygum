# 


class AutomatorCommandCheckStringsOfItemsInMenuOrderUnimportant extends AutomatorCommand
  stringOfItemsInMenuInOriginalOrder: []

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    automatorRecorderAndPlayer.checkStringsOfItemsInMenuOrderUnimportant(commandBeingPlayed.stringOfItemsInMenuInOriginalOrder)

  constructor: (@stringOfItemsInMenuInOriginalOrder, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandCheckStringsOfItemsInMenuOrderUnimportant"
