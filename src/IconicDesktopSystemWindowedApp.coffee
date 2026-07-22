# IconicDesktopSystemWindowedApp -- base class for the desktop's windowed "apps"
# (Draw, Docs Maker, Slides Maker, the sample doc/slide/dashboard examples, the
# degrees converter, ...). It lifts the launch / opener / bring-up apparatus that
# used to be copy-pasted across ~12 MenusHelper methods into ONE place. A subclass
# only declares its launcher title/icon (and, for a singleton app, the world slot
# that holds its one window) and implements buildWindow; this base owns:
#   - createOpener: builds the IconicDesktopSystemWindowedAppLauncherWdgt (the
#     desktop or in-folder shortcut) pointing at this app's "launch" action, and
#   - launch: for a singleton app (slot set) brings the existing window forward or
#     builds it; for a fresh app builds a new window and runs the windowOpened hook
#     (e.g. to spawn the adjacent Info widget).
# The launcher stores THIS object as its reflection target, and launchers are
# deep-copyable desktop widgets, so this declares keptByReferenceOnDeepCopy: true
# (DeepCopierMixin then keeps the per-app singleton by reference instead of cloning
# it -- the same guardrail Wallpaper/WidgetFactory use). OO-backlog Phase 6 step 6c.
class IconicDesktopSystemWindowedApp

  keptByReferenceOnDeepCopy: true

  # Serialization: each app singleton is encoded symbolically as {"$wk":"app:<ClassName>"}
  # and re-resolved (in Phase 5, launched if absent) against the destination world. A
  # method because the key is per-subclass. See docs/architecture/serialization-duplication-reference.md
  # §4a.
  wellKnownKey: -> "app:" + @constructor.name

  # --- per-app configuration (subclasses override) ---
  title: nil
  slot: nil           # world.<slot> holds the single window; nil => a fresh window every launch
  toolTip: nil

  # --- per-app hooks (subclasses override) ---
  buildIcon: -> nil                      # the launcher's icon widget
  buildWindow: -> nil                    # build + world.add the app's window; return it
  windowOpened: (newlyOpenedWindow) ->   # after a FRESH (non-singleton) launch; no-op by default

  # --- shared apparatus (written once) ---
  createOpener: (inWhichFolder) ->
    launcher = new IconicDesktopSystemWindowedAppLauncherWdgt @title, @buildIcon(), @, "launch"
    launcher.toolTipMessage = @toolTip if @toolTip?
    if inWhichFolder?
      # in-folder opener: size first, then add into the folder
      launcher.setExtent new Point 75, 75
      inWhichFolder.contents.contents.add launcher
    else
      # desktop launcher: add first (smart grid placement), then size
      world.add launcher
      launcher.setExtent new Point 75, 75

  launch: ->
    if @slot?
      existingWindow = world[@slot]
      if existingWindow? and !existingWindow.destroyed and existingWindow.parent?
        # §7.5 Bug B (model a) + latent 2 (Option B): the singleton may have been closed to the basement AS
        # A FIGURE -- if it was tilted/scaled (sugar) or explicitly islanded, world[@slot] is the window but
        # its enclosing sole-content island is what carries the transform, so re-home and reposition the
        # FIGURE, not the bare window (moving an island-resident window by SCREEN coords would be a plane
        # mismatch, 4A-2). Off any island the figure is the window itself ⇒ byte-identical to the pre-Bug-B path.
        figure = existingWindow._enclosingIslandFigure()
        world.add figure
        figure.bringToForeground()
        figure._applyMoveTo world.hand.position().add new Point 100, -50
        figure._moveWithin world
        figure._rememberFractionalSituationInHoldingPanel()
        return
      world[@slot] = @buildWindow()
    else
      @windowOpened @buildWindow()
