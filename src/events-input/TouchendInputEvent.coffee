class TouchendInputEvent extends TouchInputEvent

  processEvent: ->
    world.hand.processMouseUp 0,0, @ctrlKey, @shiftKey, @altKey, @metaKey
