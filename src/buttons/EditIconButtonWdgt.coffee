# Tells the window's contents that the edit button was pressed.
# See IconButtonWdgt for the shared icon-button family contract.

class EditIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "edit contents"

  createAppearance: -> new PencilIconAppearance @

  actOnClick: ->
    # Notify the containing window its edit button was pressed (the window forwards
    # to its contents); only a window answers editButtonInBarPressed, so this fires
    # for exactly the old `instanceof WindowWdgt` set. (type-test-elimination campaign)
    @parent?.editButtonInBarPressed?()
