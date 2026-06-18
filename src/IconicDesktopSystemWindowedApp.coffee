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
      # in-folder opener: size first, then add into the folder (no fullChanged)
      launcher.setExtent new Point 75, 75
      inWhichFolder.contents.contents.add launcher
    else
      # desktop launcher: add first (smart grid placement), then size, then repaint
      world.add launcher
      launcher.setExtent new Point 75, 75
      launcher.fullChanged()

  launch: ->
    if @slot?
      existingWindow = world[@slot]
      if existingWindow? and !existingWindow.destroyed and existingWindow.parent?
        world.add existingWindow
        existingWindow.bringToForeground()
        existingWindow.fullRawMoveTo world.hand.position().add new Point 100, -50
        existingWindow.fullRawMoveWithin world
        existingWindow.rememberFractionalSituationInHoldingPanel()
        return
      world[@slot] = @buildWindow()
    else
      @windowOpened @buildWindow()
