# see https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent
class WheelInputEvent extends MouseInputEvent

  deltaX: nil
  deltaY: nil
  deltaZ: nil

  constructor: (@deltaX, @deltaY, @deltaZ, button, buttons, ctrlKey, shiftKey, altKey, metaKey, isSynthetic, time) ->
    super button, buttons, ctrlKey, shiftKey, altKey, metaKey, isSynthetic, time

  @fromBrowserEvent: (event, isSynthetic, time) ->

    if Utils.runningInMobileSafari() and !event.deltaX? and !event.deltaY? and !event.deltaZ?
      # CHECK AFTER 15 Jan 2021 00:00:00 GMT
      # As of Oct 2020, using mouse/trackpad in
      # Mobile Safari, the wheel event is not sent.
      # See:
      #   https://github.com/cdr/code-server/issues/1455
      #   https://bugs.webkit.org/show_bug.cgi?id=210071
      # However, the scroll event is sent, and when that is sent,
      # we can use the window.pageYOffset
      # to re-create a passable, fake wheel event.
      event.deltaX = event.deltaZ = event.button = event.buttons = 0
      event.deltaY = window.pageYOffset
      event.altKey = false

    new @ event.deltaX, event.deltaY, event.deltaZ, event.button, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey, isSynthetic, time

  processEvent: ->
    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED
    world.hand.processWheel @deltaX, @deltaY, @deltaZ, @altKey, @button, @buttons
