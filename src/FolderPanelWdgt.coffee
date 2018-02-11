#| FolderPanelWdgt //////////////////////////////////////////////////////////


class FolderPanelWdgt extends PanelWdgt

  numberOfIconsOnDesktop: 0
  laysIconsHorizontallyInGrid: true
  iconsLayingInGridWrapCount: 3

  makeFolder: ->
    debugger
    newFolderWindow = new FolderWindowWdgt nil,nil,nil,nil, @
    newFolderWindow.close()
    newFolderWindow.createFolderReference "untitled", @

  reactToDropOf: (droppedWidget) ->
    debugger
    if !(droppedWidget instanceof ReferenceWdgt)
      droppedWidget.createReferenceAndClose nil, nil, @

  add: (aMorph, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped) ->
    super
    # If the user drops an icon, it's more natural to just position it
    # where it is. Conversely, if an icon is just "created" somewhere,
    # then automatic grid positioning is better.
    if !beingDropped and (aMorph instanceof WidgetHolderWithCaption) and !(aMorph instanceof BasementOpenerWdgt)
      if @laysIconsHorizontallyInGrid
        xPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
        yPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
      else
        xPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
        yPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
      aMorph.fullRawMoveTo @position().add new Point xPos * 85, yPos * 85
      @numberOfIconsOnDesktop++
