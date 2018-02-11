# WindowWdgt //////////////////////////////////////////////////////
# REQUIRES WindowContentsPlaceholderText

class FolderWindowWdgt extends WindowWdgt


  constructor: (@labelContent, @closeButton, @contents, @internal = false, @wdgtWhereReferenceWillGo) ->
    @contents = new ScrollPanelWdgt new FolderPanelWdgt()
    super "", @closeButton, @contents, @internal


  representativeIcon: ->
    new GenericShortcutIconWdgt new FolderIconWdgt()

  closeFromWindowBar: ->
    if !world.anyReferenceToWdgt @
      prompt = new SaveReferencePromptWdgt @, @, nil, nil
      prompt.popUpAtHand()
    else
      @close()

