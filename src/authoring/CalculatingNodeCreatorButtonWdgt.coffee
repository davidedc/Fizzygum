class CalculatingNodeCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "calculating node"

  createAppearance: -> new CalculatingNodeIconAppearance @, WorldWdgt.theme.iconInk

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new CalculatingPatchNodeWdgt
    switcherooWm._applyExtent new Point 260, 265
    return switcherooWm
