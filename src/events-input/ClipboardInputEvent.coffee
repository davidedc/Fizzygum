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

  # Cut and copy capture the selection identically, so this lives here on the
  # base and is inherited by CutInputEvent and CopyInputEvent (which add only
  # their own processEvent). PasteInputEvent overrides it (it READS the
  # clipboard instead), so this base flavour never reaches paste. `new @`
  # constructs the actual subclass the static was invoked on.
  @fromBrowserEvent: (event, isSynthetic, time) ->
    # see https://developer.mozilla.org/en-US/docs/Web/API/ClipboardEvent

    selectedText = ""
    if world.caret
      selectedText = world.caret.target.selection()
      if event?.clipboardData
        event.preventDefault()
        setStatus = event.clipboardData.setData "text/plain", selectedText

      if window.clipboardData
        event.returnValue = false
        setStatus = window.clipboardData.setData "Text", selectedText

    new @ selectedText, isSynthetic, time
