class PasteInputEvent extends ClipboardInputEvent

  @fromBrowserEvent: (event, isSynthetic, time) ->
    # see https://developer.mozilla.org/en-US/docs/Web/API/ClipboardEvent

    if world.caret
      if event?
        if event.clipboardData
          # Look for access to data if types array is missing
          text = event.clipboardData.getData "text/plain"
        # IE event is attached to the window object
        if window.clipboardData
          # The schema is fixed
          text = window.clipboardData.getData "Text"

    new @ text, isSynthetic, time

  processEvent: ->
    world.caret?.processPaste @text
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
