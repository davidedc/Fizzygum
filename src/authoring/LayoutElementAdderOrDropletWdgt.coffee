class LayoutElementAdderOrDropletWdgt extends LayoutChromeWdgt
  _acceptsDrops: true

  constructor: ->
    super()
    @setColor Color.BLACK
    @setMinAndMaxBoundsAndSpreadability (new Point 15,15) , (new Point 15,15), DivisionStackLayoutSpec.SPREADABILITY_HANDLES

  # Role query (replaces the `x instanceof LayoutElementAdderOrDropletWdgt` filters in
  # Widget._addOrRemoveAdders): "am I one of the auto-inserted stack add/drop placeholders?" — true
  # here (and any subclass), so callers skip these chrome placeholders when scanning real stack
  # content. Parallels isLayoutInert. (type-test-elimination campaign, capability-first)
  isLayoutAdderOrDroplet: ->
    true

  # paintIntoAreaOrBlitFromBackBuffer is inherited from LayoutChromeWdgt; this
  # class supplies only its drawLayoutChrome tail (the base default, via
  # spacerWidgetRenderingHelper below).

  drawHandle: (context) ->
    height = @height()
    width = @width()

    squareDim = Math.min width/2, height/2

    # the plus sign's anchor: one third down the widget (height - ceil 2/3 height), on the
    # left edge of the squareDim-wide square centered in the widget (widget-local coords)
    inscribedSquareLeftAtThirdHeight = new Point (width - squareDim)/2, height - Math.ceil 2 * height/3

    plusSignLeft = inscribedSquareLeftAtThirdHeight.add new Point Math.ceil(squareDim/15), 0
    plusSignRight = inscribedSquareLeftAtThirdHeight.add new Point squareDim - Math.ceil(squareDim/15), 0
    plusSignTop = inscribedSquareLeftAtThirdHeight.add new Point Math.ceil(squareDim/2), -Math.ceil(squareDim/3)
    plusSignBottom = inscribedSquareLeftAtThirdHeight.add new Point Math.ceil(squareDim/2), Math.ceil(squareDim/3)

    context.beginPath()
    context.moveTo 0.5 + plusSignLeft.x, 0.5 + plusSignLeft.y
    context.lineTo 0.5 + plusSignRight.x, 0.5 + plusSignRight.y
    context.moveTo 0.5 + plusSignTop.x, 0.5 + plusSignTop.y
    context.lineTo 0.5 + plusSignBottom.x, 0.5 + plusSignBottom.y

    # the arrow sits one third of the widget height below the plus sign, on the same left edge
    arrowRowLeft = inscribedSquareLeftAtThirdHeight.add new Point 0, Math.ceil 1*height/3
    arrowFlapSize = Math.ceil squareDim/8
    arrowSignLeft = arrowRowLeft.add new Point arrowFlapSize, 0
    arrowSignRight = arrowRowLeft.add new Point squareDim - arrowFlapSize, 0
    arrowUp = arrowSignRight.add new Point -arrowFlapSize, -arrowFlapSize
    arrowDown = arrowSignRight.add new Point -arrowFlapSize, arrowFlapSize
    context.moveTo 0.5 + arrowSignLeft.x, 0.5 + arrowSignLeft.y
    context.lineTo 0.5 + arrowSignRight.x, 0.5 + arrowSignRight.y

    context.lineTo 0.5 + arrowUp.x, 0.5 + arrowUp.y
    context.moveTo 0.5 + arrowSignRight.x, 0.5 + arrowSignRight.y
    context.lineTo 0.5 + arrowDown.x, 0.5 + arrowDown.y


    context.closePath()
    context.stroke()


  spacerWidgetRenderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 1
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background: stroke the same path
    # twice, shadow color first, then
    # the main color on top (only the
    # antialiased fringe of the shadow
    # stroke stays visible).
    context.save()
    context.strokeStyle = shadowColor.toString()
    @drawHandle context
    context.restore()

    context.strokeStyle = color.toString()
    @drawHandle context

  # Both gestures below are MODE-AWARE off my OWN active spec: as a DIVISION slot my
  # insertions join the division layout (a division box rides along), as a CONTENT-stack
  # slot they are inserted SPEC-LESS so the stack's arrange adopts them at that position.
  mouseClickLeft: ->
    @bringToForeground()
    # if the adder/droplet is on its own, free floating, then
    # put a supporting widget underneath it and put the adder/droplet
    # in a layout.
    if @isFreeFloating()
      newWdgt = new Widget
      @parent.add newWdgt
      newWdgt._applyGrantedBounds @boundingBox()
      newWdgt.add @, layoutSpec: @_ensureDivisionBox()
      newWdgt.showAdders()

    newAdder = new LayoutElementAdderOrDropletWdgt
    if @layoutSpec?.isDivisionElement?()
      @addAsSiblingAfterMe newAdder, layoutSpec: newAdder._divisionBox
    else
      @addAsSiblingAfterMe newAdder

  # Runs inside the drop's single settle: addAsSiblingAfterMe is already non-settling (-> _addNoSettle),
  # and fullDestroy -> the non-settling core _fullDestroyNoSettle.
  _reactToChildDropped: (widgetBeingDropped) ->
    if @layoutSpec?.isDivisionElement?()
      @addAsSiblingAfterMe widgetBeingDropped, layoutSpec: widgetBeingDropped._ensureDivisionBox()
    else
      @addAsSiblingAfterMe widgetBeingDropped
    @_fullDestroyNoSettle()

  mouseEnter: ->
    @setColor Color.create 100, 100, 100
  
  mouseLeave: ->
    @setColor Color.BLACK


