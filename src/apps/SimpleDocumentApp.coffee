# SimpleDocumentApp -- the "Docs Maker" launcher app: opens a fresh DocumentWdgt
# (+ its info widget) on each launch. An IconicDesktopSystemWindowedApp (Phase 6 6c.4).
# Distinct from SampleDocApp, which opens a filled sample document.
class SimpleDocumentApp extends IconicDesktopSystemWindowedApp

  title: "Docs Maker"
  buildIcon:    -> new TypewriterIconWdgt
  buildWindow:  -> world.openFrameWith (new DocumentWdgt), (new Point 370, 395), (new Point 170, 88)
  windowOpened: (wm) -> SimpleDocumentInfoWdgt.createNextTo wm
