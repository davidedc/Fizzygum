# IMMUTABLE — see the InputEvent header.
class PointermoveInputEvent extends PointerInputEvent

  processEvent: ->
    world.hand.processPointerMove @
