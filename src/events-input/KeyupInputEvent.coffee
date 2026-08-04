class KeyupInputEvent extends KeyboardInputEvent

  processEvent: ->
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED

    # dispatch to keyboard receivers (world.keyboardEventsReceivers -- the caret always;
    # the spreadsheet and the video player register too). None of them implements
    # processKeyUp today, so this loop is currently a no-op.
    # SNAPSHOT the receivers (same contract as KeydownInputEvent: the event is delivered to
    # the receivers registered when it arrived, never to one added mid-dispatch)
    for eachKeyboardEventsReceiver in Array.from world.keyboardEventsReceivers
      eachKeyboardEventsReceiver.processKeyUp? @key, @code, @shiftKey, @ctrlKey, @altKey, @metaKey

    # catch the F2 key: it opens the macro test menu, which lives with the harness
    # (Automator-and-test-harness-src/MenusHelperTestSupport.coffee). The soak is what
    # makes the key inert in a build that ships no harness.
    if @key == "F2" and !@shiftKey and !@ctrlKey and !@altKey and !@metaKey
      menusHelper.testMenuForMacros?()
