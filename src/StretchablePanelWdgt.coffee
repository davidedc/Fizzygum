# this is made to go inside the StretchablePanelContainer,
# it probably makes no sense on its own

class StretchablePanelWdgt extends PanelWdgt

  childRemoved: (child) ->
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


  _applyExtentAndNotify: (extent) ->
    if extent.equals @extent()
      return

    super
    @_reLayout @bounds


  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  _reLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

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
      w._moveInStretchablePanelToFractionalPosition newBoundsForThisLayout
      w._setExtentToFractionalExtentInPaneUserHasSet newBoundsForThisLayout

      # Since we can't call _reLayout with fractional position/bounds yet (TODO), we
      # have set the raw position and extent directly, and
      # we now still need to invoke _reLayout.
      w.desiredPosition = nil
      w.desiredExtent = nil
      w._reLayout()

    # TODO shouldn't be calling this _applyBoundsAndNotify from here,
    # rather use super
    @_applyBoundsAndNotify newBoundsForThisLayout




    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if !@dragsDropsAndEditingEnabled
        menu.addMenuItem "enable editing", true, @, "enableDragsDropsAndEditing", "lets you drag content in and out"
      else
        menu.addMenuItem "disable editing", true, @, "disableDragsDropsAndEditing", "prevents dragging content in and out"

    menu.removeConsecutiveLines()

  # Bubble enable/disable-editing up to my editing-coordinating parent if it is one
  # (was `@parent instanceof StretchableWidgetContainerWdgt`), otherwise do the local
  # Widget work via super -- the capability query keeps the bubble to the coordinator
  # rather than to any parent (Widget has a base enableDragsDropsAndEditing).
  # (type-test-elimination campaign)
  enableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.makePencilYellow?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent.enableDragsDropsAndEditing @
    else
      super @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.makePencilClear?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent.disableDragsDropsAndEditing @
    else
      super @
