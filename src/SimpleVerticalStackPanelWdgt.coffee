class SimpleVerticalStackPanelWdgt extends Widget

  # stacks don't necessarily enforce a width on contents
  # so the contents could stick out, so we clip at the bounds
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  _acceptsDrops: true
  tight: true
  constrainContentWidth: true
  # used to avoid recursively re-entering the
  # _positionAndResizeChildren function
  _adjustingContentsBounds: false

  colloquialName: ->
    "stack"

  add: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->
    aWdgt.rawResizeToWithoutSpacing()

    # find out WHERE to add the widget. Find the existing widget in the
    # stack that is at the same height, and put the new
    # widget after it

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    # The vertical stack just lays down
    # the children in the exact sibling order, so all we have to do
    # is to count up to the child at the same height, say it's
    # child "n", then are going to add the new widget in position
    # "n+1".
    # (conveniently, "add" supports an argument to insert a widget
    # in a specific order among the siblings.)
    positionNumberAmongSiblings = nil
    if (childrenNotHandlesNorCarets.length > 0) and (positionOnScreen instanceof Point)
      positionNumberAmongSiblings = 0
      for w in childrenNotHandlesNorCarets
        positionNumberAmongSiblings++
        if w.top() < positionOnScreen.y and w.bottom() > positionOnScreen.y
          break

    if positionNumberAmongSiblings?
      super aWdgt, positionNumberAmongSiblings, layoutSpec, beingDropped
    else
      super

  constructor: (extent, color, @padding, @constrainContentWidth = true) ->
    super()
    @appearance = new RectangularAppearance @
    @silentRawSetExtent(extent) if extent?
    @color = color if color?

  # The re-fit chokepoint for a stack (no scrollbars): re-lay-out my stacked
  # contents. See Widget._reLayoutChildren.
  _reLayoutChildren: ->
    @_positionAndResizeChildren()

  # ===== Phase 3b (Slice 2): re-fit on the _reLayout cycle =====
  # Mirror of ScrollPanelWdgt's Slice-1 pair (see there). super applies my own bounds first
  # (DETERMINISM.md case-3c), then I re-lay-out my stacked contents. Inherited by WindowWdgt.
  # This is a fixed point ONLY because _positionAndResizeChildren sizes its (deferred-layout)
  # children via rawSetWidthSizeHeightAccordingly, which -- when called during a layout pass --
  # settles them in place (synchronous _reLayout, no invalidate-climb); see that method + the
  # design doc's "Phase 3b -- Slice 2".
  # implementsDeferredLayout pinned false so adding this _reLayout doesn't flip the two read
  # sites (rawSetWidthSizeHeightAccordingly invalidate + subWidgetsMergedFullBounds).
  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  implementsDeferredLayout: ->
    false

  # When my membership changes, tell my container its contained panel changed.
  # If the container absorbs that (a scroll panel re-fits me + its scrollbars,
  # returning true), I'm done; otherwise I re-lay-out myself. This is the
  # polymorphic replacement for `if @amIPanelOfScrollPanelWdgt()` -- the stack
  # no longer asks where it sits in the scroll structure; it just notifies, and
  # only a (non-List) scroll panel reacts. See
  # ScrollPanelWdgt._reLayOutAfterContainedPanelChange.
  # Membership-change re-fit. The absorb query (_reLayOutAfterContainedPanelChange) STAYS synchronous --
  # its truthy answer decides whether I skip my own re-fit (return-value contract). If not absorbed, my
  # own re-fit DEFERS to the cycle (else arm; my _reLayout is 'super; @_reLayoutChildren'). These run
  # outside a pass (drop gesture / destroy / add-flush re-parent -- where invalidate is legal); the
  # in-pass arm keeps the synchronous re-fit. (fam 2 -- deferred-layout-residuals-audit.md)
  childRemoved: ->
    return if @parent?._reLayOutAfterContainedPanelChange?()
    if world?._recalculatingLayouts
      # layout-apply-sanctioned: seam in-pass arm (runs under _recalculatingLayouts)
      @_reLayoutChildren()
    else
      @invalidateLayout()

  reactToDropOf: ->
    return if @parent?._reLayOutAfterContainedPanelChange?()
    if world?._recalculatingLayouts
      # layout-apply-sanctioned: seam in-pass arm (runs under _recalculatingLayouts)
      @_reLayoutChildren()
    else
      @invalidateLayout()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  availableWidthForContents: ->
    @width() - 2 * @padding

  _positionAndResizeChildren: ->
    # avoid recursively re-entering this function
    if @_adjustingContentsBounds then return else @_adjustingContentsBounds = true
    @padding = 5

    stackHeight = 0
    verticalPadding = 0

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    childrenNotHandlesNorCarets.forEach (widget) =>
      if widget.layoutSpec != LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT
        widget.initialiseDefaultVerticalStackLayoutSpec()
        widget.layoutSpecDetails.rememberInitialDimensions widget, @
        widget.setLayoutSpec LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT

    childrenNotHandlesNorCarets.forEach (widget) =>
      verticalPadding += @padding

      if !@constrainContentWidth
        # if the stack doesn't constrain the positions of the
        # contents then it's much harder to right/left/center align
        # things, because for example imagine this case: you
        # remove an element from the stack. Now, something that was
        # centered ends up defining the new bounds of the Stack.
        # But hey, that shouldn't have happened because that element
        # was centered, so it could not possibly define the bounds...
        # So the determination of the bounds becomes rather more
        # complex, we are skipping that for the time being: if a stack
        # doesn't constrain the widths of the contents then everything in
        # it looks left-aligned
        leftPosition = @left() + @padding
      else
        recommendedElementWidth = widget.layoutSpecDetails.getWidthInStack()

        # this re-layouts each widget to fit the width. When this runs FROM _reLayout (on the
        # recalculateLayouts cycle) rawSetWidthSizeHeightAccordingly settles a deferred-layout
        # child IN PLACE (synchronous _reLayout, no invalidate-climb), so this
        # _positionAndResizeChildren is a fixed point -- see Widget.rawSetWidthSizeHeightAccordingly.
        widget.rawSetWidthSizeHeightAccordingly recommendedElementWidth

        # contained text that OPTED INTO FIT_BOX_TO_TEXT (a SimplePlainTextWdgt or a
        # bare TextWdgt put into that mode) fits its BOX to the TEXT: wrap to the
        # width set above, height follows the wrapped content. We RESPECT the mode
        # (so a FIT_TEXT_TO_BOX placeholder is left alone); reassert soft-wrap.
        if widget.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
          widget.softWrap = true

        if widget.layoutSpecDetails.alignment == 'right'
          leftPosition = @left() + @width() - @padding - recommendedElementWidth
        else if widget.layoutSpecDetails.alignment == 'center'
          leftPosition = @left() + Math.floor (@width() - recommendedElementWidth) / 2
        else
          # we hope here that  widget.layoutSpecDetails.alignment == 'left'
          leftPosition = @left() + @padding


      widget.fullRawMoveTo new Point leftPosition, @top() + verticalPadding + stackHeight
      stackHeight += widget.height()

    newHeight = stackHeight + verticalPadding + @padding

    if !@tight or childrenNotHandlesNorCarets.length == 0
      newHeight = Math.max newHeight, @height()

    @rawSetHeight newHeight
    @_adjustingContentsBounds = false

  rawSetExtent: (aPoint) ->
    unless aPoint.equals @extent()
      #console.log "move 15"
      @breakNumberOfRawMovesAndResizesCaches()
      super aPoint
      # raw setter: APPLY the re-fit NOW -- synchronous, single-container, TERMINAL
      # (_reLayoutChildren -> _positionAndResizeChildren, which does not climb to my parent).
      # Never SCHEDULE it (no invalidateLayout): the sanctioned immediate-mutator apply,
      # exactly like TextWdgt.rawSetExtent -> @_reLayoutSelf and rawSetWidthSizeHeightAccordingly
      # -> @_reLayout (task #17). check-layering.js rule [E] forbids the SCHEDULE, not this APPLY.
      @_reLayoutChildren()
