# The desktop / in-folder icon that opens a windowed app. Two modes, one click path:
#
#   EAGER — built by IconicDesktopSystemWindowedApp.createOpener, which hands over the live app
#           singleton as @target and the method to call on it. The app class is already here (it had
#           to be, to build this icon at all), so the click is a plain call.
#   LAZY  — built from a DESCRIPTOR: a title, an icon made of CORE art, and the app's class NAME as
#           a string. Nothing of the app exists yet. On the click the name is resolved to the part
#           that owns it, that part is fetched, compiled and run, and only then is the app launched.
#
# ⚠⚠ THE LAZY MODE IS WHAT LETS AN APP'S SOURCE ARRIVE ON ITS OWN CLICK RATHER THAN WITH ITS
# NEIGHBOURS'. A launcher was assumed to have to be eager, because WorldWdgt.createDesktop builds
# every icon at boot and an app class inside a lazy part could not be constructed there — which is
# why authoring-launcher and fizzytiles-launcher exist as eager slivers. But building the ICON never
# needed the APP: the art is core, and the only thing genuinely required at boot is a NAME. So each
# of the Examples folder's five doors sits alone in its own one-class part and is fetched by exactly
# the click that wants it — opening the folder fetches nothing at all.
#
# ⚠ A STRING IS ALSO WHAT MAKES THIS SERIALIZE FOR FREE. The eager mode stores a live app object,
# which the Serializer encodes symbolically as {"$wk":"app:<ClassName>"} and re-resolves on load;
# the lazy mode stores the same information as a plain field, so a saved world carries the icon
# without carrying — or needing — the app.
class IconicDesktopSystemWindowedAppLauncherWdgt extends IconicDesktopSystemLinkWdgt

  # set only in the lazy mode; nil means @target/@callback are live (the eager mode)
  appClassName: nil

  constructor: (@title, @icon, @target, @callback) ->
    if !@title?
      @title = @target.colloquialName()

    super @title, @icon

  # Build the lazy-mode icon for `appClassName` and put it in `folder`. A class method rather than a
  # bare constructor so the two modes cannot be confused at a call site (`new …(title, icon, nil,
  # nil)` would be silently launch-less), and because installing an in-folder icon is a ritual —
  # size FIRST, then add, since the icon grid places on add.
  # ⚠ `buildIcon` is a THUNK, and the guard comes before it: an artifact that can never produce this
  # app constructs no widget and gets no icon, rather than one whose click could only reject.
  @addToFolder: (folder, appClassName, title, buildIcon) ->
    launcher = @_lazyLauncherFor appClassName, title, buildIcon
    return unless launcher?
    # in-folder: size FIRST, then add — the icon grid places on add
    launcher.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
    folder.contents.contents.add launcher

  # Same, onto the desktop. ⚠ The two orders are NOT interchangeable and never were (this pair is
  # lifted verbatim from IconicDesktopSystemWindowedApp.createOpener's two arms): the desktop places
  # by smart grid ON ADD, so it must be added before it is sized, while a folder's grid reads the
  # extent as it adds.
  @addToDesktop: (appClassName, title, buildIcon) ->
    launcher = @_lazyLauncherFor appClassName, title, buildIcon
    return unless launcher?
    world.add launcher
    launcher.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()

  # nil when this artifact can never produce the app — no widget is constructed and no icon appears,
  # rather than one whose click could only reject. `buildIcon` is a thunk for exactly that reason.
  @_lazyLauncherFor: (appClassName, title, buildIcon) ->
    return nil unless world.parts.canEverProvideClass appClassName
    launcher = new @ title, buildIcon(), nil, nil
    launcher.appClassName = appClassName
    launcher

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    return @target[@callback].call @target unless @appClassName?

    # ⚠ The part is looked up FROM THE CLASS NAME rather than named here: a launcher should not have
    # to know how the partition is carved, and PartsRegistry already answers exactly this question
    # for the snapshot loader. whenClassAvailable runs its callback INLINE when the class is already
    # in — the usual case after the first click — and inline is correctness, not economy: deferring
    # by a microtask moves the launch a whole world cycle later, and the suite measures cycles.
    appClassName = @appClassName
    world.parts.whenClassAvailable appClassName, ->
      (new window[appClassName]).launch()
