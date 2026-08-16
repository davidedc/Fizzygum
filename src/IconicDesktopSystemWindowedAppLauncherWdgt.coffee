# The desktop / in-folder icon that opens a windowed app. Two modes, one click path:
#
#   EAGER — built by IconicDesktopSystemWindowedApp.createOpener, which hands over the live app
#           singleton as @target and the method to call on it. The app class is already here (it had
#           to be, to build this icon at all), so the click is a plain call.
#   LAZY  — built from the app's class NAME as a string. Nothing of the app exists yet. On the click
#           the name is resolved to the part that owns it, that part is fetched, compiled and run,
#           and only then is the app launched.
#
# Both take the caption and the art from AppCatalog, through the one _fromCatalogEntry path below —
# stating them per-mode is how a field reaches one mode and not the other. See AppCatalog.
#
# ⚠⚠ THE LAZY MODE IS WHAT LETS AN APP'S SOURCE ARRIVE ON ITS OWN CLICK RATHER THAN WITH ITS
# NEIGHBOURS'. WorldWdgt.createDesktop builds every icon at boot, which makes a launcher look like it
# has to be eager — an app class inside a lazy part cannot be constructed there. But building the
# ICON does not need the APP: for the desktop's own icons the art is core, and the only thing
# genuinely required at boot is a NAME. So no app needs an eager sliver beside it. The Examples
# folder's five doors take this further: each sits alone in its own one-class part, fetched only by
# the click that wants it — opening the folder fetches just its own art (the lazy examples-icons
# part), never any door's app.
#
# ⚠ A STRING IS ALSO WHAT MAKES THIS SERIALIZE FOR FREE. The eager mode stores a live app object,
# which the Serializer encodes symbolically as {"$wk":"app:<ClassName>"} and re-resolves on load;
# the lazy mode stores the same information as a plain field, so a saved world carries the icon
# without carrying — or needing — the app.
class IconicDesktopSystemWindowedAppLauncherWdgt extends IconicDesktopSystemLinkWdgt

  # the DISPATCH pair, live only in the EAGER mode -- see appClassName below, whose presence
  # means the app class has not arrived yet and these two are undefined
  target: undefined
  callback: undefined

  # set only in the lazy mode; undefined means @target/@callback are live (the eager mode)
  appClassName: undefined

  constructor: (@title, @icon, @target, @callback) ->
    if !@title?
      @title = @target.colloquialName()

    super @title, @icon

  # Build the lazy-mode icon for `appClassName` and put it in `folder`. A class method rather than a
  # bare constructor so the two modes cannot be confused at a call site (`new …(title, icon, undefined,
  # undefined)` would be silently launch-less), and because installing an in-folder icon is a ritual —
  # size FIRST, then add, since the icon grid places on add.
  # ⚠ `iconOverride` has exactly ONE caller in the system and is not a general escape hatch: the
  # Examples folder's C-F door draws art from the LAZY `examples-icons` part, which a CORE file may
  # not name (AppCatalog's header explains why). Everything else takes its icon from the catalog.
  @addToFolder: (folder, appClassName, iconOverride) ->
    launcher = @forAppNamed appClassName, iconOverride
    return unless launcher?
    # in-folder: size FIRST, then add — the icon grid places on add
    launcher.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
    folder.contents.contents.add launcher

  # Same, onto the desktop. ⚠ The two orders are NOT interchangeable and never were (this pair is
  # lifted verbatim from IconicDesktopSystemWindowedApp.createOpener's two arms): the desktop places
  # by smart grid ON ADD, so it must be added before it is sized, while a folder's grid reads the
  # extent as it adds.
  @addToDesktop: (appClassName) ->
    launcher = @forAppNamed appClassName
    return unless launcher?
    world.add launcher
    launcher.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()

  # LAZY mode. undefined when this artifact can never produce the app — no widget is constructed and no
  # icon appears, rather than one whose click could only reject. ⚠ The availability question comes
  # BEFORE the catalog lookup and before the icon thunk runs, and it is `canEverProvideClass` rather
  # than `if TheApp?`: for a lazy class an existence test reads "not fetched yet" and would drop the
  # icon for ever, when what is being asked at boot is "can this artifact EVER produce it".
  @forAppNamed: (appClassName, iconOverride) ->
    return undefined unless world.parts.canEverProvideClass appClassName
    launcher = @_fromCatalogEntry appClassName, iconOverride: iconOverride
    launcher.appClassName = appClassName  if launcher?
    launcher

  # EAGER mode: the app singleton is already in hand, so the click is a plain call on it.
  @forApp: (app) ->
    @_fromCatalogEntry app.constructor.name, target: app, callback: "launch"

  # ⭐ THE ONE PLACE A LAUNCHER IS BUILT FROM AN APP'S IDENTITY, which is the whole point of the
  # catalog: a construction path per mode is how a field ends up on one launcher and not the other
  # (`toolTip` is the one that fits in a comment). One reader ⇒ a field reaches both modes or neither.
  # The app's name is the only operand — the two modes disagree on everything else, which is why
  # the rest ride opts: LAZY supplies iconOverride and no target, EAGER supplies target/callback
  # and no icon, so whichever came first positionally forced the other mode to skip it with an
  # `undefined` (R3). opts: iconOverride, target, callback.
  @_fromCatalogEntry: (appClassName, opts = {}) ->
    iconOverride = opts.iconOverride
    entry = AppCatalog.get appClassName
    if !entry?
      # a programming error, not a packaging one: the app exists but nothing says what it looks
      # like. Loud, because the boot smoke fails on console errors and will catch it immediately.
      console.error "AppCatalog has no entry for '#{appClassName}'"
      return undefined
    icon = if iconOverride? then iconOverride() else entry.icon()
    launcher = new @ entry.title, icon, opts.target, opts.callback
    launcher.toolTipMessage = entry.toolTip  if entry.toolTip?
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
