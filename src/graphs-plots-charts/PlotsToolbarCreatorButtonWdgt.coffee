class PlotsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "plots/graphs"

  createAppearance: -> new AllPlotsIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->

    switcherooWm = new FrameWdgt new PlotsToolbarWdgt
    switcherooWm.setExtent new Point 60, 192
    switcherooWm._applyMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm._moveWithin world
    world.add switcherooWm

    return switcherooWm

