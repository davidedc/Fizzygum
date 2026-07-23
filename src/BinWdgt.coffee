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
  
  # NOT homepage-excluded (it long was): the snapshot-load teardown
  # (WorldWdgt._teardownForSnapshotLoadNoSettle) ships in --homepage and calls
  # this -- with it stripped, "open from file…" on a homepage build crashed
  # at teardown.
  empty: ->
    @scrollPanel?.contents?.fullDestroyChildren()
  
  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @scrollPanel = new ScrollPanelWdgt
    @_addNoSettle @scrollPanel

    @emptyBinButton = new SimpleButtonWdgt true, @, "emptyBinRequested", "Empty bin"
    @_addNoSettle @emptyBinButton

    @_invalidateLayout()


  # Button action (button-action strings stay public and un-underscored). Empty bin is
  # the framework's only bulk-destructive user action, so it confirms through an
  # in-world menu first; the menu is transient, so dismissal destroys it.
  emptyBinRequested: ->
    menu = new MenuWdgt @, target: @, title: "Empty the bin?\nEverything shown in it will be\ndestroyed for good."
    menu.addMenuItem "Yes, empty it", @, "emptyBin"
    menu.addMenuItem "Cancel"
    menu.popUpCenteredAtHand world

  # Destroy every bin resident. By the standing storage invariant everything in
  # the bin IS lost (reachable items rest on the shelf) -- but a sort may still
  # be PENDING from an event this very cycle, so drain first: anything reachable
  # still sitting here moves to the shelf and is spared. Destroying a binned
  # shortcut cannot strand work either way: a target reachable ONLY through a
  # lost shortcut is itself lost, so it already sits in this same sweep.
  emptyBin: ->
    world.storageSorter.drainPendingSort()
    for w in @scrollPanel.contents.children.slice()
      continue if w.destroyed
      w.fullDestroy()

  # a closed/lost widget is scattered into the bin's contents. A core itself: called only
  # from close()'s private chain (_closeNoSettle) and the storage sorter's drain, invoking
  # a core, with no settle (the close/drain batch settles).
  _addRestingWidgetNoSettle: (w) ->
    @scrollPanel.contents._addInPseudoRandomPositionNoSettle w

  # is w currently sitting in the bin's contents? §7.5 Bug B (model a) + latent 2 (Option B): a
  # tilted/scaled or explicitly-islanded widget is re-homed to the bin AS ITS FIGURE (w.parent is then
  # the island, whose parent is the contents), so classify against w's REAL container through any
  # sole-content island wrap -- the same look-through idiom FrameWdgt.isInternal uses -- else holds(w)
  # would go false while w is demonstrably in the bin.
  holds: (w) ->
    p = w._parentThroughIslands()
    p? and p == @scrollPanel.contents

  # an arrival (close filing or a drop into the open bin window) may change
  # storage membership -- mark-only; the end-of-cycle drain sorts. (The sorter
  # suppresses the echo of its own drain moves through this relay.)
  _reactToChildAddedInScrollPanel: (child) ->
    world.noteStorageMembershipMayHaveChanged()

  # a pickup/departure out of the open bin window is the symmetric membership
  # event (e.g. a shortcut dragged out re-seeds its target's reachability while
  # still in the hand) -- mark-only; the end-of-cycle drain sorts.
  _reactToChildRemovedInScrollPanel: (child) ->
    world.noteStorageMembershipMayHaveChanged()


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
