class MouseInputEvent extends InputEvent
  button: nil
  buttons: nil
  ctrlKey: nil
  shiftKey: nil
  altKey: nil
  metaKey: nil


  constructor: (@button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey) ->
