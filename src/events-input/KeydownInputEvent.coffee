class KeydownInputEvent extends KeyboardInputEvent

  processEvent: ->
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
    world.keyboardEventsReceiver?.processKeyDown @key, @code, @shiftKey, @ctrlKey, @altKey, @metaKey
