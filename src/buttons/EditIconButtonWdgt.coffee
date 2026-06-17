# Tells the window's contents that the edit button was pressed.
# See IconButtonWdgt for the shared icon-button family contract.

class EditIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "edit contents"

  createAppearance: -> new PencilIconAppearance @

  actOnClick: ->
    if @parent?
      if (@parent instanceof WindowWdgt)
        @parent.contents?.editButtonPressedFromWindowBar?()
