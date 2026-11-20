# IMMUTABLE — see the InputEvent header.
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
  # base and CutInputEvent and CopyInputEvent (which add only their own
  # processEvent) take it: a subclass is made with a copy of its parent's statics
  # (extend, in boot's globalFunctions). PasteInputEvent overrides it (it READS
  # the clipboard instead), so this base flavour never reaches paste. `new @`
  # constructs the actual subclass the static was invoked on.
  #   The event is claimed -- its default kept off and the selected text written
  # to the clipboard -- only when the text being edited has something selected.
  # With nothing selected, or no caret, it is left to the browser, whose default
  # puts nothing on the clipboard when the page selects nothing, so the clipboard
  # keeps what it held, as a platform's text field leaves it; a claim with no
  # text would write an empty clipboard over it. The event still answers,
  # carrying "". Its text is what reached the clipboard here; what a cut then
  # deletes is not read from it: CaretWdgt.processCut asks the live selection
  # when the queued event is processed, and deletes nothing when none stands.
  @fromBrowserEvent: (event, isSynthetic, time) ->
    # see https://developer.mozilla.org/en-US/docs/Web/API/ClipboardEvent

    selectedText = world.caret?.target.selection() ? ""
    if selectedText isnt ""
      if event?.clipboardData
        event.preventDefault()
        event.clipboardData.setData "text/plain", selectedText

      if window.clipboardData
        event.returnValue = false
        window.clipboardData.setData "Text", selectedText

    new @ selectedText, isSynthetic, time
