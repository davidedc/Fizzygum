# Makes the window droppable into other documents.
# See IconButtonWdgt for the shared icon-button family contract.

class ExternalIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "make this window droppable\ninto other documents"

  createAppearance: -> new ExternalIconAppearance @

  actOnClick: ->
    # These buttons sit in a SwitchButtonWdgt inside the window, so the window is
    # the grandparent; only a window answers makeInternal, replacing the old
    # `instanceof WindowWdgt` test. (type-test-elimination campaign)
    @parent?.parent?.makeInternal?()
