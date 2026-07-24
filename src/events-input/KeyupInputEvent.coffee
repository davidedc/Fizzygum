class KeyupInputEvent extends KeyboardInputEvent

  processEvent: ->
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED

    # dispatch to keyboard receiver
    # so far the caret is the only keyboard
    # event handler and it has no keyup
    # handler
    # SNAPSHOT the receivers (same contract as KeydownInputEvent: the event is delivered to
    # the receivers registered when it arrived, never to one added mid-dispatch)
    for eachKeyboardEventsReceiver in Array.from world.keyboardEventsReceivers
      eachKeyboardEventsReceiver.processKeyUp? @key, @code, @shiftKey, @ctrlKey, @altKey, @metaKey

    # »>> this part is excluded from the fizzygum homepage build
    # catch the F2 key
    if @key == "F2" and !@shiftKey and !@ctrlKey and !@altKey and !@metaKey
      menusHelper.testMenuForMacros()
    # this part is excluded from the fizzygum homepage build <<«
