class ScrollPanelWdgt extends PanelWdgt

  autoScrollTrigger: nil
  hasVelocity: true # dto.
  padding: 0 # around the scrollable area
  isTextLineWrapping: false
  isScrollingByfloatDragging: true
  scrollBarsThickness: nil
  contents: nil
  vBar: nil
  hBar: nil
  # used to avoid recursively re-entering the
  # adjustContentsBounds function
  _adjustingContentsBounds: false

  # there are several ways in which we allow
  # scrolling when a ScrollPanel is scrollable
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
    # super() paints the ScrollPanel, which we don't want,
    # so we set 0 opacity here.
    @alpha = 0
    super()

    @contents = new PanelWdgt @ unless @contents?
    @addRaw @contents

    # the ScrollPanel is never going to paint itself,
    # but its values are going to mimick the values of the
    # contained Panel
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

  wantsDropOf: (aWdgt) ->
    if @contents instanceof FolderPanelWdgt
      return false
    return @_acceptsDrops

  colloquialName: ->
    if @contents instanceof FolderPanelWdgt
      "folder"
    else if @contents instanceof ToolPanelWdgt
      "toolbar"
    else
      "scrollable panel"

  adjustContentsBasedOnHBar: (num) ->
    @contents.fullRawMoveTo new Point @left() - num, @contents.position().y
    @adjustContentsBounds()
    @adjustScrollBars()

  adjustContentsBasedOnVBar: (num) ->
    @contents.fullRawMoveTo new Point @contents.position().x, @top() - num
    @adjustContentsBounds()
    @adjustScrollBars()

  setColor: (aColorOrAMorphGivingAColor, morphGivingColor, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken

    aColor = super aColorOrAMorphGivingAColor, morphGivingColor, connectionsCalculationToken, true
    # keep in synch the color of the content.
    # Note that the container ScrollPanel.
    # is actually not painted.
    @contents.setColor aColorOrAMorphGivingAColor, morphGivingColor, connectionsCalculationToken
    return aColor

  setAlphaScaled: (alphaOrMorphGivingAlpha, morphGivingAlpha) ->
    alpha = super
    # update the alpha of the ScrollPanel - note
    # that we are never going to paint the ScrollPanel
    # we are updating the alpha so that its value is the same as the
    # contained Panel
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
    # ScrollPanel. The reason why the bar could belong to another
    # ScrollPanel is the following: the bar could have been detached
    # from a ScrollPanel A. The ScrollPanel A (which is still fully
    # working albeit detached) is then duplicated into
    # a ScrollPanel B. What happens is that because the bar is not
    # a child of A (rather, it's only referenced as a property),
    # the duplication mechanism does not duplicate the bar and it does
    # not update the reference to it. This is correct because one cannot
    # just change all the references to other objects that are not children
    # , a good example being the targets, i.e. if you duplicate a colorPicker
    # which targets a Widget you want the duplication of the colorPicker to
    # still change color of that same Widget.
    # So: the ScrollPanel B could still reference the scrollbar
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
        # ScrollPanel, otherwise we don't move it.
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
        # ScrollPanel, otherwise we don't move it.
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
  # end up in the Panel inside it.
  # This would also apply to resizing handles - so we need to
  # correct for that case
  add: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->
    # TODO this check below should probably just be testing if layoutSpec
    # is a corner or edge internal layout
    if aWdgt instanceof ModifiedTextTriangleAnnotationWdgt or aWdgt instanceof HandleMorph
      super
    else
      @contents.add aWdgt, position, layoutSpec, beingDropped, nil, positionOnScreen
      @adjustContentsBounds()
      @adjustScrollBars()

  # see SimpleSlideWdgt for performance improvements
  # of this over the non-
  addMany: (widgetsToBeAdded) ->
    @contents.addMany widgetsToBeAdded
    @adjustContentsBounds()
    @adjustScrollBars()


  showResizeAndMoveHandlesAndLayoutAdjusters: ->
    super
    @adjustContentsBounds()
    @adjustScrollBars()

  
  setContents: (aWdgt, extraPadding) ->
    @extraPadding = extraPadding
    # there should never be a shadow but one never knows...
    @contents.closeChildren()
    @contents.fullRawMoveTo @position()

    aWdgt.fullRawMoveTo @position().add @padding + @extraPadding

    @add aWdgt


  rawSetExtent: (aPoint) ->
    unless aPoint.equals @extent()
      #console.log "move 15"
      @breakNumberOfRawMovesAndResizesCaches()

      # TODO this part seems like it should be in a doLayout function
      # rather than here
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
    # avoid recursively re-entering this function
    if @_adjustingContentsBounds then return else @_adjustingContentsBounds = true

    # if PanelWdgt is of type isTextLineWrapping
    # it means that you don't want the TextMorph to
    # extend indefinitely as you are typing. Rather,
    # the width will be constrained and the text will
    # wrap.
    padding = Math.floor @extraPadding + @padding
    totalPadding = 2*padding

    if @contents instanceof SimpleVerticalStackPanelWdgt
      @contents.adjustContentsBounds()
    else if @isTextLineWrapping and @contents instanceof PanelWdgt
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

      # add-in the content's own external padding
      if @contents.externalPadding?
        subBounds = subBounds.expandBy @contents.externalPadding

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
      if @isTextLineWrapping or
       (@ instanceof SimplePlainTextScrollPanelWdgt) or
       (@ instanceof SimpleVerticalStackScrollPanelWdgt)
        newBounds = subBounds.expandBy(padding).ceil()

        # ok so this is tricky: say that you have a document with
        # ONLY a centered icon in it.
        # If you don't add this line, the subBounds will start at the
        # origin of the icon, which is NOT aligned to the left of the
        # viewport. So what will happen is that the panel will be moved
        # so its left will coincide with the left of the viewport.
        # So the icon will appear non-centered.
        newBounds = newBounds.merge new Rectangle @contents.left(), @contents.top(), @contents.left() + @width(), @contents.top() + 1

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

    unless @contents.boundingBox().equals newBounds
      @contents.silentRawSetBounds newBounds
      @contents.reLayout()
    
    # you'd think that if @contents.boundingBox().equals newBounds
    # then we don't need to check if the contents are "in good view"
    # but actually for example a stack resizes itself automatically when the
    # elements are resized (in the foreach loop above),
    # so we need anyways to do this check and fix the view if the
    # case. The good news is that it's a cheap check to do in case
    # there is nothing to do.
    @keepContentsInScrollPanelWdgt()
    @_adjustingContentsBounds = false

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

  scrollTo: (whereTo) ->
    @contents.fullRawMoveLeftSideTo -whereTo.x
    @contents.fullRawMoveTopSideTo -whereTo.y
    @adjustScrollBars()    


  scrollToBottom: ->
    @scrollY -100000
    @adjustScrollBars()    
  
  scrollY: (steps) ->
    ct = @contents.top()
    t = @top()
    ch = @contents.height()
    b = @bottom()
    newY = ct + steps
    if newY + ch < b
      newY = b - ch
    # prevents content to be scrolled to the Panel's
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
  
  # sometimes you can scroll the contents of a ScrollPanel
  # by floatDragging its contents. This is particularly
  # useful in touch devices.
  # You can test this also in non-touch mode
  # by anchoring a ScrollPanel to something
  # non-draggable such as a color palette (can't drag it
  # because user can drag on it to pick a color)
  # Ten you chuck a long text into the ScrollPanel and
  # drag the Panel (on the side of the text, where there is no
  # text) and you should see the ScrollPanel scrolling.
  mouseDownLeft: (pos) ->

    return nil  unless @isScrollingByfloatDragging

    oldPos = pos
    deltaX = 0
    deltaY = 0
    friction = 0.8
    world.steppingWdgts.add @
    @step = =>
      scrollbarJustChanged = false
      if world.hand.mouseButton and
        !world.hand.isThisPointerFloatDraggingSomething() and
        # if the Widget at hand is float draggable then
        # we are probably about to detach it, so
        # we shouldn't move anything, because user might
        # just float-drag the morph as soon as the threshold is
        # reached, and we don't want to scroll until that happens
        # that would be strange because it would be giving the
        # wrong cue to the user, we just want to hold steady
        !world.hand.wdgtToGrab?.detachesWhenDragged() and
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
          world.steppingWdgts.delete @
        else
          if (Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5)
            @step = noOperation
            world.steppingWdgts.delete @
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
    world.steppingWdgts.add @
    @step = =>
      pos = hand.position()
      inner = @boundingBox().insetBy inset
      if @boundsContainPoint(pos) and
        !inner.containsPoint(pos) and
        hand.isThisPointerFloatDraggingSomething()
          @autoScroll pos
      else
        @step = noOperation
        world.steppingWdgts.delete @
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

  # ScrollPanelWdgt events.
  wheel: (xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg) ->

    x = xArg
    y = yArg
    z = zArg

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
    # unused
    if WorldMorph.preferencesAndSettings.invertWheelZ
      z *= -1

    if y != 0
      # TODO this escalation should also
      # be implemented in the touch case... user could scroll
      # WITHOUT wheel, by just touch-dragging the contents...
      #
      # Escalate the scroll in case we are in a nested
      # ScrollPanel situation and we already
      # scrolled this inner one "up/down to the end".
      # In such case, the outer one has to scroll...
      #
      # if scrolling up and the content top is already below the top (or just a little above the top)
      #  OR
      # if scrolling down and the content bottom is already above the bottom (or just a little below the bottom)
      #  THEN
      # escalate the method up, since there might be another scrollbar catching it
      #
      # The "just a little" caveats are because sometimes dimensions are non-integer
      # (TODO ...which shouldn't really happen)
      #
      if (y > 0 and @contents.top() >= (@top() - 1)) or
       (y < 0 and @contents.bottom() <= (@bottom() + 1))
        @escalateEvent 'wheel', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
      else
        scrollbarJustChanged = true
        @scrollY y * WorldMorph.preferencesAndSettings.wheelScaleY
    if x != 0
      # similar to the vertical case, escalate the scroll in case
      # we are in a nested ScrollPanel situation
      if (x > 0 and @contents.left() >= (@left()-1)) or
       (x < 0 and @contents.right() <= (@right()+1) )
        @escalateEvent 'wheel', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
      else
        scrollbarJustChanged = true
        @scrollX x * WorldMorph.preferencesAndSettings.wheelScaleX

    if scrollbarJustChanged
      @adjustContentsBounds()
      @adjustScrollBars()
  

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    if @takesOverAndCoalescesChildrensMenus
      if @contents
        childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents
      if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length == 1
        childrenNotHandlesNorCarets[0].addMorphSpecificMenuEntries morphOpeningThePopUp, menu
    else
      super
  
  # »>> this part is excluded from the fizzygum homepage build
  # unused code
  toggleTextLineWrapping: ->
    @isTextLineWrapping = not @isTextLineWrapping
  # this part is excluded from the fizzygum homepage build <<«

  enableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.makePencilYellow?()

    @enableDrops()
    @dragsDropsAndEditingEnabled = true

    @contents.enableDragsDropsAndEditing @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.makePencilClear?()

    @disableDrops()
    @dragsDropsAndEditingEnabled = false

    @contents.disableDragsDropsAndEditing @
    @invalidateLayout()

