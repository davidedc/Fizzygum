# FolderPanelWdgt //////////////////////////////////////////////////////////

# a FolderPanelWdgt is a Panel that:
#
# 1) lets user create new folders in them
# 2) holds neatly any desktop system links in a grid
#    (including, but not limited to, other desktop system links that refer
#    to widgets and folders).
# 3) has extra logic such that any widget dropped in it "becomes"
#    a reference to such widget, and the widget is moved to the basement.
#    The reason for this is that the actual "rest" place where
#    general widgets should be is in the basement.
#    The simulated "file system" (i.e. shortcuts and folders) is just a
#    network of pointers to stuff that "rests" in the basement and is
#    pulled in/out of it as the user works with them.
#
# Note that the desktop is a FolderPanelWdgt, but overrides
# behaviour 3)
#
# Note that the panel of the Basement IS NOT a FolderPanelWdgt
# because it doesn't have behaviours 1) and 3).

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
    if !(droppedWidget instanceof IconicDesktopSystemShortcutWdgt)
      droppedWidget.createReferenceAndClose nil, nil, @

  add: (aMorph, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped) ->
    super
    # If the user drops an icon, it's more natural to just position it
    # where it is. Conversely, if an icon is just "created" somewhere,
    # then automatic grid positioning is better.
    if !beingDropped and (aMorph instanceof WidgetHolderWithCaptionWdgt) and !(aMorph instanceof BasementOpenerWdgt)
      if @laysIconsHorizontallyInGrid
        xPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
        yPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
      else
        xPos = Math.floor @numberOfIconsOnDesktop / @iconsLayingInGridWrapCount
        yPos = @numberOfIconsOnDesktop % @iconsLayingInGridWrapCount
      aMorph.fullRawMoveTo @position().add new Point xPos * 85, yPos * 85
      @numberOfIconsOnDesktop++

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "new folder", true, @contents.contents, "makeFolder", "make a new folder", nil,nil,nil,nil, @wdgtWhereReferenceWillGo
