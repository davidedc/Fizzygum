class TouchmoveInputEvent extends TouchInputEvent
  processEvent: ->
    # note that the position can be non-integer, so rounding it
    # we have no real use for fractional input position and it's complicated
    # to handle for drawing, clipping etc., better stick to integer coords
    world.hand.processMouseMove Math.round(@touches[0].pageX), Math.round(@touches[0].pageY), 0, 1, @ctrlKey, @shiftKey, @altKey, @metaKey

    #console.log "touchmoveBrowserEvent " + event.touches[0].pageX + "  " + event.touches[0].pageY
