class ToolbarCreatorButtonWdgt extends CreatorButtonWdgt

  mouseClickLeft: (ignored, ignored2, ignored3, ignored4, ignored5, ignored6, ignored7, partOfDoubleClick) ->
    if partOfDoubleClick
      return
    windowToBePlaced = @createWidgetToBeHandled()
    windowToBePlaced._applyMoveTo @topRight().add new Point 20,-40
    world.add windowToBePlaced
    windowToBePlaced._moveWithin world

  # Shared window-building scaffold for the toolbar creator buttons: take a
  # ready-built, drops/edit-disabled tools panel (each subclass fills and locks
  # its own), wrap it in a FrameWdgt, place it, add it to the world and size it
  # to the given extent. Returns the window.
  # NB PlotsToolbarCreatorButtonWdgt is deliberately NOT routed through here: it
  # sizes with the public setExtent BEFORE placing, a different op order.
  _buildToolWindow: (toolsPanel, extent) ->
    switcherooWm = new FrameWdgt toolsPanel
    switcherooWm._applyMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm._moveWithin world
    world.add switcherooWm
    switcherooWm._applyExtent extent

    return switcherooWm
