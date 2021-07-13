class CutInputEvent extends ClipboardInputEvent

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

    new @ selectedText, isSynthetic, time

  processEvent: ->
    world.caret?.processCut @text
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
