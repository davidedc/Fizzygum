# see https://developer.mozilla.org/en-US/docs/Web/API/TouchEvent
class TouchInputEvent extends InputEvent
  ctrlKey: nil
  shiftKey: nil
  altKey: nil
  metaKey: nil

  touches: nil

  constructor: (@touches, @ctrlKey, @shiftKey, @altKey, @metaKey, isSynthetic, time) ->
    super isSynthetic, time

  @fromBrowserEvent: (event, isSynthetic, time) ->
    new @ event.touches, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey, isSynthetic, time
