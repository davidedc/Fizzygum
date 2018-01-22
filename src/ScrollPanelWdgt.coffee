# ScrollPanelWdgt ////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

class ScrollPanelWdgt extends PanelWdgt

  autoScrollTrigger: nil
  hasVelocity: true # dto.
  padding: 0 # around the scrollable area
  growth: 0 # pixels or Point to grow right/left when near edge
  isTextLineWrapping: false
  isScrollingByfloatDragging: true
  scrollBarsThickness: nil
  contents: nil
  vBar: nil
  hBar: nil

  # there are several ways in which we allow
  # scrolling when a scrollframe is scrollable
  # (i.e. the scrollbars are showing).
  # You can choose to scroll it by dragging the
  # contents or by dragging the background,
  # independently. Which could be useful for
  # example when showing a geographic map.
  canScrollByDraggingBackground: false
  canScrollByDraggingForeground: false

  constructor: (
    @contents,
    @scrollBarsThickness = (WorldMorph.preferencesAndSettings.scrollBarsThickness),
    @sliderColor
    ) ->
    # super() paints the scrollframe, which we don't want,
    # so we set 0 opacity here.
    @alpha = 0
    super()

    @contents = new PanelWdgt @ unless @contents?
    @addRaw @contents

    # the scrollFrame is never going to paint itself,
    # but its values are going to mimick the values of the
    # contained frame
    @color = @contents.color
    @alpha = @contents.alpha
    
    #@setColor = @contents.setColor
    #@setAlphaScaled = @contents.setAlphaScaled

    @hBar = new SliderMorph nil, nil, nil, nil, @sliderColor
    @hBar.rawSetHeight @scrollBarsThickness

    @hBar.target = @
    @addRaw @hBar

    @vBar = new SliderMorph nil, nil, nil, nil, @sliderColor
    @vBar.rawSetWidth @scrollBarsThickness
    @vBar.target = @
    @addRaw @vBar

    @hBar.target = @
    @hBar.action = "adjustContentsBasedOnHBar"
    @vBar.target = @
    @vBar.action = "adjustContentsBasedOnVBar"

    @adjustScrollBars()

  adjustContentsBasedOnHBar: (num) ->
    @contents.fullRawMoveTo new Point @left() - num, @contents.position().y
    @adjustContentsBounds()
    @adjustScrollBars()

  adjustContentsBasedOnVBar: (num) ->
    @contents.fullRawMoveTo new Point @contents.position().x, @top() - num
    @adjustContentsBounds()
    @adjustScrollBars()

  setColor: (aColorOrAMorphGivingAColor, morphGivingColor) ->
    aColor = super
    # keep in synch the color of the content.
    # Note that the container scrollFrame.
    # is actually not painted.
    @contents.setColor aColorOrAMorphGivingAColor, morphGivingColor
    return aColor

  setAlphaScaled: (alphaOrMorphGivingAlpha, morphGivingAlpha) ->
    alpha = super
    # update the alpha of the scrollFrame - note
    # that we are never going to paint the scrollFrame
    # we are updating the alpha so that its value is the same as the
    # contained frame
    @contents.setAlphaScaled alphaOrMorphGivingAlpha, morphGivingAlpha
    return alpha

  anyScrollBarShowing: ->
    if (@hBar.visibleBasedOnIsVisibleProperty() and !@hBar.isCollapsed()) or
    (@vBar.visibleBasedOnIsVisibleProperty() and !@vBar.isCollapsed())
      return true
    return false

  adjustScrollBars: ->
    # one typically has both scrollbars in view, plus a resizer
    # in buttom right corner, so adjust the width/height of the
    # scrollbars so that there is no overlap between the three things
    spaceToLeaveOnOneSide = Math.max(@scrollBarsThickness, WorldMorph.preferencesAndSettings.handleSize) + 2 * @padding
    hWidth = @width() - spaceToLeaveOnOneSide
    vHeight = @height() - spaceToLeaveOnOneSide

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
        @hBar.rawSetWidth hWidth  if @hBar.width() isnt hWidth
        # we check whether the bar has been detached. If it's still
        # attached then we possibly move it, together with the
        # scrollframe, otherwise we don't move it.
        if @hBar.parent == @
          @hBar.fullRawMoveTo new Point @left(), @bottom() - @hBar.height()
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
        @vBar.rawSetHeight vHeight  if @vBar.height() isnt vHeight
        # we check whether the bar has been detached. If it's still
        # attached then we possibly move it, together with the
        # scrollframe, otherwise we don't move it.
        if @vBar.parent == @
          @vBar.fullRawMoveTo new Point @right() - @vBar.width(), @top()
        stopValue = @contents.height() - @height()
        @vBar.updateSpecs(
          0, # start
          stopValue, # stop
          @top() - @contents.top(), # value
          @height() / @contents.height() * stopValue # size
        )
      else
        @vBar.hide()
  
  # when you add things to the ScrollPanelWdgt they actually
  # end up in the frame inside it. This also applies to
  # resizing handles!
  add: (aMorph) ->
    @contents.add aMorph
    @adjustContentsBounds()
    @adjustScrollBars()

  showResizeAndMoveHandlesAndLayoutAdjusters: ->
    super
    @adjustContentsBounds()
    @adjustScrollBars()

  # puts the morph in the scrollframe
  # in some sparse manner and keeping it
  # "in view"
  addInPseudoRandomPosition: (aMorph) ->
    @contents.add aMorph
    posx = Math.abs(hashCode(aMorph.toString())) % @width()
    posy = Math.abs(hashCode(aMorph.toString() + "x")) % @height()
    position = @contents.position().add new Point posx, posy
    aMorph.fullMoveTo position
    aMorph.fullRawMoveWithin @contents
    @adjustContentsBounds()
    @adjustScrollBars()
  
  
  setContents: (aMorph, extraPadding) ->
    @extraPadding = extraPadding
    # there should never be a shadow but one never knows...
    @contents.fullDestroyChildren()
    @contents.fullRawMoveTo @position()

    aMorph.fullRawMoveTo @position().add @padding + @extraPadding

    @add aMorph


  rawSetExtent: (aPoint) ->
    unless aPoint.eq @extent()
      #console.log "move 15"
      @breakNumberOfRawMovesAndResizesCaches()
      if @isTextLineWrapping and !(@contents instanceof SimpleVerticalStackPanelWdgt)
        @contents.fullRawMoveTo @position()
      super aPoint
      @contents.rawSetExtent aPoint
      @adjustContentsBounds()
      @adjustScrollBars()


  reactToDropOf: ->
    @adjustContentsBounds()
    @adjustScrollBars()
  
  reactToGrabOf: ->
    @adjustContentsBounds()
    @adjustScrollBars()

  adjustContentsBounds: ->
    # if PanelWdgt is of type isTextLineWrapping
    # it means that you don't want the TextMorph to
    # extend indefinitely as you are typing. Rather,
    # the width will be constrained and the text will
    # wrap.
    padding = Math.floor @extraPadding + @padding
    totalPadding = 2*padding

    if @isTextLineWrapping
      if @contents instanceof SimpleVerticalStackPanelWdgt
        @contents.adjustContentsBounds()
      else if @contents instanceof PanelWdgt
        @contents.children.forEach (morph) =>
          if (morph instanceof TextMorph) or (morph instanceof SimplePlainTextWdgt)
            # this re-layouts the text to fit the width.
            # The new height of the TextMorph will then be used
            # to redraw the vertical slider.
            morph.rawSetWidth @contents.width() - totalPadding
            # the SimplePlainTextWdgt just needs this to be different from null
            # while the TextMorph actually uses this number
            morph.maxTextWidth = @contents.width() - totalPadding
            @contents.rawSetHeight (Math.max morph.height(), @height()) - totalPadding

    subBounds = @contents.subMorphsMergedFullBounds()?.ceil()
    if subBounds
      # in case of a SimpleVerticalStackScrollPanelWdgt then we really
      # want to make sure that we don't stretch the view and the stack
      # after the end of the contents (this can happen for example
      # when you are completely scrolled to the bottom and remove a long
      # chunk of text at the bottom: you don't want the extra vacant space
      # to be in view, you want to shrink all that part up and reposition the
      # stack so you actually see a bottom that has something in it)
      # So we first size the stack according to the minimum area of the
      # components in it, then we add the minimum space needed to fill
      # the viewport, so we never end up with empty space filling the stack
      # beyond the height of the viewport.
      if @isTextLineWrapping or (@ instanceof SimplePlainTextScrollPanelWdgt)
        newBounds = subBounds.expandBy(padding)?.ceil()

        # ok so this is tricky: say that you have a document with
        # ONLY a centered icon in it.
        # If you don't add this line, the subBounds will start at the
        # origin of the icon, which is NOT aligned to the left of the
        # viewport. So what will happen is that the panel will be moved
        # so its left will coincide with the left of the viewport.
        # So the icon will appear non-centered.
        newBounds = newBounds.merge new Rectangle @left(), @top(), @right(), @top() + 1

        if newBounds.height() < @height()
          newBounds = newBounds.growBy new Point 0, @height() - newBounds.height()
        # I don't think this check below is needed anymore,
        # TODO verify when there are a healthy number of tests around
        # vertical stack and text scroll panels
        if newBounds.width() < @width()
          newBounds = newBounds.growBy new Point @width() - newBounds.width(), 0
      else
        newBounds = subBounds.expandBy(padding).merge @boundingBox()?.ceil()
    else
      newBounds = @boundingBox()?.ceil()

    unless @contents.boundingBox().eq newBounds
      @contents.silentRawSetBounds newBounds
      @contents.reLayout()
    
    # you'd think that if @contents.boundingBox().eq newBounds
    # then we don't need to check if the contents are "in good view"
    # but actually for example a stack resizes itself automatically when the
    # elements are resized (in the foreach loop above),
    # so we need anyways to do this check and fix the view if the
    # case. The good news is that it's a cheap check to do in case
    # there is nothing to do.
    @keepContentsInScrollPanelWdgt()

  keepContentsInScrollPanelWdgt: ->
    if @contents.left() > @left()
      @contents.fullRawMoveBy new Point @left() - @contents.left(), 0
    if @contents.right() < @right()
      @contents.fullRawMoveBy new Point @right() - @contents.right(), 0
    if @contents.top() > @top()
      @contents.fullRawMoveBy new Point 0, @top() - @contents.top()
    if @contents.bottom() < @bottom()
      @contents.fullRawMoveBy new Point 0, @bottom() - @contents.bottom()
  
  # ScrollPanelWdgt scrolling by floatDragging:
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
  # You can test this also in non-touch mode
  # by anchoring a scrollframe to something
  # non-draggable such as a color palette (can't drag it
  # because user can drag on it to pick a color)
  # Ten you chuck a long text into the scrollframe and
  # drag the frame (on the side of the text, where there is no
  # text) and you should see the scrollframe scrolling.
  mouseDownLeft: (pos) ->

    return nil  unless @isScrollingByfloatDragging

    oldPos = pos
    deltaX = 0
    deltaY = 0
    friction = 0.8
    world.addSteppingMorph @
    @step = =>
      scrollbarJustChanged = false
      if world.hand.mouseButton and
        !world.hand.floatDraggingSomething() and
        # if the Morph at hand is float draggable then
        # we are probably about to detach it, so
        # we shouldn't move anything, because user might
        # just float-drag the morph as soon as the threshold is
        # reached, and we don't want to scroll until that happens
        # that would be strange because it would be giving the
        # wrong cue to the user, we just want to hold steady
        !world.hand.morphToGrab.detachesWhenDragged() and
        @boundsContainPoint(world.hand.position())
          newPos = world.hand.position()
          if @hBar.visibleBasedOnIsVisibleProperty() and
          !@hBar.isCollapsed()
            deltaX = newPos.x - oldPos.x
            if deltaX isnt 0
              scrollbarJustChanged ||= @scrollX deltaX
          if @vBar.visibleBasedOnIsVisibleProperty() and
          !@vBar.isCollapsed()
            deltaY = newPos.y - oldPos.y
            if deltaY isnt 0
              scrollbarJustChanged ||= @scrollY deltaY
          oldPos = newPos
      else
        unless @hasVelocity
          @step = noOperation
          world.removeSteppingMorph @
        else
          if (Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5)
            @step = noOperation
            world.removeSteppingMorph @
          else
            if @hBar.visibleBasedOnIsVisibleProperty() and
            !@hBar.isCollapsed()
              deltaX = deltaX * friction
              if deltaX isnt 0
                scrollbarJustChanged ||= @scrollX Math.round deltaX
            if @vBar.visibleBasedOnIsVisibleProperty() and
            !@vBar.isCollapsed()
              deltaY = deltaY * friction
              if deltaY isnt 0
                scrollbarJustChanged ||= @scrollY Math.round deltaY
      if scrollbarJustChanged
        @adjustContentsBounds()
        @adjustScrollBars()
    super
  
  startAutoScrolling: ->
    inset = WorldMorph.preferencesAndSettings.scrollBarsThickness * 3
    if @isOrphan() then return nil
    hand = world.hand
    @autoScrollTrigger = Date.now()  unless @autoScrollTrigger
    world.addSteppingMorph @
    @step = =>
      pos = hand.position()
      inner = @boundingBox().insetBy inset
      if @boundsContainPoint(pos) and
        !inner.containsPoint(pos) and
        hand.floatDraggingSomething()
          @autoScroll pos
      else
        @step = noOperation
        world.removeSteppingMorph @
        @autoScrollTrigger = nil
  
  autoScroll: (pos) ->
    return nil  if Date.now() - @autoScrollTrigger < 500
    inset = WorldMorph.preferencesAndSettings.scrollBarsThickness * 3
    area = @topLeft().extent new Point @width(), inset
    scrollbarJustChanged = false
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @scrollY inset - (pos.y - @top())
    area = @topLeft().extent new Point inset, @height()
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @scrollX inset - (pos.x - @left())
    area = (new Point(@right() - inset, @top())).extent new Point inset, @height()
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @scrollX -(inset - (@right() - pos.x))
    area = (new Point(@left(), @bottom() - inset)).extent new Point @width(), inset
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @scrollY -(inset - (@bottom() - pos.y))
    if scrollbarJustChanged
      @adjustContentsBounds()
      @adjustScrollBars()  
  
  # ScrollPanelWdgt scrolling when editing text
  # so to bring the caret fully into view.
  scrollCaretIntoView: (caretMorph) ->
    txt = caretMorph.target
    offset = txt.position().subtract @contents.position()
    ft = @top() + @padding
    fb = @bottom() - @padding
    fl = @left() + @padding
    fr = @right() - @padding
    @adjustContentsBounds()
    marginAroundCaret = @padding
    if @extraPadding?
      marginAroundCaret += @extraPadding
    if caretMorph.top() < ft
      newT = @contents.top() + ft - caretMorph.top()
      @contents.fullRawMoveTopSideTo newT + marginAroundCaret
      caretMorph.fullRawMoveTopSideTo ft
    else if caretMorph.bottom() > fb
      newB = @contents.bottom() + fb - caretMorph.bottom()
      @contents.fullRawMoveBottomSideTo newB - marginAroundCaret
      caretMorph.fullRawMoveBottomSideTo fb
    if caretMorph.left() < fl
      newL = @contents.left() + fl - caretMorph.left()
      @contents.fullRawMoveLeftSideTo newL + marginAroundCaret
      caretMorph.fullRawMoveLeftSideTo fl
    else if caretMorph.right() > fr
      newR = @contents.right() + fr - caretMorph.right()
      @contents.fullRawMoveRightSideTo newR - marginAroundCaret
      caretMorph.fullRawMoveRightSideTo fr
    @adjustContentsBounds()
    @adjustScrollBars()

  # ScrollPanelWdgt events:
  wheel: (x, y, z, altKey, button, buttons) ->

    # if we don't destroy the resizing handles,
    # they'll follow the contents being moved!
    world.hand.destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem @

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

    if WorldMorph.preferencesAndSettings.invertWheelX
      x *= -1
    if WorldMorph.preferencesAndSettings.invertWheelY
      y *= -1
    if WorldMorph.preferencesAndSettings.invertWheelZ
      z *= -1

    if y != 0
      scrollbarJustChanged = true
      @scrollY y * WorldMorph.preferencesAndSettings.wheelScaleY
    if x != 0
      scrollbarJustChanged = true
      @scrollX x * WorldMorph.preferencesAndSettings.wheelScaleX

    if scrollbarJustChanged
      @adjustContentsBounds()
      @adjustScrollBars()
  

  addMorphSpecificMenuEntries: (morphOpeningTheMenu, menu) ->
    if @takesOverAndCoalescesChildrensMenus
      childrenNotHandlesNorCarets = @contents?.children.filter (m) ->
        !((m instanceof HandleMorph) or (m instanceof CaretMorph))
      if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length == 1
        childrenNotHandlesNorCarets[0].addMorphSpecificMenuEntries morphOpeningTheMenu, menu
    else
      super
  
  toggleTextLineWrapping: ->
    @isTextLineWrapping = not @isTextLineWrapping
