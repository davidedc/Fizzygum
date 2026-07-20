class WindowsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "many types of\npre-made windows"

  createAppearance: -> new WindowsToolbarIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->

    switcherooWm = @_buildToolWindow new WindowsToolbarWdgt, new Point 61, 192
    readmeWindow = InfoDocs.createNextTo "windowsToolbar", switcherooWm
    readmeWindow?._applyMoveTo new Point 300, 200
    readmeWindow?._rememberFractionalSituationInHoldingPanel()

    return switcherooWm
