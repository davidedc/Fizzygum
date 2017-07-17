# ShadowMorph /////////////////////////////////////////////////////////
# REQUIRES BackBufferMixin

class ShadowMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype
  @augmentWith BackBufferMixin

  targetMorph: null
  offset: null
  alpha: 0
  color: null

  # alpha should be between zero (transparent)
  # and one (fully opaque)
  constructor: (@targetMorph, @offset = new Point(7, 7), @alpha = 0.2, @color = new Color(0, 0, 0)) ->
    # console.log "creating shadow morph"
    super()
    @bounds.debugIfFloats()
    @offset.debugIfFloats()

  reLayout: ->
    # console.log "shadow morph update rendering"
    super()
    fb = @targetMorph.fullBoundsNoShadow()
    @silentRawSetExtent fb.extent().add @targetMorph.shadowBlur * 2
    @silentFullRawMoveTo fb.origin.add(@offset).subtract @targetMorph.shadowBlur
    @bounds.debugIfFloats()
    @offset.debugIfFloats()
    @notifyChildrenThatParentHasReLayouted()


  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle = @fullClippedBounds(), noShadow = false) ->

    if noShadow
      return

    @reLayout()
    [@backBuffer, @backBufferContext] = @createRefreshOrGetBackBuffer()
    #console.log "shadow backbuffer size: " + @backBuffer.width + " " + @backBuffer.height
    #console.log "shadow refreshing myself! "
    #console.log "shadow parent: " + @targetMorph
    #console.log "shadow target morph: " + @targetMorph

    @justBeforeBeingPainted?()

    if !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
      return null


    if !@backBuffer?
      return null

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null

      aContext.save()

      aContext.globalAlpha = @alpha

      #console.log "shadow drawing the new backbuffer "
      aContext.drawImage @backBuffer,
        Math.round(sl),
        Math.round(st),
        Math.round(w),
        Math.round(h),
        Math.round(al),
        Math.round(at),
        Math.round(w),
        Math.round(h)

      aContext.restore()

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio
      @paintHighlight aContext, al, at, w, h


  # No changes of position or extent should be
  # performed in here,
  # There is really little hope to cache this buffer
  # cross-morph.
  # So just keep a dedicated one
  # for each canvas, simple.
  createRefreshOrGetBackBuffer: ->

    #console.log "shadow refreshing the backbuffer of @targetMorph: " + @targetMorph
    
    # this extend is calculated by relayout to be the fullBoundsNoShadow,
    # so it depends by all the extents of all the children.
    extent = @extent()

    # unfortunately you can't cache just on the fullBoundsNoShadow, because
    # you could have this:
    #   _________
    #  |         |
    #  |    A    |
    #  |       __|____
    #  |______|       |
    #         |   B   |
    #         |       |
    #         |_______|
    #
    # with B attached to A. If you resize A only,
    # then the fullBoundsNoShadow remains the same,
    # but the shadow (attached to A only, which includes
    # the shadows of the combinations of A and B) needs to
    # be recalculated.
    #
    # So if you want to cache, you'd have to cache on the whole of the
    # bounds (origin related to the root morph A, and extent) of
    # A and all its submorphs.

    ###
    if @backBuffer?
      # @backBuffer.width and @backBuffer.height are already in
      # physical coordinates so no need to adjust for pixelratio
      backBufferExtent = new Point @backBuffer.width, @backBuffer.height
      if backBufferExtent.eq extent.scaleBy pixelRatio
        return [@backBuffer, @backBufferContext]
    ###

    @bounds.debugIfFloats()
    if WorldMorph.preferencesAndSettings.useBlurredShadows and !WorldMorph.preferencesAndSettings.isFlat
      @backBuffer = @targetMorph.shadowImage @offset, @color, true
    else
      @backBuffer = @targetMorph.shadowImage @offset, @color, false
    @backBufferContext =  @backBuffer.getContext "2d"
    @bounds.debugIfFloats()
    @offset.debugIfFloats()

    return [@backBuffer, @backBufferContext]
