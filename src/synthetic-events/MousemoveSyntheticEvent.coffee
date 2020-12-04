# this file is only needed for Macros

class MousemoveSyntheticEvent
  pageX: nil
  pageY: nil
  button: nil
  buttons: nil
  ctrlKey: nil
  shiftKey: nil
  altKey: nil
  metaKey: nil

  constructor: (pageX, pageY, @button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey) ->
    # When the macro system calculates the mouse moves, it takes
    # as input information the logical coordinates of widgets,
    # which are all relative to the canvas. Those then need to be
    # transformed into actual mouse event positions, which are in logical
    # coordinates *relative to the page*, hence this offset
    # adjustment here.
    canvasPosition = world.getCanvasPosition()
    @pageX = pageX + canvasPosition.x
    @pageY = pageY + canvasPosition.y
