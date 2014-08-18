# 


class SystemTestsEventCheckNumberOfItemsInMenu extends SystemTestsEvent
  numberOfItemsInMenu: 0

  @replayFunction: (systemTestsRecorderAndPlayer, queuedEvent) ->
    systemTestsRecorderAndPlayer.checkNumberOfItemsInMenu(queuedEvent.numberOfItemsInMenu)

  constructor: (@numberOfItemsInMenu, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the event
    @testCommand = "SystemTestsEventCheckNumberOfItemsInMenu"
