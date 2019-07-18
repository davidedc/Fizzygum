class IconicDesktopSystemFolderShortcutWdgt extends IconicDesktopSystemShortcutWdgt

  _acceptsDrops: true

  reactToDropOf: (droppedWidget) ->
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

    whatToBringUp = @target.findRootForGrab()
    # things like draggable graphs have no root for grab,
    # however since they are in the basement "directly" on their own
    # it's OK to bring those up (as opposed to things
    # that are part of other widgets that are in the basement,
    # in that case you'd tear it off an existing widget and it
    # would probably be a bad thing)
    if !whatToBringUp? and @target.isDirectlyInBasement()
      whatToBringUp = @target
    if !whatToBringUp?
      @inform "The referenced item does exist\nhowever it's part of something\nthat can't be grabbed!"
    else
      # let's make SURE what we are bringing up is
      # visible
      whatToBringUp.show()
      whatToBringUp.spawnNextTo @, world
      whatToBringUp.rememberFractionalSituationInHoldingPanel()
      whatToBringUp.setTitle? @label.text

