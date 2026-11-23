# THE LID OF A TOOL CELL (GlassBoxBottomWdgt): the tool panel puts me over a tool that is there only to
# be dragged out (not actionableAsThumbnail), so a press lands on me instead of reaching the tool, and
# the whole cell is a target as large as the cell.
#
# I am the cell's CREATOR: what I make is the one copy my cell hands out (copyOfToolToHandOut: a fresh
# copy of its tool, at the size the tool came into the cell at). A click on me places it and a drag
# out of me carries it, through CreatorWdgt's two doors (activated, grabbedWidgetSwitcheroo), so the
# two gestures make one thing.
#
# I paint nothing. My hover / press state is the one the cell under me shows (CreatorWdgt tells it;
# GlassBoxBottomWdgt asks the hand about the widget a tap on it reaches, which is me).

class GlassBoxTopWdgt extends CreatorWdgt

  # the lid of a tool cell (GlassBoxBottomWdgt)
  colloquialName: -> "tool cell lid"

  # what a click on me places and what a drag out of me carries: the one copy my cell hands out (a lid
  # standing in no cell makes nothing)
  _createWidgetToBeHandled: ->
    @parent?.copyOfToolToHandOut?()
