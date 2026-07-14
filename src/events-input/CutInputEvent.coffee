class CutInputEvent extends ClipboardInputEvent

  # @fromBrowserEvent (identical to copy's) is inherited from ClipboardInputEvent;
  # cut adds only the processEvent that actually removes the selection.
  processEvent: ->
    world.caret?.processCut @text
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
