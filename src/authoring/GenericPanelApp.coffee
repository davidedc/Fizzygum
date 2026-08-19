# GenericPanelApp -- the "Generic panel" launcher app: opens a fresh GenericPanelWdgt
# citizen (+ its info widget) at the hand on each launch. WindowedApp (6c.4).
class GenericPanelApp extends WindowedApp

  requiredParts: ["authoring"]

  buildWindow:  -> world.openFrameWith (new GenericPanelWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> InfoDocs.createNextTo "genericPanel", wm
