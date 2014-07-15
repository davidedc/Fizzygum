# The SystemTests recorder collects a number
# of events from the user and puts them in a
# queue. This is the superclass of all the
# possible events.


class SystemTestsEvent
  type: ''
  time: 0
  timeOfCreation: 0

  constructor: (systemTestsRecorderAndPlayer) ->
    @timeOfCreation = new Date().getTime()
    @time = @timeOfCreation - systemTestsRecorderAndPlayer.lastRecordedEventTime
