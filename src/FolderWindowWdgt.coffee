# WindowWdgt //////////////////////////////////////////////////////
# REQUIRES WindowContentsPlaceholderText

class FolderWindowWdgt extends WindowWdgt


  constructor: (@labelContent, @closeButton, @contents, @internal = false, @wdgtWhereReferenceWillGo) ->
    @contents = new ScrollPanelWdgt new FolderPanelWdgt()
    super "", @closeButton, @contents, @internal


  representativeIcon: ->
    new GenericShortcutIconWdgt new FolderIconWdgt()

  addMorphSpecificMenuEntries: (morphOpeningTheMenu, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "new folder...", true, @contents.contents, "makeFolder", "make a new folder", nil,nil,nil,nil, @wdgtWhereReferenceWillGo

  closeFromWindowBar: ->
    if !world.anyReferenceToWdgt @
      prompt = new SaveReferencePromptWdgt @, @, nil, nil
      prompt.popUpAtHand()
    else
      @close()

