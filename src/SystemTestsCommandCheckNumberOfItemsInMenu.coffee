# 


class SystemTestsCommandCheckNumberOfItemsInMenu extends SystemTestsCommand
  numberOfItemsInMenu: 0

  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    systemTestsRecorderAndPlayer.checkNumberOfItemsInMenu(queuedCommand.numberOfItemsInMenu)

  constructor: (@numberOfItemsInMenu, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandCheckNumberOfItemsInMenu"
