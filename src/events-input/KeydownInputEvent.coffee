class KeydownInputEvent extends KeyboardInputEvent

  processEvent: ->
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
    #
    # SNAPSHOT the receivers: this event is delivered to the receivers registered when it
    # ARRIVED. A receiver added while it is being processed (world.edit creating a caret from
    # inside a receiver's handler — a Tab hop's switchTextFieldFocus, the spreadsheet starting
    # a cell edit on a printable/Enter key) must NOT also receive it: iterating the live Set
    # made one Tab press runaway-hop through every entry field (each new caret was visited and
    # re-handled the same Tab), and made an edit-starting key double-deliver into the fresh
    # caret (a seeded char typed twice; Enter-to-edit instantly self-accepted).
    for eachKeyboardEventsReceiver in Array.from world.keyboardEventsReceivers
      eachKeyboardEventsReceiver.processKeyDown @key, @code, @shiftKey, @ctrlKey, @altKey, @metaKey
