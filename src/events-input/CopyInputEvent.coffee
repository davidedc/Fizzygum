class CopyInputEvent extends ClipboardInputEvent

  # Copy is Cut without the processEvent side-effect: the clipboard write already
  # happened in the inherited @fromBrowserEvent (on ClipboardInputEvent), so Copy
  # needs no processEvent — InputEvent's empty default is correct.
