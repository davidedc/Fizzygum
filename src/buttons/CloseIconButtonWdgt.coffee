# Closes the window (or its container) this button sits in.
# See IconButtonWdgt for the shared icon-button family contract.

class CloseIconButtonWdgt extends IconButtonWdgt

  iconHoverColor: Color.RED
  iconToolTipMessage: "close window"

  createAppearance: -> new CloseIconAppearance @

  actOnClick: ->
    # Ask the container what its bar's close button does -- a window handles it
    # (closeFromFrameBar or close, per its contents); any other container of a
    # close button just closes. Was an `instanceof FrameWdgt` branch.
    # (type-test-elimination campaign)
    if @parent?
      if @parent.closeButtonInBarPressed?
        @parent.closeButtonInBarPressed()
      else
        @parent.close()
