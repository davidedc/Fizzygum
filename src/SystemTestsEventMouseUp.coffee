# 


class SystemTestsEventMouseUp extends SystemTestsEvent

  constructor: (systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    @type = "mouseUp"
