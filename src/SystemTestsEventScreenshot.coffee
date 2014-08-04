#


class SystemTestsEventScreenshot extends SystemTestsEvent
  screenShotImageName: null
  @replayFunction: (systemTestsRecorderAndPlayer, queuedEvent) ->
    systemTestsRecorderAndPlayer.compareScreenshots(queuedEvent.screenShotImageName)


  constructor: (@screenShotImageName, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the event
    @type = "SystemTestsEventScreenshot"
