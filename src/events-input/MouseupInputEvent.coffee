# this file is only needed for Macros

class MouseupInputEvent extends MouseInputEvent

  # TODO mouseup and mousedown currently don't take the pointer position
  # from the event - the idea being that the position is always changed
  # by a mousemove, so we only change the pointer position on move events
  # so we don't need it on mouseup or mousedown.
  # While this thinking is "parsimonious", it doesn't apply well to pointer events,
  # where there is no pointer update until the "down" happens.
  # So we'll need to correct this eventually

  processEvent: ->
    world.hand.processMouseUp @button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey
