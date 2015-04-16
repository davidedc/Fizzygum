# 


class SystemTestsCommandOpenContextMenu extends SystemTestsCommand
  morphToOpenContextMenuAgainst_UniqueIDString: null

  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    #systemTestsRecorderAndPlayer.handMorph.openContextMenuAtPointer (Morph.morphFromUniqueIDString commandBeingPlayed.morphToOpenContextMenuAgainst_UniqueIDString)


  constructor: (@morphToOpenContextMenuAgainst_UniqueIDString, systemTestsRecorderAndPlayer) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandOpenContextMenu"
