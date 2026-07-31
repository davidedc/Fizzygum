# ToolbarsApp -- the "Super Toolbar" launcher app: opens the SuperToolbarWdgt
# palette (the toolbar-creator buttons) + its info widget on each launch.
# IconicDesktopSystemWindowedApp (Phase 6 6c.4). The window wrap is the shared
# world.openFrameWith.
class ToolbarsApp extends IconicDesktopSystemWindowedApp

  title: "Super Toolbar"
  toolTip: "a toolbar to rule them all"

  buildIcon: -> new ToolbarsIconWdgt

  # The window it opens is a citizen of the LAZY 'authoring' part, so bring the part in at the door.
  # REQUIRED, not optional: the part does not enrich this window, it IS this window. Awaiting is safe
  # because the base launch() is fire-and-forget, and the already-loaded path stays SYNCHRONOUS --
  # see PartsRegistry.whenAllLoaded for why that is correctness rather than speed.
  launch: ->
    world.parts.whenAllLoaded ["authoring"], => super()

  buildWindow: ->
    world.openFrameWith new SuperToolbarWdgt, (new Point 60, 261), (new Point 170, 170)

  windowOpened: (wm) -> InfoDocs.createNextTo "superToolbar", wm
