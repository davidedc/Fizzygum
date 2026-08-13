# this is made to go inside a StretchableWidgetContainerWdgt,
# it probably makes no sense on its own

class StretchablePanelWdgt extends PanelWdgt

  @augmentWith BubblesEditModeToCoordinatorMixin, @name

  # I re-lay my children from their proportional records (StretchLayoutSpecs, see
  # _reLayout below) -- my COMPLETE child rule, asked by the __add seed and the world's
  # drain stations (see Widget.consumesFractionalGeometryOf): layout-inert chrome
  # (handles / carets / highlighters) is never a reflow subject, exactly as my arrange's
  # childrenNotHandlesNorCarets excludes it.
  consumesFractionalGeometryOf: (child) ->
    !child.isLayoutInert?()

  _reactToChildRemoved: (child) ->
    super
    if @parent?.setRatio? and @parent.ratio?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      if childrenNotHandlesNorCarets.length == 0
        @parent.resetRatio()

  _reactToChildAdded: (child) ->
    super
    # only set ratio with the first added child
    # the following ones don't change it
    if @parent?.setRatio? and !@parent.ratio?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      if childrenNotHandlesNorCarets.length != 0
        @parent.setRatio @width() / @height()



  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    @_repaintAsOneUnit =>

      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      # The engine-standard GRANT-BOUNDS arrange (spec-unification arc, closing the founding
      # "antipattern" TODO): each consumed child is granted the integer box its
      # StretchLayoutSpec derives for my granted bounds, through the child's OWN
      # _reLayout(bounds) — the same shape StackLayoutEngine uses. ⚠⚠ The grant MUST keep
      # routing through base Widget._reLayout's PLAIN twins (_applyMoveTo / _applyExtent),
      # never Base twins — falsified both ways (auto-bookkeeping arc, measured): the island's
      # anchor-carrying _applyMoveTo override (Bug-G) is load-bearing for a tilted child, and
      # _applyExtent's schedule-valve gives a resized composite interior (wrapping text,
      # nested scroll) its deferred second re-lay. Base _reLayout provides exactly those on
      # the granted path — see the imposer comment in Widget._moveInDesktopToFractionalPosition.
      for w in childrenNotHandlesNorCarets
        # the SAME membership rule the __add seed and the world drains ask (D10): a
        # layout-inert overlay (highlighter) parked in me is not a reflow subject, and the
        # gated recorder below would refuse it a spec anyway — skip, don't undefined-deref
        continue unless @consumesFractionalGeometryOf w
        # Hardening (§5b): a child that somehow lacks its proportional record — a stale/foreign child,
        # or one added mid-pass before the world's fill drain could seed it — must NOT abort my WHOLE
        # relayout by dereferencing an undefined spec in the grant below (that TypeError is caught as
        # LAYOUT_ERROR and silently aborts the pass). Lazily derive it from the child's current place in
        # me, marked PROVISIONAL (D8): a pre-placement guess the fill drain re-derives once at
        # builder-final geometry — which is what retired the place-before-add builder rule.
        # (No-op when the record is already present — the common case.)
        w._rememberFractionalSituationInHoldingPanel true if !w.layoutSpec?.isStretchElement?()
        # the panel OWNS a spec-carrying child's frame: a pending desire against it is stale
        # by definition (user intent arrives through the post-flush re-record drain), and a
        # desire left to linger would fire at the child's next own settle — clear both.
        w.desiredPosition = undefined
        w.desiredExtent = undefined
        # layout-apply-sanctioned: this IS the arrange — grant the spec-derived integer box
        w._reLayout w.layoutSpec.grantedBoundsWithin newBoundsForThisLayout

      # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
      # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
      # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
      @_applyGrantedBounds newBoundsForThisLayout

    super
    @_markLayoutAsFixed()


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addEditingLockMenuEntries menu, @childrenNotHandlesNorCarets()

  # canonical settle-wraps; the bubbling cores they dispatch to are injected by
  # BubblesEditModeToCoordinatorMixin
  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget
