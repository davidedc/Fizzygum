# A window-content citizen in the ErrorsLogViewerWdgt mould: a plain Widget that paints no
# background of its own (the wrapping FrameWdgt paints it) -- only its footer band's rule -- with
# a main pane filling the body down to a footer band (FooterBandLayout) that holds its one
# button.
class BinWdgt extends Widget

  # panes:
  viewport: undefined
  emptyBinButton: undefined

  # the main pane's inset from my top and sides; it always runs down to my footer band.
  externalPadding: 0

  constructor: ->
    # a naked (chrome-less) bin must establish its OWN usable extent (the
    # InspectorWdgt idiom); the windowed path (BinOpenerWdgt) overrides this
    # via the window's bounds.
    super new Point 340, 270
    # my only paint: my footer band's rule, my one seam (_seamRects)
    @appearance = new SeamRulesAppearance @
    # I only ever appear as a window's content (BinOpenerWdgt always wraps me in a
    # FrameWdgt), and I am a VIEW, not a fixed-proportion artifact: fill the window
    # on both axes and track its resizes (like PaletteWdgt / the text viewports).
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.DONT_MIND, FrameContentLayoutSpec.DONT_MIND, 1
    @_buildAndConnectChildren()

  colloquialName: ->
    "Bin"

  # Closing my window puts ME away: I am the world's bin (world.binWdgt) and go back off the tree,
  # taking my residents off the desktop with me. A stroke can be pressing one of them in my open
  # window, so the hand is told before I leave (ActivePointerWdgt.noteWidgetClosed) -- I cannot pass
  # through the close funnel, which would file me into myself.
  closeFromContainerFrame: (containerWindow) ->
    world.hand.noteWidgetClosed @
    @removeFromTree()
    # containerWindow is now empty (we just detached above), so destroying it loses nothing
    containerWindow.fullDestroy()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    @viewport = new ViewportWdgt
    # my main pane, dressed in the bin pane's roles (ViewportWdgt.wearPaneRoles, read as it paints,
    # and its plane wears them too): the binViewportFill, and the window content's border -- like a
    # code area, it is my window's content down to my footer band, so the window's border and its
    # strip's rule run along it. Drops stay ENABLED: dropping things into the open bin is how you
    # throw them away.
    @viewport.wearPaneRoles fill: "binViewportFill", stroke: "windowContentPanelStroke"
    @_addNoSettle @viewport

    # "…": the press asks first (emptyBinRequested's confirmation) and empties only on a yes
    @emptyBinButton = new SimpleButtonWdgt @, "emptyBinRequested", face: "Empty bin…"
    @_addNoSettle @emptyBinButton

    @_invalidateLayout()


  # Button action (button-action strings stay public and un-underscored). Empty bin is
  # the framework's only bulk-destructive user action, so it confirms through an
  # in-world menu first; the menu is transient, so dismissal destroys it.
  emptyBinRequested: ->
    menu = new MenuWdgt @, target: @, title: "Empty the bin?\nEverything shown in it will be\ndestroyed for good.", titleIsAMessage: true
    menu.addMenuItem "Yes, empty it", @, "emptyBin"
    menu.addMenuItem "Cancel"
    # the pointer rests on the first row -- "Yes, empty it" -- where this confirmation wants it
    # (see popUpCenteredAtHand).
    menu.popUpCenteredAtHand world

  # Destroy every bin resident. By the standing storage invariant everything in
  # the bin IS lost (reachable items rest on the shelf) -- but a sort may still
  # be PENDING from an event this very cycle, so drain first: anything reachable
  # still sitting here moves to the shelf and is spared. Destroying a binned
  # shortcut cannot strand work either way: a target reachable ONLY through a
  # lost shortcut is itself lost, so it already sits in this same sweep.
  emptyBin: ->
    world.storageSorter.drainPendingSort()
    for w in @viewport.contents.children.slice()
      continue if w.destroyed
      w.fullDestroy()

  # a closed/lost widget is scattered into the bin's contents. A core itself: called only
  # from close()'s private chain (_closeNoSettle) and the storage sorter's drain, invoking
  # a core, with no settle (the close/drain batch settles).
  _addRestingWidgetNoSettle: (w) ->
    @viewport.contents._addInPseudoRandomPositionNoSettle w

  # is w currently sitting in the bin's contents? §7.5 Bug B (model a) + latent 2 (Option B): a
  # tilted/scaled or explicitly-islanded widget is re-homed to the bin AS ITS FIGURE (w.parent is then
  # the island, whose parent is the contents), so classify against w's REAL container through any
  # sole-content island wrap -- the same look-through idiom FrameWdgt.isInternal uses -- else holds(w)
  # would go false while w is demonstrably in the bin.
  holds: (w) ->
    p = w._parentThroughIslands()
    p? and p == @viewport.contents

  # an arrival (close filing or a drop into the open bin window) may change
  # storage membership -- mark-only; the end-of-cycle drain sorts. (The sorter
  # suppresses the echo of its own drain moves through this relay.)
  _reactToChildAddedInViewport: (child) ->
    world.noteStorageMembershipMayHaveChanged()

  # AN EXPLICIT DROP INTO MY OPEN WINDOW CARRIES TRASH INTENT (reference-widgets plan R5,
  # ratified 2026-08-19): run the same sever the "Move to trash" menu row runs, so the drop
  # STICKS -- without it, a still-referenced widget put in the bin is re-filed to the shelf by
  # the very next drain and visibly escapes the bin, silently overriding the user's gesture.
  # This hook fires ONLY for user drops (the drop-specific relay in
  # PanelWdgt._reactToChildDropped): close filing and the drain's own moves arrive through
  # _addNoSettle and never reach it, so an automatic filing can never sever anything.
  # Dropping a SHORTCUT here severs edges into the SHORTCUT itself (usually none) and leaves
  # its referent alone -- trashing an alias never touches the thing it points at; the referent
  # stays reachable through the bin-held holder until the bin is emptied.
  # Runs inside the drop's single settle -> the non-settling sever core.
  _reactToChildDroppedInViewport: (child) ->
    world._severLivenessEdgesIntoWdgtNoSettle child._enclosingIslandFigure()

  # a pickup/departure out of the open bin window is the symmetric membership
  # event (e.g. a shortcut dragged out re-seeds its target's reachability while
  # still in the hand) -- mark-only; the end-of-cycle drain sorts.
  _reactToChildRemovedInViewport: (child) ->
    world.noteStorageMembershipMayHaveChanged()


  # My one seam: my footer band's rule, between the main pane and the button.
  _seamRects: ->
    [FooterBandLayout.ruleIn new Rectangle 0, 0, @width(), @height()]

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    # the main pane from externalPadding in at my top and sides, flush down to my footer band
    # (clamped at 0: a transient degenerate height must not invert its rect)
    mainPaneTop = @top() + @externalPadding
    mainPaneHeight = Math.max 0, (FooterBandLayout.topIn @bounds) - mainPaneTop

    if @viewport.parent == @
      @viewport._applyBounds (new Point @left() + @externalPadding, mainPaneTop), new Point @width() - 2 * @externalPadding, mainPaneHeight

    # the Empty-bin button sits at the LEFT of my footer band (owner-placed: the destructive
    # action away from the grip's corner), at its own size
    FooterBandLayout.arrange @, [@emptyBinButton], []
