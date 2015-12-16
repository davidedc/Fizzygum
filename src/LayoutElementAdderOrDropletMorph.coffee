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

    super

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
      morphPosition = @position()
      aContext.translate morphPosition.x, morphPosition.y

      @spacerMorphRenderingHelper aContext, new Color(255, 255, 255), new Color(200, 200, 255)

      aContext.restore()

  drawHandle: (context) ->
    p0 = @bottomLeft().subtract(@position())
    p0 = p0.subtract(new Point(0, Math.ceil(@height()/2)))
    
    plusSignLeft = p0.add(new Point(Math.ceil(@width()/15),0))
    plusSignRight = p0.add(new Point(@width() - Math.ceil(@width()/14), 0))
    plusSignTop = p0.add new Point(Math.ceil(@width()/2),-Math.ceil(@height()/3))
    plusSignBottom = p0.add new Point(Math.ceil(@width()/2),Math.ceil(@height()/3))

    context.beginPath()
    context.moveTo 0.5 + plusSignLeft.x, 0.5 + plusSignLeft.y
    context.lineTo 0.5 + plusSignRight.x, 0.5 + plusSignRight.y
    context.moveTo 0.5 + plusSignTop.x, 0.5 + plusSignTop.y
    context.lineTo 0.5 + plusSignBottom.x, 0.5 + plusSignBottom.y
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
    super
    if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
      return
    if !(@firstSiblingAfterMeSuchThat((m) -> m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED) instanceof LayoutElementAdderOrDropletMorph)
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


