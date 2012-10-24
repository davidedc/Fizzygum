# FrameMorph //////////////////////////////////////////////////////////

# I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
# and event handling.

class FrameMorph extends Morph

  @scrollFrame: null

  constructor: (@scrollFrame = null) ->
    super()
    @color = new Color(255, 250, 245)
    @drawNew()
    @acceptsDrops = true
    if @scrollFrame
      @isDraggable = false
      @noticesTransparentClick = false
      @alpha = 0
  
  boundsIncludingChildren: ->
    shadow = @getShadow()
    return @bounds.merge(shadow.bounds)  if shadow isnt null
    @bounds
  
  fullImage: ->
    # use only for shadows
    @image
  
  fullDrawOn: (aCanvas, aRect) ->
    return null  unless @isVisible
    boundsRectangle = aRect or @boundsIncludingChildren()
    
    # the part to be redrawn could be outside the frame entirely,
    # in which case we can stop going down the morphs inside the frame
    # since the whole point of the frame is to clip everything to a specific
    # rectangle.
    # So, check which part of the Frame should be redrawn:
    dirtyPartOfFrame = @bounds.intersect(boundsRectangle)
    
    # if there is no dirty part in the frame then do nothing
    return null unless dirtyPartOfFrame.extent().gt(new Point(0, 0))
    
    # this draws the background of the frame itself, which could
    # contain an image or a pentrail
    @drawOn aCanvas, dirtyPartOfFrame
    
    @children.forEach (child) =>
      if child instanceof ShadowMorph
        child.fullDrawOn aCanvas, boundsRectangle
      else
        child.fullDrawOn aCanvas, dirtyPartOfFrame
  
  
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
    if @children.length > 0
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
      @drawNew()
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
  
  
  # FrameMorph duplicating:
  copyRecordingReferences: (dict) ->
    # inherited, see comment in Morph
    c = super dict
    c.frame = (dict[@scrollFrame])  if c.frame and dict[@scrollFrame]
    c
  
  
  # FrameMorph menus:
  developersMenu: ->
    menu = super()
    if @children.length > 0
      menu.addLine()
      menu.addItem "move all inside...", "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
    menu
  
  keepAllSubmorphsWithin: ->
    @children.forEach (m) =>
      m.keepWithin @
