# Un-collapses the window this button sits in.
# See IconButtonWdgt for the shared icon-button family contract.

class UncollapseIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "un-collapse window"

  createAppearance: -> new UncollapseIconAppearance @

  actOnClick: ->
    # my parent is the collapse/uncollapse SwitchButtonWdgt; ITS parent is the
    # bar, which answers the press protocol (and forwards to the frame -- the
    # frame owns what its bar buttons mean).
    @parent.parent.uncollapseButtonInBarPressed?()
