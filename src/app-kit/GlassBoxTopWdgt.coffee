# If the widget in the tool panel doesn't
# need to be interactive (i.e. it's just there
# to be dragged out, then we should put
# this glass top on it, so that it prevents
# mouse actions to reach the widget, and it
# provides a larger target area to grab the
# widget)
#
# I paint nothing. My hover / press state is the one the cell under me shows (CreatorWdgt tells it;
# GlassBoxBottomWdgt asks the hand about the widget a tap on it reaches, which is me).

class GlassBoxTopWdgt extends CreatorWdgt

  # the lid of a tool cell (GlassBoxBottomWdgt)
  colloquialName: -> "tool cell lid"

  _createWidgetToBeHandled: ->
    # nosettle-sanctioned: fullCopy has no NoSettle core; a lid's copy is made at event time (a click on
    # its cell, CreatorWdgt.activated), outside any pass
    widgetToBeHandled = @parent.children[0].fullCopy()
    # refused (Widget.fullCopy has told the person why): nothing to hand over
    return undefined unless widgetToBeHandled?
    widgetToBeHandled.isTemplate = false
    return widgetToBeHandled

  # grab the widget inside the glass box
  # i.e. the first child of my parent
  # i.e. the first child of the glass box bottom
  findRootForGrab: ->
    return @parent.children[0]
