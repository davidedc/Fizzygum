# REQUIRES WindowContentsPlaceholderText

class FolderWindowWdgt extends WindowWdgt


  constructor: (@labelContent, @closeButton, @contents, @internal = false) ->
    @contents = new ScrollPanelWdgt new FolderPanelWdgt()
    super "", @closeButton, @contents, @internal


  representativeIcon: ->
    new GenericShortcutIconWdgt new FolderIconWdgt()

  closeFromWindowBar: ->
    if !world.anyReferenceToWdgt @
      prompt = new SaveShortcutPromptWdgt @, @
      prompt.popUpAtHand()
    else
      @close()

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    @contents.contents.addMorphSpecificMenuEntries morphOpeningThePopUp, menu

  createReference: (referenceName, whichFolderPanelToAddTo) ->
    # this function can also be called as a callback
    # of a trigger, in which case the first parameter
    # here is a menuItem. We take that parameter away
    # in that case.
    if referenceName? and typeof(referenceName) != "string"
      referenceName = nil
      placeToDropItIn = world

    morphToAdd = new IconicDesktopSystemFolderShortcutWdgt @, referenceName
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    whichFolderPanelToAddTo.add morphToAdd
    morphToAdd.setExtent new Point 75, 75
    morphToAdd.fullChanged()
    @bringToForegroud()

