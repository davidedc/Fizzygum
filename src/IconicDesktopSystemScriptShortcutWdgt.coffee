# Normally a shortcut just brings up another widget
# so normally a Script Shortcut would bring up... a ScriptWdgt
# However here we make an exception and instead of doing that,
# we actually ask the referred ScriptWdgt to run the its code.

class IconicDesktopSystemScriptShortcutWdgt extends IconicDesktopSystemShortcutWdgt

  constructor: (@referencedWidget, @title, @icon) ->
    if !@icon?
      @icon = new GenericShortcutIconWdgt new ScriptIconWdgt
    
    super @referencedWidget, @title, @icon

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    if @referencedWidget.destroyed
      @inform "The referenced item\nis dead!"
      return

    @referencedWidget.contents.doAll()


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "edit script...", @, "editScript"
    menu

  editScript: ->
    @bringUpTarget()
