# this file is only needed for Macros

class KeyupSyntheticEvent
  keyCode: nil
  shiftKey: nil
  ctrlKey: nil
  altKey: nil
  metaKey: nil

  constructor: (@keyCode, @shiftKey, @ctrlKey, @altKey, @metaKey) ->
