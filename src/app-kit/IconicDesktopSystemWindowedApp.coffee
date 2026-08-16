# IconicDesktopSystemWindowedApp -- base class for the desktop's windowed "apps"
# (Draw, Docs Maker, Slides Maker, the sample doc/slide/dashboard examples, the
# degrees converter, ...). It lifts the launch / opener / bring-up apparatus that
# used to be copy-pasted across ~12 MenusHelper methods into ONE place. A subclass
# declares the parts its window is built from (and, for a singleton app, the world
# slot that holds its one window) and implements buildWindow; this base owns:
#   - createOpener: builds the IconicDesktopSystemWindowedAppLauncherWdgt (the
#     desktop or in-folder shortcut) pointing at this app's "launch" action, and
# ⚠ WHAT AN APP LOOKS LIKE IS NOT DECLARED HERE. Its caption, icon and tooltip live
# in AppCatalog, keyed by class NAME, because the desktop draws an app's icon at BOOT
# for an app whose class has not been fetched -- reading a field off this object would
# make every app eager again. See AppCatalog's header and build-and-packaging.md §2.
#   - launch: for a singleton app (slot set) brings the existing window forward or
#     builds it; for a fresh app builds a new window and runs the windowOpened hook
#     (e.g. to spawn the adjacent Info widget).
# The launcher stores THIS object as its reflection target, and launchers are
# deep-copyable desktop widgets, so this declares keptByReferenceOnDeepCopy: true
# (the Duplicator then keeps the per-app singleton by reference instead of cloning
# it -- the same guardrail Wallpaper/WidgetFactory use). OO-backlog Phase 6 step 6c.
class IconicDesktopSystemWindowedApp

  keptByReferenceOnDeepCopy: true

  # Serialization: each app singleton is encoded symbolically as {"$wk":"app:<ClassName>"}
  # and re-resolved (in Phase 5, launched if absent) against the destination world. A
  # method because the key is per-subclass. See docs/architecture/serialization-duplication-reference.md
  # §4a.
  wellKnownKey: -> "app:" + @constructor.name

  # --- per-app configuration (subclasses override) ---
  slot: undefined           # world.<slot> holds the single window; undefined => a fresh window every launch

  # THE PARTS THIS APP'S buildWindow BUILDS FROM. One declaration with two readers, which is the
  # whole point of stating it as data rather than writing the await by hand in each subclass:
  #   - `launch` below awaits exactly this, so the window is never assembled from absent classes;
  #   - buildSystem/check-part-edges.js reads the same line, and treats it as satisfying every
  #     reference this class makes into those parts -- because the gate reads one line at a time
  #     and can never see that a `launch` three methods up already awaited.
  # A declaration cannot drift from the await, because the await IS the declaration -- a hand-written
  # launch override defeats the gate the same way (case history: docs/architecture/build-and-packaging.md).
  # ⚠ REQUIRED vs OPTIONAL is the distinction PartsRegistry documents: `requiredParts` CONSTITUTE
  # the window (a Sample doc that assembles plots is broken without them, so it must reject loudly),
  # `optionalParts` merely ENRICH it (a docked palette offers fewer tools, which is reduced rather
  # than broken). ⚠ Only `requiredParts` satisfies the gate -- an optional part may genuinely be
  # absent, so a reference to one still has to be guarded where it stands.
  requiredParts: []
  optionalParts: []

  # --- per-app hooks (subclasses override) ---
  buildWindow: -> undefined                    # build + world.add the app's window; return it
  windowOpened: (newlyOpenedWindow) ->   # after a FRESH (non-singleton) launch; no-op by default

  # --- shared apparatus (written once) ---
  # Put this app's EAGER launcher on the desktop. Takes NOTHING, and that is load-bearing: it is
  # wired to demo menu items, and ButtonWdgt dispatches actions with a fixed four-slot convention
  # (`@target[@action].call @target, menuItem, panelTarget, arg1, arg2`), so any parameter here would
  # receive a WIDGET from a click. A verb that takes nothing cannot be mis-fed by the dispatcher.
  # ⚠ The in-folder variant lives on the launcher class as
  # IconicDesktopSystemWindowedAppLauncherWdgt.addToFolder — go there rather than re-growing a
  # parameter here; note the two add/size ORDERS are not interchangeable, which that pair documents.
  createOpener: ->
    launcher = IconicDesktopSystemWindowedAppLauncherWdgt.forApp @
    return unless launcher?
    # desktop launcher: add first (smart grid placement), then size
    world.add launcher
    launcher.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()

  # ⚠ Both already-loaded paths stay SYNCHRONOUS, which is correctness rather than speed: whenAllLoaded
  # runs its callback inline when the parts are in, and an EMPTY list is inline too, so an app that
  # declares nothing pays not one microtask. Deferring by even a microtask moves the launch a whole
  # world CYCLE later, and the SystemTest suite measures cycles (../Fizzygum-tests/DETERMINISM.md).
  launch: ->
    world.parts.whenAllLoaded @requiredParts, =>
      world.parts.whenOptionalPartsLoaded @optionalParts, =>
        @_launchNow()

  _launchNow: ->
    if @slot?
      existingWindow = world[@slot]
      if existingWindow? and !existingWindow.destroyed and existingWindow.parent?
        # §7.5 Bug B (model a) + latent 2 (Option B): the singleton may have been closed to the bin AS
        # A FIGURE -- if it was tilted/scaled (sugar) or explicitly islanded, world[@slot] is the window but
        # its enclosing sole-content island is what carries the transform, so re-home and reposition the
        # FIGURE, not the bare window (moving an island-resident window by SCREEN coords would be a plane
        # mismatch, 4A-2). Off any island the figure is the window itself ⇒ byte-identical to the pre-Bug-B path.
        figure = existingWindow._enclosingIslandFigure()
        world.add figure
        figure.bringToForeground()
        figure._applyMoveTo world.hand.position().add new Point 100, -50
        figure._moveWithin world
        # RE-RECORD (the F6 family, auto-bookkeeping arc): the window carries fractional
        # bookkeeping from its previous desktop life, which the fill-only seed respects --
        # after this re-home moves it, its proportional situation must be re-derived
        # explicitly or the next desktop reflow snaps it back to the old spot.
        figure._rememberFractionalSituationInHoldingPanel()
        return
      world[@slot] = @buildWindow()
      # an app-slot write is a reachability chokepoint (the slot is what the
      # classifier's furniture marking reads) -- mark for the storage sort
      world.noteStorageMembershipMayHaveChanged()
    else
      @windowOpened @buildWindow()
