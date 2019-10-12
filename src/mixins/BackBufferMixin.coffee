# //////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions

# A BackBuffer is a canvas that a morph can keep for
# two reasons:
#   1) as a cache
#   2) because the morph has inherently a "raster" nature
#      such as the canvas where you can run a turtle to
#      draw stuff, or a Widget where you want to have
#      pixel-based filters.
#
# The cache use is useful for morphs that ideally
#  * have a small extent
#  * have an expensive painting process
#  * are repainted often
#
# (Note that the cache for the time being is only
# for the very morph, not for the whole of the
# hierarchy.)
#
# Ideal use of a cache is text because painting text
# can be a lengthy operation.
# Worst possible use of a cache is the large
# desktop background rectangle, where a lot of memory
# would be wasted for saving a very short painting
# operation.
#
# In theory the backing store use should be transparent and
# automatic, driven perhaps by dynamic considerations,
# but we are not there yet.

BackBufferMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      # note that image contains only the CURRENT morph, not the composition of this
      # morph with all of the submorphs. I.e. for an inspector, this will only
      # contain the background of the window pane. Not any of its contents.
      # for the worldMorph, this only contains the background
      backBuffer: nil
      backBufferContext: nil

      # just a flag to indicate that the
      # backBufferContext value can be derived from others
      backBufferContext_isDerivedValue: true

      # as seen by the " * ceilPixelRatio " parts in the code,
      # this function returns actual pixels, not logical pixels.
      # Hence, these values are only good outside of the
      # scope of the scaling due to the ceilPixelRatio
      calculateKeyValues: (aContext, clippingRectangle) ->
        area = clippingRectangle.intersect(@boundingBox()).round()
        # test whether anything that we are going to be drawing
        # is visible (i.e. within the clippingRectangle)
        if area.isNotEmpty()
          delta = @position().neg()
          src = area.translateBy(delta).round()
          
          # the " * ceilPixelRatio " multiplications
          # tranform logical pixels into actual pixels.
          sl = src.left() * ceilPixelRatio
          st = src.top() * ceilPixelRatio
          al = area.left() * ceilPixelRatio
          at = area.top() * ceilPixelRatio
          # @backBuffer.width and @backBuffer.height are already in
          # physical coordinates so no need to adjust for pixelratio
          w = Math.min(src.width() * ceilPixelRatio, @backBuffer.width - sl)
          h = Math.min(src.height() * ceilPixelRatio, @backBuffer.height - st)
        return [area,sl,st,al,at,w,h]

      isTransparentAt: (aPoint) ->
        @bounds.debugIfFloats()
        if @boundsContainPoint aPoint
          return false  if @texture
          data = @getPixelColor aPoint
          # check the 4th byte - the Alpha (RGBA)
          return data.a is 0
        false

      # Widget pixel access:
      getPixelColor: (aPoint) ->
        [@backBuffer, @backBufferContext] = @createRefreshOrGetBackBuffer()
        point = aPoint.toLocalCoordinatesOf @
        data = @backBufferContext.getImageData point.x * ceilPixelRatio, point.y * ceilPixelRatio, 1, 1
        new Color data.data[0], data.data[1], data.data[2], data.data[3]


      # This method only paints this very morph's "image",
      # it doesn't descend the children
      # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
      # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
      # Note that this morph might paint something on the screen even if
      # it's not a "leaf".
      paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
        @justBeforeBeingPainted?()

        if !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
          return nil

        [@backBuffer, @backBufferContext] = @createRefreshOrGetBackBuffer()

        if !@backBuffer?
          return nil

        [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
        return nil if w < 1 or h < 1 or area.isEmpty()

        aContext.save()

        aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

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
        # of the ceilPixelRatio
        @paintHighlight aContext, al, at, w, h
