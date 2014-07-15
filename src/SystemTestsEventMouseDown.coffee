# 


class SystemTestsEventMouseDown extends SystemTestsEvent
  button: null
  ctrlKey: null


  constructor: (@button, @ctrlKey, systemTestsRecorderAndPlayer) ->
  	super(systemTestsRecorderAndPlayer)
  	@type = "mouseDown"
