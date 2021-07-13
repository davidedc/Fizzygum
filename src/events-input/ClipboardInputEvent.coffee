# clipboard events take a text instead of the event,
# the reason is that you can't access the clipboard
# outside of the EventListener, I presume for
# security reasons. So, since these process* methods
# are executed outside of the listeners, we really can't use
# the event and the clipboard object in the event, so
# we have to work with text. The clipboard IS handled, but
# it's handled in the listeners

class ClipboardInputEvent extends InputEvent

  # for security reasons clipboard access is not
  # allowed outside of the event listener, we
  # have to keep the text content around in here.
  text: ""

  constructor: (@text, isSynthetic, time) ->
    super isSynthetic, time
