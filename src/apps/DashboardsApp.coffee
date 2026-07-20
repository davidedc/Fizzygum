# DashboardsApp -- the "Dashboards" launcher app: opens a fresh Dashboards window
# (+ its info widget) at the hand on each launch. An IconicDesktopSystemWindowedApp (6c.4).
# Distinct from SampleDashboardApp, which opens a filled sample dashboard.
class DashboardsApp extends IconicDesktopSystemWindowedApp

  title: "Dashboards"
  buildIcon:    -> new DashboardsIconWdgt
  buildWindow:  -> world.openFrameWith (new DashboardWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> InfoDocs.createNextTo "dashboards", wm
