class DesktopAppearance extends RectangularAppearance


  currentPattern: nil

  # This method only paints this very morph
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @morph.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil


    # set up a pattern
    if @morph.patternName? && @morph.patternName == @morph.pattern1
      @currentPattern = @morph.patternName
      @pattern = nil

    if @morph.patternName? && @morph.patternName != @currentPattern
      @currentPattern = @morph.patternName
      @pattern = document.createElement('canvas')
      @pattern.width = 5 * pixelRatio
      @pattern.height = 5 * pixelRatio
      pctx = @pattern.getContext('2d')
      pctx.scale pixelRatio, pixelRatio

      switch @morph.patternName
        when @morph.pattern2
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.lineWidth = 0.25
          pctx.beginPath()
          pctx.arc 2,2,2,0,2*Math.PI
          pctx.fillStyle = 'rgb(220, 219, 220)'
          pctx.fill()
        when @morph.pattern3
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 1,0
          pctx.lineTo 1,5
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()
        when @morph.pattern4
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 0,5
          pctx.lineTo 5,0
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()
        when @morph.pattern5
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 2,2
          pctx.lineTo 4,4
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()
        when @morph.pattern6
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 0,0
          pctx.lineTo 3,3
          pctx.lineTo 5,0
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()
        when @morph.pattern7
          pctx.fillStyle = 'rgb(244, 243, 244)'
          pctx.fillRect 0,0,5,5
          pctx.moveTo 0,5
          pctx.lineTo 5,0
          pctx.moveTo 2.5,2.5
          pctx.lineTo 0,0
          pctx.strokeStyle = 'rgb(225, 224, 225)'
          pctx.stroke()


      @pattern = aContext.createPattern(@pattern, 'repeat')



    [area,sl,st,al,at,w,h] = @morph.calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil

      @morph.justBeforeBeingPainted?()

      aContext.save()
      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @morph.alpha
      aContext.fillStyle = @morph.color.toString()

      if !@morph.color?
        debugger


      # paintRectangle is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio

      # paint the background
      toBePainted = new Rectangle al, at, al + w, at + h

      if @morph.backgroundColor?
        color = @morph.backgroundColor
        if appliedShadow?
          color = "black"
        @morph.paintRectangle aContext, toBePainted.left(), toBePainted.top(), toBePainted.width(), toBePainted.height(), color


      # now paint the actual morph, which is a rectangle
      # (potentially inset because of the padding)
      toBePainted = toBePainted.intersect @morph.boundingBoxTight().scaleBy pixelRatio

      color = @morph.color
      if appliedShadow?
        color = "black"

      @morph.paintRectangle aContext, toBePainted.left(), toBePainted.top(), toBePainted.width(), toBePainted.height(), color

      @drawAdditionalPartsOnBaseShape? false, false, appliedShadow, aContext, al, at, w, h

      if !appliedShadow?
        @paintStroke aContext, clippingRectangle

      if @pattern?
        aContext.fillStyle = @pattern
        aContext.fillRect toBePainted.left(), toBePainted.top(), toBePainted.width(), toBePainted.height()

      aContext.restore()

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio
      @paintHighlight aContext, al, at, w, h

