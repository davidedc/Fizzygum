# see https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent
class KeyboardInputEvent extends InputEvent
  key: nil
  code: nil
  shiftKey: nil
  ctrlKey: nil
  altKey: nil
  metaKey: nil

  constructor: (@key, @code, @shiftKey, @ctrlKey, @altKey, @metaKey, isSynthetic, time) ->
    super isSynthetic, time

  @fromBrowserEvent: (event, isSynthetic, time) ->
    new @ event.key, event.code, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey, isSynthetic, time
