# If the widget in the tool panel doesn't
# need to be interactive (i.e. it's just there
# to be dragged out, then we should put
# this glass top on it, so that it prevents
# mouse actions to reach the widget, and it
# provides a larger target area to grab the
# widget)

class GlassBoxTopWdgt extends Widget

  # grab the widget inside the glass box
  # i.e. the first child of my parent
  # i.e. the first child of the glass box bottom
  findRootForGrab: ->
    return @parent.children[0]
