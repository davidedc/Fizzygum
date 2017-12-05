# 


class AutomatorCommandOpenContextMenu extends AutomatorCommand
  morphToOpenContextMenuAgainst_UniqueIDString: nil

  @replayFunction: (automatorRecorderAndPlayer, commandBeingPlayed) ->
    #automatorRecorderAndPlayer.handMorph.openContextMenuAtPointer (Morph.morphFromUniqueIDString commandBeingPlayed.morphToOpenContextMenuAgainst_UniqueIDString)


  constructor: (@morphToOpenContextMenuAgainst_UniqueIDString, automatorRecorderAndPlayer) ->
    super(automatorRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @automatorCommandName = "AutomatorCommandOpenContextMenu"
