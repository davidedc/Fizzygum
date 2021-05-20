# Normally a shortcut just brings up another widget
# so normally a Script Shortcut would bring up... a ScriptWdgt
# However here we make an exception and instead of doing that,
# we actually ask the referred ScriptWdgt to run the its code.

# TODO I don't think this should be extending IconicDesktopSystemShortcutWdgt but
# but rather IconicDesktopSystemLinkWdgt

class IconicDesktopSystemScriptShortcutWdgt extends IconicDesktopSystemShortcutWdgt

  constructor: (@target, @title, @icon) ->
    if !@icon?
      @icon = new GenericShortcutIconWdgt new ScriptIconWdgt
    
    super @target, @title, @icon

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

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
