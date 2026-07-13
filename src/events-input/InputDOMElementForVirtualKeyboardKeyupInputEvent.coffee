# Virtual-keyboard key RELEASE. Must extend KeyupInputEvent (which dispatches
# processKeyUp), NOT KeydownInputEvent — otherwise a soft-keyboard key-up
# re-runs processKeyDown and doubles every keystroke on touch devices.
class InputDOMElementForVirtualKeyboardKeyupInputEvent extends KeyupInputEvent
