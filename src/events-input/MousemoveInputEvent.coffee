class MousemoveInputEvent extends MouseInputEvent
  pageX: nil
  pageY: nil

  constructor: (pageX, pageY, button, buttons, ctrlKey, shiftKey, altKey, metaKey, isSynthetic, time) ->
    super button, buttons, ctrlKey, shiftKey, altKey, metaKey, isSynthetic, time
    # When the macro system calculates the mouse moves, it takes
    # as input information the logical coordinates of widgets,
    # which are all relative to the canvas. Those then need to be
    # transformed into actual mouse event positions, which are in logical
    # coordinates *relative to the page*, hence this offset
    # adjustment here.
    canvasPosition = world.getCanvasPosition()
    @pageX = pageX + canvasPosition.x
    @pageY = pageY + canvasPosition.y

  @fromBrowserEvent: (event, isSynthetic, time) ->
    new @ event.pageX, event.pageY, event.button, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey, isSynthetic, time


  processEvent: ->

    world.hand.processMouseMove @pageX, @pageY, @button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey
    # "@hand.processMouseMove" could cause a Grab
    # command to be issued, so we want to
    # add the mouse move command here *after* the
    # potential grab command.

    #if @hand.isThisPointerFloatDraggingSomething()
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
