# ToolbarsApp -- the "Super Toolbar" launcher app: opens the SuperToolbarWdgt
# palette (the toolbar-creator buttons) + its info widget on each launch.
# IconicDesktopSystemWindowedApp (Phase 6 6c.4). The window wrap is the shared
# world.openFrameWith.
class ToolbarsApp extends IconicDesktopSystemWindowedApp

  title: "Super Toolbar"
  toolTip: "a toolbar to rule them all"

  buildIcon: -> new ToolbarsIconWdgt

  buildWindow: ->
    world.openFrameWith new SuperToolbarWdgt, (new Point 60, 261), (new Point 170, 170)

  windowOpened: (wm) -> InfoDocs.createNextTo "superToolbar", wm
