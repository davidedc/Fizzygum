# AnalogClockMorph //////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES Morph

class AnalogClockMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  constructor: ->

    @fps = 1
    world.addSteppingMorph @

    super()
    @setColor new Color 255, 125, 125
    @silentRawSetExtent new Point 200, 200
    return

    #@setMinAndMaxBoundsAndSpreadability (new Point 15,15) , (new Point 15,15), LayoutSpec.SPREADABILITY_HANDLES

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

      aContext.globalAlpha = @backgroundTransparency

      # paintRectangle here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called before the scaling.
      @paintRectangle aContext, al, at, w, h, @backgroundColor
      aContext.scale pixelRatio, pixelRatio

      morphPosition = @position()
      aContext.translate morphPosition.x, morphPosition.y

      @renderingHelper aContext, new Color(255, 255, 255), new Color(200, 200, 255)

      aContext.restore()

      # paintHighlight here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called outside the effect of the scaling
      # (after the restore).
      @paintHighlight aContext, al, at, w, h

  # BlinkerMorph stepping:
  step: ->
    @changed()

  renderingHelper: (context, color, shadowColor) ->
    context.lineWidth = 1
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()
    context.globalAlpha = @alpha
    context.strokeStyle = shadowColor.toString()

    height = @height()
    width = @width()

    squareDim = Math.min width/2, height/2

    # p0 is the origin, the origin being in the bottom-left corner
    p0 = @bottomLeft().subtract(@position())

    # now the origin if on the left edge, in the top 2/3 of the morph
    p0 = p0.subtract new Point 0, Math.ceil 2 * height/3
    
    now = new Date()
    context.translate width/2, height/2
    context.scale 0.9, 0.9

    context.rotate -Math.PI / 2
    context.strokeStyle = 'black'
    context.fillStyle = 'white'
    context.lineWidth = 6
    context.lineCap = 'round'

    # hour face ticks
    context.save()
    i = 0
    while i < 12
      context.beginPath()
      context.rotate Math.PI / 6
      context.moveTo squareDim*2.4/3, 0
      context.lineTo squareDim, 0
      context.stroke()
      i++
    context.restore()

    # minute face ticks
    context.save()
    context.lineWidth = 5
    i = 0
    while i < 60
      if i % 5 != 0
        context.beginPath()
        context.moveTo squareDim*2.7/3, 0
        context.lineTo squareDim, 0
        context.stroke()
      context.rotate Math.PI / 30
      i++
    context.restore()
    sec = now.getSeconds()
    min = now.getMinutes()
    hr = now.getHours()
    hr = if hr >= 12 then hr - 12 else hr
    context.fillStyle = 'black'

    # hour hand
    context.save()
    context.rotate hr * Math.PI / 6 + Math.PI / 360 * min + Math.PI / 21600 * sec
    context.lineWidth = 8
    context.beginPath()
    context.moveTo -squareDim/7, 0
    context.lineTo squareDim/2, 0
    context.stroke()
    context.restore()

    # minute hand
    context.save()
    context.rotate Math.PI / 30 * min + Math.PI / 1800 * sec
    context.lineWidth = 5
    context.beginPath()
    context.moveTo -squareDim/5, 0
    context.lineTo squareDim/1.3, 0
    context.stroke()
    context.restore()

    # seconds hand
    context.save()
    context.rotate sec * Math.PI / 30
    context.strokeStyle = '#D40000'
    context.fillStyle = '#D40000'
    context.lineWidth = 6
    context.beginPath()
    context.moveTo -squareDim/5, 0
    context.lineTo squareDim/1.3, 0
    context.stroke()

    context.beginPath()
    context.arc(0, 0, 7, 0, Math.PI * 2, true)
    context.fill()

    context.restore()

    context.beginPath()
    context.lineWidth = 10
    context.strokeStyle = '#325FA2'
    context.arc 0, 0, squareDim, 0, Math.PI * 2, true
    context.stroke()


    context.restore()

    context.strokeStyle = color.toString()



