# Collapses the window this button sits in.
# See IconButtonWdgt for the shared icon-button family contract.

class CollapseIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "collapse window"

  createAppearance: -> new CollapseIconAppearance @

  actOnClick: ->
    @parent.parent.contents.collapse()
