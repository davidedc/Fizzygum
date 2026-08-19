# PatchProgrammingApp -- the "Patch programming" launcher app: opens a fresh PatchProgramming
# window (+ its info widget) at the hand on each launch. WindowedApp (6c.4).
class PatchProgrammingApp extends WindowedApp

  requiredParts: ["authoring"]

  buildWindow:  -> world.openFrameWith (new PatchProgrammingWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> InfoDocs.createNextTo "patchProgramming", wm
