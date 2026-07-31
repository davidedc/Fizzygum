# SimpleDocumentApp -- the "Docs Maker" launcher app: opens a fresh DocumentWdgt
# (+ its info widget) on each launch. An IconicDesktopSystemWindowedApp (Phase 6 6c.4).
# Distinct from SampleDocApp, which opens a filled sample document.
class SimpleDocumentApp extends IconicDesktopSystemWindowedApp

  title: "Docs Maker"
  buildIcon:    -> new TypewriterIconWdgt

  # The window it opens is a citizen of the LAZY 'authoring' part, so bring the part in at the door.
  # REQUIRED, not optional: the part does not enrich this window, it IS this window. Awaiting is safe
  # because the base launch() is fire-and-forget, and the already-loaded path stays SYNCHRONOUS --
  # see PartsRegistry.whenAllLoaded for why that is correctness rather than speed.
  launch: ->
    world.parts.whenAllLoaded ["authoring"], => super()
  buildWindow:  -> world.openFrameWith (new DocumentWdgt), (new Point 370, 395), (new Point 170, 88)
  windowOpened: (wm) -> InfoDocs.createNextTo "docsMaker", wm
