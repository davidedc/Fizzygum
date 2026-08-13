# IMMUTABLE — see the InputEvent header.
# see https://developer.mozilla.org/en-US/docs/Web/API/TouchEvent
class TouchInputEvent extends InputEvent
  ctrlKey: undefined
  shiftKey: undefined
  altKey: undefined
  metaKey: undefined

  touches: undefined

  constructor: (@touches, @ctrlKey, @shiftKey, @altKey, @metaKey, isSynthetic, time) ->
    super isSynthetic, time

  @fromBrowserEvent: (event, isSynthetic, time) ->
    new @ event.touches, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey, isSynthetic, time
