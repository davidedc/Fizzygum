# WindowWdgt //////////////////////////////////////////////////////
# REQUIRES WindowContentsPlaceholderText

class FolderWindowWdgt extends WindowWdgt


  constructor: (@labelContent, @closeButton, @contents, @internal = false) ->
    @contents = new ScrollPanelWdgt new FolderPanelWdgt()
    super "", @closeButton, @contents, @internal


  representativeIcon: ->
    new GenericShortcutIconWdgt new FolderIconWdgt()

  closeFromWindowBar: ->
    if !world.anyReferenceToWdgt @
      prompt = new SaveReferencePromptWdgt @, @
      prompt.popUpAtHand()
    else
      @close()

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    @contents.contents.addMorphSpecificMenuEntries morphOpeningThePopUp, menu
