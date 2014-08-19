# 


class SystemTestsCommandShowComment extends SystemTestsCommand
  message: ""

  @replayFunction: (systemTestsRecorderAndPlayer, queuedCommand) ->
    SystemTestsControlPanelUpdater.addMessageToTestCommentsConsole queuedCommand.message

  constructor: (@message, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandShowComment"
