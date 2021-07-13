class TouchstartInputEvent extends TouchInputEvent

  processEvent: ->
    # note that the position can be non-integer, so rounding it
    # we have no real use for fractional input position and it's complicated
    # to handle for drawing, clipping etc., better stick to integer coords
    # TODO it might be nice to discard duplicates due to the fact that
    # two events in a row (first one being fractional and second one being integer)
    # might be lumped-up into the same integer position
    world.hand.processMouseMove Math.round(@touches[0].pageX), Math.round(@touches[0].pageY), 0, 0, @ctrlKey, @shiftKey, @altKey, @metaKey
    world.hand.processMouseDown 0,1, @ctrlKey, @shiftKey, @altKey, @metaKey

    #console.log "touchstartBrowserEvent"
