# this is made to go inside the StretchablePanelContainer,
# it probably makes no sense on its own

class StretchablePanelWdgt extends PanelWdgt

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


  _applyExtent: (extent) ->
    if extent.equals @extent()
      return

    super
    @_reLayout @bounds


  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    # TODO antipattern - in _reLayout you should never set raw position
    # and extent like this directly on the children (except in the base Widget
    # implementation) because the children might have their own layouts
    # inside of them, so you have to call _reLayout on them in some form.
    # the bad news here is that _reLayout cannot take in input a fractional position yet
    for w in childrenNotHandlesNorCarets
      # Hardening (§5b): a child that somehow lacks its fractional bookkeeping — a stale/foreign child,
      # or a wrapper that reached me without the materialize/drop transfer — must NOT abort my WHOLE
      # relayout by dereferencing nil[0] in the two consumers below (that TypeError is caught as
      # LAYOUT_ERROR and silently aborts the pass). Lazily derive it from the child's current place in
      # me (self-healing; byte-identical when the data is already present — the common case).
      w._rememberFractionalSituationInHoldingPanel() if !w.positionFractionalInHoldingPanel? or !w.extentFractionalInHoldingPanel?
      w._moveInStretchablePanelToFractionalPosition newBoundsForThisLayout
      w._setExtentToFractionalExtentInPaneUserHasSet newBoundsForThisLayout

      # Since we can't call _reLayout with fractional position/bounds yet (TODO), we
      # have set the raw position and extent directly, and
      # we now still need to invoke _reLayout.
      w.desiredPosition = nil
      w.desiredExtent = nil
      w._reLayout()

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout




    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()


  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addEditingLockMenuEntries menu, @childrenNotHandlesNorCarets()

  # Bubble enable/disable-editing up to my editing-coordinating parent if it is one
  # (was `@parent instanceof StretchableWidgetContainerWdgt`), otherwise do the local
  # Widget work via super -- the capability query keeps the bubble to the coordinator
  # rather than to any parent (Widget has a base enableDragsDropsAndEditing).
  # (type-test-elimination campaign)
  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.showEditModeInBar?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent._enableDragsDropsAndEditingNoSettle @
    else
      super @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget

  _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent._disableDragsDropsAndEditingNoSettle @
    else
      super @
