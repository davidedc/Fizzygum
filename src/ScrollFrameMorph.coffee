# ScrollFrameMorph ////////////////////////////////////////////////////

class ScrollFrameMorph extends FrameMorph
  constructor: (scroller, size, sliderColor) ->
    @init scroller, size, sliderColor


ScrollFrameMorph::init = (scroller, size, sliderColor) ->
  myself = this
  super()
  @scrollBarSize = size or MorphicPreferences.scrollBarSize
  @autoScrollTrigger = null
  @isScrollingByDragging = true # change if desired
  @hasVelocity = true # dto.
  @padding = 0 # around the scrollable area
  @growth = 0 # pixels or Point to grow right/left when near edge
  @isTextLineWrapping = false
  @contents = scroller or new FrameMorph(this)
  @add @contents
  # start
  # stop
  # value
  # size
  @hBar = new SliderMorph(null, null, null, null, "horizontal", sliderColor)
  @hBar.setHeight @scrollBarSize
  @hBar.action = (num) ->
    myself.contents.setPosition new Point(myself.left() - num, myself.contents.position().y)

  @hBar.isDraggable = false
  @add @hBar
  # start
  # stop
  # value
  # size
  @vBar = new SliderMorph(null, null, null, null, "vertical", sliderColor)
  @vBar.setWidth @scrollBarSize
  @vBar.action = (num) ->
    myself.contents.setPosition new Point(myself.contents.position().x, myself.top() - num)

  @vBar.isDraggable = false
  @add @vBar

ScrollFrameMorph::adjustScrollBars = ->
  hWidth = @width() - @scrollBarSize
  vHeight = @height() - @scrollBarSize
  @changed()
  if @contents.width() > @width() + MorphicPreferences.scrollBarSize
    @hBar.show()
    @hBar.setWidth hWidth  if @hBar.width() isnt hWidth
    @hBar.setPosition new Point(@left(), @bottom() - @hBar.height())
    @hBar.start = 0
    @hBar.stop = @contents.width() - @width()
    @hBar.size = @width() / @contents.width() * @hBar.stop
    @hBar.value = @left() - @contents.left()
    @hBar.drawNew()
  else
    @hBar.hide()
  if @contents.height() > @height() + @scrollBarSize
    @vBar.show()
    @vBar.setHeight vHeight  if @vBar.height() isnt vHeight
    @vBar.setPosition new Point(@right() - @vBar.width(), @top())
    @vBar.start = 0
    @vBar.stop = @contents.height() - @height()
    @vBar.size = @height() / @contents.height() * @vBar.stop
    @vBar.value = @top() - @contents.top()
    @vBar.drawNew()
  else
    @vBar.hide()

ScrollFrameMorph::addContents = (aMorph) ->
  @contents.add aMorph
  @contents.adjustBounds()

ScrollFrameMorph::setContents = (aMorph) ->
  @contents.children.forEach (m) ->
    m.destroy()

  @contents.children = []
  aMorph.setPosition @position().add(new Point(2, 2))
  @addContents aMorph

ScrollFrameMorph::setExtent = (aPoint) ->
  @contents.setPosition @position().copy()  if @isTextLineWrapping
  super aPoint
  @contents.adjustBounds()


# ScrollFrameMorph scrolling by dragging:
ScrollFrameMorph::scrollX = (steps) ->
  cl = @contents.left()
  l = @left()
  cw = @contents.width()
  r = @right()
  newX = undefined
  newX = cl + steps
  newX = l  if newX > l
  newX = r - cw  if newX + cw < r
  @contents.setLeft newX  if newX isnt cl

ScrollFrameMorph::scrollY = (steps) ->
  ct = @contents.top()
  t = @top()
  ch = @contents.height()
  b = @bottom()
  newY = undefined
  newY = ct + steps
  newY = t  if newY > t
  newY = b - ch  if newY + ch < b
  @contents.setTop newY  if newY isnt ct

ScrollFrameMorph::step = ->
  nop()

