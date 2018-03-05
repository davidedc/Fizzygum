class BasementWdgt extends BoxMorph

  # panes:
  scrollPanel: nil
  resizer: nil

  hideUsedWdgtsOnButton: nil
  hideUsedWdgtsOffButton: nil
  hideUsedWdgtsToggle: nil

  showingLostItemsOnly: false

  constructor: ->
    super()

    @silentRawSetExtent new Point 340, 270
    @color = new Color 60, 60, 60
    @padding = 5
    @buildAndConnectChildren()

  colloquialName: ->
    "Basement"

  closeFromContainerWindow: (containerWindow) ->
    # remove ourselves from
    # the window
    @removeFromTree()
    # here we are just removing the empty window
    # there is nothing in it
    containerWindow.fullDestroy()
  
  empty: ->
    @scrollPanel?.contents?.fullDestroyChildren()
  
  buildAndConnectChildren: ->

    @scrollPanel = new ScrollPanelWdgt()
    @add @scrollPanel

    @hideUsedWdgtsOnButton = new SimpleButtonMorph true, @, "showAllWidgets", (new StringMorph2 "☒ only show lost items").alignCenter()
    @hideUsedWdgtsOffButton = new SimpleButtonMorph true, @, "hideUsedWidgets", (new StringMorph2 "☐ only show lost items").alignCenter()
    @hideUsedWdgtsToggle = new ToggleButtonMorph @hideUsedWdgtsOffButton, @hideUsedWdgtsOnButton, 0
    @add @hideUsedWdgtsToggle


    # resizer
    @resizer = new HandleMorph @

    @invalidateLayout()


  # this is a very basic garbage collection mechanism
  # we basically try to find out which items in the basement
  # are still referenced somehow and which aren't
  # it's based on the idea that "referencing" widgets
  # are kept in a list, and we can just scan those and mark
  # everything they reference as "reachable".
  doGC: ->
    world.incrementalGcSessionId++
    newGcSessionId = world.incrementalGcSessionId

    # precondition: the BasementWdgt is on the desktop.
    # first, take all orphan references and mark them as visited so we
    # get them out of the way immediately. They are unreachable by
    # definition (remember, the BasementWdgt is on screen, so they
    # are not even in the basement!) and
    # so they don't make their target reacheable.
    for eachReferencingMorph in world.widgetsReferencingOtherWidgets
      if eachReferencingMorph.isOrphan()
        eachReferencingMorph.markReferenceAsVisited newGcSessionId

    # then, take all remaining references, filter OUT the ones in the
    # basement (so: get the non-orphan non-basement references, which means
    # they are reachable from the desktop without going via the basement)
    # and for each:
    #  - mark what they reach (and their parents) as reachable
    #     (note that what they reach MIGHT be in the basement)
    #  - mark them as visited so we don't visit again
    for eachReferencingMorph in world.widgetsReferencingOtherWidgets
      if !eachReferencingMorph.wasReferenceVisited newGcSessionId
        if !eachReferencingMorph.isInBasement()
          eachReferencingMorph.target.markItAndItsParentsAsReachable newGcSessionId
          eachReferencingMorph.markReferenceAsVisited newGcSessionId

    # then, take all remaining references (which by exclusion at this point
    # must be the references the basement) and,
    # if they are reachable, then we have to mark what they reference
    # as reachable.
    # How do we know if they are reachable?
    # They are reachable if one of their parents is reachable.
    # Then:
    #   - mark what it references (and parents) as reacheable
    #   - mark it as visited so we don't visit again
    # Note that this a progressive search, because a reference might
    # make another reference reacheable, which might make another
    # reference reachable... in those chains we have to keep
    # searching until we find no new references
    newReachableReferencesUncovered = true
    while newReachableReferencesUncovered
      newReachableReferencesUncovered = false
      for eachReferencingMorph in world.widgetsReferencingOtherWidgets
        if !eachReferencingMorph.wasReferenceVisited newGcSessionId
          if eachReferencingMorph.isInBasementButReachable newGcSessionId
            newReachableReferencesUncovered = true
            eachReferencingMorph.target.markItAndItsParentsAsReachable newGcSessionId
            eachReferencingMorph.markReferenceAsVisited newGcSessionId

    return newGcSessionId

  hideUsedWidgets: ->
    @showingLostItemsOnly = true

    newGcSessionId = @doGC()

    # now we have an idea of which children in the basement
    # are reachable and which aren't
    referencedChildren = []

    for eachChild in @scrollPanel.contents.children
      if eachChild.isInBasementButReachable newGcSessionId
        if referencedChildren.indexOf eachChild == -1
          referencedChildren.push eachChild

    for eachChild in referencedChildren
      eachChild.hide()

  showAllWidgets: ->
    @showingLostItemsOnly = false
    for eachChild in @scrollPanel.contents.children
      eachChild.show()

  # if a child has been added to the scrollPanel,
  # the scrollPanel checks its parent to see if it
  # has this callback. We use this callback because
  # we want to make
  # sure that the "only show lost items"
  # filter is respected. Just re-invoke the
  # methods that calculate the visibility
  childAddedInScrollPanel: ->
    if @showingLostItemsOnly
      @hideUsedWidgets()
    else
      @showAllWidgets()


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

    @rawSetBounds newBoundsForThisLayout

    trackChanges.push false

    x = @left() + @cornerRadius
    y = @top() + @cornerRadius
    r = @right() - @cornerRadius
    w = r - x

    # scrollPanel
    y = @top() + 2
    w = @width() - @cornerRadius
    w -= @cornerRadius
    b = @bottom() - (2 * @cornerRadius) - WorldMorph.preferencesAndSettings.handleSize
    h = b - y
    @scrollPanel.fullRawMoveTo new Point x, y
    @scrollPanel.rawSetExtent new Point w, h

    # hideUsedWdgts toggle button
    x = @scrollPanel.left()
    y = @scrollPanel.bottom() + @cornerRadius
    h = WorldMorph.preferencesAndSettings.handleSize
    w = @scrollPanel.width() - h - @cornerRadius
    @hideUsedWdgtsToggle.doLayout (new Rectangle  0,0,w,h).translateBy new Point x, y
    trackChanges.pop()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()
