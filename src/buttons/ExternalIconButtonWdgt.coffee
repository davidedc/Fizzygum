# Makes the window droppable into other documents.
# See IconButtonWdgt for the shared icon-button family contract.

class ExternalIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "make this window droppable\ninto other documents"

  createAppearance: -> new ExternalIconAppearance @

  actOnClick: ->
    if @parent?.parent?
      if (@parent.parent instanceof WindowWdgt)
        @parent.parent.makeInternal()
