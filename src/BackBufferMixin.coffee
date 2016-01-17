# //////////////////////////////////////////////////////////

# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions

# A BackBuffer is a canvas that a morph can keep for
# two reasons:
#   1) as a cache
#   2) because the morph has inherently a "raster" nature
#      such as the canvas where you can run a turtle to
#      draw stuff, or a Morph where you want to have
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
# Ideal use of a cache is tex,t because painting text
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
  # klass properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: ->
    @addInstanceProperties

      # note that image contains only the CURRENT morph, not the composition of this
      # morph with all of the submorphs. I.e. for an inspector, this will only
      # contain the background of the window pane. Not any of its contents.
      # for the worldMorph, this only contains the background
      backBuffer: null
      backBufferContext: null
      backBufferIsPotentiallyDirty: true

      # just a flag to indicate that the
      # backBufferContext value can be derived from others
      backBufferContext_isDerivedValue: true

      calculateKeyValues: (aContext, clippingRectangle) ->
        area = clippingRectangle.intersect(@boundingBox()).round()
        # test whether anything that we are going to be drawing
        # is visible (i.e. within the clippingRectangle)
        if area.isNotEmpty()
          delta = @position().neg()
          src = area.translateBy(delta).round()
          sl = src.left() * pixelRatio
          st = src.top() * pixelRatio
          al = area.left() * pixelRatio
          at = area.top() * pixelRatio
          w = Math.min(src.width() * pixelRatio, @backBuffer.width - sl)
          h = Math.min(src.height() * pixelRatio, @backBuffer.height - st)
        return [area,sl,st,al,at,w,h]

      isTransparentAt: (aPoint) ->
        @bounds.debugIfFloats()
        if @boundsContainPoint aPoint
          return false  if @texture
          data = @getPixelColor aPoint
          # check the 4th byte - the Alpha (RGBA)
          return data.a is 0
        false

      # Morph pixel access:
      getPixelColor: (aPoint) ->
        [@backBuffer, @backBufferContext] = @createRefreshOrGetImmutableBackBuffer()
        point = aPoint.toLocalCoordinatesOf @
        data = @backBufferContext.getImageData point.x * pixelRatio, point.y * pixelRatio, 1, 1
        new Color data.data[0], data.data[1], data.data[2], data.data[3]


      # This method only paints this very morph's "image",
      # it doesn't descend the children
      # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
      # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
      # Note that this morph might paint something on the screen even if
      # it's not a "leaf".
      paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

        if !@visibleBasedOnIsVisibleProperty() or @isCollapsed()
          return null

        [@backBuffer, @backBufferContext] = @createRefreshOrGetImmutableBackBuffer()

        if !@backBuffer?
          return null

        [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
        if area.isNotEmpty()
          if w < 1 or h < 1
            return null

          aContext.save()

          aContext.globalAlpha = @alpha

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
          @paintHighlight aContext, al, at, w, h
