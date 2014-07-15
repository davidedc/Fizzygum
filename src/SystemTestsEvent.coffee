# The SystemTests recorder collects a number
# of events from the user and puts them in a
# queue. This is the superclass of all the
# possible events.


class SystemTestsEvent
  type: ''
  time: 0

  constructor: (systemTestsRecorderAndPlayer) ->
    @time = (new Date().getTime()) - systemTestsRecorderAndPlayer.lastRecordedEventTime
