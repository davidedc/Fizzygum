# 


class AutomatorCommandCheckNumberOfItemsInMenu extends AutomatorCommand
  numberOfItemsInMenu: 0

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    automatorRecorderAndPlayer.checkNumberOfItemsInMenu(commandBeingPlayed.numberOfItemsInMenu)

  constructor: (@numberOfItemsInMenu, automatorRecorderAndPlayer) ->
    super automatorRecorderAndPlayer
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandCheckNumberOfItemsInMenu"
