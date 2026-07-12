# this file is excluded from the fizzygum homepage build

class StackElementsSizeAdjustingWdgt extends LayoutChromeWdgt


  hand: nil
  indicator: nil
  category: 'Widgetic-Layouts'


  constructor: ->
    super()
    @noticesTransparentClick = true
    #@setColor Color.LIME
    @setMinAndMaxBoundsAndSpreadability (new Point 5,5) , (new Point 5,5), LayoutSpec.SPREADABILITY_HANDLES
    @minimumExtent = new Point 0,0

  @includeInNewWidgetMenu: ->
    # Return true for all classes that can be instantiated from the menu
    return false

  detachesWhenDragged: ->
    return false

  grabsToParentWhenDragged: ->
    return false

  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->

    # the user is in the process of dragging but didn't
    # actually move the mouse yet
    if !deltaDragFromPreviousCall?
      return

    # Affine transforms §7.12: deltaDragFromPreviousCall is a SCREEN-space vector, but the cell
    # widths below live in MY plane — inside a rotated/scaled island map it through the inverse
    # linear part, as the difference of two plane-mapped points (a delta must never be point-mapped:
    # the translation would double-apply). Gated so the dormant path never pays the ancestor walk.
    if @_isInsideNonIdentityIsland()
      deltaDragFromPreviousCall = (@screenPointToMyPlane pos).subtract @screenPointToMyPlane pos.subtract deltaDragFromPreviousCall

    leftWidget = @lastSiblingBeforeMeSuchThat (m) ->
      m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    rightWidget = @firstSiblingAfterMeSuchThat (m) ->
      m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    if leftWidget? and rightWidget?
      lmdd = leftWidget.getMaxDim()
      rmdd = rightWidget.getMaxDim()
 
      #if (lmdd.x + deltaDragFromPreviousCall.x > 0) and (rmdd.x - deltaDragFromPreviousCall.x > 0)
      #  leftWidget.setDesiredDim new Point((lmdd.x + deltaDragFromPreviousCall.x), lmdd.y)
      #  rightWidget.setDesiredDim new Point((rmdd.x - deltaDragFromPreviousCall.x), rmdd.y)

      

      # the factor "Math.max(lmdd.x,rmdd.x)/100" here below is because
      # spacers have huge max factors, so we need to scale the
      # change based on how much the biggest max factor is.
      biggestMaxOfTheTwo = Math.max Math.abs(lmdd.x), Math.abs(rmdd.x)
      deltaX = (deltaDragFromPreviousCall.x * Math.pow(biggestMaxOfTheTwo,1.07)) * 500
      deltaX = deltaX / (@parent.width() * 700)

      totalMax = @parent.children.reduce ((acc,elem) => acc + elem.getMaxDim().x), 0

      deltaX = deltaX * (totalMax / biggestMaxOfTheTwo)


      until (lmdd.x + deltaX > 0) and (rmdd.x - deltaX > 0)
        deltaX = deltaX / 2


      # The move grows the left cell by deltaX and shrinks the right by the same -- legal ONLY while neither cell
      # is pushed BELOW its content (desired) width, where getMaxDim clamps UP to getDesiredDim (getMaxDim ==
      # max(@maxWidth, getDesiredDim)) so the +deltaX/-deltaX no longer cancel and the conservation sum changes.
      # PREDICT that check WITHOUT mutating -- the same max(maxWidth, desired) getMaxDim uses, in the same
      # `a - b + c - d` float grouping the original read used (float add isn't associative) -- and set ONCE iff it
      # holds, instead of speculatively setting both cells, re-reading, and reverting on a boundary hit. Byte-
      # identical to the old set-then-revert (same accept/reject, same final maxDims; a rejected move netted zero)
      # but ~3x fewer _setMaxDimNoSettle calls -- no 2 speculative sets + 2 reverts per rejected move, and this
      # drag rejects ~60% of moves at the limits. (efficiency, divider revert-thrash -- docs/coalescing-measurement.md)
      ldes = leftWidget.getDesiredDim().x
      rdes = rightWidget.getDesiredDim().x
      prev   = lmdd.x - ldes + rmdd.x - rdes
      newone = Math.max(lmdd.x + deltaX, ldes) - ldes + Math.max(rmdd.x - deltaX, rdes) - rdes
      if prev == newone
        # drag-move STREAM: the _-private deferred-settle entrypoint (restricted to stream handlers like this one by
        # check-layering [O]), which DECLARES intentional per-move deferred settling onto the one end-of-cycle flush
        # instead of reaching into the private _setMaxDimNoSettle core. Measured warranted here (~13 moves/frame
        # -> ~26 muts/frame; see docs/coalescing-measurement.md); toggle world.deferredSettlingEnabled to
        # self-settle-per-move and A/B it. (the plain setMaxDim self-settles, for discrete callers.)
        # (end-of-cycle-flush-drawdown -- CONVERT)
        leftWidget._setMaxDimDeferredSettle new Point lmdd.x + deltaX, lmdd.y
        rightWidget._setMaxDimDeferredSettle new Point rmdd.x - deltaX, rmdd.y


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
  #  @color = paneColor
  #
  #cursor: ->
  #  if @owner.direction == "#horizontal"
  #    Cursor.resizeLeft()
  #  else
  #    Cursor.resizeTop()

  # The size-adjuster's glyph: a grey filled circle. (The shared background
  # fill + clip + translate live in
  # LayoutChromeWdgt.paintIntoAreaOrBlitFromBackBuffer.)
  drawLayoutChrome: (aContext) ->
    aContext.fillStyle = @color.toString()
    
    centerX = @bounds.width() / 2
    centerY = @bounds.height() / 2
    radius = Math.min centerX, centerY
    radius = radius - radius / 20
    aContext.beginPath()
    aContext.arc centerX, centerY, radius, 0, 2 * Math.PI
    aContext.fillStyle = Color.GRAY.toString()
    aContext.fill()
    aContext.closePath()

