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
    @_settleLayoutsAfter => @_addNoSettle aWdgt, position, layoutSpec, beingDropped, unused, positionOnScreen

  # _addNoSettle -- the non-settling core of add(), mirroring Widget.add/_addNoSettle. The stack-specific
  # work (rawResize-without-spacing + sibling-position computation) only uses raw/structural setters,
  # so build-time / layout-time / teardown adders can call it directly without flushing layouts.
  # (window-rebuild follow-up: lets WindowWdgt._buildAndConnectChildrenNoSettle add chrome + content through cores.)
  _addNoSettle: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->
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
      super aWdgt, positionNumberAmongSiblings, layoutSpec, beingDropped
    else
      super aWdgt, position, layoutSpec, beingDropped

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
  _reactToChildRemoved: ->
    return if @parent?._reLayOutAfterContainedPanelChange?()
    @_reFitContainer()

  _reactToChildDropped: ->
    return if @parent?._reLayOutAfterContainedPanelChange?()
    @_reFitContainer()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  availableWidthForContents: ->
    @width() - 2 * @padding

  # §4.1 pure measure (proper-layouts): the side-effect-free preferred extent of the stack at an
  # available width -- Σ over children of (padding + child preferred height), + a trailing padding,
  # mirroring _positionAndResizeChildren's arithmetic. Each child measures via its OWN
  # preferredExtentForWidth (text wrap / clock square / ratio); a child without one (a plain widget
  # whose height is width-independent) falls back to its current height. NO mutation, NO seam --
  # this is the composable container measure a parent (the scroll panel, Stage C) will consume
  # instead of the subWidgetsMergedFullBounds applied-bounds read-back. WindowWdgt overrides this
  # with a Stage-B stub (Stage D gives windows the real content+chrome measure). Proven byte-exact
  # suite-wide: 3252 measure-vs-committed-height differentials, 0 mismatches. No consumer yet.
  preferredExtentForWidth: (availW) ->
    availForContents = availW - 2 * @padding
    children = @childrenNotHandlesNorCarets()
    totalHeight = 0
    for widget in children
      if @constrainContentWidth
        # A child transiently without its layoutSpec (mid drop/delete) gets the raw available width --
        # keeps the measure TOTAL (never throws), mirroring WindowWdgt.preferredExtentForWidth's guard.
        childWidth = widget.layoutSpecDetails?.getWidthInStack(availForContents) ? availForContents
        measured = widget.preferredExtentForWidth?(childWidth)
        childHeight = measured?.y ? widget.height()
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
        recW = widget.layoutSpecDetails?.getWidthInStack(avail) ? avail
        measured = widget.preferredExtentForWidth?(recW)
        h = measured?.y ? widget.height()
        w = recW
        if widget.layoutSpecDetails?.alignment == 'right'
          left = @left() + @width() - @padding - recW
        else if widget.layoutSpecDetails?.alignment == 'center'
          left = @left() + Math.floor (@width() - recW) / 2
        else
          left = @left() + @padding
      else
        h = widget.height()
        w = widget.width()
        left = @left() + @padding
      minE = widget.getMinimumExtent?()
      if minE?
        h = Math.max h, minE.y
        w = Math.max w, minE.x
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
        widget.layoutSpecDetails.rememberInitialDimensions widget, @
        widget.setLayoutSpec LayoutSpec.ATTACHEDAS_VERTICAL_STACK_ELEMENT

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
        recommendedElementWidth = widget.layoutSpecDetails.getWidthInStack()

        # §4.2 Stage 1 (structural arrange): MEASURE the child's preferred extent at the recommended width, then
        # APPLY it via the NON-notifying arrange twin so this arrange does not fire the re-fit seam at ME (Intent-2
        # self-re-enqueue = the capstone's Pattern B). preferredExtentForWidth is PURE and already encapsulates each
        # child type's width->height sizing (wrapped text / clock square / ratio), so it returns the SAME extent the
        # old _setWidthSizeHeightAccordingly mutate-and-read-back produced -- proven byte-exact by the §4.1 Stage-A/B
        # differential probes. A deferred-layout child (a nested container) then re-lays-out its OWN children at that
        # extent (its self-resize is a no-op == the measure, so it fires no seam either). (was: notify-by-mutation
        # mutate-then-read-back; assessment §2.4.)
        # §4.2 Stage 1: apply the child's width WITHOUT firing the re-fit seam at ME (Pattern B) -- but for LEAF
        # children ONLY. A child that is itself a TRACKING CONTAINER (`_reLayoutChildren?` -- a Window / Stack /
        # ScrollPanel, the same marker the seam gates on) KEEPS the seam-firing _setWidthSizeHeightAccordingly:
        # its child-resize re-enqueue is LOAD-BEARING for a constrained-scroll-stack's content<->scrollbar WIDTH
        # convergence (making it non-notifying settled the stack 6px wider, overlapping its scrollbar --
        # macroWindowCellsInConstrainedScrollStackReflow). That converts only in Stage 3, once the convergence is
        # structural. (NB do NOT use `implementsDeferredLayout()` here -- it is pinned false on Window/Stack/Scroll
        # precisely so it doesn't flip their read sites, so it would mis-route them to the leaf branch.) A LEAF child
        # (text / clock / box -- the stack's 10 capstone Pattern-B pushes) takes the pure measure applied
        # non-notifying: the measure carries its per-type width->height sizing (wrapped text / clock square / ratio),
        # byte-exact by the §4.1 Stage-A/B probes, and a leaf has no inner convergence to drive.
        if widget._reLayoutChildren?
          elementHeight = widget._setWidthSizeHeightAccordingly recommendedElementWidth
        else
          measured = widget.preferredExtentForWidth recommendedElementWidth
          widget._applyExtentBase measured
          elementHeight = measured.y

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


      # §4.2 Stage 1: move via the NON-notifying arrange twin for LEAF children (once the resize stops firing the
      # seam, the child-MOVE becomes the surviving half of the stack's Pattern-B pushes). A child that is a TRACKING
      # CONTAINER (`_reLayoutChildren?`) keeps the seam-firing _applyMoveTo: its move's in-pass re-enqueue is
      # load-bearing for a constrained-scroll-stack's content<->scrollbar WIDTH convergence (dropping it settled the
      # stack 6px wider, overlapping its scrollbar) -- it converts only in Stage 3. Same discriminator as the resize.
      targetPos = new Point leftPosition, @top() + verticalPadding + stackHeight
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

  _applyExtent: (aPoint) ->
    unless aPoint.equals @extent()
      @__breakMoveResizeCaches()
      super aPoint
      # immediate mutator: APPLY the re-fit NOW -- synchronous, single-container, TERMINAL
      # (_reLayoutChildren -> _positionAndResizeChildren, which does not climb to my parent).
      # Never SCHEDULE it (no _invalidateLayout): the sanctioned immediate-mutator apply,
      # exactly like TextWdgt._applyExtent -> @_reLayoutSelf and _setWidthSizeHeightAccordingly
      # -> @_reLayout (task #17). check-layering.js rule [E] forbids the SCHEDULE, not this APPLY.
      @_reLayoutChildren()
