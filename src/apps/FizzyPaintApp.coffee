# FizzyPaintApp -- the "Draw" launcher app: opens a fresh ReconfigurablePaint window
# (+ its info widget) on each launch. An IconicDesktopSystemWindowedApp (Phase 6 6c.4);
# the base owns the launcher/opener + launch, and world.openFrameWith does the window wrap.
class FizzyPaintApp extends IconicDesktopSystemWindowedApp

  title: "Draw"
  buildIcon:    -> new PaintBucketIconWdgt
  buildWindow:  -> world.openFrameWith (new ReconfigurablePaintWdgt), (new Point 460, 400), (new Point 174, 114)
  windowOpened: (wm) -> ReconfigurablePaintInfoWdgt.createNextTo wm
