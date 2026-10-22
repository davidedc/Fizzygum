class WindowsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "many types of\npre-made windows"

  createAppearance: -> new WindowsToolbarIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->

    switcherooWm = @_buildToolWindow new WindowsToolbarWdgt
    readmeWindow = InfoDocs.createNextTo "windowsToolbar", switcherooWm
    readmeWindow?._applyMoveTo new Point 300, 200

    return switcherooWm
