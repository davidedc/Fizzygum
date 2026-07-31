# DashboardsApp -- the "Dashboards" launcher app: opens a fresh Dashboards window
# (+ its info widget) at the hand on each launch. An IconicDesktopSystemWindowedApp (6c.4).
# Distinct from SampleDashboardApp, which opens a filled sample dashboard.
class DashboardsApp extends IconicDesktopSystemWindowedApp

  title: "Dashboards"
  buildIcon:    -> new DashboardsIconWdgt
  buildWindow:  -> world.openFrameWith (new DashboardWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> InfoDocs.createNextTo "dashboards", wm

  # The window's docked DashboardsToolbarWdgt offers the two map tools and the plot tools, which are
  # the LAZY 'maps' and 'plots' parts -- so bring them in at the door, or the palette would open
  # several tools short. (The already-loaded path stays synchronous; see PartsRegistry.)
  #
  # ⚠ OPTIONAL, not required: these parts ENRICH this window, they do not constitute it. A profile
  # may ship neither -- `lean` does -- and there the right outcome is a Dashboards window with a
  # smaller palette, which is what the toolbar's own `if WorldMapCreatorButtonWdgt?` filters already
  # produce. whenAllLoaded would instead REJECT on such a build, so this always-shipped desktop icon
  # would open nothing at all. See PartsRegistry.whenOptionalPartsLoaded.
  launch: ->
    world.parts.whenOptionalPartsLoaded ["maps", "plots"], => super()
