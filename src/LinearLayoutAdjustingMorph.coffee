# LinearLayoutAdjustingMorph

# this Morph must be attached to a LinearLayoutMorph
# because it relies on LinearLayoutMorph's adjustHorizontallyByAt
# and adjustVerticallyByAt to adjust the layout

# This is a port of the LayoutAdjustingMorph class from
# Cuis Smalltalk (version 4.2-1766)
# Cuis is by Juan Vuletich


class LinearLayoutAdjustingMorph extends RectangleMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  hand: null
  indicator: null
  category: 'Morphic-Layouts'

  constructor: ->
    super()
    @isfloatDraggable = false
    @noticesTransparentClick = true

  # HandleMorph floatDragging and dropping:
  rootForGrab: ->
    @

  @includeInNewMorphMenu: ->
    # Return true for all classes that can be instantiated from the menu
    return false

  nonFloatDragging: (nonFloatDragPositionWithinMorphAtStart, pos) ->
    console.log "layout adjuster being moved!"
    newPos = pos.subtract nonFloatDragPositionWithinMorphAtStart
    @parent.adjustByAt @, newPos

  #SliderButtonMorph events:
  mouseEnter: ->
    if @parent.direction == "#horizontal"
      document.getElementById("world").style.cursor = "col-resize"
    else if @parent.direction == "#vertical"
      document.getElementById("world").style.cursor = "row-resize"
  
  mouseLeave: ->
    document.getElementById("world").style.cursor = "auto"

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
