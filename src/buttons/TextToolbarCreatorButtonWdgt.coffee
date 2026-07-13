class TextToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "Text tools"

  createAppearance: -> new TextToolbarIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

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

    switcherooWm = new WindowWdgt toolsPanel
    switcherooWm._applyMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm._moveWithin world
    world.add switcherooWm
    switcherooWm._applyExtent new Point 130, 156

    return switcherooWm
