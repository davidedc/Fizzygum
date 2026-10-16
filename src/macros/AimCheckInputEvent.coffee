# IMMUTABLE — see the InputEvent header: every field is set at construction and never written again.
# THE ONE QUEUED EVENT NO USER PRODUCES. Every other event on the queue replays something a user
# does to the system, or (PointercancelInputEvent) something the BROWSER does to the user's stroke;
# this one replays nothing and changes nothing. The macro toolkit queues it immediately before a
# press whose aim it must verify (MacroToolkit._queuePress), at that press's own time, and draining
# it asks the toolkit whether the press meets the widget its verb aimed at
# (MacroToolkit.verifyPressLanding), which fails the test when it does not.
#   WHY A QUEUED EVENT AND NOT A CHECK INSIDE THE VERB: a verb runs at the moment it QUEUES its
# gesture, while its press lands only when the queue DRAINS. At queue time a mouse has not made its
# approach yet — and that approach is what fattens a thin scroll indicator under it — and every
# earlier event still waiting in the queue (a menu opening, a window closing, a pane scrolling) has
# yet to change the world the press will meet. Drained right before the press, the check reads the
# world exactly as the press finds it.
#   This class lives in the `macros` part, which no production profile ships, so it is test
# machinery by placement.
class AimCheckInputEvent extends InputEvent

  # the MacroToolkit that queued me, which answers the question when I drain
  toolkit: undefined

  # the widget the press must land on, or on something inside it; the WORLD means the bare desktop
  receiver: undefined

  # which verb or declaration set the expectation, named in the failure message
  setBy: undefined

  # WHERE THE PRESS STATES IT LANDS. A finger's down states its own place, and the hand moves there
  # before it presses (ActivePointerWdgt.processPointerDown's position head). A mouse down or a
  # wheel notch states none (PointerInputEvent.worldX): it lands wherever the hand stands when it
  # drains, which is where the approach left it — so this stays undefined and the check reads the
  # hand then.
  place: undefined

  # a touch press ARRIVES with its press, which a mouse press has already done by the time it drains
  isTouch: false

  # `press` is the press this check precedes, read here for its time, its place and its kind before
  # the chokepoint queues it (queueInputEvent rewrites a scaled event's time as it enqueues it).
  constructor: (@toolkit, @receiver, @setBy, press) ->
    super true, press.time
    @place = new Point press.worldX, press.worldY  if press.worldX?
    @isTouch = press.pointerType is "touch"

  processEvent: ->
    @toolkit.verifyPressLanding @
