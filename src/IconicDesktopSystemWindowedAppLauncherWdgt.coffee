class IconicDesktopSystemWindowedAppLauncherWdgt extends IconicDesktopSystemLinkWdgt

  constructor: (@title, @icon, @target, @callback) ->
    if !@title?
      @title = @target.colloquialName()

    super @title, @icon

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    @target[@callback].call @target
