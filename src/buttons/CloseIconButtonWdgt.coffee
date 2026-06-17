# Closes the window (or its container) this button sits in.
# See IconButtonWdgt for the shared icon-button family contract.

class CloseIconButtonWdgt extends IconButtonWdgt

  iconHoverColor: Color.RED
  iconToolTipMessage: "close window"

  createAppearance: -> new CloseIconAppearance @

  actOnClick: ->
    if @parent?
      if (@parent instanceof WindowWdgt) and @parent.contents?
        @parent.closeFromWindowBar()
      else
        @parent.close()
