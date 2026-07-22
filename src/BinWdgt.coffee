class BinWdgt extends BoxWdgt

  # panes:
  scrollPanel: nil
  emptyBinButton: nil

  constructor: ->
    super()

    @__commitExtent new Point 340, 270
    @color = Color.create 60, 60, 60
    @padding = 5
    # I only ever appear as a window's content (BinOpenerWdgt always wraps me in a
    # FrameWdgt), and I am a VIEW, not a fixed-proportion artifact: fill the window
    # on both axes and track its resizes (like PaletteWdgt / the text scroll panels).
    @layoutSpecDetails = new FrameContentLayoutSpec FrameContentLayoutSpec.DONT_MIND, FrameContentLayoutSpec.DONT_MIND, 1
    @_buildAndConnectChildren()

  colloquialName: ->
    "Bin"

  closeFromContainerFrame: (containerWindow) ->
    # remove ourselves from
    # the window
    @removeFromTree()
    # here we are just removing the empty window
    # there is nothing in it
    containerWindow.fullDestroy()
  
  # »>> this part is excluded from the fizzygum homepage build
  empty: ->
    @scrollPanel?.contents?.fullDestroyChildren()
  # this part is excluded from the fizzygum homepage build <<«
  
  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @scrollPanel = new ScrollPanelWdgt
    @_addNoSettle @scrollPanel

    @emptyBinButton = new SimpleButtonWdgt true, @, "emptyBinRequested", "Empty bin"
    @_addNoSettle @emptyBinButton

    @_invalidateLayout()


  # this is a very basic garbage collection mechanism
  # we basically try to find out which items in the bin
  # are still referenced somehow and which aren't
  # it's based on the idea that "referencing" widgets
  # are kept in a list, and we can just scan those and mark
  # everything they reference as "reachable".
  doGC: ->
    world.incrementalGcSessionId++
    newGcSessionId = world.incrementalGcSessionId

    # precondition: the BinWdgt is on the desktop.
    # first, take all orphan references and mark them as visited so we
    # get them out of the way immediately. They are unreachable by
    # definition (remember, the BinWdgt is on screen, so they
    # are not even in the bin!) and
    # so they don't make their target reachable.
    for eachReferencingWdgt from world.widgetsReferencingOtherWidgets
      if eachReferencingWdgt.isOrphan()
        eachReferencingWdgt.markReferenceAsVisited newGcSessionId

    # then, take all remaining references, filter OUT the ones in the
    # bin (so: get the non-orphan non-bin references, which means
    # they are reachable from the desktop without going via the bin)
    # and for each:
    #  - mark what they reach (and their parents) as reachable
    #     (note that what they reach MIGHT be in the bin)
    #  - mark them as visited so we don't visit again
    for eachReferencingWdgt from world.widgetsReferencingOtherWidgets
      if !eachReferencingWdgt.wasReferenceVisited newGcSessionId
        if !eachReferencingWdgt.isInBin()
          eachReferencingWdgt.target.markItAndItsParentsAsReachable newGcSessionId
          eachReferencingWdgt.markReferenceAsVisited newGcSessionId

    # system furniture parked in the bin is reachable through WORLD FIELDS, not
    # through the shortcut tracker: the app singletons (world[slot], revived by their
    # desktop launchers) and the editor templates window (revived by TemplatesButtonWdgt).
    # Without this they'd classify as lost -- and be shown in, and destroyable from, the
    # lost-items view. Marked before the fixpoint below so references held INSIDE this
    # furniture propagate reachability like any other reachable bin resident.
    for slot in Serializer.WORLD_APP_SLOTS
      world[slot]?.markItAndItsParentsAsReachable newGcSessionId
    world.simpleEditorTemplates?.markItAndItsParentsAsReachable newGcSessionId

    # then, take all remaining references (which by exclusion at this point
    # must be the references the bin) and,
    # if they are reachable, then we have to mark what they reference
    # as reachable.
    # How do we know if they are reachable?
    # They are reachable if one of their parents is reachable.
    # Then:
    #   - mark what it references (and parents) as reachable
    #   - mark it as visited so we don't visit again
    # Note that this a progressive search, because a reference might
    # make another reference reachable, which might make another
    # reference reachable... in those chains we have to keep
    # searching until we find no new references
    newReachableReferencesUncovered = true
    while newReachableReferencesUncovered
      newReachableReferencesUncovered = false
      for eachReferencingWdgt from world.widgetsReferencingOtherWidgets
        if !eachReferencingWdgt.wasReferenceVisited newGcSessionId
          if eachReferencingWdgt.isInBinButReachable newGcSessionId
            newReachableReferencesUncovered = true
            eachReferencingWdgt.target.markItAndItsParentsAsReachable newGcSessionId
            eachReferencingWdgt.markReferenceAsVisited newGcSessionId

    return newGcSessionId

  # The bin's one view: LOST items only. Anything reachable -- through a shortcut chain
  # or a world field (doGC) -- is parked infrastructure (the simulated disk), not junk,
  # so it is hidden; what stays visible is exactly what "Empty bin" would destroy.
  # Symmetric on purpose: an item whose last reference died while it sat hidden must
  # re-surface at the next refresh. Public: the opener refreshes the view at every
  # open (references can die while the bin is closed), and the child-add callback
  # below re-applies it as things land.
  refreshLostOnlyView: ->
    newGcSessionId = @doGC()
    for w in @scrollPanel.contents.children
      if w.isInBinButReachable newGcSessionId
        w.hide()
      else
        w.show()
    # hidden children are excluded from the scroll fit (subWidgetsMergedFullBounds),
    # so a visibility flip changes the content frame: re-fit through the phase-safe
    # valve (this callback also runs inside add/settle batches).
    @_reFitContainer @scrollPanel

  # Button action (button-action strings stay public and un-underscored). Empty bin is
  # the framework's only bulk-destructive user action, so it confirms through an
  # in-world menu first; the menu is transient, so dismissal destroys it.
  emptyBinRequested: ->
    menu = new MenuWdgt @, target: @, title: "Empty the bin?\nEverything shown in it will be\ndestroyed for good."
    menu.addMenuItem "Yes, empty it", @, "emptyBin"
    menu.addMenuItem "Cancel"
    menu.popUpCenteredAtHand world

  # Destroy every LOST item. The lost set comes from ONE doGC, then we destroy -- never
  # recompute mid-loop: destroying a binned shortcut can make its target newly lost, and
  # THIS session's set already classifies that target correctly (unreachable then ==
  # lost then: binning the last link binned the document, the semantics the confirm
  # warns about). Reachable (parked) residents are untouched. doGC's on-screen
  # precondition holds: the button lives in the open bin window.
  emptyBin: ->
    newGcSessionId = @doGC()
    lostOnes = (w for w in @scrollPanel.contents.children when !w.isInBinButReachable newGcSessionId)
    for w in lostOnes
      w.fullDestroy()

  # a closed/lost widget is scattered into the bin's contents. A core itself: called only from
  # close()'s private chain (_closeNoSettle) and invoking a core, with no settle (the close batch settles).
  _addLostWidgetNoSettle: (w) ->
    @scrollPanel.contents._addInPseudoRandomPositionNoSettle w

  # is w currently sitting in the bin's contents? §7.5 Bug B (model a) + latent 2 (Option B): a
  # tilted/scaled or explicitly-islanded widget is re-homed to the bin AS ITS FIGURE (w.parent is then
  # the island, whose parent is the contents), so classify against w's REAL container through any
  # sole-content island wrap -- the same look-through idiom FrameWdgt.isInternal uses -- else holds(w)
  # would go false while w is demonstrably in the bin.
  holds: (w) ->
    p = w._parentThroughIslands()
    p? and p == @scrollPanel.contents

  # if a child has been added to the scrollPanel,
  # the scrollPanel checks its parent to see if it
  # has this callback: re-apply the lost-only filter
  # so the new arrival is classified right away.
  _reactToChildAddedInScrollPanel: (child) ->
    @refreshLostOnlyView()


  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout

    world.disableTrackChanges()

    x = @left() + @cornerRadius

    # scrollPanel
    y = @top() + 2
    w = @width() - @cornerRadius
    w -= @cornerRadius
    b = @bottom() - (2 * @cornerRadius) - WorldWdgt.preferencesAndSettings.handleSize
    h = b - y
    @scrollPanel._applyBounds (new Point x, y), new Point w, h

    # Empty bin button
    x = @scrollPanel.left()
    y = @scrollPanel.bottom() + @cornerRadius
    h = WorldWdgt.preferencesAndSettings.handleSize
    w = @scrollPanel.width()
    @emptyBinButton._reLayout (new Rectangle  0,0,w,h).translateBy new Point x, y
    world.maybeEnableTrackChanges()

    super
    @_markLayoutAsFixed()
