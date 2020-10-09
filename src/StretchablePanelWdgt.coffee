# this is made to go inside the StretchablePanelContainer,
# it probably makes no sense on its own

class StretchablePanelWdgt extends PanelWdgt

  childRemoved: (child) ->
    super
    if @parent?.setRatio? and @parent.ratio?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      if childrenNotHandlesNorCarets.length == 0
        @parent.resetRatio()

  childAdded: (child) ->
    super
    # only set ratio with the first added child
    # the following ones don't change it
    if @parent?.setRatio? and !@parent.ratio?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      if childrenNotHandlesNorCarets.length != 0
        @parent.setRatio @width() / @height()


  rawSetExtent: (extent) ->
    if extent.equals @extent()
      return

    super
    @doLayout @bounds


  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      return

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.trackChanges.push false

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    # TODO antipattern - in doLayout you should never set raw position
    # and extent like this directly on the children (except in the base Widget
    # implementation) because the children might have their own layouts
    # inside of them, so you have to call doLayout on them in some form.
    # the bad news here is that doLayout cannot take in input a fractional position yet
    for w in childrenNotHandlesNorCarets
      w.fullRawMoveInStretchablePanelToFractionalPosition newBoundsForThisLayout
      w.rawSetExtentToFractionalExtentInPaneUserHasSet newBoundsForThisLayout

      # Since we can't call doLayout with fractional position/bounds yet (TODO), we
      # have set the raw position and extent directly, and
      # we now still need to invoke doLayout.
      w.desiredPosition = nil
      w.desiredExtent = nil
      w.doLayout()

    @rawSetBounds newBoundsForThisLayout




    world.trackChanges.pop()
    @fullChanged()

    super
    @layoutIsValid = true

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if !@dragsDropsAndEditingEnabled
        menu.addMenuItem "enable editing", true, @, "enableDragsDropsAndEditing", "lets you drag content in and out"
      else
        menu.addMenuItem "disable editing", true, @, "disableDragsDropsAndEditing", "prevents dragging content in and out"

    menu.removeConsecutiveLines()

  enableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.makePencilYellow?()
    if @parent? and @parent != triggeringWidget and @parent instanceof StretchableWidgetContainerWdgt
      @parent.enableDragsDropsAndEditing @
    else
      super @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.makePencilClear?()
    if @parent? and @parent != triggeringWidget and @parent instanceof StretchableWidgetContainerWdgt
      @parent.disableDragsDropsAndEditing @
    else
      super @
