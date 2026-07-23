# A window-content citizen in the ErrorsLogViewerWdgt/InspectorWdgt mould: a plain
# Widget with no background of its own (the wrapping FrameWdgt paints it), a main
# pane filling the body, and a 15-high bottom button row that reserves the
# sizing-handle corner.
class BinWdgt extends Widget

  # panes:
  scrollPanel: nil
  emptyBinButton: nil

  externalPadding: 0
  internalPadding: 5

  # the Empty-bin button's natural width -- kept until the window gets too
  # narrow for it (see _reLayout)
  emptyBinButtonWidth: 100

  constructor: ->
    # a naked (chrome-less) bin must establish its OWN usable extent (the
    # InspectorWdgt idiom); the windowed path (BinOpenerWdgt) overrides this
    # via the window's bounds.
    super new Point 340, 270
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
    # a white content pane, like the inspector's list/detail panes and the text
    # panels (orphan-construction field writes; PanelWdgt.setColor keeps the
    # pair in sync from then on). Drops stay ENABLED: dropping things into the
    # open bin is how you throw them away.
    @scrollPanel.color = Color.WHITE
    @scrollPanel.contents.color = Color.WHITE
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

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this widget are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    world.disableTrackChanges()

    # the main pane fills the body above the button row (the
    # ErrorsLogViewerWdgt scheme: the row's height is the handleSize band)
    mainPaneHeight = @height() - 2 * @externalPadding - @internalPadding - WorldWdgt.preferencesAndSettings.handleSize
    mainPaneBottom = @top() + @externalPadding + mainPaneHeight

    if @scrollPanel.parent == @
      @scrollPanel._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point @width() - 2 * @externalPadding, mainPaneHeight

    # the Empty-bin button sits at the LEFT of the bottom row (owner-placed:
    # destructive action away from the sizing-handle corner) at its NATURAL
    # width -- it shrinks only when the window gets narrower than natural
    # width + padding + the sizing handle (both always spared). Integer by
    # construction: a constant clamped by integer geometry.
    if @emptyBinButton.parent == @
      rowWidth = @width() - 2 * @externalPadding - @internalPadding - WorldWdgt.preferencesAndSettings.handleSize
      buttonWidth = Math.max 0, Math.min @emptyBinButtonWidth, rowWidth
      buttonBounds = new Rectangle new Point @left() + @externalPadding, mainPaneBottom + @internalPadding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight buttonWidth, 15
      @emptyBinButton._reLayout buttonBounds

    world.maybeEnableTrackChanges()

    super
    @_markLayoutAsFixed()
