class ScrollPanelWdgt extends PanelWdgt

  autoScrollTrigger: nil
  hasVelocity: true
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
    # the CONTENTS vetoes raw drops into its frame (a folder's contents are managed by the
    # folder-window machinery) — capability via ?(), was `@contents instanceof FolderPanelWdgt`
    # (type-test-elimination ε)
    return false if @contents?.vetoesScrollPanelDrops?()
    return @_acceptsDrops

  colloquialName: ->
    # the CONTENTS names the construct ("folder"/"toolbar") — capability via ?(), was two
    # `@contents instanceof` tests (type-test-elimination ε)
    @contents?.scrollPanelColloquialName?() ? "scrollable panel"

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

  # The width my @contents must lay itself out within: my viewport width. Asked via ?() by
  # content that wraps to its container (ToolPanelWdgt's row-wrap). Capability, was
  # `parent instanceof ScrollPanelWdgt` at the caller (type-test-elimination ε).
  widthContentsMustFitWithin: ->
    @width()

  # Pressing a slider's TRACK jump-drags the button to the press point when the slider is
  # chrome its parent owns (my scrollbars) — SliderWdgt.mouseDownLeft asks its parent via ?().
  # PromptWdgt gives its input slider the same policy. Capability, was
  # `(parent instanceof ScrollPanelWdgt) or (parent instanceof PromptWdgt)` (type-test-elimination ε).
  sliderTrackPressJumpsButton: ->
    true

  # My direct children are chrome (contents panel + scrollbars), not user-lockable content —
  # opt OUT of the "lock to panel" menu toggle; see PanelWdgt.childrenCanLockToMe
  # (type-test-elimination ε).
  childrenCanLockToMe: ->
    false

  # Am I a content-sizing scroll frame — one whose content frame derives from a PURE measure
  # of @contents's children (§4.1 Stage C, see _positionAndResizeChildren)? The two dedicated
  # subclasses (SimplePlainTextScrollPanelWdgt / SimpleVerticalStackScrollPanelWdgt) always
  # are; a plain frame is when text-wrapping. Class-level query, was two self-instanceof
  # tests at the arrange site (type-test-elimination ε).
  isContentSizing: ->
    @isTextLineWrapping

  _reLayoutScrollbars: ->
    # §4.2 Stage 3 (structural arrange): the bars below apply their geometry via the NON-notifying
    # arrange twins (_applyExtentBase / _applyMoveToBase), not the notifying setters -- they are
    # chrome I own and place from my own size, never affecting my content-fit, so notifying would
    # only trigger a redundant confirm pass. The @_adjustingContentsBounds save/restore this used to
    # need is gone along with the notify-by-mutation seam it guarded against.
    # See docs/archive/proper-layouts-4.2-structural-arrange-plan.md.

    # one typically has both scrollbars in view, plus a resizer
    # in bottom right corner, so adjust the width/height of the
    # scrollbars so that there is no overlap between the three things
    spaceToLeaveOnOneSide = Math.max(@scrollBarsThickness, WorldWdgt.preferencesAndSettings.handleSize) + 2 * @padding
    hWidth = @width() - spaceToLeaveOnOneSide
    vHeight = @height() - spaceToLeaveOnOneSide

    @changed()

    # this check is to see whether the bar actually belongs to this ScrollPanel: a bar can survive
    # detached from its original ScrollPanel A (it's referenced as a property, not a child, so
    # duplicating A into B does not retarget or duplicate the bar), leaving B referencing A's bar. We
    # guard on the bar's own `target` before touching it so a stray duplicate never resizes/hides a
    # scrollbar that belongs to a different panel.
    if @hBar.target == @
      if @contents.width() >= @width() + 1
        @hBar.show()
        # chrome I own and place -- apply via the non-notifying twin as above (see the method-top
        # comment). _applyExtentBase == _applyWidth/Height minus the seam; preserves height/width by
        # passing the current other axis.
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
      # with this panel's own _reLayout ('super; @_reLayoutChildren'), distinct from the seam sites
      # (raw-mutator / gesture triggers), which DO defer -- see
      # docs/archive/deferred-layout-residuals-audit.md. Deferring this re-fit was tried and rejected
      # (diverges nested-scroll geometry for zero gain) -- see
      # docs/archive/layout-system-architecture-assessment.md, "Do not revisit (already falsified)".
      # layout-apply-sanctioned: public content-change endpoint, idempotent w/ _reLayout (OVERVIEW §11 PROOF 2)
      @_reLayoutChildren()

  # thin-wrap-exempt: SYNCHRONOUS content-change endpoint -- @contents.addMany + immediate @_reLayoutChildren
  # (re-reading APPLIED geometry is load-bearing; deferring it diverges nested-scroll geometry, exactly as
  # for add() -- see docs/archive/layout-system-architecture-assessment.md, "Do not revisit"). The
  # _addManyNoSettle twin below is the non-settling core for in-flush callers (createToolsPanel), NOT a
  # settle the public form should route through.
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


  # SCROLL-POSITION POLICY, not a child re-lay (schedule-valve arc V1, 2026-07-16 — absorbs the old
  # _reLayoutMyChildrenAfterImmediateResize override, whose re-lay half is now the base default /
  # the engine's job): a REAL immediate resize of a text-wrapping panel re-pins its contents to my
  # origin (the shipped reset-scroll-on-resize behaviour), while a re-lay at an unchanged frame
  # must never touch the scroll position. The pin lives AT the resize event because only the event
  # knows the delta — a scheduled/settle re-lay enters _reLayout with the extent already committed,
  # so an extent-delta gate inside _reLayout structurally cannot see an immediate resize. Pinning
  # BEFORE super is byte-equal to the old post-commit pin (an extent commit never changes my
  # origin); the arrange that follows (via the resize re-lay) then anchors and clamps off the
  # pinned position, same order as the old hook (pin → size → arrange). Wrapping-STACK contents
  # are excluded exactly as before (the arrange's clamp manages their position).
  _applyExtent: (aPoint) ->
    if !aPoint.equals(@extent()) and @isTextLineWrapping and !(@contents instanceof SimpleVerticalStackPanelWdgt)
      @contents._applyMoveTo @position()
    super aPoint


  # Gesture-driven container re-fit (a widget was dropped into / grabbed out of me): DEFER it to the
  # cycle via _reFitContainer -> _scheduleRelayoutRespectingPhase. These are dispatched from
  # ActivePointerWdgt.drop/grab AFTER a self-settling add, so they always run OUTSIDE any layout pass --
  # the off-pass arm (invalidate self; my _reLayout is 'super; @_reLayoutChildren', so the cycle re-fits
  # me identically) is what runs. The in-pass arm (a no-climb enqueue, for a caller that DOES fire
  # mid-pass) is never exercised here. See deferred-layout-residuals-audit.md fam 2.
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
  # deferred-layout child contributes only its viewport rect, not its scrolled subtree, which would
  # shrink a NESTED scroll panel's reported content size and regress nested-scroll (the proven 16->18
  # Path-A trap). We pin it PERMANENTLY to false, re-examined and reconfirmed through the sizing-model
  # unification arc (U3/U4): do not un-pin without a driving defect. See
  # docs/archive/sizing-model-unification-plan.md.
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
      # (schedule-valve V1) the old immediate-resize hook pre-set the stack to the viewport extent
      # (polymorphic contents._applyExtent) BEFORE the arrange ran; with the hook retired the arrange
      # normalizes the tracked WIDTH itself -- a WIDTH-CONSTRAINING stack's width is MY contract (it
      # tracks the viewport; macroWindowCellsInConstrainedScrollStackReflow regressed without this),
      # its height falls out of the merge-commit below. A FREE-width stack
      # (constrainContentWidth false) OWNS its width -- the whole point of the horizontal scrollbar
      # -- so normalizing it would valve-schedule a re-grow every arrange and ping-pong onto the
      # end-of-cycle flush (the capstone gate caught exactly that on
      # macroFreeWidthScrollStackShowsHorizontalScrollbar). Width-only: nothing between here and
      # the commit reads the stack's height.
      if @contents.constrainContentWidth and @contents.width() != @width()
        @contents._applyWidth @width()
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
          # (schedule-valve V1) wrap width derives from MY viewport, not @contents.width(): the two are
          # equal at the fixpoint (the merge-commit below pins contents width to mine for wrap panels),
          # but mid-transient — my frame just resized, contents not yet re-committed — only @width() is
          # current. The old immediate-resize hook pre-set contents to the viewport precisely to feed
          # this read; deriving from @width() removes that dependency.
          textWidth = @width() - totalPadding
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
    # class-level query, was two self-instanceof tests here (type-test-elimination ε)
    isContentSizing = @isContentSizing()
    if isContentSizing
      if @contents instanceof SimpleVerticalStackPanelWdgt
        subBounds = @contents.subWidgetsMergedPreferredBounds(@contents.width())?.ceil()
      else
        # (schedule-valve V1) same viewport-derived width as the re-wrap above — see that comment.
        subBounds = @contents.subWidgetsMergedPreferredBounds(@width() - totalPadding)?.ceil()
    else
      # (D4, U3-A) the ONE named state-read: user-placed free-floating children's positions
      # are state, and nothing above mutated them -- see subWidgetsMergedFullBounds's comment.
      subBounds = @contents.subWidgetsMergedFullBounds()?.ceil()
    if subBounds

      # add-in the content's own external padding
      if @contents.externalPadding?
        subBounds = subBounds.expandBy @contents.externalPadding

      # For a content-sizing stack/text panel: never stretch the view past the end of @contents (e.g.
      # after deleting text while scrolled to the bottom -- we don't want to reveal vacant space, we
      # want to shrink up and keep the bottom in view). So size first to the components' minimum area,
      # then grow only enough to fill the viewport.
      if isContentSizing
        newBounds = subBounds.expandBy(padding).ceil()

        # Anchor to the viewport's own left/top even when subBounds starts elsewhere (e.g. a single
        # centered icon) -- otherwise merging bounds that start off-origin would shift the panel so
        # the icon's left aligns with the viewport's left, un-centering it.
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
      # (schedule-valve V1; gate made STRUCTURAL by §9-N4) a contents WITH ITS OWN ARRANGE places its
      # children in its _reLayout (ToolPanelWdgt wraps its buttons -- the 2026-07-16 census-day bug,
      # healed until now by the retired hook's polymorphic contents._applyExtent chain); committing its
      # new frame via the non-notifying twin re-fits only its SELF layer, so schedule its full re-lay
      # through the phase-valve -- in-pass the same flush's next round heals it, off-pass the wrapping
      # settle does. The engine heals the interior; this arrange never re-lays it synchronously. (Also
      # covers the FrameWdgt early-settle route, where the later engine re-visit sees no frame delta
      # for the injection to act on.) The gate is implementsDeferredLayout, NOT children.length: a
      # base-_reLayout contents (the plain PanelWdgt of every ordinary scroll panel) gets nothing from
      # a full re-lay beyond the _reLayoutSelf above, and this arrange is ALSO reached off-settle by
      # the sanctioned synchronous content-change endpoints (public add/addMany -> _reLayoutChildren)
      # and the drag-to-scroll step -- a children.length gate made every such call push the contents
      # onto the end-of-cycle flush (the capstone gate caught 34 careless pushes across 10 scroll
      # tests, N4 close; plan §11).
      if @contents.implementsDeferredLayout()
        @contents._scheduleRelayoutRespectingPhase()

    # Always run this check even when @contents.boundingBox() already equals newBounds: a stack can
    # resize itself in the foreach loop above without changing the outer frame, so the view can still
    # need fixing. Cheap to check when there's nothing to do.
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
    # Return true iff the content actually moved -- callers use this to decide whether to trigger the
    # content/scrollbar update.
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
    # Return true iff the content actually moved -- callers use this to decide whether to trigger the
    # content/scrollbar update.
    if newY isnt ct
      @contents._moveTopSideTo newY
      return true
    else
      return false
  
  # Float-dragging a ScrollPanel's contents scrolls it (particularly useful on touch devices); the same
  # gesture works with the mouse when dragging over content that isn't itself draggable (e.g. text in a
  # scroll panel anchored to a non-draggable background, such as a color palette).
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
        # a float-draggable widget under the hand is probably about to be detached, so hold steady
        # instead of scrolling -- scrolling now would give the wrong cue right before the float-drag
        # threshold is reached
        !world.hand.wdgtToGrab?.detachesWhenDragged() and
        # per-frame samples of the hand are SCREEN-plane; map each into MY plane at the read
        # site (the raw-pointer lint enforces exactly this shape), so the containment gate
        # compares like planes and the deltas below are in-plane — a tilted panel drag-scrolls
        # along its own axes. Off any island the mapping returns the same point (dormant
        # byte-identical). The press point (oldPos = the handler's `pos`) arrives pre-mapped.
        @boundsContainPoint(@screenPointToMyPlane world.hand.position())
          wasScrollDragging = true
          newPos = @screenPointToMyPlane world.hand.position()
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
          # plane-mapped like the per-frame samples above — the flush's release-minus-press
          # total must be computed between points of the SAME plane
          releasePos = @screenPointToMyPlane world.hand.position()
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
  # docs/archive/softwrap-deferred-layout-conversion-plan.md for the model finding, the
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

    # public-call-sanctioned: enableDrops is the trivial public drop-acceptance setter
    # (macro/cross-object surface) — settle-free, consciously reused by this core.
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

    # public-call-sanctioned: disableDrops — see the enableDrops note in the enable core above.
    @disableDrops()
    @dragsDropsAndEditingEnabled = false

    @contents._disableDragsDropsAndEditingNoSettle @
    # ELIMINATE (end-of-cycle-flush-drawdown): a disable-probe proved the deferred re-fit that used to
    # live here redundant -- disabling only changes appearance/drop-handling, and the cascade's
    # @contents._disableDragsDropsAndEditingNoSettle above already did the synchronous work. See
    # docs/archive/end-of-cycle-flush-inventory.md. (Was `@_invalidateLayout()`.)

