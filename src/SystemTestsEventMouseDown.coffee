# 


class SystemTestsEventMouseDown extends SystemTestsEvent
  type: ''
  time: 0
  button: null
  ctrlKey: null


  constructor: (@button, @ctrlKey, systemTestsRecorderAndPlayer) ->
  	super(systemTestsRecorderAndPlayer)
  	@type = "mouseDown"
