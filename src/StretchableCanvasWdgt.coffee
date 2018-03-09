# The difference between this and a Canvas is that once the
# user starts to paint on the StretchableCanvas, it locks the
# aspect ratio... and any further resizing keeps the original
# paiting and the user can keep painting at any new scale...
#
# This is achieved by keeping an extra canvas behind the scenes
# that keeps the original resolution of when the first paint
# action happened. The user keeps painting on that "behind
# the scenes canvas" with the original resolution, no matter
# what the scale of the "front facing" canvas is on screen.
# So any time the user resizes the front canvas or she paints
# on the "behind the scenes", the "behind the scenes"
# is painted on the front one at the correct scale.
#
# Note that since the "behind the scenes" canvas
# keeps the same size... if the user starts painting
# when the size is small... then enlarging the canvas
# will just cause the smaller "behind the scenes" canvas
# to be painted on the smaller "front facing" canvas...
# so everything new will be painted blurry.
#
# You could enhance this so that if the user scales up
# the canvas, then the "behind the scenes" is also
# resized-up (previous content will be blurry but new
# content will be sharp).

class StretchableCanvasWdgt extends CanvasMorph

  anythingPaintedYet: false
  extentWhenCanvasGotDirty: nil

  behindTheScenesBackBuffer: nil
  behindTheScenesBackBufferContext: nil


  # No changes of position or extent should be
  # performed in here.
  # There is really little hope to cache this buffer
  # cross-morph, unless you key the buffer with the
  # order of all the primitives and their
  # parameters. So if user wants a cache it will have to specify
  # a dedicated one in here. See textMorph for an example.
  createRefreshOrGetBackBuffer: ->

    extent = @extent()

    if !@backBuffer?
      @createNewSmallExtentBuffer extent

    # little shortcut: if nothing has been painted yet then
    # we can omit painting the big canvas on the small one,
    # just clean up the small canvas
    if !@anythingPaintedYet and @color?
      @backBufferContext.fillStyle = @color.toString()
      @backBufferContext.fillRect 0, 0, extent.x * pixelRatio, extent.y * pixelRatio

    # if something *has* been painted then
    # we need to paint the "behind the scenes" buffer into the
    # one we show on screen
    if @anythingPaintedYet
      @backBufferContext.setTransform 1, 0, 0, 1, 0, 0
      @backBufferContext.scale @width()/@extentWhenCanvasGotDirty.x, @height()/@extentWhenCanvasGotDirty.y
      @backBufferContext.drawImage @behindTheScenesBackBuffer, 0, 0

    
    # we leave the context with the correct pixel scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @backBufferContext.scale pixelRatio, pixelRatio
    return [@backBuffer, @backBufferContext]


  # don't need this at the moment, you'd need to
  # clear both backbuffers and invoke a @parent?.resetRatio?()
  # since once it's empty you can really let the user re-think
  # the aspect ratio of her painting
  clear: (color = @color) ->
    throw new Error "not implemented yet"

  createNewBigExtentBuffer: (extent) ->
    @behindTheScenesBackBuffer = newCanvas extent.scaleBy pixelRatio
    @behindTheScenesBackBufferContext = @behindTheScenesBackBuffer.getContext "2d"

    if @color?
      @behindTheScenesBackBufferContext.fillStyle = @color.toString()
      @behindTheScenesBackBufferContext.fillRect 0, 0, extent.x * pixelRatio, extent.y * pixelRatio

    # we leave the context with the correct scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @behindTheScenesBackBufferContext.scale pixelRatio, pixelRatio

  createNewSmallExtentBuffer: (extent) ->
    @backBuffer = newCanvas extent.scaleBy pixelRatio
    @backBufferContext = @backBuffer.getContext "2d"


    # we leave the context with the correct scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @backBufferContext.scale pixelRatio, pixelRatio


  rawSetExtent: (extent) ->

    if extent.eq @extent()
      return

    if !@behindTheScenesBackBuffer? or !@anythingPaintedYet
      @createNewBigExtentBuffer extent

    super
    @doLayout @bounds


  getContextForPainting: ->
    # only set ratio with the first paint operation
    # the following ones don't change it
    if @parent?.setRatio? and !@parent.ratio?
      @parent.setRatio @width() / @height()
      @extentWhenCanvasGotDirty = @extent()
      @anythingPaintedYet = true

    @behindTheScenesBackBufferContext.setTransform 1, 0, 0, 1, 0, 0
    @behindTheScenesBackBufferContext.scale pixelRatio, pixelRatio

    @behindTheScenesBackBufferContext.scale @extentWhenCanvasGotDirty.x/@width(), @extentWhenCanvasGotDirty.y/@height()

    @behindTheScenesBackBufferContext.translate -@bounds.origin.x, -@bounds.origin.y
    return @behindTheScenesBackBufferContext

  # don't need this at the moment, you'd need to
  # paint on the "behind the scenes" backbuffer
  drawLine: (start, dest, lineWidth, color) ->
    throw new Error "not implemented yet"
  
  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    console.log "scanvas dolayout 1"


    console.log "scanvas dolayout 2"

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    @rawSetBounds newBoundsForThisLayout

    childrenNotHandlesNorCarets = @children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    for eachChild in childrenNotHandlesNorCarets
      console.log "scanvas eachChild: " + eachChild + " bounds: " + @bounds
      eachChild.rawSetBounds @bounds


    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
