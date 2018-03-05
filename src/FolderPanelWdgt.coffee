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
# Note that the panel of the Basement IS NOT a FolderPanelWdgt
# because it doesn't need any of these behaviours.
#
# Also, the desktop IS NOT a FolderPanelWdgt because it
# doesn't need 3)

# REQUIRES GridPositioningOfAddedShortcutsMixin
# REQUIRES KeepIconicDesktopSystemLinksBackMixin
# REQUIRES CreateShortcutOfDroppedItemsMixin

class FolderPanelWdgt extends PanelWdgt

  @augmentWith GridPositioningOfAddedShortcutsMixin, @name
  @augmentWith KeepIconicDesktopSystemLinksBackMixin, @name
  @augmentWith CreateShortcutOfDroppedItemsMixin, @name

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "new folder", true, @, "makeFolder", "make a new folder"

