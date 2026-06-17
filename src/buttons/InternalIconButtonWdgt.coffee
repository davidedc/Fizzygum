# Pops the window out of documents, making it un-droppable into other documents.
# See IconButtonWdgt for the shared icon-button family contract.

class InternalIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "pop-out window from documents,\nmake it un-droppable\ninto other documents"

  createAppearance: -> new InternalIconAppearance @

  actOnClick: ->
    if @parent?.parent?
      if (@parent.parent instanceof WindowWdgt)
        @parent.parent.makeExternal()
