# FizzyPaintApp -- the "Draw" launcher app: opens a fresh ImageWdgt (the framed
# paintable-image citizen, §5.D) + its info widget on each launch. An
# IconicDesktopSystemWindowedApp (Phase 6 6c.4); the base owns the
# launcher/opener + launch, and the openFrameWith passthrough hands the citizen
# through.
class FizzyPaintApp extends IconicDesktopSystemWindowedApp

  title: "Draw"
  buildIcon:    -> new PaintBucketIconWdgt
  buildWindow:  -> world.openFrameWith (new ImageWdgt), (new Point 460, 400), (new Point 174, 114)
  windowOpened: (wm) -> InfoDocs.createNextTo "drawingsMaker", wm
