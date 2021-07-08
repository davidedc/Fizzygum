# see also https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent
class MouseInputEvent extends InputEvent
  button: nil
  buttons: nil
  ctrlKey: nil
  shiftKey: nil
  altKey: nil
  metaKey: nil


  constructor: (@button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey, isSynthetic, time) ->
    super isSynthetic, time

  @fromBrowserEvent: (event, isSynthetic, time) ->
    new @ event.button, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey, isSynthetic, time
