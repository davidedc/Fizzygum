class KeydownInputEvent extends KeyboardInputEvent

  @fromBrowserEvent: (event, isSynthetic, time) ->
    new @ event.key, event.code, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey, isSynthetic, time
