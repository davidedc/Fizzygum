# REQUIRES HighlightableMixin

class ScriptShortcutWdgt extends IconicDesktopSystemLinkWdgt

  @augmentWith HighlightableMixin, @name

  @_acceptsDrops: false
  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 0, 0, 0

  constructor: (@target, @title, @icon) ->
    if !@title?
      @title = @target.colloquialName()

    if !@icon?
      super @title, new GenericShortcutIconWdgt new ScriptIconWdgt()
    else
      super @title, @icon
    world.widgetsReferencingOtherWidgets.push @

  destroy: ->
    super
    world.widgetsReferencingOtherWidgets.remove @

  mouseDoubleClick: ->
    if @target.destroyed
      @inform "The referenced item\nis dead!"
      return

    @target.contents.doAll()


  alignCopiedMorphToReferenceTracker: (cloneOfMe) ->
    if world.widgetsReferencingOtherWidgets.indexOf(@) != -1
      world.widgetsReferencingOtherWidgets.push cloneOfMe

  addShapeSpecificMenuItems: (menu) ->
    menu.addLine()
    menu.addMenuItem "edit script...", true, @, "editScript"
    menu

  editScript: ->
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
