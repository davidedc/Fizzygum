class InputEvent
  isSynthetic: false

  # in theory you could get the time from the event,
  # see https://developer.mozilla.org/en-US/docs/Web/API/Event/timeStamp
  # however that timeStamp field seems a bit fidgety, so
  # we'll just create this time ourselves.
  time: 0

  constructor: (@isSynthetic, @time = Date.now()) ->

  processEvent: ->
