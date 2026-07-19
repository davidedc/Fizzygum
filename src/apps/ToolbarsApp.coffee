# ToolbarsApp -- the "Super Toolbar" launcher app: opens a fresh tools ScrollPanel (the
# toolbar-creator buttons) + its info widget on each launch. IconicDesktopSystemWindowedApp
# (Phase 6 6c.4). Building the toolbar-creator-button panel is its only bespoke step; the
# window wrap is the shared world.openFrameWith.
class ToolbarsApp extends IconicDesktopSystemWindowedApp

  title: "Super Toolbar"
  toolTip: "a toolbar to rule them all"

  buildIcon: -> new ToolbarsIconWdgt

  buildWindow: ->
    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    toolsPanel.addMany [
      new TextToolbarCreatorButtonWdgt
      new UsefulTextSnippetsToolbarCreatorButtonWdgt
      new SlidesToolbarCreatorButtonWdgt
      new PlotsToolbarCreatorButtonWdgt
      new PatchProgrammingComponentsToolbarCreatorButtonWdgt
      new WindowsToolbarCreatorButtonWdgt
    ]

    toolsPanel.disableDragsDropsAndEditing()
    world.openFrameWith toolsPanel, (new Point 60, 261), (new Point 170, 170)

  windowOpened: (wm) -> ToolbarsInfoWdgt.createNextTo wm
