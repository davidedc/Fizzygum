class ClipboardInputEvent extends InputEvent
  text: ""

  constructor: (@text, isSynthetic, time) ->
    super isSynthetic, time
