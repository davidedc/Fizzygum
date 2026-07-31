# GenericPanelApp -- the "Generic panel" launcher app: opens a fresh GenericPanelWdgt
# citizen (+ its info widget) at the hand on each launch. IconicDesktopSystemWindowedApp (6c.4).
class GenericPanelApp extends IconicDesktopSystemWindowedApp

  title: "Generic panel"
  buildIcon:    -> new GenericPanelIconWdgt

  # The window it opens is a citizen of the LAZY 'authoring' part, so bring the part in at the door.
  # REQUIRED, not optional: the part does not enrich this window, it IS this window. Awaiting is safe
  # because the base launch() is fire-and-forget, and the already-loaded path stays SYNCHRONOUS --
  # see PartsRegistry.whenAllLoaded for why that is correctness rather than speed.
  launch: ->
    world.parts.whenAllLoaded ["authoring"], => super()
  buildWindow:  -> world.openFrameWith (new GenericPanelWdgt), (new Point 460, 400), world.hand.position()
  windowOpened: (wm) -> InfoDocs.createNextTo "genericPanel", wm
