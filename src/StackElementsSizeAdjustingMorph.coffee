# StackElementsSizeAdjustingMorph



class StackElementsSizeAdjustingMorph extends Morph


  hand: nil
  indicator: nil
  category: 'Morphic-Layouts'


  constructor: ->
    super()
    @isLockingToPanels = false
    @noticesTransparentClick = true
    #@setColor new Color 0, 255, 0
    @setMinAndMaxBoundsAndSpreadability (new Point 5,5) , (new Point 5,5), LayoutSpec.SPREADABILITY_HANDLES
    @minimumExtent = new Point 0,0

  @includeInNewMorphMenu: ->
    # Return true for all classes that can be instantiated from the menu
    return false

  detachesWhenDragged: ->
    return false

  grabsToParentWhenDragged: ->
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

      

      # the factor "Math.max(lmdd.x,rmdd.x)/100" here below is because
      # spacers have huge max factors, so we need to scale the
      # change based on how much the biggest max factor is.
      biggestMaxOfTheTwo = Math.max Math.abs(lmdd.x), Math.abs(rmdd.x)
      deltaX = (deltaDragFromPreviousCall.x * Math.pow(biggestMaxOfTheTwo,1.07)) * 500
      console.log " deltax 2 : " + deltaX + " lmdd.x: " + lmdd.x + " rmdd.x: " + rmdd.x
      deltaX = deltaX / (@parent.width() * 700)

      totalMax = 0
      for C in @parent.children
        totalMax += C.getMaxDim().x

      deltaX = deltaX * (totalMax / biggestMaxOfTheTwo)

      console.log "(@parent.width() * 100): " + (@parent.width() * 100) + " deltax 3: " + deltaX

      until (lmdd.x + deltaX > 0) and (rmdd.x - deltaX > 0)
        deltaX = deltaX / 2

      console.log " deltax 4 : " + deltaX

      prev = leftMorph.getMaxDim().x - leftMorph.getDesiredDim().x + rightMorph.getMaxDim().x - rightMorph.getDesiredDim().x
      leftMorph.setMaxDim new Point lmdd.x + deltaX, lmdd.y
      rightMorph.setMaxDim new Point rmdd.x - deltaX, rmdd.y
      newone = leftMorph.getMaxDim().x - leftMorph.getDesiredDim().x + rightMorph.getMaxDim().x - rightMorph.getDesiredDim().x
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

  #adoptWidgetsColor: (paneColor) ->
  #  super adoptWidgetsColor paneColor
  #  @color = paneColord
  #
  #cursor: ->
  #  if @owner.direction == "#horizontal"
  #    Cursor.resizeLeft()
  #  else
  #    Cursor.resizeTop()

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil

      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

      # paintRectangle here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called before the scaling.
      @paintRectangle aContext, al, at, w, h, @color
      aContext.scale pixelRatio, pixelRatio

      morphPosition = @position()
      aContext.translate morphPosition.x, morphPosition.y
      aContext.fillStyle = @color.toString()
      
      centerX = @bounds.width() / 2
      centerY = @bounds.height() / 2
      radius = Math.min centerX, centerY
      radius = radius - radius / 20
      aContext.beginPath()
      aContext.arc centerX, centerY, radius, 0, 2 * Math.PI, false
      aContext.fillStyle = 'Gray'
      aContext.fill()
      aContext.closePath()

      aContext.restore()

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio (i.e. after the restore)
      @paintHighlight aContext, al, at, w, h

