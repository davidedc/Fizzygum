# 


class AutomatorCommandShowComment extends AutomatorCommand
  message: ""

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    SystemTestsControlPanelUpdater.addMessageToTestCommentsConsole commandBeingPlayed.message

  constructor: (@message, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandShowComment"
