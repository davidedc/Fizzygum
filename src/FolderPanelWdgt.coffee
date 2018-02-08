#| FolderPanelWdgt //////////////////////////////////////////////////////////


class FolderPanelWdgt extends PanelWdgt

  makeFolder: ->
    debugger
    newFolderWindow = new FolderWindowWdgt nil,nil,nil,nil, @
    newFolderWindow.close()
    #world.create newFolderWindow
    newFolderWindow.createFolderReference "untitled", @

  reactToDropOf: (droppedWidget) ->
    debugger
    if !(droppedWidget instanceof ReferenceWdgt)
      droppedWidget.createReferenceAndClose nil, nil, @
