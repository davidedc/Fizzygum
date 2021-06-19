# this file is only needed for Macros

class MousemoveInputEvent extends MouseInputEvent
  pageX: nil
  pageY: nil

  constructor: (pageX, pageY, button, buttons, ctrlKey, shiftKey, altKey, metaKey) ->
    super button, buttons, ctrlKey, shiftKey, altKey, metaKey
    # When the macro system calculates the mouse moves, it takes
    # as input information the logical coordinates of widgets,
    # which are all relative to the canvas. Those then need to be
    # transformed into actual mouse event positions, which are in logical
    # coordinates *relative to the page*, hence this offset
    # adjustment here.
    canvasPosition = world.getCanvasPosition()
    @pageX = pageX + canvasPosition.x
    @pageY = pageY + canvasPosition.y
