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


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    menu.addLine()
    menu.addMenuItem "edit script...", @, "editScript"
    menu

  editScript: ->
    @bringUpTarget()
