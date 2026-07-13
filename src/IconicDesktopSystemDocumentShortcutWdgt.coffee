# This is a reference to any type of document, be it a script, or an image
# or a slide or a note etc. etc.

class IconicDesktopSystemDocumentShortcutWdgt extends IconicDesktopSystemShortcutWdgt

  _reactToChildDropped: (droppedWidget) ->

  constructor: (@target, @title, @icon) ->
    if !@icon?
      @icon = new GenericShortcutIconWdgt new GenericObjectIconWdgt @target.representativeIcon()

    super @target, @title, @icon

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    @bringUpTarget()


