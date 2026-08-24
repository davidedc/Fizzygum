# IMMUTABLE — see the InputEvent header.
class PointerupInputEvent extends PointerInputEvent

  processEvent: ->
    world.hand.processPointerUp @
