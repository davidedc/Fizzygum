class KeydownInputEvent extends KeyboardInputEvent

  processEvent: ->
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
    for eachKeyboardEventsReceiver from world.keyboardEventsReceivers
      eachKeyboardEventsReceiver.processKeyDown @key, @code, @shiftKey, @ctrlKey, @altKey, @metaKey
