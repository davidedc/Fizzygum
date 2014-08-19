# The SystemTests recorder collects a number
# of commands from the user and puts them in a
# queue. This is the superclass of all the
# possible commands.


class SystemTestsCommand
  testCommandName: ''
  millisecondsSincePreviousCommand: 0

  constructor: (systemTestsRecorderAndPlayer) ->
    @millisecondsSincePreviousCommand = (new Date().getTime()) - systemTestsRecorderAndPlayer.timeOfPreviouslyRecordedCommand
