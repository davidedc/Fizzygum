# FizzyPaintApp -- the "Draw" launcher app: opens a fresh ImageWdgt (the framed
# paintable-image citizen, §5.D) + its info widget on each launch. An
# IconicDesktopSystemWindowedApp (Phase 6 6c.4); the base owns the
# launcher/opener + launch, and the openFrameWith passthrough hands the citizen
# through.
class FizzyPaintApp extends IconicDesktopSystemWindowedApp

  title: "Draw"
  buildIcon:    -> new PaintBucketIconWdgt

  # The window it opens is a citizen of the LAZY 'authoring' part, so bring the part in at the door.
  # REQUIRED, not optional: the part does not enrich this window, it IS this window. Awaiting is safe
  # because the base launch() is fire-and-forget, and the already-loaded path stays SYNCHRONOUS --
  # see PartsRegistry.whenAllLoaded for why that is correctness rather than speed.
  launch: ->
    world.parts.whenAllLoaded ["authoring"], => super()
  buildWindow:  -> world.openFrameWith (new ImageWdgt), (new Point 460, 400), (new Point 174, 114)
  windowOpened: (wm) -> InfoDocs.createNextTo "drawingsMaker", wm
