# StackElementsSizeAdjustingMorph



class StackElementsSizeAdjustingMorph extends LayoutableMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  hand: null
  indicator: null
  category: 'Morphic-Layouts'

  constructor: ->
    super()
    @noticesTransparentClick = true

  # HandleMorph floatDragging and dropping:
  rootForGrab: ->
    @

  @includeInNewMorphMenu: ->
    # Return true for all classes that can be instantiated from the menu
    return false

  nonFloatDragging: (nonFloatDragPositionWithinMorphAtStart, pos, deltaDragFromPreviousCall) ->
    debugger

    # the user is in the process of dragging but didn't
    # actually move the mouse yet
    if !deltaDragFromPreviousCall?
      return

    leftMorph = @lastSiblingBeforeMeSuchThat (m) ->
      m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    rightMorph = @firstSiblingAfterMeSuchThat (m) ->
      m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    if leftMorph? and rightMorph?
      lmdd = leftMorph.getDesiredDim()
      rmdd = rightMorph.getDesiredDim()
 
      if (lmdd.x + deltaDragFromPreviousCall.x > 0) and (rmdd.x - deltaDragFromPreviousCall.x > 0)
        leftMorph.setDesiredDim new Point((lmdd.x + deltaDragFromPreviousCall.x), lmdd.y)
        rightMorph.setDesiredDim new Point((rmdd.x - deltaDragFromPreviousCall.x), rmdd.y)

      #if (lmdd.x + deltaDragFromPreviousCall.x > 0)
      #  leftMorph.setDesiredDim new Point((lmdd.x + deltaDragFromPreviousCall.x), lmdd.y)
      #if (rmdd.x - deltaDragFromPreviousCall.x > 0)
      #  rightMorph.setDesiredDim new Point((rmdd.x - deltaDragFromPreviousCall.x), rmdd.y)


  #SliderButtonMorph events:
  mouseEnter: ->
  #  if @parent.direction == "#horizontal"
  #    document.getElementById("world").style.cursor = "col-resize"
  #  else if @parent.direction == "#vertical"
  #    document.getElementById("world").style.cursor = "row-resize"
  
  mouseLeave: ->
  #  document.getElementById("world").style.cursor = "auto"

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
