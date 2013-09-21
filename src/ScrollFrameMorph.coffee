# ScrollFrameMorph ////////////////////////////////////////////////////

# this comment below is needed to figure our dependencies between classes
# REQUIRES globalFunctions

class ScrollFrameMorph extends FrameMorph

  autoScrollTrigger: null
  hasVelocity: true # dto.
  padding: 0 # around the scrollable area
  growth: 0 # pixels or Point to grow right/left when near edge
  isTextLineWrapping: false
  isScrollingByDragging: true
  scrollBarSize: null
  contents: null
  vBar: null
  hBar: null

  constructor: (contents, scrollBarSize, sliderColor) ->
    # super() paints the scrollframe, which we don't want,
    # so we set 0 opacity here.
    @alpha = 0
    super()
    @scrollBarSize = scrollBarSize or WorldMorph.MorphicPreferences.scrollBarSize
    @contents = contents or new FrameMorph(@)
    @add @contents

    # the scrollFrame is never going to paint itself,
    # but its values are going to mimick the values of the
    # contained frame
    @color = @contents.color
    @alpha = @contents.alpha
    # the scrollFrame is a container, it redirects most
    # commands to the "contained" frame
    @updateRendering = @contents.updateRendering
    #@setColor = @contents.setColor
    #@setAlphaScaled = @contents.setAlphaScaled

    @hBar = new SliderMorph(null, null, null, null, "horizontal", sliderColor)
    @hBar.setHeight @scrollBarSize
    @hBar.action = (num) =>
      @contents.setPosition new Point(@left() - num, @contents.position().y)
    @hBar.isDraggable = false
    @add @hBar

    @vBar = new SliderMorph(null, null, null, null, "vertical", sliderColor)
    @vBar.setWidth @scrollBarSize
    @vBar.action = (num) =>
      @contents.setPosition new Point(@contents.position().x, @top() - num)
    @vBar.isDraggable = false
    @add @vBar


  setColor: (aColor) ->
    # update the color of the scrollFrame - note
    # that we are never going to paint the scrollFrame
    # we are updating the color so that its value is the same as the
    # contained frame
    @color = aColor
    @contents.setColor(aColor)

  setAlphaScaled: (alpha) ->
    # update the alpha of the scrollFrame - note
    # that we are never going to paint the scrollFrame
    # we are updating the alpha so that its value is the same as the
    # contained frame
    @alpha = @calculateAlphaScaled(alpha)
    @contents.setAlphaScaled(alpha)

  adjustScrollBars: ->
    hWidth = @width() - @scrollBarSize
    vHeight = @height() - @scrollBarSize
    @changed()
    if @contents.width() > @width() + WorldMorph.MorphicPreferences.scrollBarSize
      @hBar.show()
      @hBar.setWidth hWidth  if @hBar.width() isnt hWidth
      @hBar.setPosition new Point(@left(), @bottom() - @hBar.height())
      @hBar.start = 0
      @hBar.stop = @contents.width() - @width()
      @hBar.size = @width() / @contents.width() * @hBar.stop
      @hBar.value = @left() - @contents.left()
      @hBar.updateRendering()
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
      @vBar.updateRendering()
    else
      @vBar.hide()
  
  addContents: (aMorph) ->
    @contents.add aMorph
    @contents.adjustBounds()
  
  setContents: (aMorph) ->
    @contents.destroyAll()
    #
    @contents.children = []
    aMorph.setPosition @position().add(@padding + 2)
    @addContents aMorph
  
  setExtent: (aPoint) ->
    @contents.setPosition @position().copy()  if @isTextLineWrapping
    super aPoint
    @contents.adjustBounds()
  
  
  # ScrollFrameMorph scrolling by dragging:
  scrollX: (steps) ->
    cl = @contents.left()
    l = @left()
    cw = @contents.width()
    r = @right()
    newX = cl + steps
    newX = r - cw  if newX + cw < r
    newX = l  if newX > l
    @contents.setLeft newX  if newX isnt cl
  
  scrollY: (steps) ->
    ct = @contents.top()
    t = @top()
    ch = @contents.height()
    b = @bottom()
    newY = ct + steps
    if newY + ch < b
      newY = b - ch
    # prevents content to be scrolled to the frame's
    # bottom if the content is otherwise empty
    newY = t  if newY > t
    @contents.setTop newY  if newY isnt ct
  
  mouseDownLeft: (pos) ->
    return null  unless @isScrollingByDragging
    world = @root()
    oldPos = pos
    deltaX = 0
    deltaY = 0
    friction = 0.8
    @step = =>
      if world.hand.mouseButton and
        (!world.hand.children.length) and
        (@bounds.containsPoint(world.hand.position()))
          newPos = world.hand.bounds.origin
          deltaX = newPos.x - oldPos.x
          @scrollX deltaX  if deltaX isnt 0
          deltaY = newPos.y - oldPos.y
          @scrollY deltaY  if deltaY isnt 0
          oldPos = newPos
      else
        unless @hasVelocity
          @step = noOperation
        else
          if (Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5)
            @step = noOperation
          else
            deltaX = deltaX * friction
            @scrollX Math.round(deltaX)
            deltaY = deltaY * friction
            @scrollY Math.round(deltaY)
      @adjustScrollBars()
  
  startAutoScrolling: ->
    inset = WorldMorph.MorphicPreferences.scrollBarSize * 3
    world = @world()
    return null  unless world
    hand = world.hand
    @autoScrollTrigger = Date.now()  unless @autoScrollTrigger
    @step = =>
      pos = hand.bounds.origin
      inner = @bounds.insetBy(inset)
      if (@bounds.containsPoint(pos)) and
        (not (inner.containsPoint(pos))) and
        (hand.children.length)
          @autoScroll pos
      else
        @step = noOperation
        @autoScrollTrigger = null
  
  autoScroll: (pos) ->
    return null  if Date.now() - @autoScrollTrigger < 500
    inset = WorldMorph.MorphicPreferences.scrollBarSize * 3
    area = @topLeft().extent(new Point(@width(), inset))
    @scrollY inset - (pos.y - @top())  if area.containsPoint(pos)
    area = @topLeft().extent(new Point(inset, @height()))
    @scrollX inset - (pos.x - @left())  if area.containsPoint(pos)
    area = (new Point(@right() - inset, @top())).extent(new Point(inset, @height()))
    @scrollX -(inset - (@right() - pos.x))  if area.containsPoint(pos)
    area = (new Point(@left(), @bottom() - inset)).extent(new Point(@width(), inset))
    @scrollY -(inset - (@bottom() - pos.y))  if area.containsPoint(pos)
    @adjustScrollBars()  
  
  # ScrollFrameMorph scrolling by editing text:
  scrollCaretIntoView: (morph) ->
    txt = morph.target
    offset = txt.position().subtract(@contents.position())
    ft = @top() + @padding
    fb = @bottom() - @padding
    @contents.setExtent txt.extent().add(offset).add(@padding)
    if morph.top() < ft
      @contents.setTop @contents.top() + ft - morph.top()
      morph.setTop ft
    else if morph.bottom() > fb
      @contents.setBottom @contents.bottom() + fb - morph.bottom()
      morph.setBottom fb
    @adjustScrollBars()

  # ScrollFrameMorph events:
  mouseScroll: (y, x) ->
    @scrollY y * WorldMorph.MorphicPreferences.mouseScrollAmount  if y
    @scrollX x * WorldMorph.MorphicPreferences.mouseScrollAmount  if x
    @adjustScrollBars()
  
  copyRecordingReferences: (dict) ->
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
  
  developersMenu: ->
    menu = super()
    if @isTextLineWrapping
      menu.addItem "auto line wrap off...", "toggleTextLineWrapping", "turn automatic\nline wrapping\noff"
    else
      menu.addItem "auto line wrap on...", "toggleTextLineWrapping", "enable automatic\nline wrapping"
    menu
  
  toggleTextLineWrapping: ->
    @isTextLineWrapping = not @isTextLineWrapping
