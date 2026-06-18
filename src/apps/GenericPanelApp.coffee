# GenericPanelApp -- the "Generic panel" launcher app: opens a fresh StretchableEditable
# window (+ its info widget) at the hand on each launch. IconicDesktopSystemWindowedApp (6c.4).
class GenericPanelApp extends IconicDesktopSystemWindowedApp

  title: "Generic panel"
  buildIcon:    -> new GenericPanelIconWdgt
  buildWindow:  -> @openWindowWith (new StretchableEditableWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> GenericPanelInfoWdgt.createNextTo wm
