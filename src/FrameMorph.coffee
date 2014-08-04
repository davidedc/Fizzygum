#| FrameMorph //////////////////////////////////////////////////////////
#| 
#| I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
#| 
#| and event handling. 
#| 
#| It's a good idea to use me whenever it's clear that there is a  
#| 
#| "container"/"contained" scenario going on.

class FrameMorph extends Morph

  @scrollFrame: null

  # if this frame belongs to a scrollFrame, then
  # the @scrollFrame points to it
  constructor: (@scrollFrame = null) ->
    super()
    @color = new Color(255, 250, 245)
    @acceptsDrops = true
    if @scrollFrame
      @isDraggable = false
      @noticesTransparentClick = false
    @updateRendering()

  setColor: (aColor) ->
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container srollFrame
    # is actually not painted.
    if @scrollFrame
      @scrollFrame.color = aColor
    super(aColor)

  setAlphaScaled: (alpha) ->
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container srollFrame
    # is actually not painted.
    if @scrollFrame
      @scrollFrame.alpha = @calculateAlphaScaled(alpha)
    super(alpha)
  
  boundsIncludingChildren: ->
    shadow = @getShadow()
    return @bounds.merge(shadow.bounds)  if shadow isnt null
    @bounds
  
  recursivelyBlit: (aCanvas, clippingRectangle = @bounds) ->
    return null  unless (!@isMinimised and @isVisible)

    # a FrameMorph has the special property that all of its children
    # are actually inside its boundary. This allows
    # us to avoid the further traversal of potentially
    # many many morphs if we see that the rectangle we
    # want to blit is outside its frame.
    # If the rectangle we want to blit is inside the frame
    # then we do have to continue traversing all the
    # children of the Frame.

    # This is why as well it's good to use FrameMorphs whenever
    # it's clear that there is a "container" case. Think
    # for example that you could stick a big RectangleMorph
    # (not a Frame) on the desktop and then attach a thousand
    # CircleBoxMorphs on it. That's a nightmare scenegraph
    # to *completely* traverse for *any* broken rectangle.
    # If the RectangleMorph is made into a frame, one can
    # avoid the traversal for any broken rectangle not
    # overlapping it.

    # Also note that in theory you could stop recursion on any
    # FrameMorph completely covered by a large opaque morph
    # (or on any Morph which boundsIncludingChildren are completely
    # covered, for that matter). You could
    # keep for example a list of the top n biggest opaque morphs
    # (say, frames and rectangles)
    # and check that case while you traverse the list.
    # (see https://github.com/davidedc/Zombie-Kernel/issues/149 )
    
    # the part to be redrawn could be outside the frame entirely,
    # in which case we can stop going down the morphs inside the frame
    # since the whole point of the frame is to clip everything to a specific
    # rectangle.
    # So, check which part of the Frame should be redrawn:
    dirtyPartOfFrame = @bounds.intersect(clippingRectangle)
    
    # if there is no dirty part in the frame then do nothing
    return null if dirtyPartOfFrame.isEmpty()
    
    # this draws the background of the frame itself, which could
    # contain an image or a pentrail
    @blit aCanvas, dirtyPartOfFrame
    
    @children.forEach (child) =>
      if child instanceof ShadowMorph
        child.recursivelyBlit aCanvas, clippingRectangle
      else
        child.recursivelyBlit aCanvas, dirtyPartOfFrame
  
  
  # FrameMorph scrolling optimization:
  moveBy: (delta) ->
    @changed()
    @bounds = @bounds.translateBy(delta)
    @children.forEach (child) ->
      child.silentMoveBy delta
    @changed()
  
  
  # FrameMorph scrolling support:
  submorphBounds: ->
    result = null
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        result = result.merge(child.boundsIncludingChildren())
    result
  
  keepInScrollFrame: ->
    return null  if @scrollFrame is null
    if @left() > @scrollFrame.left()
      @moveBy new Point(@scrollFrame.left() - @left(), 0)
    if @right() < @scrollFrame.right()
      @moveBy new Point(@scrollFrame.right() - @right(), 0)  
    if @top() > @scrollFrame.top()
      @moveBy new Point(0, @scrollFrame.top() - @top())  
    if @bottom() < @scrollFrame.bottom()
      @moveBy 0, new Point(@scrollFrame.bottom() - @bottom(), 0)
  
  adjustBounds: ->
    return null  if @scrollFrame is null
    subBounds = @submorphBounds()
    if subBounds and (not @scrollFrame.isTextLineWrapping)
      newBounds = subBounds.expandBy(@scrollFrame.padding).growBy(@scrollFrame.growth).merge(@scrollFrame.bounds)
    else
      newBounds = @scrollFrame.bounds.copy()
    unless @bounds.eq(newBounds)
      @bounds = newBounds
      @updateRendering()
      @keepInScrollFrame()
    if @scrollFrame.isTextLineWrapping
      @children.forEach (morph) =>
        if morph instanceof TextMorph
          morph.setWidth @width()
          @setHeight Math.max(morph.height(), @scrollFrame.height())
    @scrollFrame.adjustScrollBars()
  
  
  # FrameMorph dragging & dropping of contents:
  reactToDropOf: ->
    @adjustBounds()
  
  reactToGrabOf: ->
    @adjustBounds()
  
    
  # FrameMorph menus:
  developersMenu: ->
    menu = super()
    if @children.length
      menu.addLine()
      menu.addItem "move all inside...", (->@keepAllSubmorphsWithin()), "keep all submorphs\nwithin and visible"
    menu
  
  keepAllSubmorphsWithin: ->
    @children.forEach (m) =>
      m.keepWithin @
