# SimpleDocumentApp -- the "Docs Maker" launcher app: opens a fresh DocumentWdgt
# (+ its info widget) on each launch. An WindowedApp (Phase 6 6c.4).
# Distinct from SampleDocApp, which opens a filled sample document.
class SimpleDocumentApp extends WindowedApp

  requiredParts: ["authoring"]

  buildWindow:  -> world.openFrameWith (new DocumentWdgt), (new Point 370, 395), (new Point 170, 88)
  windowOpened: (wm) -> InfoDocs.createNextTo "docsMaker", wm
