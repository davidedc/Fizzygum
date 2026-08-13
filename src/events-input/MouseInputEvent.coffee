# IMMUTABLE — see the InputEvent header.
# see also https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent
class MouseInputEvent extends InputEvent

  button: undefined
  buttons: undefined

  ctrlKey: undefined
  shiftKey: undefined
  altKey: undefined
  metaKey: undefined

  constructor: (@button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey, isSynthetic, time) ->
    super isSynthetic, time

  @fromBrowserEvent: (event, isSynthetic, time) ->
    new @ event.button, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey, isSynthetic, time
