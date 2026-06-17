# Un-collapses the window this button sits in.
# See IconButtonWdgt for the shared icon-button family contract.

class UncollapseIconButtonWdgt extends IconButtonWdgt

  iconToolTipMessage: "un-collapse window"

  createAppearance: -> new UncollapseIconAppearance @

  actOnClick: ->
    @parent.parent.contents.unCollapse()
