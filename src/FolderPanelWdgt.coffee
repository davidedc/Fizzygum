# a FolderPanelWdgt is a Panel that:
#
# 1) lets user create new folders in them
# 2) holds neatly any desktop system links in a grid
#    (including, but not limited to, other desktop system links that refer
#    to widgets and folders).
# 3) has extra logic such that any widget dropped in it "becomes"
#    a reference to such widget, and the widget is moved to storage
#    (the SHELF: referenced, so the eager storage sort keeps it there).
#    The reason for this is that the actual "rest" place where
#    general widgets should be is a storage container, not a panel.
#    The simulated "file system" (i.e. shortcuts and folders) is just a
#    network of pointers to stuff that "rests" on the shelf and is
#    pulled in/out of it as the user works with them.
#
# Note that the panel of the Bin IS NOT a FolderPanelWdgt
# because it doesn't need any of these behaviours.
#
# Also, the desktop IS NOT a FolderPanelWdgt because it
# doesn't need 3)
#
# (2 - the grid positioning, plus keeping links in the background - lives
# in the shared IconicDesktopSystemPanelWdgt base, common with the
# desktop; 1 and 3 are mine.)

class FolderPanelWdgt extends IconicDesktopSystemPanelWdgt

  # I manage my contents through the folder machinery (shortcut-creation on drop, grid
  # positioning), so my enclosing scroll frame must refuse RAW drops — it asks via ?()
  # (type-test-elimination ε; see ScrollPanelWdgt.wantsDropOfChild).
  vetoesScrollPanelDrops: ->
    true

  # ...and it borrows my colloquial name (type-test-elimination ε; see
  # ScrollPanelWdgt.colloquialName).
  scrollPanelColloquialName: ->
    "folder"

  # Widgets that are NOT shortcuts (object shortcuts or folders) that are
  # dropped are then going to be closed and their references
  # are going to be left in the folder instead.
  # HOWEVER we have to move that first "transient" widget dropped so that
  # it doesn't go "left" or "above" the folder panel, otherwise the
  # folder panel is going to resize so to fit the dropped widget
  # and the folder window is going to get scrollbars and the
  # subsequent shortcut is going to end up in a bad place instead
  # of the neat automatic grid positioning.
  # So, move the "transient" dropped widget just a bit to the
  # right and below the origin.
  _beforeChildDropped: (child) ->
    # a shortcut (already a reference) just fits within; a real dropped widget is offset so
    # the folder panel doesn't resize and scroll (was `instanceof
    # IconicDesktopSystemShortcutWdgt`). (type-test-elimination campaign)
    if child.isDesktopShortcut?()
      child._moveWithin @
    else
      child._applyMoveTo @position().add new Point 10, 10

  _reactToChildDropped: (droppedWidget) ->
    super
    # a real widget (not already a shortcut) leaves a reference behind and closes
    # (was `!(droppedWidget instanceof IconicDesktopSystemShortcutWdgt)`).
    # (type-test-elimination campaign)
    # _reactToChildDropped runs inside the drop's single settle -> the non-settling core.
    if !droppedWidget.isDesktopShortcut?()
      droppedWidget._createReferenceAndCloseNoSettle nil, @

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "new folder", @, "makeFolder", toolTip: "make a new folder"

