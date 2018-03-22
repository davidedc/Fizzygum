class ToolbarCreatorButtonWdgt extends CreatorButtonWdgt

  mouseClickLeft: (ignored, ignored2, ignored3, ignored4, ignored5, ignored6, ignored7, partOfDoubleClick) ->
    if partOfDoubleClick
      return
    windowToBePlaced = @createWidgetToBeHandled()
    windowToBePlaced.fullRawMoveTo @topRight().add new Point 20,-40
    world.add windowToBePlaced
    windowToBePlaced.fullRawMoveWithin world
