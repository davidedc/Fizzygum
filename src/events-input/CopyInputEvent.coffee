class CopyInputEvent extends ClipboardInputEvent

  # cut and copy implementations are the same
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

    # TODO surely we should be able to say "new @" here? Why doesn't that work?
    new CopyInputEvent selectedText, isSynthetic, time
