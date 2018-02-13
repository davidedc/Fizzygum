class IconicDesktopSystemFolderShortcutWdgt extends IconicDesktopSystemShortcutWdgt

  _acceptsDrops: true

  reactToDropOf: (droppedWidget) ->
    debugger
    if droppedWidget instanceof IconicDesktopSystemLinkWdgt
      @target.contents.contents.add droppedWidget
    else
      droppedWidget.createReferenceAndClose nil, @target.contents.contents

  constructor: (@target, @title) ->
    super @target, @title, new GenericShortcutIconWdgt new FolderIconWdgt()

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

