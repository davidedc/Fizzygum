# LayoutAdjustingMorph

# this comment below is needed to figure our dependencies between classes

# This is a port of the
# respective Cuis Smalltalk classes (version 4.2-1766)
# Cuis is by Juan Vuletich


class LayoutAdjustingMorph extends RectangleMorph

  hand: null
  indicator: null

  constructor: ->

  @includeInNewMorphMenu: ->
    # Return true for all classes that can be instantiated from the menu
    return false

  ###
  adoptWidgetsColor: (paneColor) ->
    super adoptWidgetsColor paneColor
    @color = paneColord

  cursor: ->
    if @owner.direction == "#horizontal"
      Cursor.resizeLeft()
    else
      Cursor.resizeTop()
  ###
