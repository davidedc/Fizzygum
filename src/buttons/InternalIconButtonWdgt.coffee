# Pops the window out of documents, making it un-droppable into other documents.
# See IconButtonWdgt for the shared icon-button family contract.

class InternalIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "pop-out window from documents,\nmake it un-droppable\ninto other documents"

  createAppearance: -> new InternalIconAppearance @

  actOnClick: ->
    # Grandparent is the window (these buttons sit in a SwitchButtonWdgt in the
    # window); only a window answers makeExternal, replacing the old
    # `instanceof WindowWdgt` test. (type-test-elimination campaign)
    @parent?.parent?.makeExternal?()
