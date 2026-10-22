# a FolderPanelWdgt is a Panel that:
#
# 1) lets user create new folders in them
# 2) holds neatly any desktop system links in a grid
#    (including, but not limited to, other desktop system links that refer
#    to widgets and folders).
# 3) has extra logic such that any widget dropped in it, other than a
#    desktop icon (which just stays where it was dropped), "becomes"
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
# in the shared IconGridPanelWdgt base, common with the
# desktop; 1 and 3 are mine.)

class FolderPanelWdgt extends IconGridPanelWdgt

  # I wear a folder window's panel look, read as I am painted (_surfaceFill, _surfaceStroke): my fill
  # is the folderPanelFill role until a colour is set on me, and I have no border -- the window's
  # frame and its strip's rule are my lines (FolderWindowWdgt). Like every panel I hold no colour of
  # my own, so a folder saved, loaded or duplicated wears the look of the world it is shown in.

  # the fill my RectangularAppearance paints me in while I hold no colour of my own (my viewport,
  # whose paint mimics mine, answers it too: ViewportWdgt._surfaceFill)
  _surfaceFill: ->
    WorldWdgt.theme.folderPanelFill

  # ... and my border: none (not the generic panel's)
  _surfaceStroke: ->
    undefined

  # I manage my contents through the folder machinery (shortcut-creation on drop, grid
  # positioning), so my enclosing viewport must refuse RAW drops — it asks via ?()
  # (type-test-elimination ε; see ViewportWdgt.wantsDropOfChild).
  vetoesViewportDrops: ->
    true

  # ...and it borrows my colloquial name (type-test-elimination ε; see
  # ViewportWdgt.colloquialName).
  viewportColloquialName: ->
    "folder"

  # A dropped DESKTOP ICON (isDesktopIcon: a shortcut, an app launcher, any icon with a caption)
  # stays where the user dropped it, only kept inside me -- a drop into an open folder brings its
  # position, as a drop on the desktop does. Anything else is to be FILED (_reactToChildDropped
  # below), so it first comes in just inside my top-left: while it is my child it cannot pull my
  # frame's origin up or left of where my grid's slots are measured from (my viewport frames me
  # round my children), and once it has gone, my frame shrinks back to what my icons need -- no
  # scroll bar while they fit in my viewport.
  _beforeChildDropped: (child) ->
    # (instead of `instanceof WidgetHolderWithCaptionWdgt`; type-test-elimination campaign)
    if child.isDesktopIcon?()
      child._moveWithin @
    else
      child._applyMoveTo @position().add new Point 10, 10

  # What I received decides what I keep (a capability, not a class test: the type-test-elimination
  # campaign). A DESKTOP ICON is mine as it is, where it was dropped: the drop has already made it my
  # child, so an app launcher moves in exactly as a shortcut does, and neither takes a slot (a drop
  # onto my folder's ICON brings no position and takes my next free slot instead:
  # DesktopLinkWdgt._reactToBeingDroppedIntoFolder). Anything else is FILED: it leaves a reference
  # behind in my next free slot and closes (Widget._createReferenceAndCloseNoSettle).
  # _reactToChildDropped runs inside the drop's single settle -> the non-settling core.
  _reactToChildDropped: (droppedWidget) ->
    super
    return if droppedWidget.isDesktopIcon?()
    droppedWidget._createReferenceAndCloseNoSettle @

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "New folder", @, "makeFolderFromMenu", toolTip: "make a new folder"

