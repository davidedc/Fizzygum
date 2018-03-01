# this is made to go inside the StretchablePanelContainer,
# it probably makes no sense on its own

class StretchablePanelWdgt extends PanelWdgt

  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

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
      @notifyChildrenThatParentHasReLayouted()
      return

    debugger


    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    childrenNotHandlesNorCarets = @children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    for eachChild in childrenNotHandlesNorCarets
      eachChild.fullRawMoveInStretchablePanelToFractionalPosition newBoundsForThisLayout
      eachChild.rawSetExtentToFractionalExtentInPaneUserHasSet newBoundsForThisLayout      

    @rawSetBounds newBoundsForThisLayout




    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()