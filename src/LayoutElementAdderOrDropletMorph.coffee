# LayoutElementAdderOrDropletMorph //////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES LayoutSpec


class LayoutElementAdderOrDropletMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype
  _acceptsDrops: true

  constructor: ->
    super()
    @setColor new Color(0, 0, 0)
    @setMinAndMaxBoundsAndSpreadability (new Point 15,15) , (new Point 15,15), LayoutSpec.SPREADABILITY_HANDLES

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

    if @preliminaryCheckNothingToDraw false, clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null

      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = @alpha

      aContext.scale pixelRatio, pixelRatio

      @paintBackgroundRectangle aContext, al, at, w, h

      morphPosition = @position()
      aContext.translate morphPosition.x, morphPosition.y

      @spacerMorphRenderingHelper aContext, new Color(255, 255, 255), new Color(200, 200, 255)

      aContext.restore()
      @paintHighlight aContext, al, at, w, h

  drawHandle: (context) ->
    height = @height()
    width = @width()

    squareDim = Math.min width/2, height/2

    # p0 is the origin, the origin being in the bottom-left corner
    p0 = @bottomLeft().subtract(@position())

    # now the origin if on the left edge, in the top 2/3 of the morph
    p0 = p0.subtract(new Point(0, Math.ceil(2*height/3)))
    
    # now the origin is in the middle height of the morph,
    # on the left edge of the square incribed in the morph
    p0 = p0.add new Point (width -  squareDim)/2,0

    
    plusSignLeft = p0.add(new Point(Math.ceil(squareDim/15),0))
    plusSignRight = p0.add(new Point(squareDim - Math.ceil(squareDim/15), 0))
    plusSignTop = p0.add new Point(Math.ceil(squareDim/2),-Math.ceil(squareDim/3))
    plusSignBottom = p0.add new Point(Math.ceil(squareDim/2),Math.ceil(squareDim/3))

    context.beginPath()
    context.moveTo 0.5 + plusSignLeft.x, 0.5 + plusSignLeft.y
    context.lineTo 0.5 + plusSignRight.x, 0.5 + plusSignRight.y
    context.moveTo 0.5 + plusSignTop.x, 0.5 + plusSignTop.y
    context.lineTo 0.5 + plusSignBottom.x, 0.5 + plusSignBottom.y

    # now the new origin is in the lower part of the morph, so
    # we can put an arrow there.
    p0 = p0.add(new Point(0, Math.ceil(1*height/3)))
    arrowFlapSize = Math.ceil squareDim/8
    arrowSignLeft = p0.add(new Point(arrowFlapSize,0))
    arrowSignRight = p0.add(new Point(squareDim - arrowFlapSize, 0))
    arrowUp = arrowSignRight.add(new Point(- arrowFlapSize, - arrowFlapSize))
    arrowDown = arrowSignRight.add(new Point(- arrowFlapSize, + arrowFlapSize))
    context.moveTo 0.5 + arrowSignLeft.x, 0.5 + arrowSignLeft.y
    context.lineTo 0.5 + arrowSignRight.x, 0.5 + arrowSignRight.y

    context.lineTo 0.5 + arrowUp.x, 0.5 + arrowUp.y
    context.moveTo 0.5 + arrowSignRight.x, 0.5 + arrowSignRight.y
    context.lineTo 0.5 + arrowDown.x, 0.5 + arrowDown.y


    context.closePath()
    context.stroke()


  spacerMorphRenderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 1
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()
    context.strokeStyle = shadowColor.toString()
    @drawHandle(context)
    context.restore()

    context.strokeStyle = color.toString()
    @drawHandle(context)

  mouseClickLeft: ->
    @bringToForegroud()
    # if the adder/droplet is on its own, free floating, then
    # put a supporting morph underneath it and put the adder/droplet
    # in a layout.
    if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
      newMorph = new Morph()
      @parent.add newMorph
      newMorph.rawSetBounds @boundingBox()
      newMorph.add @, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
      newMorph.showAdders()

    @addAsSiblingAfterMe \
      (new LayoutElementAdderOrDropletMorph()),
      null,
      LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

  reactToDropOf: (morphBeingDropped) ->
    @addAsSiblingAfterMe \
      morphBeingDropped,
      null,
      LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED    
    @destroy()

  mouseEnter: ->
    @setColor new Color(100, 100, 100)
  
  mouseLeave: ->
    @setColor new Color(0, 0, 0)


