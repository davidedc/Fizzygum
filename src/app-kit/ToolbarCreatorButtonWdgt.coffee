class ToolbarCreatorButtonWdgt extends CreatorButtonWdgt

  mouseClickLeft: (ignored, ignored2, ignored3, ignored4, ignored5, ignored6, ignored7, partOfDoubleClick) ->
    if partOfDoubleClick
      return
    windowToBePlaced = @createWidgetToBeHandled()
    # the new window is a WORLD child placed beside ME, and I live on a toolbar's scrolled
    # plane — emit my corner through the plane→screen map (identity when unscrolled/untilted,
    # rounded because screen-family values may be fractional under tilt), never the raw
    # plane-local @topRight() (paint-time scroll review F1).
    windowToBePlaced._applyMoveTo (@localPointToScreen @topRight()).round().add new Point 20, -40
    world.add windowToBePlaced
    windowToBePlaced._moveWithin world

  # Shared window-building scaffold for the toolbar creator buttons: take a
  # ready-built, drops/edit-disabled tools panel (each subclass fills and locks
  # its own), wrap it in a FrameWdgt that HUGS it, and place it down the left of
  # the world, centred on whatever height the hug produced. Returns the window.
  # The palette's size is the ONE payload derivation
  # (FrameWdgt.sizeToPayloadNaturalExtent) rather than a constant per palette, so
  # every toolbar this scaffold opens is sized by the same criterion -- which is
  # also why PlotsToolbarCreatorButtonWdgt comes through here now: its own
  # size-then-place order had nothing left to differ about.
  _buildToolWindow: (toolsPanel) ->
    switcherooWm = new FrameWdgt toolsPanel
    switcherooWm.sizeToPayloadNaturalExtent()
    switcherooWm._applyMoveTo new Point 90, Math.floor((world.height() - switcherooWm.height()) / 2)
    switcherooWm._moveWithin world
    world.add switcherooWm

    return switcherooWm
