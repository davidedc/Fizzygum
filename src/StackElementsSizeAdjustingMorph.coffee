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
    @setColor new Color(0, 255, 0)
    @setMinAndMaxBoundsAndSpreadability (new Point 5,5) , (new Point 5,5), LayoutSpec.SPREADABILITY_NONE

  # HandleMorph floatDragging and dropping:
  rootForGrab: ->
    @

  @includeInNewMorphMenu: ->
    # Return true for all classes that can be instantiated from the menu
    return false

  nonFloatDragging: (nonFloatDragPositionWithinMorphAtStart, pos, deltaDragFromPreviousCall) ->

    # the user is in the process of dragging but didn't
    # actually move the mouse yet
    if !deltaDragFromPreviousCall?
      return

    leftMorph = @lastSiblingBeforeMeSuchThat (m) ->
      m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    rightMorph = @firstSiblingAfterMeSuchThat (m) ->
      m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    if leftMorph? and rightMorph?
      lmdd = leftMorph.getMaxDim()
      rmdd = rightMorph.getMaxDim()
 
      #if (lmdd.x + deltaDragFromPreviousCall.x > 0) and (rmdd.x - deltaDragFromPreviousCall.x > 0)
      #  leftMorph.setDesiredDim new Point((lmdd.x + deltaDragFromPreviousCall.x), lmdd.y)
      #  rightMorph.setDesiredDim new Point((rmdd.x - deltaDragFromPreviousCall.x), rmdd.y)

      deltaX = deltaDragFromPreviousCall.x / 2

      until (lmdd.x + deltaX > 0) and (rmdd.x - deltaX > 0)
        deltaX = deltaX / 2

      prev = (leftMorph.getMaxDim().x - leftMorph.getDesiredDim().x + rightMorph.getMaxDim().x - rightMorph.getDesiredDim().x)
      leftMorph.setMaxDim new Point((lmdd.x + deltaX), lmdd.y)
      rightMorph.setMaxDim new Point((rmdd.x - deltaX), rmdd.y)
      newone = (leftMorph.getMaxDim().x - leftMorph.getDesiredDim().x + rightMorph.getMaxDim().x - rightMorph.getDesiredDim().x)
      if prev != newone
        leftMorph.setMaxDim lmdd
        rightMorph.setMaxDim rmdd
      #console.log "leftMorph.getMaxDim().x : " + leftMorph.getMaxDim().x 
      #console.log "leftMorph.getDesiredDim().x: " + leftMorph.getDesiredDim().x
      #console.log "rightMorph.getMaxDim().x: " + rightMorph.getMaxDim().x
      #console.log "rightMorph.getDesiredDim().x: " + rightMorph.getDesiredDim().x 
      console.log "should be constant: " + (leftMorph.getMaxDim().x - leftMorph.getDesiredDim().x + rightMorph.getMaxDim().x - rightMorph.getDesiredDim().x)


  # TODO: this mechanism to show the right cursor is 90%
  # there but could be better. The cursor changes to normal
  # as soon as the pointer gets out of the adjuster, which
  # happens while nonFloatDragging. It's not a big deal
  # and it's simpler, but something one could improve.
  mouseEnter: ->
    document.getElementById("world").style.cursor = "col-resize"
  
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