ScrollFrameMorph::mouseDownLeft = (pos) ->
  return null  unless @isScrollingByDragging
  world = @root()
  oldPos = pos
  myself = this
  deltaX = 0
  deltaY = 0
  friction = 0.8
  @step = ->
    newPos = undefined
    if world.hand.mouseButton and (world.hand.children.length is 0) and (myself.bounds.containsPoint(world.hand.position()))
      newPos = world.hand.bounds.origin
      deltaX = newPos.x - oldPos.x
      myself.scrollX deltaX  if deltaX isnt 0
      deltaY = newPos.y - oldPos.y
      myself.scrollY deltaY  if deltaY isnt 0
      oldPos = newPos
    else
      unless myself.hasVelocity
        myself.step = ->
          nop()
      else
        if (Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5)
          myself.step = ->
            nop()
        else
          deltaX = deltaX * friction
          myself.scrollX Math.round(deltaX)
          deltaY = deltaY * friction
          myself.scrollY Math.round(deltaY)
    @adjustScrollBars()

ScrollFrameMorph::startAutoScrolling = ->
  myself = this
  inset = MorphicPreferences.scrollBarSize * 3
  world = @world()
  hand = undefined
  inner = undefined
  pos = undefined
  return null  unless world
  hand = world.hand
  @autoScrollTrigger = Date.now()  unless @autoScrollTrigger
  @step = ->
    pos = hand.bounds.origin
    inner = myself.bounds.insetBy(inset)
    if (myself.bounds.containsPoint(pos)) and (not (inner.containsPoint(pos))) and (hand.children.length > 0)
      myself.autoScroll pos
    else
      myself.step = ->
        nop()

      myself.autoScrollTrigger = null

ScrollFrameMorph::autoScroll = (pos) ->
  inset = undefined
  area = undefined
  return null  if Date.now() - @autoScrollTrigger < 500
  inset = MorphicPreferences.scrollBarSize * 3
  area = @topLeft().extent(new Point(@width(), inset))
  @scrollY inset - (pos.y - @top())  if area.containsPoint(pos)
  area = @topLeft().extent(new Point(inset, @height()))
  @scrollX inset - (pos.x - @left())  if area.containsPoint(pos)
  area = (new Point(@right() - inset, @top())).extent(new Point(inset, @height()))
  @scrollX -(inset - (@right() - pos.x))  if area.containsPoint(pos)
  area = (new Point(@left(), @bottom() - inset)).extent(new Point(@width(), inset))
  @scrollY -(inset - (@bottom() - pos.y))  if area.containsPoint(pos)
  @adjustScrollBars()


# ScrollFrameMorph events:
ScrollFrameMorph::mouseScroll = (y, x) ->
  @scrollY y * MorphicPreferences.mouseScrollAmount  if y
  @scrollX x * MorphicPreferences.mouseScrollAmount  if x
  @adjustScrollBars()

ScrollFrameMorph::copyRecordingReferences = (dict) ->
  
  # inherited, see comment in Morph
  c = super dict
  c.contents = (dict[@contents])  if c.contents and dict[@contents]
  if c.hBar and dict[@hBar]
    c.hBar = (dict[@hBar])
    c.hBar.action = (num) ->
      c.contents.setPosition new Point(c.left() - num, c.contents.position().y)
  if c.vBar and dict[@vBar]
    c.vBar = (dict[@vBar])
    c.vBar.action = (num) ->
      c.contents.setPosition new Point(c.contents.position().x, c.top() - num)
  c

ScrollFrameMorph::developersMenu = ->
  menu = super()
  if @isTextLineWrapping
    menu.addItem "auto line wrap off...", "toggleTextLineWrapping", "turn automatic\nline wrapping\noff"
  else
    menu.addItem "auto line wrap on...", "toggleTextLineWrapping", "enable automatic\nline wrapping"
  menu

ScrollFrameMorph::toggleTextLineWrapping = ->
  @isTextLineWrapping = not @isTextLineWrapping
