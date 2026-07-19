# The "Super Toolbar" palette -- the toolbar of toolbar-creator buttons
# (ToolbarsApp opens it in a window; each button summons one specific palette).

class SuperToolbarWdgt extends ToolbarWdgt

  _toolbarItems: -> [
    new TextToolbarCreatorButtonWdgt
    new UsefulTextSnippetsToolbarCreatorButtonWdgt
    new SlidesToolbarCreatorButtonWdgt
    new PlotsToolbarCreatorButtonWdgt
    new PatchProgrammingComponentsToolbarCreatorButtonWdgt
    new WindowsToolbarCreatorButtonWdgt
  ]
