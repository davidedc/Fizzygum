# this file is only needed for Macros

class MousemoveSyntheticEvent
  pageX: nil
  pageY: nil
  button: nil
  buttons: nil
  ctrlKey: nil
  shiftKey: nil
  altKey: nil
  metaKey: nil

  constructor: (@pageX, @pageY, @button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey) ->
