class TextToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  constructor: ->
    super
    @appearance = new TextToolbarIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "Text tools"

  createWidgetToBeHandled: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    toolsPanel.addMany [
      new ChangeFontButtonWdgt @
      new BoldButtonWdgt
      new ItalicButtonWdgt
      new FormatAsCodeButtonWdgt
      new IncreaseFontSizeButtonWdgt
      new DecreaseFontSizeButtonWdgt

      new AlignLeftButtonWdgt
      new AlignCenterButtonWdgt
      new AlignRightButtonWdgt
    ]

    toolsPanel.disableDragsDropsAndEditing()

    switcherooWm = new WindowWdgt nil, nil, toolsPanel
    switcherooWm.fullRawMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm.fullRawMoveWithin world
    world.add switcherooWm
    switcherooWm.rawSetExtent new Point 130, 156

    return switcherooWm
