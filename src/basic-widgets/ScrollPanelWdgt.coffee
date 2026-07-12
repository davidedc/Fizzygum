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
    @scrollBarsThickness = (WorldWdgt.preferencesAndSettings.scrollBarsThickness),
    @sliderColor
    ) ->
    # super() paints the ScrollPanel, which we don't want,
    # so we set 0 opacity here.
    @alpha = 0
    super()
    @_buildScrollFrame()

  # Build the scroll frame (contents + h/v scrollbars) via the NoSettle core, settling ONCE at the end
  # (orphan-settledness: `new ScrollPanelWdgt` returns settled). The name is deliberately DISTINCT from the
  # leaf builder `_buildAndConnectChildren`: ScrollPanelWdgt is a base whose subclass ListWdgt OVERRIDES
  # `_buildAndConnectChildren` to build its list CONTENTS, and CoffeeScript binds a subclass's constructor
  # params (@elements, …) only AFTER super(). If THIS base constructor called the (virtual)
  # `_buildAndConnectChildren`, `new ListWdgt` would dispatch into ListWdgt's contents-core during super()
  # with @elements still nil → crash. So the base builds only the frame here (a name ListWdgt does not
  # override); ListWdgt's constructor builds its contents via `_buildAndConnectChildren` AFTER super().
  _buildScrollFrame: ->
    @_settleLayoutsAfter => @_buildScrollFrameNoSettle()

  _buildScrollFrameNoSettle: ->
    @contents = new PanelWdgt @ unless @contents?
    # _addNoSettle (NOT the self-settling public add): we are building our own innards
    # during construction; the panel is not parented yet, so a flush here would be a
    # redundant whole-world relayout (and would throw if we are built during a layout pass).
    @_addNoSettle @contents

    # the ScrollPanel is never going to paint itself,
    # but its values are going to mimic the values of the
    # contained Panel
    @color = @contents.color
    @alpha = @contents.alpha

    @hBar = new SliderWdgt nil, nil, nil, nil, @sliderColor
    @hBar._applyHeight @scrollBarsThickness

    @hBar.target = @
    @_addNoSettle @hBar

    @vBar = new SliderWdgt nil, nil, nil, nil, @sliderColor
    @vBar._applyWidth @scrollBarsThickness
    @vBar.target = @
    @_addNoSettle @vBar

    @hBar.target = @
    @hBar.action = "adjustContentsBasedOnHBar"
    @vBar.target = @
    @vBar.action = "adjustContentsBasedOnVBar"

    @_reLayoutScrollbars()

  wantsDropOfChild: (aWdgt) ->
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
    @contents._applyMoveTo new Point @left() - num, @contents.position().y
    # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  adjustContentsBasedOnVBar: (num) ->
    @contents._applyMoveTo new Point @contents.position().x, @top() - num
    # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  setColor: (aColorOrAWidgetGivingAColor, widgetGivingColor) ->
    aColor = super aColorOrAWidgetGivingAColor, widgetGivingColor
    # keep in sync the color of the content.
    # Note that the container ScrollPanel.
    # is actually not painted.
    @contents.setColor aColorOrAWidgetGivingAColor, widgetGivingColor
    return aColor

  setAlphaScaled: (alphaOrWidgetGivingAlpha, widgetGivingAlpha) ->
    alpha = super
    # update the alpha of the ScrollPanel - note
    # that we are never going to paint the ScrollPanel
    # we are updating the alpha so that its value is the same as the
    # contained Panel
    @contents.setAlphaScaled alphaOrWidgetGivingAlpha, widgetGivingAlpha
    return alpha

  anyScrollBarShowing: ->
    if (@hBar.visibleBasedOnIsVisibleProperty() and !@hBar.isInCollapsedSubtree()) or
    (@vBar.visibleBasedOnIsVisibleProperty() and !@vBar.isInCollapsedSubtree())
      return true
    return false

  _reLayoutScrollbars: ->
    # (proper-layouts Phase D, 2026-06-28) This used to set @_adjustingContentsBounds (save/restore) SOLELY so
    # the cross-method seam check in Widget._reFitContainer suppressed the bars' raw resizes below from
    # re-fitting ME (the panel). That check was deleted in Phase D, so the save/restore was inert and is gone
    # too. (proper-layouts Phase E, 2026-06-28) The @_adjustingContentsBounds field is now fully DELETED: its
    # last use -- the _positionAndResizeChildren re-entrancy guard -- was retired by the arrange applying its
    # own geometry through the override-bypassing _applyExtentBase (the interim _resizeOwn*SkippingChildRelayout
    # helpers were inlined away in Tier D, 2026-07-02).
    # (§4.2 Stage 3, 2026-06-29) The bars below now apply their geometry via the NON-notifying arrange twins
    # (_applyExtentBase / _applyMoveToBase) so they no longer fire the re-fit seam back at ME: the bars
    # are chrome I own and place from my own size, never affecting my content-fit, so the seam's self-re-enqueue
    # (the capstone's Pattern C) was a pure redundant confirm pass. (The whole notify-by-mutation seam has since
    # been DELETED -- 2026-07-01, replaced by the settle-time up-edge -- so no mutator fires anything anymore.)

    # one typically has both scrollbars in view, plus a resizer
    # in bottom right corner, so adjust the width/height of the
    # scrollbars so that there is no overlap between the three things
    spaceToLeaveOnOneSide = Math.max(@scrollBarsThickness, WorldWdgt.preferencesAndSettings.handleSize) + 2 * @padding
    hWidth = @width() - spaceToLeaveOnOneSide
    vHeight = @height() - spaceToLeaveOnOneSide

    unless @parent instanceof ListWdgt
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
        # §4.2 Stage 3: my scrollbars are chrome I OWN and place -- pure followers of my own width/height, never
        # affecting my content-fit (subBounds reads @contents' children, not my bars). So size/position them via
        # the NON-notifying twins; the old _applyWidth/_applyMoveTo fired the re-fit seam back at ME (the
        # capstone's Pattern C self-re-enqueue), a redundant confirm pass. (_applyExtentBase == _applyWidth/Height
        # minus the seam; preserves height/width by passing the current other axis.)
        @hBar._applyExtentBase new Point(hWidth, @hBar.height())  if @hBar.width() isnt hWidth
        # we check whether the bar has been detached. If it's still
        # attached then we possibly move it, together with the
        # ScrollPanel, otherwise we don't move it.
        if @hBar.parent == @
          @hBar._applyMoveToBase new Point @left(), @bottom() - @hBar.height()
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
        # §4.2 Stage 3: same as the hBar above -- non-notifying twin (chrome I own, never affects content-fit).
        @vBar._applyExtentBase new Point(@vBar.width(), vHeight)  if @vBar.height() isnt vHeight
        # we check whether the bar has been detached. If it's still
        # attached then we possibly move it, together with the
        # ScrollPanel, otherwise we don't move it.
        if @vBar.parent == @
          @vBar._applyMoveToBase new Point @right() - @vBar.width(), @top()
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
    # annotation + handle both attach to the scroll frame directly (was their two instanceof)
    # (type-test-elimination campaign)
    if aWdgt.attachesToScrollFrameDirectly?()
      super
    else
      @contents.add aWdgt, position, layoutSpec, beingDropped, nil, positionOnScreen
      # Intentional synchronous APPLY (not an off-settle trigger to defer): add / addMany /
      # showResizeAndMoveHandlesAndLayoutAdjusters are public content-change ENDPOINTS, idempotent
      # with this panel's own _reLayout ('super; @_reLayoutChildren') so the cycle re-fits identically;
      # the inline call just keeps geometry current within the calling public method. Distinct from
      # the seam sites (raw-mutator / gesture triggers), which DO defer. (deferred-layout-residuals-audit.md)
      # Deferring this re-fit through a batch settler was PROBED 2026-06-22 (OVERVIEW §11 Phase-4) and
      # REJECTED: it deterministically diverges nested-scroll content/thumb geometry (3 frames of
      # macroNestedScrollPanelsRouteWheel + macroDocumentScrollsMixedTextAndClocks) for ZERO gain -- the
      # synchronous re-fit's re-read of APPLIED geometry is load-bearing (OVERVIEW §11 PROOF 2). Leave synchronous.
      # layout-apply-sanctioned: public content-change endpoint, idempotent w/ _reLayout (OVERVIEW §11 PROOF 2)
      @_reLayoutChildren()

  # see SimpleSlideWdgt for performance improvements
  # of this over the non-
  # thin-wrap-exempt: SYNCHRONOUS content-change endpoint -- @contents.addMany + immediate @_reLayoutChildren
  # (re-reading APPLIED geometry is load-bearing; deferring it diverges nested-scroll geometry, exactly as for
  # add() -- OVERVIEW §11 PROOF 2). The _addManyNoSettle twin below is the non-settling core for in-flush callers
  # (createToolsPanel), NOT a settle the public form should route through.
  addMany: (widgetsToBeAdded) ->
    @contents.addMany widgetsToBeAdded
    @_reLayoutChildren() # layout-apply-sanctioned: public content-change endpoint -- see add() (OVERVIEW §11 PROOF 2)

  # NON-settling core: forward to @contents' addMany core (the buttons attach to the scrolled ToolPanelWdgt, NOT
  # this frame -- like add() -> @contents.add above), then SCHEDULE this frame's re-fit. The enclosing wrapper's
  # flush applies it -- vs the public addMany's synchronous @_reLayoutChildren endpoint (which is off-settle).
  _addManyNoSettle: (widgetsToBeAdded) ->
    @contents._addManyNoSettle widgetsToBeAdded
    @_invalidateLayout()


  # Override the NON-settling CORE (the public showResizeAndMoveHandlesAndLayoutAdjusters wrapper is inherited from
  # Widget and self-settles once around the whole show-handles tree). super adds the handles + climbs; @_reLayout
  # Children re-fits my contents+scrollbars synchronously, riding that outer settle. (end-of-cycle-flush-drawdown.)
  _showResizeAndMoveHandlesAndLayoutAdjustersNoSettle: ->
    super
    @_reLayoutChildren() # layout-apply-sanctioned: public content-change endpoint -- see add() (OVERVIEW §11 PROOF 2)

  
  setContents: (aWdgt, extraPadding = 0) ->
    @extraPadding = extraPadding
    # there should never be a shadow but one never knows...
    @contents.closeChildren()
    @contents._applyMoveTo @position()

    aWdgt._applyMoveTo @position().add @padding + @extraPadding

    @add aWdgt


  _applyExtent: (aPoint) ->
    unless aPoint.equals @extent()
      # TODO this part seems like it should be in a _reLayout function
      # rather than here
      if @isTextLineWrapping and !(@contents instanceof SimpleVerticalStackPanelWdgt)
        @contents._applyMoveTo @position()
      super aPoint
      @contents._applyExtent aPoint
      # immediate mutator: APPLY the re-fit NOW -- synchronous, single-container, TERMINAL
      # (_reLayoutChildren -> _positionAndResizeChildren + _reLayoutScrollbars, neither climbs to my
      # parent). Never SCHEDULE it (no _invalidateLayout): the sanctioned immediate-mutator
      # apply, like TextWdgt._applyExtent -> @_reLayoutSelf (task #17). Rule [E] forbids the SCHEDULE.
      @_reLayoutChildren()


  # Gesture-driven container re-fit (a widget was dropped into / grabbed out of me): DEFER it to
  # the cycle. These are dispatched from ActivePointerWdgt.drop/grab AFTER a self-settling add, so
  # they run OUTSIDE any layout pass -- the else arm (invalidate self; my _reLayout is
  # 'super; @_reLayoutChildren', so the cycle re-fits me identically) is what runs. The in-pass
  # arm keeps the synchronous re-fit (the pre-existing behaviour) for safety. (No recalc-enqueue arm:
  # unlike the seams, these are never dispatched mid-pass. See deferred-layout-residuals-audit.md fam 2.)
  _reactToChildDropped: ->
    @_reFitContainer()

  _reactToChildGrabbed: (child) ->
    @_reFitContainer()

  # Re-fit my contents area and my scrollbars: the named "re-fit me" pair, shared
  # by every trigger that changes what I contain (drops, grabs, attaches, a
  # contained panel's notification). Inherited by ListWdgt and the other scroll
  # panels -- they all re-fit the same way (the ListWdgt opt-out below is ONLY
  # for the contained-panel notification, not for this pair).
  _reLayoutChildren: ->
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # ===== Phase 3b (Slice 1): re-fit on the _reLayout cycle =====
  # A scroll panel re-fits its contents+scrollbars during recalculateLayouts (deferred),
  # not only via the inline _reLayoutChildren triggers. super (Widget::_reLayout) applies
  # MY OWN new bounds FIRST -- consuming @desired* and, on a real resize, re-fitting via the
  # _applyExtent override -- and THEN we re-fit to the (now-applied) viewport. Establishing
  # own bounds before re-fitting the contents is the DETERMINISM.md case-3c discipline (a
  # custom _reLayout must apply its own bounds before laying out what it contains). On a pure
  # resize the re-fit here is redundant with the _applyExtent override and idempotent; on a
  # content-only change (Phase 3b Slice 2, when the inline triggers become _invalidateLayout)
  # it is the one that runs.
  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  # implementsDeferredLayout is `@_reLayout != Widget::_reLayout`, so the _reLayout above would
  # otherwise flip it true and change TWO read sites: (A) _setWidthSizeHeightAccordingly
  # (invalidate-on-resize) and, the load-bearing one, (B) subWidgetsMergedFullBounds -- a
  # deferred-layout child contributes only its viewport rect, not its scrolled subtree, which
  # would shrink a NESTED scroll panel's reported content size and regress nested-scroll
  # (the proven 16->18 Path-A trap). We pin it to false so the _reLayout drives the re-fit
  # while our merged-bounds/resize classification stays exactly as before we had a _reLayout.
  implementsDeferredLayout: ->
    false

  _reLayoutChildrenAndScrollbars: ->
    @_reLayoutChildren()

  # A contained panel (e.g. a vertical stack acting as my @contents) tells me
  # its set of children changed, so I re-fit. I return true so the panel knows I
  # took over its re-layout (my _positionAndResizeChildren already re-lays my contents
  # out) and needn't do its own. This is the polymorphic replacement for
  # SimpleVerticalStackPanelWdgt testing `@amIPanelOfScrollPanelWdgt()`: the
  # stack just notifies its parent, and only a scroll panel reacts. NB kept
  # SEPARATE from _reLayoutChildrenAndScrollbars / _reactToChildDropped / _reactToChildGrabbed on
  # purpose -- a ListWdgt opts OUT of THIS notification (see ListWdgt) yet still
  # re-fits on its own drops/grabs/attaches.
  _reLayOutAfterContainedPanelChange: ->
    @_reLayoutChildrenAndScrollbars()
    return true

  _positionAndResizeChildren: ->

    # if PanelWdgt is of type isTextLineWrapping
    # it means that you don't want the text widget to
    # extend indefinitely as you are typing. Rather,
    # the width will be constrained and the text will
    # wrap.
    padding = Math.floor @extraPadding + @padding
    totalPadding = 2*padding

    if @contents instanceof SimpleVerticalStackPanelWdgt
      # arrange the content stack's children; I OWN its frame regardless (I size it from the §4.1 pure
      # measure -- subBounds -> the frame commit below), and the stack's terminal self-resize notifies nobody
      # (the notify-by-mutation seam is deleted; its parentWillSizeMe don't-notify-my-sizer parameter went
      # with it -- Tier D, 2026-07-02).
      @contents._positionAndResizeChildren()
    else if @isTextLineWrapping and @contents instanceof PanelWdgt
      @contents.children.forEach (widget) =>
        if widget.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
          # contained text that OPTED INTO FIT_BOX_TO_TEXT (a SimplePlainTextWdgt or
          # a bare TextWdgt put into that mode) fits its BOX to the TEXT: reassert
          # soft-wrap, then feed it the width — _applyWidth re-lays-out the text to
          # that width (height = wrapped line count), and that new height drives the
          # vertical slider below. We RESPECT the mode (a non-text child or a
          # FIT_TEXT_TO_BOX widget is skipped).
          widget.softWrap = true
          textWidth = @contents.width() - totalPadding
          widget._applyWidth textWidth
          # (Phase C, proper-layouts) We only RE-WRAP the text child here (_applyWidth -> height = wrapped
          # line count); paint + the caret's synchronous @wrappedLines read need that committed, and the new
          # height then flows into subBounds below. We do NOT prime the contents FRAME height here anymore:
          # the merged-bounds commit at the end of this method is the SINGLE owner of @contents' extent. The
          # old priming `@contents._applyHeight (max(<text wrapped height>, @height()) - totalPadding)` was
          # redundant with that commit (nothing between here and there reads @contents.height() -- subBounds is
          # the CHILDREN's merged bounds, not the frame's) and, worse, NON-IDEMPOTENT: it set `max(M,vp) -
          # totalPadding` while the commit sets `max(M + 2*padding, vp)`, so the frame height flip-flopped by
          # ~totalPadding every pass (a re-fit seam each) -- one of the three self-oscillations the
          # @_adjustingContentsBounds flag had to mask, and the one that PERPETUATED the non-convergence (the
          # position clamp self-settles in <=2 passes once this stops). The genuine content-height read-back is
          # subBounds itself, retired only when a later phase gives the arrange a pure measure of its children.

    # §4.1 Stage C (proper-layouts): a content-sizing scroll panel (text-wrapping / vertical-stack / plain-text)
    # derives its content frame from a PURE measure of @contents's children (subWidgetsMergedPreferredBounds)
    # rather than mutating them and reading their merged APPLIED bounds back. This breaks the frame-sizing's
    # dependency on the children having been resized first -- the mutate-then-read-back the re-fit seam exists
    # for (assessment §2.4) -- yet is byte-identical (measured extent == applied at the fixed point; Stage-C
    # probe 0/1429 converged mismatches). The stack measures at its own width (it subtracts its own padding);
    # a bare text panel measures its children at the scroll-padding-inset width (== the _applyWidth re-wrap
    # above). The else-branch (folder / toolbar) is NOT a content-sizing target and keeps the applied read-back.
    isContentSizing = @isTextLineWrapping or
     (@ instanceof SimplePlainTextScrollPanelWdgt) or
     (@ instanceof SimpleVerticalStackScrollPanelWdgt)
    if isContentSizing
      if @contents instanceof SimpleVerticalStackPanelWdgt
        subBounds = @contents.subWidgetsMergedPreferredBounds(@contents.width())?.ceil()
      else
        subBounds = @contents.subWidgetsMergedPreferredBounds(@contents.width() - totalPadding)?.ceil()
    else
      subBounds = @contents.subWidgetsMergedFullBounds()?.ceil()
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
      if isContentSizing
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
      # §4.2 Stage 3 (structural arrange): I OWN my content's frame -- I computed newBounds from the §4.1 pure
      # measure (subBounds), so apply it via the NON-notifying twin. The old _commitBounds fired the re-fit
      # seam back at ME (Intent-2 self-re-enqueue = the capstone's Pattern D), redundant since I am the one sizing
      # the content; the seam only delivered a confirm pass that the §4.1 measure already makes a no-op.
      @contents._commitBounds newBounds
      @contents._reLayoutSelf()

    # you'd think that if @contents.boundingBox().equals newBounds
    # then we don't need to check if the contents are "in good view"
    # but actually for example a stack resizes itself automatically when the
    # elements are resized (in the foreach loop above),
    # so we need anyways to do this check and fix the view if the
    # case. The good news is that it's a cheap check to do in case
    # there is nothing to do.
    @keepContentsInScrollPanelWdgt()

  # §4.2 Stage 3 (structural arrange): the position clamp keeping my content snug against my viewport edges. I
  # OWN this position, so apply each nudge via the NON-notifying move twin -- the old _applyMoveBy fired the
  # re-fit seam back at ME (part of the scroll panel's Intent-2 self-re-enqueue), redundant since I am the clamper.
  keepContentsInScrollPanelWdgt: ->
    if @contents.left() > @left()
      @contents._applyMoveByBase new Point @left() - @contents.left(), 0
    if @contents.right() < @right()
      @contents._applyMoveByBase new Point @right() - @contents.right(), 0
    if @contents.top() > @top()
      @contents._applyMoveByBase new Point 0, @top() - @contents.top()
    if @contents.bottom() < @bottom()
      @contents._applyMoveByBase new Point 0, @bottom() - @contents.bottom()
  
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
      @contents._moveLeftSideTo newX
      return true
    else
      return false

  # Scroll so CONTENT-point `whereTo` sits at my top-left. FRAME-RELATIVE (offset from my own
  # origin), so the result is independent of where I am in the world -- a caller's scroll survives
  # my being moved/resized (e.g. the sample-slide edit->view container shift). Was `-whereTo.x/.y`,
  # i.e. absolute world coords that only landed right for a frame at the world origin -- the root of
  # the 2026-07 mis-scrolled-slide magic constant. SampleSlideApp is the sole caller.
  scrollTo: (whereTo) ->
    @contents._moveLeftSideTo @left() - whereTo.x
    @contents._moveTopSideTo @top() - whereTo.y
    # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
    @_reLayoutScrollbars()


  scrollToBottom: ->
    @scrollY -100000
    # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
    @_reLayoutScrollbars()
  
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
      @contents._moveTopSideTo newY
      return true
    else
      return false
  
  # Sometimes you can scroll the contents of a ScrollPanel
  # by floatDragging its contents. This is particularly
  # useful in touch devices.
  # You can test this also in non-touch mode
  # by anchoring a ScrollPanel to something
  # non-draggable such as a color palette (can't drag it
  # because user can drag on it to pick a color).
  # Then you chuck a long text into the ScrollPanel and
  # drag the Panel (on the side of the text, where there is no
  # text) and you should see the ScrollPanel scrolling.
  mouseDownLeft: (pos) ->

    return nil  unless @isScrollingByfloatDragging

    oldPos = pos
    deltaX = 0
    deltaY = 0
    friction = 0.8
    wasScrollDragging = false
    # Did ANY frame of this gesture see a float-drag in progress? A float-drag means
    # the gesture is MOVING a (detachable) widget, not scrolling, so it must never get
    # a parting scroll — even if its frames collapse (see the flush's collapse branch).
    everFloatDragged = false
    world.steppingWdgts.add @
    @step = =>
      scrollbarJustChanged = false
      everFloatDragged ||= world.hand.isThisPointerFloatDraggingSomething()
      if world.hand.mouseButton and
        !world.hand.isThisPointerFloatDraggingSomething() and
        # if the Widget at hand is float draggable then
        # we are probably about to detach it, so
        # we shouldn't move anything, because user might
        # just float-drag the widget as soon as the threshold is
        # reached, and we don't want to scroll until that happens
        # that would be strange because it would be giving the
        # wrong cue to the user, we just want to hold steady
        !world.hand.wdgtToGrab?.detachesWhenDragged() and
        @boundsContainPoint(world.hand.position())
          wasScrollDragging = true
          newPos = world.hand.position()
          if @hBar.visibleBasedOnIsVisibleProperty() and
          !@hBar.isInCollapsedSubtree()
            deltaX = newPos.x - oldPos.x
            if deltaX isnt 0
              scrollbarJustChanged ||= @scrollX deltaX
          if @vBar.visibleBasedOnIsVisibleProperty() and
          !@vBar.isInCollapsedSubtree()
            deltaY = newPos.y - oldPos.y
            if deltaY isnt 0
              scrollbarJustChanged ||= @scrollY deltaY
          oldPos = newPos
      else
        # final FLUSH: this step samples the hand once per FRAME, so the tail
        # of the pointer's path that arrived in the same frame as the
        # mouse-up was never scrolled — without this the scroll total
        # truncates at the last pre-release frame sample, a frame-cadence
        # artifact. Scrolling the leftover here makes the total exactly
        # release-point minus press-point — event-determined, identical
        # across engines — and the leftover doubles as the glide's seed
        # velocity. Only when this drag actually scroll-dragged (a float-move
        # of the panel must not get a parting scroll), and only if released
        # inside the panel (matching the per-frame gate above).
        #
        # CADENCE COLLAPSE: under the harness's pacing control (or just a slow / HiDPI
        # frame) the whole press->drag->release can drain inside ONE cycle, so the FIRST
        # @step already sees the button up and NO button-down frame ever set
        # wasScrollDragging. That used to drop the scroll ENTIRELY (total -> 0), making
        # the outcome depend on frame cadence — it scrolled at dpr 1 but not at dpr 2,
        # the same gesture giving different pixels. Recover it here: when the gesture
        # never float-dragged anything and the hand isn't poised to detach a widget
        # (so it IS a scroll-drag, not a float-move) and the press is inside the panel,
        # treat it as a scroll-drag. oldPos is still the press point, so the flush below
        # scrolls exactly release-minus-press — the SAME event-determined total the
        # multi-frame path lands on, now identical at every dpr / speed / engine.
        collapsedScrollDrag = !wasScrollDragging and
          !everFloatDragged and
          !world.hand.wdgtToGrab?.detachesWhenDragged() and
          @boundsContainPoint(oldPos)
        if wasScrollDragging or collapsedScrollDrag
          wasScrollDragging = false
          releasePos = world.hand.position()
          if @boundsContainPoint releasePos
            if @hBar.visibleBasedOnIsVisibleProperty() and
            !@hBar.isInCollapsedSubtree()
              deltaX = releasePos.x - oldPos.x
              if deltaX isnt 0
                scrollbarJustChanged ||= @scrollX deltaX
            if @vBar.visibleBasedOnIsVisibleProperty() and
            !@vBar.isInCollapsedSubtree()
              deltaY = releasePos.y - oldPos.y
              if deltaY isnt 0
                scrollbarJustChanged ||= @scrollY deltaY
            oldPos = releasePos
        # POST-RELEASE MOMENTUM (the glide): keep scrolling by the last
        # frame's hand delta, decayed by friction each frame, until it fades.
        # Both that last delta and the glide length are FRAME-CADENCE driven
        # (how many queued events played back in the final frame), so under
        # the test harness's animations pacing control the glide is
        # SUPPRESSED outright — the content stops exactly at the event-
        # determined release offset and screenshots are reproducible across
        # engines. While a glide IS running (normal interactive use) it is
        # tracked in world.wdgtsWithOngoingScrollMomentum so the macro pump
        # can hold until it settles (the font-atlas-wait idea).
        glideSuppressed = Automator? and
          Automator.animationsPacingControl and
          Automator.state != Automator.IDLE
        if !@hasVelocity or glideSuppressed or
        ((Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5))
          @step = noOperation
          world.steppingWdgts.delete @
          world.wdgtsWithOngoingScrollMomentum.delete @
        else
          world.wdgtsWithOngoingScrollMomentum.add @
          if @hBar.visibleBasedOnIsVisibleProperty() and
          !@hBar.isInCollapsedSubtree()
            deltaX = deltaX * friction
            if deltaX isnt 0
              scrollbarJustChanged ||= @scrollX Math.round deltaX
          if @vBar.visibleBasedOnIsVisibleProperty() and
          !@vBar.isInCollapsedSubtree()
            deltaY = deltaY * friction
            if deltaY isnt 0
              scrollbarJustChanged ||= @scrollY Math.round deltaY
      if scrollbarJustChanged
        # layout-apply-sanctioned: scroll-input (momentum glide), determinism-exempt (residuals-audit fam 1)
        @_positionAndResizeChildren()
        @_reLayoutScrollbars()
    super
  
  # During a float-drag, if I want the dragged widget and the pointer is in my edge band, I
  # auto-scroll. ActivePointerWdgt calls this instead of testing `newWdgt instanceof
  # ScrollPanelWdgt` and driving the wantsDropOfChild / edge / startAutoScrolling logic itself.
  # (type-test-elimination campaign)
  maybeStartAutoScrollForDraggedWidget: (widgetBeingFloatDragged, pointerPosition) ->
    if @wantsDropOfChild widgetBeingFloatDragged
      if !@boundingBox().insetBy(WorldWdgt.preferencesAndSettings.scrollBarsThickness * 3).containsPoint pointerPosition
        @startAutoScrolling()

  startAutoScrolling: ->
    # The edge auto-scroll is wall-clock driven (the Date.now() settle below
    # plus per-frame increments), but unlike the momentum glide in
    # mouseDownLeft it is NOT suppressed under the test harness's pacing
    # control: it is a load-bearing interaction with its own SystemTest
    # (macroListWdgtAutoScrollsNearDraggedEdge). Its determinism contract is
    # SATURATION instead — a macro holds the drag in the edge band long
    # enough that the scroll CLAMPS, so the screenshotted endpoint is
    # frame-cadence-independent even though the path there isn't (see the
    # edge-auto-scroll entry in src/macros/MACRO-PATTERNS.md).
    inset = WorldWdgt.preferencesAndSettings.scrollBarsThickness * 3
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
    inset = WorldWdgt.preferencesAndSettings.scrollBarsThickness * 3
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
      # layout-apply-sanctioned: scroll-input (edge auto-scroll), determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
      @_reLayoutScrollbars()
  
  # ScrollPanelWdgt scrolling when editing text
  # so to bring the caret fully into view.
  scrollCaretIntoView: (caretWidget) ->
    txt = caretWidget.target
    ft = @top() + @padding
    fb = @bottom() - @padding
    fl = @left() + @padding
    fr = @right() - @padding
    # layout-apply-sanctioned: scroll-input (caret-into-view), determinism-exempt (residuals-audit fam 1)
    @_positionAndResizeChildren()
    marginAroundCaret = @padding
    if @extraPadding?
      marginAroundCaret += @extraPadding
    if caretWidget.top() < ft
      newT = @contents.top() + ft - caretWidget.top()
      @contents._moveTopSideTo newT + marginAroundCaret
      caretWidget._moveTopSideTo ft
    else if caretWidget.bottom() > fb
      newB = @contents.bottom() + fb - caretWidget.bottom()
      @contents._moveBottomSideTo newB - marginAroundCaret
      caretWidget._moveBottomSideTo fb
    if caretWidget.left() < fl
      newL = @contents.left() + fl - caretWidget.left()
      @contents._moveLeftSideTo newL + marginAroundCaret
      caretWidget._moveLeftSideTo fl
    else if caretWidget.right() > fr
      newR = @contents.right() + fr - caretWidget.right()
      @contents._moveRightSideTo newR - marginAroundCaret
      caretWidget._moveRightSideTo fr
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # ScrollPanelWdgt events.
  wheel: (xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg) ->

    x = xArg
    y = yArg

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

    if WorldWdgt.preferencesAndSettings.invertWheelX
      x *= -1
    if WorldWdgt.preferencesAndSettings.invertWheelY
      y *= -1

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
        @scrollY y * WorldWdgt.preferencesAndSettings.wheelScaleY
    if x != 0
      # similar to the vertical case, escalate the scroll in case
      # we are in a nested ScrollPanel situation
      if (x > 0 and @contents.left() >= (@left()-1)) or
       (x < 0 and @contents.right() <= (@right()+1) )
        @escalateEvent 'wheel', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
      else
        scrollbarJustChanged = true
        @scrollX x * WorldWdgt.preferencesAndSettings.wheelScaleX

    if scrollbarJustChanged
      # layout-apply-sanctioned: scroll-input (wheel), determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
      @_reLayoutScrollbars()
  

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    if @takesOverAndMergesChildrensMenus
      if @contents
        childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents
      if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length == 1
        childrenNotHandlesNorCarets[0].addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu
    else
      super
  
  # Set this scroll panel's text-line-wrapping state; turning wrapping ON fills
  # the content to the panel's bounds. (Called by SimplePlainTextWdgt's soft-wrap
  # toggle, which used to write this flag + resize the content from outside.)
  #
  # The resize here is DELIBERATELY IMMEDIATE (raw geometry), not the framework's
  # ideal DEFERRED pattern (set a flag + _invalidateLayout(), let recalculateLayouts
  # -> _reLayout derive the geometry). This is INTERMEDIATE state, not an oversight:
  # the deferred mechanism is half-built by construction (the geometry accessors read
  # applied @bounds only, so handler-level raw geometry is a symptom of that
  # incompleteness, not a one-off). Soft-wrap has an EXTRA blocker on top: the content
  # panel + text are ATTACHEDAS_FREEFLOATING, so _invalidateLayout() on them does NOT
  # climb up to this scroll panel, and the wrap geometry lives in _positionAndResizeChildren
  # -- which the _reLayout cycle never reaches for a wrap toggle. Completing the
  # deferred model (and this case) is deliberate, sequenced work; see
  # docs/softwrap-deferred-layout-conversion-plan.md for the model finding, the
  # obstacle map, and what a conversion would take.
  setTextLineWrapping: (wraps) ->
    @isTextLineWrapping = wraps
    if wraps
      @contents._applyMoveTo @position()
      @contents._applyExtent @extent()

  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.showEditModeInBar?()

    @enableDrops()
    @dragsDropsAndEditingEnabled = true

    @contents._enableDragsDropsAndEditingNoSettle @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget

  _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()

    @disableDrops()
    @dragsDropsAndEditingEnabled = false

    @contents._disableDragsDropsAndEditingNoSettle @
    # ELIMINATE (end-of-cycle-flush-drawdown): the "disable editing" menu action used to schedule an OFF-SETTLE
    # re-fit here (@_invalidateLayout) -- a careless end-of-cycle push (it reaches the flush from the menu trigger,
    # outside any settle; the suite-wide production audit flagged exactly this site). A disable-probe proved it
    # REDUNDANT: disabling changes appearance + drop-handling, not this panel's settled geometry, and the cascade's
    # @contents._disableDragsDropsAndEditingNoSettle above already did its synchronous work, so the deferred re-fit changed
    # nothing -- removing it is byte-identical (full gauntlet incl. the 12 panel-locking apps) and clears the
    # macroLockedDocumentRejectsDrop record. (Was `@_invalidateLayout()`.)

