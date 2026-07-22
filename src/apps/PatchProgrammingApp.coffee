# PatchProgrammingApp -- the "Patch programming" launcher app: opens a fresh PatchProgramming
# window (+ its info widget) at the hand on each launch. IconicDesktopSystemWindowedApp (6c.4).
class PatchProgrammingApp extends IconicDesktopSystemWindowedApp

  title: "Patch programming"
  buildIcon:    -> new PatchProgrammingIconWdgt
  buildWindow:  -> world.openFrameWith (new PatchProgrammingWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> InfoDocs.createNextTo "patchProgramming", wm
