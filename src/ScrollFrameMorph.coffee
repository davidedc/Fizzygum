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

  constructor: (@contents, scrollBarSize, @sliderColor) ->
    # super() paints the scrollframe, which we don't want,
    # so we set 0 opacity here.
    @alpha = 0
    super()
    @scrollBarSize = scrollBarSize or WorldMorph.preferencesAndSettings.scrollBarSize

    @contents = new FrameMorph(@) unless @contents?
    @add @contents

    # the scrollFrame is never going to paint itself,
    # but its values are going to mimick the values of the
    # contained frame
    @color = @contents.color
    @alpha = @contents.alpha
    
    #@setColor = @contents.setColor
    #@setAlphaScaled = @contents.setAlphaScaled

    @hBar = new SliderMorph(null, null, null, null, "horizontal", @sliderColor)
    @hBar.setHeight @scrollBarSize

    @hBar.isDraggable = false
    @hBar.target = @
    @add @hBar

    @vBar = new SliderMorph(null, null, null, null, "vertical", @sliderColor)
    @vBar.setWidth @scrollBarSize
    @vBar.isDraggable = false
    @vBar.target = @
    @add @vBar

    @hBar.action = (num, target) =>
      target.contents.setPosition new Point(target.left() - num, target.contents.position().y)
      target.contents.adjustBounds()
    @vBar.action = (num, target) =>
      target.contents.setPosition new Point(target.contents.position().x, target.top() - num)
      target.contents.adjustBounds()
    @adjustScrollBars()

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

    # this check is to see whether the bar actually belongs to this
    # scrollframe. The reason why the bar could belong to another
    # scrollframe is the following: the bar could have been detached
    # from a scrollframe A. The scrollframe A (which is still fully
    # working albeit detached) is then duplicated into
    # a scrollframe B. What happens is that because the bar is not
    # a child of A (rather, it's only referenced as a property),
    # the duplication mechanism does not duplicate the bar and it does
    # not update the reference to it. This is correct because one cannot
    # just change all the references to other objects that are not children
    # , a good example being the targets, i.e. if you duplicate a colorPicker
    # which targets a Morph you want the duplication of the colorPicker to
    # still change color of that same Morph.
    # So: the scrollframe B could still reference the scrollbar
    # detached from A and that causes a problem because changes to B would
    # change the dimensions and hiding/unhiding of the scrollbar.
    # So here we avoid that by actually checking what the scrollbar is
    # attached to.
    if @hBar.target == @ 
      if @contents.width() >= @width() + 1
        @hBar.show()
        @hBar.setWidth hWidth  if @hBar.width() isnt hWidth
        # we check whether the bar has been detached. If it's still
        # attached then we possibly move it, together with the
        # scrollframe, otherwise we don't move it.
        if @hBar.parent == @
          @hBar.setPosition new Point(@left(), @bottom() - @hBar.height())
        @hBar.start = 0
        @hBar.stop = @contents.width() - @width()
        @hBar.size = @width() / @contents.width() * @hBar.stop
        @hBar.value = @left() - @contents.left()
        @hBar.updateRange()
      else
        @hBar.hide()

    # see comment on equivalent if line above.
    if @vBar.target == @ 
      if @contents.height() >= @height() + 1
        @vBar.show()
        @vBar.setHeight vHeight  if @vBar.height() isnt vHeight
        # we check whether the bar has been detached. If it's still
        # attached then we possibly move it, together with the
        # scrollframe, otherwise we don't move it.
        if @vBar.parent == @
          @vBar.setPosition new Point(@right() - @vBar.width(), @top())
        @vBar.start = 0
        @vBar.stop = @contents.height() - @height()
        @vBar.size = @height() / @contents.height() * @vBar.stop
        @vBar.value = @top() - @contents.top()
        @vBar.updateRange()
      else
        @vBar.hide()
  
  addContents: (aMorph) ->
    @contents.add aMorph
    @contents.adjustBounds()
    @adjustScrollBars()
  
  setContents: (aMorph, extraPadding) ->
    @extraPadding = extraPadding
    @contents.destroyAll()
    #
    @contents.children = []
    aMorph.setPosition @position().add(@padding + @extraPadding)
    @addContents aMorph
  
  setExtent: (aPoint) ->
    @contents.setPosition @position().copy()  if @isTextLineWrapping
    super aPoint
    @contents.adjustBounds()
    @adjustScrollBars()
  
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
          if @hBar.isVisible
            deltaX = newPos.x - oldPos.x
            @scrollX deltaX  if deltaX isnt 0
          if @vBar.isVisible
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
            if @hBar.isVisible
              deltaX = deltaX * friction
              @scrollX Math.round(deltaX)
            if @vBar.isVisible
              deltaY = deltaY * friction
              @scrollY Math.round(deltaY)
      #console.log "adjusting..."
      @contents.adjustBounds()
      @adjustScrollBars()
  
  startAutoScrolling: ->
    inset = WorldMorph.preferencesAndSettings.scrollBarSize * 3
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
    inset = WorldMorph.preferencesAndSettings.scrollBarSize * 3
    area = @topLeft().extent(new Point(@width(), inset))
    @scrollY inset - (pos.y - @top())  if area.containsPoint(pos)
    area = @topLeft().extent(new Point(inset, @height()))
    @scrollX inset - (pos.x - @left())  if area.containsPoint(pos)
    area = (new Point(@right() - inset, @top())).extent(new Point(inset, @height()))
    @scrollX -(inset - (@right() - pos.x))  if area.containsPoint(pos)
    area = (new Point(@left(), @bottom() - inset)).extent(new Point(@width(), inset))
    @scrollY -(inset - (@bottom() - pos.y))  if area.containsPoint(pos)
    @contents.adjustBounds()
    @adjustScrollBars()  
  
  # ScrollFrameMorph scrolling when editing text
  # so to bring the caret fully into view.
  scrollCaretIntoView: (caretMorph) ->
    txt = caretMorph.target
    offset = txt.position().subtract(@contents.position())
    ft = @top() + @padding
    fb = @bottom() - @padding
    fl = @left() + @padding
    fr = @right() - @padding
    @contents.adjustBounds()
    if caretMorph.top() < ft
      @contents.setTop @contents.top() + ft - caretMorph.top()
      caretMorph.setTop ft
    else if caretMorph.bottom() > fb
      @contents.setBottom @contents.bottom() + fb - caretMorph.bottom()
      caretMorph.setBottom fb
    if caretMorph.left() < fl
      @contents.setLeft @contents.left() + fl - caretMorph.left()
      caretMorph.setLeft fl
    else if caretMorph.right() > fr
      @contents.setRight @contents.right() + fr - caretMorph.right()
      caretMorph.setRight fr
    @contents.adjustBounds()
    @adjustScrollBars()

  # ScrollFrameMorph events:
  mouseScroll: (y, x) ->
    @scrollY y * WorldMorph.preferencesAndSettings.mouseScrollAmount  if y
    @scrollX x * WorldMorph.preferencesAndSettings.mouseScrollAmount  if x
    @contents.adjustBounds()
    @adjustScrollBars()
  
  
  developersMenu: ->
    menu = super()
    if @isTextLineWrapping
      menu.addItem "auto line wrap off...", (->@toggleTextLineWrapping()), "turn automatic\nline wrapping\noff"
    else
      menu.addItem "auto line wrap on...", (->@toggleTextLineWrapping()), "enable automatic\nline wrapping"
    menu
  
  toggleTextLineWrapping: ->
    @isTextLineWrapping = not @isTextLineWrapping
