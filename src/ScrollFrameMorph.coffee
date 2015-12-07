# ScrollFrameMorph ////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

class ScrollFrameMorph extends FrameMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  autoScrollTrigger: null
  hasVelocity: true # dto.
  padding: 0 # around the scrollable area
  growth: 0 # pixels or Point to grow right/left when near edge
  isTextLineWrapping: false
  isScrollingByfloatDragging: true
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

    @hBar.isfloatDraggable = false
    @hBar.target = @
    @add @hBar

    @vBar = new SliderMorph(null, null, null, null, "vertical", @sliderColor)
    @vBar.setWidth @scrollBarSize
    @vBar.isfloatDraggable = false
    @vBar.target = @
    @add @vBar

    @hBar.target = @
    @hBar.action = "adjustContentsBasedOnHBar"
    @vBar.target = @
    @vBar.action = "adjustContentsBasedOnVBar"

    @adjustScrollBars()

  adjustContentsBasedOnHBar: (num) ->
    @contents.fullRawMoveTo new Point(@left() - num, @contents.position().y)
    @adjustContentsBounds()
    @adjustScrollBars()

  adjustContentsBasedOnVBar: (num) ->
    @contents.fullRawMoveTo new Point(@contents.position().x, @top() - num)
    @adjustContentsBounds()
    @adjustScrollBars()

  setColor: (aColorOrAMorphGivingAColor, morphGivingColor) ->
    aColor = super(aColorOrAMorphGivingAColor, morphGivingColor)
    # keep in synch the color of the content.
    # Note that the container scrollFrame.
    # is actually not painted.
    @contents.setColor aColorOrAMorphGivingAColor, morphGivingColor
    return aColor

  setAlphaScaled: (alphaOrMorphGivingAlpha, morphGivingAlpha) ->
    debugger
    alpha = super(alphaOrMorphGivingAlpha, morphGivingAlpha)
    # update the alpha of the scrollFrame - note
    # that we are never going to paint the scrollFrame
    # we are updating the alpha so that its value is the same as the
    # contained frame
    @contents.setAlphaScaled alphaOrMorphGivingAlpha, morphGivingAlpha
    return alpha

  adjustScrollBars: ->
    hWidth = @width() - @scrollBarSize
    vHeight = @height() - @scrollBarSize
    unless @parent instanceof ListMorph
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
          @hBar.fullRawMoveTo new Point(@left(), @bottom() - @hBar.height())
        stopValue = @contents.width() - @width()
        @hBar.updateSpecs(
          0, # start
          stopValue, # stop
          @left() - @contents.left(), # value
          @width() / @contents.width() * stopValue # size
        )
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
          @vBar.fullRawMoveTo new Point(@right() - @vBar.width(), @top())
        stopValue = @contents.height() - @height()
        @vBar.updateSpecs(
          0, # start
          stopValue, # stop
          @top() - @contents.top(), # value
          @height() / @contents.height() * stopValue # size
        )
      else
        @vBar.hide()
  
  addContents: (aMorph) ->
    @contents.add aMorph
    @adjustContentsBounds()
    @adjustScrollBars()
  
  setContents: (aMorph, extraPadding) ->
    @extraPadding = extraPadding
    @contents.fullDestroyChildren()

    aMorph.fullRawMoveTo @position().add(@padding + @extraPadding)
    @addContents aMorph
  
  setExtent: (aPoint) ->
    #console.log "move 15"
    @breakNumberOfRawMovesAndResizesCaches()
    @contents.fullRawMoveTo @position()  if @isTextLineWrapping
    super aPoint
    @contents.setExtent(aPoint)
    @adjustContentsBounds()
    @adjustScrollBars()


  reactToDropOf: ->
    @adjustContentsBounds()
    @adjustScrollBars()
  
  reactToGrabOf: ->
    @adjustContentsBounds()
    @adjustScrollBars()

  adjustContentsBounds: ->
    # if FrameMorph is of type isTextLineWrapping
    # it means that you don't want the TextMorph to
    # extend indefinitely as you are typing. Rather,
    # the width will be constrained and the text will
    # wrap.
    if @isTextLineWrapping
      @contents.children.forEach (morph) =>
        if morph instanceof TextMorph
          totalPadding =  2*(@extraPadding + @padding)
          # this re-layouts the text to fit the width.
          # The new height of the TextMorph will then be used
          # to redraw the vertical slider.
          morph.maxWidth = 0
          morph.setWidth @contents.width() - totalPadding
          morph.maxWidth = @contents.width() - totalPadding
          @contents.setHeight Math.max(morph.height(), @height() - totalPadding)

    subBounds = @contents.subMorphsMergedFullBounds()
    if subBounds
      newBounds = subBounds.expandBy(@padding + @extraPadding).merge(@boundingBox())
    else
      newBounds = @boundingBox()

    unless @contents.boundingBox().eq(newBounds)
      @contents.silentSetBounds newBounds
      @contents.reLayout()
      
      @keepContentsInScrollFrame()

  keepContentsInScrollFrame: ->
    if @contents.left() > @left()
      @contents.fullRawMoveBy new Point(@left() - @contents.left(), 0)
    if @contents.right() < @right()
      @contents.fullRawMoveBy new Point(@right() - @contents.right(), 0)  
    if @contents.top() > @top()
      @contents.fullRawMoveBy new Point(0, @top() - @contents.top())  
    if @contents.bottom() < @bottom()
      @contents.fullRawMoveBy 0, new Point(@bottom() - @contents.bottom(), 0)
  
  # ScrollFrameMorph scrolling by floatDragging:
  scrollX: (steps) ->
    cl = @contents.left()
    l = @left()
    cw = @contents.width()
    r = @right()
    newX = cl + steps
    newX = r - cw  if newX + cw < r
    newX = l  if newX > l
    # return true if any movement of
    # the scrollbar button is
    # actually happening, otherwise
    # false. We use this to figure
    # out in some places whether
    # we need to trigger a bunch of
    # updates of the content and scrollbars
    # or not.
    if newX isnt cl
      @contents.fullRawMoveLeftSideTo newX
      return true
    else
      return false
  
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
    # return true if any movement of
    # the scrollbar button is
    # actually happening, otherwise
    # false. We use this to figure
    # out in some places whether
    # we need to trigger a bunch of
    # updates of the content and scrollbars
    # or not.
    if newY isnt ct
      @contents.fullRawMoveTopSideTo newY
      return true
    else
      return false
  
  # sometimes you can scroll the contents of a scrollframe
  # by floatDragging its contents. This is particularly
  # useful in touch devices.
  mouseDownLeft: (pos) ->
    return null  unless @isScrollingByfloatDragging
    oldPos = pos
    deltaX = 0
    deltaY = 0
    friction = 0.8
    @step = =>
      scrollbarJustChanged = false
      if world.hand.mouseButton and
        (!world.hand.floatDraggingSomething()) and
        (@boundsContainPoint(world.hand.position()))
          newPos = world.hand.position()
          if @hBar.visibleBasedOnIsVisibleProperty()
            deltaX = newPos.x - oldPos.x
            if deltaX isnt 0
              scrollbarJustChanged = scrollbarJustChanged || @scrollX deltaX
          if @vBar.visibleBasedOnIsVisibleProperty()
            deltaY = newPos.y - oldPos.y
            if deltaY isnt 0
              scrollbarJustChanged = scrollbarJustChanged || @scrollY deltaY
          oldPos = newPos
      else
        unless @hasVelocity
          @step = noOperation
        else
          if (Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5)
            @step = noOperation
          else
            if @hBar.visibleBasedOnIsVisibleProperty()
              deltaX = deltaX * friction
              if deltaX isnt 0
                scrollbarJustChanged = scrollbarJustChanged || @scrollX Math.round(deltaX)
            if @vBar.visibleBasedOnIsVisibleProperty()
              deltaY = deltaY * friction
              if deltaY isnt 0
                scrollbarJustChanged = scrollbarJustChanged || @scrollY Math.round(deltaY)
      if scrollbarJustChanged
        @adjustContentsBounds()
        @adjustScrollBars()
  
  startAutoScrolling: ->
    inset = WorldMorph.preferencesAndSettings.scrollBarSize * 3
    if @isOrphan() then return null
    hand = world.hand
    @autoScrollTrigger = Date.now()  unless @autoScrollTrigger
    @step = =>
      pos = hand.position()
      inner = @boundingBox().insetBy(inset)
      if (@boundsContainPoint(pos)) and
        (not (inner.containsPoint(pos))) and
        (hand.floatDraggingSomething())
          @autoScroll pos
      else
        @step = noOperation
        @autoScrollTrigger = null
  
  autoScroll: (pos) ->
    return null  if Date.now() - @autoScrollTrigger < 500
    inset = WorldMorph.preferencesAndSettings.scrollBarSize * 3
    area = @topLeft().extent(new Point(@width(), inset))
    scrollbarJustChanged = false
    if area.containsPoint(pos)
      scrollbarJustChanged = scrollbarJustChanged ||
        @scrollY inset - (pos.y - @top())
    area = @topLeft().extent(new Point(inset, @height()))
    if area.containsPoint(pos)
      scrollbarJustChanged = scrollbarJustChanged ||
        @scrollX inset - (pos.x - @left())
    area = (new Point(@right() - inset, @top())).extent(new Point(inset, @height()))
    if area.containsPoint(pos)
      scrollbarJustChanged = scrollbarJustChanged ||
        @scrollX -(inset - (@right() - pos.x))
    area = (new Point(@left(), @bottom() - inset)).extent(new Point(@width(), inset))
    if area.containsPoint(pos)
      scrollbarJustChanged = scrollbarJustChanged ||
        @scrollY -(inset - (@bottom() - pos.y))
    if scrollbarJustChanged
      @adjustContentsBounds()
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
    @adjustContentsBounds()
    if caretMorph.top() < ft
      @contents.fullRawMoveTopSideTo @contents.top() + ft - caretMorph.top()
      caretMorph.fullRawMoveTopSideTo ft
    else if caretMorph.bottom() > fb
      @contents.fullMoveBottomSideTo @contents.bottom() + fb - caretMorph.bottom()
      caretMorph.fullMoveBottomSideTo fb
    if caretMorph.left() < fl
      @contents.fullRawMoveLeftSideTo @contents.left() + fl - caretMorph.left()
      caretMorph.fullRawMoveLeftSideTo fl
    else if caretMorph.right() > fr
      @contents.fullRawMoveRightSideTo @contents.right() + fr - caretMorph.right()
      caretMorph.fullRawMoveRightSideTo fr
    @adjustContentsBounds()
    @adjustScrollBars()

  # ScrollFrameMorph events:
  mouseScroll: (y, x) ->
    scrollbarJustChanged = false

    # this paragraph prevents too much
    # diagonal movement when the intention
    # is clearly to just move vertically or
    # horizontally. Doesn't need to be always
    # the case though.
    if Math.abs(y) < Math.abs(x)
      y = 0
    if Math.abs(x) < Math.abs(y)
      x = 0

    if y
      scrollbarJustChanged = true
      @scrollY y * WorldMorph.preferencesAndSettings.mouseScrollAmount
    if x
      scrollbarJustChanged = true
      @scrollX x * WorldMorph.preferencesAndSettings.mouseScrollAmount  
    if scrollbarJustChanged
      @adjustContentsBounds()
      @adjustScrollBars()
  
  
  developersMenu: ->
    menu = super()
    if @isTextLineWrapping
      menu.addItem "auto line wrap off...", true, @, "toggleTextLineWrapping", "turn automatic\nline wrapping\noff"
    else
      menu.addItem "auto line wrap on...", true, @, "toggleTextLineWrapping", "enable automatic\nline wrapping"
    menu
  
  toggleTextLineWrapping: ->
    @isTextLineWrapping = not @isTextLineWrapping
