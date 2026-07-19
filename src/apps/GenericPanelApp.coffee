# GenericPanelApp -- the "Generic panel" launcher app: opens a fresh GenericPanelWdgt
# citizen (+ its info widget) at the hand on each launch. IconicDesktopSystemWindowedApp (6c.4).
class GenericPanelApp extends IconicDesktopSystemWindowedApp

  title: "Generic panel"
  buildIcon:    -> new GenericPanelIconWdgt
  buildWindow:  -> world.openFrameWith (new GenericPanelWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> GenericPanelInfoWdgt.createNextTo wm
