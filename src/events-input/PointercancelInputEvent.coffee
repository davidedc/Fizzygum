# IMMUTABLE — see the InputEvent header.
# The browser confiscated the stroke (a system gesture took it, a palm was rejected, the tab went
# away). The hand treats it as an ABORT, never as a release — see ActivePointerWdgt.processPointerCancel.
class PointercancelInputEvent extends PointerInputEvent

  processEvent: ->
    world.hand.processPointerCancel @
