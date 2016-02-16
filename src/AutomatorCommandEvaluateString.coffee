# 


class AutomatorCommandEvaluateString extends AutomatorCommand
  command: ""

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    world.evaluateString commandBeingPlayed.command

  constructor: (@command, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandEvaluateString"
