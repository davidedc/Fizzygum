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

  scrollFrame: null
  extraPadding: 0

  # if this frame belongs to a scrollFrame, then
  # the @scrollFrame points to it
  constructor: (@scrollFrame = null) ->
    super()
    @color = new Color(255, 250, 245)
    @acceptsDrops = true
    if @scrollFrame
      @isDraggable = false
      @noticesTransparentClick = false

  setColor: (aColor) ->
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container scrollFrame
    # is actually not painted.
    if @scrollFrame
      @scrollFrame.color = aColor
    super(aColor)

  setAlphaScaled: (alpha) ->
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container scrollFrame
    # is actually not painted.
    if @scrollFrame
      @scrollFrame.alpha = @calculateAlphaScaled(alpha)
    super(alpha)

  # used for example:
  # - to determine which morphs you can attach a morph to
  # - for a SliderMorph's "set target" so you can change properties of another Morph
  # - by the HandleMorph when you attach it to some other morph
  # Note that this method has a slightly different
  # version in Morph (because it doesn't clip)
  plausibleTargetAndDestinationMorphs: (theMorph) ->
    # find if I intersect theMorph,
    # then check my children recursively
    # exclude me if I'm a child of theMorph
    # (cause it's usually odd to attach a Morph
    # to one of its submorphs or for it to
    # control the properties of one of its submorphs)
    result = []
    if !@isMinimised and
        @isVisible and
        !theMorph.containedInParentsOf(@) and
        @bounds.intersects(theMorph.bounds)
      result = [@]

    # Since the FrameMorph clips its children
    # at its boundary, hence we need
    # to check that we don't consider overlaps with
    # morphs contained in this frame that are clipped and
    # hence *actually* not overlapping with theMorph.
    # So continue checking the children only if the
    # frame itself actually overlaps.
    if @bounds.intersects(theMorph.bounds)
      @children.forEach (child) ->
        result = result.concat(child.plausibleTargetAndDestinationMorphs(theMorph))

    return result
  
  # frames clip at their boundaries
  # so there is no need to do a deep
  # traversal to find the bounds.
  boundsIncludingChildren: ->
    shadow = @getShadow()
    if shadow?
      return @bounds.merge(shadow.bounds)
    @bounds

  
  boundsIncludingChildrenNoShadow: ->
    # answer my full bounds but ignore any shadow
    @bounds

  
  recursivelyBlit: (aCanvas, clippingRectangle = @bounds) ->
    return null  unless (!@isMinimised and @isVisible)

    # a FrameMorph has the special property that all of its children
    # are actually inside its boundary.
    # This allows
    # us to avoid the further traversal of potentially
    # many many morphs if we see that the rectangle we
    # want to blit is outside its frame.
    # If the rectangle we want to blit is inside the frame
    # then we do have to continue traversing all the
    # children of the Frame.

    # This is why as well it's good to use FrameMorphs whenever
    # it's clear that there is a "container" case. Think
    # for example that you could stick a small
    # RectangleMorph (not a Frame) on the desktop and then
    # attach a thousand
    # CircleBoxMorphs on it.
    # Say that the circles are all inside the rectangle,
    # apart from four that are at the corners of the world.
    # that's a nightmare scenegraph
    # to *completely* traverse for *any* broken rectangle
    # anywhere on the screen.
    # The traversal is complete because a) Morphic doesn't
    # assume that the rectangle clips its children and
    # b) the bounding rectangle (which currently is not
    # efficiently calculated anyways) is the whole screen.
    # So the children could be anywhere and need to be all
    # checked for damaged areas to repaint.
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
    #console.log "moving all morphs in the frame"
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
  
  # Should it be in the scrollframe rather than in Frame?
  keepInScrollFrame: ->
    if !@scrollFrame?
      return null
    if @left() > @scrollFrame.left()
      @moveBy new Point(@scrollFrame.left() - @left(), 0)
    if @right() < @scrollFrame.right()
      @moveBy new Point(@scrollFrame.right() - @right(), 0)  
    if @top() > @scrollFrame.top()
      @moveBy new Point(0, @scrollFrame.top() - @top())  
    if @bottom() < @scrollFrame.bottom()
      @moveBy 0, new Point(@scrollFrame.bottom() - @bottom(), 0)
  
  adjustBounds: ->
    if !@scrollFrame?
      return null

    # if FrameMorph is of type isTextLineWrapping
    # it means that you don't want the TextMorph to
    # extend indefinitely as you are typing. Rather,
    # the width will be constrained and the text will
    # wrap.
    if @scrollFrame.isTextLineWrapping
      @children.forEach (morph) =>
        if morph instanceof TextMorph
          totalPadding =  2*(@scrollFrame.extraPadding + @scrollFrame.padding)
          # this re-layouts the text to fit the width.
          # The new height of the TextMorph will then be used
          # to redraw the vertical slider.
          morph.setWidth @width() - totalPadding
          morph.maxWidth = @width() - totalPadding
          @setHeight Math.max(morph.height(), @scrollFrame.height() - totalPadding)

    subBounds = @submorphBounds()
    if subBounds
      newBounds = subBounds.expandBy(@scrollFrame.padding + @scrollFrame.extraPadding).growBy(@scrollFrame.growth).merge(@scrollFrame.bounds)
    else
      newBounds = @scrollFrame.bounds.copy()
    unless @bounds.eq(newBounds)
      @bounds = newBounds
      @updateBackingStore()
      @keepInScrollFrame()
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
      menu.addItem "move all inside", (->@keepAllSubmorphsWithin()), "keep all submorphs\nwithin and visible"
    menu
  
  keepAllSubmorphsWithin: ->
    @children.forEach (m) =>
      m.keepWithin @
