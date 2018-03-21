class ToolbarCreatorButtonWdgt extends CreatorButtonWdgt

  mouseClickLeft: ->
    windowToBePlaced = @createWidgetToBeHandled()
    windowToBePlaced.fullRawMoveTo @topRight().add new Point 20,-40
    world.add windowToBePlaced
    windowToBePlaced.fullRawMoveWithin world
