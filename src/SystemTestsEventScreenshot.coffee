# 


class SystemTestsEventScreenshot extends SystemTestsEvent
  screenShotImageName: null


  constructor: (@screenShotImageName, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    @type = "takeScreenshot"
