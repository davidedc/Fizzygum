# IMMUTABLE — see the InputEvent header.
class PointerdownInputEvent extends PointerInputEvent

  processEvent: ->
    world.hand.processPointerDown @
