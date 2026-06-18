# PatchProgrammingApp -- the "Patch progr." launcher app: opens a fresh PatchProgramming
# window (+ its info widget) at the hand on each launch. IconicDesktopSystemWindowedApp (6c.4).
class PatchProgrammingApp extends IconicDesktopSystemWindowedApp

  title: "Patch progr."
  buildIcon:    -> new PatchProgrammingIconWdgt
  buildWindow:  -> world.openWindowWith (new PatchProgrammingWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> PatchProgrammingInfoWdgt.createNextTo wm
