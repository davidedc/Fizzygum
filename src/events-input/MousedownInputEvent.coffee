class MousedownInputEvent extends MouseInputEvent

  # TODO mouseup and mousedown currently don't take the pointer position
  # from the event - the idea being that the position is always changed
  # by a mousemove, so we only change the pointer position on move events
  # so we don't need it on mouseup or mousedown.
  # While this thinking is "parsimonious", it doesn't apply well to pointer events,
  # where there is no pointer update until the "down" happens.
  # So we'll need to correct this eventually

  processEvent: ->
    # the recording of the test command (in case we are
    # recording a test) is handled inside the function
    # here below.
    # This is different from the other methods similar
    # to this one but there is a little bit of
    # logic we apply in case there is a right-click,
    # or user left or right-clicks on a menu,
    # in which case we record a more specific test
    # commands.
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
    world.hand.processMouseDown @button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey
