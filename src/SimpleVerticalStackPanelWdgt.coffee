class SimpleVerticalStackPanelWdgt extends Widget

  # stacks don't necessarily enforce a width on contents
  # so the contents could stick out, so we clip at the bounds
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  _acceptsDrops: true
  tight: true
  constrainContentWidth: true

  colloquialName: ->
    "stack"

  # A vertical stack constrains a dropped child to its width/height ratio, and frees that
  # constraint when the child is grabbed back out. These container capabilities replace the
  # `whereIn/whereFrom instanceof SimpleVerticalStackPanelWdgt` tests in the ratio mixin and
  # Example3DPlotWdgt; WindowWdgt (a stack subclass) overrides the DROP one to false because
  # a window does NOT impose the ratio on its contents. (type-test-elimination campaign)
  imposesRatioConstraintOnDroppedChildren: ->
    true

  releasesRatioConstraintOnGrabbedChildren: ->
    true

  add: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped, positionOnScreen: positionOnScreen

  # _addNoSettle -- the non-settling core of add(), mirroring Widget.add/_addNoSettle. The stack-specific
  # work (_resizeToWithoutSpacing + sibling-position computation) only uses immediate mutators / structural
  # cores, so build-time / layout-time / teardown adders can call it directly without flushing layouts.
  # (window-rebuild follow-up: lets WindowWdgt._buildAndConnectChildrenNoSettle add chrome + content through cores.)
  _addNoSettle: (aWdgt, opts = {}) ->
    position = opts.position
    layoutSpec = opts.layoutSpec ? LayoutSpec.ATTACHEDAS_FREEFLOATING
    beingDropped = opts.beingDropped
    positionOnScreen = opts.positionOnScreen
    aWdgt._resizeToWithoutSpacing()

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
      super aWdgt, position: positionNumberAmongSiblings, layoutSpec: layoutSpec, beingDropped: beingDropped
    else
      super aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped

  constructor: (extent, color, @padding = 5, @constrainContentWidth = true) ->
    super()
    @appearance = new RectangularAppearance @
    @__commitExtent(extent) if extent?
    @color = color if color?

  # The re-fit chokepoint for a stack (no scrollbars): re-lay-out my stacked
  # contents. See Widget._reLayoutChildren.
  _reLayoutChildren: ->
    @_positionAndResizeChildren()

  # ===== Phase 3b (Slice 2): re-fit on the _reLayout cycle =====
  # Mirror of ScrollPanelWdgt's Slice-1 pair (see there). super applies my own bounds first
  # (DETERMINISM.md case-3c), then I re-lay-out my stacked contents. Inherited by WindowWdgt.
  # This is a fixed point ONLY because _positionAndResizeChildren sizes its (deferred-layout)
  # children via _setWidthSizeHeightAccordingly, which -- when called during a layout pass --
  # settles them in place (synchronous _reLayout, no invalidate-climb); see that method + the
  # design doc's "Phase 3b -- Slice 2".
  # implementsDeferredLayout pinned false so adding this _reLayout doesn't flip the two read
  # sites (_setWidthSizeHeightAccordingly invalidate + subWidgetsMergedFullBounds).
  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()
    # (schedule-valve arc V3, 2026-07-16) my arrange above may have re-committed my own HEIGHT (the
    # tight-hug), AFTER super's corner-internal tail already placed my handle overlays -- re-place
    # them at the FINAL frame (idempotent when the hug was a no-op). The retired synchronous hook
    # masked this ordering by running the arrange inside super's self-extent-apply, so the hug used
    # to land before the corner tail.
    @_reLayoutCornerInternalChildren()

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
  _reactToChildRemoved: (child) ->
    return if @parent?._reLayOutAfterContainedPanelChange?()
    @_reFitContainer()

  _reactToChildDropped: (child) ->
    return if @parent?._reLayOutAfterContainedPanelChange?()
    @_reFitContainer()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  availableWidthForContents: ->
    @width() - 2 * @padding

  # The per-child stack sizing POLICY, in ONE place for the three siblings that walk my children
  # (the pure measures preferredExtentForWidth / subWidgetsMergedPreferredBounds and the applying
  # _positionAndResizeChildren): the width my stack recommends for a child, and the left edge its
  # alignment puts it at. A child transiently without its layoutSpec (mid drop/delete) gets the raw
  # available width -- keeps the pure measures TOTAL (never throw), mirroring
  # WindowWdgt.preferredExtentForWidth's guard; the arrange initialises every spec before asking.
  _childWidthInStack: (widget, availForContents) ->
    widget.layoutSpecDetails?.getWidthInStack(availForContents) ? availForContents

  _childLeftInStack: (widget, childWidth) ->
    if widget.layoutSpecDetails?.alignment == 'right'
      @left() + @width() - @padding - childWidth
    else if widget.layoutSpecDetails?.alignment == 'center'
      @left() + Math.floor (@width() - childWidth) / 2
    else
      # 'left' (or a transiently-missing spec)
      @left() + @padding

  # The per-child MEASURED EXTENT at a recommended width, in ONE place for the three walkers
  # (the pure measures preferredExtentForWidth / subWidgetsMergedPreferredBounds and the applying
  # _positionAndResizeChildren): measure via the child's own preferredExtentForWidth (fallback: a
  # width-invariant child keeps its current height), then ROUND + MIN-CLAMP exactly as __commitExtent
  # will when the arrange applies it -- so what a measure REPORTS is byte-what the arrange COMMITS.
  # (Before this helper the three sites disagreed: no-clamp-no-round / clamp-no-round /
  # commit-clamped-but-hand-forward-unclamped -- masked only by every measure returning integers
  # >= the (5,5) default minimumExtent.)
  _childMeasuredExtentInStack: (widget, recommendedWidth) ->
    measured = widget.preferredExtentForWidth?(recommendedWidth)
    ext = if measured? then measured.round() else new Point recommendedWidth, widget.height()
    minE = widget.getMinimumExtent?()
    if minE? then ext = ext.max minE
    ext

  # §4.1 pure measure (proper-layouts): the side-effect-free preferred extent of the stack at an
  # available width -- Σ over children of (padding + child preferred height), + a trailing padding,
  # mirroring _positionAndResizeChildren's arithmetic. Each child measures via its OWN
  # preferredExtentForWidth (text wrap / clock square / ratio); a child without one (a plain widget
  # whose height is width-independent) falls back to its current height. NO mutation, NO seam --
  # this is the composable container measure a parent (the scroll panel, Stage C) will consume
  # instead of the subWidgetsMergedFullBounds applied-bounds read-back. WindowWdgt overrides this
  # with its real content+chrome measure (Stage D). Proven byte-exact suite-wide: 3252
  # measure-vs-committed-height differentials, 0 mismatches. CONSUMED by
  # WindowWdgt.preferredExtentForWidth (a window recursing into its stack content) and by any
  # enclosing stack/scroll measuring a nested stack.
  preferredExtentForWidth: (availW) ->
    availForContents = availW - 2 * @padding
    children = @childrenNotHandlesNorCarets()
    totalHeight = 0
    for widget in children
      if @constrainContentWidth
        childHeight = (@_childMeasuredExtentInStack widget, @_childWidthInStack widget, availForContents).y
      else
        childHeight = widget.height()
      totalHeight += @padding + childHeight
    totalHeight += @padding
    if !@tight or children.length == 0
      totalHeight = Math.max totalHeight, @height()
    return new Point availW, totalHeight

  # §4.1 Stage C (proper-layouts) override of Widget.subWidgetsMergedPreferredBounds: my children's merged
  # bounds derived PURELY from measures -- I compute each child's SIZE (preferredExtentForWidth) AND POSITION
  # (the SAME cumulative-stack + alignment arithmetic as _positionAndResizeChildren below, but WITHOUT
  # applying it), so a scroll-panel parent can size its content frame without my children having been
  # resized+moved first. Unlike the base (which reads stable applied positions of a non-laying-out panel's
  # children), a stack's child positions are layout-derived, so they are RE-DERIVED here from measured
  # heights. availW = my available width (I subtract my own padding, exactly as the arrange does). Sizes are
  # min-extent-clamped to match __commitExtent. Byte-identical to subWidgetsMergedFullBounds at the fixed
  # point (Stage-C probe: 0/1429 converged mismatches). NB the tight=false viewport grow in
  # preferredExtentForWidth is deliberately NOT applied here -- the scroll panel does its own viewport grow,
  # and the frame wants the NATURAL children union.
  subWidgetsMergedPreferredBounds: (availW) ->
    kids = @childrenNotHandlesNorCarets()
    return nil if kids.length == 0
    avail = (availW ? @width()) - 2 * @padding
    merged = nil
    cumH = 0
    for widget, i in kids
      if @constrainContentWidth
        recW = @_childWidthInStack widget, avail
        e = @_childMeasuredExtentInStack widget, recW
        w = e.x
        h = e.y
        left = @_childLeftInStack widget, recW
      else
        h = widget.height()
        w = widget.width()
        left = @left() + @padding
      top = @top() + (i + 1) * @padding + cumH
      r = new Rectangle left, top, left + w, top + h
      merged = if merged? then merged.merge r else r
      cumH += h
    merged

  _positionAndResizeChildren: ->

    stackHeight = 0
    verticalPadding = 0

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    childrenNotHandlesNorCarets.forEach (widget) =>
      if widget.layoutSpec != LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT
        widget.initialiseDefaultVerticalStackLayoutSpec()
        widget.layoutSpecDetails.captureInitialPlacement widget, @
        widget._setLayoutSpec LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT

    childrenNotHandlesNorCarets.forEach (widget) =>
      verticalPadding += @padding
      elementHeight = nil   # set in the else-branch from the handed-forward resize result; see stackHeight += below

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
        recommendedElementWidth = @_childWidthInStack widget, @availableWidthForContents()

        # Size the child at the recommended width -- two paths by child KIND, neither of
        # which notifies anyone (the notify-by-mutation seam was deleted 2026-07-01; my
        # container re-fits at settle time via the up-edge):
        #  - a TRACKING-CONTAINER child (`_reLayoutChildren?` -- Window / Stack / ScrollPanel)
        #    goes through _setWidthSizeHeightAccordingly: applying its width must ALSO
        #    arrange its own subtree at that width (a pure measure cannot apply a subtree
        #    arrange), and the call HANDS the resulting height forward (Path B), so I never
        #    read the child's geometry back.
        #  - a LEAF child (text / clock / box) is sized by the PURE measure
        #    preferredExtentForWidth -- it carries each type's width->height sizing (wrapped
        #    text / clock square / ratio), proven byte-exact vs the old mutate-and-read-back
        #    by the §4.1 Stage-A/B differential probes -- applied through the
        #    override-bypassing _applyExtentBase.
        # (NB do NOT use `implementsDeferredLayout()` as the discriminator -- it is pinned
        # false on Window/Stack/Scroll precisely so it doesn't flip their read sites, so it
        # would mis-route them to the leaf branch.)
        if widget._reLayoutChildren?
          elementHeight = widget._setWidthSizeHeightAccordingly recommendedElementWidth
        else
          measured = @_childMeasuredExtentInStack widget, recommendedElementWidth
          widget._applyExtentBase measured
          elementHeight = measured.y

        # contained text that OPTED INTO FIT_BOX_TO_TEXT (a SimplePlainTextWdgt or a
        # bare TextWdgt put into that mode) fits its BOX to the TEXT: wrap to the
        # width set above, height follows the wrapped content. We RESPECT the mode
        # (so a FIT_TEXT_TO_BOX placeholder is left alone); reassert soft-wrap.
        if widget.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
          widget.softWrap = true

        leftPosition = @_childLeftInStack widget, recommendedElementWidth


      # Move the child -- same discriminator as the resize above, DIFFERENT reason (nothing
      # notifies anything anymore; the notify-by-mutation seam was deleted 2026-07-01):
      # _applyMoveTo is the POLYMORPHIC move corner (ClippingAtRectangularBoundsMixin's
      # scroll-optimization override dispatches through it), _applyMoveToBase the uniform
      # base translate. Each child KIND keeps the path it has always taken: a tracking
      # container (a clipping widget) keeps its override's repaint behaviour, a leaf keeps
      # the base translate. Unifying onto either name is a REPAINT-PATH change (e.g. a
      # clipping leaf panel would gain the override), not a free cleanup -- see the
      # twin-collapse verdict on Widget._applyMoveBy.
      # Integer placement (Layer A): the running stackHeight / centred leftPosition are kept EXACT (fractional
      # child heights sum without accumulating rounding error), but the child's committed @bounds origin must be
      # integer -- round only at placement. docs/fractional-widget-bounds-investigation-plan.md (Path 2).
      targetPos = (new Point leftPosition, @top() + verticalPadding + stackHeight).round()
      if widget._reLayoutChildren?
        widget._applyMoveTo targetPos
      else
        widget._applyMoveToBase targetPos
      # else-branch: consume the handed-forward height (no read-back of applied @bounds). The
      # !constrainContentWidth if-branch does NO resize -- there is no mutate-then-read-back to remove there --
      # so it falls back to reading the child's already-settled height. (proper-layouts Phase B)
      stackHeight += elementHeight ? widget.height()

    newHeight = stackHeight + verticalPadding + @padding

    if !@tight or childrenNotHandlesNorCarets.length == 0
      newHeight = Math.max newHeight, @height()

    # Apply my arranged height via the override-bypassing base apply: it commits my frame + repaints WITHOUT
    # re-entering _reLayoutChildren (I am mid-arrange; my children are already placed), and it notifies nobody
    # (the notify-by-mutation seam is deleted -- my container re-fits at settle time via the up-edge, from my
    # FINAL frame). The old parentWillSizeMe fork here ("my scroll-panel sizer owns my frame, don't notify it"
    # vs "notify") died with the seam: both arms had become this same call, differing only by a redundant
    # unconditional cache-break (Tier D, 2026-07-02).
    @_applyExtentBase new Point @width(), newHeight
