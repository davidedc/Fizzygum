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

    return @_buildToolWindow toolsPanel, new Point 130, 156
