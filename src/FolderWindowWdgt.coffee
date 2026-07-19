class FolderWindowWdgt extends FrameWdgt


  constructor: (@labelContent, @closeButton, @contents, @internal = false) ->
    @contents = new ScrollPanelWdgt new FolderPanelWdgt
    super @contents, labelContent: "", closeButton: @closeButton


  representativeIcon: ->
    new GenericShortcutIconWdgt new FolderIconWdgt

  closeFromFrameBar: ->
    if !world.anyReferenceToWdgt @
      prompt = new SaveShortcutPromptWdgt @, @
      prompt.popUpAtHand()
    else
      @close()

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @contents.contents.addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu

  createReference: (referenceName, whichFolderPanelToAddTo) ->
    # this function can also be called as a callback
    # of a trigger, in which case the first parameter
    # here is a menuItem. We take that parameter away
    # in that case.
    if referenceName? and typeof(referenceName) != "string"
      referenceName = nil

    widgetToAdd = new IconicDesktopSystemFolderShortcutWdgt @, referenceName
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    whichFolderPanelToAddTo.add widgetToAdd
    widgetToAdd.setExtent new Point 75, 75
    widgetToAdd.fullChanged()
    @bringToForeground()

