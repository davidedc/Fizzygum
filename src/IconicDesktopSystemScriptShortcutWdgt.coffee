class IconicDesktopSystemScriptShortcutWdgt extends IconicDesktopSystemShortcutWdgt

  constructor: (@target, @title, @icon) ->
    if !@icon?
      @icon = new GenericShortcutIconWdgt new ScriptIconWdgt()
    
    super @target, @title, @icon

  mouseDoubleClick: ->
    if @target.destroyed
      @inform "The referenced item\nis dead!"
      return

    @target.contents.doAll()


  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
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
