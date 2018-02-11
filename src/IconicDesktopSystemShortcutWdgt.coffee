# REQUIRES HighlightableMixin

# a "shortcut" (for friends) is a reference to something else.
# What does it mean? That if you duplicate the shortcut you just
# duplicate a reference, and opening either one will open the
# SAME referenced widget. Note that you can't show TWO
# "SAME widget"s at the same time, so opening a shortcut is likely
# to move the referenced widget from a location to another.
#
# If you want to duplicate the referencED widget instead, just
# duplicate that one, and create a reference FOR THE COPY.
#
# So, for example, is the Fizzypaint launcher icon a reference?
# NO, because if you duplicate the launcher, and open both of the
# launchers, you don't get to the SAME widget, you get to two entirely
# separate Fizzypaint instances that have different lifes and can be
# shown both at the same time on the screen.

class IconicDesktopSystemShortcutWdgt extends IconicDesktopSystemLinkWdgt

  @augmentWith HighlightableMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 0, 0, 0

  wantsDropOf: (aMorph) ->
    return @isFolder

  reactToDropOf: (droppedWidget) ->
    debugger
    if !@isFolder
      return
    if droppedWidget instanceof IconicDesktopSystemShortcutWdgt
      @target.contents.contents.add droppedWidget
    else
      droppedWidget.createReferenceAndClose nil, nil, @target.contents.contents

  constructor: (@target, @title, @isFolder = false) ->
    if !@title?
      @title = @target.colloquialName()

    if @isFolder
      super @title, new GenericShortcutIconWdgt new FolderIconWdgt()
    else
      super @title, new GenericShortcutIconWdgt new GenericObjectIconWdgt @target.representativeIcon()
    world.widgetsReferencingOtherWidgets.push @

  destroy: ->
    super
    world.widgetsReferencingOtherWidgets.remove @

  mouseDoubleClick: ->
    if @target.destroyed
      @inform "The referenced item\nis dead!"
      return

    if @target.isAncestorOf @
      @inform "The referenced item is\nalready open and containing\nwhat you just clicked on!"
      return

    # the target could be hidden if it's been hidden in the
    # basement view "only show lost items"
    @target.show()

    myPosition = @positionAmongSiblings()
    whatToBringUp = @target.findRootForGrab()
    if !whatToBringUp?
      @inform "The referenced item does exist\nhowever it's part of something\nthat can't be grabbed!"
    else
      # let's make SURE what we are bringing up is
      # visible
      whatToBringUp.show()
      whatToBringUp.spawnNextTo @, world
      whatToBringUp.setTitle? @label.text


  alignCopiedMorphToReferenceTracker: (cloneOfMe) ->
    if world.widgetsReferencingOtherWidgets.indexOf(@) != -1
      world.widgetsReferencingOtherWidgets.push cloneOfMe

