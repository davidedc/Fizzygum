# this file is only needed for Macros

class KeydownSyntheticEvent
  keyCode: nil
  shiftKey: nil
  ctrlKey: nil
  altKey: nil
  metaKey: nil

  constructor: (@keyCode, @shiftKey, @ctrlKey, @altKey, @metaKey) ->
