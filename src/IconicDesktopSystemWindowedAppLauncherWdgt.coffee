class IconicDesktopSystemWindowedAppLauncherWdgt extends IconicDesktopSystemLinkWdgt

  @augmentWith HighlightableMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.BLACK


  constructor: (@title, @icon, @target, @callback) ->
    if !@title?
      @title = @target.colloquialName()

    super @title, @icon

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    @target[@callback].call @target
