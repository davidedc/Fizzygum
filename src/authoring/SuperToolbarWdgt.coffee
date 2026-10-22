# The "Super toolbar" palette -- the toolbar of toolbar-creator buttons
# (ToolbarsApp opens it in a window; each button summons one specific palette).

class SuperToolbarWdgt extends ToolbarWdgt

  # the app's one name, as its desktop caption writes it (AppCatalog), so my window is titled with
  # it; every other palette is a "toolbar" (ToolPanelWdgt.viewportColloquialName)
  colloquialName: ->
    "Super toolbar"

  # The plots palette and the button that summons it both belong to the LAZY 'plots' part, so this
  # row simply does not offer it until the part is in. That is deliberate and it is why the palette
  # lives in the part too: every one of PlotsToolbarWdgt's items is a plot button, so leaving the
  # opener here and filtering the palette's own contents would pop an EMPTY window -- a worse
  # answer than not offering the palette yet.
  _toolbarItems: ->
    items = [
      new TextToolbarCreatorButtonWdgt
      new UsefulTextSnippetsToolbarCreatorButtonWdgt
      new SlidesToolbarCreatorButtonWdgt
      (new PlotsToolbarCreatorButtonWdgt if PlotsToolbarCreatorButtonWdgt?)
      new PatchProgrammingComponentsToolbarCreatorButtonWdgt
      new WindowsToolbarCreatorButtonWdgt
    ]
    (eachItem for eachItem in items when eachItem?)
