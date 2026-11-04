# The "Super toolbar" -- the toolbar of toolbar-creator buttons
# (ToolbarsApp opens it in a window; each button summons one specific toolbar). EVERY TOOLBAR HAS AN
# ENTRY here, the one place any toolbar can be called up floating, whichever window docks it too: the
# text, snippets, slides, sheet, dashboards, plots, paint, patch-programming and windows toolbars.

class SuperToolbarWdgt extends ToolbarWdgt

  # the app's one name, as its desktop caption writes it (AppCatalog), so my window is titled with
  # it; every other toolbar is plain "toolbar" (ToolPanelWdgt.viewportColloquialName)
  colloquialName: ->
    "Super toolbar"

  # The plots toolbar and the button that summons it both belong to the LAZY 'plots' part, so this
  # row simply does not offer it until the part is in. That is deliberate and it is why the toolbar
  # lives in the part too: every one of PlotsToolbarWdgt's items is a plot button, so leaving the
  # opener here and filtering the toolbar's own contents would pop an EMPTY window -- a worse
  # answer than not offering the toolbar yet.
  _toolbarItems: ->
    items = [
      new TextToolbarCreatorButtonWdgt
      new UsefulTextSnippetsToolbarCreatorButtonWdgt
      new SlidesToolbarCreatorButtonWdgt
      new SheetToolbarCreatorButtonWdgt
      new DashboardsToolbarCreatorButtonWdgt
      (new PlotsToolbarCreatorButtonWdgt if PlotsToolbarCreatorButtonWdgt?)
      new PaintToolbarCreatorButtonWdgt
      new PatchProgrammingComponentsToolbarCreatorButtonWdgt
      new WindowsToolbarCreatorButtonWdgt
    ]
    (eachItem for eachItem in items when eachItem?)
