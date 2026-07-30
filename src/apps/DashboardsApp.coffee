# DashboardsApp -- the "Dashboards" launcher app: opens a fresh Dashboards window
# (+ its info widget) at the hand on each launch. An IconicDesktopSystemWindowedApp (6c.4).
# Distinct from SampleDashboardApp, which opens a filled sample dashboard.
class DashboardsApp extends IconicDesktopSystemWindowedApp

  title: "Dashboards"
  buildIcon:    -> new DashboardsIconWdgt
  buildWindow:  -> world.openFrameWith (new DashboardWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> InfoDocs.createNextTo "dashboards", wm

  # The window's docked DashboardsToolbarWdgt offers the two map tools, which are the LAZY 'maps'
  # part -- so bring it in at the door, or the palette would open two tools short. Same shape as
  # SampleDashboardApp.launch (which explains why the already-loaded path stays synchronous).
  launch: ->
    if world.parts.isLoaded "maps" then super()
    else world.parts.ensureLoaded("maps").then => super()
