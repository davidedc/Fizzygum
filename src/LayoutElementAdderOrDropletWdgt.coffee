# this file is excluded from the fizzygum homepage build

class LayoutElementAdderOrDropletWdgt extends LayoutChromeWdgt
  _acceptsDrops: true

  constructor: ->
    super()
    @setColor Color.BLACK
    @setMinAndMaxBoundsAndSpreadability (new Point 15,15) , (new Point 15,15), LayoutSpec.SPREADABILITY_HANDLES

  # Role query (replaces the `x instanceof LayoutElementAdderOrDropletWdgt` filters in
  # Widget.addOrRemoveAdders): "am I one of the auto-inserted stack add/drop placeholders?" — true
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

    # p0 is the origin, the origin being in the bottom-left corner
    p0 = @bottomLeft().subtract(@position())

    # now the origin if on the left edge, in the top 2/3 of the widget
    p0 = p0.subtract new Point 0, Math.ceil 2 * height/3
    
    # now the origin is in the middle height of the widget,
    # on the left edge of the square inscribed in the widget
    p0 = p0.add new Point (width -  squareDim)/2, 0

    
    plusSignLeft = p0.add new Point Math.ceil(squareDim/15), 0
    plusSignRight = p0.add new Point squareDim - Math.ceil(squareDim/15), 0
    plusSignTop = p0.add new Point Math.ceil(squareDim/2), -Math.ceil(squareDim/3)
    plusSignBottom = p0.add new Point Math.ceil(squareDim/2), Math.ceil(squareDim/3)

    context.beginPath()
    context.moveTo 0.5 + plusSignLeft.x, 0.5 + plusSignLeft.y
    context.lineTo 0.5 + plusSignRight.x, 0.5 + plusSignRight.y
    context.moveTo 0.5 + plusSignTop.x, 0.5 + plusSignTop.y
    context.lineTo 0.5 + plusSignBottom.x, 0.5 + plusSignBottom.y

    # now the new origin is in the lower part of the widget, so
    # we can put an arrow there.
    p0 = p0.add new Point 0, Math.ceil 1*height/3
    arrowFlapSize = Math.ceil squareDim/8
    arrowSignLeft = p0.add new Point arrowFlapSize, 0
    arrowSignRight = p0.add new Point squareDim - arrowFlapSize, 0
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
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()
    context.strokeStyle = shadowColor.toString()
    @drawHandle context
    context.restore()

    context.strokeStyle = color.toString()
    @drawHandle context

  mouseClickLeft: ->
    @bringToForeground()
    # if the adder/droplet is on its own, free floating, then
    # put a supporting widget underneath it and put the adder/droplet
    # in a layout.
    if @isFreeFloating()
      newWdgt = new Widget
      @parent.add newWdgt
      newWdgt.rawSetBounds @boundingBox()
      newWdgt.add @, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
      newWdgt.showAdders()

    @addAsSiblingAfterMe \
      (new LayoutElementAdderOrDropletWdgt),
      nil,
      LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

  # Runs inside the drop's single settle: addAsSiblingAfterMe is already non-settling (-> _addNoSettle),
  # and fullDestroy -> the non-settling core _fullDestroyNoSettle.
  _reactToDropOfNoSettle: (widgetBeingDropped) ->
    @addAsSiblingAfterMe \
      widgetBeingDropped,
      nil,
      LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @_fullDestroyNoSettle()

  mouseEnter: ->
    @setColor Color.create 100, 100, 100
  
  mouseLeave: ->
    @setColor Color.BLACK


