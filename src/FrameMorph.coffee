# FrameMorph //////////////////////////////////////////////////////////

# I clip my submorphs at my bounds

class FrameMorph extends Morph
  constructor: (aScrollFrame) ->
    @init aScrollFrame

FrameMorph::init = (aScrollFrame) ->
  @scrollFrame = aScrollFrame or null
  super()
  @color = new Color(255, 250, 245)
  @drawNew()
  @acceptsDrops = true
  if @scrollFrame
    @isDraggable = false
    @noticesTransparentClick = false
    @alpha = 0

FrameMorph::fullBounds = ->
  shadow = @getShadow()
  return @bounds.merge(shadow.bounds)  if shadow isnt null
  @bounds

FrameMorph::fullImage = ->
  
  # use only for shadows
  @image

FrameMorph::fullDrawOn = (aCanvas, aRect) ->
  myself = this
  rectangle = undefined
  return null  unless @isVisible
  rectangle = aRect or @fullBounds()
  @drawOn aCanvas, rectangle
  @children.forEach (child) ->
    if child instanceof ShadowMorph
      child.fullDrawOn aCanvas, rectangle
    else
      child.fullDrawOn aCanvas, myself.bounds.intersect(rectangle)



# FrameMorph scrolling optimization:
FrameMorph::moveBy = (delta) ->
  @changed()
  @bounds = @bounds.translateBy(delta)
  @children.forEach (child) ->
    child.silentMoveBy delta

  @changed()


# FrameMorph scrolling support:
FrameMorph::submorphBounds = ->
  result = null
  if @children.length > 0
    result = @children[0].bounds
    @children.forEach (child) ->
      result = result.merge(child.fullBounds())

  result

FrameMorph::keepInScrollFrame = ->
  return null  if @scrollFrame is null
  @moveBy new Point(@scrollFrame.left() - @left(), 0)  if @left() > @scrollFrame.left()
  @moveBy new Point(@scrollFrame.right() - @right(), 0)  if @right() < @scrollFrame.right()
  @moveBy new Point(0, @scrollFrame.top() - @top())  if @top() > @scrollFrame.top()
  @moveBy 0, new Point(@scrollFrame.bottom() - @bottom(), 0)  if @bottom() < @scrollFrame.bottom()

FrameMorph::adjustBounds = ->
  subBounds = undefined
  newBounds = undefined
  myself = this
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
    @children.forEach (morph) ->
      if morph instanceof TextMorph
        morph.setWidth myself.width()
        myself.setHeight Math.max(morph.height(), myself.scrollFrame.height())

  @scrollFrame.adjustScrollBars()


# FrameMorph dragging & dropping of contents:
FrameMorph::reactToDropOf = ->
  @adjustBounds()

FrameMorph::reactToGrabOf = ->
  @adjustBounds()


# FrameMorph duplicating:
FrameMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.frame = (dict[@scrollFrame])  if c.frame and dict[@scrollFrame]
  c


# FrameMorph menus:
FrameMorph::developersMenu = ->
  menu = super()
  if @children.length > 0
    menu.addLine()
    menu.addItem "move all inside...", "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
  menu

FrameMorph::keepAllSubmorphsWithin = ->
  myself = this
  @children.forEach (m) ->
    m.keepWithin myself
